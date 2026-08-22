#!/usr/bin/env bash
# Test: researching-prior-art skill — merged-report contract (behavioral, slow)
#
# Seeds a temp git repo whose package.json names a real small library (ms),
# invokes the skill headlessly with a fixed decision and N=2, and asserts the
# contract from docs/specs/2026-08-22-researching-prior-art-design.md:
#   (a) .superpowers/research/<slug>-research-report.md exists
#   (b) its first line is exactly the research report marker
#   (c) it contains at least one citation (URL or clone file path) and one
#       quoted snippet
#   (d) it contains a "Sources fetched" section
#   (e) the plugin dev repo is unmutated (HEAD + status snapshot)
#   (f) the run was not killed by the timeout
# No assertions on hardcoded git history.
#
# Requires the INSTALLED plugin to include researching-prior-art — run
# tools/sync-dev-install.sh after editing skills/ before running this.

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
  "name": "research-fixture",
  "version": "1.0.0",
  "dependencies": {
    "ms": "2.1.3"
  }
}
PKG_EOF
git add package.json
git commit --quiet -m "base: fixture with ms dependency"

PROMPT="Invoke the superpowers-orchestrator:researching-prior-art skill on the git repository at $TEST_PROJECT. Decision: verify that the npm package ms (pinned at 2.1.3 in package.json) still fits this project's duration-parsing needs — this decision depends on version-sensitive external API behavior. Candidates: ms (npm, canonical name ms). N=2. Topic slug: ms-duration. Do not ask me any questions — proceed to completion."

# Safety net: a misanchored run must not mutate the dev repo.
# --ignored=matching because .superpowers/ (self-.gitignore, written in Task 1
# Step 0) and state.md (committed .gitignore) are excluded here — exactly the
# paths the skill under test writes.
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

# (f) GNU timeout reports 124; the tests/lib/timeout-shim.sh fallback reports 143.
if [ "$CLAUDE_STATUS" -eq 124 ] || [ "$CLAUDE_STATUS" -eq 143 ]; then
    echo "FAIL(f): the claude run was killed by the 1700s inner timeout (exit $CLAUDE_STATUS)"
    FAILURES=$((FAILURES+1))
fi

PLUGIN_HEAD_AFTER=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_AFTER=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)
if [ "$PLUGIN_HEAD_AFTER" != "$PLUGIN_HEAD_BEFORE" ] || [ "$PLUGIN_STATUS_AFTER" != "$PLUGIN_STATUS_BEFORE" ]; then
    echo "FAIL(e): the run mutated the plugin dev repo (misanchored skill?)"
    echo "  Inspect: git -C $PLUGIN_DIR status --porcelain; git -C $PLUGIN_DIR diff"
    FAILURES=$((FAILURES+1))
fi

REPORT="$TEST_PROJECT/.superpowers/research/ms-duration-research-report.md"
if [ ! -f "$REPORT" ]; then
    echo "FAIL(a): merged report not created at $REPORT"
    FAILURES=$((FAILURES+1))
else
    if [ "$(head -1 "$REPORT")" != "<!-- research report -->" ]; then
        echo "FAIL(b): first line of the merged report is not the research report marker"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qE 'https?://|\.superpowers/research/clones/' "$REPORT"; then
        echo "FAIL(c): no citation (URL or clone file path) found in the merged report"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qE '"[^"]{10,}"|`[^`]{10,}`' "$REPORT"; then
        echo "FAIL(c): no quoted snippet found in the merged report"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qi 'Sources fetched' "$REPORT"; then
        echo "FAIL(d): merged report has no 'Sources fetched' section"
        FAILURES=$((FAILURES+1))
    fi
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: researching-prior-art behavioral test"
else
    trap - EXIT
    echo "FAILED: $FAILURES assertion(s); project kept for debugging: $TEST_PROJECT (transcript in output.txt — clean up manually)"
    exit 1
fi
