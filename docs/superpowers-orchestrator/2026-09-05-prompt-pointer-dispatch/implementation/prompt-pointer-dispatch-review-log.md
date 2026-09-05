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

## Round 2 verification 1 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 3 Minor | r2: 0 Critical, 1 Important, 3 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 3 Important, 6 Minor
### Dispositions
- [I1] fixed — the round-2 fill command hard-coded the carried file, so round 1 without a carried list (direct mode) would exit 5 and fall back to inline dispatch; the three CARRIED_BLOCK cases are now stated → 32ecce8 ← 1/2: r1:I1
- [I2] rejected: harness probe not runnable here — in a session with permission mode `acceptEdits` (not bypass), Write one small file under a fresh `mktemp -d` directory and observe whether a permission prompt appears before the write lands — (ambiguous observation) — a value-file Write outside the working directories may wait on a permission prompt in a non-bypass session; this session runs in bypass mode, so no observation here can match or contradict the claim ← 1/2: r1:I2
- [I3] rejected: duplicate of round 2 [I1], an open user-decision item (no reader-side fallback for the pointer mechanism; a fix adds a failure class the Task 3 Contract forbids) ← 1/2: r2:I1
- [M1] fixed — fill-prompt.js renamed over an existing --out silently; now exits 5 before any write when the file exists, with a test → 32ecce8 ← 1/2: r1:M1
- [M2] carried — fill-prompt.js: a whitespace-only @file value is not empty, and a CRLF value inside an LF template keeps its CR bytes (cosmetic in a rendered prompt) ← 1/2: r1:M2
- [M3] rejected: decided by orchestrator ruling 1 (CLAUDE.md is local-only, git-ignored) and the loop never edits plan text — Task 4 marks a CLAUDE.md edit complete that a fresh clone never receives ← 1/2: r1:M3
- [M4] carried — the lost-path rule (inline dispatch after a context compaction, no second mktemp -d) may be read as a resume by one controller and as mid-invocation by another; allowing a second directory contradicts Global Constraints 'created once per controller' and needs a plan amendment ← 1/2: r2:M1
- [M5] fixed — fill-prompt.js dropped trailing blank lines before the fill, so a last-line whole-line placeholder with an empty value left two trailing newlines; now dropped after the fill, with a test → 32ecce8 ← 1/2: r2:M2
- [M6] rejected: duplicate of round 1 [M19], an open user-decision item (all dispatches share one flat prompt directory) ← 1/2: r2:M3

## Round 2 verification 2 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 2 Important, 3 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 2 Important, 6 Minor
### Dispositions
- [I1] rejected: harness probe not runnable here — from the controller's session in the permission mode an orchestrated run uses (not bypass), Write one line to `<fresh mktemp -d dir>/probe.txt` with the Write tool and observe whether a permission prompt appears (then a throwaway subagent's Read of that file is the second probe) — (not settled by one probe) — value-file Writes and prompt-file Reads outside the working directories may raise permission prompts or be auto-denied in a non-bypass session, stalling the loop or making every round inconclusive; this session runs in bypass mode ← 2/2: r1:I1, r2:I2
- [I2] user-decision — 'once per controller' is read literally by a controller that runs a second direct-mode invocation in the same session: the second invocation reuses the directory, every fill hits an existing file name, exits 5 and falls back to inline dispatch; the suggested wording 'once per invocation' contradicts the Global Constraint (plan-mandated) — at skills/multi-code-review/SKILL.md:332 — clause: Global Constraints "The prompt directory is created once per controller with `mktemp -d`, outside the checkout, before round 1; the skill text never shows `$PROMPT_DIR` or any othe" ← 1/2: r2:I1
- [M1] carried — the verification-cycle table row reuses round-<i>-lens.txt, which a resumed controller never wrote for an earlier round's post-loop re-review; the fill exits 5 and that re-review goes inline ← 1/2: r1:M1
- [M2] carried — fill-prompt.js: the existing-file check followed by rename is not atomic against a concurrent fill of the same --out; the comment claims a guarantee that holds for sequential fills only ← 1/2: r1:M2
- [M3] carried — the pointer sentence names 'the Read tool'; a platform whose file-reading tool has another name has no fallback stated (the skill already refuses platforms without the Agent tool) ← 1/2: r1:M3
- [M4] carried — a harmless re-run of an already successful fill now exits 5 'file already exists', and step 2.3 sends the dispatch inline although the existing file is complete; the step could run test -s and dispatch the pointer instead ← 1/2: r2:M1
- [M5] carried — the file-name table has no row for the single after-loop verification re-review, so its cycle index <c> is unstated and may collide with an in-loop cycle file ← 1/2: r2:M2
- [M6] carried — the lens text is written with a Bash heredoc that the dangerous-command hook scans; the security lens text is one character away from a pattern match, and the no-retry rule would then send every security round inline ← 1/2: r2:M3

_Completed — 2026-09-05 — cap reached — HEAD 32ecce86b51b9f578c1b96a7b75c3936734ee189_
Secrets found: none

### Post-loop addendum — 2026-09-05 — decisions
Effective HEAD had moved (marker 32ecce8, effective HEAD a283aad at answer time: plan and spec amendments); the marker above is left unchanged, the verification re-review of the accepted fixes is skipped, and Invocation 2 below reviews them.
- [M19] decided (orchestrator): plan governs: "The prompt directory is created once per invocation with `mktemp -d`, outside the checkout, before round 1 (a controller that runs a second invocation, or resum" — /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md (round 1 item)
- [I2] decided (orchestrator): amend plan: the Global Constraints prompt-directory entry now reads "created once per invocation with `mktemp -d`, outside the checkout, before round 1 (a controller that runs a second invocation, or resumes one, creates a fresh directory first)" (amended by ruling 3); fix it: the Procedure preamble of skills/multi-code-review/SKILL.md says the directory is created once per invocation — before round 1, or before the round a resumed invocation continues at — never once per controller, so a second invocation in one session gets a fresh directory and no file-name collision (round 2 verification 2 item)
- [I2] fixed — the Procedure preamble now says the prompt directory is created once per invocation (before round 1, or before the round a resumed invocation continues at); a second or resumed invocation creates a fresh directory, and the lost-path rule runs `mktemp -d` again instead of forbidding a second directory → f534fea
- [I1] decided (user): amend plan: every failure of the pointer mechanism, writer side and reader side, is fatal — the controller writes the round entry it owes, then returns `BLOCKED: <cause>` naming the failure; there is no inline fallback (Global Constraints entry amended by ruling 4; Task 3 Contract amended; spec Amendment 1); fix it: skills/multi-code-review/SKILL.md's Procedure preamble, step 2, step 3 and Error Handling section state the fatal rule for every failure (`mktemp -d`/`cygpath`, the fill script, `test -s`, Node missing, a value-file write refused or failed, and a round with no usable report after the pointer dispatch and the one identical retry — that round is written `inconclusive`, then the loop returns BLOCKED naming the round and each reviewer's final message) and no longer describe or perform inline dispatch or template reading; tests/reviewer-templates/run-tests.sh section 10 asserts `BLOCKED:` in the Error Handling range and the absence of `inline dispatch` from the Procedure and Error Handling ranges (round 2 item)
- [I1] fixed — every failure of the pointer mechanism is fatal: the preamble, step 2, step 3, the fix-dispatch bullet and Error Handling state the exact `BLOCKED:` outcomes (directory, prompt file, value file, Node missing, no usable report in a round) and every inline-fallback sentence is removed; tests/reviewer-templates/run-tests.sh section 10 asserts `BLOCKED:` in the Error Handling range and the absence of `inline dispatch` from the Procedure and Error Handling ranges → f534fea

_Invocation 2 — 2026-09-05 — N=2 M=2 — BASE..HEAD b9b9ffb..f534fea — branch feature/prompt-pointer-dispatch — gate: orchestration_
