
## Round 1

Findings addressed: I1, M1, M2, CF2, CF4, CF5.

- I1 — `skills/multi-code-review/SKILL.md` (Procedure step 2, sub-step 4): stated the reviewer dispatch's `description` wording literally (`multi-code-review round <i>: <lens name>`, with ` (reviewer <j>/<m>)` appended only when M ≥ 2) instead of pointing at "the template"; kept the sentence that only `description` differs between the M calls, and only when M ≥ 2.
- M1 — `skills/multi-code-review/fix-prompt.md` (step 3): reworded so the fix subagent appends a NEW `## Round [ROUND]` section at the end of the fix-report file on every dispatch, never merging into an existing section of the same heading — so the last section is always the current dispatch's, even when verification-cycle fixes or re-dispatches reuse the round number.
- M2 — `skills/multi-code-review/fix-prompt.md` (intro): reworded "The controller never pastes this text" to "...except on the inline-dispatch fallback of SKILL.md Error Handling", removing the contradiction with that fallback.
- CF2 — `skills/multi-code-review/scripts/fill-prompt.js` (`writeAtomic`): added a `created` flag set only after the `wx` open succeeds; the catch block now unlinks the temporary path only when this process actually created it, so it never deletes a pre-existing file/symlink that caused the open to fail.
- CF4 — `tests/fill-prompt/run-tests.sh` (section 5, "missing @file exits 5"): added `assert_absent "missing @file: nothing written" "$WORK/s5.md"` to match its sibling cases.
- CF5 — `tests/fill-prompt/run-tests.sh` (section 6b): added `assert_eq "mixed line endings: output has exactly 2 lines (fails if the file is missing)" "$MIXED_EOL_LINE_COUNT" "2"` before the CR-count comparison, so the assertion no longer passes vacuously when the output file is missing (both `line_count` and the CR grep would then yield an empty string, which the fixed line-count value catches). Left the S5 comment above it unchanged.

### Covering tests

Command: `bash tests/fill-prompt/run-tests.sh`
Result: `Results: 81 passed, 0 failed`

Command: `bash tests/reviewer-templates/run-tests.sh`
Result: `Results: 55 passed, 0 failed`

Command: `bash tests/in-run-rulings/run-tests.sh`
Result: `Results: 496 passed, 0 failed`

Command: `bash tests/writing-plans/run-tests.sh`
Result: `Results: 15 passed, 0 failed`

Command: `bash tests/sdd-scripts/run-tests.sh`
Result: `Results: 193 passed, 0 failed`

Command: `bash tests/codex/run-unit-tests.sh`
Result: `Results: 10 suites passed, 0 suites failed / All unit tests passed.`

Command: `bash tests/smart-compress/run-tests.sh`
Result: `Results: 87 passed / 0 failed`

All seven covering test suites passed after the fixes. Commit SHA: `2ade665f1356714a3d292f5a3210f78127667c0d`.

## Round 2

Findings addressed: M1, M2, M3 (all in `skills/multi-code-review/SKILL.md`).

- [M1] Reworded the "Before round 1 — the prompt directory" heading and
  paragraph to "Before the first round this controller runs": `mktemp -d`
  runs once per controller, before round 1 or before the round a resumed
  invocation continues at; stated that a resumed controller always creates
  its own fresh directory because the path is never logged, so file names
  stay unique by construction; added a rule for the path going missing from
  context mid-invocation — the controller never guesses it, never searches
  for it, never runs `mktemp -d` a second time, and falls back to inline
  dispatch for the rest of the invocation (as for a `mktemp -d` failure),
  stating this in the completion report.
- [M2] Changed the shown fill-command template's `CARRIED_BLOCK` argument
  from the inline placeholder `'CARRIED_BLOCK=<carried block>'` to the real
  `@<file>` form `'CARRIED_BLOCK=@<PROMPT_DIR>/round-1-carried.txt'`, and
  added a note underneath that every other round passes the empty value
  `'CARRIED_BLOCK='`, with every `NAME=` argument staying single-quoted.
- [M3] Added words to the "Round `i`, verification cycle `c`, reviewers"
  row's Value files cell stating that a verification cycle never reuses
  `round-1-carried.txt` and always passes the empty `CARRIED_BLOCK=`,
  because carried-findings triage happens on round 1 only. File names in
  the table were not changed.

Covering tests re-run:

Command: `bash tests/reviewer-templates/run-tests.sh`
Result: `Results: 55 passed, 0 failed`

Command: `bash tests/in-run-rulings/run-tests.sh`
Result: `Results: 496 passed, 0 failed`

Command: `bash tests/fill-prompt/run-tests.sh`
Result: `Results: 81 passed, 0 failed`

Command: `bash tests/writing-plans/run-tests.sh`
Result: `Results: 15 passed, 0 failed`

Command: `bash tests/sdd-scripts/run-tests.sh`
Result: `Results: 193 passed, 0 failed`

Command: `bash tests/codex/run-unit-tests.sh`
Result: `Results: 10 suites passed, 0 suites failed. All unit tests passed.`

Command: `bash tests/smart-compress/run-tests.sh`
Result: `Results: 87 passed / 0 failed`

All seven covering test suites passed after the fixes. Commit SHA:
`f93e9e6a191e3d5638b730ea8e1cce93be0c6aee`.

## Round 2

Findings addressed: I1, M1, M2.

- [I1] `skills/multi-code-review/SKILL.md`, Procedure step 2 sub-step 2: replaced the ambiguous "on every other round" sentence after the shown fill command with the three explicit cases — round 1 WITH a carried list uses `'CARRIED_BLOCK=@<PROMPT_DIR>/round-1-carried.txt'`; round 1 WITHOUT a carried list, and every later round, use the empty value `'CARRIED_BLOCK='`, because step 1 only writes `round-1-carried.txt` when there is a carried list, and passing the `@<file>` form otherwise makes the script exit 5.
- [M1] `skills/multi-code-review/scripts/fill-prompt.js`, `writeAtomic`: now exits 5 (message on stderr naming the path) before any write when `--out` already exists, so a prompt file already written is never silently replaced; updated the function's comment and the top-of-file exit-code comment accordingly.
- [M2] `skills/multi-code-review/scripts/fill-prompt.js`, `main`/`dropTrailingBlank`: moved the trailing-blank-line drop to run on the filled output instead of the pre-fill dedented body, so a template whose last body line is a whole-line placeholder given the empty value no longer leaves two trailing newlines; updated `dropTrailingBlank`'s comment to describe the new ordering requirement.

Tests added to `tests/fill-prompt/run-tests.sh` (new section "8. Round 2 fixes: refuse to overwrite --out, and trailing blank after fill"): filling onto an existing `--out` exits 5 and leaves the existing file's content unchanged (M1); a template whose last body line is a whole-line placeholder given the empty value produces output ending in exactly one newline (M2).

Covering tests:

Command: `bash tests/fill-prompt/run-tests.sh`
Result: `Results: 86 passed, 0 failed`

Command: `bash tests/reviewer-templates/run-tests.sh`
Result: `Results: 55 passed, 0 failed`

Command: `bash tests/in-run-rulings/run-tests.sh`
Result: `Results: 496 passed, 0 failed`

Command: `bash tests/writing-plans/run-tests.sh`
Result: `Results: 15 passed, 0 failed`

Command: `bash tests/sdd-scripts/run-tests.sh`
Result: `Results: 193 passed, 0 failed`

Command: `bash tests/codex/run-unit-tests.sh`
Result: `Results: 10 suites passed, 0 suites failed. All unit tests passed.`

Command: `bash tests/smart-compress/run-tests.sh`
Result: `Results: 87 passed, 0 failed`

All seven covering test suites passed after the fixes. Commit SHA:
`32ecce86b51b9f578c1b96a7b75c3936734ee189`.
