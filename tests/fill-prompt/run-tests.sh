#!/usr/bin/env bash
# fill-prompt test suite: unit tests on
# skills/multi-code-review/scripts/fill-prompt.js. Pure bash + node; no
# claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# everything goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/
# specs/prompt-pointer-dispatch-design.md, sections "scripts/fill-prompt.js"
# and "Testing strategy" item 1.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL_DIR="$ROOT/skills/multi-code-review"
FILL="$SKILL_DIR/scripts/fill-prompt.js"
FIXTURES="$ROOT/tests/fill-prompt/fixtures"
SMALL="$FIXTURES/small-template.md"
REVIEWER_TEMPLATE="$SKILL_DIR/reviewer-prompt.md"
FIX_TEMPLATE="$SKILL_DIR/fix-prompt.md"

# Wording the filled real templates must carry, and the residue they must not.
MARKER='<!-- multi-review report -->'
PATHSPEC="':(top,exclude)docs/superpowers-orchestrator/*/*-review-log.md'"
# A residual placeholder: uppercase letters and underscores, at least two
# characters, in square brackets.
PLACEHOLDER_ERE='\[[A-Z][A-Z_]*[A-Z]\]'
USAGE_LINE='usage: node fill-prompt.js --template <path> --out <path> [NAME=<value> | NAME=@<file>]...'
FAILURE_HEADING='## Previous attempt failed'

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
: "${WORK:?mktemp failed — refusing to run with an empty work path}"
trap 'rm -rf "$WORK"' EXIT
ERRF="$WORK/stderr.txt"
OUTF="$WORK/stdout.txt"
STATUS=0

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}
assert_file_not_matches() { # desc file extended-regex
  if grep -qE -- "$3" "$2"; then bad "$1 (unexpected match for: $3)"; else ok "$1"; fi
}
assert_same() { # desc actual-file expected-file
  if cmp -s "$2" "$3"; then ok "$1"; else bad "$1 (files differ)"; diff "$3" "$2" || true; fi
}
assert_absent() { # desc path
  if [ -e "$2" ]; then bad "$1 (exists: $2)"; else ok "$1"; fi
}
line_count() { grep -c '' "$1" | tr -d ' '; }

# Run the script; exit status in $STATUS, stderr in $ERRF, stdout in $OUTF.
fill() {
  node "$FILL" "$@" >"$OUTF" 2>"$ERRF"
  STATUS=$?
}
# The small template with the two fixed values and the four variable ones.
small_fill() { # out OPTIONAL_LINE INLINE_VALUE BODY_VALUE SHARED
  fill --template "$SMALL" --out "$1" ROUND=3 LENS_NAME=Security \
    "OPTIONAL_LINE=$2" "INLINE_VALUE=$3" "BODY_VALUE=$4" "SHARED=$5"
}

bold "1. Byte-for-byte fill of the small template"
small_fill "$WORK/full.md" "Optional line present." plain "@$FIXTURES/body-value.md" shared
assert_eq "full fill exits 0" "$STATUS" "0"
assert_eq "full fill prints nothing on stdout" "$(cat "$OUTF")" ""
assert_eq "full fill prints nothing on stderr" "$(cat "$ERRF")" ""
assert_same "full fill matches expected-full.md byte for byte" "$WORK/full.md" "$FIXTURES/expected-full.md"

bold "2. Values survive unchanged and are never re-substituted"
small_fill "$WORK/special.md" "" plain "@$FIXTURES/special-value.md" shared
assert_eq "special value: exits 0" "$STATUS" "0"
assert_file_contains "special value: \$HOME survives" "$WORK/special.md" '$HOME'
assert_file_contains "special value: backtick-quoted word survives" "$WORK/special.md" '`word`'
assert_file_contains "special value: pathspec survives" "$WORK/special.md" "$PATHSPEC"
assert_file_contains "special value: \$& and \$1 survive (replace specials not interpreted)" "$WORK/special.md" '$& $1'
assert_file_contains "special value: command substitution text survives as text" "$WORK/special.md" '$(echo no)'
small_fill "$WORK/bracket.md" "" plain "@$FIXTURES/bracket-value.md" shared
assert_eq "bracket value: exits 0" "$STATUS" "0"
assert_file_contains "bracket value: inserted verbatim" "$WORK/bracket.md" 'see [C1] and [ROUND] verbatim'
assert_eq "bracket value: the body's own [ROUND] was filled, only the value's stays" "$(grep -cF '[ROUND]' "$WORK/bracket.md" | tr -d ' ')" "1"
assert_file_contains "bracket value: report-id tokens in the body are untouched" "$WORK/bracket.md" 'Report ids such as [C1] and [I1] stay.'

bold "3. Empty values: whole-line removal versus a shared line"
small_fill "$WORK/empty.md" "" plain "@$FIXTURES/body-value.md" ""
assert_eq "empty values: exits 0" "$STATUS" "0"
assert_file_not_contains "empty whole-line value removes its line" "$WORK/empty.md" 'OPTIONAL_LINE'
assert_eq "empty whole-line value: one line fewer than the full fill" "$(line_count "$WORK/empty.md")" "7"
assert_file_contains "empty shared-line value substitutes the empty string" "$WORK/empty.md" 'Shared line with  here.'

bold "4. @file values, trailing newlines, malformed body"
sed '3d' "$FIXTURES/expected-full.md" > "$WORK/expected-no-optional.md"
small_fill "$WORK/nl.md" "@$FIXTURES/newline-only.md" plain "@$FIXTURES/body-value.md" shared
assert_eq "newline-only @file: exits 0" "$STATUS" "0"
assert_same "newline-only @file counts as empty and removes the whole line" "$WORK/nl.md" "$WORK/expected-no-optional.md"
fill --template "$FIXTURES/bad-indent-template.md" --out "$WORK/bad.md" ROUND=1
assert_eq "body line indented less than the first exits 2" "$STATUS" "2"
assert_file_contains "bad indent: message says the template is malformed" "$ERRF" 'malformed template'
assert_absent "bad indent: nothing written" "$WORK/bad.md"

bold "5. Strictness and exit codes"
fill --template "$SMALL" --out "$WORK/s3.md" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain "BODY_VALUE=@$FIXTURES/body-value.md"
assert_eq "uncovered placeholder exits 3" "$STATUS" "3"
assert_file_contains "uncovered placeholder: message names it" "$ERRF" 'SHARED'
assert_absent "uncovered placeholder: nothing written" "$WORK/s3.md"
fill --template "$SMALL" --out "$WORK/s4.md" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y NOT_HERE=1
assert_eq "unknown name exits 4" "$STATUS" "4"
assert_file_contains "unknown name: message names it" "$ERRF" 'NOT_HERE'
assert_absent "unknown name: nothing written" "$WORK/s4.md"
fill --template "$SMALL" --out "$WORK/s4b.md" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y LEGEND_ONLY=1
assert_eq "name that appears only in the legend exits 4" "$STATUS" "4"
assert_file_contains "legend-only name: message names it" "$ERRF" 'LEGEND_ONLY'
fill --template "$SMALL" --out "$WORK/wrap.md" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y WRAPPER_ONLY=z
assert_eq "name that appears only in the wrapper is accepted (exit 0)" "$STATUS" "0"
fill --template "$SMALL" --out "$WORK/s1a.md" --bogus ROUND=3
assert_eq "unknown option exits 1" "$STATUS" "1"
assert_eq "unknown option: usage line on stderr" "$(cat "$ERRF")" "$USAGE_LINE"
fill --template "$SMALL" ROUND=3
assert_eq "missing --out exits 1" "$STATUS" "1"
fill --out "$WORK/s1c.md" ROUND=3
assert_eq "missing --template exits 1" "$STATUS" "1"
fill --template "$SMALL" --template "$SMALL" --out "$WORK/s1d.md" ROUND=3
assert_eq "repeated --template exits 1" "$STATUS" "1"
fill --template "$SMALL" --out "$WORK/s1e.md" ROUND=3 ROUND=4
assert_eq "repeated NAME exits 1" "$STATUS" "1"
fill --template "$WORK/missing-template.md" --out "$WORK/s1e2.md" ROUND=3 ROUND=4
assert_eq "repeated NAME with an unreadable template still exits 1 (usage before file reads)" "$STATUS" "1"
fill --template "$SMALL" --out "$WORK/s1f.md" lowercase=1
assert_eq "argument that is not NAME=<rest> exits 1" "$STATUS" "1"
fill --template "$SMALL" ROUND=3 --out
assert_eq "option without a value exits 1" "$STATUS" "1"
fill --template "$SMALL" --out "$WORK/s5.md" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain "BODY_VALUE=@$WORK/does-not-exist.md" SHARED=y
assert_eq "missing @file exits 5" "$STATUS" "5"
assert_file_contains "missing @file: message names the file" "$ERRF" 'does-not-exist.md'
fill --template "$FIXTURES/no-prompt-template.md" --out "$WORK/s2.md" ROUND=3
assert_eq "template without a prompt block exits 2" "$STATUS" "2"
assert_absent "template without a prompt block: nothing written" "$WORK/s2.md"
fill --template "$WORK/missing-template.md" --out "$WORK/s5b.md" ROUND=3
assert_eq "unreadable --template exits 5" "$STATUS" "5"
fill --template "$SMALL" --out "$WORK/no-such-dir/out.md" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y
assert_eq "unwritable --out exits 5" "$STATUS" "5"

bold "6. The real reviewer template"
printf '%s\n' 'Lens text with $ signs, `code` and [C1]-style ids.' > "$WORK/lens.txt"
printf '%s\n' '## Carried Findings' 'Triage these carried Minor findings in your Carried Findings Triage section:' '- [M1] a.py:1 — carried from the host gate' > "$WORK/carried.txt"
PLAN_LINE_VALUE='Plan/requirements the branch implements (read it first): /repo/docs/plan.md'
fill --template "$REVIEWER_TEMPLATE" --out "$WORK/reviewer.md" ROUND=1 REPO_ROOT=/repo BASE_SHA=aaa111 HEAD_SHA=bbb222 PACKAGE_FILE=/repo/.superpowers/sdd/review-1.md 'LENS_NAME=Correctness & spec alignment' "LENS_INSTRUCTIONS=@$WORK/lens.txt" "PLAN_LINE=$PLAN_LINE_VALUE" "CARRIED_BLOCK=@$WORK/carried.txt"
assert_eq "reviewer template: full value set exits 0" "$STATUS" "0"
assert_eq "reviewer template: first output line is the dedented first body line" "$(head -n 1 "$WORK/reviewer.md")" 'You are an independent code reviewer. You review ONE branch diff'
assert_file_contains "reviewer template: marker line present" "$WORK/reviewer.md" "$MARKER"
assert_file_contains "reviewer template: blinding pathspec line present" "$WORK/reviewer.md" "$PATHSPEC"
assert_file_contains "reviewer template: plan line filled" "$WORK/reviewer.md" "$PLAN_LINE_VALUE"
assert_file_contains "reviewer template: carried block filled" "$WORK/reviewer.md" '## Carried Findings'
assert_file_contains "reviewer template: lens name filled into the lens heading" "$WORK/reviewer.md" '**Correctness & spec alignment.** Lens text with $ signs'
assert_file_not_matches "reviewer template: no residual placeholder" "$WORK/reviewer.md" "$PLACEHOLDER_ERE"
fill --template "$REVIEWER_TEMPLATE" --out "$WORK/reviewer2.md" ROUND=2 REPO_ROOT=/repo BASE_SHA=aaa111 HEAD_SHA=bbb222 PACKAGE_FILE=/repo/.superpowers/sdd/review-2.md 'LENS_NAME=Adversarial red-team' "LENS_INSTRUCTIONS=@$WORK/lens.txt" PLAN_LINE= CARRIED_BLOCK=
assert_eq "reviewer template: empty PLAN_LINE and CARRIED_BLOCK exit 0" "$STATUS" "0"
assert_file_not_contains "reviewer template: empty plan line omitted" "$WORK/reviewer2.md" 'Plan/requirements'
assert_file_not_matches "reviewer template: no residual placeholder without plan or carried block" "$WORK/reviewer2.md" "$PLACEHOLDER_ERE"
NO_PACKAGE_VALUE='none — fetch the diff yourself via the git commands below'
fill --template "$REVIEWER_TEMPLATE" --out "$WORK/reviewer2b.md" ROUND=2 REPO_ROOT=/repo BASE_SHA=aaa111 HEAD_SHA=bbb222 "PACKAGE_FILE=$NO_PACKAGE_VALUE" 'LENS_NAME=Adversarial red-team' "LENS_INSTRUCTIONS=@$WORK/lens.txt" PLAN_LINE= CARRIED_BLOCK=
assert_eq "reviewer template: quoted no-package PACKAGE_FILE value (contains spaces) exits 0" "$STATUS" "0"
assert_file_contains "reviewer template: no-package value inserted verbatim" "$WORK/reviewer2b.md" "$NO_PACKAGE_VALUE"
fill --template "$REVIEWER_TEMPLATE" --out "$WORK/reviewer3.md" ROUND=1 REPO_ROOT=/repo BASE_SHA=aaa111 HEAD_SHA=bbb222 PACKAGE_FILE=/repo/x.md LENS_NAME=x "LENS_INSTRUCTIONS=@$WORK/lens.txt" PLAN_LINE= CARRIED_BLOCK= PLAN_PATH=/repo/docs/plan.md
assert_eq "reviewer template: PLAN_PATH (legend only) exits 4" "$STATUS" "4"
assert_file_contains "reviewer template: PLAN_PATH message names it" "$ERRF" 'PLAN_PATH'

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
