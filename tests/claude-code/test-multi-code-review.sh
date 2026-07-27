#!/usr/bin/env bash
# Test: multi-code-review skill — N-round whole-branch review loop (behavioral, slow)
#
# Seeds a temp git repo with a base commit and a branch carrying a blatant
# planted defect, invokes the skill headlessly with N=2, and asserts the
# review-log contract from docs/specs/2026-07-27-multi-code-review-design.md:
#   (a) .superpowers/reviews/*-review-log.md exists with a Round 1 entry
#   (b) every enumerated Critical/Important disposition uses the canonical
#       vocabulary (fixed / rejected: / user-decision / unresolved:)
#   (c) a fix commit exists OR no disposition claims "fixed"
#   (d) fix commits (if any) use generic subjects — no finding text
#   (f) the run was not killed by the timeout
#   (g)/(h) the loop ran Round 2 and wrote its completion marker
#
# Requires the INSTALLED plugin to include multi-code-review — reinstall the
# plugin cache after editing skills/ before running this.

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

cat > sum.js << 'BASE_EOF'
function sumFirstN(arr, n) {
  let total = 0;
  for (let i = 0; i < n; i++) total += arr[i];
  return total;
}
module.exports = { sumFirstN };
BASE_EOF
git add sum.js
git commit --quiet -m "base: sumFirstN"
BASE_SHA=$(git rev-parse HEAD)

git checkout --quiet -b feature-under-review
cat > sum.js << 'DEFECT_EOF'
function sumFirstN(arr, n) {
  // BUG (planted, blatant): off-by-one reads past n and past the array end
  let total = 0;
  for (let i = 0; i <= n; i++) total += arr[i];
  return total;
}
module.exports = { sumFirstN };
DEFECT_EOF
cat > sum.test.js << 'TEST_EOF'
// Planted weak test: asserts nothing about the result
const { sumFirstN } = require('./sum');
sumFirstN([1, 2, 3], 2);
console.log('ok');
TEST_EOF
git add sum.js sum.test.js
git commit --quiet -m "feature: extend sumFirstN"
SEEDED_HEAD_SHA=$(git rev-parse HEAD)

PROMPT="Invoke the superpowers-optimized:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-under-review) with BASE $BASE_SHA and N=2. Do not ask me any questions — use N=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."

# Safety net: the skill commits; a misanchored run must not mutate the dev repo.
PLUGIN_HEAD_BEFORE=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_BEFORE=$(git -C "$PLUGIN_DIR" status --porcelain | shasum | cut -d' ' -f1)

CLAUDE_STATUS=0
cd "$PLUGIN_DIR" && timeout 1800 claude -p "$PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output.txt" || CLAUDE_STATUS=${PIPESTATUS[0]}

cd "$TEST_PROJECT"
FAILURES=0

# (f) the run must not have been killed by the timeout: GNU timeout reports
#     124, the tests/lib/timeout-shim.sh fallback reports 143 (SIGTERM).
if [ "$CLAUDE_STATUS" -eq 124 ] || [ "$CLAUDE_STATUS" -eq 143 ]; then
    echo "FAIL(f): the claude run was killed by the 1800s timeout (exit $CLAUDE_STATUS) — the loop never finished"
    FAILURES=$((FAILURES+1))
fi

PLUGIN_HEAD_AFTER=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_AFTER=$(git -C "$PLUGIN_DIR" status --porcelain | shasum | cut -d' ' -f1)
if [ "$PLUGIN_HEAD_AFTER" != "$PLUGIN_HEAD_BEFORE" ] || [ "$PLUGIN_STATUS_AFTER" != "$PLUGIN_STATUS_BEFORE" ]; then
    echo "FAIL(e): the run mutated the plugin dev repo (misanchored skill?)"
    echo "  Inspect $PLUGIN_DIR; recover with: git -C $PLUGIN_DIR reset --hard $PLUGIN_HEAD_BEFORE"
    FAILURES=$((FAILURES+1))
fi

LOG=$(ls .superpowers/reviews/*-review-log.md 2>/dev/null | head -1 || true)

if [ -z "$LOG" ] || [ ! -f "$LOG" ]; then
    echo "FAIL(a): no .superpowers/reviews/*-review-log.md created"
    FAILURES=$((FAILURES+1))
else
    if ! grep -q "^## Round 1" "$LOG"; then
        echo "FAIL(a): review log has no '## Round 1' entry"
        FAILURES=$((FAILURES+1))
    fi
    # (g) the N=2 loop ran its second round
    if ! grep -q "^## Round 2 — " "$LOG"; then
        echo "FAIL(g): review log has no '## Round 2' entry — the loop did not run both rounds"
        FAILURES=$((FAILURES+1))
    fi
    # (h) the loop reached its completion marker
    if ! grep -q "^_Completed — " "$LOG"; then
        echo "FAIL(h): review log has no '_Completed — ' marker — the loop did not finish"
        FAILURES=$((FAILURES+1))
    fi
    # (b) every enumerated C/I disposition line uses canonical vocabulary,
    #     anchored to the disposition position (not matched anywhere on the line)
    BAD_DISPO=$(grep -E "^- \[(C|I)[0-9]+\]" "$LOG" | grep -vE "^- \[(C|I)[0-9]+\] (fixed — |rejected: |user-decision|unresolved: )" || true)
    if [ -n "$BAD_DISPO" ]; then
        echo "FAIL(b): non-canonical Critical/Important disposition(s):"
        echo "$BAD_DISPO"
        FAILURES=$((FAILURES+1))
    fi
    # (c) "fixed" dispositions require at least one commit beyond the seeded two
    COMMITS_NOW=$(git rev-list --count HEAD)
    if grep -qE "^- \[(C|I|M)[0-9]+\] fixed — " "$LOG" && [ "$COMMITS_NOW" -le 2 ]; then
        echo "FAIL(c): log claims fixed findings but no fix commit exists"
        FAILURES=$((FAILURES+1))
    fi
    # (d) fix commits use generic subjects — selected by range from the seeded
    #     branch tip, so no assumption about history shape or commit counts
    NON_GENERIC=$(git log --format=%s "$SEEDED_HEAD_SHA..HEAD" | grep -vE "^review fixes \(round [0-9]+\)$" || true)
    if [ -n "$NON_GENERIC" ]; then
        echo "FAIL(d): fix commit subject(s) not generic:"
        echo "$NON_GENERIC"
        FAILURES=$((FAILURES+1))
    fi
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: multi-code-review behavioral test"
else
    trap - EXIT
    echo "FAILED: $FAILURES assertion(s); project kept for debugging: $TEST_PROJECT (transcript in output.txt — clean up manually)"
    exit 1
fi
