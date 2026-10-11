_Researched: 2026-10-11 | registry: technique | canonical name: bash-command-text-parsing | versions inspected: n/a_

# Technique: parsing the Bash command text for written paths

A hook reads `tool_input.command` and derives the paths the command writes.
No versioned artifact. Checked: Claude Code permissions docs (2026-10-11),
three npm parsers, and this repository's hooks at commit 311a4e8.

## Local state (this repository, commit 311a4e8)

- No `package.json`, lockfile or `node_modules`; the hooks use only Node.js
  built-ins (hooks/bash-compress-hook.js header).
- hooks/track-edits.js has `redirectTargets()`: reads `>`, `>>`, `>|`
  targets, skips quotes and comments, stops at the first `<<` line, drops
  targets matching `/[$`\\]|^~/`. Its own comments list the limits: `tee`,
  variables, lines after `<<`, `[[ a > b ]]`, `cd` inside a subshell. No
  tests found for it.
- hooks/compression-rules.js has a compound-command detector
  `/[;|\n]|&&|(?<![<>])&(?!>)/` that ignores quotes; it does not split.

## Claude Code's own parsing (https://code.claude.com/docs/en/permissions)

- Separators: "`&&`, `||`, `;`, `|`, `|&`, `&`, and newlines".
- Wrappers removed: "`timeout`, `time`, `nice`, `nohup`, and `stdbuf`, plus
  the shell builtins `command` and `builtin`, and zsh's `noglob`".
- Redirect and `tee` targets are checked; `/dev/null`, `2>&1`, heredocs,
  here-strings are not. `bash -c` and `/bin/rm` are not followed. Rules
  "don't apply to ... a Python or Node script that opens files itself".
- Commands over 10,000 characters, or not fully parseable, prompt.

## Libraries (latest on 2026-10-11)

- unbash 5.0.0 (https://github.com/webpro-nl/unbash, commit 558bceb):
  "Fast 0-deps bash parser written in TypeScript"; `"type": "module"` (ESM
  only); `node >=14`; AST `Redirect { operator, target }` and heredoc
  nodes; does not "target PowerShell, `cmd.exe`, or other shell
  languages"; no knowledge of which arguments of `mv`/`cp`/`sed -i` are
  paths.
- shell-quote 1.12.0: zero dependencies, tokenizer only; README says heredoc
  bodies are not recognized and `$(...)` is not interpreted. Source not
  read.
- bash-parser 0.5.0 (https://github.com/vorpaljs/bash-parser, commit
  67a05de): about 15 runtime dependencies; "the `posix` mode is almost
  complete, and we are implementing the `bash` mode" (documents/mode.md).

## Coverage limits

Not visible to a redirect reader: `tee`, `sed -i`, `mv`, `cp`, `rm`,
`touch`, git commands that rewrite files, `patch`, `curl -o`, `tar -x`,
`npm install`, formatters, `make`, `python -c`, `node -e`, scripts,
`bash -c`, `xargs`, `find -exec`. Targets with variables, `~`, globs, or
after `cd` are unknown. A redirect to a git-ignored file is seen (unlike
`bashEditDiff`). A failing command fires PostToolUseFailure, so a
PostToolUse reader sees successful commands only.

## Prior art

No published Claude Code hook or plugin that does this was found
(searches 2026-10-11).

## Not verified

Windows Git Bash path forms (`C:\...`, `/c/...`) in command text; unbash
loaded from CommonJS on Node 16.
