#!/usr/bin/env bash
# suite-guard test suite: behaviour checks on
# tests/lib/undefined-command-guard.sh, and a check that every fast suite
# loads that guard.
# Pure bash + grep; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows).
#
# Why the guard exists (row 66 of the orchestration issues): a suite stayed
# green when a check called a function that was not defined. Bash printed
# "command not found", the exit code of that command was 127, no FAIL was
# counted, and the suite ended with exit code 0.
#
# Every behaviour check writes a small fixture script into a temporary
# folder, runs it with bash, and reads its exit code and its output.

set -u
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GUARD_NAME='undefined-command-guard.sh'
GUARD="$ROOT/tests/lib/$GUARD_NAME"

# The guard must be loaded before the first check of a suite runs. Every
# suite starts with a comment header, then its `set` line, then the load
# line. The longest header ends at line 34 (tests/in-run-rulings).
GUARD_LOAD_MAX_LINE=45

# The fast suites that must load the guard.
GUARDED_SUITES='smart-compress reviewer-templates writing-plans in-run-rulings
fill-prompt orchestrating-development review-gates measure-context pickup
analyze-compaction sdd-scripts suite-guard'

# Fragments of the guard's message (free text, matched as fixed strings).
MSG_FAIL='FAIL'
MSG_CODE='exit code 127'
# A marker that a fixture prints when it reaches its last line.
REACHED_END='fixture-reached-its-end'
# A marker that a fixture prints from its own EXIT trap.
CLEANUP_RAN='fixture-cleanup-ran'
UNDEFINED_CALL='undefined_function_of_row_66 some-argument'

PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

pass() { PASS=$((PASS+1)); green "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); ERRORS+=("$1"); red "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# run_fixture <name> <body>: write a script that loads the guard and then
# runs <body>; run it; leave its exit code in CODE and its output (standard
# output and standard error together) in OUT.
run_fixture() {
  local script="$WORK/$1.sh"
  {
    printf '%s\n' 'set -u'
    printf 'source "%s"\n' "$GUARD"
    printf '%s\n' "$2"
    printf 'echo %s\n' "$REACHED_END"
  } > "$script"
  CODE=0
  OUT="$(bash "$script" 2>&1)" || CODE=$?
}

out_has() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }

# assert_stopped <label>: the last fixture ended early with exit code 1 and
# printed the guard's message.
assert_stopped() {
  if [ "$CODE" -eq 1 ] && out_has "$MSG_FAIL" && out_has "$MSG_CODE" \
     && ! out_has "$REACHED_END"; then
    pass "$1"
  else
    fail "$1 (exit code $CODE, output: $OUT)"
  fi
}

# assert_continued <label>: the last fixture reached its last line, ended
# with exit code 0, and the guard printed nothing.
assert_continued() {
  if [ "$CODE" -eq 0 ] && out_has "$REACHED_END" && ! out_has "$MSG_CODE"; then
    pass "$1"
  else
    fail "$1 (exit code $CODE, output: $OUT)"
  fi
}

bold "The guard stops a suite on a call to an undefined function"

run_fixture bare "$UNDEFINED_CALL"
assert_stopped "a bare call to an undefined function stops the script"
if printf '%s\n' "$OUT" | grep -F -- "$MSG_CODE" | grep -qF 'bare.sh'; then
  pass "the message names the script"
else
  fail "the message names the script (output: $OUT)"
fi

run_fixture last-in-function "check() {
  $UNDEFINED_CALL
}
check"
assert_stopped "an undefined call at the end of a function body stops the script"

run_fixture middle-of-function "check() {
  echo before
  $UNDEFINED_CALL
  echo after
}
check"
assert_stopped "an undefined call in the middle of a function body stops the script"

run_fixture for-loop "for item in 1 2; do
  $UNDEFINED_CALL
  echo next
done"
assert_stopped "an undefined call inside a for loop stops the script"

bold "The guard reacts only to exit code 127"

run_fixture exit-code-1 "false
printf 'abc\n' | grep -q 'no-such-text'
check() { false; echo in-function; }
check"
assert_continued "a command that fails with exit code 1 does not stop the script"

# This check records a known limit; it does not describe a wanted behaviour.
# Bash does not run an ERR (error) trap for a command that is the condition
# of an `if`, or a part of an `&&` or `||` list. The guard cannot see an
# undefined call in those places.
run_fixture if-condition "if $UNDEFINED_CALL; then echo yes; fi
$UNDEFINED_CALL || echo handled"
assert_continued "known limit: an undefined call in an if condition or an || list is not seen"

# This check records the second known limit. Inside a command substitution
# such as `x=$(check)`, the guard runs in the subshell. It prints its message
# and ends the subshell only. The script sees exit code 1 and continues.
run_fixture command-substitution "check() {
  echo before
  $UNDEFINED_CALL
  echo after
}
captured=\$(check)"
if [ "$CODE" -eq 0 ] && out_has "$REACHED_END" && out_has "$MSG_CODE"; then
  pass "known limit: an undefined call inside \$(...) prints the message, but the script continues"
else
  fail "known limit: an undefined call inside \$(...) prints the message, but the script continues (exit code $CODE, output: $OUT)"
fi

bold "The guard keeps the EXIT trap of a suite"

run_fixture exit-trap "trap 'echo $CLEANUP_RAN' EXIT
$UNDEFINED_CALL"
assert_stopped "an undefined call stops a script that has an EXIT trap"
if out_has "$CLEANUP_RAN"; then
  pass "the EXIT trap of the script still runs after the guard stops it"
else
  fail "the EXIT trap of the script still runs after the guard stops it (output: $OUT)"
fi

bold "Every fast suite loads the guard before its first check"

for suite in $GUARDED_SUITES; do
  file="$ROOT/tests/$suite/run-tests.sh"
  load_line="$(grep -nE "^(source|\.) .*/$GUARD_NAME\"?\$" "$file" | head -1 | cut -d: -f1)"
  if [ -z "$load_line" ]; then
    fail "tests/$suite/run-tests.sh loads the guard"
  elif [ "$load_line" -gt "$GUARD_LOAD_MAX_LINE" ]; then
    fail "tests/$suite/run-tests.sh loads the guard in its first $GUARD_LOAD_MAX_LINE lines (found at line $load_line)"
  else
    pass "tests/$suite/run-tests.sh loads the guard at line $load_line"
  fi
done

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
