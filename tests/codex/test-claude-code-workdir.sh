#!/usr/bin/env bash
# Unit and static test: the behavioural suites under tests/claude-code/ run
# `claude` in a fresh, empty work folder (orchestration issues row 4).
#
# A `claude -p` session started inside the plugin repository loads the
# repository's CLAUDE.md and its workspace files (state.md, session-log.md),
# and a skill that writes into its working directory then writes into the
# developer's clone. The suites therefore run `claude` through
# run_claude_in_workdir, in a work folder made by create_claude_workdir
# (both in tests/claude-code/test-helpers.sh).
#
# Checks:
#   1. Static: no shell script under tests/claude-code/ (subfolders included)
#      except test-helpers.sh runs the `claude` command directly. A "command
#      word" is the word a shell runs as a command: the first word of a
#      command line, or the word after a shell operator (; & | ( { ! and a
#      backquote), after a shell keyword or a command prefix (then, do, if,
#      exec, env, xargs, timeout <duration>, ...), after a variable
#      assignment prefix (FOO=1 claude), or the first word of a `-c` string.
#      Lines ending in a backslash are joined with the next line first, and
#      whole comment lines are skipped. `claude --version` is allowed: it
#      prints a version and starts no session. The same scan also rejects a
#      line that changes into the plugin repository (`cd "$PLUGIN_DIR"` or
#      `cd "$SCRIPT_DIR/../.."`) and later names claude. The scan runs on
#      fixture scripts first: one fixture for each bypass found by the
#      row 4 red-team review (each must be reported), and one fixture of
#      harmless lines that only mention claude (none may be reported).
#   2. Static: no file under tests/claude-code/ contains `reset --hard`. The
#      old recovery message told the developer to hard-reset their own clone.
#   3. Unit: create_claude_workdir prints an existing, empty folder whose
#      path is its own physical path (`pwd -P`, symbolic links resolved). It
#      fails and prints nothing when `mktemp -d` fails, and then run_claude
#      removes nothing.
#   4. Unit: assert_workdir_empty passes on an empty folder, and fails on a
#      planted file, on an empty path, and on a folder that does not exist.
#   5. Unit: run_claude_in_workdir runs `claude` in the work folder, leaves
#      the caller's working directory unchanged, returns claude's exit
#      status, and refuses a folder inside the plugin repository.
#   6. Unit: run_claude runs `claude` in an empty folder outside the
#      repository and removes that folder, after a success and after a
#      failure.
#   7. Unit: cleanup_test_project removes every folder it is given;
#      cleanup_claude_workdir removes a work folder and refuses an empty
#      path, /, the home folder, the current working directory, and a folder
#      inside the plugin repository.
#   8. Static: no shell script under tests/claude-code/ (subfolders
#      included) except test-helpers.sh writes a `claude -p` transcript into
#      the test project. The test project is the fixture git repository that
#      the skill under test inspects: an untracked transcript there makes the
#      working tree not clean, and a skill such as multi-code-review then
#      stops. The rule and its limits are described at the check.
#   9. Unit: create_transcript_dir prints an empty folder outside the plugin
#      repository; finish_transcript_dir removes it after a success (exit
#      status 0) and keeps it and prints its path after a failure.
#
# Every fake command (claude, mktemp, rm) is placed first on PATH, and the
# test stops before the call when the shell does not resolve the command to
# the fake. So a fast unit run never starts a real `claude` session and never
# runs a real `rm` on a refused path.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
SUITE_DIR="${REPO_ROOT}/tests/claude-code"
HELPERS_NAME="test-helpers.sh"
HELPERS_FILE="${SUITE_DIR}/${HELPERS_NAME}"
# shellcheck source=../claude-code/test-helpers.sh
source "${HELPERS_FILE}"

PLANTED_NAME="planted"
FAKE_CLAUDE_STATUS_FAIL=3

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# check <message> <command...>: count a pass when the command succeeds.
check() {
  local message="$1"
  shift
  if "$@"; then ok "$message"; else bad "$message"; fi
}

# is_removed <path...>: return 0 when every path is non-empty and no longer
# exists.
is_removed() {
  local path
  for path in "$@"; do
    [ -n "$path" ] && [ ! -e "$path" ] || return 1
  done
}

# Folders made by this test, removed on exit.
SCRATCH=()
cleanup_scratch() {
  local d
  for d in "${SCRATCH[@]+"${SCRATCH[@]}"}"; do
    command rm -rf "$d"
  done
}
trap cleanup_scratch EXIT

# new_scratch: print a new scratch folder (physical path) that is removed on
# exit. Call it without a command substitution when the caller needs the
# SCRATCH entry: this function stores the path in LAST_SCRATCH.
new_scratch() {
  LAST_SCRATCH="$(cd "$(command mktemp -d)" && pwd -P)"
  SCRATCH+=("$LAST_SCRATCH")
}

# make_fake <bin_dir> <name> <script body>: write an executable fake command.
make_fake() {
  printf '#!/usr/bin/env bash\n%s\n' "$3" > "$1/$2"
  chmod +x "$1/$2"
}

# in_fake_path <bin_dir> <command...>: run the command in a subshell with
# <bin_dir> first on PATH. The assignment to PATH also clears the shell's table
# of remembered command locations; a `PATH=... command` prefix does not, so a
# command already run once (such as rm) would still resolve to the real one.
in_fake_path() (
  PATH="$1:$PATH"
  shift
  "$@"
)

# require_fake <bin_dir> <name>: stop the whole test when <name> does not
# resolve to the fake in <bin_dir> once <bin_dir> is first on PATH.
require_fake() {
  local resolved
  resolved="$(in_fake_path "$1" command -v "$2" || true)"
  if [ "$resolved" != "$1/$2" ]; then
    bad "the fake $2 is found first on PATH (resolved to '$resolved')"
    echo "claude-code work folder: stopped before calling a real $2"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Static scan of shell scripts for direct `claude` calls.
# ---------------------------------------------------------------------------

# Regular expression pieces (POSIX extended syntax). The scanned text of each
# logical line is "<line number>:<text>", so the start of the text follows ":".
SQ="'"
QUOTE="[\"${SQ}]"
LINE_START='^[0-9]+:[[:space:]]*'
OPERATOR='[;&|({!`][[:space:]]*'
NOT_WORD='(^|[^A-Za-z0-9_])'
KEYWORD="${NOT_WORD}(then|do|else|elif|if|while|until|exec|command|eval)[[:space:]]+"
PREFIX_WITH_OPTIONS="${NOT_WORD}(xargs|env|sudo|nohup|time)([[:space:]]+-[^[:space:]]+)*[[:space:]]+"
TIMEOUT_PREFIX="${NOT_WORD}timeout([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^[:space:]]+[[:space:]]+"
ASSIGNMENT_PREFIX="(^|[[:space:]:])[A-Za-z_][A-Za-z0-9_]*=([^[:space:]\"${SQ}]*|\"[^\"]*\"|${SQ}[^${SQ}]*${SQ})[[:space:]]+"
SHELL_STRING='-c[[:space:]]+'
CLAUDE_WORD="${QUOTE}?([^[:space:]\"${SQ}\`;|&()]*/)?claude${QUOTE}?([[:space:]]|[;|&)\`]|\$)"
CLAUDE_COMMAND_RE="(${LINE_START}|${OPERATOR}|${KEYWORD}|${PREFIX_WITH_OPTIONS}|${TIMEOUT_PREFIX}|${ASSIGNMENT_PREFIX}|${SHELL_STRING})${CLAUDE_WORD}"
CD_REPO_RE='cd[[:space:]]+"?\$\{?(PLUGIN_DIR|SCRIPT_DIR\}?/\.\./\.\.)\}?"?.*claude'
# The one allowed form. It is replaced before matching.
CLAUDE_VERSION_RE='claude --version([[:space:]]|\)|$)'
ALLOWED_MARK='ALLOWED_VERSION_QUERY'

# list_shell_scripts <dir>: print every shell script under <dir> (subfolders
# included) except <dir>/test-helpers.sh. A shell script is a file named
# *.sh or a file whose first line is a sh or bash "#!" line.
list_shell_scripts() {
  local dir="$1" file
  find "$dir" -type f | sort | while IFS= read -r file; do
    [ "$file" = "$dir/$HELPERS_NAME" ] && continue
    case "$file" in
      *.sh) printf '%s\n' "$file" ;;
      *) head -n 1 "$file" | grep -qE '^#!.*[/ ](ba)?sh([[:space:]]|$)' && printf '%s\n' "$file" ;;
    esac
    true
  done
}

# logical_lines <file>: print "<first line number>:<text>" for each logical
# line: a line ending in a backslash is joined with the next line, and whole
# comment lines are left out.
logical_lines() {
  awk '
    {
      line = $0
      if (joined == "") {
        first = NR
        if (line ~ /^[ \t]*#/) next
      }
      if (line ~ /\\$/) {
        joined = joined substr(line, 1, length(line) - 1) " "
        next
      }
      print first ":" joined line
      joined = ""
    }
    END { if (joined != "") print first ":" joined }
  ' "$1"
}

# scan_claude_calls <dir>: print "<file>:<line>: <rule>: <text>" for every
# direct claude call and every claude call after a change into the plugin
# repository, in the shell scripts under <dir>.
scan_claude_calls() {
  local file lines
  list_shell_scripts "$1" | while IFS= read -r file; do
    lines="$(logical_lines "$file" | sed -E "s/${CLAUDE_VERSION_RE}/${ALLOWED_MARK}\\1/g")"
    printf '%s\n' "$lines" | grep -E "$CLAUDE_COMMAND_RE" | sed "s|^|$file:direct claude call: |" || true
    printf '%s\n' "$lines" | grep -E "$CD_REPO_RE" | sed "s|^|$file:claude after cd into the repository: |" || true
  done
}

echo "1. no suite script runs the claude command directly"
new_scratch
FIXTURE_DIR="$LAST_SCRATCH"
mkdir -p "$FIXTURE_DIR/sub"
# One fixture per bypass: "<file name>|<script line or lines>".
BYPASS_CASES=(
  'v1-workdir-set-to-repo.sh|CLAUDE_WORKDIR="$PLUGIN_DIR"
( cd "$CLAUDE_WORKDIR" && timeout 10 claude -p "v1" )'
  'v2-second-cd.sh|( cd "$CLAUDE_WORKDIR" && cd "$PLUGIN_DIR" && timeout 10 claude -p "v2" )'
  'v3-print-flag.sh|cd "$PLUGIN_DIR" && timeout 10 claude --print "v3"'
  'v4-continuation-before-p.sh|cd "$PLUGIN_DIR" && timeout 10 claude \
    -p "v4"'
  'v5-pipe-from-echo.sh|echo "v5" | claude -p'
  'v6-two-spaces.sh|cd "$PLUGIN_DIR" && timeout 10 claude  -p "v6"'
  'v7-model-before-p.sh|cd "$PLUGIN_DIR" && timeout 10 claude --model sonnet -p "v7"'
  'sub/v8-subfolder.sh|cd "$PLUGIN_DIR" && claude -p "v8"'
  'v9-claude-on-continuation-line.sh|timeout 10 \
    claude -p "v9"'
  'v10-command-substitution.sh|OUT=$(claude -p "v10")'
  'v11-shell-string.sh|bash -c "claude -p v11"'
  'v12-environment-prefix.sh|FOO=1 claude -p "v12"'
)
HARMLESS_FILE="harmless.sh"
cat > "$FIXTURE_DIR/$HARMLESS_FILE" <<'EOF'
#!/usr/bin/env bash
# cd "$PLUGIN_DIR" && timeout 10 claude -p "only a comment"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$HOME/.claude/hooks-logs"
echo "FAIL(f): the claude run was killed by the 1800s timeout (exit $CLAUDE_STATUS)"
echo "Install Claude Code first: https://code.claude.com"
echo "Claude version: $(claude --version 2>/dev/null || echo 'not found')"
if ! command -v claude &> /dev/null; then
    echo "claude-code tests need the claude command"
fi
CONFIG="/etc/claude-code/managed-settings.json"
run_claude_in_workdir "$CLAUDE_WORKDIR" 10 -p "ask claude to review" \
    --add-dir "$TEST_PROJECT"
EOF
for bypass in "${BYPASS_CASES[@]}"; do
  printf '%s\n' "${bypass#*|}" > "$FIXTURE_DIR/${bypass%%|*}"
done
fixture_report="$(scan_claude_calls "$FIXTURE_DIR")"
for bypass in "${BYPASS_CASES[@]}"; do
  fixture_file="$FIXTURE_DIR/${bypass%%|*}"
  check "the scan reports the bypass ${bypass%%|*}" grep -qF "$fixture_file:" <<EOF
$fixture_report
EOF
done
if grep -F "$FIXTURE_DIR/$HARMLESS_FILE:" <<EOF
$fixture_report
EOF
then
  bad "the scan reports no line of $HARMLESS_FILE (lines that only mention claude)"
else
  ok "the scan reports no line of $HARMLESS_FILE (lines that only mention claude)"
fi

suite_script_count="$(list_shell_scripts "$SUITE_DIR" | wc -l | tr -d ' ')"
check "the scan finds suite scripts under tests/claude-code/ ($suite_script_count)" [ "$suite_script_count" -gt 0 ]
suite_report="$(scan_claude_calls "$SUITE_DIR")"
if [ -z "$suite_report" ]; then
  ok "no suite script outside $HELPERS_NAME runs claude directly"
else
  bad "suite scripts run claude directly:"
  printf '%s\n' "$suite_report"
fi

echo "2. no file under tests/claude-code/ prints a hard reset"
reset_hits="$(grep -rnF 'reset --hard' "$SUITE_DIR" || true)"
if [ -z "$reset_hits" ]; then
  ok "no 'reset --hard' under tests/claude-code/"
else
  bad "'reset --hard' found under tests/claude-code/: $reset_hits"
fi

echo "3. create_claude_workdir"
workdir="$(create_claude_workdir)"
SCRATCH+=("$workdir")
check "the work folder exists" [ -d "$workdir" ]
check "the work folder is empty" [ -z "$(ls -A "$workdir")" ]
check "the work folder path is its physical path" [ "$workdir" = "$(cd "$workdir" && pwd -P)" ]

new_scratch
fake_mktemp_bin="$LAST_SCRATCH"
make_fake "$fake_mktemp_bin" mktemp 'echo "mkdtemp failed: No space left on device" >&2; exit 1'
new_scratch
fake_claude_bin="$LAST_SCRATCH"
FAKE_CLAUDE_LOG="$fake_claude_bin/calls.log"
export FAKE_CLAUDE_LOG
# Fake claude: record the call, print the working directory and the number of
# entries in it, and exit with FAKE_CLAUDE_STATUS (0 when unset).
make_fake "$fake_claude_bin" claude 'echo called >> "$FAKE_CLAUDE_LOG"
pwd -P
ls -A | wc -l | tr -d " "
exit "${FAKE_CLAUDE_STATUS:-0}"'
require_fake "$fake_mktemp_bin" mktemp
require_fake "$fake_claude_bin" claude
new_scratch
victim="$LAST_SCRATCH"
touch "$victim/keep"
set +e
failed_output="$(cd "$victim" && in_fake_path "$fake_mktemp_bin" create_claude_workdir 2>/dev/null)"
failed_status=$?
(cd "$victim" && in_fake_path "$fake_mktemp_bin:$fake_claude_bin" run_claude "x" 5) >/dev/null 2>&1
run_failed_status=$?
set -e
check "create_claude_workdir fails when mktemp fails (status $failed_status)" [ "$failed_status" -ne 0 ]
check "create_claude_workdir prints nothing when mktemp fails" [ -z "$failed_output" ]
check "run_claude fails when mktemp fails (status $run_failed_status)" [ "$run_failed_status" -ne 0 ]
check "run_claude removes nothing from the caller's folder when mktemp fails" [ -f "$victim/keep" ]
check "run_claude does not call claude when mktemp fails" [ ! -e "$FAKE_CLAUDE_LOG" ]

echo "4. assert_workdir_empty"
# assert_status <expected: pass|fail> <message> <arguments...>
assert_status() {
  local expected="$1" message="$2" status
  shift 2
  set +e
  ASSERT_OUTPUT="$(assert_workdir_empty "$@" 2>&1)"
  status=$?
  set -e
  if [ "$expected" = pass ]; then check "$message" [ "$status" -eq 0 ]; else check "$message" [ "$status" -ne 0 ]; fi
}
assert_status pass "passes on an empty folder" e "$workdir"
touch "$workdir/$PLANTED_NAME"
assert_status fail "fails on a planted file" e "$workdir"
check "the failure output names the planted file" grep -qF "$PLANTED_NAME" <<EOF
$ASSERT_OUTPUT
EOF
assert_status fail "fails on an empty path" e ""
new_scratch
missing_dir="$LAST_SCRATCH/missing"
assert_status fail "fails on a folder that does not exist" e "$missing_dir"

echo "5. run_claude_in_workdir"
caller_dir="$(pwd -P)"
new_scratch
call_dir="$LAST_SCRATCH"
set +e
call_output="$(in_fake_path "$fake_claude_bin" run_claude_in_workdir "$call_dir" 30 -p "hello")"
call_status=$?
check "the fake claude was called" [ -s "$FAKE_CLAUDE_LOG" ]
check "claude runs in the work folder" [ "$(printf '%s\n' "$call_output" | sed -n 1p)" = "$call_dir" ]
check "the folder is empty when claude starts" [ "$(printf '%s\n' "$call_output" | sed -n 2p)" = "0" ]
check "run_claude_in_workdir returns 0 after a success (got $call_status)" [ "$call_status" -eq 0 ]
check "the caller's working directory is unchanged" [ "$(pwd -P)" = "$caller_dir" ]
FAKE_CLAUDE_STATUS=$FAKE_CLAUDE_STATUS_FAIL in_fake_path "$fake_claude_bin" run_claude_in_workdir "$call_dir" 30 -p "hello" >/dev/null
call_status=$?
check "run_claude_in_workdir returns claude's exit status (got $call_status)" [ "$call_status" -eq "$FAKE_CLAUDE_STATUS_FAIL" ]
command rm -f "$FAKE_CLAUDE_LOG"
in_fake_path "$fake_claude_bin" run_claude_in_workdir "$REPO_ROOT/tests" 30 -p "hello" >/dev/null 2>&1
call_status=$?
check "run_claude_in_workdir refuses a folder inside the plugin repository" [ "$call_status" -ne 0 ]
check "claude is not called for a folder inside the plugin repository" [ ! -e "$FAKE_CLAUDE_LOG" ]
in_fake_path "$fake_claude_bin" run_claude_in_workdir "" 30 -p "hello" >/dev/null 2>&1
call_status=$?
check "run_claude_in_workdir refuses an empty folder path" [ "$call_status" -ne 0 ]
check "claude is not called for an empty folder path" [ ! -e "$FAKE_CLAUDE_LOG" ]
set -e

echo "6. run_claude runs claude in a fresh empty folder"
# run_fake_claude <exit status>: call run_claude with the fake claude; set
# RUN_STATUS, RUN_DIR (the folder claude ran in) and RUN_ENTRIES.
run_fake_claude() {
  local output
  set +e
  output="$(FAKE_CLAUDE_STATUS="$1" in_fake_path "$fake_claude_bin" run_claude "hello" 30 2>&1)"
  RUN_STATUS=$?
  set -e
  RUN_DIR="$(printf '%s\n' "$output" | sed -n 1p)"
  RUN_ENTRIES="$(printf '%s\n' "$output" | sed -n 2p)"
}
run_fake_claude 0
check "run_claude returns 0 after a success (got $RUN_STATUS)" [ "$RUN_STATUS" -eq 0 ]
check "claude does not run in the caller's working directory ('$RUN_DIR')" [ "${RUN_DIR:-$caller_dir}" != "$caller_dir" ]
case "$RUN_DIR/" in
  "$REPO_ROOT"/*) bad "claude runs outside the plugin repository (ran in '$RUN_DIR')" ;;
  *) ok "claude runs outside the plugin repository" ;;
esac
check "the folder is empty when claude starts (entries: '$RUN_ENTRIES')" [ "$RUN_ENTRIES" = "0" ]
check "the caller's working directory is unchanged" [ "$(pwd -P)" = "$caller_dir" ]
check "run_claude removes the folder after a success ('$RUN_DIR')" is_removed "$RUN_DIR"
run_fake_claude "$FAKE_CLAUDE_STATUS_FAIL"
check "run_claude returns claude's exit status after a failure (got $RUN_STATUS)" [ "$RUN_STATUS" -eq "$FAKE_CLAUDE_STATUS_FAIL" ]
check "run_claude removes the folder after a failure ('$RUN_DIR')" is_removed "$RUN_DIR"

echo "7. cleanup_test_project and cleanup_claude_workdir"
new_scratch
first_dir="$LAST_SCRATCH"
new_scratch
second_dir="$LAST_SCRATCH"
cleanup_test_project "$first_dir" "$second_dir"
check "cleanup_test_project removes both folders" is_removed "$first_dir" "$second_dir"
new_scratch
check "cleanup_claude_workdir removes a work folder" cleanup_claude_workdir "$LAST_SCRATCH"
check "the work folder is gone" is_removed "$LAST_SCRATCH"

new_scratch
fake_rm_bin="$LAST_SCRATCH"
FAKE_RM_LOG="$fake_rm_bin/rm.log"
export FAKE_RM_LOG
make_fake "$fake_rm_bin" rm 'echo "$*" >> "$FAKE_RM_LOG"'
require_fake "$fake_rm_bin" rm
# refuses <label> <path> [folder to run in]: cleanup_claude_workdir must fail
# and must not call rm.
refuses() {
  local status
  set +e
  (cd "${3:-.}" && in_fake_path "$fake_rm_bin" cleanup_claude_workdir "$2") >/dev/null 2>&1
  status=$?
  set -e
  check "cleanup_claude_workdir refuses $1" [ "$status" -ne 0 ]
  check "rm is not called for $1" [ ! -e "$FAKE_RM_LOG" ]
}
refuses "an empty path" ""
refuses "the root folder /" "/"
refuses "the home folder" "$HOME"
refuses "the current working directory" "$victim" "$victim"
refuses "the plugin repository" "$REPO_ROOT"
refuses "a folder inside the plugin repository" "$REPO_ROOT/tests"

echo "8. no suite script writes a transcript into the test project"
# The rule. A line is reported when a path starts with $TEST_PROJECT/ or
# ${TEST_PROJECT}/ (quoted or not) and one of these is true:
#   a. the path is an argument of `tee`. The suites use `tee` only to keep a
#      copy of a session's output, never to build the fixture.
#   b. the path is the target of `>` or `>>` and the file name ends in .txt.
#      Fixture setup writes code and documents (.js, .json, .md), so
#      `cat > "$TEST_PROJECT/sum.js"` stays allowed; a .txt file in the test
#      project is a transcript or a prompt copy.
#   c. the file name contains "output" and ends in .txt, in any use. This
#      catches a transcript path stored in a variable first
#      (OUTPUT_FILE="$TEST_PROJECT/claude-output.txt" ... tee "$OUTPUT_FILE")
#      and later reads or messages that name such a file.
# Limit: a transcript written through a variable whose value has another
# name, or after `cd "$TEST_PROJECT"` with a relative path, is not detected.
# Whole comment lines are skipped, as in check 1.
PROJECT_PATH='"?\$(TEST_PROJECT|\{TEST_PROJECT\})/'
NAME_CHAR='[^[:space:]"'"${SQ}"'/]'
TEE_INTO_PROJECT_RE="${NOT_WORD}tee([[:space:]]+-[^[:space:]]+)*[[:space:]]+${PROJECT_PATH}"
TXT_REDIRECT_INTO_PROJECT_RE=">>?[[:space:]]*${PROJECT_PATH}([^[:space:]\"${SQ}]*/)?${NAME_CHAR}*\.txt"
OUTPUT_TXT_IN_PROJECT_RE="${PROJECT_PATH}([^[:space:]\"${SQ}]*/)?${NAME_CHAR}*output${NAME_CHAR}*\.txt"
TRANSCRIPT_IN_PROJECT_RE="(${TEE_INTO_PROJECT_RE})|(${TXT_REDIRECT_INTO_PROJECT_RE})|(${OUTPUT_TXT_IN_PROJECT_RE})"

# scan_project_transcripts <dir>: print "<file>:<line>:<text>" for every line
# that writes or names a transcript inside the test project.
scan_project_transcripts() {
  local file
  list_shell_scripts "$1" | while IFS= read -r file; do
    logical_lines "$file" | grep -E "$TRANSCRIPT_IN_PROJECT_RE" | sed "s|^|$file:|" || true
  done
}

new_scratch
TRANSCRIPT_FIXTURE_DIR="$LAST_SCRATCH"
mkdir -p "$TRANSCRIPT_FIXTURE_DIR/sub"
TRANSCRIPT_BAD_CASES=(
  't1-tee.sh|run_claude_in_workdir "$CLAUDE_WORKDIR" 10 -p "x" 2>&1 | tee "$TEST_PROJECT/output.txt" || true'
  't2-tee-braces-append.sh|claude_run 2>&1 | tee -a "${TEST_PROJECT}/output-m1.txt"'
  't3-tee-unquoted.sh|claude_run | tee $TEST_PROJECT/log.md'
  't4-redirect-txt.sh|cat > "$TEST_PROJECT/prompt.txt" <<'"'EOF'"'
x
EOF'
  't5-append-txt.sh|claude_run >> "$TEST_PROJECT/notes/run.txt"'
  't6-variable.sh|OUTPUT_FILE="$TEST_PROJECT/claude-output.txt"'
  't7-read.sh|OUT=$(cat "$TEST_PROJECT/output-pretool.txt")'
  'sub/t8-subfolder.sh|claude_run | tee "$TEST_PROJECT/output-pipeline.txt"'
)
TRANSCRIPT_GOOD_FILE="fixture-setup.sh"
cat > "$TRANSCRIPT_FIXTURE_DIR/$TRANSCRIPT_GOOD_FILE" <<'EOF'
#!/usr/bin/env bash
# claude_run | tee "$TEST_PROJECT/output.txt" (only a comment)
cat > "$TEST_PROJECT/sum.js" <<'JS'
module.exports = {};
JS
cat > "${TEST_PROJECT}/docs/spec.md" <<'MD'
# Spec
MD
echo '{}' >> "$TEST_PROJECT/package.json"
MARKER_FILE="$TEST_PROJECT/subagent-hook-test-marker.txt"
run_claude_in_workdir "$CLAUDE_WORKDIR" 10 -p "x" 2>&1 | tee "$TRANSCRIPT_DIR/output.txt"
OUTPUT_FILE="$TRANSCRIPT_DIR/claude-output.txt"
if cd "$TEST_PROJECT" && npm test > /dev/null 2>&1; then echo ok; fi
EOF
for bad_case in "${TRANSCRIPT_BAD_CASES[@]}"; do
  printf '%s\n' "${bad_case#*|}" > "$TRANSCRIPT_FIXTURE_DIR/${bad_case%%|*}"
done
transcript_fixture_report="$(scan_project_transcripts "$TRANSCRIPT_FIXTURE_DIR")"
for bad_case in "${TRANSCRIPT_BAD_CASES[@]}"; do
  check "the scan reports ${bad_case%%|*}" grep -qF "$TRANSCRIPT_FIXTURE_DIR/${bad_case%%|*}:" <<EOF
$transcript_fixture_report
EOF
done
if grep -F "$TRANSCRIPT_FIXTURE_DIR/$TRANSCRIPT_GOOD_FILE:" <<EOF
$transcript_fixture_report
EOF
then
  bad "the scan reports no line of $TRANSCRIPT_GOOD_FILE (fixture setup and transcripts outside the project)"
else
  ok "the scan reports no line of $TRANSCRIPT_GOOD_FILE (fixture setup and transcripts outside the project)"
fi
suite_transcript_report="$(scan_project_transcripts "$SUITE_DIR")"
if [ -z "$suite_transcript_report" ]; then
  ok "no suite script outside $HELPERS_NAME writes a transcript into the test project"
else
  bad "suite scripts write a transcript into the test project:"
  printf '%s\n' "$suite_transcript_report"
fi

echo "9. create_transcript_dir and finish_transcript_dir"
# transcript_dir_or_empty: call create_transcript_dir; print nothing when the
# helper is missing or fails, so the checks below fail instead of the script.
transcript_dir_or_empty() {
  create_transcript_dir 2>/dev/null || true
}
# is_folder <path>: return 0 when <path> is non-empty and an existing folder.
is_folder() {
  [ -n "$1" ] && [ -d "$1" ]
}
kept_dir="$(transcript_dir_or_empty)"
[ -n "$kept_dir" ] && SCRATCH+=("$kept_dir")
check "create_transcript_dir prints an existing folder ('$kept_dir')" is_folder "$kept_dir"
check "the transcript folder is empty" [ -z "$(ls -A "${kept_dir:-/nonexistent}" 2>/dev/null || echo missing)" ]
case "$kept_dir/" in
  "$REPO_ROOT"/*|/) bad "the transcript folder is outside the plugin repository ('$kept_dir')" ;;
  *) ok "the transcript folder is outside the plugin repository" ;;
esac
set +e
kept_output="$(finish_transcript_dir 1 "$kept_dir" 2>&1)"
set -e
check "finish_transcript_dir keeps the folder after a failure" is_folder "$kept_dir"
check "finish_transcript_dir prints the folder path after a failure" grep -qF "${kept_dir:-no folder}" <<EOF
$kept_output
EOF
removed_dir="$(transcript_dir_or_empty)"
[ -n "$removed_dir" ] && SCRATCH+=("$removed_dir")
set +e
finish_transcript_dir 0 "$removed_dir" >/dev/null 2>&1
set -e
check "finish_transcript_dir removes the folder after a success" is_removed "$removed_dir"

echo ""
echo "claude-code work folder: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
