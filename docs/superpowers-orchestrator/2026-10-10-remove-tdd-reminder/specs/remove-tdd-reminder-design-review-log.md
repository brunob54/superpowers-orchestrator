_Invocation 1 — 2026-10-10 — N=4 M=2 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-opus-5-5
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 7 Minor | r2: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 13/13
**Reviewer verdict:** 0 Critical, 1 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — §6.1: three observer tests switch `commit` off themselves (lines 716, 728, 737) and test 715 needs a second due reminder → added the switch rule: the known name becomes `decision-log`; test 715 arranges commit + one SIGNIFICANT_FILE edit and switches decision-log off with a padded mixed-case name ← 2/2: r1:I1, r2:I1
- [M1] applied — §6.1: the worktree case at line 352 becomes a check that passes for any code → the case is deleted and listed; the three SKILL.md cases stay ← 2/2: r1:M3, r2:M1
- [M2] applied — §6.1: the deletion range 848-1222 overlapped the kept helpers 859-942; unused constants and stale comments were missing → range split (tests 944-1222, heading 848-857), PYTHON_TEST_FILE_CASES and SOURCE_EDIT added, comments 392-393, 753-755, 786-792, 1546-1547 (git-index text moves), 1627 added ← 2/2: r1:M5, r2:M3
- [M3] applied — §4/§6: no direct test of the removal → added a regression test: one source edit with no test edit gives {} ← 2/2: r1:M6, r2:M2
- [M4] applied — §2: the non-goal "no change to plugin.universal.yaml" contradicted the release version bump → reworded to the hook entries; the version line changes with the release ← 1/2: r1:M1
- [M5] applied — §2: the 7-day cleanup runs only inside setGuard, so fewer blocks mean less cleanup (verified: hooks/stop-reminders.js:116 is the only caller) → recorded as an accepted limit; the cleanup is not moved ← 1/2: r1:M2
- [M6] applied — §6.1: test() runs at once, so rewritten tests at 123, 144, 396, 401 would read constants before their declaration → added the order rule: these tests move below the commit section ← 1/2: r1:M4
- [M7] applied — §6.2: T19/T20 mainly test edit logging → remove only the TDD assertion, keep the line-count assertion ← 1/2: r1:M7
- [M8] applied — §7: deleting both guide entries leaves "I still see the TDD reminder" uncovered → replaced by one short entry (older install, or the Codex adapter) ← 1/2: r2:M4

## Round 2 — Ambiguity & testability — claude-opus-5-5
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 7 Minor | r2: 0 Critical, 2 Important, 5 Minor
**Sources mapped:** 15/15
**Reviewer verdict:** 0 Critical, 2 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §6.2: "lines 461-466" also covered SCRATCHPAD_FIELD and SCRATCH_FILE, still used (verified at a75c3ec) → remove line 466 only, rewrite the comment 461-463 with the reason of §3.2, keep 464-465 ← 2/2: r1:I1, r2:I1
- [I2] applied — §6.1/§8: tests 715 and 825 assert absences that pass vacuously; the commit arrangement rewrites the edit log (writeFileSync, line 91) → 715: edit appended after the arrangement, save-marker mechanism named, positive control with both reminders; 825: useAuth.js is one of exactly five files, asserts "Commit reminder: 5 files"; §8 item 2 extended ← 2/2: r1:M3, r2:I2
- [M1] applied — §6.1: two insertion points named, in-place rewrites could read undeclared consts → every rewritten test moves to one new section after the last commit-section test; new titles for 396 and 401 ← 2/2: r1:M1, r2:M1
- [M2] applied — §6.1: lists not stated complete, heading 753-755 "changed" above an empty section, kept-helper heading unnamed → heading and comment 753-759 deleted; lists declared complete, a failing test outside them stops the run for a ruling; kept helpers get a one-line comment ← 2/2: r1:M2, r2:M2
- [M3] applied — §6.1: regression path only an example, could pass on the old code under a test-named or tracked path → fixed path /project/src/app.js; the plan shows the test red at a75c3ec ← 2/2: r1:M4, r2:M5
- [M4] applied — §3.2: the reminders the scratchpad exclusion protects were not named → decision-log and state-md named with line references; the commit reminder is not affected ← 2/2: r1:M5, r2:M4
- [M5] applied — §1: Stop-block behaviour, bashEditDiff and "Claude Code's own list of changed files" had no source → hooks reference cited, stop-reminders.js 61-67 and bash-compress-hook.js 71 cited, the term replaced by the field name ← 2/2: r1:M6, r2:M3
- [M6] applied — §1: the 48% figure had no population or method; "gain is small" stood under "measured" → method and counts (162 of 337, 46 of 143 sessions, 2026-09-06 to 2026-10-10) added, scripts stated as not kept; the fourth reason labelled as a judgment ← 1/2: r1:M7

## Round 3 — Feasibility & architecture risk — claude-opus-5-5
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 1 Minor | r2: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 0 Critical, 1 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — §6: tests/context-management/run-tests.sh is not in the CLAUDE.md fast list and no listed suite calls it, yet it pins project-memory.md line 193 which this change rewrites (reviewer ran it at a75c3ec: 108 passed) → added as a required command, run on its own ← 1/2: r1:I1
- [M1] applied — §3.2: "the commit reminder is not affected" is false for a scratch file inside a git repository (gitReaderForFile runs git in the file's folder; track-edits.js 156-158 names the fixture case) → sentence replaced: the exclusion also keeps fixture-repository files out of the commit count ← 2/2: r1:M1, r2:M2
- [M2] applied — §2/§7: the session summary is shown only inside a block of another reminder (verified: stop-reminders.js 742-748 returns {} for a summary alone), so it now appears less often, and README line 434 would keep a false claim → second accepted limit added; §7 asks for the README text to say the summary appears only inside a block ← 1/2: r2:M1
- [M3] applied — §6.1: nine shared-behaviour tests depended on the commit reminder (git, 5-file threshold, time limit, subagent postponement) although five could observe the decision-log reminder through the existing arrangeDueBlock (line 475) → 123, 727, 736, 743 observe decision-log (switch values unchanged); 396, 401, 825 and 715 keep the commit arrangement; 715 keeps ' Commit ,unknown ' and asserts decision-log stays; test 144 deleted as a repeat of T2b (line 461); the switch rule removed; §8 wording adjusted (reviewer prototyped both designs in a git-archive copy: the delete and rewrite lists were complete) ← 1/2: r2:M3

## Round 4 — Adversarial failure modes — claude-opus-5-5
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 0 Important, 4 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 0 Important, 4 Minor
**Converged:** no

### Dispositions
- [M1] applied — §8 item 2/§6.1: a positive control run in the same HOME writes the 2-minute guard, so test 401's {} would come from the guard and pass for any window → each control and its protected case run in separate temporary HOME folders ← 2/2: r1:M1, r2:M3
- [M2] applied — §2: the cleanup accepted limit understated its effect; for a user with commit and decision-log switched off and no state.md, the cleanup stops completely (measured 26 edit logs, ~240 KB per 7 days on the owner's computer) → the class of users and the measured size named; the cleanup is still not moved ← 2/2: r1:M2, r2:M1
- [M3] applied — §7/§9: "remove tdd" is wrong for a settings file read by installations on two versions → remove it only after every installation that reads the file runs v7.71.0 or later; the warning is harmless until then ← 2/2: r1:M3, r2:M2
- [M4] applied — §6.1: the regression test's {} could come from an edit log never read, and an unnamed cwd falls back to the checkout → built with evaluateEdits/evaluateStop (fresh HOME and cwd), plus getRecentEdits(<session id>) returns exactly one entry ← 1/2: r2:M4

Self-review after the loop (brainstorming Spec Self-Review): no placeholders; no stale reference to the removed switch rule or to test 144 as a rewritten test; the delete and rewrite lists stand above their completeness statement; scope unchanged (one plan). No inline fix needed.
