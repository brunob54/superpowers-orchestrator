# Orchestration Log — prompt-pointer-dispatch

_Invocation 1 — 2026-09-05 — spec docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/specs/prompt-pointer-dispatch-design.md — N_plan=2 N_code=2 M=2 cap=3 — branch feature/prompt-pointer-dispatch — BASE b9b9ffb_

## Phase 1 — Plan — DONE — 2026-09-05
plan: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md — 4 tasks

## Phase 2 — Plan review — rounds 2 — cap — unresolved 0

## Phase 3 — Batch 1 (tasks 1–3) — COMPLETE — commits 8bf79e6..873d0ed
- Task 1: complete — commits 8bf79e6..6182d43 (security pre-review folded in; one fix round)
- Task 2: complete — commits 7c31a80..0c0950f (one fix round)
- Task 3: complete — commits e33b1cd..f122489 (security pre-review folded in; clean first review)

## RULING 1 — 2026-09-05 — phase 3 — Task 4 Step 4 cannot git add the gitignored CLAUDE.md; local edit only
Items: [task 4/1] forced — option (a) local edit only, no commit; Step 4 satisfied with nothing to commit; never `git add -f`
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch-open-decisions.md
Forks: none
Re-dispatch: phase 3, in-run resume 1 of 3

## Phase 3 — Batch 2 (tasks 4–4) — COMPLETE — commits bbb8f38..bf17503
- Task 4: complete — no code commit (CLAUDE.md is local-only per ruling 1); plan tick bf17503; all seven fast suites green, reviewer-prompt.md UNCHANGED

## RULING 2 — 2026-09-05 — phase 4 — three plan conflicts from code review invocation 1: two ruled, one escalated
Items: [M19] forced — plan governs: "The prompt directory is created once per invocation with `mktemp -d`, outside the checkout, before round 1 (a controller that runs a second invocation, or resum" — docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md
Items: [I2] forced — amend plan: prompt directory created once per invocation, not per controller (amended by ruling 3); fix it: Procedure preamble says once per invocation
Items: [I1] escalated (spec wrong) — a systematic reader-side pointer failure never reaches the inline fallback; every fix contradicts the spec's Error handling row and the Task 3 Contract
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch-open-decisions.md
Forks: none
Re-dispatch: none — escalated

## STOPPED — 2026-09-05 — phase 4 — [I1] escalated (spec wrong): reader-side pointer failure has no inline fallback
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/implementation/prompt-pointer-dispatch-review-log.md
Open: [I1] escalated (spec wrong) — a systematic reader-side failure of the pointer (every reviewer unable to read its prompt file) never reaches the inline-dispatch fallback; every fix contradicts the spec Error handling row "retry the identical pointer once … No new failure class" and the Task 3 Contract that mirrors it
Ruled: [M19 inv 1] forced — plan governs: "The prompt directory is created once per invocation with `mktemp -d`, outside the checkout, before round 1 (a controller that runs a second invocation, or resum" — docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md
Ruled: [I2 inv 1] forced — amend plan: the Global Constraints prompt-directory entry now reads "created once per invocation with `mktemp -d`, outside the checkout, before round 1 (a controller that runs a second invocation, or resumes one, creates a fresh directory first)" (amended by ruling 3); fix it: the Procedure preamble of skills/multi-code-review/SKILL.md says the directory is created once per invocation — before round 1, or before the round a resumed invocation continues at — never once per controller, so a second invocation in one session gets a fresh directory and no file-name collision
Owed probe: - [I2] rejected: harness probe not runnable here — in the session's normal permission mode (not bypass), write one file under a fresh `mktemp -d` directory and dispatch one throwaway subagent with the three-sentence pointer; observe whether a permission prompt appears before the subagent reports the file's content — (ambiguous observation) — a Read of the prompt file outside the working directories may raise a permission prompt in default permission mode; this session runs in bypass mode, so no observation here can match or contradict the claim ← 1/2: r1:I2
Owed probe: - [I2] rejected: harness probe not runnable here — in a session with permission mode `acceptEdits` (not bypass), Write one small file under a fresh `mktemp -d` directory and observe whether a permission prompt appears before the write lands — (ambiguous observation) — a value-file Write outside the working directories may wait on a permission prompt in a non-bypass session; this session runs in bypass mode, so no observation here can match or contradict the claim ← 1/2: r1:I2
Owed probe: - [I1] rejected: harness probe not runnable here — from the controller's session in the permission mode an orchestrated run uses (not bypass), Write one line to `<fresh mktemp -d dir>/probe.txt` with the Write tool and observe whether a permission prompt appears (then a throwaway subagent's Read of that file is the second probe) — (not settled by one probe) — value-file Writes and prompt-file Reads outside the working directories may raise permission prompts or be auto-denied in a non-bypass session, stalling the loop or making every round inconclusive; this session runs in bypass mode ← 2/2: r1:I1, r2:I2
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md

## RULING 5 — 2026-09-05 — phase 4 — invocation 2 open items: two ruled, one escalated
Items: [I1] forced — fix it: (this answers the round 4 user-decision item on lens-file reuse) the verification-cycle row of the file-name table in skills/multi-code-review/SKILL.md, and the sentence after the table, say that a verification cycle reuses its round's lens file when the current prompt directory holds it and otherwise writes it first — a resumed or post-loop-addendum controller starts from a fresh directory (ruling 3) that holds no earlier file; the same rule for a fix re-dispatch's findings file
Items: [I3] escalated (spec wrong) — a credential-shaped finding line makes the findings-file Write be refused by protect-secrets.js, fatal under the user's rule and repeating on resume; every fix softens the user's decided wording
Items: [I1] forced — fix it: (this answers the round 4 verification 3 unresolved item on the restore rule) in fix-prompt.md step 2 and the SKILL.md fix-failure bullet, the restore after a failed fix attempt uses git checkout -- <path> only for files git tracks; a file the attempt created and git does not track is removed by explicit path (rm -- <path>), never git clean, so the re-dispatch starts on a clean tree
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch-open-decisions.md
Forks: none
Re-dispatch: none — escalated

## STOPPED — 2026-09-05 — phase 4 — [I3] escalated (spec wrong): credential-shaped finding text makes the findings-file Write fatal
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/implementation/prompt-pointer-dispatch-review-log.md
Open: [I3] escalated (spec wrong) — a Security-lens finding that quotes the credential it reports makes the controller's Write of round-<i>-findings.txt be refused by hooks/safety/protect-secrets.js; under the fatal rule the round returns BLOCKED and the same round reproduces the stop on every resume; every fix softens the user's decided wording (ruling 4 Follow-up, spec Amendment 1)
Ruled: [I1 inv 2] forced — fix it: (this answers the round 4 user-decision item on lens-file reuse) the verification-cycle row of the file-name table in skills/multi-code-review/SKILL.md, and the sentence after the table, say that a verification cycle reuses its round's lens file when the current prompt directory holds it and otherwise writes it first — a resumed or post-loop-addendum controller starts from a fresh directory (ruling 3) that holds no earlier file; the same rule for a fix re-dispatch's findings file
Ruled: [I1 inv 2] forced — fix it: (this answers the round 4 verification 3 unresolved item on the restore rule) in fix-prompt.md step 2 and the SKILL.md fix-failure bullet, the restore after a failed fix attempt uses git checkout -- <path> only for files git tracks; a file the attempt created and git does not track is removed by explicit path (rm -- <path>), never git clean, so the re-dispatch starts on a clean tree
Owed probe: - [I2] rejected: harness probe not runnable here — in a session running in acceptEdits mode, Write a one-line file into a fresh `mktemp -d` directory and observe whether a permission prompt appears — (ambiguous observation) — a value-file Write outside the working directories may raise a permission prompt in a non-bypass session, which none of the fatal rows names; this session runs in bypass mode, so no observation here can match or contradict the claim ← 1/2: r1:I2
Owed probe: - [I3] rejected: harness probe not runnable here — run one N=4, M=3 invocation past an automatic compaction and check whether the compaction summary still contains the `mktemp -d` path verbatim — (not settled by one probe) — a prompt-directory path lost to a context compaction ends the loop with BLOCKED under the once-per-invocation constraint (round 3 [M1]); recording the path in an untracked workspace file is a spec-level change (round 4 verification 2 [M2]) ← 1/2: r1:I2
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md

## RULING 8 — 2026-09-06 — phase 4 — invocation 3: three items against the user's decided wording, all escalated
Items: [I2] escalated (spec wrong) — round 5: the secrets hook names a credential kind, never a line, so the withhold rule cannot select a line
Items: [I2] escalated (spec wrong) — round 6: the u = 0 fatal rule also stops on transient reviewer failures unrelated to the prompt file
Items: [I4] escalated (spec wrong) — round 6: a controller's own fill-command slip is fatal by the letter although nothing was written
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch-open-decisions.md
Forks: none
Re-dispatch: none — escalated

## STOPPED — 2026-09-06 — phase 4 — three items against the user's decided wording (rulings 8-10), all escalated (spec wrong)
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/implementation/prompt-pointer-dispatch-review-log.md
Open: [I2] escalated (spec wrong) — round 5: hooks/safety/protect-secrets.js names a credential kind ("Hardcoded <kind> detected in content"), never a line, so "each line the hook's message names" withholds nothing and the retried Write is refused again
Open: [I2] escalated (spec wrong) — round 6: the u = 0 fatal rule also returns BLOCKED for a round whose reviewers both died of a rate limit, tool error or kill, unrelated to the prompt file
Open: [I4] escalated (spec wrong) — round 6: a controller's own fill-command slip (exit 1, 3, 4, or 5 on an @file it never wrote) is fatal by the letter although nothing was written
Owed probe: - [I3] rejected: harness probe not runnable here — in a controller session holding a `mktemp -d` path, run `/compact` and check whether the summary still carries the literal path — (tool missing) — a prompt-directory path lost to a context compaction ends the loop with BLOCKED under the once-per-invocation constraint (round 3 [M1]); the suggested second `mktemp -d` contradicts that constraint, and no tool of this controller triggers a compaction ← 1/2: r1:I3
Owed probe: - [M6] rejected: harness probe not runnable here — from a subagent running in the orchestrator's normal permission mode, Write one file under a fresh `mktemp -d` path and observe whether a permission prompt appears — (ambiguous observation) — a value-file Write outside the working directories may raise a permission prompt in a non-bypass session; this session runs in bypass mode, so no observation here can match or contradict the claim ← 1/2: r2:M3
Resume: Resume orchestration for docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md

_Invocation 2 — 2026-09-06 — N_code=1 M=1 — resumed_

## RULING 11 — 2026-09-06 — phase 4 — invocation 4: five items ruled under the user's delegation (no questions until Phase 5)
Items: [I1] forced — amend plan: per-line secrets probe is one Write tool call, no hook path (amended by ruling 11); fix it: Error Handling and fix bullet
Items: [I2] forced — amend plan: format-only unusable report is not a pointer failure, round logged inconclusive (amended by ruling 11); fix it: step 3 and Error Handling
Items: [I4] forced — amend plan: write-once applies from the first pointer dispatch; before it, rm -- <file> and re-fill (amended by ruling 11); fix it: step 2
Items: [I6] forced — amend plan: same as [I1]; fix it: same as [I1]
Items: [I3] forced — fix it: rules before the variable blocks in fix-prompt.md; failure text capped at the last 150 lines with an omitted-lines note
Detail: docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch-open-decisions.md
Forks: none
Re-dispatch: phase 4, in-run resume 1 of 3


## Phase 4 — Code review — rounds 9 (5 invocations, N_code=2 M=2 then N_code=1 M=1) — cap — fixes 17 — unresolved 0

_Completed — 2026-09-06 — HEAD 0b81785_
