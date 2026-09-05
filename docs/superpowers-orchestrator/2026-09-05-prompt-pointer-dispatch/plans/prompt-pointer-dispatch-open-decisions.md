# Open decisions — prompt-pointer-dispatch

Ruling record of orchestrating-development's in-run rulings for this run.

## Ruling 1 — 2026-09-05 — phase 3 — [task 4/1] Task 4 Step 4 cannot `git add` the gitignored CLAUDE.md

- **Class:** forced
- **Item:** [task 4/1] n/a n/a — Task 4 Step 4 tells the implementer to run `git add CLAUDE.md` and commit, but CLAUDE.md is untracked and gitignored (.gitignore:7), so the command fails; which option governs: (a) local edit only, (b) `git add -f`, (c) register the suite in a tracked file instead?
- **Contract clause:** "git add CLAUDE.md / git commit -m 'docs(claude-md): list the fill-prompt unit suite among the fast tests' …" — docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/plans/prompt-pointer-dispatch.md, Task 4 Step 4 (reference text under the plan's Body authority note; the Task 4 Contract binds only the line's content and position inside CLAUDE.md)
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** option (a) — local edit only, no commit: keep the Step 1 edit on disk, treat Step 4 as satisfied with nothing to commit, never run `git add -f` on CLAUDE.md, record in the task report that CLAUDE.md is a local-only gitignored file, tick the task's checkboxes and commit the plan tick as usual — CLAUDE.md is untracked and gitignored by a deliberate `.gitignore` entry, the user's standing rule for this run states an edit to it is on-disk only and it must never be git-added, and the Task 4 Contract is already satisfied by the on-disk edit, so no other outcome is defensible.
