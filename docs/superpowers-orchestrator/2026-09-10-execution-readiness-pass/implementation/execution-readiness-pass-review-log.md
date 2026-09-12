# Code review log — execution-readiness-pass

carried findings: 31 `Minor:` lines read from `.superpowers/sdd/progress.md`

_Invocation 1 — 2026-09-11 — N=4 M=3 — BASE..HEAD 0f0a48d..c052a2b — branch feature/execution-readiness-pass — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 6 Minor | r2: 0 Critical, 2 Important, 3 Minor | r3: 0 Critical, 2 Important, 5 Minor
**Sources mapped:** 20/20
**Reviewer verdict:** 0 Critical, 5 Important, 13 Minor
**Converged:** no
### Dispositions
- [I1] fixed — readiness-pass definition at SKILL.md:636 now names `Triage of a readiness finding` beside the mandated "same validation, consolidation and triage as a round" phrase, which stays → c168b96 ← 2/3: r1:I2, r3:I1
- [I2] fixed — the **On a resume** fallthrough is narrowed so a plan document continues under the `Readiness entries` resume order instead of rotating rounds r+1..N → c168b96 ← 1/3: r1:I1
- [I3] fixed — the readiness-triage authority rule is restated as the design spec's single two-part test, removing the contradictory head condition → c168b96 ← 1/3: r2:I1
- [I4] fixed — Deviation 1 of the Phase 2 controller template gains the readiness exclusion as prose; Deviation 3 is byte-identical and the template still holds exactly one bracketed single capital letter → c168b96 ← 1/3: r2:I2
- [I5] fixed — the once-per-gate "For a complete entry" sentence is qualified, and the two plan routes are added to the **Otherwise** enumeration → c168b96 ← 1/3: r3:I2
- [M1] fixed — the **Otherwise** parenthetical now names the `another pass requested` marker, so it cannot be read as the self-review marker → c168b96 ← 2/3: r1:M1, r3:M5
- [M2] rejected: Global Constraint 3 permits exactly three changed items outside the `reviewer-prompt.md` fence and the `[LENS_INSTRUCTIONS]` note is not one of them — reviewer-prompt.md:141 says "copied verbatim" while SKILL.md:664-665 orders a clause removed on the missing-structure path ← 1/3: r1:M2
- [M3] carried — the readiness triage names no route for a finding whose premise is a harness property, which the shared reviewer prompt still tells every reviewer to tag ← 1/3: r1:M3
- [M4] carried — docs/guide/README.md:247-249 reads as though both sequences run at N = 0, while the skill runs the pre-sequence alone ← 1/3: r1:M4
- [M5] carried — the guide and RELEASE-NOTES say "repeated until a pass changes nothing", weaker than the settled rule, which also requires every reviewer usable ← 1/3: r1:M5
- [M6] rejected: orchestration artifact (documented) — the branch adds an orchestration log and a plan review log under the topic folder; reported by the reviewer as required, contents unread ← 1/3: r1:M6
- [M7] carried — docs/guide/README.md:258-259 points at a pre-flight plan read that section 3 Stage 3 never describes ← 1/3: r2:M1
- [M8] carried — SKILL.md:961 gives `superseded` no trigger and does not say whether such an entry counts toward the sequence cap ← 1/3: r2:M2
- [M9] carried — SKILL.md:958-961 derives a readiness pass number from position among `## Round` headings, which cannot separate pass numbers inside one sequence ← 1/3: r2:M3
- [M10] carried — SKILL.md:389 gives the pre-sequence only the "before round 1" trigger, a point that does not exist at N = 0 ← 1/3: r3:M1
- [M11] carried — SKILL.md:951-952 requires an `Owed:` item to name both sides, which cannot be written for a `rejected: not a conflict` item ← 1/3: r3:M2
- [M12] carried — the plan's Task 9 Step 1 block fuses an implementer-only note into user-facing guide content; the shipped guide is correct ← 1/3: r3:M3
- [M13] carried — SKILL.md:378 gives the `git hash-object` producer of `plan-blob` no failure route, so a silent miss switches the feature off for that plan ← 1/3: r3:M4

Carried-finding dispositions (round 1), decided from the round-1 reviewers'
recommendations under the corroboration rule — `user-decision` needs two of
the three reviewers, else `fix-before-merge` if any reviewer recommends it,
else `ship-as-is`. The three `fix-before-merge` items were fixed in this
round; no carried item's premise is a harness property, so the harness guard
named no probe.

- [L1] carried — SKILL.md:650-681, the readiness cell lists plan, spec, general while the four existing cells list spec, plan, general
- [L2] carried — reviewer-prompt.md:139 is 95 characters and cannot be wrapped, because tests/reviewer-templates/run-tests.sh:401 matches it with a single-line grep -qF
- [L3] fixed — the lens cell's two residual-risk mitigation sentences are now pinned by one new `assert_folded_contains` on `will be discarded` in tests/reviewer-templates/run-tests.sh → 840a145
- [L4] carried — tests/reviewer-templates/run-tests.sh:355-357, the readiness-cell extractor stops at `^## ` and would not stop at a `###` heading
- [L5] carried — SKILL.md:566-567, the post-sequence resume guard states the fact but not the consequence; the pre-sequence trigger supplies it
- [L6] carried — SKILL.md:595, a 16-character ragged line left from the pasted reference body
- [L7] carried — SKILL.md:392-395, the step-2 usability sentence sits before "Each unusable report" instead of after the sentence the brief named
- [L8] carried — SKILL.md:637-638, a blank line splits one mandated paragraph in two; no current needle spans the break
- [L9] carried — tests/reviewer-templates/run-tests.sh:216-228, the 11 section-13 needles fold the whole file rather than the subsection
- [L10] carried — SKILL.md:651-654, Step 0 uses "the higher side" before Step 1 defines the two authority levels
- [L11] carried — SKILL.md:675-679, the stated reason for excluding "out of lens scope" from the `Owed:` block also fits `rejected: not a conflict`, which is listed
- [L12] carried — SKILL.md:671, a whole sentence is rendered as one monospace code span mid-paragraph
- [L13] carried — tests/reviewer-templates/run-tests.sh:468, the clause-3 needle "as a round is" is a generic four-word fragment
- [L14] carried — tests/reviewer-templates/run-tests.sh:467, the clause-2 needle stops before the rule it introduces
- [L15] carried — tests/reviewer-templates/run-tests.sh:458 and :463, "rejected: plan-mandated" is a strict substring of a longer needle on the same list and can never fail alone
- [L16] carried — SKILL.md:963-968 and :987-989, one unrouted N = 0 state after a cap recomputation; it costs a redundant pass, never correctness
- [L17] fixed — SKILL.md now reads "Either of the two invocation lines below adds `M=<m>`", removing the reading in which a controller writes both lines and freezes `r` at 0 → 840a145
- [L18] carried — SKILL.md:304-306 vs :345-347, the "only fields read" whitelist is read about 40 lines before the sentence that extends it
- [L19] carried — SKILL.md:998-1000, "counts as changed, so it never blocks" read alone contradicts :975-977; the paragraph's subject scopes it to N = 0 entries
- [L20] carried — SKILL.md:367-369, "The `plan-blob` field is the one exception" sits in a paragraph covering all three document kinds and names no entry class
- [L21] carried — SKILL.md:955-957, **Fields read** lists the marker line without saying which entries carry it
- [L22] carried — SKILL.md:963-968, the completeness test nests an "or" inside a comma list, so one clause can be read as a standalone branch
- [L23] carried — SKILL.md:380, :383, :1008, under-filled lines left by the mechanical edits
- [L24] carried — SKILL.md, the clean-round paragraph was reflowed although no mandated edit touches it; whitespace only
- [L25] carried — tests/reviewer-templates/run-tests.sh, section 15 pins the completion-report paragraph by string with no position assertion
- [L26] carried — tests/reviewer-templates/run-tests.sh, three brief-mandated needles ("has ended", "git hash-object", "Readiness pre:") are weak regression pins
- [L27] carried — skills/orchestrating-development/SKILL.md:265-270, two near-restated sentences about N_plan = 0; both are separately mandated Must-convey items
- [L28] fixed — tests/orchestrating-development/run-tests.sh:338, the assertion description no longer claims the Phase 2 controller runs no commands; only the description string changed → 840a145
- [L29] carried — skills/orchestrating-development/doc-review-loop-prompt.md:58,64, "post-sequence" is used twice and defined only in the skill the template points at
- [L30] carried — docs/REVIEW-PROCESS-COMPARISON.md:192-195, the reflow moved one line-wrap boundary past the mandated phrase; no word changed
- [L31] user-decision — the plan's Task 10 Step 4 expects every suite in its eight-suite chain to end "0 failed", but tests/smart-compress/run-tests.sh ends 79 passed, 8 failed; the controller re-ran it on this branch and confirmed the failures, and git diff over BASE..HEAD shows the branch changes neither that suite nor hooks/, so the redness predates the branch. A reader of Task 10 Step 4 would read those 8 failures as a regression of the release commit (plan-mandated) — at docs/superpowers-orchestrator/2026-09-10-execution-readiness-pass/plans/execution-readiness-pass.md:1514 — clause: Task 10 "Expected: PASS for every suite each ends with 'Results: <n> passed, 0 failed' (the Codex suite prints its own summary) and the chain exits 0."

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 4 Minor | r2: 0 Critical, 3 Important, 4 Minor | r3: 0 Critical, 4 Important, 3 Minor
**Sources mapped:** 22/22
**Reviewer verdict:** 0 Critical, 8 Important, 10 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the lens cell's coverage-block anchor now exists in every report shape, so a zero-finding readiness report can carry the block instead of being discarded; both mitigation sentences are kept → b2590ba ← 3/3: r1:I2, r2:I3, r3:I1
- [I2] fixed — `<k>` of `coverage: GC<k>` is defined as the 1-based position among the Global Constraints top-level list items, one line per position in order, a repeated or out-of-range `<k>` counting as a missing line → b2590ba ← 2/3: r1:I3, r2:I1
- [I3] fixed — Step 0 of the readiness triage now defines "found" as matching after the file's lines are folded and whitespace runs collapsed, so ordinary wrapped plan prose is no longer rejected as not a conflict → b2590ba ← 1/3: r1:I1
- [I4] fixed — position governs a readiness heading only where a `## Round` heading exists and the entry lies outside their span, and `<p>` is the entry's ordinal among its own sequence's entries → b2590ba ← 1/3: r1:I4
- [I5] fixed — "its pre-sequence has not ended" is added to the plan interrupted test and to the N ≥ 1 completeness clause, so the resume order and the completeness rule speak about the same three stages → b2590ba ← 1/3: r2:I2
- [I6] fixed — one routing sentence above the conflict table sends an amendment-reversal finding to the `fixed text vs fixed text` row whatever its sides' authority; the row and its pinned phrase are byte-identical → b2590ba ← 1/3: r3:I2
- [I7] fixed — the completeness rule now also holds for a plan entry whose rotating range an overriding N = 0 emptied, so such an entry can no longer stay interrupted forever → b2590ba ← 1/3: r3:I3
- [I8] fixed — the readiness heading, the `**Result:**` line and `**Host self-review:** done` count only inside their own entry, never as quoted text, and `Owed:` quoted sides must be indented or fenced → b2590ba ← 1/3: r3:I4
- [M1] fixed — a heading carrying ` — superseded` counts toward nothing, the pass count included, and the one obsolescence condition is named → b2590ba ← 2/3: r1:M1, r2:M2
- [M2] fixed — the sequence-end test reads "at least as many passes as its cap", so a cap recomputed downward can no longer leave an entry permanently incomplete → b2590ba ← 1/3: r1:M2
- [M3] carried — the `readiness owed: <n>` note has no field in the orchestrator's Phase 2 log line, so the count is dropped at the phase boundary ← 1/3: r1:M3
- [M4] carried — the missing-structure header note is required on "every readiness entry of this invocation", which would mean back-filling an entry already closed ← 1/3: r1:M4
- [M5] carried — the self-review marker and the `plan-blob` rewrite are two writes at "that same moment" with no stated order and no crash rule ← 1/3: r2:M1
- [M6] fixed — "A missing sweep costs a retry; it can never settle a sequence", which no longer contradicts the cap behaviour → b2590ba ← 1/3: r2:M3
- [M7] carried — the gate cost sentence omits retries, and docs/guide/README.md promises an owed conflict appears in the gate's report, which the orchestration path does not deliver ← 1/3: r2:M4
- [M8] carried — the pre-sequence's only procedural trigger is "before round 1", a point that does not exist at N = 0 ← 1/3: r3:M1
- [M9] carried — the plan's Global Constraint 1 states "about 258 net lines", "near 1046" and a "34-line margin"; the file is now at the 1080 cap with no headroom, and tests/reviewer-templates/run-tests.sh repeats the 258 figure. The binding rule, at most 1080 lines, holds. The subject is binding plan text, which this loop never edits ← 1/3: r3:M2
- [M10] carried — the plan's Task 9 Step 1 fenced body holds an implementer-only note between two sentences meant to be written; the shipped guide correctly omits it ← 1/3: r3:M3

## Round 3 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 1 Important, 2 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the column-1 guard on quoted control fields now covers a disposition line as well as an `Owed:` item, so a quoted `**Host self-review:** done` or `## Readiness` line can no longer be read as a real field → 7674643 ← 2/3: r1:I1, r2:M3
- [M1] fixed — `git hash-object "<plan path>"` is quoted at all five sites, and the two test needles that quoted the unquoted form were updated with it → 7674643 ← 3/3: r1:M1, r2:M2, r3:M1
- [M2] fixed — the controller's read-only-command grant keeps its Contract-mandated wording and now enumerates what that is today, one command and nothing else → 7674643 ← 3/3: r1:M2, r2:M1, r3:M2

Note on [I1]: the fix asked for the disposition-line half to be added to the test
assertion that pins the `Owed:` half. No assertion pins that guard sentence at all
today, so none was extended and none was added; the shipped rule carries the fix, the
test suite does not pin it. Recorded here so the gap is visible to a later release.

## Round 4 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 5 Minor | r2: 0 Critical, 2 Important, 3 Minor | r3: 0 Critical, 2 Important, 5 Minor
**Sources mapped:** 19/19
**Reviewer verdict:** 0 Critical, 5 Important, 7 Minor
**Converged:** no
### Dispositions
- [I1] fixed — section 13 gains three needles pinning the settled-pass definition, the reduced cap for a plan with no locatable spec, and the fresh-invocation clause; a reviewer had proved by mutation that deleting the cap clause left the suite green → 9ee6b97 ← 3/3: r1:I1, r2:M3, r3:I2
- [I2] fixed — the size-budget comment now records the measured figures, 788 at base, 291 added, 1079 now, one line of headroom under the 1080 maximum, in place of arithmetic the file contradicted; the 1080 figure itself is binding plan text and was not touched → 9ee6b97 ← 3/3: r1:M1, r2:I1, r3:M2
- [I3] fixed — two needles now pin the pre-sequence and post-sequence ordering sentence itself, beside the two bare words the plan's Task 2 Contract lists as invariants, which are kept → 9ee6b97 ← 2/3: r1:I2, r2:M1
- [I4] fixed — two positive assertions pin the sentence that states the N_plan = 0 behaviour and its return contract, so a reworded reintroduction of the Phase 2 skip can no longer pass on the negative assertion alone → 9ee6b97 ← 1/3: r2:I2
- [I5] fixed — section 14 gains needles for the two central rows of the readiness triage table, including the only statement that a readiness finding is ever applied; a reviewer had proved by mutation that deleting both rows left the suite green → 9ee6b97 ← 1/3: r3:I1
- [M1] carried — this suite's `first_line_of` is substring-based while the sibling suites use a whole-line form; every anchor is unique today ← 2/3: r1:M4, r3:M4
- [M2] carried — sections 13, 14 and 15 verify subsection-scoped contracts with file-wide matches, so prose that migrates into another section keeps the suite green ← 2/3: r2:M2, r3:M1
- [M3] fixed — two assertions pin the Phase 2 template's new sentences: the readiness exclusion from `unresolved`, and the `_Loop complete_` line appended when it is absent → 9ee6b97 ← 1/3: r1:M2
- [M4] carried — the plan's Task 10 verification greps for `executing-plans`, a string already present twice in the guide before this branch, so that one check passes vacuously. The subject is plan text, which this loop never edits ← 1/3: r1:M3
- [M5] carried — section 14 leaves two Error Handling invariants unasserted (the tier-2 and tier-3 first sentence, and the absence of the word `unresolved` in the two bullets) and two of its needles stop mid-sentence; both needles are brief-mandated and already carried from the ledger ← 1/3: r1:M5
- [M6] fixed — one assertion now guards the `## Lens Rotation` table against an `Execution readiness` row, which the existing bold-count guard would not have caught → 9ee6b97 ← 1/3: r3:M3
- [M7] carried — the six documentation needles the plan names for docs/guide/README.md, docs/FORK-IMPROVEMENTS.md and docs/REVIEW-PROCESS-COMPARISON.md are run once by hand and committed to no suite ← 1/3: r3:M5

## Round 4 verification 1 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 6 Minor, counts recomputed | r2: 0 Critical, 0 Important, 4 Minor | r3: 0 Critical, 1 Important, 5 Minor
**Sources mapped:** 17/17
**Reviewer verdict:** 0 Critical, 2 Important, 9 Minor
### Dispositions
- [I1] fixed — one needle now pins the silent-failure guard "Never use the absence of a `## Readiness` heading as that test", which the plan's own cut procedure would otherwise have allowed to be deleted with the suite green → 6b978c3 ← 1/3: r1:I1
- [I2] fixed — three needles now pin the **On a resume** plan narrowing, the only one of the five corrections the plan calls undroppable that carried no contract test → 6b978c3 ← 1/3: r3:I1
- [M1] carried — the section 13, 14 and 15 needle loops assert against the whole file although their descriptions name a subsection, and the two bare needles `pre-sequence` and `post-sequence`, which the plan's Task 2 Contract lists as invariants and which therefore stay, cannot fail on their own ← 3/3: r1:M1, r1:M4, r2:M2, r3:M2
- [M2] fixed — the Lens Rotation range no longer falls back to an empty file: an unresolved or inverted anchor now calls `bad`, so the guard on the release's uncounted-lens promise can no longer pass vacuously. This was a defect in a round 4 fix → 6b978c3 ← 3/3: r1:M2, r2:M1, r3:M1
- [M3] carried — the 1080-line maximum leaves one line of headroom, and the plan's Global Constraint 1 promises a 34-line margin. The maximum is binding plan text this loop cannot raise, and the test comment already records the measured state; the remaining hazard is that the next one-line wording fix in that file turns the suite red until prose is reflowed ← 2/3: r1:M6, r3:M3
- [M4] carried — three needles are short fragments matched file-wide (`as a round is`, `has ended`, `git hash-object`); two of the three are named as invariants by the plan's Task 4 Contract ← 1/3: r1:M3
- [M5] carried — Step 0 of the readiness triage, the step that produces `rejected: not a conflict`, carries no needle ← 1/3: r1:M5
- [M6] fixed — two needles now pin the orchestration path's own report shapes, the compact `readiness owed: <n>` note and the `gate: orchestration` invoker value → 6b978c3 ← 1/3: r2:M3
- [M7] carried — the coverage-index `<k>` rules and the clause-removal rule "Removing a clause never renumbers the checks that remain" carry no needle ← 1/3: r2:M4
- [M8] fixed — one needle now pins "today that is one command … and nothing else", the premise the Phase 2 background-read exemption rests on → 6b978c3 ← 1/3: r3:M4
- [M9] carried — four further pieces of behaviour-bearing prose carry no needle: the lens cell's "never reconstruct it" safety sentence, its other-lenses boundary sentence, the `<k>` numbering rule and the `Readiness post: not run (N=0)` shape ← 1/3: r3:M5

## Round 4 verification 2 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 4 Minor | r2: 0 Critical, 1 Important, 3 Minor | r3: 0 Critical, 2 Important, 4 Minor
**Sources mapped:** 14/14
**Reviewer verdict:** 0 Critical, 2 Important, 8 Minor
### Dispositions
- [I1] fixed — one needle now pins the sequence-end definition itself, `A sequence **has ended** when its last pass reads`, which occurs once; the bare `has ended` needle stays because the plan's Task 4 Contract lists it as an invariant, and the ordering half of this finding was already pinned by the round 4 fixes → 9c4305a ← 2/3: r1:M1, r3:I1, r3:M1
- [I2] fixed — two paired assertions now pin the two lens-cell anchors the clause-removal table quotes verbatim, so a reword on the cell side turns the suite red instead of leaving the removal instruction pointing at text that no longer exists → 9c4305a ← 2/3: r2:I1, r3:I2
- [M1] carried — the section 13, 14 and 15 needle loops still assert against the whole file rather than the subsection their descriptions name; a reviewer proved by mutation that deleting the triage subsection leaves 6 of 13 needles green, while the position checks do catch an outright deletion ← 2/3: r2:M1, r3:M2
- [M2] carried — the step-2 coverage usability needle is asserted file-wide although the four sibling step-2 assertions above it use the step-2 span the suite already builds ← 1/3: r1:M2
- [M3] carried — no test fills the controller template with `N_PLAN=0`, the release's central new input; a reviewer read the fill script and confirmed the value survives, so this is a coverage gap and not a live defect ← 1/3: r1:M3
- [M4] carried — the 1080-line maximum leaves one line of headroom against the plan's promised 34, and the prescribed remedy is the reflow most likely to disturb the whole-line assertions the same constraint protects ← 1/3: r1:M4
- [M5] carried — two ordinary sentences in the skill are wrapped in backticks and render as inline code; the assertions match either way, so the suite cannot see the markup choice ← 1/3: r2:M2
- [M6] carried — Global Constraint 3, no changed line inside the reviewer prompt's fence, has no automated guard; a reviewer confirmed by reading the hunk that both changed regions on this branch are outside the fence ← 1/3: r2:M3
- [M7] carried — the completion-report line shapes are pinned only by their labels: `Readiness post: not run (N=0)`, the `pass(es) —` shape and the `[ROUND]` value `readiness <pre|post> <p>` are unpinned ← 1/3: r3:M3
- [M8] carried — the size-budget arithmetic has no negative control in the suite; the plan names one as a manual step, and a reviewer ran it by hand on a padded copy and saw it report over budget ← 1/3: r3:M4

## Round 4 verification 3 — Test & coverage quality — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 4 Minor | r2: 0 Critical, 1 Important, 5 Minor | r3: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 16/16
**Reviewer verdict:** 0 Critical, 3 Important, 5 Minor
### Dispositions
- [I1] unresolved: verification cap — the clause-removal machinery and the triage authority rules carry no assertion: the removal table's `Clause removed` column, the no-renumbering paragraph, the paragraph that tells the controller where to stop, the `<k>` numbering rule that decides report usability, and Step 0's side-matching test with Step 1's `Fixed text` list. The controller verified the gap: only the cell-side anchor is pinned. Three cycles of verification were spent on the findings of rounds 1 to 4, so no cycle remained to review a fix for this one — at skills/multi-doc-review/SKILL.md:672 — clause: Task 2 "- Invariants: the subsection carries the strings `pre-sequence`, `post-sequence`, `at most three passes`, `Readiness passes are not counted in N and are not par"
- [I2] unresolved: verification cap — the sentence that wires a readiness pass to its lens text carries no assertion in any suite: `[LENS_NAME]` = `Execution readiness`, `[LENS_INSTRUCTIONS]` = that lens's `plan:` cell, `[ROUND]` = `readiness <pre|post> <p>`. Both endpoints are pinned and the link joining them is not, so a reword pointing the fill at the `spec:` cell would hand every readiness reviewer the text "not used" as its lens instructions with every suite green. The controller confirmed no test matches the sentence. No verification cycle remained to review a fix — at skills/multi-doc-review/SKILL.md:639 — clause: Task 2 "- Invariants: the subsection carries the strings `pre-sequence`, `post-sequence`, `at most three passes`, `Readiness passes are not counted in N and are not par"
- [I3] unresolved: verification cap — the plan states a verification the shipped test performs only in part: no needle anywhere in tests/ matched `skip the rotating loop` or the tier sentence, so those two fragments could be reverted with every suite green. The bullet's readiness clause `for a plan document the Execution readiness pre-sequence still runs` is not among them: it is already pinned at tests/reviewer-templates/run-tests.sh:428 and :495, so the narrowed invalid-N bullet as a whole was never revertible with the suite green. This sentence corrects the original wording of this line, which claimed the whole bullet was revertible; the correction was ordered by the orchestrator with the decision recorded in the addendum below. No verification cycle remained to review a fix — at skills/multi-doc-review/SKILL.md:1035 — clause: Task 3 "- Verification: the same suite section asserts the new bullet's three clauses and the narrowed invalid-N wording."
- [M1] carried — the bare `pre-sequence` and `post-sequence` needles still cannot fail on their own; the plan's Task 2 Contract lists both as invariants, so they stay, and the ordering they stand for is pinned by the round 4 fixes ← 2/3: r1:M1, r2:M1
- [M2] carried — Phase 0's positive rules are unpinned: `N_plan=0 still dispatches the Phase 2 controller` and `N_code=0 means you skip Phase 4 yourself` have no assertion, while the matching Phase 2 text gained three ← 2/3: r1:M3, r2:M5
- [M3] carried — sections 13, 14 and 15 still assert against the whole file rather than the subsection their descriptions name ← 2/3: r2:M2, r3:M3
- [M4] carried — section 14 recomputes `SEQ_LINE` and `LENS_ROT_LINE` under new names with identical arguments, so a later change to one anchor string leaves the other stale ← 1/3: r2:M3
- [M5] carried — one assertion description in tests/orchestrating-development/run-tests.sh names a reason that holds for only one of the two templates its loop runs over ← 1/3: r2:M4

_Completed — 2026-09-11 — cap reached — HEAD 9c4305ac0fd8a73c239b3abd85c6908020c4d11f_
Secrets found: none

### Decisions addendum — 2026-09-11

Answers supplied by the orchestrator on a later dispatch, for the open items of invocation 1.

- [I1] decided (orchestrator): fix it: add `assert_folded_contains` needles in the existing section-13 needle loop of tests/reviewer-templates/run-tests.sh for the three fallback rows `check (3)`, `check (4)` and `check (5)`, for the `<k>` numbering rule (1-based position among the Global Constraints top-level list items; a repeated or out-of-range `<k>` counts as missing), and for the removal table's `Clause removed` cells. Leave the no-renumbering paragraph and the "Stop at that paragraph" paragraph unpinned, so Global Constraint 1 Move 2 keeps a cut reserve at the one-line margin. Do not file Step 0's folded side-matching test or Step 1's `Fixed text` list under Task 2 — they are Task 3's contract; record them as owed in the completion report. Never use `assert_file_contains` or `assert_file_has_line` for any of these: a whole-line assertion adds a member to Global Constraint 1 Move 1's no-reflow list.
- [I1] fixed — six `assert_folded_contains` needles added inside the existing section-13 loop: three whole-row needles for the fallback rows `check (3)`, `check (4)` and `check (5)`, each carrying its `Clause removed` cell, and two needles for the `<k>` numbering rule (the 1-based-position sentence and the repeated/out-of-range sentence). The no-renumbering paragraph and the "Stop at that paragraph" paragraph were left unpinned as instructed, and no whole-line assertion was used → c9700a9
- [I2] decided (orchestrator): fix it: add ONE `assert_folded_contains` needle over the whole readiness lens-wiring sentence, covering all three placeholder mappings together (`[LENS_NAME]` = `Execution readiness`, `[LENS_INSTRUCTIONS]` = that lens's `plan:` cell, `[ROUND]` = `readiness <pre|post> <p>`), in the same section-13 needle loop. Never `assert_file_contains` or `assert_file_has_line`, which would make the sentence a seventh member of Global Constraint 1 Move 1's no-reflow list and remove the reflow lever. Mind the apostrophe in `that lens's` when quoting the needle in bash.
- [I2] fixed — one `assert_folded_contains` needle now spans the whole readiness lens-wiring sentence, pinning the three placeholder mappings together; the embedded apostrophe is written with the concatenation idiom the file already uses → c9700a9
- [I3] decided (orchestrator): fix it: add `assert_folded_contains` needles for the two genuinely unpinned fragments only — the tier sentence and `skip the rotating loop, log` — each written as a whole-bullet needle, never the bare fragment `tier 2, else tier 3`, which prose elsewhere in the same file would satisfy while pinning nothing. Do NOT re-pin `for a plan document the Execution readiness pre-sequence still runs`: it is already pinned at tests/reviewer-templates/run-tests.sh:428 and :495, verified by the orchestrator. Also correct this item's own disposition text in the review log, which claims the whole narrowed invalid-N bullet is revertible with every suite green when its readiness clause is in fact pinned.
- [I3] fixed — two whole-bullet `assert_folded_contains` needles added, one for the tier sentence and one for `N = 0 → skip the rotating loop, log;`; the already-pinned readiness clause was not re-pinned, and the [I3] disposition line of Round 4 verification 3 above was corrected in this same commit → c9700a9
- [L31] decided (orchestrator): amend plan: Task 10 Step 4 now runs tests/smart-compress/run-tests.sh outside the `&&` chain and records its "79 passed, 8 failed" as predating BASE, since the branch changes neither that suite nor hooks/; the amendment is already committed in chore(orchestration): execution-readiness-pass ruling 1, so the plan file already reads the amended way. fix it: nothing further in code — do not modify tests/smart-compress/ or hooks/, which are outside this branch's scope. No code change follows from this answer; the item is closed.

Verification re-review skipped: the effective HEAD had moved past this entry's completion marker before the addendum was written (the plan amendment of commit 5d8e528), so a new invocation entry follows and reviews the fix. This entry's completion marker is unchanged.

_Invocation 2 — 2026-09-11 — N=4 M=3 — BASE..HEAD 0f0a48d..c9700a9 — branch feature/execution-readiness-pass — gate: orchestration_

## Round 5 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 4 Minor | r2: 0 Critical, 2 Important, 2 Minor | r3: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 14/14
**Reviewer verdict:** 0 Critical, 3 Important, 7 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the once-per-gate interrupted test was unqualified and preempted the plan completeness rule, so an entry finished under an N = 0 override resumed forever; the test is now narrowed to spec and general documents and a plan entry reaches `Readiness entries` unconditionally → 5f01e60 ← 3/3: r1:M2, r2:I1, r3:M3
- [I2] fixed — the resumed round range and the `## Round <i>` header numbering were narrowed to spec and general documents, leaving a plan resume with no range established anywhere; the sentence now applies to every document type and `Readiness entries` decides only which stage runs first → 5f01e60 ← 2/3: r1:I1, r2:I2
- [I3] fixed — Step 0 of the readiness triage demanded two file-quotable sides, which made the check (2) plan-mandated row unreachable; Step 0 now exempts a check (2) finding, which has one side only → 5f01e60 ← 1/3: r3:I1
- [M1] fixed — the 1080-line budget of skills/multi-doc-review/SKILL.md had one line of headroom left; Move 1 reflow of the added prose brought the file to 1074 lines with no whole-line-asserted line reflowed → 5f01e60 ← 2/3: r1:M4, r2:M2
- [M2] carried — skills/multi-doc-review/SKILL.md:748 tells the controller to copy the lens cell verbatim while `Readiness sequences` may order a clause removed ← 1/3: r1:M1
- [M3] carried — no Error Handling bullet covers `git hash-object` failing or being unavailable when the `plan-blob` field is written ← 1/3: r1:M3
- [M4] carried — a readiness entry with a malformed `**Result:**` line is read as open in Error Handling and counts toward nothing under Fields read; the two rules differ on whether it consumes a pass slot ← 1/3: r2:M1
- [M5] fixed — the RELEASE-NOTES 7.14.0 entry said a missing sweep can never end a sequence where the skill says settle → 5f01e60 ← 1/3: r3:M1
- [M6] carried — the `Owed:` block requires each item to name both sides, which a `rejected: not a conflict` item cannot do ← 1/3: r3:M2
- [M7] carried — docs/guide/README.md:248 and the phase table read as though both readiness sequences run at N = 0, while the post-sequence runs only at N >= 1 ← 1/3: r3:M4

## Round 6 — Adversarial red-team — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 6 Important, 3 Minor | r2: 0 Critical, 3 Important, 2 Minor | r3: 0 Critical, 4 Important, 4 Minor
**Sources mapped:** 22/22
**Reviewer verdict:** 0 Critical, 8 Important, 6 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the plan interrupted test and the plan completeness rule were no longer exhaustive, so an entry resumed under a lower N matched neither; the completeness rule now carries the same "however its rotating rounds ended" clause and the two tests are exact complements → c082204 ← 3/3: r1:I1, r2:I2, r3:I2
- [I2] fixed — the `<k>` numbering rule lived only on the controller side, so the reviewer was validated against a definition it never received; the 1-based position rule and the one-line-per-position requirement now sit in the check (5) paragraph of the lens cell → c082204 ← 3/3: r1:I3, r2:I1, r3:I3
- [I3] fixed — an owed readiness conflict reached nobody on the autonomous path; Phase 2 now records the controller's `readiness owed: <n>` note in its log entry and Phase 5's report lists the readiness owed conflicts beside the harness probes owed, with no new `REVIEW_DONE` token and no new stop → c082204 ← 2/3: r1:I5, r2:M2
- [I4] fixed — the pre/post classification rule read `## Round` heading position across the whole file instead of the entry being read, which turned a redone pre pass and an N = 0 second invocation into post entries that could never complete; the rule is now scoped to this invocation entry → c082204 ← 2/3: r1:I6, r3:I1
- [I5] fixed — recomputing the cap on every read could reopen a sequence after the host self-review had run, leaving a stale `plan-blob`; a resume that reopens an ended sequence must now re-run the self-review and rewrite the hash → c082204 ← 1/3: r1:I2
- [I6] fixed — a `**Global Constraints:**` block holding no top-level list item satisfied the coverage guarantee vacuously; such a block is now treated like no block at all in the clause-removal rule → c082204 ← 1/3: r1:I4
- [I7] fixed — a readiness entry with a malformed `**Result:**` line was read as an open pass by Error Handling and as counting toward nothing by Fields read; the Error Handling bullet is narrowed so the sequence is open without the entry occupying a pass slot → c082204 ← 1/3: r2:I3
- [I8] fixed — the triage was written for two-sided conflicts while check (5) mandates one finding per Global Constraints entry over many sites; the triage now states that such a finding has one fixed side and several plan sides and that `applied` requires every site amended → c082204 ← 1/3: r3:I4
- [M1] fixed — the budget comment's figures were re-measured against the file after the round 6 edits and reflow, which brought it back to the 1079 lines the comment already states, within the 1080 maximum → c082204 ← 3/3: r1:M1, r2:M1, r3:M3
- [M2] carried — tests/review-gates/run-tests.sh:532 labels a new section `15.` while line 237 already uses `15.`, so a failure reported as 15 is ambiguous ← 1/3: r1:M2
- [M3] rejected: harness probe not runnable here — dispatch one throwaway subagent, in a session whose Bash allowlist does not name `git hash-object`, told to run `git hash-object <path>`, and observe whether the call returns or raises a permission prompt — (ambiguous observation) ← 1/3: r1:M3
- [M4] carried — `rejected: not a conflict` is listed in the `Owed:` block although it names no verified conflict, on the same reasoning that excludes `out of lens scope` ← 1/3: r3:M1
- [M5] carried — the clause-removal note is ordered onto every readiness entry of the invocation although the structure it depends on can appear or disappear between passes ← 1/3: r3:M2
- [M6] carried — docs/guide/README.md:248-249 describes a pass as repeated until it changes nothing and omits the second settling condition, that every reviewer of the pass returned a usable report ← 1/3: r3:M4

## Round 7 — Security — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no
### Dispositions
- [M1] carried — the Phase 2 controller's new Bash grant is stated twice in one sentence, once by open reference to the commands the skill's procedure names and once as a closed enumeration of `git hash-object`; nothing pins the skill side, so a later second command would widen an unattended agent's shell permission with the suite still green ← 2/3: r1:M1, r3:M1
- [M2] carried — the plan path is interpolated into `git hash-object "<plan path>"` at five sites and double quotes stop word splitting and globbing but not command substitution; no rule validates the path or refuses one holding a backtick or `$(` ← 1/3: r2:M1
- [M3] carried — the readiness triage now requires both sides quoted verbatim into a committed log and into the Phase 5 report, while skills/multi-doc-review/reviewer-prompt.md carries no rule against reproducing a credential, unlike its multi-code-review sibling ← 1/3: r2:M2
- [M4] carried — Triage Step 1 takes the spec path from the `**Spec:**` line of the document under review rather than from the `[SPEC_PATH]` the controller was dispatched with, and nothing requires the two to agree or keeps the path inside the repository ← 1/3: r2:M3
