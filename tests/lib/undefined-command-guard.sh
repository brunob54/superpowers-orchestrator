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
# The re-run wrapper (row 68 of the orchestration issues): the ERR trap does
# not run in the places of limits 1 to 5 below, but bash still prints its
# "command not found" line on standard error there. On its first load, the
# guard therefore starts the suite again as a child process, with a marker
# variable set and with `LC_MESSAGES=C`, so that bash prints the message in
# English. The wrapper copies the standard error of the child to a log file
# and still shows it. The child loads the guard again, sees the marker, and
# runs the body of the suite with the ERR trap. The body runs one time. When
# the child ends, the wrapper ends with exit code 1 if the log file holds a
# line of the form `<script>: line <number>: <command>: command not found`.
# In every other case the wrapper ends with the exit code of the child. The
# wrapper does not start when the suite is loaded with `source`, or when the
# guard is loaded from a file that is not $0 (measured without this rule:
# `bash -c 'source suite'` ran `bash bash` and ended with exit code 126).
# The wrapper uses no named pipe and no process substitution (neither is
# reliable in Git Bash on Windows).
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
# Limits of the ERR trap. Each one was measured on bash 3.2. In the places
# of limits 1 to 5 the trap does not stop the suite at the call. The re-run
# wrapper then fails the suite at its END, when the message of bash reached
# standard error. tests/suite-guard has a check for limits 1, 2, 3 and 4, for
# the pipeline form of limit 5, and for the `return 127` form of limit 6.
# 1. Bash runs no ERR trap for a command that is the condition of an `if`,
#    `while` or `until`, for a command negated with `!`, and for every command
#    of an `&&` or `||` list except the last one. The trap cannot see an
#    undefined call in those places.
# 2. While a function runs in one of these places (`if helper`,
#    `if ! helper`, `helper && x`, `helper || x`), bash runs no ERR trap for
#    ANY command in the body of that function, and of the functions that it
#    calls. `set -E` does not change this. One exception: a plain statement
#    `! helper` KEEPS the trap on in the body of `helper`, and the trap stops
#    the suite there. A plain statement `! undefined_call` is a case of
#    limit 1.
# 3. A command substitution runs in a subshell, and the `exit 1` of the trap
#    ends only that subshell. Two cases:
#    - `x=$(undefined_call)` as a plain assignment: the assignment gives exit
#      code 127 to the script, and the trap stops the script.
#    - `x=$(check)`, where the undefined call is in the middle of the body of
#      `check`: the FAIL line is printed, but the script sees exit code 1 and
#      continues.
# 4. `assert "label" "$(undefined_call)"` and `local x="$(undefined_call)"`:
#    the exit code of the substitution is lost. No FAIL line is printed and
#    the script continues with an empty value.
# 5. In a plain subshell `( ... )`, the FAIL line is printed and the subshell
#    ends, but the script sees exit code 1 and continues. In a background job
#    (`command &`), nothing is seen. In a pipeline, the trap sees only the
#    last command.
# 6. The trap reads the exit code only. It stops the script on EVERY exit
#    code 127, also when a command gives 127 on purpose: a function that runs
#    `return 127`, `bash -c "exit 127"`, `x=$(exit 127)`. The message then
#    still says that a command was not found. A future check that expects
#    exit code 127 must run that command in a place of limit 1, for example
#    `code=0; command_under_test || code=$?`.
#
# Limits of the re-run wrapper. Limits 7 to 10 were measured on bash 3.2.
# 7. The wrapper reads standard error only. It does not see an undefined call
#    whose standard error is hidden or captured: `helper 2>/dev/null`,
#    `x=$(helper 2>&1)`, `if helper >/dev/null 2>&1`.
# 8. The wrapper fails the suite for every line of the message form on the
#    standard error of the suite, also when a check makes such a line on
#    purpose: a check that calls an undefined command to test something, or
#    that prints the full form `<script>: line 5: tool: command not found`.
#    Such a check must capture or hide that standard error. The bare words
#    `command not found`, or `tool: command not found`, do not match.
# 9. Standard error passes through `tee`. When a caller joins both streams
#    (`bash suite 2>&1`), a standard error line can arrive late relative to
#    the standard output lines near it. `bash -x suite` traces the wrapper
#    only, no longer the body of the suite.
# 10. A SIGTERM or SIGHUP signal that is sent to the wrapper only ends the
#    wrapper at once (exit code 143 or 129) and removes the log file, but the
#    child suite runs on to its end. Ctrl-C in a terminal sends SIGINT to the
#    wrapper and to the child, so both end.
# 11. Not tested: Git Bash on Windows, and bash 5. Not testable on this Mac,
#    which has no message catalogue: on a bash with message catalogues,
#    `LC_ALL` or `LANGUAGE` overrides `LC_MESSAGES`, the message is then not
#    in English, and the wrapper does not see it.
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

# The name of the marker variable. The re-run wrapper sets it for the child.
GUARD_INNER_RUN_VAR='__GUARD_INNER_RUN'
# The form of the message of bash: `<script>: line <number>: <command>:
# command not found`.
GUARD_NOT_FOUND_PATTERN=': line [0-9]*: .*: command not found$'

# The re-run wrapper. It starts only when the marker is not set, and only when
# the file that loads the guard is the script that bash runs ($0).
if [ -z "${!GUARD_INNER_RUN_VAR:-}" ] && [ "${BASH_SOURCE[1]:-}" = "$0" ]; then
  __guard_log="$(mktemp "${TMPDIR:-/tmp}/undefined-command-guard.XXXXXX")" || exit 1
  # Measured on bash 3.2: the EXIT trap also runs when SIGINT, SIGTERM or
  # SIGHUP ends the wrapper, so the log file is removed in those cases too.
  trap 'rm -f "$__guard_log"' EXIT
  # File descriptor 3 keeps the standard output of the child away from `tee`.
  { env "$GUARD_INNER_RUN_VAR=1" LC_MESSAGES=C "$BASH" "$0" "$@" 2>&1 1>&3 | tee "$__guard_log" >&2
    __guard_code=${PIPESTATUS[0]}; } 3>&1
  __guard_count="$(grep -c -- "$GUARD_NOT_FOUND_PATTERN" "$__guard_log")"
  if [ "$__guard_count" -gt 0 ]; then
    echo "FAIL: the standard error of $0 holds $__guard_count \"command not found\" line(s); the suite fails, because a check that does not run proves nothing" >&2
    __guard_code=1
  fi
  exit "$__guard_code"
fi

set -E
trap '__guard_code=$?
if [ "$__guard_code" -eq 127 ]; then
  echo "FAIL: a command was not found (exit code 127) near line $LINENO of $0; the suite stops, because a check that does not run proves nothing" >&2
  exit 1
fi' ERR
