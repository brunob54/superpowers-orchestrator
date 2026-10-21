# Review log — upstream-v7-fixes

_Invocation 1 — 2026-10-21 — N=3 M=3 — BASE..HEAD 093d71a..1349908 — branch feature/upstream-v7-fixes — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no
### Dispositions
- [M1] fixed — batch-controller start check named the two causes for every non-zero exit of merge-base --is-ancestor; now exit 1 only, any other exit is a git error → 5113be87 ← 1/3: r1:M1
- [M2] fixed — review-package header and v7.74.0 release note did not name the exit-2 "cannot compare BASE and HEAD" case → 5113be87 ← 1/3: r2:M1
- [M3] carried — start-check BLOCKED return can meet a stale task-<n>-report.md with an unanswered Question/Conflict section from an abandoned run, so the return enters the rulings predicate instead of the failure path ← 1/3: r3:M1
- [M4] fixed — guide section 4 did not say that with no completed ledger line the retry runs the task again → 5113be87 ← 1/3: r3:M2
- [carried task 1 a] carried — create-only .gitignore section: rm -rf cleanup only at section end (3/3 ship-as-is)
- [carried task 1 b] carried — absent and empty cmp checks repeat the same if/else block (3/3 ship-as-is)
- [carried task 2 a] fixed — review-package resolve_commit wrote the "bad $1: $2" / return 2 handler twice; merged into one condition (3/3 fix-before-merge) → 5113be87
- [carried task 2 b] carried — new exit-2 line "cannot compare BASE and HEAD" outside the fixed wordings (3/3 ship-as-is; documentation side fixed as M2)
- [carried task 2 c] carried — security M1: raw BASE/HEAD names re-resolved in later git commands (3/3 ship-as-is)
- [carried task 2 d] carried — security M2: a :/text argument gets ^{commit} appended (3/3 ship-as-is)
- [carried task 2 e] carried — security M3: range-guard test section has no EXIT trap and no leading "-" case (3/3 ship-as-is)
- [carried task 3 a] carried — release-note bullet must name ${IDENTITY:+x}: already done in RELEASE-NOTES.md (3/3 ship-as-is)
- [carried task 3 b] carried — IDENTITY hook-probe rows discriminate nothing (3/3 ship-as-is)
- [carried task 3 c] carried — line 58 tests the shell variable, not the exported environment (3/3 ship-as-is)
- [carried task 3 d] carried — Step 2 ran bash only and checked "no s3cret" by eye (3/3 ship-as-is)
- [carried task 3 e] carried — "Env vars in build script" label now checks only IDENTITY, intended (3/3 ship-as-is)
- [carried task 4] carried — Exit 3 paragraph is one line of about 2,000 characters (3/3 ship-as-is)
- [carried task 5 a] carried — Pre-Flight block lacks pins for three sentences (3/3 ship-as-is)
- [carried task 5 b] carried — no pin that the batched-question paragraph and blocker sentence stay (3/3 ship-as-is)
- [carried task 6 a] carried — implementer-prompt DONE_WITH_CONCERNS line narrower than the C9 rule (3/3 ship-as-is)
- [carried task 6 b] carried — plan tick also ticked two checkboxes inside a fenced block of the plan (3/3 ship-as-is)
- [carried task 7] carried — section 26 lists the eight controller files by hand (3/3 ship-as-is)
- [carried task 8] carried — no pin that the unreadable-evidence paragraph comes before "## Part 1" (3/3 ship-as-is)
- [carried task 9] carried — round step 1 does not itself say exit 3 stops the loop (3/3 ship-as-is)
- [carried task 10] carried — section 5f does not pin "A wrong branch state is not an open item" (3/3 ship-as-is)
- [carried task 11] carried — README Platform status line of about 82 characters (3/3 ship-as-is)
- [carried task 12] carried — guide code spans break across source lines (3/3 ship-as-is)
- [carried task 13 a] carried — release note names ${IDENTITY:+x}; plan reference text still says ${IDENTITY:-} (3/3 ship-as-is)
- [carried task 13 b] carried — Step 8 ran the 20 fast suites in one shell loop (3/3 ship-as-is)
- [carried task 13 c] carried — RELEASE-NOTES.md header note still names GitHub Copilot CLI as used (3/3 ship-as-is)

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 2 Minor | r2: 0 Critical, 1 Important, 0 Minor | r3: 0 Critical, 2 Important, 1 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — the C9 'did not cause' criterion counts only a test that is a changed file or directly imports or reads one, so a regression the task causes through another module, a run script or a shared fixture is labelled not caused and left unfixed (plan-mandated) — at skills/subagent-driven-development/implementer-prompt.md:57 — clause: Task 6 "Must convey: a test outside the task that fails and that the change did not cause is not fixed, unless the brief or the controller's dispatch names that test as" ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] fixed — batch-controller start-check BLOCKED return could meet a stale task-<n>-report.md section from an abandoned run of the same plan and be ruled on as an open item; the start check now renames that file to .stale, and the guide and release-note repair text name the old report files → 63778304 ← 1/3: r1:I2
- [I3] rejected: needs a state outside the supported environment (the branch history rewritten during a run, CLAUDE.md Supported environment), which that section makes Minor; the exit-3 stop is loud as required — exit-3 handling offers no route when the user cannot or will not restore BASE as an ancestor ← 1/3: r3:I2
- [M1] rejected: orchestration artifact (documented) — plan checkbox ticks inside the Task 6 reference block ← 1/3: r1:M1
- [M2] fixed — Resume Procedure step 2 routed only a resume-prompt answer, not the user's answer to step 3's question, to the exit-3 task review → 63778304 ← 1/3: r1:M2
- [M3] carried — Pre-Flight scan table rows for names two or more tasks mention are unbounded, so table size varies between controllers ← 1/3: r3:M1

## Round 3 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 0 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor
**Converged:** no
### Dispositions
- [M1] carried — review-package range mode checks the resolved base_name/head_name but builds the package from the raw arguments, so a ref that moves between guard and diff gives an unchecked range (same issue as carried task 2 security M1, shipped as-is in round 1) ← 2/3: r2:M1, r3:M1
- [M2] carried — batch-controller start check pastes <head7> from the ledger into a git command without a hexadecimal check; needs a ledger written to mislead (outside the supported environment) ← 2/3: r2:M2, r3:M2

_Completed — 2026-10-21 — cap reached — HEAD 63778304028428c4f546d4bf21ad3e5f45bb9e8f_
Secrets found: none
