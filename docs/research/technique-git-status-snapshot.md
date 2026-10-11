_Researched: 2026-10-11 | registry: technique | canonical name: git-status-snapshot | versions inspected: n/a_

# Technique: git status snapshot before and after a Bash call

A PreToolUse hook saves `git status` output; the PostToolUse hook compares
it with a new `git status`. No versioned artifact. Checked: git 2.50.1
docs, Claude Code hooks docs (2026-10-11), aider source.

## Pairing the two hook processes (https://code.claude.com/docs/en/hooks)

- "PreToolUse hooks receive `tool_name`, `tool_input`, and `tool_use_id`."
  PostToolUse and PostToolUseFailure examples also hold `tool_use_id`
  (examples only, not the field tables).
- "Cancelling a running tool does not fire this hook" (PostToolUseFailure):
  an interrupted command leaves the snapshot without a reader.
- `cwd` is "the new directory after Claude runs `cd`", so Pre and Post can
  see different directories.
- "All matching hooks run in parallel."

## Cost

- https://git-scm.com/docs/git-status: untracked-file search "may take some
  time in a large working tree. Consider enabling untracked cache and split
  index"; scripts running status in the background "should consider using
  `git --no-optional-locks status`" (the index lock can make other git
  processes fail).
- https://git-scm.com/docs/git-config: built-in fsmonitor daemon only on
  Windows and macOS.
- GitHub blog (Chromium, about 400K files, Windows): 17.941 s plain,
  1.063 s with fsmonitor and untracked cache after the first run
  (https://github.blog/engineering/infrastructure/improve-git-monorepo-performance-with-a-file-system-monitor).
- This repository (497 tracked files, macOS, clean tree, 2026-10-11):
  0.01 s per `git status --porcelain`.
- Claude Code's own snapshot (behind `bashEditDiff`) has an open Windows
  cost report: github.com/anthropics/claude-code issue #96492.

## What it misses or attributes wrongly (reasoning from git semantics)

- A file already dirty and changed again keeps the same porcelain line;
  needs a content hash or mtime.
- Git-ignored files, files outside the repository, submodule contents.
- Writes by other sessions, editors or background processes during the
  window.
- `git checkout`, `pull`, `merge`, `stash pop`, `reset`, `switch`,
  `rebase`, `commit` change or clean many files.
- Background commands; overlapping windows of parallel Bash calls
  (whether Bash calls run in parallel is unverified).

## Prior art

- Aider (https://github.com/Aider-AI/aider, commit 5dc9490b, aider/repo.py):
  `get_dirty_files` runs `git diff --name-only --cached` and
  `git diff --name-only`; `check_for_dirty_commit` commits dirty files
  before its own edits instead of comparing snapshots.
- https://github.com/dougcunha/claude-mods `session-info/hooks/track.ts`
  (commit da1f53cb): falls back to a before/after `git status` compare when
  `bashEditDiff` is unavailable or skipped.
- Claude Code checkpointing docs: "Checkpointing does not track files
  modified by Bash commands."

## Not verified

Timing on large repositories, dirty trees, or Windows Git Bash.
