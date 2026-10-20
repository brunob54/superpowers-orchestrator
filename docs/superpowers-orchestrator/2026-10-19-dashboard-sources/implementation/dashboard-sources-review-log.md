# Code review log — dashboard-sources

_Invocation 1 — 2026-10-20 — N=4 M=3 — BASE..HEAD d36133f..f07637c — branch feature/dashboard-sources — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 1 Important, 0 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 1 Important, 2 Minor
**Converged:** no
### Dispositions
- [I1] fixed — commitMeta git log names the revision without `--`; a file HEAD (or folder head on macOS) in the repository root crashes the private extract with exit 1 → e4aac14b ← 3/3: r1:M1, r2:I1, r3:M1
- [M1] fixed — RELEASE-NOTES first-refresh line shows only `status ok → absent`; not-found and error statuses print other text → e4aac14b ← 1/3: r1:M2
- [M2] fixed — RELEASE-NOTES "every date the extractor computes is local" overclaims; unfinished-run dates stay in committer time zone → e4aac14b ← 1/3: r3:M2
- [carried task 7 security M4] fixed — followedRef git log has no `--` → e4aac14b
- [carried task 7 security M7] fixed — refresh step 6 single-quoted stored sharedRef; guard sentence added (lone user-decision under M=3 → fix-before-merge) → e4aac14b
- [carried task 1 security] carried — safeText(a.heading) can no longer change a verdict
- [carried task 1 security] carried — test-11 section 7 nothing-written check has no session-log.md to protect
- [carried task 1 security] carried — most basicInvalid reasons checked by verdict only (pre-existing)
- [carried task 1 review] carried — test-10 anchorWith default occurrence: 1
- [carried task 1 review] carried — test-11 section order 14, 15, 13
- [carried task 2 review] carried — dashboard-parse.js header comment ragged
- [carried task 3 review] carried — no session fixture with a date but no time
- [carried task 4 review] carried — test-04 section 10 tzDoc hides exit code
- [carried task 4 review] carried — no detached-HEAD isCurrent test
- [carried task 4 review] carried — LATE, TOKYO, LOCAL_DAY declared mid-file
- [carried task 5 review] carried — asOfLine prints () without commit.date
- [carried task 5 review] carried — byDateThenName compares dates as strings
- [carried task 6 review] carried — test-08 number check matches anywhere in the sentence
- [carried task 6 review] carried — Source sentences checked against builders by all three reviewers this round; all match
- [carried task 7 security M1] carried — git error message can hold an absolute path from a linked worktree
- [carried task 7 security M2] carried — form-error sharedRef name stored raw
- [carried task 7 security M3] carried — control characters reach the stderr line
- [carried task 7 security M5/M6] carried — non-string sharedRef gives no line; no dedicated security tests
- [carried task 7 review] carried — later-git-failure catch path of followedRef has no test
- [carried task 7 review] carried — sharedRefLine error text can end with ..
- [carried task 8 review] carried — plan-mandated duplication of shared-ref line (ruling 1)
- [carried task 8 review] carried — test-07 shared hidden case duplicates no-sharedRef path
- [carried task 8 review] carried — no test for published set and previousBuild null
- [carried task 9 security M1] carried — test-06 shared-output check has no positive control
- [carried task 9 security M2] carried — renderSharedRef shows sharedRef for any audience (Constraint 13)
- [carried task 9 security M3] carried — trackedOnly copies unknown top-level keys (S-41 scope)
- [carried task 9 security M4] carried — private accept check uses only sharedRef: null
- [carried task 9 review] carried — SHARED_DOC_FILE used only in the new block
- [carried task 9 review] carried — test-06 privacy-data folder inside h.ROOT
- [carried task 10 review] carried — test-12 SHARED_LINE label constant
- [carried task 10 review] carried — refresh step 4 relies on the model keeping the stderr line
- [carried task 11 review] carried — pre-existing long line in docs/guide/README.md
- [carried task 12 review] carried — RELEASE-NOTES Problem line not directly supported by Why
- [carried task 12 review] carried — "the same week" and "25 days" spec incident figures

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 3/3
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** no
### Dispositions
- [M1] fixed — refresh step 8 repeats the step-4 shared-ref line next to a shared URL just published, so its Last published part is one refresh old; step 8 now says the line is the state before this refresh → 934c1734 ← 1/3: r1:M1
- [M2] carried — first refresh after upgrading from a 7.72 share shows a false Never published warning on the private page until the next refresh (spec section 4.5 accepts the one-refresh delay of published; the report part is covered by the M1 wording) ← 1/3: r2:M1
- [M3] fixed — commits() git log still had no `--`; a root file HEAD turned the commits section into an error and the new test did not check it → 934c1734 ← 1/3: r3:M1
