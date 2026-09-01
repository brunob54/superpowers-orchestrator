# Orchestration Log — plan-contracts-not-bodies

_Invocation 1 — 2026-08-31 — spec docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/specs/plan-contracts-not-bodies-design.md — N_plan=2 N_code=2 M=1 cap=3 — branch feature/plan-contracts-not-bodies — BASE 6f589ed_

## Phase 1 — Plan — DONE — 2026-08-31
plan: docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/plans/plan-contracts-not-bodies.md — 6 tasks
note: controller return carried narration before the marker line; fields parseable, accepted (worklist row 9 shape, recorded as evidence there)

## Phase 2 — Plan review — rounds 2 — cap — unresolved 0

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits c38f65a..6ba5c5c
- Task 1: complete — Contracts and Literal Bodies section + wording suite (c38f65a..05b6360)
- Task 2: complete — Contract field in Task Template (0aeca6b..c03a3e1)
- Task 3: complete — Plan Header authority note (fe9cad1..2992681)

## Phase 3 — Batch 2 (tasks 4–6) — COMPLETE — commits bcd2984..2d5bc29
- Task 4: complete — Self-Review check 5 (bcd2984..9d83cbc)
- Task 5: complete — lens targets + reviewer-templates check (3f274ac..31ceac1)
- Task 6: complete — CLAUDE.md line on-disk only + final verification (892b21b..2d5bc29)

## STOPPED — 2026-08-31 — phase 4 — code review left 2 user-decision items (rounds 2, cap, fixes 0)
Detail: docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/implementation/plan-contracts-not-bodies-review-log.md
Open: [I1] user-decision — lens gate bound to rewordable free-text phrase "reference implementations"; silent off-switch
Open: [I2] user-decision — Global Constraints block lets self-pinned literals bypass rule 5 unguarded
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/plans/plan-contracts-not-bodies.md

## STOPPED — 2026-08-31 — phase 4 — resume left 2 unresolved items at the verification cap (rounds 2, cap, fixes 3)
Detail: docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/implementation/plan-contracts-not-bodies-review-log.md
Open: [I2] unresolved — assert_exact for `**Exact content:**` is a whole-file grep; cannot fail if rule 4 is deleted (vacuous pass, Case 001 shape)
Open: [I3] unresolved — `**Files:**`-list completeness required by rule 1's boundary test but no decision procedure exists in check 5 or any lens target
note: earlier rulings [I1]/[I2] of the previous entry fixed in 86bf5c5; standing rule worked — 3 wording findings rejected with named reasons, no chain
note: controller return again carried narration before the marker (2nd occurrence this run; worklist row 9)
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/plans/plan-contracts-not-bodies.md

## STOPPED — 2026-09-01 — phase 4 — invocation 2 left 1 unresolved item (rounds 2, cap, fixes 5)
Detail: docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/implementation/plan-contracts-not-bodies-review-log.md
Open: [I3] unresolved — the `**Body authority:**` note contradicts itself: its open-ended "Other non-task plan content ... follows the same reference default" sentence precedes, and on a literal reading swallows, the sentence declaring that `**Global Constraints:**` and the note itself bind
note: introduced by this loop's own verification-2 fix; verification cycles for round 4 were spent, so the remedy could not ship reviewed
note: standing rule held — 2 Important findings rejected with named reasons ([I1] multi-code-review triage change, out of scope by the spec's Non-goals; [I2] property-binding needing a spec list the controller never reads)
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/plans/plan-contracts-not-bodies.md

## STOPPED — 2026-09-01 — phase 4 — 3 unresolved at the verification cap; note not converging by accretion
Detail: docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/implementation/plan-contracts-not-bodies-review-log.md
Open: [U1] unresolved — Self-Review check 5 quantifies over every fenced/quoted block "in the plan" but its buckets reach only task content, so the header block quote every generated plan carries fits no bucket: the check reports a defect on 100% of generated plans
Open: [U2] unresolved — an `**Exact content:**` marker whose reason is present but names no pin falls through both clauses and binds byte-for-byte, so a vacuous reason outranks a properly reasoned self-pin
Open: [U3] unresolved — task content that is neither fenced nor block-quoted (`Expected:` lines, `**Files:**` lists) is in neither of the note's two sets; this branch's own plan hit that class twice
note: [I3] and the mislabeled amendment both fixed (f026387); suites 16/16, 24/24, 10/10
note: the loop reports the note's LENGTH is now itself a defect — ~1500 chars, 7 normative sentences with nested exceptions; each of the last 4 verification cycles produced 3-4 findings of the single shape "case X falls between two sentences"
note: a third independent reviewer proposes the note stop binding by its wording and instead carry an explicit non-conflict disposition for findings against its own prose — decidable from the note alone; NOT acted on, it changes the binding regime
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/plans/plan-contracts-not-bodies.md

## Phase 4 — Code review — rounds 4 (2 invocations) — cap — fixes 10 — unresolved 0 — user_decision 0
Resolved by orchestrator ruling under the user's standing delegation: invocation 1 [I1]/[I2] (86bf5c5), invocation 2 [I2]/[I3] (808d813), [I3] note self-contradiction (f026387), and the structural restructure A-F (a10e5a6).
Standing rule bounded every verification chain: findings against plan-mandated wording were decided inside the loop (fixed, or rejected with a named reason); none escalated.

_Completed — 2026-09-01 — HEAD a10e5a6_
