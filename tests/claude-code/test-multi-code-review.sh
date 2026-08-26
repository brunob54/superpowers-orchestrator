#!/usr/bin/env bash
# Test: multi-code-review skill — N-round whole-branch review loop (behavioral, slow)
#
# Seeds a temp git repo with a base commit and a branch carrying a blatant
# planted defect, invokes the skill headlessly with N=2, and asserts the
# review-log contract from docs/superpowers-orchestrator/2026-07-27-multi-code-review/specs/multi-code-review-design.md:
#   (a) .superpowers/reviews/*-review-log.md exists with a Round 1 entry
#   (b) every enumerated Critical/Important disposition uses the canonical
#       vocabulary (fixed / rejected: / user-decision / unresolved:)
#   (c) a fix commit exists OR no disposition claims "fixed"
#   (d) fix commits (if any) use generic subjects — no finding text
#   (f) the run was not killed by the timeout
#   (g)/(h) the loop ran Round 2 and wrote its completion marker
#
# Case 2 (pipeline mode, TOPIC_DIR) repeats the setup on a second branch and
# adds:
#   (e2) same blast-radius check as (e): the Case 2 run did not mutate the
#        plugin dev repo, using a plugin-repo snapshot taken fresh right
#        before the Case 2 agent call
#   (p1) the pipeline-mode review log is created under TOPIC_DIR/implementation
#   (p1b) the direct-mode sidecar log was NOT also written — TOPIC_DIR must
#        select pipeline mode exclusively, not run both modes
#   (p2) that log is committed, not left untracked
#   (p3) at least one chore(review) commit per round
#   (p4) the working tree is clean at the end (test transcripts excluded)
#   (p5) reviewer blinding: no review package contains the path of the log
#        or of the fix-reports file
#   (p5-control) positive control for (p5): at least 2 new review packages
#        were written during Case 2, so (p5) actually examined a package
#        built after round 1's chore(review) log commit existed — gated on
#        round 1 having produced a "review fixes (" commit, since otherwise
#        round 2 legitimately reuses round 1's package name
#   (p6) when round 1 produced a fix commit, the fix-reports file exists
#        under TOPIC_DIR/implementation, and (p7) it is committed
#   (setup) Case 2 starts on a clean tree and a fresh branch from the base
#        commit; a failure there is recorded like any other assertion and
#        the summary still prints (see the guard before Case 2)
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

# Uncommitted changes in the test project, transcripts excluded. The project
# is a bare `mktemp -d` + `git init` with no .gitignore, and both cases write
# their `claude -p` transcript into it (`output.txt`, `output-pipeline.txt`).
# Those transcripts are test scaffolding, not a product of the loop, so a
# check that counted them would fail on every run whatever the skill does.
project_dirt() {
    git status --porcelain -- ':(top)' ':(top,exclude,glob)output*.txt'
}

# Print the summary and exit. On failure the EXIT trap is disarmed first, so
# the project and its transcripts survive for debugging.
finish() {
    if [ "$FAILURES" -eq 0 ]; then
        echo "PASS: multi-code-review behavioral test"
        exit 0
    fi
    trap - EXIT
    echo "FAILED: $FAILURES assertion(s); project kept for debugging: $TEST_PROJECT (transcripts in output.txt and output-pipeline.txt — clean up manually)"
    exit 1
}

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

PROMPT="Invoke the superpowers-orchestrator:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-under-review) with BASE $BASE_SHA and N=2. Do not ask me any questions — use N=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."

# Safety net: the skill commits; a misanchored run must not mutate the dev repo.
# --ignored=matching is included because .superpowers/ and state.md/known-issues.md/*.txt
# are gitignored in this repo — exactly the paths the skill under test writes — so a
# plain --porcelain diff would miss a misanchored run landing its review log or journal here.
PLUGIN_HEAD_BEFORE=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_BEFORE=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)

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
PLUGIN_STATUS_AFTER=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)
if [ "$PLUGIN_HEAD_AFTER" != "$PLUGIN_HEAD_BEFORE" ] || [ "$PLUGIN_STATUS_AFTER" != "$PLUGIN_STATUS_BEFORE" ]; then
    echo "FAIL(e): the run mutated the plugin dev repo (misanchored skill?)"
    echo "  Inspect: git -C $PLUGIN_DIR status --porcelain; git -C $PLUGIN_DIR diff"
    echo "  Only after confirming that tree held nothing else of value, recover with: git -C $PLUGIN_DIR reset --hard $PLUGIN_HEAD_BEFORE (this discards ALL uncommitted work in that repo)"
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
    NON_GENERIC=$(git log --format=%s "$SEEDED_HEAD_SHA..HEAD" | grep -vE "^review fixes \(([^,]+, )?round [0-9]+\)$" || true)
    if [ -n "$NON_GENERIC" ]; then
        echo "FAIL(d): fix commit subject(s) not generic:"
        echo "$NON_GENERIC"
        FAILURES=$((FAILURES+1))
    fi
fi

# ── Case 2: pipeline mode (TOPIC_DIR) ────────────────────────────────────────
# The log and fix reports are committed under <topic>/implementation/, one
# chore(review) commit per round, and the review package the log names must
# not contain the log's own text (reviewer blinding).

# Guard the branch switch. This script runs under `set -euo pipefail`, so a
# `git checkout` that fails here — a dirty tree left by Case 1 that the
# checkout would overwrite, or a branch of the same name that already exists —
# would abort the script before the summary prints, and the EXIT trap would
# delete the project with its transcripts. Record each condition as a numbered
# setup failure instead and, since Case 2 must start from $BASE_SHA on a fresh
# branch and a clean tree, go straight to the summary when it cannot.
SETUP_DIRT=$(project_dirt)
if [ -n "$SETUP_DIRT" ]; then
    echo "FAIL(setup): working tree not clean after Case 1 — Case 2 cannot start from a clean $BASE_SHA:"
    echo "$SETUP_DIRT"
    FAILURES=$((FAILURES+1))
    finish
fi
if ! CHECKOUT_ERROR=$(git checkout --quiet -b feature-pipeline-review "$BASE_SHA" 2>&1); then
    echo "FAIL(setup): could not create branch feature-pipeline-review from $BASE_SHA:"
    echo "$CHECKOUT_ERROR"
    FAILURES=$((FAILURES+1))
    finish
fi
cat > sum.js << 'DEFECT2_EOF'
function sumFirstN(arr, n) {
  // BUG (planted, blatant): off-by-one reads past n and past the array end
  let total = 0;
  for (let i = 0; i <= n; i++) total += arr[i];
  return total;
}
module.exports = { sumFirstN };
DEFECT2_EOF
git add sum.js
git commit --quiet -m "feature: extend sumFirstN (pipeline case)"

TOPIC_DIR="$TEST_PROJECT/docs/superpowers-orchestrator/2026-08-25-sum-fix"
PIPE_PROMPT="Invoke the superpowers-orchestrator:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-pipeline-review) with BASE $BASE_SHA, N=2, and TOPIC_DIR $TOPIC_DIR. Do not ask me any questions — use N=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."

# Snapshot the review-package count BEFORE this case runs. Case 1 already
# wrote at least one package into the same project, so an absolute
# "at least one package exists" control could never fail; only an increase
# proves that this case's own loop built packages. The threshold is an
# increase of at least TWO, one per round of this N=2 case — see the
# (p5-control) comment below for why one is not enough.
# `|| true` is required: the script runs under `set -euo pipefail` (line 18),
# and when the glob matches nothing `ls` exits 2, `pipefail` propagates that
# through `wc`/`tr`, and `set -e` would abort the whole script instead of
# letting the control report. Same idiom as line 99 of this file.
PKG_COUNT_BEFORE=$(ls "$TEST_PROJECT"/.superpowers/sdd/review-*.diff 2>/dev/null | wc -l | tr -d ' ' || true)

# Safety net (Case 2): re-snapshot the plugin repository immediately before
# this case's agent call, same as assertion (e) does for Case 1. Case 1's
# PLUGIN_HEAD_BEFORE/PLUGIN_STATUS_BEFORE only cover Case 1 — without a fresh
# snapshot here, a Case 2 run that writes its topic folder or its commit into
# the developer's own checkout instead of the test project would leave this
# suite green.
PLUGIN_HEAD_BEFORE2=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_BEFORE2=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)

CLAUDE_STATUS2=0
cd "$PLUGIN_DIR" && timeout 1800 claude -p "$PIPE_PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output-pipeline.txt" || CLAUDE_STATUS2=${PIPESTATUS[0]}

# (f2) same timeout-kill check as (f), repeated for Case 2.
if [ "$CLAUDE_STATUS2" -eq 124 ] || [ "$CLAUDE_STATUS2" -eq 143 ]; then
    echo "FAIL(f2): the Case 2 claude run was killed by the 1800s timeout (exit $CLAUDE_STATUS2) — the loop never finished"
    FAILURES=$((FAILURES+1))
fi

# (e2) same blast-radius check as assertion (e), repeated for Case 2.
PLUGIN_HEAD_AFTER2=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_AFTER2=$(git -C "$PLUGIN_DIR" status --porcelain --ignored=matching | shasum | cut -d' ' -f1)
if [ "$PLUGIN_HEAD_AFTER2" != "$PLUGIN_HEAD_BEFORE2" ] || [ "$PLUGIN_STATUS_AFTER2" != "$PLUGIN_STATUS_BEFORE2" ]; then
    echo "FAIL(e2): the Case 2 run mutated the plugin dev repo (misanchored skill?)"
    echo "  Inspect: git -C $PLUGIN_DIR status --porcelain; git -C $PLUGIN_DIR diff"
    echo "  Only after confirming that tree held nothing else of value, recover with: git -C $PLUGIN_DIR reset --hard $PLUGIN_HEAD_BEFORE2 (this discards ALL uncommitted work in that repo)"
    FAILURES=$((FAILURES+1))
fi

cd "$TEST_PROJECT"
PIPE_LOG="$TOPIC_DIR/implementation/sum-fix-review-log.md"

# (p1b) mode selection is only half-verified by (p1): a run that ALSO wrote
# the direct-mode sidecar would still pass every assertion above. The
# sidecar's branch-slug is the branch name with every non-alphanumeric run
# replaced by "-" (skills/multi-code-review/SKILL.md); this case's branch
# "feature-pipeline-review" has none, so the slug is unchanged. That sidecar
# lives under .superpowers/reviews/, which carries a self-ignoring
# .gitignore, so it is invisible to the (p4) clean-tree check below and must
# be checked directly.
DIRECT_SIDECAR=".superpowers/reviews/feature-pipeline-review-review-log.md"
if [ -f "$DIRECT_SIDECAR" ]; then
    echo "FAIL(p1b): direct-mode sidecar $DIRECT_SIDECAR also exists — TOPIC_DIR did not select pipeline mode exclusively"
    FAILURES=$((FAILURES+1))
fi

if [ ! -f "$PIPE_LOG" ]; then
    echo "FAIL(p1): no $PIPE_LOG created in pipeline mode"
    FAILURES=$((FAILURES+1))
else
    # (p2) the log is committed, not left untracked
    if ! git ls-files --error-unmatch "$PIPE_LOG" > /dev/null 2>&1; then
        echo "FAIL(p2): the pipeline-mode review log is not tracked in the branch"
        FAILURES=$((FAILURES+1))
    fi
    # (g2) the N=2 loop ran its second round, same check as (g) for Case 1.
    if ! grep -q "^## Round 2 — " "$PIPE_LOG"; then
        echo "FAIL(g2): pipeline review log has no '## Round 2' entry — the loop did not run both rounds"
        FAILURES=$((FAILURES+1))
    fi
    # (h2) the loop reached its completion marker, same check as (h) for Case 1.
    if ! grep -q "^_Completed — " "$PIPE_LOG"; then
        echo "FAIL(h2): pipeline review log has no '_Completed — ' marker — the loop did not finish"
        FAILURES=$((FAILURES+1))
    fi
    # (p3) one chore(review) commit per round
    REVIEW_COMMITS=$(git log --format=%s "$BASE_SHA"..HEAD | grep -c '^chore(review): ' || true)
    if [ "$REVIEW_COMMITS" -lt 2 ]; then
        echo "FAIL(p3): expected at least 2 chore(review) commits, found $REVIEW_COMMITS"
        FAILURES=$((FAILURES+1))
    fi
    # (p4) the working tree is clean at the end (transcripts excluded — see
    #      project_dirt above).
    DIRT=$(project_dirt)
    if [ -n "$DIRT" ]; then
        echo "FAIL(p4): working tree not clean after the pipeline-mode loop:"
        echo "$DIRT"
        FAILURES=$((FAILURES+1))
    fi
    # (p5) reviewer blinding: no review package contains the log's own text.
    # Compare the package count against the pre-case snapshot. Without this
    # control the loop below reports success when this case examined nothing
    # it wrote — no package written, the `review-package` fallback path taken,
    # or the workspace archived — and this is the plan's only end-to-end check
    # that a real run does not hand the reviewer its own review log. The
    # comparison must be an INCREASE, not "at least one": Case 1 ran in the
    # same project and already left packages behind, so an absolute count
    # could never fail.
    #
    # The increase must be at least TWO — one package per round of this N=2
    # case. One new package is not enough: round 1's package is built before
    # any `chore(review)` log commit exists in `BASE..HEAD`, so it cannot
    # contain the log path and the (p5) grep below can never fail on it. Only
    # a package regenerated AFTER round 1's log commit can catch an unblinded
    # reviewer. A run that reuses round 1's package for round 2 — the exact
    # failure this control exists to detect — leaves exactly one new package,
    # which a "-le $PKG_COUNT_BEFORE" test would let through. Package files
    # are named per range (`review-<base7>..<head7>.diff`), so a correct N=2
    # run leaves two.
    # The +2 threshold only holds when round 1 actually produced a fix commit.
    # If round 1 found nothing to fix, the effective HEAD (see "Pipeline rule 4"
    # in skills/multi-code-review/SKILL.md) is unchanged between round 1 and
    # round 2, so round 2 legitimately regenerates a package under the
    # identical `review-<base7>..<head7>.diff` name instead of a new one — that
    # is correct behaviour, not the reused-package bug this control looks for.
    FIX_COMMITS=$(git log --format=%s "$BASE_SHA"..HEAD | grep -c '^review fixes (' || true)
    if [ "$FIX_COMMITS" -lt 1 ]; then
        echo "SKIP(p5-control): round 1 produced no 'review fixes (' commit, so a same-name package regeneration in round 2 is expected — the +2 threshold does not apply"
    else
        PKG_COUNT=$(ls .superpowers/sdd/review-*.diff 2>/dev/null | wc -l | tr -d ' ' || true)
        if [ "$PKG_COUNT" -lt $((PKG_COUNT_BEFORE + 2)) ]; then
            echo "FAIL(p5-control): fewer than 2 new review packages under .superpowers/sdd/ (before Case 2: $PKG_COUNT_BEFORE, after: $PKG_COUNT) — round 2 did not regenerate after round 1's chore(review) log commit, so the blinding assertion examined only packages built before the log existed"
            FAILURES=$((FAILURES+1))
        fi
        # (p6)/(p7) a round that dispatched a fix subagent also wrote the
        # fix-reports file next to the log, and committed it — the skill
        # commits "<log> [<fix reports>]" together in the chore(review) commit.
        # Gated on the same condition: without a fix commit there is no fix
        # report to write.
        PIPE_FIX_REPORTS="$TOPIC_DIR/implementation/sum-fix-fix-reports.md"
        if [ ! -f "$PIPE_FIX_REPORTS" ]; then
            echo "FAIL(p6): round 1 produced a fix commit but $PIPE_FIX_REPORTS does not exist"
            FAILURES=$((FAILURES+1))
        elif ! git ls-files --error-unmatch "$PIPE_FIX_REPORTS" > /dev/null 2>&1; then
            echo "FAIL(p7): the pipeline-mode fix-reports file is not tracked in the branch"
            FAILURES=$((FAILURES+1))
        fi
    fi
    # The fix-reports file quotes what each fix subagent did, so it must be
    # blinded the same way as the log: both paths are needles here.
    for PKG in .superpowers/sdd/review-*.diff; do
        [ -f "$PKG" ] || continue
        for NEEDLE in sum-fix-review-log.md sum-fix-fix-reports.md; do
            if grep -q "$NEEDLE" "$PKG"; then
                echo "FAIL(p5): review package $PKG contains $NEEDLE — the reviewer was not blinded"
                FAILURES=$((FAILURES+1))
            fi
        done
    done
fi

finish
