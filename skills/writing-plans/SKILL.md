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

Derive the **topic folder** from the spec path (the derivation rule and the
folder shape are defined in the "Artifact Layout" section of
`skills/brainstorming/SKILL.md`): the spec must be
`<D>/specs/<file>` where `<D>` is a direct child of
`docs/superpowers-orchestrator/` at the repository root and `<D>`'s basename
matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`. Then `<D>` is
the topic folder, its basename is `<date>-<slug>`, and `<slug>` is that
basename minus the date prefix.

Save to `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`,
creating `plans/` if it does not exist.

- User preferences for plan location override this default.
- A spec that is **outside the layout** is handled by "Spec Outside the
  Layout" below — do not write a plan next to it.

## Spec Outside the Layout

A spec whose path is not `<D>/specs/<file>` — where `<D>` is a direct child
of `docs/superpowers-orchestrator/` at the repository root whose basename
matches the topic-folder shape defined in the "Artifact Layout" section of
`skills/brainstorming/SKILL.md` — gets **no plan written beside it**. The
`specs/` segment is required: the general derivation rule in that section
also accepts `<D>/plans/<file>`, but a *spec* sitting in a `plans/` folder is
outside the layout and gets the offer below, exactly as this task's "Does NOT
cover" note states. The invariant this protects: every plan lives in a topic folder
together with its spec.

1. Compute `<slug>` = the spec basename with `YYYY-MM-DD-`, `-design` and
   `.md` stripped, each only if present, then normalized by the "Slug" rule
   in the "Artifact Layout" section of `skills/brainstorming/SKILL.md` (the
   same normalization brainstorming applies to a topic name). Without it, a
   basename such as `MyFeature-design.md` yields a folder name that fails
   the layout check, and the offer below repeats on every run.
2. Name the expected location:
   `docs/superpowers-orchestrator/<today>-<slug>/specs/<slug>-design.md`. If a
   folder matching `docs/superpowers-orchestrator/????-??-??-<slug>/` already
   exists, reuse that folder instead of `<today>` (slug uniqueness). More than
   one match → stop and report the ambiguity; write nothing. If the reused
   folder already holds `specs/<slug>-design.md` or its
   `specs/<slug>-design-review-log.md` sidecar, stop and report the
   collision — a different spec already owns that slug — and move and write
   nothing.
3. State the reason the spec is outside the layout — wrong parent directory,
   or a folder name that does not match
   `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$` — next to the
   expected location, so a spec already in the right place but wrongly named
   is never described as a move onto itself.
4. Ask the user **once** whether to move the spec there.
   - **Yes:** `mkdir -p` the destination `specs/` folder first (`git mv` fails
     when the destination directory does not exist), then `git mv` the spec to
     `specs/<slug>-design.md` and — when it exists — its `-review-log.md`
     sidecar to `specs/<slug>-design-review-log.md`. A file git does not track
     yet (`git ls-files --error-unmatch <path>` fails — the normal state of a
     spec that was written and never committed) cannot be moved with `git mv`:
     move it with plain `mv` and `git add` the destination path instead. Use
     plain `mv` when the project is not a git repository. The sidecar is
     renamed together with the spec because the sidecar rule derives the log
     name from the document name: a sidecar that kept its old basename would be
     orphaned and a later spec review would start a new log. Then continue with
     the moved spec.
   - **No:** stop. No plan is written.

## Plan Header

```markdown
# <Feature Name> Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Fenced code blocks and block-quoted wording in task steps are reference implementations for the task's stated `**Contract:**`. A review finding against such a body is an ordinary fix while the contract holds; only blocks marked `**Exact content:**` bind byte-for-byte. The `**Global Constraints:**` block binds as stated.

**Goal:** <single sentence>
**Spec:** `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/specs/<slug>-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
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

## Contracts and Literal Bodies

A **contract** is the set of properties an artifact must guarantee, stated
so that a check can falsify them. A **reference implementation** is a
concrete body (a code block or quoted text) that satisfies the contract:
it shows one way, it does not bind.

1. **State a contract for every governed artifact.** For every helper,
   function, command, or piece of wording a task introduces or modifies,
   state the contract in the task's `**Contract:**` field: the invariants
   that must hold and the verification (a runnable command or check) that
   would falsify them; for code artifacts also inputs and outputs. A task
   that creates or modifies several artifacts holds one entry per artifact
   in the same field (a list) — or is a candidate for splitting.
   Procedural step blocks that operate the pipeline rather than build the
   feature — the Step 5 commit command, `Run:` verification lines — need
   no contract entry; rule 3's default covers them. The boundary is a
   test, not a feeling: a block is procedural exactly when it creates or
   modifies no file named in the task's `**Files:**` list. Two contract
   shapes exist — code artifact and wording artifact — shown in the
   examples below.

2. **Pin an interface only when something outside the plan depends on
   it.** An interface (signature, flag set, file format) is pinned in the
   contract only when something *outside the plan* already depends on it.
   Stating inputs and outputs in the `**Contract:**` field does not pin
   them: a concrete signature written there is descriptive — part of the
   reference implementation — unless the external-dependency condition
   holds, and a fix may amend the signature together with the contract's
   inputs/outputs wording as one ordinary fix.

3. **Bodies are reference implementations by default.** Code blocks and
   quoted wording in task steps are reference implementations. The
   implementer follows them as written; a later review finding against
   such a body is an **ordinary fix** so long as the stated contract still
   holds. Only a change that breaks or amends the contract itself is a
   plan conflict.

4. **Mark exact content explicitly.** A block is binding byte-for-byte
   only when the line immediately above the fenced block or block quote it
   pins reads `**Exact content:** <reason>`. The reason must name the
   *external* pin: a pre-existing test asserting the string, another file
   that must already match byte-for-byte, or user-approved copy — and a
   user-approval reason must cite where the approval is recorded (a spec
   section, a review-log disposition, or a plan amendment quote); an
   uncited approval claim is not a valid reason. A marker with no reason
   is a plan failure of the same class as the "No Placeholders" patterns.
   Never place the marker inline on the same line as the content it pins.

5. **A self-pin never justifies the marker.** A pin the plan itself
   introduces (the plan also writes the test that asserts the string, or
   also writes the matching file) does not justify `**Exact content:**`:
   body and pin are amendable **together as one ordinary fix** — the fix
   changes the text and its pinning test in the same commit. The same
   applies to a *pre-existing* pin whose assertion the same plan edits: a
   pin the plan controls is a self-pin, whatever its age. Only a pin the
   plan leaves untouched binds. Circular reasons — a reason citing an
   artifact the same plan creates or modifies — are a plan failure.

6. **Boundaries.**
   (a) This section defines the *authority* of bodies; it does not license
   vague steps — the "No Placeholders" rules still require actual code.
   (b) The default never applies to the plan header's
   `**Global Constraints:**` block, which binds as stated; a conflict with
   a global constraint is genuine and stops the run.
   (c) Other non-task plan content (header prose such as
   `**Architecture:**` and `**Assumptions:**`, the File Structure section)
   follows the same reference default: findings against it are ordinary
   fixes unless they contradict a stated contract or a global constraint.
   (d) A finding against a body in a task whose field reads
   `**Contract:** none — <reason>` is an ordinary fix under rule 3's
   default — there is no contract to break.
   (e) The implementer follows the reference body; the contract governs
   later findings.

**Example — code artifact contract:**

> **Contract:** `assert_round_reviewers <log> <round> <m> <required|optional>`
> - Inputs: review-log path, round number, expected reviewer count M, an
>   expectation mode supplied by the caller.
> - Output: exit 0 only when the round entry demonstrates M reviewers per
>   lens and every consolidated finding maps to reviewer sources.
> - Invariants: mode `required` makes a `Sources mapped: 0/0` entry fail;
>   mode `optional` keeps the documented skip; a missing or misspelled
>   mode fails.
> - Verification: synthetic-fixture checks covering both modes × both
>   outcomes, bad mode, missing round entry.
> - Interface not externally pinned — the signature above is descriptive
>   and may change in a fix (rule 2).

**Example — wording artifact contract:**

> **Contract:** model-probe example in `reviewer-prompt.md`
> - Must convey: a reviewer asserting a harness property runs a probe; the
>   probe prompt must not name the canary token.
> - Invariant: no example places the token inside the probe prompt text.
> - Verification: `bash tests/reviewer-templates/run-tests.sh` asserts the
>   section exists and the example probe omits the token.
> - Sentence wording is free; the properties above bind.

## Task Template

````markdown
### Task N: <Name>

**Files:**
- Create: `<path>`
- Modify: `<path>`
- Test: `<path>`

**Security flag:** `none` *(set to `security` if this task handles auth, credentials, input validation, permissions, crypto, or data access boundaries — triggers pre-implementation security review before the implementer is dispatched)*

**Does NOT cover:** *(required when this task adds a condition, gate, trigger, or any "when X do Y" logic — state the scenarios the condition excludes. If an excluded scenario should be covered, revise this task before implementing.)*

**Contract:** *(one entry per artifact this task creates or modifies: the invariants that must hold and the verification that would falsify them; inputs and outputs for code artifacts. See "Contracts and Literal Bodies" for the two shapes — code artifact and wording artifact. Write `none — <reason>` when the task creates or modifies nothing a later review finding could be judged against.)*

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

- **Slug** = the plan's file basename with the `YYYY-MM-DD-` date prefix and the `.md` extension stripped, each only if present. Every skill in the pipeline derives the slug with this same rule. Under the artifact layout the plan basename *is* the slug, so the rule yields it unchanged: `docs/superpowers-orchestrator/2026-08-17-auth-login/plans/auth-login.md` → `auth-login`.
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

These patterns are about *content completeness*; the "Contracts and
Literal Bodies" section defines the *authority* of that content. A body
must still be actual code or actual wording even when it binds only as a
reference implementation.

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
Plan saved to `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`. Ready to execute with **[Subagent-Driven / Inline Execution]** (<N> tasks[, <one-word reason>]).

Recommended: start execution in a fresh session (`/clear` in Claude Code) — this session's planning context is no longer needed for execution and only spends the first batch's context budget before Task 1 begins. The plan file and `state.md` carry everything execution needs. Then paste:

    <paste prompt from the table below>

Or reply here to execute in this session, or say "inline" / "subagent" to switch.
```

Fill the paste prompt from the selected approach. When Subagent-Driven is
selected, offer both variants (batched first) — the selection logic does not
distinguish them:

| Approach | Paste prompt | Behavior |
|---|---|---|
| Subagent-Driven, batched | `Use subagents in batched autonomous mode on docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` | Never asks mid-batch; hands off at the context boundary |
| Subagent-Driven, interactive | `Use subagents to implement docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` | Per-task subagents; stops to ask on ambiguity or blockers |
| Inline | `Execute the plan at docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` | Continuous in-session execution with checkpoints |

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
