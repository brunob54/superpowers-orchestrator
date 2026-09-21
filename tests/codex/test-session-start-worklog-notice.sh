#!/usr/bin/env bash
# Unit test: the <active-work-logs> notice of hooks/session-start (skill
# worklog, v7.52.0). The hook runs the list command of skills/worklog/SKILL.md
# in the project directory and names at most three active work logs in one
# notice. It appends the notice to the notices part, which is always included,
# whatever the size of state.md.
#
# Cases (from the section "Testing strategy" of the worklog design):
#   1. No docs/worklogs folder: exit 0, no notice, and the same output as with
#      a folder that holds only a closed work log. The folder test of the
#      list command skips find in both states. Then the same folder with mode
#      000: the folder test passes and find fails, so this is the fixture
#      that runs the pipeline to its failure. Exit 0 and the same output
#      again pin the "|| true" of the list command under the hook's
#      "set -euo pipefail".
#   2. One active and one closed work log: the exact one-path notice, after
#      two line breaks, at the end of the notices part.
#   3. A file name that breaks the slug rule, with an active line 1: the same
#      output as without that file. An assertion "is not named" alone would
#      also pass on a hook that ended early.
#   4. Five active work logs: the exact five-path notice, also when the hook
#      starts in a sub-folder of the project.
#   5. An unreadable work log between two readable ones, and a work log whose
#      line 1 starts with a byte order mark.
#   6. A root longer than 300 characters: its last 300 characters, after "…".
#   7. Three, then four active work logs, the edge of worklog_paths_max: the
#      exact notice, with no " and " text, then with " and 1 more".
#   8. A root with a space and a glob character, and four active work logs:
#      the exact notice (the hook splits the list on line breaks only, with
#      file-name pattern expansion off).
#   9. A root of exactly 300 characters, the edge of worklog_root_max: printed
#      whole, with no "…".
#
# Self-contained like tests/codex/test-session-start-budget.sh: no network
# (SUPERPOWERS_AUTO_UPDATE=0), a temporary HOME, CLAUDE_PLUGIN_ROOT set. The
# output is parsed with JSON.parse (Node).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK="${REPO_ROOT}/hooks/session-start"
OPEN_TAG="<active-work-logs>"
CLOSING_TAG="</EXTREMELY_IMPORTANT>"
CREATED="2026-09-21"
NL=$'\n'
NOTICE_TAIL='. Before you work on one of them, read it with the Read tool and follow its section "How to maintain this document". During an orchestrated run or a whole-branch review, do not write it.</active-work-logs>'

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
# pwd -P resolves macOS's /var -> /private/var symbolic link, so a fixture
# path equals the root that git rev-parse --show-toplevel prints in the hook.
TMP=$(mktemp -d)
TMP=$(cd "$TMP" && pwd -P)
TMP_HOME=$(mktemp -d)
trap 'chmod -R u+rwx "$TMP" 2>/dev/null || true; rm -rf "$TMP" "$TMP_HOME"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# assert_eq <label> <actual> <expected>
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# assert_contains <label> <haystack> <needle>
assert_contains() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *) bad "$1" ;;
  esac
}
# assert_absent <label> <haystack> <needle>
assert_absent() {
  case "$2" in
    *"$3"*) bad "$1" ;;
    *) ok "$1" ;;
  esac
}
# assert_same <label> <context> <other context>: without the texts in the
# message, because a context is several thousand characters long.
assert_same() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1"; fi
}

# run_hook <dir>: runs the hook with <dir> as the working directory. Sets
# HOOK_CODE to its exit status and CTX to the additionalContext string of the
# Claude Code output branch. A hook that ends before it writes its JSON
# output counts as one failure and leaves CTX empty, so the assertions of the
# case still run and report.
run_hook() {
  local raw="${TMP}/hook-output.json"
  local pass=()
  [ -n "${SYSTEMROOT:-}" ] && pass+=("SYSTEMROOT=$SYSTEMROOT")
  [ -n "${TEMP:-}" ] && pass+=("TEMP=$TEMP")
  HOOK_CODE=0
  (cd "$1" && env -i PATH="$PATH" HOME="$TMP_HOME" GIT_CEILING_DIRECTORIES="$TMP" \
      CLAUDE_PLUGIN_ROOT="$REPO_ROOT" SUPERPOWERS_AUTO_UPDATE=0 \
      ${pass[@]+"${pass[@]}"} bash "$HOOK") > "$raw" || HOOK_CODE=$?
  CTX=$(node -e '
    const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    process.stdout.write(j.hookSpecificOutput.additionalContext);' "$raw" 2>/dev/null) \
    || { CTX=""; bad "the hook wrote no valid JSON output (exit status ${HOOK_CODE})"; }
}

# project <name>: an empty git repository; sets P to its path.
project() {
  P="${TMP}/$1"
  mkdir -p "$P"
  git -C "$P" init -q
}

# worklog <file name> <active|closed>: a work log in $P/docs/worklogs whose
# slug= field repeats the file name.
worklog() {
  local slug="${1%.md}"
  mkdir -p "${P}/docs/worklogs"
  if [ "$2" = active ]; then
    printf '<!-- Work log: status=active slug=%s created=%s -->\n\n# Work log: fixture\n' "$slug" "$CREATED"
  else
    printf '<!-- Work log: status=closed slug=%s created=%s closed=%s -->\n\n# Work log: fixture\n' "$slug" "$CREATED" "$CREATED"
  fi > "${P}/docs/worklogs/$1"
}

# notice <root> <paths> [more]: the exact notice text of the design.
notice() {
  printf '%sActive work logs under %s: %s%s%s' "$OPEN_TAG" "$1" "$2" "${3:-}" "$NOTICE_TAIL"
}
# more <n>: the [more] text of notice for <n> work logs that are not named.
more() { printf ' and %s more under docs/worklogs/' "$1"; }
# The <paths> text of notice for the work logs a.md, b.md and c.md.
THREE_PATHS="docs/worklogs/a.md, docs/worklogs/b.md, docs/worklogs/c.md"
# chars <n> <character>: <character> repeated <n> times.
chars() { printf '%*s' "$1" '' | tr ' ' "$2"; }

echo "session-start: active work log notice"

# ── Case 1: no docs/worklogs folder ────────────────────────────────────────
project nofolder
run_hook "$P"
assert_eq "no folder: the hook exits 0" "$HOOK_CODE" "0"
assert_absent "no folder: no notice" "$CTX" "$OPEN_TAG"
ctx_nofolder="$CTX"
worklog z.md closed
run_hook "$P"
assert_eq "only a closed work log: the hook exits 0" "$HOOK_CODE" "0"
assert_same "only a closed work log: the output equals the output with no folder" "$CTX" "$ctx_nofolder"
chmod 000 "${P}/docs/worklogs"
if [ -r "${P}/docs/worklogs" ]; then
  echo "  note - docs/worklogs stays readable (root user?); the unreadable-folder check is skipped"
else
  run_hook "$P"
  assert_eq "unreadable docs/worklogs folder: the hook exits 0" "$HOOK_CODE" "0"
  assert_same "unreadable docs/worklogs folder: the output equals the output with no folder" "$CTX" "$ctx_nofolder"
fi
chmod 755 "${P}/docs/worklogs"

# ── Case 2: one active and one closed work log ─────────────────────────────
project one
worklog a.md active
worklog z.md closed
run_hook "$P"
assert_eq "one active work log: the hook exits 0" "$HOOK_CODE" "0"
assert_contains "one active work log: the exact notice, after two line breaks, at the end of the notices" \
  "$CTX" "${NL}${NL}$(notice "$P" docs/worklogs/a.md)${NL}${CLOSING_TAG}"
assert_absent "one active work log: the closed work log is not named" "$CTX" "docs/worklogs/z.md"

# ── Case 3: file names that break the slug rule ────────────────────────────
S41=$(chars 41 s)
i=0
for name in 'x y.md' 'A.md' 'new.md' "${S41}.md"; do
  i=$(( i + 1 ))
  project "badname${i}"
  worklog z.md closed
  run_hook "$P"
  ctx_without="$CTX"
  worklog "$name" active
  run_hook "$P"
  assert_eq "${name}: the hook exits 0" "$HOOK_CODE" "0"
  assert_same "${name}: the output equals the output without that file" "$CTX" "$ctx_without"
done

# ── Case 4: five active work logs ──────────────────────────────────────────
project five
for letter in a b c d e; do worklog "${letter}.md" active; done
five_notice=$(notice "$P" "$THREE_PATHS" "$(more 2)")
run_hook "$P"
assert_contains "five active work logs: the exact notice" "$CTX" "$five_notice"
mkdir -p "${P}/src"
run_hook "${P}/src"
assert_contains "five active work logs, hook started in a sub-folder: the same notice" "$CTX" "$five_notice"

# ── Case 5: an unreadable work log and a byte order mark ───────────────────
project unreadable
worklog a.md active
worklog b.md active
printf '\357\273\277<!-- Work log: status=active slug=c created=%s -->\n' "$CREATED" > "${P}/docs/worklogs/c.md"
chmod 000 "${P}/docs/worklogs/b.md"
if [ -r "${P}/docs/worklogs/b.md" ]; then
  echo "  note - b.md stays readable (root user?); it is removed, and only the byte order mark is checked"
  rm -f "${P}/docs/worklogs/b.md"
fi
run_hook "$P"
assert_eq "unreadable work log: the hook exits 0" "$HOOK_CODE" "0"
assert_contains "an unreadable work log hides neither readable one; the byte order mark one is named" \
  "$CTX" "$(notice "$P" "docs/worklogs/a.md, docs/worklogs/c.md")"

# ── Case 6: a root longer than 300 characters ──────────────────────────────
project "$(chars 200 a)/$(chars 200 b)"
worklog a.md active
run_hook "$P"
assert_contains "a root longer than 300 characters: its last 300 characters after …" \
  "$CTX" "$(notice "…${P: -300}" docs/worklogs/a.md)"
assert_absent "a root longer than 300 characters: the full root is not printed" "$CTX" "under ${P}:"

# ── Case 7: three, then four active work logs ──────────────────────────────
project three
for letter in a b c; do worklog "${letter}.md" active; done
run_hook "$P"
assert_contains "three active work logs: the exact notice, with no \" and \" text" \
  "$CTX" "$(notice "$P" "$THREE_PATHS")"
worklog d.md active
run_hook "$P"
assert_contains "four active work logs: the exact notice, with \"$(more 1)\"" \
  "$CTX" "$(notice "$P" "$THREE_PATHS" "$(more 1)")"

# ── Case 8: a root with a space and a glob character ───────────────────────
# The folder "with space x" matches the pattern "with space [x]". A hook that
# expanded file-name patterns in the list would name that folder's a.md in
# place of the project's; a hook that split the list on spaces would name
# parts of paths.
project "with space [x]"
for letter in a b c d; do worklog "${letter}.md" active; done
mkdir -p "${TMP}/with space x/docs/worklogs"
: > "${TMP}/with space x/docs/worklogs/a.md"
run_hook "$P"
assert_contains "a root with a space and a glob character, four active work logs: the exact notice" \
  "$CTX" "$(notice "$P" "$THREE_PATHS" "$(more 1)")"

# ── Case 9: a root of exactly 300 characters ───────────────────────────────
# Two folder names, because one folder name may hold at most 255 bytes.
rest=$(( 300 - ${#TMP} - 1 ))
half=$(( rest / 2 ))
project "$(chars "$half" c)/$(chars $(( rest - half - 1 )) d)"
assert_eq "the fixture root has exactly 300 characters" "${#P}" "300"
worklog a.md active
run_hook "$P"
assert_contains "a root of exactly 300 characters: printed whole, with no …" \
  "$CTX" "$(notice "$P" docs/worklogs/a.md)"

echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
