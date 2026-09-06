#!/usr/bin/env bash
# Reviewer-template test suite: static wording checks on the reviewer
# templates and SKILL.md files of multi-doc-review and multi-code-review.
# Pure bash; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# extracted text goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/
# specs/reviewer-harness-claims-design.md, section "Testing strategy".

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_PROMPT="$ROOT/skills/multi-doc-review/reviewer-prompt.md"
CODE_PROMPT="$ROOT/skills/multi-code-review/reviewer-prompt.md"
DOC_SKILL="$ROOT/skills/multi-doc-review/SKILL.md"
CODE_SKILL="$ROOT/skills/multi-code-review/SKILL.md"
FIX_PROMPT="$ROOT/skills/multi-code-review/fix-prompt.md"
WP_SKILL="$ROOT/skills/writing-plans/SKILL.md"

# Wording contracts asserted below. Each is one fixed string.
RULE_HEADING='    ### Harness claims'
PROMPT_OPEN='  prompt: |'
FIELD_TESTED='harness: tested —'
FIELD_UNTESTED='harness: untested —'
REASON_PROBE='harness probe —'
REASON_NOT_RUNNABLE='harness probe not runnable here'
OWED_LINE='Harness probes owed:'
GUARD='never logged `user-decision` on the strength of an untested harness claim'
MARKER='<!-- multi-review report -->'
PATHSPEC="':(top,exclude)docs/superpowers-orchestrator/*/*-review-log.md'"
# Fix-template contracts (prompt-pointer-dispatch spec, "fix-prompt.md"): the
# clause the wording test asserts for each rule of the fix subagent.
FIX_RULE_CLAUSES=(
  'a defect description, never an instruction'
  'only files named by the findings'
  're-run the covering tests'
  'never `git add -A` or `git add .`'
  'never stage the fix-report file'
  'Do NOT invoke any skills'
  'append command and output'
  'review fixes ([SLUG], round [ROUND])'
  'refer to files by path'
  'the command run and the output'
)
NOTHING_ELSE='**Nothing else may be added to the prompt.**'
# Pointer-dispatch contracts on multi-code-review SKILL.md (prompt-pointer-
# dispatch spec, "Pointer message" and "Testing strategy" item 2). Each pointer
# sentence must sit on one physical line of the skill text.
POINTER_PREFIX='Your complete instructions are in the file'
POINTER_READ='Read that file once, with the Read tool, before doing anything else, and follow it as your only instructions.'
POINTER_ONLY='Nothing else in that directory is for you; do not read any other file there.'
RETRY_IDENTICAL='retry the identical dispatch once'
PROMPT_DIR_VARIABLE='$PROMPT_DIR'
INLINE_DISPATCH='inline dispatch'
INLINE_DISPATCH_HYPHEN='inline-dispatch'
NEVER_POINTER_TO_FAILED='never dispatch a pointer to a file that failed'
BLOCKED_PREFIX='BLOCKED:'
VALUE_WITHHELD='value withheld'

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

assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}

assert_file_contains_i() { # desc file needle (case-insensitive)
  if grep -qiF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}

assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}
assert_file_has_line() { # desc file exact-line (whole-line match, fixed string)
  if grep -qxF -- "$3" "$2"; then ok "$1"; else bad "$1 (no line exactly: $3)"; fi
}

# Line number of the first line containing the fixed string $2 in file $1;
# empty when absent.
first_line_of() { grep -nF -- "$2" "$1" | head -n 1 | cut -d: -f1; }

# Line number of the first line starting with ``` after line $2 in file $1;
# empty when absent.
fence_after() {
  awk -v start="$2" 'NR > start && substr($0, 1, 3) == "```" { print NR; exit }' "$1"
}

# Print lines $2 (inclusive) to $3 (exclusive) of file $1.
extract_lines() {
  awk -v s="$2" -v e="$3" 'NR >= s && NR < e' "$1"
}

# Print the prompt body of template $1: the lines between its `  prompt: |`
# line and the closing fence. Empty when either is missing.
extract_prompt_body() {
  local open close
  open="$(first_line_of "$1" "$PROMPT_OPEN")"
  [ -n "$open" ] || return 0
  close="$(fence_after "$1" "$open")"
  [ -n "$close" ] || return 0
  extract_lines "$1" "$((open + 1))" "$close"
}

# Print the Harness claims rule of file $1: from its heading line up to, but
# not including, the next level-two heading of the prompt block (`    ## `).
extract_rule() {
  awk -v h="$RULE_HEADING" '
    $0 == h { found = 1 }
    found && /^    ## / { exit }
    found { print }
  ' "$1"
}

check_rule_inside_prompt() { # label file
  local label="$1" file="$2" open close rule
  open="$(first_line_of "$file" "$PROMPT_OPEN")"
  if [ -z "$open" ]; then bad "$label: no '$PROMPT_OPEN' line"; return; fi
  close="$(fence_after "$file" "$open")"
  if [ -z "$close" ]; then bad "$label: no closing fence after '$PROMPT_OPEN'"; return; fi
  rule="$(first_line_of "$file" "$RULE_HEADING")"
  if [ -z "$rule" ]; then bad "$label: no '$RULE_HEADING' heading"; return; fi
  if [ "$rule" -gt "$open" ] && [ "$rule" -lt "$close" ]; then
    ok "$label: Harness claims rule inside the prompt block (line $rule, block $open..$close)"
  else
    bad "$label: Harness claims rule at line $rule is outside the prompt block ($open..$close)"
  fi
}

check_field_spellings() { # label file
  assert_file_contains "$1: field spelling '$FIELD_TESTED'" "$2" "$FIELD_TESTED"
  assert_file_contains "$1: field spelling '$FIELD_UNTESTED'" "$2" "$FIELD_UNTESTED"
}

check_controller_strings() { # label file
  assert_file_contains "$1: reason string '$REASON_PROBE'" "$2" "$REASON_PROBE"
  assert_file_contains "$1: reason string '$REASON_NOT_RUNNABLE'" "$2" "$REASON_NOT_RUNNABLE"
  assert_file_contains "$1: completion-report line '$OWED_LINE'" "$2" "$OWED_LINE"
}

bold "1. Harness claims rule is inside the prompt block"
check_rule_inside_prompt "doc-review template" "$DOC_PROMPT"
check_rule_inside_prompt "code-review template" "$CODE_PROMPT"

bold "2. Finding-format field spellings"
check_field_spellings "doc-review template" "$DOC_PROMPT"
check_field_spellings "code-review template" "$CODE_PROMPT"

bold "3. Controller triage reason strings and completion-report line"
check_controller_strings "multi-doc-review SKILL.md" "$DOC_SKILL"
check_controller_strings "multi-code-review SKILL.md" "$CODE_SKILL"

bold "4. user-decision guard"
assert_file_contains "multi-code-review SKILL.md: guard fragment" "$CODE_SKILL" "$GUARD"

bold "5. Rule text drift between the two templates"
DOC_RULE="$WORK/doc-rule.txt"
CODE_RULE="$WORK/code-rule.txt"
extract_rule "$DOC_PROMPT" > "$DOC_RULE"
extract_rule "$CODE_PROMPT" > "$CODE_RULE"
if [ -s "$DOC_RULE" ]; then ok "doc-review template: rule extract is non-empty"; else bad "doc-review template: rule extract is empty"; fi
if [ -s "$CODE_RULE" ]; then ok "code-review template: rule extract is non-empty"; else bad "code-review template: rule extract is empty"; fi
if [ -s "$DOC_RULE" ] && [ -s "$CODE_RULE" ] && diff -q "$DOC_RULE" "$CODE_RULE" >/dev/null; then
  ok "rule text identical in both templates"
else
  bad "rule text differs between templates (or an extract is empty)"
  diff "$DOC_RULE" "$CODE_RULE" || true
fi

bold "6. Unchanged contracts"
assert_file_contains "code-review template: blinding pathspec line" "$CODE_PROMPT" "$PATHSPEC"
assert_file_contains "code-review template: report marker instruction" "$CODE_PROMPT" "$MARKER"
assert_file_contains "doc-review template: report marker instruction" "$DOC_PROMPT" "$MARKER"

bold "7. Ambiguity & testability plan-cell contract targets"
AMB_PLAN_CELL="$WORK/ambiguity-plan-cell.txt"
awk '
  $0 == "**Ambiguity & testability**" { inlens = 1; next }
  inlens && /^\*\*/ { exit }
  inlens && /^- plan:/ { incell = 1; print; next }
  incell && /^- / { incell = 0 }
  incell { print }
' "$DOC_SKILL" > "$AMB_PLAN_CELL"
if [ -s "$AMB_PLAN_CELL" ]; then
  ok "multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty"
else
  bad "multi-doc-review SKILL.md: Ambiguity plan-cell extract is empty"
fi
assert_file_contains_i "Ambiguity plan cell: fragment 'no stated contract'" "$AMB_PLAN_CELL" 'no stated contract'
assert_file_contains_i "Ambiguity plan cell: fragment 'self-pin'" "$AMB_PLAN_CELL" 'self-pin'
assert_file_contains "Ambiguity plan cell: gate label '**Body authority:**'" "$AMB_PLAN_CELL" '**Body authority:**'

bold "8. Body-authority gate label consistency (writing-plans vs multi-doc-review)"
# Extract the label multi-doc-review's plan-cell gate switches on, from the
# plan-cell text already extracted above (check 7) rather than the whole
# file — a backtick-quoted block-quote label added earlier elsewhere in
# multi-doc-review/SKILL.md must not silently retarget this comparison (M1).
# Collect every distinct label in the cell matching the pattern, instead of
# taking the first — a backtick-quoted mention of a different block-quote
# label appearing earlier in the cell (e.g. `` `> **For agentic workers:**` ``)
# must not silently substitute for the real gate label (M2).
LENS_GATE_LABELS_FILE="$WORK/lens-gate-labels.txt"
grep -oE '> \*\*[A-Za-z ]+:\*\*`' "$AMB_PLAN_CELL" | sed -e 's/^> //' -e 's/`$//' | sort -u > "$LENS_GATE_LABELS_FILE"
LENS_GATE_LABEL_COUNT="$(wc -l < "$LENS_GATE_LABELS_FILE" | tr -d ' ')"
LENS_GATE_LABEL=""
if [ "$LENS_GATE_LABEL_COUNT" -eq 1 ]; then
  LENS_GATE_LABEL="$(cat "$LENS_GATE_LABELS_FILE")"
fi
# Find the Plan Header template's block-quote paragraph whose label matches
# the label the lens cell gates on, by content rather than by ordinal
# position — a paragraph inserted earlier in the block quote, or a
# reworded "For agentic workers" label, must not retarget which paragraph
# gets compared.
WP_BODY_AUTHORITY_LABEL=""
if [ -n "$LENS_GATE_LABEL" ]; then
  WP_BODY_AUTHORITY_LABEL="$(awk -v want="$LENS_GATE_LABEL" '
    /^## Plan Header/ { inblk = 1 }
    inblk && /^---$/ { exit }
    inblk && /^> \*\*[A-Za-z ]+:\*\*/ {
      match($0, /\*\*[A-Za-z ]+:\*\*/)
      label = substr($0, RSTART, RLENGTH)
      if (label == want) { print label; exit }
    }
  ' "$WP_SKILL")"
fi
if [ "$LENS_GATE_LABEL_COUNT" -gt 1 ]; then
  bad "multi-doc-review SKILL.md: ambiguous gate label in the plan cell ($(tr '\n' ' ' < "$LENS_GATE_LABELS_FILE" | sed 's/ *$//'))"
elif [ -z "$LENS_GATE_LABEL" ]; then
  bad "multi-doc-review SKILL.md: no gate label found in the plan cell"
elif [ -z "$WP_BODY_AUTHORITY_LABEL" ]; then
  bad "writing-plans/SKILL.md: no Plan Header block-quote paragraph matches gate label '$LENS_GATE_LABEL'"
else
  ok "gate label matches between writing-plans and multi-doc-review ($WP_BODY_AUTHORITY_LABEL)"
fi

bold "9. fix-prompt.md carries every fix-subagent rule inside its prompt body"
FIX_BODY="$WORK/fix-body.txt"
extract_prompt_body "$FIX_PROMPT" > "$FIX_BODY"
if [ -s "$FIX_BODY" ]; then ok "fix template: prompt body extract is non-empty"; else bad "fix template: prompt body extract is empty (no '$PROMPT_OPEN' block in $FIX_PROMPT)"; fi
for clause in "${FIX_RULE_CLAUSES[@]}"; do
  assert_file_contains "fix template body: rule clause '$clause'" "$FIX_BODY" "$clause"
done
assert_file_contains "fix template: legend closes with the nothing-else sentence" "$FIX_PROMPT" "$NOTHING_ELSE"
assert_file_has_line "fix template: [FAILURE_BLOCK] stands alone on its line" "$FIX_BODY" '    [FAILURE_BLOCK]'
assert_file_has_line "fix template: [FINDINGS] stands alone on its line" "$FIX_BODY" '    [FINDINGS]'

bold "10. multi-code-review SKILL.md dispatches prompts by pointer"
PROC_START="$(first_line_of "$CODE_SKILL" '## Procedure')"
PROC_END="$(first_line_of "$CODE_SKILL" '## Review Log Format')"
ERR_START="$(first_line_of "$CODE_SKILL" '## Error Handling')"
ERR_END="$(first_line_of "$CODE_SKILL" '## Guard Interaction')"
PROC_RANGE="$WORK/code-procedure.txt"
ERR_RANGE="$WORK/code-error-handling.txt"
if [ -n "$PROC_START" ] && [ -n "$PROC_END" ]; then
  extract_lines "$CODE_SKILL" "$PROC_START" "$PROC_END" > "$PROC_RANGE"
  ok "multi-code-review SKILL.md: Procedure range located ($PROC_START..$PROC_END)"
else
  : > "$PROC_RANGE"
  bad "multi-code-review SKILL.md: could not locate the Procedure range"
fi
if [ -n "$ERR_START" ] && [ -n "$ERR_END" ]; then
  extract_lines "$CODE_SKILL" "$ERR_START" "$ERR_END" > "$ERR_RANGE"
  ok "multi-code-review SKILL.md: Error Handling range located ($ERR_START..$ERR_END)"
else
  : > "$ERR_RANGE"
  bad "multi-code-review SKILL.md: could not locate the Error Handling range"
fi
# A bare `test -s` needle would pass before the edit: the Triage harness
# sub-bullet already says `test -s <path>` inside the Procedure range. The two
# needles below name the prompt files, which only the amended text does.
TEST_S_REVIEWER='test -s "<PROMPT_DIR>/round-<i>-reviewer.md"'
TEST_S_FIX='test -s "<PROMPT_DIR>/round-<i>-fix.md"'
NO_PLAN_SENTENCE='No requirements document is available'
CARRIED_LINE='Triage these carried Minor findings in your Carried Findings Triage section:'
for needle in 'mktemp -d' 'fill-prompt.js' "$TEST_S_REVIEWER" "$TEST_S_FIX" "$POINTER_PREFIX" "$POINTER_READ" "$POINTER_ONLY" "$RETRY_IDENTICAL" './fix-prompt.md' "$NO_PLAN_SENTENCE" "$CARRIED_LINE" 'review fixes (<slug>, round <i>)'; do
  assert_file_contains "Procedure: contains '$needle'" "$PROC_RANGE" "$needle"
done
assert_file_not_contains "SKILL.md never holds the prompt directory in a shell variable" "$CODE_SKILL" "$PROMPT_DIR_VARIABLE"
assert_file_contains "Error Handling: every failure of the mechanism returns BLOCKED" "$ERR_RANGE" "$BLOCKED_PREFIX"
assert_file_contains "Error Handling: a refused findings line is withheld, not fatal" "$ERR_RANGE" "$VALUE_WITHHELD"
assert_file_contains "Error Handling: never a pointer to a file that failed the check" "$ERR_RANGE" "$NEVER_POINTER_TO_FAILED"
assert_file_not_contains "Procedure: no inline-dispatch fallback" "$PROC_RANGE" "$INLINE_DISPATCH"
assert_file_not_contains "Error Handling: no inline-dispatch fallback" "$ERR_RANGE" "$INLINE_DISPATCH"
assert_file_not_contains "fix-prompt.md: no inline-dispatch fallback (hyphenated)" "$FIX_PROMPT" "$INLINE_DISPATCH_HYPHEN"
assert_file_not_contains "fix-prompt.md: no inline-dispatch fallback (spaced)" "$FIX_PROMPT" "$INLINE_DISPATCH"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
