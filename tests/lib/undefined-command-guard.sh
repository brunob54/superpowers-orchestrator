#!/usr/bin/env bash
# undefined-command-guard.sh: stop a test suite when a command is not found.
#
# Load this file near the top of a suite, before the first check: directly
# after the `set` line, or after the comment header when the suite has no
# `set` line:
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
# suite still removes its temporary files. A suite that sets an ERR trap of
# its own after the load line replaces this guard. tests/suite-guard scans
# every guarded suite for the plain forms of this: a `trap` line that names
# ERR, `set +E`, `set +o errtrace`, `shopt -u -o errtrace`. The scan reads the
# text of the suite file only. It cannot see a command that `eval` runs, a
# signal name held in a variable, a line continuation between `trap` and ERR,
# or a file that the suite loads with `source`.
#
# Known limits. Each one was measured on bash 3.2. tests/suite-guard has a
# check for limits 1, 2, 3 and 4, and for the `return 127` form of limit 6.
# Limit 5 has no check.
# 1. Bash runs no ERR trap for a command that is the condition of an `if`,
#    `while` or `until`, for a command negated with `!`, and for every command
#    of an `&&` or `||` list except the last one. The guard cannot see an
#    undefined call in those places.
# 2. While a function runs in one of the places of limit 1 (`if helper`,
#    `helper && x`, `helper || x`), bash runs no ERR trap for ANY command in
#    the body of that function, and of the functions that it calls. `set -E`
#    does not change this. An undefined call in such a body is not seen.
# 3. A command substitution runs in a subshell, and the `exit 1` of the trap
#    ends only that subshell. Two cases:
#    - `x=$(undefined_call)` as a plain assignment: the assignment gives exit
#      code 127 to the script, and the guard stops the script.
#    - `x=$(check)`, where the undefined call is in the middle of the body of
#      `check`: the FAIL line is printed, but the script sees exit code 1 and
#      continues.
# 4. `assert "label" "$(undefined_call)"` and `local x="$(undefined_call)"`:
#    the exit code of the substitution is lost. No FAIL line is printed and
#    the script continues with an empty value.
# 5. In a plain subshell `( ... )`, the FAIL line is printed and the subshell
#    ends, but the script sees exit code 1 and continues. In a background job
#    (`command &`), nothing is seen. In a pipeline, the guard sees only the
#    last command.
# 6. The guard reads the exit code only. It stops the script on EVERY exit
#    code 127, also when a command gives 127 on purpose: a function that runs
#    `return 127`, `bash -c "exit 127"`, `x=$(exit 127)`. The message then
#    still says that a command was not found. A future check that expects
#    exit code 127 must run that command in a place of limit 1, for example
#    `code=0; command_under_test || code=$?`.
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

set -E
trap '__guard_code=$?
if [ "$__guard_code" -eq 127 ]; then
  echo "FAIL: a command was not found (exit code 127) near line $LINENO of $0; the suite stops, because a check that does not run proves nothing" >&2
  exit 1
fi' ERR
