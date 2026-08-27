# Review log — reviewers-per-lens-design.md

_Invocation 1 — 2026-08-27 — N=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5
**Reviewer verdict:** 0 Critical, 5 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — §6.1/§7: precedence of M on a resumed invocation was undefined and the premise "recovers M like N" was false → added "Precedence on resume" (the passed parameter governs, the invocation line is never rewritten, `**Reviewers:**` is written whenever the effective M differs); the orchestration log named as the only parameter source on resume
- [I2] applied — §5.6: partial rounds against "No fix ships unreviewed" were undefined → a partial round or cycle (u ≥ 1) satisfies the reviewed condition; an empty partial cycle ends the verification; "never clean" concerns the streak only
- [I3] applied — §5.3: carried-findings triage with M recommendation sets → recommendation lines are outside k; most-cautious rule (user-decision > fix-before-merge > ship-as-is); no source annotation on carried dispositions
- [I4] applied — §4.2: `M=2` would be rejected by the BASE character set → M tokens are extracted before the positional rule runs
- [I5] applied — §6.2/§6.1: `fixed — <summary> → <sha>` shape and its sha readers → shape redefined with an optional suffix, readers take the token after `→ `, both readers added to the consumer list, addendum lines carry no annotation
- [M1] applied — §6.2: inconclusive (u = 0) and skipped entries for M ≥ 2 defined
- [M2] applied — §5.3 rule 8: malformed ids renumbered by position per heading, `ids renumbered` noted on the reviewer's verdict entry
- [M3] applied — §7: batched handoff writes `M=<m>` into the Resume Instructions prompt
- [M4] applied — §7: pre-7.4.0 orchestration header defaulting to M = 1 stated as an explicit exception to the never-defaulted rule

## Round 2 — Ambiguity & testability — claude-fable-5
**Reviewer verdict:** 0 Critical, 6 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — §6.2/§5: "byte-identical when M = 1" contradicted the `**Reviewers:**` rule for a resumed invocation → byte-identity restricted to invocation lines recording `M=1` or none; the effective-M=1-under-larger-M entry defined (one `**Reviewers:**` line, original ids, no annotations)
- [I2] applied — §7: batched handoff wrote "the M in effect", which would freeze an environment-derived value → `M=<m>` written only when the user stated M at batch start
- [I3] applied — §10: `**Sources mapped:**` was self-certified → tests cross-check the sum of `**Reviewer verdicts:**` counts and the count of distinct source ids against k, scoped to the round-1 entry
- [I4] applied — §4.4: "subagents do not receive SessionStart context" had no citation → verified with a probe subagent (2026-08-27), cited; template value wins if both are ever present
- [I5] applied — §5.1: "`description` is not part of the prompt" had no citation → verified with the same probe (marker token in `description` not found), cited; fallback stated (drop the suffix, keep the non-goal)
- [I6] applied — §4.2: extraction-first rule stated for `multi-code-review` only → now both skills; example "2 times with 3 reviewers per round" → N = 2, M = 3
- [M1] applied — §5.3 rule 3: "same place" thresholds defined (deepest cited section; line ranges sharing a line, a point is a one-line range; same symbol)
- [M2] applied — §6.2: no code or test parses `**Reviewer verdict:**`; the false claim about the orchestrator reading it removed
- [M3] applied — §5.5/§6.2: count-line disagreement recorded by `, counts recomputed` on the reviewer's entry when M ≥ 2
- [M4] applied — §8: "no manifest declares environment variables" corrected (`plugin.universal.yaml:121` declares `CLAUDE_PLUGIN_ROOT`)
- [M5] applied — §10: script-level parser test dropped (no script parses `_Invocation`); fixture text updates kept
- [M6] applied — §3: prompt-cache prefix sharing labeled unverified
- [M7] applied — §5.3: carried-finding decision taken over the recommendations present; none present → controller decides alone
- [M8] applied — §10/§6.2: round-1 scoping of the greps specified; zero-finding reviewer entry form added to the example

## Round 3 — Feasibility & architecture risk — claude-fable-5
**Reviewer verdict:** 0 Critical, 2 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — §8: the bash snippet called `escape_for_json` before its definition (exit 127 under `set -e`, no session context) → three explicit placements: `case` block with the content blocks, the escape call in the escape group, the variable appended at line 448
- [I2] applied — §10: the session-start test was not hermetic (network fetch, possible fast-forward of the checkout, reads of the five memory files, cache write) → `SUPERPOWERS_AUTO_UPDATE=0`, empty temporary working directory, temporary `HOME` required
- [M1] applied — §3: the templates' header sentence "One reviewer per round" listed as a second prose-only edit
- [M2] applied — §3/§4.4/§8/§10/§11: Codex adapter emission dropped from scope — no Codex consumer exists because every review loop needs the Agent tool; post-push checklist no longer required
- [M3] applied — §4.4/§7: a changed `settings.json` value takes effect after a CLI restart, not on `/clear` (labeled unverified); wording changed in both places
- [M4] applied — §11: `docs/REVIEW-PROCESS-COMPARISON.md` edit limited to line 197; line 220 (fix subagent) unchanged

_Completed — 2026-08-27 — cap reached (3 rounds, none clean)_
