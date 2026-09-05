# prompt-pointer-dispatch — code review log

_Invocation 1 — 2026-09-05 — N=2 M=2 — BASE..HEAD b9b9ffb..a9d5039 — branch feature/prompt-pointer-dispatch — gate: orchestration_

## Round 1 — Correctness & spec alignment — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 1 Minor | r2: 0 Critical, 1 Important, 1 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 1 Important, 2 Minor
**Converged:** no
### Dispositions
- [I1] fixed — SKILL.md step 2 sub-step 4 never stated the reviewer dispatch description wording (the base text lived only in the template the controller no longer reads); now spelled out literally → 2ade665 ← 2/2: r1:I1, r2:I1
- [M1] fixed — fix-prompt.md: re-dispatches and verification-cycle fixes reuse one round number, producing repeated identical `## Round` headings; now appends a new section at the end of the file each time → 2ade665 ← 1/2: r1:M1
- [M2] fixed — fix-prompt.md intro said the controller never pastes this text, contradicting the inline-dispatch fallback in SKILL.md Error Handling; reworded → 2ade665 ← 1/2: r2:M1
- Carried findings from `.superpowers/sdd/progress.md` (18 `Minor:` lines), decided from the two reviewers' recommendations:
- [M3] carried — fill-prompt.js writeAtomic: a body of only whole-line placeholders with empty values writes a 1-byte file and exits 0 (unreachable with the real templates)
- [M4] fixed — fill-prompt.js writeAtomic catch unlinked a temporary path this process may not have created; now guarded by a created flag → 2ade665
- [M5] carried — fill-prompt.js end-of-line detection is whole-file; the comment does not say so
- [M6] fixed — tests/fill-prompt section 5: the 'missing @file exits 5' case lacked the assert_absent check its siblings have → 2ade665
- [M7] fixed — tests/fill-prompt section 6b: the CR-count assertion passed vacuously on a missing file; now asserts the two-line shape first (the S5 comment wording is left as is) → 2ade665
- [M8] carried — fill-prompt.js writeAtomic: flag 'wx' and the random temp-name component are pinned by no test
- [M9] carried — tests/fill-prompt section 6b: the two hardening templates are built by duplicated printf lines
- [M10] carried — fix-prompt.md model field: the corrected fix-subagent model wording is pinned by no assertion in reviewer-templates section 9
- [M11] carried — tests/reviewer-templates: assert_file_not_contains is defined in Task 2 and first used in Task 3 section 10
- [M12] carried — tests/reviewer-templates section 9: no direct assertion for 'no three-backtick line in the body' or 'no bracketed uppercase token other than the six placeholders'
- [M13] carried — tests/reviewer-templates section 9: the nothing-else sentence assertion is file-scoped, not legend-scoped
- [M14] carried — tests/reviewer-templates first_line_of: grep stderr leaks when the template is missing
- [M15] carried — fix-prompt.md: an empty FAILURE_BLOCK leaves two consecutive blank lines before '## Procedure' (cosmetic)
- [M16] carried — tests/reviewer-templates section 10: the Procedure range also spans Lens Rotation (plan-mandated end marker)
- [M17] carried — SKILL.md Critical/Important bullet: the fix-dispatch description and 'the fix-subagent model of Parameters' are pinned by no section-10 needle
- [M18] carried — SKILL.md step 2 sub-step 2: 'every value except LENS_INSTRUCTIONS and a non-empty CARRIED_BLOCK is inline' reads as a rule before the two rules that override it
- [M19] user-decision — Task 3 security review residual M3: a verification-cycle reviewer prompt sits beside its round's fix prompt in one flat prompt directory, so a reviewer that ignores the pointer sentence could read finding text; one reviewer recommended user-decision, one ship-as-is, and every fix (per-dispatch sub-directories, deleting the fix prompt after use) contradicts the once-per-controller, never-cleaned-up directory the plan fixes (plan-mandated) — at skills/multi-code-review/SKILL.md:331 — clause: Global Constraints "The prompt directory is created once per controller with `mktemp -d`, outside the checkout, before round 1; the skill text never shows `$PROMPT_DIR` or any othe"
- [M20] carried — Task 4 produced no commit: CLAUDE.md is gitignored (.gitignore:7), so the branch history holds no record of the Testing-block edit beyond the plan tick and ruling 1 (traceability note only)

## Round 2 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 6/6
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — a systematic reader-side failure of the pointer (every reviewer unable to read its prompt file) never reaches the inline-dispatch fallback: each round retries the identical pointer once and ends inconclusive, so all N rounds pass with zero findings; the suggested fix adds a reader-side failure class, which the Task 3 Contract forbids with 'no new failure class' (plan-mandated) — at skills/multi-code-review/SKILL.md:1446 — clause: Task 3 "Must convey the four fallback rows of the spec and the one row this plan adds: `mktemp -d` failure → inline dispatch for the whole invocation, stated in the com" ← 1/2: r1:I1
- [I2] rejected: harness probe not runnable here — in the session's normal permission mode (not bypass), write one file under a fresh `mktemp -d` directory and dispatch one throwaway subagent with the three-sentence pointer; observe whether a permission prompt appears before the subagent reports the file's content — (ambiguous observation) — a Read of the prompt file outside the working directories may raise a permission prompt in default permission mode; this session runs in bypass mode, so no observation here can match or contradict the claim ← 1/2: r1:I2
- [M1] fixed — no rule for a controller that holds no prompt-directory path: a resumed invocation starts in a new controller, and a context compaction loses the literal path mid-invocation; now a controller creates its own directory before its first round, and a lost path takes inline dispatch for the rest of the invocation → f93e9e6 ← 2/2: r1:M2, r2:M1
- [M2] fixed — the step 2 fill command showed the carried block as an inline single-quoted value although the rule requires the @file form; an apostrophe in carried text would break the command → f93e9e6 ← 1/2: r1:M1
- [M3] fixed — the verification-cycle table row did not say whether a round-1 cycle re-sends the carried block; now always the empty value → f93e9e6 ← 1/2: r2:M2

