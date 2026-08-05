# Review Log — 2026-08-04-orchestrating-development-design.md

_Invocation 1 — 2026-08-04 — N=4 — gate: brainstorming_

## Round 1 — Correctness & completeness — fable
**Reviewer verdict:** 0 Critical, 4 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — Major-Error Policy: stop procedure impossible for pre-log Phase 0 failures; Phase-1-stop resume line named a nonexistent plan → split into pre-log stop (report-only, nothing written) vs in-run stop; Phase 1 stops resume via the spec path and re-dispatch the plan-writer
- [I2] applied — Phase 3: no cross-check of BATCH_COMPLETE against checkboxes; unbounded re-selection loop possible → added step 5 checkbox cross-check; reported-complete-but-unchecked → stop
- [I3] applied — Resume: no branch/tree/exclude preconditions in a fresh session → added step 0 (derive+checkout branch, clean tree required, re-ensure .git/info/exclude)
- [I4] applied — Phase 4: `gate: orchestration` is an invoker kind neither sub-skill defines; multi-code-review's completion skip is scoped to `gate: sdd` → added explicit template deviations (sentinel match + completion-skip extension) and made the orchestration log the primary re-run guard for Phases 2/4
- [M1] applied — Phase 0: batch cap unbounded made the 15-line return contract unsatisfiable → cap bounded 1–10, invalid → 3
- [M2] applied — Phase 0: pre-existing plan/log paths silently overwritten → added existence preconditions
- [M3] applied — Data flow: `.superpowers/reviews/<branch>-review-log.md` wrong for a slash-containing branch → `feature-<slug>-review-log.md` per multi-code-review's slug rule
- [M4] applied — Phase 2: controller "has" writing-plans' Self-Review checklist was false for a fresh-context subagent → template passes the writing-plans SKILL.md path + section name

## Round 2 — Ambiguity & testability — fable
**Reviewer verdict:** 0 Critical, 6 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — Log format/Phase 5: Phase 4 log-entry commit timing unspecified; one reading falsely stops every happy path → Phase 4 appends+commits its entry before Phase 5; commit schedule now lists "after Phase 4" and states every entry is committed before the next phase
- [I2] applied — N=0 unrepresentable in contracts → orchestrator skips dispatch itself and logs `skipped (N_x=0)` lines; sub-skill skipped-entry parenthetical dropped; log format gains the skipped shapes
- [I3] applied — `Task <n>: <status>` implied undefined partial-success statuses → contract fixed to `complete` only; any non-completable task forces `BLOCKED`; completed earlier tasks keep checkboxes/commits
- [I4] applied — malformed = missing leading token only, yet stop rules parse fields → malformed redefined to include absent/unparseable consumed fields; stop-rule fields never default to 0
- [I5] applied — interrupted Phase 2 resume undefined (multi-doc-review has no completion marker) → controller appends `_Loop complete_` line; invocation entry without it = interrupted, resume at next round; orchestration log Phase 2 entry is completion authority
- [I6] applied — Testing Strategy named `topSkill()` (lives in tests/codex/test-skill-activator.js) inside `tests/skill-triggering/` (CLI behavioral suite) → rank assertions relocated to the unit suite; behavioral prompt files optional/deferred; "full suite" = run-unit-tests.sh
- [M1] applied — Phase 2 `unresolved` had no producible condition/log shape → defined as apply-attempted-and-failed-twice with `unresolved: <reason>` disposition line
- [M2] applied — carried Minors passed as path vs list mismatch → controller extracts `Minor:` lines into the template placeholder
- [M3] applied — slug derivation undefined for non-conforming spec filenames → strip each affix only if present
- [M4] applied — nested-dispatch verification unverifiable → verification method + reproducible re-check described in Accepted Risks
- [M5] applied — SDD Autonomy Policy has controllers journaling state.md while Architecture makes orchestrator sole writer → explicit deviation: controllers never write state.md; blocker question goes in the task report file

## Round 3 — Feasibility & architecture risk — fable
**Reviewer verdict:** 0 Critical, 3 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — Phase 0/Resume ordered clean-tree check before exclude-ensuring; prior normal-flow state.md spuriously fails the first run → excludes now precede the porcelain check in both; Phase 0 restructured (steps renumbered 1–8). Merge also fixed the adjacent gap the same restructure exposed: brainstorming leaves the spec uncommitted, so the clean-tree check now exempts the spec + its review-log sidecar and step 6 commits them on the feature branch
- [I2] applied — committed plan review log appears in every Phase 4 package and MCR's reviewer prompt marks `*-review-log.md` diffs reportable; convergence impossible if graded C/I, fixer could delete audit logs → documented triage rule (`rejected: orchestration artifact (documented)`); cap-reached accepted as outcome; rationale recorded
- [I3] applied — subagent-guard's stated intent (block recursive sub-subagents) contradicts the load-bearing nested dispatch → sanctioned-nested-dispatch decision recorded in Guard section; guard header-comment amendment added to Repo Touches (comment-only)
- [M1] applied — Scope + Repo Touches still pointed rank tests at tests/skill-triggering/ → repointed to tests/codex/test-skill-activator.js
- [M2] applied — literal `.git/info/exclude` fails in linked worktrees; worktree rationale wrong → `git rev-parse --git-path info/exclude` in both sites; rationale corrected
- [M3] applied — checkbox predicate undefined (per-step boxes, no per-task box) → task complete ⇔ all boxes under `### Task N` checked; controllers tick all step boxes
- [M4] applied — cap 10 exceeds what a controller's context sustains → cap-sizing note (~5 risk threshold) + cheap-retry mechanics via ledger skip
- [M5] applied — nested task reviewers unmarked vs guard on skill-discussing repos → known-exposure note; fallback marker would cover them

## Round 4 — Adversarial failure modes — fable
**Reviewer verdict:** 0 Critical, 6 Important, 2 Minor
**Converged:** no

### Dispositions
- [I1] applied — mid-task controller death leaves orphan commits that bypass the task-review gate; retry story assumed task-boundary death → mandatory retried-controller procedure (REVIEW_BASE from last ledger HEAD, partial-work implementer note, package covers both attempts, SDD crash-shortcut forbidden in-batch); Phase 0 cap ceiling lowered 10 → 5
- [I2] applied — guard's verb+name matcher blocks free-text BLOCKED returns ("use executing-plans"), hanging the run on its only escape hatch → `<!-- orchestration report -->` marker promoted from fallback to initial implementation on every controller return; guard exemption + tests/codex unit test; malformed-return definition includes the marker
- [I3] applied — permission prompts stall an unattended run indefinitely; no-watchdog non-goal assigned detection to the absent user → Phase 0 question batch gains explicit permission-mode confirmation; non-goal amended to name this mitigation
- [I4] applied — triage rule covered only presence/modification findings; content findings on the fully-readable orchestration log would route a fixer into the audit trail → rule extended to any finding whose subject file is an orchestration artifact (presence, modification, or content)
- [I5] applied — parameter-caused stops resumed into identical stops with no documented teardown → resume prompt may override parameters (logged as a new invocation line); `Abandon orchestration` teardown procedure added
- [I6] applied — branch point never surfaced; unattended run can stack on a stale branch and surface the mistake only at merge → Phase 0 batch announces branch+sha, non-default branch point requires explicit confirmation (default abort)
- [M1] applied — clone-boundary/git-clean loss of ledger/state.md silently degrades Phase 4 → controller logs `carried findings unavailable — ledger absent`; resume step 6 documents what does not survive
- [M2] applied — date-stripped slugs collide across specs; collision message could point the user at an unrelated run's resume prompt → collision handling compares the existing log's recorded spec path before suggesting resume

_Loop complete — 2026-08-04 — rounds 4 — cap reached (no clean rounds; all 33 findings applied, 0 rejected). Post-loop self-review: fixed one merge-introduced inconsistency (Architecture still said controllers never name skills in returns; superseded by the round-4 marker decision)._
