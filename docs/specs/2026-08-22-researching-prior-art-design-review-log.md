_Invocation 1 — 2026-08-22 — N=5 — gate: brainstorming_

## Round 1 — Correctness & completeness — session model
**Reviewer verdict:** 2 Critical, 4 Important, 4 Minor
**Converged:** no

### Dispositions
- [C1] applied — dirty-tree check redefined as pre-dispatch `git status --porcelain` snapshot + allowlist (`docs/research/`, `.superpowers/research/`); happy path no longer triggers the stop (Global Constraints, flow step 8, Brainstorming integration, Error Handling)
- [C2] applied — read-only rule gains exactly one carve-out: the researcher may write its own `[REPORT_FILE]` via one shell redirect (Global Constraints, Researcher contract)
- [I1] applied — version anchor defined for not-yet-added candidates: latest stable release at research time, named explicitly (Researcher contract)
- [I2] applied — sub-skill creates `.superpowers/research/` with a self-`.gitignore` containing `*` before dispatch, the multi-code-review pattern (flow step 3, Files table)
- [I3] applied — cache keyed by `<candidate-slug>` (kebab-case candidate name), defined for library and non-library candidates alike (Files table, Cache contract, Controller contract)
- [I4] applied — cache/N interaction specified: fresh cache subtracts candidate and reduces N with reported reduction; all-cached dispatches nothing; stale re-verification runs inside the reduced dispatch; version drift invalidates the entry and re-enters the candidate (Cache contract)
- [M1] applied — N formula documented as intentional: at suggested N, angle 5 merges into each candidate's angle-1 assignment (Normative Wordings)
- [M2] applied — marker explicitly required on the controller's summary message too (Normative Wordings, Controller contract)
- [M3] applied — spec section gains the category "research attempted, failed — evidence gap" covering Error Handling outcomes (Brainstorming integration)
- [M4] applied — "difficult to reverse" given concrete tests: public interface, stored data format/schema, or wire protocol others will depend on (Normative Wordings)

## Round 2 — Ambiguity & testability — session model
**Reviewer verdict:** 1 Critical, 6 Important, 5 Minor
**Converged:** no

### Dispositions
- [C1] applied — full-cache-hit path now synthesizes the merged report file from cache entries, so the file-existence check holds uniformly (Cache contract)
- [I1] applied — deterministic ordered assignment list as a function of C, with enumerated merge (fold bottom-up, pair candidates) and split (angle 5 out, angle 3 halves, angle 4 halves) rules; N clamped to 0-10 (Assignments)
- [I2] applied — cached candidate saves exactly its per-candidate assignment (N-1 each); shared-angle researchers exclude cached candidates (Cache contract)
- [I3] applied — stale re-verification sequenced: re-verifier in first wave; on version drift the controller dispatches one follow-up researcher after the wave, same invocation, no user interaction, overshoot bounded and reported (Cache contract)
- [I4] applied — "version-sensitive external API behavior" defined (behavior changed or documented to change across released versions); intake check restated as the same predicate, both branches (Normative Wordings, Spec-side enforcement)
- [I5] applied — time budget restated as a prompt-level instruction; blocking dispatches; missing/unusable report on return → evidence gap; no timer mechanism (Controller contract)
- [I6] applied — spot-fetch semantics split: transient failure → retry once then evidence gap; snippet mismatch → downgrade only the claims backed by that citation (Controller contract)
- [M1] applied — slug rule with scoped-package example: @tanstack/react-query → tanstack-react-query (Cache contract)
- [M2] applied — rung detection: Claude Code = rung 1; controller unable to dispatch → fall to rung 2 (Degradation ladder)
- [M3] applied — controller timeout detection = Agent dispatch error or platform timeout, no additional timer (Error Handling)
- [M4] applied — [MODEL] tiers rephrased: Haiku-class only for split-out existence check and cache re-verification (Researcher contract)
- [M5] applied — integration-test "verbatim" defined: fixed lines exact, placeholder lines by pattern, bracketed sentence asserted absent (Testing Strategy)

## Round 3 — Feasibility & architecture risk — session model
**Reviewer verdict:** 0 Critical, 2 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — citation bullet placed in the Ambiguity & testability lens's `spec:` cell, named explicitly; multi-doc-review has four rotating lenses, not one "spec lens" (Spec-side enforcement)
- [I2] applied — brainstorming integration scope extended to amend the Hard Gate (research-artifact carve-out) and the invoked-skills sentence (researching-prior-art permitted mid-flow alongside multi-doc-review) (Scope item 2)
- [M1] applied — README release chore enumerates every count occurrence: three "27 skills" mentions, Skills Library entry, "25 rules covering 24 skills" line (Global Constraints)
- [M2] applied — researching-prior-art also added to subagent-guard's SKILL_NAMES list and `skill:` alternation, per file convention (subagent-guard section)
- [M3] applied — controller rule: all reports missing after an Explore wave → one re-dispatch with general-purpose (product-drift defense) (Controller contract)
- [M4] applied — orchestrator Phase 0 reads the spec body for the intake check; documented as a deliberate thin-sequencer exception (Spec-side enforcement)
- [M5] applied — behavioral test must be registered in run-skill-tests.sh hardcoded arrays plus help text (Testing Strategy)

## Round 4 — Adversarial failure modes — session model
**Reviewer verdict:** 1 Critical, 7 Important, 3 Minor
**Converged:** no

### Dispositions
- [C1] applied — untrusted-content rule extended to the controller and to brainstorming's read step (merged report is data); researchers must describe and flag instruction-like fetched text instead of quoting it verbatim; verbatim snippets restricted to factual evidence (Researcher/Controller contracts, Brainstorming integration)
- [I1] applied — cache slug gains a registry/ecosystem prefix; header stores registry + exact canonical name; hit requires exact match, slug match alone is not a hit (Cache contract)
- [I2] applied — every cache hit, fresh included, gets the Haiku re-verifier; future-dated header treated as invalid (Cache contract)
- [I3] applied — second read-only carve-out: clones into `.superpowers/research/clones/` (self-gitignored, on the allowlist), so not-yet-installed candidates can be read in full (Researcher contract, Global Constraints)
- [I4] applied — honest coverage statement for the porcelain comparison (cannot see already-dirty/untracked files); non-git projects skip the check with a stated skip (Global Constraints, Error Handling)
- [I5] applied — fold completed: after shared-assignment folds, round-robin distribution across exactly N researchers (terminates for N>=1); post-cache N floored at 1 while any candidate un-researched (Assignments, Cache contract)
- [I6] applied — angle 4 is decision-scoped and always dispatched; all-cached runs dispatch re-verifiers + angle 4, never nothing (Cache contract)
- [I7] applied — predicate gains a third branch: selecting an external hosted service, platform, or base image (Normative Wordings)
- [M1] applied — N above the maximum split count: dispatch the maximum, report the difference, never invent assignments (Assignments)
- [M2] applied — unexpected tree change now presents the diff and asks the user instead of halting unconditionally (Global Constraints, Brainstorming integration, Error Handling)
- [M3] applied — spot-fetch scope stated: catches fabricated citations, not fabricated conclusions (Controller contract)

## Round 5 — Correctness & completeness — session model
**Reviewer verdict:** 0 Critical, 5 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — fresh-hit re-verifier mismatch treated identically to stale: entry invalidated, follow-up full-research researcher (Cache contract, re-verifier outcomes)
- [I2] applied — confirmed re-verification specified: cached findings count as evidence, angles 1+5 stay removed, N stays reduced, header date refreshed (Cache contract)
- [I3] applied — all-cached path keeps the controller: dispatched as usual with the reduced set; merged report is always controller-written (Cache contract)
- [I4] applied — predicate scope aligned in all three places: "any branch of the three-branch predicate"; Rollout sentence fixed (Spec-side enforcement, Rollout)
- [I5] applied — re-verifiers are outside N and outside the merge/split algorithm; exceed-N note generalized (Cache contract)
- [M1] applied — controller-prompt.md gains a required-placeholder list; controller agent type stated as general-purpose (Controller contract)
- [M2] applied — carve-out count made consistent: "exactly two carve-outs" in both places (Global Constraints)
- [M3] applied — S = min(C+3, 10); unusable gate reply → re-ask once, then suggested S (Normative Wordings)
- [M4] applied — snapshot and comparison owned by the sub-skill; brainstorming reads the result and asks the user (Global Constraints, flow step 8, Brainstorming integration)
- [M5] applied — split-out OpenSSF-health half explicitly Sonnet-class; rung-3 platforms skip the gate before asking N (Researcher contract, Normative Wordings)

_Loop complete — 5 rounds run, cap reached (round 5 not clean). Post-loop spec self-review: placeholder scan clean, no stale `<library>` references, carve-out counts consistent; no merge-introduced issues found._
