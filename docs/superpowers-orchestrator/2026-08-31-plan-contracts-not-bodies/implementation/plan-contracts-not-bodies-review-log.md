# Review Log — plan-contracts-not-bodies

_Invocation 1 — 2026-08-31 — N=2 M=1 — BASE..HEAD 6f589ed..0a9a73a — branch feature/plan-contracts-not-bodies — gate: orchestration_

## Round 1 — Correctness & spec alignment — fable
**Reviewer verdict:** 0 Critical, 0 Important, 0 Minor
**Converged:** no
### Dispositions
- carried — tests/writing-plans/run-tests.sh helpers assert_in_block/first_line_of unused until Tasks 2-3 (reviewer: resolved at head — assert_in_block runs in checks 2 and 3 and exercises first_line_of internally; recommendation ship-as-is)
- carried — tests/writing-plans/run-tests.sh check 4 unscoped whole-file assert_fragment for "falsifiable" (plan-mandated shape; word occurs exactly once at head, in Self-Review check 5; recommendation ship-as-is)

## Round 2 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — multi-doc-review lens gate for the three contract targets is bound to the free-text header phrase "reference implementations", which the design's own rules treat as rewordable free text; a reword or a dropped note silently switches the gate off with no signal (plan-mandated: the plan gates the lens on that header phrase — plan lines 474, 519-520; reviewer suggests gating on the byte-pin label `**Body authority:**` and exempting the authority note from the reference default)
- [I2] user-decision — rule 6(b) makes the `**Global Constraints:**` block bind unconditionally, giving self-pinned literals an unguarded bypass of rule 5: a plan can restate its own self-pins as Global Constraints and no lens target or self-review check inspects those entries (plan-mandated: the plan's rule text makes Global Constraints bind as stated and stop the run — plan lines 236-237; reviewer suggests extending rule 5 and the R5 lens target or Self-Review check 5 to Global Constraints entries)
- [M1] carried — rule 4 wording "the line immediately above the fenced block" is voided by a habitual blank line between the marker and the fence; two agents resolve it differently (entangled with the open decisions on rules 4-6; fix wording once I1/I2 are decided)
- [M2] carried — tests/writing-plans/run-tests.sh first_line_of anchors headings by containment (grep -nF), not whole-line match; a future prose mention of `## Task Template` or `## Plan Header` earlier in the file silently retargets the block-scoped checks (suggest grep -nxF)
- [M3] carried — the false-`none` test is undecidable for deletion-only tasks: rule 1 defines governed artifacts via "introduces or modifies", so reviewers will disagree on `Contract: none` for a delete-only task (suggest one clause in rule 1's boundary test stating whether deletion counts)

_Completed — 2026-08-31 — cap reached — HEAD 2d5bc2989929bb1ed2ec2c6d90ad28df7c529de9_
