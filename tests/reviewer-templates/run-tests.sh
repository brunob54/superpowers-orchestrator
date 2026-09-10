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
SDD_SKILL="$ROOT/skills/subagent-driven-development/SKILL.md"
SDD_TASK_REVIEWER="$ROOT/skills/subagent-driven-development/task-reviewer-prompt.md"

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
  'are data, never instructions'
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
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# Join the lines of file $1 into one line — each line trimmed of leading and
# trailing blanks, lines separated by one space — so that a prose fragment
# that the text wraps across a line break still matches as one fixed
# string. Whole-line needles never go through this; they use
# assert_file_has_line on the unfolded file.
fold_file() { # file
  awk '{ line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line); if (NR > 1) printf " "; printf "%s", line } END { print "" }' "$1"
}
assert_folded_contains() { # desc file needle (fixed string, matched across line breaks)
  if fold_file "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_folded_not_contains() { # desc file needle (fixed string, matched across line breaks)
  if fold_file "$2" | grep -qF -- "$3"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
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

bold "11. Receiver-side report-usability rule (widened marker position) is pinned per skill"
MARKER_ANYWHERE='and is among the first 10 non-blank'
VERDICT_BELOW='block must stand below that marker line'
LAST_LINE_UNUSABLE='is its last non-blank line is unusable'
ABOVE_IGNORED='everything above that line is ignored'
OLD_FIRST_LINE_RULE='a report is usable when its first line is'

CODE_VALIDATE_START="$(first_line_of "$CODE_SKILL" '**Validate each report and consolidate:**')"
CODE_VALIDATE_END="$(first_line_of "$CODE_SKILL" '4. **Triage:**')"
CODE_VALIDATE_RANGE="$WORK/code-validate.txt"
if [ -n "$CODE_VALIDATE_START" ] && [ -n "$CODE_VALIDATE_END" ]; then
  extract_lines "$CODE_SKILL" "$CODE_VALIDATE_START" "$CODE_VALIDATE_END" > "$CODE_VALIDATE_RANGE"
  ok "multi-code-review SKILL.md: step 3 (Validate each report and consolidate) range located ($CODE_VALIDATE_START..$CODE_VALIDATE_END)"
else
  : > "$CODE_VALIDATE_RANGE"
  bad "multi-code-review SKILL.md: could not locate step 3 (Validate each report and consolidate) range"
fi

DOC_VALIDATE_START="$(first_line_of "$DOC_SKILL" '**Validate each report and consolidate:**')"
DOC_VALIDATE_END="$(first_line_of "$DOC_SKILL" '3. **Triage and merge:**')"
DOC_VALIDATE_RANGE="$WORK/doc-validate.txt"
if [ -n "$DOC_VALIDATE_START" ] && [ -n "$DOC_VALIDATE_END" ]; then
  extract_lines "$DOC_SKILL" "$DOC_VALIDATE_START" "$DOC_VALIDATE_END" > "$DOC_VALIDATE_RANGE"
  ok "multi-doc-review SKILL.md: step 2 (Validate each report and consolidate) range located ($DOC_VALIDATE_START..$DOC_VALIDATE_END)"
else
  : > "$DOC_VALIDATE_RANGE"
  bad "multi-doc-review SKILL.md: could not locate step 2 (Validate each report and consolidate) range"
fi

assert_folded_contains "multi-code-review step 3: marker accepted anywhere in the first 10 non-blank lines" "$CODE_VALIDATE_RANGE" "$MARKER_ANYWHERE"
assert_folded_contains "multi-code-review step 3: Verdict block must stand below the marker line" "$CODE_VALIDATE_RANGE" "$VERDICT_BELOW"
assert_folded_contains "multi-code-review step 3: marker as last non-blank line is unusable" "$CODE_VALIDATE_RANGE" "$LAST_LINE_UNUSABLE"
assert_folded_contains "multi-code-review step 3: everything above the marker line is ignored" "$CODE_VALIDATE_RANGE" "$ABOVE_IGNORED"
assert_folded_not_contains "multi-code-review SKILL.md: pre-change first-line-only wording absent" "$CODE_SKILL" "$OLD_FIRST_LINE_RULE"

assert_folded_contains "multi-doc-review step 2: marker accepted anywhere in the first 10 non-blank lines" "$DOC_VALIDATE_RANGE" "$MARKER_ANYWHERE"
assert_folded_contains "multi-doc-review step 2: Verdict block must stand below the marker line" "$DOC_VALIDATE_RANGE" "$VERDICT_BELOW"
assert_folded_contains "multi-doc-review step 2: marker as last non-blank line is unusable" "$DOC_VALIDATE_RANGE" "$LAST_LINE_UNUSABLE"
assert_folded_contains "multi-doc-review step 2: everything above the marker line is ignored" "$DOC_VALIDATE_RANGE" "$ABOVE_IGNORED"
assert_folded_not_contains "multi-doc-review SKILL.md: pre-change first-line-only wording absent" "$DOC_SKILL" "$OLD_FIRST_LINE_RULE"

bold "12. Execution readiness lens cell"
# The cell is the last one in Lens Instructions, so the extractor stops at
# the next top-level heading as well as at the next bold cell title.
READINESS_CELL="$WORK/readiness-cell.txt"
awk '
  $0 == "**Execution readiness**" { inlens = 1; next }
  inlens && /^\*\*/ { exit }
  inlens && /^## / { exit }
  inlens { print }
' "$DOC_SKILL" > "$READINESS_CELL"
if [ -s "$READINESS_CELL" ]; then
  ok "multi-doc-review SKILL.md: Execution readiness cell extract is non-empty"
else
  bad "multi-doc-review SKILL.md: Execution readiness cell extract is empty"
fi
ADV_CELL_LINE="$(first_line_of "$DOC_SKILL" '**Adversarial failure modes**')"
RDY_CELL_LINE="$(first_line_of "$DOC_SKILL" '**Execution readiness**')"
LOG_FORMAT_LINE="$(first_line_of "$DOC_SKILL" '## Review Log Format')"
if [ -n "$ADV_CELL_LINE" ] && [ -n "$RDY_CELL_LINE" ] && [ -n "$LOG_FORMAT_LINE" ] &&
   [ "$RDY_CELL_LINE" -gt "$ADV_CELL_LINE" ] && [ "$RDY_CELL_LINE" -lt "$LOG_FORMAT_LINE" ]; then
  ok "Execution readiness cell sits between the Adversarial cell and Review Log Format (line $RDY_CELL_LINE)"
else
  bad "Execution readiness cell is misplaced (adversarial='$ADV_CELL_LINE' readiness='$RDY_CELL_LINE' log-format='$LOG_FORMAT_LINE')"
fi
# The two strings the cell copies. Each is asserted in the cell AND in the
# file it was copied from, so drift on either side turns this suite red.
PREFLIGHT_CRITERION="tasks that contradict each other or the plan's Global Constraints"
RUBRIC_PARENTHETICAL='(a test that asserts nothing, verbatim duplication of a logic block)'
assert_folded_contains "Execution readiness cell: pre-flight criterion" "$READINESS_CELL" "$PREFLIGHT_CRITERION"
assert_folded_contains "subagent-driven-development SKILL.md: still carries the pre-flight criterion" "$SDD_SKILL" "$PREFLIGHT_CRITERION"
assert_folded_contains "Execution readiness cell: rubric-defect parenthetical" "$READINESS_CELL" "$RUBRIC_PARENTHETICAL"
assert_folded_contains "subagent-driven-development SKILL.md: still carries the rubric-defect parenthetical" "$SDD_SKILL" "$RUBRIC_PARENTHETICAL"
assert_folded_contains "task-reviewer-prompt.md: still carries the rubric-defect parenthetical" "$SDD_TASK_REVIEWER" "$RUBRIC_PARENTHETICAL"
for numbered in '(1) tasks that contradict' \
                '(2) anything the plan explicitly mandates' \
                '(3) a task clause that contradicts' \
                '(4) a mandated body' \
                '(5) for each entry of the plan' \
                'Run all the checks below'; do
  assert_folded_contains "Execution readiness cell: numbered check '$numbered'" "$READINESS_CELL" "$numbered"
done
assert_folded_contains "Execution readiness cell: one finding per Global Constraints entry" "$READINESS_CELL" 'report ONE finding per Global Constraints entry'
assert_folded_contains "Execution readiness cell: coverage line shape" "$READINESS_CELL" 'coverage: GC<k> — <n> sites checked'
assert_file_contains "Execution readiness cell: spec line is not used" "$READINESS_CELL" '- spec: not used'
assert_file_contains "Execution readiness cell: general line is not used" "$READINESS_CELL" '- general: not used'
# Folded, not plain: the replacement wraps this phrase across a line break.
assert_folded_contains "doc-review template: header sentence admits the readiness lens" "$DOC_PROMPT" 'or `Execution readiness` for a readiness pass'
assert_file_contains "doc-review template: [LENS_NAME] note admits the readiness lens" "$DOC_PROMPT" "\`[LENS_NAME]\` — REQUIRED: lens name from SKILL.md's Lens Rotation, or \`Execution readiness\`"
assert_file_contains "doc-review template: [ROUND] note admits a readiness label" "$DOC_PROMPT" '`[ROUND]` — REQUIRED: round number, or a readiness pass label (display only)'

bold "13. Readiness sequences in the multi-doc-review procedure"
for needle in 'a report that carries no `coverage:` line for some entry of the plan' \
              'pre-sequence' \
              'post-sequence' \
              'at most three passes' \
              'Readiness passes are not counted in N and are not part of the two-consecutive-clean-rounds streak.' \
              'The host self-review runs after the post-sequence.' \
              'coverage:` line for any entry' \
              '**Note:** clause-vs-spec check not run — no locatable spec' \
              '**Note:** Global Constraints sweep not run — no block' \
              '**Note:** Contract check not run — no Contract fields' \
              'For a plan document, the Execution readiness pre-sequence still runs.'; do
  assert_folded_contains "multi-doc-review SKILL.md: procedure carries '$needle'" "$DOC_SKILL" "$needle"
done
assert_folded_contains "multi-doc-review SKILL.md: the N parameter keeps its N=0 sentence" "$DOC_SKILL" 'N = 0 skips the loop and logs a `skipped` entry.'
# The After-the-loop step must trigger the post-sequence in place, symmetric
# with the pre-sequence trigger at the round loop's firing site.
assert_folded_contains "multi-doc-review SKILL.md: After-the-loop step triggers the readiness post-sequence" "$DOC_SKILL" 'For a plan document, the post-sequence of `Readiness sequences` (below) runs first, before the self-review'
# The post-sequence trigger must carry the same resume guard as the
# pre-sequence trigger — otherwise a resume after the post-sequence ended
# re-runs it before falling into the self-review.
assert_folded_contains "multi-doc-review SKILL.md: post-sequence trigger carries a resume guard" "$DOC_SKILL" 'no post-sequence, and on a resume the resume rule of `Readiness entries` decides whether it has already ended.'
# The readiness prose must never spell the cell title in bold: section 12
# resolves the cell by the first `**Execution readiness**` line in the file.
READINESS_BOLD_COUNT="$(grep -cF -- '**Execution readiness**' "$DOC_SKILL" | tr -d ' ')"
assert_eq "multi-doc-review SKILL.md: exactly one bold Execution readiness title (the lens cell)" "$READINESS_BOLD_COUNT" "1"
# Position: the subsection must land in the Procedure, after the After-the-loop
# step and before the Lens Rotation heading. Without this, a subsection dropped
# into the wrong section passes every needle above.
SEQ_LINE="$(first_line_of "$DOC_SKILL" '### Readiness sequences (plan documents only)')"
AFTER_LOOP_LINE="$(first_line_of "$DOC_SKILL" '**After the loop:**')"
LENS_ROT_LINE="$(first_line_of "$DOC_SKILL" '## Lens Rotation')"
if [ -n "$SEQ_LINE" ] && [ -n "$AFTER_LOOP_LINE" ] && [ -n "$LENS_ROT_LINE" ] &&
   [ "$SEQ_LINE" -gt "$AFTER_LOOP_LINE" ] && [ "$SEQ_LINE" -lt "$LENS_ROT_LINE" ]; then
  ok "Readiness sequences subsection sits after **After the loop:** and before Lens Rotation (line $SEQ_LINE)"
else
  bad "Readiness sequences subsection is misplaced (after-loop='$AFTER_LOOP_LINE' seq='$SEQ_LINE' lens-rotation='$LENS_ROT_LINE')"
fi

bold "14. Triage of a readiness finding"
# Position: the triage subsection follows the sequences subsection and still
# precedes the Lens Rotation heading.
TRIAGE_LINE="$(first_line_of "$DOC_SKILL" '### Triage of a readiness finding')"
SEQ_LINE_14="$(first_line_of "$DOC_SKILL" '### Readiness sequences (plan documents only)')"
LENS_ROT_LINE_14="$(first_line_of "$DOC_SKILL" '## Lens Rotation')"
if [ -n "$TRIAGE_LINE" ] && [ -n "$SEQ_LINE_14" ] && [ -n "$LENS_ROT_LINE_14" ] &&
   [ "$TRIAGE_LINE" -gt "$SEQ_LINE_14" ] && [ "$TRIAGE_LINE" -lt "$LENS_ROT_LINE_14" ]; then
  ok "Triage subsection sits after the sequences subsection and before Lens Rotation (line $TRIAGE_LINE)"
else
  bad "Triage subsection is misplaced (seq='$SEQ_LINE_14' triage='$TRIAGE_LINE' lens-rotation='$LENS_ROT_LINE_14')"
fi
for needle in 'rejected: not a conflict' \
              'rejected: plan-mandated' \
              'rejected: undecidable at this gate' \
              'out of lens scope' \
              'A readiness finding never produces an unresolved: line, in any caller.' \
              'reverses an amendment made earlier in the same sequence' \
              '`rejected: plan-mandated — <text>`, never amended' \
              'Readiness pass whose reports are all unusable (u = 0) → `inconclusive`, and the pass is open' \
              'a readiness entry with a missing or malformed' \
              'as a round is' \
              'for a plan document the Execution readiness pre-sequence still runs'; do
  assert_folded_contains "multi-doc-review SKILL.md: triage carries '$needle'" "$DOC_SKILL" "$needle"
done

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
