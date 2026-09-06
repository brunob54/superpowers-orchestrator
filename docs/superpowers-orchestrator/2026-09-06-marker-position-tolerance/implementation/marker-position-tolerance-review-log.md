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
