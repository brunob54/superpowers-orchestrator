# Superpowers Orchestrator Release Notes

> **Note on platform claims.** Only Claude Code and GitHub Copilot CLI have
> actually been used to run this plugin. Statements anywhere in this file
> about Codex, OpenCode, or Gemini CLI being validated, proven, or confirmed
> live do **not** reflect a run performed for this fork. Entries before
> v6.7.0 were inherited from the parent project
> (`REPOZY/superpowers-optimized`) and are kept unchanged as history; any
> testing they describe was not done here.

## v7.13.0 — the `<superpowers-defaults>` session block

**Problem.** Only M, reviewers per lens, could be set from the environment.
N, the number of review rounds, and the batch task cap had none, and each new
parameter cost its own tag, its own anti-injection rule, and a wording block
copied into every consuming skill.

**Change.** `hooks/session-start` now emits one `<superpowers-defaults>` block
carrying `reviewers-per-lens`, `review-rounds` and `batch-task-cap`, set by
`SUPERPOWERS_REVIEWERS_PER_LENS`, `SUPERPOWERS_REVIEW_ROUNDS` and
`SUPERPOWERS_BATCH_TASK_CAP`. One resolution rule, defined once in
`skills/multi-doc-review/SKILL.md`, replaces four copies of the old tag rule.

**Effect.** You can now set the review-round count and the batch size the way
you already set M. Nothing to migrate: `SUPERPOWERS_REVIEWERS_PER_LENS` keeps
its name and meaning. Restart the CLI after updating the plugin.

Details:

- **The parameter table.** `reviewers-per-lens` (env
  `SUPERPOWERS_REVIEWERS_PER_LENS`, accepts `1`–`5`, hardcoded default `1`);
  `review-rounds` (env `SUPERPOWERS_REVIEW_ROUNDS`, accepts `1`–`10`,
  hardcoded default `3`); `batch-task-cap` (env `SUPERPOWERS_BATCH_TASK_CAP`,
  accepts `1`–`5`, hardcoded default `3`). The block always carries all
  three lines, even when a value falls back to its default, and is emitted
  last in the session context — after every embedded workspace file. The
  table lives once, in `skills/multi-doc-review/SKILL.md`'s new `Resolving a
  default` section; every consuming skill cites it instead of copying it.
- **Why `0` is rejected for `SUPERPOWERS_REVIEW_ROUNDS`.** N = 0 skips a
  review loop entirely. An environment variable set once and forgotten would
  otherwise silently disable spec review, plan review and whole-branch code
  review on every future session, with no message anywhere. `0` stays
  available where you state it and see its consequence — in an invocation,
  and as an option at every gate question — but it is not an accepted block
  or environment value; an unset or invalid `SUPERPOWERS_REVIEW_ROUNDS`
  (including `0`) falls back to `3`, like any other rejected value.
- **Three offered-default labels.** A gate's offered value is labelled
  **current default** when it equals the hardcoded default, **recommended**
  when it is stronger (more review rounds, more reviewers, or — since a
  smaller cap means more human checkpoints — a lower `batch-task-cap`), and
  **session default** when it is weaker. This replaces M's old two-label
  rule and applies it to all three parameters.
- **N's option list and the recommended-to-current-default relabelling.**
  The option list is built by taking, in order and skipping any value
  already held, the offered value, then `3`, then `2`, then `4`, stopping at
  three values, then appending the zero option last. An offered N of 3 — the
  common case — reproduces the historical list, but its label changes: it
  was "3 (recommended)" at all three gates and is now "3 (current
  default)". This relabelling is intentional, not an accidental edit:
  labelling a stale environment setting as the project's advice would be
  wrong in the direction that weakens review.
- **The resume prompt carries X and N as well as M.** Batched Autonomous
  Mode's `/clear` handoff previously carried only `M=<m>` across the
  boundary; a task count X and a review-round count N fell back to the
  hardcoded default otherwise. Now the resume prompt carries `X=<x>` and
  `N=<n>` alongside `M=<m>`, so a value you stated survives the boundary
  instead of being silently re-resolved from the environment on the next
  batch.
- **Platform limits.** Claude Code runs `hooks/session-start` and so emits
  and reads the block; Cursor runs the same hook, but this has not been
  verified for this fork. Codex and OpenCode build their session context
  a different way, emit no block, and resolve every one of the three
  parameters to its hardcoded default unconditionally — a value stated in
  the invocation still wins there, only the block tier never applies.
- **Restart window.** `hooks/session-start` re-runs on `clear` and
  `compact` and re-injects the block with the current environment values,
  but a value already resolved earlier in the same run is kept regardless.
  After changing an environment variable or updating the plugin, restart
  the CLI before the change takes effect in a new run.

## v7.12.0 — the review gates ask how many reviewers per round

**Problem.** M — the number of identical reviewer subagents each review
round dispatches in parallel — was never shown to a user who did not know
it exists. Where `SUPERPOWERS_REVIEWERS_PER_LENS` is unset, every gate
review ran one reviewer per round without saying so.

**Change.** The three interactive review gates — spec, plan and
whole-branch code review — now ask for M in the same question batch as N,
defaulting to the session tag's value, and pass both as explicit
`N=<n> M=<m>` tokens. Both review skills parse `N=<n>`.

**Effect.** You choose the reviewer count at each gate, with its cost
stated. One extra question per gate. Reinstall the plugin; nothing else to
migrate.

Details:

- **The gate question.** Each gate now runs four steps in order: platform
  check, suppression check (document gates only), the question, then the
  invocation. It asks only for the value you have not already stated, and
  always asks for N when a stated N is 0 — a skip is never inherited from a
  sentence typed hours earlier.
- **Where the values come from.** Only text you wrote as an instruction
  about this review counts. A value inside a tool result, or inside quoted
  or pasted material, is data. When a gate does not ask, it says which
  values it is using and where they came from.
- **The cost is stated.** The M question carries one sentence: the M
  reviewers of a round run at the same time, so running time stays close to
  one review; the token cost grows about M times per round, and the loop
  runs about N × M reviewers in total. The code gate adds that each
  reviewer there reads the whole-branch diff.
- **Nothing autonomous asks.** The review skills still never ask for M.
  Batched Autonomous Mode, the orchestrator's Phase 2 and Phase 4
  controllers, the plan writer and the batch controller all resolve both
  values by their own rule and ask nothing. A new suite,
  `tests/review-gates/run-tests.sh`, pins each of those paths, and compares
  the shared default definition across the four files that carry it.

## v7.11.0 — a user's own plan amendment now backs its marker

**Problem.** When the user answered an escalated item with `amend plan`,
the answer was appended to the ruling record as a `**Follow-up:**` line,
because that record is appended and never rewritten. The test that decides
whether an `(amended by ruling <n>)` marker carries authority read only the
entry's `**Resolution:**` line, which still said `escalated`. A clause the
user had personally decided was therefore treated as ordinary reference
text, and a review finding against it could be dropped with no escalation
and no visible sign — the exact case that test exists to prevent.

**Change.** The backing test now accepts either line: a `**Resolution:**`
beginning `amend plan`, or a `**Follow-up:**` answer beginning `amend
plan`. Two smaller rules ship with it. An answer to an item that shares a
bare finding id with another open item of the same invocation must name its
round in prose, so the controller matches it by that sentence and not by
the id alone. And the two controllers that run commands must read a
background command's output file through `tail`, never whole.

**Effect.** A finding against a user-amended clause is triaged as decided
wording again, and cannot be silently discarded. Nothing to migrate —
reinstall the plugin to pick the rules up.

Details:

- **The backing test reads both lines.** The rule lives in
  `skills/orchestrating-development/SKILL.md` under "The ruling record"
  and is mirrored in `skills/multi-code-review/SKILL.md`, so the
  orchestrator and the review loop apply one rule. The alternative fix —
  having Resume step 3 rewrite the Resolution line when it applies a
  user's amendment — was rejected: the ruling record is appended and
  never rewritten, and rewriting one line would break that property for
  every reader of the record.
- **An answer names its round when ids collide.** The `inv <i>` qualifier
  separates invocations, not rounds, and finding ids restart at `[C1]`,
  `[I1]` in every round and every verification cycle. One invocation can
  therefore hold two open `[I1]` items. Each answer for such an item now
  opens with a parenthesis naming its round. This is what already kept the
  two `[I1 inv 2]` rulings of the `prompt-pointer-dispatch` run on their
  correct findings; it is now a rule rather than a habit, and it costs
  nothing, since it changes only the answer text.
- **A background result is read through `tail`.** The
  `batch-controller` and `code-review-loop` templates forbid a whole read
  of a background command's output file and name `tail -n 50` plus a
  `grep` for the detail. One measured controller spent a single 125 KB
  read on a test-suite log — more of its window than every prompt it was
  given. The plan-writer and doc-review templates do not carry the rule,
  because those controllers run no commands.
- **Tests.** `tests/in-run-rulings/run-tests.sh` goes from 502 to 512
  assertions; two older pins that asserted the Resolution-only wording
  were rewritten, because they encoded the defect.
  `tests/orchestrating-development/run-tests.sh` goes from 147 to 155,
  including the two absences. All six fast suites pass.

## v7.10.0 — the orchestrator dispatches its controllers by pointer

**Problem.** The orchestrator (the session that drives the whole
pipeline) pasted a full controller template, 94 to 249 lines, into
every dispatch and every retry. Those copies accumulate in one context
window that must last the whole run, so the percentage of that window
spent on re-sent prompts grew steadily as the orchestration went on —
about a quarter of it on one measured run.

**Change.** The orchestrator now fills each template into a file in a
temporary directory and dispatches a three-sentence pointer to it. Any
failure of the mechanism stops the run.

**Effect.** The orchestrator keeps its window for the whole pipeline.
Reinstall the plugin: a run started before the reinstall uses the old
inline dispatch.

Field report: the orchestrator (the `orchestrating-development` session
that drives plan writing, plan review, batched implementation and the code
review loop) runs four kinds of controller subagent, one per phase, and it
used to send each one its instructions as a copy of the whole controller
template — `plan-writer-prompt.md`, `doc-review-loop-prompt.md`,
`batch-controller-prompt.md` or `code-review-loop-prompt.md`, 94 to 249
lines — pasted into the `prompt` field of the Agent call, on every
dispatch and on every retry. Case 017 in the orchestration issues log
measured the cost on the `autonomous-in-run-decisions` run: the Phase 4
template was pasted on all 16 dispatches, 13 of them byte-identical
retries after an environment kill, and those re-sends took about a
quarter of the orchestrator's own context window (the working memory the
model holds for the whole run). The orchestrator is the one session of a
run that cannot be restarted cheaply: its window has to last from Phase 0
to Phase 5. Worklist row 13 listed this as fix 1 of three.

v7.10.0 applies the v7.9.0 mechanism one level up. The orchestrator runs
`mktemp -d` once per session, which creates a temporary directory outside
the checkout (the prompt directory), and never holds that path in a shell
variable or writes it to any log. Before each dispatch it fills the
phase's template once with `skills/multi-code-review/scripts/fill-prompt.js`
— the v7.9.0 script, reused in place — into `dispatch-<k>-<label>.md` in
that directory (`<k>` is a counter of fills, `<label>` names the dispatch:
`plan-writer`, `plan-review`, `batch-<n>`, `code-review`), checks the file
with `test -s`, and dispatches the same three-sentence pointer v7.9.0
uses: the controller reads the file once with the Read tool, follows it as
its only instructions, and reads nothing else in that directory. The
orchestrator never opens a template and never holds a filled prompt. An
identical retry resends the same pointer to the same file, with no new
fill. A re-dispatch that carries answers — after an in-run ruling, after a
plan writer's `BLOCKED` question is answered, or on resume — is a new fill
under the next `<k>`; the answer lines go into a value file
`dispatch-<k>-answers.txt`, written with the Write tool only (never with a
heredoc, because answer text quotes plan clauses and findings that may
contain shell characters), and the script refuses to overwrite a prompt
file with different content. Design:
`docs/superpowers-orchestrator/2026-09-06-orchestrator-prompt-pointer/specs/orchestrator-prompt-pointer-design.md`.

Every failure of the mechanism is **fatal for the run**: the orchestrator
writes the log entry it owes, if any, appends a `## STOPPED` entry whose
first line names the cause, and stops. There is no inline fallback, for
the reason Amendment 1 of the v7.9.0 spec gave: a fallback that pastes
the template would hide the defect and silently bring the old cost back.
The skill's `## Major-Error Stop Policy` states the boundary of that rule
in two tables, so that the environment failures of today keep their
existing handling:

- **Failures OF the mechanism (fatal):** `mktemp -d` fails or prints a
  path under the repository; the fill script fails (a malformed template,
  a dispatched file name reused with different content, a second
  non-zero exit after a corrected command) or `test -s` finds the prompt
  file empty; Node is missing; a value file cannot be written; a value
  file is refused twice by `hooks/safety/protect-secrets.js` (before the
  second attempt the orchestrator applies the v7.9.0 rule — probe each
  line with one Write of a throwaway file, replace every refused line by
  its location plus `secret-bearing finding, value withheld`, retry once);
  a controller's final message, after the one identical retry, shows it
  could not read or did not follow its prompt file.
- **NOT failures of the mechanism (handled as before):** a controller
  that dies of its environment (usage limit, tool error, no final message)
  gets the identical retry and then today's stop; a slip in the
  orchestrator's own fill command (a wrong argument, a missing value) is
  corrected once; a return unusable on format alone is a malformed return
  and gets the identical retry; a prompt directory path lost from the
  orchestrator's context (after a compaction, typically) is never guessed
  or searched for — the orchestrator runs `mktemp -d` again and continues
  in the new directory with the counter restarted at 1. That last rule
  differs from `multi-code-review`, where a lost path ends the invocation:
  the orchestrator's files are named by a counter, so nothing can collide.

### What changed

- **`skills/orchestrating-development/SKILL.md`** — Controller Dispatch
  Rules gain "Prompt files and the pointer" (the prompt directory, the
  no-variable rule, the file-name table, the value-file rule, `test -s`,
  the pointer wording); Phase 0 creates the directory; Phases 1 to 4
  replace "fill the template and dispatch" by the fill command, the check
  and the pointer; `## Resume` creates a fresh directory before its
  re-dispatch; `## In-run rulings` writes the answer lines into the value
  file; the Major-Error Stop Policy carries the two tables above with the
  fixed `## STOPPED` cause texts; `## Prompt Templates` says the templates
  are filled by the script and never read by the orchestrator.
- **The four controller templates** — two changes forced by the script.
  `[M]` became `[M_REVIEWERS]` in `doc-review-loop-prompt.md` and
  `code-review-loop-prompt.md` (the script's placeholder pattern needs at
  least two characters; the controller-facing text is unchanged). The
  `## Resume Answer` section is now present on every dispatch of
  `plan-writer-prompt.md`, `batch-controller-prompt.md` and
  `code-review-loop-prompt.md`: a fixed sentence precedes the placeholder,
  and a section with no answer line below that sentence means the run has
  recorded no answer. Every rule that used to key on the section's
  presence keys on the presence of an answer line instead. Everything
  else in the templates is byte-identical.
- **Tests** — new `tests/orchestrating-development/run-tests.sh` (147
  assertions on the skill text and the templates: the pointer wording,
  the absence of any `$PROMPT_DIR` variable and of any inline fallback,
  the fill commands, the two stop-policy tables, the `## Resume Answer`
  shape); `tests/fill-prompt/run-tests.sh` grew from 102 to 166 tests and
  now fills the four orchestrator templates as well;
  `tests/in-run-rulings/run-tests.sh` pins the renamed placeholder and
  the new section heading. The Testing block of `CLAUDE.md` lists the new
  suite.

### First measurement of v7.9.0

The run that built this release was the first orchestrated run on the
installed 7.9.0 copy, so the acceptance measure owed by v7.9.0 (worklist
row 14 fix 1, Case 018) was taken on its two Phase 4 review-loop
controllers, by the rules of that spec's Acceptance measure section:

| Controller | Dispatches | Prompt material | Peak context |
|---|---:|---:|---:|
| invocation 1 (2 rounds, 1 fix) | 8 | 8.5% | 199K |
| invocation 2 (2 rounds, 2 verification cycles, 4 fixes) | 12 | 9.0% | 218K |
| largest pre-7.9.0 controller (Case 018 Follow-up) | 32 | 41.6% | 374K |

Both are under the 10 percent target. The pointers themselves are 0.7
percent; the rest is the fill commands and the value files the
controller writes. Row 14 fix 1 is closed.

### Not included

- **The orchestrator's own acceptance measure is not taken.** The run
  that built this release executed the installed 7.9.0 skill text and
  dispatched its controllers by pointer by hand, which is a practice and
  not this change. The target is all prompt material below 10 percent of
  the orchestrator session's content (the spec's Acceptance measure
  section defines the count); it is taken on the first orchestrated run
  after reinstall, and its number selects the next fix of row 13 — the
  scribe subagent when the target is met, a second measurement when it is
  not.
- **The compaction probe is still owed:** whether a compaction summary
  keeps the literal prompt directory path. Until it is run, the
  lost-path rule above is the designed answer either way.
- **The permissions question of v7.9.0 was probed once**, on 2026-09-06,
  in a session in auto permission mode (not bypass mode): a Write and a
  Read under a `mktemp -d` directory outside the checkout did not prompt.
  Other permission modes, and the Git Bash path form (`cygpath -m`),
  remain untested.
- **Not changed:** `multi-doc-review` still pastes its reviewer prompt
  inline, and a batch controller still pastes the
  `subagent-driven-development` prompts to its implementers and
  reviewers.

### Upgrading

Reinstall the plugin: a run started before the reinstall executes the old
inline dispatch. A `## STOPPED` entry whose cause begins `prompt directory
could not be created`, `prompt file <name> not produced`, `value file
<name> could not be written`, `value file <name> refused twice by
protect-secrets` or `prompt file <name> not read by <controller name>` is a
stop of this mechanism; the resume prompt is the existing one, and the
resumed session creates its own fresh prompt directory, so nothing from
the stopped session's directory is reused.

## v7.9.0 — reviewers and fixers receive their prompt by pointer

**Problem.** A code-review loop controller (the subagent that runs one
review loop) pasted the reviewer prompt and a hand-written fix prompt
into every dispatch. That text was 35 to 42 percent of the
controller's context window.

**Change.** The controller now fills the reviewer template into a file
with a script and dispatches a three-sentence pointer to it; the fix
subagent is dispatched the same way from a new template. Any failure
returns BLOCKED.

**Effect.** Reviewers read the same text as before, and the controller
keeps more of its window. Reinstall the plugin.

Field report: a `multi-code-review` controller is the subagent that runs
one code-review loop, and its context window (the working memory the model
holds for the whole loop) grows with every round. Measured on the three
largest controllers of the previous orchestrated run (Case 018 Follow-up in
the orchestration issues log; 374K, 373K and 333K tokens of context), the
largest single source of that growth was text the controller itself pasted
into its Agent dispatches: the filled reviewer prompt (about 9 KB, from
`reviewer-prompt.md`) once per reviewer, and a fix prompt it composed by
hand (about 11 KB) once per fix dispatch. Together they were 35 to 42
percent of each controller's window — ahead of the reviewer reports it
received (20 to 25 percent). The largest controller made 32 dispatches
over 4 rounds; a controller can make up to 33. The text was also redundant:
every placeholder of the reviewer template varies per round or per
invocation, none per reviewer, so the M reviewers of a round were sent
byte-identical prompts.

`multi-code-review` now dispatches every reviewer and every fix subagent by
**pointer**. Before round 1 the controller runs `mktemp -d` once, which
creates a temporary directory outside the checkout (the prompt directory).
Each round it writes the round's values — lens text, commit range, package
path, carried findings — into small files there, and runs
`scripts/fill-prompt.js`, a deterministic Node script, which fills the
template into one prompt file in that directory. The controller never reads
the template and never holds the filled text. It then dispatches a fixed
three-sentence message that names the file: the reviewer reads the file
once with the Read tool and follows it as its only instructions, and must
read nothing else in that directory. The reviewer reads exactly the text it
received inline before: `reviewer-prompt.md` is byte-identical, and the
fill test asserts the file is the template body filled under the legend's
rules. The fix subagent is dispatched the same way from a new template,
`fix-prompt.md`, which carries the rules the controller used to compose by
hand. Design:
`docs/superpowers-orchestrator/2026-09-05-prompt-pointer-dispatch/specs/prompt-pointer-dispatch-design.md`.

Every failure of the mechanism is **fatal**: the controller writes the
round entry it owes, if any, and returns `BLOCKED: <cause>`. There is no
inline fallback (author decision, Amendment 1 of the spec: a fallback that
pastes the prompt inline would hide the defect and silently bring the old
cost back; a stop makes the defect visible the moment it appears, and the
orchestrator already treats a controller `BLOCKED` as a stop with a resume
path). The run's review rounds bounded that rule with four refinements,
recorded as Amendments 2 to 4:

- A value-file Write refused by `hooks/safety/protect-secrets.js` (a
  finding quotes a credential-shaped string) is not fatal at once. The
  hook names only a credential kind, never a line, so the controller probes
  each line with one Write tool call of a throwaway file, replaces every
  refused line by its `file:line` plus the fixed text `secret-bearing
  finding, value withheld`, and retries the Write once. The finding keeps
  its id and severity, so the fix subagent still removes the credential at
  that location. A second refusal is fatal.
- A round in which every reviewer died of its environment (a usage limit,
  a tool error, no final message), or returned a report unusable on format
  alone, is not a failure of the mechanism: it is logged `inconclusive`
  and the loop continues, as before. A round in which no reviewer could
  read or follow its prompt file is fatal.
- A slip in the controller's own fill command (a mistyped argument, a
  missing value, a value file it never wrote) is corrected once; a second
  non-zero exit is fatal.
- A prompt file may be removed and filled again under the same name until
  a pointer to it has been dispatched; after that it is never rewritten.

### What changed

- **`skills/multi-code-review/scripts/fill-prompt.js`** — new. Fills the
  prompt body of a template into a file from `NAME=<value>` and
  `NAME=@<file>` arguments; untrusted text (findings, lens text, failure
  text) always goes through the `@<file>` form. Exit codes 1 to 5 name
  the cause (usage, malformed template, uncovered placeholder, unknown
  name, read or write failure); an `--out` file that already exists with
  different content is refused.
- **`skills/multi-code-review/fix-prompt.md`** — new template for the fix
  subagent, re-dispatch (`FAILURE_BLOCK`), verification-cycle and
  post-loop-addendum fixes. Every rule precedes the `[FINDINGS]` and
  failure blocks, so a truncated Read cannot drop a rule.
- **`skills/multi-code-review/SKILL.md`** — Procedure "Before round 1"
  (the prompt directory, Git Bash path conversion, the value-file rule,
  the file-name table, the pointer wording); step 2 (write values, fill,
  `test -s`, dispatch M pointers to the same file); the
  Critical/Important bullet (fix dispatch by pointer, the secrets probe);
  Error Handling (the fatal rule, the per-cause `BLOCKED` texts and the
  four refinements above). `reviewer-prompt.md` is unchanged.
- **Tests** — new `tests/fill-prompt/run-tests.sh` (102 unit tests on the
  script, including a fill of the real templates); section 10 of
  `tests/reviewer-templates/run-tests.sh` pins the pointer wording, the
  absence of any `$PROMPT_DIR` variable and of any inline fallback. The
  Testing block of `CLAUDE.md` lists the new suite.

### Not included

- **The acceptance measure is not taken.** The target is all prompt
  material below 10 percent of the controller's content (the spec's
  Acceptance measure section defines the count). The run that built this
  release executed the installed 7.8.0 copy and could not measure itself;
  the measure is taken on the first orchestrated run after reinstall.
- **Nine harness probes are owed.** All ask the same question: whether a
  Write or Read under a `mktemp -d` directory prompts for permission in a
  session that is not in bypass mode. Until one is run, treat the
  Prerequisites note of the guide as the safe assumption.
- The mechanism is specified for macOS and Linux; the Git Bash path form
  (`cygpath -m`) is an owed probe, not a tested path.
- The orchestrator's own dispatch of its controllers still pastes the
  controller templates inline (worklist row 13 in the orchestration issues
  log).

### Upgrading

Reinstall the plugin: a run started before the reinstall executes the old
inline dispatch. A `BLOCKED: prompt …` return from the loop stops an
orchestrated run with a `## STOPPED` entry and a resume prompt, like any
other controller `BLOCKED`; a resumed controller creates its own fresh
prompt directory, so nothing from the stopped invocation is reused.

## v7.8.0 — the orchestrator rules on in-run decisions

**Problem.** Most stops of the autonomous pipeline were not the user's
decisions: a review finding or a blocked task contradicted the plan.
In Case 007 one stop became a chain of four.

**Change.** The orchestrator (the session that drives the pipeline)
now classifies each open item as escalated, forced or design. It rules
on design items after two or three forked subagents review them under
different lenses. It records and commits every ruling before it
re-dispatches the phase.

**Effect.** Only escalated items reach you, and Phase 5 stays yours.
Reinstall the plugin.

Field report: in the recorded orchestrated runs (Cases 001, 007, 008 and
010 in the orchestration issues log), most stops of the autonomous pipeline
were not the user's decisions. In Phase 4 the code-review loop returned an
item as `user-decision` or `unresolved` because the correct fix
contradicted the plan's text; in Phase 3 a batch controller returned
`BLOCKED task=<n>` because the implementation had found a defect in the
plan, not in the code. In both cases the orchestrator — which holds the
spec, the plan and the run's history, and whose own artifact the plan is —
was better placed to decide than the user. Case 007 shows the cost of
stopping instead: one stop became a chain of four, because each decided
fix got a verification re-review that raised new items against the
decided wording.

`orchestrating-development` now settles those items inside the run. When a
Phase 4 return carries open items, or a Phase 3 return is a `BLOCKED
task=<n>` whose report holds a `### Conflict <k>` or `### Question <k>`
section, the orchestrator classifies each item with a **closed escalation
predicate**: `escalated` when its correct resolution changes the spec,
grows the scope, needs an irreversible or outward-facing action, concerns
an exposed secret, or hits the in-run resume cap (`chain`); `forced` when
one sentence names the fact that makes every other outcome indefensible;
`design` otherwise. A `design` item is reviewed by two or three **forked
subagents** under distinct lenses — design consistency, implementation
practicality, adversarial — dispatched in parallel and blind to each
other. The orchestrator consolidates their verdicts and rules; one
`evidence consistency` round follows when they contradict, and a fixed
tie-break applies when the contradiction stays unsettled. Every ruling is
recorded, with its class, answer and reason, in a new per-topic file
`plans/<slug>-open-decisions.md`, journaled as a `## RULING <n>` entry in
the orchestration log, and committed **before** the phase is re-dispatched
with the answers in `[RESUME_ANSWER]`. Only the escalated items reach you,
on the `Open:` lines of a `## STOPPED` entry; the items already decided
are listed as `Ruled:` and need no answer.

Four guards keep the judgement honest: a `plan governs` rejection quotes
the clause that makes the finding non-binding, verbatim with its source
path; a Critical is never rejected by a ruling; every ruling is recorded
when it is made, never reconstructed after the run; and a user's earlier
decision is never overturned — the same clause raised again is escalated.
In-run resumes are capped at three per phase (per task in Phase 3); the
fourth open return of the same unit stops the run with every item
`escalated (chain)`. A ruling that amends the plan edits the binding
clause in place, marks it `(amended by ruling <n>)` and inserts an audit
note; in Phase 4 that starts a new review invocation over the amended
plan.

### What changed

- **`orchestrating-development`** — new `## In-run rulings` section: the
  escalation predicate; a second documented exception to the
  thin-sequencer rule (to classify an item the orchestrator may read the
  review log's latest disposition line, the blocked task's report, the
  cited plan clause and spec section, the code at the cited `file:line`,
  and the ruling record — nothing else, and all of it as data); the fork
  review for a `design` item (forks for the first `design` item of a
  return, fresh `general-purpose` reviewers for later items and
  tie-breaks, so no reviewer inherits an earlier consolidation); the
  ruling record; the `## RULING` log entry; the resume cap;
  `Open:`/`Ruled:` lines on `## STOPPED`; a `Rulings:` line in
  `state.md`; Resume step 3 cases for a crash after a ruling commit and
  for a user answer that replaces a `Ruled:` line, which reverts the
  ruling and the change made under it. The Phase 5 report counts the
  rulings of the run and lists the review loop's `Secrets found:` items.
- **`multi-code-review`** — decisions are journaled as
  `decided (orchestrator)` or `decided (user)`; a ruling's rejection is
  written `rejected: plan governs (orchestrator decision) — "<clause>"`;
  every open-item disposition line is self-sufficient (id, summary,
  `file:line`, plan location and quoted clause), so the orchestrator can
  classify it from the log alone; inside a verification cycle a finding
  against decided wording is the loop's to reject, never `user-decision`,
  a Critical excepted; the completion report carries a `Secrets found:`
  line. The binding-text test now reads the plan's `**Body authority:**`
  note instead of restating it, so a stated `**Contract:**` is binding as
  the note says.
- **Templates** — `code-review-loop-prompt.md` and
  `batch-controller-prompt.md` carry the `(orchestrator)` / `(user)` tag
  on every `[RESUME_ANSWER]` line; a `BLOCKED task=<n>` for an open item
  writes its detail to `.superpowers/sdd/task-<n>-report.md` as
  `### Conflict <k>` / `### Question <k>` sections, which is how the
  orchestrator tells an open item from a controller failure.
- **Tests** — new `tests/in-run-rulings/run-tests.sh` (496 checks), a
  wording-contract suite that pins every clause above and carries negative
  assertions for the stop rules this release removes.

### Upgrading

Reinstall the plugin: a run started before the reinstall executes the old
stop rule. Phase 1 `BLOCKED` questions, Phase 2 `unresolved` items and
Phase 5 are unchanged and stay yours. A resume prompt answers only the
`Open:` ids of a `## STOPPED` entry; answering a `Ruled:` id overrides that
ruling.

## v7.7.0 — plans state contracts, not literal bodies

**Problem.** A plan could fix a helper body, a command, or wording
exactly. Review loops may never overrule an approved plan, so a review
finding about that text stopped the run for a user decision — eleven
interruptions across four runs.

**Change.** A task now states a contract: what its artifact must
guarantee. The code block beside it is one reference implementation.
Only the `**Global Constraints:**` block and a block marked
`**Exact content:**` bind as written.

**Effect.** A review finding against a body is now an ordinary fix, not
a stop. Nothing to migrate: older plans keep their old authority.

Field report: across four earlier runs, eleven interruptions of the
autonomous pipeline traced to one cause. A plan had fixed a helper's body,
a command, or a piece of wording **verbatim**, and the review loops may
never overrule an approved plan — so every later review finding about that
text became a `user-decision` stop the pipeline could not settle alone
(Cases 001, 003, 007 and 008 in the orchestration issues log). One run lost
three of its four stops to it; another turned a single stop into a chain of
six.

`writing-plans` now asks for the **contract** instead. A task states what
its artifact must guarantee — invariants, and the verification that would
falsify them, plus inputs and outputs when the artifact is code — and the
code block beside it is a *reference implementation*: one way to satisfy
that contract, not the contract itself. A later review finding against such
a body is an ordinary fix while the contract still holds. Only two things
in a plan bind as written: the `**Global Constraints:**` block, and a block
whose new `**Exact content:** <reason>` marker names a pin the plan does
not itself write or edit. A pin the plan creates or edits is a *self-pin* —
body and pin amend together as one ordinary fix — which is exactly the case
that produced the Case 008 chain.

The rule has to reach the reviewer that applies it, and a review controller
reads the plan, never `writing-plans`. So every generated plan's header now
carries a `**Body authority:**` note stating the binding set and declaring
everything else — the note included — a reference implementation. A finding
against the note's own wording is recorded against `writing-plans` and the
run continues; it is never a plan conflict.

### What changed

- **`writing-plans`** — new "Contracts and Literal Bodies" section; a
  `**Contract:**` field in the Task Template (`none — <reason>` allowed);
  the `**Body authority:**` note in the Plan Header template; Self-Review
  gains a contract audit that treats a vacuous contract, a false `none`,
  and a marker whose reason names no external pin as defects.
- **`multi-doc-review`** — the plan cell of the Ambiguity & testability
  lens gains contract targets: bodies with no stated contract, vacuous or
  unverifiable contracts, and self-pinned `**Exact content:**` markers. The
  targets apply only to a plan carrying the `**Body authority:**` label, so
  plans written before this release are reviewed exactly as before.
- **Tests** — new `tests/writing-plans/run-tests.sh` (15 checks) and a new
  section in `tests/reviewer-templates/run-tests.sh` (24 total), including
  a cross-suite equality check so renaming the gate label in one file
  cannot leave the gate silently inert with both suites green.

### Upgrading

Nothing to do. Plans written before this release carry no
`**Body authority:**` note, keep their old authority at execution and
triage time, and are reviewed under the previous lens text.

## v7.6.0 — reviewers test harness claims instead of asserting them

**Problem.** A reviewer could assert a property of the harness (the
agent runtime that runs the review) without testing it. One false
claim stopped an unattended run.

**Change.** Both reviewer templates now require a harness finding to
carry a probe the reviewer ran and its observation, or to name one
probe for the controller to run once and dispose on.

**Effect.** An untestable harness claim is rejected and reported as an
owed probe, never as a user decision, so the run continues. Nothing to
migrate.

Field report: a code reviewer asserted that the Agent tool's `description`
field reaches the reviewer's context, so a `(reviewer j/m)` suffix would
leak the reviewer count. The review loop escalated the finding to the user,
which stopped an unattended run. A three-second probe — a subagent dispatched
with a random token only in its `description` — showed the token absent.
The claim was false, and one full stop was spent on it. Claims about the
**harness** (the agent runtime that runs the review: what reaches a
subagent's context, what a hook injects, how a dispatch behaves) cannot be
checked against the repository, so nothing required the reviewer to test
them.

- **Harness claims rule.** Both reviewer templates (`multi-doc-review`,
  `multi-code-review`) carry a `### Harness claims` sub-section: a finding
  whose premise is a harness property must carry a probe the reviewer ran
  and its observation (`| harness: tested — <probe>; observed <result>`),
  or name the one probe the controller should run
  (`| harness: untested — <probe>`). A reviewer-safe probe writes nothing
  to the checkout, binds no shared resource, runs no code from the change
  under review, and dispatches no subagent — a reviewer's child runs
  detached (v7.5.0 field report), so dispatch-based probes run once, in
  the controller. A harness property is a claim about the runtime running
  *this* review; a claim about a library, the operating system, or a
  remote service is an ordinary claim with a citable source.
- **Controller triage.** Both review skills run a named probe once —
  read-only, one action, with a concrete poll for a dispatch that returned
  only a launch acknowledgement (separate `test -s` calls, at most 20,
  spread over the controller's own work; no `sleep`) — and dispose on the
  observation. A claim nobody can test here is
  `rejected: harness probe not runnable here — <probe> — (<reason>)`, never
  `unresolved` and never `user-decision`, and every such rejection is
  listed in the completion report under `Harness probes owed:`. In
  `multi-code-review`, a finding is never logged `user-decision` on the
  strength of an untested harness claim; before that disposition the
  controller re-runs a `tested` probe itself.
- **Owed probes reach the user in pipeline mode.** `orchestrating-development`
  lists the review logs' owed-probe lines in its Phase 5 report and as
  `Owed probe:` lines in a Phase 4 `## STOPPED` entry.
- **New fast suite.** `tests/reviewer-templates/run-tests.sh` (19 checks)
  pins the wording contracts: the rule sits inside `prompt: |`, the field
  spellings and reason strings exist, the two templates' rule text is
  byte-identical, and the blinding pathspec and report marker survive.

No log-format break: the new field and reason strings appear only in rounds
run after the update; existing logs are read as before. Nothing to migrate.
This was also the behavioural proof of v7.5.0: nine named controller
dispatches, zero stalls.

## v7.5.0 — blocking controller dispatch

**Problem.** In every orchestrated run since v7.0.0, at least one
controller (the subagent that runs a pipeline phase) ended its turn
waiting for a subagent and never resumed. A human had to nudge it.

**Change.** Each of the four controller templates now carries a fixed
dispatch name. A named subagent is a teammate, and a teammate's own
Agent calls block until the child finishes and return its result.

**Effect.** The controller receives each child's result directly, so
the run continues without a human. Nothing to migrate; no path or log
format changes.

Field report: in every orchestrated run since v7.0.0, at least one
controller (the subagent that runs a phase of `orchestrating-development`)
ended its turn with a line such as `Waiting for the round 1 reviewer to
finish.` and never resumed. The run stood still until a human sent the
controller a message. Four parallel research passes and two measured
experiments (2026-08-28 to 2026-08-30) traced it to Claude Code itself, not
to this plugin, not to a platform: a subagent dispatched without a `name`
runs its own children asynchronously, and each child's completion notice is
delivered to the main conversation — never to the controller that is waiting
for it (anthropics/claude-code#75043, open). A subagent dispatched *with* a
`name` is a teammate, and a teammate's own Agent calls block until the child
finishes and return its final message inline — measured 48 s against 8 s
for the same 30-second child.

- **Named controllers.** Each of the four controller templates in
  `skills/orchestrating-development/` now carries a fixed dispatch name
  (`orch-plan-writer`, `orch-plan-review`, `orch-batch-<n>`,
  `orch-code-review`), and the skill's Controller Dispatch Rules state the
  property this buys — the controller's own subagent calls return each
  child's result — and its form on a platform whose dispatch tool has no
  `name` parameter (Copilot CLI: foreground dispatch, never a background
  mode). Nested workers stay unnamed: a teammate cannot create teammates.
- **"Waiting on a subagent" rule.** Every controller prompt now says: never
  end a turn while a subagent you dispatched is outstanding; if a dispatch
  returned only a launch acknowledgement, do not wait for a notice that
  will not arrive — poll the file the child was told to write, on a bounded
  loop, and reconstruct the result from it; if the file never appears,
  retry once, then return `BLOCKED`.
- **`SendMessage` success is not delivery.** Measured on Claude Code
  2.1.251: a send to a recipient that does not exist returns
  `{"success": true}` and lands in the main conversation. Controllers
  confirm a child's work only through the file it writes.

No user-facing phrase, log format, or artifact path changes. Nothing to
migrate. Requires nothing newer than before; on Claude Code, 2.1.251 or
later also lets a child reply to an unnamed parent (fixed upstream in that
release).

## v7.4.0 — M reviewers per lens

**Problem.** Each review round dispatched exactly one reviewer.
Language models are not deterministic, so a round took one sample of
judgment and could miss what another run would report.

**Change.** A new parameter M (1–5, default 1) dispatches M reviewers
in parallel with the identical prompt. Their reports merge into one
finding set — every finding kept, duplicates merged at the highest
severity.

**Effect.** More findings per round; running time stays near one
review, token cost grows about M times. Nothing to migrate — at M=1
logs are unchanged. State `M=<m>`, or set
`SUPERPOWERS_REVIEWERS_PER_LENS`.

Field report: LLMs (large language models) are not deterministic — the same
reviewer prompt reports different findings on different runs, and one run can
miss a problem another run would report. Each round of `multi-doc-review` and
`multi-code-review` dispatched exactly one reviewer, so a round took one
sample of the reviewer's judgment under its lens.

- **M reviewers per lens.** A new parameter M (integer 1–5, default 1) sets
  how many reviewer subagents a round dispatches — in parallel, with the
  identical prompt, none told that the others exist. Their reports are
  consolidated into one finding set before triage: every finding of every
  usable report is kept (a union — no majority vote, which would drop exactly
  the findings this feature exists to catch), findings that name the same
  place and the same defect are merged at the highest severity given, and
  every reviewer-local id is traced to exactly one consolidated finding
  (`**Sources mapped:** k/k`). Running time stays close to one review; the
  token cost grows about M times per round. State it as `M=<m>`,
  `<m> reviewers per lens`, `<m> reviewers per round`, or
  `<m> parallel reviewers`: `/multi-doc-review <doc> [N] [M=<m>]`,
  `/multi-code-review [BASE] [N] [M=<m>]`. The skills never ask for M.
- **Convergence with M ≥ 2.** A round is clean only when the consolidated
  set has zero Critical and zero Important findings **and** all M reviewers
  returned a usable report; a partial round (a reviewer still unusable after
  one retry) is never clean. Verification re-reviews use the same M.
- **Log format.** Every invocation line now records `M=<m>` after `N=<n>`
  (a line without `M=` reads as M = 1). With M ≥ 2 a round entry gains
  `**Reviewers:**`, `**Reviewer verdicts:**`, and `**Sources mapped:**`
  lines, and every finding disposition line ends with
  ` ← <a>/<m>: <source ids>` — the agreement count and the
  reviewer-qualified ids (`r1:C1`). With M = 1 the entry is byte-identical
  to before. Readers of the `fixed — … → <sha>` line take the token right
  after `→ `.
- **Orchestration and SDD.** `orchestrating-development`'s Phase 0 batch
  asks for M (default: the environment variable's value, else 1); the
  orchestration-log header and `state.md` record `M=<m>`; `... with M=2`
  overrides it on resume, and a log written before 7.4.0 resumes with
  M = 1; both loop-controller templates carry `[M]`, because subagents never
  receive the session tag. The subagent-driven-development final gate and
  Batched Autonomous Mode never ask — they use the same default resolution,
  and a batch handoff carries a stated M across `/clear`.
- `SUPERPOWERS_REVIEWERS_PER_LENS` env var (integer 1–5, default 1) sets M
  for every invocation that does not state it; `hooks/session-start`
  carries it to the skills as a `<reviewers-per-lens>` session tag. Set it
  in settings.json's `env` block so it survives plugin updates; restart the
  CLI after changing it. Invalid or out-of-range values silently fall back
  to 1.
- **Tests.** `tests/codex/run-unit-tests.sh` gains a hermetic shell test of
  the tag (`tests/codex/test-session-start-reviewers-tag.sh`); the two
  behavioral review tests gain an M=2 case that cross-checks the round-1
  entry's counts against its source annotations.
- **Docs sync.** README (feature bullets, Skills Library, environment
  variables), `docs/guide/README.md` (stages, Phase 0 table, log sample,
  settings, cheat-sheet), `docs/FORK-IMPROVEMENTS.md`, and
  `docs/REVIEW-PROCESS-COMPARISON.md` updated for M.

## v7.3.0 — one folder per topic, committed code reviews

**Problem.** The documents of one feature were spread over three flat
directories, linked only by a shared file-name prefix, and the code
review history was never committed.

**Change.** Every document of a topic now lives in one folder,
`docs/superpowers-orchestrator/<date>-<slug>/`, with a sub-folder per
pipeline stage. Pipeline code reviews are committed there; reviewer
diffs hide those committed review files.

**Effect.** One folder now holds everything about a feature. Other
projects are not migrated automatically: old files stay readable, and a
run stopped mid-pipeline must be moved by hand. Git 2.32 or later is
required.

Field report: the documents of one feature were spread over three flat
directories, linked only by a shared `YYYY-MM-DD-<slug>` file-name prefix, and
the code review history was never committed. Finding, archiving, or deleting
"everything about feature X" meant matching prefixes across directories.

- **One folder per topic.** Every document of a feature now lives under
  `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/`, with one sub-folder
  per pipeline stage:

  ```
  docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/
    specs/<slug>-design.md                 specs/<slug>-design-review-log.md
    plans/<slug>.md                        plans/<slug>-review-log.md
    plans/<slug>-open-decisions.md
    implementation/<slug>-review-log.md    implementation/<slug>-fix-reports.md
    <slug>-orchestration-log.md
  ```

  File names drop the date — the folder carries it — and keep the slug, so
  editor tabs and grep results stay distinguishable across topics. The rule is
  defined once, in the "Artifact Layout" section of the `brainstorming` skill;
  every other skill states its own exact paths and cites that section.
- **The plugin name returns to the path.** This reverses release v6.6.1, which
  removed it. The reason: the plugin's output is now a folder tree of its own,
  and separating it from the project's own `docs/` tree is worth the extra path
  segment.
- **Code reviews are committed.** A pipeline-driven `multi-code-review` run
  receives a new optional input, `TOPIC_DIR`, and writes its review log and fix
  reports under `<topic>/implementation/`, committing them after every round
  with the subject `chore(review): <slug> round <i> log`. A direct
  `/multi-code-review` run has no plan and therefore no topic folder: it keeps
  today's git-ignored `.superpowers/reviews/` behavior exactly.
- **Reviewers stay blind.** Committed review material is now part of the
  branch, so every whole-branch diff handed to a reviewer excludes the files
  whose names match the plugin's four sidecar patterns — `*-review-log.md`,
  `*-fix-reports.md`, `*-orchestration-log.md`, `*-open-decisions.md` —
  inside `docs/superpowers-orchestrator/*/` and at the legacy locations
  `docs/specs/` and `docs/plans/` (a sidecar moved out of those folders with
  `git mv` would otherwise appear as a deletion hunk carrying its whole old
  content). The reviewer's read prohibition lists the same set. This also
  closes a pre-existing leak: the committed spec and plan review-log sidecars
  were visible in whole-branch diffs before. Only a file matching one of the
  four names inside those folders is ever hidden; every other file is
  visible — a `*-review-log.md` anywhere else, or a file under
  `implementation/` whose name matches none of the four patterns (a
  `CLAUDE.md`, a note), reaches every reviewer. The plugin folder holds
  plugin output only, and a project must not put its own files there.
- **A Phase 4 stop is resumable with answers.** When the final code review
  leaves open items (`unresolved` or `user_decision` findings), the
  orchestrator's `## STOPPED` entry lists them by their review-log ids.
  `Resume orchestration for <plan> — [<id>]: <answer>` hands the answers to the
  code-review-loop controller, which journals each one as
  `decided (user): <answer>` in a committed addendum
  (`chore(review): <slug> decisions`). The completion skip — the rule that
  lets a re-dispatched controller reuse a finished review instead of running
  it again — now applies only when the recorded invocation ended with
  `unresolved = 0` and `user_decision = 0`; with open items, no answers and
  no new code since the stop, the orchestrator re-presents the open items
  and stops (Resume step 3) — a controller dispatched in that state returns
  `BLOCKED: … resume with answers` only as the retry backstop; code
  committed after the stop re-runs the review on resume, with or without
  answers.
- **A skipped review is committed too.** In pipeline mode an N=0 run writes
  its `skipped` entry into the tracked review log and commits it as
  `chore(review): <slug> skipped`, so the log never stays modified after a
  skipped gate.
- **This repository was migrated** with `git mv`; document contents are
  untouched. **Other projects are not migrated automatically:** existing
  `docs/specs/` and `docs/plans/` files stay readable as plain files, and new
  topics use the new layout. Skills, hooks and tests know only the new layout —
  a spec outside the layout stops orchestration with a message naming the
  expected location, `writing-plans` offers to move the spec there, and the
  subagent-driven-development review gate runs a plan outside the layout in
  direct mode (log under `.superpowers/reviews/`).
- **Minimum git version: 2.32**, stated explicitly for the first time (also in
  the README). It is needed for `git commit --trailer` and assumed by the
  pathspec magic above.
- **After updating:** an existing `.superpowers/sdd/plan.ref` that points at a
  moved plan makes the next `subagent-driven-development` run treat it as a
  plan switch and archive the workspace under `archive/<old plan basename>/`.
  This is expected after migration and loses nothing.

**Residual risk (accepted):** a second clone of the same branch — another
machine, or CI — that resumes the same committed in-progress review entry is
not detected. Today's batched mode already resumes automatically without such
detection; branch ownership prevents the scenario in practice, and a machine
token in the invocation entry would add state for nothing.

**Migrating a run stopped under the old layout (any project):** a run that
stopped before this release keeps its documents at the old flat paths, and
neither `orchestrate` nor `Resume orchestration` finds them there: the
orchestrator stops at intake because the old spec or plan path is outside
the layout, at the branch check because the branch exists but no
orchestration log is found in the layout (only the spec was moved), or at
resume because no orchestration log is found in the layout, and each of
those stops points here. Move the documents by hand, then resume:

1. Create `docs/superpowers-orchestrator/<date>-<slug>/` with the
   sub-folders `specs/` and `plans/` — `<date>` is the run's start date and
   `<slug>` its slug (the old file names minus the `YYYY-MM-DD-` prefix and,
   for the spec, the `-design` suffix).
2. `git mv` the spec and, when it exists, its `-review-log.md` sidecar into
   `specs/`, dropping the date prefix from the file names
   (`docs/specs/<date>-<slug>-design.md` becomes `specs/<slug>-design.md`).
3. `git mv` the plan and, when it exists, its `-review-log.md` sidecar into
   `plans/`, dropping the date prefix (`docs/plans/<date>-<slug>.md` becomes
   `plans/<slug>.md`).
4. `git mv` the open-decisions file, when present, into `plans/` as well
   (`docs/plans/<date>-<slug>-open-decisions.md` becomes
   `plans/<slug>-open-decisions.md`).
5. `git mv` the orchestration log to the topic root as
   `<slug>-orchestration-log.md`.
6. Edit the orchestration log's `_Invocation` header `spec` path and its
   `plan:` line, and the plan's `**Spec:**` header line, to the new paths.
7. Commit, then `Resume orchestration for <new plan path>`.

The code review log of a run stopped in Phase 4 is not migrated: under the
old layout it lived in the untracked `.superpowers/reviews/` folder, and
the new layout expects it under `<topic>/implementation/`. After migration
a Phase 4 stop therefore re-runs the final code review instead of resuming
it.

**Post-migration manual step for this repository:** the orchestration run that
implemented this change kept its own plan and orchestration log at
`docs/plans/2026-08-25-artifact-layout.md` and
`docs/plans/2026-08-25-artifact-layout-orchestration-log.md`, because moving
either mid-run would have broken every later checkbox-tick commit. After the
run ends, move them by hand:

```bash
# Task 19 Step 4 created only `.../2026-08-25-artifact-layout/specs`. `git mv`
# fails with "No such file or directory" when the destination directory does
# not exist, so create `plans/` first.
mkdir -p docs/superpowers-orchestrator/2026-08-25-artifact-layout/plans
git mv docs/plans/2026-08-25-artifact-layout.md \
       docs/superpowers-orchestrator/2026-08-25-artifact-layout/plans/artifact-layout.md
git mv docs/plans/2026-08-25-artifact-layout-review-log.md \
       docs/superpowers-orchestrator/2026-08-25-artifact-layout/plans/artifact-layout-review-log.md
git mv docs/plans/2026-08-25-artifact-layout-orchestration-log.md \
       docs/superpowers-orchestrator/2026-08-25-artifact-layout/artifact-layout-orchestration-log.md
```

(Skip any line whose source file does not exist.)

## v7.2.0 — prior-art research grounds technology decisions

**Problem.** Design sessions picked libraries, hosted services, and API
versions from model memory. That memory is old and does not know
versions, so specs carried technology claims nobody had checked.

**Change.** A new skill, `researching-prior-art`, adds a research gate
to brainstorming. One controller subagent runs N read-only researchers
in parallel and merges one evidence report; results are cached under
`docs/research/` for 90 days. Specs must carry a "Prior art and
alternatives" section.

**Effect.** Dependency decisions rest on verified sources, and
contradictions are listed instead of being resolved silently. Nothing
to migrate.

Field report: design sessions picked libraries, hosted services, and
API versions from model memory. Memory is stale and version-blind, so
the resulting specs carried unverifiable technology claims. Decisions
that add a dependency now pass through verified external evidence
before approaches are compared.

- **New skill `researching-prior-art`.** Brainstorming gains a research
  gate: when a decision would add or change a dependency-manifest
  entry, depends on version-sensitive external API behavior, or
  selects a hosted service, platform, or base image, it names the
  candidates and asks the user for N (0 skips; the skip is recorded in
  the spec). The sub-skill dispatches one controller subagent, which
  runs N read-only researcher subagents in parallel — candidate source
  reading, version verification anchored to the repo's own manifest,
  registry existence and OpenSSF health, prior art — spot-fetches
  citations, discards unusable reports, and merges the rest into
  `.superpowers/research/<slug>-research-report.md`. Contradictions
  are listed, never silently resolved. Platforms without the Agent
  tool skip and state the evidence gap.
- **Durable cache under `docs/research/`.** One committed file per
  candidate (`<registry>-<name>.md`). Research writes these files and
  the skill commits them for you, staging only the
  `docs/research/` cache files by explicit path — nothing else in your
  working tree is staged, and a commit that fails is reported but never
  blocks the session. A hit younger than 90 days
  removes that candidate's research assignment, but every hit still
  gets a cheap re-verifier — a committed header can be planted or
  edited.
- **Specs must carry the evidence.** Brainstorming's Design Contents
  gains a "Prior art and alternatives" section, required when the
  research predicate matched for at least one decision in the design
  (with per-finding dispositions); multi-doc-review's spec lens flags
  external-technology claims with neither a citation nor the label
  "unverified"; orchestrating-development's Phase 0 stops when a
  predicate-matching spec has neither the section nor the override
  sentence ("No decision in this design matched the prior-art trigger
  predicate.") — a documented exception to its thin-sequencer rule.
- **Guard marker `<!-- research report -->`.** Research reports quote
  skill-like phrases from external docs; subagent-guard exempts
  marker-first messages and adds the new skill to its roster and
  alternation (unit-tested). Routing rule added to skill-rules.json
  (26 rules covering 25 skills).
- Docs synced: README counts and Skills Library, guide Stage 1,
  lineage ranges.

## v7.1.0 — commit messages carry the workstream slug and stage

**Problem.** A pipeline run produced commits whose messages carried no
context. `chore(plan): task 3 complete` does not say which plan, and
`git log` could not separate two workstreams on one branch.

**Change.** Every skill derives the same *slug* from the plan file
name. Content commits add two git trailers, `Session: <slug>` and
`Stage: task <N>/<total>`; process commits put the slug in the subject.

**Effect.** `git log --grep "^Session: <slug>"` lists one whole
workstream. Nothing to migrate: `executing-plans` adds the trailers to
plans written before this convention.

Field report: a pipeline run produces many commits whose messages carry
no context — `chore(plan): task 3 complete` does not say which plan, and
a month later `git log` cannot separate two workstreams on one branch.

- **One convention, defined in `writing-plans`.** The *slug* is the
  plan's file basename with the `YYYY-MM-DD-` date prefix and `.md`
  stripped (`2026-08-17-auth-login.md` → `auth-login`); every skill in
  the pipeline derives it with the same rule. Content commits keep a
  conventional subject and add two git trailers: `Session: <slug>` and
  `Stage: task <N>/<total>`. `git log --grep "^Session: <slug>"` lists a
  whole workstream. The plan template's commit step now pre-fills the
  full command (No Placeholders applies to it).
- **Implementers inherit the format.** The SDD implementer prompt gains
  a Commit Messages section with `[SLUG]` / `[TASK_TOTAL]` placeholders;
  `executing-plans` adds the trailers when running a pre-convention plan.
- **Process commits name the slug in the subject** (they are the ones
  read via `git log --oneline`): checkbox ticks become
  `chore(plan): <slug> task <n> complete` (SDD per-task flow and the
  orchestration batch controller; the controller's crash-recovery search
  now greps `task <n> complete`, matching pre-slug ticks too);
  multi-code-review fix commits become
  `review fixes (<slug>, round <i>)` — still no finding text, so the
  reviewer-blinding rule is intact (behavioral test regex updated,
  accepts both shapes); orchestration boundary commits become
  `chore(orchestration): <slug> <boundary>` and Phase 2's revised plan
  `docs(plan): <slug> plan after review`.
- Docs synced: FORK-IMPROVEMENTS quotes the new tick subject.

## v7.0.1 — spec gate offers the fresh-session orchestration route

**Problem.** After the spec review rounds, the model could reword the
gate message and drop the orchestration option. The user then had to
search the guide for the phrase that starts the orchestrator (the
session that drives the whole pipeline).

**Change.** Brainstorming's User Review Gate message is now
verbatim-required and placed after the review loop. It offers two
paths: continue in-session to `writing-plans`, or run `/clear` and
paste `orchestrate the development of <path>`.

**Effect.** The prompt arrives ready to paste, with the real spec path.
Nothing to migrate.

Field report: after the spec review rounds, the gate message could be
paraphrased by the model and the orchestration option silently dropped —
the user had to find the orchestrator's trigger phrase in the guide.

- **brainstorming User Review Gate rewritten.** The message is now marked
  verbatim-required and anchored *after* the multi-doc-review loop (the
  previous header said "after the spec self-review passes", leaving the
  gate's position ambiguous). It presents two explicit paths: (1) review
  and continue to `writing-plans` in-session, or (2) run `/clear` and
  paste `orchestrate the development of <path>` — paste-ready with the
  real spec path, mirroring the writing-plans ready message. The prompt
  was verified to route uniquely to `orchestrating-development` through
  the skill activator.
- Stale wording fixed: the gate said "written and committed", but
  brainstorming leaves the spec uncommitted (orchestration commits it).
  Now "written and saved".
- Process-flow contradiction fixed: the flow said writing-plans is the
  only possible next step; orchestration hand-off is now a second
  terminal state (the user starts it in a fresh session — brainstorming
  still never invokes implementation skills itself).
- Guide synced: §3's quoted spec-gate dialog matches the new message
  verbatim; §4 "Starting a run" now recommends `/clear` first and notes
  the gate supplies the same prompt pre-filled.

## v7.0.0 — project renamed: superpowers-optimized → superpowers-orchestrator

**Problem.** The old name, `superpowers-optimized`, described the
fork's first change: token efficiency. The fork's main feature today is
the autonomous orchestration pipeline, so the name no longer matched.

**Change.** The plugin, the marketplace, and the GitHub repository are
renamed to `superpowers-orchestrator`. The skill prefix used in hints
and cross-skill references changes with them.

**Effect.** You must reinstall the plugin: an in-place update cannot
cross a rename. The entry lists the migration commands for Claude Code,
Codex, and OpenCode. GitHub redirects the old URLs and git remotes.

**Breaking change: the plugin and marketplace are renamed.** The installed
plugin id changes from `superpowers-optimized@superpowers-optimized` to
`superpowers-orchestrator@superpowers-orchestrator`, so the plugin must be
reinstalled — an in-place update cannot cross the rename.

- **Why the rename:** the old name described the fork's first change
  (token efficiency). The fork's main feature today is the autonomous
  orchestration pipeline (`orchestrating-development`, batched
  `subagent-driven-development`, `multi-code-review`). The name now matches.
- **Claude Code migration:** `/plugin uninstall superpowers-optimized`,
  remove the old marketplace entry, then
  `/plugin marketplace add brunob54/superpowers-orchestrator` and
  `/plugin install superpowers-orchestrator@superpowers-orchestrator`.
  If `~/.claude/settings.json` has an `extraKnownMarketplaces` entry for
  the old name, replace it — it re-seeds the marketplace list on start.
- **Codex migration:** rename the clone directory,
  `mv ~/.codex/superpowers-optimized ~/.codex/superpowers-orchestrator`
  (see `.codex/INSTALL.md`). The hook commands look for the new directory
  first and fall back to the old names.
- **OpenCode migration:** the plugin file is renamed to
  `superpowers-orchestrator.js`; remove the old
  `~/.config/opencode/plugins/superpowers-optimized.js` symlink and create
  the new one (see `.opencode/INSTALL.md`). The JS export is renamed
  `SuperpowersOptimizedPlugin` → `SuperpowersOrchestratorPlugin`.
- **GitHub repository** renamed to `brunob54/superpowers-orchestrator`;
  GitHub redirects the old URLs and git remotes.
- The skill prefix in this plugin's hints and cross-skill references is now
  `superpowers-orchestrator:`. The skill-name parser and the subagent guard
  accept both the old and the new prefix during the transition.
- Manifest `homepage`/`repository` fields and the session-start update
  check now point at `brunob54/superpowers-orchestrator` (previously the
  intermediate `REPOZY` fork, whose repo does not carry this fork's
  releases). The README lineage note keeps citing both upstreams as
  history.

## v6.15.1 — statusline bridge installer + configurable gate threshold

**Problem.** Wiring the statusline bridge by pointing settings.json at
the plugin cache path broke on every release, because that path
contains the version number. The start gate's block threshold was also
fixed at 60 percent and could not be changed.

**Change.** A new script, `tools/install-statusline-bridge.sh`, copies
the bridge to `~/.claude/statusline/` and prints the settings snippet.
The `SUPERPOWERS_PRESSURE_THRESHOLD` variable (10-90, default 60)
overrides the threshold.

**Effect.** The wiring survives plugin updates. Run the installer once,
and re-run it after each update.

- New `tools/install-statusline-bridge.sh` copies the statusline bridge to
  the version-independent `~/.claude/statusline/` and prints the
  settings.json snippet to wire it — pointing settings at the plugin cache
  path would break on every release, since that path embeds the version.
  Detects an existing `statusLine` and prints the delegate-mode variant
  instead, so a configured HUD keeps rendering. Re-run after plugin
  updates to refresh the installed copy.
- `SUPERPOWERS_PRESSURE_THRESHOLD` env var (a percentage, valid 10–90,
  default 60) overrides the start gate's block threshold on both the
  statusline-cache and transcript paths; the gate's STOP message reports
  the active value. Set it in settings.json's `env` block so it survives
  plugin updates. Invalid or out-of-range values fall back to 60.

## v6.15.0 — batched mode: fixed task cap replaces the measured batch boundary

**Problem.** Batched mode ended each batch using a context-pressure
measurement whose hardcoded 200K window overstated pressure about five
times on 1M-context models. Batches therefore ended near 13 percent of
real occupancy.

**Change.** A batch now ends at a fixed task cap: the count the user
gives, otherwise 3. An opt-in statusline bridge caches the true window
size, so the start gate reports the real number.

**Effect.** Batches run to their intended length. The 60 percent start
gate is unchanged. The bridge is optional and wired in settings.json.

- **subagent-driven-development** Batched Autonomous Mode now ends batches
  at a fixed task cap — the user's explicit count, otherwise 3 — instead of
  the in-batch 60% context-pressure measurement. Batches are expected to
  start in fresh sessions (the writing-plans handoff and resume flow both
  route through `/clear`), which made the measurement redundant; its
  hardcoded 200K window also overstated pressure ~5× on 1M-context models,
  ending batches at ~13% real occupancy.
- The 60% **start gate** on prompt submission is unchanged — it still
  catches implementation started mid-session with arbitrary existing
  context. The `--pressure` CLI remains as a manual inspection tool.
- orchestrating-development's cap-sizing note updated to match; the
  batched-mode behavioral test asserts the cap boundary instead of the
  pressure boundary; README and FORK-IMPROVEMENTS updated.
- **Statusline bridge (opt-in)** makes the start gate model-window-aware:
  new `hooks/statusline-context-cache.js` tees Claude Code's statusline
  `context_window` payload (which carries the TRUE window size — 200K, 1M,
  or larger) into `~/.claude/hooks-logs/context-window.cache.json`, and
  `getContextPressure()` prefers that cache when its session id matches
  the asking session (30-min staleness cutoff), falling back to transcript
  parsing against the 200K default otherwise. The gate's block message now
  reports the real window. Wire it in settings.json:
  `"statusLine": {"type": "command", "command": "node <plugin-cache-root>/hooks/statusline-context-cache.js"}`.
  Already have a statusline? Append `-- <your command>` and the bridge
  caches, then relays your renderer's output unchanged (falling back to
  its own line if the renderer fails).
  Subagents are unaffected — the statusline is main-session scoped, so the
  session-id match keeps the cache from ever misinforming them.

## v6.14.0 — orchestrating-development: autonomous spec→merge-gate pipeline

**Problem.** Turning an approved spec into reviewed code required the
user to start each stage by hand: plan writing, plan reviews,
implementation batches, then code reviews.

**Change.** A new skill, `orchestrating-development`, runs that whole
sequence from the spec: plan writing, N plan-review rounds, batched
implementation with a fresh controller subagent per batch, and N
code-review rounds. It stops only on major errors and ends before
merge or pull request.

**Effect.** One interactive Phase 0, then an autonomous run with a
committed log, plus resume and abandon procedures. Existing manual
workflows are unchanged.

- New skill **orchestrating-development**: from an approved spec, runs
  plan writing, N plan-review rounds, batched implementation (fresh
  controller subagent per ≤cap tasks, nested implementer/reviewer
  workers), and N code-review rounds fully autonomously — stopping only
  on major errors, ending before merge/PR. One interactive Phase 0
  (review counts, batch cap, branch-point + permission confirmations);
  committed orchestration log `docs/plans/…-orchestration-log.md`;
  resume and abandon procedures.
- `hooks/subagent-guard.js`: new `<!-- orchestration report -->` exempt
  marker for controller returns (free-text BLOCKED reasons may name
  skills); header now records that controller nested dispatch is
  sanctioned. Unit-tested in `tests/codex/test-subagent-guard.js`.
- `hooks/skill-rules.json`: routing entry for orchestrate / resume
  orchestration / abandon orchestration phrasings, rank-tested in
  `tests/codex/test-skill-activator.js`.
- `brainstorming` spec-review gate message now offers orchestration as
  an alternative to the manual writing-plans handoff. Existing manual
  workflows are unchanged.

## v6.13.0 — plan handoff starts a fresh session; batch phrasing routes correctly

**Problem.** Plan execution continued inside the planning session, so
planning context spent the batch budget before Task 1. A leftover
`state.md` could resume the wrong plan. The advertised phrase "execute
the plan in batches" routed to the wrong skill, and the trigger test
used `.some()`, so it never failed.

**Change.** `writing-plans` recommends `/clear` and seeds `state.md`
for the new plan. Batched mode checks `state.md` against the prompt and
ignores a stale one. Both routing patterns are fixed.

**Effect.** Execution starts clean and reaches the intended skill.
Nothing to migrate.

- `writing-plans` now recommends starting execution in a **fresh session**
  (`/clear`) rather than continuing in the planning session. Planning
  context — brainstorming, the plan itself, the multi-doc-review rounds —
  is dead weight for execution and spends the Batched Autonomous Mode
  context budget (60% pressure boundary) before Task 1 begins. The Ready
  Message now carries a paste-prompt table for batched / interactive
  subagent-driven / inline execution.
- `writing-plans` gained a **Seed `state.md`** step before the ready
  message: a full rewrite of the plan-execution sections pointing at the
  new plan. This is what makes the fresh session safe — without it, a
  `state.md` left over from a previous plan makes the next session resume
  the wrong plan.
- `subagent-driven-development` Batch Loop step 1 now cross-checks
  `state.md` against the prompt: if it names a different plan, or its plan
  file no longer exists, it is stale — ignored, and overwritten at batch
  end. Previously any `state.md` recording "a plan in progress" triggered
  the Resume Procedure, which then read *its* recorded plan path.
- **Fix (routing):** SDD's own advertised trigger "execute the plan in
  batches" routed to `executing-plans`, not `subagent-driven-development`
  — matches sort by priority before score, and `executing-plans` is
  `high` where SDD is `medium`. `executing-plans`' plan pattern now
  carries a distance-bounded negative lookahead
  (`(?![\s\S]{0,80}?\bin\s+batch)`), so batch phrasing drops it below the
  confidence threshold entirely instead of merely outranking it.
- **Fix (routing):** SDD's batch pattern required `plan` and `in batches`
  to be *adjacent*, so the phrasing users actually type — `execute the
  plan at docs/plans/X.md in batched autonomous mode` — matched SDD not at
  all. It now tolerates up to 80 characters between them
  (`plan\b[\s\S]{0,80}?\bin\s+batch`), which fits a plan path but excludes
  a distant unrelated mention of batching.
- The trigger test that should have caught both used `.some()` — asserting
  the skill was *present* among matches, not that it ranked first — so it
  stayed green throughout. `tests/codex/test-skill-activator.js` gains a
  `topSkill()` helper and 11 rank-asserting cases covering the batch
  phrasings, the writing-plans paste prompts, and the plain
  `executing-plans` phrasings that must not regress.

## v6.12.0 — SDD workspace is plan-scoped

**Problem.** A leftover `progress.md` from a finished plan read like a
completed record of the current plan, so the controller (the subagent
that executes the plan) could skip all work.

**Change.** `sdd-workspace` now takes the plan path and records it in
`.superpowers/sdd/plan.ref`; a workspace belonging to another plan, or
one without `plan.ref`, is archived first.

**Effect.** Each plan gets its own ledger. The first scoped run
archives any pre-6.12 workspace once; carried Minor findings then sit
in `archive/unknown-*/progress.md` — read them during final-review
triage.

- `scripts/sdd-workspace` now takes the plan path (`sdd-workspace PLAN_FILE`)
  and records it in `.superpowers/sdd/plan.ref`. A workspace belonging to a
  different plan — or a pre-6.12 workspace with no `plan.ref` — is archived
  to `.superpowers/sdd/archive/<slug>/` (moved, never deleted) before the
  new plan starts. Fixes the stale-ledger hazard where a leftover
  `progress.md` from a finished plan read exactly like a completed record
  of the current plan and could make the controller skip all work.
- Out-of-repo plans are supported: their identity is the absolute physical
  path (no error, no false mismatch).
- Arg-less calls (internal, from `task-brief`/`review-package`) are
  unchanged on stdout; they now print a stderr scoping line (or a legacy
  warning) so version-skewed sessions can see which plan the ledger
  belongs to. Archiving also prints an `archived previous workspace to
  archive/<slug>` notice on stderr.
- SDD SKILL.md: step 1 and the Batched Autonomous Mode Resume Procedure
  now pass `PLAN_FILE`; resume counts as a skill start for scoping.
  Checkboxes + `git log` stay authoritative for position.
- Upgrade note: the first scoped run archives any pre-6.12 workspace even
  when resuming the same plan (one-time cost); carried Minor findings are
  then in `archive/unknown-*/progress.md` — consult during final-review
  triage.

## v6.11.0 — multi-review renamed to multi-doc-review

**Problem.** Two loops had confusable names: `multi-review` reviewed
spec and plan documents, `multi-code-review` reviewed a branch diff. A
secret-protection rule also blocked writes whose text merely contained
`.env`.

**Change.** The document loop becomes `multi-doc-review`
(`/multi-doc-review <doc> [N]`); the old name no longer routes.
Behavior, lenses, and the report marker are unchanged. The `cat-env`
rule now stops at redirects, newlines, and `&`.

**Effect.** Rename the command in any script or note you keep; nothing
else to migrate. A 21-case unit suite covers the secret rule.

- **Breaking (invocation name):** the `multi-review` skill is now
  `multi-doc-review`; the slash form is `/multi-doc-review <doc> [N]`.
  The old name no longer routes. The rename disambiguates it from
  `multi-code-review` (v6.10.0) — this loop reviews spec and plan
  *documents*, that one reviews a branch diff.
- Renamed: `skills/multi-review/` → `skills/multi-doc-review/`,
  `tests/claude-code/test-multi-review.sh` →
  `tests/claude-code/test-multi-doc-review.sh`,
  `tests/skill-triggering/prompts/multi-review.txt` →
  `.../multi-doc-review.txt`; roster entry in `hooks/subagent-guard.js`
  and routing entry in `hooks/skill-rules.json` updated; brainstorming and
  writing-plans gate steps repointed.
- Unchanged: behavior, lenses, log format, and the reviewer report marker
  `<!-- multi-review report -->` — the marker is a shared wire protocol
  also emitted by `multi-code-review`, so renaming it would break both.
- Fix: the `cat-env` rule in `hooks/safety/protect-secrets.js` (and the
  opencode plugin's copy) blocked *writes* whose payload merely contained
  the token `.env` — `cat >> notes.md <<'EOF' … EOF` heredocs, generated
  docs — because its argument gap `[^|;]*` spanned redirects, newlines,
  and `&&`. The gap now excludes `>`, newlines, and `&`; `<` stays
  allowed so `cat < .env` is still caught. New unit suite
  `tests/codex/test-protect-secrets.js` (21 cases) covers both directions.

## v6.10.0 — multi-code-review: N-round independent whole-branch code review

**Problem.** A branch received a single final code-review pass. One
reviewer under one lens can miss defects.

**Change.** The new `multi-code-review` skill runs up to N rounds
(default 3, cap 10). Each round uses a fresh reviewer subagent under a
rotating lens plus one fix subagent, records a sidecar audit log, and
the loop exits early after two clean rounds.

**Effect.** subagent-driven-development now ends with this loop; direct
use is `/multi-code-review [BASE] [N]`. It needs Claude Code; other
platforms keep the single-pass review. Nothing to migrate.

- New `multi-code-review` skill: runs up to N (default 3, cap 10)
  independent review rounds on a branch diff — one clean-context reviewer
  subagent per round under a rotating lens (correctness/spec alignment,
  adversarial red-team, security, test quality, each with a
  prose/instruction-file adaptation) — with one fix subagent per round for
  Critical/Important findings, fresh review packages after fixes, a
  sidecar `.superpowers/reviews/<branch>-review-log.md` audit trail, and
  early exit after two consecutive clean rounds. No fix ships unreviewed:
  exits that would ship an unreviewed fix trigger a same-lens
  verification re-review (3-cycle cap).
- subagent-driven-development's final whole-branch review is now this
  loop (session model with sonnet floor, replacing the always-opus rule);
  direct use: `/multi-code-review [BASE] [N]`. Claude Code only —
  platforms without the Agent tool keep the single-pass final review.

## v6.9.0 — multi-review: N-round independent document review

**Problem.** A spec or plan reached its approval gate after a single
review pass. One reader under one lens misses issues.

**Change.** The new `multi-review` skill runs up to N document review
rounds (default 3, cap 10), each with a fresh reviewer subagent under a
rotating lens, merges Critical and Important findings between rounds,
and exits early after two clean rounds.

**Effect.** brainstorming and writing-plans run the loop automatically
before their approval gates; direct use is `/multi-review <doc> [N]`.
Plan headers now carry a `**Spec:**` line. Nothing to migrate.

- New `multi-review` skill: runs up to N (default 3, cap 10) independent
  review rounds on a spec or plan — one clean-context reviewer subagent per
  round under a rotating lens (correctness, ambiguity, feasibility,
  adversarial) — merging Critical/Important findings between rounds, with a
  sidecar `<doc>-review-log.md` audit trail and early exit after two
  consecutive clean rounds.
- brainstorming and writing-plans invoke the loop automatically before their
  user approval gates (once per gate); direct use: `/multi-review <doc> [N]`.
- writing-plans Plan Header gains a `**Spec:**` line so plan reviews can
  locate their spec.
- subagent-guard: reviewer reports (marker `<!-- multi-review report -->`)
  are exempt from skill-leakage blocking; `multi-review` added to the roster.
- Removed orphaned `spec-document-reviewer-prompt.md` /
  `plan-document-reviewer-prompt.md` (superseded).

## v6.8.0 (2026-07-18)

**Problem.** Each task was reviewed by two subagents — one for spec
compliance, one for quality — and dispatch prompts carried pasted
handoff text. That cost extra turns and tokens.

**Change.** One reviewer now returns both verdicts, and new scripts
(`sdd-workspace`, `task-brief`, `review-package`) write briefs,
reports, and review diffs to files that dispatch prompts reference by
path. Every dispatch must name its model.

**Effect.** Upstream measured about 2x faster runs and 50-60% fewer
tokens. Nothing to migrate.

### Subagent-Driven Development: token-optimized review flow (port of upstream v6.0.0)

Ports obra/superpowers v6.0.0's measured cost rework (~2x faster, ~50-60% fewer tokens in upstream evals), adapted to this fork's Parallel Waves and Batched Autonomous Mode.

- **One reviewer per task, two verdicts.** `spec-reviewer-prompt.md` and `code-quality-reviewer-prompt.md` are replaced by a single `task-reviewer-prompt.md` returning a spec-compliance verdict and a quality verdict, plus a "⚠️ cannot verify from diff" verdict the controller resolves itself. One fix pass clears both; reviewers are read-only and immune to implementer rationales.
- **Handoffs move as files.** New scripts `sdd-workspace`, `task-brief`, and `review-package` write task briefs, implementer reports, and review diffs (commit list + stat + `-U10` diff) to `.superpowers/sdd/`. Dispatch prompts carry paths, not pasted text.
- **Fork extension: `review-package --commits SHA...`** builds a wave task's package from its own reported commits — a BASE..HEAD range would mix interleaved sibling tasks' changes. Range fallback is banned in waves.
- **Every dispatch names its model.** Templates mark `model:` REQUIRED (an omitted model silently inherits the session's most expensive one), with turn-count-beats-token-price guidance; the final whole-branch review always runs on the most capable model.
- **Controller discipline:** at most one narration line between tool calls; a durable progress ledger (`.superpowers/sdd/progress.md`) prevents re-dispatching completed tasks after compaction; pre-flight plan review; ONE fix subagent per review's findings; reviewer coaching banned.
- **writing-plans:** plans now carry a Global Constraints block, handed verbatim to every reviewer.
- New fast test suite: `tests/sdd-scripts/run-tests.sh`.

## v6.7.1 (2026-07-18)

**Problem.** The systematic-debugging routing rule in
`hooks/skill-rules.json` contained neither "debug" nor "root cause", so
a prompt such as "debug this stack trace and identify the root cause"
scored below the confidence threshold and received no skill hint.

**Change.** Both words were added to that rule.

**Effect.** Canonical debugging prompts now route to
systematic-debugging. Three new matcher tests cover the change,
including a negative case for the `--debug` build flag. Nothing to
migrate.

Debug-prompt routing fix.

### Fixes

**systematic-debugging trigger keywords** — Added "debug" and "root cause" to the systematic-debugging rule in `hooks/skill-rules.json`. Canonical debugging prompts such as "debug this stack trace and identify the root cause" scored below the routing confidence threshold because the rule contained neither word, so no skill hint was injected. Surfaced by the repo-adapter smoke checks in the Codex post-push validation checklist — these run the hook scripts directly against fixture input and need no live Codex install, which is what was done here; covered by three new matcher tests (including a `--debug`-build-flag negative).

## v6.7.0 (2026-07-07)

**Problem.** A long plan had to finish inside one session. Nothing
ended execution at a safe point or carried the position forward.

**Change.** Batched Autonomous Mode executes up to N plan tasks per
session, ends the batch when context pressure reaches 60% (measured by
the new `--pressure` CLI, with a 3-task fallback), writes a handoff
into `state.md`, and resumes after `/clear` from plan.md checkboxes and
git.

**Effect.** Say "resume the plan" to start the next batch. A
path-encoding fix restores pressure measurement for project paths
containing underscores or dots. Nothing to migrate.

Batched Autonomous Mode: resumable, context-bounded plan execution.

### New Features

**Batched Autonomous Mode (subagent-driven-development)** — Execute up to N plan tasks per session, each via a fresh subagent with full review gates, ending the batch when context pressure reaches 60% (measured live via the new `--pressure` CLI on the skill-activator hook, with a conservative 3-task fallback cap when measurement fails). Execution inside a batch is strictly sequential and fully autonomous: blockers and plan ambiguities end the batch early with a journaled question instead of a guess, superseding the interactive escalation paths. At batch end the orchestrator writes a handoff into `state.md` (100-line cap, no cumulative re-summarizing) and prints exact resume instructions; after `/clear`, "resume the plan" reconciles position from plan.md checkboxes + git (authoritative) against the state.md narrative, refuses to run past unanswered blocking questions, and starts the next batch. Plan-complete batches skip resume instructions and route to the final whole-branch review. Spec: `docs/superpowers-orchestrator/2026-07-06-sdd-batched-autonomous-mode/specs/sdd-batched-autonomous-mode-design.md`.

**`--pressure` CLI on skill-activator** — `node hooks/skill-activator.js --pressure [cwd]` reports the current session's context pressure as JSON by reading the most recently modified session JSONL, reusing the v6.6.1 pressure-gate estimation. Prints `{"error":"unmeasurable"}` when no usable session data exists.

### Changes

**subagent-driven-development triggers** — `hooks/skill-rules.json` now routes "implement the next N tasks", "execute the plan in batches", and "resume the plan/implementation" to subagent-driven-development. Trigger vocabulary was deliberately kept narrow after false-positive analysis: generic terms ("handoff", "next tasks") were excluded, and the resume pattern ignores conversational tails ("resume the plan discussion").

**Test coverage** — Unit tests for session autodiscovery, the `--pressure` CLI, and trigger matching (incl. false-positive regressions) in `test-skill-activator.js`; new integration test `tests/claude-code/test-batched-autonomous-mode.sh`; skill-triggering prompt for batched execution.

### Fixes

**`cwdToProjectDir` encoding (skill-activator)** — Project paths are now encoded by normalizing every non-alphanumeric character to a dash, matching Claude Code's real session-directory naming. Previously underscores and dots were preserved, so on any project path containing them (e.g. `.../AI_Coding/My_tools/...`) the session JSONL lookup silently missed — which disabled both the new `--pressure` CLI and the pre-existing v6.6.1 context-pressure gate for those projects. Caught by a live smoke test in the final whole-branch review; the unit tests had passed because they round-tripped paths through the same (wrong) encoder on both sides. A regression test now asserts against the hardcoded real-world encoding.

**smart-compress test harness** — Repaired 10 chronic failures (some latent for multiple releases) in `tests/smart-compress/run-tests.sh`. The bash suite invoked `bash-compress-hook.js` twice per command under a shared session id — colliding with the hook's intentional once-per-session re-run skip, whose tmpdir tracking files also persist across runs for constant session ids (the source of the "flaky" pass-on-first-run-only behavior). Tests now use a unique session id per invocation; the end-to-end git-log test asserts on the live `HEAD` subject instead of a hardcoded commit message that had scrolled out of the truncated output window. Suite is 87/87 across repeated runs; hook behavior unchanged.

## v6.6.1 (2026-05-08)

Context pressure gate, Tailwind v4 reference, plan-level security flag, stub scan, and cleaner docs paths.

### New Features

**Context pressure gate** — The skill-activator hook (and its Codex adapter) now reads the live session JSONL to estimate context window usage, and hard-blocks plan-execution prompts when the last assistant turn exceeded 60% of the 200K window. When triggered, the hook replaces all skill hints with a compact-first instruction telling the model to save state.md via context-management, run /compact, and resume from state.md. This prevents Auto Compact from firing mid-implementation and destroying file paths, variable names, and discovered facts at the worst possible moment. Pressure is computed from `input + cache_creation + cache_read` of the last assistant turn — that is the actual current context size, not a cumulative sum across turns.

**Tailwind v4 reference (`skills/frontend-design/tailwind-v4.md`)** — A dedicated companion file with v4 install commands, `@theme` config syntax, renamed class scales, and new features. Frontend-design's training data is biased toward v3, which leads to broken setups when scaffolding for current Tailwind. The skill now routes to this file before any Tailwind work on greenfield or version-unknown projects.

### Changes

**Writing-plans: security flag per task** — Every task in a plan now carries a `Security flag: none | security` line. Setting it to `security` (for tasks handling auth, credentials, input validation, permissions, crypto, or data-access boundaries) triggers a pre-implementation security review before the implementer is dispatched. Catches the class of bug where security-relevant work ships without anyone explicitly checking it.

**Writing-plans: scope-reduction scan** — Plan self-review now searches the plan for "v1", "basic", "simple", "for now", "placeholder", "initial version", and "minimal", and verifies each hit was explicitly sanctioned by the user. Catches quiet scope downgrades where the model promises less than what was asked for without flagging it.

**Writing-plans: execution auto-selection** — Replaces the open "Which approach?" question with deterministic logic: ≥60% context or ≥5 tasks → subagent-driven; heavy inter-task state sharing → inline; default → subagent. The "Ready to execute" framing and explicit "Stop here" instruction give the user a real redirect window instead of the model chaining straight into execution.

**Verification-before-completion: stub scan** — Implementation tasks now require a grep pass for `TODO`, `FIXME`, `placeholder`, and `NotImplementedError` (excluding test files) before any "done" claim. Any hit in a file the task created or modified blocks completion until the stub is removed or explicitly justified. Catches the common failure mode of declaring success while leaving stub code in production.

**Frontend-design: framework & version awareness** — Before scaffolding any CSS framework, the skill now requires inspecting `package.json` and CSS entry files to detect the existing version (or stating the chosen version explicitly on greenfield). Mixing v3 config syntax with v4 CSS directives produces broken builds; this gate prevents that class of error.

**Dependency-management trigger refinement** — Removed "version bump" from the dependency-management trigger keywords. It was overlapping with the dedicated `version-bump` skill, causing the wrong workflow to load on plain version-bump requests.

**Cleaner docs output paths** — Brainstorming specs and writing-plans plans now save to `docs/specs/` and `docs/plans/` instead of `docs/superpowers-optimized/specs/` and `docs/superpowers-optimized/plans/`. The plugin name no longer surfaces in the folder structure of every project that uses these skills. CLAUDE.md, both skill files, both reviewer prompt templates, the autoimprove fixture, and all integration tests were updated. The `stop-reminders` decision-log detection was unaffected — its regex already matched any `specs/` or `plans/` parent folder rather than the plugin-namespaced one, so existing repos with the old path continue triggering reminders correctly.

**Test coverage** — ~290 lines of new tests in `test-skill-activator.js` cover the context pressure gate: execution-trigger pattern matching, Windows/Unix `cwdToProjectDir` encoding, JSONL pressure parsing, threshold behavior, and the block message format.

## v6.6.0 (2026-04-15)

Full-stack audit: 3 new skills, smarter cross-session memory, scope gates across 6 skills, and expanded hook coverage.

### New Features

**Refactoring skill** — Enforces behavior-locking tests before any structural change and incremental verification after each move. Four phases: lock current behavior with characterization tests, define the refactoring boundary, make one structural change at a time with tests green after each, then audit for stale references. Includes guidance on writing characterization tests for side-effectful code and detecting test runners automatically.

**Performance Investigation skill** — Measure-first methodology for performance work. Requires a quantitative baseline before any optimization, profiling to identify the actual bottleneck (not the guessed one), a hypothesis with predicted improvement, and re-measurement after every change. Profiling tool recommendations are CLI-friendly so the AI can read output directly; GUI-only tools prompt the user to share results.

**Dependency Management skill** — Structured incremental updates with verification at each step. Covers the full lifecycle: audit outdated packages, assess impact from changelogs, update one dependency at a time with test/build/smoke verification, and handle security vulnerabilities as a special case. Includes lockfile merge conflict resolution, version pinning strategy, and monorepo coordination guidance.

**Weighted memory scoring** — The skill-activator hook now ranks session-log and known-issues matches using a weighted score (70% keyword density + 30% recency) instead of flat boolean matching. More relevant entries surface first.

**Per-project watermark** — The context-engine hook now creates a per-project watermark file (md5 hash of cwd) so multiple projects sharing the same machine don't overwrite each other's session-start state.

**Cross-session diff base** — When a valid watermark exists from a previous session, the context-engine uses it as the git diff base instead of HEAD~1. This means the "what changed" snapshot reflects changes since your last session, not just the last commit.

**Blast radius import filtering** — The context-engine's blast radius analysis now applies a secondary filter checking for actual import/require/from references, reducing false positives from files that happen to contain the same basename but don't actually depend on the changed file.

### Changes

**6 scope gates added to existing skills** — frontend-design checks for an existing design system before generating a new one; TDD bootstraps test infrastructure before writing the first test; finishing-branch pulls decisions from session-log into PR descriptions; using-superpowers has a soft gate for existing projects without memory files; deliberation has a loop guard preventing infinite deliberation-premise-check cycles; context-management clarifies state.md vs plan.md roles.

**Subagent guard expanded** — The action verb pattern now catches activate/trigger/execute/launch/spawn/start in addition to the original invoke/use/run/call verbs. Also detects Skill tool invocation patterns (`Skill("superpowers..."`, `skill: "brainstorming"`).

**Stop-reminders pattern coverage widened** — The isSignificantSession check now detects edits to specs/*.md, plans/*.md, and plugin.universal.yaml in addition to SKILL.md, hooks/*.js, and CLAUDE.md.

**Session-log hard cap raised** — The per-entry hard cap was raised from 1000 to 1500 characters (~375 tokens) to accommodate multi-subsystem sessions that legitimately need more space.

**Session-start awk parser fix** — The parser that extracts recent [saved] entries now correctly flushes the previous block when encountering consecutive [saved] entries. Previously, consecutive entries without non-[saved] content between them would silently drop the earlier entry.

### Fixes

**Systematic-debugging post-fix improvement** — After resolving a bug, the skill now suggests promoting permanent discoveries to project-map.md Critical Constraints, ensuring hard-won architectural knowledge persists beyond the session-log.

**3 new test suites** — Added dedicated test files for context-engine.js (16 tests), stop-reminders.js (14 tests), and subagent-guard.js (25 tests). Combined with the existing skill-activator tests (41), the plugin now has 96 unit tests covering all major hooks.

## v6.5.2 (2026-04-11)

Stop hook reliability, session isolation, and subagent plan tracking improvements.

### Fixes

**Stats-only sessions no longer trigger stop-hook blocking** — In v6.5.1, the stop hook would emit `decision: "block"` even when the only available reminder was the informational session-stats summary (e.g., "6 min, 1 skill invocation"). Users saw "Stop hook error: Session summary: ..." after every turn in light sessions. The hook now checks for actionable reminders before blocking; stats-only sessions return `{}` silently.

**Edit log is now session-aware — no cross-session contamination** — The shared `~/.claude/hooks-logs/edit-log.txt` used a 3-field format (`timestamp | tool | path`) with no session identifier. Test sessions running via `claude -p` saw edits from the interactive session, triggering false-positive TDD and decision-log reminders inside headless test runs. The log format is now 4-field (`timestamp | session_id | tool | path`) and `stop-reminders.js` filters entries by the current session id, so each session only sees its own edits.

**Plan checkboxes now enforced after subagent-driven development** — The subagent-driven-development skill previously marked tasks complete without updating the `- [ ]` checkboxes in `plan.md`. The task-complete instruction now explicitly requires changing `- [ ]` to `- [x]` in `plan.md` and syncing `state.md` if present, matching the intent of the plan-tracking system.

**State.md staleness detection added to stop hook** — The stop hook now detects when `state.md` exists and contains plan status that appears out of date relative to recent edits (modified source files with no corresponding state update). Users see a targeted reminder to update `state.md` rather than silently leaving it stale across sessions.

**Context-management resets the decision-log reminder marker** — After saving context, the skill now writes a timestamp to `~/.claude/hooks-logs/last-saved-entry.txt`. The stop hook uses this marker to suppress the "update your decision log" reminder immediately after a context-management save, preventing redundant reminders in the same turn.

## v6.5.1 (2026-04-10)

Patch release focused on Stop-hook correctness and reminder signal quality.

### Fixes

**Claude Code `Stop` hook output contract corrected** — `hooks/stop-reminders.js` previously emitted `hookSpecificOutput` with `hookEventName: "Stop"`, which Claude rejects on Stop events with JSON validation errors. The Stop reminder path now emits a schema-valid continuation payload (`decision: "block"` + `reason`) and keeps `{}` for no-op cases. A regression suite (`tests/codex/test-stop-reminders.js`) now enforces this output shape.

**Stop-hook TDD reminders now recognize `test-*.js` under `tests/`** — Both Stop reminder implementations now classify repository-style test filenames such as `tests/codex/test-stop-reminders.js` as tests, preventing false-positive “source changed without tests” reminders when test files use `test-*.js` naming instead of `*.test.js`.

## v6.5.0 (2026-04-09)

Codex parity hardening: the plugin now follows the current Codex hook contract more closely, adds reactive Bash smart-compress on Codex, and tightens install/update guidance so complete Codex installs are easier to get right.

### New Features

**Codex `PostToolUse(Bash)` smart-compress** — Codex sessions can now replace noisy Bash output after execution with a compressed summary using the same compression rules already used by the Claude-side Bash compressor. Large `find`/`ls` output and long passing test runs can be collapsed to concise summaries with explicit `[smart-compress]` and `[compressed: X->Y lines | type]` markers, reducing context waste without hiding failures.

### Changes

**Codex hook set expanded to five native hooks** — The Codex build now wires `SessionStart`, `UserPromptSubmit`, `PreToolUse(Bash)`, `PostToolUse(Bash)`, and `Stop` through dedicated Codex adapters. This keeps the Codex path aligned with the current official hook model while still acknowledging the remaining platform limits versus Claude Code.

**Codex install/update docs now define a complete install** — The Codex docs now treat skills, custom agents, and macOS/Linux lifecycle hooks as the standard install on supported platforms, include a clean reinstall fallback for stale or inconsistent local installs, and call out `codex-cli 0.118.0+` as the minimum tested version for live hook behavior.

**Compiler/reporting language is now precise about Codex parity** — Generated loss reports and the Codex-facing docs now say only what they actually prove: native compilation for hooks targeted to Codex, not full Claude parity. This removes misleading wording that could imply unsupported Claude-only hook surfaces also existed on Codex.

### Fixes

**Codex hook output/registry compatibility hardened** — The Codex-generated hook registry now uses the current top-level `hooks` shape, the plugin manifest no longer carries the stale Codex `hooks` field, and the Codex-specific adapters now emit the output shapes expected by the current Codex docs. This addresses the class of failures where Codex would silently ignore hooks or reject invalid hook output.

**Codex `Stop` and `PostToolUse(Bash)` are now validated live, not just by unit tests** — The Codex `Stop` adapter now uses the continuation-block path (`decision: "block"` + `reason`) that Codex actually surfaces at turn end, and the reactive Codex `PostToolUse(Bash)` smart-compress path has been proven live on `codex-cli 0.118.0` for compressible commands such as `find . -type f`. This closes the earlier uncertainty where the adapters looked correct locally but had not yet been confirmed against the real Codex runtime.

**Codex JSON transcript interpretation is now documented correctly** — In `codex exec --json`, the `command_execution.aggregated_output` field can still show the original raw Bash output even when the model was actually continued from the hook-provided compressed replacement. The Codex test checklist and troubleshooting guidance now treat the final model-visible response and captured hook output as the source of truth for `PostToolUse(Bash)` verification.

**Codex Bash safety checks close more real shell read paths** — The Codex Bash safety path now catches additional `.env` read patterns such as `sed` and `awk`, reducing the chance that a secret file read slips past Codex's Bash-only interception surface.

## v6.4.0 (2026-04-07)

Native Codex hooks, OpenCode safety parity, hookbridge migration, and memory system improvements.

### New Features

**Native Codex hook adapters** — Three new adapter scripts in `hooks/codex/` bring full lifecycle hook support to Codex (macOS/Linux with hooks enabled):
- `session-start-adapter.js` — injects project context (project-map, session-log, state, known-issues) at session start, matching the Claude Code session-start hook behavior
- `stop-adapter.js` — generates discipline reminders at turn end using git uncommitted changes instead of edit-log.txt (which Codex cannot write)
- `pretool-bash-adapter.js` — single dispatcher for PreToolUse(Bash): runs dangerous-command and secret-protection checks in one process (required because Codex fires multiple matching hooks concurrently)

The `codex-hooks.json` now registers all four Codex hook events: `SessionStart`, `UserPromptSubmit` (skill activator), `Stop`, and `PreToolUse(Bash)`.

**Codex agent configs** — `codex-agents/code-reviewer.toml` and `codex-agents/red-team.toml` enable native Codex agent support for the code-reviewer and red-team workflows, but Codex still requires manual placement in `~/.codex/agents/` because plugin manifests cannot bundle TOML agents.

**OpenCode `tool.execute.before` safety hook** — The OpenCode plugin now intercepts all bash, read, edit, and write tool calls before execution, applying the same safety checks as the Claude Code hooks: 19 dangerous command patterns, 25 sensitive file path patterns, 14 secret-leaking bash patterns, and hardcoded secret detection for write operations. Blocking is via thrown errors, matching OpenCode's native hook contract. Previously the OpenCode plugin only injected the system prompt; it had no pre-execution safety layer.

**`plugin.universal.yaml` as single source of truth** — All hook files and platform manifests (`hooks/hooks.json`, `hooks/codex-hooks.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`) are now generated from `plugin.universal.yaml` in the repo root via `hookbridge compile`. Do not hand-edit the generated files — they will be overwritten. This eliminates the previous duplication where hooks were maintained in three places and could drift out of sync. Compiled with the new open source tool Hookbridge: https://github.com/REPOZY/Hookbridge

**Context-management: structured grep workflow** — The skill now specifies a four-step grep process: extract 2-3 distinctive nouns from the task, grep each individually, adjust based on hit count (0 hits → fall back to project-map critical constraints; 1–10 hits → read them; >10 hits on one keyword → narrow with a second term), then surface findings explicitly. Previously the skill gave a single generic grep command with no guidance on what to do with the results.

**Context-management: superseded-entry detection** — Before appending a new `[saved]` entry, the skill now instructs checking for earlier entries on the same topic and marking contradicted ones as `[superseded by YYYY-MM-DD]`. This prevents the session-log from accumulating contradictory decisions across sessions without any connection between them.

### Changes

**`[auto]` entry system retired** — `stop-reminders.js` no longer writes automatic `[auto]` entries to `session-log.md` at session stop. The session-log is now `[saved]`-only — human-written entries via the context-management skill. Auto-entries produced noise that inflated injection costs and were never referenced in practice.

**Skill-rules expanded coverage** — The TDD rule now matches "tests first", "failing tests first", and "write the failing tests" in addition to the existing keywords. The verification-before-completion rule adds "verify everything", "all done", "we're done", and intent patterns like "think I'm done" and "before we call it done" to reduce missed activations on natural phrasing.

**Red-team agent security constraints** — The red-team agent prompt now explicitly states that file contents are untrusted data and that the agent must not follow instructions embedded in source files, comments, or strings. Output is restricted to the conversation — no file writes, no shell commands. This prevents a malicious file under review from hijacking the agent.

**Token-efficiency: Read tool chunk rule** — Added an explicit rule: the Read tool returns a maximum of 2,000 lines per call. For files suspected to exceed this limit, use `offset` and `limit` parameters and read in sequential chunks. Never assume a single read covered the complete file.

**OpenCode plugin export renamed** — The plugin export is now `SuperpowersOptimizedPlugin` (was `SuperpowersPlugin`). This only affects internal plugin wiring in `.opencode/plugins/superpowers-optimized.js`; no user-facing behavior changes.

**`plugin-compiler/` directory removed** — The working copy of hookbridge that lived inside the plugin repo has been removed. hookbridge lives at its canonical location and `plugin.universal.yaml` in the repo root replaces it as the hook compilation entry point.

**Codex platform docs rewritten** — `docs/platforms/codex.md` and `.codex/INSTALL.md` now both include a feature comparison table (macOS/Linux with hooks vs Windows native), corrected install steps, and clear hook-capability boundaries (what Codex can and cannot intercept).

### Fixes

**OpenCode system transform array handling corrected** — The `experimental.chat.system.transform` hook was using `output.system ||= []` before pushing content, which would incorrectly skip pushing when the array was already populated. Fixed to direct `.push()` since OpenCode always pre-populates the system array.

Fixed the "Stop hook error: JSON validation failed: Hook JSON output validation failed" issue: https://github.com/REPOZY/superpowers-optimized/issues/9

Fixed the minor issue found in the Security Audit posted by a user: https://github.com/REPOZY/superpowers-optimized/issues/12

## v6.3.0 (2026-04-03)

Session memory quality pass: the stop-reminders hook now tracks undocumented work phases across long sessions, enforced token budgets prevent session-log bloat from inflating injection costs, and parallel dispatch defaults are corrected in two skills.

### New Features

**Phase-aware decision-log reminders** — The stop-reminders hook previously asked "were significant files edited in the last 30 minutes?" — a window that fails in long sessions with multiple work phases (same edits stay in the window after a `[saved]` entry, while later phases can slip out entirely). It now asks "were significant files edited since the last `[saved]` entry?" The `track-edits` hook detects when a `[saved]` entry is written to `session-log.md` and records a timestamp marker; `stop-reminders` reads that marker at Stop time. Each logical work batch gets exactly one reminder at the right time, with no false positives between phases.

**Session-log token budget guard** — `stop-reminders` now measures the last 2 `[saved]` entries at every session Stop and warns when any entry exceeds the 250-token budget (~1,000 characters). These entries are injected into every future session; a bloated entry costs tokens forever. The warning identifies the specific over-budget entry and instructs what to trim.

**Strict `[saved]` entry template in context-management** — The context-management skill's `[saved]` entry template now has an explicit structure (Goal / Decisions / Rejected / Open only), a "Never include" list (test results, task checklists → `state.md`, how-it-works walkthroughs, speculative analysis → design docs, one-time confirmations), and a hard token budget. Without this enforcement, the AI defaulted to "more is safer" and wrote entries that were 5–10× over the optimal size.

**dispatching-parallel-agents skill hint added** — `skill-rules.json` now includes a rule for `dispatching-parallel-agents` — it was the only skill with no hint coverage, meaning prompts like "dispatch these tasks simultaneously" received no routing suggestion.

### Changes

**Parallel Waves is now the default in subagent-driven-development** — "Parallel Waves" was previously labeled "Optional Speed Mode". It is now the stated default for independent tasks; sequential execution is the explicit fallback for tasks with shared-file or state dependencies. The single-message dispatch requirement is now explicit in both `subagent-driven-development` and `dispatching-parallel-agents`, with a rationale: all subagents share the same cached system prompt prefix, and dispatching them in one message ensures every agent gets a cache hit on the heavy shared prefix.

**Anti-sycophancy rules added to global CLAUDE.md** — Four rules now govern position stability: don't revise a stated position under pushback without new evidence; proactively state the strongest objection to any non-trivial proposal; agreement must cite a specific reason, not just affirm; state confidence level explicitly when uncertain.

## v6.2.0 (2026-03-30)

Cross-session memory overhaul: the full memory stack is now injected automatically at session start, stop-reminders actually writes to session-log.md, and agents can no longer waste tokens as content relays.

### New Features

**Full memory stack injected at session start** — `session-log.md` (last 2 `[saved]` decisions), `state.md` (active task snapshot), `known-issues.md` (error map), and `context-snapshot.json` (changed files + recent commits) are now all injected into session context by the session-start hook — unconditionally, without requiring the AI to remember to read them. Previously only `project-map.md` was injected; the rest depended entirely on AI compliance with the entry sequence.

**Decision-log reminder in stop-reminders** — When the session modified SKILL.md files, hooks, or plugin config, the Stop hook now surfaces an explicit prompt to invoke `context-management` before ending the session. These are the sessions where the "why" matters most and is most likely to be lost.

### Changes

**Agent & External Content Rules added to token-efficiency** — Five new rules cover the behavioral characteristics of the Agent tool and WebFetch that the AI previously had to discover by failure: agent results are always compressed on return (never use agents as content relays), WebFetch returns AI summaries not raw text (use `curl -sf` for verbatim URL content), and local files should always be Read directly. These rules are always-on from session start.

**"When the User Names a Specific Skill" section added to using-superpowers** — Clarifies that phrases like "use brainstorming" or "use context management" are Skill tool invocations, not conceptual goals to achieve ad-hoc. This was the root cause of entry sequence bypass in analyzed session transcripts: the AI improvised with agents instead of calling the Skill tool.

**Mandatory first actions surfaced at injection point** — The session-start hook now prepends three concrete steps before the full using-superpowers body: activate token-efficiency, classify complexity, and invoke named skills via the Skill tool. Previously these were buried in the skill text where they competed with everything else for attention.

**Content-relay anti-pattern added to dispatching-parallel-agents** — "The task is content relay" is now an explicit entry in the "Do not use when" list, with a one-line explanation: agent results are compressed, raw content will be lost.

**using-superpowers step 4 extended** — Now requires a `[saved]` entry at the end of any session where significant decisions were made, not just sessions with ongoing incomplete work.

**`known-issues.md` added to auto-gitignore list** — `track-edits.js` now includes `known-issues.md` in the AI_ARTIFACTS list so it is automatically added to `.gitignore` on first write.

### Fixes

**stop-reminders.js never wrote to session-log.md** — The hook was documented as "auto-writes session-log.md `[auto]` entry" but only wrote to a private temp file at `~/.claude/hooks-logs/edit-log.txt`. The `[auto]` entries visible in prior session logs were written manually by the AI. Fixed: the hook now writes a proper `[auto]` entry to `session-log.md` in the project root on session stop, gated by the existing 2-minute guard to prevent duplicates.

**MANDATORY FIRST ACTIONS had invalid JSON** — The preamble added in the previous session contained literal unescaped double-quotes (`"use brainstorming"`) inside the bash string that produced the hook's JSON output. This caused `JSON.parse` failures on every session start for any platform that validated the JSON. Fixed by removing the quotes from the example text.

## v6.1.0 (2026-03-28)

Skill quality pass: two new automated review gates, richer subagent prompts, sharper stop conditions, and a fix to the project-map staleness loop.

### New Features

**Spec reviewer gate in brainstorming** — After a design is approved and saved, `brainstorming` now dispatches a spec-reviewer subagent using a calibrated prompt template (`spec-document-reviewer-prompt.md`) before handing off to `writing-plans`. The reviewer checks for placeholders, internal contradictions, ambiguous requirements, and scope creep. Critical issues block the handoff; minor issues become advisory recommendations. This catches design gaps before they propagate into the plan.

**Plan reviewer gate in writing-plans** — `writing-plans` now dispatches a plan-reviewer subagent using `plan-document-reviewer-prompt.md` after the plan is saved. The reviewer cross-checks the plan against the original spec — not just the plan in isolation — catching scope drift, vague steps, missing file paths, and incorrect TDD ordering. Both reviewer prompts include skill leakage prevention to keep subagents focused.

### Changes

`**dispatching-parallel-agents` strengthened** — Added a "Do not use when" block covering exploratory debugging, related failures, and shared-state scenarios. Added an assembled example prompt showing all required fields (scope, goal, constraints, output format, leakage prevention) wired together. Added a ❌/✅ common mistakes section. Updated the description to "2+" (more precise than "multiple") and added "sequential dependencies" as an explicit disqualifier alongside file and state conflicts.

`**executing-plans` stop conditions expanded** — The single "stop on repeated verification failures" bullet is replaced with a named list: missing dependency, plan gap preventing start, unclear/contradictory instruction, repeated verification failure. Added "never guess — ask for clarification" as an explicit directive. Added the main/master branch prohibition with a reference to the worktree step.

`**claude-md-creator` self-assesses redundancy** — The skill no longer asks the user "anything you'd cut?" It now applies the redundancy filter itself before presenting the draft: every line must pass "would the agent produce incorrect output without this?" Lines that don't survive the filter are cut before the user sees them.

**PR description required in `finishing-a-development-branch`** — Option 2 (push + open PR) now requires a structured description: what changed, why, how to verify, and notable decisions. Previously the skill just said "Create PR" with no guidance on content.

**Worktree path persistence clarified** — `using-git-worktrees` now explicitly states that the `cd` in the creation step does not persist across separate shell calls, and that all subsequent commands must use the full worktree path or `cd <path> && <command>` inline.

`**find-polluter.sh` surfaced for test pollution** — `systematic-debugging` Phase 1 now references the `find-polluter.sh` script for tests that fail only in certain orderings. Previously the script existed in the skill folder but was never mentioned in the skill itself.

### Fixes

**project-map.md staleness loop fixed** — The staleness check in `using-superpowers` entry sequence step 6 detected stale map entries and re-read changed files — but never wrote the updates back. Every session with a stale map would re-read the same files and leave the map unchanged for next time, repeating the cycle forever. The check now explicitly updates the changed Key Files entries and refreshes the git hash in the header after re-reading, breaking the loop.

**project-map.md version sync constraint was incomplete** — The constraint listed three manifest files that must stay version-synced, but omitted `.codex-plugin/plugin.json` and `VERSION` (both required per `CLAUDE.md`). A version bump following the map's constraint would silently miss two files. Updated to list all five.

**context-snapshot.json creation expectation clarified** — When `git init` runs mid-session via the fresh-project gate, `context-snapshot.json` is not created in that session (the context-engine hook already fired at session start before git existed). The confirm path in `using-superpowers` now states this explicitly and notes that the file will appear on the next session start from the project root.

## v6.0.0 (2026-03-24)

Comprehensive codebase audit and hardening. Twelve bugs, routing gaps, and safety issues found and fixed across hooks, skill routing, and the subagent guard.

### Fixes

**Gitignore corruption when section already exists** — When `track-edits.js` appended an AI artifact to an existing `# AI assistant artifacts` section in `.gitignore`, it omitted the newline prefix, causing the new entry to be concatenated onto the last line of the file if it lacked a trailing newline. The entry would be silently malformed and git would not recognize it. Fixed by applying the `prefix` variable in both branches.

**Dead export `appendAutoSessionEntry` in stop-reminders** — `stop-reminders.js` exported `appendAutoSessionEntry` in its `module.exports`, but the function was never defined anywhere in the file. Any consumer calling it would get a `TypeError`. Removed from exports.

**Cross-platform cache age check in session-start** — The update check used `date -r FILE +%s` to read a file's modification time, which behaves inconsistently on some Linux distributions. On failure the cache age defaulted to 0, causing a GitHub fetch on every session start. Replaced with `stat -c %Y` (GNU/Linux) falling back to `stat -f %m` (BSD/macOS) falling back to 0.

**Awk stderr leaked into session context** — The `session-start` hook used `2>&1` when capturing the using-superpowers skill body via awk. Any awk error (permission denied, missing file) would be injected into the AI's session context as part of the skill text. Changed to `2>/dev/null`.

`**premise-check` was unreachable via skill-activator hook** — Despite being the most important safety-net skill (validates whether work should exist before building it), `premise-check` had no entry in `skill-rules.json`. The skill-activator hook could never suggest it based on user input — it only fired if the model proactively read the Routing Guide text. Added a high-priority rule covering "design a system", "should we build this", "validate the premise", and related phrases.

`**receiving-code-review` was unreachable via skill-activator hook** — Same gap: no `skill-rules.json` entry. Phrases like "address review feedback" and "respond to review" never triggered it. Added a medium-priority rule.

`**error-recovery` missing from Routing Guide** — The skill existed and was in `skill-rules.json`, but was absent from the Routing Guide in `using-superpowers`. A model doing full-complexity routing would never find it as a destination. Added to the guide.

`**deliberation` missing from subagent-guard** — The subagent guard's violation patterns covered 20 skills but omitted `deliberation`. A subagent invoking `deliberation` by plain name (without the `superpowers-optimized:` prefix) would slip through. Added to the patterns. The guard was also refactored to use a verb-prefix pattern (`invoking/using/running + skill name`) that eliminates false positives from prose mentions of skill names.

**ReDoS vulnerability in block-dangerous-commands** — Six regex patterns used `(-.+\s+)*` which is a nested quantifier enabling catastrophic backtracking on adversarial input. Replaced with `(-\S+\s+)*` which eliminates the backtracking risk while preserving the same match semantics.

### Changes

**Routing Guide clarifies parallel execution paths** — The distinction between `dispatching-parallel-agents` (ad-hoc parallel work outside plan execution) and `subagent-driven-development` (plan execution with optional parallel waves) is now explicit in the Routing Guide. Previously the two entries looked equivalent, causing model confusion on which to pick.

**Internal skills documented in Routing Guide** — `self-consistency-reasoner` (invoked internally by `systematic-debugging` and `verification-before-completion`) and `token-efficiency` (always-on, invoked at Entry Sequence step 1) are now noted as intentional non-entries in the Routing Guide. Previously their absence was undocumented, which could be misread as orphaned skills.

**CMD arg limit documented in run-hook.cmd** — A comment now notes the 8-argument limit of the `%2-%9` forwarding pattern in the Windows batch wrapper, flagging it for future callers who need more.

## v5.8.0 (2026-03-24)

"Map this project" now correctly triggers the context-management skill and writes `project-map.md` to the project root.

### Fixes

**"map this project" routing was broken** — Saying "map this project" produced a chat response instead of a `project-map.md` file. Two bugs caused this: (1) `skill-rules.json` had no rule mapping map intent to `context-management`, so the skill was never suggested; (2) even when invoked manually, `context-management` defaulted to writing `state.md` because the project map procedure was buried below the state-saving procedure with no routing gate. Fixed by adding a dedicated high-priority rule in `skill-rules.json` covering "map this project", "map the project", "generate/create/update project map", updating the `context-management` skill description to include these trigger phrases, and adding an explicit routing table at the top of the skill that branches to the correct procedure before any other content is read.

## v5.7.0 (2026-03-23)

Context engine, pre-verified blast radius for code review and debugging, and a fix for false-positive update notices.

### New Features

**Context engine** — A new `context-engine.js` SessionStart hook runs automatically on every session start and writes `context-snapshot.json` to the project root. It captures the files changed in the last commit, a change summary, the last 5 commits, and blast radius (which other tracked files reference each changed file, computed via `git grep`). Zero dependencies — uses Node.js built-ins and git. Fails silently if git is unavailable. Automatically adds `context-snapshot.json` to `.gitignore` on first write.

**Code review uses context snapshot** — `requesting-code-review` now checks `context-snapshot.json` before dispatching the agent. If the snapshot is fresh (git hash matches HEAD), the changed files and blast radius are used to scope the review immediately — no exploration needed. If stale, changed files are used as a starting point. If absent, the skill falls back to `git diff` directly.

**Systematic debugging uses context snapshot** — Phase 1 of `systematic-debugging` now reads `context-snapshot.json` first when investigating what changed recently. The `changed_files` and `recent_commits` fields answer the question immediately, without running `git log` and `git diff` manually.

### Fixes

**Update check false positive** — The session-start hook was reading the installed version from its own directory, which could be an older cached copy after a Claude Code plugin update. The hook would then report a newer version as available even though the update was already applied. Fixed by reading the installed version from `~/.claude/plugins/installed_plugins.json` (the authoritative source) first, with a fallback to the hook's own `plugin.json`.

## v5.6.0 (2026-03-21)

Session memory enhanced, auto-gitignore for AI artifacts, and routing guide completeness. `project-map.md` is now injected directly into every session start by the hook — no instruction-following required. AI workspace files are automatically added to `.gitignore` the moment they're created. The routing guide now covers every user-invocable skill in the plugin.

### New Features

**project-map.md auto-injected at session start** — The session-start hook now reads `project-map.md` from the working directory and injects its content directly into context, unconditionally, before the first turn. Previously, reading the project map relied on Claude following the entry sequence — if the task was classified as micro, or if the first message was conversational, the file might never be read. Now it's always in context. For maps ≤200 lines the full content is injected; for larger maps only the `## Critical Constraints` and `## Hot Files` sections are injected, with a note pointing to the full file.

**Auto-gitignore for AI workspace artifacts** — When Claude creates `project-map.md`, `session-log.md`, or `state.md` in a project, they are now automatically added to `.gitignore` under a `# AI assistant artifacts` section header. These are tooling artifacts — generated by the AI, not part of the project — and should never appear in `git status` as untracked files. The gitignore check runs in the `PostToolUse` hook for files Claude writes directly, and in the stop hook for `session-log.md` entries written by the hook itself. Idempotent: if the entry already exists, nothing is changed.

### Changes

**Routing guide now covers all user-invocable skills** — `premise-check` and `using-git-worktrees` were missing from the routing guide in `using-superpowers` and had no coverage anywhere in the entry sequence. Both are now listed: `premise-check` at the top of the guide (run before brainstorming or planning when it's unclear whether work should exist at all), and `using-git-worktrees` before the implementation entries (run before implementation when the work needs branch isolation).

`**claude-md-creator` added to routing guide with explicit bypass protection** — CLAUDE.md creation was being classified as lightweight and implemented directly, bypassing the `claude-md-creator` skill that exists specifically for this task. The routing guide now includes an explicit entry for CLAUDE.md / AGENTS.md creation pointing to `claude-md-creator`, with a note that it applies at any complexity level. The lightweight action text now includes an exception: if a dedicated implementation skill exists for the task, invoke it — lightweight only skips workflow overhead, not implementation skills.

## v5.5.0 (2026-03-20)

Reasoning gap prevention and fresh project memory setup. The AI now catches its own design and implementation gaps earlier, classifies tasks more accurately, and proactively offers to set up the memory stack before building anything in a new directory.

### New Features

**Fresh project gate** — When you type "build", "create", "implement", or any creation-intent prompt in a directory with no `project-map.md`, the AI now pauses before starting and explains exactly what it will lose without the memory stack (re-exploring structure, re-reading known files, re-proposing rejected approaches, losing the "why" behind decisions). It offers to run `git init` and generate `project-map.md` in ~30 seconds before proceeding, or start immediately if you prefer. Previously this offer only appeared if git was absent — now it fires whenever no `project-map.md` exists, regardless of git status, so users who already have git initialized are no longer silently skipped.

**Failure-mode check in brainstorming** — Before any design can be approved, the AI must now state the top 2–3 ways the chosen approach could fail or not cover all cases. This is adversarial reasoning — actively trying to break the design — not a list of known assumptions. Critical failure modes (the design fails for a significant user scenario) must be fixed before proceeding; minor ones are documented as non-goals. This catches unknown assumptions at the design stage, where fixing them costs nothing, rather than discovering them after implementation.

**Assumption externalization in writing-plans** — The plan header now requires an `Assumptions` field listing what the plan rests on and what each assumption excludes ("Assumes X — will NOT work if Y"). Every task involving conditional logic now requires a `Does NOT cover` field stating which scenarios the condition excludes. If an excluded scenario should be covered, the task is revised before implementation begins. This catches known assumptions at the planning stage, complementing the adversarial failure-mode check in brainstorming.

**Condition coverage check in verification** — `verification-before-completion` now requires, as step 5 of its gate, that any change involving a condition or gate explicitly state what it does NOT cover before the task is marked done. If the answer reveals a gap that should be covered, it must be fixed before proceeding. This is the final catch in a three-stage adversarial pipeline: design → planning → completion.

### Changes

**Classification hard overrides** — The complexity classification in `using-superpowers` now has a hard override section that is evaluated before the lightweight criteria. If any of four conditions are true (adds/modifies/removes a condition or trigger, affects user experience, modifies a shared dependency, introduces a new outcome), the task is immediately classified as full regardless of file count. This prevents lightweight anchoring on file count for tasks that have significant behavioral impact.

**Lightweight articulation requirement** — Before classifying any task as lightweight, the AI must now explicitly state in one sentence why each of the four lightweight criteria is satisfied. If any criterion cannot be clearly articulated, the task is classified as full. Combined with the hard overrides, this closes the gap where tasks with new conditional logic were being mis-classified as lightweight, skipping brainstorming and the design-stage failure-mode check.

## v5.4.0 (2026-03-20)

Session memory, deliberation skill, social accountability, and ASI-guided auto-fix. The AI no longer starts every session amnesiac, makes better architectural decisions before committing to a direction, and its review agents now prioritize and fix findings more accurately.

### New Features

**Deliberation skill** — New `skills/deliberation/SKILL.md` for complex architectural or technology decisions where the options aren't yet well-defined or the problem may need reframing before brainstorming begins. The skill convenes 3–5 named stakeholder perspectives (Security Engineer, Developer Experience Advocate, Ops/Infrastructure Engineer, Maintainability Advocate, Performance Engineer, User/Product) — each speaks once without debate or rebuttal. The output surfaces where perspectives converge (load-bearing constraints that any solution must satisfy), where they genuinely disagree (live tensions that cannot be papered over), and optionally reframes the original question when deliberation reveals it was mis-stated. No forced conclusion — deliberation produces clarity about the decision space, not a recommendation. Routed by `using-superpowers` before brainstorming when the decision is unclear. Triggered by: "trade-off", "should we use", "evaluate these options", "architecture decision", "not sure which approach".

**Session memory stack** — The plugin now builds a four-file memory stack at your project root that eliminates re-discovery overhead across sessions. `session-log.md` accumulates a history of decisions, rejected approaches, and key facts. The stop hook auto-appends a minimal `[auto]` entry at every session end (skills used, files modified) at zero cost — no setup, no action required. When you explicitly invoke `context-management`, it writes a richer `[saved]` entry capturing goals, rationale, and what was tried and abandoned. At session start, the AI greps this log for keywords from the current task and surfaces relevant history before doing any work.

**Project map** — New `project-map.md` is the semantic memory layer: a persistent, AI-written map of the project's directory structure, key file purposes, and critical non-obvious constraints (e.g. "single quotes break Linux CI in hooks.json"). Generate it once with "map this project". After that, the AI reads it at every session start instead of re-globbing and re-reading files it already understands. Staleness is automatic: the AI checks the git hash in the map header against the current commit, then uses `git diff --name-only` to identify exactly which files changed and re-reads only those. Works on non-git projects too via file timestamp comparison. If no git repository is detected, the AI offers to run `git init` during map generation (creates a `.git` folder, touches no user files) with a clear explanation of what happens if you decline.

**Skill quality gate** — The `skill-creator` skill now includes a five-dimension quality check (Safety, Completeness, Executability, Maintainability, Cost-awareness) that must pass before moving to test cases. A skill that fails Executability or Completeness is redesigned, not just tested. This catches gaps and ambiguities at the design stage rather than discovering them during evaluation.

**Model selection guidance for subagents** — `subagent-driven-development` now specifies which model to use for each Agent tool call: Haiku for file reads, log scanning, and patch verification (output is data, not decisions); Sonnet for all implementation tasks (default); Opus for architecture analysis, complex spec review, and multi-system debugging. Reduces cost on lightweight review work and improves accuracy on reasoning-heavy tasks.

### Changes

**Social accountability in agent prompts** — The `code-reviewer`, `red-team`, and `implementer` agent prompts now include social accountability framing informed by 2389.ai research. Each agent is explicitly told that downstream work depends on the accuracy of its output: a false positive in the red team report triggers a full wasted fix cycle; a missed bug in code review ships to production; an implementer task that fails review cycles back and blocks the whole pipeline. The framing is factual, not motivational — it describes what actually happens, which is what improved accuracy in the research.

**ASI-guided iterative auto-fix pipeline** — The auto-fix pipeline in `requesting-code-review` was rewritten from a sequential batch (fix all Critical/High in order, run full suite once at end) to an ASI-guided iterative loop. The red team now marks one finding as the ASI (Actionable Side Information — the single finding that poses the greatest real-world risk if unaddressed). The pipeline starts there: write failing test → fix code → re-read only the files touched by the fix → check whether any other reported findings are now resolved or changed in severity → re-identify the new ASI → repeat until no Critical or High findings remain → run full suite once. This prevents fix collisions when multiple findings touch shared code, and catches side effects immediately rather than discovering them in a single final regression run.

**Proactive compaction breakpoints** — `token-efficiency` now includes explicit guidance to break context at logical seams before implementation begins (after research/exploration, after abandoning a failed approach) rather than waiting for auto-compaction at 95% context fill. Auto-compaction at 95% destroys the most recently gathered context — exactly the variable names, file paths, and evidence that implementation depends on. A proactive break at 50% preserves all of it.

**context-management expanded** — Now manages all four memory files (`project-map.md`, `session-log.md`, `state.md`, `known-issues.md`) as a unified stack with documented procedures for each. Session-start procedure updated to grep `session-log.md` for task keywords before diving in. Explicit cross-reference to `episodic-memory@superpowers-marketplace` for semantic cross-project recall that falls outside the scope of per-project grep-based memory.

**Entry sequence updated** — `using-superpowers` entry sequence now includes `project-map.md` as step 5: read the map if it exists, check staleness, re-read only changed files. This makes orientation at session start deterministic and zero-waste.

**Session-start hook** — Now detects when no git repository is present and injects a quiet background note into session context. The AI acts on this only when `project-map.md` is relevant — it does not announce it verbally on every session start.

## v5.3.0 (2026-03-17)

Frontend design intelligence and documentation improvements. The frontend skill was completely rewritten from a 62-line checklist into a comprehensive design reasoning system, and several docs were updated to reflect the current state of the plugin.

### New Features

**frontend-design skill (complete rewrite)** — The former `frontend-craftsmanship` skill has been renamed to `frontend-design` and rewritten from scratch. It now includes a 4-step design system generation framework that forces deliberate style, color, typography, and effects decisions before writing code. Adds a 25-style reference catalog (Minimalism through Cyberpunk), a 30-category industry design reference table mapping product types to recommended design directions, 8 common page structure patterns (dashboard, landing page, admin panel, etc.), 5-state UI state management (loading, error, empty, success, partial), frontend-backend integration patterns (API loading, optimistic updates, error boundaries, auth flows), dark mode implementation guidance, micro-copy and UX writing standards, and 10 priority quality standard categories covering accessibility, touch targets, performance, animation, forms, navigation, and charts. 353 lines, single file, zero dependencies.

**Red team pipeline documentation** — New `docs/architecture/red-team-pipeline.md` explains the end-to-end flow from code review through red team dispatch to auto-fix pipeline, including when each component fires, what the red team produces, how auto-fix processes findings, and merge blocking rules.

**Frontend design documentation** — New `docs/architecture/frontend-design.md` explains the skill's 7 capabilities with examples, what users can expect when prompting for frontend work, and how activation integrates with other Superpowers skills.

### Changes

**Testing documentation updated** — `docs/testing.md` (now `docs/architecture/testing-structure.md`) was rewritten to reflect the actual 5-directory test structure: claude-code, skill-triggering, explicit-skill-requests, subagent-driven-dev, and opencode. Added the subagent hook scope test, fixed stale plugin name references, and added a quick reference section with copy-paste commands for every test suite.

**AGENTS.minimal.md updated** — Added missing `premise-check` skill reference.

**frontend-craftsmanship → frontend-design rename** — All references across 9 files updated: SKILL.md frontmatter, skill-rules.json, subagent-guard.js, README.md, AGENTS.minimal.md, using-superpowers routing, executing-plans, subagent-driven-development, and RELEASE-NOTES.md.

## v5.2.0 (2026-03-15)

Adversarial red team analysis and auto-fix pipeline. Code review now goes beyond checklists — it actively tries to break your code, then fixes what it finds.

### New Features

**Red team agent** — New `agents/red-team.md` adversarially attacks completed implementations to find concrete failure scenarios that checklist-based review misses. Focuses on 7 attack categories: logic bugs, adversarial inputs, state corruption, concurrency & timing, resource exhaustion, error cascading, and assumption violations. Each finding includes a specific trigger, root cause with file:line references, and a test case skeleton. Explicitly does NOT overlap with the OWASP/CWE security review — its domain is adversarial logic analysis.

**Auto-fix pipeline** — When the red team report contains Critical or High findings, `requesting-code-review` now runs an auto-fix pipeline: for each finding, the test case skeleton is fleshed into a real test (must fail — proving the scenario is real), then the code is fixed to pass the test, then the full suite is verified for regressions. False positives are caught naturally (test passes → finding was invalid → skip). Medium findings are tracked for later, not auto-fixed.

**Red team integration in code review** — `requesting-code-review` now dispatches the red team agent in parallel with the code reviewer when changes touch complex logic, concurrency, state management, data transformation pipelines, retry/recovery logic, or performance-critical paths.

**Hardcoded secret content scanning** — `protect-secrets.js` now scans the content of Edit and Write operations for hardcoded secrets before the write happens. Detects 14 patterns: AWS access/secret keys, GitHub tokens, OpenAI keys, Anthropic keys, Stripe keys, private key PEM blocks, generic API key assignments, database connection strings with passwords, Slack tokens, SendGrid keys, Twilio keys, and Supabase keys. On detection, the write is blocked and the agent is instructed to move the value to an environment variable (e.g. `.env` file) and reference it via `process.env.VARIABLE_NAME` instead. Files where secrets are expected (`.env`, documentation) are allowlisted.

### Changes

**Subagent guard updated** — `hooks/subagent-guard.js` now includes violation patterns for `premise-check` and `red-team` skills, preventing subagents from invoking these skills via filesystem discovery.

---

## v5.1.0 (2026-03-14)

Upstream sync and hardening release. Adopts the most impactful changes from obra/superpowers, adds new safety mechanisms, and removes deprecated features.

### New Features

**Subagent context isolation** — All delegation skills (`subagent-driven-development`, `dispatching-parallel-agents`, `executing-plans`) now explicitly prohibit forwarding parent session context or history to subagents. Each subagent prompt is constructed from scratch with only task-scoped information. This prevents context pollution where subagents inherit the parent's reasoning chains and behave incorrectly (e.g., a reviewer acting as a lead developer).

**Subagent skill leakage prevention** — All subagent prompt templates now include an explicit instruction preventing subagents from discovering and invoking superpowers-optimized skills via filesystem access. Without this, a focused implementer subagent could discover workflow skills like `brainstorming` or `executing-plans` and derail into orchestration mode instead of doing its assigned task.

**Instruction priority hierarchy** — `using-superpowers` now declares an explicit priority order: (1) explicit user instructions, (2) project-level CLAUDE.md/AGENTS.md, (3) Superpowers skill instructions. Skills are defaults, not mandates — if a user explicitly overrides a skill's behavior, the agent follows the user.

**Plan review gate** — `writing-plans` now dispatches a plan-reviewer subagent after saving a plan, before offering execution options. The reviewer checks for vague steps, missing file paths, hidden dependencies, incorrect TDD ordering, and scope gaps against the approved design. Bad plans are revised before execution begins.

**Project scope decomposition** — `brainstorming` now assesses whether a project is too large for a single spec (4+ independent subsystems or 20+ tasks) and decomposes into sub-projects with separate specs. This prevents the common failure mode of trying to design an entire system in one monolithic document.

**Architecture guidance for existing codebases** — `brainstorming` now includes explicit guidance to study existing patterns before proposing new ones, match project conventions, and design for isolation (minimizing blast radius per change).

**Premise check skill** — New `premise-check` skill validates whether proposed work should exist before investing in it. Forces three questions (does the problem exist? is the solution proportional? what's the cost of not building?) and triggers reassessment when new evidence weakens the original motivation for in-progress work. Prevents over-engineering by catching unnecessary complexity before it's built.

### Changes

**Recommended subagent-driven-development** — `writing-plans` now labels `subagent-driven-development` as the recommended execution path (parallel with per-task review gates) and `executing-plans` as the alternative (sequential, simpler). User choice is preserved.

**Slash commands removed** — The `commands/` directory (`/brainstorm`, `/execute-plan`, `/write-plan`) has been removed. Skills are now the primary mechanism in Claude Code. Natural language routing via `skill-activator.js` and the `using-superpowers` router handle all workflow selection automatically — no manual command invocation needed.

**Gemini CLI support** — Added Gemini CLI installation instructions to README.

**Compatibility warning** — README now includes a prominent note about potential interference from other plugins or custom skills/agents that overlap with this plugin's domains.

### Fixes

**Linux hook variable expansion** — All 7 hook entries in `hooks.json` changed from single quotes to escaped double quotes around `${CLAUDE_PLUGIN_ROOT}`. Single quotes prevented shell variable expansion on Linux, causing "No such file or directory" errors (upstream issue #577).

---

## v5.0.0 (2026-03-13)

Major overhaul focused on signal-to-noise ratio: every skill must earn its place by changing behavior Claude wouldn't follow on its own. Role-play skills merged into the skills that use them, router redesigned for zero-cost micro-tasks, and two new killer features added (error recovery intelligence and progress visibility).

### Breaking Changes

**6 skills removed (merged or deleted)**

The following skills no longer exist as standalone skills. Their useful parts have been absorbed into the skills that invoke them:

- `senior-engineer` — Engineering rigor sections merged into `brainstorming` (design-phase) and `executing-plans` (implementation-phase). The role-play prompt ("you are an expert with 30 years experience") was removed as it didn't change behavior — specific rules do.
- `testing-specialist` — Advanced test strategy (integration, E2E, property-based, performance, flaky test diagnosis, coverage strategy) merged into `test-driven-development` as a new "Advanced Test Strategy" section.
- `security-reviewer` — Full OWASP/CWE security checklist, severity enforcement, and auto-trigger conditions merged into `requesting-code-review` as a built-in "Security Review" section. The `protect-secrets.js` hook continues to handle automated enforcement.
- `adaptive-workflow-selector` — 3-tier complexity classification (micro/lightweight/full) folded directly into `using-superpowers` as an inline "Complexity Classification" section. No longer requires a separate skill invocation.
- `prompt-optimizer` — Removed. Rarely triggered, marginal value. Brainstorming already handles ambiguous requests through clarifying questions.
- `writing-skills` — Removed. Developer-only meta-skill, not user-facing value. Contributing guide updated in README.

**Skill count: 24 → 19** (5 deleted, 1 new)

`**adaptive-workflow-selector` no longer exists as a standalone skill.** If your CLAUDE.md or custom workflows reference it, update them to use `using-superpowers` which now handles complexity classification inline.

### Added

**error-recovery — Project-specific error-to-solution intelligence**

New skill that maintains `known-issues.md` at the project root — a mapping of recurring errors to their proven solutions. Designed for errors that waste time when rediscovered each session: environment setup, missing services, platform-specific issues, configuration problems.

- Consulted automatically by `systematic-debugging` in a new Phase 0 (before investigation begins)
- Read by `using-superpowers` during the entry sequence when the file exists
- Updated after resolving bugs that meet recurrence criteria (environment-dependent, config, platform-specific)
- Entries kept concise: error pattern, cause, fix command, context
- File capped at 50 entries with pruning guidance

**track-session-stats.js — Progress visibility hook**

New PostToolUse hook (triggered on Skill tool calls) that tracks skill invocations to `session-stats.json`. Provides:

- Session duration
- Total skill invocations with per-skill breakdown
- Auto-expires after 2 hours (new session)
- Integrated into `stop-reminders.js` which now surfaces a session summary line

**Micro-task detection in skill-activator.js**

The UserPromptSubmit hook now detects micro-tasks (typo fixes, variable renames, import additions, etc.) and outputs `{}` — zero routing overhead. Patterns include:

- "fix the typo on line 42" → skipped
- "rename foo to bar" → skipped
- "add missing import" → skipped
- "build me a new auth system" → routed normally

**Confidence threshold in skill-activator.js**

Skill matching now requires a minimum score of 2 (was 1). Single-keyword matches that produced false positives are filtered out:

- "review" alone → no suggestion (was: suggested code review)
- "review my code before merge" → correctly routes to requesting-code-review

**3-tier complexity classification in using-superpowers**

Replaces the separate `adaptive-workflow-selector` skill with an inline classification:

- **Micro**: typo fix, single rename, 1-line config change → skip everything, just do it
- **Lightweight**: ~2 files, no new behavior/architecture → implement directly, only verification-before-completion at the end
- **Full**: anything else → complete pipeline (brainstorming → planning → execution → review → verify)

**Lightweight fast path**

Lightweight tasks now skip brainstorming, planning, worktrees, and parallel dispatch. Only gate: `verification-before-completion` when done. This eliminates the previous 3-skill-invocation overhead for small changes.

### Changed

**brainstorming: Added Engineering Rigor section**

Absorbed from senior-engineer: requirements verification, edge case identification, explicit trade-off evaluation, SOLID principles, architectural risk flagging. Removed prompt-optimizer reference.

**executing-plans: Added Engineering Rigor for Complex Tasks section**

Absorbed from senior-engineer: approach validation against requirements, edge case identification, simpler alternative consideration, hidden coupling prevention. Removed senior-engineer reference.

**test-driven-development: Added Advanced Test Strategy section**

Absorbed from testing-specialist: integration tests, E2E tests, property-based tests, performance tests, flaky test diagnosis, coverage strategy. Removed testing-specialist reference.

**requesting-code-review: Added Security Review (Built-In) section**

Absorbed from security-reviewer: OWASP Top 10/CWE scan, input validation, auth flow review, secrets handling, dependency vulnerabilities, logging hygiene. Auto-triggers when changes touch auth, data handling, APIs, secrets, crypto, or infrastructure. Critical/High findings block merge. Updated description to include security-related trigger keywords.

**receiving-code-review: Updated security finding reference**

Removed standalone security-reviewer reference. Security findings now come from the integrated security section in requesting-code-review.

**subagent-driven-development: Removed senior-engineer references**

Replaced "invoke senior-engineer subagent" with inline guidance: validate approach against requirements, consider simpler alternatives. Blocked task protocol updated similarly.

**writing-plans: Removed prompt-optimizer reference**

Replaced with direct guidance: ask clarifying questions for ambiguous features rather than invoking a separate prompt optimization step.

**systematic-debugging: Added Phase 0 (Check Known Issues)**

New first phase before investigation: check `known-issues.md` for the error message/code/test name, try documented solution first. If it works, stop — no further investigation needed. Added post-fix prompt to update known-issues.md for recurring errors.

**using-superpowers: Complete rewrite**

- Entry sequence simplified: token-efficiency → classify complexity → check state.md → check known-issues.md → follow appropriate path
- Removed adaptive-workflow-selector invocation
- Added inline complexity classification (micro/lightweight/full)
- Removed security-reviewer from routing guide (now built into requesting-code-review)
- Updated red flags section

**token-efficiency: Updated description**

Removed adaptive-workflow-selector reference. Added "exploration tracking" to description.

**skill-rules.json: Rebuilt**

- Removed 6 rules for deleted skills (adaptive-workflow-selector, senior-engineer, testing-specialist, security-reviewer, prompt-optimizer, writing-skills)
- Added error-recovery rule
- Merged security keywords into requesting-code-review rule
- Merged testing-specialist keywords into test-driven-development rule
- Total: 16 → 14 rules

**hooks.json: Added track-session-stats**

New PostToolUse hook entry for Skill matcher, running `track-session-stats.js`.

**stop-reminders.js: Added session stats summary**

Now loads `session-stats.json` and includes a session summary line (duration, skill count, breakdown) in stop-hook output alongside existing TDD and commit reminders.

**AGENTS.minimal.md: Updated to reflect new skill set**

Removed references to adaptive-workflow-selector, senior-engineer, security-reviewer, testing-specialist, prompt-optimizer. Added error-recovery and known-issues.md guidance.

**README.md: Complete rewrite**

- Added workflow diagram showing the complete hook and routing flow
- Updated feature comparison table (7 hooks, 3-tier routing, integrated security, error recovery, progress visibility)
- Updated Skills Library to 19 skills organized by category (Core Workflow, Design & Planning, Execution, Quality & Testing, Review & Integration, Intelligence)
- Listed all 7 hooks with their matchers and descriptions
- Updated contributing guide (removed writing-skills reference)
- Added "Proportional overhead" to philosophy section

## v4.6.0 (2026-03-11)

This release integrates self-consistency reasoning (Wang et al., ICLR 2023) into the two skills where single-chain reasoning failures are most expensive: root cause diagnosis and completion verification. Also includes plugin manifest fixes, marketplace metadata improvements, and README updates with research-driven optimization documentation and shields.io badges.

### Added

**self-consistency-reasoner — Multi-path reasoning technique for high-stakes inference**

New internal skill based on the Self-Consistency method (Wang et al., ICLR 2023). Generates N independent reasoning paths and takes majority vote to catch confident-but-wrong single-chain failures. Not invoked independently — embedded in the skills that need it. Key design decisions:

- Scoped to fire only during high-stakes multi-step inference where being wrong has real cost
- Path count scales to difficulty: 3 for binary verification, 5 for root cause diagnosis, 7 for complex multi-factor problems
- Low confidence (<=50% agreement) triggers a hard stop, not a best-guess — ambiguity is surfaced, not hidden
- Process is internal: users see only the aggregated result and confidence level

**systematic-debugging: Self-Consistency Gate in Phase 3**

Phase 3 (Hypothesize and Test) now requires multi-path reasoning before committing to a root cause hypothesis. The agent generates 3-5 independent hypotheses via different approaches (trace forward from inputs, backward from error, from recent changes, from similar past bugs), takes majority vote, and gates on confidence:

- High (80-100%): proceed to test
- Moderate (60-79%): proceed but note minority hypothesis as fallback
- Low (<=50%): hard stop — gather more evidence before choosing a direction

This directly addresses the most expensive debugging failure mode: latching onto the first plausible hypothesis and committing 3+ edits before discovering the root cause was different.

**verification-before-completion: Self-Consistency Verification**

Added multi-path verification for non-trivial completion claims. When the evidence evaluation requires multi-step inference, the agent generates 3 independent reasoning paths evaluating "does this evidence actually prove the claim?" — one checking what the evidence proves, one checking what it doesn't prove, one considering alternative explanations. Catches the failure mode where evidence is interpreted through a single (potentially wrong) lens, leading to false "done" declarations.

**README: Research-Driven Optimizations section**

Added comprehensive documentation of the three research papers that ground the fork's optimizations:

- arXiv:2602.11988 (AGENTbench) — why minimal context files outperform verbose ones
- arXiv:2602.24287 — why prior assistant responses degrade performance
- Wang et al., ICLR 2023 — why single reasoning chains fail on hard problems

Each paper section includes key findings, what was changed in the fork, and the four core principles that emerged.

**README: shields.io badges**

Added badges for GitHub stars, install command (links to Installation section), Cursor, Claude Code, Codex CLI, and MIT license.

### Fixed

**Plugin manifest: Duplicate hooks error**

Removed `"hooks": "./hooks/hooks.json"` from both `.claude-plugin/plugin.json` and `.cursor-plugin/plugin.json`. Claude Code auto-loads `hooks/hooks.json` from the standard path, so explicitly declaring it caused a "Duplicate hooks file detected" error on plugin installation.

**Plugin manifest: Invalid author.repository field**

Removed `repository` from inside the `author` object in `.claude-plugin/plugin.json`. The `author` field only supports `name` and `email` per the plugin schema. The top-level `repository` field was already correctly set.

### Improved

**Marketplace metadata**

Enhanced `.claude-plugin/marketplace.json` with `metadata.description`, plugin-level `homepage`, `repository`, `license`, `category`, and `tags` fields for better discoverability.

---

## v4.5.0 (2026-03-10)

This release adds a comprehensive hooks system with proactive skill routing, edit tracking, stop reminders, and two safety guard hooks. Also includes cross-session memory for the code-reviewer agent and README corrections.

### Added

**Hooks System — 5 new hooks for proactive workflow enforcement and safety**

The plugin now ships a full hooks pipeline registered in `hooks/hooks.json`:

- **skill-activator** (UserPromptSubmit) — Matches user prompts against 17 keyword/regex rules in `hooks/skill-rules.json` before Claude processes them. Injects up to 3 relevant skill suggestions wrapped in `<user-prompt-submit-hook>` tags, reinforcing the `using-superpowers` routing system deterministically. Returns `{}` for non-matching prompts (zero token cost).
- **track-edits** (PostToolUse, matcher: Edit|Write) — Logs every file edit to `~/.claude/hooks-logs/edit-log.txt` with ISO timestamp, tool name, and resolved file path. Auto-rotates at 500 lines with a size-based check (50KB threshold) to avoid reading the file on every write. Feeds data to `stop-reminders`. Never blocks.
- **stop-reminders** (Stop) — Generates contextual reminders when Claude finishes a response: TDD reminder (source files changed without corresponding test files), commit reminder (5+ files modified). Uses a file-based TTL guard (`stop-hook-fired.lock`, 2-minute expiry) to prevent the infinite loop where Stop hook output causes Claude to resume.
- **block-dangerous-commands** (PreToolUse, matcher: Bash) — Blocks destructive bash commands across 3 severity tiers (critical/high/strict). Default level: `high`. Covers 26 patterns including `rm -rf /`, `git push --force`, `DROP TABLE`, `chmod 777`, `mkfs`, `:(){ :|:& };:`, and more. Logs blocked operations to `~/.claude/hooks-logs/YYYY-MM-DD.jsonl`. Based on claude-code-hooks by karanb192 (MIT License).
- **protect-secrets** (PreToolUse, matcher: Read|Edit|Write|Bash) — Prevents reading, modifying, or exfiltrating sensitive files. 30 sensitive file patterns (`.env`, SSH keys, AWS credentials, PEM files, etc.) + 31 bash exfiltration patterns (`curl -d @.env`, `scp id_rsa`, `cat .env`, etc.). Allowlist for safe files (`.env.example`, `.env.template`). Allowlist intentionally NOT applied to bash commands to prevent bypass via chained commands like `cat .env.example && cat .env`. Based on claude-code-hooks by karanb192 (MIT License).

**code-reviewer agent: Cross-session memory**

Added `memory: user` to `agents/code-reviewer.md`. The code-reviewer agent now retains learnings about codebase patterns, recurring issues, and project conventions across reviews via `~/.claude/user-memory/`.

### Fixed

**README: Incorrect plugin names in install/update commands**

- Cursor install command: `/plugin-add superpowers` → `/plugin-add superpowers-optimized`
- Update command: `/plugin update superpowers` → `/plugin update superpowers-optimized`

**README: Missing documentation for hooks and agents**

- Added Hooks subsection to "What's Inside" listing all 5 hooks
- Added Agents subsection documenting the code-reviewer with `memory: user`
- Updated comparison table with Hooks system and Safety guards rows
- Updated intro and summary to mention hooks and safety guards

---

## v4.4.0 (2026-03-06)

This release closes the gap between what the skills document and what agents actually do wrong. Improvements are sourced from a systematic AI self-review of the plugin combined with the previously-documented real-session failure patterns from `docs/superpowers-optimized/specs/2025-11-28-skills-improvements-from-user-feedback.md`.

### Added

**verification-before-completion: Configuration Change Verification**

Added a dedicated section for changes that affect provider selection, feature flags, environment variables, or credentials. The core gap: agents verified that operations *succeeded* but not that outcomes reflected the *intended change*. The documented failure — a subagent testing an LLM integration, receiving status 200, and reporting "OpenAI working" while still hitting Anthropic — is now addressed with a gate that requires identifying, locating, and verifying the observable difference, not just operation completion. Includes a reference table of insufficient vs required evidence for common change types.

**testing-anti-patterns: Anti-Pattern 6 — Mock-Interface Drift**

Added the sixth anti-pattern: deriving mocks from implementation code rather than the interface definition. The documented failure: both the production code and the mock used `cleanup()` when the interface defined `close()`. Tests passed. Runtime crashed. TypeScript cannot catch this in inline `vi.fn()` mocks. The gate function requires reading the interface file *before* looking at the code under test, then mocking only methods with exactly the names defined in the interface. A failing test caused by a method-name mismatch is correctly treated as a bug in the code, not the mock.

**subagent-driven-development: E2E Process Hygiene section**

Added process cleanup instructions for subagents that start background services. Subagents are stateless and have no knowledge of processes started by previous subagents. Documented failure: 4+ accumulated server processes causing port conflicts and E2E tests hitting stale servers with wrong config. The section provides the exact `pkill`/`lsof`/`pgrep` pattern to include in subagent prompts for service-dependent tasks.

**subagent-driven-development: Blocked Task Protocol section**

Added escalation rules for fundamentally blocked tasks: stop after 2 failed attempts, surface the block to the user with evidence, invoke `senior-engineer` for architectural blocks, and document non-critical blocks in `state.md` rather than silently skipping them. Prevents the undefined behavior of infinite retry loops or silent task omission.

**adaptive-workflow-selector: Skill Invocation Guide**

Added concrete skill lists for each workflow path, solving the gap where the selector chose a path but never specified what that path contained. Three tiers: micro tasks (skip the selector entirely), lightweight (only `test-driven-development` + `verification-before-completion`), and full (follow the `using-superpowers` routing guide).

**frontend-design: Concrete Standards Checklist**

Replaced aspirational guidance ("accessible, responsive, Core Web Vitals") with a verifiable, output-changing checklist across four categories: structure (semantic HTML, heading hierarchy), accessibility (alt text, aria-label, focus-visible, WCAG AA contrast), CSS (design tokens, clamp() typography, prefers-reduced-motion, mobile-first), and performance (lazy loading, layout shift prevention).

### Fixed

**requesting-code-review: Reviewer file access**

Added explicit file reading instruction to both `skills/requesting-code-review/code-reviewer.md` and `agents/code-reviewer.md`. Documented failure: reviewer subagents reporting "file doesn't appear to exist" for files that did exist, because no instruction told them to explicitly load files before reviewing. Reviewers must now run `git diff --name-only` and use the Read tool on each file before analyzing the diff.

**subagent-driven-development/implementer-prompt: Self-review produces fixes, not just findings**

Enhanced step 5 of the implementer prompt: self-review now explicitly requires fixing identified issues and re-running verification before reporting, rather than just noting them. Eliminates the unnecessary round-trip where an implementer who already knows the fix has to report it and wait for a separate fixer subagent.

**context-management: state.md canonical location**

Specified that `state.md` should be written at the project root, or next to the active plan file if one exists. Previously unspecified, causing inconsistency across sessions.

### Improved

**using-superpowers: Routing guide now covers all specialist skills**

Added two missing routing entries: `frontend-design` for UI/frontend implementation tasks, and `security-reviewer` for security-sensitive changes before merge. The routing guide is now comprehensive across all active specialist skills.

**dispatching-parallel-agents: Integration verification strengthened**

Step 6 "Run integration verification" now specifies: execute the full project test suite plus any cross-domain checks, and do not mark the wave complete until integration passes. Removes ambiguity about what "integration verification" means in practice.

---

## v4.3.1 (2026-02-21)

### Added

**Cursor support**

Superpowers now works with Cursor's plugin system. Includes a `.cursor-plugin/plugin.json` manifest and Cursor-specific installation instructions in the README. The SessionStart hook output now includes an `additional_context` field alongside the existing `hookSpecificOutput.additionalContext` for Cursor hook compatibility.

### Fixed

**Windows: Restored polyglot wrapper for reliable hook execution (#518, #504, #491, #487, #466, #440)**

Claude Code's `.sh` auto-detection on Windows was prepending `bash` to the hook command, breaking execution. The fix:

- Renamed `session-start.sh` to `session-start` (extensionless) so auto-detection doesn't interfere
- Restored `run-hook.cmd` polyglot wrapper with multi-location bash discovery (standard Git for Windows paths, then PATH fallback)
- Exits silently if no bash is found rather than erroring
- On Unix, the wrapper runs the script directly via `exec bash`
- Uses POSIX-safe `dirname "$0"` path resolution (works on dash/sh, not just bash)

This fixes SessionStart failures on Windows with spaces in paths, missing WSL, `set -euo pipefail` fragility on MSYS, and backslash mangling.

## v4.3.0 (2026-02-12)

This fix should dramatically improve superpowers skills compliance and should reduce the chances of Claude entering its native plan mode unintentionally.

### Changed

**Brainstorming skill now enforces its workflow instead of describing it**

Models were skipping the design phase and jumping straight to implementation skills like frontend-design, or collapsing the entire brainstorming process into a single text block. The skill now uses hard gates, a mandatory checklist, and a graphviz process flow to enforce compliance:

- `<HARD-GATE>`: no implementation skills, code, or scaffolding until design is presented and user approves
- Explicit checklist (6 items) that must be created as tasks and completed in order
- Graphviz process flow with `writing-plans` as the only valid terminal state
- Anti-pattern callout for "this is too simple to need a design" — the exact rationalization models use to skip the process
- Design section sizing based on section complexity, not project complexity

**Using-superpowers workflow graph intercepts EnterPlanMode**

Added an `EnterPlanMode` intercept to the skill flow graph. When the model is about to enter Claude's native plan mode, it checks whether brainstorming has happened and routes through the brainstorming skill instead. Plan mode is never entered.

### Fixed

**SessionStart hook now runs synchronously**

Changed `async: true` to `async: false` in hooks.json. When async, the hook could fail to complete before the model's first turn, meaning using-superpowers instructions weren't in context for the first message.

## v4.2.0 (2026-02-05)

### Breaking Changes

**Codex: Replaced bootstrap CLI with native skill discovery**

The `superpowers-codex` bootstrap CLI, Windows `.cmd` wrapper, and related bootstrap content file have been removed. Codex now uses native skill discovery via `~/.agents/skills/superpowers/` symlink, so the old `use_skill`/`find_skills` CLI tools are no longer needed.

Installation is now just clone + symlink (documented in INSTALL.md). No Node.js dependency required. The old `~/.codex/skills/` path is deprecated.

### Fixes

**Windows: Fixed Claude Code 2.1.x hook execution (#331)**

Claude Code 2.1.x changed how hooks execute on Windows: it now auto-detects `.sh` files in commands and prepends `bash`. This broke the polyglot wrapper pattern because `bash "run-hook.cmd" session-start.sh` tries to execute the `.cmd` file as a bash script.

Fix: hooks.json now calls session-start.sh directly. Claude Code 2.1.x handles the bash invocation automatically. Also added .gitattributes to enforce LF line endings for shell scripts (fixes CRLF issues on Windows checkout).

**Windows: SessionStart hook runs async to prevent terminal freeze (#404, #413, #414, #419)**

The synchronous SessionStart hook blocked the TUI from entering raw mode on Windows, freezing all keyboard input. Running the hook async prevents the freeze while still injecting superpowers context.

**Windows: Fixed O(n^2) `escape_for_json` performance**

The character-by-character loop using `${input:$i:1}` was O(n^2) in bash due to substring copy overhead. On Windows Git Bash this took 60+ seconds. Replaced with bash parameter substitution (`${s//old/new}`) which runs each pattern as a single C-level pass — 7x faster on macOS, dramatically faster on Windows.

**Codex: Fixed Windows/PowerShell invocation (#285, #243)**

- Windows doesn't respect shebangs, so directly invoking the extensionless `superpowers-codex` script triggered an "Open with" dialog. All invocations now prefixed with `node`.
- Fixed `~/` path expansion on Windows — PowerShell doesn't expand `~` when passed as an argument to `node`. Changed to `$HOME` which expands correctly in both bash and PowerShell.

**Codex: Fixed path resolution in installer**

Used `fileURLToPath()` instead of manual URL pathname parsing to correctly handle paths with spaces and special characters on all platforms.

**Codex: Fixed stale skills path in writing-skills**

Updated `~/.codex/skills/` reference (deprecated) to `~/.agents/skills/` for native discovery.

### Improvements

**Worktree isolation now required before implementation**

Added `using-git-worktrees` as a required skill for both `subagent-driven-development` and `executing-plans`. Implementation workflows now explicitly require setting up an isolated worktree before starting work, preventing accidental work directly on main.

**Main branch protection softened to require explicit consent**

Instead of prohibiting main branch work entirely, the skills now allow it with explicit user consent. More flexible while still ensuring users are aware of the implications.

**Simplified installation verification**

Removed `/help` command check and specific slash command list from verification steps. Skills are primarily invoked by describing what you want to do, not by running specific commands.

**Codex: Clarified subagent tool mapping in bootstrap**

Improved documentation of how Codex tools map to Claude Code equivalents for subagent workflows.

### Tests

- Added worktree requirement test for subagent-driven-development
- Added main branch red flag warning test
- Fixed case sensitivity in skill recognition test assertions

---

## v4.1.1 (2026-01-23)

### Fixes

**OpenCode: Standardized on `plugins/` directory per official docs (#343)**

OpenCode's official documentation uses `~/.config/opencode/plugins/` (plural). Our docs previously used `plugin/` (singular). While OpenCode accepts both forms, we've standardized on the official convention to avoid confusion.

Changes:

- Renamed `.opencode/plugin/` to `.opencode/plugins/` in repo structure
- Updated all installation docs (INSTALL.md, README.opencode.md) across all platforms
- Updated test scripts to match

**OpenCode: Fixed symlink instructions (#339, #342)**

- Added explicit `rm` before `ln -s` (fixes "file already exists" errors on reinstall)
- Added missing skills symlink step that was absent from INSTALL.md
- Updated from deprecated `use_skill`/`find_skills` to native `skill` tool references

---

## v4.1.0 (2026-01-23)

### Breaking Changes

**OpenCode: Switched to native skills system**

Superpowers for OpenCode now uses OpenCode's native `skill` tool instead of custom `use_skill`/`find_skills` tools. This is a cleaner integration that works with OpenCode's built-in skill discovery.

**Migration required:** Skills must be symlinked to `~/.config/opencode/skills/superpowers/` (see updated installation docs).

### Fixes

**OpenCode: Fixed agent reset on session start (#226)**

The previous bootstrap injection method using `session.prompt({ noReply: true })` caused OpenCode to reset the selected agent to "build" on first message. Now uses `experimental.chat.system.transform` hook which modifies the system prompt directly without side effects.

**OpenCode: Fixed Windows installation (#232)**

- Removed dependency on `skills-core.js` (eliminates broken relative imports when file is copied instead of symlinked)
- Added comprehensive Windows installation docs for cmd.exe, PowerShell, and Git Bash
- Documented proper symlink vs junction usage for each platform

**Claude Code: Fixed Windows hook execution for Claude Code 2.1.x**

Claude Code 2.1.x changed how hooks execute on Windows: it now auto-detects `.sh` files in commands and prepends `bash` . This broke the polyglot wrapper pattern because `bash "run-hook.cmd" session-start.sh` tries to execute the .cmd file as a bash script.

Fix: hooks.json now calls session-start.sh directly. Claude Code 2.1.x handles the bash invocation automatically. Also added .gitattributes to enforce LF line endings for shell scripts (fixes CRLF issues on Windows checkout).

---

## v4.0.3 (2025-12-26)

### Improvements

**Strengthened using-superpowers skill for explicit skill requests**

Addressed a failure mode where Claude would skip invoking a skill even when the user explicitly requested it by name (e.g., "subagent-driven-development, please"). Claude would think "I know what that means" and start working directly instead of loading the skill.

Changes:

- Updated "The Rule" to say "Invoke relevant or requested skills" instead of "Check for skills" - emphasizing active invocation over passive checking
- Added "BEFORE any response or action" - the original wording only mentioned "response" but Claude would sometimes take action without responding first
- Added reassurance that invoking a wrong skill is okay - reduces hesitation
- Added new red flag: "I know what that means" → Knowing the concept ≠ using the skill

**Added explicit skill request tests**

New test suite in `tests/explicit-skill-requests/` that verifies Claude correctly invokes skills when users request them by name. Includes single-turn and multi-turn test scenarios.

## v4.0.2 (2025-12-23)

### Fixes

**Slash commands now user-only**

Added `disable-model-invocation: true` to all three slash commands (`/brainstorm`, `/execute-plan`, `/write-plan`). Claude can no longer invoke these commands via the Skill tool—they're restricted to manual user invocation only.

The underlying skills (`superpowers:brainstorming`, `superpowers:executing-plans`, `superpowers:writing-plans`) remain available for Claude to invoke autonomously. This change prevents confusion when Claude would invoke a command that just redirects to a skill anyway.

## v4.0.1 (2025-12-23)

### Fixes

**Clarified how to access skills in Claude Code**

Fixed a confusing pattern where Claude would invoke a skill via the Skill tool, then try to Read the skill file separately. The `using-superpowers` skill now explicitly states that the Skill tool loads skill content directly—no need to read files.

- Added "How to Access Skills" section to `using-superpowers`
- Changed "read the skill" → "invoke the skill" in instructions
- Updated slash commands to use fully qualified skill names (e.g., `superpowers:brainstorming`)

**Added GitHub thread reply guidance to receiving-code-review** (h/t @ralphbean)

Added a note about replying to inline review comments in the original thread rather than as top-level PR comments.

**Added automation-over-documentation guidance to writing-skills** (h/t @EthanJStark)

Added guidance that mechanical constraints should be automated, not documented—save skills for judgment calls.

## v4.0.0 (2025-12-17)

### New Features

**Two-stage code review in subagent-driven-development**

Subagent workflows now use two separate review stages after each task:

1. **Spec compliance review** - Skeptical reviewer verifies implementation matches spec exactly. Catches missing requirements AND over-building. Won't trust implementer's report—reads actual code.
2. **Code quality review** - Only runs after spec compliance passes. Reviews for clean code, test coverage, maintainability.

This catches the common failure mode where code is well-written but doesn't match what was requested. Reviews are loops, not one-shot: if reviewer finds issues, implementer fixes them, then reviewer checks again.

Other subagent workflow improvements:

- Controller provides full task text to workers (not file references)
- Workers can ask clarifying questions before AND during work
- Self-review checklist before reporting completion
- Plan read once at start, extracted to TodoWrite

New prompt templates in `skills/subagent-driven-development/`:

- `implementer-prompt.md` - Includes self-review checklist, encourages questions
- `spec-reviewer-prompt.md` - Skeptical verification against requirements
- `code-quality-reviewer-prompt.md` - Standard code review

**Debugging techniques consolidated with tools**

`systematic-debugging` now bundles supporting techniques and tools:

- `root-cause-tracing.md` - Trace bugs backward through call stack
- `defense-in-depth.md` - Add validation at multiple layers
- `condition-based-waiting.md` - Replace arbitrary timeouts with condition polling
- `find-polluter.sh` - Bisection script to find which test creates pollution
- `condition-based-waiting-example.ts` - Complete implementation from real debugging session

**Testing anti-patterns reference**

`test-driven-development` now includes `testing-anti-patterns.md` covering:

- Testing mock behavior instead of real behavior
- Adding test-only methods to production classes
- Mocking without understanding dependencies
- Incomplete mocks that hide structural assumptions

**Skill test infrastructure**

Three new test frameworks for validating skill behavior:

`tests/skill-triggering/` - Validates skills trigger from naive prompts without explicit naming. Tests 6 skills to ensure descriptions alone are sufficient.

`tests/claude-code/` - Integration tests using `claude -p` for headless testing. Verifies skill usage via session transcript (JSONL) analysis. Includes `analyze-token-usage.py` for cost tracking.

`tests/subagent-driven-dev/` - End-to-end workflow validation with two complete test projects:

- `go-fractals/` - CLI tool with Sierpinski/Mandelbrot (10 tasks)
- `svelte-todo/` - CRUD app with localStorage and Playwright (12 tasks)

### Major Changes

**DOT flowcharts as executable specifications**

Rewrote key skills using DOT/GraphViz flowcharts as the authoritative process definition. Prose becomes supporting content.

**The Description Trap** (documented in `writing-skills`): Discovered that skill descriptions override flowchart content when descriptions contain workflow summaries. Claude follows the short description instead of reading the detailed flowchart. Fix: descriptions must be trigger-only ("Use when X") with no process details.

**Skill priority in using-superpowers**

When multiple skills apply, process skills (brainstorming, debugging) now explicitly come before implementation skills. "Build X" triggers brainstorming first, then domain skills.

**brainstorming trigger strengthened**

Description changed to imperative: "You MUST use this before any creative work—creating features, building components, adding functionality, or modifying behavior."

### Breaking Changes

**Skill consolidation** - Six standalone skills merged:

- `root-cause-tracing`, `defense-in-depth`, `condition-based-waiting` → bundled in `systematic-debugging/`
- `testing-skills-with-subagents` → bundled in `writing-skills/`
- `testing-anti-patterns` → bundled in `test-driven-development/`
- `sharing-skills` removed (obsolete)

### Other Improvements

- **render-graphs.js** - Tool to extract DOT diagrams from skills and render to SVG
- **Rationalizations table** in using-superpowers - Scannable format including new entries: "I need more context first", "Let me explore first", "This feels productive"
- **docs/testing.md** - Guide to testing skills with Claude Code integration tests

---

## v3.6.2 (2025-12-03)

### Fixed

- **Linux Compatibility**: Fixed polyglot hook wrapper (`run-hook.cmd`) to use POSIX-compliant syntax
  - Replaced bash-specific `${BASH_SOURCE[0]:-$0}` with standard `$0` on line 16
  - Resolves "Bad substitution" error on Ubuntu/Debian systems where `/bin/sh` is dash
  - Fixes #141

---

## v3.5.1 (2025-11-24)

### Changed

- **OpenCode Bootstrap Refactor**: Switched from `chat.message` hook to `session.created` event for bootstrap injection
  - Bootstrap now injects at session creation via `session.prompt()` with `noReply: true`
  - Explicitly tells the model that using-superpowers is already loaded to prevent redundant skill loading
  - Consolidated bootstrap content generation into shared `getBootstrapContent()` helper
  - Cleaner single-implementation approach (removed fallback pattern)

---

## v3.5.0 (2025-11-23)

### Added

- **OpenCode Support**: Native JavaScript plugin for OpenCode.ai
  - Custom tools: `use_skill` and `find_skills`
  - Message insertion pattern for skill persistence across context compaction
  - Automatic context injection via chat.message hook
  - Auto re-injection on session.compacted events
  - Three-tier skill priority: project > personal > superpowers
  - Project-local skills support (`.opencode/skills/`)
  - Shared core module (`lib/skills-core.js`) for code reuse with Codex
  - Automated test suite with proper isolation (`tests/opencode/`)
  - Platform-specific documentation (`docs/platforms/opencode.md`, `docs/platforms/codex.md`)

### Changed

- **Refactored Codex Implementation**: Now uses shared `lib/skills-core.js` ES module
  - Eliminates code duplication between Codex and OpenCode
  - Single source of truth for skill discovery and parsing
  - Codex successfully loads ES modules via Node.js interop
- **Improved Documentation**: Rewrote README to explain problem/solution clearly
  - Removed duplicate sections and conflicting information
  - Added complete workflow description (brainstorm → plan → execute → finish)
  - Simplified platform installation instructions
  - Emphasized skill-checking protocol over automatic activation claims

---

## v3.4.1 (2025-10-31)

### Improvements

- Optimized superpowers bootstrap to eliminate redundant skill execution. The `using-superpowers` skill content is now provided directly in session context, with clear guidance to use the Skill tool only for other skills. This reduces overhead and prevents the confusing loop where agents would execute `using-superpowers` manually despite already having the content from session start.

## v3.4.0 (2025-10-30)

### Improvements

- Simplified `brainstorming` skill to return to original conversational vision. Removed heavyweight 6-phase process with formal checklists in favor of natural dialogue: ask questions one at a time, then present design in 200-300 word sections with validation. Keeps documentation and implementation handoff features.

## v3.3.1 (2025-10-28)

### Improvements

- Updated `brainstorming` skill to require autonomous recon before questioning, encourage recommendation-driven decisions, and prevent agents from delegating prioritization back to humans.
- Applied writing clarity improvements to `brainstorming` skill following Strunk's "Elements of Style" principles (omitted needless words, converted negative to positive form, improved parallel construction).

### Bug Fixes

- Clarified `writing-skills` guidance so it points to the correct agent-specific personal skill directories (`~/.claude/skills` for Claude Code, `~/.codex/skills` for Codex).

## v3.3.0 (2025-10-28)

### New Features

**Experimental Codex Support**

- Added unified `superpowers-codex` script with bootstrap/use-skill/find-skills commands
- Cross-platform Node.js implementation (works on Windows, macOS, Linux)
- Namespaced skills: `superpowers:skill-name` for superpowers skills, `skill-name` for personal
- Personal skills override superpowers skills when names match
- Clean skill display: shows name/description without raw frontmatter
- Helpful context: shows supporting files directory for each skill
- Tool mapping for Codex: TodoWrite→update_plan, subagents→manual fallback, etc.
- Bootstrap integration with minimal AGENTS.md for automatic startup
- Complete installation guide and bootstrap instructions specific to Codex

**Key differences from Claude Code integration:**

- Single unified script instead of separate tools
- Tool substitution system for Codex-specific equivalents
- Simplified subagent handling (manual work instead of delegation)
- Updated terminology: "Superpowers skills" instead of "Core skills"

### Files Added

- `.codex/INSTALL.md` - Installation guide for Codex users
- `.codex/superpowers-bootstrap.md` - Bootstrap instructions with Codex adaptations
- `.codex/superpowers-codex` - Unified Node.js executable with all functionality

**Note:** Codex support is experimental. The integration provides core superpowers functionality but may require refinement based on user feedback.

## v3.2.3 (2025-10-23)

### Improvements

**Updated using-superpowers skill to use Skill tool instead of Read tool**

- Changed skill invocation instructions from Read tool to Skill tool
- Updated description: "using Read tool" → "using Skill tool"
- Updated step 3: "Use the Read tool" → "Use the Skill tool to read and run"
- Updated rationalization list: "Read the current version" → "Run the current version"

The Skill tool is the proper mechanism for invoking skills in Claude Code. This update corrects the bootstrap instructions to guide agents toward the correct tool.

### Files Changed

- Updated: `skills/using-superpowers/SKILL.md` - Changed tool references from Read to Skill

## v3.2.2 (2025-10-21)

### Improvements

**Strengthened using-superpowers skill against agent rationalization**

- Added EXTREMELY-IMPORTANT block with absolute language about mandatory skill checking
  - "If even 1% chance a skill applies, you MUST read it"
  - "You do not have a choice. You cannot rationalize your way out."
- Added MANDATORY FIRST RESPONSE PROTOCOL checklist
  - 5-step process agents must complete before any response
  - Explicit "responding without this = failure" consequence
- Added Common Rationalizations section with 8 specific evasion patterns
  - "This is just a simple question" → WRONG
  - "I can check files quickly" → WRONG
  - "Let me gather information first" → WRONG
  - Plus 5 more common patterns observed in agent behavior

These changes address observed agent behavior where they rationalize around skill usage despite clear instructions. The forceful language and pre-emptive counter-arguments aim to make non-compliance harder.

### Files Changed

- Updated: `skills/using-superpowers/SKILL.md` - Added three layers of enforcement to prevent skill-skipping rationalization

## v3.2.1 (2025-10-20)

### New Features

**Code reviewer agent now included in plugin**

- Added `superpowers:code-reviewer` agent to plugin's `agents/` directory
- Agent provides systematic code review against plans and coding standards
- Previously required users to have personal agent configuration
- All skill references updated to use namespaced `superpowers:code-reviewer`
- Fixes #55

### Files Changed

- New: `agents/code-reviewer.md` - Agent definition with review checklist and output format
- Updated: `skills/requesting-code-review/SKILL.md` - References to `superpowers:code-reviewer`
- Updated: `skills/subagent-driven-development/SKILL.md` - References to `superpowers:code-reviewer`

## v3.2.0 (2025-10-18)

### New Features

**Design documentation in brainstorming workflow**

- Added Phase 4: Design Documentation to brainstorming skill
- Design documents now written to `docs/superpowers-optimized/specs/YYYY-MM-DD-<topic>-design.md` before implementation
- Restores functionality from original brainstorming command that was lost during skill conversion
- Documents written before worktree setup and implementation planning
- Tested with subagent to verify compliance under time pressure

### Breaking Changes

**Skill reference namespace standardization**

- All internal skill references now use `superpowers:` namespace prefix
- Updated format: `superpowers:test-driven-development` (previously just `test-driven-development`)
- Affects all REQUIRED SUB-SKILL, RECOMMENDED SUB-SKILL, and REQUIRED BACKGROUND references
- Aligns with how skills are invoked using the Skill tool
- Files updated: brainstorming, executing-plans, subagent-driven-development, systematic-debugging, testing-skills-with-subagents, writing-plans, writing-skills

### Improvements

**Design vs implementation plan naming**

- Design documents use `-design.md` suffix to prevent filename collisions
- Implementation plans continue using existing `YYYY-MM-DD-<feature-name>.md` format
- Design specs stored in `docs/superpowers-optimized/specs/`, implementation plans in `docs/superpowers-optimized/plans/`

## v3.1.1 (2025-10-17)

### Bug Fixes

- **Fixed command syntax in README** (#44) - Updated all command references to use correct namespaced syntax (`/superpowers:brainstorm` instead of `/brainstorm`). Plugin-provided commands are automatically namespaced by Claude Code to avoid conflicts between plugins.

## v3.1.0 (2025-10-17)

### Breaking Changes

**Skill names standardized to lowercase**

- All skill frontmatter `name:` fields now use lowercase kebab-case matching directory names
- Examples: `brainstorming`, `test-driven-development`, `using-git-worktrees`
- All skill announcements and cross-references updated to lowercase format
- This ensures consistent naming across directory names, frontmatter, and documentation

### New Features

**Enhanced brainstorming skill**

- Added Quick Reference table showing phases, activities, and tool usage
- Added copyable workflow checklist for tracking progress
- Added decision flowchart for when to revisit earlier phases
- Added comprehensive AskUserQuestion tool guidance with concrete examples
- Added "Question Patterns" section explaining when to use structured vs open-ended questions
- Restructured Key Principles as scannable table

**Anthropic best practices integration**

- Added `skills/writing-skills/anthropic-best-practices.md` - Official Anthropic skill authoring guide
- Referenced in writing-skills SKILL.md for comprehensive guidance
- Provides patterns for progressive disclosure, workflows, and evaluation

### Improvements

**Skill cross-reference clarity**

- All skill references now use explicit requirement markers:
  - `**REQUIRED BACKGROUND:`** - Prerequisites you must understand
  - `**REQUIRED SUB-SKILL:**` - Skills that must be used in workflow
  - `**Complementary skills:**` - Optional but helpful related skills
- Removed old path format (`skills/collaboration/X` → just `X`)
- Updated Integration sections with categorized relationships (Required vs Complementary)
- Updated cross-reference documentation with best practices

**Alignment with Anthropic best practices**

- Fixed description grammar and voice (fully third-person)
- Added Quick Reference tables for scanning
- Added workflow checklists Claude can copy and track
- Appropriate use of flowcharts for non-obvious decision points
- Improved scannable table formats
- All skills well under 500-line recommendation

### Bug Fixes

- **Re-added missing command redirects** - Restored `commands/brainstorm.md` and `commands/write-plan.md` that were accidentally removed in v3.0 migration
- Fixed `defense-in-depth` name mismatch (was `Defense-in-Depth-Validation`)
- Fixed `receiving-code-review` name mismatch (was `Code-Review-Reception`)
- Fixed `commands/brainstorm.md` reference to correct skill name
- Removed references to non-existent related skills

### Documentation

**writing-skills improvements**

- Updated cross-referencing guidance with explicit requirement markers
- Added reference to Anthropic's official best practices
- Improved examples showing proper skill reference format

## v3.0.1 (2025-10-16)

### Changes

We now use Anthropic's first-party skills system!

## v2.0.2 (2025-10-12)

### Bug Fixes

- **Fixed false warning when local skills repo is ahead of upstream** - The initialization script was incorrectly warning "New skills available from upstream" when the local repository had commits ahead of upstream. The logic now correctly distinguishes between three git states: local behind (should update), local ahead (no warning), and diverged (should warn).

## v2.0.1 (2025-10-12)

### Bug Fixes

- **Fixed session-start hook execution in plugin context** (#8, PR #9) - The hook was failing silently with "Plugin hook error" preventing skills context from loading. Fixed by:
  - Using `${BASH_SOURCE[0]:-$0}` fallback when BASH_SOURCE is unbound in Claude Code's execution context
  - Adding `|| true` to handle empty grep results gracefully when filtering status flags

---

# Superpowers v2.0.0 Release Notes

## Overview

Superpowers v2.0 makes skills more accessible, maintainable, and community-driven through a major architectural shift.

The headline change is **skills repository separation**: all skills, scripts, and documentation have moved from the plugin into a dedicated repository ([obra/superpowers-skills](https://github.com/obra/superpowers-skills)). This transforms superpowers from a monolithic plugin into a lightweight shim that manages a local clone of the skills repository. Skills auto-update on session start. Users fork and contribute improvements via standard git workflows. The skills library versions independently from the plugin.

Beyond infrastructure, this release adds nine new skills focused on problem-solving, research, and architecture. We rewrote the core **using-skills** documentation with imperative tone and clearer structure, making it easier for Claude to understand when and how to use skills. **find-skills** now outputs paths you can paste directly into the Read tool, eliminating friction in the skills discovery workflow.

Users experience seamless operation: the plugin handles cloning, forking, and updating automatically. Contributors find the new architecture makes improving and sharing skills trivial. This release lays the foundation for skills to evolve rapidly as a community resource.

## Breaking Changes

### Skills Repository Separation

**The biggest change:** Skills no longer live in the plugin. They've been moved to a separate repository at [obra/superpowers-skills](https://github.com/obra/superpowers-skills).

**What this means for you:**

- **First install:** Plugin automatically clones skills to `~/.config/superpowers/skills/`
- **Forking:** During setup, you'll be offered the option to fork the skills repo (if `gh` is installed)
- **Updates:** Skills auto-update on session start (fast-forward when possible)
- **Contributing:** Work on branches, commit locally, submit PRs to upstream
- **No more shadowing:** Old two-tier system (personal/core) replaced with single-repo branch workflow

**Migration:**

If you have an existing installation:

1. Your old `~/.config/superpowers/.git` will be backed up to `~/.config/superpowers/.git.bak`
2. Old skills will be backed up to `~/.config/superpowers/skills.bak`
3. Fresh clone of obra/superpowers-skills will be created at `~/.config/superpowers/skills/`

### Removed Features

- **Personal superpowers overlay system** - Replaced with git branch workflow
- **setup-personal-superpowers hook** - Replaced by initialize-skills.sh

## New Features

### Skills Repository Infrastructure

**Automatic Clone & Setup** (`lib/initialize-skills.sh`)

- Clones obra/superpowers-skills on first run
- Offers fork creation if GitHub CLI is installed
- Sets up upstream/origin remotes correctly
- Handles migration from old installation

**Auto-Update**

- Fetches from tracking remote on every session start
- Auto-merges with fast-forward when possible
- Notifies when manual sync needed (branch diverged)
- Uses pulling-updates-from-skills-repository skill for manual sync

### New Skills

**Problem-Solving Skills** (`skills/problem-solving/`)

- **collision-zone-thinking** - Force unrelated concepts together for emergent insights
- **inversion-exercise** - Flip assumptions to reveal hidden constraints
- **meta-pattern-recognition** - Spot universal principles across domains
- **scale-game** - Test at extremes to expose fundamental truths
- **simplification-cascades** - Find insights that eliminate multiple components
- **when-stuck** - Dispatch to right problem-solving technique

**Research Skills** (`skills/research/`)

- **tracing-knowledge-lineages** - Understand how ideas evolved over time

**Architecture Skills** (`skills/architecture/`)

- **preserving-productive-tensions** - Keep multiple valid approaches instead of forcing premature resolution

### Skills Improvements

**using-skills (formerly getting-started)**

- Renamed from getting-started to using-skills
- Complete rewrite with imperative tone (v4.0.0)
- Front-loaded critical rules
- Added "Why" explanations for all workflows
- Always includes /SKILL.md suffix in references
- Clearer distinction between rigid rules and flexible patterns

**writing-skills**

- Cross-referencing guidance moved from using-skills
- Added token efficiency section (word count targets)
- Improved CSO (Claude Search Optimization) guidance

**sharing-skills**

- Updated for new branch-and-PR workflow (v2.0.0)
- Removed personal/core split references

**pulling-updates-from-skills-repository** (new)

- Complete workflow for syncing with upstream
- Replaces old "updating-skills" skill

### Tools Improvements

**find-skills**

- Now outputs full paths with /SKILL.md suffix
- Makes paths directly usable with Read tool
- Updated help text

**skill-run**

- Moved from scripts/ to skills/using-skills/
- Improved documentation

### Plugin Infrastructure

**Session Start Hook**

- Now loads from skills repository location
- Shows full skills list at session start
- Prints skills location info
- Shows update status (updated successfully / behind upstream)
- Moved "skills behind" warning to end of output

**Environment Variables**

- `SUPERPOWERS_SKILLS_ROOT` set to `~/.config/superpowers/skills`
- Used consistently throughout all paths

## Bug Fixes

- Fixed duplicate upstream remote addition when forking
- Fixed find-skills double "skills/" prefix in output
- Removed obsolete setup-personal-superpowers call from session-start
- Fixed path references throughout hooks and commands

## Documentation

### README

- Updated for new skills repository architecture
- Prominent link to superpowers-skills repo
- Updated auto-update description
- Fixed skill names and references
- Updated Meta skills list

### Testing Documentation

- Added comprehensive testing checklist (`docs/TESTING-CHECKLIST.md`)
- Created local marketplace config for testing
- Documented manual testing scenarios

## Technical Details

### File Changes

**Added:**

- `lib/initialize-skills.sh` - Skills repo initialization and auto-update
- `docs/TESTING-CHECKLIST.md` - Manual testing scenarios
- `.claude-plugin/marketplace.json` - Local testing config

**Removed:**

- `skills/` directory (82 files) - Now in obra/superpowers-skills
- `scripts/` directory - Now in obra/superpowers-skills/skills/using-skills/
- `hooks/setup-personal-superpowers.sh` - Obsolete

**Modified:**

- `hooks/session-start.sh` - Use skills from ~/.config/superpowers/skills
- `commands/brainstorm.md` - Updated paths to SUPERPOWERS_SKILLS_ROOT
- `commands/write-plan.md` - Updated paths to SUPERPOWERS_SKILLS_ROOT
- `commands/execute-plan.md` - Updated paths to SUPERPOWERS_SKILLS_ROOT
- `README.md` - Complete rewrite for new architecture

### Commit History

This release includes:

- 20+ commits for skills repository separation
- PR #1: Amplifier-inspired problem-solving and research skills
- PR #2: Personal superpowers overlay system (later replaced)
- Multiple skill refinements and documentation improvements

## Upgrade Instructions

### Fresh Install

```bash
# In Claude Code
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

The plugin handles everything automatically.

### Upgrading from v1.x

1. **Backup your personal skills** (if you have any):
  ```bash
   cp -r ~/.config/superpowers/skills ~/superpowers-skills-backup
  ```
2. **Update the plugin:**
  ```bash
   /plugin update superpowers
  ```
3. **On next session start:**
  - Old installation will be backed up automatically
  - Fresh skills repo will be cloned
  - If you have GitHub CLI, you'll be offered the option to fork
4. **Migrate personal skills** (if you had any):
  - Create a branch in your local skills repo
  - Copy your personal skills from backup
  - Commit and push to your fork
  - Consider contributing back via PR

## What's Next

### For Users

- Explore the new problem-solving skills
- Try the branch-based workflow for skill improvements
- Contribute skills back to the community

### For Contributors

- Skills repository is now at [https://github.com/obra/superpowers-skills](https://github.com/obra/superpowers-skills)
- Fork → Branch → PR workflow
- See skills/meta/writing-skills/SKILL.md for TDD approach to documentation

## Known Issues

None at this time.

## Credits

- Problem-solving skills inspired by Amplifier patterns
- Community contributions and feedback
- Extensive testing and iteration on skill effectiveness

---

**Full Changelog:** [https://github.com/obra/superpowers/compare/dd013f6...main](https://github.com/obra/superpowers/compare/dd013f6...main)
**Skills Repository:** [https://github.com/obra/superpowers-skills](https://github.com/obra/superpowers-skills)
**Issues:** [https://github.com/obra/superpowers/issues](https://github.com/obra/superpowers/issues)
