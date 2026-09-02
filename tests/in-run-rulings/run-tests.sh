#!/usr/bin/env bash
# in-run-rulings wording test suite: static checks on the wording that the
# autonomous in-run decisions design requires in
# skills/orchestrating-development/SKILL.md, its two controller prompt
# templates, and skills/multi-code-review/SKILL.md.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows).
#
# Matching rule (design R11): binding literal labels are byte pins, matched
# exactly and case-sensitively; free-text fragments are matched
# case-insensitively, because free text gets reworded by review fixes.
# Every fragment is scoped to the section it pins, so that deleting the
# rule cannot pass on a mention of the same words elsewhere in the file.
#
# Contract source: docs/superpowers-orchestrator/
# 2026-09-02-autonomous-in-run-decisions/specs/
# autonomous-in-run-decisions-design.md, section R11.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORCH_SKILL="$ROOT/skills/orchestrating-development/SKILL.md"
LOOP_PROMPT="$ROOT/skills/orchestrating-development/code-review-loop-prompt.md"
BATCH_PROMPT="$ROOT/skills/orchestrating-development/batch-controller-prompt.md"
MCR_SKILL="$ROOT/skills/multi-code-review/SKILL.md"

PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

# Line number of the first line of file $1 whose entire content equals the
# fixed string $2 (whole-line match); empty when absent. Headings are
# located this way so that a prose mention of the heading text cannot
# retarget a range.
first_line_of() { grep -nxF -- "$2" "$1" | head -n 1 | cut -d: -f1; }

# Line number of the first line of file $1 after line $3 that contains the
# fixed string $2 anywhere; empty when absent.
line_containing_after() {
  awk -v needle="$2" -v start="$3" \
    'NR > start && index($0, needle) > 0 { print NR; exit }' "$1"
}

# Line number of the first line of file $1 after line $3 whose text starts
# with the fixed string $2; empty when absent.
line_starting_with_after() {
  awk -v pfx="$2" -v start="$3" \
    'NR > start && index($0, pfx) == 1 { print NR; exit }' "$1"
}

# Assert that the fixed string $3 occurs in file $2 on a line at or after
# line $4 (inclusive) and before line $5 (exclusive). $6 is the match mode:
# "exact" (case-sensitive byte pin) or "fragment" (case-insensitive).
assert_in_range() { # desc file needle start end mode
  local desc="$1" file="$2" needle="$3" start="$4" end="$5" mode="$6"
  local hit
  if [ -z "$start" ] || [ -z "$end" ]; then
    bad "$desc (could not locate the range to search in ${file#$ROOT/})"
    return
  fi
  if [ "$mode" = "exact" ]; then
    hit="$(awk -v needle="$needle" -v a="$start" -v b="$end" \
      'NR >= a && NR < b && index($0, needle) > 0 { print NR; exit }' "$file")"
  else
    hit="$(awk -v needle="$needle" -v a="$start" -v b="$end" \
      'NR >= a && NR < b && index(tolower($0), tolower(needle)) > 0 { print NR; exit }' "$file")"
  fi
  if [ -n "$hit" ]; then
    ok "$desc (line $hit, range $start..$end)"
  else
    bad "$desc (not inside range $start..$end of ${file#$ROOT/})"
  fi
}

# Assert that the fixed string $3 occurs anywhere in file $2 (byte pin).
assert_pin() { # desc file needle
  if grep -qF -- "$3" "$2"; then
    ok "$1"
  else
    bad "$1 (byte pin absent from ${2#$ROOT/})"
  fi
}

# Range anchors in orchestrating-development/SKILL.md. Headings are
# whole-line matches. The `## In-run rulings` section ends where the
# `## Major-Error Stop Policy` heading begins, because the section's own
# log-entry examples start lines with `## ` and a "next heading" search
# would stop at one of them.
RULINGS_HEADING='## In-run rulings'
RULINGS_LINE="$(first_line_of "$ORCH_SKILL" "$RULINGS_HEADING")"
RULINGS_END="$(first_line_of "$ORCH_SKILL" '## Major-Error Stop Policy')"

bold "1. Escalation predicate (R1)"
if [ -n "$RULINGS_LINE" ]; then
  ok "section heading '$RULINGS_HEADING' (whole-line match, line $RULINGS_LINE)"
else
  bad "section heading '$RULINGS_HEADING' (no whole line matches)"
fi
for label in '`escalated`' '`forced`' '`design`' '`spec wrong`' '`scope`' \
             '`irreversible`' '`secret`' '`chain`' 'escalated (chain)'; do
  assert_in_range "class or reason label $label" \
    "$ORCH_SKILL" "$label" "$RULINGS_LINE" "$RULINGS_END" exact
done
for frag in 'escalation wins' '### Conflict' '### Question' \
            'fatal environment failure' 'never `spec wrong`' \
            'handled as a whole' 'applied twice'; do
  assert_in_range "predicate fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_LINE" "$RULINGS_END" fragment
done

# --- end of checks ---

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
