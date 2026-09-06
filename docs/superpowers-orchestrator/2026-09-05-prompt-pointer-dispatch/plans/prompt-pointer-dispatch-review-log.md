# Review Log — prompt-pointer-dispatch.md

_Invocation 1 — 2026-09-05 — N=2 M=2 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 4 Minor | r2: 0 Critical, 3 Important, 2 Minor
**Sources mapped:** 11/11
**Reviewer verdict:** 0 Critical, 5 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 3 Steps 4 and 5 (fill commands), Task 3 Contract, Task 1 section 6: inline fill values shown unquoted although the sanctioned no-package `PACKAGE_FILE` value contains spaces, so the shell splits it and the script exits 1 on every no-package round → every `NAME=` argument in both fill commands is single-quoted, the reason is stated next to each command, the Contract requires it, and section 6 gains a real-template case filling the no-package value and asserting exit 0 ← 2/2: r1:I2, r2:M2
- [I2] applied — Task 3 Step 4 (step 2 replacement), Task 3 Contract: the no-plan sentence and the carried block were referred to as "the legend's …" without text, so the controller would have to read the template to compose them → both texts spelled out in the step 2 replacement (each on one physical line), the Contract requires them, and section 10 pins `No requirements document is available` and the carried-block line ← 1/2: r1:I1
- [I3] applied — Task 3 Step 1 (section 10 needles), Step 2 expectation, Contract invariants: the `test -s` needle already matches the Triage harness sub-bullet inside the Procedure range, so the contract bound nothing and Step 2's expected failure list was wrong → needles replaced by `test -s "<PROMPT_DIR>/round-<i>-reviewer.md"` and `test -s "<PROMPT_DIR>/round-<i>-fix.md"`, the Step 2 expectation and the Contract invariants updated and the reason recorded ← 1/2: r2:I1
- [I4] applied — Global Constraints, Task 3 Contract (Error Handling), Task 3 Step 6: a value-file write can be denied by this plugin's own hooks (`protect-secrets.js` scans Write content for secret-like strings; `block-dangerous-commands.js` scans the whole Bash command string with no heredoc awareness — confirmed: the controller's own grep containing such a pattern was denied during this triage) and no fallback row covered it → new Error Handling row (inline dispatch for the dispatch that value serves, stated with the hook's reason, text never altered, no retry through the other write form), the Global Constraints fallback list and the Contract name the case ← 1/2: r2:I2
- [I5] applied — Assumptions, Task 3 Step 3 ("Before round 1"), Task 3 Contract: no assumption about the shape of the `mktemp -d` path on Git Bash, where a POSIX `/tmp/…` path inside a `NAME=@…` value is not converted by MSYS and native Node cannot resolve it, making the mechanism permanently inoperative on one of the three named platforms → explicit Assumption added (unverified on Windows, first Windows run checks it), "Before round 1" converts the path once with `cygpath -m` on Git Bash, the Contract requires the sentence ← 1/2: r2:I3
- [M1] applied — Task 3 Step 3 (Procedure intro): "Every prompt this skill dispatches" contradicted the Triage probe-subagent dispatch → reworded to "Every reviewer and fix-subagent prompt", probe subagent named as excluded ← 1/2: r1:M1
- [M2] applied — Task 3 Step 3 (file-name table): `<c>` undefined on the fix row → defined as the cycle whose re-review produced the findings being fixed ← 1/2: r1:M2
- [M3] applied — Task 1 reference script and Contract: the repeated-`NAME` check ran after the template was read, so a usage error with a bad template exited 2 or 5 → check moved into `parseArgs` before any file read, Contract states the precedence, one test case added (repeated `NAME` with an unreadable template exits 1) ← 1/2: r1:M3
- [M4] applied — Task 3 Step 3 (file-name table, written-once sentence), Step 5 (retry bullet): the fix re-dispatch reuses the findings file but the table and the once-per-dispatch sentence did not say so → re-dispatch rows note the reuse, the sentence names both reuses, the retry bullet passes the same `FINDINGS=@…` ← 1/2: r1:M4
- [M5] applied — Task 3 Step 5 (Critical/Important bullet): the bullet restated the fix rules while saying it did not, duplicating the template body the spec asks it to only point at → list cut to the pointer plus the `hooks/subagent-guard.js` reason, which the spec keeps in SKILL.md ← 1/2: r2:M1

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 5 Minor | r2: 0 Critical, 1 Important, 7 Minor
**Sources mapped:** 14/14
**Reviewer verdict:** 0 Critical, 2 Important, 10 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 3 Step 4 (step 2 fill command): `CARRIED_BLOCK` shown unconditionally as the `@` file while the prose makes it conditional, so a copied command on rounds 2..N references a file never written (exit 5, inline fallback) → argument shown as `'CARRIED_BLOCK=<carried block>'` in the same style as `PLAN_LINE`, the quoting sentence and the prose name both forms and state that the file is never referenced on a round that did not write it ← 1/2: r1:I1
- [I2] applied — Global Constraints bullet 8: the clauses "a value-file write denied by a hook or failing" and "finding text is never altered to pass a hook" (placed there under round-1 [I4]) trace to no spec row and restate the SKILL.md Error Handling row this plan writes — a self-pin in disguise under the plan's Body authority regime → both clauses removed from Global Constraints; the Error Handling row, the Step 6 text and the Task 3 Contract clause from round-1 [I4] stay, where they are reviewable as ordinary content ← 1/2: r2:I1
- [M1] applied — Task 1 Step 2 section 5: the "option without a value" case also repeated `--out`, so it could not show which branch exited 1 → argv changed to `--template "$SMALL" ROUND=3 --out` ← 2/2: r1:M1, r2:M2
- [M2] applied — Task 2 Step 1 section 9: the "stands alone on its line" assertions were fixed-string prefix matches, so `    [FINDINGS] note` would pass → whole-line helper `assert_file_has_line` (`grep -qxF`) added next to `assert_file_not_contains`, both assertions use it ← 2/2: r1:M3, r2:M3
- [M3] applied — Task 2 Contract invariants: "the legend ends with the sentence …" while the template and the test both have the paragraph continue → reworded to "the legend's closing paragraph begins with the sentence" ← 1/2: r1:M2
- [M4] applied — Global Constraints exit-code bullet: no code for an unreadable `--template` (the spec has the same gap; the Task 1 Contract fixes it at 5) → the bullet states that a cause the spec assigns no code to takes the code the Task 1 Contract states, a pointer rather than a new binding clause ← 1/2: r1:M4
- [M5] applied — Task 1 Step 1 fixture `special-value.md`: no creation instruction although its line holds `$HOME` and `$(echo no)` → "create it with the Write tool or a quoted heredoc" added with the reason ← 1/2: r1:M5
- [M6] applied — Task 3 Step 3, Contract, Assumptions: the `cygpath -m` sentence gave no rule for detecting Git Bash and no handling for a `cygpath` failure → detection by `uname -s` printing a name beginning with `MINGW` or `MSYS`; a `cygpath` failure takes the whole-invocation inline fallback; every other platform uses the printed path as is ← 1/2: r2:M1
- [M7] applied — Task 1 Step 1: only `newline-only.md` had a creation command although four other fixtures must end with exactly one newline → one verification loop over the fixtures directory (`tail -c1 | od -An -c`, every line must end with `\n`) added after the fixtures ← 1/2: r2:M4
- [M8] applied — Task 3 Contract invariants vs Step 1 section 10: the fix-commit subject invariant named section 10 as its verification but section 10 had no such needle → `'review fixes (<slug>, round <i>)'` added to the needle loop and to Step 2's already-pass list ← 1/2: r2:M5
- [M9] applied — Global Constraints exit-code bullet: exit 2 listed two causes while the script and Assumption 4 also exit 2 for a missing or unclosed fence and an empty body → reworded as the spec's "malformed template" covering all four causes ← 1/2: r2:M6
- [M10] applied — Task 3 Step 3 file-name table: `<k>` readable as counting re-dispatches too → "counting first dispatches only — a re-dispatch keeps the `k` of the dispatch it repeats" ← 1/2: r2:M7

### Self-review (writing-plans checklist, after the loop)
- Spec coverage: every item of the spec's Testing strategy (1–4) and Rollout maps to Tasks 1–4 or to "Not in this plan (by the spec)"; no gap.
- Placeholder scan: no TBD/TODO/"add appropriate" patterns; the only `XXXX` is the example `mktemp -d` path.
- Type consistency: every helper the tasks call (`assert_absent`, `assert_same`, `assert_file_not_matches`, `small_fill`, `assert_file_has_line`, `extract_lines`, `extract_prompt_body`) is defined by the same or an earlier task; `<skill-dir>` and `<PROMPT_DIR>` are used consistently.
- Scope-reduction scan: the only hit, "minimal fixes", traces to the spec's fix-subagent rules.
- Contract audit: no `**Exact content:**` markers; every task carries a falsifiable Contract; Task 4's whole-branch checks are procedural `Run:` lines; Global Constraints bullet 8 and the exit-code bullet were re-worded during this loop so that every entry traces to the spec ([I2] and [M4]/[M9] of round 2).
- No merge-introduced issue found; nothing fixed at this step.

Harness probes owed: none

_Loop complete — 2026-09-05 — rounds 2_
