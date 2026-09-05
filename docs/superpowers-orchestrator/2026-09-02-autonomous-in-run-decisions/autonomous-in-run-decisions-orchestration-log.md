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

## RULING 8 — 2026-09-04 — phase 4 — author's answer applied, ruling 2 withdrawn
Items: [I3 r5] (user) — Ruling 1 confirmed; Ruling 2 withdrawn in full; the spec joins the plan's File Structure table
       [I1] [I2] [I3 v3] [I4] forced — fix it, carried from RULING 2's Ruled: lines
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: none — the author decided the escalated item; the rest are forced
Re-dispatch: phase 4, in-run resume 2 of 3

## RULING 9 — 2026-09-04 — phase 4 — two forced, two escalated by guard 4
Items: [I1 v3] forced — fix it (pin each fork rule with an assertion that fails when it is deleted)
       [I7] forced — fix it, applied directly (amendment markers removed from reference text)
       [I8] escalated (spec wrong) — the secret class cannot match a Phase 3 item
       [I3 r11] escalated (spec wrong) — nothing delivers the secret residue
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: none — two forced answers; the two escalations are barred from a ruling by guard 4, which the author's 2026-09-04 decision triggers
Re-dispatch: none — escalated

## STOPPED — 2026-09-04 — phase 4 — two secret-class gaps are the spec author's decision
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/implementation/autonomous-in-run-decisions-review-log.md
Open: [I8] user-decision — the `secret` class cannot match a Phase 3 open item, so a credential raised as a Phase 3 question is decided autonomously
Open: [I3] user-decision — nothing delivers the secret residue: a credential scrubbed at HEAD survives in history with nobody told to rotate it
Ruled: [I1 v3] forced — fix it (pin each fork rule against deletion)
Ruled: [I7] forced — applied directly, markers removed from reference text
Owed probe: none
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions.md

## RULING 13 — 2026-09-04 — phase 4 — author's answer applied; secret residue closed, Phase 3 gap recorded
Items: [I3 r11] (user) — fix it: Secrets found: line on the loop's report and the Phase 5 report (spec R13)
       [I8] (user) — recorded as a known limitation in the spec; no code change
       [I1 v3] forced — fix it, carried from RULING 9's Ruled: lines
       [I7] forced — already applied in cb9824f
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: none — the author decided the escalated items
Re-dispatch: phase 4, in-run resume 3 of 3
note: the author also chose the branch outcome — merge to main once these fixes land and pass review.

## RULING 16 — 2026-09-05 — phase 4 — four ruled, one escalated
Items: [I3 r14] forced — fix it (the cap's anchor ignores a `— resumed_` invocation line)
       [I2 v3] forced — fix it (pin the rest of the Secrets found: sentence)
       [I3 v3] forced — fix it (add the sixth negative assertion, for the Phase 3 removal)
       [I1 v3] design — fix it (fold-by-default in the fragment branch; inversion assertions over the named safety properties)
       [I7] escalated (spec wrong) — a stated `**Contract:**` is not in the binding set
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: 4 (design consistency, adversarial for [I7]; implementation practicality, adversarial for [I1 v3]) — contradiction: none; each pair tabled the same fourth option from opposite directions
Re-dispatch: none — escalated

## STOPPED — 2026-09-05 — phase 4 — the binding-set definition is the spec author's decision
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/implementation/autonomous-in-run-decisions-review-log.md
Open: [I7] user-decision — a stated `**Contract:**` is outside the binding set, so contract-governed behaviour can change under a bare `fix it`; on this plan that includes the invariant forbidding the rejection of a Critical
Ruled: [I3 r14] forced — fix it (cap anchor ignores a resumed invocation line)
Ruled: [I2 v3] forced — fix it (pin the rest of the Secrets found: sentence)
Ruled: [I3 v3] forced — fix it (sixth negative assertion for the Phase 3 removal)
Ruled: [I1 v3] design — fix it (fold-by-default plus inversion assertions)
Owed probe: - [I7] dispatch two agents in one session with the identical name value and observe whether the second dispatch is rejected, silently renamed, or accepted as a duplicate — (would break a constraint) (round 14)
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions.md

## RULING 21 — 2026-09-05 — phase 4 — author's answer applied; binding test defers to the plan's note
Items: [I7] (user) — fix it: read the plan's Body-authority note, drop the enumerated copy, bound the decided-wording rule (spec R14)
       [I3 r14] [I2 v3] [I3 v3] [I1 v3] — fix it, carried from RULING 16's Ruled: lines
Detail: docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions-open-decisions.md
Forks: none — the author decided the escalated item
Re-dispatch: phase 4, in-run resume 1 of 3 (counted after the latest STOPPED entry)
