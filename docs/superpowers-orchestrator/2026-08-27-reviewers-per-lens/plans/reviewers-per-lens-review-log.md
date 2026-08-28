# Review log — reviewers-per-lens.md (plan)

_Invocation 1 — 2026-08-27 — N=4 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-fable-5
**Reviewer verdict:** 0 Critical, 2 Important, 1 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 6 Step 1 (`assert_round_reviewers`): the awk entry extraction `"^## Round " r " "` also matched a `## Round <i> verification <c> — …` header, so a verification-cycle entry was appended to the round entry and the count checks produced a false FAIL(m) → rule 1 now matches `"^## Round " r " — "` (the en dash follows the round number on the round header only); the helper comment explains why.
- [I2] applied — Global Constraints, Task 2 Step 5, Task 3 Step 7 (`**Reviewers:**` rule): "written when M ≥ 2, and also when the effective M differs from the invocation line's M: then it is the only added line" let a resumed invocation with effective M = 2 and a line recording M=1 drop the verdicts, traceability check, and annotations → reworded to the spec 6.2 scope: the single-line case applies only when the effective M is 1 and the line records a larger M; an effective M ≥ 2 always writes all three lines and the annotations.
- [M1] applied — Task 7 Step 4 (guide stage description): the cross-reference "see the `SUPERPOWERS_REVIEWERS_PER_LENS` setting in §6" pointed to the wrong guide section (Step 5 inserts the example after `docs/guide/README.md:658`, inside §7 Context pressure) → changed to §7.


## Round 2 — Ambiguity & testability — claude-fable-5
**Reviewer verdict:** 0 Critical, 1 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 6 Step 6 (behavioral verification precondition): the reinstall of the local plugin was prose with no commands, no branch name, and no proof that the installed copy carries the new text; the cache is laid out per version and Task 8 (version bump) runs after Task 6 → replaced with exact commands (fetch `feature/reviewers-per-lens` into the marketplace clone, whose `marketplace.json` has `"source": "./"`; check it out; `claude plugin update superpowers-orchestrator -y`), an executable precondition check (`grep -c 'usable <u>/<m>'` on the cached `$(cat VERSION)` copy of `skills/multi-doc-review/SKILL.md`, expected ≥ 1), the stale-copy recovery (remove the cached version directory, update again, re-check), a rule not to run the tests until the check passes, and the restore of the clone to `main` afterwards.
- [M1] applied — Task 1 Step 3: expected output said the first line is `FAIL - …`; the script prints a header line first and indents the `FAIL`/`ok` lines by two spaces → expected output now lists the header line, the indented `  FAIL - …` line, the `  ok   - …` lines, and `  5 passed, 1 failed`.
- [M2] applied — Task 1 Step 5: "final line `All unit tests passed.`" — the runner prints ` All unit tests passed.` (leading space) followed by a `=====` rule → reworded to "the line ` All unit tests passed.` (one leading space; the final line is the `=====` rule)".
- [M3] applied — Task 2 Step 5 and Task 3 Step 7 (`**Reviewer verdicts:**` rule): the order of the two suffixes when a reviewer needs both was unstated → added "`, ids renumbered` first, then `, counts recomputed`" in both tasks.
- [M4] applied — Task 2 Step 5 (source-annotation rule): "Post-loop note lines" is a term the doc-review skill does not define → reworded to "the note lines the 'After the loop' step writes for merge-introduced fixes (self-review notes) carry no annotation".
- [M5] applied — Task 3 Step 6 (partial verification paragraph): "a partial verification cycle whose consolidated set is empty ends the verification" left the all-carried/all-rejected case unstated → reworded to "a partial verification cycle after which no unreviewed fix remains (an empty consolidated set included) ends the verification of its originating round".
- [M6] applied — Task 4 Step 8: `grep -c` with several files prefixes each count with the path as typed, not the bare file name → expected output now shows the `skills/orchestrating-development/…` prefixes. Task 5 Step 3: `grep -n 'batched autonomous'` already matches two lines (announce line 172 and paste prompt line 220) → expected output now says three lines and names the announce line.
- [M7] applied — Task 6 Step 6: "the Case 1 and Case 2 PASS lines" do not exist; `finish()` prints one `PASS: multi-code-review behavioral test` line for both cases → expected output now names that single line.

## Round 3 — Feasibility & architecture risk — claude-fable-5
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** no

### Dispositions
- [M1] applied — Task 5 Step 3: the Round 2 rewording named the third `grep -n 'batched autonomous'` match as "the new `mode, M=<m>)` line", but the new paste prompt wraps after `(batched autonomous`, so the matched line is the one ending there → expected output now names the line ending in `(batched autonomous` and says its `mode, M=<m>)"` continuation is not matched.
- [M2] applied — Task 2 Step 8: the pattern `One reviewer per round` can never match `skills/multi-doc-review/reviewer-prompt.md` because the old sentence wraps after `One`, so the check was vacuous for that file → added `^reviewer per round;` (the old second line) to the pattern; the new header does not contain it.
- [M3] applied — Task 1 Step 1 (`run_hook`): `env -i` drops `SYSTEMROOT` and `TEMP`, which native `git.exe` on Windows Git Bash can need to start → the env line now passes both through when set (`${SYSTEMROOT:+SYSTEMROOT="$SYSTEMROOT"} ${TEMP:+TEMP="$TEMP"}`), with a comment; no effect on macOS/Linux.

## Round 4 — Adversarial failure modes — claude-fable-5
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 6 header and Step 6: Task 6 declared no dependency on Tasks 2–3 and no ordering against Task 8; subagent-driven-development's Parallel Waves group by file overlap only, so Task 6 (files disjoint from every other task) would run in the first wave, install a branch without the skill text, and the stale-copy remedy looped without an exit → added a `**Depends on:**` line (Tasks 1–5 committed; Task 8 not started because it changes `VERSION`), a branch-content check before the installation (`git grep -c 'usable <u>/<m>' "$BR" -- skills/multi-doc-review/SKILL.md`, ≥ 1, else stop and report), and bounded the remove/update remedy to one retry with a stop-and-report outcome.
- [I2] applied — Task 2 Step 4 rule 8 / Step 6 and Task 3 Step 4 rule 8 / Step 9: the renumbering rule was unconditional while its note can only live on the `**Reviewer verdicts:**` line (M ≥ 2) and the M = 1 entry is promised byte-identical → rule 8 and both Error Handling bullets now say "M ≥ 2 only; with M = 1 the report keeps its original ids, as today" (consistent with the spec's "When M = 1 the consolidated set is the report's enumeration with its original ids").
- [M1] applied — Task 6 Step 6: the clone restore ran only after a passing test run, a rerun's fetch into a checked-out branch would be refused, and the 7.3.0 cache directory keeps the branch's skills → fetch into a detached checkout (`checkout --detach FETCH_HEAD`), restore the clone unconditionally, and state that `rm -rf "$CACHE"` plus an update from `main` is needed to get the released copy back.
- [M2] applied — Task 6 Step 1 (`assert_round_reviewers`): the "at least one annotation" check failed on a legitimately empty round-1 consolidated set (`Sources mapped 0/0`) → the check is skipped with a `note:` line when k = 0; the header comment says why and tells the runner to rerun if findings were expected.
- [M3] applied — Task 6 Step 6: the branch name was hard-coded → `BR=$(git branch --show-current)` with a comment naming `feature/reviewers-per-lens` as the orchestration value.

### Post-loop self-review (writing-plans checklist)
- Spec coverage: spec sections 4–11 each map to a task (hook + tag → Task 1; §4–§6 per skill → Tasks 2–3; §7 → Tasks 4–5; §10 → Tasks 1 and 6; §11 → Tasks 7–8); no gap.
- Placeholder scan: no TBD/TODO/"add appropriate"/steps-without-code hits.
- Type consistency: helper names (`assert_round_reviewers`, `run_hook`, `expect_tag`, `expect_no_tag`), the variable/tag names, and the log-line names are spelled identically across tasks.
- Scope-reduction scan: the only hit ("placeholder") names the `[M]` template placeholder, not a scope downgrade.
- Merge check: the Step 2 fixture uses `Sources mapped 4/4` and `3/3`, so the Round 4 [M2] k = 0 skip leaves its expected output unchanged. No merge-introduced issue found.

_Loop complete — 2026-08-28 — rounds 4_
