# Upstream v7.0.0 Fixes and Copilot CLI Retirement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Port seven upstream obra/superpowers v7.0.0 fixes (A13, A17, C11, D8, D4, D6, C9) into this fork, mark GitHub Copilot CLI as no longer supported, record five Windows-only upstream fixes as accepted limits, and release v7.74.0.
**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/specs/upstream-v7-fixes-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
**Architecture:** Two bash scripts of the SDD skill change behaviour (`sdd-workspace` writes its `.gitignore` only when the file is absent or empty; `review-package` range mode exits 3 on a HEAD that does not descend from BASE, exits 2 on a non-commit BASE or HEAD, and writes `Commits in range: none` for an empty range). Every other change is skill or template wording, each pinned by folded-text assertions in the existing fast suites (`tests/sdd-scripts`, `tests/reviewer-templates`, `tests/orchestrating-development`). The release task bumps the version, writes the release notes, updates the user guide and appends accepted limits to the local, untracked issues log.
**Tech Stack:** bash 3.2+ (macOS) and git 2.50.1 for the scripts and the test suites; Markdown for skills, templates and documents; Node >= 16 only for the safety-hook probe in Task 3.
**Assumptions:**
- Every line number below refers to the files at commit `fb222d38` (v7.73.1). The branch `feature/upstream-v7-fixes` adds only files under `docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/`, so the numbers hold at the start of Task 1 (checked on 2026-10-21 with `git diff --stat fb222d38 HEAD`). Once a task edits a file, later tasks locate their place in that file by its text, not by its number; inside one task, every line number is that of `fb222d38` too, so a step that follows an earlier step of the same task in the same file (Task 8 (b), Task 10 (b), Task 12 (b)-(d)) locates its place by the quoted text. Will NOT work if another branch is merged in before execution.
- Assumes `git merge-base --is-ancestor` exits 0 for a commit and itself and exits non-zero (1, or 128 for an unknown object) otherwise (spec section 3; measured there with git 2.50.1). Will NOT work with a git that treats a commit as not its own ancestor.
- Assumes `docs/orchestration-issues.md` is git-ignored through `.git/info/exclude` and is not tracked (checked on 2026-10-21: `git check-ignore -v` prints `.git/info/exclude:23:/docs/orchestration-issues.md`; `git ls-files --error-unmatch` fails). Task 13 therefore never stages it. Will NOT ship that edit with the branch, by design.
- Assumes `.superpowers/` is git-ignored through `.git/info/exclude` in this checkout (checked: `.git/info/exclude:21:.superpowers/`). The test fixtures create their own repositories with `mktemp -d`, so the suites do not depend on it.
- Assumes git 2.31 or later for `git rev-parse --path-format=absolute` (Task 13; this machine has git 2.50.1). Will NOT locate the main checkout with an older git; the step then fails loudly at that command.
- Tasks 1-13 run one after another, in numbered order; no task of this plan runs in a parallel wave. Most tasks share a file with another task: Tasks 1, 2, 4, 5, 6 and 8 edit `tests/sdd-scripts/run-tests.sh`; Tasks 4, 5 and 8 edit `skills/subagent-driven-development/SKILL.md`; Tasks 6 and 7 edit `implementer-prompt.md`; Tasks 7 and 8 edit `task-reviewer-prompt.md`; Tasks 7 and 9 edit `skills/multi-code-review/reviewer-prompt.md`; Tasks 7, 8 and 9 edit `tests/reviewer-templates/run-tests.sh`; Tasks 10 and 11 edit `tests/orchestrating-development/run-tests.sh`; Tasks 11 and 12 edit `docs/guide/README.md`; Tasks 11 and 13 edit `README.md`.
**Global Constraints:**
- Target version: `7.74.0` (one release). Version files: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, the `README.md` version badge, and the two `v6.7.0–v7.73.1` ranges in the README's Lineage & status note (they become `v6.7.0–v7.74.0`).
- `review-package` range mode: exit 3 with exactly the one line `HEAD is not a descendant of BASE: ${base}..${head}` on standard error and no file written; exit 2 keeps `bad BASE: <arg>` / `bad HEAD: <arg>` and now also covers a BASE or HEAD that names a tree or a blob; exit 0 for an empty range, whose `## Commits` section holds the one line `Commits in range: none`. `--commits` mode never exits 3. The `blind_pathspecs` list does not change.
- Fixed return and question wordings: `BLOCKED task=<n>: review range invalid — <the script's error line>` (orchestrated exit 3); `BLOCKED task=<n>: review range invalid — HEAD does not descend from the last completed ledger HEAD <head7> (branch switched, reset or rewritten, or ledger left from an earlier run of this plan)` (batch-controller start check); `BLOCKED: review range invalid — <the script's error line>` (multi-code-review exit 3); `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)` (Batched Autonomous Mode journal entry).
- The sentence `Do NOT dispatch subagents.` is added to exactly four worker templates (`skills/subagent-driven-development/implementer-prompt.md`, `skills/subagent-driven-development/task-reviewer-prompt.md`, `skills/multi-code-review/reviewer-prompt.md`, `skills/multi-doc-review/reviewer-prompt.md`) and to no controller text (the five files of `skills/orchestrating-development/` named in spec section 4.6, `skills/multi-code-review/SKILL.md`, `skills/multi-doc-review/SKILL.md`, `skills/subagent-driven-development/SKILL.md`). The quoted sentence "You are a focused subagent. Do NOT invoke any skills from the superpowers-orchestrator plugin. Do NOT use the Skill tool. Your only job is the task described below." stays one unbroken piece everywhere.
- No new text in `skills/subagent-driven-development/SKILL.md` contains `git commit`, `chore(plan)`, the substring `tick`, or the wave line `You run in a parallel wave.`. No new text in `implementer-prompt.md` contains `git add -A`, `git commit -a`, `git commit --amend`, `git stash`, `git reset`, `git checkout`, `git restore`, `git status`, `git diff`, `whole tree`, `formatter`, `index.lock` or `current HEAD`; its `## Commit Messages` section does not change.
- No new text in `skills/orchestrating-development/batch-controller-prompt.md` contains a bracketed uppercase token (`fill-prompt.js` exits 3 on an unknown one), and none names a Core Flow step. Its only changes are the C11 exit-3 rule and the Deviation 4 start check.
- Files that do not change: `skills/multi-code-review/fix-prompt.md`, `skills/requesting-code-review/code-reviewer.md`, `agents/code-reviewer.md`, `agents/red-team.md`, every file under `hooks/`, `docs/FORK-IMPROVEMENTS.md`, `docs/research/claude-code-mods.md`. The Copilot CLI sentences listed in spec section 2 "Non-goals" stay as they are; only the sentences of spec section 4.8 change.
- `docs/orchestration-issues.md` is edited only in the main checkout and is never committed.
- Plain English in every document, comment and test label: no idioms, short sentences, terms defined at first use (user instruction for this repository).

---

## File Structure

| File | Change | Task |
|---|---|---|
| `skills/subagent-driven-development/scripts/sdd-workspace` | create-only `.gitignore`, header comment | 1 |
| `skills/subagent-driven-development/scripts/review-package` | commit checks, range guard (exit 3), empty-range line, header comment | 2 |
| `skills/systematic-debugging/SKILL.md` | two example lines print no secret | 3 |
| `skills/subagent-driven-development/SKILL.md` | Core Flow exit-3 pointer; **DONE** empty-package sentence and **Exit 3** paragraph; Resume step 2 sentence (Task 4); Pre-Flight table (Task 5); ⚠️ items for unreadable evidence (Task 8) | 4, 5, 8 |
| `skills/subagent-driven-development/implementer-prompt.md` | C9 rule (Task 6); `Do NOT dispatch subagents.` (Task 7) | 6, 7 |
| `skills/test-driven-development/SKILL.md` | C9 checklist items | 6 |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | `Do NOT dispatch subagents.` (Task 7); unreadable-evidence paragraph and ⚠️ output line (Task 8) | 7, 8 |
| `skills/multi-code-review/reviewer-prompt.md` | `Do NOT dispatch subagents.` (Task 7); legend excepts exit 3 (Task 9) | 7, 9 |
| `skills/multi-doc-review/reviewer-prompt.md` | `Do NOT dispatch subagents.` | 7 |
| `skills/multi-code-review/SKILL.md` | Error Handling bullet for exit 3 | 9 |
| `skills/orchestrating-development/batch-controller-prompt.md` | exit-3 rule; Deviation 4 start check | 10 |
| `README.md`, `docs/platforms/codex.md`, `.codex/INSTALL.md`, `docs/guide/README.md` §1 | Copilot CLI no longer supported | 11 |
| `docs/guide/README.md` §3, §4, §9 | v7.74.0 behaviour | 12 |
| `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md`; local `docs/orchestration-issues.md` (not committed) | release v7.74.0; accepted limits | 13 |
| `tests/sdd-scripts/run-tests.sh` | sections `sdd-workspace (create-only .gitignore)` (Task 1), `review-package (range guard, exit 3)` (Task 2), `SDD SKILL.md and implementer: rules of v7.74.0` (Tasks 4, 5, 6, 8) | 1, 2, 4, 5, 6, 8 |
| `tests/reviewer-templates/run-tests.sh` | sections 26, 27, 28 | 7, 8, 9 |
| `tests/orchestrating-development/run-tests.sh` | section 5f (batch controller exit 3) and section 12 additions (Copilot) | 10, 11 |

Placement rules used by several tasks:
- **The v7.74.0 section of `tests/sdd-scripts/run-tests.sh`** is created by Task 4 directly before the two final lines `bold ""` and `bold "Results: $PASS passed, $FAIL failed"` (after the section `SDD SKILL.md: the security review of Core Flow step 3`). Tasks 5, 6 and 8 append their assertions to the end of that section, again directly before those two final lines.
- **New sections of `tests/reviewer-templates/run-tests.sh`** go after section 25 (the loop ending with `assert_eq "the prompt templates without a fence are exactly the two named files" ...`), directly before the final `echo` and `bold "Results: ..."` lines, in the order 26, 27, 28.

---

### Task 1: `sdd-workspace` writes `.gitignore` only when it is absent or empty (A13)

**Files:**
- Modify: `skills/subagent-driven-development/scripts/sdd-workspace`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** a dangling symbolic link named `.gitignore` (`[ -s ]` is false, so `printf` writes `*` through the link; accepted, spec section 8 item 6); a user `.gitignore` that does not ignore the workspace files (they then show as untracked; accepted, spec section 4.1); a committed ledger `progress.md` that the archive step moves into the ignored `archive/` folder (accepted, spec section 4.1). The archive step and `blind_pathspecs` do not change.

**Contract:**
- `sdd-workspace` `.gitignore` write
  - Inputs: the existing `$dir/.gitignore` (absent, empty, or not empty).
  - Output: absent or zero-length file → the file holds exactly `*` and a newline afterwards; a file that is not empty → byte-identical afterwards. Exit codes and printed path unchanged.
  - Invariants: every call of `sdd-workspace` (with or without PLAN_FILE, and the internal calls from `task-brief` and `review-package`) leaves a non-empty `.gitignore` unchanged, also when a different plan's workspace is archived; `.gitignore` is never moved into `archive/`.
  - Verification: the new section `sdd-workspace (create-only .gitignore)` in `bash tests/sdd-scripts/run-tests.sh` (byte comparison with `cmp` after each of the five calls, `git status --porcelain` on the file, the absent case and the zero-length case); the existing pins `self-ignoring gitignore`, `workspace invisible to git status` and `.gitignore remains at workspace root after archive` stay green.
  - Interface not externally pinned.
- Header comment of `sdd-workspace` (wording artifact)
  - Must convey: the script writes the self-ignoring `.gitignore` only when the workspace has none or an empty one; a non-empty one (for example a committed one) is never changed.
  - Verification: `grep -F 'is never changed' skills/subagent-driven-development/scripts/sdd-workspace` prints the line.
  - Sentence wording is free.

- [x] **Step 1: Write the failing test**

In `tests/sdd-scripts/run-tests.sh`, insert after line 104 (`git reset --quiet`, the end of the `sdd-workspace` section) and before `bold "task-brief"`:

```bash

bold "sdd-workspace (create-only .gitignore)"

# A repository may commit its own .superpowers/sdd/.gitignore, for example one
# that keeps the ledger progress.md tracked. Every script call must leave a
# file that is not empty byte-identical; an absent or empty file is written as
# "*" and a newline. The section uses its own fixture repository, so that the
# shared fixture above keeps its state.
GI_REPO=$(mktemp -d)
: "${GI_REPO:?mktemp failed — refusing to run with an empty repo path}"
GI_REPO=$(cd "$GI_REPO" && pwd -P)
GI_SAVED=$(mktemp)
GI_STAR=$(mktemp)
printf '*\n' > "$GI_STAR"
cd "$GI_REPO"
git -c init.defaultBranch=main init --quiet
git config user.email "test@test"
git config user.name "test"
GI_WS="$GI_REPO/.superpowers/sdd"
GI_FILE="$GI_WS/.gitignore"
mkdir -p "$GI_WS"
printf '*\n!.gitignore\n!progress.md\n' > "$GI_FILE"
cp "$GI_FILE" "$GI_SAVED"
git add .superpowers/sdd/.gitignore && git commit --quiet -m "own workspace gitignore"
GI_FIRST=$(git rev-parse HEAD)
printf '### Task 1: x\nBody of task A.\n' > planA.md
printf '### Task 1: y\nBody of task B.\n' > planB.md
git add planA.md planB.md && git commit --quiet -m "two plans"

gi_unchanged() { # label
  if cmp -s "$GI_FILE" "$GI_SAVED"; then
    ok "$1: the committed .gitignore stays byte-identical"
  else
    bad "$1: the committed .gitignore stays byte-identical (now: $(tr '\n' '|' < "$GI_FILE" 2>/dev/null))"
  fi
  assert_eq "$1: git status shows no change to the committed .gitignore" \
    "$(git status --porcelain -- .superpowers/sdd/.gitignore)" ""
}
"$SCRIPTS/sdd-workspace" > /dev/null 2>&1
gi_unchanged "sdd-workspace without arguments"
"$SCRIPTS/sdd-workspace" planA.md > /dev/null 2>&1
gi_unchanged "sdd-workspace planA.md"
"$SCRIPTS/task-brief" planA.md 1 > /dev/null 2>&1
gi_unchanged "task-brief planA.md 1"
"$SCRIPTS/review-package" "$GI_FIRST" HEAD > /dev/null 2>&1
gi_unchanged "review-package in range mode"
"$SCRIPTS/sdd-workspace" planB.md > /dev/null 2>&1
gi_unchanged "sdd-workspace planB.md (archives the planA workspace)"
if ls -d "$GI_WS"/archive/* > /dev/null 2>&1; then
  ok "a different plan archives the planA workspace"
else
  bad "a different plan archives the planA workspace"
fi
if ls "$GI_WS"/archive/*/.gitignore > /dev/null 2>&1; then
  bad "the committed .gitignore is not moved into archive/"
else
  ok "the committed .gitignore is not moved into archive/"
fi
rm "$GI_FILE"
"$SCRIPTS/sdd-workspace" > /dev/null 2>&1
if cmp -s "$GI_FILE" "$GI_STAR"; then
  ok "an absent .gitignore is written as '*' and a newline"
else
  bad "an absent .gitignore is written as '*' and a newline"
fi
: > "$GI_FILE"
"$SCRIPTS/sdd-workspace" > /dev/null 2>&1
if cmp -s "$GI_FILE" "$GI_STAR"; then
  ok "an empty .gitignore is written as '*' and a newline"
else
  bad "an empty .gitignore is written as '*' and a newline"
fi
cd "$REPO"
rm -rf "$GI_REPO" "$GI_SAVED" "$GI_STAR"
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL lines `sdd-workspace without arguments: the committed .gitignore stays byte-identical (now: *|)` and the same for the other four calls (the script rewrites the file on every call), and the five `<call>: git status shows no change to the committed .gitignore` checks (the rewritten file is tracked, so git reports it as modified); the absent and empty cases pass; the `Results:` line reports at least ten failures (the pipe into `grep` hides the suite's own exit status).

- [x] **Step 3: Implement the change**

In `skills/subagent-driven-development/scripts/sdd-workspace`, replace line 85 (`printf '*\n' > "$dir/.gitignore"`) with:

```bash
# Create-only: a repository may commit its own .gitignore here (for example
# one that keeps progress.md tracked). Rewriting the file on every run would
# undo that version each time. An empty file ignores nothing and is rewritten.
[ -s "$dir/.gitignore" ] || printf '*\n' > "$dir/.gitignore"
```

Replace header lines 8-10 (from "A self-ignoring .gitignore keeps the" to "modifying any tracked file.") so that the block reads:

```bash
# subagent from writing its report file. A self-ignoring .gitignore keeps the
# workspace out of `git status` and out of accidental commits without
# modifying any tracked file. The script writes that .gitignore only when the
# workspace has none or an empty one: a .gitignore that is not empty, for
# example one that the repository commits, is never changed.
```

(Line 8 keeps its first half, "subagent from writing its report file.", unchanged.)

- [x] **Step 4: Run the test to verify it passes**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -3`
Expected: PASS — `Results: <n> passed, 0 failed`.

Run: `grep -F 'is never changed' skills/subagent-driven-development/scripts/sdd-workspace`
Expected: prints `# example one that the repository commits, is never changed.`

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/scripts/sdd-workspace tests/sdd-scripts/run-tests.sh
git commit -m "fix(sdd): sdd-workspace writes .gitignore only when absent or empty" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 1/13"
```

---

### Task 2: `review-package` exits 3 on a range whose HEAD does not descend from BASE (C11, the script)

**Files:**
- Modify: `skills/subagent-driven-development/scripts/review-package`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `security` *(input validation: the script now validates its BASE and HEAD arguments as commits and as an ancestor pair before it reads or writes anything)*

**Does NOT cover:** `--commits` mode (no range, no guard: a SHA that is HEAD itself or not an ancestor of HEAD still exits 0); refusing an empty range (upstream's second guard is not ported; an empty range exits 0); the summary count at the end of the script (it keeps its pathspecs and prints `0 commit(s)` for an empty range and for a range with only blinded commits); the callers' handling of exit 3 (Tasks 4, 9, 10).

**Contract:**
- `review-package BASE HEAD [OUTFILE]` (range mode)
  - Inputs: BASE, HEAD (any git revision), optional OUTFILE path.
  - Output: exit 2 with `bad BASE: <BASE>` or `bad HEAD: <HEAD>` as the last line of standard error when that argument does not name a commit (a tree, a blob, or nothing; for a tree or a blob, git's own line `error: <arg>^{commit}: expected commit type, but the object dereferences to tree type` — or `blob type` — comes before it, because `--quiet` does not silence that message; tests (6) use a substring check for this reason); exit 3 with exactly `HEAD is not a descendant of BASE: <BASE>..<HEAD>` on standard error when BASE is not an ancestor of HEAD; in both cases no file is written and `sdd-workspace` is not called. Exit 0 otherwise; when the range BASE..HEAD holds zero commits (counted without the blind pathspecs), the line directly after `## Commits` is `Commits in range: none`.
  - Invariants: a commit is its own ancestor (BASE = HEAD exits 0); a BASE that is a merge commit HEAD descends from exits 0; a range whose commits change only blinded files exits 0 and does not carry the `Commits in range: none` line; an annotated tag as BASE exits 0; `--commits` mode is unchanged; the script still holds exactly four `git diff` / `git show` read lines, each with `"${no_helpers[@]}"`.
  - Verification: the new section `review-package (range guard, exit 3)` in `bash tests/sdd-scripts/run-tests.sh`, tests (1) to (7); the existing sections `review-package (range mode)`, `review-package (--commits mode)`, `review-package (reviewer blinding)` and `review-package ignores configured diff helper programs` stay green.
  - Interface: exit codes 0/2 and their messages are pinned by pre-existing tests (`bad BASE exits 2`); exit 3 and the new line are new and not externally pinned.
- Header comment of `review-package` (wording artifact)
  - Must convey: an empty range is not an error and its Commits section holds the one line `Commits in range: none`; exit 3 (nothing written) means HEAD does not descend from BASE; exit 2 means a usage error or a BASE or HEAD that does not name a commit.
  - Verification: `grep -c 'Commits in range: none' skills/subagent-driven-development/scripts/review-package` prints `2` (header comment and the `echo` line).
  - Sentence wording is free.

- [x] **Step 1: Write the failing test**

In `tests/sdd-scripts/run-tests.sh`, insert after the line `assert_eq "--commits with no SHAs exits 2" "$?" "2"` (end of the `review-package (--commits mode)` section) and before `bold "sdd-workspace (plan scoping)"`:

```bash

bold "review-package (range guard, exit 3)"

# A range whose HEAD does not descend from BASE gives a two-dot diff that
# shows the task's own work as deleted: the script exits 3 and writes
# nothing. An empty range (BASE = HEAD) is valid, and the package says so. A
# BASE or HEAD that is not a commit exits 2. The section uses its own fixture
# repository, so that the shared fixture keeps its state. Every call passes
# full 40-character SHAs, because the script echoes its arguments as given.
RG_REPO=$(mktemp -d)
: "${RG_REPO:?mktemp failed — refusing to run with an empty repo path}"
RG_REPO=$(cd "$RG_REPO" && pwd -P)
RG_OUT=$(mktemp -d)
: "${RG_OUT:?mktemp failed — refusing to run with an empty folder path}"
RG_ERR="$RG_OUT/stderr.txt"
cd "$RG_REPO"
git -c init.defaultBranch=main init --quiet
git config user.email "test@test"
git config user.name "test"
rg_commit() { # path content message -> prints the full SHA of the new commit
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" > "$1"
  git add "$1" && git commit --quiet -m "$3"
  git rev-parse HEAD
}
RG_C0=$(rg_commit a.txt a "c0: add a")
RG_C1=$(rg_commit b.txt b "c1: add b")
# A commit beside main, made without a checkout.
RG_SIDE=$(git commit-tree "$RG_C0^{tree}" -p "$RG_C0" -m side)
RG_C2=$(rg_commit docs/superpowers-orchestrator/x/x-review-log.md log "c2: change only a blinded file")
git branch feature "$RG_C2"
RG_C3=$(rg_commit m.txt m "c3: add m on main")
git checkout --quiet feature
RG_C4=$(rg_commit f.txt f "c4: add f on feature")
git merge --no-ff --quiet -m "merge main into feature" main
RG_M=$(git rev-parse HEAD)
RG_C5=$(rg_commit g.txt g "c5: add g")
assert_eq "range guard fixture: C3 and C4 exist, so the merge is not a fast-forward" \
  "$(git rev-list --parents -n 1 "$RG_M" | wc -w | tr -d ' ')" "3"

# (1) An empty range: exit 0, and the Commits section says so.
RG_PKG="$RG_OUT/empty.diff"
RG_STDOUT=$("$SCRIPTS/review-package" "$RG_C1" "$RG_C1" "$RG_PKG" 2>"$RG_ERR")
assert_eq "range guard (1): an empty range exits 0" "$?" "0"
assert_eq "range guard (1): the line after '## Commits' is 'Commits in range: none'" \
  "$(awk 'prev == "## Commits" { print; exit } { prev = $0 }' "$RG_PKG" 2>/dev/null)" "Commits in range: none"
if printf '%s\n' "$RG_STDOUT" | grep -qE ': 0 commit\(s\), [0-9]+ bytes$'; then
  ok "range guard (1): the summary says 0 commit(s)"
else
  bad "range guard (1): the summary says 0 commit(s) (got: $RG_STDOUT)"
fi

# (2) HEAD does not descend from BASE: exit 3, one stderr line, no file.
RG_PKG2="$RG_OUT/reversed.diff"
"$SCRIPTS/review-package" "$RG_SIDE" "$RG_C1" "$RG_PKG2" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (2): HEAD not descending from BASE exits 3" "$?" "3"
assert_eq "range guard (2): standard error is exactly the guard line" \
  "$(cat "$RG_ERR")" "HEAD is not a descendant of BASE: $RG_SIDE..$RG_C1"
[ ! -e "$RG_PKG2" ] && ok "range guard (2): no file at the given OUTFILE path" || bad "range guard (2): no file at the given OUTFILE path"
"$SCRIPTS/review-package" "$RG_SIDE" "$RG_C1" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (2): without OUTFILE it also exits 3" "$?" "3"
if ls "$RG_REPO/.superpowers/sdd"/review-*.diff > /dev/null 2>&1; then
  bad "range guard (2): no review-*.diff in the workspace"
else
  ok "range guard (2): no review-*.diff in the workspace"
fi
# Test (1) and the first call of test (2) pass OUTFILE, so no call before
# this one creates the workspace; the guard must stop the script before it
# calls sdd-workspace.
if [ -e "$RG_REPO/.superpowers" ]; then
  bad "range guard (2): exit 3 without OUTFILE does not call sdd-workspace"
else
  ok "range guard (2): exit 3 without OUTFILE does not call sdd-workspace"
fi

# (3) A task that changes only a blinded file is not an empty range.
RG_PKG3="$RG_OUT/blinded.diff"
RG_STDOUT=$("$SCRIPTS/review-package" "$RG_C1" "$RG_C2" "$RG_PKG3" 2>"$RG_ERR")
assert_eq "range guard (3): a range with only a blinded commit exits 0" "$?" "0"
assert_contains "range guard (3): the summary says 0 commit(s)" "$RG_STDOUT" ": 0 commit(s), "
assert_file_not_contains "range guard (3): the package does not say the range is empty" "$RG_PKG3" "Commits in range: none"

# (4) A BASE that is a merge commit HEAD descends from.
RG_PKG4="$RG_OUT/merge-base.diff"
"$SCRIPTS/review-package" "$RG_M" "$RG_C5" "$RG_PKG4" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (4): a merge commit as BASE exits 0" "$?" "0"
assert_file_contains "range guard (4): the package holds the task's hunk" "$RG_PKG4" "+g"

# (5) --commits mode does not change.
"$SCRIPTS/review-package" --commits "$RG_C5" --out "$RG_OUT/c5.diff" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (5): --commits with HEAD itself exits 0" "$?" "0"
"$SCRIPTS/review-package" --commits "$RG_SIDE" --out "$RG_OUT/side.diff" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (5): --commits with a commit that is not an ancestor of HEAD exits 0" "$?" "0"

# (6) A BASE or HEAD that is not a commit exits 2 and writes nothing.
RG_PKG6="$RG_OUT/tree.diff"
"$SCRIPTS/review-package" "$RG_C0^{tree}" "$RG_C5" "$RG_PKG6" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (6): a tree as BASE exits 2" "$?" "2"
assert_file_contains "range guard (6): standard error names the bad BASE" "$RG_ERR" "bad BASE: "
[ ! -e "$RG_PKG6" ] && ok "range guard (6): no file for a tree as BASE" || bad "range guard (6): no file for a tree as BASE"
# The blob goes by its object ID: after "<rev>:" git reads the rest as a path.
RG_BLOB=$(git rev-parse "$RG_C5:g.txt")
RG_PKG6B="$RG_OUT/blob.diff"
"$SCRIPTS/review-package" "$RG_C0" "$RG_BLOB" "$RG_PKG6B" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (6): a blob as HEAD exits 2" "$?" "2"
assert_file_contains "range guard (6): standard error names the bad HEAD" "$RG_ERR" "bad HEAD: "
[ ! -e "$RG_PKG6B" ] && ok "range guard (6): no file for a blob as HEAD" || bad "range guard (6): no file for a blob as HEAD"

# (7) An annotated tag as BASE still passes: ^{commit} follows the tag.
git tag -a t0 -m t0 "$RG_M"
RG_PKG7="$RG_OUT/tag.diff"
"$SCRIPTS/review-package" t0 "$RG_C5" "$RG_PKG7" > /dev/null 2>"$RG_ERR"
assert_eq "range guard (7): an annotated tag as BASE exits 0" "$?" "0"
assert_file_contains "range guard (7): the package holds the task's hunk" "$RG_PKG7" "+g"

cd "$REPO"
rm -rf "$RG_REPO" "$RG_OUT"
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL lines for `range guard (1): the line after '## Commits' is 'Commits in range: none'`, `range guard (2): HEAD not descending from BASE exits 3 (expected '3', got '0')`, the other (2) checks, and every (6) check — exit code, standard-error text and no file (a tree or a blob passes today's `rev-parse --verify`: today a tree as BASE exits 0 and writes a package, and a blob as HEAD exits 129 after the redirection has created the OUTFILE). Tests (3), (4), (5) and (7) pass.

- [x] **Step 3: Implement the change**

In `skills/subagent-driven-development/scripts/review-package`:

(a) Change 0 — replace lines 114-115 with:

```bash
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null || { echo "bad BASE: $base" >&2; exit 2; }
git rev-parse --verify --quiet "${head}^{commit}" >/dev/null || { echo "bad HEAD: $head" >&2; exit 2; }
```

(b) Change 1 — insert after those two lines, before `if [ $# -eq 3 ]; then` (so that nothing is written and `sdd-workspace` is not called on exit 3):

```bash

# Range guard (exit 3). When HEAD does not descend from BASE, the two-dot
# diff shows the task's own work as deleted. A commit is its own ancestor, so
# BASE = HEAD passes: an empty range is not an error, and the package says so.
git merge-base --is-ancestor "$base" "$head" || { echo "HEAD is not a descendant of BASE: ${base}..${head}" >&2; exit 3; }
# Counted without the blind pathspecs: a range whose commits change only
# blinded files is not an empty range.
range_count=$(git rev-list --count "${base}..${head}")
```

(c) Change 2 — directly after `  echo "## Commits"` inside the range-mode `{ … } > "$out"` block (the second `echo "## Commits"` of the file, not the one of `--commits` mode), insert:

```bash
  [ "$range_count" -gt 0 ] || echo "Commits in range: none"
```

(d) Change 3 — after header line 9 (`#   (named per range, so a re-review after fixes gets a distinct fresh file).`) add:

```bash
#   An empty range (BASE = HEAD) is not an error: the package is written,
#   and its Commits section holds the one line "Commits in range: none".
#   Exit 3 (nothing written): HEAD does not descend from BASE. Exit 2: a
#   usage error, or a BASE or HEAD that does not name a commit.
```

- [x] **Step 4: Run the test to verify it passes**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -3`
Expected: PASS — `Results: <n> passed, 0 failed` (the helper-program section still counts four `git diff`/`git show` read lines).

Run: `grep -c 'Commits in range: none' skills/subagent-driven-development/scripts/review-package`
Expected: `2`

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/scripts/review-package tests/sdd-scripts/run-tests.sh
git commit -m "fix(sdd): review-package exits 3 when HEAD does not descend from BASE" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 2/13"
```

---

### Task 3: the systematic-debugging example prints no secret value (A17)

**Files:**
- Modify: `skills/systematic-debugging/SKILL.md`

**Security flag:** `security` *(the change removes a secret value from example output; the new lines must pass both safety hooks for a secret-like variable name)*

**Does NOT cover:** line 66 (`codesign --sign "$IDENTITY" …`), which stays; the lines under "Check recent changes" pinned by `tests/codex/test-session-start-snapshot.sh:396-417`, which do not change. No automated suite covers these example lines (spec section 7.1); the check below runs the lines by hand.

**Contract:**
- Example lines 54 and 58 of `skills/systematic-debugging/SKILL.md` (wording artifact with runnable content)
  - Must convey: line 54 reports whether `IDENTITY` is set (`SET` / `UNSET`) without its value; line 58 reports whether `IDENTITY` is in the environment without its value.
  - Invariants: neither line prints the variable's value; neither line contains a `$1`-style token; both lines keep the two-space indent; `protect-secrets.js` `checkBashCommand` and `block-dangerous-commands.js` `checkCommand` return `blocked: false` for both lines with the name `IDENTITY` and with the name `API_TOKEN`; the old forms `${IDENTITY:+SET}${IDENTITY:-UNSET}` and `env | grep IDENTITY` are gone.
  - Verification: Step 2's commands (run the two lines with `IDENTITY=s3cret` and with `IDENTITY` unset; probe both hooks).
  - Sentence wording is free; the properties above bind.

- [x] **Step 1: Replace the two lines**

In `skills/systematic-debugging/SKILL.md`, replace line 54 (`  echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"`) with:

```bash
  echo "IDENTITY: $([ -n "${IDENTITY:-}" ] && echo SET || echo UNSET)"
```

and line 58 (`  env | grep IDENTITY || echo "IDENTITY not in environment"`) with:

```bash
  [ -n "${IDENTITY:-}" ] && echo "IDENTITY in environment" || echo "IDENTITY not in environment"
```

- [x] **Step 2: Run the lines and the hook probe**

Run: `T=$(mktemp) && sed -n '54p;58p' skills/systematic-debugging/SKILL.md > "$T" && IDENTITY=s3cret bash "$T"; env -u IDENTITY bash "$T"; rm -f "$T"`
Expected: four lines, in this order: `IDENTITY: SET`, `IDENTITY in environment`, `IDENTITY: UNSET`, `IDENTITY not in environment`. No line contains `s3cret`.

Run: `node -e 'const fs=require("fs");const p=require("./hooks/safety/protect-secrets.js");const b=require("./hooks/safety/block-dangerous-commands.js");const lines=fs.readFileSync("skills/systematic-debugging/SKILL.md","utf8").split("\n");for(const i of [53,57])for(const n of ["IDENTITY","API_TOKEN"]){const c=lines[i].split("IDENTITY").join(n);console.log(i+1,n,p.checkBashCommand(c).blocked,b.checkCommand(c).blocked)}'`
Expected: four lines `54 IDENTITY false false`, `54 API_TOKEN false false`, `58 IDENTITY false false`, `58 API_TOKEN false false`.

Run: `grep -cF -e '${IDENTITY:+SET}' -e 'env | grep IDENTITY' skills/systematic-debugging/SKILL.md`
Expected: `0`

Record the output of the first command in the task report (spec section 7.1).

- [x] **Step 3: Commit**

```bash
git add skills/systematic-debugging/SKILL.md
git commit -m "fix(systematic-debugging): the example prints no secret value" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 3/13"
```

---

### Task 4: SDD `SKILL.md` — the empty-package sentence and the exit-3 rules (C11, interactive and batched)

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** waves (Parallel Waves step 3 uses `--commits`, has no range, and does not change; its whole text is pinned); the final review at SDD `SKILL.md:521` (`MERGE_BASE` is always an ancestor of HEAD); the orchestrated batch controller (Task 10 gives it its own rule); the task reviewer template (no new text for an empty package). Exit 3 has no numbered **BLOCKED** remedy, also not item 5.

**Contract:**
- Core Flow step 3 pointer (SDD `SKILL.md:73`, wording artifact)
  - Must convey: when `review-package` exits 3, the controller follows **Exit 3** under **DONE** instead of dispatching the task reviewer.
  - Invariant: the pinned fragment ``dispatch the single task reviewer (`./task-reviewer-prompt.md`)`` stays unchanged.
  - Verification: v7.74.0 section of `tests/sdd-scripts/run-tests.sh`; `tests/reviewer-templates/run-tests.sh` section 20 stays green.
- **DONE** empty-package sentence and the **Exit 3** paragraph (SDD `SKILL.md:441`, wording artifact)
  - Must convey: a task that committed nothing gets a package whose Commits section holds `Commits in range: none`, and the task reviewer is dispatched with it; on exit 3 no task reviewer is dispatched for that range, the implementer is never asked to switch or reset the branch, the task is BLOCKED at once with no numbered remedy (also not item 5); interactive asks one question and re-runs the same call with the same BASE after a confirmed repair, asking again on a repeated exit 3; Batched Autonomous Mode ends the batch and journals the fixed blocking question with the full BASE, runs `review-package <the journaled BASE> HEAD` and the task review after a repair, records no new BASE, dispatches no implementer, and journals again on a repeated exit 3; an orchestrated batch controller follows its own prompt.
  - Invariants: the paragraph holds none of the counted phrases (`git commit`, `chore(plan)`, substring `tick`, the wave line); the **DONE_WITH_CONCERNS** paragraph is unchanged; `- Record BASE: `git rev-parse HEAD` before dispatching.` is unchanged.
  - Verification: v7.74.0 section of `tests/sdd-scripts/run-tests.sh` (folded needles and negative needles of spec section 7.1); the existing phrase counts of that suite stay green.
- Resume Procedure step 2 sentence (SDD `SKILL.md:426-430`, wording artifact)
  - Must convey: a task whose `## Open Issues` entry asks `Is the branch of task N repaired?` is neither marked complete nor reviewed in step 2; step 3 handles it; when the resume prompt answers that the branch is repaired, the task resumes at its task review from the journaled BASE (the **Exit 3** paragraph) before step 4, with no new BASE and no implementer dispatch — so step 4 and the Batch Loop's normal per-task flow never record a fresh BASE for it.
  - Verification: the two needles are checked inside the `### Resume Procedure` section extract.

- [x] **Step 1: Write the failing test**

In `tests/sdd-scripts/run-tests.sh`, directly before the two final lines `bold ""` and `bold "Results: $PASS passed, $FAIL failed"`, insert:

```bash

# ── Rules of v7.74.0 (design 2026-10-21-upstream-v7-fixes) ────────────────
# C11: review-package exits 3 when HEAD does not descend from BASE, and an
# empty range gets the line "Commits in range: none". The SDD skill tells the
# controller what to do with both, in each run mode. Later blocks of this
# section pin the Pre-Flight table (D4), the implementer rule for a failing
# test outside the task (C9) and the controller rule for unreadable test
# evidence (D8).
bold ""
bold "SDD SKILL.md and implementer: rules of v7.74.0"
V774_RESUME="$WAVE_DIR/v774-resume-procedure.txt"
awk '/^### Resume Procedure/ { f = 1 } f && /^## / { exit } f' "$SDD_SKILL_MD" > "$V774_RESUME"
for needle in \
  'When the script exits 3, follow **Exit 3** under **DONE** in Handling Implementer Status instead.' \
  'A task that committed nothing gets a package whose Commits section holds the line `Commits in range: none`; dispatch the task reviewer with it as with any package.' \
  '**Exit 3.** `review-package BASE HEAD` exits 3 when HEAD does not descend from BASE' \
  'or a commit at or before BASE was rewritten (an amend or a rebase), and no correct package exists' \
  'An orchestrated batch controller follows its own prompt for this exit.' \
  'Never dispatch the task reviewer for that range' \
  'by the rule of your run mode in the rest of this paragraph only' \
  'never ask the implementer to switch or reset the branch' \
  'no numbered remedy of **BLOCKED** applies, also not item 5 (advance to the next independent task)' \
  'after the user confirms that the branch is repaired, run the same `review-package BASE HEAD` call again with the same BASE. When it exits 3 again, ask the same question again.' \
  '`Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`' \
  'Resume Procedure step 3 presents that question to the user and stops.' \
  'After the user answers that the branch is repaired, run `review-package <the journaled BASE> HEAD` and the task review; record no new BASE and dispatch no implementer for the task.' \
  'When the script exits 3 again, journal the same question again and end; never pick a new BASE yourself.'; do
  assert_folded_contains "SKILL.md exit 3 and empty package: contains '$needle'" "$SDD_SKILL_MD" "$needle"
done
assert_folded_contains "SKILL.md Resume Procedure step 2: a task with the exit-3 question is left to step 3" "$V774_RESUME" \
  'A task whose entry under `## Open Issues` asks `Is the branch of task N repaired?` (**Exit 3** under **DONE**, Handling Implementer Status) is not marked complete here and is not reviewed here: step 3 handles its entry.'
assert_folded_contains "SKILL.md Resume Procedure step 2: an answered exit-3 question resumes at the task review from the journaled BASE" "$V774_RESUME" \
  'When the resume prompt answers that the branch is repaired, step 3 records the answer, and the task resumes at its task review from the journaled BASE, by the **Exit 3** paragraph, before step 4: record no new BASE and dispatch no implementer for it.'
for needle in 'by the rule of your run mode below only' 'Resume Procedure step 2 never marks such a task complete'; do
  if fold_file "$SDD_SKILL_MD" | grep -qF -- "$needle"; then
    bad "SKILL.md exit 3: does not contain the draft wording '$needle'"
  else
    ok "SKILL.md exit 3: does not contain the draft wording '$needle'"
  fi
done
assert_file_contains "SKILL.md Core Flow: Record BASE is unchanged" "$SDD_SKILL_MD" '- Record BASE: `git rev-parse HEAD` before dispatching.'
V774_DWC='**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they'"'"'re observations (e.g., "this file is getting large"), note them and proceed to review.'
assert_eq "SKILL.md DONE_WITH_CONCERNS: the paragraph is unchanged" \
  "$(grep -E '^\*\*DONE_WITH_CONCERNS:\*\*' "$SDD_SKILL_MD")" "$V774_DWC"
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL for every `SKILL.md exit 3 and empty package: contains …` needle and for the two Resume Procedure step 2 needles; the negative needles, `Record BASE` and `DONE_WITH_CONCERNS` pass.

- [x] **Step 3: Implement the change**

In `skills/subagent-driven-development/SKILL.md`:

(a) Line 73 (Core Flow, the bullet that starts ``- Run `scripts/review-package BASE HEAD` ``): append to the end of that line, after "with the brief, report, and package paths.", one space and:

> When the script exits 3, follow **Exit 3** under **DONE** in Handling Implementer Status instead.

(b) Line 441 (the **DONE:** paragraph, one line): append to the end of the line, after "In a wave, use `--commits` with the implementer's reported SHAs instead.", one space and:

> A task that committed nothing gets a package whose Commits section holds the line `Commits in range: none`; dispatch the task reviewer with it as with any package.

Then insert, after that line and one blank line, this new paragraph as a single line (the neighbouring status paragraphs are single lines; keep the blank line before **DONE_WITH_CONCERNS:**):

```markdown
**Exit 3.** `review-package BASE HEAD` exits 3 when HEAD does not descend from BASE: the branch was switched or reset during the task, or a commit at or before BASE was rewritten (an amend or a rebase), and no correct package exists (the script names the fault on standard error). Never dispatch the task reviewer for that range, and never ask the implementer to switch or reset the branch. Handle the task as **BLOCKED** at once, by the rule of your run mode in the rest of this paragraph only: no numbered remedy of **BLOCKED** applies, also not item 5 (advance to the next independent task), because this is a fault of the branch state, not of the implementer's capability, and the task's work is not yet reviewed. Interactive: ask the user one question that names the task, the range and the script's error line; after the user confirms that the branch is repaired, run the same `review-package BASE HEAD` call again with the same BASE. When it exits 3 again, ask the same question again. Batched Autonomous Mode: end the batch (Autonomy Policy) and journal under `## Open Issues`, marked blocking, this question: `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`, with N the task number and `<sha>` its BASE in full, because nothing else keeps BASE after /clear. Resume Procedure step 3 presents that question to the user and stops. After the user answers that the branch is repaired, run `review-package <the journaled BASE> HEAD` and the task review; record no new BASE and dispatch no implementer for the task. When the script exits 3 again, journal the same question again and end; never pick a new BASE yourself. An orchestrated batch controller follows its own prompt for this exit.
```

(c) Resume Procedure step 2 (lines 426-430, ending "mark its checkbox complete and advance."): append to the step, keeping its three-space indent, so that the end of the step reads:

```markdown
   mark its checkbox complete and advance. A task whose entry under
   `## Open Issues` asks `Is the branch of task N repaired?` (**Exit 3** under
   **DONE**, Handling Implementer Status) is not marked complete here and is
   not reviewed here: step 3 handles its entry. When the resume prompt
   answers that the branch is repaired, step 3 records the answer, and the
   task resumes at its task review from the journaled BASE, by the **Exit 3**
   paragraph, before step 4: record no new BASE and dispatch no implementer
   for it.
```

No new line may start with `4. ` or `5. ` (the review-gates suite anchors Core Flow step 4 by such lines).

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -3`
Expected: PASS — `Results: <n> passed, 0 failed` (the phrase counts `git commit|1`, `chore(plan)|1`, `tick|1` still hold).

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -1 && bash tests/review-gates/run-tests.sh 2>&1 | tail -1`
Expected: both print `Results: <n> passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md tests/sdd-scripts/run-tests.sh
git commit -m "feat(sdd): rules for an empty review package and for review-package exit 3" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 4/13"
```

---

### Task 5: SDD Pre-Flight Plan Review writes its scan as a table (D4)

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** `skills/orchestrating-development/batch-controller-prompt.md` (it follows the SDD section by reference; no change for D4); a check that a real scan writes a complete table (the table is written by an agent at run time; only the wording is pinned); rewriting the table after an `amend plan` ruling or on a restarted run of the same plan after an abandon (the "once per plan" rule skips the write when `.superpowers/sdd/preflight.md` exists; accepted, spec section 8 item 10). Upstream's sentences "Rule on everything you find …" and "the spec is the binding authority" are not ported.

**Contract:**
- `## Pre-Flight Plan Review` section of SDD `SKILL.md` (wording artifact)
  - Must convey: the scan result is a four-column table (`Row` = `path`, `name` or `task`; `Tasks`; `Compared`; `Found`) with one row per path that the **Files:** lists of two or more tasks name, one row per name that the text of two or more tasks mentions (each row listing every task that mentions it), and one row per task; `Found` is `none` unless the row shows a conflict of a kind the two bullet items list; every row whose `Found` is not `none` is a conflict handled by the existing rules; the table goes to `.superpowers/sdd/preflight.md` under `## Pre-flight scan` once per plan (the scan still runs every time); the table never decides a conflict and no answer is written into that file; a scan with no conflict proceeds without a question, and the table is still written.
  - Invariants: the two bullet items, `PREFLIGHT_CRITERION` and `RUBRIC_PARENTHETICAL` stay; the interactive batched-question paragraph and the Batched Autonomous Mode blocker sentence stay (the orchestrated rule lives in `batch-controller-prompt.md:150-159`, outside this section, and does not change); the section contains none of `` `Row` (`file` ``, `One row for every pair of tasks`, `Rule on everything you find`, `Rule on each conflict`, `record each ruling in the ledger`, `binding authority`, `proceed without comment`; no counted phrase of the SDD `SKILL.md` phrase counts.
  - Verification: the Pre-Flight block of the v7.74.0 section of `tests/sdd-scripts/run-tests.sh`; `tests/reviewer-templates/run-tests.sh` (section 12 pins `PREFLIGHT_CRITERION`, `RUBRIC_PARENTHETICAL`) stays green.

- [x] **Step 1: Write the failing test**

In `tests/sdd-scripts/run-tests.sh`, at the end of the v7.74.0 section (directly before the two final lines `bold ""` and `bold "Results: …"`), insert:

```bash
# D4: the Pre-Flight Plan Review writes what it compared as a table into its
# own file, once per plan. The table records the scan; it never decides a
# conflict.
V774_PREFLIGHT="$WAVE_DIR/v774-preflight.txt"
awk '/^## Pre-Flight Plan Review$/ { f = 1; print; next } f && /^## / { exit } f' "$SDD_SKILL_MD" > "$V774_PREFLIGHT"
if [ -s "$V774_PREFLIGHT" ]; then ok "SKILL.md Pre-Flight: the section extract is not empty"; else bad "SKILL.md Pre-Flight: the section extract is not empty"; fi
for needle in \
  "The scan's result is a table, not a verdict." \
  'Write the table to `.superpowers/sdd/preflight.md`, under the line `## Pre-flight scan`, once per plan: when that file already exists, run the scan and handle what it finds as before, but do not write the table again' \
  'it never decides a conflict' \
  'a path that the **Files:** lists of two or more tasks name, or a name that the text of two or more tasks mentions' \
  'The row lists every task that mentions that path or name' \
  'for a path, compare the edits that the listed tasks make at that path' \
  '`Row` (`path`, `name` or `task`)' \
  '`Found` is `none` unless the row shows a conflict of a kind that the two items above list' \
  'Every row whose `Found` is not `none` is a conflict'; do
  assert_folded_contains "SKILL.md Pre-Flight: contains '$needle'" "$V774_PREFLIGHT" "$needle"
done
for needle in '`Row` (`file`' 'One row for every pair of tasks' 'Rule on everything you find' 'Rule on each conflict' \
              'record each ruling in the ledger' 'binding authority' 'proceed without comment'; do
  if fold_file "$V774_PREFLIGHT" | grep -qF -- "$needle"; then
    bad "SKILL.md Pre-Flight: does not contain '$needle'"
  else
    ok "SKILL.md Pre-Flight: does not contain '$needle'"
  fi
done
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL for every positive Pre-Flight needle and for `does not contain 'proceed without comment'`.

- [x] **Step 3: Implement the change**

In `skills/subagent-driven-development/SKILL.md`, replace the whole `## Pre-Flight Plan Review` section (lines 203-216 at `fb222d38`, from the heading to the line ending "journal it and end the batch.)") with:

```markdown
## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for conflicts:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a
  defect (a test that asserts nothing, verbatim duplication of a logic block)

The scan's result is a table, not a verdict. One row for every link
between tasks: a path that the **Files:** lists of two or more tasks name,
or a name that the text of two or more tasks mentions (for example a
function, a type, a command or a file format). The row lists every task
that mentions that path or name, what you compared (the `Compared` cell
names the path or the name first), and what you found. For a name,
compare what each listed task says the name is or does: what a task that
defines it produces against what a task that uses it consumes; for a
path, compare the edits that the listed tasks make at that path. One row
for every task: whether its own text agrees with itself — the tests it
specifies against the code it specifies, the files it creates against the
files it changes later. A scan without these rows is not a scan you ran.
The table has four columns: `Row` (`path`, `name` or `task`), `Tasks`,
`Compared`, `Found`. `Found` is `none` unless the row shows a conflict of
a kind that the two items above list; then it is a short description of
that conflict. Every row whose `Found` is not `none` is a conflict, and
the rules below for what you find apply to it.

Write the table to `.superpowers/sdd/preflight.md`, under the line
`## Pre-flight scan`, once per plan: when that file already exists, run
the scan and handle what it finds as before, but do not write the table
again, also not after the plan was amended. The table records what you
compared; it never decides a conflict, and the answer to a conflict is not
written into that file.

Present everything you find to the user as one batched question — each
finding beside the plan text that mandates it, asking which governs —
before execution begins, not one interrupt per discovery mid-plan. If the
scan finds no conflict, proceed without a question (the table is still
written). The review loop still catches conflicts that appear only during
implementation. (In Batched Autonomous Mode a pre-flight conflict is a
blocker — journal it and end the batch.)
```

Keep the line `` `## Pre-flight scan`, once per plan: … `` starting with the backtick: a line that starts with `## ` would end the section extract of the test.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -3`
Expected: PASS — `Results: <n> passed, 0 failed`.

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -1`
Expected: `Results: <n> passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md tests/sdd-scripts/run-tests.sh
git commit -m "feat(sdd): the pre-flight scan writes a table to preflight.md once per plan" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 5/13"
```

---

### Task 6: an implementer reports a failing test outside its task and does not fix it (C9)

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/test-driven-development/SKILL.md`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** fix subagents (`skills/multi-code-review/fix-prompt.md` and the SDD fix subagent; accepted, spec section 8 item 9); a definition of "the full suite" per repository; any new controller, task-reviewer or batch-controller text (the concern takes the existing **DONE_WITH_CONCERNS** observation branch); a wave-specific sentence. The rule excludes a test that the task itself writes or changes, and a test that the brief or the controller's dispatch names as part of the task.

**Contract:**
- C9 rule in `implementer-prompt.md` (wording artifact, replaces lines 55-56)
  - Must convey: a test outside the task that fails and that the change did not cause is not fixed, unless the brief or the controller's dispatch names that test as part of the task; a test that the task writes or changes is the task's own; "did not cause" means the test neither is a file that the task changes nor imports or reads one; the implementer commits as usual, reports `DONE_WITH_CONCERNS` and names the test as an observation with its failing output and the reason.
  - Invariants: the text stays above `## Commit Messages`; it holds none of the counted phrases of the implementer template; the "run the full suite once before committing" sentence stays.
  - Verification: the C9 block of the v7.74.0 section of `tests/sdd-scripts/run-tests.sh`; the existing phrase counts and the whole-section pin of `## Commit Messages` stay green.
- C9 checklist items in `skills/test-driven-development/SKILL.md` (wording artifact, replaces line 96)
  - Must convey: the relevant suite passes apart from failures named under the next item; a test outside the task that fails and that the change did not cause is not fixed but named (status `DONE_WITH_CONCERNS` when the report carries a status, or in the reply to the user in the main session) with its failing output and the reason; the same "did not cause" criterion; a test that the task writes or changes is not outside the task; in the main session, the task is the change the user asked for.
  - Verification: the C9 block of the v7.74.0 section (line checks on the TDD file).

- [x] **Step 1: Write the failing test**

In `tests/sdd-scripts/run-tests.sh`, at the end of the v7.74.0 section (directly before the two final lines), insert:

```bash
# C9: an implementer that sees a test outside its task fail, and its change
# did not cause the failure, does not fix it: it commits as usual and names
# the test as an observation. The test-driven-development checklist carries
# the same reporting rule for the main session and executing-plans.
for needle in \
  "A test outside your task that fails, and that your change did not cause (a test that your task writes or changes is your task's own), is not fixed, unless your brief or the controller's dispatch names that test as part of your task." \
  'Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one.' \
  "Commit your work as usual, report DONE_WITH_CONCERNS and name the test as an observation, not as a doubt about your own work: give the test's failing output and the reason why your change did not cause it."; do
  assert_folded_contains "implementer-prompt.md C9: contains '$needle'" "$IMPLEMENTER_PROMPT_MD" "$needle"
done
TDD_SKILL_MD="$(dirname "$SDD_DIR")/test-driven-development/SKILL.md"
V774_TDD_PREFIX='- [ ] A test outside your task that fails, and that your change did not cause, is not fixed'
V774_TDD_SUFFIX='In the main session, your task is the change the user asked for.'
if grep -qxF -- '- [ ] Relevant suite passes, apart from failures named under the next item.' "$TDD_SKILL_MD"; then
  ok "TDD checklist: the suite item names the exception"
else
  bad "TDD checklist: the suite item names the exception"
fi
V774_TDD_LINE=$(grep -F -- "$V774_TDD_PREFIX" "$TDD_SKILL_MD" | head -n 1)
case "$V774_TDD_LINE" in
  "$V774_TDD_PREFIX"*"$V774_TDD_SUFFIX") ok "TDD checklist: the C9 item starts and ends as specified" ;;
  *) bad "TDD checklist: the C9 item starts and ends as specified (got: $V774_TDD_LINE)" ;;
esac
assert_contains "TDD checklist: the C9 item states when the change did not cause the failure" "$V774_TDD_LINE" \
  'Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one.'
if grep -qxF -- '- [ ] Relevant suite passes.' "$TDD_SKILL_MD"; then
  bad "TDD checklist: the old item '- [ ] Relevant suite passes.' is gone"
else
  ok "TDD checklist: the old item '- [ ] Relevant suite passes.' is gone"
fi
```

(Inside `case`, the quoted `"$V774_TDD_PREFIX"` matches literally, so its `[ ]` is not a pattern bracket.)

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL for the three `implementer-prompt.md C9` needles and the four TDD checklist checks.

- [x] **Step 3: Implement the change**

In `skills/subagent-driven-development/implementer-prompt.md`, replace lines 55-56:

```text
    While iterating, run the focused test for what you're changing; run the
    full suite once before committing, not after every edit.
```

with:

```text
    While iterating, run the focused test for what you're changing; run the
    full suite once before committing, not after every edit. A test outside
    your task that fails, and that your change did not cause (a test that
    your task writes or changes is your task's own), is not fixed, unless
    your brief or the controller's dispatch names that test as part of
    your task. Your change did not cause the failure when the test neither
    is a file that your task changes nor imports or reads one. Commit your
    work as usual, report DONE_WITH_CONCERNS and name the test as an
    observation, not as a doubt about your own work: give the test's
    failing output and the reason why your change did not cause it.
```

In `skills/test-driven-development/SKILL.md`, replace line 96 (`- [ ] Relevant suite passes.`) with these two lines:

```markdown
- [x] Relevant suite passes, apart from failures named under the next item.
- [x] A test outside your task that fails, and that your change did not cause, is not fixed: it is named in your report (status `DONE_WITH_CONCERNS` when your report carries a status), or in your reply to the user when you work in the main session, with the test's failing output and the reason why your change did not cause it. Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one. A test that your task writes or changes is not outside your task. In the main session, your task is the change the user asked for.
```

- [x] **Step 4: Run the test to verify it passes**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -3`
Expected: PASS — `Results: <n> passed, 0 failed` (the implementer phrase counts and the `## Commit Messages` whole-section pin still hold).

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/implementer-prompt.md skills/test-driven-development/SKILL.md tests/sdd-scripts/run-tests.sh
git commit -m "feat(sdd,tdd): a failing test outside the task is reported, not fixed" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 6/13"
```

---

### Task 7: four worker templates forbid subagent dispatch (D6)

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Modify: `skills/multi-code-review/reviewer-prompt.md`
- Modify: `skills/multi-doc-review/reviewer-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** `skills/requesting-code-review/code-reviewer.md`, `agents/code-reviewer.md`, `agents/red-team.md` (they run outside the review loops); prompts that a controller composes itself (the SDD security reviewer, the SDD fix subagent); `skills/multi-code-review/fix-prompt.md` (already carries the sentence; pinned by `FIX_RULE_CLAUSES`); every controller text (must keep dispatching workers).

**Contract:**
- `Do NOT dispatch subagents.` in the four worker templates (wording artifact)
  - Must convey: the worker does not dispatch subagents.
  - Invariants: in the two SDD templates the sentence follows "Your only job is the task described below." and the MUST-include sentence of SDD `SKILL.md:595` stays one unbroken piece inside the prompt body; in the two review-loop templates the sentence follows `Do NOT use the Skill tool.` at the end of the first bullet (no new bullet, so `CODE_SHARED_IN_PLACE` and `DOC_SHARED_IN_PLACE` stay green); none of the eight controller files of spec section 4.6 contains `Do NOT dispatch subagents`, folded.
  - Verification: new section `26. Worker templates forbid subagent dispatch; controller texts do not` in `bash tests/reviewer-templates/run-tests.sh`; sections 9 and 24 of that suite stay green.

- [x] **Step 1: Write the failing test**

In `tests/reviewer-templates/run-tests.sh`, after section 25 (after the line `assert_eq "the prompt templates without a fence are exactly the two named files" "$FENCELESS" "$EXPECTED_FENCELESS"`) and before the final `echo`, insert:

```bash

bold "26. Worker templates forbid subagent dispatch; controller texts do not"
# Upstream D6 (v7.0.0): a worker must not dispatch subagents of its own. The
# sentence goes into the first rule of exactly four worker templates. A
# controller must dispatch its workers, so no controller text may carry it.
NO_DISPATCH='Do NOT dispatch subagents.'
SDD_IMPLEMENTER="$ROOT/skills/subagent-driven-development/implementer-prompt.md"
LEAKAGE_SENTENCE='You are a focused subagent. Do NOT invoke any skills from the superpowers-orchestrator plugin. Do NOT use the Skill tool. Your only job is the task described below.'
for t in "$SDD_IMPLEMENTER" "$SDD_TASK_REVIEWER"; do
  name="${t#"$ROOT"/skills/}"
  body="$WORK/no-dispatch-$(basename "$t" .md).txt"
  extract_prompt_body "$t" > "$body"
  if [ -s "$body" ]; then ok "$name: prompt body extract is non-empty"; else bad "$name: prompt body extract is empty"; fi
  assert_folded_contains "$name: the sentence follows the only-job sentence" "$body" "Your only job is the task described below. $NO_DISPATCH"
  assert_folded_contains "$name: the MUST-include sentence of SDD SKILL.md stays unbroken" "$body" "$LEAKAGE_SENTENCE"
done
for t in "$CODE_PROMPT" "$DOC_PROMPT"; do
  name="${t#"$ROOT"/skills/}"
  body="$WORK/no-dispatch-$(basename "$(dirname "$t")").txt"
  extract_prompt_body "$t" > "$body"
  if [ -s "$body" ]; then ok "$name: prompt body extract is non-empty"; else bad "$name: prompt body extract is empty"; fi
  assert_folded_contains "$name: the sentence ends the first rule, after the Skill-tool sentence" "$body" "Do NOT use the Skill tool. $NO_DISPATCH"
done
for c in orchestrating-development/SKILL.md orchestrating-development/batch-controller-prompt.md \
         orchestrating-development/code-review-loop-prompt.md orchestrating-development/doc-review-loop-prompt.md \
         orchestrating-development/plan-writer-prompt.md multi-code-review/SKILL.md multi-doc-review/SKILL.md \
         subagent-driven-development/SKILL.md; do
  assert_folded_not_contains "$c: a controller text never forbids dispatching subagents" "$ROOT/skills/$c" 'Do NOT dispatch subagents'
done
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL for the four `the sentence follows …` / `the sentence ends the first rule …` checks; the unbroken-sentence and controller checks pass.

- [x] **Step 3: Implement the change**

`skills/subagent-driven-development/implementer-prompt.md` lines 15-17 and `skills/subagent-driven-development/task-reviewer-prompt.md` lines 23-25 — in each file replace the three lines of the first rule with:

```text
    You are a focused subagent. Do NOT invoke any skills from the
    superpowers-orchestrator plugin. Do NOT use the Skill tool. Your only job
    is the task described below. Do NOT dispatch subagents.
```

`skills/multi-code-review/reviewer-prompt.md` lines 31-32 — replace with:

```text
    - Do NOT invoke any skills from any plugin. Do NOT use the Skill
      tool. Do NOT dispatch subagents.
```

`skills/multi-doc-review/reviewer-prompt.md` line 33 — replace with:

```text
    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
      Do NOT dispatch subagents.
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -1`
Expected: PASS — `Results: <n> passed, 0 failed`.

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -1 && bash tests/fill-prompt/run-tests.sh 2>&1 | tail -1`
Expected: both print a results line with `0 failed`.

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/task-reviewer-prompt.md skills/multi-code-review/reviewer-prompt.md skills/multi-doc-review/reviewer-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(templates): four worker templates forbid subagent dispatch" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 7/13"
```

---

### Task 8: evidence the task reviewer cannot read is a ⚠️ item, not missing evidence (D8)

**Files:**
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Test: `tests/reviewer-templates/run-tests.sh`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** `skills/multi-code-review/reviewer-prompt.md` `## Tests` (pinned whole by `CODE_TESTS_SECTION`; its reviewer gets no implementer report); `batch-controller-prompt.md` (it follows "Handling Reviewer ⚠️ Items" by reference). The focused-test permission of the task reviewer's `## Tests` (for a specific doubt that reading the code raises) does not change; the new "no test" clause covers only evidence that cannot be read.

**Contract:**
- Unreadable-evidence paragraph in `task-reviewer-prompt.md` `## Tests` (wording artifact)
  - Must convey: evidence the reviewer cannot read is not missing evidence; the reviewer reads the report file again with the Read tool, paging; still missing or unreadable → a ⚠️ "Cannot verify from diff" item, never a ❌ finding that the evidence does not exist; no test is run to produce the evidence again, also not a focused one.
  - Invariants: the paragraph stands inside `## Tests` after `test output should be pristine.`, which stays; the focused-test sentence stays.
- ⚠️ output line of `task-reviewer-prompt.md` (wording artifact)
  - Must convey: the ⚠️ line also covers test evidence in the report that the reviewer could not read.
- "Handling Reviewer ⚠️ Items" in SDD `SKILL.md` (wording artifact)
  - Must convey: ⚠️ items include test evidence in the implementer's report that the reviewer could not read; for such an item the controller reads the report file with the Read tool, paging until no PARTIAL notice remains; still unreadable or absent → a real gap: the task goes back to the implementer to re-run the tests and write the command and its output into the report file, then re-review.
  - Invariant: no counted phrase of the SDD `SKILL.md` phrase counts.
- Verification for all three: new section `27. Task reviewer: unreadable evidence is a ⚠️ item` in `bash tests/reviewer-templates/run-tests.sh`, and the D8 block of the v7.74.0 section of `bash tests/sdd-scripts/run-tests.sh`; `CODE_TESTS_SECTION` stays green.

- [x] **Step 1: Write the failing tests**

In `tests/reviewer-templates/run-tests.sh`, after section 26 and before the final `echo`, insert:

```bash

bold "27. Task reviewer: unreadable evidence is a ⚠️ item"
# Upstream D8 (v7.0.0): a report or test evidence that the task reviewer
# cannot read must not be reported as missing evidence. The reviewer reads the
# report again, paging, and otherwise reports a ⚠️ item that the controller
# resolves.
TASK_TESTS_SECTION="$WORK/task-reviewer-tests-section.txt"
awk '$0 == "    ## Tests" { f = 1; print; next } f && /^    ## / { exit } f' "$SDD_TASK_REVIEWER" > "$TASK_TESTS_SECTION"
assert_folded_contains "task reviewer: evidence that cannot be read is not missing evidence" "$SDD_TASK_REVIEWER" \
  'Evidence you cannot read is not missing evidence.'
assert_folded_contains "task reviewer: no test is run to produce the evidence again" "$SDD_TASK_REVIEWER" \
  'do not run a test to produce the evidence again, also not a focused one'
assert_folded_contains "task reviewer: the ⚠️ output line names unreadable test evidence" "$SDD_TASK_REVIEWER" \
  'and test evidence in the report that you could not read'
assert_folded_contains "task reviewer: ## Tests keeps the focused-test permission" "$TASK_TESTS_SECTION" \
  'Run a test only when reading the code raises a specific doubt that no existing run answers'
PRISTINE_LINE="$(first_line_of "$TASK_TESTS_SECTION" 'test output should be pristine.')"
EVIDENCE_LINE="$(first_line_of "$TASK_TESTS_SECTION" 'Evidence you cannot read')"
if [ -n "$PRISTINE_LINE" ] && [ -n "$EVIDENCE_LINE" ] && [ "$EVIDENCE_LINE" -gt "$PRISTINE_LINE" ]; then
  ok "task reviewer: inside ## Tests, the new paragraph follows the pristine-output sentence"
else
  bad "task reviewer: inside ## Tests, the new paragraph follows the pristine-output sentence (pristine line '$PRISTINE_LINE', evidence line '$EVIDENCE_LINE')"
fi
assert_folded_not_contains "multi-code-review reviewer template: no unreadable-evidence rule (its reviewer gets no implementer report)" \
  "$CODE_PROMPT" 'Evidence you cannot read'
assert_folded_contains "SDD SKILL.md: ⚠️ items include unreadable test evidence" "$SDD_SKILL" \
  "and test evidence in the implementer's report that the reviewer could not read"
```

In `tests/sdd-scripts/run-tests.sh`, at the end of the v7.74.0 section (directly before the two final lines), insert:

```bash
# D8: the controller resolves a ⚠️ item about test evidence by reading the
# report file itself, paging; still unreadable or absent is a real gap.
assert_folded_contains "SKILL.md ⚠️ items: the controller reads the report file for an item about test evidence" "$SDD_SKILL_MD" \
  'For an item about test evidence, read the report file that holds the evidence with the Read tool'
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E 'FAIL|Results'; bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: section 27 fails on the four new-wording checks and the order check; the sdd-scripts suite fails on the `SKILL.md ⚠️ items` check.

- [x] **Step 3: Implement the change**

(a) `skills/subagent-driven-development/task-reviewer-prompt.md`, after line 107 (`    findings — test output should be pristine.`), inside `## Tests` and before `## Part 1: Spec Compliance`, add one blank line and:

```text
    Evidence you cannot read is not missing evidence. If the report or its
    test evidence looks cut off, or you cannot find a result that the
    report claims, read the report file again with the Read tool, paging
    as described above. If the evidence is still missing or cannot be
    read after that, report it as a ⚠️ "Cannot verify from diff" item —
    never as a ❌ finding that the evidence does not exist — and do not
    run a test to produce the evidence again, also not a focused one.
```

(b) Same file, the output lines at 176-178 — replace:

```text
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]
```

with:

```text
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and test evidence in the report that you could not read,
      and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]
```

(c) `skills/subagent-driven-development/SKILL.md`, section `## Handling Reviewer ⚠️ Items`: replace "requirements that live in unchanged code or span tasks." with "requirements that live in unchanged code or span tasks, and test evidence in the implementer's report that the reviewer could not read." (rewrap the paragraph as needed). At the end of the paragraph, after "send it back to the implementer and re-review.", append:

> For an item about test evidence, read the report file that holds the evidence with the Read tool, paging until no PARTIAL notice remains. If the evidence is still unreadable or absent, it is a real gap: send the task back to the implementer to re-run the tests and write the command and its output into the report file, then re-review.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -1 && bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -1`
Expected: PASS — both print `Results: <n> passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/task-reviewer-prompt.md skills/subagent-driven-development/SKILL.md tests/reviewer-templates/run-tests.sh tests/sdd-scripts/run-tests.sh
git commit -m "feat(sdd): unreadable test evidence is a warning item, not missing evidence" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 8/13"
```

---

### Task 9: multi-code-review stops on `review-package` exit 3 (C11, review loop)

**Files:**
- Modify: `skills/multi-code-review/SKILL.md`
- Modify: `skills/multi-code-review/reviewer-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** an empty range (already refused before round 1 by the bullet "Empty or invalid range …" and the BASE resolution at `SKILL.md:62-64`; a branch reset to exactly BASE during the loop gives an empty package that the reviewers read, as today); round step 1 itself (`SKILL.md:510-515`, unchanged); every other `review-package` failure (missing script, exit 2), which keeps the no-package fallback.

**Contract:**
- Exit-3 bullet in multi-code-review `SKILL.md` Error Handling (wording artifact)
  - Must convey: `review-package` exit 3 (HEAD does not descend from BASE) is fatal: the whole invocation stops and returns `BLOCKED: review range invalid — <the script's error line>`; nothing dispatched; the failed round owes no round entry; earlier rounds keep their dispositions; the no-package fallback never applies to exit 3.
  - Invariants: the bullet stands directly before the fallback bullet, whose first line ``- `review-package` missing or failing → dispatch with `[PACKAGE_FILE]` =`` is unchanged; the bullet names no `git diff` command (`CODE_SKILL_PROSE_MENTIONS=1` stays true).
- Placeholder legend of `reviewer-prompt.md` (wording artifact)
  - Must convey: the no-package value is passed when the script is missing or fails with an exit code other than 3; on exit 3 nothing is dispatched (SKILL.md, Error Handling).
- Verification for both: new section `28. multi-code-review: review-package exit 3 is fatal` in `bash tests/reviewer-templates/run-tests.sh`; the existing worklist-row-54 block (`CODE_FALLBACK_RANGE`, `CODE_SKILL_PROSE_MENTIONS`) stays green.

- [x] **Step 1: Write the failing test**

In `tests/reviewer-templates/run-tests.sh`, after section 27 and before the final `echo`, insert:

```bash

bold "28. multi-code-review: review-package exit 3 is fatal"
# review-package exits 3 when HEAD does not descend from BASE: the branch
# changed under the loop, and no correct package exists. The loop stops
# instead of using the no-package fallback.
CODE_FALLBACK_FIRST="$(first_line_of "$CODE_SKILL" '- `review-package` missing or failing')"
if [ -n "$CODE_FALLBACK_FIRST" ] && [ "$CODE_FALLBACK_FIRST" -gt 1 ]; then
  CODE_ABOVE_FALLBACK="$(sed -n "$((CODE_FALLBACK_FIRST - 1))p" "$CODE_SKILL")"
else
  CODE_ABOVE_FALLBACK=""
fi
case "$CODE_ABOVE_FALLBACK" in
  *'to exit 3.') ok "multi-code-review SKILL.md: the exit-3 bullet stands directly before the fallback bullet" ;;
  *) bad "multi-code-review SKILL.md: the exit-3 bullet stands directly before the fallback bullet (line above: '$CODE_ABOVE_FALLBACK')" ;;
esac
CODE_EXIT3_BULLET="$WORK/code-exit3-bullet.md"
awk '/^- `review-package` exits 3/ { on = 1; print; next } on && /^- / { exit } on { print }' "$CODE_SKILL" > "$CODE_EXIT3_BULLET"
for needle in \
  '- `review-package` exits 3 (HEAD does not descend from BASE: the branch changed under the loop)' \
  'fatal: stop the whole invocation and return' \
  '`BLOCKED: review range invalid — <the script'"'"'s error line>`' \
  'nothing dispatched' \
  'The failed round owes no round entry' \
  'never applies to exit 3'; do
  assert_folded_contains "multi-code-review SKILL.md exit-3 bullet: contains '$needle'" "$CODE_EXIT3_BULLET" "$needle"
done
assert_folded_contains "multi-code-review reviewer template: the no-package value excepts exit 3" "$CODE_PROMPT" \
  'fails with an exit code other than 3'
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL for the position check, the six bullet needles and the legend needle.

- [x] **Step 3: Implement the change**

(a) `skills/multi-code-review/SKILL.md`, Error Handling: insert between the bullet "- Empty or invalid range (BASE = HEAD, no merge-base, or BASE does not resolve to a commit) → stop and report; nothing dispatched." (lines 1760-1761) and the fallback bullet that starts at line 1762:

```markdown
- `review-package` exits 3 (HEAD does not descend from BASE: the branch
  changed under the loop) → fatal: stop the whole invocation and return
  `BLOCKED: review range invalid — <the script's error line>`; nothing
  dispatched. The failed round owes no round entry, because no reviewer
  report of it was received; the entries of earlier rounds keep their
  dispositions. The no-package fallback of the next bullet never applies
  to exit 3.
```

(b) `skills/multi-code-review/reviewer-prompt.md`, placeholder legend (lines 265-272, outside the prompt block): replace "When the script is missing or failing," (line 267) with "When the script is missing or fails with an exit code other than 3," and append after "no-package form." (line 272) the sentence " On exit 3 nothing is dispatched (SKILL.md, Error Handling)." Rewrap the bullet's continuation lines with the same two-space indent.

- [x] **Step 4: Run the test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -1`
Expected: PASS — `Results: <n> passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add skills/multi-code-review/SKILL.md skills/multi-code-review/reviewer-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-code-review): review-package exit 3 stops the loop" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 9/13"
```

---

### Task 10: the batch controller's exit-3 rule and start check (C11, orchestrated)

**Files:**
- Modify: `skills/orchestrating-development/batch-controller-prompt.md`
- Test: `tests/orchestrating-development/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** a ruling for exit 3 (no `### Question <k>` or `### Conflict <k>` section is written, so the orchestrator treats the return as a controller failure, retries once and stops under its Major-Error Stop Policy); a ledger with no completed line (the start check is skipped); the abandon step of `orchestrating-development/SKILL.md` (unchanged; a stale ledger from an abandoned run makes the start check stop, accepted in spec section 8 item 10); D4 and C9 (no batch-controller change for them); the rest of Deviation 4 from "when you start, set REVIEW_BASE = …".

**Contract:**
- Exit-3 rule in `batch-controller-prompt.md` (replaces lines 70-71, wording artifact)
  - Must convey: when `review-package` exits 3, HEAD does not descend from BASE (branch switched or reset during the task, or a commit at or before BASE rewritten); dispatch no task reviewer and no implementer for that range, write no question or conflict section, and return `BLOCKED task=<n>: review range invalid — <the script's error line>`; the orchestrator reads it as a controller failure, retries once, then stops under its Major-Error Stop Policy.
- Deviation 4 start check (replaces the first line of item 4 at line 197, wording artifact)
  - Must convey: after `sdd-workspace PLAN_FILE` and before the Pre-Flight Plan Review and any dispatch, when the ledger holds a completed line, run `git merge-base --is-ancestor <head7> HEAD` with `<head7>` from the last completed ledger line in file order; on a non-zero exit (branch switched, reset or rewritten, or a ledger left from an abandoned or earlier run of this plan) dispatch nothing, write no question or conflict section, and return the fixed start-check line with `<n>` the first unchecked task of the task list; with no completed ledger line, skip the check; then continue with the existing item text.
  - Invariants (both artifacts): item 4 still starts with `4. Mid-task crash recovery:`; the continuation joins "Then, for each assigned task that is unchecked" with the unchanged "when you start, set REVIEW_BASE = …"; no bracketed uppercase token; no Core Flow step named; `Task <n>: complete commits <base7>..<head7>` stays in the block.
  - Verification: new section `5f.` in `bash tests/orchestrating-development/run-tests.sh`; `bash tests/in-run-rulings/run-tests.sh`, `bash tests/fill-prompt/run-tests.sh` and `bash tests/review-gates/run-tests.sh` stay green.

- [x] **Step 1: Write the failing test**

In `tests/orchestrating-development/run-tests.sh`, after section 5e (after the assertion `assert_folded_not_contains "batch-controller-prompt.md item 5: no longer says 'SDD mandates'" …` and its needle line) and before `bold "6. The Resume Answer section: …"`, insert:

```bash

bold "5f. review-package exit 3 and the start check: a BLOCKED return with no question section"
# C11 of the v7.74.0 design: exit 3 of review-package means HEAD does not
# descend from BASE. No ruling can repair a branch state, so the batch
# controller returns BLOCKED with no Question or Conflict section, and the
# orchestrator stops under its Major-Error Stop Policy. At its start, the
# batch controller checks that the branch still descends from the HEAD of
# the last completed ledger line, so a retried dispatch stops before any
# dispatch when completed work was lost.
for needle in \
  'When `review-package` exits 3, HEAD does not descend from BASE: the branch was switched or reset during the task, or a commit at or before BASE was rewritten (an amend or a rebase).' \
  'Dispatch no task reviewer and no implementer for that range' \
  'write no `### Question <k>` or `### Conflict <k>` section for it, and return `BLOCKED task=<n>: review range invalid — <the script'"'"'s error line>`.' \
  'the orchestrator reads this return as a controller failure, retries the identical dispatch once, and then stops under its Major-Error Stop Policy' \
  '4. Mid-task crash recovery: first, after `sdd-workspace PLAN_FILE` and before the Pre-Flight Plan Review and before any dispatch, check the branch.' \
  'run `git merge-base --is-ancestor <head7> HEAD`, with `<head7>` the HEAD recorded by the last completed ledger line in file order' \
  'or the ledger is left from an abandoned or earlier run of this plan' \
  '`BLOCKED task=<n>: review range invalid — HEAD does not descend from the last completed ledger HEAD <head7> (branch switched, reset or rewritten, or ledger left from an earlier run of this plan)`' \
  'with `<n>` the first unchecked task of your task list' \
  'With no completed ledger line, skip this check.' \
  'Then, for each assigned task that is unchecked when you start, set REVIEW_BASE' \
  'Task <n>: complete commits <base7>..<head7>'; do
  assert_folded_contains "batch-controller-prompt.md exit 3 and start check: contains '$needle'" "$BATCH_BLOCK" "$needle"
done
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: eleven FAIL lines, one for each needle except the last; `Task <n>: complete commits <base7>..<head7>` already passes (the `Then, for each assigned task …` needle fails too, because today's text has no "Then,").

- [x] **Step 3: Implement the change**

(a) `skills/orchestrating-development/batch-controller-prompt.md` lines 70-71 — replace:

```text
    `review-package BASE HEAD` per review (BASE = the HEAD you record
    before dispatching that task's implementer).
```

with:

```text
    `review-package BASE HEAD` per review (BASE = the HEAD you record
    before dispatching that task's implementer). When `review-package`
    exits 3, HEAD does not descend from BASE: the branch was switched or
    reset during the task, or a commit at or before BASE was rewritten
    (an amend or a rebase). Dispatch no task reviewer and no implementer
    for that range, write no `### Question <k>` or `### Conflict <k>`
    section for it, and return
    `BLOCKED task=<n>: review range invalid — <the script's error line>`.
    A wrong branch state is not an open item: without such a section
    the orchestrator reads this return as a controller failure, retries
    the identical dispatch once, and then stops under its Major-Error
    Stop Policy.
```

(b) Same file, line 197 — replace the first line of Deviation 4,
`    4. Mid-task crash recovery: for each assigned task that is unchecked`, with:

```text
    4. Mid-task crash recovery: first, after `sdd-workspace PLAN_FILE`
       and before the Pre-Flight Plan Review and before any dispatch,
       check the branch. When the ledger holds a completed line, run
       `git merge-base --is-ancestor <head7> HEAD`, with `<head7>` the
       HEAD recorded by the last completed ledger line in file order. A
       non-zero exit has one of two causes: the branch was switched,
       reset, or rewritten by an amend or a rebase, so it no longer holds
       work that the ledger records as complete; or the ledger is left
       from an abandoned or earlier run of this plan. Then dispatch
       nothing, write no `### Question <k>` or `### Conflict <k>`
       section, and return
       `BLOCKED task=<n>: review range invalid — HEAD does not descend from the last completed ledger HEAD <head7> (branch switched, reset or rewritten, or ledger left from an earlier run of this plan)`,
       with `<n>` the first unchecked task of your task list. With no
       completed ledger line, skip this check. Then, for each assigned
       task that is unchecked
```

The next existing line (`       when you start, set REVIEW_BASE = the HEAD recorded by the last`) stays unchanged and continues the sentence.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | tail -1`
Expected: PASS — `Results: <n> passed, 0 failed`.

Run: `bash tests/in-run-rulings/run-tests.sh 2>&1 | tail -1 && bash tests/fill-prompt/run-tests.sh 2>&1 | tail -1 && bash tests/review-gates/run-tests.sh 2>&1 | tail -1`
Expected: each prints a results line with `0 failed`.

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/batch-controller-prompt.md tests/orchestrating-development/run-tests.sh
git commit -m "feat(orchestration): batch controller stops on review-package exit 3 and checks the branch at start" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 10/13"
```

---

### Task 11: GitHub Copilot CLI is marked as no longer supported

**Files:**
- Modify: `README.md`
- Modify: `docs/guide/README.md`
- Modify: `docs/platforms/codex.md`
- Modify: `.codex/INSTALL.md`
- Test: `tests/orchestrating-development/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** deleting any Copilot CLI section or file; the Copilot sentences listed in spec section 2 "Non-goals" (`skills/worklog/SKILL.md`, `skills/pickup/SKILL.md`, `skills/orchestrating-development/SKILL.md`, `docs/guide/README.md` lines 50-53, 636-638, 1247, 1459, 1481, `docs/platforms/codex.md:15`, `.codex/INSTALL.md:13`, `.opencode/INSTALL.md:6`, `RELEASE-NOTES.md` lines 3-4, `docs/research/claude-code-mods.md:361`); the Copilot CLI session-start fix (rejected, spec section 5).

**Contract:**
- Copilot CLI status in `README.md`, `docs/guide/README.md` §1, `docs/platforms/codex.md:9`, `.codex/INSTALL.md:7` (wording artifact)
  - Must convey: Copilot CLI is no longer supported since 2026-10-21; Claude Code is the platform to use; the history (Copilot CLI used up to v7.13.0) and every file stay; no reason is given.
  - Invariants: the badge names only Claude Code; the `### GitHub Copilot CLI` section keeps its heading and status line and gains the note; the sentences pinned by section 12 of `tests/orchestrating-development/run-tests.sh` stay; none of `README.md`, `docs/platforms/codex.md` and `.codex/INSTALL.md` holds `Use Claude Code or GitHub Copilot CLI.` any more (documents under `docs/superpowers-orchestrator/` that quote the old sentence stay).
  - Verification: the two new section-12 assertions; Step 4's grep commands and its folded count of the `README.md:14` and `:461-463` phrases.

- [x] **Step 1: Write the failing test**

In `tests/orchestrating-development/run-tests.sh`, at the end of section 12 (after the assertion whose needle is `'On any other platform, Copilot CLI included, the skill refuses with one line.'`) and before the final `echo`, insert:

```bash
# 2026-10-21 (user decision): GitHub Copilot CLI is no longer a supported
# platform. The badge names Claude Code only, and the Copilot CLI section of
# the README carries the note. The note is a quote block, so its later lines
# start with "> " and are checked as one whole line, not folded.
assert_file_not_contains "platform: the README badge no longer names Copilot CLI" "$README_FILE" 'Copilot_CLI-white'
assert_file_has_line "platform: the README Copilot CLI section carries the no-longer-supported note" "$README_FILE" \
  '> **No longer supported (since 2026-10-21).** GitHub Copilot CLI is no'
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: two FAIL lines (badge, note).

- [x] **Step 3: Implement the change**

Apply each row (text located by its words; line numbers are those of `fb222d38`):

| File:line | Today | New text |
|---|---|---|
| `README.md:3` | the badge `USE_WITH-Claude_Code_%7C_Copilot_CLI` | `[![AI Coding Agents](https://img.shields.io/badge/USE_WITH-Claude_Code-white?style=for-the-badge)]()` |
| `README.md:14` | "(Claude Code and GitHub Copilot CLI, which are the two it has been used with — Copilot CLI only up to v7.13.0, so later releases are untested there; Cursor and OpenCode integrations exist but are untested, and Codex is no longer supported — see [Platform status](#installation))" | "(Claude Code and GitHub Copilot CLI, which are the two it has been used with — Copilot CLI only up to v7.13.0; Cursor and OpenCode integrations exist but are untested, and Copilot CLI and Codex are no longer supported — see [Platform status](#installation))" |
| `README.md:54` | "In Claude Code or Copilot CLI, start a new chat and paste:" | "In Claude Code, start a new chat and paste:" |
| `README.md:461-463` | "… **Copilot CLI** was last used with v7.13.0 …" | "… **Copilot CLI** (no longer supported since 2026-10-21) was last used with v7.13.0 …"; rewrap; the rest of the paragraph (`:461-472`) stays |
| `README.md:525` (Codex note) | "Use Claude Code or GitHub Copilot CLI." | "Use Claude Code." |
| `README.md:622-624` | heading `### GitHub Copilot CLI`, blank line, the status line | insert the note below between the heading and the status line, with one blank line on each side; the section stays |
| `docs/guide/README.md:33-34` (§1) | "(Claude Code, Cursor, OpenCode, GitHub Copilot CLI, and Codex, which is no longer supported)" | "(Claude Code, Cursor and OpenCode; GitHub Copilot CLI and Codex are no longer supported)" |
| `docs/platforms/codex.md:9` | "… Use Claude Code or GitHub Copilot CLI." | "… Use Claude Code." |
| `.codex/INSTALL.md:7` | "… Use Claude Code or GitHub Copilot CLI." | "… Use Claude Code." |

The note for `README.md` `### GitHub Copilot CLI` (a quote block; every line keeps its `> ` prefix):

```markdown
> **No longer supported (since 2026-10-21).** GitHub Copilot CLI is no
> longer a supported platform of Superpowers Orchestrator. The Copilot CLI
> text in this section and in the skills stays in the repository, but
> Copilot CLI is no longer maintained or reviewed as a platform. Use
> Claude Code.
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | tail -1`
Expected: PASS — `Results: <n> passed, 0 failed` (the existing section-12 sentences still match).

Run: `grep -c 'Use Claude Code or GitHub Copilot CLI' README.md docs/platforms/codex.md .codex/INSTALL.md`
Expected: `README.md:0`, `docs/platforms/codex.md:0`, `.codex/INSTALL.md:0`.

Run: `grep -c 'In Claude Code or Copilot CLI' README.md; awk '{ l = $0; sub(/^[ \t]+/, "", l); sub(/[ \t]+$/, "", l); printf "%s ", l }' docs/guide/README.md | grep -oF -- 'GitHub Copilot CLI and Codex are no longer supported' | wc -l | tr -d ' '`
Expected: `0`, then `1` (the guide is folded first, because the §1 parenthetical wraps across lines 33-34).

Run (folds `README.md` into one line, because the `:461-463` row is rewrapped, then counts each phrase of the `:14` and `:461-463` rows):

```bash
for n in 'Copilot CLI and Codex are no longer supported' '(no longer supported since 2026-10-21) was last used with v7.13.0'; do
  printf '%s: ' "$n"
  awk '{ l = $0; sub(/^[ \t]+/, "", l); sub(/[ \t]+$/, "", l); printf "%s ", l }' README.md | grep -oF -- "$n" | wc -l | tr -d ' '
done
```

Expected: each phrase prints `1`.

- [x] **Step 5: Commit**

```bash
git add README.md docs/guide/README.md docs/platforms/codex.md .codex/INSTALL.md tests/orchestrating-development/run-tests.sh
git commit -m "docs(platforms): GitHub Copilot CLI is no longer supported" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 11/13"
```

---

### Task 12: user guide sections for the v7.74.0 behaviour

**Files:**
- Modify: `docs/guide/README.md`

**Security flag:** `none`

**Does NOT cover:** §1 (done in Task 11); the systematic-debugging example (A17) and the task reviewer's evidence rules (D8), which no guide section quotes; "When the review loop's prompt delivery fails" (`:414`), which does not describe the no-package fallback and does not change.

**Contract:**
- Four guide passages (wording artifact)
  - §3 Stage 2 must convey: since v7.74.0 the Pre-Flight Plan Review writes what it compared as a table into `.superpowers/sdd/preflight.md` (one row per path named by the **Files:** lists of two or more tasks, one per name mentioned by two or more tasks, each listing every task that mentions it, and one per task); the scan runs at every start, the table is written once per plan; the table only records; a conflict is asked (interactive), ends the batch (batched) or goes to the orchestrator (orchestrated).
  - §3 Stage 3 must convey: the C9 implementer rule with its exception and its "did not cause" criterion, and that the controller proceeds to review and the task reviewer decides; the TDD checklist in the main session; the batched exit-3 blocking question `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`, the next session's question and stop, the review from that BASE after a repair, and the repeated journal entry; the interactive question and its repetition; `Commits in range: none` for a task that committed nothing; implementers and the reviewers of SDD and of the two review loops dispatch no subagents.
  - §4 must convey: the orchestrated exit-3 return `BLOCKED task=<n>: review range invalid — <the script's error line>` with no question; one retry; the start check against the last completed ledger HEAD; its two causes and two repairs (repair the branch and resume; or remove or archive `.superpowers/sdd/progress.md` and `.superpowers/sdd/preflight.md` and start again); the review-loop return `BLOCKED: review range invalid — <the script's error line>`.
  - §9 must convey: before v7.74.0 every SDD script call rewrote `.superpowers/sdd/.gitignore`; since v7.74.0 it is created only when missing or empty; a committed ledger is part of the branch, is seen by the whole-branch reviewers, and makes an orchestrated run stop at the next batch boundary or at Phase 5.
  - Verification: Step 2's grep commands; `bash tests/orchestrating-development/run-tests.sh` stays green (its guide pins in section 12).

- [x] **Step 1: Write the four passages**

(a) **§3 Stage 2** — in the paragraph that ends "read the `Owed:` list yourself." (line 321), append to the same paragraph:

> Since v7.74.0 the Pre-Flight Plan Review writes what it compared as a table into `.superpowers/sdd/preflight.md`: one row for each path that the **Files:** lists of two or more tasks name, and one row for each name that the text of two or more tasks mentions, each row listing every task that mentions that path or name; and one row for each task. It runs the scan at every start, as before, but writes the table only once per plan. The table only records the scan: a conflict is still asked of you (interactive), ends the batch (batched mode), or goes to the orchestrator (orchestrated run).

(b) **§3 Stage 3** — after the paragraph that ends "moment the task completes." (line 350), add one blank line and this paragraph:

> Since v7.74.0 an implementer that sees a test outside its task fail, and its own change did not cause the failure, does not fix it, unless its brief or its dispatch names that test as part of the task. Its change did not cause the failure when the test neither is a file that the task changes nor imports or reads one. It commits its work as usual, reports `DONE_WITH_CONCERNS`, and names the test as an observation, with the test's failing output and that reason. The controller therefore proceeds to the task review, and the task reviewer decides whether the failure is a finding, so a fix, when one is made, goes through the review gate. In the main session, the test-driven development checklist has the failure named in the reply to you. In batched mode, a task whose review range is wrong ends the batch with the blocking question `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)` under `## Open Issues`. The next session asks you that question and stops; after you answer that the branch is repaired, it reviews that task from that BASE before it goes on. If the range is still wrong, it writes the same question under `## Open Issues` again and stops. In interactive mode the controller asks you at once, and asks again after each repair that leaves the range wrong. A task that committed nothing still gets its task review; its review package then says `Commits in range: none`. Implementers and the reviewers of SDD and of the two review loops do not dispatch subagents of their own.

(c) **§4 "When it stops instead of finishing"** (heading at line 827) — insert, before the paragraph that starts "A review finding that merely differs" (line 857), this paragraph followed by one blank line:

> Since v7.74.0, when a task's review range is wrong — the branch HEAD no longer descends from the commit recorded before the task, because the branch was switched, reset, or rewritten by an amend or a rebase — the batch controller returns `BLOCKED task=<n>: review range invalid — <the script's error line>` with no question. The orchestrator treats that return as a major error and retries the batch once. The retried controller first checks that the branch still descends from the HEAD of the last completed task in the ledger `.superpowers/sdd/progress.md`; when it does not, the retry returns the same kind of line at once, and the orchestrator stops and reports the error. That check stops for one of two causes. Either the branch was switched, reset, or rewritten: repair the branch, then resume the run. Or the ledger is left from an abandoned or earlier run of the same plan (abandoning a run deletes its branch, but not the ledger): remove or archive `.superpowers/sdd/progress.md`, and the stale `.superpowers/sdd/preflight.md` with it, then start the run again. A review loop whose range turns wrong in the same way stops the whole invocation and returns `BLOCKED: review range invalid — <the script's error line>`.

(d) **§9 Troubleshooting** — after the entry "**I edited a skill but behavior didn't change.** …" (ending "then start a fresh session (§1)." at line 1543), add one blank line and:

> **My committed `.superpowers/sdd/.gitignore` was reset to `*`.** Before v7.74.0 every SDD script call rewrote the file. Since v7.74.0 the scripts create it only when it is missing or empty, so a version you commit stays as you wrote it. If you also commit the ledger `progress.md`, it is part of the branch, the whole-branch reviewers see it, and an orchestrated run stops at the next batch boundary or at Phase 5, because every ledger write leaves the working tree dirty.

Insert each passage as a plain paragraph, without the `> ` prefix: the quote marks only delimit the text in this plan (unlike the README note of Task 11, which is a quote block in the README). Wrap the new prose at the line width of the surrounding paragraphs.

- [x] **Step 2: Verify the passages**

Run (folds the guide into one line, then counts each phrase):

```bash
for n in 'writes the table only once per plan' \
         'Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)' \
         'review range invalid — <the script' \
         'remove or archive `.superpowers/sdd/progress.md`' \
         'was reset to `*`.**' \
         'Commits in range: none' \
         'do not dispatch subagents of their own'; do
  printf '%s: ' "$n"
  awk '{ l = $0; sub(/^[ \t]+/, "", l); sub(/[ \t]+$/, "", l); printf "%s ", l }' docs/guide/README.md | grep -oF -- "$n" | wc -l | tr -d ' '
done
```

Expected: every phrase prints a count of at least `1` (`review range invalid — <the script` prints `2`).

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | tail -1`
Expected: `Results: <n> passed, 0 failed`.

- [x] **Step 3: Commit**

```bash
git add docs/guide/README.md
git commit -m "docs(guide): v7.74.0 pre-flight table, failing tests outside a task, review range stops" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 12/13"
```

---

### Task 13: release v7.74.0 and record the accepted limits

**Files:**
- Modify: `VERSION`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugin.universal.yaml`
- Modify: `README.md`
- Modify: `RELEASE-NOTES.md`
- Modify (local, never committed): `<main checkout>/docs/orchestration-issues.md`

**Security flag:** `none`

**Does NOT cover:** porting the five Windows-only upstream fixes (A10, A11, A12, E7, EPIPE; recorded as accepted limits only); `tests/codex/post-push-validation-checklist.md` (no Codex-facing behaviour changes); `docs/FORK-IMPROVEMENTS.md`; the update of the user's memory file `platforms-actually-used.md`, which the main session does after the release, outside the repository (spec section 9). The accepted-limits step does nothing when the issues log is absent in the main checkout or already holds `(upstream A10)`.

**Contract:**
- Version bump (wording artifact)
  - Invariant: `7.74.0` in `VERSION`, `.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:13`, `plugin.universal.yaml:7`, the README version badge (line 6) and the two `v6.7.0–v7.74.0` ranges (lines 22 and 24); `7.73.1` remains in none of these files.
  - Verification: Step 2's grep commands.
- `RELEASE-NOTES.md` entry `## v7.74.0` (wording artifact)
  - Must convey: the three-line summary of spec section 4.10 (Problem, Change, Effect; near 100 words, 120 at most), directly under the heading and above the full prose; prose that covers each item of spec section 2 with its files, exit code 3 of `review-package` and its three caller rules (orchestrated: a stop under the Major-Error Stop Policy, not a ruling; batched: the fixed blocking question, asked by the resumed session before it reviews from that BASE, journaled again on a repeated exit 3; interactive: the same question again on a repeated exit 3), the batch-controller start check with its two causes and two repairs, exit 2 for a non-commit BASE or HEAD, the `Commits in range: none` line, the C9 implementer rule, the new file `.superpowers/sdd/preflight.md`, the committed-ledger stop, the five accepted limits as "not ported", and the four rejected items of spec section 5.
  - Invariants: the entry stands above `## v7.73.1` and below the file's header note; every statement of the summary is supported by the prose.
  - Verification: Step 4's commands (heading position, summary word count, key phrases).
- Accepted limits in the local issues log (wording artifact, not committed)
  - Must convey: the five entries and the note of spec section 4.9, appended at the end of `## Accepted limits`.
  - Invariants: the step runs in the main checkout (parent folder of `git rev-parse --path-format=absolute --git-common-dir`); it appends once (skipped when a line holds `(upstream A10)`); it is skipped when the file is absent; the file is never staged; the task report says which of append, skip-absent, skip-present happened.
  - Verification: Step 6's commands.
- All fast suites (procedural)
  - Verification: Step 8 runs every fast suite listed in `CLAUDE.md`, each as its own command.

- [x] **Step 1: Bump the version**

Replace `7.73.1` with `7.74.0` in: `VERSION` (whole content `7.74.0` and a newline); `.claude-plugin/plugin.json` line 4 (`"version": "7.74.0",`); `.claude-plugin/marketplace.json` line 13; `plugin.universal.yaml` line 7 (`version: "7.74.0"`); `README.md` line 6 (badge `version-7.74.0-white`); `README.md` lines 22 and 24 (`v6.7.0–v7.73.1` → `v6.7.0–v7.74.0`, keeping the en dash).

- [x] **Step 2: Verify the bump**

Run: `grep -n '7\.73\.1' VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md`
Expected: no output (exit 1).

Run: `grep -c '7\.74\.0' VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md`
Expected: `VERSION:1`, `.claude-plugin/plugin.json:1`, `.claude-plugin/marketplace.json:1`, `plugin.universal.yaml:1`, `README.md:3`.

- [x] **Step 3: Write the release-notes entry**

In `RELEASE-NOTES.md`, insert above the line that starts with `## v7.73.1` (after the header note block and its blank line) this entry, followed by one blank line:

```markdown
## v7.74.0 — fixes ported from upstream v7.0.0; Copilot CLI no longer supported

**Problem.** `sdd-workspace` reset a committed `.superpowers/sdd/.gitignore` on every call. `review-package` packaged a reversed range as a diff that deletes the task's work. A systematic-debugging example printed a secret value.

**Change.** Seven upstream fixes: create-only `.gitignore`; `review-package` exit 3 for a reversed range (the loop stops or the task is BLOCKED) and a `Commits in range: none` line for an empty one; a safe secret check; unreadable evidence is a ⚠️ item; a pre-flight scan table; four worker templates forbid subagent dispatch; an implementer reports a failing test outside its task and does not fix it. Copilot CLI is no longer supported.

**Effect.** Reinstall the plugin. A repository that committed its own `.superpowers/sdd/.gitignore` restores its version once.

Upstream obra/superpowers released v7.0.0 on 2026-10-09. A comparison with this fork found seven upstream fixes whose defect also exists here; two verification passes reproduced or confirmed each of them. This release ports those seven, records five Windows-only upstream fixes as accepted limits, and rejects four other upstream items.

### What changed

- **`.superpowers/sdd/.gitignore` is created only when it is absent or empty (upstream A13).** `skills/subagent-driven-development/scripts/sdd-workspace` wrote `*` into the workspace `.gitignore` on every call, and `task-brief` and `review-package` call it for every brief and every package. A repository that commits its own version of that file (for example to keep the ledger `progress.md` tracked) saw the file reset each time, and `git status` showed it as modified. The script now writes the file only when it is missing or zero bytes long; a file that is not empty is never changed. A repository whose committed version an older release already reset restores its version once; from then on it stays. If you also commit the ledger `progress.md`, it is part of the branch: the whole-branch reviewers see it, and an orchestrated run stops at the next batch boundary or at Phase 5, because every ledger write leaves a tracked file changed. When a different plan starts, the archive step moves a committed `progress.md` into the ignored `archive/` folder, so `git status` shows it as deleted.
- **`review-package` exits 3 on a range whose HEAD does not descend from BASE (upstream C11).** Before, such a range exited 0 and wrote a reverse diff that showed the task's own work as deleted. Range mode now runs `git merge-base --is-ancestor BASE HEAD` before it writes anything, and on failure exits 3 with the one line `HEAD is not a descendant of BASE: <base>..<head>` on standard error; no file is written. A BASE or HEAD that names a tree or a blob now exits 2 with `bad BASE:` or `bad HEAD:`, like any other bad reference. An empty range (BASE = HEAD) stays valid: the package is written, and its Commits section holds the one line `Commits in range: none`. `--commits` mode, which wave tasks use, does not change. Upstream's second guard, which refuses an empty range, is not ported.
- **Every caller of the range form handles exit 3, and none of them asks for a ruling.**
  - Interactive SDD (`skills/subagent-driven-development/SKILL.md`, new **Exit 3** paragraph under **DONE**): the task is BLOCKED at once, with none of the numbered **BLOCKED** remedies. The controller asks you one question that names the task, the range and the script's error line. After you confirm a repair, it runs the same call with the same BASE; on a repeated exit 3 it asks the same question again.
  - Batched Autonomous Mode: the batch ends with the blocking question `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)` under `## Open Issues`. The question keeps the task's BASE, which nothing else keeps after /clear. Resume Procedure step 2 no longer marks such a task complete; step 3 asks you the question and stops. After you answer that the branch is repaired, the resumed session runs `review-package <the journaled BASE> HEAD` and the task review before it goes on. On a repeated exit 3 it journals the same question again and ends.
  - Orchestrated run (`skills/orchestrating-development/batch-controller-prompt.md`): the batch controller returns `BLOCKED task=<n>: review range invalid — <the script's error line>` with no question or conflict section. The orchestrator reads that as a controller failure, retries the batch once, and then stops under its Major-Error Stop Policy. Exit 3 is a stop, not a ruling.
  - Review loop (`skills/multi-code-review/SKILL.md`, Error Handling): exit 3 stops the whole invocation with `BLOCKED: review range invalid — <the script's error line>`; nothing is dispatched, and the no-package fallback never applies to exit 3. `skills/multi-code-review/reviewer-prompt.md` says the same in its placeholder legend.
- **The batch controller checks the branch at its start.** After `sdd-workspace PLAN_FILE` and before any dispatch, Deviation 4 now runs `git merge-base --is-ancestor <head7> HEAD` against the HEAD of the last completed ledger line. A non-zero exit returns `BLOCKED task=<n>: review range invalid — HEAD does not descend from the last completed ledger HEAD <head7> (branch switched, reset or rewritten, or ledger left from an earlier run of this plan)`, so a retried batch stops before it dispatches anything. The check has two causes and two repairs. The branch was switched, reset or rewritten: repair the branch and resume. Or the ledger is left from an abandoned or earlier run of the same plan (abandoning deletes the branch, not the ledger): remove or archive `.superpowers/sdd/progress.md` and `.superpowers/sdd/preflight.md`, then start again. With no completed ledger line the check is skipped.
- **An empty package is reviewed as before.** A task that committed nothing gets a package whose Commits section says `Commits in range: none`. The controller dispatches the task reviewer with it; a task whose brief asks for changed files then fails under **Missing**.
- **The systematic-debugging example prints no secret (upstream A17).** In `skills/systematic-debugging/SKILL.md`, with `IDENTITY=s3cret` the example printed `IDENTITY: SETs3cret`, and its `env | grep IDENTITY` line printed the value too. Both lines now use a `[ -n "${IDENTITY:-}" ]` test and print only `SET`/`UNSET` or `in environment`/`not in environment`. Upstream's `printenv` form is not ported, because the fork's secrets hook refuses it for a secret-like name such as `API_TOKEN`.
- **Evidence the task reviewer cannot read is a ⚠️ item (upstream D8).** `skills/subagent-driven-development/task-reviewer-prompt.md` now says that evidence the reviewer cannot read is not missing evidence: the reviewer reads the report again, paging, and otherwise reports a ⚠️ "Cannot verify from diff" item, never a ❌ finding, and runs no test to produce the evidence again. "Handling Reviewer ⚠️ Items" in the SDD skill tells the controller to read the report file itself; evidence that is still unreadable or absent sends the task back to the implementer to re-run the tests and write the command and its output into the report file.
- **The Pre-Flight Plan Review writes its scan as a table (upstream D4).** The scan used to leave no record ("If the scan is clean, proceed without comment"). The SDD controller now writes what it compared to the new file `.superpowers/sdd/preflight.md`, under `## Pre-flight scan`: one row per path that the **Files:** lists of two or more tasks name, one row per name that the text of two or more tasks mentions, and one row per task, in four columns (`Row`, `Tasks`, `Compared`, `Found`). The scan still runs at every start; the table is written once per plan. The table never decides a conflict: conflicts go through the existing rules of each run mode. Upstream's sentences that let the controller rule on conflicts are not ported.
- **Four worker templates forbid subagent dispatch (upstream D6).** The implementer and task-reviewer templates of SDD and the reviewer templates of `multi-code-review` and `multi-doc-review` now say "Do NOT dispatch subagents.", the wording that `fix-prompt.md` already used. No controller text gets the sentence, because controllers must dispatch their workers. In the user's transcripts 0 of 83 implementers, 0 of 82 task reviewers and 1 of 299 review-round reviewers had dispatched a subagent, so the rule prevents a possible fault; it does not fix an observed one.
- **A failing test outside the task is reported, not fixed (upstream C9).** `skills/subagent-driven-development/implementer-prompt.md` now says: a test outside the task that fails, and that the change did not cause, is not fixed, unless the brief or the dispatch names that test as part of the task. The change did not cause the failure when the test neither is a file that the task changes nor imports or reads one. The implementer commits its work as usual, reports `DONE_WITH_CONCERNS` and names the test as an observation, with the failing output and that reason. The controller proceeds to review, and the task reviewer and the fix subagent keep their existing rules. The checklist of `skills/test-driven-development/SKILL.md` carries the same reporting rule; in the main session, the failure is named in the reply to the user.
- **GitHub Copilot CLI is no longer supported.** `README.md` (badge, introduction, platform status, Codex note and a note in the Copilot CLI section), `docs/guide/README.md`, `docs/platforms/codex.md` and `.codex/INSTALL.md` now say so, in the form of commit `4f15206`, which marked Codex as no longer supported. The Copilot CLI files and sections stay; Copilot CLI was last used with v7.13.0.
- **User guide.** §3 describes the pre-flight table, the implementer rule for a failing test outside its task and the batched and interactive exit-3 paths; §4 describes the orchestrated stop and the start check; §9 has a troubleshooting entry for a reset `.superpowers/sdd/.gitignore`.

### Not ported (accepted limits)

Five Windows-only upstream fixes are recorded as accepted limits in the local issues log, not ported: the WSL `bash.exe` launcher found by `hooks/run-hook.cmd` (A10), `bash.cmd` or `where.bat` in the current folder (A11), `exit /b %ERRORLEVEL%` inside a parenthesized block (A12), the missing `"shell": "bash"` key in `hooks/hooks.json` (E7), and the `printf` write error on a closed pipe in Git Bash (EPIPE, #1612). None of them has a case, and none loses user work or makes a wrong commit. No hook file changes.

### Rejected

- **D7** — reading the spec at SDD setup so that plan conflicts resolve against it: it contradicts this fork's rule that the controller never decides a plan conflict, and it costs about 8-16K tokens per batch controller (an estimate).
- **Upstream C9 as written** ("the project's whole suite defines green"): this repository has no single test command, and wave implementers share one working tree. Only the reporting rule is ported.
- **The Copilot CLI session-start fix**: Copilot CLI is no longer supported.
- **Copying the whole upstream SDD `SKILL.md`**: upstream forbids parallel implementers, and this fork's default is Parallel Waves.

### Known limits

- A dangling symbolic link named `.superpowers/sdd/.gitignore` is written through (the link's target gets `*`); it needs a link made on purpose.
- A failing test that an implementer leaves in place and the task review does not fix stays failing on the branch. A later whole-branch fix subagent that changes a file the test covers restores its files and stops, and its findings can become `unresolved`; the stop is loud and loses no work.
- After an abandoned run, a restarted run of the same plan in the same checkout stops at the start check until the old ledger is removed, and an old `preflight.md` makes the restarted run skip writing a new table.
```

- [x] **Step 4: Verify the release-notes entry**

Run: `grep -n '^## v7\.7[34]' RELEASE-NOTES.md | head -3`
Expected: the `## v7.74.0 — …` line comes before the `## v7.73.1 — …` line.

Run: `awk '/^## v7\.74\.0/ { f = 1; next } f && /^Upstream obra\/superpowers released/ { exit } f' RELEASE-NOTES.md | wc -w`
Expected: a number of at most `120` (the summary of spec section 4.10 counts 117 words with `wc -w`).

Run: `for n in 'HEAD is not a descendant of BASE' 'Commits in range: none' 'Is the branch of task N repaired?' 'review range invalid' '.superpowers/sdd/preflight.md' 'Major-Error Stop Policy' 'restores its version once' 'Do NOT dispatch subagents.' 'DONE_WITH_CONCERNS' 'not ported'; do printf '%s: ' "$n"; awk '/^## v7\.74\.0/ { f = 1 } /^## v7\.73\.1/ { exit } f' RELEASE-NOTES.md | grep -cF -- "$n"; done`
Expected: every phrase prints a count of at least `1`.

- [x] **Step 5: Locate the issues log in the main checkout**

Run: `MAIN=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)"); LOG="$MAIN/docs/orchestration-issues.md"; if [ ! -f "$LOG" ]; then echo "SKIP-ABSENT $LOG"; elif grep -qF -- '(upstream A10)' "$LOG"; then echo "SKIP-PRESENT $LOG"; else echo "APPEND $LOG"; fi`
Expected: one line. `SKIP-ABSENT` or `SKIP-PRESENT` → do not edit the file; write that line into the task report and go to Step 7. `APPEND` → Step 6.

- [x] **Step 6: Append the accepted limits (only after `APPEND`)**

Open the file named by Step 5 with the Read tool at the `## Accepted limits` section (find its line and the next `## ` heading with `grep -n '^## ' <file>`). With the Edit tool, insert after the last entry of that section (before the blank line that precedes the next `## ` heading) these six entries:

```markdown
- 2026-10-21 (upstream A10) — state: Windows, Git for Windows installed per
  user under `%LOCALAPPDATA%\Programs\Git`, and the WSL `bash.exe` launcher
  on PATH; consequence: `hooks/run-hook.cmd:33-37` finds and runs the WSL
  launcher, session-start fails, and the session starts without the
  injected context; no lost work. Found by the upstream v7.0.0 comparison,
  code reading only, not reproduced on Windows.
- 2026-10-21 (upstream A11) — state: Windows, a cloned repository that holds
  a `bash.cmd` or `where.bat` in its top folder; consequence: cmd.exe
  searches the current folder before PATH, so `hooks/run-hook.cmd:33` and
  `:36` run that file at session start. Source for the search order, not
  reproduced: Microsoft `path` command documentation,
  https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/path
  ("The current directory is always searched before the directories
  specified in the command path."). Found by the upstream v7.0.0
  comparison, code reading only, not reproduced on Windows.
- 2026-10-21 (upstream A12) — state: Windows, the session-start hook fails;
  consequence: `hooks/run-hook.cmd:24`, `:29`, `:37` run
  `exit /b %ERRORLEVEL%` inside a parenthesized block, which cmd.exe expands
  before the hook runs, so the wrapper always exits 0 and the failure is
  silent. Unverified: Microsoft `cmd` documentation,
  https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cmd,
  says only that with delayed expansion `!` substitutes a variable "at run
  time"; it does not describe the expansion of a parenthesized block. Found
  by the upstream v7.0.0 comparison, code reading only, not reproduced.
- 2026-10-21 (upstream E7) — state: Windows without Git Bash, or a Claude
  Code version that does not default to Git Bash; consequence:
  `hooks/hooks.json:9` has no `"shell": "bash"` key, so PowerShell can fail
  to parse the quoted command. On current Claude Code the default is already
  Git Bash when it is installed (https://code.claude.com/docs/en/hooks,
  checked on 2026-10-21: the `shell` field "Defaults to "bash", or to
  "powershell" on Windows when Git Bash isn't installed"), and without Git
  Bash `run-hook.cmd` has no bash to run in any case. Found by the upstream
  v7.0.0 comparison; on macOS the key was measured to change nothing.
- 2026-10-21 (upstream EPIPE, #1612) — state: Windows Git Bash, Claude Code
  closes the hook's standard output before `printf` finishes; consequence:
  `hooks/session-start:704-710` print with plain `printf` under
  `set -euo pipefail` (`:4`), so Git Bash can print "printf: write error:
  Permission denied" at each start; per upstream the context is still
  injected. Upstream pipes the output through `cat`. Not reproduced.
- 2026-10-21 (note for a later port of A10-A12) — do not copy upstream's
  `hooks/run-hook.cmd` whole: its Unix part runs `exec "${BASH:-bash}"`. A
  SessionStart hook runs under `sh -c` on macOS (measured with Claude Code
  2.1.306), where `$BASH` is `/bin/sh`, that is bash 3.2 in POSIX mode. The
  copy would run `hooks/session-start` in POSIX mode instead of the `bash`
  found on PATH. Today's script prints the same output there, but a later
  edit that uses a bash-only form such as `<(...)` would break every session
  start on macOS while the tests, which run the script with `bash`, stay
  green. Port only the Windows batch part, keep `exec bash`.
```

Run: `MAIN=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)"); awk '/^## Accepted limits$/ { f = 1; next } f && /^## / { exit } f && /^- 2026-10-21 \((upstream|note for a later port)/ { n++ } END { print n + 0 }' "$MAIN/docs/orchestration-issues.md"`
Expected: `6` (all six entries stand inside `## Accepted limits`).

Write into the task report which outcome happened: appended, skipped because absent, or skipped because already present. The file stays out of every commit.

- [x] **Step 7: Confirm the issues log is not staged**

Run: `MAIN=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)"); git -C "$MAIN" status --porcelain -- docs/orchestration-issues.md`
Expected: no output (the file in the main checkout is ignored and untracked; the check runs there because Steps 5-6 edit that copy, also when this task runs in a linked worktree).

- [x] **Step 8: Run every fast suite**

Run each command on its own (each prints a final results line; a suite that does not end with 0 failures stops the task):
- Run: `bash tests/codex/run-unit-tests.sh`
- Run: `bash tests/smart-compress/run-tests.sh`
- Run: `bash tests/reviewer-templates/run-tests.sh`
- Run: `bash tests/writing-plans/run-tests.sh`
- Run: `bash tests/in-run-rulings/run-tests.sh`
- Run: `bash tests/fill-prompt/run-tests.sh`
- Run: `bash tests/orchestrating-development/run-tests.sh`
- Run: `bash tests/review-gates/run-tests.sh`
- Run: `bash tests/measure-context/run-tests.sh`
- Run: `bash tests/pickup/run-tests.sh`
- Run: `bash tests/analyze-compaction/run-tests.sh`
- Run: `bash tests/sdd-scripts/run-tests.sh`
- Run: `bash tests/suite-guard/run-tests.sh`
- Run: `bash tests/worklog/run-tests.sh`
- Run: `bash tests/dashboard/run-tests.sh`
- Run: `bash tests/finishing-branch/run-tests.sh`
- Run: `bash tests/using-git-worktrees/run-tests.sh`
- Run: `bash tests/skill-test-runner/run-tests.sh`
- Run: `bash tests/find-polluter/run-tests.sh`
- Run: `bash tests/verification-before-completion/run-tests.sh`

Expected: every command exits 0 and reports no failure.

- [x] **Step 9: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): v7.74.0 — upstream v7.0.0 fixes; Copilot CLI no longer supported" --trailer "Session: upstream-v7-fixes" --trailer "Stage: task 13/13"
```
