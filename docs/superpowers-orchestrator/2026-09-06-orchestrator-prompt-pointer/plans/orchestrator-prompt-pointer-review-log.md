# Review log — orchestrator-prompt-pointer.md

_Invocation 1 — 2026-09-06 — N=2 M=2 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 3 Minor | r2: 0 Critical, 3 Important, 1 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 3 Important, 2 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 4 Step 1 / Task 5 Step 1 / Task 6 Step 1 (wording suite sections 1, 3, 4, 7, 8): five fragment needles are wrapped across a line break in the plan's own reference text, so per-line `grep -qF` can never pass → added `fold_file` and `assert_folded_contains` helpers (lines trimmed and joined with one space) and switched every prose-fragment check on a range file to them; whole-line checks stay unfolded; Task 4 contract invariant records the folding rule ← 2/2: r1:I1, r2:I1
- [I2] applied — Task 4 Step 1 (section 5): `assert_file_has_line` on the nothing-else line fails permanently on plan-writer-prompt.md, whose line continues after the sentence and is pinned byte-identical → changed to the substring check `assert_file_contains`, with a comment giving the reason ← 2/2: r1:I2, r2:I2
- [I3] applied — Task 6 Step 3 (Resume step 3) and Task 6 contract: the new text always wrote a value file, contradicting the Global Constraint that a run with no recorded answer writes no value file and passes `RESUME_ANSWER=` → added the no-answer clause (Phase 4 moved-HEAD and migrated-run paths) to the Resume step 3 text and to the contract's Must-convey; section 8 gains the needle `no answer line`; Task 6 Step 2 expected count 8 → 9 ← 2/2: r1:M1, r2:I3
- [M1] applied — Assumptions item 1: the body-only comparison silently supersedes the spec's "body and wrapper" phrase → the assumption now states that the spec sentence is superseded and is a spec amendment to record ← 2/2: r1:M2, r2:M1
- [M2] applied — Task 1 Step 2 expected output: the no-`[M]` and no-residual-placeholder checks pass on a missing file (grep finds nothing), they do not fail → sentence corrected to name the assertions that fail (exit code, `M filled`, checklist line) ← 1/2: r1:M3

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 4 Minor | r2: 0 Critical, 0 Important, 5 Minor
**Sources mapped:** 11/11
**Reviewer verdict:** 0 Critical, 2 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 1 Step 2 and Task 2 Step 2 expected output: the red-run pass counts (102, 116) cannot occur; on the unchanged templates 9 of section 10's 14 assertions and 15 of section 11's 24 pass (verified: the suite prints `102 passed` today; the script's name pattern needs two letters, so `M=<n>` is a usage error already) → Task 1 reads `Results: 111 passed, 5 failed` and Task 2 reads `Results: 131 passed, 9 failed`, each with the failing assertions listed ← 2/2: r1:I1, r2:M1
- [I2] applied — Task 6 contract, second wording artifact: "stay verbatim and contiguous" contradicts Step 3, which inserts sentences between the pinned ones → invariant now reads "each stay verbatim as one unbroken sentence; other text may stand between them, and Step 3 places its new sentences between the first and the third" ← 1/2: r1:I2
- [M1] applied — Assumptions item 1: "the script would exit 4" is wrong for a wrapper-only name (the script accepts it) → parenthetical corrected: the script writes nothing for it, only the set comparison catches the drift ← 1/2: r1:M1
- [M2] applied — Task 4 contract invariant "each on one physical line" was unverifiable after the folding fix of round 1 → section 1 gains a trimmed-range `assert_file_has_line` check for each of the three pointer sentences (`POINTER_FIRST` added) ← 1/2: r1:M2
- [M3] applied — Task 2 section 11: the needle `holds no` is unanchored → needle is now `` `## Resume Answer` holds no `` (one physical line of the filled output) ← 1/2: r1:M3
- [M4] applied — Task 3 in-run-rulings assertion "heading is present" over-promises (`exact` mode is a substring match) → renamed "heading line exists" with a comment saying the negative assertion carries the parenthetical check ← 1/2: r1:M4
- [M5] applied — Task 2 Step 2 count (fixed under [I1]) and Task 5 Step 2 expected list omits `phase 0: names the creation-failure cause` (the cause text is absent from today's text) → added to the expected failures ← 1/2: r2:M2
- [M6] applied — Task 4 Step 3 fatal-table row 4: `<name>` ambiguous between the value file and the probe file → row states `<name>` is always the value file's name and the probe file is named in the error text ← 1/2: r2:M3
- [M7] applied — Task 5 contract names `<mcr>`, which the body never introduces → contract now asks for the spelled-out `<base>/../multi-code-review/...` path ← 1/2: r2:M4
- [M8] applied — Task 6 Resume step 3 "both below" reads as exhaustive (a third no-answer path exists); Task 4 cites Phase 0 step 9 before Task 5 adds it → "for example" wording; Task 4's Does-NOT-cover line records the forward reference ← 1/2: r2:M5

### Self-review (writing-plans checklist, after the loop)
- Spec coverage: no gap found (round 1's two reviewers reported none; the body-only cross-check deviation is recorded as a spec amendment in Assumptions item 1).
- Placeholder scan: no TBD / "add appropriate" / step-without-code pattern.
- Type consistency: `fold_file`, `assert_folded_contains` and `POINTER_FIRST` are defined once in Task 4 Step 1 and used by the Task 4, 5 and 6 test blocks inserted into the same suite; `$WORK` is defined before its new use.
- Scope-reduction scan: no "v1", "basic", "simple", "for now", "initial version", "minimal" hit.
- Contract audit: every merge-introduced block sits inside an existing contract-covered artifact; no `**Exact content:**` marker added; no Global Constraints entry touched.
- No merge-introduced issue found; nothing fixed at this step.

Harness probes owed: none

_Loop complete — 2026-09-06 — rounds 2_
