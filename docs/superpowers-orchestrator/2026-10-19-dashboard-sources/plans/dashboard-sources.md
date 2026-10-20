# Dashboard Release 1 (Sources, "As Of" Line, Shared-Ref Line, Git Card) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Release 7.73.0 of the `dashboard` skill: remove session open items, show sessions newest first with their date, add a "Source:" line to every card, a true "as of" line, a shared-ref line on the private page, and a sorted, folded Git card.
**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
**Architecture:** The extractor (`skills/dashboard/scripts/dashboard-extract.js`) loses the `sessionOpenItems` section, gains `commit.date`, local dates, the `current` mark on branch items and, in the private run only, a top-level `sharedRef` field that it computes from `config.json` and the state files without stopping, and reports as one line on standard error. The page template (`skills/dashboard/template.html`) renders a "Source:" line on every card, the new "as of" line, the shared-ref line in a static header element, and a Git card sorted by date with old branches folded. `dashboard-sync.js` keeps only `set-part`; `dashboard-render.js --verify` refuses a shared document that holds `sharedRef`. `SKILL.md`, the guide, the README, the old dashboard spec and the release files follow.
**Tech Stack:** Node.js (>= 16; scripts use only `fs`, `path`, `os`, `crypto`, `child_process`), git (the `-local` date suffix, checked with git 2.50.1), plain JavaScript in an HTML page (no library), Bash test runner `tests/dashboard/run-tests.sh`.
**Assumptions:**
- Assumes git accepts `--date=short-local` and `%(committerdate:short-local)` (checked on 2026-10-20 with git 2.50.1: a commit at `2026-01-09T23:30:00+00:00` prints `2026-01-09` with `short` and `2026-01-10` with `short-local` under `TZ=Asia/Tokyo`) — will NOT give local dates on a git version without the `-local` suffix (oldest such version unverified, spec section 4.5).
- Assumes `%(refname:lstrip=2)` prints `main` where `%(refname:short)` prints `heads/main` because a tag `main` exists (checked on 2026-10-20 with git 2.50.1) — will NOT strip correctly for a ref outside `refs/heads/`, which the Git card never lists.
- Assumes `git update-ref refs/remotes/origin/tree <tree id>` succeeds and `git rev-parse --verify --quiet refs/remotes/origin/tree^{commit}` then fails (checked on 2026-10-20) — the "not a commit" test case depends on it.
- Assumes git honours the IANA zone name in `TZ=Asia/Tokyo` (true on macOS and Linux; not checked for Git for Windows, whose native git may read only the POSIX form such as `JST-9`) — the local-date cases of test-04 sections 10 and 11 will NOT pass on a git that ignores the name.
- Assumes Node honours a change of `process.env.TZ` at run time (Node >= 13) — the daylight-saving test of Task 8 will NOT exercise a time-zone change on an older Node.
- Assumes the dashboard suite is green before Task 1 (checked on 2026-10-20: 13 test files, 0 failures).
- Assumes every file this plan edits is tracked by git and none is ignored (checked on 2026-10-20 with `git ls-files --error-unmatch` on all 26 files and `git check-ignore -v` on the plan path).
**Global Constraints:**
1. Target version: `7.73.0`. Release files: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, the `README.md` version badge, the two `v6.7.0–vX.Y.Z` ranges of the README's Lineage & status note, and a `RELEASE-NOTES.md` entry for 7.73.0 that starts with the three-line summary (Problem / Change / Effect, about 100 words, 120 at most).
2. Every list of names to remove in spec section 4.1 is checked by searching the whole repository for each name before it is removed; a name with another caller stays.
3. `KIND.raw` of the extractor stays (every malformed work-log table row has `kind: 'raw'`). `RESOLVED_SUFFIX`, `SUPERSEDED_MARK`, `ID_SEPARATOR`, `SESSION_LOG` of the parser stay. `normalizeLine`, `occurrenceOf` and `lineItemId` stay byte-for-byte unchanged, so that the ids of existing items do not change.
4. A proposal whose `kind` is `resolve-open-item` gets the verdict `invalid` with exactly this reason, held in one constant: `resolve-open-item was removed in 7.73.0; reject this proposal`. Every other unknown kind gets the reason `kind is not set-part`. No change to SKILL.md `sync` for this.
5. The extractor emits the `sessions` items newest first (reverse file order); the 10-entry limit stays. The template shows each session item as `<YYYY-MM-DD HH:MM of entry> · <goal>`, and the goal alone when `entry` does not start with that pattern after `## `.
6. A constant `SOURCES` in `template.html`, next to `TITLES`, maps each section id to one sentence; `renderSection` renders it as `Source: <sentence>` (prefix held in one constant `SOURCE_PREFIX`) in a `<p class="muted source">` element placed directly after the card's `<h2>`, before every status, note, extra line and item, in every state of the section (with items, empty, not found, failed, absent). For sections whose shared run reads a different source, a constant `SHARED_SOURCES` holds a replacement sentence shown instead (never both) when `data.audience` is `shared`. Every sentence names where the section reads its items and the rule that selects them; paths are relative to the repository root; no sentence contains an absolute path or a user name. Numbers in the sentences equal the extractor constants: 10 = `SESSION_ENTRIES` (`sessions`), 20 = `COMMIT_LIMIT` (`commits`, in `SOURCES` and `SHARED_SOURCES`), 15 = `RELEASE_LIMIT` (`releases`). `SOURCES` and `SHARED_SOURCES` are added to the `globalThis.DashboardApp` export. All page text is set with `textContent`.
7. Local dates: `commit.date`, the shared-ref `date`, `oldestNotShown`, the branch dates and the "Recent commits" dates use `--date=short-local` / `%(committerdate:short-local)`. `skills/pickup/scripts/git-runs.js` is not changed (unfinished-run dates stay in the committer's time zone).
8. Every count of days between two dates (the 14-day rules and the 90-day fold, all in the template) is a calendar-day count on the `YYYY-MM-DD` parts: `(Date.UTC(y2, m2-1, d2) - Date.UTC(y1, m1-1, d1)) / 86400000`.
9. `asOfLine()` prints `as of commit <short> (<commit date>) on branch <branch> · built <YYYY-MM-DD HH:MM>` on a branch and `as of commit <short> (<commit date>), detached HEAD · built <YYYY-MM-DD HH:MM>` on a detached HEAD, followed by ` · N tracked files changed, not committed` (` · 1 tracked file changed, not committed` for N = 1) only when `sections.git.dirty` is a number greater than 0.
10. The private extract run reads `sharing`, `sharedRef` and `sharedUrl` from `config.json` and the files `<state>/shared.json` and `<state>/private.json` only when it gets `--data-dir`; no new command-line option is added; the shared run never computes the field and its data never has the key. Cases: `sharing` is `on` and `sharedRef` is stored → **following**; `sharing` is not `on` and `sharedUrl` is stored → **sharing off**; anything else → `null`. For following, the private run never calls `checkSharedName` or `sharedRemote`; it runs, in this order, the form check (failure → `error`, message `<value> is not of the form <remote>/<branch>`), `git show-ref --verify --quiet refs/remotes/<name>` (failure → `missing`), `git rev-parse --verify --quiet refs/remotes/<name>^{commit}` (failure → `error`, message `<name> is not a commit`); any later git failure → `error` with git's message; every command names the ref `refs/remotes/<name>`. Every `error` message passes through `sanitize()` and keeps only its first non-empty line. A failure here never stops the private extract (exit 0).
11. Data shapes of `sharedRef`: no line → `null`; following, checks pass → `{ name, short (7 hex), date, notShown, oldestNotShown (or null), published (or null), previousBuild (or null) }`; following, check 2 fails → `{ name, missing: true, published, previousBuild }`; following, check 1 or 3 or a later command fails → `{ name, error, published, previousBuild }`; sharing off → `{ off: true, published }`. `notShown` = `git rev-list --count <ref>..HEAD`; `oldestNotShown` = first line of `git log --reverse --format=%cd --date=short-local <ref>..HEAD`, `null` when `notShown` is 0; `published` / `previousBuild` = `generatedAt` of `<state>/shared.json` / `<state>/private.json` cut to `YYYY-MM-DD HH:MM`, `null` when the file is missing or not valid JSON.
12. Shared-ref line texts, joined by one space in this order (ref part, not-shown part, published part): `The shared page follows <name>, last commit <date>.` / `The shared page follows <name>, which no longer exists. The shared page cannot be updated.` / `The state of the shared ref could not be read: <error>.` / `Sharing is off. The shared page from an earlier share is still published and is no longer updated.`; not shown (left out when `notShown` is 0): `<n> commits of this branch are not in <name>; the oldest is from <oldestNotShown>.` / `1 commit of this branch is not in <name>; it is from <oldestNotShown>.` / `The checked-out commit has <n> commits that are not in <name>; the oldest is from <oldestNotShown>.` / `The checked-out commit has 1 commit that is not in <name>; it is from <oldestNotShown>.` (the last two when `commit.branch` is `null`); published: `Last published <published>.` / `Never published from this machine.`
13. The line is the static element `<p id="shared-ref" hidden></p>` placed directly after `#as-of`; `renderPage()` never inserts it, it sets its `textContent`, its `class` attribute (with `setAttribute`) and its `hidden` state on every call. When `sharedRef` is `null` or absent the element is hidden and empty. Classes: `shared-ref banner warn` when (1) `oldestNotShown` lies more than `SHARED_STALE_DAYS = 14` calendar days before the date part of `generatedAt`, or (2) the case is following and `published` is `null` or `previousBuild` is not `null` and its date lies more than 14 calendar days after the date of `published`, or (3) the ref is `missing` or the case is `error`; `shared-ref muted` otherwise. Sharing off is always `shared-ref muted`.
14. When `sharedRef` is not `null`, the private extract writes `dashboard-extract: shared page: <line>` on standard error and exits 0; standard output is not used for it. SKILL.md `refresh` tells the model to repeat that line, without the `dashboard-extract: ` prefix, in its final report. `share` step 5 copies `<scratchpad>/dashboard/shared.json` to `<state>/shared.json` after a successful publish.
15. `dashboard-render.js --verify` for the shared audience refuses data that has a top-level `sharedRef` key (any value), with the reason `the shared data contains sharedRef`, added to the existing reasons list.
16. Git card: the private run marks the item of the checked-out branch with `current: true` (all others: no field); branch names come from `%(refname:lstrip=2)` in both audiences where the name comes from `for-each-ref`; the template shows `[current]` after the name; the shared run never sets the field. The template sorts branch items by `date` descending, then `name` ascending; items whose `date` is missing, `null` or empty come after all dated items, by name. Branches whose `date` is more than `BRANCH_FOLD_DAYS = 90` days before the date part of `generatedAt` are folded into one `<details>` element after the item list, whose `<summary>` reads `<n> older branches (no commit in the last 90 days)` or `1 older branch (no commit in the last 90 days)`; the current branch and items without a date are never folded; no `<details>` element when no branch is old. Both audiences sort and fold the same way.
17. `refresh` never changes `sharedRef` by itself and never follows the checked-out branch. No change to `context-management`.
18. The dashboard spec `docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md` gets one line `Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: <what changed>` at each affected section (5.1, 5.2, the section 7 table, section 8, the test lists); those sections are not rewritten. Code comments that cite a spec section for removed behaviour are removed with the code.

---

## File Structure

| File | Responsibility | Tasks |
|---|---|---|
| `skills/dashboard/scripts/dashboard-sync.js` | Checks and applies page proposals; keeps only `set-part`, names the removed kind | 1 |
| `skills/dashboard/scripts/dashboard-parse.js` | Shared parsing rules; loses the open-item parser | 2 |
| `skills/dashboard/scripts/dashboard-extract.js` | Builds the page data; loses `sessionOpenItems`, gains local dates, `commit.date`, `current`, `sharedRef` and its report line | 2, 4, 7 |
| `skills/dashboard/scripts/dashboard-render.js` | `--verify` refuses `sharedRef` in shared data | 9 |
| `skills/dashboard/template.html` | The page: open-item UI removed, session line, "as of" line, Git card order and fold, "Source:" lines, shared-ref line | 3, 5, 6, 8 |
| `skills/dashboard/SKILL.md` | Description, `refresh` report, `share` step 5 | 10 |
| `tests/dashboard/test-02-parse.js` … `test-12-skill-text.js`, `fake-page.js` | Behaviour tests through the scripts' command lines and the fake page | 1–10 |
| `docs/guide/README.md`, `README.md`, `hooks/skill-rules.json`, `docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md` | User documents and the old spec's amendment lines | 11 |
| `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md` | Release 7.73.0 | 12 |

Task order matters: tasks 3, 5, 6 and 8 edit `template.html` and `tests/dashboard/test-07-template.js` in sequence; tasks 2, 4 and 7 edit `dashboard-extract.js` in sequence; Task 8 uses the extractor output of Task 7; Task 7 uses the constants `LATE`, `TOKYO` and `LOCAL_DAY` that Task 4 adds to `test-04-extract-core.js`. Run the tasks in number order. Run every task alone, one after another, never in a parallel wave: each task runs the whole dashboard suite while the new tests of another task fail on purpose, and Task 2 removes `lineAtOccurrence` and `RESOLVED_MARK` from `dashboard-parse.js`, which `dashboard-sync.js` uses until Task 1 is done.

All test commands run from the repository root. One test file runs alone with `node tests/dashboard/<file>`; it prints `PASS:`/`FAIL:` lines and `<n> passed, <m> failed`, and exits 1 on any failure.

---

### Task 1: `sync` keeps only `set-part`; a `resolve-open-item` proposal is invalid with a fixed reason

**Files:**
- Modify: `skills/dashboard/scripts/dashboard-sync.js`
- Test: `tests/dashboard/test-10-sync-check.js` (rewritten on `set-part`)
- Test: `tests/dashboard/test-11-sync-apply.js` (rewritten on `set-part`)

**Security flag:** `security` (this task changes the validation rules of proposals, which are untrusted data written by the page; the security cases of test-10 section 7 and test-11 sections 10–15 must keep their coverage on `set-part`)

**Does NOT cover:** proposals already written to a file by an older sync (a `[resolved` mark that an interrupted sync wrote into `session-log.md` stays; rejecting the proposal does not undo it — the release notes of Task 12 say so). It does not change SKILL.md `sync`: step 3 already lets the owner reject an `invalid` proposal.

**Contract:**
- `basicInvalid(p)` in `dashboard-sync.js`
  - Inputs: a normalized proposal document. Output: a reason string, or `null` when the proposal passes the rules that need no file.
  - Invariants: `p.kind === 'resolve-open-item'` → exactly `resolve-open-item was removed in 7.73.0; reject this proposal` (one constant, built from the kind constant); any other kind that is not `set-part` → exactly `kind is not set-part`; every remaining rule (path, allow-list `docs/worklogs/<slug>.md`, status list, note rule, status-or-note, anchor fields with heading `## Parts` and a safe `part`, branch present and safe, `createdAt` form) gives the same reason as before for a `set-part` proposal.
  - Verification: `node tests/dashboard/test-10-sync-check.js` (sections 3, 7a, 7b, 7c) and `node tests/dashboard/test-11-sync-apply.js` (section 7: an old `resolve-open-item` proposal given to `--apply` is reported invalid with that reason and writes nothing).
  - Interface not externally pinned — the function is internal; its reasons are pinned by the global constraint 4 for the two kind reasons only.
- `expectedChange`, `evaluate`, and the removal of `findResolveTarget`, `KIND.resolve` and `DEFAULT_NOTE`
  - Invariants: no code path of `dashboard-sync.js` names `lineAtOccurrence`, `RESOLVED_MARK`, `SESSION_LOG` or `KIND.resolve`; every `set-part` verdict (`unique`, `already-applied`, `none`, `several`, `invalid`, `file-missing`, `wrong-branch`, `held-run`) and every `--apply` outcome (one write per file, carriage returns and byte order mark kept, retry on a concurrent change, `not written` lines, create-only temporary file, bytes not valid UTF-8 kept, git failure after a write reported) stays as before.
  - Verification: `grep -n -E "lineAtOccurrence|RESOLVED_MARK|SESSION_LOG|KIND\.resolve|DEFAULT_NOTE|findResolveTarget" skills/dashboard/scripts/dashboard-sync.js` prints nothing; both test files pass.
- `tests/dashboard/test-10-sync-check.js` and `tests/dashboard/test-11-sync-apply.js` (rewritten)
  - Must convey: every case that was built on `resolve-open-item` now runs on `set-part`, and the security cases keep their coverage.
  - Invariant: neither file builds a proposal of kind `resolve-open-item` except the one that checks the removed-kind reason.
  - Verification: `grep -c "kind: 'resolve-open-item'" tests/dashboard/test-10-sync-check.js tests/dashboard/test-11-sync-apply.js` prints `1` for each file (the one proposal builder of the removed kind; a comment or a reason text that names the kind does not count). The security sections stay: `grep -c -E "^// 7[a-e]\." tests/dashboard/test-10-sync-check.js` prints `5` and `grep -c -E "^// 1[0-5]\." tests/dashboard/test-11-sync-apply.js` prints `6` (the same counts as at 971beb2b).

- [x] **Step 1: Rewrite `tests/dashboard/test-10-sync-check.js` on `set-part`**

Replace the whole file with:

```js
'use strict';
// dashboard-sync.js --check: every verdict of spec section 8 step 2, the
// anchors (heading ordinal, part number), the new lines, the warnings, and
// the reason that a proposal of the kind removed in 7.73.0 gets.
const fs = require('fs');
const path = require('path');
const h = require('./helpers');

const SYNC = h.script('dashboard-sync.js');
const CREATED = '2026-09-29T00:30:00+02:00';
const SHA = 'c'.repeat(40);
const W = 'docs/worklogs/w.md';
// A work log that git does not track.
const LOOSE = 'docs/worklogs/loose.md';
const PARTS = '## Parts';
const REMOVED_REASON = 'resolve-open-item was removed in 7.73.0; reject this proposal';
const ROW = {
  1: '| 1 | first | done | 2026-09-22 | abc1234 | |',
  2: '| 2 | second | in progress | 2026-09-23 | | waits on item #1 |',
  3: '|  3  | third | not started |  |  |  |',
  4: '| 4 | fourth | in progress | 2026-09-23 | | |',
  5: '| 5 | dup | in progress | | | |',
};
const DONE4 = '| 4 | fourth | done | 2026-09-29 |  |  |';
const WORKLOG = [
  '<!-- Work log: status=active slug=w created=2026-09-21 -->', '', PARTS, '',
  '| # | Part | Status | Since | Commit | Note |', '|---|------|--------|-------|--------|------|',
  ROW[1], ROW[2], ROW[3], ROW[4], ROW[5], ROW[5], '', '## Open items', '',
  '| # | Item | Part | Found | Blocks |', '|---|------|------|-------|--------|', '| 1 | fix x | 4 | 2026-09-23 | 4 |', '',
].join('\n');

const anchorWith = (fields) => Object.assign({ heading: PARTS, headingOrdinal: 1, line: ROW[4], occurrence: 1, part: '4' }, fields);
const setPart = (part, fields, extra) => Object.assign({
  kind: 'set-part', file: W, branch: 'main', baseCommit: SHA,
  anchor: { heading: PARTS, headingOrdinal: 1, line: ROW[part], occurrence: 1, part: String(part) },
  createdAt: CREATED, state: 'pending', closedAt: null,
}, fields, extra || {});
// A proposal of the kind that 7.73.0 removed, as a page before 7.73.0 wrote it.
const oldResolve = () => ({
  kind: 'resolve-open-item', file: 'session-log.md', branch: 'main', baseCommit: SHA,
  anchor: { heading: '## 2026-01-05 [saved]', headingOrdinal: 1, line: 'Open: one line', occurrence: 1 },
  createdAt: CREATED, state: 'pending', closedAt: null,
});

// Runs --check in <dir> on the proposals <docs> ({ id: document, or a raw
// file text }); returns { id: { verdict, lines } } and the raw output.
let folderCount = 0;
function check(dir, docs) {
  folderCount += 1;
  const folder = path.join(h.ROOT, `check-${folderCount}`);
  Object.entries(docs).forEach(([id, doc]) => h.proposalFile(folder, id, doc, 1));
  const result = h.node(dir, [SYNC, '--check', folder, '--versions', h.versionsFile(folder)]);
  const found = {};
  let current = null;
  for (const line of result.out.split('\n')) {
    const match = line.match(/^proposal (\S+): (\S+)(?: — (.*))?$/);
    if (match) {
      current = { verdict: match[2], reason: match[3] || '', lines: [] };
      found[match[1]] = current;
    } else if (current && line.startsWith('  ')) {
      current.lines.push(line.trim());
    }
  }
  return { found, out: result.out, code: result.code };
}
const reasonOf = (run) => Object.fromEntries(Object.entries(run.found).map(([id, value]) => [id, value.reason]));
const verdictOf = (run) => Object.fromEntries(Object.entries(run.found).map(([id, value]) => [id, value.verdict]));
const worklogFile = (dir) => path.join(dir, ...W.split('/'));

const d = h.repo('sync-check');
h.write(d, 'file.txt', 'x\n');
h.write(d, W, WORKLOG);
fs.symlinkSync('w.md', path.join(d, 'docs', 'worklogs', 'link.md'));
h.commit(d, 'base', ['file.txt', 'docs']);
h.write(d, LOOSE, WORKLOG);

// 1. unique targets and their new lines.
let run = check(d, {
  utc: setPart(4, { status: 'done' }, { createdAt: '2026-09-30T00:30:00+02:00' }),
  loose: setPart(4, { status: 'done' }, { file: LOOSE }),
  part4: setPart(4, { status: 'done' }),
  part2: setPart(2, { note: 'new note' }),
  padded: setPart(3, { status: 'in progress' }),
  sameStatus: setPart(4, { status: 'in progress', note: 'n' }),
  both: setPart(4, { status: 'done', note: 'finished' }),
});
h.eq('unique verdicts', Object.values(verdictOf(run)), Array(7).fill('unique'));
h.eq('the date is the local date of createdAt, not its UTC date', run.found.utc.lines[2], '+ | 4 | fourth | done | 2026-09-30 |  |  |');
h.eq('a work log that git does not track: the diff and the untracked label', run.found.loose.lines.slice(0, 3), [`file: ${LOOSE} (untracked)`, `- ${ROW[4]}`, `+ ${DONE4}`]);
h.eq('set-part: status and Since change; a blocked part gets a warning', [run.found.part4.lines[2], run.found.part4.lines.some((l) => l.startsWith('warning: an open item blocks this part'))], [`+ ${DONE4}`, true]);
h.check('a target that git tracks is labelled tracked', run.found.part4.lines[0].endsWith(' (tracked)'));
h.check('a note that replaces an "item #" Note gets a warning', run.found.part2.lines.some((l) => l.startsWith('warning: the Note')));
h.eq('a padded row is rewritten with single spaces', run.found.padded.lines.slice(1, 3), [`- ${ROW[3]}`, '+ | 3 | third | in progress | 2026-09-29 |  |  |']);
h.eq('a status equal to the current one keeps Since', run.found.sameStatus.lines[2], '+ | 4 | fourth | in progress | 2026-09-23 |  | n |');
h.eq('status and note on one row in one proposal', run.found.both.lines[2], '+ | 4 | fourth | done | 2026-09-29 |  | finished |');
h.check('the summary line counts the verdicts', run.out.includes('summary: unique=7'));

// 2. none, several, already-applied.
run = check(d, {
  ordinal: setPart(4, { status: 'done' }, { anchor: anchorWith({ headingOrdinal: 9 }) }),
  changed: setPart(4, { status: 'done' }, { anchor: anchorWith({ line: '| 4 | fourth | in progress | 2026-09-01 | | |' }) }),
  dup: setPart(5, { status: 'done' }),
  missingPart: setPart(4, { status: 'done' }, { anchor: anchorWith({ part: '9' }) }),
});
h.eq('none and several', verdictOf(run), { changed: 'none', dup: 'several', missingPart: 'none', ordinal: 'none' });
fs.writeFileSync(worklogFile(d), WORKLOG.replace(ROW[4], DONE4));
h.eq('the expected new line at the anchor gives already-applied', verdictOf(check(d, { part: setPart(4, { status: 'done' }) })), { part: 'already-applied' });
fs.writeFileSync(worklogFile(d), WORKLOG);

// 3. invalid: one proposal per rule of spec section 8 step 2.1.
const invalid = {
  badKind: setPart(4, { status: 'done' }, { kind: 'delete' }),
  removedKind: oldResolve(),
  dotdot: setPart(4, { status: 'done' }, { file: '../docs/worklogs/w.md' }),
  absolute: setPart(4, { status: 'done' }, { file: '/etc/passwd' }),
  backslash: setPart(4, { status: 'done' }, { file: 'docs\\worklogs\\w.md' }),
  setPartOther: setPart(4, { status: 'done' }, { file: 'docs/other/w.md' }),
  badStatus: setPart(4, { status: 'dropped' }),
  pipeNote: setPart(4, { note: 'a | b' }),
  bracketNote: setPart(4, { note: 'see [x]' }),
  longNote: setPart(4, { note: 'x'.repeat(201) }),
  twoLines: setPart(4, { note: 'a\nb' }),
  nothing: setPart(4, {}),
  noAnchor: setPart(4, { status: 'done' }, { anchor: { heading: PARTS } }),
  otherHeading: setPart(4, { status: 'done' }, { anchor: anchorWith({ heading: '## Open items' }) }),
  detached: setPart(4, { status: 'done' }, { branch: null }),
  badCreated: setPart(4, { status: 'done' }, { createdAt: '2026-09-29 00:30' }),
  noop: setPart(4, { status: 'in progress' }),
  doneWithCommit: setPart(1, { status: 'in progress' }),
  symlink: setPart(4, { status: 'done' }, { file: 'docs/worklogs/link.md' }),
};
run = check(d, Object.assign({ broken: '{' }, invalid));
h.eq('every rule gives invalid', verdictOf(run), Object.fromEntries(Object.keys(invalid).concat('broken').sort().map((id) => [id, 'invalid'])));

const PATH_REASON = 'file is not a relative path inside the repository';
const reasons = reasonOf(run);
h.eq('the kind rules give their own reasons', [reasons.badKind, reasons.removedKind], ['kind is not set-part', REMOVED_REASON]);
h.eq('the path rules give their own reason', [reasons.dotdot, reasons.absolute, reasons.backslash], [PATH_REASON, PATH_REASON, PATH_REASON]);
h.eq('the allow-list rule gives its own reason', reasons.setPartOther, 'set-part allows only docs/worklogs/<slug>.md');
h.eq('the symbolic link target gives its reason', reasons.symlink, 'the target file is a symbolic link');

// 3b. A folder link that leaves the repository: the file resolves outside.
const outer = h.repo('sync-outside');
const outsideDir = path.join(h.ROOT, 'outside-worklogs');
h.write(outer, 'file.txt', 'x\n');
h.commit(outer, 'base', ['file.txt']);
fs.mkdirSync(outsideDir, { recursive: true });
const OUTSIDE_TEXT = WORKLOG;
fs.writeFileSync(path.join(outsideDir, 'w.md'), OUTSIDE_TEXT);
let haveFolderLink = true;
try { fs.mkdirSync(path.join(outer, 'docs')); fs.symlinkSync(outsideDir, path.join(outer, 'docs', 'worklogs')); } catch (error) { haveFolderLink = false; console.log('  NOTE: this file system refuses a symbolic link; the outside-folder case is skipped'); }
if (haveFolderLink) {
  const outsideProposal = setPart(4, { status: 'done' });
  const outsideRun = check(outer, { out: outsideProposal });
  h.eq('a work log folder that links outside the repository: invalid, with its reason', [outsideRun.found.out.verdict, outsideRun.found.out.reason], ['invalid', 'the file lies outside the repository']);
  const applyFolder = path.join(h.ROOT, 'outside-apply');
  h.proposalFile(applyFolder, 'out', outsideProposal, 1);
  const applied = h.node(outer, [SYNC, '--apply', applyFolder, 'out', '--versions', h.versionsFile(applyFolder)]);
  h.check('apply reports invalid for it', applied.out.startsWith('proposal out: invalid'), applied.out);
  h.eq('apply leaves the outside file unchanged', fs.readFileSync(path.join(outsideDir, 'w.md'), 'utf8'), OUTSIDE_TEXT);
}

// 4. file-missing and wrong-branch.
run = check(d, {
  missing: setPart(4, { status: 'done' }, { file: 'docs/worklogs/gone.md' }),
  otherBranch: setPart(4, { status: 'done' }, { branch: 'feature/other' }),
});
h.eq('file-missing and wrong-branch', verdictOf(run), { missing: 'file-missing', otherBranch: 'wrong-branch' });

// 5. held-run: an in-progress run on another branch holds nothing; on the
// current branch it holds tracked files; a stopped run holds them from any
// branch; a work log that git does not track is never held.
h.git(d, 'checkout', '-q', '-b', 'feature/busy');
h.write(d, h.logPath('2026-09-20', 'busy'), h.runLog('busy', ['## Phase 3 — Batch 1']));
h.commit(d, 'busy log', ['docs/superpowers-orchestrator']);
h.git(d, 'checkout', '-q', 'main');
h.eq('an in-progress run on another branch holds nothing', verdictOf(check(d, { part: setPart(4, { status: 'done' }) })), { part: 'unique' });
h.git(d, 'checkout', '-q', 'feature/busy');
h.eq('an in-progress run on the current branch holds a tracked file', verdictOf(check(d, { part: setPart(4, { status: 'done' }, { branch: 'feature/busy' }) })), { part: 'held-run' });
h.git(d, 'checkout', '-q', '-b', 'feature/stopped', 'main');
h.write(d, h.logPath('2026-09-21', 'stopped'), h.runLog('stopped', ['## Phase 1', '## STOPPED — 2026-09-21 — phase 3 — blocked']));
h.commit(d, 'stopped log', ['docs/superpowers-orchestrator']);
h.eq('a stopped run on the current branch holds a tracked file', verdictOf(check(d, { part: setPart(4, { status: 'done' }, { branch: 'feature/stopped' }) })), { part: 'held-run' });
h.git(d, 'checkout', '-q', 'main');
const loosePart = () => setPart(4, { status: 'done' }, { file: LOOSE });
h.eq('a stopped run on another branch: tracked held, untracked not', verdictOf(check(d, { part: setPart(4, { status: 'done' }), loose: loosePart() })), { loose: 'unique', part: 'held-run' });
h.commit(d, 'track the loose work log', [LOOSE]);
h.eq('a work log that git tracks now is held too', verdictOf(check(d, { loose: loosePart() })), { loose: 'held-run' });

// 6. The command cannot run: no proposal folder, no --versions option, or a
// versions file that does not match the body files one to one. No verdict
// line is printed.
h.eq('no proposal folder: exit 2', h.node(d, [SYNC, '--check', path.join(h.ROOT, 'nowhere'), '--versions', path.join(h.ROOT, 'nowhere.txt')]).code, 2);
const joined = path.join(h.ROOT, 'versions-join');
h.proposalFile(joined, 'one', setPart(4, { status: 'done' }), 1);
h.eq('no --versions option: exit 2', h.node(d, [SYNC, '--check', joined]).code, 2);
const badVersions = {
  'a body file with no versions line': '',
  'a versions line with no body file': 'one 1\nother 1\n',
  'an id on two lines': 'one 1\none 2\n',
  'a version that is not a positive integer': 'one 0\n',
  'a version that is not a number': 'one v1\n',
  'a line with no version': 'one\n',
};
Object.entries(badVersions).forEach(([name, text], i) => {
  const file = path.join(h.ROOT, `versions-bad-${i}.txt`);
  fs.writeFileSync(file, text);
  const result = h.node(d, [SYNC, '--check', joined, '--versions', file]);
  h.eq(`${name}: exit 2 and no verdict line`, [result.code, /^proposal /m.test(result.out)], [2, false]);
});
h.eq('the matching versions file of the same folder is accepted', h.node(d, [SYNC, '--check', joined, '--versions', h.versionsFile(joined)]).code, 0);

// 7. The findings of the security review of the first dashboard release.
// 7a. A note holds no character that is invisible in the diff or that
// breaks a line: control characters, line and paragraph separators,
// bidirectional controls; the script uses the note rule of
// dashboard-parse.js. Ordinary non-ASCII text stays allowed.
const hiddenInNote = {
  nulNote: setPart(4, { note: 'ok\u0000x' }),
  tabNote: setPart(4, { note: 'a\tb' }),
  escapeNote: setPart(4, { note: 'a\u001b(0b' }),
  deleteNote: setPart(4, { note: 'a\u007fb' }),
  nextLineNote: setPart(4, { note: 'a\u0085b' }),
  lineSeparatorNote: setPart(4, { note: 'a\u2028b' }),
  paragraphSeparatorNote: setPart(4, { note: 'a\u2029b' }),
  rightToLeftNote: setPart(4, { note: 'a\u202eb' }),
  isolateNote: setPart(4, { note: 'a\u2066b' }),
};
// 7b. The anchor fields and the branch hold no line break or control
// character, so one proposal cannot print a forged verdict block.
const forged = (id) => `x\nproposal ${id}: unique\n  file: ${W} (untracked)`;
const forgedFields = {
  headingBreak: setPart(4, { status: 'done' }, { anchor: anchorWith({ heading: `${PARTS}${forged('zz')}` }) }),
  lineBreak: setPart(4, { status: 'done' }, { anchor: anchorWith({ line: `${ROW[4]}${forged('yy')}` }) }),
  partBreak: setPart(4, { status: 'done' }, { anchor: anchorWith({ part: `9${forged('xx')}` }) }),
  branchBreak: setPart(4, { status: 'done' }, { branch: `main${forged('ww')}` }),
  branchEscape: setPart(4, { status: 'done' }, { branch: 'main\u001b[2J' }),
};
// 7c. A "__proto__" key cannot replace the checked fields.
const protoDoc = `{"__proto__": ${JSON.stringify(setPart(4, { status: 'done' }))}, "status": "done"}`;
const hostile = Object.assign({ proto: protoDoc }, hiddenInNote, forgedFields);
run = check(d, hostile);
h.eq('hidden characters, forged fields and a __proto__ key give invalid', verdictOf(run), Object.fromEntries(Object.keys(hostile).sort().map((id) => [id, 'invalid'])));
h.check('no forged verdict line and one summary line', !/^proposal (zz|yy|xx|ww):/m.test(run.out) && run.out.split('\n').filter((line) => line.startsWith('summary:')).length === 1, run.out);
const escapeId = path.join(h.ROOT, 'versions-escape.txt');
fs.writeFileSync(escapeId, 'one 1\ne\u001bx 1\n');
const escapeRun = h.node(d, [SYNC, '--check', joined, '--versions', escapeId]);
h.eq('an id with a control character: exit 2, the line is named, the character is not printed', [escapeRun.code, escapeRun.err.includes('line 2'), escapeRun.err.includes('\u001b')], [2, true, false]);

// 7d. The tracked check asks git about the path that the file system
// resolves: a work log reached through a tracked folder link.
const partDone = setPart(4, { status: 'done' });
const linked = h.repo('sync-linked');
h.write(linked, 'real/worklogs/w.md', WORKLOG);
fs.mkdirSync(path.join(linked, 'docs'));
fs.symlinkSync(path.join('..', 'real', 'worklogs'), path.join(linked, 'docs', 'worklogs'));
h.commit(linked, 'base', ['real', 'docs']);
run = check(linked, { part: partDone, accents: setPart(4, { note: 'café — naïve' }) });
h.eq('a file reached through a folder link is labelled tracked', run.found.part.lines[0], `file: ${W} (tracked)`);
h.eq('ordinary non-ASCII text in a note is allowed', run.found.accents.verdict, 'unique');
const addStoppedRun = (dir) => {
  h.git(dir, 'checkout', '-q', '-b', 'feature/stopped');
  h.write(dir, h.logPath('2026-09-21', 'stopped'), h.runLog('stopped', ['## Phase 1', '## STOPPED — 2026-09-21 — phase 3 — blocked']));
  h.commit(dir, 'stopped log', ['docs/superpowers-orchestrator']);
  h.git(dir, 'checkout', '-q', 'main');
};
addStoppedRun(linked);
h.eq('a file reached through a folder link is held by a stopped run', verdictOf(check(linked, { part: partDone })), { part: 'held-run' });
// On a file system that ignores letter case (the macOS default), git records
// "Docs/worklogs/w.md" while the proposal names "docs/worklogs/w.md".
const cased = h.repo('sync-cased');
h.write(cased, 'Docs/worklogs/w.md', WORKLOG);
h.commit(cased, 'base', ['Docs']);
if (fs.existsSync(path.join(cased, 'docs'))) {
  h.eq('a file recorded with other letter case is labelled tracked', check(cased, { part: partDone }).found.part.lines[0], `file: ${W} (tracked)`);
} else {
  console.log('  NOTE: this file system keeps letter case apart; the letter-case case is skipped');
}

// 7e. A git failure stops the check (exit 2, no verdict line, no absolute
// path in the message) instead of giving "untracked" or no held-run.
const failedRun = (dir) => {
  const result = h.node(dir, [SYNC, '--check', joined, '--versions', h.versionsFile(joined)]);
  return [result.code, /^proposal /m.test(result.out), result.err.includes(h.ROOT)];
};
const scanFail = h.repo('sync-scan-fail');
h.write(scanFail, W, WORKLOG);
h.commit(scanFail, 'base', ['docs']);
h.git(scanFail, 'checkout', '-q', '-b', 'feature/broken');
h.write(scanFail, h.logPath('2026-09-22', 'broken'), h.runLog('broken', ['## Phase 3 — Batch 2']));
h.commit(scanFail, 'broken log', ['docs/superpowers-orchestrator']);
h.git(scanFail, 'checkout', '-q', 'main');
const blob = h.git(scanFail, 'rev-parse', `feature/broken:${h.logPath('2026-09-22', 'broken')}`);
fs.rmSync(path.join(scanFail, '.git', 'objects', blob.slice(0, 2), blob.slice(2)));
h.eq('a failed git command of the run scan: exit 2, no verdict, no absolute path', failedRun(scanFail), [2, false, false]);
const indexFail = h.repo('sync-index-fail');
h.write(indexFail, W, WORKLOG);
h.commit(indexFail, 'base', ['docs']);
fs.writeFileSync(path.join(indexFail, '.git', 'index'), 'not an index');
h.eq('a failed git ls-files: exit 2, no verdict, no absolute path', failedRun(indexFail), [2, false, false]);

h.finish();
```

- [x] **Step 2: Rewrite `tests/dashboard/test-11-sync-apply.js` on `set-part`**

Replace the whole file with:

```js
'use strict';
// dashboard-sync.js --apply and --batches: one write per file, line endings
// and the byte order mark kept, repeated runs, both orders of two rows, a
// file that changes during the write, a sync stopped after the marking, ids
// that were not marked, a removed proposal kind, a held run, batches of at
// most 50 records, and the security cases: a link at a temporary name, bytes
// that are not valid UTF-8, a git failure after a write, and an id with a
// line break.
const fs = require('fs');
const path = require('path');
const h = require('./helpers');

const SYNC = h.script('dashboard-sync.js');
const CREATED = '2026-09-29T00:30:00+02:00';
const SHA = 'c'.repeat(40);
const W = 'docs/worklogs/w.md';
// A second work log, which git does not track.
const U = 'docs/worklogs/u.md';
const WORKLOG_DIR = ['docs', 'worklogs'];
const ROW4 = '| 4 | fourth | in progress | 2026-09-23 | | |';
const ROW5 = '| 5 | fifth | not started | | | |';
const DONE4 = '| 4 | fourth | done | 2026-09-29 |  |  |';
const DONE5 = '| 5 | fifth | done | 2026-09-29 |  |  |';
const WORKLOG = [
  '<!-- Work log: status=active slug=w created=2026-09-21 -->', '', '## Parts', '',
  '| # | Part | Status | Since | Commit | Note |', '|---|------|--------|-------|--------|------|', ROW4, ROW5, '',
].join('\n');
// The line indexes of the two rows in WORKLOG.
const AT4 = 6;
const AT5 = 7;
const ROWS = { 4: ROW4, 5: ROW5 };
const part = (number, fields, extra) => Object.assign({
  kind: 'set-part', file: W, branch: 'main', baseCommit: SHA,
  anchor: { heading: '## Parts', headingOrdinal: 1, line: ROWS[number], occurrence: 1, part: String(number) },
  createdAt: CREATED, state: 'pending', closedAt: null,
}, fields, extra || {});
const done = (number, extra) => part(number, { status: 'done' }, extra);

let folderCount = 0;
function folderOf(docs) {
  folderCount += 1;
  const folder = path.join(h.ROOT, `apply-${folderCount}`);
  Object.entries(docs).forEach(([id, doc], i) => h.proposalFile(folder, id, doc, i + 1));
  return folder;
}
const versionsOf = (folder) => ['--versions', h.versionsFile(folder)];
const apply = (dir, folder, ids, env) => h.node(dir, [SYNC, '--apply', folder, ...ids, ...versionsOf(folder)], env);
const lines = (result) => result.out.trim().split('\n');
const read = (dir, rel) => fs.readFileSync(path.join(dir, ...rel.split('/')), 'utf8');
const rowsOf = (dir) => read(dir, W).split('\n');
const tempFiles = (dir) => fs.readdirSync(path.join(dir, ...WORKLOG_DIR)).filter((name) => name.endsWith('.tmp'));
function freshRepo(name, worklogText) {
  const d = h.repo(name);
  h.write(d, W, worklogText === undefined ? WORKLOG : worklogText);
  h.commit(d, 'base', ['docs']);
  return d;
}

// 1. Two rows of one file in one call; a second run writes nothing.
let d = freshRepo('apply-one');
const both = folderOf({ a: done(4), b: done(5) });
let result = apply(d, both, ['a', 'b']);
h.eq('both rows are written in one call', [rowsOf(d)[AT4], rowsOf(d)[AT5]], [DONE4, DONE5]);
h.eq('the report lines', lines(result), ['proposal a: applied', 'proposal b: applied', `changed ${W} (tracked)`]);
const afterFirst = read(d, W);
result = apply(d, both, ['a', 'b']);
h.check('a second run gives already-applied and writes nothing', lines(result).every((line) => line.includes('already-applied')) && read(d, W) === afterFirst);

// 2. The two rows applied one at a time, in both orders.
for (const order of [['b', 'a'], ['a', 'b']]) {
  d = freshRepo(`apply-order-${order.join('')}`);
  const folder = folderOf({ a: done(4), b: done(5) });
  order.forEach((id) => apply(d, folder, [id]));
  h.eq(`order ${order.join(' then ')}: both rows written, none twice`, [rowsOf(d)[AT4], rowsOf(d)[AT5], read(d, W).split('| done |').length - 1], [DONE4, DONE5, 2]);
}

// 3. A part: status and note on one row, in a tracked file.
d = freshRepo('apply-part');
result = apply(d, folderOf({ p: part(4, { status: 'done', note: 'finished' }) }), ['p']);
h.eq('the row is rewritten', rowsOf(d)[AT4], '| 4 | fourth | done | 2026-09-29 |  | finished |');
h.eq('a tracked file is named as tracked', lines(result)[1], `changed ${W} (tracked)`);

// 4. Carriage returns and a byte order mark are kept.
d = freshRepo('apply-crlf', `\ufeff${WORKLOG.split('\n').join('\r\n')}`);
apply(d, folderOf({ c: done(5) }), ['c']);
const raw = read(d, W);
h.eq('byte order mark, carriage returns, changed line', [raw.startsWith('\ufeff'), raw.split('\n').slice(0, -1).every((line) => line.endsWith('\r')), raw.split('\r\n')[AT5]], [true, true, DONE5]);

// 5. The file changes between the read and the rename: the check runs again.
d = freshRepo('apply-race');
result = apply(d, folderOf({ c: done(5) }), ['c'], { DASHBOARD_SYNC_TEST_CHANGE_ONCE: 'appended line\n' });
h.eq('the change is applied and the other writer\'s line is kept', [lines(result)[0], rowsOf(d)[AT5], read(d, W).includes('appended line')], ['proposal c: applied', DONE5, true]);
h.eq('no temporary file is left', tempFiles(d), []);

// 6. A sync that stopped after the marking: the next check completes it.
d = freshRepo('apply-resume', WORKLOG.replace(ROW4, DONE4));
const marked = folderOf({ a: done(4, { state: 'applying' }), b: done(5, { state: 'applying' }) });
const checked = h.node(d, [SYNC, '--check', marked, ...versionsOf(marked)]);
h.check('check: already-applied for the written row, unique for the other', checked.out.includes('proposal a: already-applied') && checked.out.includes('proposal b: unique'));
h.eq('apply completes it', lines(apply(d, marked, ['a', 'b'])).slice(0, 2), ['proposal a: already-applied — the row already holds this change', 'proposal b: applied']);

// 7. Only the listed ids are written; an unknown id is reported; an invalid
// proposal and a proposal of the kind removed in 7.73.0 write nothing.
d = freshRepo('apply-subset');
result = apply(d, folderOf({ a: done(4), b: done(5) }), ['a', 'zzz']);
h.eq('an id that was not marked is not written', [rowsOf(d)[AT4], rowsOf(d)[AT5]], [DONE4, ROW5]);
h.check('an unknown id is reported', lines(result)[0] === 'proposal zzz: not-found — no file for this id in the folder');
const beforeInvalid = fs.readFileSync(path.join(d, ...W.split('/')));
const invalidRun = apply(d, folderOf({ x: done(5, { file: '../docs/worklogs/w.md' }) }), ['x']);
h.check('an invalid proposal is reported and nothing is written', lines(invalidRun)[0].startsWith('proposal x: invalid') && fs.readFileSync(path.join(d, ...W.split('/'))).equals(beforeInvalid));
const removedKind = {
  kind: 'resolve-open-item', file: 'session-log.md', branch: 'main', baseCommit: SHA,
  anchor: { heading: '## 2026-01-01 [saved]', headingOrdinal: 1, line: '- same', occurrence: 1 },
  createdAt: CREATED, state: 'applying', closedAt: null,
};
const removedRun = apply(d, folderOf({ r: removedKind }), ['r']);
h.eq('an applying proposal of the removed kind: invalid with its reason, nothing written', [lines(removedRun), fs.readFileSync(path.join(d, ...W.split('/'))).equals(beforeInvalid), fs.existsSync(path.join(d, 'session-log.md'))], [['proposal r: invalid — resolve-open-item was removed in 7.73.0; reject this proposal'], true, false]);

// 7b. Two proposals whose anchors name the same row: one is applied, the
// other is refused, and the file holds one change.
d = freshRepo('apply-same-line');
result = apply(d, folderOf({ a: done(4), b: part(4, { note: 'other' }) }), ['a', 'b']);
h.eq('one applied, one refused for the same line', lines(result).slice(0, 2), ['proposal a: applied', 'proposal b: none — another proposal of this sync changes the same line']);
h.eq('the file holds exactly one change', rowsOf(d)[AT4], DONE4);

// 8. A held run: nothing is written.
d = freshRepo('apply-held');
h.git(d, 'checkout', '-q', '-b', 'feature/stopped');
h.write(d, h.logPath('2026-09-21', 'stopped'), h.runLog('stopped', ['## STOPPED — 2026-09-21 — phase 3 — blocked']));
h.commit(d, 'stopped log', ['docs/superpowers-orchestrator']);
h.git(d, 'checkout', '-q', 'main');
result = apply(d, folderOf({ p: done(4) }), ['p']);
h.eq('held-run: the tracked file is not written', [lines(result).length, lines(result)[0].startsWith('proposal p: held-run'), read(d, W)], [1, true, WORKLOG]);

// 9. Batches of at most 50 records, pinned to each file's version.
const many = {};
for (let i = 0; i < 120; i += 1) many[`p${String(i).padStart(3, '0')}`] = done(4);
const manyFolder = folderOf(many);
const manyVersions = versionsOf(manyFolder);
const ids = Object.keys(many);
const batchLines = lines(h.node(d, [SYNC, '--batches', manyFolder, 'applied', ...ids, ...manyVersions])).map((line) => JSON.parse(line));
h.eq('three batches of 50, 50 and 20', batchLines.map((batch) => batch.length), [50, 50, 20]);
const first = batchLines[0][0];
h.eq('one record', [first.op, first.collection, first.doc_id, first.data.state, first.if_version, batchLines[2][19].if_version], ['update', 'proposals', 'p000', 'applied', 1, 120]);
h.check('applied records carry closedAt as local time with its offset', /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/.test(first.data.closedAt));
h.eq('pending records carry closedAt null', JSON.parse(lines(h.node(d, [SYNC, '--batches', manyFolder, 'pending', 'p000', ...manyVersions]))[0])[0].data.closedAt, null);
h.eq('an unknown state stops', h.node(d, [SYNC, '--batches', manyFolder, 'done', 'p000', ...manyVersions]).code, 2);
h.eq('an id with no file stops', h.node(d, [SYNC, '--batches', manyFolder, 'applied', 'nothing', ...manyVersions]).code, 2);
h.eq('a --data-dir pair is accepted and not read', JSON.parse(lines(h.node(d, [SYNC, '--data-dir', '', '--batches', manyFolder, 'pending', 'p000', ...manyVersions]))[0])[0].doc_id, 'p000');

// A preload module runs in the process of the script before the script
// itself, so it can act at the exact moment that another program would.
function preload(name, code) {
  const file = path.join(h.ROOT, name);
  fs.writeFileSync(file, `'use strict';\nconst fs = require('fs');\nconst path = require('path');\n${code}\n`);
  return file;
}
const applyWith = (module, dir, folder, applyIds) => h.node(dir, ['-r', module, SYNC, '--apply', folder, ...applyIds, ...versionsOf(folder)]);
const DONE_LINES = WORKLOG.split('\n');
DONE_LINES[AT5] = DONE5;

// 10. A symbolic link at the temporary name (the random part is fixed by the
// preload): the create-only write never goes through it.
d = freshRepo('apply-temp-link');
const outside = path.join(h.ROOT, 'outside-apply.txt');
fs.writeFileSync(outside, 'OUTSIDE');
const TEMP_NAME_HEX = '07'.repeat(6);
const plantLink = preload('plant-link.js', `require('crypto').randomBytes = (count) => Buffer.alloc(count, 7);
fs.symlinkSync(${JSON.stringify(outside)}, path.join(process.cwd(), ${WORKLOG_DIR.map((segment) => JSON.stringify(segment)).join(', ')}, '.w.md.dashboard-${TEMP_NAME_HEX}.tmp'));`);
result = applyWith(plantLink, d, folderOf({ c: done(5) }), ['c']);
h.eq('a link at the temporary name: the create-only write stops, the outside file and the target are unchanged', [fs.readFileSync(outside, 'utf8'), result.code !== 0, result.out.includes('proposal c: applied'), read(d, W)], ['OUTSIDE', true, false, WORKLOG]);

// 11. A byte that is not valid UTF-8 on a line that no proposal changes is
// written back as it was.
const LATIN1_LINE = Buffer.from('caf\xE9 (latin-1)\n', 'latin1');
d = freshRepo('apply-bytes', Buffer.concat([Buffer.from(WORKLOG), LATIN1_LINE]));
apply(d, folderOf({ c: done(5) }), ['c']);
h.check('the lines not changed are written back byte for byte', fs.readFileSync(path.join(d, ...W.split('/'))).equals(Buffer.concat([Buffer.from(DONE_LINES.join('\n')), LATIN1_LINE])));

// 12. Git fails after the first file was written: the report of that file
// is printed before the stop. The untracked work log U is written first.
d = freshRepo('apply-git-fails');
h.write(d, U, WORKLOG);
const breakIndex = preload('break-index.js', `const rename = fs.renameSync;
fs.renameSync = (...args) => {
  rename(...args);
  fs.renameSync = rename;
  fs.writeFileSync(path.join(process.cwd(), '.git', 'index'), 'not an index');
};`);
result = applyWith(breakIndex, d, folderOf({ a: done(5, { file: U }), b: done(4) }), ['a', 'b']);
h.eq('the written file is reported, then the git failure stops', [result.code, lines(result)], [2, ['proposal a: applied', `changed ${U} (untracked)`]]);

// 14. The file changes during every attempt (only the modification time, so
// the bytes stay the same): nothing is written, no applied line, exit 1.
d = freshRepo('apply-always-changing');
const touchAlways = preload('touch-always.js', `const stat = fs.statSync;
let tick = 0;
fs.statSync = (target, ...rest) => {
  const result = stat(target, ...rest);
  if (String(target).endsWith('w.md')) { tick += 1; fs.utimesSync(target, 1000 + tick, 1000 + tick); }
  return result;
};`);
result = applyWith(touchAlways, d, folderOf({ c: done(5) }), ['c']);
h.eq('a file that changes 3 times: exit 1, one not-written line, no proposal line, bytes kept', [result.code, lines(result).length, lines(result)[0].startsWith(`not written: ${W} changed 3 times`), result.out.includes('proposal '), read(d, W), tempFiles(d)], [1, 1, true, false, WORKLOG, []]);

// 15. The rename fails: exit 1, one not-written line naming the temporary
// file that keeps the new text, no proposal line, the target unchanged.
d = freshRepo('apply-rename-fails');
const failRename = preload('fail-rename.js', `fs.renameSync = () => { throw new Error('rename refused'); };`);
result = applyWith(failRename, d, folderOf({ c: done(5) }), ['c']);
const kept = (lines(result)[0].match(/the new text is kept in (.+)$/) || [])[1];
h.eq('a failed rename: exit 1, one not-written line, no proposal line, bytes kept', [result.code, lines(result).length, lines(result)[0].startsWith(`not written: ${W}: rename refused`), result.out.includes('proposal '), read(d, W)], [1, 1, true, false, WORKLOG]);
h.check('the printed temporary file exists and holds the new text', Boolean(kept) && fs.existsSync(kept) && fs.readFileSync(kept, 'utf8') === DONE_LINES.join('\n'));
if (kept) fs.rmSync(kept, { force: true });

// 13. An id argument with a line break is printed escaped, on one line.
d = freshRepo('apply-id-escape');
const escapeFolder = folderOf({ a: done(4) });
const FORGED = 'zz\nproposal a: applied';
h.eq('the not-found line holds the escaped id', lines(apply(d, escapeFolder, [FORGED])), [`proposal ${JSON.stringify(FORGED)}: not-found — no file for this id in the folder`]);
result = h.node(d, [SYNC, '--batches', escapeFolder, 'applied', FORGED, ...versionsOf(escapeFolder)]);
h.eq('batches: the stop message holds the escaped id on one line', [result.code, result.out, result.err.trim().split('\n').length, result.err.includes(JSON.stringify(FORGED))], [2, '', 1, true]);

h.finish();
```

- [x] **Step 3: Run the two test files to verify they fail**

Run: `node tests/dashboard/test-10-sync-check.js | grep FAIL; node tests/dashboard/test-11-sync-apply.js | grep FAIL`
Expected: FAIL lines for `every rule gives invalid` and `the kind rules give their own reasons` (the old `basicInvalid` accepts `oldResolve()`, and `evaluate` then gives it the verdict `file-missing`, because the fixture has no `session-log.md`), and `an applying proposal of the removed kind: invalid with its reason, nothing written`.

- [x] **Step 4: Implement the change in `skills/dashboard/scripts/dashboard-sync.js`**

Before removing, search the repository for each name (Global Constraint 2):

Run: `git grep -n -E "findResolveTarget|DEFAULT_NOTE|KIND\.resolve"` (the whole repository, no pathspec)
Expected: hits in `skills/dashboard/scripts/dashboard-sync.js`, and one hit in `skills/dashboard/template.html` (`EDIT_KIND.resolve`, a different constant of the page, which Task 3 removes). No other caller of the sync names. Hits in documents under `docs/` (specs, plans, review logs and acceptance notes, this plan and its spec included) are not callers and do not count.

Replace the line `const KIND = { resolve: 'resolve-open-item', setPart: 'set-part' };` with:

```js
const KIND = { setPart: 'set-part' };
// The proposal kind that 7.73.0 removed. A page database can still hold
// proposals of this kind; they get this reason, and the owner rejects them.
const REMOVED_KIND = 'resolve-open-item';
const REMOVED_KIND_REASON = `${REMOVED_KIND} was removed in 7.73.0; reject this proposal`;
```

Delete the line `const DEFAULT_NOTE = 'from the dashboard';`.

Replace the function `basicInvalid` with:

```js
// The rules of spec section 8 step 2.1 that need no file.
function basicInvalid(p) {
  if (p.kind === REMOVED_KIND) return REMOVED_KIND_REASON;
  if (p.kind !== KIND.setPart) return 'kind is not set-part';
  if (typeof p.file !== 'string' || !p.file || path.isAbsolute(p.file) || p.file.includes('\\') || p.file.split('/').includes('..')) {
    return 'file is not a relative path inside the repository';
  }
  if (!WORKLOG_FILE.test(p.file)) return 'set-part allows only docs/worklogs/<slug>.md';
  if (p.status !== undefined && !parse.PART_STATUSES.includes(p.status)) return 'status must be not started, in progress or done, on set-part only';
  if (p.note !== undefined && (typeof p.note !== 'string' || p.note.length > parse.NOTE_LIMIT || parse.NOTE_FORBIDDEN.test(p.note))) {
    return `note must be one line of at most ${parse.NOTE_LIMIT} characters without | [ ] or control characters`;
  }
  if (p.status === undefined && p.note === undefined) return 'set-part needs a status or a note';
  const a = p.anchor;
  const anchorOk = Boolean(a) && safeText(a.heading) && a.heading.startsWith(parse.HEADING_PREFIX)
    && Number.isInteger(a.headingOrdinal) && a.headingOrdinal >= 1 && safeText(a.line)
    && a.heading === parse.PARTS_HEADING && safeText(a.part);
  if (!anchorOk) return 'the anchor fields are missing or wrong';
  if (typeof p.branch !== 'string' || !p.branch) {
    return 'set-part needs the branch of the page (a page built on a detached HEAD cannot propose work-log edits)';
  }
  if (!safeText(p.branch)) return 'the branch holds a line break or a control character';
  if (typeof p.createdAt !== 'string' || !CREATED_AT.test(p.createdAt)) return 'createdAt is not a local time with its offset';
  return null;
}
```

In `expectedChange`, delete these four lines (the resolve branch):

```js
  if (p.kind === KIND.resolve) {
    const note = p.note === undefined ? DEFAULT_NOTE : p.note;
    return { changed: !p.anchor.line.includes(parse.RESOLVED_MARK), line: `${p.anchor.line} [resolved ${date}: ${note}]` };
  }
```

Delete the whole function `findResolveTarget`.

In `evaluate`, replace these three lines:

```js
  const header = section && p.kind === KIND.setPart ? parse.sectionTable(lines, section).header : [];
```
```js
  if (p.kind === KIND.setPart && p.branch !== env.branch) return verdict(VERDICT.wrongBranch, `the page was built on ${p.branch}; check out that branch and sync again`);
```
```js
  const found = p.kind === KIND.resolve ? findResolveTarget(p, lines, section, expected) : findPartTarget(p, lines, section, expected);
```

with, in the same places:

```js
  const header = section ? parse.sectionTable(lines, section).header : [];
```
```js
  if (p.branch !== env.branch) return verdict(VERDICT.wrongBranch, `the page was built on ${p.branch}; check out that branch and sync again`);
```
```js
  const found = findPartTarget(p, lines, section, expected);
```

- [x] **Step 5: Run the tests to verify they pass**

Run: `node tests/dashboard/test-10-sync-check.js | tail -1; node tests/dashboard/test-11-sync-apply.js | tail -1; grep -n -E "lineAtOccurrence|RESOLVED_MARK|SESSION_LOG|KIND\.resolve|DEFAULT_NOTE|findResolveTarget" skills/dashboard/scripts/dashboard-sync.js`
Expected: two lines `<n> passed, 0 failed`; the grep prints nothing.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [x] **Step 6: Commit**

```bash
git add skills/dashboard/scripts/dashboard-sync.js tests/dashboard/test-10-sync-check.js tests/dashboard/test-11-sync-apply.js
git commit -m "feat(dashboard): sync keeps only set-part; a resolve-open-item proposal is invalid" --trailer "Session: dashboard-sources" --trailer "Stage: task 1/12"
```

---

### Task 2: The extractor no longer builds `sessionOpenItems`; `sessions` is newest first; the open-item parser is removed

**Files:**
- Modify: `skills/dashboard/scripts/dashboard-extract.js`
- Modify: `skills/dashboard/scripts/dashboard-parse.js`
- Test: `tests/dashboard/test-05-extract-files.js`
- Test: `tests/dashboard/test-02-parse.js`
- Test: `tests/dashboard/test-06-privacy.js`

**Security flag:** `none`

**Does NOT cover:** the template (Task 3 removes the open-item card and adds the session date). It does not change `normalizeLine`, `occurrenceOf`, `lineItemId`, `RESOLVED_SUFFIX`, `SUPERSEDED_MARK`, `ID_SEPARATOR`, `SESSION_LOG` or `KIND.raw` (Global Constraint 3).

**Contract:**
- `sessionLog(context)` in `dashboard-extract.js`
  - Inputs: the extract context. Output: `{ sessions: <section> }` only.
  - Invariants: no `sessionOpenItems` key in any extractor output; `sessions` holds the `Goal:` items of the last `SESSION_ENTRIES` (10) entries that are not superseded, newest entry first, each with `entry` (the raw heading) and `goal`; item ids are the same as before (same `lineItem` call); a missing `session-log.md` gives `sessions` the not-found section; a malformed work-log table row still has `kind: 'raw'`.
  - Verification: `node tests/dashboard/test-05-extract-files.js` and `node tests/dashboard/test-06-privacy.js`.
  - Interface not externally pinned.
- Removal in `dashboard-parse.js` of `openItems`, `openItemText`, `lineAtOccurrence`, `RESOLVED_MARK`, `OPEN_LIST`, `OPEN_ONE_LINE`, `ONE_LINE_PREFIX`, `LIST_END`, `BULLET`, `CONTINUATION` and their exports
  - Invariants: `normalizeLine`, `occurrenceOf`, `lineItemId` are byte-for-byte unchanged; every other export stays.
  - Verification: `for f in normalizeLine occurrenceOf lineItemId; do diff <(git show 971beb2b:skills/dashboard/scripts/dashboard-parse.js | sed -n "/^function $f(/,/^}/p") <(sed -n "/^function $f(/,/^}/p" skills/dashboard/scripts/dashboard-parse.js) || echo "CHANGED: $f"; done` prints nothing (each of the three function texts, from its `function` line to its closing `}`, is compared whole with its text at 971beb2b); `git diff 971beb2b -- skills/dashboard/scripts/dashboard-parse.js | grep -E "^[-+].*(RESOLVED_SUFFIX =|SUPERSEDED_MARK =|ID_SEPARATOR =|SESSION_LOG =)"` prints nothing; `node tests/dashboard/test-02-parse.js` passes.
- `tests/dashboard/test-02-parse.js`, `test-05-extract-files.js`, `test-06-privacy.js` (edited)
  - Must convey: the dropped cases are exactly the open-item and `lineAtOccurrence` cases; the `normalizeLine` cases and the cases of every kept function stay.
  - Verification: `grep -n -E "openItems|openItemText|lineAtOccurrence|sessionOpenItems" tests/dashboard/test-02-parse.js tests/dashboard/test-05-extract-files.js tests/dashboard/test-06-privacy.js` prints only the two test-05 lines that assert the section is absent.

- [x] **Step 1: Write the failing test changes in `tests/dashboard/test-05-extract-files.js`**

Replace the block from `h.eq('sessionOpenItems: kinds and texts of the 10 recent entries', …` through `h.eq('sessions: the Goal lines of the same 10 entries', …);` (lines 78–89 at commit 971beb2b, nine statements) with:

```js
h.eq('no sessionOpenItems section', Object.prototype.hasOwnProperty.call(s, 'sessionOpenItems'), false);
h.eq('sessions: the Goal lines of the last 10 entries, newest first', s.sessions.items.map((item) => item.goal), ['goal 13', 'goal 12', 'goal 11', 'goal 10', 'goal 9', 'goal 8', 'goal 7', 'goal 6', 'goal 4', 'goal 3']);
h.eq('sessions: each item keeps its entry heading', [s.sessions.items[0].entry, s.sessions.items[9].entry], ['## 2026-01-13 [saved]', '## 2026-01-03 [saved]']);
h.eq('the second equal heading has ordinal 2', s.sessions.items[1].source.headingOrdinal, 2);
h.eq('an untracked session-log.md gives private items', s.sessions.items[0].visibility, 'private');
```

Replace `h.eq('a committed session-log.md gives tracked items', extract(d).sessionOpenItems.items[0].visibility, 'tracked');` with:

```js
h.eq('a committed session-log.md gives tracked items', extract(d).sessions.items[0].visibility, 'tracked');
```

Replace the line `const FILE_SECTIONS = ['activeWorklogs', 'closedWorklogs', 'sessionOpenItems', 'sessions', 'currentGoal', 'releases', 'runHistory', 'knownIssues'];` with:

```js
const FILE_SECTIONS = ['activeWorklogs', 'closedWorklogs', 'sessions', 'currentGoal', 'releases', 'runHistory', 'knownIssues'];
h.eq('a missing session-log.md gives no sessionOpenItems section', Object.prototype.hasOwnProperty.call(ms, 'sessionOpenItems'), false);
```

(The fixture keeps `session-log.md` with its `Open:` lines; the existing `activeWorklogs` assertion `['raw', null, null]` keeps the malformed-row `kind: 'raw'` check.)

- [x] **Step 2: Edit `tests/dashboard/test-06-privacy.js` and `tests/dashboard/test-02-parse.js`**

In `test-06-privacy.js`, replace `h.eq('untracked sources are not-found', [s.sessionOpenItems.status, s.currentGoal.status, s.knownIssues.status], ['not-found', 'not-found', 'not-found']);` with:

```js
h.eq('untracked sources are not-found', [s.sessions.status, s.currentGoal.status, s.knownIssues.status], ['not-found', 'not-found', 'not-found']);
```

In `test-02-parse.js`:
- replace the header comment line `// dashboard-parse.js: normalization, sections, ids, tables, open items,` with `// dashboard-parse.js: normalization, sections, ids, tables,`;
- delete the two lines `h.eq('lineAtOccurrence finds the second equal line', …);` and `h.eq('lineAtOccurrence gives -1 past the last', …);`;
- delete the block from `const entry = [` through `h.eq('openItemText strips the bullet and the one-line prefix', …);` (the `entry` fixture and the three `openItems`/`openItemText` checks).

Keep both `normalizeLine` checks and the `lineItemId uses the normalized line` check.

- [x] **Step 3: Run the tests to verify they fail**

Run: `node tests/dashboard/test-05-extract-files.js | grep FAIL`
Expected: FAIL for `no sessionOpenItems section`, `sessions: the Goal lines of the last 10 entries, newest first`, `sessions: each item keeps its entry heading`, `the second equal heading has ordinal 2` and `a missing session-log.md gives no sessionOpenItems section`.

- [x] **Step 4: Implement in `skills/dashboard/scripts/dashboard-extract.js`**

Search first (Global Constraint 2):

Run: `git grep -l -w -E "sessionOpenItems|openItem|olderUnresolved|openItems|openItemText|lineAtOccurrence|RESOLVED_MARK|OPEN_LIST|OPEN_ONE_LINE|ONE_LINE_PREFIX|LIST_END|BULLET|CONTINUATION"` (the whole repository, no pathspec)
Expected: exactly these files: `skills/dashboard/scripts/dashboard-extract.js`, `skills/dashboard/scripts/dashboard-parse.js`, `skills/dashboard/template.html` (Task 3 removes its names), `tests/dashboard/test-05-extract-files.js` (the two absence checks of Step 1), `tests/dashboard/test-07-template.js` and `tests/dashboard/test-08-template-edits.js` (Task 3 changes both). No other caller. (`-w` matches whole words only, so names such as `SHARED_BULLET` in other suites do not count.) Hits in documents under `docs/` (specs, plans, review logs and acceptance notes, this plan and its spec included) are not callers and do not count. This search also covers some names that Task 3 removes from the template (`EDIT_KIND.resolve` is covered by the search of Task 1; `ITEM_KIND.openItem` and the `sessionOpenItems` entries of `TABS` and `TITLES` by this one). The kind string `open-item` and the label `Mark resolved` are not matched by `-w openItem`; Task 3 Step 4 searches for them.

In `SECTION`, remove `sessionOpenItems: 'sessionOpenItems', `:

```js
const SECTION = {
  unfinishedRuns: 'unfinishedRuns', git: 'git', activeWorklogs: 'activeWorklogs',
  currentGoal: 'currentGoal', releases: 'releases', runHistory: 'runHistory', closedWorklogs: 'closedWorklogs',
  commits: 'commits', sessions: 'sessions', knownIssues: 'knownIssues',
};
```

In `KIND`, remove `openItem: 'open-item', ` (keep `raw: 'raw'`):

```js
const KIND = {
  run: 'run', branch: 'branch', commit: 'commit', worklog: 'worklog', worklogFile: 'worklog-file', part: 'part',
  worklogOpenItem: 'worklog-open-item', raw: 'raw', goal: 'goal', release: 'release',
  topic: 'topic', session: 'session', knownIssue: 'known-issue',
};
```

Replace the function `sessionLog` with:

```js
// The Goal: lines of the last SESSION_ENTRIES entries that are not
// superseded, newest entry first.
function sessionLog(context) {
  const text = context.source.read(parse.SESSION_LOG);
  if (text === null) return notFoundSection(SECTION.sessions, parse.SESSION_LOG);
  const lines = parse.splitLines(text);
  const entries = parse.headings(lines).filter((entry) => !entry.raw.includes(parse.SUPERSEDED_MARK));
  const sessions = [];
  for (const entry of entries.slice(-SESSION_ENTRIES)) {
    const goal = lines.slice(entry.index + 1, entry.end).findIndex((line) => line.startsWith(GOAL_PREFIX));
    if (goal !== -1) {
      const index = entry.index + 1 + goal;
      sessions.push(lineItem(context, parse.SESSION_LOG, lines, entry, index, { kind: KIND.session, entry: entry.raw, goal: lines[index].slice(GOAL_PREFIX.length) }));
    }
  }
  return { [SECTION.sessions]: okSection(sessions.reverse()) };
}
```

In `BUILDERS`, replace `{ ids: [SECTION.sessionOpenItems, SECTION.sessions], build: sessionLog },` with:

```js
  { ids: [SECTION.sessions], build: sessionLog },
```

- [x] **Step 5: Implement in `skills/dashboard/scripts/dashboard-parse.js`**

In the header comment, replace `// table rows, the open items of a session-log entry, the Node copy of the` with `// table rows, the Node copy of the`.

Delete these lines (keep `RESOLVED_SUFFIX`, `SUPERSEDED_MARK`, `ID_SEPARATOR` and every line around them unchanged):

```js
const RESOLVED_MARK = '[resolved';
```
```js
const OPEN_LIST = /^Open:\s*$/;
const OPEN_ONE_LINE = /^Open: (.*\S.*)$/;
const ONE_LINE_PREFIX = 'Open: ';
const LIST_END = /^[A-Za-z][A-Za-z0-9_-]*:/;
const BULLET = '- ';
const CONTINUATION = /^[ \t]+\S/;
```

Delete the whole functions `lineAtOccurrence`, `openItems` (with its comment block that starts `// The open items of the lines [start, end) of one entry`) and `openItemText`.

Replace the `module.exports` block with:

```js
module.exports = {
  HEADING_PREFIX, SUPERSEDED_MARK, WORKLOG_CLASS,
  SESSION_LOG, WORKLOG_DIR, PARTS_HEADING, OPEN_ITEMS_HEADING, PART_COLUMNS, OPEN_ITEM_COLUMNS,
  PART_STATUSES, NOTE_LIMIT, NOTE_FORBIDDEN, UNSAFE_CHARACTER,
  splitLines, normalizeHeading, normalizeLine, headings, findSection, occurrenceOf,
  splitRow, joinRow, sectionTable, columnIndex,
  itemId, lineItemId, keyItemId, worklogLine1, worklogClass, worklogNameValid, listingName,
  localIso, parseArguments, realPath, isInside,
};
```

- [x] **Step 6: Run the tests to verify they pass**

Run: `node tests/dashboard/test-02-parse.js | tail -1; node tests/dashboard/test-05-extract-files.js | tail -1; node tests/dashboard/test-06-privacy.js | tail -1; for f in normalizeLine occurrenceOf lineItemId; do diff <(git show 971beb2b:skills/dashboard/scripts/dashboard-parse.js | sed -n "/^function $f(/,/^}/p") <(sed -n "/^function $f(/,/^}/p" skills/dashboard/scripts/dashboard-parse.js) || echo "CHANGED: $f"; done; git diff 971beb2b -- skills/dashboard/scripts/dashboard-parse.js | grep -E "^[-+].*(RESOLVED_SUFFIX =|SUPERSEDED_MARK =|ID_SEPARATOR =|SESSION_LOG =)"`
Expected: three lines `<n> passed, 0 failed`; the loop and the grep print nothing.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [x] **Step 7: Commit**

```bash
git add skills/dashboard/scripts/dashboard-extract.js skills/dashboard/scripts/dashboard-parse.js tests/dashboard/test-02-parse.js tests/dashboard/test-05-extract-files.js tests/dashboard/test-06-privacy.js
git commit -m "feat(dashboard): drop session open items from the extractor; sessions newest first" --trailer "Session: dashboard-sources" --trailer "Stage: task 2/12"
```

---

### Task 3: The page drops the open-item card and the "Mark resolved" control; a session line starts with its entry date

**Files:**
- Modify: `skills/dashboard/template.html`
- Test: `tests/dashboard/test-07-template.js`
- Test: `tests/dashboard/test-08-template-edits.js`

**Security flag:** `none`

**Does NOT cover:** the "as of" line, the Git card, the Source lines and the shared-ref line (Tasks 5, 6, 8). A session `entry` that does not start with `## YYYY-MM-DD HH:MM` shows the goal alone; the template never parses another date form.

**Contract:**
- Template removals (`sessionOpenItems` in `TABS` and `TITLES`, the `open-item` case of `itemLines`, the `olderUnresolved` extra, the "Mark resolved" button, `EDIT_KIND.resolve`, `ITEM_KIND.openItem`, the resolve branches of `changesSomething`, `proposalBase`, `canEditItem`)
  - Invariants: the "Waits for me" tab holds `unfinishedRuns`, `git`, `activeWorklogs`, `currentGoal` in this order; the template text holds neither `Mark resolved` nor `resolve-open-item` nor `sessionOpenItems` nor `olderUnresolved`; `proposalBase` always builds a `set-part` proposal with `anchor.part` set; only a `part` item on a branch gets edit controls; a `set-part` edit still writes one pending proposal.
  - Verification: `node tests/dashboard/test-07-template.js`, `node tests/dashboard/test-08-template-edits.js`, and `grep -c -E "Mark resolved|resolve-open-item|sessionOpenItems|olderUnresolved|'open-item'" skills/dashboard/template.html` prints `0` (the opening quote of `'open-item'` keeps the work-log case `case 'worklog-open-item'`, which stays, out of the count).
- `sessionLine(item)` (the `session` case of `itemLines`)
  - Inputs: a `session` item with `entry` and `goal`. Output: one line.
  - Invariants: `entry` that starts with `## YYYY-MM-DD HH:MM` → `YYYY-MM-DD HH:MM · <goal>`; any other `entry`, or none → `<goal>`; never throws.
  - Verification: the two session checks of test-07.
  - Interface not externally pinned.
- `tests/dashboard/test-07-template.js` and `tests/dashboard/test-08-template-edits.js` (edited)
  - Must convey: the dropped or rewritten cases are exactly those of the open-item card, the open-item line and the "Mark resolved" control (with the write counts that included the open item); every `set-part` case and every case of another card stays.
  - Verification: both files pass; the task review compares the removed and changed lines of `git diff -- tests/dashboard/test-07-template.js tests/dashboard/test-08-template-edits.js` with this list.

- [x] **Step 1: Write the failing test changes in `tests/dashboard/test-07-template.js`**

In `sample()`, replace the `sessionOpenItems: { … },` line with:

```js
      sessions: { status: 'ok', note: '', items: [{ id: '2'.repeat(40), visibility: 'private', source: source('session-log.md'), kind: 'session', entry: '## 2026-09-28 10:00 [saved]', goal: PAYLOAD }] },
```

Replace `h.eq('tab 1 sections, in order', order('panel-waits'), ['unfinishedRuns', 'git', 'activeWorklogs', 'sessionOpenItems', 'currentGoal']);` with:

```js
h.eq('tab 1 sections, in order', order('panel-waits'), ['unfinishedRuns', 'git', 'activeWorklogs', 'currentGoal']);
```

Replace `h.check('the git counts and the older open items are shown', …);` with:

```js
h.check('the git counts are shown', doc.getElementById('panel-waits').textContent.includes('2 commits not pushed'));
const SESSION = { kind: 'session', goal: 'Rename the RDKit helper' };
h.eq('a session line starts with the date and time of its entry', app.itemLines(Object.assign({ entry: '## 2026-10-14 12:00 [saved]' }, SESSION)), ['2026-10-14 12:00 · Rename the RDKit helper']);
h.eq('an entry with no date and time, or no entry: the goal alone', [app.itemLines(Object.assign({ entry: '## Notes' }, SESSION)), app.itemLines(SESSION)], [['Rename the RDKit helper'], ['Rename the RDKit helper']]);
```

In the async part, replace the two expectations `[false, 5]` (in `a private page shows the banner and its sections`) and `5` (in `the fetched data renders its sections`) with `[false, 4]` and `4`.

- [x] **Step 2: Write the failing test changes in `tests/dashboard/test-08-template-edits.js`**

- Replace `const { fakeDocument, load, settle } = require('./fake-page');` with `const { TEMPLATE, fakeDocument, load, settle } = require('./fake-page');`.
- Delete the line `const OPEN_ID = 'o'.repeat(40);`.
- Replace the `changesSomething` check with:

```js
h.eq('changesSomething', [app.changesSomething(part, { status: 'in progress' }), app.changesSomething(part, { note: 'n' }), app.changesSomething(part, { status: 'done' })], [false, false, true]);
```

- In `data()`, delete the `sessionOpenItems: { … },` line.
- Replace the four lines from `h.eq('controls on the part and the open item only', …` through `h.eq('an applying proposal: its label and no control', …);` with:

```js
h.eq('a control on the part only', buttons(render('main', true, idleStore)).map((b) => b.textContent), ['Propose change']);
h.eq('a detached HEAD: no control', buttons(render(null, true, idleStore)).length, 0);
const busy = render('main', true, idleStore, new Map([[PART_ID, { doc: { state: 'applying', closedAt: null } }]]));
h.eq('an applying proposal: its label and no control', [buttons(busy).length, nodes(busy, 'SPAN').some((n) => n.textContent === 'sync in progress')], [0, true]);
h.check('the template has no "Mark resolved" control', !TEMPLATE.includes('Mark resolved'));
```

- In the async part, replace the block from `doc = render('main', true, store);` (the one followed by `buttons(doc)[1].listeners.click();`) through `h.eq('a note with | is not written', writes.length, 2);` with:

```js
  doc = render('main', true, store);
  nodes(doc, 'INPUT')[0].value = 'a | b';
  buttons(doc)[0].listeners.click();
  await settle();
  h.eq('a note with | is not written', writes.length, 1);
```

- Replace `h.eq('an edit that changes nothing is not written', writes.length, 2);` with `h.eq('an edit that changes nothing is not written', writes.length, 1);`.
- Replace `const noteOnPending = writes[2] || { doc: {} };` and its check with:

```js
  const noteOnPending = writes[1] || { doc: {} };
  h.eq('a note-only edit keeps the pending status', [writes.length, noteOnPending.doc.status, noteOnPending.doc.note], [2, 'done', 'added a note']);
```

- Replace `const noteOnDropped = writes[3] || { doc: {} };` and its check with:

```js
  const noteOnDropped = writes[2] || { doc: {} };
  h.eq('a note-only edit on a dropped part writes no status', [writes.length, 'status' in noteOnDropped.doc, noteOnDropped.doc.note], [3, false, 'why']);
```

- Replace the `listFails` block's two lines `doc = render('main', true, listFails);` and `buttons(doc)[1].listeners.click();` with:

```js
  doc = render('main', true, listFails);
  nodes(doc, 'SELECT')[0].value = 'done';
  buttons(doc)[0].listeners.click();
```

- Replace the two boot owner lines (the line that starts `const owner = await boot(fakeRuntime(true, [{ id: OPEN_ID,` and the check `h.eq('the owner gets the controls and the pending label', …)` after it) with:

```js
  const owner = await boot(fakeRuntime(true, [{ id: PART_ID, doc: { state: 'pending', closedAt: null } }], []));
  h.eq('the owner gets the control and the pending label', [buttons(owner).length, nodes(owner, 'SPAN').some((n) => n.textContent === 'pending sync'), owner.getElementById('viewer-warning').hidden], [1, true, true]);
```

- Replace the two `OPEN_ID` uses in `listedRuntime` (the store list and its expectation) with `PART_ID`.

- [x] **Step 3: Run the tests to verify they fail**

Run: `node tests/dashboard/test-07-template.js | grep FAIL; node tests/dashboard/test-08-template-edits.js | grep FAIL`
Expected: test-07 FAIL for `tab 1 sections, in order`, `a session line starts with the date and time of its entry`, `a private page shows the banner and its sections` and `the fetched data renders its sections` (the old `TABS` still lists `sessionOpenItems`, so the first tab has 5 cards); test-08 FAIL for `the template has no "Mark resolved" control`. (The other test-08 checks already pass: the data no longer holds an open item.)

- [x] **Step 4: Implement in `skills/dashboard/template.html`**

Search first (Global Constraint 2) for the two names that the searches of Task 1 and Task 2 do not cover, the kind string `open-item` and the label `Mark resolved`:

Run: `git grep -l -E "'open-item'|\"open-item\"|Mark resolved"` (the whole repository, no pathspec)
Expected: outside `docs/`, only `skills/dashboard/template.html` (the names this step removes) and the test files that Steps 1 and 2 changed (`tests/dashboard/test-07-template.js`, `tests/dashboard/test-08-template-edits.js`), where a hit can only be a check that the control or the card is absent. Task 2 has already removed the extractor's `openItem` kind and the test-05 lines that named it. Hits in documents under `docs/` are not callers and do not count.

Replace `TABS` and `TITLES` with:

```js
  const TABS = [
    { tab: 'tab-waits', panel: 'panel-waits', sections: ['unfinishedRuns', 'git', 'activeWorklogs', 'currentGoal'] },
    { tab: 'tab-history', panel: 'panel-history', sections: ['releases', 'runHistory', 'closedWorklogs', 'commits', 'sessions', 'knownIssues'] },
  ];
  const TITLES = {
    unfinishedRuns: 'Unfinished orchestration runs', git: 'Git', activeWorklogs: 'Active work logs',
    currentGoal: 'Current goal', releases: 'Releases',
    runHistory: 'Orchestration topics', closedWorklogs: 'Closed work logs', commits: 'Recent commits',
    sessions: 'Recent sessions', knownIssues: 'Known issues',
  };
```

Replace `const EDIT_KIND = { resolve: 'resolve-open-item', setPart: 'set-part' };` and `const ITEM_KIND = { openItem: 'open-item', part: 'part' };` with:

```js
  const EDIT_KIND = { setPart: 'set-part' };
  const ITEM_KIND = { part: 'part' };
  // The "YYYY-MM-DD HH:MM" at the start of a session-log entry heading, for
  // example "## 2026-10-14 12:00 [saved]".
  const ENTRY_TIME = /^## (\d{4}-\d{2}-\d{2} \d{2}:\d{2})/;
```

Add this function directly before `function itemLines(item) {`:

```js
  // One session line: the date and time of its entry, then the goal; the
  // goal alone when the entry heading does not start with a date and time.
  function sessionLine(item) {
    const time = ENTRY_TIME.exec(text(item.entry));
    return time ? `${time[1]} · ${text(item.goal)}` : text(item.goal);
  }
```

In `itemLines`, delete the line `case 'open-item': return [text(item.text)].concat((item.continuation || []).map(text));` and replace `case 'session': return [text(item.goal)];` with `case 'session': return [sessionLine(item)];`.

In `sectionExtras`, delete the line `if (id === 'sessionOpenItems' && section.olderUnresolved) lines.push(…);`.

Replace `changesSomething`, `proposalBase` and `canEditItem`, each with the comment block directly above it (the comment above `changesSomething` starts `// An open item always changes;`), with:

```js
  // A part edit changes something when a given status or note differs from
  // the current cell.
  function changesSomething(item, fields) {
    return (fields.status !== undefined && fields.status !== item.status) || (fields.note !== undefined && fields.note !== item.note);
  }
```
```js
  function proposalBase(item, data) {
    return {
      kind: EDIT_KIND.setPart,
      file: item.source.file,
      branch: data.commit.branch,
      baseCommit: data.commit.sha,
      anchor: { heading: item.source.heading, headingOrdinal: item.source.headingOrdinal, line: item.source.line, occurrence: item.source.occurrence, part: item.number },
    };
  }
```
```js
  function canEditItem(item, ctx) {
    return ctx.canEdit && item.kind === ITEM_KIND.part && ctx.data.commit.branch !== null;
  }
```

In `editControls`, replace the lines from `const start = item.kind === ITEM_KIND.part ? startStatus(item, existing) : null;` through the end of the click listener with:

```js
    const start = startStatus(item, existing);
    const status = statusList(start);
    const note = el('input', { type: 'text', maxlength: NOTE_LIMIT, placeholder: NOTE_HINT, 'aria-label': 'note' });
    const message = el('span', { className: 'muted', role: 'status' });
    const button = el('button', { type: 'button', text: 'Propose change' });
    const inputs = [status, note, button];
    button.addEventListener('click', () => {
      // A browser list always has a value: only a chosen status that differs
      // from the start status is a status change.
      const chosen = status.value;
      const change = chosen !== NO_STATUS_CHANGE && chosen !== start ? chosen : undefined;
      submitEdit(item, ctx, { status: change, noteText: note.value || '', message, inputs });
    });
```

- [x] **Step 5: Run the tests to verify they pass**

Run: `node tests/dashboard/test-07-template.js | tail -1; node tests/dashboard/test-08-template-edits.js | tail -1; grep -c -E "Mark resolved|resolve-open-item|sessionOpenItems|olderUnresolved|'open-item'" skills/dashboard/template.html`
Expected: two lines `<n> passed, 0 failed`; then `0`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [x] **Step 6: Commit**

```bash
git add skills/dashboard/template.html tests/dashboard/test-07-template.js tests/dashboard/test-08-template-edits.js
git commit -m "feat(dashboard): remove the open-item card and control; date the session lines" --trailer "Session: dashboard-sources" --trailer "Stage: task 3/12"
```

---

### Task 4: The extractor adds `commit.date`, local dates and the `current` mark; branch names use `lstrip=2`

**Files:**
- Modify: `skills/dashboard/scripts/dashboard-extract.js`
- Test: `tests/dashboard/test-04-extract-core.js`

**Security flag:** `none`

**Does NOT cover:** the template's use of these fields (Task 5). The shared run never sets `current`. On a detached HEAD no item is marked: `currentBranch()` of `git-runs.js` returns the constant `DETACHED` (`'detached'`) there, so the code compares with the branch name only when `current` is not `DETACHED`. As a result, a checked-out branch literally named `detached` gets no mark (the same limit that `commit.branch` already has; `git-runs.js` is not changed, Global Constraint 7). The checked-out branch is listed only when it is unmerged (no change to the selection).

**Contract:**
- `commitMeta(context)`: adds `date` = `git log -1 --no-walk --format=%cd --date=short-local <context.ref>`, in both audiences. `--no-walk` keeps git from reading the parent commits: without it, `git log -1` exits 128 on a history whose parent commit object is missing (checked on 2026-10-20 with git 2.50.1), and `commitMeta` runs outside the error handling of `buildSections`, so the extract would stop with a stack trace instead of giving the existing error sections that test-04 section 8 and test-06 case (10) expect. Where the command succeeds, its output is the same as without `--no-walk`.
- `commits(context)`: dates with `--date=short-local`.
- `localBranches(context)`: names with `%(refname:lstrip=2)`, dates with `%(committerdate:short-local)`; the item whose name equals the checked-out branch gets `current: true`, all others have no `current` field.
- `sharedBranches(context)`: dates with `--date=short-local`; never a `current` field.
- `localBranchNames()`: names with `%(refname:lstrip=2)`.
  - Invariants: `commit.date` matches `^\d{4}-\d{2}-\d{2}$`; under `TZ=Asia/Tokyo` a commit at `2026-01-09T23:30:00+00:00` gives `2026-01-10` in `commit.date`, the branch date and the commit dates; with a tag that has the name of the checked-out branch, the item name is still the plain branch name and still carries `current: true`; on the default branch no item has `current`.
  - Verification: `node tests/dashboard/test-04-extract-core.js`; `grep -c "refname:short\|--date=short'\|committerdate:short)" skills/dashboard/scripts/dashboard-extract.js` prints `0`.
  - Interface not externally pinned.

- [x] **Step 1: Write the failing tests in `tests/dashboard/test-04-extract-core.js`**

After `h.check('commit sha and short hash', …);` add:

```js
h.check('commit.date is a date', /^\d{4}-\d{2}-\d{2}$/.test(doc.commit.date || ''), String(doc.commit.date));
```

After `h.eq('git: unmerged local branches, the default branch excluded', …);` add:

```js
h.eq('git: with the default branch checked out no item is marked current', doc.sections.git.items.some((i) => 'current' in i), false);
```

After `h.eq('the checked-out run branch is still an unfinished run', …);` (section 4) add:

```js
const currentItems = (sections) => sections.git.items.filter((i) => 'current' in i).map((i) => [i.name, i.current]);
h.eq('git: only the checked-out unmerged branch is marked current', currentItems(doc.sections), [['feature/stopped', true]]);
h.git(d, 'tag', 'feature/stopped');
h.eq('a tag with the name of the branch: the plain name, still current', currentItems(extract(d).sections), [['feature/stopped', true]]);
h.git(d, 'tag', '-d', 'feature/stopped');
```

Before `h.finish();` add:

```js
// 10. Local dates (spec section 4.4): a commit at 23:30 UTC is on the next
// day in Tokyo (UTC+9). `--date=short` would print the committer's date;
// `short-local` prints the local date.
const LATE = '2026-01-09T23:30:00+00:00';
const TOKYO = { TZ: 'Asia/Tokyo' };
const LOCAL_DAY = '2026-01-10';
const tz = h.repo('core-local-dates');
h.write(tz, 'file.txt', 'base\n');
h.commit(tz, 'late base', ['file.txt'], LATE);
h.git(tz, 'checkout', '-q', '-b', 'feature/late');
h.write(tz, 'file.txt', 'late\n');
h.commit(tz, 'late branch', ['file.txt'], LATE);
const tzRun = h.node(tz, [EXTRACT, '--audience', 'private'], TOKYO);
const tzDoc = tzRun.code === 0 ? JSON.parse(tzRun.out) : null;
h.eq('local dates: commit.date, the branch date and the commit dates', tzDoc && [tzDoc.commit.date, tzDoc.sections.git.items.map((i) => i.date), tzDoc.sections.commits.items.map((i) => i.date)], [LOCAL_DAY, [LOCAL_DAY], [LOCAL_DAY, LOCAL_DAY]]);
h.git(tz, 'checkout', '-q', 'main');
```

- [x] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard/test-04-extract-core.js | grep FAIL`
Expected: FAIL for `commit.date is a date`, `git: only the checked-out unmerged branch is marked current`, `a tag with the name of the branch: the plain name, still current` (got `heads/feature/stopped` or no item) and `local dates: …` (got `2026-01-09` dates and no `commit.date`).

- [x] **Step 3: Implement in `skills/dashboard/scripts/dashboard-extract.js`**

Add after `const FIELD_SEPARATOR = '\x1f';`:

```js
// Every date that the extractor computes is a date in the local time zone,
// the zone of generatedAt (spec section 4.4).
const LOCAL_DATE = 'short-local';
const SHORT_LENGTH = 7;
```

Replace the `items` statement of `localBranches` with:

```js
  const current = currentBranch();
  // On a detached HEAD, currentBranch() returns DETACHED: no item is current.
  const isCurrent = (name) => current !== DETACHED && name === current;
  const items = mustLines(['for-each-ref', ...filter, `--format=%(refname:lstrip=2)%09%(committerdate:${LOCAL_DATE})`, HEADS])
    .map((row) => row.split('\t'))
    .filter(([name]) => name !== base)
    .map(([name, date]) => keyItem(context, SECTION.git, name, null, Object.assign({ kind: KIND.branch, name, date }, isCurrent(name) ? { current: true } : {})));
```

In `sharedBranches`, replace `const date = must(['log', '-1', '--format=%cd', '--date=short', upstream]);` with:

```js
    const date = must(['log', '-1', '--format=%cd', `--date=${LOCAL_DATE}`, upstream]);
```

In `commits`, replace `'--date=short'` with `` `--date=${LOCAL_DATE}` ``.

Replace `commitMeta` with:

```js
function commitMeta(context) {
  const sha = must(['rev-parse', `${context.ref}^{commit}`]);
  // The shared run never reads HEAD.
  const current = context.shared ? null : currentBranch();
  return {
    sha,
    short: sha.slice(0, SHORT_LENGTH),
    // --no-walk: read only this commit, never its parents (a missing parent
    // object must not stop the extract).
    date: must(['log', '-1', '--no-walk', '--format=%cd', `--date=${LOCAL_DATE}`, context.ref]),
    branch: context.shared ? remoteName(context.ref) : (current === DETACHED ? null : current),
    ref: context.ref,
    defaultBranch: context.shared ? null : defaultBranch(),
  };
}
```

Replace the body of `localBranchNames` with:

```js
  return mustLines(['for-each-ref', '--format=%(refname:lstrip=2)', HEADS]);
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `node tests/dashboard/test-04-extract-core.js | tail -1; grep -c "refname:short\|--date=short'\|committerdate:short)" skills/dashboard/scripts/dashboard-extract.js`
Expected: `<n> passed, 0 failed`; then `0`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [x] **Step 5: Commit**

```bash
git add skills/dashboard/scripts/dashboard-extract.js tests/dashboard/test-04-extract-core.js
git commit -m "feat(dashboard): commit date, local dates and the current branch mark" --trailer "Session: dashboard-sources" --trailer "Stage: task 4/12"
```

---

### Task 5: The page shows the true "as of" line and a Git card sorted by date, with `[current]` and folded old branches

**Files:**
- Modify: `skills/dashboard/template.html`
- Test: `tests/dashboard/test-07-template.js`

**Security flag:** `none`

**Does NOT cover:** the extractor (Task 4 adds the fields). An item whose `date` is not of the form `YYYY-MM-DD` but not empty counts as dated for the order and is never folded (its day count is `null`). Sorting does not use the extractor order.

**Contract:**
- `asOfLine(data)`
  - Inputs: the page data. Output: one line.
  - Invariants: exactly the forms of Global Constraint 9; the count part appears only when `sections.git.dirty` is a number > 0; the shared page (dirty `null`) never shows it; the build time keeps the `YYYY-MM-DD HH:MM` cut of `generatedAt`.
  - Verification: the as-of checks of test-07.
- `calendarDays(from, to)`
  - Inputs: two texts that start with `YYYY-MM-DD`. Output: the calendar-day difference computed with `Date.UTC` (Global Constraint 8), or `null` when one has no date.
  - Verification: the fold checks at 90 and 91 days of test-07 (Task 8 adds the daylight-saving check).
- Git card rendering (`byDateThenName`, `splitBranches`, `itemBlocks`, the `branch` case of `itemLines`)
  - Invariants: Global Constraint 16; both audiences sort and fold the same way.
  - Verification: the git-card checks of test-07.
  - Interface not externally pinned.

- [ ] **Step 1: Write the failing tests in `tests/dashboard/test-07-template.js`**

In `sample()`, replace the `commit:` line with:

```js
    commit: { sha: 'a'.repeat(40), short: 'aaaaaaa', date: '2026-09-29', branch, ref: 'HEAD', defaultBranch: 'main' },
```

Replace the two as-of checks (`h.eq('the as-of line on a branch', …);` and `h.eq('the as-of line on a detached HEAD', …);`) with:

```js
const BUILT_PART = ' · built 2026-09-29 20:40';
const asOf = (audience, branch, dirty) => {
  const data = sample(audience, branch);
  data.sections.git.dirty = dirty;
  return app.asOfLine(data);
};
h.eq('the as-of line of the rendered page', doc.getElementById('as-of').textContent, `as of commit aaaaaaa (2026-09-29) on branch main${BUILT_PART} · 1 tracked file changed, not committed`);
h.eq('the as-of line: detached with 2 changed files, a branch with none, the shared page', [asOf('private', null, 2), asOf('private', 'main', 0), asOf('shared', 'origin/main', null)], [
  `as of commit aaaaaaa (2026-09-29), detached HEAD${BUILT_PART} · 2 tracked files changed, not committed`,
  `as of commit aaaaaaa (2026-09-29) on branch main${BUILT_PART}`,
  `as of commit aaaaaaa (2026-09-29) on branch origin/main${BUILT_PART}`,
]);
```

After `h.check('the git counts are shown', …);` add:

```js
// The Git card (spec section 4.6): order, [current], the fold at 90 days.
const DAY_MS = 24 * 60 * 60 * 1000;
const SAMPLE_DAY = Date.UTC(2026, 8, 29);
const daysBefore = (n) => new Date(SAMPLE_DAY - n * DAY_MS).toISOString().slice(0, 10);
const branchItem = (name, date, extra) => Object.assign({ id: `b-${name}`, visibility: 'tracked', source: source(null), kind: 'branch', name }, date === undefined ? {} : { date }, extra || {});
const SHARED_VIEW = { data: sample('shared', 'origin/main'), canEdit: false, proposals: new Map(), store: null };
function gitCard(items, view) {
  const card = app.renderSection('git', { status: 'ok', note: '', ahead: null, dirty: null, items }, view || VIEW);
  const names = (list) => list.children.map((li) => li.children[0].textContent.split(' · ')[0]);
  const list = card.children.find((node) => node.tagName === 'UL');
  const details = card.children.find((node) => node.tagName === 'DETAILS');
  return { shown: list ? names(list) : [], summary: details ? details.children[0].textContent : null, folded: details ? names(details.children[1]) : [] };
}
const BRANCHES = [
  branchItem('x-empty', ''), branchItem('old91', daysBefore(91)), branchItem('b-new', daysBefore(1)), branchItem('y-null', null),
  branchItem('cur', daysBefore(300), { current: true }), branchItem('a-new', daysBefore(1)), branchItem('edge90', daysBefore(90)),
  branchItem('z-missing'), branchItem('older200', daysBefore(200)),
];
const EXPECTED_CARD = {
  shown: ['a-new', 'b-new', 'edge90', 'cur [current]', 'x-empty', 'y-null', 'z-missing'],
  summary: '2 older branches (no commit in the last 90 days)',
  folded: ['old91', 'older200'],
};
h.eq('git card: newest first, then by name; no date last; the current branch never folded; old branches folded in order', gitCard(BRANCHES), EXPECTED_CARD);
h.eq('git card: the shared page sorts and folds the same way', gitCard(BRANCHES, SHARED_VIEW), EXPECTED_CARD);
h.eq('git card: one old branch', gitCard([branchItem('a', daysBefore(1)), branchItem('old', daysBefore(91))]).summary, '1 older branch (no commit in the last 90 days)');
h.eq('git card: no old branch makes no details element', gitCard([branchItem('a', daysBefore(90))]), { shown: ['a'], summary: null, folded: [] });
```

(`VIEW`, `source` and `sample` are defined earlier in the file; place this block after the line that defines `VIEW`.)

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard/test-07-template.js | grep FAIL`
Expected: FAIL for the two as-of checks and for three of the four git-card checks (got the old `, built` form and the extractor order with no `<details>`). The check `git card: no old branch makes no details element` already passes before the change: the old page also makes no `<details>` element.

- [ ] **Step 3: Implement in `skills/dashboard/template.html`**

Add after `const NOTHING_HERE = 'nothing here';`:

```js
  const GIT_SECTION = 'git';
  // Branches with no commit for more than this many days are folded.
  const BRANCH_FOLD_DAYS = 90;
  const FOLD_REASON = `(no commit in the last ${BRANCH_FOLD_DAYS} days)`;
  const CURRENT_MARK = ' [current]';
  const DAY_MS = 24 * 60 * 60 * 1000;
  const DATE_PART = /^(\d{4})-(\d{2})-(\d{2})/;
```

Replace the `branch` case of `itemLines` with:

```js
      case 'branch': return [`${text(item.name)}${item.current === true ? CURRENT_MARK : ''} · last commit ${text(item.date)}`];
```

In `sectionExtras`, replace the two `id === 'git'` tests with `id === GIT_SECTION`.

Replace `asOfLine` with:

```js
  function asOfLine(data) {
    const commit = data.commit;
    const generated = text(data.generatedAt);
    const where = commit.branch === null
      ? `as of commit ${text(commit.short)} (${text(commit.date)}), detached HEAD`
      : `as of commit ${text(commit.short)} (${text(commit.date)}) on branch ${text(commit.branch)}`;
    const git = data.sections && data.sections[GIT_SECTION];
    const dirty = git ? git.dirty : null;
    const changed = typeof dirty === 'number' && dirty > 0 ? ` · ${dirty} tracked ${dirty === 1 ? 'file' : 'files'} changed, not committed` : '';
    return `${where} · built ${generated.slice(0, 10)} ${generated.slice(11, 16)}${changed}`;
  }

  // The number of calendar days from the date at the start of <from> to the
  // date at the start of <to> (YYYY-MM-DD), or null when one has no date.
  // Only the dates count, so a daylight-saving change never shifts the
  // result (spec section 4.4).
  function calendarDays(from, to) {
    const a = DATE_PART.exec(text(from));
    const b = DATE_PART.exec(text(to));
    if (!a || !b) return null;
    return (Date.UTC(Number(b[1]), Number(b[2]) - 1, Number(b[3])) - Date.UTC(Number(a[1]), Number(a[2]) - 1, Number(a[3]))) / DAY_MS;
  }

  // A branch "without a date": its date is missing, null or empty.
  const hasDate = (item) => Boolean(item.date);

  // Newest date first, then name; branches without a date last, by name.
  function byDateThenName(a, b) {
    if (hasDate(a) !== hasDate(b)) return hasDate(a) ? -1 : 1;
    if (hasDate(a) && a.date !== b.date) return a.date < b.date ? 1 : -1;
    const left = text(a.name);
    const right = text(b.name);
    return left < right ? -1 : (left > right ? 1 : 0);
  }

  // The sorted branch items, split into those shown one by one and those
  // folded: a dated branch more than BRANCH_FOLD_DAYS days before the date of
  // <generatedAt>, never the current branch.
  function splitBranches(items, generatedAt) {
    const sorted = items.slice().sort(byDateThenName);
    const old = (item) => {
      const days = item.current === true || !hasDate(item) ? null : calendarDays(item.date, generatedAt);
      return days !== null && days > BRANCH_FOLD_DAYS;
    };
    return { shown: sorted.filter((item) => !old(item)), folded: sorted.filter(old) };
  }
```

Add directly before `function renderSection(id, section, ctx) {`:

```js
  function itemList(items, ctx) {
    return el('ul', { className: 'items' }, items.map((item) => renderItem(item, ctx)));
  }

  // The item blocks of a card. The Git card is sorted by date and folds old
  // branches into one <details> element (spec section 4.6); every other card
  // is one list in data order.
  function itemBlocks(id, items, ctx) {
    if (!items.length) return [];
    if (id !== GIT_SECTION) return [itemList(items, ctx)];
    const { shown, folded } = splitBranches(items, ctx.data.generatedAt);
    const blocks = shown.length ? [itemList(shown, ctx)] : [];
    if (folded.length) {
      const summary = folded.length === 1 ? `1 older branch ${FOLD_REASON}` : `${folded.length} older branches ${FOLD_REASON}`;
      blocks.push(el('details', {}, [el('summary', { text: summary }), itemList(folded, ctx)]));
    }
    return blocks;
  }
```

In `renderSection`, replace the last list line `if (section.items.length) card.appendChild(el('ul', { className: 'items' }, section.items.map((item) => renderItem(item, ctx))));` with:

```js
    itemBlocks(id, section.items, ctx).forEach((node) => card.appendChild(node));
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `node tests/dashboard/test-07-template.js | tail -1; node tests/dashboard/test-08-template-edits.js | tail -1`
Expected: two lines `<n> passed, 0 failed`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [ ] **Step 5: Commit**

```bash
git add skills/dashboard/template.html tests/dashboard/test-07-template.js
git commit -m "feat(dashboard): true as-of line; Git card by date with current mark and fold" --trailer "Session: dashboard-sources" --trailer "Stage: task 5/12"
```

---

### Task 6: Every card has a "Source:" line

**Files:**
- Modify: `skills/dashboard/template.html`
- Test: `tests/dashboard/test-07-template.js`
- Test: `tests/dashboard/test-08-template-edits.js`

**Security flag:** `none`

**Does NOT cover:** a section id that has no sentence in `SOURCES` gets no Source line (all ten current ids have one). The wording of the selection rules is checked against the code by the plan review, not by a test (spec section 7, failure mode 2).

**Contract:**
- `SOURCES`, `SHARED_SOURCES`, `SOURCE_PREFIX`, `sourceLine(id, audience)` and the `renderSection` change
  - Must convey: for each section, where its items are read (file, folder or git command; for `unfinishedRuns` and `runHistory` the folder and the kind of refs scanned) and the rule that selects them; on the shared page, the shared run's own source for `unfinishedRuns`, `git` and `commits`.
  - Invariants: Global Constraint 6. The Source line is `card.children[1]` (directly after `<h2>`) with class `muted source` in all five states; exactly one `Source: ` line per card; on the shared page a `SHARED_SOURCES` sentence replaces the `SOURCES` one; no sentence holds an absolute path; the sentences of `sessions`, `commits` (both tables) and `releases` contain the values of `SESSION_ENTRIES`, `COMMIT_LIMIT`, `RELEASE_LIMIT` read from the extractor source.
  - Verification: the Source checks of test-07 and the numbers check of test-08.
  - Sentence wording is free within these rules; the reference sentences below were checked against the builders of `dashboard-extract.js` and `scanRuns` of `skills/pickup/scripts/git-runs.js`. No test reads the selection rule of a sentence (spec section 7, failure mode 2): an implementer who changes a reference sentence checks the new text against the builder of its section, and the whole-branch code review checks every changed sentence the same way.

- [ ] **Step 1: Write the failing tests**

In `tests/dashboard/test-07-template.js`, replace `const cardLines = (card) => card.children.slice(1).map((line) => [line.getAttribute('class'), line.textContent]);` with:

```js
// children[0] is the title and children[1] the Source line.
const cardLines = (card) => card.children.slice(2).map((line) => [line.getAttribute('class'), line.textContent]);
```

After the git-card block of Task 5, add:

```js
// The Source line (spec section 4.3): directly after the title, in every state.
const SECTION_IDS = ['unfinishedRuns', 'git', 'activeWorklogs', 'currentGoal', 'releases', 'runHistory', 'closedWorklogs', 'commits', 'sessions', 'knownIssues'];
const SOURCE_STATES = {
  'with items': { status: 'ok', note: '', items: [{ id: 'i'.repeat(40), visibility: 'tracked', source: source(null), kind: 'known-issue', title: 't' }] },
  empty: { status: 'ok', note: '', items: [] },
  'not found': { status: 'not-found', note: 'x not found', items: [] },
  failed: { status: 'error', note: 'git command failed', items: [] },
  absent: undefined,
};
const sourceOf = (id, state, view) => {
  const card = app.renderSection(id, state, view);
  return [card.children[0].tagName, card.children[1].getAttribute('class'), card.children[1].textContent, card.textContent.split('Source: ').length - 1];
};
h.check('every section has a sentence', SECTION_IDS.every((id) => typeof app.SOURCES[id] === 'string' && app.SOURCES[id].length > 0));
for (const id of SECTION_IDS) {
  for (const [label, state] of Object.entries(SOURCE_STATES)) {
    h.eq(`the Source line of ${id}, ${label}`, sourceOf(id, state, VIEW), ['H2', 'muted source', `Source: ${app.SOURCES[id]}`, 1]);
  }
  const sharedSentence = app.SHARED_SOURCES[id] || app.SOURCES[id];
  h.eq(`the shared Source line of ${id}`, sourceOf(id, SOURCE_STATES.empty, SHARED_VIEW), ['H2', 'muted source', `Source: ${sharedSentence}`, 1]);
  if (app.SHARED_SOURCES[id]) h.check(`the shared card of ${id} does not show the private sentence`, !app.renderSection(id, SOURCE_STATES.empty, SHARED_VIEW).textContent.includes(app.SOURCES[id]));
}
h.eq('SHARED_SOURCES replaces the sentences of unfinishedRuns, git and commits', Object.keys(app.SHARED_SOURCES).sort(), ['commits', 'git', 'unfinishedRuns']);
const ALL_SENTENCES = Object.values(app.SOURCES).concat(Object.values(app.SHARED_SOURCES));
h.check('no sentence holds an absolute path or a home folder', ALL_SENTENCES.every((sentence) => !/(^|\s|\()(\/|~|[A-Za-z]:[\\/])/.test(sentence)));
```

In `tests/dashboard/test-08-template-edits.js`, add `const fs = require('fs');` after `'use strict';` and the header comment, and add before `h.finish();` (inside the async block):

```js
  // 8. The numbers of the Source sentences equal the limits of the extractor
  // (spec section 4.3). The extractor exports nothing, so the test reads its
  // source text: an accepted exception to the rule of spec section 6.
  const extractSource = fs.readFileSync(path.join(h.SCRIPTS, 'dashboard-extract.js'), 'utf8');
  const limitOf = (name) => Number((extractSource.match(new RegExp(`^const ${name} = (\\d+);$`, 'm')) || [])[1]);
  const NUMBERED = [
    ['sessions', 'SESSION_ENTRIES', [app.SOURCES]],
    ['commits', 'COMMIT_LIMIT', [app.SOURCES, app.SHARED_SOURCES]],
    ['releases', 'RELEASE_LIMIT', [app.SOURCES]],
  ];
  for (const [id, name, tables] of NUMBERED) {
    const value = limitOf(name);
    h.check(`${name} is read from the extractor source`, Number.isInteger(value), String(value));
    tables.forEach((table, i) => h.check(`the ${i ? 'shared ' : ''}sentence of ${id} names ${name} = ${value}`, new RegExp(`\\b${value}\\b`).test(String(table && table[id]))));
  }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `node tests/dashboard/test-07-template.js | grep -c FAIL; node tests/dashboard/test-08-template-edits.js | grep FAIL`
Expected: a non-zero count for test-07 (`every section has a sentence` and every Source check fail: `app.SOURCES` is undefined, so the checks throw or fail); test-08 FAIL lines for the four `sentence of …` checks.

(If test-07 stops at a thrown `TypeError` on `app.SOURCES[id]` before `finish()`, the file reports `finish() was never called`; that is the expected failure too.)

- [ ] **Step 3: Implement in `skills/dashboard/template.html`**

Add after the `TITLES` constant:

```js
  const SHARED = 'shared';
  // The "Source:" line of each card: where the card reads its items, and the
  // rule that selects them. Paths are relative to the repository root.
  // tests/dashboard/test-08-template-edits.js checks that the numbers below
  // equal SESSION_ENTRIES, COMMIT_LIMIT and RELEASE_LIMIT of
  // scripts/dashboard-extract.js.
  const SOURCE_PREFIX = 'Source: ';
  const SOURCE_CLASS = 'muted source';
  const SOURCES = {
    unfinishedRuns: 'The orchestration logs in docs/superpowers-orchestrator/ on the local feature/<slug> branches that are not merged into the default branch; a branch is listed while its one log has no "_Completed — " line, or when it has more than one log.',
    git: 'Local branches that are not merged into the default branch, with the date of their last commit (git for-each-ref); the commits of the checked-out branch that are not in its upstream (git rev-list) and the tracked files with uncommitted changes (git status).',
    activeWorklogs: 'Work logs in docs/worklogs/ whose line 1 says status=active: their parts that are not started or in progress, and the rows of their open items table; a file that cannot be read as a work log is listed with a note.',
    currentGoal: 'The text under the ## Current Goal heading of state.md.',
    releases: 'The version in VERSION (or in package.json) and the first 15 headings of the form ## v<version> or ## [<version>], in file order, of RELEASE-NOTES.md (or CHANGELOG.md).',
    runHistory: 'Topic folders <date>-<slug> in docs/superpowers-orchestrator/: their specs, plans and implementation folders, and the ## headings of their orchestration logs.',
    closedWorklogs: 'Work logs in docs/worklogs/ whose line 1 says status=closed.',
    commits: 'The last 20 commits of the checked-out branch or commit (git log).',
    sessions: 'The Goal: lines of the last 10 entries of session-log.md that are not superseded, newest first.',
    knownIssues: 'The ## headings of known-issues.md.',
  };
  // The sentence of the shared page for the sections that the shared run
  // reads from another place; it is shown instead of the SOURCES sentence.
  const SHARED_SOURCES = {
    unfinishedRuns: 'The orchestration logs in docs/superpowers-orchestrator/ on the upstreams, on the shared remote, of the local feature/<slug> branches, when the upstream is not merged into the upstream of the default branch; a branch is listed while its one log has no "_Completed — " line, or when it has more than one log.',
    git: 'The upstreams on the shared remote of the local branches, other than the shared ref, that are not merged into the upstream of the default branch, with the date of their last commit (git log).',
    commits: 'The last 20 commits of the shared ref (git log).',
  };
```

Add directly before `function renderSection(id, section, ctx) {`:

```js
  // The Source line of a card, or null when the section has no sentence.
  function sourceLine(id, audience) {
    const sentence = audience === SHARED && SHARED_SOURCES[id] ? SHARED_SOURCES[id] : SOURCES[id];
    return sentence ? el('p', { className: SOURCE_CLASS, text: `${SOURCE_PREFIX}${sentence}` }) : null;
  }
```

In `renderSection`, replace the first line `const card = el('article', { className: 'card', 'data-section': id }, [el('h2', { text: TITLES[id] || id })]);` with:

```js
    const card = el('article', { className: 'card', 'data-section': id }, [el('h2', { text: TITLES[id] || id }), sourceLine(id, ctx.data.audience)]);
```

In the `globalThis.DashboardApp` export, replace `PART_STATUSES, NOTE_LIMIT, NOTE_FORBIDDEN,` with:

```js
    PART_STATUSES, NOTE_LIMIT, NOTE_FORBIDDEN, SOURCES, SHARED_SOURCES,
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `node tests/dashboard/test-07-template.js | tail -1; node tests/dashboard/test-08-template-edits.js | tail -1`
Expected: two lines `<n> passed, 0 failed`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [ ] **Step 5: Commit**

```bash
git add skills/dashboard/template.html tests/dashboard/test-07-template.js tests/dashboard/test-08-template-edits.js
git commit -m "feat(dashboard): a Source line on every card" --trailer "Session: dashboard-sources" --trailer "Stage: task 6/12"
```

---

### Task 7: The private extract computes `sharedRef` and reports the shared-page line on standard error

**Files:**
- Modify: `skills/dashboard/scripts/dashboard-extract.js`
- Test: `tests/dashboard/test-04-extract-core.js`

**Security flag:** `security` (the task reads `config.json` and two state files outside the repository, and passes a value stored by hand with `--config-set` to git commands; the value must never reach a shell, must never be read as a git option, and an error message must never print an absolute path)

**Does NOT cover:** the page line and its classes (Task 8); the `--verify` guard (Task 9); a `git fetch` (the line describes the local remote-tracking ref, spec section 7 failure mode 4); a remote looked up by name (a removed or renamed remote shows as `missing` through check 2). `refresh` never changes `sharedRef` (Global Constraint 17). An unsubstituted or empty `--data-dir` gives `null` here, while the state commands still stop on it.

**Contract:**
- `sharedRefState(context, dataDir)`, `followedRef(context, name)`, `publishTime(dir, name)`, `readJsonOrNull(file)`, `oneLine(context, message)`, `sharedRefForm(name)`
  - Inputs: the extract context and the `--data-dir` value. Output: the `sharedRef` value of Global Constraint 11.
  - Invariants: Global Constraints 10 and 11; the private run never calls `checkSharedName`, `sharedRemote` or `stop()` from these functions; every git command after the form check names `refs/remotes/<name>` and passes the value as one argument of `spawnSync` (no shell); the shared run's data has no `sharedRef` key; every error message is sanitized and one line; the private extract exits 0 in every case of spec section 4.5.
  - Verification: section 11 of `node tests/dashboard/test-04-extract-core.js` (every case of the spec's test-04 row: no `--data-dir`, no `config.json`, invalid `config.json`, sharing off without and with `sharedUrl`, following with `notShown` 0, 1 and 2, `published`/`previousBuild` present, missing and invalid, missing ref, removed remote, wrong form, single quote, not a commit; local dates under `TZ=Asia/Tokyo`; all exits 0).
  - Interface not externally pinned — the field shape is pinned by Global Constraint 11.
- `sharedRefLine(info, branch)` and the report in `main()`
  - Invariants: Global Constraints 12 and 14; the line is written once, after the document, only when `sharedRef` is not `null`; standard output carries only the JSON document (or the `written` line with `--out`).
  - Verification: the report-line checks of section 11 of test-04; Task 8's same-wording test compares it with the page line.
- `requireSharedRefForm(name, label)` refactored to use `sharedRefForm(name)`
  - Invariant: the same names pass and stop as before.
  - Verification: `node tests/dashboard/test-06-privacy.js` (the malformed-ref and shell-character cases) passes unchanged.

- [ ] **Step 1: Write the failing tests in `tests/dashboard/test-04-extract-core.js`**

Before `h.finish();` (after section 10 of Task 4) add:

```js
// 11. The shared-ref line of the private run (spec section 4.5): read from
// config.json and the state files through --data-dir; never a stop.
const sr = h.repo('core-shared-ref');
h.addRemote(sr, 'core-shared-ref-remote');
h.write(sr, 'file.txt', 'base\n');
h.commit(sr, 'base', ['file.txt'], LATE);
h.git(sr, 'push', '-q', '-u', 'origin', 'main');
const srData = path.join(h.ROOT, 'shared-ref-data');
const REPORT = 'dashboard-extract: shared page: ';
const exits = [];
// One private run in <sr> with <args>, in Tokyo time; gives
// [the sharedRef value, the report lines without their prefix]. A document
// without the key gives a text, so that "absent" never passes as null.
const NO_KEY = 'no sharedRef key';
function sharedRefRun(args) {
  const result = h.node(sr, [EXTRACT, '--audience', 'private', ...args], TOKYO);
  exits.push(result.code);
  const reports = result.err.split('\n').filter((line) => line.startsWith(REPORT)).map((line) => line.slice(REPORT.length));
  if (result.code !== 0) return [`exit ${result.code}: ${result.err}`, reports];
  const parsed = JSON.parse(result.out);
  return [Object.prototype.hasOwnProperty.call(parsed, 'sharedRef') ? parsed.sharedRef : NO_KEY, reports];
}
const withData = () => sharedRefRun(['--data-dir', srData]);
const setKey = (assignment) => run(sr, ['--data-dir', srData, '--config-set', assignment]);
const srState = run(sr, ['--data-dir', srData, '--state-dir']).out.trim();
const stateFile = (name, content) => fs.writeFileSync(path.join(srState, name), content);
const removeState = (...names) => names.forEach((name) => fs.rmSync(path.join(srState, name), { force: true }));
const NEVER = 'Never published from this machine.';

h.eq('no line: no --data-dir', sharedRefRun([]), [null, []]);
h.eq('no line: no config.json', withData(), [null, []]);
stateFile('config.json', 'not json');
h.eq('no line: a config.json that is not valid JSON', withData(), [null, []]);
removeState('config.json');
setKey('sharing=off');
h.eq('no line: sharing off without sharedUrl', withData(), [null, []]);
setKey('sharedUrl=https://claude.ai/code/artifact/shared');
h.eq('sharing off with sharedUrl', withData(), [{ off: true, published: null }, [`Sharing is off. The shared page from an earlier share is still published and is no longer updated. ${NEVER}`]]);
setKey('sharing=on');
setKey('sharedRef=origin/main');
const tip = h.git(sr, 'rev-parse', 'HEAD').slice(0, 7);
let [info, reports] = withData();
const fieldsOf = (value) => [value.name, value.short, value.date, value.notShown, value.oldestNotShown, value.published, value.previousBuild];
h.eq('following, nothing not shown: the fields, in local dates', fieldsOf(info), ['origin/main', tip, LOCAL_DAY, 0, null, null, null]);
h.eq('following, nothing not shown: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. ${NEVER}`]);
h.write(sr, 'file.txt', 'one\n');
h.commit(sr, 'not shown 1', ['file.txt'], '2026-01-11T23:30:00+00:00');
[info, reports] = withData();
h.eq('one commit not shown, with its local date', [info.notShown, info.oldestNotShown], [1, '2026-01-12']);
h.eq('one commit not shown: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. 1 commit of this branch is not in origin/main; it is from 2026-01-12. ${NEVER}`]);
h.write(sr, 'file.txt', 'two\n');
h.commit(sr, 'not shown 2', ['file.txt'], '2026-01-14T12:00:00+00:00');
[info, reports] = withData();
h.eq('two commits not shown: the count and the oldest date', [info.notShown, info.oldestNotShown], [2, '2026-01-12']);
h.eq('two commits not shown: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. 2 commits of this branch are not in origin/main; the oldest is from 2026-01-12. ${NEVER}`]);
// A tag with the same name as the shared value: git resolves a bare
// "origin/main" to the tag (refs/tags comes before refs/remotes), so this
// case fails any command that does not name refs/remotes/origin/main.
h.git(sr, 'tag', 'origin/main', 'HEAD');
[info] = withData();
h.eq('a tag with the same name as the shared value is not followed', [info.short, info.notShown], [tip, 2]);
h.git(sr, 'tag', '-d', 'origin/main');
stateFile('shared.json', JSON.stringify({ generatedAt: '2026-10-01T10:05:00+02:00' }));
stateFile('private.json', JSON.stringify({ generatedAt: '2026-10-15T09:00:00+02:00' }));
[info, reports] = withData();
h.eq('published and previousBuild come from the state files', [info.published, info.previousBuild], ['2026-10-01 10:05', '2026-10-15 09:00']);
h.eq('published: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. 2 commits of this branch are not in origin/main; the oldest is from 2026-01-12. Last published 2026-10-01 10:05.`]);
stateFile('shared.json', 'not json');
stateFile('private.json', '{');
[info] = withData();
h.eq('state files that are not valid JSON give null', [typeof info, info.published, info.previousBuild], ['object', null, null]);
removeState('shared.json', 'private.json');
setKey('sharedRef=origin/gone');
[info] = withData();
h.eq('a missing ref', [info.name, info.missing, info.published, info.previousBuild, 'error' in info], ['origin/gone', true, null, null, false]);
setKey('sharedRef=main');
h.eq('a value of the wrong form', withData()[0].error, 'main is not of the form <remote>/<branch>');
setKey("sharedRef=origin/a'b");
h.eq('a value with a single quote', withData()[0].error, "origin/a'b is not of the form <remote>/<branch>");
h.git(sr, 'update-ref', 'refs/remotes/origin/tree', h.git(sr, 'rev-parse', 'HEAD^{tree}'));
setKey('sharedRef=origin/tree');
h.eq('a ref that is not a commit', withData()[0].error, 'origin/tree is not a commit');
setKey('sharedRef=origin/main');
h.git(sr, 'remote', 'remove', 'origin');
h.eq('a removed remote: the ref is missing', withData()[0].missing, true);
h.check('every private run exits 0', exits.every((code) => code === 0), exits.join(','));
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard/test-04-extract-core.js | grep FAIL`
Expected: FAIL for every section-11 check except `every private run exits 0`: the field is absent (each run gives `no sharedRef key`), and no report line exists. A check that reads a field of `info` may stop the file with a `TypeError`; the file then reports `finish() was never called`, which is the expected failure too.

- [ ] **Step 3: Implement in `skills/dashboard/scripts/dashboard-extract.js`**

Extend the usage comment at the top, after the line `// repo.name, and fails closed. The state folder`… block, by adding these lines before `// Exit status:`:

```js
// The private run with --data-dir also reads config.json and the last
// shared.json and private.json of the state folder, for the shared-ref line
// (spec section 4.5 of dashboard-sources); it writes that line on standard
// error as "dashboard-extract: shared page: <line>" and still exits 0.
```

Add after `const CONFIG_FILE = 'config.json';`:

```js
const MESSAGE_PREFIX = 'dashboard-extract: ';
const SHARED_PAGE_REPORT = 'shared page: ';
const SHARING_ON = 'on';
const STATE_FILES = { shared: 'shared.json', private: 'private.json' };
// The start of a generatedAt time: YYYY-MM-DDTHH:MM.
const TIME_OF_DATA = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/;
const SHARED_REF_TEXT = {
  off: 'Sharing is off. The shared page from an earlier share is still published and is no longer updated.',
  never: 'Never published from this machine.',
};
```

Replace the body of `stop` with:

```js
  process.stderr.write(`${MESSAGE_PREFIX}${message}\n`);
  process.exit(EXIT_STOP);
```

Add this block directly before the line `// ---- the document ----`:

```js
// ---- the shared-ref line of the private page (spec section 4.5) ----

function readJsonOrNull(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    return null;
  }
}

// The generatedAt of the state file <name> in <dir>, cut to
// "YYYY-MM-DD HH:MM"; null when the file is missing, is not valid JSON or
// holds no such time.
function publishTime(dir, name) {
  const doc = readJsonOrNull(path.join(dir, name));
  const at = doc && typeof doc.generatedAt === 'string' && TIME_OF_DATA.test(doc.generatedAt) ? doc.generatedAt : null;
  return at === null ? null : `${at.slice(0, 10)} ${at.slice(11, 16)}`;
}

// A message as one line: sanitized (no repository or home folder), then its
// first non-empty line.
function oneLine(context, message) {
  return sanitize(context, String(message)).split('\n').map((line) => line.trim()).find(Boolean) || '';
}

// The checks of checkSharedName, as tests that return a result instead of
// stopping; the first failing check decides. Every command names the ref by
// its full name refs/remotes/<name>: a bare <remote>/<branch> could resolve
// to a local branch or tag through git's name guessing.
function followedRef(context, name) {
  if (!sharedRefForm(name)) return { error: oneLine(context, `${name} is not of the form <remote>/<branch>`) };
  const ref = remoteRef(name);
  if (!git(['show-ref', '--verify', '--quiet', ref]).ok) return { missing: true };
  if (!git(['rev-parse', '--verify', '--quiet', `${ref}^{commit}`]).ok) return { error: oneLine(context, `${name} is not a commit`) };
  try {
    const range = `${ref}..${HEAD_REF}`;
    const notShown = Number(must(['rev-list', '--count', range]));
    return {
      short: must(['rev-parse', `${ref}^{commit}`]).slice(0, SHORT_LENGTH),
      // --no-walk, as in commitMeta: read only the tip, never its parents.
      date: must(['log', '-1', '--no-walk', '--format=%cd', `--date=${LOCAL_DATE}`, ref]),
      notShown,
      oldestNotShown: notShown ? mustLines(['log', '--reverse', '--format=%cd', `--date=${LOCAL_DATE}`, range])[0] : null,
    };
  } catch (error) {
    return { error: oneLine(context, error.message) };
  }
}

// The sharedRef field of the private data, or null when the page shows no
// line. <dataDir> is the --data-dir value. Nothing here stops the extract.
function sharedRefState(context, dataDir) {
  if (!dataDir || dataDir.includes(DATA_DIR_UNSET)) return null;
  const dir = stateDir(dataDir, context.top);
  const config = readJsonOrNull(path.join(dir, CONFIG_FILE));
  if (!config || typeof config !== 'object') return null;
  const published = publishTime(dir, STATE_FILES.shared);
  const name = config.sharedRef;
  if (config.sharing === SHARING_ON && typeof name === 'string' && name) {
    return Object.assign({ name }, followedRef(context, name), { published, previousBuild: publishTime(dir, STATE_FILES.private) });
  }
  if (config.sharing !== SHARING_ON && config.sharedUrl) return { off: true, published };
  return null;
}

// The "not shown" part of the line. <branch> is null on a detached HEAD.
function notShownText(info, branch) {
  const { notShown, name, oldestNotShown } = info;
  if (branch === null) {
    return notShown === 1
      ? `The checked-out commit has 1 commit that is not in ${name}; it is from ${oldestNotShown}.`
      : `The checked-out commit has ${notShown} commits that are not in ${name}; the oldest is from ${oldestNotShown}.`;
  }
  return notShown === 1
    ? `1 commit of this branch is not in ${name}; it is from ${oldestNotShown}.`
    : `${notShown} commits of this branch are not in ${name}; the oldest is from ${oldestNotShown}.`;
}

// The shared-ref line. template.html builds the same text from the same
// fields (the page cannot load this file); tests/dashboard/test-07-template.js
// compares the two.
function sharedRefLine(info, branch) {
  const parts = [];
  if (info.off) parts.push(SHARED_REF_TEXT.off);
  else if (info.missing) parts.push(`The shared page follows ${info.name}, which no longer exists. The shared page cannot be updated.`);
  else if (info.error !== undefined) parts.push(`The state of the shared ref could not be read: ${info.error}.`);
  else {
    parts.push(`The shared page follows ${info.name}, last commit ${info.date}.`);
    if (info.notShown > 0) parts.push(notShownText(info, branch));
  }
  parts.push(info.published ? `Last published ${info.published}.` : SHARED_REF_TEXT.never);
  return parts.join(' ');
}
```

Replace `function extract(audience, sharedName, top) {` and its `return { … };` with:

```js
function extract(audience, sharedName, top, dataDir) {
  const shared = audience === AUDIENCE.shared;
  const ref = shared ? remoteRef(sharedName) : HEAD_REF;
  // base: the ref against which the shared run decides "merged" (null: no
  // merge exclusion). The private run does not use it.
  const context = {
    shared, ref, remote: shared ? sharedRemote(sharedName) : null, base: shared ? defaultUpstream() : null, top, home: os.homedir(), now: Date.now(), committed: new Map(),
    source: shared ? refSource(ref) : workingTreeSource(top),
  };
  return {
    schemaVersion: SCHEMA_VERSION,
    audience,
    generatedAt: parse.localIso(new Date()),
    repo: { name: shared ? sharedRepoName(sharedName, context.remote) : path.basename(top) },
    commit: commitMeta(context),
    // Only the private data has this key; dashboard-render.js --verify
    // refuses shared data that holds it.
    ...(shared ? {} : { sharedRef: sharedRefState(context, dataDir) }),
    sections: buildSections(context),
  };
}
```

Replace `requireSharedRefForm` with:

```js
// true when <name> has the form <remote>/<branch> (SHARED_REF_NAME, no "..").
function sharedRefForm(name) {
  return SHARED_REF_NAME.test(name) && !name.includes('..');
}

function requireSharedRefForm(name, label) {
  if (!sharedRefForm(name)) stop(`${label} is not of the form <remote>/<branch>`);
}
```

In `main()`, replace the last line `writeDocument(extract(audience, args['--ref'], top), out);` with:

```js
  const doc = extract(audience, args['--ref'], top, args['--data-dir']);
  writeDocument(doc, out);
  if (doc.sharedRef) process.stderr.write(`${MESSAGE_PREFIX}${SHARED_PAGE_REPORT}${sharedRefLine(doc.sharedRef, doc.commit.branch)}\n`);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `node tests/dashboard/test-04-extract-core.js | tail -1; node tests/dashboard/test-06-privacy.js | tail -1`
Expected: two lines `<n> passed, 0 failed`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [ ] **Step 5: Commit**

```bash
git add skills/dashboard/scripts/dashboard-extract.js tests/dashboard/test-04-extract-core.js
git commit -m "feat(dashboard): the private extract computes the shared-ref state and reports it" --trailer "Session: dashboard-sources" --trailer "Stage: task 7/12"
```

---

### Task 8: The private page shows the shared-ref line with its warning rules

**Files:**
- Modify: `skills/dashboard/template.html`
- Modify: `tests/dashboard/fake-page.js`
- Test: `tests/dashboard/test-07-template.js`

**Security flag:** `none`

**Does NOT cover:** the computation of the field (Task 7). A `sharedRef` value of an unknown shape (none of `off`, `missing`, `error`, or the following fields) is rendered as following with empty fields; the extractor never writes such a value. The line updates only at `refresh`: `share` itself does not rebuild the private page.

**Contract:**
- `sharedRefLine(info, branch)`, `notShownText(info, branch)`, `sharedRefWarns(info, generatedAt)`, `renderSharedRef(data)` and the static element `<p id="shared-ref" hidden></p>`
  - Invariants: Global Constraints 12 and 13; the page line equals the extractor's report line for the same data in every case (branch, detached HEAD, missing, error, sharing off); two calls of `renderPage` leave exactly one shared-ref element (the static one) with one line; days are counted with `calendarDays` (Task 5).
  - Verification: the shared-ref checks and the same-wording checks of `node tests/dashboard/test-07-template.js`.
  - Interface not externally pinned.
- `tests/dashboard/fake-page.js`: `shared-ref` added to `STATIC_IDS` and `HIDDEN_IDS`
  - Invariant: the fake document starts the element hidden, as the template does.
  - Verification: the hidden checks of test-07.

- [ ] **Step 1: Edit `tests/dashboard/fake-page.js`**

Replace the two constants with:

```js
const STATIC_IDS = ['page-title', 'as-of', 'shared-ref', 'private-banner', 'viewer-warning', 'load-error', 'tab-waits', 'tab-history', 'panel-waits', 'panel-history'];
// The static elements that the template marks "hidden".
const HIDDEN_IDS = ['shared-ref', 'private-banner', 'viewer-warning', 'load-error', 'panel-history'];
```

- [ ] **Step 2: Write the failing tests in `tests/dashboard/test-07-template.js`**

After the Source block of Task 6, add:

```js
// The shared-ref line (spec section 4.5): texts, classes, the hidden state.
const WARN = 'shared-ref banner warn';
const INFO = 'shared-ref muted';
const REF_BUILT = '2026-10-19T16:43:00+02:00';
const FOLLOW = { name: 'origin/main', short: '1234567', date: '2026-10-01', notShown: 0, oldestNotShown: null, published: '2026-10-19 16:40', previousBuild: '2026-10-19 16:30' };
const FOLLOWS = 'The shared page follows origin/main, last commit 2026-10-01.';
const LAST = 'Last published 2026-10-19 16:40.';
const NEVER = 'Never published from this machine.';
const follow = (fields) => Object.assign({}, FOLLOW, fields);
// The shared-ref element after one render: [text, class, hidden].
function refLine(info, branch, generatedAt, audience) {
  const pageDoc = fakeDocument(audience || 'private');
  const data = sample(audience || 'private', branch === undefined ? 'main' : branch);
  data.generatedAt = generatedAt || REF_BUILT;
  if (info !== undefined) data.sharedRef = info;
  load(pageDoc).DashboardApp.renderPage({ data, canEdit: false, proposals: new Map(), store: null });
  const node = pageDoc.getElementById('shared-ref');
  return [node.textContent, node.getAttribute('class'), node.hidden];
}
h.eq('following, nothing not shown', refLine(FOLLOW), [`${FOLLOWS} ${LAST}`, INFO, false]);
h.eq('2 commits not shown, the oldest 14 days old: information', refLine(follow({ notShown: 2, oldestNotShown: '2026-10-05' })), [`${FOLLOWS} 2 commits of this branch are not in origin/main; the oldest is from 2026-10-05. ${LAST}`, INFO, false]);
h.eq('the oldest not shown 15 days old: warning', refLine(follow({ notShown: 2, oldestNotShown: '2026-10-04' }))[1], WARN);
h.eq('1 commit not shown', refLine(follow({ notShown: 1, oldestNotShown: '2026-10-05' }))[0], `${FOLLOWS} 1 commit of this branch is not in origin/main; it is from 2026-10-05. ${LAST}`);
h.eq('detached HEAD, 2 not shown', refLine(follow({ notShown: 2, oldestNotShown: '2026-10-05' }), null)[0], `${FOLLOWS} The checked-out commit has 2 commits that are not in origin/main; the oldest is from 2026-10-05. ${LAST}`);
h.eq('detached HEAD, 1 not shown', refLine(follow({ notShown: 1, oldestNotShown: '2026-10-05' }), null)[0], `${FOLLOWS} The checked-out commit has 1 commit that is not in origin/main; it is from 2026-10-05. ${LAST}`);
h.eq('a ref tip 30 days old with nothing not shown: information', refLine(follow({ date: '2026-09-19' }))[1], INFO);
h.eq('never published: warning', refLine(follow({ published: null })), [`${FOLLOWS} ${NEVER}`, WARN, false]);
h.eq('a gap of 14 days to the previous private publish: information', refLine(follow({ published: '2026-10-01 10:00', previousBuild: '2026-10-15 10:00' }))[1], INFO);
h.eq('a gap of 15 days: warning', refLine(follow({ published: '2026-10-01 10:00', previousBuild: '2026-10-16 10:00' }))[1], WARN);
h.eq('both times 30 days old and equal: information', refLine(follow({ published: '2026-09-19 10:00', previousBuild: '2026-09-19 10:00' }))[1], INFO);
h.eq('a missing ref: warning', refLine({ name: 'origin/main', missing: true, published: FOLLOW.published, previousBuild: FOLLOW.previousBuild }), [`The shared page follows origin/main, which no longer exists. The shared page cannot be updated. ${LAST}`, WARN, false]);
h.eq('an error: warning', refLine({ name: 'main', error: 'main is not of the form <remote>/<branch>', published: FOLLOW.published, previousBuild: FOLLOW.previousBuild }), [`The state of the shared ref could not be read: main is not of the form <remote>/<branch>. ${LAST}`, WARN, false]);
h.eq('sharing off: information', refLine({ off: true, published: null }), [`Sharing is off. The shared page from an earlier share is still published and is no longer updated. ${NEVER}`, INFO, false]);
const hiddenOf = (line) => [line[0], line[2]];
h.eq('no sharedRef key: hidden and empty', hiddenOf(refLine(undefined)), ['', true]);
h.eq('sharedRef null: hidden and empty', hiddenOf(refLine(null)), ['', true]);
h.eq('the shared page: hidden and empty', hiddenOf(refLine(undefined, 'origin/main', REF_BUILT, 'shared')), ['', true]);
const twice = fakeDocument('private');
const twiceApp = load(twice).DashboardApp;
const twiceView = { data: Object.assign(sample('private', 'main'), { sharedRef: FOLLOW }), canEdit: false, proposals: new Map(), store: null };
twiceApp.renderPage(twiceView);
twiceApp.renderPage(twiceView);
h.eq('two renders: no created shared-ref element, one line in the static one', [twice.created.filter((node) => node.getAttribute('id') === 'shared-ref').length, twice.getElementById('shared-ref').textContent], [0, `${FOLLOWS} ${LAST}`]);
h.check('the template places id="shared-ref" directly after id="as-of"', /<p id="as-of" class="muted"><\/p>\s*<p id="shared-ref" hidden><\/p>/.test(TEMPLATE));
// Days are calendar days, also across a daylight-saving change. Europe/Berlin
// moves its clocks back on 2026-10-25: a count of local midnights gives
// 14.04 days from 2026-10-12 to 2026-10-26, which would wrongly be a warning,
// so this case fails a count that divides a difference of local times. (The
// spring change of 2026-03-29 gives 13.96 and 14.96 days, which round the
// same way as the calendar count, so it cannot catch that defect.)
const savedZone = process.env.TZ;
process.env.TZ = 'Europe/Berlin';
const DST_BUILT = '2026-10-26T12:00:00+01:00';
h.eq('across a daylight-saving change: 14 days is information, 15 days a warning', [refLine(follow({ notShown: 1, oldestNotShown: '2026-10-12' }), 'main', DST_BUILT)[1], refLine(follow({ notShown: 1, oldestNotShown: '2026-10-11' }), 'main', DST_BUILT)[1]], [INFO, WARN]);
if (savedZone === undefined) delete process.env.TZ; else process.env.TZ = savedZone;

// The same wording (spec section 6): the extractor's report line and the page
// line built from the extractor's data, for each case of section 4.5.
const EXTRACT = h.script('dashboard-extract.js');
const REPORT = 'dashboard-extract: shared page: ';
const wording = h.repo('template-shared-ref');
h.addRemote(wording, 'template-shared-ref-remote');
h.write(wording, 'file.txt', 'base\n');
h.commit(wording, 'base', ['file.txt']);
h.git(wording, 'push', '-q', '-u', 'origin', 'main');
h.write(wording, 'file.txt', 'one\n');
h.commit(wording, 'one', ['file.txt']);
h.write(wording, 'file.txt', 'two\n');
h.commit(wording, 'two', ['file.txt']);
const wordingData = path.join(h.ROOT, 'template-shared-ref-data');
const wordingSet = (assignment) => h.node(wording, [EXTRACT, '--data-dir', wordingData, '--config-set', assignment]);
function sameWording(label) {
  const result = h.node(wording, [EXTRACT, '--audience', 'private', '--data-dir', wordingData]);
  const said = result.err.split('\n').filter((line) => line.startsWith(REPORT)).map((line) => line.slice(REPORT.length));
  const pageDoc = fakeDocument('private');
  load(pageDoc).DashboardApp.renderPage({ data: JSON.parse(result.out), canEdit: false, proposals: new Map(), store: null });
  h.eq(`same wording, ${label}`, [said.length, pageDoc.getElementById('shared-ref').textContent], [1, said[0]]);
}
wordingSet('sharing=on');
wordingSet('sharedRef=origin/main');
sameWording('checks passing on a branch');
h.git(wording, 'checkout', '-q', '--detach', 'HEAD');
sameWording('checks passing on a detached HEAD');
h.git(wording, 'checkout', '-q', 'main');
wordingSet('sharedRef=origin/gone');
sameWording('a missing ref');
wordingSet('sharedRef=main');
sameWording('an error');
wordingSet('sharing=off');
wordingSet('sharedUrl=https://claude.ai/code/artifact/shared');
sameWording('sharing off');
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `node tests/dashboard/test-07-template.js | grep FAIL`
Expected: FAIL for every shared-ref check except those that expect a hidden, empty element (before the change the element stays empty and hidden and has no class, so the checks of a class fail too, also those that expect the information style), for `the template places id="shared-ref" …`, and for the five `same wording` checks (got `''` against the extractor's line).

- [ ] **Step 4: Implement in `skills/dashboard/template.html`**

In the header, replace `<p id="as-of" class="muted"></p>` with:

```html
    <p id="as-of" class="muted"></p>
    <p id="shared-ref" hidden></p>
```

Add after the `FOLD_REASON` / `CURRENT_MARK` constants of Task 5:

```js
  const SHARED_REF_ID = 'shared-ref';
  // A day count above this many days makes the shared-ref line a warning.
  const SHARED_STALE_DAYS = 14;
  const SHARED_REF_CLASS = { warn: 'shared-ref banner warn', info: 'shared-ref muted' };
  // skills/dashboard/scripts/dashboard-extract.js holds the only other copy
  // of these texts (the page cannot load shared code);
  // tests/dashboard/test-07-template.js checks that both give one line.
  const SHARED_REF_TEXT = {
    off: 'Sharing is off. The shared page from an earlier share is still published and is no longer updated.',
    never: 'Never published from this machine.',
  };
```

Add directly before `function renderPage(ctx) {`:

```js
  // The "not shown" part of the shared-ref line. <branch> is null on a
  // detached HEAD.
  function notShownText(info, branch) {
    const notShown = info.notShown;
    const name = text(info.name);
    const oldest = text(info.oldestNotShown);
    if (branch === null) {
      return notShown === 1
        ? `The checked-out commit has 1 commit that is not in ${name}; it is from ${oldest}.`
        : `The checked-out commit has ${notShown} commits that are not in ${name}; the oldest is from ${oldest}.`;
    }
    return notShown === 1
      ? `1 commit of this branch is not in ${name}; it is from ${oldest}.`
      : `${notShown} commits of this branch are not in ${name}; the oldest is from ${oldest}.`;
  }

  // The shared-ref line (spec section 4.5, "Page").
  function sharedRefLine(info, branch) {
    const parts = [];
    if (info.off) parts.push(SHARED_REF_TEXT.off);
    else if (info.missing) parts.push(`The shared page follows ${text(info.name)}, which no longer exists. The shared page cannot be updated.`);
    else if (info.error !== undefined) parts.push(`The state of the shared ref could not be read: ${text(info.error)}.`);
    else {
      parts.push(`The shared page follows ${text(info.name)}, last commit ${text(info.date)}.`);
      if (info.notShown > 0) parts.push(notShownText(info, branch));
    }
    parts.push(info.published ? `Last published ${text(info.published)}.` : SHARED_REF_TEXT.never);
    return parts.join(' ');
  }

  // true when the line is a warning: old work not shown, a shared publish
  // that keeps failing, a missing ref or an error (spec section 4.5,
  // "Style"). Sharing off is always an information line.
  function sharedRefWarns(info, generatedAt) {
    if (info.off) return false;
    if (info.missing || info.error !== undefined) return true;
    const waiting = calendarDays(info.oldestNotShown, generatedAt);
    if (waiting !== null && waiting > SHARED_STALE_DAYS) return true;
    if (!info.published) return true;
    const gap = calendarDays(info.published, info.previousBuild);
    return gap !== null && gap > SHARED_STALE_DAYS;
  }

  // Sets the static shared-ref element: renderPage runs several times, so it
  // never creates the element, only sets its text, class and hidden state.
  function renderSharedRef(data) {
    const node = document.getElementById(SHARED_REF_ID);
    const info = data.sharedRef;
    const shown = info !== null && info !== undefined;
    node.textContent = shown ? sharedRefLine(info, data.commit.branch) : '';
    node.setAttribute('class', shown && sharedRefWarns(info, data.generatedAt) ? SHARED_REF_CLASS.warn : SHARED_REF_CLASS.info);
    node.hidden = !shown;
  }
```

In `renderPage`, after `document.getElementById('as-of').textContent = asOfLine(data);` add:

```js
    renderSharedRef(data);
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `node tests/dashboard/test-07-template.js | tail -1; node tests/dashboard/test-08-template-edits.js | tail -1`
Expected: two lines `<n> passed, 0 failed`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [ ] **Step 6: Commit**

```bash
git add skills/dashboard/template.html tests/dashboard/fake-page.js tests/dashboard/test-07-template.js
git commit -m "feat(dashboard): the shared-ref line on the private page" --trailer "Session: dashboard-sources" --trailer "Stage: task 8/12"
```

---

### Task 9: `--verify` refuses `sharedRef` in shared data; the shared output never holds `sharedRef` or `current`

**Files:**
- Modify: `skills/dashboard/scripts/dashboard-render.js`
- Test: `tests/dashboard/test-09-render.js`
- Test: `tests/dashboard/test-06-privacy.js`

**Security flag:** `security` (a guard of the shared page: the check that keeps private-only data off a page that can be public)

**Does NOT cover:** a general check of section-level or other top-level fields of shared data (S-41, release 2). The private audience accepts `sharedRef`.

**Contract:**
- `verify(dir, audience)` in `dashboard-render.js`
  - Invariants: for the shared audience, data whose top level has the key `sharedRef` (any value, `null` too) gets the reason `the shared data contains sharedRef` in the `refused: <reason>; <reason>` line and exit 1; for the private audience the key is accepted; every existing reason stays.
  - Verification: `node tests/dashboard/test-09-render.js`.
- The shared extract output (behaviour from Tasks 4 and 7, checked here)
  - Invariants: no top-level `sharedRef` key and no `current` field on any git item, also with `--data-dir` naming a configuration whose sharing is on and with an unmerged branch checked out; no `shared page:` line on standard error.
  - Verification: `node tests/dashboard/test-06-privacy.js`.
- `tests/dashboard/test-09-render.js` session fixture: moved from an `Open:` line to a `Goal:` line (a kept kind, `session`).
  - Invariant: the edit only keeps the fixture in a form the extractor still parses after Task 2. The check `(1) no marker in the shared page files` tests that the shared extract reads only the pushed ref: `session-log.md` is written after the push and never committed, so its marker reaches no data with either line, and no private data is built in that case.
  - Verification: `node tests/dashboard/test-09-render.js`.

- [ ] **Step 1: Write the failing tests**

In `tests/dashboard/test-09-render.js`, replace `h.write(d, 'session-log.md', `## 2026-01-01 [saved]\nOpen: ${MARKER}\n`);` with:

```js
h.write(d, 'session-log.md', `## 2026-01-01 [saved]\nGoal: ${MARKER}\n`);
```

Before `h.finish();` add:

```js
// --verify refuses shared data that holds the private-only key sharedRef,
// whatever its value; the private audience accepts it.
const REFUSED_KEY = 'refused: the shared data contains sharedRef';
for (const [label, value] of [['null', null], ['sharing off', { off: true, published: null }]]) {
  const dir = scratch(`shared-ref-${label.replace(' ', '-')}`);
  render(h.ROOT, ['--audience', 'shared', '--in', writeJson('shared4.json', sharedDoc), '--out', dir]);
  const dataFile = path.join(dir, 'dashboard-data.json');
  fs.writeFileSync(dataFile, JSON.stringify(Object.assign(JSON.parse(read(dataFile)), { sharedRef: value })));
  const refused = render(h.ROOT, ['--verify', dir, '--audience', 'shared']);
  h.eq(`verify refuses shared data with sharedRef ${label}`, [refused.code, refused.out.trim()], [1, REFUSED_KEY]);
}
const privateWithRef = scratch('private-with-ref');
render(h.ROOT, ['--audience', 'private', '--in', writeJson('private2.json', Object.assign({}, privateDoc, { sharedRef: null })), '--out', privateWithRef]);
h.eq('verify accepts private data with sharedRef', render(h.ROOT, ['--verify', privateWithRef, '--audience', 'private']).out.trim(), 'verified private');
```

In `tests/dashboard/test-06-privacy.js`, after `h.check('(10) no section note holds a machine path', …);` add:

```js
// The shared run never computes the shared-ref line and never marks the
// current branch, also with a configuration whose sharing is on and with an
// unmerged branch checked out (spec sections 4.5 and 4.6).
const privacyData = path.join(h.ROOT, 'privacy-data');
run(d, ['--data-dir', privacyData, '--config-set', 'sharing=on']);
run(d, ['--data-dir', privacyData, '--config-set', 'sharedRef=origin/main']);
h.git(d, 'checkout', '-q', 'feature/run');
const configured = run(d, ['--data-dir', privacyData, '--audience', 'shared', '--ref', 'origin/main']);
const configuredDoc = configured.code === 0 ? JSON.parse(configured.out) : { sections: { git: { items: [] } } };
h.eq('the shared output: exit 0, no sharedRef key, no current field, no shared-page line', [configured.code, 'sharedRef' in configuredDoc, configuredDoc.sections.git.items.some((i) => 'current' in i), configured.err.includes('shared page:')], [0, false, false, false]);
h.git(d, 'checkout', '-q', 'main');
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `node tests/dashboard/test-09-render.js | grep FAIL; node tests/dashboard/test-06-privacy.js | grep FAIL`
Expected: test-09 FAIL for the two `verify refuses shared data with sharedRef …` checks (got `[0, "verified shared"]`); test-06 prints no FAIL line (the shared run already has neither field after Tasks 4 and 7; this check guards against a regression).

- [ ] **Step 3: Implement in `skills/dashboard/scripts/dashboard-render.js`**

Add after `const NO_SECTION = { status: 'absent', items: [] };`:

```js
// The top-level key that only the private data may hold (the shared-ref
// line of the private page).
const PRIVATE_ONLY_KEY = 'sharedRef';
```

In `verify`, inside the block `if (doc && audience === AUDIENCE.shared) {`, after the line `if (untracked) reasons.push(`${untracked} items are not tracked`);` add:

```js
    if (Object.prototype.hasOwnProperty.call(doc, PRIVATE_ONLY_KEY)) reasons.push(`the shared data contains ${PRIVATE_ONLY_KEY}`);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `node tests/dashboard/test-09-render.js | tail -1; node tests/dashboard/test-06-privacy.js | tail -1`
Expected: two lines `<n> passed, 0 failed`.

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [ ] **Step 5: Commit**

```bash
git add skills/dashboard/scripts/dashboard-render.js tests/dashboard/test-09-render.js tests/dashboard/test-06-privacy.js
git commit -m "feat(dashboard): --verify refuses sharedRef in shared data" --trailer "Session: dashboard-sources" --trailer "Stage: task 9/12"
```

---

### Task 10: `SKILL.md`: description, the `shared page:` line in the `refresh` report, `share` keeps `shared.json`

**Files:**
- Modify: `skills/dashboard/SKILL.md`
- Test: `tests/dashboard/test-12-skill-text.js`

**Security flag:** `none`

**Does NOT cover:** SKILL.md `sync` (no change: step 3 already lets the owner reject an `invalid` proposal). `share off` (it stores `sharing=off` only; the private page shows "Sharing is off" from the next `refresh` on). SKILL.md `local` (no change: its private extract also computes `sharedRef`, so the local file shows the shared-ref line, and the extractor prints the `dashboard-extract: shared page:` line on standard error with exit 0; that line is information, not an error, and `local` does not repeat it, because its report is only the file path).

**Contract:**
- SKILL.md wording (description line 4, `refresh` steps 4 and 8, `share` step 5)
  - Must convey: the description no longer lists "open items of recent sessions"; the model repeats the extractor's `dashboard-extract: shared page:` line, without the `dashboard-extract: ` prefix, in the `refresh` report; after a successful shared publish, `share` copies `<scratchpad>/dashboard/shared.json` to `<state>/shared.json`, as `refresh` step 7 does.
  - Invariants: every script command line still carries `--data-dir "${CLAUDE_PLUGIN_DATA}"`; every existing pinned phrase of test-12 stays.
  - Verification: `node tests/dashboard/test-12-skill-text.js`.
  - Sentence wording is free, except for three strings that the new checks of Step 1 read word for word: the `refresh` text holds `` repeat that line in the report without its `dashboard-extract: ` prefix ``; the `share` section holds the line `cp "<scratchpad>/dashboard/shared.json" "<state>/shared.json"`; the description does not hold `open items of recent sessions`.

- [ ] **Step 1: Write the failing tests in `tests/dashboard/test-12-skill-text.js`**

Before `h.finish();` add:

```js
// The shared-ref line of the private extract is repeated in the refresh
// report, and share keeps the data of a shared publish in the state folder
// (spec dashboard-sources, sections 4.5 and 4.7).
const SHARED_LINE = 'shared-ref line and the shared publish';
flatHas(SHARED_LINE, 'repeat that line in the report without its `dashboard-extract: ` prefix');
const SHARE_SECTION = FLAT.slice(FLAT.indexOf('## `share`'), FLAT.indexOf('## `share off`'));
h.check(`${SHARED_LINE}: share copies shared.json to the state folder`, SHARE_SECTION.includes('cp "<scratchpad>/dashboard/shared.json" "<state>/shared.json"'));
h.check(`${SHARED_LINE}: the description names no session open items`, !front.includes('open items of recent sessions'));
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard/test-12-skill-text.js | grep FAIL`
Expected: FAIL for the three new checks.

- [ ] **Step 3: Implement in `skills/dashboard/SKILL.md`**

In the description (line 4), replace `unfinished orchestration runs, branches, work logs, open items of recent sessions, releases, commits` with `unfinished orchestration runs, branches, work logs, releases, commits`.

In `refresh` step 4, replace the paragraph after the code block with:

```markdown
   Exit code 2 of the extractor (not a git repository, no commit yet) stops
   the refresh with its message; nothing is published. When a shared page is
   configured (sharing on, or a shared page left from an earlier share), the
   extractor also prints one line on standard error that starts with
   `dashboard-extract: shared page:`; keep it for the report of step 8.
```

Replace `refresh` step 8 with:

```markdown
8. Report in a few lines: the output of `--diff`, the size of
   `dashboard-data.json` from the renderer's `written` line, and the URL of
   each page that was published. When step 4 printed a line that starts with
   `dashboard-extract: shared page:`, repeat that line in the report without
   its `dashboard-extract: ` prefix. Do not describe the content of the page.
```

Replace `share` step 5 with:

````markdown
5. Run step 6 of `refresh` (extract, render and publish the shared audience;
   store `sharedUrl` at once when the page is new). Only when it published
   the shared page, keep its data as `refresh` step 7 does, so that the
   private page can say when the shared page was last published:

   ```bash
   cp "<scratchpad>/dashboard/shared.json" "<state>/shared.json"
   ```
````

- [ ] **Step 4: Run the test to verify it passes**

Run: `node tests/dashboard/test-12-skill-text.js | tail -1`
Expected: `<n> passed, 0 failed`

Run: `bash tests/dashboard/run-tests.sh | tail -1`
Expected: `dashboard suite: every test file passed`

- [ ] **Step 5: Commit**

```bash
git add skills/dashboard/SKILL.md tests/dashboard/test-12-skill-text.js
git commit -m "docs(dashboard): report the shared-page line; share keeps shared.json" --trailer "Session: dashboard-sources" --trailer "Stage: task 10/12"
```

---

### Task 11: User documents and the old dashboard spec

**Files:**
- Modify: `docs/guide/README.md`
- Modify: `README.md`
- Modify: `docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md`
- Check (no change expected): `hooks/skill-rules.json`

**Security flag:** `none`

**Does NOT cover:** `RELEASE-NOTES.md` and the version lines (Task 12). It does not rewrite the amended sections of the old spec (Global Constraint 18).

**Contract:**
- `docs/guide/README.md`, dashboard passage
  - Must convey: no session open items and no "Mark resolved" control; the "Source:" line of each card; the commit date and the changed-file count in the "as of" line; the shared-ref line with its texts, its two warning rules (old work not shown for more than 14 days, shared publish failing) and the fact that it updates only at `refresh`; the "sharing off" line; the folded old branches and `[current]` of the Git card.
  - Verification: `grep -c -E "Mark resolved|open items of the recent" docs/guide/README.md` prints `0`; `for t in 'Source:' 'shared-ref line' 'Sharing is off' 'older branches' '\[current\]' 'tracked files changed' '14 days' 'next .refresh.'; do grep -q -E "$t" docs/guide/README.md || echo "MISSING $t"; done` prints nothing (each of the eight terms is checked on its own).
- `README.md` lines 39 and 370
  - Must convey: "open items" in the dashboard bullets means work-log open items.
  - Verification: `grep -n "dashboard" README.md | grep -c "work logs and their open items"` prints `2`.
- `docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md`
  - Invariant: exactly five new lines that start with `Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: `, one after the `### 5.1 JSON shape` heading, one after `### 5.2 Sections`, one directly after the section 7 kind table, one after `## 8. \`sync\``, one after `## 11. Testing and rollout`; no other line of the file changes.
  - Verification: `grep -c "^Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: " docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md` prints `5`; `git diff --numstat -- docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md` shows `10	0` (five lines plus five blank lines added, none removed).
- `hooks/skill-rules.json`: none — the dashboard entry's keywords (`project dashboard`, `status dashboard`, `dashboard page`) and its three intent patterns name no session open item (checked on 2026-10-20), so the file is not changed.

- [ ] **Step 1: Check `hooks/skill-rules.json`**

Run: `node -e "const r=require('./hooks/skill-rules.json').rules.find((x)=>x.skill==='dashboard'); const text=JSON.stringify([r.keywords, r.intentPatterns]); console.log(r.keywords.length > 0, /open item|session|resolve/i.test(text))"`
Expected: `true false` (the entry exists and has keywords; no keyword or pattern fits only session open items; no edit). A failure of the command prints a stack trace, never `true false`.

- [ ] **Step 2: Edit `docs/guide/README.md`**

Replace the first paragraph of "### The project dashboard — a status page on claude.ai" (from `Since v7.56.0, the \`dashboard\` skill` through `is a view of them, as of its last refresh.`) with:

```markdown
Since v7.56.0, the `dashboard` skill shows the status of a repository on a
claude.ai **Artifact page**: a web page that a Claude Code session publishes to
claude.ai with its Artifact tool, private to you at first. The page answers two
questions in two tabs. **Waits for me** lists the unfinished orchestration runs
(a stopped run is marked "stopped — waits for you"), the local branches that
are not merged, the active work logs with their open parts and open items, and
the current goal of `state.md`. **History** lists the releases, the
orchestration topic folders, the closed work logs, the recent commits, the
goals of the recent sessions (newest first, each with the date and time of its
`session-log.md` entry) and the known issues. The repository files stay the
only source of truth: the page is a view of them, as of its last refresh.
Since v7.73.0 the page no longer lists the open items of `session-log.md`:
the skill that writes them never marks them as closed (only the dashboard's
own `sync` did), so the page showed items that were already fixed.
```

After the "**Two pages.**" paragraph (it ends with `make only the shared page's link public.`, which spans two lines in the file; the insertion point is directly before the line that starts `**Edits.**`), insert:

```markdown
**What the page says about itself** (since v7.73.0):

- Every card starts with a **Source:** line. It names the file, the folder or
  the git command that the card reads, and the rule that selects its items.
  On the shared page, the three cards that read another place (the
  unfinished runs, the Git card and the recent commits) name that place.
- The **"as of" line** names the commit that the page shows and the date of
  that commit, for example
  `as of commit 4aebf3a (2026-10-19) on branch main · built 2026-10-19 16:43`.
  On the private page it adds, for example,
  ` · 3 tracked files changed, not committed` when files that git tracks have
  changes that are not committed. Files that git does not track are not
  counted.
- When sharing is on, the private page shows a **shared-ref line** under the
  "as of" line. It names the shared branch and the date of its last commit,
  how many commits of your checked-out branch are not in the shared branch
  and the date of the oldest one, and when the shared page was last
  published from this computer ("Never published from this machine." before
  the first publish). The line becomes a warning in two cases: work has been
  missing from the shared page for more than 14 days (the oldest commit that
  is not in the shared branch is more than 14 days old), or the shared page
  is not republished (it was never published, or its last publish lies more
  than 14 days before the last publish of the private page). It is also a
  warning when the shared branch no longer exists or its state cannot be
  read. The line is computed at each `refresh`: after `share`,
  `share --ref` or `share off` it shows the new state from the next `refresh`
  on.
- After `share off`, the line says: "Sharing is off. The shared page from an
  earlier share is still published and is no longer updated."
- The **Git card** lists the branches newest first and marks the checked-out
  branch with `[current]`. Branches with no commit in the last 90 days are
  folded under one line, for example "4 older branches (no commit in the last
  90 days)"; the checked-out branch is never folded.
```

Replace the start of the "**Edits.**" paragraph, `**Edits.** On the private page you can mark an open item of \`session-log.md\` as resolved, or change the status or the note of a part of a work log.` (it spans two lines in the file), with the block below. Replace only the text up to and including `work log.`: the words ` The page` that follow it on the same line of the file stay, so the next sentence ("The page stores each edit as a proposal.") keeps its subject.

```markdown
**Edits.** On the private page you can change the status or the note of a
part of a work log.
```

and add this sentence at the end of the same paragraph (after `resume an orchestrated run.`):

```markdown
A proposal from a page older than v7.73.0 that marked a session open item as
resolved is reported by `sync` as invalid; reject it there.
```

- [ ] **Step 3: Edit `README.md`**

On line 39, replace `(unfinished runs, branches, work logs, open items, releases)` with `(unfinished runs, branches, work logs and their open items, releases)`.

On line 370, replace `(unfinished runs, branches, work logs, open items, releases, commits)` with `(unfinished runs, branches, work logs and their open items, releases, commits)`.

- [ ] **Step 4: Add the five amendment lines to the old spec**

In `docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md`, insert each line below followed by one blank line:

After the heading `### 5.1 JSON shape` and its blank line:

```markdown
Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: the section `sessionOpenItems` is removed; `commit` gains `date`; the private data gains the top-level field `sharedRef`; a branch item of the private run can carry `current: true`.
```

After the heading `### 5.2 Sections` and its blank line:

```markdown
Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: `sessionOpenItems` is removed; `sessions` lists its items newest first; branch dates and commit dates are local dates (`short-local`).
```

After the last row of the section 7 kind table (the `| \`set-part\` | …` row) and its blank line:

```markdown
Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: the kind `resolve-open-item` and its "Mark resolved" control are removed; `set-part` is the only kind.
```

After the heading `## 8. \`sync\`` and its blank line:

```markdown
Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: `sync` knows only `set-part`; a `resolve-open-item` proposal gets the verdict `invalid` with the reason `resolve-open-item was removed in 7.73.0; reject this proposal`.
```

After the heading `## 11. Testing and rollout` and its blank line:

```markdown
Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: the session-log open-item cases and the `resolve-open-item` sync cases are removed; the sync cases run on `set-part`.
```

Run: `F=docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md; for h in '^### 5\.1 JSON shape' '^### 5\.2 Sections' '^\| .set-part. \|' '^## 8\. .sync.' '^## 11\. Testing and rollout'; do grep -A2 -E "$h" "$F" | tail -1 | grep -q '^Amended in 7.73.0 by ' || echo "MISPLACED $h"; done`
Expected: no output (each amendment line stands two lines below its own anchor: the anchor, one blank line, the amendment line).

- [ ] **Step 5: Verify**

Run: `grep -c -E "Mark resolved|open items of the recent" docs/guide/README.md; for t in 'Source:' 'shared-ref line' 'Sharing is off' 'older branches' '\[current\]' 'tracked files changed' '14 days' 'next .refresh.'; do grep -q -E "$t" docs/guide/README.md || echo "MISSING $t"; done; grep -n "dashboard" README.md | grep -c "work logs and their open items"; grep -c "^Amended in 7.73.0 by docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md: " docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md; git diff --numstat -- docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md`
Expected: `0`; no `MISSING` line; `2`; `5`; `10	0	docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md`.

- [ ] **Step 6: Commit**

```bash
git add docs/guide/README.md README.md docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md
git commit -m "docs(dashboard): guide, README and spec amendments for 7.73.0" --trailer "Session: dashboard-sources" --trailer "Stage: task 11/12"
```

---

### Task 12: Release 7.73.0

**Files:**
- Modify: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md`

**Security flag:** `none`

**Does NOT cover:** reinstalling the plugin or a behavioural run (the orchestrator's later phases). Codex files (Codex is not supported; no Codex-facing change).

**Contract:**
- Version lines (Global Constraint 1)
  - Invariants: `7.73.0` in `VERSION`, `.claude-plugin/plugin.json` `version`, `.claude-plugin/marketplace.json` plugin `version`, `plugin.universal.yaml` meta `version`, the README badge and both `v6.7.0–v7.73.0` ranges; no `7.72.2` left in those places.
  - Verification: `grep -c "7\.72\.2" VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md` prints `0` for each file; `grep -c "7\.73\.0" README.md` prints `3`.
- `RELEASE-NOTES.md` entry `## v7.73.0 — …`
  - Must convey: the three-line summary (Problem / Change / Effect, near 100 words, 120 at most, each statement backed by the entry's prose); the removed open items and control; the Source lines; the "as of" line; the shared-ref line and its two warning rules; the Git card; the expected first-`refresh` `--diff` lines `sessionOpenItems: 0 added, <n> removed` and `sessionOpenItems: status ok → absent`; that old `resolve-open-item` proposals are rejected at the next `sync`, and that rejecting one left in `applying` does not undo a `[resolved` mark already written into `session-log.md`; the accepted limits (unfinished-run dates in the committer's time zone; squash or rebase merges).
  - Invariant: the entry is placed directly above `## v7.72.2`; the summary's three labels are `**Problem.**`, `**Change.**`, `**Effect.**` in this order.
  - Verification: `awk '/^## v7.73.0/{f=1;next} /^## v7.72.2/{f=0} f' RELEASE-NOTES.md | grep -c -E "^\*\*(Problem|Change|Effect)\.\*\*"` prints `3`; `awk '/^## v7.73.0/{f=1;next} /^### /{f=0} f' RELEASE-NOTES.md | wc -w` prints at most `123` (the summary plus its three labels, each one word for `wc -w`: 120 summary words + 3, Global Constraint 1).
  - Sentence wording is free; the properties above bind.

- [ ] **Step 1: Bump the version lines**

- `VERSION`: replace `7.72.2` with `7.73.0`.
- `.claude-plugin/plugin.json`: replace `"version": "7.72.2",` with `"version": "7.73.0",`.
- `.claude-plugin/marketplace.json`: replace `"version": "7.72.2",` with `"version": "7.73.0",`.
- `plugin.universal.yaml`: replace `  version: "7.72.2"` with `  version: "7.73.0"`.
- `README.md` line 6: replace `version-7.72.2-white` with `version-7.73.0-white`.
- `README.md` lines 22 and 24: replace each `v6.7.0–v7.72.2` with `v6.7.0–v7.73.0`.

Run: `grep -c "7\.72\.2" VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md; grep -c "7\.73\.0" README.md`
Expected: `VERSION:0`, `.claude-plugin/plugin.json:0`, `.claude-plugin/marketplace.json:0`, `plugin.universal.yaml:0`, `README.md:0`; then `3`.

- [ ] **Step 2: Add the `RELEASE-NOTES.md` entry**

Insert directly above the line `## v7.72.2 — \`bypassPermissions\` also needs the setting \`bashEditDiffEnabled\``:

```markdown
## v7.73.0 — dashboard: a Source line on every card, a true "as of" line, the shared-ref line, a short Git card

**Problem.** A private dashboard page showed 11 "open items of recent sessions" that were all fixed, and its shared page was 25 days old with no warning. No card said what it reads, and old branches filled the Git card.

**Change.** Session open items and the "Mark resolved" control are removed. Every card has a "Source:" line; the "as of" line shows the commit date; the private page shows the state of the shared ref and of the last shared publish; the Git card is sorted by date and folds old branches.

**Effect.** Reinstall the plugin. Reject old `resolve-open-item` proposals at the next `sync`. Nothing else to migrate.

### Why

On 2026-10-19 the private page of one repository listed 11 open items of recent sessions; all 11 were already fixed. The extractor took every `Open:` line of the last 10 `session-log.md` entries, and a line stayed open until it held `[resolved`. The skill that writes these entries, `context-management`, never writes `[resolved`; only the dashboard's own `sync` did. In the same week the shared page was 25 days old: work had moved to another branch, and the "as of" line showed the build time, not the date of the commit, so the old page looked current.

### What changed

- **Session open items are removed** from the page, with the "Mark resolved" control and the `sync` kind `resolve-open-item`. `context-management` is not changed: it still writes `Open:` lines, and the session-start hook still shows the last two saved entries to the model. A `resolve-open-item` proposal that still waits in the page database gets the verdict `invalid` with the reason `resolve-open-item was removed in 7.73.0; reject this proposal`; reject it in `sync` step 3. A proposal left in `applying` by an interrupted sync whose write had landed is reported `invalid` too; rejecting it does not undo the `[resolved` mark already written into `session-log.md`.
- **Recent sessions** are listed newest first, each as `<date and time of the entry> · <goal>`.
- **Every card has a "Source:" line** that names the file, folder or git command it reads and the rule that selects its items. On the shared page, the unfinished runs, the Git card and the recent commits name the shared run's own source. A test keeps the numbers in these sentences (10 entries, 20 commits, 15 releases) equal to the extractor's limits.
- **The "as of" line** shows the commit date and, on the private page, ` · N tracked files changed, not committed` when N > 0. A detached HEAD now shows the build time too. Every date that the extractor computes is now in the local time zone (`--date=short-local`).
- **The shared-ref line** on the private page names the shared ref and the date of its last commit, the commits of the checked-out branch that are not in it, and the time of the last shared publish from this machine. It is a warning when the oldest of those commits is more than 14 days old, when the last shared publish lies more than 14 days before the previous private publish (or never happened), or when the ref is missing or cannot be read. The extractor reads it from `config.json` and the state files through `--data-dir` (no new option) and repeats it on standard error as `dashboard-extract: shared page: <line>`; `refresh` repeats it in its report. `share` now keeps `shared.json` in the state folder after a successful publish. `--verify` refuses shared data that holds this field.
- **The Git card** is sorted by date (newest first), marks the checked-out branch with `[current]`, and folds branches with no commit in the last 90 days into one `<details>` element. Branch names now come from `%(refname:lstrip=2)`, so a tag with the name of a branch no longer turns the name into `heads/<name>`.

### What you will see at the first refresh

The first `refresh` prints these lines once, in the `--diff` output of its renderer step, and they are expected:

    sessionOpenItems: 0 added, <n> removed
    sessionOpenItems: status ok → absent

(The first line appears only when the old section held items.)

### Accepted limits

- The dates of unfinished runs come from `skills/pickup/scripts/git-runs.js`, which `/pickup` shares; they stay in the committer's time zone (at most one day apart near midnight).
- After a squash or rebase merge, the branch's own commits are still "not in" the shared ref, and the shared-ref line says so literally; checking out the shared branch, or deleting the merged branch, ends it.
```

Run: `awk '/^## v7.73.0/{f=1;next} /^## v7.72.2/{f=0} f' RELEASE-NOTES.md | grep -c -E "^\*\*(Problem|Change|Effect)\.\*\*"; awk '/^## v7.73.0/{f=1;next} /^### /{f=0} f' RELEASE-NOTES.md | wc -w`
Expected: `3`; a number at most `123`.

- [ ] **Step 3: Run every fast suite listed in the repository `CLAUDE.md`**

Run: `for s in codex/run-unit-tests.sh smart-compress/run-tests.sh reviewer-templates/run-tests.sh writing-plans/run-tests.sh in-run-rulings/run-tests.sh fill-prompt/run-tests.sh orchestrating-development/run-tests.sh review-gates/run-tests.sh measure-context/run-tests.sh pickup/run-tests.sh analyze-compaction/run-tests.sh sdd-scripts/run-tests.sh suite-guard/run-tests.sh worklog/run-tests.sh dashboard/run-tests.sh finishing-branch/run-tests.sh using-git-worktrees/run-tests.sh skill-test-runner/run-tests.sh find-polluter/run-tests.sh verification-before-completion/run-tests.sh; do bash "tests/$s" >/dev/null 2>&1 && echo "ok $s" || echo "FAILED $s"; done`
Expected: 20 lines that start with `ok `, none with `FAILED`.

(If a harness check refuses this loop as a removal-style command, run the 20 commands one by one; the expected result is the same.)

- [ ] **Step 4: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): 7.73.0 dashboard sources, as-of line, shared-ref line, Git card" --trailer "Session: dashboard-sources" --trailer "Stage: task 12/12"
```
