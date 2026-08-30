# Review log — reviewer-harness-claims.md

_Invocation 1 — 2026-08-30 — N=2 M=1 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-fable-5
**Reviewer verdict:** 1 Critical, 2 Important, 2 Minor
**Converged:** no

### Dispositions
- [C1] applied — Task 5 Step 1 / Task 1 / Self-Review: the guard fragment was wrapped across two lines, so section 4's line-based `grep -qF` could never match; the suite would end `18 passed, 1 failed`, not `19 passed, 0 failed` → re-wrapped the Guard item so the asserted fragment sits on one physical line, added a do-not-wrap instruction before the Task 5 Step 1 block, and added a one-physical-line note to Self-Review item 3
- [I1] applied — Task 2 Step 3: expected `Results: 8 passed, 11 failed` is wrong (4 assertions newly pass on top of the 3 section-6 passes) → changed to `Results: 7 passed, 12 failed`
- [I2] applied — Task 2 Step 4: pattern `verified 2026-08-28` never matches because the canary comment is wrapped over lines 19–20 → grep pattern changed to `2026-08-28 by dispatching`, expected `20:`, with a note explaining the wrap
- [M1] applied — Task 5 Step 2: line anchor `452–455` → `453–456` (verified against `skills/multi-code-review/SKILL.md`)
- [M2] applied — Global Constraints: "ends only in `applied`/`fixed` or `rejected` — never `deferred`" contradicted ordinary Minor triage (`deferred`/`carried` on a supported Minor claim) → constraint reworded: the branch adds no disposition; an untested claim ends in `rejected`; a supported claim takes any ordinary disposition of its severity; never `deferred`/`unresolved`/`user-decision` on an untested Critical/Important claim

## Round 2 — Ambiguity & testability — claude-fable-5
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 1 Step 3: the self-containment check `grep -nE '/dev/stdin|<\('` matched the script's own header comment (which spelled `/dev/stdin`), so the step failed on a correct file → header comment reworded to describe the constraint without spelling either token; expected result kept (`matches=1`) with a note explaining why a hit is always a real use
- [M1] applied — Tasks 4 and 5: "currently lines N–M" in steps after Step 1 refer to the unmodified file → added one sentence at the top of each task: line numbers are those of the unmodified file; locate every edit by the quoted text
- [M2] applied — Task 5 Step 7 and Task 6 Step 2: "or its equivalent all-green last lines" left the pass criterion to judgement → exact summary lines stated per suite (verified against the three scripts): `Results: <n> passed, 0 failed` (sdd-scripts), `0 failed` line (smart-compress), `Results: <n> suites passed, 0 suites failed` + `All unit tests passed.` (codex)
- [M3] applied — Task 5 Step 1: `harness probe not runnable here` was wrapped across two lines in the "not runnable here" branch (the suite still passed through two other unwrapped occurrences) → re-wrapped so that occurrence sits on one physical line, making Self-Review item 3's claim literally true

_Self-review (writing-plans checklist, run by the controller after the loop) — 2026-08-30 — spec coverage (§1–§4, Interfaces, Error handling, Testing items 1–6, CLAUDE.md line → Tasks 1–6), placeholder scan, type consistency (all asserted strings identical across Task 1 variables and Tasks 2–5 text, each on one physical line), scope-reduction scan: no merge-introduced issues found; no inline fixes needed._

Harness probes owed: none

_Loop complete — 2026-08-30 — rounds 2_
