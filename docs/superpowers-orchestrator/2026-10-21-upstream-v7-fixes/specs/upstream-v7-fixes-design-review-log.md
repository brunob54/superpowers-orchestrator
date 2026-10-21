# Review log — upstream-v7-fixes-design.md

_Invocation 1 — 2026-10-21 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 6 Minor | r2: 0 Critical, 3 Important, 6 Minor | r3: 0 Critical, 3 Important, 5 Minor
**Sources mapped:** 27/27
**Reviewer verdict:** 0 Critical, 5 Important, 10 Minor
**Converged:** no

### Dispositions
- [I1] applied — §4.3.2/§4.3.3: a task that legitimately makes no commit had no completion path after exit 3 → no-commit DONE skips review-package with ledger lines `Task N: complete (no commit at <head7>: <reason>)` + `Minor:`; batch return form; Deviation 6 exception; exit 3 after a reported commit → one implementer re-dispatch, then BLOCKED ← 3/3: r1:I1, r2:I1, r3:I2
- [I2] applied — §4.7/§4.4/§6: reviewer "pristine output" rule and DONE_WITH_CONCERNS cancelled C9 → task-reviewer sentence, ledger `Minor:` line, not a batch blocker, TDD checklist reworded ← 3/3: r1:I2, r2:I2, r3:I1
- [I3] applied — §4.3.2/§6/§4.10: multi-code-review exit 3 control flow undefined → fatal case, returns `BLOCKED: review range invalid — <error line>`, no round entry ← 3/3: r1:I3, r3:I3, r2:M1
- [I4] applied — §4.6: D6 sentence broke the exact "MUST include" worker sentence → SDD templates place it after "Your only job…"; review templates after "Do NOT use the Skill tool." ← 2/3: r1:I4, r3:M4
- [I5] applied — §4.7: C9 wording forbade tasks whose purpose is to fix the failing test → limited to tests outside the task ← 1/3: r2:I3
- [M1] applied — §4.3.1: tree/blob BASE gave exit 3, not 2 → `^{commit}` checks, test (6) ← 3/3: r1:M5, r2:M6, r3:M3
- [M2] applied — §7.1: D4 negative needle did not match upstream's sentence → `Rule on everything you find`, `record each ruling in the ledger`; controller kept `Rule on each conflict` too (upstream line 179 holds it) ← 2/3: r2:M2, r3:M2
- [M3] applied — §4.10: Effect line "Nothing to migrate" contradicted §9 → names the one-time restore ← 2/3: r1:M4, r3:M1
- [M4] applied — §4.4: how the controller resolves an unreadable-evidence item → Read the evidence file; else send the task back ← 2/3: r1:M3, r2:M5
- [M5] applied — §4.7 Change 2: "Relevant suite passes" contradicted the new item → reworded (with I2) ← 1/3: r1:M1
- [M6] applied — §2 Non-goals: "no deletion of Copilot text" contradicted §4.8 → reworded ← 1/3: r2:M3
- [M7] applied — §4.9: "absent" in a linked worktree → main checkout found via `git rev-parse --git-common-dir` ← 1/3: r2:M4
- [M8] applied — §2 Non-goals: fix subagents get no C9 rule → non-goal with reason ← 1/3: r1:M2
- [M9] applied — §4.1/§8: archive_workspace moves a committed progress.md → accepted consequence ← 1/3: r1:M6
- [M10] applied — §2 Non-goals: docs/research/claude-code-mods.md:361 Copilot sentence stays (dated research document) ← 1/3: r3:M5

## Round 2 — Ambiguity & testability — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 7 Minor | r2: 0 Critical, 2 Important, 7 Minor | r3: 0 Critical, 1 Important, 6 Minor
**Sources mapped:** 26/26
**Reviewer verdict:** 0 Critical, 4 Important, 9 Minor
**Converged:** no

### Dispositions
- [I1] applied — §3/§4.3.2/§6/§8: "no commit SHA" trigger undefined for sequential implementers (wave-only rule) → git decides: HEAD = recorded BASE; general `Commits created: none — <reason>` rule on the return field (moving the wave rule would break pinned `## Commit Messages` and the `current HEAD|1` count) ← 2/3: r2:I1, r3:I1
- [I3] applied — §4.7/§6/§8: "code that the test covers" undefined → "files the failing test imports or calls directly"; ⚠️ item when not decidable; "writes or changes" clarification in implementer and TDD text ← 3/3: r1:I3, r2:M3, r3:M2
- [I2] applied — §4.3.2/§4.3.3/§6: exit-3 re-dispatch "make or name" ambiguous → with the git trigger exit 3 in SDD means non-descendant only; straight to BLOCKED; re-dispatch removed; remedies 1-3 do not apply ← 2/3: r1:I1, r2:I2
- [I4] applied — §4.3.2/§6: second report still without a reason → BLOCKED (settled with I1) ← 3/3: r1:I2, r2:M4, r3:M1
- [M1] applied — §4.7 Change 4/§6/§8: no-commit vs C9 precedence → no-commit path wins; C9 `Minor:` line follows; claim goes unchecked to the final review ← 2/3: r1:M1, r2:M5
- [M3] applied — §4.5: "interface" undefined in the D4 table → row trigger and `Compared` cell defined; table completeness not tested ← 3/3: r1:M3, r2:M2, r3:M3
- [M5] applied — §7.1: range-guard needles and fixtures ambiguous → fixture commits C0–C5, SIDE, M with full SHAs; backslash escapes removed ← 3/3: r1:M5, r2:M6, r3:M6
- [M6] applied — §4.1/§4.2/§4.3.1/§4.9/§5: external claims without source → cited (gitignore(5), git-rev-parse(1), git 2.31 notes, Claude Code docs, Microsoft docs); A12 labelled unverified; annotated-tag test (7) added ← 3/3: r1:M6, r2:M1, r3:M5
- [M2] applied — §3: `<head7>` before or after the tick commit → HEAD when the implementer returned, before the tick commit ← 1/3: r1:M2
- [M4] applied — §4.7 Change 3: C9 finding severity unnamed → `#### Important (Should Fix)` ← 1/3: r1:M4
- [M7] applied — §4.9: "release report" undefined; "five lines" → named; "five entries" ← 1/3: r1:M7
- [M9] applied — §4.3.2: connective line inside the "exactly" return block → "exactly one of these two forms" ← 1/3: r2:M7
- [M8] applied — §4: blockquote insertion convention unstated → convention stated ← 1/3: r3:M4

## Round 3 — Feasibility & architecture risk — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 2 Important, 5 Minor | r3: 0 Critical, 1 Important, 2 Minor
**Sources mapped:** 13/13
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §3/§4.3.2/§6/§8: a re-recorded BASE (crash recovery, BLOCKED re-dispatch) let earlier commits skip review on the No commit path → BASE recorded once per task, never again; batch controller uses REVIEW_BASE when Deviation 4 builds the task's package from it (decided wording adjusted: Deviation 4 sets REVIEW_BASE for every unchecked task but uses it only when earlier commits exist) ← 1/3: r3:I1
- [I2] applied — §4.3.2/§6/§8: the second return was decided by its text → git compared again: HEAD ≠ BASE → review-package; HEAD = BASE with reason → No commit; else BLOCKED ← 1/3: r2:I1
- [I3] applied — §4.3.2/§4.3.3/§4.10/§6/§8: orchestrated exit 3 became an in-run ruling item that no ruling can repair → `BLOCKED task=<n>: review range invalid — <error line>` with no question section: a controller failure, one identical retry, then the Major-Error Stop Policy ← 1/3: r2:I2
- [I4] rejected: fix-prompt.md (pinned by FIX_RULE_CLAUSES) stays out of scope; the stop is loud and loses no work — §2/§8: a branch-carried failing test makes a Phase 4 fix subagent restore and stop → non-goal rationale corrected, accepted limit added as §8 item 8 (an unresolved item is ruled on or escalated) ← 1/3: r1:I1
- [M1] applied — §4.3.2/§6: orchestration log batch heading had no rule for no-commit tasks → range of committing tasks, `— no commits` when none, per-task no-commit line ← 3/3: r1:M1, r3:M2, r2:M3
- [M2] applied — §4.3.2/§4.3.3/§6/§8: amend or rebase also causes exit 3 → named; no ban added (phrase-count pins) ← 2/3: r1:M2, r2:M1
- [M3] applied — §7.1 test (6): `<C5>:g.txt^{commit}` is read as a path → blob object ID; tree case peels correctly, kept ← 1/3: r3:M1
- [M4] applied — §8 item 2: forgotten edits can be committed by a later sequential task (no `git add -A` ban outside a wave) → reworded ← 1/3: r2:M2
- [M5] applied — §4.5: one row per task pair grows quadratically in a ledger read whole → one row per shared file or name, listing every task ← 1/3: r2:M4
- [M6] applied — §7.1: fixture assumed branch `main` → `git -c init.defaultBranch=main init` ← 1/3: r2:M5

## Round 4 — Adversarial failure modes — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 2 Minor | r2: 0 Critical, 3 Important, 2 Minor | r3: 0 Critical, 3 Important, 5 Minor
**Sources mapped:** 19/19
**Reviewer verdict:** 0 Critical, 5 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §4.3: the No commit path accepted any reason; staged task edits were swept into the unscoped batch tick commit with no review → user decision 2026-10-21: no-commit path removed; an empty range is exit 0 with `Commits in range: none` in the package header and the task reviewer always runs ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — §4.7: "not caused by its change" judged per task, so a branch regression became a carried Minor line and did not end the batch → user decision: C9 back to one sentence; the controller never accepts such a concern alone (ask the user / end the batch / BLOCKED with a Question) ← 3/3: r1:I2, r2:I3, r3:I2
- [I3] applied — §4.3.2/§4.10: the retried batch controller computes a fresh valid range and does not stop → batch controller checks at start that the last ledger head is an ancestor of HEAD, else the same `review range invalid` BLOCKED ← 3/3: r1:I3, r3:I3, r2:M1
- [I4] applied — §3/§4.3.2: BASE lived only in controller memory; after compaction earlier commits skipped review via the No commit path → moot with the no-commit path removed; an empty package after a lost BASE is today's visible failure, noted in §8 ← 3/3: r2:I2, r1:M2, r3:M4
- [I5] applied — §4.3.2: a verification-only task skipped the only reader of its evidence → moot: the task reviewer always runs ← 1/3: r1:I4
- [M1] applied — §3: `<head7>` excluded fix-subagent commits → removed with the no-commit forms, or defined as after the last implementer or fix commit ← 1/3: r1:M1
- [M2] applied — §4.2: the A17 `printenv` line is refused by protect-secrets for secret-like names → `[ -n "${VAR:-}" ]` form or a recorded limit ← 1/3: r3:M1
- [M3] applied — §4.1/§4.10: a committed progress.md stops orchestrated runs at a boundary → one sentence in the guide and release prose ← 1/3: r3:M2
- [M4] applied — §4.9: the append to the untracked issues log was not idempotent → skip when an `(upstream A10)` entry exists ← 1/3: r3:M3
- [M5] applied — §4.5: table cells could be misread as completion lines → table kept in the ledger only if readers match line starts (rows start with `|`); otherwise its own file ← 1/3: r3:M5
- [M6] applied — §4.1: a zero-length .gitignore was never repaired → `[ -s ]` ← 1/3: r2:M2

_Invocation 2 — 2026-10-21 — N=2 M=3 — gate: brainstorming_

## Round 5 — Correctness & completeness — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 3 Minor | r2: 0 Critical, 3 Important, 2 Minor | r3: 0 Critical, 3 Important, 4 Minor
**Sources mapped:** 18/18
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §4.7/§4.3.2: a batched C9 or exit-3 stop leaves committed, unreviewed work that Resume step 2 ticks as implemented → C9 decision path removed (user decision 2026-10-21: C9 is the implementer sentence only); the exit-3 journal entry records the task, its BASE and "implemented, not reviewed", and Resume step 2's shortcut never applies to it ← 3/3: r1:I1, r2:I2, r3:I1
- [I2] applied — §4.7: no path for an answer other than "accept"; the implementer rule forbade the fix → moot: decision path removed; the existing concern and reviewer rules apply ← 3/3: r1:I2, r2:I1, r3:I2
- [I3] applied — §4.7: scope of an answer across tasks undefined → moot: decision path removed ← 3/3: r2:I3, r3:I3, r1:M2
- [I4] applied — §4.3.2/§4.10/§8: the start check stops on a ledger left from an abandoned or earlier run and blames the branch → check runs after sdd-workspace; reason and guide name both causes and both repairs; restart-after-abandon is an accepted limit ← 2/3: r1:I3, r2:M2
- [M1] applied — §4.7: wave implementers would raise questions about siblings' transient failures → moot: decision path removed ← 2/3: r1:M1, r2:M1
- [M2] applied — §4.4: "append" conflicts with implementers rewriting the report file → "write" ← 1/3: r1:M3
- [M3] applied — §4.7: `accept` cited as a Phase 3 ruling verb (it is Phase 4 only) → claim removed with the decision path ← 1/3: r3:M1
- [M4] applied — §4.10: the start check gave no hint to remove stale ledger lines after a reset → both repairs named ← 1/3: r3:M2
- [M5] applied — §4.3.2: interactive exit 3 had no continuation and left BLOCKED remedies open → only the per-mode rule applies; after a confirmed repair the same `review-package BASE HEAD` runs again ← 1/3: r3:M3
- [M6] applied — §4.7: the C9 sentence did not say to commit → "commit your work as usual" ← 1/3: r3:M4

## Round 6 — Ambiguity & testability — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 6 Minor | r2: 0 Critical, 1 Important, 4 Minor | r3: 0 Critical, 2 Important, 6 Minor
**Sources mapped:** 20/20
**Reviewer verdict:** 0 Critical, 2 Important, 9 Minor
**Converged:** no

### Dispositions
- [I1] applied — §4.3.2/§6/§4.10: the batched exit-3 resume had no confirmation path (entry not a question; step 2 ran before step 3) → entry is a blocking question "Is the branch of task N repaired? …"; step 2 neither ticks nor reviews it; after the answer, review with the journaled BASE, no new BASE, no implementer; a repeated exit 3 asks again ← 3/3: r2:I1, r3:I1, r1:M3
- [I2] applied — §4.7/§4.10: a C9 concern fitted both branches of DONE_WITH_CONCERNS → implementer names it as an observation, not a doubt about its work (unless the brief or dispatch names the test); controller proceeds to review, the reviewer decides ← 3/3: r1:I1, r3:I2, r2:M2
- [M1] applied — §4.5: open list of name kinds; `Found` vs conflict undefined; two terms for a path → a name the text of two or more tasks mentions; non-`none` `Found` is a conflict; one term ← 3/3: r1:M1, r3:M4, r2:M3
- [M3] applied — §3/§4.1/§4.3/§7.1: git and shell claims without a source → cited or labelled measured (date, git version) ← 2/3: r1:M4, r3:M6
- [M5] applied — §4.8: guide sentence read as "all five no longer supported" → split ← 2/3: r1:M6, r3:M5
- [M8] applied — §4.7: "did not cause" had no criterion → the test neither is nor imports a file the task changes; concern carries the output and reason; main-session "your task" defined ← 2/3: r3:M3, r2:M1
- [M2] applied — §4.5: scan on an existing preflight.md → scan still runs, only the write is skipped ← 1/3: r1:M2
- [M4] applied — §1/§5: figures without method → source, method and conversion named, or labelled estimate ← 1/3: r1:M5
- [M6] applied — §4.3.2: "below" pointed to two places → "in the rest of this paragraph" ← 1/3: r3:M1
- [M7] applied — §4.4: focused-test permission for unreadable evidence → reviewer reports ⚠️ and runs no test ← 1/3: r3:M2
- [M9] applied — §7.1: sdd-workspace fixture contents unnamed → plan files and minimum content named ← 1/3: r2:M4

Host self-review (brainstorming Spec Self-Review) after round 6: no placeholders; prior-art sentence present once as body text; no text of the removed no-commit path or C9 decision path remains; headings at 821, 840, 1223 are inside quoted blocks. No fix needed.
