# Review Log — plan-contracts-not-bodies

_Invocation 1 — 2026-08-31 — N=2 M=1 — BASE..HEAD 6f589ed..0a9a73a — branch feature/plan-contracts-not-bodies — gate: orchestration_

## Round 1 — Correctness & spec alignment — fable
**Reviewer verdict:** 0 Critical, 0 Important, 0 Minor
**Converged:** no
### Dispositions
- carried — tests/writing-plans/run-tests.sh helpers assert_in_block/first_line_of unused until Tasks 2-3 (reviewer: resolved at head — assert_in_block runs in checks 2 and 3 and exercises first_line_of internally; recommendation ship-as-is)
- carried — tests/writing-plans/run-tests.sh check 4 unscoped whole-file assert_fragment for "falsifiable" (plan-mandated shape; word occurs exactly once at head, in Self-Review check 5; recommendation ship-as-is)

## Round 2 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — multi-doc-review lens gate for the three contract targets is bound to the free-text header phrase "reference implementations", which the design's own rules treat as rewordable free text; a reword or a dropped note silently switches the gate off with no signal (plan-mandated: the plan gates the lens on that header phrase — plan lines 474, 519-520; reviewer suggests gating on the byte-pin label `**Body authority:**` and exempting the authority note from the reference default)
- [I2] user-decision — rule 6(b) makes the `**Global Constraints:**` block bind unconditionally, giving self-pinned literals an unguarded bypass of rule 5: a plan can restate its own self-pins as Global Constraints and no lens target or self-review check inspects those entries (plan-mandated: the plan's rule text makes Global Constraints bind as stated and stop the run — plan lines 236-237; reviewer suggests extending rule 5 and the R5 lens target or Self-Review check 5 to Global Constraints entries)
- [M1] carried — rule 4 wording "the line immediately above the fenced block" is voided by a habitual blank line between the marker and the fence; two agents resolve it differently (entangled with the open decisions on rules 4-6; fix wording once I1/I2 are decided)
- [M2] carried — tests/writing-plans/run-tests.sh first_line_of anchors headings by containment (grep -nF), not whole-line match; a future prose mention of `## Task Template` or `## Plan Header` earlier in the file silently retargets the block-scoped checks (suggest grep -nxF)
- [M3] carried — the false-`none` test is undecidable for deletion-only tasks: rule 1 defines governed artifacts via "introduces or modifies", so reviewers will disagree on `Contract: none` for a delete-only task (suggest one clause in rule 1's boundary test stating whether deletion counts)

## Post-loop addendum — 2026-08-31 — invoker decisions on the open items

**Standing rule recorded for this and every later invocation of this loop:** a
verification re-review finding against ANY plan-mandated wording is this loop's
to decide — fix it, or reject it with a named reason. A Critical is never
rejected under this rule. Such findings are never journaled as `user-decision`,
so that one stop cannot become a chain.

### Dispositions
- [I1] decided (user): fix it — gate the three contract lens targets on the byte-pin label `**Body authority:**` instead of the free-text phrase "reference implementations"; add an inconsistent-regime guard; extend rule 6(b); add a whole-line-anchored Plan Header assertion for the label while keeping the existing "reference implementations" assertion; amend the spec and the plan
- [I1] fixed — lens gate bound to `**Body authority:**`, inconsistent-regime guard added, rule 6(b) extended so the note binds as stated, Plan Header label assertion added, spec R3/R5 and plan amended → 86bf5c5
- [I2] decided (user): fix it — extend Self-Review check 5 and lens target 3 so `**Global Constraints:**` entries are inspected with the decidable two-part self-pin test; genuine spec-derived constraints keep binding
- [I2] fixed — two-part self-pin test added to Self-Review check 5 and as a fourth lens target; spec Amendments section records the extension → 86bf5c5
- [M2] fixed — `first_line_of` now anchors headings with whole-line matching (`grep -nxF`) instead of containment; resolved in the same commit as the wording it pins → 86bf5c5
- [M1] carried — rule 4 adjacency wording; kept carried by the invoker's answer, then superseded by verification 2 [I4] below
- [M3] carried — the false-`none` test for deletion-only tasks; kept carried by the invoker's answer

## Round 2 verification 1 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
### Dispositions
- [I1] fixed — the inconsistent-regime guard was unreachable: it tested the plan **header** for a `**Contract:**` field, which is a Task Template field and never appears in a header; reworded to "carries `**Contract:**` fields in its tasks but no `**Body authority:**` label in its header", spec corrected to match → 2e64c15
- [I2] rejected: the invoker's ruling explicitly accepted this limit — the same decision that exempted the `**Body authority:**` note from the reference default directed that the known limit "findings against the note are plan conflicts" be documented; the proposed out-of-band routing contradicts the wording the ruling mandates
- [I3] rejected: the two-part self-pin test is the invoker's explicit ruling, and its first leg exists precisely so that genuine spec-derived constraints keep binding; the proposed single-legged test would flag those constraints, which the ruling forbids
- [M1] fixed — Task 5 Step 4 expected output corrected from `7 passed` to `8 passed` with an amendment quote; the earlier per-task counts record the suite size at each task's own point → 2e64c15
- [M2] fixed — `tests/reviewer-templates/run-tests.sh` section 7 now pins the byte pin `**Body authority:**` inside the extracted plan cell, case-sensitively → 2e64c15
- [M3] fixed — the gate is now scoped to the plan header's block quote, above the first `---` separator → 2e64c15
- [M4] carried — rule 1's procedural boundary and its whitelisted commit-block example can be read two ways; the area was reworked by verification 2 [I3] below

## Round 2 verification 2 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 5 Important, 2 Minor
### Dispositions
- [I1] fixed — the gate was an unanchored substring search, so any header block quote merely mentioning the label switched the targets on (this branch's own plan is such a case); the gate now requires the label at the start of a block-quote line, `> **Body authority:** …` → ad58895
- [I2] fixed — rule 6(b) now gives target-4 findings a resolution path: a `**Global Constraints:**` entry that fails the two-part self-pin test is amendable as an ordinary fix, while every other entry keeps binding as stated → ad58895
- [I3] fixed — the `**Files:**`-list test is now the single procedural boundary, stated the same way in rule 1, Self-Review check 5 and the lens cell, with a completeness requirement closing the omission escape hatch → ad58895
- [I4] fixed — rule 4 now binds on the paragraph immediately preceding the block instead of the line immediately above it, so a wrapped reason or a blank line no longer voids the pin; this also resolves carried [M1] of round 2 → ad58895
- [I5] fixed — the whole-file fragment assertions for "ordinary fix", "self-pin" and "falsifiable" were vacuous (each fragment occurs several times in the file); a new `assert_in_range` helper scopes each to the rule or check it pins → ad58895
- [M1] carried — the section-7 awk extractor depends on every continuation line of the cell staying indented; the failure direction is a loud FAIL, not a silent pass
- [M2] carried — `awk -v` interprets backslash escapes in assigned needles; no needle in use today contains a backslash

## Round 2 verification 3 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
### Dispositions
- [I1] rejected: plan-mandated wording — the plan's Task 3 binding statement (plan line 366) requires the Plan Header note to keep the R3 property "`**Global Constraints:**` binding as stated"; the exception is normative in rule 6(b) of the same skill file. Adding the exception to the note would break a plan-mandated property, and this loop decides such findings rather than stopping on them (standing rule above)
- [I2] unresolved: verification cap — `assert_exact` for the `**Exact content:**` label is still a whole-file grep and cannot fail if rule 4 is deleted (the label occurs four times in the file, three of them outside rule 4). The remedy is one line, scoping it with the `assert_in_range` helper already present, but all three verification cycles of round 2 are spent and no fix may ship unreviewed
- [I3] unresolved: verification cap — `**Files:**`-list completeness is asserted as a requirement but has no decision procedure: neither Self-Review check 5 nor any lens target checks that a step body's files are all listed, so two reviewers still resolve an omitted file differently. Cycles spent
- [M1] carried — the range anchors pin rule titles that the design treats as reference wording, so a permitted reword makes the anchor lookup fail
- [M2] carried — `assert_exact` matches by substring while `first_line_of` matches whole lines, so one heading edit can make the suite report contradictory results
- [M3] carried — `line_starting_with_after` with an empty start value scans from line 1 instead of reporting a missing anchor
- [M4] carried — the inconsistent-regime guard states no discriminator between a task's `**Contract:**` field and the same label quoted inside a task step body

_Completed — 2026-08-31 — cap reached — HEAD ad588950398812abeb0666f6d8908547c621fcd9_

## Post-loop addendum 2 — 2026-08-31 — invoker decisions on the open items

**Standing rule, restated for this and every later invocation of this loop:** a
verification re-review finding against ANY plan-mandated wording is this loop's
to decide — fix it, or reject it with a named reason. A Critical is never
rejected under this rule. Such findings are never journaled as `user-decision`,
so that one stop cannot become a chain.

The fix for both open items was produced and committed before this addendum was
written; no fix subagent was dispatched for them, and the verification re-review
is skipped because the effective HEAD moved past this entry's completion marker
(the new invocation below reviews the fix). The completion marker above is left
unchanged.

### Dispositions
- [I2] decided (user): fix it — scope the `**Exact content:**` label assertion in `tests/writing-plans/run-tests.sh` with the `assert_in_range` helper so it fails if rule 4 of the "Contracts and Literal Bodies" section is deleted
- [I2] fixed — the label assertion is now `assert_in_range` scoped to rule 4 instead of a whole-file grep → 808d813
- [I3] decided (user): fix it — make rule 1's procedural-block boundary test intrinsic to the block rather than relational to the `**Files:**` list; delete the orphaned completeness clause; restate the same test identically at all three sites; amend spec R1 and the plan
- [I3] fixed — a block is procedural exactly when it creates, modifies, or deletes no working-tree file, running only pipeline commands, with a fail-closed tie-break (unclear → not procedural); the `**Files:**`-list completeness clause is deleted; the same test is stated identically in rule 1, Self-Review check 5 bucket (c) and the multi-doc-review plan cell; spec R1 and the plan amended → 808d813
- [M3] resolved — the delete-only-task ambiguity is closed by the verb set "creates, modifies, or deletes" of the [I3] fix; no longer carried → 808d813
- [M1] resolved — verified at HEAD: rule 4 binds on "the paragraph immediately preceding" the fenced block and states that what matters is that the marker starts the paragraph, not that it sits on the single line right above the fence; the blank-line case is covered; no longer carried

_Invocation 2 — 2026-08-31 — N=2 M=1 — BASE..HEAD 6f589ed..808d813 — branch feature/plan-contracts-not-bodies — gate: orchestration_

## Round 3 — Correctness & spec alignment — fable
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the `**Body authority:**` note stated only half of the property spec R3 bullet 2 binds: it said the `**Global Constraints:**` block binds as stated but not that the note itself binds as stated, and the missing half lived only in rule 6(b), which never travels into a generated plan; the note now states both → 569e1cb
- [I2] rejected: already decided by this loop — the proposal to carry rule 6(b)'s Global-Constraints self-pin exception into the `**Body authority:**` note is the same proposal rejected at invocation 1 verification 3 [I1]. Spec R3 bullet 2 binds the note to state that the `**Global Constraints:**` block binds as stated; an exception clause in the note would break that spec-bound property. The exception remains normative in rule 6(b) of the same skill file, and the known limit is documented
- [I3] fixed — rule 1 stated the procedural boundary as a biconditional over the file-writing clause alone ("procedural exactly when it creates, modifies, or deletes no file in the working tree"), demoting the "runs only pipeline commands" conjunct to a following sentence; read literally this exempted inert quoted-wording bodies, inverting the wording-artifact contract shape, and it left rule 1 the odd one out among the three sites. The sentence is now conjunctive and identical to Self-Review check 5 bucket (c) and the multi-doc-review plan cell; the fail-closed tie-break is kept → 569e1cb
- [M1] fixed — rule 1's "used everywhere in this plan" had no referent inside a skill file; reworded to "the plan you are writing" in the same sentence as [I3] → 569e1cb
- [M2] carried — `first_line_of` in `tests/writing-plans/run-tests.sh` and the same-named helper in `tests/reviewer-templates/run-tests.sh` have opposite argument order and different match modes; a future copy between the suites could search the wrong file or string
- [M3] fixed — the design's Amendments section now records the rule 4 line → paragraph widening of R1.4's placement condition, which had been made without an amendment note → 569e1cb
- carried — tests/writing-plans/run-tests.sh helpers assert_in_block/first_line_of unused until Tasks 2-3 (reviewer: resolved at head — `assert_in_block` runs in sections 2 and 3 and exercises `first_line_of`; recommendation ship-as-is)
- carried — tests/writing-plans/run-tests.sh check 4 unscoped whole-file assert_fragment for "falsifiable" (reviewer: resolved at head — check 4 now uses `assert_in_range` bounded by the Self-Review check it pins; recommendation ship-as-is)

## Round 4 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 2 Important, 5 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the `**Body authority:**` note omitted rule 6(b)'s Global-Constraints self-pin exception, and the note is the only authority statement that travels inside a generated plan: a controller triaging a lens target-4 finding reads the plan, not the skill, so the finding became a run-stopping plan conflict with the documented resolution path unreachable. Ruling reversed from invocation 1 verification 3 [I1] and round 3 [I2] — three independent reviewers converged on the same gap, and the loop's standing rule lets it amend the plan-mandated wording rather than reject again. The exception is now stated in the note, spec R3 bullet 2 amended, plan amendment block added → 36213db
- [I2] fixed — the inconsistent-regime guard matched the bare string `**Contract:**` anywhere in a task, so a plan that merely quotes the field label inside a fenced block was flagged as an inconsistent regime; this branch's own plan is such a case (lines 287, 302, 374 with no header label), and the natural repair would have switched the full contract regime on over a legacy plan. The predicate is now scoped to a `**Contract:**` beginning a top-level line of the task body, mirroring the gate's existing qualifier; spec R5 and the plan amended → 36213db
- [M1] fixed — the section-heading assertion in `tests/writing-plans/run-tests.sh` matched by substring, so deleting the `## Contracts and Literal Bodies` heading still passed on any prose line naming the section; it is whole-line now, and the orphaned `assert_exact` helper is removed → 36213db
- [M2] carried — the five range anchors in `tests/writing-plans/run-tests.sh` pin rule opening phrases that the design treats as rewordable reference wording, so a permitted reword makes the anchor lookup fail; the failure direction is a loud FAIL naming a missing range, never a silent pass
- [M3] fixed — `FRAG_NOT_PROCEDURAL` was the fragment `not procedural`, which the exact inversion of the fail-closed tie-break also satisfies; it now pins `treat the block as not procedural`, a phrase only the fail-closed reading carries → 36213db
- [M4] fixed — the gate literal `**Body authority:**` was pinned independently by two suites with no equality check, so a rename in one file with its own suite updated left the gate silently inert with every suite green; `tests/reviewer-templates/run-tests.sh` section 8 now extracts the label from both files and compares byte-for-byte → 36213db
- [M5] fixed — "running only pipeline commands" was vacuously true for a block that runs no commands at all, so an inert wording body satisfied both conjuncts and read as procedural, exempting every wording artifact from a contract entry; the conjunct is now positive (runs at least one command, every command a pipeline command), restated identically at all three sites, spec R1 and the plan amended → 36213db

## Round 4 verification 1 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
### Dispositions
- [I1] rejected: the spec rules on this explicitly — its Non-goals section states that a finding becomes a plan conflict only at controller triage, and that the controller makes that classification by consulting the plan, where it meets the header authority note; the note changes what the plan's text requires, and the controller's existing, unchanged triage rule then evaluates it. No controller skill changes by design. The finding's premise, that the triage rule itself must name the note, contradicts that ruling
- [I2] fixed — the note said flatly that a block marked `**Exact content:**` binds byte-for-byte, omitting rule 5's self-pin exception (a marker whose pin the plan itself writes or edits does not bind); the note is the only carrier that reaches a controller, so the class of historical stop the design claims to convert would still have stopped the run. The note now qualifies the marker: it binds only when its reason names a pin the plan does not write or edit → bb4e79f
- [I3] fixed — the Global-Constraints exception added in round 4 was undecidable for its reader: it cited "rule 6(b)", which does not exist in a generated plan; it named the two-part self-pin test without stating it; and "an entry failing the test" reads in the opposite direction from rule 6(b)'s meaning. The test is now stated inline and positively inside the note → bb4e79f
- [M1] fixed — the gate-label extraction in `tests/reviewer-templates/run-tests.sh` grepped the whole lens skill instead of the plan-cell text already extracted, so a future block-quote label earlier in that file could retarget the comparison → bb4e79f
- [M2] fixed — the same check selected the Plan Header label paragraph by ordinal position (`n == 2`), which a new label paragraph or a reworded "For agentic workers" label would shift, failing with a message that pointed a fixer at a correct note; selection is now by matching the lens gate label → bb4e79f
- [M3] fixed — everything the last two cycles added to the note had no falsifier: deleting the whole second half left both fast suites green. Three block-scoped assertions now pin the self-pin qualification, the Global-Constraints exception and the self-binding clause; each was demonstrated to FAIL when its clause is deleted (fix report) → bb4e79f
- [M4] fixed — the procedural predicate required the block to write no working-tree file while naming a verification `Run:` line as a canonical procedural form, and a `Run:` line invoking a formatter or a snapshot-updating test writes files; the qualifier "only when the command it runs writes no working-tree file" is now stated identically at all three sites → bb4e79f

## Round 4 verification 2 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor

**Standing rule in force for this invocation and every later one:** a
verification re-review finding against ANY plan-mandated wording is this loop's
to decide — fix it, or reject it with a named reason. A Critical is never
rejected under this rule. Such findings are never journaled as `user-decision`,
so that one stop cannot become a chain.

### Dispositions
- [I1] fixed — rules 6(c) and 6(d) had no counterpart in the `**Body authority:**` note, and the note is the only copy of the body-authority regime a controller reads (it reads the plan, never the skill file — the design's own reason, spec Amendments). A finding against header prose (`**Architecture:**`, `**Assumptions:**`, the File Structure section) or against a body in a task whose field reads `**Contract:** none — <reason>` therefore had no resolution path at triage and would have stopped the run as a plan conflict — the interruption class this design exists to remove. Both rules are now stated in the note in its own voice, with no cross-reference to a rule number; spec R3 bullet 1 amended, plan amendment block added; three block-scoped falsifiers added, each demonstrated to FAIL when its clause is deleted → 14ceaa9
- [I2] fixed — the note's exact-content sentence handled only the self-pin exception, so a marker written with no reason at all named no self-pin, the `unless` clause never fired, and the block bound byte-for-byte: an unreasoned marker got stronger protection at triage than a properly reasoned self-pin, while rule 4 of the same file calls a reasonless marker a plan failure. The note now states the missing case — a marker with no reason does not bind, the body is an ordinary fix, and the missing reason is itself a finding → 14ceaa9
- [I3] rejected: the proposed remedy is undecidable for the reader it targets. Binding the note's *properties* instead of its wording would require the controller to know the bound-property list, which lives in spec R3 — a file the controller never reads — so it replaces a rule decidable from the note alone ("this note binds as stated") with one that is not, contradicting the same decidability principle that justifies [I1] and [I2] and every earlier note fix on this branch. The invoker's invocation-1 ruling also accepted this limit explicitly and directed that it be documented, which rule 6(b) does. The finding's own evidence — four amendments against the note's wording — is answered by [I1] and [I2], which close the content gaps that generated them; the residual case is a finding against the note's own wording, which this loop's standing rule already resolves without a stop
- [M1] carried — "pipeline command" is used in the procedural test but never defined. The fail-closed tie-break absorbs the ambiguity (unclear → not procedural → a contract entry is written, never a silent exemption), and the sentence carrying the term is stated identically at three sites plus spec R1 and the plan, so defining it in place would rewrite plan-mandated wording at five locations for a Minor whose failure direction is already safe
- [M2] fixed — check 8's gate-label extraction took the first backtick-quoted block-quote label in the extracted plan cell (`head -n1`); scoping to the cell ruled out matches elsewhere in the file but not an earlier match inside the cell, so a sentence naming another label before the gate mention silently retargeted the comparison and the check reported PASS while the gate label and the note label had diverged. It now collects the distinct matching labels and FAILs naming them when more than one is found; demonstrated with an injected decoy label → 6a9da94
- [M3] carried — the five range anchors pin rule opening phrases the design treats as rewordable reference wording; same disposition and reason as round 4 [M2]. Verified in the helper source: an anchor that goes missing leaves `assert_in_range`'s start empty, its `[ -z "$start" ]` guard fires and the check reports `could not locate the range to search` — a loud FAIL, never a silent pass

_Controller note: the [I1]/[I2] fix commit (6a9da94) inserted the new clauses between the note's opening sentence and "A review finding against such a body…", moving that phrase's antecedent to the `**Contract:** none` sentence and making the note read as though a finding against a contract-less body were an ordinary fix "while the contract holds". The controller caught this before re-packaging and had the fixer reorder the sentences without changing any wording (14ceaa9); the three block-scoped falsifiers are fragment searches within the Plan Header block and are order-independent, so they still pin every clause._

## Round 4 verification 3 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor

_This is the third and last verification cycle available for round 4, so no fix
subagent was dispatched: a fix made here would ship unreviewed, which the
no-fix-ships-unreviewed rule forbids. Findings still standing are recorded as
`unresolved: verification cap`._

### Dispositions
- [I1] rejected: the spec rules on this explicitly and the ruling is unchanged since invocation 1 verification 1 [I1]. Its Non-goals section states "No change to `multi-code-review`" and that "a finding becomes a plan conflict only at controller triage ('conflicting with what the plan's text requires'), and the controller makes that classification by consulting the plan, where it meets the header authority note (R3). Reviewers keep reporting findings as today; the note changes how the controller classifies them." The finding's premise — that a reviewer finding against a reference body still conflicts with what the plan's text requires — is what the note removes: the plan's text now states that such a body is a reference implementation and a finding against it is an ordinary fix, so the controller's existing, unchanged triage rule no longer classifies it as a conflict. The proposed edit to `multi-code-review`'s triage bullet is the controller-skill change the spec puts out of scope
- [I2] rejected: same proposal and same named reason as verification 2 [I3] — binding the note's enumerated properties instead of its sentences would require the controller to know the bound-property list, which lives in spec R3, a file the controller never reads; it replaces a rule decidable from the note alone with one that is not, contradicting the decidability principle that justifies every note fix on this branch. Recorded for the invoker: this is now the SECOND independent reviewer to propose property-binding for the note (verification 2 [I3], verification 3 [I2]). The convergence is noted but does not change the ruling, because the objection is to the remedy's decidability, not to the problem it names
- [I3] unresolved: verification cap — the note contradicts itself, and the contradiction was introduced by this loop's own verification 2 [I1] fix. The sentence added there reads "Other non-task plan content — header prose such as `**Architecture:**` and `**Assumptions:**`, and the File Structure section — follows the same reference default: a finding against it is an ordinary fix …". Its list is open ("such as"), and it precedes the sentence that carves out `**Global Constraints:**` and the note itself, so on a literal reading it already covers both: two controllers triaging "the note's sentences disagree", or a finding against a `**Global Constraints:**` entry, reach opposite classifications from the note alone. In the skill file the same two rules do not collide, because rule 6(c) follows rule 6(b), which carves the exceptions out first; the note reverses that order. The remedy is one clause — close the list, for example "non-task plan content other than the `**Global Constraints:**` block and this note" — but all three verification cycles of round 4 are spent and no fix may ship unreviewed
- [M1] carried — "pipeline command" undefined at all three sites; same disposition and reason as verification 2 [M1] (fail-closed tie-break absorbs it; defining it in place would rewrite plan-mandated wording at five locations). Raised by two consecutive reviewers, so it is recorded here as a repeat rather than a new item
- [M2] carried — when the plan's `**Spec:**` path is stale, no entry traces to a spec, so conjunct (a) of the Global-Constraints self-pin test is true for every entry and the exception widens beyond self-pinned literals. Real, and the remedy is a fail-closed guard (an unresolvable `**Spec:**` path disqualifies every entry from the exception), but cycles are spent
- [M3] carried — Self-Review check 5's universe is "every fenced block or quoted wording", while bucket (c)'s second canonical form is a verification `Run:` line, which is neither; the round 4 verification 1 [M4] qualifier therefore pins a case the check cannot reach. Text-only redundancy, no behavior change
- [M4] carried — check 8's gate-label extraction requires a literal `> ` prefix inside the backticks, which the lens cell's other mention of the same label omits; a reword dropping the prefix fails with "no gate label found in the plan cell" while the gate is intact. Fail-closed, so no false green — only a misdirecting failure message

_Completed — 2026-09-01 — cap reached — HEAD a10e5a6481e28e190564ae6d967de0b1793ea49a_

## Post-loop addendum 3 — 2026-09-01 — invoker decisions on the open items

**Standing rule, restated for this and every later invocation of this loop:** a
verification re-review finding against ANY plan-mandated wording is this loop's
to decide — fix it, or reject it with a named reason. A Critical is never
rejected under this rule. Such findings are never journaled as `user-decision`,
so that one stop cannot become a chain.

The effective HEAD was 14ceaa9 when this addendum was opened — unchanged since
this entry's completion marker (the only later commits, 44cd8d5, cf8dc76 and
f930008, change nothing outside the blinding pathspec set). So no new invocation
entry is started, the decided item was applied with one fix subagent and one
verification re-review, and the completion marker above is updated to the new
effective HEAD.

### Dispositions
- [I3] (round 4 verification 3) decided (user): fix it — close the note's non-task-content reference-default sentence so it cannot be read as covering the `**Global Constraints:**` block or the `**Body authority:**` note itself; the property is mandated, the wording is the loop's to choose; add a block-scoped falsifier in `tests/writing-plans/run-tests.sh` demonstrated FAILING when the exclusion is deleted; amend the plan and the spec's Amendments section
- [I3] (round 4 verification 3) fixed — the sentence now names the two exclusions inline ("…and the File Structure section, but never the `**Global Constraints:**` block and never this `**Body authority:**` note — follows the same reference default…"); the rest of the note is byte-identical, and the numbered rules were left alone because rule 6(b) already precedes rule 6(c) and does not carry the contradiction. `tests/writing-plans/run-tests.sh` gains `FRAG_NONTASK_EXCLUSION` with an `assert_in_block` assertion scoped to the Plan Header template (block 81..96), demonstrated failing as `FAIL: Plan Header note excludes Global Constraints and itself from the non-task-content default … (not inside block 81..96)` with the clause deleted; plan amendment blocks added in Task 3 Step 3 and Task 5; spec Amendments entry added. Controller-verified at HEAD: `tests/writing-plans/run-tests.sh` 16/16, `tests/reviewer-templates/run-tests.sh` 24/24, `tests/codex/run-unit-tests.sh` 10/10 → f026387

## Round 4 verification 4 — Adversarial red-team — opus

_The addendum's single verification re-review (post-loop path). Round 4's three
in-loop verification cycles were already spent, so no further cycle is
available: findings still standing here are recorded `unresolved: verification
cap`._

**Reviewer verdict:** 0 Critical, 4 Important, 3 Minor
### Dispositions
- [I1] unresolved: verification cap — Self-Review check 5 quantifies over "Every fenced block or quoted wording **in the plan**" but offers three buckets that between them reach only task content: the Plan Header template's own block quote (`> **For agentic workers:**` / `> **Body authority:**`, which every generated plan carries) falls under no task's `**Contract:**`, carries no `**Exact content:**` marker, and runs no command, so it fails bucket (c)'s positive command conjunct as well. Controller-verified in the file: check 5 as written reports a defect on 100% of generated plans, and on every `> **Amended …**` block quote besides. The lens target in `skills/multi-doc-review/SKILL.md` is correctly scoped to task-step bodies, so the self-audit is stricter than the review that enforces it. Real and concrete; the remedy is to scope check 5's universe to task steps or add a fourth bucket for non-task content, but the cap is spent and no fix may ship unreviewed
- [I2] unresolved: verification cap — the note's exact-content sentence handles a reason that names a self-pin (ordinary fix) and a marker with no reason at all (ordinary fix), but not a reason that is present and names no pin. Such a marker falls through both clauses to the default and binds byte-for-byte, so a vacuous reason ("the exact wording matters here") buys STRONGER protection at triage than a properly reasoned self-pin — the same incentive inversion verification 2 [I2] closed for the no-reason case, left open for the bad-reason case. Controller-verified: Self-Review check 5 does require every marker's reason to name a pin external to the plan, but that requirement lives in the skill file, which a controller never reads. Remedy is to state the condition positively in the note; cap spent
- [I3] unresolved: verification cap — the note partitions plan content into "fenced code blocks and block-quoted wording **in task steps**" and "other **non-task** plan content", which leaves task content that is neither fenced nor block-quoted in neither set: `**Files:**` lists, `**Contract:**` fields, step titles, and bare `Run:` / `Expected:` prose lines. Controller-verified against this branch's own plan, where an `Expected:` count drifting from the suite's real count needed an amendment twice (most recently in the f026387 fix itself) — a common finding class with no covering rule, so two controllers classify it differently. Remedy is one word in either sentence ("all other plan content"); cap spent
- [I4] rejected: the remedy's first half is the proposal already rejected at verification 2 [I3] and verification 3 [I2] on a named reason that still holds — binding the note's enumerated properties instead of its sentences requires the controller to know the bound-property list, which lives in spec R3, a file the controller never reads, so it replaces a rule decidable from the note alone with one that is not. Its second half (give a finding against the note's own prose an explicit non-conflict disposition) is new and IS decidable from the note alone, but it changes the note's binding regime rather than its wording, which is a design decision for the invoker and not a wording fix; it is reported in the loop's return instead. Recorded for the invoker: this is the THIRD independent reviewer to propose that the note stop binding by wording (verification 2 [I3], verification 3 [I2], verification 4 [I4]). The convergence is now strong enough to be the loop's headline, but the ruling is unchanged because the objection to the first half is to its decidability, not to the problem it names
- [M1] carried — the note does not state where an `**Exact content:**` marker must sit to pin a block; rule 4 of the skill file requires it to begin the paragraph immediately preceding the block, and the controller never reads that file. Same class as [I2] and blocked by the same spent cap
- [M2] carried — "pipeline command" undefined at all three sites; same disposition and reason as verification 2 [M1] and verification 3 [M1] (fail-closed tie-break absorbs it). Raised now by three consecutive reviewers
- [M3] carried — check 8's gate-label extraction in `tests/reviewer-templates/run-tests.sh` matches the label line-by-line and so depends on the whole `` `> **Body authority:**` `` span staying on one source line of `skills/multi-doc-review/SKILL.md`; a reflow that wraps the span yields zero labels and the check fails with "no gate label found in the plan cell" while the gate is intact. Fail-closed, so a misdirecting message rather than a false green; same family as verification 3 [M4]

_Addendum completed — 2026-09-01 — cap reached — HEAD f02638725b497e13a9e1552ef2699b5993faccc0_
_Harness probes owed: none_

## Post-loop addendum 4 — 2026-09-01 — invoker decisions on the open items

**Standing rule, in force for this and every later invocation of this loop:** a
verification re-review finding against ANY plan-mandated wording is this loop's
to decide — fix it, or reject it with a named reason. A Critical is never
rejected under this rule. Such findings are never journaled as `user-decision`,
so that one stop cannot become a chain.

The effective HEAD is f026387 — unchanged since this entry's completion marker
(the only later commits, 82c11c7 and 55cdce4, change nothing outside the
blinding pathspec set). So no new invocation entry is started: the decided items
were applied with one fix subagent and one verification re-review, and the
completion marker above is updated to the new effective HEAD.

**The invoker's ruling (diagnosis and remedy).** The `**Body authority:**` note
produced three to four Important findings of the shape "case X falls between two
sentences" in each of the last four verification cycles because it enumerated the
OPEN non-binding set. The remedy is to state the CLOSED binding set instead.
Adding another clause is explicitly rejected. Two changes are applied together —
the disposition alone would make the note's defects invisible without making the
note correct, and the inversion alone would leave the self-reference problem
open.

### Dispositions
- [I4] (round 4 verification 4) decided (user): fix it — invert the note's polarity. The note states the BINDING set positively and closed (exactly two members: the `**Global Constraints:**` block, and a block whose preceding paragraph reads `**Exact content:** <reason>` naming a pin the plan does not itself write or edit); everything else in the plan — every code block, every quoted wording, every header field, and the note itself — is a reference implementation whose finding is an ordinary fix unless it contradicts a stated `**Contract:**` or a global constraint. The note also states the non-conflict disposition (a finding against the note's own wording is not a plan conflict — record it against `writing-plans` and continue) with a scoping guard (the disposition covers the note's own text alone; a finding that the note contradicts something specific to the plan it appears in is about that interaction and stays an ordinary finding). Wording is the loop's to choose; the properties are mandated. This supersedes the ruling of verification 2 [I3], verification 3 [I2] and verification 4 [I4], which rejected property-binding: the invoker takes the third convergent proposal as decisive on the problem while rejecting property-binding as the remedy — the note now binds nothing by wording at all, so no bound-property list has to reach the controller
- [I1] (round 4 verification 4) decided (user): fix it — Self-Review check 5's quantifier is independently wrong and is not dissolved by the note restructure. Scope the universe to task-step content and name the Plan Header note as out of scope
- [I2] (round 4 verification 4) decided (user): fix it — dissolved by the inversion: the binding member (ii) is stated positively, so a marker whose reason names no external pin simply is not in the binding set. No separate clause is added
- [I3] (round 4 verification 4) decided (user): fix it — dissolved by the residue clause, which covers every piece of plan content rather than partitioning it into fenced/quoted and non-task halves
- [M1] (round 4 verification 4) decided (user): fix it — dissolved by the binding member (ii), which states the marker's placement inline ("a block whose immediately preceding paragraph reads `**Exact content:** <reason>`")
- (also decided) the plan's amendment block naming "round 6", a round that does not exist in this run, is corrected to the round it records; superseded amendment blocks in the plan and in the spec's Amendments section are consolidated into one current statement rather than appended to; spec R3's bullets are amended (binding-as-stated bullet replaced by the non-conflict disposition, non-task/`Contract: none` enumeration bullet replaced by the residue clause, the label byte pin and gate-predicate bullet left exactly as it is) and R4 amended per the check-5 scoping
- [I4] [I1] [I2] [I3] [M1] (round 4 verification 4) fixed — the `**Body authority:**` note is rewritten to state the closed binding set (1008 characters of note text after the `> ` prefix, down from 1426). It now reads: exactly two things bind — the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` naming a pin the plan does not itself write or edit; everything else, the note included, is reference, and a finding against it is an ordinary fix unless it contradicts a stated `**Contract:**` or a global constraint; a finding whose subject is the note's own wording is never a plan conflict (record it against the plan-writing skill file and continue), and that disposition covers the note's own text alone, so a finding that the note contradicts something specific to its plan stays an ordinary finding. Rule 6(b) of `skills/writing-plans/SKILL.md` is reconciled with the new disposition; rules 6(b)'s Global-Constraints self-pin exception, 6(c) and 6(d) stay in the skill body, which is now their only home. Self-Review check 5's universe is scoped to task-step content (fenced blocks, block quotes and `Run:` lines) with plan-header content named out of scope apart from the `**Global Constraints:**` entries it already inspects; bucket (c)'s three-site sentence is byte-unchanged. `tests/writing-plans/run-tests.sh`: seven Plan-Header assertions pinning deleted note text removed with their now-unused constants, six new assertions added (closed binding set, exact-content binding condition, residue clause, non-conflict disposition, scoping guard, check-5 scoping), each demonstrated FAILING when its clause is deleted (fix report). Spec R3's binding-as-stated bullet and its non-task/`Contract: none` enumeration bullet replaced per the ruling, the label-and-gate bullet untouched, R4 amended, Amendments consolidated; the plan's note-amendment chain consolidated into one block, the "round 6" label gone with it, check count corrected 16 → 15. Controller-verified at HEAD: `tests/writing-plans/run-tests.sh` 15/15, `tests/reviewer-templates/run-tests.sh` 24/24, `tests/codex/run-unit-tests.sh` 10/10 → a10e5a6

## Round 4 verification 5 — Adversarial red-team — opus

_The addendum's single verification re-review (post-loop path). Round 4's three
in-loop cycles plus addendum 3's cycle are spent, so no fix subagent was
dispatched: a fix made here would ship unreviewed, which the
no-fix-ships-unreviewed rule forbids. Every Important below is a finding against
plan-mandated wording, so the standing rule governs: with "fix it" unavailable
under the cap, each is rejected with a named reason rather than journalled as a
user decision. The residual risks the rejections leave standing are reported to
the invoker in this loop's return._

**Reviewer verdict:** 0 Critical, 4 Important, 3 Minor
### Dispositions
- [I1] rejected: the invoker decided precisely this trade-off in the ruling this addendum applies — the binding set is closed at exactly two members, and self-pin mechanics stay in the numbered rules of the skill body. Adding the `**Global Constraints:**` self-pin exception back into the note is the enumeration the ruling removes. The rejection is not a claim that the consequence is unreal: from the note alone, a lens target-4 finding against a `**Global Constraints:**` entry now reads as a plan conflict, where the previous note gave it a resolution path. That cost was accepted knowingly in exchange for ending a class of "case X falls between two sentences" findings that recurred in four consecutive cycles. Recorded for the invoker as the restructure's one known regression
- [I2] rejected: rule 1's opening enumeration ("the Step 5 commit command, `Run:` verification lines") is illustrative and is explicitly subordinated to the test stated two sentences later in the same rule — "The test is intrinsic to the block", and "This is the one test for 'procedural' used everywhere in the plan you are writing and in review". The two do not carry equal authority, so an agent that reads the rule to its end reaches one answer. The drift also predates this fix (round 4 verification 1 [M4] added the qualifier at the canonical-forms clause and left the enumeration alone) and is outside this addendum's subject. Recorded as a wording drift worth closing in a later pass
- [I3] rejected: a `Run:` line that runs the task's own verification falls under bucket (a) — rule 1 requires a `**Contract:**` to state "the verification (a runnable command or check)", so the task's stated contract names it. The residue the finding describes is a task-step `Run:` line that is neither the task's verification nor free of working-tree writes — `Run: npm install`, say. Under the old text that line was outside check 5's universe and passed silently; under the new text the check flags it. That is the fail-closed direction rule 1's own tie-break prescribes ("unclear → not procedural → a contract entry, never a silent exemption"), so the change makes the check stricter where it was silent, not wrong
- [I4] rejected: a finding asserting that a stated `**Contract:**` is wrong or vacuous contradicts that contract in the plain sense — it asserts what the contract denies — and the residue clause already routes such a finding away from "ordinary fix" ("unless it contradicts a stated `**Contract:**` or a global constraint"). The finding's premise, that the hedge cannot cover a finding whose subject IS the contract, is one reading of the clause and not the one the clause's plain words carry. Naming the `**Contract:**` field as a third binding member would also break the two-member closure the ruling mandates
- [M1] carried — the note tells a controller to "record it against the plan-writing skill at `skills/writing-plans/SKILL.md`", a repository-relative path that does not exist in a consumer project, where the skill lives in the plugin cache. Real, and it is the controller's own wording; the intent (record against the skill, not against the plan) survives the missing path, and the cap is spent. The single wording nit worth a follow-up pass
- [M2] carried — rule 4 admits three reason kinds for `**Exact content:**` (a pre-existing test, a file that must match, cited user-approved copy) while the note's binding condition speaks only of "a pin this plan does not itself write or edit"; user-approved copy is an approval record rather than a pin, so the note's condition is narrower than rule 4's. Narrow and cap-blocked
- [M3] carried — check 8's gate-label extraction in `tests/reviewer-templates/run-tests.sh` pins the lens cell's typography (the `> ` prefix inside the backtick span) rather than the gate itself, so a reflow or a reword fails the check with a misdirecting message while the gate is intact. Fail-closed, never a false green; same family as round 4 verification 3 [M4] and verification 4 [M3]

_Addendum completed — 2026-09-01 — cap reached — HEAD a10e5a6481e28e190564ae6d967de0b1793ea49a_
_Harness probes owed: none_
