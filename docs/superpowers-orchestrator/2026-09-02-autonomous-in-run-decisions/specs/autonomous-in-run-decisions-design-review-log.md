# Review log — autonomous-in-run-decisions-design.md

_Invocation 1 — 2026-09-02 — N=2 M=1 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewer verdict:** 1 Critical, 10 Important, 6 Minor
**Converged:** no

### Dispositions
- [C1] applied — R5 Plan amendment: a block quote under the task heading leaves the binding clause in force, so the next review raises the same finding → the amendment now edits the binding clause in place (marker `(amended by ruling <n>)`) and adds the audit block quote after the block holding the clause; insertion points named for Global Constraints and task-level clauses
- [I1] applied — R6 cap: no reset point after a stop (a plain resume writes no `_Invocation` line) → count starts after the later of the latest `_Invocation` line and the latest `## STOPPED` entry
- [I2] applied — R6 cap penalises long Phase 3 runs → Phase 3 counts per task, Phase 4 per phase
- [I3] applied — Error handling contradicted R3 on fewer than two usable fork returns → one exit: fatal environment failure, reason `fork review unavailable`
- [I4] applied — R5/R6 named two commits for the amendment → one commit `chore(orchestration): <slug> ruling <n>` holds log entry, open-decisions entries and amendment
- [I5] applied — an amendment commit moves the effective HEAD, so Phase 4 starts a new invocation instead of one fix + re-review → stated as intended in R5, counted as one in-run resume, bounded by N_code
- [I6] applied — pre-flight conflicts have no task report and may be several → in scope; `BLOCKED task=<n>` with the lowest task touched, detail in `.superpowers/sdd/task-<n>-report.md` as `### Conflict <k>` sections (R10); items named `[task <n>/<k>]`
- [I7] applied — the `user-decision` line carries no file:line or plan clause, and reviewer reports are off-limits → R8.2: open-item disposition lines carry `— at <file:line> — clause: <plan location> "<text>"`; R2 reads that line only
- [I8] applied — the loop's verification-cycle fix branch overrode binding text with weaker guards than the orchestrator's → R8.3 narrowed: the loop rejects only findings against already-decided wording, quoting the decision line; binding text not yet decided stays `user-decision`; the loop never edits plan text
- [I9] applied — fork dispatch is background for the main session; "lost" undefined → forks named `fork-<lens>`, the orchestrator waits for completion notices (no #75043 stall for the main session), "lost" defined; a notice that never arrives is a fatal environment failure — harness probe: reviewer read the Agent tool description; observed "A fork runs in the background … you'll be notified when one completes"
- [I10] applied — the `**Follow-up:**` line was never committed → committed at Resume step 3 as `chore(orchestration): <slug> ruling <n> follow-up`
- [M1] applied — `spec wrong` definition did not cover a disputed Critical → definition widened
- [M2] applied — R11 pin would not match the bold R6 sentence → R6 writes the sentence in the pinned form
- [M3] applied — no Phase 3 answer line form → `[task <n>] (orchestrator): <answer>` and `[task <n>/<k>]`
- [M4] applied — forks told to run verification commands and to write nothing → forks run only read-only git commands; forced answers are established by reading
- [M5] applied — malformed-answer check had no outcome → outcomes named in R7.1/R7.2 and Error handling
- [M6] applied — "non-fatal external problem" rule had no trigger in the flow → removed from the predicate; the existing identical-dispatch retry covers it

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 10 Important, 9 Minor
**Converged:** no

### Dispositions
- [I1] applied — R5: bare `fix it` on a binding-clause item undefined → valid only when `clause:` is `none` or reference text; `amend plan …; fix it` is the only accepting answer for binding text
- [I2] applied — R3 fork prompt asked for verbatim finding text the R2 list cannot supply → the disposition line verbatim (and the report section for Phase 3)
- [I3] applied — unsettled contradiction had no tie-break → debate round under `evidence consistency`; then the outcome that leaves binding text unchanged, else the smallest amendment; `contradiction: unsettled` recorded
- [I4] applied — predicate not re-applied after fork return → applied twice; a fork VERDICT matching an escalation entry escalates; a TABLED one does not
- [I5] applied — Phase 3 `BLOCKED task=<n>` did not separate open items from failures → report-file discriminator: a `### Conflict`/`### Question` section makes it an open item, none makes it a controller failure
- [I6] applied — "loop decision" undefined; amended clauses across invocations unstated → decided wording enumerated (decided lines, plan-governs lines of the same run, `(amended by ruling <n>)` clauses); `fixed`/ordinary `rejected` are not decisions
- [I7] applied — `secret` cited a multi-code-review rule that does not exist → cites code-review-loop-prompt.md Deviation 4 (the only producer) and defines the match on the disposition text
- [I8] applied — `chain` absent from R1's list, pin would not match → `chain` added to R1 as the fifth reason; pins `escalated (chain)` too
- [I9] applied — fork count and lens choice undefined → default triple named, the two-fork case defined by the finding's file, fork-tabled outcomes do not change the count; `evidence consistency` is the debate lens
- [I10] applied — "lost" vs "hang" under the guard → guard behaviour read from hooks/subagent-guard.js: `decision: block` + redo, the notice still arrives; "lost" = notice without marker or a failure; fork prompt reworded. Reviewer's probe (dispatch an unmarked subagent) not run: the behaviour is readable in the hook source, harness field dropped (repository-readable)
- [M1] applied — pinned cap sentence contradicted the per-task unit → one sentence true for both phases
- [M2] applied — cap count not filtered by phase → same phase, and same task in Phase 3
- [M3] applied — R4 template had no Phase 3 form → `n/a` fields stated
- [M4] applied — `<k>` only defined for pre-flight → `### Question <k>` / `### Conflict <k>` in every BLOCKED report (R10)
- [M5] applied — read bound ambiguous → whichever is smaller
- [M6] applied — `scope` undefined → union of the plan's `**Files:**` lists, else files changed BASE..HEAD
- [M7] applied — open-item line grammar → two full example lines; `(plan-mandated)` position; quoted text ≤160 chars, ` ← ` and ` — ` forbidden inside it
- [M8] applied — redundant pin → one kept
- [M9] applied — fork properties uncited → the Agent tool's own description cited

_Loop end: cap reached (N=2), rounds 1-2 not clean; self-review after the loop: two stale cross-references (R8.1 → R8.2) and the Scope bullet for multi-code-review fixed inline. Harness probes owed: none_
