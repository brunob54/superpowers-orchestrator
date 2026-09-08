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

# --- Gate spans -------------------------------------------------------
# Spec gate: checklist item 13 of skills/brainstorming/SKILL.md, up to
# item 14.
BS_SPAN="$WORK/bs-span.txt"
BS_13="$(first_match_from "$BRAINSTORMING" '^13\. ' 1)"
BS_14="$(first_match_from "$BRAINSTORMING" '^14\. ' "$((${BS_13:-0} + 1))")"
slice_to "spec gate span (step 13)" "$BRAINSTORMING" "$BS_13" "$BS_14" "$BS_SPAN"
BS_NORM="$WORK/bs-span-norm.txt"
normalize_to "$BS_SPAN" "$BS_NORM"
BS_FILE_NORM="$WORK/bs-file-norm.txt"
normalize_to "$BRAINSTORMING" "$BS_FILE_NORM"

# Wording contracts shared by every gate.
ANCHOR='ask the user for N and M'
D_MARKER='the value of the `<reviewers-per-lens>` tag emitted by'
D_TAIL='never a parameter'
COST_LINE='The M reviewers of a round run at the same time, so running time stays close to one review; the token cost grows about M times per round, and the loop runs about N × M reviewers in total.'
SHARED_PINS=(
  'in one question batch'
  'before reading any count as N'
  'inside quoted or pasted material'
  'is authoritative and overrides'
  'never inherited'
)
SUPPRESSION='already holds an invocation entry from this gate'
NO_INVOKE_PHRASE='at most once per gate'

bold "1/3/4/5. Spec gate (brainstorming step 13)"
assert_icontains "spec gate asks for N and M" "$BS_NORM" "$ANCHOR"
assert_order "spec gate: platform check before the question" "$BS_NORM" \
  'lacks the Agent tool' "$ANCHOR"
assert_order "spec gate: suppression check before the question" "$BS_NORM" \
  "$SUPPRESSION" "$ANCHOR"
assert_order "spec gate: question before the invocation" "$BS_NORM" \
  "$ANCHOR" 'invoke `superpowers-orchestrator:multi-doc-review` on the saved spec'
assert_icontains "spec gate carries the cost sentence" "$BS_NORM" "$COST_LINE"
for pin in "${SHARED_PINS[@]}"; do
  assert_contains "spec gate shared rules block pin: $pin" "$BS_NORM" "$pin"
done
assert_contains "spec gate passes the tokens last" "$BS_NORM" '`N=<n> M=<m>` as the last tokens'

bold "11. The spec gate no longer suppresses the invocation"
assert_not_icontains "brainstorming drops 'at most once per gate'" "$BS_FILE_NORM" "$NO_INVOKE_PHRASE"
assert_icontains "brainstorming leaves the run/resume/skip decision to the skill" "$BS_FILE_NORM" \
  'decides whether the loop runs, resumes or is skipped'

# Plan gate: the `## Multi-Round Plan Review` section of
# skills/writing-plans/SKILL.md, up to `## Execution Handoff`.
WP_SPAN="$WORK/wp-span.txt"
WP_START="$(first_line_of "$WRITING_PLANS" '## Multi-Round Plan Review')"
WP_END="$(first_line_of "$WRITING_PLANS" '## Execution Handoff')"
slice_to "plan gate span (Multi-Round Plan Review)" "$WRITING_PLANS" "$WP_START" "$WP_END" "$WP_SPAN"
WP_NORM="$WORK/wp-span-norm.txt"
normalize_to "$WP_SPAN" "$WP_NORM"
WP_FILE_NORM="$WORK/wp-file-norm.txt"
normalize_to "$WRITING_PLANS" "$WP_FILE_NORM"

bold "1/3/4/5. Plan gate (writing-plans Multi-Round Plan Review)"
assert_icontains "plan gate asks for N and M" "$WP_NORM" "$ANCHOR"
assert_order "plan gate: platform check before the question" "$WP_NORM" \
  'lacks the Agent tool' "$ANCHOR"
assert_order "plan gate: suppression check before the question" "$WP_NORM" \
  "$SUPPRESSION" "$ANCHOR"
assert_order "plan gate: question before the invocation" "$WP_NORM" \
  "$ANCHOR" 'invoke `superpowers-orchestrator:multi-doc-review` on the saved plan'
assert_icontains "plan gate carries the cost sentence" "$WP_NORM" "$COST_LINE"
for pin in "${SHARED_PINS[@]}"; do
  assert_contains "plan gate shared rules block pin: $pin" "$WP_NORM" "$pin"
done
assert_contains "plan gate passes the tokens last" "$WP_NORM" '`N=<n> M=<m>` as the last tokens'

bold "11. The plan gate no longer suppresses the invocation"
assert_not_icontains "writing-plans drops 'at most once per gate'" "$WP_FILE_NORM" "$NO_INVOKE_PHRASE"
assert_icontains "writing-plans leaves the run/resume/skip decision to the skill" "$WP_NORM" \
  'decides whether the loop runs, resumes or is skipped'
assert_icontains "plan gate still re-runs only Self-Review after plan changes" "$WP_NORM" \
  're-run only Self-Review'

# Code gate: Core Flow step 4 of skills/subagent-driven-development/SKILL.md.
# The naive rule fails — `^4\. ` and `^5\. ` both match several times in this
# file — so both anchors are resolved relative to the `## Core Flow`
# heading, and the suite FAILs when either does not resolve.
SDD_SPAN="$WORK/sdd-span.txt"
SDD_CORE="$(first_line_of "$SDD" '## Core Flow')"
SDD_S4="$(first_match_from "$SDD" '^4\. ' "$((${SDD_CORE:-0} + 1))")"
SDD_S5="$(first_match_from "$SDD" '^5\. ' "$((${SDD_S4:-0} + 1))")"
slice_to "code gate span (Core Flow step 4)" "$SDD" "$SDD_S4" "$SDD_S5" "$SDD_SPAN"
SDD_NORM="$WORK/sdd-span-norm.txt"
normalize_to "$SDD_SPAN" "$SDD_NORM"

# Batched Autonomous Mode span: from the whole line `## Batched Autonomous
# Mode` to the end of the file. The bare string occurs five times, first in
# the frontmatter, so only the whole-line heading may anchor it.
BAM_SPAN="$WORK/bam-span.txt"
BAM_START="$(first_line_of "$SDD" '## Batched Autonomous Mode')"
SDD_LINES="$(awk 'END { print NR + 1 }' "$SDD")"
slice_to "batched autonomous mode span" "$SDD" "$BAM_START" "$SDD_LINES" "$BAM_SPAN"
BAM_NORM="$WORK/bam-span-norm.txt"
normalize_to "$BAM_SPAN" "$BAM_NORM"

FINDINGS_PHRASE="the ledger's carried Minor-findings list"
# Integration span: from the whole line `## Integration` to the end of the
# file. It carries a SECOND copy of the fallback condition, so the check
# below must be scoped to it — step 4's own text would otherwise satisfy a
# whole-file check.
INTEG_SPAN="$WORK/integ-span.txt"
INTEG_START="$(first_line_of "$SDD" '## Integration')"
slice_to "SDD Integration span" "$SDD" "$INTEG_START" "$SDD_LINES" "$INTEG_SPAN"
INTEG_NORM="$WORK/integ-norm.txt"
normalize_to "$INTEG_SPAN" "$INTEG_NORM"

bold "1/3/4/5. Code gate (subagent-driven-development Core Flow step 4)"
assert_icontains "code gate asks for N and M" "$SDD_NORM" "$ANCHOR"
assert_order "code gate: platform check before the question" "$SDD_NORM" \
  '`multi-code-review` refuses' "$ANCHOR"
assert_order "code gate: batched-mode exception before the question" "$SDD_NORM" \
  'Batched Autonomous Mode' "$ANCHOR"
assert_order "code gate: question before the invocation" "$SDD_NORM" \
  "$ANCHOR" 'invoke the `multi-code-review` skill once'
assert_icontains "code gate carries the cost sentence" "$SDD_NORM" "$COST_LINE"
assert_icontains "code gate adds the whole-branch-diff clause" "$SDD_NORM" \
  'Each reviewer here reads the whole-branch diff.'
for pin in "${SHARED_PINS[@]}"; do
  assert_contains "code gate shared rules block pin: $pin" "$SDD_NORM" "$pin"
done

bold "7/8/9. The code gate's subagent and batched paths"
assert_not_icontains "step 4 no longer says 'never ask for M'" "$SDD_NORM" 'never ask for M'
assert_icontains "Batched Autonomous Mode still says 'never ask for M'" "$BAM_NORM" 'never ask for M'
assert_contains "step 4 pins the batched path to passing resolved tokens" "$SDD_NORM" \
  'pass `N=<n> M=<m>` resolved by that mode'"'"'s own rule'
assert_contains "step 4 names Cursor in its platform condition" "$SDD_NORM" 'Cursor'
# The second half of step 4 is carried over by retyping it. Pin one
# fragment of each rule the contract says must survive unchanged.
assert_contains "step 4 keeps the plan.ref pointer" "$SDD_NORM" '`.superpowers/sdd/plan.ref`'
assert_contains "step 4 keeps the outside-the-layout direct-mode rule" "$SDD_NORM" \
  'direct mode under `.superpowers/reviews/`'
assert_contains "step 4 keeps the completion-blocking sentence" "$SDD_NORM" \
  'block completion exactly as unresolved review findings do'
# The Integration section carries a second copy of the fallback condition;
# a reader sent there from step 4 must find the same three platforms.
assert_icontains "Integration names the same three refusal platforms" "$INTEG_NORM" \
  'no Agent tool, Codex, or Cursor'
assert_not_icontains "Integration drops the Agent-tool-only condition" "$INTEG_NORM" \
  'On platforms without the Agent tool'
CG_FINDINGS="$(first_offset "$SDD_NORM" "$FINDINGS_PHRASE")"; CG_FINDINGS="${CG_FINDINGS:-0}"
CG_TOKENS="$(last_offset "$SDD_NORM" 'N=<n> M=<m>')"; CG_TOKENS="${CG_TOKENS:-0}"
if [ "$CG_FINDINGS" -gt 0 ] && [ "$CG_TOKENS" -gt "$CG_FINDINGS" ]; then
  ok "step 4: the gate's tokens are the most recent forms in the invocation"
else
  bad "step 4: N=<n> M=<m> (at $CG_TOKENS) must come after the carried-findings phrase (at $CG_FINDINGS)"
fi

bold "2. Anti-drift: the <d> definition is identical in four files"
D_SPANS=()
for pair in "orchestrating-development:$ORCH" "brainstorming:$BRAINSTORMING" \
            "writing-plans:$WRITING_PLANS" "subagent-driven-development:$SDD"; do
  name="${pair%%:*}"
  file="${pair#*:}"
  norm="$WORK/d-$name.txt"
  normalize_to "$file" "$norm"
  n="$(count_occurrences "$norm" "$D_MARKER")"
  assert_eq "$name carries the <d> marker exactly once" "$n" "1"
  span="$(marker="$D_MARKER" tail="$D_TAIL" awk '
    BEGIN { m = ENVIRON["marker"]; t = ENVIRON["tail"] }
    { i = index($0, m); if (i == 0) { print ""; exit }
      rest = substr($0, i)
      j = index(rest, t); if (j == 0) { print ""; exit }
      print substr(rest, 1, j + length(t) - 1); exit }' "$norm")"
  if [ -z "$span" ]; then
    bad "$name: could not extract the <d> span from the marker to '$D_TAIL'"
  else
    ok "$name: <d> span extracted (${#span} characters)"
  fi
  D_SPANS+=("$span")
done
for i in 1 2 3; do
  assert_eq "the <d> span of file $((i + 1)) equals the orchestrator's" \
    "${D_SPANS[$i]}" "${D_SPANS[0]}"
done

bold "12/13/14. No subagent path can reach a gate question"
ORCH_DIR="$ROOT/skills/orchestrating-development"
PW_NORM="$WORK/plan-writer.txt"
DR_NORM="$WORK/doc-review-loop.txt"
BC_NORM="$WORK/batch-controller.txt"
normalize_to "$ORCH_DIR/plan-writer-prompt.md" "$PW_NORM"
normalize_to "$ORCH_DIR/doc-review-loop-prompt.md" "$DR_NORM"
normalize_to "$ORCH_DIR/batch-controller-prompt.md" "$BC_NORM"
assert_icontains "plan-writer-prompt still skips Multi-Round Plan Review" "$PW_NORM" \
  'SKIP its "Multi-Round Plan Review" and "Execution Handoff" sections entirely'
assert_icontains "doc-review-loop-prompt Deviation 1 names the Self-Review checklist" "$DR_NORM" \
  'run the "Self-Review" checklist'
assert_not_icontains "doc-review-loop-prompt does not name Multi-Round Plan Review" "$DR_NORM" \
  'Multi-Round Plan Review'
assert_not_icontains "batch-controller-prompt does not name Core Flow step 4" "$BC_NORM" \
  '"Core Flow" step 4'
assert_icontains "batch-controller-prompt still names only Core Flow step 3" "$BC_NORM" \
  '"Core Flow" step 3 (the per-task loop)'

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
