# Marker position tolerance — design review log

_Invocation 1 — 2026-09-06 — N=2 M=1 — direct_

## Round 1 — Correctness & completeness — claude-opus-5[1m]
**Reviewer verdict:** 1 Critical, 7 Important, 7 Minor
**Converged:** no

### Dispositions
- [C1] applied — Testing strategy: the file pins the same strictness for the other two markers (`:269`, `:383`), so "existing cases keep passing" was false → verified all three assertion names by grep; all three are now listed as replaced, and item 8 says "the remaining … cases"
- [I1] applied — Scope 1 vs Interfaces 2: off-by-one ("at most 10 lines above" vs "among the first 10") → Scope 1 now reads "one of the first 10 lines (at most 9 lines above it, blank lines counted)"
- [I2] applied — "Why 10 lines": the derivation was false (length is not a malformed condition; the cap would give 14) → the section now states 10 as a judgement call with the recorded occurrences as its evidence, and drops the cap-makes-it-malformed claim
- [I3] applied — Error handling table merged the hook and orchestrator outcomes and hid the hang → the table now has one column per side, and the not-exempt rows say the hook may block and hang the dispatch
- [I4] applied — Non-goals claimed the retry "never runs" → reworded to the marker-within-10 case, with the residual risk (preamble ≥ 10 lines, or no marker) stated as a run-ending path the design does not close
- [I5] applied — the hook's own comments state the old rule three times (`:60`, `:67`, `:74`, verified) → rewriting them is now part of Scope 2 and of the guard-predicate interface
- [I6] applied — four other passages state the hook rule as "opening with" (`multi-doc-review:502`, `multi-code-review:1860`, `researching-prior-art:427` and `:611`, all verified) → Scope 3 now covers all five sites, and Acceptance 5 checks that none survives
- [I7] applied — no rule for two marker lines inside the window → the first such line begins the report; added to Interfaces 3, the diagram, the error table and the test list
- [M1] applied — "first non-empty line below the marker" is a second loosening → moved into Scope 1 and the wording assertion
- [M2] applied — `tests/orchestrating-development` was both "one of the seven unchanged" and "one that can move" → now "the six other than the two that can move", matching Acceptance 3
- [M3] applied — `tests/in-run-rulings/run-tests.sh:793-811` ranges on the Guard Interaction headings (verified) → Scope 3 carries the constraint, and the regression paragraph names it as the suite most likely to break
- [M4] applied — the line budget is not what stops a quoted marker → "Why 10 lines" now names whole-line equality as the protection, with the budget secondary
- [M5] applied — templates keep a whole-message 15-line cap while the receiver counts from the marker → the divergence is stated in Non-goals as accepted
- [M6] applied — the Problem section values the preamble, the design discards it → one sentence: it stays in the dispatch's session transcript; the orchestrator consumes only the contract fields
- [M7] applied — `docs/FORK-IMPROVEMENTS.md:203` (verified) → folded into Scope 3 rather than left to the release step

## Round 2 — Ambiguity & testability — claude-opus-5[1m]
**Reviewer verdict:** 0 Critical, 5 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — whole-line equality inside a raw 10-line window is a NARROWING of today's `trimStart().startsWith` in two cases (marker plus text on line 1; more than 10 leading blank lines), while the document claimed the exemption "may only ever widen" → the hook predicate is now a line-start PREFIX match over the first 10 NON-BLANK lines, a strict superset of today; the orchestrator keeps whole-line equality over the same window, also a strict superset of its own current rule; both properties are stated in Architecture with the third: hook-exempt is a superset of orchestrator-accepted
- [I2] applied — undefined which marker the orchestrator searches for; a code-review-loop controller can quote `<!-- multi-review report -->` above its own marker → the orchestrator searches only `<!-- orchestration report -->`; other markers are ordinary preamble. New section "Why the orchestrator searches only its own marker", new error-table row
- [I3] applied — the cap left two questions open and "hard cap" implied a receiver-side test → the marker line is line 1 of the 15, and exceeding the cap is explicitly NOT a malformed condition (the malformed list is closed today too, verified at `SKILL.md:164-168`); error-table row added
- [I4] applied — the count said five and the list held six, and a seventh passage exists at `SKILL.md:1404-1406` inside `## In-run rulings` (verified) → Scope 3 now lists seven; the neighbouring lost-return rule at `:1411-1413` keys on the marker's presence, not its position, and is placed in Non-goals as untouched
- [I5] applied — the "hang the dispatch" premise carried no observation, and `SKILL.md:1404-1406` says the opposite ("the fork spends another turn rewriting") — harness probe: one throwaway subagent whose final message named a skill after an action verb and carried no marker was dispatched; it returned in about 6 seconds with `blocked once, then resumed; the dispatch continued after one extra turn` → the Problem section now states the measured cost (one extra turn plus a redo instruction a controller may act on by repeating committed work), and correcting the Guard Interaction "hang" wording is part of Scope 3
- [M1] applied — Acceptance items 4 and 5 were not executable → merged into one item carrying a `grep -rn` command over `skills/ hooks/ docs/FORK-IMPROVEMENTS.md` with its expected result; the side-by-side reading is replaced by the wording assertion of item 2
- [M2] applied — an unusable reviewer report gets one identical retry before `inconclusive` (verified at `multi-code-review/SKILL.md:602-607`) → the sentence now names the retry step
- [M3] applied — the wording assertion named no fragment and could pass vacuously on the number 10 → it must pin both the tolerance fragment (window size and "non-blank") and the exact marker spelling; the plan names the two fragments
- [M4] applied — "Codex has no `SubagentStop` event" is an external-platform claim with no citation → cited to `CLAUDE.md`'s hook-parity constraint; the grep evidence is kept for the registration claim only

**Post-loop self-review (direct invocation: placeholder scan, internal consistency, ambiguity, scope).**
- Placeholder scan: no TBD, no unfilled bracket, no "add appropriate".
- Internal consistency: the window ("first 10 non-blank lines") is stated
  identically in Scope 1 and 2, the Architecture diagram, both Interfaces
  sections, the error table and the test list; the two predicates (prefix for
  the hook, equality for the orchestrator) are distinguished in every place
  both appear.
- Ambiguity: the three questions round 2 raised — which marker, which
  occurrence, what the cap does — are each answered in one sentence.
- Scope: seven documentation sites, two code sites, two test files; the
  release step is listed separately and touches no behaviour.

_Invocation 1 complete — 2 rounds run (1C/7I/7M, then 0C/5I/4M), cap reached, not converged. Effective M=1. Harness probes owed: none._
