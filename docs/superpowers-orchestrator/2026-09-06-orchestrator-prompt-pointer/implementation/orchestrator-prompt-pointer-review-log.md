# Code review log — orchestrator-prompt-pointer

_Invocation 1 — 2026-09-06 — N=2 M=2 — BASE..HEAD 582763a..33437c6 — branch feature/orchestrator-prompt-pointer — gate: orchestration_

## Round 1 — Correctness & spec alignment — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 1 Important, 1 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no
### Dispositions
- [I1] fixed — fatal-table cause texts could carry the prompt-directory path into the orchestration log; the boundary paragraph now writes it as <PROMPT_DIR>/<file name> (reviewer's plan-mandated tag dropped: the fix upholds the Global Constraint and keeps every cause text verbatim) → eb9293b ← 1/2: r1:I1
- [I2] fixed — the four Agent description strings had no source outside the template wrappers the orchestrator never reads; the file-name table now carries them and Phase 1, Phase 3 and the Dispatch Rules point at it → eb9293b ← 1/2: r2:I1
- [M1] fixed — "<k> is never reused" contradicted the rm-and-refill path; qualified to once a pointer has been dispatched → eb9293b ← 1/2: r1:M1
- [M2] fixed — lost-path rule and the not-mechanism row now say the value file is written again in the fresh directory first → eb9293b ← 1/2: r1:M2
- [M3] fixed — exit 5 file-already-exists on a name whose pointer was never dispatched is a corrected-once slip (new not-mechanism row); the fatal row is unchanged → eb9293b ← 1/2: r2:M1
- [CF1] fixed — same subject as [I1], resolved by that fix → eb9293b
- [CF2] carried — mirrored secrets-hook rule differs from multi-code-review's copy in file name and verb, no tie test (ship-as-is, both reviewers; plan-mandated mirror)
- [CF3] carried — fill-prompt suite reports 160 not the plan's reference 159 (reference counts)
- [CF4] rejected: already resolved — FILL_DOT is consumed by section 7 of the wording suite (both reviewers)
- [CF5] fixed — three folded needles for name, description and model on DISPATCH_RANGE, plus one needle per template asserting the table carries its description exactly → eb9293b
- [CF6] fixed — secrets-hook probe rule extracted into its own range and asserted free of multi-code-review/SKILL.md and of "see multi-code-review" → eb9293b
- [CF7] carried — ${2#$ROOT/} unquoted pattern; ROOT holds no glob characters
- [CF8] carried — SKILL.md grows ~176 lines, accepted by the spec; carry into the row 14 measurement
- [CF9] fixed — template_body_names uses the PLACEHOLDER_ERE constant → eb9293b
- [CF10] fixed — BATCH_NUMBER needle pins "stands only in the template's wrapper and is not passed to the script" → eb9293b
- [CF11] carried — dispatch the pointer counted over the whole phase range, not per phase
- [CF12] carried — two-character name regex; the wording suite covers the [M] regression
- [CF13] fixed — Phase 3 fill block shows 'RESUME_ANSWER=' like Phases 1 and 4; the prose keeps the @ value-file form → eb9293b
- [CF14] carried — fence-parity assert for the section 13 splitter
- [CF15] fixed — sort -u and the four expected template names compared as a set → eb9293b
- [CF16] fixed — needle "exactly as step 3 creates it" on RESUME_RANGE → eb9293b
- [CF17] fixed — Write-tool and 'RESUME_ANSWER=' needles on RESUME_RANGE; Write-tool and @-form needles on INRUN_RANGE (the In-run text has no empty-form sentence because a re-dispatch there always carries answers) → eb9293b
- [CF18] carried — ragged wrapping from the reference blocks
- [CF19] carried — directory-creation sentence sits in the "A stop that made no ruling" paragraph; scope unchanged per both reviewers

