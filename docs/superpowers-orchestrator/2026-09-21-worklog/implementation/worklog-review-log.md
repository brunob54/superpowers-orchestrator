# Code review log — worklog

carried findings: 22 `Minor:` lines read from `.superpowers/sdd/progress.md`

_Invocation 1 — 2026-09-21 — N=4 M=3 — BASE..HEAD e06a224..1c04872 — branch feature/worklog — gate: orchestration_

## Round 1 — Correctness & spec alignment — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 1 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 3/3
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor
**Converged:** no
### Dispositions
- [M1] fixed — the line-1 command's two redirections are now `>|`, so it also writes when the shell option noclobber is set; a noclobber case was added to the suite → 917ba3c ← 1/3: r1:M1
- [M2] fixed — the skill now says to stop, show the output and write nothing more when the line-1 command prints anything; update check 5 and close step 4 follow that rule → 917ba3c ← 1/3: r2:M1
- [M3] fixed — ordered check 3 now names only a printed line, other than line 1, whose text after the line number starts with the status prefix; the check command is unchanged → 917ba3c ← 1/3: r3:M1
- [L1] fixed — suite cases (d) read-only work log, copy kept and its path printed last, and (e) unreadable work log, copy removed, work log unchanged → 917ba3c
- [L2] fixed — the prose now says a failed rewrite prints the copy's path on its last line → 917ba3c
- [L3] fixed — every failure branch of the line-1 command ends with `false`; the suite asserts the exit status of each branch → 917ba3c
- [L4] fixed — `closed_line` and `line1_through_link` helpers replace the repeated closed-line printf and the shared four-step fixture → 917ba3c
- [L5] carried — the check command's malformed branch prints file lines into the model's context; the block is byte-identical to the spec (Global Constraint 4)
- [L6] carried — the list command prints contributor-controlled file names; the [a-z0-9-] filter with at most 40 characters is adequate
- [L7] carried — the listing's `find` has no folder test and no sort; the stop writes nothing
- [L8] fixed — the section-7 grammar pin is now the whole `Grammar:` line → 917ba3c
- [L9] carried — the front-matter check also accepts `name: worklog-x`
- [L10] fixed — the check-ignore step gives the ready-to-copy `git -C "$(git rev-parse --show-toplevel)" check-ignore -q` form → 917ba3c
- [L11] carried — the `missing` stop rule is written twice; both copies agree
- [L12] user-decision — close writes under Accepted limits and Decisions but has no instruction for a heading the user deleted; repairs run in update only (two reviewers recommend user-decision) — at skills/worklog/SKILL.md:307 — clause: Task 3 "The repair of a missing heading or `Next item number` line runs in `update` only; `close` does not repair."
- [L13] fixed — the hook comment names the printf note of the Output section instead of stale line numbers and spells out IFS → 917ba3c
- [L14] carried — under the C locale the 300-character cut of the root counts bytes; worst case one replacement character
- [L15] fixed — the hook defines `worklog_paths_max=3` and `worklog_root_max=300` once; output byte-identical on the fixtures → 917ba3c
- [L16] carried — notice test case 3 covers few bad names and no run outside a git repository
- [L17] carried — under set -e a failing JSON.parse stops the notice test with no FAIL line; exit status still non-zero
- [L18] user-decision — a symbolic-linked `docs` folder is followed by find, so the notice can name a file outside the clone; the spec's accepted limit names only a symbolic-linked docs/worklogs (two reviewers recommend user-decision) — at skills/worklog/SKILL.md:112 — clause: Global Constraints "[Discovery through the session-start hook] 'Run the list command, unchanged: with its folder test, its `|| true` and its file-name filter."
- [L19] carried — a huge first line is read whole by awk, and one awk runs per file; fixable only inside binding lines (Global Constraints 4 and 11)
- [L20] carried — the notices sit outside the workspace budget; pack() subtracts the head, so the limit holds
- [L21] carried — a newline or closing tag in the user's own folder name breaks the notice text
- [L22] carried — redundant comment in tests/pickup/run-tests.sh case 6c
