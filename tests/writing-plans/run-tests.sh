#!/usr/bin/env bash
# writing-plans wording test suite: static checks on
# skills/writing-plans/SKILL.md for the contracts-not-bodies rules.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows).
#
# Matching rule (design R6): binding literal labels are byte pins, matched
# exactly and case-sensitively (grep -F); free-text fragments are matched
# case-insensitively (grep -iF) because free text gets reworded by review
# fixes.
#
# Contract source: docs/superpowers-orchestrator/
# 2026-08-31-plan-contracts-not-bodies/specs/
# plan-contracts-not-bodies-design.md, section R6.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$ROOT/skills/writing-plans/SKILL.md"

# Binding literal labels (byte pins).
SECTION_HEADING='## Contracts and Literal Bodies'
EXACT_LABEL='**Exact content:**'
CONTRACT_LABEL='**Contract:**'

# Binding free-text fragments.
FRAG_ORDINARY_FIX='ordinary fix'
FRAG_SELF_PIN='together as one ordinary fix'

PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

# Byte-pin match: exact, case-sensitive.
assert_exact() { # desc needle
  if grep -qF -- "$2" "$SKILL"; then ok "$1"; else bad "$1 (missing: $2)"; fi
}

# Free-text fragment match: case-insensitive.
assert_fragment() { # desc needle
  if grep -qiF -- "$2" "$SKILL"; then ok "$1"; else bad "$1 (missing: $2)"; fi
}

# Line number of the first line containing the fixed string $1; empty when
# absent.
first_line_of() { grep -nF -- "$1" "$SKILL" | head -n 1 | cut -d: -f1; }

# Line number of the first line after line $2 whose text starts with $1;
# empty when absent.
line_starting_with_after() {
  awk -v pfx="$1" -v start="$2" \
    'NR > start && index($0, pfx) == 1 { print NR; exit }' "$SKILL"
}

# Assert that string $2 occurs inside the fenced block that follows heading
# $3. $4 is the fence prefix ("```" or "````"); $5 is the match mode:
# "exact" (case-sensitive) or "fragment" (case-insensitive).
assert_in_block() { # desc needle heading fence mode
  local desc="$1" needle="$2" heading="$3" fence="$4" mode="$5"
  local h open close hit
  h="$(first_line_of "$heading")"
  if [ -z "$h" ]; then bad "$desc (no heading: $heading)"; return; fi
  open="$(line_starting_with_after "$fence" "$h")"
  if [ -z "$open" ]; then bad "$desc (no $fence fence after the heading)"; return; fi
  close="$(line_starting_with_after "$fence" "$open")"
  if [ -z "$close" ]; then bad "$desc (no closing $fence fence)"; return; fi
  if [ "$mode" = "exact" ]; then
    hit="$(awk -v needle="$needle" -v a="$open" -v b="$close" \
      'NR > a && NR < b && index($0, needle) > 0 { print NR; exit }' "$SKILL")"
  else
    hit="$(awk -v needle="$needle" -v a="$open" -v b="$close" \
      'NR > a && NR < b && index(tolower($0), tolower(needle)) > 0 { print NR; exit }' "$SKILL")"
  fi
  if [ -n "$hit" ]; then
    ok "$desc (line $hit, block $open..$close)"
  else
    bad "$desc (not inside block $open..$close)"
  fi
}

bold "1. Contracts and Literal Bodies section (R1)"
assert_exact "section heading '$SECTION_HEADING'" "$SECTION_HEADING"
assert_exact "exact-content label '$EXACT_LABEL'" "$EXACT_LABEL"
assert_fragment "authority-default fragment '$FRAG_ORDINARY_FIX'" "$FRAG_ORDINARY_FIX"
assert_fragment "self-pin fragment '$FRAG_SELF_PIN'" "$FRAG_SELF_PIN"

bold "2. Task Template Contract field (R2)"
assert_in_block "Task Template block carries '$CONTRACT_LABEL'" \
  "$CONTRACT_LABEL" '## Task Template' '````' exact

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
