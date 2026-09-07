# Open decisions — marker-position-tolerance

Ruling record for the orchestration run. Appended, never rewritten.

## Ruling 1 — 2026-09-07 — phase 4 — [I2] Which marker line begins the report when the window holds two

- **Class:** design
- **Item:** [I2 inv 1] Important skills/orchestrating-development/SKILL.md:170 — taking the FIRST qualifying marker line in the window as the report start silently ignores everything above it, so a controller that quotes a marker line or corrects a draft return has its wrong block parsed; both reviewers propose taking the last qualifying line or requiring a recognised leading token. Raised twice in one invocation: round 2 [I2] and verification 1 [I1].
- **Contract clause:** "A line equal to another skill's marker is ordinary preamble. With more than one such line, the first begins the report; everything above it is ignored." — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Global Constraint 3
- **Defensible answers:** (a) keep the first qualifying marker line; (b) take the last qualifying marker line; (c) take the first marker line whose next non-empty line begins with a recognised leading token, else malformed.
- **Forks:** 3 of 3 — design consistency: VERDICT Outcome 1, keep first-match, because the spec's stated invariant is that each side accepts everything it accepts today and more; implementation practicality: VERDICT Outcome 2, last-match, because a superseded draft block carrying a token is parsed silently; adversarial: VERDICT Outcome 1 amended with a log note, because last-match breaks on a BLOCKED reason that quotes the contract below the report, which is this repository's likeliest quoting case; contradiction: settled — a return whose first line equals the marker and which carries a second marker line lower in the window is accepted today and would be malformed under last-match, so outcome (b) narrows what the orchestrator accepts and breaks the invariant every other part of the design rests on.
- **Resolution:** amend plan: Global Constraint 3 keeps the first-match rule and now also requires the orchestrator to record `note: return carried <n> marker lines; parsed from the first` in the orchestration log when the window holds more than one marker line; fix it: state that note requirement in the Return contract of `skills/orchestrating-development/SKILL.md`, beside the first-match sentence — the reviewers' real point was that the ignored block is silent, and a note removes the silence without touching the parse.

## Ruling 2 — 2026-09-07 — phase 4 — [I2] No bound on where a consumed field is read

- **Class:** forced
- **Item:** [I2 inv 1] Important skills/orchestrating-development/SKILL.md:176 — with the 15-line cap no longer a malformed condition, no rule bounds WHERE in the return a consumed field is read, so an appendix line holding `unresolved=2` below a `unresolved=0` token block can flip a stop rule; reviewer proposes reading consumed fields only from the marker line and the 14 lines below it. Raised in verification cycle 1.
- **Contract clause:** "The malformed list stays closed: no marker line in the window, no leading token, or a consumed field (`tasks=`, per-task numbers, `rounds=`, `outcome=`," — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Global Constraint 4
- **Defensible answers:** n/a
- **Forks:** none
- **Resolution:** amend plan: Global Constraint 4 now says every consumed field is read only from the marker line and the 14 lines below it; fix it: state that bound in the Return contract of `skills/orchestrating-development/SKILL.md` — the forced fact: the contract defines the report as the marker line plus at most 14 lines below it, so a value standing below that block is text the contract never defined, and reading it there is indefensible under any outcome.

## Ruling 3 — 2026-09-07 — phase 4 — [I2] Receiver-side usability rules stayed first-line while the hook widened

- **Class:** design
- **Item:** [I2 inv 1] Important skills/multi-code-review/SKILL.md:602 — the hook exemption widened for all three markers while only the orchestrator's controller-return contract widened with it, so a preambled reviewer or research report now passes the hook and is then discarded or re-dispatched by its receiver, which costs more than the block it replaced; reviewer proposes widening the three receiver-side usability rules to the same window, or narrowing the hook to the orchestration marker alone. Raised in verification cycle 2.
- **Contract clause:** "The skill-side usability rules of the other two markers are untouched: `skills/multi-code-review/SKILL.md:602`, `skills/multi-doc-review/SKILL.md:114`," — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Task 4
- **Defensible answers:** (a) keep the plan as written; (b) widen the three receiver-side usability rules to the same window; (c) narrow the hook to the orchestration marker alone.
- **Forks:** 3 of 3 — design consistency: VERDICT Outcome 1, because the spec decided this question by name and outcome (c) contradicts Global Constraints 2 and 5; implementation practicality: VERDICT Outcome 1, because outcome (b) misidentifies one of its three targets (`research-prompt.md:164` instructs the researcher, it is not a receiver rule) and outcome (c) reverts Task 1's parameterized tests; adversarial: VERDICT Outcome 1, because outcome (b) imports this same invocation's unresolved parse-start question into three more receivers; contradiction: none — all three lenses reached outcome (a) independently.
- **Resolution:** plan governs: "The skill-side usability rules of the other two markers are untouched: `skills/multi-code-review/SKILL.md:602`, `skills/multi-doc-review/SKILL.md:114`," — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md — and the finding's cost premise does not hold: the guard's block text is "Redo your assigned task using only your core tools" (`hooks/subagent-guard.js`), which never mentions the marker, so a block never converted an unusable preambled report into a usable one. The receiver's single identical retry happened either way; the block only added a turn on top. Widening the hook is therefore cheaper than what it replaced, not dearer. Two lenses tabled the same follow-up, which is recorded for the release step and not done here (Global Constraint 8 keeps `docs/orchestration-issues.md` out of this plan): file a worklist row for the receiver-side asymmetry, to be acted on when a preambled reviewer or research report is actually recorded.

## Ruling 4 — 2026-09-07 — phase 4 — [I2] The lost-return rule's marker test is unbounded

- **Class:** forced
- **Item:** [I2 inv 2] Important skills/orchestrating-development/SKILL.md:1449 — the lost-return rule tests every line of a fork's final message with an unbounded prefix match, so a failure notice that merely quotes the reviewer marker counts as a usable return toward the two-usable-returns threshold and no re-dispatch fires; the unbounded form also breaks the plan's own hook-exempt-superset invariant. Raised by both reviewers in round 1, round 2, verification 2 and verification 3 of invocation 2.
- **Contract clause:** "The lost-return **rule** of `## In-run rulings` a fork return whose completion notice arrives without the marker line is lost, re-dispatched once, and a second " — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Task 3 Does NOT cover
- **Defensible answers:** n/a
- **Forks:** none
- **Resolution:** amend plan: Task 3's Does-NOT-cover entry now says the lost-return rule's marker test is bounded to the same first 10 non-blank lines; fix it: bound it in the `**Lost returns.**` and reviewer-return sentences of `skills/orchestrating-development/SKILL.md` — the forced fact: the plan claimed the rule was "not touched", and the rewrite falsified that claim by turning an opens-with test into an every-line prefix test, so this bounds a regression the branch itself introduced rather than adding scope; while it stands, a fork that failed and quotes its own return contract counts as usable and a design ruling can be made with no verdict behind it. Not done here, and recorded for the release step: no `ITEM:`/`VERDICT:` presence test exists either — that gap predates this branch.

## Ruling 5 — 2026-09-07 — phase 4 — [I1] A consumed field appearing twice inside the report block has no tie-break

- **Class:** forced
- **Item:** [I1 inv 2] Important skills/orchestrating-development/SKILL.md:169 — with preamble tolerated, a controller that quotes an earlier return above its own has the QUOTED block parsed, and a consumed field appearing twice inside the 15-line block has no stated tie-break. Raised in round 2 of invocation 2; the marker-selection half was rejected as decided wording by verification cycles 1 and 2 of the same invocation.
- **Contract clause:** "With more than one such line, the first begins the report; everything above it is ignored." — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Global Constraint 3, which carries `(amended by ruling 1)`
- **Defensible answers:** n/a
- **Forks:** none
- **Resolution:** amend plan: Global Constraint 4 now says the first occurrence of a consumed field inside the report block is its value; fix it: state that tie-break in the Return contract of `skills/orchestrating-development/SKILL.md` — the forced fact: constraint 3 already resolves a duplicate marker line by taking the first, so any other tie-break for a duplicate field would make one message parse two ways. The marker-selection half of this finding is not reopened: ruling 1 decided it after a three-lens fork round, the clause carries `(amended by ruling 1)`, and the two verification cycles of this invocation already rejected it on that ground.

## Ruling 6 — 2026-09-07 — phase 4 — [I2] The Guard Interaction sentence states a false necessary condition

- **Class:** forced
- **Item:** [I2 inv 2] Important skills/orchestrating-development/SKILL.md:2280 — the `## Guard Interaction` sentence this loop wrote says an unmarked message is blocked only when it pairs an action verb with a skill name, while `hooks/subagent-guard.js` also blocks four verb-free patterns (`Skill(superpowers…`, `skill: <name>`, `I'm using the … skill`, `Invoke the superpowers-…`), so an orchestrator would rule the guard out as the cause of a repeated controller turn; the `**Lost returns.**` sentence carries the same inaccuracy in the opposite direction. Reached the third verification cycle, the last available, and was logged `unresolved: verification cap`.
- **Contract clause:** none
- **Defensible answers:** n/a
- **Forks:** none
- **Resolution:** fix it: state the condition correctly in both sentences — the guard blocks an unmarked message when it matches any of the hook's violation patterns, four of which need no action verb. The forced fact: the claim was verified false against `hooks/subagent-guard.js` by two reviewers and again by the orchestrator reading the pattern list, and a document that describes a hook wrongly is the failure this whole branch exists to remove.

## Ruling 7 — 2026-09-07 — phase 4 — [I1] The fork return has no reading rules

- **Class:** forced
- **Item:** [I1 inv 3] Important skills/orchestrating-development/SKILL.md:1468 — the widened fork lost-return rule states no bound on where a fork's `ITEM:`/`VERDICT:`/`REASON:`/`CONTRADICTS:`/`TABLED:` lines are read and no rule about text above the marker, so a preamble `VERDICT:` and the report's own give two orchestrators two answers. The same question rulings 1, 2 and 5 answered for the controller side. Raised in verification cycle 3 of invocation 3.
- **Contract clause:** "With more than one such line, the first begins the report; everything above it is ignored." — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Global Constraint 3
- **Defensible answers:** n/a
- **Forks:** none
- **Resolution:** amend plan: Global Constraint 3 now applies its three reading rules to a fork's reviewer return as well, with the fork's own 25-line cap; fix it: state them in the `## In-run rulings` fork-return text of `skills/orchestrating-development/SKILL.md` — the forced fact: the branch widened where a fork's marker may stand, which is what makes text above it possible at all, and three rulings of this same run already fixed the identical questions on the controller side; any answer other than the same one would make one message parse two ways depending on which side reads it.

## Ruling 8 — 2026-09-07 — phase 4 — [I2] A quoted bare marker line disables the guard for a whole message

- **Class:** forced
- **Item:** [I2 inv 3] Important hooks/subagent-guard.js:109-117 — 16 files under `skills/` and `docs/` carry a bare marker line, so an implementer quoting a template it edited disables the leakage guard for its whole message; the reviewer's proposed narrowing contradicts Global Constraint 2, and its comment-only alternative had no verification cycle left. Raised in verification cycle 3 of invocation 3.
- **Contract clause:** "A leaking subagent that emits an exact marker at the start of one of its first 10 non-blank lines is exempt; that was already true at line 1 and the prompt instruction remains the first layer of defence." — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Task 1 Does NOT cover
- **Defensible answers:** n/a
- **Forks:** none
- **Resolution:** plan governs: "A leaking subagent that emits an exact marker at the start of one of its first 10 non-blank lines is exempt; that was already true at line 1 and the prompt instruction remains the first layer of defence." — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md — the plan accepted this residual by name before the work began, and the spec's Failure-mode check accepted it too; the reviewer's narrowing contradicts Global Constraints 2 and 5, which forbid the hook gaining a second condition and require its exemption only ever to widen. The reviewer's own second alternative — record the accepted residual in the `hasReportMarker` comment — changes no behaviour and is recorded for the release step rather than dispatched here, because this is the last in-run resume the cap allows and a comment carries no verification risk worth spending it on. What is new in this finding is the scale (16 files carry a bare marker line), not the risk; the scale is recorded here so the release-step note can cite it.

## Ruling 9 — 2026-09-07 — phase 4 — [I2] The Return contract states the 15-line cap two incompatible ways

- **Class:** escalated (chain)
- **Item:** [I2 inv 4] Important skills/orchestrating-development/SKILL.md:195 — the same bullet says "The 15-line cap counts from the marker line, which is line 1 of the 15" and, four lines later, "the templates state that cap over the whole final message, whatever number of lines preceded the marker". The four templates say `## Return (final message, 15 lines max)`, so the second is true and the first misdescribes the instruction it attributes to the controller. Raised in round 1 of invocation 4.
- **Contract clause:** "**The 15-line cap counts from the marker line, which is line 1 of the 15, and exceeding it is not a malformed condition.**" — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Global Constraint 4
- **Defensible answers:** (a) restate the cap sentence as the templates state it, amending Global Constraint 4's verbatim wording; (b) leave the constraint and change only the skill sentence that misdescribes it.
- **Forks:** none — the cap was reached before this return, so no ruling was made
- **Resolution:** escalated — the fourth open return of Phase 4 reached the in-run resume cap of 3, so every open item of this return is `escalated (chain)` whatever its own class would have been. This one would otherwise have been a design item: it amends the verbatim wording of a Global Constraint the user's own spec fixed.

## Ruling 10 — 2026-09-07 — phase 4 — [I4] The leading-token search is unbounded while consumed fields are bounded

- **Class:** escalated (chain)
- **Item:** [I4 inv 4] Important skills/orchestrating-development/SKILL.md:187 — the leading token is located by an unbounded search ("the first non-blank line below that marker line"), so a `BLOCKED` token standing 20 blank lines below the marker, outside the marker line plus 14 lines, is read as the return's token and stops the run. Ruling 2 closed exactly this hole for consumed fields; the token, which selects the phase outcome, was left unbounded. Raised in round 1 of invocation 4.
- **Contract clause:** "Must convey, all of: the templates still tell the controller to put the mar…" — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Task 2 Contract
- **Defensible answers:** (a) bound the token search to the marker line and the 14 lines below it, amending the Task 2 Contract's Must-convey wording; (b) leave it unbounded because a 20-blank-line gap has never been observed.
- **Forks:** none — the cap was reached before this return, so no ruling was made
- **Resolution:** escalated — `chain`, as above. On the merits it is the same hole ruling 2 closed for consumed fields, one step further; a resumed run should expect answer (a).

## Ruling 11 — 2026-09-07 — phase 4 — [I1] The receiver-side usability test, raised a third time and now reproduced

- **Class:** escalated (chain)
- **Item:** [I1 inv 4] Important — the hook exemption is widened to the first 10 non-blank lines while `multi-code-review` and `multi-doc-review` keep their usability test at "first line is the marker", so the exact message shape the branch newly lets through is discarded downstream, and the guard block that previously sent the reviewer back is gone. Both reviewers reproduced it against the two predicates (the new guard returns `{}` where the pre-change one returned `decision: block`), and both note that the plan's Goal line names a reviewer report as well. Raised in round 2 of invocation 4; the same question was ruled `plan governs` as ruling 3 of invocation 1.
- **Contract clause:** "The skill-side usability rules of the other two markers are untouched: `skills/multi-code-review/SKILL.md:602`, `skills/multi-doc-review/SKILL.md:114`," — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md, Task 4
- **Defensible answers:** (a) widen the usability test in both skills to the same 10-non-blank-line window; (b) state in both Guard Interaction sections that the retry is now the only repair; (c) keep the plan as written, as ruling 3 decided.
- **Forks:** none — the cap was reached before this return, so no ruling was made
- **Resolution:** escalated — `chain`, as above. It is also the one item of this run that a ruling should no longer decide alone: three lenses chose (c) at invocation 1 on the argument that a block never repaired a preambled report, and reviewers have raised it again in every invocation since, now with a reproduction and with the plan's own Goal line as evidence against (c). The author should decide it.
