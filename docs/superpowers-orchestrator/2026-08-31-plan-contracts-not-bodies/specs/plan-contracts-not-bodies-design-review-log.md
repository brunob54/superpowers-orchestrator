# Review log — plan-contracts-not-bodies-design.md

_Invocation 1 — 2026-08-31 — N=2 M=1 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5
**Reviewer verdict:** 0 Critical, 4 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — R4/R1/R2/R5: procedural fences (commit blocks, Run: lines) satisfy neither branch of the R4 dichotomy, and `Contract: none` tasks fail check 5 → R4 gains a third bucket (procedural step blocks exempt under R1 rule 3's default); R1 rule 1 exempts procedural blocks; R5 target 1 scoped to artifacts the task creates or modifies; new boundary sentence 6(d) gives `none` tasks the rule-3 default.
- [I2] applied — Non-goals bullet 1: "every reviewer reads the plan" is false (multi-code-review passes the plan on lens-1 rounds only; SDD reviewers get Global Constraints only) → bullet rewritten to name the real route: the controller performing plan-mandated triage consults the plan and meets the R3 header note there.
- [I3] applied — Non-goals bullet 2: "5 of the 6 historical stop-items" not reconstructible → replaced with a full enumeration of the eleven items in Cases 001/003/007/008: eight convert (named per item id), two remain genuine stops (Case 003 R6 [I2], Case 007 v2/v3 [I3]), one already addressed by 7.6.0's harness-claims mechanism (Case 003 R6 [I1]).
- [I4] applied — Non-goals bullet 3 contradicted R5 for pre-existing plans reviewed under the updated lens → R5 targets now conditioned on the plan carrying the R3 authority note; non-goal rewritten to state the scoping.
- [M1] applied — R1 rule 1: multi-artifact tasks hold one contract entry per artifact (list form) or the task is split.
- [M2] applied — R6: "case-insensitively, per the repository's assertion rule" dropped; binding labels match exactly and case-sensitively (`grep -F`, as the reviewer-templates suite does); free-text fragments may match case-insensitively.
- [M3] applied — new boundary sentence 6(c): non-task, non-Global-Constraints plan content follows the reference default.
- [M4] applied — R1 rule 5 extended: a pre-existing pin whose assertion the same plan edits is a self-pin; only a pin the plan leaves untouched binds; Error handling bullet updated to match.

## Round 2 — Ambiguity & testability — claude-fable-5
**Reviewer verdict:** 0 Critical, 4 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — R1 rules 1-3 vs code example: a signature written inside the Contract field was rule-2-descriptive to one reader and rule-3-binding to another → rule 2 now states that stating inputs/outputs does not pin them; the signature line is descriptive unless externally depended on, and a fix may amend signature and contract wording together as one ordinary fix; the code example gains a "not externally pinned" line.
- [I2] applied — false-`none` path unchecked → R4 treats a `none — <reason>` on a task that creates/modifies a governed artifact as a missing contract; R5 target 1 counts it as "no stated contract".
- [I3] applied — two pinned test fragments were left for the implementer to invent → bound literally: "together as one ordinary fix" (self-pin rule), "falsifiable" (Self-Review check), "self-pin" (lens cell), alongside the already-named "no stated contract".
- [I4] applied — Scope said "two reconciliation sentences", R7 defines one → Scope now says one (R7 governs).
- [M1] applied — R5 applicability predicate named: the note's test-pinned phrase "reference implementations" in the plan header.
- [M2] applied — R6 "exit non-zero on first failure" contradicted the cited suite's accumulate-then-exit behaviour → reworded to match the actual behaviour.
- [M3] applied — free-text fragments now MUST match case-insensitively (was permissive "may").
- [M4] applied — "user-approved copy" reasons must cite where the approval is recorded; uncited approval claims invalid.
- [M5] applied — procedural-block boundary given a test: creates or modifies no file named in the task's `**Files:**` list.

_Loop end: N=2 cap reached (no clean round). Post-loop self-review: fixed nothing further — see note below._

_Post-loop self-review note: one merge-introduced fix — R5 intro "the one pinned fragment" updated to "the pinned fragments" (round 2 [I3] made it two). No other issues._
