#!/usr/bin/env bash
# orchestrating-development wording test suite: static checks on the
# prompt-pointer dispatch text of skills/orchestrating-development/SKILL.md
# (the orchestrator) and on its four controller prompt templates.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# extracted text goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-09-06-orchestrator-prompt-pointer/
# specs/orchestrator-prompt-pointer-design.md, section "Testing strategy"
# item 2.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORCH_DIR="$ROOT/skills/orchestrating-development"
ORCH_SKILL="$ORCH_DIR/SKILL.md"
TEMPLATES=(plan-writer-prompt.md doc-review-loop-prompt.md batch-controller-prompt.md code-review-loop-prompt.md)
# The three templates that carry a `## Resume Answer` section.
RESUME_TEMPLATES=(plan-writer-prompt.md batch-controller-prompt.md code-review-loop-prompt.md)

# Section headings of the orchestrator, matched as whole lines.
H_DISPATCH='## Controller Dispatch Rules (apply to every phase)'
H_PHASE0='## Phase 0 — Setup (the only interactive moment)'
H_PHASE1='## Phase 1 — Plan Writing'
H_PHASE5='## Phase 5 — Completion'
H_RESUME='## Resume'
H_INRUN='## In-run rulings'
H_MAJOR='## Major-Error Stop Policy'
H_GUARD='## Guard Interaction'
H_TEMPLATES='## Prompt Templates'

# Wording contracts. Each is one fixed string.
POINTER_PREFIX='Your complete instructions are in the file'
POINTER_FIRST='Your complete instructions are in the file <ABSOLUTE PATH>.'
POINTER_READ='Read that file once, with the Read tool, before doing anything else, and follow it as your only instructions.'
POINTER_ONLY='Nothing else in that directory is for you; do not read any other file there.'
PROMPT_DIR_VARIABLE='$PROMPT_DIR'
MKTEMP='mktemp -d'
FILL_SCRIPT='fill-prompt.js'
TEST_S='test -s'
NEVER_READS='never read a template'
NEVER_REWRITTEN='written once and never rewritten'
SAME_POINTER='the same pointer to the same file'
NEVER_FAILED_FILE='never dispatch a pointer to a file that failed the check'
NO_FALLBACK='no inline fallback'
VALUE_WITHHELD='value withheld'
NO_HEREDOC='never with a heredoc'
PASTE='paste'
FILL_DOT='Fill `./'
READ_DOT='Read `./'
# `## STOPPED` cause texts of the fatal rows, and the Node row's wording.
CAUSES=(
  'prompt directory could not be created — <error text>'
  'prompt file <name> not produced — <the script'"'"'s message, or "empty">'
  'Treated as the script failing'
  'value file <name> could not be written — <the error>'
  'value file <name> refused twice by protect-secrets — <the hook'"'"'s reason>'
  'prompt file <name> not read by <controller name>'
)
# One fragment per row of the not-mechanism table.
NOT_MECHANISM_ROWS=(
  'dies of the environment'
  'A slip in your own fill command'
  'treat it as a path lost from context'
  'unusable on format alone'
  'lost from your context'
  'reads another file in the directory'
  'stale directory from an earlier session'
)
# File names of the prompt directory.
FILE_NAMES=(
  'dispatch-<k>-plan-writer.md'
  'dispatch-<k>-plan-review.md'
  'dispatch-<k>-batch-<n>.md'
  'dispatch-<k>-code-review.md'
  'dispatch-<k>-answers.txt'
  'dispatch-<k>-probe-<n>.txt'
)
# Template wrapper and body contracts.
AGENT_LINE='Agent tool (general-purpose):'
NAME_PREFIX='  name: "orch-'
PROMPT_OPEN='  prompt: |'
NOTHING_ELSE='**Nothing else may be added to the prompt.**'
RESUME_HEADING='    ## Resume Answer'
FIXED_SENTENCE='    A section with no line below this sentence means the run has recorded no answer.'
PLACEHOLDER_LINE='    [RESUME_ANSWER]'
M_TOKEN='[M]'
SINGLE_LETTER_ERE='\[[A-Z]\]'
CHECKLIST_LINE='       `- [X] unresolved: <reason> — <finding summary>`.'

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

assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}
assert_file_not_contains_i() { # desc file needle (case-insensitive)
  if grep -qiF -- "$3" "$2"; then bad "$1 (must not contain, in any case: $3)"; else ok "$1"; fi
}
assert_file_has_line() { # desc file exact-line (whole-line match, fixed string)
  if grep -qxF -- "$3" "$2"; then ok "$1"; else bad "$1 (no line exactly: $3)"; fi
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
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}

# Line number of the first line of file $1 equal to $2 as a whole line;
# empty when absent.
first_line_of() { grep -nxF -- "$2" "$1" | head -n 1 | cut -d: -f1; }
# Write the lines of file $2 from heading $3 (inclusive) to heading $4
# (exclusive) into file $5. A missing or inverted range writes an empty file
# and FAILs, so that every later check on that file fails visibly.
extract_range() { # label file start-heading end-heading out
  local start end
  start="$(first_line_of "$2" "$3")"
  end="$(first_line_of "$2" "$4")"
  if [ -z "$start" ] || [ -z "$end" ] || [ "$start" -ge "$end" ]; then
    : > "$5"
    bad "$1: could not locate the range '$3' .. '$4' in ${2#$ROOT/}"
    return
  fi
  awk -v s="$start" -v e="$end" 'NR >= s && NR < e' "$2" > "$5"
  ok "$1: range located ($start..$end)"
}
# The line right below the first line of file $1 that equals $2 as a whole
# line; empty when absent or last. The needle reaches awk through the
# environment so that no character of it is reinterpreted.
line_below() { # file exact-line
  needle="$2" awk 'BEGIN { n = ENVIRON["needle"] } found { print; exit } $0 == n { found = 1 }' "$1"
}

DISPATCH_RANGE="$WORK/dispatch.txt"
PHASE0_RANGE="$WORK/phase0.txt"
PHASES_RANGE="$WORK/phases.txt"
RESUME_RANGE="$WORK/resume.txt"
INRUN_RANGE="$WORK/inrun.txt"
MAJOR_RANGE="$WORK/major.txt"
TEMPLATES_RANGE="$WORK/templates.txt"

bold "0. Section ranges of the orchestrator"
extract_range "Controller Dispatch Rules" "$ORCH_SKILL" "$H_DISPATCH" "$H_PHASE0" "$DISPATCH_RANGE"
extract_range "Phase 0" "$ORCH_SKILL" "$H_PHASE0" "$H_PHASE1" "$PHASE0_RANGE"
extract_range "Phases 1 to 4" "$ORCH_SKILL" "$H_PHASE1" "$H_PHASE5" "$PHASES_RANGE"
extract_range "Resume" "$ORCH_SKILL" "$H_RESUME" "$H_INRUN" "$RESUME_RANGE"
extract_range "In-run rulings" "$ORCH_SKILL" "$H_INRUN" "$H_MAJOR" "$INRUN_RANGE"
extract_range "Major-Error Stop Policy" "$ORCH_SKILL" "$H_MAJOR" "$H_GUARD" "$MAJOR_RANGE"
# `## Prompt Templates` is the last section: its range runs to the end.
TEMPLATES_START="$(first_line_of "$ORCH_SKILL" "$H_TEMPLATES")"
if [ -n "$TEMPLATES_START" ]; then
  awk -v s="$TEMPLATES_START" 'NR >= s' "$ORCH_SKILL" > "$TEMPLATES_RANGE"
  ok "Prompt Templates: range located ($TEMPLATES_START..end)"
else
  : > "$TEMPLATES_RANGE"
  bad "Prompt Templates: heading '$H_TEMPLATES' not found"
fi

bold "1. Controller Dispatch Rules: the prompt directory, the fill, the check, the pointer"
for needle in "$MKTEMP" "$FILL_SCRIPT" "$TEST_S" "$POINTER_PREFIX" "$POINTER_READ" "$POINTER_ONLY" \
              "$NEVER_READS" "$NEVER_REWRITTEN" "$SAME_POINTER" "$NEVER_FAILED_FILE" \
              'cygpath -m' 'never held in a variable' 'the pointer only' "${FILE_NAMES[@]}"; do
  assert_folded_contains "dispatch rules: contains '$needle'" "$DISPATCH_RANGE" "$needle"
done
# Each pointer sentence stands on one physical line. The dispatch-rules
# text indents them inside a list item, so the indentation is trimmed
# before the whole-line match.
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$DISPATCH_RANGE" > "$WORK/dispatch-trimmed.txt"
for s in "$POINTER_FIRST" "$POINTER_READ" "$POINTER_ONLY"; do
  assert_file_has_line "dispatch rules: pointer sentence on one physical line: '$s'" "$WORK/dispatch-trimmed.txt" "$s"
done

bold "2. Negative needles over the whole orchestrator text"
assert_file_not_contains "orchestrator never holds the prompt directory in a shell variable" "$ORCH_SKILL" "$PROMPT_DIR_VARIABLE"
assert_file_not_contains_i "orchestrator never says '$PASTE'" "$ORCH_SKILL" "$PASTE"
for t in "${TEMPLATES[@]}"; do
  assert_file_not_contains "orchestrator never reads ./$t" "$ORCH_SKILL" "${READ_DOT}${t}"
done

bold "3. Major-Error Stop Policy: every failure of the mechanism is fatal, with its cause text"
for needle in "${CAUSES[@]}" "${NOT_MECHANISM_ROWS[@]}" "$VALUE_WITHHELD" "$NEVER_FAILED_FILE" \
              "$NO_FALLBACK" "$SAME_POINTER" "$NO_HEREDOC" 'hooks/safety/protect-secrets.js' \
              'dispatch-<k>-probe-<n>.txt' 'Never withhold a line on this outcome'; do
  assert_folded_contains "stop policy: contains '$needle'" "$MAJOR_RANGE" "$needle"
done

bold "4. Prompt Templates: filled by the script, never read"
assert_folded_contains "prompt templates: names the fill script" "$TEMPLATES_RANGE" "$FILL_SCRIPT"
assert_folded_contains "prompt templates: never read by the orchestrator" "$TEMPLATES_RANGE" 'never read by the orchestrator'
for t in "${TEMPLATES[@]}"; do
  assert_file_has_line "prompt templates: lists ./$t" "$TEMPLATES_RANGE" "- \`./$t\`"
done

bold "5. The four templates: no single-letter placeholder, wrapper lines kept"
for t in "${TEMPLATES[@]}"; do
  f="$ORCH_DIR/$t"
  assert_file_not_contains "$t: no [M] token" "$f" "$M_TOKEN"
  assert_file_has_line "$t: Agent tool wrapper line" "$f" "$AGENT_LINE"
  assert_file_contains "$t: name line starts with orch-" "$f" "$NAME_PREFIX"
  assert_file_has_line "$t: prompt: | line" "$f" "$PROMPT_OPEN"
  # A substring check, not a whole line: plan-writer-prompt.md continues the
  # sentence on the same line, and that line stays byte-identical.
  assert_file_contains "$t: nothing-else line" "$f" "$NOTHING_ELSE"
  single="$(grep -cE -- "$SINGLE_LETTER_ERE" "$f" | tr -d ' ')"
  if [ "$t" = "doc-review-loop-prompt.md" ]; then
    assert_eq "$t: exactly one line with a single-letter bracket token (the checklist marker)" "$single" "1"
    assert_file_has_line "$t: the checklist marker line is byte-identical" "$f" "$CHECKLIST_LINE"
  else
    assert_eq "$t: no single-letter bracket token" "$single" "0"
  fi
done

bold "6. The Resume Answer section: heading without a parenthetical, the fixed sentence, the placeholder below it"
for t in "${RESUME_TEMPLATES[@]}"; do
  f="$ORCH_DIR/$t"
  assert_file_has_line "$t: Resume Answer heading stands alone" "$f" "$RESUME_HEADING"
  assert_file_not_contains "$t: no omit parenthetical on the heading" "$f" '## Resume Answer (omit'
  assert_file_has_line "$t: the fixed sentence is one line of the body" "$f" "$FIXED_SENTENCE"
  assert_eq "$t: the placeholder line follows the fixed sentence directly" "$(line_below "$f" "$FIXED_SENTENCE")" "$PLACEHOLDER_LINE"
done
assert_file_not_contains "doc-review-loop-prompt.md: has no Resume Answer section" "$ORCH_DIR/doc-review-loop-prompt.md" 'Resume Answer'

bold "7. Phase 0 creates the prompt directory; Phases 1 to 4 fill, check and dispatch the pointer"
assert_folded_contains "phase 0: mktemp -d step" "$PHASE0_RANGE" "$MKTEMP"
assert_folded_contains "phase 0: names the creation-failure cause" "$PHASE0_RANGE" 'prompt directory could not be created'
for t in "${TEMPLATES[@]}"; do
  assert_folded_contains "phases: fill command names --template \"<base>/$t\"" "$PHASES_RANGE" "--template \"<base>/$t\""
done
for name in 'dispatch-<k>-plan-writer.md' 'dispatch-<k>-plan-review.md' 'dispatch-<k>-batch-<n>.md' 'dispatch-<k>-code-review.md'; do
  assert_folded_contains "phases: test -s on $name" "$PHASES_RANGE" "test -s \"<PROMPT_DIR>/$name\""
done
assert_file_not_contains "phases: no template is filled by hand (no 'Fill \`./' line)" "$PHASES_RANGE" "$FILL_DOT"
assert_folded_contains "phases: BATCH_NUMBER is not passed to the script" "$PHASES_RANGE" 'is not passed'
POINTER_DISPATCHES="$(grep -cF -- 'dispatch the pointer' "$PHASES_RANGE" | tr -d ' ')"
if [ "$POINTER_DISPATCHES" -ge 4 ]; then
  ok "phases: 'dispatch the pointer' appears $POINTER_DISPATCHES times (at least once per phase)"
else
  bad "phases: 'dispatch the pointer' appears $POINTER_DISPATCHES times, fewer than 4"
fi

bold "8. Resume and In-run rulings: the answer lines go into a value file"
for needle in "$MKTEMP" 'a resumed session has none' 'dispatch-1-answers.txt' '`<k>` = 1' 'the only channel for it' 'no answer line'; do
  assert_folded_contains "resume: contains '$needle'" "$RESUME_RANGE" "$needle"
done
for needle in 'dispatch-<k>-answers.txt' "$NO_HEREDOC" 'the only channel' 'a new fill under the next `<k>`' "$TEST_S"; do
  assert_folded_contains "in-run rulings: contains '$needle'" "$INRUN_RANGE" "$needle"
done

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
