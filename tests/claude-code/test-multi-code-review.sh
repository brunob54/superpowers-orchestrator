#!/usr/bin/env bash
# Test: multi-code-review skill — N-round whole-branch review loop (behavioral, slow)
#
# Seeds a temp git repo with a base commit and a branch carrying a blatant
# planted defect, invokes the skill headlessly with N=2 and M=2, and
# asserts the review-log contract from docs/superpowers-orchestrator/2026-07-27-multi-code-review/specs/multi-code-review-design.md:
#   (a) .superpowers/reviews/*-review-log.md exists with a Round 1 entry
#   (b) every enumerated Critical/Important disposition uses the canonical
#       vocabulary (fixed / rejected: / user-decision / unresolved:)
#   (c) a fix commit exists OR no disposition claims "fixed"
#   (d) fix commits (if any) use generic subjects — no finding text
#   (f) the run was not killed by the timeout
#   (g)/(h) the loop ran Round 2 and wrote its completion marker
#   (i) the invocation line records N and M
#   (m) M=2: round 1 carries the reviewers-per-lens lines (Reviewers,
#       Reviewer verdicts, Sources mapped) and source annotations that
#       agree with each other
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
#   (h3) the completion marker records the effective HEAD (Pipeline rule 4,
#        SKILL.md): a real commit, equal to the path-limited `git log -1`
#        lookup over BASE..HEAD with the blinding pathspecs read out of
#        review-package
#   (p3) each round's chore(review) log commit has the exact subject
#        "chore(review): <slug> round <i> log" (Pipeline rule 1, SKILL.md)
#   (p4) the working tree is clean at the end (test transcripts excluded)
#   (p5) reviewer blinding: no review package contains the path of the log
#        or of the fix-reports file
#   (p5-control) positive control for (p5): at least 2 new review packages
#        were written during Case 2, so (p5) actually examined a package
#        built after round 1's chore(review) log commit existed. This holds
#        unconditionally: Pipeline rule 1 always lands a
#        "chore(review): <slug> round 1 log" commit before round 2 starts,
#        so round 2's package (SKILL.md Procedure step 1: regenerated
#        whenever commits landed since the last package) always gets a new
#        `review-<base7>..<head7>.diff` name, fix commit or not.
#   (p5-control2) the count alone does not prove that any examined package's
#        range actually contained a chore(review) commit — the range where
#        blinding matters. Confirmed by resolving each NEW package's <head7>
#        back to a commit subject and requiring at least one to be a
#        chore(review) commit.
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

PROMPT="Invoke the superpowers-orchestrator:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-under-review) with BASE $BASE_SHA, N=2 and M=2. Do not ask me any questions — use N=2 and M=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."

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
    # (i) the invocation line records N and M
    if ! grep -q " N=2 M=2 — " "$LOG"; then
        echo "FAIL(i): review log invocation line does not contain ' N=2 M=2 — '"
        FAILURES=$((FAILURES+1))
    fi
    # (m) M=2: the round-1 entry carries the reviewers-per-lens lines and
    #     source annotations, and they agree with each other. Case 1 passes no
    #     carried findings, so every disposition of the round carries one.
    assert_round_reviewers "$LOG" 1 2 || FAILURES=$((FAILURES+$?))
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
# The glob here is RELATIVE (cwd is already $TEST_PROJECT, set by Case 1's
# "cd $TEST_PROJECT" above) because the after-run listings this snapshot is
# compared against — (p5-control)/(p5-control2) below — use the same
# relative glob after their own "cd $TEST_PROJECT". `comm -13` compares
# these as plain strings, so an absolute path here would never match a
# relative one there and every post-run package would be misreported as new.
PKG_COUNT_BEFORE=$(ls .superpowers/sdd/review-*.diff 2>/dev/null | wc -l | tr -d ' ' || true)
# Same snapshot, as a file listing rather than a count — (p5-control2) below
# needs the actual NEW filenames, not just how many there are.
PKGS_BEFORE=$(ls .superpowers/sdd/review-*.diff 2>/dev/null || true)

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
    # (h3) the completion marker records the EFFECTIVE HEAD (Pipeline rule 4
    # in skills/multi-code-review/SKILL.md): the newest commit in BASE..HEAD
    # that changes at least one path outside the blinding pathspec set. The
    # raw HEAD at marker time is the round's own chore(review) log commit and
    # would never match a later once-per-gate comparison. Two checks: the
    # marker names a real commit, and it equals the path-limited lookup
    # computed here. A log commit touches only blinded paths, so the
    # content-based effective HEAD can never be the log commit itself — that
    # is what (h3b) proves. The
    # pathspec set is read out of review-package itself — the set a script
    # actually executes — so this check follows the set instead of retyping
    # it. `|| true` keeps `set -e` from aborting the run when (h2) already
    # reported a missing marker.
    MARKER_SHA=$(grep '^_Completed — ' "$PIPE_LOG" | tail -n 1 | sed -E 's/.*HEAD ([0-9a-f]+)_?[[:space:]]*$/\1/' || true)
    if ! git rev-parse --verify --quiet "${MARKER_SHA}^{commit}" > /dev/null 2>&1; then
        echo "FAIL(h3a): the completion marker's HEAD '$MARKER_SHA' is not a commit in the test project"
        FAILURES=$((FAILURES+1))
    else
        BLIND_PATHSPECS=()
        while IFS= read -r ENTRY; do
            BLIND_PATHSPECS+=("$ENTRY")
        done < <(sed -n '/^blind_pathspecs=($/,/^)$/p' "$PLUGIN_DIR/skills/subagent-driven-development/scripts/review-package" | grep -oE "':[^']*'" | sed "s/^'//; s/'\$//")
        if [ "${#BLIND_PATHSPECS[@]}" -eq 0 ]; then
            echo "FAIL(h3b): could not read blind_pathspecs out of review-package — the effective HEAD cannot be computed"
            FAILURES=$((FAILURES+1))
        else
            EXPECTED_EFFECTIVE_HEAD=$(git log -1 --full-history --format=%H "$BASE_SHA..HEAD" -- "${BLIND_PATHSPECS[@]}")
            [ -n "$EXPECTED_EFFECTIVE_HEAD" ] || EXPECTED_EFFECTIVE_HEAD=$(git rev-parse "$BASE_SHA")
            if [ "$(git rev-parse "$MARKER_SHA")" != "$EXPECTED_EFFECTIVE_HEAD" ]; then
                echo "FAIL(h3b): the completion marker records $MARKER_SHA but the effective HEAD of $BASE_SHA..HEAD is $EXPECTED_EFFECTIVE_HEAD"
                FAILURES=$((FAILURES+1))
            fi
        fi
    fi
    # (p3) each round's log commit uses the EXACT generic subject from
    # Pipeline rule 1 in skills/multi-code-review/SKILL.md:
    # "chore(review): <slug> round <i> log". "at least 2 chore(review)
    # commits" is not enough: the completion commit "chore(review): <slug>
    # completed" (same rule) also matches that count, so a run that skipped
    # round 2's own log commit but landed the completion commit would still
    # pass. <slug> = TOPIC_DIR's basename minus the date prefix ("Sidecar
    # log and fix reports", pipeline mode, SKILL.md) — "sum-fix" for this
    # fixture's TOPIC_DIR (docs/superpowers-orchestrator/2026-08-25-sum-fix).
    if ! git log --format=%s "$BASE_SHA"..HEAD | grep -qxF "chore(review): sum-fix round 1 log"; then
        echo "FAIL(p3a): no commit with subject 'chore(review): sum-fix round 1 log'"
        FAILURES=$((FAILURES+1))
    fi
    if ! git log --format=%s "$BASE_SHA"..HEAD | grep -qxF "chore(review): sum-fix round 2 log"; then
        echo "FAIL(p3b): no commit with subject 'chore(review): sum-fix round 2 log'"
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
    #
    # This holds UNCONDITIONALLY — no gate on round 1 having produced a fix
    # commit. Pipeline rule 1 in skills/multi-code-review/SKILL.md always
    # lands a "chore(review): <slug> round 1 log" commit before round 2
    # starts, and Procedure step 1 there regenerates the package "whenever
    # commits landed since the last package" — so round 2's package always
    # carries a new HEAD short SHA and therefore a new
    # `review-<base7>..<head7>.diff` name, fix commit or not.
    PKG_COUNT=$(ls .superpowers/sdd/review-*.diff 2>/dev/null | wc -l | tr -d ' ' || true)
    if [ "$PKG_COUNT" -lt $((PKG_COUNT_BEFORE + 2)) ]; then
        echo "FAIL(p5-control): fewer than 2 new review packages under .superpowers/sdd/ (before Case 2: $PKG_COUNT_BEFORE, after: $PKG_COUNT) — round 2 did not regenerate after round 1's chore(review) log commit, so the blinding assertion examined only packages built before the log existed"
        FAILURES=$((FAILURES+1))
    fi
    # (p5-control2) the count alone does not prove that any package the (p5)
    # loop below actually examined had a range that contained a
    # chore(review) commit — the one case where blinding matters. Resolve
    # each NEW package (present now, absent from the pre-case $PKGS_BEFORE
    # snapshot) back to the commit its filename names: package files are
    # `review-<base7>..<head7>.diff`, so the text after `..` and before
    # `.diff` is the HEAD short SHA that package was built against.
    NEW_PKGS=$(comm -13 <(printf '%s\n' "$PKGS_BEFORE" | sort) <(ls .superpowers/sdd/review-*.diff 2>/dev/null | sort))
    # (p5-control3) self-check: NEW_PKGS must hold exactly the packages this
    # case added, no more and no less — this is what would have caught the
    # before/after path-form mismatch this control used to have, where every
    # pre-existing package was misreported as new. Confirm its entry count
    # against the arithmetic difference between the two package-count
    # snapshots above.
    NEW_PKGS_COUNT=$(printf '%s\n' "$NEW_PKGS" | grep -c . || true)
    if [ "$NEW_PKGS_COUNT" -ne $((PKG_COUNT - PKG_COUNT_BEFORE)) ]; then
        echo "FAIL(p5-control3): NEW_PKGS has $NEW_PKGS_COUNT entries but PKG_COUNT ($PKG_COUNT) - PKG_COUNT_BEFORE ($PKG_COUNT_BEFORE) = $((PKG_COUNT - PKG_COUNT_BEFORE)) — the before/after package listings are not in the same form"
        FAILURES=$((FAILURES+1))
    fi
    FOUND_REVIEW_RANGE_PKG=0
    for PKG in $NEW_PKGS; do
        HEAD7=$(basename "$PKG" .diff | sed -E 's/^review-[0-9a-f]+\.\.//')
        SUBJECT=$(git log -1 --format=%s "$HEAD7" 2>/dev/null || true)
        case "$SUBJECT" in
            "chore(review): "*) FOUND_REVIEW_RANGE_PKG=1 ;;
        esac
    done
    if [ "$FOUND_REVIEW_RANGE_PKG" -ne 1 ]; then
        echo "FAIL(p5-control2): none of the new review packages' HEAD commit is a chore(review) commit — the (p5) blinding check never examined a package whose range actually included review material. New packages: $NEW_PKGS"
        FAILURES=$((FAILURES+1))
    fi
    # (p6)/(p7) a round that dispatched a fix subagent also wrote the
    # fix-reports file next to the log, and committed it — the skill
    # commits "<log> [<fix reports>]" together in the chore(review) commit.
    # Gated on round 1 having produced a fix commit: without one there is no
    # fix report to write.
    FIX_COMMITS=$(git log --format=%s "$BASE_SHA"..HEAD | grep -c '^review fixes (' || true)
    if [ "$FIX_COMMITS" -ge 1 ]; then
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
