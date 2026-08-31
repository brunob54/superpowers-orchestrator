# Plan Contracts, Not Literal Bodies — Design

**Date:** 2026-08-31
**Topic folder:** `docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/`
**Closes:** worklist row 3 of `docs/orchestration-issues.md` (from Cases 001 and 003; Cases 007–008 show the failure mode in its purest form).

## Problem

`writing-plans` produces plans that fix helper bodies, commands, and skill
wording verbatim. The review loops (`multi-doc-review`, `multi-code-review`)
may never overrule an approved plan, so every later review finding about such
a body becomes a `plan conflict` / `user-decision` stop that the pipeline
cannot settle alone. Three of the four interruptions in the
`reviewers-per-lens` run (Cases 001, 003) and the whole Case 007–008
verification-stop chain trace to this: every one of those findings was
against verbatim plan text.

## Goal

A plan states the **contract** an artifact must satisfy — its invariants and
the verification that proves them, plus inputs and outputs where the
artifact is code — and quotes a literal body as binding only when the body
IS the contract, marking that explicitly. A later review finding about a
body then becomes an ordinary fix within the contract, not a plan conflict.

Definition used throughout: a **contract** is the set of properties an
artifact must guarantee, stated so that a check can falsify them. A
**reference implementation** is a concrete body (code block or quoted text)
that satisfies the contract; it shows one way, it does not bind.

## Scope

- `skills/writing-plans/SKILL.md` — new normative section, Task Template
  field, Plan Header note, Self-Review check, one reconciliation sentence
  (R7).
- `skills/multi-doc-review/SKILL.md` — the plan cell of one lens
  (Ambiguity & testability) gains three finding targets.
- Fast wording tests: a new suite `tests/writing-plans/run-tests.sh` and
  additions to `tests/reviewer-templates/run-tests.sh`.
- An **on-disk-only** edit to `CLAUDE.md` (gitignored in this clone) adding
  the new suite to the test list. No plan task may `git add CLAUDE.md`.

## Non-goals

- **No change to `multi-code-review`.** Worklist row 10 (bounding the
  verification chain on the consumer side) stays open and out of scope. The
  delivery route for the authority statement is the **controller**, not the
  per-round reviewers: `multi-code-review` passes the plan path to
  reviewers only on lens-1 rounds, and subagent-driven-development hands
  per-task reviewers only the `**Global Constraints:**` block — but a
  finding becomes a plan conflict only at controller triage ("conflicting
  with what the plan's text requires"), and the controller makes that
  classification by consulting the plan, where it meets the header
  authority note (R3). Reviewers keep reporting findings as today; the
  note changes how the controller classifies them.
- **Genuine design conflicts still stop the run.** A finding that
  contradicts a spec-level design decision (the Case 007 v2/v3 `[I3]`
  class — the finding disputed a ruling recorded in the spec) is not a body
  question; no contract phrasing dissolves it, and it remains a
  `user-decision` item. Of the eleven historical stop-items in Cases
  001/003/007/008 of `docs/orchestration-issues.md`, this design converts
  eight into ordinary fixes: Case 001 `[I1]` (via the interface-pinning
  rule), Case 003 R7 `[I1]`, Case 007 v2 `[I2]`, v3 `[I1]`, v3 `[I2]`
  (statable invariants), and Case 008 v4 `[I3]`/v5 `[I2]`, v4 `[I4]`,
  v6 `[I1]` (via the self-pin rule — their pinning suite was written by
  the same plan). Two remain genuine stops: Case 003 R6 `[I2]` (a design
  change to escalation semantics) and Case 007 v2/v3 `[I3]`. One, Case
  003 R6 `[I1]`, was already addressed by the harness-claims mechanism
  shipped in 7.6.0 and is out of this design's scope.
- **Plans written before this change, or by other tools, keep their old
  authority at execution and triage time** — they carry no authority note,
  so controllers treat their bodies as today. Review behaviour is scoped
  the same way: the R5 lens targets apply only to a plan whose header
  carries the R3 authority note; a plan without the note predates this
  design and is reviewed under today's lens text. Intended.
- **No hook, activation, or packaging changes.** No skill is added or
  renamed, so `hooks/skill-rules.json` and the four hook-config files are
  untouched.
- **Behavioural test suites are not part of this change's verification.**
  The fast wording suites are; the slow suites run only outside the
  orchestrated run (standing exclusion, worklist row 4).

No decision in this design matched the prior-art trigger predicate.

## Design

Eight requirements, R1–R8. For each piece of new skill wording, this spec
binds the **properties** the wording must have; where a literal string is
binding (because a test pins it or another file must match it), the spec
says so explicitly. Reference sentences given here may be reworded by the
plan or by review fixes as long as the bound properties hold.

### R1 — New section "Contracts and Literal Bodies" in `skills/writing-plans/SKILL.md`

A new top-level section (heading exactly `## Contracts and Literal Bodies`
— **this heading string is binding**: the new test suite greps for it).
Place it between "Task Rules" and "Task Template" so the template's new
field has its definition above it. The section must state, in this order,
rules with the following properties:

1. **Contract obligation.** For every helper, function, command, or piece
   of wording a task introduces or modifies, the task states the contract
   in its `**Contract:**` field (R2): the invariants that must hold and the
   verification (a runnable command or check) that would falsify them;
   for code artifacts also inputs and outputs. A task that creates or
   modifies several artifacts holds one entry per artifact in the same
   field (a list) — or is a candidate for splitting. Procedural step
   blocks that operate the pipeline rather than build the feature — the
   Step 5 commit command, `Run:` verification lines — need no contract
   entry; rule 3's default covers them. The boundary is a test, not a
   feel: a block is procedural exactly when it creates or modifies no
   file named in the task's `**Files:**` list. Two shapes are defined and
   each is shown in a short example (see "Contract shapes" below; the
   section must carry both examples, adapted or verbatim).
2. **Interface pinning rule.** An interface (signature, flag set, file
   format) is pinned in the contract only when something *outside the plan*
   already depends on it. Stating inputs and outputs in the
   `**Contract:**` field does not pin them: a concrete signature written
   there is descriptive — part of the reference implementation — unless
   the external-dependency condition holds, and a fix may amend the
   signature together with the contract's inputs/outputs wording as one
   ordinary fix, as Case 001's resolution changed a helper's signature.
3. **Authority default.** Code blocks and quoted wording in task steps are
   reference implementations. The implementer follows them as written; a
   later review finding against such a body is an **ordinary fix** so long
   as the stated contract still holds. Only a change that breaks or amends
   the contract itself is a plan conflict. (The phrase "ordinary fix" is
   binding — the test greps for it.)
4. **Exact-content marker.** A block is binding byte-for-byte only when the
   line immediately above the fenced block **or block quote** it pins reads
   `**Exact content:** <reason>` (the literal `**Exact content:**` label is
   binding — the test greps for it; the colon idiom matches the template's
   existing `**Label:** value` convention). The reason must name the
   *external* pin: a pre-existing test asserting the string, another file
   that must already match byte-for-byte, or user-approved copy — and a
   user-approval reason must cite where the approval is recorded (a spec
   section, a review-log disposition, or a plan amendment quote); an
   uncited approval claim is not a valid reason. A marker
   with no reason is a plan failure of the same class as the "No
   Placeholders" patterns. Inline placement (marker text on the same line
   as the content) is forbidden.
5. **Self-pin rule.** A pin that the plan itself introduces (the plan also
   writes the test that asserts the string, or also writes the matching
   file) does not justify the marker: body and pin are amendable **together
   as one ordinary fix** — the fix changes the text and its pinning test in
   the same commit. The same applies to a *pre-existing* pin whose
   assertion the same plan edits: a pin the plan controls is a self-pin,
   whatever its age. Only a pin the plan leaves untouched binds. Circular
   reasons — a reason citing an artifact the same plan creates or
   modifies — are a plan failure.
6. **Boundary sentences.** (a) This section defines the *authority* of
   bodies; it does not license vague steps — the "No Placeholders" rules
   still require actual code. (b) The default never applies to the plan
   header's `**Global Constraints:**` block, which binds as stated; a
   conflict with a global constraint is genuine and stops the run. (c)
   Other non-task plan content (header prose such as `**Architecture:**`
   and `**Assumptions:**`, the File Structure section) follows the same
   reference default: findings against it are ordinary fixes unless they
   contradict a stated contract or a global constraint. (d) A finding
   against a body in a task whose field reads `**Contract:** none —
   <reason>` is an ordinary fix under rule 3's default — there is no
   contract to break. (e) The implementer follows the reference body; the
   contract governs later findings.

### Contract shapes (both examples go into R1's section)

**Code artifact** (drawn from Case 001's helper — the block below is a
reference example, not bound wording):

> **Contract:** `assert_round_reviewers <log> <round> <m> <required|optional>`
> - Inputs: review-log path, round number, expected reviewer count M, an
>   expectation mode supplied by the caller.
> - Output: exit 0 only when the round entry demonstrates M reviewers per
>   lens and every consolidated finding maps to reviewer sources.
> - Invariants: mode `required` makes a `Sources mapped: 0/0` entry fail;
>   mode `optional` keeps the documented skip; a missing or misspelled mode
>   fails.
> - Verification: synthetic-fixture checks covering both modes × both
>   outcomes, bad mode, missing round entry.
> - Interface not externally pinned — the signature above is descriptive
>   and may change in a fix (rule 2).

**Wording artifact** (drawn from Case 008 — likewise a reference example):

> **Contract:** model-probe example in `reviewer-prompt.md`
> - Must convey: a reviewer asserting a harness property runs a probe; the
>   probe prompt must not name the canary token.
> - Invariant: no example places the token inside the probe prompt text.
> - Verification: `bash tests/reviewer-templates/run-tests.sh` asserts the
>   section exists and the example probe omits the token.
> - Sentence wording is free; the properties above bind.

### R2 — Task Template field

The Task Template gains a `**Contract:**` field directly after
`**Does NOT cover:**`, mirroring the Security-flag idiom: always present,
with a parenthetical instruction, and `none — <reason>` permitted when the
task creates or modifies nothing whose later review the contract would
govern. The literal `**Contract:**` label inside the template is binding
(test-pinned). Property for the parenthetical: it must point at the
"Contracts and Literal Bodies" section and name the two shapes.

### R3 — Plan Header authority note

The Plan Header template (the fenced block under "## Plan Header") gains a
fixed note, in the same mechanism as the existing "For agentic workers"
block quote, so the rule travels inside every generated plan to the
reviewers who never read `writing-plans`. Bound properties of the note:

- It states that fenced blocks and block-quoted wording in task steps are
  reference implementations for the task's stated `**Contract:**`, that a
  review finding against such a body is an ordinary fix while the contract
  holds, and that only blocks marked `**Exact content:**` bind
  byte-for-byte.
- It states that the `**Global Constraints:**` block binds as stated, and
  that the `**Body authority:**` note itself binds as stated alongside it
  — a review fix may not reword the note (rule 6(b)).
- It opens with the label `**Body authority:**` (test-pinned, byte pin,
  matched exactly and case-sensitively, asserted to occur inside the Plan
  Header fenced template). `multi-doc-review`'s plan-cell gate (R5)
  switches on this label, not on free text: a free-text phrase is
  rewordable by an ordinary review fix, so it cannot carry a gate. The
  note also contains the phrase "reference implementations" (test-pinned,
  case-insensitive fragment, same suite) — this phrase is no longer the
  gate predicate.

### R4 — Self-Review check 5

The "Self-Review" section gains a fifth check with these properties: every
fenced block or quoted wording is in one of **three** buckets — (a) it
falls under its task's stated contract, (b) it carries an
`**Exact content:**` marker, or (c) it is a procedural step block
(verification command, commit command) covered by the blanket default of
R1 rule 3; every marker's reason names a pin external to the plan and
untouched by it (the circular case is called out); every `**Contract:**`
field is falsifiable — a contract no check could fail ("must work
correctly") is treated as missing, and so is a `none — <reason>` field on
a task that does create or modify a governed artifact (a false `none`).

### R5 — `multi-doc-review` lens addition

In `skills/multi-doc-review/SKILL.md`, section "Lens Instructions", lens
**Ambiguity & testability**, the **plan** cell only, add four finding
targets (properties; exact phrasing free except the pinned fragments):

1. task-step bodies of artifacts the task creates or modifies that fix
   behaviour with **no stated contract** (the fragment "no stated
   contract" is binding — `tests/reviewer-templates/run-tests.sh` greps
   for it); a `**Contract:** none — <reason>` field on a task that does
   create or modify a governed artifact counts as no stated contract;
   procedural step blocks (verification commands, commit
   commands) are exempt;
2. contracts that are vacuous or unverifiable (no check could falsify
   them);
3. `**Exact content:**` markers with no reason, or whose reason cites an
   artifact the same plan creates or modifies (a self-pin);
4. a `**Global Constraints:**` entry that (a) does not trace to the spec
   named on the plan's `**Spec:**` line and (b) restates the body of an
   artifact the plan itself creates or modifies — a self-pin in disguise
   (the fragment "self-pin" is binding — same suite).

The four targets apply only to a plan whose header carries the label
`**Body authority:**` — a byte pin, matched exactly and case-sensitively,
not the free-text phrase "reference implementations" the note also
contains: a free-text phrase is rewordable by an ordinary review fix, so
it cannot carry a gate. A plan whose header carries a `**Contract:**`
field but no `**Body authority:**` label is an inconsistent regime and is
itself a finding — it is never silently reviewed as a legacy plan. A plan
with neither predates this design and is reviewed under today's lens text
(see Non-goals).

No other lens or cell changes: this lens already owns placeholders,
vagueness, and unverifiable verification, and a second lens would duplicate
findings under the rotation.

### R6 — Tests

Two fast, dependency-free suites in the style of
`tests/reviewer-templates/run-tests.sh` (plain bash + grep, `PASS`/`FAIL`
per check, failures accumulated and every check printed, exit non-zero at
the end when any check failed — the cited suite's actual behaviour):

- **New:** `tests/writing-plans/run-tests.sh`, asserting in
  `skills/writing-plans/SKILL.md`. Binding literal labels (`## Contracts
  and Literal Bodies`, `**Exact content:**`, `**Contract:**`) are matched
  **exactly and case-sensitively** (`grep -F`, as
  `tests/reviewer-templates/run-tests.sh` does) — they are byte pins;
  free-text fragments **must** match case-insensitively (`grep -i`), per
  the repository's lesson that free text gets reworded. Assertions: the
  `## Contracts and Literal Bodies` heading; the
  `**Exact content:**` label; the `**Contract:**` label inside the Task
  Template block; the fragment "ordinary fix"; the fragment "reference
  implementations" inside the Plan Header fenced template; the self-pin
  rule via the binding fragment "together as one ordinary fix"; the
  Self-Review check via the binding fragment "falsifiable".
- **Extended:** `tests/reviewer-templates/run-tests.sh` gains one check:
  the plan cell of Ambiguity & testability contains the binding fragments
  "no stated contract" and "self-pin". This suite's declared scope already
  covers `skills/multi-doc-review/SKILL.md`.
- Both suites must pass; the pre-existing checks of
  `tests/reviewer-templates/run-tests.sh` and
  `bash tests/codex/run-unit-tests.sh` must keep passing (no wording this
  design touches is currently pinned there, so failures indicate collateral
  edits).

### R7 — Reconciliation edits

- "No Placeholders": one added sentence referring to R1's boundary (actual
  code still required; the Contracts section defines its authority).
- No change to the `**Global Constraints:**` header field wording; R1 rule
  6(b) carries the clarification instead.

### R8 — CLAUDE.md (on-disk only)

Add the new suite one-liner to the Testing list in `CLAUDE.md`. This file
is gitignored in this clone: the edit is on-disk only, no task may
`git add` or commit it, and the plan must state this in the task.

## Error handling

- A plan writer omitting `**Contract:**` → caught by R4 (self-review) and
  R5 target 1 (plan review).
- Over-marking (`Exact content` everywhere to be safe) → R1 rules 4–5:
  each marker needs an external pin; self-pins and missing reasons are plan
  failures, and R5 target 3 makes them review findings.
- Vacuous contracts → R4 and R5 target 2.
- Legitimately pinned text (a string asserted by a pre-existing suite the
  plan does **not** touch) → carries a valid marker; findings against it
  are real plan conflicts, which is correct: the pin is external evidence
  the user relied on. When the plan also edits the pinning assertion, the
  self-pin rule applies instead (R1 rule 5) and body plus pin amend
  together as one ordinary fix.

## Testing strategy

TDD at the wording level: each task writes the failing grep assertion
first, then the skill wording that satisfies it. Verification commands:
`bash tests/writing-plans/run-tests.sh`,
`bash tests/reviewer-templates/run-tests.sh`,
`bash tests/codex/run-unit-tests.sh`. The behavioural suites are excluded
from this run (see Non-goals); the change's live effect is observable only
after a release installs it, which is outside this branch.

## Rollout

Ships in the next release (version bump per `CLAUDE.md` release list);
until then, sessions run the installed 7.6.0 copy and generate plans
without the authority note. No migration: old plans keep their old
authority (Non-goals).

## Amendments

- **2026-08-31 (code review [I1]):** R3 bullet 3 and R5's gate sentence
  change from the free-text PHRASE predicate ("reference implementations")
  to the LABEL predicate (`**Body authority:**`), and R5 gains an
  inconsistent-regime guard (a plan with `**Contract:**` fields but no
  `**Body authority:**` label is itself flagged, never silently reviewed
  as legacy). Reason: a free-text phrase is rewordable by an ordinary
  review fix, so it cannot carry a gate.
- **2026-08-31 (code review [I2]):** Self-Review check 5 and R5's lens
  targets are extended to inspect `**Global Constraints:**` entries with a
  decidable two-part test: an entry that (a) does not trace to the spec
  named on the plan's `**Spec:**` line and (b) restates the body of an
  artifact the plan itself creates or modifies is a self-pin in disguise
  and is flagged. Reason: rule 6(b)'s unconditional bind on Global
  Constraints gave self-pinned literals an unguarded bypass of rule 5.
