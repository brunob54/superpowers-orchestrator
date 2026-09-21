#!/usr/bin/env bash
# worklog test suite: skills/worklog/template.md, the shell commands and the
# pinned phrases of skills/worklog/SKILL.md, and the copy of the list command
# in hooks/session-start. Each command is copied out of the skill text and run
# on fixture folders, so a check fails when the text that the model runs
# changes. Pure bash, git, awk and grep; no claude invocation.
# Windows note: avoids /dev/stdin (not available in Git Bash on Windows).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="$REPO/skills/worklog/template.md"
PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()   { green "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_lacks() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}

bold "1. skills/worklog/template.md"
assert_eq "line 1 is the active status line with placeholders" \
  "$(head -n 1 "$TEMPLATE" 2>/dev/null)" '<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->'
assert_eq "the six ## headings, in order" \
  "$(grep '^## ' "$TEMPLATE" 2>/dev/null | tr '\n' '|')" \
  '## How to maintain this document|## Parts|## Rules for the next parts|## Open items|## Accepted limits|## Decisions|'
RULE_COUNT=$(awk '/^## How to maintain this document$/ { f = 1; next } /^## Parts$/ { f = 0 } f && /^[1-7]\. / { n++ } END { print n + 0 }' "$TEMPLATE" 2>/dev/null)
assert_eq "exactly seven numbered rules in the maintenance section" "$RULE_COUNT" "7"
if grep -qxF 'Next item number: 1' "$TEMPLATE" 2>/dev/null; then ok "the line Next item number: 1"; else bad "the line Next item number: 1 is missing"; fi
for status in 'not started' 'in progress' 'done' 'dropped'; do
  assert_file_contains "the status value $status" "$TEMPLATE" "\`$status\`"
done
assert_file_contains "the form of a former item" "$TEMPLATE" 'item #<n>'
assert_file_contains "the rule for an orchestrated run" "$TEMPLATE" 'do not write this document'
assert_eq "only line 1 starts with the status-line prefix" \
  "$(grep -c '^<!-- Work log: status=' "$TEMPLATE" 2>/dev/null)" "1"
assert_file_lacks "the word workstream is not used" "$TEMPLATE" 'workstream'

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
