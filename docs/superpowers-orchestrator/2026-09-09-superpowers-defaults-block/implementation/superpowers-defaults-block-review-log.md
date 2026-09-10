# Review log — superpowers-defaults-block

_Invocation 1 — 2026-09-09 — N=4 M=4 — BASE..HEAD f33ca91..8d3aa90 — branch feature/superpowers-defaults-block — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 4 Minor | r2: 0 Critical, 1 Important, 3 Minor | r3: 0 Critical, 1 Important, 2 Minor | r4: 0 Critical, 2 Important, 4 Minor
**Sources mapped:** 20/20
**Reviewer verdict:** 0 Critical, 5 Important, 10 Minor
**Converged:** no
### Dispositions
- [I1] fixed — README's three block-carried entries claimed the value is "always" the default on Codex and OpenCode, contradicting the branch's own tier-1 rule → dc1eef2 ← 3/4: r2:I1, r3:I1, r4:I2
- [I2] fixed — the platform clause said the default applies "unconditionally" at nine sites in four gate skills, which discards a value the user stated → dc1eef2 ← 2/4: r1:I1, r4:M3
- [I3] fixed — the sdd invocation step restated the resolution rule with no antecedent, inviting re-resolution of N and M already answered at the gate → dc1eef2 ← 1/4: r1:I2
- [I4] fixed — the release entry claimed as fact that Cursor emits and reads the block, while README and guide call Cursor unverified → dc1eef2 ← 1/4: r1:I3
- [I5] fixed — multi-doc-review's N entry restated one of the four parts Global Constraint 8 requires, while its M entry restated all four → dc1eef2 ← 1/4: r4:I1
- [M1] fixed — orchestrating-development's Phase 0 citation was singular for four values and named only the invocation as tier 1 → dc1eef2 ← 2/4: r2:M3, r4:M4
- [M2] fixed — README's positional claim about a planted block was unscoped, dropping the injection-scoping distinction → dc1eef2 ← 2/4: r3:M1, r4:M2
- [M3] carried — docs/guide/README.md:174-179 names the batch cap at the spec gate, where it plays no part ← 1/4: r1:M1
- [M4] carried — multi-code-review's platform clause names Codex, a platform this skill refuses to run on ← 1/4: r1:M2
- [M5] carried — the hook unit test exercises only the Claude Code output branch, never the Cursor additional_context branch ← 1/4: r1:M3
- [M6] fixed — the release entry described the removed behaviour in the present tense ("fall back") → dc1eef2 ← 1/4: r1:M4
- [M7] carried — the guide uses the term "block" three times without ever naming `<superpowers-defaults>` ← 1/4: r2:M1
- [M8] carried — the sdd Batch End handoff names only one source for a stated X, unlike its two sibling passages ← 1/4: r2:M2
- [M9] fixed — the sdd batched-mode exception excluded `<d-m>` by name but not `<d-n>` → dc1eef2 ← 1/4: r3:M2
- [M10] carried — the decoy pre-check in the hook unit test is satisfied by the hook's own closing delimiter ← 1/4: r4:M1
- [CF1] fixed — multi-doc-review's `### The block` parenthetical read as a competing selection rule against the session-wide tool-result rule → dc1eef2
- [CF2] fixed — the hook unit test's comment cited a test file this branch deletes → dc1eef2
- [CF3] fixed — "the table above" was ambiguous with two tables preceding it → dc1eef2
- [CF4] fixed — the tier-1 validity table named one value with two undefined phrases → dc1eef2
- [CF5] fixed — the four-form M list had no form for a review-log line carrying no `M=` token → dc1eef2
- [CF6] carried — the hook unit test's command substitution strips trailing newlines; coverage gap only
- [CF7] carried — docs/FORK-IMPROVEMENTS.md:133,176 stale inventories; already fixed by Task 10 on this branch
- [CF8] carried — tests/review-gates/run-tests.sh:377 defines skill_rel_guard at its call site rather than in the helpers block
- [CF9] carried — tests/review-gates/run-tests.sh:339-347 re-normalizes three files that already have normalized copies
- [CF10] carried — tests/review-gates/run-tests.sh section 2c has no `checked -gt 0` vacuous-pass guard of its own
- [CF11] carried — multi-doc-review:72-75 says "silently" where it means "without asking"
- [CF12] carried — multi-doc-review:36-38 describes an impossible alternative
- [CF13] carried — multi-doc-review:72 drops the "if valid" qualifier resolution item 1 carries
- [CF14] carried — multi-doc-review:172 names only the invocation, while the tier-1 table lists two entry points
- [CF15] carried — multi-doc-review uses `<d-n>` at :36 and :713 before its definition at :106
- [CF16] carried — multi-doc-review:713 "Invalid N → `<d-n>`" is mildly circular
- [CF17] carried — multi-doc-review:170-174 states the platform restriction three times
- [CF18] carried — multi-doc-review:72-78 ragged line wrapping
- [CF19] carried — multi-code-review:96-98 omits ", if valid" from the N restatement's tier 2
- [CF20] carried — multi-code-review:1713 carries no pointer to where `<d-n>` is defined
- [CF21] carried — multi-code-review:80-82 names the section before the citation says which file holds it
- [CF22] carried — multi-code-review:127-128 drops "whatever its position" from the M restatement
- [CF23] carried — multi-code-review states the tool-result rule twice per parameter, as Global Constraint 8 requires; noted for later editors
- [CF24] carried — brainstorming uses "tier 2" and "tier 3" without defining them in that file
- [CF25] carried — brainstorming:114-115 vs :109-111 use two different choose-one shapes in one paragraph
- [CF26] carried — brainstorming:138-139 forward reference created by the brief's verbatim body
- [CF27] carried — brainstorming:156 restates the fallback already given at :152
- [CF28] carried — brainstorming's out-of-range-answer messages name the replacement value but not the tier that supplied it
- [CF29] carried — brainstorming:78-83 reconciling sentence lists only the tier-2 and tier-3 forms
- [CF30] carried — brainstorming:141-142 names the section but not its file
- [CF31] carried — brainstorming:121 "Here `<d-n>` and `<d-m>` name …" could read as scoped to the preceding sentence; byte-shared with writing-plans
- [CF32] carried — writing-plans:363-367 and brainstorming:78-84 plan-mandated ordering weakness
- [CF33] carried — writing-plans:385 is the only line in its range above the file's wrapping convention
- [CF34] carried — writing-plans:387,431 short remainder lines left by an earlier commit's splices
- [CF35] carried — writing-plans:422-429 N definition carries no validity fallback sentence, while the M definition does
- [CF36] carried — commits 89dbf61 and 30c5744 share one subject line
- [CF37] carried — the sdd step 4 N sentence is a forward reference with no antecedent in that file
- [CF38] user-decision — the sdd step 2 batched-mode exception and step 7 plan-complete paragraphs restate the fallback chain without the tool-result rule or the platform clause, unlike the five sites that cite `Resolving a default` by name; neither carries the citing phrase, so Global Constraint 8 arguably does not reach them — at skills/subagent-driven-development/SKILL.md:81 — clause: Global Constraints "**The citation does not stand alone.** Each citing site restates, in its own words: the three tiers; the injection-scoping rule (which block counts); the tool-r"
- [CF39] carried — docs/guide/README.md:176-178 uses "the batch cap" with a definite article before the term is glossed
- [CF40] carried — the README `SP_NO_COMPRESS` trailing parenthetical is verbatim from the plan's Task 10 Step 2 reference body; kept so a later editor does not delete it
- [CF41] carried — the task-11 review package carried no commit-trailer evidence; a tooling observation about scripts/review-package

## Round 2 — Adversarial red-team — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 6 Minor | r2: 0 Critical, 2 Important, 2 Minor | r3: 0 Critical, 1 Important, 3 Minor | r4: 0 Critical, 2 Important, 3 Minor
**Sources mapped:** 20/20
**Reviewer verdict:** 0 Critical, 3 Important, 11 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the N option list emitted the zero option twice, first and last, and labelled the leading zero "session default" whenever the offered value resolved to 0 → bd33b79 ← 4/4: r1:I1, r2:I1, r3:I1, r4:I1
- [I2] fixed — the tier-1 validity table said "falls to the parameter's default" in some rows and "falls to tier 2" in others, making the same invalid input resolve to two different depths → bd33b79 ← 1/4: r2:I2
- [I3] fixed — the session-wide tool-result rule's excluded-origins list omitted automatically injected instruction and memory files (CLAUDE.md, AGENTS.md, another SessionStart hook's output) → bd33b79 — (harness field dropped: repository-readable) ← 1/4: r4:I2
- [M1] fixed — "X = 0 is an explicit stop" named an input case no step of Batched Autonomous Mode implemented; the boundary was evaluated only after a task had run → bd33b79 ← 3/4: r1:M3, r3:M1, r4:M1
- [M2] fixed — the hook unit test's decoy completeness guard was satisfied by the hook's own closing delimiter, so it could never fail for the reason its message stated → bd33b79 ← 2/4: r1:M2, r2:M1
- [M3] carried — the hook unit test's decoy fixture writes a complete block as literal physical lines in a tracked file; the plan's File Structure records this as deliberate ← 1/4: r1:M1
- [M4] fixed — multi-code-review's batched-mode sentence listed `<d-n>` before the stated count, inverting tier-1 precedence → bd33b79 ← 1/4: r1:M4
- [M5] fixed — the Phase 0 paragraph computed the offered default from the answer the question had not yet received → bd33b79 ← 1/4: r1:M5
- [M6] fixed — the guide showed the old resume-prompt shape at four sites, which drops every stated value at the batch boundary → bd33b79 ← 1/4: r1:M6
- [M7] carried — the offered-default label calls any value above the hardcoded default "recommended", so a stale high `SUPERPOWERS_REVIEW_ROUNDS` is presented as project advice; changing it is a design decision beyond this plan ← 1/4: r2:M2
- [M8] fixed — docs/FORK-IMPROVEMENTS.md:123 and README.md:30 still stated the superseded "falls back to 3" rule → bd33b79 ← 1/4: r3:M2
- [M9] fixed — "reproduces the historical list exactly" was untrue of the labels, which changed deliberately → bd33b79 ← 1/4: r3:M3
- [M10] rejected: Global Constraint 7 pins the citation sentence verbatim, including its repository-relative path, so the loop cannot change it — the citation names a repository-relative path that does not resolve from the plugin cache ← 1/4: r4:M2
- [M11] fixed — the handoff paragraph used the symbol N for both the completed-task count and the review round count → bd33b79 ← 1/4: r4:M3

## Round 3 — Security — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 2 Important, 1 Minor | r3: 0 Critical, 1 Important, 2 Minor | r4: 0 Critical, 2 Important, 1 Minor
**Sources mapped:** 12/12
**Reviewer verdict:** 0 Critical, 5 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] fixed — a resume-carried N, especially N=0, is a tier-1 value that is never echoed and reaches the session through state.md as well as through the pasted prompt, so a batch run could finish with no whole-branch review and no message → f0d26b2 ← 2/4: r1:I1, r4:I2
- [I2] fixed — the hook unit test's decoy fixture stored a literal complete block in a tracked file, the exact payload the design defends against → f0d26b2 ← 1/4: r2:I1
- [I3] fixed — the stated-value anti-injection property's origin list omitted automatically injected content, while the block property already covered it → f0d26b2 ← 1/4: r2:I2
- [I4] fixed — the platform clause did not say that the Codex adapter embeds repository workspace files and emits no block, so on that platform the clause is the only protection; the structural half of the reviewer's fix was not applied because Global Constraint 12 binds the Codex path unchanged → f0d26b2 ← 1/4: r3:I1
- [I5] fixed — the `X=<x>` token was missing from the stated-value enumeration, and the batch path neutralized only a block, not a stated cap token → f0d26b2 ← 1/4: r4:I1
- [M1] fixed — the review-gates complete-block guard globbed only `skills/*/SKILL.md`, leaving the prompt templates unchecked → f0d26b2 ← 3/4: r1:M2, r2:M1, r3:M1
- [M2] fixed — a carried task cap persisted across every later resume with no message → f0d26b2 ← 1/4: r1:M1
- [M3] fixed — the review-log carve-out granted tier-1 authority to a committed file without naming the bounds that make it safe → f0d26b2 ← 1/4: r3:M2
- [M4] fixed — the pasted resume prompt was an unnamed exception to the quoted-or-pasted-material rule → f0d26b2 ← 1/4: r4:M1

## Round 4 — Test & coverage quality — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 2 Minor | r2: 0 Critical, 1 Important, 4 Minor | r3: 0 Critical, 2 Important, 2 Minor | r4: 0 Critical, 2 Important, 3 Minor
**Sources mapped:** 19/19
**Reviewer verdict:** 0 Critical, 5 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the review-gates helper labelled every section 2c result line `SKILL.md`, so 17 of 45 files were never named and a real failure would point at a clean file → ee92045 ← 4/4: r1:I1, r2:M1, r3:I1, r4:M1
- [I2] user-decision — the reader half of the change has no executable evidence: no committed test sets one of the three variables and asserts a skill resolves it at tier 2, so a skill edit that dropped the block-reading tier would leave every suite green (plan-mandated) — at tests/claude-code/test-multi-doc-review.sh:53 — clause: Task 9 "**Contract:** `check_no_superpowers_defaults_setting` (renamed from `check_no_reviewers_per_lens_setting` by Step 1) in `tests/claude-code/test-helpers.sh`" ← 4/4: r1:I2, r2:M4, r3:M1, r4:I1
- [I3] fixed — the complete-block guard covered `skills/` only, leaving the documentation half of Global Constraint 2 with no regression guard → ee92045 ← 3/4: r2:M2, r3:I2, r4:M3
- [I4] fixed — the suite pinned the citation sentence and the scoping phrase but neither the tool-result rule nor the platform clause, the two parts that carry the injection defence → ee92045 ← 2/4: r1:I3, r4:I2
- [I5] fixed — `10` was never asserted rejected for the two 1-5 parameters, the value a copied ten-alternative list would wrongly accept → ee92045 ← 2/4: r1:M1, r2:I1
- [M1] fixed — no test asserted that the Codex adapter emits no block, although the skills and README rely on that claim → ee92045 ← 1/4: r1:M2
- [M2] fixed — nothing pinned the parameter table's content against the hook, although Global Constraint 3 makes that table the single source for tier 3 → ee92045 ← 1/4: r2:M3
- [M3] fixed — the widened environment guard both behavioural suites depend on had no test of its own → ee92045 ← 1/4: r3:M2
- [M4] fixed — the "block comes after every embedded workspace file" property was exercised for state.md alone → ee92045 ← 1/4: r4:M2

## Round 4 verification 1 — Test & coverage quality — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 3 Minor | r2: 0 Critical, 1 Important, 4 Minor | r3: 0 Critical, 1 Important, 4 Minor | r4: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 20/20
**Reviewer verdict:** 0 Critical, 2 Important, 10 Minor
### Dispositions
- [I1] fixed — the guard unit test added in round 4 was not hermetic: it called the helper with the real HOME, so on a machine configured the documented way the fast unit suite went red for an environment reason and the fixture path was never exercised → 7b5c8dc ← 3/4: r1:I1, r2:I1, r3:I1
- [I2] rejected: duplicate of round 4 [I2], already logged user-decision — the reader half of the change still has no end-to-end test ← 3/4: r1:I2, r2:M4, r4:I1
- [M1] fixed — section 2d guarded a hardcoded four-file list while the constraint covers every documentation file and the plan itself → 7b5c8dc ← 4/4: r1:M1, r2:M2, r3:M1, r4:M1
- [M2] carried — the per-file marker and placeholder assertions require one occurrence, so an edit that stripped all but one site stays green; the plan refuses to pin counts, and a floor is a count ← 2/4: r1:M2, r2:M3
- [M3] fixed — every assertion was a suffix match, so a duplicated block would pass all of them → 7b5c8dc ← 1/4: r1:M3
- [M4] fixed — nothing pinned the block's delimiter name in the normative skill, so a rename there alone would silently disable tier 2 → 7b5c8dc ← 1/4: r2:M1
- [M5] fixed — the defining file was not asserted for the tool-result rule or the platform clause, only the five citing files were → 7b5c8dc ← 1/4: r3:M2
- [M6] carried — no assertion pins the three-label rule or the N option-list worked example ← 1/4: r3:M3
- [M7] carried — no assertion covers the resume-prompt token shape or the two batch-cap origin sentences ← 1/4: r3:M4
- [M8] fixed — the guard test exercised one of the eight settings paths and had no clean case → 7b5c8dc ← 1/4: r4:M2
- [M9] fixed — the adapter's delimiter-absence assertion passed on an empty context → 7b5c8dc ← 1/4: r4:M3
- [M10] fixed — trailing-space and tab-padded rejected forms were not covered → 7b5c8dc ← 1/4: r4:M4

## Round 4 verification 2 — Test & coverage quality — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 6 Minor | r2: 0 Critical, 2 Important, 4 Minor | r3: 0 Critical, 1 Important, 5 Minor | r4: 0 Critical, 1 Important, 6 Minor
**Sources mapped:** 26/26
**Reviewer verdict:** 0 Critical, 3 Important, 12 Minor
### Dispositions
- [I1] fixed — the documentation guard added in cycle 1 scanned untracked workspace files and generated review sidecars, so the suite could go red on content outside the branch and contradicted the hook test's own decoy fixture → e919eb1 ← 4/4: r1:M5, r2:I1, r3:M3, r4:I1
- [I2] rejected: duplicate of round 4 [I2], already logged user-decision — no test exercises tier-2 resolution end to end ← 3/4: r1:I1, r2:I2, r4:M6
- [I3] fixed — the tool-result marker added in round 4 already existed in all six files at BASE, so that assertion could never fail → e919eb1 ← 2/4: r1:M2, r3:I1
- [M1] fixed — the count assertion added in cycle 1 aborted the whole suite under `set -euo pipefail` in exactly the absent-block case it was written for → e919eb1 ← 4/4: r1:M1, r2:M1, r3:M2, r4:M3
- [M2] fixed — the guard test's only clean case had no settings file at all, so the helper's pattern was never exercised in the passing direction → e919eb1 ← 3/4: r2:M2, r3:M5, r4:M2
- [M3] fixed — the Case 2 comment described a tier-3 fallback that no longer occurs on Claude Code → e919eb1 ← 1/4: r1:M3
- [M4] fixed — the enterprise-settings skip silenced the whole file and reported it as a passing suite → e919eb1 ← 1/4: r1:M4
- [M5] fixed — the exactly-once count spanned the whole context, so an opening-only mention in the one embedded skill body would have failed it → e919eb1 ← 1/4: r1:M6
- [M6] carried — the adapter test's title claims more than it checks: a block planted in a workspace file still passes through on Codex, which is the documented and plan-bound behaviour ← 1/4: r2:M3
- [M7] carried — the citation assertion matches once per file, not once per resolving site; the plan refuses to pin counts ← 1/4: r2:M4
- [M8] carried — the three offered-default labels and the two echo sentences carry no byte pin ← 1/4: r3:M1
- [M9] fixed — section 2b's absence checks used a narrower glob than section 2c → e919eb1 ← 1/4: r3:M4
- [M10] fixed — per-file PASS lines made the suite total depend on how many Markdown files exist at run time, breaking the plan's total-comparison check → e919eb1 ← 1/4: r4:M1
- [M11] fixed — `agents/*.md` and the two `INSTALL.md` files were outside every complete-block guard; the tracked-file list of [I1] covers them → e919eb1 ← 1/4: r4:M4
- [M12] fixed — roughly 230 per-file PASS lines buried the wording assertions the suite exists to protect → e919eb1 ← 1/4: r4:M5

## Round 4 verification 3 — Test & coverage quality — opus
**Reviewers:** M=4, usable 4/4
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 4 Minor | r2: 0 Critical, 2 Important, 4 Minor | r3: 0 Critical, 0 Important, 5 Minor | r4: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 19/19
**Reviewer verdict:** 0 Critical, 3 Important, 11 Minor
### Dispositions
- [I1] rejected: duplicate of round 4 [I2], already logged user-decision — no test exercises tier-2 resolution end to end ← 3/4: r1:M3, r2:I1, r3:M4
- [I2] unresolved: verification cap — the removed anti-drift assertion pinned a byte-identical span carrying M's hardcoded default, and the four fragment markers that replaced it carry no number, while the branch grows the restated hardcoded defaults to fourteen sites across six files; only the normative table is pinned, so thirteen literals can go stale with every suite green — at tests/review-gates/run-tests.sh:366 — clause: Global Constraints "**The parameter table is the single source for tier 3.** `SUPERPOWERS_REVIEWERS_PER_LENS` → block line `reviewers-per-lens`, accepted `1` `2` `3` `4` `5`, hardc" ← 1/4: r1:I1
- [I3] unresolved: verification cap — the echo requirement has no pin in the suite that exists to pin exactly this kind of wording, although the echo sentence is a fixed literal written into six files and is the only mechanism that makes a setting made once and then forgotten visible to the user — at tests/review-gates/run-tests.sh:330 — clause: Global Constraints "**Every path that resolves a parameter at tier 2 without asking must echo the resolved value and its source,** in its opening or completion message. This is req" ← 1/4: r2:I2
- [M1] carried — the hook test runs only the Claude Code output branch; the Cursor and no-plugin-root branches are never exercised ← 2/4: r1:M4, r3:M3
- [M2] carried — `<d-m>` and `<d-cap>` are pinned where they are used but not in the file that defines them ← 2/4: r2:M3, r3:M1
- [M3] carried — the decoy ordering cases cover four of the five sources the hook embeds; `context-snapshot.json` is uncovered ← 2/4: r3:M5, r4:M3
- [M4] carried — the two absolute enterprise settings paths are never exercised by any case of the guard test ← 1/4: r1:M1
- [M5] carried — the placeholder presence checks are whole-file, while their comment claims they catch a literal written at named line numbers ← 1/4: r1:M2
- [M6] carried — the Case 2 comment now names a tier the assertions still cannot distinguish, because both tiers yield the same value ← 1/4: r2:M1
- [M7] carried — the parameter-table pins read only the skill file, so the cross-file guarantee their comment states does not exist ← 1/4: r2:M2
- [M8] carried — the three offered-default labels and the batch-cap direction sentence carry no byte pin ← 1/4: r2:M4
- [M9] carried — the adapter test's title claims coverage of the planted-block case, which no unit test can reach ← 1/4: r3:M2
- [M10] carried — the file guards use `[ -f ]` where the message says "not readable"; an unreadable file is counted as examined ← 1/4: r4:M1
- [M11] carried — no negative assertion guards the wording Global Constraint 9 forbids ("the last complete block in the context") ← 1/4: r4:M2

_Completed — 2026-09-10 — cap reached — HEAD e919eb1017f66afaac45aa7405b9a15d69190bf3_
Secrets found: none

### Post-loop addendum — 2026-09-10 — decisions on invocation 1's open items
- [CF38] decided (orchestrator): plan governs: "**The citation does not stand alone.** Each citing site restates, in its own words: the three tiers; the injection-scoping rule (which block counts); the tool-r" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/plans/superpowers-defaults-block.md. Global Constraint 8 binds citing sites, and the finding establishes that these two paragraphs cite nothing; adding the four parts there would multiply the copied wording blocks this design exists to remove.
- [I2] decided (orchestrator): plan governs: (this answers the round 4 user-decision item on the missing end-to-end tier-2 test) "No test file *sets* `SUPERPOWERS_REVIEWERS_PER_LENS` or asserts the session tag, so there is no such code to update. The work is exactly two edits" — docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/specs/superpowers-defaults-block-design.md. The design fixes the behavioral test work at two edits, so an end-to-end tier-2 test is outside the testing strategy this run implements.
- [I2] decided (orchestrator): accept: (this answers the verification-cycle-3 unresolved item on the unpinned hardcoded-default literals) the design orders the old anti-drift block removed and then states exactly what replaces it, closing with "that is the asserted contract", so the coverage change is a choice the design made deliberately; the gap is real and is reported at Phase 5 to be raised as its own change.
- [I3] decided (orchestrator): accept: (this answers the verification-cycle-3 unresolved item on the unpinned tier-2 echo sentence) Global Constraint 11 binds the skills' behaviour, not the test suite, and the design fixes what the wording suite asserts; adding this pin grows the suite beyond the stated contract, so it belongs to a later change and is reported at Phase 5.

Open items after this addendum: unresolved 0, user-decision 0. Every item was decided without a code change, so no fix subagent ran and no verification re-review followed. The effective HEAD was computed before this addendum was written and is unchanged — e919eb1017f66afaac45aa7405b9a15d69190bf3, the same commit invocation 1's completion marker already records — so that marker stands as written and no new invocation entry follows.
