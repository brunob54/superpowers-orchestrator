# Review log — upstream-v7-fixes.md

_Invocation 1 — 2026-10-21 — N=3 M=3 — gate: orchestration — plan-blob 24df3e87b2cf247a03b8cf0b8e04ceae69c80b08_

## Readiness pre 1 — Execution readiness — claude-opus-5-5
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor

### Dispositions
- [M1] applied — Task 13 Step 3 (release-notes D6 bullet): "so the rule is insurance, not a fix for an observed fault" is a figurative phrase against Global Constraint 9 (plain English, no idioms); fixed text vs plan text → "so the rule prevents a possible fault; it does not fix an observed one." ← 3/3: r1:M1, r2:M2, r3:M1
- [M2] rejected: out of lens scope — Task 1 Step 2 and Task 2 Step 2: the Expected FAIL lists omit FAIL lines the old scripts also produce (the five `git status shows no change` checks; the (6) standard-error and no-file checks); an accuracy issue of a verification line, not a conflict between two sides ← 1/3: r2:M1

## Round 1 — Correctness & completeness — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 1 Important, 2 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 4 Step 3 (c), Contract and Step 1: the Resume step 2 sentence routed an exit-3 task to step 3 only; when the resume prompt answers that the branch is repaired, step 3 records the answer and step 4 plus the Batch Loop's normal flow would record a new BASE and dispatch an implementer, against the **Exit 3** paragraph (verified at SDD `SKILL.md:426-435`, `:287`) → appended "When the resume prompt answers that the branch is repaired, step 3 records the answer, and the task resumes at its task review from the journaled BASE, by the **Exit 3** paragraph, before step 4: record no new BASE and dispatch no implementer for it."; added a folded needle on the Resume Procedure extract; Contract and Step 2 Expected updated ← 2/3: r2:M3, r3:I1
- spec deviation: the plan's Resume Procedure step 2 text adds a second sentence that routes an answered exit-3 question to the task review from the journaled BASE before step 4 — spec: section 4.3.2 appends only the sentence ending "step 3 handles its entry." (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/specs/upstream-v7-fixes-design.md) — kept because the spec text alone lets step 4 record a new BASE and re-dispatch the implementer, which the spec's own **Exit 3** paragraph forbids
- [M1] applied — Assumptions, sequencing bullet: incomplete and partly wrong list of tasks that share files → replaced by "Tasks 1-13 run one after another, in numbered order; no task of this plan runs in a parallel wave" with the full list of shared files ← 3/3: r1:M2, r2:M1, r3:M1
- [M2] applied — Task 1 Step 2 and Task 2 Step 2: Expected FAIL lists omitted the five `git status shows no change` checks and the (6) standard-error and no-file checks, and gave a wrong reason for (6) → lists completed; reason now "a tree as BASE exits 0 and writes a package, a blob as HEAD exits 129 after the OUTFILE was created" ← 3/3: r1:M1, r2:M2, r3:M2
- [M3] applied — Task 11 Contract: invariant "no file holds `Use Claude Code or GitHub Copilot CLI.`" cannot hold (the spec and older documents quote it) → limited to `README.md`, `docs/platforms/codex.md` and `.codex/INSTALL.md` ← 1/3: r1:M3

## Round 2 — Ambiguity & testability — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 6 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 4 Minor
**Sources mapped:** 12/12
**Reviewer verdict:** 0 Critical, 0 Important, 8 Minor
**Converged:** no

### Dispositions
- [M1] applied — Task 11 Contract and Step 4: the `README.md:14` and `:461-463` rows had no check → Step 4 gains a folded count of "Copilot CLI and Codex are no longer supported" and "(no longer supported since 2026-10-21) was last used with v7.13.0", each expected `1`; Contract Verification updated ← 3/3: r1:M3, r2:M2, r3:M4
- [M2] applied — Task 13 Step 7: `git status` ran in the current checkout, not in the main checkout that Steps 5-6 edit → recomputes MAIN and runs `git -C "$MAIN" status --porcelain -- docs/orchestration-issues.md` ← 2/3: r1:M6, r3:M3
- [M3] applied — Task 12 Step 1: the plan did not say whether the `> ` prefix of the four guide passages is inserted → "Insert each passage as a plain paragraph, without the `> ` prefix" (spec section 4 quoting convention) ← 2/3: r2:M1, r3:M2
- [M4] applied — Task 2 Step 1 test (2): the Contract clause "`sdd-workspace` is not called" could not fail → added a check that `$RG_REPO/.superpowers` does not exist after the exit-3 call without OUTFILE ← 1/3: r1:M1
- [M5] applied — Task 4 and Task 10 Step 1: the main prohibitions were not pinned → added needles 'Never dispatch the task reviewer for that range' (Task 4) and 'Dispatch no task reviewer and no implementer for that range' (Task 10); Task 10 Step 2 Expected now eleven FAIL lines ← 1/3: r1:M2
- [M6] applied — Task 1 Steps 2 and 4, Task 2 Step 4: Expected claimed suite exit codes that a pipe into `grep`/`tail` hides → exit-code claims removed; the `Results:` line is the check ← 1/3: r1:M4
- [M7] applied — Task 12 Step 1 (a): "Since v7.74.0 that review writes …" can be read as the `executing-plans` critical read that the guide paragraph names just before → "Since v7.74.0 the Pre-Flight Plan Review writes …" (guide lines 314-321 checked) ← 1/3: r1:M5
- spec deviation: the §3 Stage 2 guide passage starts "Since v7.74.0 the Pre-Flight Plan Review writes what it compared" — spec: section 4.10 gives "Since v7.74.0 that review writes what it compared" (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/specs/upstream-v7-fixes-design.md) — kept because the guide paragraph's last sentences name the `executing-plans` critical read, so "that review" points at the wrong review
- [M8] applied — Task 5 Contract Invariants: "the three run-mode rules … stay" named an orchestrated rule that the section does not hold (SDD `SKILL.md:203-216` checked) → "the interactive batched-question paragraph and the Batched Autonomous Mode blocker sentence stay (the orchestrated rule lives in `batch-controller-prompt.md:150-159`, outside this section, and does not change)" ← 1/3: r3:M1

## Round 3 — Feasibility & architecture risk — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** yes

### Dispositions
- [M1] applied — Assumptions, first bullet: line numbers of a later step of the same task (Task 8 (b), Task 10 (b), Task 12 (b)-(d)) point at moved lines after an earlier step of that task → the bullet now says every line number inside a task is that of `fb222d38` and such a step locates its place by the quoted text ← 2/3: r1:M2, r3:M1
- [M2] applied — Task 11 Step 4: the guide check `grep -cF 'GitHub Copilot CLI and Codex are no longer supported'` ran on unfolded text, although the §1 parenthetical wraps across lines 33-34 → the guide is folded first, as for the README phrases ← 2/3: r2:M1, r3:M2
- [M3] applied — Task 2 Contract Output: for a tree or blob BASE/HEAD, `git rev-parse --verify --quiet "<arg>^{commit}"` still prints git's own `error: … expected commit type …` line before `bad BASE:` (verified with git 2.50.1 in a scratch repository) → Contract now says `bad BASE:`/`bad HEAD:` is the last line of standard error and names git's preceding line; the spec's code lines are kept ← 1/3: r1:M1

## Readiness post 1 — Execution readiness — claude-opus-5-5
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 0 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 0 Important, 0 Minor
**Sources mapped:** 2/2
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor

### Dispositions
- [M1] applied — Task 5 Step 3 (replacement Pre-Flight section): the section that Task 5 writes in full keeps the figurative sentence "The review loop remains the net for conflicts that only emerge from implementation.", against Global Constraint 9 (plain English, no idioms); no test pins it (`grep -rn` over `tests/` finds nothing); fixed text vs plan text → "The review loop still catches conflicts that appear only during implementation." ← 1/3: r2:M1
- spec deviation: the replacement Pre-Flight section says "The review loop still catches conflicts that appear only during implementation." — spec: section 4.5 keeps "The review loop remains the net for conflicts that only emerge from implementation." (/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/specs/upstream-v7-fixes-design.md) — kept because Global Constraint 9 (the user's plain-English instruction) forbids figurative wording in text the task writes, and the sentence is pinned by no test
- [M2] rejected: out of lens scope — Task 2 Step 1 test (2): the new comment says "Tests (1) and (3) pass OUTFILE, so no call before this one creates the workspace", but test (3) runs after this check; a comment accuracy issue, not a conflict (fixed in the host self-review below as a merge-introduced issue) ← 1/3: r2:M2

Note: reviewer r3's first report carried coverage lines for GC1-GC8 only (the plan has nine entries), so it was unusable; the identical dispatch was retried once and the retry is the r3 report counted above.

Self-review (writing-plans Self-Review checklist, after the post-sequence):
- spec coverage: every requirement of spec sections 2, 4.1-4.10, 6 and 7.1 has a task; the memory-file update of section 9 is outside the repository and named in Task 13 "Does NOT cover" — no gap.
- placeholder scan: no TBD/TODO/"implement later"/"Similar to Task" patterns.
- type and name consistency: needles, variables and helper names agree across Tasks 1-13.
- scope-reduction scan: the only hits are "placeholder legend" (the name of a template section), not a scope downgrade.
- contract audit: 13 tasks, 13 `**Contract:**` fields, no `**Exact content:**` marker, no false `none`; every Global Constraints entry traces to the spec or to the user's plain-English instruction and restates no artifact body.
- merge-introduced fix: Task 2 Step 1 test (2) comment said "Tests (1) and (3) pass OUTFILE, so no call before this one creates the workspace"; test (3) runs later → "Test (1) and the first call of test (2) pass OUTFILE, so no call before this one creates the workspace" (introduced by round 2 [M4]; reported by readiness post 1 r2:M2).
**Host self-review:** done

_Loop complete — 2026-10-21 — rounds 3_
