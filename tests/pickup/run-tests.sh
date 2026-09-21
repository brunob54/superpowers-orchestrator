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
# Cases marked "review 1" come from the first review round
# (tmp/docs/2026-09-15-pickup-deliberation/review-fixes.md), and cases marked
# "verification" from the verification round (review-fixes-2.md there).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

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
# The scan output is held in $OUT; assert_line matches a whole line with
# grep -x, so "commits: 31" never matches "commits: 310".
out_dump() { printf '%s' "$OUT" | tr '\n' '|'; }
assert_line() { # desc exact-line
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then ok "$1"; else bad "$1 (no line '$2' in: $(out_dump))"; fi
}
assert_has() { # desc needle
  if printf '%s\n' "$OUT" | grep -qF -- "$2"; then ok "$1"; else bad "$1 (missing '$2' in: $(out_dump))"; fi
}
assert_lacks() { # desc needle
  if printf '%s\n' "$OUT" | grep -qF -- "$2"; then bad "$1 (must not contain '$2': $(out_dump))"; else ok "$1"; fi
}
assert_exit0() { assert_eq "exit status is 0" "$CODE" "0"; }
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else bad "$1 (missing: $3)"; fi
}

# Isolation: the user's global and system git configuration must not change a
# result (for example init.defaultBranch or color.ui). Commit identities come
# from the environment, so no fixture needs a config write.
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

# Fixture times are fixed past dates, so no case depends on the time of day or
# on a daylight-saving change. Only "tomorrow" is relative: it is computed from
# the calendar date that `date +%F` prints, never by subtracting hours.
BEFORE="2026-01-09T12:00:00"   # commits made before the handoff
WRITTEN_DATE="2026-01-10"
WRITTEN="${WRITTEN_DATE}T10:00"  # the handoff's written= value
AFTER="2026-01-10T11:00:00"    # commits made after the handoff
# after_minute <n>: a distinct time after the handoff, so commit order is certain.
after_minute() { printf '2026-01-10T11:%02d:00' "$1"; }
TODAY=$(date +%F)
TOMORROW=$(node -e 'const [y,m,d]=process.argv[1].split("-").map(Number);const t=new Date(y,m-1,d+1);const p=(n)=>String(n).padStart(2,"0");console.log(`${t.getFullYear()}-${p(t.getMonth()+1)}-${p(t.getDate())}`)' "$TODAY")
LOG_ROOT="docs/superpowers-orchestrator"
ESC=$(printf '\033')

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
  local date="${3:-$BEFORE}"
  printf '%s\n' "$2" >> "$1/file.txt"
  git -C "$1" add file.txt
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" git -C "$1" commit -q -m "$2"
}
# base_repo <name> [branch]: a repository with one "base" commit; sets D and H
# (the base commit's short id).
base_repo() {
  D=$(new_repo "$1" "${2:-main}")
  commit "$D" "base"
  H=$(git -C "$D" rev-parse --short=7 HEAD)
}
# header <branch> <head> [written]: the first line /handoff writes.
header() { printf 'Handoff: written=%s branch=%s head=%s' "${3:-$WRITTEN}" "$1" "$2"; }
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
HANDOFF_FILE="$WRITTEN_DATE-handoff-t.md"

bold "1. Not a git work tree (prototype printed commits: 0 and exited 0)"
D=$TMP/nogit
mkdir -p "$D"
handoff "$D" "$HANDOFF_FILE" "$(header main abcdef1)"
scan "$D"
assert_exit0
assert_line "git state is none" "git: none"
assert_line "the handoff is still found" "handoff: tmp/docs/$HANDOFF_FILE"
assert_line "staleness is UNKNOWN" "status: UNKNOWN"
assert_lacks "no commit count is printed" "commits-"

bold "1b. A bare repository is not a work tree (review 1)"
D=$TMP/bare.git
git init -q --bare "$D" 2>/dev/null
scan "$D"
assert_exit0
assert_line "git state is none" "git: none"

bold "2. Repository with no commit"
D=$(new_repo nocommit main)
handoff "$D" "$HANDOFF_FILE" "$(header none none)"
scan "$D"
assert_exit0
assert_line "git state is no-commits" "git: no-commits"
assert_line "staleness is UNKNOWN" "status: UNKNOWN"
assert_lacks "no commit count is printed" "commits-"

bold "3. Same-day handoffs are ordered by the header time"
base_repo order
handoff "$D" "$WRITTEN_DATE-handoff-x.md" "$(header main "$H" "${WRITTEN_DATE}T09:00")"
handoff "$D" "$WRITTEN_DATE-handoff-x-2.md" "$(header main "$H" "${WRITTEN_DATE}T15:00")"
# x-2 gets the older modification time, so only the header can pick it.
touch -t 202001010000 "$D/tmp/docs/$WRITTEN_DATE-handoff-x-2.md"
scan "$D"
assert_exit0
assert_line "x-2 (header 15:00) is chosen over x (header 09:00)" "handoff: tmp/docs/$WRITTEN_DATE-handoff-x-2.md"
assert_line "the header time is printed" "written: ${WRITTEN_DATE}T15:00"

bold "3b. Without a header: file-name date, then modification time (review 1)"
base_repo nohead
for f in 2026-01-05-handoff-p.md 2026-01-06-handoff-q.md 2026-01-06-handoff-r.md; do handoff "$D" "$f" "No header here."; done
touch -t 202001010000 "$D/tmp/docs/2026-01-06-handoff-r.md"
touch -t 202001020000 "$D/tmp/docs/2026-01-05-handoff-p.md"
scan "$D"
assert_line "the newer file-name date wins, and then the newer modification time" "handoff: tmp/docs/2026-01-06-handoff-q.md"
assert_line "a file without a header says so" "header: none"

bold "3c. An invalid written= value is ignored for sorting and for --since (review 1)"
base_repo badwritten
handoff "$D" "2026-01-01-handoff-old.md" "$(header main deadbee 2026-9-1T08:00)"
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "the valid newer handoff wins" "handoff: tmp/docs/$HANDOFF_FILE"
scan "$D" tmp/docs/2026-01-01-handoff-old.md
assert_line "the fallback uses the file-name date" "since: 2026-01-01 00:00"

bold "4. A future-dated handoff is skipped"
base_repo future
handoff "$D" "$TOMORROW-handoff-later.md" "$(header main "$H" "${TOMORROW}T09:00")"
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "the past handoff is chosen" "handoff: tmp/docs/$HANDOFF_FILE"
assert_lacks "the future file is never named" "$TOMORROW"

bold "5. No handoff, a named handoff that is missing, and a path argument"
base_repo nohandoff
scan "$D"
assert_exit0
assert_line "handoff is none" "handoff: none"
assert_line "runs are none" "runs: none"
assert_lacks "no staleness without a handoff" "status:"
scan "$D" tmp/docs/2026-01-01-handoff-gone.md
assert_eq "exit status is 0 for a missing path" "$CODE" "0"
assert_line "the missing path is named" "handoff: missing tmp/docs/2026-01-01-handoff-gone.md"
assert_lacks "a path argument prints no runs line (review 1)" "runs:"

bold "5b. Unreadable entries never stop the scan (review 1)"
base_repo unreadable
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
mkdir -p "$D/tmp/docs/2026-01-12-handoff-dir.md"
ln -s "$TMP/nonexistent" "$D/tmp/docs/2026-01-11-handoff-link.md" 2>/dev/null
handoff "$D" "2026-01-01-handoff-locked.md" "$(header main "$H")"
chmod 000 "$D/tmp/docs/2026-01-01-handoff-locked.md"
scan "$D"
assert_exit0
assert_line "the readable handoff is chosen" "handoff: tmp/docs/$HANDOFF_FILE"
assert_line "the run scan still runs" "runs: none"
scan "$D" tmp/docs
assert_exit0
assert_line "a directory argument is unreadable" "handoff: unreadable tmp/docs"
chmod 644 "$D/tmp/docs/2026-01-01-handoff-locked.md"

bold "6. FRESH: no commit after the handoff head, clean tree, same branch"
base_repo fresh
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "the head is found" "head: $H"
assert_line "the current branch is printed" "current-branch: main"
assert_line "the handoff file itself is not counted as dirty" "dirty: 0"
assert_lacks "the branch does not differ" "branch-differs:"
assert_line "zero commits on HEAD are listed" "commits-self: 0"
assert_line "zero commits on other branches are listed" "commits-other: 0"
assert_line "status is FRESH" "status: FRESH"
mkdir -p "$D/sub"
scan "$D/sub"
assert_line "from a subdirectory the handoff path is relative to the top (verification)" "handoff: tmp/docs/$HANDOFF_FILE"
scan "$D/sub" "tmp/docs/$HANDOFF_FILE"
assert_line "a top-relative argument is found from a subdirectory (verification)" "handoff: tmp/docs/$HANDOFF_FILE"
scan "$D/sub" "../tmp/docs/$HANDOFF_FILE"
assert_line "a directory-relative argument is printed relative to the top (verification)" "handoff: tmp/docs/$HANDOFF_FILE"

bold "6b. Uncommitted work and a different branch make CHECK (review 1)"
base_repo dirty
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
printf 'state\n' > "$D/state.md"
printf 'log\n' > "$D/session-log.md"
scan "$D"
assert_line "state.md and session-log.md, which /handoff writes, are not dirty (verification)" "dirty: 0"
mkdir -p "$D/wip"
for i in 1 2 3; do printf 'work\n' > "$D/wip/$i.txt"; done
scan "$D"
assert_line "an untracked directory counts as one line (verification)" "dirty: 1"
assert_line "zero commits on HEAD are listed" "commits-self: 0"
assert_line "zero commits on other branches are listed" "commits-other: 0"
assert_line "status is CHECK" "status: CHECK"
base_repo otherbranchname
git -C "$D" branch feature/x
handoff "$D" "$HANDOFF_FILE" "$(header feature/x "$H")"
scan "$D"
assert_line "the branch difference is printed" "branch-differs: yes"
assert_line "status is CHECK" "status: CHECK"
base_repo brokenindex
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
printf 'garbage' > "$D/.git/index"
scan "$D"
assert_exit0
assert_line "a failed git status is not listed (verification)" "dirty: not-listed"
assert_line "a failed git status makes CHECK, never UNKNOWN (verification)" "status: CHECK"

bold "6c. An uncommitted work log is not work (skill worklog)"
# add_file is defined in section 10, below this case, so this case writes its
# files with the two helpers below.
# worklog_file <slug>: writes the active work log docs/worklogs/<slug>.md in $D.
worklog_file() {
  mkdir -p "$D/docs/worklogs"
  printf '<!-- Work log: status=active slug=%s created=2026-01-09 -->\n' "$1" > "$D/docs/worklogs/$1.md"
}
# commit_file <path> <date>: commits the file <path> of $D at <date>; sets H
# to the short id of the new commit.
commit_file() {
  git -C "$D" add "$1"
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$D" commit -q -m "$1"
  H=$(git -C "$D" rev-parse --short=7 HEAD)
}
base_repo worklog
worklog_file t
commit_file docs/worklogs/t.md "$BEFORE"
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
printf 'part 1 done\n' >> "$D/docs/worklogs/t.md"
printf 'new\n' > "$D/docs/worklogs/u.md"
scan "$D"
assert_line "a changed and a new file under docs/worklogs are not dirty" "dirty: 0"
assert_line "status stays FRESH" "status: FRESH"
printf 'notes\n' > "$D/docs/notes.md"
scan "$D"
assert_line "a new file elsewhere under docs/ is dirty" "dirty: 1"
assert_line "status is CHECK" "status: CHECK"
# Right after the first /worklog new, before any commit: git reports the
# whole folder as the one line "?? docs/worklogs/". The tracked file
# docs/README.md is needed for that line; without it, git reports "?? docs/".
base_repo worklogfirst
mkdir -p "$D/docs"
printf 'readme\n' > "$D/docs/README.md"
commit_file docs/README.md "$BEFORE"
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
worklog_file w
scan "$D"
assert_line "a new docs/worklogs folder, one untracked line for git, is not dirty" "dirty: 0"
assert_line "status stays FRESH" "status: FRESH"
commit_file docs/worklogs/w.md "$AFTER"
scan "$D"
assert_line "a commit after the handoff that touches only docs/worklogs makes CHECK" "status: CHECK"

bold "7. CHECK: a commit on an unmerged other branch while HEAD is on the default branch"
base_repo otherbranch
git -C "$D" checkout -q -b feature/other
commit "$D" "work on the other branch" "$AFTER"
git -C "$D" checkout -q main
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")" "Done when: row 26 is closed"
scan "$D"
assert_line "the Done when line is printed" "done-when: row 26 is closed"
assert_line "one commit on another branch is listed" "commits-other: 1"
assert_line "no commit on HEAD is listed" "commits-self: 0"
assert_has "the commit subject is listed" "work on the other branch"
assert_has "the commit names its branch" "feature/other"
assert_line "status is CHECK" "status: CHECK"

bold "7b. CHECK: a commit on a detached HEAD (prototype compared the default branch only)"
base_repo detached
git -C "$D" checkout -q --detach
commit "$D" "work on a detached head" "$AFTER"
handoff "$D" "$HANDOFF_FILE" "$(header none "$H")"
scan "$D"
assert_line "the current branch is detached" "current-branch: detached"
assert_line "one commit on HEAD is listed" "commits-self: 1"
assert_has "the detached commit is listed" "work on a detached head"
assert_line "status is CHECK" "status: CHECK"

bold "7c. Only commits after the handoff time are listed (review 1)"
base_repo window
git -C "$D" checkout -q -b feature/run
commit "$D" "run work before the handoff" "2026-01-09T15:00:00"
git -C "$D" checkout -q -b feature/later main
commit "$D" "work after the handoff" "$AFTER"
git -C "$D" checkout -q main
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "the window starts at the written time" "since: $WRITTEN_DATE 10:00"
assert_lacks "an unmerged commit made before the handoff is not listed" "run work before the handoff"
assert_has "a commit made after the handoff is listed" "work after the handoff"
assert_line "one commit on another branch is listed" "commits-other: 1"

bold "7d. HEAD's own new commits are listed whatever their date (verification)"
base_repo merged
git -C "$D" checkout -q -b feature/w
commit "$D" "work made before the handoff" "2026-01-09T15:00:00"
git -C "$D" checkout -q main
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
git -C "$D" merge -q --ff-only feature/w
scan "$D"
assert_line "a fast-forward merge of older work is listed on HEAD" "commits-self: 1"
assert_has "the merged commit is listed" "work made before the handoff"
assert_line "status is CHECK" "status: CHECK"
base_repo mergedcommit
git -C "$D" checkout -q -b feature/w
commit "$D" "older branch work" "2026-01-09T15:00:00"
git -C "$D" checkout -q main
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
GIT_COMMITTER_DATE="$AFTER" git -C "$D" merge -q --no-ff -m "merge feature w" feature/w
scan "$D"
assert_line "a merge commit and its older work are listed on HEAD" "commits-self: 2"
assert_has "the merge commit is listed" "merge feature w"

bold "7e. The written= time zone offset is passed to --since (verification)"
base_repo offset
git -C "$D" checkout -q -b feature/zone
commit "$D" "zone work at 08:30 UTC" "2026-01-10T10:30:00+0200"
commit "$D" "zone work at 10:30 UTC" "2026-01-10T11:30:00+0100"
git -C "$D" checkout -q main
handoff "$D" "$HANDOFF_FILE" "$(header main "$H" "${WRITTEN_DATE}T10:00+0000")"
OUT=$(cd "$D" && TZ=Asia/Tokyo node "$SCRIPT" 2>&1)
assert_line "the offset is printed with the window" "since: $WRITTEN_DATE 10:00 +0000"
assert_has "work after 10:00 UTC is listed" "zone work at 10:30 UTC"
assert_lacks "work before 10:00 UTC is not listed" "zone work at 08:30 UTC"

bold "7f. Invalid written= values are ignored (verification)"
base_repo badtimes
for w in "${WRITTEN_DATE}T99:99" "${WRITTEN_DATE}T24:00" "${WRITTEN_DATE}T08:60" "2026-02-30T08:00" "2026-13-01T08:00" "${WRITTEN_DATE}T10:00+1500" "${WRITTEN_DATE}T10:00-1201" "${WRITTEN_DATE}T10:00+0160"; do
  handoff "$D" "$HANDOFF_FILE" "$(header main "$H" "$w")"
  scan "$D" "tmp/docs/$HANDOFF_FILE"
  assert_line "written=$w falls back to the file-name date" "since: $WRITTEN_DATE 00:00"
done
for w in "${WRITTEN_DATE}T10:00-1200" "${WRITTEN_DATE}T10:00+1400" "${WRITTEN_DATE}T23:59"; do
  handoff "$D" "$HANDOFF_FILE" "$(header main "$H" "$w")"
  scan "$D" "tmp/docs/$HANDOFF_FILE"
  assert_has "written=$w is accepted" "since: $WRITTEN_DATE ${w:11:5}"
done
mkdir -p "$D/tmp"
printf '%s\n' "$(header main "$H" bad)" > "$D/tmp/nodate.md"
scan "$D" tmp/nodate.md
assert_line "no valid written= and no file-name date: other branches are not listed" "commits-other: not-listed"
assert_line "no valid written= and no file-name date: status is UNKNOWN" "status: UNKNOWN"

bold "7g. Header parsing: byte-order mark, runs of spaces, a later Done when line (verification)"
base_repo parsing
mkdir -p "$D/tmp/docs"
printf '\357\273\277Handoff: written=%s  branch=main   head=%s\n\nDone when: the parser is fixed\n' "$WRITTEN" "$H" > "$D/tmp/docs/$HANDOFF_FILE"
scan "$D"
assert_line "the header is read after a byte-order mark and runs of spaces" "written: $WRITTEN"
assert_line "Done when is found after a blank line" "done-when: the parser is fixed"

bold "8. Head not found: the date fallback starts at 00:00 (prototype used a bare date)"
D=$(new_repo midnight main)
commit "$D" "previous day work"
commit "$D" "early same-day work" "${WRITTEN_DATE}T00:00:01"
handoff "$D" "$HANDOFF_FILE" "$(header main deadbee "${WRITTEN_DATE}T23:00")"
scan "$D"
assert_exit0
assert_line "the head is reported not found" "head: not-found"
assert_line "the fallback names midnight" "since: $WRITTEN_DATE 00:00"
assert_line "the earlier same-day commit is counted" "commits-self: 1"
assert_has "the same-day commit is listed" "early same-day work"
assert_lacks "the previous day's commit is not listed" "previous day work"
assert_line "status is CHECK" "status: CHECK"
handoff "$D" "$WRITTEN_DATE-handoff-n.md" "$(header none none "${WRITTEN_DATE}T23:00")"
scan "$D" "tmp/docs/$WRITTEN_DATE-handoff-n.md"
assert_line "head=none is reported not found" "head: not-found"
assert_line "head=none also counts the same-day commit" "commits-self: 1"
for bad_head in HEAD main; do
  handoff "$D" "$WRITTEN_DATE-handoff-$bad_head.md" "$(header main "$bad_head" "${WRITTEN_DATE}T23:00")"
  scan "$D" "tmp/docs/$WRITTEN_DATE-handoff-$bad_head.md"
  assert_line "head=$bad_head is not a commit id, so it is not found (review 1)" "head: not-found"
done
mkdir -p "$D/tmp"
printf 'Notes without a header.\n' > "$D/tmp/notes.md"
scan "$D" tmp/notes.md
assert_line "no head and no date: since is none (review 1)" "since: none"
assert_line "no head and no date: status is UNKNOWN (review 1)" "status: UNKNOWN"

bold "9. More than 30 commits: the first 30 and the first-parent list, both capped (review 1)"
base_repo many
git -C "$D" checkout -q -b side
for i in $(seq 1 31); do commit "$D" "side commit $i" "$(after_minute "$i")"; done
git -C "$D" checkout -q main
GIT_COMMITTER_DATE="$(after_minute 40)" git -C "$D" merge -q --no-ff -m "merge the side branch" side
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "the count includes the merge commit" "commits-self: 32"
assert_line "the first 30 are announced" "commits-listed: 30"
assert_has "the oldest side commit is listed" "side commit 1"
assert_lacks "the 31st side commit is not listed" "side commit 31"
assert_line "the first-parent list is counted" "first-parent: 1"
assert_has "the merge commit is listed" "merge the side branch"
assert_line "status is CHECK" "status: CHECK"
base_repo manyunmerged
git -C "$D" checkout -q -b work
for i in $(seq 1 32); do commit "$D" "work commit $i" "$(after_minute "$i")"; done
git -C "$D" checkout -q main
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "work on an unmerged branch is counted" "commits-other: 32"
assert_has "its commits are listed although HEAD does not reach them" "work commit 30"
assert_lacks "the 31st is not listed" "work commit 31"
assert_lacks "no first-parent list for other branches (verification)" "first-parent:"
base_repo manyfirstparent
for i in $(seq 1 31); do commit "$D" "main commit $i" "$(after_minute "$i")"; done
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_line "the first-parent list is counted" "first-parent: 31"
assert_lacks "the first-parent list is capped at 30, oldest first" "main commit 31"

bold "9b. color.ui=always puts no escape codes into the output (review 1)"
base_repo color
git -C "$D" config color.ui always
commit "$D" "colored work" "$AFTER"
handoff "$D" "$HANDOFF_FILE" "$(header main "$H")"
scan "$D"
assert_has "the commit is listed" "colored work"
assert_lacks "no escape code is printed" "$ESC"

bold "10. Runs on unmerged feature branches (default branch master)"
D=$(new_repo runs master)
commit "$D" "base"
git init -q --bare "$TMP/runs-origin.git" 2>/dev/null
git -C "$D" remote add origin "$TMP/runs-origin.git"
git -C "$D" push -q origin master 2>/dev/null
git -C "$D" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
# add_file <dir> <path> <text>: writes and stages one file.
add_file() { mkdir -p "$(dirname "$1/$2")"; printf '%b' "$3" > "$1/$2"; git -C "$1" add "$2"; }
# run_log <slug>: the start of an orchestration log.
run_log() { printf '# Orchestration Log — %s\n\n## Phase 1 — Plan — DONE — 2026-09-01\n' "$1"; }
# alpha: a stopped run with a plan; also carries an older unfinished beta log.
git -C "$D" checkout -q -b feature/alpha master
add_file "$D" "$LOG_ROOT/2026-09-01-alpha/alpha-orchestration-log.md" "$(run_log alpha)\n## STOPPED — 2026-09-02 — phase 2 — blocked\nOpen: [I1] escalated (scope) — x\n"
add_file "$D" "$LOG_ROOT/2026-09-01-alpha/plans/alpha.md" "# plan\n"
add_file "$D" "$LOG_ROOT/2026-09-01-alpha/specs/alpha-design.md" "# spec\n"
add_file "$D" "$LOG_ROOT/2026-08-01-beta/beta-orchestration-log.md" "$(run_log beta)"
commit "$D" "alpha run"
# epsilon: stopped in Phase 1, no plan yet.
git -C "$D" checkout -q -b feature/epsilon master
add_file "$D" "$LOG_ROOT/2026-09-04-epsilon/epsilon-orchestration-log.md" "# Orchestration Log — epsilon\n\n## STOPPED — 2026-09-04 — phase 1 — plan writer failed\n"
add_file "$D" "$LOG_ROOT/2026-09-04-epsilon/specs/epsilon-design.md" "# spec\n"
commit "$D" "epsilon run"
# gamma: a completed run.
git -C "$D" checkout -q -b feature/gamma master
add_file "$D" "$LOG_ROOT/2026-09-03-gamma/gamma-orchestration-log.md" "$(run_log gamma)\n_Completed — 2026-09-03 — HEAD abc1234_\n"
commit "$D" "gamma run"
# zeta: two unfinished logs for one slug (review 1).
git -C "$D" checkout -q -b feature/zeta master
add_file "$D" "$LOG_ROOT/2026-09-06-zeta/zeta-orchestration-log.md" "$(run_log zeta)"
add_file "$D" "$LOG_ROOT/2026-09-07-zeta/zeta-orchestration-log.md" "$(run_log zeta)"
add_file "$D" "$LOG_ROOT/2026-09-07-zeta/plans/zeta.md" "# plan\n"
commit "$D" "zeta runs"
# dup: a completed and a stopped log for one slug (verification).
git -C "$D" checkout -q -b feature/dup master
add_file "$D" "$LOG_ROOT/2026-08-01-dup/dup-orchestration-log.md" "$(run_log dup)\n_Completed — 2026-08-02 — HEAD abc1234_\n"
add_file "$D" "$LOG_ROOT/2026-09-10-dup/dup-orchestration-log.md" "$(run_log dup)\n## STOPPED — 2026-09-10 — phase 2 — x\n"
add_file "$D" "$LOG_ROOT/2026-09-10-dup/plans/dup.md" "# plan\n"
commit "$D" "dup runs"
# delta: unfinished log, merged into local master but not pushed.
git -C "$D" checkout -q -b feature/delta master
add_file "$D" "$LOG_ROOT/2026-09-05-delta/delta-orchestration-log.md" "$(run_log delta)"
commit "$D" "delta run"
git -C "$D" checkout -q master
git -C "$D" merge -q --no-ff -m "merge delta" feature/delta
# A completed alpha log in the working tree must not hide the branch's log.
mkdir -p "$D/$LOG_ROOT/2026-09-01-alpha"
printf '_Completed — 2026-09-09 — HEAD abc1234_\n' > "$D/$LOG_ROOT/2026-09-01-alpha/alpha-orchestration-log.md"
assert_runs() { # the run assertions, shared by the root and the subdirectory scans
  assert_exit0
  assert_line "the default branch is master" "default-branch: master"
  assert_line "four runs are found" "runs: 4"
  assert_line "the stopped alpha run is found" "run: feature/alpha"
  assert_line "the alpha log path is printed" "  log: $LOG_ROOT/2026-09-01-alpha/alpha-orchestration-log.md"
  assert_line "the last heading is printed" "  last: ## STOPPED — 2026-09-02 — phase 2 — blocked"
  assert_has "the age of the last commit is printed" "  last-commit: "
  assert_line "alpha resumes from its plan" "  resume: $LOG_ROOT/2026-09-01-alpha/plans/alpha.md"
  assert_line "epsilon resumes from its spec" "  resume: $LOG_ROOT/2026-09-04-epsilon/specs/epsilon-design.md"
  assert_lacks "an older log under another slug is not offered" "beta-orchestration-log"
  assert_lacks "a completed run is not offered" "feature/gamma"
  assert_lacks "a branch merged locally (origin behind) is not offered" "feature/delta"
}
scan "$D"
assert_runs
assert_line "an ambiguous slug is one run block (review 1)" "run: feature/zeta"
assert_line "it names its first log" "  log: $LOG_ROOT/2026-09-06-zeta/zeta-orchestration-log.md"
assert_line "it names its second log" "  log: $LOG_ROOT/2026-09-07-zeta/zeta-orchestration-log.md"
assert_line "it is marked ambiguous" "  ambiguous: yes"
assert_eq "it has no resume path" "$(printf '%s\n' "$OUT" | sed -n '/^run: feature\/zeta$/,/^run: /p' | grep -c '^  resume: none$')" "1"
assert_eq "a completed log still makes its slug ambiguous (verification)" "$(printf '%s\n' "$OUT" | sed -n '/^run: feature\/dup$/,/^run: /p' | grep -c -e '^  ambiguous: yes$' -e '^  resume: none$')" "2"
bold "10b. Runs from a subdirectory (review 1)"
scan "$D/$LOG_ROOT"
assert_runs

bold "10d. An orchestrator file as the argument is not a handoff (verification)"
DELTA_LOG="$LOG_ROOT/2026-09-05-delta/delta-orchestration-log.md"
scan "$D" "$DELTA_LOG"
assert_exit0
assert_line "an orchestrator file is named as such" "handoff: orchestrator-file $DELTA_LOG"
assert_lacks "no handoff fields are printed" "status:"
scan "$D/$LOG_ROOT" "2026-09-05-delta/delta-orchestration-log.md"
assert_line "from a subdirectory it is named relative to the top" "handoff: orchestrator-file $DELTA_LOG"

bold "10c. Default branch: origin/HEAD first, then unknown (review 1)"
base_repo trunkrepo main
git -C "$D" branch trunk
git -C "$D" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
scan "$D"
assert_line "origin/HEAD's local branch is chosen before main" "default-branch: trunk"
base_repo devrepo dev
scan "$D"
assert_line "no origin/HEAD, main or master: unknown" "default-branch: unknown (no merge filter: every feature branch is scanned)"

bold "11. skills/pickup/SKILL.md wording"
assert_file_contains "name is pickup" "$PICKUP_SKILL" "name: pickup"
assert_file_contains "manual only" "$PICKUP_SKILL" "disable-model-invocation: true"
assert_file_contains "argument hint is quoted" "$PICKUP_SKILL" 'argument-hint: "[handoff path]"'
assert_file_contains "the script is named" "$PICKUP_SKILL" "scripts/pickup-scan.js"
assert_file_contains "the argument is quoted in the command (review 1)" "$PICKUP_SKILL" 'pickup-scan.js" "<argument>"'
assert_file_contains "the bare trigger sentence" "$PICKUP_SKILL" 'with exactly `Resume orchestration for <path>` and nothing appended'
assert_file_contains "run mode asks once" "$PICKUP_SKILL" "ask once"
assert_file_contains "a failed script stops the skill (review 1)" "$PICKUP_SKILL" 'no `git:` line'
assert_file_contains "a Resume line inside a handoff uses run mode (review 1)" "$PICKUP_SKILL" "inside the handoff"
assert_file_contains "unresumable runs need a human look (review 1)" "$PICKUP_SKILL" "needs a human look"
assert_file_contains "an orchestrator file gets the Resume advice (verification)" "$PICKUP_SKILL" '`handoff: orchestrator-file`'
assert_file_contains "a non-path argument shows every resume path (verification)" "$PICKUP_SKILL" 'show every `resume:` path that is not `none`'
assert_file_contains "a Resume line inside a handoff keeps only step 4's rules (verification)" "$PICKUP_SKILL" "ask-once and bare-line rules"
assert_file_contains "says why there is no skill-rules entry" "$PICKUP_SKILL" "hooks/skill-rules.json"
for key in git default-branch handoff 'header: none' written branch done-when current-branch dirty 'dirty: not-listed' branch-differs head since commits-self commits-other commits-listed first-parent status runs run ambiguous resume 'handoff: unreadable' 'handoff: orchestrator-file'; do
  case "$key" in *:*) needle="\`$key" ;; *) needle="\`$key:\`" ;; esac
  assert_file_contains "the key list names $key (review 1)" "$PICKUP_SKILL" "$needle"
done
LINES=$(grep -c '' "$PICKUP_SKILL" 2>/dev/null || echo 0)
if [ "$LINES" -ge 60 ] && [ "$LINES" -le 80 ]; then ok "SKILL.md has 60-80 lines ($LINES)"; else bad "SKILL.md has 60-80 lines (got $LINES)"; fi
WIDE=$(awk 'length > 88 && FNR > 5 { print FNR }' "$PICKUP_SKILL" | tr '\n' ' ')
assert_eq "SKILL.md body lines are at most 88 columns" "$WIDE" ""

bold "12. skills/handoff/SKILL.md header and guards"
assert_file_contains "the header format" "$HANDOFF_SKILL" 'Handoff: written=<YYYY-MM-DD>T<HH:MM><+hhmm> branch=<name|none> head=<short sha|none>'
assert_file_contains "the optional Done when line" "$HANDOFF_SKILL" 'Done when: <one checkable condition>'
assert_file_contains "the date line carries the time and offset (verification)" "$HANDOFF_SKILL" '!`date +%FT%H:%M%z`'
assert_file_contains "a detached HEAD prints none (review 1)" "$HANDOFF_SKILL" '!`git branch --show-current 2>/dev/null | grep . || echo none`'
# Every inline git command must not abort the skill outside git: it ends with
# "|| echo none". The one exception is the uncommitted-file count, a pipeline
# whose exit status is that of its last command, tr, which does not fail.
WC_PIPELINE='!`git status --short 2>/dev/null | wc -l | tr -d '"' '"'`'
GIT_CMDS=$(grep -oE '!`git [^`]*`' "$HANDOFF_SKILL")
if [ -z "$GIT_CMDS" ]; then
  bad "the handoff skill has inline git commands"
else
  unguarded=$(printf '%s\n' "$GIT_CMDS" | grep -vF '|| echo none`' | grep -vxF "$WC_PIPELINE")
  assert_eq "every inline git command is guarded" "$unguarded" ""
fi

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
