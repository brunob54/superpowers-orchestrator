# Multi-Code-Review: Multi-Round Independent Whole-Branch Code Review — Design

**Date:** 2026-07-27
**Status:** Draft — pending user approval

## Problem

Independent code reviews find largely disjoint issues (with some overlap) —
each pass surfaces defects the previous one missed. The design-phase evidence
for `multi-review` showed three lenses finding disjoint issue classes on the
same document. Yet subagent-driven-development's final whole-branch review is
a single pass: one reviewer, one lens, one verdict. This design extends that
gate into an N-round independent review loop for code, mirroring the
`multi-review` architecture so the two skills stay teachable as one pattern.

## Scope

A new standalone skill `skills/multi-code-review/` that runs an N-round
review-fix-repackage loop on a branch diff using subagents, plus a small
integration into subagent-driven-development:

- **subagent-driven-development** — the Final Whole-Branch Review step
  (Core Flow step 4, and the plan-complete path of Batched Autonomous Mode)
  invokes the loop instead of the single `code-reviewer.md` dispatch.
- **Direct invocation** — `/multi-code-review [BASE] [N]` on any branch.
  BASE defaults to `git merge-base main HEAD` (falling back to `master` when
  `main` does not exist).

## Non-Goals

- `requesting-code-review` is untouched. Its `code-reviewer.md` rubric,
  security checklist, and `agents/red-team.md` attack categories are folded
  **verbatim-adapted into this skill's lens instructions** — no cross-skill
  dispatch-time file reads beyond the established convention of referencing
  SDD's `scripts/review-package`.
- No per-round user approval. The loop reports once, at the end; the host
  gate (SDD final review → finishing-a-development-branch) remains the only
  approval point.
- No Codex/Cursor support (subagent dispatch is Claude Code-only, same as
  SDD). On platforms without the Agent tool the SDD integration falls back to
  the current single-pass final review.
- Does not replace SDD's per-task review gates. This is the *final* gate.
- Does not review documents — `multi-review` owns that. A `docs/`-only diff
  is still reviewed (lens instructions carry prose adaptations), but a spec
  or plan *document* should go through `multi-review`.
- Severity calibration is guided, not guaranteed (see Limitations).

## Parameters

- **Review range:** `BASE..HEAD`. The SDD gate passes MERGE_BASE (the commit
  the branch started from). Direct invocation computes
  `git merge-base main HEAD` unless the user supplied a BASE. If the range is
  empty (BASE = HEAD, or no merge-base resolvable), stop and report; nothing
  dispatched.
- **N (round cap):** if the user stated a count, use it (most recent wins).
  Otherwise ask once — at gate time for the SDD gate, immediately for direct
  invocations. Default **3**; valid N is an integer 0–10; anything else → 3.
  N = 0 skips the loop and logs a `skipped` entry (SDD then proceeds as if
  the final review passed with zero findings — an explicit user choice).
  **Batched Autonomous Mode never asks:** it uses the default 3 (or a count
  the user stated when starting the batch run).
- **Reviewer model:** inherit the session model, **with a sonnet floor** —
  if the session model is below sonnet (haiku), dispatch reviewers on
  `sonnet` and record the substitution in the log. This replaces SDD's
  "final whole-branch review always runs on opus" rule (explicit amendment;
  see Files). The dispatch template states the model line explicitly so it
  is never accidentally omitted-but-meant.
- **Fix-subagent model:** per SDD's Model Selection table (sonnet default);
  the loop does not override it.
- **Plan/requirements path (SDD gate):** the gate passes the plan path and
  the ledger's carried Minor-findings list. Direct invocations may name a
  requirements document; if none is available, lens 1 drops spec-alignment
  and reviews correctness only — logged as "alignment not reviewed".

## Architecture: The Loop

Controller = the main session executing the skill. All state lives in the
branch (commits), the sidecar review log, and the fix-report file.

For each round `i` in 1..N (for N > 4, lenses cycle from lens 1 — the code
has been revised since, so a re-pass is meaningful):

1. **Ensure a fresh review package.** Run
   `<sdd-skill-dir>/scripts/review-package BASE HEAD` (the script prints the
   unique file path it wrote; the package never enters the controller's
   context). Regenerate whenever commits landed since the last package
   (round 1, and any round following a fix); reuse the existing package when
   nothing changed (two consecutive no-finding rounds).
2. **Dispatch one reviewer subagent** (`general-purpose`, model per
   Parameters) using `reviewer-prompt.md` with round `i`'s lens. Inputs are
   ONLY the template placeholders:
   - package path, BASE/HEAD SHAs
   - lens name + lens instructions (verbatim from the lens table)
   - round 1 additionally: the plan/requirements path and the carried
     Minor-findings list to triage (fix-before-merge / ship-as-is /
     user-decision)
   The conversation, prior rounds' findings, fix reports, and the review log
   are never passed. Rounds 2+ are pure independent hunts on the current
   branch state.
3. **Reviewer reviews and reports** in the fixed format (below). The
   reviewer reads the package once; diff-only discipline and the named-risk
   exception follow `task-reviewer-prompt.md` (inspect code outside the diff
   only for a concrete named risk; name risk and check in the report).
   Read-only on the checkout. Barred from: the Skill tool, `*-review-log.md`
   and `*-fix-reports.md` files, and re-running the test suite (implementer
   reports carry test evidence; a focused test on a specific doubt is
   allowed). "No material issues under this lens" is an explicitly
   legitimate verdict — inventing findings to fill a report is a review
   failure.
4. **Controller triages:**
   - Critical and Important findings: dispatch **ONE fix subagent per round**
     with the complete list (never one fixer per finding). The fix subagent
     carries the implementer contract: minimal fixes, re-run the covering
     tests, append results to the fix-report file
     (`<branch-slug>-fix-reports.md` beside the log), commit. OR reject a
     finding as a false positive **with a stated reason** in the log — never
     silently dropped.
   - A finding that conflicts with what the plan's text requires
     (plan-mandated) is the user's decision: present finding and plan text,
     ask which governs. **In Batched Autonomous Mode:** journal it under
     `## Open Issues` and end the batch.
   - Minor findings: fix at the controller's discretion or log as carried;
     always logged with disposition.
5. **Append a round entry** to the review log (format below).
6. **Convergence check:** identical semantics to `multi-review`. A round is
   *clean* when its reviewer's **enumerated findings** (never the count
   line; never post-triage) contain zero Critical and zero Important. Exit
   early only after **two consecutive clean rounds**. Rejections and
   user-decision findings never make a round clean. An `inconclusive` round
   breaks the streak. With N ≤ 2 no mid-loop exit; still report "converged"
   if the final two rounds were clean; N = 1 always reports "cap reached".

**After the loop** (converged or cap reached): report to the host gate —
rounds run, per-round finding counts by severity, fixes applied (commit
SHAs), unresolved user-decision items, converged vs cap reached, log path.
SDD then proceeds to subagent shutdown and `finishing-a-development-branch`
only when no unresolved Critical/Important or user-decision items remain
(unresolved items block, exactly as unresolved review findings do today).

**Once per gate:** if the log already holds an invocation entry from
`gate: sdd` for this branch, the SDD gate does not re-run the loop (survives
session restarts). Re-run only on explicit user request.

## Lens Rotation

One reviewer per round, each round a different lens. Every lens instruction
carries a **prose adaptation**: this repository's branches are often
Markdown-heavy (skills, prompts, configs), where runtime-input attacks are
vacuous. For files that are instructions to an agent rather than executable
code, the lens targets *agent misexecution* instead.

| Round | Lens | Code focus | Prose/instruction-file adaptation |
|---|---|---|---|
| 1 | Correctness & spec alignment | `code-reviewer.md` rubric: findings vs the plan (missing/extra/misunderstood), logic errors, error handling; plus carried-Minor triage | Steps that contradict the plan or each other; instructions an executing agent would apply incorrectly |
| 2 | Adversarial red-team | `agents/red-team.md` categories: concrete breaking inputs, state sequences, races, partial-failure states, production-context mismatches — with reproducible triggers | How does an agent following this text go wrong? Misreadable steps, orderings that break, vacuously-passing verifications |
| 3 | Security | `requesting-code-review` checklist: OWASP/CWE, injection, auth flows, secrets handling, dependency CVEs, logging hygiene | Instructions that lead an agent to unsafe actions: destructive commands, secret exposure, unbounded scope (e.g. `git add -A` over sibling work) |
| 4 | Test & coverage quality | Weak assertions, mock-only tests, untested error paths, tests that assert nothing, missing edge cases from the plan | Verification commands that pass vacuously; asserted strings that drift from the text they check |

With the default N = 3, lens 4 runs only at N ≥ 4 or when findings keep the
loop alive past a cycle — accepted, because SDD's per-task reviews already
gated test quality with TDD evidence.

## Reviewer Report Contract

The reviewer's final message is the report. Its **first line is the marker**
`<!-- multi-review report -->` — reusing the existing guard-exempt marker
(see Guard Interaction). Then, no preamble, no narration:

```
### Verdict
Critical: <n> | Important: <n> | Minor: <n>
(or exactly: "No material issues under this lens.")

### Findings
#### Critical
- [C1] file:line — <what is wrong> | <why it matters> | <suggested fix>
#### Important
- [I1] ...
#### Minor
- [M1] ...

### Checks Run
- <named risk> → <what was checked outside the diff, if anything>

### Carried Findings Triage   <!-- round 1 only, when a carried list was passed -->
- <carried finding> → recommend: fix-before-merge | ship-as-is | user-decision, <one-line reason>
```

The triage recommendations are input to the controller's disposition — the
controller decides and logs; the reviewer only recommends.

The **enumerated findings are authoritative**; the Verdict count line is
informational and the controller recomputes on disagreement. "No material
issues under this lens." is used only with **zero findings of any severity**;
a Minor-only round reports counts with empty Critical/Important sections.
Every finding must carry a file:line reference into the diff.

Calibration (adapted from `task-reviewer-prompt.md`): **Critical** = merging
this would ship broken, insecure, or data-corrupting behavior. **Important**
= the branch cannot be trusted until fixed — incorrect or fragile behavior,
a missed plan requirement, maintainability damage you would block a merge
over. **Minor** = polish, "coverage could be broader". A plan-mandated
defect is still reported (Important, labeled plan-mandated) — the plan's
authorship does not grade its own work.

**Guard Interaction:** `hooks/subagent-guard.js` already exempts final
messages opening with `<!-- multi-review report -->` from skill-leakage
blocking. This skill reuses that marker verbatim — code reviews in this
repository legitimately quote skill names — so the exemption logic is
unchanged. The guard's `SKILL_NAMES` roster gains `multi-code-review` so the
new skill stays inside the guard's coverage (one-line roster change + unit
test; precedent: `multi-review` added itself the same way).

## Review Log (Audit Trail)

Sidecar file `.superpowers/reviews/<branch-slug>-review-log.md` (git-ignored
scratch, same class as the SDD ledger; destroyed by `git clean -fdx`,
acceptable). `<branch-slug>` = `git rev-parse --abbrev-ref HEAD` with every
non-alphanumeric run replaced by `-`; detached HEAD →
`detached-<short-sha>`. Fix reports live beside it as
`<branch-slug>-fix-reports.md`.

Created on invocation — including an N=0 skip (one-line `skipped` entry).
Round numbering continues across invocations; lens selection uses the
per-invocation round index (as in `multi-review`). Each invocation note
records date, N, BASE..HEAD, and invoker (`gate: sdd` | `direct`). Per
round:

```
## Round <i> — <lens name> — <model>
**Reviewer verdict:** <n> Critical, <n> Important, <n> Minor
**Converged:** yes/no
### Dispositions
- [C1] fixed — <finding summary> → <fix commit sha>
- [I1] rejected: <reason> — <finding summary>
- [I2] user-decision — <finding summary> (plan-mandated)
- [M2] carried — <finding summary>
```

A clean round writes exactly one disposition line:
`- none — no material issues under this lens`. Model substitutions (sonnet
floor) are noted on the round header line. Reviewers are barred from reading
`*-review-log.md` and `*-fix-reports.md`.

## Error Handling

- **Unusable report** (missing marker or Verdict block): retry the identical
  dispatch once; on second failure log the round `inconclusive` (never
  clean) and continue.
- **Empty range** (BASE = HEAD or no merge-base): stop and report; nothing
  dispatched.
- **`review-package` script missing or failing** (e.g. direct invocation on
  a machine without the SDD skill installed): fall back to instructing the
  reviewer to fetch the diff itself (`git diff --stat BASE..HEAD` and
  `git diff BASE..HEAD`) — the failure fallback already defined in
  `task-reviewer-prompt.md` — and log the fallback.
- **Fix subagent fails or its covering tests fail:** re-dispatch once with
  the failure appended; on second failure treat the affected findings as
  unresolved (they block the gate) and continue the loop — later rounds
  review the branch as-is.
- **Invalid N** → 3. **N = 0** → skip, log.

## Files

**New:**
- `skills/multi-code-review/SKILL.md` — controller: parameters, loop, lens
  rotation, triage/fix rules, convergence, log format, gate notes.
- `skills/multi-code-review/reviewer-prompt.md` — dispatch template in the
  `task-reviewer-prompt.md` style: `[PLACEHOLDER]` slots (`[PACKAGE_FILE]`,
  `[BASE_SHA]`, `[HEAD_SHA]`, `[LENS_NAME]`, `[LENS_INSTRUCTIONS]`,
  `[PLAN_PATH]`/`[CARRIED_MINORS]` for round 1, `[MODEL]`), Subagent Rules
  block, marker instruction, diff-only discipline, calibration, fixed output
  format.

**Modified:**
- `skills/subagent-driven-development/SKILL.md` — Core Flow step 4 and the
  digraph's "Final whole-branch review" node point to the loop; Integration
  section replaces the `requesting-code-review/code-reviewer.md` reference;
  Model Selection amends the "always opus" sentence to the session-inherit +
  sonnet-floor rule; Batched Autonomous Mode plan-complete path runs the
  loop autonomously (default N, user-decision findings → journal + end
  batch); Constructing Reviewer Prompts final-review bullets updated.
- `hooks/subagent-guard.js` — `SKILL_NAMES` roster gains `multi-code-review`
  (exemption logic unchanged).
- `tests/codex/test-subagent-guard.js` — roster assertion for the new name.
- `hooks/skill-rules.json` — register `multi-code-review`: keywords
  ("multi code review", "review the branch", "independent code reviews",
  "several code reviews", "final review rounds") and intent patterns (e.g.
  `review\s+(the\s+)?branch\s+(again|\d+\s+times)`,
  `(several|multiple)\s+(independent\s+)?(final\s+|whole.?branch\s+)?code\s+reviews`).
- Release bookkeeping per repo policy: `VERSION`,
  `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  (+ `plugin.universal.yaml` meta), `RELEASE-NOTES.md` entry.

## Testing Strategy

- **Unit** (`tests/codex/run-unit-tests.sh`): subagent-guard roster
  assertion for `multi-code-review`; skill-rules.json structure and routing
  patterns validated by the existing harness.
- **Behavioral** (`tests/claude-code/`, slow suite):
  `test-multi-code-review.sh` — seed a temp git repo with a base commit and
  a branch containing a planted defect (e.g. a function with an off-by-one
  and a test asserting nothing), invoke `/multi-code-review <base> 2`
  headlessly, assert: (a) `.superpowers/reviews/*-review-log.md` exists with
  ≥1 round entry, (b) every Critical/Important in the log carries a
  `fixed`/`rejected: <reason>`/`user-decision` disposition, (c) a fix commit
  exists OR all findings were rejected/user-decision. Follow existing
  harness rules: `timeout` shim, `--verbose` with stream-json, no hardcoded
  git history assertions.
- **Triggering** (`tests/skill-triggering/`): naive-prompt case ("run
  several independent code reviews on this branch").
- **Manual gate check** after plugin reinstall: run an SDD plan end-to-end
  on a toy feature and confirm the loop fires at the final gate.

## Limitations (accepted, documented)

- **Session-model inheritance weakens the gate vs the old always-opus rule**
  when the session runs sonnet. The sonnet floor bounds the worst case;
  users wanting the strongest gate run the session (or ask for the loop) on
  opus. Explicit user decision.
- **Convergence can be unreachable**: a branch with a standing user-decision
  (plan-mandated) finding reports "cap reached" every run. Intended
  behavior — the human decision is the exit, not more rounds.
- **A fix can introduce a regression visible only under an already-run
  lens.** Every fix is reviewed by at least the next round(s) on the updated
  branch, but under *different* lenses; exit requires two clean rounds after
  the last fix. Residual risk accepted (same class as `multi-review`).
- **Very large diffs** may exceed what one reviewer reads well; the package
  format (stat summary first) lets the reviewer prioritize, but coverage of
  huge branches is best-effort. Pre-existing limitation of the single-pass
  final review, not introduced here.
- **Independence is enforced by prompt, not sandbox** — a reviewer with repo
  read access could in principle encounter the log. Accepted residual risk.
- **Claude Code only.** Codex/Cursor SDD runs keep the single-pass final
  review.
