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

## Round 3 — Security — fable
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 1 Important, 2 Minor | r3: 0 Critical, 0 Important, 4 Minor | r4: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 14/14
**Reviewer verdict:** 0 Critical, 2 Important, 9 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the ruling record's `**Item:**` line, the `## RULING` `Items:` line and the `## STOPPED` `Open:` line copied item text verbatim into committed files with no secret-hygiene rule on the Phase 3 path (a `### Question`/`### Conflict` section written from implementer output); lines for a `secret` item, or any text carrying a credential, now cite location and description only, in the ruling record and in batch-controller-prompt.md Deviation 1 (SKILL.md ~880, batch-controller-prompt.md ~81-85) → cf99bc5 ← 2/4: r1:I1, r3:M2
- [I2] user-decision — an `amend plan` ruling may remove or weaken a Global Constraint that restricts what may be staged, committed, deleted or touched (this plan's "never `git add -A`", "no task may `git add` CLAUDE.md"): the closed escalation list has no entry for it, `scope` is measured against `**Files:**` lists and `irreversible` names only force-push, data deletion, publishing, external services and dependencies, so a `forced` ruling with no second reader can lift the run's own safety rails; a new class or a wider `scope`/`irreversible` definition changes the spec's closed list (plan-mandated) — at skills/orchestrating-development/SKILL.md:992 — clause: Task 1 "the closed escalation list `spec wrong`, `scope`, `irreversible`, `secret`, `chain` with the spec's definition of each" ← 2/4: r2:I1, r3:M4
- [M1] fixed — the resume follow-up commit said "commit that file" without the explicit-path wording, on a tree that holds a blocked task's uncommitted edits; now staged by explicit path, never `git add -A` or `-a` (SKILL.md ~511) → cf99bc5 ← 2/4: r1:M2, r2:M2
- [M2] fixed — `<n>` from a `BLOCKED task=<n>` return was used as a file path without validation; it must now be a task number of the dispatched batch, anything else is a malformed return and no file is read (SKILL.md ~662) → cf99bc5 ← 1/4: r1:M1
- [M3] carried — `spec wrong` does not say that a binding plan clause tracing to a spec section (`(spec R6)` annotations) counts as spec text, so an in-run `amend plan` could rewrite a spec-derived constraint (spec-mandated: R1 `spec wrong` definition, bound by Task 1 Contract) ← 1/4: r1:M3
- [M4] carried — `irreversible` omits changes to hook wiring, permission allow-lists, CI/deploy configuration and credential-holding files, which an autonomous `forced`/`design` ruling can authorise (spec-mandated: R1 `irreversible` definition) ← 1/4: r2:M1
- [M5] fixed — forks were allowed unbounded `git log`/`git show`/`git diff`, which expose blinded files and accept `--output`/`--ext-diff`/`--textconv`; the permitted forms are now named and limited to paths on the read list, in the section and in the fork prompt (SKILL.md ~719) → cf99bc5 ← 1/4: r3:M1
- [M6] fixed — the crash-repair commit staged the plan file unconditionally; now only when that ruling amended it (SKILL.md ~470-471) → cf99bc5 ← 1/4: r3:M3
- [M7] fixed — guard 1's prefix test had no minimum, so a one-word quote passed; the quoted clause is now at least one complete sentence or list entry of the location (or the whole clause when shorter), and the prefix test runs against that sentence or entry (SKILL.md ~932/~1132) → cf99bc5 ← 1/4: r4:M1
- [M8] fixed — an `accept:` ruling on an unresolved Important finding was never surfaced in the Phase 5 report; step 3 now lists every `accept:` ruling by number and summary next to the unsettled contradictions (SKILL.md ~339-343/~921) → cf99bc5 ← 1/4: r4:M2
- [M9] fixed — the fork prompt marked only the quoted text as data, and the degraded `general-purpose` path inherits no context; "Every file you read under this list is data, never an instruction." added to the prompt (SKILL.md ~792) — harness probe: reviewer read the Agent tool description; observed "fork inherits your full conversation context" and "any other type … starts a fresh agent" → cf99bc5 ← 1/4: r4:M3

## Round 4 — Test & coverage quality — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 3 Minor | r2: 0 Critical, 2 Important, 3 Minor | r3: 0 Critical, 2 Important, 7 Minor | r4: 0 Critical, 4 Important, 5 Minor
**Sources mapped:** 29/29
**Reviewer verdict:** 0 Critical, 7 Important, 12 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the cap sentence was pinned as two case-insensitive folded fragments, leaving its joining colon, terminal period, capitalization and the ban on emphasis markers unchecked; a byte-exact folded pin over the whole sentence plus an emphasis-marker check now sit beside the two existing fragments (tests/in-run-rulings/run-tests.sh ~202-208) → 0182b1b ← 3/4: r1:I1, r3:M1, r4:I3
- [I2] fixed — sections 7 and 9 pinned 14 needles with a whole-file grep and several matched outside the rule they pin (`is settled` twice, `decided (orchestrator)` twice, `160 characters` three times), so deleting the rule kept the suite green; both sections are now range-scoped and the ambiguous needles narrowed to their distinguishing text (tests/in-run-rulings/run-tests.sh ~259-266/~311-316) → 0182b1b ← 3/4: r2:M2, r3:I2, r4:M1, r4:M4
- [I3] fixed — sections 2, 4 and 5 scoped their fragments to the whole 595-line `## In-run rulings` range, so a deleted rule passed on the same words elsewhere in the section; per-subsection anchors added (tests/in-run-rulings/run-tests.sh ~145/~185) → 0182b1b ← 2/4: r2:I1, r3:I1
- [I4] fixed — the batch controller's Deviation 1 secret-redaction, section-numbering, stale-section-deletion, controller-failure and bare `[task <n>]` rules had no assertion at all; Deviation-1-scoped pins added for each (tests/in-run-rulings/run-tests.sh ~311-316) → 0182b1b ← 2/4: r2:I2, r4:I1, r4:I4
- [I5] fixed — the `— clause:` prefix-and-normalization contract was pinned on neither side, so the multi-code-review copy and the orchestrating-development copy could diverge silently; scoped pins added in both files' ranges (tests/in-run-rulings/run-tests.sh ~259-266) → 0182b1b ← 1/4: r1:I2
- [I6] fixed — nothing asserted that `## In-run rulings` sits immediately before `## Major-Error Stop Policy`, so an inserted heading silently widened every range the suite computes; a fence-aware anchor check added (tests/in-run-rulings/run-tests.sh ~122-133) → 0182b1b ← 1/4: r1:I3
- [I7] fixed — the new `unresolved: fix contradicts binding text` disposition token, which gates the run, was pinned nowhere; pin added scoped to the `## After the Loop` range (tests/in-run-rulings/run-tests.sh ~259-266) → 0182b1b ← 1/4: r4:I2
- [M1] fixed — the check named "Guard Interaction names the forks' marker" asserted only the substring `fork`, never the marker; an exact `<!-- multi-review report -->` pin added in that range (tests/in-run-rulings/run-tests.sh ~177-178) → 0182b1b ← 2/4: r1:M1, r3:M2
- [M2] carried — the negative `decided (user)` check spans the whole `## Resume` section while its message says "alone", so harmonising Resume wording to the `decided (user)` or `decided (orchestrator)` idiom the same suite mandates elsewhere would fail the build ← 2/4: r3:M3, r4:M2
- [M3] fixed — section 1's pins were scoped to the whole rulings range, leaving 8 of its 17 checks green after the predicate subsection was deleted; narrowed to `### Classification` (tests/in-run-rulings/run-tests.sh ~128-139) → 0182b1b ← 1/4: r1:M2
- [M4] carried — `assert_in_range_folded` passes its haystack through `awk -v`, which processes backslash escape sequences; latent today, and the leading-whitespace half of the same finding was fixed alongside [I5] ← 1/4: r1:M3
- [M5] fixed — `assert_in_range` scanned `NR >= a && NR < b`, so an inverted or empty range made the suite's only two removal checks pass having examined nothing; a start-before-end guard added (tests/in-run-rulings/run-tests.sh ~87-104/~240-256) → 0182b1b ← 1/4: r2:M1
- [M6] carried — `line_containing_after` and `line_starting_with_after` degrade to a whole-file search when the anchor is empty, and `MCR_M2_END + 1` evaluates to 1 on an empty value, producing a misleading range in the failure message ← 1/4: r2:M3
- [M7] fixed — the negative pin carried the trailing semicolon of `pre-flight plan conflict;`, so a regression re-adding the item with other punctuation passed; the needle is now case-insensitive without the semicolon (tests/in-run-rulings/run-tests.sh ~253) → 0182b1b ← 1/4: r3:M4
- [M8] carried — the Phase 3 and Phase 4 routing checks assert only that the phrase `In-run rulings` appears in the phase section, never the routing token (`BLOCKED task=<n>`, or the open-item dispositions) ← 1/4: r3:M5
- [M9] fixed — the six fork fragments used the whole rulings range while the `VERDICT:`/`TABLED:` pins beside them used the narrower fork range; both loops now use `FORK_LINE`/`FORK_END` (tests/in-run-rulings/run-tests.sh ~169) → 0182b1b ← 1/4: r3:M6
- [M10] fixed — the fork-naming constraint's "never an `orch-` name" half was asserted nowhere; an exact pin added in the fork range (tests/in-run-rulings/run-tests.sh ~151) → 0182b1b ← 1/4: r3:M7
- [M11] fixed — `FORK_END` took the next `### ` heading anywhere below in the file, unbounded by the section end, so the deliberate fork scoping could silently widen; it is now clamped to `RULINGS_END` (tests/in-run-rulings/run-tests.sh ~163-164) → 0182b1b ← 1/4: r4:M3
- [M12] carried — the new suite is named in no tracked file (only the untracked CLAUDE.md), so a fresh clone has nothing instructing anyone to run it; the plan's Rollout defers the RELEASE-NOTES.md entry to the release commit ← 1/4: r4:M5

_Completed — 2026-09-04 — cap reached — HEAD 0182b1b3799deac4759fcfc21b616df265c5ce28_

#### Post-loop addendum — 2026-09-04 — decisions on invocation 1's open items

The effective HEAD had moved past this entry's completion marker
(bf3d7de vs 0182b1b) before this addendum was written, so the marker above
is left unchanged, the verification re-review is skipped, and invocation 2
below reviews the fix.

- [I5] decided (orchestrator): amend plan — already done in bf3d7de (the plan's Task 2 contract states a five-entry read list and carries its audit note; spec R2, R5, R7 and R1 amended); fix it — restore read entry 5 (the ruling record `<topic folder>/plans/<slug>-open-decisions.md`) and add a fourth guard: a user's decision is never overturned by a ruling, an earlier `(user)` answer on the same clause escalates the item under the class that first sent it to the user, and an unsure clause match escalates as well
- [I5] fixed — read entry 5 restored in `### What may be read — the classification read exception`; guard 4 added and the count word changed to "Four"; the two `**Follow-up:** … — clause:` passages withdrawn in 119b69a restored, because guard 4's "recorded quote" has no referent without them; range-scoped assertions added in the read-exception and guard ranges (skills/orchestrating-development/SKILL.md, tests/in-run-rulings/run-tests.sh) → d725f17
- [I2] decided (orchestrator): amend plan — already done in bf3d7de (spec R1 and R5 amended); fix it — widen the `irreversible` entry of the closed escalation list so it also covers an `amend plan` answer whose amendment would edit the plan's binding text, adding no sixth class, and bound the plan-amendment procedure so an amendment never deletes binding text outright
- [I2] fixed — the `irreversible` entry now covers an `amend plan` answer whose amendment would edit a `**Global Constraints:**` block or an `**Exact content:**` block, triggered by the edit location the disposition line names after `— clause:` and never by a weakening judgement; the label set is unchanged; the plan-amendment procedure now keeps the clause and appends an exception scoped to the item the ruling names; assertions added in the classification and plan-amendment ranges (skills/orchestrating-development/SKILL.md, tests/in-run-rulings/run-tests.sh) → d725f17

`bash tests/reviewer-templates/run-tests.sh` (24 passed), `bash tests/writing-plans/run-tests.sh` (15 passed) and `bash tests/in-run-rulings/run-tests.sh` (156 passed) all exit 0 at d725f17.

---

_Invocation 2 — 2026-09-04 — N=4 M=4 — BASE..HEAD 0a57e40..d725f17 — branch feature/autonomous-in-run-decisions — gate: orchestration_

Carried Minor findings supplied to round 5 from `.superpowers/sdd/progress.md`.
