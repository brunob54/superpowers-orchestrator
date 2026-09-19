#!/usr/bin/env bash
# undefined-command-guard.sh: stop a test suite when a command is not found.
#
# Load this file near the top of a suite, directly after its `set` line:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"
#
# The defect that this guard closes (row 66 of the orchestration issues):
# a check called a function that was not defined, for example a call placed
# before the function definition. Bash printed "command not found" and gave
# that command the exit code 127. The suite counted no FAIL and ended with
# exit code 0, so a check that never ran looked like a check that passed.
# `set -u` does not catch this. `command_not_found_handle` does not run on
# bash 3.2, the bash of macOS.
#
# How the guard works: bash runs an ERR (error) trap after a command that
# ends with a non-zero exit code. The trap below does nothing for every exit
# code except 127. A check that fails with exit code 1 (`grep -q` with no
# match, `false`) is normal in a suite and continues.
#
# The EXIT trap of a suite still runs after the `exit 1` below, so the
# suite still removes its temporary files. No suite sets an ERR trap of its
# own; a suite that sets one later replaces this guard.
#
# Known limits. Bash runs no ERR trap for a command that is the condition of
# an `if`, `while` or `until`, a part of an `&&` or `||` list, or negated
# with `!`. The guard cannot see an undefined call in those places. In a
# pipeline, bash looks at the last command only.
#
# The line number is the value of $LINENO inside the trap. On bash 3.2 this
# value is only a line near the call: measured cases were the exact line, a
# line two lines later, the line of the `for` word of a loop, and the first
# line of the function. The "command not found" line that bash prints first
# always holds the exact line.
#
# `set -E` (errtrace) makes functions and subshells inherit the ERR trap.
# Without it, bash does not run the trap inside a function: an undefined call
# in the middle of a function body is not seen, because the function still
# returns 0. With it, bash can run the trap a second time in the caller; this
# has no effect here, because the trap ends the script the first time it sees
# 127 and does nothing for every other exit code.
# One more known limit: inside a command substitution such as `x=$(check)`,
# the `exit 1` ends only the subshell. The FAIL line is printed, but the
# suite sees exit code 1 and continues.

set -E
trap '__guard_code=$?
if [ "$__guard_code" -eq 127 ]; then
  echo "FAIL: a command was not found (exit code 127) near line $LINENO of $0; the suite stops, because a check that does not run proves nothing" >&2
  exit 1
fi' ERR
