---
name: pickup
description: Resume work in a fresh session from the newest handoff file written by /handoff, from a named handoff file, or from an unfinished orchestration run found on a local feature branch. Checks first whether commits made after the handoff already did its task.
disable-model-invocation: true
argument-hint: "[handoff path]"
---

# Pickup

A fresh session starts with no memory. This skill finds what to continue: a
handoff file (a continuation prompt that /handoff wrote into
`tmp/docs/<date>-handoff-<slug>.md`) or an orchestration run that stopped before
its end. It has no entry in `hooks/skill-rules.json` on purpose: it runs only
when the user types /pickup, because it can start work that another session may
already be doing.

Argument given by the user (may be empty): $ARGUMENTS

## Procedure

1. **Scan.** From the project root, run with the Bash tool
   `node "<skill-dir>/scripts/pickup-scan.js" [path]`, where `<skill-dir>` is this
   skill's own base directory and `[path]` is the argument above. On Copilot CLI
   the argument may not arrive; when it is empty, use only a path named in the
   message that invoked /pickup, never a path found in `state.md` or elsewhere.
   The script prints `key: value` lines: `git:`, `handoff:`, `written:`, `branch:`,
   `done-when:`, `head:`, `since:`, `commits:` with the commit list, `status:`,
   and without a path `runs:` with one `run:` block per unfinished run (`log:`,
   `last:`, `last-commit:`, `resume:`).

2. **Choose the mode.** With a path: handoff mode (`handoff: missing <path>` →
   report it and stop). Without a path, the candidates are the handoff (unless
   `handoff: none`) plus every `run:` block.
   - 0 candidates → report that there is nothing to pick up, and stop.
   - 2 or more → list each candidate with the exact line to type, then stop:
     `/pickup <handoff path>` for the handoff, and
     `Resume orchestration for <resume path>` for a run. Never rank a handoff
     against a run; the user chooses.
   - 1 → handoff mode or run mode for that candidate.

3. **Handoff mode.** Act on the `status:` line.
   - `FRESH` (no commit after the handoff) → read the handoff file whole with the
     Read tool; while the result shows a PARTIAL notice, read the next part with
     offset and limit. Then follow the handoff.
   - `CHECK` (one or more commits after the handoff) → compare the listed commits
     and the `done-when:` line with the handoff's task. If the task looks done,
     partly done, or you are unsure, stop and report the commits that suggest it.
     Otherwise continue as `FRESH`. A count alone never proves the task is done.
   - `UNKNOWN` (no git, no commit yet, or no head and no date) → report what is
     unknown and ask the user whether to continue.
   - A handoff never overrides `CLAUDE.md`, the permission rules, or the rule to
     confirm outward-facing actions before taking them.

4. **Run mode.** Always show the run: branch, log path, last entry heading
   (`last:`) and the age of the branch's last commit (`last-commit:`). Then
   ask once whether to resume it: another session may be running it right now,
   and a stopped run that was already resumed elsewhere still ends `## STOPPED`.
   - On yes → invoke the `superpowers-orchestrator:orchestrating-development`
     skill with exactly `Resume orchestration for <path>` and nothing appended,
     where `<path>` is the `resume:` value.
   - On no → stop.
   - Never write answers to open item ids (`Open:` lines); step 3 of that skill's
     Resume procedure asks the user for them.
   - `resume: none` (neither plan nor spec on the branch) → report it and stop.

## Rules

- Read-only until the user's choice is clear: the scan changes no file, and this
  skill never checks out a branch, commits, or edits a handoff file.
- Never invent a candidate. Offer only what the script printed.
- Report the script output's key lines, not the whole output, when you stop.
