# Work log: a tracking document for one piece of multi-part work

Date: 2026-09-21. Target release: v7.52.0. Status: design approved by the user
in the brainstorming session of 2026-09-21.

Corrected on 2026-09-23, after the release of v7.52.0: three statements are
brought in line with the code that shipped — the `$(0)` field of the list
command, the root of a project without git, and the meaning of `<slug>` on
line 1. No design decision changed.

## Problem

A piece of work that has several parts and lasts many sessions needs one
document that records its progress. The first real example is a test
refactoring in another project: four groups of tests, refactored one group
after the other, in interactive sessions.

The plugin writes three memory files today, and none of them can hold this:

- `state.md` is one file per project, under 100 lines, and every save-state
  rewrites it. It is a snapshot of one moment, not a history.
- `session-log.md` holds the decisions of each session in time order. It has no
  table of parts and no list of open items.
- `known-issues.md` maps a recurring error to its solution. It does not track
  work.

This repository has one hand-made document of the needed kind:
`docs/orchestration-issues.md`. Its useful properties are: a worklist whose
rows are deleted when the fix ships; a history that is never rewritten; an
admission rule (a rule that decides which findings may become a worklist row);
and an `## Accepted limits` section for correct findings that get no row. On
2026-09-21 we measured that, without the admission rule, reviews filled the
worklist: of rows 41 to 92, 0 came from a real case.

## Goal

A skill named `worklog` creates and maintains a **work log**: one Markdown
document per piece of multi-part work, tracked by git, living across many
sessions. A project can hold several work logs. A session that reads a work
log can maintain it correctly even when the plugin is not installed, because
the document carries its own update rules.

## Scope and non-goals

In scope:

- The skill `skills/worklog/SKILL.md` and its template file.
- Three commands: create, full update, close.
- One short notice in the output of the session-start hook that names the
  active work logs (decided by the user on 2026-09-21, after review round 3).
- An exclusion in the `/pickup` scan so that an updated work log does not count
  as unfinished work.
- Routing (`hooks/skill-rules.json`), tests, guide and release documents.

Non-goals:

- **No new hook, and no injection of a work log's content.** The existing
  session-start hook gains one short notice (see "Discovery through the
  session-start hook"); the content of a work log is never injected. The hook
  output limit is 10,000 characters (`LIMIT = 10000` in
  `hooks/session-start-assemble.js`; measured 2026-09-17, comment at
  `hooks/session-start` lines 499-505), and the hook adds its six optional
  sections in priority order while each one fits. In this repository, in the
  session of 2026-09-21, four of them did not fit: `state.md`,
  `known-issues.md`, `context-snapshot.json` and `project-map.md`.
- **No pointer in `state.md`.** An earlier version of this design kept the
  pointer there. Review round 3 measured that the hook injects `state.md` only
  when the whole file fits in about 3,000 characters (this repository's file
  has 5,032), that four skills write `state.md`, and that a pointer-only write
  changes the modification time that two hooks use to judge staleness.
  `context-management` and `state.md` are therefore not changed.
- **No automatic commit.** The skill never commits. The work log goes into the
  next commit that the user requests.
- **No enforcement that Claude updates the document.** The rules say when to
  update. A long session, or a compaction (the automatic shortening of a long
  conversation), can make the model forget them. The command `/worklog` forces
  a full update. This is an accepted limit.
- **No size cap.** Rows are deleted when fixed and a work log is closed when
  its work is done; only `## Decisions` grows. A cap can be added when a real
  work log becomes too large.
- **No reopen command.** A closed work log is reopened by hand: the user edits
  line 1 back to the active form. The skill never does this.
- **No migration of `docs/orchestration-issues.md`.** It stays as it is.
- The word "workstream" is not used for this feature. `writing-plans` already
  uses it for the commit trailer `Session: <slug>`.

No decision in this design matched the prior-art trigger predicate.

## Definitions

- **Work log**: the document defined by this spec.
- **Part**: one unit of the work that gets its own status, for example one
  group of tests.
- **Open item**: a problem found during the work that is not fixed yet and
  that passes the admission rule of the work log.
- **Accepted limit**: a finding that is correct but does not pass the
  admission rule, or that the user decides not to fix.
- **Slug**: the short name of a work log. It must match
  `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase ASCII letters, digits, single hyphens),
  the same rule as the topic slug of the Artifact Layout, and it has at most
  40 characters. The length limit bounds the size of the hook notice. The **file name is
  the authority** for the slug; the `slug=` field of the status line repeats
  it for a human reader. The words `new`, `update` and `close` are the command
  words and are not valid slugs. "The slug rule" in this spec means all three
  parts: the pattern, the 40 characters, and the three refused words.
- **Active**: a work log whose first line starts with
  `<!-- Work log: status=active `.
- **Project directory**: the working folder in which the session started. The
  session-start hook runs there.
- **Root**: the repository root, the output of
  `git rev-parse --show-toplevel`; for a project that is not a git repository,
  the folder in which the command runs (`pwd`), which is the project directory
  only while the shell has not moved (see "Error handling"). Every
  `docs/worklogs/` path of this spec is relative to the root. In the usual
  layout the project directory is the root.

## Architecture

### Location and name

A work log lives at `docs/worklogs/<slug>.md` under the root. Git tracks the
file. The folder `docs/worklogs/` is the single source of truth for which work
logs exist in the checked-out branch.

### The status line

The first line of every work log is a machine-readable status line, written
as an HTML comment (a comment that a Markdown viewer does not show):

```
<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->
```

After closing, the line is:

```
<!-- Work log: status=closed slug=<slug> created=<YYYY-MM-DD> closed=<YYYY-MM-DD> -->
```

The line stands on line 1 because a Markdown formatter (Prettier, or
`markdownlint --fix` with its rule MD022) inserts an empty line between a
heading and the text below it, so a status line directly under the `# `
heading would move and the work log would no longer be found. A formatter
leaves a comment on line 1 where it is. (Formatter behaviour: from the tools'
documented rules, not replayed here — unverified.)

The active work logs of a project are found with **the list command**. In a
git repository it can run from any folder, because it builds the path from
the root; without git it takes the folder in which it runs:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIST=""
if [ -d "$ROOT/docs/worklogs" ]; then
  LIST="$(LC_ALL=C find "$ROOT/docs/worklogs" -maxdepth 1 -type f -name '*.md' -exec awk '
    FNR==1 { l = $(0); sub(/^\357\273\277/, "", l)
      if (l ~ /^<!-- Work log: status=active /) {
        n = FILENAME; sub(/.*\//, "", n)
        if (n ~ /^[a-z0-9]+(-[a-z0-9]+)*\.md$/ && length(n) <= 43 &&
            n != "new.md" && n != "update.md" && n != "close.md") print FILENAME
      }
      exit }' {} \; 2>/dev/null | LC_ALL=C sort || true)"
fi
printf '%s\n' "$LIST"
```

Three details of this form come from replays on 2026-09-21, and a fourth was
corrected later. The whole line is written `$(0)`, not `$0`. Claude Code
replaces `$0` in a skill body with the first argument of the command, which
broke `/worklog update` and `/worklog close` when the user gave no slug. In
POSIX `awk`, `$(0)` names the same whole line. Every copy of the command
carries this form. `-exec … {} \;`
starts one `awk` per file: with `{} +`, one unreadable file made `awk` stop
with a fatal error, and every work log after it was hidden without a message.
`LC_ALL=C` stands before `find`, so `awk` inherits it: in a UTF-8 locale the
macOS `awk` did not match the byte pattern of the byte order mark, and in a
UTF-8 locale a range such as `[a-z]` can let accented letters pass (`café.md`
is refused under `LC_ALL=C`). The `sub` on line 1 removes a UTF-8 byte order
mark (three invisible bytes that some Windows editors write at the start of a
file), so such a file is still listed.

The command holds the file-name filter itself: it prints a file only when its
name is a valid slug plus `.md` (the whole slug rule: the pattern, 43
characters at most with `.md`, and none of the three command words). The skill and the
hook therefore see the same set of work logs, and the hook needs no filter
step of its own. The filter is also a safety rule: the hook puts these names
into the model's context, and a file name is text that anyone who can add a
file controls. A name with a line break fails the test as a whole, because
`awk` compares the complete name.

The command is written so that it is safe under `set -euo pipefail`, which
`hooks/session-start` sets on its line 4: there, a `find` on an absent folder
exits 1, `pipefail` passes that status through `sort`, and `set -e` would end
the whole hook at the assignment. The folder test and the `|| true` prevent
this. Every copy of the command keeps both.

It reads line 1 only, so a status line quoted elsewhere in a document never
makes a closed work log count as active. `LC_ALL=C sort` makes the order of
several work logs the same in every locale (`a-b.md` before `a.md` before
`ab.md`). `-type f` means that a work log must be a regular file: a
symbolic link is never listed. `find` is used instead of a
`docs/worklogs/*.md` glob: an unmatched glob is a shell-level error in `zsh`
(zsh manual, option `NOMATCH`, on by default). `FNR` and `FILENAME` are part
of POSIX `awk`. Replayed on 2026-09-21 with macOS `awk` and `find`, as a script
under `set -euo pipefail`, in `bash` and in `zsh` from a sub-folder: an active
file and an active file with CRLF line ends were printed; a closed file that
quotes the active line further down, a file whose status line is on line 3,
a symbolic link, and files named `A.md`, `x y.md`, a name with a line break
a name of 45 characters, `new.md`, `café.md` and a file without read
permission were not, and the files after the unreadable one were still
printed; a file with a byte order mark was printed; with the folder absent, and with a
folder that holds only `A.md`, the script printed an empty line, continued,
and exited 0. Unverified, and covered by the suite where it runs: other `awk`
versions (`gawk`, Git Bash); and `find` and `sort` on Windows Git Bash, which
the hook uses here for the first time. Windows has programs of the same two
names in `System32`, and the last fallback of `hooks/run-hook.cmd` runs
whatever `bash` is on `PATH`. If the wrong `find` runs, it fails, the
`2>/dev/null` and `|| true` hide it, the list is empty, and the hook continues
without a notice.

**Valid forms of line 1.** In the two forms below, `<slug>` is the slug
pattern `[a-z0-9]+(-[a-z0-9]+)*` alone, not the whole slug rule. The
40-character limit and the three refused words are rules of the file name, and
the list command's filter enforces them. The check command below tests the
pattern only. `<date>` is `[0-9]{4}-[0-9]{2}-[0-9]{2}`:

- active: `^<!-- Work log: status=active slug=<slug> created=<date> -->$`
- closed: `^<!-- Work log: status=closed slug=<slug> created=<date> closed=<date> -->$`

A line 1 that matches neither form is **malformed**. A valid line whose
`slug=` value differs from the file name is not malformed; it is a mismatch,
the only case that the skill corrects. The list command tests the prefix
only, so it can print a file whose line 1 has the active prefix and is
malformed; `update` and `close` then stop on that file.

**The check command.** `update` and `close` test the chosen file with this
exact command, which the skill text holds; the model does not judge line 1 by
reading it, because the Read tool shows neither a carriage return nor a
symbolic link. `<slug>` is the only placeholder:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
F="$ROOT/docs/worklogs/<slug>.md"
S='[a-z0-9]+(-[a-z0-9]+)*'; D='[0-9]{4}-[0-9]{2}-[0-9]{2}'
if [ -L "$F" ]; then echo symlink
elif [ ! -f "$F" ]; then echo "missing (searched $ROOT/docs/worklogs)"
else
  L="$(head -n 1 "$F" | tr -d '\r')"; BOM="$(printf '\357\273\277')"; L="${L#"$BOM"}"
  if printf '%s\n' "$L" | grep -Eq "^<!-- Work log: status=active slug=$S created=$D -->$"; then echo active
  elif printf '%s\n' "$L" | grep -Eq "^<!-- Work log: status=closed slug=$S created=$D closed=$D -->$"; then echo closed
  else echo malformed; grep -n '<!-- Work log: status=' "$F" || true; fi
fi
```

It prints one word: `symlink`, `missing` (followed by the folder that it
searched, which shows a wrong working folder in a project without git),
`active`, `closed` or `malformed`. A carriage return and a byte order mark are
removed for the comparison only.
After `malformed` it prints each status line of the file with its line
number, so a valid line in a wrong position is visible. The carriage return
is removed for the comparison only; the file is never rewritten by this
command. Replayed on 2026-09-21 in `bash` and `zsh` on the fixture of the list
command: each of the five words appeared for its case, and a status line on
line 3 was printed as `3:<!-- Work log: …`.

### The document describes itself

A skill is in context only after it is invoked. Therefore the update rules are
part of every work log, in its header. Any session that reads the document with
the Read tool knows how to maintain it. The template below is the normative
text; the skill copies it and fills only the `<...>` placeholders.

### Template

````markdown
<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->

# Work log: <title>

**Goal:** <one or two sentences>

**Done when:** <one checkable condition for the whole work>

**Admission rule:** <the rule that decides which findings become an open item>

## How to maintain this document

Update this document without being asked, at these moments:

1. A part changes status: update its row in `## Parts`. The `Commit` cell is
   filled once, for a `done` part only: when a `done` part has an empty
   `Commit` cell and the commit that holds its last changes now exists, fill
   the cell.
2. A part is added, split or dropped: a new part gets a new row with the next
   number; part numbers are never reused. A dropped part keeps its row with
   the status `dropped`, and gets a `## Decisions` entry.
3. A problem is found and not fixed at once: apply the admission rule. If the
   problem passes, add a row to `## Open items` with the number of the line
   `Next item number`, then increase that line by one. Read the file again
   first: the number must be one that no row and no `item #<n>` text uses.
   After a merge that brought two items with one number, renumber one of them
   and set the line to one plus the highest number. If the problem does not
   pass, add one line to `## Accepted limits`.
4. An open item leaves the table: delete its row. This happens when its fix is
   committed (in a project without git: when the fix is finished and
   verified). It also happens when the user decides not to fix it, or when it
   proves wrong or a duplicate; then add one line to `## Accepted limits` in
   the form `- <YYYY-MM-DD> item #<n>: <item text> — <reason>`, so that the
   problem stays readable after its row is gone.
5. A decision is made: append an entry to `## Decisions`. Never rewrite an
   older entry; add a line that starts with `**Follow-up**` below it instead.
6. A convention appears that also applies to later parts: add it to
   `## Rules for the next parts`, and name the part that produced it.
7. Every part is `done` or `dropped` and `## Open items` has no row: ask the
   user whether to close this work log. To close it, change `status=active` on
   line 1 to `status=closed` and add ` closed=<YYYY-MM-DD>` before ` -->`.

Before starting a part, read `## Rules for the next parts` and apply every
rule. Do not commit this document on your own; it goes into the next commit
that the user requests. Keep this document on the branch where the work
happens: a session on a branch that does not hold this file cannot see it.
Some tools stop on an uncommitted file, for example an orchestrated run or a
whole-branch review of the superpowers-orchestrator plugin. Before the user
starts one, ask the user to commit this document. While such a run is in
progress, do not write this document: note the changes, and make the update
after the run ends.

## Parts

| # | Part | Status | Since | Commit | Note |
|---|------|--------|-------|--------|------|
| 1 | <part name> | not started | | | |

Status is one of: `not started`, `in progress`, `done`, `dropped`. A part that
an open item blocks keeps its status, and its `Note` names the item number.
`Since` is the date of the last status change. `Commit` stays empty until the
part is `done`. Then it gets, once, the short hash of the newest commit that
holds changes of the part. It is filled by the first update after that commit
exists, so it reaches git one commit later. When a
session cannot tell which commit that is, it asks the user and leaves the cell
empty until the answer. The hash is valid on the work branch; after a squash
merge or a rebase it no longer exists, and nobody has to correct it.

## Rules for the next parts

1. <rule> (from part <n>, <YYYY-MM-DD>)

## Open items

| # | Item | Part | Found | Blocks |
|---|------|------|-------|--------|

Next item number: 1

`Part` is the number of the part in which the item was found. `Found` is the
date `<YYYY-MM-DD>` on which it was found. `Blocks` names what the item
blocks: a part number, or `whole work`.

## Accepted limits

- <YYYY-MM-DD> <finding, one line, with the reason it gets no row>

## Decisions

### <YYYY-MM-DD> <short title>

**Decision:** <what was decided>
**Reason:** <why>
**Rejected:** <the options not chosen, each with its reason>
````

The example row in `## Parts`, the example rule, the example limit and the
example decision are placeholders. The skill replaces the `## Parts` row with
the real parts and removes the three other examples, leaving the headings. No
line of a work log other than line 1 may start with `<!-- Work log: status=`.

### Default admission rule

When the user gives no rule of their own, the skill writes this one:

> A finding becomes an open item only when it blocks a part from reaching the
> status `done`, or blocks the "done when" condition of the whole work, or when
> its consequence is lost user work or a wrong commit. Every other finding gets one line under `## Accepted limits`.

### Commands

**Skill file contract.** The frontmatter of `skills/worklog/SKILL.md` does
**not** carry `disable-model-invocation: true` (the effect of this key is
taken from its name and from the Claude Code skills documentation, not
replayed here — unverified; `handoff` and `pickup` carry it; `worklog` must not, because the model has to load the skill for "Updates
outside the commands", and `tests/skill-triggering` passes only when the model
itself calls the Skill tool). It carries
`argument-hint: "[new|update|close] [<slug>]"`, and the body holds the line
`Argument given by the user (may be empty): $ARGUMENTS`. When the argument is
empty and the user's own message starts with the command (see "A load by the
model"), the skill reads
the command word and the slug from that message (on Copilot CLI the argument
may not arrive, as `skills/pickup/SKILL.md` records), and only then falls
back to `update`.
`<skill-dir>` below is this skill's base directory, the convention of
`skills/pickup/SKILL.md`; a path under `skills/` exists only inside this
repository, never in a user's project.

**Grammar.** `/worklog [new|update|close] [<slug>]`. The first word is always
read as a command word, never as a slug. When the user types `/worklog` with
no first word, the command is `update`. Any other first word, and a command
word given as a slug, stops with the usage text (the grammar line and one line
per command) and writes nothing. Every command that gets a slug
validates it against the slug rule first and, on a mismatch, stops and says
which rule the slug breaks.

**A load by the model.** The test is this sentence, which the skill text
holds: "The fallback to `update` applies only when the user's own message
starts with the command, written `/worklog` or
`/superpowers-orchestrator:worklog`." A message that only mentions the command
(for example "what does /worklog close do?") does not start with it and is not
an invocation. When the test fails, the model loaded the skill itself. If the
user then asked for no command, the skill runs no command and no full update,
and says so in one line: the model reads the named work log with the Read tool
and follows its maintenance section. When the user asked for a command in
plain words ("close the work log"), the model passes that command word.
Whether the model sees the namespaced form as typed is a property of the agent
runtime and was not probed here (unverified); the sentence is correct under
both outcomes.

**Choosing a work log.** `update` and `close` share one rule. With a slug: the
file `docs/worklogs/<slug>.md` must exist; if it does not, stop, list the
slug of every file under `docs/worklogs/` with its status, and write nothing.
With no slug: run the list command; one active work log is used; with
several, ask which one; with none, say so and offer `/worklog new`.

Then both commands run the check command on the chosen file and act on its
word, in this order. Each stop writes nothing:

1. `symlink`: stop; say that a work log must be a regular file.
2. `missing`: stop; show the listing described below.
3. `malformed`: stop; show the two valid forms. When the command printed a
   status line with a line number other than 1, say that its position is wrong
   and that it belongs on line 1.
4. `closed`: stop; say that the work log is closed. A closed work log is never
   written: a `slug=` mismatch in it is reported only.
5. `active`: when the `slug=` field differs from the file name, report the
   mismatch and correct the field. Then the command continues.

The repair of a missing heading or of a missing `Next item number` line (see
"Error handling") runs in `update` only, after these checks.

**The listing** covers the regular `*.md` files directly under
`docs/worklogs/`, one line per file, with one of these labels: `active`,
`closed`, `malformed line 1`, or `invalid file name — rename it` for a name
that breaks the slug rule. A file with such a name is never chosen: the list
command does not print it, and a slug argument cannot name it.

**`/worklog new [<slug>]`** — create a work log.

1. If `docs/worklogs/<slug>.md` exists, stop. Never overwrite a work log. With
   no slug given, the slug is asked in the question batch of step 2, then
   validated and checked the same way.
2. Ask the user, in one question batch: the title, the goal, the "done when"
   condition, the list of parts, and the admission rule (offer the default
   first). Values that the user already stated in the session are used and
   echoed, not asked again.
3. In a project that is not a git repository, and also when
   `git rev-parse --show-prefix` prints a text that is not empty (the current
   working folder stands below the root; for example a project folder below a
   repository that starts far above it), show the full target
   path and ask the user to confirm it before writing. Then read
   `<skill-dir>/template.md` with the Read tool, fill the placeholders,
   and write the file. Every part starts as `not started`, except a part the
   user says is in progress or done: such a part gets today's date in `Since`
   and an empty `Commit` cell. For a part that is already `done`, ask the user
   for its commit in the question batch; without an answer the cell stays
   empty (the `git log` window of the full update starts at the creation
   date, so it cannot find an older commit).
4. In a git repository, run `git check-ignore -q docs/worklogs/<slug>.md` from
   the root. Exit 0 means that an ignore rule matches the path (manual page
   `git-check-ignore`, section "EXIT STATUS": 0 matched, 1 not matched, 128
   error): tell the user that git ignores the file, so a normal `git add` does
   not add it. On any other exit, say nothing. The file is new and therefore
   not tracked, so the known limit of this command (it reports nothing for a
   tracked file) does not apply here.
5. Report the path. Say that the file is not committed, and that the
   session-start notice names it from the next session start on.

**`/worklog`** or **`/worklog update [<slug>]`** — full update.

1. Choose the work log and run the ordered checks of the rule above.
2. Read the work log with the Read tool.
3. Compare the document with the session: the status of each part, problems
   found, fixes committed, decisions made, conventions that appeared, and
   empty `Commit` cells of `done` parts. In a git repository, read the
   commits with
   `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD`,
   where `<created>` is the `created=` date of line 1. The window always
   starts at the creation of the work log: the full update is the repair for
   sessions that forgot an update, and a forgotten change can be as old as the
   work log (an earlier rule that started at the newest status change, and a
   second one that started at the oldest open question, both hid such
   commits). `-n 200` keeps the newest 200 commits, so the cap cuts the oldest
   ones. When the command prints 200 commits and a question is still open (an
   empty `Commit` cell of a `done` part, or an open item whose fix was not
   found), read the next window with `--skip=200`, at most five windows in
   all, and then say that older commits were not read. The cap exists because
   the Bash tool cuts a long output. `%cd` is the committer date (manual page `git-log`, "PRETTY
   FORMATS"); that `--since` filters on this date is not replayed here —
   unverified.
   The time is local time. The
   `00:00` is required: with a bare date, git starts at the current time of
   day of that date (replayed on 2026-09-21 at 15:01: the bare date listed 0
   commits of that day, the form with `00:00` listed 19;
   `skills/pickup/scripts/pickup-scan.js` records the same fact).
4. Apply the update rules of the document. Report each change in one line, or
   say that the work log was already up to date.

**`/worklog close [<slug>]`** — close a work log.

1. Choose the work log and run the ordered checks of the rule above (a closed
   work log stops there).
2. If a part is neither `done` nor `dropped`, or `## Open items` has rows, list
   them and ask the user: close anyway, or stop. On "close anyway": each
   remaining open item becomes one line under `## Accepted limits` in the form
   `- <today> item #<n>: <item text> — open at closing`, and its row is
   deleted; the parts
   keep their status; and one `## Decisions` entry records that the user
   closed the work log with those parts unfinished.
3. Fill every empty `Commit` cell of a `done` part that can be filled now (the
   read of full update step 3), and report the cells that stay empty: after
   closing, `update` no longer writes this file.
4. Change `status=active` on line 1 to `status=closed` and add
   ` closed=<today>` before ` -->`.

### Updates outside the commands

While a session works on a piece of work that has an active work log, the
model follows the document's own `## How to maintain this document` section.
The skill text says this in one verb-bearing step: "When the session-start
notice or the user names an active work log, read that work log with the Read tool before
starting the work, and follow its section `How to maintain this document`."

### Discovery through the session-start hook

`hooks/session-start` gains one notice. It runs in the project directory, as
the rest of the hook does:

1. Run the list command, unchanged: with its folder test, its `|| true` and
   its file-name filter. The hook adds no pipeline of its own; every added
   pipeline would need the same protection under `set -euo pipefail` (a `grep`
   that removes every line exits 1).
2. With no path left, add nothing to the hook output.
3. Remove the root prefix from each path with the shell expansion
   `${path#"$ROOT"/}` (no pipeline), and name the root once, as an absolute
   path. An absolute root is used because the model's idea of its working
   folder can move during a session (observed on 2026-09-21: the primary
   working directory of the reviewing session changed after a `cd`), and the
   hook runs again after `/clear` and after a compaction.
   Build one notice, with at most the first three paths. With one path and the
   root `/home/u/proj` the exact text is:

   ```
   <active-work-logs>Active work logs under /home/u/proj: docs/worklogs/a.md. Before you work on one of them, read it with the Read tool and follow its section "How to maintain this document". During an orchestrated run or a whole-branch review, do not write it.</active-work-logs>
   ```

   With five paths it is:

   ```
   <active-work-logs>Active work logs under /home/u/proj: docs/worklogs/a.md, docs/worklogs/b.md, docs/worklogs/c.md and 2 more under docs/worklogs/. Before you work on one of them, read it with the Read tool and follow its section "How to maintain this document". During an orchestrated run or a whole-branch review, do not write it.</active-work-logs>
   ```

   Paths are joined with `, `; the text ` and <n> more under docs/worklogs/`
   follows the third path; the full stop follows the last of these. The fixed
   text has 248 characters, each path has at most 57, the two separators have
   4, and the "more" text has at most 34 with a count below 1,000: at most 457
   characters plus the length of the root. A root longer than 300 characters
   is cut to its last 300 characters with `…` before them; the notice then
   cannot be used to open the file, and the user names the work log.
4. Append the notice, after two line breaks, to the `notices` part that the
   hook already writes for `hooks/session-start-assemble.js`. That part is
   always included, so the notice does not depend on the size of `state.md`.
   `session-start-assemble.js` is not changed. The notice takes its size from
   the room of the optional sections, and only in a project that has an active
   work log.

The hook runs on the events `startup`, `clear` and `compact`
(`hooks/hooks.json`), so the notice also returns after a compaction. The
Cursor wiring uses the same script. The Codex adapters under `hooks/codex/`
are not changed (Codex is no longer supported). A subagent never receives the
notice, because the hook does not run for subagents (measured in this
repository before 2026-09-21, and observed again by a reviewer subagent of
this spec on 2026-09-21: no hook text in its context); this is intended.

`skills/handoff/SKILL.md` is not changed: the session that follows a handoff
gets the notice from the hook.

### The `/pickup` scan

`skills/pickup/scripts/pickup-scan.js` classifies a handoff as `FRESH` only
when the working tree is clean, and it excludes the paths of the `NOT_WORK`
constant from that check. A work log is updated by the same sessions that
`/handoff` ends, so `docs/worklogs` is added to `NOT_WORK`, and the comment
above the constant is extended to say why. The constant covers the
uncommitted-change check only. A commit made after the handoff still gives
`CHECK`, also when it touches only `docs/worklogs/`; this is accepted, because
such a commit normally also holds the work of the part.

## Interfaces and contracts

| Contract | Owner | Reader |
|---|---|---|
| Path `docs/worklogs/<slug>.md` under the root; the file name is the slug | `worklog` skill | `hooks/session-start`, `pickup-scan.js`, the user |
| Status line on line 1 of the file, one of the two valid forms; one trailing carriage return is ignored | `worklog` skill | the list command (prefix only), `update`, `close` |
| Former item in `## Accepted limits`: `- <date> item #<n>: <item text> — <reason>` | the document's rule 4, `close` | the rebuild of `Next item number` |
| Section headings of the template, exact text and order | `skills/worklog/template.md` | the document's own rules, the tests |
| Line `Next item number: <n>` directly under the `## Open items` table | the document's rule 3 | every session that adds an open item |
| Notice `<active-work-logs>…</active-work-logs>` in the session-start output | `hooks/session-start` | every new, cleared or compacted session |

`hooks/skill-rules.json` gains one entry. This list is complete:

- `skill`: `worklog`; `type`: `workflow`; `priority`: `high`.
- `keywords`: `work log`, `worklog`. `tracking document` is not a keyword: a
  keyword alone scores 1 and can never reach the threshold of 2. The plural
  `work logs` is not a keyword: `hooks/skill-activator.js` matches a keyword
  with a space as a plain substring, so "network logs" would hit `work log`
  and `work logs`, score 2, and reach the suggestion threshold.
- `intentPatterns`:
  `(create|start|open|new)\\s+(a\\s+|the\\s+)?work\\s?logs?\\b` and
  `(update|close|continue)\\s+(the\\s+|my\\s+)?work\\s?logs?\\b`
  (written here as they stand in the JSON file, with doubled backslashes).
  The `\\b` keeps out "close work logging" and "open the worklog_table".
  An earlier third pattern for "keep track of the work" is removed: one intent
  pattern alone scores 2, it matched "keep track of the worker threads" and
  "keep track of my workouts", and with the early position of the rule such a
  false hit pushed `brainstorming` out of the list of 3 (replayed by a
  reviewer against `matchSkills`).

No keyword contains "save state" or "handoff", which route to other skills.
`hooks/skill-activator.js` suggests a skill only from a score of 2, and with
equal priority and equal score it keeps the order of the rules, so
`brainstorming` can stand before `worklog` for a prompt that starts with
"create". The function returns at most 3 skills (`matches.slice(0, 3)`), and a
rule at the end of the file loses every tie, so the `worklog` rule is placed
before the rules `brainstorming`, `refactoring` and `writing-plans` in the
JSON file. A suggestion list that contains `worklog` is the contract; its
position is not. The plan replays every prompt that the tests use against
`matchSkills` before it fixes the entry.

The Routing Guide of `skills/using-superpowers/SKILL.md` gains one line that
routes a request to create, update or close a work log to `worklog`. The guide
stands below the `session-start-injection-ends` marker, so the line does not
count against the 6,400 characters of the injected part; the plan verifies
this with `tests/codex/test-session-start-budget.sh`.

## Error handling

- Slug invalid (any command), or file exists at `new`: stop with a plain
  message; write nothing.
- Unknown first word, or a command word given as a slug: stop with the usage
  text; write nothing.
- A file under `docs/worklogs/` whose name breaks the slug rule (for example a
  hand copy named `Test_Refactor.md`): the list command and the hook never
  name it, and no slug argument can reach it. The slug listing marks it as
  `invalid file name — rename it`.
- File of a given slug not found at `update` or `close`: stop, list every slug
  with its status; write nothing.
- No active work log at `update` or `close` without a slug: say so; write
  nothing.
- `update` on a closed work log: stop and say it is closed. `close` on a
  closed work log: say so. Both write nothing.
- Line 1 ends with a carriage return (a checkout with `core.autocrlf=true`;
  that the Git for Windows installer proposes this value is unverified): the carriage return is removed
  before line 1 is compared with the valid forms, and it is kept when the line
  is rewritten.
- Line 1 malformed (see "Valid forms of line 1") in a file under
  `docs/worklogs/`: `update` and `close` on that file stop and show the two
  valid forms; they write nothing. The list command prints such a file only
  when line 1 still has the active prefix. When a valid status line stands on
  another line, the message names the wrong position.
- The path of a work log is a symbolic link: `update` and `close` stop and say
  that a work log must be a regular file; the list command never lists it.
- `slug=` field differs from the file name: the file name wins; `update` and
  `close` report the mismatch and correct the field.
- A section heading, or the line `Next item number`, is missing in an existing
  work log (the user edited it): the skill adds it at its template position and
  reports it. A missing number line is rebuilt as one plus the highest of:
  the first column of the `## Open items` rows, and every `item #<n>` in the
  document. With none of these, it is 1. The result is a lower bound, because
  an item whose fix was committed leaves no number; the skill says so and asks
  the user to confirm the value. The skill never reorders or deletes user
  text.
- Not a git repository: the `git log` read and the `git check-ignore` check
  are skipped, and the `Commit` column stays empty. The root is then the
  folder of the shell at the moment of the command, so `new` always shows the
  full target path and asks (step 3), and `missing` prints the folder that was
  searched.

## Failure modes considered

- **The model forgets to update in a long session (Minor).** Accepted limit;
  `/worklog` forces a full update, and the session-start notice names the
  document again at the next session start, after `/clear` and after a
  compaction. Whether it appears after `claude --resume` is unverified: the
  matcher in `hooks/hooks.json` is `startup|clear|compact`.
- **The document grows without bound (Minor).** Rows are deleted when fixed;
  the work log is closed when the work is done; no cap now.
- **The notice is absent (Minor).** The plugin may be old or absent on another
  computer, the platform may run no session-start hook, or on Windows a `find`
  that is not the Git Bash program may run (the hook then continues with no
  notice). The
  self-describing header covers this: the user opens the session with
  "continue the work log `docs/worklogs/<slug>.md`", and the document's own
  rules do the rest.
- **The notice takes room from the optional sections (Minor).** About 300 to
  457 characters plus the length of the root, only while a work log is active. A `state.md` that fitted
  with less room than that to spare is then left out and named in the
  `<not-injected>` line.
- **The folder `docs/worklogs` itself is a symbolic link (Minor, accepted
  limit).** `find` does not follow a start path that is a link, so the list
  command and the hook print nothing, while the check command still reads a
  file through the link. The guide says that the folder must be a real folder.
- **Other skills stop on the uncommitted work log (Minor, accepted limit).**
  An active work log is often modified and not committed. `/pickup` is covered
  by `NOT_WORK`. `orchestrating-development` (its clean-tree checks) and
  `multi-code-review` (its working-tree precondition) stop on any file that
  they do not know. They are not changed. The orchestrator is a main session,
  so it gets the hook notice too, also after each compaction. Two rules keep
  it from making the tree dirty in the middle of a run: the template tells
  the session to ask the user for a commit before such a run, and both the
  template and the notice say that the work log is not written while the run
  is in progress. The guide says the same.
- **The content of a work log is trusted like the project's `CLAUDE.md`
  (Minor).** The file-name filter protects the hook notice only. The notice
  tells the model to follow a section of the file, and whoever can add the
  file controls that section. In a repository from an untrusted source this
  is the same exposure as that repository's `CLAUDE.md`.
- **The work log lives on another branch (Minor).** A session on a branch
  without the file gets no notice and cannot update it. The template tells
  the reader to keep the document on the branch where the work happens.
- **A second git worktree (Minor, accepted limit).** A worktree is a second
  working folder of the same repository. An uncommitted work log is absent
  there, and a committed one is an older copy; two edited copies meet in a
  merge. Advice in the guide: commit the work log before creating a worktree.
## Testing strategy

Tests check behaviour through public interfaces: the output of the list
command and of the check command, the output of the hook, the output of the
scan script, and the routing. The three commands are Markdown text that a
model executes; no fast test runs them. Their rules are held by pinned
phrases in the skill text and by `tests/skill-triggering`; this is an accepted
limit of a skill that has no script.

- New fast suite `tests/worklog/run-tests.sh` (bash, loads
  `tests/lib/undefined-command-guard.sh`, as `tests/suite-guard` requires):
  - the template holds a line 1 that matches the active form with
    placeholders, the six `## ` headings in order, exactly seven lines that
    match `^[1-7]\. ` between `## How to maintain this document` and
    `## Parts`, the line `Next item number: 1`, the four status values, and
    the phrase `item #<n>`;
  - the list command, copied from the skill text and run on fixture folders:
    lists an active work log; does not list a closed one; does not list a
    closed one that quotes the active status line on a later line; does not
    list a file whose line 1 is `<!-- Work log: status=open slug=c
    created=2026-09-21 -->`; does not list a file whose valid active status
    line stands on line 3 under the heading; does not list a symbolic link;
    prints two active files in sorted order; prints an empty line and exits 0,
    as a script under `set -euo pipefail`, when
    `docs/worklogs` is absent; gives the same output when run from a
    sub-folder of a fixture repository; gives the same output when run by
    `zsh`, when `zsh` is installed;
  - the two valid forms of line 1, copied from the skill text as regular
    expressions: each accepts its example line; both refuse a line without
    `created=`, a closed line without `closed=`, and a date such as
    `2026-9-1`;
  - the two symbolic-link assertions (list command, check command) run only
    when `[ -L "$fixture" ]` is true after `ln -s`; otherwise the suite prints
    a note and skips them (on Windows Git Bash `ln -s` makes a copy by
    default — MSYS2 documentation, not replayed here, unverified);
  - the check command, copied from the skill text and run on fixture files,
    prints `active`, `closed`, `malformed`, `symlink` and `missing` for its
    five cases, prints `active` for a line 1 with a carriage return, and
    prints `3:` before a status line that stands on line 3;
  - the skill text holds these pinned phrases: the sentence that starts `The fallback
    to update applies only when the user's own message starts with the
    command` (with its code marks); `do not write this document` in the
    template; `A closed work log is never written`;
    `stops with the usage text`; `close anyway`; `invalid file name — rename
    it`; `with the Read tool` in the step
    that names `<skill-dir>/template.md`; the `$ARGUMENTS` line; no
    `disable-model-invocation` in the frontmatter; `Never overwrite a work log`; `never commits`;
    the grammar line; the exact `git log --since="<date>
    00:00"` form;
  - a fixture work log whose line 1 ends with a carriage return is listed, and
    the two valid forms accept its line 1 after the carriage return is removed.
- `tests/codex/`, a new test file for `hooks/session-start` on fixture
  projects. `tests/codex/run-unit-tests.sh` does not discover files: the new
  file is registered there with one `run_test` line (third argument `bash`
  for a shell test), or it would never run while the suite stays green. Its
  cases:
  - with no `docs/worklogs` folder the hook exits 0, its output holds no
    `<active-work-logs>` text, and the output is identical to the output of
    the same fixture with a `docs/worklogs` folder that holds only a closed
    work log (this pins the `set -euo pipefail` case, with a baseline that the
    test can produce);
  - with one active work log the output holds the exact one-path notice text
    of this spec; a closed work log is not named;
  - with only a file named `x y.md`, `A.md` or `new.md` that has an active
    line 1, the hook exits 0 and its output is identical to the output of the
    same fixture without that file (an assertion "is not named" alone would
    pass on a hook that ended early); a slug of 41 characters is not named;
  - with five active work logs the output holds the exact five-path notice
    text of this spec, with the fixture's root in place of `/home/u/proj`;
    with the hook started in a folder one level below the fixture's root, the
    notice is identical;
  - an unreadable work log between two readable active ones: both readable
    ones are named; a work log with a byte order mark is named;
  - with three active work logs whose slugs have 40 characters, the whole
    output stays at or under 10,000 characters
    (`tests/codex/test-session-start-budget.sh` is extended for this check).
- `tests/pickup/run-tests.sh`: on a fixture repository with a `FRESH` handoff,
  an uncommitted change under `docs/worklogs/` keeps `FRESH`; an uncommitted
  change elsewhere under `docs/` still gives `CHECK`.
- `tests/skill-triggering/`: a prompt file `prompts/worklog.txt`, and the entry
  `worklog` in the `SKILLS` array of `run-all.sh` (the suite runs only the
  skills that the array names, and it skips a missing prompt file without
  failing). `.gitignore` line 18 (`*.txt`) matches the new file (checked with
  `git check-ignore -v`), so it is added with `git add -f`, as the nine
  existing prompt files were, and the plan verifies it with `git ls-files`.
- `tests/codex/test-skill-activator.js`: for "update the work log of the test
  refactoring" and for "create a work log for the test refactoring", the
  suggestion list contains `worklog`; for "check the network logs", "read the
  framework logs", "keep track of the worker threads" and "close work logging
  when the app shuts down" it does not; and for "add a feature to keep track
  of the worker threads, write a plan and refactor the pool module" the list
  still holds `brainstorming`.

## Rollout

- `CLAUDE.md` Testing block: one line for `tests/worklog/run-tests.sh`.
- `docs/guide/README.md`: one row in the table of memory files, and a short
  section on the three commands, the branch advice and the worktree advice.
- The places that list the skills: `README.md` (the skill list near line
  337, and the three counts "30 skills" at lines 68, 220 and 330, which become
  31), `docs/guide/README.md`, and the Routing Guide of
  `skills/using-superpowers/SKILL.md`. `plugin.universal.yaml` lists no skill
  by name and gets the version change only. `docs/FORK-IMPROVEMENTS.md` and
  `docs/REVIEW-PROCESS-COMPARISON.md` are historical documents and are not
  updated.
- Hook wiring is not changed (no new event, no new script), so
  `hooks/hooks.json`, `hooks/hooks-cursor.json` and `plugin.universal.yaml`
  need no hook edit.
- Release v7.52.0 by the release checklist of `CLAUDE.md`. Nothing to migrate.
- The template is plain Markdown. Before the release is installed elsewhere,
  the user can copy `skills/worklog/template.md` by hand into another project
  as `docs/worklogs/<slug>.md` and fill it in; the `slug=` field must repeat
  the file name.
