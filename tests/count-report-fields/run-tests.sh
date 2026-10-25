#!/usr/bin/env bash
# count-report-fields test suite: unit tests on tools/count-report-fields.js,
# the committed script that takes the acceptance measure of release 7.75.0
# (the reviewer evidence line and the inputs-read declaration). Pure bash +
# node; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# output goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-
# and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md, section 9.
#
# The fixture folder holds eight transcripts. Seven are reviewers (the lens
# heading is in the prompt): a report in a SubagentHandback input with a Write
# copy (counted once); a report as a text block with a sentence above its
# marker; a report with no `### Inputs read` section; a section heading
# followed by prose; an evidence line that is not directly below its id line
# and a `whole` line with words after it; a reviewer dispatched by pointer,
# whose prompt is in the Read result of the pointer file; a reviewer without a
# marked report. One is a fix subagent (no lens heading).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/tools/count-report-fields.js"
FIX="$ROOT/tests/count-report-fields/fixtures"
SUBAGENTS="$FIX/subagents"
LOG="$FIX/review-log.md"
EXIT_OK=0
EXIT_USAGE=2
USAGE_FRAGMENT='usage: node tools/count-report-fields.js <subagents-dir> <review-log>'
EXPECTED_COUNTS='reviewer-transcripts: 7  other: 1  reports: 6  with-inputs-read: 3  ci-findings: 5  with-evidence: 3  secret-form-lines: 1  rejected-evidence-lines: 2'
EXPECTED_PER_INPUT='per-input: diff 2/4  plan 1/2  document 1/2  spec 1/1'
# The path part is compared from its last separator on: on Windows Git Bash
# node receives a C:/ path and writes back-slashes.
EXPECTED_NO_REPORT='no report: no-marker-reviewer.jsonl — multi-code-review round 2: Adversarial red-team'
EXPECTED_LINES=3

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }
ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# run_script <out-file> <err-file> [args...]: run the script, leave its exit
# code in STATUS.
run_script() {
  local out="$1" err="$2"
  shift 2
  node "$SCRIPT" "$@" > "$out" 2> "$err"
  STATUS=$?
}
assert_usage_error() { # desc err-file
  assert_eq "$1: exit code" "$STATUS" "$EXIT_USAGE"
  if grep -qF -- "$USAGE_FRAGMENT" "$2"; then ok "$1: prints the usage line"; else bad "$1: prints the usage line"; fi
}

bold "1. Counts over the fixture folder"
OUT="$WORK/out.txt"
run_script "$OUT" "$WORK/err.txt" "$SUBAGENTS" "$LOG"
assert_eq "exit code" "$STATUS" "$EXIT_OK"
assert_eq "line 1: the counts" "$(sed -n 1p "$OUT")" "$EXPECTED_COUNTS"
assert_eq "line 2: the count per expected input" "$(sed -n 2p "$OUT")" "$EXPECTED_PER_INPUT"
assert_eq "line 3: the reviewer transcript without a report, with its description" "$(sed -n 3p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT"
assert_eq "no further line" "$(awk 'END { print NR }' "$OUT")" "$EXPECTED_LINES"

bold "2. Usage errors"
run_script "$WORK/out2.txt" "$WORK/err2.txt"
assert_usage_error "no argument" "$WORK/err2.txt"
run_script "$WORK/out3.txt" "$WORK/err3.txt" "$WORK/missing-folder" "$LOG"
assert_usage_error "a folder that does not exist" "$WORK/err3.txt"
run_script "$WORK/out4.txt" "$WORK/err4.txt" "$SUBAGENTS" "$WORK/missing-log.md"
assert_usage_error "a review log that does not exist" "$WORK/err4.txt"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
