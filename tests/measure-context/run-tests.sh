#!/usr/bin/env bash
# measure-context test suite: unit tests on tools/measure-context.js, the
# committed script that takes the acceptance measure of worklist row 13 fix 1
# (docs/orchestration-issues.md, Cases 017 and 018). Pure bash + node; no
# claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# everything goes through temp files.
#
# The fixture `fixtures/synthetic.jsonl` is built so that every class holds a
# different, hand-chosen number of bytes, and so that one requestId is written
# three times with the same usage object. That repetition is the counting trap
# the script exists to avoid: a naive sum over records overcounts tokens by 3
# to 5 times on a real transcript.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/tools/measure-context.js"
FIXTURE="$ROOT/tests/measure-context/fixtures/synthetic.jsonl"

# The fixture's hand-chosen byte counts, by class.
EXP_AGENT_PROMPTS=100
EXP_FILL_COMMANDS=48
EXP_VALUE_FILES=50
EXP_OTHER_WRITES=30
EXP_BASH_COMMANDS=20
EXP_READ_RESULTS=40
EXP_BASH_RESULTS=25
EXP_AGENT_REPORTS=15
EXP_ATTACHMENTS=60
EXP_USER_MESSAGES=10
EXP_ASSISTANT_TEXT=12
EXP_CONTENT=459
EXP_PROMPT_MATERIAL=198
# The fixture holds three distinct requests, at 1110, 5000 and 2000 context
# tokens. The peak is the largest single request, never their sum (8110), and
# never inflated by the three records that repeat request 2.
EXP_PEAK=5000
EXP_ASSISTANT_RECORDS=5
EXP_DISTINCT_REQUESTS=3
EXP_SUM_OF_REQUESTS=8110

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
: "${WORK:?mktemp failed — refusing to run with an empty work path}"
trap 'rm -rf "$WORK"' EXIT
OUTF="$WORK/stdout.txt"
ERRF="$WORK/stderr.txt"
JSONF="$WORK/measure.json"
STATUS=0

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}

# Read one field out of the JSON report with node, so the test never parses
# JSON with grep.
field() { # dotted-path
  node -e '
    const fs = require("fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const value = process.argv[2].split(".").reduce((o, k) => (o === undefined ? o : o[k]), data);
    process.stdout.write(String(value));
  ' "$JSONF" "$1"
}

run_json() { # transcript
  node "$SCRIPT" "$1" --json >"$JSONF" 2>"$ERRF"
  STATUS=$?
}
run_text() { # transcript
  node "$SCRIPT" "$1" >"$OUTF" 2>"$ERRF"
  STATUS=$?
}

bold "1. The script runs on the fixture and reports every class"
run_json "$FIXTURE"
assert_eq "exits 0 on a readable transcript" "$STATUS" "0"
assert_eq "agent-prompts counts the Agent tool's prompt field" "$(field totals.agent-prompts)" "$EXP_AGENT_PROMPTS"
assert_eq "fill-commands counts a Bash command that fills a template" "$(field totals.fill-commands)" "$EXP_FILL_COMMANDS"
assert_eq "value-files counts a Write to a dispatch-<k>- file" "$(field totals.value-files)" "$EXP_VALUE_FILES"
assert_eq "other-writes counts a Write to any other path" "$(field totals.other-writes)" "$EXP_OTHER_WRITES"
assert_eq "bash-commands counts a Bash command that is not a fill" "$(field totals.bash-commands)" "$EXP_BASH_COMMANDS"
assert_eq "read-results are attributed to the Read tool by tool_use_id" "$(field totals.read-results)" "$EXP_READ_RESULTS"
assert_eq "bash-results are attributed to the Bash tool by tool_use_id" "$(field totals.bash-results)" "$EXP_BASH_RESULTS"
assert_eq "agent-reports are attributed to the Agent tool by tool_use_id" "$(field totals.agent-reports)" "$EXP_AGENT_REPORTS"
assert_eq "attachments count the harness attachment records" "$(field totals.attachments)" "$EXP_ATTACHMENTS"
assert_eq "user-messages count a plain string message" "$(field totals.user-messages)" "$EXP_USER_MESSAGES"
assert_eq "assistant-text counts the model's own prose" "$(field totals.assistant-text)" "$EXP_ASSISTANT_TEXT"

bold "2. The classes are a partition: they sum to the reported content"
assert_eq "content equals the sum of every class" "$(field content)" "$EXP_CONTENT"
SUM="$(node -e '
  const fs = require("fs");
  const d = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(String(Object.values(d.totals).reduce((a, b) => a + b, 0)));
' "$JSONF")"
assert_eq "the class totals add up to content, with nothing uncounted" "$SUM" "$EXP_CONTENT"

bold "3. Prompt material is the three dispatch classes and nothing else"
assert_eq "prompt material is agent-prompts + fill-commands + value-files" "$(field promptMaterial)" "$EXP_PROMPT_MATERIAL"
PCT="$(node -e '
  const fs = require("fs");
  const d = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(d.promptMaterialPercent.toFixed(2));
' "$JSONF")"
assert_eq "the percentage is prompt material over content" "$PCT" "43.14"

bold "4. Token figures deduplicate on requestId — the counting trap"
assert_eq "the fixture really repeats one request across records" "$(field assistantRecords)" "$EXP_ASSISTANT_RECORDS"
assert_eq "distinct requests are counted, not records" "$(field distinctRequests)" "$EXP_DISTINCT_REQUESTS"
assert_eq "peak context is the largest single request" "$(field peakTokens)" "$EXP_PEAK"
# The two numbers the peak must never be: the sum of the distinct requests, and
# anything inflated by the repeated records.
if [ "$(field peakTokens)" = "$EXP_SUM_OF_REQUESTS" ]; then
  bad "peak context must not be the sum of the requests"
else
  ok "peak context is not the sum of the requests"
fi

bold "5. The report names the units and the limits it works under"
run_text "$FIXTURE"
assert_eq "the text report exits 0" "$STATUS" "0"
assert_file_contains "the report says the peak is a maximum, not a sum" "$OUTF" 'a maximum over requests, never a sum'
assert_file_contains "the report says the token figures are deduplicated" "$OUTF" 'deduplicated on requestId'
assert_file_contains "the report names the prompt-material components" "$OUTF" 'agent-prompts + fill-commands + value-files'
# Thinking text is not stored in a transcript (only its signature), so its
# bytes are missing from content and every share is an upper bound. A reader
# who is told this cannot mistake a share for an exact figure.
assert_file_contains "the report warns that thinking text is not stored" "$OUTF" 'thinking blocks carry a signature'
assert_file_contains "the report states the direction of that error" "$OUTF" 'upper bound'

bold "6. Bad input fails loudly, never silently"
run_json "$WORK/does-not-exist.jsonl"
assert_eq "a missing transcript exits 2" "$STATUS" "2"
assert_file_contains "a missing transcript names itself" "$ERRF" 'no such transcript'
node "$SCRIPT" >"$OUTF" 2>"$ERRF"; STATUS=$?
assert_eq "no argument exits 2" "$STATUS" "2"
assert_file_contains "no argument prints the usage line" "$ERRF" 'usage: node tools/measure-context.js'

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
