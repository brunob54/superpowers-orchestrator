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
