# Review log — 2026-08-25-artifact-layout.md

_Invocation 1 — 2026-08-25 — N=4 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-opus-5[1m]
**Reviewer verdict:** 0 Critical, 5 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 19 Step 4: `git mv` leaves the emptied `docs/specs/` directory on disk, so Step 1's `test ! -d docs/specs` can never pass → added `rmdir docs/specs` after the last move out of that folder, with a comment saying why `docs/plans/` is deliberately kept.
- [I2] applied — Task 20 Steps 1–2: the verification grep covered `docs/guide/README.md` (8 hits Task 21 owns) and `tests/codex/test-skill-activator.js` (7 hits no task changed), so Step 4's "prints nothing" was unreachable → removed `docs/guide/README.md` from the grep scope with a stated reason, and made Task 6 update the seven remaining old-layout prompt paths in `test-skill-activator.js` (new table in its Step 1).
- [I3] applied — Task 17: spec §9 requires the `tests/explicit-skill-requests/` prompt texts updated, but the six files under `prompts/` were missing → added them to the Files list and to Step 4 with the exact replacement; rewrote Step 5's grep to exclude `tests/sdd-scripts/run-tests.sh` (its `docs/plans/planC.md` fixtures test a plan outside the layout on purpose, which Task 13 keeps supported) and named the four comment lines that legitimately remain.
- [I4] applied — Tasks 2, 4, 5, 9, 11, 21: six verification needles could not match the text the same task inserts (line wraps, `**` emphasis, capitalisation) → Task 2 and Task 4 needles now use `grep -qi`; Task 5 uses the short needle `segment nearest` plus `! grep -q 'docs/specs/'` (a condition that actually changes state, per M3); Task 9's inserted text is reflowed so `**pipeline mode**` sits on one line; Task 21's needle now matches the emphasised `**repository root**`; Task 11's expected `read ban` count corrected from 1 to 2, with the reason.
- [I5] applied — Task 11: `skills/multi-code-review/SKILL.md:388-392` restates the reviewer template's fallback diff commands, which Step 5 changes → added a new Step 6 that rewrites that Error Handling bullet to carry the blinding pathspec set; later steps renumbered.
- [M1] applied — Task 12: spec §9's "archive folder naming with a dateless plan basename yields the same slug" had no task → added an assertion block to `tests/sdd-scripts/run-tests.sh`, switching plans so the archive path actually fires and asserting `archive/baz`.
- [M2] applied — Task 15 Step 4: the step replaced the controller's `.superpowers/reviews/` write scope, while spec §5.4 says the topic folder is *added* → the scope now lists both, with the reason.
- [M3] applied — folded into I4's Task 5 fix: the third condition `! grep -q 'under \`docs/specs/\` → \`spec\`'` guarded nothing because that phrase spans a line break in the current file; it now greps the bare string `docs/specs/`, which occurs once today and zero times after the edit.

## Round 2 — Ambiguity & testability — claude-opus-5[1m]
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 8 Step 1: the "works from a subdirectory" assertion checked only the exit status and wrote the package to `/dev/null`, so it passed for every possible implementation → it now writes to a real file and asserts on content (`VISIBLESOURCE` present, `SECRETFINDING` absent), which is what actually distinguishes `:(top)` anchoring from a relative scope.
- [I2] applied — Task 8: the `--commits` mode edits shipped with no test, although spec §6 requires blinding in both modes → added a `--commits` invocation with the same contains/not-contains pair, and corrected Step 4's expected text to say the pre-existing `--commits` assertions predate blinding.
- [I3] applied — Task 19 Steps 9–10: Step 9's filter did not exclude this run's live files (` M` plan, `??` sidecars), making its expected output unreachable; Step 10's `git add -A docs` swept them into the migration commit → added a third `grep -v` filter with its reason, and replaced the bulk `git add` with an explicit staging plus a `git reset` of the three live files.
- [I4] applied — Task 22 Step 9: "reinstall the local plugin" was an instruction with no command, in the step that gates the only end-to-end verification → rewrote the step with the exact procedure (push, `/plugin update`, the two plugin-manager tabs, a `cat …/7.3.0/VERSION` check, fresh session) and stated plainly that it is a manual hand-off, because the plugin manager is interactive and the marketplace resolves to GitHub.
- [M1] applied — Task 8 Step 2: the expected-failure list said "and the four sibling assertions"; eight assertions fail before Step 3 → enumerated all eight and noted that the two `VISIBLESOURCE` checks pass both before and after, as regression guards.
- [M2] applied — Task 3 Step 3: one sentence told the implementer both to replace the Ready Message line (already prescribed earlier) and that the `state.md` seed bullet "stays as is" → split into two plain sentences.
- [M3] applied — Task 7 Step 1: a step titled "Write failing tests" whose Step 2 expects PASS → renamed to "Add the classification fixtures" and stated that the two positive tests are the control for the negative `implementation/` assertion.
- [M4] applied — Tasks 1, 5 and 20: three gates did not cover every edit their own task prescribes → Task 1's needle is now the bare `docs/specs/` (covering `SKILL.md:247` as well as `:53`); Task 5 gained `! grep -q 'docs/specs/' … reviewer-prompt.md`; Task 20 gained a second gate command for the generic path examples, which carry no `2026-` date and so were invisible to the first.
- [M5] applied — Task 20's note said "eight old-layout path examples" in the guide; the file has 18 matching lines → corrected to 18.
- [M6] applied — Task 22 Step 8: the step claimed to check the hook count but never counted hooks, and neither number had a stated pass condition → added `ls hooks/*.js | wc -l` and the four exact expected values (28 skills, 10 hooks).

## Round 3 — Feasibility & architecture risk — claude-opus-5[1m]
**Reviewer verdict:** 5 Critical, 2 Important, 5 Minor
**Converged:** no

### Dispositions
- [C1] applied — Task 1 Step 1: the gate's `! grep -q 'docs/specs/'` could never pass, because the "Topic folder derivation" bullet Step 3 inserts names `docs/specs/<file>` itself as the example of a path outside the layout → replaced with two specific negative needles (`docs/specs/YYYY-MM-DD-` and ``required path (`docs/specs/`)``), one per place Step 4 edits, and recorded why the bare needle is wrong here. (This gate came from round 2's M4 fix; the narrower needles keep that coverage without the contradiction.)
- [C2] applied — Task 14 Step 1: same shape — the gate requires `docs/specs/` to be absent, while Step 3's own replacement text said "an old `docs/specs/…` path included" → reworded the inserted prose to "an old flat-directory spec path included" and added a note that keeps future edits from reintroducing the literal.
- [C3] applied — Task 8 Step 1: the two package files added in round 2 were written to the repository root of the shared throwaway repository, where they survive as untracked files and break Task 12's `git status --porcelain` clean assertion → both now go to `$WS` (`.superpowers/sdd/`, self-ignoring), and the `--commits` variable was renamed `BLIND_CPKG` to avoid the `CPKG` already bound at line ~179 (round 3 M5, same fix).
- [C4] applied — Task 17 Step 2 assertion (p4): `create_test_project` makes a bare `mktemp -d` + `git init` with no `.gitignore`, and both cases `tee` their transcript into it, so the clean-tree check failed on every run regardless of behavior → the check now excludes `output*.txt` via a pathspec, with the reason stated.
- [C5] applied — Task 19 Step 10: `git add -A docs/superpowers-orchestrator docs/specs docs/plans .gitignore` names `docs/specs`, which Step 4 has already removed; `git add` is atomic across pathspecs, so it aborts and stages nothing, silently dropping Step 7's `.gitignore` edit → changed to `git add -A -- docs .gitignore`, with the failure mode written out.
- [I1] applied — Task 22: the reinstall/behavioral hand-off (old Step 9) ran before the release commit (old Step 10), so the push it asks for could not carry the version bump and the `7.3.0/` cache check could never pass → swapped them; the release commit is now Step 9 and the hand-off is Step 10, the plan's last step.
- [I2] applied — Task 19 Step 4: moving this run's own spec left two live references dangling (this plan's `**Spec:**` header, read by `multi-doc-review`; the orchestration log's recorded spec path, compared on resume) → the step now also rewrites both in place with a `sed` over the repository-relative path, plus a `grep -c` check and an instruction to stop if the orchestration log reports zero.
- [M1] applied — File Structure table: `create_test_plan` has no caller anywhere in `tests/` → the table row now says so and states why the helper is kept consistent anyway.
- [M2] applied — Task 17 Step 4: `run-extended-multiturn-test.sh` contains only the `mkdir -p` line, not the other two replacements → stated as an explicit exception so an executor does not report a miss.
- [M3] applied — the section was cited as "Artifact layout" in three places and gated as `^## Artifact Layout$` → normalized every citation to "Artifact Layout".
- [M4] applied — Task 20 Step 1: the `docs/FORK-IMPROVEMENTS.md:105` sentence Step 3 replaces carries neither a date nor a `<` placeholder, so neither existing gate could see it → added a third gate command (`grep -n 'Historical documents under'`) and updated Step 4's expectation to three commands.
- [M5] applied — the `CPKG` half is folded into C3; Task 3's Step 3 heading said "five path statements" for four sites → heading now names the four.

## Round 4 — Adversarial failure modes — claude-opus-5[1m]
**Reviewer verdict:** 0 Critical, 4 Important, 2 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 10 Step 7: the step title named two edit sites but gave only one instruction, leaving the "After the Loop" paragraph stating the raw-HEAD marker rule unconditionally — a direct contradiction of pipeline rule 4, which would make the once-per-gate skip never match and re-run the whole loop on every retry → added the second edit (marker `<sha>` qualified by mode) and a gate needle for it in Step 1.
- [I2] applied — Task 17 Step 2: the insertion anchor said "append after the direct-mode block" without naming the file's final summary block, which immediately follows it and exits → the anchor now names both boundaries (line 141 `fi`, line 143 summary) and states what goes wrong if Case 2 lands after the summary.
- [I3] applied — Task 17 Step 5: the gate needles ended in `/`, so the six `mkdir -p .../docs/plans` lines Step 4 also changes were invisible to it → dropped the trailing slash from both needles and wrote out the failure the old gate allowed (plan written into a directory that was never created).
- [I4] applied — Task 17 Step 2 assertion (p5): a `for … do [ -f ] || continue` loop over the review packages reported success when it examined nothing → added a `PKG_COUNT` control that fails when no package is found, matching the control Task 7 uses for its own negative assertion.
- [M1] applied — Task 1 Step 4: the inserted checklist item cites the "Reusing an existing topic folder" sub-section, which Task 2 creates → noted the forward reference explicitly, so an executor does not delete the sentence or reorder the two tasks.
- [M2] applied — Task 3 Step 1: the only gate in the plan that printed three counts with no `PASS`/`FAIL` verdict → restructured into shell variables with an explicit verdict line, and updated Steps 2 and 4 to expect it.

## Self-Review (writing-plans checklist, run on the merged plan)

- **1. Spec coverage** — one gap found and fixed: spec §7's row "`chore(review)` commit fails (hook, signing prompt, conflict) → multi-code-review stops the loop after the round and reports the failure; the log and fix reports stay on disk uncommitted" had no task text. Task 9's validation covered only the *next* invocation's retry. Added a "When the commit fails" paragraph to Task 10 Step 4 (pipeline rule 1), including why the loop must not start another round before the pending commit succeeds. Every other spec section maps to a task: §4→T1, §5.1→T1/T2, §5.2→T3/T4, §5.3→T5, §5.4→T14/T15, §5.5→T13, §5.6→T9/T10/T11, §5.7→T16, §5.8→T6/T7, §6→T8/T11/T15, §7→T2/T4/T9/T10/T13/T14, §8→T19/T20, §9→T6/T7/T8/T12/T17, §10→T21/T22.
- **2. Placeholder scan** — clean. No `TBD`, "add appropriate", "as needed", "etc.", or trailing-ellipsis step in the document; every step carries a concrete command or an exact before/after replacement block.
- **3. Type/name consistency** — clean. `TOPIC_DIR` is spelled identically in all 54 occurrences; the section name is now "Artifact Layout" everywhere (fixed in round 3, M3); the shell variable names added during the merges (`BLIND_CPKG`, `BLIND_SUBPKG`, `PKG_COUNT`, `DIRT`, `OLD_PLANS`, `OLD_SPEC_HDR`, `NEW_PATHS`) collide with nothing already bound in the files they are inserted into.
- **4. Scope-reduction scan** — clean. No "v1", "basic", "for now", "initial version", "minimal" or "simplified" anywhere in the plan.
- **Step numbering** — checked across all 22 tasks after the round-1 and round-4 insertions (Task 11 gained a step, Task 22 had two swapped): every task's steps run 1..n with no gap and no duplicate.

_Loop complete — 2026-08-25 — rounds 4_
