# Review log — autonomous-in-run-decisions

_Invocation 1 — 2026-09-02 — N=4 M=4 — BASE..HEAD 0a57e40..e903e73 — branch feature/autonomous-in-run-decisions — gate: orchestration_

carried findings: 11 Minor lines read from .superpowers/sdd/progress.md

## Round 1 — Correctness & spec alignment — fable
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 5 Minor | r2: 0 Critical, 3 Important, 6 Minor | r3: 0 Critical, 2 Important, 6 Minor | r4: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 30/30
**Reviewer verdict:** 0 Critical, 4 Important, 14 Minor
**Converged:** no
### Dispositions
- [I1] fixed — settled rule keyed on `[task <n>/<k>]` only, while a single-section item is named `[task <n>]`; a `[task <n>]` line now reads as `[task <n>/1]` and the settled rule covers both shapes and Question sections (SKILL.md ~549-553/~865-867, batch-controller-prompt.md ~64-68) → 866c888 ← 4/4: r1:I2, r2:I2, r3:I2, r4:I1
- [I2] fixed — Phase 3 discriminator counted any Conflict/Question section with no freshness test, so a stale answered section misclassified a controller failure as an open-item return; only sections unanswered in the dispatched `[RESUME_ANSWER]` count now (SKILL.md ~617-624, batch-controller-prompt.md Deviation 1) → 866c888 ← 3/4: r1:I3, r2:I1, r3:I1
- [I3] fixed — a second open return on one task lost the first ruling and `<k>` renumbering could apply a stale answer to a new section; every re-dispatch carries all ruled lines of the unit and `<k>` continues across attempts (SKILL.md ~849-867/~928-930, batch-controller-prompt.md ~78-82) → 866c888 ← 2/4: r1:I1, r4:M1
- [I4] fixed — a pre-flight conflict ruled for a later-batch task never reached that batch, whose first dispatch omitted `## Resume Answer`; each batch's `[RESUME_ANSWER]` now carries every recorded answer whose task is in its list (SKILL.md ~271-278/~553, batch-controller-prompt.md ~70) → 866c888 ← 1/4: r2:I3
- [M1] fixed — "new invocation started by an `amend plan` ruling counts as one in-run resume" read as double counting against the cap (SKILL.md ~904/~954-956) → 866c888 ← 4/4: r1:M4, r2:M5, r3:M5, r4:M4
- [M2] fixed — `## RULING` `Items:` line had no form for an escalated item; `[<id>] escalated (<reason>) — <summary>` defined in both copies of the block (SKILL.md ~363/~914-915) → 866c888 ← 2/4: r2:M2, r3:M4
- [M3] fixed — Resume step 3 `**Follow-up:**` append not idempotent and follow-up commit `<n>` undefined for several rulings (SKILL.md ~474-488) → 866c888 ← 2/4: r2:M6, r3:M6
- [M4] fixed — Phase 3 step 5 did not say whether a `BLOCKED` return writes a batch entry, which could break the Resume "log ends with `## RULING`" signal (SKILL.md ~269-278) → 866c888 ← 2/4: r3:M2, r4:M2
- [M5] carried — Resume step 3 `**Follow-up:**` append is unconditional but Phase 1 answers and pre-change `## STOPPED` entries have no ruling-record entry (SKILL.md ~474-478) ← 1/4: r1:M1
- [M6] carried — `Ruled:` lines are built into `[RESUME_ANSWER]` only under "When the resume prompt does answer"; the effective-HEAD-moved re-dispatch path does not say they are sent (SKILL.md ~468-471 vs ~491-495) ← 1/4: r1:M2
- [M7] carried — `## RULING` `Re-dispatch:` line does not record the batch (task list, `First batch:` value) a Phase 3 re-dispatch used, which a crash resume must reconstruct (SKILL.md ~366/~917/~451-455) ← 1/4: r1:M3
- [M8] carried — code-review-loop-prompt.md Deviation 3 secret EXCEPTION says only "record it as `unresolved`", without the `— at <file:line> — clause:` shape the self-sufficient line rule requires (multi-code-review SKILL.md ~884-893) ← 1/4: r1:M5
- [M9] carried — unclear whether a `## RULING` entry is written when every item of a return is escalated (SKILL.md ~934) ← 1/4: r2:M1
- [M10] carried — two routes for an impossible reference-text task step: `amend plan:` answer vs plain-text answer "valid against reference text" (SKILL.md ~853/~869) ← 1/4: r2:M3
- [M11] carried — self-sufficient line rule allows `clause: none` only for an `unresolved` item, but a carried item logged `user-decision` from reviewer recommendations also collides with nothing (multi-code-review SKILL.md ~884) ← 1/4: r2:M4
- [M12] carried — `fork review unavailable` stops mid-return before the already-decided `forced` items of the same return are recorded (SKILL.md ~784-789) ← 1/4: r3:M1
- [M13] carried — "The run stops only for the closed list of reasons in the predicate" contradicts the section's own environment stops (SKILL.md ~563-564) ← 1/4: r3:M3
- [M14] carried — `## STOPPED` `Detail:` for a Phase 3 stop names `.superpowers/sdd/task-<n>-report.md`, excluded state that does not survive a clone boundary (SKILL.md ~384-385) ← 1/4: r4:M3
- carried item 1 (run-tests.sh helpers/path vars unused until Tasks 2-6) — carried (4× ship-as-is: all used by the final suite)
- carried item 2 (run-tests.sh section 2 two extra fragment checks) — carried (4× ship-as-is)
- carried item 3 (run-tests.sh FORK_END scans to EOF) — carried (4× ship-as-is)
- carried item 4 (`clause:` label wording inherited from multi-code-review) — carried (4× ship-as-is)
- carried item 5 (RULING template `Items:` annotation inline after spaces) — fixed — annotation moved out of the fence, with [M2] → 866c888 (3× fix-before-merge, 1× ship-as-is)
- carried item 6 (Phase 3 step 5 lacks the escalated carve-out) — fixed — carve-out added → 866c888 (4× fix-before-merge)
- carried item 7 (Resume step 3 states the `**Follow-up:**` append twice) — fixed — first mention dropped, with [M3] → 866c888 (1× fix-before-merge, 3× ship-as-is)
- carried item 8 (run-tests.sh pre-flight negative check lacks the empty-range guard) — fixed — guard added → 866c888 (3× fix-before-merge, 1× ship-as-is)
- carried item 9 (`## RULING` block defined twice) — carried (4× ship-as-is)
- carried item 10 (`## STOPPED` `Owed probe:` sentence vacuous for a Phase 3 stop) — carried (4× ship-as-is)
- carried item 11 (batch-controller-prompt.md pre-flight rule stated twice) — carried (4× ship-as-is)

