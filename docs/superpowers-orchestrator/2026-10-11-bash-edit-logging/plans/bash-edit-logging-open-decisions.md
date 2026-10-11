# Open decisions and rulings — bash-edit-logging

## Ruling 1 — 2026-10-11 — phase 3 — [task 7/1] NUL character in a Bash-listed entry

- **Class:** design
- **Item:** [task 7/1] n/a n/a — an entry with a NUL character passes the accepted-entry rule, is logged, and makes the Stop reader's spawnSync throw, which cancels all stop reminders; the reviewer's fix rejects every C0 control character and DEL in the writer
- **Contract clause:** "It keeps an entry only when the entry is a string, `path.isAbsolute(entry)` is true, and it holds no `\n` and no `\r`; it removes duplicates (exact text); it dr" — docs/superpowers-orchestrator/2026-10-11-bash-edit-logging/plans/bash-edit-logging.md, Task 7
- **Defensible answers:** (1) plan governs: keep the writer rule (no `\n`, no `\r`); (2) amend plan: reject all C0 characters and DEL in the writer; (3) reject NUL only in the writer; (4) keep the writer rule and guard the reader (gitStdout) so a throw returns null
- **Forks:** 3 of 3 — design consistency: outcome 1 plus a reader-side guard; implementation practicality: outcome 2 narrowed to NUL only; adversarial: untabled reader-side fix, no plan or spec change; contradiction: settled — spec section 6 says a git call that cannot start adds no file for its chunk, so the defect is the unguarded spawnSync in the reader (hooks/stop-reminders.js gitStdout), not the writer rule; spec 4.1 step 2 and 5.1 state the writer rule exactly, so any writer-side change would change the spec; and no real file system allows NUL in a file name
- **Resolution:** plan governs: the writer rule stays as the plan and spec state it — the reader gap (gitStdout calls spawnSync without a guard) is carried to the whole-branch code review as a ledger line

## Ruling 2 — 2026-10-11 — phase 3 — [task 7/2] no cap on the number or length of Bash-listed entries

- **Class:** design
- **Item:** [task 7/2] n/a n/a — the accepted-entry rule has no limit on the number of entries or on the length of one entry, so a very large changedFiles list costs many synchronous file system calls; the reviewer's fix adds a count cap, a length cap and one scratchpad real-path call per hook call
- **Contract clause:** "It keeps an entry only when the entry is a string, `path.isAbsolute(entry)` is true, and it holds no `\n` and no `\r`; it removes duplicates (exact text); it dr" — docs/superpowers-orchestrator/2026-10-11-bash-edit-logging/plans/bash-edit-logging.md, Task 7
- **Defensible answers:** (1) plan governs: no cap; (2) amend plan: count cap 1000 and length cap 4096 with tests; (3) no cap, record the limit in docs/orchestration-issues.md Accepted limits
- **Forks:** 3 of 3 — design consistency: outcome 1; implementation practicality: outcome 2 with the cap applied first; adversarial: outcome 1; contradiction: settled — spec section 2 (The 200-file cap) states that Claude Code lists at most 200 files per command and section 5.1 sizes a call at about 30 KB, so a 1500-entry list is outside the supported environment and the finding is Minor under the project CLAUDE.md supported-environment rule; a cap would also change spec 4.1 and 5.1
- **Resolution:** plan governs: no count cap and no length cap — the finding is recorded as an accepted limit

## Ruling 3 — 2026-10-11 — phase 4 — [I1] Bash-only file name printed unchanged in the Stop-hook reason

- **Class:** design
- **Item:** [I1 inv 1] Important hooks/stop-reminders.js:510 — a Bash-only file name is printed unchanged as a `- <path>` line of the Stop-hook reason, so text inside a file name reaches the model as hook feedback; the spec fixes the line as an absolute path (plan-mandated)
- **Contract clause:** "All decisions in the spec were made by the user on 2026-10-11 and are binding." — docs/superpowers-orchestrator/2026-10-11-bash-edit-logging/plans/bash-edit-logging.md, Global Constraints
- **Defensible answers:** (1) plan governs: keep the `- <path>` line as spec 5.2 fixes it, record an accepted limit; (2) amend plan; fix it: sanitize or quote the printed name, which changes the Global Constraints, Task 5 and spec 5.2
- **Forks:** 3 of 3 — design consistency: outcome 1; implementation practicality: outcome 1; adversarial: outcome 1; contradiction: none
- **Resolution:** plan governs — spec 5.2 fixes the printed line as an absolute path, spec section 2 names the model-must-judge risk, the writer rejects line breaks in an entry, and the defect needs a hostile file name from third-party content (rated Minor in rounds 1, 3 and 4); the finding is recorded as an accepted limit
