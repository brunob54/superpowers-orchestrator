# Review Log — 2026-08-22-researching-prior-art.md

_Invocation 1 — 2026-08-22 — N=5 — gate: orchestration_

## Round 1 — Correctness & completeness — session model
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 5 SKILL.md: gate message not available on direct invocation → gate message block copied verbatim into the sub-skill's SKILL.md direct-path paragraph; Task 5 Step 2 now counts the gate-message line; Task 6 Step 8 now diffs the gate-message block across the two files.
- [I2] applied — Task 5 Inputs / error table: "N=0 never reaches this skill" contradicted the direct-invocation path → claim scoped to the brainstorming-invoked path; direct-path 0 reply defined (state the skip in the conversation and stop; record in a spec only when one exists).
- [M1] applied — Task 5 degradation ladder: rung 2 contract now includes re-verifier dispatch; step 6 retitled rung-agnostic and rung 2 told to run its checks after writing the merged report.
- [M2] applied — Task 4 Step 2: `SLUG` added to the placeholder verification loop.
- [M3] applied — Task 9 assertion (c): citation grep now accepts a URL or a clone file path; header comment updated.
- [M4] applied — Assumption 2: explicit recorded-disposition sentence added for the named-reference deviation (checklist/graph predicate placement).

## Round 2 — Ambiguity & testability — session model
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 12 Step 5: "Expected: empty" does not hold on the recommended execution routes (spec/plan/sidecars stay uncommitted; pre-existing untracked file `t`) → expectation rewritten to allow exactly those two classes of entries and to require everything from Tasks 1-11 committed.
- [M1] applied — Task 3 Step 2: BRE-alternation count check was factually mis-explained and weaker than claimed → replaced with the per-placeholder loop pattern (matches Task 4 Step 2).
- [M2] applied — Task 6: no post-edit check for checklist/graph edits → new Step 8 greps item 15 and both new graph node labels with expected counts; later steps renumbered (verify → Step 9, commit → Step 10).
- [M3] applied — Task 5 step 5: `[REPORT_DIR]` / `[MERGED_REPORT_FILE]` shown as relative while requiring absolute → rewritten as `<repo-root>/...` with an explicit pointer to the Root-anchoring rule.

## Round 3 — Feasibility & architecture risk — session model
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no

### Dispositions
- [M1] applied — Task 1 Step 3c: quoted exemption-condition block used wrong indentation (4/6 spaces vs the file's 6/8) → both code blocks re-quoted at the file's real indentation, with a note.
- [M2] applied — Task 1 Step 3d: claimed a both-lists convention that does not exist (three `SKILL_NAMES` entries are absent from the alternation) → reworded; explicit warning not to "fix" older entries.
- [M3] applied — Assumptions: controller prompt carries TWO extra placeholders (`[RESEARCH_PROMPT_PATH]` and `[SLUG]`), not one → assumption corrected.
- [M4] applied — Task 9/10 Step 3: README anchor ("Integration Tests list, lines 81-117") does not exist → rewritten to the section's real `####` heading-per-test format with an exact insertion anchor (before `## Adding New Tests`, line 118); notes the two currently undocumented tests are left as is.

## Round 4 — Adversarial failure modes — session model
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Tasks 3/4/5: subagent-facing templates used relative or unanchored paths (cache dir, clone dir, manifest) while subagents inherit the session's working directory → new `[REPO_ROOT]` placeholder added to both templates; clone path, version anchor, cache-state paths, and cache-write output all anchored to it; SKILL.md step-5 fill list and both placeholder-verification loops extended; Assumptions bullet rewritten to declare all three controller extras and the researcher extra.
- [I2] applied — Task 10 vs the normative gate message: backticks around `<S>` made two "verbatim" renderings possible, one failing the test regex → regex now tolerates an optional backtick (`` N=`?[0-9]+ ``); a placeholder-markup note added after the normative block and in both gate-message intro sentences (brainstorming section, sub-skill copy).
- [M1] applied — Task 9/10 scripts: inner `timeout 1800` could never fire before the runner's outer 1800 → inner budget lowered to 1700 with an explanatory comment; both FAIL messages updated.
- [M2] applied — Task 12 Step 5 exempted "pre-existing untracked files" with no recorded baseline → Task 1 gains Step 0 (status baseline to `.superpowers/pre-plan-status.txt`); Step 5 now diffs against that baseline.
- [M3] applied — Task 7 Step 2: placement claim was checked only by eye → verification now bounds the grep to the Ambiguity & testability block via sed range plus a whole-file count.

## Round 5 — Correctness & completeness — session model
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 4 vs Task 5 rung 2: the controller had no sanctioned behavior when nested dispatch itself fails, making the designed rung-2 recovery unreachable → dispatch-failure rule added to the controller prompt (write no merged report; return a marker-first summary stating subagents could not be dispatched); Task 4 Step 2 marker count updated 3 → 4.
- [M1] applied — Task 4 Paths: re-verifier and follow-up researcher report files had no defined names → `<slug>-rv<J>-report.md` and `<slug>-f<J>-report.md` naming added; verification rules stated to apply to them.
- [M2] applied — Task 5 direct path lacked the unusable-reply rule brainstorming's gate has → the two-sentence rule copied into the direct-invocation paragraph.
- [M3] applied — "`.superpowers/` is gitignored in this repo" is only true via the local `.git/info/exclude` on this machine → Task 1 Step 0 now writes a self-`.gitignore` (`*`) before the baseline snapshot; Task 9 script comment and Task 12 Step 5 reworded accordingly.

## Post-loop self-review (writing-plans checklist, run by the controller)
- Spec coverage: no requirement without an implementing task (cross-checked by rounds 1 and 5).
- Placeholder scan: clean — the `[UPPERCASE]` tokens are the templates' runtime placeholders, dispositioned in the plan's own Self-Review section.
- Type consistency: two merge-introduced issues found and fixed inline: (1) the round-5 dispatch-failure bullet lacked the literal marker string while Task 4 Step 2 expected count 4 → bullet rewritten to contain the literal marker; (2) the plan's Self-Review section still referenced "Task 6 Step 8" after the round-2 renumbering → corrected to Step 9.
- Scope-reduction scan: no downgrades.

_Loop complete — 2026-08-22 — rounds 5_
