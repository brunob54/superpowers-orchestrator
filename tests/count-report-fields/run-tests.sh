#!/usr/bin/env bash
# count-report-fields test suite: unit tests on tools/count-report-fields.js,
# the committed script that takes the acceptance measure of release 7.75.0
# (the reviewer evidence line and the inputs-read declaration). Pure bash +
# node; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# output goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-
# and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md, section 9.
#
# The fixture folder holds twenty-three transcripts: twenty-one reviewers (the
# lens heading is in the prompt) and two that are not (fix subagents). Each rule
# of the script that decides a count has a fixture that fails without it:
#   - a Write copy of a report that differs from the handback (never counted);
#     a narration text block before the handback (the handback wins); a report
#     as a text block with a sentence above its marker (taken when no handback);
#   - a Minor finding with and without `evidence:` (only Critical and Important
#     count); a marker on the 11th non-blank line (no report) and the 10th;
#   - the `unknown` and several-range forms of an input line; an input-shaped
#     line under a later heading; a line outside the grammar (`partial — not
#     read: lines 1 to 50`, a bare `partial`); a `whole` line with words after it;
#   - a pointer-dispatched reviewer whose prompt is in the Read result of the
#     pointer file, with a needle that wraps across two numbered lines; one that
#     also Reads a second file (its text is not prompt text); a second user
#     message with the lens heading (only the first user message is the prompt);
#   - CRLF line ends; a cut last JSONL line; a report with no `### Inputs read`
#     section; a heading followed by prose; an evidence line that is not directly
#     below its id line, and one below a single blank line (it counts);
#   - a reviewer without a marked report: its meta file is present, missing,
#     unparsable, or without a description; a prompt that names no input (an
#     empty expected set is not with-inputs-read); one and three arguments (exit 2).
# Section 3 ties each `needle` of the script to the live text it is copied
# from, so the script cannot drift from the prompts that it measures.

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/tools/count-report-fields.js"
FIX="$ROOT/tests/count-report-fields/fixtures"
SUBAGENTS="$FIX/subagents"
LOG="$FIX/review-log.md"
EXIT_OK=0
EXIT_USAGE=2
USAGE_FRAGMENT='usage: node tools/count-report-fields.js <subagents-dir> <review-log>'
EXPECTED_COUNTS='reviewer-transcripts: 21  other: 2  reports: 16  with-inputs-read: 10  ci-findings: 8  with-evidence: 6  secret-form-lines: 1  rejected-evidence-lines: 2'
EXPECTED_PER_INPUT='per-input: diff 10/13  plan 2/5  document 1/2  spec 1/1'
# The path part is compared from its last separator on: on Windows Git Bash
# node receives a C:/ path and writes back-slashes.
EXPECTED_NO_REPORT_1='no report: marker-eleventh.jsonl — multi-code-review round 3: Security'
EXPECTED_NO_REPORT_2='no report: no-marker-reviewer.jsonl — multi-code-review round 2: Adversarial red-team'
# A reviewer transcript without a marked report prints no description when its
# meta file is missing, cannot be parsed, or holds no description.
EXPECTED_NO_REPORT_BAD_META='no report: no-marker-bad-meta.jsonl'
EXPECTED_NO_REPORT_NO_DESCRIPTION='no report: no-marker-meta-without-description.jsonl'
EXPECTED_NO_REPORT_NO_META='no report: no-marker-no-meta.jsonl'
EXPECTED_LINES=7

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
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# run_script <out-file> <err-file> [args...]: run the script, leave its exit
# code in STATUS.
run_script() {
  local out="$1" err="$2"
  shift 2
  node "$SCRIPT" "$@" > "$out" 2> "$err"
  STATUS=$?
}
assert_usage_error() { # desc err-file
  assert_eq "$1: exit code" "$STATUS" "$EXIT_USAGE"
  if grep -qF -- "$USAGE_FRAGMENT" "$2"; then ok "$1: prints the usage line"; else bad "$1: prints the usage line"; fi
}

bold "1. Counts over the fixture folder"
OUT="$WORK/out.txt"
run_script "$OUT" "$WORK/err.txt" "$SUBAGENTS" "$LOG"
assert_eq "exit code" "$STATUS" "$EXIT_OK"
assert_eq "line 1: the counts" "$(sed -n 1p "$OUT")" "$EXPECTED_COUNTS"
assert_eq "line 2: the count per expected input" "$(sed -n 2p "$OUT")" "$EXPECTED_PER_INPUT"
assert_eq "line 3: the reviewer transcript whose marker is the 11th non-blank line" "$(sed -n 3p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT_1"
assert_eq "line 4: the reviewer transcript with an unparsable meta file, without a description" "$(sed -n 4p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT_BAD_META"
assert_eq "line 5: the reviewer transcript with a meta file that holds no description" "$(sed -n 5p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT_NO_DESCRIPTION"
assert_eq "line 6: the reviewer transcript with no meta file, without a description" "$(sed -n 6p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT_NO_META"
assert_eq "line 7: the reviewer transcript without a marked report, with its description" "$(sed -n 7p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT_2"
assert_eq "no further line" "$(awk 'END { print NR }' "$OUT")" "$EXPECTED_LINES"

bold "2. Usage errors"
run_script "$WORK/out2.txt" "$WORK/err2.txt"
assert_usage_error "no argument" "$WORK/err2.txt"
run_script "$WORK/out3.txt" "$WORK/err3.txt" "$WORK/missing-folder" "$LOG"
assert_usage_error "a folder that does not exist" "$WORK/err3.txt"
run_script "$WORK/out4.txt" "$WORK/err4.txt" "$SUBAGENTS" "$WORK/missing-log.md"
assert_usage_error "a review log that does not exist" "$WORK/err4.txt"
run_script "$WORK/out5.txt" "$WORK/err5.txt" "$SUBAGENTS"
assert_usage_error "one argument" "$WORK/err5.txt"
run_script "$WORK/out6.txt" "$WORK/err6.txt" "$SUBAGENTS" "$LOG" "$WORK/extra-argument"
assert_usage_error "three arguments" "$WORK/err6.txt"

bold "3. Each input needle of the script stands in the live text it is copied from"
# The script decides the expected inputs of a reviewer from four sentences of
# its prompt. A sentence that was reworded in the prompt, but not in the script,
# would make every count wrong without any other test failing.
fold_file() { # file: the lines of the file joined with single spaces
  awk '{ line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line); if (NR > 1) printf " "; printf "%s", line } END { print "" }' "$1"
}
script_needle() { # input name: the needle of that input, as written in the script
  sed -n "s/.*name: '$1', needle: '\(.*\)' },\$/\1/p" "$SCRIPT"
}
prompt_body() { # file: the lines between the `  prompt: |` line and the closing fence
  awk '$0 == "  prompt: |" { on = 1; next } on && substr($0, 1, 3) == "```" { exit } on { print }' "$1"
}
assert_needle_in() { # desc input source-file
  local needle
  needle="$(script_needle "$2")"
  if [ -z "$needle" ]; then
    bad "$1 (the script holds no needle for '$2')"
  elif fold_file "$3" | grep -qF -- "$needle"; then
    ok "$1"
  else
    bad "$1 (missing: $needle)"
  fi
}
CODE_PROMPT_FILE="$ROOT/skills/multi-code-review/reviewer-prompt.md"
DOC_PROMPT_FILE="$ROOT/skills/multi-doc-review/reviewer-prompt.md"
CODE_SKILL_FILE="$ROOT/skills/multi-code-review/SKILL.md"
DOC_SKILL_FILE="$ROOT/skills/multi-doc-review/SKILL.md"
prompt_body "$CODE_PROMPT_FILE" > "$WORK/code-prompt-body.txt"
prompt_body "$DOC_PROMPT_FILE" > "$WORK/doc-prompt-body.txt"
# The two lens cells that carry the spec words: the `plan` cell of the
# Correctness & completeness lens and the whole Execution readiness lens.
awk '
  $0 == "**Correctness & completeness**" { inlens = 1; next }
  inlens && /^\*\*/ { inlens = 0 }
  inlens && /^- plan:/ { incell = 1; print; next }
  incell && /^- / { incell = 0 }
  incell { print }
' "$DOC_SKILL_FILE" > "$WORK/spec-lens-cells.txt"
awk '
  $0 == "**Execution readiness**" { inlens = 1; next }
  inlens && (/^\*\*/ || /^## /) { exit }
  inlens { print }
' "$DOC_SKILL_FILE" >> "$WORK/spec-lens-cells.txt"
assert_needle_in "diff needle: stands in the code reviewer prompt body" diff "$WORK/code-prompt-body.txt"
assert_needle_in "document needle: stands in the doc reviewer prompt body" document "$WORK/doc-prompt-body.txt"
# The plan needle is also quoted in the step 6 expected-set rule of the same
# SKILL.md, so the check reads only the two texts that carry the sentence:
# the `PLAN_LINE` fill paragraph of step 2 and the legend entry of the prompt.
awk '
  /^ +`PLAN_LINE` is, on a lens-1/ { on = 1 }
  on && (/^[ \t]*$/ || /^ +`CARRIED_BLOCK` is/) { exit }
  on { print }
' "$CODE_SKILL_FILE" > "$WORK/plan-line-fill.txt"
awk '
  /^- `\[PLAN_LINE\]` / { on = 1; print; next }
  on && (/^[ \t]*$/ || /^- /) { exit }
  on { print }
' "$CODE_PROMPT_FILE" > "$WORK/plan-line-legend.txt"
assert_needle_in "plan needle: stands in the PLAN_LINE fill paragraph of multi-code-review SKILL.md" plan "$WORK/plan-line-fill.txt"
assert_needle_in "plan needle: stands in the PLAN_LINE legend entry of the multi-code-review reviewer prompt" plan "$WORK/plan-line-legend.txt"
assert_needle_in "spec needle: stands in the two lens cells of multi-doc-review SKILL.md" spec "$WORK/spec-lens-cells.txt"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
