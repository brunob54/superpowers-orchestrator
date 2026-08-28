# Code review log — reviewers-per-lens

_Invocation 1 — 2026-08-28 — N=4 M=1 — BASE..HEAD 526a74c..1e51f15 — branch feature/reviewers-per-lens — gate: orchestration_

_Carried findings source: `.superpowers/sdd/progress.md` `Minor:` lines (14 items), labelled `[K1]`–`[K14]` below._

## Round 1 — Correctness & spec alignment — opus
**Reviewer verdict:** 0 Critical, 0 Important, 8 Minor
**Converged:** no
### Dispositions
- [M1] fixed — multi-code-review SKILL.md "byte-identical" label reworded: round entry byte-identical, invocation line adds `M=<m>` → 3b30e10
- [M2] fixed — multi-code-review SKILL.md N bullet now carries the "every M form is extracted first" guard → 3b30e10
- [M3] fixed — dispatching-parallel-agents reference anchored as `../dispatching-parallel-agents/SKILL.md` in both review skills → 3b30e10
- [M4] fixed — multi-code-review After-the-Loop report list now names the effective M and any substitution → 3b30e10
- [M5] fixed — test-multi-code-review.sh header comment updated for M=2 and assertions (i)/(m) → 3b30e10
- [M6] fixed — `export -f assert_round_reviewers` added in tests/claude-code/test-helpers.sh → 3b30e10
- [M7] fixed — README.md `SUPERPOWERS_AUTO_UPDATE` cross-reference repointed at "Available Update Notification" → 3b30e10
- [M8] fixed — `**Reviewer verdicts:**` rule now states the entry is one line, never wrapped, in both review skills → 3b30e10
- [K1] carried — test-session-start-reviewers-tag.sh run_hook accepts only one extra VAR=value argument (ship-as-is: every call site passes at most one)
- [K2] fixed — multi-doc-review SKILL.md duplicate u = 0 inconclusive bullet deleted → 3b30e10
- [K3] carried — multi-doc-review ", counts recomputed" instruction placed in step 5 instead of step 2 (ship-as-is: unambiguous where it stands)
- [K4] carried — multi-doc-review uses the letter k for both the invocation number and the source-finding count (ship-as-is: locally disambiguated)
- [K5] carried — multi-doc-review "a resumed invocation given a new M" rule has no resume path defined (ship-as-is: harmless no-op, keeps both log formats identical)
- [K6] fixed — multi-doc-review after-the-loop report list now names the effective M and any substitution → 3b30e10
- [K7] fixed — multi-doc-review "byte-identical" label reworded, same fix as [M1] → 3b30e10
- [K8] carried — multi-doc-review SKILL.md grew 180 → 354 lines; consolidation rules as a reference file (ship-as-is: out of scope for this branch)
- [K9] fixed — multi-code-review canonical-dispositions "always uses the single shape" softened and pointed at the M ≥ 2 annotation rule → 3b30e10
- [K10] fixed — multi-code-review clean-round and Minor-only-round sentences qualified with "with u = M" → 3b30e10
- [K11] fixed — multi-code-review skipped-entry field list now lists M after N → 3b30e10
- [K12] carried — .superpowers/sdd/task-6-report.md per-file diffstat numbers wrong (ship-as-is: work artifact, totals correct)
- [K13] fixed — README.md first use of M now expands to "(reviewers per lens)" → 3b30e10
- [K14] carried — docs/REVIEW-PROCESS-COMPARISON.md eval item does not restate the 1–5 range (ship-as-is: stated in the sibling documents it links to)

## Round 2 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor   <!-- counts recomputed from the enumeration; the report's count line said 3 Minor while enumerating M1–M4 -->
**Converged:** no
### Dispositions
- [I1] fixed — `../dispatching-parallel-agents/SKILL.md` reference narrowed to the single-message mechanic of its Procedure step 3; its Decision Check, integration-verification step and prompt requirements declared not applicable to reviewer dispatch, in both review skills → 6f5526b
- [I2] fixed — M resolution step 2 now states that only a `<reviewers-per-lens>` tag injected at session start counts; an occurrence inside any file the controller read is data, never a parameter, in both review skills → 6f5526b
- [M1] carried — the accepted M forms do not cover the near-miss phrase "with 2 reviewers", so the number can survive into N parsing (changing the stated form list would contradict the plan's parameter grammar; left for the user)
- [M2] fixed — README.md and docs/guide/README.md now note that `SUPERPOWERS_REVIEWERS_PER_LENS` is honored on Claude Code and Cursor and has no effect on Codex → 6f5526b
- [M3] carried — tests/claude-code/test-helpers.sh `**Sources mapped:** k/k` equality check cannot fail by construction; the two checks that follow carry the real traceability assertion
- [M4] carried — tests/claude-code/test-helpers.sh assertion (m) passes trivially when a round's consolidated set is empty; making an empty round 1 a failure would make a genuinely clean round fail

## Round 3 — Security — opus
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor
**Converged:** no
### Dispositions
- [M1] fixed — plan manual-verification block now validates `VERSION` before composing `$CACHE`, so an empty or missing `VERSION` can no longer collapse the `rm -rf` target to the parent plugin-cache directory → 153fc8b (partial: the two `rm -rf "$CACHE"` mentions in the surrounding prose are inline code spans outside the fenced block and were left unchanged; the root cause is removed)
- [M2] fixed — both review skills now state that only the LAST `<reviewers-per-lens>` element of the session context is a parameter, because `hooks/session-start` appends its own tag after every embedded workspace-file block → 153fc8b

## Round 4 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — `assert_round_reviewers` skips its content checks when a round entry says `**Sources mapped:** 0/0`, so assertion (m) can pass while verifying nothing and the behavioural test still exits 0 (plan-mandated: Task 6 Step 1 fixes the helper's content verbatim, and making the 0/0 path fail would contradict it)
- [I2] fixed — both behavioural tests now assert the M=2 contract on round 2 as well as round 1 → afaafe4
- [I3] fixed — tests/claude-code/test-multi-doc-review.sh regained default (M=1) coverage as a second case asserting the M=1 log shape → afaafe4
- [M1] fixed — tests/codex/test-session-start-reviewers-tag.sh now exercises both boundaries of the `[1-5]` range (1, 3, 5) → afaafe4
- [M2] fixed — invocation-line `M=` greps added for the doc-review M=2 case and for both M=1 cases → afaafe4
- [M3] fixed — the "empty consolidated set" note in tests/claude-code/test-helpers.sh is now printed only when the `**Sources mapped:**` line was actually found → afaafe4

## Round 4 verification 1 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 2 Important, 7 Minor
### Dispositions
- [I1] fixed — the doc-review M=1 case now fails when the `## Round 1 — ` entry extracts empty, and its positive anchor greps the same header prefix → bb6d7db
- [I2] fixed — both behavioural scripts `unset SUPERPOWERS_REVIEWERS_PER_LENS`, so the default-M cases no longer depend on the developer's environment → bb6d7db
- [M1] fixed — `assert_round_reviewers` now prints a `note:` when a round was partial (usable u/m), so a green run is distinguishable from one that never exercised M ≥ 2 consolidation → bb6d7db
- [M2] fixed — the code-review M=1 case gained the same negative shape block, with the non-empty extraction guard → bb6d7db
- [M3] fixed — the session-tag test now rejects `3.0`, `2.5`, the set-but-empty value and `" 3"` → bb6d7db
- [M4] fixed — a new case seeds `state.md` with a decoy `<reviewers-per-lens>` element and asserts the hook's own tag is still last → bb6d7db
- [M5] fixed — both skills now state that a clean round with an empty consolidated set writes `**Sources mapped:** 0/0`, and only an inconclusive round omits the line → bb6d7db
- [M6] carried — no assertion covers `## Round <i> verification <c>` entries; adding a conditional assertion for entries that may not exist was judged more churn than value at this point
- [M7] fixed — both inner per-call timeouts lowered to 1500 s so two live calls fit one outer budget, and the runner's help listing now hints `--timeout 3600` for the doc-review test → bb6d7db

## Round 4 verification 2 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor
### Dispositions
- [I1] fixed — the doc-review test now captures each `claude -p` exit status and reports a dedicated timeout failure on 124/143, and both inner budgets were raised to 1700 s to fit the advised `--timeout 3600` → 4f1c932
- [I2] fixed — both behavioural scripts now also detect `SUPERPOWERS_REVIEWERS_PER_LENS` in the `env` block of the applicable settings files and abort with a named reason, because a shell-level `unset` cannot remove a settings-supplied value → 4f1c932
- [M1] fixed — plan Task 6 verification now expects `assert_round_reviewers` twice per behavioural test file → 4f1c932
- [M2] fixed — plan Task 1 verification now states the shipped assertion counts (9 passed / 4 failed before, 13 passed / 0 failed after) → 4f1c932
- [M3] fixed — plan Task 6 Step 7 now runs the doc-review behavioural test with `--timeout 3600` → 4f1c932
- [M4] fixed — `assert_round_reviewers` now reports a missing round entry as one distinct failure instead of five generic ones → 4f1c932 (the partial-round tolerance named in the same finding was left unchanged: the plan lists it explicitly under "Does NOT cover")

## Round 4 verification 3 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor
### Dispositions
- [M1] carried — on a clean M ≥ 2 round the presence of the `**Reviewer verdicts:**` line is not checked, because `**Sources mapped:** 0/0` makes the sum comparison succeed at 0; not fixed here, since the verification cycle cap (3) was reached and a further fix would ship unreviewed
- [M2] carried — `check_no_reviewers_per_lens_setting` omits `~/.claude/settings.local.json` from the settings files it inspects; same reason as [M1]

_Completed — 2026-08-28 — cap reached — HEAD 4f1c9323740622a3332e7d89d2949d85749045ea_

### Post-loop decisions — 2026-08-28
- [I1] (round 4) decided (user): fix it — `assert_round_reviewers` now takes a required fourth argument, `required` or `optional`, stating whether that round must have consolidated at least one finding; `required` makes a `**Sources mapped:** 0/0` entry fail, `optional` keeps the documented skip, and a missing or misspelled value fails. Plan Task 6 Step 1 was amended in that step as a block quote, so the helper body is no longer mandated verbatim on this point and the finding is no longer a plan conflict.
- [I1] (round 4) fixed — required `required`/`optional` argument added to `assert_round_reviewers`; the four call sites updated (round 1 `required` in both behavioural tests, round 2 `optional`) → 649b38e

_Invocation 2 — 2026-08-28 — N=4 M=1 — BASE..HEAD 526a74c..649b38e — branch feature/reviewers-per-lens — gate: orchestration_

_Carried findings source: `.superpowers/sdd/progress.md` `Minor:` lines (14 items), labelled `[K1]`–`[K14]` below._

## Round 5 — Correctness & spec alignment — opus
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no
### Dispositions
- [M1] fixed — multi-doc-review SKILL.md clean-round "- none" sentence qualified "with u = M", matching its twin in multi-code-review → 41f1eb5
- [M2] carried — the M ≥ 2 `description` note in both reviewer-prompt.md templates uses two unbracketed continuation lines instead of the files' bracket convention (presentation only; the dispatching text is unambiguous)
- [M3] fixed — `check_no_reviewers_per_lens_setting` now also inspects `$HOME/.claude/settings.local.json` → 41f1eb5
- [M4] carried — the two 1700 s inner `claude -p` budgets in test-multi-doc-review.sh leave about 200 s under the advised `--timeout 3600`; left as is because rounds 4 verification 1 and 2 already moved this value in both directions and a third change would ship unreviewed churn
- [K1] carried — test-session-start-reviewers-tag.sh run_hook accepts only one extra VAR=value argument (ship-as-is: the comment matches the code, every call site passes at most one)
- [K2] carried — multi-doc-review duplicate u = 0 inconclusive bullet (ship-as-is: already fixed on this branch, one bullet remains)
- [K3] carried — multi-doc-review ", counts recomputed" instruction placed in step 5 instead of step 2 (ship-as-is: presentation preference, no behaviour change)
- [K4] carried — multi-doc-review uses the letter k for both the invocation number and the source-finding count (ship-as-is: the two uses are in different sections)
- [K5] carried — multi-doc-review "a resumed invocation given a new M" rule has no resume path defined. The round-5 reviewer recommended `user-decision` and called both options defensible; the controller keeps invocation 1's decision (ship-as-is: an unreachable rule that preserves word-for-word parity with multi-code-review's log format), so this is not re-opened as an open item
- [K6] carried — multi-doc-review after-the-loop report list and effective M (ship-as-is: already fixed on this branch)
- [K7] carried — multi-doc-review "byte-identical" label (ship-as-is: already fixed on this branch)
- [K8] carried — multi-doc-review SKILL.md grew 180 → 354 lines (ship-as-is: a structural split does not belong in a release branch)
- [K9] carried — multi-code-review canonical-dispositions "always uses the single shape" (ship-as-is: already fixed on this branch)
- [K10] carried — clean-round and Minor-only-round sentences not qualified by u = M (ship-as-is for multi-code-review, already fixed; the same gap in multi-doc-review is [M1] above and was fixed this round)
- [K11] carried — multi-code-review skipped-entry field list missing M (ship-as-is: already fixed on this branch)
- [K12] carried — .superpowers/sdd/task-6-report.md per-file diffstat numbers wrong (ship-as-is: untracked work artifact, totals correct)
- [K13] carried — README.md first use of M does not expand it (ship-as-is: already fixed on this branch)
- [K14] carried — docs/REVIEW-PROCESS-COMPARISON.md eval item does not restate the 1–5 range (ship-as-is: that line describes a hypothetical evaluation design, not the parameter contract)

## Round 6 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — the Agent call's `description` reaches the reviewer subagent's own context on this harness, so the M ≥ 2 suffix `(reviewer <j>/<m>)` tells each reviewer that other reviewers exist and leaks M, contradicting the stated invariant (plan-mandated: the plan's design summary and both reviewer-template steps mandate that suffix and the sentence "the description is not part of the prompt" verbatim)
- [I2] user-decision — the round-1 carried-finding rule escalates to `user-decision` when ANY reviewer recommends it, so a larger M raises the probability that an unattended orchestration run stops on a Minor carried item (1 − (1 − p)^M); the documentation presents M as a quality knob with a token cost only (plan-mandated: the plan fixes "disagreement → most cautious (`user-decision` > `fix-before-merge` > `ship-as-is`)")
- [M1] carried — the Carried Findings Triage output shape carries no item ids, so with M ≥ 2 the controller must match items across reports by free text; adding ids would change the reviewer template beyond the plan's "the reviewer prompt bodies and placeholders are untouched"
- [M2] fixed — the advised outer timeout for the doc-review behavioural test raised from 3600 s to 4200 s in the runner help text and in the plan's Task 6 Step 7 verification command, leaving about 800 s of headroom over the two 1700 s inner budgets → 0a1c318
- [M3] carried — a bare `<m> reviewers` (for example "review the branch 3 times with 2 reviewers") matches no accepted M form and is then read as N; the plan fixes the four accepted forms exactly
- [M4] carried — a round is clean only at u = M, so a systematically unusable reviewer disables early exit and a larger M makes a clean round less likely; the plan fixes the u = M condition

## Round 7 — Security — opus
**Reviewer verdict:** 0 Critical, 1 Important, 0 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — when `SUPERPOWERS_REVIEWERS_PER_LENS` is unset the hook emits no `<reviewers-per-lens>` tag at all, so a tag planted in a repository file that `hooks/session-start` embeds (project-map.md, session-log.md, state.md, known-issues.md, context-snapshot.json) becomes the LAST element and is honoured as M; repository content can then raise M to 5 with no prompt (cost and concurrency amplification only, since M stays clamped to 1–5). The reviewer's fix — emit `<reviewers-per-lens>1</reviewers-per-lens>` when the variable is unset or invalid — is plan-mandated against: the plan states "Invalid or unset → no tag (silent fallback, documented)" and the shipped hermetic test asserts `expect_no_tag "unset SUPERPOWERS_REVIEWERS_PER_LENS"`. The finding's secondary suggestion (repeating the tag-ordering caveat in orchestrating-development and subagent-driven-development) was not applied separately, because the wording depends on which way this decision goes

## Round 8 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 1 Important, 6 Minor
**Converged:** no
### Dispositions
- [I1] fixed — both behavioural tests now assert that the extracted M=1 round-1 entry holds at least one enumerated disposition line before the four absence checks run, so the default-configuration block can no longer pass while verifying nothing → 3f3a999
- [M1] carried — the M=1 absence checks cover round 1 only, and Case 2 of the doc-review test has no Round-2 existence check; adding a second extraction on the last round of the loop was judged more churn than value
- [M2] carried — a partial round (usable u/m) prints a `note:` but is not counted in the test's final summary; the note already makes a degraded run visible in the transcript
- [M3] fixed — `assert_round_reviewers` now compares each annotation's agreement count with the number of source ids listed on that same line → 3f3a999
- [M4] fixed — `assert_round_reviewers` now rejects a non-single-digit `m` instead of silently building the character class `[1-1]0` → 3f3a999
- [M5] fixed — the two per-run budgets of test-multi-doc-review.sh restored to `timeout 1800` (with their failure messages), which the already-advised outer 4200 s covers → 3f3a999
- [M6] fixed — the advised outer timeout for test-multi-code-review.sh raised from 1800 s to 4200 s in the runner help text and in the plan's Task 6 verification command, above the sum of its two 1800 s inner budgets → 3f3a999

## Round 8 verification 1 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
### Dispositions
- [M1] carried — `assert_round_reviewers` still tolerates a partial round (`usable 1/2`) and only prints a `note:`; making it a failure for a `required` round is a sensible extension of the fourth argument, but it would ship unreviewed at the loop's cap
- [M2] carried — no behavioural case exercises resolution step 2 (a `<reviewers-per-lens>` session tag supplying M when the invocation states none); both tests deliberately unset the variable, and the extra live case costs a further multi-minute run
- [M3] carried — the new `[M]` placeholders in the two orchestration loop-prompt templates and the `M=<m>` field in the orchestration log header have no drift assertion in tests/sdd-scripts/run-tests.sh

_Completed — 2026-08-28 — cap reached — HEAD 3f3a999498d682a4899c7c43673d95c689223f2a_

_Invocation 3 — 2026-08-28 — N=4 M=1 — BASE..HEAD 526a74c..f80b424 — branch feature/reviewers-per-lens — gate: orchestration_

_Carried findings source: `.superpowers/sdd/progress.md` `Minor:` lines (14 items), labelled `[K1]`–`[K14]` below._

## Round 9 — Correctness & spec alignment — opus
**Reviewer verdict:** 0 Critical, 1 Important, 2 Minor
**Converged:** no
### Dispositions
- [I1] fixed — the header comment of tests/codex/test-session-start-reviewers-tag.sh still described the pre-amendment "no tag on the fallback path" contract, contradicting both the shipped hook and the file's own `expect_fallback_tag` assertions; rewritten to state the explicit `<reviewers-per-lens>1</reviewers-per-lens>` fallback → 1ff050c
- [M1] fixed — the two convergence bullets in docs/FORK-IMPROVEMENTS.md and the early-exit bullet in docs/REVIEW-PROCESS-COMPARISON.md now carry the `u = M` clean-round condition and the partial-round case → 1ff050c
- [M2] carried — the plan file still states the pre-amendment "no tag" contract in five places that Task 1's amendment supersedes without marking them (Global Constraints line 23, Task 1 "Does NOT cover", the verbatim test body of Step 1 and the expected outputs of Steps 3 and 5); Task 6 Step 1 uses an explicit "superseded on this point" marker and Task 1 does not. Carried rather than fixed: the plan is this loop's requirements document and its amendment bookkeeping belongs to the orchestrator, not to a review fix subagent
- [K1] carried — test-session-start-reviewers-tag.sh run_hook accepts only one extra VAR=value argument (ship-as-is: the comment says "one extra variable assignment", which matches the body; no call site passes two)
- [K2] carried — multi-doc-review duplicate u = 0 inconclusive bullet (ship-as-is: already fixed on this branch, one bullet remains)
- [K3] carried — multi-doc-review ", counts recomputed" instruction placed in step 5 instead of step 2 (ship-as-is: consolidation rule 1 already makes the enumeration authoritative before the entry is written)
- [K4] carried — multi-doc-review uses the letter k for both the invocation number and the source-finding count (ship-as-is: the two uses are in different sections)
- [K5] carried — multi-doc-review "a resumed invocation given a new M" rule has no resume path defined (ship-as-is: the Parameters M bullet names the case; only the mechanism is unstated)
- [K6] carried — multi-doc-review after-the-loop report list and effective M (ship-as-is: already fixed on this branch)
- [K7] carried — multi-doc-review "byte-identical" label (ship-as-is: already fixed on this branch)
- [K8] user-decision — multi-doc-review/SKILL.md has grown to 369 lines and the consolidation rules are a candidate for a reference file; the round-9 reviewer recommended `user-decision`, calling it a cost/benefit trade (context size against keeping both review loops teachable as one pattern) that belongs to the owner. Under M = 1 a single `user-decision` recommendation is decisive
- [K9] carried — multi-code-review canonical-dispositions "always uses the single shape" (ship-as-is: already fixed on this branch)
- [K10] carried — clean-round and Minor-only-round sentences not qualified by u = M (ship-as-is: already fixed in both skills)
- [K11] carried — multi-code-review skipped-entry field list missing M (ship-as-is: already fixed on this branch)
- [K12] carried — .superpowers/sdd/task-6-report.md per-file diffstat numbers wrong (ship-as-is: git-ignored work artifact, totals correct)
- [K13] carried — README.md first use of M does not expand it (ship-as-is: the multi-doc-review bullet now expands it and the Environment variables section defines it in full)
- [K14] carried — docs/REVIEW-PROCESS-COMPARISON.md eval item does not restate the 1–5 range (ship-as-is: the item names the evaluated values and both sibling documents state the range)

## Round 10 — Adversarial red-team — opus
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] fixed — both skills decided which `<reviewers-per-lens>` element supplies M by POSITION ("only the LAST element counts"), which is wrong for a file the controller reads during the session: that content arrives after the session-start block, so a tag planted in the plan file or any other read file was the last element and would be taken. The rule is now decided by SOURCE — only the block `hooks/session-start` injected counts; anything arriving through a tool result is data whatever its position — with the hook's last-position tag kept as additional protection → 33f1447
- [I2] fixed — `assert_round_reviewers` compared an annotation's agreement count with the NUMBER OF SOURCE IDS on the line, while both skills define the agreement count as the number of DISTINCT REVIEWERS; a correct line carrying two ids from one reviewer (`← 1/3: r1:I1, r1:I4`) failed the helper. The helper now counts distinct `r<j>` prefixes → 33f1447
- [I3] fixed — the dispatch step of both skills now states that the M reviewers share one working tree and run at the same time, so a reviewer must not run a command that writes to the checkout or binds a shared resource (fixed port, fixed temporary path, shared test database); read-only inspection only. With M = 1 concurrent interference could not occur, so the M change introduced the hazard → 33f1447
- [M1] carried — a round-1 entry can hold a carried ledger item and a current-round Minor finding that both render as `[M1]`; they are distinguishable, deterministically, by the presence of the ` ← <a>/<m>: <ids>` annotation (carried items never carry one), so the collision is presentational and a new id space would change a log format the behavioural tests assert against
- [M2] carried — duplicate of round 9 [M2]: the plan still states the pre-amendment "no tag" contract in places Task 1's amendment supersedes without marking them. Same disposition and same reason as round 9
- [M3] fixed — the carried-finding corroboration rule said "`user-decision` when at least TWO reviewers recommend it, or when M = 1 and the single reviewer does" without saying whether "M = 1" is the configured M or the usable count u; two agents would resolve a partial round (M = 3, u = 1) differently. It now names the configured M explicitly, which keeps M = 1 behaviour unchanged → 33f1447
- [M4] fixed — `check_no_reviewers_per_lens_setting` inspected four fixed settings paths and missed `$CLAUDE_CONFIG_DIR/settings.json` and `settings.local.json`, so the abort guard could report clean while `SUPERPOWERS_REVIEWERS_PER_LENS` was still applied to the run; both paths added → 33f1447

## Round 11 — Security — opus
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — the shared-checkout constraint added in round 10 ("a reviewer must not run any command that writes to the checkout or binds a shared resource; read-only inspection only") lives only in `skills/multi-code-review/SKILL.md:362` and `skills/multi-doc-review/SKILL.md:110`, which reviewer subagents never read; `reviewer-prompt.md` still permits each reviewer to run a focused test, and its Subagent Rules forbid only writes to the working tree, index, HEAD and branch state. On a branch of untrusted origin (a checked-out external pull request) up to five reviewers may now each execute that branch's test code at the same time in one shared checkout, and the skill's own untrusted-origin Error Handling bullet still speaks of the fix subagent alone. The reviewer's fix — add the rule to the Subagent Rules block of both `reviewer-prompt.md` files — conflicts with the plan's Global Constraint "The reviewer prompt bodies and placeholders are untouched" (plan-mandated), so the loop does not apply it. The finding's second half (extending the untrusted-origin bullet to say that M reviewers each execute the branch's code) does not conflict with the plan and was left with it, undivided, for one decision
- [M1] fixed — Phase 0 of `skills/orchestrating-development/SKILL.md` offered the M default from "a `<reviewers-per-lens>` tag in the session context" without the source restriction the two review skills now carry, so a tag planted in an embedded workspace file could become the offered default; the Phase 0 text now names the hook-injected block as the only source → 2fbc136
- [M2] fixed — `tests/claude-code/test-multi-doc-review.sh` runs two unattended `claude -p --permission-mode bypassPermissions` agents with `cd "$PLUGIN_DIR"` and had no blast-radius guard, while its sibling `test-multi-code-review.sh` snapshots the plugin repository around each run; the same `PLUGIN_HEAD_BEFORE`/`PLUGIN_STATUS_BEFORE` guard now wraps both runs → 2fbc136
- [M3] carried — the plan's Task 6 Step 6 installs the branch's skills into the live plugin cache and its restore step returns only the clone, so every later session on that machine keeps running branch skills under the released version's label until the cache is deleted by hand; the remediation is written as prose rather than as a step. Carried rather than fixed for the same reason as round 9 [M2]: the plan is this loop's requirements document and its steps belong to the orchestrator, not to a review fix subagent. The destructive command in that step is itself adequately guarded

## Round 12 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — `assert_round_reviewers` accepts `usable [1-m]/m`, so a round in which only one of two reviewers returned a usable report passes every remaining check (Sources mapped, verdict sum, distinct sources, per-line agreement count) and the helper prints a `note:` line and returns 0. Both behavioural tests can therefore report PASS while the M ≥ 2 consolidation path — the whole feature — was never exercised. The reviewer verified this against a hand-built `usable 1/2` fixture. The proposed fix is a suite-level assertion that at least one checked round reported `usable <m>/<m>`. Plan-mandated: Task 6's "Does NOT cover" declares the `[1-m]` tolerance deliberate ("only prevents a rare retry failure from failing the test") and a partial-round test out of scope, so the loop does not apply it
- [I2] fixed — three code blocks of the plan's Task 6 (Step 2's fixture verification and the Step 3 and Step 4 replacement snippets) still called `assert_round_reviewers` with three arguments, while the shipped helper requires a fourth (`required`/`optional`) since 649b38e; the documented verification therefore failed with "needs a fourth argument". All three calls now pass `required`, matching the shipped test lines, and the corrected block was run to confirm the stated expected output still holds → 4fa1ab3
- [M1] fixed — `expect_tag "1"` in the hook unit test asserts a tag byte-identical to the fallback, so that one case cannot fail even if the hook ignored the variable; the case and the assertion count are kept and a comment now records that only the `3` and `5` cases are discriminating → 4fa1ab3
- [M2] fixed — `check_no_reviewers_per_lens_setting` did not inspect the enterprise managed-settings file, which has the highest precedence, so a managed value of SUPERPOWERS_REVIEWERS_PER_LENS defeated the guard silently; both the macOS and the Linux paths were added → 4fa1ab3
- [M3] carried — the hook unit test sets only `CLAUDE_PLUGIN_ROOT`, so the Cursor output branch (`additional_context`, selected by `CURSOR_PLUGIN_ROOT`) has no assertion although README.md documents Cursor support. Both branches interpolate the same `$session_context`, so the risk is low; a new case would change the assertion count that Task 1's steps state, and that text is already stale (round 9 [M2]) — one correction of it belongs to the orchestrator, not to two separate loop fixes
- [M4] carried — no test covers the M ≥ 2 error shapes (partial round, inconclusive round, invalid stated M, the `, ids renumbered` and `, counts recomputed` suffixes). Task 6's "Does NOT cover" places partial and inconclusive rounds out of scope, so this is a scope note rather than a missed requirement; the reviewer's own suggestion routes it through the fixture-driven helper test proposed in [I2]

## Round 12 verification 1 — Test & coverage quality — opus
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
### Dispositions
- [I1] rejected: duplicate of round 12 [I1] — the same partial-round tolerance in `assert_round_reviewers`, reported again with the same suggested run-level gate; it is already recorded as `user-decision` (plan-mandated) on round 12 and is not counted twice
- [M1] carried — no test covers the inconclusive M ≥ 2 round shape (`usable 0/<m>`, which the helper's `[1-m]` class actively rejects) nor the resumed-invocation shape `**Reviewers:** M=1, usable 1/1`; same scope note as round 12 [M4]
- [M2] carried — the M plumbing through `orchestrating-development` (Phase 0 question, the `Params:` line of state.md, the `[M]` placeholder of both loop prompt templates) and through `subagent-driven-development` (final gate resolution, M carried across `/clear`) is verified only by `grep` counts on the Markdown; no test asserts that a stated M reaches either review loop. The plan's Tasks 4 and 5 define exactly that verification, so closing the gap is a scope change rather than a defect fix
- [M3] carried — the hook unit test exercises only the `hookSpecificOutput.additionalContext` output branch; the reviewer checked `hooks/session-start` and confirmed all three branches print the same `$session_context`, so the tag cannot differ between them. Same item as round 12 [M3]
- No unreviewed fix remains: this cycle reviewed 4fa1ab3, and it produced no finding requiring a fix, so the verification of round 12 ends here (1 of 3 cycles used)

_Completed — 2026-08-28 — cap reached — HEAD 4fa1ab37bfeff98f2abd6b2f007d51505db9aa79_
