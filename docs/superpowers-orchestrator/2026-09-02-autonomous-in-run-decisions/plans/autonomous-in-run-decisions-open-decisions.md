# Ruling record — autonomous-in-run-decisions

Every in-run ruling of this orchestration, appended as it was made, never
rewritten. Written by the orchestrating session under the user's standing
delegation; the predicate this run builds is not yet installed, so the
procedure was applied by hand.

## Ruling 1 — 2026-09-04 — phase 4 — [I5] a user's plan-governs answer can be overturned

- **Class:** design
- **Item:** [I5] Important skills/orchestrating-development/SKILL.md:1015 — the orchestrator can overturn a user's explicit plan-governs answer: a later invocation re-raises the same objection under a new id, the loop's decided-wording rule covers verification cycles only, and the orchestrator may read only the latest entry's disposition line
- **Contract clause:** "Must convey: the four-entry read list of spec R2 (latest disposition line only; task report file and `### Task <n>` section; the named plan clause and its spec section" — docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions.md, Task 2 Contract
- **Defensible answers:** (a) plan governs — keep four entries, accept that a user decision can be reversed; (b) amend plan — five-entry read list whose fifth entry is the ruling record, plus a fourth guard; (c) amend plan — widen the loop-side decided-wording rule from verification cycles to ordinary rounds
- **Forks:** design consistency: VERDICT (b), with the framing correction that the ruling record was never inside the thin-sequencer prohibition (it names plan bodies, diffs, reviewer reports, fix reports — not the orchestrator's own output), and the decisive point that a Phase 3 conflict's user answer exists in no review log at all. implementation practicality: VERDICT (b) — it is a revert of a revert, one file, 27 lines, breaking zero pins, while (c) fails seven plan-mandated assertions and still misses Phase 3. adversarial: VERDICT (d) else (b), rejecting (c) outright because its "decided wording" covers `decided (<who>)` for any who, which would make the orchestrator's own rulings unchallengeable — a silencer handed to the ruled party. Contradiction: none on the merits. Two forks tabled a variant (d) — carry the prior decision on the disposition line — and both named the same limit, that it covers Phase 4 only; it was therefore not taken in place of (b).
- **Resolution:** `amend plan: Task 2's contract becomes a five-entry read list, the fifth being the ruling record; spec R2 gains entry 5 and R7 gains guard 4. ; fix it: restore read entry 5 and guard 4 in the skill (the text withdrawn in 119b69a), and add guard 4's escalate-when-unsure branch.` — Reason: all three lenses converged on (b) and all three rejected (c); the adversarial lens's residual gap (a restatement of the same clause slipping past a quote match) is closed by the escalate-when-unsure branch rather than by the (d) machinery, which two forks showed covers Phase 4 only.

## Ruling 2 — 2026-09-04 — phase 4 — [I2] an amend-plan ruling can weaken a safety rail

- **Class:** design
- **Item:** [I2] Important skills/orchestrating-development/SKILL.md:992 — an `amend plan` ruling may remove or weaken a Global Constraint that restricts what may be staged, committed, deleted or touched; the closed escalation list has no entry for it, so a `forced` ruling with no second reader can lift the run's own safety rails
- **Contract clause:** "the closed escalation list `spec wrong`, `scope`, `irreversible`, `secret`, `chain` with the spec's definition of each" — docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/plans/autonomous-in-run-decisions.md, Task 1 Contract
- **Defensible answers:** (a) plan governs — the list is closed, accept the hole; (b) widen the `irreversible` definition so such an amendment escalates; (c) never `forced` — always a `design` item, so fork review always runs first
- **Forks:** design consistency: VERDICT (c) with a correction (key the rule on the closed binding set, not on Global Constraints alone), objecting that (b) needs a spec change which the predicate itself would escalate. implementation practicality: VERDICT (b), but only keyed on edit location — "an amendment that would edit the `**Global Constraints:**` block" is decidable from the disposition line's own `— clause:`, whereas "weakens a safety rail" is not; reusing the `irreversible` label avoids adding a sixth class, which would require editing the very Global Constraint that enumerates the labels. adversarial: VERDICT (b), and (c) alone is WORSE than (a) — forks inherit the orchestrator's transcript and its framing, so three converging forks launder a ruling behind a record that reads as independent review; it also named a live path in this run (round 4 [M12] plus the CLAUDE.md staging rail). Contradiction, surfaced not resolved silently: design consistency wanted (c), adversarial called (c) actively dangerous. Settled on the merits: the design-consistency lens assumed fork review is an independent second reader, and the adversarial lens showed it is not for a decision about the user's own repository; the design-consistency lens's own argument — that (b) needs a spec change and therefore escalates — supports escalation as the outcome by a different route.
- **Resolution:** `amend plan: spec R1 widens `irreversible` by edit location — an `amend plan` answer whose amendment would edit the plan's binding text (the `**Global Constraints:**` block or an `**Exact content:**` block) is `escalated (irreversible)`; spec R5 gains the no-delete bound (an amendment appends a scoped exception instead of deleting a clause). ; fix it: write both rules into the skill.` — Reason: two of three lenses chose (b); the third's objection was procedural, not on the merits. The trigger is the edit location the disposition line already carries, so no new judgement is introduced, and the label set stays closed at five. The change makes the run stop MORE often, never less, so it cannot be motivated judgement in the self-serving direction. **Surfaced to the user at the Phase 5 report:** the closed escalation list is the user's own wording, and this widens one of its definitions; a one-line instruction reverts it.

## Ruling 3 — 2026-09-04 — phase 4 — [I1] guard 2's two prohibitions are unpinned

- **Class:** forced
- **Item:** [I1] Important tests/in-run-rulings/run-tests.sh:728 — guard 2's two prohibitions ``Never `plan governs`, never `accept``` are unpinned; only the fragment `a Critical is never rejected` is asserted, so a rewrite letting a Critical be closed with `accept:` and no code change would ship green
- **Contract clause:** "Invariants: `a Critical is never rejected`" — plans/autonomous-in-run-decisions.md, Task 5 Contract
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: pin guard 2's two prohibitions in the guards range.` — The fact that makes every other outcome indefensible: the suite exists to make a rewrite of this wording fail, and the finding names a rewrite that keeps it green. A check that cannot fail under the mutation it exists to catch verifies nothing. Reading the shipped skill confirms the wording is present and correct, so this is a test gap only.

## Ruling 4 — 2026-09-04 — phase 4 — [I2] negative checks do not fold line wraps

- **Class:** forced
- **Item:** [I2] Important tests/in-run-rulings/run-tests.sh:836 — the three stop-policy and Phase 3 "the old wording is gone" negative checks scan line by line while every positive check folds line wraps first, so a re-added stop rule that straddles a re-wrapped line break reports PASS
- **Contract clause:** none — the finding is against the suite's own consistency, not against plan text
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: fold line wraps in the negative checks exactly as the positive checks do; fold in the carried Minor [M5] at the same line, which is the same defect on the `unresolved > 0` disjunct.` — Forced: the suite already fixes the folding convention for positive checks, so a negative check that does not fold is inconsistent with the suite's own stated invariant and silently passes the case it exists to catch.

## Ruling 5 — 2026-09-04 — phase 4 — [I3] the closedness scan passes on zero bullets

- **Class:** forced
- **Item:** [I3] Important tests/in-run-rulings/run-tests.sh:227 — the closedness scan reports PASS when its ``^- ``<label>``` regex matches no bullet at all, so indenting or re-tabling the five escalation reasons and adding a sixth keeps the suite green while the predicate stops being closed
- **Contract clause:** none — a vacuous-pass defect in the suite
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: the scan must fail when it matches no bullet, and must assert the five expected labels are exactly the labels found.` — Forced, and it is Case 001's class exactly: a check that passes vacuously on an empty match set reports success while verifying nothing. The closed escalation list is the feature's central claim; a scan that cannot detect a sixth member does not test it.

## Ruling 6 — 2026-09-04 — phase 4 — [I4] the design-to-fork-review link is unpinned

- **Class:** forced
- **Item:** [I4] Important tests/in-run-rulings/run-tests.sh:239 — nothing pins the link from the predicate's `design` class to the fork review; a mutation replacing `Decided after the fork review (below).` with `Decided directly, with no subagent.` left the suite at 300 passed, and every fork assertion is scoped to a subsection nothing would then reach
- **Contract clause:** none — a coverage gap
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: pin the sentence that sends a design item to the fork review.` — Forced: the reviewer ran the mutation and measured the suite still passing (300 passed). Independent fork review is one of the feature's three safety properties; a suite that stays green when the branch stops performing it is not testing the feature.

## Ruling 7 — 2026-09-04 — phase 4 — [I3 round 5] the branch amends its own spec

- **Class:** escalated (spec wrong)
- **Item:** [I3] Important docs/superpowers-orchestrator/2026-09-02-autonomous-in-run-decisions/specs/autonomous-in-run-decisions-design.md:161 — the branch amends its own requirements document: spec R1, R2, R5 and R7 carry `(amended by ruling <n>)` markers and a new `## Amendments` section attributes them to orchestrator rulings 1 and 2, while the rule this branch ships classes a spec change as `escalated (spec wrong)` — the spec author's decision, never the orchestrator's; nothing defines how a spec amendment is recorded or by whom, and the plan's File Structure table does not list the spec as a file this plan modifies
- **Contract clause:** "`spec wrong` — requires changing the spec, that is, changing what \"done\" means for this run" — plans/autonomous-in-run-decisions.md, Task 1 Contract
- **Defensible answers:** (a) the amendments stand, and the spec gains a rule saying an orchestrator ruling may amend the spec and how it is recorded; (b) the amendments are reverted and both rulings are re-made without touching the spec, which means Ruling 2's widening of `irreversible` does not ship; (c) the amendments stand for Ruling 1 (a read entry, no change to the user's escalation list) and are reverted for Ruling 2 (which widens a definition the user wrote)
- **Forks:** none — not dispatched. The finding asserts that the orchestrator exceeded its authority. Deciding it in the orchestrator's own favour is the motivated judgement the guards exist to prevent, and fork review would not cure that: the forks inherit this session's framing, which is the objection Case 013 already recorded against treating fork review as an independent second reader.
- **Resolution:** escalated — the spec fixes what "done" means for this run, and the closed escalation list it defines is the user's own wording from the run's prompt. Two reviewers of four raised it independently, and the plan's File Structure table confirms the spec was never a file this plan may modify. The orchestrator's recommendation, offered but not applied: (c) — keep Ruling 1's read entry, which adds no class and touches no wording the user authored, and let the user decide Ruling 2's widening of `irreversible`.

**Follow-up (Ruling 7) — 2026-09-04, the spec's author decided.** Option (c),
the orchestrator's recommendation: Ruling 1's amendments stand, confirmed by
the author in the same decision; Ruling 2 is withdrawn in full, so the closed
escalation list and all five of its definitions stay exactly as the author
wrote them, and the no-delete bound is withdrawn with it. The safety-rail gap
is recorded in the spec as a known limitation, not closed. The skill text and
the test pins that implemented Ruling 2 are removed by the resume, and the
plan's File Structure table now lists the spec (ruling 8).

## Ruling 8 — 2026-09-04 — phase 4 — the plan never listed the spec as a file it modifies

- **Class:** forced
- **Item:** the second half of round 5 `[I3]` — the plan's File Structure table does not list the spec, yet Ruling 1's confirmed amendments modify it
- **Contract clause:** none — the table is reference text under the plan's Body-authority note
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `amend plan: add the spec to the File Structure table, marked as edited only by an author-confirmed orchestrator ruling and implemented by no task.` — Forced: the file is modified on this branch and the table claims to list every file the plan touches, so leaving it out states something false. The row records the authority the author has now given, which is the "by whom" the finding said was undefined.
