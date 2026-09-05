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

## Ruling 9 — 2026-09-04 — phase 4 — [I1 v3] the fork subsection's rules have no failing assertion

- **Class:** forced
- **Item:** [I1] Important tests/in-run-rulings/run-tests.sh:553 — the fork subsection is covered only by the bare fragments `evidence consistency` and `general-purpose`, each occurring several times in range, so five mutations each left the suite at 397 passed: removing the fresh non-inheriting reviewers rule, removing the fresh-subagent-never-a-fork clause, removing the wait-for-all-notices rule, widening the 25-line return bound to 200, and removing the platform-degradation sentence
- **Contract clause:** "Verification: section 3 of `bash tests/in-run-rulings/run-tests.sh`" — plans/autonomous-in-run-decisions.md, Task 3 Contract
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: pin each fork rule with an assertion that fails when that rule is deleted, scoped inside the fork subsection.` — Forced: the reviewer ran five mutations and measured the suite green each time, and the plan's Task 3 Contract names this section as the verification for exactly those rules, so the contract is unmet as written. The first two mutations remove the independence guarantee that makes a contradicted `design` ruling reviewed rather than self-confirmed, which is one of the feature's three safety properties.

## Ruling 10 — 2026-09-04 — phase 4 — [I7] amendment markers sit on reference text

- **Class:** forced
- **Item:** [I7] Important skills/multi-code-review/SKILL.md:652 — the definition of decided wording includes a plan clause carrying `(amended by ruling <n>)` without requiring the clause to be binding text, while this branch's own plan carried the marker on a File Structure table row and inside a Contract bullet, both reference text, so a finding against either would be rejected as `plan governs (loop decision)` although the same rule says a finding against reference plan text stays an ordinary finding
- **Contract clause:** "the exact definition of decided wording (… and a plan clause carrying `(amended by ruling <n>)`)" — plans/autonomous-in-run-decisions.md, Task 8 Contract
- **Defensible answers:** (a) bound the marker branch to binding text, which narrows wording Task 8's Contract fixes verbatim; (b) remove the markers from the reference text they should never have carried
- **Forks:** none — forced. The skill's own amendment procedure writes the marker exclusively onto binding clauses, so a marker on a reference row is a defect in that row, not in the rule. Answer (a) would narrow a verbatim contract to accommodate an error answer (b) removes at its source.
- **Resolution:** `fix it — applied directly by the orchestrator, since both edits are plan text: the File Structure row added by ruling 8 keeps its explanation but loses the marker, because adding a row is not amending a clause; the Task 2 Contract bullet keeps its amendment record in the block quote under the task heading and loses the marker, because a Contract bullet is not in the plan's closed binding set. No marker now sits on reference text.` — Recorded follow-up, not taken here: bounding the rule itself to binding text would harden it against a future ruling repeating this error, and it narrows plan-mandated wording, so it belongs to a change the author assents to.

## Ruling 11 — 2026-09-04 — phase 4 — [I8] the secret class cannot match a Phase 3 item

- **Class:** escalated (spec wrong)
- **Item:** [I8] Important skills/orchestrating-development/SKILL.md:688 — the `secret` class is defined over an item's disposition reason or summary and narrowed to one producer in the review loop, both Phase 4 constructs, while a Phase 3 open item is a `### Question <k>` or `### Conflict <k>` section with no disposition line. The batch template on this same branch anticipates a credential there. An implementer that raises a hard-coded credential as a Phase 3 question therefore falls through to `forced` or `design` and is decided autonomously, which is what "You never decide a `secret` item" exists to prevent
- **Contract clause:** "the closed escalation list `spec wrong`, `scope`, `irreversible`, `secret`, `chain` with the spec's definition of each" — plans/autonomous-in-run-decisions.md, Task 1 Contract
- **Defensible answers:** (a) widen the `secret` definition to cover a Phase 3 section that names a credential; (b) leave it and record the gap
- **Forks:** none — not dispatched. Guard 4 fires: the spec's author decided this exact clause on 2026-09-04, ruling that the escalation list and all five definitions stay exactly as written. A ruling that widened one of them now would overturn that decision, which guard 4 forbids without qualification.
- **Resolution:** escalated — the author's decision of 2026-09-04 covers the clause this item cites. The orchestrator's recommendation, offered not applied: widen it, because the gap defeats the one class the predicate says the orchestrator never decides.

## Ruling 12 — 2026-09-04 — phase 4 — [I3 r11] nothing delivers the secret residue

- **Class:** escalated (spec wrong)
- **Item:** [I3] Important skills/orchestrating-development/SKILL.md:760 — the `secret` definition asserts that for a credential in reviewed code "a secret in reviewed code is a Critical the loop's fix removes, and only the residue (rotation, history) reaches you", but no mechanism delivers that residue: once the fix subagent removes the credential the disposition is `fixed`, which is not an open item, so the predicate never sees it, and neither the loop's return, its disposition shapes nor the Phase 5 report carries a secrets field. The branch reaches the merge decision with the credential scrubbed at HEAD, still in the branch's history, and nobody told to rotate it — while the sentence actively tells the orchestrator not to escalate, because it believes something else will
- **Contract clause:** "the closed escalation list `spec wrong`, `scope`, `irreversible`, `secret`, `chain` with the spec's definition of each" — plans/autonomous-in-run-decisions.md, Task 1 Contract
- **Defensible answers:** (a) edit the `secret` definition to drop the false assurance and escalate instead; (b) add a secrets field to the Phase 5 report and to the loop's return, which the plan does not carry today; (c) leave it and record the gap
- **Forks:** none — not dispatched. Guard 4 fires for the same reason as ruling 11: the item cites the clause the author decided on 2026-09-04.
- **Resolution:** escalated — the orchestrator's recommendation, offered not applied: (b), because it closes the hole without touching the definitions the author reserved. A secret found in reviewed code is real, its history survives the fix, and the sentence that tells the orchestrator to stay silent about it is the dangerous half.

**Follow-up (Rulings 11 and 12) — 2026-09-04, the spec's author decided.**
Ruling 12's item is closed by the author's chosen route: a `Secrets found:`
line on the review loop's completion report and the same list on the Phase 5
report, which touches no escalation-class definition. Spec R13 and the plan's
Task 6 and Task 7 amendments carry it, author-confirmed. Ruling 11's item —
the `secret` class cannot match a Phase 3 section — stays open by the
author's decision and is recorded in the spec's Amendments as a known
limitation. The author also chose the branch outcome: merge to main once the
remaining fixes land and pass review.

## Ruling 13 — 2026-09-04 — phase 4 — the secret residue reaches a person

- **Class:** design (decided by the spec's author, applied by the orchestrator)
- **Item:** round 11 `[I3]`, escalated as Ruling 12
- **Contract clause:** none — the author's decision authorises the change
- **Defensible answers:** as tabled in Ruling 12
- **Forks:** none — the author decided; the orchestrator applies
- **Resolution:** `amend plan: spec R13 and the Task 6 and Task 7 amendments, committed with this ruling. ; fix it: write the Secrets found: line into multi-code-review's completion report and the same list into Phase 5 step 3 of orchestrating-development, with assertions in tests/in-run-rulings/run-tests.sh.`

## Ruling 16 — 2026-09-05 — phase 4 — [I3 r14] a parameter override silently resets the in-run cap

- **Class:** forced
- **Item:** [I3] Important — the in-run resume cap counts `## RULING` entries written after the later of the log's latest `_Invocation` line and its latest `## STOPPED` entry, but Resume step 5 appends a `— resumed_` `_Invocation` line whenever a resume prompt overrides a parameter, with no stop involved; that line moves the anchor and resets the cap
- **Contract clause:** the cap's counting rule, plan-mandated
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: the cap's anchor ignores an `_Invocation` line that ends `— resumed_`. Only a first invocation line and a `## STOPPED` entry move it.` — The fact that makes every other outcome indefensible: the cap exists to bound a chain of in-run rulings, and it resets when a human answers the open items, because that answer ends the chain. A parameter override is not an answer to any open item — it changes N, M or the batch cap — so resetting on it lets an unbounded chain continue behind a change that decided nothing. This run itself appended such a line when the user raised N and M during batch 1.

## Ruling 17 — 2026-09-05 — phase 4 — [I2 v3] the Secrets found: rule is half-pinned

- **Class:** forced
- **Item:** [I2] Important tests/in-run-rulings/run-tests.sh — the assertion's needle stops at "reported an exposed secret or credential in reviewed code" and leaves the rest of the same sentence unpinned anywhere in the suite
- **Contract clause:** spec R13, plan Task 6 and Task 7 amendments (author-confirmed)
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: pin the rest of the sentence — that the line is always written, that a report without it is defective, and that it never reproduces the secret value.` — Forced: the author confirmed this requirement two days ago precisely so a credential reaches a person; a pin covering half the sentence leaves the other half free to be deleted, and the deleted half is the part that makes the line mandatory.

## Ruling 18 — 2026-09-05 — phase 4 — [I3 v3] the Phase 3 removal has no negative assertion

- **Class:** forced
- **Item:** [I3] Important tests/in-run-rulings/run-tests.sh — the suite carries five negative assertions covering the two Phase 4 removals and the three stop-policy removals, but none covers the Phase 3 removal this branch also makes
- **Contract clause:** none — a coverage gap of the same class as the five assertions that exist
- **Defensible answers:** n/a — forced
- **Forks:** none — forced
- **Resolution:** `fix it: add the sixth negative assertion, folded like the other five, so re-adding the base revision's unconditional Phase 3 stop turns the suite red.` — Forced: five sibling removals each carry the assertion this one lacks, so the suite's own convention decides it; without it the branch's Phase 3 change can be reverted silently.

## Ruling 19 — 2026-09-05 — phase 4 — [I1 v3] the weak-needle sweep does not converge

- **Class:** design
- **Item:** [I1] Important tests/in-run-rulings/run-tests.sh — the weak-needle sweep of the previous two cycles is not finished; single-word needles still stand where an inverted rewrite would keep the word and pass, the sharpest being the tag-default rule guarded only by the bare fragment `untagged`, and `new invocation` is in the same class; multi-word free-text needles still run through the unfolded helper at four more sites, where a pure reflow produces a failure naming a rule that did not change
- **Contract clause:** none — the suite's own consistency
- **Defensible answers:** (a) another sweep of the named sites; (b) accept and record the residual; (c) one structural rule, a lint over needle length or helper use
- **Forks:** implementation practicality: VERDICT (d) — make `assert_in_range`'s `fragment` branch delegate to the folded implementation, which fixes about 33 reflow-fragile sites at one helper instead of 33 call sites while the 69 `exact` byte pins keep their unfolded semantics; then strengthen the two named needles; record that needle strength is a reviewer judgement no check closes. It rejected (c) with measurements: a lint must parse its own 2358-line source in bash without process substitution, and a mis-parse produces exactly the phantom failure this item complains about; 28 needles are 14 characters or shorter and most are legitimate byte pins. adversarial: VERDICT (d) — sweep by inversion over a named finite set rather than by needle shape: for each assertion guarding a stated design property (the tag-default rule, guard 4's `(user)` lookup and its escalate-when-unsure branch, the closed label set, the fork independence rules) add a negative assertion that the INVERTED sentence does not satisfy the needle. It demonstrated the danger concretely: inverting "A line without a `(<who>)` tag is a user line" to "is an orchestrator line" keeps the needle `untagged`, the suite stays green, guard 4 then finds no `(user)` answer and never fires, and Case 012's defect returns. Contradiction: none — the two verdicts are complementary halves of one fix, and both rejected (b) and (c).
- **Resolution:** `fix it: adopt both halves. (1) `assert_in_range`'s `fragment` branch delegates to the folded implementation, so every free-text fragment folds by construction and the `exact` byte pins are untouched. (2) For each assertion guarding a named design property — the tag-default rule, guard 4's `(user)` lookup and its escalate-when-unsure branch, the closed label set, the fork independence rules — add a negative assertion that the inverted sentence does not satisfy the needle, and strengthen `untagged` and `new invocation` to their owning sentences. (3) Record in the suite's header comment that needle strength beyond this set is a reviewer judgement no check can close, so the residue is a stated limitation and not an eleventh sweep.` — Reason: the two lenses reached the same shape from opposite directions, and each supplied what the other lacked. The folding half is finite and needs no judgement; the inversion half terminates because its list comes from the design's stated properties rather than from a scan of the file. Answer (b) was rejected by both, and the adversarial lens said why it matters: the residual is not evenly spread, it is concentrated on attribution and escalation, which are the two rules the branch exists to make trustworthy.

## Ruling 20 — 2026-09-05 — phase 4 — [I7] a stated Contract is not in the binding set

- **Class:** escalated (spec wrong)
- **Item:** [I7] Important skills/multi-code-review/SKILL.md:1026 — the binding test recognises only a `— clause: Global Constraints` location and a `Task <n>` clause inside an `**Exact content:**` block, so a finding that contradicts a task's stated `**Contract:**` is classed reference text: the orchestrator may answer a bare `fix it`, the loop applies it, and contract-governed behaviour changes with no ruling, no marker and no audit note
- **Contract clause:** spec `## Plan amendment` "A plan conflict is a collision with the plan's **binding** text — under the 7.7.0 Body-authority note, a `**Global Constraints:**` entry or an `**Exact content:**` block"
- **Defensible answers:** (a) leave it; (b) widen the binding set to include a stated `**Contract:**`; (c) record a bare `fix it` against a `Task <n>` clause in the ruling record without calling it an amendment; (d) stop restating the set and defer to the plan's own Body-authority note, which already carries the Contract carve-out
- **Forks:** design consistency: VERDICT (d) — the plan's Body-authority note keeps two sets apart on purpose, and the spec quotes that note and drops half of the sentence it is quoting, so the disagreement is a miscitation in the spec rather than a defect in the note; correcting a miscitation is a different act from widening a definition the author chose. adversarial: VERDICT (b), with (d) strictly better, and it measured what the shipped rule costs on this very plan: nine `**Contract:**` fields and zero `**Exact content:**` blocks, so the binding set here has exactly one member, and guard 2's own invariant "a Critical is never rejected" lives in Task 5's Contract, outside it — a bare `fix it` could rewrite the guard protecting Criticals with no amendment, no marker and no audit note. It also found that the loop's unsure tie-break leans on the orchestrator's pre-commit self-check, which tests the same two locations, so the two checks share one omission. Contradiction: none — both tabled the same fourth option, one framing it as a miscitation and the other as a duplication that should defer to the note. Both said the fix touches spec text.
- **Resolution:** escalated — the spec's own Amendments section now records the author's rule that an orchestrator ruling does not amend this spec on its own authority, and the fix edits the spec's definition of binding text. The orchestrator's recommendation, offered not applied: option (d) — delete the branch's second copy of the binding set and defer to the plan's `**Body authority:**` note, which every plan already carries and which reads "unless it contradicts a stated `**Contract:**` or a global constraint"; pair it with a bound on the decided-wording rule so an amended Contract does not become unreviewable. Both lenses noted the safety consequence: on this plan the invariant forbidding the rejection of a Critical is currently changeable by a bare `fix it`.
