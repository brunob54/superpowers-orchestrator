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

# This check records known limit 1 of the guard file; it does not describe a
# wanted behaviour. Bash does not run an ERR (error) trap for a command that
# is the condition of an `if` or a `while`, for a command negated with `!`,
# and for every command of an `&&` or `||` list except the last one. The
# guard cannot see an undefined call in those places.
run_fixture if-condition "if $UNDEFINED_CALL; then echo yes; fi
while $UNDEFINED_CALL; do echo again; done
! $UNDEFINED_CALL
$UNDEFINED_CALL && echo and
$UNDEFINED_CALL || echo handled"
assert_continued "known limit: an undefined call in a condition, after !, or in an && or || list is not seen"

# These two checks record known limit 3 of the guard file. A plain
# assignment `x=$(undefined call)` gives exit code 127 to the script, and the
# guard stops the script. Inside `x=$(check)`, with the undefined call in the
# middle of the body of `check`, the guard runs in the subshell. It prints
# its message and ends the subshell only. The script sees exit code 1 and
# continues.
run_fixture plain-assignment "captured=\$($UNDEFINED_CALL)"
assert_stopped "an undefined call that is alone in a plain assignment x=\$(...) stops the script"

run_fixture command-substitution "check() {
  echo before
  $UNDEFINED_CALL
  echo after
}
captured=\$(check)"
label="known limit: an undefined call inside \$(...) prints the message, but the script continues"
if [ "$CODE" -eq 0 ] && out_has "$REACHED_END" && out_has "$MSG_CODE"; then
  pass "$label"
else
  fail "$label (exit code $CODE, output: $OUT)"
fi

# This check records known limit 2 of the guard file. While a function runs
# as the condition of an `if`, or as a part of an `&&` or `||` list, bash
# runs no ERR trap for ANY command in the body of that function. `set -E`
# does not change this. The guard cannot see an undefined call in such a
# body.
run_fixture function-as-condition "helper() {
  local value=1
  $UNDEFINED_CALL
  [ \"\$value\" -eq 1 ]
}
if helper; then echo yes; fi
helper && echo and
helper || echo or"
assert_continued "known limit: an undefined call in the body of a function that runs as a condition is not seen"

# This check records known limit 4 of the guard file. When the undefined
# call is the only command of a command substitution that is an argument of
# another command, the guard prints nothing and the script continues.
run_fixture substitution-as-argument "show() { echo \"value=[\$1]\"; }
show \"\$($UNDEFINED_CALL)\"
in_local() { local value=\"\$($UNDEFINED_CALL)\"; echo \"local=[\$value]\"; }
in_local"
assert_continued "known limit: an undefined call that is alone in \$(...) as an argument or after local is not seen"

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
