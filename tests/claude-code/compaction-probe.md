# Orchestrator Compaction Probe

Use this file to verify the compaction recovery guard of `orchestrating-development`
(v7.19.0 and later: the recovery paragraph in `## Required Start`) against the
installed plugin. A compaction is the moment Claude Code replaces the conversation
with a summary and re-attaches only the first part of each invoked skill (about
20,000 characters, the `invoked_skills` attachment record); the probe checks that
an orchestrator ruling after that moment still follows the skill's ruling
procedure.

The probe runs without a person at the terminal: a headless session
(`claude -p`, the print mode) can be compacted in two ways, both verified on
Claude Code 2.1.273 on 2026-09-16. The manual procedure below is kept for a
session where the interactive parts matter (a non-bypass permission mode).

## Preconditions

- A throwaway fixture repository with an approved spec under
  `docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md`, small
  enough that a review returns at least one open item (a plan clause the reviewer
  must collide with). A spec that works: two numbered requirements marked "hard
  constraint, not negotiable by the implementer", one a shell command built from
  an argument without quoting, one a catch-all that exits 0; both are flagged by
  every reviewer and both are binding plan text, so the run rules on them. The
  spec must carry the sentence
  `No decision in this design matched the prior-art trigger predicate.`
- The fixture's first commit must include the `.gitignore` that the plugin's
  session-start hook writes into any repository it runs in (`context-snapshot.json`
  under `# AI assistant artifacts`); an untracked `.gitignore` fails Phase 0's
  clean-tree check. Run one short `claude -p` call in the fixture first, then
  commit the file.
- The installed plugin is the version under test: `cat ~/.claude/plugins/cache/
  superpowers-orchestrator/superpowers-orchestrator/*/VERSION` prints `7.19.0` or a
  later version.
- Record the model and window: `/model` shows the model name; a `[1m]` suffix means
  the 1M window, no suffix means 200K. With the 1M window an automatic compaction
  never fires in a real run, so the manual compaction is the realistic case.
  Record both in the result block.

## Headless procedure (verified 2026-09-16)

Every call runs from the fixture repository's root, with `< /dev/null` and
`--dangerously-skip-permissions` (a headless session cannot answer a permission
prompt). Keep the session id: `S=$(uuidgen | tr 'A-Z' 'a-z')`.

1. **Start the run with a lowered automatic-compaction window.** The flag
   `--autocompact <tokens>` (floor `100k`, ceiling `1M`; the environment variable
   `CLAUDE_CODE_AUTO_COMPACT_WINDOW` is the same setting) makes compactions fire
   at about the window minus 16K tokens. `120k` fired nine times in a two-hour run.
   ```
   claude -p --session-id "$S" --autocompact 120k --dangerously-skip-permissions \
     "orchestrate docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md" < /dev/null
   ```
   A headless run does not stop at Phase 0's question: it takes the offered
   defaults (N_plan and N_code from the session-start defaults block, M=1, cap=3)
   and runs to the completion marker or a `## STOPPED` entry, then ends its turn at
   Phase 5's merge question. Do not send Phase 0 answers in a second call: a
   killed follow-up prompt still lands in the transcript. Expect one to two hours.
2. **Manual compaction, then a resume.** A resumed print-mode call whose prompt
   is `/compact` runs a real manual compaction (a `system` record with
   `subtype: compact_boundary` and `compactMetadata.trigger: "manual"`), prints
   nothing and runs no model turn.
   ```
   claude -p --resume "$S" --dangerously-skip-permissions "/compact" < /dev/null
   claude -p --resume "$S" --autocompact 120k --dangerously-skip-permissions \
     "Resume orchestration for docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md" < /dev/null
   ```
   On a completed run the Resume must re-read `## Resume`, run step 1's
   incomplete-ruling scan, report the completed state and stop.
3. **Deduplication sub-probe.** In the same session, invoke the skill again:
   ```
   claude -p --resume "$S" --dangerously-skip-permissions --max-turns 2 \
     "Invoke the superpowers-orchestrator:orchestrating-development skill with the Skill tool now, then reply with the single word invoked and do nothing else." < /dev/null
   ```
   Measure the injected `user` record (the one containing `Base directory for this
   skill`): the full body (about 150 KB) or a short "already loaded" note.
4. **Analyze.** The transcript is
   `~/.claude/projects/<encoded fixture path>/$S.jsonl` (slashes become dashes).
   Run `node tools/analyze-compaction.js <transcript> --after 25`: it lists every
   compaction with its trigger and token figures, the re-attached skill text, the
   hook records, and the tool calls that followed, and it marks the grep of
   section headings, `PARTIAL` Reads and ruling or log writes. Judge each
   compaction with the criteria below. Record the wall-clock time and the
   `compactMetadata` figures.
5. Delete the fixture branch or the fixture folder when done.

Known limits of a headless run: the `fork` agent type does not exist there (the
first fork round fails at once and the skill retries with `general-purpose`), and
the plugin's session-start hook re-runs after every compaction with output too
large to stay in context (only a 2,000-character preview remains).

## Manual procedure

1. Start the orchestration with the standard prompt (`orchestrate docs/...`). Answer
   Phase 0 so that N_code is 2 or more. Let the run reach Phase 4.
2. Wait until the log holds at least one `## RULING <n>` entry, then wait for the
   next code-review controller dispatch to be in flight.
3. Type `/compact`. Note the wall-clock time; the transcript record with
   `isCompactSummary: true` marks the moment.
4. Let the controller return. Observe every tool call between the return and the next
   `## RULING` (or `## STOPPED`) write.
5. Deduplication sub-probe, as in headless step 3, from the interactive session.
6. Stop the run (`abandon orchestration`) and delete the fixture branch.

## Pass criteria

Apply them to every compaction after which the session acted on a controller or
fork return, wrote a ruling, or took a Resume step. A compaction with nothing of
that kind pending (Phase 0 before the first dispatch, Phase 5 after the completion
marker, the sub-probe) is recorded as not applicable.

- Before acting, the session runs `grep -n '^## ' <base>/SKILL.md` to find the
  bounds of the section it is executing, then Reads that section with `offset` and
  `limit`, one more Read per `PARTIAL view` notice at the offset the notice names,
  until the section's last line is in its context. Under bypass permissions a
  `sed -n '<first>,<last>p'` of the same line range counts as that read.
- Then it runs Resume step 1's incomplete-ruling scan on the ruling record.
- The `## RULING <n>` entry carries its `Items:`, `Detail:`, `Forks:` and
  `Re-dispatch:` lines; `<n>` is the first ruling number of that return; the commit
  subject `<slug> ruling <n>` lands after the record and the log entry, in the
  skill's order.
- The `Re-dispatch: ... in-run resume <r> of 3` figure matches the count of earlier
  `## RULING` entries of that phase in the log.
- When the predicate escalates, the `## STOPPED` entry follows the Major-Error Stop
  Policy shape and its `Resume:` line is printed as the stop report.

## Fail criteria

- A ruling written with no read of `SKILL.md` between the summary and the write, a
  Read that stopped at the first `PARTIAL view` notice, or a read of a section other
  than the one being executed. A summary that says the re-read was already done
  does not count as a read.
- A `## RULING` entry missing a line, a commit before the log entry, a `Forks: none`
  on a `design` item, or a resume count that restarts at 1.
- The orchestrator guesses a `<PROMPT_DIR>` path instead of running `mktemp -d`.

## Record in docs/orchestration-issues.md

- Row 13: on a pass, replace fix (5) with "closed <date>: compaction probe passed on
  transcript `<id>`; guard shipped in v7.19.0". On a fail, keep the row and add the
  failing tool sequence as a new fix line.
- Case 017: add a `**Follow-up — <date> — compaction probe.**` paragraph naming the
  transcript id, the model and window, the number of compactions and of paged
  Reads, the ruling numbers written after a compaction, and the sub-probe result
  (full body or note).

## Result Template

```md
## Compaction Probe Result

- Plugin version:            - Model / window:
- Transcript id:             - Compactions (auto / manual):
- Guard followed / by sed / skipped / not applicable:
- Rulings written after a compaction: RULING <n> ...
- Sub-probe (re-invoke):     full body / note
- Decision: PASS / FAIL      - Blocking issues:
```

## Result — 2026-09-16 (first run of the probe)

- Plugin version: 7.29.0 — Model / window: claude-fable-5-1 [1m] (headless, bypass
  permissions, `--autocompact 120k`)
- Transcript id: `fc0770bb-5df6-4f37-9e00-a229100e0116` (fixture `slug-cli`, run
  15:45 to 17:46, N_plan=4 N_code=4 M=1 cap=3 taken from the defaults)
- Compactions: 9 automatic (pre 77K–105K tokens, post 17K–53K) and 1 manual
  (66K to 14K); every one re-attached 20,000 characters of the skill.
- Guard followed 2 (compaction 2 in Phase 0; the manual compaction before the
  Resume: grep, one Read of lines 843–1220, then the incomplete-ruling scan) /
  by sed 1 (Phase 4 return: Reads of lines 1258–1429 and 1842–2279 plus sed
  excerpts, no grep) / skipped 5 (the Phase 3 ruling across compactions 3–5 and
  the Phase 4 ruling across compactions 6–7: forks dispatched and both rulings
  written with no read after the last summary; the summaries at records 432 and
  742 restated the templates and said the re-reads were done) / not applicable 2
  (Phase 0 before the first dispatch, Phase 5 after completion).
- Rulings written after a compaction: RULING 1 (phase 3, two items, forks 3 of
  3, resume 1 of 3) and RULING 3 (phase 4); both entries complete, numbered by
  the first ruling number of the return, committed after the log entry; no
  compaction-caused defect in the log, the ruling record, the commits, the
  prompt directory or the completion marker.
- Sub-probe (re-invoke): full body (153,780 bytes), which itself triggered the
  tenth compaction.
- Decision: FAIL on the literal criteria (five skipped re-reads), PASS on the
  realistic manual case and on every outcome. Blocking issues: none. The guard
  text was tightened in v7.30.0 (summary claims never count; sed counts).
- Compactions cost 1,022 s of the run's 7,263 s. Three evaluator reports and the
  driver scripts are in the session's scratchpad only; this block is the record.
