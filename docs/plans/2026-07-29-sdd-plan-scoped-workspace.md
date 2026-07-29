# SDD Plan-Scoped Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-optimized:subagent-driven-development (recommended) or superpowers-optimized:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `.superpowers/sdd/` plan-scoped via script-enforced identity (`plan.ref`), so a stale ledger from an earlier plan can never masquerade as the current plan's finished record.

**Spec:** `docs/specs/2026-07-29-sdd-plan-scoped-workspace-design.md`

**Architecture:** `skills/subagent-driven-development/scripts/sdd-workspace` gains an optional `PLAN_FILE` argument and becomes the single enforcement point: it records the plan's identity in `<workspace>/plan.ref` and, on mismatch or legacy state, archives the whole workspace to `<workspace>/archive/<slug>/` (move, never delete). Arg-less calls (from `task-brief`/`review-package`) keep today's behavior plus stderr-only backstops. SKILL.md is updated in three places (step 1, Durable Progress, Batched Resume Procedure) to pass `PLAN_FILE` and state the new guarantee.

**Tech Stack:** Bash (macOS/Linux/Git Bash compatible), git, existing pure-bash test suite `tests/sdd-scripts/run-tests.sh`.

**Assumptions:**
- Assumes execution on a feature branch off `main` (Task 1 creates it) — will NOT run implementation commits on `main`.
- Assumes the executing controller does NOT treat the pre-existing `.superpowers/sdd/progress.md` as this plan's ledger: that file records two *prior* plans (v6.9.0 multi-review and multi-code-review) under hand-written headers. Start this plan's ledger entries under a new `# Active plan: docs/plans/2026-07-29-sdd-plan-scoped-workspace.md` heading (existing convention) — the very hazard this plan fixes.
- Assumes `mktemp -d` and `date +%s` exist (POSIX) — will NOT work on shells without them (not a supported platform).
- Assumes the sdd-scripts suite is run with repo-checkout scripts (`tests/sdd-scripts/run-tests.sh` resolves `$SCRIPTS` from the repo, not the plugin cache) — live-session behavior still requires a plugin cache reinstall (spec Rollout).

**Global Constraints:**
- stdout contract of `sdd-workspace` is unchanged: it prints exactly one line, the workspace path. Every new message goes to stderr.
- `plan.ref` is read as: first line, trailing whitespace stripped. Empty or unreadable `plan.ref` is treated identically to "no `plan.ref`" (legacy rule, `unknown-<epoch-seconds>` slug).
- Identity = repo-root-relative physical path for in-repo plans; absolute physical path for out-of-repo plans. Out-of-repo plans must NOT error (regression risk for worktree/notes-dir workflows). Directory symlinks are resolved (`pwd -P`); a symlink at the file's basename is deliberately NOT resolved.
- Archiving is a move, never a delete. `archive/` and `.gitignore` are never archived; all other entries (dotfiles included) move. `plan.ref` moves LAST so a crash mid-archive leaves the remainder slug-identified.
- On any archive destination collision (plan slugs and `unknown-*` alike), append a numeric suffix (`<slug>-2`, `<slug>-3`, …).
- `task-brief` and `review-package` call sites are untouched.
- Plan checkboxes + `git log` remain authoritative for position; `plan.ref` certifies identity only.
- Scripts must stay cross-platform: no `/dev/stdin`, no GNU-only flags, Git Bash compatible.
- Version bump to **6.12.0** in ALL of: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` (meta version), plus a `RELEASE-NOTES.md` entry. No new skill → `hooks/skill-rules.json` unchanged.

---

## File Structure

- Modify: `skills/subagent-driven-development/scripts/sdd-workspace` — plan-identity enforcement, archiving, stderr backstops (single responsibility: workspace location + identity).
- Modify: `tests/sdd-scripts/run-tests.sh` — new "sdd-workspace (plan scoping)" section appended after the existing sections (they leave the workspace in exactly the legacy pre-fix state the first new test needs).
- Modify: `skills/subagent-driven-development/SKILL.md` — three prose edits (step 1, Durable Progress, Resume Procedure).
- Modify: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `RELEASE-NOTES.md` — release 6.12.0.
- Commit (already written, uncommitted): `docs/specs/2026-07-29-sdd-plan-scoped-workspace-design.md`, its `-review-log.md`, this plan, and this plan's `-review-log.md`.

---

### Task 1: Branch and commit the design documents

**Files:**
- Commit: `docs/specs/2026-07-29-sdd-plan-scoped-workspace-design.md`
- Commit: `docs/specs/2026-07-29-sdd-plan-scoped-workspace-design-review-log.md`
- Commit: `docs/plans/2026-07-29-sdd-plan-scoped-workspace.md`
- Commit: `docs/plans/2026-07-29-sdd-plan-scoped-workspace-review-log.md` (if the plan review gate has produced it)

**Security flag:** `none`

- [ ] **Step 1: Create the feature branch**

```bash
git checkout -b BB/sdd-plan-scoped-workspace main
```

- [ ] **Step 2: Commit the spec and plan documents**

```bash
git add docs/specs/2026-07-29-sdd-plan-scoped-workspace-design.md \
        docs/specs/2026-07-29-sdd-plan-scoped-workspace-design-review-log.md \
        docs/plans/2026-07-29-sdd-plan-scoped-workspace.md
git add docs/plans/2026-07-29-sdd-plan-scoped-workspace-review-log.md 2>/dev/null || true
git commit -m "docs: spec + plan for SDD plan-scoped workspace"
```

- [ ] **Step 3: Verify**

Run: `git log --oneline -1 && git status --porcelain | grep -v '^??' | wc -l`
Expected: the new commit subject, and `0` (no tracked changes left behind; `state.md`/scratch stay untracked).

---

### Task 2: Plan-scoping in `sdd-workspace` (tests first)

**Files:**
- Modify: `tests/sdd-scripts/run-tests.sh`
- Modify: `skills/subagent-driven-development/scripts/sdd-workspace`

**Security flag:** `none`

**Does NOT cover:** concurrent SDD runs with different plans in one worktree (spec non-goal); plan renamed mid-plan (reads as a new plan — archives, recovery via checkboxes+git); content-based plan identity (editing a plan in place never archives); archive pruning.

- [ ] **Step 1: Write failing tests**

In `tests/sdd-scripts/run-tests.sh`, insert the following block immediately BEFORE the final results footer (the line `bold ""` at the end of the file, before `bold "Results: ..."`). The preceding sections have already filled the workspace with briefs/diffs and no `plan.ref` — exactly the legacy pre-fix state the first assertions need.

```bash
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
OUT=$("$SCRIPTS/sdd-workspace" planA.md)
assert_eq "scoped call prints same path" "$OUT" "$WS"
assert_eq "plan.ref holds repo-relative path" "$(cat "$WS/plan.ref")" "planA.md"
LEGACY=$(ls -d "$WS"/archive/unknown-* 2>/dev/null | head -n 1)
if [ -n "$LEGACY" ]; then ok "legacy content archived under unknown-*"; else bad "legacy content archived under unknown-*"; fi
assert_file_contains "legacy ledger intact in archive" "$LEGACY/progress.md" "old ledger"
assert_file_contains "brief archived intact" "$LEGACY/task-2-brief.md" "### Task 2: Second thing"
if ls "$LEGACY"/review-*.diff > /dev/null 2>&1; then ok "review diffs archived"; else bad "review diffs archived"; fi
assert_file_contains "dotfile archived" "$LEGACY/.hidden-note" "dot"
if [ ! -e "$WS/progress.md" ]; then ok "workspace root fresh after legacy archive"; else bad "workspace root fresh after legacy archive"; fi
if ls "$WS"/task-*-brief.md "$WS"/review-*.diff > /dev/null 2>&1; then bad "workspace root free of briefs/diffs"; else ok "workspace root free of briefs/diffs"; fi

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
"$SCRIPTS/sdd-workspace" planB.md > /dev/null
assert_eq "plan.ref switched to plan B" "$(cat "$WS/plan.ref")" "planB.md"
assert_file_contains "plan A ledger archived intact" "$WS/archive/planA/progress.md" "ledger A"

# Empty plan.ref = crash-during-write recovery state -> legacy rule.
echo "ledger B" > "$WS/progress.md"
: > "$WS/plan.ref"
"$SCRIPTS/sdd-workspace" planA.md > /dev/null
assert_eq "plan.ref rewritten after empty-ref recovery" "$(cat "$WS/plan.ref")" "planA.md"
assert_eq "empty-ref content archived under unknown-*" "$(ls -d "$WS"/archive/unknown-* | wc -l | tr -d ' ')" "2"

# Slug collision: archive/planA already exists; archiving plan A's
# workspace again must land in planA-2.
echo "ledger A2" > "$WS/progress.md"
"$SCRIPTS/sdd-workspace" planB.md > /dev/null
assert_file_contains "collision archive suffixed" "$WS/archive/planA-2/progress.md" "ledger A2"

# Out-of-repo plan: absolute physical identity, stable across calls.
EXT=$(mktemp -d)
EXT=$(cd "$EXT" && pwd -P)
cat > "$EXT/ext-plan.md" << 'PLAN'
### Task 1: external plan task
PLAN
"$SCRIPTS/sdd-workspace" "$EXT/ext-plan.md" > /dev/null
assert_eq "out-of-repo plan.ref is absolute" "$(cat "$WS/plan.ref")" "$EXT/ext-plan.md"
echo "ext ledger" > "$WS/progress.md"
"$SCRIPTS/sdd-workspace" "$EXT/ext-plan.md" > /dev/null
assert_file_contains "out-of-repo resume keeps ledger" "$WS/progress.md" "ext ledger"
rm -rf "$EXT"

# Errors and arg-less stderr backstops (stdout must stay one path line).
"$SCRIPTS/sdd-workspace" nope.md 2>/dev/null
assert_eq "missing plan exits 2" "$?" "2"
ERR=$("$SCRIPTS/sdd-workspace" 2>&1 > /dev/null)
case "$ERR" in *"workspace is scoped to plan"*) ok "arg-less prints scoping line" ;; *) bad "arg-less prints scoping line (got: $ERR)" ;; esac
OUT=$("$SCRIPTS/sdd-workspace" 2>/dev/null)
assert_eq "arg-less stdout unchanged" "$OUT" "$WS"
rm "$WS/plan.ref"
ERR=$("$SCRIPTS/sdd-workspace" 2>&1 > /dev/null)
case "$ERR" in *"warning"*) ok "arg-less warns on legacy workspace" ;; *) bad "arg-less warns on legacy workspace (got: $ERR)" ;; esac

# Fresh workspace (no content, no plan.ref): plan.ref written, no archive.
rm -rf "$WS"
"$SCRIPTS/sdd-workspace" planA.md > /dev/null
assert_eq "fresh workspace plan.ref written" "$(cat "$WS/plan.ref")" "planA.md"
if [ ! -d "$WS/archive" ]; then ok "fresh workspace created no archive"; else bad "fresh workspace created no archive"; fi
```

Note: once the implementation lands, the internal arg-less `sdd-workspace` calls inside the earlier `task-brief`/`review-package` sections will print the legacy warning to the terminal (workspace has briefs, no `plan.ref`). That stderr noise is designed behavior and must not be "fixed"; the same warning behavior is asserted at the end of the new section — the noise from the earlier sections themselves is unasserted but expected.

- [ ] **Step 2: Run the suite to verify the new tests fail**

Run: `bash tests/sdd-scripts/run-tests.sh`
Expected: FAIL — all pre-existing tests still pass; the new "plan scoping" section fails starting with `plan.ref holds repo-relative path` (the current script ignores arguments, so no `plan.ref` is ever written). Exit code 1.

- [ ] **Step 3: Implement — replace `skills/subagent-driven-development/scripts/sdd-workspace` with:**

```bash
#!/usr/bin/env bash
# Resolve and ensure the working-tree directory SDD uses for its short-lived
# artifacts: task briefs, implementer reports, review packages, and the
# progress ledger. Print the directory's absolute path.
#
# The workspace lives in the working tree (not under .git/) because agents
# cannot write into .git/ (protected path) — which would block an implementer
# subagent from writing its report file. A self-ignoring .gitignore keeps the
# workspace out of `git status` and out of accidental commits without
# modifying any tracked file.
#
# The workspace is plan-scoped: with PLAN_FILE, the plan's identity is
# recorded in plan.ref (repo-relative physical path; absolute for plans
# outside the repo). A workspace belonging to a different plan — or a legacy
# workspace with content but no plan.ref — is archived to archive/<slug>/
# first, so a leftover progress.md can never masquerade as the current
# plan's ledger. Without PLAN_FILE (internal calls from task-brief and
# review-package) behavior is unchanged apart from stderr backstops.
#
# Single source of truth for the workspace location and plan identity, so
# task-brief and review-package cannot drift to different directories.
#
# Usage: sdd-workspace [PLAN_FILE]
set -euo pipefail

usage() { echo "usage: sdd-workspace [PLAN_FILE]" >&2; exit 2; }

root=$(git rev-parse --show-toplevel)
root=$(cd "$root" && pwd -P)
dir="$root/.superpowers/sdd"
ref="$dir/plan.ref"

# plan.ref contract: first line, trailing whitespace stripped.
# Empty or unreadable reads the same as absent.
read_ref() {
  if [ -r "$ref" ]; then
    head -n 1 "$ref" | sed 's/[[:space:]]*$//'
  fi
}

# True when the workspace holds any entry other than .gitignore, archive/,
# and plan.ref itself (identity is handled separately — an empty plan.ref
# alone must read as a fresh workspace, not as archivable content).
has_content() {
  local e
  for e in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
    [ -e "$e" ] || continue
    case "$(basename "$e")" in
      .gitignore|archive|plan.ref) continue ;;
    esac
    return 0
  done
  return 1
}

# Move everything except .gitignore and archive/ into archive/<slug>/,
# suffixing on collision. plan.ref moves LAST: a crash mid-archive then
# leaves the remainder still slug-identified, so a rerun archives it under
# the same slug instead of scattering it under unknown-*.
archive_workspace() { # $1 = slug
  local dest="$dir/archive/$1" n=2
  while [ -e "$dest" ]; do dest="$dir/archive/$1-$n"; n=$((n+1)); done
  mkdir -p "$dest"
  local e name
  for e in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
    [ -e "$e" ] || continue
    name=$(basename "$e")
    case "$name" in
      .gitignore|archive|plan.ref) continue ;;
    esac
    mv "$e" "$dest/"
  done
  if [ -e "$ref" ]; then mv "$ref" "$dest/"; fi
}

# Validate before touching the filesystem.
[ $# -le 1 ] || usage
if [ $# -eq 1 ] && { [ ! -f "$1" ] || [ ! -r "$1" ]; }; then
  echo "no such readable plan file: $1" >&2
  usage
fi

mkdir -p "$dir"
printf '*\n' > "$dir/.gitignore"

if [ $# -eq 1 ]; then
  plan=$1
  # Physical path: resolve the directory (pwd -P), keep the basename as
  # given — a symlink at the file itself is deliberately not resolved.
  plan_abs="$(cd "$(dirname "$plan")" && pwd -P)/$(basename "$plan")"
  case "$plan_abs" in
    "$root"/*) identity=${plan_abs#"$root"/} ;;
    *)         identity=$plan_abs ;;  # out-of-repo plan: absolute identity
  esac
  current=$(read_ref)
  if [ "$current" = "$identity" ]; then
    : # same plan resuming — never touch the ledger
  elif [ -z "$current" ] && ! has_content; then
    printf '%s\n' "$identity" > "$ref"
  else
    if [ -n "$current" ]; then
      slug=$(basename "$current"); slug=${slug%.*}
    else
      slug="unknown-$(date +%s)"
    fi
    archive_workspace "$slug"
    printf '%s\n' "$identity" > "$ref"
  fi
else
  # Arg-less: resolve only. Stderr backstops let a version-skewed caller
  # (pre-fix SKILL.md) see which plan the ledger belongs to.
  current=$(read_ref)
  if [ -n "$current" ]; then
    echo "workspace is scoped to plan $current" >&2
  elif has_content; then
    echo "warning: workspace has content but no plan.ref — a stale ledger from another plan may be present" >&2
  fi
fi

cd "$dir" && pwd
```

- [ ] **Step 4: Run the suite to verify everything passes**

Run: `bash tests/sdd-scripts/run-tests.sh`
Expected: PASS — 0 failed, including all pre-existing sdd-workspace/task-brief/review-package tests (exit 0).

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/scripts/sdd-workspace tests/sdd-scripts/run-tests.sh
git commit -m "sdd-workspace: plan-scoped workspace via plan.ref + archive"
```

---

### Task 3: SKILL.md — pass PLAN_FILE and state the guarantee

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** other skills' prose (executing-plans etc. do not reference the workspace); the version-skewed cached SKILL.md (unfixable from the repo — spec residual risk); the File Handoffs section's arg-less mention ("workspace (`scripts/sdd-workspace` prints its path)") — intentionally untouched, arg-less resolve-only calls remain part of the contract, do NOT "fix" it.

- [ ] **Step 1: Update Core Flow step 1**

Replace this text (currently line 64, the numbered step starting "1. Read the plan once"):

```
1. Read the plan once and extract all tasks. Run `scripts/sdd-workspace` (from this skill's directory) once to create the artifact workspace, and check `.superpowers/sdd/progress.md` for a ledger from an earlier session — tasks it marks complete are DONE; never re-dispatch them.
```

with:

```
1. Read the plan once and extract all tasks. Run `scripts/sdd-workspace PLAN_FILE` (from this skill's directory) once to create the artifact workspace — the script archives any workspace belonging to a different plan, so a surviving `.superpowers/sdd/progress.md` ledger is by construction the current plan's. Tasks it marks complete are DONE; never re-dispatch them. Plan checkboxes + `git log` stay authoritative for position on any conflict (e.g. a `git reset --hard` rolled back commits the git-ignored ledger still records as complete).
```

- [ ] **Step 2: Update the Durable Progress bullet**

Replace:

```
- At skill start, check for a ledger: `.superpowers/sdd/progress.md`.
  Tasks listed there as complete are DONE — do not re-dispatch them.
```

with:

```
- At skill start, check for a ledger: `.superpowers/sdd/progress.md`.
  The workspace is plan-scoped: `scripts/sdd-workspace PLAN_FILE` records
  the plan in `plan.ref` and archives any other plan's artifacts to
  `.superpowers/sdd/archive/<slug>/`, so a surviving ledger belongs to
  the current plan. Tasks listed there as complete are DONE — do not
  re-dispatch them. Carried Minor findings from an archived run are
  recovered read-only from `archive/<slug>/progress.md` for final-review
  triage.
```

- [ ] **Step 3: Update the Resume Procedure**

Replace:

```
1. Read `state.md`; read the plan at the recorded path; read recent `git log`.
```

with:

```
1. Read `state.md`; read the plan at the recorded path; read recent `git log`.
   Run `scripts/sdd-workspace PLAN_FILE` — resume is a skill start for
   workspace scoping. If another plan ran in between, this archives its
   workspace and starts this plan with a fresh ledger; consult
   `archive/<slug>/progress.md` (read-only) to recover carried Minor
   findings.
```

- [ ] **Step 4: Verify all three edits landed and no stale step-1-style invocation instruction remains** (the File Handoffs arg-less mention stays, see Does NOT cover)

Run: `grep -c "sdd-workspace PLAN_FILE" skills/subagent-driven-development/SKILL.md && grep -c "archive/<slug>/progress.md" skills/subagent-driven-development/SKILL.md && grep -n 'Run `scripts/sdd-workspace` ' skills/subagent-driven-development/SKILL.md | wc -l`
Expected: `3`, then `2`, then `0` (no remaining arg-less invocation instruction).

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "sdd SKILL: plan-scoped workspace — step 1, durable progress, resume"
```

---

### Task 4: Release 6.12.0

**Files:**
- Modify: `VERSION`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugin.universal.yaml`
- Modify: `RELEASE-NOTES.md`

**Security flag:** `none`

- [ ] **Step 1: Bump the version in all four files**

Set `6.12.0` in: `VERSION` (whole file), `.claude-plugin/plugin.json` line with `"version"`, `.claude-plugin/marketplace.json` line with `"version"`, and `plugin.universal.yaml` meta `version:` line. All currently read `6.11.0`.

- [ ] **Step 2: Add the release-notes entry**

Insert at the top of `RELEASE-NOTES.md`, directly under the `# Superpowers Optimized Release Notes` heading:

```markdown
## v6.12.0 — SDD workspace is plan-scoped

- `scripts/sdd-workspace` now takes the plan path (`sdd-workspace PLAN_FILE`)
  and records it in `.superpowers/sdd/plan.ref`. A workspace belonging to a
  different plan — or a pre-6.12 workspace with no `plan.ref` — is archived
  to `.superpowers/sdd/archive/<slug>/` (moved, never deleted) before the
  new plan starts. Fixes the stale-ledger hazard where a leftover
  `progress.md` from a finished plan read exactly like a completed record
  of the current plan and could make the controller skip all work.
- Out-of-repo plans are supported: their identity is the absolute physical
  path (no error, no false mismatch).
- Arg-less calls (internal, from `task-brief`/`review-package`) are
  unchanged on stdout; they now print a stderr scoping line (or a legacy
  warning) so version-skewed sessions can see which plan the ledger
  belongs to.
- SDD SKILL.md: step 1 and the Batched Autonomous Mode Resume Procedure
  now pass `PLAN_FILE`; resume counts as a skill start for scoping.
  Checkboxes + `git log` stay authoritative for position.
- Upgrade note: the first scoped run archives any pre-6.12 workspace even
  when resuming the same plan (one-time cost); carried Minor findings are
  then in `archive/unknown-*/progress.md` — consult during final-review
  triage.
```

- [ ] **Step 3: Verify version consistency**

Run: `cat VERSION && grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json && grep 'version:' plugin.universal.yaml | head -1 && grep -c 'v6.12.0' RELEASE-NOTES.md`
Expected: every version line reads `6.12.0`; the last count is ≥ 1.

- [ ] **Step 4: Run the full fast test suites (regression gate)**

Run: `bash tests/sdd-scripts/run-tests.sh && bash tests/codex/run-unit-tests.sh && bash tests/smart-compress/run-tests.sh`
Expected: all three suites must exit 0 with 0 failed. Exception: if the ONLY failure is the known clean-tree `[compressed]` smart-compress test, follow `known-issues.md` (it is environmental; the 2026-07-19 probe-file fix should prevent it) and re-run — do not proceed on any other failure.

- [ ] **Step 5: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml RELEASE-NOTES.md
git commit -m "v6.12.0 - plan-scoped SDD workspace"
```

---

## Rollout notes (post-merge, not plan tasks)

- Live sessions keep running the cached plugin until reinstall — reinstall the plugin cache before any behavioral testing of the new flow, and read the cache dir's `VERSION` file (never the dir name) to confirm what is installed.
- Marketplace pointer: verify the clone HEAD after any marketplace update (known revert-to-REPOZY behavior).
