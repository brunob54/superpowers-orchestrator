# Review log — autonomous-in-run-decisions.md

_Invocation 1 — 2026-09-02 — N=2 M=1 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 4 Step 3, Task 9 Step 4 and both contracts: a pre-flight conflict ruled without an amendment is re-detected on the re-dispatched first batch, and no answer form exists for a `### Conflict <k>` → Task 4 states the two Conflict answer forms (`plan governs: "<clause>" — <path>` or `amend plan: …`) and that a conflict whose `[task <n>/<k>]` line is in `## Resume Answer` is settled; Task 9's First-batch parenthetical says the same; `is settled` added to the section 9 pins
- [I2] applied — Task 6 Step 8, Contract and Does-NOT-cover: a crash between the ruling commit (`Re-dispatch: none`) and the `stopped` commit had no Resume case → Resume step 3 gains the crash-window case (rebuild the missing `## STOPPED` entry from the ruling-record entries, commit it as `stopped`, continue as the `## STOPPED` case)
- [I3] applied — Task 7 Step 4 and Contract: `amend plan …; fix it` and `accept:` were never mapped onto the loop's paths → the rule maps `amend plan …; fix it` to the finding-governs path with the verification re-review skipped (amendment moved the effective HEAD; new invocation follows) and `accept: <reason>` to an item decided without a code change (its `decided (<who>)` line is the whole disposition); no new disposition shape introduced, the existing `decided (<who>): <answer>` line carries it
- [I4] applied — Task 4 Step 3, Contract, section 4 checks and Step 2 expectation: Phase 3 had no rule that an answer siding against binding text must be `amend plan` → sentence added ("an answer that sides against binding plan text is always `amend plan: …`; a plain-text answer is valid only against a question or against reference text"), fragment `sides against binding plan text` pinned
- [M1] applied — Task 6 Step 8: "three remaining mentions" → "two remaining mentions" (the third sits inside the block the same step replaces)
- [M2] applied — Task 6 Step 2 and Task 2 Step 2: expected-failure lists corrected (`(user)` passes early on the existing `decided (user)` text; `nothing else` fails because the section 2 fragments are scoped to the section Task 1 wrote)
- [M3] applied — Global Constraints: "written once each in their own backticks" → "each appear in their own backticks inside the predicate's list (a label may be repeated there)"; the reference text writes `escalated` twice and the suite asserts presence only (spec R11's "once" is explanatory)
- [M4] deferred — Deviation 6 `BLOCKED` (task cannot reach a clean review) is classed as a controller failure and retried once before the stop; spec R1 fixes the discriminator as two-way, so a third outcome is a spec change, not a plan fix
- [M5] applied — Task 6 Step 8 and Contract: a resume-prompt answer for a `Ruled:` id replaces the ruled line, tagged `(user)`, and is appended as a `**Follow-up:**` line
- [M6] applied — Task 6 Step 4: "Only an escalated item stops the run" → "on the strength of its content; the environment stops of the Major-Error Stop Policy apply as well"

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 1 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — Global Constraints (cap sentence) and Task 5 Step 1, Step 2, Contract: "exactly this form" was readable as "same bytes on one line" while the reference wraps the sentence, and the suite checked only its first half → the constraint now says "exactly" means these words and this punctuation and a line wrap inside the sentence is allowed; the second half `phase itself in Phase 4, the task in Phase 3` is pinned as a section 5 fragment (no negative emphasis check added: the two fragment checks already fail on emphasis markers placed inside the sentence)
- [M1] applied — Task 3, 4, 6, 9 Step 2 expected-failure lists: Task 3 and Task 4 now expect every check of their section to fail (the earlier tasks' text contains none of the pins or fragments — checked); Task 6 adds the `escalated` stop-policy fragment (absent from the file today); Task 9 excepts the two code-review-loop `(user)` pins (the existing `decided (user)` text lies in both ranges)
- [M2] applied — Task 1 Contract: the "rename the heading and confirm exit 1" verification that no step performed is dropped; the Verification line now points at Steps 2 and 5
- [M3] applied — Task 3 Step 3 and Contract: a Phase 3 item has no `file:line`, so the two-fork condition was unevaluable → "a single file" means its `### Conflict <k>` / `### Question <k>` section names exactly one file; none or several → three forks
- [M4] applied — Task 5 Step 3 (cap), Task 6 Does-NOT-cover, Contract and Step 8: the written line is `Re-dispatch: none — escalated`, so "is `none`" / "is not `none`" now read "line starts with `none`" / "line does not start with `none`"
- [M5] applied — Task 6 Step 3: the Phase 3 re-dispatch is "the same batch — same task list, same `First batch:` value", so the settled-conflict rule of the pre-flight scan runs on it

### Self-review (writing-plans checklist, after the loop)
- Spec coverage: every R1–R12 section maps to a task (R1 → 1, R2 → 2, R3 → 3, R4–R5 → 4, R6/R7/R9 → 5–6, R8.1–R8.2 → 7, R8.3 → 8, R10–R11 → 9, R12 → 1); no gap.
- Placeholder scan: none found.
- Type consistency: the three pin strings added by the merges (`sides against binding plan text`, `phase itself in Phase 4, the task in Phase 3`, `is settled`) match between the test lists, the reference text and the contracts.
- Scope-reduction scan: the only hit for "placeholder" names the `[RESUME_ANSWER]` template placeholder; nothing sanctioned was narrowed.
- Contract audit: `**Body authority:**` present; nine `**Contract:**` fields, none vacuous; no `**Exact content:**` marker; all ten Global Constraints cite the spec (the two reworded entries still trace to R1/R11 and R6); no self-pin.
- No merge-introduced issue to fix.

Harness probes owed: none

_Loop complete — 2026-09-02 — rounds 2_
