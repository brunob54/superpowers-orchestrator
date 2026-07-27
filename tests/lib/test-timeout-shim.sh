#!/usr/bin/env bash
# Tests for tests/lib/timeout-shim.sh (the fallback `timeout` used when GNU
# coreutils is absent, e.g. stock macOS).
#
# Run from the repo root:  bash tests/lib/test-timeout-shim.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1; then
    echo "SKIP: a real timeout/gtimeout is on PATH; the shim function is not defined here."
    exit 0
fi

# shellcheck source=./timeout-shim.sh
source "$SCRIPT_DIR/timeout-shim.sh"

PASS=0
FAIL=0

check() {
    local label="$1" ok="$2"
    if [ "$ok" = "ok" ]; then
        echo "  PASS: $label"
        PASS=$(( PASS + 1 ))
    else
        echo "  FAIL: $label"
        FAIL=$(( FAIL + 1 ))
    fi
}

echo "timeout-shim"

# The regression this file exists for: the watcher's `sleep` child inherits the
# pipeline's stdout. If it outlives the watcher, the downstream reader never
# sees EOF and a piped `timeout` blocks for the full duration even though the
# command exited immediately.
SECONDS=0
OUT=$(timeout 30 bash -c 'echo piped-hello' | cat)
ELAPSED=$SECONDS
[ "$OUT" = "piped-hello" ] && check "piped command output reaches the reader" ok \
    || check "piped command output reaches the reader (got '$OUT')" no
[ "$ELAPSED" -lt 5 ] && check "piped fast command returns promptly (${ELAPSED}s)" ok \
    || check "piped fast command returns promptly (took ${ELAPSED}s, expected <5s)" no

# No orphaned watcher process may survive the call.
sleep 1
if pgrep -f "sleep 30" >/dev/null 2>&1; then
    check "watcher sleep is reaped after the command exits" no
else
    check "watcher sleep is reaped after the command exits" ok
fi

# The timeout must still fire for a command that overruns.
SECONDS=0
timeout 2 bash -c 'sleep 30' >/dev/null 2>&1
STATUS=$?
ELAPSED=$SECONDS
[ "$STATUS" -ne 0 ] && check "overrunning command is killed (status $STATUS)" ok \
    || check "overrunning command is killed (status was 0)" no
[ "$ELAPSED" -lt 10 ] && check "kill happens near the deadline (${ELAPSED}s)" ok \
    || check "kill happens near the deadline (took ${ELAPSED}s)" no

# GNU-style suffixed durations are used by tests/opencode/*.sh (`timeout 60s`).
SECONDS=0
OUT=$(timeout 30s bash -c 'echo suffixed')
ELAPSED=$SECONDS
[ "$OUT" = "suffixed" ] && [ "$ELAPSED" -lt 5 ] \
    && check "suffixed duration (30s) returns promptly (${ELAPSED}s)" ok \
    || check "suffixed duration (30s) returns promptly (got '$OUT' in ${ELAPSED}s)" no

SECONDS=0
timeout 2s bash -c 'sleep 30' >/dev/null 2>&1
STATUS=$?
ELAPSED=$SECONDS
[ "$STATUS" -ne 0 ] && [ "$ELAPSED" -lt 10 ] \
    && check "suffixed duration still enforces the deadline (${ELAPSED}s)" ok \
    || check "suffixed duration still enforces the deadline (status $STATUS, ${ELAPSED}s)" no

# A duration the shim cannot normalise falls back to a one-shot sleep; it must
# still run the command and return its status, not error out.
OUT=$(timeout 0.5 bash -c 'echo fractional' 2>/dev/null)
[ "$OUT" = "fractional" ] && check "unnormalisable duration still runs the command" ok \
    || check "unnormalisable duration still runs the command (got '$OUT')" no

# Exit status of the wrapped command is propagated unchanged.
timeout 30 bash -c 'exit 3' >/dev/null 2>&1
STATUS=$?
[ "$STATUS" -eq 3 ] && check "exit status propagated" ok \
    || check "exit status propagated (got $STATUS, expected 3)" no

echo ""
echo "  Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
