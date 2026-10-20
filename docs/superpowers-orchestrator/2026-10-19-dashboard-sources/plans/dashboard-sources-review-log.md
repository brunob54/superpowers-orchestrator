_Invocation 1 — 2026-10-20 — N=4 M=3 — gate: orchestration — plan-blob 09b5cb31cc3882e16b95f96773b2667a33ad61ac_

## Readiness pre 1 — Execution readiness — claude-opus-5-5
**Result:** open
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 5 Minor | r2: 0 Critical, 1 Important, 4 Minor | r3: 0 Critical, 1 Important, 3 Minor
**Sources mapped:** 15/15
**Reviewer verdict:** 0 Critical, 1 Important, 5 Minor

### Dispositions
- [I1] applied — Task 3 Contract verification and Step 5: the pattern `open-item'` also matches the kept line `case 'worklog-open-item'` (template.html:168; fixed side: spec 4.1 removes only "the `open-item` case of `itemLines`"), so the count after Task 3 is 1, not 0 → pattern anchored as `'open-item'` at both sites; the Contract line says why ← 3/3: r1:I1, r2:I1, r3:I1
- [M1] applied — Global Constraint 2 vs Task 1 Step 4 and Task 2 Step 4: the name searches ran with pathspecs (`-- skills tests`, `-- skills hooks tests`), not over the whole repository → pathspecs removed; hits in documents under `docs/` declared not callers; Task 2 Step 4 states that the searches also cover the names Task 3 removes (checked: whole-repository runs add only documents under `docs/`) ← 3/3: r1:M1, r2:M1, r3:M2
- [M2] applied — Global Constraint 1 vs Task 12 Contract verification and Step 2: the `wc -w` bound 125 accepted a summary above 120 words → bound set to 123 (120 words plus the three one-word labels) at both sites ← 3/3: r1:M2, r2:M2, r3:M3
- [M3] applied — Task 1 Step 3 and Task 5 Step 2: the expected red-phase FAIL lists did not match the old code (Task 1: `every rule gives invalid` also fails, the old code gives `file-missing`; Task 5: the no-details git-card check already passes) → both lists corrected (verified against dashboard-sync.js basicInvalid and evaluate) ← 2/3: r1:M3, r3:M1
- [M4] rejected: plan-mandated — Task 7 Step 3 and Task 8 Step 4 order `sharedRefLine`, `notShownText` and `SHARED_REF_TEXT` written in both dashboard-extract.js and template.html (verbatim duplication of a logic block; spec 4.5 "Report" requires both copies) ← 2/3: r1:M4, r2:M4
- [M5] applied — Global Constraint 3 vs Task 2 Contract verification and Step 6: the diff grep saw only the declaration lines of `normalizeLine`, `occurrenceOf`, `lineItemId` → replaced by a loop that compares each whole function text with its text at 971beb2b (command run on the current tree: prints nothing), plus the constant grep ← 2/3: r1:M5, r2:M3

## Readiness pre 2 — Execution readiness — claude-opus-5-5
**Result:** open
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 0 Important, 0 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 1 Critical, 0 Important, 3 Minor

### Dispositions
- [C1] applied — Task 4 Contract and Step 3 `commitMeta`: `git log -1 --format=%cd --date=short-local <ref>` walks to the parent commit and exits 128 when the parent object is missing; `commitMeta` runs outside the error handling of `buildSections`, so test-04 section 8 and test-06 case (10) stop and Task 4 Step 4 and every later suite gate fail (reproduced by the controller in a scratch repository: rc=128 without `--no-walk`, rc=0 with it) → `--no-walk` added to the command in the Contract and the reference code, with the reason ← 1/3: r1:C1
- spec deviation: commitMeta reads `date` with `git log -1 --no-walk --format=%cd --date=short-local <ref>` — spec: `git log -1 --format=%cd --date=short-local <ref>` (section 4.4) (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md) — kept because the spec's command exits 128 on a history with a missing parent object and would stop the extract, breaking the existing error-section tests; the output is identical wherever the spec's command succeeds
- [M1] rejected: plan-mandated — Task 7 and Task 8 Contracts order `sharedRefLine`, `notShownText` and `SHARED_REF_TEXT` written in both dashboard-extract.js and template.html (verbatim duplication of a logic block; spec 4.5 "Report" requires both copies) ← 1/3: r2:M1
- [M2] applied — Task 11 Step 2 guide paragraph: "no tool marked them as closed" contradicts spec section 1 ("The only writer is the dashboard `sync` command") → reworded: the skill that writes them never marks them as closed (only the dashboard's own `sync` did) ← 1/3: r3:M1
- [M3] applied — Global Constraint 14 vs Task 10 Step 3 (`refresh` step 4 text): "When sharing is set up" is narrower than the cases in which the line is printed (sharing off with a stored `sharedUrl` also prints it) → condition changed to "When a shared page is configured (sharing on, or a shared page left from an earlier share)" ← 1/3: r3:M2

## Readiness pre 3 — Execution readiness — claude-opus-5-5
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 0 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 3/3
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor

### Dispositions
- [M1] rejected: plan-mandated — Global Constraints 12–14 with Task 7 Step 3 and Task 8 Step 4 require two builders of the shared-ref sentence (`notShownText`, `sharedRefLine`, `SHARED_REF_TEXT` in dashboard-extract.js and in template.html; verbatim duplication of a logic block; spec 4.5 "Report" requires both) ← 1/3: r2:M1
- [M2] applied — Global Constraint 16 vs Task 4 "Does NOT cover" and Step 3 `localBranches`: on a detached HEAD `currentBranch()` returns `DETACHED` (`'detached'`, git-runs.js:92-95), so an unmerged branch named `detached` would get `current: true` with no branch checked out → the reference code marks an item only when `current !== DETACHED`; the "Does NOT cover" sentence states the remaining limit (a checked-out branch named `detached` gets no mark) ← 1/3: r3:M1
- [M3] rejected: plan-mandated — Task 7 Contract and Step 3 `followedRef`: Global Constraint 10 and spec 4.5 order a result-returning variant of checks 2 and 3 of `checkSharedName` beside the stopping original (verbatim duplication of a logic block) ← 1/3: r3:M2

## Round 1 — Correctness & completeness — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 0 Minor
**Sources mapped:** 2/2
**Reviewer verdict:** 0 Critical, 0 Important, 1 Minor
**Converged:** no

### Dispositions
- [M1] applied — Task 10 (SKILL.md) and Global Constraint 14: SKILL.md `local` step 2 also runs the private extract with `--data-dir`, so it now prints the `dashboard-extract: shared page:` line and the local file shows the shared-ref line, and no task says what `local` does with it → Task 10 "Does NOT cover" states that `local` is unchanged, the line is information, not an error, and `local` does not repeat it ← 2/3: r1:M1, r2:M1

## Round 2 — Ambiguity & testability — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 5 Minor | r2: 0 Critical, 0 Important, 8 Minor | r3: 0 Critical, 1 Important, 8 Minor
**Sources mapped:** 22/22
**Reviewer verdict:** 0 Critical, 1 Important, 14 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 8 Step 2 daylight-saving check (also the verification the Task 5 `calendarDays` Contract relies on): the spring change in Europe/Berlin gives 13.96 and 14.96 days with a local-midnight count, the same INFO/WARN result as the calendar count, so the check cannot fail the defect Global Constraint 8 forbids (measured by the controller: autumn 2026-10-12→2026-10-26 gives 14.04) → the check now uses the autumn change (`DST_BUILT = '2026-10-26T12:00:00+01:00'`, 2026-10-12 → information, 2026-10-11 → warning), with a comment that says why ← 1/3: r3:I1
- [M1] applied — Task 7 Contract invariant "every git command after the form check names `refs/remotes/<name>`": no test case could fail it → test-04 section 11 gains a case with a tag `origin/main` on HEAD (git resolves the bare name to the tag; checked by the controller) that asserts `short` and `notShown` still follow the remote-tracking ref ← 3/3: r1:M1, r2:M2, r3:M3
- [M2] applied — Task 5 Step 4 (and Task 10 Step 4): only the task's own test files ran, so a break in another dashboard test file would surface in a later task → the dashboard suite run and its expected line added to both steps ← 3/3: r1:M4, r2:M7, r3:M5
- [M3] applied — Task 11 Contract and Step 5: `grep -c` over six alternatives counts lines, not terms → replaced by a loop that checks each of eight terms on its own (adds `14 days` and the next-`refresh` phrase, both present in the plan's guide text) and prints `MISSING <term>` for an absent one ← 2/3: r1:M2, r2:M6
- [M4] applied — Task 7 Step 3 anchor `// repository name, and fails closed. The state folder` does not exist (dashboard-extract.js:15 reads `// repo.name, …`) → quote corrected; Task 8 Step 3 expected FAIL list now also names the class-only checks ← 2/3: r1:M5, r2:M8
- [M5] applied — Task 9 Contract item for the test-09 session fixture had no invariant and no verification → invariant (the marker stays a private `session` item, so check `(1) no marker in the shared page files` still tests the shared filter) and `node tests/dashboard/test-09-render.js` added; the second part of r3:M8 (Task 11 Step 1: the `node … | grep -c` pipeline also prints `0` when the command fails) applied too: the command now prints `true false` and cannot give that on a failure (run by the controller: `true false`) ← 2/3: r2:M5, r3:M8
- [M6] applied — Task 1 Contract: `grep -c "resolve-open-item"` = 2 rejects a correct rewrite with an extra comment → the check counts `kind: 'resolve-open-item'` (expected `1` per file), which is the invariant itself; the Task 2 test grep is kept (its names are removed functions, so an extra mention would be a stale reference) ← 1/3: r1:M3
- [M7] applied — Task 6 Contract: no test reads the selection rule of a Source sentence → the Contract states that spec section 7 failure mode 2 leaves this to review, and that a changed sentence is checked against its builder by the implementer and by the whole-branch code review ← 1/3: r2:M1
- [M8] applied — Task 10 Contract: "wording is free" while Step 1 pins three strings inside a reference code block → the three pinned strings are listed in the Contract ← 1/3: r2:M3
- [M9] applied — Task 3 had no test-file contract for the cases it drops from test-07 and test-08 → a contract item lists the dropped cases (open-item card, open-item line, "Mark resolved" control, their write counts) and keeps every `set-part` case; verification is both files passing plus review of the test diff ← 1/3: r2:M4
- [M10] applied — Task 1 Contract: the "security cases keep their coverage" clause had no check → `grep -c -E "^// 7[a-e]\."` on test-10 prints 5 and `grep -c -E "^// 1[0-5]\."` on test-11 prints 6 (same counts as today and as the plan's reference files, checked) ← 1/3: r3:M1
- [M11] applied — Task 7 Step 1: the extractor's singular "not shown" text and `Last published <published>.` were never compared with an expected report line → two report-line checks added to test-04 section 11 (one commit not shown; published from the state file); the detached-HEAD singular text stays covered only by the template tests ← 1/3: r3:M2
- [M12] applied — Task 1 Steps 1–2 reference test code held raw U+2028, U+2029, U+202E, U+2066 and U+FEFF characters (confirmed at six places) → written as `\uXXXX` escapes, as the current test files do ← 1/3: r3:M4
- [M13] applied — Task 3 Step 4: the replacement of `changesSomething` did not say whether its old comment ("An open item always changes; …") goes too → the step says each function is replaced with the comment block directly above it ← 1/3: r3:M6
- [M14] applied — Task 3 Step 2 "Replace the boot owner lines" named no exact line (the Task 7 anchor part is fixed under [M4]) → the step quotes the start of the `const owner = await boot(…OPEN_ID` line and the `the owner gets the controls and the pending label` check ← 1/3: r3:M7

## Round 3 — Feasibility & architecture risk — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no

### Dispositions
- [M1] applied — Task 9 Contract, test-09 session fixture: the invariant added in round 2 ([M5]) was false — in test-09 case 6 `session-log.md` is written after the push and never committed, and only a shared extract runs, so the marker reaches no data with either line (verified by the controller, test-09 lines 82–94) → invariant reworded: the edit only keeps the fixture parsable after Task 2; check (1) tests that the shared extract reads only the pushed ref ← 2/3: r1:M1, r2:M1
- [M2] applied — Task 12 Step 3 heading "every fast suite of the repository" while the loop runs the 20 suites of CLAUDE.md (`tests/context-management/run-tests.sh` exists and is not listed) → heading now "every fast suite listed in the repository `CLAUDE.md`", which is what spec section 6 asks ← 1/3: r1:M2
- [M3] applied — Task 7 Step 3 `followedRef`: the shared-ref `date` command lacks the `--no-walk` that Task 4 gives `commitMeta`, so a missing parent object turns the line into the `error` case → `--no-walk` added with a comment ← 1/3: r2:M2
- spec deviation: followedRef reads the shared-ref `date` with `git log -1 --no-walk --format=%cd --date=short-local <ref>` — spec: `git log -1 --format=%cd --date=short-local <ref>` (section 4.5, `date`) (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-19-dashboard-sources/specs/dashboard-sources-design.md) — kept for the same reason as the commitMeta deviation of readiness pre 2: same output wherever the spec's command succeeds, and no failure on a missing parent object
- [M4] applied — Task 11 Step 2: the anchor `make only the shared page's link public.` spans two lines of docs/guide/README.md (1388–1389) → the step says so and names the insertion point (directly before the line that starts `**Edits.**`) ← 1/3: r3:M1

## Round 4 — Adversarial failure modes — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 0 Important, 7 Minor
**Converged:** yes

### Dispositions
- [M1] applied — Task 11 Step 2, "**Edits.**" paragraph: the old sentence ends in the middle of guide line 1392 ("… work log. The page"), so replacing both lines whole would leave "stores each edit as a proposal." with no subject (verified by the controller) → the step says to replace only the text up to and including `work log.` and keep ` The page` ← 2/3: r2:M2, r3:M1
- [M2] applied — Task 7 Step 1, `state files that are not valid JSON give null`: passes before the change, because `info` is the string `no sharedRef key` and its missing fields serialize as null → the check also asserts `typeof info` is `object` ← 1/3: r1:M1
- [M3] applied — Task 4 and Task 7 local-date cases rely on git honouring the IANA name `TZ=Asia/Tokyo`, not checked for Git for Windows → a new Assumptions line states the limit (the zone value is not changed: a POSIX form was not tested with Node and git here) ← 1/3: r1:M2
- [M4] applied — Task 11 Step 4/5: the count of amendment lines (5) and the numstat cannot tell whether each line stands at its own section → a check added after Step 4 that tests, for each of the five unique anchors, that the line two below it starts with `Amended in 7.73.0 by ` (anchors checked unique in the old spec) ← 1/3: r1:M3
- [M5] applied — "Task order matters" paragraph: no statement that tasks must not run in a parallel wave (each task runs the whole suite while other tasks' new tests fail on purpose; Task 2 removes `lineAtOccurrence` and `RESOLVED_MARK`, which dashboard-sync.js uses until Task 1, verified) → one sentence added ← 1/3: r2:M1
- [M6] applied — Task 12 Step 2 release-note text "`refresh --diff` prints these lines once": `refresh` has no `--diff` option (SKILL.md argument-hint); the diff is the renderer's `--diff` inside `refresh` → reworded to "The first `refresh` prints these lines once, in the `--diff` output of its renderer step" ← 1/3: r3:M2
- [M7] rejected: SKILL.md's Errors table already keys an extractor failure on exit code 2, the shared-page line comes with exit 0, and round 1 [M1] recorded in Task 10 that `local` is unchanged and the line is information; adding text to `local` lies outside the SKILL.md changes of spec section 4.7 — `local` step 2 gives no sentence for the `dashboard-extract: shared page:` line ← 1/3: r3:M3

## Readiness post 1 — Execution readiness — claude-opus-5-5
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 0 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 2/2
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor

### Dispositions
- [M1] applied — Global Constraint 2 vs Task 3 Step 4 and the coverage note of Task 2 Step 4: no whole-repository search covers the kind string `open-item` and the label `Mark resolved` (`-w openItem` matches neither), and the Task 2 note claimed that its search covered Task 3's names → Task 3 Step 4 gains a whole-repository `git grep -l` for both names with the expected files (checked by the controller: outside `docs/` today only dashboard-extract.js, template.html, test-05, test-07, test-08, and Task 2 removes the extractor and test-05 hits first); the Task 2 note now says which names it does not cover ← 1/3: r1:M1
- [M2] rejected: plan-mandated — Task 7 Step 3 and Task 8 Step 4 order `notShownText`, `sharedRefLine` and `SHARED_REF_TEXT` in both dashboard-extract.js and template.html (verbatim duplication of a logic block; Global Constraints 11–14 and spec 4.5 "Report" require both) ← 1/3: r3:M1

### Host self-review (writing-plans Self-Review)
- Spec coverage: every requirement of spec sections 4.1–4.7, 5, 6 and 8 maps to a task (three round 1 reviewers confirmed it; no gap found).
- Placeholder scan: no TBD, TODO or "add appropriate"; the two hits for `v1` and `placeholder` are test data and an HTML attribute.
- Type consistency: the names added in this review (`isCurrent` with `DETACHED`, already imported by dashboard-extract.js; `--no-walk` in `commitMeta` and `followedRef`; `typeof info` in test-04) match the names of the tasks that define them.
- Scope-reduction scan: no hit.
- Contract audit: 12 tasks, 12 `**Contract:**` fields; no `**Exact content:**` marker; every Global Constraints entry traces to the spec. No inline fix needed.
**Host self-review:** done

Owed:
- plan-mandated (readiness pre 1 [M4], pre 2 [M1], pre 3 [M1], post 1 [M2]): two builders of the shared-ref sentence
    plan side: Task 7 Step 3 and Task 8 Step 4 write `notShownText`, `sharedRefLine` and `SHARED_REF_TEXT` in both skills/dashboard/scripts/dashboard-extract.js and skills/dashboard/template.html
    rubric side: verbatim duplication of a logic block; required by Global Constraints 11–14 and spec 4.5 "Report" ("The extractor builds the line once; the template builds the page text from the data fields"), kept equal by the same-wording checks of test-07
- plan-mandated (readiness pre 3 [M3]): result-returning copy of the shared-ref checks
    plan side: Task 7 Step 3 `followedRef` runs `show-ref --verify --quiet` and `rev-parse --verify --quiet …^{commit}` beside the stopping `checkSharedName`
    rubric side: verbatim duplication of a logic block; required by Global Constraint 10 ("the private run never calls `checkSharedName`") and spec 4.5
_Loop complete — 2026-10-20 — rounds 4_
