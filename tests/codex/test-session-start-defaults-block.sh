#!/usr/bin/env bash
# Unit test: hooks/session-start appends the <superpowers-defaults> block to
# the session context, carrying one name=value line per parameter on its own
# physical line. The block is always complete — every parameter is emitted
# even when its value falls back to the hardcoded default — and it is the
# last thing in the context, after every embedded workspace file.
#
# The assertions compare the EXACT emitted string, not a substring of one
# line. That is deliberate: if the block were built with a bash double-quoted
# "\n" it would reach the model as a single escaped line, and a model shown
# one line often still extracts the values, so the failure would be
# intermittent and per-session rather than a clean fallback.
#
# The hook is not a pure function of the variables, so every run is hermetic:
#   - SUPERPOWERS_AUTO_UPDATE=0   -> no network fetch, no fast-forward
#   - an empty working directory -> no project-map.md, state.md, session-log.md,
#                                   known-issues.md or context-snapshot.json
#   - a temporary HOME           -> the hook writes ~/.claude/hooks-logs/...
#   - CLAUDE_PLUGIN_ROOT set     -> the Claude Code output branch is exercised
# The output is parsed with JSON.parse (Node), so malformed JSON fails too.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK="${REPO_ROOT}/hooks/session-start"
OPEN_TAG="<superpowers-defaults>"
CLOSE_TAG="</superpowers-defaults>"

TMP_HOME=$(mktemp -d)
TMP_CWD=$(mktemp -d)
trap 'rm -rf "$TMP_HOME" "$TMP_CWD"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# run_hook [VAR=value ...]
# Runs the hook in the hermetic environment with any number of extra variable
# assignments and prints the additionalContext string of the Claude Code
# output branch. SYSTEMROOT and TEMP pass through when set: on Windows Git
# Bash the native git.exe the hook calls can need them to start.
run_hook() {
  local extra=("$@")
  # Built as an array and expanded quoted: a Windows TEMP holding a space
  # (C:\Users\Foo Bar\AppData\Local\Temp) would word-split out of an
  # unquoted ${TEMP:+TEMP="$TEMP"}, and env would then treat the fragment
  # without an "=" as the command to run.
  local pass=()
  [ -n "${SYSTEMROOT:-}" ] && pass+=("SYSTEMROOT=$SYSTEMROOT")
  [ -n "${TEMP:-}" ] && pass+=("TEMP=$TEMP")
  (cd "$TMP_CWD" && env -i PATH="$PATH" HOME="$TMP_HOME" \
      CLAUDE_PLUGIN_ROOT="$REPO_ROOT" SUPERPOWERS_AUTO_UPDATE=0 \
      ${pass[@]+"${pass[@]}"} \
      ${extra[@]+"${extra[@]}"} bash "$HOOK") \
    | node -e '
      const j = JSON.parse(require("fs").readFileSync(0, "utf8"));
      process.stdout.write(j.hookSpecificOutput.additionalContext);'
}

# expected_block <m> <n> <cap>: the exact string the hook must append.
# Two leading newline bytes, no trailing newline after the closing delimiter.
# Command substitution strips trailing newlines only, so the leading pair
# survives and the string is unchanged.
expected_block() {
  printf '\n\n%s\nreviewers-per-lens=%s\nreview-rounds=%s\nbatch-task-cap=%s\n%s' \
    "$OPEN_TAG" "$1" "$2" "$3" "$CLOSE_TAG"
}

# expect_block <label> <m> <n> <cap> [VAR=value ...]
expect_block() {
  local label="$1" m="$2" n="$3" cap="$4" ctx want
  shift 4
  ctx=$(run_hook "$@")
  want=$(expected_block "$m" "$n" "$cap")
  case "$ctx" in
    *"$want") ok "${label} -> ${m}/${n}/${cap}, exact block at the end of the context" ;;
    *) bad "${label} -> the context does not end with the exact ${m}/${n}/${cap} block" ;;
  esac
}

echo "session-start: <superpowers-defaults> block"

# Nothing set: every line is still emitted, each at its hardcoded default.
expect_block "no variable set" 1 3 3

# Accepted values, per parameter. Each passes through unchanged, and the two
# parameters not under test stay at their hardcoded defaults.
#
# Three rows carry no information on their own: reviewers-per-lens=1,
# review-rounds=3 and batch-task-cap=3 assert the same block the unset case
# asserts, so they cannot tell a correct read of the variable from the
# fallback. The other values in each loop carry it.
for v in 1 2 3 4 5; do
  expect_block "SUPERPOWERS_REVIEWERS_PER_LENS=${v}" "$v" 3 3 "SUPERPOWERS_REVIEWERS_PER_LENS=${v}"
done
for v in 1 2 3 4 5 6 7 8 9 10; do
  expect_block "SUPERPOWERS_REVIEW_ROUNDS=${v}" 1 "$v" 3 "SUPERPOWERS_REVIEW_ROUNDS=${v}"
done
for v in 1 2 3 4 5; do
  expect_block "SUPERPOWERS_BATCH_TASK_CAP=${v}" 1 3 "$v" "SUPERPOWERS_BATCH_TASK_CAP=${v}"
done

# All three at once, at the top of each accepted range.
expect_block "all three set" 5 10 5 \
  "SUPERPOWERS_REVIEWERS_PER_LENS=5" "SUPERPOWERS_REVIEW_ROUNDS=10" "SUPERPOWERS_BATCH_TASK_CAP=5"

# Rejected forms, shared by all three parameters. Literal case alternatives
# reject each of these exactly; a character class would not.
for v in " 3" "+3" "03" "3.0" "-1" "word" ""; do
  expect_block "SUPERPOWERS_REVIEWERS_PER_LENS='${v}'" 1 3 3 "SUPERPOWERS_REVIEWERS_PER_LENS=${v}"
  expect_block "SUPERPOWERS_REVIEW_ROUNDS='${v}'" 1 3 3 "SUPERPOWERS_REVIEW_ROUNDS=${v}"
  expect_block "SUPERPOWERS_BATCH_TASK_CAP='${v}'" 1 3 3 "SUPERPOWERS_BATCH_TASK_CAP=${v}"
done

# Rejected values, per parameter. 6 through 10 are ACCEPTED for review-rounds
# and must never appear in its rejected set — that range is the capability
# this design adds.
for v in 0 6 11; do
  expect_block "SUPERPOWERS_REVIEWERS_PER_LENS=${v}" 1 3 3 "SUPERPOWERS_REVIEWERS_PER_LENS=${v}"
  expect_block "SUPERPOWERS_BATCH_TASK_CAP=${v}" 1 3 3 "SUPERPOWERS_BATCH_TASK_CAP=${v}"
done
for v in 0 11; do
  expect_block "SUPERPOWERS_REVIEW_ROUNDS=${v}" 1 3 3 "SUPERPOWERS_REVIEW_ROUNDS=${v}"
done

# A workspace file the hook embeds (state.md) can itself contain a decoy
# block. The hook appends its own block AFTER every embedded workspace-file
# block, so only the LAST complete block counts. state.md is embedded whole
# with cat and has no size cap (the 200-line threshold governs project-map.md
# only), so the fixture's size does not matter; the decoy text is asserted
# present before the ordering is asserted,
# so the check cannot pass by the workspace file never being embedded at all.
write_decoy_state() {
  cat > "$TMP_CWD/state.md" <<'STATE_EOF'
Current Goal: decoy workspace state, not a resume point
<superpowers-defaults>
reviewers-per-lens=9
review-rounds=9
batch-task-cap=9
</superpowers-defaults>
STATE_EOF
}

# expect_decoy_loses <label> <m> <n> <cap> [VAR=value ...]
# The case that matters most is the variable UNSET: with no fallback emission
# the decoy would be the only block in the context and repository content
# would choose the parameters. Line numbers are not usable here — most of the
# hook's boilerplate uses literal two-character "\n" sequences rather than
# real newlines — so ordering is checked with glob substring matching.
expect_decoy_loses() {
  local label="$1" m="$2" n="$3" cap="$4" ctx want
  local decoy="reviewers-per-lens=9"
  shift 4
  write_decoy_state
  ctx=$(run_hook "$@")
  rm -f "$TMP_CWD/state.md"
  want=$(expected_block "$m" "$n" "$cap")
  case "$ctx" in
    *"$decoy"*"$CLOSE_TAG"*) : ;;
    *) bad "${label}: the decoy block from state.md is absent or incomplete — the workspace file was not embedded, or its closing delimiter was not written literally"; return ;;
  esac
  case "$ctx" in
    *"$decoy"*"$want") ok "${label}: the workspace decoy precedes the hook's block, which ends the context" ;;
    *) bad "${label}: the context does not end with the hook's block after the decoy" ;;
  esac
}

expect_decoy_loses "decoy, no variable set" 1 3 3
expect_decoy_loses "decoy, SUPERPOWERS_REVIEW_ROUNDS=8" 1 8 3 "SUPERPOWERS_REVIEW_ROUNDS=8"

echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
