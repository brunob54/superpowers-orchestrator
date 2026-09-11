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
