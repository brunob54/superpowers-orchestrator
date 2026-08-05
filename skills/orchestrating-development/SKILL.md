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
answer the resume prompt must supply, carried in the template's
`[RESUME_ANSWER]` placeholder.) Skipped loops write the
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
   plan's checkboxes (if it exists); recent `git log`. A required
   artifact missing — no log matches the glob, or the log records a
   completed Phase 1 but the plan it names is gone — is a major error:
   stop, report what is missing, and suggest starting a fresh
   orchestration; never reconstruct it.
2. Log ends with `_Completed_` → report that and stop.
3. Log ends with `## STOPPED` carrying a blocking question the resume
   prompt does not answer → present the question and stop. When the
   resume prompt does answer it, re-dispatch the stopped phase's
   controller with that answer in the template's `[RESUME_ANSWER]`
   placeholder — the only channel for it.
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
unexpected dirty tree at a boundary; a `### Task N` heading with zero
checkboxes (malformed plan, Phase 3 step 1); a log or plan commit that
fails at a phase boundary (report the git output verbatim); resume
finding a required artifact missing (orchestration log deleted, plan
moved) — report it and suggest starting a fresh orchestration rather
than reconstructing state. Remaining failure modes surface inside the
controllers and are handled there by the consumed skills' own rules.

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
