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

## Round 2 verification 1 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
### Dispositions
- [M1] carried — the two not-mechanism rm-and-refill rows are gated only by the orchestrator's memory of whether a name was dispatched, which a compaction removes; condition them on an observable (a fill the orchestrator ran in this turn) and send any other refusal to the ls recovery, never rm ← 2/2: r1:M2, r2:M2
- [M2] carried — the ls counter recovery is unquoted, order-dependent and subject to the 50-line ls compression; use a numeric pipeline (sed, sort -n, tail) with the path double-quoted ← 1/2: r1:M1
- [M3] carried — the "not read by <controller name>" fatal row's token test also matches a marker-less BLOCKED question and a rate-limit message that other rows classify; add the four return keywords to the token list and let the environment row take precedence ← 1/2: r2:M1
- [M4] carried — the value-file correction sequence does not say to remove the prompt file filled from the wrong value, so the re-fill consumes the single file-already-exists allowance on that name ← 1/2: r2:M3

_Completed — 2026-09-06 — cap reached — HEAD 49297390bdce0c820e76eceb8f7fb5dd1e1e5358_
Secrets found: none


### Post-loop addendum — 2026-09-06 — decisions (invocation 1)
- [I4] decided (orchestrator): amend plan: Task 4 Contract "Must convey" bullet now reads "the withheld-line form keeps the answer's id, tag and ruling verb and replaces only the quoted value: `[<id>] (<tag>): <verb and its text up to the quoted value> — <file:line> — secret-bearing finding, value withheld`"; fix it: the withheld replacement in skills/orchestrating-development/SKILL.md (Major-Error Stop Policy, secrets-hook probe paragraph) keeps the ruling verb (fix it / plan governs / amend plan …; fix it / accept) and the non-secret answer text before the location, so the controller receives an actionable decision; update the wording-suite assertion that pins the withheld-line form
- [I4] fixed — the withheld replacement rule now keeps the ruling verb and the non-secret answer text up to the quoted value and states the amended Task 4 form verbatim; the wording suite pins the amended form and rejects the location-only form (verification re-review skipped: the effective HEAD had moved past the completion marker, so invocation 2 below reviews the fix) → a54f2b2

_Invocation 2 — 2026-09-06 — N=2 M=2 — BASE..HEAD 582763a..a54f2b2 — branch feature/orchestrator-prompt-pointer — gate: orchestration_

## Round 3 — Correctness & spec alignment — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 5 Minor | r2: 0 Critical, 0 Important, 5 Minor
**Sources mapped:** 10/10
**Reviewer verdict:** 0 Critical, 0 Important, 8 Minor
**Converged:** no
### Dispositions
- [M1] fixed — `${2#$ROOT/}` stripped with an unquoted glob pattern; now `${2#"$ROOT"/}` → 900596b ← 2/2: r1:M4, r2:M1
- [M2] fixed — `dispatch the pointer` was counted >= 4 over the whole Phase 1–5 range; now asserted once per phase sub-range → 900596b ← 2/2: r1:M5, r2:M2
- [M3] fixed — the Blocking-dispatch bullet still sourced `name` from the template header, against the never-read-a-template rule; now from the phase's dispatch text (Phases 1–4) → 900596b ← 1/2: r1:M1
- [M4] fixed — "the in-session identical retry … fills nothing" was absolute while the dispatch rules re-fill under <k> = 1 after a lost directory path; that exception is now stated → 900596b ← 1/2: r1:M2
- [M5] carried — the opening sentence of "Prompt files and the pointer" is one ~70-word sentence with four nested dash clauses; split into when and what ← 1/2: r1:M3
- [M6] carried — tests/fill-prompt/run-tests.sh:533 command-side name pattern is a second copy of the two-character rule with no comment saying the minimum is deliberate (CF12) ← 1/2: r2:M3
- [M7] carried — Resume step 3 states the with-answers imperative before the no-answer exception inside one ragged sentence; an empty @file yields the same prompt, so the cost is one useless Write (CF18, CF19) ← 1/2: r2:M4
- [M8] fixed — Resume step 4 said "The session's prompt directory", readable as the one already in context; now "This Resume's own prompt directory" → 900596b ← 1/2: r2:M5
- [CF1] rejected: already resolved — cause texts write the path as <PROMPT_DIR>/<file name> since eb9293b (both reviewers)
- [CF2] carried — mirrored secrets-hook rule, plan-mandated by the Global Constraint; section 3 checks it names no multi-code-review file (ship-as-is, both reviewers)
- [CF3] carried — the plan's reference test counts are reference material (ship-as-is, both reviewers)
- [CF4] rejected: already resolved — FILL_DOT is consumed by section 7 (both reviewers)
- [CF5] rejected: already resolved — name, description and model needles stand in section 1 since eb9293b (both reviewers)
- [CF6] rejected: already resolved — the probe-rule range is asserted free of multi-code-review/SKILL.md since eb9293b (both reviewers)
- [CF7] fixed — same subject as [M1] (fix-before-merge, both reviewers) → 900596b
- [CF8] carried — SKILL.md growth accepted by the spec; carry into the row 14 measurement (ship-as-is, both reviewers)
- [CF9] rejected: already resolved — template_body_names uses $PLACEHOLDER_ERE since eb9293b (both reviewers)
- [CF10] rejected: already resolved — the BATCH_NUMBER needle pins the full sentence since eb9293b (both reviewers)
- [CF11] fixed — same subject as [M2] (fix-before-merge, r1; ship-as-is, r2) → 900596b
- [CF12] carried — two-character name regex; the wording suite covers the [M] regression; a comment is polish (ship-as-is, both reviewers; see [M6])
- [CF13] rejected: already resolved — the Phase 3 fill block shows 'RESUME_ANSWER=' since eb9293b (both reviewers)
- [CF14] carried — the four-block and exact-set assertions already fail on a mis-paired fence; a parity assert is polish (ship-as-is, both reviewers)
- [CF15] rejected: already resolved — assert_same against the expected four names since eb9293b (both reviewers)
- [CF16] rejected: already resolved — needle "exactly as step 3 creates it" stands in section 8 since eb9293b (both reviewers)
- [CF17] rejected: already resolved — Write-tool and 'RESUME_ANSWER=' needles stand in section 8 since eb9293b (both reviewers)
- [CF18] carried — ragged wrapping in Resume step 3; a re-flow changes no folded pin (ship-as-is, both reviewers; see [M7])
- [CF19] carried — the directory-creation sentence now says "this step runs on every Resume"; a paragraph break would make the scope clearer (ship-as-is, both reviewers)

## Round 4 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 8/8
**Reviewer verdict:** 0 Critical, 1 Important, 6 Minor
**Converged:** no
### Dispositions
- [I1] fixed — a `cannot read value file` exit was classified fatal or recoverable by the orchestrator's memory of having written the file, so a vanished directory on a re-dispatch with answers ended the run while the same condition without a value file was recoverable; the fatal row and the two not-mechanism rows now run test -s or ls first (directory absent: lost-directory row; file absent: corrected-once slip; file present but unreadable: fatal) → 245d1ba ← 1/2: r2:I1
- [M1] carried — an inline value holding a single quote breaks the single-quoted NAME= form at the first fill (a checkout path with an apostrophe); the Global Constraints fix the inline single-quoted form, so an escape or a value-file route is a later decision (carried in invocation 1, round 2 [M4]) ← 2/2: r1:M1, r2:M2
- [M2] fixed — the fill counter <k> shares its symbol with [task <n>/<k>] and _Invocation <k>; Resume step 3 now says the file-name counter is the one that restarts at 1 → 245d1ba ← 1/2: r1:M2
- [M3] fixed — the rm-and-refill rows were gated only by memory of a dispatched name; they now run ls "<PROMPT_DIR>" before any rm and treat a file not filled in the current step as a counter slip → 245d1ba ← 1/2: r1:M3
- [M4] fixed — the counter-recovery ls was the one prescribed command with an unquoted path; now ls "<PROMPT_DIR>" → 245d1ba ← 1/2: r2:M1
- [M5] fixed — the prompt-directory cause text had no error text for a path printed under the repository root; that case now names its text in Phase 0 and in the fatal row → 245d1ba ← 1/2: r2:M3
- [M6] carried — the Phase 3 fill block shows 'RESUME_ANSWER=' while the steady state after a ruling is the @ form; the empty form was chosen in invocation 1 round 1 [CF13] to match Phases 1 and 4, and the prose under the block states when the @ form replaces it ← 1/2: r2:M4

## Round 4 verification 1 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 3 Minor | r2: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 1 Important, 4 Minor
### Dispositions
- [I1] fixed — the round-4 rm-and-refill row still ended "as is the first on a name whose pointer was already dispatched" while its handling column recovered exactly that case by ls; the row now applies on any name and the ls result decides, and the fatal row keeps only a second file-already-exists on the same name after the renumbering → 634e7b7 ← 1/2: r1:I1
- [M1] fixed — test -s cannot tell a missing value file from a missing directory; the two cannot-read rows now key on ls "<PROMPT_DIR>" alone, and test -s stays only in the fatal row's present-but-unreadable case → 634e7b7 ← 2/2: r1:M1, r2:M2
- [M2] carried — an inline value holding a single quote breaks the single-quoted NAME= form, and bash's own exit 2 could be read as the script's exit 2; the Global Constraints fix the inline single-quoted form, so an escape, a value-file route or a shell-error slip row is a later decision (carried in invocation 1 round 2 [M4] and round 4 [M1]) ← 2/2: r1:M3, r2:M1
- [M3] fixed — a plain ls listing over 50 entries is compressed alphabetically and can drop the largest dispatch-<k> name; the counter recovery and both counter-slip rows now use ls -1 | sort -t- -k2,2n | tail -n 1 → 634e7b7 ← 1/2: r1:M2
- [M4] carried — "every non-blank line below its fixed sentence" in the code-review-loop and batch-controller templates has no upper bound at the next ## heading; a literal reader could take the Deviations heading as an answer line ← 1/2: r2:M3

## Round 4 verification 2 — Adversarial red-team — fable
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
### Dispositions
- [M1] carried — an inline value holding a single quote breaks the single-quoted NAME= form and bash's own syntax error is neither a listed script exit nor a table row; the Global Constraints fix the inline single-quoted form, so an escape or a shell-error slip row is a later decision (carried in invocation 1 round 2 [M4], round 4 [M1], verification 1 [M2]) ← 2/2: r1:M2, r2:M1
- [M2] carried — the Write tool overwrites without refusal a file this same session wrote earlier (reviewer probe on a scratchpad file: a second Write with different content succeeded), so the "value-file Write refused only because the file already exists" row cannot fire on a counter slip over a session-written value file; run the numeric ls recovery before writing a value file whenever <k> is uncertain, and qualify the refusal premise to files the session has neither read nor written ← 1/2: r1:M1
- [M3] carried — the "rm denied by a hook" row prescribes one quoted re-issue and no disposition for a second denial; state that the file is then left in place and the counter-slip path is taken ← 1/2: r2:M2

_Completed — 2026-09-06 — cap reached — HEAD 634e7b7eeeea80297de38a2197bf464fa521356b_
Secrets found: none
