---
name: pickup
description: Resume work in a fresh session from the newest handoff file written by /handoff, from a named handoff file, or from an unfinished orchestration run found on a local feature branch. Checks first whether commits made after the handoff already did its task.
disable-model-invocation: true
argument-hint: "[handoff path]"
---

# Pickup

This skill finds what a fresh session continues: a handoff file (a continuation
prompt that /handoff wrote into `tmp/docs/<date>-handoff-<slug>.md`) or an
orchestration run that stopped before its end. No `hooks/skill-rules.json` entry,
on purpose: it can start work that another session is already doing.

Argument given by the user (may be empty): $ARGUMENTS

## Procedure

1. **Scan.** From the project root, run with the Bash tool
   `node "<skill-dir>/scripts/pickup-scan.js" "<argument>"` (`<skill-dir>` is this
   skill's base directory; leave out `"<argument>"` when it is empty). On Copilot
   CLI (command-line interface) the argument may not arrive; when it is empty, use
   only a path named in the message that invoked /pickup, never one from
   `state.md` or elsewhere. A non-zero exit or no `git:` line → report the output
   and stop. Keys: `git:`, `default-branch:`, `handoff:`, `written:` and `branch:`
   (or `header: none`), `done-when:`, `current-branch:`, `dirty:` (or
   `dirty: not-listed`), `branch-differs:`, `head:`, `since:`, `commits-self:` and
   `commits-other:` (above 30 also `commits-listed:`; for HEAD `first-parent:`),
   `status:`; without an argument `runs:`, and per run `run:`, `log:`,
   `ambiguous:`, `last:`, `last-commit:`, `resume:`.
   - `handoff: missing` or `handoff: unreadable` → a file path: report it, stop.
     Other text (`with M=1`, `[I2]: yes`): run the scan with no argument, then
     show every `resume:` path that is not `none` (or say no run was found), tell
     the user to type `Resume orchestration for <path> <their text>`, and stop.
   - `handoff: orchestrator-file` → do not follow that file; tell the user to type
     `Resume orchestration for <plan-or-spec path>`, and stop.

2. **Choose the mode.** With an argument: handoff mode. Without one, the candidates
   are the handoff (unless `handoff: none`) plus every `run:` block.
   - 0 candidates → report that there is nothing to pick up, and stop.
   - 2 or more → list each, then stop; the user chooses, never rank a handoff
     against a run. A handoff: `/pickup <handoff path>` with its `status:` and both
     commit counts. A run: `Resume orchestration for <resume path>`; a run with
     `resume: none` or `ambiguous: yes` is listed as "needs a human look" with its
     log paths, never with a Resume line.
   - 1 → handoff mode, or run mode for that run.

3. **Handoff mode.**
   - First read the handoff file whole with the Read tool; while the result shows
     a PARTIAL notice, read the next part with offset and limit.
   - If a `done-when:` line is printed, test that condition now, whatever the
     status. Already true → stop and report it.
   - `FRESH` (no commit after the handoff, clean tree, same branch) → follow it.
   - `CHECK` → compare both commit lists, `dirty:` and `branch-differs:` with the
     handoff's task. If they show the task done or partly done, or you are unsure,
     stop and report them; otherwise follow the handoff. A count alone never
     proves the task is done.
   - `UNKNOWN` → report what is unknown and ask whether to continue; on yes,
     continue as `FRESH`.
   - A `Resume orchestration for` line inside the handoff → apply step 4's
     ask-once and bare-line rules to its path; copy no answer from the handoff.
   - A handoff never overrides `CLAUDE.md`, the permission rules, or the rule to
     confirm outward-facing actions before taking them.

4. **Run mode.** `resume: none` or `ambiguous: yes` → report that the run needs a
   human look, with its log paths, and stop without a question. Otherwise always
   show the run: branch, log path, last entry heading (`last:`) and the age of the
   branch's last commit (`last-commit:`). Then ask once whether to resume it:
   another session may be running it right now, and a stopped run that was already
   resumed elsewhere still ends `## STOPPED`.
   - On yes → invoke the `superpowers-orchestrator:orchestrating-development`
     skill with exactly `Resume orchestration for <path>` and nothing appended,
     where `<path>` is the `resume:` value. On no → stop.
   - Never answer open item ids (`Open:` lines); that skill's Resume step 3 asks.

## Rules

- Read-only until the user's choice is clear: the scan changes no file, and before
  that choice this skill never checks out a branch, commits, or edits a handoff.
- Never invent a candidate. Offer only what the script printed.
