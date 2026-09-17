#!/usr/bin/env bash
# Unit test: hooks/session-start keeps its additionalContext at or under
# 10,000 characters, on an empty directory and on a directory whose workspace
# files are far larger than the budget.
#
# Why 10,000: Claude Code keeps a hook's additionalContext in the model's
# context only up to 10,000 characters. From 10,001 it writes the text to a
# file and keeps a 2,000-character preview (measured 2026-09-17, worklist row
# 37). Everything past the preview is never read: on this repository that was
# the Entry Sequence, every workspace file and the <superpowers-defaults>
# block that five skills read.
#
# What the hook must do to stay under the budget, and what is asserted here:
#   1. Inject only the first part of skills/using-superpowers/SKILL.md, the
#      text above the marker line; the Skill tool loads the whole file.
#   2. Add workspace files in priority order (state.md, the project-map-stale
#      note, session-log.md, known-issues.md, context-snapshot.json,
#      project-map.md), each whole when it fits the remaining budget, and
#      name the skipped ones in one <not-injected> line.
#   3. Keep the <superpowers-defaults> block last and complete.
#   4. Write every section wrapper with real newline bytes, not the two
#      characters backslash and n (a defect of the older wrappers).
# The injected skill part is pinned to INJECTION_PIN characters so that it
# cannot grow back over the budget silently.
#
# Hermetic like tests/codex/test-session-start-defaults-block.sh: no network
# (SUPERPOWERS_AUTO_UPDATE=0), a temporary HOME, CLAUDE_PLUGIN_ROOT set. The
# output is parsed with JSON.parse (Node), and lengths are measured as
# JavaScript String.length, the unit Claude Code's limit is measured in.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK="${REPO_ROOT}/hooks/session-start"
SKILL="${REPO_ROOT}/skills/using-superpowers/SKILL.md"
LIMIT=10000
INJECTION_PIN=6400
MARKER="session-start-injection-ends"
OPEN_TAG="<superpowers-defaults>"
CLOSE_TAG="</superpowers-defaults>"
NOT_INJECTED_TAG="<not-injected>"
NL=$'\n'

TMP_HOME=$(mktemp -d)
TMP_EMPTY=$(mktemp -d)
TMP_FULL=$(mktemp -d)
trap 'rm -rf "$TMP_HOME" "$TMP_EMPTY" "$TMP_FULL"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# run_hook_in <dir>: runs the hook with <dir> as the working directory and
# prints the additionalContext string of the Claude Code output branch.
run_hook_in() {
  local pass=()
  [ -n "${SYSTEMROOT:-}" ] && pass+=("SYSTEMROOT=$SYSTEMROOT")
  [ -n "${TEMP:-}" ] && pass+=("TEMP=$TEMP")
  (cd "$1" && env -i PATH="$PATH" HOME="$TMP_HOME" \
      CLAUDE_PLUGIN_ROOT="$REPO_ROOT" SUPERPOWERS_AUTO_UPDATE=0 \
      ${pass[@]+"${pass[@]}"} bash "$HOOK") \
    | node -e '
      const j = JSON.parse(require("fs").readFileSync(0, "utf8"));
      process.stdout.write(j.hookSpecificOutput.additionalContext);'
}

# js_length: prints the JavaScript String.length of standard input.
js_length() {
  node -e 'process.stdout.write(String(require("fs").readFileSync(0, "utf8").length));'
}

expected_block() {
  printf '\n\n%s\nreviewers-per-lens=1\nreview-rounds=3\nbatch-task-cap=3\n%s' "$OPEN_TAG" "$CLOSE_TAG"
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

# assert_common <case label> <context>: the checks every case must pass.
assert_common() {
  local label="$1" ctx="$2" len
  len=$(printf '%s' "$ctx" | js_length)
  if [ "$len" -le "$LIMIT" ]; then
    ok "${label}: ${len} characters, at or under ${LIMIT}"
  else
    bad "${label}: ${len} characters, over ${LIMIT}"
  fi
  assert_contains "${label}: context ends with the complete defaults block" "$ctx" "$(expected_block)"
  case "$ctx" in
    *"$(expected_block)") : ;;
    *) bad "${label}: the defaults block is not the last thing in the context" ;;
  esac
  assert_contains "${label}: </EXTREMELY_IMPORTANT> is present" "$ctx" "</EXTREMELY_IMPORTANT>"
  assert_contains "${label}: the Entry Sequence is injected" "$ctx" "## Entry Sequence"
  assert_contains "${label}: the complexity rules are injected" "$ctx" "### Hard overrides"
  assert_absent "${label}: the marker line itself is not injected" "$ctx" "$MARKER"
  assert_absent "${label}: text below the marker (the Routing Guide) is not injected" "$ctx" "## Routing Guide"
  # A real newline before each wrapper tag: the older wrappers were built
  # with a bash double-quoted "\n" and reached the model as backslash and n.
  assert_absent "${label}: no literal backslash-n sequence in the context" "$ctx" '\n'
}

echo "session-start: 10,000-character budget"

# ── Case 1: the skill file's injected part ──────────────────────────────────
marker_count=$(grep -c -F -- "$MARKER" "$SKILL" || true)
if [ "$marker_count" -eq 1 ]; then
  ok "SKILL.md carries the marker exactly once"
else
  bad "SKILL.md carries the marker ${marker_count} times, expected exactly 1"
fi
injected_len=$(node -e '
  const fs = require("fs");
  const [file, marker] = process.argv.slice(1);
  const lines = fs.readFileSync(file, "utf8").split("\n");
  let i = 0;
  if (lines[0] === "---") { i = 1; while (i < lines.length && lines[i] !== "---") i++; i++; }
  const body = [];
  for (; i < lines.length && !lines[i].includes(marker); i++) body.push(lines[i]);
  process.stdout.write(String(body.join("\n").length));' "$SKILL" "$MARKER")
if [ "$injected_len" -le "$INJECTION_PIN" ]; then
  ok "the injected skill part is ${injected_len} characters, at or under ${INJECTION_PIN}"
else
  bad "the injected skill part is ${injected_len} characters, over ${INJECTION_PIN}"
fi
below_marker=$(sed -n "/${MARKER}/,\$p" "$SKILL")
assert_contains "the Routing Guide stays in the file, below the marker" "$below_marker" "## Routing Guide"

# ── Case 2: empty directory, no git repository ─────────────────────────────
ctx_empty=$(run_hook_in "$TMP_EMPTY")
assert_common "empty directory" "$ctx_empty"
assert_absent "empty directory: nothing is reported as not injected" "$ctx_empty" "$NOT_INJECTED_TAG"

# ── Case 3: workspace files far larger than the budget ─────────────────────
# state.md and context-snapshot.json are small and must be injected whole;
# session-log.md, known-issues.md and project-map.md are each larger than the
# whole budget and must be named in the <not-injected> line instead. The
# repository has one commit whose hash differs from the map header's, so the
# project-map-stale note must appear even though the map itself does not.
filler() { # filler <lines> <prefix>: <lines> lines of about 100 characters
  local i
  for i in $(seq 1 "$1"); do
    printf '%s line %03d %s\n' "$2" "$i" "abcdefghij abcdefghij abcdefghij abcdefghij abcdefghij abcdefghij abcdef"
  done
}
(
  cd "$TMP_FULL"
  git init -q
  git -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m init
  {
    printf 'Current Goal: STATE-SENTINEL budget fixture, active task\n'
    filler 6 state
  } > state.md
  {
    printf '## 2026-01-01 10:00 [saved]\nGoal: SESSION-LOG-SENTINEL one\n'; filler 60 log
    printf '## 2026-01-02 10:00 [saved]\nGoal: SESSION-LOG-SENTINEL two\n'; filler 60 log
  } > session-log.md
  {
    local_i=1
    while [ "$local_i" -le 5 ]; do
      printf '## KNOWN-ISSUES-SENTINEL issue %d\n' "$local_i"; filler 25 issue
      local_i=$(( local_i + 1 ))
    done
  } > known-issues.md
  {
    printf '# Project Map\n*Generated 2026-01-01 | Git: 0000000*\n\n## Directory Structure\nPROJECT-MAP-SENTINEL\n'
    filler 70 map
    printf '\n## Critical Constraints\n- none\n\n## Hot Files\n- none\n'
  } > project-map.md
  printf '{"changed_files":["snapshot-sentinel.js"],"recent_commits":["abc1234 init"]}\n' > context-snapshot.json
)
ctx_full=$(run_hook_in "$TMP_FULL")
assert_common "large workspace files" "$ctx_full"
assert_contains "large workspace files: state.md is injected whole" "$ctx_full" "STATE-SENTINEL"
assert_contains "large workspace files: the <state> tag starts its own line" "$ctx_full" "${NL}<state>${NL}"
assert_contains "large workspace files: the project-map-stale note is injected" "$ctx_full" "<project-map-stale>"
assert_contains "large workspace files: context-snapshot.json is injected" "$ctx_full" "snapshot-sentinel.js"
assert_absent "large workspace files: session-log.md content is not injected" "$ctx_full" "SESSION-LOG-SENTINEL"
assert_absent "large workspace files: known-issues.md content is not injected" "$ctx_full" "KNOWN-ISSUES-SENTINEL"
assert_absent "large workspace files: project-map.md content is not injected" "$ctx_full" "PROJECT-MAP-SENTINEL"
not_injected_line=$(printf '%s' "$ctx_full" | grep -F -- "$NOT_INJECTED_TAG" || true)
assert_contains "large workspace files: one <not-injected> line is present" "$not_injected_line" "$NOT_INJECTED_TAG"
for f in session-log.md known-issues.md project-map.md; do
  assert_contains "large workspace files: <not-injected> names ${f}" "$not_injected_line" "$f"
done
for f in state.md context-snapshot.json; do
  assert_absent "large workspace files: <not-injected> does not name ${f}" "$not_injected_line" "$f"
done
case "$ctx_full" in
  *"$NOT_INJECTED_TAG"*"$OPEN_TAG"*) ok "large workspace files: the <not-injected> line precedes the defaults block" ;;
  *) bad "large workspace files: the <not-injected> line does not precede the defaults block" ;;
esac

echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
