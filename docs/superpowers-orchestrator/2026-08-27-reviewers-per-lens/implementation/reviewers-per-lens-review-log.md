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
