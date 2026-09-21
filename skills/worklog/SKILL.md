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
Change line 1 only with this command, then run the check command again. It
refuses a work log that is a symbolic link: it prints `symlink` and changes
nothing. It writes its temporary copy outside the `docs/worklogs` folder and
removes that copy once the file is rewritten. If the rewrite itself fails, it
keeps the temporary copy and prints one line, the copy's path, so the work
log can be restored from it. It prints nothing on success.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
F="$ROOT/docs/worklogs/<slug>.md"
if [ -L "$F" ]; then echo symlink; else
  T="$(mktemp)"
  if LC_ALL=C awk -v new='<line>' 'NR == 1 { cr = /\r$/; bom = /^\357\273\277/; l = (bom ? "\357\273\277" : "") new (cr ? "\r" : ""); print l; next } { print }' "$F" > "$T"; then
    if cat "$T" > "$F"; then rm -f "$T"; else echo "$T"; fi
  else
    rm -f "$T"
  fi
fi
```
