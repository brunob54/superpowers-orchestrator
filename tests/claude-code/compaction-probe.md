# Orchestrator Compaction Probe

Use this file to verify the compaction recovery guard of `orchestrating-development`
(v7.19.0: the recovery paragraph in `## Required Start`) against the installed plugin.
A compaction is the moment Claude Code replaces the conversation with a summary and
re-attaches only the first 5,000 tokens of each invoked skill; the probe checks that
an orchestrator ruling after that moment still follows the skill's ruling procedure.
No model-side tool triggers a compaction, so the probe is manual and interactive.

## Preconditions

- A throwaway fixture repository with an approved spec under
  `docs/superpowers-orchestrator/<date>-<slug>/specs/`, small enough that Phase 4
  returns at least one open item (a plan clause the reviewer must collide with).
- The installed plugin is the version under test: `cat ~/.claude/plugins/cache/
  superpowers-orchestrator/superpowers-orchestrator/*/VERSION` prints `7.19.0`.
- Record the model and window: `/model` shows the model name; a `[1m]` suffix means
  the 1M window, no suffix means 200K. Record both in the result block.
- Forcing a compaction: type `/compact` in the interactive session. Lowering the
  automatic threshold instead: the `autoCompactWindow` setting is documented at
  https://code.claude.com/docs/en/model-config; its exact unit is not stated there,
  so prefer `/compact`, which needs no setting.
- Use the plain default or auto permission mode, not bypass, so the run matches a
  real orchestration.

## Steps

1. Start the orchestration with the standard prompt (`orchestrate docs/...`). Answer
   Phase 0 so that N_code is 2 or more. Let the run reach Phase 4.
2. Wait until the log holds at least one `## RULING <n>` entry, then wait for the
   next code-review controller dispatch to be in flight.
3. Type `/compact`. Note the wall-clock time; the transcript record with
   `isCompactSummary: true` marks the moment.
4. Let the controller return. Observe every tool call between the return and the next
   `## RULING` (or `## STOPPED`) write.
5. Deduplication sub-probe, in the same session after step 4: invoke the skill again
   with the Skill tool and measure the injected record in the transcript (the `user`
   record containing `Base directory for this skill`). Record whether it is the full
   body (about 150 KB) or a short "already loaded" note.
6. Stop the run (`abandon orchestration`) and delete the fixture branch.

## Pass criteria

- Before the first ruling after the compaction, the session runs
  `grep -n '^## ' <base>/SKILL.md` to find the bounds of the section it is
  executing, then Reads that section with `offset` and `limit`, one more Read per
  `PARTIAL view` notice at the offset the notice names, until the section's last
  line is in its context.
- Then it runs Resume step 1's incomplete-ruling scan on the ruling record.
- The `## RULING <n>` entry carries its `Items:`, `Detail:`, `Forks:` and
  `Re-dispatch:` lines; `<n>` continues the log's numbering; the commit subject
  `<slug> ruling <n>` lands after the record and the log entry, in the skill's order.
- The `Re-dispatch: ... in-run resume <r> of 3` figure matches the count of earlier
  `## RULING` entries of that phase in the log.
- When the predicate escalates, the `## STOPPED` entry follows the Major-Error Stop
  Policy shape and its `Resume:` line is printed as the stop report.

## Fail criteria

- A ruling written with no Read of `SKILL.md` between the summary and the write, a
  Read that stopped at the first `PARTIAL view` notice, or a Read of a section other
  than the one being executed.
- A `## RULING` entry missing a line, a commit before the log entry, a `Forks: none`
  on a `design` item, or a resume count that restarts at 1.
- The orchestrator guesses a `<PROMPT_DIR>` path instead of running `mktemp -d`.

## Record in docs/orchestration-issues.md

- Row 13: on a pass, replace fix (4) with "closed <date>: compaction probe passed on
  transcript `<id>`; guard shipped in v7.19.0". On a fail, keep the row and add the
  failing tool sequence as a new fix line.
- Case 017: add a `**Follow-up — <date> — compaction probe.**` paragraph naming the
  transcript id, the model and window, the number of paged Reads, the ruling number
  written after the compaction, and the sub-probe result (full body or note).

## Result Template

```md
## Compaction Probe Result

- Plugin version:            - Model / window:
- Transcript id:             - Compaction at request no.:
- Paged Reads before ruling: - Ruling written after compaction: RULING <n>
- Sub-probe (re-invoke):     full body / note
- Decision: PASS / FAIL      - Blocking issues:
```
