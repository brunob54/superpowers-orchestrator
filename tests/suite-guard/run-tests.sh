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
# suite starts with a comment header, then its `set` line when it has one,
# then the load line. No suite runs a check in its first lines; the latest
# load line of today is the one of tests/in-run-rulings.
GUARD_LOAD_MAX_LINE=45

# Every file tests/*/run-tests.sh must load the guard, except the suites
# named here. The list of suites is built from the files on disk, so a new
# suite that does not load the guard fails a check below.
#   opencode: it runs under `set -euo pipefail`, which already stops the
#             script with exit code 127 on a command that is not found.
# tests/codex/run-unit-tests.sh also runs under `set -euo pipefail`. Its file
# name is not run-tests.sh, so the file pattern does not match it and it
# needs no entry here.
UNGUARDED_SUITES='opencode'
# The smallest number of suites that the file pattern must find. A pattern
# that finds nothing must not look like a success.
MIN_GUARDED_SUITES=12

# Fragments of the guard's message (free text, matched as fixed strings).
MSG_FAIL='FAIL'
MSG_CODE='exit code 127'
# A fragment of the message that the re-run wrapper of the guard prints at
# the end of the run.
MSG_AT_END='"command not found" line(s)'
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

# fixture_bash <arguments of bash>: run bash without the marker variable of
# the guard. This suite runs as the child of the re-run wrapper, so the marker
# is set here. A fixture that inherits the marker would not start the wrapper.
fixture_bash() { env -u "$GUARD_INNER_RUN_VAR" bash "$@"; }

# run_fixture <name> <body>: write a script that loads the guard and then
# runs <body>; run it; leave its path in SCRIPT, its exit code in CODE and its
# output (standard output and standard error together) in OUT.
run_fixture() {
  SCRIPT="$WORK/$1.sh"
  {
    printf '%s\n' 'set -u'
    printf 'source "%s"\n' "$GUARD"
    printf '%s\n' "$2"
    printf 'echo %s\n' "$REACHED_END"
  } > "$SCRIPT"
  CODE=0
  OUT="$(fixture_bash "$SCRIPT" 2>&1)" || CODE=$?
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

# assert_caught_at_end <label>: the ERR (error) trap did not see the call, so
# the last fixture reached its last line. The re-run wrapper then printed its
# message and ended with exit code 1.
assert_caught_at_end() {
  if [ "$CODE" -eq 1 ] && out_has "$REACHED_END" && out_has "$MSG_AT_END"; then
    pass "$1"
  else
    fail "$1 (exit code $CODE, output: $OUT)"
  fi
}

# assert_exit_code <code> <label>: the last fixture ended with <code>.
assert_exit_code() {
  if [ "$CODE" -eq "$1" ]; then pass "$2"; else fail "$2 (exit code $CODE, output: $OUT)"; fi
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

# Limit 1 of the guard file. Bash does not run an ERR (error) trap for a
# command that is the condition of an `if` or a `while`, for a command negated
# with `!`, and for every command of an `&&` or `||` list except the last
# one. The trap cannot see an undefined call in those places. The re-run
# wrapper reads the message of bash and fails the run at its end.
run_fixture if-condition "if $UNDEFINED_CALL; then echo yes; fi
while $UNDEFINED_CALL; do echo again; done
! $UNDEFINED_CALL
$UNDEFINED_CALL && echo and
$UNDEFINED_CALL || echo handled"
assert_caught_at_end "an undefined call in a condition, after !, or in an && or || list is caught at the end"

# Limit 3 of the guard file. A plain assignment `x=$(undefined call)` gives
# exit code 127 to the script, and the trap stops the script. Inside
# `x=$(check)`, with the undefined call in the middle of the body of `check`,
# the trap runs in the subshell. It prints its message and ends the subshell
# only. The script sees exit code 1 and continues. The re-run wrapper fails
# the run at its end.
run_fixture plain-assignment "captured=\$($UNDEFINED_CALL)"
assert_stopped "an undefined call that is alone in a plain assignment x=\$(...) stops the script"

run_fixture command-substitution "check() {
  echo before
  $UNDEFINED_CALL
  echo after
}
captured=\$(check)"
assert_caught_at_end "an undefined call inside \$(...) in the body of a function is caught at the end"

# Limit 2 of the guard file (row 68 of the orchestration issues). While a
# function runs as the condition of an `if`, or as a part of an `&&` or `||`
# list, bash runs no ERR trap for ANY command in the body of that function.
# `set -E` does not change this. The re-run wrapper fails the run at its end.
run_fixture function-as-condition "helper() {
  local value=1
  $UNDEFINED_CALL
  [ \"\$value\" -eq 1 ]
}
if helper; then echo yes; fi
helper && echo and
helper || echo or"
assert_caught_at_end "an undefined call in the body of a function that runs as a condition is caught at the end"

# One fixture for each form that calls a function in a place where bash runs
# no ERR trap, and for two forms that hide the exit code from the script.
HELPER_WITH_UNDEFINED_CALL="helper() {
  $UNDEFINED_CALL
  echo helper-output
}
ok() { helper; }"
form_number=0
while IFS= read -r form; do
  form_number=$((form_number+1))
  run_fixture "form-$form_number" "$HELPER_WITH_UNDEFINED_CALL
$form"
  assert_caught_at_end "an undefined call in the body of helper is caught at the end: $form"
done <<'FORMS'
if helper; then echo yes; fi
helper && echo and
for item in 1; do helper || continue; done
if ! helper; then echo no; fi
if helper | grep -q helper-output; then echo yes; fi
[ 1 -eq 1 ] && ok || echo bad
captured=$(helper)
helper | grep -q helper-output
FORMS

# Limit 4 of the guard file. When the undefined call is the only command of
# a command substitution that is an argument of another command, the trap
# prints nothing and the script continues. The re-run wrapper fails the run at
# its end.
run_fixture substitution-as-argument "show() { echo \"value=[\$1]\"; }
show \"\$($UNDEFINED_CALL)\"
in_local() { local value=\"\$($UNDEFINED_CALL)\"; echo \"local=[\$value]\"; }
in_local"
assert_caught_at_end "an undefined call that is alone in \$(...) as an argument or after local is caught at the end"

# This check records known limit 6 of the guard file. The guard reads the
# exit code only. It cannot tell a command that was not found from a command
# that gives exit code 127 on purpose.
run_fixture code-127-on-purpose "gives_127() { return 127; }
gives_127"
assert_stopped "known limit: a command that gives exit code 127 on purpose also stops the script"

bold "The guard keeps the EXIT trap of a suite"

run_fixture exit-trap "trap 'echo $CLEANUP_RAN' EXIT
$UNDEFINED_CALL"
assert_stopped "an undefined call stops a script that has an EXIT trap"
if out_has "$CLEANUP_RAN"; then
  pass "the EXIT trap of the script still runs after the guard stops it"
else
  fail "the EXIT trap of the script still runs after the guard stops it (output: $OUT)"
fi

bold "The re-run wrapper keeps the result of a suite that has no undefined call"

STDOUT_TEXT='fixture-standard-output'
STDERR_TEXT='fixture-standard-error'
run_fixture clean "echo $STDOUT_TEXT
echo $STDERR_TEXT >&2"
assert_continued "a suite with no undefined call keeps exit code 0"
label="standard output and standard error of the suite stay two separate streams"
if [ "$(fixture_bash "$SCRIPT" 2>/dev/null)" = "$STDOUT_TEXT
$REACHED_END" ] && [ "$(fixture_bash "$SCRIPT" 2>&1 >/dev/null)" = "$STDERR_TEXT" ]; then
  pass "$label"
else
  fail "$label"
fi

run_fixture exit-code-3 "exit 3"
assert_exit_code 3 "a suite that ends with exit code 3 keeps exit code 3"

# The wrapper reads only the message form of bash: `<script>: line <number>:
# <command>: command not found`. A check may print the bare words.
run_fixture bare-words "echo 'command not found' >&2
echo 'the tool said: command not found' >&2"
assert_continued "the bare words 'command not found' on standard error do not fail the suite"

bold "The re-run wrapper starts only for a suite that bash runs as a script"

# A suite that another script loads with `source`: the wrapper must not run
# the other script again. Every line of the other script must run one time.
OUTER_START='outer-script-started'
run_fixture sourced-suite "echo body-of-the-sourced-suite"
printf 'echo %s\nsource "%s"\n' "$OUTER_START" "$SCRIPT" > "$WORK/outer.sh"
CODE=0
OUT="$(fixture_bash "$WORK/outer.sh" 2>&1)" || CODE=$?
label="a suite loaded with source from another script runs one time, with its body"
if [ "$CODE" -eq 0 ] && [ "$(printf '%s\n' "$OUT" | grep -cF -- "$OUTER_START")" -eq 1 ] \
   && [ "$(printf '%s\n' "$OUT" | grep -cF -- "$REACHED_END")" -eq 1 ]; then
  pass "$label"
else
  fail "$label (exit code $CODE, output: $OUT)"
fi
# With `bash -c`, $0 is the word bash. A wrapper that starts here runs
# `bash bash` (measured: exit code 126, "cannot execute binary file").
CODE=0
OUT="$(fixture_bash -c "source \"$SCRIPT\"" 2>&1)" || CODE=$?
assert_continued "a suite loaded with source from bash -c runs its body"

bold "The re-run wrapper removes its log file"

# The log file must be under $TMPDIR. The fixture lists $TMPDIR while the log
# file exists, and this suite lists it again after the run.
LOG_DIR="$WORK/log-dir"
mkdir "$LOG_DIR"
TMPDIR="$LOG_DIR" run_fixture log-file 'echo "log-files=$(ls "$TMPDIR" | wc -l | tr -d " ")"'
label="the log file is created under \$TMPDIR and is removed at a normal exit"
if out_has 'log-files=1' && [ -z "$(ls "$LOG_DIR")" ]; then
  pass "$label"
else
  fail "$label (output: $OUT, files left: $(ls "$LOG_DIR"))"
fi
# Ctrl-C in a terminal sends SIGINT (the interrupt signal) to the wrapper and
# to the child. The fixture sends it to its parent process and to itself.
TMPDIR="$LOG_DIR" run_fixture log-file-sigint 'kill -INT "$PPID" "$$"
sleep 1'
label="the log file is removed after SIGINT, and the exit code is 130"
if [ "$CODE" -eq 130 ] && [ -z "$(ls "$LOG_DIR")" ]; then
  pass "$label"
else
  fail "$label (exit code $CODE, files left: $(ls "$LOG_DIR"))"
fi

bold "The scan finds a line that switches the guard off"

# first_guard_undo_line <file> <line>: print the number of the first line
# after <line> that the scan reads as "this switches the guard off".
#
# What the scan reads as "off", on one line:
# - the word `trap`, and later the word ERR in upper or lower case, with or
#   without quotes (`trap ":" ERR`, `trap - "err"`, `then trap - ERR`,
#   `command trap - ERR`);
# - `set` with an option group that starts with `+` and holds `E`
#   (`set +E`, `set +uE`), or `set +o errtrace`;
# - `shopt` with `-u` and `errtrace`.
# A command word counts when it stands at the start of the line or after a
# space, a tab, `;`, `&`, `|`, `(` or `{`.
# The scan skips comment lines and the text of a here-document.
#
# What the scan cannot see: a command that `eval` runs, a signal name held
# in a variable (`trap - "$sig"`), a line continuation between `trap` and
# ERR, and a file that the suite loads with `source`.
# What the scan finds by mistake: the same words in a string or after a
# command on the same line (`echo "never trap ERR"`, `x=1 # trap - ERR`).
# This gives a false FAIL, never a false PASS.
first_guard_undo_line() {
  awk -v from="$2" '
    # First reading of the file: remember the last line number of every
    # whole line (leading tabs removed). A here-document starts only when
    # its end word stands alone on a later line. Without this rule, the two
    # characters `<<` inside a string would hide the rest of the file.
    NR == FNR {
      line = $0
      sub(/^\t+/, "", line)
      last_line[line] = FNR
      next
    }
    # Second reading. Inside a here-document: skip lines up to the end word.
    end_word != "" {
      line = $0
      if (strip_tabs) sub(/^\t+/, "", line)
      if (line == end_word) end_word = ""
      next
    }
    /^[ \t]*#/ { next }
    {
      # Find the start of a here-document: two `<` characters, not three.
      rest = $0
      gsub(/<<</, "", rest)
      if (match(rest, /<<-?[ \t]*["\047\\]?[A-Za-z_][A-Za-z0-9_]*/)) {
        word = substr(rest, RSTART, RLENGTH)
        strip_tabs = (word ~ /^<<-/)
        sub(/^<<-?[ \t]*["\047\\]?/, "", word)
        if (last_line[word] > FNR) end_word = word
      }
    }
    FNR <= from { next }
    {
      lower = tolower($0)
      if (lower ~ /(^|[ \t;&|({])trap[ \t].*[ \t"\047]err(["\047 \t;)}]|$)/ ||
          $0    ~ /(^|[ \t;&|({])set[ \t]([^#]*[ \t])?\+[A-Za-z]*E/ ||
          lower ~ /(^|[ \t;&|({])set[ \t]([^#]*[ \t])?\+o[ \t]+errtrace/ ||
          (lower ~ /(^|[ \t;&|({])shopt[ \t]/ && lower ~ /[ \t]-[a-z]*u/ && lower ~ /errtrace/)) {
        print FNR
        exit
      }
    }' "$1" "$1"
}

# scan_fixture <text>: write <text> into a fixture file and leave the result
# of the scan in SCAN_LINE (empty when the scan finds nothing).
scan_fixture() {
  printf '%s\n' "$1" > "$WORK/scan-fixture.sh"
  SCAN_LINE="$(first_guard_undo_line "$WORK/scan-fixture.sh" 0)"
}

# Each line of this here-document is one form that switches the guard off on
# bash 3.2 (measured). The scan must find every one of them. The forms stand
# in a here-document because the scan skips here-document text: in any other
# place the scan would find these lines in this file.
while IFS= read -r form; do
  scan_fixture "$form"
  label="the scan finds: $form"
  if [ -n "$SCAN_LINE" ]; then pass "$label"; else fail "$label"; fi
done <<'FORMS'
trap ":" ERR
trap ':' ERR
trap - ERR
trap ":" err
trap - "ERR"
trap - 'ERR'
trap - ERR EXIT
if true; then trap - ERR; fi
for i in 1; do trap - ERR; done
true && trap - ERR
command trap - ERR
builtin trap - ERR
  trap - ERR
set +E
set +uE
set +o errtrace
shopt -u -o errtrace
shopt -uo errtrace
FORMS

# Each line of this here-document is harmless. The scan must find nothing.
while IFS= read -r form; do
  scan_fixture "$form"
  label="the scan does not find: $form"
  if [ -z "$SCAN_LINE" ]; then pass "$label"; else fail "$label (found at line $SCAN_LINE)"; fi
done <<'FORMS'
trap cleanup EXIT
trap 'rm -rf "$WORK"' EXIT INT TERM
trap 'echo "$ERRORS"' EXIT
# trap - ERR
  # set +E
set -E
set +e
set -o errtrace
ERRORS=()
FORMS

# The text of a here-document is data, not commands. \074 is the character
# `<`; it is written this way so that this line does not look like the start
# of a here-document to the scan when the scan reads this file.
printf 'cat \074\074TEXT\ntrap - ERR\nTEXT\necho done\n' > "$WORK/scan-fixture.sh"
label="the scan does not find a trap line in the text of a here-document"
SCAN_LINE="$(first_guard_undo_line "$WORK/scan-fixture.sh" 0)"
if [ -z "$SCAN_LINE" ]; then pass "$label"; else fail "$label (found at line $SCAN_LINE)"; fi
printf 'cat \074\074-TEXT\n\ttext\n\tTEXT\ntrap - ERR\n' > "$WORK/scan-fixture.sh"
label="the scan finds a trap line after the end of a here-document"
SCAN_LINE="$(first_guard_undo_line "$WORK/scan-fixture.sh" 0)"
if [ "$SCAN_LINE" = 4 ]; then pass "$label"; else fail "$label (found: '$SCAN_LINE')"; fi
# The two characters `<<` inside a string start no here-document, because
# no later line holds the end word alone. The scan must read on.
printf 'TEXT="cat \074\074WORD and more"\ntrap - ERR\n' > "$WORK/scan-fixture.sh"
label="the scan reads on after two < characters inside a string"
SCAN_LINE="$(first_guard_undo_line "$WORK/scan-fixture.sh" 0)"
if [ "$SCAN_LINE" = 2 ]; then pass "$label"; else fail "$label (found: '$SCAN_LINE')"; fi

bold "Every fast suite loads the guard before its first check"

guarded_count=0
for file in "$ROOT"/tests/*/run-tests.sh; do
  # When the pattern matches no file, bash keeps the pattern itself as one
  # word. That word is not a file and must not be counted.
  [ -f "$file" ] || continue
  suite="$(basename "$(dirname "$file")")"
  case " $UNGUARDED_SUITES " in *" $suite "*) continue ;; esac
  guarded_count=$((guarded_count+1))
  name="tests/$suite/run-tests.sh"
  load_line="$(grep -nE "^(source|\.) .*/$GUARD_NAME\"?\$" "$file" | head -1 | cut -d: -f1)"
  if [ -z "$load_line" ]; then
    fail "$name loads the guard"
    continue
  elif [ "$load_line" -gt "$GUARD_LOAD_MAX_LINE" ]; then
    fail "$name loads the guard in its first $GUARD_LOAD_MAX_LINE lines (found at line $load_line)"
  else
    pass "$name loads the guard at line $load_line"
  fi
  label="$name keeps the guard: the scan finds no line that switches it off"
  undo_line="$(first_guard_undo_line "$file" "$load_line")"
  if [ -z "$undo_line" ]; then
    pass "$label"
  else
    fail "$label (found at line $undo_line)"
  fi
done
if [ "$guarded_count" -ge "$MIN_GUARDED_SUITES" ]; then
  pass "the file pattern tests/*/run-tests.sh found $guarded_count suites that must load the guard"
else
  fail "the file pattern tests/*/run-tests.sh found $guarded_count suites; at least $MIN_GUARDED_SUITES are expected"
fi

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
