#!/bin/bash
# Test skill triggering with naive prompts
# Usage: ./run-test.sh <skill-name> <prompt-file>
#
# Tests whether Claude triggers a skill based on a natural prompt
# (without explicitly mentioning the skill)

set -e

SKILL_NAME="$1"
PROMPT_FILE="$2"
MAX_TURNS="${3:-3}"

if [ -z "$SKILL_NAME" ] || [ -z "$PROMPT_FILE" ]; then
    echo "Usage: $0 <skill-name> <prompt-file> [max-turns]"
    echo "Example: $0 systematic-debugging ./test-prompts/debugging.txt"
    exit 1
fi

# Get the directory where this script lives (should be tests/skill-triggering)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/timeout-shim.sh"
# Get the superpowers plugin root (two levels up from tests/skill-triggering)
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TIMESTAMP=$(date +%s)
OUTPUT_DIR="/tmp/superpowers-tests/${TIMESTAMP}/skill-triggering/${SKILL_NAME}"
mkdir -p "$OUTPUT_DIR"

# Read prompt from file
PROMPT=$(cat "$PROMPT_FILE")

echo "=== Skill Triggering Test ==="
echo "Skill: $SKILL_NAME"
echo "Prompt file: $PROMPT_FILE"
echo "Max turns: $MAX_TURNS"
echo "Output dir: $OUTPUT_DIR"
echo ""

# Copy prompt for reference
cp "$PROMPT_FILE" "$OUTPUT_DIR/prompt.txt"

# Seed a project map so the entry sequence does not stop to ask about memory
# setup. Without this file the session reaches the entry sequence's step-2
# gate, sees a directory with no memory files, and — for a prompt that asks to
# build something — asks the user a question instead of routing. In headless
# mode nobody answers, so the session ends before any skill is chosen and the
# test reports a routing failure that never happened.
cat > "$OUTPUT_DIR/project-map.md" <<'PROJECT_MAP'
# Project Map
_Generated: fixture | Staleness: timestamps_

## Directory Structure
. — throwaway fixture for one skill-triggering test; holds only the prompt

## Key Files
prompt.txt — the naive prompt under test

## Critical Constraints
- This directory is a test fixture. It has no source code and no git
  repository. The file exists so the entry sequence's memory-setup gate does
  not fire; routing is what the test measures.

## Hot Files
(none)
PROJECT_MAP

# Copy this skill's fixture, when it has one. Some prompts name a file the
# session is expected to act on — a plan to execute, for example. Without that
# file the session correctly reports the file as missing instead of invoking
# the skill, and the test reads it as a routing failure that did not happen.
FIXTURE_DIR="$SCRIPT_DIR/fixtures/$SKILL_NAME"
if [ -d "$FIXTURE_DIR" ]; then
    cp -R "$FIXTURE_DIR"/. "$OUTPUT_DIR"/
    echo "Fixture: copied $FIXTURE_DIR"
fi

# Run Claude
LOG_FILE="$OUTPUT_DIR/claude-output.json"
cd "$OUTPUT_DIR"

echo "Plugin dir: $PLUGIN_DIR"
echo "Running claude -p with naive prompt..."
timeout 300 claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns "$MAX_TURNS" \
    --output-format stream-json \
    --verbose \
    > "$LOG_FILE" 2>&1 || true

echo ""
echo "=== Results ==="

# Check if skill was triggered (look for Skill tool invocation)
# In stream-json, tool invocations have "name":"Skill" (not "tool":"Skill")
# Match either "skill":"skillname" or "skill":"namespace:skillname"
SKILL_PATTERN='"skill":"([^"]*:)?'"${SKILL_NAME}"'"'
if grep -q '"name":"Skill"' "$LOG_FILE" && grep -qE "$SKILL_PATTERN" "$LOG_FILE"; then
    echo "✅ PASS: Skill '$SKILL_NAME' was triggered"
    TRIGGERED=true
else
    echo "❌ FAIL: Skill '$SKILL_NAME' was NOT triggered"
    TRIGGERED=false
fi

# Show what skills WERE triggered
echo ""
echo "Skills triggered in this run:"
grep -o '"skill":"[^"]*"' "$LOG_FILE" 2>/dev/null | sort -u || echo "  (none)"

# Show first assistant message
echo ""
echo "First assistant response (truncated):"
grep '"type":"assistant"' "$LOG_FILE" | head -1 | jq -r '.message.content[0].text // .message.content' 2>/dev/null | head -c 500 || echo "  (could not extract)"

echo ""
echo "Full log: $LOG_FILE"
echo "Timestamp: $TIMESTAMP"

if [ "$TRIGGERED" = "true" ]; then
    exit 0
else
    exit 1
fi
