#!/usr/bin/env bash
# Unit test: check_no_superpowers_defaults_setting (tests/claude-code/test-helpers.sh)
#
# Every default-value case in the Claude Code and Codex behavioral suites
# depends on this function to abort early when a settings file pollutes the
# environment with one of the three superpowers session-default variables.
# Its own failure mode is silent — if the outer loop over the three variable
# names, or the inner loop over the settings paths it checks, regresses, the
# behavioral suites run against a polluted environment and their default
# cases assert nothing.
#
# Every call below sets HOME and CLAUDE_CONFIG_DIR to fresh temporary
# directories for the duration of that one call, so this test never reads,
# and is never polluted by, the real machine's settings files at those two
# roots. The two absolute enterprise managed-settings.json paths cannot be
# redirected this way: if either already sets one of the three variables on
# the machine running this test, the "returns 0" assertions below cannot be
# trusted, so the test detects that up front and reports itself skipped
# (exit 0) instead of failing for an environment reason.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../claude-code/test-helpers.sh
source "${REPO_ROOT}/tests/claude-code/test-helpers.sh"

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# The two absolute enterprise paths are outside HOME and CLAUDE_CONFIG_DIR,
# so this test cannot redirect them elsewhere. If either already carries one
# of the three variables on the machine running this test, the "returns 0"
# assertions below are not trustworthy: report the whole test skipped.
for enterprise_f in "/Library/Application Support/ClaudeCode/managed-settings.json" \
                    "/etc/claude-code/managed-settings.json"; do
  if [ -f "$enterprise_f" ]; then
    for var in SUPERPOWERS_REVIEWERS_PER_LENS SUPERPOWERS_REVIEW_ROUNDS SUPERPOWERS_BATCH_TASK_CAP; do
      if grep -qE "\"$var\"[[:space:]]*:" "$enterprise_f"; then
        echo "SKIP: $var is set in $enterprise_f; this test cannot redirect that path."
        echo ""
        echo "Results: 0 passed, 0 failed (skipped)"
        exit 0
      fi
    done
  fi
done

# run_helper <plugin_dir> <home_dir> <config_dir>: calls the function under
# test with HOME and CLAUDE_CONFIG_DIR pinned to the given temporary
# directories for this one call only. Sets the globals HELPER_STATUS and
# HELPER_OUTPUT.
run_helper() {
  local plugin_dir="$1" home_dir="$2" config_dir="$3"
  HELPER_OUTPUT="$(HOME="$home_dir" CLAUDE_CONFIG_DIR="$config_dir" check_no_superpowers_defaults_setting "$plugin_dir" 2>&1)" && HELPER_STATUS=0 || HELPER_STATUS=$?
}

# One fixture per variable, at the plugin-relative settings path.
for var in SUPERPOWERS_REVIEWERS_PER_LENS SUPERPOWERS_REVIEW_ROUNDS SUPERPOWERS_BATCH_TASK_CAP; do
  home_dir=$(mktemp -d)
  config_dir=$(mktemp -d)
  plugin_dir=$(mktemp -d)
  mkdir -p "$plugin_dir/.claude"
  fixture="$plugin_dir/.claude/settings.json"
  printf '{"env": {"%s": "3"}}\n' "$var" > "$fixture"

  run_helper "$plugin_dir" "$home_dir" "$config_dir"

  if [ "$HELPER_STATUS" -ne 1 ]; then
    bad "$var set in $fixture: expected exit 1, got $HELPER_STATUS"
  else
    ok "$var set in $fixture: exits 1"
  fi

  if echo "$HELPER_OUTPUT" | grep -qF -- "$var"; then
    ok "$var set in $fixture: message names the variable"
  else
    bad "$var set in $fixture: message does not name the variable ($HELPER_OUTPUT)"
  fi

  if echo "$HELPER_OUTPUT" | grep -qF -- "$fixture"; then
    ok "$var set in $fixture: message names the fixture path"
  else
    bad "$var set in $fixture: message does not name the fixture path ($HELPER_OUTPUT)"
  fi

  rm -rf "$home_dir" "$config_dir" "$plugin_dir"
done

# One fixture per RELATIVE settings path the helper checks
# (tests/claude-code/test-helpers.sh): the outer variable loop above only
# ever writes to the plugin path, so a path dropped from the helper's inner
# loop would otherwise go uncaught.
for path_case in "HOME/.claude/settings.json" "HOME/.claude/settings.local.json" \
                  "CONFIG_DIR/settings.json" "CONFIG_DIR/settings.local.json" \
                  "PLUGIN_DIR/.claude/settings.json" "PLUGIN_DIR/.claude/settings.local.json"; do
  home_dir=$(mktemp -d)
  config_dir=$(mktemp -d)
  plugin_dir=$(mktemp -d)
  mkdir -p "$home_dir/.claude" "$plugin_dir/.claude"

  case "$path_case" in
    HOME/*) fixture="$home_dir/${path_case#HOME/}" ;;
    CONFIG_DIR/*) fixture="$config_dir/${path_case#CONFIG_DIR/}" ;;
    PLUGIN_DIR/*) fixture="$plugin_dir/${path_case#PLUGIN_DIR/}" ;;
  esac
  printf '{"env": {"SUPERPOWERS_REVIEWERS_PER_LENS": "3"}}\n' > "$fixture"

  run_helper "$plugin_dir" "$home_dir" "$config_dir"

  if [ "$HELPER_STATUS" -ne 1 ]; then
    bad "$path_case: expected exit 1, got $HELPER_STATUS"
  else
    ok "$path_case: exits 1"
  fi

  if echo "$HELPER_OUTPUT" | grep -qF -- "$fixture"; then
    ok "$path_case: message names the fixture path"
  else
    bad "$path_case: message does not name the fixture path ($HELPER_OUTPUT)"
  fi

  rm -rf "$home_dir" "$config_dir" "$plugin_dir"
done

# Clean case: no fixture anywhere under the temporary HOME, CLAUDE_CONFIG_DIR
# or plugin directory. Proves the helper returns 0 when nothing pollutes any
# of the six relative paths.
home_dir=$(mktemp -d)
config_dir=$(mktemp -d)
plugin_dir=$(mktemp -d)
run_helper "$plugin_dir" "$home_dir" "$config_dir"
if [ "$HELPER_STATUS" -eq 0 ]; then
  ok "no fixture anywhere: exits 0"
else
  bad "no fixture anywhere: expected exit 0, got $HELPER_STATUS ($HELPER_OUTPUT)"
fi
rm -rf "$home_dir" "$config_dir" "$plugin_dir"

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
if [ "${FAIL}" -gt 0 ]; then
  exit 1
fi
