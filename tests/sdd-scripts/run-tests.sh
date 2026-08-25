#!/usr/bin/env bash
# SDD workspace-script test suite: sdd-workspace, task-brief, review-package.
# Pure bash + git; no claude invocation.
# Windows note: avoids /dev/stdin (not available in Git Bash on Windows).

set -u

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/skills/subagent-driven-development/scripts"
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
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}
# sdd-workspace's arg-less stderr backstops (scoping line / legacy warning) and
# its archive notices are asserted from $ERRF, not left to scroll past a green
# run. Capture with `2>"$ERRF"` at the call site, then assert here.
#
# Every assertion is exhaustive about the WHOLE captured stream, never just a
# substring of it: capturing stderr would otherwise hide an unexpected new line
# — a future regression's only signal — behind a green run. Each assertion also
# clears the sink, so an assertion whose call site lost its `2>"$ERRF"` reads an
# empty file and fails instead of passing on the previous call's text.
stderr_dump() { tr '\n' '|' < "$ERRF"; }

assert_stderr_eq() {     # desc expected-full-line   (deterministic messages)
  assert_eq "$1" "$(cat "$ERRF")" "$2"
  : > "$ERRF"
}
assert_stderr_one() {    # desc needle   (one line only; for messages with a timestamp)
  if [ "$(grep -c '' < "$ERRF" | tr -d ' ')" = "1" ] && grep -qF -- "$2" "$ERRF"; then
    ok "$1"
  else
    bad "$1 (want exactly one line containing '$2', got: $(stderr_dump))"
  fi
  : > "$ERRF"
}
# Silence assertions cannot tell "captured nothing" from "never captured", so arm
# the sink with a sentinel first: a missing `2>"$ERRF"` leaves it in place and fails.
arm_stderr() { printf 'SENTINEL: stderr was never captured here\n' > "$ERRF"; }
assert_stderr_silent() { # desc
  assert_eq "$1" "$(cat "$ERRF")" ""
  : > "$ERRF"
}

# Fresh throwaway git repo; all tests run inside it.
# pwd -P resolves macOS's /var -> /private/var symlink so path assertions
# match what git rev-parse --show-toplevel prints.
REPO=$(mktemp -d)
: "${REPO:?mktemp failed — refusing to run with an empty repo path}"
REPO=$(cd "$REPO" && pwd -P)
# Stderr sink for the assertions above. Kept outside $REPO so it can never
# appear in a `git status --porcelain` assertion.
ERRF=$(mktemp)
: "${ERRF:?mktemp failed — refusing to run with an empty stderr sink}"
trap 'rm -rf "$REPO" "$ERRF"' EXIT
cd "$REPO"
git init --quiet
git config user.email "test@test"
git config user.name "test"

bold "sdd-workspace"

WS=$("$SCRIPTS/sdd-workspace")
assert_eq "prints workspace path" "$WS" "$REPO/.superpowers/sdd"
[ -d "$WS" ] && ok "workspace directory created" || bad "workspace directory created"
assert_file_contains "self-ignoring gitignore" "$WS/.gitignore" "*"
WS2=$("$SCRIPTS/sdd-workspace")
assert_eq "idempotent second run" "$WS2" "$WS"
git add -A
STATUS=$(git status --porcelain)
assert_eq "workspace invisible to git status" "$STATUS" ""
git reset --quiet

bold "task-brief"

cat > plan.md << 'PLAN'
# Some Plan

## Global Constraints
- constraint one

### Task 1: First thing

Body of task one.

- [ ] Step 1

### Task 2: Second thing

Body of task two.

```text
### Task 9: decoy inside a fence
```

Still task two text.

````markdown
```text
### Task 8: decoy inside nested fences
```
````

Past the nested decoy.

### Task 3: Third thing

Body of task three.
PLAN

arm_stderr
BRIEF=$("$SCRIPTS/task-brief" plan.md 2 2>"$ERRF" | sed 's/^wrote //; s/:.*$//')
assert_stderr_silent "task-brief quiet on an unscoped workspace with no content"
assert_eq "brief path" "$BRIEF" "$REPO/.superpowers/sdd/task-2-brief.md"
assert_file_contains "brief has task 2 heading" "$BRIEF" "### Task 2: Second thing"
assert_file_contains "brief spans past the fenced decoy" "$BRIEF" "Still task two text."
assert_file_contains "fenced decoy heading kept inside brief" "$BRIEF" "### Task 9: decoy inside a fence"
assert_file_contains "brief spans past the nested-fence decoy" "$BRIEF" "Past the nested decoy."
assert_file_contains "nested decoy heading kept inside brief" "$BRIEF" "### Task 8: decoy inside nested fences"
assert_file_not_contains "brief excludes task 1" "$BRIEF" "Body of task one."
assert_file_not_contains "brief excludes task 3" "$BRIEF" "Body of task three."

"$SCRIPTS/task-brief" plan.md 99 2>/dev/null
assert_eq "missing task exits 3" "$?" "3"
"$SCRIPTS/task-brief" nope.md 1 2>/dev/null
assert_eq "missing plan exits 2" "$?" "2"

bold "review-package (range mode)"

echo "base" > base.txt
git add base.txt && git commit --quiet -m "base commit"
BASE=$(git rev-parse HEAD)
echo "alpha" > alpha.txt
git add alpha.txt && git commit --quiet -m "task: add alpha"
echo "beta" > beta.txt
git add beta.txt && git commit --quiet -m "task: add beta"
HEAD_SHA=$(git rev-parse HEAD)

PKG=$("$SCRIPTS/review-package" "$BASE" "$HEAD_SHA" 2>"$ERRF" | sed 's/^wrote //; s/:.*$//')
# Fixture dependency: the legacy warning fires only because the task-brief
# section above wrote task-2-brief.md into $WS, making has_content true.
assert_stderr_eq "review-package surfaces the legacy backstop once the workspace has content" "warning: workspace has content but no plan.ref — a stale ledger from another plan may be present"
EXPECTED_PKG="$REPO/.superpowers/sdd/review-$(git rev-parse --short "$BASE")..$(git rev-parse --short "$HEAD_SHA").diff"
assert_eq "range package path" "$PKG" "$EXPECTED_PKG"
assert_file_contains "range: first commit in list" "$PKG" "task: add alpha"
assert_file_contains "range: second commit in list" "$PKG" "task: add beta"
assert_file_contains "range: stat summary present" "$PKG" "2 files changed"
assert_file_contains "range: alpha hunk present" "$PKG" "+alpha"
assert_file_contains "range: beta hunk present" "$PKG" "+beta"

"$SCRIPTS/review-package" deadbeef "$HEAD_SHA" 2>/dev/null
assert_eq "bad BASE exits 2" "$?" "2"

bold "review-package (--commits mode)"

echo "gamma" > gamma.txt
git add gamma.txt && git commit --quiet -m "task1: add gamma"
C1=$(git rev-parse HEAD)
echo "delta" > delta.txt
git add delta.txt && git commit --quiet -m "task2: add delta (sibling)"
echo "epsilon" > epsilon.txt
git add epsilon.txt && git commit --quiet -m "task1: add epsilon"
C3=$(git rev-parse HEAD)

CPKG=$("$SCRIPTS/review-package" --commits "$C1" "$C3" 2>"$ERRF" | sed 's/^wrote //; s/:.*$//')
assert_stderr_eq "--commits surfaces the legacy backstop too" "warning: workspace has content but no plan.ref — a stale ledger from another plan may be present"
EXPECTED_CPKG="$REPO/.superpowers/sdd/review-commits-$(git rev-parse --short "$C1")..$(git rev-parse --short "$C3").diff"
assert_eq "--commits package path" "$CPKG" "$EXPECTED_CPKG"
assert_file_contains "--commits: first commit present" "$CPKG" "+gamma"
assert_file_contains "--commits: second commit present" "$CPKG" "+epsilon"
assert_file_not_contains "--commits: sibling task's hunk excluded" "$CPKG" "+delta"
assert_file_not_contains "--commits: sibling subject excluded" "$CPKG" "task2: add delta (sibling)"

"$SCRIPTS/review-package" --commits deadbeef 2>/dev/null
assert_eq "--commits bad SHA exits 2" "$?" "2"
"$SCRIPTS/review-package" --commits 2>/dev/null
assert_eq "--commits with no SHAs exits 2" "$?" "2"

bold "sdd-workspace (plan scoping)"

# Legacy pre-fix state: workspace holds briefs/diffs from the sections
# above and no plan.ref. First scoped call must archive it under unknown-*.
# Fixture dependency: task-2-brief.md ("### Task 2: Second thing") comes from
# the task-brief section's plan.md; review-*.diff from the review-package
# sections — editing those sections changes this legacy fixture.
cat > planA.md << 'PLAN'
### Task 1: plan A task
PLAN
echo "old ledger" > "$WS/progress.md"
echo "dot" > "$WS/.hidden-note"
OUT=$("$SCRIPTS/sdd-workspace" planA.md 2>"$ERRF")
assert_stderr_one "first scoping archives the legacy workspace under unknown-*" "archived previous workspace to archive/unknown-"
assert_eq "scoped call prints same path" "$OUT" "$WS"
assert_eq "plan.ref holds repo-relative path" "$(cat "$WS/plan.ref")" "planA.md"
LEGACY=$(ls -d "$WS"/archive/unknown-* 2>/dev/null | head -n 1)
if [ -n "$LEGACY" ]; then ok "legacy content archived under unknown-*"; else bad "legacy content archived under unknown-*"; fi
assert_file_contains "legacy ledger intact in archive" "$LEGACY/progress.md" "old ledger"
assert_file_contains "brief archived intact" "$LEGACY/task-2-brief.md" "### Task 2: Second thing"
if ls "$LEGACY"/review-*.diff > /dev/null 2>&1; then ok "review diffs archived"; else bad "review diffs archived"; fi
assert_file_contains "dotfile archived" "$LEGACY/.hidden-note" "dot"
if [ ! -e "$WS/progress.md" ]; then ok "workspace root fresh after legacy archive"; else bad "workspace root fresh after legacy archive"; fi
if ls "$WS"/task-*-brief.md > /dev/null 2>&1 || ls "$WS"/review-*.diff > /dev/null 2>&1; then bad "workspace root free of briefs/diffs"; else ok "workspace root free of briefs/diffs"; fi
assert_file_contains ".gitignore remains at workspace root after archive" "$WS/.gitignore" "*"
if [ ! -e "$LEGACY/.gitignore" ]; then ok ".gitignore excluded from archive move"; else bad ".gitignore excluded from archive move"; fi
BRIEF2=$("$SCRIPTS/task-brief" plan.md 2 2>"$ERRF" | sed 's/^wrote //; s/:.*$//')
assert_stderr_eq "task-brief surfaces the scoping backstop naming the current plan" "workspace is scoped to plan planA.md"
assert_eq "task-brief path unchanged once workspace is plan-scoped" "$BRIEF2" "$REPO/.superpowers/sdd/task-2-brief.md"
assert_file_contains "task-brief content unchanged once workspace is plan-scoped" "$BRIEF2" "### Task 2: Second thing"

# Resume: same plan via relative, absolute, and subdirectory-relative paths.
echo "ledger A" > "$WS/progress.md"
"$SCRIPTS/sdd-workspace" planA.md > /dev/null
assert_file_contains "relative resume keeps ledger" "$WS/progress.md" "ledger A"
"$SCRIPTS/sdd-workspace" "$REPO/planA.md" > /dev/null
assert_file_contains "absolute resume keeps ledger" "$WS/progress.md" "ledger A"
mkdir -p subdir
(cd subdir && "$SCRIPTS/sdd-workspace" ../planA.md > /dev/null)
assert_file_contains "subdir-relative resume keeps ledger" "$WS/progress.md" "ledger A"
assert_eq "resume created no new archives" "$(ls "$WS/archive" | wc -l | tr -d ' ')" "1"

# Switch to plan B: A's workspace archived intact under its slug.
cat > planB.md << 'PLAN'
### Task 1: plan B task
PLAN
"$SCRIPTS/sdd-workspace" planB.md > /dev/null 2>"$ERRF"
assert_stderr_eq "plan switch names the archive slug it wrote" "archived previous workspace to archive/planA"
assert_eq "plan.ref switched to plan B" "$(cat "$WS/plan.ref")" "planB.md"
assert_file_contains "plan A ledger archived intact" "$WS/archive/planA/progress.md" "ledger A"
assert_file_contains "archived workspace keeps its plan.ref" "$WS/archive/planA/plan.ref" "planA.md"

# Empty plan.ref = crash-during-write recovery state -> legacy rule.
echo "ledger B" > "$WS/progress.md"
: > "$WS/plan.ref"
"$SCRIPTS/sdd-workspace" planA.md > /dev/null 2>"$ERRF"
assert_stderr_one "empty-ref recovery archives under unknown-*" "archived previous workspace to archive/unknown-"
assert_eq "plan.ref rewritten after empty-ref recovery" "$(cat "$WS/plan.ref")" "planA.md"
assert_eq "empty-ref content archived under unknown-*" "$(ls -d "$WS"/archive/unknown-* | wc -l | tr -d ' ')" "2"
NEW_UNKNOWN=$(ls -d "$WS"/archive/unknown-* | sort | tail -n 1)
assert_file_contains "empty-ref ledger archived intact (not dropped/truncated)" "$NEW_UNKNOWN/progress.md" "ledger B"
if [ ! -e "$WS/progress.md" ]; then ok "workspace root fresh after empty-ref archive"; else bad "workspace root fresh after empty-ref archive"; fi

# Slug collision: archive/planA already exists; archiving plan A's
# workspace again must land in planA-2.
echo "ledger A2" > "$WS/progress.md"
"$SCRIPTS/sdd-workspace" planB.md > /dev/null 2>"$ERRF"
assert_stderr_eq "collision notice names the suffixed slug" "archived previous workspace to archive/planA-2"
assert_file_contains "collision archive suffixed" "$WS/archive/planA-2/progress.md" "ledger A2"

# Out-of-repo plan: absolute physical identity, stable across calls.
EXT=$(mktemp -d)
EXT=$(cd "$EXT" && pwd -P)
: "${EXT:?mktemp -d failed — refusing to operate on absolute root paths}"
EXT_PLAN="$EXT/ext-plan.md"
cat > "$EXT/ext-plan.md" << 'PLAN'
### Task 1: external plan task
PLAN
"$SCRIPTS/sdd-workspace" "$EXT/ext-plan.md" > /dev/null 2>"$ERRF"
assert_stderr_eq "out-of-repo scoping archives the previous plan" "archived previous workspace to archive/planB"
assert_eq "out-of-repo plan.ref is absolute" "$(cat "$WS/plan.ref")" "$EXT/ext-plan.md"
echo "ext ledger" > "$WS/progress.md"
arm_stderr
"$SCRIPTS/sdd-workspace" "$EXT/ext-plan.md" > /dev/null 2>"$ERRF"
assert_stderr_silent "out-of-repo resume archives nothing and stays quiet"
assert_file_contains "out-of-repo resume keeps ledger" "$WS/progress.md" "ext ledger"
rm -rf "$EXT"

# Errors and arg-less stderr backstops (stdout must stay one path line).
"$SCRIPTS/sdd-workspace" nope.md 2>/dev/null
assert_eq "missing plan exits 2" "$?" "2"
ERR=$("$SCRIPTS/sdd-workspace" 2>&1 > /dev/null)
case "$ERR" in *"workspace is scoped to plan $EXT_PLAN"*) ok "arg-less prints scoping line naming current plan" ;; *) bad "arg-less prints scoping line naming current plan (got: $ERR)" ;; esac
OUT=$("$SCRIPTS/sdd-workspace" 2>/dev/null)
assert_eq "arg-less stdout unchanged" "$OUT" "$WS"
rm "$WS/plan.ref"
ERR=$("$SCRIPTS/sdd-workspace" 2>&1 > /dev/null)
case "$ERR" in *"no plan.ref"*) ok "arg-less warns on legacy workspace (no plan.ref)" ;; *) bad "arg-less warns on legacy workspace (no plan.ref) (got: $ERR)" ;; esac

# Fresh workspace (no content, no plan.ref): plan.ref written, no archive.
rm -rf "$WS"
"$SCRIPTS/sdd-workspace" planA.md > /dev/null
assert_eq "fresh workspace plan.ref written" "$(cat "$WS/plan.ref")" "planA.md"
if [ ! -d "$WS/archive" ]; then ok "fresh workspace created no archive"; else bad "fresh workspace created no archive"; fi

# Archive notice: switching plans must report where the previous workspace went.
echo "seed" > "$WS/progress.md"
ARCH_ERR=$("$SCRIPTS/sdd-workspace" planB.md 2>&1 >/dev/null)
case "$ARCH_ERR" in *"archived previous workspace to archive/planA"*) ok "archive notice printed with correct slug" ;; *) bad "archive notice printed with correct slug (got: $ARCH_ERR)" ;; esac

# Missing-plan rejection creates no workspace: this invariant holds only for
# the missing-file check, which runs before any mkdir/write. It does not
# extend to the newline check, which runs after mkdir -p and the .gitignore
# write.
rm -rf "$WS"
"$SCRIPTS/sdd-workspace" nope.md 2>/dev/null
assert_eq "missing plan (no prior workspace) exits 2" "$?" "2"
if [ ! -d "$WS" ]; then ok "missing plan: workspace not created"; else bad "missing plan: workspace not created"; fi

bold "sdd-workspace (CDPATH safety)"

# A shadowing CDPATH entry must never hijack the relative `cd` used to
# resolve the plan's directory (I1): the identity must stay single-line
# and name the real plan, not a same-named directory found via CDPATH.
rm -rf "$WS"
mkdir -p docs/plans
cat > docs/plans/planC.md << 'PLAN'
### Task 1: plan C task
PLAN
SHADOW_ROOT=$(mktemp -d)
SHADOW_ROOT=$(cd "$SHADOW_ROOT" && pwd -P)
: "${SHADOW_ROOT:?mktemp -d failed — refusing to operate on absolute root paths}"
mkdir -p "$SHADOW_ROOT/docs/plans"
echo "decoy" > "$SHADOW_ROOT/docs/plans/decoy.md"
env CDPATH="$SHADOW_ROOT" "$SCRIPTS/sdd-workspace" docs/plans/planC.md > /dev/null
assert_eq "CDPATH shadow: plan.ref is single line" "$(wc -l < "$WS/plan.ref" | tr -d ' ')" "1"
assert_eq "CDPATH shadow: plan.ref names correct plan" "$(cat "$WS/plan.ref")" "docs/plans/planC.md"
echo "cdpath ledger" > "$WS/progress.md"
env CDPATH="$SHADOW_ROOT" "$SCRIPTS/sdd-workspace" docs/plans/planC.md > /dev/null
assert_file_contains "CDPATH shadow: repeat call keeps ledger" "$WS/progress.md" "cdpath ledger"
rm -rf "$SHADOW_ROOT"

bold "sdd-workspace (newline-in-path rejection)"

# A plan path whose basename embeds a literal newline would corrupt
# plan.ref the same way a CDPATH hijack does (I1) — reject it before
# writing anything, and never touch an existing ledger.
NL_PLAN=$'weird\nplan.md'
printf '### Task 1: weird\n' > "$NL_PLAN" 2>/dev/null
if [ -f "$NL_PLAN" ]; then
  ERR=$("$SCRIPTS/sdd-workspace" "$NL_PLAN" 2>&1 >/dev/null)
  RC=$?
  assert_eq "newline plan path rejected (exit 2)" "$RC" "2"
  case "$ERR" in *"multiple lines"*) ok "newline plan path: error names newline rejection" ;; *) bad "newline plan path: error names newline rejection (got: $ERR)" ;; esac
  assert_eq "newline plan path: plan.ref untouched" "$(cat "$WS/plan.ref")" "docs/plans/planC.md"
  assert_file_contains "newline plan path: ledger untouched" "$WS/progress.md" "cdpath ledger"
else
  echo "  SKIP: filesystem rejects newlines in filenames — newline-in-path rejection tests skipped"
fi
rm -f "$NL_PLAN"

bold "sdd-workspace (symlinked plan path)"

# A plan reached through a symlinked parent directory must resolve to its
# real (physical) location (script's pwd -P at :29/:94), not the symlink's
# logical name — otherwise the identity recorded in plan.ref would drift
# depending on which symlinked name was used to reach the same real plan.
rm -rf "$WS"
mkdir -p realdir
cat > realdir/planSym.md << 'PLAN'
### Task 1: symlink test
PLAN
if ln -s realdir symlink-to-real 2>/dev/null && [ -L symlink-to-real ]; then
  "$SCRIPTS/sdd-workspace" symlink-to-real/planSym.md > /dev/null
  assert_eq "symlinked plan path: identity uses resolved real path" "$(cat "$WS/plan.ref")" "realdir/planSym.md"
  echo "ledger sym" > "$WS/progress.md"
  "$SCRIPTS/sdd-workspace" symlink-to-real/planSym.md > /dev/null
  assert_file_contains "symlinked plan path: repeat call keeps ledger" "$WS/progress.md" "ledger sym"
  if [ ! -d "$WS/archive" ]; then ok "symlinked plan path: no archive on repeat call"; else bad "symlinked plan path: no archive on repeat call"; fi
else
  echo "  SKIP: ln -s not supported on this filesystem — symlinked plan path tests skipped"
fi

bold "review-package (reviewer blinding)"

# A commit that carries both an ordinary source change and committed review
# material: the package must show the source hunk and hide the review files.
mkdir -p docs/superpowers-orchestrator/2026-08-25-foo/implementation
mkdir -p docs/superpowers-orchestrator/2026-08-25-foo/specs
echo "base for blinding" > blind-base.txt
git add blind-base.txt && git commit --quiet -m "base commit for blinding"
BLIND_BASE=$(git rev-parse HEAD)

echo "SECRETFINDING round 1 verdict" > docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-review-log.md
echo "SECRETFIXREPORT ran the tests" > docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-fix-reports.md
echo "SECRETSIDECAR spec round 1" > docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design-review-log.md
echo "SECRETORCH phase 1 done" > docs/superpowers-orchestrator/2026-08-25-foo/foo-orchestration-log.md
echo "SECRETDECISIONS open item" > docs/superpowers-orchestrator/2026-08-25-foo/plans-open.tmp
mkdir -p docs/superpowers-orchestrator/2026-08-25-foo/plans
mv docs/superpowers-orchestrator/2026-08-25-foo/plans-open.tmp docs/superpowers-orchestrator/2026-08-25-foo/plans/foo-open-decisions.md
echo "VISIBLESOURCE" > blind-src.txt
git add -A && git commit --quiet -m "feature plus review material"
BLIND_HEAD=$(git rev-parse HEAD)

BPKG=$("$SCRIPTS/review-package" "$BLIND_BASE" "$BLIND_HEAD" 2>/dev/null | sed 's/^wrote //; s/:.*$//')
assert_file_contains "blinding: ordinary source change is visible" "$BPKG" "VISIBLESOURCE"
assert_file_not_contains "blinding: implementation review log hidden" "$BPKG" "SECRETFINDING"
assert_file_not_contains "blinding: implementation fix reports hidden" "$BPKG" "SECRETFIXREPORT"
assert_file_not_contains "blinding: spec review-log sidecar hidden" "$BPKG" "SECRETSIDECAR"
assert_file_not_contains "blinding: orchestration log hidden" "$BPKG" "SECRETORCH"
assert_file_not_contains "blinding: open-decisions file hidden" "$BPKG" "SECRETDECISIONS"
# The five assertions above key on file CONTENT, which only the `git diff -U10`
# body can carry. The `## Files changed` section is a `git diff --stat`, which
# prints file NAMES and counts and no content at all, so a package whose
# `--stat` is un-blinded passes every one of them while still listing
# `…/implementation/foo-review-log.md` to the reviewer. This assertion keys on
# the path, so it is the only one that reaches the `--stat` edit in Step 3.
assert_file_not_contains "blinding: review file names absent from the stat summary" "$BPKG" "implementation/foo-review-log.md"

# A commit that touches ONLY review material must not appear in the commit
# list at all — a visible "chore(review)" subject with no hunks tells a
# reviewer that review rounds happened.
echo "SECRETFINDING round 2 verdict" >> docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-review-log.md
git add -A && git commit --quiet -m "chore(review): foo round 2 log"
BLIND_HEAD2=$(git rev-parse HEAD)
BPKG2=$("$SCRIPTS/review-package" "$BLIND_BASE" "$BLIND_HEAD2" 2>/dev/null | sed 's/^wrote //; s/:.*$//')
assert_file_not_contains "blinding: review-only commit absent from the commit list" "$BPKG2" "chore(review)"

# --commits mode must be blinded too. The spec requires blinding in BOTH
# modes, and the wave-execution path uses this one. Same commit, addressed by
# SHA instead of by range.
# Write it into $WS (the `.superpowers/sdd/` workspace, which carries a
# self-ignoring `.gitignore`), NOT into the repository root: a stray untracked
# file at the root would make Task 12's `git status --porcelain` assertion
# report dirty. The variable name avoids `CPKG`, already bound at line ~179.
BLIND_CPKG="$WS/blind-from-commits.diff"
"$SCRIPTS/review-package" --commits "$BLIND_HEAD" --out "$BLIND_CPKG" >/dev/null 2>&1
assert_file_contains "blinding (--commits): ordinary source change is visible" "$BLIND_CPKG" "VISIBLESOURCE"
assert_file_not_contains "blinding (--commits): implementation review log hidden" "$BLIND_CPKG" "SECRETFINDING"
# Same reasoning for `git show --stat` in --commits mode.
assert_file_not_contains "blinding (--commits): review file names absent from the stat summary" "$BLIND_CPKG" "implementation/foo-review-log.md"

# Run from a subdirectory and assert on the package CONTENT, not on the exit
# status: `review-package` exits 0 from anywhere, with or without the
# pathspecs, so an exit-status check would pass for every implementation. The
# content check is the real discriminator — with a relative scope such as
# `-- .` the diff would be restricted to `subdir-for-anchor/` and VISIBLESOURCE
# would be missing; ':(top)' anchors every pathspec at the repository root.
mkdir -p subdir-for-anchor
BLIND_SUBPKG="$WS/blind-from-subdir.diff"
( cd subdir-for-anchor && "$SCRIPTS/review-package" "$BLIND_BASE" "$BLIND_HEAD" "$BLIND_SUBPKG" >/dev/null 2>&1 )
assert_file_contains "blinding: source visible when the package is built from a subdirectory" "$BLIND_SUBPKG" "VISIBLESOURCE"
assert_file_not_contains "blinding: review log hidden when built from a subdirectory" "$BLIND_SUBPKG" "SECRETFINDING"

# `subdir-for-anchor` is an empty directory; git stores no empty directories,
# so it leaves no untracked entry behind for Task 12's clean-tree assertion.

bold "pipeline-mode git rules (multi-code-review)"

PTOPIC="docs/superpowers-orchestrator/2026-08-25-bar"
PLOG="$PTOPIC/implementation/bar-review-log.md"
mkdir -p "$PTOPIC/implementation"
echo "unrelated source" > unrelated.txt
git add unrelated.txt && git commit --quiet -m "base for pipeline rules"

# Rule 1: `git add` + a path-limited commit commits an untracked log while
# leaving an unrelated staged file staged.
echo "round 1 verdict" > "$PLOG"
echo "staged by the user" > user-staged.txt
git add user-staged.txt
git add -- "$PLOG"
git commit --quiet -m "chore(review): bar round 1 log" -- "$PLOG"
assert_eq "rule 1: log is committed" "$(git log -1 --format=%s)" "chore(review): bar round 1 log"
assert_eq "rule 1: the user's staged file is still staged" "$(git diff --cached --name-only)" "user-staged.txt"

# Rule 2: the precondition pathspec reports clean with only the log modified,
# and dirty with a source file modified.
git commit --quiet -m "keep the user file out of the way" -- user-staged.txt
echo "round 2 verdict" >> "$PLOG"
PRECOND=$(git status --porcelain -- ':(top)' ":(top,exclude)$PTOPIC/implementation/")
assert_eq "rule 2: modified implementation log reads clean" "$PRECOND" ""
echo "changed" >> unrelated.txt
PRECOND2=$(git status --porcelain -- ':(top)' ":(top,exclude)$PTOPIC/implementation/")
if [ -n "$PRECOND2" ]; then ok "rule 2: modified source file reads dirty"; else bad "rule 2: modified source file reads dirty"; fi
git checkout --quiet -- unrelated.txt
git add -- "$PLOG" && git commit --quiet -m "chore(review): bar round 2 log" -- "$PLOG"

# Rule 4: the effective-HEAD walk skips leading chore(review) commits and
# stops at the first other commit.
#
# The walk is used twice below, with two different range bases. Define it once
# as a function rather than pasting the loop twice: two byte-identical copies
# of a logic block are exactly what the review rubric treats as a defect, and
# the repository's DRY rule forbids them. The function is NOT required to be
# byte-identical to the version `multi-code-review/SKILL.md` documents — this
# test asserts the walk's behavior, not the skill's wording.
effective_head_of() {
  local base="$1" sha subject effective_head=""
  while read -r sha subject; do
    case "$subject" in
      'chore(review):'*) continue ;;
      *) effective_head="$sha"; break ;;
    esac
  done < <(git log --format='%H %s' "$base..HEAD")
  [ -n "$effective_head" ] || effective_head="$base"
  printf '%s\n' "$effective_head"
}

PBASE=$(git rev-parse HEAD~3)
echo "real work" > real-work.txt
git add real-work.txt && git commit --quiet -m "feat: real work"
REAL_WORK_SHA=$(git rev-parse HEAD)
echo "round 3 verdict" >> "$PLOG"
git add -- "$PLOG" && git commit --quiet -m "chore(review): bar round 3 log" -- "$PLOG"

assert_eq "rule 4: effective HEAD skips the trailing review commit" \
  "$(effective_head_of "$PBASE")" "$REAL_WORK_SHA"

# Rule 4, degenerate case: a range holding only chore(review) commits falls
# back to BASE.
ONLY_BASE=$(git rev-parse HEAD~1)
assert_eq "rule 4: review-only range falls back to BASE" \
  "$(effective_head_of "$ONLY_BASE")" "$ONLY_BASE"

bold "recovery greps stay intact"

# The batch controller finds task ticks with `git log --grep "task <n> complete"`
# and fix commits with the `review fixes (<slug>, round <i>)` subject. A
# pipeline-mode log commit must match neither.
#
# Both greps run against commits that REALLY EXIST in this throwaway
# repository: the three `chore(review): bar round <i> log` commits created
# above, plus one genuine tick commit and one genuine fix commit created here.
# Each grep therefore has a match it must find AND log commits it must not
# find, so a pipeline-mode subject that started colliding with either recovery
# pattern would fail this gate. (Matching a shell variable against a literal
# with `case` could never fail — both sides are written in this same file.)
echo "tick" > tick.txt
git add tick.txt && git commit --quiet -m "chore(plan): bar task 1 complete"
TICK_SHA=$(git rev-parse --short HEAD)
echo "fix" > fix.txt
git add fix.txt && git commit --quiet -m "review fixes (bar, round 1)"
FIX_SHA=$(git rev-parse --short HEAD)

# Control: each recovery grep finds its own commit. Without this the two
# "matches no review-log commit" assertions below would also pass if the grep
# matched nothing at all.
assert_eq "recovery grep: 'task 1 complete' finds exactly the tick commit" \
  "$(git log --grep 'task 1 complete' --format=%h | tr '\n' ' ' | sed 's/ *$//')" "$TICK_SHA"
assert_eq "recovery grep: 'review fixes (' finds exactly the fix commit" \
  "$(git log --grep 'review fixes (' --format=%h | tr '\n' ' ' | sed 's/ *$//')" "$FIX_SHA"

# The real assertions: neither recovery pattern matches a pipeline-mode
# `chore(review)` log commit.
assert_eq "recovery grep: 'task 1 complete' matches no review-log commit" \
  "$(git log --grep 'task 1 complete' --format=%s | grep -c 'chore(review)' | tr -d ' ')" "0"
assert_eq "recovery grep: 'review fixes (' matches no review-log commit" \
  "$(git log --grep 'review fixes (' --format=%s | grep -c 'chore(review)' | tr -d ' ')" "0"

bold "archive naming with a dateless plan basename"

# `sdd-workspace` names the archive folder from the OUTGOING plan's basename
# minus its extension (script line ~112, `slug=$(basename -- "$current")`).
# Archiving fires only when the plan identity changes, so the check switches
# from one plan to another. Under the new layout the plan basename carries no
# date prefix (`plans/<slug>.md` instead of `plans/<date>-<slug>.md`), so the
# archive folder is named `<slug>`. The rule is unchanged; this asserts the
# result, which the spec's testing strategy requires.
mkdir -p docs/superpowers-orchestrator/2026-08-25-baz/plans
mkdir -p docs/superpowers-orchestrator/2026-08-25-qux/plans
echo "# plan" > docs/superpowers-orchestrator/2026-08-25-baz/plans/baz.md
echo "# plan" > docs/superpowers-orchestrator/2026-08-25-qux/plans/qux.md
"$SCRIPTS/sdd-workspace" docs/superpowers-orchestrator/2026-08-25-baz/plans/baz.md > /dev/null
echo "leftover" > "$WS/task-1-notes.md"
"$SCRIPTS/sdd-workspace" docs/superpowers-orchestrator/2026-08-25-qux/plans/qux.md > /dev/null
if [ -d "$WS/archive/baz" ]; then
  ok "archive naming: dateless plan basename yields archive/baz"
else
  bad "archive naming: expected $WS/archive/baz, found: $(ls "$WS/archive" 2>/dev/null | tr '\n' ' ')"
fi

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
