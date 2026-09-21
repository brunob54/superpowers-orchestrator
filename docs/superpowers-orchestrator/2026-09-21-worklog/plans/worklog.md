# Worklog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Add the `worklog` skill, which creates, fully updates and closes a work log at `docs/worklogs/<slug>.md`, with its session-start notice, its `/pickup` exclusion, its routing, its tests, and the v7.52.0 release.
**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-09-21-worklog/specs/worklog-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
**Architecture:** The skill is Markdown that a model executes (`skills/worklog/SKILL.md`) plus a template file that it copies (`skills/worklog/template.md`). The skill holds four fixed shell commands — the slug command, the list command, the check command and the line-1 command — that the model runs with the Bash tool; a fast suite copies each command out of the skill text and runs it on fixture folders. `hooks/session-start` holds a copy of the list command, every line except its print line, and appends one `<active-work-logs>` notice to its always-included notices part; `skills/pickup/scripts/pickup-scan.js` adds `docs/worklogs` to its `NOT_WORK` list.
**Tech Stack:** Markdown skills; bash 3.2 or later (macOS `/bin/bash` is 3.2), POSIX `awk`, `find`, `sort`, `grep`; Node.js 16 or later (hooks, `pickup-scan.js`, JavaScript tests); JSON (`hooks/skill-rules.json`).
**Assumptions:**
- Assumes the Claude Code Skill tool puts the user's argument into `$ARGUMENTS` — will NOT deliver it on Copilot CLI, where the argument may not arrive; the skill then reads the command word and the slug from the user's own message (spec, "Skill file contract").
- Assumes `find`, `awk` and `sort` on `PATH` are the POSIX programs (on Windows, the Git Bash programs) — will NOT list any work log where the Windows `System32` `find` runs first; the hook then continues with no notice (spec, "The status line", accepted).
- Assumes the hook runs in the project directory, as the rest of `hooks/session-start` does — will NOT name the work logs of a repository other than the one that holds the working folder.
- Assumes the fixture file systems may be case-insensitive (the default on macOS) — the fixtures never use two names that differ by letter case alone (`A.md` never sits next to `a.md`), or a fixture would overwrite its own file.
- Assumes the pinned `git log` phrase of the spec's testing list (`--since="<date> 00:00"`) names the full command of the spec's section "Commands", `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD`; the suite pins that full command, followed by the `| cat` of the skill text.
- Assumes the README's example project map (line 225, "27 rules covering 26 skills") tracks the real rule count — the spec lists only the three "30 skills" counts, but the new rule makes this line stale too, so Task 8 changes it to "28 rules covering 27 skills".
- Assumes Claude Code replaces a `$` directly followed by a digit in a skill body with an argument of the invocation (https://code.claude.com/docs/en/skills, "Available string substitutions") — will NOT deliver the spec's list command unchanged, because its awk program holds `l = $0`: `/worklog update` would receive `l = update` and list nothing. The plan therefore deviates from the spec on purpose: every copy of the list command (the skill and the hook) writes `l = $(0)`, which awk reads as the same field, and no line of `skills/worklog/SKILL.md` holds a `$` directly before a digit (Task 2).
- Assumes the plugin's own Bash output hook keeps its rules (`hooks/bash-compress-hook.js`, rule `git-log` of `hooks/compression-rules.js`: the output of a plain `git log` command longer than 40 lines is cut to 30 lines, and a pipeline is never compressed) — will NOT show the model more than 30 commits of the full update's `git log` read unless the skill pipes it through `cat`; Task 3 therefore runs the spec's command followed by `| cat` (a recorded deviation from the spec's command text).
- Assumes `CLAUDE.md` stays git-ignored (`.gitignore` line 7, checked with `git check-ignore -v CLAUDE.md`) — its Testing line is edited on disk only and does not ship with the branch.
**Global Constraints:** (copied from the spec; the spec's section named in brackets)
1. [Definitions] "**Slug**: the short name of a work log. It must match `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase ASCII letters, digits, single hyphens), the same rule as the topic slug of the Artifact Layout, and it has at most 40 characters. [...] The **file name is the authority** for the slug; the `slug=` field of the status line repeats it for a human reader. The words `new`, `update` and `close` are the command words and are not valid slugs."
2. [Location and name] "A work log lives at `docs/worklogs/<slug>.md` under the root. Git tracks the file."
3. [The status line; the quoted sentence: Template] Line 1 of every work log is `<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->`, and after closing `<!-- Work log: status=closed slug=<slug> created=<YYYY-MM-DD> closed=<YYYY-MM-DD> -->`. "No line of a work log other than line 1 may start with `<!-- Work log: status=`."
4. [The status line] "`update` and `close` test the chosen file with this exact command, which the skill text holds" — the check command of the spec, byte for byte. For the list command: "Every copy of the command keeps both" (the folder test and the `|| true`). (Plan note, not a spec quote: the plan's copies of the list command differ from the spec's text in one awk field reference, in the form and for the reason given in **Assumptions**; this is a recorded, deliberate spec deviation.)
5. [Scope and non-goals] "**No new hook, and no injection of a work log's content.**" "**No pointer in `state.md`.** [...] `context-management` and `state.md` are therefore not changed." "**No automatic commit.** The skill never commits." "**No reopen command.** [...] The skill never does this." "**No migration of `docs/orchestration-issues.md`.**" "The word "workstream" is not used for this feature."
6. [Discovery through the session-start hook] "`session-start-assemble.js` is not changed." "The Codex adapters under `hooks/codex/` are not changed (Codex is no longer supported)." "`skills/handoff/SKILL.md` is not changed". [Rollout] "Hook wiring is not changed (no new event, no new script), so `hooks/hooks.json`, `hooks/hooks-cursor.json` and `plugin.universal.yaml` need no hook edit."
7. [Commands] "The frontmatter of `skills/worklog/SKILL.md` does **not** carry `disable-model-invocation: true` [...] It carries `argument-hint: "[new|update|close] [<slug>]"`, and the body holds the line `Argument given by the user (may be empty): $ARGUMENTS`."
8. [The document describes itself; Template] "The template below is the normative text". "The example row in `## Parts`, the example rule, the example limit and the example decision are placeholders. The skill replaces the `## Parts` row with the real parts and removes the three other examples, leaving the headings."
9. [Default admission rule] "When the user gives no rule of their own, the skill writes this one: > A finding becomes an open item only when it blocks a part from reaching the status `done`, or blocks the "done when" condition of the whole work, or when its consequence is lost user work or a wrong commit. Every other finding gets one line under `## Accepted limits`."
10. [Commands] The full update reads the commits with `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD`, "at most five windows in all". (Plan note, not a spec quote: the skill runs this command in a changed form, given with its reason in **Assumptions**; this is a recorded, deliberate spec deviation.)
11. [Discovery through the session-start hook] "Run the list command, unchanged: with its folder test, its `|| true` and its file-name filter. The hook adds no pipeline of its own". (Plan note, not a spec quote: here "the list command" means the skill's copy, with the one difference from the spec's text named in **Assumptions**; the Task 4 Contract says which of its lines the hook holds.) "Build one notice, with at most the first three paths. With one path and the root `/home/u/proj` the exact text is: `<active-work-logs>Active work logs under /home/u/proj: docs/worklogs/a.md. Before you work on one of them, read it with the Read tool and follow its section "How to maintain this document". During an orchestrated run or a whole-branch review, do not write it.</active-work-logs>`". "Paths are joined with `, `; the text ` and <n> more under docs/worklogs/` follows the third path; the full stop follows the last of these." "A root longer than 300 characters is cut to its last 300 characters with `…` before them". "Append the notice, after two line breaks, to the `notices` part that the hook already writes for `hooks/session-start-assemble.js`."
12. [Interfaces and contracts] The `hooks/skill-rules.json` entry is: "`skill`: `worklog`; `type`: `workflow`; `priority`: `high`." "`keywords`: `work log`, `worklog`." "`intentPatterns`: `(create|start|open|new)\\s+(a\\s+|the\\s+)?work\\s?logs?\\b` and `(update|close|continue)\\s+(the\\s+|my\\s+)?work\\s?logs?\\b` (written here as they stand in the JSON file, with doubled backslashes)." "the `worklog` rule is placed before the rules `brainstorming`, `refactoring` and `writing-plans` in the JSON file."
13. [Rollout] "Release v7.52.0 by the release checklist of `CLAUDE.md`. Nothing to migrate." "`docs/FORK-IMPROVEMENTS.md` and `docs/REVIEW-PROCESS-COMPARISON.md` are historical documents and are not updated."

---

## File Structure

| File | Change | Responsibility |
|---|---|---|
| `skills/worklog/template.md` | Create (Task 1) | The normative work log template, a byte copy of the spec's section "Template". |
| `skills/worklog/SKILL.md` | Create (Task 2), extend (Task 3) | The skill: terms and the four shell commands (Task 2); grammar, the three commands, choosing a work log, updates outside the commands, rules (Task 3). |
| `tests/worklog/run-tests.sh` | Create (Task 1), extend (Tasks 2, 3, 4) | New fast suite: template checks, the commands run on fixtures, pinned phrases, the hook's copy of the list command. |
| `hooks/session-start` | Modify (Task 4) | The `<active-work-logs>` notice, appended to the notices part. |
| `tests/codex/test-session-start-worklog-notice.sh` | Create (Task 4) | The hook's notice on fixture projects. |
| `tests/codex/run-unit-tests.sh` | Modify (Task 4) | Registers the new test file. |
| `tests/codex/test-session-start-budget.sh` | Modify (Task 4) | Case 8: three 40-character work logs stay under 10,000 characters. |
| `skills/pickup/scripts/pickup-scan.js` | Modify (Task 5) | `docs/worklogs` joins `NOT_WORK`. |
| `tests/pickup/run-tests.sh` | Modify (Task 5) | Case 6c. |
| `hooks/skill-rules.json` | Modify (Task 6) | The `worklog` rule, before `brainstorming`. |
| `tests/codex/test-skill-activator.js` | Modify (Task 6) | Routing cases for `worklog`. |
| `tests/skill-triggering/prompts/worklog.txt` | Create (Task 7) | The naive prompt (git-ignored by `*.txt`, added with `git add -f`). |
| `tests/skill-triggering/run-all.sh` | Modify (Task 7) | `worklog` in the `SKILLS` array. |
| `skills/using-superpowers/SKILL.md` | Modify (Task 7) | One Routing Guide line, below the injection marker. |
| `docs/guide/README.md`, `README.md` | Modify (Task 8) | User documentation, skill counts and the skill list. |
| `CLAUDE.md` | Modify on disk only (Task 8) | One Testing line; git-ignored, not committed. |
| `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md` | Modify (Task 9) | Release v7.52.0. |

Task order: run the tasks one after the other, in numeric order; do not group them into parallel waves. Some dependencies share no file: Tasks 2, 3 and 4 extend the suite that Task 1 creates, and Task 4 section 8 needs the list command of Task 2; Task 7 Step 2 needs the rule of Task 6, and Task 7 Step 4 needs the skill of Tasks 2 and 3; the README count "28 rules covering 27 skills" of Task 8 is true only after Task 6; Task 9 runs every suite. Only Tasks 5 and 6 need no earlier task.

Repository premises tested before writing this plan (2026-09-21, branch `feature/worklog` at `4a09d7a`):
- `git ls-files --error-unmatch` succeeds for every file that a task modifies, except `CLAUDE.md`: `git check-ignore -v CLAUDE.md` prints `.gitignore:7:CLAUDE.md`.
- `git check-ignore -v tests/skill-triggering/prompts/worklog.txt` prints `.gitignore:18:*.txt` (exit 0); the nine existing prompt files are tracked. `git check-ignore` exits 1 for `skills/worklog/SKILL.md`, `skills/worklog/template.md`, `tests/worklog/run-tests.sh`, `tests/codex/test-session-start-worklog-notice.sh` and `docs/worklogs/x.md`; none of these paths exists yet.
- `command -v zsh node git awk sort` finds all five; `bash -c 'command -v find'` prints `/usr/bin/find`; `command -v claude` finds the CLI (Task 7).
- `hooks/session-start` sets `set -euo pipefail` on line 4, defines `nl=$'\n'` on line 13, uses no variable named `ROOT` or `LIST`, and writes the notices part on line 529.
- `add_file` in `tests/pickup/run-tests.sh` is defined in section 10 (line 435), below section 6b; a case placed after 6b must not call it (the suite guard stops on an undefined command).
- Twelve of the thirteen existing `tests/*/run-tests.sh` files are mode `100755`; `tests/smart-compress/run-tests.sh` is `100644`, and every task runs a suite with `bash <file>`, so the mode does not matter. `tests/review-gates/run-tests.sh` scans `skills/*/*.md` for a bare `<d>` placeholder, a `<reviewers-per-lens>` string and a complete `<superpowers-defaults>` block; the new skill files hold none of them.
- A replay of the planned rule against `matchSkills` (a scratch copy of `hooks/`) suggested `worklog` for both positive prompts, for none of the four negative prompts, and kept `brainstorming` for the mixed prompt; the existing 145 activator tests still passed.

---

### Task 1: The work log template and the new fast suite

**Files:**
- Create: `skills/worklog/template.md`
- Create: `tests/worklog/run-tests.sh`
- Test: `tests/worklog/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the skill text (Tasks 2 and 3). The suite's template checks do not check the wording of the seven rules beyond the phrases named in the contract; byte identity with the spec is checked once, by the Step 4 `diff` against a second extraction that does not use the Step 3 command, not by the suite.

**Contract:**
- `skills/worklog/template.md` (wording artifact)
  - Must convey: the spec's template, byte for byte (Global Constraint 8).
  - Invariants: line 1 is `<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->`; the `## ` headings are, in order, `How to maintain this document`, `Parts`, `Rules for the next parts`, `Open items`, `Accepted limits`, `Decisions`; exactly seven lines match `^[1-7]\. ` between the first two headings; the line `Next item number: 1` exists; only line 1 starts with `<!-- Work log: status=`.
  - Verification: the Step 4 `diff` against the spec's fenced `markdown` block of section "Template" prints nothing; `bash tests/worklog/run-tests.sh` section 1 passes.
- `tests/worklog/run-tests.sh` (code artifact)
  - Inputs: none (paths derived from the script location). Output: exit 0 only when every check passes; exit 1 and a list of failed checks otherwise.
  - Invariants: loads `tests/lib/undefined-command-guard.sh` directly after its `set -u` line, before any `mktemp`, `trap` or `cd` line (the guard file's own rule; `tests/suite-guard` checks every `tests/*/run-tests.sh`); section 1 checks the template invariants above, the four status values, `item #<n>`, `do not write this document`, and the absence of the word `workstream`.
  - Verification: Step 2 shows exit 1 while the template is absent; Step 4 shows exit 0; `bash tests/suite-guard/run-tests.sh` passes.
  - Interface not externally pinned — the helper names are descriptive and may change in a fix.

- [x] **Step 1: Write the failing suite**

Create `tests/worklog/run-tests.sh` with this content, then run `chmod +x tests/worklog/run-tests.sh`:

```bash
#!/usr/bin/env bash
# worklog test suite: skills/worklog/template.md, the shell commands and the
# pinned phrases of skills/worklog/SKILL.md, and the copy of the list command
# in hooks/session-start. Each command is copied out of the skill text and run
# on fixture folders, so a check fails when the text that the model runs
# changes. Pure bash, git, awk and grep; no claude invocation.
# Windows note: avoids /dev/stdin (not available in Git Bash on Windows).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="$REPO/skills/worklog/template.md"
PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()   { green "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_lacks() { # desc file needle
  if grep -qF -- "$3" "$2" 2>/dev/null; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}

bold "1. skills/worklog/template.md"
assert_eq "line 1 is the active status line with placeholders" \
  "$(head -n 1 "$TEMPLATE" 2>/dev/null)" '<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->'
assert_eq "the six ## headings, in order" \
  "$(grep '^## ' "$TEMPLATE" 2>/dev/null | tr '\n' '|')" \
  '## How to maintain this document|## Parts|## Rules for the next parts|## Open items|## Accepted limits|## Decisions|'
RULE_COUNT=$(awk '/^## How to maintain this document$/ { f = 1; next } /^## Parts$/ { f = 0 } f && /^[1-7]\. / { n++ } END { print n + 0 }' "$TEMPLATE" 2>/dev/null)
assert_eq "exactly seven numbered rules in the maintenance section" "$RULE_COUNT" "7"
if grep -qxF 'Next item number: 1' "$TEMPLATE" 2>/dev/null; then ok "the line Next item number: 1"; else bad "the line Next item number: 1 is missing"; fi
for status in 'not started' 'in progress' 'done' 'dropped'; do
  assert_file_contains "the status value $status" "$TEMPLATE" "\`$status\`"
done
assert_file_contains "the form of a former item" "$TEMPLATE" 'item #<n>'
assert_file_contains "the rule for an orchestrated run" "$TEMPLATE" 'do not write this document'
assert_eq "only line 1 starts with the status-line prefix" \
  "$(grep -c '^<!-- Work log: status=' "$TEMPLATE" 2>/dev/null)" "1"
assert_file_lacks "the word workstream is not used" "$TEMPLATE" 'workstream'

bold ""
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
```

- [x] **Step 2: Run the suite to verify it fails**

Run: `bash tests/worklog/run-tests.sh`
Expected: FAIL — exit 1, `Results: 1 passed, 11 failed`; "line 1 is the active status line with placeholders" and every other section 1 check fail, because `skills/worklog/template.md` does not exist. The one pass is "the word workstream is not used": `grep` exits 2 on the absent file, and `assert_file_lacks` counts that as absence.

- [x] **Step 3: Create the template from the spec**

The template is the fenced `markdown` block of the spec's section "Template", copied byte for byte. Create it with this command from the repository root:

```bash
mkdir -p skills/worklog
awk '/^### Template$/ { t = 1 } t && /^````markdown$/ { c = 1; next } c && /^````$/ { exit } c' \
  docs/superpowers-orchestrator/2026-09-21-worklog/specs/worklog-design.md > skills/worklog/template.md
```

- [x] **Step 4: Run the checks to verify they pass**

Run: `S=docs/superpowers-orchestrator/2026-09-21-worklog/specs/worklog-design.md; A=$(grep -n '^````markdown$' "$S" | cut -d: -f1); wc -l < skills/worklog/template.md | tr -d ' ' && diff <(sed -n "$((A + 1)),\$p" "$S" | sed '/^````$/,$d') skills/worklog/template.md && echo TEMPLATE-SAME`
Expected: `94`, then `TEMPLATE-SAME`. The `diff` compares against a second extraction built with `grep` and `sed`, not with the Step 3 `awk` program, so an error in that program shows here. The spec holds one `` ````markdown `` fence; a second one makes the arithmetic fail loudly.

Run: `bash tests/worklog/run-tests.sh`
Expected: PASS — `Results: 12 passed, 0 failed`, exit 0.

Run: `bash tests/suite-guard/run-tests.sh`
Expected: PASS — the new suite loads the guard.

- [x] **Step 5: Commit**

```bash
git add skills/worklog/template.md tests/worklog/run-tests.sh
git commit -m "feat(worklog): add the work log template and its test suite" --trailer "Session: worklog" --trailer "Stage: task 1/9"
```

---

### Task 2: The skill file with its four shell commands

**Files:**
- Create: `skills/worklog/SKILL.md`
- Modify: `tests/worklog/run-tests.sh`
- Test: `tests/worklog/run-tests.sh`

**Security flag:** `security` *(the list command puts file names, which anyone who can add a file controls, into the model's context through the hook; the slug command validates user input before it enters a shell command)*

**Does NOT cover:**
- The list command prints nothing for a `docs/worklogs` folder that is itself a symbolic link (`find` does not follow a start path that is a link); the check command still reads a file through such a link. Accepted limit of the spec ("Failure modes considered").
- The list command tests the prefix of line 1 only; a malformed line 1 with the active prefix is printed, and `update`/`close` then stop on it (Task 3).
- The check command's `slug=` pattern checks the pattern only, not the 40-character limit or the command words: the file name is the authority for the slug.
- The slug command refuses a text with a line break only through the pre-test that the skill text states (every character is `a`-`z`, a digit or a hyphen); the model applies that pre-test before it builds the command.
- Other `awk` versions (`gawk`, Git Bash) and Windows `find` are not run here; the suite covers them where it runs.

**Contract:**
- The slug command, in `skills/worklog/SKILL.md` under `### The slug command` (code artifact)
  - Input: the placeholder `<slug>`, replaced by the model. Output: one line — `valid`, `breaks the pattern ^[a-z0-9]+(-[a-z0-9]+)*$`, `has more than 40 characters`, or `is a command word`.
  - Invariants: the pattern test runs under `LC_ALL=C` (an accented letter never passes); a slug of 40 characters is `valid`, one of 41 is too long; `new`, `update`, `close` are command words.
  - Verification: suite section 2.
  - Interface not externally pinned — the messages are descriptive and may change together with the suite in a fix.
- The list command, under `### The list command` (code artifact)
  - Invariant: the block is the first fenced `bash` block of the spec with one change, `l = $0` written `l = $(0)` (the deliberate spec deviation named in the header's **Assumptions**); no line of it holds a `$` directly before a digit.
  - Behaviour: prints the absolute path of every active work log with a valid file name, sorted under `LC_ALL=C`, then a line end; prints one empty line when there is none; exit 0 under `set -euo pipefail` also with the folder absent.
  - Verification: the Step 4 `diff` prints `BLOCK-1-SAME`; suite section 3.
- The check command, under `### The check command` (code artifact)
  - Invariant: the block is byte-identical to the second fenced `bash` block of the spec (Global Constraint 4).
  - Behaviour: prints `symlink`, `missing (searched <root>/docs/worklogs)`, `active`, `closed`, or `malformed` followed by every status line with its line number; changes no file.
  - Verification: the Step 4 `diff` prints `BLOCK-2-SAME`; suite section 5.
- The valid forms of line 1, the lines `- active: ` and `- closed: ` under `### Valid forms of line 1` (wording artifact)
  - Must convey: the two valid forms of the spec as extended regular expressions, with the slug pattern and the date pattern `[0-9]{4}-[0-9]{2}-[0-9]{2}`.
  - Invariant: each form accepts its example line and refuses a line without `created=`, a closed line without `closed=`, and the date `2026-9-1`.
  - Verification: suite section 4.
- The line-1 command, under `### The line-1 command` (code artifact)
  - Inputs: the placeholders `<slug>` and `<line>`. Output: none; the file's line 1 becomes `<line>`.
  - Invariants: a carriage return at the end of line 1 and a byte order mark at its start are kept; lines 2 and later are byte-identical, except that a missing line break at the end of the file is added (awk `print` always ends a line); the file keeps its permissions (it is rewritten in place with `cat`, not replaced with `mv`); the block holds no `$` directly before a digit, because Claude Code replaces `$0`, `$1` and so on in a skill body with the arguments of the invocation (https://code.claude.com/docs/en/skills, "Available string substitutions").
  - Verification: suite section 6 (the carriage return, the byte order mark, lines 2 and later, the permissions); suite section 2 for the `$`-digit rule. The added final line break is a stated limit and is not checked.
  - Interface not externally pinned.
- The rest of the Task 2 text of `skills/worklog/SKILL.md` (wording artifact): the front matter and the Terms section.
  - Must convey: the name `worklog`; the argument hint `"[new|update|close] [<slug>]"`; no `disable-model-invocation` key (Global Constraint 7); the `$ARGUMENTS` line; the slug rule, the root, "active", "today", `<skill-dir>`; "This skill never commits".
  - Verification: suite section 7 (Task 3) checks the front matter and the `$ARGUMENTS` line; the Terms section is checked by reading it against the spec's section "Definitions", except the root of a project without git: that clause follows the spec's section "Error handling" ("the folder of the shell at the moment of the command", which is what the `|| pwd` of the commands does), not "Definitions" ("the project directory"). Section 7 does not exist yet during Task 2.
- `tests/worklog/run-tests.sh` sections 2 to 6 (code artifact)
  - Invariants: each command is copied out of the skill text by its `### ` heading, never retyped in the suite; section 2 fails when any line of `SKILL.md` holds a `$` directly before a digit; the list command runs as a script under `set -euo pipefail`; when `zsh` is installed, section 3 also runs the list command and section 6b the slug, check and line-1 commands under `zsh`, the shell of the Bash tool on macOS; fixture names never differ by letter case alone; the symbolic-link, unreadable-file, line-break-name and `zsh` checks print a NOTE and are skipped where the platform cannot produce their fixture.
  - Verification: Step 2 fails while `SKILL.md` is absent; Step 4 passes.

- [x] **Step 1: Add the failing sections to the suite**

In `tests/worklog/run-tests.sh`, insert this block directly after the line `TEMPLATE="$REPO/skills/worklog/template.md"`:

```bash
SKILL="$REPO/skills/worklog/SKILL.md"
```

Insert this block directly after the `assert_file_lacks` function (before the line `bold "1. skills/worklog/template.md"`):

```bash
note() { printf '  NOTE: %s\n' "$1"; }
# The output of a fixture run is held in $OUT; these match a whole line with
# grep -x, so a path never matches a longer path.
out_lacks() { # desc exact-line
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then bad "$1 (found line '$2')"; else ok "$1"; fi
}
out_has_line() { # desc exact-line
  if printf '%s\n' "$OUT" | grep -qxF -- "$2"; then ok "$1"; else bad "$1 (no line '$2' in: $(printf '%s' "$OUT" | tr '\n' '|'))"; fi
}

# Isolation: the user's global and system git configuration must not change a
# result, and git must never find a repository above a fixture folder.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
# pwd -P resolves macOS's /var -> /private/var symbolic link, so a fixture
# path equals the path that git rev-parse --show-toplevel prints.
TMP=$(mktemp -d)
: "${TMP:?mktemp failed — refusing to run with an empty fixture path}"
TMP=$(cd "$TMP" && pwd -P)
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
export GIT_CEILING_DIRECTORIES="$TMP"

NL=$'\n'
CREATED='2026-09-21'
CLOSED_ON='2026-09-22'
ACTIVE_FMT='<!-- Work log: status=active slug=%s created=%s -->'
CLOSED_FMT='<!-- Work log: status=closed slug=%s created=%s closed=%s -->'
# Fixture names never differ by letter case alone: the default macOS file
# system does not tell A.md from a.md.
S40=$(printf '%40s' '' | tr ' ' s)
S41=$(printf '%41s' '' | tr ' ' t)

# block_after <heading>: the lines of the first ```bash block after the line
# <heading> in the skill file, without the fence lines.
block_after() {
  awk -v h="$1" '$0 == h { f = 1; next } f && /^```bash$/ { c = 1; next } c && /^```$/ { exit } c { print }' "$SKILL" 2>/dev/null
}
# form_of <name>: the regular expression of one valid form of line 1, from
# the line "- <name>: `<expression>`" of the skill file.
form_of() {
  awk -v p="- $1: " 'index($0, p) == 1 { s = substr($0, length(p) + 1); gsub(/^`|`$/, "", s); print s; exit }' "$SKILL" 2>/dev/null
}
SLUG_CMD=$(block_after '### The slug command')
LIST_CMD=$(block_after '### The list command')
CHECK_CMD=$(block_after '### The check command')
LINE1_CMD=$(block_after '### The line-1 command')
ACTIVE_RE=$(form_of active)
CLOSED_RE=$(form_of closed)
# The list command runs as a script under set -euo pipefail, the options that
# hooks/session-start sets on its line 4.
printf 'set -euo pipefail\n%s\n' "$LIST_CMD" > "$TMP/list.sh"

# The replacement texts below hold no "&" and no backslash, so bash 5.2's
# patsub_replacement option cannot change them.
# RUN_SHELL runs the slug, check and line-1 commands; section 6b sets it to
# zsh, the shell that the Bash tool runs on macOS.
RUN_SHELL=bash
# run_slug <slug>: runs the slug command; sets OUT.
run_slug() {
  printf '%s\n' "${SLUG_CMD//<slug>/$1}" > "$TMP/slug.sh"
  OUT=$("$RUN_SHELL" "$TMP/slug.sh" 2>&1)
}
# run_list <folder> [shell]: runs the list command from <folder>; sets OUT to
# its output followed by "exit=<status>".
run_list() {
  OUT=$(cd "$1" && "${2:-bash}" "$TMP/list.sh" 2>&1; printf 'exit=%s' "$?")
}
# lines <path>...: the output that run_list expects for these paths.
lines() { printf '%s\n' "$@"; printf 'exit=0'; }
# run_check <folder> <slug>: runs the check command from <folder>; sets OUT.
run_check() {
  printf '%s\n' "${CHECK_CMD//<slug>/$2}" > "$TMP/check.sh"
  OUT=$(cd "$1" && "$RUN_SHELL" "$TMP/check.sh" 2>&1)
}
# run_line1 <folder> <slug> <new line 1>: runs the line-1 command; sets OUT.
run_line1() {
  local cmd="${LINE1_CMD//<slug>/$2}"
  printf '%s\n' "${cmd//<line>/$3}" > "$TMP/line1.sh"
  OUT=$(cd "$1" && "$RUN_SHELL" "$TMP/line1.sh" 2>&1)
}
# repo <name>: a git repository with an empty docs/worklogs folder; sets D
# (the repository) and W (its docs/worklogs folder).
repo() { D="$TMP/$1"; W="$D/docs/worklogs"; mkdir -p "$W"; git -C "$D" init -q; }
# active_log <file> <slug> and closed_log <file> <slug>: a work log with that
# status line on line 1.
active_log() { { printf "$ACTIVE_FMT\n" "$2" "$CREATED"; printf '\n# Work log: fixture\n'; } > "$1"; }
closed_log() { { printf "$CLOSED_FMT\n" "$2" "$CREATED" "$CLOSED_ON"; printf '\n# Work log: fixture\n'; } > "$1"; }
```

Insert this block directly before the footer line `bold ""`:

```bash
bold "2. The slug command"
for name in SLUG_CMD LIST_CMD CHECK_CMD LINE1_CMD ACTIVE_RE CLOSED_RE; do
  if [ -n "${!name}" ]; then ok "the skill text holds $name"; else bad "the skill text holds $name"; fi
done
# Claude Code replaces $0, $1 and so on in a skill body with the arguments of
# the invocation, so a command holding such a token reaches the model changed.
assert_eq "no line of the skill holds a \$ directly before a digit" "$(grep -nE '\$[0-9]' "$SKILL" 2>/dev/null)" ''
PATTERN_MSG='breaks the pattern ^[a-z0-9]+(-[a-z0-9]+)*$'
for s in test-refactor "$S40" 7; do
  run_slug "$s"; assert_eq "slug '$s' is valid" "$OUT" 'valid'
done
for s in A a--b -a a- 'café' 'x y'; do
  run_slug "$s"; assert_eq "slug '$s' breaks the pattern" "$OUT" "$PATTERN_MSG"
done
run_slug "$S41"; assert_eq "a slug of 41 characters is too long" "$OUT" 'has more than 40 characters'
for s in new update close; do
  run_slug "$s"; assert_eq "'$s' is a command word" "$OUT" 'is a command word'
done

bold "3. The list command"
repo mixed
MD="$D"; MW="$W"
active_log "$W/alpha.md" alpha
closed_log "$W/closed.md" closed
{ printf "$CLOSED_FMT\n\n" quoted "$CREATED" "$CLOSED_ON"; printf "$ACTIVE_FMT\n" quoted "$CREATED"; } > "$W/quoted.md"
printf '<!-- Work log: status=open slug=c created=2026-09-21 -->\n' > "$W/open-status.md"
{ printf '# Work log: heading first\n\n'; printf "$ACTIVE_FMT\n" line-three "$CREATED"; } > "$W/line-three.md"
for name in Upper 'x y' new 'café' "$S41"; do active_log "$W/$name.md" "$name"; done
active_log "$W/$S40.md" "$S40"
{ printf '\357\273\277'; printf "$ACTIVE_FMT\n" bom "$CREATED"; } > "$W/bom.md"
printf "$ACTIVE_FMT\r\n\r\n# Work log: fixture\r\n" crlf "$CREATED" > "$W/crlf.md"
if ! active_log "$W/$(printf 'n\nl').md" nl 2>/dev/null; then
  note "this file system refuses a line break in a file name; that case is skipped"
fi
HAVE_LINKS=0
ln -s alpha.md "$W/link.md" 2>/dev/null
if [ -L "$W/link.md" ]; then
  HAVE_LINKS=1
else
  rm -f "$W/link.md"
  note "ln -s made no symbolic link here; the symbolic-link checks are skipped"
fi
run_list "$MD"
MIXED_EXPECTED=$(lines "$MW/alpha.md" "$MW/bom.md" "$MW/crlf.md" "$MW/$S40.md")
assert_eq "only valid active work logs are listed, sorted; a byte order mark and a CRLF line end are accepted" "$OUT" "$MIXED_EXPECTED"
for name in closed quoted open-status line-three Upper 'x y' new 'café' "$S41"; do
  out_lacks "$name.md is not listed" "$MW/$name.md"
done
if [ "$HAVE_LINKS" = 1 ]; then out_lacks "a symbolic link is not listed" "$MW/link.md"; fi
mkdir -p "$MD/src/deep"
run_list "$MD/src/deep"
assert_eq "the same output from a sub-folder" "$OUT" "$MIXED_EXPECTED"
if command -v zsh >/dev/null 2>&1; then
  run_list "$MD/src/deep" zsh
  assert_eq "the same output when zsh runs it" "$OUT" "$MIXED_EXPECTED"
else
  note "zsh is not installed; the zsh check is skipped"
fi
repo sorted
for name in ab a a-b; do active_log "$W/$name.md" "$name"; done
run_list "$D"
assert_eq "several work logs in C-locale order" "$OUT" "$(lines "$W/a-b.md" "$W/a.md" "$W/ab.md")"
repo unreadable
for name in a b c; do active_log "$W/$name.md" "$name"; done
chmod 000 "$W/b.md"
if [ -r "$W/b.md" ]; then
  note "b.md stays readable (root user?); the unreadable-file check is skipped"
else
  run_list "$D"
  assert_eq "an unreadable file hides no other work log" "$OUT" "$(lines "$W/a.md" "$W/c.md")"
fi
chmod 644 "$W/b.md"
D="$TMP/nofolder"; mkdir -p "$D"; git -C "$D" init -q
run_list "$D"
assert_eq "no docs/worklogs folder: one empty line and exit 0 under set -euo pipefail" "$OUT" "$(lines '')"
repo onlybad
active_log "$W/A.md" a
run_list "$D"
assert_eq "a folder with only A.md: one empty line and exit 0" "$OUT" "$(lines '')"

bold "4. The valid forms of line 1"
# form_matches <regex> <line>: exit 0 when <line> matches <regex>.
form_matches() { printf '%s\n' "$2" | grep -Eq -- "$1"; }
if form_matches "$ACTIVE_RE" "$(printf "$ACTIVE_FMT" test-refactor "$CREATED")"; then
  ok "the active form accepts its example line"; else bad "the active form accepts its example line"; fi
if form_matches "$CLOSED_RE" "$(printf "$CLOSED_FMT" test-refactor "$CREATED" "$CLOSED_ON")"; then
  ok "the closed form accepts its example line"; else bad "the closed form accepts its example line"; fi
for line in '<!-- Work log: status=active slug=test-refactor -->' \
            "<!-- Work log: status=closed slug=test-refactor created=$CREATED -->" \
            '<!-- Work log: status=active slug=test-refactor created=2026-9-1 -->'; do
  for form in active closed; do
    re=$(form_of "$form")
    if form_matches "$re" "$line"; then bad "the $form form refuses '$line'"; else ok "the $form form refuses '$line'"; fi
  done
done
if form_matches "$ACTIVE_RE" "$(head -n 1 "$MW/crlf.md" | tr -d '\r')"; then
  ok "a CRLF line 1 matches the active form once the carriage return is removed"
else
  bad "a CRLF line 1 matches the active form once the carriage return is removed"
fi

bold "5. The check command"
run_check "$MD" alpha;  assert_eq "an active work log prints active" "$OUT" 'active'
run_check "$MD" closed; assert_eq "a closed work log prints closed" "$OUT" 'closed'
run_check "$MD" crlf;   assert_eq "a line 1 with a carriage return prints active" "$OUT" 'active'
run_check "$MD" bom;    assert_eq "a line 1 with a byte order mark prints active" "$OUT" 'active'
run_check "$MD" open-status
assert_eq "an unknown status prints malformed first" "${OUT%%"$NL"*}" 'malformed'
run_check "$MD" line-three
assert_eq "a status line on line 3 prints malformed first" "${OUT%%"$NL"*}" 'malformed'
out_has_line "the status line on line 3 is printed with its line number" "3:$(printf "$ACTIVE_FMT" line-three "$CREATED")"
run_check "$MD" absent
assert_eq "a missing file prints missing and the folder it searched" "$OUT" "missing (searched $MW)"
if [ "$HAVE_LINKS" = 1 ]; then
  run_check "$MD" link; assert_eq "a symbolic link prints symlink" "$OUT" 'symlink'
fi
run_check "$MD/src/deep" alpha
assert_eq "the same word from a sub-folder" "$OUT" 'active'
BEFORE_SUM=$(cksum < "$MW/crlf.md")
run_check "$MD" crlf
assert_eq "the check command changes no file" "$(cksum < "$MW/crlf.md")" "$BEFORE_SUM"

bold "6. The line-1 command"
repo line1
printf "$ACTIVE_FMT\r\n\r\n# Work log: fixture\r\nrow\r\n" crlf "$CREATED" > "$W/crlf.md"
{ printf '\357\273\277'; printf "$ACTIVE_FMT\n\n# Work log: fixture\n" bom "$CREATED"; } > "$W/bom.md"
printf "$ACTIVE_FMT\n\n# Work log: fixture\n" wrong-slug "$CREATED" > "$W/plain.md"
# The command rewrites the file in place, so its mode must not change.
chmod 640 "$W/plain.md"
MODE_BEFORE=$(ls -l "$W/plain.md" | cut -c1-10)
for name in crlf bom plain; do
  REST_SUM=$(tail -n +2 "$W/$name.md" | cksum)
  NEW_LINE=$(printf "$CLOSED_FMT" "$name" "$CREATED" "$CLOSED_ON")
  run_line1 "$D" "$name" "$NEW_LINE"
  assert_eq "$name: the command exits quietly" "$OUT" ''
  assert_eq "$name: lines 2 and later are unchanged" "$(tail -n +2 "$W/$name.md" | cksum)" "$REST_SUM"
  run_check "$D" "$name"
  assert_eq "$name: the check command then prints closed" "$OUT" 'closed'
done
assert_eq "crlf: line 1 is the new line" "$(head -n 1 "$W/crlf.md" | tr -d '\r')" "$(printf "$CLOSED_FMT" crlf "$CREATED" "$CLOSED_ON")"
assert_eq "crlf: line 1 still ends with a carriage return" "$(head -n 1 "$W/crlf.md" | tail -c 2 | od -An -tx1 | tr -d ' \n')" '0d0a'
assert_eq "bom: the byte order mark is kept" "$(head -c 3 "$W/bom.md" | od -An -tx1 | tr -d ' \n')" 'efbbbf'
assert_eq "plain: line 1 is the new line, with no carriage return" "$(head -n 1 "$W/plain.md")" "$(printf "$CLOSED_FMT" plain "$CREATED" "$CLOSED_ON")"
assert_eq "plain: the file keeps its permissions" "$(ls -l "$W/plain.md" | cut -c1-10)" "$MODE_BEFORE"

bold "6b. The slug, check and line-1 commands under zsh"
if command -v zsh >/dev/null 2>&1; then
  RUN_SHELL=zsh
  run_slug test-refactor; assert_eq "zsh: slug 'test-refactor' is valid" "$OUT" 'valid'
  run_slug 'café'; assert_eq "zsh: slug 'café' breaks the pattern" "$OUT" "$PATTERN_MSG"
  run_slug "$S41"; assert_eq "zsh: a slug of 41 characters is too long" "$OUT" 'has more than 40 characters'
  run_check "$MD" crlf; assert_eq "zsh: a line 1 with a carriage return prints active" "$OUT" 'active'
  run_check "$MD" bom; assert_eq "zsh: a line 1 with a byte order mark prints active" "$OUT" 'active'
  run_check "$MD" absent; assert_eq "zsh: a missing file prints missing and the folder it searched" "$OUT" "missing (searched $MW)"
  printf "$ACTIVE_FMT\r\n\r\n# Work log: fixture\r\n" zsh-crlf "$CREATED" > "$W/zsh-crlf.md"
  run_line1 "$D" zsh-crlf "$(printf "$CLOSED_FMT" zsh-crlf "$CREATED" "$CLOSED_ON")"
  run_check "$D" zsh-crlf; assert_eq "zsh: the line-1 command closes a work log with CRLF line ends" "$OUT" 'closed'
  RUN_SHELL=bash
else
  note "zsh is not installed; the zsh checks of section 6b are skipped"
fi

```

- [x] **Step 2: Run the suite to verify it fails**

Run: `bash tests/worklog/run-tests.sh`
Expected: FAIL — exit 1; "the skill text holds SLUG_CMD" (and the five other "the skill text holds" checks) fail, because `skills/worklog/SKILL.md` does not exist. Section 1 still passes.

- [x] **Step 3: Create the skill file**

Create `skills/worklog/SKILL.md` with this content. The block under `### The check command` is the spec's second fenced `bash` block byte for byte. The block under `### The list command` is the spec's first fenced `bash` block with one change, `l = $0` written `l = $(0)` (the deliberate spec deviation named in the header's **Assumptions**). If a character differs, copy the blocks from the spec again and apply that one change.

````markdown
---
name: worklog
description: >
  Creates and maintains a work log: one Markdown document per piece of
  multi-part work that lasts many sessions, at docs/worklogs/<slug>.md, with
  its own update rules. /worklog new [<slug>] creates one; /worklog or
  /worklog update [<slug>] runs a full update; /worklog close [<slug>] closes
  one. Triggers on: "work log", "worklog", "create a work log", "start a work
  log", "update the work log", "close the work log", "continue the work log".
argument-hint: "[new|update|close] [<slug>]"
---

# Work log

A work log is one Markdown document per piece of work that has several parts
and lasts many sessions, for example four groups of tests that are refactored
one group after the other. It lives at `docs/worklogs/<slug>.md` under the
root, and git tracks it. It carries its own update rules in its section
`How to maintain this document`, so a session can maintain it without this
skill. This skill creates a work log, runs a full update, and closes it. This
skill never commits: the work log goes into the next commit that the user
requests.

Argument given by the user (may be empty): $ARGUMENTS

## Terms

- **Slug rule**: a slug matches `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase ASCII
  letters, digits, single hyphens), has at most 40 characters, and is none of
  the three command words `new`, `update` and `close`. The file name is the
  authority for the slug; the `slug=` field of line 1 repeats it for a human
  reader.
- **Root**: the output of `git rev-parse --show-toplevel`; in a project that is
  not a git repository, the folder of the shell at the moment of the command.
  Every `docs/worklogs/` path in this skill is relative to the root.
- **Active**: a work log whose line 1 starts with
  `<!-- Work log: status=active `.
- **Today**: the output of `date +%F`, run with the Bash tool.
- **`<skill-dir>`**: this skill's base directory. A path under `skills/`
  exists only inside the plugin's own repository, never in a user's project.

## Shell commands

Run these commands with the Bash tool. Replace only the placeholders that a
command names, and copy everything else unchanged. Never put a slug into a
command before it passes this first test: every character is a lowercase
letter `a` to `z`, a digit or a hyphen. A slug with any other character
breaks the pattern: stop, say so, and write nothing.

### The slug command

Placeholder: `<slug>`. It prints `valid`, or the rule that the slug breaks.

```bash
s='<slug>'
if ! printf '%s\n' "$s" | LC_ALL=C grep -Eqx '[a-z0-9]+(-[a-z0-9]+)*'; then echo 'breaks the pattern ^[a-z0-9]+(-[a-z0-9]+)*$'
elif [ "${#s}" -gt 40 ]; then echo 'has more than 40 characters'
else case "$s" in new|update|close) echo 'is a command word';; *) echo valid;; esac; fi
```

### The list command

It prints the path of every active work log, one per line, in the same order
in every locale, or one empty line when there is none. It reads line 1 only,
and it prints a file only when its name is a valid slug plus `.md`. The
folder test and the `|| true` keep it safe under `set -euo pipefail`; every
copy of this command keeps both. The awk program writes the whole line as
`$(0)`: Claude Code replaces a `$` directly followed by a digit in this file
with an argument of the command, so no line of this file holds one.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIST=""
if [ -d "$ROOT/docs/worklogs" ]; then
  LIST="$(LC_ALL=C find "$ROOT/docs/worklogs" -maxdepth 1 -type f -name '*.md' -exec awk '
    FNR==1 { l = $(0); sub(/^\357\273\277/, "", l)
      if (l ~ /^<!-- Work log: status=active /) {
        n = FILENAME; sub(/.*\//, "", n)
        if (n ~ /^[a-z0-9]+(-[a-z0-9]+)*\.md$/ && length(n) <= 43 &&
            n != "new.md" && n != "update.md" && n != "close.md") print FILENAME
      }
      exit }' {} \; 2>/dev/null | LC_ALL=C sort || true)"
fi
printf '%s\n' "$LIST"
```

### The check command

Placeholder: `<slug>`. It prints one word: `symlink`, `missing` (followed by
the folder that it searched), `active`, `closed` or `malformed`. After
`malformed` it prints each status line of the file with its line number. It
removes a carriage return and a byte order mark for the comparison only, and
it never changes the file. Never judge line 1 by reading it: the Read tool
shows neither a carriage return nor a symbolic link.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
F="$ROOT/docs/worklogs/<slug>.md"
S='[a-z0-9]+(-[a-z0-9]+)*'; D='[0-9]{4}-[0-9]{2}-[0-9]{2}'
if [ -L "$F" ]; then echo symlink
elif [ ! -f "$F" ]; then echo "missing (searched $ROOT/docs/worklogs)"
else
  L="$(head -n 1 "$F" | tr -d '\r')"; BOM="$(printf '\357\273\277')"; L="${L#"$BOM"}"
  if printf '%s\n' "$L" | grep -Eq "^<!-- Work log: status=active slug=$S created=$D -->$"; then echo active
  elif printf '%s\n' "$L" | grep -Eq "^<!-- Work log: status=closed slug=$S created=$D closed=$D -->$"; then echo closed
  else echo malformed; grep -n '<!-- Work log: status=' "$F" || true; fi
fi
```

### Valid forms of line 1

- active: `^<!-- Work log: status=active slug=[a-z0-9]+(-[a-z0-9]+)* created=[0-9]{4}-[0-9]{2}-[0-9]{2} -->$`
- closed: `^<!-- Work log: status=closed slug=[a-z0-9]+(-[a-z0-9]+)* created=[0-9]{4}-[0-9]{2}-[0-9]{2} closed=[0-9]{4}-[0-9]{2}-[0-9]{2} -->$`

A line 1 that matches neither form is malformed. A valid line whose `slug=`
value differs from the file name is not malformed: it is a mismatch, the only
case that this skill corrects. No line other than line 1 may start with
`<!-- Work log: status=`.

### The line-1 command

Placeholders: `<slug>`, and `<line>`, the new line 1 in one of the two valid
forms. It replaces line 1 only. It keeps a carriage return at the end of line
1 and a byte order mark at its start, and every other line stays as it was.
Change line 1 only with this command, then run the check command again.

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
F="$ROOT/docs/worklogs/<slug>.md"
LC_ALL=C awk -v new='<line>' 'NR == 1 { cr = /\r$/; bom = /^\357\273\277/; l = (bom ? "\357\273\277" : "") new (cr ? "\r" : ""); print l; next } { print }' "$F" > "$F.tmp" && cat "$F.tmp" > "$F" && rm -f "$F.tmp"
```
````

- [x] **Step 4: Run the checks to verify they pass**

Run: `S=docs/superpowers-orchestrator/2026-09-21-worklog/specs/worklog-design.md; for n in 1 2; do h=$([ "$n" = 1 ] && echo '### The list command' || echo '### The check command'); diff <(awk -v n="$n" '/^```bash$/ { k++; c = 1; next } c && /^```$/ { c = 0 } c && k == n' "$S" | sed 's/l = \$0;/l = $(0);/') <(awk -v h="$h" '$0 == h { f = 1; next } f && /^```bash$/ { c = 1; next } c && /^```$/ { exit } c' skills/worklog/SKILL.md) && echo "BLOCK-$n-SAME"; done`
Expected: `BLOCK-1-SAME` (the list command, compared after the one change `l = $0` → `l = $(0)` is applied to the spec's text; the `sed` changes nothing in the check command) and `BLOCK-2-SAME` (the check command), with no diff lines.

Run: `bash tests/worklog/run-tests.sh`
Expected: PASS — exit 0, 0 failed. NOTE lines may appear only on a platform that cannot make a symbolic link, an unreadable file, a file name with a line break, or has no `zsh`.

Run: `bash tests/review-gates/run-tests.sh`
Expected: PASS — the new skill files carry no bare `<d>`, no `<reviewers-per-lens>` and no complete defaults block.

- [x] **Step 5: Commit**

```bash
git add skills/worklog/SKILL.md tests/worklog/run-tests.sh
git commit -m "feat(worklog): add the skill file with its slug, list, check and line-1 commands" --trailer "Session: worklog" --trailer "Stage: task 2/9"
```

---

### Task 3: The skill's commands and rules

**Files:**
- Modify: `skills/worklog/SKILL.md`
- Modify: `tests/worklog/run-tests.sh`
- Test: `tests/worklog/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:**
- No fast test runs the three commands themselves: they are Markdown that a model executes. Their rules are held by the pinned phrases below and by `tests/skill-triggering` (Task 7); this is the spec's accepted limit ("Testing strategy").
- The fallback to `update` applies only to a user message that starts with `/worklog` or `/superpowers-orchestrator:worklog`; a message that only mentions the command runs nothing. Whether the model sees the namespaced form as typed was not probed (spec, unverified).
- The repair of a missing heading or `Next item number` line runs in `update` only; `close` does not repair.
- A closed work log is never written, not even to correct a `slug=` mismatch; it is never reopened by the skill.
- In a project without git, the `git log` read and the `git check-ignore` test are skipped and the `Commit` column stays empty.

**Contract:**
- The Task 3 text of `skills/worklog/SKILL.md`: the section `## Commands and arguments` (inserted between `## Terms` and `## Shell commands`) and the sections `## Choosing a work log`, `/worklog new`, `/worklog update`, `/worklog close`, `## Updates outside the commands` and `## Rules` (appended after `### The line-1 command`) (wording artifact)
  - Must convey every rule of the spec's sections "Commands", "Updates outside the commands" and "Error handling": the grammar and the usage text; the first word is always a command word; the `$ARGUMENTS` fallback and the load-by-the-model test; slug validation first; the shared choosing rule and the five ordered checks (`symlink`, `missing`, `malformed`, `closed`, `active`), each stop writing nothing; the listing and its four labels; `new` in its steps (no overwrite, one question batch with the default admission rule offered first and written when the user gives no rule of their own, confirmation of the target path outside git or below the root, the template read with the Read tool and filled, `git check-ignore -q` with exit 0 meaning ignored, the report); the full update (read, repairs in `update` only, the `git log` window from the creation date with `00:00`, piped through `cat` so that the plugin's Bash output hook does not cut it, at most five windows of 200, the document's own rules); `close` (close anyway or stop, former items as `- <today> item #<n>: <item text> — open at closing`, the `## Decisions` entry, last `Commit` cells, line 1 changed with the line-1 command); the "Updates outside the commands" step; the skill never commits and never reopens.
  - Invariants: each pinned phrase of suite section 7 stands on one line of the file, so `grep -F` finds it; the line that names `<skill-dir>/template.md` also says `with the Read tool`; the front matter has no `disable-model-invocation`; the word `workstream` does not occur; no line holds a `$` directly before a digit (suite section 2).
  - Verification: `bash tests/worklog/run-tests.sh` section 7 for the pinned phrases and section 2 for the `$`-digit rule; every other "Must convey" item by reading the text against the spec's sections "Commands", "Updates outside the commands" and "Error handling".
  - Sentence wording is free; the properties above bind.
- `tests/worklog/run-tests.sh` section 7 (code artifact)
  - Output: one PASS or FAIL per pinned phrase and per front-matter property.
  - Invariant: it pins at least every skill-text item that the spec's section "Testing strategy" lists — the sentence that starts ``The fallback to `update` applies only when the user's own message starts with the command``, `A closed work log is never written`, `stops with the usage text`, `close anyway`, `invalid file name — rename it`, `with the Read tool` in the step that names `<skill-dir>/template.md`, the `$ARGUMENTS` line, no `disable-model-invocation` in the front matter, `Never overwrite a work log`, `never commits`, the grammar line and the `git log` command with `--since="<created> 00:00"`, pinned together with its `| cat` — plus the sentence of `## Updates outside the commands` and the default admission rule. A fix may add phrases, never remove one of these.
  - Verification: Step 2 fails before the text exists; Step 4 passes.

- [x] **Step 1: Add the failing section to the suite**

Insert this block in `tests/worklog/run-tests.sh` directly before the footer line `bold ""`:

```bash
bold "7. Pinned phrases of skills/worklog/SKILL.md"
FRONT=$(awk 'NR == 1 && $0 == "---" { f = 1; next } f && $0 == "---" { exit } f { print }' "$SKILL" 2>/dev/null)
case "$FRONT" in *'name: worklog'*) ok "the front matter names the skill worklog" ;; *) bad "the front matter names the skill worklog" ;; esac
case "$FRONT" in *'argument-hint: "[new|update|close] [<slug>]"'*) ok "the front matter carries the argument hint" ;; *) bad "the front matter carries the argument hint" ;; esac
case "$FRONT" in *disable-model-invocation*) bad "the front matter carries disable-model-invocation" ;; *) ok "the front matter does not carry disable-model-invocation" ;; esac
PHRASES=(
  'Argument given by the user (may be empty): $ARGUMENTS'
  '/worklog [new|update|close] [<slug>]'
  "The fallback to \`update\` applies only when the user's own message starts with the command"
  'stops with the usage text'
  'A closed work log is never written'
  'close anyway'
  'invalid file name — rename it'
  'malformed line 1'
  'Never overwrite a work log'
  'never commits'
  "git log -n 200 --since=\"<created> 00:00\" --format='%h %cd %s' --date=short HEAD | cat"
  'When the session-start notice or the user names an active work log, read that work log with the Read tool before starting the work, and follow its section `How to maintain this document`.'
  '> A finding becomes an open item only when it blocks a part from reaching the status `done`, or blocks the "done when" condition of the whole work, or when its consequence is lost user work or a wrong commit. Every other finding gets one line under `## Accepted limits`.'
)
for phrase in "${PHRASES[@]}"; do
  assert_file_contains "the skill text holds: $phrase" "$SKILL" "$phrase"
done
TEMPLATE_STEP=$(grep -F '<skill-dir>/template.md' "$SKILL" 2>/dev/null)
case "$TEMPLATE_STEP" in
  *'with the Read tool'*) ok "the step that names <skill-dir>/template.md reads it with the Read tool" ;;
  *) bad "the step that names <skill-dir>/template.md reads it with the Read tool" ;;
esac
assert_file_lacks "the word workstream is not used" "$SKILL" 'workstream'

```

- [x] **Step 2: Run the suite to verify it fails**

Run: `bash tests/worklog/run-tests.sh`
Expected: FAIL — exit 1; section 7 reports missing phrases such as `stops with the usage text`, `close anyway`, `invalid file name — rename it`, the `git log` command and the admission rule, and the `<skill-dir>/template.md` check fails. The front-matter checks, the `$ARGUMENTS` line and `never commits` already pass.

- [x] **Step 3: Add the text to the skill**

Insert this section in `skills/worklog/SKILL.md` directly before the line `## Shell commands`, with one empty line after it:

````markdown
## Commands and arguments

Grammar: `/worklog [new|update|close] [<slug>]`

The first word is always read as a command word, never as a slug. When the
user types `/worklog` with no first word, the command is `update`; the test
at the end of this section decides whether the user typed the command. Any
other first word, and a command word
given as a slug (for example `/worklog new close`), stops with the usage text and writes nothing. The usage text is the grammar line and one line per command:

```text
/worklog [new|update|close] [<slug>]
/worklog new [<slug>]       create a work log
/worklog update [<slug>]    full update; /worklog alone does the same
/worklog close [<slug>]     close a work log
```

Every command that gets a slug first tests it by "The slug command" below. A
result other than `valid` stops the command: say which rule the slug breaks,
and write nothing. A command word given as a slug in the argument has already
stopped with the usage text, before this test.

When the argument above is empty and the user's own message starts with the
command, read the command word and the slug from that message (on Copilot CLI,
the command-line interface of GitHub Copilot, the argument may not arrive);
only then fall back to `update`.
The fallback to `update` applies only when the user's own message starts with the command, written `/worklog` or `/superpowers-orchestrator:worklog`.
A message that only mentions the command (for example "what does /worklog
close do?") does not start with it and is not an invocation. When this test
fails, the model loaded this skill by itself:

- If the user asked for no command, run no command and no full update, and say
  so in one line. Read the named work log with the Read tool and follow its
  section `How to maintain this document`.
- If the user asked for a command in plain words ("close the work log"), run
  that command.
````

Append these sections at the end of `skills/worklog/SKILL.md`, after the line-1 command block, with one empty line before them:

````markdown
## Choosing a work log

`update` and `close` share this rule.

- With a slug: the file `docs/worklogs/<slug>.md` must exist. When the check
  command prints `missing`, stop, show the listing, and write nothing.
- With no slug: run the list command. With one path, use that work log. With
  several, ask the user which one. With none, say that no work log is active,
  offer `/worklog new`, and write nothing.

Then run the check command on the chosen file and act on its word, in this
order. Each stop writes nothing.

1. `symlink`: stop; say that a work log must be a regular file.
2. `missing`: stop; show the listing.
3. `malformed`: stop; show the two valid forms of line 1. When the command
   printed a status line with a line number other than 1, say that its
   position is wrong and that it belongs on line 1.
4. `closed`: stop; say that the work log is closed. A closed work log is never written: a `slug=` mismatch in it is reported only.
5. `active`: when the `slug=` field differs from the file name, report the
   mismatch and correct the field with the line-1 command. Then the command
   continues.

**The listing** has one line per regular `*.md` file directly under
`docs/worklogs/`. Find the files with
`find "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/docs/worklogs" -maxdepth 1 -type f -name '*.md'`.
The slug of a file is its name without `.md`. Test it with the first test of
"Shell commands", then with the slug command. A name that fails either test
breaks the slug rule; the listing then goes on with the next file, because the
stop of the first test does not apply to a listed name.
A file whose name breaks the slug rule gets the label `invalid file name — rename it`,
and it is never chosen. For every other file, run the check command with its
slug and use its word as the label, with `malformed line 1` for `malformed`.

## `/worklog new [<slug>]` — create a work log

1. Test the slug with the slug command, then run the check command on it. A
   word other than `missing` stops the command. Never overwrite a work log.
   With no slug given, ask for the slug in the question batch of step 2, and
   test it the same way before step 3.
2. Ask the user, in one question batch: the title, the goal, the "done when"
   condition, the list of parts, and the admission rule. Offer the default
   admission rule first:

   > A finding becomes an open item only when it blocks a part from reaching the status `done`, or blocks the "done when" condition of the whole work, or when its consequence is lost user work or a wrong commit. Every other finding gets one line under `## Accepted limits`.

   When the user gives no rule of their own, write the default admission rule.
   Use and echo the values that the user already stated in this session; do
   not ask for them again. When the user says that a part is already `done`,
   ask for its commit in the same batch. Without an answer its `Commit` cell
   stays empty: the `git log` read of the full update starts at the creation
   date, so it cannot find an older commit.
3. In a project that is not a git repository, and also when
   `git rev-parse --show-prefix` prints a text that is not empty (the current
   folder stands below the root), show the full target path and ask the user
   to confirm it before writing.
4. Read `<skill-dir>/template.md` with the Read tool. Fill these placeholders
   only: `<slug>` and `<YYYY-MM-DD>` on line 1 (today), `<title>`, the goal,
   the "done when" condition and the admission rule. Replace the example row
   of `## Parts` with one row per part, numbered from 1. Remove the example
   rule, the example limit and the example decision, and keep the section
   headings `## Rules for the next parts`, `## Accepted limits` and
   `## Decisions`. The line `### <YYYY-MM-DD> <short title>` belongs to the
   example decision and is removed with it.
   Leave every other `<...>` text as it is: it belongs to the document's own
   rules. Every part starts as `not started`, except a part that the user
   says is `in progress` or `done`: such a part gets today in `Since`, and its
   `Commit` cell stays empty unless the user gave the commit of a `done` part.
   Create the folder `docs/worklogs/` under the root when it does not exist,
   and write the file.
5. In a git repository, run `git check-ignore -q docs/worklogs/<slug>.md`
   from the root. Exit 0 means that an ignore rule matches the path: tell the
   user that git ignores the file, so a normal `git add` does not add it. On
   any other exit, say nothing.
6. Report the path. Say that the file is not committed, and that the
   session-start notice names it from the next session start on.

## `/worklog` or `/worklog update [<slug>]` — full update

1. Choose the work log and run the ordered checks of "Choosing a work log".
2. Read the work log with the Read tool, whole.
3. Repairs, in `update` only. When a section heading of the template, or the
   line `Next item number`, is missing (the user edited the document), add it
   at its template position and report it. Rebuild a missing number line as
   one plus the highest of: the first column of the `## Open items` rows, and
   every `item #<n>` in the document; with none of these, it is 1. The result
   is a lower bound, because an item whose fix was committed leaves no number:
   say so, and ask the user to confirm the value.
4. Compare the document with the session: the status of each part, problems
   found, fixes committed, decisions made, conventions that appeared, and
   empty `Commit` cells of `done` parts. In a git repository, read the commits
   with this command, where `<created>` is the `created=` date of line 1:
   `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD | cat`
   The window always starts at the creation of the work log, because a
   forgotten change can be as old as the work log. The `00:00` is required:
   with a bare date, git starts at the current time of day of that date. The
   `| cat` is required too: a Bash output hook of this plugin cuts the output
   of a plain `git log` command that is longer than 40 lines to its first 30
   lines, and it never cuts the output of a pipeline. When
   the command prints 200 commits and a question is still open (an empty
   `Commit` cell of a `done` part, or an open item whose fix was not found),
   read the next window with `--skip=200`, then `--skip=400`, at most five
   windows in all; then say that older commits were not read.
5. Apply the update rules of the document's section `How to maintain this
   document`. Report each change in one line, or say that the work log was
   already up to date.

## `/worklog close [<slug>]` — close a work log

1. Choose the work log and run the ordered checks of "Choosing a work log" (a
   closed work log stops there).
2. Read the work log with the Read tool, whole. If a part is neither `done`
   nor `dropped`, or `## Open items` has rows, list them and ask the user:
   close anyway, or stop. On "close anyway": each remaining open item becomes
   one line under `## Accepted limits` in the form
   `- <today> item #<n>: <item text> — open at closing`, and its row is
   deleted; the parts keep their status; and one `## Decisions` entry records
   that the user closed the work log with those parts unfinished.
3. Fill every empty `Commit` cell of a `done` part that can be filled now
   (the `git log` read of the full update, step 4), and report the cells that
   stay empty: after closing, `update` no longer writes this file.
4. Run the line-1 command with line 1 in the closed form: `status=closed`
   instead of `status=active`, and ` closed=<today>` before ` -->`. Then run
   the check command; it must print `closed`.

## Updates outside the commands

When the session-start notice or the user names an active work log, read that work log with the Read tool before starting the work, and follow its section `How to maintain this document`.

## Rules

- This skill never commits. It never reopens a closed work log: the user edits
  line 1 back to the active form by hand.
- Every stop writes nothing more. A stop of the grammar, of the slug test or
  of the ordered checks comes before any write; a stop at step 2 of `close`
  keeps the `slug=` correction that check 5 already made.
- In a project that is not a git repository, skip the `git log` read and the
  `git check-ignore` test, and leave the `Commit` column empty. The root is
  then the folder of the shell, so `new` always shows the full target path and
  asks, and `missing` prints the folder that was searched.
- `docs/worklogs` must be a real folder: the list command does not follow a
  folder that is a symbolic link.
- Never reorder or delete user text, except the deletions that a step of this
  skill or a rule of the work log names (an open-item row that leaves the
  table).
````

- [x] **Step 4: Run the suite to verify it passes**

Run: `bash tests/worklog/run-tests.sh`
Expected: PASS — exit 0, 0 failed (the NOTE lines of Task 2 may appear on some platforms).

Run: `grep -c '^## ' skills/worklog/SKILL.md`
Expected: `9` (Terms, Commands and arguments, Shell commands, Choosing a work log, the three command sections, Updates outside the commands, Rules; the `# Work log` title is not counted).

- [x] **Step 5: Commit**

```bash
git add skills/worklog/SKILL.md tests/worklog/run-tests.sh
git commit -m "feat(worklog): add the grammar, the three commands and the rules to the skill" --trailer "Session: worklog" --trailer "Stage: task 3/9"
```

---

### Task 4: The session-start notice

**Files:**
- Modify: `hooks/session-start`
- Create: `tests/codex/test-session-start-worklog-notice.sh`
- Modify: `tests/codex/run-unit-tests.sh`
- Modify: `tests/codex/test-session-start-budget.sh`
- Modify: `tests/worklog/run-tests.sh`
- Test: `tests/codex/test-session-start-worklog-notice.sh`, `tests/codex/test-session-start-budget.sh`, `tests/worklog/run-tests.sh`

**Security flag:** `security` *(the hook puts file names from the project folder into the model's context; the file-name filter of the list command is the safety rule, and a file name is text that anyone who can add a file controls)*

**Does NOT cover:**
- The hook never injects the content of a work log, and it adds no notice when no active work log with a valid file name exists.
- A subagent never receives the notice: the hook does not run for subagents (intended, spec).
- `claude --resume`: the hook matcher is `startup|clear|compact`; whether the notice appears after a resume is unverified (spec, accepted).
- A work log on another branch, in a second git worktree, or in a `docs/worklogs` folder that is a symbolic link is not named (spec, accepted limits).
- On Windows, a `find` that is not the Git Bash program yields an empty list and no notice; not tested there.
- `hooks/session-start-assemble.js`, `hooks/hooks.json`, `hooks/hooks-cursor.json` and `hooks/codex/` are not changed (Global Constraint 6). The header comment of `hooks/session-start-assemble.js` (line 20) keeps its list "the legacy-skills warning, the update notice and the git note", which no longer names every notice; the spec keeps that file unchanged.

**Contract:**
- The notice block of `hooks/session-start` (code artifact)
  - Input: the working folder of the hook. Output: the variable `worklog_notice`, empty when the list command prints no path, else two line breaks followed by the notice text of Global Constraint 11 with the hook's root.
  - Invariants: the lines from `ROOT=` to the closing `fi` of the list command are the skill's list command without its print line, unchanged (the print line `printf '%s\n' "$LIST"` is left out because the hook's standard output is its JSON output, and the spec's step 2 of "Discovery through the session-start hook" adds nothing to that output when no path is left; the hook reads `LIST` itself); these lines keep the skill's `l = $(0)` where the spec's text has `l = $0` (the deliberate spec deviation named in **Assumptions**: Claude Code replaces `$0` in a skill body, and suite section 8 requires the hook to hold the skill's lines), so "unchanged" in Global Constraint 11 means "the same as the skill's copy"; the notice names at most the first three paths, relative to the root, joined with `, `, then ` and <n> more under docs/worklogs/` when there are more; the root is absolute, cut to its last 300 characters after `…` when longer; `worklog_notice` is the last part of the text written to `${parts_dir}/notices`; the code after the list command runs no pipeline; the hook still exits 0 on every fixture.
  - Verification: `bash tests/codex/test-session-start-worklog-notice.sh`; suite section 8 of `tests/worklog/run-tests.sh`; `bash tests/codex/test-session-start-budget.sh` case 8.
- `tests/codex/test-session-start-worklog-notice.sh` (code artifact)
  - Output: exit 0 only when all six cases pass; one `ok`/`FAIL` line per check.
  - Invariants: runs the hook with `env -i` (no network, a temporary `HOME`, `CLAUDE_PLUGIN_ROOT` set); compares whole outputs for the "identical" cases; builds each expected notice from the fixed tail of Global Constraint 11 and the fixture's real root (`pwd -P`).
  - Verification: Step 2 shows failures on the current hook; Step 4 passes.
- `tests/codex/run-unit-tests.sh` (code artifact): one `run_test` line registers the new file with the runner `bash`, or it never runs. Verification: the runner lists "session-start (active work log notice)".
- `tests/codex/test-session-start-budget.sh` case 8 (code artifact): with three active 40-character work logs and the oversized workspace files of case 5, `assert_common` passes and the notice is injected. The case 5 fixture moves into the function `write_oversized_workspace`, which cases 5 and 8 both call (no copied fixture code). Verification: Step 4.
- `tests/worklog/run-tests.sh` section 8 (code artifact): passes only when `hooks/session-start` contains every line of the skill's list command except its last (print) line, as one contiguous block. Verification: Step 2 fails, Step 4 passes.

- [x] **Step 1: Write the failing tests**

Create `tests/codex/test-session-start-worklog-notice.sh` with this content, then run `chmod +x tests/codex/test-session-start-worklog-notice.sh`:

```bash
#!/usr/bin/env bash
# Unit test: the <active-work-logs> notice of hooks/session-start (skill
# worklog, v7.52.0). The hook runs the list command of skills/worklog/SKILL.md
# in the project directory and names at most three active work logs in one
# notice. It appends the notice to the notices part, which is always included,
# whatever the size of state.md.
#
# Cases (from the section "Testing strategy" of the worklog design):
#   1. No docs/worklogs folder: exit 0, no notice, and the same output as with
#      a folder that holds only a closed work log. This pins the hook's
#      "set -euo pipefail": a find on an absent folder must not end the hook.
#   2. One active and one closed work log: the exact one-path notice, after
#      two line breaks, at the end of the notices part.
#   3. A file name that breaks the slug rule, with an active line 1: the same
#      output as without that file. An assertion "is not named" alone would
#      also pass on a hook that ended early.
#   4. Five active work logs: the exact five-path notice, also when the hook
#      starts in a sub-folder of the project.
#   5. An unreadable work log between two readable ones, and a work log whose
#      line 1 starts with a byte order mark.
#   6. A root longer than 300 characters: its last 300 characters, after "…".
#
# Self-contained like tests/codex/test-session-start-budget.sh: no network
# (SUPERPOWERS_AUTO_UPDATE=0), a temporary HOME, CLAUDE_PLUGIN_ROOT set. The
# output is parsed with JSON.parse (Node).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK="${REPO_ROOT}/hooks/session-start"
OPEN_TAG="<active-work-logs>"
CLOSING_TAG="</EXTREMELY_IMPORTANT>"
CREATED="2026-09-21"
NL=$'\n'
NOTICE_TAIL='. Before you work on one of them, read it with the Read tool and follow its section "How to maintain this document". During an orchestrated run or a whole-branch review, do not write it.</active-work-logs>'

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
# pwd -P resolves macOS's /var -> /private/var symbolic link, so a fixture
# path equals the root that git rev-parse --show-toplevel prints in the hook.
TMP=$(mktemp -d)
TMP=$(cd "$TMP" && pwd -P)
TMP_HOME=$(mktemp -d)
trap 'chmod -R u+rwx "$TMP" 2>/dev/null || true; rm -rf "$TMP" "$TMP_HOME"' EXIT

PASS=0
FAIL=0
ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# assert_eq <label> <actual> <expected>
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# assert_contains <label> <haystack> <needle>
assert_contains() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *) bad "$1" ;;
  esac
}
# assert_absent <label> <haystack> <needle>
assert_absent() {
  case "$2" in
    *"$3"*) bad "$1" ;;
    *) ok "$1" ;;
  esac
}
# assert_same <label> <context> <other context>: without the texts in the
# message, because a context is several thousand characters long.
assert_same() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1"; fi
}

# run_hook <dir>: runs the hook with <dir> as the working directory. Sets
# HOOK_CODE to its exit status and CTX to the additionalContext string of the
# Claude Code output branch.
run_hook() {
  local raw="${TMP}/hook-output.json"
  local pass=()
  [ -n "${SYSTEMROOT:-}" ] && pass+=("SYSTEMROOT=$SYSTEMROOT")
  [ -n "${TEMP:-}" ] && pass+=("TEMP=$TEMP")
  HOOK_CODE=0
  (cd "$1" && env -i PATH="$PATH" HOME="$TMP_HOME" GIT_CEILING_DIRECTORIES="$TMP" \
      CLAUDE_PLUGIN_ROOT="$REPO_ROOT" SUPERPOWERS_AUTO_UPDATE=0 \
      ${pass[@]+"${pass[@]}"} bash "$HOOK") > "$raw" || HOOK_CODE=$?
  CTX=$(node -e '
    const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    process.stdout.write(j.hookSpecificOutput.additionalContext);' "$raw")
}

# project <name>: an empty git repository; sets P to its path.
project() {
  P="${TMP}/$1"
  mkdir -p "$P"
  git -C "$P" init -q
}

# worklog <file name> <active|closed>: a work log in $P/docs/worklogs whose
# slug= field repeats the file name.
worklog() {
  local slug="${1%.md}"
  mkdir -p "${P}/docs/worklogs"
  if [ "$2" = active ]; then
    printf '<!-- Work log: status=active slug=%s created=%s -->\n\n# Work log: fixture\n' "$slug" "$CREATED"
  else
    printf '<!-- Work log: status=closed slug=%s created=%s closed=%s -->\n\n# Work log: fixture\n' "$slug" "$CREATED" "$CREATED"
  fi > "${P}/docs/worklogs/$1"
}

# notice <root> <paths> [more]: the exact notice text of the design.
notice() {
  printf '%sActive work logs under %s: %s%s%s' "$OPEN_TAG" "$1" "$2" "${3:-}" "$NOTICE_TAIL"
}

echo "session-start: active work log notice"

# ── Case 1: no docs/worklogs folder ────────────────────────────────────────
project nofolder
run_hook "$P"
assert_eq "no folder: the hook exits 0" "$HOOK_CODE" "0"
assert_absent "no folder: no notice" "$CTX" "$OPEN_TAG"
ctx_nofolder="$CTX"
worklog z.md closed
run_hook "$P"
assert_eq "only a closed work log: the hook exits 0" "$HOOK_CODE" "0"
assert_same "only a closed work log: the output equals the output with no folder" "$CTX" "$ctx_nofolder"

# ── Case 2: one active and one closed work log ─────────────────────────────
project one
worklog a.md active
worklog z.md closed
run_hook "$P"
assert_eq "one active work log: the hook exits 0" "$HOOK_CODE" "0"
assert_contains "one active work log: the exact notice, after two line breaks, at the end of the notices" \
  "$CTX" "${NL}${NL}$(notice "$P" docs/worklogs/a.md)${NL}${CLOSING_TAG}"
assert_absent "one active work log: the closed work log is not named" "$CTX" "docs/worklogs/z.md"

# ── Case 3: file names that break the slug rule ────────────────────────────
S41=$(printf '%41s' '' | tr ' ' s)
i=0
for name in 'x y.md' 'A.md' 'new.md' "${S41}.md"; do
  i=$(( i + 1 ))
  project "badname${i}"
  worklog z.md closed
  run_hook "$P"
  ctx_without="$CTX"
  worklog "$name" active
  run_hook "$P"
  assert_eq "${name}: the hook exits 0" "$HOOK_CODE" "0"
  assert_same "${name}: the output equals the output without that file" "$CTX" "$ctx_without"
done

# ── Case 4: five active work logs ──────────────────────────────────────────
project five
for letter in a b c d e; do worklog "${letter}.md" active; done
five_notice=$(notice "$P" "docs/worklogs/a.md, docs/worklogs/b.md, docs/worklogs/c.md" " and 2 more under docs/worklogs/")
run_hook "$P"
assert_contains "five active work logs: the exact notice" "$CTX" "$five_notice"
mkdir -p "${P}/src"
run_hook "${P}/src"
assert_contains "five active work logs, hook started in a sub-folder: the same notice" "$CTX" "$five_notice"

# ── Case 5: an unreadable work log and a byte order mark ───────────────────
project unreadable
worklog a.md active
worklog b.md active
printf '\357\273\277<!-- Work log: status=active slug=c created=%s -->\n' "$CREATED" > "${P}/docs/worklogs/c.md"
chmod 000 "${P}/docs/worklogs/b.md"
if [ -r "${P}/docs/worklogs/b.md" ]; then
  echo "  note - b.md stays readable (root user?); it is removed, and only the byte order mark is checked"
  rm -f "${P}/docs/worklogs/b.md"
fi
run_hook "$P"
assert_eq "unreadable work log: the hook exits 0" "$HOOK_CODE" "0"
assert_contains "an unreadable work log hides neither readable one; the byte order mark one is named" \
  "$CTX" "$(notice "$P" "docs/worklogs/a.md, docs/worklogs/c.md")"

# ── Case 6: a root longer than 300 characters ──────────────────────────────
long_a=$(printf '%200s' '' | tr ' ' a)
long_b=$(printf '%200s' '' | tr ' ' b)
project "${long_a}/${long_b}"
worklog a.md active
run_hook "$P"
assert_contains "a root longer than 300 characters: its last 300 characters after …" \
  "$CTX" "$(notice "…${P: -300}" docs/worklogs/a.md)"
assert_absent "a root longer than 300 characters: the full root is not printed" "$CTX" "under ${P}:"

echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
```

In `tests/codex/run-unit-tests.sh`, add this line directly after the line that registers `test-session-start-budget.sh`:

```bash
run_test "session-start (active work log notice)" "${SCRIPT_DIR}/test-session-start-worklog-notice.sh" bash
```

In `tests/codex/test-session-start-budget.sh`:

1. In the header list "What the hook must do to stay under the budget, and what is asserted here", add after item 4:

```bash
#   5. Stay at or under the budget when the <active-work-logs> notice names
#      three work logs with 40-character slugs (case 8).
```

2. Replace the fixture block of case 5 — the parenthesised block that starts with `cd "$TMP_REPO"` and `{ printf 'Current Goal: STATE-SENTINEL budget fixture, active task\n'; text_of 500 state; } > state.md` and ends with the `context-snapshot.json` line and `)`, directly above `ctx_full=$(run_hook_in "$TMP_REPO")` — by a function that holds the same block, indented by two spaces, and one call:

```bash
# write_oversized_workspace: the workspace files of case 5 in $TMP_REPO;
# case 8 uses them too.
write_oversized_workspace() {
  (
    cd "$TMP_REPO"
    { printf 'Current Goal: STATE-SENTINEL budget fixture, active task\n'; text_of 500 state; } > state.md
    {
      printf '## 2026-01-01 10:00 [saved]\nGoal: SESSION-LOG-SENTINEL one\n'; text_of "$LIMIT" log
      printf '## 2026-01-02 10:00 [saved]\nGoal: SESSION-LOG-SENTINEL two\n'; text_of "$LIMIT" log
    } > session-log.md
    for i in 1 2 3 4 5; do
      printf '## KNOWN-ISSUES-SENTINEL issue %d\n' "$i"; text_of "$(( LIMIT / 4 ))" issue
    done > known-issues.md
    write_map "PROJECT-MAP-SENTINEL${NL}$(text_of "$LIMIT" map)" > project-map.md
    printf '{"changed_files":["snapshot-sentinel.js"],"recent_commits":["abc1234 init"]}\n' > context-snapshot.json
  )
}
write_oversized_workspace
```

3. Insert case 8 directly before the final line pair `echo "  ${PASS} passed, ${FAIL} failed"` / `[ "$FAIL" -eq 0 ]`:

```bash
# ── Case 8: three active work logs with 40-character slugs ─────────────────
# The <active-work-logs> notice belongs to the notices, which are always
# included, so its room comes out of the room of the workspace sections.
# With the longest notice that three names can produce and the oversized
# workspace files of case 5, the output must stay at or under the limit.
(
  cd "$TMP_REPO"
  mkdir -p docs/worklogs
  for letter in a b c; do
    slug="${letter}$(printf '%39s' '' | tr ' ' w)"
    printf '<!-- Work log: status=active slug=%s created=2026-09-21 -->\n' "$slug" > "docs/worklogs/${slug}.md"
  done
)
write_oversized_workspace
ctx_worklogs=$(run_hook_in "$TMP_REPO")
clear_workspace
rm -rf "$TMP_REPO/docs"
assert_common "three 40-character work logs" "$ctx_worklogs"
assert_contains "three 40-character work logs: the notice is injected" "$ctx_worklogs" "<active-work-logs>"
```

In `tests/worklog/run-tests.sh`, insert this block directly before the footer line `bold ""`:

```bash
bold "8. hooks/session-start holds the list command unchanged"
# Every line of the list command except its last one, the print line: the
# hook uses the LIST variable itself.
HOOK_LIST=$(printf '%s\n' "$LIST_CMD" | sed '$d')
HOOK_TEXT=$(cat "$REPO/hooks/session-start")
if [ -n "$HOOK_LIST" ]; then
  case "$HOOK_TEXT" in
    *"$HOOK_LIST"*) ok "the hook holds the list command of the skill, line for line" ;;
    *) bad "the hook holds the list command of the skill, line for line" ;;
  esac
else
  bad "the hook holds the list command of the skill, line for line (the skill text holds no list command)"
fi

```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash tests/codex/test-session-start-worklog-notice.sh`
Expected: FAIL — exit 1, `16 passed, 5 failed`: the notice checks of cases 2, 4 (both), 5 and 6 fail, because the output holds no notice; cases 1 and 3 pass.

Run: `bash tests/codex/test-session-start-budget.sh`
Expected: FAIL — exit 1; only "three 40-character work logs: the notice is injected" fails; every other check, case 5 included, passes.

Run: `bash tests/worklog/run-tests.sh`
Expected: FAIL — exit 1; only "the hook holds the list command of the skill, line for line" fails.

- [x] **Step 3: Add the notice to the hook**

In `hooks/session-start`, insert this block directly after the `fi` that closes the "Git repository check" block (the `git_notice` assignment), before the line `# ── Legacy skills warning`, with one empty line before and after it:

```bash
# ── Active work logs ──────────────────────────────────────────────────────────
# Names the active work logs of the project (skills/worklog) in one short
# notice; the content of a work log is never injected. The lines from ROOT= to
# the closing fi are the list command of skills/worklog/SKILL.md, copied
# unchanged (tests/worklog/run-tests.sh compares the two). Like the skill, the
# awk program reads the whole line as $(0), not $0: Claude Code replaces a "$"
# followed by a digit in a skill body with an argument, and this copy must
# stay equal to the skill's copy. Its folder test and
# its "|| true" keep it safe under the "set -euo pipefail" of line 4: a find
# on an absent folder exits 1, pipefail passes that status through sort, and
# set -e would end this hook at the assignment. The code after it runs no
# pipeline of its own, so it needs no such protection. It names at most three
# paths, relative to the root, and names the root once as an absolute path,
# because the model's idea of its working folder can move during a session.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIST=""
if [ -d "$ROOT/docs/worklogs" ]; then
  LIST="$(LC_ALL=C find "$ROOT/docs/worklogs" -maxdepth 1 -type f -name '*.md' -exec awk '
    FNR==1 { l = $(0); sub(/^\357\273\277/, "", l)
      if (l ~ /^<!-- Work log: status=active /) {
        n = FILENAME; sub(/.*\//, "", n)
        if (n ~ /^[a-z0-9]+(-[a-z0-9]+)*\.md$/ && length(n) <= 43 &&
            n != "new.md" && n != "update.md" && n != "close.md") print FILENAME
      }
      exit }' {} \; 2>/dev/null | LC_ALL=C sort || true)"
fi
worklog_notice=""
if [ -n "$LIST" ]; then
    worklog_rest="$LIST"
    worklog_count=0
    worklog_paths=""
    while [ -n "$worklog_rest" ]; do
        worklog_path="${worklog_rest%%"$nl"*}"
        if [ "$worklog_path" = "$worklog_rest" ]; then
            worklog_rest=""
        else
            worklog_rest="${worklog_rest#*"$nl"}"
        fi
        worklog_count=$(( worklog_count + 1 ))
        if [ "$worklog_count" -le 3 ]; then
            worklog_paths="${worklog_paths:+${worklog_paths}, }${worklog_path#"$ROOT"/}"
        fi
    done
    worklog_more=""
    if [ "$worklog_count" -gt 3 ]; then
        worklog_more=" and $(( worklog_count - 3 )) more under docs/worklogs/"
    fi
    # A root longer than 300 characters keeps its last 300, so the notice
    # stays small; the model then cannot open the file from the notice alone.
    worklog_root="$ROOT"
    if [ "${#worklog_root}" -gt 300 ]; then
        worklog_root="…${worklog_root: -300}"
    fi
    worklog_notice="${nl}${nl}<active-work-logs>Active work logs under ${worklog_root}: ${worklog_paths}${worklog_more}. Before you work on one of them, read it with the Read tool and follow its section \"How to maintain this document\". During an orchestrated run or a whole-branch review, do not write it.</active-work-logs>"
fi
```

Then change the line that writes the notices part (line 529 before this task):

```bash
printf '%s' "${warning_message}${update_notice}${git_notice}${worklog_notice}" > "${parts_dir}/notices"
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/codex/test-session-start-worklog-notice.sh`
Expected: PASS — `21 passed, 0 failed`, exit 0.

Run: `bash tests/codex/test-session-start-budget.sh`
Expected: PASS — 0 failed, exit 0; "three 40-character work logs: <n> characters, at or under 10000".

Run: `bash tests/worklog/run-tests.sh`
Expected: PASS — exit 0, 0 failed.

Run: `bash tests/codex/run-unit-tests.sh`
Expected: PASS — "All unit tests passed."; the list shows "── session-start (active work log notice)".

- [x] **Step 5: Commit**

```bash
git add hooks/session-start tests/codex/test-session-start-worklog-notice.sh tests/codex/run-unit-tests.sh tests/codex/test-session-start-budget.sh tests/worklog/run-tests.sh
git commit -m "feat(session-start): name the active work logs in one notice" --trailer "Session: worklog" --trailer "Stage: task 4/9"
```

---

### Task 5: `/pickup` does not count an uncommitted work log as work

**Files:**
- Modify: `skills/pickup/scripts/pickup-scan.js`
- Modify: `tests/pickup/run-tests.sh`
- Test: `tests/pickup/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** a commit made after the handoff still gives `CHECK`, also when it touches only `docs/worklogs/` — `NOT_WORK` covers the uncommitted-change check only (spec, accepted). A new file elsewhere under `docs/` still counts as work; when `docs/` itself is untracked and holds such a file, git reports the whole `docs/` folder as one line.

**Contract:**
- `NOT_WORK` in `skills/pickup/scripts/pickup-scan.js` (code artifact)
  - Input: the working tree. Output: the `dirty:` count excludes every path under `docs/worklogs`, as it excludes `tmp/docs`, `state.md` and `session-log.md`.
  - Invariants: the comment above the constant says why the work logs are excluded and that the list covers the uncommitted-change check only; the commit counts are not changed.
  - Verification: `bash tests/pickup/run-tests.sh` case 6c.
- `tests/pickup/run-tests.sh` case 6c (code artifact): a `FRESH` handoff stays `FRESH` with a changed tracked work log and a new untracked one; a new `docs/notes.md` gives `dirty: 1` and `CHECK`. The case calls no helper defined below it (`add_file` is defined in section 10). Verification: Step 2 fails, Step 4 passes.

- [x] **Step 1: Write the failing test**

In `tests/pickup/run-tests.sh`, insert this block directly before the line `bold "7. CHECK: a commit on an unmerged other branch while HEAD is on the default branch"`:

```bash
bold "6c. An uncommitted work log is not work (skill worklog)"
# add_file is defined in section 10, below this case, so this case writes its
# files inline.
base_repo worklog
mkdir -p "$D/docs/worklogs"
printf '<!-- Work log: status=active slug=t created=2026-01-09 -->\n' > "$D/docs/worklogs/t.md"
git -C "$D" add docs/worklogs/t.md
GIT_AUTHOR_DATE="$BEFORE" GIT_COMMITTER_DATE="$BEFORE" git -C "$D" commit -q -m "work log"
H=$(git -C "$D" rev-parse --short=7 HEAD)
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

```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/pickup/run-tests.sh`
Expected: FAIL — exit 1; the three case 6c checks "a changed and a new file under docs/worklogs are not dirty" (got `dirty: 2`), "status stays FRESH" and "a new file elsewhere under docs/ is dirty" (got `dirty: 3`) fail.

- [x] **Step 3: Extend `NOT_WORK`**

In `skills/pickup/scripts/pickup-scan.js`, replace the two lines

```js
// Files that /handoff itself writes after the handoff; they are not work.
const NOT_WORK = [HANDOFF_DIR, 'state.md', 'session-log.md'];
```

with

```js
// Files that /handoff itself writes after the handoff, and the work logs of
// skills/worklog, which the same sessions update; they are not work. This list
// covers the uncommitted-change check only: a commit made after the handoff
// still counts, also when it touches only docs/worklogs.
const NOT_WORK = [HANDOFF_DIR, 'state.md', 'session-log.md', 'docs/worklogs'];
```

- [x] **Step 4: Run the test to verify it passes**

Run: `bash tests/pickup/run-tests.sh`
Expected: PASS — exit 0, 0 failed.

- [x] **Step 5: Commit**

```bash
git add skills/pickup/scripts/pickup-scan.js tests/pickup/run-tests.sh
git commit -m "feat(pickup): an uncommitted work log is not unfinished work" --trailer "Session: worklog" --trailer "Stage: task 5/9"
```

---

### Task 6: Routing — the `worklog` rule

**Files:**
- Modify: `hooks/skill-rules.json`
- Modify: `tests/codex/test-skill-activator.js`
- Test: `tests/codex/test-skill-activator.js`

**Security flag:** `none`

**Does NOT cover:** the position of `worklog` in the suggestion list — the contract is that the list contains it (spec, "Interfaces and contracts"). `tracking document` and `work logs` are not keywords, and there is no pattern for "keep track of the work" (spec: each produced false hits). A slash command such as `/worklog new x` scores 1 and gets no suggestion; the slash command invokes the skill directly.

**Contract:**
- The `worklog` entry of `hooks/skill-rules.json` (code artifact)
  - Invariants: the entry holds exactly the fields and values of Global Constraint 12, and it stands before the `brainstorming` entry (directly after `premise-check`), so before `brainstorming`, `writing-plans` and `refactoring`; the file stays valid JSON.
  - Verification: `node tests/codex/test-skill-activator.js`; Step 4's JSON check.
- The worklog routing tests in `tests/codex/test-skill-activator.js` (code artifact): the two positive prompts contain `worklog`; the four negative prompts do not; the mixed feature prompt still contains `brainstorming`. Verification: Step 2 fails on the two positive prompts, Step 4 passes.

- [x] **Step 1: Write the failing tests**

In `tests/codex/test-skill-activator.js`, insert this block directly before the line `// ── Result ────────────────────────────────────────────────────────────────────`:

```js
// ── worklog routing ───────────────────────────────────────────────────────────
// The worklog rule stands before brainstorming, refactoring and writing-plans
// in hooks/skill-rules.json: with equal priority and equal score the sort
// keeps the file order, and only the first three suggestions are returned.

console.log('\nworklog routing');

const suggested = (prompt) => matchSkills(prompt).map(m => m.skill);

for (const prompt of [
  'update the work log of the test refactoring',
  'create a work log for the test refactoring',
]) {
  test(`"${prompt}" suggests worklog`, () => {
    const matched = suggested(prompt);
    assert.ok(matched.includes('worklog'), `Expected worklog, got: ${JSON.stringify(matched)}`);
  });
}

// "network logs" and "framework logs" contain the keyword "work log" as a
// plain substring (score 1, below the threshold of 2); "worker threads" and
// "work logging" must not reach an intent pattern.
for (const prompt of [
  'check the network logs',
  'read the framework logs',
  'keep track of the worker threads',
  'close work logging when the app shuts down',
]) {
  test(`"${prompt}" does NOT suggest worklog`, () => {
    const matched = suggested(prompt);
    assert.ok(!matched.includes('worklog'), `Unexpected worklog suggestion: ${JSON.stringify(matched)}`);
  });
}

test('a feature request that mentions keeping track still suggests brainstorming', () => {
  const matched = suggested('add a feature to keep track of the worker threads, write a plan and refactor the pool module');
  assert.ok(matched.includes('brainstorming'), `Expected brainstorming, got: ${JSON.stringify(matched)}`);
});

```

- [x] **Step 2: Run the tests to verify they fail**

Run: `node tests/codex/test-skill-activator.js`
Expected: FAIL — exit 1; `2 failed`: "update the work log of the test refactoring" suggests worklog, and "create a work log for the test refactoring" suggests worklog.

- [x] **Step 3: Add the rule**

In `hooks/skill-rules.json`, insert this object between the `},` that closes the `premise-check` entry and the `{` that opens the `brainstorming` entry:

```json
    {
      "skill": "worklog",
      "type": "workflow",
      "priority": "high",
      "keywords": ["work log", "worklog"],
      "intentPatterns": ["(create|start|open|new)\\s+(a\\s+|the\\s+)?work\\s?logs?\\b", "(update|close|continue)\\s+(the\\s+|my\\s+)?work\\s?logs?\\b"]
    },
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `node -e 'const r = require("./hooks/skill-rules.json").rules; const i = r.findIndex((x) => x.skill === "worklog"); console.log(i, r[i + 1].skill, r.length)'`
Expected: `5 brainstorming 28`.

Run: `node tests/codex/test-skill-activator.js`
Expected: PASS — exit 0, `152 passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add hooks/skill-rules.json tests/codex/test-skill-activator.js
git commit -m "feat(routing): route work log requests to the worklog skill" --trailer "Session: worklog" --trailer "Stage: task 6/9"
```

---

### Task 7: Skill triggering and the Routing Guide

**Files:**
- Create: `tests/skill-triggering/prompts/worklog.txt`
- Modify: `tests/skill-triggering/run-all.sh`
- Modify: `skills/using-superpowers/SKILL.md`
- Test: `tests/skill-triggering/run-test.sh`, `tests/codex/test-session-start-budget.sh`

**Security flag:** `none`

**Does NOT cover:** the triggering test calls the real `claude` CLI once; one run of a model is not deterministic. The Routing Guide line is below the `session-start-injection-ends` marker, so it is not in the session-start injection and is read only when the model loads `using-superpowers` with the Skill tool.

**Contract:**
- `tests/skill-triggering/prompts/worklog.txt` (wording artifact)
  - Must convey: a naive request to start a work log for a multi-session piece of work, without the skill name as a command; `matchSkills` suggests `worklog` for it and does not suggest `brainstorming` (replayed while writing this plan: `["worklog:3"]`).
  - Invariant: git tracks the file although `.gitignore` line 18 (`*.txt`) matches it.
  - Verification: `git ls-files --error-unmatch tests/skill-triggering/prompts/worklog.txt` after Step 5; `bash tests/skill-triggering/run-test.sh worklog tests/skill-triggering/prompts/worklog.txt 8` prints `PASS`.
- The `SKILLS` array of `tests/skill-triggering/run-all.sh` (code artifact): holds `"worklog"`; the suite runs only the skills that the array names. Verification: `grep -n '"worklog"' tests/skill-triggering/run-all.sh` (Step 3).
- The Routing Guide line in `skills/using-superpowers/SKILL.md` (wording artifact)
  - Must convey: a request to create, update or close a work log routes to `worklog`.
  - Invariants: the line stands in `## Routing Guide`, below the marker line; the text above the marker is unchanged (at most 6,400 characters).
  - Verification: `bash tests/codex/test-session-start-budget.sh` passes; the Step 3 `awk` prints `BELOW-MARKER`, and `git diff --numstat` shows one added line and none removed.

- [x] **Step 1: Write the prompt, the array entry and the guide line**

Create `tests/skill-triggering/prompts/worklog.txt` with this one line:

```text
The test refactoring in this project will take many sessions: four groups of tests, refactored one group after the other. Start a work log for it, so that every session sees which groups are done and which problems are still open.
```

In `tests/skill-triggering/run-all.sh`, add the line `    "worklog"` after the line `    "multi-code-review"` inside the `SKILLS=(` array.

In `skills/using-superpowers/SKILL.md`, in `## Routing Guide`, add this line directly after the line that starts `- Known issue tracking / save recurring fixes:`:

```markdown
- Tracking document for one piece of multi-part work across sessions (create, update or close a work log): `worklog`
```

- [x] **Step 2: Run the routing check**

Run: `node -e 'const { matchSkills } = require("./hooks/skill-activator"); const p = require("fs").readFileSync("tests/skill-triggering/prompts/worklog.txt", "utf8"); console.log(JSON.stringify(matchSkills(p).map((m) => m.skill)))'`
Expected: `["worklog"]`.

- [x] **Step 3: Run the budget test**

Run: `bash tests/codex/test-session-start-budget.sh`
Expected: PASS — 0 failed; "the injected skill part is <n> characters, at or under 6400".

Run: `awk '/^<!-- session-start-injection-ends/ { m = NR } /^- Tracking document for one piece of multi-part work/ { w = NR } END { print (m > 0 && w > m) ? "BELOW-MARKER" : "NOT-BELOW" }' skills/using-superpowers/SKILL.md; git diff --numstat skills/using-superpowers/SKILL.md; grep -n '"worklog"' tests/skill-triggering/run-all.sh`
Expected: `BELOW-MARKER`; one line with `1`, `0` and `skills/using-superpowers/SKILL.md`, separated by tabs (one line added, none removed, so the text above the marker is unchanged); one line that holds `"worklog"`.

- [x] **Step 4: Run the skill-triggering test**

Run: `bash tests/skill-triggering/run-test.sh worklog tests/skill-triggering/prompts/worklog.txt 8`
Expected: `✅ PASS: Skill 'worklog' was triggered` (takes up to 5 minutes; it calls the real `claude` CLI with `--plugin-dir` set to this checkout). Run it with a Bash tool timeout of at least 360000 ms (6 minutes): the default of 120000 ms ends the tool call before the script prints its result, and a tool time-out is not a FAIL. A model run is not deterministic: when it prints FAIL, run it once more; when the second run also fails, stop and report BLOCKED with the log path that the script prints.

- [x] **Step 5: Commit**

```bash
git add -f tests/skill-triggering/prompts/worklog.txt
git add tests/skill-triggering/run-all.sh skills/using-superpowers/SKILL.md
git commit -m "test(skill-triggering): add the worklog prompt; route work logs in the guide" --trailer "Session: worklog" --trailer "Stage: task 7/9"
git ls-files --error-unmatch tests/skill-triggering/prompts/worklog.txt
```

Expected after the last command: it prints `tests/skill-triggering/prompts/worklog.txt` and exits 0.

---

### Task 8: User documentation

**Files:**
- Modify: `docs/guide/README.md`
- Modify: `README.md`
- Modify (on disk only, git-ignored): `CLAUDE.md`

**Security flag:** `none`

**Does NOT cover:** `docs/FORK-IMPROVEMENTS.md` and `docs/REVIEW-PROCESS-COMPARISON.md` (historical, Global Constraint 13); `plugin.universal.yaml` (version only, Task 9); the version badge, the release ranges and the release list of `README.md` (Task 9). `CLAUDE.md` is git-ignored (`.gitignore` line 7): its edit stays on disk and does not ship with the branch.

**Contract:**
- `docs/guide/README.md` (wording artifact)
  - Must convey: the memory-files table has a row for `docs/worklogs/<slug>.md`; the §6 introduction names the work logs under `docs/worklogs/`; the `/pickup` paragraph says that a change under `docs/worklogs/` is not an uncommitted change; a new subsection at the end of §6 explains what a work log is, the three commands, that the skill never commits, the session-start notice, the branch advice, the worktree advice, the advice to commit before an orchestrated run or a whole-branch review, that `docs/worklogs` must be a real folder, and the manual reopen; the phrase cheat-sheet has a `/worklog` row.
  - Invariant: plain English, a term defined at its first use (the user's writing rules).
  - Verification: the Step 2 `grep` commands for the table row, the heading and the command strings; the advice items of the new subsection and the `/pickup` sentence by reading the edited text against this "Must convey" list.
- `README.md` (wording artifact)
  - Must convey: 31 skills in the three count places (lines 68, 220, 330); the example project map line counts 28 rules covering 27 skills; a `worklog` entry in the Core Workflow list after `pickup`.
  - Verification: the Step 2 `grep` commands.
- `CLAUDE.md` (wording artifact, not committed): one Testing line for `bash tests/worklog/run-tests.sh`. Verification: `grep -n 'tests/worklog/run-tests.sh' CLAUDE.md`, or, when the implementer declined the edit, the manual step named in its report.

- [x] **Step 1: Edit the three files**

`docs/guide/README.md`:

1. In §6, the two lines that start `so through plain-text files — five at your project root` and `files under` (lines 1143 and 1144 before this task) become these three lines:

```markdown
so through plain-text files — five at your project root, plus the handoff
files under `tmp/docs/` and the work logs under `docs/worklogs/` — readable,
editable, and deletable by you:
```

2. In the memory-files table, add this row directly after the `tmp/docs/<date>-handoff-<slug>.md` row:

```markdown
| `docs/worklogs/<slug>.md` | Where one piece of multi-part work stands: its parts, open items, accepted limits and decisions | `/worklog new`; then at each change, by the rules in the file itself; `/worklog` for a full update; `/worklog close` |
```

3. In the `/pickup` paragraph, the sentence "The files that `/handoff` itself writes (...) do not count as uncommitted changes." ends in the middle of line 1194 (before this task), and the next sentence starts on the same line. Replace the two lines 1193 and 1194

```markdown
(`tmp/docs/`, `state.md`, `session-log.md`) do not count as uncommitted
changes. When the handoff has a `Done when:` line, `/pickup` tests that
```

with these four lines, so the new sentence stands between the two:

```markdown
(`tmp/docs/`, `state.md`, `session-log.md`) do not count as uncommitted
changes. Since v7.52.0, a change under `docs/worklogs/` (a work log, see the
end of this section) does not count either. When the handoff has a
`Done when:` line, `/pickup` tests that
```

4. Directly before the line `## 7. Context pressure — the "memory almost full" safety gate`, insert this subsection, with one empty line before and after it:

```markdown
### Work logs — one tracking document for multi-part work

Since v7.52.0, a **work log** records the progress of one piece of work that
has several parts and lasts many sessions — for example four groups of tests
that you refactor one group after the other. A work log is one Markdown file,
`docs/worklogs/<slug>.md`, and git tracks it. A project can hold several. The
slug is the short name of the work log: lowercase ASCII letters (`a` to `z`),
digits and single hyphens, at most 40 characters, and not one of the command
words `new`, `update` and `close`.

The file has a table of parts, a list of open items, a list of accepted
limits, and a list of decisions. Its header holds its own update rules, so any
session that reads the file can keep it up to date, also on a computer where
the plugin is not installed. An **admission rule** (a rule that decides which
problem becomes an open item) keeps the list of open items short: every other
correct finding gets one line under `## Accepted limits`.

| Command | What it does |
| --- | --- |
| `/worklog new [<slug>]` | Asks for the title, the goal, the "done when" condition, the parts and the admission rule, then writes the file. It never overwrites a file. |
| `/worklog` or `/worklog update [<slug>]` | A full update: compares the file with the session and with the commits made since the file was created, and applies the file's own rules. |
| `/worklog close [<slug>]` | Closes the work log. When a part is not finished or an open item remains, it asks you first. |

Without a slug, `update` and `close` use the only active work log, or ask you
which one. The skill never commits: the work log goes into the next commit that
you ask for. At each session start, after `/clear` and after a compaction (the
automatic shortening of a long conversation), the session-start hook names the
active work logs in one short notice; it never adds their content.

What you should know:

- **Keep the work log on the branch where the work happens.** A session on a
  branch that does not hold the file cannot see it.
- **Commit the work log before you create a git worktree** (a second working
  folder of the same repository). An uncommitted work log is absent there, and
  two edited copies meet in a merge.
- **Commit the work log before an orchestrated run or a whole-branch review.**
  Those tools stop on an uncommitted file that they do not know. While such a
  run is in progress, the work log is not written.
- **`docs/worklogs` must be a real folder**, not a symbolic link: the list of
  active work logs does not follow a folder that is a link.
- A closed work log is reopened by hand: edit its line 1 back to the active
  form, `<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->`.
```

5. In §8 "Phrase cheat-sheet", add this row directly after the `/pickup [handoff path]` row:

```markdown
| `/worklog new [<slug>]`, `/worklog`, `/worklog close [<slug>]` | Create, fully update or close a work log: the tracking document of one piece of multi-part work, under `docs/worklogs/` | §6 |
```

`README.md`:

1. Line 68: `a workflow router and 30 skills` becomes `a workflow router and 31 skills`.
2. Line 220: `skills/ — 30 skills, each in skills/<name>/SKILL.md` becomes `skills/ — 31 skills, each in skills/<name>/SKILL.md`.
3. Line 225: `27 rules covering 26 skills` becomes `28 rules covering 27 skills`.
4. Line 330: `## Skills Library (30 skills)` becomes `## Skills Library (31 skills)`.
5. Directly after the `- **pickup** — ...` line of the Core Workflow list, add:

```markdown
- **worklog** — `/worklog [new|update|close] [<slug>]`: creates, fully updates and closes a work log, one Markdown document per piece of multi-part work at `docs/worklogs/<slug>.md` (parts, open items, accepted limits, decisions) that carries its own update rules; the session-start hook names the active work logs; never commits
```

`CLAUDE.md` (git-ignored; the edit stays on disk): in the Testing block, directly after the line that starts `bash tests/suite-guard/run-tests.sh`, add:

```bash
bash tests/worklog/run-tests.sh              # skills/worklog: template, the slug/list/check/line-1 commands copied from the skill text, pinned phrases, the hook's copy of the list command
```

If the implementer declines this edit (its own rules may forbid a change to `CLAUDE.md` that another agent asks for), it names the line in its report as a manual step for the user, and the task still counts as done: the file is git-ignored and ships with nothing.

- [x] **Step 2: Verify the edits**

Run: `grep -c '31 skills' README.md; grep -c '30 skills' README.md; grep -c '28 rules covering 27 skills' README.md; grep -c '^- \*\*worklog\*\*' README.md`
Expected: `3`, `0`, `1`, `1`.

Run: `grep -c 'docs/worklogs' docs/guide/README.md; grep -n '^### Work logs' docs/guide/README.md; grep -c '/worklog new \[<slug>\]' docs/guide/README.md`
Expected: a count of at least `6`; one heading line; `2` (the command table and the cheat-sheet row).

Run: `grep -n 'tests/worklog/run-tests.sh' CLAUDE.md; git status --short CLAUDE.md`
Expected: one line; `git status` prints nothing (the file is ignored). When the edit was declined, the `grep` prints nothing and the report names the manual step instead.

Run: `bash tests/review-gates/run-tests.sh`
Expected: PASS — section 2d finds no complete defaults block in the documentation.

- [x] **Step 3: Commit**

`CLAUDE.md` is left out: git ignores it, and `git add CLAUDE.md` would fail.

```bash
git add docs/guide/README.md README.md
git commit -m "docs: document the worklog skill in the guide and the README" --trailer "Session: worklog" --trailer "Stage: task 8/9"
```

---

### Task 9: Release v7.52.0

**Files:**
- Modify: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md`
- Test: `tests/codex/test-version-files.js`, every fast suite

**Security flag:** `none`

**Does NOT cover:** installing the plugin or pushing; `tests/codex/post-push-validation-checklist.md` (it runs after a push, which this plan does not do, and Codex is no longer supported; no file under `hooks/codex/` changes, but the Codex adapter also reads `hooks/skill-rules.json`, which gains one rule in Task 6).

**Contract:**
- The version places (code and wording artifacts): `VERSION`, the `version` of `.claude-plugin/plugin.json` and of the first plugin in `.claude-plugin/marketplace.json`, the meta `version` of `plugin.universal.yaml`, the README badge, the two `v6.7.0–v7.52.0` ranges, the last `(vX.Y.Z)` item of the README release list, and the first `## v` heading of `RELEASE-NOTES.md` all state `7.52.0`.
  - Verification: `node tests/codex/test-version-files.js` passes.
- The `RELEASE-NOTES.md` entry (wording artifact)
  - Must convey: a three-line summary directly under `## v7.52.0 — ...` (Problem, Change, Effect), near 100 words and at most 120, each statement supported by the entry's prose, and "Nothing to migrate."; prose on why a new document is needed (the limits of `state.md`, `session-log.md` and `known-issues.md`) and why the plugin must be reinstalled, what a work log is, the three commands, the session-start notice with its size bound, the `/pickup` change, the tests, and the accepted limits.
  - Verification: Step 2's word count prints a number at most 120; a reader finds each summary statement in the prose.
- The README release list item (wording artifact): one new last item `... (v7.52.0)` before ` — are covered in`. Verification: `node tests/codex/test-version-files.js`.

- [ ] **Step 1: Bump the version and write the entry**

Change `7.51.0` to `7.52.0` in: `VERSION` (the only line), `.claude-plugin/plugin.json` (`"version"`), `.claude-plugin/marketplace.json` (`"version"` of the first plugin), `plugin.universal.yaml` (`  version: "7.51.0"` under meta), the README badge (`badge/version-7.51.0-white`), and the two README ranges `v6.7.0–v7.51.0` (lines 22 and 24).

In the README release list line (it starts with `The remaining releases`), replace ` and an orchestration skill that runs on Claude Code only (v7.51.0) — are covered in` with:

```markdown
 an orchestration skill that runs on Claude Code only (v7.51.0), and a `worklog` skill that keeps one tracking document per piece of multi-part work, named by the session-start hook (v7.52.0) — are covered in
```

In `RELEASE-NOTES.md`, insert this entry directly before the line `## v7.51.0 — orchestration runs on Claude Code only; the usage-limit wait`:

```markdown
## v7.52.0 — the worklog skill: one tracking document per piece of multi-part work

**Problem.** Work with several parts that lasts many sessions had no document
for its progress. `state.md` is a snapshot that every save rewrites,
`session-log.md` has no table of parts and no list of open items, and
`known-issues.md` maps errors to fixes.

**Change.** A new skill, `worklog`, creates, fully updates and closes
`docs/worklogs/<slug>.md`, a document that carries its own update rules. The
session-start hook names the active work logs in one notice of at most 457
characters plus the length of the root path, and `/pickup` no longer counts
an uncommitted work log as unfinished work.

**Effect.** Type `/worklog new` to start a work log. Reinstall the plugin.
Nothing to migrate.

### Why a new document

The plugin already writes three memory files, and none of them can hold the
progress of multi-part work. `state.md` is one file per project, under 100
lines, and every save-state rewrites it: it is a snapshot of one moment, not a
history. `session-log.md` holds the decisions of each session in time order;
it has no table of parts and no list of open items. `known-issues.md` maps a
recurring error to its solution; it does not track work.

The new skill, the hook change and the `/pickup` change ship inside the
plugin, so a session uses them only after the plugin is reinstalled.

### What a work log is

A work log is one Markdown file per piece of multi-part work, for example
four groups of tests that are refactored one group after the other. It lives
at `docs/worklogs/<slug>.md` under the repository root, and git tracks it. The
slug is its short name: lowercase letters, digits and single hyphens, at most
40 characters, and not one of the command words `new`, `update` and `close`.
Line 1 is a status line written as an HTML comment, which a Markdown viewer
does not show: `<!-- Work log: status=active slug=<slug> created=<YYYY-MM-DD> -->`.
It stands on line 1 because a Markdown formatter can insert an empty line
under a heading, so a status line under the heading would move.

The document has a table of parts, a list of open items with a
`Next item number` line, a list of accepted limits, and a list of decisions
whose entries are never rewritten. An admission rule decides which problem
becomes an open item. The model is `docs/orchestration-issues.md`: measured
on 2026-09-21, 0 of its rows 41 to 92 came from a real case, because reviews
filled the worklist before it had an admission rule. The section
`How to maintain this document` holds seven update rules, so a session that
reads the file can maintain it even where the plugin is not installed. The
skill never commits.

### The three commands

- `/worklog new [<slug>]` asks for the title, the goal, the "done when"
  condition, the parts and the admission rule in one question batch, fills
  `skills/worklog/template.md`, and writes the file. It never overwrites a
  work log.
- `/worklog` or `/worklog update [<slug>]` compares the document with the
  session and with the commits since its creation date
  (`git log -n 200 --since="<created> 00:00"`, at most five windows of 200
  commits), and applies the document's own rules.
- `/worklog close [<slug>]` asks first when a part is unfinished or an open
  item remains, fills the last `Commit` cells, and changes line 1 to the
  closed form.

The skill tests line 1 with a fixed shell command, not by reading it, because
the Read tool shows neither a carriage return nor a symbolic link. It changes
line 1 with a second command that keeps a carriage return and a byte order
mark. The model can load the skill by itself (the skill has no
`disable-model-invocation` key), and `hooks/skill-rules.json` routes "create
a work log" and "update the work log" to it.

### The session-start notice

`hooks/session-start` runs the list command of the skill, copied unchanged,
and names at most three active work logs in one `<active-work-logs>` notice,
with the root as an absolute path. The notice is appended to the notices,
which are always included; the content of a work log is never injected. The
list command reads line 1 only, prints a file only when its name is a valid
slug plus `.md` (a file name is text that anyone who can add a file
controls), and is safe under the hook's `set -euo pipefail`. The fixed text
of the notice has 248 characters; with three 40-character slugs and the text
for further work logs, the notice has at most 457 characters plus the length
of the root. A root longer than 300 characters is cut to its last 300.

### `/pickup`

`skills/pickup/scripts/pickup-scan.js` adds `docs/worklogs` to the paths that
its uncommitted-change check leaves out. A commit made after the handoff
still gives `CHECK`, also when it touches only `docs/worklogs/`.

### Tests

A new fast suite, `tests/worklog/run-tests.sh`, checks the template, copies
the slug, list, check and line-1 commands out of the skill text and runs them
on fixture folders (in `bash`, and in `zsh` when it is installed), checks the
pinned phrases of the skill, and checks that the hook holds the list command
unchanged. `tests/codex/test-session-start-worklog-notice.sh` checks the
exact notice on fixture projects, and `tests/codex/test-session-start-budget.sh`
keeps the output at or under 10,000 characters with three 40-character work
logs. `tests/pickup/run-tests.sh` and `tests/codex/test-skill-activator.js`
gain cases, and `tests/skill-triggering` gains a `worklog` prompt.

### Accepted limits

- The model can forget the update rules in a long session or after a
  compaction; `/worklog` forces a full update.
- An orchestrated run and a whole-branch review stop on an uncommitted file
  that they do not know. The template and the notice ask for a commit before
  such a run and forbid writes while it runs.
- On Windows, if a `find` that is not the Git Bash program runs, the list is
  empty and the hook continues without a notice (not tested there).
- That a formatter moves a status line below a heading is taken from the
  tools' documented rules, not replayed.
```

- [ ] **Step 2: Verify the release**

Run: `node tests/codex/test-version-files.js`
Expected: PASS — exit 0, every version place states 7.52.0.

Run: `awk '/^## v7.52.0/ { f = 1; next } f && /^### / { exit } f' RELEASE-NOTES.md | wc -w`
Expected: a number at most 120 (the whole summary, the three bold labels included; `wc -w` counts each label as one word).

Run: `for s in tests/codex/run-unit-tests.sh tests/smart-compress/run-tests.sh tests/reviewer-templates/run-tests.sh tests/writing-plans/run-tests.sh tests/in-run-rulings/run-tests.sh tests/fill-prompt/run-tests.sh tests/orchestrating-development/run-tests.sh tests/review-gates/run-tests.sh tests/measure-context/run-tests.sh tests/pickup/run-tests.sh tests/analyze-compaction/run-tests.sh tests/sdd-scripts/run-tests.sh tests/suite-guard/run-tests.sh tests/worklog/run-tests.sh; do log=$(mktemp); bash "$s" > "$log" 2>&1 && echo "PASS $s" || { echo "FAIL $s"; tail -20 "$log"; }; rm -f "$log"; done`
Expected: `PASS` for all 14 suites.

- [ ] **Step 3: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): v7.52.0" --trailer "Session: worklog" --trailer "Stage: task 9/9"
```
