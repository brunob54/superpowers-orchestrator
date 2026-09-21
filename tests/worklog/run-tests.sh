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
CHECK_CMD=$(block_after '### The check command')
LINE1_CMD=$(block_after '### The line-1 command')
ACTIVE_RE=$(form_of active)
CLOSED_RE=$(form_of closed)
# The list command runs as a script under set -euo pipefail, the options that
# hooks/session-start sets on its line 4.
printf 'set -euo pipefail\n%s\n' "$LIST_CMD" > "$TMP/list.sh"

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
# run_list <folder> [shell]: runs the list command from <folder>; sets OUT to
# its output followed by "exit=<status>".
run_list() {
  OUT=$(cd "$1" && "${2:-bash}" "$TMP/list.sh" 2>&1; printf 'exit=%s' "$?")
}
# lines <path>...: the output that run_list expects for these paths.
lines() { printf '%s\n' "$@"; printf 'exit=0'; }
# run_check <folder> <slug>: runs the check command from <folder>; sets OUT.
run_check() {
  printf '%s\n' "${CHECK_CMD//<slug>/$2}" > "$TMP/check.sh"
  OUT=$(cd "$1" && "$RUN_SHELL" "$TMP/check.sh" 2>&1)
}
# run_line1 <folder> <slug> <new line 1>: runs the line-1 command; sets OUT.
run_line1() {
  local cmd="${LINE1_CMD//<slug>/$2}"
  printf '%s\n' "${cmd//<line>/$3}" > "$TMP/line1.sh"
  OUT=$(cd "$1" && "$RUN_SHELL" "$TMP/line1.sh" 2>&1)
}
# repo <name>: a git repository with an empty docs/worklogs folder; sets D
# (the repository) and W (its docs/worklogs folder).
repo() { D="$TMP/$1"; W="$D/docs/worklogs"; mkdir -p "$W"; git -C "$D" init -q; }
# active_log <file> <slug> and closed_log <file> <slug>: a work log with that
# status line on line 1.
active_log() { { printf "$ACTIVE_FMT\n" "$2" "$CREATED"; printf '\n# Work log: fixture\n'; } > "$1"; }
closed_log() { { printf "$CLOSED_FMT\n" "$2" "$CREATED" "$CLOSED_ON"; printf '\n# Work log: fixture\n'; } > "$1"; }

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
for name in SLUG_CMD LIST_CMD CHECK_CMD LINE1_CMD ACTIVE_RE CLOSED_RE; do
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
repo onlybad
active_log "$W/A.md" a
run_list "$D"
assert_eq "a folder with only A.md: one empty line and exit 0" "$OUT" "$(lines '')"

bold "4. The valid forms of line 1"
# form_matches <regex> <line>: exit 0 when <line> matches <regex>.
form_matches() { printf '%s\n' "$2" | grep -Eq -- "$1"; }
if form_matches "$ACTIVE_RE" "$(printf "$ACTIVE_FMT" test-refactor "$CREATED")"; then
  ok "the active form accepts its example line"; else bad "the active form accepts its example line"; fi
if form_matches "$CLOSED_RE" "$(printf "$CLOSED_FMT" test-refactor "$CREATED" "$CLOSED_ON")"; then
  ok "the closed form accepts its example line"; else bad "the closed form accepts its example line"; fi
for line in '<!-- Work log: status=active slug=test-refactor -->' \
            "<!-- Work log: status=closed slug=test-refactor created=$CREATED -->" \
            '<!-- Work log: status=active slug=test-refactor created=2026-9-1 -->'; do
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
run_check "$MD" absent
assert_eq "a missing file prints missing and the folder it searched" "$OUT" "missing (searched $MW)"
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
  NEW_LINE=$(printf "$CLOSED_FMT" "$name" "$CREATED" "$CLOSED_ON")
  run_line1 "$D" "$name" "$NEW_LINE"
  assert_eq "$name: the command exits quietly" "$OUT" ''
  assert_eq "$name: lines 2 and later are unchanged" "$(tail -n +2 "$W/$name.md" | cksum)" "$REST_SUM"
  run_check "$D" "$name"
  assert_eq "$name: the check command then prints closed" "$OUT" 'closed'
done
assert_eq "crlf: line 1 is the new line" "$(head -n 1 "$W/crlf.md" | tr -d '\r')" "$(printf "$CLOSED_FMT" crlf "$CREATED" "$CLOSED_ON")"
assert_eq "crlf: line 1 still ends with a carriage return" "$(head -n 1 "$W/crlf.md" | tail -c 2 | od -An -tx1 | tr -d ' \n')" '0d0a'
assert_eq "bom: the byte order mark is kept" "$(head -c 3 "$W/bom.md" | od -An -tx1 | tr -d ' \n')" 'efbbbf'
assert_eq "plain: line 1 is the new line, with no carriage return" "$(head -n 1 "$W/plain.md")" "$(printf "$CLOSED_FMT" plain "$CREATED" "$CLOSED_ON")"
assert_eq "plain: the file keeps its permissions" "$(ls -l "$W/plain.md" | cut -c1-10)" "$MODE_BEFORE"

if [ "$HAVE_LINKS" = 1 ]; then
  # (a) a symbolic link planted at the predictable temp path <slug>.md.tmp
  # must not be written through: the command's temporary file must never
  # live at that name.
  OUTSIDE_A="$TMP/outside-a.md"
  printf 'outside file A, untouched\n' > "$OUTSIDE_A"
  OUTSIDE_A_SUM=$(cksum < "$OUTSIDE_A")
  active_log "$W/attack-tmp.md" attack-tmp
  ln -s "$OUTSIDE_A" "$W/attack-tmp.md.tmp"
  run_line1 "$D" attack-tmp "$(printf "$CLOSED_FMT" attack-tmp "$CREATED" "$CLOSED_ON")"
  assert_eq "a symbolic link at <slug>.md.tmp: the outside file stays byte-identical" "$(cksum < "$OUTSIDE_A")" "$OUTSIDE_A_SUM"
  run_check "$D" attack-tmp
  assert_eq "a symbolic link at <slug>.md.tmp: the work log still closes" "$OUT" 'closed'
  rm -f "$W/attack-tmp.md.tmp"

  # (b) a work log that is itself a symbolic link to a file outside the
  # folder: the command refuses it and leaves the link target unchanged.
  OUTSIDE_B="$TMP/outside-b.md"
  printf 'outside file B, untouched\n' > "$OUTSIDE_B"
  OUTSIDE_B_SUM=$(cksum < "$OUTSIDE_B")
  ln -s "$OUTSIDE_B" "$W/linked-log.md"
  run_line1 "$D" linked-log "$(printf "$CLOSED_FMT" linked-log "$CREATED" "$CLOSED_ON")"
  assert_eq "a work log that is a symbolic link: the command prints symlink" "$OUT" 'symlink'
  assert_eq "a work log that is a symbolic link: the link target stays byte-identical" "$(cksum < "$OUTSIDE_B")" "$OUTSIDE_B_SUM"
  rm -f "$W/linked-log.md"

  # (c) after a successful run, no <slug>.md.tmp file is left in the folder
  # for a fixture without the planted link (crlf, bom, plain, above).
  assert_eq "no <slug>.md.tmp file is left in docs/worklogs" "$(find "$W" -maxdepth 1 -name '*.md.tmp' 2>/dev/null | wc -l | tr -d ' ')" "0"
else
  note "this file system made no symbolic link in section 3; the line-1 symbolic-link checks are skipped"
fi

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
  run_line1 "$D" zsh-crlf "$(printf "$CLOSED_FMT" zsh-crlf "$CREATED" "$CLOSED_ON")"
  run_check "$D" zsh-crlf; assert_eq "zsh: the line-1 command closes a work log with CRLF line ends" "$OUT" 'closed'
  RUN_SHELL=bash
else
  note "zsh is not installed; the zsh checks of section 6b are skipped"
fi

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
