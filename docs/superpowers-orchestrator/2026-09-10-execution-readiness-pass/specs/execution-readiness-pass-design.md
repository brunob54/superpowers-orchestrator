# Execution readiness pass for the plan review gate

**Date:** 2026-09-10
**Status:** approved design, spec review complete (4 rounds, 3 reviewers each)
**Target version:** 7.14.0

## Problem

The Pre-Flight Plan Review of `skills/subagent-driven-development/SKILL.md`
(section "Pre-Flight Plan Review") is a read of the whole plan by the batch
controller, done before Task 1 is dispatched. It looks for two things: tasks
that contradict each other or the plan's Global Constraints, and anything the
plan explicitly mandates that the review rubric treats as a defect. In an
orchestrated run, every conflict it finds is returned as `BLOCKED task=<n>`,
ruled on by the orchestrator, and the batch is dispatched again.

The run of 2026-09-09 (topic `superpowers-defaults-block`) shows the cost of
finding these conflicts that late. The plan had passed four review rounds
with four reviewers each, which applied 74 findings. The pre-flight then
blocked three times before Task 1 started, carrying six conflicts. About
48 minutes passed between the commit of the Phase 2 log (`1474b60`, 19:43)
and Task 1's first commit (`5a47d9c`, 20:31), all of it pre-flight blocks,
rulings and re-dispatches. Analysis of the six conflicts (see "Evidence"):

- all six were findable from the plan and the spec alone;
- four of the six were single checks against one Global Constraint;
- two of the six were created by the plan review loop itself, when a round
  applied a finding that made one task inconsistent with another.

The plan lenses of `skills/multi-doc-review/SKILL.md` do not run these
checks as a sweep, and no lens runs after the last merge. So a plan can leave
the review gate carrying conflicts the gate's own merges introduced.

## Goal

Run the pre-flight criteria, extended by three checks the evidence supports,
as reviewer passes inside the plan review gate: once before the rotating
rounds and once after them, each repeated until a pass changes nothing. The
SDD Pre-Flight Plan Review stays unchanged as the net for what the reviewers
miss.

## Scope and non-goals

In scope:

- a new lens cell, "Execution readiness", in `skills/multi-doc-review/SKILL.md`;
- a new procedure stage, the readiness sequence, run before round 1 and
  after the last rotating round, for plan documents only;
- a review log entry shape for a readiness pass, with its own heading, and
  the completeness and resume rules that read it;
- a conflict-verification step and an authority order for disposing of a
  two-sided conflict at triage, plus an `Owed:` block in the review log and
  an owed line in the completion report;
- one added sentence and one added cost clause at the two plan gates;
- in `skills/orchestrating-development/`: Phase 2 dispatches the plan
  review controller for `N_plan = 0` as for any other N, the controller
  template `doc-review-loop-prompt.md` accepts `N_PLAN = 0`, and its
  Deviations 1 and 2 follow the new order and the new completeness rule;
- the contract tests, guide sections, and release files this touches.

Non-goals:

- No change to `skills/subagent-driven-development/SKILL.md`, to
  `skills/orchestrating-development/batch-controller-prompt.md`, or to the
  Phase 3 pre-flight behaviour. The pre-flight remains the net.
- No change to the fenced prompt of `skills/multi-doc-review/reviewer-prompt.md`.
  The pass uses the existing placeholders. Only two lines outside the fence
  change (see "Files touched").
- No change to Deviation 3 of `doc-review-loop-prompt.md` and no change to
  the meaning of `unresolved`. A readiness finding never produces an
  `unresolved:` line (see "Triage").
- No readiness pass for `spec` or `general` documents.
- No new key in the `<superpowers-defaults>` block and no environment
  variable. The pass cap is a constant of the skill, and there is no switch
  that turns the sequence off (Accepted limitations, item 6).
- No new token in the `REVIEW_DONE` return contract.
- No repository-premise test (row 8 of the orchestration issues worklist).
  It is the same family of check but widens the change; it stays open.
- No edit to `docs/orchestration-issues.md`. The file is local and
  untracked; the maintainer should note the new cost term in its row 14.
- No behavioural test suite run. Acceptance is measured on the next
  orchestration run of this repository (see "Testing strategy").

No decision in this design matched the prior-art trigger predicate.

## Definitions

- **Rotating round:** one of the N rounds that the existing Lens Rotation
  table governs. Unchanged by this design.
- **Readiness pass:** one review dispatched under the lens "Execution
  readiness": M reviewers filled from `reviewer-prompt.md`, the same
  consolidation and triage as a round, one entry in the review log under
  its own heading.
- **Settled pass:** a readiness pass that **applied** no Critical and no
  Important finding, and for which all M reviewers returned a usable report.
  A pass that applied nothing left the text unchanged, so a further pass
  over that text would report the same thing; that is why it ends the
  sequence. A pass with fewer than M usable reports, and an inconclusive
  pass, are never settled.
- **Open pass:** any readiness pass that is not settled.
- **Readiness sequence:** at most three passes over the same document. The
  sequence ends at the first settled pass, or when it reaches its cap,
  whichever comes first. The cap is three, and one when the plan has no
  locatable spec (see "Missing plan structures").
- **Pre-sequence:** the readiness sequence run before rotating round 1.
- **Post-sequence:** the readiness sequence run after the last rotating
  round.
- **Site:** any task step, mandated body, verification line or header field
  of the plan whose text a Global Constraints entry constrains.
- **Fixed text:** plan text this triage never amends, because its authority
  comes from outside the plan (see "Triage").

The settled rule replaces an earlier "clean pass" rule that keyed on zero
Critical and Important findings of any disposition. Under that rule one
recurring rejection made every pass of every sequence not clean, so the
sequence always ran to its cap and always ended on an unreviewed merge,
which is the defect this design exists to remove.

## Architecture

### Where the sequences run

For a plan document, the procedure of `skills/multi-doc-review/SKILL.md`
becomes:

1. Invocation note (unchanged).
2. **Pre-sequence.** Runs on the plan as `writing-plans` saved it.
3. **Rotating rounds 1..N** (unchanged, including lens selection and the
   early-exit rule).
4. **Post-sequence.** Runs when N is at least 1, over the plan as it stands
   after the last rotating round's triage.
5. **Host self-review** (the existing "After the loop" step: the host
   skill's checklist, merge-introduced issues fixed inline and noted in the
   log). It stays last, as today, so that the checklist sees every merge the
   rotating rounds and the post-sequence made. It writes the marker line
   `**Host self-review:** done` into the log when it finishes.
6. Outcome report (see "Completion report").

With N = 0 the rotating loop is skipped and its `skipped` line is logged as
today; the pre-sequence runs, then step 5, then step 6. Step 4 does not run.

Something has to be the last edit inside the gate. It is the host
self-review, as it is today: a checklist-bounded read-and-fix pass, whose
blast radius is smaller than a findings merge. The evidence names findings
merges, not checklist fixes, as the source of loop-introduced conflicts (two
of six). Accepted limitation 2 records this.

A fresh invocation always runs the full procedure above, including a re-run
started by the `another pass requested` marker.

For `spec` and `general` documents, neither sequence runs and the procedure
is unchanged.

### What the sequences do not touch

The skill states this as one sentence, pinned by the contract test:
`Readiness passes are not counted in N and are not part of the
two-consecutive-clean-rounds streak.`

- A pre-sequence that applies findings does not break or start a streak; the
  streak is computed over rotating rounds only.
- Lens selection for rotating rounds uses the per-invocation rotating round
  index, as today. Readiness entries carry their own heading and are never
  counted as rounds.
- A third pass that is still open ends the sequence and is recorded in the
  log. It does not change `outcome`, contributes nothing to `unresolved`,
  and stops nothing.

### Reviewer prompt and the copied wording

A readiness reviewer receives `reviewer-prompt.md` filled with
`[LENS_NAME]` = `Execution readiness`, `[LENS_INSTRUCTIONS]` = the plan cell
below, `[ROUND]` = a display label of the form `readiness <pre|post> <p>`,
and the same document, doc type and spec placeholders as a rotating round.
The fenced prompt's rules are unchanged: the reviewer may not use the Skill
tool, read a `*-review-log.md` file, read sibling documents under `specs/`
or `plans/`, or inspect the target's git history; it may read the spec and
the rest of the repository, skill files included.

The rubric wording is copied into the cell rather than referenced by file
path because `[LENS_INSTRUCTIONS]` is filled verbatim and must be
self-contained. The copy is pinned to its sources by a contract test.

### Cost bound

Counting dispatches without retries (the existing one-retry-per-unusable-
report rule can double any pass): each sequence dispatches between 1 × M and
3 × M reviewers. With N ≥ 1 both sequences together add between 2 × M and
6 × M dispatches on top of N × M; with N = 0 the pre-sequence alone costs
between 1 × M and 3 × M. Under the settled rule a plan with no conflict
costs one pass per sequence, which is the expected case. On a platform
without parallel dispatch the reviewers of a pass run one after another, so
the added wall-clock time grows with M; the gate's cost clause says so.

The guide has no cost section today; it gains one sentence naming this term
in its plan-stage section, after the sentence that describes the N and M
questions.

**Size budget.** `skills/multi-doc-review/SKILL.md` is read whole by the
Phase 2 controller and by the writing-plans host session. This design's
additions to that file are capped at 150 lines; the file is 788 lines at the
time of writing, so the contract test asserts a maximum of 938 lines and
names 7.14.0 as the release that set the figure.

## The lens cell

Added to the "Lens Instructions" section of `skills/multi-doc-review/SKILL.md`,
after the "Adversarial failure modes" cell and before "Review Log Format".
The `plan:` text is copied verbatim into `[LENS_INSTRUCTIONS]`. The five
checks are numbered so that none is silently dropped.

```markdown
**Execution readiness**
- plan: Read the plan as the agent that will execute it, task by task, and
  report every conflict that would stop execution. Quote both sides of each
  conflict verbatim. Run all five checks:
  (1) tasks that contradict each other or the plan's Global Constraints;
  (2) anything the plan explicitly mandates that the review rubric treats as
  a defect (a test that asserts nothing, verbatim duplication of a logic
  block);
  (3) a task clause that contradicts the spec section it traces to (read the
  spec listed under Target; the section is the one whose text the clause
  restates or implements, found from the task's stated purpose);
  (4) a mandated body — an `**Exact content:**` block, or a sentence a task
  orders written verbatim — that violates an invariant of its own task's
  `**Contract:**` field; a fenced code block or block-quoted wording in a
  task step is a reference implementation, not a mandated body, and is not
  reported under this check;
  (5) for each entry of the plan's `**Global Constraints:**` block, every
  site the entry binds — a site is any task step, mandated body,
  verification line or header field whose text the entry constrains.
  For check (5) report ONE finding per Global Constraints entry, listing
  every failing site inside it, never one finding per site. End your report
  with a coverage block, one line per entry, in this shape:
  `coverage: GC<k> — <n> sites checked`. A report without a coverage line
  for every entry is incomplete and will be discarded.
  Coverage, ambiguity, feasibility and style belong to the other lenses; do
  not report them here.
- spec: not used — the Execution readiness pass runs for plan documents only.
- general: not used — the Execution readiness pass runs for plan documents only.
```

Two strings in this cell are copies of existing wording, pinned by a
contract test:

- `tasks that contradict each other or the plan's Global Constraints` —
  from the Pre-Flight Plan Review of
  `skills/subagent-driven-development/SKILL.md`;
- `(a test that asserts nothing, verbatim duplication of a logic block)` —
  the parenthetical shared by that section and by the Calibration section of
  `skills/subagent-driven-development/task-reviewer-prompt.md`.

Severity follows the reviewer prompt's Calibration: a contradiction is
Important, and Critical when acting on the plan as written would produce
wrong results for a core scenario.

### Coverage makes a pass usable

The sweep is the largest check and the one whose absence is invisible: a
reviewer that enumerates nothing returns zero findings, which is
indistinguishable from a plan with no conflict and would end the sequence at
pass 1. So the coverage block is a usability condition, not a courtesy. A
readiness report that lacks a `coverage:` line for any entry of the plan's
Global Constraints block is **unusable**: it is retried once under the
existing rule, and if the retry is also unusable that reviewer counts as
unusable, the pass has fewer than M usable reports, and the pass is
therefore open. A missing sweep costs a retry; it can never end a sequence.

### Missing plan structures

Three fallbacks, all of the same shape: the clause is removed from
`[LENS_INSTRUCTIONS]` and every readiness entry of that invocation carries a
header note directly after its `**Result:**` line.

| Missing | Clause removed | Note line |
|---|---|---|
| no locatable spec | check (3) | `**Note:** clause-vs-spec check not run — no locatable spec` |
| no `**Global Constraints:**` block | check (5) and its coverage block | `**Note:** Global Constraints sweep not run — no block` |
| no task carries `**Contract:**` | check (4) | `**Note:** Contract check not run — no Contract fields` |

The note is a header line, not a disposition line, so the existing one-line
rule for a settled pass is unchanged.

With no locatable spec the authority order below loses its top level, so
most same-level conflicts become undecidable and the sequence would spend
its cap for little gain. Therefore: **when the plan has no locatable spec,
each sequence runs at most one pass.** The pass still reports and still
applies what the Global Constraints block decides.

## Triage of a readiness finding

### Step 0 — verify the conflict

Before any disposition, quote both sides from their files. If either side is
not found verbatim, or the higher side does not state what the finding
claims, dispose `rejected: not a conflict — <side not found>`. A readiness
finding causes a mandatory edit to a plan that already passed N × M review
rounds, so an unverified claim must never reach the authority order.

### Step 1 — the authority order

Two levels only.

**Fixed text — never amended by this triage:**

- the spec named on the plan's `**Spec:**` line;
- a `**Global Constraints:**` entry that traces to that spec (the entries
  are copied verbatim from the spec; an entry is not fixed only when it
  fails the two-part self-pin test of the writing-plans Self-Review, namely
  it does not trace to the spec **and** it restates the body of an artifact
  the plan itself creates or modifies);
- an `**Exact content:**` body whose reason names a pin outside the plan,
  such as a string an existing test asserts;
- a `**Contract:**` invariant that restates an external standard.

**Plan text — amendable:** everything else, including task steps, mandated
bodies pinned only inside the plan, and a Global Constraints entry that
fails the two-part test.

### Step 2 — disposition

| Conflict | Disposition |
|---|---|
| fixed text vs plan text | amend the plan side, `applied` |
| plan text vs plan text | amend the side the spec decides against; failing that, the side the Global Constraints block decides against; failing both, `rejected: undecidable at this gate — <both sides>` |
| fixed text vs fixed text (the spec contradicts itself, or a finding reverses an amendment made earlier in the same sequence) | `rejected: undecidable at this gate — spec inconsistent` |
| the plan mandates a rubric defect (check 2) | `rejected: plan-mandated — <text>`, never amended |

The rubric row keeps the rule of the two files this design copies from: the
task-reviewer prompt says a plan-mandated defect is reported, labelled
plan-mandated, and "the plan's authorship does not grade its own work; the
human decides"; the SDD pre-flight puts it to the user asking which governs.
Amending it out of the plan would delete the mandate and with it the Phase 3
reviewer's ability to report it, removing that human checkpoint instead of
moving it earlier.

Every `rejected:` disposition above is a rejection with a reason, which the
existing triage rule allows, and each is listed in the `Owed:` block.

### Step 3 — `unresolved` is untouched

**A readiness finding never produces an `unresolved:` line, in any caller.**
Deviation 3 of `doc-review-loop-prompt.md` is unchanged and its meaning is
unchanged; a readiness finding whose application fails is disposed
`rejected: undecidable at this gate` instead. A Phase 2 `unresolved` stop is
a major-error stop outside the in-run rulings, with no resume channel, while
a Pre-Flight Plan Review conflict at Phase 3 is inside the in-run rulings:
the orchestrator decides it and re-dispatches without a human, which is how
all three pre-flight blocks of 2026-09-09 were settled. Routing a readiness
conflict into `unresolved` would therefore create a human stop where the
pipeline is autonomous today.

## Interfaces and contracts

### Review log entry

A readiness pass is written under its own heading, never `## Round`:

```
## Readiness <pre|post> <p> — Execution readiness — <model>
**Result:** <settled|open>
```

`open` after an all-inconclusive pass is written `open (all inconclusive)`.
The rest of the entry is the existing round-entry body: the `**Reviewers:**`,
`**Reviewer verdicts:**` and `**Sources mapped:**` lines under the same
rules, `**Reviewer verdict:**` with the consolidated counts, then
`### Dispositions`. A settled pass with an empty consolidated set writes the
one disposition line `- none — no material issues under this lens`. There is
no `**Converged:**` line: convergence is a property of the rotating loop.

The distinct heading is what makes the mixed-version case safe. Review logs
are committed, and a session running an installed copy older than 7.14.0
counts every `## Round` heading toward `r`. Had readiness passes used
`## Round`, such a session would read a log with three pre-sequence entries
and one rotating entry as `r = 4`, call an interrupted `N = 4` entry
complete, and skip three rotating rounds silently. With the separate
heading the old reader sees fewer rounds, not more, so it re-reviews rather
than under-reviews.

After the host self-review finishes, the controller appends
`**Host self-review:** done` as its own line in the invocation entry.

Layout of an N = 0 entry for a plan: the invocation line, the one-line
`skipped` entry, the readiness entries of the pre-sequence, then the
self-review marker.

An `Owed:` block is appended to the invocation entry when the invocation
ends with any `rejected: undecidable at this gate`, `rejected:
plan-mandated` or `rejected: not a conflict` disposition — one item per
distinct conflict, naming both sides. This block, not the controller's
return message, is the durable record.

### Fields the controller reads

The once-per-gate check reads the recorded N, M, invoker, the `## Round`
headers, and the `**Converged:** yes` line, as today. This design adds two
readable fields, under the existing recognition conditions (at the start of
a line of an entry, not inside a fenced code block, never as a substring of
a disposition line): the `## Readiness <pre|post> <p>` heading and its
`**Result:**` line, and the `**Host self-review:** done` line. Every other
character stays data.

`r` counts `## Round` headings only; no classification by lens name is
needed. A readiness entry's sequence and pass number come from its heading,
and where a heading disagrees with the entry's position among the `## Round`
headings, position governs and the controller rewrites the heading. A
readiness entry that a later resume made obsolete (a post-sequence restarted
because an N override extended the rotating loop) keeps its text and gains
` — superseded` at the end of its heading, so a reader cannot mistake it for
work that governed the final plan.

Only the `**Result:**` value decides whether a sequence has ended, and the
two values `settled` and `open` are compared as whole words. Neither is a
substring of the other, so a partial read cannot turn an open pass into a
settled one.

### Completeness rule

An invocation entry for a plan document **written by this release** (it
holds at least one `## Readiness` heading, or its recorded N is 0) is
complete when:

- its recorded N is 0, its pre-sequence has ended, and the self-review
  marker is present; or
- its rotating rounds are complete under the existing rule, its
  post-sequence has ended, and the self-review marker is present.

A sequence **has ended** when its last pass reads `**Result:** settled`, or
when it holds as many passes as its cap (three; one when the plan has no
locatable spec). Any other state is interrupted.

**Entries from earlier releases.** An entry with no `## Readiness` heading
anywhere and a recorded N of at least 1 was written before this release.
Both of its sequences count as ended, it owes no readiness pass and no
self-review marker, and the existing completeness rule decides it: complete
if its last round carries `**Converged:** yes` or `r` is at least N, and
otherwise interrupted, resuming at rotating index `r + 1`. Without this rule
an upgraded session would find an empty pre-sequence that can never end,
run a pre pass after the rotating entries, and never reach the interrupted
rounds.

**N = 0 plan entries and the gates.** The writing-plans gate never inherits
a recorded `N = 0`: it asks the user for N and invokes the skill with the
answer. So an N = 0 plan entry never blocks or resumes under an invocation
whose N is at least 1; that invocation runs the full procedure. An N = 0
plan entry blocks a later N = 0 invocation only while the plan is unchanged
since that entry was written; when the plan has changed, or when the user
passes the `another pass requested` marker, the later invocation runs. For
`spec` and `general` documents the existing sentence that an N = 0 entry
never blocks a later invocation applies unchanged.

### Resume rule

The controller continues from the first unfinished stage:

1. pre-sequence not ended: run its next pass;
2. rotating rounds not complete: continue at rotating index `r + 1`;
3. post-sequence not ended (N ≥ 1): run its next pass;
4. self-review marker absent: run the host self-review and write the marker.

The M passed to the resuming invocation governs the remaining passes.

### Return contract

`REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>` keeps its
tokens and meanings. `rounds` counts rotating rounds only. For `N_plan = 0`
the controller returns `rounds=0 outcome=cap unresolved=0`. Readiness
results never change `unresolved`.

The orchestration controller's return is capped at 15 lines with at most
three optional notes, so the owed list never travels in it. Under the
orchestration invoker the controller writes at most one note,
`readiness owed: <n>`, and the orchestrator takes no stopping action on it.
The owed items live in the review log's `Owed:` block.

### Completion report

In the in-session gates (writing-plans and direct invocations) the "After
the loop" report gains three items, and a report without them is defective:

- one line per sequence: `Readiness pre: <p> pass(es) — <settled|open after
  3|open after 3 (all inconclusive)>`, and the same for `Readiness post:`,
  or `Readiness post: not run (N=0)`;
- `Readiness conflicts applied: <n>` with one item per applied conflict,
  naming both sides and the side amended, so the gate's single user approval
  can see the edits the triage made;
- `Readiness conflicts owed: <n>` with one item per distinct owed conflict,
  or `Readiness conflicts owed: none`.

An all-inconclusive sequence must be visible as such: it means the reviewers
never ran, not that the plan is conflicted, and the acceptance measure below
must not credit a gate that did not run.

### Gate wording

Two sentences are added at each plan gate:

> For a plan, the Execution readiness pass runs even when N is 0.

> For a plan, add 2 to 6 further passes of M reviewers for the readiness
> sequences (1 to 3 when N is 0); on a platform without parallel dispatch
> the reviewers of a pass run one after another.

Anchors, quoted from the current files:

- `skills/writing-plans/SKILL.md`, plan gate. The first sentence follows the
  sentence that reads, once its line wraps are joined, ``N is the number of
  review rounds (0–10, default `<d-n>`; 0 skips the loop and logs a
  `skipped` entry).`` The second is appended to the cost sentence said with
  the M question, after `…and the loop runs about N × M reviewers in total.`
- `skills/orchestrating-development/SKILL.md`, Phase 0. The `N_plan`
  question is prose with no option list and carries no cost sentence, so
  both sentences are added as one block directly after the sentence that
  begins `N=0 means you skip that phase yourself — no controller
  dispatched;`, which this design narrows to `N_code`.

The spec gate of `skills/brainstorming/SKILL.md` is unchanged.

The N parameter section of `skills/multi-doc-review/SKILL.md` gains, after
``N = 0 skips the loop and logs a `skipped` entry.``:
`For a plan document, the Execution readiness pre-sequence still runs.`

### Orchestrating-development changes

- **Phase 0.** The `N_plan` question carries the two sentences above. The
  sentence `N=0 means you skip that phase yourself — no controller
  dispatched;` and the `skipped (N_plan=0)` log form are narrowed to
  `N_code`, as is the Orchestration Log Format sentence ``Skipped loops
  write the `skipped (N_x=0)` line shapes from Phase 0``. One sentence is
  added there: a `skipped (N_plan=0)` line written by an earlier release
  still means Phase 2 is complete.
- **Phase 2.** `If N_plan = 0, log the skip and go to Phase 3` is removed;
  the controller is dispatched for every N_plan value. The log line keeps
  its shape and reads `## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap
  — unresolved 0` in that case, so a human and the resume step can tell it
  from a controller that produced nothing.
- **`doc-review-loop-prompt.md`.** `[N_PLAN]` accepts an integer 0–10.
  Deviation 1 states: `The host self-review runs after the post-sequence.`
  Deviation 2 defers to the skill's completeness and resume rules, states
  `count rotating entries only`, and writes `_Loop complete — YYYY-MM-DD —
  rounds <r>_` as soon as the skill classifies the entry as complete, by
  whichever clause of the completeness rule applied — including the
  earlier-release clause, which owes no post-sequence. An entry the skill
  classifies as complete is synthesized even when that line is absent, and
  the line is then appended. Deviation 3 is unchanged. Constraint on every
  edit to this template: the orchestrating-development contract tests
  require exactly one line matching a bracketed single capital letter, kept
  byte-identical, so all new wording is prose.

### Error handling

- A readiness pass with a prompt-delivery or round-level failure is handled
  by the existing Error Handling section, as a round is. An inconclusive
  pass is open and uses one of the three.
- A readiness report without a complete coverage block is unusable; see
  "Coverage makes a pass usable".
- A readiness entry whose `**Result:**` line is missing or malformed is read
  as open. Its sequence and pass number come from its position.
- A third pass that is still open ends the sequence; the procedure
  continues.
- Out-of-scope findings (coverage, ambiguity, feasibility, style) are
  rejected with the reason `out of lens scope`. Under the settled rule such
  a pass still ends the sequence when it applied nothing.
- Missing spec, Global Constraints block, or Contract fields: see "Missing
  plan structures".

## Testing strategy

Contract tests only. String assertions run on whitespace-normalised text,
because the pinned parenthetical is line-wrapped in `task-reviewer-prompt.md`:
the reviewer-templates suite uses its own `assert_folded_contains` helper,
the review-gates suite its `*_NORM` files.

`tests/reviewer-templates/run-tests.sh`, a new section, pins:

- the `**Execution readiness**` cell exists and starts after the
  `**Adversarial failure modes**` cell;
- its `plan:` text contains `tasks that contradict each other or the plan's
  Global Constraints`, which also appears in the Pre-Flight Plan Review
  section of `skills/subagent-driven-development/SKILL.md`;
- its `plan:` text contains `(a test that asserts nothing, verbatim
  duplication of a logic block)`, which also appears in
  `skills/subagent-driven-development/SKILL.md` and in
  `skills/subagent-driven-development/task-reviewer-prompt.md`;
- the cell carries the five numbered checks and the string
  `coverage: GC<k> — <n> sites checked`;
- the cell's `spec:` and `general:` lines carry `not used`;
- the procedure carries `pre-sequence`, `post-sequence`, `at most three
  passes`, `Readiness passes are not counted in N and are not part of the
  two-consecutive-clean-rounds streak.`, and `The host self-review runs
  after the post-sequence.`;
- the log format carries `## Readiness <pre|post> <p> — Execution readiness
  — <model>`, `**Result:**`, and `**Host self-review:** done`, and the skill
  states `r counts ## Round headings only.`;
- the triage section carries `rejected: not a conflict`, `rejected:
  plan-mandated`, `rejected: undecidable at this gate`, and the sentence
  `A readiness finding never produces an unresolved: line, in any caller.`;
- `doc-review-loop-prompt.md` declares `[N_PLAN]` as `0–10` and carries
  `count rotating entries only` and `The host self-review runs after the
  post-sequence.`;
- `skills/multi-doc-review/SKILL.md` is at most 938 lines (baseline 788,
  set by 7.14.0, recorded in the assertion's comment).

`tests/review-gates/run-tests.sh`: the sentence `For a plan, the Execution
readiness pass runs even when N is 0.` and the cost clause `add 2 to 6
further passes of M reviewers` appear in the plan gate of
`skills/writing-plans/SKILL.md` and in Phase 0 of
`skills/orchestrating-development/SKILL.md`, and in neither case in
`skills/brainstorming/SKILL.md`; every existing assertion still passes.

`tests/orchestrating-development/run-tests.sh` gains an assertion that
Phase 2 no longer carries `If N_plan = 0, log the skip`.
`tests/writing-plans/run-tests.sh` and `tests/fill-prompt/run-tests.sh` are
run unchanged and must stay green.

Acceptance measure, outside the suites: the next orchestration run on this
repository is recorded as a case in `docs/orchestration-issues.md` with its
Phase 3 pre-flight block count, the readiness lines from its Phase 2 report,
and the Phase 2 controller's context shares from `make measure-context`. The
release meets its goal when that run has zero pre-flight blocks whose
conflict was findable from the plan and the spec alone. A block whose
conflict needed repository state or implementation results does not count
against it, and a run whose readiness sequences were all inconclusive does
not count at all. The baseline is the three blocks of 2026-09-09.

## Files touched

- `skills/multi-doc-review/SKILL.md` — lens cell, procedure stages,
  parameter sentence, log entry shape, fields read, completeness and resume
  rules, triage steps, completion report, missing-structure fallbacks.
- `skills/multi-doc-review/reviewer-prompt.md` — three lines outside the
  fence: the `[LENS_NAME]` placeholder note and the header sentence "the
  lens comes from SKILL.md's Lens Rotation table", both gaining "or
  `Execution readiness`", and the `[ROUND]` placeholder note, which becomes
  "round number, or a readiness pass label (display only)". The fenced
  prompt is unchanged.
- `skills/writing-plans/SKILL.md` — two gate sentences.
- `skills/orchestrating-development/SKILL.md` — two gate sentences in
  Phase 0, the `N_plan = 0` narrowing in Phase 0 and in the Orchestration
  Log Format section, the Phase 2 dispatch and log line.
- `skills/orchestrating-development/doc-review-loop-prompt.md` — `[N_PLAN]`
  range, Deviations 1 and 2.
- `tests/reviewer-templates/run-tests.sh`, `tests/review-gates/run-tests.sh`,
  `tests/orchestrating-development/run-tests.sh` — new assertions.
- `docs/guide/README.md` — the plan stage section (including the new cost
  sentence and the net disclosure), the Phase 2 parameter table and phase
  description, the round-durability section, the command cheat-sheet row.
- `docs/FORK-IMPROVEMENTS.md` — the sentence that names the four doc lenses.
- `docs/REVIEW-PROCESS-COMPARISON.md` — the two mentions of the pre-flight
  plan read.
- Release files: `VERSION`, `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, the
  README version badge and the two lineage ranges, `RELEASE-NOTES.md` with
  the three-line summary.

## Rollout

Version 7.14.0. Editing the skill does not change live sessions; the local
plugin must be reinstalled before the next orchestration run. Two migration
directions, both covered:

- **New code, old log:** an entry with no `## Readiness` heading is read
  under the earlier-release clause, so a complete entry stays complete and
  an interrupted one resumes at its rotating index.
- **Old code, new log:** an installed copy older than 7.14.0 does not
  recognise the `## Readiness` heading, so it counts fewer rounds and
  re-reviews rather than skipping rounds.

Nothing else to migrate.

## Accepted limitations

1. **Out-of-scope findings cost a pass, not a sequence.** They are rejected,
   and under the settled rule a pass that applied nothing still ends the
   sequence.
2. **The host self-review's own fixes are the last edit inside the gate and
   are seen by no pass.** This is today's behaviour, unchanged. The SDD
   pre-flight is the net.
3. **An undecidable or plan-mandated conflict still reaches Phase 3.** It is
   rejected at the gate, listed in the log's `Owed:` block, found again by
   the Phase 3 pre-flight and ruled there. The gate removes the decidable
   class only.
4. **The net exists only on the subagent-driven-development path.**
   `skills/executing-plans/SKILL.md` has no whole-plan conflict scan, so a
   plan executed through it, or a writing-plans-gate user who never runs
   orchestration, has no later check for an owed conflict. The guide's plan
   stage section says so.
5. **Worst-case cost is 6 × M extra dispatches before retries**, and on a
   platform without parallel dispatch they are sequential.
6. **There is no switch that turns the readiness sequence off.** N = 0 for a
   plan still costs 1 to 3 × M dispatches, in the host session at the
   writing-plans gate. This follows the decision that readiness always runs
   for a plan, together with the non-goal of adding a defaults key. A user
   who wants no dispatches at all does not invoke the gate.

## Evidence

From the run `docs/superpowers-orchestrator/2026-09-09-superpowers-defaults-block/`
(orchestration log and open-decisions file), the six pre-flight conflicts
ruled before Task 1. The `Item` column uses the orchestration log's
numbering, `<ruling>/<item>`: the log records three pre-flight blocks as
RULING 1 (two items), RULING 3 (one item) and RULING 4 (three items).

| Item | Tasks | Conflict | Criterion | Cell check |
|---|---|---|---|---|
| 1/1 | 1 | a verification command would write a complete defaults block, which Global Constraint 2 forbids | task vs Global Constraint | (5) sweep |
| 1/2 | 4 | an "In short" clause spelled the injection name without the form Global Constraint 9 pins | task vs Global Constraint, sibling tasks disagree | (5), (1) |
| 3/1 | 5, 6 | Task 6 says "exactly as in Task 5" while Task 5 changes that list, so the literal reading breaches Global Constraint 11; introduced by round 4's merge | tasks contradict each other, task vs Global Constraint | (1), (5) |
| 4/1 | 3, 4 | a mandated sentence says "presents first" where the spec says that does not apply to a prose question; introduced by round 1's merge | plan clause vs spec | (3) |
| 4/2 | 7 | a citing site restates two of the four parts Global Constraint 8 requires | task vs Global Constraint | (5) |
| 4/3 | 7 | a resume-prompt body restates two of four parts; sibling steps carry all four | task vs Global Constraint | (5) |

In every row the amended side is plan text and the governing side is fixed
text, so the authority order applies each of them without reaching the
undecidable case.

Two later implementer-raised blocks, RULING 7 and RULING 8, are also
covered: ruling 7 (an origin echo that can state an origin the value did not
have) by check (1), and ruling 8 (a 150-word fenced body under a Contract
that restates this repository's 120-word release rule) by check (4), where
the Contract is fixed text and the body is plan text.

The plan review of that run: N = 4, M = 4, lenses in rotation order applied
21, 19, 9 and 25 findings, never converged, reached the cap.
