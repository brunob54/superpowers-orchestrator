#!/usr/bin/env bash
# Test: multi-doc-review skill — N-round document review loop (behavioral, slow)
#
# Seeds a deliberately flawed spec, invokes the skill headlessly with N=2 and M=2,
# and asserts the review-log contract from
# docs/superpowers-orchestrator/2026-07-19-multi-review/specs/multi-review-design.md:
#   (a) sidecar <doc-basename>-review-log.md exists with a Round 1 entry
#   (b) doc modified OR all Critical/Important dispositions are rejections
#   (c) log has a disposition line or an explicit no-findings verdict
#   (m) round 1 carries the M=2 lines (Reviewers, Reviewer verdicts, Sources
#       mapped) and source annotations that agree with each other
#
# Requires the INSTALLED plugin to include multi-doc-review — reinstall the
# plugin cache after editing skills/ before running this.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/timeout-shim.sh"
source "$SCRIPT_DIR/test-helpers.sh"

TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project '$TEST_PROJECT'" EXIT

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

cd "$PLUGIN_DIR" && timeout 1800 claude -p "$PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output.txt" || true

LOG="$TOPIC_DIR/specs/test-feature-design-review-log.md"
FAILURES=0

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
    # (m) M=2: the round-1 entry carries the reviewers-per-lens lines and
    #     source annotations, and they agree with each other
    assert_round_reviewers "$LOG" 1 2 || FAILURES=$((FAILURES+$?))
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: multi-doc-review behavioral test"
else
    echo "FAILED: $FAILURES assertion(s); transcript in $TEST_PROJECT/output.txt"
    exit 1
fi
