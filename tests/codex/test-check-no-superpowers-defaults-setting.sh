#!/usr/bin/env bash
# Unit test: check_no_superpowers_defaults_setting (tests/claude-code/test-helpers.sh)
#
# Every default-value case in the Claude Code and Codex behavioral suites
# depends on this function to abort early when a settings file pollutes the
# environment with one of the three superpowers session-default variables.
# Its own failure mode is silent — if the outer loop over the three variable
# names regresses, the behavioral suites run against a polluted environment
# and their default cases assert nothing. This test exercises the function
# directly, one fixture per variable, and checks only the "returns 1" half:
# the "returns 0" half is not reproducible on a machine that already sets one
# of the three variables in ~/.claude/settings.json or in the enterprise
# managed-settings file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../claude-code/test-helpers.sh
source "${REPO_ROOT}/tests/claude-code/test-helpers.sh"

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

for var in SUPERPOWERS_REVIEWERS_PER_LENS SUPERPOWERS_REVIEW_ROUNDS SUPERPOWERS_BATCH_TASK_CAP; do
  plugin_dir=$(mktemp -d)
  mkdir -p "$plugin_dir/.claude"
  fixture="$plugin_dir/.claude/settings.json"
  printf '{"env": {"%s": "3"}}\n' "$var" > "$fixture"

  output="$(check_no_superpowers_defaults_setting "$plugin_dir" 2>&1)" && status=0 || status=$?

  if [ "${status:-0}" -ne 1 ]; then
    bad "$var set in $fixture: expected exit 1, got ${status:-0}"
  else
    ok "$var set in $fixture: exits 1"
  fi

  if echo "$output" | grep -qF -- "$var"; then
    ok "$var set in $fixture: message names the variable"
  else
    bad "$var set in $fixture: message does not name the variable ($output)"
  fi

  if echo "$output" | grep -qF -- "$fixture"; then
    ok "$var set in $fixture: message names the fixture path"
  else
    bad "$var set in $fixture: message does not name the fixture path ($output)"
  fi

  rm -rf "$plugin_dir"
done

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
if [ "${FAIL}" -gt 0 ]; then
  exit 1
fi
