# Marker Position Tolerance — Plan Review Log

_Invocation 1 — 2026-09-06 — N=2 M=2 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-opus-5[1m]
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 4 Minor | r2: 0 Critical, 3 Important, 3 Minor
**Sources mapped:** 12/12
**Reviewer verdict:** 0 Critical, 3 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 4 (title, Files, Does NOT cover, Contract 1, new Step 5, Step 7, Step 9) and the File Structure table: the two `reviewer-prompt.md` notes spell the rule `OPEN with`, so they state the pre-change rule and escape the spec's own grep → both files are now rewritten in a new Step 5, and Step 7 adds a supplementary `grep -rniE "open(s|ing)? with"` with its four expected surviving hits enumerated ← 2/2: r1:I1, r2:I2
- [I2] applied — Task 1 Step 1, `Two marker lines inside the window exempt`: the message put the first marker on line 1, so the test passed on the unmodified guard while Step 2 listed it as an expected failure → a narration line now precedes the first marker, which makes the case fail before the change and actually exercise the window ← 2/2: r1:I2, r2:I3
- [I3] applied — Task 4 Step 3: the prescribed residual-risk replacement contained "opens with it", a hit the Step 7 grep forbids inside `skills/` → reworded to "the marker does not have to be the message's first line", with a sentence recording why the phrase is avoided ← 1/2: r2:I1
- [M1] applied — Task 4 Contract 1 invariants: the "keeps the instruction never to remove the marker" invariant is now scoped to the five passages that carry such an instruction, and states that none is added to the other three ← 1/2: r1:M1
- [M2] applied — Assumptions (new fourth bullet) and Task 4 Steps 1, 2 and 4: records that `tests/reviewer-templates/run-tests.sh:262` ranges on the whole line `## Guard Interaction` of `skills/multi-code-review/SKILL.md`, and that every heading line stays untouched ← 1/2: r1:M2
- [M3] applied — Task 1 Contract 1 Verification: adds the leading-whitespace and CRLF cases to the enumerated list, and notes that the CRLF case is the only executable check of Global Constraint 10 ← 1/2: r1:M3
- [M4] applied — Task 1 Step 1: the constants block now comes first, and each of the three replacement tests carries `VERB_SKILL_BODY` below its marker line, matching the shape `markerOnNonBlankLine` builds ← 1/2: r1:M4
- [M5] applied — Task 4 Step 6: `docs/FORK-IMPROVEMENTS.md`'s reviewer-report bullet (`:122`) is rewritten alongside the orchestration bullet (`:203`) ← 1/2: r2:M1
- [M6] applied — Task 2 Contract 1 and 2, Step 1, Step 2, Step 4 and the File Structure table: a third assertion pins the fragment `a longer report is **not** malformed`, so the cap's new status is protected by a test ← 1/2: r2:M2
- [M7] applied — Task 1 Contract 3, Step 1 and Step 2: a new test `The hook comments state the window rule` asserts the hook source has no `opens with` and does contain `MARKER_SEARCH_LINES non-blank lines`, so the comment rewrite is verified inside Task 1 rather than three commits later ← 1/2: r2:M3

## Round 2 — Ambiguity & testability — claude-opus-5[1m]
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 3 Important, 3 Minor
**Sources mapped:** 10/10
**Reviewer verdict:** 0 Critical, 3 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 3 (Files, Contract 1-3, new Steps 1 and 2) and Task 4 Step 7: the "Must convey" property of the nine prose passages had only negative greps behind it, so a rewrite that deleted the exemption sentence would have passed every named check → Task 3 now adds three assertions to `tests/orchestrating-development/run-tests.sh` (positive `first 10 non-blank lines` in the `## Guard Interaction` range and in the `## In-run rulings` range, negative `hang the dispatch` over the whole file) with a failing-test-first step, and Task 4 Step 7 gains a positive, fold-tolerant check that every rewritten prose file contains the phrase ← 2/2: r1:I1, r2:I2
- [I2] applied — Task 3 Contract 1 and new Step 1: the invariant "the section no longer claims … hang the dispatch, and stall the unattended run" had no falsifying check → the negative assertion `assert_file_not_contains … "hang the dispatch"` now pins it, and Step 2 records it among the three that must fail first ← 1/2: r2:I1
- [I3] applied — Task 1 Contract 1 Verification and Step 1: the round-1 claim that the CRLF case is the only executable check of Global Constraint 10 was wrong — under a prefix match a trailing `\r` sits after the marker and never changes the result → the Verification now states what each CRLF case can and cannot catch, and a new test `Twelve CRLF blank lines before the marker still exempt` is the case that actually pins the trailing-`\r` trim (with `trimStart()` alone each blank CRLF line is the single character `\r`, counts as non-blank and pushes the marker out of the window) ← 1/2: r2:I3
- [M1] applied — Task 1 Contract 1 and 2, Task 2 Contract 2: "rule 2" and "rule 5" now name their source in full (`skills/writing-plans/SKILL.md`, Contracts and Literal Bodies), so no reader resolves them against this plan's own numbered Global Constraints ← 1/2: r1:M1
- [M2] applied — Task 4 Step 7: "any of the nine rewritten passages" became "any of the eight passages of this task's Contract", a count a reader can check ← 1/2: r1:M2
- [M3] applied — Task 4 Step 7, supplementary grep: the expectation is now stated as a property (no remaining hit may state what the hook exempts) with the four reference-wording hits given as an illustration, so a task that words its sections without "open with" is not judged by a stale total ← 1/2: r1:M3
- [M4] applied — Task 3 Step 3: "must survive this edit byte-for-byte" became "their character sequence must survive", with a note that the suite folds line breaks and that the first pinned sentence shares a physical line with the last deleted one ← 1/2: r2:M1
- [M5] applied — Task 2 Contract 1 and Step 3: the bullet used "non-blank" for the window and "non-empty" for the token line in adjacent sentences; both now read "non-blank", with the meaning stated once, so a whitespace-only line below the marker is skipped rather than read as the token line ← 1/2: r2:M2
- [M6] applied — Task 4 Step 7: the `fill-prompt.js` hit is matched by its text instead of by the line number `:247`, which an unrelated edit above it would change ← 1/2: r2:M3

_Loop complete — 2026-09-06 — rounds 2_

### Self-review (writing-plans checklist, after the loop)
- Spec coverage: every Scope item and every Testing-strategy case maps to a task — Scope 1 → Task 2, Scope 2 → Task 1, Scope 3 → Tasks 3 and 4, Scope 4 → Task 1 Step 1, Task 2 Step 1 and Task 3 Step 1; Acceptance 1-4 → Task 4 Steps 7 and 8. No gap found.
- Placeholder scan: no TBD, "add appropriate", FIXME or trailing-ellipsis pattern. The only hits for the scope-reduction words are the two TDD step titles "Implement minimal change", which are the standard step name.
- Type consistency: `hasReportMarker`, `MARKER_SEARCH_LINES`, `REPORT_MARKERS`, `WINDOW`, `VERB_SKILL_BODY`, `markerOnNonBlankLine`, `RETURN_WINDOW`, `RETURN_MARKER`, `RETURN_CAP_NOT_MALFORMED`, `GUARD_WINDOW`, `GUARD_HANG_OLD_CLAIM` and `GUARD_RANGE` are each spelled the same everywhere they appear.
- Contract audit: the one `**Exact content:**` marker cites `tests/in-run-rulings/run-tests.sh:798-811`, a file this plan neither writes nor edits (Global Constraint 9), so it is not a self-pin. Every other fenced block sits under a stated `**Contract:**` or is a procedural block (the commit blocks, the `Run:` lines, and the `for` loop of Task 4 Step 7, which writes no working-tree file).
- Fixed during the self-review: Tasks 2 and 3 both described "the three new assertions in `tests/orchestrating-development/run-tests.sh`" — the two contracts now name their block (`1b` for Task 2, `3b` for Task 3), so the same file carrying two contracts is unambiguous.
