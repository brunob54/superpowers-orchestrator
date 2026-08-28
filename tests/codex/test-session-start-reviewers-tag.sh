#!/usr/bin/env bash
# Unit test: hooks/session-start emits <reviewers-per-lens><m></reviewers-per-lens>
# when SUPERPOWERS_REVIEWERS_PER_LENS is an integer from 1 to 5, and emits no
# tag otherwise (unset, 0, 6, 10, abc).
#
# The hook is not a pure function of the variable, so every run is hermetic:
#   - SUPERPOWERS_AUTO_UPDATE=0   -> no network fetch, no fast-forward of the checkout
#   - an empty working directory -> no project-map.md, state.md, session-log.md,
#                                   known-issues.md or context-snapshot.json is read
#   - a temporary HOME           -> the hook writes ~/.claude/hooks-logs/update-check.cache
#   - CLAUDE_PLUGIN_ROOT set     -> the Claude Code output branch is exercised
# The output is parsed with JSON.parse (Node), so a malformed JSON document fails
# the test as well.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK="${REPO_ROOT}/hooks/session-start"
VAR_NAME="SUPERPOWERS_REVIEWERS_PER_LENS"
TAG_OPEN="<reviewers-per-lens>"
TAG_CLOSE="</reviewers-per-lens>"

TMP_HOME=$(mktemp -d)
TMP_CWD=$(mktemp -d)
trap 'rm -rf "$TMP_HOME" "$TMP_CWD"' EXIT

PASS=0
FAIL=0

ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# run_hook [VAR=value]
# Runs the hook in the hermetic environment, optionally with one extra
# variable assignment, and prints the additionalContext string of the Claude
# Code output branch. JSON.parse doubles as a well-formedness check.
# SYSTEMROOT and TEMP pass through when they are set: on Windows Git Bash the
# native git.exe the hook calls can need them to start; on macOS and Linux
# they are unset and nothing is added.
run_hook() {
  local extra=()
  [ $# -gt 0 ] && extra=("$1")
  (cd "$TMP_CWD" && env -i PATH="$PATH" HOME="$TMP_HOME" \
      CLAUDE_PLUGIN_ROOT="$REPO_ROOT" SUPERPOWERS_AUTO_UPDATE=0 \
      ${SYSTEMROOT:+SYSTEMROOT="$SYSTEMROOT"} ${TEMP:+TEMP="$TEMP"} \
      ${extra[@]+"${extra[@]}"} bash "$HOOK") \
    | node -e '
      const j = JSON.parse(require("fs").readFileSync(0, "utf8"));
      process.stdout.write(j.hookSpecificOutput.additionalContext);'
}

# expect_tag <value>: the tag with that value is present and ends the context
expect_tag() {
  local value="$1" ctx
  ctx=$(run_hook "${VAR_NAME}=${value}")
  case "$ctx" in
    *"${TAG_OPEN}${value}${TAG_CLOSE}") ok "${VAR_NAME}=${value} emits ${TAG_OPEN}${value}${TAG_CLOSE} at the end of the context" ;;
    *) bad "${VAR_NAME}=${value} does not end the context with ${TAG_OPEN}${value}${TAG_CLOSE}" ;;
  esac
}

# expect_no_tag <label> [VAR=value]: no tag at all in the context
expect_no_tag() {
  local label="$1" ctx
  shift
  ctx=$(run_hook "$@")
  case "$ctx" in
    *"${TAG_OPEN}"*) bad "${label} emits a tag" ;;
    *) ok "${label} emits no tag" ;;
  esac
}

echo "session-start: <reviewers-per-lens> tag"
for v in 1 3 5; do
  expect_tag "$v"
done
expect_no_tag "unset ${VAR_NAME}"
for v in 0 6 10 abc; do
  expect_no_tag "${VAR_NAME}=${v}" "${VAR_NAME}=${v}"
done

echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
