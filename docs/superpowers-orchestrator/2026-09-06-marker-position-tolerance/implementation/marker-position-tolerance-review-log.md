# Marker Position Tolerance — code review log

_Invocation 1 — 2026-09-06 — N=2 M=2 — BASE..HEAD f112faa..c41d44c — branch feature/marker-position-tolerance — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no
### Dispositions
- [M1] fixed — the two rewritten `## Guard Interaction` bodies (multi-doc-review, multi-code-review) said a report with a sentence above its marker is still exempt, without saying the widened rule governs hook blocking only while report usability still needs the marker on the first line; a qualifying clause was added to both → a79242e ← 2/2: r1:M1, r2:M1
- [M2] carried — the 15-line return cap now has no receiver-side effect and an over-long controller return is accepted with no trace; reviewer proposes the orchestrator log a one-line observation. Not fixed: the plan mandates the acceptance behaviour (Global Constraint 4) and a new logging behaviour is beyond this branch's scope ← 1/2: r1:M2
- [M3] fixed — the `MARKER_SEARCH_LINES` comment justified the bounded window with a case the prefix-match predicate already excludes (a marker quoted inside a finding line); reworded to name the real over-exemption case, a marker at the start of a line further down → a79242e ← 1/2: r2:M2
- [M4] carried — `tests/orchestrating-development/run-tests.sh:289` asserts the 10-non-blank-line phrase over the whole `## In-run rulings` range rather than the `**Lost returns.**` paragraph, so the pin is weaker than its label. Not fixed: the assertion's range is plan-mandated (Task 3, Contract item 3) ← 1/2: r2:M3
- [CF1] carried — task-1 report's RED list names 11 failures where the plan's Step 2 predicts 12; both reviewers recommend ship-as-is, the plan's own Contract note explains the difference and nothing depends on the count
- [CF2] carried — `tests/codex/test-subagent-guard.js:465,:474`, the two blank-line cases pass against the unmodified hook; both reviewers recommend ship-as-is, they are regression guards for "blanks do not consume the window"
- [CF3] carried — `tests/codex/test-subagent-guard.js:439-442`, the whole-file negative wording assertion; both reviewers recommend ship-as-is, it is the plan-mandated form and cannot produce a false pass
- [CF4] carried — residual exposure: a marker at the start of a line inside the first 10 non-blank lines escapes leakage detection; both reviewers recommend ship-as-is, the bounded window is the documented, deliberate mitigation
- [CF5] fixed — the colloquial clause "and keep saying so" in the Return contract bullet replaced with "and that instruction does not change"; both reviewers recommended fix-before-merge → a79242e
- [CF6] fixed — the long measurement sentence in `skills/orchestrating-development/SKILL.md` `## Guard Interaction` split into short literal sentences; one reviewer recommended fix-before-merge, the other ship-as-is, so the corroborated caution rule selects fix-before-merge → a79242e
- [CF7] carried — the six rewritten passages copy the plan's reference wording nearly verbatim; both reviewers recommend ship-as-is, the plan's Body-authority note permits it

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 2 Minor | r2: 0 Critical, 2 Important, 3 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the `**Lost returns.**` passage stated the hook's 10-non-blank-line window but its loss test still read "arrives without the marker line" with no position rule, so two orchestrators could accept or lose the same fork return; the loss sentence now names the window explicitly → 33d38b0 ← 2/2: r1:I1, r2:I1
- [I2] user-decision — taking the FIRST qualifying marker line in the window as the report start silently ignores everything above it, so a controller that quotes a marker line or corrects a draft return has its wrong block parsed; both reviewers propose taking the last qualifying line or requiring a recognised leading token (plan-mandated) — at skills/orchestrating-development/SKILL.md:170 — clause: Global Constraints "With more than one such line, the first begins the report; everything above it is ignored." ← 2/2: r1:I2, r2:I2
- [M1] fixed — the `MARKER_SEARCH_LINES` comment read as if the bounded window closed the indented or fenced quotation case, while such a quotation inside the window still exempts; the comment now records that accepted residual → 33d38b0 ← 2/2: r1:M1, r2:M1
- [M2] carried — the two negative wording assertions ban the bare phrases `opens with` and `hang the dispatch` over whole files, so an unrelated future comment fails the suite with a message pointing at the wrong sentence. Not fixed: the `tests/codex/test-subagent-guard.js` form is plan-mandated (Task 1, Contract item 3) ← 1/2: r1:M2
- [M3] carried — the 15-line return cap now has no receiver-side effect, so an oversized controller return enters the orchestrator context with no trace; reviewer proposes recording the return's line count in the orchestration log. Not fixed: the acceptance behaviour is plan-mandated (Global Constraint 4) and the new logging is beyond this branch ← 1/2: r2:M2
- [M4] carried — the "Measured on 2026-09-06" sentence in `## Guard Interaction` carries no pointer to where the measurement is recorded and does not name the dispatch shape measured. Not fixed: the probe run, its method and its observation are recorded in this run's own spec at `docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/specs/marker-position-tolerance-design.md:67-79`, and a citation of a repository-local topic folder inside a shipped skill file would not resolve in any other installation (harness field dropped: repository-readable) ← 1/2: r2:M3

## Round 2 verification 1 — Adversarial red-team — opus
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 3 Minor | r2: 0 Critical, 1 Important, 3 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 2 Important, 6 Minor
### Dispositions
- [I1] user-decision — taking the FIRST qualifying marker line in the window as the report start makes a superseded draft block authoritative and removes the retry that used to catch it; both reviewers propose taking the last qualifying line or declaring a second marker line malformed. Same open item as round 2 [I2] (plan-mandated) — at skills/orchestrating-development/SKILL.md:170 — clause: Global Constraints "With more than one such line, the first begins the report; everything above it is ignored." ← 2/2: r1:I1, r2:I1
- [I2] user-decision — with the 15-line cap no longer a malformed condition, no rule bounds WHERE in the return a consumed field is read, so an appendix line holding `unresolved=2` below a `unresolved=0` token block can flip a stop rule; reviewer proposes reading consumed fields only from the marker line and the 14 lines below it (plan-mandated) — at skills/orchestrating-development/SKILL.md:176 — clause: Global Constraints "The malformed list stays closed: no marker line in the window, no leading token, or a consumed field (`tasks=`, per-task numbers, `rounds=`, `outcome=`," ← 1/2: r1:I2
- [M1] carried — the branch leaves three marker predicates (prefix over a window, whole-line equality over a window, first-line exact) and an agent may carry the wrong one across passages; reviewer proposes naming the predicate once and referencing it. Not fixed: a cross-skill refactor is beyond this branch ← 1/2: r1:M1
- [M2] carried — the "Measured on 2026-09-06" sentence cites no artifact and the negative wording pin now makes restoring the stronger claim a test failure. Not fixed: the probe run is recorded in this run's own spec at `docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/specs/marker-position-tolerance-design.md:67-79`, and a repository-local citation inside a shipped skill file would not resolve in another installation (harness field dropped: repository-readable) ← 1/2: r1:M2
- [M3] carried — the hook exemption widens for all three markers while only the orchestrator's controller-return acceptance widens with it, so on the two review paths the widening only enlarges the leakage surface; reviewer proposes widening the usability rules or narrowing the hook per marker. Not fixed: the plan's Task 4 "Does NOT cover" excludes the receiver-side reviewer rules and Global Constraint 5 forbids the hook a second condition ← 1/2: r1:M3
- [M4] fixed — the loss sentence written in round 2 counted its window in the completion notice while the Return contract bullet and the hook count it in the final message; the sentence now names the reviewer's final message → 6dd6ae6 ← 1/2: r2:M1
- [M5] fixed — `skills/researching-prior-art/SKILL.md` `## Guard interaction` stated the widened rule without the usability caveat its two sibling sections gained in round 1, while the research controller still discards a report whose marker is not its first line; the caveat was added → 6dd6ae6 ← 1/2: r2:M2
- [M6] carried — the two negative wording pins forbid the bare phrases `opens with` and `hang the dispatch` over whole files, so an unrelated future sentence fails a test whose name points elsewhere. Not fixed: the `tests/codex/test-subagent-guard.js` form is plan-mandated (Task 1, Contract item 3) ← 1/2: r2:M3

## Round 2 verification 2 — Adversarial red-team — opus
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 1 Important, 3 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
### Dispositions
- [I1] fixed — the loss sentence rewritten in round 2 and verification 1 had attached a 10-non-blank-line window to the lost-return rule, which the plan keeps keyed on the marker's presence (Task 3 "Does NOT cover"), and the window made acceptance narrower than before the branch; the sentence now keys on presence with no window and names its prefix test explicitly → e86c93d ← 1/2: r1:I1
- [I2] user-decision — the hook exemption widened for all three markers while only the orchestrator's controller-return contract widened with it, so a preambled reviewer or research report now passes the hook and is then discarded or re-dispatched by its receiver, which costs more than the block it replaced; reviewer proposes widening the three receiver-side usability rules to the same window, or narrowing the hook to the orchestration marker alone (plan-mandated) — at skills/multi-code-review/SKILL.md:602 — clause: Task 4 "The skill-side usability rules of the other two markers are untouched: `skills/multi-code-review/SKILL.md:602`, `skills/multi-doc-review/SKILL.md:114`," ← 1/2: r2:I1
- [M1] carried — taking the FIRST qualifying marker line makes a controller's self-correction unreachable; this is the same open item already logged `user-decision` as round 2 [I2] and verification 1 [I1], and it is Minor here, so it carries rather than opening a second item ← 2/2: r1:M1, r2:M1
- [M2] fixed — the window qualifier in the loss sentence dangled behind a long subject, so two agents could attach it differently; the same rewrite that fixed [I1] removed the qualifier and stated the test unambiguously → e86c93d ← 2/2: r1:M2, r2:M2
- [M3] rejected: contradicts binding plan text — Global Constraint 5 "**The hook gains no second condition.** It never checks for a leading token, and its exemption only ever widens." — reviewer proposes tracking code-fence toggles in the window scan so a marker quoted inside a fence stops exempting; that is a second condition and it narrows the exemption ← 1/2: r2:M3

_Note — verification cycle 3 was dispatched over e86c93d and interrupted before any reviewer returned a report, so no entry is written for it (Error Handling: a failure before any reviewer report of the round owes no round entry). The fix commit e86c93d therefore ships without a later review round over it._

_Completed — 2026-09-07 — cap reached — HEAD e86c93dfc1a4d49f6d7b0c35f8172d98453947c6_
Secrets found: none

## Post-loop addendum — decisions — 2026-09-07
### Dispositions
- [I2] (round 2) decided (orchestrator): amend plan: Global Constraint 3 keeps the first-match rule and now also requires the orchestrator to record `note: return carried <n> marker lines; parsed from the first` in the orchestration log when the window holds more than one marker line — the amendment is committed and the plan already reads that way; fix it: state that note requirement in the Return contract of skills/orchestrating-development/SKILL.md, beside the first-match sentence, and leave the parse rule itself unchanged.
- [I2] (round 2) fixed — the Return contract bullet now records `note: return carried <n> marker lines; parsed from the first` in the orchestration log when the window holds more than one marker line, so the ignored block leaves a trace; the first-match parse rule is unchanged → 08c6c28
- [I1] (verification 1) decided (orchestrator): amend plan: as on the round 2 line above, Global Constraint 3 keeps first-match and gains the log note; fix it: the same single edit to the Return contract of skills/orchestrating-development/SKILL.md — one fix settles both ids, do not make it twice.
- [I1] (verification 1) fixed — same item as round 2 [I2]; settled by the single Return contract edit made for it, dispatched once → 08c6c28
- [I2] (verification 1) decided (orchestrator): amend plan: Global Constraint 4 now says every consumed field is read only from the marker line and the 14 lines below it, and a value standing below that block is never read — the amendment is committed; fix it: state that bound in the Return contract of skills/orchestrating-development/SKILL.md, next to the sentence saying the cap is not a malformed condition.
- [I2] (verification 1) fixed — the Return contract bullet now bounds every consumed field to the marker line and the 14 lines below it, and states that a value below that block is never read; the 15-line cap stays a non-malformed condition → 08c6c28
- [I2] (verification 2) decided (orchestrator): plan governs: "The skill-side usability rules of the other two markers are untouched: `skills/multi-code-review/SKILL.md:602`, `skills/multi-doc-review/SKILL.md:114`," — docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/plans/marker-position-tolerance.md
- [M1] (verification 2) carried — unchanged; it was already the Minor form of round 2 [I2], which this addendum decides and fixes

_Addendum note — the effective HEAD had moved past this entry's completion marker (e7a4ff8, the plan amendment) before the addendum was written, so the completion marker above is left unchanged, the verification re-review of the fix is skipped, and invocation 2 below reviews it._

_Invocation 2 — 2026-09-07 — N=2 M=2 — BASE..HEAD f112faa..08c6c28 — branch feature/marker-position-tolerance — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 2 Minor | r2: 0 Critical, 1 Important, 3 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the Return contract now orders the note `note: return carried <n> marker lines; parsed from the first`, but `## Orchestration Log Format` listed no such line and the bullet named no entry to attach it to, so the trace had no defined home; the line was added to the log-format block and the bullet now names the phase or batch entry it is appended under → ae59204 ← 2/2: r1:I1, r2:M1
- [I2] user-decision — the rewritten lost-return rule tests every line of a fork's final message with an unbounded prefix match, while both other sides of the change use the first 10 non-blank lines, so a message that merely quotes the reviewer marker at the start of any line counts as a usable return toward the two-usable-returns threshold; both reviewers propose bounding it to the same window, which the plan says is not touched (plan-mandated) — at skills/orchestrating-development/SKILL.md:1432 — clause: Task 3 "The lost-return **rule** of `## In-run rulings` a fork return whose completion notice arrives without the marker line is lost, re-dispatched once, and a second " ← 2/2: r1:I2, r2:I1
- [M1] carried — the "Measured on 2026-09-06" sentence in `## Guard Interaction` names no record of the measurement and no re-test condition. Not fixed: the probe run, its method and its observation are recorded in this run's own spec at `docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/specs/marker-position-tolerance-design.md:67-79`, and a citation of a repository-local topic folder inside a shipped skill file would not resolve in any other installation (harness field dropped: repository-readable) ← 2/2: r1:M2, r2:M2
- [M2] fixed — `## Guard Interaction` said an unmarked return is answered with `decision: block` without the condition that the message also names a plugin skill, so it contradicted the `**Lost returns.**` paragraph of the same file; the condition was added → ae59204 ← 1/2: r1:M1
- [M3] carried — the plan's Goal sentence says a reviewer report is accepted within the window, while Task 4 leaves the two reviewer-side usability rules on the first line, so the Goal overstates the reviewer side. Not fixed: the reviewer states no code change is needed and the branch follows Task 4; the mismatch is inside the plan's own text ← 1/2: r2:M3
- [CF1] carried — task-1 report's RED list names 11 failures where the plan's Step 2 predicts 12; both reviewers recommend ship-as-is, the plan's Contract note explains the difference and the report is a completed-step artifact
- [CF2] carried — `tests/codex/test-subagent-guard.js:465,:474`, the two blank-line cases pass against the unmodified hook; both reviewers recommend ship-as-is, the CRLF sibling carries the discriminating comment
- [CF3] carried — `tests/codex/test-subagent-guard.js:439-442`, the whole-file negative wording assertion; both reviewers recommend ship-as-is, it is the plan-mandated form and a self-pin the same task owns
- [CF4] carried — residual exposure: a marker quoted at the start of a line inside the first 10 non-blank lines escapes leakage detection; both reviewers recommend ship-as-is, the bounded window is the documented mitigation. Both add that the unbounded form of the same exposure on the fork path is [I2] above
- [CF5] carried — the colloquial clause "and keep saying so"; both reviewers recommend ship-as-is, it was already fixed in invocation 1
- [CF6] carried — the long measurement sentence in `## Guard Interaction`; both reviewers recommend ship-as-is, it was already split in invocation 1; its precision problem is [M1] above
- [CF7] carried — the six rewritten passages copy the plan's reference wording nearly verbatim; both reviewers recommend ship-as-is, the plan's Body-authority note permits it
