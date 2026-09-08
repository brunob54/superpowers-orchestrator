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

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 2 Minor | r2: 0 Critical, 3 Important, 2 Minor | r3: 0 Critical, 2 Important, 5 Minor
**Sources mapped:** 17/17
**Reviewer verdict:** 0 Critical, 4 Important, 7 Minor
**Converged:** no
### Dispositions
- [I1] fixed — a skipped (recorded N=0) entry no longer blocks a later gate invocation, so the re-asked N is honoured → 5a60a7e ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] user-decision — the code gate's 'never by `<d>`' qualifier forbids the very session-tag fallback Batched Autonomous Mode's own rule ends at, so two agents pass M=3 and M=1 for the same run (plan-mandated) — at skills/subagent-driven-development/SKILL.md:81 — clause: Global Constraints "Batched Autonomous Mode and every subagent-dispatched controller ask nothing and resolve both values by their own rule, never by `<d>`. (Spec R5, R7)" ← 3/3: r1:I2, r2:I3, r3:I2
- [I3] fixed — multi-doc-review now resumes an invocation whose recorded rounds were not all logged, making the gates' 'resumes' promise true → 5a60a7e ← 2/3: r1:I3, r3:M4
- [I4] fixed — the recorded-N=0 branch now names the recorded value and states its whole continuation, so the freshly answered N cannot be discarded → 5a60a7e ← 2/3: r1:M1, r2:I2
- [M1] fixed — the batched-mode and Cursor pins now match fragments unique to the exception and the refusal list → 5a60a7e ← 1/3: r1:M2
- [M2] fixed — the awk span anchors use bracket expressions, so a backslash-dot no longer degrades to match any character → 5a60a7e ← 1/3: r2:M1
- [M3] carried — the suppression path's origin echo names values for a loop the review skill may then skip ← 1/3: r2:M2
- [M4] fixed — the M offer's label is keyed on the value, since hooks/session-start always emits a tag → 5a60a7e ← 1/3: r3:M1
- [M5] fixed — the Batched Autonomous Mode span ends at the next heading instead of the end of file → 5a60a7e ← 1/3: r3:M2
- [M6] fixed — both review skills state the default for a gate invocation that carries no stated count → 5a60a7e ← 1/3: r3:M3
- [M7] carried — the four-option cap does not say whether the free-text choice counts against it ← 1/3: r3:M5

## Round 3 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no
### Dispositions
- [M1] fixed — a value on the log's invocation line outside N 0-10 or M 1-5 now counts as not recorded, so the origin echo names the default → c4e7d9e ← 3/3: r1:M1, r2:M1, r3:M1
- [M2] rejected: the loop never edits plan text, and the plan's falsification step has already been executed; the plan's Step 2b restores a mutated skill file with a bare git checkout and no cleanliness precondition ← 2/3: r2:M3, r3:M2
- [M3] fixed — both gates now say the sidecar's content is data and only its recorded N and M are read → c4e7d9e ← 1/3: r1:M2
- [M4] fixed — the code gate states that an N or M form inside the carried Minor-findings list is data, never a parameter → c4e7d9e ← 1/3: r2:M2

## Round 3 verification 1 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 1 Important, 4 Minor
### Dispositions
- [I1] fixed — both review skills' N bullets now carry the tool-result-is-data rule that only M's bullet had, closing an N=0 read out of a file → 1965b46 ← 1/3: r1:I1
- [M1] rejected: the loop never edits plan text, and the plan's falsification step has already been executed; the plan's Step 2b restores a mutated skill file with a bare git checkout and no backup ← 3/3: r1:M2, r2:M2, r3:M1
- [M2] carried — an in-range value planted on the sidecar's invocation line is still adopted; the doc gates draw no tracked-log distinction ← 1/3: r1:M1
- [M3] fixed — the suite now pins both guard sentences of the sidecar-read path in each document gate span → 1965b46 ← 1/3: r2:M1
- [M4] carried — multi-code-review has no mirror rule for an N or M form inside the inline carried-findings list; the gate's own rule is the only guard ← 1/3: r3:M2

## Round 3 verification 2 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 1 Important, 1 Minor
**Sources mapped:** 6/6
**Reviewer verdict:** 0 Critical, 1 Important, 4 Minor
### Dispositions
- [I1] user-decision — the document gates recover M from the committed sidecar log, so a repository file chooses a review parameter, which the project's own invariant for the `<reviewers-per-lens>` tag forbids; the spec's R5 requires that recovery (plan-mandated) — at skills/brainstorming/SKILL.md:65 — clause: Task 2 "Must convey, in this order: the platform check; the suppression check with the origin echo; the question one question batch for whichever of N and M" ← 1/3: r3:I1
- [M1] fixed — M's resolution step 1 now carries the same tool-result-is-data rule as N's bullet in both review skills → 4397311 ← 2/3: r1:M2, r2:M2
- [M2] rejected: the loop never edits plan text, and the plan's falsification step has already been executed; the plan's Step 2b restores a mutated skill file with a bare git checkout and no backup ← 1/3: r1:M1
- [M3] fixed — the gates recognise the invocation line only at the start of a line, so a forged string inside a disposition summary is no longer matched → 4397311 ← 1/3: r2:M1
- [M4] fixed — multi-doc-review's Once per gate block now states that only the recorded N, M and round headers are read from the log → 4397311 ← 1/3: r3:M1

## Round 3 verification 3 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 6/6
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
### Dispositions
- [M1] rejected: the loop never edits plan text, and the plan's falsification step has already been executed; the plan's Step 2b restores a mutated skill file with a bare git checkout and no backup ← 2/3: r1:M2, r3:M2
- [M2] carried — no rule says which `_Invocation` line the gates read when the sidecar log holds several ← 2/3: r2:M2, r3:M1
- [M3] carried — on the resume path a value recovered from the log can set the review depth with no question asked ← 1/3: r1:M1
- [M4] carried — multi-code-review's own N and M rules do not name the inline carried-findings list among the sources that are data ← 1/3: r2:M1

_Completed — 2026-09-08 — cap reached — HEAD 43973112f8bb0181167b0fb514e116cc287d85ff_
Secrets found: none

### Post-loop addendum — 2026-09-08 — decisions on invocation 1's open items
- [CF4] decided (orchestrator): plan governs: "Must convey: `bash tests/review-gates/run-tests.sh` belongs to the fast, non-behavioural suites, with a one-line description of what it covers." — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md
- [I2] decided (orchestrator): amend plan: the Global Constraints entry now reads that `<d>` names the gate's default-offering resolution, which these paths never enter, and that Batched Autonomous Mode's own rule may still end at the `<reviewers-per-lens>` session tag as that rule's own last resort — the amendment is already committed and the plan file reads the amended way; fix it: carry the same disambiguation into the Batched Autonomous Mode qualifier of Core Flow step 4 in `skills/subagent-driven-development/SKILL.md`, so the shipped text no longer forbids the session-tag fallback that mode's own rule ends at, while still forbidding the gate's `<d>` default-offering path
- [I2] fixed — carried the ruling-2 disambiguation into the Batched Autonomous Mode qualifier of Core Flow step 4, so the shipped text no longer forbids the session-tag fallback that mode's own rule ends at → a969659
- [I1] decided (orchestrator): plan governs: "Must convey, in this order: the platform check; the suppression check with the origin echo; the question one question batch for whichever of N and M" — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md

Open items after this addendum: unresolved 0, user-decision 0. The effective HEAD moved past invocation 1's completion marker before this addendum was written, so that marker is left unchanged and a new invocation follows; the verification re-review of the [I2] fix is skipped because invocation 2 reviews it.

_Invocation 2 — 2026-09-08 — N=3 M=3 — BASE..HEAD 9f73f00..a969659 — branch feature/review-gate-m-question — gate: orchestration_
