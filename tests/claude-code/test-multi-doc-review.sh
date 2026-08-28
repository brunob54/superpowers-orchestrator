#!/usr/bin/env bash
# Test: multi-doc-review skill — N-round document review loop (behavioral, slow)
#
# Two cases assert the M contract end-to-end, both against the review-log
# contract from
# docs/superpowers-orchestrator/2026-07-19-multi-review/specs/multi-review-design.md:
#
# Case 1 (M=2): seeds a deliberately flawed spec, invokes the skill headlessly
# with N=2 and M=2, and asserts:
#   (a) sidecar <doc-basename>-review-log.md exists with a Round 1 entry
#   (b) doc modified OR all Critical/Important dispositions are rejections
#   (c) log has a disposition line or an explicit no-findings verdict
#   (i) the invocation line records N=2 M=2
#   (m) rounds 1 and 2 carry the M=2 lines (Reviewers, Reviewer verdicts,
#       Sources mapped) and source annotations that agree with each other —
#       the M passed to the invocation governs every round it runs, not
#       just round 1
#
# Case 2 (M=1, the default configuration): repeats the setup on a second,
# separate spec and topic dir, invokes the skill with N=2 and no M= (so the
# skill falls back to M=1 — the way every gate invocation and every user
# without an explicit M= runs it), and asserts:
#   (a2)/(b2)/(c2) same checks as Case 1
#   (i2) the invocation line records N=2 M=1 (M is recorded even at M=1, so
#        a log is self-describing)
#   (m1) the M=1 log shape stays byte-identical to earlier releases: round 1
#        has NO '**Reviewers:**', NO '**Reviewer verdicts:**' and NO
#        '**Sources mapped:**' line, and its disposition lines carry NO
#        ' ← ' source annotation
#
# Requires the INSTALLED plugin to include multi-doc-review — reinstall the
# plugin cache after editing skills/ before running this.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/timeout-shim.sh"
source "$SCRIPT_DIR/test-helpers.sh"

# [I2] M must come from the prompt (M=2 explicit in Case 1, or no M= for the
# Case 2 default), never from the developer's own environment. `unset` here
# only clears SUPERPOWERS_REVIEWERS_PER_LENS from THIS shell's environment —
# it does NOT remove a value Claude Code applies from a settings file's
# `env` block (README.md and docs/guide/README.md document setting M that
# way): Claude Code applies that block inside its own process and passes it
# to hooks, so the shell-level unset cannot reach it. The check below
# detects that case and aborts before any `claude -p` call, instead of
# letting Case 2's M=1 default silently resolve to a different M.
unset SUPERPOWERS_REVIEWERS_PER_LENS
check_no_reviewers_per_lens_setting "$PLUGIN_DIR" || exit 1

TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project '$TEST_PROJECT'" EXIT

FAILURES=0

# ── Case 1: M=2 ──────────────────────────────────────────────────────────
TOPIC_DIR="$TEST_PROJECT/docs/superpowers-orchestrator/2026-08-25-test-feature"
mkdir -p "$TOPIC_DIR/specs"
SPEC="$TOPIC_DIR/specs/test-feature-design.md"
cat > "$SPEC" << 'SPEC_EOF'
# Test Feature Design

## Requirements
- The exporter writes CSV files to the output directory.
- The exporter never writes any file to disk.

## Retry Behavior
Failed exports are retried a reasonable number of times.
SPEC_EOF
SPEC_SHA_BEFORE=$(shasum "$SPEC" | cut -d' ' -f1)

PROMPT="Invoke the superpowers-orchestrator:multi-doc-review skill on the document $SPEC with N=2 and M=2. Do not ask me any questions — use N=2 and M=2 and proceed to completion."
# Deliberately no doc-type statement: the spec's Testing Strategy requires this
# test to run the skill on a new-layout spec path (nearest segment specs/ ->
# spec); stating the type would override inference per the skill's Parameters
# rule. This test does not observe the inferred doc type — see the NOTE below.
# NOTE: no assertion below actually observes the inferred type. The review log
# records no doc type, and the lens names are identical for the spec, plan, and
# general doc types, so the log this run produces is byte-compatible with a
# "general" inference. The transcript captured below (output.txt) cannot make
# up the difference either: `claude -p` here uses the default plain-text output
# (no --verbose, no --output-format stream-json), so it holds only the
# top-level agent's final printed message, not the reviewer subagent's prompt
# text — there is nothing in it a grep could key on to confirm "spec" was
# actually inferred rather than assumed.

CLAUDE_STATUS=0
cd "$PLUGIN_DIR" && timeout 1700 claude -p "$PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output.txt" || CLAUDE_STATUS=${PIPESTATUS[0]}

# (f) the run must not have been killed by the timeout: GNU timeout reports
#     124, the tests/lib/timeout-shim.sh fallback reports 143 (SIGTERM).
if [ "$CLAUDE_STATUS" -eq 124 ] || [ "$CLAUDE_STATUS" -eq 143 ]; then
    echo "FAIL(f): the claude run was killed by the 1700s timeout (exit $CLAUDE_STATUS) — the loop never finished"
    FAILURES=$((FAILURES+1))
fi

LOG="$TOPIC_DIR/specs/test-feature-design-review-log.md"

if [ ! -f "$LOG" ]; then
    echo "FAIL(a): review log $LOG was not created"
    FAILURES=$((FAILURES+1))
else
    if ! grep -q "^## Round 1" "$LOG"; then
        echo "FAIL(a): review log has no '## Round 1' entry"
        FAILURES=$((FAILURES+1))
    fi
    SPEC_SHA_AFTER=$(shasum "$SPEC" | cut -d' ' -f1)
    if [ "$SPEC_SHA_AFTER" = "$SPEC_SHA_BEFORE" ] && \
       grep -qE "^- \[(C|I)[0-9]+\] applied" "$LOG"; then
        echo "FAIL(b): log claims applied Critical/Important findings but the spec is byte-identical"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qiE "applied|rejected:|deferred|no material issues|skipped|inconclusive" "$LOG"; then
        echo "FAIL(c): log has no disposition line and no no-findings verdict"
        FAILURES=$((FAILURES+1))
    fi
    # (i) the invocation line records N and M
    if ! grep -q " N=2 M=2 — " "$LOG"; then
        echo "FAIL(i): review log invocation line does not contain ' N=2 M=2 — '"
        FAILURES=$((FAILURES+1))
    fi
    # (m) M=2: the round-1 entry carries the reviewers-per-lens lines and
    #     source annotations, and they agree with each other.
    #     'required': Case 1 seeds a spec with defects, so round 1 must
    #     consolidate at least one finding — an empty set here means the
    #     seeding or the logging broke, not that the spec was clean.
    assert_round_reviewers "$LOG" 1 2 required || FAILURES=$((FAILURES+$?))
    # (m) M=2, round 2: the M passed to the invocation governs every round it
    #     runs, not just round 1 — this N=2 run already produces a round 2,
    #     so its reviewers-per-lens lines must be checked too.
    #     'optional': round 2 runs after round 1's applied findings, so
    #     finding nothing is convergence — a legitimate result.
    assert_round_reviewers "$LOG" 2 2 optional || FAILURES=$((FAILURES+$?))
fi

# ── Case 2: M=1 (default configuration) ─────────────────────────────────
# A separate spec and topic dir, so this case's log and Case 1's log never
# collide.
TOPIC_DIR2="$TEST_PROJECT/docs/superpowers-orchestrator/2026-08-25-test-feature-m1"
mkdir -p "$TOPIC_DIR2/specs"
SPEC2="$TOPIC_DIR2/specs/test-feature-design.md"
cat > "$SPEC2" << 'SPEC2_EOF'
# Test Feature Design

## Requirements
- The exporter writes CSV files to the output directory.
- The exporter never writes any file to disk.

## Retry Behavior
Failed exports are retried a reasonable number of times.
SPEC2_EOF
SPEC2_SHA_BEFORE=$(shasum "$SPEC2" | cut -d' ' -f1)

PROMPT2="Invoke the superpowers-orchestrator:multi-doc-review skill on the document $SPEC2 with N=2. Do not ask me any questions — use N=2 and proceed to completion."
# Deliberately no M=: this case exercises the DEFAULT configuration (M=1),
# the way every gate invocation and every user without an explicit M= runs
# it — see the (m1) checks below.

CLAUDE_STATUS2=0
cd "$PLUGIN_DIR" && timeout 1700 claude -p "$PROMPT2" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output-m1.txt" || CLAUDE_STATUS2=${PIPESTATUS[0]}

# (f2) same timeout check as (f), for the Case 2 run.
if [ "$CLAUDE_STATUS2" -eq 124 ] || [ "$CLAUDE_STATUS2" -eq 143 ]; then
    echo "FAIL(f2): the Case 2 claude run was killed by the 1700s timeout (exit $CLAUDE_STATUS2) — the loop never finished"
    FAILURES=$((FAILURES+1))
fi

LOG2="$TOPIC_DIR2/specs/test-feature-design-review-log.md"

if [ ! -f "$LOG2" ]; then
    echo "FAIL(a2): review log $LOG2 was not created"
    FAILURES=$((FAILURES+1))
else
    if ! grep -q "^## Round 1 — " "$LOG2"; then
        echo "FAIL(a2): review log has no '## Round 1 — ' entry"
        FAILURES=$((FAILURES+1))
    fi
    SPEC2_SHA_AFTER=$(shasum "$SPEC2" | cut -d' ' -f1)
    if [ "$SPEC2_SHA_AFTER" = "$SPEC2_SHA_BEFORE" ] && \
       grep -qE "^- \[(C|I)[0-9]+\] applied" "$LOG2"; then
        echo "FAIL(b2): log claims applied Critical/Important findings but the spec is byte-identical"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qiE "applied|rejected:|deferred|no material issues|skipped|inconclusive" "$LOG2"; then
        echo "FAIL(c2): log has no disposition line and no no-findings verdict"
        FAILURES=$((FAILURES+1))
    fi
    # (i2) the invocation line records M right after N INCLUDING when M=1 (so
    #      a log is self-describing), same rule as (i) for Case 1's M=2.
    if ! grep -q " N=2 M=1 — " "$LOG2"; then
        echo "FAIL(i2): review log invocation line does not contain ' N=2 M=1 — '"
        FAILURES=$((FAILURES+1))
    fi
    # (m1) M=1: the round-1 entry stays byte-identical to earlier releases —
    #      no reviewers-per-lens lines and no source annotations at all.
    ROUND1_M1=$(awk -v r=1 '
        $0 ~ "^## Round " r " — " { on = 1; print; next }
        /^## Round / { if (on) exit }
        on { print }' "$LOG2")
    if [ -z "$ROUND1_M1" ]; then
        echo "FAIL(m1): no '## Round 1 — ' entry extracted"
        FAILURES=$((FAILURES+1))
    fi
    if printf '%s\n' "$ROUND1_M1" | grep -q '^\*\*Reviewers:\*\*'; then
        echo "FAIL(m1): M=1 round 1 has a '**Reviewers:**' line — must be absent for the default configuration"
        FAILURES=$((FAILURES+1))
    fi
    if printf '%s\n' "$ROUND1_M1" | grep -q '^\*\*Reviewer verdicts:\*\*'; then
        echo "FAIL(m1): M=1 round 1 has a '**Reviewer verdicts:**' line — must be absent for the default configuration"
        FAILURES=$((FAILURES+1))
    fi
    if printf '%s\n' "$ROUND1_M1" | grep -q '^\*\*Sources mapped:\*\*'; then
        echo "FAIL(m1): M=1 round 1 has a '**Sources mapped:**' line — must be absent for the default configuration"
        FAILURES=$((FAILURES+1))
    fi
    if printf '%s\n' "$ROUND1_M1" | grep -q ' ← '; then
        echo "FAIL(m1): M=1 round 1 has a disposition line with a ' ← ' source annotation — must be absent for the default configuration"
        FAILURES=$((FAILURES+1))
    fi
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: multi-doc-review behavioral test"
else
    echo "FAILED: $FAILURES assertion(s); transcripts in $TEST_PROJECT/output.txt and $TEST_PROJECT/output-m1.txt"
    exit 1
fi
