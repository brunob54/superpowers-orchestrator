# Reviewer harness claims — test, do not assert

**Topic:** `reviewer-harness-claims` · **Date:** 2026-08-30 · **Status:** approved design

## Problem

A reviewer subagent in `multi-doc-review` or `multi-code-review` sometimes
bases a finding on a claim about the **harness** — the agent runtime that
runs the pipeline (Claude Code, Codex, Copilot CLI, OpenCode): what reaches a
subagent's context, what a hook injects, how a tool call behaves, what an
environment variable does at run time. Such a claim is not visible in the
document or the diff under review, so the reviewer cannot point at a line
that proves it, and today nothing requires the reviewer to test it.

Recorded cost (`docs/orchestration-issues.md`, Case 003, finding R6 `[I1]`):
a reviewer asserted that the Agent `description` field reaches the
reviewer's context, so the `(reviewer j/m)` suffix would leak M. The loop
escalated the finding to the user. A three-second probe — a subagent
dispatched with a canary token in its description only — showed the token
absent. The claim was false, and one full stop of an unattended run was
spent on it.

Both reviewer templates now carry that probe's result as a comment
("verified 2026-08-28 … canary token … Re-test if the harness changes how a
dispatch label is delivered"). That protects one claim. This design
generalises it: **a finding that rests on a harness property must carry a
test of that property, or must say exactly which test is missing.**

## Scope

Four files, wording only:

- `skills/multi-doc-review/reviewer-prompt.md` — new reviewer rule inside
  the `prompt:` block, plus the finding format extension.
- `skills/multi-code-review/reviewer-prompt.md` — same rule, same extension.
- `skills/multi-doc-review/SKILL.md` — controller triage step for tagged
  findings.
- `skills/multi-code-review/SKILL.md` — controller triage step for tagged
  findings, including the `user-decision` guard.

Plus one new fast test file (see Testing strategy) and its line in
`CLAUDE.md`'s Testing block.

## Non-goals

- No change to lenses, severities, convergence rules, or the review-log
  format beyond the new disposition reasons named below.
- No new hook, script, or `hooks/skill-rules.json` entry — routing is
  unchanged.
- No behavioural test run (real `claude` sessions) for this change. The
  behavioural suites must not run concurrently with a review loop
  (`docs/orchestration-issues.md`, worklist item 4); the fast test below is
  the verification for this change. A behavioural check of the new wording
  is a separate, later task.
- No version bump, release-notes entry, or `docs/guide/` update inside this
  change: releasing is decided after the branch outcome (merge / PR / keep /
  discard) and follows the release checklist in `CLAUDE.md`.
- The worklist row in `docs/orchestration-issues.md` (item 2) is a local,
  untracked file and is edited by hand after the run, not by the
  implementation.
- Claims about the **code or document under review** are unchanged: they
  keep the existing rule (a file:line or section reference). This design is
  only about claims whose truth lives in the runtime, not in the
  repository.

No decision in this design matched the prior-art trigger predicate.

## Definitions

- **Harness property**: a statement about how the agent runtime behaves
  when the pipeline runs — for example: which fields of an Agent dispatch
  reach the child's context; what a hook injects and when; whether a
  nested dispatch blocks; what an environment variable changes at run time;
  what a tool returns. Its truth cannot be read from the repository; it can
  only be observed by running the harness.
- **Probe**: one action — one command, one dispatch of a throwaway
  subagent, or one read of the prober's own context — that observes the
  harness property directly and whose result answers the claim. An
  observation is **unambiguous** when it can be written in one clause that
  either matches or contradicts the result the claim predicts; anything
  else is ambiguous. The canary-token dispatch above is the model probe.
- **Reviewer-safe probe**: a probe the reviewer may run itself. It must
  (a) write nothing to the checkout, the index, HEAD, or branch state;
  (b) bind no shared resource (fixed port, fixed temporary path, shared
  database); (c) run no code from the change under review (the branch, or
  the repository a document describes); and (d) dispatch no subagent. Examples: reading the reviewer's own context for an expected
  string; printing an environment variable; reading the installed plugin's
  files; running a command that is not part of the branch. Anything else
  is a **controller probe**.

Rule (d) exists because a reviewer is itself a child of a controller: a
subagent dispatched from a reviewer runs detached in Claude Code
(`docs/orchestration-issues.md`, Case 002), so a reviewer that dispatches
one may end its turn waiting and stall the round. The controller is named
and its dispatches block (v7.5.0), so a probe that needs a dispatch runs
there, once — the same rule the templates already state for anything that
must actually run.

## Approaches considered

1. **Reviewer-side rule only.** Require the reviewer to probe; an
   unprobed harness claim is capped at Minor. Simple, but a reviewer often
   cannot run the decisive probe (rule (d) above; a platform without an
   Agent tool — `researching-prior-art` calls this degradation rung 3;
   which platforms fall there is not asserted here), and capping severity
   hides a possibly true Critical claim.
2. **Reviewer tags, controller probes. (chosen)** The reviewer marks every
   harness-based finding with the probe it ran and what it observed — or,
   when the probe is not reviewer-safe, with the exact probe the controller
   should run. The controller runs a named probe once before triage and
   disposes of the finding on the observed result. An untested claim never
   reaches `user-decision`, and a claim nobody can test here never blocks:
   it is rejected with its probe recorded, and listed in the completion
   report so the user can run the probe.
3. **Controller-only detection.** The controller inspects every finding for
   a harness premise. Rejected as the primary mechanism: the reviewer knows
   its own premises; the controller would have to guess from prose and
   would miss cases. It survives only as the backstop in Design §3 step 3,
   for the one case that would otherwise halt a run.

Approach 2 keeps the reviewer honest at the source (it must say what its
claim rests on) and places the only action that can run in the one agent
already allowed to run things.

## Design

### 1. Reviewer rule (both `reviewer-prompt.md`, inside the `prompt:` block)

A new sub-section of `## Subagent Rules`, titled **Harness claims**, with
this content (final wording is the plan's; the properties below are
normative):

- Defines *harness property* and *probe* as above, in two sentences.
- States the rule: a finding whose premise is a harness property MUST
  either carry a reviewer-safe probe the reviewer ran and its observation,
  or name the single probe the controller should run. A harness claim
  without either is not a finding; drop it.
- States the four reviewer-safe conditions (a)–(d) verbatim, and that
  everything else is a controller probe.
- Gives the model probe inline, in one clause — for example: "a subagent
  dispatched with a token only in its `description` reports the token
  absent from its context". The canary note in the template's
  `description:` comment stays as it is, but it is outside `prompt: |` and
  never reaches the reviewer, so the rule cannot point at it.
- One probe per finding. A claim that one probe cannot settle is tagged
  `harness: untested — not settled by one probe; first: <probe>` so the
  controller takes the "not runnable here" branch (§3) instead of treating
  a partial result as support.
- Any allowance elsewhere in the prompt to run a focused test is never a
  probe: condition (c) governs every harness claim, and that allowance
  stays what it is — for doubts about the change under review, not about
  the runtime. (Written in this template-neutral form: the rule text is
  identical in both templates — Testing strategy item 5 — and only the
  code-review template has a `## Tests` section.)
- Placement: the rule is the last sub-section under `## Subagent Rules`,
  immediately before the prompt's next level-two heading, in both
  templates.

### 2. Finding format extension (both `reviewer-prompt.md`)

Each finding line keeps its existing shape and gains an optional trailing
field:

```
| harness: tested — <probe in one clause>; observed <result>
| harness: untested — <the one probe the controller should run>
```

The field appears only on findings whose premise is a harness property.
The existing reference sentence of each template is kept — "Every finding
must reference a section or line of the target document." (doc review) and
"Every finding must carry a file:line reference into the diff." (code
review); the harness field is in addition to, not instead of, that
reference.
In `multi-code-review` a reviewer-run probe is also listed under
`### Checks Run` (the section already exists for "what was checked outside
the diff").

### 3. Controller triage (both `SKILL.md`)

A new numbered step in each skill's triage procedure, placed before the
existing dispositions are chosen. In `multi-doc-review` this amends the
triage sentence "Every Critical/Important finding is either applied to the
document or `rejected: <reason>`" — the amendment adds no disposition; the
harness branch below always ends in one of those two.

1. For every finding carrying `harness: untested — <probe>` — **except**
   one tagged `not settled by one probe`, which goes straight to the "not
   runnable here" branch of step 2 (its `first: <probe>` text is used only
   to fill the `Harness probes owed:` line) — run that probe once,
   yourself. Controller probe constraints: it writes nothing to the
   checkout, the index, HEAD, or branch state; binds no shared resource
   (fixed port, fixed temporary path, shared database); runs no code from
   the change under review; and consists of one action — one command, one
   read of your own context, or one dispatch of a throwaway subagent whose
   prompt is self-contained and that writes nothing. **Dispatch rule:** run
   a dispatch-based probe only when you know the dispatch will complete
   within your own turn — you are the main session (the Agent tool's result
   or a task notification comes back to you), or your own prompt states
   that you were dispatched with a `name:` (the `orch-*` controllers of
   `orchestrating-development`, whose dispatches block since v7.5.0). An
   unnamed subagent's child runs detached and its completion never reaches
   the subagent (Case 002); when you cannot tell which case you are in,
   take the "not runnable here" branch with the reason `dispatch would not
   block`. The reviewer's condition (d) exists for exactly this reason and
   does not apply to a controller that passes the dispatch rule.
2. Dispose on the observation:
   - Observation contradicts the claim → `rejected: harness probe —
     <observation>`.
   - Observation supports the claim → triage the finding as if it had
     been `harness: tested`; the ordinary rules apply from here. The
     observation is recorded on the disposition line as a trailing clause
     `— harness probe: <observation>`, placed before any source annotation
     (` ← a/m: …`), whatever the disposition (`applied`, `fixed`,
     `user-decision`, …). The fix subagent of `multi-code-review` does not
     receive the harness field or the observation: it fixes the code, and
     the finding text it receives already states what to change.
   - The probe cannot be run here (tool missing, a platform without
     nested dispatch, the dispatch rule of step 1 fails, the reviewer
     tagged it "not settled by one probe", the probe would break a
     constraint above, or the observation is ambiguous as defined under
     Definitions) → `rejected: harness probe not runnable here — <probe>` in
     both skills. This is the existing "reject as unverifiable" path of
     `multi-code-review` ("you may reject it as unverifiable, logging that
     reason") applied with the probe text kept, and it is **not blocking**:
     `unresolved` and `user-decision` both stop the host gate, and a stop
     for a claim with a ready three-second probe is the cost this design
     removes. Every such rejection is also listed in the skill's
     completion report: a line `Harness probes owed:` followed by one item
     `- [id] <probe>` per rejection, or `Harness probes owed: none` when
     there is none — the line is always written, so its absence in a report
     is itself a defect. The user sees the probes at the after-loop report
     and can run them.
3. `multi-code-review` only — the guard: a finding is never logged
   `user-decision` on the strength of an untested harness claim. Before any
   `user-decision` the controller asks whether the finding's premise is a
   harness property. If it is and the reviewer tagged it, step 1 applies
   first; only a *supported* claim can then become `user-decision`. If it
   is and the reviewer did **not** tag it, the controller names one probe
   itself when one exists within the constraints of step 1 and runs it;
   when it cannot name one, the "not runnable here" branch applies with the
   reason `no probe named`. This is the backstop mentioned under Approaches
   — controller detection is never the primary mechanism, only the last
   check before the one disposition that halts a run. The guard applies to
   every `user-decision` disposition, including one reached through the
   carried-findings path (round 1 of a resumed loop, decided from reviewer
   recommendations): a carried item whose premise is a harness property is
   checked the same way before it is logged `user-decision`.

A finding carrying `harness: tested — …` is triaged normally, and its
observation is accepted: the rule exists to keep claims tested, and to keep
reviewers from stalling a round, not to re-verify every observation. When
the stated probe was not reviewer-safe (for example the reviewer dispatched
a subagent), the controller still accepts the observation and appends
`(reviewer probe not reviewer-safe)` to the disposition line. The
controller may re-run a probe when the observation looks inconsistent with
the reviewer's conclusion, but is not required to.

### 4. Data flow

```
reviewer  ──finding + harness field──▶  controller
                                          │ untested → run probe once
                                          │ tested   → normal triage
                                          ▼
                                    review log: disposition + observation
```

Nothing new crosses the reviewer/controller boundary except the trailing
field on a finding line; the log gains two reason strings
(`harness probe — …`, `harness probe not runnable here …`), one trailing
clause (`— harness probe: <observation>`), and each completion report gains
the `Harness probes owed:` line.

## Interfaces and contracts

- Finding line: existing format + optional `| harness: tested — …` or
  `| harness: untested — …`. The parser is a model, not code; the field
  is at the end so existing log-grepping tests (which match `^- \[C1\]
  applied`, `fixed — `, `rejected: `, `user-decision`, `unresolved: `) are
  unaffected.
- Dispositions: unchanged set, and the harness branch uses only
  `rejected: <reason>` — never `deferred`, `unresolved`, or
  `user-decision`, so no Critical/Important finding is deferred (which
  `multi-doc-review` forbids) and nothing new blocks a gate. Reason strings
  after `rejected:` are free text today and stay so.
- The `## Shared checkout — read-only inspection only` section and the
  blinding pathspec line in `multi-code-review/reviewer-prompt.md` are not
  touched (the `tests/sdd-scripts` drift check asserts the pathspec text
  verbatim).
- The `<!-- multi-review report -->` marker instruction is not touched
  (`tests/codex/test-subagent-guard.js` depends on it).

## Error handling

- Reviewer cannot tell whether a premise is a harness property: the rule
  gives the test — "can its truth be read from the repository?" If no, tag
  it. Over-tagging costs one controller probe; under-tagging is caught by
  the controller guard (step 3) for the only case that halts a run.
- Probe result is ambiguous: treated as "cannot be run here" —
  `rejected: harness probe not runnable here — <probe>` — never as support
  for the claim.
- Controller probe would break the shared-checkout rule: it is not run;
  same disposition as "cannot be run here".

## Testing strategy

One new fast test file, pure bash, no `claude` invocation:
`tests/reviewer-templates/run-tests.sh`, listed in `CLAUDE.md`'s Testing
block next to the other fast suites. It asserts, on the repository's own
files:

1. Both `reviewer-prompt.md` files contain the `Harness claims` rule
   **inside** `prompt: |` (the rule must reach the reviewer): the line of
   its heading is greater than the line of `prompt: |` and lower than the
   line of the closing fence — the first line matching `^```` after
   `prompt: |` (each file has two fence lines). The `description:` comment
   is inside the fence too but above `prompt: |`, so a rule placed there
   fails.
2. Both reviewer templates contain the two field spellings
   `harness: tested —` and `harness: untested —`.
3. Both `SKILL.md` files contain the controller step's two reason strings
   (`harness probe —` and `harness probe not runnable here`) and the
   completion-report line `Harness probes owed:`.
4. `multi-code-review/SKILL.md` contains the guard fragment `never logged
   \`user-decision\` on the strength of an untested harness claim`.
5. Drift: the `Harness claims` rule text is identical in the two reviewer
   templates. The rule is a level-three heading indented four spaces inside
   the prompt block (`    ### Harness claims`) and, by the placement rule
   of §1, the last sub-section before the next level-two heading; extract
   from that line up to, but not including, the next line matching
   `^    ## ` in each file, and compare with `diff`.
6. Unchanged contracts: the blinding pathspec line and the
   `<!-- multi-review report -->` instruction still appear in
   `multi-code-review/reviewer-prompt.md` (guards the surgical-edit
   requirement).

Existing fast suites (`tests/codex/run-unit-tests.sh`,
`tests/smart-compress/run-tests.sh`, `tests/sdd-scripts/run-tests.sh`) must
still pass. Behavioural suites are a non-goal (see above).

## Failure-mode check

1. **A reviewer asserts a harness property without tagging it** (Critical
   if it reaches `user-decision`). Mitigated by the controller guard (§3
   step 3): before any `user-decision` the controller asks whether the
   premise is a harness property and, if so, names and runs one probe
   itself or takes the "not runnable here" branch. Residual: a mis-tagged claim
   that never escalates costs at most one wrong `applied`/`fixed`, which
   the next round's reviewer sees. Accepted as Minor.
2. **The controller's probe itself stalls the round** — a probe that needs
   a dispatch. Mitigated: controller dispatches block since v7.5.0 (named
   controller); the probe is "once, bounded"; if a probe needs more than one
   action it is not run. Residual risk on platforms whose dispatch does not
   block: covered by "cannot be run here". Minor.
3. **Reviewer-safe probes perturb the checkout** (a reviewer runs something
   that writes). Mitigated by conditions (a)–(c), which restate the existing
   shared-checkout rule inside the prompt block, where the reviewer reads
   it. Minor.
4. **The rule grows the reviewer prompt enough to dilute attention.**
   Bounded: the rule is one short sub-section and one optional field; the
   plan should keep it near 15 lines, as a guideline that no test asserts.
   Accepted.

## Rollout

No migration. The change is live for any session once the plugin copy is
reinstalled (editing `skills/` here does not change running sessions —
`CLAUDE.md`). Existing review logs are unaffected: the new field and reason
strings only appear in rounds run after the change.
