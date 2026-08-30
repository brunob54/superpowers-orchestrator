# Review log — reviewer-harness-claims-design.md

_Invocation 1 — 2026-08-30 — N=2 M=1 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5
**Reviewer verdict:** 0 Critical, 5 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — §3 step 2 / Approaches: `unresolved` blocks the host gate exactly as `user-decision` did in Case 003 → the "not runnable here" branch is now `rejected: harness probe not runnable here — <probe>` in both skills (non-blocking, the existing "reject as unverifiable" path), plus a `Harness probes owed:` line in each completion report
- [I2] applied — §3 / Interfaces: deferring a Critical/Important contradicts multi-doc-review's triage sentence → harness branch uses only `rejected:`; Scope names the triage-sentence amendment and the completion-report line
- [I3] applied — §1: the canary note lives in the `description:` comment, outside `prompt: |`, unreachable by the reviewer → model probe inlined in the rule
- [I4] applied — §1 vs §3: first-probe result on a multi-probe claim could support it → reviewer tags `not settled by one probe; first: <probe>`, controller takes the not-runnable branch
- [I5] applied — §3 step 3 / Failure mode 1: guard had no action for an untagged premise → controller names and runs one probe itself, else not-runnable with reason `no probe named`; Approach 3 text reconciled (backstop, not primary)
- [M1] applied — Testing 1: rule line must be greater than the `prompt: |` line, not only lower than the fence
- [M2] applied — Testing 5: `    ### Harness claims` heading, extraction to the next `^    ## ` line
- [M3] applied — Testing 4: exact guard fragment given
- [M4] applied — §3 step 2: observation recorded as `— harness probe: <observation>` before the source annotation; fixer does not receive the field
- [M5] applied — §3 step 1: controller probe constraints stated directly
- [M6] applied — §2: both reference sentences named
- [M7] applied — §1: a focused test is never a probe; condition (c) governs harness claims
- [M8] applied — §3: a `tested` observation from a non-reviewer-safe probe is accepted, with `(reviewer probe not reviewer-safe)` noted on the disposition line

## Round 2 — Ambiguity & testability — claude-fable-5
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §1 / Definitions (c): drift-compared rule text referred to the code template's `## Tests` section and to "the branch under review" → wording made template-neutral ("any allowance elsewhere in the prompt", "the change under review")
- [I2] applied — §3 step 1 vs §1: the `not settled by one probe` tag would be run as a normal probe → step 1 excludes it explicitly; its `first:` probe fills the owed line only
- [I3] applied — Error handling: "deferred / unresolved" parenthetical contradicted §3 → replaced with the `rejected: harness probe not runnable here` disposition
- [I4] applied — §3 step 1: no rule for deciding whether a dispatch-based probe will block → dispatch rule added (main session or a prompt-stated `name:`; otherwise not runnable, reason `dispatch would not block`); "rung" reworded
- [M1] applied — Definitions: probe = one command, one dispatch, or one read of own context; ambiguity criterion given
- [M2] applied — §3: owed line shape fixed (heading line + one item per rejection, `none` when empty, always written)
- [M3] applied — Testing 1/5 and §1: closing fence named; placement rule (last sub-section under Subagent Rules) added
- [M4] applied — Failure mode 4: ≤ 15 lines is a guideline no test asserts
- [M5] applied — §3 step 3: guard applies to carried-findings `user-decision` too
- [M6] applied — Approaches 1: "platforms without the Agent tool" labelled (degradation rung 3; platforms not asserted)

_Cap reached after 2 rounds (N=2); neither round clean._
