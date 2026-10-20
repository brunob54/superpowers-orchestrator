# Dashboard release 1: sources, a true "as of" line, the shared-branch line, a short Git card

- Date: 2026-10-19
- Target version: 7.73.0
- Skill: `skills/dashboard`
- Input: the report "Dashboard structure: consolidated suggestions"
  (2026-10-19, written in the repository django-task-manager by six review
  agents). The report is not in this repository. This spec repeats every fact
  of the report that it relies on, so the report is not needed to implement
  it. Suggestion ids such as S-1 refer to that report.

## 1. Problem

On 2026-10-19 the private dashboard page of django-task-manager showed 11
"Open items of recent sessions". All 11 were already fixed. Two mechanisms
produced the wrong picture:

1. **Session open items never close.** The extractor
   (`scripts/dashboard-extract.js`, the script that reads files and git and
   writes the page data as JSON) takes every `Open:` line of the last 10
   entries of `session-log.md`. A line stays open until its text contains
   `[resolved`. The skill that writes these entries, `context-management`,
   never writes `[resolved`. The only writer is the dashboard `sync` command.
   The section title does not name `session-log.md`, so the owner looked for
   the items in the work log.
2. **The shared page was 25 days old, with no warning.** The shared page is
   built from a fixed remote branch, the **shared ref** (stored once as
   `sharedRef` in the dashboard configuration). Work had moved to another
   branch. The "as of" line of the page shows the build time, not the date of
   the commit, so the old page looked current.

In addition, no card says which file or git command it reads, and the Git
card lists all unmerged branches in name order, so old branches fill the
first screen.

## 2. Scope

This release changes:

1. **Session open items are removed from the page**, together with the page
   control and the `sync` action that resolve them (section 4.1).
2. **"Recent sessions" shows the entry date**, newest first (section 4.2).
3. **Every card has a "Source:" line** (S-1, section 4.3).
4. **The "as of" line shows the commit date** and the number of files not
   committed (S-5, section 4.4).
5. **The private page shows the state of the shared ref and of the last
   shared publish**, with a warning for work missing from the shared page
   for more than two weeks and for a shared publish that keeps failing
   (S-8, section 4.5).
6. **The Git card is sorted by date, marks the current branch, and folds old
   branches** (S-26, section 4.6).

### Non-goals

- Work-log tabs, the counter row, the full section-field guard of the shared
  page (S-41) and the keyboard pattern of the tabs (S-35). These are
  release 2 and get their own spec.
- Every other suggestion of the report (P2 and P3 items).
- No change to `context-management`. It still writes `Open:` lines into
  `session-log.md`. The page no longer shows them; the session-start hook
  still shows the last 2 saved entries to the model. This is intended.
- `refresh` never changes `sharedRef` by itself and never follows the
  checked-out branch: that could publish unfinished work.
- No count of unpushed commits per branch and no "gone" upstream mark.

No decision in this design matched the prior-art trigger predicate.

## 3. Current state (facts this design relies on)

All paths are relative to `skills/dashboard/`. Line numbers are as of
version 7.72.2 (commit 971beb2b).

- Section ids: `scripts/dashboard-extract.js:91-95`. Tab layout: the `TABS`
  constant in `template.html:108-111`; card titles: `TITLES`,
  `template.html:112-117`; per-card muted lines: `sectionExtras`,
  `template.html:180-187`.
- `sessionLog()` (`dashboard-extract.js:464-493`) builds two sections from
  the last `SESSION_ENTRIES = 10` (`:106`) entries that are not superseded:
  `sessionOpenItems` (kinds `open-item` and `raw`, plus the section field
  `olderUnresolved`) and `sessions` (kind `session`: the `Goal:` line, with
  the entry heading in the field `entry`). Items are pushed in file order,
  so the oldest entry comes first.
- The parser code used only for open items: the functions `openItems` and
  `openItemText` (`scripts/dashboard-parse.js:124-173`), the constants
  `RESOLVED_MARK` (`:18`), `OPEN_LIST`, `OPEN_ONE_LINE`, `ONE_LINE_PREFIX`,
  `LIST_END`, `BULLET`, `CONTINUATION` (`:21-26`), and their exports
  (`:306-310`). `SUPERSEDED_MARK` (`:19`) and `ID_SEPARATOR` (`:20`) lie
  between them and stay. `lineAtOccurrence` is also open-item-only: its one
  caller is `findResolveTarget` (`scripts/dashboard-sync.js:288`), which
  this release removes; test-02 has two cases for it.
- `RESOLVED_SUFFIX` (`:17`) is NOT open-item-only: `normalizeLine`
  (`:75-77`) strips it, and `normalizeLine` is called by `occurrenceOf` and
  `lineItemId` (`:106-117`, `:222`). Every item id depends on it, and so
  does every match of a pending proposal to its item on the page, which
  finds a proposal by item id. (Sync's `findPartTarget` matches a
  `set-part` proposal by part number and exact row text, without
  `normalizeLine`.)
- `KIND.raw` (`scripts/dashboard-extract.js:98`) is NOT open-item-only:
  `tableItems()` (`:577`) gives every malformed work-log table row
  `kind: 'raw'`, and test-05 (`:96`) expects it.
- `sync` knows two proposal kinds: `resolve-open-item` (only on
  `session-log.md`) and `set-part` (only on `docs/worklogs/<slug>.md`)
  (`scripts/dashboard-sync.js:39`, `basicInvalid` at `:214-235`). A proposal
  with an `invalid` verdict stays `pending`, and SKILL.md `sync` step 3 lets
  the owner reject it explicitly.
- The page shows a proposal only next to the item with the same id
  (`template.html:308`, `:352`). A proposal whose item no longer exists is
  not shown on the page.
- `commitMeta()` (`dashboard-extract.js:661-672`) returns `sha`, `short`,
  `branch`, `ref`, `defaultBranch`. There is no commit date. `asOfLine()`
  (`template.html:189-194`) prints "as of commit <short> on branch <branch>,
  built <date time>", or "as of commit <short> (detached HEAD)" with no build
  time. The number of dirty tracked files exists only as
  `sections.git.dirty` (private run; `null` in the shared run).
- The private extract run (SKILL.md `refresh` step 4) does not receive the
  shared ref. The shared run receives it as `--ref '<sharedRef>'`, in the
  form `<remote>/<branch>` (SKILL.md `refresh` step 6). When the ref no
  longer exists, the shared extract stops with exit code 2
  (`dashboard-extract.js:770`).
- Git card, private run: `git for-each-ref --no-merged=refs/heads/<base>
  --format=%(refname:short)%09%(committerdate:short) refs/heads/`
  (`dashboard-extract.js:376`), default branch removed, no `--sort` (git's
  default order, refname ascending, per git-for-each-ref(1) `--sort`). Items have `kind: 'branch'`, `name`,
  `date`. The shared run takes each date from `git log -1` of the upstream
  (`:445`). No item marks the current branch.
- `dashboard-render.js --verify` for the shared audience checks items only:
  it counts items whose `visibility` is not `tracked`
  (`dashboard-render.js:165-168`). It does not check section-level or
  top-level fields.
- The extractor reads `config.json` only in its state commands
  (`dashboard-extract.js:178-197`), through `stateDir()` and
  `readConfig()` (`:146-160`); every command of SKILL.md passes
  `--data-dir`. `refresh` step 7 copies `private.json` to
  `<state>/private.json` after a successful private publish, and
  `shared.json` to `<state>/shared.json` after a successful shared publish.
  `share` publishes the shared page through `refresh` step 6 but does not
  copy `shared.json`.
- The extractor writes its messages to standard error with the prefix
  `dashboard-extract: ` (`dashboard-extract.js:124`). It exports nothing.
  `COMMIT_LIMIT = 20` is at `:51`.

## 4. Design

### 4.1 Session open items removed

- **Every list of names to remove in this section** is checked by
  searching the whole repository for each name before it is removed; a
  name with another caller stays.
- **Extractor.** Remove `SECTION.sessionOpenItems`, `KIND.openItem`, the
  open-item loop (including its `KIND.raw` branch at `:480`) and
  `olderUnresolved` from `sessionLog()`. `KIND.raw` itself stays
  (section 3).
  The builder entry registers only `SECTION.sessions`. When `session-log.md`
  is missing, only `sessions` gets the not-found section.
- **Parser.** Remove the code that only open items use (section 3),
  including `lineAtOccurrence` and its two test-02 cases. Keep
  `RESOLVED_SUFFIX`, `SUPERSEDED_MARK`, `ID_SEPARATOR`, `SESSION_LOG`, and
  everything else that another caller still uses. `normalizeLine`,
  `occurrenceOf` and `lineItemId` stay byte-for-byte unchanged, so that the
  ids of existing items do not change and pending `set-part` proposals
  still meet their items on the page.
- **Template.** Remove `sessionOpenItems` from `TABS` and `TITLES`, the
  `open-item` case of `itemLines`, the `olderUnresolved` extra, the "Mark
  resolved" button, `EDIT_KIND.resolve`, `ITEM_KIND.openItem`, and the
  resolve branches of `changesSomething`, `proposalBase` and `canEditItem`.
  `proposalBase` then always builds a `set-part` proposal.
- **Sync.** Remove `KIND.resolve`, its rules in `basicInvalid`,
  `expectedChange` and `findResolveTarget`. A proposal whose `kind` is
  `resolve-open-item` gets the verdict `invalid` with exactly this reason,
  held in one constant:

  `resolve-open-item was removed in 7.73.0; reject this proposal`

  Every other unknown kind gets the reason `kind is not set-part`. This
  replaces the old reason, which named both kinds. Sync step 3 already lets the owner reject an
  `invalid` proposal; no change to SKILL.md `sync` is needed for this.
- **First refresh after the update.** `refresh --diff` prints
  `sessionOpenItems: status ok → absent` (`dashboard-render.js:193`), and
  before it `sessionOpenItems: 0 added, <n> removed` when the old section
  held items. The release notes quote these lines and say that they are
  expected.

### 4.2 Recent sessions

- The extractor emits the `sessions` items newest first (reverse file
  order). The 10-entry limit stays.
- The template shows each item as one line:
  `<entry date and time> · <goal>`, for example
  `2026-10-14 12:00 · Rename the RDKit helper`. The date and time come from
  the existing field `entry` (the heading text, for example
  `## 2026-10-14 12:00 [saved]`); the template shows only its
  `YYYY-MM-DD HH:MM` part. When `entry` does not start with that pattern
  after `## `, the template shows the goal alone.

### 4.3 "Source:" line on every card

- A constant `SOURCES` in `template.html`, next to `TITLES`, maps each
  section id to one sentence. `renderSection` renders it as
  `Source: <sentence>` (the prefix `Source: ` is one constant,
  `SOURCE_PREFIX`) in a `<p class="muted source">` element placed directly
  after the card's `<h2>`, before every status, note, extra line and item.
  This holds in every state of the section: with items, empty, not found,
  failed, and absent from the data ("not in this data").
- The shared page uses the same sentences, except where the shared run reads
  a different source. For those sections a constant `SHARED_SOURCES` holds a
  replacement sentence: when `data.audience` is `shared`, the page shows the
  `SHARED_SOURCES` sentence in place of the `SOURCES` sentence, never both.
- Every sentence names where the section reads its items — the file, the
  folder, or the git command; for a section that scans many files or refs
  (`unfinishedRuns`, `runHistory`), the folder and the kind of refs
  scanned — and the rule that selects the items. Paths are relative to the
  repository root. No sentence contains an absolute path or a user name.
- The table below is a proposal. Before writing each sentence, the
  implementer reads the builder of that section and corrects both the
  source and the selection rule where the code differs; where the table and
  the rule above disagree, the rule wins. The spec reviewer of the plan
  checks the final texts against the code.

| Section | Private (and shared, unless a shared text is given) | Shared text, when different |
|---|---|---|
| `unfinishedRuns` | Orchestration runs that are not finished, read from the orchestration logs on local branches. | Orchestration runs that are not finished, read from the orchestration logs on the pushed branches of the shared remote. |
| `git` | Unmerged local branches (`git for-each-ref`), unpushed commits and changed files (`git status`) of the checked-out branch. | Unmerged pushed branches of the shared remote. |
| `activeWorklogs` | Work logs in `docs/worklogs/` that are not closed: their parts that are not started or in progress, and their open items. | — |
| `currentGoal` | The `## Current Goal` section of `state.md`. | — |
| `releases` | The version in `VERSION` (or `package.json`) and the first 15 release headings, in file order, of `RELEASE-NOTES.md` (or `CHANGELOG.md`). | — |
| `runHistory` | Topic folders in `docs/superpowers-orchestrator/` and their orchestration logs. | — |
| `closedWorklogs` | Work logs in `docs/worklogs/` that are closed. | — |
| `commits` | The last 20 commits of the checked-out branch (`git log`). | The last 20 commits of the shared ref (`git log`). |
| `sessions` | The `Goal:` lines of the last 10 entries of `session-log.md`, newest first. | — |
| `knownIssues` | The `## ` headings of `known-issues.md`. | — |

- **Neutral about the file location.** The file sentences do not say
  whether a file is read from the working tree or from the shared ref: the
  shared run reads every file from the shared ref, and the "as of" line of
  the shared page already names that ref. A file that is committed on the
  shared ref (for example a tracked `session-log.md`) appears on the shared
  page; no sentence claims otherwise.
- **Numbers.** The numbers in these sentences must equal the extractor
  constants: 10 = `SESSION_ENTRIES` (`sessions`), 20 = `COMMIT_LIMIT`
  (`commits`, in `SOURCES` and in `SHARED_SOURCES`), 15 = `RELEASE_LIMIT`
  (`releases`). `SOURCES` and `SHARED_SOURCES` are added to the
  `globalThis.DashboardApp` export of the template (`template.html:535`),
  as `PART_STATUSES` already is. A test in test-08 reads the sentences
  from that export and reads the three constants from the extractor's
  source text, then checks that each named sentence contains its value.
  Reading the extractor's source text is an accepted exception to the rule
  of section 6 (tests use public interfaces): the extractor exports
  nothing, and the test exists only to keep two copies of one number
  equal.
- All text is set with `textContent` (the test page throws on any use of
  `innerHTML`).

### 4.4 A true "as of" line

- `commitMeta()` adds `date`: the committer date of the page's commit,
  `git log -1 --format=%cd --date=short-local <ref>`, in both audiences.
- **Local dates.** The local time zone is used for every date that the
  dashboard's own extractor computes: this `date`, the shared-ref `date`
  (4.5), the branch dates (4.6), and the "Recent commits" dates, whose
  `git log` in `commits()` (`dashboard-extract.js:457`, both audiences)
  changes from `--date=short` to `--date=short-local`. One commit then
  shows the same date in the "as of" line, the shared-ref line and
  "Recent commits". Not changed: the `lastCommitDate` of unfinished runs,
  which comes from `skills/pickup/scripts/git-runs.js:143`. That module is
  shared with `/pickup`, and changing it would change `/pickup` output and
  its suite; its dates stay in the committer's time zone (accepted, a
  one-day difference near midnight at most).
- **Day counts.** Every count of days between two dates (the 14-day
  rules of section 4.5 and the 90-day fold, all in the template) is a
  calendar-day count on the `YYYY-MM-DD` parts:
  `(Date.UTC(y2, m2-1, d2) - Date.UTC(y1, m1-1, d1)) / 86400000`. It never
  divides a difference of local times, which a daylight-saving change would
  shift by an hour.
- `asOfLine()` prints:
  - on a branch: `as of commit 4aebf3a (2026-10-19) on branch X · built
    2026-10-19 16:43`;
  - on a detached HEAD: `as of commit 4aebf3a (2026-10-19), detached HEAD ·
    built 2026-10-19 16:43` (the build time is now shown here too);
  - followed by ` · N tracked files changed, not committed` only when
    `sections.git.dirty` is a number greater than 0. In the shared run it is
    `null`, so the shared page never shows this part. `N` is the same count
    as the Git card (`git status --porcelain --untracked-files=no`), so
    untracked files are not counted; the wording says "tracked" for that
    reason. For N = 1 the text is ` · 1 tracked file changed, not
    committed`.
- The commit date is formatted as stored; the build time keeps the existing
  `YYYY-MM-DD HH:MM` cut of `generatedAt`.

### 4.5 Shared-ref line on the private page

**Input.** The private extract run reads the dashboard configuration
itself. Every command of SKILL.md already passes `--data-dir`, and the
extractor already has `stateDir()` and `readConfig()`
(`dashboard-extract.js:146-160`). When the private run gets `--data-dir`,
it reads `sharing`, `sharedRef` and `sharedUrl` from `config.json` and the
files `<state>/shared.json` (the data of the last successful shared
publish: SKILL.md `refresh` step 7 copies it there only after the shared
page was published; this release makes `share` copy it too, see 4.7) and
`<state>/private.json` (the data of the last successful private publish,
copied by `refresh` step 7). No new command-line option is added, so the model never has
to build one, and a stored value with an unusual character never reaches a
shell command. Without `--data-dir`, or when `config.json` is missing, the
field `sharedRef` is `null`. The shared run never computes this field.

**Which case applies.**

| Configuration | Case |
|---|---|
| `sharing` is `on` and `sharedRef` is stored | **following** (the checks below) |
| `sharing` is not `on` and `sharedUrl` is stored | **sharing off** |
| anything else | `null`: no line |

For **following**, the private run does NOT call `checkSharedName` or
`sharedRemote`: both call `stop()` (exit code 2), and SKILL.md `refresh`
step 4 treats exit code 2 as "nothing is published". It runs the same
three checks in a variant that returns a result instead of stopping, in
this order, and the first failing check decides the result:

1. The form check of `requireSharedRefForm`, as a test that returns true
   or false. Failure → `error` with the message `<value> is not of the form
   <remote>/<branch>` (a value stored by hand with `--config-set` can have
   any form).
2. `git show-ref --verify --quiet refs/remotes/<name>` (the exact-name
   check). Non-zero exit → `missing`.
3. `git rev-parse --verify --quiet refs/remotes/<name>^{commit}`. Failure
   → `error` with the message `<name> is not a commit`.

After the three checks, a failure of any further git command → `error`
with git's message. Every later command names the ref by its full name,
`refs/remotes/<name>` (written `<ref>` below), as checks 2 and 3 do: a bare
`<remote>/<branch>` could resolve to a local branch or tag of that name
through git's name guessing, which is why `checkSharedName` uses the full
name today. The private run never looks up the remote, so a removed or
renamed remote shows as `missing` through check 2: git-remote(1) states
that `remove` removes and `rename` renames all remote-tracking branches of
the remote. Test-04 checks the removed case.

An `error` message is passed through the existing `sanitize()` of the
extractor (the repository folder becomes its token and the home folder
`~`), and only its first non-empty line is kept, so that the sentence is
always one line.

**Data.** The private data gets one new top-level field, `sharedRef`:

| Case | Value |
|---|---|
| no line | `null` |
| following, the checks pass | `{ "name": "<value>", "short": "<7 hex>", "date": "YYYY-MM-DD", "notShown": <n>, "oldestNotShown": "YYYY-MM-DD" or null, "published": "YYYY-MM-DD HH:MM" or null, "previousBuild": "YYYY-MM-DD HH:MM" or null }` |
| following, check 2 fails | `{ "name": "<value>", "missing": true, "published": …, "previousBuild": … }` |
| following, check 1 or 3 fails, or a later git command fails | `{ "name": "<value>", "error": "<message: sanitize(), first non-empty line>", "published": …, "previousBuild": … }` |
| sharing off | `{ "off": true, "published": "YYYY-MM-DD HH:MM" or null }` |

- `date`: `git log -1 --format=%cd --date=short-local <ref>`, the committer
  date of the ref tip in the local time zone.
- `notShown`: `git rev-list --count <ref>..HEAD`, the number of commits
  reachable from HEAD that are not reachable from the shared ref.
- `oldestNotShown`: the committer date of the oldest of those commits,
  `git log --reverse --format=%cd --date=short-local <ref>..HEAD`, first
  line; `null` when `notShown` is 0.
- `published`: the `generatedAt` of `<state>/shared.json`, cut to
  `YYYY-MM-DD HH:MM`; `null` when that file is missing or is not valid
  JSON. It is the time of the last successful shared publish. The private
  extract runs before the shared publish of the same refresh (SKILL.md
  `refresh` steps 4 to 7), so it shows the publish of the previous
  refresh.
- `previousBuild`: the `generatedAt` of `<state>/private.json`, cut the
  same way; `null` when that file is missing or is not valid JSON. It is
  the time of the previous successful private publish. After a refresh
  where both pages were published, `published` and `previousBuild` are
  minutes apart; when the shared publish failed, `published` stays behind
  while `previousBuild` moves on.

Source for the `-local` dates: git-log(1), option `--date`: a `-local`
suffix on a format uses the local time zone; git-for-each-ref(1) accepts
the same formats on date fields. Checked with git 2.50.1; the oldest git
version that has the suffix is unverified.

A failure here never stops the private extract.

**Page.** When `sharedRef` is `null` or absent (`== null`), the line is
hidden and empty. This is always the case on the shared page, whose data
never has the key. Otherwise the line is built from these parts, joined by
one space, in this order:

| Part | Condition | Text |
|---|---|---|
| ref | following, checks pass | `The shared page follows <name>, last commit <date>.` |
| ref | missing | `The shared page follows <name>, which no longer exists. The shared page cannot be updated.` |
| ref | error | `The state of the shared ref could not be read: <error>.` |
| ref | sharing off | `Sharing is off. The shared page from an earlier share is still published and is no longer updated.` |
| not shown | checks pass, on a branch, `notShown` ≥ 2 | `<notShown> commits of this branch are not in <name>; the oldest is from <oldestNotShown>.` |
| not shown | checks pass, on a branch, `notShown` = 1 | `1 commit of this branch is not in <name>; it is from <oldestNotShown>.` |
| not shown | checks pass, detached HEAD (`commit.branch` is `null`), `notShown` ≥ 2 | `The checked-out commit has <notShown> commits that are not in <name>; the oldest is from <oldestNotShown>.` |
| not shown | checks pass, detached HEAD, `notShown` = 1 | `The checked-out commit has 1 commit that is not in <name>; it is from <oldestNotShown>.` |
| published | `published` is not `null` | `Last published <published>.` |
| published | `published` is `null` | `Never published from this machine.` |

The "not shown" part is left out when `notShown` is 0. The texts state
literal git facts ("not in <name>"); they do not say "ahead of", because a
detached HEAD can have diverged from the ref.

**Style.** The line is a static element of the template header,
`<p id="shared-ref" hidden></p>`, placed directly after `#as-of`.
`renderPage()` runs several times for the owner (at boot, after editing
turns on, after each saved edit), so it never inserts this element: each
call sets its `textContent` and its `class` attribute (with
`setAttribute`), and its `hidden` state. A render repeated any number of
times therefore shows exactly one line.

The classes are `shared-ref banner warn` (the existing warning style) when
any of these holds, and `shared-ref muted` (an information line)
otherwise:

1. **Old work not shown:** `oldestNotShown` lies more than
   `SHARED_STALE_DAYS = 14` calendar days before the date part of
   `generatedAt`.
2. **Shared publish failing:** the case is **following**, and either
   `published` is `null`, or `previousBuild` is not `null` and its date
   lies more than 14 calendar days after the date of `published`. The
   comparison is with the previous private publish, not with today, so a
   two-week pause between refreshes never fires this rule: after such a
   pause both times are equally old.
3. The ref is `missing`, or the case is `error`.

The **sharing off** case is always an information line. The constant
lives in the template; day counts use the calendar-day rule of
section 4.4.

**Why these two rules.** Rule 1 answers "is there work that has been
missing from the shared page for more than two weeks?". In the incident,
the shared ref was 25 days old and HEAD had 19 commits on top of it, the
oldest about 24 days old: rule 1 fires. A new feature branch over a quiet
shared `main` does not fire it until its own oldest commit is two weeks
old; a fast-forward that moves the ref to an old commit does not fire it
either, because only the not-shown commits count. Rule 2 answers "has the
shared page been republished recently?": when step 6 of `refresh` fails at
every refresh (a dead shared URL, a refused publish, a refused
`--verify`), `published` stops moving while `previousBuild` keeps
moving, and rule 2 fires once the gap passes two weeks. A
signal based only on the ref (its age, or ancestry against HEAD) cannot
see that failure, and ancestry alone cannot tell a stale shared ref from an
ordinary feature branch, because in both the shared ref is an ancestor of
HEAD.

**When the line changes.** The line is computed at each private extract.
After `share`, `share --ref <new>` or `share off`, the private page shows
the new state from the next `refresh` on; `share` itself does not rebuild
the private page.

**Report.** When `sharedRef` is not `null`, the private extract run writes
the same line on standard error, as
`dashboard-extract: shared page: <line>`, and still exits 0. Standard
output is not used: without `--out` it carries the JSON document. SKILL.md
`refresh` tells the model to repeat that line, without the
`dashboard-extract: ` prefix, in its final report. The extractor builds
the line once; the template builds the page text from the data fields.
Both produce the exact texts above; test-07 compares them (section 6).

**Guard.** `dashboard-render.js --verify` for the shared audience refuses
data that has a top-level `sharedRef` key (any value). The reason text
`the shared data contains sharedRef` is added to the existing reasons
list, which `--verify` prints as one line `refused: <reason>; <reason>`
(`dashboard-render.js:170`). This one-field check is added now because the
field exists only for the private page; the general section-field guard
(S-41) is release 2.

### 4.6 Git card

- **Current branch.** The private run marks the item of the checked-out
  branch with `current: true` (all others: no field). The item `name` is
  read with `%(refname:lstrip=2)` instead of `%(refname:short)`, in both
  audiences where the name comes from `for-each-ref`: `:short` prints
  `heads/<name>` when a tag has the same name as the branch
  (git-for-each-ref(1), "refname"; checked with git 2.50.1), and the
  comparison with the checked-out branch name (from `symbolic-ref`, with
  `refs/heads/` stripped) would then fail. The template shows
  `[current]` after the name. The checked-out branch is listed only when it
  is unmerged (no change to the selection). The shared run never sets the
  field.
- **Order.** The template sorts branch items by `date` descending, then by
  `name` ascending. An item "without a date" is one whose `date` field is
  missing, `null` or an empty string; such items come after all dated
  items, by name. The extractor order is not relied on.
- **Local dates.** The private run's branch dates change from
  `%(committerdate:short)` to `%(committerdate:short-local)`, and the
  shared run's from `--date=short` to `--date=short-local`, so that they
  are in the same time zone as `generatedAt` (section 4.4 "Local dates";
  source and check: section 4.5, `date`). The fold uses the calendar-day
  count of section 4.4.
- **Folding.** Branches whose `date` is more than `BRANCH_FOLD_DAYS = 90`
  days before the date part of `generatedAt` are not listed one by one.
  The current branch is never folded. Items without a date are never
  folded. The card then holds, in this order: the item list (dated items
  that are not folded, then items without a date), and after that list one
  `<details>` element whose `<summary>` reads `<n> older branches (no
  commit in the last 90 days)`, or `1 older branch (no commit in the last
  90 days)` for one, and which holds a second list of the folded items in
  the same sort order. When no branch is old, no `<details>` element is
  made.
- Both audiences use the same sorting and folding.

### 4.7 Documents

- `SKILL.md`: the description (line 4) no longer lists "open items of recent
  sessions"; the `refresh` report step repeats the `shared page:` line;
  `share` step 5, after a successful publish, copies
  `<scratchpad>/dashboard/shared.json` to `<state>/shared.json`, as
  `refresh` step 7 does, so that `published` (section 4.5) is set from the
  first share on.
- `docs/guide/README.md`: remove the passages about session open items and
  the "Mark resolved" control (around lines 1360-1363 and 1391). Add to the
  passage that describes the two pages (around lines 1354-1389): the
  "Source:" line of each card, the commit date and the changed-file count
  in the "as of" line, the shared-ref line with its texts and its two
  warning rules (old work not shown, shared publish failing) and the fact
  that it updates only at `refresh`, the "sharing off" line, and the
  folded old branches of the Git card.
- `README.md`: lines 39 and 370 say "open items"; make each say which open
  items (work-log open items) where it refers to the dashboard.
- `hooks/skill-rules.json`: check the dashboard entry's keywords and
  patterns; remove any that only fit session open items.
- The dashboard spec
  `docs/superpowers-orchestrator/2026-09-29-dashboard/specs/dashboard-design.md`:
  add one line `Amended in 7.73.0 by
  docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md:
  <what changed>` at each affected section (5.1, 5.2, the section 7 table,
  section 8, the test lists). Do not rewrite those sections. Code comments
  that cite a spec section for removed behaviour are removed with the code.
- The release files listed in the repository `CLAUDE.md` ("Releases"),
  with a `RELEASE-NOTES.md` entry for 7.73.0 that starts with the
  three-line summary.

## 5. Error handling

- Shared-ref computation: the three checks of section 4.5 and every later
  git failure become the `missing` or `error` case, as section 4.5 assigns
  them; the private extract continues and exits 0.
- A missing `entry` date or a branch without a date never throws in the
  template: the fallbacks of sections 4.2 and 4.6 apply.
- A missing or unreadable `config.json`, `<state>/shared.json` or
  `<state>/private.json`: `sharedRef` is `null` (configuration) or
  `published` / `previousBuild` is `null` (state files); the private
  extract continues and exits 0.
- Old `resolve-open-item` proposals: `invalid` with the reason of
  section 4.1; they stay `pending` until the owner rejects them.

## 6. Testing

All tests are in `tests/dashboard/` and run with
`bash tests/dashboard/run-tests.sh`. Tests check behaviour through the
scripts' command lines and the page as rendered by the existing fake page,
not internal function names.

| Test file | Change |
|---|---|
| `test-02-parse.js` | Drop the open-item cases and the two `lineAtOccurrence` cases; keep the cases of `normalizeLine` and of every kept function. |
| `test-05-extract-files.js` | Fixture keeps `session-log.md`; assert no `sessionOpenItems` section, `sessions` newest first with `entry`; a malformed work-log table row still has `kind: 'raw'`; update `FILE_SECTIONS`. |
| `test-04-extract-core.js` | `commit.date` present; `current: true` on the checked-out unmerged branch only, also when a tag has the same name as the branch; `sharedRef` read from `config.json` through `--data-dir` in every case of section 4.5 (no line: sharing off without `sharedUrl`, no `--data-dir`, no `config.json`; following with checks passing, including `notShown` 0, 1 and 2 and `oldestNotShown`; missing ref; removed remote; value of the wrong form; value with a single quote; ref that is not a commit; sharing off with `sharedUrl`), with `published` and `previousBuild` from present, missing and invalid state files, and in none of them a non-zero exit; the `dashboard-extract: shared page:` line on standard error when `sharedRef` is not `null`, and no such line otherwise; `commit.date`, the shared-ref `date`, `oldestNotShown` and the `commits` dates in the local time zone (run with a fixed `TZ` and a commit whose committer zone differs, so that `short` and `short-local` give different dates). |
| `fake-page.js` | Add `shared-ref` to `STATIC_IDS` (and to the hidden ids, as it starts `hidden`), so that the template can set its text, class attribute and `hidden` state. |
| `test-06-privacy.js` | No `sharedRef` key and no `current` field in shared output; drop the `sessionOpenItems` status check. |
| `test-07-template.js` | Tab content without the removed section; a `Source: ` line directly after the `<h2>` of every card, in all five states (with items, empty, not found, failed, absent); on the shared page the replacement text where defined, and never both texts; the "as of" variants (branch, detached, dirty count 1 and 2, shared page without count); the shared-ref line, checked by its classes and by every exact text of the section 4.5 table: rule 1 at 14 and 15 days of `oldestNotShown`, and a ref tip 30 days old with `notShown` 0 (information style); rule 2 with `published` `null`, with a gap of 14 and of 15 days to `previousBuild`, and with both times 30 days old and equal (information style); warning style when missing and on error; information style for sharing off; hidden and empty on the shared page and when `sharedRef` is absent; days counted across a daylight-saving change in calendar days; branch order (dated, then without a date: missing, `null` and empty), `[current]`, folding at 90 and 91 days, `1 older branch` and `2 older branches`, no `<details>` when nothing is old; session line with and without a parsable `entry`; `renderPage` called twice (as after editing turns on) still gives exactly one shared-ref element; the template source places `id="shared-ref"` directly after `id="as-of"`. **Same wording:** run the extractor on a fixture repository for each shared-ref case (checks passing on a branch and on a detached HEAD, missing, error, sharing off), render its data file with the template, and compare the page line with the extractor's `dashboard-extract: shared page:` sentence. |
| `test-08-template-edits.js` | No "Mark resolved" control; a `set-part` edit still works. Add the check that the numbers in the named sentences of `SOURCES` and `SHARED_SOURCES` equal `SESSION_ENTRIES`, `COMMIT_LIMIT` and `RELEASE_LIMIT` (section 4.3). |
| `test-09-render.js` | `--verify` refuses shared data with a top-level `sharedRef`; drop the session-item privacy fixture or move it to a kept kind. |
| `test-10-sync-check.js`, `test-11-sync-apply.js` | Rewrite the cases built on `resolve-open-item` on `set-part`; a `resolve-open-item` proposal gets `invalid` with the exact reason; the security cases keep their coverage on `set-part`. |
| `test-12-skill-text.js` | Pin the instruction to repeat the `shared page:` line in the `refresh` report, and the copy of `shared.json` to `<state>/shared.json` in `share` step 5. |

Also run every fast suite listed in the repository `CLAUDE.md` before the
release.

## 7. Failure modes considered

1. **Warning on every feature branch, or no warning on a failing shared
   publish** (critical in the first draft and again in review round 4,
   fixed): see "Why these two rules" in section 4.5. A feature branch whose
   oldest commit is more than two weeks old and is not yet in the shared
   ref does show the warning; this is intended, because that work has been
   missing from the shared page for more than two weeks.
2. **Source text drifts from the extractor limits** (minor): the test of
   section 4.3 fixes the numbers to the constants. The wording of the
   selection rules is checked by the plan review, not by a test.
3. **Old resolve proposals stay in the page database** (minor): they are
   invisible on the page, `sync` names them with a clear reason, and the
   owner rejects them once. A proposal left in `applying` by an interrupted
   sync whose write had already landed is also reported `invalid`;
   rejecting it does not undo the `[resolved` mark already written into
   `session-log.md` (the release notes say so).
4. **The shared-ref state is computed from the local remote-tracking ref**
   (not a defect): the shared page is built from the same local ref, so the
   line describes the ref that the shared page follows. A `git fetch`
   updates both. The private page is published (step 5) before the shared
   page (step 6), so `published` shows the previous refresh's shared
   publish; rule 2 of section 4.5 compares it with the previous private
   publish, so a single failed step 6 is reported in the terminal only, and
   failures that persist for two weeks turn the line into a warning.
5. **Squash or rebase merges** (accepted limit): after the work of a branch
   lands on the shared ref as new commits, the branch's own commits are
   still "not in <name>". The text states this literally ("commits of this
   branch are not in <name>"), and it is true; while the owner stays on
   such a branch for more than two weeks after its first commit, rule 1
   shows the warning. Checking out the shared branch, or deleting the
   merged branch, ends it.
6. **Unfinished-run dates in the committer's time zone** (accepted limit):
   section 4.4 "Local dates".

## 8. Rollout

- One release, 7.73.0. Nothing to migrate in the repository files. The
  owner rejects any old `resolve-open-item` proposal at the next `sync`.
- The first `refresh` after the update prints
  `sessionOpenItems: status ok → absent` in its `--diff` output (section
  4.1).
