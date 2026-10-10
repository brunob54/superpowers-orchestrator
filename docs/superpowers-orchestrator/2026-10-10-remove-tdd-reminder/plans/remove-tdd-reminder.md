# Remove the TDD Reminder of the Stop Hook — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Remove the TDD reminder (TDD means test-driven development) from the Claude Code stop hook `hooks/stop-reminders.js`, together with every helper and test that only it used, update the documents, and release the change as v7.71.0.
**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-10-remove-tdd-reminder/specs/remove-tdd-reminder-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
**Architecture:** The data flow does not change: `hooks/track-edits.js` appends Edit and Write calls to the per-session edit log, and `generateReminders` in `hooks/stop-reminders.js` reads the recent edits and builds the reminders. The change deletes the TDD block of `generateReminders` and the helpers only that block uses. The tests are changed in three steps that keep every commit green: first the tests that used the TDD reminder only as the block they observe are rewritten to observe a reminder that stays (Task 1), then the tests and helpers that exist only for the TDD reminder are deleted while the hook still has it (Tasks 2 and 3), then the hook code is removed together with two new regression tests that fail before the removal and pass after it (Task 4). Documents (Task 5) and the release (Task 6) follow.
**Tech Stack:** Node.js (version 16.7 or later; the test files use `node:assert`, `fs`, `child_process`), Bash, git, Markdown. No dependency is added.
**Assumptions:** Assumes the tracked files named in each task are at the content they had at commit `a75c3ec` (the commits after it change documents only) — will NOT work if `hooks/stop-reminders.js`, `tests/codex/test-stop-reminders.js` or `tests/codex/test-track-edits.js` was edited since; every edit script stops with an "Anchor not found" or "Anchor is not unique" error in that case, and the run then stops for a ruling. Assumes every edit script runs from the repository root, with `node` on the path. Assumes `<scratch>` is a folder outside the repository (the session scratchpad directory): the scripts and helper files of this plan are written there and are never committed. Assumes `git` and `bash` are installed (the test files create git repositories). Assumes the two accepted limits of spec §2 (the cleanup of per-session files runs less often; the session summary appears less often) stay accepted — will NOT work as a reason to move `removeOldSessionFiles` or `setGuard`.
**Global Constraints:**
- The decision: remove the TDD reminder completely; remove the name `tdd` from the names that `SUPERPOWERS_STOP_REMINDERS_OFF` accepts, with no compatibility alias (spec §1: "there are not many people using this plugin. Let's keep it simple.").
- No change to the other four reminders (spec §2): same conditions, same texts, same order (commit, decision-log, state-md, session-log-size).
- No change to the edit log or to `hooks/track-edits.js` other than one comment (spec §2, §3.2). Bash-made edits stay invisible to the edit log.
- The Codex adapter is not changed (spec §2): `hooks/codex/stop-adapter.js` keeps its own copy of a TDD reminder; its tests (`tests/codex/test-stop-adapter.js`) and its documents (`.codex/INSTALL.md`, `tests/codex/post-push-validation-checklist.md`) stay as they are.
- History is not rewritten (spec §2): old `RELEASE-NOTES.md` entries, the closed work log `docs/worklogs/group-a-fixes.md`, `docs/orchestration-issues-closed-rows.md`, and earlier topic folders under `docs/superpowers-orchestrator/`.
- No change to skills, `hooks/skill-rules.json` (its `tdd` keyword routes to the test-driven-development skill and is unrelated), or the hook entries of the wiring files (`hooks/hooks.json`, `plugin.universal.yaml`, `hooks/codex-hooks.json`, `hooks/hooks-cursor.json`). The version line of `plugin.universal.yaml` changes as part of the release.
- Kept in `hooks/stop-reminders.js` (spec §3.1): `isSourceFile`, `SOURCE_PATTERNS`, `CONFIG_PATTERNS`, all git helpers (`gitStdout`, `GIT_READ_ONE_FILE`, `gitReaderForFile`, `nearestExistingFolder`, `GIT_STATUS`, `ALL_UNTRACKED_FILES`, `GIT_TIMEOUT_MS`, `storedPath`), the 2-minute guard (`shouldFire`, the `stop-hook-fired-<session id>.lock` file) and the `stop_hook_active` check, and `editedPaths` in `generateReminders`.
- Removed from `hooks/stop-reminders.js` (spec §3.1): `TDD: 'tdd'` of the `REMINDER` object, the TDD block of `generateReminders`, `isTestFile`, `TEST_PATTERNS`, `isBackAtCommittedState`, `firstEditTimeMs`, `formatFileList`, `MAX_NAMED_FILES` with its comment, `SECOND_MS`, and the exports `isSourceFile` and `isTestFile`.
- The accepted names of `SUPERPOWERS_STOP_REMINDERS_OFF` are `commit`, `decision-log`, `state-md`, `session-log-size`; `tdd` is treated like any other unknown name (spec §4). No reason text starts with "TDD reminder:" any more, in any state.
- Testing (spec §6): the fast suites listed in `CLAUDE.md` (section Testing) must all exit 0 after the change, each run as its own command; `bash tests/context-management/run-tests.sh` must also exit 0, run on its own. The delete list and the rewrite list of spec §6.1 are complete: a test outside both lists that fails after the change stops the run for a ruling; it is not changed to make it pass. A rewritten test that expects a block asserts the text of the reminder it observes; a rewritten test whose key check is an absence has a positive control that runs in a separate temporary HOME folder.
- Release (spec §2, §7; `CLAUDE.md` section Releases): v7.71.0. Bump the version in `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` (meta), the README version badge and the two `v6.7.0–vX.Y.Z` ranges of the README. The `RELEASE-NOTES.md` entry starts with the three-line summary (Problem, Change, Effect; near 100 words, 120 at most). Its Effect line tells a user who has `tdd` in `SUPERPOWERS_STOP_REMINDERS_OFF` to remove it, only after every installation that reads the settings file runs v7.71.0 or later, and says that the unsupported Codex adapter still has its own copy of the reminder.
- Writing style (user instruction for every document and code comment): plain, literal English; define every technical term at its first use; abbreviations are expanded at their first use in a file.

---

## File Structure

| File | Change | Task |
|---|---|---|
| `tests/codex/test-stop-reminders.js` | Rewrite the shared-behaviour tests (1); delete the tests, helpers and comments that exist only for the TDD reminder (2); add two regression tests and edit the state-md scenario (4) | 1, 2, 4 |
| `tests/codex/test-track-edits.js` | Remove the second assertion of T19 and T20 and the constant `TDD_REMINDER`; rewrite one comment | 3 |
| `hooks/track-edits.js` | One header comment | 3 |
| `hooks/stop-reminders.js` | Remove the TDD reminder and its helpers; four comments | 4 |
| `README.md`, `docs/guide/README.md`, `docs/architecture/agentic-workflow.md`, `docs/architecture/project-memory.md`, `tests/context-management/run-tests.sh` | Remove the TDD reminder from the documents; the test pins the sentence of `project-memory.md` | 5 |
| `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md` | Release v7.71.0 | 6 |

Not changed (spec §2): `hooks/codex/stop-adapter.js`, `tests/codex/test-stop-adapter.js`, `tests/codex/run-unit-tests.sh` (it lists test files; none is added or removed), `hooks/skill-rules.json`, the wiring files, the skills.

Premises tested while writing this plan (each command was run in the repository; the result is stated):

- `git ls-files --error-unmatch <path>` succeeds, and `git check-ignore -q <path>` finds no ignore rule, for all 14 files that the tasks change or commit: `hooks/stop-reminders.js`, `hooks/track-edits.js`, `tests/codex/test-stop-reminders.js`, `tests/codex/test-track-edits.js`, `tests/context-management/run-tests.sh`, `docs/architecture/project-memory.md`, `docs/architecture/agentic-workflow.md`, `docs/guide/README.md`, `README.md`, `RELEASE-NOTES.md`, `plugin.universal.yaml`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `VERSION`.
- `command -v node bash git` finds all three (Node v24.13.1).
- `git grep -n "isSourceFile\|isTestFile"` outside `hooks/codex`, `tests/codex/test-stop-adapter.js`, `RELEASE-NOTES.md` and `docs` finds uses only in `hooks/stop-reminders.js` and `tests/codex/test-stop-reminders.js`; `hooks/codex/stop-adapter.js` has its own copies and does not require `hooks/stop-reminders.js`.
- At the start, `bash tests/codex/run-unit-tests.sh` (26 suites) and `bash tests/context-management/run-tests.sh` (108 checks) both exit 0.

---

### Task 1: Rewrite the shared-behaviour tests to observe reminders that stay

**Files:**
- Modify: `tests/codex/test-stop-reminders.js`

**Security flag:** `none`

**Does NOT cover:** This task does not delete any test of the TDD reminder itself and does not change `hooks/` (Tasks 2 and 4). It does not change the `tdd` scenario of `REMINDER_SCENARIOS` or the constant `TDD_SCENARIO` (Task 2 removes them, with the last tests that use them). The constant `UNKNOWN_NAME_WARNING` stays: the new tests use it. It adds no regression test of the removal (Task 4).

**Contract:** One new section of `tests/codex/test-stop-reminders.js`, placed directly before the heading `// ── No commit reminder while a subagent is still running`, so after the last test of the commit section.
- Must hold: the section is named `Shared behaviour of the reminders` and holds exactly these tests, in this order: "When reminders exist: emits decision+reason, not Stop hookSpecificOutput", "Counts edits that are 10 minutes old", "Ignores edits that are 31 minutes old", "Names are trimmed and case-insensitive, unknown names are ignored, other reminders stay", "A block names each unknown name in the switch and lists the known names", "Known names only: the block has no unknown-name warning", "A repeated unknown name is listed twice in the warning (the parser keeps duplicates)", "A React hook file (src/hooks/useAuth.js) does not ask for a decision-log entry".
- Invariants: each test observes the decision-log reminder (through the existing helper `arrangeDueBlock`) or the commit reminder (a git repository with 5 uncommitted edited files); every test that expects a block asserts the text of the reminder it observes (`DECISION_LOG` or the commit reminder text), also the tests of the unknown-name warning; the test "Known names only: the block has no unknown-name warning" has a positive control (the same arrangement with the switch value `'commit,foo'` must give the warning) in a separate `evaluateStop` call, so in a separate temporary HOME folder; the switch values of the unknown-name tests are the old values (`'commit,tdd commit, state.md'`, `'commit'`, `'foo,foo'`, `' Commit ,unknown '`); the test "Ignores edits that are 31 minutes old" holds a positive control (the same arrangement with 29-minute-old edits must give the commit reminder) in a separate `evaluateStop` call, so in a separate temporary HOME folder; the test of the names holds a positive control (without the switch the block holds both the commit and the decision-log reminder); the React hook test asserts the text "Commit reminder: 5 files", which proves that the edit of `src/hooks/useAuth.js` was read (an unread edit gives a count of 4); this exact count is the key check of that test (spec §8 item 2), so the test needs no separate positive control, although its first assertion is an absence of the decision-log reminder. The old versions of these tests and the test "Active guard suppresses reminder output" are deleted (T2b already checks the guard after a real first block).
- Verification: `node tests/codex/test-stop-reminders.js` exits 0 with the hook unchanged; three mutations of a scratch copy of the hook each make the named test fail (Step 4); `git diff --stat` lists only `tests/codex/test-stop-reminders.js`.
- The titles and the helper names are descriptive and may change in a fix; the properties above bind.

- [x] **Step 1: Delete the old versions of the tests**

Save this script as `<scratch>/t1-cuts.js`. It deletes the old tests 123 and 144 (`When reminders exist ...`, `Active guard suppresses reminder output`), the two tests of the 30-minute window with their comment and constant `SOURCE_EDIT`, the helper `arrangeCommitAndTdd` with the test of the trimmed names, the three tests of the unknown-name warning, and the test of the React hook file. Every anchor must occur exactly once; the script stops with an error otherwise.

```js
const fs = require('fs');

const FILE = process.argv[2];
let text = fs.readFileSync(FILE, 'utf8');

/** Index of `anchor`, which must occur exactly once in the file. */
function anchorIndex(anchor) {
  const first = text.indexOf(anchor);
  if (first < 0) throw new Error(`Anchor not found: ${anchor}`);
  if (text.indexOf(anchor, first + 1) >= 0) throw new Error(`Anchor is not unique: ${anchor}`);
  return first;
}

/** Replace the text from `startAnchor` (included) up to `endAnchor` (not included). */
function replaceBetween(startAnchor, endAnchor, replacement = '') {
  const start = anchorIndex(startAnchor);
  const end = anchorIndex(endAnchor);
  if (end <= start) throw new Error(`End anchor is before start anchor: ${startAnchor} -> ${endAnchor}`);
  text = text.slice(0, start) + replacement + text.slice(end);
}

/** Replace the text `oldText`, which must occur exactly once. */
function replaceOnce(oldText, newText) {
  const start = anchorIndex(oldText);
  text = text.slice(0, start) + newText + text.slice(start + oldText.length);
}

// Test 'When reminders exist ...' and test 'Active guard suppresses reminder output'.
replaceBetween("test('When reminders exist: emits decision+reason, not Stop hookSpecificOutput'",
  "test('No reminders available emits {}'");

// The comment, SOURCE_EDIT and the two tests of the 30-minute window.
replaceBetween('// The reminder about source edits reads the edits of the last 30 minutes.',
  '// ── Save marker and stop guard of one session');

// arrangeCommitAndTdd and the test of the trimmed names.
replaceBetween('/** The commit scenario plus one source edit: two reminders are due. */',
  "const TDD_SCENARIO = REMINDER_SCENARIOS.find(s => s.name === 'tdd');");

// The three tests of the unknown-name warning.
replaceBetween("test('A block names each unknown name in the switch and lists the known names'",
  "test('An unknown name alone never makes the hook block'");

// The test of the React hook file.
replaceBetween("test('A React hook file (src/hooks/useAuth.js) does not ask for a decision-log entry'",
  "test('A hooks/*.js file beside a hooks.json asks for a decision-log entry'");

fs.writeFileSync(FILE, text, 'utf8');
```

Run: `node <scratch>/t1-cuts.js tests/codex/test-stop-reminders.js`
Expected: no output, exit status 0.

- [x] **Step 2: Insert the new section**

Insert the following block directly before the line that starts with `// ── No commit reminder while a subagent is still running` (use the Edit tool: the old string is that comment text up to `still running`, the new string is the block, then that same comment text). The new string is the block, one empty line, and then that comment text, so the block is followed by exactly one empty line.

```js
// ── Shared behaviour of the reminders ────────────────────────────────────────
// These checks cover behaviour that every reminder shares: the shape of the
// output, the names of the switch, the 30-minute window of the edits, and the
// reading of one edit from the edit log. Each check observes the reminder that
// needs the least set-up: the decision-log reminder (no git), or the commit
// reminder where the check is about a window or a count of files.

console.log('\nShared behaviour of the reminders');

test('When reminders exist: emits decision+reason, not Stop hookSpecificOutput', () => {
  const result = evaluateStop(arrangeDueBlock);
  assert.strictEqual(result.decision, 'block',
    `Expected decision=block, got: ${JSON.stringify(result)}`);
  assert.strictEqual(typeof result.reason, 'string',
    `Expected reason string, got: ${JSON.stringify(result)}`);
  assert.ok(result.reason.includes('<stop-hook-reminders>'),
    `Expected stop reminders tag in reason: ${result.reason}`);
  assert.ok(result.reason.includes(DECISION_LOG),
    `Expected the decision-log reminder in reason: ${result.reason}`);
  assert.ok(!result.hookSpecificOutput,
    `Stop output must not include hookSpecificOutput: ${JSON.stringify(result)}`);
});

// The commit reminder reads the edits of the last 30 minutes. The two tests
// below arrange the same 5 modified files and differ only in the age of the
// edit records.
const INSIDE_WINDOW_MINUTES = 10;
const LAST_MINUTES_OF_WINDOW = 29;
const OUTSIDE_WINDOW_MINUTES = 31;

/** 5 tracked files with a change that git has not committed, and edit records `ageMinutes` old. */
function arrangeModifiedFilesEditedAgo({ logDir, cwdDir }, ageMinutes) {
  const { sessionFiles } = repoWithSessionAndOtherFiles(cwdDir, COMMIT_THRESHOLD);
  modifyFiles(sessionFiles);
  writeRecentEdits(logDir, sessionFiles, ageMinutes);
}

test(`Counts edits that are ${INSIDE_WINDOW_MINUTES} minutes old`, () => {
  assertCommitReminder(evaluateStop(context => arrangeModifiedFilesEditedAgo(context, INSIDE_WINDOW_MINUTES)),
    COMMIT_THRESHOLD);
});

test(`Ignores edits that are ${OUTSIDE_WINDOW_MINUTES} minutes old`, () => {
  // The positive control runs in its own temporary HOME (the environment variable
  // that names the home folder): its block writes the
  // 2-minute guard file, which would silence a second stop in the same HOME.
  assertCommitReminder(evaluateStop(context => arrangeModifiedFilesEditedAgo(context, LAST_MINUTES_OF_WINDOW)),
    COMMIT_THRESHOLD);
  assertNoReminder(evaluateStop(context => arrangeModifiedFilesEditedAgo(context, OUTSIDE_WINDOW_MINUTES)));
});

/** The commit scenario plus one edit of a skill file: the commit and decision-log reminders are due. */
function arrangeCommitAndDecisionLog(context) {
  COMMIT_SCENARIO.arrange(context);
  // The commit scenario rewrites the edit log, so this edit is appended after it.
  fs.appendFileSync(path.join(context.logDir, 'edit-log.txt'),
    editLogLine(TEST_SESSION_ID, SIGNIFICANT_FILE), 'utf8');
}

test('Names are trimmed and case-insensitive, unknown names are ignored, other reminders stay', () => {
  // Positive control, in its own temporary HOME: without the switch the block holds both reminders.
  assertBlockTexts(evaluateStop(arrangeCommitAndDecisionLog).reason || '', [COMMIT_SCENARIO.text, DECISION_LOG]);
  const result = withRemindersOff(' Commit ,unknown ', () => evaluateStop(arrangeCommitAndDecisionLog));
  assertBlockTexts(result.reason || '', [DECISION_LOG], [COMMIT_SCENARIO.text]);
});

test('A block names each unknown name in the switch and lists the known names', () => {
  const result = withRemindersOff('commit,tdd commit, state.md', () => evaluateStop(arrangeDueBlock));
  const reason = result.reason || '';
  assert.ok(reason.includes(DECISION_LOG), `Expected the decision-log reminder, got: ${reason}`);
  assert.ok(reason.includes(UNKNOWN_NAME_WARNING), `Expected the warning, got: ${reason}`);
  assert.ok(reason.includes('"tdd commit"') && reason.includes('"state.md"'),
    `Expected both unknown names, got: ${reason}`);
  assert.ok(reason.includes('session-log-size'), `Expected the known names, got: ${reason}`);
});

test('Known names only: the block has no unknown-name warning', () => {
  // Positive control, in its own temporary HOME: the same arrangement with an unknown name gives the warning.
  const control = withRemindersOff('commit,foo', () => evaluateStop(arrangeDueBlock));
  assert.ok((control.reason || '').includes(UNKNOWN_NAME_WARNING),
    `Expected the warning for an unknown name, got: ${JSON.stringify(control)}`);
  const result = withRemindersOff('commit', () => evaluateStop(arrangeDueBlock));
  assert.ok((result.reason || '').includes(DECISION_LOG), `Expected a block, got: ${JSON.stringify(result)}`);
  assert.ok(!result.reason.includes(UNKNOWN_NAME_WARNING), `Expected no warning, got: ${result.reason}`);
});

test('A repeated unknown name is listed twice in the warning (the parser keeps duplicates)', () => {
  const result = withRemindersOff('foo,foo', () => evaluateStop(arrangeDueBlock));
  const reason = result.reason || '';
  assert.ok(reason.includes(DECISION_LOG), `Expected the decision-log reminder, got: ${reason}`);
  assert.ok(reason.includes('"foo", "foo"'), `Expected the name twice, got: ${reason}`);
});

// The pattern `hooks/<name>.js` must not match a React project's folder named
// hooks. The file counts as an edit that the commit reminder reads: it is one of
// exactly 5 uncommitted edited files, so a count of 5 proves that the edit was
// read (an unread edit would give a count of 4).
test('A React hook file (src/hooks/useAuth.js) does not ask for a decision-log entry', () => {
  const reactHookFile = path.join('src', 'hooks', 'useAuth.js');
  const result = evaluateStop(({ logDir, cwdDir }) => {
    repoWithSessionAndOtherFiles(cwdDir, 1);
    recordEdits(logDir, writeNewFiles(cwdDir,
      [reactHookFile, ...numberedNames(path.join('src', 'other'), COMMIT_THRESHOLD - 1)]));
  });
  assert.ok(!(result.reason || '').includes(DECISION_LOG),
    `Expected no decision-log reminder, got: ${JSON.stringify(result)}`);
  assertCommitReminder(result, COMMIT_THRESHOLD);
});
```

- [x] **Step 3: Run the test file**

Run: `node tests/codex/test-stop-reminders.js`
Expected: the last line is `stop-reminders: <N> passed, 0 failed` (N was 154 when this plan was written) and the exit status is 0. The hook is unchanged, so the TDD reminder still exists; the rewritten tests pass before and after its removal.

- [x] **Step 4: Mutation check (the rewritten tests really fire)**

Save this script as `<scratch>/mutate-check.js`. It copies `hooks/` and the test file to a new temporary folder, replaces one text in the copy of the hook, runs the copy of the test file and prints the labels of the failing tests. The repository is not changed.

```js
// Usage (from the repository root):
//   node <scratch>/mutate-check.js <text in hooks/stop-reminders.js> <replacement>
// Copies hooks/ and tests/codex/test-stop-reminders.js to a new scratch folder,
// replaces the text once in the copy of the hook, runs the copy of the test
// file, and prints the labels of the tests that fail. The repository is not
// changed.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const [oldText, newText] = process.argv.slice(2);
const TEST_FILE = path.join('tests', 'codex', 'test-stop-reminders.js');

const copyRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'mutate-check-'));
fs.cpSync('hooks', path.join(copyRoot, 'hooks'), { recursive: true });
fs.mkdirSync(path.join(copyRoot, path.dirname(TEST_FILE)), { recursive: true });
fs.copyFileSync(TEST_FILE, path.join(copyRoot, TEST_FILE));

const hookCopy = path.join(copyRoot, 'hooks', 'stop-reminders.js');
const hookText = fs.readFileSync(hookCopy, 'utf8');
const occurrences = hookText.split(oldText).length - 1;
if (occurrences !== 1) throw new Error(`Expected the text exactly once, found ${occurrences} times: ${oldText}`);
fs.writeFileSync(hookCopy, hookText.replace(oldText, () => newText), 'utf8');

const run = spawnSync(process.execPath, [path.join(copyRoot, TEST_FILE)], { encoding: 'utf8' });
const failing = run.stderr.split('\n').filter(line => line.startsWith('  ✗'));
console.log(failing.length === 0 ? 'No test fails.' : failing.join('\n'));
fs.rmSync(copyRoot, { recursive: true, force: true });
```

Run these three commands from the repository root, one after the other:

```bash
node <scratch>/mutate-check.js 'new Date(Date.now() - 30 * 60 * 1000)' 'new Date(Date.now() - 40 * 60 * 1000)'
node <scratch>/mutate-check.js 'return !namesSwitchedOff().includes(name);' 'return true;'
node <scratch>/mutate-check.js 'matchesSession(entry, sessionId) &&' "matchesSession(entry, sessionId) && !entry.filePath.includes('useAuth') &&"
```

Expected: the first prints a list that holds `✗ Ignores edits that are 31 minutes old`; the second prints a list that holds `✗ Names are trimmed and case-insensitive, unknown names are ignored, other reminders stay`; the third prints a list that holds `✗ A React hook file (src/hooks/useAuth.js) does not ask for a decision-log entry`. A command that prints `No test fails.` means the named test does not observe what it claims: stop and report.

- [x] **Step 5: Commit**

```bash
git add tests/codex/test-stop-reminders.js
git commit -m "test(stop-reminders): observe the shared behaviour through the decision-log and commit reminders" --trailer "Session: remove-tdd-reminder" --trailer "Stage: task 1/6"
```

---

### Task 2: Delete the tests, helpers and comments that exist only for the TDD reminder

**Files:**
- Modify: `tests/codex/test-stop-reminders.js`

**Security flag:** `none`

**Does NOT cover:** This task does not change `hooks/` (the TDD reminder still exists after it; no test checks it). It does not remove the `tests/test-a.js` edit of the state-md scenario (Task 4: before the hook change, that edit still silences the TDD reminder, and the switch test of `state-md` needs it). It does not touch the commit section (line `Commit reminder counts the files of this session only` onward) except one comment.

**Contract:** The deletions of spec §6.1.
- Must hold after the task: `tests/codex/test-stop-reminders.js` holds no test of the TDD reminder and no use of `isTestFile`; the `tdd` entry is gone from `REMINDER_SCENARIOS` (so the tests generated from it are gone); the helpers and constants named in the delete list of spec §6.1 are gone; the helpers that the commit section or the `commit` scenario still use stay (`git`, `gitDate`, `SECOND_MS` of the test file, `initRepo`, `writeRepoFile`, `COMMITTED_TEXT`, `EDITED_TEXT`, `commitAll`, `repoWithCommittedFiles`, `recordEdits`, `EDIT_AGE_MINUTES`, `FIRST_COMMIT_AGE_MS`, `assertNoReminder`); the heading of the restored-file section is replaced by one comment line naming them as git helpers of the commit section; the explanation of the git index (a plain `git status` writes the index again) now stands next to the test "The count of 5 session files does not rewrite the index of the repository"; the comments that named the removed reminder or a deleted test are rewritten.
- Verification: `node tests/codex/test-stop-reminders.js` exits 0 (a use of a deleted name would stop the file with a `ReferenceError` at load time); the search in Step 3 finds no use of any deleted name and at least two occurrences (definition and use) of every kept name; `git diff --stat` lists only `tests/codex/test-stop-reminders.js`.
- The exact comment wording is free; the properties above bind.

- [x] **Step 1: Confirm the removal lists by search**

Run: `grep -n "// ── TDD reminder names its files\|// ── Commit reminder counts the files of this session only" tests/codex/test-stop-reminders.js`
Expected: two lines, the first with the first heading and the second with the second heading. They give the range of line numbers for the next search.

Run: `grep -n "SOURCE_NAME\|OTHER_SOURCE_NAME\|NEW_SOURCE_NAME\|MIDDLE_COMMIT_AGE_MS\|MIDDLE_COMMIT_MINUTES\|repoWithCommittedSource\|recordEditsAtAges\|assertReminderNames\|TDD_SCENARIO\|PYTHON_TEST_FILE_CASES\|isTestFile" tests/codex/test-stop-reminders.js`
Expected: every hit lies inside the part of the file between the heading `// ── TDD reminder names its files` and the heading `// ── Commit reminder counts the files of this session only`, or is the line `const TDD_SCENARIO = ...`, or is the test "Test-file detection recognizes tests/codex/test-*.js naming" near the top. A hit anywhere else (for example in the commit section) means a name of the delete list is still used: stop and report, and do not remove that name.

- [x] **Step 2: Apply the deletions**

Save this script as `<scratch>/t2-cuts.js`.

```js
const fs = require('fs');

const FILE = process.argv[2];
let text = fs.readFileSync(FILE, 'utf8');

/** Index of `anchor`, which must occur exactly once in the file. */
function anchorIndex(anchor) {
  const first = text.indexOf(anchor);
  if (first < 0) throw new Error(`Anchor not found: ${anchor}`);
  if (text.indexOf(anchor, first + 1) >= 0) throw new Error(`Anchor is not unique: ${anchor}`);
  return first;
}

/** Replace the text from `startAnchor` (included) up to `endAnchor` (not included). */
function replaceBetween(startAnchor, endAnchor, replacement = '') {
  const start = anchorIndex(startAnchor);
  const end = anchorIndex(endAnchor);
  if (end <= start) throw new Error(`End anchor is before start anchor: ${startAnchor} -> ${endAnchor}`);
  text = text.slice(0, start) + replacement + text.slice(end);
}

/** Replace the text `oldText`, which must occur exactly once. */
function replaceOnce(oldText, newText) {
  const start = anchorIndex(oldText);
  text = text.slice(0, start) + newText + text.slice(start + oldText.length);
}

// Test of isTestFile (the test of the removed reminder).
replaceBetween("test('Test-file detection recognizes tests/codex/test-*.js naming'",
  "test('No reminders available emits {}'");

// Comment of the test 'Commit reminder suppressed when all session edits are committed'.
replaceOnce(
  '    // May block for TDD reminder (source files, no tests), but must NOT mention "Commit reminder"\n',
  '    // Must NOT mention "Commit reminder"\n');

// The worktree case that only the removed reminder could answer.
replaceOnce(
  "  ['a hooks/*.js edit (also a source file for the test-first reminder)', `${AGENT_WORKTREE}/hooks/a.js`],\n",
  '');

// The scenario of the removed reminder, and the tests that it generates.
replaceBetween("  {\n    name: 'tdd',\n", "  {\n    name: 'commit',\n");

// Constant of the scenario of the removed reminder.
replaceOnce("const TDD_SCENARIO = REMINDER_SCENARIOS.find(s => s.name === 'tdd');\n", '');

// Section 'TDD reminder names its files'.
replaceBetween('// ── TDD reminder names its files', '// ── File patterns of the reminders');

// Comment of the section 'File patterns of the reminders': only the hook pattern remains.
replaceBetween('// Reported in a design review: the Python test pattern',
  "console.log('\\nFile patterns of the reminders');",
  [
    "// Reported in a design review: the hook pattern `hooks/<name>.js` matched any",
    "// project's folder named hooks (a React project's src/hooks/useAuth.js), which",
    "// asked for a decision-log entry that had nothing to record. A folder named",
    "// hooks counts only beside a hooks.json file.",
    '',
    '',
  ].join('\n'));

// Python test file cases, and the test of latest_report.py.
replaceBetween('const PYTHON_TEST_FILE_CASES = [',
  "test('A hooks/*.js file beside a hooks.json asks for a decision-log entry'");

// Heading, comment and first constants of the section about the restored file.
replaceBetween('// ── TDD reminder leaves out a file that is back at its committed state',
  "const COMMITTED_TEXT = 'module.exports = 1;\\n';",
  '// Git helpers that the commit section below uses.\n\n');

// Constants for a file with two edit records.
replaceBetween('// For a file with two edit records: the commit lies between the two edits.',
  'function git(repoDir, args, env = {}) {', '\n');

// Helper for one committed source file.
replaceBetween('/** The same with one source file. Returns the full path of the source file. */',
  'function recordEdits(logDir, files) {');

// Helper for edit records of different ages.
replaceBetween('/** Write one edit record per [file, age in minutes] pair. */',
  'function assertNoReminder(result) {');

// Helper that names the files of the removed reminder, and all tests of the restored file.
replaceBetween('function assertReminderNames(result, name) {',
  '// ── Commit reminder counts the files of this session only');

// The comment that pointed to the deleted test about the index.
replaceOnce(
  [
    '// See the test of the restored file above: a new modification time makes a',
    '// plain `git status` write the index again.',
    '',
  ].join('\n'),
  [
    '// The index is the file in which git stores the state of every tracked file.',
    '// A new modification time makes the index entry of the file out of date, and',
    '// a plain `git status` then writes the index again. The hook must not write',
    '// into the repository of the user.',
    '',
  ].join('\n'));

// Comment of arrangeEveryReminder: no test edit is involved any more.
replaceOnce('  // Two source edits later than state.md, with no test edit, and one skill file.\n',
  '  // Two source edits later than state.md, and one skill file.\n');

fs.writeFileSync(FILE, text, 'utf8');
```

Run: `node <scratch>/t2-cuts.js tests/codex/test-stop-reminders.js`
Expected: no output, exit status 0.

- [x] **Step 3: Check that nothing is left over and nothing needed was removed**

Run: `grep -n "SOURCE_NAME\|MIDDLE_COMMIT\|repoWithCommittedSource\|recordEditsAtAges\|assertReminderNames\|TDD_SCENARIO\|PYTHON_TEST_FILE_CASES\|isTestFile" tests/codex/test-stop-reminders.js`
Expected: no output.

Run: `for name in gitDate initRepo writeRepoFile COMMITTED_TEXT EDITED_TEXT commitAll repoWithCommittedFiles recordEdits EDIT_AGE_MINUTES FIRST_COMMIT_AGE_MS assertNoReminder; do echo "$name $(grep -c "$name" tests/codex/test-stop-reminders.js)"; done`
Expected: every count is 2 or more.

Run: `grep -n "TDD\|tdd" tests/codex/test-stop-reminders.js`
Expected: only the lines of the state-md scenario comment (two lines that say "TDD reminder") and the unknown-name test (`'commit,tdd commit, state.md'` and `'"tdd commit"'`).

- [x] **Step 4: Run the test file**

Run: `node tests/codex/test-stop-reminders.js`
Expected: the last line is `stop-reminders: <N> passed, 0 failed` (N was 111 when this plan was written) and the exit status is 0.

- [x] **Step 5: Commit**

```bash
git add tests/codex/test-stop-reminders.js
git commit -m "test(stop-reminders): delete the tests and helpers that only the TDD reminder used" --trailer "Session: remove-tdd-reminder" --trailer "Stage: task 2/6"
```

---

### Task 3: Scratchpad tests and header comment of the edit hook

**Files:**
- Modify: `tests/codex/test-track-edits.js`
- Modify: `hooks/track-edits.js`

**Security flag:** `none`

**Does NOT cover:** This task does not change what `hooks/track-edits.js` logs (only a comment changes). It does not change the tests T19b, T21, T22 or any other scratchpad test. It does not touch `hooks/stop-reminders.js`.

**Contract:**
- `tests/codex/test-track-edits.js`: T19 and T20 keep their first assertion (the line count of the edit log: 0 and 1) and lose their second assertion (the one that uses the text "TDD reminder"); the constant `TDD_REMINDER` is removed; the title of T19 no longer names the TDD reminder; the comment above `SCRATCHPAD_FIELD` gives the reasons that still hold (decision-log reminder, state-md reminder, count of the commit reminder). The constants `SCRATCHPAD_FIELD` and `SCRATCH_FILE` stay.
- `hooks/track-edits.js`: the header comment states the same reasons for the scratchpad exclusion. The exclusion itself is unchanged.
- Verification: `node tests/codex/test-track-edits.js` exits 0; `grep -n "TDD" tests/codex/test-track-edits.js hooks/track-edits.js` prints nothing; `git diff --stat` lists only the two files, and the diff of `hooks/track-edits.js` touches only lines that start with ` *` inside the header comment.
- The comment wording is free; the properties above bind.

- [x] **Step 1: Apply the edits**

Save this script as `<scratch>/t3-edits.js`. It edits the file that is named in its first argument: the test file or the hook.

```js
const fs = require('fs');

const FILE = process.argv[2];
let text = fs.readFileSync(FILE, 'utf8');

/** Index of `anchor`, which must occur exactly once in the file. */
function anchorIndex(anchor) {
  const first = text.indexOf(anchor);
  if (first < 0) throw new Error(`Anchor not found: ${anchor}`);
  if (text.indexOf(anchor, first + 1) >= 0) throw new Error(`Anchor is not unique: ${anchor}`);
  return first;
}

/** Replace the text from `startAnchor` (included) up to `endAnchor` (not included). */
function replaceBetween(startAnchor, endAnchor, replacement = '') {
  const start = anchorIndex(startAnchor);
  const end = anchorIndex(endAnchor);
  if (end <= start) throw new Error(`End anchor is before start anchor: ${startAnchor} -> ${endAnchor}`);
  text = text.slice(0, start) + replacement + text.slice(end);
}

/** Replace the text `oldText`, which must occur exactly once. */
function replaceOnce(oldText, newText) {
  const start = anchorIndex(oldText);
  text = text.slice(0, start) + newText + text.slice(start + oldText.length);
}

if (FILE.endsWith('test-track-edits.js')) {
  replaceOnce(
    [
      '// A scratch file must not be logged, because the stop hook\'s test-first',
      '// reminder (the "TDD reminder"; TDD is test-driven development) names every',
      '// logged source file that has no test change next to it.',
      '',
    ].join('\n'),
    [
      '// A scratch file must not be logged: a logged scratch file would trigger the',
      '// decision-log reminder (a scratch SKILL.md counts as significant) and the',
      '// state-md reminder (source files edited after state.md). It would also add to',
      '// the count of the commit reminder when the file lies inside a git repository,',
      '// for example a test-fixture repository in the scratchpad.',
      '',
    ].join('\n'));
  replaceOnce("const TDD_REMINDER = 'TDD reminder';\n", '');
  replaceOnce(
    [
      "test('T19: a Write of a source file inside the scratchpad is not logged and gives no TDD reminder', () => {",
      '',
    ].join('\n'),
    "test('T19: a Write of a source file inside the scratchpad is not logged', () => {\n");
  replaceOnce(
    [
      "  assert.strictEqual(ownEditLogLines(homeDir, SESSION_A), 0, 'The scratch file must not be logged');",
      "  const reason = stop(homeDir, cwdDir, SESSION_A).reason || '';",
      "  assert.ok(!reason.includes(TDD_REMINDER), `Expected no TDD reminder, got: ${reason}`);",
      '',
    ].join('\n'),
    "  assert.strictEqual(ownEditLogLines(homeDir, SESSION_A), 0, 'The scratch file must not be logged');\n");
  replaceOnce(
    [
      '  assert.strictEqual(ownEditLogLines(homeDir, SESSION_A), 1);',
      "  const reason = stop(homeDir, cwdDir, SESSION_A).reason || '';",
      "  assert.ok(reason.includes(TDD_REMINDER), `Expected a TDD reminder, got: ${reason}`);",
      '',
    ].join('\n'),
    '  assert.strictEqual(ownEditLogLines(homeDir, SESSION_A), 1);\n');
} else {
  replaceOnce(
    [
      ' * `scratchpad_dir`) is not logged: such a file is not a change to the project,',
      ' * and a logged one made the stop hook ask for tests of a scratch script.',
      ' * Without the field (a headless session has no scratchpad) every edit is',
      ' * logged, as before.',
      '',
    ].join('\n'),
    [
      ' * `scratchpad_dir`) is not logged: such a file is not a change to the project.',
      ' * A logged scratch file would trigger the decision-log reminder (a scratch',
      ' * SKILL.md, specs/*.md or plans/*.md file counts as significant) and the',
      ' * state-md reminder (source files edited after state.md). It would also add',
      ' * to the count of the commit reminder when the file lies inside a git',
      ' * repository, for example a test-fixture repository in the scratchpad.',
      ' * Without the field (a headless session has no scratchpad) every edit is',
      ' * logged, as before.',
      '',
    ].join('\n'));
}

fs.writeFileSync(FILE, text, 'utf8');
```

Run: `node <scratch>/t3-edits.js tests/codex/test-track-edits.js`
Run: `node <scratch>/t3-edits.js hooks/track-edits.js`
Expected: no output from either command, exit status 0.

- [x] **Step 2: Check the result**

Run: `grep -n "TDD" tests/codex/test-track-edits.js hooks/track-edits.js`
Expected: no output (the command exits with status 1).

Run: `git diff -U0 hooks/track-edits.js | grep '^[-+]' | grep -v '^\(---\|+++\)' | grep -v '^[-+] \*'`
Expected: no output (the command exits with status 1): every changed line of the hook is a line of the header comment.

Run: `node --check hooks/track-edits.js && node tests/codex/test-track-edits.js`
Expected: the last line is `save-marker: <N> passed, 0 failed` (N was 63 when this plan was written) and the exit status is 0.

- [x] **Step 3: Commit**

```bash
git add tests/codex/test-track-edits.js hooks/track-edits.js
git commit -m "test(track-edits): drop the TDD reminder from the scratchpad tests and the header comment" --trailer "Session: remove-tdd-reminder" --trailer "Stage: task 3/6"
```

---

### Task 4: Remove the TDD reminder from the stop hook

**Files:**
- Modify: `hooks/stop-reminders.js`
- Modify: `tests/codex/test-stop-reminders.js`

**Security flag:** `none`

**Does NOT cover:** This task does not change the commit, decision-log, state-md or session-log-size reminder (conditions, texts, order), the 2-minute guard, the `stop_hook_active` check, the git helpers or `removeOldSessionFiles`. It does not change `hooks/codex/stop-adapter.js`. It does not make the hook log Bash-made edits. It does not add a compatibility alias for `tdd`: the name becomes an unknown name.

**Contract:**
- `hooks/stop-reminders.js`: `generateReminders` no longer builds a reminder about source files without test edits; no block text starts with "TDD reminder:" in any state; `REMINDER` holds `COMMIT`, `DECISION_LOG`, `STATE_MD`, `SESSION_LOG_SIZE`, so `KNOWN_REMINDER_NAMES` is `commit, decision-log, state-md, session-log-size` and `tdd` is an unknown name that the existing warning names; the module exports no longer hold `isSourceFile` and `isTestFile`, and all other exports stay; `isSourceFile`, `SOURCE_PATTERNS`, `CONFIG_PATTERNS`, the git helpers and `editedPaths` stay; the header, the comment with the example `"commit,state-md"`, the docstring of `evaluatePayload`, and the guard comment name no removed reminder (spec §3.1 lists these four comments; the comment above `SOURCE_PATTERNS`, which says "non-test", is not changed). Interface not externally pinned for the removed helpers (nothing outside the plan imports them; verified by search).
- Tests: two new tests and one added assertion (the regression tests of spec §6.1): (a) one edit of the fixed absolute path `/project/src/app.js` with no test edit, no significant file and fewer than five files gives `{}`, and `getRecentEdits` returns exactly one entry in the same HOME; (b) with `SUPERPOWERS_STOP_REMINDERS_OFF=tdd` and a due commit reminder, the block holds the commit reminder and the unknown-name warning with `"tdd"`; (c) the block of the scenario with every reminder holds no "TDD reminder" (this is an added assertion in an existing test, not a third new test; it is an allowed extension of the lists of spec §6.1, because that test passes before and after the change except for this assertion). The state-md scenario has no `tests/test-a.js` edit any more.
- Verification: before the hook edit, `node tests/codex/test-stop-reminders.js` fails exactly the three tests named in Step 2; after it, the file exits 0; `bash tests/codex/run-unit-tests.sh` exits 0; `git grep -n "TDD\|isTestFile" -- hooks/stop-reminders.js` prints nothing.
- Wording of the four changed comments is free; the properties above bind.

- [x] **Step 1: Add the regression tests (they must fail first)**

Insert the following block directly before the line that starts with `// ── No commit reminder while a subagent is still running` (use the Edit tool as in Task 1; the new string is the block, one empty line, and then that comment text; the block comes after the section `Shared behaviour of the reminders`).

```js
// ── The TDD reminder is gone ─────────────────────────────────────────────────
// Before v7.71.0 the stop hook had a fifth reminder, the "TDD reminder" (TDD
// means test-driven development), for source files edited without a test edit.

const REMOVED_TDD_REMINDER_TEXT = 'TDD reminder';
// A fixed absolute path that does not exist on disk. No folder of it is a
// temporary folder or is named test or tests.
const SOURCE_FILE_WITHOUT_TEST = '/project/src/app.js';

test('One source edit with no test edit gives no reminder', () => {
  assertNoReminder(evaluateStop(({ hook, logDir }) => {
    writeRecentEdit(logDir, SOURCE_FILE_WITHOUT_TEST);
    // The empty result must not come from an edit log that was never read.
    assert.strictEqual(hook.getRecentEdits(TEST_SESSION_ID).length, 1,
      'Expected the edit of the source file in the edit log');
  }));
});

test('The name "tdd" is unknown: it switches nothing off, and the block names it', () => {
  const result = withRemindersOff('tdd', () => evaluateStop(COMMIT_SCENARIO.arrange));
  assertCommitReminder(result, 6);
  assertBlockTexts(result.reason || '', [UNKNOWN_NAME_WARNING, '"tdd"']);
});
```

Then, with the Edit tool, change the assertion of the test `Without a running subagent, the scenario with every reminder gives every reminder`. The old string is the line

```js
  assertBlockTexts(evaluateStop(arrangeEveryReminder).reason || '', [COMMIT_SCENARIO.text, ...OTHER_BLOCK_TEXTS]);
```

and the new text is

```js
  assertBlockTexts(evaluateStop(arrangeEveryReminder).reason || '', [COMMIT_SCENARIO.text, ...OTHER_BLOCK_TEXTS],
    [REMOVED_TDD_REMINDER_TEXT]);
```

- [x] **Step 2: Run the test file and see the failures**

Run: `node tests/codex/test-stop-reminders.js`
Expected: exactly three tests fail, with these labels: `One source edit with no test edit gives no reminder` (the block holds "TDD reminder: 1 source file(s) modified without test changes: /project/src/app.js"), `The name "tdd" is unknown: it switches nothing off, and the block names it` (no unknown-name warning, because `tdd` is still a known name), and `Without a running subagent, the scenario with every reminder gives every reminder` (the block holds "TDD reminder"). The last line is `stop-reminders: <N> passed, 3 failed` (N was 110 when this plan was written), and the exit status is 1. Any other result: stop and report.

- [x] **Step 3: Remove the TDD reminder from the hook, and the test edit from the state-md scenario**

Save this script as `<scratch>/t4-edits.js`. It edits the file that is named in its first argument: the test file (the state-md scenario) or the hook.

```js
const fs = require('fs');

const FILE = process.argv[2];
let text = fs.readFileSync(FILE, 'utf8');

/** Index of `anchor`, which must occur exactly once in the file. */
function anchorIndex(anchor) {
  const first = text.indexOf(anchor);
  if (first < 0) throw new Error(`Anchor not found: ${anchor}`);
  if (text.indexOf(anchor, first + 1) >= 0) throw new Error(`Anchor is not unique: ${anchor}`);
  return first;
}

/** Replace the text from `startAnchor` (included) up to `endAnchor` (not included). */
function replaceBetween(startAnchor, endAnchor, replacement = '') {
  const start = anchorIndex(startAnchor);
  const end = anchorIndex(endAnchor);
  if (end <= start) throw new Error(`End anchor is before start anchor: ${startAnchor} -> ${endAnchor}`);
  text = text.slice(0, start) + replacement + text.slice(end);
}

/** Replace the text `oldText`, which must occur exactly once. */
function replaceOnce(oldText, newText) {
  const start = anchorIndex(oldText);
  text = text.slice(0, start) + newText + text.slice(start + oldText.length);
}

if (FILE.endsWith('test-stop-reminders.js')) {
  // The scenario of state.md: the test edit existed only to silence the TDD reminder.
  replaceOnce(
    [
      '    // The source edits also make the TDD reminder due; the test file edit',
      '    // stops it, because a session that changed a test gets no TDD reminder.',
      '    arrange: ({ logDir, cwdDir }) => {',
      '',
    ].join('\n'),
    [
      '    // Two source edits, both later than state.md.',
      '    arrange: ({ logDir, cwdDir }) => {',
      '',
    ].join('\n'));
  replaceOnce("writeRecentEdits(logDir, ['src/a.js', 'src/b.js', 'tests/test-a.js']);",
    "writeRecentEdits(logDir, ['src/a.js', 'src/b.js']);");
} else {
  // Header and comments.
  replaceOnce(' * gentle reminders about TDD, verification, and commit hygiene.\n',
    ' * gentle reminders about uncommitted work, decision records, and session files.\n');
  replaceOnce('// names in this environment variable, for example "commit,tdd". Names are not\n',
    '// names in this environment variable, for example "commit,state-md". Names are not\n');
  replaceOnce(' * Only blocks Claude\'s stop when actionable reminders exist (TDD, commit,\n * decision log, session-log size).',
    ' * Only blocks Claude\'s stop when actionable reminders exist (commit,\n * decision log, state.md, session-log size).');
  replaceOnce('  // reminder that the model cannot clear (the TDD reminder) repeats.\n',
    '  // reminder that the model cannot clear (the commit reminder: the user may want\n  // the files uncommitted) repeats.\n');

  // The name of the reminder.
  replaceOnce("  TDD: 'tdd',\n", '');

  // The patterns and the function that only the TDD reminder uses.
  replaceBetween('// Common test file patterns\n', '// Common source file patterns (non-test, non-config)\n');
  replaceOnce('function isTestFile(filePath) {\n  return TEST_PATTERNS.some(p => p.test(filePath));\n}\n\n', '');

  // SECOND_MS, isBackAtCommittedState, firstEditTimeMs, MAX_NAMED_FILES and formatFileList.
  replaceBetween('const SECOND_MS = 1000;\n',
    '/**\n * Return the full path of a logged file as the file system stores it');

  // The TDD block of generateReminders. The line of editedPaths stays.
  replaceBetween('  const sourceFiles = editedPaths.filter(isSourceFile);\n',
    '  // Commit reminder: counts the files that this session edited', '\n');

  // The exports.
  replaceOnce('    isSourceFile,\n    isTestFile,\n', '');
}

fs.writeFileSync(FILE, text, 'utf8');
```

Run: `node <scratch>/t4-edits.js tests/codex/test-stop-reminders.js`
Run: `node <scratch>/t4-edits.js hooks/stop-reminders.js`
Expected: no output from either command, exit status 0.

- [x] **Step 4: Run the tests**

Run: `node --check hooks/stop-reminders.js && node tests/codex/test-stop-reminders.js`
Expected: the last line is `stop-reminders: <N> passed, 0 failed` (N was 113 when this plan was written) and the exit status is 0.

Run: `git grep -n "TDD\|tdd\|isTestFile\|TEST_PATTERNS\|SECOND_MS\|formatFileList\|MAX_NAMED_FILES\|firstEditTimeMs\|isBackAtCommittedState" -- hooks/stop-reminders.js`
Expected: no output (exit status 1).

Run: `bash tests/codex/run-unit-tests.sh`
Expected: the last lines are `Results: 26 suites passed, 0 suites failed` and `All unit tests passed.`, and the exit status is 0.

- [x] **Step 5: Commit**

```bash
git add hooks/stop-reminders.js tests/codex/test-stop-reminders.js
git commit -m "feat(stop-reminders): remove the TDD reminder" --trailer "Session: remove-tdd-reminder" --trailer "Stage: task 4/6"
```

---

### Task 5: Remove the TDD reminder from the documents

**Files:**
- Modify: `README.md`
- Modify: `docs/guide/README.md`
- Modify: `docs/architecture/agentic-workflow.md`
- Modify: `docs/architecture/project-memory.md`
- Modify: `tests/context-management/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** This task does not change the README version badge or the release ranges (Task 6), `RELEASE-NOTES.md`, `docs/worklogs/group-a-fixes.md`, `.codex/INSTALL.md` or any document about Codex. It does not change `docs/architecture/project-memory.md` outside line 193.

**Contract:**
- `README.md`: the diagram labels (line 123 and line 129), the list of names (`tdd` removed), the `track-edits` entry ("Logs file changes for the stop reminders") and the `stop-reminders` entry no longer describe a TDD reminder; the `stop-reminders` entry says that the session summary is shown only inside a block of another reminder and never blocks a stop alone; the names listed there are `commit`, `decision-log`, `state-md`, `session-log-size`.
- `docs/guide/README.md`: the list of names has no `tdd`; the two troubleshooting entries about the test-first reminder are replaced by one short entry that says: since v7.71.0 the stop hook of Claude Code has no TDD reminder; a session that still shows one has an older installed copy (§1) or shows the message of the unsupported Codex adapter; the name `tdd` is now an unknown name that should be removed after every installation that reads the setting runs v7.71.0 or later. TDD is defined at its first use in the entry.
- `docs/architecture/agentic-workflow.md`: no text says that the hooks give TDD reminders; the box line keeps its width.
- `docs/architecture/project-memory.md` line 193 and the pinned copy of that line in `tests/context-management/run-tests.sh` (line 870) change together to the same sentence, without "source edits without test changes".
- Verification: `git grep -n "TDD reminder" -- README.md docs/guide/README.md docs/architecture` prints exactly one line, in `docs/guide/README.md` (the new entry); `git grep -n "tdd" -- README.md docs/architecture` prints nothing; `bash tests/context-management/run-tests.sh` exits 0.

- [x] **Step 1: Apply the edits**

Save this script as `<scratch>/t5-docs.js`. It edits the file that is named in its first argument; it chooses the edits by the file name (the README of the repository root and `docs/guide/README.md` have the same base name, and the script tells them apart by the name of the folder).

```js
const fs = require('fs');

const FILE = process.argv[2];
let text = fs.readFileSync(FILE, 'utf8');

/** Index of `anchor`, which must occur exactly once in the file. */
function anchorIndex(anchor) {
  const first = text.indexOf(anchor);
  if (first < 0) throw new Error(`Anchor not found: ${anchor}`);
  if (text.indexOf(anchor, first + 1) >= 0) throw new Error(`Anchor is not unique: ${anchor}`);
  return first;
}

/** Replace the text from `startAnchor` (included) up to `endAnchor` (not included). */
function replaceBetween(startAnchor, endAnchor, replacement = '') {
  const start = anchorIndex(startAnchor);
  const end = anchorIndex(endAnchor);
  if (end <= start) throw new Error(`End anchor is before start anchor: ${startAnchor} -> ${endAnchor}`);
  text = text.slice(0, start) + replacement + text.slice(end);
}

/** Replace the text `oldText`, which must occur exactly once. */
function replaceOnce(oldText, newText) {
  const start = anchorIndex(oldText);
  text = text.slice(0, start) + newText + text.slice(start + oldText.length);
}

const FILE_NAME = require('path').basename(FILE);
const IN_DIR = require('path').basename(require('path').dirname(FILE));

if (FILE_NAME === 'README.md' && IN_DIR !== 'guide') {
  replaceOnce('track-edits — TDD reminders<br/>', 'track-edits — edit log for the reminders<br/>');
  replaceOnce('TDD + commit nudges, decision-log reminder,<br/>session summary (skills used)',
    'commit nudge, decision-log reminder,<br/>session summary (skills used; only inside<br/>a block of another reminder)');
  replaceOnce('Names: `tdd`, `commit`, `decision-log`,', 'Names: `commit`, `decision-log`,');
  replaceOnce('Logs file changes for TDD reminders, except', 'Logs file changes for the stop reminders, except');
  replaceOnce('Surfaces TDD reminders, commit nudges, and session summary after each response turn.',
    'Surfaces commit nudges and decision-log, state.md and session-log reminders after each response turn. The session summary is shown only inside a block of another reminder; a summary alone never blocks a stop.');
  replaceOnce('`tdd` removes "TDD reminder", `commit` removes', '`commit` removes');
  replaceOnce(' The session summary never blocks on its own and has no name. Since v7.58.0 the TDD reminder asks git about each file and leaves out a file that was edited and then restored: git tracks it, reports no change for it, and no commit on any branch changed it since the edit. A file committed after the edit, a new file that was deleted or moved, an ignored file and a file outside a git repository are still named\n',
    ' The session summary has no name.\n');
} else if (FILE_NAME === 'README.md') {
  replaceOnce('The names are `tdd`, `commit`, `decision-log`, `state-md` and\n`session-log-size`;',
    'The names are `commit`, `decision-log`, `state-md` and\n`session-log-size`;');
  replaceBetween('**The test-first reminder names a scratch file.**',
    '**I updated, but the plugin is still the old version.**',
    [
      '**The stop hook asks for tests ("TDD reminder"; TDD means test-driven development).** Example: "TDD reminder: 2',
      'source file(s) modified without test changes: …". Since v7.71.0 the stop',
      'hook of Claude Code has no such reminder. If a session still shows one,',
      'the installed copy is older (§1),',
      'or the message comes from the Codex adapter, which is not supported and',
      'keeps its own copy of the reminder. The name `tdd` in',
      '`SUPERPOWERS_STOP_REMINDERS_OFF` is now an unknown name: it switches',
      'nothing off, and the next block of the hook names it. Remove `tdd` from the',
      'setting once every installation that reads the setting runs v7.71.0 or',
      'later.',
      '',
      '',
    ].join('\n'));
} else if (FILE_NAME === 'agentic-workflow.md') {
  replaceOnce('logs file changes for TDD reminders     │', 'logs file changes for the reminders     │');
  // The box line keeps its width: the new text is padded to the length of the old text.
  const OLD_BOX_TEXT = '"5 source files modified without tests"                ';
  const NEW_BOX_TEXT = '"Decision log: write a [saved] entry"'.padEnd(OLD_BOX_TEXT.length);
  replaceOnce(OLD_BOX_TEXT, NEW_BOX_TEXT);
} else {
  // project-memory.md and tests/context-management/run-tests.sh state the same sentence.
  replaceOnce('it reminds the AI about source edits without test changes, uncommitted files of the session,',
    'it reminds the AI about uncommitted files of the session,');
}

fs.writeFileSync(FILE, text, 'utf8');
```

Run these five commands from the repository root:

```bash
node <scratch>/t5-docs.js README.md
node <scratch>/t5-docs.js docs/guide/README.md
node <scratch>/t5-docs.js docs/architecture/agentic-workflow.md
node <scratch>/t5-docs.js docs/architecture/project-memory.md
node <scratch>/t5-docs.js tests/context-management/run-tests.sh
```

Expected: no output from any of them, exit status 0 each time.

- [x] **Step 2: Check the documents**

Run: `git grep -n "TDD reminder" -- README.md docs/guide/README.md docs/architecture`
Expected: one line only, `docs/guide/README.md:1553:**The stop hook asks for tests ("TDD reminder"; TDD means test-driven development).** Example: "TDD reminder: 2`.

Run: `git grep -n "tdd" -- README.md docs/architecture`
Expected: no output (exit status 1).

Run: `sed -n 34,46p docs/architecture/agentic-workflow.md`
Expected: the lines of the two boxes have the same width as before (every line between the box corners ends with `│` in the same column as the line above it); the Stop Hook box holds the line `"Decision log: write a [saved] entry"`.

- [x] **Step 3: Run the architecture test**

Run: `bash tests/context-management/run-tests.sh`
Expected: the last line shows `Results: 108 passed, 0 failed` (108 when this plan was written) and the exit status is 0.

- [x] **Step 4: Commit**

```bash
git add README.md docs/guide/README.md docs/architecture/agentic-workflow.md docs/architecture/project-memory.md tests/context-management/run-tests.sh
git commit -m "docs: remove the TDD reminder from the README, the guide and the architecture documents" --trailer "Session: remove-tdd-reminder" --trailer "Stage: task 5/6"
```

---

### Task 6: Release v7.71.0

**Files:**
- Modify: `VERSION`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugin.universal.yaml`
- Modify: `README.md`
- Modify: `RELEASE-NOTES.md`

**Security flag:** `none`

**Does NOT cover:** This task does not push, merge or tag (the orchestrator ends before merge). It does not change `hooks/codex-hooks.json`, `hooks/hooks.json`, `hooks/hooks-cursor.json` or any other hook wiring. It does not change old `RELEASE-NOTES.md` entries.

**Contract:**
- Version: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (first plugin), `plugin.universal.yaml` (meta, line 7), the README badge and the two README ranges `v6.7.0–vX.Y.Z` all state `7.71.0`; the first heading of `RELEASE-NOTES.md` is `## v7.71.0`. Verification: `node tests/codex/test-version-files.js` exits 0, and `git grep -n "7\.70\.0" -- VERSION .claude-plugin plugin.universal.yaml README.md` prints nothing.
- `RELEASE-NOTES.md` entry: the three lines (Problem, Change, Effect) stand directly under the `## v7.71.0` heading, near 100 words and at most 120; the Effect line tells a user with `tdd` in the variable to remove it, after all installations that read the file run v7.71.0 or later, and says that the unsupported Codex adapter keeps its own copy; every figure in the entry traces to the spec (162 of 337 source-file changes, 48%, 143 sessions, 46 sessions; 26 edit logs, about 240 KB). Verification: `awk '/^## v7.71.0/{f=1;next} /^A session runs the installed copy/{f=0} f' RELEASE-NOTES.md | wc -w` prints a number of 120 or less.
- Verification of the whole change: every fast suite of `CLAUDE.md` and `tests/context-management/run-tests.sh` exits 0, each run as its own command (Step 5).
- The wording of the entry is free; the properties above bind.

- [ ] **Step 1: Bump the version strings**

Save this script as `<scratch>/t6-bump.js`. It replaces every occurrence of `7.70.0` in the file named by its first argument, and stops with an error unless the number of occurrences is the number given as its second argument.

```js
// Usage: node t6-bump.js <file> <expected number of occurrences of 7.70.0>
const fs = require('fs');

const OLD_VERSION = '7.70.0';
const NEW_VERSION = '7.71.0';

const [file, expectedCount] = [process.argv[2], Number(process.argv[3])];
const text = fs.readFileSync(file, 'utf8');
const count = text.split(OLD_VERSION).length - 1;
if (count !== expectedCount) throw new Error(`${file}: expected ${expectedCount} occurrences of ${OLD_VERSION}, found ${count}`);
fs.writeFileSync(file, text.split(OLD_VERSION).join(NEW_VERSION), 'utf8');
console.log(`${file}: ${count} occurrence(s) changed`);
```

Run these five commands from the repository root:

```bash
node <scratch>/t6-bump.js VERSION 1
node <scratch>/t6-bump.js .claude-plugin/plugin.json 1
node <scratch>/t6-bump.js .claude-plugin/marketplace.json 1
node <scratch>/t6-bump.js plugin.universal.yaml 1
node <scratch>/t6-bump.js README.md 3
```

Expected: each command prints `<file>: <n> occurrence(s) changed` with the number it was given (1, 1, 1, 1, 3).

- [ ] **Step 2: Add the release note**

Insert the following entry directly before the line `## v7.70.0 — a per-rule switch for protect-secrets` of `RELEASE-NOTES.md` (use the Edit tool: the old string is that heading line, the new string is the entry, then that heading line). The entry ends with one empty line.

````markdown
## v7.71.0 — the stop hook no longer has a TDD reminder

**Problem.** The stop hook's TDD reminder (TDD means test-driven development: the test is written before the code) fired on a comment-only change, missed the 48% of source-file changes made through Bash, and stayed silent under any folder named `test` or `tests`.

**Change.** The reminder is removed, with the code that only it used. `tdd` is no longer a name that the environment variable `SUPERPOWERS_STOP_REMINDERS_OFF` accepts.

**Effect.** The other four reminders are unchanged. Remove `tdd` from the variable: it now shows as an unknown name; where several installations read one settings file, remove it after all of them run v7.71.0 or later. The unsupported Codex adapter (the stop script of the Codex tool) keeps its own copy of the reminder.

A session runs the installed copy of the plugin. The changes below reach a session only after an update of the plugin and a restart of the command-line interface (CLI).

### 1. Why the reminder is removed

The stop hook (`hooks/stop-reminders.js`) runs when Claude finishes a reply. It can block the stop with a list of reminders, and Claude then reads them and writes another reply. The TDD reminder was one of five reminders. Its text was "TDD reminder: N source file(s) modified without test changes: ...". The user decided on 2026-10-10 to remove it completely, with no compatibility alias for its name. The first three reasons below were measured or reproduced on 2026-10-10 in the owner's session; the scripts and test repositories were temporary and are not kept. The fourth reason is a judgment.

- **False alarms are built into the rule.** Only an edited test file silenced the reminder; running the existing tests did not. In a headless run, Claude added one comment line to a source file, the reminder fired, and Claude answered it with a second reply that said a comment needs no test.
- **It could not see edits made through Bash.** The edit log (the per-session file in which `hooks/track-edits.js` records edits) holds only Edit and Write calls. For a Bash call, Claude Code records the files that the command changed in the field `bashEditDiff` of the tool result. Method: the owner's local transcripts of 2026-09-06 to 2026-10-10 (143 sessions, main sessions and subagents) were read. Each Edit or Write call counted as one file change, and each Bash call whose `bashEditDiff` listed a changed file counted as one. A source file is a file with a code extension (for example `.js`, `.py`, `.go`); files in temporary or scratch folders were left out. In the 46 sessions whose transcripts carry `bashEditDiff`, 162 of 337 source-file changes (48%) were made through Bash.
- **It had a path defect.** The patterns that recognize a test file were matched against the absolute path, so a repository under any folder named `test` or `tests` (any letter case) never got the reminder. Reproduced in two fresh repositories.
- **Its gain was small (a judgment, not a measurement).** The workflow skills (`test-driven-development`, and plans with tests first) are the main source of test-first discipline. The reminder was a small addition to them.

### 2. What changed in the code

- **`hooks/stop-reminders.js`.** The block of `generateReminders` that built the TDD reminder is removed. The helpers that only it used are removed too: `isTestFile`, `TEST_PATTERNS`, `isBackAtCommittedState` (the git check that v7.58.0 added), `firstEditTimeMs`, `formatFileList`, `MAX_NAMED_FILES` and `SECOND_MS`. The module no longer exports `isSourceFile` and `isTestFile`. The functions that the other reminders use stay: `isSourceFile` (state-md reminder), the git helpers (commit reminder), the 2-minute guard and the `stop_hook_active` check. The commit, decision-log, state-md and session-log-size reminders keep their conditions, their texts and their order.
- **`hooks/track-edits.js`.** One header comment changes. It gave the TDD reminder as the reason why a file inside the session scratchpad is not logged. It now names the reasons that still hold: a logged scratch file would trigger the decision-log reminder and the state-md reminder, and it would add to the count of the commit reminder when it lies inside a git repository. The exclusion itself is unchanged.
- The behaviours that v7.54.0 (the reminder names the files it counts) and v7.58.0 (the reminder leaves out a restored file) gave to the TDD reminder end with it.

### 3. The name `tdd`

`tdd` is now an unknown name, like any other name that is not in the list: it switches nothing off, and the next block of the hook names it in the existing warning: `Unknown name in SUPERPOWERS_STOP_REMINDERS_OFF: "tdd". Separate names with commas. Known names: commit, decision-log, state-md, session-log-size.` followed by an instruction to tell the user. When no reminder is due, nothing blocks, so nothing shows the warning; this is the behaviour for every unknown name. The accepted names are `commit`, `decision-log`, `state-md` and `session-log-size`.

A user who set `tdd` should remove it. For a settings file that several installations read (a committed project `.claude/settings.json`, or a user settings file synchronized between computers), remove it only after every one of them runs v7.71.0 or later. Until then the warning is harmless.

### 4. Tests

- The tests of the TDD reminder itself are deleted: the test-file detection, the naming of files in the reminder text, the restored-file tests, and the `tdd` scenario of the switch tests.
- A test that used the TDD reminder only as the block it observes is rewritten to observe a reminder that is still produced, and keeps its check: the output shape, the trimmed and case-insensitive names, the unknown-name warning, the 30-minute window of the edits, and the reading of a `src/hooks/useAuth.js` edit. Each rewritten test whose key check is an absence (a block that is not there, or a reminder that is not in the block) has a positive control (the same arrangement without the condition under test, which must still give the result that the test checks for) in its own temporary home folder.
- Two new tests: one source edit with no test edit gives no reminder (it fails with the TDD reminder in place); and the name `tdd` produces the unknown-name warning next to a due commit reminder. The block with every reminder also asserts that no "TDD reminder" text appears.

### 5. Accepted limits

- **The cleanup of per-session files runs less often.** The 7-day cleanup (`removeOldSessionFiles`) runs only when the hook blocks. The TDD reminder had the widest condition, so the hook now blocks less often. A user whose sessions get none of the other four blocks (for example a user who switched off both `commit` and `decision-log` and has no `state.md` or oversized `session-log.md`) loses the cleanup, and per-session files collect in `~/.claude/hooks-logs/`. Measured on the owner's computer on 2026-10-10: 26 edit logs, about 240 KB in one 7-day window. Only the cleanup reads that folder as a whole, so the effect is disk use only.
- **The session summary appears less often.** It is shown only inside a block of another reminder, and the hook now blocks less often.
- **Edits made through Bash stay invisible to the edit log.** Logging them from `tool_response.bashEditDiff.changedFiles` is a separate, later release.
- **The Codex adapter keeps its own copy of the TDD reminder** (`hooks/codex/stop-adapter.js`). Codex has been documented as unsupported since 2026-09-21, so the adapter, its tests and its documents are not changed.

### 6. Documentation

The README (the diagram labels, the list of names, the `track-edits` and `stop-reminders` entries), the guide (the list of names; the two troubleshooting entries about the test-first reminder become one short entry), `docs/architecture/agentic-workflow.md` and `docs/architecture/project-memory.md` no longer describe a TDD reminder. The architecture test `tests/context-management/run-tests.sh` pins the sentence of `project-memory.md` and changes with it.
````

- [ ] **Step 3: Check the version files and the entry**

Run: `node tests/codex/test-version-files.js`
Expected: the last line is `10 passed, 0 failed` and the exit status is 0.

Run: `git grep -n "7\.70\.0" -- VERSION .claude-plugin plugin.universal.yaml README.md`
Expected: no output (exit status 1).

Run: `awk '/^## v7.71.0/{f=1;next} /^A session runs the installed copy/{f=0} f' RELEASE-NOTES.md | wc -w`
Expected: a number of 120 or less (119 when this plan was written).

- [ ] **Step 4: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): v7.71.0" --trailer "Session: remove-tdd-reminder" --trailer "Stage: task 6/6"
```

- [ ] **Step 5: Run every fast suite, each as its own command**

Run each of these commands on its own, one after the other (not in parallel, not in a loop). Every one must exit 0.

```bash
bash tests/codex/run-unit-tests.sh
bash tests/smart-compress/run-tests.sh
bash tests/reviewer-templates/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/in-run-rulings/run-tests.sh
bash tests/fill-prompt/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/measure-context/run-tests.sh
bash tests/pickup/run-tests.sh
bash tests/analyze-compaction/run-tests.sh
bash tests/sdd-scripts/run-tests.sh
bash tests/suite-guard/run-tests.sh
bash tests/worklog/run-tests.sh
bash tests/dashboard/run-tests.sh
bash tests/context-management/run-tests.sh
```

Expected: every command exits 0. A suite that fails stops the run for a ruling; it is not changed to make it pass. (When this plan was written, `tests/suite-guard/run-tests.sh` failed once when it ran in parallel with other suites, and passed on its own: run it alone.)

Run: `git status --short -- . ':!docs/superpowers-orchestrator'`
Expected: no output (the working tree is clean outside the topic folder of this run; nothing in `<scratch>` is inside the repository).

Run: `git diff --stat a75c3ec..HEAD -- . ':!docs/superpowers-orchestrator' ':!docs/research'`
Expected: the changed files are exactly the 14 files listed in "Premises tested", and no file under `hooks/codex/`, `skills/` or `hooks/*.json`.
