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
BODY_AUTHORITY_LABEL='**Body authority:**'

# Binding free-text fragments.
FRAG_ORDINARY_FIX='ordinary fix'
FRAG_SELF_PIN='together as one ordinary fix'
FRAG_REF_IMPL='reference implementations'
FRAG_FALSIFIABLE='falsifiable'
FRAG_NOT_PROCEDURAL='not procedural'

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

# Line number of the first line whose entire content equals the fixed
# string $1 (whole-line match); empty when absent. Callers pass full
# heading lines, so a partial-match (containment) search could be
# retargeted by an unrelated prose mention of the same text earlier in the
# file — whole-line anchoring avoids that.
first_line_of() { grep -nxF -- "$1" "$SKILL" | head -n 1 | cut -d: -f1; }

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

# Assert that string $2 occurs on a line at or after line number $3
# (inclusive — the rule or check's own heading line often carries its body
# on the same line) and before line number $4 (exclusive). $5 is the match
# mode: "exact" (case-sensitive) or "fragment" (case-insensitive). Scopes a
# fragment assertion to the rule or check it is meant to pin, instead of
# searching the whole file — a whole-file search still passes after the
# pinned rule is deleted, as long as the fragment happens to appear
# elsewhere.
assert_in_range() { # desc needle start end mode
  local desc="$1" needle="$2" start="$3" end="$4" mode="$5"
  local hit
  if [ -z "$start" ] || [ -z "$end" ]; then
    bad "$desc (could not locate the range to search)"
    return
  fi
  if [ "$mode" = "exact" ]; then
    hit="$(awk -v needle="$needle" -v a="$start" -v b="$end" \
      'NR >= a && NR < b && index($0, needle) > 0 { print NR; exit }' "$SKILL")"
  else
    hit="$(awk -v needle="$needle" -v a="$start" -v b="$end" \
      'NR >= a && NR < b && index(tolower($0), tolower(needle)) > 0 { print NR; exit }' "$SKILL")"
  fi
  if [ -n "$hit" ]; then
    ok "$desc (line $hit, range $start..$end)"
  else
    bad "$desc (not inside range $start..$end)"
  fi
}

# Line ranges for the fragments that must be scoped to one rule or check
# each, rather than matched anywhere in the file (see assert_in_range).
CONTRACTS_HEADING_LINE="$(first_line_of "$SECTION_HEADING")"
RULE1_LINE="$(line_starting_with_after '1. **State a contract for every governed artifact.**' "$CONTRACTS_HEADING_LINE")"
RULE2_LINE="$(line_starting_with_after '2. **Pin an interface only when something outside the plan depends on' "$RULE1_LINE")"
RULE3_LINE="$(line_starting_with_after '3. **Bodies are reference implementations by default.**' "$CONTRACTS_HEADING_LINE")"
RULE4_LINE="$(line_starting_with_after '4. **Mark exact content explicitly.**' "$RULE3_LINE")"
RULE5_LINE="$(line_starting_with_after '5. **A self-pin never justifies the marker.**' "$RULE4_LINE")"
RULE6_LINE="$(line_starting_with_after '6. **Boundaries.**' "$RULE5_LINE")"
SELF_REVIEW_5_LINE="$(line_starting_with_after '**5. Contract audit:**' "$CONTRACTS_HEADING_LINE")"
SELF_REVIEW_5_END_LINE="$(line_starting_with_after 'If you find issues, fix them inline.' "$SELF_REVIEW_5_LINE")"

bold "1. Contracts and Literal Bodies section (R1)"
assert_exact "section heading '$SECTION_HEADING'" "$SECTION_HEADING"
assert_in_range "exact-content label '$EXACT_LABEL' (rule 4)" \
  "$EXACT_LABEL" "$RULE4_LINE" "$RULE5_LINE" exact
assert_in_range "procedural tie-break fragment '$FRAG_NOT_PROCEDURAL' (rule 1)" \
  "$FRAG_NOT_PROCEDURAL" "$RULE1_LINE" "$RULE2_LINE" fragment
assert_in_range "authority-default fragment '$FRAG_ORDINARY_FIX' (rule 3)" \
  "$FRAG_ORDINARY_FIX" "$RULE3_LINE" "$RULE4_LINE" fragment
assert_in_range "self-pin fragment '$FRAG_SELF_PIN' (rule 5)" \
  "$FRAG_SELF_PIN" "$RULE5_LINE" "$RULE6_LINE" fragment

bold "2. Task Template Contract field (R2)"
assert_in_block "Task Template block carries '$CONTRACT_LABEL'" \
  "$CONTRACT_LABEL" '## Task Template' '````' exact

bold "3. Plan Header authority note (R3)"
assert_in_block "Plan Header template carries '$FRAG_REF_IMPL'" \
  "$FRAG_REF_IMPL" '## Plan Header' '```' fragment
assert_in_block "Plan Header template carries '$BODY_AUTHORITY_LABEL'" \
  "$BODY_AUTHORITY_LABEL" '## Plan Header' '```' exact

bold "4. Self-Review contract audit (R4)"
assert_in_range "self-review fragment '$FRAG_FALSIFIABLE' (check 5)" \
  "$FRAG_FALSIFIABLE" "$SELF_REVIEW_5_LINE" "$SELF_REVIEW_5_END_LINE" fragment

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
