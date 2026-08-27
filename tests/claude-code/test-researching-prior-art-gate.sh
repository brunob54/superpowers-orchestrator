#!/usr/bin/env bash
# Test: brainstorming research gate — gate-message contract (behavioral, slow)
#
# Seeds a temp git repo and asks for a headless brainstorm of a decision that
# matches the research trigger predicate (adds a dependency-manifest entry).
# Asserts, per docs/superpowers-orchestrator/2026-08-22-researching-prior-art/specs/researching-prior-art-design.md:
#   (a) the gate message's fixed lines appear exactly
#   (b) the Candidates and Suggested-N lines match by pattern
#   (c) the bracketed reversibility sentence is absent (the seeded decision
#       commits no public interface, stored format, or wire protocol)
#   (d) no research dispatch happens before the N answer
#   (e) the plugin dev repo is unmutated
#
# Requires the INSTALLED plugin to include the updated brainstorming skill —
# run tools/sync-dev-install.sh after editing skills/ before running this.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/timeout-shim.sh"
source "$SCRIPT_DIR/test-helpers.sh"

TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project '$TEST_PROJECT'" EXIT

cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@example.com"
git config user.name "Test"

cat > package.json << 'PKG_EOF'
{
  "name": "gate-fixture",
  "version": "1.0.0",
  "dependencies": {}
}
PKG_EOF
git add package.json
git commit --quiet -m "base: empty fixture"

PROMPT="Use the brainstorming skill on the project at $TEST_PROJECT to design this feature: add HTTP request retry logic using one of the npm packages got or axios (this will add a new dependency to package.json). Assume sensible defaults instead of asking clarifying questions. When you reach the research gate, present the gate message and then stop — I have not chosen N yet, so do not pick one and do not dispatch any research."

PLUGIN_HEAD_BEFORE=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_BEFORE=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)

# Inner budget (1700s) sits below the runner's outer --timeout 1800 so a hang
# is killed here first: the timeout assertion can fire and the keep-project
# trap still runs (the outer timeout would kill this whole script instead).
CLAUDE_STATUS=0
cd "$PLUGIN_DIR" && timeout 1700 claude -p "$PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output.txt" || CLAUDE_STATUS=${PIPESTATUS[0]}

cd "$TEST_PROJECT"
FAILURES=0

if [ "$CLAUDE_STATUS" -eq 124 ] || [ "$CLAUDE_STATUS" -eq 143 ]; then
    echo "FAIL: the claude run was killed by the 1700s inner timeout (exit $CLAUDE_STATUS)"
    FAILURES=$((FAILURES+1))
fi

PLUGIN_HEAD_AFTER=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_AFTER=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)
if [ "$PLUGIN_HEAD_AFTER" != "$PLUGIN_HEAD_BEFORE" ] || [ "$PLUGIN_STATUS_AFTER" != "$PLUGIN_STATUS_BEFORE" ]; then
    echo "FAIL(e): the run mutated the plugin dev repo (misanchored skill?)"
    FAILURES=$((FAILURES+1))
fi

OUT="$TEST_PROJECT/output.txt"

# (a) fixed gate-message lines, exact substrings
if ! grep -qF "Research gate: this decision triggers prior-art research." "$OUT"; then
    echo "FAIL(a): gate opening line missing or paraphrased"
    FAILURES=$((FAILURES+1))
fi
if ! grep -qF "Reply with a number, or 0 to" "$OUT"; then
    echo "FAIL(a): gate reply instruction missing or paraphrased"
    FAILURES=$((FAILURES+1))
fi
if ! grep -qF "committed to this repository" "$OUT"; then
    echo "FAIL(a): consent disclosure's repository-commit clause missing or paraphrased"
    FAILURES=$((FAILURES+1))
fi
if ! grep -qF "cached under" "$OUT"; then
    echo "FAIL(a): consent disclosure's caching clause missing or paraphrased"
    FAILURES=$((FAILURES+1))
fi

# (b) Candidates and Suggested-N lines, by pattern
if ! grep -qE "Candidates: .*(got|axios)" "$OUT"; then
    echo "FAIL(b): Candidates line missing or names no seeded candidate"
    FAILURES=$((FAILURES+1))
fi
if ! grep -qE "How many research subagents should I dispatch\? Suggested N=\`?[0-9]+" "$OUT"; then
    echo "FAIL(b): Suggested-N line missing or malformed"
    FAILURES=$((FAILURES+1))
fi

# (c) the bracketed reversibility sentence must be absent for this decision
if grep -qF "This choice is difficult to reverse" "$OUT"; then
    echo "FAIL(c): reversibility sentence present for an easily-reversible decision"
    FAILURES=$((FAILURES+1))
fi

# (d) no research dispatch before the N answer
if grep -qF "<!-- research report -->" "$OUT"; then
    echo "FAIL(d): a research report marker appeared before any N answer"
    FAILURES=$((FAILURES+1))
fi
if [ -d "$TEST_PROJECT/.superpowers/research" ]; then
    echo "FAIL(d): .superpowers/research was created before any N answer"
    FAILURES=$((FAILURES+1))
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: research-gate behavioral test"
else
    trap - EXIT
    echo "FAILED: $FAILURES assertion(s); project kept for debugging: $TEST_PROJECT (transcript in output.txt — clean up manually)"
    exit 1
fi
