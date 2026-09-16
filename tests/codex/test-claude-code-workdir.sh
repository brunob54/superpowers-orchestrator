#!/usr/bin/env bash
# Unit and static test: the behavioural suites under tests/claude-code/ run
# `claude` in a fresh, empty work folder (orchestration issues row 4).
#
# A `claude -p` session started inside the plugin repository loads the
# repository's CLAUDE.md and its workspace files (state.md, session-log.md),
# and a skill that writes into its working directory then writes into the
# developer's clone. The suites therefore run `claude` in a folder made by
# create_claude_workdir (tests/claude-code/test-helpers.sh).
#
# Checks:
#   1. Static: every line of a suite that runs `claude -p` (comment and echo
#      lines excluded) starts the call inside a subshell that changes into a
#      work folder variable: `( cd "$CLAUDE_WORKDIR" && ...` (a digit suffix
#      such as CLAUDE_WORKDIR2 is allowed). test-helpers.sh is excluded: its
#      run_claude is checked by behaviour in check 4.
#   2. Static: no file under tests/claude-code/ contains `reset --hard`. The
#      old recovery message told the developer to hard-reset their own clone.
#   3. Unit: create_claude_workdir prints an existing, empty folder whose
#      path is its own physical path (`pwd -P`, symbolic links resolved), and
#      assert_workdir_empty passes on it and fails on a planted file.
#   4. Unit: run_claude runs `claude` in an empty folder that is not the
#      caller's working directory, leaves the caller's working directory
#      unchanged, and removes that folder afterwards. A fake `claude` script
#      on PATH prints its own working directory.
#   5. Unit: cleanup_test_project removes every folder it is given.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUITE_DIR="${REPO_ROOT}/tests/claude-code"
HELPERS_FILE="${SUITE_DIR}/test-helpers.sh"
# shellcheck source=../claude-code/test-helpers.sh
source "${HELPERS_FILE}"

# The text that marks a `claude` run, and the required start of that run.
CLAUDE_CALL='claude -p'
WORKDIR_SUBSHELL_RE='\( cd "\$CLAUDE_WORKDIR[0-9]*" && .*claude -p'
PLANTED_NAME="planted"

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# has_function <name>: return 0 when test-helpers.sh defines <name>.
has_function() {
  if declare -F "$1" >/dev/null; then
    return 0
  fi
  bad "test-helpers.sh defines $1"
  return 1
}

# Folders made by this test, removed on exit.
SCRATCH=()
cleanup_scratch() {
  local d
  for d in "${SCRATCH[@]+"${SCRATCH[@]}"}"; do
    rm -rf "$d"
  done
}
trap cleanup_scratch EXIT

echo "1. every claude -p call in a suite runs in a work folder"
for suite in "${SUITE_DIR}"/*.sh; do
  [ "$suite" = "$HELPERS_FILE" ] && continue
  name="$(basename "$suite")"
  while IFS= read -r numbered; do
    [ -z "$numbered" ] && continue
    line_no="${numbered%%:*}"
    text="${numbered#*:}"
    # Comment lines and echo lines only mention the command.
    if printf '%s\n' "$text" | grep -qE '^[[:space:]]*(#|echo )'; then
      continue
    fi
    if printf '%s\n' "$text" | grep -qE "$WORKDIR_SUBSHELL_RE"; then
      ok "$name:$line_no runs claude in a work folder"
    else
      bad "$name:$line_no runs claude outside a work folder: $text"
    fi
  done <<EOF
$(grep -nF "$CLAUDE_CALL" "$suite" || true)
EOF
done

echo "2. no file under tests/claude-code/ prints a hard reset"
reset_hits="$(grep -rnF 'reset --hard' "$SUITE_DIR" || true)"
if [ -z "$reset_hits" ]; then
  ok "no 'reset --hard' under tests/claude-code/"
else
  bad "'reset --hard' found under tests/claude-code/: $reset_hits"
fi

echo "3. create_claude_workdir and assert_workdir_empty"
if has_function create_claude_workdir && has_function assert_workdir_empty; then
  workdir="$(create_claude_workdir)"
  SCRATCH+=("$workdir")
  if [ -d "$workdir" ]; then ok "the work folder exists"; else bad "the work folder exists ($workdir)"; fi
  if [ -z "$(ls -A "$workdir")" ]; then ok "the work folder is empty"; else bad "the work folder is empty"; fi
  if [ "$workdir" = "$(cd "$workdir" && pwd -P)" ]; then
    ok "the work folder path is its physical path"
  else
    bad "the work folder path is its physical path ($workdir)"
  fi
  if assert_workdir_empty e "$workdir" >/dev/null; then
    ok "assert_workdir_empty passes on an empty folder"
  else
    bad "assert_workdir_empty passes on an empty folder"
  fi
  touch "$workdir/$PLANTED_NAME"
  set +e
  planted_output="$(assert_workdir_empty e "$workdir")"
  planted_status=$?
  set -e
  if [ "$planted_status" -ne 0 ]; then
    ok "assert_workdir_empty fails on a planted file"
  else
    bad "assert_workdir_empty fails on a planted file"
  fi
  if printf '%s\n' "$planted_output" | grep -qF "$PLANTED_NAME"; then
    ok "the failure output names the planted file"
  else
    bad "the failure output names the planted file: $planted_output"
  fi
fi

echo "4. run_claude runs claude in a fresh empty folder"
fake_bin="$(mktemp -d)"
SCRATCH+=("$fake_bin")
cat > "$fake_bin/claude" <<'EOF'
#!/usr/bin/env bash
# Fake claude: print the working directory and the number of entries in it.
pwd -P
ls -A | wc -l | tr -d ' '
EOF
chmod +x "$fake_bin/claude"
caller_dir="$(pwd -P)"
set +e
run_output="$(PATH="$fake_bin:$PATH" run_claude "hello" 30)"
run_status=$?
set -e
run_dir="$(printf '%s\n' "$run_output" | sed -n 1p)"
run_entries="$(printf '%s\n' "$run_output" | sed -n 2p)"
if [ "$run_status" -eq 0 ]; then ok "run_claude returns 0"; else bad "run_claude returns 0 (got $run_status)"; fi
if [ -n "$run_dir" ] && [ "$run_dir" != "$caller_dir" ]; then
  ok "claude does not run in the caller's working directory"
else
  bad "claude does not run in the caller's working directory (ran in '$run_dir')"
fi
case "$run_dir/" in
  "$REPO_ROOT"/*) bad "claude runs outside the plugin repository (ran in '$run_dir')" ;;
  *) ok "claude runs outside the plugin repository" ;;
esac
if [ "$run_entries" = "0" ]; then ok "the folder is empty when claude starts"; else bad "the folder is empty when claude starts (entries: '$run_entries')"; fi
if [ "$(pwd -P)" = "$caller_dir" ]; then ok "the caller's working directory is unchanged"; else bad "the caller's working directory is unchanged"; fi
if [ -n "$run_dir" ] && [ ! -e "$run_dir" ]; then
  ok "run_claude removes the folder afterwards"
else
  bad "run_claude removes the folder afterwards ('$run_dir')"
fi

echo "5. cleanup_test_project removes every folder it is given"
first_dir="$(mktemp -d)"
second_dir="$(mktemp -d)"
SCRATCH+=("$first_dir" "$second_dir")
cleanup_test_project "$first_dir" "$second_dir"
if [ ! -e "$first_dir" ] && [ ! -e "$second_dir" ]; then
  ok "both folders are removed"
else
  bad "both folders are removed"
fi

echo ""
echo "claude-code work folder: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
