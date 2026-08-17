---
name: writing-plans
description: >
  MUST USE after design approval to decompose requirements into executable
  task plans with verification commands and TDD ordering. Triggers on:
  "write a plan", "break this down", "plan the implementation", after
  brainstorming approval. Routed by brainstorming as the next step.
---

# Writing Plans

Create an implementation plan another agent can execute with minimal ambiguity.

## Output Path

Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`.
- User preferences for plan location override this default.

## Plan Header

```markdown
# <Feature Name> Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <single sentence>
**Spec:** `docs/specs/<the spec this plan implements>.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews)*
**Architecture:** <2-4 sentences>
**Tech Stack:** <languages/libraries/tools>
**Assumptions:** <list the key assumptions this plan rests on. For each, state what it excludes: "Assumes X — will NOT work if Y."> *(skip only if the plan contains zero conditional logic)*
**Global Constraints:** <rules that bind every task — version floors, dependency limits, naming and copy, exact values — copied verbatim from the spec. subagent-driven-development hands this block verbatim to every reviewer as its attention lens. Omit only if the spec truly has none; a missing block forces the SDD controller to re-derive constraints from the spec on every dispatch.>

---
```

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- Prefer smaller, focused files over large ones that do too much — you reason best about code you can hold in context at once, and your edits are more reliable when files are focused.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure — but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Rules

- Keep tasks independent when possible.
- Keep each step to one action (roughly 2-5 minutes).
- Use exact file paths.
- Include exact verification commands and expected outcomes.
- Use TDD ordering when code behavior changes.
- For ambiguous features, ask clarifying questions before finalizing the plan rather than guessing.

## Task Template

````markdown
### Task N: <Name>

**Files:**
- Create: `<path>`
- Modify: `<path>`
- Test: `<path>`

**Security flag:** `none` *(set to `security` if this task handles auth, credentials, input validation, permissions, crypto, or data access boundaries — triggers pre-implementation security review before the implementer is dispatched)*

**Does NOT cover:** *(required when this task adds a condition, gate, trigger, or any "when X do Y" logic — state the scenarios the condition excludes. If an excluded scenario should be covered, revise this task before implementing.)*

- [ ] **Step 1: Write failing test**

```<lang>
<actual test code>
```

- [ ] **Step 2: Run test to verify it fails**

Run: `<command>`
Expected: FAIL with "<expected failure reason>"

- [ ] **Step 3: Implement minimal change**

```<lang>
<actual implementation code>
```

- [ ] **Step 4: Run test to verify it passes**

Run: `<command>`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add <files>
git commit -m "<type>(<scope>): <what changed>" --trailer "Session: <slug>" --trailer "Stage: task <N>/<total>"
```
````

## Commit Messages

Every commit made while executing a plan must say which workstream and which stage it belongs to — without this, a branch full of task commits is unreadable later.

- **Slug** = the plan's file basename with the `YYYY-MM-DD-` date prefix and the `.md` extension stripped: `docs/plans/2026-08-17-auth-login.md` → `auth-login`. Every skill in the pipeline derives the slug with this same rule.
- Step 5 of each task carries the full commit command: a conventional subject describing the change, plus two trailers (a trailer is a `Key: value` line at the end of the commit message, the same mechanism as `Co-Authored-By`):
  - `Session: <slug>` — the workstream.
  - `Stage: task <N>/<total>` — position in the pipeline.
- Fill in the real slug and task numbers when writing the plan — the No Placeholders rule applies to the commit command too. `git log --grep "^Session: <slug>"` then lists every commit of the workstream.

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Quality Bar

- No vague steps like "update logic".
- No hidden dependencies between distant tasks.
- Call out migrations, feature flags, and rollback checks when relevant.
- Prefer small vertical slices over large horizontal phases.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Scope-reduction scan:** Search the plan for: "v1", "basic", "simple", "for now", "placeholder", "initial version", "minimal". For each hit, verify it was explicitly sanctioned by the user — not a quiet scope downgrade from what was requested. Fix any that weren't.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Multi-Round Plan Review

After self-review, invoke `superpowers-orchestrator:multi-doc-review` on the saved
plan (doc type `plan`; spec path from the plan header's `**Spec:**` line).
It asks for N if not already stated (default 3; 0 skips), runs at most once
per gate, and writes its audit log to `<plan-basename>-review-log.md`. If
the user requests plan changes afterward, re-run only Self-Review — another
loop pass only on explicit user request. Skip on platforms without the
Agent tool.

## Execution Handoff

After saving the plan, completing self-review, and completing the multi-round plan review, auto-select the execution approach using the logic below, seed `state.md`, then output the ready message and **stop**. Do not invoke any execution skill until the user replies.

### Selection Logic (evaluate in order)

1. Current context window ≥ 60% full → **Subagent-Driven** (offload context pressure)
2. Task count ≥ 5 → **Subagent-Driven** (fresh context per task)
3. Tasks have heavy inter-task state sharing (each task depends on runtime state from the previous) → **Inline**
4. Default → **Subagent-Driven**

### Seed `state.md`

Write the plan pointer into `state.md` at the project root — a full rewrite of
the plan-execution sections, in the same shape subagent-driven-development
writes at each batch end:

- `## Current Goal` — the plan's Goal line
- `## Plan` — path to the plan file + "Next task: 1 — <title>"
- `## Decisions & Deviations` — decisions made during planning that live only in
  this conversation. Usually empty: a decision that binds implementation belongs
  in the plan's Global Constraints, not here.
- `## Open Issues` — anything unresolved that execution must not run past

**Replace any earlier plan's sections — never append.** A `state.md` still
pointing at a previous plan makes the next session resume the wrong plan. This
seed is what makes it safe to start execution in a fresh session.

### Ready Message

```
Plan saved to `docs/plans/<filename>.md`. Ready to execute with **[Subagent-Driven / Inline Execution]** (<N> tasks[, <one-word reason>]).

Recommended: start execution in a fresh session (`/clear` in Claude Code) — this session's planning context is no longer needed for execution and only spends the first batch's context budget before Task 1 begins. The plan file and `state.md` carry everything execution needs. Then paste:

    <paste prompt from the table below>

Or reply here to execute in this session, or say "inline" / "subagent" to switch.
```

Fill the paste prompt from the selected approach. When Subagent-Driven is
selected, offer both variants (batched first) — the selection logic does not
distinguish them:

| Approach | Paste prompt | Behavior |
|---|---|---|
| Subagent-Driven, batched | `Use subagents in batched autonomous mode on docs/plans/<filename>.md` | Never asks mid-batch; hands off at the context boundary |
| Subagent-Driven, interactive | `Use subagents to implement docs/plans/<filename>.md` | Per-task subagents; stops to ask on ambiguity or blockers |
| Inline | `Execute the plan at docs/plans/<filename>.md` | Continuous in-session execution with checkpoints |

**Use these prompts verbatim — they are tuned to the skill-activator's
scoring, not just readable.** Two failure modes they avoid: a prompt matching
only one keyword scores 1 and is dropped below the confidence threshold, so the
fresh session routes to no skill at all; and a Subagent-Driven prompt that loses
its "subagents" or "in batches" wording falls through to executing-plans
(priority `high` against subagent-driven-development's `medium`) and silently
lands in inline execution.

**Stop here.** Do not invoke any execution skill until the user replies.

### On User Reply

**If Subagent-Driven:**
- **REQUIRED SUB-SKILL:** Use superpowers-orchestrator:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution:**
- **REQUIRED SUB-SKILL:** Use superpowers-orchestrator:executing-plans
- Continuous execution with checkpoints for review
