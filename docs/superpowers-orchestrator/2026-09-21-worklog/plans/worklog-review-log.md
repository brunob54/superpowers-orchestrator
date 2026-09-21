# Review log — worklog.md

_Invocation 1 — 2026-09-21 — N=4 M=3 — gate: orchestration — plan-blob 40f703f4ba165dd92b22e314548389c4d5af0665_

## Readiness pre 1 — Execution readiness — claude-opus-5[1m]
**Result:** open
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 1 Minor, ids renumbered, counts recomputed | r2: 1 Critical, 0 Important, 3 Minor | r3: 0 Critical, 1 Important, 1 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 1 Critical, 2 Important, 2 Minor

### Dispositions
- [C1] rejected: undecidable at this gate — spec inconsistent — GC4 and Task 2 Step 3: the list command that GC4 requires "used unchanged" holds `l = $0`, and GC7 makes the skill take arguments; Claude Code replaces `$0` in a skill body with the first argument (verified in https://code.claude.com/docs/en/skills, "Available string substitutions": "`$N` — Shorthand for `$ARGUMENTS[N]`, such as `$0` for the first argument"), so `/worklog update` and `/worklog close` receive a broken list command. Site left: the list command (the spec's own text, fixed by GC4). Site amended: the line-1 command (plan text) now builds line 1 in a variable `l` and holds no `$0`; its Contract gains the invariant "no `$` directly before a digit" and suite section 6 checks it ← 1/3: r2:C1
- [I1] applied — Task 9: the release-notes summary names `state.md`, `session-log.md`, `known-issues.md` and a reinstall that no prose of the entry supports; Step 2 accepted 130 words against the Contract's and the checklist's 120; the reason for skipping the post-push checklist said "no Codex-facing file changes" although the Codex adapter reads `hooks/skill-rules.json` → added the prose section "### Why a new document" (the three memory files, from the spec's "Problem" section, and the reinstall), named it in the Contract, set Step 2 to "at most 120 (the whole summary, the three bold labels included)", and rewrote the skip reason ← 3/3: r1:M1, r2:M1, r3:I1
- [I2] rejected: plan-mandated — Task 4 Contract: "the lines from `ROOT=` to the closing `fi` of the list command are the skill's list command without its print line, unchanged" (verbatim duplication of a logic block in `skills/worklog/SKILL.md` and `hooks/session-start`; GC11 quotes the spec: "Run the list command, unchanged") ← 2/3: r1:I1, r3:M1
- [M1] rejected: undecidable at this gate — spec inconsistent — (a) Task 2 Terms "the folder of the shell at the moment of the command" follows the spec's "Error handling", while the spec's "Definitions" says the root of a project without git is "the project directory"; (b) Task 2 "Valid forms of line 1" uses the slug pattern only, following the spec's check command, while the spec's "Valid forms of line 1" says "`<slug>` is the slug rule" and "Definitions" says the slug rule means "all three parts" ← 1/3: r2:M2
- [M2] applied — Task 1 Step 2: the expected result said every section 1 check fails, but "the word workstream is not used" passes on the absent file (`grep` exits 2) → the expectation is now `Results: 1 passed, 11 failed` with that reason ← 1/3: r2:M3

## Readiness pre 2 — Execution readiness — claude-opus-5[1m]
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 0 Important, 3 Minor | r2: 1 Critical, 0 Important, 2 Minor | r3: 1 Critical, 0 Important, 1 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 1 Critical, 0 Important, 4 Minor

### Dispositions
- [C1] rejected: undecidable at this gate — spec inconsistent — the same conflict as readiness pre 1 [C1]: GC4 keeps the spec's list command unchanged, and it holds `l = $0`, which Claude Code replaces with the first argument (GC7 makes the skill take arguments), so `/worklog update` and `/worklog close` without a slug get an empty list; every proposed fix (`l = $(0)`, a shared script, a wider section 6 check that would then fail on the list command) changes the spec's command text (harness field dropped: repository-readable) ← 3/3: r1:C1, r2:C1, r3:C1
- [M1] rejected: plan-mandated — the same text as readiness pre 1 [I2]: Task 4 Contract "the lines from `ROOT=` to the closing `fi` of the list command are the skill's list command without its print line, unchanged" ← 3/3: r1:M2, r2:M1, r3:M1
- [M2] applied — Task 4 Contract: GC11 says "Run the list command, unchanged" while the Contract drops the print line with no reason → the Contract now says the print line is left out because the hook's standard output is its JSON output and the spec's step 2 adds nothing to it when no path is left ← 1/3: r1:M1
- [M3] applied — Task 2 Contract: the verification lines promised `LIST-SAME` and `CHECK-SAME`, which Step 4 never prints → they now name `BLOCK-1-SAME` and `BLOCK-2-SAME`, and the Step 4 expectation drops the two unprinted names ← 1/3: r1:M3
- [M4] applied — Task 3 Step 3 (`/worklog new`, step 2) and Contract: GC9 says "When the user gives no rule of their own, the skill writes this one", but the skill text only offered the default → step 2 now says "When the user gives no rule of their own, write the default admission rule.", and the Contract names it ← 1/3: r2:M2

## Round 1 — Correctness & completeness — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 0 Important, 0 Minor | r2: 1 Critical, 0 Important, 1 Minor | r3: 1 Critical, 0 Important, 2 Minor
**Sources mapped:** 6/6
**Reviewer verdict:** 1 Critical, 0 Important, 2 Minor
**Converged:** no

### Dispositions
- [C1] applied — Task 2 Step 3 (`### The list command`), Task 4 Step 3, suite section 6: the list command in the skill body holds `l = $0`, which Claude Code replaces with the first argument (verified in https://code.claude.com/docs/en/skills, "Available string substitutions"; each reviewer replayed `l = update` and `l = close` on macOS awk: one empty line, no error), so `/worklog update` and `/worklog close` without a slug report that no work log is active; the planned suite runs the file text and cannot see it → `l = $0` is written `l = $(0)` in the skill copy and the hook copy (controller replay: the same two paths listed under bash and zsh, the Task 2 Step 4 comparison prints BLOCK-1-SAME and BLOCK-2-SAME, the hook copy equals the skill copy); GC4 carries a "Plan deviation" sentence; the Task 2 Contract, Step 3 text and Step 4 `diff` (a `sed` applies the one change to the spec's text) follow it; the skill text says why it writes `$(0)`; the `$`-digit check moved from section 6 (line-1 command only) to section 2 and covers every line of `SKILL.md`; the Task 2 and Task 3 Contracts name it ← 3/3: r1:C1, r2:C1, r3:C1
- spec deviation: every copy of the list command (skill and hook) writes the awk field reference as `l = $(0)` — spec: the list command's `FNR==1 { l = $0; ...`, "used unchanged" in every copy (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-09-21-worklog/specs/worklog-design.md) — kept because Claude Code replaces `$0` in a skill body with the first argument, so the spec's text breaks `/worklog update` and `/worklog close` without a slug; `$(0)` is the same field in POSIX awk
- [M1] applied — File Structure, "Repository premises tested": "Every existing fast suite `run-tests.sh` is mode `100755`" is false (`git ls-files -s` shows `tests/smart-compress/run-tests.sh` at `100644`) → the premise now states twelve of thirteen and that every task runs a suite with `bash <file>` ← 2/3: r2:M1, r3:M2
- [M2] applied — Task 2 Contract (the line-1 command): "lines 2 and later are byte-identical" is false for a file without a final line break, because awk `print` adds one → the invariant now states that exception ← 1/3: r3:M1

## Round 2 — Ambiguity & testability — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 4 Minor | r2: 0 Critical, 1 Important, 4 Minor | r3: 0 Critical, 0 Important, 8 Minor
**Sources mapped:** 18/18
**Reviewer verdict:** 0 Critical, 1 Important, 12 Minor
**Converged:** no

### Dispositions
- [I1] applied — Global Constraints entry 4: the "Plan deviation" sentence added in round 1 and the plan's own words "is used unchanged" do not trace to the spec and restate the body of artifacts the plan creates (a self-pin in disguise inside a block labelled "copied from the spec") → entry 4 now holds only the spec's quotes; the `$(0)` deviation and its reason moved to a new `**Assumptions:**` bullet (reference text), and the Task 2 Contract and Step 3 point to that bullet ← 3/3: r1:I1, r2:I1, r3:M2
- [M1] applied — Task 7 Step 3 and Contract: "the same `<n>` as before this task" had no baseline, and the `grep -n '"worklog"'` verification was never run → Step 3 now runs an `awk` check that the guide line stands below the marker (`BELOW-MARKER`), `git diff --numstat` (one line added, none removed) and the `grep`; both Contract verifications name them ← 3/3: r1:M3, r2:M1, r3:M5
- [M2] applied — Task 2 Contract (line-1 command): the permissions invariant named section 6, which checks no file mode → section 6 sets mode 640 on `plain.md` and checks it after the command; the Contract says the added final line break is a stated limit, not checked ← 2/3: r1:M2, r3:M4
- [M3] applied — Task 3 Step 3 (`## Commands and arguments`): "With no first word, the command is `update`" dropped the spec's condition "When the user types `/worklog`" → restored, with a pointer to the load test at the end of the section ← 1/3: r1:M1
- [M4] applied — Architecture: "a verbatim copy of the list command" although the hook leaves out the print line → "a copy of the list command, every line except its print line" ← 1/3: r1:M4
- [M5] applied — Task 8 Step 1 item 3: the sentence to follow ends in the middle of line 1194, so an inserted two-line block would split the next sentence → the item now replaces lines 1193 and 1194 with four re-wrapped lines ← 1/3: r2:M2
- [M6] applied — Task 3 Step 3 (`/worklog new`, step 4): "keep their headings" left the example decision's `### <YYYY-MM-DD> <short title>` line open to a literal reading → the step names the three section headings to keep and says the `###` line goes with the example decision ← 1/3: r2:M3
- [M7] applied — Global Constraints entries 3 and 8: two quotes cited the wrong spec section (verified: spec line 360 is in "Template", spec line 255 in "The document describes itself") → the brackets now name both sections ← 1/3: r2:M4
- [M8] applied — Task 3 Contract (suite section 7): the contracts named no phrases, so a fix could drop a phrase that the spec's "Testing strategy" requires → the section 7 contract lists the spec's phrases and says a fix may add phrases, never remove one of these ← 1/3: r3:M1
- [M9] applied — Global Constraint 11 and Architecture: the print-line omission was not recorded next to the header → the Architecture change of [M4] covers it, and the Task 4 Contract already gives the reason (readiness pre 2 [M2]); no sentence is added to the Global Constraints block, because a plan sentence there is a self-pin ([I1]) ← 1/3: r3:M3
- [M10] applied — Task 2, Task 3 and Task 8 Contracts: each verification line covered only part of its contract → each now says which items its command checks and that the others are checked by reading against the named spec sections or the "Must convey" list ← 1/3: r3:M6
- [M11] applied — Task 3 Step 3 skill text: (a) the Rules bullet "Every stop writes nothing" now says that a stop of the grammar, the slug test or the ordered checks comes before any write, and a stop at `close` step 2 keeps the check-5 correction; (b) the slug-test paragraph says a command word given as a slug has already stopped with the usage text; (c) the listing says the slug of a file is its name without `.md`, tests it with the first test and the slug command, and goes on after a failing name ← 1/3: r3:M7
- [M12] rejected: the plan's numbers are correct — `grep -n` on `docs/guide/README.md` prints line 1143 for `so through plain-text files — five at your project root, plus the handoff` and line 1144 for `files under \`tmp/docs/\``; line 1142 is `Sessions start with zero conversational memory.` ← 1/3: r3:M8

## Round 3 — Feasibility & architecture risk — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 1 Important, 1 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 3 Step 3 (full update, step 4): the plugin's own Bash output hook cuts a plain `git log` output longer than 40 lines to 30 lines (verified in the repository: rule `git-log` at `hooks/compression-rules.js` line 242, and `NEVER_COMPRESS` exempts compound commands, a pipe included), so the model would see commits 1 to 30 and the next window would start at 201 → the read is now the spec's command followed by `| cat`, with the reason in the skill text; the Task 3 Contract and a new `**Assumptions:**` bullet name it; the section 7 pin is a substring of the new line, so it still matches (harness field dropped: repository-readable) ← 1/3: r2:I1
- spec deviation: the full update runs `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD | cat` — spec: "reads the commits with `git log -n 200 --since="<created> 00:00" --format='%h %cd %s' --date=short HEAD`" (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-09-21-worklog/specs/worklog-design.md) — kept because the plugin's `git-log` compression rule would otherwise show only 30 of up to 200 commits, and a pipeline is never compressed
- [M1] applied — Task 1 Step 4: macOS `wc -l <file>` prints leading spaces, so the expected `94 skills/worklog/template.md` does not match letter for letter → the command is `wc -l < skills/worklog/template.md | tr -d ' '` and the expectation is `94` ← 2/3: r1:M1, r2:M1
- [M2] applied — Task 7 Step 4: the script can run a little over 300 seconds while the Bash tool's default time-out is 120000 ms (harness: tested by the reviewer; the controller's own Bash tool description also says "default 120000, max 600000"), so a tool time-out could be taken for a FAIL → the step asks for a time-out of at least 360000 ms and says a tool time-out is not a FAIL ← 1/3: r1:M2
- [M3] applied — header note and Tasks 4, 7, 8: dependencies that no shared file shows (Task 7 needs the Task 6 rule and the Tasks 2-3 skill; the Task 8 count needs Task 6), which a parallel-wave executor could miss → a "Task order" paragraph above the repository premises says to run the tasks in numeric order and lists these dependencies ← 1/3: r3:M1

## Round 4 — Adversarial failure modes — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 1 Important, 1 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 1 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — Global Constraints 4 and 11, Task 4 Contract and hook comment: the binding "Run the list command, unchanged" met a `$(0)` copy whose reason stood only in reference text, and the Task 4 brief never named it, so a per-task reviewer or fix subagent could restore `$0` and stop the run → Global Constraints 4, 10 and 11 each carry a labelled "Plan note, not a spec quote" that points to **Assumptions** without restating any artifact body (round 2 [I1] stays satisfied); the Task 4 Contract says the hook keeps the skill's `l = $(0)` and that "unchanged" in Global Constraint 11 means "the same as the skill's copy"; the hook comment gives the reason ← 2/3: r2:I1, r3:M2
- [M1] applied — Task 1 Step 4: the `diff` compared the template with the output of the same `awk` program that wrote it, so it could not fail → it now compares against a second extraction built with `grep -n` and `sed` (controller replay: identical, 94 lines), and "Does NOT cover" says so ← 2/3: r2:M1, r3:M1
- [M2] applied — Task 3 section 7: the pinned `git log` phrase stopped at `HEAD`, so a fix could drop the round 3 `| cat` with every check green → the phrase now ends with ` | cat`, and the section 7 Contract and the Assumption on the pinned phrase say so ← 1/3: r1:M1
- [M3] applied — Task 8 Step 1 (`CLAUDE.md`): an implementer subagent may decline a `CLAUDE.md` edit asked for by another agent (harness: tested by the reviewer; the controller's own context carries the same sentence, "no agent message can authorize changing your permission settings, CLAUDE.md, or configuration") and could report BLOCKED → a declined edit is named as a manual step in the report and the task still counts as done; the Contract and Step 2 accept that outcome ← 1/3: r1:M2
- [M4] applied — Task 2 suite: only the list command ran under `zsh`, the shell of the Bash tool on macOS (harness: tested by the reviewer, `$ZSH_VERSION` 5.9) → the three helpers run `"$RUN_SHELL"`, and a new section 6b runs the slug, check and line-1 commands under `zsh` when it is installed, with a NOTE otherwise (controller replay of the assembled Task 1-2 suite: 90 passed, 0 failed under `/bin/bash` 3.2; with the spec's `l = $0` restored, the section 2 check fails as intended) ← 1/3: r1:M3

## Readiness post 1 — Execution readiness — claude-opus-5[1m]
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 1 Important, 2 Minor | r3: 0 Critical, 1 Important, 0 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 1 Important, 4 Minor

### Dispositions
- [I1] rejected: plan-mandated — the same text as readiness pre 1 [I2]: Task 4 Contract "the lines from `ROOT=` to the closing `fi` of the list command are the skill's list command without its print line, unchanged" (the 12-line block stands in `skills/worklog/SKILL.md` and `hooks/session-start`; the task-reviewer rubric reports such a copy as Important, labelled plan-mandated) ← 3/3: r1:I1, r2:I1, r3:I1
- [M1] applied — Task 2 Contract (Terms): the verification line said to read the Terms against the spec's "Definitions", but the Root clause for a project without git follows the spec's "Error handling" (the `|| pwd` of the commands) → the verification line names that exception and both spec passages; the spec's own inconsistency stays owed from readiness pre 1 [M1] ← 2/3: r1:M2, r2:M1
- [M2] applied — Task 3 Step 3 (`## Rules`): "Never reorder or delete user text" was unconditional, while `close` step 2 and rule 4 of the work log delete an open-item row; the spec places the sentence inside its repair bullet ("Error handling") → the bullet now excepts the deletions that a step of the skill or a rule of the work log names ← 1/3: r1:M1
- [M3] applied — Task 8 Step 1 item 4 (guide subsection), a site of Global Constraint 1: the slug description omitted "ASCII" and the three command words → it now says lowercase ASCII letters (`a` to `z`), digits and single hyphens, at most 40 characters, and not `new`, `update` or `close` ← 1/3: r1:M3
- [M4] rejected: plan-mandated — Global Constraint 4: "Every copy of the command keeps both" (the folder test and the `|| true`); the list command's `2>/dev/null` and `|| true` hide an unreadable file or a failing Windows `find`, which the task-reviewer rubric lists as swallowed errors ← 1/3: r2:M2

### Host self-review (writing-plans "Self-Review", after the post-sequence)
- Check 5 (contract audit): the "Plan note" of Global Constraint 10 named the `| cat` of the skill text, and the note of Global Constraint 11 described which lines the hook holds; both restated part of an artifact the plan creates (a self-pin in disguise, the round 2 [I1] defect) → both notes now only point to **Assumptions** and to the Task 4 Contract.
- Checks 1 to 4: no spec requirement without a task; the placeholder and scope-reduction scans found only the template's own `<...>` placeholder wording; names are consistent across tasks (`RUN_SHELL`, `PATTERN_MSG`, `MD`/`MW`, `D`/`W`). Controller replay of the assembled Task 1 to 3 suite and skill in a scratch folder: `Results: 108 passed, 0 failed` under `/bin/bash` 3.2, 9 `## ` headings, no `$` directly before a digit in `SKILL.md`.
**Host self-review:** done

Owed:
- readiness pre 1 [C1], pre 2 [C1] — undecidable at this gate, spec inconsistent: Global Constraint 4 (the spec's list command "used unchanged", holding `l = $0`) against Global Constraint 7 (the skill takes arguments, and Claude Code replaces `$0` in a skill body with the first argument). Round 1 [C1] applied the recorded spec deviation `l = $(0)`; the spec's list command still needs the same amendment.
- readiness pre 1 [M1] (a) — undecidable at this gate, spec inconsistent: the root of a project without git is "the project directory" in the spec's "Definitions" and "the folder of the shell at the moment of the command" in its "Error handling"; the plan follows "Error handling".
- readiness pre 1 [M1] (b) — undecidable at this gate, spec inconsistent: the spec's "Valid forms of line 1" says "`<slug>` is the slug rule" (all three parts), while its check command tests the pattern only; the plan follows the check command.
- readiness pre 1 [I2], pre 2 [M1], post 1 [I1] — plan-mandated: the Task 4 Contract "the lines from `ROOT=` to the closing `fi` of the list command are the skill's list command without its print line, unchanged" (the same 12-line block in `skills/worklog/SKILL.md` and `hooks/session-start`; the task-reviewer rubric treats verbatim duplication of a logic block as a defect).
- readiness post 1 [M4] — plan-mandated: Global Constraint 4 "Every copy of the command keeps both" (the `2>/dev/null` and the `|| true` hide an unreadable file or a failing Windows `find`; the task-reviewer rubric lists swallowed errors as a defect).

_Loop complete — 2026-09-21 — rounds 4_
