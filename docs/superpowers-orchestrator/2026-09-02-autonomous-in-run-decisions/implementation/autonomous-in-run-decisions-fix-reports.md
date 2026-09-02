
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
