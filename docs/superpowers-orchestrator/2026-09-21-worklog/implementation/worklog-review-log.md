# Code review log — worklog

carried findings: 22 `Minor:` lines read from `.superpowers/sdd/progress.md`

_Invocation 1 — 2026-09-21 — N=4 M=3 — BASE..HEAD e06a224..1c04872 — branch feature/worklog — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 3/3
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** no
### Dispositions
- [M1] fixed — the line-1 command's two redirections are now `>|`, so it also writes when the shell option noclobber is set; a noclobber case was added to the suite → 917ba3c ← 1/3: r1:M1
- [M2] fixed — the skill now says to stop, show the output and write nothing more when the line-1 command prints anything; update check 5 and close step 4 follow that rule → 917ba3c ← 1/3: r2:M1
- [M3] fixed — ordered check 3 now names only a printed line, other than line 1, whose text after the line number starts with the status prefix; the check command is unchanged → 917ba3c ← 1/3: r3:M1
- [L1] fixed — suite cases (d) read-only work log, copy kept and its path printed last, and (e) unreadable work log, copy removed, work log unchanged → 917ba3c
- [L2] fixed — the prose now says a failed rewrite prints the copy's path on its last line → 917ba3c
- [L3] fixed — every failure branch of the line-1 command ends with `false`; the suite asserts the exit status of each branch → 917ba3c
- [L4] fixed — `closed_line` and `line1_through_link` helpers replace the repeated closed-line printf and the shared four-step fixture → 917ba3c
- [L5] carried — the check command's malformed branch prints file lines into the model's context; the block is byte-identical to the spec (Global Constraint 4)
- [L6] carried — the list command prints contributor-controlled file names; the [a-z0-9-] filter with at most 40 characters is adequate
- [L7] carried — the listing's `find` has no folder test and no sort; the stop writes nothing
- [L8] fixed — the section-7 grammar pin is now the whole `Grammar:` line → 917ba3c
- [L9] carried — the front-matter check also accepts `name: worklog-x`
- [L10] fixed — the check-ignore step gives the ready-to-copy `git -C "$(git rev-parse --show-toplevel)" check-ignore -q` form → 917ba3c
- [L11] carried — the `missing` stop rule is written twice; both copies agree
- [L12] user-decision — close writes under Accepted limits and Decisions but has no instruction for a heading the user deleted; repairs run in update only (two reviewers recommend user-decision) — at skills/worklog/SKILL.md:307 — clause: Task 3 "The repair of a missing heading or `Next item number` line runs in `update` only; `close` does not repair."
- [L13] fixed — the hook comment names the printf note of the Output section instead of stale line numbers and spells out IFS → 917ba3c
- [L14] carried — under the C locale the 300-character cut of the root counts bytes; worst case one replacement character
- [L15] fixed — the hook defines `worklog_paths_max=3` and `worklog_root_max=300` once; output byte-identical on the fixtures → 917ba3c
- [L16] carried — notice test case 3 covers few bad names and no run outside a git repository
- [L17] carried — under set -e a failing JSON.parse stops the notice test with no FAIL line; exit status still non-zero
- [L18] user-decision — a symbolic-linked `docs` folder is followed by find, so the notice can name a file outside the clone; the spec's accepted limit names only a symbolic-linked docs/worklogs (two reviewers recommend user-decision) — at skills/worklog/SKILL.md:112 — clause: Global Constraints "[Discovery through the session-start hook] 'Run the list command, unchanged: with its folder test, its `|| true` and its file-name filter."
- [L19] carried — a huge first line is read whole by awk, and one awk runs per file; fixable only inside binding lines (Global Constraints 4 and 11)
- [L20] carried — the notices sit outside the workspace budget; pack() subtracts the head, so the limit holds
- [L21] carried — a newline or closing tag in the user's own folder name breaks the notice text
- [L22] carried — redundant comment in tests/pickup/run-tests.sh case 6c

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 1 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 1 Important, 2 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the bare `/worklog` test now also counts a user message holding a `<command-name>` tag that names `/worklog` or `/superpowers-orchestrator:worklog`, the form in which Claude Code delivers a typed slash command; the pinned sentence is kept and the tag form is pinned in suite section 7 → 54850ef ← 2/3: r2:M1, r3:I1
- [M1] carried — the binding intent patterns of Global Constraint 12 (`work\s?logs?`) also fire on application-domain prompts such as a Jira or Tempo "worklog"; changing them contradicts Global Constraint 12, and the consequence is one routing suggestion ← 2/3: r1:M1, r3:M1
- [M2] fixed — more than one word after the command word now stops with the usage text and writes nothing → 54850ef ← 1/3: r2:M2

## Round 3 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** no
### Dispositions
- [M1] fixed — the listing's names now come from a fixed listing command that tests each name in awk like the list command (folder test, C-locale sort, `|| true`) and prints an invalid name with unsafe characters replaced by `?`; the check command runs only on slugs it printed; suite section 3b runs it on a hostile file name → 325a266 ← 3/3: r1:M1, r2:M1, r3:M1
- [M2] carried — the notice tells the model to follow a repository-supplied work log section from inside the session-start block; the spec accepts work-log content at the trust level of the project's CLAUDE.md, and the notice text is fixed by Global Constraint 11 ← 1/3: r1:M2
- [M3] carried — the check command, the line-1 command and `new` follow a symbolic-linked `docs` or `docs/worklogs` folder, so a crafted repository can direct a write outside the clone; the check command is fixed by Global Constraint 4, and the linked-folder question is open as the round 1 [L18] user-decision ← 1/3: r2:M2

## Round 4 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 6 Minor | r2: 0 Critical, 0 Important, 7 Minor | r3: 0 Critical, 0 Important, 5 Minor
**Sources mapped:** 19/19
**Reviewer verdict:** 0 Critical, 1 Important, 11 Minor
**Converged:** no
### Dispositions
- [I1] fixed — an unreadable `docs/worklogs` folder fixture now runs the `|| true` of the list command, the listing command and the hook, each assertion red without it; the comments that claimed the no-folder fixture tested it are corrected → ce6b7e1 ← 1/3: r1:I1
- [M1] fixed — five rules added by review fixes are now pinned in suite section 7, each on one line of SKILL.md → ce6b7e1 ← 3/3: r1:M4, r2:M7, r3:M3
- [M2] fixed — notice-test case 7 asserts the exact notice with three active work logs (no "more" text) and with four (" and 1 more") → ce6b7e1 ← 2/3: r1:M2, r2:M1
- [M3] fixed — a folder without git holds an active work log; the list and check commands and the `missing (searched …)` path are asserted there → ce6b7e1 ← 2/3: r1:M5, r3:M5
- [M4] fixed — the noclobber run and line-1 cases (b), (d), (e) run under zsh too, and the zsh success run checks its output and exit status → ce6b7e1 ← 2/3: r1:M6, r2:M5
- [M5] fixed — notice-test cases for a root holding a space and a glob character and for a root of exactly 300 characters → ce6b7e1 ← 2/3: r2:M2, r3:M1
- [M6] fixed — the listing command also runs on the section-3 fixture folder, with exact output and labels → ce6b7e1 ← 2/3: r2:M4, r3:M2
- [M7] carried — budget case 8 cannot fail for the reason its comment gives and does not build the worst notice; plan-given case ← 1/3: r1:M1
- [M8] carried — no activator prompt returns more than two matches, so the rule position of Global Constraint 12 is checked only by the plan's one-time command ← 1/3: r1:M3
- [M9] carried — on macOS the C-locale sort checks cannot fail when `LC_ALL=C` is removed, because the fixture names sort the same in the ambient locales ← 1/3: r2:M3
- [M10] fixed — line-1 case (e) asserts that the failed command prints something → ce6b7e1 ← 1/3: r2:M6
- [M11] fixed — pickup case 6c also covers an untracked `docs/worklogs/` folder (dirty 0, FRESH) and a later commit under it (CHECK) → ce6b7e1 ← 1/3: r3:M4

## Round 4 verification 1 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 0 Important, 6 Minor
**Sources mapped:** 12/12
**Reviewer verdict:** 0 Critical, 0 Important, 7 Minor
### Dispositions
- [M1] fixed — the refused line-1 forms, trailing text after `-->` and an uppercase `slug=` now run through the check command in section 5, each asserted `malformed` → 226329e ← 3/3: r1:M1, r2:M1, r3:M1
- [M2] fixed — an activator test asserts that the `worklog` rule stands before `brainstorming`, `refactoring` and `writing-plans` in hooks/skill-rules.json → 226329e ← 2/3: r1:M2, r2:M2
- [M3] fixed — pickup case 6c adds a project with no `docs/` folder before the first work log (dirty 0, FRESH) and a corrected comment → 226329e ← 2/3: r1:M3, r3:M2
- [M4] fixed — budget case 8 keeps the plan's fixture, asserts the three names and the closing tag, and its comment no longer claims the longest notice → 226329e ← 2/3: r2:M3, r3:M5
- [M5] fixed — the mktemp stand-in records its argument count and the suite asserts the line-1 command calls it with no argument → 226329e ← 1/3: r3:M3
- [M6] fixed — the usage-text pin is now a phrase unique to the unknown-first-word rule → 226329e ← 1/3: r3:M4
- [M7] fixed — the notice test's case-1 header now says only the absent folder skips find → 226329e ← 1/3: r3:M6

## Round 4 verification 2 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 4 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 0 Important, 6 Minor
### Dispositions
- [M1] carried — budget case 8 never measures the largest notice (a root over 300 characters with the " and <n> more" text); the plan's Task 4 Contract fixes that case's fixture, so the worst case needs a new case ← 2/3: r2:M3, r3:M1
- [M2] fixed — the private mktemp stand-in passes its arguments to the real mktemp and logs the path; the suite asserts the copy is outside docs/worklogs and removed after success, and that case (d) keeps it outside the folder; the argument-count check is dropped → d030fec ← 1/3: r1:M1
- [M3] fixed — the comment above the two first-use fixtures of pickup case 6c now states git's output for each state correctly → d030fec ← 1/3: r2:M1
- [M4] carried — the activator test "a feature request that mentions keeping track still suggests brainstorming" never matches the worklog rule, so it guards no worklog behaviour ← 1/3: r2:M2
- [M5] carried — no fixture puts a file in a sub-folder of docs/worklogs, so removing `-maxdepth 1` from the list, listing and hook copies passes every suite ← 1/3: r2:M4
- [M6] carried — the check, line-1 and listing commands never run on a root that holds a space; only the hook's copy is tested with one ← 1/3: r3:M2

## Round 4 verification 3 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 1 Important, 2 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 1 Important, 5 Minor
### Dispositions
- [I1] user-decision — budget case 8 cannot fail for any notice the design allows: the plan-mandated oversized fixture of case 5 leaves about 898 characters of room against a largest notice of about 760, so no test checks that the notices part is counted in the budget; a separate near-limit case would not contradict the Contract; three earlier reviewers graded the same gap Minor (round 4 [M7], verification 2 [M1]) (plan-mandated) — at tests/codex/test-session-start-budget.sh:312 — clause: Task 4 "`tests/codex/test-session-start-budget.sh` case 8 (code artifact): with three active 40-character work logs and the oversized workspace files of case 5," ← 1/3: r2:I1
- [M1] carried — the C-locale sort checks cannot fail on macOS or in a C-locale runner when `LC_ALL=C` is removed from the list, listing or hook copy ← 2/3: r1:M1, r2:M1
- [M2] carried — the suite's zsh runs read the user's `~/.zshenv`, which can put another mktemp before the stand-in or print text, giving a false failure ← 1/3: r1:M2
- [M3] carried — no fixture uses `update.md` or `close.md`, or a file in a sub-folder of docs/worklogs, so the command-word tests and `-maxdepth 1` of the filter copies are untested ← 1/3: r2:M2
- [M4] carried — the root cut is tested at 300 and about 460 characters only, so the threshold could move up to about 460 without a failing test ← 1/3: r3:M1
- [M5] carried — the line-1 tests still assert that mktemp is called exactly once, a property the skill does not state ← 1/3: r3:M2

_Completed — 2026-09-21 — cap reached — HEAD d030fec3e793f1e32f2a82f18fd6e97b6d34e54c_
Secrets found: none

### Post-loop addendum 1 — 2026-09-21
Verification re-review skipped: the effective HEAD had moved past the completion marker (29d0eb6, the plan amendment of ruling 3), so invocation 2 reviews the fix.
- [L12] decided (orchestrator): fix it: before `close` writes anything, it checks that every section heading it reads or writes (`## Parts`, `## Open items`, `## Accepted limits`, `## Decisions`) stands; when one is missing, `close` stops, names the missing heading and tells the user to run `/worklog update`, which repairs it; `close` itself never adds a heading or the `Next item number` line
- [L12] fixed — before it writes anything, `close` checks that `## Parts`, `## Open items`, `## Accepted limits` and `## Decisions` stand, and otherwise stops, names the missing heading and tells the user to run `/worklog update`; the repair stays in `update`; the sentence is pinned in suite section 7 → bf83855
- [L18] decided (orchestrator): plan governs: "[Discovery through the session-start hook] 'Run the list command, unchanged: with its folder test, its `|| true` and its file-name filter." — docs/superpowers-orchestrator/2026-09-21-worklog/plans/worklog.md
- [I1] decided (orchestrator): amend plan: Task 4's Contract bullet for `tests/codex/test-session-start-budget.sh` case 8 also requires a case 9 — the three 40-character work logs of case 8 with workspace files sized so that the room they leave is smaller than the notice; `assert_common` passes and the whole notice is present; case 9 fails when the budget leaves the notice out of its count (Amendment 3 in the plan); fix it: (this answers the round 4 verification 3 user-decision item on budget case 8) add case 9 to `tests/codex/test-session-start-budget.sh` as the amended Contract states, and show once that it fails on a copy of the hook whose budget does not count the notice
- [I1] fixed — budget case 9 uses the three 40-character work logs of case 8 and a state.md sized from a live run so that the room it leaves is smaller than the notice; it asserts `assert_common`, the whole notice and state.md skipped; it failed 3 checks on a copy of the assembler whose budget leaves the notices part out, and passes on the branch → bf83855

_Invocation 2 — 2026-09-21 — N=4 M=3 — BASE..HEAD e06a224..bf83855 — branch feature/worklog — gate: orchestration_
carried findings: none passed — the ledger's 22 `Minor:` lines were triaged in round 1 (invocation 1); round numbering continues, so this invocation has no round 1

## Round 5 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** no
### Dispositions
- [M1] fixed — ordered check 5 now says to read line 1 only to take its `slug=` and `created=` values and to build the corrected line from them and the file-name slug; the check command's word stays the only judge of validity → a18f595 ← 2/3: r1:M1, r2:M1
- [M2] fixed — the README mermaid diagram now says "28 skill rules", matching the rule count of hooks/skill-rules.json → a18f595 ← 1/3: r3:M1
- [M3] fixed — the release notes' 457-character figure now names the printed root and the condition "with fewer than 1,000 further work logs", in the summary and in the prose → a18f595 ← 1/3: r3:M2

## Round 6 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 1 Minor | r2: 0 Critical, 0 Important, 0 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — the two `worklog` intent patterns also match the Jira and Tempo term worklog in coding requests; replayed with matchSkills, 'update the worklog of issue PROJ-12 through the Jira REST API' suggests worklog alone, so no brainstorming hint is offered; the fix changes the patterns that Global Constraint 12 fixes; [M2] of this round removes the skill-side consequence (a plain-words request about another product's worklog runs no command); invocation 1 round 2 [M1] carried the same overlap as Minor (plan-mandated) — at hooks/skill-rules.json:43 — clause: Global Constraints "[Interfaces and contracts] The `hooks/skill-rules.json` entry is: '`skill`: `worklog`; `type`: `workflow`; `priority`: `high`.'" ← 1/3: r1:I1
- [M1] fixed — check 5 no longer offers `head -n 1`, which a rule of the plugin's Bash safety hook blocks for a slug holding the word secret or credentials; line 1 is read with the Read tool, limit 1 → 0b7b969 ← 1/3: r1:M1
- [M2] fixed — the load-by-the-model branch runs a plain-words command only when the request is about this plugin's work log under docs/worklogs/; a request about another product's worklog (a Jira or Tempo time entry) gets one line saying the skill does not apply, and the request continues → 0b7b969 ← 1/3: r3:M1
- [M3] carried — the rule that the work log goes into the next commit the user requests names no branch, so after a branch switch before the first commit it can be staged into a commit on another branch; the sentence is template text, which Global Constraint 8 makes normative, and the trigger needs a switch before the work log's first commit ← 1/3: r3:M2

## Round 7 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor
**Converged:** no
### Dispositions
- [M1] carried — the session-start notice tells the model to follow the section "How to maintain this document" of any active work log, with no limit on what that repository-written section may ask for, while the file name is filtered as untrusted; the notice text is fixed by Global Constraint 11 and the template is normative (Global Constraint 8); the spec accepts work-log content at the trust level of the project's CLAUDE.md, and the trigger is a hostile contributor (same as invocation 1 round 3 [M2]) ← 3/3: r1:M2, r2:M1, r3:M1
- [M2] carried — when `docs` or `docs/worklogs` is a committed symbolic link, the check command prints `missing` or `active` instead of `symlink`, so `new` creates a file in the link's target and `update`, `close` and the line-1 command write there; the check command, which gates every command, is fixed byte for byte by Global Constraint 4; the state needs a hostile committed link (same as invocation 1 round 3 [M3]) — harness probe: the Write tool returned success for <A>/docs/worklogs/x.md with docs/worklogs linked to folder B, and x.md appeared in B ← 2/3: r1:M1, r2:M2

## Round 8 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 4 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 0 Important, 6 Minor
**Converged:** yes
### Dispositions
- [M1] carried — budget case 9 prints `notice_size` but does not assert its own precondition, that the text state.md adds beyond the room is smaller than the notice; measured margin about 223 characters today, so a later shorter notice or longer wrapper could make it pass on a broken budget; the case failed 3 checks on such a broken copy when it was added ← 2/3: r1:M1, r3:M4
- [M2] carried — the positive routing tests pin only 'update the work log' and 'create a work log'; the one-word form worklog, the verbs start, open, new, close and continue and the article my are routed today but pinned by no test ← 2/3: r1:M2, r2:M2
- [M3] carried — the zsh runs of the line-1 suite read the user's `~/.zshenv` (and bash reads `$BASH_ENV`), which can put another mktemp before the stand-in and give a false failure (same as invocation 1 round 4 verification 3 [M2]) ← 1/3: r2:M1
- [M4] carried — the check of exactly seven numbered rules in the template's maintenance section counts only lines numbered 1 to 7, so an eighth rule passes; the pattern is the Task 1 contract's ← 1/3: r3:M1
- [M5] carried — no fixture runs the `update.md` and `close.md` exclusions of the list and listing commands or of the hook's copy; only `new.md` is tested (same gap as invocation 1 round 4 verification 3 [M3]) ← 1/3: r3:M2
- [M6] carried — no negative routing prompt tests the final word boundary of the first intent pattern, for example 'create a work logging service' ← 1/3: r3:M3

_Completed — 2026-09-21 — converged — HEAD 0b7b9694613e7b4b58f2175ddcd55a1a2f19b53d_
Secrets found: none

### Post-loop addendum 1 — 2026-09-21
Effective HEAD unchanged (0b7b969, the completion marker's HEAD): the decision needs no code change, so no fix runs, no new invocation starts and the completion marker stands.
- [I1] decided (orchestrator): plan governs: "[Interfaces and contracts] The `hooks/skill-rules.json` entry is: '`skill`: `worklog`; `type`: `workflow`; `priority`: `high`.'" — docs/superpowers-orchestrator/2026-09-21-worklog/plans/worklog.md
