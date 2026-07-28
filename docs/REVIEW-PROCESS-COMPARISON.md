# Review Processes Across the Superpowers Lineage

A comparison of how specs, plans, and code get reviewed in the three repositories
of this plugin's lineage. Written 2026-07-28; version numbers and behavior are a
snapshot of that date.

| Repository | Version compared | Commit | Last activity |
|---|---|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) (original, Jesse Vincent) | v6.2.0 | `3dcbd5c` | 2026-07-23 |
| [REPOZY/superpowers-optimized](https://github.com/REPOZY/superpowers-optimized) (parent fork) | v6.6.1 | `ae16bf3` | 2026-05-08 |
| brunob54/superpowers-optimized (this repository) | v6.11.0 | `5a3fca8` | active |

Version numbers are **not comparable across repositories** — each line numbers its
own releases. REPOZY v6.6.1 is not "newer" than obra v6.2.0; they diverged long
before either number.

This document is descriptive, not promotional. Where the evidence favors a
simpler design than the one this fork ships, that is stated plainly
(see [What the evidence actually shows](#what-the-evidence-actually-shows)).

---

## Context: the video that prompted this comparison

In an interview about Superpowers
([youtube.com/watch?v=6YltXh12W-g](https://www.youtube.com/watch?v=6YltXh12W-g)),
Jesse Vincent describes the Superpowers 5 workflow:

> "One of the other things in Superpowers 5 is I've taken the review loop that
> we've always done on the code and we now do it on the spec and the plan."

> "Once that plan is written — and again reviewed by loop — the main agent
> becomes the coordinator and starts dispatching tasks to sub-agents."

Other statements from the same conversation that bear on review design:

- Specs "are the only thing that humans should be reading at this point …
  the code does not matter anymore. The spec gets reviewed whether it's by you
  or by more Claudes."
- He knows teams that cross-review specs between Claude and Codex, "and then
  review those reviews with the other tool," with good reported results.
- "I have also found that simply multiple agent reviews with the same model
  helps" — backed by his five-terminals experiment: paste the same prompt into
  five Claude Code instances and you get "five pretty different results."
  Different agent instances find different things.
- The phrase "look at this with fresh eyes" alone measurably changes how an
  agent reviews, even without a subagent.
- He briefly removed the pause after spec-writing in Superpowers 5, got
  immediate user pushback ("I need to read that spec before we start
  planning"), and restored it as an optional pause.

**Important caveat:** the talk describes the v5.0.0-era design. As shown below,
the shipped obra code removed the subagent spec/plan review loop two weeks after
v5.0.0 shipped, and as of v6.2.0 no document reviewer subagent is dispatched by
any obra skill. The talk's argument for instance-diversity in review and the
shipped code's retreat from looped document review coexist unreconciled in the
upstream project.

---

## obra/superpowers: history and current state

### The document review loop: shipped, tightened, removed

The original repository's release notes record a complete lifecycle for the
feature this fork independently rebuilt:

**v5.0.0 (2026-03-09) — introduced.** A "Document review system":
spec and plan reviewer subagent prompts
(`spec-document-reviewer-prompt.md`, `plan-document-reviewer-prompt.md`),
dispatched after the design doc is written and per plan chunk respectively.
"Review loops repeat until approved or escalate after 5 iterations." This is
the mechanism described in the video.

**v5.0.4 (2026-03-16) — tightened.** Chunk-by-chunk plan review replaced by a
single whole-plan pass; a "Calibration" section added so reviewers only flag
issues that would cause real problems ("minor wording, stylistic preferences,
and formatting quibbles should not block approval"); max iterations cut from
5 to 3; checklists trimmed (spec 7→5 categories, plan 7→4).

**v5.0.6 (2026-03-24) — removed.** Quoting the release notes:

> "The subagent review loop (dispatching a fresh agent to review plans/specs)
> doubled execution time (~25 min overhead) without measurably improving plan
> quality. Regression testing across 5 versions with 5 trials each showed
> identical quality scores regardless of whether the review loop ran."
>
> "Self-review catches 3-5 real bugs per run in ~30s instead of ~25 min, with
> comparable defect rates to the subagent approach."

Both loops were replaced with inline self-review checklists run by the
authoring agent itself (spec: placeholder scan, internal consistency, scope,
ambiguity; plan: spec coverage, placeholder scan, type consistency). The two
reviewer prompt template files still exist in the tree as of v6.2.0 but are
referenced by nothing — vestigial.

### Code review in obra v6.x

v6.0.0 (2026-06-16) rewrote how subagent-driven-development (SDD) reviews each
task, explicitly motivated by "a long run of cost-and-quality experiments on
real projects":

- **One reviewer per task, two verdicts.** The previous two per-task reviewers
  (spec compliance and code quality) merged into a single
  `task-reviewer-prompt.md` returning both verdicts, so one fix pass clears
  both. A "can't verify from the diff" verdict flags requirements living in
  untouched code.
- **One broad review at the end** of the run, "on the most capable model,"
  instead of re-reviewing everything task by task.
- **Pre-flight plan read** before the first task, surfacing internal plan
  conflicts at once instead of mid-run.
- **File handoffs.** `task-brief` and `review-package` scripts write task text
  and review diffs to files, because pasted diffs "park permanently in the most
  expensive context."
- **Anti-gaming rules.** Every dispatch must name a model (unnamed dispatches
  silently inherit the session's most expensive one — one observed run put all
  26 reviewers on the top tier); the controller may not tell a reviewer what
  to ignore or pre-rate severity; reviewers are read-only and instructed to be
  skeptical of implementer rationales.

v6.2.0 (2026-07-23) added plan-scoped workspaces and restructured the fix loop:
fix rounds **resume the implementer** (rounds 1–3) rather than dispatching
fresh agents, escalating to a fresh implementer on a more capable model
(rounds 4–5); a scoped `re-review-prompt.md` checks the fixes rather than
re-reading the whole task; a five-round circuit breaker triggers controller
adjudication of each open finding, with load-bearing findings blocking and the
rest parked in the ledger with rulings.

The final whole-branch review is a **single round**: one reviewer dispatch,
one fix dispatch for its findings, one scoped re-review, adjudication of
residuals.

### Current obra review pipeline, end to end

1. Brainstorming → spec → **inline self-review** → user gate.
2. Writing-plans → plan → **inline self-review** → execution handoff.
3. SDD per task: implementer → **task reviewer (two verdicts)** →
   resume-based fix loop with five-round breaker.
4. End of run: **one whole-branch review** on the most capable model → one fix
   dispatch → one scoped re-review → adjudicate residuals.

---

## REPOZY/superpowers-optimized: the parent fork (v6.6.1)

The parent fork restructured obra's skills for token efficiency and added
operational machinery, but its review *process* tracks obra's post-v5.0.6
design, frozen at the state of roughly obra v5.x (it predates obra's v6.0.0
SDD consolidation and never absorbed it):

- **Spec review:** inline self-review (same four checks as obra) + user gate.
  No document reviewer subagent. Ships obra's orphaned
  `spec-document-reviewer-prompt.md` / `plan-document-reviewer-prompt.md`,
  also unreferenced.
- **Plan review:** inline self-review (same three checks as obra).
- **SDD per task:** the **older two-stage gate** obra later merged — a
  spec-compliance reviewer subagent, then a separate code-quality reviewer
  subagent, each with its own fix/re-review loop
  (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`).
- **Final review:** a single one-pass "final whole-branch review" — no round
  structure, no log, no defined fix protocol.

Its genuine review-adjacent contributions, which this fork retains:

- **`context-snapshot.json` scoping** in requesting-code-review: when a fresh
  snapshot exists, the reviewer prompt is seeded with changed files *plus
  blast-radius callers*; a stale snapshot degrades gracefully.
- **Built-in security pass**: reviews touching auth, credentials, input
  validation, permissions, crypto, or data-access boundaries must include a
  security review as part of the same review, not a separate step.
- **Plan-level security flag** (v6.6.1): tasks marked `security` trigger a
  pre-implementation security review before the implementer is dispatched.
- **Parallel waves** as the default execution mode, with the same two-stage
  gate per task in a wave.

The parent's last commit is 2026-05-08; it has not incorporated anything obra
shipped in v6.x.

---

## This fork (brunob54, v6.11.0)

Everything below was added on top of the REPOZY v6.6.1 baseline
(see [FORK-IMPROVEMENTS.md](FORK-IMPROVEMENTS.md) for full descriptions):

**v6.8.0 — SDD review flow rework.** A deliberate port of obra's v6.0.0
per-task review design into the REPOZY-structured skill: single task reviewer
with two verdicts, `task-brief` / `review-package` file handoffs, one fix
subagent per round covering both verdicts, pre-flight plan review,
model-required dispatches. The parent's two-reviewer prompts were replaced by
`task-reviewer-prompt.md`.

**v6.9.0 — multi-doc-review** (renamed from `multi-review` in v6.11.0).
N-round independent document review at the brainstorming (spec) and
writing-plans (plan) gates, or direct via `/multi-doc-review <path> [N]`:

- Each round dispatches **one fresh reviewer subagent, blind** to the authoring
  conversation, to prior rounds' findings, and to the audit log.
- Rounds rotate through **four lenses**: correctness & completeness,
  ambiguity & testability, feasibility & architecture risk, adversarial
  failure modes — with per-doc-type instructions for each.
- Findings are **triaged into the document between rounds**: every
  Critical/Important finding is either applied or logged
  `rejected: <reason>` — never silently dropped. A sidecar log
  (`<doc>-review-log.md`) records every disposition.
- **Early exit** after two consecutive clean rounds (zero Critical/Important
  enumerated); default N=3, valid 0–10, N=0 is an explicit skip.
- **Once per gate**: a completed loop is recorded in the log and not re-run
  after user-requested edits (only the host self-review re-runs), surviving
  session restarts.
- The host skill's inline self-review still runs after the loop, to catch
  merge-introduced issues.

**v6.10.0 — multi-code-review.** The same loop shape applied to a branch diff,
replacing SDD's single-pass final whole-branch review, or direct via
`/multi-code-review [BASE] [N]`:

- Lenses per round: correctness & spec alignment, adversarial red-team,
  security, test quality.
- One **fix subagent per round** for Critical/Important findings, committing
  fixes before the next round re-reviews the updated diff.
- Sidecar audit log and fix reports under `.superpowers/reviews/`
  (self-git-ignored).
- Same convergence rule (two consecutive clean rounds) and N semantics.
- Operational hardening: user-supplied BASE refs are charset-validated and
  resolved via `git rev-parse` before any shell use; ancestry is verified so a
  stale BASE cannot make foreign commits appear as deletions; a dirty working
  tree blocks fix dispatch without explicit consent; reviewer model inherits
  the session model with a **sonnet floor**.

The parent's `requesting-code-review` (context-snapshot scoping, built-in
security pass) is retained unchanged for ad-hoc reviews outside the SDD flow.

---

## Side-by-side

| Stage | obra v6.2.0 | REPOZY v6.6.1 (parent) | This fork v6.11.0 |
|---|---|---|---|
| Spec review | Inline self-review + user gate | Inline self-review + user gate | Self-review + **multi-doc-review** loop + user gate |
| Plan review | Inline self-review | Inline self-review | Self-review + **multi-doc-review** loop |
| SDD per-task review | One reviewer, two verdicts; resume-based fix loop; 5-round circuit breaker with adjudication | Two sequential reviewers (spec, then quality), each with own fix loop | One reviewer, two verdicts (ported from obra v6.0.0); one fix subagent per round |
| Final branch review | One review ("most capable model") + one fix dispatch + one scoped re-review + adjudication | One review, one pass, no defined fix protocol | **multi-code-review**: N rounds, rotating lenses, fix subagent per round, audit log, early exit on 2 clean rounds |
| Ad-hoc code review | `code-reviewer.md` template dispatch | Same + context-snapshot scoping + built-in security pass | Same as parent (retained) |
| Review audit trail | SDD ledger + fix-round entries | None beyond commits | Sidecar review logs for both loops (every finding's disposition recorded) |
| Doc reviewer templates | Vestigial (unreferenced since v5.0.6) | Vestigial (inherited) | Removed; replaced by `reviewer-prompt.md` per loop skill |

Design-level differences between this fork's loops and the loop obra removed:

| Property | obra v5.0.0–v5.0.6 (removed) | This fork's multi-doc-review |
|---|---|---|
| Round structure | Same reviewer checklist, re-dispatched until "Approved" | N independent rounds, each blind to prior rounds |
| Reviewer focus | One generic checklist (5–7 categories) every pass | A different lens each round |
| Between rounds | Fix, then re-review for approval | Triage each finding (apply or reject-with-reason), merge, next lens |
| Exit condition | Reviewer approves, or iteration cap (5, later 3) | Two *consecutive* clean rounds, or cap N |
| Repeat protection | None recorded | Once-per-gate guard persisted in the log |
| Audit trail | None | Sidecar log of every finding and disposition |

---

## What the evidence actually shows

This section exists to keep the document honest.

**The only quantitative result anywhere in the lineage is negative.** obra's
v5.0.6 measurement — 5 versions × 5 trials, identical quality scores with and
without the subagent loop, ~25 minutes of overhead per run — is the sole
controlled comparison of looped document review against inline self-review.
Nothing in this fork's history is comparable evidence. Anyone adopting this
fork's loops should know that the original project tried the *idea* and walked
it back on data.

**That result measured a different design.** The removed loop re-ran one
generic checklist to approval; this fork's loop runs blind rounds under
rotating lenses with severity triage. The mechanism Jesse describes in the
video — different agent instances reliably find different things — is exactly
what lens rotation plus blindness tries to exploit and what
iterate-to-approval does not. Whether that difference moves the measured
outcome is **untested**. The burden of proof sits with this fork's design, not
against it.

**The cost concern transfers even if the quality result doesn't.** N blind
rounds cost N reviewer dispatches plus triage plus (for code) fix subagents.
The early-exit rule, the once-per-gate guard, and N=0 bound the cost in ways
the removed loop did not, but a converging run still pays for two clean rounds
to prove convergence. obra's ~25-minute figure is the right order of magnitude
to expect per gate.

**Anecdotal signal from dogfooding this repository (July 2026), for what it
is worth:** the multi-code-review plan accumulated 27 findings over 10 review
rounds before shipping, including issues found only under the red-team lens
(e.g. a forgeable resume sentinel, command injection via an unvalidated BASE
ref); in a multi-doc-review run, round 2 found a Critical defect that round
1's own merge had introduced. That last example cuts both ways: the loop
caught the defect, but the loop's merge step also created it — a failure mode
inline self-review cannot have. None of this is a controlled comparison.

**Things obra's current design does that this fork's does not:**

- The final whole-branch review explicitly runs on **the most capable model**;
  this fork's reviewers inherit the session model (floored at sonnet), so a
  sonnet session gets sonnet reviewers throughout.
- Fix rounds **resume the implementer** (preserving its context) before
  escalating to fresh agents on stronger models; this fork dispatches a fresh
  fix subagent per round.
- The per-task fix loop has an explicit **five-round circuit breaker with
  finding-by-finding adjudication**; this fork's per-task loop and review
  loops rely on the round cap N and triage discipline instead.

**What would settle the open question.** An A/B evaluation in the style obra
already used: specs and plans with planted flaws (obra's eval scenarios —
e.g. `spec-reviewer-catches-planted-flaws` — are a ready template), run under
(a) self-review only, (b) one blind round, (c) the full N=3 lens loop,
measuring planted-flaw catch rate, false-finding rate (merge churn),
wall-clock, and tokens. Until that exists, the fair summary is: this fork's
review loops are a **plausible, differently-designed second attempt** at an
idea the original project shipped, measured, and abandoned — with bounded cost
and anecdotal but no controlled evidence of benefit.
