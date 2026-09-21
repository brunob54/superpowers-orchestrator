---
name: worklog
description: >
  Creates and maintains a work log: one Markdown document per piece of
  multi-part work that lasts many sessions, at docs/worklogs/<slug>.md, with
  its own update rules. /worklog new [<slug>] creates one; /worklog or
  /worklog update [<slug>] runs a full update; /worklog close [<slug>] closes
  one. Triggers on: "work log", "worklog", "create a work log", "start a work
  log", "update the work log", "close the work log", "continue the work log".
argument-hint: "[new|update|close] [<slug>]"
---

# Work log

A work log is one Markdown document per piece of work that has several parts
and lasts many sessions, for example four groups of tests that are refactored
one group after the other. It lives at `docs/worklogs/<slug>.md` under the
root, and git tracks it. It carries its own update rules in its section
`How to maintain this document`, so a session can maintain it without this
skill. This skill creates a work log, runs a full update, and closes it. This
skill never commits: the work log goes into the next commit that the user
requests.

Argument given by the user (may be empty): $ARGUMENTS

## Terms

- **Slug rule**: a slug matches `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase ASCII
  letters, digits, single hyphens), has at most 40 characters, and is none of
  the three command words `new`, `update` and `close`. The file name is the
  authority for the slug; the `slug=` field of line 1 repeats it for a human
  reader.
- **Root**: the output of `git rev-parse --show-toplevel`; in a project that is
  not a git repository, the folder of the shell at the moment of the command.
  Every `docs/worklogs/` path in this skill is relative to the root.
- **Active**: a work log whose line 1 starts with
  `<!-- Work log: status=active `.
- **Today**: the output of `date +%F`, run with the Bash tool.
- **`<skill-dir>`**: this skill's base directory. A path under `skills/`
  exists only inside the plugin's own repository, never in a user's project.

## Commands and arguments

Grammar: `/worklog [new|update|close] [<slug>]`

The first word is always read as a command word, never as a slug. When the
user types `/worklog` with no first word, the command is `update`; the test
at the end of this section decides whether the user typed the command. Any
other first word, and a command word
given as a slug (for example `/worklog new close`), stops with the usage text and writes nothing. More than one word after the command word also stops with the usage text and writes nothing. The usage text is the grammar line and one line per command:

```text
/worklog [new|update|close] [<slug>]
/worklog new [<slug>]       create a work log
/worklog update [<slug>]    full update; /worklog alone does the same
/worklog close [<slug>]     close a work log
```

Every command that gets a slug first tests it by "The slug command" below. A
result other than `valid` stops the command: say which rule the slug breaks,
and write nothing. A command word given as a slug in the argument has already
stopped with the usage text, before this test.

When the argument above is empty and the user's own message starts with the
command, read the command word and the slug from that message (on Copilot CLI,
the command-line interface of GitHub Copilot, the argument may not arrive);
only then fall back to `update`.
The fallback to `update` applies only when the user's own message starts with the command, written `/worklog` or `/superpowers-orchestrator:worklog`.
The message also counts as starting with the command when it holds a
`<command-name>` tag that names `/worklog` or
`/superpowers-orchestrator:worklog`, which is how Claude Code delivers a
typed slash command.
A message that only mentions the command (for example "what does /worklog
close do?") does not start with it and is not an invocation. When this test
fails, the model loaded this skill by itself:

- If the user asked for no command, run no command and no full update, and say
  so in one line. Read the named work log with the Read tool and follow its
  section `How to maintain this document`.
- If the user asked for a command in plain words ("close the work log"), run
  that command.

## Shell commands

Run these commands with the Bash tool. Replace only the placeholders that a
command names, and copy everything else unchanged. Never put a slug into a
command before it passes this first test: every character is a lowercase
letter `a` to `z`, a digit or a hyphen. A slug with any other character
breaks the pattern: stop, say so, and write nothing.

### The slug command

Placeholder: `<slug>`. It prints `valid`, or the rule that the slug breaks.

```bash
s='<slug>'
if ! printf '%s\n' "$s" | LC_ALL=C grep -Eqx '[a-z0-9]+(-[a-z0-9]+)*'; then echo 'breaks the pattern ^[a-z0-9]+(-[a-z0-9]+)*$'
elif [ "${#s}" -gt 40 ]; then echo 'has more than 40 characters'
else case "$s" in new|update|close) echo 'is a command word';; *) echo valid;; esac; fi
```

### The list command

It prints the path of every active work log, one per line, in the same order
in every locale, or one empty line when there is none. It reads line 1 only,
and it prints a file only when its name is a valid slug plus `.md`. The
folder test and the `|| true` keep it safe under `set -euo pipefail`; every
copy of this command keeps both. The awk program writes the whole line as
`$(0)`: Claude Code replaces a `$` directly followed by a digit in this file
with an argument of the command, so no line of this file holds one.

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

### The listing command

It prints one line per regular `*.md` file directly under `docs/worklogs`, in
the same order in every locale, and nothing when there is none. For a file
whose name is a valid slug plus `.md`, the line is that slug. For any other
file, the line is the file name, with each character other than `a` to `z`, a
digit, `.` and `-` replaced by `?`, followed by
`: invalid file name — rename it`. It tests each name inside awk, as the list
command does, so a file name reaches no command before it passes the slug
rule. It never reads a file. The folder test and the `|| true` keep it safe
under `set -euo pipefail`.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [ -d "$ROOT/docs/worklogs" ]; then
  LC_ALL=C find "$ROOT/docs/worklogs" -maxdepth 1 -type f -name '*.md' -exec awk 'BEGIN { n = ARGV[1]; sub(/.*\//, "", n)
    if (n ~ /^[a-z0-9]+(-[a-z0-9]+)*\.md$/ && length(n) <= 43 &&
        n != "new.md" && n != "update.md" && n != "close.md") print substr(n, 1, length(n) - 3)
    else { gsub(/[^a-z0-9.-]/, "?", n); print n ": invalid file name — rename it" } }' {} \; 2>/dev/null | LC_ALL=C sort || true
fi
```

### The check command

Placeholder: `<slug>`. It prints one word: `symlink`, `missing` (followed by
the folder that it searched), `active`, `closed` or `malformed`. After
`malformed` it prints each status line of the file with its line number. It
removes a carriage return and a byte order mark for the comparison only, and
it never changes the file. Never judge line 1 by reading it: the Read tool
shows neither a carriage return nor a symbolic link.

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

### Valid forms of line 1

- active: `^<!-- Work log: status=active slug=[a-z0-9]+(-[a-z0-9]+)* created=[0-9]{4}-[0-9]{2}-[0-9]{2} -->$`
- closed: `^<!-- Work log: status=closed slug=[a-z0-9]+(-[a-z0-9]+)* created=[0-9]{4}-[0-9]{2}-[0-9]{2} closed=[0-9]{4}-[0-9]{2}-[0-9]{2} -->$`

A line 1 that matches neither form is malformed. A valid line whose `slug=`
value differs from the file name is not malformed: it is a mismatch, the only
case that this skill corrects. No line other than line 1 may start with
`<!-- Work log: status=`.

### The line-1 command

Placeholders: `<slug>`, and `<line>`, the new line 1 in one of the two valid
forms. It replaces line 1 only. It keeps a carriage return at the end of line
1 and a byte order mark at its start, and every other line stays as it was.
Change line 1 only with this command. It refuses a work log that is a
symbolic link: it prints `symlink` and changes nothing. It writes its
temporary copy outside the `docs/worklogs` folder and removes that copy once
the file is rewritten. If the rewrite itself fails, it keeps the temporary
copy and prints the copy's path on its last line, so the work log can be
restored from it. It prints nothing on success. Its exit status is 0 on
success and 1 on every failure. Its redirections are written `>|`, so they
also write when the shell option `noclobber` is set (that option refuses a
`>` redirection to a file that exists).

When the command prints nothing, run the check command again. When the
command prints anything, stop: show its output to the user (a printed path is
the kept copy of the work log, from which it can be restored) and write
nothing more.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
F="$ROOT/docs/worklogs/<slug>.md"
if [ -L "$F" ]; then echo symlink; false; else
  T="$(mktemp)"
  if LC_ALL=C awk -v new='<line>' 'NR == 1 { cr = /\r$/; bom = /^\357\273\277/; l = (bom ? "\357\273\277" : "") new (cr ? "\r" : ""); print l; next } { print }' "$F" >| "$T"; then
    if cat "$T" >| "$F"; then rm -f "$T"; else echo "$T"; false; fi
  else
    rm -f "$T"; false
  fi
fi
```

## Choosing a work log

`update` and `close` share this rule.

- With a slug: the file `docs/worklogs/<slug>.md` must exist. When the check
  command prints `missing`, stop, show the listing, and write nothing.
- With no slug: run the list command. With one path, use that work log. With
  several, ask the user which one. With none, say that no work log is active,
  offer `/worklog new`, and write nothing.

Then run the check command on the chosen file and act on its word, in this
order. Each stop writes nothing.

1. `symlink`: stop; say that a work log must be a regular file.
2. `missing`: stop; show the listing.
3. `malformed`: stop; show the two valid forms of line 1. When the command
   printed a line, other than line 1, whose text after the line number and
   its colon starts with `<!-- Work log: status=`, say that its position is
   wrong and that it belongs on line 1.
4. `closed`: stop; say that the work log is closed. A closed work log is never written: a `slug=` mismatch in it is reported only.
5. `active`: when the `slug=` field differs from the file name, report the
   mismatch and correct the field with the line-1 command. When the line-1
   command prints anything, stop, as "The line-1 command" says. Otherwise
   the command continues.

**The listing** has one line per regular `*.md` file directly under
`docs/worklogs/`. Get the files with the listing command only, never with
another command: a file name is text that anyone who can add a file controls.
A file whose name breaks the slug rule gets the label `invalid file name — rename it`,
and it is never chosen. For every other file, the listing command printed its
slug alone on a line: run the check command with that slug only, and use its
word as the label, with `malformed line 1` for `malformed`.

## `/worklog new [<slug>]` — create a work log

1. Test the slug with the slug command, then run the check command on it. A
   word other than `missing` stops the command. Never overwrite a work log.
   With no slug given, ask for the slug in the question batch of step 2, and
   test it the same way before step 3.
2. Ask the user, in one question batch: the title, the goal, the "done when"
   condition, the list of parts, and the admission rule. Offer the default
   admission rule first:

   > A finding becomes an open item only when it blocks a part from reaching the status `done`, or blocks the "done when" condition of the whole work, or when its consequence is lost user work or a wrong commit. Every other finding gets one line under `## Accepted limits`.

   When the user gives no rule of their own, write the default admission rule.
   Use and echo the values that the user already stated in this session; do
   not ask for them again. When the user says that a part is already `done`,
   ask for its commit in the same batch. Without an answer its `Commit` cell
   stays empty: the `git log` read of the full update starts at the creation
   date, so it cannot find an older commit.
3. In a project that is not a git repository, and also when
   `git rev-parse --show-prefix` prints a text that is not empty (the current
   folder stands below the root), show the full target path and ask the user
   to confirm it before writing.
4. Read `<skill-dir>/template.md` with the Read tool. Fill these placeholders
   only: `<slug>` and `<YYYY-MM-DD>` on line 1 (today), `<title>`, the goal,
   the "done when" condition and the admission rule. Replace the example row
   of `## Parts` with one row per part, numbered from 1. Remove the example
   rule, the example limit and the example decision, and keep the section
   headings `## Rules for the next parts`, `## Accepted limits` and
   `## Decisions`. The line `### <YYYY-MM-DD> <short title>` belongs to the
   example decision and is removed with it.
   Leave every other `<...>` text as it is: it belongs to the document's own
   rules. Every part starts as `not started`, except a part that the user
   says is `in progress` or `done`: such a part gets today in `Since`, and its
   `Commit` cell stays empty unless the user gave the commit of a `done` part.
   Create the folder `docs/worklogs/` under the root when it does not exist,
   and write the file.
5. In a git repository, run
   `git -C "$(git rev-parse --show-toplevel)" check-ignore -q docs/worklogs/<slug>.md`.
   Exit 0 means that an ignore rule matches the path: tell the
   user that git ignores the file, so a normal `git add` does not add it. On
   any other exit, say nothing.
6. Report the path. Say that the file is not committed, and that the
   session-start notice names it from the next session start on.

## `/worklog` or `/worklog update [<slug>]` — full update

1. Choose the work log and run the ordered checks of "Choosing a work log".
2. Read the work log with the Read tool, whole.
3. Repairs, in `update` only. When a section heading of the template, or the
   line `Next item number`, is missing (the user edited the document), add it
   at its template position and report it. Rebuild a missing number line as
   one plus the highest of: the first column of the `## Open items` rows, and
   every `item #<n>` in the document; with none of these, it is 1. The result
   is a lower bound, because an item whose fix was committed leaves no number:
   say so, and ask the user to confirm the value.
4. Compare the document with the session: the status of each part, problems
   found, fixes committed, decisions made, conventions that appeared, and
   empty `Commit` cells of `done` parts. In a git repository, read the commits
   with this command, where `<created>` is the `created=` date of line 1:
   `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD | cat`
   The window always starts at the creation of the work log, because a
   forgotten change can be as old as the work log. The `00:00` is required:
   with a bare date, git starts at the current time of day of that date. The
   `| cat` is required too: a Bash output hook of this plugin cuts the output
   of a plain `git log` command that is longer than 40 lines to its first 30
   lines, and it never cuts the output of a pipeline. When
   the command prints 200 commits and a question is still open (an empty
   `Commit` cell of a `done` part, or an open item whose fix was not found),
   read the next window with `--skip=200`, then `--skip=400`, at most five
   windows in all; then say that older commits were not read.
5. Apply the update rules of the document's section `How to maintain this
   document`. Report each change in one line, or say that the work log was
   already up to date.

## `/worklog close [<slug>]` — close a work log

1. Choose the work log and run the ordered checks of "Choosing a work log" (a
   closed work log stops there).
2. Read the work log with the Read tool, whole. If a part is neither `done`
   nor `dropped`, or `## Open items` has rows, list them and ask the user:
   close anyway, or stop. On "close anyway": each remaining open item becomes
   one line under `## Accepted limits` in the form
   `- <today> item #<n>: <item text> — open at closing`, and its row is
   deleted; the parts keep their status; and one `## Decisions` entry records
   that the user closed the work log with those parts unfinished.
3. Fill every empty `Commit` cell of a `done` part that can be filled now
   (the `git log` read of the full update, step 4), and report the cells that
   stay empty: after closing, `update` no longer writes this file.
4. Run the line-1 command with line 1 in the closed form: `status=closed`
   instead of `status=active`, and ` closed=<today>` before ` -->`. When the
   line-1 command prints anything, stop, as "The line-1 command" says.
   Otherwise run the check command; it must print `closed`. Any other word
   stops the command: show that word to the user.

## Updates outside the commands

When the session-start notice or the user names an active work log, read that work log with the Read tool before starting the work, and follow its section `How to maintain this document`.

## Rules

- This skill never commits. It never reopens a closed work log: the user edits
  line 1 back to the active form by hand.
- Every stop writes nothing more. A stop of the grammar, of the slug test or
  of the ordered checks comes before any write; a stop at step 2 of `close`
  keeps the `slug=` correction that check 5 already made.
- In a project that is not a git repository, skip the `git log` read and the
  `git check-ignore` test, and leave the `Commit` column empty. The root is
  then the folder of the shell, so `new` always shows the full target path and
  asks, and `missing` prints the folder that was searched.
- `docs/worklogs` must be a real folder: the list command does not follow a
  folder that is a symbolic link.
- Never reorder or delete user text, except the deletions that a step of this
  skill or a rule of the work log names (an open-item row that leaves the
  table).
