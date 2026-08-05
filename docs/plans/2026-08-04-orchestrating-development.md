# Orchestrating-Development Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-optimized:subagent-driven-development (recommended) or superpowers-optimized:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `orchestrating-development` skill: a fully autonomous spec→plan→review→implement→review pipeline driven by fresh-context controller subagents.

**Spec:** `docs/specs/2026-08-04-orchestrating-development-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews)*

**Architecture:** A new skill directory holds the orchestrator procedure (SKILL.md) and four controller prompt templates; controllers consume the existing skills' SKILL.md files read-only as procedure sources. One hook behavior change (`subagent-guard.js` gains an `<!-- orchestration report -->` exempt marker) and one routing entry (`skill-rules.json`) wire it in; everything else is additive. TDD applies to the two JS-touching tasks; markdown tasks verify via grep assertions.

**Tech Stack:** Markdown skill files; Node >= 16 hooks and unit tests (`tests/codex/`); bash test runners.

**Assumptions:**
- Assumes the Agent tool with nested dispatch (subagent spawning subagents), verified in this environment 2026-08-04 — will NOT work on Codex/Cursor; the skill refuses there.
- Assumes plans follow writing-plans' Task Template (`### Task N:` headings with `- [ ]` step checkboxes) — the task-complete predicate is defined against that shape.
- Assumes `subagent-guard.js` remains a final-message text matcher — the marker exemption is meaningless if the guard mechanism changes.

**Global Constraints:**
- Every controller return's FIRST line is exactly `<!-- orchestration report -->`; the contract's leading token is the next line; hard return cap 15 lines.
- Return tokens are exactly `PLAN_READY`, `REVIEW_DONE`, `BATCH_COMPLETE`, `BLOCKED` — the orchestrator parses these strings; templates and SKILL.md must match character-for-character.
- Controllers never use the Skill tool and never write `state.md`; nested worker prompts include SDD's leakage-prevention line.
- Parameters: N_plan and N_code are integers 0–10 (default 3); batch cap is an integer 1–5 (default 3). Invalid → default. N=0 → orchestrator skips the phase itself (no controller dispatched).
- Orchestration log path: `docs/plans/YYYY-MM-DD-<slug>-orchestration-log.md`; branch `feature/<slug>`; `<slug>` = spec basename with `YYYY-MM-DD-` prefix and `-design` suffix each stripped only if present.
- The four consumed skills (`writing-plans`, `multi-doc-review`, `subagent-driven-development`, `multi-code-review`) are NOT edited — controllers reference their SKILL.md files by path (`../<skill-name>/SKILL.md` relative to this skill's base directory).
- Hooks stay cross-platform (Node >= 16, no `/dev/stdin`); the guard change is inside `hooks/subagent-guard.js` only — no hook wiring files change.
- Release = version bump in `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, README version badge, plus a `RELEASE-NOTES.md` entry. Target version: **6.14.0**.

---

## File Structure

| File | Responsibility |
|---|---|
| `hooks/subagent-guard.js` | (modify) exempt `<!-- orchestration report -->`; header records sanctioned controller nested dispatch |
| `tests/codex/test-subagent-guard.js` | (modify) unit tests for the new marker |
| `hooks/skill-rules.json` | (modify) routing entry for orchestrating-development |
| `tests/codex/test-skill-activator.js` | (modify) routing-rank tests via `topSkill()` |
| `skills/orchestrating-development/SKILL.md` | (create) orchestrator procedure: phases 0–5, contracts, log format, resume/abandon, stop policy |
| `skills/orchestrating-development/plan-writer-prompt.md` | (create) Phase 1 controller template |
| `skills/orchestrating-development/doc-review-loop-prompt.md` | (create) Phase 2 controller template |
| `skills/orchestrating-development/batch-controller-prompt.md` | (create) Phase 3 controller template |
| `skills/orchestrating-development/code-review-loop-prompt.md` | (create) Phase 4 controller template |
| `skills/brainstorming/SKILL.md` | (modify) one line in the User Review Gate message |
| Version files + `RELEASE-NOTES.md` + `README.md` | (modify) v6.14.0 |

Tasks 1 and 2 touch disjoint files but SHARE the unit-test suite — do NOT run them concurrently in one working tree (Task 2's full-suite step fails spuriously while Task 1 sits between its failing-test and implementation steps); run them sequentially, in either order. Tasks 3–7 create independent files (SKILL.md names the template files; keep names exactly as above). Task 8 is independent. Tasks 9–10 run last, in order.

---

### Task 1: Guard exempt marker for controller returns (TDD)

**Files:**
- Modify: `hooks/subagent-guard.js`
- Test: `tests/codex/test-subagent-guard.js`

**Security flag:** `security` *(the guard is a defense layer; widening an exemption is a permission-boundary change)*

**Does NOT cover:** exempting SDD's nested task-reviewer reports (spec lists that as a known inherited exposure, follow-up only); any change to violation patterns, verbs, or the roster list.

- [x] **Step 1: Write failing tests**

Append to `tests/codex/test-subagent-guard.js`, immediately after the existing multi-review-marker test section (search for `'<!-- multi-review report -->'` tests, add after that section, before the final summary/exit lines):

```js
// ── Orchestration report marker ──────────────────────────────────────────────

console.log('\nOrchestration report marker');

test('orchestration-marked BLOCKED return naming a skill is allowed', () => {
  const out = runGuard([
    '<!-- orchestration report -->',
    'BLOCKED task=3: plan says use executing-plans semantics but the spec forbids it — which governs?',
  ].join('\n'));
  assert.deepStrictEqual(out, {});
});

test('same skill-naming BLOCKED text without the marker is blocked', () => {
  const out = runGuard(
    'BLOCKED task=3: plan says use executing-plans semantics but the spec forbids it — which governs?'
  );
  assert.strictEqual(out.decision, 'block');
});

test('orchestration marker after the first line does not exempt', () => {
  const out = runGuard('I was using executing-plans.\n<!-- orchestration report -->');
  assert.strictEqual(out.decision, 'block');
});

test('leading whitespace before the orchestration marker still exempts', () => {
  // Body must contain a verb+skill pair so this fails on the unmodified
  // guard — a benign body would pass vacuously.
  const out = runGuard(
    '  <!-- orchestration report -->\nBLOCKED task=3: plan says use executing-plans semantics'
  );
  assert.deepStrictEqual(out, {});
});
```

- [x] **Step 2: Run tests to verify the new ones fail**

Run: `node tests/codex/test-subagent-guard.js`
Expected: FAIL — exactly 2 new failures ("…is allowed" and "leading whitespace…" get `decision: 'block'` instead of `{}`); the two negative tests already pass. All pre-existing tests still pass.

- [x] **Step 3: Implement the marker exemption**

In `hooks/subagent-guard.js`:

(a) Replace the constant block

```js
const REVIEW_REPORT_MARKER = '<!-- multi-review report -->';
```

with

```js
const REVIEW_REPORT_MARKER = '<!-- multi-review report -->';

// Orchestrating-development controller subagents return status contracts whose
// free text (e.g. a BLOCKED reason quoting a plan conflict) may legitimately
// pair action verbs with skill names. A genuine controller return opens with
// this exact marker (the skill's prompt templates make it the mandatory first
// line); anything after the start of the message does not count.
const ORCHESTRATION_REPORT_MARKER = '<!-- orchestration report -->';
```

(b) Replace the exemption check

```js
      if (lastMessage.trimStart().startsWith(REVIEW_REPORT_MARKER)) {
        process.stdout.write('{}');
        return;
      }
```

with

```js
      const trimmedMessage = lastMessage.trimStart();
      if (
        trimmedMessage.startsWith(REVIEW_REPORT_MARKER) ||
        trimmedMessage.startsWith(ORCHESTRATION_REPORT_MARKER)
      ) {
        process.stdout.write('{}');
        return;
      }
```

(c) In the header comment (lines 2–14): append this sentence immediately after the line ending "…without skill invocations." (the end of the first paragraph; note "spawn recursive sub-subagents" sits mid-paragraph — do not insert there). Keep the block comment's ` * ` prefix on each inserted line:

```
Exception: orchestrating-development dispatches controller subagents that
intentionally spawn nested workers — that is sanctioned design, not leakage;
controller returns are exempted via the orchestration report marker below.
```

- [x] **Step 4: Run tests to verify all pass**

Run: `node tests/codex/test-subagent-guard.js`
Expected: PASS — 0 failed, including all pre-existing tests.

- [x] **Step 5: Commit**

```bash
git add hooks/subagent-guard.js tests/codex/test-subagent-guard.js
git commit -m "feat(guard): exempt orchestration report marker; record sanctioned controller nesting"
```

---

### Task 2: Routing entry + rank tests (TDD)

**Files:**
- Modify: `hooks/skill-rules.json`
- Test: `tests/codex/test-skill-activator.js`

**Security flag:** `none`

**Does NOT cover:** routing for phrasings that never name orchestration or a pipeline (e.g. "do everything automatically") — below the activator's confidence threshold by design; behavioral prompt files in `tests/skill-triggering/` (deferred per spec Testing Strategy).

- [x] **Step 1: Write failing rank tests**

In `tests/codex/test-skill-activator.js`, after the existing `topSkill()` rank-test section (search for `function topSkill(prompt)`; append after the last test in that section):

```js
// ── orchestrating-development routing ────────────────────────────────────────

const ORCH = 'orchestrating-development';

test('"orchestrate the development of <spec>" ranks orchestrating-development first', () => {
  assert.strictEqual(
    topSkill('orchestrate the development of docs/specs/2026-08-04-foo-design.md'), ORCH);
});

test('"run the whole pipeline autonomously from the spec" routes to orchestrating-development', () => {
  assert.strictEqual(topSkill('run the whole pipeline autonomously from the spec'), ORCH);
});

test('"Resume orchestration for <plan>" routes to orchestrating-development, not SDD', () => {
  assert.strictEqual(topSkill('Resume orchestration for docs/plans/2026-08-04-foo.md'), ORCH);
});

test('"Abandon orchestration for <plan>" routes to orchestrating-development', () => {
  assert.strictEqual(topSkill('Abandon orchestration for docs/plans/2026-08-04-foo.md'), ORCH);
});

test('"orchestrate it" (the brainstorming-gate reply phrase) routes to orchestrating-development', () => {
  assert.strictEqual(topSkill('orchestrate it'), ORCH);
});

test('bare "orchestrate" scores below threshold and routes nowhere', () => {
  assert.strictEqual(topSkill('orchestrate'), null);
});

test('non-regression: "execute the plan in batches" still ranks SDD first', () => {
  assert.strictEqual(topSkill('execute the plan in batches'), SDD);
});

test('non-regression: "resume the plan at <path>" still routes to SDD', () => {
  assert.strictEqual(
    topSkill('Resume the plan at docs/plans/2026-08-04-foo.md (batched autonomous mode)'), SDD);
});
```

- [x] **Step 2: Run tests to verify the new ones fail**

Run: `node tests/codex/test-skill-activator.js`
Expected: FAIL — the five positive ORCH tests fail (skill unknown → `null` or another skill ranks first); the bare-orchestrate and two non-regression tests already pass. No pre-existing test fails.

- [x] **Step 3: Add the rules entry**

In `hooks/skill-rules.json`, append to the `rules` array (after the `multi-code-review` entry, matching existing formatting):

```json
{
  "skill": "orchestrating-development",
  "type": "workflow",
  "priority": "high",
  "keywords": [
    "orchestrate",
    "orchestration",
    "orchestrator",
    "whole pipeline",
    "full pipeline",
    "resume orchestration",
    "abandon orchestration"
  ],
  "intentPatterns": [
    "orchestrate\\s+(the\\s+)?(development|implementation|pipeline)",
    "orchestrate\\b[\\s\\S]{0,80}?docs[\\/]specs[\\/]",
    "\\borchestrate\\s+(it|this)\\b",
    "(resume|abandon)\\s+orchestration",
    "(run|execute|start)\\s+the\\s+(whole|full|entire)\\s+pipeline"
  ]
}
```

- [x] **Step 4: Run tests to verify all pass**

Run: `node tests/codex/test-skill-activator.js`
Expected: PASS — 0 failed, including every pre-existing routing test.

- [x] **Step 5: Run the full unit suite (cross-hook non-regression)**

Run: `bash tests/codex/run-unit-tests.sh`
Expected: 0 failed across all suites.

- [x] **Step 6: Commit**

```bash
git add hooks/skill-rules.json tests/codex/test-skill-activator.js
git commit -m "feat(routing): orchestrating-development entry with rank tests"
```

---

### Task 3: `skills/orchestrating-development/SKILL.md`

**Files:**
- Create: `skills/orchestrating-development/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** Codex/Cursor execution (skill refuses without the Agent tool); parallel waves inside a batch; auto-merge/PR; spec authoring/review; timeout watchdogs (permission-stall risk is handled by the Phase 0 confirmation instead).

- [x] **Step 1: Write the file with exactly this content**

````markdown
---
name: orchestrating-development
description: >
  MUST USE when the user asks to orchestrate the full development pipeline
  from an approved spec: plan writing, N plan-review rounds, batched
  implementation, and N code-review rounds run autonomously, stopping only
  on major errors, ending before merge/PR. Triggers on: "orchestrate the
  development", "orchestrate docs/specs/...", "run the whole pipeline
  autonomously", "resume orchestration", "abandon orchestration". Requires
  the Agent tool with nested dispatch (Claude Code only).
---

# Orchestrating Development

Drive an approved spec through plan → plan review → batched implementation
→ whole-branch code review with no user interaction between Phase 0 and
completion. You are a thin sequencer: every phase and every batch runs in a
fresh controller subagent; all state moves through files. Never read plan
bodies, diffs, reviewer reports, or fix reports yourself.

## Required Start

Announce: `I'm using orchestrating-development to run this pipeline.`

**Platform check:** this skill requires the Agent tool (with nested
dispatch). On platforms without it, refuse with one line —
`orchestrating-development requires subagent dispatch (Agent tool), which
this platform lacks` — and stop.

## Controller Dispatch Rules (apply to every phase)

- Dispatch via the Agent tool, `general-purpose` type. Model: inherit the
  session model with a **sonnet floor** (a haiku-tier or unrecognized
  session model dispatches on `sonnet`). Nested workers inside a batch
  follow SDD's Model Selection table, chosen by the batch controller.
- Build the prompt ONLY from the filled template — never pass conversation
  history, prior phases' returns, or your own reasoning.
- Resolve procedure-source paths from this skill's base directory:
  `../writing-plans/SKILL.md`, `../multi-doc-review/SKILL.md`,
  `../subagent-driven-development/SKILL.md`, `../multi-code-review/SKILL.md`.
  Controllers read these files as their procedure; they never use the Skill
  tool. Controllers never write `state.md` — you are its only writer.
- **Return contract:** first line exactly `<!-- orchestration report -->`
  (guard exemption); leading token on the next line; hard cap 15 lines;
  detail goes to files. A return is **malformed** when the marker line or
  the leading token is absent OR any field you consume (`tasks=`, per-task
  numbers, `rounds=`, `outcome=`, `unresolved=`, `user_decision=`,
  `fixes=`) is absent or unparseable. An unparseable stop-rule field never
  defaults to 0. Malformed return or controller error → retry the identical
  dispatch once; second failure → major error → stop, logging
  `inconclusive controller: <phase/batch>`.

## Phase 0 — Setup (the only interactive moment)

Input: the spec path (from the invocation phrase; if absent, ask for it in
the same question batch below).

1. Platform check (above).
2. **Ask once (single batch):** N_plan (0–10, default 3), N_code (0–10,
   default 3), batch cap (1–5, default 3). Invalid → default. N=0 means
   you skip that phase yourself — no controller dispatched; the log records
   `## Phase 2 — Plan review — skipped (N_plan=0)` /
   `## Phase 4 — Code review — skipped (N_code=0)`. The same batch carries
   two confirmations — this is the user's last interaction before hours of
   autonomy:
   - **Branch point:** state the current branch and HEAD sha the feature
     branch will be cut from, and whether it is the default branch. A
     non-default branch point requires explicit confirmation (default:
     abort).
   - **Permissions:** remind the user the run is unattended and every
     permission prompt stalls it indefinitely; have them confirm the
     session will not prompt for the pipeline's edit/Bash/Agent calls.
3. **Local ignores (before the clean-tree check):** ensure `state.md` and
   `.superpowers/` are matched by the exclude file at
   `$(git rev-parse --git-path info/exclude)` (append missing lines). The
   literal `.git/info/exclude` path does not exist in a linked worktree.
4. **Preconditions:** git repo; spec file exists; the computed plan path
   and log path (step 7) do not already exist; `git status --porcelain`
   empty EXCEPT the spec and its `<spec-basename>-review-log.md` sidecar
   (brainstorming leaves them uncommitted). Any other dirt → stop and
   report; never stash or commit the user's unrelated changes.
5. **Branch:** create and switch to `feature/<slug>` from current HEAD.
   `<slug>` = spec basename with `YYYY-MM-DD-` prefix and `-design` suffix
   each stripped only if present. If the branch exists: locate the
   existing orchestration log for that slug with the glob
   `docs/plans/*-<slug>-orchestration-log.md` (its date prefix is the
   PRIOR run's start date — never assume today's) and compare its
   recorded spec path with the invoked spec — same spec → report "prior run", suggest the resume
   prompt; different/missing → report "unrelated prior run with the same
   slug", tell the user to rename the spec or clear the old branch. Stop
   either way.
6. **Commit inputs:** if the spec/sidecar were dirty in step 4, commit them
   (`docs(spec): <slug> design`).
7. **Log:** create `docs/plans/YYYY-MM-DD-<slug>-orchestration-log.md`
   (start date) with the invocation header (format below), recording
   BASE = `git rev-parse HEAD`. Commit it
   (`chore: start orchestration log`).
8. **Seed `state.md`:** the sections writing-plans seeds, plus
   `## Orchestration` (format below).

Any failure in steps 1–6 is a **pre-log stop**: report and stop; nothing
further written, no resume line; if the branch was already created (step
5 succeeded), name it so the user can delete it. From here to Phase 5,
never ask the user anything.

## Phase 1 — Plan Writing

Fill `./plan-writer-prompt.md` (spec path; output plan path
`docs/plans/YYYY-MM-DD-<slug>.md`, same date and slug as the log) and
dispatch. Expected return: `PLAN_READY <path> tasks=<T>` or
`BLOCKED: <question>` (spec ambiguity → major error → stop). On success:
commit the plan (`docs(plan): <slug> implementation plan`), append and
commit the Phase 1 log entry.

## Phase 2 — Plan Review Loop

If N_plan = 0, log the skip and go to Phase 3. Otherwise fill
`./doc-review-loop-prompt.md` (plan path, spec path, N_plan) and dispatch.
Expected return: `REVIEW_DONE rounds=<r> outcome=<converged|cap>
unresolved=<n>` or `BLOCKED: <reason>`. `unresolved > 0` → major error →
stop. On success: commit the revised plan + its review log, append and
commit the Phase 2 log entry.

## Phase 3 — Implementation Batches

Loop until every task is complete:

1. Cheap-scan the plan's `### Task N` headings and checkboxes only.
   **Task-complete predicate:** a task is complete ⇔ every checkbox under
   its `### Task N` heading is checked; "unchecked task" = any box
   unchecked. A `### Task N` heading with ZERO checkboxes is a malformed
   plan → major error → stop (the predicate would otherwise pass it
   vacuously and silently skip the task). Select the next ≤ cap unchecked
   tasks in plan order.
2. Fill `./batch-controller-prompt.md` (plan path, task numbers,
   first-batch flag for SDD's Pre-Flight Plan Review) and dispatch.
3. Expected return: `BATCH_COMPLETE tasks=<i>..<j>` + one
   `Task <n>: complete commits <base7>..<head7>` line per task, or
   `BLOCKED task=<n>: <one-line reason>` (detail in the task's report
   file). `BATCH_COMPLETE` asserts every listed task completed with a
   clean review — there is no partial-success return; completed earlier
   tasks keep their checkboxes and commits.
4. **Checkbox cross-check:** re-scan the reported task numbers. Any task
   reported complete whose boxes are not all checked → major error → stop
   (a well-formed return contradicted by file state must never re-enter
   the selection loop).
5. Append and commit the batch's log entry (the controller already
   committed each checkbox tick per-task); rewrite `state.md`. `BLOCKED`
   → major error → stop.

Cap sizing: nothing but the cap bounds a controller's context (SDD's 60%
pressure check belongs to the batch loop you replaced) — that is why
Phase 0 caps it at 5. On a controller death, previously completed tasks
are checkbox-ticked and ledger-recorded, so the retried controller
(idempotent `sdd-workspace`, same plan) skips them; the template's
mid-task recovery procedure reviews any orphan commits from the first
attempt together with the completion — never let SDD's
crash-reconciliation shortcut ("commits present → mark complete") skip a
task review inside a batch.

## Phase 4 — Final Code Review Loop

If N_code = 0, log the skip and go to Phase 5. Preconditions: all
orchestration-log edits are committed (they are, if you committed at each
boundary), and `git merge-base --is-ancestor <BASE> HEAD` succeeds —
failure means the branch was rebased or reset mid-run → major error →
stop. Fill `./code-review-loop-prompt.md` (BASE = the Phase 0
recorded branch point, N_code, plan path, ledger path
`.superpowers/sdd/progress.md`) and dispatch. Expected return:
`REVIEW_DONE rounds=<r> outcome=<converged|cap> fixes=<n> unresolved=<n>
user_decision=<n>` or `BLOCKED: <reason>`. `unresolved > 0` or
`user_decision > 0` → major error → stop (the findings are journaled in
the review log; point the stop entry there). On success: append and
commit the Phase 4 log entry before Phase 5 begins.

## Phase 5 — Completion

1. Verify every task satisfies the task-complete predicate and
   `git status --porcelain` is clean; discrepancy → stop and report —
   never silently reconcile.
2. Append the completion marker to the log; commit.
3. Report: tasks completed, batches run, plan-review rounds/outcome,
   code-review rounds/fixes/outcome, and the three log paths
   (orchestration, plan review, `.superpowers/reviews/` code review).
4. Invoke `finishing-a-development-branch` (interactive — merge/PR/keep/
   discard is the user's call).

## Orchestration Log Format

```
# Orchestration Log — <slug>

_Invocation 1 — YYYY-MM-DD — spec docs/specs/<spec>.md — N_plan=<n> N_code=<n> cap=<n> — branch feature/<slug> — BASE <sha7>_

## Phase 1 — Plan — DONE — YYYY-MM-DD
plan: docs/plans/<plan>.md — <T> tasks

## Phase 2 — Plan review — rounds <r> — <converged|cap> — unresolved 0

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits <base7>..<head7>
- Task 1: complete — <one-line>

## Phase 4 — Code review — rounds <r> — <converged|cap> — fixes <n> — unresolved 0

_Completed — YYYY-MM-DD — HEAD <sha7>_
```

A stop writes instead:

```
## STOPPED — YYYY-MM-DD — phase <p> — <one-line reason>
Detail: <path to the file holding the blocker detail>
Resume: Resume orchestration for docs/plans/<plan>.md
```

(For a Phase 1 stop the plan may not exist: the Resume line names the
spec path instead, and resume re-dispatches the plan-writer with the
answer the resume prompt must supply.) Skipped loops write the
`skipped (N_x=0)` line shapes from Phase 0. Round-by-round detail lives
in the sub-skills' own logs — never duplicate it here. Commit the log at
every boundary: Phase 0, after Phases 1–2, after each batch, after
Phase 4, and at completion/stop.

## state.md Section

Rewrite the plan-execution sections at every boundary (SDD's shape, cap
100 lines) plus:

```
## Orchestration
Spec: docs/specs/<spec>.md  Plan: docs/plans/<plan>.md
Params: N_plan=<n> N_code=<n> cap=<n>  Branch: feature/<slug>  BASE: <sha7>
Position: phase <p>[, next batch tasks <i>–<j>]
```

## Resume

Trigger: `Resume orchestration for <plan-or-spec path>`.

0. Derive `feature/<slug>` from the named path; verify the branch exists
   (else stop — nothing to resume) and check it out; re-ensure the exclude
   entries (Phase 0 step 3) FIRST, then require `git status --porcelain`
   empty (else stop).
1. Read the orchestration log — locate it with
   `docs/plans/*-<slug>-orchestration-log.md` (its date prefix is the
   run's start date, not today's) — authoritative for parameters and last
   completed phase; `state.md` (narrative, may be one step stale); the
   plan's checkboxes (if it exists); recent `git log`.
2. Log ends with `_Completed_` → report that and stop.
3. Log ends with `## STOPPED` carrying a blocking question the resume
   prompt does not answer → present the question and stop.
4. Otherwise continue at the first incomplete phase/batch. Your own log's
   phase entries are the primary re-run guard; the sub-skills' logs are
   the backstop.
5. Never re-ask Phase 0 questions — parameters come from the log's
   LATEST invocation line — but the resume prompt MAY override them (e.g.
   `... with cap=2`); an override appends
   `_Invocation <k> — YYYY-MM-DD — <changed params> — resumed_` with `<k>`
   incrementing from the last invocation number. Overrides are
   PER-PARAMETER: a parameter absent from the latest invocation line is
   taken from the most recent earlier line that records it — never
   defaulted (defaulting would silently discard the user's Phase 0
   choices). This is the designed escape from a parameter-caused stop.
6. Excluded state (`state.md`, `.superpowers/`) does not survive clone
   boundaries or `git clean -fdx`; anything lost is reported, never
   silently reconstructed.

**Abandoning:** on `Abandon orchestration for <plan>`: confirm once, then
delete the feature branch (refuse if checked out elsewhere or already
merged — report instead) and state what remains. This is the sanctioned
teardown for a wedged or superseded run.

## Major-Error Stop Policy

In-run stop = append `## STOPPED` to the log, commit it, update
`state.md` `## Open Issues` (blocking items first), report with the
resume prompt. Stop on: plan-writer BLOCKED; doc-review unresolved > 0 or
loop failure; pre-flight plan conflict; batch-controller BLOCKED;
checkbox cross-check mismatch; code-review unresolved or user-decision
items; any controller malformed/failed twice; branch changed under you or
unexpected dirty tree at a boundary. Everything else is handled inside
the controllers by the consumed skills' own rules.

## Guard Interaction

Controller returns open with `<!-- orchestration report -->`;
`hooks/subagent-guard.js` exempts messages opening with that marker.
Never remove the marker instruction from the four templates — free-text
`BLOCKED` reasons legitimately pair action verbs with skill names, and an
unmarked return would be blocked, hang the dispatch, and stall the
unattended run. Nested workers dispatched by batch controllers carry
SDD's leakage-prevention line; nested reviewers inside the two loop
controllers emit `<!-- multi-review report -->`, which the guard already
exempts.

## Prompt Templates

- `./plan-writer-prompt.md`
- `./doc-review-loop-prompt.md`
- `./batch-controller-prompt.md`
- `./code-review-loop-prompt.md`
````

- [x] **Step 2: Verify required strings**

Run:
```bash
f=skills/orchestrating-development/SKILL.md
grep -c "orchestration report" $f          # expected: >= 2
grep -n "PLAN_READY\|BATCH_COMPLETE\|REVIEW_DONE" $f | wc -l   # expected: >= 4
grep -n "rev-parse --git-path info/exclude" $f                 # expected: 1 hit
grep -n "sonnet floor" $f                                      # expected: 1 hit
grep -n "finishing-a-development-branch" $f                    # expected: 1 hit
```
Expected: counts as annotated; no output missing.

- [x] **Step 3: Commit**

```bash
git add skills/orchestrating-development/SKILL.md
git commit -m "feat(skill): orchestrating-development orchestrator procedure"
```

---

### Task 4: `plan-writer-prompt.md`

**Files:**
- Create: `skills/orchestrating-development/plan-writer-prompt.md`

**Security flag:** `none`

**Does NOT cover:** plan review (Phase 2 owns it); execution handoff (the orchestrator owns sequencing — the template explicitly skips writing-plans' handoff sections).

- [x] **Step 1: Write the file with exactly this content**

````markdown
# Plan-Writer Controller Prompt Template

Phase 1 of orchestrating-development. One controller per run; it writes
the implementation plan from the approved spec, autonomously.

```
Agent tool (general-purpose):
  description: "orchestration phase 1: plan writer"
  model: session model, sonnet floor
  prompt: |
    You are an autonomous plan-writing controller. You write ONE
    implementation plan from ONE spec. You have no other tasks.

    ## Controller Rules

    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
    - Do NOT write `state.md`. Do NOT ask the user anything.
    - Your ONLY file writes are the plan file named below.

    ## Procedure

    Read [WRITING_PLANS_SKILL_PATH] and follow it as your procedure —
    the sections from "Output Path" through "Self-Review" inclusive.
    SKIP its "Multi-Round Plan Review" and "Execution Handoff" sections
    entirely: the orchestrator owns both. Skip any announcement lines.

    Deviation from that procedure: where it says to ask clarifying
    questions for ambiguous features, you instead derive the answer from
    the spec and the repository. If an answer cannot be derived, stop and
    return BLOCKED with the question — never guess.

    ## Inputs

    Spec (your requirements): [SPEC_PATH]
    Plan output path (exact, already reserved): [PLAN_PATH]
    The plan header's **Spec:** line must name [SPEC_PATH].

    ## Return (final message, 15 lines max)

    First line exactly:

    <!-- orchestration report -->

    Then exactly one of:

    PLAN_READY [PLAN_PATH] tasks=<T>
    BLOCKED: <the one question that could not be derived>

    <T> = the number of `### Task N` headings you wrote. Optionally up to
    3 further one-line notes (assumptions you resolved from the spec).
```

**Placeholders:**
- `[WRITING_PLANS_SKILL_PATH]` — REQUIRED: absolute path of
  `../writing-plans/SKILL.md` resolved from this skill's base directory
- `[SPEC_PATH]` — REQUIRED: absolute path of the approved spec
- `[PLAN_PATH]` — REQUIRED: absolute output path
  `docs/plans/YYYY-MM-DD-<slug>.md` computed by the orchestrator

**Nothing else may be added to the prompt.** No conversation history, no
design rationale.

**Controller returns:** marker line, then `PLAN_READY <path> tasks=<T>`
or `BLOCKED: <question>`.
````

- [x] **Step 2: Verify**

Run: `grep -c "orchestration report\|PLAN_READY\|BLOCKED" skills/orchestrating-development/plan-writer-prompt.md`
Expected: >= 5 total matching lines.

- [x] **Step 3: Commit**

```bash
git add skills/orchestrating-development/plan-writer-prompt.md
git commit -m "feat(skill): plan-writer controller template"
```

---

### Task 5: `doc-review-loop-prompt.md`

**Files:**
- Create: `skills/orchestrating-development/doc-review-loop-prompt.md`

**Security flag:** `none`

**Does NOT cover:** spec reviews (only the plan is reviewed here); N=0 (the orchestrator never dispatches this controller then).

- [ ] **Step 1: Write the file with exactly this content**

````markdown
# Doc-Review-Loop Controller Prompt Template

Phase 2 of orchestrating-development. One controller per run; it executes
the multi-doc-review loop on the plan, autonomously.

```
Agent tool (general-purpose):
  description: "orchestration phase 2: plan review loop"
  model: session model, sonnet floor
  prompt: |
    You are an autonomous document-review-loop controller. You run an
    N-round independent review-and-merge loop on ONE plan document.

    ## Controller Rules

    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
    - Do NOT write `state.md`. Do NOT ask the user anything.
    - You MAY dispatch reviewer subagents via the Agent tool, edit the
      plan (merging findings), and write the review log sidecar.

    ## Procedure

    Read [MULTI_DOC_REVIEW_SKILL_PATH] and execute its whole procedure
    with these parameters — never ask for any of them:
    - Target document: [PLAN_PATH]   (doc type: plan)
    - Spec path: [SPEC_PATH]
    - N (round cap): [N_PLAN]
    - Reviewer template: [REVIEWER_PROMPT_PATH] (fill ONLY its
      placeholders; reviewers inherit your model)
    - Invoker recorded in the log: `gate: orchestration`

    ## Deviations (binding)

    1. After the loop, run the "Self-Review" checklist from
       [WRITING_PLANS_SKILL_PATH] on the merged plan (that is the host
       checklist for plan documents); fix issues inline, note them in
       the log.
    2. When the loop finishes, append to the review log:
       `_Loop complete — YYYY-MM-DD — rounds <r>_`
       If you find an existing `gate: orchestration` invocation entry
       WITHOUT that line, it is your own interrupted loop: continue at
       the next round (count existing `## Round` entries) — the
       once-per-gate rule blocks re-running a completed loop, never
       continuing an interrupted one. If instead you find your own
       COMPLETED `gate: orchestration` entry (the `_Loop complete_` line
       present), do not re-run anything: synthesize your REVIEW_DONE
       return from the review log's recorded rounds and dispositions —
       a retry dispatched after only the final message was lost must not
       run the loop twice.
    3. A Critical/Important finding is `unresolved` only when applying it
       was attempted and failed twice (the merge would contradict the
       spec or another applied finding); log it as
       `- [X] unresolved: <reason> — <finding summary>`.

    ## Return (final message, 15 lines max)

    First line exactly:

    <!-- orchestration report -->

    Then exactly one of:

    REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>
    BLOCKED: <reason the loop could not run at all>

    Optionally up to 3 one-line notes (e.g. per-round finding counts).
```

**Placeholders:**
- `[MULTI_DOC_REVIEW_SKILL_PATH]` — REQUIRED: absolute path of
  `../multi-doc-review/SKILL.md`
- `[REVIEWER_PROMPT_PATH]` — REQUIRED: absolute path of
  `../multi-doc-review/reviewer-prompt.md`
- `[WRITING_PLANS_SKILL_PATH]` — REQUIRED: absolute path of
  `../writing-plans/SKILL.md` (Self-Review section is the after-loop
  checklist)
- `[PLAN_PATH]` — REQUIRED: absolute plan path
- `[SPEC_PATH]` — REQUIRED: absolute spec path
- `[N_PLAN]` — REQUIRED: integer 1–10

**Nothing else may be added to the prompt.**

**Controller returns:** marker line, then
`REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>` or
`BLOCKED: <reason>`.
````

- [ ] **Step 2: Verify**

Run: `grep -c "REVIEW_DONE\|gate: orchestration\|Loop complete" skills/orchestrating-development/doc-review-loop-prompt.md`
Expected: >= 4 matching lines.

- [ ] **Step 3: Commit**

```bash
git add skills/orchestrating-development/doc-review-loop-prompt.md
git commit -m "feat(skill): doc-review-loop controller template"
```

---

### Task 6: `batch-controller-prompt.md`

**Files:**
- Create: `skills/orchestrating-development/batch-controller-prompt.md`

**Security flag:** `none`

**Does NOT cover:** parallel waves (batches are sequential by design decision); the final whole-branch review (Phase 4 owns it); shutdown of named resident teammates (controllers spawn only task-scoped workers).

- [ ] **Step 1: Write the file with exactly this content**

````markdown
# Batch-Controller Prompt Template

Phase 3 of orchestrating-development. One controller per batch of ≤ cap
tasks; it runs SDD's per-task flow with nested workers, autonomously.

```
Agent tool (general-purpose):
  description: "orchestration phase 3: batch [BATCH_NUMBER] (tasks [TASK_LIST])"
  model: session model, sonnet floor
  prompt: |
    You are an autonomous batch controller. You implement the listed plan
    tasks, sequentially, each through the full implement-review-fix gate.

    ## Controller Rules

    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
    - Do NOT write `state.md`. Do NOT ask the user anything.
    - You MAY dispatch nested worker subagents (implementers, task
      reviewers, fix subagents) via the Agent tool. Every nested worker
      prompt MUST include: "You are a focused subagent. Do NOT invoke any
      skills from the superpowers-optimized plugin. Do NOT use the Skill
      tool. Your only job is the task described below."

    ## Procedure

    Read [SDD_SKILL_PATH]. Your procedure is its per-task flow and
    supporting sections — follow these, skipping all others (you are not
    the whole skill): "Core Flow" step 3 (the per-task loop), "E2E
    Process Hygiene", the "Autonomy Policy" under Batched Autonomous
    Mode, "Handling Implementer Status", "File Handoffs", "Handling
    Reviewer ⚠️ Items", "Constructing Reviewer Prompts", "Durable
    Progress", "Model Selection for Agent Tool Calls", "Subagent Skill
    Leakage Prevention", "Hard Rules". Worker templates:
    [IMPLEMENTER_PROMPT_PATH] and [TASK_REVIEWER_PROMPT_PATH]. Scripts
    (run from [SDD_SCRIPTS_DIR]): `sdd-workspace PLAN_FILE` once at
    start (idempotent for the same plan), `task-brief PLAN_FILE N` per
    task, `review-package BASE HEAD` per review (BASE = the HEAD you
    record before dispatching that task's implementer).

    ## Batch Parameters

    Plan: [PLAN_PATH]
    Tasks to implement, in order: [TASK_LIST]
    First batch: [FIRST_BATCH]  (if "yes": run SDD's "Pre-Flight Plan
    Review" over the whole plan before task 1; any conflict → return
    BLOCKED for that conflict — never best-guess it)

    ## Deviations (binding)

    1. Never ask the user. NEEDS_CONTEXT: answer from plan, spec, and
       repository; underivable → BLOCKED. Blocker questions go in the
       blocked task's report file — never `state.md`.
    2. Sequential only — no parallel waves inside a batch.
    3. On completing a task, tick EVERY checkbox under its `### Task N`
       heading in the plan (the orchestrator's completeness predicate is
       all-boxes-checked), append the ledger line per "Durable Progress",
       then commit the tick immediately, staging the plan file by
       explicit path — `git add [PLAN_PATH] && git commit -m
       "chore(plan): task <n> complete"` — never `git add -A`. An
       uncommitted tick leaves the tree dirty at the next phase boundary
       and wedges the run.
    3b. Extract the plan's `**Global Constraints:**` block yourself from
       [PLAN_PATH] and hand it verbatim to every task-reviewer dispatch
       (SDD's task-reviewer template expects it; the orchestrator never
       reads plan bodies and cannot supply it).
    4. Mid-task crash recovery: for each assigned task that is unchecked
       when you start, set REVIEW_BASE = the HEAD recorded by the last
       ledger line (or your starting HEAD if none) and check
       `git log REVIEW_BASE..HEAD` for existing commits touching it. If
       any exist, dispatch the implementer with an explicit partial-work
       note (verify existing behavior and tests rather than expecting a
       fresh TDD fail step) and build that task's review package from
       REVIEW_BASE — orphan commits are reviewed with the completion.
       Never apply SDD's crash shortcut ("commits present → mark
       complete"): it skips the review gate.
    5. A task with **Security flag:** `security` gets the
       pre-implementation security review SDD mandates before its
       implementer is dispatched.
    6. Any task that cannot reach completed-with-clean-review makes your
       whole return BLOCKED for that task; earlier completed tasks keep
       their checkboxes, commits, and ledger lines.

    ## Return (final message, 15 lines max)

    First line exactly:

    <!-- orchestration report -->

    Then exactly one of:

    BATCH_COMPLETE tasks=[TASK_RANGE]
    BLOCKED task=<n>: <one-line reason; detail in the task's report file>

    After BATCH_COMPLETE, one line per task, exactly:
    Task <n>: complete commits <base7>..<head7>
```

**Placeholders:**
- `[BATCH_NUMBER]` — REQUIRED: 1-based batch index (display only)
- `[TASK_LIST]` — REQUIRED: comma-separated task numbers, e.g. `4, 5, 6`
- `[TASK_RANGE]` — REQUIRED: `<first>..<last>` of TASK_LIST
- `[PLAN_PATH]` — REQUIRED: absolute plan path
- `[FIRST_BATCH]` — REQUIRED: `yes` or `no`
- `[SDD_SKILL_PATH]` / `[SDD_SCRIPTS_DIR]` / `[IMPLEMENTER_PROMPT_PATH]` /
  `[TASK_REVIEWER_PROMPT_PATH]` — REQUIRED: absolute paths under
  `../subagent-driven-development/` resolved from this skill's base
  directory

**Nothing else may be added to the prompt.**

**Controller returns:** marker line, then `BATCH_COMPLETE tasks=<i>..<j>`
plus per-task lines, or `BLOCKED task=<n>: <reason>`.
````

- [ ] **Step 2: Verify**

Run: `grep -c "BATCH_COMPLETE\|REVIEW_BASE\|Pre-Flight\|focused subagent" skills/orchestrating-development/batch-controller-prompt.md`
Expected: >= 6 matching lines.

- [ ] **Step 3: Commit**

```bash
git add skills/orchestrating-development/batch-controller-prompt.md
git commit -m "feat(skill): batch-controller template with mid-task crash recovery"
```

---

### Task 7: `code-review-loop-prompt.md`

**Files:**
- Create: `skills/orchestrating-development/code-review-loop-prompt.md`

**Security flag:** `none`

**Does NOT cover:** interactive resolution of user-decision findings (the orchestrator stops instead — batched-autonomous behavior); N=0 (never dispatched).

- [ ] **Step 1: Write the file with exactly this content**

````markdown
# Code-Review-Loop Controller Prompt Template

Phase 4 of orchestrating-development. One controller per run; it executes
the multi-code-review loop on the branch, autonomously.

```
Agent tool (general-purpose):
  description: "orchestration phase 4: code review loop"
  model: session model, sonnet floor
  prompt: |
    You are an autonomous code-review-loop controller. You run an N-round
    review-fix-repackage loop on ONE branch diff.

    ## Controller Rules

    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
    - Do NOT write `state.md`. Do NOT ask the user anything.
    - You MAY dispatch reviewer and fix subagents via the Agent tool,
      commit fixes, and write under `.superpowers/reviews/`.

    ## Procedure

    Read [MULTI_CODE_REVIEW_SKILL_PATH] and execute its whole procedure
    with these parameters — never ask for any of them:
    - BASE: [BASE_SHA]   (the orchestration branch point; already
      verified an ancestor of HEAD)
    - N (round cap): [N_CODE]
    - Plan/requirements path: [PLAN_PATH]
    - Reviewer template: [REVIEWER_PROMPT_PATH]
    - Invoker recorded in the log: `gate: orchestration`
    - Apply its Batched-Autonomous-Mode rules throughout (they appear
      inline in its sentinel and disposition sections, not under a
      heading of that name): never ask; plan-mandated/user-decision
      findings are journaled in the log and reported in your return,
      never presented interactively.

    ## Deviations (binding)

    1. Carried Minor findings: read [LEDGER_PATH] and fill the reviewer
       template's carried-findings placeholder with its `Minor:` lines
       only. If the file is absent, proceed and write
       `carried findings unavailable — ledger absent` in the review log.
    2. Sentinel and once-per-gate: treat a `gate: orchestration` entry as
       a matching invoker kind — an entry with your BASE and no
       completion marker is your own interrupted loop: resume it at the
       next round automatically; the completion skip applies to
       `gate: orchestration` entries whose completion-marker HEAD and
       branch match. If the completion marker already matches the current
       HEAD and branch, do not re-run anything: synthesize your
       REVIEW_DONE return from the review log's recorded rounds and
       dispositions — a retry dispatched after only the final message was
       lost must not run the loop twice.
    3. Triage rule: any reviewer finding whose subject file is an
       orchestration artifact — `*-orchestration-log.md`, the plan file's
       checkbox ticks, or a `*-review-log.md` sidecar — whether the
       finding is about its presence, modification, or content, is
       rejected as `rejected: orchestration artifact (documented)`. Never
       dispatch a fix subagent against these files.

    ## Return (final message, 15 lines max)

    First line exactly:

    <!-- orchestration report -->

    Then exactly one of:

    REVIEW_DONE rounds=<r> outcome=<converged|cap> fixes=<n> unresolved=<n> user_decision=<n>
    BLOCKED: <reason the loop could not run at all>

    `fixes` = count of fix commits made. Optionally up to 3 one-line
    notes.
```

**Placeholders:**
- `[MULTI_CODE_REVIEW_SKILL_PATH]` — REQUIRED: absolute path of
  `../multi-code-review/SKILL.md`
- `[REVIEWER_PROMPT_PATH]` — REQUIRED: absolute path of
  `../multi-code-review/reviewer-prompt.md`
- `[BASE_SHA]` — REQUIRED: the Phase 0 recorded branch-point SHA
- `[N_CODE]` — REQUIRED: integer 1–10
- `[PLAN_PATH]` — REQUIRED: absolute plan path
- `[LEDGER_PATH]` — REQUIRED: absolute path of
  `.superpowers/sdd/progress.md` at the repo root

**Nothing else may be added to the prompt.**

**Controller returns:** marker line, then `REVIEW_DONE rounds=<r>
outcome=<converged|cap> fixes=<n> unresolved=<n> user_decision=<n>` or
`BLOCKED: <reason>`.
````

- [ ] **Step 2: Verify**

Run: `grep -c "REVIEW_DONE\|orchestration artifact\|ledger absent\|user_decision" skills/orchestrating-development/code-review-loop-prompt.md`
Expected: >= 5 matching lines.

- [ ] **Step 3: Commit**

```bash
git add skills/orchestrating-development/code-review-loop-prompt.md
git commit -m "feat(skill): code-review-loop controller template"
```

---

### Task 8: Brainstorming exit-message line

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** changing brainstorming's terminal state (it remains `writing-plans`); routing (Task 2 owns it).

- [ ] **Step 1: Edit the User Review Gate blockquote**

In `skills/brainstorming/SKILL.md`, replace the line:

```markdown
> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."
```

with:

```markdown
> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan. (Alternatively, say 'orchestrate it' to run plan, reviews, and implementation autonomously via orchestrating-development.)"
```

- [ ] **Step 2: Verify**

Run: `grep -c "orchestrate it" skills/brainstorming/SKILL.md`
Expected: `1`

- [ ] **Step 3: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): offer orchestration at the spec review gate"
```

---

### Task 9: Version bump to 6.14.0 + release notes

**Files:**
- Modify: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md`

**Security flag:** `none`

- [ ] **Step 1: Bump every version field**

- `VERSION`: `6.14.0`
- `.claude-plugin/plugin.json` line 4: `"version": "6.14.0",`
- `.claude-plugin/marketplace.json` line 13: `"version": "6.14.0",`
- `plugin.universal.yaml` line 7: `version: "6.14.0"`
- `README.md`, four named edits (find each by string, not line number):
  - version badge: `version-6.13.0-white` → `version-6.14.0-white`
  - the lineage sentence `This fork's own additions (v6.7.0–v6.13.0)` →
    `(v6.7.0–v6.14.0)`; the other historical `v6.13.0` mention
    ("fresh-session plan handoff (v6.13.0)") stays unchanged
  - the sentence containing `25 specialized skills` → `26 specialized skills`
  - the sentence containing `24 rules covering 23 skills` →
    `25 rules covering 24 skills` (Task 2 added one rule for one new skill)
  - BOTH occurrences of `26 skills` (the `skills/ — 26 skills, each in
    skills/<name>/SKILL.md` directory summary and the
    `## Skills Library (26 skills)` heading) → `27 skills`
  - under the Skills Library section, add one bullet for the new skill,
    alongside the other execution-workflow skills:
    `- **orchestrating-development** — autonomous spec→plan→review→implement→review pipeline; fresh controller subagent per phase/batch; stops only on major errors, ends before merge/PR`

- [ ] **Step 2: Add the release-notes entry**

At the top of `RELEASE-NOTES.md`, after the `# Superpowers Optimized Release Notes` heading, insert:

```markdown
## v6.14.0 — orchestrating-development: autonomous spec→merge-gate pipeline

- New skill **orchestrating-development**: from an approved spec, runs
  plan writing, N plan-review rounds, batched implementation (fresh
  controller subagent per ≤cap tasks, nested implementer/reviewer
  workers), and N code-review rounds fully autonomously — stopping only
  on major errors, ending before merge/PR. One interactive Phase 0
  (review counts, batch cap, branch-point + permission confirmations);
  committed orchestration log `docs/plans/…-orchestration-log.md`;
  resume and abandon procedures.
- `hooks/subagent-guard.js`: new `<!-- orchestration report -->` exempt
  marker for controller returns (free-text BLOCKED reasons may name
  skills); header now records that controller nested dispatch is
  sanctioned. Unit-tested in `tests/codex/test-subagent-guard.js`.
- `hooks/skill-rules.json`: routing entry for orchestrate / resume
  orchestration / abandon orchestration phrasings, rank-tested in
  `tests/codex/test-skill-activator.js`.
- `brainstorming` spec-review gate message now offers orchestration as
  an alternative to the manual writing-plans handoff. Existing manual
  workflows are unchanged.
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "6\.14\.0" VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml | wc -l   # expected: 4
grep -c "version-6\.14\.0-white" README.md                                    # expected: 1
grep -c "v6\.7\.0–v6\.14\.0\|26 specialized skills\|25 rules covering 24 skills" README.md   # expected: 3
grep -c "27 skills" README.md                                                 # expected: 2
grep -c "orchestrating-development" README.md                                 # expected: >= 1
grep -c "26 skills" README.md                                                 # expected: 0
grep -n "6\.13\.0" VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml   # expected: no output
grep -c "## v6\.14\.0" RELEASE-NOTES.md                                       # expected: 1
```
(README's remaining `v6.13.0` hit — the historical "fresh-session plan
handoff (v6.13.0)" sentence — is correct and stays.)

- [ ] **Step 4: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "v6.14.0 - orchestrating-development autonomous pipeline"
```

---

### Task 10: Full verification + local install sync

**Files:**
- None created; runs suites and syncs the dev install.

**Security flag:** `none`

- [ ] **Step 1: Run both fast suites**

Run: `bash tests/codex/run-unit-tests.sh`
Expected: 0 failed across all suites.

Run: `bash tests/smart-compress/run-tests.sh`
Expected: 0 failed (the suite self-seeds `.sp-test-probe.tmp`; a pristine tree is fine).

- [ ] **Step 1b: Guard cross-platform smoke (explicit checks)**

The guard is shared across platforms and Task 1 changed its behavior. The
Codex checklist has no SubagentStop parity (its SubagentStop item set is
empty), so the cross-platform obligation reduces to exactly these checks:

```bash
node --version          # expected: v16 or later
node --check hooks/subagent-guard.js && echo SYNTAX_OK   # expected: SYNTAX_OK
printf '%s' '{"last_assistant_message":"<!-- orchestration report -->\nBLOCKED task=1: plan says use executing-plans"}' \
  | node hooks/subagent-guard.js        # expected: {}
printf '%s' '{"last_assistant_message":"BLOCKED task=1: plan says use executing-plans"}' \
  | node hooks/subagent-guard.js        # expected: {"decision":"block",...}
```

Record the outcome — `guard smoke: PASS` or `guard smoke: PARTIAL —
<which check could not run>` — as a line in this task's report file
(subagent-driven execution), or under `state.md`'s `## Evidence` section
when executing inline via executing-plans (which has no report files).

- [ ] **Step 2: Template/SKILL.md cross-check (manual lint)**

Verify, by grep, that every placeholder named in each template's
**Placeholders:** list appears in its prompt block, and that the return
tokens in the four templates match SKILL.md exactly:

```bash
for f in skills/orchestrating-development/*-prompt.md; do
  echo "== $f"
  grep -o "\[[A-Z_]\{2,\}\]" "$f" | sort -u
done
# {2,} keeps the literal log-shape token `[X]` in doc-review-loop-prompt.md
# out of the results — it is not a placeholder.
grep -o "PLAN_READY\|REVIEW_DONE\|BATCH_COMPLETE\|BLOCKED" skills/orchestrating-development/SKILL.md | sort | uniq -c
```
Expected: each template's bracket set matches its Placeholders list;
SKILL.md contains all four tokens.

- [ ] **Step 3: Sync the dev install**

Run: `bash tools/sync-dev-install.sh`
Expected: completes without error (mirrors the repo into the registry's
`installPath` — do NOT locate the install by directory-name glob; the
active dir's name lies about its version). Verify using the target path
the script prints: `ls <printed-installPath>/skills | grep orchestrating`
→ `orchestrating-development`.
Note: live sessions only see the new skill after this sync (editing the
repo does NOT change live behavior — CLAUDE.md constraint).

- [ ] **Step 4: Commit (only if anything changed)**

```bash
git status --porcelain
```
Expected: clean — this task makes no repo edits; if the cross-check in
Step 2 exposed a mismatch, fix it in the owning file, re-run the owning
task's verify step, and commit there, not here.
