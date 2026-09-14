---
name: handoff
description: Write a continuation prompt for a fresh session into tmp/docs/<date>-handoff-<slug>.md, save state, and print the prompt so the user can clear the context window and continue the work elsewhere.
disable-model-invocation: true
---

# Handoff

The user is about to clear the context window. Produce a prompt that lets a fresh
session, which starts with zero memory of this one, continue the work without
re-deriving anything this session established.

Today's date: !`date +%F`
Current branch and HEAD: !`git branch --show-current 2>/dev/null` at !`git rev-parse --short HEAD 2>/dev/null`
Uncommitted files: !`git status --short 2>/dev/null | wc -l | tr -d ' '`
Argument given by the user (may be empty): $ARGUMENTS

## Procedure

1. **Decide the slug.** If the user gave an argument, use it (lower-case, hyphens).
   Otherwise derive a short slug from the next work item (the row number or feature
   name the next session will work on). The file is
   `tmp/docs/<today>-handoff-<slug>.md`, where `<today>` is the date printed above.
   Create `tmp/docs/` if it does not exist. Never overwrite an existing file: if the
   name is taken, append `-2`.

2. **Collect the facts, mostly from files, not from memory.** Every source below is
   optional; use the ones the project has. Read `state.md` and the last two
   `[saved]` entries of `session-log.md` (written by the context-management skill
   in projects where state was saved); the previous handoff in `tmp/docs/` (the
   newest `*handoff*` file) for the conventions section, or the project's
   `CLAUDE.md` when there is no previous handoff; the version file and the
   installed version if the project publishes a package or plugin; the project's
   worklist or issue file if `state.md`, the previous handoff or `CLAUDE.md` names
   one (the item the next session works on). Delegate bulk reads to a subagent;
   keep this window small.

3. **Write the prompt** with exactly these sections, in plain English, no idioms,
   every technical term defined at first use, lines at most 88 columns:

   - **Opening paragraph.** The task in one or two sentences, naming the row or
     feature and the file and line where it is described; the repository, the
     branch, the version, whether the tree is clean, and whether the installed
     plugin matches main.
   - **## What is already known (do not re-derive).** Every fact this session
     verified that the next session would otherwise have to re-measure: figures,
     with the transcript ids or file:line they came from; decisions the user made,
     stated as decisions; contradictions found between documents and evidence;
     what was rejected and why, in one line each; the exact commands that produced
     key evidence when they were not obvious. Facts only, each with its source.
   - **## How to proceed.** Numbered steps, in the order the next session should
     take them. Name the design step when one is needed (independent lenses plus
     a rebuttal round before tallying), the point where the user decides, and the
     delivery shape (spec plus orchestrated run, or a direct change on a feature
     branch with assertions first). Name every fast test suite to run.
   - **## Conventions that bit us.** The repository rules that cost time in this
     or earlier sessions: forbidden words, line budgets, merge style, the full
     release checklist with every file to bump, the issues-log rules, the
     save-state rule. Carry forward the previous handoff's list and add what this
     session learned; drop nothing unless it is no longer true.
   - **Closing reminders** after the sections: uncommitted files, background
     agents still running, a CLI restart owed after a plugin update, files that are
     local and untracked.

4. **Save state as well.** Run the `superpowers-orchestrator:context-management`
   skill's save-state procedure (`state.md` plus a `[saved]` entry in
   `session-log.md`) if it is available and the session made decisions; point
   `state.md` at the handoff file. A handoff without the saved "why" loses the
   decisions.

5. **Report.** Reply with the file path on the first line, then the whole prompt
   inside one fenced code block so the user can copy it, then any reminder that
   belongs outside the prompt (for example: restart the CLI before the fresh
   session). Nothing else.

## Rules

- The prompt must stand alone: a reader with the repository but none of this
  conversation must be able to start work from it.
- Never invent a figure. If a number is not in a file or a tool output of this
  session, leave it out or mark it "not recorded".
- Do not paste large file contents into the prompt; cite paths and line numbers.
- Do not commit anything. The handoff file lives in `tmp/docs/` under the project
  root, whatever the project; create the directory if it is missing. Check with
  `git check-ignore tmp/docs` whether it is gitignored and say in the reply when it
  is not, so the user can decide whether to ignore or commit it.
