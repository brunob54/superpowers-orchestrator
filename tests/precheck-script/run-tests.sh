#!/usr/bin/env bash
# Pre-check script test suite (rows 76 to 80 of the orchestration issues).
# Resume step 3 of skills/orchestrating-development/SKILL.md holds one fixed
# script that the orchestrator runs before it reverts a fix commit. This suite
# takes the script out of the skill file and runs it in fixture repositories,
# once with bash and once with zsh when zsh is installed (`zsh -f`: zsh reads
# no start-up file of the user). Any output of the
# script, on standard output or on standard error, means "do not revert".
# Pure bash + git; no claude invocation.
# Windows note: avoids /dev/stdin (not available in Git Bash on Windows).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

SKILL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/skills/orchestrating-development/SKILL.md"
PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()   { green "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }
skip() { printf '  SKIP: %s\n' "$1"; }

# The two results of one run of the script.
QUIET=quiet
ALARM=alarm
# The text that the orchestrator replaces with the hash of the fix commit.
SHA_PLACEHOLDER='<sha>'
# The words of the skill that stand directly before the script.
SCRIPT_ANCHOR='pre-check script below'
# The opening fence line of the script, with the indent of its list item.
FENCE_OPEN='   ```bash'
SCRIPT_LINE_COUNT=21
# The two lines that the script prints about a later commit (rows 79 and 80).
# The path follows each text.
GONE_AT_HEAD='in the fix commit, not at HEAD: '
FOLDER_AT_HEAD='a folder at HEAD, not in the fix commit: '
# The line that the script prints in a sparse checkout (row 87).
SPARSE_LINE='a sparse checkout'
# The shell option that ends a script at the first command that fails.
ERREXIT_LINE='set -e'
# The words of the skill that stand directly before the revert command, and
# the end of that command.
REVERT_ANCHOR='revert it without a commit of its own'
REVERT_COMMAND_END="revert --no-commit $SHA_PLACEHOLDER"

# All fixtures live under one throwaway folder.
# pwd -P resolves the /var -> /private/var symbolic link of macOS.
WORK=$(mktemp -d)
: "${WORK:?mktemp failed — refusing to run with an empty work folder path}"
WORK=$(cd "$WORK" && pwd -P)
trap 'rm -rf "$WORK"' EXIT
RUN_FILE="$WORK/precheck-run.sh"

bold "The skill holds the pre-check script"

# The script is the first fenced bash block after the anchor words. The block
# stands inside a numbered list item, so every line carries 3 spaces of indent.
SCRIPT_TEXT="$(awk -v anchor="$SCRIPT_ANCHOR" -v fence="$FENCE_OPEN" '
  index($0, anchor) > 0 { armed = 1 }
  armed && !inside && $0 == fence { inside = 1; next }
  inside && $0 == "   ```" { exit }
  inside { sub(/^   /, ""); print }
' "$SKILL")"
if [ -n "$SCRIPT_TEXT" ]; then
  ok "a fenced bash block follows the words '$SCRIPT_ANCHOR'"
else
  bad "a fenced bash block follows the words '$SCRIPT_ANCHOR'"
fi
PLACEHOLDER_LINES="$(printf '%s\n' "$SCRIPT_TEXT" | grep -cF -- "$SHA_PLACEHOLDER")"
if [ "$PLACEHOLDER_LINES" = "1" ]; then
  ok "one line of the script holds $SHA_PLACEHOLDER"
else
  bad "one line of the script holds $SHA_PLACEHOLDER (found on $PLACEHOLDER_LINES lines)"
fi

# assert_count <label> <actual> <expected>
assert_count() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected $3, found $2)"; fi
}
assert_count "the script has $SCRIPT_LINE_COUNT lines" \
  "$(printf '%s\n' "$SCRIPT_TEXT" | grep -c '')" "$SCRIPT_LINE_COUNT"
assert_count "one line of the skill holds the words '$SCRIPT_ANCHOR'" \
  "$(grep -cF -- "$SCRIPT_ANCHOR" "$SKILL")" 1
# A second block anywhere after those words would be a second script to run.
assert_count "one fenced bash block stands after those words" \
  "$(awk -v anchor="$SCRIPT_ANCHOR" -v fence="$FENCE_OPEN" '
    index($0, anchor) > 0 { armed = 1 }
    armed && $0 == fence { count++ }
    END { print count + 0 }' "$SKILL")" 1

SHELLS=(bash)
if command -v zsh >/dev/null 2>&1; then
  SHELLS+=('zsh -f')
else
  skip "zsh is not installed; every case runs with bash only"
fi

# newrepo <name>: make an empty repository with one base commit and enter it.
newrepo() {
  cd "$WORK" && rm -rf "$1" && mkdir "$1" && cd "$1" && git init -q . \
    && git config user.name t && git config user.email t@t \
    && printf 'u\n' > user.txt && git add -A && git commit -qm base
}
# fix: commit everything as the fix commit and keep its hash in SHA.
fix() { git add -A -f && git commit -qm fix && SHA=$(git rev-parse HEAD); }
# add_all: commit everything as an ordinary commit that stands before the fix.
add_all() { git add -A && git commit -qm add; }
# later: commit everything as an ordinary commit that stands after the fix.
later() { add_all; }
# dirty: change a file that the fix commit does not touch.
dirty() { printf 'u\nunrelated user work\n' > user.txt; }

# check_case <label> <expected> [<hash>] [<locale>] [<line>] [<first>]: run the
# script in the current folder with every shell, and compare the result with
# <expected>.
# When <line> is given, the output must also hold <line> as a whole line.
# When <first> is given, it stands as one more line in front of the script.
check_case() {
  local label="$1" expected="$2" hash="${3:-$SHA}" locale="${4:-}" line="${5:-}" first="${6:-}" shell out got
  printf '%s\n' ${first:+"$first"} "${SCRIPT_TEXT//$SHA_PLACEHOLDER/$hash}" > "$RUN_FILE"
  for shell in "${SHELLS[@]}"; do
    # $shell is not quoted: `zsh -f` must become two words.
    out="$(env ${locale:+LC_ALL=$locale} $shell "$RUN_FILE" 2>&1)"
    if [ -n "$out" ]; then got="$ALARM"; else got="$QUIET"; fi
    if [ "$got" = "$expected" ] && { [ -z "$line" ] || printf '%s\n' "$out" | grep -qxF -- "$line"; }; then
      ok "$label [$shell]: $expected"
    else
      bad "$label [$shell]: expected $expected${line:+ with the line <$line>}, got $got ($(printf '%s' "$out" | head -n 2 | tr '\n' ';'))"
    fi
  done
}
# check_alarm_line <label> <line>: the script must print <line> as a whole line.
check_alarm_line() { check_case "$1" "$ALARM" "" "" "$2"; }

bold "Names (row 77)"

newrepo plain; printf 'a\n' > plain.txt; mkdir -p sub/dir-1; printf 'a\n' > sub/dir-1/ok_file.v2.txt; fix; dirty
check_case "plain names, and a change in a file that the fix does not touch" "$QUIET"
newrepo wide; mkdir '@types'; printf 'a\n' > 'a+b.ts'; printf 'a\n' > '@types/x.d.ts'; printf 'a\n' > 'k=v.txt'; printf 'a\n' > 'a,b.txt'; fix
check_case "names that hold + @ = and a comma" "$QUIET"
for name in 'café.txt' 'a b.txt' '*.txt' ':x.txt' '=x.txt' '-n.txt' 'a\b.txt'; do
  newrepo special; printf 'a\n' > "./$name"; fix
  check_case "special name <$name>" "$ALARM"
done
# Measured: a range such as A-Z in the letters list lets this name pass under
# bash 3.2 with a UTF-8 (8-bit Unicode Transformation Format) locale.
for locale in en_US.UTF-8 C; do
  newrepo locale; printf 'a\n' > 'café.txt'; fix
  check_case "special name <café.txt> under LC_ALL=$locale" "$ALARM" "$SHA" "$locale"
done

bold "Local changes"

newrepo unstaged; printf 'a\n' > f.txt; fix; printf 'b\n' >> f.txt
check_case "unstaged change on a listed path" "$ALARM"
newrepo staged; printf 'a\n' > f.txt; fix; printf 'b\n' >> f.txt; git add f.txt
check_case "staged change on a listed path" "$ALARM"
newrepo moved; printf 'a\nb\nc\n' > listed.txt; fix; git mv listed.txt u_moved.txt
check_case "the user's staged rename away from a listed path" "$ALARM"
newrepo rename; printf 'a\nb\nc\n' > a.txt; add_all; git mv a.txt b.txt; fix
check_case "the fix renamed a file, no local change" "$QUIET"
newrepo empty; git commit -q --allow-empty -m fix; SHA=$(git rev-parse HEAD); dirty
check_case "empty fix commit over a changed tree" "$QUIET"
newrepo badhash
check_case "a hash that names no commit" "$ALARM" 0123456789abcdef

# Review round 1, F3 (measured): from a sub-folder the script reads f.txt as
# s/f.txt, finds nothing, and a staged user line ends in the resume commit.
newrepo subfolder; printf 'a\n' > f.txt; mkdir s; printf 'k\n' > s/keep.txt; add_all; printf 'b\n' >> f.txt; fix; printf 'c\n' >> f.txt; git add f.txt; cd s
check_case "staged change on a listed path, the script runs from a sub-folder" "$ALARM"

bold "A file on disk that HEAD does not hold (rows 73 and 78)"

newrepo del; printf 'a\n' > gone.txt; add_all; git rm -q gone.txt; fix
check_case "the fix deleted a file, nothing stands on disk" "$QUIET"
newrepo untr; printf 'a\n' > gone.txt; add_all; git rm -q gone.txt; fix; printf 'mine\n' > gone.txt
check_case "untracked user file on a deleted path" "$ALARM"
newrepo ign; printf 'a\n' > gone.dat; add_all; git rm -q gone.dat; printf '*.dat\n' > .gitignore; fix; printf 'mine\n' > gone.dat
check_case "ignored user file on a deleted path" "$ALARM"
newrepo ignfold; mkdir ig; printf 'a\n' > ig/x.txt; add_all; git rm -q ig/x.txt; printf 'ig/\n' > .gitignore; fix; mkdir -p ig; printf 'mine\n' > ig/x.txt
check_case "ignored user file inside an ignored folder, on a deleted path" "$ALARM"
newrepo ignother; mkdir ig; printf 'a\n' > ig/x.txt; add_all; git rm -q ig/x.txt; printf 'ig/\n' > .gitignore; fix; mkdir -p ig; printf 'mine\n' > ig/other.txt
check_case "ignored folder that holds only another file" "$QUIET"
newrepo oldname; printf 'a\nb\nc\n' > a.dat; add_all; git mv a.dat b.txt; printf '*.dat\n' > .gitignore; fix; printf 'mine\n' > a.dat
check_case "ignored user file on the old name of a renamed file" "$ALARM"

# A file system that ignores case finds q.txt under the name Q.TXT.
cd "$WORK" && printf 'q\n' > q.txt
if [ -e Q.TXT ]; then
  newrepo notes; printf 'a\n' > Notes.txt; add_all; git rm -q Notes.txt; printf 'notes.txt\n' > .gitignore; fix; printf 'mine\n' > notes.txt
  check_case "ignored file notes.txt, the fix deleted Notes.txt" "$ALARM"
  newrepo caseup; printf 'a\n' > old.txt; add_all; git mv old.txt Old.txt; fix
  check_case "the fix renamed old.txt to Old.txt" "$ALARM"
  newrepo casedown; printf 'a\n' > Old.txt; add_all; git mv Old.txt old.txt; fix
  check_case "the fix renamed Old.txt to old.txt" "$ALARM"
  newrepo casedir; mkdir dir; printf 'a\n' > dir/f.txt; add_all; git mv dir tmpd; git mv tmpd Dir; fix
  check_case "the fix renamed the folder dir/ to Dir/" "$ALARM"
else
  skip "this file system respects case; the four letter-case cases did not run"
fi

bold "A parent folder name that is not a folder (row 76)"

newrepo r76; mkdir d; printf 'x\n' > d/x.txt; add_all; git rm -q d/x.txt; printf '/d\n' > .gitignore; fix; printf 'mine\n' > d
check_case "ignored file d, the fix deleted d/x.txt" "$ALARM"
newrepo r76link; mkdir d real; printf 'x\n' > d/x.txt; add_all; git rm -q d/x.txt; printf '/d\n/real\n' > .gitignore; fix; rm -rf d; ln -s real d
check_case "ignored symbolic link d, the fix deleted d/x.txt" "$ALARM"
newrepo r76deep; mkdir -p a/b; printf 'x\n' > a/b/x.txt; printf 'k\n' > a/keep.txt; add_all; git rm -q a/b/x.txt; printf '/a/b\n' > .gitignore; fix; printf 'mine\n' > a/b
check_case "ignored file a/b, the fix deleted a/b/x.txt" "$ALARM"
newrepo r76ok; mkdir d; printf 'x\n' > d/x.txt; printf 'k\n' > d/keep.txt; add_all; git rm -q d/x.txt; printf '*.dat\n' > .gitignore; fix; printf 'j\n' > d/junk.dat
check_case "ordinary folder d that holds an ignored file" "$QUIET"
newrepo tparent; mkdir d; printf 'x\n' > d/x.txt; add_all; git rm -q d/x.txt; printf 'file\n' > d; fix
check_case "the fix replaced the folder d/ by a tracked file d" "$ALARM"

bold "An ignored file under a listed path (review round 1, C1)"

# filetofolder <name>: the fix commit replaces the tracked file d by d/x.txt.
filetofolder() {
  newrepo "$1"; printf 'file\n' > d; printf '*.dat\n' > .gitignore; add_all
  git rm -q d; mkdir d; printf 'x\n' > d/x.txt; fix
}
# Measured: the revert ends with exit code 0 and deletes d/junk.dat.
filetofolder c1; printf 'precious\n' > d/junk.dat
check_case "the fix replaced the file d by d/x.txt, ignored user file d/junk.dat" "$ALARM"
filetofolder c1safe
check_case "the fix replaced the file d by d/x.txt, no user file" "$QUIET"
newrepo subsrc; printf 's\n' > s.txt; add_all; printf 's2\n' > s.txt; git commit -qam s2
newrepo super; git -c protocol.file.allow=always submodule add -q "$WORK/subsrc" sub >/dev/null 2>&1; git commit -qm addsub
( cd sub && git checkout -q HEAD~1 ); fix
check_case "the fix moved a sub-module pointer" "$QUIET"

bold "A later commit changed what stands on a listed path (rows 79 and 80)"

# Measured on git 2.50.1. Row 80: a later commit renamed or deleted a file of
# the fix commit; the revert then changes a file outside the list, or changes
# nothing, and the resume commit, which names the listed paths, fails. Row 79:
# a later commit renamed a folder; git follows the rename and writes a file of
# the revert into the other folder, over an ignored file of the user.
newrepo r80a; printf 'a\nb\nc\n' > a.txt; add_all; printf 'a\nFIX\nc\n' > a.txt; fix; git mv a.txt b.txt; later
check_alarm_line "the fix changed a.txt, a later commit renamed it to b.txt" "${GONE_AT_HEAD}a.txt"
newrepo r80b; printf 'n\n' > n.txt; fix; git rm -q n.txt; later
check_alarm_line "the fix added n.txt, a later commit deleted it" "${GONE_AT_HEAD}n.txt"
newrepo r79; mkdir d; printf 'x\n' > d/ignx.txt; printf 'k\n' > d/k.txt; add_all; git rm -q d/ignx.txt; fix; git mv d e; later
check_alarm_line "the fix deleted d/ignx.txt, a later commit renamed the folder d/ to e/" "${GONE_AT_HEAD}d"
newrepo dirmod; mkdir d; printf 'a\nb\nc\n' > d/m.txt; printf 'k\n' > d/k.txt; add_all; printf 'a\nFIX\nc\n' > d/m.txt; fix; git mv d e; later
check_alarm_line "the fix changed d/m.txt, a later commit renamed the folder d/ to e/" "${GONE_AT_HEAD}d"
# The file inside the new folder holds other content than the file dd held:
# with equal content git reads the later commit as a rename.
newrepo s14; printf 'a\nb\nc\n' > dd; add_all; git rm -q dd; fix; mkdir dd; printf 'other\n' > dd/in.txt; later
check_alarm_line "the fix deleted the file dd, a later commit made the folder dd/" "${FOLDER_AT_HEAD}dd"
newrepo s18; printf 'a\nb\nc\n' > dd; add_all; printf 'a\nFIX\nc\n' > dd; fix; git rm -q dd; mkdir dd; printf 'other\n' > dd/in.txt; later
check_alarm_line "the fix changed the file dd, a later commit made the folder dd/" "${FOLDER_AT_HEAD}dd"
# Equal content: git reads the later commit as a rename. Measured: without an
# alarm the revert command ends with exit code 0 there and stages a change of
# dd/in.txt, a path outside the list.
newrepo s18same; printf 'a\nb\nc\n' > dd; add_all; printf 'a\nFIX\nc\n' > dd; fix; git mv dd tmpname; mkdir dd; git mv tmpname dd/in.txt; later
check_alarm_line "the fix changed the file dd, a later commit moved it to dd/in.txt with equal content" "${FOLDER_AT_HEAD}dd"
# The accepted cost: this revert would succeed and stay inside the list. The
# script still stops it, because it cannot tell a deleted folder from a
# renamed folder.
newrepo dirgone; mkdir d; printf 'x\n' > d/x.txt; printf 'k\n' > d/k.txt; add_all; git rm -q d/x.txt; fix; git rm -rq d; later
check_alarm_line "the fix deleted d/x.txt, a later commit deleted the whole folder d/ (the accepted cost)" "${GONE_AT_HEAD}d"
# The commit that a sub-module entry names is no object of this repository, so
# a read of the object fails; `git rev-parse` reads the entry only.
newrepo subgone; git -c protocol.file.allow=always submodule add -q "$WORK/subsrc" sub >/dev/null 2>&1; fix; git rm -qf sub; later
check_alarm_line "the fix added a sub-module, a later commit removed it" "${GONE_AT_HEAD}sub"

newrepo lastfile; mkdir q; printf 'o\n' > q/only.txt; add_all; git rm -q q/only.txt; fix
check_case "the fix deleted the last file of a top folder" "$QUIET"
newrepo renlater; printf 'a\nb\nc\n' > a.txt; add_all; git mv a.txt r.txt; fix; printf 'a\nb\nLATER\n' > r.txt; later
check_case "the fix renamed a.txt to r.txt, a later commit changed r.txt" "$QUIET"
newrepo partmove; mkdir d; printf 'a\nb\nc\n' > d/a.txt; printf 'k\n' > d/b.txt; add_all; printf 'a\nFIX\nc\n' > d/a.txt; fix; mkdir e; git mv d/b.txt e/b.txt; later
check_case "a later commit moved another file out of d/, and d/ stands at HEAD" "$QUIET"
newrepo dirback; mkdir d; printf 'x\n' > d/x.txt; add_all; git rm -q d/x.txt; fix; mkdir -p d; printf 'o\n' > d/other.txt; later
check_case "the fix deleted the last file of d/, a later commit made d/ again" "$QUIET"
newrepo rootfix; git checkout -q --orphan alone; fix
check_case "the fix commit is a root commit" "$QUIET"

bold "Index bits, a sparse checkout, a deleted nested folder (rows 81, 86, 87)"

# Rows 81, 86 and 87. Measured on git 2.50.1 with bash 3.2 and zsh 5.9.
# Row 81: git does not compare a file that carries the assume-unchanged bit or
# the skip-worktree bit with the disk, so `git status` hides a local change
# there. With the assume-unchanged bit the resume commit committed the hidden
# change of the user, and the undo lost it. With the skip-worktree bit the
# resume commit ended with exit code 0 and left the path out.
# `git ls-files -v` prints the letter h or S for such a path, and H for an
# ordinary path.
# twofiles <name>: the fix commit changes a.txt and then conf.txt.
twofiles() {
  newrepo "$1"; printf '1\n' > a.txt; printf 'v1\n' > conf.txt; add_all
  printf '2\n' > a.txt; printf 'v2\n' > conf.txt; fix
}
twofiles bitassume; git update-index --assume-unchanged conf.txt; printf 'EDIT\n' > conf.txt
check_alarm_line "assume-unchanged bit and a hidden change on a listed path" "h conf.txt"
twofiles bitskip; git update-index --skip-worktree conf.txt
check_alarm_line "skip-worktree bit on a listed path, no change" "S conf.txt"
# Measured: with `grep -v` in place of `sed`, and with `set -e` in front, the
# script ends at the first ordinary path and prints nothing. No output means
# "start the revert", so that form is unsafe. The bit stands on the second path.
twofiles biterrexit; git update-index --assume-unchanged conf.txt; printf 'EDIT\n' > conf.txt
check_case "assume-unchanged bit on the second listed path, '$ERREXIT_LINE' in front of the script" "$ALARM" "" "" "h conf.txt" "$ERREXIT_LINE"

# Row 87: a sparse checkout keeps only a part of the tree on disk. The resume
# commit left a reverted path outside that part out and still ended with exit
# code 0. When the fix deleted an outside path, `git ls-files -v` prints nothing
# for it before the revert, so only the configuration value shows the state.
# sparsebase <name>: two folders, src/ and cfg/, in one base commit.
sparsebase() {
  newrepo "$1"; mkdir src cfg; printf '1\n' > src/a.txt; printf '1\n' > cfg/c.txt; printf 'k\n' > cfg/k.txt; add_all
}
sparsebase sparsemod; printf '2\n' > src/a.txt; printf '2\n' > cfg/c.txt; fix; git sparse-checkout set src
check_alarm_line "sparse checkout in cone mode, the fix changed an outside path" "$SPARSE_LINE"
sparsebase sparsedel; printf '2\n' > src/a.txt; git rm -q cfg/c.txt; fix; git sparse-checkout set --no-cone '/src/'
check_alarm_line "sparse checkout without cone mode, the fix deleted an outside path" "$SPARSE_LINE"
# The accepted cost (the user's decision of 2026-09-21): this revert would be
# complete, and the script still stops it. No fix commit is reverted in a
# sparse checkout.
sparsebase sparsein; printf '2\n' > src/a.txt; fix; git sparse-checkout set src
check_alarm_line "sparse checkout in cone mode, every listed path inside (the accepted cost)" "$SPARSE_LINE"

# Row 86: the fix deleted the last file of a nested folder, so the folder is
# gone from disk. For a missing folder below an existing one, the search for
# untracked files printed a warning on standard error, and the script read
# that warning as an alarm. The script now runs that search only when the
# folder of the path stands on disk.
newrepo nested; mkdir -p d/s; printf 'x\n' > d/s/x.txt; printf 'k\n' > d/k.txt; add_all; git rm -q d/s/x.txt; fix
check_case "the fix deleted d/s/x.txt, d/k.txt stays" "$QUIET"
newrepo nested3; mkdir -p d/s/t; printf 'x\n' > d/s/t/x.txt; printf 'y\n' > d/s/t/y.txt; printf 'k\n' > d/k.txt; add_all; git rm -q d/s/t/x.txt d/s/t/y.txt; fix
check_case "the fix deleted the two files of d/s/t/, d/k.txt stays" "$QUIET"
# These two cases keep an alarm that the new folder test must not remove.
filetofolder untrbelow; printf 'u\n' > d/u.txt
check_alarm_line "the fix replaced the file d by d/x.txt, untracked user file d/u.txt" "?? d/u.txt"
newrepo userdel; mkdir -p d/s; printf '1\n' > d/s/x.txt; printf 'k\n' > d/k.txt; add_all; printf '2\n' > d/s/x.txt; fix; rm -rf d/s
check_alarm_line "the user deleted the folder d/s/ of a changed file" " D d/s/x.txt"

bold "The revert command does not follow a folder rename (row 79)"

# The command is the one back-quoted text that ends in `$REVERT_COMMAND_END`
# and stands after the words of $REVERT_ANCHOR. The prose is wrapped, so the
# search reads the skill as one line.
REVERT_MATCHES="$(tr '\n' ' ' < "$SKILL" | tr -s ' ' | grep -oE -- "$REVERT_ANCHOR \(\`[^\`]*$REVERT_COMMAND_END\`")"
assert_count "one revert command stands after the words '$REVERT_ANCHOR'" \
  "$(printf '%s' "$REVERT_MATCHES" | grep -c '')" 1
REVERT_COMMAND="${REVERT_MATCHES#*\`}"
REVERT_COMMAND="${REVERT_COMMAND%\`}"

# check_revert <label> <name> [<setting>]: build the reverse fixture in the
# folder <name>, run the revert command of the skill there, and check the
# user's ignored file. The fix commit renamed the folder d/ to e/. A later
# commit added the tracked file e/ignnew.txt. The user keeps an ignored file
# d/ignnew.txt. Measured: the plain command follows the rename back, exits 1
# and writes the tracked content over the user's file. With <setting>, the
# configuration of the repository sets merge.directoryRenames to <setting>.
check_revert() {
  local label="$1" name="$2" setting="${3:-}" code
  newrepo "$name"; mkdir d; for f in x y z; do printf 'a\nb\nc\n' > "d/$f.txt"; done
  printf 'ignnew.txt\n' > .gitignore; add_all; git mv d e; fix
  printf 'tracked\n' > e/ignnew.txt; git add -f e/ignnew.txt; git commit -qm later
  mkdir -p d; printf 'mine\n' > d/ignnew.txt
  [ -z "$setting" ] || git config merge.directoryRenames "$setting"
  check_case "$label: the pre-check script" "$QUIET"
  bash -c "${REVERT_COMMAND//$SHA_PLACEHOLDER/$SHA}" >/dev/null 2>&1
  code=$?
  assert_count "$label: the revert command ends with exit code 0" "$code" 0
  assert_count "$label: the user's ignored file keeps its content" "$(cat d/ignnew.txt)" mine
  assert_count "$label: no status line names ignnew.txt" \
    "$(git status --porcelain | grep -cF -- ignnew.txt)" 0
}
check_revert "reverse fixture" reverse
check_revert "reverse fixture, merge.directoryRenames=true" reversetrue true

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
