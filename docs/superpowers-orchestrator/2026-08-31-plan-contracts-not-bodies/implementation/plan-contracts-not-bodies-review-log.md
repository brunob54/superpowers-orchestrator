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
