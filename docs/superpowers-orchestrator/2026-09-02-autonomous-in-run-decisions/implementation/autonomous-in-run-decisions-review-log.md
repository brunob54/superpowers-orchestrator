# Review log — autonomous-in-run-decisions

_Invocation 1 — 2026-09-02 — N=4 M=4 — BASE..HEAD 0a57e40..e903e73 — branch feature/autonomous-in-run-decisions — gate: orchestration_

carried findings: 11 Minor lines read from .superpowers/sdd/progress.md

## Round 1 — Correctness & spec alignment — fable
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 5 Minor | r2: 0 Critical, 3 Important, 6 Minor | r3: 0 Critical, 2 Important, 6 Minor | r4: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 30/30
**Reviewer verdict:** 0 Critical, 4 Important, 14 Minor
**Converged:** no
### Dispositions
- [I1] fixed — settled rule keyed on `[task <n>/<k>]` only, while a single-section item is named `[task <n>]`; a `[task <n>]` line now reads as `[task <n>/1]` and the settled rule covers both shapes and Question sections (SKILL.md ~549-553/~865-867, batch-controller-prompt.md ~64-68) → 866c888 ← 4/4: r1:I2, r2:I2, r3:I2, r4:I1
- [I2] fixed — Phase 3 discriminator counted any Conflict/Question section with no freshness test, so a stale answered section misclassified a controller failure as an open-item return; only sections unanswered in the dispatched `[RESUME_ANSWER]` count now (SKILL.md ~617-624, batch-controller-prompt.md Deviation 1) → 866c888 ← 3/4: r1:I3, r2:I1, r3:I1
- [I3] fixed — a second open return on one task lost the first ruling and `<k>` renumbering could apply a stale answer to a new section; every re-dispatch carries all ruled lines of the unit and `<k>` continues across attempts (SKILL.md ~849-867/~928-930, batch-controller-prompt.md ~78-82) → 866c888 ← 2/4: r1:I1, r4:M1
- [I4] fixed — a pre-flight conflict ruled for a later-batch task never reached that batch, whose first dispatch omitted `## Resume Answer`; each batch's `[RESUME_ANSWER]` now carries every recorded answer whose task is in its list (SKILL.md ~271-278/~553, batch-controller-prompt.md ~70) → 866c888 ← 1/4: r2:I3
- [M1] fixed — "new invocation started by an `amend plan` ruling counts as one in-run resume" read as double counting against the cap (SKILL.md ~904/~954-956) → 866c888 ← 4/4: r1:M4, r2:M5, r3:M5, r4:M4
- [M2] fixed — `## RULING` `Items:` line had no form for an escalated item; `[<id>] escalated (<reason>) — <summary>` defined in both copies of the block (SKILL.md ~363/~914-915) → 866c888 ← 2/4: r2:M2, r3:M4
- [M3] fixed — Resume step 3 `**Follow-up:**` append not idempotent and follow-up commit `<n>` undefined for several rulings (SKILL.md ~474-488) → 866c888 ← 2/4: r2:M6, r3:M6
- [M4] fixed — Phase 3 step 5 did not say whether a `BLOCKED` return writes a batch entry, which could break the Resume "log ends with `## RULING`" signal (SKILL.md ~269-278) → 866c888 ← 2/4: r3:M2, r4:M2
- [M5] carried — Resume step 3 `**Follow-up:**` append is unconditional but Phase 1 answers and pre-change `## STOPPED` entries have no ruling-record entry (SKILL.md ~474-478) ← 1/4: r1:M1
- [M6] carried — `Ruled:` lines are built into `[RESUME_ANSWER]` only under "When the resume prompt does answer"; the effective-HEAD-moved re-dispatch path does not say they are sent (SKILL.md ~468-471 vs ~491-495) ← 1/4: r1:M2
- [M7] carried — `## RULING` `Re-dispatch:` line does not record the batch (task list, `First batch:` value) a Phase 3 re-dispatch used, which a crash resume must reconstruct (SKILL.md ~366/~917/~451-455) ← 1/4: r1:M3
- [M8] carried — code-review-loop-prompt.md Deviation 3 secret EXCEPTION says only "record it as `unresolved`", without the `— at <file:line> — clause:` shape the self-sufficient line rule requires (multi-code-review SKILL.md ~884-893) ← 1/4: r1:M5
- [M9] carried — unclear whether a `## RULING` entry is written when every item of a return is escalated (SKILL.md ~934) ← 1/4: r2:M1
- [M10] carried — two routes for an impossible reference-text task step: `amend plan:` answer vs plain-text answer "valid against reference text" (SKILL.md ~853/~869) ← 1/4: r2:M3
- [M11] carried — self-sufficient line rule allows `clause: none` only for an `unresolved` item, but a carried item logged `user-decision` from reviewer recommendations also collides with nothing (multi-code-review SKILL.md ~884) ← 1/4: r2:M4
- [M12] carried — `fork review unavailable` stops mid-return before the already-decided `forced` items of the same return are recorded (SKILL.md ~784-789) ← 1/4: r3:M1
- [M13] carried — "The run stops only for the closed list of reasons in the predicate" contradicts the section's own environment stops (SKILL.md ~563-564) ← 1/4: r3:M3
- [M14] carried — `## STOPPED` `Detail:` for a Phase 3 stop names `.superpowers/sdd/task-<n>-report.md`, excluded state that does not survive a clone boundary (SKILL.md ~384-385) ← 1/4: r4:M3
- carried item 1 (run-tests.sh helpers/path vars unused until Tasks 2-6) — carried (4× ship-as-is: all used by the final suite)
- carried item 2 (run-tests.sh section 2 two extra fragment checks) — carried (4× ship-as-is)
- carried item 3 (run-tests.sh FORK_END scans to EOF) — carried (4× ship-as-is)
- carried item 4 (`clause:` label wording inherited from multi-code-review) — carried (4× ship-as-is)
- carried item 5 (RULING template `Items:` annotation inline after spaces) — fixed — annotation moved out of the fence, with [M2] → 866c888 (3× fix-before-merge, 1× ship-as-is)
- carried item 6 (Phase 3 step 5 lacks the escalated carve-out) — fixed — carve-out added → 866c888 (4× fix-before-merge)
- carried item 7 (Resume step 3 states the `**Follow-up:**` append twice) — fixed — first mention dropped, with [M3] → 866c888 (1× fix-before-merge, 3× ship-as-is)
- carried item 8 (run-tests.sh pre-flight negative check lacks the empty-range guard) — fixed — guard added → 866c888 (3× fix-before-merge, 1× ship-as-is)
- carried item 9 (`## RULING` block defined twice) — carried (4× ship-as-is)
- carried item 10 (`## STOPPED` `Owed probe:` sentence vacuous for a Phase 3 stop) — carried (4× ship-as-is)
- carried item 11 (batch-controller-prompt.md pre-flight rule stated twice) — carried (4× ship-as-is)


## Round 2 — Adversarial red-team — fable
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 6 Important, 6 Minor | r2: 0 Critical, 4 Important, 5 Minor | r3: 0 Critical, 5 Important, 5 Minor | r4: 0 Critical, 6 Important, 6 Minor
**Sources mapped:** 43/43
**Reviewer verdict:** 0 Critical, 13 Important, 15 Minor
**Converged:** no
### Dispositions
- [I1] fixed — bare `[task <n>]` answer form was defined by the report file's current section count, which grows across attempts; now unconditionally `[task <n>/1]` (user shorthand only) and orchestrator lines always use `[task <n>/<k>]` (SKILL.md ~567-569/~901, batch-controller-prompt.md ~68-70/~157-165) → 68ec491 ← 4/4: r1:I5, r2:I2, r3:I2, r4:I1
- [I2] fixed — two rules for which Phase 3 answers a dispatch carries (step 5: every recorded answer; ~898: only since the latest `_Invocation`/`## STOPPED`), so a ruling made before a stop was dropped on resume; one rule now, stated once: every ruled line of the run for that task, nothing dropped at an invocation line or a stop (SKILL.md ~283-284/~898/~981) → 68ec491 ← 3/4: r1:I2, r2:I1, r4:I2
- [I3] fixed — `### Question <k>`/`### Conflict <k>` sections live in `task-<n>-report.md`, which the re-dispatched implementer rewrites, so a second question re-used number 1 and read as a controller failure; `<k>` now numbers above the highest section seen in the file or in the dispatched `[RESUME_ANSWER]`, a section counts as answered only when its exact `<k>` was sent, and stale sections are cleared at a task's first dispatch of the run (batch-controller-prompt.md ~84, SKILL.md ~649) → 68ec491 ← 2/4: r1:I1, r3:I1
- [I4] fixed — `(amended by ruling <n>)` marker on an `**Exact content:**` block could land inside the fence (copied into the product) or after it (not on the clause); placement now pinned to the `**Exact content:**` paragraph line and the decided-wording rule matches that paragraph (SKILL.md ~916-918) → 68ec491 ← 2/4: r1:I3, r4:I5
- [I5] user-decision — the orchestrator can overturn a user's explicit plan-governs answer: a later invocation re-raises the same objection under a new id, the loop's decided-wording rule covers verification cycles only (Task 8), and the orchestrator may read only the latest entry's disposition line, so a guard needs the ruling record — a fifth read entry the plan's four-entry read list excludes (plan-mandated; a fix adding that entry and a guard 4 was applied in 68ec491 and withdrawn in 119b69a) — at skills/orchestrating-development/SKILL.md:1015 — clause: Task 2 "Must convey: the four-entry read list of spec R2 (latest disposition line only; task report file and `### Task <n>` section; the named plan clause and its spec section" ← 2/4: r1:I4, r3:I4
- [I6] fixed — quoted clause on the self-sufficient line is normalized (` — `/` ← ` replaced, 160-char cap) but every consumer compared it as verbatim; one normalization rule now applies on both sides and the quote is compared as a prefix of the normalized plan text at the named location (multi-code-review SKILL.md ~892-894, SKILL.md ~858/~911-918/~1020-1024) → 68ec491 ← 2/4: r1:I6, r2:M5
- [I7] fixed — a conflict touching several tasks was ruled under the lowest task and its answer carried only to batches holding that task; every recorded `[task …]` answer now goes on every Phase 3 dispatch, the lowest-numbered-task filing rule unchanged (SKILL.md ~283-284/~573) → 68ec491 ← 1/4: r2:I3
- [I8] fixed — fork returns for several `design` items in one return carried nothing naming the item; a mandatory `ITEM: [<id>]` line follows the marker, and items are forked and consolidated one at a time (SKILL.md ~703/~746/~776) → 68ec491 ← 1/4: r2:I4
- [I9] fixed — Resume step 3 acted on a trailing `## RULING` entry without checking that the `ruling <n>` commit landed; the commit is now verified in `git log` and made first when missing (SKILL.md ~464) → 68ec491 ← 1/4: r3:I3
- [I10] fixed — a resume answer that replaced a `Ruled:` line left the plan amendment that line had applied in force; Resume step 3 now reverts the amendment (by label and marker) in the same resume commit (SKILL.md ~485) → 68ec491 ← 1/4: r3:I5
- [I11] fixed — the crash-window rebuild of a missing `## STOPPED` took `Open:` lines from every `escalated` entry in the ruling record, re-opening answered escalations; now limited to the trailing return's entries and skips entries carrying a `**Follow-up:**` line (SKILL.md ~473) → 68ec491 ← 1/4: r4:I3
- [I12] fixed — a bare `fix it` against binding text was forbidden but absent from the pre-commit self-check, and the loop had no disposition for it; the self-check now lists that repair and the loop logs `unresolved: fix contradicts binding text — "<clause>"` (SKILL.md ~1020-1031, multi-code-review SKILL.md ~645) → 68ec491 ← 1/4: r4:I4
- [I13] fixed — nothing said what the tree may hold at a Phase 3 ruling commit after a mid-task `BLOCKED`, so "unexpected dirty tree at a boundary" could stop every such block; the ruling commit is now stated not to be a clean-tree boundary, with the blocked task's uncommitted work named and handed to the re-dispatched controller's recovery (SKILL.md ~264-278/~965-968) → 68ec491 ← 1/4: r4:I6
- [M1] fixed — chain stop said "no further ruling is made" while the return-as-a-whole rule required `## RULING` and ruling-record entries; the chain stop now records each item as `escalated (chain)` in both, the cap sentence untouched (SKILL.md ~994-995) → 68ec491 ← 3/4: r1:M3, r2:M1, r3:M3
- [M2] fixed — "the log's latest `_Invocation` line" could be read as the review log's, resetting the cap on every `amend plan`; now "the orchestration log's" (SKILL.md ~989) → 68ec491 ← 2/4: r1:M1, r4:M4
- [M3] fixed — a pre-flight conflict touching no task had no `<n>` for `BLOCKED task=<n>`; the batch's first task is the fallback (batch-controller-prompt.md ~63, SKILL.md ~573) → 68ec491 ← 2/4: r1:M2, r4:M3
- [M4] carried — loop-side decided-wording rule applies in verification cycles only, so an ordinary round of a post-amendment invocation re-raises a decided clause as `user-decision` and spends a resume (plan-mandated: Task 8 "Does NOT cover … findings in an ordinary `## Round <i>`", spec R8.3) ← 2/4: r2:M3, r4:M6
- [M5] fixed — the section's `Items:` template omitted the reason the Log Format shape carries for an escalated item; both shapes used in both places (SKILL.md ~953) → 68ec491 ← 2/4: r3:M4, r4:M1
- [M6] fixed — forks inherit the orchestrator's transcript, so a preference written before they return anchors all of them; the orchestrator now writes no preference before the forks return and lists tabled outcomes in the order they arose (SKILL.md ~731) → 68ec491 ← 1/4: r1:M4
- [M7] fixed — `rejected: plan governs (orchestrator decision) — "<clause>"` inherited no ` ← `/` — ` sanitization; the same replacement applies to that quote (multi-code-review SKILL.md ~947-950) → 68ec491 ← 1/4: r1:M5
- [M8] carried — scope = union of the plan's `**Files:**` lists, so a file the implementer legitimately changed but no task listed makes a later `fix it` there `escalated (scope)` (spec-mandated: R1 `scope` definition, bound by Task 1 Contract) ← 1/4: r1:M6
- [M9] carried — the `scope` test needs every task's `**Files:**` list but the four-entry read list ("Nothing else") does not allow reading them (plan Task 2 Contract / spec R2; no variant of the fix is free of a plan or spec change) ← 1/4: r2:M2
- [M10] carried — `secret` class triggers on a summary that merely names the word "secret" without an exposure (spec-mandated: R1 `secret` definition "disposition reason or summary names an exposed secret") ← 1/4: r2:M4
- [M11] fixed — the cap sentence was pinned as two single-line fragments while the Global Constraint allows a wrap inside the sentence; the check now folds newlines over the range before matching (tests/in-run-rulings/run-tests.sh ~181-182) → 68ec491 ← 1/4: r3:M1
- [M12] fixed — "a notice that never arrives" had no bound; a wait bound after which the return counts as lost is stated, with no other work during the wait (SKILL.md ~813) → 68ec491 ← 1/4: r3:M2
- [M13] fixed — what `rejected: plan governs (loop decision)` quotes for wording decided only by an `(amended by ruling <n>)` marker was undefined; it quotes the amended clause plus its marker (multi-code-review SKILL.md ~647) → 68ec491 ← 1/4: r3:M5
- [M14] fixed — the `<finding summary>` before `— at <file:line>` was not sanitized and a `"` inside the quote was unhandled; the replacement now covers the summary and the quote rule names the `"` case (multi-code-review SKILL.md ~892-894) → 68ec491 ← 1/4: r4:M2
- [M15] carried — "the LATEST `_Invocation` entry's disposition line for that id" assumes one line per id per entry, but review-log ids restart each round (pre-existing for user answers, now exercised autonomously) (SKILL.md ~673) ← 1/4: r4:M5
