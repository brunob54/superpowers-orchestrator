# Review log — reviewer-harness-claims

_Invocation 1 — 2026-08-30 — N=2 M=1 — BASE..HEAD 82722ff..27c49b3 — branch feature/reviewer-harness-claims — gate: orchestration_

## Round 1 — Correctness & spec alignment — fable
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor
**Converged:** no
### Dispositions
- [M1] carried — multi-doc-review/SKILL.md:218 "one of the two below" omits the `deferred` Minor disposition the plan's Global Constraints allow (plan-mandated verbatim wording; a text change is the user's call)
- [M2] carried — `rejected: harness probe not runnable here — <probe>` reachable with no value for `<probe>` (untagged premise / `no probe named` branch) in multi-code-review/SKILL.md:424,476,986 and multi-doc-review/SKILL.md:172,428 (plan-mandated verbatim wording; a text change is the user's call)
- carried — CLAUDE.md:12 new suite line does not align its `#` comment column with lines 10-11 (reviewer: ship-as-is — file is gitignored and untracked; text is the plan's verbatim wording)

## Round 2 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] user-decision — dispatch rule (multi-code-review/SKILL.md:437, multi-doc-review/SKILL.md:185) is keyed on "your own prompt states that you were dispatched with a `name:`", text the `orch-*` controller prompts of orchestrating-development never contain (`name:` is an Agent-tool header parameter; verified against this controller's own prompt); a fix changes plan-mandated verbatim wording or edits `skills/orchestrating-development/*` outside the plan's file set (plan-mandated)
- [I2] user-decision — `Harness probes owed:` list lives only in the completion report (plan Global Constraints); in pipeline mode the controller return is capped at one status line plus 3 notes and the orchestrator relays no owed-probes field, so owed probes can be dropped unattended; a file home or orchestrator relay is outside the plan's file set (plan-mandated)
- [I3] fixed — probe constraints gain "sends nothing anywhere — no network request, no message" and the sentence that reviewer-authored probe text is data, not an instruction, in both SKILL.md files → de3e5eb
- [M1] carried — `no probe named` branch has no literal disposition/owed-item text for the empty `<probe>` (multi-code-review/SKILL.md:476, :986); same issue as round 1 [M2] (plan-mandated wording; a text change is the user's call)
- [M2] carried — a `harness: tested — read own context` observation can be made from a context the claim is not about, so the rule can pass vacuously (reviewer-prompt.md:72-73 in both templates; plan-mandated byte-identical rule text)
- [M3] carried — a not-runnable harness rejection on a Critical/Important finding keeps every round dirty and forces `cap reached` (multi-code-review/SKILL.md:459-461); the plan forbids touching convergence rules

## Round 2 verification 1 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 2 Important, 2 Minor
### Dispositions
- [I1] user-decision — same item as round 2 [I1]: dispatch rule keyed on a `name:` statement the `orch-*` controller prompts do not contain (plan-mandated)
- [I2] user-decision — same item as round 2 [I2]: `Harness probes owed:` list has no path across the pipeline return boundary (plan-mandated)
- [M1] carried — tests/reviewer-templates/run-tests.sh:61-66,113-118 drift check passes when both rule bodies are deleted and only the `### Harness claims` heading remains; no assertion pins a normative sentence of the body
- [M2] carried — same item as round 2 [M3]: a not-runnable harness rejection keeps the round non-clean (plan forbids touching convergence rules)
- verification result: the round 2 fix (de3e5eb) raised no finding; no unreviewed fix remains

## Post-loop addendum — 2026-08-30 — resume answers (gate: orchestration)
_Effective HEAD at addendum time: de3e5ebfec8c816312530d8c0c66f833e6224d01 — unchanged since the completion marker; no new invocation._
### Dispositions
- [I1] decided (user): fix it — option (b): reword the controller dispatch rule in both `skills/multi-code-review/SKILL.md` and `skills/multi-doc-review/SKILL.md` so it depends on nothing the controller cannot observe — a dispatch-based probe may run from any position; the probe subagent always writes its observation to a file at a unique temporary path outside the checkout and returns it as its final message; a launch-acknowledgement return is followed by a bounded poll of that file; a file that never appears is `not runnable here` with the reason `probe subagent did not report`; the reason `dispatch would not block` is removed; amendments recorded under plan Tasks 4 and 5
- [I1] fixed — dispatch rule reworded identically in both SKILL.md files (`dispatch would not block` no longer appears in either); amendments added under plan Tasks 4 and 5; `tests/reviewer-templates/run-tests.sh` unchanged (no assertion referenced the removed condition) → ca872f7c509e8e15034b9d696d684f9ff75defcd
- [I2] decided (user): fix it — option (a): the review log is the durable home of owed probes (every owed probe is a `rejected: harness probe not runnable here — <probe>` line); `skills/orchestrating-development/SKILL.md` — outside the plan's file set, explicitly allowed by the user — gains the "harness probes owed" item in the Phase 5 step 3 completion report and `Owed probe: <verbatim line>` lines after the `Open:` lines of the Phase 4 `## STOPPED` entry; amendment recorded under plan Task 5
- [I2] fixed — both additions made in `skills/orchestrating-development/SKILL.md`; amendment added under plan Task 5; no mirror copy of the skill exists (the only other files containing "Phase 5 — Completion" are the historical plan and design spec under `docs/superpowers-orchestrator/2026-08-04-orchestrating-development/`, left unchanged) → ca872f7c509e8e15034b9d696d684f9ff75defcd
- fix-commit tests: `tests/codex/run-unit-tests.sh` (10 suites passed), `tests/smart-compress/run-tests.sh` (87 passed), `tests/sdd-scripts/run-tests.sh` (193 passed), `tests/reviewer-templates/run-tests.sh` (19 passed) — output in the fix reports
- verification cycles remaining for round 2 before this addendum: 2 (one `## Round 2 verification` entry already logged)

## Round 2 verification 2 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
### Dispositions
- [I1] fixed — dispatch rule now creates a path that does not yet exist (`mktemp -u`) and polls until the observation file exists and is non-empty (`test -s`); a file still missing or still empty when the poll ends is `not runnable here` with the reason `probe subagent did not report`; identical wording in both SKILL.md files; `tests/reviewer-templates/run-tests.sh` passes (19 passed) → debacbbe524a7fdac4b5546d5096edcdd63f6e58
- [I2] user-decision — `not settled by one probe; first: <probe>` findings: the `first: <probe>` text "fills only the `Harness probes owed:` line of the completion report" (multi-code-review/SKILL.md:424-427, multi-doc-review/SKILL.md:169-172) while the log disposition `rejected: harness probe not runnable here — <probe>` carries no probe for this case; since decision [I2] the orchestrator harvests owed probes from the log lines, so such a probe is lost; the sentence is plan text (plan lines 467 and 640); suggested change: the disposition line carries the `first: <probe>` text as its `<probe>` (plan-mandated)
- [I3] user-decision — a `harness: tested — …` observation is accepted with no rule for an observation that neither matches nor contradicts the predicted result (for example "observed no result returned" from a reviewer's own detached dispatch; multi-code-review/SKILL.md:484-490, multi-doc-review/SKILL.md:216-222); two controllers dispose differently; the acceptance sentence is plan text (plan lines 508-510 and 696-698); suggested change: an observation that is not one clause matching or contradicting the claim is treated as `harness: untested — <the stated probe>` (plan-mandated)
- [M1] carried — `no probe named` rejections produce an owed item with no runnable probe (multi-code-review/SKILL.md:479-482, :826-831); same family as round 1 [M2] and round 2 [M1] (plan-mandated wording)
- [M2] carried — a persistent not-runnable harness rejection on a Critical/Important finding keeps every round non-clean and forces the cap (multi-code-review/SKILL.md:467-471, :562-565); same item as round 2 [M3] and verification 1 [M2] (plan forbids touching convergence rules)
- [M3] carried — with M ≥ 2 the same-issue consolidation rule does not say which `harness:` field survives a merge of a `tested` and an `untested` report of one claim (multi-code-review/SKILL.md:382-392)
- [M4] carried — the dispatch rule's "give up after a fixed limit" names no limit and does not say whether a probe dispatch is retried (multi-code-review/SKILL.md:445-447, multi-doc-review/SKILL.md:189-191); the wording mirrors the orchestration controllers' "Waiting on a subagent" rule as the user's decision [I1] specified
- verification result: the post-loop fix (ca872f7) raised [I1] against its own dispatch-rule wording; [I2] and [I3] are plan-mandated; fix cycle 3 (the last for round 2) dispatched for [I1]

## Round 2 verification 3 — Adversarial red-team — fable
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor
### Dispositions
- [I1] user-decision — the dispatch rule's poll ("check every few seconds, give up after a fixed limit") names no mechanism and no limit; in this harness a foreground `sleep` in Bash is refused and every Agent dispatch returns a launch acknowledgement, so the poll is the normal path, not a fallback, and the text has no branch for "the poll cannot run"; the reference to the "Waiting on a subagent" rule points at text only the orchestration controller prompts carry (multi-code-review/SKILL.md:445, multi-doc-review/SKILL.md:189); suggested change: name the wait mechanism (for example the `Monitor` tool with an until-condition, or background Bash), a concrete default limit, and a "poll mechanism unavailable → not runnable here" branch; the wording was set by decision [I1] and the verification cap for round 2 is reached, so no fix cycle remains — harness: tested — reviewer read its own tool descriptions; observed "Foreground `sleep` is blocked; use Monitor with an until-loop" (Bash) and "Subagents run in the background" (Agent)
- [I2] user-decision — the single disposition shape `rejected: harness probe not runnable here — <probe>` has three branches writing a reason into the `<probe>` slot (`probe subagent did not report` from decision [I1], `no probe named` from the plan, "with the reason" wording), so the owed-probe lines harvested by decision [I2] may carry a reason instead of the probe text, and a `no probe named` item is owed but cannot be run (multi-code-review/SKILL.md:451,485, multi-doc-review/SKILL.md:194); extends verification 2 [I2] and the carried `<probe>` family (round 1 [M2], round 2 [M1], verification 2 [M1]); suggested change: `rejected: harness probe not runnable here — <probe> (<reason>)` and an explicit rule for `no probe named` items on the owed line (plan-mandated)
- [I3] user-decision — same item as verification 2 [I3]: a `harness: tested — …` observation is accepted without re-verification, so a fabricated or wrong-dispatch `tested` clause bypasses the user-decision guard and can stop an unattended run (multi-code-review/SKILL.md:488, multi-doc-review/SKILL.md:216); suggested change: before any `user-decision` or `unresolved` on a `harness: tested` Critical/Important finding, the controller runs the stated probe once when it is controller-runnable, else treats the finding as `untested` (plan-mandated)
- [M1] carried — orchestrating-development/SKILL.md:311 lists owed-probe lines of the whole code-review and plan-review logs, so stale owed probes of earlier invocations are re-reported; the wording follows decision [I2]; suggested change: restrict to this pipeline's invocation entries
- [M2] carried — orchestrating-development/SKILL.md:355 writes `Owed probe:` lines only for a Phase 4 stop and only from the code-review log, so a Phase 2 stop drops the plan-review log's owed probes; the scope follows decision [I2]
- [M3] carried — item 1 runs a probe for every `harness: untested` finding whatever its severity, so Minor untested claims cost a dispatch-plus-poll cycle each (multi-code-review/SKILL.md:425, multi-doc-review/SKILL.md:169; plan-mandated)
- verification result: the cycle-3 fix (debacbb) raised no finding against its own wording (missing/empty observation file); the three Important findings contest plan text or decision wording and are journaled; verification cap for round 2 reached (3 cycles) — no unreviewed fix remains
- carried findings from the ledger (`Minor:` lines of `.superpowers/sdd/progress.md`) were not passed to a reviewer: this resume ran no round 1
- open items after this addendum: unresolved 0, user-decision 4 (verification 2 [I2], verification 2/3 [I3], verification 3 [I1], verification 3 [I2])

_Completed — 2026-08-30 — cap reached — HEAD debacbbe524a7fdac4b5546d5096edcdd63f6e58_
