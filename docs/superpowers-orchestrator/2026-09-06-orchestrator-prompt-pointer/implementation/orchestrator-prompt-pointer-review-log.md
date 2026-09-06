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

## Round 2 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 2 Minor | r2: 0 Critical, 2 Important, 4 Minor
**Sources mapped:** 11/11
**Reviewer verdict:** 0 Critical, 4 Important, 6 Minor
**Converged:** no
### Dispositions
- [I1] fixed — a Resume inside the session that stopped conflicted with "mktemp -d once per session"; Resume step 3 now always creates a fresh directory and the Dispatch Rules read once per orchestration invocation → 4929739 ← 2/2: r1:I3, r2:I1
- [I2] fixed — a value file found wrong before its first dispatch could not be written again (the Write tool refuses an existing file it has not read) and the fatal row classified that refusal as a mechanism failure; the file is now removed with rm before it is written again and a new not-mechanism row covers the case → 4929739 ← 1/2: r1:I1
- [I3] fixed — every rm of a prompt-directory file must double-quote the path because block-dangerous-commands denies an unquoted rm of a path under /var; stated at both rm rules, and a new not-mechanism row re-issues a hook-denied rm once, quoted → 4929739 ← 1/2: r1:I2
- [I4] user-decision — the withheld replacement for a secret-refused answer line keeps id, tag and location but drops the ruling verb, so a ruling that quotes a secret-shaped plan clause is recorded as decided with no decision (plan-mandated) — at skills/orchestrating-development/SKILL.md:2143 — clause: Task 4 "Must convey: every failure of the mechanism is fatal (log entry owed, `## STOPPED` with the fixed cause text as the heading's one-line reason, `state.md` rewrit" ← 1/2: r2:I2
- [M1] fixed — "the case of every first batch" read as a rule for a re-dispatched first batch that carries answers; now "a batch dispatched before any answer is recorded" → 4929739 ← 1/2: r1:M1
- [M2] fixed — "as every phase does" was wrong for Phase 2, whose template has no [RESUME_ANSWER] placeholder; now "as Phases 1, 3 and 4 do" → 4929739 ← 1/2: r1:M2
- [M3] fixed — the ls recovery of <k> now takes the numerically largest number, not the last line ls prints → 4929739 ← 1/2: r2:M1
- [M4] carried — a checkout path holding an apostrophe breaks the single-quoted NAME= values at the first fill; the Global Constraints fix the quoting form, so an escape or a Phase 0 precondition is a later decision ← 1/2: r2:M2
- [M5] fixed — the probe file is removed only after outcome (a); a refused probe leaves no file to remove → 4929739 ← 1/2: r2:M3
- [M6] fixed — the idempotence paragraph now says its retry is a resume after a crash in a fresh directory, never the in-session identical retry; both pinned phrases kept → 4929739 ← 1/2: r2:M4

