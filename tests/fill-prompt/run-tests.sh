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
# The number must be the line of the template FILE (line 7 of the fixture),
# not an offset counted from the first body line.
assert_file_contains "bad indent: message names the template file line" "$ERRF" 'template line 7 is not indented at least as far as the first body line'
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
assert_absent "missing @file: nothing written" "$WORK/s5.md"
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

bold "6b. Hardening: line endings, trailing blank body line, output file mode"
# S5: a template whose lines are mostly LF but the fence-open line ends
# CRLF. Splitting on the detected end-of-line string (instead of on either
# line ending) would leave the plain-LF lines merged into one line holding
# an embedded bare newline; locks that this never happens and that, once
# CRLF is the detected end-of-line, every output line ends with CR.
MIXED_EOL_TEMPLATE="$WORK/mixed-eol-template.md"
printf '```\r\n' > "$MIXED_EOL_TEMPLATE"
printf 'Agent tool (general-purpose):\n' >> "$MIXED_EOL_TEMPLATE"
printf '  prompt: |\n' >> "$MIXED_EOL_TEMPLATE"
printf '    First line [ROUND].\n' >> "$MIXED_EOL_TEMPLATE"
printf '    Second line.\n' >> "$MIXED_EOL_TEMPLATE"
printf '```\n' >> "$MIXED_EOL_TEMPLATE"
fill --template "$MIXED_EOL_TEMPLATE" --out "$WORK/mixed-eol.md" ROUND=3
assert_eq "mixed line endings: exits 0" "$STATUS" "0"
MIXED_EOL_LINE_COUNT="$(line_count "$WORK/mixed-eol.md")"
MIXED_EOL_CR_COUNT="$(grep -c $'\r$' "$WORK/mixed-eol.md" | tr -d ' ')"
assert_eq "mixed line endings: output has exactly 2 lines (fails if the file is missing)" "$MIXED_EOL_LINE_COUNT" "2"
assert_eq "mixed line endings: no output line holds an embedded bare newline (every line ends with CR)" "$MIXED_EOL_CR_COUNT" "$MIXED_EOL_LINE_COUNT"
printf 'First line 3.\nSecond line.\n' > "$WORK/mixed-eol-expected.txt"
tr -d '\r' < "$WORK/mixed-eol.md" > "$WORK/mixed-eol-normalized.txt"
assert_same "mixed line endings: LF-normalized output matches the expected text" "$WORK/mixed-eol-normalized.txt" "$WORK/mixed-eol-expected.txt"

# S7: a template whose body's last line before the closing fence is blank
# (whitespace only). Skipping the trailing-blank-line drop would leave that
# blank line in the dedented body, so the written output would end with two
# newlines instead of exactly one; locks the single-trailing-newline
# invariant byte for byte.
TRAILING_BLANK_TEMPLATE="$WORK/trailing-blank-template.md"
printf '```\n' > "$TRAILING_BLANK_TEMPLATE"
printf 'Agent tool (general-purpose):\n' >> "$TRAILING_BLANK_TEMPLATE"
printf '  prompt: |\n' >> "$TRAILING_BLANK_TEMPLATE"
printf '    First line [ROUND].\n' >> "$TRAILING_BLANK_TEMPLATE"
printf '    Second line.\n' >> "$TRAILING_BLANK_TEMPLATE"
printf '    \n' >> "$TRAILING_BLANK_TEMPLATE"
printf '```\n' >> "$TRAILING_BLANK_TEMPLATE"
fill --template "$TRAILING_BLANK_TEMPLATE" --out "$WORK/trailing-blank.md" ROUND=3
assert_eq "trailing blank body line: exits 0" "$STATUS" "0"
printf 'First line 3.\nSecond line.\n' > "$WORK/trailing-blank-expected.txt"
assert_same "trailing blank body line: output matches expected byte for byte (exactly one trailing newline)" "$WORK/trailing-blank.md" "$WORK/trailing-blank-expected.txt"

# S3: the output file's permissions are owner read/write only.
OUTPUT_MODE_FILE="$WORK/mode-check.md"
fill --template "$SMALL" --out "$OUTPUT_MODE_FILE" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y
assert_eq "output file mode: fill exits 0" "$STATUS" "0"
UNAME_S="$(uname -s)"
case "$UNAME_S" in
  MINGW*|MSYS*)
    ok "output file mode: owner read/write only (skipped on Git Bash — Windows emulates POSIX permissions)"
    ;;
  *)
    OUTPUT_MODE="$(ls -ld "$OUTPUT_MODE_FILE" | cut -c1-10)"
    assert_eq "output file mode: owner read/write only" "$OUTPUT_MODE" "-rw-------"
    ;;
esac

bold "7. The real fix template"
printf '%s\n' '- [C1] Critical — src/a.py:10 — off-by-one in the range end' '- [I1] Important — src/b.py:3 — missing null check' > "$WORK/findings.txt"
fill --template "$FIX_TEMPLATE" --out "$WORK/fix.md" ROUND=2 SLUG=my-branch REPO_ROOT=/repo FIX_REPORT_FILE=/repo/docs/x/implementation/my-branch-fix-reports.md "FINDINGS=@$WORK/findings.txt" FAILURE_BLOCK=
assert_eq "fix template: first dispatch (empty FAILURE_BLOCK) exits 0" "$STATUS" "0"
assert_file_contains "fix template: generic commit subject filled" "$WORK/fix.md" 'review fixes (my-branch, round 2)'
assert_file_contains "fix template: findings inserted verbatim" "$WORK/fix.md" '- [C1] Critical — src/a.py:10 — off-by-one in the range end'
assert_file_contains "fix template: fix-report path filled" "$WORK/fix.md" '/repo/docs/x/implementation/my-branch-fix-reports.md'
assert_file_not_contains "fix template: no failure heading on the first dispatch" "$WORK/fix.md" "$FAILURE_HEADING"
assert_file_not_matches "fix template: no residual placeholder" "$WORK/fix.md" "$PLACEHOLDER_ERE"
printf '%s\n' "$FAILURE_HEADING" 'covering tests failed: 2 errors in tests/test_a.py' > "$WORK/failure.txt"
fill --template "$FIX_TEMPLATE" --out "$WORK/fix-retry.md" ROUND=2 SLUG=my-branch REPO_ROOT=/repo FIX_REPORT_FILE=/repo/docs/x/implementation/my-branch-fix-reports.md "FINDINGS=@$WORK/findings.txt" "FAILURE_BLOCK=@$WORK/failure.txt"
assert_eq "fix template: re-dispatch (FAILURE_BLOCK from file) exits 0" "$STATUS" "0"
assert_file_contains "fix template: failure heading present on the re-dispatch" "$WORK/fix-retry.md" "$FAILURE_HEADING"
assert_file_contains "fix template: failure text present on the re-dispatch" "$WORK/fix-retry.md" 'covering tests failed: 2 errors in tests/test_a.py'
assert_file_not_matches "fix template: no residual placeholder on the re-dispatch" "$WORK/fix-retry.md" "$PLACEHOLDER_ERE"

bold "8. Round 2 fixes: refuse to overwrite --out, and trailing blank after fill"
# M1: filling onto an existing --out whose content DIFFERS exits 5 and leaves
# the existing file's content unchanged; no temporary file is left behind
# either.
EXISTING_OUT="$WORK/existing.md"
printf 'pre-existing content\n' > "$EXISTING_OUT"
fill --template "$SMALL" --out "$EXISTING_OUT" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y
assert_eq "existing --out: exits 5" "$STATUS" "5"
assert_file_contains "existing --out: message names the path" "$ERRF" "$EXISTING_OUT"
assert_eq "existing --out: content unchanged" "$(cat "$EXISTING_OUT")" "pre-existing content"
# The atomic write names its temporary file `.<out basename>.<pid>.<hex>.tmp`
# in the output directory; none may survive the refusal.
assert_eq "existing --out: no temporary file left behind" "$(find "$WORK" -maxdepth 1 -name '.existing.md.*' | wc -l | tr -d ' ')" "0"

# Round 4 [M1]: a repeat of a fill whose first run completed — the caller lost
# the tool result and re-issued the same command — finds an --out whose content
# is byte-identical to what this run would write, so it exits 0 without writing
# anything. The file is unchanged and no temporary file survives.
IDENTICAL_OUT="$WORK/identical.md"
fill --template "$SMALL" --out "$IDENTICAL_OUT" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y
assert_eq "identical repeat: the first fill exits 0" "$STATUS" "0"
cp "$IDENTICAL_OUT" "$WORK/identical-expected.txt"
fill --template "$SMALL" --out "$IDENTICAL_OUT" ROUND=3 LENS_NAME=Security OPTIONAL_LINE= INLINE_VALUE=plain BODY_VALUE=x SHARED=y
assert_eq "identical repeat: exits 0" "$STATUS" "0"
assert_same "identical repeat: content unchanged byte for byte" "$IDENTICAL_OUT" "$WORK/identical-expected.txt"
assert_eq "identical repeat: no temporary file left behind" "$(find "$WORK" -maxdepth 1 -name '.identical.md.*' | wc -l | tr -d ' ')" "0"

# M2: a template whose last body line is a whole-line placeholder given the
# empty value. Dropping trailing blanks BEFORE fill would miss the blank
# line that fill's removal of the placeholder line exposes as the new last
# line, leaving two trailing newlines; locks the single-trailing-newline
# invariant for this case too.
TRAILING_PLACEHOLDER_TEMPLATE="$WORK/trailing-placeholder-template.md"
printf '```\n' > "$TRAILING_PLACEHOLDER_TEMPLATE"
printf 'Agent tool (general-purpose):\n' >> "$TRAILING_PLACEHOLDER_TEMPLATE"
printf '  prompt: |\n' >> "$TRAILING_PLACEHOLDER_TEMPLATE"
printf '    First line [ROUND].\n' >> "$TRAILING_PLACEHOLDER_TEMPLATE"
printf '    Second line.\n' >> "$TRAILING_PLACEHOLDER_TEMPLATE"
printf '    [OPT]\n' >> "$TRAILING_PLACEHOLDER_TEMPLATE"
printf '```\n' >> "$TRAILING_PLACEHOLDER_TEMPLATE"
fill --template "$TRAILING_PLACEHOLDER_TEMPLATE" --out "$WORK/trailing-placeholder.md" ROUND=3 OPT=
assert_eq "trailing whole-line placeholder given the empty value: exits 0" "$STATUS" "0"
printf 'First line 3.\nSecond line.\n' > "$WORK/trailing-placeholder-expected.txt"
assert_same "trailing whole-line placeholder given the empty value: output matches expected byte for byte (exactly one trailing newline)" "$WORK/trailing-placeholder.md" "$WORK/trailing-placeholder-expected.txt"

bold "9. Round 4 fix: a fenced example inside the prompt body"
# I3: the body of this template holds a fenced example whose opening fence is
# at column 0. Taking that fence as the closing fence would truncate the body
# (the marker line after the example would be lost) and still exit 0; the
# template must be rejected instead.
INNER_FENCE_OUT="$WORK/inner-fence.md"
fill --template "$FIXTURES/inner-fence-template.md" --out "$INNER_FENCE_OUT" ROUND=1
assert_eq "fenced example inside the body exits 2" "$STATUS" "2"
assert_file_contains "inner fence: message says the template is malformed" "$ERRF" 'malformed template'
assert_file_contains "inner fence: message gives the reason" "$ERRF" 'the first fenced block closes inside the prompt body'
assert_absent "inner fence: nothing written" "$INNER_FENCE_OUT"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
