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
