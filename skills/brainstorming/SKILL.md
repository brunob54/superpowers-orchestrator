---
name: brainstorming
description: >
  MUST USE when the user wants new features, behavior changes, refactoring
  with new capabilities, or architecture decisions and no approved design
  exists yet. Produces an approved design document before any code is written.
  Triggers on: "build this", "add a feature", "I want to change", "how should we",
  "design", "architect", "new project", "refactor", "we need to add/build/create",
  "implement a new". Routed by using-superpowers, or invoke directly via /brainstorming.
---

# Brainstorming

Turn rough requests into an approved design before implementation.

## Hard Gate

Do not write code, edit files, or invoke implementation skills until design approval is explicit.

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

1. Inspect project context (relevant files, docs, recent commits).
2. Assess scope: if the project touches 4+ independent subsystems or would require 20+ implementation tasks, decompose into sub-projects. Design each sub-project as a separate spec. Present the decomposition to the user for approval before designing individual specs.
3. Ask all clarifying questions together in a single turn. Use multiple-choice format where possible to reduce round trips.
4. Propose 2-3 approaches with trade-offs and a recommendation.
5. Present design in short sections; confirm each section.
6. For existing codebases: study existing patterns before proposing new ones. Match the project's conventions unless there's a compelling reason to diverge. Design for isolation — prefer changes that minimize blast radius and don't require coordinating across many files.
7. If the repo lacks `CLAUDE.md` / `AGENTS.md` and long-term collaboration is expected, consider using `claude-md-creator` to create a minimal, high-signal context file.
8. **Before approving the design — failure-mode check:** State the top 2-3 ways the chosen approach could fail or not cover all cases. This is adversarial reasoning, not a list of known assumptions — actively try to break the design. For each failure mode found, assess severity:
   - **Critical** (design fails for a significant user scenario): revise the design before proceeding.
   - **Minor** (edge case, acceptable limitation): document as a non-goal in the design.
   Do not skip this step. An approach that survives adversarial questioning is an approach worth approving.
9. Save approved design to `docs/specs/YYYY-MM-DD-<topic>-design.md`.
10. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see Spec Self-Review below). Fix issues inline; no subagent dispatch needed.
11. **Multi-round spec review** — invoke `superpowers-orchestrator:multi-doc-review` on the saved spec (doc type `spec`). It asks for N if not already stated (default 3; 0 skips), runs at most once per gate, and writes its audit log to `<spec-basename>-review-log.md`. Skip on platforms without the Agent tool.
12. **User reviews written spec** — present the User Review Gate message (below) verbatim, with `<path>` filled in. This is the skill's final message; do not paraphrase it or drop either option.
13. If the user approves in-session: invoke `writing-plans`. If the user chooses orchestration: stop — they run it from a fresh session.

## Process Flow

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Assess scope" [shape=diamond];
    "Decompose into sub-projects" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Failure-mode check" [shape=box];
    "Save design doc" [shape=box];
    "Spec self-review\n(fix inline)" [shape=box];
    "Multi-doc-review loop" [shape=box];
    "User reviews spec?" [shape=diamond];
    "Invoke writing-plans" [shape=doublecircle];

    "Explore project context" -> "Assess scope";
    "Assess scope" -> "Decompose into sub-projects" [label="4+ subsystems"];
    "Assess scope" -> "Ask clarifying questions" [label="manageable"];
    "Decompose into sub-projects" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Failure-mode check" [label="yes"];
    "Failure-mode check" -> "Save design doc";
    "Save design doc" -> "Spec self-review\n(fix inline)";
    "Spec self-review\n(fix inline)" -> "Multi-doc-review loop";
    "Multi-doc-review loop" -> "User reviews spec?";
    "Hand off to orchestration\n(user runs it in a fresh session)" [shape=doublecircle];

    "User reviews spec?" -> "Save design doc" [label="changes requested"];
    "User reviews spec?" -> "Invoke writing-plans" [label="approved in-session"];
    "User reviews spec?" -> "Hand off to orchestration\n(user runs it in a fresh session)" [label="user chooses orchestration"];
}
```

**The terminal state is invoking writing-plans, or handing off to orchestration.** Do NOT invoke frontend-design, or any other implementation skill. The ONLY skill brainstorming itself invokes afterwards is writing-plans; orchestrating-development is never invoked from this session — the user starts it in a fresh session via the gate message.

## Spec Self-Review

After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix any issues inline. No need to re-review — just fix and move on.

## User Review Gate

After the multi-doc-review loop completes (or is skipped), present this message **verbatim** with `<path>` replaced by the actual spec path. It must be the last message before the user answers — even when review rounds ran in between, repeat it in full; do not paraphrase it and do not drop option 2:

> Spec written and saved to `<path>`. The review rounds are complete. Choose how to continue:
>
> 1. **Review it here** — request changes, or approve to continue to `writing-plans` in this session.
> 2. **Autonomous pipeline** — run `/clear` (the spec and its review log stay on disk), then paste:
>
>        orchestrate the development of <path>
>
>    orchestrating-development runs plan writing, plan reviews, batched implementation, and code reviews unattended, and stops before any merge or PR. A fresh session is recommended because the pipeline then starts with the full context window.

Wait for the user's response. If they request changes, make them and re-run the self-review. Only proceed once the user approves.

If the user requests changes after the multi-doc-review loop already ran at this
gate, re-run only the Spec Self-Review on the edited spec — the loop runs at
most once per gate (detection: the spec's `-review-log.md` already holds an
invocation entry from this gate). Run the loop again only if the user
explicitly asks.

## Design for Isolation and Clarity

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently.
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Smaller, well-bounded units are easier to reason about — you reason better about code you can hold in context at once, and your edits are more reliable when files are focused.

## Design Contents

Include:
- Scope and non-goals
- Architecture and data flow
- Interfaces/contracts
- Error handling
- Testing strategy
- Rollout or migration notes (if needed)

## Engineering Rigor

Apply senior engineering judgment during design:
- Verify requirements are complete and unambiguous before designing.
- Identify edge cases, error paths, and cross-platform concerns early.
- Evaluate trade-offs explicitly (performance vs. readability, flexibility vs. simplicity).
- Prioritize modularity, SOLID principles, and production-ready standards.
- Flag architectural risks that will be expensive to fix later.

## Interaction Rules

- Batch all questions into a single turn; use multiple choice to reduce ambiguity.
- Remove non-essential scope (YAGNI).
- If user feedback conflicts with prior assumptions, revise design before proceeding.

## Exit Criteria

- User approved the design.
- Failure-mode check completed — critical failure modes resolved, minor ones documented as non-goals.
- Design document exists at the required path (`docs/specs/`).
- Spec self-review completed — placeholders, contradictions, ambiguity, and scope issues resolved.
- Multi-doc-review loop completed or explicitly skipped (N=0) — every Critical/Important finding applied or rejected-with-reason in the review log.
- User reviewed the written spec and approved.
- `writing-plans` is invoked as the next skill.
