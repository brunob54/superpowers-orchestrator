# Reviewers per lens (M parallel reviewers per round) — design

Date: 2026-08-27
Slug: `reviewers-per-lens`
Status: reviewed (multi-doc-review, 3 rounds, cap reached — see the
`-review-log.md` sidecar), awaiting user approval
Target release: 7.4.0

## 1. Problem

LLMs (large language models) are not deterministic. The same reviewer
prompt produces different findings on different runs, and one run can
miss a problem that another run would report. The two review-loop skills,
`multi-doc-review` and `multi-code-review`, dispatch exactly **one**
reviewer subagent per round (`skills/multi-doc-review/SKILL.md:56`,
`skills/multi-code-review/SKILL.md:297`). A round therefore takes one
sample of the reviewer's judgment under its lens. The rotating lenses
diversify the *focus* across rounds, but nothing samples the *same* lens
more than once.

This design adds a parameter **M — reviewers per lens**. When M > 1, each
round dispatches M reviewers with the identical prompt, in parallel, and
combines their reports before the round continues. Running time stays
close to a single review because the M reviewers run at the same time;
the token cost grows roughly M times per round. The default is 1, so
nothing changes for users who do not opt in.

## 2. Definitions

- **Lens** — the focus a reviewer is told to take in one round (for
  example "Security"). Each skill has four lenses; round *i* uses lens
  *i*, cycling from lens 1 after lens 4.
- **Round** — one pass of the loop: dispatch, validate, triage (or fix),
  log, convergence check. With this design a round has M reviewers, all
  under the round's single lens.
- **Reviewer** — one `general-purpose` subagent dispatched from the
  skill's `reviewer-prompt.md` template. Reviewer *j* of a round is
  written `r<j>` (`r1`, `r2`, …).
- **Controller** — whoever runs the skill procedure: the main session for
  a direct invocation or an SDD (subagent-driven development) gate, or
  the controller subagent dispatched by `orchestrating-development`.
- **Usable report** — a reviewer's final message whose first line is
  `<!-- multi-review report -->` and which contains a Verdict block
  (today's validation rule).
- **Consolidated report** — the single finding set the controller builds
  from the M reports of one round (section 5.3). The word *consolidate*
  is used for this step; *merge* keeps its existing meaning in the skills
  (applying findings to a document) and in git.
- **Agreement count** — for one consolidated finding, the number of
  distinct reviewers that reported it, written `<a>/<m>` (for example
  `2/3`).
- **Source id** — a finding id as written by one reviewer, qualified by
  the reviewer number: `r1:I2` is finding `I2` of reviewer 1.

## 3. Scope and non-goals

In scope:

1. The parameter M in `multi-doc-review` and `multi-code-review`:
   syntax, validation, default resolution, per-round procedure, report
   consolidation, convergence rule, log format.
2. Passing M through `orchestrating-development` (Phase 0 question, log
   header, both loop templates, resume override) and through
   `subagent-driven-development` (final gate and Batched Autonomous Mode).
3. The environment variable `SUPERPOWERS_REVIEWERS_PER_LENS` and the
   session-context tag that carries its value to the skills
   (`hooks/session-start`).
4. Tests: hook unit tests, an M=2 case in each behavioral review test.
5. Documentation and the 7.4.0 release bump.

Non-goals (decided, with the reason):

- **`requesting-code-review` is unchanged.** Its code-reviewer and
  red-team pair is two different agents, not M samples of one lens.
- **No diversity between the M reviewers.** All M receive the identical
  prompt and the same model. They are not told that other reviewers
  exist. Reason: identical prompts keep the samples independent; they
  may also let prompt caching share the prompt prefix across the M
  dispatches (unverified — the rationale stands without it). If sampling
  happens to return identical reports, the consolidation simply yields
  one finding set.
- **The agreement count is never passed to the fix subagent.** It is
  recorded in the log for the controller's triage and for the human
  reader only.
- **No majority vote.** A vote would drop exactly the findings this
  feature exists to catch (reported by one run, missed by another).
- **No file-based report transport.** Reports stay in the reviewers'
  final messages (section 12, alternative B).
- **No change to the reviewer prompt content.** M identical dispatches
  need no new placeholder. Each `reviewer-prompt.md` receives two edits
  outside the prompt body: the optional `(reviewer <j>/<m>)` suffix on
  the `description:` line of its dispatch block (5.1), and the header
  sentence "One reviewer per round" (`skills/multi-doc-review/reviewer-prompt.md:3-4`,
  `skills/multi-code-review/reviewer-prompt.md:4`) reworded to "M
  reviewers per round (default 1), all with this identical prompt". The
  prompt body and its placeholders are untouched.
- **No Codex adapter change.** The review loops need the Agent tool, so
  no Codex consumer of the tag exists (section 8).
- **No separate M for plan reviews and code reviews.** One M applies to
  both loops of an orchestration run.

## 4. The parameter M

### 4.1 Meaning and range

M is the number of reviewer subagents dispatched per round, all under the
round's lens. Valid M is an integer from 1 to 5 inclusive. Any other
value (0, 6, a word, a decimal) resolves to the default (4.3). The cap of
5 bounds the cost (linear in M) and the size of the consolidation step;
the recall gain has diminishing returns — if one reviewer finds a given
issue with probability p, all M reviewers miss it with probability
(1 − p)^M, which for p = 0.5 is 12% at M = 3 and 3% at M = 5.

### 4.2 Syntax

M is always stated explicitly, never as a bare positional integer. This
keeps `multi-code-review`'s existing rule intact ("a lone integer 0–10 is
N; anything else is a git ref").

Accepted forms in an invocation (case-insensitive; the most recent wins):

- `M=<m>`
- `<m> reviewers per lens`
- `<m> reviewers per round`
- `<m> parallel reviewers`

Slash forms, extended:

```
/multi-doc-review <doc-path> [N] [M=<m>]
/multi-code-review [BASE] [N] [M=<m>]
```

In **both** skills, every `M=<m>` token and every prose form above is
extracted from the invocation **first**, so that a count inside an M
form is never read as N. `multi-doc-review`'s "most recent count wins"
rule for N then applies to the remaining text: "review the spec 2 times
with 3 reviewers per round" gives N = 2 and M = 3. In `multi-code-review`
the existing `[BASE] [N]` positional rule (a lone integer 0–10 is N,
anything else is a git ref) applies to the remaining arguments only.
Without this order `M=2` would be tested as a BASE and rejected by the
ref character set (`^[A-Za-z0-9._/~^{}-]+$`, which has no `=`).

### 4.3 Default resolution (both skills)

1. A value stated in the invocation (4.2) — if valid.
2. Otherwise, the value of a `<reviewers-per-lens>` tag present in the
   session context (4.4) — if valid.
3. Otherwise **1**.

The skills **never ask** for M. It is a rarely changed setting; the
environment variable exists so that the user is not asked at every gate.
The one place M is asked is the existing Phase 0 question batch of
`orchestrating-development` (section 7), which already asks for N_plan,
N_code and the batch cap in one message.

### 4.4 Environment variable and session tag

Variable: `SUPERPOWERS_REVIEWERS_PER_LENS`. Set it in `settings.json`'s
`env` block so it survives plugin updates, exactly as documented for
`SUPERPOWERS_PRESSURE_THRESHOLD`:

```json
{ "env": { "SUPERPOWERS_REVIEWERS_PER_LENS": "3" } }
```

No skill can read an environment variable — skills are Markdown read by
the model. The value therefore travels the same way `<project-map-stale>`
does (`hooks/session-start:285`, read by
`skills/using-superpowers/SKILL.md:90`):

- `hooks/session-start` (bash) reads the variable. When it is an integer
  from 1 to 5, the hook appends
  `<reviewers-per-lens><m></reviewers-per-lens>` to the session context
  it already emits (after the `<context-snapshot>` block, through
  `escape_for_json`, on every platform branch of its output). When the
  variable is unset or invalid, the hook emits nothing — the skills then
  fall to the default 1. The fallback is silent, matching the pressure
  threshold's behavior; the documentation states it.
- Cursor uses the same bash script; no separate change. The Codex
  adapter is left unchanged (section 8): no Codex consumer exists.
- A value set in `settings.json`'s `env` block is applied when the CLI
  process starts; `/clear` re-runs the SessionStart hook but with the
  same process environment (unverified against the Claude Code settings
  documentation; stated in the user documentation as "restart the CLI
  after changing the value").

The tag is visible to the **main session only**. Subagents do not receive
SessionStart context (verified empirically on 2026-08-27: a probe
subagent dispatched from a Claude Code session with the plugin active
found none of the session-start blocks — `<EXTREMELY_IMPORTANT>`,
`<session-log>`, `<known-issues>` — in its context). Every controller
subagent (orchestration Phase 2 and Phase 4) therefore receives M
explicitly through its template placeholder, exactly as it receives N
today. A controller whose template carries no M value (an old template)
uses 1. Should a controller ever see both a template value and a tag,
the template value wins.

## 5. Round procedure with M reviewers

The steps below replace step 1 ("Dispatch one reviewer") and extend
steps 2 and 5 of each skill's per-round procedure
(`skills/multi-doc-review/SKILL.md:54-75`,
`skills/multi-code-review/SKILL.md:295-364`). Steps not mentioned are
unchanged. When M = 1 the procedure is identical to today's in every
observable respect except the invocation line of the log (6.1) and, on
a resumed invocation whose line records a larger M, the single
`**Reviewers:**` line of 6.2.

### 5.1 Dispatch

Dispatch **M reviewers in one message** — M parallel Agent tool calls
(the convention of `skills/dispatching-parallel-agents/SKILL.md`). Each
call fills the same `reviewer-prompt.md` template with the same
placeholder values: same round number, same lens name and instructions,
same document or package path, same model. In `multi-code-review` all M
reviewers of a round read the **same package file**; the package is
generated once per round as today.

Only the Agent call's `description` differs, and only when M ≥ 2:

```
description: "multi-doc-review round <i>: <lens name> (reviewer <j>/<m>)"
description: "multi-code-review round <i>: <lens name> (reviewer <j>/<m>)"
```

The `description` is not part of the prompt (verified empirically on
2026-08-27: a probe subagent dispatched with a marker token in its
`description` did not find the token anywhere in its context); the
reviewers are not told that other reviewers exist. If a future platform
version exposed the `description` to the subagent, the suffix would be
dropped, not the non-goal. The prompt content rules are unchanged:
nothing but the template placeholders is filled; the conversation, prior
findings, fix reports and the log are never passed.

If a platform runs the M calls one after another instead of in parallel,
the result is the same; only the running time grows.

### 5.2 Per-reviewer validation and retry

Each report is validated independently by today's rule (first line is the
marker, a Verdict block is present). Each unusable report is retried
**once** with the identical dispatch; the retry keeps the same reviewer
number `<j>`. The retries of one round may be dispatched together in one
message. After the retries:

- *u* = the number of usable reports, 0 ≤ u ≤ m.
- u = 0 → the round is `inconclusive` (today's rule), nothing is
  triaged, the streak is broken, the loop continues.
- u ≥ 1 → consolidate the usable reports (5.3) and continue. The round is
  *partial* when u < m; a partial round is logged with its counts and can
  never be clean (5.5).

### 5.3 Report consolidation

The controller builds one consolidated finding set from the u usable
reports. Rules, in order:

1. **Enumeration is the source of truth.** Findings are taken from each
   report's enumerated findings, never from its count line (today's rule,
   applied per report).
2. **Union.** Every enumerated finding of every usable report appears in
   the consolidated set, either on its own or inside a consolidated
   finding. Nothing is dropped at this step.
3. **Same-issue rule.** Two findings are the same issue when they point
   at the same place **and** describe the same defect — the same single
   change would resolve both. "Same place" means: for a document, the
   deepest numbered section (or heading) cited — a finding that cites
   several sections is placed at the first one it cites; for code, the
   same file with line ranges that share at least one line (a single
   `file:line` reference is a range of that one line), or the same named
   symbol. Different defects at the same place stay separate. When in doubt, keep them separate: a duplicate costs one
   `rejected: duplicate of [..]` disposition at triage; a wrongly merged
   pair loses a finding.
4. **Severity.** A consolidated finding takes the **highest** severity
   any of its sources gave it.
5. **Text.** The consolidated finding keeps the most specific description
   among its sources; the controller may combine details from several
   sources but must not add claims that no source made.
6. **Ids.** Consolidated findings get fresh ids per severity class —
   `C1…`, `I1…`, `M1…` — ordered by agreement count (highest first),
   then by the lowest reviewer number among the finding's sources, then
   by that reviewer's own id order. Reviewer-local ids are never reused
   as consolidated ids by reference; they appear only as source ids in
   the log (6.2). This rule applies whenever M ≥ 2, including a partial
   round with a single usable report.
7. **Traceability.** Every source id maps to exactly one consolidated
   finding. The controller counts the enumerated findings across the u
   usable reports (*k*) and the source ids it mapped; the two numbers
   must be equal before the round entry is written. On a mismatch the
   controller repairs the consolidation, never the count.
8. **Malformed ids.** A usable report may still carry missing or
   duplicated ids, or a finding under a severity heading that does not
   match its id prefix. Before consolidation the controller renumbers that
   report's findings by position within each severity heading (`C1…`,
   `I1…`, `M1…` in order of appearance; the heading decides the
   severity) and notes `ids renumbered` on that reviewer's entry of the
   `**Reviewer verdicts:**` line (6.2). After renumbering, *k* and the
   source ids are well defined, so the check of rule 7 always has a
   repairable outcome.

When M = 1 the consolidated set is the report's enumeration with its
original ids, unchanged from today.

**Carried findings (`multi-code-review`, round 1).** Every round-1
reviewer receives the carried Minor-findings list and returns one
recommendation per carried item (`fix-before-merge` | `ship-as-is` |
`user-decision`). These recommendation lines are not enumerated findings:
they are outside the consolidated set and outside *k*. The controller
decides each carried item from all M recommendations; when they disagree
it takes the most cautious one — `user-decision` if any reviewer
recommends it (the disagreement itself is information for the human),
else `fix-before-merge` if any reviewer recommends it, else
`ship-as-is`. The decision is taken over the recommendations actually
present in the usable reports; when none is present for an item (every
reviewer omitted it, or the only reviewer that addressed it was
unusable), the controller decides alone, as today. Carried-finding
dispositions carry no source annotation (6.2).

### 5.4 Triage and fixes

Unchanged. The consolidated set is the input of the existing step: in
`multi-doc-review` every Critical/Important finding is applied to the
document or `rejected: <reason>`; in `multi-code-review` the complete
Critical/Important list goes to **one** fix subagent per round. The fix
subagent receives the consolidated findings in the same shape it receives
a single reviewer's findings today (id, severity, location, description);
it receives no source ids and no agreement counts.

### 5.5 Convergence

A round is **clean** when both hold:

- the consolidated set enumerates zero Critical and zero Important
  findings (never the count lines; never post-triage — rejections and
  user-decision findings never make a round clean), **and**
- all M reviewers returned a usable report (u = m).

A partial round (u < m) is never clean and breaks the clean streak, like
an `inconclusive` round. The early-exit rule is otherwise unchanged: exit
only after **two consecutive clean rounds**; with N ≤ 2 no mid-loop exit;
N = 1 always reports "cap reached". Because the union keeps every
reviewer's findings, two consecutive clean rounds are harder to reach
with M > 1 than with M = 1; that is the intended effect.

When a report's count line disagrees with its enumeration, the counts
are recomputed from the enumeration (today's `multi-code-review` rule).
With M = 1 the recomputed counts go on the verdict line as today; with
M ≥ 2 the per-reviewer counts already come from the enumeration, and the
disagreement is recorded by the suffix `, counts recomputed` on that
reviewer's entry of the `**Reviewer verdicts:**` line (6.2).

### 5.6 Verification re-reviews (`multi-code-review` only)

"No fix ships unreviewed" dispatches a verification re-review under the
same lens after fixes, at most 3 cycles per originating round. A
verification re-review uses the **same M**, the same consolidation, and
the same log additions (6.2) under its existing header
`## Round <i> verification <c> — <lens> — <model>`. A partial
verification round counts as a cycle; its usable reports' findings are
triaged normally.

Partial rounds and cycles interact with "No fix ships unreviewed" as
follows. A partial round or verification cycle (u ≥ 1) satisfies the
existing condition "a later round with a usable report ran on the updated
branch": the fixes it examined count as reviewed. A partial verification
cycle whose consolidated set is empty ends the verification of its
originating round. "Never clean" (5.5) concerns only the convergence
streak; it never reopens a verification. So a cap exit after a partial
round ships no unreviewed fix, and three partial cycles with empty
consolidated sets end with nothing standing and nothing `unresolved`.

## 6. Log format

### 6.1 Invocation line — both skills, every M

The invocation line records M right after N, **including when M = 1**, so
that a log is self-describing:

```
_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_
_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — BASE..HEAD <base7>..<head7> — branch <raw-name> — <invoker>_
```

An invocation line without `M=` (written by an earlier release) is read
as M = 1 by readers and tests.

**Precedence on resume.** The M passed to the skill (invocation text or
controller template) governs every round the skill runs, including the
remaining rounds of a resumed, unfinished invocation. The review log's
invocation line is never rewritten. `multi-code-review` recovers no
parameter from its own log — its resume path matches an open entry by
invoker kind and BASE only and takes N and M from the parameters it was
given; `orchestrating-development` recovers parameters from the
*orchestration* log (section 7), not from the review log. A reader sees
the effective M of every round on the `**Reviewers:**` line (6.2), which
is written whenever the effective M differs from the invocation line's
M, even when the effective M is 1.

Consumers of the invocation line and of the disposition lines that must
accept the new fields: the resume path of `multi-code-review`
(in-progress entry detection, `skills/multi-code-review/SKILL.md` around
lines 259-280 and 540-600); the readers of the `<sha>` in
`fixed — <summary> → <sha>` lines (`skills/multi-code-review/SKILL.md`
around lines 553-557 and
`skills/orchestrating-development/code-review-loop-prompt.md` lines
144-150, the idempotent fix-commit lookup);
`skills/orchestrating-development/code-review-loop-prompt.md` lines 104
and 132; and any test that matches these lines
(`tests/claude-code/test-multi-code-review.sh`,
`tests/sdd-scripts/run-tests.sh`). The implementation plan must grep for
`_Invocation`, `N=` and `→ <sha>` across `skills/`, `hooks/` and `tests/`
and update every match.

### 6.2 Round entry — additions when M ≥ 2

When M = 1 and the invocation line records `M=1` (or no `M=`), the round
entry is byte-identical to today's. When the effective M is 1 but the
invocation line records a larger M (a resumed invocation, 6.1), the entry
is today's entry plus exactly one line after the header —
`**Reviewers:** M=1, usable 1/1` (or `usable 0/1` for an inconclusive
round) — with original ids, no source annotation and no
`**Reviewer verdicts:**` or `**Sources mapped:**` lines. When the
effective M ≥ 2 the entry gains three lines after the header and a
trailing source annotation on every finding disposition:

```
## Round <i> — <lens name> — <model>
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 0 Important, 1 Minor | r2: 0 Critical, 1 Important, 0 Minor | r3: 0 Critical, 1 Important, 0 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 1 Critical, 1 Important, 1 Minor
**Converged:** no

### Dispositions
- [C1] applied — <doc section>: <finding summary> → <change made> ← 2/3: r1:C1, r3:I1
- [I1] rejected: <reason> — <finding summary> ← 1/3: r2:I1
- [M1] deferred — <finding summary> ← 1/3: r1:M1
```

(In this example r1 and r3 reported the same issue — r1 as Critical,
r3 as Important — so it is one consolidated finding at the highest
severity: the four source ids (k = 4) map to three consolidated findings,
and every source id appears in exactly one annotation.)

Rules:

- `**Reviewers:**` — M and the usable count of this round. Written when
  M ≥ 2, and also when the effective M differs from the invocation line's
  M (a resumed invocation with a new M, 6.1), so that a reader always
  knows the effective M of a round.
- `**Reviewer verdicts:**` — one entry per reviewer in reviewer order;
  a usable reviewer with no findings is written
  `r<j>: 0 Critical, 0 Important, 0 Minor`; an unusable reviewer is
  written `r<j>: unusable`; a reviewer whose ids were renumbered (5.3
  rule 8) gets the suffix `, ids renumbered`, and one whose count line
  disagreed with its enumeration (5.5) the suffix `, counts recomputed`.
  Counts come from each report's enumeration.
- `**Sources mapped:**` — the traceability check of 5.3 rule 7; both
  numbers are *k*. The entry is written only after the check passed, so
  the two numbers are always equal.
- `**Reviewer verdict:**` — keeps its name and position; when M ≥ 2 it
  carries the **consolidated** counts. No code or test parses this line
  today: the behavioral tests grep disposition lines, and the
  orchestrator's completion check counts `unresolved` and
  `user-decision` disposition lines. The name is kept for human readers
  and so that the M = 1 entry stays unchanged.
- Source annotation — appended at the **end** of the disposition line as
  ` ← <a>/<m>: <source ids>`; `<a>` is the agreement count, the source
  ids are comma-separated in reviewer order. The disposition line keeps
  its existing prefix (`- [I1] applied — …`), so every existing test
  pattern anchored at the start of the line (`^- \[(C|I)[0-9]+\] applied`,
  `^- \[(C|I|M)[0-9]+\] fixed — `) still matches. The canonical
  disposition vocabulary is unchanged. The `fixed` disposition keeps its
  single shape, which becomes
  `fixed — <summary> → <sha>[ ← <a>/<m>: <ids>]`; every reader of
  `<sha>` takes the token immediately after `→ ` (that is, before ` ← `
  when an annotation is present). Post-loop addendum lines
  (`decided (user): …`, addendum `fixed …`) carry no annotation — the
  annotation lives on the finding's original disposition line.
  The round-1 dispositions of findings carried from an earlier
  invocation's ledger carry no annotation (5.3) — they are decided from
  the reviewers' recommendations and never enter the consolidated set;
  a current-round finding whose disposition word is `carried` is an
  ordinary consolidated finding and keeps its annotation.
- The clean-round line `- none — no material issues under this lens` is
  written without annotation; it appears only when the consolidated set
  is empty **and** u = m. A partial round with an empty consolidated set
  writes `- none — no material issues under this lens (partial round,
  usable <u>/<m>)`.
- An `inconclusive` round (u = 0) with M ≥ 2 writes
  `**Reviewers:** M=<m>, usable 0/<m>` and
  `**Reviewer verdicts:** r1: unusable | r2: unusable | …`, no
  `**Sources mapped:**` line (nothing was consolidated), then today's
  `**Reviewer verdict:** inconclusive` and `- inconclusive — <reason>`
  lines.
- A `skipped` entry (N = 0) is unchanged apart from its invocation line,
  which carries `M=` like every other.
- `multi-code-review`'s `_Completed — …` line is unchanged.

## 7. `orchestrating-development` and `subagent-driven-development`

`orchestrating-development`:

- **Phase 0 question batch** gains one item: *M — reviewers per lens
  (1–5, default `<d>`)*, where `<d>` is the value of the
  `<reviewers-per-lens>` tag if present, else 1. Invalid → default, as
  for the other parameters. One M applies to Phase 2 and Phase 4.
- **Orchestration log header**:
  `_Invocation 1 — YYYY-MM-DD — spec <path> — N_plan=<n> N_code=<n> M=<m> cap=<n> — branch feature/<slug> — BASE <sha7>_`.
  A header written before 7.4.0 has no `M=`; on resume M is 1 for it.
  This is an explicit exception to the orchestrator's rule that resume
  parameters are never defaulted (`skills/orchestrating-development/SKILL.md`,
  Resume step 5): no line of such a log records M, so there is nothing to
  recover.
- **Templates** `doc-review-loop-prompt.md` and
  `code-review-loop-prompt.md` gain the placeholder `[M]` — *REQUIRED:
  integer 1–5* — listed next to `[N_PLAN]` / `[N_CODE]` and passed to
  the controller as the skill's M (the controller fills the review log's
  invocation line from it).
- **`state.md` Params line**: `Params: N_plan=<n> N_code=<n> M=<m> cap=<n>`.
- **Resume override**: `... with M=2` appends the existing override line
  `_Invocation <k> — YYYY-MM-DD — M=2 — resumed_`; a controller
  dispatched after it carries the new value in `[M]`, and the precedence
  rule of 6.1 applies to the review log it continues.
- The `REVIEW_DONE …` return lines and the `BLOCKED:` form are
  **unchanged**; M changes how a round is produced, not what the loop
  reports.

`subagent-driven-development`:

- The final whole-branch gate passes M to `multi-code-review` using the
  default resolution of 4.3; it does not ask.
- Batched Autonomous Mode, which never asks, uses the same resolution.
  Its handoff writes `M=<m>` into the `## Resume Instructions` prompt
  **only when the user stated M when the batch run started**, so that
  the stated value survives `/clear`. Otherwise it writes nothing about
  M, and the resolution of 4.3 runs again after every resume — a changed
  environment variable then takes effect at the next batch started after
  the CLI was restarted (4.4).

## 8. Hook change

`hooks/session-start` runs under `set -euo pipefail`, and its helper
`escape_for_json` is defined (around line 428) **after** the content
blocks are built (lines 235-418) and before the group of escape calls
(lines 438-446). A call to the helper placed before its definition
exits the script with status 127 and no JSON — every session would lose
its context. The change therefore has three separate placements:

1. With the content blocks (before the `escape_for_json` definition):

   ```bash
   reviewers_content=""
   case "${SUPERPOWERS_REVIEWERS_PER_LENS:-}" in
     [1-5]) reviewers_content="\n\n<reviewers-per-lens>${SUPERPOWERS_REVIEWERS_PER_LENS}</reviewers-per-lens>" ;;
   esac
   ```

2. In the escape group (lines 438-446), after the definition:
   `reviewers_escaped=$(escape_for_json "$reviewers_content")`.
3. `${reviewers_escaped}` appended at the end of the `session_context`
   assignment (line 448), after `${context_snapshot_escaped}`.

The pattern `[1-5]` matches exactly one character from 1 to 5, so `10`,
`0`, `3.0`, ` 3` and words are rejected.

`hooks/codex/session-start-adapter.js` is **not** changed. No consumer of
the tag exists on Codex: `multi-doc-review`, `multi-code-review` and
`orchestrating-development` all require the Agent tool and refuse or
skip on platforms without it, so an emitted tag would be inert. The
adapter can gain the same block if a Codex consumer ever appears.

No hook wiring file (`hooks/hooks.json`, `hooks/codex-hooks.json`,
`hooks/hooks-cursor.json`, `plugin.universal.yaml`) changes: the hook
event set is unchanged, and no manifest lists the user-set
`SUPERPOWERS_*` variables (`plugin.universal.yaml:121` declares only the
plugin-root variable `CLAUDE_PLUGIN_ROOT`), so none needs an entry.

## 9. Error handling

| Situation | Behavior |
|---|---|
| M stated but invalid (0, 6, `two`, `2.5`) | Use the default of 4.3; do not ask; note the substitution in the skill's completion message. |
| Environment variable set but invalid | No tag emitted; skills use 1; documented as a silent fallback. |
| One or more reviewers unusable after one retry, u ≥ 1 | Partial round: consolidate the usable reports, log `usable <u>/<m>` and `r<j>: unusable`, triage normally, round never clean. |
| All reviewers unusable after retries (u = 0) | `inconclusive` round, as today. |
| Sources-mapped mismatch (k mapped ≠ k enumerated) | Repair the consolidation before writing the entry; never write the line with unequal numbers. |
| Review-log invocation line without `M=` | Read as M = 1 by readers and tests; the controller's M always comes from its parameters, never from the review log (6.1). |
| Orchestration-log header without `M=` on resume | M = 1 — the one defaulted resume parameter (section 7). |
| Reviewer report with missing or duplicated ids | Renumber by position per severity heading, note `ids renumbered` (5.3 rule 8). |
| M recommendations for a carried finding disagree | Most cautious wins: `user-decision`, else `fix-before-merge`, else `ship-as-is` (5.3). |
| Controller template without `[M]` | M = 1. |
| Platform without parallel dispatch | Reviewers run one after another; procedure unchanged. |

## 10. Testing strategy

Unit tests (fast, `bash tests/codex/run-unit-tests.sh`):

- `hooks/session-start`: a new shell test (its location and its wiring
  into the fast unit-test entry point are decided by the plan) runs the
  script with the variable set to `3` (tag present with value 3), unset
  (no tag), and set to each of `0`, `6`, `10`, `abc` (no tag). The test
  asserts on the emitted JSON for the Claude Code branch
  (`CLAUDE_PLUGIN_ROOT` set). The script is not a pure function of the
  variable, so every run is made hermetic: `SUPERPOWERS_AUTO_UPDATE=0`
  (otherwise `check_for_updates` fetches over the network and may
  fast-forward the developer's checkout), an **empty temporary working
  directory** (so no `project-map.md`, `state.md`, `session-log.md`,
  `known-issues.md` or `context-snapshot.json` is read), and `HOME`
  pointed at a temporary directory (the script writes
  `~/.claude/hooks-logs/update-check.cache`). The same guard pattern
  exists in `tests/codex/test-session-start-adapter.js:26-36`.

Behavioral tests (slow, `tests/claude-code/run-skill-tests.sh --integration`):

- `test-multi-doc-review.sh`: the prompt states `N=2` and `M=2`. The
  test extracts the round-1 entry — the lines from `^## Round 1 ` up to
  the next `^## Round ` (or end of file) — and asserts inside it:
  `^\*\*Reviewers:\*\* M=2, usable [12]/2$` (`[12]` tolerates one
  unusable reviewer, so a rare retry failure does not fail the test);
  `^\*\*Sources mapped:\*\* ([0-9]+)/\1$`; and two cross-checks that do
  not trust the controller's own line — the sum of every count on the
  `**Reviewer verdicts:**` line equals *k* of the `**Sources mapped:**`
  line, and the number of distinct `r<j>:<id>` tokens across the entry's
  source annotations equals *k*. At least one disposition line must end
  in ` ← [12]/2: r[12]:[CIM][0-9]+(, r[12]:[CIM][0-9]+)*$`. Existing
  assertions are unchanged.
- `test-multi-code-review.sh`, Case 1 only: `M=2` added to the prompt;
  the same round-1 assertions and cross-checks (Case 1 passes no carried
  findings, so every disposition of the round carries an annotation);
  the invocation line asserted to contain ` N=2 M=2 — `. Case 2
  (pipeline mode) stays at M = 1 so that its package-count control
  (`p5-control`, one package per round) keeps its current meaning; the
  design keeps one package per round in any case.
- Both tests keep their existing assertions, which verify that the M = 1
  disposition and header formats are untouched.

Script-level tests (`tests/sdd-scripts/run-tests.sh`): no script under
`skills/*/scripts/` or `hooks/` parses `_Invocation` lines, so no parser
test is needed; any fixture or text-drift assertion that quotes the line
or the `fixed — … → <sha>` shape is updated to the new text.

Routing: `hooks/skill-rules.json` needs no change — M is a parameter of
an already-routed skill, not a new trigger.

## 11. Documentation and release

- `README.md`: version badge; the two `v6.7.0–v7.4.0` ranges; the release
  enumeration at line 37; the doc-review and code-review bullets (lines
  32-33) and Skills Library entries (lines 367-368) — "one clean-context
  reviewer per round" becomes "M clean-context reviewers per round
  (default 1)"; a short environment-variables note listing
  `SUPERPOWERS_REVIEWERS_PER_LENS` next to `SUPERPOWERS_PRESSURE_THRESHOLD`
  and `SUPERPOWERS_AUTO_UPDATE`.
- `docs/guide/README.md`: Stage descriptions (lines 168-170, 197-198,
  226-233); the Phase 0 parameter table (lines 404-410) gains the M row;
  the orchestration-log sample header (line 445); the phrase cheat-sheet
  rows for both slash forms (lines 719-720); a settings example next to
  the pressure-threshold one (lines 656-658).
- `docs/FORK-IMPROVEMENTS.md` §3 and §4 ("one clean-context reviewer
  subagent" wording, file inventories).
- `docs/REVIEW-PROCESS-COMPARISON.md` line 197 ("one fresh reviewer
  subagent"; line 220 describes the fix subagent and stays as it is),
  and the open ablation list at line 313 (add "(d) M reviewers per
  lens").
- `RELEASE-NOTES.md`: a `## v7.4.0 — M reviewers per lens` entry in the
  existing shape (field report, bold-led bullets, env-var wording modeled
  on the `SUPERPOWERS_PRESSURE_THRESHOLD` entry, docs-sync bullet).
- Version bump in `VERSION`, `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `plugin.universal.yaml` (meta).
- `tests/codex/post-push-validation-checklist.md` is not required: no
  Codex-facing file changes (section 8).
- The environment-variable documentation states that a changed value
  takes effect after the CLI is restarted (4.4).
- `skills/multi-doc-review/SKILL.md` and `skills/multi-code-review/SKILL.md`
  Parameters, Procedure, Log Format and Error Handling sections;
  `skills/orchestrating-development/SKILL.md` Phase 0, log header,
  resume, state block; both loop templates;
  `skills/subagent-driven-development/SKILL.md` final gate and batched
  mode.

## 12. Alternatives considered

- **B — file-based reports plus a merge subagent.** Reviewers write their
  report to `.superpowers/reviews/` and return only the marker and the
  Verdict block; a merge subagent reads the M files and returns one
  consolidated report. It keeps the controller's context close to
  today's in direct mode. Rejected for this release: reviewers would lose
  the strict read-only rule, a new template and a new failure path
  (merger unusable) appear, reviewers would need a prohibition against
  reading each other's files, and `multi-doc-review` would gain a
  `.superpowers/` dependency it does not have. The log format of section
  6 does not depend on the transport, so B can replace the transport
  later without changing the log.
- **C — a per-round coordinator subagent** that dispatches the M
  reviewers and consolidates. Rejected: in pipeline mode this is three
  levels of nested dispatch (session → controller → coordinator →
  reviewer), which is unproven in Claude Code.
- **Majority vote** (`skills/self-consistency-reasoner/SKILL.md` style):
  rejected, see non-goals. That skill also runs its N paths inside one
  agent context; it does not produce independent samples.
- **Research gate** (`skills/brainstorming/SKILL.md`, Research Gate): the
  predicate did not match — no dependency manifest entry, no
  version-sensitive external API, no hosted service is chosen — so no
  `researching-prior-art` run was made.

## 13. Failure-mode check

Adversarial review of the chosen design, with severity and the resulting
decision:

1. **The controller silently loses a finding while consolidating** (two
   distinct findings merged as one, or one forgotten). *Critical if
   unchecked.* Mitigated by 5.3 rules 3 and 7 and the `**Sources
   mapped:**` line: every source id must appear exactly once, the numbers
   must match before the entry is written, and the source annotations
   make any loss visible to a reader and to tests.
2. **Appending `M=` to the invocation line breaks a parser** in a resume
   path or a test. *Critical if missed.* Mitigated by 6.1: every consumer
   is listed, the plan must grep for all of them, and old lines without
   `M=` are defined as M = 1.
3. **Context growth in direct mode.** M reports per round enter the main
   session's context; at M = 5 and N = 10 that is up to 50 reports.
   *Minor.* Bounded by the cap of 5; the cost is the price the user opts
   into; alternative B remains available as a transport change.
4. **A controller subagent never sees the session tag**, so an
   environment-variable default would be ignored in pipeline mode.
   *Critical if unhandled.* Handled by 4.4 and 7: M always travels
   explicitly through the templates; the main session resolves the
   default.
5. **A hung reviewer blocks the round** because the controller waits for
   all M. *Minor.* Same exposure as today's single reviewer, multiplied
   by M; the per-reviewer retry rule applies; no new timeout mechanism is
   added.
6. **Identical prompts return identical reports** (sampling collapses).
   *Minor.* The consolidation yields today's single finding set; cost is
   wasted, correctness is unaffected. Prompt diversity stays a non-goal.
7. **Severity inflation.** One reviewer marks Critical what two mark
   Minor; the consolidated finding is Critical. *Minor.* Recall over
   precision is the stated goal; triage can still reject with a reason,
   and the source annotation shows the disagreement.

## 14. Rollout

No migration. Existing logs are read with M = 1 where `M=` is absent.
Users who set nothing see no change. The feature is opt-in per invocation
(`M=<m>`) or per machine (`SUPERPOWERS_REVIEWERS_PER_LENS`).
