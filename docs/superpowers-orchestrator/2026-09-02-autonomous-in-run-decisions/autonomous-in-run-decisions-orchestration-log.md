# Orchestration Log — autonomous-in-run-decisions

_Invocation 1 — 2026-09-02 — spec docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/specs/autonomous-in-run-decisions-design.md — N_plan=2 N_code=2 M=1 cap=3 — branch feature/autonomous-in-run-decisions — BASE 

## Phase 1 — Plan — DONE — 2026-09-02
plan: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions.md — 9 tasks
note: controller reports the spec's "Deviation 4" secret producer lives in Deviation 3 of the installed code-review-loop template; plan follows the file (recorded in its Assumptions)

## Phase 2 — Plan review — rounds 2 — cap — unresolved 0
note: first controller dispatch killed by the account session limit after writing the invocation line (Case 009 recurrence); identical retry completed the loop

_Invocation 2 — 2026-09-02 — N_code=4 M=4 — resumed_
note: in-run parameter change requested by the user during batch 1 ("from now on N=4 and M=4"); Phase 2 had already completed with N_plan=2 M=1, so the override reaches Phase 4 only. Committed at the batch 1 boundary.

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits ed46125..05fd0cd
- Task 1: complete — test harness and the escalation predicate (ed46125..08b384a)
- Task 2: complete — the classification read exception (9b3b129..9333e99)
- Task 3: complete — fork review for a design item (a50a632..05fd0cd); one fix round on two test pins, re-review clean
note: pre-flight scan raised 3 candidates, each checked against spec and repository and found not to be a plan conflict (recorded in .superpowers/sdd/progress.md); three Minor findings carried in the ledger

## Phase 3 — Batch 2 (tasks 4–6) — COMPLETE — commits 3924678..aefc0ba
- Task 4: complete — the ruling record, the answers and the plan amendment (3924678..a7ff0b5)
- Task 5: complete — the RULING log entry, the cap, idempotence and the guards (0303449..daa5b51)
- Task 6: complete — rulings wired into the phases, log format, state.md, Resume and the stop policy (717755d..aefc0ba)
note: each task clean on its first review round; Minor findings carried in the ledger

## Phase 3 — Batch 3 (tasks 7–9) — COMPLETE — commits 9da1ffe..14b2ba5
- Task 7: complete — multi-code-review attribution and self-sufficient open-item lines (9da1ffe..382319f)
- Task 8: complete — multi-code-review loop-side rule for verification cycles (f053552..fb542cb)
- Task 9: complete — controller prompt templates and the regression gates (10fb328..14b2ba5)
note: all three clean on the first review round; one Minor (duplicated pre-flight wording in the batch-controller template) carried in the ledger

## RULING 1 — 2026-09-04 — phase 4 — both open items decided after independent fork review
Items: [I5] design — amend plan (five-entry read list, guard 4); fix it
       [I2] design — amend plan (irreversible widened by edit location, no-delete bound); fix it
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: 6 (design consistency, implementation practicality, adversarial — three per item) — contradiction: none on [I5]; settled on [I2]
Re-dispatch: phase 4, in-run resume 1 of 3
note: this run executes the INSTALLED 7.7.0 skill, which stops on open items; the predicate, the ruling record and this entry were applied by hand under the user's standing delegation. The installed code-review-loop template journals every resume answer as `decided (user)`, so the label in the review log will read `(user)` although both rulings are the orchestrator's — the attribution fix is part of what this branch builds and is not yet installed.

## RULING 2 — 2026-09-04 — phase 4 — four coverage gaps ruled, one item escalated
Items: [I1] forced — fix it (pin guard 2's two prohibitions)
       [I2] forced — fix it (fold line wraps in the negative checks; folds in carried [M5])
       [I3 v3] forced — fix it (closedness scan must fail on zero bullets)
       [I4] forced — fix it (pin the design-to-fork-review link)
       [I3 r5] escalated (spec wrong) — the branch amends its own spec
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: none — the four are forced answers; the escalated item is not the orchestrator's to decide
Re-dispatch: none — escalated

## STOPPED — 2026-09-04 — phase 4 — one open item is the spec author's decision
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/implementation/autonomous-in-run-decisions-review-log.md
Open: [I3] user-decision — the branch amends its own requirements document (spec R1/R2/R5/R7 markers and the new ## Amendments section) while the rule it ships classes a spec change as `escalated (spec wrong)`
Ruled: [I1] forced — fix it (pin guard 2's two prohibitions)
Ruled: [I2] forced — fix it (fold line wraps in the negative checks)
Ruled: [I3 v3] forced — fix it (closedness scan must fail on zero bullets)
Ruled: [I4] forced — fix it (pin the design-to-fork-review link)
Owed probe: - [I12] rejected: harness probe not runnable here — dispatch one throwaway `subagent_type: "fork"` that terminates without emitting a final message and observe whether the main session receives a failure/error notice or waits with no event — (would break a constraint)
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions.md
