# Selected fixes from upstream obra/superpowers v7.0.0, and Copilot CLI no longer supported — design

- Date: 2026-10-21
- Target version: 7.74.0 (one release)
- Base: `main` at `fb222d38` (v7.73.1). Every line number in this document
  refers to that commit and was checked against the file on 2026-10-21.
- Upstream: obra/superpowers, tag `v7.0.0` (release commit `bb92a777`).
  This repository is a fork of that project. Item ids such as A13 or C11
  are the ids of the comparison report "Upstream obra/superpowers releases
  after v6.0.0 — comparison with this fork" (2026-10-21). That report and
  its three verification reports are not in this repository. This spec
  repeats every fact of them that it relies on, so they are not needed to
  implement it.
- Design approved by the user on 2026-10-21.

## 1. Problem

Upstream released v7.0.0 on 2026-10-09. A comparison with this fork found
seven upstream fixes whose defect also exists here, and two verification
passes reproduced or confirmed each of them:

1. **A13.** `skills/subagent-driven-development/scripts/sdd-workspace`
   rewrites `.superpowers/sdd/.gitignore` with `*` on every call. A
   repository that commits its own version of that file (for example to keep
   the ledger tracked) sees the file reset on every task brief and every
   review package. Reproduced: a committed three-line file became `*` after
   one run, and `git status` showed it as modified.
2. **A17.** An example in `skills/systematic-debugging/SKILL.md` prints a
   secret value. Reproduced: with `IDENTITY=s3cret`, line 54 prints
   `IDENTITY: SETs3cret`.
3. **C11.** `review-package` accepts an empty range (zero commits), and a
   range whose HEAD does not descend from BASE. Reproduced: both exit 0. The
   first writes an empty package; the second writes a reverse diff that
   deletes the task's own work.
4. **D8.** The task reviewer has no rule for test evidence it cannot read.
   It can report a cut-off report as missing evidence.
5. **D4.** The SDD Pre-Flight Plan Review leaves no record. "If the scan is
   clean, proceed without comment" gives no evidence that a scan ran.
6. **D6.** Four worker templates forbid the Skill tool but not the
   dispatch of subagents. In this user's transcripts 0 of 83 implementers
   and 0 of 82 task reviewers dispatched a subagent, and 1 of 299 review-round
   reviewers did (a multi-doc-review reviewer sent 3 `Explore` agents).
   Source and method: an earlier verification pass of 2026-10-21 counted
   the subagent transcripts of every project under `~/.claude/projects`
   (this repository and the user's other projects). It classified each
   subagent by the task description in its `.meta.json` file ("Implement
   Task …", "Review Task …", "… round N …") and counted a dispatch as an
   `Agent` or `Task` tool call in that subagent's transcript. Subagents with
   other descriptions, and transcripts older than the retention period, are
   not counted. The rule is cheap insurance, not a fix for an observed
   fault.
7. **C9.** No worker text says what to do with a test failure that the
   worker's own change did not cause. An implementer can then fix it
   inside its task: a change outside the task's scope that its brief did
   not ask for and that no reviewer was told about.

Separately, the user decided on 2026-10-21 that GitHub Copilot CLI is no
longer a supported platform. The documents still present it as one of the
two platforms in use.

## 2. Scope

This release makes these changes:

1. **A13** — `sdd-workspace` writes the workspace `.gitignore` only when the
   file is absent (section 4.1).
2. **A17** — the two example lines of systematic-debugging print no secret
   value (section 4.2).
3. **C11** — `review-package` exits 3 when HEAD does not descend from
   BASE, and exits 2 on a BASE or HEAD that is not a commit. An empty range
   stays valid (exit 0), and the package says `Commits in range: none`.
   Every caller of the range form has a rule for exit 3, and the
   orchestrated batch controller checks at its start that the branch still
   descends from the last completed task (section 4.3).
4. **D8** — the task reviewer reports evidence it cannot read as a ⚠️ item
   (section 4.4).
5. **D4** — the SDD controller writes the conflict-scan result as a table
   to `.superpowers/sdd/preflight.md`, once per plan (section 4.5).
6. **D6** — four worker templates say "Do NOT dispatch subagents."
   (section 4.6).
7. **C9** — an implementer that sees a failure of a test outside its
   task, that its change did not cause, does not fix it: it commits its
   work as usual, reports `DONE_WITH_CONCERNS` and names the test as an
   observation. The controller, the task reviewer and the fix subagent
   handle that concern by their existing rules (the controller proceeds to
   review, and the task reviewer decides); no new stop and no new ruling. The TDD
   checklist carries the same reporting rule (section 4.7).
8. **Copilot CLI** is marked as no longer supported, in the form used for
   Codex in commit `4f15206` (section 4.8).
9. **Accepted limits** — five Windows-only upstream fixes are recorded as
   accepted limits in the local issues log, not ported (section 4.9).
10. **Release v7.74.0** — version bump, release notes, user guide
    (section 4.10).

### Non-goals

- The Windows hook wrapper `hooks/run-hook.cmd`, the `"shell": "bash"` key
  and the EPIPE pipe (upstream A10, A11, A12, E7 and the `printf | cat`
  change). They are recorded as accepted limits (section 4.9); no hook file
  changes.
- No change to `review-package`'s `blind_pathspecs` list. A ledger that a
  user commits reaches the whole-branch reviewers (section 4.1, accepted).
- No change to `skills/orchestrating-development/batch-controller-prompt.md`
  for D4 or C9. Its only changes are the C11 rules of section 4.3.2 (the
  exit-3 rule and the start check in Deviation 4).
- No change to `skills/requesting-code-review/code-reviewer.md`,
  `agents/code-reviewer.md` or `agents/red-team.md` for D6. They run
  outside the review loops. The prompts that a controller composes itself
  (the SDD security reviewer, the SDD fix subagent) are not templates and do
  not change either.
- No definition of "the full suite" per repository for C9.
- No C9 rule for fix subagents (`skills/multi-code-review/fix-prompt.md`
  and the SDD fix subagent). They run after a review. Their rule for a
  failing covering test does not handle a failure that the branch already
  carries: the fix subagent restores every file it changed, does not
  commit, reports the failure and stops (`fix-prompt.md:52-75`). The stop
  is loud and loses no work; section 8 item 9 records this interaction as
  an accepted limit. `fix-prompt.md` is pinned by `FIX_RULE_CLAUSES`
  (`tests/reviewer-templates/run-tests.sh:53-65`), and changing it is out
  of scope. This release changes only the implementer path.
- No deletion of Copilot CLI sections or files; only the sentences listed in
  section 4.8 change. The Copilot sentences in
  `skills/worklog/SKILL.md`, `skills/pickup/SKILL.md`,
  `skills/orchestrating-development/SKILL.md`, `docs/guide/README.md`
  (lines 50-53, 636-638, 1247, 1459, 1481), `docs/platforms/codex.md:15`,
  `.codex/INSTALL.md:13`, `.opencode/INSTALL.md:6` and the header of
  `RELEASE-NOTES.md` (lines 3-4) stay as they are.
  `docs/research/claude-code-mods.md:361` ("GitHub Copilot CLI (which this
  plugin also supports)") also stays: it is a dated research document that
  records what was true when it was written.
- The other items of the comparison report (brainstorming, plan format,
  executing-plans, the fix-round cap and others) need their own specs.

No decision in this design matched the prior-art trigger predicate.

## 3. Terms and facts used throughout

- **SDD** is the skill `subagent-driven-development`. Its **controller** is
  the agent that dispatches workers; a **worker** is a subagent that does one
  job (implementer, task reviewer, round reviewer, fix subagent).
- **Ledger**: `.superpowers/sdd/progress.md`, the SDD progress file. A
  completed task has the line
  `Task N: complete (commits <base7>..<head7>, review clean)`
  (`skills/subagent-driven-development/SKILL.md:559-561`). `<head7>` is the
  HEAD after the task's last implementer or fix-subagent commit, before the
  plan checkbox commit (Core Flow step 3, "Mark task complete",
  `SKILL.md:76`, and `batch-controller-prompt.md` Deviation 3, `:183-192`,
  both append the ledger line before that commit). Carried Minor findings
  are `Minor:` lines; the code-review controller copies "its `Minor:`
  lines" into its reviewers' prompts
  (`skills/orchestrating-development/code-review-loop-prompt.md:91-94`).
- **Three run modes of SDD.** *Interactive*: the controller may ask the
  user. *Batched Autonomous Mode*: the controller never asks the user; a
  blocker is journaled under `## Open Issues` of `state.md` and ends the
  batch (`SKILL.md:394-406`, "Autonomy Policy"). *Orchestrated*: the batch
  controller of `orchestrating-development` returns `BLOCKED task=<n>` with
  `### Question <k>` or `### Conflict <k>` sections in
  `.superpowers/sdd/task-<n>-report.md`, and the orchestrator rules on them
  (`batch-controller-prompt.md:127-181`, "Deviation 1").
- **Wave**: SDD "Parallel Waves". Several implementers work in one working
  tree at the same time, and each task's review package is built with
  `review-package --commits <SHAs>`, never with a range
  (`SKILL.md:218-232`). Waves run only in interactive SDD; batches run tasks
  one at a time (`batch-controller-prompt.md` Deviation 2).
- **BASE / HEAD.** In range mode `review-package BASE HEAD` packages the
  commits reachable from HEAD and not from BASE. Per task, BASE is the HEAD
  that the controller recorded before it dispatched the implementer
  (`SKILL.md:67`). A commit X **descends from** BASE when BASE is an
  ancestor of X; git checks this with `git merge-base --is-ancestor BASE X`
  (git-merge-base(1), git 2.50.1: it exits "with status 0 if true, or with
  status 1 if not. Errors are signaled by a non-zero status that is not
  1."). A commit is its own ancestor (measured on 2026-10-21, git 2.50.1:
  `git merge-base --is-ancestor C C` exits 0 for a commit `C`; the manual
  page does not state this case). An **empty range** is a range BASE..HEAD
  that holds zero commits, for example BASE = HEAD after a task that
  committed nothing.
- **Range mode** is every SDD run outside a wave: interactive sequential
  tasks, Batched Autonomous Mode and the orchestrated batch controller.
- **Implementer return.** The implementer ends with a status return of at
  most 15 lines; one of its items is "Your concerns, if any"
  (`implementer-prompt.md:182-189`).
- **Pathspec**: a git path filter. `review-package` passes the
  **blind pathspecs** (`review-package:43-53`) to every read, so review logs
  and other review material never reach a reviewer.
- **Pin**: a test assertion that compares skill text with a fixed string.
  **Folded** text: each line trimmed and all lines joined with one space, so
  a phrase that wraps across a line break still matches
  (`fold_file`, `tests/sdd-scripts/run-tests.sh:40-42`; the same helper
  exists in `tests/reviewer-templates/run-tests.sh`).
- **Phrase count**: a pin that counts how often a phrase occurs in a whole
  folded file (`assert_phrase_counts`, `tests/sdd-scripts/run-tests.sh:1343`,
  case-sensitive substring). In SDD `SKILL.md`, `git commit`, `chore(plan)`
  and `tick` must each occur exactly once, and the wave line
  `You run in a parallel wave.` twice (`:1367-1368`). "tick" is a substring
  match, so a new word such as "ticked" also counts. In
  `implementer-prompt.md` the counted phrases are `git add -A`,
  `git commit -a`, `git commit --amend`, `git stash`, `git reset`,
  `git checkout`, `git restore` (1 each), `git status`, `git diff`,
  `whole tree`, `formatter`, `index.lock` (2 each) and `current HEAD` (1)
  (`:1359-1362`). **No new text in this design contains any of these
  phrases** (no new SDD `SKILL.md` text holds `git commit` or a word that
  contains `tick`). The whole `## Commit Messages` section of
  `implementer-prompt.md` is pinned rule by rule
  (`tests/sdd-scripts/run-tests.sh:1339-1340`) and does not change.
- **Template placeholders.** `fill-prompt.js` fills `[UPPERCASE]` tokens in
  the orchestrator's controller templates and exits 3 on an unknown one. No
  new text in `batch-controller-prompt.md` contains a bracketed uppercase
  token.

## 4. Design

**Quoting convention.** New text shown in this section as a `> `
blockquote, outside a code fence, is inserted into the target file
without the `> ` prefix. Inside a code fence every character is literal:
a `> ` line inside a fence is inserted with its `> ` prefix (for example
the README note of section 4.8, which is a quote block in the README).

### 4.1 A13 — `sdd-workspace` writes `.gitignore` only when absent or empty

**Current.** `skills/subagent-driven-development/scripts/sdd-workspace:84-85`:

```bash
mkdir -p "$dir"
printf '*\n' > "$dir/.gitignore"
```

The line runs on every call. `task-brief:23` and `review-package:79,120`
call `sdd-workspace` without arguments, so every brief and every package
rewrites the file. The script runs under `set -euo pipefail` (`:24`).
`has_content` and the archive step already skip `.gitignore`
(`:49`, `:69`), so the file stays at the workspace root on an archive.

**Change 1 — the write (`sdd-workspace:85`).** Replace line 85 with these
four lines (upstream form, with the fork's variable `$dir` and `-s` in
place of upstream's `-e`):

```bash
# Create-only: a repository may commit its own .gitignore here (for example
# one that keeps progress.md tracked). Rewriting the file on every run would
# undo that version each time. An empty file ignores nothing and is rewritten.
[ -s "$dir/.gitignore" ] || printf '*\n' > "$dir/.gitignore"
```

`[ -s ]` is true when the file exists and is not empty (test(1), macOS:
"True if file exists and has a size greater than zero"; measured on
2026-10-21 with bash 3.2.57: false for an absent file and for a zero-length
file). Upstream tests
`[ -e ]`; with it, a zero-length `.gitignore` would stay and the workspace
would show in `git status`. A dangling symbolic link named `.gitignore` is
outside this design (section 8, item 6).

**Change 2 — the header comment (`sdd-workspace:8-10`).** Today lines 8-10
read "A self-ignoring .gitignore keeps the / workspace out of `git status`
and out of accidental commits without / modifying any tracked file." Replace
them with:

```bash
# subagent from writing its report file. A self-ignoring .gitignore keeps the
# workspace out of `git status` and out of accidental commits without
# modifying any tracked file. The script writes that .gitignore only when the
# workspace has none or an empty one: a .gitignore that is not empty, for
# example one that the repository commits, is never changed.
```

(Line 8 keeps its first half, "subagent from writing its report file.",
unchanged.)

**What the user's own file decides (non-goal).** With create-only, the
user's committed `.gitignore` wins. When that file does not ignore the
workspace files, they appear as untracked files in `git status` in a plain
SDD run. (An orchestrated run adds `.superpowers/` to the local exclude file,
`orchestrating-development/SKILL.md:367-370`, which keeps untracked files of
the workspace hidden.) When the user also commits the ledger, the committed
ledger, with its `Minor:` lines, is part of the branch diff that
whole-branch reviewers read, because the blind pathspecs do not exclude
`.superpowers/sdd/`. An orchestrated run then stops: every ledger write
leaves a tracked file changed, and the orchestrator stops on an
"unexpected dirty tree at a boundary"
(`orchestrating-development/SKILL.md:2905-2906`) at the next batch
boundary, or at Phase 5 step 1, which requires a clean
`git status --porcelain` (`SKILL.md:719-721`). This is an accepted limit:
it needs a deliberate commit by the user, the stop is loud, and no new
blind pathspec is added.

**A committed ledger and the archive step (accepted).** When a different
plan starts, `archive_workspace` (`sdd-workspace:60-75`) moves every entry
except `.gitignore`, `archive` and `plan.ref` into `archive/<slug>/`, a
committed `progress.md` included. With a user file such as `*`,
`!.gitignore`, `!progress.md`, the `archive/` folder stays ignored (git does
not re-include a file inside an ignored folder; gitignore(5), git 2.50.1,
checked on 2026-10-21: "It is not possible to re-include a file if a
parent directory of that file is excluded."), so `git status` shows
`.superpowers/sdd/progress.md` as deleted. This release does not change the
archive step: the state needs a deliberate commit of the ledger by the user,
and the user decides whether to commit that deletion.

### 4.2 A17 — the systematic-debugging example prints no secret

**Current.** `skills/systematic-debugging/SKILL.md`:

- line 54: `  echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"` — prints the
  value whenever the variable is set;
- line 58: `  env | grep IDENTITY || echo "IDENTITY not in environment"` —
  prints `IDENTITY=<value>`. The fork's `hooks/safety/protect-secrets.js`
  (rule `env-dump`) blocks this command on Claude Code; it does not block
  line 54.

**Change.** Replace line 54 with upstream's line (v7.0.0 line 91), and
line 58 with a line in the same form, keeping the fork's two-space indent:

```bash
  echo "IDENTITY: $([ -n "${IDENTITY:-}" ] && echo SET || echo UNSET)"
```

```bash
  [ -n "${IDENTITY:-}" ] && echo "IDENTITY in environment" || echo "IDENTITY not in environment"
```

Upstream's line 95,
`printenv IDENTITY >/dev/null 2>&1 && echo "IDENTITY in environment" || …`,
is not ported. The fork's `hooks/safety/protect-secrets.js` refuses it,
rule `echo-secret-var`, for a secret-like name such as `API_TOKEN`
(measured on 2026-10-21 with `checkBashCommand`: `blocked: true` for
`API_TOKEN`, `blocked: false` for `IDENTITY`), and a reader copies the
example with the name of their own variable. The `[ -n ]` form is allowed
for both names. Line 58 sits under "Layer 2: Build script", so it runs
inside the build script, where the variable is set only when the
environment passes it in; the shell test answers the same question as
`env | grep`.

Line 66 (`codesign --sign "$IDENTITY" …`) stays. Both safety hooks allow the
two new lines (`protect-secrets.js` `checkBashCommand` and
`block-dangerous-commands.js` `checkCommand`, measured on 2026-10-21 with
`IDENTITY` and `API_TOKEN`). Neither line contains a `$1`-style token (Claude Code
replaces such a token in a skill body with an argument word; source:
https://code.claude.com/docs/en/skills, checked on 2026-10-21: "`$N` |
Shorthand for `$ARGUMENTS[N]`, such as `$0` for the first argument or `$1`
for the second", and "An indexed placeholder with no corresponding
argument … stays in the content unchanged"). No other file
quotes these lines, and no test pins them;
`tests/codex/test-session-start-snapshot.sh:396-417` pins only the lines
under "Check recent changes", which do not change.

### 4.3 C11 — `review-package` exits 3 on a non-descendant range

#### 4.3.1 The script

**Current.** `skills/subagent-driven-development/scripts/review-package`
range mode checks only that both references resolve (`:114-115`):

```bash
git rev-parse --verify --quiet "$base" >/dev/null || { echo "bad BASE: $base" >&2; exit 2; }
git rev-parse --verify --quiet "$head" >/dev/null || { echo "bad HEAD: $head" >&2; exit 2; }
```

Exit codes today: 0 success; 2 usage error, bad reference, bad `--commits`
SHA (`:22`, `:76`, `:114-115`). The package starts with the title line
`# Review package: ${base}..${head}`, then a `## Commits` section with the
output of `git log --oneline` (`:124-128`). For an empty range that
section is empty.

A BASE or HEAD that names a tree or a blob (for example `HEAD^{tree}`)
passes these two checks, because `git rev-parse --verify` accepts any
object (git-rev-parse(1), git 2.50.1: `--verify` checks only that the
parameter "can be turned into a raw 20-byte SHA-1 that can be used to
access the object database"). The guard of Change 1 would then fail on
it with exit 3, which reports a wrong range instead of a bad reference.
`--commits` mode already checks for a commit (`:76`):
`git rev-parse --verify --quiet "${c}^{commit}" >/dev/null || { echo "bad commit: $c" >&2; exit 2; }`.

**Change 0 — commit checks (`:114-115`).** Replace the two lines with:

```bash
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null || { echo "bad BASE: $base" >&2; exit 2; }
git rev-parse --verify --quiet "${head}^{commit}" >/dev/null || { echo "bad HEAD: $head" >&2; exit 2; }
```

The messages and the exit code stay. An annotated tag still passes:
`^{commit}` follows the tag to its commit (gitrevisions(7), git 2.50.1:
"`<rev>^{commit}` describes the corresponding commit object"). Test (7)
of the range-guard section (section 7.1) checks this.

**Change 1 — the guard and the count.** Insert after line 115, before the
output path is computed at line 117 (so nothing is written and
`sdd-workspace` is not called on exit 3):

```bash

# Range guard (exit 3). When HEAD does not descend from BASE, the two-dot
# diff shows the task's own work as deleted. A commit is its own ancestor, so
# BASE = HEAD passes: an empty range is not an error, and the package says so.
git merge-base --is-ancestor "$base" "$head" || { echo "HEAD is not a descendant of BASE: ${base}..${head}" >&2; exit 3; }
# Counted without the blind pathspecs: a range whose commits change only
# blinded files is not an empty range.
range_count=$(git rev-list --count "${base}..${head}")
```

The guard line is upstream v7.0.0's first guard (`review-package:25-28`).
Upstream's second guard, which exits 3 on an empty range, is not ported.

**Change 2 — the empty-range line.** After `echo "## Commits"` (`:127`)
insert:

```bash
  [ "$range_count" -gt 0 ] || echo "Commits in range: none"
```

For an empty range, the `## Commits` section then holds that one line in
place of an empty list. The list `[ … ] || echo …` ends with status 0 in
both cases, so `set -e` (`:17`) does not stop the script (bash(1), `set -e`:
"The shell does not exit if the command that fails is … part of a && or ||
list"; measured on 2026-10-21 with bash 3.2.57 under `set -e`: status 0
for a true test and for a false test, and the next command runs). The summary
count at `:137` keeps its pathspecs and prints `0 commit(s)` as today, for
an empty range and for a range with only blinded commits; only the empty
range gets the new line.

**Change 3 — the header comment.** After line 9 (end of the range-mode
block, "(named per range, so a re-review after fixes gets a distinct fresh
file).") add:

```bash
#   An empty range (BASE = HEAD) is not an error: the package is written,
#   and its Commits section holds the one line "Commits in range: none".
#   Exit 3 (nothing written): HEAD does not descend from BASE. Exit 2: a
#   usage error, or a BASE or HEAD that does not name a commit.
```

**`--commits` mode does not change.** It names commits explicitly and has
no range; it gets no guard. A `--commits` call with a SHA that is HEAD
itself, or with a SHA that is not an ancestor of HEAD, still exits 0.

**Pins that stay green.** `tests/sdd-scripts/run-tests.sh:1269-1272` counts
the `git diff` and `git show` command lines of the script (must stay 4, each
with the options array). The new lines use `git merge-base` and
`git rev-list`, so the count does not change.

#### 4.3.2 The callers

Every caller found by `grep -rn review-package skills/`:

| File:line | Change |
|---|---|
| `skills/subagent-driven-development/SKILL.md:73` (Core Flow) | pointer to the exit-3 rule (below) |
| `skills/subagent-driven-development/SKILL.md:441` (**DONE**) | the empty-package sentence and the exit-3 rule (below) |
| `skills/subagent-driven-development/SKILL.md:226` (wave step 3) | none: uses `--commits`; the whole step is pinned (`tests/sdd-scripts/run-tests.sh:1386`, `:1394-1395`) |
| `skills/subagent-driven-development/SKILL.md:521` (final review) | none: `MERGE_BASE` is always an ancestor of HEAD |
| `skills/orchestrating-development/batch-controller-prompt.md:70-71` | the orchestrated exit-3 rule (below) |
| `skills/multi-code-review/SKILL.md:510-515` (round step 1) | none in the step itself |
| `skills/multi-code-review/SKILL.md:1762-1771` (fallback bullet) | a new bullet placed before it (below) |
| `skills/multi-code-review/reviewer-prompt.md:265-272` (placeholder legend) | exit 3 excepted (below) |
| `skills/subagent-driven-development/task-reviewer-prompt.md:213-216` | none |

Two more places change that are not callers of the script: SDD
`SKILL.md:426-430` (Resume Procedure step 2, below), and the start of
`batch-controller-prompt.md` Deviation 4 (`:197`), the start check
(below).

**An empty range in SDD.** A task that committed nothing gets a package whose
`## Commits` section holds `Commits in range: none` and whose diff is
empty. This is today's path with one more line. The controller dispatches
the task reviewer as for any package, and the reviewer judges the task
against its brief and the report. A task whose brief asks for changed
files and whose package shows none is a ❌ under **Missing**
("requirements they skipped, missed, or claimed without implementing",
`task-reviewer-prompt.md:113-114`). A task that needs no tracked change —
one that edits only a git-ignored file (`skills/writing-plans/SKILL.md:122`:
"the task leaves that file out of its commit step") or only runs a
verification — is judged on its report. The reviewer template gets no new
text for this: the reviewer reads the diff file whole (`:44-49`) and
fetches the diff itself only "if the diff file is missing" (`:50`), so it
reads a present package with that line as the range it was given, and the
line says in words that the range is empty.

**Exit 3 in SDD.** The script exits 3 only when HEAD does not descend from
BASE: the branch was switched or reset during the task, or a commit at or
before BASE was rewritten (an amend or a rebase). No implementer dispatch
can repair that without changing the branch, so the task goes to BLOCKED
directly, and the implementer is never asked to switch or reset the
branch.

**SDD `SKILL.md:73`.** Today the line ends "… and dispatch the single task
reviewer (`./task-reviewer-prompt.md`) with the brief, report, and package
paths." Append one sentence to that line:

> When the script exits 3, follow **Exit 3** under **DONE** in Handling
> Implementer Status instead.

The pinned fragment ``dispatch the single task reviewer (`./task-reviewer-prompt.md`)``
(`tests/reviewer-templates/run-tests.sh:826-829`) stays unchanged.

**SDD `SKILL.md:441`.** Today the paragraph ends "In a wave, use `--commits`
with the implementer's reported SHAs instead." Append one sentence to that
paragraph, and add one paragraph directly after it:

> A task that committed nothing gets a package whose Commits section holds
> the line `Commits in range: none`; dispatch the task reviewer with it as
> with any package.
>
> **Exit 3.** `review-package BASE HEAD` exits 3 when HEAD does not
> descend from BASE: the branch was switched or reset during the task, or
> a commit at or before BASE was rewritten (an amend or a rebase), and no
> correct package exists (the script names the fault on standard error).
> Never dispatch the task reviewer for that range, and never ask the
> implementer to switch or reset the branch. Handle the task as
> **BLOCKED** at once, by the rule of your run mode in the rest of this
> paragraph only: no numbered remedy of **BLOCKED** applies, also not
> item 5 (advance to the next independent task), because this is a fault
> of the branch state, not of the implementer's capability, and the
> task's work is not yet reviewed. Interactive: ask the user one question
> that names the task, the range and the script's error line; after the
> user confirms that the branch is repaired, run the same
> `review-package BASE HEAD` call again with the same BASE. When it exits
> 3 again, ask the same question again. Batched Autonomous Mode: end the
> batch (Autonomy Policy) and journal under `## Open Issues`, marked
> blocking, this question:
> `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`,
> with N the task number and `<sha>` its BASE in full, because nothing
> else keeps BASE after /clear. Resume Procedure step 3 presents that
> question to the user and stops. After the user answers that the branch
> is repaired, run `review-package <the journaled BASE> HEAD` and the
> task review; record no new BASE and dispatch no implementer for the
> task. When the script exits 3 again, journal the same question again
> and end; never pick a new BASE yourself. An orchestrated batch
> controller follows its own prompt for this exit.

The first blockquote line continues the **DONE** paragraph; the
`**Exit 3.**` paragraph is new. The new text holds none of the counted
phrases of section 3. The batched entry is a question with fixed words, so
that Resume Procedure step 3 ("If `## Open Issues` contains a blocking
question and the resume prompt does not answer it, present the question to
the user and STOP", `SKILL.md:431-434`) applies to it without a new rule.

Why the batched entry holds BASE: the batch ends with the task's commits
on the branch and no review. BASE lives only in the controller's context
(Core Flow, `SKILL.md:67`, "Record BASE"); the `state.md` handoff has no
field for it (`SKILL.md:325-337`), and a completed task's ledger line
exists only after its review. After /clear, Resume Procedure step 2
("check `git log` for evidence it was already implemented … if so, mark
its checkbox complete and advance", `SKILL.md:426-430`) would find the
task's commits and mark it complete without a review. The journaled entry
keeps the task out of that shortcut and gives the resumed controller the
BASE of the failed call. If the user's repair removed some of the task's
commits, the package from the journaled BASE shows less work, and the task
reviewer reports what is missing under **Missing**, as for any package.

**SDD `SKILL.md:426-430` (Resume Procedure step 2).** Today the step ends
"… if so, mark its checkbox complete and advance." Append to the step:

> A task whose entry under `## Open Issues` asks
> `Is the branch of task N repaired?` (**Exit 3** under **DONE**, Handling
> Implementer Status) is not marked complete here and is not reviewed
> here: step 3 handles its entry.

Step 3 then presents the question and stops. After the user answers that
the branch is repaired, the **Exit 3** paragraph applies: the controller
runs `review-package <the journaled BASE> HEAD` and the task review.

No fast suite pins the text of step 2 (`grep -rn` over `tests/` for
`Reconcile position`, `already implemented` and `mark its checkbox` finds
nothing). The new sentence holds no `tick` substring and no `git commit`.

**`batch-controller-prompt.md:70-71`.** Today:

```
    `review-package BASE HEAD` per review (BASE = the HEAD you record
    before dispatching that task's implementer).
```

Replace with:

```
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

**`batch-controller-prompt.md:197` (Deviation 4, the start check).**
Replace the first line of the item,
`    4. Mid-task crash recovery: for each assigned task that is unchecked`,
with:

```
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

The rest of Deviation 4 (`:198-226`, from "when you start, set
REVIEW_BASE = …") stays. The in-run-rulings suite finds Deviation 4 by the
text `4. Mid-task crash recovery:` (`tests/in-run-rulings/run-tests.sh:3060`),
which stays at the start of the item, and its four assertions inside the
item (`:3062-3077`) keep their text. `<n>` is a task number of the plan,
as the Phase 3 discriminator requires (`SKILL.md:1661-1672`). None of the
new batch-controller text holds a bracketed uppercase token, and none
names a Core Flow step.

**Why the start check.** The orchestrator reads a `BLOCKED task=<n>`
without an unanswered section as a controller failure
(`batch-controller-prompt.md:176-177`). Its Phase 3 discriminator sends
such a return to "the existing path — retry the identical dispatch once,
then stop under the Major-Error Stop Policy" (`SKILL.md:1680-1685`), and
the policy's stop list holds "a batch-controller `BLOCKED` that the
Phase 3 discriminator classifies as a controller failure"
(`SKILL.md:2899-2900`) and "branch changed under you" (`:2905`). Without
the check, the retried controller would set REVIEW_BASE from the ledger,
dispatch the implementer again and meet the wrong range only at the next
review. With the check, a branch that lost completed work — the
git-ignored ledger still records it — makes the retry return the same
`review range invalid` line before it dispatches anything, and the run
stops for a human. When the branch still descends from the last
completed HEAD (for example, only a commit made after it was rewritten),
the retried controller passes the check, Deviation 4 builds the task's
package from REVIEW_BASE, which is then an ancestor of HEAD, and the
batch can complete. With no completed ledger line, no completed task's
work can be lost: the check is skipped, and the retry runs from the
current HEAD. A `<head7>` that git cannot resolve also gives a non-zero
exit, so the check stops loudly in that case too (measured on 2026-10-21,
git 2.50.1: `git merge-base --is-ancestor deadbee HEAD` prints
`fatal: Not a valid object name deadbee` and exits 128).

**Why after `sdd-workspace PLAN_FILE`.** The template runs that script
"once at start (idempotent for the same plan)"
(`batch-controller-prompt.md:68-69`), and it archives a workspace that
another plan left (`archive_workspace`, `sdd-workspace:60-75`). Run after
it, the check reads this plan's own ledger, or none. Run before it, the
check could read the ledger of a different plan and stop on HEADs that
this run never recorded.

**The second cause: a ledger left from an earlier run.** `Abandon
orchestration` deletes the feature branch
(`skills/orchestrating-development/SKILL.md:1563-1566`: "confirm once,
then delete the feature branch … and state what remains") and does not
touch the git-ignored `.superpowers/sdd/` workspace. When the same plan
is orchestrated again in the same checkout, `sdd-workspace PLAN_FILE`
finds the same `plan.ref` and archives nothing, so the old ledger stays
and its completed lines name HEADs that the new branch does not hold. The
check then stops the first batch before any dispatch. That stop is
correct (the ledger does not describe this branch), but its repair is
different: the user removes or archives `.superpowers/sdd/progress.md`
and the stale `.superpowers/sdd/preflight.md`. The return line therefore
names both causes, and so does the guide (section 4.10). The abandon step
does not change; section 8 item 10 records this as an accepted limit.

This matches the rule for a **fatal environment failure**: it "stays a
controller `BLOCKED` return handled by the Major-Error Stop Policy — it is
never classified as `forced`" (`SKILL.md:1650-1652`). The escalation list
(`SKILL.md:1622-1648`) has no entry for a branch state, and a ruling
cannot repair a branch that was switched, reset or rewritten, so neither
return carries a question section. Interactive SDD (ask the user) and
Batched Autonomous Mode (journal and end the batch) keep the rules of the
SDD **Exit 3** paragraph above. The batch controller follows SDD's
"Handling Implementer Status" by reference (`:52-58`), so it reads the
empty-package sentence there.

**multi-code-review `SKILL.md`, Error Handling.** An empty range needs no
new rule here: the Error Handling bullet at `:1760-1761` already reads
"Empty or invalid range (BASE = HEAD, no merge-base, or BASE does not
resolve to a commit) → stop and report; nothing dispatched.", and the
BASE resolution stops on the same states before round 1 (`:62-64`).
Insert a new bullet between that bullet and the fallback bullet that
starts at `:1762`:

```
- `review-package` exits 3 (HEAD does not descend from BASE: the branch
  changed under the loop) → fatal: stop the whole invocation and return
  `BLOCKED: review range invalid — <the script's error line>`; nothing
  dispatched. The failed round owes no round entry, because no reviewer
  report of it was received; the entries of earlier rounds keep their
  dispositions. The no-package fallback of the next bullet never applies
  to exit 3.
```

This is the fatal-failure rule of Procedure (`SKILL.md:472-501`): "A
failure that happens before any reviewer report of the round was received
owes no round entry" (`:487-488`), and "the controller then returns
`BLOCKED: <cause>`, naming the failure in the wording of Error Handling"
(`:499-500`). The return fits the `BLOCKED: <reason>` form that the
orchestrated code-review controller allows
(`code-review-loop-prompt.md:243`, `:283`).

The fallback bullet keeps its first line
``- `review-package` missing or failing → dispatch with `[PACKAGE_FILE]` =``
unchanged, because `tests/reviewer-templates/run-tests.sh:929` extracts the
bullet by that first line. The fallback still applies to every other
failure (a missing script, exit 2). The new bullet names no `git diff`
command, so `CODE_SKILL_PROSE_MENTIONS=1` (`:934-935`) stays true.

**multi-code-review `reviewer-prompt.md:265-272`** (the placeholder legend,
outside the prompt block). Replace "When the script is missing or failing,"
on line 267 with "When the script is missing or fails with an exit code
other than 3,", and append after "no-package form." on line 272 the
sentence " On exit 3 nothing is dispatched (SKILL.md, Error Handling)."

#### 4.3.3 Why an empty range stays valid and exit 3 is BLOCKED

An empty range is not a wrong range. Today it already reaches the task
reviewer, which judges the task against its brief, so a task that skipped
its changes fails visibly under **Missing**. The new line only states the
fact, so that neither the controller nor the reviewer takes an empty diff
for a broken package. Earlier drafts of this design made an empty range
exit 3 and added a completion path for a task that committed nothing, with its
own ledger, return and log forms and its own BASE rules. Review rounds
kept finding holes in that path, and the user removed it on 2026-10-21.

A HEAD that does not descend from BASE is a wrong range: the two-dot diff
shows the task's own work as deleted. No correct package exists, and an
implementer dispatch could repair it only by changing the branch, which
no worker is asked to do. BLOCKED uses paths that exist in all three run
modes: interactive SDD asks the user, Batched Autonomous Mode journals a
blocking question that holds the task's BASE and ends the batch, and the
orchestrated batch controller returns a `BLOCKED task=<n>` with no
question section, which the orchestrator
handles as a major error and stops for a human. A question section would
make exit 3 an in-run ruling item, and no ruling can repair a branch
state. Orchestrated runs always use the range form, because their batches
run tasks one at a time.

### 4.4 D8 — evidence that cannot be read is not missing evidence

**Current.** `skills/subagent-driven-development/task-reviewer-prompt.md:95-107`
(`## Tests`) forbids re-running the suite and ends with "Warnings or other
noise in the implementer's reported test output are / findings — test output
should be pristine." (`:106-107`). No sentence covers a report or evidence
that the reviewer cannot read. The paging rule at `:69-81` already tells the
reviewer to open files with the Read tool and to page until no PARTIAL
notice remains.

**Change 1 — `task-reviewer-prompt.md`, after line 107** (inside
`## Tests`, before `## Part 1: Spec Compliance` at `:109`), add one blank
line and:

```
    Evidence you cannot read is not missing evidence. If the report or its
    test evidence looks cut off, or you cannot find a result that the
    report claims, read the report file again with the Read tool, paging
    as described above. If the evidence is still missing or cannot be
    read after that, report it as a ⚠️ "Cannot verify from diff" item —
    never as a ❌ finding that the evidence does not exist — and do not
    run a test to produce the evidence again, also not a focused one.
```

The last clause covers only evidence that cannot be read. The focused-test
permission of the paragraph above (`:99-104`, "Run a test only when reading
the code raises a specific doubt that no existing run answers — and then a
focused test") does not change and still applies to its own case: a
specific doubt that reading the code raises.

**Change 2 — the output line `task-reviewer-prompt.md:176-178`.** Replace:

```
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]
```

with:

```
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and test evidence in the report that you could not read,
      and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]
```

**Change 3 — SDD `SKILL.md:491-492`** (Handling Reviewer ⚠️ Items). Replace
"requirements that live in unchanged code or span tasks." with
"requirements that live in unchanged code or span tasks, and test evidence
in the implementer's report that the reviewer could not read." The rest of
the paragraph stays: the controller resolves each item itself, and a real
gap (the evidence is truly absent) is "a failed spec verdict — send it back
to the implementer and re-review". At the end of the paragraph (after
"send it back to the implementer and re-review." on line 496), append:

> For an item about test evidence, read the report file that holds the
> evidence with the Read tool, paging until no PARTIAL notice remains. If
> the evidence is still unreadable or absent, it is a real gap: send the
> task back to the implementer to re-run the tests and write the command
> and its output into the report file, then re-review.

"Write … into", not "append … to": a re-dispatched implementer rewrites
its report file ("The task's implementer rewrites that report file",
`batch-controller-prompt.md:134-135`, Deviation 1; the template says
"Write your full report to [REPORT_FILE]", `implementer-prompt.md:172`).

The batch controller follows "Handling Reviewer ⚠️ Items" by reference
(`batch-controller-prompt.md:52-58`), so the same rule reaches it with no
change to its template.

**Not changed.** `skills/multi-code-review/reviewer-prompt.md` `## Tests`
(`:157-162`) is pinned whole (`CODE_TESTS_SECTION`,
`tests/reviewer-templates/run-tests.sh:1002`, asserted at `:1040`), and its
reviewer gets no implementer report.

### 4.5 D4 — the conflict scan writes a table to its own file

**Current.** `skills/subagent-driven-development/SKILL.md:203-216`:

```
## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for conflicts:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a
  defect (a test that asserts nothing, verbatim duplication of a logic block)

Present everything you find to the user as one batched question — each
finding beside the plan text that mandates it, asking which governs —
before execution begins, not one interrupt per discovery mid-plan. If the
scan is clean, proceed without comment. The review loop remains the net for
conflicts that only emerge from implementation. (In Batched Autonomous Mode
a pre-flight conflict is a blocker — journal it and end the batch.)
```

**Change — SDD `SKILL.md:203-216` only.** Replace the section with:

```
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
written). The review loop remains the net for conflicts that only emerge
from implementation. (In Batched Autonomous Mode a pre-flight conflict is a
blocker — journal it and end the batch.)
```

**Why its own file, not the ledger.** No reader of the ledger matches a
line by its first characters. Core Flow step 1 reads "Tasks it marks
complete" (`SKILL.md:64`); the batch controller reads a "completed ledger
line" (`batch-controller-prompt.md:142`, `:198-199`); the code-review
controller takes "its `Minor:` lines" (`code-review-loop-prompt.md:91-93`).
These are agents that read prose, so a table cell that held such text could
be read as a ledger line, although a Markdown table row starts with `|`.
`.superpowers/sdd/preflight.md` keeps the table away from every ledger read
and needs no rule on the text of a cell. The file is in the SDD workspace,
so the workspace `.gitignore` covers it, and `archive_workspace`
(`sdd-workspace:60-75`) moves it into `archive/<slug>/` with every other
entry when a different plan starts.

**Why one row per path or name, not per pair.** A row per pair of linked
tasks grows with the square of the number of tasks that share one path:
ten tasks that all edit `RELEASE-NOTES.md` would give 45 rows. One row per
shared path or shared name lists every task that mentions it, so the table
grows linearly: one row per link plus one row per task.

**One term per thing.** The text calls the link between tasks a `path`
everywhere, and the `Row` value for it is `path` too, so a reader never
has to decide whether `file` and `path` name two kinds of row. "The files
it creates" in the task row keeps its plain meaning.

The three decision rules stay as they are, and a row whose `Found` is not
`none` goes through them as any other finding of the scan: interactive
asks the user; Batched Autonomous Mode journals and ends the batch
(`SKILL.md:408`); orchestrated returns `BLOCKED task=<n>` by the batch
controller's pre-flight rule (`batch-controller-prompt.md:150-159`), which
does not change.
Upstream's sentences "Rule on everything you find before execution begins …
record each ruling in the ledger" and "the spec is the binding authority" are
**not** ported: copied whole, they make the controller decide conflicts.
(Upstream v7.0.0 `skills/subagent-driven-development/SKILL.md:176-180`,
checked on 2026-10-21; the section 7.1 test uses the first two phrases as
negative needles.)

**Why "once per plan".** The batch controller runs the pre-flight review
"on every re-dispatch" (`batch-controller-prompt.md:166-167`) and follows the
SDD section by reference (`:92`). The "once" rule in SDD therefore also stops
a second table on a re-dispatch, and `batch-controller-prompt.md` needs no
change for D4. The rule skips only the write: the scan itself still runs
on every start and every re-dispatch, as today, and a conflict that it
finds is handled as today (the batch controller "derives the same conflict
again over unchanged plan text", `batch-controller-prompt.md:167-168`).
The file is plan-scoped: a different plan gets a fresh
workspace (`sdd-workspace` archives the old one), so its table is written
again. After an `amend plan` ruling the table can describe the plan before
the amendment; the ruling itself is recorded by the ruling mechanism. A
run of the same plan that starts again after an abandon keeps the old
file, so no new table is written (section 8 item 10).

**Wording checks.** The new text contains none of the phrase-count phrases
of section 3 (no `git commit`, no `chore(plan)`, no substring `tick`, no
wave line). The section 7.1 test pins the wording of the row rules only;
no test checks that a real scan writes a complete table (one row for
every shared path, every shared name and every task), because the table is
written by an agent at run time. `PREFLIGHT_CRITERION` and
`RUBRIC_PARENTHETICAL` (`tests/reviewer-templates/run-tests.sh:447-453`)
stay in the section.

### 4.6 D6 — workers do not dispatch subagents

Add the sentence `Do NOT dispatch subagents.` to the first rule of exactly
four worker templates. The wording is the one of
`skills/multi-code-review/fix-prompt.md:26-27`. The placement differs per
template:

- In the two SDD templates the first rule is the sentence that SDD
  `SKILL.md:595` says every subagent prompt MUST include, and that
  `batch-controller-prompt.md:20-23` quotes: "You are a focused subagent.
  Do NOT invoke any skills from the superpowers-orchestrator plugin. Do NOT
  use the Skill tool. Your only job is the task described below." That
  sentence stays one unbroken piece, so the new sentence goes **after**
  "Your only job is the task described below.".
- In the two review-loop reviewer templates the first rule is a bullet
  that holds no such quoted sentence; the new sentence goes right after
  `Do NOT use the Skill tool.`, at the end of that first bullet. This keeps
  `CODE_SHARED_IN_PLACE` and `DOC_SHARED_IN_PLACE` green (see Placement).

| File:lines | New text (indentation as in the file) |
|---|---|
| `skills/subagent-driven-development/implementer-prompt.md:15-17` | `You are a focused subagent. Do NOT invoke any skills from the` / `superpowers-orchestrator plugin. Do NOT use the Skill tool. Your only job` / `is the task described below. Do NOT dispatch subagents.` |
| `skills/subagent-driven-development/task-reviewer-prompt.md:23-25` | the same three lines |
| `skills/multi-code-review/reviewer-prompt.md:31-32` | `- Do NOT invoke any skills from any plugin. Do NOT use the Skill` / `  tool. Do NOT dispatch subagents.` |
| `skills/multi-doc-review/reviewer-prompt.md:33` | `- Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.` / `  Do NOT dispatch subagents.` |

(`/` marks a line break.)

**Where the sentence must not go.** No controller text gets it: the five
files of `skills/orchestrating-development/` (`SKILL.md`,
`batch-controller-prompt.md`, `code-review-loop-prompt.md`,
`doc-review-loop-prompt.md`, `plan-writer-prompt.md`),
`skills/multi-code-review/SKILL.md`, `skills/multi-doc-review/SKILL.md` and
`skills/subagent-driven-development/SKILL.md`. Controllers must dispatch
workers. On 2026-10-21 none of these eight files holds the sentence, folded
or not. The quoted leakage sentence in `batch-controller-prompt.md:20-23` and
`SKILL.md:595` stays unchanged.

**Placement.** The first rule is not pinned: on 2026-10-21 no fast suite
holds the needles `focused subagent`, `Your only job` or
`Do NOT use the Skill` (searched in every `tests/*/run-tests.sh`, in
`tests/reviewer-templates` and `tests/orchestrating-development`
included). A new bullet at the end of the
rules list of the two review templates would break `CODE_SHARED_IN_PLACE`
and `DOC_SHARED_IN_PLACE` (`tests/reviewer-templates/run-tests.sh:1012-1013`,
asserted at `:1037-1038`); appending to the first bullet keeps them green
(measured for the review templates: all 323 checks pass). `FIX_RULE_CLAUSES`
(`:53-65`) pins `fix-prompt.md`, which does not change. The D6 test of
section 7.1 pins the unbroken MUST-include sentence in both SDD templates.

### 4.7 C9 — failures the implementer did not cause

**Change 1 — `skills/subagent-driven-development/implementer-prompt.md:55-56`.**
Today:

```
    While iterating, run the focused test for what you're changing; run the
    full suite once before committing, not after every edit.
```

Replace with:

```
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

The parenthesis states in the template that a failing test that the task
itself writes or changes is the task's own work. The "unless" clause keeps
a task whose brief or dispatch asks for the fix of that test inside its
own scope. The criterion "neither is a file that your task changes nor
imports or reads one" can be checked from the task's own file list and
the test's source; "reads" covers a test that checks the text of a file,
as the fast suites of this repository do. "Commit your work as
usual" keeps the task's commits on the branch, so the review package
holds the task's work. The implementer names the test in the two places
that already carry concerns: the report file ("Any issues or concerns",
`implementer-prompt.md:180`) and the status return ("Your concerns, if
any", `:188`). The new text holds none of the counted phrases of
section 3 (`whole tree`, `git status`, `git diff`, `formatter`,
`current HEAD` and the others; "commit your work" is not `git commit`).
The text stays above `## Commit Messages` (`:58`), whose whole section is
pinned.

**Change 2 — `skills/test-driven-development/SKILL.md:96`** (last item of
`## Completion Checklist` at `:91`). Replace `- [ ] Relevant suite passes.`
with these two items:

```
- [ ] Relevant suite passes, apart from failures named under the next item.
- [ ] A test outside your task that fails, and that your change did not cause, is not fixed: it is named in your report (status `DONE_WITH_CONCERNS` when your report carries a status), or in your reply to the user when you work in the main session, with the test's failing output and the reason why your change did not cause it. Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one. A test that your task writes or changes is not outside your task. In the main session, your task is the change the user asked for.
```

The last sentence defines "your task" for an agent that has no task
brief: in the main session it is the change the user asked for, so a
failing test that the user asked to fix is inside the task.

Both files get the rule because they reach different agents: SDD
implementers never read the TDD skill ("Do NOT use the Skill tool"), and the
TDD skill reaches the main session and `executing-plans`. No wave-specific
sentence is added: in a wave, an implementer that sees a sibling task's
failure names it and does not fix it, and the controller runs integration
verification after the wave (wave step 4, `SKILL.md:227`).

**Downstream: no change.** No other file gets C9 text: not SDD
`SKILL.md`, not `task-reviewer-prompt.md`, not
`batch-controller-prompt.md`. The concern then takes today's path:

- **The controller** handles it under the existing **DONE_WITH_CONCERNS**
  rule (SDD `SKILL.md:443`): "Read the concerns before proceeding. If the
  concerns are about correctness or scope, address them before review. If
  they're observations (e.g., "this file is getting large"), note them and
  proceed to review." The implementer names the test "as an observation,
  not as a doubt about your own work", so the controller takes the second
  branch: it notes the concern and proceeds to review, and the task
  reviewer decides whether the failure is a finding. The batch controller
  follows "Handling Implementer Status" by reference
  (`batch-controller-prompt.md:52-58`).
- **The task reviewer** reads the report file (`task-reviewer-prompt.md:36`,
  "Read the implementer's report: [REPORT_FILE]"), which names the test.
  Its existing rule "Warnings or other noise in the implementer's reported
  test output are findings — test output should be pristine."
  (`:106-107`) may report the failing test as a finding.
- **A fix subagent** may then fix it: Core Flow step 3 (`SKILL.md:75`)
  dispatches "ONE fix subagent for all of them", which appends to the
  report file, and the task is re-reviewed.

**Why this is acceptable.** C9 targets one fault: the implementer's
uncontrolled scope change, an implementer that edits code outside its
brief to make an unrelated test pass, without a reviewer being told why.
A fix that the review gate orders is a different thing: a deliberate,
reviewed change. A reviewer names the finding, one fix subagent makes the
change, and the task is re-reviewed. No failure is ever accepted
silently: the implementer names it in its status return and in its
report file, the controller reads the concern, and the task reviewer
reads the report. The user decided on 2026-10-21 that C9 adds this
implementer rule only, with no new stop and no new ruling; section 8
item 8 records the limit that follows.

### 4.8 Copilot CLI marked as no longer supported

Same form as the Codex change of commit `4f15206` (2026-09-21): add a note,
keep the history and every file, give no reason.

| File:line | Today | New text |
|---|---|---|
| `README.md:3` | badge `USE_WITH-Claude_Code_%7C_Copilot_CLI` | `[![AI Coding Agents](https://img.shields.io/badge/USE_WITH-Claude_Code-white?style=for-the-badge)]()` |
| `README.md:14` | "(Claude Code and GitHub Copilot CLI, which are the two it has been used with — Copilot CLI only up to v7.13.0, so later releases are untested there; Cursor and OpenCode integrations exist but are untested, and Codex is no longer supported — see [Platform status](#installation))" | "(Claude Code and GitHub Copilot CLI, which are the two it has been used with — Copilot CLI only up to v7.13.0; Cursor and OpenCode integrations exist but are untested, and Copilot CLI and Codex are no longer supported — see [Platform status](#installation))" |
| `README.md:54` | "In Claude Code or Copilot CLI, start a new chat and paste:" | "In Claude Code, start a new chat and paste:" |
| `README.md:461-463` | "… **Copilot CLI** was last used with v7.13.0 …" | "… **Copilot CLI** (no longer supported since 2026-10-21) was last used with v7.13.0 …"; the rest of the paragraph (`:461-472`) stays |
| `README.md:525` (Codex note) | "Use Claude Code or GitHub Copilot CLI." | "Use Claude Code." |
| `README.md:622-624` | heading `### GitHub Copilot CLI`, then the status line | insert the note below between the heading and the status line (one blank line on each side); the section stays |
| `docs/guide/README.md:33-34` (§1) | "(Claude Code, Cursor, OpenCode, GitHub Copilot CLI, and Codex, which is no longer supported)" | "(Claude Code, Cursor and OpenCode; GitHub Copilot CLI and Codex are no longer supported)" |
| `docs/platforms/codex.md:9` | "… Use Claude Code or GitHub Copilot CLI." | "… Use Claude Code." |
| `.codex/INSTALL.md:7` | "… Use Claude Code or GitHub Copilot CLI." | "… Use Claude Code." |

The note for `README.md` `### GitHub Copilot CLI`:

```
> **No longer supported (since 2026-10-21).** GitHub Copilot CLI is no
> longer a supported platform of Superpowers Orchestrator. The Copilot CLI
> text in this section and in the skills stays in the repository, but
> Copilot CLI is no longer maintained or reviewed as a platform. Use
> Claude Code.
```

**Pins that stay green** (`tests/orchestrating-development/run-tests.sh:633-662`):
the README keeps "`orchestrating-development` refuses to run on Copilot CLI"
(`README.md:659`) and "`orchestrating-development` runs on Claude Code only
and refuses on OpenCode"; the guide keeps "§4's orchestration runs on Claude
Code only", "Copilot CLI and OpenCode have never run it" (`:50-53`) and "On
any other platform, Copilot CLI included, the skill refuses with one line."
(`:636-638`). None of the edits above touches those sentences.

`.claude-plugin/*.json`, `plugin.universal.yaml`, `hooks/` and `CLAUDE.md`
hold no Copilot statement. There is no `docs/platforms/copilot*.md`.

### 4.9 Accepted limits in the local issues log

`docs/orchestration-issues.md` is local and untracked: `.git/info/exclude`
ignores it, and it is absent in a fresh clone and in a linked worktree.
This step edits the file in the main checkout only and is never committed.
The step locates the main checkout first, also when it runs in a linked
worktree: the main checkout is the parent folder of the path that
`git rev-parse --path-format=absolute --git-common-dir` prints (in this
repository: `.../Superpowers/.git`, so `.../Superpowers`). The option
`--path-format` needs git 2.31 or later (git 2.31.0 release notes:
"git rev-parse" can be explicitly told to give output as absolute or
relative path with the `--path-format=(absolute|relative)` option). The
README states no minimum git version; this machine has git 2.50.1. The
step tests for `docs/orchestration-issues.md` in that folder. When the
file is absent there, the step is skipped, and the report of the plan task
that runs this step (the release task) says so. The append runs once: before
it, the step runs `grep -F -- '(upstream A10)' <file>`; when a line holds
that text, the entries are already there (from an earlier run of the
step), nothing is appended, and the task's report says so.

Append these five entries to `## Accepted limits` (format of that section:
date, state, consequence, who found it). Upstream's fixes for them are not
ported. Windows Git Bash is in the supported environment, but none of these
states has a case, and none loses user work or makes a wrong commit, so the
admission rule gives no worklist row. The user decided on 2026-10-21 to
record them here and not to port them in this release.

```
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
```

And this note, as one more entry of the same section:

```
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

### 4.10 Release v7.74.0 and documents

**Version bump** (every file `CLAUDE.md` "Releases" lists): `VERSION`
(`7.73.1` → `7.74.0`); `.claude-plugin/plugin.json:4`;
`.claude-plugin/marketplace.json:13`; `plugin.universal.yaml:7`;
`README.md:6` (static version badge); the two `v6.7.0–v7.73.1` ranges at
`README.md:22` and `README.md:24`.

**`RELEASE-NOTES.md`** — a new entry above `## v7.73.1`, starting with this
summary:

```
## v7.74.0 — fixes ported from upstream v7.0.0; Copilot CLI no longer supported

**Problem.** `sdd-workspace` reset a committed `.superpowers/sdd/.gitignore` on every call. `review-package` packaged a reversed range as a diff that deletes the task's work. A systematic-debugging example printed a secret value.

**Change.** Seven upstream fixes: create-only `.gitignore`; `review-package` exit 3 for a reversed range (the loop stops or the task is BLOCKED) and a `Commits in range: none` line for an empty one; a safe secret check; unreadable evidence is a ⚠️ item; a pre-flight scan table; four worker templates forbid subagent dispatch; an implementer reports a failing test outside its task and does not fix it. Copilot CLI is no longer supported.

**Effect.** Reinstall the plugin. A repository that committed its own `.superpowers/sdd/.gitignore` restores its version once.
```

The full prose below the summary covers each item of section 2 with its
files, the new exit code 3 of `review-package` and its three caller rules
(in an orchestrated run, exit 3 is a stop under the Major-Error Stop
Policy, not a ruling; in Batched Autonomous Mode, the blocking question
`Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`
under `## Open Issues`, which the resumed session asks before it reviews
the task from that BASE, and journals again on a repeated exit 3; in
interactive mode, a repeated exit 3 asks the same question again), the
start check of the batch controller and its two
causes (a changed branch, or a ledger left from an abandoned or earlier
run of the plan) with their two repairs, the exit 2
for a BASE or HEAD that is not a commit, the `Commits in range: none` line
of an empty range, the implementer rule for a failing test outside its
task (named in the report as an observation, with its failing output and
the reason, not fixed; the controller proceeds to review, and the task
reviewer and the fix subagent keep their existing rules), the new file
`.superpowers/sdd/preflight.md`, the fact that a committed ledger
`progress.md` makes an orchestrated run stop at the next batch boundary or
at Phase 5 (section 4.1), the five accepted limits (as "not ported"), and
the four rejected items of section 5. Every statement of the summary must
be supported by that prose.

**`docs/guide/README.md`** (not synchronized automatically):

- **§1** (`:33-34`): the Copilot CLI change of section 4.8.
- **§3 Stage 2** (`:314-321`): after "read the `Owed:` list yourself." on
  line 321, append to the same paragraph: "Since v7.74.0 that review writes
  what it compared as a table into `.superpowers/sdd/preflight.md`:
  one row for each path that the **Files:** lists of two or more tasks
  name, and one row for each name that the text of two or more tasks
  mentions, each row listing every task that mentions that path or name;
  and one row for each task. It runs the scan at every start, as before,
  but writes the table only once per plan. The table only
  records the scan: a conflict is still asked of you (interactive), ends the
  batch (batched mode), or goes to the orchestrator (orchestrated run)."
- **§3 Stage 3** (`:347-350`): after the paragraph that ends "moment the
  task completes.", add a paragraph: "Since v7.74.0 an implementer that sees
  a test outside its task fail, and its own change did not cause the
  failure, does not fix it, unless its brief or its dispatch names that
  test as part of the task. Its change did not cause the failure when the test neither is
  a file that the task changes nor imports or reads one. It commits its
  work as usual, reports `DONE_WITH_CONCERNS`, and names the test as an
  observation, with the test's failing output and that reason. The
  controller therefore proceeds to the task review, and the task reviewer
  decides whether the failure is a finding, so a fix, when one is made,
  goes through the review gate. In the main session, the test-driven
  development checklist has the failure named in the reply to you. In
  batched mode, a task whose review range is wrong ends the batch with the
  blocking question
  `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`
  under `## Open Issues`. The next session asks you that question and
  stops; after you answer that the branch is repaired, it reviews that
  task from that BASE before it goes on. If the range is still wrong, it
  writes the same question under `## Open Issues` again and stops. In
  interactive mode the controller asks
  you at once, and asks again after each repair that leaves the range
  wrong. A task that
  committed nothing still gets its task review; its review package then says
  `Commits in range: none`. Implementers and the reviewers of SDD and of
  the two review loops do not dispatch subagents of their own."
- **§4 "When it stops instead of finishing"** (`:827`): insert before the
  paragraph that starts "A review finding that merely differs" (`:857`) a
  paragraph: "Since v7.74.0, when a task's review range is wrong — the
  branch HEAD no longer descends from the commit recorded before the task,
  because the branch was switched, reset, or rewritten by an amend or a
  rebase — the batch controller returns
  `BLOCKED task=<n>: review range invalid — <the script's error line>`
  with no question. The orchestrator treats that return as a major error
  and retries the batch once. The retried controller first checks that
  the branch still descends from the HEAD of the last completed task in
  the ledger `.superpowers/sdd/progress.md`; when it does not, the retry
  returns the same kind of line at once, and the orchestrator stops and
  reports the error. That check stops for one of two causes. Either the
  branch was switched, reset, or rewritten: repair the branch, then resume
  the run. Or the
  ledger is left from an abandoned or earlier run of the same plan
  (abandoning a run deletes its branch, but not the ledger): remove or
  archive `.superpowers/sdd/progress.md`, and the stale
  `.superpowers/sdd/preflight.md` with it, then start the run again. A
  review loop whose range turns wrong in the same way stops the whole
  invocation and returns
  `BLOCKED: review range invalid — <the script's error line>`."
- **§9 Troubleshooting** (`:1541`): add an entry after the "I edited a
  skill but behavior didn't change." entry: "**My committed
  `.superpowers/sdd/.gitignore` was reset to `*`.** Before v7.74.0 every SDD
  script call rewrote the file. Since v7.74.0 the scripts create it only
  when it is missing or empty, so a version you commit stays as you wrote
  it. If you also commit the ledger `progress.md`, it is part of the
  branch, the whole-branch reviewers see it, and an orchestrated run stops
  at the next batch boundary or at Phase 5, because every ledger write
  leaves the working tree dirty."

No guide section quotes the systematic-debugging example (A17) or the task
reviewer's evidence rules (D8). The guide does not describe the
multi-code-review no-package fallback, so "When the review loop's prompt
delivery fails" (`:414`) does not change.

`docs/FORK-IMPROVEMENTS.md` does not change. No Codex-facing behaviour
changes (only two Codex documents get the one-sentence edit of section 4.8),
so `tests/codex/post-push-validation-checklist.md` is not needed.

## 5. Rejected items

| Item | Reason |
|---|---|
| **D7** — read the spec at SDD setup; "conflicts inside the plan resolve against it" | It contradicts the fork's rule that the controller never decides a plan conflict (interactive: the user; orchestrated: the orchestrator, `batch-controller-prompt.md:155-158`). It also costs about 8-16K tokens per batch controller (an estimate, not a measure: an earlier verification pass of 2026-10-21 found that the 28 specs of this repository average 32.7 KB, the largest 66 KB, and 32.7 KB and 66 KB at about 4 bytes per token give about 8K and 16K tokens), 2 to 6 batch controllers per run (the same pass, from 5 recent orchestration logs), and again after every `/clear` in Batched Autonomous Mode. |
| Upstream C9 as written — "the project's whole suite defines green", "run the project's test command … even when your task named only one test file" | This repository has no single test command (20 fast suites, about 190 s together, above the Bash tool's default 120 s time-out — source: https://code.claude.com/docs/en/env-vars, checked on 2026-10-21, `BASH_DEFAULT_TIMEOUT_MS` "default: 120000, or 2 minutes" — plus claude-CLI suites with real API cost). Wave implementers share one working tree, so a whole-suite run sees the unfinished edits of sibling tasks. Only the reporting rule is ported (section 4.7). |
| Copilot CLI session-start fix (print the top-level `additionalContext` when `COPILOT_CLI` is set) | Copilot CLI is no longer a supported platform (section 4.8). |
| Copying the whole upstream SDD `SKILL.md` | Upstream forbids parallel implementers ("Never dispatch multiple implementation subagents in parallel"); the fork's default is Parallel Waves (`SKILL.md:218-232`). Only single items are ported. |

## 6. Error handling

- `review-package` range mode: exit 3 with the one line
  `HEAD is not a descendant of BASE: <base>..<head>` on standard error; no
  file written. Exit 0 keeps its meaning; for an empty range the package's
  `## Commits` section holds the line `Commits in range: none`. Exit 2
  keeps its meaning and now also covers a BASE or HEAD that names a tree or
  a blob (`bad BASE: <arg>` or `bad HEAD: <arg>`). `--commits` mode never
  exits 3.
- SDD, empty package (a task that committed nothing): the controller
  dispatches the task reviewer as for any package; the reviewer judges the
  task against its brief and the report (a task that had to change files
  is a ❌ under **Missing**).
- Exit 3 of `review-package BASE HEAD` in SDD (the branch was switched or
  reset, or a commit at or before BASE was rewritten by an amend or a
  rebase): no task reviewer, no implementer re-dispatch, no request to
  switch or reset the branch; BLOCKED at once, with none of the numbered
  remedies of **BLOCKED** (also not item 5, advance to the next
  independent task). SDD interactive → one question to the user that names
  the task, the range and the script's error line; after the user
  confirms a repair, the same `review-package BASE HEAD` call again with
  the same BASE; on a repeated exit 3, the same question again. SDD
  Batched Autonomous Mode → the batch ends with the blocking question
  `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)`
  under `## Open Issues`; on resume, step 2 of the Resume Procedure
  neither marks that task complete nor reviews it, and step 3 presents
  the question and stops. After the user answers that the branch is
  repaired, the controller runs `review-package <the journaled BASE> HEAD`
  and the task review; it records no new BASE and dispatches no
  implementer. On a repeated exit 3 it journals the same question again
  and ends; it never picks a new BASE itself. Orchestrated batch controller →
  `BLOCKED task=<n>: review range invalid — <the script's error line>`
  with no `### Question <k>` or `### Conflict <k>` section; the
  orchestrator reads it as a controller failure, retries the identical
  dispatch once, then stops under the Major-Error Stop Policy.
- Batch controller start check (Deviation 4, after `sdd-workspace
  PLAN_FILE` and before the Pre-Flight Plan Review): the HEAD of the last
  completed ledger line is not an ancestor of HEAD, or git cannot resolve
  it (the branch was switched, reset or rewritten, or the ledger is left
  from an abandoned or earlier run of this plan) → dispatch nothing,
  return
  `BLOCKED task=<n>: review range invalid — HEAD does not descend from the last completed ledger HEAD <head7> (branch switched, reset or rewritten, or ledger left from an earlier run of this plan)`
  with `<n>` the first unchecked task of the batch's task list; handled as
  the line above. No completed ledger line → the check is skipped. The
  user repairs the branch, or removes or archives
  `.superpowers/sdd/progress.md` and `.superpowers/sdd/preflight.md`.
- multi-code-review: exit 3 → fatal: the whole invocation stops and returns
  `BLOCKED: review range invalid — <the script's error line>`; nothing
  dispatched; the failed round owes no round entry, and the entries of
  earlier rounds keep their dispositions. An empty range stays the existing
  stop before round 1 (`SKILL.md:62-64`, `:1760-1761`). Any other failure
  of `review-package` keeps the no-package fallback.
- C9: an implementer that sees a test outside its task fail, not caused by
  its change (the test neither is a file that the task changes nor imports
  or reads one), does not fix it, unless its brief or the controller's
  dispatch names that test as part of its task; it commits its work as
  usual, reports DONE_WITH_CONCERNS and names the test as an observation,
  with the test's failing output and that reason. A test that the task
  writes or changes is the task's own. The controller (existing
  **DONE_WITH_CONCERNS** rule, observation branch) notes the concern and
  proceeds to review; the task reviewer (existing rule on test output)
  decides whether the failure is a finding; the fix subagent handles a
  finding as today; no new stop and no new ruling. In the main session
  "your task" is the change the user asked for, and the TDD checklist has
  the failure named in the reply to the user.
- Task reviewer ⚠️ item for unreadable test evidence: the controller reads
  the report file with the Read tool, paging; still unreadable or absent →
  the task goes back to the implementer to re-run the tests and write the
  command and its output into the report file, then re-review.
- `sdd-workspace`: a `.gitignore` that is not empty is never read or
  changed; an absent or empty one is written as `*`; the script's exit
  codes do not change.
- Pre-flight scan: `.superpowers/sdd/preflight.md` already exists → the
  scan still runs and its conflicts are handled as before; only the table
  is not written again. A row whose `Found` is not `none` is a conflict
  and goes through the existing Pre-Flight rules of the run mode.
- Accepted-limits step (section 4.9): `docs/orchestration-issues.md`
  absent, or a line already holds `(upstream A10)` → nothing is appended;
  the release task's report says which.

## 7. Testing

Tests check behaviour through the scripts' command lines where a script
exists; skill text is checked with folded wording pins, as the existing
suites do.

### 7.1 New tests

| Suite | Section | Assertions |
|---|---|---|
| `tests/sdd-scripts/run-tests.sh` | new section `sdd-workspace (create-only .gitignore)`, placed after line 104, in its own fixture repository (created with `mktemp -d` and resolved with `pwd -P` like `$REPO`, initialised with `git -c init.defaultBranch=main init` as `tests/smart-compress/run-tests.sh:467` does, so that the branch name `main` does not depend on the user's git settings, removed at the end of the section) so that the shared fixture keeps its state | Fixture files, both committed at the repository root: `planA.md` holds the two lines `### Task 1: x` and `Body of task A.`; `planB.md` holds the two lines `### Task 1: y` and `Body of task B.`, so it is a different plan. (`task-brief` prints the lines from a heading `Task 1` of any level up to the next heading with as many `#` characters or fewer, and exits 3 when that output is empty, `task-brief:46-71`; measured on 2026-10-21: each file gives a two-line brief, and `sdd-workspace planB.md` then archives the planA workspace.) The first commit adds `.superpowers/sdd/.gitignore` with the three lines `*`, `!.gitignore`, `!progress.md`; the second commit adds `planA.md` and `planB.md`. (1) Run `sdd-workspace`, `sdd-workspace planA.md`, `task-brief planA.md 1` and `review-package <first commit> HEAD` (each calls `sdd-workspace`). After each call, `cmp` against a saved copy shows the file byte-identical, and `git status --porcelain -- .superpowers/sdd/.gitignore` prints nothing. (2) Run `sdd-workspace planB.md`, which archives the planA workspace: the file is still byte-identical and is not in `archive/`. (3) Delete the file and run `sdd-workspace`: the file exists again and its content is exactly `*` and a newline. (4) Truncate the file to zero bytes (`: > <file>`) and run `sdd-workspace`: its content is exactly `*` and a newline. |
| `tests/sdd-scripts/run-tests.sh` | new section `review-package (range guard, exit 3)`, placed after the `--commits mode` section (after line 533), in its own fixture repository (same rules as above) | Fixture commits, each held in a variable as its full 40-character SHA: `C0` (adds `a.txt`) and `C1` (adds `b.txt`) on `main`; `SIDE=$(git commit-tree "$C0^{tree}" -p "$C0" -m side)`, a commit beside `main` made without a checkout; `C2` on `main` changes only the blinded file `docs/superpowers-orchestrator/x/x-review-log.md`; then branch `feature` from `C2`; `C3` on `main` (adds `m.txt`); `C4` on `feature` (adds `f.txt`); `M`, the merge of `main` into `feature` with `--no-ff` (a merge commit, not a fast-forward); `C5` on `feature` (adds `g.txt` with the line `g`). Every call passes full SHAs, and every standard-error needle holds exactly those full SHAs, because the script echoes its arguments as given. (1) BASE `C1`, HEAD `C1` (an empty range), with an OUTFILE path: exit 0; the package holds the line `Commits in range: none` directly after the line `## Commits`; standard output ends with `: 0 commit(s), <n> bytes`. (2) BASE `SIDE`, HEAD `C1`: exit 3; standard error is exactly `HEAD is not a descendant of BASE: <SIDE>..<C1>`; no file at a given OUTFILE path, and no `review-*.diff` in the workspace for a call without OUTFILE. (3) BASE `C1`, HEAD `C2` (a task that changes only a blinded file): exit 0, a package is written, the summary says `0 commit(s)`, and the package does not hold `Commits in range: none`. (4) BASE `M`, HEAD `C5` (BASE is a merge commit): exit 0 and the package holds the hunk `+g`. (5) `--commits` unchanged: `--commits <C5>` (HEAD itself) and `--commits <SIDE>` both exit 0. (6) A BASE or HEAD that is not a commit: BASE `<C0>^{tree}`, HEAD `C5` exits 2 and standard error contains `bad BASE: ` (git peels `^{tree}^{commit}` and refuses a tree, so this call checks the commit check: gitrevisions(7), git 2.50.1, `<rev>^{<type>}` dereferences "until an object of type <type> is found or the object cannot be dereferenced anymore (in which case, barf)"; measured on 2026-10-21, git 2.50.1: `git rev-parse --verify --quiet "<C0>^{tree}^{commit}"` exits 1, and without `--quiet` git prints "expected commit type, but the object dereferences to tree type"); `BLOB=$(git rev-parse "$C5:g.txt")`, then BASE `C0`, HEAD `$BLOB` (the blob's object ID) exits 2 and standard error contains `bad HEAD: `; no file is written in either call. The blob is passed by its object ID, not as `<C5>:g.txt`: after `<rev>:` git reads the rest as a path (gitrevisions(7), git 2.50.1: "A suffix : followed by a path names the blob or tree at the given path"), so `<C5>:g.txt^{commit}` looks for a file named `g.txt^{commit}` and fails for that reason, not because of the commit check (measured on 2026-10-21, git 2.50.1: for a scratch commit `<C>` that holds `g.txt`, `git rev-parse "<C>:g.txt^{commit}"` prints `fatal: path 'g.txt^{commit}' does not exist in '<C>'`). (7) An annotated tag as BASE: `git tag -a t0 -m t0 <M>`; BASE `t0`, HEAD `C5`, with an OUTFILE path: exit 0 and the package holds the hunk `+g`. |
| `tests/sdd-scripts/run-tests.sh` | new section `SDD SKILL.md and implementer: rules of v7.74.0` | Pre-Flight Plan Review section (from its heading to the next `## ` heading, folded) contains `The scan's result is a table, not a verdict.`, `` Write the table to `.superpowers/sdd/preflight.md`, under the line `## Pre-flight scan`, once per plan: when that file already exists, run the scan and handle what it finds as before, but do not write the table again ``, `it never decides a conflict`, `` a path that the **Files:** lists of two or more tasks name, or a name that the text of two or more tasks mentions ``, `The row lists every task that mentions that path or name`, `for a path, compare the edits that the listed tasks make at that path`, `` `Row` (`path`, `name` or `task`) ``, `` `Found` is `none` unless the row shows a conflict of a kind that the two items above list `` and `` Every row whose `Found` is not `none` is a conflict ``; it does not contain `` `Row` (`file` ``, `One row for every pair of tasks`, `Rule on everything you find`, `Rule on each conflict`, `record each ruling in the ledger`, `binding authority` or `proceed without comment`. SDD `SKILL.md` folded contains `` When the script exits 3, follow **Exit 3** under **DONE** in Handling Implementer Status instead. ``, `` A task that committed nothing gets a package whose Commits section holds the line `Commits in range: none`; dispatch the task reviewer with it as with any package. ``, `` **Exit 3.** `review-package BASE HEAD` exits 3 when HEAD does not descend from BASE ``, `or a commit at or before BASE was rewritten (an amend or a rebase), and no correct package exists`, `An orchestrated batch controller follows its own prompt for this exit.`, `by the rule of your run mode in the rest of this paragraph only`, `never ask the implementer to switch or reset the branch`, `no numbered remedy of **BLOCKED** applies, also not item 5 (advance to the next independent task)`, `` after the user confirms that the branch is repaired, run the same `review-package BASE HEAD` call again with the same BASE. When it exits 3 again, ask the same question again. ``, `` `Is the branch of task N repaired? (task N: BASE <sha>, implemented, not reviewed)` ``, `Resume Procedure step 3 presents that question to the user and stops.`, `` After the user answers that the branch is repaired, run `review-package <the journaled BASE> HEAD` and the task review; record no new BASE and dispatch no implementer for the task. ``, `When the script exits 3 again, journal the same question again and end; never pick a new BASE yourself.`, `` A task whose entry under `## Open Issues` asks `Is the branch of task N repaired?` (**Exit 3** under **DONE**, Handling Implementer Status) is not marked complete here and is not reviewed here: step 3 handles its entry. `` (this one inside the `### Resume Procedure` section, from its heading to the next `## ` heading) and `For an item about test evidence, read the report file that holds the evidence with the Read tool`; it does not contain `by the rule of your run mode below only` or `Resume Procedure step 2 never marks such a task complete`; it still contains `` - Record BASE: `git rev-parse HEAD` before dispatching. `` and the **DONE_WITH_CONCERNS** paragraph unchanged (`If they're observations (e.g., "this file is getting large"), note them and proceed to review.` is still its last sentence). `implementer-prompt.md` folded contains `A test outside your task that fails, and that your change did not cause (a test that your task writes or changes is your task's own), is not fixed, unless your brief or the controller's dispatch names that test as part of your task.`, `Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one.` and `Commit your work as usual, report DONE_WITH_CONCERNS and name the test as an observation, not as a doubt about your own work: give the test's failing output and the reason why your change did not cause it.`. `skills/test-driven-development/SKILL.md` contains the line `- [ ] Relevant suite passes, apart from failures named under the next item.` and a line that starts with `- [ ] A test outside your task that fails, and that your change did not cause, is not fixed` and ends with `In the main session, your task is the change the user asked for.`, and that line contains `Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one.`; the file no longer contains the line `- [ ] Relevant suite passes.` alone. The existing phrase counts (`:1359-1368`) and the whole-section pin of `## Commit Messages` (`:1339-1340`) run unchanged. |
| `tests/reviewer-templates/run-tests.sh` | new section `26. Worker templates forbid subagent dispatch; controller texts do not` | For each of the two SDD worker templates of section 4.6, the prompt body (`extract_prompt_body`) folded contains `Your only job is the task described below. Do NOT dispatch subagents.` and the whole sentence of SDD `SKILL.md:595` unbroken: `You are a focused subagent. Do NOT invoke any skills from the superpowers-orchestrator plugin. Do NOT use the Skill tool. Your only job is the task described below.`. For each of the two review-loop reviewer templates, the prompt body folded contains `Do NOT use the Skill tool. Do NOT dispatch subagents.`. For each of the eight controller files of section 4.6, the whole file folded does not contain `Do NOT dispatch subagents`. |
| `tests/reviewer-templates/run-tests.sh` | new section `27. Task reviewer: unreadable evidence is a ⚠️ item` | `task-reviewer-prompt.md` folded contains `Evidence you cannot read is not missing evidence.`, `do not run a test to produce the evidence again, also not a focused one` and `and test evidence in the report that you could not read`; `## Tests` still contains `Run a test only when reading the code raises a specific doubt that no existing run answers`; inside `## Tests`, `Evidence you cannot read` stands after `test output should be pristine.`, which is still in the section; `skills/multi-code-review/reviewer-prompt.md` folded does not contain `Evidence you cannot read`; SDD `SKILL.md` folded contains `and test evidence in the implementer's report that the reviewer could not read`. |
| `tests/reviewer-templates/run-tests.sh` | new section `28. multi-code-review: review-package exit 3 is fatal` | The exit-3 bullet stands directly before the fallback bullet: the line above the fallback bullet's first line ends with `to exit 3.`; the exit-3 bullet (from its first line to the next bullet, folded) contains `` - `review-package` exits 3 (HEAD does not descend from BASE: the branch changed under the loop) ``, `fatal: stop the whole invocation and return`, `` `BLOCKED: review range invalid — <the script's error line>` ``, `nothing dispatched`, `The failed round owes no round entry` and `never applies to exit 3`. `reviewer-prompt.md` folded contains `fails with an exit code other than 3`. |
| `tests/orchestrating-development/run-tests.sh` | after the batch-controller assertions at `:520-545`, on `$BATCH_BLOCK` | folded contains `` When `review-package` exits 3, HEAD does not descend from BASE: the branch was switched or reset during the task, or a commit at or before BASE was rewritten (an amend or a rebase). ``, `` write no `### Question <k>` or `### Conflict <k>` section for it, and return `BLOCKED task=<n>: review range invalid — <the script's error line>`. ``, `the orchestrator reads this return as a controller failure, retries the identical dispatch once, and then stops under its Major-Error Stop Policy`, `` 4. Mid-task crash recovery: first, after `sdd-workspace PLAN_FILE` and before the Pre-Flight Plan Review and before any dispatch, check the branch. ``, `` run `git merge-base --is-ancestor <head7> HEAD`, with `<head7>` the HEAD recorded by the last completed ledger line in file order ``, `or the ledger is left from an abandoned or earlier run of this plan`, `` `BLOCKED task=<n>: review range invalid — HEAD does not descend from the last completed ledger HEAD <head7> (branch switched, reset or rewritten, or ledger left from an earlier run of this plan)` ``, `` with `<n>` the first unchecked task of your task list ``, `With no completed ledger line, skip this check.` and `Then, for each assigned task that is unchecked when you start, set REVIEW_BASE`; it still contains `Task <n>: complete commits <base7>..<head7>`. |
| `tests/orchestrating-development/run-tests.sh` | section 12 (`:633`) | `README.md` does not contain `Copilot_CLI-white` (badge); `README.md` contains the line `> **No longer supported (since 2026-10-21).** GitHub Copilot CLI is no` (a fixed-string line match: the note is a quote block, so its later lines start with `> ` and do not fold into one sentence). |

A17 has no automated test (no suite covers systematic-debugging examples,
and a new suite would need its own guard and `CLAUDE.md` entry). The plan's
task runs the two new lines by hand, once with `IDENTITY=s3cret` (expected
output `IDENTITY: SET` and `IDENTITY in environment`, no `s3cret`) and once
with `IDENTITY` unset (expected `IDENTITY: UNSET` and
`IDENTITY not in environment`), and records the output in its report.

### 7.2 Existing pins that must stay green

- `tests/sdd-scripts/run-tests.sh:98` (`self-ignoring gitignore`),
  `:101-103` (workspace invisible to `git status`), `:558-559` (`.gitignore`
  stays at the root on archive and is not moved).
- `tests/sdd-scripts/run-tests.sh:483-507` (range mode), `:509-533`
  (`--commits` mode), `:717-937` (blinding and the `blind_pathspecs` drift
  check: nine entries), `:1216-1272` (helper programs; four `git diff` or
  `git show` reads, each with the options array).
- `tests/sdd-scripts/run-tests.sh:1359-1368` phrase counts, `:1383-1395`
  (wave steps 1-6 and step 3 compared whole), the whole `## Commit Messages`
  section of the implementer template, `:1406-1407` (the fix dispatch rule
  is the last bullet before `## Durable Progress`; Durable Progress does
  not change) and `:1414` (the "Mark task complete" bullet, not changed).
- `tests/reviewer-templates/run-tests.sh:447-453` (`PREFLIGHT_CRITERION`,
  `RUBRIC_PARENTHETICAL`), `:807-819` (paging sentences), `:826-829` (the
  two dispatch steps name their templates), `:929-938` (fallback bullet by
  its first line; `CODE_SKILL_PROSE_MENTIONS=1`; guarded diff reads),
  `:1002` and `:1040` (`CODE_TESTS_SECTION`), `:1012-1013` and `:1037-1038`
  (`CODE_SHARED_IN_PLACE`, `DOC_SHARED_IN_PLACE`), `:53-65` and `:331`
  (`FIX_RULE_CLAUSES`).
- `tests/orchestrating-development/run-tests.sh:633-662` (Copilot and
  OpenCode platform sentences), `:520-545` (batch-controller block).
- `tests/in-run-rulings/run-tests.sh` and `tests/fill-prompt/run-tests.sh`
  (batch-controller text and filling; the batch template still fills with
  exit 0, because the new text has no bracketed uppercase token; the
  in-run-rulings suite finds Deviation 4 by "4. Mid-task crash recovery:"
  and its end by "5. A task with" (`:3060-3061`), and neither changes).
- `tests/review-gates/run-tests.sh:522-531` (the batch controller names
  only Core Flow step 3; the new text names no Core Flow step), `:252-255`
  (the Core Flow step 4 span: no new line starts with `4. ` or `5. `) and
  `:264-300` (the Batched Autonomous Mode span still says
  "never ask for M").
- `tests/codex/test-session-start-snapshot.sh:396-417`
  (systematic-debugging lines under "Check recent changes").

Run every fast suite listed in `CLAUDE.md` before the release.

## 8. Failure modes considered

All are Minor.

1. **C11 false stop on a valid range.** A task whose commits change only
   blinded files, or a BASE that is a merge commit (after `main` was merged
   into the branch), must not be rejected. The guard tests ancestry with
   `git merge-base --is-ancestor`, which accepts a merge commit that HEAD
   descends from, and the empty-range line counts commits without the
   blind pathspecs; tests (3) and (4) of the range-guard section cover
   both cases.
2. **C11 and a task that committed nothing.** Its package is empty and
   says `Commits in range: none`, and the task reviewer decides. This is
   today's behaviour with one more line: a task whose brief asks for
   changed files fails visibly under **Missing**, and uncommitted edits
   that stay on disk make the next clean-tree check of an orchestrated run
   stop (`orchestrating-development/SKILL.md:2905-2906`, `:719-721`). In
   multi-code-review an empty range is refused before round 1
   (`SKILL.md:62-64`); a branch reset to exactly BASE during the loop gives
   an empty package that the round's reviewers read, as today.
3. **C11 exit 3 in SDD.** It means that HEAD does not descend from BASE.
   The task goes to BLOCKED at once, with no implementer re-dispatch. The
   cost is one question (interactive), one ended batch (batched; the
   journaled blocking question keeps the task's BASE, keeps the task out
   of the Resume step 2 shortcut and makes Resume step 3 stop, so the task
   is reviewed after the repair), or, in
   an orchestrated run, one retried batch dispatch and then a stop under
   the Major-Error Stop Policy: the batch controller returns no question
   section, so the orchestrator never rules on a branch state. The start
   check of Deviation 4 makes the retry stop before any dispatch when the
   branch lost a completed task's HEAD. When only commits after that HEAD
   were rewritten, the retry can complete the batch on a valid range
   (section 4.3.2, "Why the start check").
4. **BASE lost after compaction.** A controller that loses its recorded
   BASE after a context compaction and records a later commit reviews a
   smaller range. This is today's behaviour, and this design does not make
   it worse. The only new rules that use BASE are the exit-3 rules, and
   they use the BASE of the call that failed: in interactive mode the
   controller repeats that same call; in Batched Autonomous Mode the
   journaled question under `## Open Issues` holds BASE, because /clear
   loses the controller's context. On a repeated exit 3 the controller
   asks or journals the same question again and never records a new
   BASE.
5. **D6 sentence reaching a controller.** A controller that read "Do NOT
   dispatch subagents." as its own rule could not run its workers. The
   sentence stands only inside the four worker prompt blocks, and the D6
   test fails when any of the eight controller files contains it.
6. **A13 and the user's own `.gitignore`.** The user's committed file wins
   (section 4.1). A file that does not ignore the workspace files shows them
   as untracked in a plain SDD run; a committed ledger reaches whole-branch
   reviewers and makes an orchestrated run stop at the next boundary.
   Accepted: both need a deliberate user action, and the stop is loud. A
   dangling symbolic link named `.gitignore` makes `[ -s ]` false, so
   `printf` writes `*` through the link to its target (test(1), macOS: "If
   file is a symbolic link, test will fully dereference it"; measured on
   2026-10-21 with bash 3.2.57: `[ -s ]` is false for a link to a missing
   file, and `printf '*\n' >` the link creates the target file with `*`);
   this needs a link
   the user created on purpose and is accepted as well. A committed ledger
   is moved into the ignored `archive/` folder when a different plan
   starts, so `git status` shows `progress.md` as deleted (section 4.1);
   accepted for the same reason.
7. **D4 table read as data.** The table is in its own file,
   `.superpowers/sdd/preflight.md`, so no reader of the ledger sees it
   (section 4.5, "Why its own file, not the ledger").
8. **C9 failure that is a regression of the branch.** A test outside the
   task that fails can be a regression that an earlier task caused, or a
   failure that the task caused while the implementer claims it did not.
   The implementer names it as an observation, with the failing output
   and its reason, and does not fix it. Whether it is fixed in this task
   is then decided by today's rules: the controller takes the observation
   branch of **DONE_WITH_CONCERNS** and proceeds to review, the task
   reviewer decides by its rule on test output, and a fix subagent is
   ordered by the review. This design adds no stop and no
   ruling for it (user decision, 2026-10-21). Accepted: the failure is
   never hidden, because it is named in the implementer's status return
   and report file, which the controller and the task reviewer read; a
   controller and a reviewer that both leave it in place is today's
   behaviour, and item 9 describes what follows.
9. **C9 failure left in place, then a fix round.** When the task review
   leaves a C9 failure in place, the failing test stays failing on the
   branch. A fix subagent of the whole-branch review
   (`skills/multi-code-review/fix-prompt.md:52-75`) that changes a file
   this test covers re-runs the covering tests, sees the failure, restores
   every file it changed, reports the failure and stops. When it fails
   twice, the findings become `unresolved: <reason>`, blocking
   (`skills/multi-code-review/SKILL.md:1773-1774`); in an orchestrated run
   that reaches the orchestrator as an open item of Phase 4, which it rules
   on or escalates to a human. Accepted: the failure existed before the fix
   round and was named in the task's report, the stop is loud, no work is
   lost (the fix subagent restores the committed content), and the item
   is resolved by a ruling or by a human, never silently. Changing
   `fix-prompt.md`, which `FIX_RULE_CLAUSES` pins, is out of scope
   (section 2, Non-goals).
10. **A ledger left from an abandoned or earlier run.** `Abandon
    orchestration` deletes the feature branch
    (`skills/orchestrating-development/SKILL.md:1563-1566`) but not the
    git-ignored `.superpowers/sdd/` workspace. When the same plan is
    orchestrated again in the same checkout, `sdd-workspace PLAN_FILE`
    finds the same `plan.ref` and archives nothing, so the old ledger and
    the old `preflight.md` stay. The ledger's completed lines name HEADs
    that the new branch does not hold, so the start check of Deviation 4
    returns `BLOCKED … review range invalid` before any dispatch, and the
    run stops for a human. The old `preflight.md` has a second effect: the
    "once per plan" rule of section 4.5 sees the file and skips the table
    on the restarted run (the scan itself still runs). Accepted: the stop is loud, the return line
    names both causes, the guide (section 4.10, §4) names both repairs
    (repair the branch, or remove or archive `progress.md` together with
    `preflight.md`), and no work is lost. A user who removes only
    `progress.md` gets no new table, which loses the scan record but no
    work. The abandon step does not change.

## 9. Rollout

- One release, v7.74.0. Users reinstall the plugin.
- A repository that already committed a custom `.superpowers/sdd/.gitignore`
  must restore its version once (the old scripts reset it); from then on it
  stays.
- Outside the repository, after the release: the main session updates the
  user's memory file `platforms-actually-used.md`, which still says that
  Claude Code and Copilot CLI are the platforms really used.
