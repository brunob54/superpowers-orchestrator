# Orchestrating-Development Design

**Date:** 2026-08-04
**Status:** Approved design, pre-implementation
**Repo:** superpowers-optimized plugin (skills + hooks)

## Goal

A new skill, `orchestrating-development`, that takes an approved spec and runs
the entire remaining pipeline autonomously — plan writing, N rounds of plan
review, batched implementation with per-task review gates, and N rounds of
whole-branch code review — stopping only for major errors, and ending just
before merge/PR. The orchestrator manages sub-agents so that its own session
context stays nearly flat for the whole run: every phase and every
implementation batch executes in a fresh-context subagent, and all state moves
through files.

## User Decisions (recorded)

| Decision | Choice |
|---|---|
| End point of autonomy | Stop before merge/PR; `finishing-a-development-branch` runs interactively |
| Plan approval gate | None — fully autonomous from spec approval onward |
| Orchestration log | `docs/plans/YYYY-MM-DD-<feature>-orchestration-log.md`, committed |
| Batch grouping | Fixed cap, default 3 tasks, sequential within a batch |
| Review-round counts | Asked once at Phase 0: N_plan and N_code separately (defaults 3) |
| Architecture | Two-level orchestration (lean main-session orchestrator + fresh subagent controllers per phase/batch) |

## Scope

- New skill directory `skills/orchestrating-development/` containing
  `SKILL.md` and four prompt templates (one per controller kind).
- Registration in `hooks/skill-rules.json` (keywords + intentPatterns) so the
  skill auto-routes; routing-rank tests in `tests/codex/test-skill-activator.js`
  (the unit suite holding the `topSkill()` helper).
- One-line addition to `brainstorming/SKILL.md`'s User Review Gate message
  offering orchestration as an alternative to the plain `writing-plans`
  handoff. Brainstorming's default terminal state remains `writing-plans`.
- Orchestration log format, `state.md` integration, and a resume procedure.

## Non-Goals

- Codex/Cursor support. The skill requires the Agent tool; on platforms
  without it, refuse with one line (same pattern as `multi-code-review`).
- Parallel waves inside a batch. Batches execute tasks sequentially (user
  decision). SDD's Parallel Waves section does not apply inside a batch.
- Auto-merge or auto-PR. The run ends before `finishing-a-development-branch`.
- Spec authoring or spec review. `brainstorming` owns those; orchestration
  begins only after the user has approved a spec.
- Editing `writing-plans`, `multi-doc-review`, `subagent-driven-development`,
  or `multi-code-review` SKILL.md files. Controllers consume them read-only
  as procedure sources (see Procedure-by-File-Reference).
- Cross-repo orchestration; the run operates on the current repository only.
- Timeout-based watchdogs on subagents. The harness notifies on subagent
  completion; a genuinely hung subagent is surfaced by the user
  interrupting. The dominant stall cause — permission prompts in an
  unattended session — is addressed at Phase 0 instead (explicit
  permission-mode confirmation before autonomy begins), not by timers.

## Architecture

Two levels:

1. **Orchestrator (main session).** Executes `SKILL.md`. Holds only: the
   Phase 0 parameters, file paths, per-batch/phase one-line summaries, and
   stop-rule logic. Appends to the orchestration log at every phase and batch
   boundary and keeps `state.md` current. Never reads plan bodies, diffs,
   reviewer reports, or fix reports.
2. **Controllers (fresh subagents, one per phase or batch).** Each controller
   is dispatched with a filled prompt template, executes its phase by
   following the canonical SKILL.md of the corresponding existing skill
   (read as a file — never via the Skill tool), communicates detail through
   files, and returns a short status contract (hard cap 15 lines).

Batch controllers additionally dispatch **nested** worker subagents (the
existing SDD implementer / task-reviewer / fix flow). Nested dispatch
(subagent spawning subagents via the Agent tool) was verified working in this
environment on 2026-08-04.

### Data flow

```
spec (docs/specs/…-design.md)
  └─ Phase 1: plan-writer ──────────► plan (docs/plans/…​.md)
       └─ Phase 2: doc-review-loop ─► plan (revised) + <plan>-review-log.md
            └─ Phase 3: batch-controller × ⌈T/cap⌉
                 │  nested: implementer → task reviewer → fix subagent per task
                 └────────────────────► commits, plan checkboxes,
                                        .superpowers/sdd/progress.md (ledger)
                      └─ Phase 4: code-review-loop ─► fix commits,
                                        .superpowers/reviews/feature-<slug>-review-log.md
                           └─ Phase 5: summary → finishing-a-development-branch (interactive)

Orchestrator writes throughout: docs/plans/…-orchestration-log.md, state.md
```

### Procedure-by-File-Reference

Controllers get their procedure by reading the existing skill's `SKILL.md`
from the plugin installation (the orchestrator resolves each path from its
own skill base directory: `../<skill-name>/SKILL.md`). Each prompt template
names the sections that apply and the sections to skip, plus the autonomy
deviations. This keeps a single canonical source (no drift between templates
and skills) without subagents invoking the Skill tool — the Subagent Skill
Leakage Prevention rule stays intact. Templates instruct controllers to skip
skill announcement lines and to open every return with the
`<!-- orchestration report -->` marker (guard interaction, below).

## Phase Specifications

### Phase 0 — Setup (interactive; the only questions of the run)

Inputs: spec path (from the invocation phrase, or from brainstorming's
handoff; if absent, ask for it in the same question batch below).

1. **Platform check:** Agent tool available, else refuse:
   `orchestrating-development requires subagent dispatch (Agent tool), which this platform lacks.`
2. **Ask once (single batch):** N_plan (integer 0–10, default 3), N_code
   (integer 0–10, default 3), batch cap (integer 1–5, default 3 — the
   ceiling is 5 because nothing but the cap bounds a batch controller's
   context; see the cap sizing note in Phase 3). Invalid values → the
   default. N=0 for either loop means the orchestrator skips that phase
   entirely — no controller is dispatched; the orchestration log records
   the skip (`## Phase 2 — Plan review — skipped (N_plan=0)` /
   `## Phase 4 — Code review — skipped (N_code=0)`).
   The same question batch also carries two confirmations, because this is
   the user's last interaction before hours of autonomy:
   - **Branch point:** state the current branch and `HEAD` sha the feature
     branch will be cut from, and whether that is the repo's default
     branch. A non-default branch point requires explicit confirmation
     (default: abort) — an unattended run stacked on a stale feature
     branch completes "successfully" and surfaces the mistake only at
     merge, after the full cost is sunk.
   - **Permissions:** remind the user the run is unattended and every
     permission prompt stalls it indefinitely; ask them to confirm the
     session's permission mode will not prompt for the pipeline's edit /
     Bash / Agent calls (auto-accept or allowlist) before proceeding.
3. **Local ignores (before the clean-tree check):** ensure `state.md` and
   `.superpowers/` are matched by the repository's exclude file, resolved
   via `git rev-parse --git-path info/exclude` — the literal
   `.git/info/exclude` path does not exist in a linked worktree, where
   `.git` is a file. This must precede step 4: a `state.md` left by prior
   normal-flow use (writing-plans, SDD) is otherwise untracked noise that
   would spuriously fail the clean-tree check on the first orchestrated run
   in a clone. Excluding rather than gitignoring keeps the sub-skills'
   clean-tree checks meaningful without polluting the repo's `.gitignore`.
4. **Preconditions:** current directory is a git repo; the spec file
   exists; the computed plan path and orchestration log path (step 7) do
   not already exist (a same-slug leftover from an earlier run must never
   be silently overwritten); `git status --porcelain` is empty EXCEPT that
   the spec file and its `<spec-basename>-review-log.md` sidecar may be
   untracked or modified — brainstorming leaves them uncommitted, so the
   normal flow arrives here with exactly that dirt. Any other dirt → stop
   and report; never stash or commit the user's unrelated changes.
5. **Branch:** create and switch to `feature/<slug>` from current HEAD.
   `<slug>` = the spec basename with the `YYYY-MM-DD-` prefix and `-design`
   suffix each stripped *only if present* (a non-conforming spec filename
   still yields a deterministic slug from its remaining basename). If the
   branch exists already, stop — and disambiguate before suggesting
   anything: read the existing orchestration log for that slug (if any) and
   compare its recorded spec path with the invoked spec. Same spec →
   report "prior run" and suggest the resume prompt. Different or missing
   spec → report "unrelated prior run with the same slug" and tell the
   user to rename the spec (different slug) or clear the old branch —
   never suggest resuming a run that belongs to another spec (date-stripped
   slugs collide across dates: `2025-01-10-auth-design` and
   `2026-08-04-auth-design` both yield `feature/auth`).
6. **Commit inputs:** if the spec and/or its review-log sidecar were dirty
   in step 4, commit them now on the feature branch
   (`docs(spec): <slug> design`).
7. **Log:** create `docs/plans/YYYY-MM-DD-<slug>-orchestration-log.md`
   (orchestration start date) with the invocation header (format below),
   recording BASE = `git rev-parse HEAD` (the branch point; Phase 4 uses it
   as MERGE_BASE). Commit the log file on the feature branch
   (`chore: start orchestration log`).
8. **Seed `state.md`** (same sections writing-plans seeds, plus
   `## Orchestration` with phase/batch position and the Phase 0 parameters).

From here to Phase 5, the orchestrator never asks the user anything.

### Phase 1 — Plan writing

Dispatch **plan-writer** controller. Procedure source:
`writing-plans/SKILL.md` — sections through Self-Review apply; the
Multi-Round Plan Review and Execution Handoff sections are explicitly skipped
(the orchestrator owns both). Inputs: spec path, output plan path
`docs/plans/YYYY-MM-DD-<slug>.md` (computed by the orchestrator, same date
and slug as the log). Autonomy deviation: writing-plans says to ask
clarifying questions for ambiguous features — the controller instead derives
answers from the spec and repository; if underivable, it returns
`BLOCKED: <the question>` and the orchestrator stops (spec ambiguity is a
major error).

Return contract: `PLAN_READY <path> tasks=<T>` or `BLOCKED: <question>`.

The orchestrator then commits the plan (`docs(plan): <slug> implementation plan`)
and logs Phase 1.

### Phase 2 — Plan review loop

Dispatch **doc-review-loop** controller. Procedure source:
`multi-doc-review/SKILL.md` (whole skill), with parameters injected: target =
plan path, doc type `plan`, spec path, N = N_plan, invoker recorded as
`gate: orchestration`. The controller runs the full loop itself — dispatching
one nested reviewer per round, triaging findings into the plan, writing
`<plan-basename>-review-log.md` — exactly as the skill specifies. Autonomy
deviation: never ask for N (injected); the after-loop host self-review is
writing-plans' Self-Review checklist — the template therefore also passes
the `../writing-plans/SKILL.md` path and names its Self-Review section (a
fresh-context controller has no other way to hold that checklist).

Further template deviations (multi-doc-review's log has no completion
marker or unresolved disposition of its own):
- **End-of-loop line:** the controller appends
  `_Loop complete — YYYY-MM-DD — rounds <r>_` to the plan review log when
  the loop finishes. An invocation entry without that line is an
  interrupted loop: a resumed controller continues at the next round
  (counting existing `## Round` entries) — the once-per-gate rule blocks
  re-running a *completed* loop, never continuing its own interrupted one.
  The orchestration log's Phase 2 entry remains the completion authority.
- **Unresolved findings:** a Critical/Important finding counts as
  `unresolved` only when applying it was attempted and failed twice (the
  merge would contradict the spec or another applied finding); the
  controller logs it as `- [X] unresolved: <reason> — <finding summary>`
  and includes it in the return count. Apply-or-reject remains the normal
  path.

Return contract:
`REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>` or
`BLOCKED: <reason>`. `unresolved > 0` is a major error → stop.

The orchestrator commits the revised plan + review log and logs Phase 2.

### Phase 3 — Implementation batches

Loop until every plan task checkbox is checked:

1. Read only the plan's task headers/checkboxes (cheap scan) and select the
   next ≤ cap unchecked tasks, in plan order. **Task-complete predicate:**
   a task is complete ⇔ every checkbox under its `### Task N` heading is
   checked (writing-plans' template uses per-step checkboxes, ~5 per task,
   with no single per-task box); "unchecked task" = any box under the
   heading unchecked. Batch controllers must tick all of a task's step
   boxes on completion — the cross-check in step 5 and Phase 5's
   completeness check both key on this predicate.
2. Dispatch **batch-controller** with: plan path, the explicit task numbers,
   the SDD skill directory path (for `SKILL.md`, `scripts/`, and the
   implementer/task-reviewer prompt templates), and the ledger/workspace
   convention. Procedure source: SDD's per-task flow (Core Flow steps 3,
   File Handoffs, Handling Implementer Status, Handling Reviewer ⚠️ Items,
   Constructing Reviewer Prompts, Durable Progress, Model Selection) plus the
   Batched Autonomous Mode Autonomy Policy. The first batch also runs SDD's
   Pre-Flight Plan Review; any conflict → `BLOCKED`.
3. The batch controller: runs `scripts/sdd-workspace PLAN_FILE` (idempotent
   for the same plan), then per task — brief via `scripts/task-brief`,
   implementer dispatch, review package via `scripts/review-package BASE HEAD`
   (BASE recorded per task), task reviewer, fix cycles, checkbox update,
   ledger line. Sequential; full review gates (both verdicts); security-flagged
   tasks get the pre-implementation security review. Never asks the user;
   NEEDS_CONTEXT answered from plan/spec/repo or escalated to `BLOCKED`.
4. Return contract: `BATCH_COMPLETE tasks=<i>..<j>` followed by one line per
   task (`Task <n>: complete commits <base7>..<head7>`), or
   `BLOCKED task=<n>: <one-line reason>` (detail in the task's report file).
   `BATCH_COMPLETE` asserts every listed task completed with a clean review —
   there is no partial-success return: any task that cannot reach that state
   makes the whole return `BLOCKED` for that task (earlier completed tasks
   in the batch keep their checkboxes and commits; the orchestrator's next
   selection naturally excludes them).
5. **Checkbox cross-check:** after each `BATCH_COMPLETE`, the orchestrator
   re-scans the reported task numbers' checkboxes in the plan. Any task
   reported complete whose checkbox is still unchecked → major error → stop
   (a well-formed return contradicted by file state must never silently
   re-enter the selection loop — that is the unbounded re-implementation
   failure mode).
6. Orchestrator logs the batch, updates `state.md`, and continues.
   `BLOCKED` → major error → stop.

Model policy: controllers inherit the session model with a sonnet floor
(mirroring multi-code-review's reviewer-model rule); nested implementers/
reviewers follow SDD's Model Selection table, chosen by the batch controller.

Cap sizing note: a batch controller has no context-pressure boundary — SDD's
60% check belongs to the batch loop the orchestrator replaces — so the cap
alone bounds controller context; that is why Phase 0 caps it at 5. On a
controller death, tasks completed before the failure are already
checkbox-ticked and ledger-recorded, so the retried controller (idempotent
`sdd-workspace`, same plan) skips them.

**Retried controller, mid-task death (mandatory procedure):** a controller
that died mid-task leaves orphan commits on the branch with the task's
checkboxes unchecked and no ledger line — and those commits must not
bypass the task-review gate. The batch-controller template requires, for
each assigned task that is unchecked at controller start: determine
REVIEW_BASE = the HEAD recorded by the last ledger line (or the batch's
starting HEAD if none), check `git log REVIEW_BASE..HEAD` for existing
commits touching the task, and if any exist, dispatch the implementer with
an explicit partial-work note (verify existing behavior and tests rather
than expecting a fresh TDD fail step) and build the task's review package
from REVIEW_BASE — so the first attempt's orphan commits are reviewed
together with the completion. Never apply SDD's crash-reconciliation
shortcut ("commits present → mark complete and advance") inside a batch:
that shortcut skips the review gate.

### Phase 4 — Final code review loop

Precondition: orchestrator commits any uncommitted orchestration-log edits
first (the sub-skill's clean-tree check must pass).

Dispatch **code-review-loop** controller. Procedure source:
`multi-code-review/SKILL.md` (whole skill), parameters injected: BASE = the
Phase 0 recorded branch point, N = N_code, plan path, carried Minor findings
= the ledger path (`.superpowers/sdd/progress.md`), invoker recorded as
`gate: orchestration`. Autonomy deviations = the skill's own Batched
Autonomous Mode rules: never ask for N; plan-mandated/user-decision findings
are journaled and returned as blocking. Two explicit template deviations,
because neither consumed skill defines a `gate: orchestration` invoker kind:
(a) multi-code-review's in-progress sentinel treats a `gate: orchestration`
entry as a matching invoker kind (same BASE → resume automatically, as its
Batched Autonomous Mode rule does for `gate: sdd`); (b) its once-per-gate
completion skip extends to `gate: orchestration` entries with matching
completion-marker HEAD and branch. Independently of (b), the orchestrator
never re-dispatches a loop its own log records as completed — the
orchestration log's phase entry is the primary re-run guard for Phases 2
and 4; the sub-skill logs are the backstop.

Return contract:
`REVIEW_DONE rounds=<r> outcome=<converged|cap> fixes=<n> unresolved=<n> user_decision=<n>`
or `BLOCKED: <reason>`. `unresolved > 0` or `user_decision > 0` → major
error → stop (the findings are already journaled in the review log; the
orchestrator's stop entry points there).

The carried-Minors input is extracted, not passed as a path: the controller
reads the ledger and fills the reviewer template's carried-findings
placeholder with the `Minor:` lines only (multi-code-review expects a list,
not a file reference). If the ledger is absent — excluded scratch does not
survive a clone boundary or `git clean -fdx` — the controller proceeds but
logs `carried findings unavailable — ledger absent` in the review log, so
the loss is visible instead of silently reviewing with an empty list.

**Known interaction — orchestration artifacts in the review diff.** The
branch's diff necessarily contains the committed orchestration log, the
plan, plan checkbox ticks, and the plan/spec `*-review-log.md` sidecars —
and multi-code-review's reviewer prompt explicitly treats a diff that adds
or modifies a `*-review-log.md` path as reportable, while
`*-orchestration-log.md` matches no skip rule at all, so reviewers read its
full, perpetually-changing content every round. The code-review-loop
template therefore carries a documented triage rule: any finding whose
subject file is one of these orchestration artifacts — presence,
modification, or content — is rejected as
`rejected: orchestration artifact (documented)`. A fix subagent is never
dispatched against an audit log: content findings on it are exactly the
route by which a fixer would edit or delete the audit trail. Because rejections
never make a round clean (multi-code-review's rule), a run whose reviewers
grade this Critical/Important every round reaches cap instead of
converging — an accepted degradation, not an error.

On success, the orchestrator appends the Phase 4 log entry and commits the
log before Phase 5 begins (so Phase 5's clean-tree check is meaningful).

### Phase 5 — Completion

1. Verify every plan checkbox is checked and `git status --porcelain` is
   clean; discrepancy → stop and report (never silently reconcile).
2. Append the completion marker to the orchestration log; commit the log.
3. Report the run summary to the user: tasks completed, batches run, plan
   review rounds/outcome, code review rounds/fixes/outcome, stop-worthy
   events (none, if reached), and the three log paths (orchestration, plan
   review, code review).
4. Invoke `finishing-a-development-branch` (interactive — merge/PR/keep/
   discard is the user's call).

## Subagent Contracts (summary)

All controllers: dispatched via the Agent tool, `general-purpose` type,
session model with sonnet floor; prompt built ONLY from the filled template
(no conversation history); hard return cap 15 lines; detail goes to files;
must not use the Skill tool; nested worker prompts must include SDD's
leakage-prevention line. **Every controller return's first line is exactly
`<!-- orchestration report -->`** (guard exemption — see Guard and Leakage
Interactions); the contract's leading token is the first line after the
marker. Returns should still avoid naming plugin skills gratuitously, but
the marker — not phrasing discipline — is what makes free-text `BLOCKED`
reasons safe.
Controllers never write `state.md` — the orchestrator is its only writer.
A batch controller's blocker question goes in the blocked task's report
file (SDD's Autonomy-Policy instruction to journal into `state.md` is
explicitly overridden by the template); the orchestrator journals it under
`## Open Issues` at the stop.

A return is **malformed** when the marker line or the leading token is
absent OR any field the orchestrator's rules consume (`tasks=`, per-task numbers, `rounds=`,
`outcome=`, `unresolved=`, `user_decision=`, `fixes=`) is absent or
unparseable — an unparseable stop-rule field never defaults to 0, because a
defaulted 0 would silently bypass a major-error stop. Malformed return or
controller error → retry the identical dispatch once; second failure →
major error → stop, logging `inconclusive controller: <phase/batch>`.

## Orchestration Log Format

```
# Orchestration Log — <slug>

_Invocation 1 — YYYY-MM-DD — spec docs/specs/<spec>.md — N_plan=<n> N_code=<n> cap=<n> — branch feature/<slug> — BASE <sha7>_

## Phase 1 — Plan — DONE — YYYY-MM-DD
plan: docs/plans/<plan>.md — <T> tasks

## Phase 2 — Plan review — rounds <r> — <converged|cap> — unresolved 0

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits <base7>..<head7>
- Task 1: complete — <one-line>
- Task 2: complete — <one-line>
- Task 3: complete — <one-line>

## Phase 4 — Code review — rounds <r> — <converged|cap> — fixes <n> — unresolved 0

_Completed — YYYY-MM-DD — HEAD <sha7>_
```

A stop writes instead:

```
## STOPPED — YYYY-MM-DD — phase <p> — <one-line reason>
Detail: <path to the file holding the blocker detail>
Resume: Resume orchestration for docs/plans/<plan>.md
```

Skipped loops (N=0) replace the Phase 2/4 line with
`## Phase 2 — Plan review — skipped (N_plan=0)` /
`## Phase 4 — Code review — skipped (N_code=0)`.

Round-by-round review detail lives in the sub-skills' own logs, never
duplicated here. The orchestration log is committed at Phase 0, after
Phases 1–2, after each batch, after Phase 4, and at completion/stop — every
entry is committed before the next phase begins, so the log in git history
is itself the crash-safe position record and the tree is clean at each
phase boundary.

## state.md Integration and Resume

At every phase/batch boundary the orchestrator rewrites the plan-execution
sections of `state.md` (SDD's shape, hard cap 100 lines) plus:

```
## Orchestration
Spec: docs/specs/<spec>.md  Plan: docs/plans/<plan>.md
Params: N_plan=<n> N_code=<n> cap=<n>  Branch: feature/<slug>  BASE: <sha7>
Position: phase <p>[, next batch tasks <i>–<j>]
```

**Resume procedure** (trigger phrase: `Resume orchestration for
docs/plans/<plan>.md` — or the spec path, for a Phase 1 stop):

0. **Preconditions (a fresh session is the normal case):** derive
   `feature/<slug>` from the named plan/spec path; verify the branch exists
   (else stop — nothing to resume) and check it out if not already on it;
   re-ensure the exclude entries from Phase 0 step 3 first, via
   `git rev-parse --git-path info/exclude` (a different clone lacks them;
   linked worktrees of the same clone share the file, but re-ensuring is
   idempotent either way); then require `git status --porcelain` empty
   (else stop and report).
1. Read the orchestration log (authoritative for parameters and last
   completed phase), `state.md` (narrative, may be one step stale), the
   plan's checkboxes (if the plan exists yet), and recent `git log`.
2. If the log's last entry is `_Completed_`, report that and stop.
3. If the last entry is `## STOPPED` with a blocking question the resume
   prompt does not answer, present the question and stop — never execute
   past an unanswered blocker.
4. Otherwise continue at the first incomplete phase/batch. Sub-skill
   once-per-gate rules (plan review log invocation entries;
   multi-code-review's completion-marker check) prevent re-running completed
   loops; plan checkboxes + git prevent re-implementing completed tasks.
5. Phase 0 questions are never re-asked — parameters come from the log's
   invocation line — but the resume prompt MAY override them explicitly
   (e.g. `Resume orchestration for docs/plans/<plan>.md with cap=2`).
   An override appends a new invocation line to the orchestration log
   (`_Invocation 2 — date — <changed params> — resumed_`) so the recorded
   parameters never silently diverge from the run. This is the designed
   escape from a parameter-caused stop (a cap-exhausted controller failing
   twice would otherwise stop again identically on every resume).
6. **Excluded state does not survive clone boundaries or `git clean -fdx`:**
   the SDD ledger, `state.md`, and workspace report files (including any
   `Detail:` paths in `## STOPPED` entries) are local scratch. Resume in a
   fresh clone proceeds from the log + plan + git alone; anything lost is
   reported, never silently reconstructed.

**Abandoning a run:** on request (`Abandon orchestration for
docs/plans/<plan>.md`), confirm once, then: delete the feature branch
(refuse if it is checked out elsewhere or already merged — report instead),
and state what remains (the branch carried the plan, logs, and commits;
excluded scratch under `.superpowers/` and `state.md` sections are cleaned
per their own skills' rules). This is the sanctioned teardown for a wedged
or superseded run — without it, Phase 0's never-overwrite preconditions
would leave no documented path to start over.

## Major-Error Policy (exhaustive stop list)

Two stop shapes, split by whether the run's artifacts exist yet:

- **Pre-log stop (Phase 0, any failure before the log exists — steps 1–6):**
  report the failure to the user and stop. Nothing further is written or
  committed, no resume line (there is no run to resume; the user fixes the
  precondition and starts fresh). If the failure landed after step 5, name
  the already-created branch in the report so the user can delete it. This
  is the shape Phase 0's "stop and report" means; it never conflicts with
  the no-commits-on-a-dirty-tree rule.
- **In-run stop (Phase 1 onward):** append `## STOPPED` to the log, commit
  it, update `state.md` `## Open Issues` (blocking items first), report to
  the user with the resume prompt. If the stop occurs before the plan file
  exists (Phase 1 `BLOCKED`), the resume line names the spec instead:
  `Resume: Resume orchestration for docs/specs/<spec>.md` — resume then
  re-dispatches the plan-writer (with the blocker's answer, which the
  resume prompt must supply).

Stop on:

1. Phase 0 precondition failure (dirty tree, missing spec, existing branch,
   pre-existing plan/log path, no Agent tool) — pre-log stop shape.
2. Plan-writer `BLOCKED` (spec ambiguity underivable from spec/repo).
3. Doc-review loop: unresolved Critical/Important after triage, or the loop
   itself failing (all rounds inconclusive).
4. Pre-flight plan conflict (first batch).
5. Batch controller `BLOCKED`: implementer blocked after SDD's autonomous
   remedies, verification failing twice, plan ambiguity, or a review finding
   that conflicts with plan text (user-decision).
6. Code-review loop: unresolved or user-decision findings remaining.
7. Any controller malformed/failed twice.
8. Git surprises mid-run: branch changed under the orchestrator, unexpected
   dirty tree at a phase boundary.

Everything else is handled autonomously inside the controllers per the
existing skills' rules (fix cycles, re-dispatches, model upgrades).

## Guard and Leakage Interactions

- Controllers follow file-referenced procedures; the Skill tool is forbidden
  to them. Nested worker prompts carry SDD's standard leakage-prevention
  instruction.
- `hooks/subagent-guard.js` blocks subagent final messages that pair an
  action verb with a roster skill name and carry no sanctioned marker. The
  terse return contracts alone cannot guarantee safety: `BLOCKED: <question>`
  and `BLOCKED task=<n>: <reason>` are free text, and on skill-repos a
  blocker question naturally reads like "should Task 3 use executing-plans
  semantics" — a verb+name match that would block the return, force a redo
  that trips the same match, and hang the unattended run precisely on its
  only escape hatch. Therefore the exempt marker is part of the initial
  implementation, not a fallback: **every controller return OPENS with
  `<!-- orchestration report -->`**, the guard exempts that marker (a
  behavior change to `subagent-guard.js`), and a unit test in
  `tests/codex/` feeds a skill-naming `BLOCKED` return through the guard
  to prove the exemption. Hook wiring files are unaffected (the change is
  inside the guard script), but the guard is shared across platforms —
  run the cross-platform checklist after the change.
- The doc-review-loop and code-review-loop controllers' nested reviewers
  already emit `<!-- multi-review report -->`, which the guard exempts.
- **Sanctioned nested dispatch (design decision, recorded here on
  purpose):** `subagent-guard.js`'s header states its intent as blocking
  subagents that "spawn recursive sub-subagents" — this design's batch
  controllers do exactly that, deliberately. Nested dispatch currently
  passes because the guard is a final-message text matcher, and this spec
  makes that sanctioned rather than incidental: implementation must amend
  the guard's header comment to state that controller-style nested
  dispatch under orchestrating-development is intended behavior
  (comment-only change, no behavior change), so a future guard
  strengthening cannot "fix" the guard against this feature by accident.
- Known exposure: SDD's nested *task reviewers* return reports as final
  messages with no exempt marker; on repos whose files legitimately
  discuss skills (this plugin repo — the designated first-run integration
  test — above all), the guard can false-positive block those reports
  mid-batch, degrading a task review to a redo loop. Pre-existing SDD
  behavior, inherited unchanged; with the `<!-- orchestration report -->`
  marker now in the guard, extending it to nested task-reviewer reports is
  a cheap follow-up if the first run hits this.

## Repo Touches

| File | Change |
|---|---|
| `skills/orchestrating-development/SKILL.md` | New — orchestrator procedure |
| `skills/orchestrating-development/plan-writer-prompt.md` | New template |
| `skills/orchestrating-development/doc-review-loop-prompt.md` | New template |
| `skills/orchestrating-development/batch-controller-prompt.md` | New template |
| `skills/orchestrating-development/code-review-loop-prompt.md` | New template |
| `hooks/skill-rules.json` | New routing entry (keywords, intentPatterns for "orchestrate …", "resume orchestration …") |
| `skills/brainstorming/SKILL.md` | One line in the User Review Gate message offering orchestration |
| `tests/codex/test-skill-activator.js` | Routing-rank tests via its `topSkill()` helper (rank, not presence — presence-only assertions are a known trap in this repo); optional deferred prompt files in `tests/skill-triggering/` |
| `hooks/subagent-guard.js` | Add `<!-- orchestration report -->` exempt marker (behavior change, unit-tested in `tests/codex/`); header-comment amendment recording sanctioned controller nested dispatch |
| Version files | `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, README badge, `RELEASE-NOTES.md` |

The guard marker is the single hook behavior change; everything else is
additive.

## Error Handling (orchestrator-level summary)

| Failure | Handling |
|---|---|
| Controller malformed return / error | Retry identical dispatch once → stop |
| Controller `BLOCKED` | Stop (major error), journal, resume prompt |
| Sub-skill internal failures | Handled inside per that skill's own error rules; surfaced only if they escalate to `BLOCKED`/unresolved |
| Log/plan commit fails (hooks, conflicts) | Stop and report verbatim git output |
| Resume with missing artifacts (log deleted, plan moved) | Stop; report what is missing; suggest starting a fresh orchestration |

## Testing Strategy

1. **Routing-rank unit tests** (`tests/codex/test-skill-activator.js`, via
   its existing `topSkill()` helper — this is where rank assertions live;
   `tests/skill-triggering/` is the separate slow CLI behavioral suite):
   "orchestrate the development of docs/specs/x-design.md", "run the whole
   pipeline autonomously from the spec", and "Resume orchestration for
   docs/plans/x.md" must rank `orchestrating-development` first; existing
   skills' triggers must not regress. "Full suite" here means the fast
   unit suite: `bash tests/codex/run-unit-tests.sh`. Behavioral prompt
   files under `tests/skill-triggering/` are optional and deferred with
   the other behavioral tests.
2. **Explicit-request tests** (`tests/explicit-skill-requests/`): "use
   orchestrating-development" resolves to the skill (same deferred-
   behavioral caveat).
3. **Guard unit test** (`tests/codex/`): a controller-style return opening
   with `<!-- orchestration report -->` and containing a skill-naming
   `BLOCKED` reason (e.g. "use executing-plans") passes the guard;
   the same text without the marker is blocked.
4. **Template lint (manual checklist in the plan):** every placeholder in
   the four templates is filled by the orchestrator procedure; return
   contracts match the strings SKILL.md parses.
5. **Behavioral smoke (deferred, optional):** a `tests/claude-code/` case
   for Phase 0 refusal on a dirty tree. Full-pipeline behavioral tests are
   out of scope (30+ min, real implementer runs).
6. **First-run validation:** the first real orchestration run is the
   integration test; the log format makes divergence auditable.

## Rollout

Standard release: version bump across all files listed above, RELEASE-NOTES
entry, reinstall the local plugin before any behavioral testing (sessions run
the installed copy, not this working tree). No migration concerns — the
skill is additive; existing workflows (manual writing-plans → SDD) are
untouched.

## Accepted Risks (failure-mode check outcomes)

1. **A flawed plan reaches implementation without human review** — accepted
   by the no-pause decision; mitigated by N_plan review rounds and the
   never-best-guess-ambiguity stop rule.
2. **Nested dispatch is an environmental assumption** — verified in this
   environment (2026-08-04) by dispatching a `general-purpose` subagent
   that itself dispatched a trivial nested agent and echoed its reply; the
   check is reproducible by repeating that one-off dispatch (an implementer
   may re-run it before relying on nesting). If unavailable, batch
   controllers fail fast and the orchestrator stops with a clear error
   rather than degrading review isolation.
3. **Controller misreads a scoped SKILL.md section** — mitigated by explicit
   section lists in templates and by the unchanged review gates catching
   downstream damage; residual risk accepted.
4. **Long unattended runs accumulate cost** — inherent to the feature;
   the Phase 0 question batch is the user's cost-control point (N values,
   cap), and every subagent is single-purpose with file handoffs.
