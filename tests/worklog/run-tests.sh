#!/usr/bin/env bash
# worklog test suite: skills/worklog/template.md, the shell commands and the
# pinned phrases of skills/worklog/SKILL.md, and the copy of the list command
# in hooks/session-start. Each command is copied out of the skill text and run
# on fixture folders, so a check fails when the text that the model runs
# changes. Pure bash, git, awk and grep; no claude invocation.
# Windows note: avoids /dev/stdin (not available in Git Bash on Windows).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="$REPO/skills/worklog/template.md"
SKILL="$REPO/skills/worklog/SKILL.md"
PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()   { green "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_lacks() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}
assert_not_empty() { # desc actual
  if [ -n "$2" ]; then ok "$1"; else bad "$1 (got an empty text)"; fi
}

note() { printf '  NOTE: %s\n' "$1"; }
# The output of a fixture run is held in $OUT; these match a whole line with
# grep -x, so a path never matches a longer path.
out_lacks() { # desc exact-line
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then bad "$1 (found line '$2')"; else ok "$1"; fi
}
out_has_line() { # desc exact-line
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then ok "$1"; else bad "$1 (no line '$2' in: $(printf '%s' "$OUT" | tr '\n' '|'))"; fi
}

# Isolation: the user's global and system git configuration must not change a
# result, and git must never find a repository above a fixture folder.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
# pwd -P resolves macOS's /var -> /private/var symbolic link, so a fixture
# path equals the path that git rev-parse --show-toplevel prints.
TMP=$(mktemp -d)
: "${TMP:?mktemp failed — refusing to run with an empty fixture path}"
TMP=$(cd "$TMP" && pwd -P)
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
export GIT_CEILING_DIRECTORIES="$TMP"

NL=$'\n'
CREATED='2026-09-21'
CLOSED_ON='2026-09-22'
ACTIVE_FMT='<!-- Work log: status=active slug=%s created=%s -->'
CLOSED_FMT='<!-- Work log: status=closed slug=%s created=%s closed=%s -->'
# Fixture names never differ by letter case alone: the default macOS file
# system does not tell A.md from a.md.
S40=$(printf '%40s' '' | tr ' ' s)
S41=$(printf '%41s' '' | tr ' ' t)

# block_after <heading>: the lines of the first ```bash block after the line
# <heading> in the skill file, without the fence lines.
block_after() {
  awk -v h="$1" '$0 == h { f = 1; next } f && /^```bash$/ { c = 1; next } c && /^```$/ { exit } c { print }' "$SKILL" 2>/dev/null
}
# form_of <name>: the regular expression of one valid form of line 1, from
# the line "- <name>: `<expression>`" of the skill file.
form_of() {
  awk -v p="- $1: " 'index($0, p) == 1 { s = substr($0, length(p) + 1); gsub(/^`|`$/, "", s); print s; exit }' "$SKILL" 2>/dev/null
}
SLUG_CMD=$(block_after '### The slug command')
LIST_CMD=$(block_after '### The list command')
LISTING_CMD=$(block_after '### The listing command')
CHECK_CMD=$(block_after '### The check command')
LINE1_CMD=$(block_after '### The line-1 command')
ACTIVE_RE=$(form_of active)
CLOSED_RE=$(form_of closed)
# strict_script <name> <command>: writes <command> to $TMP/<name> after the
# line "set -euo pipefail".
strict_script() { printf 'set -euo pipefail\n%s\n' "$2" > "$TMP/$1"; }
# The list command runs as a script under set -euo pipefail, the options that
# hooks/session-start sets on its line 4, and the listing command runs under
# the same options. Only the fixture with an unreadable docs/worklogs folder
# (sections 3 and 3b) tests the "|| true" of each command: find fails there.
# With no folder, the folder test skips find; with an unreadable file, find
# still exits 0, because "find -exec ... \;" ignores the exit status of awk.
strict_script list.sh "$LIST_CMD"
strict_script listing.sh "$LISTING_CMD"

# The replacement texts below hold no "&" and no backslash, so bash 5.2's
# patsub_replacement option cannot change them.
# RUN_SHELL runs the slug, check and line-1 commands; section 6b sets it to
# zsh, the shell that the Bash tool runs on macOS.
RUN_SHELL=bash
# run_slug <slug>: runs the slug command; sets OUT.
run_slug() {
  printf '%s\n' "${SLUG_CMD//<slug>/$1}" > "$TMP/slug.sh"
  OUT=$("$RUN_SHELL" "$TMP/slug.sh" 2>&1)
}
# run_list <folder> [shell] [script]: runs the list command (or the script
# $TMP/<script>) from <folder>; sets OUT to its output followed by
# "exit=<status>". run_listing <folder> [shell] runs the listing command.
run_list() {
  OUT=$(cd "$1" && "${2:-bash}" "$TMP/${3:-list.sh}" 2>&1; printf 'exit=%s' "$?")
}
run_listing() { run_list "$1" "${2:-bash}" listing.sh; }
# lines <path>...: the output that run_list expects for these paths.
lines() { printf '%s\n' "$@"; printf 'exit=0'; }
# run_check <folder> <slug>: runs the check command from <folder>; sets OUT.
run_check() {
  printf '%s\n' "${CHECK_CMD//<slug>/$2}" > "$TMP/check.sh"
  OUT=$(cd "$1" && "$RUN_SHELL" "$TMP/check.sh" 2>&1)
}
# run_line1 <folder> <slug> <new line 1> [<first line>]: runs the line-1
# command, after <first line> when it is given (for example a shell option);
# sets OUT and CODE, the exit status.
run_line1() {
  local cmd="${LINE1_CMD//<slug>/$2}"
  printf '%s\n%s\n' "${4:-}" "${cmd//<line>/$3}" > "$TMP/line1.sh"
  OUT=$(cd "$1" && "$RUN_SHELL" "$TMP/line1.sh" 2>&1)
  CODE=$?
}
# repo <name>: a git repository with an empty docs/worklogs folder; sets D
# (the repository) and W (its docs/worklogs folder).
repo() { D="$TMP/$1"; W="$D/docs/worklogs"; mkdir -p "$W"; git -C "$D" init -q; }
# active_log <file> <slug> and closed_log <file> <slug>: a work log with that
# status line on line 1.
active_log() { { printf "$ACTIVE_FMT\n" "$2" "$CREATED"; printf '\n# Work log: fixture\n'; } > "$1"; }
closed_log() { { printf "$CLOSED_FMT\n" "$2" "$CREATED" "$CLOSED_ON"; printf '\n# Work log: fixture\n'; } > "$1"; }
# closed_line <slug>: the closed status line of <slug>, with no line break.
closed_line() { printf "$CLOSED_FMT" "$1" "$CREATED" "$CLOSED_ON"; }

bold "1. skills/worklog/template.md"
assert_eq "line 1 is the active status line with placeholders" \
  "$(head -n 1 "$TEMPLATE" 2>/dev/null)" '<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->'
assert_eq "the six ## headings, in order" \
  "$(grep '^## ' "$TEMPLATE" 2>/dev/null | tr '\n' '|')" \
  '## How to maintain this document|## Parts|## Rules for the next parts|## Open items|## Accepted limits|## Decisions|'
RULE_COUNT=$(awk '/^## How to maintain this document$/ { f = 1; next } /^## Parts$/ { f = 0 } f && /^[1-7]\. / { n++ } END { print n + 0 }' "$TEMPLATE" 2>/dev/null)
assert_eq "exactly seven numbered rules in the maintenance section" "$RULE_COUNT" "7"
if grep -qxF 'Next item number: 1' "$TEMPLATE" 2>/dev/null; then ok "the line Next item number: 1"; else bad "the line Next item number: 1 is missing"; fi
for status in 'not started' 'in progress' 'done' 'dropped'; do
  assert_file_contains "the status value $status" "$TEMPLATE" "\`$status\`"
done
assert_file_contains "the form of a former item" "$TEMPLATE" 'item #<n>'
assert_file_contains "the rule for an orchestrated run" "$TEMPLATE" 'do not write this document'
assert_eq "only line 1 starts with the status-line prefix" \
  "$(grep -c '^<!-- Work log: status=' "$TEMPLATE" 2>/dev/null)" "1"
assert_file_lacks "the word workstream is not used" "$TEMPLATE" 'workstream'

bold "2. The slug command"
for name in SLUG_CMD LIST_CMD LISTING_CMD CHECK_CMD LINE1_CMD ACTIVE_RE CLOSED_RE; do
  if [ -n "${!name}" ]; then ok "the skill text holds $name"; else bad "the skill text holds $name"; fi
done
# Claude Code replaces $0, $1 and so on in a skill body with the arguments of
# the invocation, so a command holding such a token reaches the model changed.
assert_eq "no line of the skill holds a \$ directly before a digit" "$(grep -nE '\$[0-9]' "$SKILL" 2>/dev/null)" ''
PATTERN_MSG='breaks the pattern ^[a-z0-9]+(-[a-z0-9]+)*$'
for s in test-refactor "$S40" 7; do
  run_slug "$s"; assert_eq "slug '$s' is valid" "$OUT" 'valid'
done
for s in A a--b -a a- 'café' 'x y'; do
  run_slug "$s"; assert_eq "slug '$s' breaks the pattern" "$OUT" "$PATTERN_MSG"
done
run_slug "$S41"; assert_eq "a slug of 41 characters is too long" "$OUT" 'has more than 40 characters'
for s in new update close; do
  run_slug "$s"; assert_eq "'$s' is a command word" "$OUT" 'is a command word'
done

bold "3. The list command"
repo mixed
MD="$D"; MW="$W"
active_log "$W/alpha.md" alpha
closed_log "$W/closed.md" closed
{ printf "$CLOSED_FMT\n\n" quoted "$CREATED" "$CLOSED_ON"; printf "$ACTIVE_FMT\n" quoted "$CREATED"; } > "$W/quoted.md"
printf '<!-- Work log: status=open slug=c created=2026-09-21 -->\n' > "$W/open-status.md"
{ printf '# Work log: heading first\n\n'; printf "$ACTIVE_FMT\n" line-three "$CREATED"; } > "$W/line-three.md"
for name in Upper 'x y' new 'café' "$S41"; do active_log "$W/$name.md" "$name"; done
active_log "$W/$S40.md" "$S40"
{ printf '\357\273\277'; printf "$ACTIVE_FMT\n" bom "$CREATED"; } > "$W/bom.md"
printf "$ACTIVE_FMT\r\n\r\n# Work log: fixture\r\n" crlf "$CREATED" > "$W/crlf.md"
if ! active_log "$W/$(printf 'n\nl').md" nl 2>/dev/null; then
  note "this file system refuses a line break in a file name; that case is skipped"
fi
HAVE_LINKS=0
ln -s alpha.md "$W/link.md" 2>/dev/null
if [ -L "$W/link.md" ]; then
  HAVE_LINKS=1
else
  rm -f "$W/link.md"
  note "ln -s made no symbolic link here; the symbolic-link checks are skipped"
fi
run_list "$MD"
MIXED_EXPECTED=$(lines "$MW/alpha.md" "$MW/bom.md" "$MW/crlf.md" "$MW/$S40.md")
assert_eq "only valid active work logs are listed, sorted; a byte order mark and a CRLF line end are accepted" "$OUT" "$MIXED_EXPECTED"
for name in closed quoted open-status line-three Upper 'x y' new 'café' "$S41"; do
  out_lacks "$name.md is not listed" "$MW/$name.md"
done
if [ "$HAVE_LINKS" = 1 ]; then out_lacks "a symbolic link is not listed" "$MW/link.md"; fi
mkdir -p "$MD/src/deep"
run_list "$MD/src/deep"
assert_eq "the same output from a sub-folder" "$OUT" "$MIXED_EXPECTED"
if command -v zsh >/dev/null 2>&1; then
  run_list "$MD/src/deep" zsh
  assert_eq "the same output when zsh runs it" "$OUT" "$MIXED_EXPECTED"
else
  note "zsh is not installed; the zsh check is skipped"
fi
repo sorted
for name in ab a a-b; do active_log "$W/$name.md" "$name"; done
run_list "$D"
assert_eq "several work logs in C-locale order" "$OUT" "$(lines "$W/a-b.md" "$W/a.md" "$W/ab.md")"
repo unreadable
for name in a b c; do active_log "$W/$name.md" "$name"; done
chmod 000 "$W/b.md"
if [ -r "$W/b.md" ]; then
  note "b.md stays readable (root user?); the unreadable-file check is skipped"
else
  run_list "$D"
  assert_eq "an unreadable file hides no other work log" "$OUT" "$(lines "$W/a.md" "$W/c.md")"
fi
chmod 644 "$W/b.md"
D="$TMP/nofolder"; mkdir -p "$D"; git -C "$D" init -q
run_list "$D"
assert_eq "no docs/worklogs folder: one empty line and exit 0 under set -euo pipefail" "$OUT" "$(lines '')"
# A docs/worklogs folder with mode 000: the folder test passes, and find
# fails when it reads the folder, so only the "|| true" keeps the exit
# status 0.
repo lockedfolder
LD="$D"; LW="$W"
active_log "$W/a.md" a
# locked_run <run function> <desc> <expected>: runs <run function> on $LD
# while its docs/worklogs folder has mode 000, compares OUT with <expected>,
# and restores the mode. When the folder stays readable (for example for the
# root user), the check is skipped with a NOTE line.
locked_run() {
  chmod 000 "$LW"
  if [ -r "$LW" ]; then
    note "docs/worklogs stays readable (root user?); the check '$2' is skipped"
  else
    "$1" "$LD"
    assert_eq "$2" "$OUT" "$3"
  fi
  chmod 755 "$LW"
}
locked_run run_list "an unreadable docs/worklogs folder: one empty line and exit 0 under set -euo pipefail" "$(lines '')"
# A folder that is not a git repository: the root is the folder of the shell
# (the "|| pwd" of each command).
NG="$TMP/notgit"; NGW="$NG/docs/worklogs"
mkdir -p "$NGW"
active_log "$NGW/solo.md" solo
run_list "$NG"
assert_eq "not a git repository: the work log under the folder of the shell is listed" "$OUT" "$(lines "$NGW/solo.md")"
repo onlybad
active_log "$W/A.md" a
run_list "$D"
assert_eq "a folder with only A.md: one empty line and exit 0" "$OUT" "$(lines '')"

bold "3b. The listing command"
# A file named x'$(touch <marker>)'.md creates the marker file when any shell
# evaluates that name, so the marker must not exist after the runs. The
# zero-byte empty.md is listed because the command never reads a file.
INVALID_LABEL='invalid file name — rename it'
MARKER=listing-marker
repo listing
: > "$W/x'\$(touch $MARKER)'.md"
: > "$W/x y.md"
: > "$W/new.md"
: > "$W/empty.md"
for name in alpha a-b; do active_log "$W/$name.md" "$name"; done
LISTING_EXPECTED=$(lines a-b alpha empty "new.md: $INVALID_LABEL" "x???touch?$MARKER??.md: $INVALID_LABEL" "x?y.md: $INVALID_LABEL")
run_listing "$D"
assert_eq "valid names print their slug, other names a label with ? for unsafe characters, in C-locale order, exit 0" "$OUT" "$LISTING_EXPECTED"
if command -v zsh >/dev/null 2>&1; then
  run_listing "$D" zsh
  assert_eq "the same listing when zsh runs it" "$OUT" "$LISTING_EXPECTED"
else
  note "zsh is not installed; the zsh listing check is skipped"
fi
assert_eq "the hostile file name ran no command: no marker file exists" "$(find "$TMP" -name "$MARKER")" ''
run_listing "$TMP/nofolder"
assert_eq "listing, no docs/worklogs folder: no line and exit 0 under set -euo pipefail" "$OUT" 'exit=0'
locked_run run_listing "listing, an unreadable docs/worklogs folder: no line and exit 0 under set -euo pipefail" 'exit=0'
# The listing command has its own copy of the file-name filter, so it runs on
# the folder of section 3 too. Under LC_ALL=C each byte of é becomes one "?".
# The symbolic link is not a regular file, so it has no line.
MIXED_LISTING=("?pper.md: $INVALID_LABEL" alpha bom "caf??.md: $INVALID_LABEL" closed crlf line-three)
if [ -f "$MW/$(printf 'n\nl').md" ]; then MIXED_LISTING+=("n?l.md: $INVALID_LABEL"); fi
MIXED_LISTING+=("new.md: $INVALID_LABEL" open-status quoted "$S40" "$S41.md: $INVALID_LABEL" "x?y.md: $INVALID_LABEL")
run_listing "$MD"
assert_eq "listing of the section 3 folder: the same file-name filter as the list command" "$OUT" "$(lines "${MIXED_LISTING[@]}")"

bold "4. The valid forms of line 1"
# form_matches <regex> <line>: exit 0 when <line> matches <regex>.
form_matches() { printf '%s\n' "$2" | grep -Eq -- "$1"; }
if form_matches "$ACTIVE_RE" "$(printf "$ACTIVE_FMT" test-refactor "$CREATED")"; then
  ok "the active form accepts its example line"; else bad "the active form accepts its example line"; fi
if form_matches "$CLOSED_RE" "$(closed_line test-refactor)"; then
  ok "the closed form accepts its example line"; else bad "the closed form accepts its example line"; fi
# REFUSED_LINES: line-1 texts that no valid form accepts (no created=, a
# closed line with no closed=, and a date of the wrong shape). Section 5
# reuses this list to check that the check command's own copy of the
# patterns also refuses each one.
REFUSED_LINES=(
  '<!-- Work log: status=active slug=test-refactor -->'
  "<!-- Work log: status=closed slug=test-refactor created=$CREATED -->"
  '<!-- Work log: status=active slug=test-refactor created=2026-9-1 -->'
)
for line in "${REFUSED_LINES[@]}"; do
  for form in active closed; do
    re=$(form_of "$form")
    if form_matches "$re" "$line"; then bad "the $form form refuses '$line'"; else ok "the $form form refuses '$line'"; fi
  done
done
if form_matches "$ACTIVE_RE" "$(head -n 1 "$MW/crlf.md" | tr -d '\r')"; then
  ok "a CRLF line 1 matches the active form once the carriage return is removed"
else
  bad "a CRLF line 1 matches the active form once the carriage return is removed"
fi

bold "5. The check command"
run_check "$MD" alpha;  assert_eq "an active work log prints active" "$OUT" 'active'
run_check "$MD" closed; assert_eq "a closed work log prints closed" "$OUT" 'closed'
run_check "$MD" crlf;   assert_eq "a line 1 with a carriage return prints active" "$OUT" 'active'
run_check "$MD" bom;    assert_eq "a line 1 with a byte order mark prints active" "$OUT" 'active'
run_check "$MD" open-status
assert_eq "an unknown status prints malformed first" "${OUT%%"$NL"*}" 'malformed'
run_check "$MD" line-three
assert_eq "a status line on line 3 prints malformed first" "${OUT%%"$NL"*}" 'malformed'
out_has_line "the status line on line 3 is printed with its line number" "3:$(printf "$ACTIVE_FMT" line-three "$CREATED")"
# The check command has its own copy of the active and closed patterns (its
# S=/D= values and two grep -Eq lines), separate from the "### Valid forms of
# line 1" prose lines that section 4 checks above. These fixtures pin that
# copy directly: each of section 4's refused lines, plus a valid active line
# with text after -->, plus an uppercase slug= value, must make the check
# command print malformed.
MALFORMED_NAMES=(malformed-no-created malformed-no-closed malformed-bad-date)
for i in "${!REFUSED_LINES[@]}"; do
  name="${MALFORMED_NAMES[$i]}"
  { printf '%s\n' "${REFUSED_LINES[$i]}"; printf '\n# Work log: fixture\n'; } > "$MW/$name.md"
  run_check "$MD" "$name"
  assert_eq "the check command refuses '${REFUSED_LINES[$i]}'" "${OUT%%"$NL"*}" 'malformed'
done
{ printf "$ACTIVE_FMT extra\n" malformed-trailing "$CREATED"; printf '\n# Work log: fixture\n'; } > "$MW/malformed-trailing.md"
run_check "$MD" malformed-trailing
assert_eq "the check command refuses a valid active line with extra text after -->" "${OUT%%"$NL"*}" 'malformed'
{ printf "$ACTIVE_FMT\n" MALFORMED "$CREATED"; printf '\n# Work log: fixture\n'; } > "$MW/malformed-upper-slug.md"
run_check "$MD" malformed-upper-slug
assert_eq "the check command refuses an uppercase slug= value" "${OUT%%"$NL"*}" 'malformed'
run_check "$MD" absent
assert_eq "a missing file prints missing and the folder it searched" "$OUT" "missing (searched $MW)"
run_check "$NG" solo
assert_eq "not a git repository: the work log under the folder of the shell prints active" "$OUT" 'active'
run_check "$NG" absent
assert_eq "not a git repository: a missing file prints the folder of the shell that it searched" "$OUT" "missing (searched $NGW)"
if [ "$HAVE_LINKS" = 1 ]; then
  run_check "$MD" link; assert_eq "a symbolic link prints symlink" "$OUT" 'symlink'
fi
run_check "$MD/src/deep" alpha
assert_eq "the same word from a sub-folder" "$OUT" 'active'
BEFORE_SUM=$(cksum < "$MW/crlf.md")
run_check "$MD" crlf
assert_eq "the check command changes no file" "$(cksum < "$MW/crlf.md")" "$BEFORE_SUM"

bold "6. The line-1 command"
repo line1
printf "$ACTIVE_FMT\r\n\r\n# Work log: fixture\r\nrow\r\n" crlf "$CREATED" > "$W/crlf.md"
{ printf '\357\273\277'; printf "$ACTIVE_FMT\n\n# Work log: fixture\n" bom "$CREATED"; } > "$W/bom.md"
printf "$ACTIVE_FMT\n\n# Work log: fixture\n" wrong-slug "$CREATED" > "$W/plain.md"
# The command rewrites the file in place, so its mode must not change.
chmod 640 "$W/plain.md"
MODE_BEFORE=$(ls -l "$W/plain.md" | cut -c1-10)
for name in crlf bom plain; do
  REST_SUM=$(tail -n +2 "$W/$name.md" | cksum)
  run_line1 "$D" "$name" "$(closed_line "$name")"
  assert_eq "$name: the command exits quietly" "$OUT" ''
  assert_eq "$name: the exit status is 0" "$CODE" '0'
  assert_eq "$name: lines 2 and later are unchanged" "$(tail -n +2 "$W/$name.md" | cksum)" "$REST_SUM"
  run_check "$D" "$name"
  assert_eq "$name: the check command then prints closed" "$OUT" 'closed'
done
assert_eq "crlf: line 1 is the new line" "$(head -n 1 "$W/crlf.md" | tr -d '\r')" "$(closed_line crlf)"
assert_eq "crlf: line 1 still ends with a carriage return" "$(head -n 1 "$W/crlf.md" | tail -c 2 | od -An -tx1 | tr -d ' \n')" '0d0a'
assert_eq "bom: the byte order mark is kept" "$(head -c 3 "$W/bom.md" | od -An -tx1 | tr -d ' \n')" 'efbbbf'
assert_eq "plain: line 1 is the new line, with no carriage return" "$(head -n 1 "$W/plain.md")" "$(closed_line plain)"
assert_eq "plain: the file keeps its permissions" "$(ls -l "$W/plain.md" | cut -c1-10)" "$MODE_BEFORE"

# line1_through_link <link> <slug> <label>: makes <link> in $W a symbolic
# link to a new file outside the docs/worklogs folder, runs the line-1
# command to close <slug> (OUT and CODE keep its result), and checks that
# the outside file stays byte-identical.
line1_through_link() {
  local outside="$TMP/outside-$2.md" sum
  printf 'outside file of %s, untouched\n' "$2" > "$outside"
  sum=$(cksum < "$outside")
  ln -s "$outside" "$W/$1"
  run_line1 "$D" "$2" "$(closed_line "$2")"
  assert_eq "$3: the outside file stays byte-identical" "$(cksum < "$outside")" "$sum"
}
if [ "$HAVE_LINKS" = 1 ]; then
  # (a) a symbolic link planted at the predictable temp path <slug>.md.tmp
  # must not be written through: the command's temporary file must never
  # live at that name.
  active_log "$W/attack-tmp.md" attack-tmp
  line1_through_link attack-tmp.md.tmp attack-tmp "a symbolic link at <slug>.md.tmp"
  run_check "$D" attack-tmp
  assert_eq "a symbolic link at <slug>.md.tmp: the work log still closes" "$OUT" 'closed'
  rm -f "$W/attack-tmp.md.tmp"
else
  note "this file system made no symbolic link in section 3; the line-1 symbolic-link checks are skipped"
fi

# (c) the temporary file that mktemp creates is outside the docs/worklogs
# folder, as the skill states, and is removed after a successful run. The
# system's shared temporary folder (on macOS, "/var/folders/.../T/") holds
# files from every process the user runs, not only this test, so other work
# can add or remove a "tmp.*" entry there at any moment. Watching that
# shared folder makes the test fail for a reason outside the command under
# test. Instead, this builds a private stand-in program named "mktemp": a
# small script placed in a folder of its own, $MKBIN, that is put first on
# PATH before the line-1 command runs. The stand-in passes its own
# arguments through to the real mktemp program (found by its full path,
# with "command -v mktemp", before the stand-in exists), so the file lands
# exactly where the real command would put it, and it writes the path that
# call returns to a log file, $MKLOG, one line per call.
REAL_MKTEMP="$(command -v mktemp)"
MKBIN="$TMP/mkbin"
MKLOG="$TMP/mktemp.log"
mkdir -p "$MKBIN"
: > "$MKLOG"
{
  printf '#!/bin/sh\n'
  printf 'p="$(%s "$@")"\n' "$REAL_MKTEMP"
  printf 'printf "%%s\\n" "$p" >> "%s"\n' "$MKLOG"
  printf 'printf "%%s\\n" "$p"\n'
} > "$MKBIN/mktemp"
chmod +x "$MKBIN/mktemp"
OLD_PATH="$PATH"
# run_line1_private <slug>: runs the line-1 command to close <slug>, with the
# stand-in mktemp first on PATH; $MKLOG then names only the calls of this
# run.
run_line1_private() {
  : > "$MKLOG"
  PATH="$MKBIN:$OLD_PATH"
  run_line1 "$D" "$1" "$(closed_line "$1")"
  PATH="$OLD_PATH"
}
# mktemp_calls: the number of times the stand-in mktemp was called in the
# last run. mktemp_outside: "outside" when every path it logged is not
# under the fixture's docs/worklogs folder $W, "inside" otherwise (empty
# input, no logged call, also prints "outside", so callers first check
# mktemp_calls is not "0"). mktemp_removed: "absent" when every path it
# logged no longer exists, "present" otherwise.
mktemp_calls() { wc -l < "$MKLOG" | tr -d ' '; }
mktemp_outside() {
  local line
  while IFS= read -r line; do
    case "$line" in "$W"/*) printf 'inside\n'; return ;; esac
  done < "$MKLOG"
  printf 'outside\n'
}
mktemp_removed() {
  local line
  while IFS= read -r line; do
    if [ -e "$line" ]; then printf 'present\n'; return; fi
  done < "$MKLOG"
  printf 'absent\n'
}
active_log "$W/tmp-cleanup.md" tmp-cleanup
run_line1_private tmp-cleanup
assert_not_empty "the line-1 command calls mktemp at least once" "$(cat "$MKLOG")"
assert_eq "the line-1 command calls mktemp exactly once" "$(mktemp_calls)" '1'
assert_eq "the path mktemp returns is outside the docs/worklogs folder" "$(mktemp_outside)" 'outside'
assert_eq "no temporary file lingers after a successful run" "$(mktemp_removed)" 'absent'
run_check "$D" tmp-cleanup
assert_eq "tmp-cleanup: the check command then prints closed" "$OUT" 'closed'

# line1_cases <p> <label prefix>: the noclobber run and the failure paths
# (b), (d) and (e) of the line-1 command, run with the shell RUN_SHELL.
# Section 6 calls it with bash and section 6b with zsh. <p> starts every
# slug, so each shell closes work logs of its own; <label prefix> starts
# every label.
line1_cases() {
  local p="$1" lp="$2" s l sum kept
  # The shell option noclobber (bash "set -o noclobber", zsh "setopt
  # noclobber") refuses a ">" redirection to a file that exists. mktemp
  # creates the temporary file before the command writes to it, and the work
  # log exists, so the command must still rewrite line 1 with this option set.
  s="${p}noclobber"; l="${lp}noclobber"
  active_log "$W/$s.md" "$s"
  run_line1 "$D" "$s" "$(closed_line "$s")" 'set -o noclobber'
  assert_eq "$l: the command exits quietly" "$OUT" ''
  assert_eq "$l: the exit status is 0" "$CODE" '0'
  run_check "$D" "$s"
  assert_eq "$l: the check command then prints closed" "$OUT" 'closed'

  # (b) a work log that is itself a symbolic link to a file outside the
  # folder: the command refuses it and leaves the link target unchanged.
  # Without symbolic links, the note of case (a) covers this case too.
  if [ "$HAVE_LINKS" = 1 ]; then
    s="${p}linked-log"; l="${lp}a work log that is a symbolic link"
    line1_through_link "$s.md" "$s" "$l"
    assert_eq "$l: the command prints symlink" "$OUT" 'symlink'
    assert_eq "$l: the exit status is 1" "$CODE" '1'
    rm -f "$W/$s.md"
  fi

  # (d) the rewrite fails: the work log is read-only, so writing it back is
  # refused. The command keeps its temporary copy, prints the copy's path on
  # its last line, and exits with status 1; the work log is unchanged.
  s="${p}read-only"; l="${lp}a failed rewrite"
  active_log "$W/$s.md" "$s"
  sum=$(cksum < "$W/$s.md")
  chmod 444 "$W/$s.md"
  if [ -w "$W/$s.md" ]; then
    note "$s.md stays writable (root user?); the kept-copy check is skipped"
  else
    run_line1_private "$s"
    kept=$(cat "$MKLOG")
    assert_eq "$l: the exit status is 1" "$CODE" '1'
    assert_eq "$l: the last line printed is the path of the copy" "${OUT##*"$NL"}" "$kept"
    assert_eq "$l: the kept copy exists" "$([ -f "$kept" ] && printf present || printf absent)" 'present'
    assert_eq "$l: the kept copy is outside the docs/worklogs folder" "$(mktemp_outside)" 'outside'
    assert_eq "$l: the copy is kept, with the new line 1" "$(head -n 1 "$kept" 2>/dev/null)" "$(closed_line "$s")"
    assert_eq "$l: the work log is unchanged" "$(cksum < "$W/$s.md")" "$sum"
    rm -f "$kept"
  fi
  chmod 644 "$W/$s.md"

  # (e) awk fails: the work log cannot be read. The command prints the error
  # of awk, removes its temporary copy and exits with status 1; the work log
  # is unchanged. The printed text is checked because the skill stops only
  # when the command prints something.
  s="${p}unreadable"; l="${lp}awk fails"
  active_log "$W/$s.md" "$s"
  sum=$(cksum < "$W/$s.md")
  chmod 000 "$W/$s.md"
  if [ -r "$W/$s.md" ]; then
    note "$s.md stays readable (root user?); the awk-failure check is skipped"
  else
    run_line1_private "$s"
    assert_eq "$l: the exit status is 1" "$CODE" '1'
    assert_not_empty "$l: the command prints something" "$OUT"
    assert_eq "$l: the command called mktemp once" "$(mktemp_calls)" '1'
    assert_eq "$l: the temporary copy is removed" "$(mktemp_removed)" 'absent'
  fi
  chmod 644 "$W/$s.md"
  assert_eq "$l: the work log is unchanged" "$(cksum < "$W/$s.md")" "$sum"
}
line1_cases '' ''

bold "6b. The slug, check and line-1 commands under zsh"
if command -v zsh >/dev/null 2>&1; then
  RUN_SHELL=zsh
  run_slug test-refactor; assert_eq "zsh: slug 'test-refactor' is valid" "$OUT" 'valid'
  run_slug 'café'; assert_eq "zsh: slug 'café' breaks the pattern" "$OUT" "$PATTERN_MSG"
  run_slug "$S41"; assert_eq "zsh: a slug of 41 characters is too long" "$OUT" 'has more than 40 characters'
  run_check "$MD" crlf; assert_eq "zsh: a line 1 with a carriage return prints active" "$OUT" 'active'
  run_check "$MD" bom; assert_eq "zsh: a line 1 with a byte order mark prints active" "$OUT" 'active'
  run_check "$MD" absent; assert_eq "zsh: a missing file prints missing and the folder it searched" "$OUT" "missing (searched $MW)"
  printf "$ACTIVE_FMT\r\n\r\n# Work log: fixture\r\n" zsh-crlf "$CREATED" > "$W/zsh-crlf.md"
  run_line1 "$D" zsh-crlf "$(closed_line zsh-crlf)"
  assert_eq "zsh: the line-1 command exits quietly" "$OUT" ''
  assert_eq "zsh: the exit status of the line-1 command is 0" "$CODE" '0'
  run_check "$D" zsh-crlf; assert_eq "zsh: the line-1 command closes a work log with CRLF line ends" "$OUT" 'closed'
  line1_cases zsh- 'zsh: '
  RUN_SHELL=bash
else
  note "zsh is not installed; the zsh checks of section 6b are skipped"
fi

bold "7. Pinned phrases of skills/worklog/SKILL.md"
FRONT=$(awk 'NR == 1 && $0 == "---" { f = 1; next } f && $0 == "---" { exit } f { print }' "$SKILL" 2>/dev/null)
case "$FRONT" in *'name: worklog'*) ok "the front matter names the skill worklog" ;; *) bad "the front matter names the skill worklog" ;; esac
case "$FRONT" in *'argument-hint: "[new|update|close] [<slug>]"'*) ok "the front matter carries the argument hint" ;; *) bad "the front matter carries the argument hint" ;; esac
case "$FRONT" in *disable-model-invocation*) bad "the front matter carries disable-model-invocation" ;; *) ok "the front matter does not carry disable-model-invocation" ;; esac
PHRASES=(
  'Argument given by the user (may be empty): $ARGUMENTS'
  'Grammar: `/worklog [new|update|close] [<slug>]`'
  "The fallback to \`update\` applies only when the user's own message starts with the command"
  'The message also counts as starting with the command when it holds a'
  '`<command-name>` tag that names `/worklog`'
  'given as a slug (for example `/worklog new close`), stops with the usage text'
  'More than one word after the command word also stops with the usage text and writes nothing'
  'When the command prints anything, stop: show its output to the user (a printed path is the kept copy of the work log, from which it can be restored)'
  'Get the files with the listing command only, never with another command'
  'Any other word stops the command: show that word to the user'
  'A closed work log is never written'
  'close anyway'
  "$INVALID_LABEL"
  'malformed line 1'
  'Never overwrite a work log'
  'never commits'
  "git log -n 200 --since=\"<created> 00:00\" --format='%h %cd %s' --date=short HEAD | cat"
  'When the session-start notice or the user names an active work log, read that work log with the Read tool before starting the work, and follow its section `How to maintain this document`.'
  '> A finding becomes an open item only when it blocks a part from reaching the status `done`, or blocks the "done when" condition of the whole work, or when its consequence is lost user work or a wrong commit. Every other finding gets one line under `## Accepted limits`.'
  'Before writing anything, check that the section headings `## Parts`, `## Open items`, `## Accepted limits` and `## Decisions` all stand; when one is missing, stop, name the missing heading, and tell the user to run `/worklog update`, which repairs it — `close` itself never adds a heading or the `Next item number` line.'
)
for phrase in "${PHRASES[@]}"; do
  assert_file_contains "the skill text holds: $phrase" "$SKILL" "$phrase"
done
TEMPLATE_STEP=$(grep -F '<skill-dir>/template.md' "$SKILL" 2>/dev/null)
case "$TEMPLATE_STEP" in
  *'with the Read tool'*) ok "the step that names <skill-dir>/template.md reads it with the Read tool" ;;
  *) bad "the step that names <skill-dir>/template.md reads it with the Read tool" ;;
esac
assert_file_lacks "the word workstream is not used" "$SKILL" 'workstream'

bold "8. hooks/session-start holds the list command unchanged"
# Every line of the list command except its last one, the print line: the
# hook uses the LIST variable itself.
HOOK_LIST=$(printf '%s\n' "$LIST_CMD" | sed '$d')
HOOK_TEXT=$(cat "$REPO/hooks/session-start")
if [ -n "$HOOK_LIST" ]; then
  case "$HOOK_TEXT" in
    *"$HOOK_LIST"*) ok "the hook holds the list command of the skill, line for line" ;;
    *) bad "the hook holds the list command of the skill, line for line" ;;
  esac
else
  bad "the hook holds the list command of the skill, line for line (the skill text holds no list command)"
fi

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
