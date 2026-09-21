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

## Round 4

Findings addressed: I1, M1, M2, M3, M4, M5, M6, M10, M11.

Files changed: `skills/worklog/SKILL.md`, `tests/worklog/run-tests.sh`,
`tests/codex/test-session-start-worklog-notice.sh`,
`tests/pickup/run-tests.sh`.

I1: new fixture with a `docs/worklogs` folder of mode 000 (the folder test
passes, `find` fails). `tests/worklog/run-tests.sh` section 3 runs the list
command on it (one empty line, `exit=0`), section 3b the listing command
(`exit=0`), through the helper `locked_run`, which skips with a NOTE line when
the folder stays readable and restores mode 755. The notice test case 1 runs
the hook on the same folder with mode 000 (exit 0, output equal to the
no-folder output). `run_hook` now counts a hook that writes no JSON as a
failure instead of ending the test script, so this assertion reports. The
comment above `strict_script` and the case 1 comment now name the
unreadable-folder fixture as the only one that runs the pipeline to its
failure.

M1: `skills/worklog/SKILL.md` rewraps three sentences onto one line each,
meaning unchanged (the line-1 stop rule, "Get the files with the listing
command only, never with another command: ...", close step 4 "Any other word
stops the command: ..."). Section 7 pins five new phrases, one per rule.

M2: notice test case 7: three active work logs (exact notice, no " and "),
then four (exact notice with " and 1 more under docs/worklogs/").

M3: a folder `notgit` with no `git init` and one active work log: the list
command prints its path; the check command prints `active`, and
`missing (searched <folder>/docs/worklogs)` for a slug that does not exist.

M4: the noclobber run and cases (b), (d), (e) of the line-1 command moved into
the function `line1_cases`, called with bash in section 6 (labels unchanged)
and with zsh in section 6b (labels start with "zsh: ", slugs with "zsh-").
Section 6b also asserts `OUT` empty and `CODE` 0 for its success run.

M5: notice test case 8: project folder `with space [x]` with four active work
logs and a folder `with space x` that the pattern matches; exact notice.
Case 9: a root of exactly 300 characters (two folder names), printed whole.

M6: section 3b runs the listing command on the section 3 folder and asserts
the exact output, labels included; the line-break name is expected only when
the file system made it.

M10: case (e) asserts that the command prints something (`assert_not_empty`).

M11: `tests/pickup/run-tests.sh` section 6c: a fresh repository with a tracked
`docs/README.md`, then an untracked `docs/worklogs/w.md` (git reports
`?? docs/worklogs/`): `dirty: 0` and `status: FRESH`; after a commit of that
file dated after the handoff: `status: CHECK`. The helpers `worklog_file` and
`commit_file` (defined before use) replace the inline commit of the older
sub-case.

Mutation checks, each on a scratch copy of hooks/, skills/, tests/ and lib/
(the working tree was never changed): every mutation turned its new
assertion red.

- `|| true` removed from the list command of the skill: FAIL "an unreadable
  docs/worklogs folder: one empty line and exit 0 under set -euo pipefail".
- `|| true` removed from the listing command: FAIL "listing, an unreadable
  docs/worklogs folder: ..." (expected 'exit=0', got 'exit=1').
- `|| true` removed from the hook copy: FAIL "unreadable docs/worklogs folder:
  the hook exits 0 (expected '0', got '1')".
- Each of the five M1 rules deleted: FAIL "the skill text holds: <phrase>".
- Hook `-gt` to `-ge` for worklog_paths_max: FAIL "three active work logs".
- `|| pwd` removed from the list command / the check command: FAIL on the
  three "not a git repository" assertions.
- Line-1 command `>|` to `>`: FAIL "zsh: noclobber: the command exits
  quietly"; symbolic-link refusal removed: FAIL "zsh: a work log that is a
  symbolic link: ..."; `echo "$T"` removed: FAIL "zsh: a failed rewrite: the
  last line printed is the path of the copy"; `rm -f "$T"` removed after an
  awk failure: FAIL "zsh: awk fails: the temporary copy is removed".
- Hook `IFS="$nl"` removed, and `set -f` removed: FAIL "a root with a space
  and a glob character, four active work logs: the exact notice".
- Hook `-gt` to `-ge` for worklog_root_max: FAIL "a root of exactly 300
  characters: printed whole, with no …".
- Listing `length(n) <= 43` to `<= 44`: FAIL "listing of the section 3
  folder: the same file-name filter as the list command".
- `2>/dev/null` added to the awk of the line-1 command: FAIL "awk fails: the
  command prints something (got an empty text)".
- `docs/worklogs` removed from NOT_WORK of pickup-scan.js: FAIL "a new
  docs/worklogs folder, one untracked line for git, is not dirty"; an exclude
  of docs/worklogs added to the commits-self `git log`: FAIL "a commit after
  the handoff that touches only docs/worklogs makes CHECK".

Covering tests, after the fixes:

```
$ bash tests/worklog/run-tests.sh
...
Results: 166 passed, 0 failed
$ bash tests/codex/test-session-start-worklog-notice.sh
...
  28 passed, 0 failed
$ bash tests/pickup/run-tests.sh
...
Results: 205 passed, 0 failed
$ bash tests/codex/run-unit-tests.sh
...
 Results: 17 suites passed, 0 suites failed
 All unit tests passed.
$ bash tests/suite-guard/run-tests.sh
...
Results: 116 passed, 0 failed
```

## Round 4

Findings addressed: M1, M2, M3, M4, M5, M6, M7.

Files changed: `tests/worklog/run-tests.sh`, `tests/codex/test-skill-activator.js`,
`tests/pickup/run-tests.sh`, `tests/codex/test-session-start-budget.sh`,
`tests/codex/test-session-start-worklog-notice.sh`.

M1: `tests/worklog/run-tests.sh` section 4's three refused line-1 examples
were pulled into a named array `REFUSED_LINES`, reused by section 4's own
loop. Section 5 now writes each of those three lines, plus a valid active
line with extra text after `-->`, plus a line with an uppercase `slug=`
value, as line 1 of five new validly-named fixture files under `$MW`
(`malformed-no-created.md`, `malformed-no-closed.md`, `malformed-bad-date.md`,
`malformed-trailing.md`, `malformed-upper-slug.md`), and asserts that
`run_check` prints `malformed` as its first line for each — pinning the check
command's own `S=`/`D=` patterns independently of the "### Valid forms of
line 1" prose lines.

M2: `tests/codex/test-skill-activator.js` worklog block: added a test that
reads `hooks/skill-rules.json` and asserts the index of the `worklog` rule is
lower than the indexes of `brainstorming`, `refactoring` and `writing-plans`.
The existing comment already described this correctly, so it was left as is.

M3: `tests/pickup/run-tests.sh` case 6c: added a new fixture `worklognofolder`
with no `docs/` folder at all before the first `/worklog new` (a handoff,
then `docs/worklogs/w.md` created untracked), asserting `dirty: 0` and
`status: FRESH`. Reworded the comment above the existing `worklogfirst`
fixture so it describes both fixtures (no folder yet, and a folder that
already holds a tracked file) and names the scan's pathspec-limited status
command rather than plain `git status`.

M4: `tests/codex/test-session-start-budget.sh` case 8: added assertions that
each of the three 40-character slugs is named in the notice and that the
notice's closing `</active-work-logs>` tag is present, in addition to the
existing opening-tag check. Reworded the case comment to stop claiming "the
longest notice that three names can produce" and note that the fixture's
root is a short temporary path, so the root-truncation branch does not fire.

M5: `tests/worklog/run-tests.sh` mktemp stand-in: added `MKARGS`, a log of
the stand-in's argument count (`$#`) on every call, reset alongside `MKLOG`
in `run_line1_private`. Added the assertion that the line-1 command's single
mktemp call in the `tmp-cleanup` case carries no argument.

M6: `tests/worklog/run-tests.sh` section 7 `PHRASES`: replaced the pinned
phrase `'stops with the usage text'` (now also contained in the later
"More than one word..." sentence) with the phrase unique to the original
rule: `` 'given as a slug (for example `/worklog new close`), stops with the
usage text' ``.

M7: `tests/codex/test-session-start-worklog-notice.sh:10` header comment of
case 1: corrected "The folder test of the list command skips find in both
states" to state that only the absent-folder state skips `find`; with only a
closed work log, `find` runs and exits 0, and neither state reaches the
`|| true`.

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
Results: 172 passed, 0 failed
exit=0

$ node tests/codex/test-skill-activator.js; echo "exit=$?"
...
skill-activator (UserPromptSubmit): 153 passed, 0 failed
exit=0

$ bash tests/pickup/run-tests.sh; echo "exit=$?"
...
Results: 207 passed, 0 failed
exit=0

$ bash tests/codex/test-session-start-budget.sh; echo "exit=$?"
...
105 passed, 0 failed
exit=0

$ bash tests/codex/test-session-start-worklog-notice.sh; echo "exit=$?"
...
28 passed, 0 failed
exit=0
```

## Round 4

Findings addressed: M2, M3.

Files changed: `tests/worklog/run-tests.sh`, `tests/pickup/run-tests.sh`.

M2: `tests/worklog/run-tests.sh` mktemp stand-in (about line 437): the
stand-in now passes its own arguments through to the real mktemp (resolved
by full path before the stand-in is put on PATH) instead of always creating
the file inside a private folder with a fixed template, and it logs the
path the real command returns instead of the argument count. Dropped
`MKARGS` and the "calls mktemp with no argument" assertion. Added
`mktemp_outside` (the logged path is not under the fixture's
`docs/worklogs` folder `$W`) and `mktemp_removed` (the logged path no
longer exists), replacing `private_tmp_left`. The `tmp-cleanup` case now
asserts: at least one call was logged (`assert_not_empty`, so the removal
check cannot pass on empty input), the existing "exactly once" assertion
(kept — the line-1 command's script calls `mktemp` exactly one time), the
path is outside `docs/worklogs`, and the path no longer exists. Case (d)
(the failed-rewrite branch) gained two assertions: the kept copy exists,
and it is outside `docs/worklogs`. Case (e) (the awk-failure branch) now
calls `mktemp_removed` instead of the removed `private_tmp_left`.

M3: `tests/pickup/run-tests.sh:288` comment above the `worklognofolder` and
`worklogfirst` fixtures of case 6c: the comment had the two git outputs
swapped. Verified with git in a scratch repository
(`/private/tmp/.../scratchpad/m3check`): with no `docs/` folder, plain
`git status --porcelain` and the scan's `-- ':(top)'` pathspec both print
`?? docs/`, and adding `:(top,exclude)docs/worklogs` prints nothing; with a
tracked `docs/README.md`, plain status prints `?? docs/worklogs/`, and
adding the exclude again prints nothing — matching
`skills/pickup/scripts/pickup-scan.js:243-244`. Rewrote the comment to
state this correctly.

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
Results: 177 passed, 0 failed
exit=0

$ bash tests/pickup/run-tests.sh; echo "exit=$?"
...
Results: 207 passed, 0 failed
exit=0
```

## Round 4

Findings addressed: L12, I1.

Files changed: `skills/worklog/SKILL.md`, `tests/worklog/run-tests.sh`,
`tests/codex/test-session-start-budget.sh`.

L12: `skills/worklog/SKILL.md`, `/worklog close` section, step 2: before the
existing "If a part is neither `done` nor `dropped` ..." sentence, added
"Before writing anything, check that the section headings `## Parts`,
`## Open items`, `## Accepted limits` and `## Decisions` all stand; when
one is missing, stop, name the missing heading, and tell the user to run
`/worklog update`, which repairs it — `close` itself never adds a heading
or the `Next item number` line." The repair itself stays in `update` only
(its step 3, unchanged). Pinned the same sentence as a new entry in the
`PHRASES` array of suite section 7 (`tests/worklog/run-tests.sh`).

I1: `tests/codex/test-session-start-budget.sh`: added case 9. It reuses the
three 40-character work logs of case 8, first measuring `room_with_notice`
(the room the notice for those three work logs alone leaves, LIMIT minus
the output length with only that notice added) and `notice_size` (how much
smaller that is than `free_room`, the no-notice room measured before case
3). A single state.md is then sized to `room_with_notice` raw characters:
its own wrapper text always makes the wrapped section land a bit over the
true room (so a budget that correctly counts the notice skips it, and the
output stays at or under the limit with the whole notice present) while
staying under the true room plus the notice's own size (so a budget that
leaves the notice out of its count would find room for it and take the
output over the limit). Case 8 is unchanged.

Verification of I1: built a temporary copy of `hooks/session-start-assemble.js`
outside the checkout (under a `mktemp -d` directory, never committed) whose
`remaining` calculation in `pack()` is measured against a `headForBudget`
that omits the notices part, while the real `head` used for the final
output still includes it — i.e. "the budget leaves the notice out of its
count". Copied `hooks/` and `skills/` into a temporary plugin root with
that one file swapped in, pointed a copy of the test script's `REPO_ROOT`
at it, and ran the whole (unmodified) `tests/codex/test-session-start-budget.sh`
against it:

```
118 passed, 3 failed
  FAIL - the room left counts the notice: 10135 characters, over 10000
  FAIL - the room left counts the notice: state.md content is not injected
  FAIL - the room left counts the notice: <not-injected> names state.md
```

All 3 failures are in case 9; cases 1-8 passed unchanged. Run against the
real, unmodified `hooks/session-start-assemble.js` on this branch, the same
case 9 passes (state.md is skipped, the output is 7951 characters, and the
whole notice is present). The temporary copy and its plugin-root directory
were left under the OS temporary directory (never inside this checkout,
never staged, never committed).

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
Results: 178 passed, 0 failed
exit=0

$ bash tests/codex/test-session-start-budget.sh; echo "exit=$?"
...
  (room_with_notice=2231, notice_size=496)
  121 passed, 0 failed
exit=0
```
