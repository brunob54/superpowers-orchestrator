# Open decisions — superpowers-defaults-block

## Ruling 1 — 2026-09-09 — phase 3 — [task 1/1] Task 1 Step 2 grep writes the closing delimiter unbroken

- **Class:** forced
- **Item:** [task 1/1] n/a n/a — Task 1 Step 2's second verification command writes the closing delimiter as a fixed string, so the plan file itself carries a complete block, which Global Constraint 2 forbids for this plan.
- **Contract clause:** "**No complete block may appear in any skill body, any documentation file, or this plan.**" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md (Global Constraints, entry 2)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: rewrite Task 1 Step 2's second verification command in the bracketed regular-expression form the plan already uses at its three other delimiter greps, leaving the expected count at 2 — Global Constraint 2 is binding plan text that forbids a complete block anywhere in this plan and states no exception for a substring inside a shell command, so keeping the unbroken form would leave a constraint the plan itself mandates already violated.

## Ruling 2 — 2026-09-09 — phase 3 — [task 4/1] Task 4 Step 2's mandated body drops the required scoping phrase

- **Class:** forced
- **Item:** [task 4/1] n/a n/a — The "In short:" clause of the body Task 4 Step 2 mandates writes "the last complete block of the session-start injection", the unbackticked spelling Global Constraint 9 explicitly forbids.
- **Contract clause:** "**The scoping phrase is load-bearing and must never be dropped.**" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md (Global Constraints, entry 9)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: rewrite that clause to "only the last complete `<superpowers-defaults>` block **of the `hooks/session-start` injection** counts", matching the sibling body for the same edit in the plan's Task 3 — Global Constraint 9 fixes one byte form for this phrase and says "never" of the unbackticked spelling, which the test suite's assertion does not match, so the mandated body as written produced text the constraint forbids.
