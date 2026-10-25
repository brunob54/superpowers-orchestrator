_Invocation 1 — 2026-10-25 — N=4 M=3 — BASE..HEAD b8c9435..1a25f83 — branch feature/reviewer-evidence-and-inputs-read — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 5 Minor
**Converged:** no
### Dispositions
- [M1] carried — tools/count-report-fields.js:54 counts a Critical/Important id line with a `harness:` field as a finding without evidence, although both reviewer prompts exempt it; the spec's measure defines with-evidence as presence only ← 1/3: r1:M1
- [M2] fixed — docs/guide/README.md addendum paragraph did not name the second trigger of re-review 2 (no usable report of re-review 1 declares the diff read whole) → f8b078db ← 1/3: r2:M1
- [M3] carried — skills/multi-doc-review/SKILL.md:531-532 evidence note for a Critical does not say that the reason is one of the same five phrases, as the code skill says ← 1/3: r2:M2
- [M4] carried — the `(evidence: <reason>)` note on a Critical open-item line enters the orchestrator Phase 4 Item summary (orchestrating-development/SKILL.md:2096-2098 strips only `(plan-mandated)`); cosmetic ← 1/3: r3:M1
- [M5] carried — tools/count-report-fields.js:236 matches the expected-input needles over the whole prompt, carried-findings text included, so a carried line quoting a needle can inflate the expected set ← 1/3: r3:M2
- [carried task 1 paging stop clause] carried — ship-as-is (3/3)
- [carried task 1 82-character line] carried — ship-as-is (3/3)
- [carried task 2 doc prompt Repository root text] carried — ship-as-is (3/3)
- [carried task 2 short wrapped lines] carried — ship-as-is (3/3)
- [carried task 3 inert code-only bullet in doc prompt] carried — ship-as-is (3/3)
- [carried task 4 short harness line] carried — ship-as-is (3/3)
- [carried task 4 test 31 awk anchors] carried — ship-as-is (3/3)
- [carried task 5 joined line code-review-loop-prompt.md:199] carried — ship-as-is (3/3)
- [carried task 5 guide clean-round rule] carried — ship-as-is (3/3; already rewritten by Task 9)
- [carried task 5 wide line item 10] carried — ship-as-is (3/3)
- [carried task 6 line-initial `1)` in multi-doc-review Resume paragraph] fixed — paragraph re-wrapped, no word change → f8b078db
- [carried task 6 line starting `= 1.`] carried — ship-as-is (3/3)
- [carried task 6 code spans across lines] carried — ship-as-is (3/3)
- [carried task 7 test 16 comment figure] carried — ship-as-is (3/3)
- [carried task 8 fixture Write copy findings] carried — ship-as-is (3/3)
- [carried task 8 untrimmed heading and id-line tests] carried — ship-as-is (3/3)
- [carried task 8 INPUT_LINE_RE repeats INPUTS names] fixed — alternation built from INPUTS → f8b078db
- [carried task 8 unreadable transcript exit 1] carried — ship-as-is (3/3)
- [carried task 8 no fixture for unknown or several ranges] carried — ship-as-is (3/3)
- [carried task 9 short guide line] carried — ship-as-is (3/3)

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 3 Important, 1 Minor | r3: 0 Critical, 2 Important, 2 Minor
**Sources mapped:** 11/11
**Reviewer verdict:** 0 Critical, 4 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — the `input partial` rejection reason applies to any gap-form or absence-form Important finding whose report declares the diff partial or omits the declaration, even when every unread range is annotated with unrelated paths and the evidence was read from the checkout file, so a true finding can be rejected with no file read; the fix-reviewed rule reads the same annotated declaration the opposite way (plan-mandated) — at skills/multi-code-review/SKILL.md:990 — clause: Task 4 "Must convey spec 5.2: the controller reads each Critical/Important finding's evidence line against the claim before choosing a disposition, as a text comparison" ← 3/3: r1:I1, r2:I2, r3:I1
- [I2] user-decision — a fix that no reviewer read (every later report declares the diff partial without qualifying annotations) ships when the verification cap or the addendum bound is spent, and the loop's return carries no signal of it; only the `**Inputs read:**` log lines show it (plan-mandated) — at skills/multi-code-review/SKILL.md:1268-1276 — clause: Task 5 "Addendum re-review rule (wording artifact): a re-review is clean only when it also has a report that passes the fix-reviewed test; one without such a report and" ← 1/3: r2:I1
- [I3] user-decision — the controller may reject an Important finding as `rejected: evidence (missing)` or `(line differs)` without opening any file, so a true finding from a reviewer that omits the new evidence line can be dropped, and two controllers decide differently (plan-mandated) — at skills/multi-code-review/SKILL.md:983-989 — clause: Task 4 "Must convey spec 5.2: the controller reads each Critical/Important finding's evidence line against the claim before choosing a disposition, as a text comparison" ← 1/3: r2:I3
- [I4] fixed — verification re-review gave no single reading when unreviewed fixes come from more than one originating round; one sequence under the highest originating round and its lens → eb51fde7 ← 1/3: r3:I2
- [M1] carried — the fix-reviewed test accepts a reviewer's path annotation on an unread range without checking that the range starts at a `diff --git` header and ends before the next one ← 2/3: r1:M1, r2:M1
- [M2] carried — a diff with a hunk no reviewer can read whole (a large lockfile) makes every rotating round partial for the inputs-read cause, so the loop never converges early, with no message naming the cause ← 1/3: r1:M2
- [M3] carried — paging stop clause has no exit when a single line exceeds the Read token cap (refused even at limit 1); harness: tested by the reviewer ← 1/3: r3:M1
- [M4] carried — the absence form uses the removed text as the grep pattern, so a removed line holding a credential would be copied into the report ← 1/3: r3:M2
