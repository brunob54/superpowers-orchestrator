# Marker position tolerance — design

**Topic:** `marker-position-tolerance` · **Date:** 2026-09-06 · **Files
touched:** `skills/orchestrating-development/SKILL.md`,
`hooks/subagent-guard.js`, three other skills' guard prose,
`docs/FORK-IMPROVEMENTS.md`, `tests/`

## Problem

A controller subagent dispatched by `orchestrating-development` must end its
turn with a report whose **first line** is exactly the marker
`<!-- orchestration report -->`. Two independent mechanisms enforce that
single sentence:

- `skills/orchestrating-development/SKILL.md:162` — the orchestrator's
  Return contract. A return without the marker on the first line is
  **malformed**, and the prescribed response is one identical retry; a second
  failure is a major error that stops the run.
- `hooks/subagent-guard.js:119-123` — the `SubagentStop` hook. It scans every
  subagent's final message for an action verb followed by a skill name and
  blocks the subagent from stopping when it finds one. A message is exempt
  when `lastMessage.trimStart().startsWith(<marker>)` for one of three
  markers. Controller returns need that exemption because a free-text
  `BLOCKED` reason legitimately pairs a verb with a skill name ("plan says
  use `executing-plans` semantics"). Three assertions pin the strictness:
  `tests/codex/test-subagent-guard.js:269`, `:335`, `:383`.

Controllers do not always comply. Three occurrences are on record, across two
runs and three phases:

| Run | Phase | What preceded the marker |
|---|---|---|
| `reviewer-harness-claims` | dispatch 6 | narration (worklist row 9's original observation) |
| `plan-contracts-not-bodies` | Phase 1 (plan writer) | a Self-Review summary |
| `plan-contracts-not-bodies` | Phase 4 (code-review loop) | one sentence explaining a deliberate decision |

Evidence: `docs/orchestration-issues.md` Case 002 Follow-up 7 and Case 011;
the two `note:` lines at
`docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/plan-contracts-not-bodies-orchestration-log.md:7`
and `:32`. Worklist row 9 says "Seen once"; that wording is stale — Case 011
titles itself a "row 9 recurrence" and closes with "three recorded
occurrences".

**Why the strict rule costs more than it protects.** In all three cases the
marker was present, every consumed field parsed, and the report was correct.
The strict reading throws that away and retries. The retry is not free and,
in one phase, not even safe:

- A Phase 1 retry re-writes a plan that already exists on disk.
- A Phase 4 retry hits `code-review-loop-prompt.md` Deviation 2. When the
  previous invocation left open items (`unresolved` or `user_decision`
  non-zero), the effective HEAD is unchanged, and `## Resume Answer` holds no
  answer line, the controller is required to return
  `BLOCKED: previous invocation left <n> open items and the effective HEAD is
  unchanged; resume with answers` — "never re-run and never synthesize". The
  orchestrator reads `BLOCKED` as a major error and stops the run.

So a substantively correct return, whose only defect is a sentence of
narration above the marker, can end an unattended run. The narration is not
noise: in the Phase 4 case it explained why the controller had deliberately
left a defect uncommitted (a commit at that point would have moved the
effective HEAD past the completion marker and silently reopened the gate).
The design does not preserve that text anywhere new — it stays where it
already is, in the session transcript of the dispatch, readable by the user;
the orchestrator consumes only the contract fields, as it does today.

**The second cost, on the hook side — measured, not assumed.** A blocked
return does not hang the dispatch. Probe run 2026-09-06: one throwaway
`general-purpose` subagent was dispatched with a self-contained prompt whose
only instruction was to end its turn with `I finished by using
writing-plans.` — an action verb plus a skill name, no marker. Observation:
`blocked once, then resumed; the dispatch continued after one extra turn`
(the dispatch returned in about 6 seconds). So the cost of a false block is
one extra subagent turn plus the hook's redo instruction, which reads *"Redo
your assigned task using only your core tools"* (`hooks/subagent-guard.js:136`).
For a throwaway probe that costs a turn. For a controller that has already
run a review round and made fix commits, an instruction to redo the assigned
task is an instruction to repeat work that is already on disk — the harm is
duplicated work, not a stall.

Two statements in the repository claim otherwise and are corrected by this
design: `skills/orchestrating-development/SKILL.md` "## Guard Interaction"
says an unmarked return would "hang the dispatch, and stall the unattended
run", while the same file's "## Lost returns" paragraph (`:1404-1406`)
already describes the observed behaviour — *"the fork spends another turn
rewriting — the notice still arrives, later"*. The probe supports the second.

## Scope

Four changes.

1. **Return contract** (`skills/orchestrating-development/SKILL.md:162`). The
   orchestrator accepts a return when a line whose surrounding whitespace is
   removed **equals** `<!-- orchestration report -->` is among the **first 10
   non-blank lines** of the final message. Blank lines are skipped and do not
   consume the budget. When more than one such line exists, the first begins
   the report. Everything above it is ignored. The leading token is on the
   first non-empty line below it. The 15-line cap counts from the marker
   line, which is line 1 of the 15.
2. **Guard exemption** (`hooks/subagent-guard.js`). A message is exempt when
   one of its first 10 non-blank lines, with leading whitespace removed,
   **starts with** one of the three known markers. One predicate serves all
   three markers. The three block comments above the marker constants, which
   each end *"anything after the start of the message does not count"*
   (`:60`, `:67`, `:74`), and the file's opening block comment, are rewritten
   to state the new rule.
3. **Documentation of the exemption**, so that no file states a rule the hook
   no longer follows. **Seven** passages describe it as "opening with" the
   marker:
   - `skills/orchestrating-development/SKILL.md` "## Guard Interaction"
   - `skills/orchestrating-development/SKILL.md:1404-1406` ("## Lost
     returns", inside `## In-run rulings`) — the same edit corrects the
     "hang" claim of the Guard Interaction section against the probe above
   - `skills/multi-doc-review/SKILL.md:502`
   - `skills/multi-code-review/SKILL.md:1860`
   - `skills/researching-prior-art/SKILL.md:427` (an accepted-residual-risk
     paragraph whose scope widens with the predicate) and `:611`
   - `docs/FORK-IMPROVEMENTS.md:203`

   **Constraint on the two orchestrating-development edits:**
   `tests/in-run-rulings/run-tests.sh:793-811` ranges between the headings
   `## Guard Interaction` and `## Prompt Templates` and asserts three
   fragments inside it — the two fork sentences and the exact spelling
   `<!-- multi-review report -->`. Both headings and all three fragments must
   survive. The Lost-returns paragraph sits in a second ranged region of the
   same suite; its bounded-loss sentences (`:842` and around it) are not
   touched by this change.
4. **Tests**: replace the three strictness assertions in
   `tests/codex/test-subagent-guard.js` that the change reverses, add
   boundary assertions on the new predicate, and add a wording-contract
   assertion on the new Return-contract sentence to
   `tests/orchestrating-development/run-tests.sh`.

## Non-goals

- **Row 9's alternative fix — "make the retry path synthesize from the
  log".** Rejected. Deviation 2's `BLOCKED` is deliberate protection: an
  invocation that ended with open items must not be reported as finished
  without the answers to those items. Widening synthesis to that case would
  let a run report `REVIEW_DONE` over unanswered findings. Change 1 narrows
  the trigger instead: a correct return whose marker is within the window is
  never called malformed, so the retry never runs for it.
  **Residual risk, stated rather than removed:** a return with 10 or more
  non-blank lines above the marker, or with no marker line at all, is still
  malformed, still retried, and in Phase 4 can still meet Deviation 2 and
  stop the run. The three recorded occurrences are all inside the new window;
  a fourth of a different shape is not covered by this design.
- **The four controller prompt templates**
  (`plan-writer-prompt.md`, `doc-review-loop-prompt.md`,
  `batch-controller-prompt.md`, `code-review-loop-prompt.md`). Each keeps its
  "First line exactly: `<!-- orchestration report -->`" instruction and its
  `## Return (final message, 15 lines max)` heading. The tolerance is
  receiver-side only: controllers keep being told to emit the canonical
  shape, and the orchestrator stops punishing a small deviation. A tolerated
  return of 9 preamble lines plus a 15-line report therefore satisfies the
  receiver while exceeding what its own template asked for; that divergence
  is accepted.
- **The lost-return rule of `## In-run rulings`
  (`SKILL.md:1411-1413`).** It keys on the *presence* of the marker line in a
  fork's completion notice, not on its position, so this change does not
  touch it: a notice with the marker anywhere is not lost, exactly as today.
  Only the neighbouring sentence describing the *hook's* exemption changes
  (Scope item 3).
- **The skill-side usability rules of the other markers.**
  `skills/multi-code-review/SKILL.md:602`,
  `skills/multi-doc-review/SKILL.md:114`,
  `skills/researching-prior-art/research-prompt.md:164` and
  `controller-prompt.md:126`/`:233` keep requiring the marker as a report's
  first line. Only the hook's exemption widens for those markers; what makes
  a report *usable* is untouched.
- **Hook wiring files.** `subagent-guard.js` is registered in exactly two
  places: `hooks/hooks.json` (`SubagentStop`) and `plugin.universal.yaml`
  (line 86); it appears in neither `hooks/codex-hooks.json` nor
  `hooks/hooks-cursor.json`, and `hooks/codex/` holds no subagent adapter
  (verified 2026-09-06 by grep over all four files and a listing of
  `hooks/codex/`). That Codex has no `SubagentStop` event at all is this
  repository's own recorded platform fact — `CLAUDE.md`, Constraints:
  *"Codex has only partial hook parity — no `PostToolUse(Edit|Write|Skill)`,
  `SubagentStop`, or pre-execution Bash rewrite."* Only the script body
  changes, not the command line, so no wiring file changes.
- **A new orchestration-log note.** The orchestrator records nothing extra
  when it accepts a return with a preamble. A tolerated return is no longer
  a deviation, so there is nothing to track.
- **Release work** — version bumps, `RELEASE-NOTES.md`, `project-map.md:63`,
  and the row 9 line of `docs/orchestration-issues.md`. Those belong to the
  release step after the pipeline ends, not to the implementation plan.
  `docs/guide/` needs no change: it contains no occurrence of the marker
  (verified 2026-09-06 by grep).

No decision in this design matched the prior-art trigger predicate: no new
dependency, no external library, no version claim. The one external-platform
claim (Codex hook parity) is cited to `CLAUDE.md` above.

## Architecture

Today, one boolean decides both questions:

```
             final message
                   |
       trimStart().startsWith(<any of 3 markers>)
          /                      \
        yes                       no
         |                         |
   hook: exempt            hook: scan for verb+skill → may block (redo turn)
   orchestrator: parse     orchestrator: malformed → retry → maybe BLOCKED
```

After the change each side has its own predicate over the same window — the
**first 10 non-blank lines**:

```
             final message
                   |
      +------------+-------------------------+
      |                                      |
  HOOK: does a line in the window            ORCHESTRATOR: does a line in the
  START WITH any of the 3 markers?           window EQUAL the orchestration
      |                                      marker (that one only)?
   yes -> exempt                                 |
   no  -> verb+skill scan, may block         yes -> parse from the FIRST such
                                                    line; ignore what is above
                                             no  -> malformed -> one retry
```

Three properties make this safe:

1. **Each side only widens.** The hook exempts everything it exempts today
   (today's rule is this rule restricted to the first non-blank line) and
   more. The orchestrator accepts everything it accepts today (a first line
   equal to the marker) and more.
2. **Hook-exempt is a superset of orchestrator-accepted.** A line that equals
   the marker also starts with it, so nothing the orchestrator would parse
   can be blocked by the hook.
3. **The two predicates differ on purpose.** The hook is looser (prefix
   match, any of three markers) because its wrong answer costs a redo turn on
   a controller that may repeat committed work. The orchestrator is stricter
   (whole-line equality, one marker) because it must know exactly where the
   report begins and which line carries the leading token.

The hook is a **leakage detector**, not a contract enforcer. It answers one
question: did this subagent invoke a skill it was not allowed to invoke? The
report contract is enforced by the orchestrator, which can retry and stop
cleanly.

### Why the orchestrator searches only its own marker

A code-review-loop controller reads reviewer returns that open with
`<!-- multi-review report -->` and can legitimately quote that line in its
preamble. If the orchestrator started parsing at any marker line, such a
return would be parsed from the reviewer marker, find no leading token below
it, and be judged malformed — the exact failure this design removes. Lines
equal to the other two markers are ordinary preamble text to the
orchestrator.

### Why a bounded window and not the whole message

Searching the whole message would be simpler and is wrong. Reviewers of *this*
repository read `skills/orchestrating-development/` and quote the marker
inside their findings; the hook's own comment records the reason for the
restriction — *"anything after the start of the message does not count."* A
whole-message search would exempt any report that happens to quote a marker
line anywhere, including a genuinely leaking one. The exemption must stay a
property of the message's opening.

### Why 10 non-blank lines

10 is a judgement call, not a derived number. Its evidence is the shape of
the three recorded occurrences — a sentence, a short paragraph, a Self-Review
summary — none of which needs more than a handful of lines. Two properties
bound the choice from either side:

- Too small (1, as today) breaks on exactly those three returns.
- Too large weakens the exemption's usefulness as a prefix property: the
  further into a message the search runs, the more likely it is to reach
  quoted text rather than a report's own opening.

Blank lines are skipped so that the rule cannot be defeated by formatting —
today's `trimStart()` already ignores any number of leading blank lines, and
counting them would take that away.

The main protection against a quoted marker is **position, not equality**: a
quoted marker inside a finding is almost always preceded on its line by list
punctuation or an id (`- [C1] …`), so it neither starts the line nor equals
it. A `multi-review` report can reach its first finding at about line 8,
inside the window, and that is harmless for this reason.

### Why the hook gains no second condition

An obvious strengthening — also require the line after the marker to carry a
known leading token (`PLAN_READY`, `BATCH_COMPLETE`, `REVIEW_DONE`,
`BLOCKED`) — is rejected. It would create a new way for the hook to block a
genuine controller return. Measured cost of a false block (probe above): one
extra turn plus a redo instruction that a controller may act on by repeating
committed work. Measured cost of a missed leak: one wasted subagent turn. The
first is worse, so the hook's exemption only ever widens.

### Why the same predicate serves all three markers

`REVIEW_REPORT_MARKER` and `RESEARCH_REPORT_MARKER` sit in the same `if` and
have the same failure mode. Leaving them strict while the orchestration marker
widens would be an inconsistency with no reason behind it. The visible effect
of widening them is an improvement: a reviewer report with a preamble returns
instead of being blocked into a redo turn, and it is then handled by the
defined unusable-report path — one identical retry first, and `inconclusive`
only when no reviewer of the round returns a usable report
(`skills/multi-code-review/SKILL.md:602-607`,
`skills/multi-doc-review/SKILL.md:114-118`).

## Interfaces

Normative content below; exact prose is the plan's.

### The Return contract bullet (`SKILL.md`, Controller Dispatch Rules)

Replaces "first line exactly `<!-- orchestration report -->` (guard
exemption); leading token on the next line; hard cap 15 lines". The amended
bullet must state all of:

1. The controller is told to make the marker its first line (the templates
   say so and do not change).
2. A return is accepted when a line whose surrounding whitespace is removed
   equals `<!-- orchestration report -->` and is among the **first 10
   non-blank lines** of the final message. Blank lines are skipped and do not
   consume the budget.
3. Only that marker is searched for. A line equal to another skill's marker
   is ordinary preamble.
4. When more than one such line is present, the **first** one begins the
   report. Everything above it is ignored, and is not a reason to retry.
5. The leading token is on the first non-empty line below that marker line.
6. The 15-line cap counts from the marker line, which is line 1 of the 15.
   The cap is an instruction to the controller, not a receiver-side test:
   **exceeding it is not a malformed condition** — the malformed list of
   item 7 is closed, as it is today.
7. Malformed is unchanged otherwise: no marker line in the window, or no
   leading token, or any consumed field (`tasks=`, per-task numbers,
   `rounds=`, `outcome=`, `unresolved=`, `user_decision=`, `fixes=`) absent
   or unparseable. An unparseable stop-rule field never defaults to 0.
   Malformed or controller error → one identical retry; second failure →
   major error.

### The guard predicate (`hooks/subagent-guard.js`)

One function replacing the three-way `trimmedMessage.startsWith(...)` test:

- Input: the raw `last_assistant_message`.
- Walk its lines in order; skip lines that are empty after trimming; stop
  after 10 non-blank lines have been examined.
- Trim each examined line's surrounding whitespace, including a trailing
  `\r`, so a CRLF message behaves the same.
- Exempt when such a line **starts with** `REVIEW_REPORT_MARKER`,
  `ORCHESTRATION_REPORT_MARKER` or `RESEARCH_REPORT_MARKER`. Prefix, not
  equality: a first line of `<!-- orchestration report --> REVIEW_DONE …` is
  exempt today and must stay exempt.
- A line that contains a marker but does not start with it — a finding line,
  a sentence quoting the marker — does not exempt.
- The window constant is named (for example `MARKER_SEARCH_LINES = 10`),
  declared once, and commented with the reason above.
- The three block comments above the marker constants (`:60`, `:67`, `:74`)
  and the file's opening block comment replace their "opens with … anything
  after the start of the message does not count" wording with the new rule.
- Everything else in the hook is unchanged: the violation patterns, the
  logging, the block reason, the parse-failure fallback that allows the stop.

### The guard prose in the seven documented places

`skills/orchestrating-development/SKILL.md` "## Guard Interaction": the
sentence "the guard exempts messages opening with that marker" becomes a
statement of the widened rule, and its "hang the dispatch, and stall the
unattended run" clause is corrected to what the probe observed — a blocked
return costs an extra turn and a redo instruction, so the marker instruction
stays mandatory in the four templates for cost, not for deadlock. The
heading, the following `## Prompt Templates` heading, the two fork sentences
and the exact spelling `<!-- multi-review report -->` all stay, because
`tests/in-run-rulings/run-tests.sh` ranges on them.

The six other passages (Scope item 3) get the same correction in their own
words. `skills/researching-prior-art/SKILL.md:427` states an accepted
residual risk whose scope widens with the predicate: it must say that a
message carrying a marker at the start of one of its first 10 non-blank lines
is exempt, not only one opening with it.

## Error handling

Two enforcement sides: the hook decides whether the subagent may stop, the
orchestrator decides whether the return is usable. "Window" means the first
10 non-blank lines.

| Case | Hook | Orchestrator |
|---|---|---|
| Marker alone on line 1 | exempt | parsed. Unchanged from today. |
| Marker plus text on line 1 (`<!-- orchestration report --> REVIEW_DONE …`) | exempt (prefix match, as today) | not a marker line: malformed → one identical retry. Unchanged from today. |
| Any number of blank lines, then the marker | exempt (blanks skipped, as today) | parsed. Unchanged from today. |
| Marker alone on lines 2–10 of the window, prose above | exempt | parsed from that line; no retry, no log note. **This is the fix.** |
| Two lines equal to the marker inside the window | exempt | parsed from the first one |
| A `<!-- multi-review report -->` line above the orchestration marker, both in the window | exempt | preamble; parsed from the orchestration marker |
| Marker below the window | not exempt: the verb+skill scan runs and may block, costing a redo turn | malformed → one identical retry. Unchanged from today. |
| No marker at all | not exempt: same scan, same redo cost | same as the row above. Unchanged from today. |
| Marker present, a consumed field unparseable | exempt | malformed → one identical retry. Unchanged from today. |
| Report longer than 15 lines from the marker | exempt | accepted; the cap is not a malformed condition. Unchanged from today. |
| Marker quoted mid-line inside a finding | not a marker line; no exemption | not a marker line; unchanged from today |
| Message with fewer than 10 non-blank lines | only the lines that exist are examined | same |
| Hook input unparseable | stop allowed | not applicable |

## Testing strategy

All tests are fast unit or wording-contract suites. No behavioural suite is
needed, and none may be run against this clone while the review loop is
committing to it (`docs/orchestration-issues.md` Case 004, worklist row 4).

**`tests/codex/test-subagent-guard.js`** — three existing assertions state
the strictness the change reverses and must be replaced, not merely joined:

- `:269` `Marker mid-message does not exempt` (multi-review marker)
- `:335` `orchestration marker after the first line does not exempt`
- `:383` `Research marker mid-message does not exempt`

Their replacements, plus the new boundary cases:

1. Marker alone on line 2, verb+skill body → exempt.
2. Marker alone on the 10th non-blank line, verb+skill body → exempt (the
   boundary that must pass).
3. Marker alone on the 11th non-blank line, verb+skill body → blocked (the
   boundary that must fail).
4. Twelve blank lines, then the marker, then a verb+skill body → exempt
   (blank lines do not consume the window; today's `trimStart()` behaviour is
   preserved).
5. `<!-- orchestration report --> REVIEW_DONE rounds=2` as line 1, verb+skill
   body → exempt (prefix match; the case the change must not narrow).
6. A line containing the marker after other text (`- [C1] the
   <!-- orchestration report --> marker …`), inside the window, verb+skill
   body → blocked.
7. Leading whitespace before a marker on line 3 → exempt.
8. The same widened behaviour, and the same 11th-non-blank-line boundary, for
   `<!-- multi-review report -->` and `<!-- research report -->`.
9. Two marker lines within the window → exempt.
10. The remaining first-line, no-marker and whitespace cases keep passing
    unchanged.

Every exemption test's body must contain a verb+skill pair, so that it fails
on the unmodified guard rather than passing vacuously — the convention the
current file already states at its whitespace test.

**`tests/orchestrating-development/run-tests.sh`** — one assertion over the
Return contract bullet that pins **both** halves of the new rule, so that a
later edit cannot restore either extreme: a fragment carrying the tolerance
(the window's size and the words "non-blank") **and** a fragment carrying the
exact marker spelling `<!-- orchestration report -->`. The plan names the two
exact fragments; an assertion that searches only for the number `10` passes
vacuously and is not acceptable.

**Regression** — the six fast suites listed in `CLAUDE.md` other than the two
above must pass unchanged. `tests/in-run-rulings/run-tests.sh` is one of the
six and ranges on two regions this change edits; it is the suite most likely
to break by accident.

## Acceptance

1. `bash tests/codex/run-unit-tests.sh` passes, with the new guard cases.
2. `bash tests/orchestrating-development/run-tests.sh` passes, with the new
   wording assertion — which is also the executable form of "the skill and
   the hook state the same rule".
3. The other six fast suites pass unchanged, `tests/in-run-rulings` included.
4. No file still describes the guard exemption as applying only to a message
   that opens with a marker. Command and expected result:

   ```
   grep -rn "opening with\|opens with" skills/ hooks/ docs/FORK-IMPROVEMENTS.md
   ```

   Every remaining hit must be unrelated to the guard exemption; no hit may
   describe `hooks/subagent-guard.js`. The seven passages of Scope item 3 are
   the checklist.

Worklist row 9 closes when this merges. Its "Seen once" wording is corrected
to three occurrences in the same edit that removes the row.

## Failure-mode check

- **A leaking subagent hides behind a marker line at line 7.** Possible, and
  possible today at line 1 as well. The hook is a second layer; the first is
  the prompt instruction not to invoke skills. The change moves the bar from
  "the first non-blank line" to "one of the first 10 non-blank lines", which
  is not a bar an accidental leak clears — it requires emitting the exact
  marker text at the start of a line.
- **A controller emits a narrative report with the marker at line 6.** Still
  accepted, and the fields still have to parse. If they do not, it is
  malformed on the field rule, which is the rule that matters.
- **A controller writes 12 non-blank lines of narration.** Not covered:
  malformed, retried, and in Phase 4 possibly `BLOCKED` (Non-goals, residual
  risk). The design narrows the failure window; it does not close it.
- **A blocked controller obeys the redo instruction literally** and repeats a
  review round it has already committed. This is the real cost of a false
  block (probe above), and it is why the hook only ever widens. The change
  reduces how often it can happen; it does not change the instruction.
- **The 15-line cap becomes ambiguous.** Removed by stating that the cap
  counts from the marker line and that exceeding it is not a malformed
  condition.
- **CRLF line endings on Windows Git Bash.** Handled by trimming each line
  before comparing.

## Rollout

Implementation lands on a feature branch. The release step afterwards bumps
`VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
the `plugin.universal.yaml` meta version, the `README.md` version badge and
its two lineage ranges, adds a `RELEASE-NOTES.md` entry with the
Problem/Change/Effect summary, updates `project-map.md:63`, and removes
worklist row 9. The installed plugin must be reinstalled before any
behavioural test.

## Amendments

None.
