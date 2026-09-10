# Design — the `<superpowers-defaults>` session block

_Date: 2026-09-09 · Status: approved_

## Problem

A skill is Markdown read by the model. The model cannot read environment
variables. So a value that a skill needs must travel from the environment into
the session as a tag injected by `hooks/session-start`.

Today exactly one parameter does this. `hooks/session-start:436-439` reads
`SUPERPOWERS_REVIEWERS_PER_LENS` and emits a `<reviewers-per-lens>` tag, which
six skills read. Three other environment variables exist
(`SUPERPOWERS_PRESSURE_THRESHOLD`, `SUPERPOWERS_AUTO_UPDATE`,
`SP_NO_COMPRESS`), but every one of them is read directly by hook code and
never reaches a skill.

Two parameters that users are asked for in the same breath as M have no
environment default at all:

- **N**, the number of review rounds (default 3). Asked at the spec gate, the
  plan gate, the whole-branch code-review gate, and at orchestration Phase 0.
- **the batch/task cap** (default 3). Asked at orchestration Phase 0, and used
  silently by `subagent-driven-development` Batched Autonomous Mode.

Adding each new parameter the way M was added costs a dedicated tag, a
dedicated anti-injection rule, validation written twice, and a wording block
copied into every consuming skill. Repeating that per parameter does not
scale, and it multiplies the inconsistencies the existing variables already
carry.

## Prior art and alternatives

No decision in this design matched the prior-art trigger predicate.

## Scope

In scope:

1. One generalized `<superpowers-defaults>` block, emitted by
   `hooks/session-start`, carrying one `name=value` line per parameter.
2. Three parameters carried in it: `reviewers-per-lens` (existing, moved),
   `review-rounds` (new), `batch-task-cap` (new).
3. One normative resolution rule, defined once, then cited by name and
   restated in short form at each site, replacing the divergent per-parameter
   rules the skills carry today.
4. One canonical documentation block listing every parameter with the same
   structure.

## Non-goals

- **No change to the three hook-internal variables.**
  `SUPERPOWERS_PRESSURE_THRESHOLD`, `SUPERPOWERS_AUTO_UPDATE` and
  `SP_NO_COMPRESS` are read by hook code, never by a skill. They gain nothing
  from the block.
- **`SP_NO_COMPRESS` is not renamed.** Its `SP_` prefix breaks the
  `SUPERPOWERS_` convention, but the name is documented in `README.md` and in
  `docs/architecture/smart-compress.md`, and users may have it in
  `settings.json`. Renaming it is a user-visible change that serves no
  parameter in this design.
- **No shared validation helper for hook code.** Each hook keeps its own
  guard. Extracting one would widen the change into a hook refactor without
  serving any parameter in this design.
- **The Codex and OpenCode paths are unchanged.**
  `hooks/codex/session-start-adapter.js` builds its own session context and
  emits no `<reviewers-per-lens>` tag today; it emits no block after this
  change either. `.opencode/plugins/superpowers-orchestrator.js` injects its
  bootstrap context through a system-prompt transform and never runs
  `hooks/session-start` at all. On both platforms every parameter resolves at
  tier 3, its hardcoded default. Cursor runs the same `hooks/session-start`
  (`hooks/hooks-cursor.json:10`) and so receives the block, but that has not
  been verified live.
- **No change to positional argument parsing.** In
  `/multi-code-review [BASE] [N]` an integer 0–10 is still N and anything else
  is still a git ref. The block supplies the fallback only when no N token is
  present in the invocation.
- **The block never suppresses a question that is asked today.** It changes
  which value is offered, and which value the already-silent paths resolve to.
  A skill that asks today still asks.
- **No legacy synonym for the removed tag.** See "Rollout" below; the
  mid-session-update window is an accepted limitation.
- **No new parameters beyond the three named above.** Other model-read and
  hook-read knobs were surveyed and deliberately left hardcoded.

## Architecture and data flow

```
settings.json env block
        |
        v
  environment variable            (SUPERPOWERS_REVIEW_ROUNDS=4)
        |
        v
  hooks/session-start             validates; falls back on any invalid value
        |
        v
  <superpowers-defaults> block    emitted LAST in session_context
        |
        v
  main session                    reads the block
        |                         a controller subagent does NOT; it takes
        |                         its values from its filled template
        v
  offered default in a question, or a silently resolved value
```

The block is emitted at the position `${reviewers_escaped}` occupies today —
the end of `session_context`, after every embedded workspace file
(`project-map.md`, `session-log.md`, `state.md`, `known-issues.md`,
`context-snapshot.json`).

**Design assumption, carried without an edit or a test.** A fork inherits the
dispatching session's transcript (`skills/orchestrating-development/SKILL.md:1337`)
and may therefore see the block. No rule is added forbidding a fork to read it,
because a fork is dispatched to decide one question and never runs a review
loop, so it resolves none of these parameters. This assumption produces no edit
site and no assertion; it is recorded so a later reader does not mistake the
"main session only" wording for a claim about forks.

### Block format

**The block must be built with real newline characters.** This is the single
most important implementation constraint in this design, and it is *not* how
`hooks/session-start:436` builds the tag it replaces.

That line assigns a bash **double-quoted** string,
`reviewers_content="\n\n<reviewers-per-lens>1</reviewers-per-lens>"`. In double
quotes `\n` is not a newline — it is the two characters backslash and `n`.
`escape_for_json` (`hooks/session-start:449-457`) then runs
`s="${s//\\/\\\\}"` first, doubling every backslash, so the JSON carries `\\n`
and the decoded context receives a literal backslash-n. Today that is harmless,
because the tag is a single self-delimiting element. A multi-line block is the
first thing that depends on the difference.

Measured, running the repository's own `escape_for_json` over both forms and
JSON-decoding the result:

| Construction | Physical lines delivered |
|---|---|
| `block="\n\n<superpowers-defaults>\n…"` (double quotes, as line 436) | **1** |
| `block=$'\n\n<superpowers-defaults>\n…'` (ANSI-C quoting) | **5** |

Use ANSI-C quoting (`$'…'`), a heredoc, or `printf` — any form that puts real
newline bytes in the variable, so `escape_for_json`'s substitution, verbatim
from `hooks/session-start:452`:

```sh
s="${s//$'\n'/\\n}"
```

turns them into true JSON `\n` escapes. Two real newline bytes precede the
opening delimiter, and no newline follows the closing one. Do **not** copy the
spacing construction of line 436 — that is the form this section warns against.

Delivered to the model, the block is separate physical lines:

```
<superpowers-defaults>
reviewers-per-lens=1
review-rounds=3
batch-task-cap=3
[closing delimiter, written broken here — see the rule below]
```

**No complete block may appear in any skill body, any documentation file, or
this spec.** A reader selects the last complete block, and a skill body loaded
by the Skill tool, a documentation file, or a diff enters the context *after*
the session-start injection. A complete literal example anywhere in those texts
becomes the last complete block, and every user who set an environment variable
silently gets the hardcoded defaults instead. Every example — in
`skills/multi-doc-review/SKILL.md`, at each citing site, in `README.md`, in
`docs/guide/README.md`, and in this document — must break one delimiter, for
example by writing the closing tag as `</superpowers-defaults…>` or by omitting
it with a bracketed note. The wording-contract test asserts that no
`skills/**/SKILL.md` contains both an opening and a closing delimiter line.

**Contract:** the block arrives as separate physical lines after JSON decoding.
Every reader rule below depends on it. If it arrives as one escaped line the
symptom is **not** a clean silent tier 3: a model shown one line containing
`reviewers-per-lens=1 review-rounds=3 batch-task-cap=3` will often still extract
the values, so the failure is intermittent and per-session. A future debugger
must not rule this bug out because the feature appeared to work once.

**Complete block.** A block is *complete* when it has an opening
`<superpowers-defaults>` line and a matching closing delimiter line.
Completeness is a property of the delimiters only — it says nothing about which
parameters are present. **Pairing rule:** scan backwards from the end of the
session-start injection for a closing line, then back to the nearest preceding
opening line. Nearest pairing, never outermost.

The block `hooks/session-start` emits always carries every parameter, including
when a value falls back to its hardcoded default — emitting nothing on the
fallback path would leave a block planted in a repository file as the only
block in the injection.

One line holds one parameter, written `name=value` with no spaces around the
`=`. Line order is fixed and is the order of the parameter table below.

**Canonical form is a writing convention for the hook, not a reader-side
defence.** The reader is a language model and every reader row in the error
table is prose only, so nothing verifies that it refuses
`reviewers-per-lens = 5` or `Reviewers-Per-Lens=5`. Strictness would only ever
matter against a writer that is not the hook, which is precisely the case it
cannot be trusted to catch. The real defences are the hook's always-complete,
always-last emission, the injection scoping below, and the platform clause.

## Interfaces and contracts

### Parameter table

This table is the **single source for tier 3**. Where a skill's prose names a
hardcoded default, it must match this table.

| Environment variable | Block line | Accepted in the block | Hardcoded default |
|---|---|---|---|
| `SUPERPOWERS_REVIEWERS_PER_LENS` | `reviewers-per-lens` | `1` `2` `3` `4` `5` | `1` |
| `SUPERPOWERS_REVIEW_ROUNDS` | `review-rounds` | `1` `2` `3` `4` `5` `6` `7` `8` `9` `10` | `3` |
| `SUPERPOWERS_BATCH_TASK_CAP` | `batch-task-cap` | `1` `2` `3` `4` `5` | `3` |

**`0` is deliberately not an accepted value for `SUPERPOWERS_REVIEW_ROUNDS`.**
N = 0 skips a review loop entirely. An environment variable set once and then
forgotten would silently disable spec review, plan review and whole-branch code
review on every future session, with no message anywhere — the pipeline's main
safety property turned off by a value nobody sees. N = 0 stays available where
the user states it and sees its consequence: in an invocation, and as an option
at every gate question. `SUPERPOWERS_REVIEW_ROUNDS=0` is invalid and falls back
to 3, like any other unlisted value.

**Surviving convention.** The legacy review-log rule — an invocation line
carrying no `M=` token is read as M = 1, "not defaulted to `<d>`"
(`skills/brainstorming/SKILL.md:78-82`,
`skills/writing-plans/SKILL.md:363-366`) — is unchanged by this design. Under
the rename it reads "not defaulted to `<d-m>`". It is a rule about reading an
old log line, not about resolving a default.

### What each range constrains

The block column above constrains the environment variable and the block line.
Tier 1 — a value stated in an invocation or typed as an answer — has its own
validity per parameter and per entry point:

| Parameter | Entry point | Valid at tier 1 | Invalid value |
|---|---|---|---|
| N | invocation or gate question | integer 0–10 | falls to the parameter's default |
| N | orchestration Phase 0 (`N_plan`, `N_code`) | integer 0–10 | falls to the offered default |
| M | invocation or gate question | integer 1–5 | falls to the parameter's default |
| batch cap | orchestration Phase 0 | integer 1–5 | falls to the offered default, as `skills/orchestrating-development/SKILL.md:240` already says ("Invalid → default") |
| batch cap | a task count X stated to `subagent-driven-development` | any integer ≥ 1 | X = 0 is an explicit stop, never a fallback; any other invalid value falls to tier 2 |

The two batch-cap rows differ on purpose, and this is the one place where the
same parameter carries two validity sets. Phase 0's question is preserved
verbatim, and it already bounds its answer to 1–5. A task count the user states
in a phrase ("implement the next 8 tasks") is not bounded today and is not
bounded by this design: X is never clamped to 5.

### Validation in the hook

Validation lives in `hooks/session-start`, in a `case` statement with **literal
alternatives**, one per accepted value:

```sh
case "${SUPERPOWERS_REVIEW_ROUNDS:-}" in
  1|2|3|4|5|6|7|8|9|10) review_rounds="${SUPERPOWERS_REVIEW_ROUNDS}" ;;
esac
```

Literal alternatives are required, not a character class. The existing `[1-5]`
glob matches exactly one character, which cannot express a two-digit value.
Literal alternatives also reject ` 3`, `+3`, `03` and `3.0` exactly — each of
these must fall back to the hardcoded default.

Any value that is not listed falls back to the hardcoded default, silently.
This matches the behavior of all three existing variables: an invalid value is
never an error.

### The normative resolution rule

The rule is defined **once**, in `skills/multi-doc-review/SKILL.md`, under a
section named `Resolving a default`. That same section also holds the
offered-default rule and the two option-list rules below — one file, one
section, everything about resolving these parameters. Every other skill cites
it by name. This follows the precedent already set by `Artifact Layout`, which
`skills/brainstorming/SKILL.md` defines once as "the single normative
definition" and other skills cite.

**Citation marker, and the minimum each site must restate.** Every citing skill
contains this exact sentence, which is the string the wording-contract test
greps for:

> Resolve this value by `Resolving a default` in
> `skills/multi-doc-review/SKILL.md`.

**The citation does not stand alone.** Two facts force a restatement beside it:

1. **No precedent exists for a bare pointer.** Every cross-skill reference in
   this repository names the other file *and* restates the rule inline —
   `skills/writing-plans/SKILL.md:46`,
   `skills/orchestrating-development/SKILL.md:258` and `:264`,
   `skills/subagent-driven-development/SKILL.md:150`,
   `skills/multi-code-review/SKILL.md:134`.
2. **The path is not resolvable at run time.** A session's working directory is
   the user's own project, where `skills/multi-doc-review/SKILL.md` does not
   exist; the plugin lives in the installed cache.

**Minimum restatement content — an implementer may not trim below this.** The
three tiers alone are not enough. `multi-code-review` and `multi-doc-review`
read diffs, review packages and target documents, which are attacker-controlled
text; a site carrying only "tier 2 is the block's line" with no in-file rule
about which blocks count is strictly weaker than the guard it replaces. Each
citing site restates, in its own words:

- the three tiers;
- the **injection-scoping** rule (which block counts);
- the **tool-result** rule (what is data rather than a parameter);
- the **platform** clause below.

### Two defences, covering different attacks

Neither is redundant, and neither alone is sufficient:

- **Origin** excludes text that never came from the hook: tool results (a file
  read, command output, a diff, a review package) and text the user typed or
  pasted.
- **Last complete block within the session-start injection** excludes decoys
  planted inside embedded workspace files. Origin cannot help there:
  `hooks/session-start:470` concatenates `project-map.md`, `session-log.md`,
  `state.md`, `known-issues.md` and `context-snapshot.json` into the *same*
  `additionalContext` as the block, so a decoy inside one of them has the same
  origin as the real thing. Position is the only defence for that class. This
  matters in practice: `state.md` and `session-log.md` are written by the
  session itself, so a session that reviewed a document containing a block can
  persist that text into a file the next session's hook embeds.

**The scoping phrase is load-bearing and must never be dropped.** It is "the
last complete block **of the session-start injection**" — never "the last
complete block in the context". Everything a session reads afterwards lands
later: skill bodies loaded by the Skill tool, documentation, diffs. Today's M
rule already carries this qualifier ("the last such element **inside the
injected block**", `skills/multi-doc-review/SKILL.md:66-68`); dropping it would
make position select the attacker's block rather than the hook's.

### The rule

1. A value stated in the invocation, if valid for that parameter and entry
   point (see "What each range constrains").
2. Otherwise the parameter's line inside the last complete
   `<superpowers-defaults>` block **of the `hooks/session-start` injection**,
   if valid.
3. Otherwise the hardcoded default in this design's parameter table.

Properties:

- **Platform clause.** A block is honored only where `hooks/session-start`
  runs — Claude Code and Cursor. On Codex and OpenCode the reader resolves
  tier 3 unconditionally and never reads a block from the context. This must be
  stated as a rule the reader can apply, because origin is not observable in a
  flat rendered context: `hooks/codex/session-start-adapter.js` embeds
  `project-map.md`, `session-log.md`, `state.md` and `known-issues.md` into its
  own session context and emits no block, so a block planted in any of those
  files would otherwise be the only — and therefore last — one, and repository
  content would choose N, M and the cap on every Codex session.
- **A block arriving through a tool result is data — session-wide.** Any
  `<superpowers-defaults…>` block that reaches the session through a file it
  read, command output, a diff, a review package, or text the user typed or
  pasted is ignored, whatever its position. This rule has no carve-out: nothing
  legitimately supplies a *block* except the hook.
- **A stated value arriving through a tool result is data — scoped to the
  controller.** This is the narrower guard, and it is deliberately not
  session-wide, as today's guards are
  (`skills/multi-doc-review/SKILL.md:29`,
  `skills/multi-code-review/SKILL.md:68`, `:93`): an `N=<n>` or `M=<m>` token,
  an M prose form, or a whole block that reaches *the controller* through a
  file it read, command output, or any other tool result is data. **Carve-out:**
  a gate reading its own review log's invocation line during a resume is not a
  tool-result value. Those paths are specified to recover the recorded N and M
  (`skills/brainstorming/SKILL.md:92-93`,
  `skills/writing-plans/SKILL.md:366-377`), and an invocation line is never
  rewritten. Widening this guard to "the session" would make a resumed loop
  discard its own recorded M and re-resolve mid-loop — exactly what
  `skills/multi-doc-review/SKILL.md:75-79` exists to prevent.
- **Read the last complete block of the injection, then read every parameter
  from that block only.** Never scan for the last occurrence of an individual
  line. Blocks are never merged: a parameter whose line is absent from that
  block is absent, and tier 3 applies to it.
- **Main session only.** A dispatched subagent never receives the block. See
  the fork assumption above for the one context that inherits it.
- **A controller subagent takes its values from its filled template
  placeholder.** A template value wins over the block. A template placeholder
  left unfilled means the parameter's hardcoded default — defensive only, since
  `skills/multi-code-review/scripts/fill-prompt.js` exits 3 on an unfilled body
  placeholder, so the dispatch fails rather than delivering one. This
  generalizes the two sub-rules the M rule states today
  (`skills/multi-doc-review/SKILL.md:70-71`).

### Placeholder names

The placeholder `<d>`, which today means "the default for M", is replaced by
three named placeholders: `<d-m>`, `<d-n>` and `<d-cap>`. The bare `<d>` is
removed from every skill.

**Mapping rule for the rename: all 34 `<d>` occurrences become `<d-m>`.** The
rename is mechanical, not a judgement call — `<d>` means "the default for M"
everywhere it appears today, and N and the cap state their defaults as the
literal `3`. `<d-n>` and `<d-cap>` are therefore *introduced* at new sites, not
converted from `<d>`; those sites are the third inventory table below.

**One `review-rounds` value serves both round counts.** Orchestration Phase 0
asks two independent counts, `N_plan` and `N_code`, each with default 3
(`skills/orchestrating-development/SKILL.md:232-233`). The single
`review-rounds` line supplies the offered default for both, and `<d-n>` appears
twice in that question batch. Phase 0's wording says so explicitly, in the same
way it already says "one M applies to Phase 2 and Phase 4". The user may still
answer the two questions differently.

### The offered-default rule

This rule lives in the same `Resolving a default` section.

Where a skill offers a value in a question, the offered value is **the value
resolved by `Resolving a default`** — not "the block value", which does not
exist on Codex or when a line is absent. It is presented first and labelled:

- **current default** when it equals the hardcoded default;
- **recommended** when it is *stronger* than the hardcoded default — more
  review rounds, more reviewers;
- **session default** when it is *weaker* than the hardcoded default.

The three-way split matters because M's environment range can only increase
review strength (2–5 against a default of 1), while `review-rounds` and
`batch-task-cap` can be set below their defaults. Labelling
`SUPERPOWERS_REVIEW_ROUNDS=1` as "1 (**recommended**)" at all three gates would
make a safety gate present one user's stale setting as the project's advice, in
the direction that weakens review.

This is the existing M rule ("**current default** when `<d>` is `1`" and
"**recommended** when `<d>` is `2`–`5`") stated once and applied to all three
parameters.

**Intended wording change.** N's option is labelled "3 (recommended)" in all
three gates today (`skills/brainstorming/SKILL.md:139`,
`skills/writing-plans/SKILL.md:422`,
`skills/subagent-driven-development/SKILL.md:115`). Under the rule above, an
offered N of 3 becomes "3 (**current default**)". This relabelling is intended
and must not be read as an accidental edit when the diff is reviewed.

**N's option list.** N's existing list already holds four entries — `3
(recommended), 2, 4` and a zero option — so "offered value first, then the
existing options" would produce five whenever the offered value is not among
them. The list is therefore built by an explicit rule: take, in order and
skipping any value already held, the offered value, then `3`, then `2`, then
`4`; stop at three values; then append the zero option as the fourth. Zero is
always present and always last. When the offered value is 3 this reproduces
today's list exactly; an offered 5 gives `5, 3, 2, 0`.

Each gate keeps its own zero-option label text. In
`skills/subagent-driven-development/SKILL.md:116` that is
`0 — skip; the branch finishes with no whole-branch review`; the rule pins the
position of the zero option, never its wording.

**M's option list** keeps its current construction — `<d-m>` first, then 1, 2
and 3 with `<d-m>` removed if among them — which never exceeds four.

**Prose questions.** Orchestration Phase 0 asks `N_plan`, `N_code` and the cap
in prose inside one question batch, with no option list. That form is
unchanged: only the offered default becomes `<d-n>` (twice) and `<d-cap>`, each
labelled by the rule above. "Presented first" does not apply to a prose
question.

The existing sentence stating that a round's reviewers run at the same time,
that token cost grows about M times per round, and that the loop runs about
N × M reviewers in total, is kept and uses the offered values.

### Where each parameter is resolved, by execution context

The paths below are grouped by the context they run in, because the context
decides which tier is even reachable. They are not a disjoint checklist — a
single invocation can match more than one description.

**Main session (the block is reachable, tier 2 applies):**

- A direct invocation of `multi-doc-review` or `multi-code-review` with no
  stated count. It still asks its question
  (`skills/multi-doc-review/SKILL.md:36-37`,
  `skills/multi-code-review/SKILL.md:75-76`); the block changes what that
  question offers.
- The spec, plan and whole-branch gates when the user is present. They ask, and
  offer the resolved value.
- `subagent-driven-development` Batched Autonomous Mode, which never asks and
  takes the resolved value silently.
- The two resume-from-review-log paths
  (`skills/brainstorming/SKILL.md:82-94`,
  `skills/writing-plans/SKILL.md:366-377`), which never ask.
- Orchestration Phase 0, which asks and then fills the values into the
  controller templates.

**Controller subagent (the block is NOT reachable, tier 2 never applies):**

- The Phase 2 and Phase 4 review loops. They are dispatched from filled
  templates (`skills/orchestrating-development/SKILL.md:435-439, 554-558`) and
  receive `N` and `M` as template values, exactly as M works today.
- **The Phase 3 batch controller.** `skills/orchestrating-development/SKILL.md:465-500`
  fills `batch-controller-prompt.md` and dispatches it, and that prompt directs
  the subagent to Batched Autonomous Mode (`batch-controller-prompt.md:53`). So
  the same `subagent-driven-development` lines this design edits are also read
  inside a controller. Under orchestration the batch cap is not resolved there
  at all — the batch loop is replaced, as
  `skills/orchestrating-development/SKILL.md:534-536` already states — and N and
  M come from the filled template. The rewrites at
  `subagent-driven-development/SKILL.md:83` and `:299` must be worded so they
  hold in both contexts.

The rule for every dispatched controller, not only these: a controller is never
instructed to read the block. Its value comes from the template, or from the
hardcoded default.

**Origin sentences.** The two resume paths print a sentence naming where each
value came from. N now has three possible origins, so **two** new forms are
needed, each bound to the tier that actually supplied the value:

> Tier 2 — `N=<n>` — the log's invocation line does not record it, so this is
> the session default from the `<superpowers-defaults…>` block.

> Tier 3 — `N=<n>` — the log's invocation line does not record it, so this is
> the default.

The tier-3 form is the sentence that already exists for M
(`skills/brainstorming/SKILL.md:89-90`) and it is retained. Without it, a resume
on Codex or OpenCode — or any session where the `review-rounds` line is
absent — would tell the user the value came from a block that was never
injected, a false statement in the one place added to make origin auditable.

`batch-task-cap` resolves as: the user's explicit task count X when one was
stated and valid, otherwise the block's `batch-task-cap` line, otherwise 3.

**Across a batch boundary.** Batched Autonomous Mode ends every batch with
`/clear` and a resume prompt that today carries only `M=<m>`
(`skills/subagent-driven-development/SKILL.md:290-293`), while `:296-299` says
the default resolution runs again after every resume. Today the values that do
not survive fall to the hardcoded 3; under this design they would fall to tier 2,
so a user who said "implement the next 8 tasks" on a machine with
`SUPERPOWERS_BATCH_TASK_CAP=1` would silently get one-task batches from batch 2
onward. **The resume prompt therefore carries X and N as well as M.** A value
the user stated survives the boundary; it is not re-resolved from the
environment. This also keeps the "Run" definition below honest.

### Edit-site inventory

Two renames run through the skills, and they touch different sets of lines. An
implementation sized from the tag count alone would miss roughly two thirds of
the work.

**Tag string `<reviewers-per-lens>` — 15 occurrences:**

| File | Occurrences |
|---|---|
| `skills/multi-doc-review/SKILL.md` | 2 |
| `skills/multi-code-review/SKILL.md` | 2 |
| `skills/brainstorming/SKILL.md` | 2 |
| `skills/writing-plans/SKILL.md` | 2 |
| `skills/orchestrating-development/SKILL.md` | 2 |
| `skills/subagent-driven-development/SKILL.md` | 5 (lines 83, 100, 102, 147, 299) |

**Placeholder `<d>` — 34 occurrences:**

| File | Occurrences |
|---|---|
| `skills/brainstorming/SKILL.md` | 11 |
| `skills/writing-plans/SKILL.md` | 11 |
| `skills/subagent-driven-development/SKILL.md` | 10 |
| `skills/orchestrating-development/SKILL.md` | 2 |

Sites needing more than a name substitution:

- **`skills/subagent-driven-development/SKILL.md:83`** — the Batched Autonomous
  Mode last-resort sentence inside the step 4 gate. Today it reads that the
  mode's own rule "may still end at the `<reviewers-per-lens>` session tag as
  its own last resort". That tag carries M only, so today N has no session-level
  last resort on this path. Naming the block instead **gives N one**, which is
  the behavior the Batched Autonomous Mode path above asks for. This is an
  intended change, not a preserved meaning: the rewritten sentence states the
  last resort for N and for M, and keeps the part that is preserved — this path
  resolves by its own rule and never enters the gate's default-offering path.
- **`skills/subagent-driven-development/SKILL.md:147`** — a cross-reference
  reading "the same treatment a `<reviewers-per-lens>` element from another
  source gets **above**". Once the local rule above it becomes a citation, the
  word "above" points at nothing. It becomes the citation marker sentence.
- **`skills/subagent-driven-development/SKILL.md:299`** — a second, independent
  last-resort sentence, "…session tag, else 1", inside Batched Autonomous Mode.
  It needs the same treatment as line 83.

**Literal defaults — the sites neither grep finds.** These state N's or the
cap's default as a bare `3`. They are where tier 2 has to be inserted, and where
`<d-n>` and `<d-cap>` are introduced. An implementation working only from the
two greps above would emit a `review-rounds` line that no path ever reads.

| File | Lines | What it states |
|---|---|---|
| `skills/multi-doc-review/SKILL.md` | 36, 37, 38, 549 | N's default and its invalid-value fallback — in the very file the rule lives in |
| `skills/multi-code-review/SKILL.md` | 75, 78, 79, 82, 1693 | N's default, including "Batched Autonomous Mode never asks: default 3" |
| `skills/brainstorming/SKILL.md` | 93, 121 | the resume path's "3 for N", and N's range sentence |
| `skills/writing-plans/SKILL.md` | 377, 405 | the same two |
| `skills/subagent-driven-development/SKILL.md` | 96, 251-253, 286-290, 296 | N's range; the task cap "otherwise **3 tasks**"; the resume-prompt sentence "multi-code-review's default resolution (session tag, else 1) runs again after every resume"; "never ask for N (default 3 …)" |
| `skills/orchestrating-development/SKILL.md` | 232-233, 240 | Phase 0's `N_plan`, `N_code` and cap defaults |

Line 299 of `subagent-driven-development` is listed with the tag sites above,
not here — it does carry the tag string.

## Error handling

The **Verified by** column says how each row is checked. "Hook test" rows are
covered by the hook-level suite; "prose only" rows are contracts carried by
skill Markdown that no automated test can reach, and they are listed here so a
later editor knows they are load-bearing and unguarded.

| Condition | Behavior | Verified by |
|---|---|---|
| Environment variable unset | Hardcoded default; the line is still emitted | Hook test |
| Environment variable holds an unlisted value | Hardcoded default; the line is still emitted; no error | Hook test |
| `SUPERPOWERS_REVIEW_ROUNDS=0` | Unlisted, so 3; N = 0 stays available per invocation and per question | Hook test |
| Block absent from the context | Tier 3 for every parameter | Prose only |
| Block present, one line absent | Tier 3 for that parameter only; blocks are never merged | Prose only |
| Block line present, value invalid | Tier 3 for that parameter only | Prose only |
| Block line malformed (spacing, case, unknown name) | Line ignored; tier 3 for that parameter | Prose only |
| Block line repeated inside one block | The last occurrence in that block wins. Defensive only — the hook cannot emit this, so it is out of test scope | Not tested, by decision |
| Block reached through a tool result, or typed or pasted by the user | Ignored entirely; it is data. Origin decides | Prose only |
| Two blocks in the session-start injection | The last complete one wins | Prose only |
| Context compacted mid-session | `hooks/session-start` is wired to `startup\|clear\|compact` (`hooks/hooks.json:5`, `hooks/hooks-cursor.json:6`), so the hook re-runs on a compact and the block is injected again, carrying the same environment values. A value already resolved in the current run is kept regardless | Hook wiring; the keep-the-value part is prose only |

**"Run"** means one skill invocation, from the invocation that resolved a value
to that invocation's completion message. An orchestration pipeline is not one
run: each controller receives its values through its template, so a pipeline
never re-resolves a parameter mid-flight.

No condition produces an error message or stops a run.

**Every path that resolves a parameter at tier 2 without asking must echo the
resolved value and its source**, in its opening or completion message. This
extends the note the two review skills already write for a substituted M, and it
is required, not optional. The reason is symmetry with the `0` ban above: that
rule exists because a variable "set once and then forgotten" changes behaviour
with no message anywhere. The same argument applies at the other end.
`SUPERPOWERS_REVIEW_ROUNDS=10` with `SUPERPOWERS_REVIEWERS_PER_LENS=5` takes an
unattended gate from about 15 reviewer subagents to about 50, across three
gates; `SUPERPOWERS_BATCH_TASK_CAP` set low silently shrinks every autonomous
batch. Banning one end while leaving the other silent would apply the threat
model to a single value and ignore its neighbours. An echo costs one line and
makes a forgotten setting visible the first time it acts.

## Testing strategy

Hook-level, in `tests/codex/`:

- Replace `tests/codex/test-session-start-reviewers-tag.sh` with a test for
  the whole block.
- **Accepted values, per parameter:** `1`–`5` for `reviewers-per-lens` and
  `batch-task-cap`; `1`–`10` for `review-rounds`. Each passes through
  unchanged.
- **Rejected forms, shared by all three parameters:** ` 3`, `+3`, `03`, `3.0`,
  `-1`, a word, empty.
- **Rejected values, per parameter:** `0`, `6` and `11` for
  `reviewers-per-lens` and `batch-task-cap`; `0` and `11` for `review-rounds`.
  `6` through `10` are accepted for `review-rounds` and must not appear in its
  rejected set — that range is the capability this design adds.
- Assert the block is emitted with every parameter when no variable is set.
- Assert the block is the last element of `session_context`, after every
  embedded workspace file. **Keep both decoy cases the current test already
  has.** `tests/codex/test-session-start-reviewers-tag.sh:96-145` writes a decoy
  `state.md` and runs two assertions — the variable *unset* (the attack case,
  where the fallback emission is what defeats the decoy) and the variable *set*.
  Carrying only one of them would drop the coverage that exists today. Two
  further requirements, because this assertion can pass without testing
  anything: the decoy fixture must stay under the 200-line embedding threshold
  (`hooks/session-start:262-282` embeds `project-map.md` in full only below it,
  and extracts Critical Constraints and Hot Files above it), or place the decoy
  inside an extracted section; and the test must assert the decoy text is
  actually present in the decoded context *before* asserting the hook's block
  comes after it.
- Assert the exact emitted string, including the two leading newlines and the
  line order.
- Update `tests/codex/run-unit-tests.sh` where it names the replaced test file.

Wording contracts, in `tests/review-gates/run-tests.sh`:

- **Remove the existing anti-drift block.** `D_MARKER` (line 175) pins the
  literal string ``the value of the `<reviewers-per-lens>` tag emitted by``,
  line 334 asserts each of four gate skills "carries the `<d>` marker exactly
  once", span extraction ends at line 347, and the identity loop at lines
  348-351 asserts the four extracted spans are equal. All of it contradicts
  this design and cannot be left in place.
- **Replace it.** The duplicated span is gone by construction, because the rule
  now lives in one file. The new marker is the citation sentence given under
  "The normative resolution rule", grepped as a literal string. Assertions:
  `skills/multi-doc-review/SKILL.md` contains the `Resolving a default` section
  exactly once; each citing skill contains the citation marker **at least
  once** — that is the asserted contract. Per-file counts are predictions about
  an edit not yet made, so they are recorded after implementation, never
  asserted: a test pinned to an exact count fails for a wording reason and
  invites editing the skill to satisfy the number. Finally, no skill contains
  the bare `<d>` placeholder or the string `<reviewers-per-lens>`. **The `<d>`
  assertion must be case-sensitive:** `<D>` is a live, unrelated Artifact Layout
  placeholder in three skills, and a case-insensitive match would fail
  permanently.

Comparison rule, applied to the citation marker: compare it after collapsing
every whitespace run to one space. Byte equality cannot be used — the same
sentence is wrapped differently in each skill file.

Behavioral, in `tests/claude-code/`. No test file *sets*
`SUPERPOWERS_REVIEWERS_PER_LENS` or asserts the session tag, so there is no
such code to update. The work is exactly two edits: generalize the two `unset`
lines (`test-multi-code-review.sh:76`, `test-multi-doc-review.sh:51`) to the
three variable names; three files also carry comments naming the tag
(`test-multi-code-review.sh:15,69`, `test-multi-doc-review.sh:22,44,179`,
`test-helpers.sh:196,213,259`) which read false once it is removed and are
updated with the code; and generalize the ambient-environment guard
`check_no_reviewers_per_lens_setting`
(`tests/claude-code/test-helpers.sh:211`) to all three variable names — it
exists because Claude Code's `settings.json` `env` block survives a shell-level
`unset`, and without it any assertion about the block's contents is
untrustworthy on a machine where one of the new variables is set. Generalize
the `unset` lines in the two test scripts the same way.

## Rollout and migration notes

`hooks/session-start` and the skills ship inside one plugin version directory,
so there is no version skew between them on disk. The `<reviewers-per-lens>`
tag is removed in the same release that adds the block; no dual emission and no
later cleanup task.

One window remains and is accepted as a limitation, stated without a mechanism
claim: **after updating the plugin, restart the CLI before running a review.**
A session that spans the update may combine old and new state. The observable
consequence covers all three parameters and runs in both directions: an
injection made before the update carries the old tag and no block, so
`review-rounds` and `batch-task-cap` fall to tier 3 — a user with
`SUPERPOWERS_REVIEW_ROUNDS=8` silently gets 3 — and M falls back to 1. No
message is written in any of these cases. `README.md` already tells
users a changed value takes effect after a restart, so this adds no new
instruction.

The earlier draft explained this window by saying the injected block is fixed at
session start. That explanation was wrong and is removed: `hooks/session-start`
runs on `startup|clear|compact` (`hooks/hooks.json:5`), so the block is
re-injected on a compact or a clear. How skill files themselves are loaded within
a session has not been probed, and this design no longer depends on it.

Users who set `SUPERPOWERS_REVIEWERS_PER_LENS` need to do nothing: the variable
name is unchanged, only the tag that carries it into the session changes.

### Documentation

`README.md`'s "Environment variables" section becomes the canonical block.
Every variable is listed with the same six fields: name, meaning, accepted
range, default, how an invocation value overrides it, and where it is honored.

- The **override** field reads the literal text "not overridable in an
  invocation" for the three hook-internal variables, which have no invocation
  path at all.
- The **where it is honored** field is required, not optional: the current
  entry ends with "Honored on Claude Code; not verified on Cursor or Codex"
  (`README.md:379`), which is true and must not be dropped. It gains OpenCode
  alongside Codex as a platform where no block is emitted.
- **`SP_NO_COMPRESS` is an addition to this section, not a reformat.** The
  section (`README.md:375-381`) lists only three variables today;
  `SP_NO_COMPRESS` is documented elsewhere, at `README.md:394` inside the
  bash-compress-hook bullet. It gains a full entry here, and the mention at
  line 394 stays as a cross-reference rather than a second definition.

`docs/guide/README.md` needs edits at sites that mostly do **not** name the
variable, and it names the tag nowhere:

- `:173-177` — the existing description of `SUPERPOWERS_REVIEWERS_PER_LENS`.
- `:516-520` — the Phase 0 question table. Its `N_plan`, `N_code` and batch-cap
  rows give a bare default of `3` with no environment source, while the `M` row
  already reads "1, or the value of `SUPERPOWERS_REVIEWERS_PER_LENS`". Those
  three rows become wrong the moment the block ships.
- `:885-896` — the settings section, written for M alone. It gains
  `SUPERPOWERS_REVIEW_ROUNDS` and `SUPERPOWERS_BATCH_TASK_CAP`.

`CLAUDE.md` records that the guide is not auto-synced with releases, so nothing
else will catch these.

`docs/FORK-IMPROVEMENTS.md:133` and `:176` both name "`hooks/session-start`
(the `<reviewers-per-lens>` session tag, v7.4.0)" and the test file this design
replaces, in per-feature file inventories. Both are updated. Historical
`RELEASE-NOTES.md` entries are left unchanged — they record what was true at
the time.

The release entry in `RELEASE-NOTES.md` carries the three-line
Problem/Change/Effect summary and states that nothing needs migrating.
