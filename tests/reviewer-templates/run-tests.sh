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

# Line number of the first line containing the fixed string $2 in file $1;
# empty when absent.
first_line_of() { grep -nF -- "$2" "$1" | head -n 1 | cut -d: -f1; }

# Line number of the first line starting with ``` after line $2 in file $1;
# empty when absent.
fence_after() {
  awk -v start="$2" 'NR > start && substr($0, 1, 3) == "```" { print NR; exit }' "$1"
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
# Extract the label the Plan Header template's second `> **Label:**`
# block-quote paragraph opens with (today "Body authority") directly from
# writing-plans/SKILL.md, rather than hardcoding it a second time here — a
# rename in one file without the other then fails this check.
WP_BODY_AUTHORITY_LABEL="$(awk '
  /^## Plan Header/ { inblk = 1 }
  inblk && /^> \*\*[A-Za-z ]+:\*\*/ {
    n++
    if (n == 2) {
      match($0, /\*\*[A-Za-z ]+:\*\*/)
      print substr($0, RSTART, RLENGTH)
      exit
    }
  }
  inblk && /^---$/ { exit }
' "$WP_SKILL")"
# Extract the label multi-doc-review's plan-cell gate switches on, from its
# own committed sentence (`> **Body authority:**` inside backticks).
LENS_GATE_LABEL="$(grep -oE '> \*\*[A-Za-z ]+:\*\*`' "$DOC_SKILL" | head -n1 | sed -e 's/^> //' -e 's/`$//')"
if [ -z "$WP_BODY_AUTHORITY_LABEL" ]; then
  bad "writing-plans/SKILL.md: no body-authority label found in the Plan Header block quote"
elif [ -z "$LENS_GATE_LABEL" ]; then
  bad "multi-doc-review SKILL.md: no gate label found in the plan cell"
elif [ "$WP_BODY_AUTHORITY_LABEL" = "$LENS_GATE_LABEL" ]; then
  ok "gate label matches between writing-plans and multi-doc-review ($WP_BODY_AUTHORITY_LABEL)"
else
  bad "gate label mismatch: writing-plans has '$WP_BODY_AUTHORITY_LABEL', multi-doc-review gates on '$LENS_GATE_LABEL'"
fi

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
