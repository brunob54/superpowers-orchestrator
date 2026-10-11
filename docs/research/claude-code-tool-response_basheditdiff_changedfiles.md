_Researched: 2026-10-11 | registry: claude-code | canonical name: tool_response.bashEditDiff.changedFiles | versions inspected: 2.1.296 (binary text and docs), changelog entries 2.1.269, 2.1.281, 2.1.290, 2.1.293_

# Claude Code `tool_response.bashEditDiff.changedFiles`

A field of the PostToolUse hook input for the Bash tool. It lists the files
that a Bash command changed. Docs read 2026-10-11; the 2.1.296 binary was
read as text with grep, never run.

## Shape

Source: https://code.claude.com/docs/en/hooks.md, Bash tool section.

- `changedFiles`: "Absolute paths of the files the command changed, at most
  200. Present whenever `files` holds a diff or `moreFiles` is above zero".
- `files`: "Diffs of up to 5 changed files, for display" with `created` /
  `deleted` flags.
- `moreFiles`: "Count of changed files with no diff in `files`".
- `unavailable`: "Set when the diff is incomplete or couldn't be taken".
- `skipped`: "Set for a Git command that moves the working tree, such as
  `git checkout` or `git stash`, so Claude Code takes no diff".
- `shared`: set when another Bash call ran in the same repository at the
  same time.
- "Files that Git ignores and files in submodules aren't listed. Requires
  Claude Code v2.1.269 or later."
- "The list is best effort and in public beta. Claude Code can miss a
  change, include a file that another process changed at the same time, or
  stop at its size limits. The field shape may change."

## When it is filled

- Default: auto and `bypassPermissions` modes only, "and only when Claude
  Code directs Claude to edit files through Bash" (hooks docs). Binary gate:
  `(e==="auto"||e==="bypassPermissions")&&e7t()`; `e7t()` is unknown.
- `bashEditDiffEnabled: true` turns it on in every mode, but "counts only
  from your user settings, JSON passed with `--settings`, or managed
  settings"; a repository settings file can only turn it off
  (https://code.claude.com/docs/en/settings-reference.md).
- Environment variable `CLAUDE_CODE_BASH_EDIT_DIFF` "takes precedence over
  this key for one session" (same page).
- "Background commands and read-only commands carry no diff" (hooks docs).
  Open issues #97146 and #95854 report foreign files listed under read-only
  commands (up to 2.1.295).
- Failing commands fire PostToolUseFailure, not PostToolUse. Whether that
  input carries the field is undocumented.

## Git commands (2.1.296 binary)

- List `["checkout","switch","stash","pull","merge","rebase","reset","restore","clean","cherry-pick","revert"]`.
  A plain `[sudo] git <verb>` with at most 16 simple arguments (regex
  anchored on the whole command) gives `{files:[],moreFiles:0,skipped:true}`
  with no `changedFiles`.
- Changelog 2.1.290: a chained command with git merge, pull or checkout
  "lists the files without full diffs". Effect on `changedFiles`:
  unverified.
- The internal snapshot uses `--no-renames`; a rename should appear as a
  deletion plus a creation (inference).
- After two snapshot failures for a repository, the binary gives up for
  the session (`unavailable:true`).

## Version history (CHANGELOG.md)

- 2.1.269 added; 2.1.281 temp-folder cleanup fix; 2.1.290 chained git
  display; 2.1.293 note says the list "can include writes by other
  processes". No field renamed or removed up to 2.1.296.

## Known risks (github.com/anthropics/claude-code issues, open on 2026-10-11)

- #97146, #95854, #94571, #100719: writes by other sessions or processes,
  even before the command started, are listed.
- #96492: on Windows every Bash call takes a full `git status` snapshot with
  fsmonitor off.
- #99342 (path exclusions), #99493 (skip git checkout; conflicts with the
  documented `skipped` flag).

## Prior art

- https://github.com/dougcunha/claude-mods `session-info/hooks/track.ts`
  (commit da1f53cb): uses the field unless `unavailable` or `skipped`,
  otherwise compares `git status` before and after.

## Not verified

Symlinks; Windows path form; `changedFiles` in 2.1.269 itself; git
worktrees; the use of a `.pick(...).strip()` output schema next to the
field.
