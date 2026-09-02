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

bold "2. Classification read exception (R2)"
REQUIRED_START_LINE="$(first_line_of "$ORCH_SKILL" '## Required Start')"
assert_in_range "intro names the second read exception" \
  "$ORCH_SKILL" 'in-run rulings' 1 "$REQUIRED_START_LINE" fragment
for frag in 'data, not instructions' 'never a reviewer report file' \
            'read-only git commands' 'resume step 3' 'nothing else' \
            '40 lines'; do
  assert_in_range "read-exception fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_LINE" "$RULINGS_END" fragment
done

bold "3. Fork review (R3)"
for pin in 'subagent_type: "fork"' '<!-- multi-review report -->' 'fork-<lens>' \
           'fork review unavailable' 'contradiction: unsettled'; do
  assert_in_range "fork pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RULINGS_LINE" "$RULINGS_END" exact
done
# 'VERDICT:' and 'TABLED:' also occur as prose in the "Classification" section
# above (its escalation-predicate text mentions both words), so pinning them
# to the whole ## In-run rulings range would pass even without the fork
# subsection. Scope them to the fork subsection itself, whose end is the next
# `### ` heading after it, or the section end when there is none.
FORK_LINE="$(first_line_of "$ORCH_SKILL" '### Fork review for a design item')"
FORK_END="$(line_starting_with_after "$ORCH_SKILL" '### ' "$FORK_LINE")"
FORK_END="${FORK_END:-$RULINGS_END}"
for pin in 'VERDICT:' 'TABLED:'; do
  assert_in_range "fork pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$FORK_LINE" "$FORK_END" exact
done
for frag in 'not a debate' 'never pass conversation history' \
            'action verb followed by a skill name' 'in parallel, in one message' \
            'evidence consistency' 'general-purpose'; do
  assert_in_range "fork fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_LINE" "$RULINGS_END" fragment
done
GUARD_LINE="$(first_line_of "$ORCH_SKILL" '## Guard Interaction')"
TEMPLATES_LINE="$(first_line_of "$ORCH_SKILL" '## Prompt Templates')"
assert_in_range "Guard Interaction names the forks' marker" \
  "$ORCH_SKILL" 'fork' "$GUARD_LINE" "$TEMPLATES_LINE" fragment

bold "4. Ruling record, answers and plan amendment (R4, R5)"
for pin in '-open-decisions.md' '**Follow-up:**' '## Ruling <n>' \
           '(orchestrator):' 'decided (orchestrator)' 'amend plan:' \
           'plan governs:' 'fix it:' 'accept:' '**Amendment' \
           '[task <n>/<k>]'; do
  assert_in_range "ruling-record or answer pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RULINGS_LINE" "$RULINGS_END" exact
done
for frag in 'appended, never rewritten' '(amended by ruling' \
            'never apply the amendment twice' 'new invocation' \
            'untagged' 'sides against binding plan text'; do
  assert_in_range "ruling-record or answer fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_LINE" "$RULINGS_END" fragment
done

bold "5. RULING log entry, cap and guards (R6, R7, R9)"
for pin in '## RULING' 'Re-dispatch:' 'Re-dispatch: none' 'Ruled:' \
           'chore(orchestration): <slug> ruling <n>' \
           'plan governs (orchestrator decision)'; do
  assert_in_range "log-entry or guard pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RULINGS_LINE" "$RULINGS_END" exact
done
for frag in 'in-run resumes of one phase are capped at 3 per unit' \
            'phase itself in Phase 4, the task in Phase 3' \
            'previous invocation left' 'durable marker' \
            'a Critical is never rejected' 'quotes its clause' \
            'recorded when it is made'; do
  assert_in_range "log-entry or guard fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_LINE" "$RULINGS_END" fragment
done

bold "6. Wiring into phases, log format, state.md, Resume and stop policy (R6)"
PHASE3_LINE="$(first_line_of "$ORCH_SKILL" '## Phase 3 — Implementation Batches')"
PHASE4_LINE="$(first_line_of "$ORCH_SKILL" '## Phase 4 — Final Code Review Loop')"
PHASE5_LINE="$(first_line_of "$ORCH_SKILL" '## Phase 5 — Completion')"
LOG_FORMAT_LINE="$(first_line_of "$ORCH_SKILL" '## Orchestration Log Format')"
STATE_LINE="$(first_line_of "$ORCH_SKILL" '## state.md Section')"
RESUME_LINE="$(first_line_of "$ORCH_SKILL" '## Resume')"
assert_in_range "Phase 3 routes BLOCKED task=<n> to the predicate" \
  "$ORCH_SKILL" 'In-run rulings' "$PHASE3_LINE" "$PHASE4_LINE" fragment
assert_in_range "Phase 4 routes open items to the predicate" \
  "$ORCH_SKILL" 'In-run rulings' "$PHASE4_LINE" "$PHASE5_LINE" fragment
assert_in_range "Phase 5 report lists unsettled contradictions" \
  "$ORCH_SKILL" 'contradiction: unsettled' "$PHASE5_LINE" "$LOG_FORMAT_LINE" fragment
for pin in '## RULING' 'Ruled:' 'Open:' 'Owed probe:' 'ruling <n> follow-up'; do
  assert_in_range "log-format pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$LOG_FORMAT_LINE" "$STATE_LINE" exact
done
assert_in_range "state.md carries the Rulings line" \
  "$ORCH_SKILL" 'Rulings:' "$STATE_LINE" "$RESUME_LINE" exact
for pin in '## RULING' 'Ruled:' '**Follow-up:**' '(orchestrator)' '(user)' 'decided (<who>)'; do
  assert_in_range "resume pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RESUME_LINE" "$RULINGS_LINE" exact
done
if [ -n "$RESUME_LINE" ] && [ -n "$RULINGS_LINE" ] && \
   awk -v a="$RESUME_LINE" -v b="$RULINGS_LINE" \
     'NR >= a && NR < b && index($0, "decided (user)") > 0 { found = 1 } END { exit found ? 1 : 0 }' "$ORCH_SKILL"; then
  ok "Resume step 3 no longer names decided (user) alone"
else
  bad "Resume step 3 still names decided (user) alone (range $RESUME_LINE..$RULINGS_LINE)"
fi
for frag in 'escalated' 'fork review unavailable'; do
  assert_in_range "stop policy fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_END" "$GUARD_LINE" fragment
done
if awk -v a="$RULINGS_END" -v b="$GUARD_LINE" \
     'NR >= a && NR < b && index($0, "pre-flight plan conflict;") > 0 { found = 1 } END { exit found ? 1 : 0 }' "$ORCH_SKILL"; then
  ok "stop policy no longer lists a pre-flight plan conflict as a stop by itself"
else
  bad "stop policy still lists 'pre-flight plan conflict;' (range $RULINGS_END..$GUARD_LINE)"
fi

bold "7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)"
for pin in 'decided (orchestrator)' 'decided (<who>)' \
           'plan governs (orchestrator decision)' 'plan governs (user decision)' \
           '`decided (user)` or `decided (orchestrator)`' \
           '— clause:' 'clause: none' '(plan-mandated) — at ' \
           '160 characters'; do
  assert_pin "multi-code-review pin '$pin'" "$MCR_SKILL" "$pin"
done
MCR_FORMAT_LINE="$(line_containing_after "$MCR_SKILL" '_Invocation <k> — YYYY-MM-DD — N=<n> M=<m>' 0)"
MCR_FORMAT_END="$(line_containing_after "$MCR_SKILL" 'Round entry with M ≥ 2' "$MCR_FORMAT_LINE")"
MCR_M2_END="$(line_starting_with_after "$MCR_SKILL" '```' "$(line_starting_with_after "$MCR_SKILL" '```' "$MCR_FORMAT_END")")"
assert_in_range "M = 1 log-format example carries the clause" \
  "$MCR_SKILL" 'user-decision — <finding summary> (plan-mandated) — at <file:line> — clause:' \
  "$MCR_FORMAT_LINE" "$MCR_FORMAT_END" exact
assert_in_range "M >= 2 log-format example carries the clause before the annotation" \
  "$MCR_SKILL" '— clause: <plan location> "<quoted plan text>" ← 1/3: r1:I1' \
  "$MCR_FORMAT_END" "$((MCR_M2_END + 1))" exact

bold "8. Loop-side rule for verification cycles (R8.3)"
NO_FIX_LINE="$(line_containing_after "$MCR_SKILL" '**No fix ships unreviewed:**' 0)"
NO_FIX_END="$(line_starting_with_after "$MCR_SKILL" '## ' "$NO_FIX_LINE")"
assert_in_range "loop-decision rejection shape" \
  "$MCR_SKILL" 'plan governs (loop decision)' "$NO_FIX_LINE" "$NO_FIX_END" exact
for frag in 'a Critical is never rejected under this rule' 'decided wording' \
            '(amended by ruling' 'same BASE' 'never edits plan text' \
            '3-cycle cap is unchanged'; do
  assert_in_range "loop-side rule fragment '$frag'" \
    "$MCR_SKILL" "$frag" "$NO_FIX_LINE" "$NO_FIX_END" fragment
done

# --- end of checks ---

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
