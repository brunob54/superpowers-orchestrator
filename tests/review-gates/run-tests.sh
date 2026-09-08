#!/usr/bin/env bash
# review-gates wording test suite: static checks on the three interactive
# review gates (brainstorming spec gate, writing-plans plan gate,
# subagent-driven-development code gate) and on the two review skills those
# gates invoke.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# extracted text goes through temp files.
#
# Matching rule (design section 9): binding literal labels are byte pins,
# matched exactly and case-sensitively (grep -F); free-text fragments are
# matched case-insensitively (grep -iF) because free text gets reworded by
# review fixes.
#
# Contract source: docs/superpowers-orchestrator/
# 2026-09-08-review-gate-m-question/specs/review-gate-m-question-design.md,
# section 9.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRAINSTORMING="$ROOT/skills/brainstorming/SKILL.md"
WRITING_PLANS="$ROOT/skills/writing-plans/SKILL.md"
SDD="$ROOT/skills/subagent-driven-development/SKILL.md"
ORCH="$ROOT/skills/orchestrating-development/SKILL.md"
MDR="$ROOT/skills/multi-doc-review/SKILL.md"
MCR="$ROOT/skills/multi-code-review/SKILL.md"

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
: "${WORK:?mktemp failed — refusing to run with an empty work path}"
trap 'rm -rf "$WORK"' EXIT

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }
ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

# Normalization (design section 9): strip leading blanks, then blockquote
# markers, then one list bullet from every line; then collapse every run of
# whitespace, newlines included, to one space. The same sentence appears as
# prose, as a blockquote and as a numbered list item across these files, so
# raw byte comparison cannot work.
normalize_file() { # file -> one normalized line on stdout
  awk '{
    line = $0
    sub(/^[ \t]+/, "", line)
    while (sub(/^>[ \t]?/, "", line)) { sub(/^[ \t]+/, "", line) }
    sub(/^([-*+]|[0-9]+\.)[ \t]+/, "", line)
    print line
  }' "$1" | tr '\n\t' '  ' | tr -s ' '
}
normalize_to() { normalize_file "$1" > "$2"; }

assert_contains() { # desc file needle (byte pin, case-sensitive)
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_icontains() { # desc file needle (free text, case-insensitive)
  if grep -qiF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_not_icontains() { # desc file needle (case-insensitive)
  if grep -qiF -- "$3" "$2"; then bad "$1 (must not contain, in any case: $3)"; else ok "$1"; fi
}
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}

# 1-based character offset of the FIRST occurrence of fixed string $2 in the
# single-line file $1; 0 when absent. The needle reaches awk through the
# environment so that no character of it is reinterpreted.
first_offset() { # file needle
  needle="$2" awk 'BEGIN { n = ENVIRON["needle"] } { print index($0, n); exit }' "$1"
}
# 1-based character offset of the LAST occurrence; 0 when absent.
last_offset() { # file needle
  needle="$2" awk 'BEGIN { n = ENVIRON["needle"] }
    { s = $0; base = 0; pos = 0
      while ((i = index(s, n)) > 0) { pos = base + i; base = pos; s = substr(s, i + 1) }
      print pos; exit }' "$1"
}
# Number of occurrences of fixed string $2 in the single-line file $1.
count_occurrences() { # file needle
  needle="$2" awk 'BEGIN { n = ENVIRON["needle"] }
    { s = $0; c = 0
      while ((i = index(s, n)) > 0) { c++; s = substr(s, i + 1) }
      print c; exit }' "$1"
}
# Ordering assertions carry free-text fragments (design section 9 lists
# assertions 1, 3, 4 and 5 as free text), so both the text and the needles
# are lowercased before the offsets are compared.
assert_order() { # desc file earlier-needle later-needle
  local a b lc n3 n4
  lc="$WORK/order-lc.txt"
  tr '[:upper:]' '[:lower:]' < "$2" > "$lc"
  n3="$(printf '%s' "$3" | tr '[:upper:]' '[:lower:]')"
  n4="$(printf '%s' "$4" | tr '[:upper:]' '[:lower:]')"
  # An unresolved span leaves an empty file, on which awk runs no main
  # block and prints nothing; default to 0 so the comparisons below stay
  # integer comparisons instead of raising "integer expression expected".
  a="$(first_offset "$lc" "$n3")"; a="${a:-0}"
  b="$(first_offset "$lc" "$n4")"; b="${b:-0}"
  if [ "$a" -eq 0 ]; then bad "$1 (missing: $3)"
  elif [ "$b" -eq 0 ]; then bad "$1 (missing: $4)"
  elif [ "$a" -lt "$b" ]; then ok "$1"
  else bad "$1 ('$3' at $a is not before '$4' at $b)"; fi
}

# Line number of the first line of file $1 equal to $2 as a whole line;
# empty when absent.
first_line_of() { grep -nxF -- "$2" "$1" | head -n 1 | cut -d: -f1; }
# Line number of the first line of file $1 at or after line $3 whose text
# matches the extended regular expression $2; empty when absent.
first_match_from() { # file ere from-line
  awk -v re="$2" -v from="$3" 'NR >= from && $0 ~ re { print NR; exit }' "$1"
}
# Write lines $3..$4-1 of file $2 into file $5, labelling the check $1. An
# unresolved anchor writes an empty file and FAILs, so every later check on
# that file fails visibly.
slice_to() { # label file start end out
  if [ -z "$3" ] || [ -z "$4" ] || [ "$3" -ge "$4" ]; then
    : > "$5"
    bad "$1: could not locate the span (start='$3' end='$4')"
    return
  fi
  awk -v s="$3" -v e="$4" 'NR >= s && NR < e' "$2" > "$5"
  ok "$1: span located ($3..$4)"
}

MDR_NORM="$WORK/mdr.txt"
MCR_NORM="$WORK/mcr.txt"
normalize_to "$MDR" "$MDR_NORM"
normalize_to "$MCR" "$MCR_NORM"

bold "6. The review skills still refuse to ask for M"
assert_contains "multi-doc-review keeps 'Never ask for M'" "$MDR_NORM" 'Never ask for M'
assert_contains "multi-code-review keeps 'Never ask for M'" "$MCR_NORM" 'Never ask for M'
assert_contains "multi-code-review keeps '(in every mode)'" "$MCR_NORM" '(in every mode)'

bold "10. Both review skills parse N=<n>"
assert_contains "multi-doc-review N section names N=<n>" "$MDR_NORM" '**N (round cap):** if the user stated a count, use it — `N=<n>`'
assert_contains "multi-code-review N section names N=<n>" "$MCR_NORM" '**N (round cap):** if the user stated a count, use it — `N=<n>`'
assert_contains "multi-code-review lifts N= out before the positional BASE rule" "$MCR_NORM" 'Every `N=<n>` and `M=<m>` token'
assert_contains "multi-doc-review frontmatter shows the N=<n> form" "$MDR_NORM" \
  '/multi-doc-review <doc-path> [N|N=<n>] [M=<m>]'
assert_contains "multi-code-review frontmatter shows the N=<n> form" "$MCR_NORM" \
  '/multi-code-review [BASE] [N|N=<n>] [M=<m>]'
# The rules the Task 1 contract says must survive the BASE-bullet edit.
assert_contains "multi-code-review keeps the BASE ref charset rule" "$MCR_NORM" \
  '`^[A-Za-z0-9._/~^{}-]+$`'
assert_contains "multi-code-review keeps the default-branch clause" "$MCR_NORM" \
  'take `git merge-base <default> HEAD`'
assert_contains "multi-code-review keeps the single-argument form rule" "$MCR_NORM" \
  'Single-argument form: an integer 0–10 is N'
assert_contains "multi-code-review keeps the Batched Autonomous Mode sentence" "$MCR_NORM" \
  '**Batched Autonomous Mode never asks:**'

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
