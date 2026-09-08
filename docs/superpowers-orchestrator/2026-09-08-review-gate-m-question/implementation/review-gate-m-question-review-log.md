# Review Gate M Question — Code Review Log

_Invocation 1 — 2026-09-08 — N=3 M=3 — BASE..HEAD 9f73f00..ab06ac1 — branch feature/review-gate-m-question — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 4 Minor | r2: 0 Critical, 2 Important, 3 Minor | r3: 0 Critical, 3 Important, 4 Minor
**Sources mapped:** 18/18
**Reviewer verdict:** 0 Critical, 5 Important, 7 Minor
**Converged:** no
### Dispositions
- [I1] fixed — escaped the pipe inside the two command-table cells of docs/guide/README.md, which GFM was splitting into a fourth cell → 7067322 ← 2/3: r1:I1, r2:I1
- [I2] fixed — qualified the code gate's non-asking origin echo so a Batched Autonomous Mode run no longer claims the user stated the values → 7067322 ← 2/3: r2:I2, r3:I2
- [I3] fixed — a recorded N=0 is no longer inherited by the document gates' suppression path → 7067322 ← 2/3: r2:M2, r3:I3
- [I4] fixed — moved multi-doc-review's Once per gate guard to the top of its Procedure, ahead of the log-append instruction → 7067322 ← 1/3: r1:I2
- [I5] fixed — the suppression path's origin echo is now per value, covering a log that records N but not M → 7067322 ← 1/3: r3:I1
- [M1] fixed — dropped the duplicated coordinating 'and' in README.md's release list → 7067322 ← 3/3: r1:M1, r2:M1, r3:M2
- [M2] fixed — reworded the false 'the gate asked for whichever value' reason in both review skills → 7067322 ← 2/3: r1:M2, r3:M1
- [M3] fixed — docs/guide/README.md now states one default for M → 7067322 ← 1/3: r1:M3
- [M4] carried — tests/review-gates/run-tests.sh asserts no order between the platform check and the suppression check ← 1/3: r1:M4
- [M5] rejected: out of scope, Task 6's Contract excludes docs/REVIEW-PROCESS-COMPARISON.md as a dated snapshot — stale command form in that file ← 1/3: r2:M3
- [M6] fixed — README.md:32 no longer mixes plural and singular for the gates → 7067322 ← 1/3: r3:M3
- [M7] carried — the document gates' origin echo names values for a loop the review skill may then skip ← 1/3: r3:M4
- [CF1] carried — the '(in every mode)' assertion pins an isolated substring (ship-as-is, 3 of 3 reviewers)
- [CF2] carried — path variables and helpers unused until later tasks (ship-as-is, 3 of 3 reviewers; no longer true on the final tree)
- [CF3] carried — D_MARKER and D_TAIL unused until Task 5 (ship-as-is, 3 of 3 reviewers; both are read by the shipped anti-drift block)
- [CF4] user-decision — CLAUDE.md is git-ignored in this repository, so Task 5's Testing-section line never ships with the branch (plan-mandated) — at CLAUDE.md:17 — clause: Task 5 "Must convey: `bash tests/review-gates/run-tests.sh` belongs to the fast, non-behavioural suites, with a one-line description of what it covers."
- [CF5] fixed — removed the third 'that gate' from docs/guide/README.md's plan-gate paragraph → 7067322
- [CF6] carried — docs/FORK-IMPROVEMENTS.md states the single-pass fallback twice (ship-as-is, 3 of 3 reviewers)
