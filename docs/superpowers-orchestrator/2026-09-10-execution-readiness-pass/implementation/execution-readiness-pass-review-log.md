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
