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

## Ruling 3 — 2026-09-09 — phase 3 — [task 5/1] Task 6 Step 2 item 5 contradicts Task 5 Step 4

- **Class:** forced
- **Item:** [task 5/1] n/a n/a — Task 6 Step 2 item 5 says to leave the three standalone M-origin forms unchanged, "exactly as in Task 5", but Task 5 Step 4 adds a fourth choice to the byte-identical list in the other file; following item 5 also reports a tier-2 M as the hardcoded default.
- **Contract clause:** "**Every path that resolves a parameter at tier 2 without asking must echo the resolved value and its source,**" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md (Global Constraints, entry 11)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: Task 6 Step 2 item 5 now directs the same fourth-choice addition Task 5 Step 4 makes, and excludes only the N wording from that branch — item 5's instruction was unexecutable as written, because "exactly as in Task 5" describes a Task 5 step that does change those forms, and the only other reading breaches both Global Constraint 11 and Task 6's own binding Contract, which requires the same four properties as Task 5's contract.

## Ruling 4 — 2026-09-09 — phase 3 — [task 3/1] "presents `<d-n>` first" contradicts the prose-question rule

- **Class:** forced
- **Item:** [task 3/1] n/a n/a — Task 3 Step 1 pastes the normative sentence "'Presented first' does not apply to a prose question", and Task 3 Step 2 then mandates a sentence saying the ask-once prose question presents `<d-n>` first; Task 4 Step 2 repeats the same clause.
- **Contract clause:** "\"Presented first\" does not apply to a prose question." — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/specs/superpowers-defaults-block-design.md (The offered-default rule, Prose questions)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: Task 3 Step 2 and Task 4 Step 2 now say the question offers `<d-n>` and that "presented first" does not apply to it — the design document states that rule for prose questions with no carve-out, so the only resolution that does not change the spec is to drop the "presents first" clause; the alternative would have required narrowing the spec's own sentence, which is out of this run's authority.

## Ruling 5 — 2026-09-09 — phase 3 — [task 7/1] Task 7 Step 3's citing site carries 2 of 4 required parts

- **Class:** forced
- **Item:** [task 7/1] n/a n/a — Task 7 Step 3's replacement N sentence cites `Resolving a default` but restates only the three tiers and the injection-scoping rule, omitting the tool-result rule and the platform clause.
- **Contract clause:** "**The citation does not stand alone.**" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md (Global Constraints, entry 8)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: the body now carries all four parts, in the wording Task 5 Step 3 already uses for the byte-identical site in the sibling file — Global Constraint 8 says an implementer may not trim below the four parts, and the only alternative would declare a binding constraint inapplicable at a site the plan nowhere exempts.

## Ruling 6 — 2026-09-09 — phase 3 — [task 7/2] Task 7 Step 6's resume-prompt body carries 2 of 4 required parts

- **Class:** forced
- **Item:** [task 7/2] n/a n/a — Task 7 Step 6's replacement resume-prompt body cites `Resolving a default` by name and by file, so it is a citing site, and it restates only the tiers and the injection-scoping rule.
- **Contract clause:** "**The citation does not stand alone.**" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md (Global Constraints, entry 8)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: the body now states the tool-result rule and the platform clause as well — nothing in the plan exempts a resume prompt from Global Constraint 8, and this same task's Steps 4 and 5 bodies already carried all four parts, so Step 6 was the outlier rather than a stated exception.

## Ruling 7 — 2026-09-09 — phase 3 — [task 6/1] the resume-path origin echo and the widened placeholder

- **Class:** design
- **Item:** [task 6/1] n/a n/a — The plan mandates a two-alternative origin echo on the resume path, while the normative section the same plan added defines the placeholder in that echo as a value that can also come from a third source (tier 1, a value stated in this session), so the echo can state an origin the value did not have.
- **Contract clause:** "Never state an origin the values did not have." — skills/writing-plans/SKILL.md (resume-path origin paragraph), restated as Global Constraints entry 11 of docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md
- **Defensible answers:** (a) add a third, tier-1 alternative to the echo at every site; (b) declare the two alternatives complete because the branch never consults a stated value, leaving the committed wording unchanged; (c) keep exactly two alternatives and state in the same branch that the placeholders there mean the tier-2-or-tier-3 result.
- **Forks:** 3 of 3 — design consistency: VERDICT (b) Side A governs, TABLED (c) add a clarifying clause; implementation practicality: VERDICT (b) Side A governs, TABLED (c) one clarifying sentence in both gate files; adversarial: VERDICT neither (a) nor (b) as tabled, TABLED (c) amend the plan so the branch states the placeholders mean the tier-2-or-tier-3 result; contradiction: none — all three converged on (c), which neither side had tabled
- **Resolution:** amend plan: Task 5 Step 4 keeps the two-alternative choose-one echo the design document requires and now also mandates one sentence stating that on this path `<d-n>` and `<d-m>` mean the tier-2-or-tier-3 result, because the branch does not consult a value stated in this session; the sentence goes into every file carrying that echo — (a) was rejected because the design document asks for exactly two new forms and a tier-1 echo form would name a source the branch never reads, and (b) was rejected as worded because the file points the reader at the wider definition through "(defined below)", so silence leaves the false-origin reading available. Task 5 is unticked and re-run so `skills/brainstorming/SKILL.md` receives the same sentence and the two gate files stay identical.

## Ruling 8 — 2026-09-09 — phase 3 — [task 11/1] the mandated release-notes summary exceeds its own word cap

- **Class:** forced
- **Item:** [task 11/1] n/a n/a — Task 11's Contract invariant caps the RELEASE-NOTES.md three-line summary at 120 words, while Step 2's fenced reference body supplies 150; every other invariant of the task is satisfied.
- **Contract clause:** "the whole summary near 100 words and at most 120" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md (Task 11, Invariants), restating the release rule of CLAUDE.md
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: Step 2's fenced summary body is rewritten at 113 words, keeping all three labels and every fact the longer version stated — the repository's own CLAUDE.md fixes the summary at "near 100 words (120 at most)", so the Contract invariant restates a standard outside this run's authority and raising the cap was never an available outcome; the body is the side that had to change.
