# Orchestration Log — reviewer-harness-claims

_Invocation 1 — 2026-08-30 — spec docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/specs/reviewer-harness-claims-design.md — N_plan=2 N_code=2 M=1 cap=3 — branch feature/reviewer-harness-claims — BASE 

## Phase 1 — Plan — DONE — 2026-08-30
plan: docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/plans/reviewer-harness-claims.md — 6 tasks

## Phase 2 — Plan review — rounds 2 — cap — unresolved 0

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits 658a989..ce1b35a
- Task 1: complete — fast test suite for the reviewer-template wording contracts (658a989..57d807f)
- Task 2: complete — harness claims rule and finding field, doc-review reviewer template (f781fbc..897de5a)
- Task 3: complete — harness claims rule and finding field, code-review reviewer template (7564c2d..ce1b35a)

## Phase 3 — Batch 2 (tasks 4–6) — BLOCKED at task 6 — commits 4593974..a148818
- Task 4: complete — controller triage of harness claims in multi-doc-review (4593974..daa45aa)
- Task 5: complete — controller triage, user-decision guard, fix-subagent input in multi-code-review (c974540..a148818)
- Task 6: blocked — plan Steps 3–4 commit `CLAUDE.md`, which `.gitignore:7` ignores (untracked since 4f03c2a); Step 1 applied on disk, all four fast suites pass

## STOPPED — 2026-08-30 — phase 3 — batch controller BLOCKED task=6: CLAUDE.md is gitignored, plan assumes it is tracked
Detail: .superpowers/sdd/task-6-report.md
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/plans/reviewer-harness-claims.md

## Phase 3 — Batch 3 (task 6, resumed with answer) — COMPLETE — commits dc805d4..ede5568
- Task 6: complete — CLAUDE.md Testing line on disk only (file is gitignored, plan amended); all four fast suites pass; no code commit, tick commit ede5568

## Phase 4 — Code review — rounds 2 — cap — fixes 1 — unresolved 0 — user-decision 2

## STOPPED — 2026-08-30 — phase 4 — 2 user-decision items (plan-mandated wording; fixes touch files outside the plan's file set)
Detail: docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/implementation/reviewer-harness-claims-review-log.md
Open: [I1] user-decision — dispatch rule keyed on "your own prompt states that you were dispatched with a `name:`", text the `orch-*` controller prompts never contain
Open: [I2] user-decision — `Harness probes owed:` list lives only in the completion report; no path across the pipeline return boundary, so owed probes can be dropped unattended
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/plans/reviewer-harness-claims.md

## Phase 4 — Code review (resumed with answers [I1]: b, [I2]: a) — rounds 2 — cap — fixes 2 — unresolved 0 — user-decision 4

## STOPPED — 2026-08-30 — phase 4 — 4 user-decision items raised by the verification re-reviews of the resume fixes (plan-mandated wording)
Detail: docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/implementation/reviewer-harness-claims-review-log.md
Open: [v2 I2] user-decision — `not settled by one probe; first: <probe>`: the `first:` text fills only the completion-report line, never the review-log `rejected:` line, so the owed probe is lost in pipeline mode
Open: [v2/v3 I3] user-decision — a `harness: tested — …` observation is accepted without re-verification and without a rule for an observation that neither matches nor contradicts the prediction; it bypasses the user-decision guard
Open: [v3 I1] user-decision — the dispatch rule's poll names no mechanism and no limit; a foreground `sleep` is refused in this harness; the "Waiting on a subagent" reference is not in the review skills' context
Open: [v3 I2] user-decision — `rejected: harness probe not runnable here — <probe>`: three branches write a reason (`probe subagent did not report`, `no probe named`, …) into the `<probe>` slot instead of the probe text
Owed probe: none
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/plans/reviewer-harness-claims.md

## Phase 4 — Code review (resumed with Case 007 rulings + standing rule) — rounds 2 — cap — fixes 3 — unresolved 0 — user-decision 3

## STOPPED — 2026-08-30 — phase 4 — 3 user-decision items against the reviewer templates' plan-mandated text (Tasks 2/3), outside the standing rule's scope
Detail: docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/implementation/reviewer-harness-claims-review-log.md
Open: [v4 I3 = v5 I2] user-decision — model-probe sentence: a probe prompt that names the token contaminates the probe
Open: [v4 I4] user-decision — tie-break sentence "cannot be read from the repository" widens harness property to library/OS/remote claims
Open: [v6 I1] user-decision — no strip rule for a `harness:` field on a repository-readable premise
Owed probe: none
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/plans/reviewer-harness-claims.md

## Phase 4 — Code review (resumed with Case 008 rulings, standing rule widened) — rounds 2 — cap — fixes 1 — unresolved 0 — user-decision 0
Harness probes owed: none

_Completed — 2026-08-30 — HEAD 63eb0ab_
