#!/usr/bin/env bash
# /pickup test suite: skills/pickup/scripts/pickup-scan.js on fixture git
# repositories, plus wording assertions on skills/pickup/SKILL.md and
# skills/handoff/SKILL.md. Pure bash, git and node; no claude invocation.
# Windows note: avoids /dev/stdin (not available in Git Bash on Windows).
#
# The first cases are the failure shapes of the design prototype
# (tmp/docs/2026-09-15-pickup-deliberation/pickup-proto/pickup-scan.js):
# it compared against the default branch but not HEAD, used a bare
# --since=<date> (that date at the current time of day), printed
# "commits: 0" outside git, and used origin/main as the merge base.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/skills/pickup/scripts/pickup-scan.js"
PICKUP_SKILL="$ROOT/skills/pickup/SKILL.md"
HANDOFF_SKILL="$ROOT/skills/handoff/SKILL.md"
PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# The scan output is held in $OUT; each line is matched whole with grep -x so
# "commits: 1" never matches "commits: 13".
assert_line() { # desc exact-line
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then ok "$1"; else bad "$1 (no line '$2' in: $(printf '%s' "$OUT" | tr '\n' '|'))"; fi
}
assert_has() { # desc needle
  if printf '%s\n' "$OUT" | grep -qF -- "$2"; then ok "$1"; else bad "$1 (missing '$2' in: $(printf '%s' "$OUT" | tr '\n' '|'))"; fi
}
assert_lacks() { # desc needle
  if printf '%s\n' "$OUT" | grep -qF -- "$2"; then bad "$1 (must not contain '$2': $(printf '%s' "$OUT" | tr '\n' '|'))"; else ok "$1"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else bad "$1 (missing: $3)"; fi
}

# Isolation: the user's global and system git configuration must not change a
# result (for example init.defaultBranch or a commit template). Commit
# identities come from the environment, so no fixture needs a config write.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

# pwd -P resolves macOS's /var -> /private/var symbolic link.
TMP=$(mktemp -d)
: "${TMP:?mktemp failed — refusing to run with an empty fixture path}"
TMP=$(cd "$TMP" && pwd -P)
trap 'rm -rf "$TMP"' EXIT
# Git must never find a repository above a fixture directory.
export GIT_CEILING_DIRECTORIES="$TMP"

# Local dates, computed by node so the suite does not depend on BSD or GNU date.
TODAY=$(node -e 'const d=new Date();const p=(n)=>String(n).padStart(2,"0");console.log(`${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())}`)')
YESTERDAY=$(node -e 'const d=new Date(Date.now()-864e5);const p=(n)=>String(n).padStart(2,"0");console.log(`${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())}`)')
LOG_ROOT="docs/superpowers-orchestrator"

# new_repo <name> <branch>: an empty repository whose unborn branch is <branch>.
new_repo() {
  local dir="$TMP/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q 2>/dev/null
  git -C "$dir" symbolic-ref HEAD "refs/heads/$2"
  printf '%s\n' "$dir"
}
# commit <dir> <subject> [date]: one commit that appends a line to file.txt.
commit() {
  local date="${3:-${YESTERDAY}T12:00:00}"
  printf '%s\n' "$2" >> "$1/file.txt"
  git -C "$1" add file.txt
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git -C "$1" commit -q -m "$2"
}
short_head() { git -C "$1" rev-parse --short=7 HEAD; }
# handoff <dir> <file-name> <first-line> [second-line]
handoff() {
  mkdir -p "$1/tmp/docs"
  { printf '%s\n' "$3"; [ -n "${4:-}" ] && printf '%s\n' "$4"; printf '\nNext task text.\n'; } > "$1/tmp/docs/$2"
}
# scan <dir> [args...]: runs the script from <dir>; sets OUT and CODE.
scan() {
  local dir="$1"; shift
  OUT=$(cd "$dir" && node "$SCRIPT" "$@" 2>&1)
  CODE=$?
}

bold "1. Not a git work tree (prototype printed commits: 0 and exited 0)"
D=$TMP/nogit
mkdir -p "$D"
handoff "$D" "$TODAY-handoff-a.md" "Handoff: written=${TODAY}T09:00 branch=main head=abcdef1"
scan "$D"
assert_eq "exit status is 0" "$CODE" "0"
assert_line "git state is none" "git: none"
assert_line "the handoff is still found" "handoff: tmp/docs/$TODAY-handoff-a.md"
assert_line "staleness is UNKNOWN" "status: UNKNOWN"
assert_lacks "no commit count is printed" "commits:"

bold "2. Repository with no commit"
D=$(new_repo nocommit main)
handoff "$D" "$TODAY-handoff-a.md" "Handoff: written=${TODAY}T09:00 branch=none head=none"
scan "$D"
assert_eq "exit status is 0" "$CODE" "0"
assert_line "git state is no-commits" "git: no-commits"
assert_line "staleness is UNKNOWN" "status: UNKNOWN"
assert_lacks "no commit count is printed" "commits:"

bold "3. Same-day handoffs are ordered by the header time"
D=$(new_repo order main)
commit "$D" "base"
H=$(short_head "$D")
handoff "$D" "$YESTERDAY-handoff-x.md" "Handoff: written=${YESTERDAY}T09:00 branch=main head=$H"
handoff "$D" "$YESTERDAY-handoff-x-2.md" "Handoff: written=${YESTERDAY}T15:00 branch=main head=$H"
# x-2 gets the older modification time, so only the header can pick it.
touch -t 202001010000 "$D/tmp/docs/$YESTERDAY-handoff-x-2.md"
scan "$D"
assert_eq "exit status is 0" "$CODE" "0"
assert_line "x-2 (header 15:00) is chosen over x (header 09:00)" "handoff: tmp/docs/$YESTERDAY-handoff-x-2.md"
assert_line "the header time is printed" "written: ${YESTERDAY}T15:00"

bold "4. A future-dated handoff is skipped"
D=$(new_repo future main)
commit "$D" "base"
H=$(short_head "$D")
handoff "$D" "2999-01-01-handoff-later.md" "Handoff: written=2999-01-01T09:00 branch=main head=$H"
handoff "$D" "$TODAY-handoff-now.md" "Handoff: written=${TODAY}T00:00 branch=main head=$H"
scan "$D"
assert_line "today's handoff is chosen" "handoff: tmp/docs/$TODAY-handoff-now.md"
assert_lacks "the future file is never named" "2999-01-01"

bold "5. No handoff, and a named handoff that is missing"
D=$(new_repo nohandoff main)
commit "$D" "base"
scan "$D"
assert_eq "exit status is 0" "$CODE" "0"
assert_line "handoff is none" "handoff: none"
assert_line "runs are none" "runs: none"
assert_lacks "no staleness without a handoff" "status:"
scan "$D" tmp/docs/2026-01-01-handoff-gone.md
assert_eq "exit status is 0 for a missing path" "$CODE" "0"
assert_line "the missing path is named" "handoff: missing tmp/docs/2026-01-01-handoff-gone.md"

bold "6. FRESH: no commit after the handoff head"
D=$(new_repo fresh main)
commit "$D" "base"
H=$(short_head "$D")
handoff "$D" "$TODAY-handoff-f.md" "Handoff: written=${TODAY}T10:00 branch=main head=$H"
scan "$D"
assert_line "the head is found" "head: $H"
assert_line "zero commits are listed" "commits: 0"
assert_line "status is FRESH" "status: FRESH"

bold "7. CHECK: a commit on an unmerged other branch while HEAD is on the default branch"
D=$(new_repo otherbranch main)
commit "$D" "base"
H=$(short_head "$D")
git -C "$D" checkout -q -b feature/other
commit "$D" "work on the other branch"
git -C "$D" checkout -q main
handoff "$D" "$TODAY-handoff-o.md" "Handoff: written=${TODAY}T10:00 branch=main head=$H" "Done when: row 26 is closed"
scan "$D"
assert_line "the Done when line is printed" "done-when: row 26 is closed"
assert_line "one commit is listed" "commits: 1"
assert_has "the commit subject is listed" "work on the other branch"
assert_has "the commit names its branch" "feature/other"
assert_line "status is CHECK" "status: CHECK"

bold "7b. CHECK: a commit on a detached HEAD (prototype compared the default branch only)"
D=$(new_repo detached main)
commit "$D" "base"
H=$(short_head "$D")
git -C "$D" checkout -q --detach
commit "$D" "work on a detached head"
handoff "$D" "$TODAY-handoff-d.md" "Handoff: written=${TODAY}T10:00 branch=main head=$H"
scan "$D"
assert_line "one commit is listed" "commits: 1"
assert_has "the detached commit is listed" "work on a detached head"
assert_line "status is CHECK" "status: CHECK"

bold "8. Head not found: the date fallback starts at 00:00 (prototype used a bare date)"
D=$(new_repo midnight main)
commit "$D" "yesterday work"
commit "$D" "early today work" "${TODAY}T00:00:01"
handoff "$D" "$TODAY-handoff-m.md" "Handoff: written=${TODAY}T23:00 branch=main head=deadbee"
scan "$D"
assert_eq "exit status is 0" "$CODE" "0"
assert_line "the head is reported not found" "head: not-found"
assert_line "the fallback names midnight" "since: $TODAY 00:00"
assert_line "the earlier same-day commit is counted" "commits: 1"
assert_has "the same-day commit is listed" "early today work"
assert_lacks "yesterday's commit is not listed" "yesterday work"
assert_line "status is CHECK" "status: CHECK"
handoff "$D" "$TODAY-handoff-n.md" "Handoff: written=${TODAY}T23:00 branch=none head=none"
scan "$D" "tmp/docs/$TODAY-handoff-n.md"
assert_line "head=none is reported not found" "head: not-found"
assert_line "head=none also counts the same-day commit" "commits: 1"

bold "9. More than 30 commits: first-parent display, status still CHECK"
D=$(new_repo many main)
commit "$D" "base"
H=$(short_head "$D")
git -C "$D" checkout -q -b side
for i in $(seq 1 31); do commit "$D" "side commit $i"; done
git -C "$D" checkout -q main
git -C "$D" merge -q --no-ff -m "merge the side branch" side
handoff "$D" "$TODAY-handoff-many.md" "Handoff: written=${TODAY}T10:00 branch=main head=$H"
scan "$D"
assert_has "the count is printed" "commits: 31"
assert_has "the first-parent display is announced" "first-parent"
assert_has "the merge commit is listed" "merge the side branch"
assert_lacks "the side commits are not listed" "side commit 17"
assert_line "status is CHECK" "status: CHECK"

bold "10. Runs on unmerged feature branches (default branch master)"
D=$(new_repo runs master)
commit "$D" "base"
git -C "$D" init -q --bare "$TMP/runs-origin.git" 2>/dev/null
git -C "$D" remote add origin "$TMP/runs-origin.git"
git -C "$D" push -q origin master 2>/dev/null
git -C "$D" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
# add_file <dir> <path> <text>: writes and stages one file.
add_file() { mkdir -p "$(dirname "$1/$2")"; printf '%b' "$3" > "$1/$2"; git -C "$1" add "$2"; }
LOG_HEAD="# Orchestration Log — %s\n\n_Invocation 1 — 2026-09-01 — branch feature/%s_\n\n## Phase 1 — Plan — DONE — 2026-09-01\n"
# alpha: a stopped run with a plan; also carries an older unfinished beta log.
git -C "$D" checkout -q -b feature/alpha master
add_file "$D" "$LOG_ROOT/2026-09-01-alpha/alpha-orchestration-log.md" "$(printf "$LOG_HEAD" alpha alpha)\n## STOPPED — 2026-09-02 — phase 2 — blocked\nOpen: [I1] escalated (scope) — x\n"
add_file "$D" "$LOG_ROOT/2026-09-01-alpha/plans/alpha.md" "# plan\n"
add_file "$D" "$LOG_ROOT/2026-09-01-alpha/specs/alpha-design.md" "# spec\n"
add_file "$D" "$LOG_ROOT/2026-08-01-beta/beta-orchestration-log.md" "$(printf "$LOG_HEAD" beta beta)"
commit "$D" "alpha run"
# epsilon: stopped in Phase 1, no plan yet.
git -C "$D" checkout -q -b feature/epsilon master
add_file "$D" "$LOG_ROOT/2026-09-04-epsilon/epsilon-orchestration-log.md" "# Orchestration Log — epsilon\n\n## STOPPED — 2026-09-04 — phase 1 — plan writer failed\n"
add_file "$D" "$LOG_ROOT/2026-09-04-epsilon/specs/epsilon-design.md" "# spec\n"
commit "$D" "epsilon run"
# gamma: a completed run.
git -C "$D" checkout -q -b feature/gamma master
add_file "$D" "$LOG_ROOT/2026-09-03-gamma/gamma-orchestration-log.md" "$(printf "$LOG_HEAD" gamma gamma)\n_Completed — 2026-09-03 — HEAD abc1234_\n"
commit "$D" "gamma run"
# delta: unfinished log, merged into local master but not pushed.
git -C "$D" checkout -q -b feature/delta master
add_file "$D" "$LOG_ROOT/2026-09-05-delta/delta-orchestration-log.md" "$(printf "$LOG_HEAD" delta delta)"
commit "$D" "delta run"
git -C "$D" checkout -q master
git -C "$D" merge -q --no-ff -m "merge delta" feature/delta
# A completed alpha log in the working tree must not hide the branch's log.
mkdir -p "$D/$LOG_ROOT/2026-09-01-alpha"
printf '_Completed — 2026-09-09 — HEAD abc1234_\n' > "$D/$LOG_ROOT/2026-09-01-alpha/alpha-orchestration-log.md"
scan "$D"
assert_eq "exit status is 0" "$CODE" "0"
assert_line "the default branch is master" "default-branch: master"
assert_line "two runs are found" "runs: 2"
assert_line "the stopped alpha run is found" "run: feature/alpha"
assert_line "the alpha log path is printed" "  log: $LOG_ROOT/2026-09-01-alpha/alpha-orchestration-log.md"
assert_line "the last heading is printed" "  last: ## STOPPED — 2026-09-02 — phase 2 — blocked"
assert_has "the age of the last commit is printed" "  last-commit: "
assert_line "alpha resumes from its plan" "  resume: $LOG_ROOT/2026-09-01-alpha/plans/alpha.md"
assert_line "epsilon resumes from its spec" "  resume: $LOG_ROOT/2026-09-04-epsilon/specs/epsilon-design.md"
assert_lacks "an older log under another slug is not offered" "beta-orchestration-log"
assert_lacks "a completed run is not offered" "feature/gamma"
assert_lacks "a branch merged locally (origin behind) is not offered" "feature/delta"

bold "11. skills/pickup/SKILL.md wording"
assert_file_contains "name is pickup" "$PICKUP_SKILL" "name: pickup"
assert_file_contains "manual only" "$PICKUP_SKILL" "disable-model-invocation: true"
assert_file_contains "argument hint is quoted" "$PICKUP_SKILL" 'argument-hint: "[handoff path]"'
assert_file_contains "the script is named" "$PICKUP_SKILL" "scripts/pickup-scan.js"
assert_file_contains "the bare trigger sentence" "$PICKUP_SKILL" 'with exactly `Resume orchestration for <path>` and nothing appended'
assert_file_contains "run mode asks once" "$PICKUP_SKILL" "ask once"
assert_file_contains "says why there is no skill-rules entry" "$PICKUP_SKILL" "hooks/skill-rules.json"
LINES=$(grep -c '' "$PICKUP_SKILL" 2>/dev/null || echo 0)
if [ "$LINES" -ge 60 ] && [ "$LINES" -le 80 ]; then ok "SKILL.md has 60-80 lines ($LINES)"; else bad "SKILL.md has 60-80 lines (got $LINES)"; fi

bold "12. skills/handoff/SKILL.md header and guards"
assert_file_contains "the header format" "$HANDOFF_SKILL" 'Handoff: written=<YYYY-MM-DD>T<HH:MM> branch=<name|none> head=<sha7|none>'
assert_file_contains "the optional Done when line" "$HANDOFF_SKILL" 'Done when: <one checkable condition>'
assert_file_contains "the date line carries the time" "$HANDOFF_SKILL" '!`date +%FT%H:%M`'
# Every inline git command must not abort the skill outside git: a command
# whose own exit status reaches the shell ends with "|| echo none"; a pipeline
# ends in another command, whose exit status is the pipeline's, so it only
# needs 2>/dev/null.
GIT_CMDS=$(grep -oE '!`git [^`]*`' "$HANDOFF_SKILL")
if [ -z "$GIT_CMDS" ]; then
  bad "the handoff skill has inline git commands"
else
  unguarded=$(printf '%s\n' "$GIT_CMDS" | grep -vF '2>/dev/null || echo none`' | grep -vF '2>/dev/null |')
  assert_eq "every inline git command is guarded" "$unguarded" ""
fi

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
