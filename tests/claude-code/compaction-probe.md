# Orchestrator Compaction Probe

Use this file to verify the compaction recovery guard of
`orchestrating-development` (v7.19.0 and later: the recovery paragraph in
`## Required Start`) against the installed plugin. A compaction is the moment
Claude Code replaces the conversation with a summary because the context
window is nearly full. After a compaction Claude Code attaches again
(re-attaches) only the first part of each invoked skill: about 20,000
characters, stored in a record of the attachment kind `invoked_skills`. A
record is one JSON line of the session transcript, the JSON Lines file in
which Claude Code stores everything that happened in one session. The probe
checks that an orchestrator ruling (the decision the orchestrator writes when
a review finding contradicts the plan) made after a compaction still follows
the skill's ruling procedure.

The probe runs without a person at the terminal. A headless session
(`claude -p`, the print mode: Claude Code reads one prompt, runs until its
turn ends, prints the answer and exits, with nobody at the terminal) can be
compacted in two ways. Both were verified on Claude Code 2.1.273 on
2026-09-16. The manual procedure below is kept for a session where a person
sees and answers the permission prompts (any mode other than bypass
permissions, the mode that skips every permission prompt).

## Preconditions

- A throwaway fixture repository (a small git repository created only for
  this test and deleted after it) with an approved spec under
  `docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md`. The
  spec must be small enough that a review returns at least one open item (a
  plan clause that the reviewer's finding must contradict, so that the
  orchestrator has to rule on it). A spec that works has two numbered
  requirements marked "hard constraint, not negotiable by the implementer".
  One is a shell command built from an argument without quoting; the other
  is a catch-all that exits 0. Every reviewer reports both, and both are
  binding plan text, so the run must rule on them. The spec must carry the
  sentence `No decision in this design matched the prior-art trigger
  predicate.` The spec used by the first run is in the appendix at the end
  of this file.
- The plugin's context-engine hook (a script Claude Code runs when a session
  starts) writes `context-snapshot.json` into the repository and adds it to
  the repository's local exclude file (`git rev-parse --git-path
  info/exclude`). Git never commits that file, so the working tree stays
  clean and the fixture needs no extra commit. Plugin versions before 7.32.0
  wrote a `.gitignore` entry instead: with such a version, run one short
  `claude -p` call in the fixture first, then commit `.gitignore`, because
  Phase 0's check that the working tree is clean fails on an untracked
  `.gitignore`.
- The installed plugin is the version under test:
  `cat ~/.claude/plugins/cache/superpowers-orchestrator/superpowers-orchestrator/*/VERSION`
  prints `7.19.0` or a later version.
- Record the model and the context window. In an interactive session
  `/model` shows the model name; a `[1m]` suffix means the 1,000,000-token
  window, no suffix means the 200,000-token window. In print mode there is no
  `/model`: take the model name from the `message.model` field of any
  `assistant` record in the transcript, and pass `--model <name>` to `claude`
  when a specific model is wanted. With the 1,000,000-token window an
  automatic compaction never starts in a real run, so the manual compaction
  is the realistic case. Record both in the result block.

## Headless procedure (verified 2026-09-16)

Every call runs from the fixture repository's root, with `< /dev/null` and
`--dangerously-skip-permissions` (bypass permissions: a headless session
cannot answer a permission prompt). Keep the session id:
`S=$(uuidgen | tr 'A-Z' 'a-z')`.

1. **Start the run with a lowered automatic-compaction window.** The flag
   `--autocompact <tokens>` (floor `100k`, ceiling `1M`; the environment
   variable `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, found in the binary, is untested)
   lowers the context size at which a compaction starts: on a small probe
   session, `100k` started one at about 84K tokens; on the recorded run, `120k`
   started eight in two hours, at 77K to 105K tokens.
   ```
   claude -p --session-id "$S" --autocompact 120k --dangerously-skip-permissions \
     "orchestrate docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md" < /dev/null
   ```
   The skill text says that Phase 0 asks one question: the review counts
   N_plan and N_code, the reviewer count M and the batch cap. In the one
   recorded run the first call did not stop at that question. It took the
   offered defaults (N_plan=4, N_code=4, M=1, cap=3; N_plan and N_code come
   from the `<superpowers-defaults>` block that the session-start hook prints,
   so another machine may offer other values). It ran to the completion
   marker (the log line the skill writes when the pipeline is done) or to a
   `## STOPPED` entry, and then ended its turn at Phase 5's merge question.
   Check the first call's output. If it ends with the Phase 0 question,
   answer it in a resumed call (`claude -p --resume "$S" ...` with the
   answers as the prompt). Send that call only after the first call has
   returned: a queued follow-up call that is killed is still written to the
   transcript. Expect one to two hours.
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
3. **Deduplication sub-probe** (does Claude Code inject the skill body a
   second time, or only a short note?). In the same session, invoke the skill
   again:
   ```
   claude -p --resume "$S" --dangerously-skip-permissions --max-turns 2 \
     "Invoke the superpowers-orchestrator:orchestrating-development skill with the Skill tool now, then reply with the single word invoked and do nothing else." < /dev/null
   ```
   Measure the injected `user` record (the one containing `Base directory for
   this skill`): the full body (about 150 KB) or a short "already loaded" note.
4. **Analyze.** The transcript is
   `~/.claude/projects/<encoded fixture path>/$S.jsonl`. The encoded path is
   the fixture's resolved absolute path with every slash, dot and underscore
   replaced by a dash (on macOS `/tmp` resolves to `/private/tmp`). The
   command `ls -t ~/.claude/projects/*/"$S".jsonl` finds the file. Run
   `node tools/analyze-compaction.js <transcript> --after 25`. For every
   compaction it lists the trigger, the token figures, the re-attached skill
   text, the hook records and the tool calls that followed. It marks the grep
   of section headings, the Reads that hit a `PARTIAL` notice, and the ruling
   or log writes. Judge each compaction with the criteria below. Record the
   wall-clock time and the `compactMetadata` figures.
5. Delete the fixture branch or the fixture folder when done.

Known limits of a headless run. The `fork` agent type (a subagent that
inherits the whole conversation) does not exist there: the first fork round
fails at once and the skill retries with `general-purpose`. The plugin's
session-start hook re-runs after every compaction; before v7.31.0 its output
was too large to stay in context (Claude Code wrote it to a file and kept
only a 2,000-character preview), and since v7.31.0 the hook keeps its output
under 10,000 characters.

## Manual procedure

1. Start the orchestration with the standard prompt (`orchestrate docs/...`).
   Answer Phase 0 so that N_code is 2 or more. Let the run reach Phase 4.
2. Wait until the log holds at least one `## RULING <n>` entry. Then wait
   until the next code-review controller (the subagent that runs one review
   round) has been dispatched and has not yet returned.
3. Type `/compact`. Note the wall-clock time; the transcript record with
   `isCompactSummary: true` marks the moment.
4. Let the controller return. Observe every tool call between the return and
   the next `## RULING` (or `## STOPPED`) write.
5. Deduplication sub-probe, as in headless step 3, from the interactive session.
6. Stop the run (`abandon orchestration`) and delete the fixture branch.

## Pass criteria

Apply them to every compaction after which the session acted on a controller or
fork return, wrote a ruling, or took a Resume step. When a compaction has
nothing of that kind pending (Phase 0 before the first dispatch, Phase 5
after the completion marker, the sub-probe), the person running the probe
records it as not applicable.

- Before acting, the session runs `grep -n '^## ' <base>/SKILL.md` to find
  the bounds of the section it is executing. It then Reads that section with
  `offset` and `limit`. For every `PARTIAL view` notice it Reads once more at
  the offset the notice names, until the section's last line is in its
  context. Under bypass permissions a `sed -n '<first>,<last>p'` of the same
  line range counts as that read.
- Then it runs Resume step 1's incomplete-ruling scan on the ruling record.
- The `## RULING <n>` entry carries its `Items:`, `Detail:`, `Forks:` and
  `Re-dispatch:` lines; `<n>` is the first ruling number of that return; the
  commit with subject `<slug> ruling <n>` is made after the record and the
  log entry are written, in the skill's order.
- The `Re-dispatch: ... in-run resume <r> of 3` figure matches the count of
  earlier `## RULING` entries of that phase in the log.
- When the predicate escalates, the `## STOPPED` entry follows the Major-Error
  Stop Policy shape and its `Resume:` line is printed as the stop report.

## Fail criteria

- A ruling written with no read of `SKILL.md` between the summary and the
  write, a Read that stopped at the first `PARTIAL view` notice, or a read of
  a section other than the one being executed. A summary that says the re-read
  was already done does not count as a read.
- A `## RULING` entry missing a line, a commit before the log entry, a
  `Forks: none` on a `design` item, or a resume count that restarts at 1.
- The orchestrator guesses a `<PROMPT_DIR>` path instead of running `mktemp -d`.

## Record in docs/orchestration-issues.md

- Row 13: on a pass, replace fix (5) with "closed <date>: compaction probe
  passed on transcript `<id>`; guard shipped in v7.19.0". On a fail, keep the
  row and add the failing tool sequence as a new fix line.
- Case 017: add a `**Follow-up — <date> — compaction probe.**` paragraph
  naming the transcript id, the model and window, the number of compactions
  and of paged Reads, the ruling numbers written after a compaction, and the
  sub-probe result (full body or note).

## Result Template

```md
## Compaction Probe Result

- Plugin version:            - Model / window:
- Transcript id:             - Compactions (auto / manual):
- Guard followed / partial / skipped / not applicable:
- Rulings written after a compaction: RULING <n> ...
- Sub-probe (re-invoke):     full body / note
- Decision: PASS / FAIL      - Blocking issues:
```

## Result — 2026-09-16 (first run of the probe)

- Plugin version: 7.29.0 — Model / window: claude-fable-5-1 [1m] (headless,
  bypass permissions, `--autocompact 120k`)
- Transcript id: `fc0770bb-5df6-4f37-9e00-a229100e0116` (fixture `slug-cli`, run
  15:45 to 17:46, N_plan=4 N_code=4 M=1 cap=3 taken from the defaults)
- Compactions: 9 automatic (pre 77K–105K tokens, post 17K–53K) and 1 manual
  (66K to 14K); every one re-attached 20,000 characters of the skill.
- Guard compliance, one outcome per line:
  - Followed 2: compaction 2 in Phase 0, and the manual compaction (number 9)
    before the Resume, with grep, one Read of lines 843–1220 and then the
    incomplete-ruling scan.
  - Partial 1: after the Phase 4 return (compaction 6) the reads covered
    lines 1258–1590 of the `## In-run rulings` section (lines 1221–1692 on
    plugin 7.29.0), without the heading grep. The section's first 37 and
    last 102 lines were not read, and the session also read lines 660–709,
    1842–2279 and 2300–2345 of other sections.
  - Skipped 4: the Phase 3 ruling across compactions 3, 4 and 5, and the
    Phase 4 ruling after compaction 7. Forks were dispatched and both rulings
    were written with no read after the last summary. The summaries at
    records 361 and 742 restated the templates and said the re-reads were
    done; the summary at record 432 proposed two `sed -n` reads that the
    session then skipped.
  - Not applicable 3: compaction 1 (Phase 0 before the first dispatch),
    compaction 8 (Phase 5 after the completion marker) and compaction 10
    (the sub-probe).
- Rulings written after a compaction: RULING 1 (phase 3, two items, forks 3 of
  3, resume 1 of 3) and RULING 3 (phase 4). Both entries are complete,
  numbered by the first ruling number of the return, and committed after the
  log entry. No compaction caused a defect in the log, the ruling record, the
  commits, the prompt directory or the completion marker.
- Sub-probe (re-invoke): full body (153,780 bytes), which itself triggered the
  tenth compaction.
- Decision: FAIL on the literal criteria (four skipped re-reads and one
  partial), PASS on the realistic manual case and on every outcome. Blocking
  issues: none. v7.30.0 tightens the guard text (a summary claim never
  counts; a `sed -n` read of the same line range counts).
- The eight compactions of the run took 870 s of its 7,263 s. `mktemp -d` ran
  once (record 163) and eight of the ten summaries carried the path. Three
  evaluator reports and the driver scripts are in the session's scratchpad
  only; this block is the record.

## Appendix — the fixture spec of the first run

The fixture file
`docs/superpowers-orchestrator/2026-09-16-slug-cli/specs/slug-cli-design.md`,
copied without change, so that the run can be repeated
without the session's scratchpad:

```md
# slug-cli — design

## Goal

A small Node.js command-line tool that turns each line of a text file into a
URL slug (a lowercase string where words are separated by hyphens and every
other character is removed) and prints one slug per line.

## Requirements

R1. `slug.js` exports `slugify(text)`. It lowercases the text, replaces every
run of characters that are not `a-z` or `0-9` with one hyphen, and removes
hyphens at the start and at the end. `slugify("Hello, World!")` is
`hello-world`. `slugify("  ")` is the empty string.

R2. `cli.js` takes exactly one argument, the path of a text file, reads the
file, and prints `slugify(line)` for every line, one per line, in file order.
With no argument or more than one argument it prints `usage: node cli.js
<file>` to standard error and exits with status 2.

R3. `slug.test.js` tests R1 and R2 with the `node:assert` module and runs with
`node slug.test.js`; it exits 0 when every check passes. There is no test
framework and no `package.json`.

R4. **Hard constraint, not negotiable by the implementer.** `cli.js` reads the
input file by running the shell command `cat <path>` through
`child_process.execSync`, where `<path>` is the argument inserted into the
command string as given, without quoting or escaping. Reason: the operators
rely on shell expansion inside the path (for example `~` and `$HOME`). Do not
use `fs.readFileSync` for the input file.

R5. **Hard constraint, not negotiable by the implementer.** `cli.js` catches
every exception, prints nothing about it, and exits with status 0. Reason:
the tool runs inside a shell pipeline that must never stop.

## Out of scope

Unicode transliteration, a maximum slug length, streaming of large files.

## Prior art

No decision in this design matched the prior-art trigger predicate.
```
