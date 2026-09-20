#!/usr/bin/env bash
# Pre-check script test suite (rows 76, 77 and 78 of the orchestration issues).
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
# The words of the skill that end the paragraph of the script.
SCRIPT_AREA_END='do not start the revert at all'
# The opening fence line of the script, with the indent of its list item.
FENCE_OPEN='   ```bash'
SCRIPT_LINE_COUNT=13

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
# A second block near the script would be a second script to run.
assert_count "one fenced bash block stands between those words and the words '$SCRIPT_AREA_END'" \
  "$(awk -v anchor="$SCRIPT_ANCHOR" -v last="$SCRIPT_AREA_END" -v fence="$FENCE_OPEN" '
    index($0, anchor) > 0 { armed = 1 }
    armed && $0 == fence { count++ }
    armed && index($0, last) > 0 { exit }
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
# dirty: change a file that the fix commit does not touch.
dirty() { printf 'u\nunrelated user work\n' > user.txt; }

# check_case <label> <expected> [<hash>] [<locale>]: run the script in the
# current folder with every shell, and compare the result with <expected>.
check_case() {
  local label="$1" expected="$2" hash="${3:-$SHA}" locale="${4:-}" shell out got
  printf '%s\n' "${SCRIPT_TEXT//$SHA_PLACEHOLDER/$hash}" > "$RUN_FILE"
  for shell in "${SHELLS[@]}"; do
    # $shell is not quoted: `zsh -f` must become two words.
    out="$(env ${locale:+LC_ALL=$locale} $shell "$RUN_FILE" 2>&1)"
    if [ -n "$out" ]; then got="$ALARM"; else got="$QUIET"; fi
    if [ "$got" = "$expected" ]; then
      ok "$label [$shell]: $expected"
    else
      bad "$label [$shell]: expected $expected, got $got ($(printf '%s' "$out" | head -n 2 | tr '\n' ';'))"
    fi
  done
}

bold "Names (row 77)"

newrepo plain; printf 'a\n' > plain.txt; mkdir -p sub/dir-1; printf 'a\n' > sub/dir-1/ok_file.v2.txt; fix; dirty
check_case "plain names, and a change in a file that the fix does not touch" "$QUIET"
newrepo wide; mkdir '@types'; printf 'a\n' > 'a+b.ts'; printf 'a\n' > '@types/x.d.ts'; printf 'a\n' > 'k=v.txt'; printf 'a\n' > 'a,b.txt'; fix
check_case "names that hold + @ = and a comma" "$QUIET"
for name in 'café.txt' 'a b.txt' '*.txt' ':x.txt' '=x.txt' '-n.txt'; do
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

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
