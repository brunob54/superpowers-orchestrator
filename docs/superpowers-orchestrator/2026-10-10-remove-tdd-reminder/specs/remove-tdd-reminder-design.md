# Remove the TDD reminder of the stop hook — design

Date: 2026-10-10. Release: v7.71.0. Base: `main` at `a75c3ec` (v7.70.0).
All line numbers in this document refer to commit `a75c3ec`.

## 1. Decision and reasons

The stop hook `hooks/stop-reminders.js` runs when Claude finishes a reply. It
can block the stop with a list of reminders; Claude then reads them and writes
another reply (Claude Code hooks reference, https://code.claude.com/docs/en/hooks,
section "Stop decision control": the `reason` of a block "Tells Claude why it
should continue"; see also the comment at `hooks/stop-reminders.js` lines
61-67). One of the five reminders is the **TDD reminder** (TDD means
test-driven development: the test is written before the code). Its text is
"TDD reminder: N source file(s) modified without test changes: ...".

The user decided on 2026-10-10 to remove the TDD reminder completely, and to
remove the name `tdd` from the names that the environment variable
`SUPERPOWERS_STOP_REMINDERS_OFF` accepts, with no compatibility alias ("there
are not many people using this plugin. Let's keep it simple."). The first three
reasons were measured or reproduced on 2026-10-10 in the owner's session; the
scripts and test repositories were temporary and are not kept. The fourth is a
judgment.

- **False alarms are built into the rule.** Only an edited test file silences
  the reminder; running the existing tests does not. A comment-only change
  fires it: in a headless run, Claude added one comment line to `app/calc.py`,
  the reminder fired, and Claude answered it with a second reply ("A comment
  line does not change what the code does, so no test is needed").
- **It is blind to edits made through Bash.** `hooks/track-edits.js` logs only
  Edit and Write calls (line 319). For a Bash call, Claude Code itself records
  the files the command changed, in the field `bashEditDiff` of the tool result
  (named in `hooks/bash-compress-hook.js` line 71; documented in the hooks
  reference, section "Bash"). Method: the owner's local transcripts of
  2026-09-06 to 2026-10-10 (143 sessions, main sessions and subagents) were
  read; each Edit or Write call counted as one file change, and each Bash call
  whose `bashEditDiff` listed a changed file counted as one; a source file is
  one with an extension that `SOURCE_PATTERNS` (line 134) matches; files in
  temporary or scratch folders were left out. In the 46 sessions whose
  transcripts carry `bashEditDiff`, 162 of 337 source-file changes (48%) were
  made through Bash.
- **It has a path defect.** `TEST_PATTERNS` (line 120) is matched against the
  absolute path, so a repository under any folder named `test` or `tests`
  (any letter case) never gets the reminder. Reproduced in two fresh
  repositories.
- **Its gain is small** (the owner's judgment, not a measurement). The
  workflow skills (test-driven-development, plans
  with tests first) are the main source of test-first discipline; the
  reminder was only a small addition to them.

## 2. Scope and non-goals

In scope:

- Remove the TDD reminder from `hooks/stop-reminders.js`, together with every
  helper that only it uses.
- `tdd` becomes an unknown name in `SUPERPOWERS_STOP_REMINDERS_OFF`.
- Remove or rewrite the tests that depend on the TDD reminder.
- Update the user documentation and the architecture documents.
- Release v7.71.0 with the release checklist of `CLAUDE.md` (section
  Releases).

Non-goals:

- **No change to the other four reminders** (commit, decision-log, state-md,
  session-log-size): same conditions, same texts, same order.
- **No change to the edit log or to `hooks/track-edits.js`** other than one
  comment. Three remaining reminders read the edit log.
- **Bash-made edits stay invisible to the edit log.** Logging them (from
  `tool_response.bashEditDiff.changedFiles`) is a separate, later release.
- **The Codex adapter is not changed.** `hooks/codex/stop-adapter.js` keeps its
  own copy of a TDD reminder (lines 199-207), its tests
  (`tests/codex/test-stop-adapter.js`) and its documents (`.codex/INSTALL.md`,
  `tests/codex/post-push-validation-checklist.md`) stay as they are. Codex has
  been documented as unsupported since 2026-09-21 (user decision on
  2026-10-10).
- **History is not rewritten:** old `RELEASE-NOTES.md` entries, the closed work
  log `docs/worklogs/group-a-fixes.md` (its four accepted limits about
  `isTestFile`, lines 103-107, stay; user decision on 2026-10-10),
  `docs/orchestration-issues-closed-rows.md`, and earlier topic folders under
  `docs/superpowers-orchestrator/`.
- No change to skills, `hooks/skill-rules.json` (its `tdd` keyword routes to
  the test-driven-development skill and is unrelated), or the hook entries of
  the wiring files (`hooks/hooks.json`, `plugin.universal.yaml`,
  `hooks/codex-hooks.json`, `hooks/hooks-cursor.json`). The version line of
  `plugin.universal.yaml` (line 7, checked by
  `tests/codex/test-version-files.js`) changes as part of the release.
- **Accepted limit: the cleanup of per-session files runs less often.** The
  7-day cleanup of per-session files (`removeOldSessionFiles`) runs only inside
  `setGuard` (`hooks/stop-reminders.js` lines 114-117), which runs only when the
  hook blocks (line 751). The TDD reminder had the widest condition of all the
  reminders, so after this change the hook blocks less often and the cleanup
  runs less often. Any block of the commit, decision-log, state-md or
  session-log-size reminder still runs the cleanup. For a user whose sessions
  get none of these blocks (for example a user who switched off both `commit`
  and `decision-log` and has no `state.md` or oversized `session-log.md` in the
  session folder), the cleanup stops completely, and the per-session files
  collect in `~/.claude/hooks-logs/` (measured on the owner's computer on
  2026-10-10: 26 edit logs, about 240 KB in one 7-day window). Only the cleanup
  itself reads that folder as a whole, so the effect is disk use only. This
  release does not move the cleanup.
- **Accepted limit: the session summary appears less often.** The "Session
  summary: ..." line is shown only inside a block of another reminder: a
  summary alone gives `{}` (`hooks/stop-reminders.js` lines 744-748; the test
  comment in `tests/codex/test-track-edits.js` near line 693 says the same).
  With the TDD reminder gone, the hook blocks less often, so the summary
  appears less often. This release does not change that.

No decision in this design matched the prior-art trigger predicate.

## 3. Architecture after the change

The data flow does not change: `track-edits.js` appends Edit and Write calls
to the per-session edit log `~/.claude/hooks-logs/edit-log-<session id>.txt`;
at a stop, `stop-reminders.js` reads the recent edits, builds the reminders,
and blocks the stop when at least one reminder is due. The only change is that
`generateReminders` no longer builds the TDD reminder.

### 3.1 `hooks/stop-reminders.js`

Remove:

- `TDD: 'tdd'` from the `REMINDER` object (line 44). Because
  `KNOWN_REMINDER_NAMES` is `Object.values(REMINDER)` (line 51), `tdd` becomes
  an unknown name with no other change.
- The TDD block in `generateReminders` (lines 525-542): the `sourceFiles` and
  `testFiles` lists and the reminder text. `editedPaths` (line 524) stays,
  because the commit reminder uses it.
- The helpers that only the TDD block uses: `isTestFile` (line 158),
  `TEST_PATTERNS` (line 120), `isBackAtCommittedState` (line 382),
  `firstEditTimeMs` (line 403), `formatFileList` (line 417), `MAX_NAMED_FILES`
  (line 409) and its comment (lines 407-408), `SECOND_MS` (line 356; its only
  use is line 397).
- The exports `isSourceFile` and `isTestFile` (lines 777-778). No remaining
  test imports them.

Keep:

- `isSourceFile`, `SOURCE_PATTERNS` and `CONFIG_PATTERNS`: the state-md
  reminder uses `isSourceFile` (line 628).
- All git helpers (`gitStdout`, `GIT_READ_ONE_FILE`, `gitReaderForFile`,
  `nearestExistingFolder`, `GIT_STATUS`, `ALL_UNTRACKED_FILES`,
  `GIT_TIMEOUT_MS`, `storedPath`): the commit reminder uses them through
  `countFilesWithUncommittedChanges` (line 472).
- The 2-minute guard (`shouldFire`, the `stop-hook-fired-<session id>.lock`
  file) and the `stop_hook_active` check. The commit reminder cannot always
  be cleared by the model either (the user may want the files uncommitted), so
  the guard still limits how often a block repeats.

Change only the text of:

- the file header (line 6: "reminders about TDD, verification, and commit
  hygiene");
- the comment with the example `"commit,tdd"` (lines 37-41) — the new example
  uses two names that remain, for example `"commit,state-md"`;
- the docstring at line 698 ("(TDD, commit, ...)");
- the guard comment at lines 708-711, which names "the TDD reminder" as the
  reminder that the model cannot clear — it names the commit reminder instead.

### 3.2 `hooks/track-edits.js`

Only the header comment at lines 13-16, which gives the TDD reminder as the
reason for the scratchpad exclusion ("made the stop hook ask for tests of a
scratch script"). The exclusion stays, and the comment states the reason that
still holds: a logged scratch file would trigger the decision-log reminder (a
scratch `SKILL.md`, `specs/*.md` or `plans/*.md` file counts as significant,
`isSignificantSession`, lines 598-611) and the state-md reminder (source files
edited after `state.md`, lines 621-641). The exclusion also keeps
the files of a test-fixture repository in the scratchpad out of the commit
reminder's count: that reminder runs git in the folder of each logged file
(`gitReaderForFile`, lines 350-354), so it counts a scratch file whenever the
file lies inside a git repository (`hooks/track-edits.js` lines 156-158 name
this case).

## 4. Interfaces and contracts

- **Stop hook output.** Unchanged in shape: `{"decision":"block","reason":
  "<stop-hook-reminders>\n...\n</stop-hook-reminders>"}` when at least one
  reminder is due, else `{}`. No reason text starts with "TDD reminder:" any
  more, in any state.
- **`SUPERPOWERS_STOP_REMINDERS_OFF`.** The accepted names are `commit`,
  `decision-log`, `state-md`, `session-log-size`. The name `tdd` is treated like
  any other unknown name: it switches nothing off, and the existing
  unknown-name warning (`unknownNameWarning`, line 68) names it in the next
  block. When no reminder is due, nothing blocks, so nothing shows the warning;
  this is the existing behaviour for every unknown name.
- **Exports of `stop-reminders.js`.** `isSourceFile` and `isTestFile` are no
  longer exported. All other exports stay.

## 5. Error handling

No new error path. The removed code ran git per named file
(`isBackAtCommittedState`); removing it removes those git calls at a stop. The
remaining git calls (commit reminder) keep their current error handling.

## 6. Testing strategy

The fast suites listed in `CLAUDE.md` (section Testing) must all exit 0 after
the change, each run as its own command. In addition,
`bash tests/context-management/run-tests.sh` must exit 0, run on its own: it is
not in that list and no listed suite calls it, but it pins line 193 of
`docs/architecture/project-memory.md`, which this change rewrites (§6.3).

### 6.1 `tests/codex/test-stop-reminders.js`

Delete the tests of the TDD reminder itself:

- line 112 "Test-file detection recognizes tests/codex/test-*.js naming";
- the `tdd` scenario at lines 645-649, which generates the tests at lines 689
  and 695 and the subagent test at line 1612;
- lines 760, 769, 776 (names files, full path, five files);
- line 807 (the six `isTestFile(...)` cases) and line 818 ("latest_report.py");
- the section heading and comment at lines 753-759, whose three tests (760,
  769, 776) are deleted;
- the case `${AGENT_WORKTREE}/hooks/a.js` of `IGNORED_WORKTREE_EDITS` (label
  at line 352). After the change, one edit of that path cannot produce any
  reminder even without the worktree filter (it is not a plugin hook file, one
  file is fewer than five, and there is no `state.md`), so the case would pass
  for any code. The three SKILL.md cases (lines 351, 353, 354) still test the
  filter and stay;
- the restored-file tests from line 944 to line 1222 (about 30 tests) and the
  heading of that section at lines 848-857. The helper block at lines 859-942
  is **not** deleted as a whole: the helpers it holds that the commit section
  still uses stay where they are (list below), and the deleted heading is
  replaced by a one-line comment naming them as git helpers of the commit
  section.

Some tests use the TDD reminder only as the block they observe. Deleting them
would silently remove the coverage of shared behaviour, so each one is
rewritten to observe a reminder that is still produced, and keeps its check.
The observed reminder is the simplest one that can carry the check:

- **Decision-log reminder**, arranged with the existing helper
  `arrangeDueBlock` (line 475; one `SKILL.md` edit, no git), which the tests
  T2b to T2g already use as their observed block:
  - line 123 "When reminders exist: emits decision+reason ...";
  - lines 727, 736, 743 (unknown-name warnings through `TDD_SCENARIO`). Their
    switch values (line 728 `'commit,tdd commit, state.md'`, line 737
    `'commit'`) stay unchanged: they switch off the commit reminder, and the
    decision-log reminder still makes the block that carries the warning.
- **Commit reminder** (git repository, at least five uncommitted edited
  files), only where the check needs it:
  - line 396 "Counts a source edit that is 10 minutes old" and line 401 "31
    minutes old": only the commit and state-md reminders read the 30-minute
    window. Test 401 has a positive control (§8 item 2);
  - line 825 "A React hook file ..." (its second assertion), see below;
  - line 715 "Names are trimmed ... other reminders stay" (through
    `arrangeCommitAndTdd`, line 709), see below.

**Test 715.** It arranges the commit scenario plus one due decision-log
reminder: one edit of `SIGNIFICANT_FILE` (line 415), appended to the edit log
**after** the commit arrangement has written it (that arrangement rewrites the
edit log with `writeFileSync`, line 91, so an earlier entry would be lost
without an error), with no save marker file (`markerFile`) newer than that
edit. **Positive control first:** without the switch, the same arrangement
gives a block that holds both "Commit reminder:" and "Decision log:". Then,
with the switch value of line 716 unchanged (`' Commit ,unknown '`), the block
holds "Decision log:" and no "Commit reminder:".

**Test 825** ("A React hook file ..."): its second assertion used the TDD
reminder to prove that the edit of `src/hooks/useAuth.js` was read. In the
rewrite, `useAuth.js` is one of exactly five uncommitted edited files in a git
repository, and the test asserts the text "Commit reminder: 5 files". If that
edit were not read, the count would be 4 and no commit reminder would
appear.

**Test 144** ("Active guard suppresses reminder output") is deleted, not
rewritten: T2b (line 461, "the stop guard of this session still silences its
next stop") already checks the guard after a real first block.

**Order in the file.** The helper `test()` (lines 30-32) runs each test at
once, so a test cannot use a `const` that is declared further down. Every
rewritten test (lines 123, 396, 401, 715, 727, 736, 743 and 825) moves to
one new section placed directly after the last test of the commit section, so
that every constant and helper it uses is already declared when it runs. The
new titles of tests 396 and 401 describe the commit arrangement: "Counts edits
that are 10 minutes old" and "Ignores edits that are 31 minutes old".

The commit reminder fires only when at least `COMMIT_REMINDER_MIN_FILES` (5,
line 505) edited files are still uncommitted, so each rewritten test that
observes it arranges at least five such files. The plan names, for each rewritten test, the
arrangement it uses. The delete list and the rewrite list above are complete:
a test outside both lists that fails after the change stops the run for a
ruling; it is not changed to make it pass.

In the state-md scenario (lines 671-677), remove the `tests/test-a.js` edit,
which exists only to silence the TDD reminder.

Add two tests:

- **Regression test of the removal:** one edit of the source file
  `/project/src/app.js` (a fixed absolute path that does not exist on disk,
  lies outside every temporary folder and outside every folder named `test`
  or `tests`) inside the 30-minute window, with no test edit, no significant
  file and fewer than five files, gives `{}`. The test is built with the
  existing `evaluateEdits` or `evaluateStop` helper, which gives a fresh
  temporary HOME and `cwd` (so untracked `state.md` or `session-log.md` files
  of the checkout cannot change the result), and in the same HOME it asserts
  that `getRecentEdits(<the test's session id>)` returns exactly one entry, so
  that `{}` cannot come from an edit log that was never read. The plan shows
  that this test fails at `a75c3ec` (where the TDD reminder fires for it)
  before the removal makes it pass.
- With `SUPERPOWERS_STOP_REMINDERS_OFF=tdd` and a due commit reminder, the
  block contains the commit reminder and an unknown-name warning that names
  `tdd`.

Comments and labels whose text refers to the removed reminder or to deleted
tests are changed: the comment at line 220; lines 392-393 ("The reminder about
source edits ..."); the section heading at lines 753-755; lines 786-792 (the
Python test pattern that "silenced the TDD reminder"); lines 1546-1547 ("See
the test of the restored file above") — the explanation of the git index at
lines 1208-1211, which that comment points to, moves next to it before the
test at line 1212 is deleted; and line 1627 ("with no test edit").

Helpers and constants that become unused in the test file are removed:
`SOURCE_NAME`, `OTHER_SOURCE_NAME`, `NEW_SOURCE_NAME`, `MIDDLE_COMMIT_AGE_MS`,
the two `EDIT_*_MIDDLE_COMMIT_MINUTES`, `repoWithCommittedSource`,
`recordEditsAtAges`, `assertReminderNames`, `TDD_SCENARIO`,
`arrangeCommitAndTdd`, `PYTHON_TEST_FILE_CASES` (line 796) and `SOURCE_EDIT`
(line 394). Helpers that the commit section (line 1224 onward) or line 655
still use stay: `git`, `gitDate`, `SECOND_MS` (the test file's own),
`initRepo`, `writeRepoFile`, `COMMITTED_TEXT`, `EDITED_TEXT`, `commitAll`,
`repoWithCommittedFiles`, `recordEdits`, `EDIT_AGE_MINUTES`,
`FIRST_COMMIT_AGE_MS`, `assertNoReminder`. The implementer confirms each of
these lists with a search before removing anything; a name the search shows
still in use stays.

### 6.2 `tests/codex/test-track-edits.js`

T19 (line 495) and T20 (line 511) mainly test edit logging: their first
assertion checks the line count of the edit log (0 or 1). Only their second
assertion uses the TDD reminder. Remove that second assertion and keep the
line-count assertion; change a test title that names the TDD reminder. Remove
line 466 (`TDD_REMINDER`). Rewrite the comment at lines 461-463 so that it
gives the reason that still holds (the same reason as in §3.2). Lines 464-465
(`SCRATCHPAD_FIELD`, `SCRATCH_FILE`) stay: the remaining scratchpad tests use
them.

### 6.3 `tests/context-management/run-tests.sh`

Line 870 compares the whole of line 193 of `docs/architecture/project-memory.md`
("reminds the AI about source edits without test changes, ..."). The test and
the document line change together.

### 6.4 Runner

`tests/codex/run-unit-tests.sh` (lines 45, 46, 65) lists the test files; it
changes only if a file is added or removed.

## 7. Documentation

- `README.md`: the mermaid label "track-edits — TDD reminders" (line 123); "TDD
  + commit nudges" (line 129); the list of names (line 423); "Logs file changes
  for TDD reminders" (line 432); the stop hook entry (line 434: "Surfaces TDD
  reminders", "`tdd` removes \"TDD reminder\"", and the sentence "Since v7.58.0
  the TDD reminder asks git ..."); the same entry's "session summary after
  each response turn" becomes a statement that the summary appears only inside
  a block of another reminder (also in the line-129 diagram text if it names
  the summary). The README version badge and the two
  `v6.7.0–vX.Y.Z` ranges are part of the release checklist.
- `docs/guide/README.md`: the list of names (line 1530). Replace the two
  troubleshooting entries "The test-first reminder names a scratch file"
  (lines 1553-1560) and "The test-first reminder names a file that has no
  change" (lines 1562-1574) with one short entry: since v7.71.0 the Claude
  Code stop hook has no TDD reminder; if a session still shows one, the
  installed copy is older (§1 of the guide), or the message comes from the
  unsupported Codex adapter, which keeps its own copy.
- `docs/architecture/agentic-workflow.md`: line 35 ("logs file changes for TDD
  reminders") and line 44 ("5 source files modified without tests").
- `docs/architecture/project-memory.md`: line 193, together with the test of
  section 6.3.
- `RELEASE-NOTES.md`: a v7.71.0 entry that starts with the three-line summary
  (Problem, Change, Effect). The Effect line says that a user who has `tdd` in
  `SUPERPOWERS_STOP_REMINDERS_OFF` should remove it, because it is now reported
  as an unknown name — but, for a settings file that several installations
  read (a committed project `.claude/settings.json`, or a user settings file
  synced between computers), only after every one of them runs v7.71.0 or
  later; until then the warning is harmless. It also says that the unsupported
  Codex adapter still has its own copy of the reminder.

## 8. Failure modes

1. **Lost coverage of shared behaviour** (would be critical). The output
   format, the guard, name trimming and the unknown-name warning were tested
   through the TDD reminder. Deleting those tests would leave the shared code
   untested. Section 6.1 rewrites them against the decision-log or the commit
   reminder.
2. **Rewritten tests that do not fire** (minor). The commit reminder needs at
   least five uncommitted edited files; a test that arranges fewer would pass
   for the wrong reason. Section 6.1 requires at least five. A rewritten test
   that expects a block asserts that the reminder it observes is in it. A rewritten
   test that expects no block (the 31-minute edit at line 401) has a positive
   control in the same test: the same arrangement without the condition under
   test (edits 29 minutes old) must produce the commit reminder. **Each
   positive control and the case it protects run in separate temporary HOME
   folders** (separate `evaluateStop` or `evaluateEdits` calls): a control's
   block writes the 2-minute guard file (`setGuard`, line 751), and a second
   stop in the same HOME would then return `{}` because of the guard, so the
   protected case would pass for the wrong reason. A test whose key assertion is that one
   reminder is absent (test 715) has the same kind of positive control, and a
   test that must prove one edit was read (test 825) asserts an exact file
   count (§6.1).
3. **A user who set `tdd`** (minor, accepted by the user). The name now
   produces an unknown-name warning in the next block. The release note tells
   the user to remove it.
4. **Codex keeps a TDD reminder** (minor, accepted). The README describes the
   Claude Code stop hook; the release note states the Codex exception.

## 9. Rollout

Update the plugin and restart the CLI (command-line interface). Nothing to
migrate, except removing `tdd` from `SUPERPOWERS_STOP_REMINDERS_OFF` where a
user set it. In a settings file that several installations read, remove it
only after all of them run v7.71.0 or later; until then the unknown-name
warning is harmless.
