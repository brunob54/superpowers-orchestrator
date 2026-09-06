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
