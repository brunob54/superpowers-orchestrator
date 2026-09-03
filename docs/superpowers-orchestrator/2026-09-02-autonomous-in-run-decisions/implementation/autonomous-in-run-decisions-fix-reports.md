
## Round 1 fixes — 2026-09-02

### Changes, per finding

- **I1** — `skills/orchestrating-development/SKILL.md` (open-item definition, settled rule) and `batch-controller-prompt.md` (First-batch block, `[RESUME_ANSWER]` placeholder doc): a `[task <n>]` line now answers a report file holding exactly one section and is read as `[task <n>/1]`; the settled rule fires for both line shapes and for `### Question <k>` sections as well as `### Conflict <k>` sections.
- **I2** — Phase 3 discriminator in `SKILL.md` and Deviation 1 in `batch-controller-prompt.md`: only sections whose answer line was NOT in the `[RESUME_ANSWER]` of the dispatch that returned `BLOCKED` count; a return with no unanswered section is a controller failure.
- **I3** — `SKILL.md` answers section and re-dispatch rule, plus Deviation 1: every Phase 3 re-dispatch carries every ruled `[task <n>…]` line recorded for that task since the later of the latest `_Invocation` line and the latest `## STOPPED` entry; section numbers continue across attempts (new sections are appended, earlier ones are never renumbered or removed).
- **I4** — Phase 3 step 5 in `SKILL.md`, and the template's `## Resume Answer` heading and placeholder doc: every batch dispatch carries the recorded `[task <n>…]` answers whose `<n>` is in that batch's task list; the section is omitted only when no answer applies to the batch.
- **M1** — `SKILL.md` (~938 and ~992): a new review invocation started by an `amend plan` ruling IS the re-dispatch its `## RULING` entry already counts, not a second resume. The cap sentence is unchanged byte-for-byte.
- **M2 + CF1** — both copies of the `## RULING` block (log format and the RULING-entry section) now carry the same two `Items:` shapes, including `[<id>] escalated (<reason>) — <summary>`; the "one line per item" annotation moved out of the fence into prose under it.
- **M3 + CF3** — Resume step 3: the duplicated `**Follow-up:**` clause is dropped; the append is skipped when a `**Follow-up:**` line with the same text already stands in the entry; one commit covers all follow-ups of one resume, with `<n>` the lowest ruling number touched.
- **M4** — Phase 3 step 5: a `BLOCKED task=<n>` return writes no batch entry (the `## RULING`, or `## STOPPED`, entry is that boundary's entry); the batch entry is written only on `BATCH_COMPLETE`.
- **CF2** — Phase 3 step 5 now carries the escalated carve-out ("unless an item is escalated (see \"Handling a return as a whole\")").
- **CF4** — `tests/in-run-rulings/run-tests.sh`: the pre-flight negative check got the empty-range guard `[ -n "$RULINGS_END" ] && [ -n "$GUARD_LINE" ] &&`, in the same form as its sibling above it.

### Test runs

`bash tests/in-run-rulings/run-tests.sh` — full output:

```
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 561)
  PASS: class or reason label `escalated` (line 588, range 561..1035)
  PASS: class or reason label `forced` (line 591, range 561..1035)
  PASS: class or reason label `design` (line 596, range 561..1035)
  PASS: class or reason label `spec wrong` (line 603, range 561..1035)
  PASS: class or reason label `scope` (line 607, range 561..1035)
  PASS: class or reason label `irreversible` (line 611, range 561..1035)
  PASS: class or reason label `secret` (line 614, range 561..1035)
  PASS: class or reason label `chain` (line 620, range 561..1035)
  PASS: class or reason label escalated (chain) (line 621, range 561..1035)
  PASS: predicate fragment 'escalation wins' (line 589, range 561..1035)
  PASS: predicate fragment '### Conflict' (line 568, range 561..1035)
  PASS: predicate fragment '### Question' (line 569, range 561..1035)
  PASS: predicate fragment 'fatal environment failure' (line 624, range 561..1035)
  PASS: predicate fragment 'never `spec wrong`' (line 633, range 561..1035)
  PASS: predicate fragment 'handled as a whole' (line 653, range 561..1035)
  PASS: predicate fragment 'applied twice' (line 656, range 561..1035)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 686, range 561..1035)
  PASS: read-exception fragment 'never a reviewer report file' (line 674, range 561..1035)
  PASS: read-exception fragment 'read-only git commands' (line 691, range 561..1035)
  PASS: read-exception fragment 'resume step 3' (line 697, range 561..1035)
  PASS: read-exception fragment 'nothing else' (line 685, range 561..1035)
  PASS: read-exception fragment '40 lines' (line 682, range 561..1035)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 731, range 561..1035)
  PASS: fork pin '<!-- multi-review report -->' (line 773, range 561..1035)
  PASS: fork pin 'fork-<lens>' (line 732, range 561..1035)
  PASS: fork pin 'fork review unavailable' (line 812, range 561..1035)
  PASS: fork pin 'contradiction: unsettled' (line 798, range 561..1035)
  PASS: fork pin 'VERDICT:' (line 776, range 701..816)
  PASS: fork pin 'TABLED:' (line 779, range 701..816)
  PASS: fork fragment 'not a debate' (line 723, range 561..1035)
  PASS: fork fragment 'never pass conversation history' (line 729, range 561..1035)
  PASS: fork fragment 'action verb followed by a skill name' (line 782, range 561..1035)
  PASS: fork fragment 'in parallel, in one message' (line 703, range 561..1035)
  PASS: fork fragment 'evidence consistency' (line 712, range 561..1035)
  PASS: fork fragment 'general-purpose' (line 738, range 561..1035)
  PASS: Guard Interaction names the forks' marker (line 1066, range 1056..1071)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record or answer pin '-open-decisions.md' (line 818, range 561..1035)
  PASS: ruling-record or answer pin '**Follow-up:**' (line 840, range 561..1035)
  PASS: ruling-record or answer pin '## Ruling <n>' (line 825, range 561..1035)
  PASS: ruling-record or answer pin '(orchestrator):' (line 847, range 561..1035)
  PASS: ruling-record or answer pin 'decided (orchestrator)' (line 847, range 561..1035)
  PASS: ruling-record or answer pin 'amend plan:' (line 865, range 561..1035)
  PASS: ruling-record or answer pin 'plan governs:' (line 863, range 561..1035)
  PASS: ruling-record or answer pin 'fix it:' (line 858, range 561..1035)
  PASS: ruling-record or answer pin 'accept:' (line 869, range 561..1035)
  PASS: ruling-record or answer pin '**Amendment' (line 926, range 561..1035)
  PASS: ruling-record or answer pin '[task <n>/<k>]' (line 570, range 561..1035)
  PASS: ruling-record or answer fragment 'appended, never rewritten' (line 821, range 561..1035)
  PASS: ruling-record or answer fragment '(amended by ruling' (line 919, range 561..1035)
  PASS: ruling-record or answer fragment 'never apply the amendment twice' (line 932, range 561..1035)
  PASS: ruling-record or answer fragment 'new invocation' (line 938, range 561..1035)
  PASS: ruling-record or answer fragment 'untagged' (line 855, range 561..1035)
  PASS: ruling-record or answer fragment 'sides against binding plan text' (line 885, range 561..1035)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry or guard pin '## RULING' (line 579, range 561..1035)
  PASS: log-entry or guard pin 'Re-dispatch:' (line 956, range 561..1035)
  PASS: log-entry or guard pin 'Re-dispatch: none' (line 978, range 561..1035)
  PASS: log-entry or guard pin 'Ruled:' (line 981, range 561..1035)
  PASS: log-entry or guard pin 'chore(orchestration): <slug> ruling <n>' (line 929, range 561..1035)
  PASS: log-entry or guard pin 'plan governs (orchestrator decision)' (line 1024, range 561..1035)
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (line 985, range 561..1035)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (line 986, range 561..1035)
  PASS: log-entry or guard fragment 'previous invocation left' (line 971, range 561..1035)
  PASS: log-entry or guard fragment 'durable marker' (line 1012, range 561..1035)
  PASS: log-entry or guard fragment 'a Critical is never rejected' (line 1028, range 561..1035)
  PASS: log-entry or guard fragment 'quotes its clause' (line 1020, range 561..1035)
  PASS: log-entry or guard fragment 'recorded when it is made' (line 1031, range 561..1035)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (line 276, range 246..298)
  PASS: Phase 4 routes open items to the predicate (line 309, range 298..327)
  PASS: Phase 5 report lists unsettled contradictions (line 340, range 327..347)
  PASS: log-format pin '## RULING' (line 371, range 347..415)
  PASS: log-format pin 'Ruled:' (line 388, range 347..415)
  PASS: log-format pin 'Open:' (line 387, range 347..415)
  PASS: log-format pin 'Owed probe:' (line 389, range 347..415)
  PASS: log-format pin 'ruling <n> follow-up' (line 413, range 347..415)
  PASS: state.md carries the Rulings line (line 425, range 415..428)
  PASS: resume pin '## RULING' (line 464, range 428..561)
  PASS: resume pin 'Ruled:' (line 474, range 428..561)
  PASS: resume pin '**Follow-up:**' (line 488, range 428..561)
  PASS: resume pin '(orchestrator)' (line 483, range 428..561)
  PASS: resume pin '(user)' (line 484, range 428..561)
  PASS: resume pin 'decided (<who>)' (line 503, range 428..561)
  PASS: Resume step 3 no longer names decided (user) alone
  PASS: stop policy fragment 'escalated' (line 1042, range 1035..1056)
  PASS: stop policy fragment 'fork review unavailable' (line 1044, range 1035..1056)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin 'decided (orchestrator)'
  PASS: multi-code-review pin 'decided (<who>)'
  PASS: multi-code-review pin 'plan governs (orchestrator decision)'
  PASS: multi-code-review pin 'plan governs (user decision)'
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`'
  PASS: multi-code-review pin '— clause:'
  PASS: multi-code-review pin 'clause: none'
  PASS: multi-code-review pin '(plan-mandated) — at '
  PASS: multi-code-review pin '160 characters'
  PASS: M = 1 log-format example carries the clause (line 768, range 759..774)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 789, range 774..793)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..678)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 656, range 623..678)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..678)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..678)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..678)
  PASS: loop-side rule fragment 'never edits plan text' (line 662, range 623..678)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 664, range 623..678)
9. Controller prompt templates (R10)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(user)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 214, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 213, range 209..216)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin '(user)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 136, range 116..177)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 161, range 116..177)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 165, range 157..173)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 166, range 157..173)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 162, range 157..173)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 166, range 157..173)
  PASS: batch-controller report-section pin '### Question <k>'
  PASS: batch-controller report-section pin '### Conflict <k>'
  PASS: batch-controller report-section pin 'lowest-numbered task'
  PASS: batch-controller report-section pin '.superpowers/sdd/task-<n>-report.md'
  PASS: batch-controller report-section pin 'is settled'

Results: 122 passed, 0 failed
```

`bash tests/reviewer-templates/run-tests.sh` — summary:

```
Results: 24 passed, 0 failed
```

`bash tests/writing-plans/run-tests.sh` — summary:

```
Results: 15 passed, 0 failed
```

## Round 2 fixes — 2026-09-03

### Findings addressed
- [I1] skills/orchestrating-development/SKILL.md:566 and :875; skills/orchestrating-development/batch-controller-prompt.md:66 and :157 — the open item is named `[task <n>/<k>]` in every orchestrator-written line, and a bare `[task <n>]` is defined as a user shorthand that always means `[task <n>/1]`, independent of the report file's section count.
- [I2] skills/orchestrating-development/SKILL.md:897 and :283 and :979 — one Phase 3 answer-set rule ("The Phase 3 answer set — one rule"): every dispatch carries every ruled line recorded for the run, across invocations and stops; Phase 3 step 5 and the re-dispatch step refer to it; a `## STOPPED` entry lists on `Ruled:` lines every non-escalated ruling of the stopped unit.
- [I3] skills/orchestrating-development/SKILL.md:638 and :901; skills/orchestrating-development/batch-controller-prompt.md:84 — sections stay in `.superpowers/sdd/task-<n>-report.md`; a new section's `<k>` is 1 above the highest `<k>` in the file and in the dispatched `## Resume Answer` together, so an overwritten file never re-uses a number; a section counts as answered only for that exact `<k>`; at a task's first dispatch of the run the controller deletes sections left by an earlier run.
- [I4] skills/orchestrating-development/SKILL.md:916; skills/multi-code-review/SKILL.md:652 — for a fenced or block-quoted `**Exact content:**` clause the `(amended by ruling <n>)` marker goes at the end of the introducing paragraph line, never inside the fence or quote, and the loop's decided-wording rule matches that paragraph line.
- [I5] skills/orchestrating-development/SKILL.md:1031 (guard 4), :840 (Follow-up shape), :685 (read list) — a clause already decided by the user, recorded in the orchestrator's own ruling record, is never overruled: the answer repeats the user's decision tagged `(user)`, or the item is escalated; every `**Follow-up:**` line now carries the item's `clause:` text as the matching key.
- [I6] skills/multi-code-review/SKILL.md:891; skills/orchestrating-development/SKILL.md:871, :912, :1020 — one normalization rule (` — ` and ` ← ` each replaced by one space, cut to 160 characters) and one comparison rule (normalize the plan text at the named location, test the quote as a prefix) for the `plan governs` guard, the amendment lookup and the decided-wording test.
- [I7] skills/orchestrating-development/SKILL.md:283 and :897 — covered by the one answer-set rule: every recorded `[task <n>/<k>]` answer travels on every Phase 3 dispatch, whatever batch its task is in; the ruling record is readable under the classification read exception.
- [I8] skills/orchestrating-development/SKILL.md:703, :752, :776 — the fork return carries a mandatory `ITEM: [<id>]` line first after the marker, the prompt's `## Item` section states the id, and with several design items open the orchestrator dispatches and consolidates one item's forks at a time.
- [I9] skills/orchestrating-development/SKILL.md:464 — Resume step 3 verifies the `chore(orchestration): <slug> ruling <n>` commit is in `git log` before acting on a trailing `## RULING` entry, and commits the pending ruling first when it is not.
- [I10] skills/orchestrating-development/SKILL.md:485 — when a user answer replaces a `Ruled:` line whose ruling amended the plan, Resume step 3 reverts the amendment (clause found by its marker, note by its label) in the same resume commit.
- [I11] skills/orchestrating-development/SKILL.md:473 — the crash-window rebuild of a missing `## STOPPED` uses only the entries of that return (ruling number at or above the trailing entry's `<n>`) and never an entry that already carries a `**Follow-up:**` line.
- [I12] skills/orchestrating-development/SKILL.md:960; skills/multi-code-review/SKILL.md:943 — the pre-commit self-check turns a bare `fix it` against binding text into `amend plan: …; fix it` or `escalated`; the loop refuses such an answer with `unresolved: fix contradicts binding text — "<clause>"`.
- [I13] skills/orchestrating-development/SKILL.md:963 — the ruling commit is stated not to be a clean-tree boundary: the blocked task's uncommitted work may stand, is neither committed nor reverted, and the re-dispatched controller's mid-task recovery reviews it.
- [M1] skills/orchestrating-development/SKILL.md:994 — a chain stop still records each item as `escalated (chain)` in the `## RULING` entry and the ruling record before the `## STOPPED` entry; the pinned cap sentence is unchanged.
- [M2] skills/orchestrating-development/SKILL.md:989 — "the orchestration log's latest `_Invocation` line".
- [M3] skills/orchestrating-development/SKILL.md:572; skills/orchestrating-development/batch-controller-prompt.md:63 and :86 — a pre-flight conflict that touches no task uses the batch's first task as `<n>` and its report file.
- [M5] skills/orchestrating-development/SKILL.md:952 — the `## RULING` template uses the Orchestration Log Format's two `Items:` shapes, so an escalated item keeps its reason.
- [M6] skills/orchestrating-development/SKILL.md:726 — the orchestrator writes no preference into the transcript before the forks return and lists tabled outcomes in the order they arose.
- [M7] skills/multi-code-review/SKILL.md:936 — the clause on a `rejected: plan governs (orchestrator decision)` line is normalized like a `user-decision` quote.
- [M11] tests/in-run-rulings/run-tests.sh:83 and :195 — new `assert_in_range_folded` helper; the two cap-sentence fragments are matched with the range's line wraps folded to spaces.
- [M12] skills/orchestrating-development/SKILL.md:813 — a fork notice counts as lost once every other fork of the round has returned (once before the re-dispatch, once after it); no monitoring step and no other work during the wait.
- [M13] skills/multi-code-review/SKILL.md:652 — when a marker alone decides the wording, the rejection quotes the amended clause together with its marker.
- [M14] skills/multi-code-review/SKILL.md:891 — the ` — `/` ← ` replacement also applies to the finding summary, and a `"` inside the quoted plan text is written as `'`.

Not fixed (carried by the brief, recorded not fixed): M4, M8, M9, M10, M15.

### Commands run

`bash tests/in-run-rulings/run-tests.sh`

```
Results: 122 passed, 0 failed
```

`bash tests/reviewer-templates/run-tests.sh`

```
Results: 24 passed, 0 failed
```

`bash tests/writing-plans/run-tests.sh`

```
Results: 15 passed, 0 failed
```

`bash tests/codex/run-unit-tests.sh`

```
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
```

### Commit
`68ec491 review fixes (autonomous-in-run-decisions, round 2)` — files: skills/orchestrating-development/SKILL.md, skills/orchestrating-development/batch-controller-prompt.md, skills/multi-code-review/SKILL.md, tests/in-run-rulings/run-tests.sh

### Round 2 re-dispatch — I5 fix withdrawn (plan Task 2 read list) — 2026-09-03
- reverted: the fifth entry `5. Your own ruling record for this run, …` in "What may be read — the classification read exception"; the list ends at item 4 followed by "Nothing else." again
- reverted: guard `4. **A decision the user has already made is never overruled.** …` in "Guards against motivated judgement", and the count word restored from "Four" to "Three rules apply everywhere a ruling is made"
- reverted: in "The ruling record", the sentence "That line carries the user's answer and, after it, the item's `clause:` text quoted — … leaves the user's decision unprotected."
- reverted: in Resume step 3, the phrase "as a `**Follow-up:**` line carrying the item's `clause:` text (its shape is in `## In-run rulings`, "The ruling record")," restored to "as a `**Follow-up:**` line," — the rest of that hunk (finding I10, including "— with the plan file when an amendment was reverted —") is kept
- kept: all other round-2 changes

Commands run:

```
bash tests/in-run-rulings/run-tests.sh
Results: 122 passed, 0 failed
bash tests/reviewer-templates/run-tests.sh
Results: 24 passed, 0 failed
bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed
bash tests/codex/run-unit-tests.sh
Results: 10 suites passed, 0 suites failed
```

Commit: `119b69a review fixes (autonomous-in-run-decisions, round 2)` — files: skills/orchestrating-development/SKILL.md
