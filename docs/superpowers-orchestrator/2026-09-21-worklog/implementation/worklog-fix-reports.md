## Round 1

Findings addressed: M1, M2, M3, L1, L2, L3, L4, L8, L10, L13, L15.

Files changed: `skills/worklog/SKILL.md`, `tests/worklog/run-tests.sh`,
`hooks/session-start`.

Before the fix, the new suite cases failed as intended
(`bash tests/worklog/run-tests.sh`: 126 passed, 5 failed — the noclobber
case printed `cannot overwrite existing file` and left line 1 active; the
symbolic-link, kept-copy and awk-failure branches exited with status 0).
Mutation checks after the fix: replacing `echo "$T"; false` with
`rm -f "$T"; false` turns 2 checks red; deleting the `Grammar:` line turns 1
check red.

Hook output comparison (L15): the committed `hooks/session-start` and the
changed one were run on fixtures with 1, 3, 4 and 5 active work logs and on a
root longer than 300 characters; `cmp` found the outputs byte-identical.

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
Results: 131 passed, 0 failed
exit=0

$ bash tests/codex/test-session-start-worklog-notice.sh; echo "exit=$?"
...
  21 passed, 0 failed
exit=0

$ bash tests/codex/run-unit-tests.sh; echo "exit=$?"
...
 Results: 17 suites passed, 0 suites failed
 All unit tests passed.
exit=0
```

## Round 2

Findings addressed: I1, M2.

Files changed: `skills/worklog/SKILL.md`, `tests/worklog/run-tests.sh`.

I1: widened the test that decides whether the user's own message "starts
with the command" — added a new sentence right after the existing pinned
sentence in section "## Commands and arguments" of `skills/worklog/SKILL.md`
saying the message also counts as starting with the command when it holds a
`<command-name>` tag naming `/worklog` or
`/superpowers-orchestrator:worklog`, which is how Claude Code delivers a
typed slash command with no argument. The existing pinned sentence and the
"only mentions the command" negative-case sentence were left unchanged.
Added a matching pinned-phrase line to the `PHRASES` array of section 7 in
`tests/worklog/run-tests.sh` (`grep -F` against the skill file).

M2: added one sentence to the paragraph after the grammar line in
"## Commands and arguments" of `skills/worklog/SKILL.md`: "More than one
word after the command word also stops with the usage text and writes
nothing." This reuses the already-pinned phrase "stops with the usage text",
so no new test phrase was needed.

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
Results: 132 passed, 0 failed
exit=0
```

## Round 3

Findings addressed: M1.

Files changed: `skills/worklog/SKILL.md`, `tests/worklog/run-tests.sh`.

M1: added the subsection "### The listing command" to "## Shell commands" of
`skills/worklog/SKILL.md`, directly after the list command. It is one fixed
command with no placeholder: the folder test, `LC_ALL=C find ... -maxdepth 1
-type f -name '*.md' -exec awk`, the list command's name test inside awk
(pattern, length at most 43, not `new.md`/`update.md`/`close.md`),
`LC_ALL=C sort` and `|| true`. The awk program runs in `BEGIN` only, so it
never reads a file (an empty or unreadable file is still listed). A valid
name prints its slug; any other name prints the name with every character
outside `a-z0-9.-` replaced by `?`, followed by
`: invalid file name — rename it`. The paragraph "**The listing**" of
"## Choosing a work log" now gets the files with this command only, and runs
the check command only with a slug that the command printed alone on a line;
the raw `find` and the prose-only name test are gone. The check command and
the list command are unchanged; no line holds a `$` directly before a digit;
the pinned phrases stay on one line.

Suite: new section 3b of `tests/worklog/run-tests.sh` copies the command out
of the skill text and runs it under `set -euo pipefail` (bash, and zsh when
installed) on a fixture with `alpha.md`, `a-b.md`, a zero-byte `empty.md`,
`x'$(touch listing-marker)'.md`, `x y.md` and `new.md`, asserting the exact
sorted lines and exit 0, that no marker file exists anywhere under the
fixture root, and that a root with no docs/worklogs folder prints no line and
exits 0. Section 2 also checks that the skill text holds the command.

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
3b. The listing command
  PASS: valid names print their slug, other names a label with ? for unsafe characters, in C-locale order, exit 0
  PASS: the same listing when zsh runs it
  PASS: the hostile file name ran no command: no marker file exists
  PASS: listing, no docs/worklogs folder: no line and exit 0 under set -euo pipefail
...
Results: 137 passed, 0 failed
exit=0
```
