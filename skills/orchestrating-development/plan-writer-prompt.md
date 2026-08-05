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
