# Review log: worklog-design.md

_Invocation 1 — 2026-09-21 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 6 Minor | r2: 0 Critical, 5 Important, 6 Minor | r3: 0 Critical, 6 Important, 6 Minor
**Sources mapped:** 33/33
**Reviewer verdict:** 0 Critical, 10 Important, 9 Minor
**Converged:** no

### Dispositions
- [I1] applied — Template, Open items: "item numbers are never reused" could not be followed, the document stored no counter → line `Next item number: <n>` under the table; rule 3 uses and increases it; added to the contracts table and the tests ← 3/3: r1:I1, r2:I2, r3:I2
- [I2] applied — Commands, Error handling: `update` and `close` had no rule for a missing file, a closed work log, no slug at `close`, an invalid slug, reopening → one shared "Choosing a work log" rule; slug validated in every command; closed work log stops both commands; reopening is a non-goal, done by hand ← 3/3: r1:I4, r2:I4, r3:I5
- [I3] applied — Location, status line, Discovery: paths were relative to the repository root but the command used a relative path → "Root" defined; the list command builds its path from the root; the pointer path is relative to the root; sub-folder case added to the tests ← 3/3: r1:M3, r2:I3, r3:M1
- [I4] applied — Template rules: an open item could leave the table only through a committed fix → rule 4 covers no-git projects, a user decision not to fix, and a wrong or duplicate item ← 3/3: r1:I2, r2:M2, r3:M5
- [I5] applied — Template rules: no rule for a part added, split or dropped → rule 2; status `dropped`; the close check accepts `done` or `dropped` ← 2/3: r1:I3, r3:M4
- [I6] applied — Commands new/close: "run the save-state step" was ambiguous and had side effects → the commands replace only the `Active work log:` lines of an existing `state.md`; no `[saved]` entry, no marker move; with no `state.md` they write nothing and say so ← 2/3: r2:I5, r3:I3
- [I7] applied — Discovery: `subagent-driven-development` Batch End also rewrites `state.md` (verified at SKILL.md:328) → "the pointer rule" defined once; the Batch End handoff names it; scope, contracts and tests updated; the claim "cannot lose a pointer" removed ← 1/3: r2:I1
- [I8] applied — Template Parts legend: the `Commit` cell cannot hold the hash of the commit that contains it → rule 1 and full update step 3 fill an empty cell later; the legend says it reaches git one commit later ← 1/3: r3:I1
- [I9] applied — Discovery, branches: a save-state on a branch without the file dropped the pointer without a message → pointer rule step 2 keeps the line with "(not present on this branch)"; template advice on the branch; new failure mode ← 1/3: r3:I4
- [I10] applied — close, "close anyway": unfinished parts left no record → one `## Decisions` entry records it; the open-item rows are deleted after they are copied ← 1/3: r3:I6
- [M1] applied — status line: the grep matched the prefix on any line → the list command reads line 2 only (find + awk, replayed by the controller on a fixture in bash and zsh); a template sentence forbids the prefix elsewhere ← 3/3: r1:M2, r2:M4, r3:M2
- [M2] applied — full update step 3: the start of the `git log` range was undefined → newest `Since` date, else `created=` ← 3/3: r1:M5, r2:M3, r3:M3
- [M3] applied — Parts: a blocked part had no status → it keeps its status and `Note` names the item ← 1/3: r1:M1
- [M4] applied — new: an ignored `docs/worklogs` path was silent → `git check-ignore -q` step with a message ← 1/3: r1:M4
- [M5] applied — Failure modes: the sentence on the staleness check was wrong → corrected; a pointer line is valid also under "no active task" ← 1/3: r1:M6
- [M6] applied — Template rules: no rule for closing in a session without the plugin → rule 7 ← 1/3: r2:M1
- [M7] applied — Testing: a prompt file alone runs no test (verified: fixed `SKILLS` array in run-all.sh) → the array entry is named ← 1/3: r2:M5
- [M8] applied — a second git worktree → accepted limit under Failure modes, advice in the guide ← 1/3: r2:M6
- [M9] applied — slug field against file name → the file name is the authority; the full update reports and corrects the field ← 1/3: r3:M6

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 5 Important, 6 Minor | r2: 0 Critical, 5 Important, 7 Minor | r3: 0 Critical, 5 Important, 6 Minor
**Sources mapped:** 34/34
**Reviewer verdict:** 0 Critical, 7 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — Discovery: "at the end of the `Current Goal` section" had no single meaning (three forms of `Current Goal`), and the insert case of `new` was undefined → the pointers move to a section of their own, `## Work logs`, last in `state.md`; pointer rule step 4 defines create, replace and remove ← 3/3: r1:I2, r2:I1, r3:I1
- [I2] applied — status line: "malformed" was undefined → "Valid forms of line 2" with one regular expression per form; a slug mismatch is the only corrected case; the fixture line of the test is named; new test of the two forms ← 3/3: r1:I3, r2:I3, r3:M1
- [I3] applied — Error handling: "the highest number found in the document" was undefined → former items get the fixed form `item #<n>`; the rebuild reads the first column of `## Open items` and every `item #<n>`; the result is a lower bound that the user confirms ← 3/3: r1:I4, r2:I2, r3:I4
- [I4] applied — Commands: the argument grammar was incomplete → one grammar paragraph; `new` without a slug asks for it; an unknown first word stops with the usage text; the three command words are refused as slugs ← 3/3: r1:I5, r2:M3, r3:I5
- [I5] applied — full update step 3: no exact `git log` command → the command with `--since="<date> 00:00"`, local time, "when every `Since` cell is empty"; the bare-date behaviour was replayed by the controller (0 against 19 commits at 15:01) ← 3/3: r1:M3, r2:I4, r3:I3
- [I6] applied — Definitions: which `state.md` was meant → "Project directory" defined as the folder where the session started; `state.md` always means that file; the pointer line says "(path from the repository root)"; the "any folder" claim is limited to git repositories ← 2/3: r1:I1, r2:I5
- [I7] applied — Scope, Failure modes: "the two writers that exist today" was false, four skills write `state.md` (verified: writing-plans "Seed `state.md`", the batch handoff, orchestrating-development) → the other writers are not changed and are listed by name; a lost section repairs itself from the folder; this reverses the `subagent-driven-development` sentence that round 1 [I7] added, by that finding's own second option ← 1/3: r3:I2
- [M1] applied — claims about external tools without a source → zsh `NOMATCH`, POSIX `awk`, `git-check-ignore` exit codes cited; the controller's replay recorded; other `awk` versions labelled unverified; "never be committed" replaced ← 3/3: r1:M1, r2:M1, r3:M4
- [M2] applied — Non-goals: the limit had no citation and "four files" could not be checked → both hook files cited; the project, the date and the four files named; "placed last in that order" ← 3/3: r1:M2, r2:M2, r3:M5
- [M3] applied — Template: "the commit that finished the part" was undefined → the newest commit that holds changes of the part; ask the user when unknown ← 3/3: r1:M4, r2:M4, r3:M2
- [M4] applied — Contracts: open keyword list, patterns as prose, unstable pointer order → the complete keyword list and two regular expressions; `| sort` on the list command; the part of r3:M6 on the `subagent-driven-development` sentence no longer applies after [I7] ← 3/3: r1:M6, r2:M6, r3:M6
- [M5] applied — default admission rule: "can lose work" was vague → "its consequence is lost user work or a wrong commit" ← 2/3: r1:M5, r2:M5
- [M6] applied — Testing: wording checks had no pinned phrase → the phrases and the rule-count pattern are named ← 1/3: r2:M7
- [M7] applied — "list the existing slugs" → every slug with its status ← 1/3: r3:M3

## Round 3 — Feasibility & architecture risk — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 5 Important, 3 Minor | r3: 0 Critical, 2 Important, 3 Minor
**Sources mapped:** 17/17
**Reviewer verdict:** 0 Critical, 5 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — Discovery: the hook injects `state.md` only when the whole file fits in about 3,000 characters (this repository's file has 5,032, and it was not injected in the reviewing session), so the pointer was often invisible → user decision of 2026-09-21: the session-start hook adds one short notice to its always-included `notices` part; the pointer in `state.md` and every change to `context-management` leave the design; new section "Discovery through the session-start hook", with a file-name filter as a safety rule; new hook tests ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — skill contract and routing: the frontmatter was undefined (`handoff` and `pickup` carry `disable-model-invocation: true`, verified), the activator can list `brainstorming` first, one keyword could not reach the score threshold, the Routing Guide had no line → "Skill file contract" paragraph; keyword list reduced and a third intent pattern; the contract is "the list contains `worklog`"; one Routing Guide line; the plan replays the test prompts against `matchSkills` ← 2/3: r2:I5, r3:I2
- [I3] rejected: moot after [I1] — a pointer-only write changed the modification time of `state.md` that two hooks read; the design no longer writes `state.md`, and the fact is recorded as a reason in the non-goal "No pointer in `state.md`" ← 1/3: r2:I2
- [I4] applied — `new` step 3: `skills/worklog/template.md` exists only in this repository → `<skill-dir>/template.md`, with the convention of `skills/pickup/SKILL.md`; the pinned test phrase follows ← 1/3: r2:I3
- [I5] applied — Testing: `.gitignore` line 18 matches `prompts/worklog.txt` (verified with `git check-ignore -v`) and the suite skips a missing prompt without failing → `git add -f` and a `git ls-files` check are named ← 1/3: r2:I4
- [M1] applied — Rollout: the `handoff` search finds nothing in `plugin.universal.yaml` and misses the Routing Guide → the files are named directly; the two historical documents are stated as not updated; no hook wiring change ← 3/3: r1:M2, r2:M3, r3:M1
- [M2] applied — valid forms of line 2 against a checkout with CRLF line ends (outside the default `core.*` settings, named by both reviewers) → one trailing carriage return is ignored and kept; a CRLF fixture in the tests ← 2/3: r1:M1, r2:M2
- [M3] rejected: moot after [I1] — `context-management` says "project root" while the hook reads the working folder; `context-management` is no longer changed ← 1/3: r1:M3
- [M4] applied — Grammar: on Copilot CLI the argument may not arrive, and the fallback `update` would then write to a file that the user did not name → the skill first reads the command word and the slug from the invoking message ← 1/3: r2:M1
- [M5] rejected: moot after [I1] — "last section of `state.md`" could be displaced by other writers; the section no longer exists ← 1/3: r3:M2
- [M6] applied — `/pickup` scan: `NOT_WORK` covers only uncommitted changes → stated as accepted: a commit that touches only `docs/worklogs/` still gives `CHECK` ← 1/3: r3:M3

## Round 4 — Adversarial failure modes — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 2 Important, 3 Minor | r2: 0 Critical, 4 Important, 4 Minor | r3: 0 Critical, 3 Important, 4 Minor
**Sources mapped:** 21/21
**Reviewer verdict:** 1 Critical, 4 Important, 7 Minor
**Converged:** no

### Dispositions
- [C1] applied — hook notice, list command: `hooks/session-start` runs under `set -euo pipefail`; with `docs/worklogs` absent, `find` exits 1 and the hook would end before its output in almost every project (replayed by all three reviewers) → the list command is rewritten with a folder test and `|| true`, replayed by the controller as a script under `set -euo pipefail` in bash and zsh (absent folder: empty line, exit 0); the false sentence about the exit status is removed; the hook test pins the case ← 3/3: r1:C1, r2:I2, r3:I2
- [I1] applied — status line on line 2: a Markdown formatter inserts an empty line under the heading, and the work log then disappears without a message → the status line is an HTML comment on line 1; the list command reads line 1; valid forms, template, close wording and tests follow; a valid line in a wrong position gets its own message; fixture with the line on line 3 (replayed: not listed). The formatter behaviour itself is labelled unverified ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — full update step 3: the `git log` window started at the newest status change and hid the commits that the repair needs → the window starts at the oldest of: `Since` of `done` parts with an empty `Commit`, `Found` of open-item rows, the newest `Since`; else `created=` ← 3/3: r1:I2, r2:M1, r3:I3
- [I3] applied — an active work log is often uncommitted, and `orchestrating-development` and `multi-code-review` stop on an unknown dirty file → option (b): those skills are not changed; the template tells the session to ask the user for a commit before such a run; new accepted limit under Failure modes; the guide repeats it ← 1/3: r2:I3
- [I4] applied — keyword `work logs`: the activator matches a keyword with a space as a substring, so "network logs" scored 2 → the plural keyword is removed with the reason; two negative activator tests ← 1/3: r2:I4
- [M1] applied — the file-name filter is not the whole safety measure → failure mode: the content of a work log is trusted like the project's `CLAUDE.md` ← 2/3: r1:M1, r2:M3
- [M2] applied — two sessions or two branches can give one item number twice → rule 3: read the file again, use an unused number; renumber after a merge ← 2/3: r1:M2, r3:M3
- [M3] applied — a symbolic link is never listed while `update` found it → a work log must be a regular file; `update` and `close` say so; test fixture ← 2/3: r1:M3, r3:M4
- [M4] applied — a recorded hash disappears after a squash merge or a rebase → the template says the hash is valid on the work branch ← 1/3: r2:M2
- [M5] applied — a repository root far above the project → `new` shows the full target path and asks for confirmation when the root differs from the project directory ← 1/3: r2:M4
- [M6] applied — the pinned phrase `no [saved] entry` was left from the removed `state.md` design → removed from the tests ← 1/3: r3:M1
- [M7] applied — a file name with a line break gives a second output line → the hook keeps only lines that start with `$ROOT/docs/worklogs/` ← 1/3: r3:M2

**Host self-review (brainstorming Spec Self-Review), 2026-09-21:** placeholder scan: none. Consistency: one sentence in full update step 3 was damaged by a round 4 replacement (a leftover fragment of the older wording) → repaired; `new` step 3 joined two actions without a connecting word → "Then read"; stale wording search (`pointer`, `save-state`, `line 2`, `## Work logs`) finds only the non-goal that records the removed design. Scope: one implementation plan. Ambiguity: none found.

_Invocation 2 — 2026-09-21 — N=4 M=3 — gate: brainstorming_

## Round 5 — Correctness & completeness — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 2 Important, 3 Minor | r3: 0 Critical, 1 Important, 5 Minor
**Sources mapped:** 15/15
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — full update step 3: the window of round 4 still left out the `Since` date of an `in progress` part, so the commit of a forgotten status change was not read → the window always starts at the `created=` date, with `-n 200` and a message when 200 commits are printed ← 2/3: r1:I1, r2:M1
- [I2] applied — a file whose name breaks the slug rule: the hook filtered it, the skill's list command printed it, and the slug correction then wrote a malformed line 1 → the file-name filter moves into the list command, so both readers agree; such a file is never chosen; the slug listing marks it `invalid file name — rename it`; new Error handling entry ← 2/3: r2:I1, r3:M2
- [I3] applied — a former open item kept only `item #<n>: <reason>`, so the problem text was lost, most of all at "close anyway" → the form carries the item text; rule 4, `close` step 2 and the contract row follow ← 1/3: r2:I2
- [I4] applied — the hook's own filter step was not protected under `set -euo pipefail` (a `grep` that removes every line exits 1), and the planned test would pass on a hook that ended early → the hook runs the list command unchanged and adds no filter step (the filter is inside `awk`, replayed by the controller: a folder with only `A.md` gives an empty line and exit 0); the test asserts exit 0 and an identical output ← 1/3: r3:I1
- [M1] applied — no maximum slug length, so the notice size had no bound → 40 characters in the slug rule and in the filter; the notice is at most about 440 characters; test with a slug of 41 characters ← 3/3: r1:M3, r2:M2, r3:M1
- [M2] applied — `close` named only the "already closed" stop → the checks (symbolic link, malformed line 1, wrong position, slug mismatch) move into the shared rule "Choosing a work log"; both commands correct a slug mismatch ← 2/3: r1:M1, r2:M3
- [M3] applied — a load by the model with no command word was undefined → paragraph "A load by the model": no full update, read the named work log and follow its maintenance section ← 1/3: r1:M2
- [M4] applied — a command word given as a slug had two different messages → the usage text, in both places ← 1/3: r3:M3
- [M5] applied — `new`: `Since` of a part that starts as `in progress` or `done` was undefined → today's date, `Commit` empty ← 1/3: r3:M4
- [M6] applied — `--since` filters on the committer date while `%ad` printed the author date → `%cd` ← 1/3: r3:M5

## Round 6 — Ambiguity & testability — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 8 Minor | r2: 0 Critical, 3 Important, 8 Minor | r3: 0 Critical, 2 Important, 8 Minor
**Sources mapped:** 31/31
**Reviewer verdict:** 0 Critical, 5 Important, 11 Minor
**Converged:** no

### Dispositions
- [I1] applied — shared checks: the slug correction (a write) stood before the closed test ("write nothing") → an ordered list of five outcomes; a closed work log is never written, its mismatch is reported only; the repair of a missing heading runs in `update` only, after the checks ← 3/3: r1:I2, r2:M1, r3:I2
- [I2] applied — `Commit` cell: three different rules in four places → one rule everywhere: empty until the part is `done`, then filled once with the newest commit that holds changes of the part; a part already `done` at `new` gets its hash from the user or stays empty ← 3/3: r1:M3, r2:I2, r3:M1
- [I3] applied — an empty argument meant `update` for `/worklog` and "no command" for a load by the model, with no test between them → one pinned sentence: the fallback to `update` applies only when the user's own message contains the text `/worklog` ← 2/3: r1:I1, r2:I3
- [I4] applied — default admission rule named a "done when" condition of a part, which the template does not hold → "blocks a part from reaching the status `done`" ← 1/3: r2:I1
- [I5] applied — the line 1 checks had machine precision and no mechanism; the Read tool shows neither a carriage return nor a symbolic link → "The check command": an exact command in the skill text that prints one of five words, replayed by the controller in bash and zsh; the tests run it on fixtures ← 1/3: r3:I1
- [M1] applied — the notice: no method for the root prefix, the full stop with more than three paths, sizes not computed, "repository root" false without git → `${path#"$ROOT"/}`; exact texts for one path and for five paths; "Paths start at the project root"; computed maximum of 413 characters ← 3/3: r1:M5, r2:M5, r3:M5
- [M2] applied — "after a resume" was undefined → the three hook events are named; `claude --resume` is labelled unverified ← 3/3: r1:M6, r2:M2, r3:M4
- [M3] applied — external claims without a source → `%cd` cited, `--since` on the committer date labelled unverified; the Git for Windows default labelled unverified; the effect of `disable-model-invocation` labelled unverified; the subagent claim gets its two observations. The `harness: tested` observation of r3 on point (d) is accepted: it matches the claim ← 3/3: r1:M7, r2:M7, r3:M8
- [M4] applied — were `new`, `update`, `close` part of "the slug rule"? → yes, stated in Definitions; the list command refuses the three file names (replayed: `new.md` is not listed); "another slug" → "a slug" ← 2/3: r1:M1, r2:M3
- [M5] applied — the slug listing had undefined labels → regular `*.md` files only, four labels ← 2/3: r2:M4, r3:M7
- [M6] applied — "identical to the output of v7.51.0" named no baseline that a test can produce → the baseline is the same fixture with only a closed work log, plus exit 0 and no notice text; the hook test bullet is rewritten as a list ← 2/3: r2:M6, r3:M3
- [M7] applied — how the skill learns the project directory → the condition of `new` step 3 is "the root differs from the current working folder (`pwd`)" ← 2/3: r2:M8, r3:M6
- [M8] applied — the columns `Part` and `Found` were undefined → one sentence in the template ← 1/3: r1:M2
- [M9] applied — `sort` depends on the locale → `LC_ALL=C sort` (replayed: `a-b.md`, `a.md`, `ab.md`) ← 1/3: r1:M4
- [M10] applied — no listed test runs a command → the opening sentence of the Testing strategy says so as an accepted limit; five more pinned phrases ← 1/3: r1:M8
- [M11] applied — the repair of a missing heading: which command, which position → `update` only, after the ordered checks (the position rule of Error handling stays: its template position) ← 1/3: r3:M2

## Round 7 — Feasibility & architecture risk — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 4 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 12/12
**Reviewer verdict:** 0 Critical, 1 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — the notice gave paths from the root, but in a layout with the working folder below the root the model knows only its working folder → the hook puts one `../` before each path per folder level (`git rev-parse --show-prefix`, no pipeline); the last sentence of the notice is "Paths start at the working folder of this session."; sizes recomputed; a hook test starts the hook one level below the root ← 1/3: r3:I1
- [M1] applied — README: the three counts "30 skills" (lines 68, 220, 330) were not in the Rollout list → named, they become 31 ← 3/3: r1:M2, r2:M1, r3:M3
- [M2] applied — `tests/codex/run-unit-tests.sh` holds a fixed list of `run_test` lines → the new file is registered there, stated in the Testing strategy ← 2/3: r2:M2, r3:M2
- [M3] applied — `find` and `sort` are new in the hook, and Windows has programs of the same names → added to the unverified sentence with the result (no notice, the hook continues) and to the failure mode "The notice is absent"; the one-command-two-readers form is kept ← 2/3: r2:M3, r3:M4
- [M4] applied — `matchSkills` returns at most 3 skills and a rule at the end loses every tie; the keyword `tracking document` alone could never reach the threshold → the cap is stated, the `worklog` rule is placed before `brainstorming`, `refactoring` and `writing-plans`, the keyword is removed ← 1/3: r1:M1
- [M5] applied — on Windows Git Bash `ln -s` makes a copy, so the two symbolic-link assertions would fail → they run only when `[ -L ]` is true, else a printed note ← 1/3: r1:M3
- [M6] rejected: harness probe not runnable here — in an interactive Claude Code session with the plugin installed, type `/superpowers-orchestrator:pickup` (an existing skill) and ask the model to quote the exact command-name text it sees in its context — (would break a constraint) — the namespaced form `/superpowers-orchestrator:worklog` may not contain the text `/worklog`, so the default `update` would not run ← 1/3: r1:M4
- [M7] applied — comparing the root with `pwd` as text is not reliable on Windows Git Bash and on macOS → `new` step 3 and the hook use `git rev-parse --show-prefix` ← 1/3: r3:M1

## Round 8 — Adversarial failure modes — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 3 Minor | r2: 0 Critical, 2 Important, 4 Minor | r3: 0 Critical, 2 Important, 5 Minor
**Sources mapped:** 18/18
**Reviewer verdict:** 0 Critical, 3 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — an orchestrator is a main session, gets the hook notice (also after each compaction), follows "update without being asked", and the dirty work log then stops Phase 5, the resume check and the `multi-code-review` precondition in the middle of a run → the template and the notice both say that the work log is not written while an orchestrated run or a whole-branch review is in progress; the failure mode is rewritten; pinned phrase; the three skills stay unchanged ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — the third intent pattern had no word boundary and scores 2 alone: it matched "keep track of the worker threads", and with the early rule position a false hit pushed `brainstorming` out of the list of 3 → the pattern is removed; `\b` after `logs?` in the two others; four negative activator prompts and one eviction assertion ← 2/3: r1:I2, r2:M4
- [I3] applied — the test "the message contains `/worklog`" also fired on a message that only mentions the command ("what does /worklog close do?"), and it may miss the namespaced form → the test is "the user's own message starts with the command, written `/worklog` or `/superpowers-orchestrator:worklog`"; a load by the model says in one line that it runs no command. The harness premise (which command text the model sees) was not probed: rejected: harness probe not runnable here — in a session with the plugin installed, type `/superpowers-orchestrator:pickup` and read the user record of the transcript: observe whether the recorded command text contains the short form `/pickup` or only the namespaced form — (would break a constraint); the new sentence is correct under both outcomes, and this also settles round 7 [M6] ← 2/3: r2:I2, r3:I2
- [M1] applied — a byte order mark on line 1 made the file leave the list without a message → the list command and the check command remove it for the comparison; replayed by the controller: macOS `awk` matches the byte pattern only under `LC_ALL=C`, which now stands before `find` ← 3/3: r1:M3, r2:M2, r3:M1
- [M2] applied — `-n 200` keeps the newest commits and cuts the oldest, against the stated reason → up to five windows with `--skip=200` while a question is open; the reason for the cap is stated ← 2/3: r1:M1, r3:M5
- [M3] applied — without git the root is `pwd` of the call, so a moved shell wrote a second work log in a sub-folder → `new` always shows the full target path and asks when there is no git repository; `missing` prints the folder that was searched ← 2/3: r1:M2, r3:M3
- [M4] applied — one unreadable file made `awk` stop and hid every later work log (replayed by the reviewer) → `-exec awk … {} \;`, one `awk` per file; replayed by the controller: the files after an unreadable one are printed ← 1/3: r2:M1
- [M5] applied — relative paths in the notice depend on a working folder that can move (the controller's own primary working directory changed after a `cd` in this session) → the notice names the absolute root once and paths from it; the `../` rule of round 7 [I1] is replaced; sizes recomputed (at most 457 characters plus the root) ← 1/3: r2:M3
- [M6] applied — the folder `docs/worklogs` as a symbolic link: the list command prints nothing while the check command reads through it → accepted limit under Failure modes; the guide says the folder must be a real folder ← 1/3: r3:M2
- [M7] applied — the `Commit` cell of the last part stayed empty for ever, because a closed work log is never written → `close` first fills the cells it can and reports the rest ← 1/3: r3:M4

**Host self-review (brainstorming Spec Self-Review), 2026-09-21, second pass:** placeholder scan: none. Consistency: the Error handling bullet "Not a git repository … Everything else works" contradicted round 8 [M3] → rewritten; the search for stale figures (390, 413, 425, 431), for `line 2`, for the removed keyword and the removed third pattern, and for the old notice wording finds only the sentences that record the removal. Scope: one implementation plan. Ambiguity: none found.
