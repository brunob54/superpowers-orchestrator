# Usage-Limit Restart Probe

Use this file to verify that an unattended orchestrated run continues by itself
after a claude.ai usage limit stops it, instead of waiting for a person to type
`continue` (orchestration issue row 12).

A **usage limit** is the moment claude.ai refuses further requests until a reset
time. Claude Code 2.1.272 has a setting for it, `autoContinueAtUsageLimit`:
"When a claude.ai usage limit stops your session, wait for the limit to reset and
continue the task automatically. When off, the limit dialog offers the wait as a
choice instead." (Text read from the settings schema of the installed CLI on
2026-09-15; the public settings documentation does not list the key.)

The probe is an **observation**, not a test that can be started on demand: no
model-side tool can produce a real usage limit. Run it on the next orchestrated
run that hits one.

## Scope

- Covered by this probe: account usage limits. They were 23 of the 29 recorded
  restart events (Case 009, Follow-up of 2026-09-15, second entry).
- Not covered: the other 6 events — 4 machine sleeps, 1 `529 Overloaded`, and 1
  request time-out. The setting names usage limits only. Those stay open in row 12
  step (c).

## Preconditions

- `~/.claude/settings.json` holds `"autoContinueAtUsageLimit": true` (added
  2026-09-15). Check with
  `python3 -c "import json;print(json.load(open('$HOME/.claude/settings.json')).get('autoContinueAtUsageLimit'))"`.
- The CLI was restarted after that line was added. A setting read at startup does
  not apply to a session that was already running.
- `claude --version` prints 2.1.272 or later.
- An interactive session. Scheduled jobs and this setting do not exist in
  headless `claude -p` mode.
- Record the plan or spec path of the run, the model and the window (`/model`; a
  `[1m]` suffix means the 1M window).

## Steps

1. Start an orchestrated run as usual (`orchestrate docs/...`), and leave the
   session alone.
2. When a usage limit stops the session, **type nothing**. Note the wall-clock
   time and what the session prints (a wait notice, or a dialog offering the
   wait as a choice).
3. Wait past the reset time named in the message.
4. Record what happens without any input:
   - does the session continue the same task by itself?
   - if the limit hit a controller subagent (a subagent dispatched by the
     orchestrator), does that subagent continue, or does the orchestrator
     re-dispatch it?
   - does the orchestration log get its next entry with no typed `continue`?
5. Find the error records in the transcript afterwards:
   `grep -c '"isApiErrorMessage":true' ~/.claude/projects/<escaped cwd>/<session>.jsonl`
   and note the first and last of them. Deduplicate on `requestId`: one API
   response is written as several records.

## Pass criteria

- No human input between the limit message and the next orchestration log entry.
- The run reaches its next phase boundary, and the log's `Re-dispatch:` or
  `## RULING` numbering continues without a restart at 1.
- A controller killed by the limit is either resumed or re-dispatched exactly
  once; no phase runs twice.

## Fail criteria

- The session stays stopped after the reset time until a person types something.
- The setting shows a dialog that waits for a choice, so an unattended run still
  needs a person.
- The orchestrator re-dispatches a controller that had already finished, or skips
  a phase.

## Record in docs/orchestration-issues.md

- On a pass: in row 12, mark the usage-limit half closed, naming this probe's
  date, the run slug and the transcript id. Keep step (c) for the remaining 6
  events (sleep, 529, time-out), or close that half when those are judged too
  rare to fix.
- On a fail: keep row 12 open and add the observed behaviour as a new line, with
  the transcript id and the times.
- Either way: add a `**Follow-up — <date> — usage-limit restart probe.**`
  paragraph to Case 009 with the numbers below.

## Result Template

```md
## Usage-Limit Restart Probe Result

- Plugin version:            - CLI version:
- Setting value read:        - Model / window:
- Run slug:                  - Transcript id:
- Limit at (local time):     - Reset named in the message:
- Continued without input:   yes / no
- Where the limit hit:       orchestrator turn / controller subagent
- Next log entry at:         - Phases re-run:
- Decision: PASS / FAIL      - Blocking issues:
```
