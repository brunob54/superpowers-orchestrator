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
