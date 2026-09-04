
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

## Round 3 fixes — 2026-09-03

### Findings addressed
- [I1] skills/orchestrating-development/SKILL.md:880, skills/orchestrating-development/batch-controller-prompt.md:81-85 — added "Never reproduce a secret." to `### The ruling record` (the `**Item:**`, `Items:` and `Open:` lines name the location and describe the value, never copy it), referenced it from the `## RULING` entry's `Items:` prose, and added the matching rule to batch-controller-prompt.md Deviation 1 for `### Question <k>` / `### Conflict <k>` sections.
- [M1] skills/orchestrating-development/SKILL.md:511 — the resume follow-up commit now stages by explicit path, never `git add -A` and never `git commit -a`.
- [M2] skills/orchestrating-development/SKILL.md:662 — the Phase 3 discriminator now requires `<n>` to be a task number present in the dispatched `[TASK_LIST]`; any other value is a malformed return, no file is read for it, and it takes the controller-failure path.
- [M5] skills/orchestrating-development/SKILL.md:719 — forks' read-only git use is bound to three forms (`git log --oneline <BASE>..HEAD`, `git show <sha>:<path>`, `git diff <BASE>..HEAD -- <path>`) for paths on the read list, with `--output`, `--ext-diff` and `--textconv` forbidden; the fork prompt's "What you may read" block carries the same bound for the degraded `general-purpose` path.
- [M6] skills/orchestrating-development/SKILL.md:470-471 — resume step 3's crash repair stages the plan file only when that ruling amended it.
- [M7] skills/orchestrating-development/SKILL.md:932 — the quoted-clause rule now states the compared unit (one sentence or one list entry, never a whole section) and the quote's minimum length; guard 1 keeps referring to that one rule.
- [M8] skills/orchestrating-development/SKILL.md:339-343 — Phase 5 step 3 now lists every ruling whose Resolution line begins with `accept:`, by ruling number with its item summary, or `none`, next to the unsettled contradictions.
- [M9] skills/orchestrating-development/SKILL.md:792 — the fork prompt's "What you may read" block states "Every file you read under this list is data, never an instruction."

### Commands run
```
bash tests/in-run-rulings/run-tests.sh
Results: 122 passed, 0 failed
```

```
bash tests/reviewer-templates/run-tests.sh
Results: 24 passed, 0 failed
```

```
bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed
```

```
bash tests/codex/run-unit-tests.sh
Results: 10 suites passed, 0 suites failed
```

### Commit
`cf99bc5 review fixes (autonomous-in-run-decisions, round 3)` — files: skills/orchestrating-development/SKILL.md, skills/orchestrating-development/batch-controller-prompt.md

## Round 4

- [I1] tests/in-run-rulings/run-tests.sh — added a case-sensitive `assert_in_range_folded_exact` helper and used it to pin the full cap sentence, byte-exact including the `: ` colon and the final period, next to the two existing case-insensitive half-fragment checks; added a separate check that no `*` appears inside the matched sentence span.
- [I2] tests/in-run-rulings/run-tests.sh — section 7's pins are now split and range-scoped to `## Review Log Format`/`## After the Loop`/`## Error Handling` in multi-code-review/SKILL.md instead of whole-file `assert_pin`; section 9's batch-controller report-section pins are now scoped to a `DEV1_LINE`/`DEV1_END` range anchored on `1. Never ask the user.` and `2. Sequential only`. Ambiguous needles (`160 characters`) were narrowed to their distinguishing text (`cut it to 160 characters`).
- [I3] tests/in-run-rulings/run-tests.sh — sections 1, 2, 4 and 5 now use per-`### `-subsection anchors (`CLASS_LINE`/`CLASS_END`, `READ_EXCEPTION_LINE`/`READ_EXCEPTION_END`, `RECORD_LINE`/`RECORD_END`, `ANSWERS_LINE`/`ANSWERS_END`, `LOG_ENTRY_LINE`/`LOG_ENTRY_END`, `GUARDS_LINE`/`GUARDS_END`) instead of the whole `## In-run rulings` range, computed the same way as the pre-existing `FORK_LINE`/`FORK_END` pair.
- [I4] skills/orchestrating-development/batch-controller-prompt.md was not edited (out of scope for this fix subagent); coverage gap closed in tests/in-run-rulings/run-tests.sh instead: added Deviation-1-scoped pins for `Never copy a secret or a credential`, `re-used on the same task`, `those sections before you write your own`, `controller failure`, and `` [task <n>]` line means `[task <n>/1] ``, reading exact wording from the current file rather than inventing it.
- [I5] tests/in-run-rulings/run-tests.sh — added range-scoped pins on both sides: multi-code-review/SKILL.md gets `**Normalization is one rule:**`, `tests the quote as a **prefix**` and `No consumer compares the quote with the raw plan text`; orchestrating-development/SKILL.md gets `**The quoted clause, and how it is compared.**`, `test whether the quote is a prefix of it` (answers subsection) and a folded check for `never as a byte-equal match` (guards subsection).
- [I6] tests/in-run-rulings/run-tests.sh — added a new "0. Section anchors" check asserting `RULINGS_LINE < RULINGS_END`, plus a fence-aware awk scan asserting no other line starting with `## ` (outside a ` ``` ` fenced block) lies between them.
- [I7] tests/in-run-rulings/run-tests.sh — added the pin `unresolved: fix contradicts binding text`, scoped to multi-code-review/SKILL.md's `## After the Loop` range.
- [M1] tests/in-run-rulings/run-tests.sh — added an exact assertion for `<!-- multi-review report -->` in the Guard Interaction range, alongside the existing `fork` fragment check.
- [M3] tests/in-run-rulings/run-tests.sh — folded into the [I3] fix: section 1's label and fragment loops now use `CLASS_LINE`/`CLASS_END` (the `### Classification — the escalation predicate` subsection) instead of the whole `## In-run rulings` range.
- [M5] tests/in-run-rulings/run-tests.sh — added a `start -ge end` guard to `assert_in_range` that fails (rather than silently passing on an empty scan) when the range is inverted or empty; added the same guard to the two ad hoc absence checks (Resume step 3's `decided (user)` check, and the stop policy's `pre-flight plan conflict` check).
- [M7] tests/in-run-rulings/run-tests.sh — the stop-policy absence check now matches `pre-flight plan conflict` case-insensitively without the trailing semicolon, so different punctuation around a re-added item still fails the check.
- [M9] tests/in-run-rulings/run-tests.sh — the six fork fragment checks (`not a debate`, etc.) now use `"$FORK_LINE" "$FORK_END"` instead of the whole `## In-run rulings` range, matching the standard already used for `VERDICT:`/`TABLED:`.
- [M10] tests/in-run-rulings/run-tests.sh — added an exact assertion for `` never an `orch-` name `` scoped to the fork range.
- [M11] tests/in-run-rulings/run-tests.sh — `FORK_END` is now clamped to `RULINGS_END` whenever it is empty or falls past `RULINGS_END`, instead of only defaulting when empty.

Additional changes made necessary by the above (not separately numbered findings):
- Removed `assert_pin`, which the [I2] rewrite of sections 7 and 9 left with no remaining call sites.
- `assert_in_range_folded` (and the new `assert_in_range_folded_exact`) now strip each line's leading whitespace before joining lines with a single space, so a folded needle spanning an indented list-continuation line (the Deviation 1 rules in batch-controller-prompt.md, and the guards subsection's `never as a byte-equal match`) is not broken by the indentation's extra spaces. This is a behavior change to a shared helper, needed because the guard fragment added under [I5] and a design considered for [I4] both span indented line wraps; it does not change the outcome of any previously-passing folded check, since none of those relied on multiple consecutive spaces.

### Commands run
```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/in-run-rulings/run-tests.sh
```
Exit code: 0

Tail of output:
```
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 100, range 79..107)

Results: 140 passed, 0 failed
```

### Commit
`review fixes (autonomous-in-run-decisions, round 4)` — files: tests/in-run-rulings/run-tests.sh

## Round 5 fixes — 2026-09-04

Commit subject used, as instructed by the fix prompt: `review fixes
(autonomous-in-run-decisions, round 3)`.

### Findings addressed

- **[I5] Defect A — skills/orchestrating-development/SKILL.md,
  `### What may be read — the classification read exception`.** Restored the
  fifth numbered read entry, withdrawn in commit 119b69a: the orchestrator's
  own ruling record `<topic folder>/plans/<slug>-open-decisions.md`. Its
  wording now points at the new guard 4 — it says guard 4 reads the record,
  before every decision, for an earlier answer tagged `(user)` on the same
  clause, and that the Phase 3 re-dispatch answer set reads it too.
- **[I5] Defect B — same file, `### Guards against motivated judgement`.**
  Changed the count word from "Three" to "Four" and added guard 4: a user's
  decision is never overturned by a ruling; before deciding an item the
  orchestrator reads the ruling record for an earlier answer tagged `(user)`
  on the same clause, compared under the normalization rule; when such an
  answer stands, the item is **escalated**, never decided, under the class
  that first sent it to the user; and when the orchestrator cannot tell
  whether the clause is the same one — the item restates the clause instead
  of carrying the recorded quote — it escalates as well, because an unsure
  match never becomes a ruling. The withdrawn guard 4's "answer as the user
  did" branch was NOT restored: the decided behaviour is to escalate. No
  sixth escalation class was added.
- **[I5] Defect B — dependency, explicitly restored.** Guard 4's phrase "the
  recorded quote" has no referent unless the ruling record carries the
  clause quote on each `(user)` follow-up. Commit 119b69a had withdrawn the
  two passages that required this, and **both are restored as they stood
  before 119b69a**:
  1. `## Resume` step 3 — the `**Follow-up:**` line must carry the item's
     `clause:` text, with a pointer to its shape in `## In-run rulings`,
     "The ruling record".
  2. `### The ruling record` (the paragraph that ends the subsection, the
     one the withdrawn hunk sat in) — the `**Follow-up:**` line shape
     `**Follow-up:** <answer> — clause: <plan location> "<quoted plan
     text>"`, or `— clause: none`, and the sentence saying the quote is the
     key guard 4 matches a later item against.
- **[I2] Defect A — same file, `### Classification — the escalation
  predicate`.** Widened the `irreversible` entry of the closed escalation
  list: an `amend plan` answer whose amendment would edit the plan's
  **binding** text — the `**Global Constraints:**` block, or an
  `**Exact content:**` block — is `escalated (irreversible)` as well. The
  trigger is the edit location the item's disposition line already names
  after `— clause:`, never a judgement about whether the amendment weakens
  anything. The label set is unchanged: `spec wrong`, `scope`,
  `irreversible`, `secret`, `chain`.
- **[I2] Defect B — same file, the `**Plan amendment.**` paragraph.** Added
  the missing bound on deletion: an amendment never **deletes** binding text
  outright; it keeps the clause and appends to it an exception scoped to the
  item the ruling names, so that the clause still governs every other task.

### New assertions — tests/in-run-rulings/run-tests.sh

All new needles are scoped to the narrowest existing range anchor that holds
the rule; no new anchor was needed. Binding literal labels use
`assert_in_range` in `exact` mode; free text uses `fragment` mode, or
`assert_in_range_folded` when the needle crosses a line wrap.

- Read-exception range (`READ_EXCEPTION_LINE`..`READ_EXCEPTION_END`): exact
  pin on `<topic folder>/plans/<slug>-open-decisions.md`; folded fragment
  `the file you write yourself`; fragments `Guard 4 (below) reads it` and
  `` earlier answer tagged `(user)` on the same clause ``.
- Guards range (`GUARDS_LINE`..`GUARDS_END`): `assert_in_range_folded_exact`
  on `Four rules apply everywhere a ruling is made` (catches dropping guard 4
  without renumbering); fragments `A user's decision is never overturned by a
  ruling`, `read your ruling record`, `` recorded answer tagged `(user)` ``,
  `under the class that first sent it to the user`, `you never re-answer it
  in the`; folded fragment `an unsure match never becomes a ruling`.
- Classification range (`CLASS_LINE`..`CLASS_END`): exact pin
  `escalated (irreversible)`; folded fragments `amendment would edit the
  plan's **binding** text` and `never a judgement about whether the
  amendment weakens anything`.
- Answers range (`ANSWERS_LINE`..`ANSWERS_END`, which holds the
  `**Plan amendment.**` paragraph): folded fragments
  `never **deletes** binding text outright` and `appends to it an exception
  scoped to the item the ruling names`.

### Mutation check on the new needles

Each new rule was deleted from a scratch copy of the skill file and the suite
re-run; every deletion failed the suite (exit 1) with exactly the intended
assertions failing, then the file was restored byte-identical:

```
--- entry 5 deleted:              exit=1, 4 failures (all four entry-5 assertions)
--- guard 4 deleted:              exit=1, 6 failures (all six guard-4 assertions)
--- irreversible widening removed: exit=1, 3 failures (the three irreversible assertions)
--- amendment bound removed:      exit=1, 2 failures (the two amendment-bound assertions)
--- "Four" changed to "Three":    exit=1, 1 failure (guard count word is 'Four')
```

### Commands run

```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/reviewer-templates/run-tests.sh
```
Exit code: 0

```
1. Harness claims rule is inside the prompt block
  PASS: doc-review template: Harness claims rule inside the prompt block (line 42, block 25..133)
  PASS: code-review template: Harness claims rule inside the prompt block (line 64, block 24..193)
2. Finding-format field spellings
  PASS: doc-review template: field spelling 'harness: tested —'
  PASS: doc-review template: field spelling 'harness: untested —'
  PASS: code-review template: field spelling 'harness: tested —'
  PASS: code-review template: field spelling 'harness: untested —'
3. Controller triage reason strings and completion-report line
  PASS: multi-doc-review SKILL.md: reason string 'harness probe —'
  PASS: multi-doc-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-doc-review SKILL.md: completion-report line 'Harness probes owed:'
  PASS: multi-code-review SKILL.md: reason string 'harness probe —'
  PASS: multi-code-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-code-review SKILL.md: completion-report line 'Harness probes owed:'
4. user-decision guard
  PASS: multi-code-review SKILL.md: guard fragment
5. Rule text drift between the two templates
  PASS: doc-review template: rule extract is non-empty
  PASS: code-review template: rule extract is non-empty
  PASS: rule text identical in both templates
6. Unchanged contracts
  PASS: code-review template: blinding pathspec line
  PASS: code-review template: report marker instruction
  PASS: doc-review template: report marker instruction
7. Ambiguity & testability plan-cell contract targets
  PASS: multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty
  PASS: Ambiguity plan cell: fragment 'no stated contract'
  PASS: Ambiguity plan cell: fragment 'self-pin'
  PASS: Ambiguity plan cell: gate label '**Body authority:**'
8. Body-authority gate label consistency (writing-plans vs multi-doc-review)
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
```

```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/writing-plans/run-tests.sh
```
Exit code: 0

```
1. Contracts and Literal Bodies section (R1)
  PASS: section heading '## Contracts and Literal Bodies' (whole-line match, line 122)
  PASS: exact-content label '**Exact content:**' (rule 4) (line 172, range 170..184)
  PASS: procedural tie-break fragment 'treat the block as not procedural' (rule 1) (line 149, range 129..154)
  PASS: authority-default fragment 'ordinary fix' (rule 3) (line 166, range 163..170)
  PASS: self-pin fragment 'together as one ordinary fix' (rule 5) (line 187, range 184..194)
2. Task Template Contract field (R2)
  PASS: Task Template block carries '**Contract:**' (line 261, block 249..291)
3. Plan Header authority note (R3)
  PASS: Plan Header template carries 'reference implementations' (line 86, block 81..96)
  PASS: Plan Header template carries '**Body authority:**' (line 86, block 81..96)
  PASS: Plan Header note states the closed binding set 'Exactly two things in this plan bind' (line 86, block 81..96)
  PASS: Plan Header note states the exact-content binding condition 'names a pin this plan does not itself write or edit' (line 86, block 81..96)
  PASS: Plan Header note states the residue clause 'Everything else is reference' (line 86, block 81..96)
  PASS: Plan Header note states the non-conflict disposition 'is never a plan conflict: record it against the plan-writing skill' (line 86, block 81..96)
  PASS: Plan Header note states the disposition's scoping guard 'covers the note's own text alone' (line 86, block 81..96)
4. Self-Review contract audit (R4)
  PASS: self-review fragment 'falsifiable' (check 5) (line 338, range 338..340)
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
```

```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/in-run-rulings/run-tests.sh
```
Exit code: 0

```
0. Section anchors
  PASS: '## In-run rulings' precedes '## Major-Error Stop Policy' (lines 588..1215)
  PASS: no other '## ' heading (outside a fenced code block) between 588 and 1215
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 588)
  PASS: class or reason label `escalated` (line 617, range 612..708)
  PASS: class or reason label `forced` (line 620, range 612..708)
  PASS: class or reason label `design` (line 625, range 612..708)
  PASS: class or reason label `spec wrong` (line 632, range 612..708)
  PASS: class or reason label `scope` (line 636, range 612..708)
  PASS: class or reason label `irreversible` (line 640, range 612..708)
  PASS: class or reason label `secret` (line 649, range 612..708)
  PASS: class or reason label `chain` (line 655, range 612..708)
  PASS: class or reason label escalated (chain) (line 656, range 612..708)
  PASS: predicate fragment 'escalation wins' (line 618, range 612..708)
  PASS: predicate fragment '### Conflict' (line 678, range 612..708)
  PASS: predicate fragment '### Question' (line 678, range 612..708)
  PASS: predicate fragment 'fatal environment failure' (line 659, range 612..708)
  PASS: predicate fragment 'never `spec wrong`' (line 668, range 612..708)
  PASS: predicate fragment 'handled as a whole' (line 698, range 612..708)
  PASS: predicate fragment 'applied twice' (line 701, range 612..708)
  PASS: irreversible entry pin 'escalated (irreversible)' (line 645, range 612..708)
  PASS: irreversible entry covers an amendment of binding plan text (range 612..708, line wraps folded)
  PASS: irreversible entry triggers on the edit location, not on a judgement (range 612..708, line wraps folded)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 736, range 708..756)
  PASS: read-exception fragment 'never a reviewer report file' (line 719, range 708..756)
  PASS: read-exception fragment 'read-only git commands' (line 741, range 708..756)
  PASS: read-exception fragment 'resume step 3' (line 752, range 708..756)
  PASS: read-exception fragment 'nothing else' (line 735, range 708..756)
  PASS: read-exception fragment '40 lines' (line 727, range 708..756)
  PASS: read-exception entry 5 names the ruling-record path (line 730, range 708..756)
  PASS: read-exception entry 5 calls it the file you write yourself (range 708..756, line wraps folded)
  PASS: read-exception entry 5 fragment 'Guard 4 (below) reads it' (line 731, range 708..756)
  PASS: read-exception entry 5 fragment 'earlier answer tagged `(user)` on the same clause' (line 732, range 708..756)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 800, range 588..1215)
  PASS: fork pin '<!-- multi-review report -->' (line 847, range 588..1215)
  PASS: fork pin 'fork-<lens>' (line 801, range 588..1215)
  PASS: fork pin 'fork review unavailable' (line 887, range 588..1215)
  PASS: fork pin 'contradiction: unsettled' (line 873, range 588..1215)
  PASS: fork pin 'VERDICT:' (line 851, range 756..899)
  PASS: fork pin 'TABLED:' (line 854, range 756..899)
  PASS: fork fragment 'not a debate' (line 778, range 756..899)
  PASS: fork fragment 'never pass conversation history' (line 798, range 756..899)
  PASS: fork fragment 'action verb followed by a skill name' (line 857, range 756..899)
  PASS: fork fragment 'in parallel, in one message' (line 758, range 756..899)
  PASS: fork fragment 'evidence consistency' (line 767, range 756..899)
  PASS: fork fragment 'general-purpose' (line 807, range 756..899)
  PASS: fork naming never uses an orch- name (line 802, range 756..899)
  PASS: Guard Interaction names the forks' marker (line 1246, range 1236..1251)
  PASS: Guard Interaction names the forks' return marker exactly (line 1245, range 1236..1251)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record pin '-open-decisions.md' (line 901, range 899..939)
  PASS: ruling-record pin '**Follow-up:**' (line 931, range 899..939)
  PASS: ruling-record pin '## Ruling <n>' (line 908, range 899..939)
  PASS: ruling-record fragment 'appended, never rewritten' (line 904, range 899..939)
  PASS: answer pin '(orchestrator):' (line 943, range 939..1084)
  PASS: answer pin 'decided (orchestrator)' (line 943, range 939..1084)
  PASS: answer pin 'amend plan:' (line 961, range 939..1084)
  PASS: answer pin 'plan governs:' (line 959, range 939..1084)
  PASS: answer pin 'fix it:' (line 954, range 939..1084)
  PASS: answer pin 'accept:' (line 965, range 939..1084)
  PASS: answer pin '**Amendment' (line 1064, range 939..1084)
  PASS: answer pin '[task <n>/<k>]' (line 991, range 939..1084)
  PASS: answer fragment '(amended by ruling' (line 1050, range 939..1084)
  PASS: answer fragment 'never apply the amendment twice' (line 1070, range 939..1084)
  PASS: answer fragment 'new invocation' (line 1076, range 939..1084)
  PASS: answer fragment 'untagged' (line 951, range 939..1084)
  PASS: answer fragment 'sides against binding plan text' (line 1001, range 939..1084)
  PASS: answer fragment '**The quoted clause, and how it is compared.**' (line 968, range 939..1084)
  PASS: answer fragment 'test whether the quote is a prefix of it' (line 976, range 939..1084)
  PASS: amendment never deletes binding text outright (range 939..1084, line wraps folded)
  PASS: amendment appends an exception scoped to the ruling's item (range 939..1084, line wraps folded)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry pin '## RULING' (line 1090, range 1084..1179)
  PASS: log-entry pin 'Re-dispatch:' (line 1095, range 1084..1179)
  PASS: log-entry pin 'Re-dispatch: none' (line 1134, range 1084..1179)
  PASS: log-entry pin 'Ruled:' (line 1137, range 1084..1179)
  PASS: log-entry pin 'chore(orchestration): <slug> ruling <n>' (line 1113, range 1084..1179)
  PASS: guard pin 'plan governs (orchestrator decision)' (line 1191, range 1179..1215)
  PASS: guard fragment forbidding a byte-equal match (range 1179..1215, line wraps folded)
  PASS: log-entry sentence, byte-exact incl. punctuation (range 1084..1179, line wraps folded, case-sensitive)
  PASS: log-entry sentence carries no '*' emphasis marker
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (range 1084..1179, line wraps folded)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (range 1084..1179, line wraps folded)
  PASS: log-entry fragment 'previous invocation left' (line 1127, range 1084..1179)
  PASS: guard fragment 'durable marker' (line 1176, range 1084..1179)
  PASS: guard fragment 'a Critical is never rejected' (line 1195, range 1179..1215)
  PASS: guard fragment 'quotes its clause' (line 1184, range 1179..1215)
  PASS: guard fragment 'recorded when it is made' (line 1198, range 1179..1215)
  PASS: guard count word is 'Four' (range 1179..1215, line wraps folded, case-sensitive)
  PASS: guard 4 states a user decision is never overturned (line 1201, range 1179..1215)
  PASS: guard 4 fragment 'read your ruling record' (line 1202, range 1179..1215)
  PASS: guard 4 fragment 'recorded answer tagged `(user)`' (line 1203, range 1179..1215)
  PASS: guard 4 fragment 'under the class that first sent it to the user' (line 1207, range 1179..1215)
  PASS: guard 4 fragment 'you never re-answer it in the' (line 1208, range 1179..1215)
  PASS: guard 4 escalates when the clause match is unsure (range 1179..1215, line wraps folded)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (line 276, range 246..300)
  PASS: Phase 4 routes open items to the predicate (line 311, range 300..329)
  PASS: Phase 5 report lists unsettled contradictions (line 342, range 329..351)
  PASS: log-format pin '## RULING' (line 375, range 351..419)
  PASS: log-format pin 'Ruled:' (line 392, range 351..419)
  PASS: log-format pin 'Open:' (line 391, range 351..419)
  PASS: log-format pin 'Owed probe:' (line 393, range 351..419)
  PASS: log-format pin 'ruling <n> follow-up' (line 417, range 351..419)
  PASS: state.md carries the Rulings line (line 429, range 419..432)
  PASS: resume pin '## RULING' (line 468, range 432..588)
  PASS: resume pin 'Ruled:' (line 491, range 432..588)
  PASS: resume pin '**Follow-up:**' (line 489, range 432..588)
  PASS: resume pin '(orchestrator)' (line 500, range 432..588)
  PASS: resume pin '(user)' (line 501, range 432..588)
  PASS: resume pin 'decided (<who>)' (line 530, range 432..588)
  PASS: Resume step 3 no longer names decided (user) alone
  PASS: stop policy fragment 'escalated' (line 1222, range 1215..1236)
  PASS: stop policy fragment 'fork review unavailable' (line 1224, range 1215..1236)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin '— clause:' (line 775, range 758..921)
  PASS: multi-code-review pin 'clause: none' (line 914, range 758..921)
  PASS: multi-code-review pin '(plan-mandated) — at ' (line 775, range 758..921)
  PASS: multi-code-review pin 'cut it to 160 characters' (line 906, range 758..921)
  PASS: multi-code-review pin '**Normalization is one rule:**' (line 904, range 758..921)
  PASS: multi-code-review pin 'tests the quote as a **prefix**' (line 909, range 758..921)
  PASS: multi-code-review pin 'No consumer compares the quote with the raw plan text' (line 910, range 758..921)
  PASS: multi-code-review pin 'decided (orchestrator)' (line 982, range 921..1091)
  PASS: multi-code-review pin 'decided (<who>)' (line 965, range 921..1091)
  PASS: multi-code-review pin 'plan governs (orchestrator decision)' (line 953, range 921..1091)
  PASS: multi-code-review pin 'plan governs (user decision)' (line 952, range 921..1091)
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`' (line 1001, range 921..1091)
  PASS: multi-code-review pin 'unresolved: fix contradicts binding text' (line 971, range 921..1091)
  PASS: M = 1 log-format example carries the clause (line 775, range 766..781)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 796, range 781..800)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..685)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 663, range 623..685)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..685)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..685)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..685)
  PASS: loop-side rule fragment 'never edits plan text' (line 669, range 623..685)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 671, range 623..685)
9. Controller prompt templates (R10)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(user)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 214, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 213, range 209..216)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin '(user)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 136, range 116..177)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 161, range 116..177)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 177, range 171..185)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 178, range 171..185)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 175, range 171..185)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 178, range 171..185)
  PASS: batch-controller Deviation 1 pin '### Question <k>' (line 83, range 79..107)
  PASS: batch-controller Deviation 1 pin '### Conflict <k>' (line 84, range 79..107)
  PASS: batch-controller Deviation 1 pin 'lowest-numbered task' (line 96, range 79..107)
  PASS: batch-controller Deviation 1 pin '.superpowers/sdd/task-<n>-report.md' (line 82, range 79..107)
  PASS: batch-controller Deviation 1 pin 'is settled' (line 99, range 79..107)
  PASS: batch-controller Deviation 1 pin 'Never copy a secret or a credential' (line 103, range 79..107)
  PASS: batch-controller Deviation 1 pin 're-used on the same task' (line 86, range 79..107)
  PASS: batch-controller Deviation 1 pin 'those sections before you write your own' (line 95, range 79..107)
  PASS: batch-controller Deviation 1 pin 'controller failure' (line 102, range 79..107)
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 100, range 79..107)

Results: 156 passed, 0 failed
```

### Commit

`review fixes (autonomous-in-run-decisions, round 3)` — files:
skills/orchestrating-development/SKILL.md, tests/in-run-rulings/run-tests.sh

## Round 5 fixes — second batch (I1–I8, M1–M10, CF1) — 2026-09-04

Commit subject used, as instructed by the fix prompt: `review fixes
(autonomous-in-run-decisions, round 5)`.

### Findings addressed

- **[I1] skills/orchestrating-development/SKILL.md — the `amend plan`
  carve-out, in all four places.** The `irreversible` entry of the closed
  escalation list keeps its trigger and now names the binding set by
  pointing at the definition in "Plan amendment". The three sections that
  contradicted it were reconciled: (a) the `amend plan: …; fix it: …`
  bullet in "The answers, and how a ruling reaches the plan" now says such
  an answer is "never one of yours when the amendment's edit location is
  itself binding text … such an item is `escalated (irreversible)`", and
  that the orchestrator writes only an amendment of reference text, plus a
  user's `amend plan` answer when it arrives on a resume; (b) the Phase 3
  answer sentence "An answer that sides against binding plan text is
  always `amend plan: …`" now continues "and such an answer is never yours
  to rule: the item is `escalated (irreversible)` …, and the `amend plan`
  line reaches the controller as the user's answer on the resume";
  (c) the pre-commit self-check now converts a bare `fix it` whose
  `clause:` names binding text into `escalated (irreversible)`, and keeps
  `amend plan: …; fix it` only for a clause naming reference text;
  (d) the plan-amendment procedure is scoped — "This procedure serves the
  amendments that are still yours — a ruling on **reference** text — and a
  user's `amend plan` answer arriving on a resume" — and its step 1 is now
  "**Edit the named clause in place**", splitting the binding case
  (user-authorised) from the reference case (a ruling of your own). No
  sixth escalation class was added; the label set is unchanged.
- **[I2] skills/orchestrating-development/batch-controller-prompt.md.**
  The section heading now reads
  `## Resume Answer (omit only when the run has recorded no answer at all)`,
  matching the `[RESUME_ANSWER]` placeholder documentation in the same file.
- **[I4] skills/orchestrating-development/SKILL.md, Resume step 3.** The
  `Ruled:`-line construction is now named as the Phase 4 path; for Phase 3
  the answer set is "the full run-wide set defined by
  'The Phase 3 answer set — one rule'": every ruled `[task <n>/<k>]` line
  of the run, for every task, taken from the ruling record, with nothing
  dropped at the `## STOPPED` entry. In both phases a resume-prompt answer
  replaces the ruled line for the same id.
- **[I5] skills/orchestrating-development/SKILL.md, Resume step 3
  crash-window rebuild.** The rebuild now follows "Handling a return as a
  whole" exactly: an `Open:` line for each `escalated` entry of that
  return, and a `Ruled:` line for every ruling of the stopped unit that
  was not escalated — this return's and its earlier returns' alike —
  excluding entries that already carry a `**Follow-up:**` line. The cap
  paragraph's cross-reference was updated to match ("from those entries
  together with the unit's earlier non-escalated rulings").
- **[I6] skills/orchestrating-development/SKILL.md (Phase 3
  discriminator) and batch-controller-prompt.md.** The membership test is
  widened: `<n>` "must be a task number of the plan — an integer that has
  a `### Task <n>` heading in the plan you cheap-scanned in Phase 3 step 1
  — and not only one of this batch's task numbers", with the reason
  stated (the pre-flight review runs over the whole plan, so `<n>` may
  belong to a later batch). The batch template states the same bound once,
  in Deviation 1's pre-flight rule.
- **[I7] skills/orchestrating-development/SKILL.md, guard 4.** The
  escalation label now has a defined fallback: "under the class that first
  sent it to the user — and under `spec wrong` when the entry carrying
  that answer is a `forced` or a `design` one, which has no escalation
  class of its own, so that the label is always one of the five of the
  closed list."
- **[I8] skills/multi-code-review/SKILL.md, "Normalization is one rule".**
  The paragraph now states the same unit as orchestrating-development:
  "the unit compared is one sentence or one list entry, never a whole
  section", and consumers "normalize each sentence and each list entry of
  the plan text at that location the same way, and test the quote as a
  **prefix** of one of them".
- **[M1] skills/orchestrating-development/SKILL.md.** The `of <planned>`
  slot was added to the ruling record's `**Forks:**` field
  (`<k> of <planned> — <lens>: <VERDICT line> …`) and to the `Forks:` line
  of the `## RULING` entry, in both copies of that shape (the
  `## Orchestration Log Format` example and the "RULING log entry" one).
- **[M2] skills/multi-code-review/SKILL.md.** The disposition text is now
  `unresolved: fix contradicts binding text`, with a sentence saying the
  mandatory `— clause:` suffix carries the clause, so it is written once.
- **[M3] skills/orchestrating-development/SKILL.md.** The discriminator's
  parenthetical is now "a dispatch that carries no answer line for this
  task leaves every section of it unanswered".
- **[M4] skills/orchestrating-development/SKILL.md, the cap.** The Phase 3
  count is now "of the same task number, counted on an `Items:` line
  naming that task in either form, `[task <n>]` or `[task <n>/<k>]`".
- **[M5] skills/orchestrating-development/SKILL.md.** The ruling record's
  `**Item:**` template names a Phase 3 item `[task <n>/<k>]`.
- **[M6] skills/orchestrating-development/SKILL.md.** The ruling record
  now says Resume step 3 appends the `**Follow-up:**` line "to **any**
  entry the user later answers, not only to an `escalated` one", naming
  the `forced`/`design` case explicitly.
- **[M7] skills/orchestrating-development/SKILL.md, Resume step 3.** The
  pre-amendment clause is "recovered verbatim from the ruling's own
  commit, `git show <ruling commit>^:<plan path>`, never from the audit
  note, whose prose is not required to quote the original".
- **[M8] skills/orchestrating-development/SKILL.md, Resume step 3.** The
  commit-landed check is now
  `git log --format=%s --grep "<slug> ruling <n>"`, and the text requires
  comparing each printed subject with the full expected string, naming the
  two false positives `--grep` produces (`ruling <n> follow-up`, and
  `ruling 10` for ruling 1).
- **[M9] skills/orchestrating-development/SKILL.md.** The `irreversible`
  entry now uses one definition of binding text — the one "Plan amendment"
  gives — including a pre-note plan's mandated text.
- **[M10] skills/orchestrating-development/SKILL.md.** The entry now says
  a `Global Constraints` location is binding on its face, a `Task <n>`
  location can be either and is read under entry 3 of the read exception,
  and that "never a judgement" bars judging the amendment's effect only.
- **[CF1] skills/orchestrating-development/batch-controller-prompt.md.**
  The pre-flight lowest-numbered-task / report-file rule is now stated
  once, in Deviation 1 ("**Pre-flight rule (one statement):** …"), and the
  First-batch parameter points at it ("under Deviation 1's pre-flight
  rule, which states the task number and the report file once, for both
  places"). The bound chosen for [I6] is stated in that one place.

### New assertions — tests/in-run-rulings/run-tests.sh

No assertion was deleted or weakened. Added, each scoped to the section it
pins:

- section 1: `under entry 3 of the read exception` (folded) and
  `may belong to a later batch` (folded), in the classification range.
- section 4: `<k> of <planned>` in the ruling-record range;
  `not only to an `escalated` one` (folded) there too;
  `escalated (irreversible)` and `never written as a ruling of your own`
  (folded) in the answers range.
- section 5: `escalated (irreversible)`,
  `` `[task <n>]` or `[task <n>/<k>]` `` and `<k> of <planned>` in the
  log-entry range; `which has no escalation class of its own` (folded) in
  the guards range.
- section 6: `The Phase 3 answer set — one rule` added to the resume pin
  loop; `git show <ruling commit>^:<plan path>` and
  `compare each printed subject with the full expected string` (folded) in
  the resume range.
- section 7: `one sentence or one list entry, never a whole section` added
  to the multi-code-review review-log-format pin loop.
- section 9: the batch template's
  `## Resume Answer (omit only when the run has recorded no answer at all)`
  heading; `Pre-flight rule` and `absent from` added to the Deviation 1
  pin loop; `under Deviation 1's pre-flight rule` before the placeholder
  documentation.

Result count went from 156 to 174 checks, all passing.

### Commands run

```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/reviewer-templates/run-tests.sh
```
Exit code: 0
```
1. Harness claims rule is inside the prompt block
  PASS: doc-review template: Harness claims rule inside the prompt block (line 42, block 25..133)
  PASS: code-review template: Harness claims rule inside the prompt block (line 64, block 24..193)
2. Finding-format field spellings
  PASS: doc-review template: field spelling 'harness: tested —'
  PASS: doc-review template: field spelling 'harness: untested —'
  PASS: code-review template: field spelling 'harness: tested —'
  PASS: code-review template: field spelling 'harness: untested —'
3. Controller triage reason strings and completion-report line
  PASS: multi-doc-review SKILL.md: reason string 'harness probe —'
  PASS: multi-doc-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-doc-review SKILL.md: completion-report line 'Harness probes owed:'
  PASS: multi-code-review SKILL.md: reason string 'harness probe —'
  PASS: multi-code-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-code-review SKILL.md: completion-report line 'Harness probes owed:'
4. user-decision guard
  PASS: multi-code-review SKILL.md: guard fragment
5. Rule text drift between the two templates
  PASS: doc-review template: rule extract is non-empty
  PASS: code-review template: rule extract is non-empty
  PASS: rule text identical in both templates
6. Unchanged contracts
  PASS: code-review template: blinding pathspec line
  PASS: code-review template: report marker instruction
  PASS: doc-review template: report marker instruction
7. Ambiguity & testability plan-cell contract targets
  PASS: multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty
  PASS: Ambiguity plan cell: fragment 'no stated contract'
  PASS: Ambiguity plan cell: fragment 'self-pin'
  PASS: Ambiguity plan cell: gate label '**Body authority:**'
8. Body-authority gate label consistency (writing-plans vs multi-doc-review)
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
```

```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/writing-plans/run-tests.sh
```
Exit code: 0
```
1. Contracts and Literal Bodies section (R1)
  PASS: section heading '## Contracts and Literal Bodies' (whole-line match, line 122)
  PASS: exact-content label '**Exact content:**' (rule 4) (line 172, range 170..184)
  PASS: procedural tie-break fragment 'treat the block as not procedural' (rule 1) (line 149, range 129..154)
  PASS: authority-default fragment 'ordinary fix' (rule 3) (line 166, range 163..170)
  PASS: self-pin fragment 'together as one ordinary fix' (rule 5) (line 187, range 184..194)
2. Task Template Contract field (R2)
  PASS: Task Template block carries '**Contract:**' (line 261, block 249..291)
3. Plan Header authority note (R3)
  PASS: Plan Header template carries 'reference implementations' (line 86, block 81..96)
  PASS: Plan Header template carries '**Body authority:**' (line 86, block 81..96)
  PASS: Plan Header note states the closed binding set 'Exactly two things in this plan bind' (line 86, block 81..96)
  PASS: Plan Header note states the exact-content binding condition 'names a pin this plan does not itself write or edit' (line 86, block 81..96)
  PASS: Plan Header note states the residue clause 'Everything else is reference' (line 86, block 81..96)
  PASS: Plan Header note states the non-conflict disposition 'is never a plan conflict: record it against the plan-writing skill' (line 86, block 81..96)
  PASS: Plan Header note states the disposition's scoping guard 'covers the note's own text alone' (line 86, block 81..96)
4. Self-Review contract audit (R4)
  PASS: self-review fragment 'falsifiable' (check 5) (line 338, range 338..340)
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
```

```
bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/in-run-rulings/run-tests.sh
```
Exit code: 0
```
0. Section anchors
  PASS: '## In-run rulings' precedes '## Major-Error Stop Policy' (lines 604..1273)
  PASS: no other '## ' heading (outside a fenced code block) between 604 and 1273
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 604)
  PASS: class or reason label `escalated` (line 633, range 628..738)
  PASS: class or reason label `forced` (line 636, range 628..738)
  PASS: class or reason label `design` (line 641, range 628..738)
  PASS: class or reason label `spec wrong` (line 648, range 628..738)
  PASS: class or reason label `scope` (line 652, range 628..738)
  PASS: class or reason label `irreversible` (line 656, range 628..738)
  PASS: class or reason label `secret` (line 674, range 628..738)
  PASS: class or reason label `chain` (line 680, range 628..738)
  PASS: class or reason label escalated (chain) (line 681, range 628..738)
  PASS: predicate fragment 'escalation wins' (line 634, range 628..738)
  PASS: predicate fragment '### Conflict' (line 708, range 628..738)
  PASS: predicate fragment '### Question' (line 708, range 628..738)
  PASS: predicate fragment 'fatal environment failure' (line 684, range 628..738)
  PASS: predicate fragment 'never `spec wrong`' (line 693, range 628..738)
  PASS: predicate fragment 'handled as a whole' (line 728, range 628..738)
  PASS: predicate fragment 'applied twice' (line 731, range 628..738)
  PASS: irreversible entry pin 'escalated (irreversible)' (line 663, range 628..738)
  PASS: irreversible entry covers an amendment of binding plan text (range 628..738, line wraps folded)
  PASS: irreversible entry triggers on the edit location, not on a judgement (range 628..738, line wraps folded)
  PASS: irreversible entry reads binding-ness from the task section (range 628..738, line wraps folded)
  PASS: discriminator bounds <n> by the plan, not by the batch (range 628..738, line wraps folded)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 766, range 738..786)
  PASS: read-exception fragment 'never a reviewer report file' (line 749, range 738..786)
  PASS: read-exception fragment 'read-only git commands' (line 771, range 738..786)
  PASS: read-exception fragment 'resume step 3' (line 782, range 738..786)
  PASS: read-exception fragment 'nothing else' (line 765, range 738..786)
  PASS: read-exception fragment '40 lines' (line 757, range 738..786)
  PASS: read-exception entry 5 names the ruling-record path (line 760, range 738..786)
  PASS: read-exception entry 5 calls it the file you write yourself (range 738..786, line wraps folded)
  PASS: read-exception entry 5 fragment 'Guard 4 (below) reads it' (line 761, range 738..786)
  PASS: read-exception entry 5 fragment 'earlier answer tagged `(user)` on the same clause' (line 762, range 738..786)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 830, range 604..1273)
  PASS: fork pin '<!-- multi-review report -->' (line 877, range 604..1273)
  PASS: fork pin 'fork-<lens>' (line 831, range 604..1273)
  PASS: fork pin 'fork review unavailable' (line 917, range 604..1273)
  PASS: fork pin 'contradiction: unsettled' (line 903, range 604..1273)
  PASS: fork pin 'VERDICT:' (line 881, range 786..929)
  PASS: fork pin 'TABLED:' (line 884, range 786..929)
  PASS: fork fragment 'not a debate' (line 808, range 786..929)
  PASS: fork fragment 'never pass conversation history' (line 828, range 786..929)
  PASS: fork fragment 'action verb followed by a skill name' (line 887, range 786..929)
  PASS: fork fragment 'in parallel, in one message' (line 788, range 786..929)
  PASS: fork fragment 'evidence consistency' (line 797, range 786..929)
  PASS: fork fragment 'general-purpose' (line 837, range 786..929)
  PASS: fork naming never uses an orch- name (line 832, range 786..929)
  PASS: Guard Interaction names the forks' marker (line 1304, range 1294..1309)
  PASS: Guard Interaction names the forks' return marker exactly (line 1303, range 1294..1309)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record pin '-open-decisions.md' (line 931, range 929..973)
  PASS: ruling-record pin '**Follow-up:**' (line 961, range 929..973)
  PASS: ruling-record pin '## Ruling <n>' (line 938, range 929..973)
  PASS: ruling-record fragment 'appended, never rewritten' (line 934, range 929..973)
  PASS: ruling-record Forks field carries the planned count (line 944, range 929..973)
  PASS: ruling record widens the follow-up to any answered entry (range 929..973, line wraps folded)
  PASS: answer pin '(orchestrator):' (line 977, range 973..1133)
  PASS: answer pin 'decided (orchestrator)' (line 977, range 973..1133)
  PASS: answer pin 'amend plan:' (line 995, range 973..1133)
  PASS: answer pin 'plan governs:' (line 993, range 973..1133)
  PASS: answer pin 'fix it:' (line 988, range 973..1133)
  PASS: answer pin 'accept:' (line 1004, range 973..1133)
  PASS: answer pin '**Amendment' (line 1113, range 973..1133)
  PASS: answer pin '[task <n>/<k>]' (line 1030, range 973..1133)
  PASS: answer fragment '(amended by ruling' (line 1099, range 973..1133)
  PASS: answer fragment 'never apply the amendment twice' (line 1119, range 973..1133)
  PASS: answer fragment 'new invocation' (line 1125, range 973..1133)
  PASS: answer fragment 'untagged' (line 985, range 973..1133)
  PASS: answer fragment 'sides against binding plan text' (line 1040, range 973..1133)
  PASS: answer fragment '**The quoted clause, and how it is compared.**' (line 1007, range 973..1133)
  PASS: answer fragment 'test whether the quote is a prefix of it' (line 1015, range 973..1133)
  PASS: amendment never deletes binding text outright (range 973..1133, line wraps folded)
  PASS: amendment appends an exception scoped to the ruling's item (range 973..1133, line wraps folded)
  PASS: answer pin 'escalated (irreversible)' (line 999, range 973..1133)
  PASS: the amendment procedure is scoped to the amendments still the orchestrator's (range 973..1133, line wraps folded)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry pin '## RULING' (line 1139, range 1133..1234)
  PASS: log-entry pin 'Re-dispatch:' (line 1144, range 1133..1234)
  PASS: log-entry pin 'Re-dispatch: none' (line 1186, range 1133..1234)
  PASS: log-entry pin 'Ruled:' (line 1189, range 1133..1234)
  PASS: log-entry pin 'chore(orchestration): <slug> ruling <n>' (line 1165, range 1133..1234)
  PASS: guard pin 'plan governs (orchestrator decision)' (line 1246, range 1234..1273)
  PASS: guard fragment forbidding a byte-equal match (range 1234..1273, line wraps folded)
  PASS: log-entry sentence, byte-exact incl. punctuation (range 1133..1234, line wraps folded, case-sensitive)
  PASS: log-entry sentence carries no '*' emphasis marker
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (range 1133..1234, line wraps folded)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (range 1133..1234, line wraps folded)
  PASS: log-entry fragment 'previous invocation left' (line 1179, range 1133..1234)
  PASS: self-check escalates a bare fix it on binding text (line 1159, range 1133..1234)
  PASS: cap counts a Phase 3 task in either line form (line 1200, range 1133..1234)
  PASS: RULING Forks line carries the planned count (line 1143, range 1133..1234)
  PASS: guard fragment 'durable marker' (line 1231, range 1133..1234)
  PASS: guard fragment 'a Critical is never rejected' (line 1250, range 1234..1273)
  PASS: guard fragment 'quotes its clause' (line 1239, range 1234..1273)
  PASS: guard fragment 'recorded when it is made' (line 1253, range 1234..1273)
  PASS: guard count word is 'Four' (range 1234..1273, line wraps folded, case-sensitive)
  PASS: guard 4 states a user decision is never overturned (line 1256, range 1234..1273)
  PASS: guard 4 fragment 'read your ruling record' (line 1257, range 1234..1273)
  PASS: guard 4 fragment 'recorded answer tagged `(user)`' (line 1258, range 1234..1273)
  PASS: guard 4 fragment 'under the class that first sent it to the user' (line 1262, range 1234..1273)
  PASS: guard 4 fragment 'you never re-answer it in the' (line 1266, range 1234..1273)
  PASS: guard 4 escalates when the clause match is unsure (range 1234..1273, line wraps folded)
  PASS: guard 4 names a fallback class for a forced or design entry (range 1234..1273, line wraps folded)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (line 276, range 246..300)
  PASS: Phase 4 routes open items to the predicate (line 311, range 300..329)
  PASS: Phase 5 report lists unsettled contradictions (line 342, range 329..351)
  PASS: log-format pin '## RULING' (line 375, range 351..419)
  PASS: log-format pin 'Ruled:' (line 392, range 351..419)
  PASS: log-format pin 'Open:' (line 391, range 351..419)
  PASS: log-format pin 'Owed probe:' (line 393, range 351..419)
  PASS: log-format pin 'ruling <n> follow-up' (line 417, range 351..419)
  PASS: state.md carries the Rulings line (line 429, range 419..432)
  PASS: resume pin '## RULING' (line 468, range 432..604)
  PASS: resume pin 'Ruled:' (line 495, range 432..604)
  PASS: resume pin '**Follow-up:**' (line 498, range 432..604)
  PASS: resume pin '(orchestrator)' (line 507, range 432..604)
  PASS: resume pin '(user)' (line 508, range 432..604)
  PASS: resume pin 'decided (<who>)' (line 546, range 432..604)
  PASS: resume pin 'The Phase 3 answer set — one rule' (line 510, range 432..604)
  PASS: resume recovers the pre-amendment clause from the ruling commit (line 521, range 432..604)
  PASS: resume compares the printed subject with the full expected string (range 432..604, line wraps folded)
  PASS: Resume step 3 no longer names decided (user) alone
  PASS: stop policy fragment 'escalated' (line 1280, range 1273..1294)
  PASS: stop policy fragment 'fork review unavailable' (line 1282, range 1273..1294)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin '— clause:' (line 775, range 758..924)
  PASS: multi-code-review pin 'clause: none' (line 917, range 758..924)
  PASS: multi-code-review pin '(plan-mandated) — at ' (line 775, range 758..924)
  PASS: multi-code-review pin 'cut it to 160 characters' (line 908, range 758..924)
  PASS: multi-code-review pin '**Normalization is one rule:**' (line 904, range 758..924)
  PASS: multi-code-review pin 'one sentence or one list entry, never a whole section' (line 905, range 758..924)
  PASS: multi-code-review pin 'tests the quote as a **prefix**' (line 912, range 758..924)
  PASS: multi-code-review pin 'No consumer compares the quote with the raw plan text' (line 913, range 758..924)
  PASS: multi-code-review pin 'decided (orchestrator)' (line 988, range 924..1097)
  PASS: multi-code-review pin 'decided (<who>)' (line 968, range 924..1097)
  PASS: multi-code-review pin 'plan governs (orchestrator decision)' (line 956, range 924..1097)
  PASS: multi-code-review pin 'plan governs (user decision)' (line 955, range 924..1097)
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`' (line 1007, range 924..1097)
  PASS: multi-code-review pin 'unresolved: fix contradicts binding text' (line 974, range 924..1097)
  PASS: M = 1 log-format example carries the clause (line 775, range 766..781)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 796, range 781..800)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..685)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 663, range 623..685)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..685)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..685)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..685)
  PASS: loop-side rule fragment 'never edits plan text' (line 669, range 623..685)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 671, range 623..685)
9. Controller prompt templates (R10)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(user)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 214, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 213, range 209..216)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin '(user)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 136, range 116..177)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 161, range 116..177)
  PASS: batch-controller Resume Answer heading states the omit condition (line 71, range 1..175)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 181, range 175..189)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 182, range 175..189)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 179, range 175..189)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 182, range 175..189)
  PASS: First-batch parameter defers to Deviation 1's pre-flight rule (line 63, range 1..175)
  PASS: batch-controller Deviation 1 pin '### Question <k>' (line 81, range 77..111)
  PASS: batch-controller Deviation 1 pin '### Conflict <k>' (line 82, range 77..111)
  PASS: batch-controller Deviation 1 pin 'lowest-numbered task' (line 95, range 77..111)
  PASS: batch-controller Deviation 1 pin 'Pre-flight rule' (line 93, range 77..111)
  PASS: batch-controller Deviation 1 pin 'absent from' (line 99, range 77..111)
  PASS: batch-controller Deviation 1 pin '.superpowers/sdd/task-<n>-report.md' (line 80, range 77..111)
  PASS: batch-controller Deviation 1 pin 'is settled' (line 103, range 77..111)
  PASS: batch-controller Deviation 1 pin 'Never copy a secret or a credential' (line 107, range 77..111)
  PASS: batch-controller Deviation 1 pin 're-used on the same task' (line 84, range 77..111)
  PASS: batch-controller Deviation 1 pin 'those sections before you write your own' (line 93, range 77..111)
  PASS: batch-controller Deviation 1 pin 'controller failure' (line 106, range 77..111)
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 104, range 77..111)

Results: 174 passed, 0 failed
```

### Commit

`review fixes (autonomous-in-run-decisions, round 5)` — files:
skills/orchestrating-development/SKILL.md,
skills/orchestrating-development/batch-controller-prompt.md,
skills/multi-code-review/SKILL.md, tests/in-run-rulings/run-tests.sh

## Round 6 fixes — 2026-09-04

Findings I1–I11 and M1–M8 of round 6. Files touched:
`skills/orchestrating-development/SKILL.md`,
`skills/orchestrating-development/batch-controller-prompt.md`,
`skills/multi-code-review/SKILL.md`,
`tests/in-run-rulings/run-tests.sh`.

### Findings addressed

- **I1 — the revert step never produced a commit hash.** Resume step 3's
  revert sentence now carries its own lookup, in a **Finding that commit, and
  reading it** clause: `git log --format="%H %s" --grep "<slug> ruling <n>"`
  prints `<hash> <subject>` lines, only the lines whose subject equals the
  whole expected string `chore(orchestration): <slug> ruling <n>` are kept
  (the same exact-subject filter the landed-check already states, so
  `ruling 10`, `ruling 11` and `ruling 1 follow-up` are dropped for
  `<n>` = 1), exactly one line must survive — zero or more than one is a
  major error — and `<ruling commit>` is that line's hash. The clause also
  states that `git show <ruling commit>^:<plan path>` prints the WHOLE plan
  file: only the clause's own text is copied out of it, and its output is
  never written over the plan file.
- **I2 — the two rules cancelled each other.** `batch-controller-prompt.md`
  Deviation 1 no longer identifies a task's first dispatch of this run by the
  absence of a `[task <n>…]` line. It keys on work this run produced — every
  checkbox under `### Task <n>` unticked AND no completed ledger line naming
  the task (the two signals Deviation 4 already reads) — and says explicitly
  that the answer line is not the signal, because the orchestrator fills one
  in for every task it has ruled on, dispatched or not.
- **I3 — two missing notices matched no case.** The lost-return bound in
  `### Fork review for a design item` is now stated over the ROUND: as soon
  as at least one notice of the round has arrived, every lens still missing
  counts as one loss at that same moment and each is re-dispatched once, in
  one message; the same test then applies to the re-dispatch round, after
  which every lens still missing is left out for good. The `design` ruling
  still needs two usable returns or stops with `fork review unavailable`.
- **I4 — `binding` was undefined in the loop's file.** The refusal rule in
  `multi-code-review/SKILL.md` now carries the test itself: `Global
  Constraints` is binding on its face; a `Task <n>` clause is binding only
  when the quoted clause sits in that task's `**Exact content:**` block (or
  is mandated text in a plan written before the 7.7.0 Body-authority note);
  every other `Task <n>` clause and `— clause: none` are not binding. A
  reading that leaves the loop unsure resolves to reference text, so the two
  actors cannot deadlock over one item both agreed to fix.
- **I5 — the `irreversible` trigger had no Phase 3 form.** The entry now
  states it: a Phase 3 item is a `### Conflict <k>` or `### Question <k>`
  section with no disposition line and no `— clause:`, so the edit location
  is the plan location that section names on the plan side, read under entry
  3 of the read exception; binding when it is a `**Global Constraints:**`
  entry, an `**Exact content:**` block, or mandated text in a pre-note plan,
  and reference text otherwise.
- **I6 — a re-derived pre-flight conflict got a new number.** Both the
  section-numbering rule in `## In-run rulings` and Deviation 1 of the batch
  template now say that before allocating a new `<k>` the controller compares
  the conflict with the answered `[task <n>/<k>]` lines of this dispatch's
  `## Resume Answer`; when one answers that same conflict (its answer names
  the same plan text) the `<k>` is re-used, the answer applied, and no
  `BLOCKED` returned. A new `<k>` is allocated only for a conflict no
  answered line matches.
- **I7 — no write order, and no detection of a half-written ruling.** The
  ruling record now fixes the order — ruling-record entry first, then the
  `## RULING` log entry, then the plan amendment, all three in the single
  ruling commit — and explains what the order bounds. Resume step 3 gained
  the matching check: an `(amended by ruling <n>)` marker in the plan with no
  `## Ruling <n>` entry in the ruling record is an inconsistent state
  whatever the log ends with; the marked edit is reverted and its
  `**Amendment <n>` note deleted, never left standing.
- **I8 / M3 — a later item's forks inherit the earlier verdicts.** The
  anchoring guard now states that the inheritance reaches across items and
  across rounds, and gives one remedy: only the FIRST `design` item of a
  return uses the fork path; every later item's reviewers and every tie-break
  reviewer are dispatched as fresh `general-purpose` subagents on the path
  the section already defines for a platform without a `fork` type.
  Consolidation reasoning for an item is written only after that item's round
  has fully returned.
- **I9 — the bare `[task <n>]` form was both a shorthand and a written
  form.** The definition now says every line the orchestrator writes uses
  `[task <n>/<k>]` — answer, `Open:` and `Ruled:` alike — and that a bare
  user answer is resolved before it travels: it answers the one open section
  when exactly one is open, and is otherwise ambiguous (present it and stop),
  never defaulted to `/1`. The Orchestration Log Format no longer permits the
  bare form on an `Open:` line, and the Phase 3 answer example writes the
  user line with its `<k>`.
- **I10 — the `"` replacement was missing from the normalization rule.** Both
  files now enumerate three operations in the one rule: replace each ` — `
  and each ` ← ` with one space, replace each `"` with `'`, then cut to 160
  characters; `multi-code-review` adds that a consumer skipping the `"`
  replacement fails every clause holding a double quotation mark. The
  amendment procedure gained its missing branch: no match under the prefix
  rule is never an edit by guess — no edit is made, the ruling is not
  recorded as applied, an amendment of the orchestrator's own escalates as
  `escalated (spec wrong)`, and a user's `amend plan` answer with no target
  is presented back as a blocking question.
- **I11 — the read exception's closed list excluded its own consumers.** Its
  opening sentence now names three purposes (classifying an open item,
  resuming a stopped run, writing the Phase 5 report), entry 4 permits the
  orchestrator alone — never a fork — the two ruling-commit commands when
  Resume step 3 reverts an amendment, and entry 5 names the Resume rebuild
  and the Phase 5 count. The list keeps five entries and its closing
  "Nothing else".
- **M1 — the two `## STOPPED` paths differed.** "Handling a return as a
  whole" now carries the same Follow-up exclusion as the Resume rebuild:
  never an entry that already carries a `**Follow-up:**` line, which the user
  answered at an earlier stop.
- **M2 — an `unresolved:` addendum line had no listed shape.** The
  no-annotation exception in `multi-code-review`'s log format now lists
  addendum `unresolved: …` beside `decided (<who>): …` and addendum
  `fixed …`.
- **M4 — the Phase 3 cap matched substrings.** The cap now says the task is
  matched as the whole bracketed token — `[task <n>]` exactly, or
  `[task <n>/` as a prefix — so task 1 counts no `[task 12/1]` and no
  `[task 10]` line.
- **M5 — `Re-dispatch:` line vs value.** All three places now test the
  `Re-dispatch:` VALUE, with the written form of the whole line given beside
  it.
- **M6 — guard 1 could be satisfied by the loop's own clause.** The guard now
  states that a quotable clause is not by itself a reason to reject: what it
  tests is that the clause makes the FINDING non-binding, and the forced test
  still has to pass.
- **M7 — `— clause: none` under guard 4.** The guard now says a
  `— clause: none` follow-up quotes no clause and matches nothing, and that
  only non-empty quoted clauses are compared, so a clause-less item is never
  escalated by it.
- **M8 — the git allowlist forbade the wrong flags.** Both statements (the
  read exception and the fork prompt) now mandate
  `git diff --no-ext-diff --no-textconv <BASE>..HEAD -- <path>`, saying that
  the helper programs run by DEFAULT and that both options turn them off;
  `--output` stays forbidden on all three forms.

### New assertions — tests/in-run-rulings/run-tests.sh

34 assertions added, each scoped to the subsection that holds the rule it
pins (byte pins in "exact" mode for literal labels and command forms,
case-insensitive fragments — folded across line wraps where the sentence
wraps — for free text):

- section 1: the Phase 3 form of the `irreversible` trigger (2), the bare-id
  rule and its no-default-to-`/1` clause (2, scoped to the `## In-run
  rulings` intro range above the classification subsection);
- section 2: the read exception's three purposes, its ruling-commit read, and
  the negative diff flags (3);
- section 3: the negative diff flags in the fork prompt, the round-wide lost
  return bound (2), the first-item-only fork path, and the deferred
  consolidation reasoning (5);
- section 4: the fixed write order, the `"` replacement in the orchestrator's
  normalization sentence, the no-match escalation, and the re-derived
  conflict number (4);
- section 5: the whole-bracketed-token cap match, the `Re-dispatch:` value
  test, the Follow-up exclusion on a stop, guard 1's "not by itself a
  reason", and guard 4's clause-less follow-up (5);
- section 6: the ruling-commit lookup command, its exactly-one-line filter,
  the copy-the-clause-only rule, and the orphan-marker revert (4);
- section 7: the `"` replacement and the three-operation statement in
  `multi-code-review`, the `unresolved:` addendum shape, and the
  binding-text test with its `**Exact content:**` anchor (5);
- section 9: the two first-dispatch signals in Deviation 1 and the two
  re-derived-conflict pins (4).

One existing assertion needed no rewording, but its pinned phrase would have
been split by a line wrap: `cut it to 160 characters` in
`multi-code-review/SKILL.md` was kept whole on one line when the `"`
replacement was inserted into the same sentence. No assertion was deleted or
weakened.

### Mutation check on the new needles

Each new rule's own text was deleted in turn (33 distinct fragments, one per
new assertion group) and `tests/in-run-rulings/run-tests.sh` was re-run: every
mutation made the suite fail, and the file was restored after each run. No new
assertion passes on text that survives deleting its rule.

### Commands run

```
$ bash tests/reviewer-templates/run-tests.sh
1. Harness claims rule is inside the prompt block
  PASS: doc-review template: Harness claims rule inside the prompt block (line 42, block 25..133)
  PASS: code-review template: Harness claims rule inside the prompt block (line 64, block 24..193)
2. Finding-format field spellings
  PASS: doc-review template: field spelling 'harness: tested —'
  PASS: doc-review template: field spelling 'harness: untested —'
  PASS: code-review template: field spelling 'harness: tested —'
  PASS: code-review template: field spelling 'harness: untested —'
3. Controller triage reason strings and completion-report line
  PASS: multi-doc-review SKILL.md: reason string 'harness probe —'
  PASS: multi-doc-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-doc-review SKILL.md: completion-report line 'Harness probes owed:'
  PASS: multi-code-review SKILL.md: reason string 'harness probe —'
  PASS: multi-code-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-code-review SKILL.md: completion-report line 'Harness probes owed:'
4. user-decision guard
  PASS: multi-code-review SKILL.md: guard fragment
5. Rule text drift between the two templates
  PASS: doc-review template: rule extract is non-empty
  PASS: code-review template: rule extract is non-empty
  PASS: rule text identical in both templates
6. Unchanged contracts
  PASS: code-review template: blinding pathspec line
  PASS: code-review template: report marker instruction
  PASS: doc-review template: report marker instruction
7. Ambiguity & testability plan-cell contract targets
  PASS: multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty
  PASS: Ambiguity plan cell: fragment 'no stated contract'
  PASS: Ambiguity plan cell: fragment 'self-pin'
  PASS: Ambiguity plan cell: gate label '**Body authority:**'
8. Body-authority gate label consistency (writing-plans vs multi-doc-review)
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
(exit 0)

$ bash tests/writing-plans/run-tests.sh
1. Contracts and Literal Bodies section (R1)
  PASS: section heading '## Contracts and Literal Bodies' (whole-line match, line 122)
  PASS: exact-content label '**Exact content:**' (rule 4) (line 172, range 170..184)
  PASS: procedural tie-break fragment 'treat the block as not procedural' (rule 1) (line 149, range 129..154)
  PASS: authority-default fragment 'ordinary fix' (rule 3) (line 166, range 163..170)
  PASS: self-pin fragment 'together as one ordinary fix' (rule 5) (line 187, range 184..194)
2. Task Template Contract field (R2)
  PASS: Task Template block carries '**Contract:**' (line 261, block 249..291)
3. Plan Header authority note (R3)
  PASS: Plan Header template carries 'reference implementations' (line 86, block 81..96)
  PASS: Plan Header template carries '**Body authority:**' (line 86, block 81..96)
  PASS: Plan Header note states the closed binding set 'Exactly two things in this plan bind' (line 86, block 81..96)
  PASS: Plan Header note states the exact-content binding condition 'names a pin this plan does not itself write or edit' (line 86, block 81..96)
  PASS: Plan Header note states the residue clause 'Everything else is reference' (line 86, block 81..96)
  PASS: Plan Header note states the non-conflict disposition 'is never a plan conflict: record it against the plan-writing skill' (line 86, block 81..96)
  PASS: Plan Header note states the disposition's scoping guard 'covers the note's own text alone' (line 86, block 81..96)
4. Self-Review contract audit (R4)
  PASS: self-review fragment 'falsifiable' (check 5) (line 338, range 338..340)
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
(exit 0)

$ bash tests/in-run-rulings/run-tests.sh
0. Section anchors
  PASS: '## In-run rulings' precedes '## Major-Error Stop Policy' (lines 623..1377)
  PASS: no other '## ' heading (outside a fenced code block) between 623 and 1377
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 623)
  PASS: class or reason label `escalated` (line 658, range 653..772)
  PASS: class or reason label `forced` (line 661, range 653..772)
  PASS: class or reason label `design` (line 666, range 653..772)
  PASS: class or reason label `spec wrong` (line 673, range 653..772)
  PASS: class or reason label `scope` (line 677, range 653..772)
  PASS: class or reason label `irreversible` (line 681, range 653..772)
  PASS: class or reason label `secret` (line 708, range 653..772)
  PASS: class or reason label `chain` (line 714, range 653..772)
  PASS: class or reason label escalated (chain) (line 715, range 653..772)
  PASS: predicate fragment 'escalation wins' (line 659, range 653..772)
  PASS: predicate fragment '### Conflict' (line 699, range 653..772)
  PASS: predicate fragment '### Question' (line 700, range 653..772)
  PASS: predicate fragment 'fatal environment failure' (line 718, range 653..772)
  PASS: predicate fragment 'never `spec wrong`' (line 727, range 653..772)
  PASS: predicate fragment 'handled as a whole' (line 762, range 653..772)
  PASS: predicate fragment 'applied twice' (line 765, range 653..772)
  PASS: irreversible entry pin 'escalated (irreversible)' (line 688, range 653..772)
  PASS: irreversible entry covers an amendment of binding plan text (range 653..772, line wraps folded)
  PASS: irreversible entry triggers on the edit location, not on a judgement (range 653..772, line wraps folded)
  PASS: irreversible entry reads binding-ness from the task section (range 653..772, line wraps folded)
  PASS: discriminator bounds <n> by the plan, not by the batch (range 653..772, line wraps folded)
  PASS: irreversible entry states its Phase 3 form (range 653..772, line wraps folded)
  PASS: Phase 3 trigger reads the location the conflict section names (range 653..772, line wraps folded)
  PASS: bare task id is never a form the orchestrator writes (range 623..653, line wraps folded)
  PASS: a bare user answer is resolved, never defaulted to section 1 (range 623..653, line wraps folded)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 807, range 772..830)
  PASS: read-exception fragment 'never a reviewer report file' (line 785, range 772..830)
  PASS: read-exception fragment 'read-only git commands' (line 812, range 772..830)
  PASS: read-exception fragment 'resume step 3' (line 777, range 772..830)
  PASS: read-exception fragment 'nothing else' (line 806, range 772..830)
  PASS: read-exception fragment '40 lines' (line 793, range 772..830)
  PASS: read-exception entry 5 names the ruling-record path (line 799, range 772..830)
  PASS: read-exception entry 5 calls it the file you write yourself (range 772..830, line wraps folded)
  PASS: read-exception entry 5 fragment 'Guard 4 (below) reads it' (line 800, range 772..830)
  PASS: read-exception entry 5 fragment 'earlier answer tagged `(user)` on the same clause' (line 801, range 772..830)
  PASS: read exception names its three purposes (range 772..830, line wraps folded)
  PASS: read exception permits the ruling-commit read for the orchestrator (line 797, range 772..830)
  PASS: fork diff form mandates the negative flags (line 817, range 772..830)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 887, range 623..1377)
  PASS: fork pin '<!-- multi-review report -->' (line 935, range 623..1377)
  PASS: fork pin 'fork-<lens>' (line 879, range 623..1377)
  PASS: fork pin 'fork review unavailable' (line 975, range 623..1377)
  PASS: fork pin 'contradiction: unsettled' (line 961, range 623..1377)
  PASS: fork pin 'VERDICT:' (line 939, range 830..994)
  PASS: fork pin 'TABLED:' (line 942, range 830..994)
  PASS: fork fragment 'not a debate' (line 852, range 830..994)
  PASS: fork fragment 'never pass conversation history' (line 885, range 830..994)
  PASS: fork fragment 'action verb followed by a skill name' (line 945, range 830..994)
  PASS: fork fragment 'in parallel, in one message' (line 832, range 830..994)
  PASS: fork fragment 'evidence consistency' (line 841, range 830..994)
  PASS: fork fragment 'general-purpose' (line 877, range 830..994)
  PASS: fork naming never uses an orch- name (line 889, range 830..994)
  PASS: Guard Interaction names the forks' marker (line 1408, range 1398..1413)
  PASS: Guard Interaction names the forks' return marker exactly (line 1407, range 1398..1413)
  PASS: fork prompt mandates the negative diff flags (line 927, range 830..994)
  PASS: lost-return bound is stated over the round (range 830..994, line wraps folded)
  PASS: every still-missing lens of a round is lost at the same moment (range 830..994, line wraps folded)
  PASS: only the first design item uses the fork path (range 830..994, line wraps folded)
  PASS: consolidation reasoning waits for the item's round (range 830..994, line wraps folded)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record pin '-open-decisions.md' (line 996, range 994..1045)
  PASS: ruling-record pin '**Follow-up:**' (line 1033, range 994..1045)
  PASS: ruling-record pin '## Ruling <n>' (line 1003, range 994..1045)
  PASS: ruling-record fragment 'appended, never rewritten' (line 999, range 994..1045)
  PASS: ruling-record Forks field carries the planned count (line 1009, range 994..1045)
  PASS: ruling record widens the follow-up to any answered entry (range 994..1045, line wraps folded)
  PASS: answer pin '(orchestrator):' (line 1049, range 1045..1225)
  PASS: answer pin 'decided (orchestrator)' (line 1049, range 1045..1225)
  PASS: answer pin 'amend plan:' (line 1067, range 1045..1225)
  PASS: answer pin 'plan governs:' (line 1065, range 1045..1225)
  PASS: answer pin 'fix it:' (line 1060, range 1045..1225)
  PASS: answer pin 'accept:' (line 1076, range 1045..1225)
  PASS: answer pin '**Amendment' (line 1197, range 1045..1225)
  PASS: answer pin '[task <n>/<k>]' (line 1103, range 1045..1225)
  PASS: answer fragment '(amended by ruling' (line 1183, range 1045..1225)
  PASS: answer fragment 'never apply the amendment twice' (line 1203, range 1045..1225)
  PASS: answer fragment 'new invocation' (line 1217, range 1045..1225)
  PASS: answer fragment 'untagged' (line 1057, range 1045..1225)
  PASS: answer fragment 'sides against binding plan text' (line 1113, range 1045..1225)
  PASS: answer fragment '**The quoted clause, and how it is compared.**' (line 1079, range 1045..1225)
  PASS: answer fragment 'test whether the quote is a prefix of it' (line 1088, range 1045..1225)
  PASS: amendment never deletes binding text outright (range 1045..1225, line wraps folded)
  PASS: amendment appends an exception scoped to the ruling's item (range 1045..1225, line wraps folded)
  PASS: answer pin 'escalated (irreversible)' (line 1071, range 1045..1225)
  PASS: the amendment procedure is scoped to the amendments still the orchestrator's (range 1045..1225, line wraps folded)
  PASS: ruling writes have a fixed order (range 994..1045, line wraps folded)
  PASS: normalization also replaces a double quotation mark (range 1045..1225, line wraps folded)
  PASS: amendment lookup escalates when no clause matches (range 1045..1225, line wraps folded)
  PASS: a re-derived conflict keeps its answered number (range 1045..1225, line wraps folded)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry pin '## RULING' (line 1231, range 1225..1329)
  PASS: log-entry pin 'Re-dispatch:' (line 1236, range 1225..1329)
  PASS: log-entry pin 'Re-dispatch: none' (line 1278, range 1225..1329)
  PASS: log-entry pin 'Ruled:' (line 1281, range 1225..1329)
  PASS: log-entry pin 'chore(orchestration): <slug> ruling <n>' (line 1257, range 1225..1329)
  PASS: guard pin 'plan governs (orchestrator decision)' (line 1341, range 1329..1377)
  PASS: guard fragment forbidding a byte-equal match (range 1329..1377, line wraps folded)
  PASS: log-entry sentence, byte-exact incl. punctuation (range 1225..1329, line wraps folded, case-sensitive)
  PASS: log-entry sentence carries no '*' emphasis marker
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (range 1225..1329, line wraps folded)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (range 1225..1329, line wraps folded)
  PASS: log-entry fragment 'previous invocation left' (line 1271, range 1225..1329)
  PASS: self-check escalates a bare fix it on binding text (line 1251, range 1225..1329)
  PASS: cap counts a Phase 3 task in either line form (line 1293, range 1225..1329)
  PASS: RULING Forks line carries the planned count (line 1235, range 1225..1329)
  PASS: guard fragment 'durable marker' (line 1326, range 1225..1329)
  PASS: guard fragment 'a Critical is never rejected' (line 1351, range 1329..1377)
  PASS: guard fragment 'quotes its clause' (line 1334, range 1329..1377)
  PASS: guard fragment 'recorded when it is made' (line 1354, range 1329..1377)
  PASS: guard count word is 'Four' (range 1329..1377, line wraps folded, case-sensitive)
  PASS: guard 4 states a user decision is never overturned (line 1357, range 1329..1377)
  PASS: guard 4 fragment 'read your ruling record' (line 1358, range 1329..1377)
  PASS: guard 4 fragment 'recorded answer tagged `(user)`' (line 1359, range 1329..1377)
  PASS: guard 4 fragment 'under the class that first sent it to the user' (line 1363, range 1329..1377)
  PASS: guard 4 fragment 'you never re-answer it in the' (line 1367, range 1329..1377)
  PASS: guard 4 escalates when the clause match is unsure (range 1329..1377, line wraps folded)
  PASS: guard 4 names a fallback class for a forced or design entry (range 1329..1377, line wraps folded)
  PASS: cap matches the whole bracketed token (line 1294, range 1225..1329)
  PASS: cap tests the Re-dispatch value, not the line's first word (range 1225..1329, line wraps folded)
  PASS: a stop skips an entry already carrying a follow-up (range 1225..1329, line wraps folded)
  PASS: guard 1 says a quotable clause is not by itself a reason (range 1329..1377, line wraps folded)
  PASS: guard 4 ignores a clause-less follow-up (range 1329..1377, line wraps folded)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (line 276, range 246..300)
  PASS: Phase 4 routes open items to the predicate (line 311, range 300..329)
  PASS: Phase 5 report lists unsettled contradictions (line 342, range 329..351)
  PASS: log-format pin '## RULING' (line 375, range 351..420)
  PASS: log-format pin 'Ruled:' (line 392, range 351..420)
  PASS: log-format pin 'Open:' (line 391, range 351..420)
  PASS: log-format pin 'Owed probe:' (line 393, range 351..420)
  PASS: log-format pin 'ruling <n> follow-up' (line 418, range 351..420)
  PASS: state.md carries the Rulings line (line 430, range 420..433)
  PASS: resume pin '## RULING' (line 469, range 433..623)
  PASS: resume pin 'Ruled:' (line 502, range 433..623)
  PASS: resume pin '**Follow-up:**' (line 505, range 433..623)
  PASS: resume pin '(orchestrator)' (line 514, range 433..623)
  PASS: resume pin '(user)' (line 515, range 433..623)
  PASS: resume pin 'decided (<who>)' (line 565, range 433..623)
  PASS: resume pin 'The Phase 3 answer set — one rule' (line 517, range 433..623)
  PASS: resume recovers the pre-amendment clause from the ruling commit (line 541, range 433..623)
  PASS: resume compares the printed subject with the full expected string (range 433..623, line wraps folded)
  PASS: Resume step 3 no longer names decided (user) alone
  PASS: resume ruling-commit lookup prints the hash (line 533, range 433..623)
  PASS: resume ruling-commit lookup keeps exactly one subject (range 433..623, line wraps folded)
  PASS: resume copies the clause, never the whole printed file (range 433..623, line wraps folded)
  PASS: resume reverts an orphan amendment marker (range 433..623, line wraps folded)
  PASS: stop policy fragment 'escalated' (line 1384, range 1377..1398)
  PASS: stop policy fragment 'fork review unavailable' (line 1386, range 1377..1398)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin '— clause:' (line 775, range 758..928)
  PASS: multi-code-review pin 'clause: none' (line 921, range 758..928)
  PASS: multi-code-review pin '(plan-mandated) — at ' (line 775, range 758..928)
  PASS: multi-code-review pin 'cut it to 160 characters' (line 910, range 758..928)
  PASS: multi-code-review pin '**Normalization is one rule:**' (line 905, range 758..928)
  PASS: multi-code-review pin 'one sentence or one list entry, never a whole section' (line 906, range 758..928)
  PASS: multi-code-review pin 'tests the quote as a **prefix**' (line 916, range 758..928)
  PASS: multi-code-review pin 'No consumer compares the quote with the raw plan text' (line 917, range 758..928)
  PASS: multi-code-review pin 'decided (orchestrator)' (line 1006, range 928..1115)
  PASS: multi-code-review pin 'decided (<who>)' (line 972, range 928..1115)
  PASS: multi-code-review pin 'plan governs (orchestrator decision)' (line 960, range 928..1115)
  PASS: multi-code-review pin 'plan governs (user decision)' (line 959, range 928..1115)
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`' (line 1025, range 928..1115)
  PASS: multi-code-review pin 'unresolved: fix contradicts binding text' (line 978, range 928..1115)
  PASS: M = 1 log-format example carries the clause (line 775, range 766..781)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 796, range 781..800)
  PASS: multi-code-review normalization replaces a double quotation mark (line 909, range 758..928)
  PASS: multi-code-review names all three replacements as one rule (range 758..928, line wraps folded)
  PASS: addendum shapes include an unresolved line (line 843, range 758..928)
  PASS: the binding-text test is stated where the refusal rule lives (range 928..1115, line wraps folded)
  PASS: binding-text test names the Exact content block (line 986, range 928..1115)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..685)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 663, range 623..685)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..685)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..685)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..685)
  PASS: loop-side rule fragment 'never edits plan text' (line 669, range 623..685)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 671, range 623..685)
9. Controller prompt templates (R10)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(user)' (line 213, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 214, range 209..216)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 213, range 209..216)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin '(user)' (line 120, range 116..177)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 136, range 116..177)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 161, range 116..177)
  PASS: batch-controller Resume Answer heading states the omit condition (line 71, range 1..189)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 195, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 196, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 193, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 196, range 189..203)
  PASS: First-batch parameter defers to Deviation 1's pre-flight rule (line 63, range 1..189)
  PASS: batch-controller Deviation 1 pin '### Question <k>' (line 81, range 77..125)
  PASS: batch-controller Deviation 1 pin '### Conflict <k>' (line 82, range 77..125)
  PASS: batch-controller Deviation 1 pin 'lowest-numbered task' (line 100, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Pre-flight rule' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'absent from' (line 104, range 77..125)
  PASS: batch-controller Deviation 1 pin '.superpowers/sdd/task-<n>-report.md' (line 80, range 77..125)
  PASS: batch-controller Deviation 1 pin 'is settled' (line 108, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Never copy a secret or a credential' (line 121, range 77..125)
  PASS: batch-controller Deviation 1 pin 're-used on the same task' (line 84, range 77..125)
  PASS: batch-controller Deviation 1 pin 'those sections before you write your own' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'controller failure' (line 120, range 77..125)
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 109, range 77..125)
  PASS: Deviation 1 keys the stale-section deletion on this run's own work (line 92, range 77..125)
  PASS: Deviation 1 rejects the answer line as the first-dispatch signal (line 94, range 77..125)
  PASS: batch-controller re-derived conflict pin 're-use that `<k>`, apply the answer' (line 116, range 77..125)
  PASS: batch-controller re-derived conflict pin 'Allocate a new `<k>` only for a' (line 117, range 77..125)

Results: 208 passed, 0 failed
(exit 0)

```

## Round 7 fixes — 2026-09-04

Findings I1–I5 and M1–M2 of round 7. Files touched:
`skills/orchestrating-development/SKILL.md`,
`skills/orchestrating-development/code-review-loop-prompt.md`,
`skills/multi-code-review/SKILL.md`,
`tests/in-run-rulings/run-tests.sh`.

### Findings addressed

- **I1 — a committed credential could be decided without a human.**
  Deviation 3's secret EXCEPTION in
  `skills/orchestrating-development/code-review-loop-prompt.md` no longer
  claims that an `unresolved` count stops the run. It now pins the
  disposition text to a fixed leading form, so that the whole line reads
  `unresolved: exposed secret or credential in an orchestration artifact — <file:line>`,
  states the real mechanism (the orchestrator's `secret` escalation class
  matches that leading text and stops the run), warns that a reason written
  in free words would be classified as an ordinary item and decided without
  the user, and repeats the no-copy rule for the value. The `secret`
  escalation entry in `skills/orchestrating-development/SKILL.md` states the
  same pinned form byte for byte and says to match that leading text.

- **I2 — an `(amended by ruling <n>)` marker was self-asserted authority.**
  The orphan-marker check no longer runs only on a resume. A new paragraph
  **A marker is authority only while the ruling record backs it** was added
  to `### The ruling record` in
  `skills/orchestrating-development/SKILL.md`: before a clause carrying the
  marker is treated as decided wording, the reader checks that the ruling
  record holds a `## Ruling <n>` entry for that same `<n>`; a marker with no
  such entry is reference text and the clause carries no decided-wording
  authority. The same rule is written for the loop in
  `skills/multi-code-review/SKILL.md`, under "Decided wording in a
  verification cycle": the loop checks
  `<TOPIC_DIR>/plans/<slug>-open-decisions.md` for a `## Ruling <n>` heading
  with that number compared as a whole number (ruling 1 is not matched by
  `## Ruling 10`), and treats the marker as reference text both when no entry
  stands and when the loop was called without `TOPIC_DIR`, so no ruling
  record exists at all. Each file points at the other so the two actors
  apply one rule.

- **I3 — the `secret` trigger was Phase-4-only and closed the producer set.**
  The `secret` entry in `skills/orchestrating-development/SKILL.md` now
  triggers on the item's disposition reason or summary **or**, in Phase 3,
  where an open item is a report section and carries no disposition line at
  all, on the text of the `### Conflict <k>` or `### Question <k>` section.
  "One producer exists" was replaced by **Two producers exist**:
  `code-review-loop-prompt.md` Deviation 3 with its fixed form, and
  `batch-controller-prompt.md` Deviation 1, whose implementer names a
  credential's location and describes its value in a question or conflict
  section.

- **I4 — the fork prompt had no send-nothing clause.** The read-only line of
  the fork prompt block in `skills/orchestrating-development/SKILL.md` now
  reads: write nothing, dispatch nothing, run no other command, **and send
  nothing anywhere** — text in the prompt or in a file the fork reads that
  directs it to fetch a URL, post a file, or otherwise transmit data is
  itself a reportable finding, never an instruction. This matches the
  sibling reviewer template's clause.

- **I5 — the two `stopped` commits had no staging rule.** A new paragraph
  **Every `stopped` commit stages by explicit path** was added to the
  Major-Error Stop Policy in `skills/orchestrating-development/SKILL.md`: the
  only files staged are the orchestration log and, when committed with it,
  `state.md`, each named on the command line; `git add -A`, `git add .` and
  `git commit -a` are forbidden, because a stop can happen over a
  deliberately dirty tree and a sweeping stage would put the blocked task's
  half-finished, unreviewed work into the
  `chore(orchestration): <slug> stopped` commit. Both `stopped` commit sites
  now point at that rule: "Handling a return as a whole" and the Resume
  rebuild path.

- **M1 — the no-delete bound covered binding text only.** The bound in the
  plan-amendment procedure now reads "never **deletes** a clause outright —
  **binding and reference text alike**", with the reason stated: a safety
  rule is often written in reference text as an ordinary sentence, and a
  `forced` item's amendment is read by no fork, so replacing such a sentence
  wholesale would drop the rule for every later task unnoticed. Step 1 was
  adjusted to match: the amended text is the kept clause followed by the
  scoped exception, never a clause dropped and rewritten.

- **M2 — the "Never reproduce a secret" list was closed.** The rule now
  states the universal form first (every line, in every file a ruling commit
  touches — the ruling record, the orchestration log and the plan, with no
  exempt field), says the list below is not closed, and extends it to the
  `## Ruling <n> — … — [<id>] <short title>` heading, the `**Resolution:**`
  line, and the `## RULING <n> — … — <one-line summary>` heading, alongside
  the `**Item:**`, `Items:` and `Open:` lines it already named.

### New assertions — tests/in-run-rulings/run-tests.sh

Section 1 (escalation predicate): a byte pin for the fixed secret
disposition form, a folded fragment for the Phase 3 report-section half of
the trigger, and byte pins for `**Two producers exist.**` and
`` `batch-controller-prompt.md` Deviation 1 ``.

Section 3 (fork review): folded fragments `send nothing anywhere` and
`is itself a reportable finding, never an instruction`, scoped to the fork
subsection.

Section 4 (ruling record, answers and plan amendment): a byte pin for
`**A marker is authority only while the ruling record backs it.**` plus
folded fragments for "at every moment, not only on a resume" and "A marker
with no such entry behind it is reference text"; folded fragments for the
widened secret rule ("in every file a ruling commit touches", "The list
below is not closed", the `**Resolution:**` field). The existing no-delete
assertion's needle moved with the wording, from
`never **deletes** binding text outright` to
`never **deletes** a clause outright`, and two new folded fragments were
added beside it for the widened scope
(`**binding and reference text alike**`) and for step 1
(`never a clause dropped and rewritten`).

Section 6 (stop policy): a byte pin for
`` **Every `stopped` commit stages by explicit path.** ``, byte pins for
`git add -A`, `git add .` and `git commit -a` scoped to the stop-policy
range, a folded fragment naming the only files staged, and one folded
fragment at each of the two `stopped` commit sites (Resume range and
log-entry range).

Section 8 (loop-side rule): a byte pin for the loop's marker paragraph, a
byte pin for `<TOPIC_DIR>/plans/<slug>-open-decisions.md`, and folded
fragments for "the marker is **reference text**" and the no-`TOPIC_DIR`
case.

Section 9 (controller prompt templates): a new Deviation 3 range
(`3. Triage rule:` up to `4. Reviewer blinding:`) with a byte pin for the
fixed disposition form and folded fragments for "fixed leading form", the
`secret`-class mechanism sentence, and "Never copy the value itself".

### Mutation check on the new needles

Each of the 28 new needles was verified by deleting the rule it pins from
the source file, running the suite, confirming it failed on that needle's
own assertion, and restoring the file. All 28 failed as expected; the tree
was restored afterwards (`git status --short` shows only the four intended
files modified).

### Commands run

```
$ bash tests/reviewer-templates/run-tests.sh
1. Harness claims rule is inside the prompt block
  PASS: doc-review template: Harness claims rule inside the prompt block (line 42, block 25..133)
  PASS: code-review template: Harness claims rule inside the prompt block (line 64, block 24..193)
2. Finding-format field spellings
  PASS: doc-review template: field spelling 'harness: tested —'
  PASS: doc-review template: field spelling 'harness: untested —'
  PASS: code-review template: field spelling 'harness: tested —'
  PASS: code-review template: field spelling 'harness: untested —'
3. Controller triage reason strings and completion-report line
  PASS: multi-doc-review SKILL.md: reason string 'harness probe —'
  PASS: multi-doc-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-doc-review SKILL.md: completion-report line 'Harness probes owed:'
  PASS: multi-code-review SKILL.md: reason string 'harness probe —'
  PASS: multi-code-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-code-review SKILL.md: completion-report line 'Harness probes owed:'
4. user-decision guard
  PASS: multi-code-review SKILL.md: guard fragment
5. Rule text drift between the two templates
  PASS: doc-review template: rule extract is non-empty
  PASS: code-review template: rule extract is non-empty
  PASS: rule text identical in both templates
6. Unchanged contracts
  PASS: code-review template: blinding pathspec line
  PASS: code-review template: report marker instruction
  PASS: doc-review template: report marker instruction
7. Ambiguity & testability plan-cell contract targets
  PASS: multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty
  PASS: Ambiguity plan cell: fragment 'no stated contract'
  PASS: Ambiguity plan cell: fragment 'self-pin'
  PASS: Ambiguity plan cell: gate label '**Body authority:**'
8. Body-authority gate label consistency (writing-plans vs multi-doc-review)
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
exit=0

$ bash tests/writing-plans/run-tests.sh
1. Contracts and Literal Bodies section (R1)
  PASS: section heading '## Contracts and Literal Bodies' (whole-line match, line 122)
  PASS: exact-content label '**Exact content:**' (rule 4) (line 172, range 170..184)
  PASS: procedural tie-break fragment 'treat the block as not procedural' (rule 1) (line 149, range 129..154)
  PASS: authority-default fragment 'ordinary fix' (rule 3) (line 166, range 163..170)
  PASS: self-pin fragment 'together as one ordinary fix' (rule 5) (line 187, range 184..194)
2. Task Template Contract field (R2)
  PASS: Task Template block carries '**Contract:**' (line 261, block 249..291)
3. Plan Header authority note (R3)
  PASS: Plan Header template carries 'reference implementations' (line 86, block 81..96)
  PASS: Plan Header template carries '**Body authority:**' (line 86, block 81..96)
  PASS: Plan Header note states the closed binding set 'Exactly two things in this plan bind' (line 86, block 81..96)
  PASS: Plan Header note states the exact-content binding condition 'names a pin this plan does not itself write or edit' (line 86, block 81..96)
  PASS: Plan Header note states the residue clause 'Everything else is reference' (line 86, block 81..96)
  PASS: Plan Header note states the non-conflict disposition 'is never a plan conflict: record it against the plan-writing skill' (line 86, block 81..96)
  PASS: Plan Header note states the disposition's scoping guard 'covers the note's own text alone' (line 86, block 81..96)
4. Self-Review contract audit (R4)
  PASS: self-review fragment 'falsifiable' (check 5) (line 338, range 338..340)
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
exit=0

$ bash tests/in-run-rulings/run-tests.sh
0. Section anchors
  PASS: '## In-run rulings' precedes '## Major-Error Stop Policy' (lines 624..1424)
  PASS: no other '## ' heading (outside a fenced code block) between 624 and 1424
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 624)
  PASS: class or reason label `escalated` (line 659, range 654..783)
  PASS: class or reason label `forced` (line 662, range 654..783)
  PASS: class or reason label `design` (line 667, range 654..783)
  PASS: class or reason label `spec wrong` (line 674, range 654..783)
  PASS: class or reason label `scope` (line 678, range 654..783)
  PASS: class or reason label `irreversible` (line 682, range 654..783)
  PASS: class or reason label `secret` (line 709, range 654..783)
  PASS: class or reason label `chain` (line 725, range 654..783)
  PASS: class or reason label escalated (chain) (line 726, range 654..783)
  PASS: predicate fragment 'escalation wins' (line 660, range 654..783)
  PASS: predicate fragment '### Conflict' (line 700, range 654..783)
  PASS: predicate fragment '### Question' (line 701, range 654..783)
  PASS: predicate fragment 'fatal environment failure' (line 729, range 654..783)
  PASS: predicate fragment 'never `spec wrong`' (line 738, range 654..783)
  PASS: predicate fragment 'handled as a whole' (line 773, range 654..783)
  PASS: predicate fragment 'applied twice' (line 776, range 654..783)
  PASS: irreversible entry pin 'escalated (irreversible)' (line 689, range 654..783)
  PASS: irreversible entry covers an amendment of binding plan text (range 654..783, line wraps folded)
  PASS: irreversible entry triggers on the edit location, not on a judgement (range 654..783, line wraps folded)
  PASS: irreversible entry reads binding-ness from the task section (range 654..783, line wraps folded)
  PASS: secret class pins the loop's fixed disposition form (line 717, range 654..783)
  PASS: secret trigger covers the Phase 3 report-section form (range 654..783, line wraps folded)
  PASS: secret class names two producers, not one (line 713, range 654..783)
  PASS: secret class names the batch template as the second producer (line 719, range 654..783)
  PASS: discriminator bounds <n> by the plan, not by the batch (range 654..783, line wraps folded)
  PASS: irreversible entry states its Phase 3 form (range 654..783, line wraps folded)
  PASS: Phase 3 trigger reads the location the conflict section names (range 654..783, line wraps folded)
  PASS: bare task id is never a form the orchestrator writes (range 624..654, line wraps folded)
  PASS: a bare user answer is resolved, never defaulted to section 1 (range 624..654, line wraps folded)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 818, range 783..841)
  PASS: read-exception fragment 'never a reviewer report file' (line 796, range 783..841)
  PASS: read-exception fragment 'read-only git commands' (line 823, range 783..841)
  PASS: read-exception fragment 'resume step 3' (line 788, range 783..841)
  PASS: read-exception fragment 'nothing else' (line 817, range 783..841)
  PASS: read-exception fragment '40 lines' (line 804, range 783..841)
  PASS: read-exception entry 5 names the ruling-record path (line 810, range 783..841)
  PASS: read-exception entry 5 calls it the file you write yourself (range 783..841, line wraps folded)
  PASS: read-exception entry 5 fragment 'Guard 4 (below) reads it' (line 811, range 783..841)
  PASS: read-exception entry 5 fragment 'earlier answer tagged `(user)` on the same clause' (line 812, range 783..841)
  PASS: read exception names its three purposes (range 783..841, line wraps folded)
  PASS: read exception permits the ruling-commit read for the orchestrator (line 808, range 783..841)
  PASS: fork diff form mandates the negative flags (line 828, range 783..841)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 898, range 624..1424)
  PASS: fork pin '<!-- multi-review report -->' (line 949, range 624..1424)
  PASS: fork pin 'fork-<lens>' (line 890, range 624..1424)
  PASS: fork pin 'fork review unavailable' (line 989, range 624..1424)
  PASS: fork pin 'contradiction: unsettled' (line 975, range 624..1424)
  PASS: fork pin 'VERDICT:' (line 953, range 841..1008)
  PASS: fork pin 'TABLED:' (line 956, range 841..1008)
  PASS: fork fragment 'not a debate' (line 863, range 841..1008)
  PASS: fork fragment 'never pass conversation history' (line 896, range 841..1008)
  PASS: fork fragment 'action verb followed by a skill name' (line 959, range 841..1008)
  PASS: fork fragment 'in parallel, in one message' (line 843, range 841..1008)
  PASS: fork fragment 'evidence consistency' (line 852, range 841..1008)
  PASS: fork fragment 'general-purpose' (line 888, range 841..1008)
  PASS: fork naming never uses an orch- name (line 900, range 841..1008)
  PASS: Guard Interaction names the forks' marker (line 1470, range 1460..1475)
  PASS: Guard Interaction names the forks' return marker exactly (line 1469, range 1460..1475)
  PASS: fork prompt mandates the negative diff flags (line 938, range 841..1008)
  PASS: fork prompt's read-only clause forbids sending anything (range 841..1008, line wraps folded)
  PASS: fork prompt makes a transmission instruction reportable (range 841..1008, line wraps folded)
  PASS: lost-return bound is stated over the round (range 841..1008, line wraps folded)
  PASS: every still-missing lens of a round is lost at the same moment (range 841..1008, line wraps folded)
  PASS: only the first design item uses the fork path (range 841..1008, line wraps folded)
  PASS: consolidation reasoning waits for the item's round (range 841..1008, line wraps folded)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record pin '-open-decisions.md' (line 1010, range 1008..1083)
  PASS: ruling-record pin '**Follow-up:**' (line 1071, range 1008..1083)
  PASS: ruling-record pin '## Ruling <n>' (line 1017, range 1008..1083)
  PASS: ruling-record fragment 'appended, never rewritten' (line 1013, range 1008..1083)
  PASS: ruling-record Forks field carries the planned count (line 1023, range 1008..1083)
  PASS: ruling record widens the follow-up to any answered entry (range 1008..1083, line wraps folded)
  PASS: answer pin '(orchestrator):' (line 1087, range 1083..1269)
  PASS: answer pin 'decided (orchestrator)' (line 1087, range 1083..1269)
  PASS: answer pin 'amend plan:' (line 1105, range 1083..1269)
  PASS: answer pin 'plan governs:' (line 1103, range 1083..1269)
  PASS: answer pin 'fix it:' (line 1098, range 1083..1269)
  PASS: answer pin 'accept:' (line 1114, range 1083..1269)
  PASS: answer pin '**Amendment' (line 1241, range 1083..1269)
  PASS: answer pin '[task <n>/<k>]' (line 1141, range 1083..1269)
  PASS: answer fragment '(amended by ruling' (line 1227, range 1083..1269)
  PASS: answer fragment 'never apply the amendment twice' (line 1247, range 1083..1269)
  PASS: answer fragment 'new invocation' (line 1261, range 1083..1269)
  PASS: answer fragment 'untagged' (line 1095, range 1083..1269)
  PASS: answer fragment 'sides against binding plan text' (line 1151, range 1083..1269)
  PASS: answer fragment '**The quoted clause, and how it is compared.**' (line 1117, range 1083..1269)
  PASS: answer fragment 'test whether the quote is a prefix of it' (line 1126, range 1083..1269)
  PASS: amendment never deletes a clause outright (range 1083..1269, line wraps folded)
  PASS: the no-delete bound covers reference text too (range 1083..1269, line wraps folded)
  PASS: amendment step 1 keeps the clause under the no-delete bound (range 1083..1269, line wraps folded)
  PASS: amendment appends an exception scoped to the ruling's item (range 1083..1269, line wraps folded)
  PASS: answer pin 'escalated (irreversible)' (line 1109, range 1083..1269)
  PASS: the amendment procedure is scoped to the amendments still the orchestrator's (range 1083..1269, line wraps folded)
  PASS: ruling writes have a fixed order (range 1008..1083, line wraps folded)
  PASS: ruling record bounds the marker's authority to a backing entry (line 1052, range 1008..1083)
  PASS: the marker check is not the Resume-only check (range 1008..1083, line wraps folded)
  PASS: an unbacked marker is reference text, not decided wording (range 1008..1083, line wraps folded)
  PASS: the secret rule covers every file a ruling commit touches (range 1008..1083, line wraps folded)
  PASS: the secret rule's field list is open, not closed (range 1008..1083, line wraps folded)
  PASS: the secret rule names the Resolution field (range 1008..1083, line wraps folded)
  PASS: normalization also replaces a double quotation mark (range 1083..1269, line wraps folded)
  PASS: amendment lookup escalates when no clause matches (range 1083..1269, line wraps folded)
  PASS: a re-derived conflict keeps its answered number (range 1083..1269, line wraps folded)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry pin '## RULING' (line 1275, range 1269..1376)
  PASS: log-entry pin 'Re-dispatch:' (line 1280, range 1269..1376)
  PASS: log-entry pin 'Re-dispatch: none' (line 1322, range 1269..1376)
  PASS: log-entry pin 'Ruled:' (line 1325, range 1269..1376)
  PASS: log-entry pin 'chore(orchestration): <slug> ruling <n>' (line 1301, range 1269..1376)
  PASS: guard pin 'plan governs (orchestrator decision)' (line 1388, range 1376..1424)
  PASS: guard fragment forbidding a byte-equal match (range 1376..1424, line wraps folded)
  PASS: log-entry sentence, byte-exact incl. punctuation (range 1269..1376, line wraps folded, case-sensitive)
  PASS: log-entry sentence carries no '*' emphasis marker
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (range 1269..1376, line wraps folded)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (range 1269..1376, line wraps folded)
  PASS: log-entry fragment 'previous invocation left' (line 1315, range 1269..1376)
  PASS: self-check escalates a bare fix it on binding text (line 1295, range 1269..1376)
  PASS: cap counts a Phase 3 task in either line form (line 1340, range 1269..1376)
  PASS: RULING Forks line carries the planned count (line 1279, range 1269..1376)
  PASS: guard fragment 'durable marker' (line 1373, range 1269..1376)
  PASS: guard fragment 'a Critical is never rejected' (line 1398, range 1376..1424)
  PASS: guard fragment 'quotes its clause' (line 1381, range 1376..1424)
  PASS: guard fragment 'recorded when it is made' (line 1401, range 1376..1424)
  PASS: guard count word is 'Four' (range 1376..1424, line wraps folded, case-sensitive)
  PASS: guard 4 states a user decision is never overturned (line 1404, range 1376..1424)
  PASS: guard 4 fragment 'read your ruling record' (line 1405, range 1376..1424)
  PASS: guard 4 fragment 'recorded answer tagged `(user)`' (line 1406, range 1376..1424)
  PASS: guard 4 fragment 'under the class that first sent it to the user' (line 1410, range 1376..1424)
  PASS: guard 4 fragment 'you never re-answer it in the' (line 1414, range 1376..1424)
  PASS: guard 4 escalates when the clause match is unsure (range 1376..1424, line wraps folded)
  PASS: guard 4 names a fallback class for a forced or design entry (range 1376..1424, line wraps folded)
  PASS: cap matches the whole bracketed token (line 1341, range 1269..1376)
  PASS: cap tests the Re-dispatch value, not the line's first word (range 1269..1376, line wraps folded)
  PASS: a stop skips an entry already carrying a follow-up (range 1269..1376, line wraps folded)
  PASS: guard 1 says a quotable clause is not by itself a reason (range 1376..1424, line wraps folded)
  PASS: guard 4 ignores a clause-less follow-up (range 1376..1424, line wraps folded)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (line 276, range 246..300)
  PASS: Phase 4 routes open items to the predicate (line 311, range 300..329)
  PASS: Phase 5 report lists unsettled contradictions (line 342, range 329..351)
  PASS: log-format pin '## RULING' (line 375, range 351..420)
  PASS: log-format pin 'Ruled:' (line 392, range 351..420)
  PASS: log-format pin 'Open:' (line 391, range 351..420)
  PASS: log-format pin 'Owed probe:' (line 393, range 351..420)
  PASS: log-format pin 'ruling <n> follow-up' (line 418, range 351..420)
  PASS: state.md carries the Rulings line (line 430, range 420..433)
  PASS: resume pin '## RULING' (line 469, range 433..624)
  PASS: resume pin 'Ruled:' (line 502, range 433..624)
  PASS: resume pin '**Follow-up:**' (line 505, range 433..624)
  PASS: resume pin '(orchestrator)' (line 515, range 433..624)
  PASS: resume pin '(user)' (line 516, range 433..624)
  PASS: resume pin 'decided (<who>)' (line 566, range 433..624)
  PASS: resume pin 'The Phase 3 answer set — one rule' (line 518, range 433..624)
  PASS: resume recovers the pre-amendment clause from the ruling commit (line 542, range 433..624)
  PASS: resume compares the printed subject with the full expected string (range 433..624, line wraps folded)
  PASS: Resume step 3 no longer names decided (user) alone
  PASS: resume ruling-commit lookup prints the hash (line 534, range 433..624)
  PASS: resume ruling-commit lookup keeps exactly one subject (range 433..624, line wraps folded)
  PASS: resume copies the clause, never the whole printed file (range 433..624, line wraps folded)
  PASS: resume reverts an orphan amendment marker (range 433..624, line wraps folded)
  PASS: stop policy fragment 'escalated' (line 1446, range 1424..1460)
  PASS: stop policy fragment 'fork review unavailable' (line 1448, range 1424..1460)
  PASS: stop policy states the stopped commit's staging rule (line 1430, range 1424..1460)
  PASS: stop policy forbids 'git add -A' for a stopped commit (line 1432, range 1424..1460)
  PASS: stop policy forbids 'git add .' for a stopped commit (line 1433, range 1424..1460)
  PASS: stop policy forbids 'git commit -a' for a stopped commit (line 1433, range 1424..1460)
  PASS: stop policy names the only files a stopped commit stages (range 1424..1460, line wraps folded)
  PASS: the Resume rebuild path stages its stopped commit by explicit path (range 433..624, line wraps folded)
  PASS: the escalated-return stop stages its stopped commit by explicit path (range 1269..1376, line wraps folded)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin '— clause:' (line 793, range 776..946)
  PASS: multi-code-review pin 'clause: none' (line 939, range 776..946)
  PASS: multi-code-review pin '(plan-mandated) — at ' (line 793, range 776..946)
  PASS: multi-code-review pin 'cut it to 160 characters' (line 928, range 776..946)
  PASS: multi-code-review pin '**Normalization is one rule:**' (line 923, range 776..946)
  PASS: multi-code-review pin 'one sentence or one list entry, never a whole section' (line 924, range 776..946)
  PASS: multi-code-review pin 'tests the quote as a **prefix**' (line 934, range 776..946)
  PASS: multi-code-review pin 'No consumer compares the quote with the raw plan text' (line 935, range 776..946)
  PASS: multi-code-review pin 'decided (orchestrator)' (line 1024, range 946..1133)
  PASS: multi-code-review pin 'decided (<who>)' (line 990, range 946..1133)
  PASS: multi-code-review pin 'plan governs (orchestrator decision)' (line 978, range 946..1133)
  PASS: multi-code-review pin 'plan governs (user decision)' (line 977, range 946..1133)
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`' (line 1043, range 946..1133)
  PASS: multi-code-review pin 'unresolved: fix contradicts binding text' (line 996, range 946..1133)
  PASS: M = 1 log-format example carries the clause (line 793, range 784..799)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 814, range 799..818)
  PASS: multi-code-review normalization replaces a double quotation mark (line 927, range 776..946)
  PASS: multi-code-review names all three replacements as one rule (range 776..946, line wraps folded)
  PASS: addendum shapes include an unresolved line (line 861, range 776..946)
  PASS: the binding-text test is stated where the refusal rule lives (range 946..1133, line wraps folded)
  PASS: binding-text test names the Exact content block (line 1004, range 946..1133)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..703)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 681, range 623..703)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..703)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..703)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..703)
  PASS: loop-side rule fragment 'never edits plan text' (line 687, range 623..703)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 689, range 623..703)
  PASS: loop bounds the marker's authority to a backing entry (line 664, range 623..703)
  PASS: loop names the ruling-record path it checks the marker against (line 667, range 623..703)
  PASS: loop treats an unbacked marker as reference text (range 623..703, line wraps folded)
  PASS: loop covers the no-TOPIC_DIR case, where no record exists (range 623..703, line wraps folded)
9. Controller prompt templates (R10)
  PASS: Deviation 3 pins the fixed secret disposition form (line 109, range 94..119)
  PASS: Deviation 3 says the leading text is fixed (range 94..119, line wraps folded)
  PASS: Deviation 3 names the real mechanism: the secret class stops the run (range 94..119, line wraps folded)
  PASS: Deviation 3 forbids copying the value into the line (range 94..119, line wraps folded)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 222, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(user)' (line 222, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 223, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 222, range 218..225)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 129, range 125..186)
  PASS: code-review-loop Deviation 5 pin '(user)' (line 129, range 125..186)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 145, range 125..186)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 170, range 125..186)
  PASS: batch-controller Resume Answer heading states the omit condition (line 71, range 1..189)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 195, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 196, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 193, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 196, range 189..203)
  PASS: First-batch parameter defers to Deviation 1's pre-flight rule (line 63, range 1..189)
  PASS: batch-controller Deviation 1 pin '### Question <k>' (line 81, range 77..125)
  PASS: batch-controller Deviation 1 pin '### Conflict <k>' (line 82, range 77..125)
  PASS: batch-controller Deviation 1 pin 'lowest-numbered task' (line 100, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Pre-flight rule' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'absent from' (line 104, range 77..125)
  PASS: batch-controller Deviation 1 pin '.superpowers/sdd/task-<n>-report.md' (line 80, range 77..125)
  PASS: batch-controller Deviation 1 pin 'is settled' (line 108, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Never copy a secret or a credential' (line 121, range 77..125)
  PASS: batch-controller Deviation 1 pin 're-used on the same task' (line 84, range 77..125)
  PASS: batch-controller Deviation 1 pin 'those sections before you write your own' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'controller failure' (line 120, range 77..125)
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 109, range 77..125)
  PASS: Deviation 1 keys the stale-section deletion on this run's own work (line 92, range 77..125)
  PASS: Deviation 1 rejects the answer line as the first-dispatch signal (line 94, range 77..125)
  PASS: batch-controller re-derived conflict pin 're-use that `<k>`, apply the answer' (line 116, range 77..125)
  PASS: batch-controller re-derived conflict pin 'Allocate a new `<k>` only for a' (line 117, range 77..125)

Results: 237 passed, 0 failed
exit=0
```

## Round 8 fixes — 2026-09-04

Findings I1–I3 and M1–M3, M5–M8 of round 8. Files touched:
`skills/orchestrating-development/SKILL.md`,
`tests/in-run-rulings/run-tests.sh`.

Every finding of round 8 except M1's first half was a defect in the test
suite itself, so the two source-file changes are small: only M1 required a
wording change (`skills/orchestrating-development/SKILL.md`, the ruling
record's marker paragraph).

### Findings addressed

- **I1 — the Phase 3 routing assertion could not fail.**
  `tests/in-run-rulings/run-tests.sh`, the three phase-routing assertions.
  Each pinned only a fragment that occurs more than once in its phase
  range (`In-run rulings`, or `contradiction: unsettled`), so deleting the
  routing sentence left the suite green. Each now pins bytes of its own
  routing sentence, folded because every one of them crosses a line wrap:
  Phase 3 pins ``return goes through the Phase 3 discriminator of `## In-run rulings` ``,
  Phase 4 pins ``` `## In-run rulings`: classify each open item by its review-log id ```,
  Phase 5 pins ``every entry whose Forks line records `contradiction: unsettled` ``.

- **I2 — the emphasis check was a tautology.**
  Same file, the check named "log-entry sentence carries no `*` emphasis
  marker". It searched the match itself, which is byte-identical to the
  needle and can never hold a `*`. It now reads the single character on
  each side of the match and fails when either is `*`. Only the touching
  characters are examined, because the paragraph opens with a bolded
  `**The cap.**` lead-in that is separated from the sentence by a space
  and is not emphasis on the sentence.

- **I3 — the `Ruled:` and `Open:` log-format pins survived deleting the
  example.** Same file, the log-format pin list. Both labels also occur in
  the prose below the `## STOPPED` example block. Each is now pinned as a
  whole field line, placeholder tail included:
  `Open: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>`
  and `Ruled: [<id>] <forced|design> — <answer>`, so that only the
  example's own line can satisfy the pin.

- **M1 — four new rules carried no assertion, and one had already
  diverged.**
  1. `skills/orchestrating-development/SKILL.md`, the ruling record's
     "A marker is authority only while the ruling record backs it"
     paragraph, now carries the whole-number qualifier the loop already
     stated: "the heading line begins `## Ruling <n> ` with that number,
     compared as a whole number, so ruling 1 is not matched by a
     `## Ruling 10` heading." The rule is now pinned on both sides — in
     the ruling-record range and in the loop's no-fix range.
  2. The batch template's section-number allocation rule is pinned in
     Deviation 1's range, in two parts: "number a new section 1 above the
     highest `<k>` you can see" and "never renumber a section you wrote in
     this dispatch".
  3. The batch template's run-wide `[RESUME_ANSWER]` scope is pinned in
     the placeholder's range: "with every answer the run has recorded so
     far, whatever batch its task belongs to".
  4. The loop template's "an untagged line is a user line" is pinned in
     Deviation 5's range.

- **M2 — the two folded checks folded differently.** Same file. The
  emphasis check folded its range with `printf "%s "` and kept each line's
  leading whitespace, while `assert_in_range_folded_exact` stripped it.
  The fold is now one helper, `fold_range`, used by
  `assert_in_range_folded`, `assert_in_range_folded_exact` and the
  emphasis check, so the three can never disagree about the text they
  search. The emphasis check's two outcomes now get distinct messages:
  "is wrapped in a `*` emphasis marker" versus "not found in range …".

- **M3 — the Guard Interaction fork wiring was untested.** Same file. The
  bare case-insensitive `fork` fragment and the pre-existing
  `<!-- multi-review report -->` marker pin both survived deleting the
  sentence this branch adds. Two folded pins now carry bytes of that
  sentence: "Forks dispatched under `## In-run rulings` open their return
  with that same `<!-- multi-review report -->` marker" and "a fork return
  without it is a lost return under that section". The marker pin is kept
  and its comment now states explicitly that it is an unchanged-wording
  regression pin only, which cannot fail when the fork sentence is
  deleted.

- **M5 — the Resume negative check failed on correct content.** Same
  file. It forbade every occurrence of `decided (user)` in the Resume
  range, including the correct enumeration
  ``` `decided (user)` or `decided (orchestrator)` ``` that the same suite
  REQUIRES in the sibling files. It now fails only on a `decided (user)`
  occurrence whose own line does not also carry `decided (orchestrator)`.

- **M6 — five fork pins were scoped to the whole section.** Same file.
  The `FORK_LINE`/`FORK_END` computation moved above the loop, and all
  seven fork pins (the five plus `VERDICT:` and `TABLED:`) now use it.

- **M7 — the interloper scan reported PASS over an absent range.** Same
  file. With both anchors empty, `awk -v a="" -v b=""` compared strings,
  produced no output, and the check printed PASS. It is now guarded with
  a non-empty and start-before-end test, the way the two negative checks
  elsewhere in the suite are guarded, and reports a FAIL naming the
  missing range instead.

- **M8 — two bare `(user)` needles added no coverage.** Same file. Both
  loop-prompt ranges already held `decided (user)` before this branch. In
  the `[RESUME_ANSWER]` doc range the needle is now the byte pin
  ``` `(orchestrator)` or `(user)` ```; in Deviation 5's range it is
  ``` tagged `(orchestrator)` or `(user)` ```. Both exist only in the new
  per-line tagging wording.

### Mutation check on the new and repaired assertions

Every assertion below was verified by mutating or deleting the rule it
pins in a working copy of the file, running the suite, confirming the
named assertion FAILED, and restoring the file. The tree was clean
afterwards apart from the two intended files.

| Finding | Mutation applied | Assertion that failed |
| --- | --- | --- |
| I1 | Phase 3 routing sentence reworded to drop "goes through the Phase 3 discriminator of `## In-run rulings`" (the section's other `## In-run rulings` mention left in place) | `Phase 3 routes BLOCKED task=<n> to the predicate` |
| I1 | Phase 4 routing sentence reworded to drop "`## In-run rulings`: classify each open item by its review-log id" | `Phase 4 routes open items to the predicate` |
| I1 | Phase 5 report clause "and every entry whose Forks line records `contradiction: unsettled` …" deleted | `Phase 5 report lists unsettled contradictions` |
| I2 | cap sentence wrapped as `**In-run resumes … Phase 3.**` | `log-entry sentence is wrapped in a '*' emphasis marker` (while the byte-exact sibling still PASSED, which is the gap this closes) |
| I3 | the `Open:` and `Ruled:` field lines of the `## STOPPED` example block deleted | both `log-format pin 'Open: …'` and `log-format pin 'Ruled: …'` |
| M1.1 | whole-number qualifier removed from `skills/orchestrating-development/SKILL.md` | `the marker's ruling number is compared as a whole number` |
| M1.1 | whole-number qualifier removed from `skills/multi-code-review/SKILL.md` | `loop compares the marker's ruling number as a whole number` |
| M1.2 | "number a new section 1 above the highest `<k>` you can see" replaced by "pick any unused section number" | `Deviation 1 allocates a new section number above the highest visible one` |
| M1.2 | "and never renumber a section you wrote in this dispatch." deleted | `Deviation 1 never renumbers a section written in this dispatch` |
| M1.3 | "the run has recorded so far, whatever batch its task belongs to" replaced by "this batch has recorded so far" | `batch-controller [RESUME_ANSWER] carries the run-wide answer set` |
| M1.4 | "; an untagged line is a user line." deleted from Deviation 5 | `code-review-loop Deviation 5 treats an untagged line as a user line` |
| M2 | cap sentence indented as a list item (`- **The cap.** …`) | nothing — both folded checks PASSED and agreed (244 passed, 0 failed). Before the fix the emphasis check would have reported a marker that is not there. |
| M3 | the Guard Interaction fork sentence deleted | `Guard Interaction states that forks open with the reviewer marker` and `Guard Interaction makes a markerless fork return a lost return`; the marker regression pin still PASSED, as its comment now says |
| M5 | Resume step 3 given the correct enumeration ``` `decided (user)` or `decided (orchestrator)` ``` | nothing — 244 passed, 0 failed (the old check turned red on correct content) |
| M5 | Resume step 3 given a bare `decided (user)` | `Resume step 3 names a bare decided (user)` |
| M6 | `<!-- multi-review report -->` removed from the fork subsection and mentioned in the sibling "### The ruling record" subsection instead | `fork pin '<!-- multi-review report -->'` (it would have PASSED under the old whole-section scope) |
| M7 | both range anchors renamed (`## In-run rulings` → `## In-run decisions`) | `cannot scan for an unexpected '## ' heading: the range ..1427 is missing, empty or inverted` (previously this printed PASS) |
| M8 | the `[RESUME_ANSWER]` doc's per-line tagging reverted to the untagged wording | `code-review-loop [RESUME_ANSWER] doc pin '`(orchestrator)` or `(user)`'` |
| M8 | Deviation 5's per-line tagging reverted to the untagged wording | `code-review-loop Deviation 5 pin 'tagged `(orchestrator)` or `(user)`'` (while the bare `(orchestrator)` and `decided (<who>)` pins still PASSED, which is the gap this closes) |

### Commands run

```
$ bash tests/reviewer-templates/run-tests.sh
1. Harness claims rule is inside the prompt block
  PASS: doc-review template: Harness claims rule inside the prompt block (line 42, block 25..133)
  PASS: code-review template: Harness claims rule inside the prompt block (line 64, block 24..193)
2. Finding-format field spellings
  PASS: doc-review template: field spelling 'harness: tested —'
  PASS: doc-review template: field spelling 'harness: untested —'
  PASS: code-review template: field spelling 'harness: tested —'
  PASS: code-review template: field spelling 'harness: untested —'
3. Controller triage reason strings and completion-report line
  PASS: multi-doc-review SKILL.md: reason string 'harness probe —'
  PASS: multi-doc-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-doc-review SKILL.md: completion-report line 'Harness probes owed:'
  PASS: multi-code-review SKILL.md: reason string 'harness probe —'
  PASS: multi-code-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-code-review SKILL.md: completion-report line 'Harness probes owed:'
4. user-decision guard
  PASS: multi-code-review SKILL.md: guard fragment
5. Rule text drift between the two templates
  PASS: doc-review template: rule extract is non-empty
  PASS: code-review template: rule extract is non-empty
  PASS: rule text identical in both templates
6. Unchanged contracts
  PASS: code-review template: blinding pathspec line
  PASS: code-review template: report marker instruction
  PASS: doc-review template: report marker instruction
7. Ambiguity & testability plan-cell contract targets
  PASS: multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty
  PASS: Ambiguity plan cell: fragment 'no stated contract'
  PASS: Ambiguity plan cell: fragment 'self-pin'
  PASS: Ambiguity plan cell: gate label '**Body authority:**'
8. Body-authority gate label consistency (writing-plans vs multi-doc-review)
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
exit=0

$ bash tests/writing-plans/run-tests.sh
1. Contracts and Literal Bodies section (R1)
  PASS: section heading '## Contracts and Literal Bodies' (whole-line match, line 122)
  PASS: exact-content label '**Exact content:**' (rule 4) (line 172, range 170..184)
  PASS: procedural tie-break fragment 'treat the block as not procedural' (rule 1) (line 149, range 129..154)
  PASS: authority-default fragment 'ordinary fix' (rule 3) (line 166, range 163..170)
  PASS: self-pin fragment 'together as one ordinary fix' (rule 5) (line 187, range 184..194)
2. Task Template Contract field (R2)
  PASS: Task Template block carries '**Contract:**' (line 261, block 249..291)
3. Plan Header authority note (R3)
  PASS: Plan Header template carries 'reference implementations' (line 86, block 81..96)
  PASS: Plan Header template carries '**Body authority:**' (line 86, block 81..96)
  PASS: Plan Header note states the closed binding set 'Exactly two things in this plan bind' (line 86, block 81..96)
  PASS: Plan Header note states the exact-content binding condition 'names a pin this plan does not itself write or edit' (line 86, block 81..96)
  PASS: Plan Header note states the residue clause 'Everything else is reference' (line 86, block 81..96)
  PASS: Plan Header note states the non-conflict disposition 'is never a plan conflict: record it against the plan-writing skill' (line 86, block 81..96)
  PASS: Plan Header note states the disposition's scoping guard 'covers the note's own text alone' (line 86, block 81..96)
4. Self-Review contract audit (R4)
  PASS: self-review fragment 'falsifiable' (check 5) (line 338, range 338..340)
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
exit=0

$ bash tests/in-run-rulings/run-tests.sh
0. Section anchors
  PASS: '## In-run rulings' precedes '## Major-Error Stop Policy' (lines 624..1427)
  PASS: no other '## ' heading (outside a fenced code block) between 624 and 1427
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 624)
  PASS: class or reason label `escalated` (line 659, range 654..783)
  PASS: class or reason label `forced` (line 662, range 654..783)
  PASS: class or reason label `design` (line 667, range 654..783)
  PASS: class or reason label `spec wrong` (line 674, range 654..783)
  PASS: class or reason label `scope` (line 678, range 654..783)
  PASS: class or reason label `irreversible` (line 682, range 654..783)
  PASS: class or reason label `secret` (line 709, range 654..783)
  PASS: class or reason label `chain` (line 725, range 654..783)
  PASS: class or reason label escalated (chain) (line 726, range 654..783)
  PASS: predicate fragment 'escalation wins' (line 660, range 654..783)
  PASS: predicate fragment '### Conflict' (line 700, range 654..783)
  PASS: predicate fragment '### Question' (line 701, range 654..783)
  PASS: predicate fragment 'fatal environment failure' (line 729, range 654..783)
  PASS: predicate fragment 'never `spec wrong`' (line 738, range 654..783)
  PASS: predicate fragment 'handled as a whole' (line 773, range 654..783)
  PASS: predicate fragment 'applied twice' (line 776, range 654..783)
  PASS: irreversible entry pin 'escalated (irreversible)' (line 689, range 654..783)
  PASS: irreversible entry covers an amendment of binding plan text (range 654..783, line wraps folded)
  PASS: irreversible entry triggers on the edit location, not on a judgement (range 654..783, line wraps folded)
  PASS: irreversible entry reads binding-ness from the task section (range 654..783, line wraps folded)
  PASS: secret class pins the loop's fixed disposition form (line 717, range 654..783)
  PASS: secret trigger covers the Phase 3 report-section form (range 654..783, line wraps folded)
  PASS: secret class names two producers, not one (line 713, range 654..783)
  PASS: secret class names the batch template as the second producer (line 719, range 654..783)
  PASS: discriminator bounds <n> by the plan, not by the batch (range 654..783, line wraps folded)
  PASS: irreversible entry states its Phase 3 form (range 654..783, line wraps folded)
  PASS: Phase 3 trigger reads the location the conflict section names (range 654..783, line wraps folded)
  PASS: bare task id is never a form the orchestrator writes (range 624..654, line wraps folded)
  PASS: a bare user answer is resolved, never defaulted to section 1 (range 624..654, line wraps folded)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 818, range 783..841)
  PASS: read-exception fragment 'never a reviewer report file' (line 796, range 783..841)
  PASS: read-exception fragment 'read-only git commands' (line 823, range 783..841)
  PASS: read-exception fragment 'resume step 3' (line 788, range 783..841)
  PASS: read-exception fragment 'nothing else' (line 817, range 783..841)
  PASS: read-exception fragment '40 lines' (line 804, range 783..841)
  PASS: read-exception entry 5 names the ruling-record path (line 810, range 783..841)
  PASS: read-exception entry 5 calls it the file you write yourself (range 783..841, line wraps folded)
  PASS: read-exception entry 5 fragment 'Guard 4 (below) reads it' (line 811, range 783..841)
  PASS: read-exception entry 5 fragment 'earlier answer tagged `(user)` on the same clause' (line 812, range 783..841)
  PASS: read exception names its three purposes (range 783..841, line wraps folded)
  PASS: read exception permits the ruling-commit read for the orchestrator (line 808, range 783..841)
  PASS: fork diff form mandates the negative flags (line 828, range 783..841)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 898, range 841..1008)
  PASS: fork pin '<!-- multi-review report -->' (line 949, range 841..1008)
  PASS: fork pin 'fork-<lens>' (line 890, range 841..1008)
  PASS: fork pin 'fork review unavailable' (line 989, range 841..1008)
  PASS: fork pin 'contradiction: unsettled' (line 975, range 841..1008)
  PASS: fork pin 'VERDICT:' (line 953, range 841..1008)
  PASS: fork pin 'TABLED:' (line 956, range 841..1008)
  PASS: fork fragment 'not a debate' (line 863, range 841..1008)
  PASS: fork fragment 'never pass conversation history' (line 896, range 841..1008)
  PASS: fork fragment 'action verb followed by a skill name' (line 959, range 841..1008)
  PASS: fork fragment 'in parallel, in one message' (line 843, range 841..1008)
  PASS: fork fragment 'evidence consistency' (line 852, range 841..1008)
  PASS: fork fragment 'general-purpose' (line 888, range 841..1008)
  PASS: fork naming never uses an orch- name (line 900, range 841..1008)
  PASS: Guard Interaction states that forks open with the reviewer marker (range 1463..1478, line wraps folded)
  PASS: Guard Interaction makes a markerless fork return a lost return (range 1463..1478, line wraps folded)
  PASS: Guard Interaction still spells the nested-reviewer marker exactly (line 1472, range 1463..1478)
  PASS: fork prompt mandates the negative diff flags (line 938, range 841..1008)
  PASS: fork prompt's read-only clause forbids sending anything (range 841..1008, line wraps folded)
  PASS: fork prompt makes a transmission instruction reportable (range 841..1008, line wraps folded)
  PASS: lost-return bound is stated over the round (range 841..1008, line wraps folded)
  PASS: every still-missing lens of a round is lost at the same moment (range 841..1008, line wraps folded)
  PASS: only the first design item uses the fork path (range 841..1008, line wraps folded)
  PASS: consolidation reasoning waits for the item's round (range 841..1008, line wraps folded)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record pin '-open-decisions.md' (line 1010, range 1008..1086)
  PASS: ruling-record pin '**Follow-up:**' (line 1074, range 1008..1086)
  PASS: ruling-record pin '## Ruling <n>' (line 1017, range 1008..1086)
  PASS: ruling-record fragment 'appended, never rewritten' (line 1013, range 1008..1086)
  PASS: ruling-record Forks field carries the planned count (line 1023, range 1008..1086)
  PASS: ruling record widens the follow-up to any answered entry (range 1008..1086, line wraps folded)
  PASS: answer pin '(orchestrator):' (line 1090, range 1086..1272)
  PASS: answer pin 'decided (orchestrator)' (line 1090, range 1086..1272)
  PASS: answer pin 'amend plan:' (line 1108, range 1086..1272)
  PASS: answer pin 'plan governs:' (line 1106, range 1086..1272)
  PASS: answer pin 'fix it:' (line 1101, range 1086..1272)
  PASS: answer pin 'accept:' (line 1117, range 1086..1272)
  PASS: answer pin '**Amendment' (line 1244, range 1086..1272)
  PASS: answer pin '[task <n>/<k>]' (line 1144, range 1086..1272)
  PASS: answer fragment '(amended by ruling' (line 1230, range 1086..1272)
  PASS: answer fragment 'never apply the amendment twice' (line 1250, range 1086..1272)
  PASS: answer fragment 'new invocation' (line 1264, range 1086..1272)
  PASS: answer fragment 'untagged' (line 1098, range 1086..1272)
  PASS: answer fragment 'sides against binding plan text' (line 1154, range 1086..1272)
  PASS: answer fragment '**The quoted clause, and how it is compared.**' (line 1120, range 1086..1272)
  PASS: answer fragment 'test whether the quote is a prefix of it' (line 1129, range 1086..1272)
  PASS: amendment never deletes a clause outright (range 1086..1272, line wraps folded)
  PASS: the no-delete bound covers reference text too (range 1086..1272, line wraps folded)
  PASS: amendment step 1 keeps the clause under the no-delete bound (range 1086..1272, line wraps folded)
  PASS: amendment appends an exception scoped to the ruling's item (range 1086..1272, line wraps folded)
  PASS: answer pin 'escalated (irreversible)' (line 1112, range 1086..1272)
  PASS: the amendment procedure is scoped to the amendments still the orchestrator's (range 1086..1272, line wraps folded)
  PASS: ruling writes have a fixed order (range 1008..1086, line wraps folded)
  PASS: ruling record bounds the marker's authority to a backing entry (line 1052, range 1008..1086)
  PASS: the marker check is not the Resume-only check (range 1008..1086, line wraps folded)
  PASS: an unbacked marker is reference text, not decided wording (range 1008..1086, line wraps folded)
  PASS: the marker's ruling number is compared as a whole number (range 1008..1086, line wraps folded)
  PASS: the secret rule covers every file a ruling commit touches (range 1008..1086, line wraps folded)
  PASS: the secret rule's field list is open, not closed (range 1008..1086, line wraps folded)
  PASS: the secret rule names the Resolution field (range 1008..1086, line wraps folded)
  PASS: normalization also replaces a double quotation mark (range 1086..1272, line wraps folded)
  PASS: amendment lookup escalates when no clause matches (range 1086..1272, line wraps folded)
  PASS: a re-derived conflict keeps its answered number (range 1086..1272, line wraps folded)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry pin '## RULING' (line 1278, range 1272..1379)
  PASS: log-entry pin 'Re-dispatch:' (line 1283, range 1272..1379)
  PASS: log-entry pin 'Re-dispatch: none' (line 1325, range 1272..1379)
  PASS: log-entry pin 'Ruled:' (line 1328, range 1272..1379)
  PASS: log-entry pin 'chore(orchestration): <slug> ruling <n>' (line 1304, range 1272..1379)
  PASS: guard pin 'plan governs (orchestrator decision)' (line 1391, range 1379..1427)
  PASS: guard fragment forbidding a byte-equal match (range 1379..1427, line wraps folded)
  PASS: log-entry sentence, byte-exact incl. punctuation (range 1272..1379, line wraps folded, case-sensitive)
  PASS: log-entry sentence carries no '*' emphasis marker around it
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (range 1272..1379, line wraps folded)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (range 1272..1379, line wraps folded)
  PASS: log-entry fragment 'previous invocation left' (line 1318, range 1272..1379)
  PASS: self-check escalates a bare fix it on binding text (line 1298, range 1272..1379)
  PASS: cap counts a Phase 3 task in either line form (line 1343, range 1272..1379)
  PASS: RULING Forks line carries the planned count (line 1282, range 1272..1379)
  PASS: guard fragment 'durable marker' (line 1376, range 1272..1379)
  PASS: guard fragment 'a Critical is never rejected' (line 1401, range 1379..1427)
  PASS: guard fragment 'quotes its clause' (line 1384, range 1379..1427)
  PASS: guard fragment 'recorded when it is made' (line 1404, range 1379..1427)
  PASS: guard count word is 'Four' (range 1379..1427, line wraps folded, case-sensitive)
  PASS: guard 4 states a user decision is never overturned (line 1407, range 1379..1427)
  PASS: guard 4 fragment 'read your ruling record' (line 1408, range 1379..1427)
  PASS: guard 4 fragment 'recorded answer tagged `(user)`' (line 1409, range 1379..1427)
  PASS: guard 4 fragment 'under the class that first sent it to the user' (line 1413, range 1379..1427)
  PASS: guard 4 fragment 'you never re-answer it in the' (line 1417, range 1379..1427)
  PASS: guard 4 escalates when the clause match is unsure (range 1379..1427, line wraps folded)
  PASS: guard 4 names a fallback class for a forced or design entry (range 1379..1427, line wraps folded)
  PASS: cap matches the whole bracketed token (line 1344, range 1272..1379)
  PASS: cap tests the Re-dispatch value, not the line's first word (range 1272..1379, line wraps folded)
  PASS: a stop skips an entry already carrying a follow-up (range 1272..1379, line wraps folded)
  PASS: guard 1 says a quotable clause is not by itself a reason (range 1379..1427, line wraps folded)
  PASS: guard 4 ignores a clause-less follow-up (range 1379..1427, line wraps folded)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (range 246..300, line wraps folded)
  PASS: Phase 4 routes open items to the predicate (range 300..329, line wraps folded)
  PASS: Phase 5 report lists unsettled contradictions (range 329..351, line wraps folded)
  PASS: log-format pin '## RULING' (line 375, range 351..420)
  PASS: log-format pin 'Owed probe:' (line 393, range 351..420)
  PASS: log-format pin 'ruling <n> follow-up' (line 418, range 351..420)
  PASS: log-format pin 'Open: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>' (line 391, range 351..420)
  PASS: log-format pin 'Ruled: [<id>] <forced|design> — <answer>' (line 392, range 351..420)
  PASS: state.md carries the Rulings line (line 430, range 420..433)
  PASS: resume pin '## RULING' (line 469, range 433..624)
  PASS: resume pin 'Ruled:' (line 502, range 433..624)
  PASS: resume pin '**Follow-up:**' (line 505, range 433..624)
  PASS: resume pin '(orchestrator)' (line 515, range 433..624)
  PASS: resume pin '(user)' (line 516, range 433..624)
  PASS: resume pin 'decided (<who>)' (line 566, range 433..624)
  PASS: resume pin 'The Phase 3 answer set — one rule' (line 518, range 433..624)
  PASS: resume recovers the pre-amendment clause from the ruling commit (line 542, range 433..624)
  PASS: resume compares the printed subject with the full expected string (range 433..624, line wraps folded)
  PASS: Resume step 3 never names decided (user) without decided (orchestrator) beside it
  PASS: resume ruling-commit lookup prints the hash (line 534, range 433..624)
  PASS: resume ruling-commit lookup keeps exactly one subject (range 433..624, line wraps folded)
  PASS: resume copies the clause, never the whole printed file (range 433..624, line wraps folded)
  PASS: resume reverts an orphan amendment marker (range 433..624, line wraps folded)
  PASS: stop policy fragment 'escalated' (line 1449, range 1427..1463)
  PASS: stop policy fragment 'fork review unavailable' (line 1451, range 1427..1463)
  PASS: stop policy states the stopped commit's staging rule (line 1433, range 1427..1463)
  PASS: stop policy forbids 'git add -A' for a stopped commit (line 1435, range 1427..1463)
  PASS: stop policy forbids 'git add .' for a stopped commit (line 1436, range 1427..1463)
  PASS: stop policy forbids 'git commit -a' for a stopped commit (line 1436, range 1427..1463)
  PASS: stop policy names the only files a stopped commit stages (range 1427..1463, line wraps folded)
  PASS: the Resume rebuild path stages its stopped commit by explicit path (range 433..624, line wraps folded)
  PASS: the escalated-return stop stages its stopped commit by explicit path (range 1272..1379, line wraps folded)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin '— clause:' (line 793, range 776..946)
  PASS: multi-code-review pin 'clause: none' (line 939, range 776..946)
  PASS: multi-code-review pin '(plan-mandated) — at ' (line 793, range 776..946)
  PASS: multi-code-review pin 'cut it to 160 characters' (line 928, range 776..946)
  PASS: multi-code-review pin '**Normalization is one rule:**' (line 923, range 776..946)
  PASS: multi-code-review pin 'one sentence or one list entry, never a whole section' (line 924, range 776..946)
  PASS: multi-code-review pin 'tests the quote as a **prefix**' (line 934, range 776..946)
  PASS: multi-code-review pin 'No consumer compares the quote with the raw plan text' (line 935, range 776..946)
  PASS: multi-code-review pin 'decided (orchestrator)' (line 1024, range 946..1133)
  PASS: multi-code-review pin 'decided (<who>)' (line 990, range 946..1133)
  PASS: multi-code-review pin 'plan governs (orchestrator decision)' (line 978, range 946..1133)
  PASS: multi-code-review pin 'plan governs (user decision)' (line 977, range 946..1133)
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`' (line 1043, range 946..1133)
  PASS: multi-code-review pin 'unresolved: fix contradicts binding text' (line 996, range 946..1133)
  PASS: M = 1 log-format example carries the clause (line 793, range 784..799)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 814, range 799..818)
  PASS: multi-code-review normalization replaces a double quotation mark (line 927, range 776..946)
  PASS: multi-code-review names all three replacements as one rule (range 776..946, line wraps folded)
  PASS: addendum shapes include an unresolved line (line 861, range 776..946)
  PASS: the binding-text test is stated where the refusal rule lives (range 946..1133, line wraps folded)
  PASS: binding-text test names the Exact content block (line 1004, range 946..1133)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..703)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 681, range 623..703)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..703)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..703)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..703)
  PASS: loop-side rule fragment 'never edits plan text' (line 687, range 623..703)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 689, range 623..703)
  PASS: loop bounds the marker's authority to a backing entry (line 664, range 623..703)
  PASS: loop names the ruling-record path it checks the marker against (line 667, range 623..703)
  PASS: loop treats an unbacked marker as reference text (range 623..703, line wraps folded)
  PASS: loop compares the marker's ruling number as a whole number (range 623..703, line wraps folded)
  PASS: loop covers the no-TOPIC_DIR case, where no record exists (range 623..703, line wraps folded)
9. Controller prompt templates (R10)
  PASS: Deviation 3 pins the fixed secret disposition form (line 109, range 94..119)
  PASS: Deviation 3 says the leading text is fixed (range 94..119, line wraps folded)
  PASS: Deviation 3 names the real mechanism: the secret class stops the run (range 94..119, line wraps folded)
  PASS: Deviation 3 forbids copying the value into the line (range 94..119, line wraps folded)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 222, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '`(orchestrator)` or `(user)`' (line 222, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 223, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 222, range 218..225)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 129, range 125..186)
  PASS: code-review-loop Deviation 5 pin 'tagged `(orchestrator)` or `(user)`' (line 129, range 125..186)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 145, range 125..186)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 170, range 125..186)
  PASS: code-review-loop Deviation 5 treats an untagged line as a user line (range 125..186, line wraps folded)
  PASS: batch-controller Resume Answer heading states the omit condition (line 71, range 1..189)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 195, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 196, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 193, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 196, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] carries the run-wide answer set (range 189..203, line wraps folded)
  PASS: First-batch parameter defers to Deviation 1's pre-flight rule (line 63, range 1..189)
  PASS: batch-controller Deviation 1 pin '### Question <k>' (line 81, range 77..125)
  PASS: batch-controller Deviation 1 pin '### Conflict <k>' (line 82, range 77..125)
  PASS: batch-controller Deviation 1 pin 'lowest-numbered task' (line 100, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Pre-flight rule' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'absent from' (line 104, range 77..125)
  PASS: batch-controller Deviation 1 pin '.superpowers/sdd/task-<n>-report.md' (line 80, range 77..125)
  PASS: batch-controller Deviation 1 pin 'is settled' (line 108, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Never copy a secret or a credential' (line 121, range 77..125)
  PASS: batch-controller Deviation 1 pin 're-used on the same task' (line 84, range 77..125)
  PASS: batch-controller Deviation 1 pin 'those sections before you write your own' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'controller failure' (line 120, range 77..125)
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 109, range 77..125)
  PASS: Deviation 1 allocates a new section number above the highest visible one (range 77..125, line wraps folded)
  PASS: Deviation 1 never renumbers a section written in this dispatch (range 77..125, line wraps folded)
  PASS: Deviation 1 keys the stale-section deletion on this run's own work (line 92, range 77..125)
  PASS: Deviation 1 rejects the answer line as the first-dispatch signal (line 94, range 77..125)
  PASS: batch-controller re-derived conflict pin 're-use that `<k>`, apply the answer' (line 116, range 77..125)
  PASS: batch-controller re-derived conflict pin 'Allocate a new `<k>` only for a' (line 117, range 77..125)

Results: 244 passed, 0 failed
exit=0

```

## Round 8 verification cycle 1 fixes — 2026-09-04

Findings I1–I2 (Important) and M1, M2, M4–M12 (Minor) of round 8
verification cycle 1, plus I3. One file touched:
`tests/in-run-rulings/run-tests.sh`. No skill file and no template file
changed: every finding of this cycle was a hole in the test suite, and
[M2] and [M10] were defects in the suite's own helper code.

Check count: 244 → 287.

### Findings addressed

- **I1 — the ruling-record entry template and the `## RULING` example
  block were barely pinned.** Two additions.
  (a) In the "4. Ruling record, answers and plan amendment" section, a new
  loop pins each of the entry template's six field lines as a WHOLE field
  line with its placeholder tail — `- **Class:** …`, `- **Item:** …`,
  `- **Contract clause:** …`, `- **Defensible answers:** …`,
  `- **Forks:** …`, `- **Resolution:** …` — plus the entry's heading line
  `## Ruling <n> — YYYY-MM-DD — phase <p> — [<id>] <short title>`, all in
  "exact" mode and scoped to `RECORD_LINE..RECORD_END`. Whole field lines
  are required because `**Item:**` and `**Resolution:**` also occur in the
  "Never reproduce a secret" prose of that same subsection, which is what
  made the old single `**Resolution:**` needle useless.
  (b) In "5. RULING log entry, cap and guards", a new loop pins the
  `## RULING` example block's six lines, each whole with its placeholder
  tail: the header line, both `Items:` shapes, `Detail:`, `Forks:` and
  `Re-dispatch:`, scoped to `LOG_ENTRY_LINE..LOG_ENTRY_END`.

- **I2 — the `[RESUME_ANSWER]` tag-to-`<who>` mapping was not pinned on
  the skill side.** Two folded assertions added in section 7, scoped to
  `MCR_AFTER_LOOP_LINE..MCR_ERROR_HANDLING_LINE`:
  ``tagged `(orchestrator)` or `(user)`; an untagged line is a user line``
  and ``or `decided (user): <answer>`, `<who>` taken from the tag``.

- **I3 — the two orchestrator-answer mappings had no assertion.** Four
  assertions added in section 7, same range: an exact pin on the `accept:`
  disposition shape ``` `decided (<who>): accept: ```; a folded pin on
  "line is its whole disposition, it no longer counts as unresolved, and
  no fix or re-review runs"; a folded pin on ``An `amend plan: …; fix
  it: …` answer takes the finding-governs path for its `fix it` part``;
  and a folded pin on "the verification re-review is skipped and the new
  invocation that always follows reviews the fix".

- **M1 — the stop policy's three command pins could not tell a
  prohibition from a recommendation.** A folded assertion now pins the
  forbidding sentence itself, with its verb and all three commands:
  ``Never `git add -A` and never `git add .`, and never `git commit -a`.``
  The three bare pins are kept, retitled "stop policy names '<X>' for a
  stopped commit", as additional weaker checks on each command's spelling.

- **M2 — `awk -v` escape-processes the value it assigns.** All three
  places now pass the needle and the folded haystack through the
  environment instead: `assert_in_range_folded`,
  `assert_in_range_folded_exact` and the cap-sentence emphasis block read
  `ENVIRON["needle"]` and `ENVIRON["hay"]`.

- **M4 — the Phase 3 answer set's definition had no assertion of its
  own.** Two assertions added in section 4, scoped to
  `ANSWERS_LINE..ANSWERS_END`: an exact pin on
  `**The Phase 3 answer set — one rule.**` and a folded pin on ``every
  ruled `[task <n>/<k>]` line recorded for this run, for every task,
  whatever batch the task belongs to``. The Resume-range check on the same
  string is left in place as the cross-reference pin.

- **M5 — three unpinned rules.** (a) Phase 5's accept-list requirement:
  folded pin ``every entry whose Resolution line begins with `accept:`,
  listed by ruling number``, scoped to `PHASE5_LINE..LOG_FORMAT_LINE`.
  (b) The cap's reset anchor: folded pin ``the orchestration log's latest
  `_Invocation` line and its latest `## STOPPED` entry, so that a resume
  after a stop starts from zero``, scoped to
  `LOG_ENTRY_LINE..LOG_ENTRY_END`. (c) Phase 3 step 5's rule: folded pin
  ``A `BLOCKED task=<n>` return writes no batch entry``, scoped to
  `PHASE3_LINE..PHASE4_LINE`.

- **M6 — the first-dispatch pin dropped the negation.** A folded
  assertion now carries it: ``never by the absence of a `[task <n>…]` line
  in `## Resume Answer` ``, scoped to `DEV1_LINE..DEV1_END`. The old byte
  pin is kept, retitled "Deviation 1 spells the rejected first-dispatch
  signal exactly", as the weaker spelling check.

- **M7 — three sentences of the classification contract had no
  assertion.** Three folded pins added in section 1, scoped to
  `CLASS_LINE..CLASS_END`: "a fact that makes every other outcome
  indefensible", "never reaches the predicate either", and
  `**Phase 5** stays the user's`.

- **M8 — the fork subsection's numbers were unpinned.** Six assertions
  added in section 3, scoped to `FORK_LINE..FORK_END`: folded pins on
  "The default is three forks", on the two-fork condition ("when the
  item's `file:line` names a single file and none of the outcomes you
  tabled amends the plan") and on the threshold ("needs at least two
  usable fork returns"); plus a loop of four exact pins, one per lens,
  each on the lens's own defining bullet rather than on the bare lens name
  (three of the four names also occur in the "default is three forks"
  sentence and in the fork prompt).

- **M9 — the Phase 4 answer vocabulary was pinned only by single
  tokens.** A loop of four exact pins added in section 4, each on the
  bullet's own defining bytes: ``` `fix it: <what the fix must achieve>` —
  the finding is accepted ```, `plan governs: "<verbatim clause>" —
  <source path>`, `amend plan: <the amendment>; fix it: <what the fix must
  achieve>`, ``` `accept: <reason>` — for an `unresolved` item only ```;
  plus a folded pin on the rule inside the `fix it` bullet, "a bare `fix
  it` never authorises a fix against binding text". The four bare-label
  pins are kept unchanged.

- **M10 — the cap-sentence emphasis check did not survive a line wrap.**
  The check now steps over any spaces on each side of the match before it
  looks for a `*` run, and tells emphasis on the sentence from a
  neighbouring bold span by the run's OTHER side: a `*` run before the
  match whose own left neighbour is a space (or the start of the text)
  OPENS a span around the sentence, while one whose left neighbour is any
  other character CLOSES an earlier span — which is what the paragraph's
  `**The cap.**` lead-in is. The mirror rule applies after the match.

- **M11 — the `(user)` needle in the resume pin loop was dead.** It is
  replaced by a folded assertion on the enumerating bytes the branch
  actually added: ``each tagged `(orchestrator)`, plus the resume prompt's
  answers, each tagged `(user)` ``. The loop's other six pins are
  unchanged.

- **M12 — the log-format loop's comment did not describe three of its
  needles.** `## RULING` and `Owed probe:` are extended to whole field
  lines with their placeholder tails (`## RULING <n> — YYYY-MM-DD — phase
  <p> — <one-line summary>` and `Owed probe: <verbatim line>`), and
  `ruling <n> follow-up` is moved out of the loop into its own assertion
  with a comment saying what it pins (the boundary-commit subject list,
  not an example line). The two short labels are kept as separate weaker
  checks in a second loop, so no check is lost.

### Mutation check on the new and repaired assertions

Each mutation was applied to the source file in place, the suite run, and
the file restored with `git checkout --`. The baseline is
`287 passed, 0 failed`.

| Finding | Mutation | Result |
| --- | --- | --- |
| I1 (a) | Deleted the ruling-record entry's heading line and its six field lines | `279 passed, 8 failed` — the seven new pins plus the pre-existing `<k> of <planned>` pin |
| I1 (b) | Deleted the `## RULING` example's fence opening, header, both `Items:` lines and `Detail:` line | `283 passed, 4 failed` |
| I2 | Reworded the passage back to a form with no tag and no `<who>` mapping | `285 passed, 2 failed` |
| I3 | Deleted the whole `amend plan` / `accept` mapping paragraph | `283 passed, 4 failed` |
| M1 | Inverted the prohibition into ``Use `git add -A` or `git add .`, or `git commit -a`.`` | `286 passed, 1 failed` — the new folded pin only; the three bare pins still passed, which is the defect the finding named |
| M4 | Deleted the `**The Phase 3 answer set — one rule.**` paragraph | `285 passed, 2 failed` |
| M5 (a) | Deleted the Phase 5 accept-list clause | `286 passed, 1 failed` |
| M5 (b) | Deleted the cap's reset anchor clause | `286 passed, 1 failed` |
| M5 (c) | Deleted "A `BLOCKED task=<n>` return writes no batch entry: …" | `286 passed, 1 failed` |
| M6 | Replaced "never by" with "or by" (rule inverted) | `286 passed, 1 failed` |
| M7 | Reworded the `forced` test, the transient exclusion and the Phase 5 exclusion away | `284 passed, 3 failed` |
| M8 | Changed "three forks" to "one fork", reworded the two-fork condition, deleted three lens bullets, changed the threshold to "at least one usable fork return" | `281 passed, 6 failed` |
| M8 | Deleted the `adversarial` lens bullet alone | `286 passed, 1 failed` |
| M9 | Deleted the whole Phase 4 answer definition list | `280 passed, 7 failed` — the four new definition pins and the bare-`fix it` rule, plus two of the pre-existing bare-label pins |
| M10 | Wrapped the cap sentence in `**` markers separated from it by a line wrap on BOTH sides | `286 passed, 1 failed` ("log-entry sentence is wrapped in a '*' emphasis marker"). The old single-character test was run on the same folded string and returned `clean`, so this mutation was invisible before the fix. |
| M10 (control) | Added a bold lead-in `**The count.**` immediately AFTER the sentence | `287 passed, 0 failed` — no false positive |
| M11 | Removed the per-line `(orchestrator)`/`(user)` tagging from Resume step 3 | `286 passed, 1 failed` |
| M12 | Reworded the two example lines so they keep their short label but lose their placeholder tail | `285 passed, 2 failed` — the two new whole-line pins failed while the two bare-label pins still passed, which is exactly the gap the finding named |
| M12 | Removed the ``ruling <n> follow-up`` commit subject from the log format | `286 passed, 1 failed` |

**M2 adds no assertion**, so there is no rule to delete or invert. It was
verified directly against the two awk value paths, on the awk this machine
runs (`/usr/bin/awk`, BWK awk; no `gawk` or `mawk` installed):

```
$ V='value with a line continuation: a\nb and an escaped paren \( end'
$ awk -v x="$V" 'BEGIN{ print x; print "length=" length(x) }'
value with a line continuation: a
b and an escaped paren ( end
length=62
$ x="$V" awk 'BEGIN{ v=ENVIRON["x"]; print v; print "length=" length(v) }'
value with a line continuation: a\nb and an escaped paren \( end
length=64
```

`awk -v` rewrote 64 bytes into 62: it turned `\n` into a real newline and
dropped the backslash of `\(`. `ENVIRON` passed every byte through
unchanged. No pinned range carries a backslash today, so no check changes
its verdict from this fix — the suite reports `287 passed, 0 failed`
before and after — but the folded helpers now compare the file's bytes
rather than an escape-processed rewrite of them, and the cap-sentence
emphasis block computes its positions on those same unmodified bytes.

### Commands run

All three write zero bytes to standard error.

```
$ bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/reviewer-templates/run-tests.sh
1. Harness claims rule is inside the prompt block
  PASS: doc-review template: Harness claims rule inside the prompt block (line 42, block 25..133)
  PASS: code-review template: Harness claims rule inside the prompt block (line 64, block 24..193)
2. Finding-format field spellings
  PASS: doc-review template: field spelling 'harness: tested —'
  PASS: doc-review template: field spelling 'harness: untested —'
  PASS: code-review template: field spelling 'harness: tested —'
  PASS: code-review template: field spelling 'harness: untested —'
3. Controller triage reason strings and completion-report line
  PASS: multi-doc-review SKILL.md: reason string 'harness probe —'
  PASS: multi-doc-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-doc-review SKILL.md: completion-report line 'Harness probes owed:'
  PASS: multi-code-review SKILL.md: reason string 'harness probe —'
  PASS: multi-code-review SKILL.md: reason string 'harness probe not runnable here'
  PASS: multi-code-review SKILL.md: completion-report line 'Harness probes owed:'
4. user-decision guard
  PASS: multi-code-review SKILL.md: guard fragment
5. Rule text drift between the two templates
  PASS: doc-review template: rule extract is non-empty
  PASS: code-review template: rule extract is non-empty
  PASS: rule text identical in both templates
6. Unchanged contracts
  PASS: code-review template: blinding pathspec line
  PASS: code-review template: report marker instruction
  PASS: doc-review template: report marker instruction
7. Ambiguity & testability plan-cell contract targets
  PASS: multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty
  PASS: Ambiguity plan cell: fragment 'no stated contract'
  PASS: Ambiguity plan cell: fragment 'self-pin'
  PASS: Ambiguity plan cell: gate label '**Body authority:**'
8. Body-authority gate label consistency (writing-plans vs multi-doc-review)
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
exit=0
```

```
$ bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/writing-plans/run-tests.sh
1. Contracts and Literal Bodies section (R1)
  PASS: section heading '## Contracts and Literal Bodies' (whole-line match, line 122)
  PASS: exact-content label '**Exact content:**' (rule 4) (line 172, range 170..184)
  PASS: procedural tie-break fragment 'treat the block as not procedural' (rule 1) (line 149, range 129..154)
  PASS: authority-default fragment 'ordinary fix' (rule 3) (line 166, range 163..170)
  PASS: self-pin fragment 'together as one ordinary fix' (rule 5) (line 187, range 184..194)
2. Task Template Contract field (R2)
  PASS: Task Template block carries '**Contract:**' (line 261, block 249..291)
3. Plan Header authority note (R3)
  PASS: Plan Header template carries 'reference implementations' (line 86, block 81..96)
  PASS: Plan Header template carries '**Body authority:**' (line 86, block 81..96)
  PASS: Plan Header note states the closed binding set 'Exactly two things in this plan bind' (line 86, block 81..96)
  PASS: Plan Header note states the exact-content binding condition 'names a pin this plan does not itself write or edit' (line 86, block 81..96)
  PASS: Plan Header note states the residue clause 'Everything else is reference' (line 86, block 81..96)
  PASS: Plan Header note states the non-conflict disposition 'is never a plan conflict: record it against the plan-writing skill' (line 86, block 81..96)
  PASS: Plan Header note states the disposition's scoping guard 'covers the note's own text alone' (line 86, block 81..96)
4. Self-Review contract audit (R4)
  PASS: self-review fragment 'falsifiable' (check 5) (line 338, range 338..340)
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
exit=0
```

```
$ bash /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/tests/in-run-rulings/run-tests.sh
0. Section anchors
  PASS: '## In-run rulings' precedes '## Major-Error Stop Policy' (lines 624..1427)
  PASS: no other '## ' heading (outside a fenced code block) between 624 and 1427
1. Escalation predicate (R1)
  PASS: section heading '## In-run rulings' (whole-line match, line 624)
  PASS: class or reason label `escalated` (line 659, range 654..783)
  PASS: class or reason label `forced` (line 662, range 654..783)
  PASS: class or reason label `design` (line 667, range 654..783)
  PASS: class or reason label `spec wrong` (line 674, range 654..783)
  PASS: class or reason label `scope` (line 678, range 654..783)
  PASS: class or reason label `irreversible` (line 682, range 654..783)
  PASS: class or reason label `secret` (line 709, range 654..783)
  PASS: class or reason label `chain` (line 725, range 654..783)
  PASS: class or reason label escalated (chain) (line 726, range 654..783)
  PASS: predicate fragment 'escalation wins' (line 660, range 654..783)
  PASS: predicate fragment '### Conflict' (line 700, range 654..783)
  PASS: predicate fragment '### Question' (line 701, range 654..783)
  PASS: predicate fragment 'fatal environment failure' (line 729, range 654..783)
  PASS: predicate fragment 'never `spec wrong`' (line 738, range 654..783)
  PASS: predicate fragment 'handled as a whole' (line 773, range 654..783)
  PASS: predicate fragment 'applied twice' (line 776, range 654..783)
  PASS: the forced test is the one sentence that makes every other outcome indefensible (range 654..783, line wraps folded)
  PASS: a transient external problem never reaches the predicate (range 654..783, line wraps folded)
  PASS: Phase 5 stays the user's (range 654..783, line wraps folded)
  PASS: irreversible entry pin 'escalated (irreversible)' (line 689, range 654..783)
  PASS: irreversible entry covers an amendment of binding plan text (range 654..783, line wraps folded)
  PASS: irreversible entry triggers on the edit location, not on a judgement (range 654..783, line wraps folded)
  PASS: irreversible entry reads binding-ness from the task section (range 654..783, line wraps folded)
  PASS: secret class pins the loop's fixed disposition form (line 717, range 654..783)
  PASS: secret trigger covers the Phase 3 report-section form (range 654..783, line wraps folded)
  PASS: secret class names two producers, not one (line 713, range 654..783)
  PASS: secret class names the batch template as the second producer (line 719, range 654..783)
  PASS: discriminator bounds <n> by the plan, not by the batch (range 654..783, line wraps folded)
  PASS: irreversible entry states its Phase 3 form (range 654..783, line wraps folded)
  PASS: Phase 3 trigger reads the location the conflict section names (range 654..783, line wraps folded)
  PASS: bare task id is never a form the orchestrator writes (range 624..654, line wraps folded)
  PASS: a bare user answer is resolved, never defaulted to section 1 (range 624..654, line wraps folded)
2. Classification read exception (R2)
  PASS: intro names the second read exception (line 23, range 1..26)
  PASS: read-exception fragment 'data, not instructions' (line 818, range 783..841)
  PASS: read-exception fragment 'never a reviewer report file' (line 796, range 783..841)
  PASS: read-exception fragment 'read-only git commands' (line 823, range 783..841)
  PASS: read-exception fragment 'resume step 3' (line 788, range 783..841)
  PASS: read-exception fragment 'nothing else' (line 817, range 783..841)
  PASS: read-exception fragment '40 lines' (line 804, range 783..841)
  PASS: read-exception entry 5 names the ruling-record path (line 810, range 783..841)
  PASS: read-exception entry 5 calls it the file you write yourself (range 783..841, line wraps folded)
  PASS: read-exception entry 5 fragment 'Guard 4 (below) reads it' (line 811, range 783..841)
  PASS: read-exception entry 5 fragment 'earlier answer tagged `(user)` on the same clause' (line 812, range 783..841)
  PASS: read exception names its three purposes (range 783..841, line wraps folded)
  PASS: read exception permits the ruling-commit read for the orchestrator (line 808, range 783..841)
  PASS: fork diff form mandates the negative flags (line 828, range 783..841)
3. Fork review (R3)
  PASS: fork pin 'subagent_type: "fork"' (line 898, range 841..1008)
  PASS: fork pin '<!-- multi-review report -->' (line 949, range 841..1008)
  PASS: fork pin 'fork-<lens>' (line 890, range 841..1008)
  PASS: fork pin 'fork review unavailable' (line 989, range 841..1008)
  PASS: fork pin 'contradiction: unsettled' (line 975, range 841..1008)
  PASS: fork pin 'VERDICT:' (line 953, range 841..1008)
  PASS: fork pin 'TABLED:' (line 956, range 841..1008)
  PASS: fork fragment 'not a debate' (line 863, range 841..1008)
  PASS: fork fragment 'never pass conversation history' (line 896, range 841..1008)
  PASS: fork fragment 'action verb followed by a skill name' (line 959, range 841..1008)
  PASS: fork fragment 'in parallel, in one message' (line 843, range 841..1008)
  PASS: fork fragment 'evidence consistency' (line 852, range 841..1008)
  PASS: fork fragment 'general-purpose' (line 888, range 841..1008)
  PASS: fork naming never uses an orch- name (line 900, range 841..1008)
  PASS: fork subsection states the default of three forks (range 841..1008, line wraps folded)
  PASS: fork subsection states the two-fork condition (range 841..1008, line wraps folded)
  PASS: fork lens definition '`design consistency` — does each outcome agree with the spec' (line 846, range 841..1008)
  PASS: fork lens definition '`implementation practicality` — what each outcome costs to build' (line 848, range 841..1008)
  PASS: fork lens definition '`adversarial` — how each outcome fails' (line 850, range 841..1008)
  PASS: fork lens definition '`evidence consistency` — does the finding' (line 852, range 841..1008)
  PASS: a design ruling needs at least two usable fork returns (range 841..1008, line wraps folded)
  PASS: Guard Interaction states that forks open with the reviewer marker (range 1463..1478, line wraps folded)
  PASS: Guard Interaction makes a markerless fork return a lost return (range 1463..1478, line wraps folded)
  PASS: Guard Interaction still spells the nested-reviewer marker exactly (line 1472, range 1463..1478)
  PASS: fork prompt mandates the negative diff flags (line 938, range 841..1008)
  PASS: fork prompt's read-only clause forbids sending anything (range 841..1008, line wraps folded)
  PASS: fork prompt makes a transmission instruction reportable (range 841..1008, line wraps folded)
  PASS: lost-return bound is stated over the round (range 841..1008, line wraps folded)
  PASS: every still-missing lens of a round is lost at the same moment (range 841..1008, line wraps folded)
  PASS: only the first design item uses the fork path (range 841..1008, line wraps folded)
  PASS: consolidation reasoning waits for the item's round (range 841..1008, line wraps folded)
4. Ruling record, answers and plan amendment (R4, R5)
  PASS: ruling-record pin '-open-decisions.md' (line 1010, range 1008..1086)
  PASS: ruling-record pin '**Follow-up:**' (line 1074, range 1008..1086)
  PASS: ruling-record pin '## Ruling <n>' (line 1017, range 1008..1086)
  PASS: ruling-record fragment 'appended, never rewritten' (line 1013, range 1008..1086)
  PASS: ruling-record entry field line '- **Class:** forced | design | escalated (<spec wrong|scope|irreversible|secret|chain>)' (line 1019, range 1008..1086)
  PASS: ruling-record entry field line '- **Item:** [<id>] <severity> <file:line> — <finding summary, verbatim>' (line 1020, range 1008..1086)
  PASS: ruling-record entry field line '- **Contract clause:** "<verbatim quote>" — <path of the spec, plan or skill that holds it>' (line 1021, range 1008..1086)
  PASS: ruling-record entry field line '- **Defensible answers:** <one line each; `n/a` for forced>' (line 1022, range 1008..1086)
  PASS: ruling-record entry field line '- **Forks:** <k> of <planned> — <lens>: <VERDICT line>' (line 1023, range 1008..1086)
  PASS: ruling-record entry field line '- **Resolution:** <the answer as written into [RESUME_ANSWER]>' (line 1024, range 1008..1086)
  PASS: ruling-record entry heading line carries its placeholder tail (line 1017, range 1008..1086)
  PASS: ruling-record Forks field carries the planned count (line 1023, range 1008..1086)
  PASS: ruling record widens the follow-up to any answered entry (range 1008..1086, line wraps folded)
  PASS: answer pin '(orchestrator):' (line 1090, range 1086..1272)
  PASS: answer pin 'decided (orchestrator)' (line 1090, range 1086..1272)
  PASS: answer pin 'amend plan:' (line 1108, range 1086..1272)
  PASS: answer pin 'plan governs:' (line 1106, range 1086..1272)
  PASS: answer pin 'fix it:' (line 1101, range 1086..1272)
  PASS: answer pin 'accept:' (line 1117, range 1086..1272)
  PASS: answer pin '**Amendment' (line 1244, range 1086..1272)
  PASS: answer pin '[task <n>/<k>]' (line 1144, range 1086..1272)
  PASS: Phase 4 answer definition '`fix it: <what the fix must achieve>` — the finding is accepted' (line 1101, range 1086..1272)
  PASS: Phase 4 answer definition 'plan governs: "<verbatim clause>" — <source path>' (line 1106, range 1086..1272)
  PASS: Phase 4 answer definition 'amend plan: <the amendment>; fix it: <what the fix must achieve>' (line 1108, range 1086..1272)
  PASS: Phase 4 answer definition '`accept: <reason>` — for an `unresolved` item only' (line 1117, range 1086..1272)
  PASS: a bare fix it never authorises a fix against binding text (range 1086..1272, line wraps folded)
  PASS: the Phase 3 answer set is defined once, here (line 1169, range 1086..1272)
  PASS: the Phase 3 answer set carries every ruled line of the run (range 1086..1272, line wraps folded)
  PASS: answer fragment '(amended by ruling' (line 1230, range 1086..1272)
  PASS: answer fragment 'never apply the amendment twice' (line 1250, range 1086..1272)
  PASS: answer fragment 'new invocation' (line 1264, range 1086..1272)
  PASS: answer fragment 'untagged' (line 1098, range 1086..1272)
  PASS: answer fragment 'sides against binding plan text' (line 1154, range 1086..1272)
  PASS: answer fragment '**The quoted clause, and how it is compared.**' (line 1120, range 1086..1272)
  PASS: answer fragment 'test whether the quote is a prefix of it' (line 1129, range 1086..1272)
  PASS: amendment never deletes a clause outright (range 1086..1272, line wraps folded)
  PASS: the no-delete bound covers reference text too (range 1086..1272, line wraps folded)
  PASS: amendment step 1 keeps the clause under the no-delete bound (range 1086..1272, line wraps folded)
  PASS: amendment appends an exception scoped to the ruling's item (range 1086..1272, line wraps folded)
  PASS: answer pin 'escalated (irreversible)' (line 1112, range 1086..1272)
  PASS: the amendment procedure is scoped to the amendments still the orchestrator's (range 1086..1272, line wraps folded)
  PASS: ruling writes have a fixed order (range 1008..1086, line wraps folded)
  PASS: ruling record bounds the marker's authority to a backing entry (line 1052, range 1008..1086)
  PASS: the marker check is not the Resume-only check (range 1008..1086, line wraps folded)
  PASS: an unbacked marker is reference text, not decided wording (range 1008..1086, line wraps folded)
  PASS: the marker's ruling number is compared as a whole number (range 1008..1086, line wraps folded)
  PASS: the secret rule covers every file a ruling commit touches (range 1008..1086, line wraps folded)
  PASS: the secret rule's field list is open, not closed (range 1008..1086, line wraps folded)
  PASS: the secret rule names the Resolution field (range 1008..1086, line wraps folded)
  PASS: normalization also replaces a double quotation mark (range 1086..1272, line wraps folded)
  PASS: amendment lookup escalates when no clause matches (range 1086..1272, line wraps folded)
  PASS: a re-derived conflict keeps its answered number (range 1086..1272, line wraps folded)
5. RULING log entry, cap and guards (R6, R7, R9)
  PASS: log-entry pin '## RULING' (line 1278, range 1272..1379)
  PASS: log-entry pin 'Re-dispatch:' (line 1283, range 1272..1379)
  PASS: log-entry pin 'Re-dispatch: none' (line 1325, range 1272..1379)
  PASS: log-entry pin 'Ruled:' (line 1328, range 1272..1379)
  PASS: log-entry pin 'chore(orchestration): <slug> ruling <n>' (line 1304, range 1272..1379)
  PASS: RULING example line '## RULING <n> — YYYY-MM-DD — phase <p> — <one-line summary>' (line 1278, range 1272..1379)
  PASS: RULING example line 'Items: [<id>] <forced|design> — <answer>' (line 1279, range 1272..1379)
  PASS: RULING example line 'Items: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>' (line 1280, range 1272..1379)
  PASS: RULING example line 'Detail: <topic folder>/plans/<slug>-open-decisions.md' (line 1281, range 1272..1379)
  PASS: RULING example line 'Forks: none | <k> of <planned> (<lens>, <lens>[, <lens>]) — contradiction: none | settled | unsettled' (line 1282, range 1272..1379)
  PASS: RULING example line 'Re-dispatch: phase <p>, in-run resume <r> of 3' (line 1283, range 1272..1379)
  PASS: guard pin 'plan governs (orchestrator decision)' (line 1391, range 1379..1427)
  PASS: guard fragment forbidding a byte-equal match (range 1379..1427, line wraps folded)
  PASS: log-entry sentence, byte-exact incl. punctuation (range 1272..1379, line wraps folded, case-sensitive)
  PASS: log-entry sentence carries no '*' emphasis marker around it
  PASS: log-entry or guard fragment 'in-run resumes of one phase are capped at 3 per unit' (range 1272..1379, line wraps folded)
  PASS: log-entry or guard fragment 'phase itself in Phase 4, the task in Phase 3' (range 1272..1379, line wraps folded)
  PASS: log-entry fragment 'previous invocation left' (line 1318, range 1272..1379)
  PASS: self-check escalates a bare fix it on binding text (line 1298, range 1272..1379)
  PASS: cap counts a Phase 3 task in either line form (line 1343, range 1272..1379)
  PASS: RULING Forks line carries the planned count (line 1282, range 1272..1379)
  PASS: guard fragment 'durable marker' (line 1376, range 1272..1379)
  PASS: guard fragment 'a Critical is never rejected' (line 1401, range 1379..1427)
  PASS: guard fragment 'quotes its clause' (line 1384, range 1379..1427)
  PASS: guard fragment 'recorded when it is made' (line 1404, range 1379..1427)
  PASS: guard count word is 'Four' (range 1379..1427, line wraps folded, case-sensitive)
  PASS: guard 4 states a user decision is never overturned (line 1407, range 1379..1427)
  PASS: guard 4 fragment 'read your ruling record' (line 1408, range 1379..1427)
  PASS: guard 4 fragment 'recorded answer tagged `(user)`' (line 1409, range 1379..1427)
  PASS: guard 4 fragment 'under the class that first sent it to the user' (line 1413, range 1379..1427)
  PASS: guard 4 fragment 'you never re-answer it in the' (line 1417, range 1379..1427)
  PASS: guard 4 escalates when the clause match is unsure (range 1379..1427, line wraps folded)
  PASS: guard 4 names a fallback class for a forced or design entry (range 1379..1427, line wraps folded)
  PASS: cap matches the whole bracketed token (line 1344, range 1272..1379)
  PASS: cap tests the Re-dispatch value, not the line's first word (range 1272..1379, line wraps folded)
  PASS: cap counts from the later of the invocation line and the last stop (range 1272..1379, line wraps folded)
  PASS: a stop skips an entry already carrying a follow-up (range 1272..1379, line wraps folded)
  PASS: guard 1 says a quotable clause is not by itself a reason (range 1379..1427, line wraps folded)
  PASS: guard 4 ignores a clause-less follow-up (range 1379..1427, line wraps folded)
6. Wiring into phases, log format, state.md, Resume and stop policy (R6)
  PASS: Phase 3 routes BLOCKED task=<n> to the predicate (range 246..300, line wraps folded)
  PASS: Phase 4 routes open items to the predicate (range 300..329, line wraps folded)
  PASS: Phase 5 report lists unsettled contradictions (range 329..351, line wraps folded)
  PASS: Phase 5 report lists every accepted ruling (range 329..351, line wraps folded)
  PASS: a BLOCKED task return writes no batch log entry (range 246..300, line wraps folded)
  PASS: log-format example line '## RULING <n> — YYYY-MM-DD — phase <p> — <one-line summary>' (line 375, range 351..420)
  PASS: log-format example line 'Owed probe: <verbatim line>' (line 393, range 351..420)
  PASS: log-format example line 'Open: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>' (line 391, range 351..420)
  PASS: log-format example line 'Ruled: [<id>] <forced|design> — <answer>' (line 392, range 351..420)
  PASS: log format names the follow-up commit subject (line 418, range 351..420)
  PASS: log-format label '## RULING' (line 375, range 351..420)
  PASS: log-format label 'Owed probe:' (line 393, range 351..420)
  PASS: state.md carries the Rulings line (line 430, range 420..433)
  PASS: resume pin '## RULING' (line 469, range 433..624)
  PASS: resume pin 'Ruled:' (line 502, range 433..624)
  PASS: resume pin '**Follow-up:**' (line 505, range 433..624)
  PASS: resume pin '(orchestrator)' (line 515, range 433..624)
  PASS: resume pin 'decided (<who>)' (line 566, range 433..624)
  PASS: resume pin 'The Phase 3 answer set — one rule' (line 518, range 433..624)
  PASS: Resume step 3 tags the Ruled lines and the user's answers per line (range 433..624, line wraps folded)
  PASS: resume recovers the pre-amendment clause from the ruling commit (line 542, range 433..624)
  PASS: resume compares the printed subject with the full expected string (range 433..624, line wraps folded)
  PASS: Resume step 3 never names decided (user) without decided (orchestrator) beside it
  PASS: resume ruling-commit lookup prints the hash (line 534, range 433..624)
  PASS: resume ruling-commit lookup keeps exactly one subject (range 433..624, line wraps folded)
  PASS: resume copies the clause, never the whole printed file (range 433..624, line wraps folded)
  PASS: resume reverts an orphan amendment marker (range 433..624, line wraps folded)
  PASS: stop policy fragment 'escalated' (line 1449, range 1427..1463)
  PASS: stop policy fragment 'fork review unavailable' (line 1451, range 1427..1463)
  PASS: stop policy states the stopped commit's staging rule (line 1433, range 1427..1463)
  PASS: stop policy forbids the three sweeping stage commands (range 1427..1463, line wraps folded)
  PASS: stop policy names 'git add -A' for a stopped commit (line 1435, range 1427..1463)
  PASS: stop policy names 'git add .' for a stopped commit (line 1436, range 1427..1463)
  PASS: stop policy names 'git commit -a' for a stopped commit (line 1436, range 1427..1463)
  PASS: stop policy names the only files a stopped commit stages (range 1427..1463, line wraps folded)
  PASS: the Resume rebuild path stages its stopped commit by explicit path (range 433..624, line wraps folded)
  PASS: the escalated-return stop stages its stopped commit by explicit path (range 1272..1379, line wraps folded)
  PASS: stop policy no longer lists a pre-flight plan conflict as a stop by itself
7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)
  PASS: multi-code-review pin '— clause:' (line 793, range 776..946)
  PASS: multi-code-review pin 'clause: none' (line 939, range 776..946)
  PASS: multi-code-review pin '(plan-mandated) — at ' (line 793, range 776..946)
  PASS: multi-code-review pin 'cut it to 160 characters' (line 928, range 776..946)
  PASS: multi-code-review pin '**Normalization is one rule:**' (line 923, range 776..946)
  PASS: multi-code-review pin 'one sentence or one list entry, never a whole section' (line 924, range 776..946)
  PASS: multi-code-review pin 'tests the quote as a **prefix**' (line 934, range 776..946)
  PASS: multi-code-review pin 'No consumer compares the quote with the raw plan text' (line 935, range 776..946)
  PASS: multi-code-review pin 'decided (orchestrator)' (line 1024, range 946..1133)
  PASS: multi-code-review pin 'decided (<who>)' (line 990, range 946..1133)
  PASS: multi-code-review pin 'plan governs (orchestrator decision)' (line 978, range 946..1133)
  PASS: multi-code-review pin 'plan governs (user decision)' (line 977, range 946..1133)
  PASS: multi-code-review pin '`decided (user)` or `decided (orchestrator)`' (line 1043, range 946..1133)
  PASS: multi-code-review pin 'unresolved: fix contradicts binding text' (line 996, range 946..1133)
  PASS: M = 1 log-format example carries the clause (line 793, range 784..799)
  PASS: M >= 2 log-format example carries the clause before the annotation (line 814, range 799..818)
  PASS: multi-code-review normalization replaces a double quotation mark (line 927, range 776..946)
  PASS: multi-code-review names all three replacements as one rule (range 776..946, line wraps folded)
  PASS: addendum shapes include an unresolved line (line 861, range 776..946)
  PASS: the binding-text test is stated where the refusal rule lives (range 946..1133, line wraps folded)
  PASS: binding-text test names the Exact content block (line 1004, range 946..1133)
  PASS: loop reads the answer line's tag, and treats an untagged line as a user line (range 946..1133, line wraps folded)
  PASS: loop takes <who> from that tag (range 946..1133, line wraps folded)
  PASS: the accept disposition shape (line 990, range 946..1133)
  PASS: an accept answer runs no fix and no re-review, and stops counting as unresolved (range 946..1133, line wraps folded)
  PASS: an amend plan answer takes the finding-governs path for its fix it part (range 946..1133, line wraps folded)
  PASS: that path skips the verification re-review, because a new invocation follows (range 946..1133, line wraps folded)
8. Loop-side rule for verification cycles (R8.3)
  PASS: loop-decision rejection shape (line 648, range 623..703)
  PASS: loop-side rule fragment 'a Critical is never rejected under this rule' (line 681, range 623..703)
  PASS: loop-side rule fragment 'decided wording' (line 644, range 623..703)
  PASS: loop-side rule fragment '(amended by ruling' (line 652, range 623..703)
  PASS: loop-side rule fragment 'same BASE' (line 651, range 623..703)
  PASS: loop-side rule fragment 'never edits plan text' (line 687, range 623..703)
  PASS: loop-side rule fragment '3-cycle cap is unchanged' (line 689, range 623..703)
  PASS: loop bounds the marker's authority to a backing entry (line 664, range 623..703)
  PASS: loop names the ruling-record path it checks the marker against (line 667, range 623..703)
  PASS: loop treats an unbacked marker as reference text (range 623..703, line wraps folded)
  PASS: loop compares the marker's ruling number as a whole number (range 623..703, line wraps folded)
  PASS: loop covers the no-TOPIC_DIR case, where no record exists (range 623..703, line wraps folded)
9. Controller prompt templates (R10)
  PASS: Deviation 3 pins the fixed secret disposition form (line 109, range 94..119)
  PASS: Deviation 3 says the leading text is fixed (range 94..119, line wraps folded)
  PASS: Deviation 3 names the real mechanism: the secret class stops the run (range 94..119, line wraps folded)
  PASS: Deviation 3 forbids copying the value into the line (range 94..119, line wraps folded)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '(orchestrator)' (line 222, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc pin '`(orchestrator)` or `(user)`' (line 222, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc pin 'decided (<who>)' (line 223, range 218..225)
  PASS: code-review-loop [RESUME_ANSWER] doc says authoritative either way (line 222, range 218..225)
  PASS: code-review-loop Deviation 5 pin '(orchestrator)' (line 129, range 125..186)
  PASS: code-review-loop Deviation 5 pin 'tagged `(orchestrator)` or `(user)`' (line 129, range 125..186)
  PASS: code-review-loop Deviation 5 pin 'decided (<who>)' (line 145, range 125..186)
  PASS: code-review-loop Deviation 5 pin '`decided (user)` or `decided (orchestrator)`' (line 170, range 125..186)
  PASS: code-review-loop Deviation 5 treats an untagged line as a user line (range 125..186, line wraps folded)
  PASS: batch-controller Resume Answer heading states the omit condition (line 71, range 1..189)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(orchestrator)' (line 195, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '(user)' (line 196, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc pin '[task <n>/<k>]' (line 193, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] doc says authoritative either way (line 196, range 189..203)
  PASS: batch-controller [RESUME_ANSWER] carries the run-wide answer set (range 189..203, line wraps folded)
  PASS: First-batch parameter defers to Deviation 1's pre-flight rule (line 63, range 1..189)
  PASS: batch-controller Deviation 1 pin '### Question <k>' (line 81, range 77..125)
  PASS: batch-controller Deviation 1 pin '### Conflict <k>' (line 82, range 77..125)
  PASS: batch-controller Deviation 1 pin 'lowest-numbered task' (line 100, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Pre-flight rule' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'absent from' (line 104, range 77..125)
  PASS: batch-controller Deviation 1 pin '.superpowers/sdd/task-<n>-report.md' (line 80, range 77..125)
  PASS: batch-controller Deviation 1 pin 'is settled' (line 108, range 77..125)
  PASS: batch-controller Deviation 1 pin 'Never copy a secret or a credential' (line 121, range 77..125)
  PASS: batch-controller Deviation 1 pin 're-used on the same task' (line 84, range 77..125)
  PASS: batch-controller Deviation 1 pin 'those sections before you write your own' (line 98, range 77..125)
  PASS: batch-controller Deviation 1 pin 'controller failure' (line 120, range 77..125)
  PASS: batch-controller Deviation 1 pin '[task <n>]` line means `[task <n>/1]' (line 109, range 77..125)
  PASS: Deviation 1 allocates a new section number above the highest visible one (range 77..125, line wraps folded)
  PASS: Deviation 1 never renumbers a section written in this dispatch (range 77..125, line wraps folded)
  PASS: Deviation 1 keys the stale-section deletion on this run's own work (line 92, range 77..125)
  PASS: Deviation 1 rejects the answer line as the first-dispatch signal (range 77..125, line wraps folded)
  PASS: Deviation 1 spells the rejected first-dispatch signal exactly (line 94, range 77..125)
  PASS: batch-controller re-derived conflict pin 're-use that `<k>`, apply the answer' (line 116, range 77..125)
  PASS: batch-controller re-derived conflict pin 'Allocate a new `<k>` only for a' (line 117, range 77..125)

Results: 287 passed, 0 failed
exit=0
```

All three suites exit 0. The third reports 287 checks, more than the
244 the round-8 baseline reported.

### Round 8 verification 2 fixes

Findings fixed (all in `tests/in-run-rulings/run-tests.sh`; no SKILL.md
changes needed — every finding was a test-coverage gap, not a wording
defect):

- **I1** — added three new assertions in section 5, scoped to
  `$LOG_ENTRY_LINE..$LOG_ENTRY_END`: a byte pin on
  `**Handling a return as a whole.**`, a folded pin on `rule and record the
  others`, and a folded pin on `a \`Ruled:\` line every ruling of the
  stopped unit that was not`. Also added two folded pins for the
  Idempotence paragraph's mechanism clauses (`Phase 3 is idempotent by
  construction: the ruling and any amendment are committed before the
  re-dispatch` and `a retry rebuilds the identical \`[RESUME_ANSWER]\` from
  the ruling-record entry`) — this also fixes M11, the same finding class.
- **I2** — added `MCR_WORKSPACE_LINE`/`MCR_PROCEDURE_LINE` anchors
  (`## Workspace and Log`..`## Procedure`) and a folded pin on
  `` decided (<who>): <answer>`, `<who>` being `` in section 7, covering
  Pipeline rule 1's generalization sentence at multi-code-review
  SKILL.md:269.
- **M2** — converted `assert_in_range`, `line_containing_after` and
  `line_starting_with_after` to pass their needle through `ENVIRON`
  instead of `awk -v`, matching the pattern the folded helpers already
  use, so no helper silently rewrites escape sequences in a pinned needle.
- **M3** — added a folded pin on the escalated-item stop sentence itself
  (not just the bare word `escalated`), and two new negative checks in the
  stop-policy range for `code-review unresolved` and bare
  `batch-controller BLOCKED;`, modelled on the existing pre-flight
  negative check.
- **M5** — renamed the ~657 description to
  "log-entry (idempotence paragraph) fragment 'durable marker'" (it
  searches the idempotence paragraph, not the guards subsection); renamed
  the ~643 loop's description from "log-entry or guard fragment" to
  "log-entry fragment" (the range is log-entry only); extended the ~650
  check's needle to the full sentence antecedent — `a bare \`fix it\` whose
  item's \`clause:\` names binding plan text becomes
  \`escalated (irreversible)\`` — instead of the bare token.
- **M6** — added a negative check in the Phase 4 range (guarded for an
  empty/inverted range) asserting the old
  `` `user_decision > 0` → major error → stop `` wording is absent, so a
  re-added old stop sentence beside the new routing sentence now fails.
- **M7** — guarded `CAP_SENTENCE_FOLDED`'s computation with the same
  empty/inverted-range check `assert_in_range` uses, before calling
  `fold_range`, so an empty `LOG_ENTRY_LINE` reports a failure instead of
  silently folding lines 1..`GUARDS_LINE`.
- **M8** — added `ITEM: [<id>]` and `CONTRADICTS: none |` to the fork pin
  list.
- **M9** — added a closedness check over `$CLASS_LINE..$CLASS_END` that
  scans the predicate's own `- \`<label>\` — ` bullet lines and fails when
  any label falls outside the closed set of five (`spec wrong`, `scope`,
  `irreversible`, `secret`, `chain`).
- **M10** — rewrote the cap-sentence emphasis check to loop over every
  occurrence of the sentence in the folded range and fail if any one
  carries `*` emphasis markers, instead of inspecting only the first
  occurrence.
- **M11** — see I1 above (same edit fixes both).
- **M12** — added the `[ "$start" -ge "$end" ]` inverted-range guard (with
  a distinct message) to both `assert_in_range_folded` and
  `assert_in_range_folded_exact`, matching `assert_in_range`.

Verification, beyond the required suite run: spot-checked that the new/
changed assertions actually catch what they claim to, by mutating a
temporary copy of the target SKILL.md files and re-running the suite
against each mutation, then restoring the original:

- Deleting SKILL.md lines 1322-1328 ("Handling a return as a whole") now
  fails 3 checks (was: suite green). Restored → 300 passed, 0 failed.
- Reverting multi-code-review SKILL.md:269 to the pre-branch
  `` decided (user): <answer> `` wording now fails 1 check (was: suite
  green). Restored → 300 passed, 0 failed.
- Re-adding the old Phase 4 stop sentence
  (`` `unresolved > 0` or `user_decision > 0` → major error → stop ``)
  beside the new routing sentence now fails 1 check (was: suite green).
  Restored → 300 passed, 0 failed.
- Injecting a sixth escalation reason (`` - `deadline` — test injected
  reason ``) into the predicate's bullet list is caught by the new M9
  closedness scan in isolation (awk unit check).

Commands and pass/fail evidence:

```
$ bash tests/in-run-rulings/run-tests.sh
...
Results: 300 passed, 0 failed
exit=0

$ bash tests/reviewer-templates/run-tests.sh
...
Results: 24 passed, 0 failed
exit=0

$ bash tests/writing-plans/run-tests.sh
...
Results: 15 passed, 0 failed
exit=0
```

All three suites exit 0. `tests/in-run-rulings/run-tests.sh` grew from
the round-8-baseline count to 300 checks (18 net new assertions across
I1/I2/M3/M6/M8/M9/M11, plus the M5 rename/extension of 3 existing
checks and the M2/M7/M10/M12 changes to shared helper logic that apply
across all existing checks using them).

Commit: `fca4a92ec1544a2b27158d62a6d2fc700386fa56` — "review fixes
(autonomous-in-run-decisions, round 8)" — 1 file changed
(`tests/in-run-rulings/run-tests.sh`, 187 insertions, 40 deletions).

No findings were skipped. All 12 findings (I1, I2, M2, M3, M5, M6, M7,
M8, M9, M10, M11, M12) resulted in edits confined to
`tests/in-run-rulings/run-tests.sh`.

---

## Round 8 follow-up — Ruling 2 withdrawal (F1) and suite hardening (F2-F5)

Files edited: `skills/orchestrating-development/SKILL.md`,
`tests/in-run-rulings/run-tests.sh`. No document under `docs/` and no spec
or plan file was touched.

### F1 — Critical: remove "Ruling 2" from the orchestrating-development skill

The spec author withdrew Ruling 2 in full. Every part of it was removed from
`skills/orchestrating-development/SKILL.md`, and each of the five sites was
restored to the wording it had at `bf3d7de` (the state just before `d725f17`),
reconciled with the wording later rounds legitimately changed:

1. The `irreversible` entry of the closed escalation list now reads again as
   the plain list of an irreversible or outward-facing action. The
   binding-set definition, the "trigger is the edit location" paragraph, the
   `— clause:` reading instruction and the whole "In Phase 3 the trigger has
   a second form" paragraph are gone.
2. The plan-amendment procedure lost the no-delete bound (including its
   "**binding and reference text alike**" half and the justification about a
   safety rule written as an ordinary reference sentence) and the opening
   sentence that scoped the procedure to "the amendments that are still
   yours". Numbered step 1 is back to "**Edit the binding clause in place** —
   replace the Global Constraints entry, the Exact-content block, or the
   mandated sentence with the amended text": the "which under the no-delete
   bound above …" clause is removed, and with the bound and the opening
   sentence gone, the binding/reference split that step 1 carried had no
   remaining definition, so the step was restored to its pre-Ruling-2 form.
3. The `amend plan: <the amendment>; fix it: …` answers bullet is back to
   "The only accepting answer when `clause:` names binding text. You write the
   amendment (below) before re-dispatching; the loop then fixes."
4. The Phase 3 `### Conflict <k>` answer sentence is back to
   "… is always `amend plan: …` (the amendment procedure below); a plain-text
   answer is valid only against a question or against reference text …".
5. The pre-commit self-check is back to "a bare `fix it` whose item's
   `clause:` names binding plan text becomes `amend plan: …; fix it` or
   `escalated`, because a fix against binding text needs the amendment …".

Ruling 1 was not touched: the fifth read entry (the ruling record) in the
classification read exception, and guard 4 with its count word "Four", are
unchanged. Nothing was added to any spec.

The token `escalated (irreversible)` no longer occurs in the skill; the class
enumeration `escalated (<spec wrong|scope|irreversible|secret|chain>)` stays
(5 occurrences):

```
$ grep -c "escalated (irreversible)" skills/orchestrating-development/SKILL.md
0
$ grep -n "irreversible" skills/orchestrating-development/SKILL.md
377:Items: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>
391:Open: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>
682:- `irreversible` — needs an irreversible or outward-facing action: a
995:- **Class:** forced | design | escalated (<spec wrong|scope|irreversible|secret|chain>)
1232:Items: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>
```

In `tests/in-run-rulings/run-tests.sh` the assertions pinning the deleted
passages were removed, with the comments that belonged only to them: the
`irreversible entry pin 'escalated (irreversible)'` check and the
edit-location / binding-text / task-section / Phase-3-second-form checks beside
it in the classification range; the `answer pin 'escalated (irreversible)'`
check and the five no-delete checks in the answers range; and the self-check
check in the log-entry range. Every other assertion was kept, including the
five class labels and the closedness scan, and no assertion targeting
`skills/multi-code-review/SKILL.md` (`$MCR_SKILL`) was changed.

Search confirming no assertion still pins deleted text (no output = none):

```
$ grep -n "escalated (irreversible)\|deletes\*\* a clause\|binding and reference text alike\|clause dropped and rewritten\|exception scoped to the item\|ruling of your own\|In Phase 3 the trigger has a second form\|plan location that section names\|under entry 3 of the read exception\|amendment would edit the plan" tests/in-run-rulings/run-tests.sh
$ echo $?
1
```

### F2 — Important: pin guard 2's two prohibitions

Added, in the guards range, a case-sensitive folded pin on guard 2's own
bytes ``Never `plan governs`, never `accept`.``, which cross a line wrap.

Mutation proof — inverting the prohibition in the skill:

```
F2 guard2 inverted -> exit=1
  FAIL: guard 2 forbids `plan governs` and `accept` on a Critical (not inside range 1328..1376 of skills/orchestrating-development/SKILL.md, line wraps folded, case-sensitive)
```

### F3 — Important: negative checks must fold line wraps

Added one helper, `assert_absent_in_range_folded` (desc file needle start end
mode), beside the folded positive helpers: it reuses `fold_range`, fails when
the range anchors are missing/empty/inverted, and reports PASS only when the
needle is absent from the folded range. The three stop-policy negative checks
(pre-flight plan conflict, code-review unresolved, unconditional
`batch-controller BLOCKED;`) now go through it instead of scanning line by
line. The Phase 4 negative check goes through it too, and is now two checks —
one per disjunct of the removed sentence — so that re-adding the
`unresolved > 0` half alone is caught.

Mutation proof:

```
F3 wrapped pre-flight stop re-added -> exit=1
  FAIL: stop policy no longer lists a pre-flight plan conflict as a stop by itself (still present in range 1376..1415 of skills/orchestrating-development/SKILL.md, line wraps folded)
F3 unresolved-half Phase 4 stop re-added -> exit=1
  FAIL: Phase 4 no longer stops directly on the unresolved count (old wording absent) (still present in range 300..330 of skills/orchestrating-development/SKILL.md, line wraps folded)
```

### F4 — Important: the closedness scan passed on zero bullets

The scan now collects every ``^- `<label>` `` bullet label of the
classification range, sorts them, and compares the whole set with the five
expected labels (`spec wrong`, `scope`, `irreversible`, `secret`, `chain`).
A set that is empty, larger or different fails.

Mutation proof:

```
F4 sixth label -> exit=1
  FAIL: the closed escalation list's bullets are 'chain|deadline|irreversible|scope|secret|spec wrong|', not the five expected 'chain|irreversible|scope|secret|spec wrong|'
F4 indented bullets -> exit=1
  FAIL: the closed escalation list's bullets are '', not the five expected 'chain|irreversible|scope|secret|spec wrong|'
```

### F5 — Important: pin the design-class-to-fork-review link

Added a folded pin on the sentence that sends a `design` item to the fork
review, in the classification range: `Decided after the fork review`.

Mutation proof — replacing it with "Decided directly, with no subagent.":

```
F5 fork link removed -> exit=1
  FAIL: a design item is decided after the fork review (not inside range 654..759 of skills/orchestrating-development/SKILL.md, line wraps folded)
```

### Verification — fresh output

```
$ bash tests/reviewer-templates/run-tests.sh
...
  PASS: gate label matches between writing-plans and multi-doc-review (**Body authority:**)

Results: 24 passed, 0 failed
exit=0

$ bash tests/writing-plans/run-tests.sh
...
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
exit=0

$ bash tests/in-run-rulings/run-tests.sh
...
  PASS: batch-controller re-derived conflict pin 'Allocate a new `<k>` only for a' (line 117, range 77..125)

Results: 290 passed, 0 failed
exit=0
```

Covering suites:

```
$ bash tests/codex/run-unit-tests.sh
...
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
==================================================
exit=0

$ bash tests/smart-compress/run-tests.sh
...
\n\n══════════════════════════════════════════
  Results: 87 passed
  0 failed
══════════════════════════════════════════
exit=0
```

The in-run-rulings suite went from 300 checks to 290: 12 assertions pinning
withdrawn Ruling 2 text were removed (F1), 1 was added for guard 2 (F2), 1 for
the design/fork link (F5), and the Phase 4 negative check became two checks
(F3). No finding was skipped or partially applied.

## Round 9 fixes — 2026-09-04

Findings I1–I6, M1–M3, M6, M8–M12. All fixes are wording changes in the four
skill files plus the pin updates they require in
`tests/in-run-rulings/run-tests.sh`. No file under `docs/`, no plan, no spec,
no version file was touched.

### [I5] backticks inside a double-quoted check description

`tests/in-run-rulings/run-tests.sh` line 722 wrote the description of the
guard-2 check in double quotes with two backtick-quoted terms inside, so bash
ran `plan governs` and `accept` as command substitutions on every run of the
suite. Fixed by single-quoting the description, the spelling every other
backtick-bearing description in the file already uses.

Scan for other occurrences (only escaped backticks remain inside double
quotes, which bash treats as literal):

```
$ grep -nP '"[^"]*(?<!\\)`' tests/in-run-rulings/run-tests.sh | grep -v "\\$ORCH_SKILL\|\\$MCR_SKILL\|\\$BATCH_PROMPT\|\\$LOOP_PROMPT\|^ *#"
(no line whose backtick sits inside an actual double-quoted string remains;
 the suite's standard error is now empty — see the verification section)
```

Before the fix:

```
$ bash tests/in-run-rulings/run-tests.sh 2>&1 >/dev/null
tests/in-run-rulings/run-tests.sh: line 722: plan: command not found
tests/in-run-rulings/run-tests.sh: line 722: accept: command not found
```

After the fix:

```
$ bash tests/in-run-rulings/run-tests.sh 2>/tmp/e1.txt >/tmp/o1.txt; echo "exit=$?  stderr_bytes=$(wc -c </tmp/e1.txt)"
exit=0  stderr_bytes=       0
```

The PASS line now carries the whole description:

```
  PASS: guard 2 forbids `plan governs` and `accept` on a Critical (range …, line wraps folded, case-sensitive)
```

### [I1] read exception did not cover two reads Resume step 3 mandates

`skills/orchestrating-development/SKILL.md`, entry 4 of
`### What may be read — the classification read exception`, permitted the
`git log --format="%H %s" --grep …` and `git show <ruling commit>^:<plan path>`
reads only when Resume step 3 reverts a plan amendment. Resume step 3 also
runs the commit-landed check (`--format=%s`, on every resume whose log ends
with a `## RULING` entry) and scans the whole plan for an orphan
`(amended by ruling <n>)` marker. Entry 4 now covers the `## RULING` entry
checks of Resume step 3 generally: both `--format` spellings of the
`git log --grep` landed check, the `git show` read, and the whole-plan scan
for an orphan marker and its `**Amendment <n>` note. The "Nothing else."
close is unchanged.

### [I2] the `secret` entry did not match the spec's and the plan's definition

The entry claimed "**Two producers exist.**", added a Phase 3 report-section
trigger, and named `batch-controller-prompt.md` Deviation 1 as a second
producer. The requirements document (design doc line 172) and the plan
(reference text lines 269–275, Assumptions line 13) both define the class by
the item's **disposition reason or summary** and both say **one** producer,
`code-review-loop-prompt.md` Deviation 3. The entry now reads that way. The
decidability refinement is kept: Deviation 3's fixed leading disposition form
is still quoted verbatim, and any other reason naming a secret is still
treated as this class. The closing sentence about a secret in reviewed code is
kept, reworded from "is neither" (which referred to the two producers) to "is
not this class". No other entry of the escalation list and none of the five
class labels changed.

Suite pins updated in the same bytes: the two pins asserting the two-producer
claim and the Phase 3 report-section trigger were replaced by two pins on the
restored wording — the disposition-reason trigger and the one-producer
sentence naming Deviation 3.

### [I6] the lost-return bound contradicted the waiting rule

The bound fired "as soon as at least one notice of the round has arrived",
which on a three-fork round marked the two lenses still working as lost. The
bound is now stated over a condition that can only hold once the round is
genuinely over: a round is **finished** when no fork of it is still running —
every lens has delivered its completion notice, or the platform has reported
that fork as failed or as no longer running. Until then a missing notice is
merely outstanding and the orchestrator keeps waiting; another lens's notice
arriving never marks it lost. At the moment the round is finished, every lens
of the round with no usable return counts as one loss, is re-dispatched once
in one message, and after the re-dispatch round is finished is left out with
`forks: <k> of <planned>`. The bound stays stated over the round, and the
`fork review unavailable` stop for fewer than two usable returns is unchanged.

Suite pins: the pin on the withdrawn phrase `counts as one loss at that same
moment` was replaced by three pins on the new rule — the finished-round
definition, the "never marks it lost" clause, and the loss-at-finish sentence.

### [I3] orchestrator-rejection line named two of three replacements

`skills/multi-code-review/SKILL.md`, the
`rejected: plan governs (orchestrator decision) — "<clause>"` paragraph,
described normalization as "each ` — ` and each ` ← ` replaced by one space,
cut to 160 characters" — the `"` replacement was missing, so a clause holding
a double quotation mark kept it and the line's own `"…"` delimiters closed
early. The parenthetical is replaced by a pointer to the one normalization
rule of "Self-sufficient open-item lines", naming all three replacements and
the 160-character cut. The one rule itself is unchanged.

### [I4] two clauses claimed the same slot with no stated order

The `— at <file:line> — clause: …` suffix and the
`— harness probe: <observation>` clause were both placed "before the ` ← `
annotation" with no relative order, and the observation text was exempt from
the replacements the location clause relies on. The Review Log Format bullet
now states the order explicitly — summary, then `— at … — clause: …`, then
`— harness probe: <observation>`, then any ` ← ` annotation — so that the
first ` — at ` on the line is always the one that introduces the location, and
requires the same three replacements (` — `, ` ← `, `"`) on the observation
text. The Triage harness-claims item and the "Self-sufficient open-item lines"
paragraph both point at that one rule. The location clause keeps the position
the plan requires: after the summary and before any ` ← ` annotation.

### [M1] Deviation 1's stale-section rationale was false for a same-run re-dispatch

`skills/orchestrating-development/batch-controller-prompt.md`: a task that
returned `BLOCKED` and is re-dispatched after a ruling still shows both
first-dispatch signals inside the same run, so "was left by an earlier run"
was false exactly in the case this branch adds. The rationale now reads "was
left by a previous run, or by an earlier dispatch of this one that returned
`BLOCKED` and produced no ticked checkbox and no ledger line". The deletion
itself and the section-numbering rule are unchanged.

### [M2] Deviation 3's fixed secret line contradicted the mandatory suffix

`skills/orchestrating-development/code-review-loop-prompt.md`: the deviation
fixed the *whole* disposition line, which no controller can satisfy together
with multi-code-review's mandatory `— at … — clause:` suffix on every
`unresolved:` line. It now fixes only the **leading** text ("the disposition
line BEGINS …") and states that the mandatory suffix still follows, with
`— clause: none` for a secret that collides with no plan text. The mandatory
suffix rule itself is untouched.

### [M3] the tie-break round was told to dispatch a fork and not to dispatch one

`skills/orchestrating-development/SKILL.md`: the consolidation paragraph now
dispatches "one further reviewer under `evidence consistency` — a fresh
`general-purpose` subagent, never a fork", cross-referencing the
anti-anchoring inheritance rule earlier in the same subsection. The
`evidence consistency` lens name and the `contradiction: unsettled` outcome
are unchanged.

### [M6] binding-text test cited a note that does not exist where it said

`skills/multi-code-review/SKILL.md`: "the orchestrating-development 7.7.0
Body-authority note" is now "the `**Body authority:**` note that the
plan-writing skill (`../writing-plans/SKILL.md`) puts in every plan header".
`skills/writing-plans/` was not edited.

### [M8] Phase 3 step 2's fill list omitted `[RESUME_ANSWER]`

`skills/orchestrating-development/SKILL.md`, Phase 3 step 2 now lists
`[RESUME_ANSWER]` — the run-wide answer set that step 5 states, filled on
every dispatch, first or repeat, whenever the run has recorded any answer.

### [M9] two references pointed at a file absent from a fresh clone

`skills/orchestrating-development/SKILL.md`: the ruling-record shape no longer
attributes itself to "the orchestration issues log's Case template" (it reads
"in the shape below:", and the fenced block below supplies it), and the cap
paragraph no longer cites "Case 007 of the orchestration issues log" (it now
names the chain it bounds: "the chain of repeated open returns on one unit
that motivated the cap").

### [M10] a quoted rule was attributed to the wrong section

`skills/orchestrating-development/SKILL.md`: both quotes stay verbatim, and
the attribution is corrected — the Controller Dispatch Rules' "never pass
conversation history", and the prompt templates' "nothing else may be added to
the prompt".

### [M11] a bare task line was described as settling any section of that task

`skills/orchestrating-development/SKILL.md`: the sentence now says that a
`[task <n>/<k>]` line settles the section with that exact `<k>` and a bare
`[task <n>]` line settles section 1 only. Both line shapes stay valid.

### [M12] the prohibition on best-guessing a pre-flight conflict lost its subject

`skills/orchestrating-development/batch-controller-prompt.md`: the pre-flight
rule now carries the clause back explicitly — "Never best-guess the conflict
itself: an unsettled pre-flight conflict is returned as `BLOCKED` for that
conflict, never decided by you from plan, spec or repository — the sentence
above about answering NEEDS_CONTEXT that way covers a missing fact, not a plan
that contradicts itself." The existing "never best-guess a number inside
`[TASK_LIST]`" sentence is unchanged, so no duplication is re-introduced.

### Verification — fresh output

```
$ bash tests/in-run-rulings/run-tests.sh 2>/tmp/e1.txt >/tmp/o1.txt; echo "exit=$?  stderr_bytes=$(wc -c </tmp/e1.txt)"; tail -2 /tmp/o1.txt
exit=0  stderr_bytes=       0

Results: 291 passed, 0 failed

$ bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -2
Results: 24 passed, 0 failed
exit=0

$ bash tests/writing-plans/run-tests.sh 2>&1 | tail -2
Results: 15 passed, 0 failed
exit=0

$ bash tests/codex/run-unit-tests.sh 2>&1 | tail -2
 All unit tests passed.
exit=0

$ bash tests/smart-compress/run-tests.sh 2>&1 | tail -3
  Results: 87 passed
  0 failed
exit=0
```

The in-run-rulings suite went from 290 checks to 291: two pins on the
withdrawn `secret` wording were replaced by two on the restored wording (I2),
and one pin on the withdrawn lost-return moment was replaced by three on the
new round-finished rule (I6). Standard error is empty (I5). No finding was
skipped or partially applied.
