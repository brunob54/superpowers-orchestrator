# Orchestrator prompt-pointer dispatch — design

Date: 2026-09-06. Topic slug: `orchestrator-prompt-pointer`. Worklist row 13,
fix 1, of `docs/orchestration-issues.md` (Case 017).

## Problem

`skills/orchestrating-development/SKILL.md` (the orchestrator) runs four
kinds of controller subagent, one per phase: the plan writer (Phase 1), the
plan-review loop (Phase 2), one batch controller per batch (Phase 3) and the
code-review loop (Phase 4). Each controller receives its instructions as the
`prompt` field of an Agent tool call, and today that field holds a copy of the
whole controller template, filled in by the orchestrator: 94 to 249 lines per
dispatch.

Case 017 measured the cost on the `autonomous-in-run-decisions` run: the
Phase 4 template was pasted on all 16 dispatches (13 of them byte-identical
retries after an environment kill), and those re-sends took about a quarter
of the orchestrator's own context window. The orchestrator is the one session
of a run that cannot be restarted cheaply: its window has to last from Phase 0
to Phase 5.

v7.9.0 (the `prompt-pointer-dispatch` run, merged at `d4d4351`) solved the
same problem one level down. `multi-code-review` now writes each reviewer and
fix prompt once, through a deterministic fill script, into a per-invocation
temporary directory outside the checkout, and dispatches a fixed
three-sentence pointer that tells the subagent to read that file. This design
applies that shipped mechanism to the orchestrator's own four dispatches. It
reuses the script and the pointer wording as they are; the only new text is
the orchestrator's use of them.

Terms used below:

- **Template**: one of the four Markdown files in
  `skills/orchestrating-development/` whose fenced block holds an Agent call
  with a `prompt: |` body and `[NAME]` placeholders.
- **Fill script**: `skills/multi-code-review/scripts/fill-prompt.js`, the
  Node script of v7.9.0 that extracts a template's prompt body, substitutes
  the placeholders from `NAME=<value>` or `NAME=@<file>` arguments and writes
  the result to `--out`.
- **Prompt file**: the file the fill script writes; the controller reads it.
- **Value file**: a file holding one multi-line placeholder value, read by
  the fill script through `NAME=@<file>`.
- **Prompt directory**: the directory `mktemp -d` prints, written
  `<PROMPT_DIR>` in this document; it holds the prompt files and value files
  of one orchestrator session.
- **Pointer**: the fixed three-sentence `prompt` field that names a prompt
  file.
- **Dispatch**: one Agent tool call that starts a controller.

## Scope

1. The orchestrator creates one prompt directory per session, fills each
   controller prompt once into it with the fill script, checks the file,
   and dispatches the pointer. This covers the four templates, the identical
   retry of a dispatch, and the in-run re-dispatch that carries a
   `[RESUME_ANSWER]` section.
2. The four templates are made fillable by the script: the single-letter
   placeholder `[M]` is renamed, and the optional `## Resume Answer`
   section is given semantics the script's whole-line rule can produce.
3. Every failure of the mechanism is fatal for the run, with the boundary
   of "the mechanism" stated in Error handling so that later refinements are
   forced rulings and not escalations (the lesson of Case 022).
4. Wording tests for the new orchestrator text and the four templates, and
   fill-script tests over the four templates.
5. The acceptance measure, defined inline, for the orchestrator session's
   window.

## Non-goals

Stated so that a reviewer does not ask for them:

- Row 13 fixes 2 and 3: a scribe subagent for ruling records, Cases and
  log entries; never re-reading an accepted report. Separate runs.
- Row 14 fixes 2 to 4 (an M schedule for later rounds, reviewer reports to
  a file, one controller per round).
- `multi-doc-review`'s reviewer dispatch, which still pastes its reviewer
  prompt inline. Separate run, same mechanism.
- `docs/guide/` and `RELEASE-NOTES.md`: release work, done at release time.
- Worklist rows 15 (open-item ids collide across rounds) and 16 (a
  user-answered amendment's marker is never backed). A recurrence in this
  run is recorded as a Follow-up on its Case, not fixed here.
- Moving the fill script to a shared location. It stays at
  `skills/multi-code-review/scripts/fill-prompt.js`; see Architecture.
- Any platform without the Agent tool and nested dispatch. The orchestrator
  already runs on Claude Code only (its Required Start says so); Windows
  Git Bash is covered by the same `cygpath` rule as `multi-code-review`.
- Changing what a controller does with its prompt. A controller reads one
  file instead of receiving the same text inline; the text is the same.
- Reclaiming the context that the orchestrator's own log writing, ruling
  records and heredocs use (the second and third contributors of Case 017).

No decision in this design matched the prior-art trigger predicate.

## Architecture and data flow

### Today

```
orchestrator                                   controller
  Read ./<template>.md  (94–249 lines)
  substitute [NAME] by hand
  Agent(prompt = <filled template>)   ───────▶  reads its prompt inline
  ... retry: Agent(prompt = <same text>)  ───▶
```

Every dispatch and every retry re-sends the whole text through the
orchestrator's window.

### After

```
orchestrator                                             controller
  mktemp -d                       (once per session)
  Write  <PROMPT_DIR>/dispatch-<k>-answers.txt   (only when answers exist)
  node fill-prompt.js --template <base>/<template>.md
       --out <PROMPT_DIR>/dispatch-<k>-<label>.md NAME=... RESUME_ANSWER=@...
  test -s <PROMPT_DIR>/dispatch-<k>-<label>.md
  Agent(prompt = <three-sentence pointer>)  ─────────────▶  Read <file>
  ... retry: Agent(prompt = <same pointer>)  ────────────▶  Read <same file>
```

The orchestrator never reads a template and never pastes a prompt. What
crosses its window per dispatch is a fill command (about ten short
arguments), a `test -s` and a three-line pointer; per retry, a `test -s`
and the pointer only. The value file is the one multi-line value, and it exists only when
the run has recorded answers.

### The script stays where it is

The fill script is location-independent (it uses only `fs`, `path` and
`crypto`, and never its own directory). The orchestrator already resolves
its procedure sources as `../multi-code-review/SKILL.md` and the like from
its base directory (Controller Dispatch Rules), so it reaches the script the
same way: `<this skill's base directory>/../multi-code-review/scripts/fill-prompt.js`.
Moving the script would touch `tests/fill-prompt/run-tests.sh`,
`multi-code-review/SKILL.md` (three references), `fix-prompt.md` and the
release notes, for no gain: the installed plugin copy holds the whole
repository tree, so any path inside it is installed. Decision: reuse in place.

### Why one directory per session and not per run

A run can span several sessions (Resume after `/clear`). A temporary path
is not durable state: it must never be written to `state.md`, the
orchestration log, a ruling record or a commit message (the shipped
`multi-code-review` rule, mirrored). So the directory lives exactly as long
as the orchestrator's context holds its path: a resumed session runs
`mktemp -d` again at its first dispatch. File names carry a per-session
counter (below), so a fresh directory never collides with anything.

## Interfaces

### Prompt directory

- Created by the orchestrator, as its own Bash command, once per session:
  in Phase 0 after the parameters are settled and before the Phase 1
  dispatch, or — on a resume — at Resume's re-dispatch step, before the
  first fill. The same paragraph of `multi-code-review`'s Procedure governs
  it and is mirrored sentence for sentence: `mktemp -d` with no argument
  (never a template or a path inside the repository); a printed path under
  the repository root is treated as a `mktemp -d` failure; on Git Bash
  (`uname -s` beginning `MINGW` or `MSYS`) the path is converted once with
  `cygpath -m` as its own command; the literal path is copied into every
  later command, Write call and pointer, never held in a shell variable of
  any name (a variable set in one tool call does not exist in the next; a
  wording test asserts the new text contains no `$PROMPT_DIR` token); the
  path never appears in `state.md`, the orchestration log, a ruling record,
  a Case or a commit message.
- **Path lost from context.** When the orchestrator no longer has the
  literal path in its context — after a context compaction, typically — it
  does not guess it, does not search the temporary location for it and does
  not reuse a path from any file. It runs `mktemp -d` again and continues
  with the new directory; the counter `<k>` restarts at 1 there (a name
  needs to be unique inside one directory only). This is NOT a failure of
  the mechanism. It differs from the
  `multi-code-review` rule (a lost path ends that invocation `BLOCKED`) for
  a stated reason: that rule protects the once-per-invocation directory
  whose round-numbered file names would collide, and the orchestrator has
  no such constraint — every file it writes is named by a counter, and a
  re-fill from the same values produces the same content. An identical
  retry issued after the path was lost therefore re-fills the prompt into
  the new directory under `<k>` = 1 and dispatches a pointer to that file; the content is identical, so it is still the identical
  dispatch of the retry rule. The compaction probe of the
  `prompt-pointer-dispatch` run (does a compaction summary keep the literal
  path) stays owed and is not attempted by this run.

### File names

All in `<PROMPT_DIR>`. `<k>` is a counter of fills the orchestrator has run
into the current prompt directory, starting at 1 and never reused inside
that directory (a fresh directory restarts it at 1); `<label>` names the
dispatch.

| Dispatch | Prompt file | Value file (only when the run has recorded answers) |
|---|---|---|
| Phase 1 plan writer | `dispatch-<k>-plan-writer.md` | `dispatch-<k>-answers.txt` |
| Phase 2 plan-review loop | `dispatch-<k>-plan-review.md` | — (the template has no `[RESUME_ANSWER]`) |
| Phase 3 batch `<n>` | `dispatch-<k>-batch-<n>.md` | `dispatch-<k>-answers.txt` |
| Phase 4 code-review loop | `dispatch-<k>-code-review.md` | `dispatch-<k>-answers.txt` |
| Secrets-hook probe of value file `<k>`, line `<n>` (Error handling) | — | `dispatch-<k>-probe-<n>.txt`, one line, removed after the probe |

Rules:

- A prompt file is written once and never rewritten once a pointer to it has
  been dispatched. Before that first dispatch the orchestrator may remove it
  (`rm -- <file>`) and fill it again under the same name when it finds the
  fill's values were wrong (the `multi-code-review` Amendment 4 rule).
- The identical retry of a dispatch (Controller Dispatch Rules: malformed
  return or controller error, retried once) resends the same pointer to the
  same file. No fill, no new file.
- A re-dispatch with a different `[RESUME_ANSWER]` — the Phase 3 and Phase
  4 re-dispatch after in-run rulings, the Phase 1 re-dispatch after a
  `BLOCKED` question is answered, and any Resume re-dispatch — is a new
  fill under the next `<k>`, with its own value file. Never a rewrite: the
  script itself refuses to write `--out` over an existing file with
  different content (exit 5), so a counter slip cannot silently replace a
  dispatched prompt.
- The orchestrator keeps `<k>` in its context. When it is unsure of the
  next value it lists the directory (`ls <PROMPT_DIR>`, one short Bash
  result) and takes the largest `<k>` (the number after `dispatch-`) plus
  one.

### Value files

- The only multi-line value is `[RESUME_ANSWER]`: one line per answer in the
  format `## In-run rulings` defines (`[<id>] (orchestrator): <answer>` /
  `[<id>] (user): <answer>`; the Phase 3 run-wide answer set; qualified ids
  travel unchanged), with the one exception `## Resume` step 3 already
  makes: the Phase 1 re-dispatch answer to a plan writer's `BLOCKED`
  question is a user line without an id or a tag. The composition rules of `## Resume` and `## In-run
  rulings` are unchanged; only where the lines go changes: into
  `dispatch-<k>-answers.txt`, then `RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt`.
- Written with the Write tool, never with a heredoc of any kind. Answer
  text quotes plan clauses and finding text, which the mirrored
  `multi-code-review` rule treats as untrusted (it may contain `$(...)`,
  backticks, or a line equal to a heredoc delimiter); and a heredoc is a
  Bash command, scanned by `block-dangerous-commands.js` and by the secrets
  hook's Bash patterns, whose refusals have no rewrite path. Only a Write
  refused by the secrets hook has the withhold-and-retry row of Error
  handling.
- When the run has recorded no answer, no value file is written and the fill
  passes `RESUME_ANSWER=` (empty). The script's whole-line rule then removes
  the placeholder line; see the template change below for what the
  controller sees.
- Every other placeholder is a short value (a path, an integer, `yes`/`no`,
  the batch template's task list `4, 5, 6`, a range) and is passed inline
  as `'NAME=<value>'`, single-quoted as `multi-code-review`'s command
  quotes its values, so that a value with spaces or shell characters stays
  one argument (an unquoted `TASK_LIST=4, 5, 6` splits into three
  arguments and exits 1). An inline value may not begin with `@` (the
  script's file-reference marker); none of the orchestrator's values does.

### The fill command, per phase

The orchestrator never opens a template: the placeholder list of each
template is written into the skill text as the fill command, so a
mismatch between the two is caught by the script (exit 3: a body placeholder
without a value; exit 4: a value naming no placeholder) and never by a
human reading the legend. `<base>` is the orchestrator's base directory,
`<mcr>` is `<base>/../multi-code-review`, `<sdd>` is
`<base>/../subagent-driven-development`. The exact paths the orchestrator
resolves for the skill-path placeholders are those it resolves today.

Phase 1:

```
node "<mcr>/scripts/fill-prompt.js" \
  --template "<base>/plan-writer-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-plan-writer.md" \
  'WRITING_PLANS_SKILL_PATH=<base>/../writing-plans/SKILL.md' \
  'SPEC_PATH=<spec path>' 'PLAN_PATH=<topic folder>/plans/<slug>.md' \
  'RESUME_ANSWER='
```

Phase 2:

```
node "<mcr>/scripts/fill-prompt.js" \
  --template "<base>/doc-review-loop-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-plan-review.md" \
  'MULTI_DOC_REVIEW_SKILL_PATH=<base>/../multi-doc-review/SKILL.md' \
  'REVIEWER_PROMPT_PATH=<base>/../multi-doc-review/reviewer-prompt.md' \
  'WRITING_PLANS_SKILL_PATH=<base>/../writing-plans/SKILL.md' \
  'PLAN_PATH=<plan path>' 'SPEC_PATH=<spec path>' 'N_PLAN=<N_plan>' \
  'M_REVIEWERS=<M>'
```

Phase 3, batch `<n>`:

```
node "<mcr>/scripts/fill-prompt.js" \
  --template "<base>/batch-controller-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-batch-<n>.md" \
  'SDD_SKILL_PATH=<sdd>/SKILL.md' 'SDD_SCRIPTS_DIR=<sdd>/scripts' \
  'IMPLEMENTER_PROMPT_PATH=<sdd>/implementer-prompt.md' \
  'TASK_REVIEWER_PROMPT_PATH=<sdd>/task-reviewer-prompt.md' \
  'PLAN_PATH=<plan path>' 'TASK_LIST=<i>, <i+1>, <j>' 'TASK_RANGE=<i>..<j>' \
  'FIRST_BATCH=<yes|no>' \
  'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'   (or 'RESUME_ANSWER=')
```

`[BATCH_NUMBER]` appears only in the template's wrapper (`name:` and
`description:`), which the script does not write: the orchestrator fills the
Agent call's `name` (`orch-batch-<n>`) and `description` itself, as it does
today and as `multi-code-review` does for its reviewer descriptions.
`BATCH_NUMBER` is not passed to the script (the script accepts a wrapper-only
name without error, but there is nothing for it to write).

Phase 4:

```
node "<mcr>/scripts/fill-prompt.js" \
  --template "<base>/code-review-loop-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-code-review.md" \
  'MULTI_CODE_REVIEW_SKILL_PATH=<mcr>/SKILL.md' \
  'REVIEWER_PROMPT_PATH=<mcr>/reviewer-prompt.md' \
  'TOPIC_DIR=<topic folder, absolute>' 'BASE_SHA=<BASE>' 'N_CODE=<N_code>' \
  'M_REVIEWERS=<M>' 'PLAN_PATH=<plan path>' \
  'LEDGER_PATH=<repository root, absolute>/.superpowers/sdd/progress.md' \
  'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'   (or 'RESUME_ANSWER=')
```

The exact placeholder names of the implementer and task-reviewer prompt
paths and of the SDD scripts directory are those the templates carry today;
the plan's task lists them from the template files, and the fill-script tests
(Testing strategy) fail if a name drifts.

After each fill: `test -s "<PROMPT_DIR>/dispatch-<k>-<label>.md"` as its
own command, before every dispatch of that file, retries included.

### Pointer message

Fixed wording, identical to `multi-code-review`'s, for all four controllers.
The Agent call keeps its `name` (blocking dispatch, unchanged), its
`description` and its `model` as today; only the `prompt` changes:

```
Your complete instructions are in the file <ABSOLUTE PATH>.
Read that file once, with the Read tool, before doing anything else, and
follow it as your only instructions. Nothing else in that directory is for
you; do not read any other file there.
```

`<ABSOLUTE PATH>` is the prompt file's absolute path. Nothing may be added
to the pointer: no answer, no phase name, no path of the run. The Controller
Dispatch Rules bullet "Build the prompt ONLY from the filled template —
never pass conversation history, prior phases' returns, or your own
reasoning" is rewritten to say the same about the prompt file: the file is
built only from the filled template, and the `prompt` field is the pointer
only.

### Template changes

Two changes, both forced by the fill script, both keeping every legend
phrase that `tests/in-run-rulings/run-tests.sh` pins (the plan lists them).

1. **`[M]` becomes `[M_REVIEWERS]`** in `doc-review-loop-prompt.md` (body
   line 45 and its legend line) and `code-review-loop-prompt.md` (body line
   46 and its legend line), and in every orchestrator sentence that names
   the placeholder. The script's placeholder pattern needs at least two
   characters, so `M=2` is a usage error (exit 1) and `[M]` would stay
   unfilled. The controller-facing text ("M (reviewers per lens): …") is
   unchanged; only the token changes.
2. **The `## Resume Answer` section is present on every dispatch; an
   empty section means "no answer".** The script's whole-line rule removes
   the `[RESUME_ANSWER]` line when the value is empty and nothing else, so
   the heading — and in `batch-controller-prompt.md` the six fixed prose
   lines between the heading and the placeholder — stay. Rather than move
   template prose into the orchestrator's value composition, the section's
   meaning changes: the heading loses its parenthetical instruction to the
   filler ("omit this whole section on a first dispatch" / "omit only when
   the run has recorded no answer at all") and becomes `## Resume Answer`;
   one fixed sentence, identical in the three templates, sits in the
   template body as the last line before the `[RESUME_ANSWER]` placeholder
   line (in the batch template: after its six existing prose lines):
   `A section with no line below this sentence means the run has recorded
   no answer.` An **answer line** is any non-blank line below that
   sentence — a `[<id>] (tag): …` line, a `[task <n>/<k>] (tag): …` line,
   or the plan writer's untagged user line alike. Every rule that keys on
   the section's presence keys on the presence of at least one answer line
   instead. That list is not exhaustive by construction: the plan's task
   greps each template and the orchestrator's text for `Resume Answer` and
   rewrites every presence test it finds. Known today: in
   `code-review-loop-prompt.md` Deviation 2 (lines 85, 89 and 93: "no
   `## Resume Answer` section is present, return `BLOCKED: previous
   invocation left <n> open items …`" / "With a `## Resume Answer` section
   present, Deviation 5 applies"), Deviation 5 (line 130, "when present")
   and the idempotence paragraph (line 186); in
   `batch-controller-prompt.md` lines 66, 95, 101, 122 and 128; in
   `plan-writer-prompt.md` the section's own lines; in the orchestrator's
   `## Resume` and `## In-run rulings` sentences that say the section is
   omitted or present. The legend's `[RESUME_ANSWER]` bullet
   says the placeholder is filled from the value file when the run has
   recorded any answer and passed empty otherwise, keeping its pinned
   phrases ("authoritative either way", "carries the run-wide answer set",
   the qualified-line drop, and the rest the plan lists from the test).
   `plan-writer-prompt.md`, whose section is filled only after a `BLOCKED`
   question, gets the same shape. One assertion of
   `tests/in-run-rulings/run-tests.sh` (line 2450 today) pins the batch
   template's old heading with its parenthetical verbatim; it is rewritten
   to the new heading and the fixed sentence, and the plan lists every
   pinned phrase that changes next to every one it keeps.

Everything else in the four templates is byte-identical: the wrapper lines,
the `**Nothing else may be added to the prompt.**` line, the body's
bracketed non-placeholder tokens (`[task <n>/<k>]`, `[I2 inv 3]`, `[<id>]`),
which contain spaces or lowercase letters and are never substituted. The
backticked `[TASK_LIST]` inside the batch template's own prose (line 119,
"never best-guess a number inside `[TASK_LIST]`") is a placeholder like any
other and is substituted, as today's hand fill substitutes it; the
resulting sentence names the list itself, which is the intended reading. All
four templates already have the shape the script requires (one fenced
block, `prompt: |`, a bare closing fence, no inner fence, a uniformly
indented body); a dry run of the script over each of them exits 0 today,
apart from `[M]`.

### The orchestrator's text

Normative content; the exact prose is the plan's. The change touches:

- **Controller Dispatch Rules**: a new bullet for the prompt directory and
  the pointer (creation, the no-variable rule, the file-name table, the
  `test -s`, the pointer wording, "the orchestrator never reads a template
  and never pastes a prompt"); the "Build the prompt ONLY…" bullet rewritten
  as above; the retry sentence gains "the same pointer to the same file".
- **Phase 0**: the `mktemp -d` step after the parameters, before Phase 1.
- **Phases 1 to 4**: each "Fill `./x.md` (…) and dispatch" sentence becomes
  the fill command above, the `test -s`, and "dispatch the pointer". The
  Phase 3 step 5 sentences that `tests/in-run-rulings` pins ("the same batch
  — same task list, same `First batch:` value — is re-dispatched",
  "a controller failure (no such section) → retry the identical dispatch
  once → major error → stop", "Every batch dispatch, first or repeat,
  carries in `[RESUME_ANSWER]` the answer set") stay verbatim; the plan
  writer runs that suite to prove it.
- **`## Resume`**: the re-dispatch step creates the session's directory
  first (a resumed session has none) and fills the stopped phase's prompt
  under `<k>` = 1.
- **`## In-run rulings`**: the answer lines go into the value file; the
  sentences "re-dispatch the phase's controller with the answers in
  `[RESUME_ANSWER]` — the only channel" and "a retry rebuilds the identical
  `[RESUME_ANSWER]` from the ruling-record entry" stay verbatim (pinned);
  "rebuilds" now means a new fill under the next `<k>` from the same
  ruling-record entry, which produces the same content.
- **Major-Error Stop Policy**: the mechanism failures below join the list
  of major errors, each with its `## STOPPED` cause text.
- **`## Prompt Templates`**: says the templates are filled by the script,
  never read by the orchestrator.

The multi-code-review Error Handling rows for the secrets hook are mirrored,
not cross-referenced: the orchestrator's text must stand alone, because a
controller-level rule read through another skill's file is the drift Case
016 recorded.

## Error handling

Every failure of the mechanism is **fatal for the run**: the orchestrator
writes the log entry it owes (if any), appends a `## STOPPED` entry whose
first line names the cause in the fixed text below, rewrites `state.md`, and
stops. There is no inline fallback anywhere: a fallback that pastes the
template would hide the defect and silently bring the old cost back (the
author's decision of 2026-09-05 on the shipped mechanism, Amendment 1 of the
`prompt-pointer-dispatch` spec, applied here without a new decision). A
resume after such a stop creates a fresh directory and re-fills; the resume
prompt is the existing one.

**The boundary — what is a failure of the mechanism and what is not** (the
author's brief of 2026-09-06 states it; this section is the normative
copy). A later review finding that refines a row inside this boundary is a
forced ruling for the orchestrator, not an escalation.

Failures OF the mechanism (fatal):

| Condition | `## STOPPED` cause |
|---|---|
| `mktemp -d` fails, prints a path under the repository root, or `cygpath` fails where the path must be converted | `prompt directory could not be created — <error text>`. Nothing is dispatched. |
| The fill script exits 2 (malformed template); or exits 5 with `cannot read` on an `@<file>` the orchestrator did write, with `cannot write <out>: existing path could not be read`, or with `cannot write <out>: file already exists` (a dispatched name reused with different content); or a second non-zero exit after a corrected command; or `test -s` fails on the prompt file | `prompt file <name> not produced — <the script's message, or "empty">`. Never dispatch a pointer to a file that failed the check. The script's exit-5 causes are enumerated in full between this row and the two not-mechanism rows below, as `multi-code-review`'s Error Handling enumerates them. |
| Node is missing | Treated as the script failing (row above). |
| A value-file write fails for a reason other than the secrets hook | `value file <name> could not be written — <the error>`. |
| A value-file Write is refused by `hooks/safety/protect-secrets.js` twice | `value file <name> refused twice by protect-secrets — <the hook's reason>`. Before the second attempt the orchestrator applies the mirrored `multi-code-review` rule: the hook names a credential kind and never a line, so it probes each line of the refused file with one Write tool call of the one-line throwaway file `dispatch-<k>-probe-<n>.txt` in the prompt directory, removed with `rm --` after the probe (never a Bash command, which `block-dangerous-commands.js` would also scan, and never a hook path), replaces every line the hook refuses by its `file:line` plus the fixed text `secret-bearing finding, value withheld` — the location-only form the orchestrator's own "Never reproduce a secret" rule already imposes on every answer — and retries the Write once. |
| A controller's final message shows it could not read, or did not follow, its prompt file — after the one identical retry of the Controller Dispatch Rules | `prompt file <name> not read by <controller name> — <the first line of each of the two final messages>`. The sign: the final message says it could not read, find or open the file, or it carries neither the report marker nor any of these tokens: the plan path, the topic folder path, the orchestration or review log path, `tasks=`, `task=`, `rounds=` — no sign of the prompt file's content. A message carrying at least one of them, without the marker, is a malformed return (not-mechanism table). |

NOT failures of the mechanism (today's paths, unchanged):

| Condition | Handling |
|---|---|
| A controller dies of the environment (usage limit, rate limit, tool error, no final message at all — Case 009) | The identical retry once, then the major-error stop of today (`inconclusive controller: <phase/batch>`), as the Controller Dispatch Rules say. The retry is the same pointer to the same file. |
| A slip in the orchestrator's own fill command: the script exits 1 (usage), 3 (a placeholder without a value), 4 (a value naming no placeholder), 5 with `cannot read template` (a wrong `--template` path), or 5 naming an `@<file>` the orchestrator never wrote | The orchestrator corrects its command once and runs it again; a second non-zero exit is fatal as the row above (the `multi-code-review` Amendment 3 rule). |
| The fill script exits 5 with `cannot write <out>: <error>` for any error text other than `file already exists` and `existing path could not be read` (a missing directory, a permission error, a full disk — whatever the errno text) | The prompt directory is gone, unwritable, or the path in the command is wrong — treated as a path lost from context: `mktemp -d` again and re-fill under `<k>` = 1 in the fresh directory. A second such exit in the fresh directory is fatal as the fatal row above (the temporary location itself is not writable). |
| A return unusable on format alone (the marker or a consumed field missing) whose text shows the controller worked on the run | Malformed return: the identical retry once, then the major-error stop of today. Not a pointer failure. |
| The prompt directory's path is lost from the orchestrator's context | `mktemp -d` again, continue (Interfaces). |
| A controller reads another file in the directory | Cannot be prevented by wording alone; the directory holds only this session's prompt and value files, and the pointer forbids it. The remaining exposure is a controller that disobeys a direct instruction — the same exposure the `multi-code-review` rule accepted. Accepted. |
| A stale directory from an earlier session is still on disk | Never reused (the path is not recorded anywhere); the platform's temporary-directory cleaning removes it. Accepted. |

The `## STOPPED` cause text goes on the entry's first line after the
heading, as today's causes do; the entry keeps the existing `Open:` /
`Ruled:` lines when the stop coincides with open items (it will not: the
five writer-side failures are detected before dispatch, and a controller
that never read its prompt file returns no open items).

The secrets hook scans Write content and Bash command strings, not the
fill script's output; the value file is the one place answer text is written
by a scanned tool, so the hook row above is the only hook interaction. The
fill command itself carries paths, integers and short tokens and matches no
Bash pattern of the hook.

## Testing strategy

Unit-level, fast, run by the plan's tasks and listed in `CLAUDE.md`'s test
block (an on-disk edit only: `CLAUDE.md` is gitignored in this repository
and is never `git add`ed — Case 005; the plan's task says so and a
plan-review reviewer is asked to test tracked-ness with one `git ls-files`
command instead of asserting it).

1. **Fill-script tests over the four templates**, added to
   `tests/fill-prompt/run-tests.sh` next to the existing reviewer and fix
   template cases: each orchestrator template is filled with representative
   values and the script must exit 0; the output must contain no unfilled
   placeholder (a grep for `\[[A-Z][A-Z_]*[A-Z]\]` finds nothing); an empty
   `RESUME_ANSWER=` removes the placeholder line and keeps the `## Resume
   Answer` heading and, for the batch template, its fixed sentence; a
   `RESUME_ANSWER=@file` with two lines inserts both under the heading;
   `M_REVIEWERS=2` is accepted by the two review-loop templates and `M=2`
   is not (exit 1); the batch template fills without `BATCH_NUMBER`; a
   `--out` that exists with different content exits 5 (the never-rewrite
   guard). Every `'NAME=` token inside each fenced block of the
   orchestrator's text that contains `fill-prompt.js`, keyed by the template
   file named on that block's `--template` line, is compared with the set of
   `[NAME]` tokens in that template's body and wrapper: the two sets must be
   equal, so the command and the template cannot drift.
2. **Wording tests**, a new `tests/orchestrating-development/run-tests.sh`
   modeled on `tests/reviewer-templates/run-tests.sh` (its pointer needles
   and negative needles are the pattern): the orchestrator's text contains
   `mktemp -d`, `fill-prompt.js`, `test -s`, the three pointer sentences
   verbatim, the never-rewrite rule, every `## STOPPED` cause text of the fatal rows
   and every row of the not-mechanism table; it contains no `$PROMPT_DIR` token, no line
   matching ``Fill `./`` between the Phase 1 and Phase 5 headings, and no
   occurrence of "paste" or of "Read `./" followed by a template file name
   anywhere (the sentence "Controllers read these files as their procedure"
   and the `## Prompt Templates` file list stay and match neither needle); the four templates contain no
   `[M]` token and no other single-letter uppercase bracket token except
   the checklist marker `- [X]` in the body of `doc-review-loop-prompt.md`
   (line 72 today), which is not a placeholder and stays byte-identical;
   they keep their wrapper lines and
   their `**Nothing else may be added to the prompt.**` line, and carry the
   new `## Resume Answer` heading without a parenthetical.
3. **Existing suites stay green after the one assertion above is
   updated**: `tests/in-run-rulings/run-tests.sh` (all its assertions, 496 today, pin
   the sentences this design keeps verbatim, plus the batch heading it
   changes),
   `tests/reviewer-templates/run-tests.sh`, `tests/writing-plans/run-tests.sh`,
   `tests/fill-prompt/run-tests.sh`, `tests/codex/run-unit-tests.sh`,
   `tests/smart-compress/run-tests.sh`, `tests/sdd-scripts/run-tests.sh`.
4. **No behavioural suite in this run.** None of `tests/claude-code/`
   exercises the orchestrator, and no suite greps an Agent prompt for
   template text, so no behavioural assertion changes. The behavioural
   evidence is the acceptance measure, taken on the first orchestrated run
   after the change is installed.

## Acceptance measure

Taken on the first orchestrated run after the change is installed (the run
that builds it executes the installed 7.9.0 copy and cannot measure its own
skill text; that run dispatches by pointer by hand, which is a practice and
not this change). The metric is defined here in full so that it depends on
no untracked file; the measuring script is written from these rules when the
measure is taken and is not part of this branch. The classes are those of
the `prompt-pointer-dispatch` spec's Acceptance measure, applied to the
orchestrator's own transcript.

- **Unit.** The orchestrator session's transcript (the main session's
  `.jsonl` file, not an `agent-*.jsonl`), from the record that invokes
  `orchestrating-development` to the Phase 5 stop message. When the run
  spans several sessions, each session's slice is measured and reported
  separately. Every quantity is bytes of UTF-8 text.
- **Denominator — content.** The sum of: the text of every assistant
  message; every tool-use input the orchestrator issued (for the Agent tool
  the `prompt` field, for Bash the `command` field, for Write the content and
  path, for Read and Edit their parameters, for Skill its arguments); the
  text of every tool result returned to it; and the user prompts of the
  slice. Harness attachments injected into user turns count; the
  transcript's duplicate copy of each tool result (`toolUseResult`) and
  record metadata do not.
- **Numerator — prompt material.** The sum of: every Agent `prompt` field
  (pointers included); the content of every Write call, and the `command`
  text of every Bash call, that writes a value file under the prompt
  directory; the `command` text of every fill command; and every Read result
  whose path is one of the four templates or a file under the prompt
  directory. Excluded: `test -s`, `mktemp -d`, `ls` of the directory and
  every other Bash call; the log, `state.md`, ruling-record and Case writes;
  every controller return; the Skill invocation's own text.
- **Target.** Numerator below 10 percent of the denominator. For
  comparison, Case 017 measured the template re-sends alone at about a
  quarter of the orchestrator's used window on the
  `autonomous-in-run-decisions` run (16 dispatches, 13 of them byte-identical
  retries). Report the session's peak context — the maximum, over its
  assistant messages, of (input + cache-read + cache-creation tokens) —
  beside the percentage.
- **Closure.** Row 13 fix 1 in `docs/orchestration-issues.md` closes when the
  measure is taken, whatever the number: the 10 percent figure is not an
  acceptance gate for this branch, it selects what comes next — fix 2 (the
  scribe subagent) when the target is met, a second measurement of where
  the window went when it is not.

## Failure-mode check

Adversarial pass over the chosen design; each mode has its answer or its
accepted status.

1. **A compaction removes the literal path.** Answered in Interfaces: a
   fresh `mktemp -d`, the counter restarts at 1 in the new directory, an
   identical retry re-fills the same content there. The cost is one fill. The
   compaction probe stays owed.
2. **The counter slips and a fill targets a dispatched file.** The script
   exits 5 when `--out` exists with different content and 0 when the content
   is identical, so a dispatched prompt is never replaced and an identical
   re-fill is harmless. A `file already exists` exit on different content
   is fatal at once (Error handling, mirroring `multi-code-review`): the
   guard is the point, and `ls <PROMPT_DIR>` before the fill is how the
   orchestrator avoids reaching it.
3. **A controller ignores "do not read any other file there".** The
   directory holds this session's prompt files, answer files and, briefly,
   one-line secrets-probe files. A sibling prompt
   tells a controller about another phase's task; an answers file holds
   ruling answers in the location-only form for anything secret-bearing.
   Nothing there is a secret, and nothing there is an instruction the
   controller would follow before its own file. Accepted, as
   `multi-code-review` accepted it.
4. **The empty `## Resume Answer` section confuses a controller into
   believing an answer exists.** The section carries a fixed sentence
   stating what an empty section means, and every rule keyed on the
   section now keys on answer lines. A wording test asserts the fixed
   sentence; the in-run-rulings suite asserts the answer-line rules.
5. **The secrets hook refuses the answers file on every resume** (Case
   021's failure mode one level up). The location-only rewrite is applied
   before the second attempt, the withheld line keeps its id, and the
   orchestrator's own answer rule already forbids the quoted secret; a
   second refusal is a real defect and stops the run visibly.
6. **The fill command in the skill text drifts from a template's
   placeholders** after a later edit to one and not the other. Exit 3 or 4
   at the next run, and the fill-script test that cross-checks the names
   fails at the next test run. Not silent.
7. **The saving is smaller than expected because the orchestrator's window
   is dominated by its own writing** (Case 017's second contributor). True
   and out of scope: this change removes the first contributor only; the
   measure reports the percentage and the peak, and row 13 fixes 2 and 3
   follow.

## Rollout

One branch, `feature/orchestrator-prompt-pointer`, from `main` at
`f1e1ddd`. The change is text and tests only; nothing runs at install time.
The installed copy is byte-identical to the checkout after the release's
reinstall; `hooks/skill-rules.json` is unchanged (no new or renamed skill).
Release work — version bumps, the release notes, `docs/guide/` — is a
separate step after Phase 5 and is out of this run's scope.

## Amendments

None yet.
