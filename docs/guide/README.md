# Superpowers Optimized — User Guide

_Guide last reviewed against plugin version **6.15.1**._

This is the day-to-day operating manual for the plugin: which phrases trigger
which workflow, what the pipelines look like end to end, and what to do when
something is interrupted. For the feature pitch and full skills catalog, see
the [main README](../../README.md). For internals, see
[docs/architecture/](../architecture/).

The guide is organized by intent — find the section matching what you want to
do. Authoritative parameter detail always lives in each skill's `SKILL.md`;
this guide documents the stable user surface and links there.

> Screenshot convention: images live in [`images/`](images/), named by topic
> (`orchestration-phase0-questions.png`, not by date), with the plugin version
> in the caption.

---

## Contents

1. [Quick start — your first session](#1-quick-start--your-first-session)
2. [Installing and staying up to date](#2-installing-and-staying-up-to-date)
3. ["I want to build a feature" — the main pipeline](#3-i-want-to-build-a-feature--the-main-pipeline)
4. ["I want an autonomous run" — orchestrating development](#4-i-want-an-autonomous-run--orchestrating-development)
5. ["My run was interrupted" — resuming and recovering](#5-my-run-was-interrupted--resuming-and-recovering)
6. ["How does it remember?" — the memory system](#6-how-does-it-remember--the-memory-system)
7. [Context pressure and the statusline bridge](#7-context-pressure-and-the-statusline-bridge)
8. [Phrase cheat-sheet](#8-phrase-cheat-sheet)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Quick start — your first session

<!-- TODO: What happens when a session starts (using-superpowers loads, task
gets classified micro/lightweight/full), what the user sees, and the one rule
that matters: name a skill and it WILL be invoked via the Skill tool. Show one
tiny end-to-end example (a small fix) and one routed example (a feature request
landing in brainstorming). -->

📸 _Screenshot: session start with the superpowers banner / skill suggestion._

## 2. Installing and staying up to date

<!-- TODO: Point to README install instructions rather than duplicating them.
Cover what the README does not: the installed-copy distinction (sessions run
`~/.claude/plugins/cache/superpowers-optimized/`, NOT your checkout — editing
the repo changes nothing until you update the plugin); how updates arrive
(marketplace update); post-update steps (re-run install-statusline-bridge.sh
to refresh the stable statusline copy). -->

## 3. "I want to build a feature" — the main pipeline

<!-- TODO: The core workflow walkthrough:
brainstorming (design doc + review gate) → writing-plans (task decomposition,
plan review) → execution (executing-plans, or subagent-driven-development for
parallel/batched work) → verification-before-completion →
finishing-a-development-branch (merge/PR/keep/discard).
For each stage: what triggers it, what artifact it produces (spec in
docs/specs/, plan in docs/plans/), and what the user decides at each gate.
Include where multi-doc-review and multi-code-review slot in. -->

📸 _Screenshot: a plan file with task checkboxes mid-execution._

### Batched autonomous mode

<!-- TODO: "implement the next N tasks" — cap-only batch boundary (user count,
default 3), the 60% start gate for mid-session starts, handoff into state.md,
resume after /clear. -->

## 4. "I want an autonomous run" — orchestrating development

The `orchestrating-development` skill drives an **approved spec** through the
entire pipeline with no interaction after setup: plan writing → N plan-review
rounds → batched implementation → N whole-branch code-review rounds. It runs
for hours unattended, stops only on major errors, and always ends *before*
merge — creating the PR or merging is your call, made interactively at the
end via `finishing-a-development-branch`.

What it will **never** do: merge or open a PR on its own, ask you questions
mid-run, stash or commit unrelated changes it finds in your tree, or silently
reconcile inconsistent state — anything suspicious is a stop, not a guess.

Authoritative detail:
[`skills/orchestrating-development/SKILL.md`](../../skills/orchestrating-development/SKILL.md).

### Prerequisites

- **An approved spec** in `docs/specs/` — usually produced by `brainstorming`
  (§3). Orchestration starts *from* a spec; it does not design one.
- **Claude Code only.** The pipeline needs nested subagent dispatch (the
  orchestrator spawns controllers, which spawn workers). On other platforms
  the skill refuses with one line.
- **A clean working tree**, except the spec and its review-log sidecar
  (brainstorming leaves those uncommitted; orchestration commits them for
  you). Any other dirt stops setup — it will not touch your unrelated changes.
- **Pre-authorized permissions** — see the Phase 0 warning below.

### Starting a run

```
orchestrate the development of docs/specs/2026-08-04-my-feature-design.md
```

### Phase 0 — the only conversation you'll have

Setup asks everything in **one question batch**. After you answer, the next
thing you hear is completion or a stop.

| Question | Range | Default |
| --- | --- | --- |
| `N_plan` — plan-review rounds | 0–10 (0 = skip) | 3 |
| `N_code` — code-review rounds | 0–10 (0 = skip) | 3 |
| Batch cap — tasks per implementation batch | 1–5 | 3 |

The same batch asks for two confirmations:

- **Branch point** — it states the branch and commit the feature branch will
  be cut from. Cutting from a non-default branch requires explicit
  confirmation (default: abort).
- **Permissions** — the run is unattended, and **a single permission prompt
  stalls it indefinitely**: a subagent waiting on an approval dialog nobody
  will answer. Before confirming, make sure the session can run the
  pipeline's edit/Bash/Agent calls without prompting (pre-approve in
  `.claude/settings.json`, or run with permissions accepted for the session).
  This is the most common cause of a "hung" run.

📸 _Screenshot: the Phase 0 question batch. (v6.15.1)_

### What happens while you're away

| Phase | What it does | Artifact |
| --- | --- | --- |
| 1 — Plan | Writes the implementation plan from the spec | `docs/plans/<date>-<slug>.md` |
| 2 — Plan review | N independent review rounds, findings applied between rounds | plan review-log sidecar |
| 3 — Implementation | Tasks in batches of ≤ cap; each task test-driven, reviewed, and committed with its checkbox ticked | commits on `feature/<slug>` |
| 4 — Code review | N whole-branch review rounds with fixes applied | `.superpowers/reviews/` log |
| 5 — Completion | Verifies every checkbox and a clean tree, then hands over | final report |

Each phase runs in a fresh controller subagent; the orchestrator itself stays
lean and moves all state through files committed at every boundary — which is
what makes interrupted runs recoverable (§5).

### Watching progress

The orchestration log is the run's public face:
`docs/plans/<date>-<slug>-orchestration-log.md`, committed at every boundary.
Tail it from another terminal:

```
# Orchestration Log — my-feature

_Invocation 1 — 2026-08-08 — spec docs/specs/2026-08-04-my-feature-design.md — N_plan=3 N_code=3 cap=3 — branch feature/my-feature — BASE a1b2c3d_

## Phase 1 — Plan — DONE — 2026-08-08
plan: docs/plans/2026-08-08-my-feature.md — 7 tasks

## Phase 2 — Plan review — rounds 2 — converged — unresolved 0

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits a1b2c3d..e4f5a6b
- Task 1: complete — added parser with regression tests
```

The plan's task checkboxes are the other live signal — each tick is committed
the moment its task completes.

📸 _Screenshot: an orchestration log mid-run. (v6.15.1)_

### When it stops instead of finishing

Any major error — a blocked controller, unresolved review findings, a plan
inconsistency, the branch changed under it — appends a `## STOPPED` entry to
the log with the reason, a pointer to the detail file, and the exact resume
prompt to use. Nothing is lost: everything up to the stop is committed. See
§5 for resuming, overriding parameters on resume, and abandoning a wedged run.

### On completion

You get a summary (tasks, batches, review rounds and outcomes, the three log
paths), and `finishing-a-development-branch` takes over interactively —
merge, PR, keep, or discard is yours to decide.

## 5. "My run was interrupted" — resuming and recovering

Every long-running workflow in this plugin — orchestrated or not — keeps its
position in **files and git, never in the conversation**. The plan's task
checkboxes are ticked and committed the moment each task completes; commits
land per task; `state.md` carries the narrative. A crash, a killed terminal,
a `/clear`, or a power loss therefore loses at most the work in flight since
the last completed task — everything earlier is already on disk and in
history. Recovery is always the same idea: a fresh session reads the files,
reconciles them against git, and continues at the first genuinely
incomplete step.

What differs is the resume phrase and a few caveats, by workflow:

### Orchestrated runs

Two interruption shapes, one resume phrase:

- **Deliberate stop** (major error): the orchestration log ends with a
  `## STOPPED` entry naming the reason, a pointer to the detail file, and the
  exact resume prompt to paste.
- **Crash / power loss**: no `STOPPED` entry — the log simply ends at the
  last committed boundary. Resume infers the position from the log, the
  plan's checkboxes, and recent git history.

Either way:

```
Resume orchestration for docs/plans/2026-08-08-my-feature.md
```

Resume checks out the feature branch, reads the log (authoritative for
parameters and last completed phase), and continues at the first incomplete
phase or batch. It **never re-asks the Phase 0 questions** — parameters come
from the log — but you may override them per-parameter in the resume prompt
(`... with cap=2`), which is also the designed escape when a parameter caused
the stop. Mid-batch, already-completed tasks keep their ticked checkboxes and
commits and are skipped; orphan commits from a half-finished task are
reviewed together with the task's completion, never blindly trusted.

If a stop recorded a blocking question, answer it in the resume prompt;
resume with an unanswered blocker just presents the question and stops again.

**Interrupted during plan writing or a review round?** Resume re-enters any
phase whose completion entry never made it into the orchestration log, but
how much is redone differs:

- **Plan writing (Phase 1)** is only durable once the finished plan is
  committed. A crash mid-write leaves at most a partial, uncommitted plan
  file — that's the dirty-tree case below: discard it, resume, and the plan
  is rewritten from the spec. Nothing done is lost, because nothing was
  finished.
- **Review loops (Phases 2 and 4)** are durable *round by round*. Every
  completed round is recorded in the loop's own review log before the next
  begins, and Phase 4's fixes are committed as they're applied — so the
  resumed loop picks up at the next round rather than restarting from
  round 1 (even a partially-used fix-verification cycle budget is recovered
  from the log). Only the round in flight is lost; if it died mid-edit,
  its uncommitted changes are again the dirty-tree case — typically you
  discard them and that round simply re-runs.

To tear down a wedged or superseded run instead of resuming it:

```
Abandon orchestration for docs/plans/2026-08-08-my-feature.md
```

(confirms once, then deletes the feature branch — refusing if it's merged or
checked out elsewhere).

### Batched plan execution (SDD batched autonomous mode)

Batches end with a handoff written to `state.md` containing verbatim resume
instructions. After `/clear` (or a crash), paste:

```
Resume the plan at docs/plans/2026-08-08-my-feature.md (batched autonomous mode)
```

Resume reads `state.md`, then **reconciles against the authoritative
record**: plan checkboxes + git history. `state.md` is narrative and may be
one batch stale — that's expected. The reconciliation even heals the classic
crash window: a task interrupted *between* its commit and its checkbox tick
is detected in `git log`, its box is marked, and execution advances rather
than redoing (or half-redoing) done work. A blocking question recorded in
`## Open Issues` stops resume until you answer it — the run never executes
past an unanswered blocker.

One safety rule to know: resume refuses a `state.md` that names a
*different* plan than your prompt does — you're asked to resolve the
mismatch, never silently switched.

### Ordinary sessions

The same file-based durability serves everyday work:

- Ending a session mid-task? Say **`save state`** — `state.md` gets the
  current goal, decisions, and resume instructions for the next session.
- Decisions and rejected approaches accumulate in `session-log.md`, and
  solved errors in `known-issues.md` — both are recalled automatically in
  future sessions (§6).
- A plan being executed non-batched still has its committed checkboxes; a
  fresh session pointed at the plan picks up from the first unchecked task.

### Two caveats that apply everywhere

1. **A dirty tree blocks resume.** If the interruption left uncommitted
   changes (a task died mid-edit), resume stops and reports rather than
   guessing what the half-done work meant. Inspect the diff yourself, then
   commit or discard it before resuming. This is deliberate: recovery never
   silently reconciles your working tree.
2. **`state.md` and `.superpowers/` are git-excluded.** They survive a crash
   on the same machine, but not a fresh clone or `git clean -fdx`. The
   committed artifacts (plan, checkboxes, logs) are the source of truth;
   anything excluded that's lost is reported, never silently reconstructed.

## 6. "How does it remember?" — the memory system

<!-- TODO: The five project-memory files and what each answers:
project-map.md (what exists), session-log.md (what happened & was decided),
known-issues.md (errors already solved — consulted automatically before
debugging), state.md (mid-work snapshot for cross-session handoff),
context-snapshot.json (what changed before this session).
When they're written, where they live, what's safe to delete.
Note: state.md and .superpowers/ are git-excluded — they survive a crash but
not a fresh clone or `git clean -fdx`. -->

📸 _Screenshot: a known-issues recall firing at prompt time._

## 7. Context pressure and the statusline bridge

<!-- TODO: Why context pressure matters (batch boundaries, start gates), the
statusline bridge (install-statusline-bridge.sh, delegate mode preserving an
existing statusline), SUPERPOWERS_PRESSURE_THRESHOLD, and the 1M-window
calibration story (why the bridge exists: without it, pressure math assumed a
200K window). -->

📸 _Screenshot: statusline showing real context occupancy._

## 8. Phrase cheat-sheet

<!-- TODO: One table: phrase → what happens. Seed rows:
- "orchestrate the development of <spec>" → full autonomous pipeline
- "Resume orchestration for <plan>" → resume from last boundary
- "Abandon orchestration for <plan>" → teardown wedged run
- "implement the next N tasks" → SDD batched mode
- "resume the plan" → SDD resume
- "/multi-code-review [BASE] [N]" → N whole-branch review rounds
- "/multi-doc-review <doc> [N]" → N doc review rounds
- "save state" / "compress context" → context-management
- "map this project" → project-map generation
- "save this fix" → error-recovery / known-issues entry
Keep this table in sync at every release (see CLAUDE.md Releases). -->

## 9. Troubleshooting

<!-- TODO: Symptom → cause → fix, seeded from real support cases:
- A skill didn't trigger → is it in hooks/skill-rules.json? Named skills can
  always be invoked explicitly.
- Edited a skill but behavior unchanged → you edited the repo, not the
  installed copy (see §2).
- Unattended run stalled → a permission prompt; why Phase 0 asks you to
  confirm permissions up front.
- Marketplace pointer reverted after update → verify clone HEAD.
Link to platform notes (docs/platforms/) for Codex/OpenCode/Windows limits. -->
