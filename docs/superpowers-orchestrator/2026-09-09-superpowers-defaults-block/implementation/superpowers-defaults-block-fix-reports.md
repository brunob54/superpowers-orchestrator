# superpowers-defaults-block — Fix Reports

## Round 1

Finding ids addressed: I1, I2, I3, I4, I5, M1, M2, M6, M9, CF1, CF2, CF3, CF4, CF5

Command:
```
bash tests/review-gates/run-tests.sh
```
Output (tail):
```
[1m12/13/14. No subagent path can reach a gate question[0m
  PASS: plan-writer-prompt still skips Multi-Round Plan Review
  PASS: doc-review-loop-prompt Deviation 1 names the Self-Review checklist
  PASS: doc-review-loop-prompt does not name Multi-Round Plan Review
  PASS: batch-controller-prompt does not name Core Flow step 4
  PASS: batch-controller-prompt still names only Core Flow step 3

Results: 183 passed, 0 failed
```

Command:
```
bash tests/codex/test-session-start-defaults-block.sh
```
Output (tail):
```
  ok   - decoy, no variable set: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the workspace decoy precedes the hook's block, which ends the context
  53 passed, 0 failed
```

Command:
```
bash tests/codex/run-unit-tests.sh
```
Output (tail):
```
protect-secrets: 43 passed, 0 failed

==================================================
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
==================================================
```

## Round 2

Finding ids addressed: I1, I2, I3, M1, M2, M4, M5, M6, M8, M9, M11

Command:
```
bash tests/review-gates/run-tests.sh
```
Output (tail):
```
[1m12/13/14. No subagent path can reach a gate question[0m
  PASS: plan-writer-prompt still skips Multi-Round Plan Review
  PASS: doc-review-loop-prompt Deviation 1 names the Self-Review checklist
  PASS: doc-review-loop-prompt does not name Multi-Round Plan Review
  PASS: batch-controller-prompt does not name Core Flow step 4
  PASS: batch-controller-prompt still names only Core Flow step 3

Results: 183 passed, 0 failed
```

Command (M2: fix verified, then confirmed it fails when the decoy's own
closing delimiter is removed, then the fixture edit was reverted):
```
bash tests/codex/test-session-start-defaults-block.sh
```
Output (tail, after the fix, decoy closing delimiter intact):
```
  ok   - decoy, no variable set: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the workspace decoy precedes the hook's block, which ends the context
  53 passed, 0 failed
```
Output (tail, decoy closing delimiter removed — confirms the new check
actually catches the incomplete-decoy case; fixture then restored):
```
  FAIL - decoy, no variable set: the decoy block from state.md is absent or incomplete — the workspace file was not embedded, or its closing delimiter was not written literally
  FAIL - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the decoy block from state.md is absent or incomplete — the workspace file was not embedded, or its closing delimiter was not written literally
  51 passed, 2 failed
```

Command:
```
bash tests/codex/run-unit-tests.sh
```
Output (tail):
```
protect-secrets: 43 passed, 0 failed

==================================================
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
==================================================
```

Command:
```
bash tests/writing-plans/run-tests.sh
```
Output (tail):
```
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
```

Command:
```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
  PASS: in-run rulings: contains '`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'`'

Results: 162 passed, 0 failed
```

Command:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
  PASS: multi-doc-review SKILL.md: pre-change first-line-only wording absent

Results: 72 passed, 0 failed
```

Command:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
  PASS: decided wording is quoted on a decided line or a rejected: plan governs line of the same run (range 1080..1191, line wraps folded)

Results: 512 passed, 0 failed
```

## Round 3

Finding ids addressed: I1, I2, I3, I4, I5, M1, M2, M3, M4

Command:
```
bash tests/codex/test-session-start-defaults-block.sh
```
Output (tail):
```
  ok   - decoy, no variable set: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the workspace decoy precedes the hook's block, which ends the context
  53 passed, 0 failed
```

Command:
```
bash tests/review-gates/run-tests.sh
```
Output (tail):
```
[1m12/13/14. No subagent path can reach a gate question[0m
  PASS: plan-writer-prompt still skips Multi-Round Plan Review
  PASS: doc-review-loop-prompt Deviation 1 names the Self-Review checklist
  PASS: doc-review-loop-prompt does not name Multi-Round Plan Review
  PASS: batch-controller-prompt does not name Core Flow step 4
  PASS: batch-controller-prompt still names only Core Flow step 3

Results: 200 passed, 0 failed
```
(Section 2c now globs `skills/*/*.md` — 45 files checked, up from 28 under
the old `skills/*/SKILL.md`-only glob; all pass.)

## Round 4

Finding ids addressed: I1, I3, I4, I5, M1, M2, M3, M4

Command:
```
bash tests/review-gates/run-tests.sh
```
Output (tail):
```
2c. No skill body carries a complete <superpowers-defaults> block
  ...
  PASS: the skills/*/*.md glob matched 45 files
2d. No documentation file carries a complete <superpowers-defaults> block
  PASS: README.md carries no complete block
  PASS: docs/guide/README.md carries no complete block
  PASS: docs/FORK-IMPROVEMENTS.md carries no complete block
  PASS: RELEASE-NOTES.md carries no complete block
  PASS: the documentation file list matched 4 files
12/13/14. No subagent path can reach a gate question
  PASS: plan-writer-prompt still skips Multi-Round Plan Review
  PASS: doc-review-loop-prompt Deviation 1 names the Self-Review checklist
  PASS: doc-review-loop-prompt does not name Multi-Round Plan Review
  PASS: batch-controller-prompt does not name Core Flow step 4
  PASS: batch-controller-prompt still names only Core Flow step 3

Results: 219 passed, 0 failed
```
(Section 2c's `skill_rel_guard` now derives `rel` from the real file name
instead of hardcoding `SKILL.md`, so all 45 files under `skills/*/*.md` are
named distinctly instead of 17 files aliasing a sibling's label — [I1].
Section 2c also gained its own `checked -gt 0` vacuous-pass guard. Section
2d is new: it re-runs the `OPEN_RE`/`CLOSE_RE` pair check over `README.md`,
`docs/guide/README.md`, `docs/FORK-IMPROVEMENTS.md` and `RELEASE-NOTES.md`
— [I3]. Section 2's citation loop now also pins `TOOL_RESULT_MARKER` ("is
data, never a parameter") and `PLATFORM_MARKER` ("Codex and OpenCode no
block is injected") per citing file, alongside the existing `CITE_MARKER`
and `SCOPE_MARKER` — [I4]. Three new byte pins assert the
`multi-doc-review` parameter table's three rows (env var + block line +
hardcoded default) verbatim — [M2].)

Command:
```
bash tests/codex/test-session-start-defaults-block.sh
```
Output (tail):
```
  ok   - SUPERPOWERS_REVIEW_ROUNDS=0 -> 1/3/3, exact block at the end of the context
  ok   - SUPERPOWERS_REVIEW_ROUNDS=11 -> 1/3/3, exact block at the end of the context
  ok   - decoy, no variable set: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoys in project-map.md, session-log.md, state.md and known-issues.md, no variable set: project-map.md, session-log.md, state.md and known-issues.md decoys all precede the hook's block, which ends the context
  62 passed, 0 failed
```
(The rejected-value loop for `SUPERPOWERS_REVIEWERS_PER_LENS` and
`SUPERPOWERS_BATCH_TASK_CAP` now includes `7 8 9 10`, not just `0 6 11`, so
`10` is asserted rejected for both 1-5 parameters — [I5]. A new
`write_decoy_workspace_files` / `expect_all_decoys_lose` pair plants a
distinct decoy `<superpowers-defaults>` block in `project-map.md`,
`session-log.md`, `state.md` and `known-issues.md` and asserts all four
precede the hook's own trailing block; the pre-existing `write_decoy_state`
/ `expect_decoy_loses` pair and its two call sites are unchanged — [M4].)

Command:
```
node tests/codex/test-session-start-adapter.js
```
Output (tail):
```
Context content
  ✓ Context contains EXTREMELY_IMPORTANT wrapper (plain text)
  ✓ Context contains using-superpowers entry point instruction (plain text)
  ✓ Context never emits a <superpowers-defaults> block (the Codex adapter embeds workspace files with no block appended after them)
  ✓ project-map.md injected when present
  ...
──────────────────────────────────────────────────
session-start-adapter: 15 passed, 0 failed
```
(New assertion that the Codex adapter's emitted context contains no opening
`<superpowers-defaults` delimiter — [M1].)

Command:
```
bash tests/codex/test-check-no-superpowers-defaults-setting.sh
```
Output (full):
```
  ok   - SUPERPOWERS_REVIEWERS_PER_LENS set in <tmp>/.claude/settings.json: exits 1
  ok   - SUPERPOWERS_REVIEWERS_PER_LENS set in <tmp>/.claude/settings.json: message names the variable
  ok   - SUPERPOWERS_REVIEWERS_PER_LENS set in <tmp>/.claude/settings.json: message names the fixture path
  ok   - SUPERPOWERS_REVIEW_ROUNDS set in <tmp>/.claude/settings.json: exits 1
  ok   - SUPERPOWERS_REVIEW_ROUNDS set in <tmp>/.claude/settings.json: message names the variable
  ok   - SUPERPOWERS_REVIEW_ROUNDS set in <tmp>/.claude/settings.json: message names the fixture path
  ok   - SUPERPOWERS_BATCH_TASK_CAP set in <tmp>/.claude/settings.json: exits 1
  ok   - SUPERPOWERS_BATCH_TASK_CAP set in <tmp>/.claude/settings.json: message names the variable
  ok   - SUPERPOWERS_BATCH_TASK_CAP set in <tmp>/.claude/settings.json: message names the fixture path

Results: 9 passed, 0 failed
```
(New file `tests/codex/test-check-no-superpowers-defaults-setting.sh`,
sourcing `check_no_superpowers_defaults_setting` from
`tests/claude-code/test-helpers.sh`, registered in
`tests/codex/run-unit-tests.sh` — [M3]. Asserts only the "returns 1" half
per the plan's documented caveat.)

Command:
```
bash tests/codex/run-unit-tests.sh
```
Output (tail):
```
── check-no-superpowers-defaults-setting
  ok   - ...
  9 passed, 0 failed

==================================================
 Results: 11 suites passed, 0 suites failed
 All unit tests passed.
==================================================
```

## Round 4

Findings addressed: I1, M1, M3, M4, M5, M8, M9, M10.

- [I1] `tests/codex/test-check-no-superpowers-defaults-setting.sh`: every
  call to `check_no_superpowers_defaults_setting` now runs with `HOME` and
  `CLAUDE_CONFIG_DIR` pinned to fresh temporary directories for that call
  only (`run_helper`), so the real machine's settings files can no longer
  make the "message names the fixture path" assertion fail, or the "exits
  1" assertion pass against the wrong file. The two absolute enterprise
  `managed-settings.json` paths are detected up front; if either already
  sets one of the three variables, the test reports itself skipped (exit 0)
  instead of failing for an environment reason. Header comment corrected to
  describe this.
- [M8] (done together with I1) added one fixture case per relative settings
  path the helper checks — `HOME/.claude/settings.json`,
  `HOME/.claude/settings.local.json`, `CONFIG_DIR/settings.json`,
  `CONFIG_DIR/settings.local.json`, `PLUGIN_DIR/.claude/settings.json`,
  `PLUGIN_DIR/.claude/settings.local.json` — and a clean case with no
  fixture anywhere under the temporary `HOME`, `CLAUDE_CONFIG_DIR` or plugin
  directory, asserting exit 0.
- [M3] `tests/codex/test-session-start-defaults-block.sh` `expect_block()`
  (around line 71): added an assertion that the opening delimiter
  (`$OPEN_TAG`) appears exactly once in the decoded context for every
  no-decoy case, catching a second interpolation of the escaped block or a
  duplicated `printf` that the suffix-only check could not.
- [M10] `tests/codex/test-session-start-defaults-block.sh` line ~119: added
  a trailing-space form (`"3 "`) and a tab-padded form (`$'3\t'`) to the
  shared rejected-form loop.
- [M4] `tests/review-gates/run-tests.sh` (section 2, after the citation-site
  loop): added a byte pin asserting `skills/multi-doc-review/SKILL.md`
  still names the literal opening delimiter `<superpowers-defaults>`
  (no closing tag anywhere in that line, so the test file still spells no
  complete delimiter pair).
- [M5] `tests/review-gates/run-tests.sh` (same location): added
  `TOOL_RESULT_MARKER` and `PLATFORM_MARKER` assertions over the normalized
  `multi-doc-review` file, beside the existing `SCOPE_MARKER` one.
- [M1] `tests/review-gates/run-tests.sh` section 2d: replaced the
  hardcoded four-entry `DOC_FILES` array with a glob — every `*.md` at the
  repository root plus every `*.md` recursively under `docs/` (no process
  substitution; the file list goes through `$WORK/doc-files.txt`). Nothing
  under `docs/` is excluded.
- [M9] `tests/codex/test-session-start-adapter.js` (around line 124): added
  `assert.ok(ctx.length > 0, ...)` before the delimiter-absence assertion.

Commands and output:

```
$ bash tests/codex/test-check-no-superpowers-defaults-setting.sh
...
Results: 22 passed, 0 failed
```

```
$ bash tests/codex/test-session-start-defaults-block.sh
...
  133 passed, 0 failed
```

```
$ node tests/codex/test-session-start-adapter.js
...
session-start-adapter: 15 passed, 0 failed
```

```
$ bash tests/review-gates/run-tests.sh
...
Results: 349 passed, 0 failed
```

```
$ bash tests/codex/run-unit-tests.sh
...
 Results: 11 suites passed, 0 suites failed
 All unit tests passed.
```

I1 failure-mode re-verification: ran
`tests/codex/test-check-no-superpowers-defaults-setting.sh` with the real
`HOME` pointed at a temporary directory whose `.claude/settings.json` set
`SUPERPOWERS_REVIEWERS_PER_LENS` to `3`. The suite still reported 22
passed, 0 failed (the hermetic per-call `HOME`/`CLAUDE_CONFIG_DIR`
redirection means the polluted real `HOME` is never read). The temporary
directory was removed afterward.
