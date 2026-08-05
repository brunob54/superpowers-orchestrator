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

    ## Resume Answer (omit this whole section on a first dispatch)

    [RESUME_ANSWER]

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
       completed ledger line; with no ledger line, the most recent
       `chore(plan): task <n> complete` commit on the branch (find it
       with `git log`); with neither, the branch's merge-base with the
       default branch. Never fall back to your own starting HEAD — on a
       retried controller it already contains the crashed attempt's
       commits, so `git log REVIEW_BASE..HEAD` comes back empty and
       those orphans silently bypass the task-review gate. Then check
       `git log REVIEW_BASE..HEAD` for existing commits touching the
       task. If any exist, dispatch the implementer with an explicit
       partial-work note (verify existing behavior and tests rather than
       expecting a fresh TDD fail step) and build that task's review
       package from REVIEW_BASE — orphan commits are reviewed with the
       completion. Never apply SDD's crash shortcut ("commits present →
       mark complete"): it skips the review gate.
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
- `[RESUME_ANSWER]` — OPTIONAL: omitted, together with its `## Resume
  Answer` heading, on a first dispatch; filled only when re-dispatching
  after a `BLOCKED task=<n>` stop, with the user's answer to that task's
  blocking question. Authoritative — the controller uses it instead of
  re-deriving that answer
- `[SDD_SKILL_PATH]` / `[SDD_SCRIPTS_DIR]` / `[IMPLEMENTER_PROMPT_PATH]` /
  `[TASK_REVIEWER_PROMPT_PATH]` — REQUIRED: absolute paths under
  `../subagent-driven-development/` resolved from this skill's base
  directory

**Nothing else may be added to the prompt.**

**Controller returns:** marker line, then `BATCH_COMPLETE tasks=<i>..<j>`
plus per-task lines, or `BLOCKED task=<n>: <reason>`.
