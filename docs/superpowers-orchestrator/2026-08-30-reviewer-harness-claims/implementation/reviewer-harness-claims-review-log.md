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

