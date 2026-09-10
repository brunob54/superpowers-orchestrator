# Execution Readiness Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Run the pre-flight plan-conflict criteria, extended by three checks, as reviewer passes inside the plan review gate — once before the rotating rounds and once after them, each repeated until a pass changes nothing — so that decidable plan conflicts are found and fixed at the gate instead of at the Phase 3 pre-flight.

**Spec:** `docs/superpowers-orchestrator/2026-09-10-execution-readiness-pass/specs/execution-readiness-pass-design.md`

**Architecture:** All work is text in Markdown skill files plus assertions in three pure-bash contract suites; no runtime code exists for this feature. `skills/multi-doc-review/SKILL.md` gains one lens cell (`Execution readiness`), two Procedure subsections (the readiness sequences and their triage), one Review Log Format subsection (the readiness entry shape, the fields a controller reads, the completeness and resume rules), one sentence in the N parameter, and one completion-report paragraph. `skills/multi-doc-review/reviewer-prompt.md` changes three lines outside its fenced prompt so the existing placeholders admit the new lens and the new round label. The two plan gates (`skills/writing-plans/SKILL.md`, Phase 0 of `skills/orchestrating-development/SKILL.md`) gain the same two sentences; Phase 2 of the orchestrator stops skipping itself when `N_plan = 0` and its controller template accepts that value. Every change is pinned by a string assertion in `tests/reviewer-templates/run-tests.sh`, `tests/review-gates/run-tests.sh` or `tests/orchestrating-development/run-tests.sh`.

**Tech Stack:** Markdown (skill bodies, prompt templates, guide and release documentation), Bash with `grep`/`awk` (the three contract suites), JSON and YAML (the release metadata files).

**Assumptions:**

- Assumes `skills/multi-doc-review/SKILL.md` is 788 lines when Task 1 starts — measured against the working tree while this plan was written. Will NOT hold if another change lands in that file first; the budget check of Global Constraint 1 then measures the real file against the fixed maximum of 938 lines, and the prose this plan adds must be tightened until it fits.
- Assumes the two strings this plan copies still exist in `skills/subagent-driven-development/SKILL.md` (`tasks that contradict each other or the plan's Global Constraints`, line 205 today) and that the second one also exists in `skills/subagent-driven-development/task-reviewer-prompt.md` (line 142 today, wrapped across two physical lines). Will NOT hold if those files are edited; this plan modifies neither (Global Constraint 2), and Task 1's test asserts both sources still carry the strings, so a drift fails the suite instead of passing silently.
- Assumes the test suites run under `bash` with `grep`, `awk`, `sed`, `diff` and `git` on `PATH`, as the existing suites already do. Will NOT work on a shell that is not bash.
- Assumes every file in this repository is UTF-8 and that the em dash (`—`), the multiplication sign (`×`) and the en dash (`–`) survive as literal bytes in test needles, as they already do in `tests/review-gates/run-tests.sh`. Will NOT hold on a checkout that rewrites encodings.
- Assumes the reader of every rule added to a skill body is a language model reading rendered context, so no automated test can verify that a controller *obeys* a rule — the suites verify only that the rule's text is present. Will NOT catch a controller that reads the rule and ignores it; the spec's acceptance measure (the next orchestration run of this repository) is the only check of obedience, and it is outside these suites.

**Global Constraints:**

1. **`skills/multi-doc-review/SKILL.md` must be at most 938 lines after every task.** The file is 788 lines before this plan and this design's additions to it are capped at 150 lines. The contract test asserts the maximum of 938 and names 7.14.0 as the release that set the figure. When a reference body in this plan makes the file exceed 938 lines, tighten the prose of the paragraphs that task added until the count fits; never drop a string another task's assertion pins.
2. **No change to `skills/subagent-driven-development/SKILL.md`, to `skills/orchestrating-development/batch-controller-prompt.md`, or to the Phase 3 pre-flight behaviour.** The Pre-Flight Plan Review remains the net for what the reviewers miss.
3. **No change to the fenced prompt of `skills/multi-doc-review/reviewer-prompt.md`.** The pass uses the existing placeholders. Only three lines outside the fence change: the header sentence naming the lens source, the `[LENS_NAME]` note and the `[ROUND]` note.
4. **No change to Deviation 3 of `skills/orchestrating-development/doc-review-loop-prompt.md` and no change to the meaning of `unresolved`.** A readiness finding never produces an `unresolved:` line, in any caller.
5. **No new key in the `<superpowers-defaults>` block and no environment variable.** The pass cap is a constant of the skill, and there is no switch that turns the readiness sequence off.
6. **No new token in the `REVIEW_DONE` return contract.** `REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>` keeps its tokens and their meanings; `rounds` counts rotating rounds only.
7. **No edit to `docs/orchestration-issues.md`.** The file is local and untracked.
8. **Every edit to `skills/orchestrating-development/doc-review-loop-prompt.md` keeps exactly one line matching a bracketed single capital letter, byte-identical.** The orchestrating-development and fill-prompt contract tests both assert it, so all new wording in that template is prose.
9. **No readiness pass for `spec` or `general` documents.** Both sequences run for plan documents only.
10. **Contract tests only; no behavioural suite is run for acceptance.** String assertions run on whitespace-normalised text — `assert_folded_contains` in `tests/reviewer-templates/run-tests.sh`, the `*_NORM` files in `tests/review-gates/run-tests.sh`. `tests/writing-plans/run-tests.sh` and `tests/fill-prompt/run-tests.sh` are run unchanged and must stay green.
11. **Target version 7.14.0.**

---

## File Structure

| File | Responsibility in this change |
|---|---|
| `skills/multi-doc-review/SKILL.md` | The whole readiness feature as the controller reads it: the lens cell, the two Procedure subsections, the log-entry shape with the completeness and resume rules, the N sentence, the completion-report items. |
| `skills/multi-doc-review/reviewer-prompt.md` | Three lines outside the fenced prompt, so the existing placeholders admit the new lens name and the new round label. |
| `skills/writing-plans/SKILL.md` | Two sentences at the plan gate: readiness runs at N = 0, and its cost. |
| `skills/orchestrating-development/SKILL.md` | The same two sentences in Phase 0; the `N_plan = 0` narrowing in Phase 0 and in the Orchestration Log Format section; the Phase 2 dispatch and its log line. |
| `skills/orchestrating-development/doc-review-loop-prompt.md` | The `[N_PLAN]` range and Deviations 1 and 2. |
| `tests/reviewer-templates/run-tests.sh` | Every wording pin on `multi-doc-review` and on the doc-review-loop template, plus the size budget. |
| `tests/review-gates/run-tests.sh` | The two gate sentences, present at the plan gates and absent from the spec gate. |
| `tests/orchestrating-development/run-tests.sh` | Phase 2 no longer carries its `N_plan = 0` skip branch. |
| `docs/guide/README.md`, `docs/FORK-IMPROVEMENTS.md`, `docs/REVIEW-PROCESS-COMPARISON.md` | User-facing description of the new pass, its cost and its limit. |
| `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md` | The 7.14.0 release. |

Task order follows the reading order of `skills/multi-doc-review/SKILL.md` (lens cell → procedure → triage → log format), then its size budget, then the callers, then the documentation, then the release. Each task is a self-contained vertical slice: one wording change plus the assertion that pins it.

---

### Task 1: Execution readiness lens cell and the reviewer-template notes

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Modify: `skills/multi-doc-review/reviewer-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the cell's `plan:` text is the only one that reviews anything — the `spec:` and `general:` lines say `not used`, so a readiness pass over a spec document or a general document is excluded here and is excluded again by the procedure of Task 2. This task does not make the cell reachable: nothing dispatches a readiness reviewer until Task 2 adds the sequences. It also does not handle a plan that is missing a spec, a Global Constraints block or Contract fields — the fallback that removes a clause from the filled instructions is Task 2.

**Contract:**

> **Contract:** the `**Execution readiness**` cell in the "Lens Instructions" section of `skills/multi-doc-review/SKILL.md`
> - Must convey: read the plan as the agent that will execute it; report every conflict that would stop execution; quote both sides verbatim; run five numbered checks; for check (5) report one finding per Global Constraints entry and end with a coverage block; the other lenses' subjects are out of scope.
> - Invariants: the cell's first line stands after the `**Adversarial failure modes**` cell and before the `## Review Log Format` heading; its `plan:` text carries `tasks that contradict each other or the plan's Global Constraints` and `(a test that asserts nothing, verbatim duplication of a logic block)`, both of which still appear unchanged in `skills/subagent-driven-development/`; the five checks are numbered `(1)` to `(5)`; the coverage shape `coverage: GC<k> — <n> sites checked` appears; the `spec:` and `general:` lines both carry `not used`.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 12.

> **Contract:** the placeholder notes of `skills/multi-doc-review/reviewer-prompt.md`
> - Must convey: `[LENS_NAME]` and the file's header sentence admit `Execution readiness` beside the Lens Rotation table; `[ROUND]` admits a readiness pass label as well as a round number.
> - Invariant: the fenced prompt body — every line between the `  prompt: |` line and its closing fence — is byte-identical to the version before this task.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 12, plus `git diff -U0 -- skills/multi-doc-review/reviewer-prompt.md` showing no changed line inside the fence.

- [ ] **Step 1: Write failing test**

Add these two variable declarations to `tests/reviewer-templates/run-tests.sh`, directly after the `WP_SKILL="$ROOT/skills/writing-plans/SKILL.md"` line:

```bash
SDD_SKILL="$ROOT/skills/subagent-driven-development/SKILL.md"
SDD_TASK_REVIEWER="$ROOT/skills/subagent-driven-development/task-reviewer-prompt.md"
```

Then add this section directly before the final `echo` / `bold "Results: ..."` block of the same file:

```bash
bold "12. Execution readiness lens cell"
# The cell is the last one in Lens Instructions, so the extractor stops at
# the next top-level heading as well as at the next bold cell title.
READINESS_CELL="$WORK/readiness-cell.txt"
awk '
  $0 == "**Execution readiness**" { inlens = 1; next }
  inlens && /^\*\*/ { exit }
  inlens && /^## / { exit }
  inlens { print }
' "$DOC_SKILL" > "$READINESS_CELL"
if [ -s "$READINESS_CELL" ]; then
  ok "multi-doc-review SKILL.md: Execution readiness cell extract is non-empty"
else
  bad "multi-doc-review SKILL.md: Execution readiness cell extract is empty"
fi
ADV_CELL_LINE="$(first_line_of "$DOC_SKILL" '**Adversarial failure modes**')"
RDY_CELL_LINE="$(first_line_of "$DOC_SKILL" '**Execution readiness**')"
LOG_FORMAT_LINE="$(first_line_of "$DOC_SKILL" '## Review Log Format')"
if [ -n "$ADV_CELL_LINE" ] && [ -n "$RDY_CELL_LINE" ] && [ -n "$LOG_FORMAT_LINE" ] &&
   [ "$RDY_CELL_LINE" -gt "$ADV_CELL_LINE" ] && [ "$RDY_CELL_LINE" -lt "$LOG_FORMAT_LINE" ]; then
  ok "Execution readiness cell sits between the Adversarial cell and Review Log Format (line $RDY_CELL_LINE)"
else
  bad "Execution readiness cell is misplaced (adversarial='$ADV_CELL_LINE' readiness='$RDY_CELL_LINE' log-format='$LOG_FORMAT_LINE')"
fi
# The two strings the cell copies. Each is asserted in the cell AND in the
# file it was copied from, so drift on either side turns this suite red.
PREFLIGHT_CRITERION="tasks that contradict each other or the plan's Global Constraints"
RUBRIC_PARENTHETICAL='(a test that asserts nothing, verbatim duplication of a logic block)'
assert_folded_contains "Execution readiness cell: pre-flight criterion" "$READINESS_CELL" "$PREFLIGHT_CRITERION"
assert_folded_contains "subagent-driven-development SKILL.md: still carries the pre-flight criterion" "$SDD_SKILL" "$PREFLIGHT_CRITERION"
assert_folded_contains "Execution readiness cell: rubric-defect parenthetical" "$READINESS_CELL" "$RUBRIC_PARENTHETICAL"
assert_folded_contains "subagent-driven-development SKILL.md: still carries the rubric-defect parenthetical" "$SDD_SKILL" "$RUBRIC_PARENTHETICAL"
assert_folded_contains "task-reviewer-prompt.md: still carries the rubric-defect parenthetical" "$SDD_TASK_REVIEWER" "$RUBRIC_PARENTHETICAL"
for numbered in '(1) tasks that contradict' \
                '(2) anything the plan explicitly mandates' \
                '(3) a task clause that contradicts' \
                '(4) a mandated body' \
                '(5) for each entry of the plan'; do
  assert_folded_contains "Execution readiness cell: numbered check '$numbered'" "$READINESS_CELL" "$numbered"
done
assert_folded_contains "Execution readiness cell: one finding per Global Constraints entry" "$READINESS_CELL" 'report ONE finding per Global Constraints entry'
assert_folded_contains "Execution readiness cell: coverage line shape" "$READINESS_CELL" 'coverage: GC<k> — <n> sites checked'
assert_file_contains "Execution readiness cell: spec line is not used" "$READINESS_CELL" '- spec: not used'
assert_file_contains "Execution readiness cell: general line is not used" "$READINESS_CELL" '- general: not used'
assert_file_contains "doc-review template: header sentence admits the readiness lens" "$DOC_PROMPT" 'or `Execution readiness` for a readiness pass'
assert_file_contains "doc-review template: [LENS_NAME] note admits the readiness lens" "$DOC_PROMPT" "\`[LENS_NAME]\` — REQUIRED: lens name from SKILL.md's Lens Rotation, or \`Execution readiness\`"
assert_file_contains "doc-review template: [ROUND] note admits a readiness label" "$DOC_PROMPT" '`[ROUND]` — REQUIRED: round number, or a readiness pass label (display only)'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: Execution readiness cell extract is empty" and with the three `doc-review template` needles reported missing.

- [ ] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, insert this cell into the "Lens Instructions" section, after the last line of the `**Adversarial failure modes**` cell and before the `## Review Log Format` heading, separated from both by one blank line:

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

In `skills/multi-doc-review/reviewer-prompt.md`, change exactly three lines outside the fenced prompt.

Replace the sentence that today reads `M reviewers per round (default 1), all with this identical prompt; the lens comes from SKILL.md's Lens Rotation table.` with:

```markdown
Use this template when dispatching a multi-doc-review reviewer subagent. M
reviewers per round (default 1), all with this identical prompt; the lens
comes from SKILL.md's Lens Rotation table, or `Execution readiness` for a
readiness pass. The reviewers are not told that other reviewers exist.
```

Replace the two placeholder lines under `**Placeholders:**` with:

```markdown
- `[ROUND]` — REQUIRED: round number, or a readiness pass label (display only)
- `[LENS_NAME]` — REQUIRED: lens name from SKILL.md's Lens Rotation, or `Execution readiness`
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `git diff -U0 -- skills/multi-doc-review/reviewer-prompt.md`
Expected: only the three lines above appear as changed, none of them between the `  prompt: |` line and its closing fence.

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 938 (Global Constraint 1).

- [ ] **Step 5: Commit**

```bash
git add skills/multi-doc-review/SKILL.md skills/multi-doc-review/reviewer-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-doc-review): add the Execution readiness lens cell" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 1/10"
```

---

### Task 2: The readiness sequences in the procedure

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the sequences run for plan documents only — a `spec` or `general` document is excluded, and so is any caller that does not run this skill's Procedure. The post-sequence is excluded when N is 0, because there is no last rotating round to run after. This task does not define how a readiness finding is disposed of (Task 3), what a readiness log entry looks like or how a controller reads one back (Task 4), and it does not change any gate's wording (Tasks 6 and 7).

**Contract:**

> **Contract:** the `Readiness sequences (plan documents only)` subsection of the Procedure in `skills/multi-doc-review/SKILL.md`
> - Must convey: a pre-sequence runs before rotating round 1 and a post-sequence after the last rotating round when N ≥ 1; a fresh invocation always runs both, a re-run under the `another pass requested` marker included; a pass is one `Execution readiness` review of M reviewers with the same validation, consolidation and triage as a round; a pass is settled only when it applied no Critical and no Important finding and all M reviewers were usable; a sequence runs at most three passes, one when the plan has no locatable spec; a report without a complete coverage block is unusable; a missing plan structure removes its check and writes a header note.
> - Invariants: the subsection carries the strings `pre-sequence`, `post-sequence`, `at most three passes`, `Readiness passes are not counted in N and are not part of the two-consecutive-clean-rounds streak.` and `The host self-review runs after the post-sequence.`; the three fallback rows name check (3), check (5) and check (4) with their note lines; the subsection never spells `**Execution readiness**` in bold, so Task 1's placement check keeps resolving to the lens cell.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 13.

> **Contract:** the N parameter sentence of `skills/multi-doc-review/SKILL.md`
> - Must convey: N = 0 skips the rotating loop, and for a plan document the readiness pre-sequence still runs.
> - Invariant: the existing sentence `N = 0 skips the loop and logs a \`skipped\` entry.` is unchanged and the new sentence follows it.
> - Verification: the same suite section asserts `For a plan document, the Execution readiness pre-sequence still runs.` and the unchanged sentence together.

- [ ] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 12:

```bash
bold "13. Readiness sequences in the multi-doc-review procedure"
for needle in 'pre-sequence' \
              'post-sequence' \
              'at most three passes' \
              'Readiness passes are not counted in N and are not part of the two-consecutive-clean-rounds streak.' \
              'The host self-review runs after the post-sequence.' \
              'coverage:` line for any entry' \
              '**Note:** clause-vs-spec check not run — no locatable spec' \
              '**Note:** Global Constraints sweep not run — no block' \
              '**Note:** Contract check not run — no Contract fields' \
              'For a plan document, the Execution readiness pre-sequence still runs.'; do
  assert_folded_contains "multi-doc-review SKILL.md: procedure carries '$needle'" "$DOC_SKILL" "$needle"
done
assert_folded_contains "multi-doc-review SKILL.md: the N parameter keeps its N=0 sentence" "$DOC_SKILL" 'N = 0 skips the loop and logs a `skipped` entry.'
# The readiness prose must never spell the cell title in bold: section 12
# resolves the cell by the first `**Execution readiness**` line in the file.
READINESS_BOLD_COUNT="$(grep -cF -- '**Execution readiness**' "$DOC_SKILL" | tr -d ' ')"
assert_eq "multi-doc-review SKILL.md: exactly one bold Execution readiness title (the lens cell)" "$READINESS_BOLD_COUNT" "1"
```

`assert_eq` does not yet exist in this suite; add it next to `assert_file_has_line`:

```bash
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: procedure carries 'pre-sequence'" and the other nine needles reported missing.

- [ ] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, in the `**N (round cap):**` bullet of the Parameters section, append one sentence directly after `N = 0 skips the loop and logs a \`skipped\` entry.`:

```markdown
  For a plan document, the Execution readiness pre-sequence still runs.
```

In the Procedure section, insert this paragraph immediately before the paragraph that begins `For each round \`i\` in the range established above`:

```markdown
For a plan document, run the pre-sequence of `Readiness sequences` below
before round 1.
```

Then insert this subsection after the numbered step 5 (`**Convergence check:**`) and before the `**After the loop:**` paragraph:

```markdown
### Readiness sequences (plan documents only)

For a plan document, run a **readiness sequence** before rotating round 1
(the **pre-sequence**) and, when N ≥ 1, a second after the last rotating
round (the **post-sequence**), over the plan as that round's triage left it;
for `spec` and `general` documents neither sequence runs. A fresh invocation
always runs both, a re-run started by the `another pass requested` marker
included. A **readiness pass** is one review dispatched under the lens
`Execution readiness`: M
reviewers filled from `reviewer-prompt.md` with `[LENS_NAME]` =
`Execution readiness`, `[LENS_INSTRUCTIONS]` = that lens's `plan:` cell and
`[ROUND]` = `readiness <pre|post> <p>`, every other placeholder as a
rotating round fills it; then the same validation, consolidation and triage
as a round, and one log entry under its own heading. A pass is **settled**
when it **applied** no Critical and no Important finding and all M reviewers
returned a usable report; any other pass is **open**, an inconclusive pass
included. A sequence runs **at most three passes** and ends at its first
settled pass or at its cap, whichever comes first; the cap is one instead of
three when the plan has no locatable spec. A third pass that is still open
ends the sequence and stops nothing.

`Readiness passes are not counted in N and are not part of the
two-consecutive-clean-rounds streak.` A pre-sequence that applies findings
neither breaks nor starts the streak, and rotating lens selection keeps
using the per-invocation rotating round index. `The host self-review runs
after the post-sequence.` It stays the last edit inside the gate, and when
it finishes you write `**Host self-review:** done` as its own line of the
invocation entry. With N = 0 the rotating loop is skipped and its `skipped`
entry is logged as today, the pre-sequence runs, then the host self-review.

A readiness report that lacks a `coverage:` line for any entry of the plan's
`**Global Constraints:**` block is **unusable**: it is retried once under
the report-validation rule of step 2, and a reviewer still unusable leaves
the pass with fewer than M usable reports, so the pass is open. A missing
sweep costs a retry; it can never end a sequence. When a structure the lens
cell names is missing, remove that clause from `[LENS_INSTRUCTIONS]` and
write a header note directly after the `**Result:**` line of every readiness
entry of this invocation — a header line, not a disposition line:

| Missing | Clause removed | Note line |
|---|---|---|
| no locatable spec | check (3) | `**Note:** clause-vs-spec check not run — no locatable spec` |
| no `**Global Constraints:**` block | check (5) and its coverage block | `**Note:** Global Constraints sweep not run — no block` |
| no task carries `**Contract:**` | check (4) | `**Note:** Contract check not run — no Contract fields` |
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 938 (Global Constraint 1).

- [ ] **Step 5: Commit**

```bash
git add skills/multi-doc-review/SKILL.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-doc-review): run readiness sequences around the rotating rounds" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 2/10"
```

---

### Task 3: Triage of a readiness finding

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** this triage applies to findings of a readiness pass only — a rotating round's findings keep the existing triage of Procedure step 3, including its harness-claim branch. The authority order decides a conflict between two quoted sides; it does not decide a finding that is not a conflict at all (Step 0 rejects it) and it does not amend the spec, a spec-traced Global Constraints entry, an externally pinned `**Exact content:**` body, or a `**Contract:**` invariant that restates an external standard. It does not change `unresolved` in any caller, and it does not tell the orchestrator to stop on an owed conflict.

**Contract:**

> **Contract:** the `Triage of a readiness finding` subsection of `skills/multi-doc-review/SKILL.md`
> - Must convey: verify both sides verbatim before disposing; two authority levels, fixed text and plan text; four conflict shapes with one disposition each; a readiness finding never reaches `unresolved`; an out-of-lens finding is rejected.
> - Invariants: the subsection carries the disposition strings `rejected: not a conflict`, `rejected: plan-mandated`, `rejected: undecidable at this gate` and `out of lens scope`; it carries the sentence `A readiness finding never produces an unresolved: line, in any caller.`; the plan-mandated row says the finding is never amended.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 14.

> **Contract:** the readiness bullet added to the `## Error Handling` section of `skills/multi-doc-review/SKILL.md`
> - Must convey: a readiness pass whose reports are all unusable is inconclusive and open; a readiness entry with a missing or malformed `**Result:**` line is read as open.
> - Invariant: the existing Error Handling bullets are unchanged; the new bullet never uses the word `unresolved`.
> - Verification: the same suite section asserts the bullet's two clauses.

- [ ] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 13:

```bash
bold "14. Triage of a readiness finding"
for needle in 'rejected: not a conflict' \
              'rejected: plan-mandated' \
              'rejected: undecidable at this gate' \
              'out of lens scope' \
              'A readiness finding never produces an unresolved: line, in any caller.' \
              'never amended' \
              'a readiness entry with a missing or malformed'; do
  assert_folded_contains "multi-doc-review SKILL.md: triage carries '$needle'" "$DOC_SKILL" "$needle"
done
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: triage carries 'rejected: not a conflict'" and the other six needles reported missing.

- [ ] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, insert this subsection directly after the `### Readiness sequences (plan documents only)` subsection added by Task 2, and before the `**After the loop:**` paragraph:

```markdown
### Triage of a readiness finding

**Step 0 — verify.** Quote both sides from their files before any
disposition. If either side is not found verbatim, or the higher side does
not state what the finding claims, dispose
`rejected: not a conflict — <side not found>`.

**Step 1 — authority.** **Fixed text**, never amended by this triage: the
spec named on the plan's `**Spec:**` line; a `**Global Constraints:**` entry
that traces to that spec (an entry is not fixed only when it both fails to
trace to the spec and restates the body of an artifact the plan itself
creates or modifies); an `**Exact content:**` body whose reason names a pin
outside the plan; a `**Contract:**` invariant that restates an external
standard. **Plan text**, amendable: everything else.

| Conflict | Disposition |
|---|---|
| fixed text vs plan text | amend the plan side, `applied` |
| plan text vs plan text | amend the side the spec decides against; failing that, the side the Global Constraints block decides against; failing both, `rejected: undecidable at this gate — <both sides>` |
| fixed text vs fixed text | `rejected: undecidable at this gate — spec inconsistent` |
| the plan mandates a rubric defect (check 2) | `rejected: plan-mandated — <text>`, never amended |

`A readiness finding never produces an unresolved: line, in any caller.` A
finding whose application fails is disposed `rejected: undecidable at this
gate`; a finding outside the lens (coverage, ambiguity, feasibility, style)
is rejected with the reason `out of lens scope`. Every `rejected:`
disposition of a readiness pass is listed in the invocation entry's `Owed:`
block.
```

In the `## Error Handling` section of the same file, append this bullet after the existing harness-probe bullet:

```markdown
- Readiness pass whose reports are all unusable (u = 0) → `inconclusive`,
  and the pass is open; a readiness entry with a missing or malformed
  `**Result:**` line is read as open.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 938 (Global Constraint 1).

- [ ] **Step 5: Commit**

```bash
git add skills/multi-doc-review/SKILL.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-doc-review): triage rules for readiness findings" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 3/10"
```

---

### Task 4: Readiness log entries, completeness, resume and the completion report

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the completeness rule decides a plan-document entry only — an entry for a `spec` or `general` document keeps the existing rule untouched, and so does a plan entry written before this release, which owes no readiness pass and no self-review marker. The resume rule covers the four stages of one invocation; it does not decide whether a *new* invocation runs at all, which stays with the once-per-gate step. Two states are excluded on purpose: a readiness heading inside a fenced code block and a `**Result:**` string appearing inside a disposition line are not fields — the existing recognition conditions exclude both. The completion-report items are for the in-session gates; under the `gate: orchestration` invoker the controller writes one note instead, and this task changes no token of `REVIEW_DONE`.

**Contract:**

> **Contract:** the `Readiness entries` subsection of the `## Review Log Format` section of `skills/multi-doc-review/SKILL.md`
> - Must convey: the heading and `**Result:**` shape of a readiness entry; that the rest of the entry is the round-entry body without a `**Converged:**` line; the `Owed:` block; which two fields a controller reads back; the completeness rule for this release and for earlier releases; the resume order.
> - Invariants: the file carries the literal heading line `## Readiness <pre|post> <p> — Execution readiness — <model>`, the `**Result:**` label, the `**Host self-review:** done` line, the sentence `r counts ## Round headings only.`, the word `superseded` for an obsolete entry, and the phrase `has ended` for the sequence-end test; `settled` and `open` are described as compared as whole words.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 15.

> **Contract:** the readiness items of the completion report in the `**After the loop:**` step
> - Must convey: one line per sequence, the applied-conflict list and the owed-conflict list; a report missing them is defective; under the orchestration invoker the controller writes `readiness owed: <n>` instead.
> - Invariants: the three item labels `Readiness pre:`, `Readiness post:` and `Readiness conflicts owed:` appear; the existing `Harness probes owed:` sentence is unchanged; the `REVIEW_DONE` token list is restated without additions.
> - Verification: the same suite section asserts the three labels and `rounds=0 outcome=cap unresolved=0`.

- [ ] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 14:

```bash
bold "15. Readiness log entries, completeness, resume and the completion report"
assert_file_has_line "multi-doc-review SKILL.md: readiness entry heading shape" "$DOC_SKILL" '## Readiness <pre|post> <p> — Execution readiness — <model>'
assert_file_has_line "multi-doc-review SKILL.md: readiness entry result line" "$DOC_SKILL" '**Result:** <settled|open>'
for needle in '**Host self-review:** done' \
              'r counts ## Round headings only.' \
              'open (all inconclusive)' \
              '`Owed:` block' \
              'superseded' \
              'has ended' \
              'compared as whole words' \
              'Readiness pre:' \
              'Readiness post:' \
              'Readiness conflicts owed:' \
              'rounds=0 outcome=cap unresolved=0'; do
  assert_folded_contains "multi-doc-review SKILL.md: log format carries '$needle'" "$DOC_SKILL" "$needle"
done
assert_folded_contains "multi-doc-review SKILL.md: completion report keeps the harness line" "$DOC_SKILL" 'Harness probes owed:'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: readiness entry heading shape (no line exactly: ## Readiness <pre|post> <p> — Execution readiness — <model>)" and the other needles reported missing.

- [ ] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, append one sentence to the end of the **Once per gate** paragraph of the Procedure, after `After user-requested changes at the gate, re-run only the host self-review checklist before taking this step again.`:

```markdown
For a plan document, `Readiness entries` below adds to this completeness rule.
```

Insert this subsection into the `## Review Log Format` section, after the rules for the added `M ≥ 2` lines and before the `## Error Handling` heading:

````markdown
### Readiness entries

A readiness pass is written under its own heading, never `## Round`:

```
## Readiness <pre|post> <p> — Execution readiness — <model>
**Result:** <settled|open>
```

`open` after an all-inconclusive pass is written `open (all inconclusive)`.
The rest of the entry is the round-entry body above under the same rules,
with no `**Converged:**` line. A settled pass with an empty consolidated set
writes the one disposition line `- none — no material issues under this
lens`. An `Owed:` block is appended to the invocation entry when the
invocation ends with any `rejected: undecidable at this gate`,
`rejected: plan-mandated` or `rejected: not a conflict` disposition — one
item per distinct conflict, naming both sides; that block, not a
controller's return message, is the durable record.

**Fields read.** Under the recognition conditions of the once-per-gate step,
this release adds the `## Readiness <pre|post> <p>` heading with its
`**Result:**` line and the `**Host self-review:** done` line;
`r counts ## Round headings only.` A readiness entry's sequence and pass
number come from its heading, and where a heading disagrees with the entry's
position among the `## Round` headings, position governs and you rewrite the
heading; an entry a later resume made obsolete gains ` — superseded` at the
end of its heading. `settled` and `open` are compared as whole words.

**Completeness.** An invocation entry for a plan written by this release —
it holds at least one `## Readiness` heading, or its recorded N is 0 — is
complete when its recorded N is 0, its pre-sequence has ended and the
self-review marker is present, or when its rotating rounds are complete
under the once-per-gate rule, its post-sequence has ended and that marker is
present. A sequence **has ended** when its last pass reads
`**Result:** settled` or it holds as many passes as its cap; any other state
is interrupted. An entry with no `## Readiness` heading anywhere whose
recorded N is at least 1 was written before this release: both sequences
count as ended, it owes no readiness pass and no marker, and the
once-per-gate rule decides it unchanged. An N = 0 plan entry blocks a later
N = 0 invocation only while the plan is unchanged since that entry was
written.

**Resume.** Continue from the first unfinished stage: pre-sequence not ended
→ its next pass; rotating rounds not complete → rotating index `r+1`;
post-sequence not ended (N ≥ 1) → its next pass; marker absent → the host
self-review, then the marker. The M passed to the resuming invocation
governs the remaining passes.
````

Insert this paragraph into the `**After the loop:**` step, directly after the sentence `The host gate's single user approval follows — this skill adds no approvals of its own.`:

```markdown
For a plan document the report also carries — and is defective without them
— one line per sequence, `Readiness pre: <p> pass(es) — <settled|open after
3|open after 3 (all inconclusive)>` and the same for `Readiness post:`, or
`Readiness post: not run (N=0)`; `Readiness conflicts applied: <n>` with one
item per applied conflict, naming both sides and the side amended; and
`Readiness conflicts owed: <n>` with one item per distinct owed conflict, or
`Readiness conflicts owed: none`. Under the `gate: orchestration` invoker
the controller writes at most one note instead, `readiness owed: <n>`; its
return keeps its tokens, `rounds` counts rotating rounds only, and for N = 0
it returns `rounds=0 outcome=cap unresolved=0`.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 938 (Global Constraint 1). If the number is larger, tighten the prose of the paragraphs this task and Tasks 2 and 3 added until it fits, keeping every string the suite pins.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-doc-review/SKILL.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-doc-review): readiness log entries, completeness and resume" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 4/10"
```

---

### Task 5: The size budget of `skills/multi-doc-review/SKILL.md`

**Files:**
- Modify: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the budget bounds the whole file, not the size of any one section, and it does not bound `skills/multi-doc-review/reviewer-prompt.md` or any other file — those are read by reviewers, not whole by the Phase 2 controller. It does not fail a file that is under budget for the wrong reason (a section deleted); the wording assertions of Tasks 1 to 4 cover that.

**Contract:**

> **Contract:** the size-budget assertion of `tests/reviewer-templates/run-tests.sh`
> - Inputs: the line count of `skills/multi-doc-review/SKILL.md`, taken with `awk 'END { print NR }'`.
> - Output: a `PASS` line naming the count and the maximum when the count is at most 938; a `FAIL` line otherwise, which makes the suite exit 1.
> - Invariants: the maximum is the literal 938; the comment above it records the 788-line baseline and names 7.14.0 as the release that set the figure.
> - Verification: `bash tests/reviewer-templates/run-tests.sh` passes on the real file, and the same arithmetic reports a number above 938 for a fixture built from that file plus 200 blank lines.

- [ ] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 15:

```bash
bold "16. multi-doc-review SKILL.md stays inside its size budget"
# The Phase 2 controller and the writing-plans host session read this file
# whole. Baseline 788 lines before 7.14.0; the Execution readiness design
# caps its additions at 150 lines, so the file may not exceed 938. Figure
# set by release 7.14.0.
MDR_MAX_LINES=938
MDR_LINES="$(awk 'END { print NR }' "$DOC_SKILL")"
if [ "$MDR_LINES" -le "$MDR_MAX_LINES" ]; then
  ok "multi-doc-review SKILL.md is $MDR_LINES lines (max $MDR_MAX_LINES)"
else
  bad "multi-doc-review SKILL.md is $MDR_LINES lines, over the $MDR_MAX_LINES-line budget"
fi
```

- [ ] **Step 2: Prove the assertion can fail**

Run:

```bash
OVER="$(mktemp)" && cat skills/multi-doc-review/SKILL.md > "$OVER" && \
  for i in $(seq 1 200); do echo >> "$OVER"; done && \
  awk 'END { print NR }' "$OVER" && rm -f "$OVER"
```

Expected: a number greater than 938 — the same arithmetic the assertion uses reports an over-budget file, so the check is not vacuous.

- [ ] **Step 3: Run the suite on the real file**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS, including a line "multi-doc-review SKILL.md is <n> lines (max 938)" with `<n>` at most 938.

- [ ] **Step 4: Run the neighbouring suites**

Run: `bash tests/review-gates/run-tests.sh && bash tests/writing-plans/run-tests.sh`
Expected: PASS for both — "Results: <n> passed, 0 failed".

- [ ] **Step 5: Commit**

```bash
git add tests/reviewer-templates/run-tests.sh
git commit -m "test(reviewer-templates): bound multi-doc-review SKILL.md at 938 lines" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 5/10"
```

---

### Task 6: The writing-plans plan gate sentences

**Files:**
- Modify: `skills/writing-plans/SKILL.md`
- Test: `tests/review-gates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the two sentences describe a plan document only; the spec gate of `skills/brainstorming/SKILL.md` must not carry them, and the test asserts their absence there. They change no default, no range and no option list: N keeps 0–10 with its own default, M keeps 1–5 with its own, and the existing cost sentence is kept verbatim with the new clause appended after it. This task does not touch Phase 0 of the orchestrator, which carries the same two sentences in Task 7.

**Contract:**

> **Contract:** the two readiness sentences at the plan gate of `skills/writing-plans/SKILL.md`
> - Must convey: for a plan the readiness pass runs even when N is 0; the readiness sequences add 2 to 6 further passes of M reviewers, 1 to 3 when N is 0, and those reviewers run one after another where dispatch is not parallel.
> - Invariants: the sentence `For a plan, the Execution readiness pass runs even when N is 0.` follows the sentence stating N's range and its `skipped` entry; the clause `add 2 to 6 further passes of M reviewers` follows the existing cost sentence, which is unchanged up to and including `and the loop runs about N × M reviewers in total.`; neither string appears anywhere in `skills/brainstorming/SKILL.md`.
> - Verification: `bash tests/review-gates/run-tests.sh`, section 16, and its existing assertion `plan gate carries the cost sentence`, which still passes.

- [ ] **Step 1: Write failing test**

Add this section to `tests/review-gates/run-tests.sh`, directly before the final `echo` / `bold "Results: ..."` block:

```bash
bold "16. The plan gates carry the Execution readiness sentences"
READINESS_N0='For a plan, the Execution readiness pass runs even when N is 0.'
READINESS_COST='add 2 to 6 further passes of M reviewers'
assert_icontains "plan gate carries the readiness N=0 sentence" "$WP_NORM" "$READINESS_N0"
assert_icontains "plan gate carries the readiness cost clause" "$WP_NORM" "$READINESS_COST"
assert_not_icontains "brainstorming carries no readiness N=0 sentence" "$BS_FILE_NORM" "$READINESS_N0"
assert_not_icontains "brainstorming carries no readiness cost clause" "$BS_FILE_NORM" "$READINESS_COST"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/review-gates/run-tests.sh`
Expected: FAIL with "plan gate carries the readiness N=0 sentence (missing: For a plan, the Execution readiness pass runs even when N is 0.)" and with the cost-clause assertion failing the same way; the two `brainstorming carries no …` assertions pass already.

- [ ] **Step 3: Implement minimal change**

In `skills/writing-plans/SKILL.md`, in the `## Multi-Round Plan Review` section, insert one sentence directly after the clause that ends `0 skips the loop and logs a \`skipped\` entry).` and before the sentence beginning `` `<d-n>` is resolved by ``:

```markdown
For a plan, the Execution readiness pass runs even when N is 0.
```

In the same section, append to the cost sentence said with the M question — the one ending `and the loop runs about N × M reviewers in total.` — this continuation, leaving that sentence itself unchanged:

```markdown
For a plan, add 2 to 6 further passes of M reviewers for the readiness
sequences (1 to 3 when N is 0); on a platform without parallel dispatch the
reviewers of a pass run one after another.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/review-gates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed", including the existing "plan gate carries the cost sentence".

- [ ] **Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md tests/review-gates/run-tests.sh
git commit -m "feat(writing-plans): state the readiness pass and its cost at the plan gate" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 6/10"
```

---

### Task 7: Phase 0 and Phase 2 of orchestrating-development

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md`
- Test: `tests/review-gates/run-tests.sh`
- Test: `tests/orchestrating-development/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the narrowing applies to `N_plan` only — `N_code = 0` still skips Phase 4 with no controller dispatched, and its `skipped (N_code=0)` log line is unchanged. Phase 2 is no longer skippable, so the case "the user wants no plan review at all" is deliberately excluded: `N_plan = 0` now means no rotating rounds, not no controller. An orchestration log written by an earlier release that carries `skipped (N_plan=0)` is excluded from the new behaviour and still reads as a complete Phase 2. This task does not change Phase 3, Phase 4, Phase 5, the Resume steps or the in-run rulings.

**Contract:**

> **Contract:** the Phase 0 wording of `skills/orchestrating-development/SKILL.md`
> - Must convey: the two readiness sentences, the same as at the writing-plans gate; `N_code = 0` skips Phase 4 with no controller; `N_plan = 0` still dispatches the Phase 2 controller; an earlier release's `skipped (N_plan=0)` line still means Phase 2 is complete.
> - Invariants: the strings `For a plan, the Execution readiness pass runs even when N is 0.` and `add 2 to 6 further passes of M reviewers` appear inside the Phase 0 span; the `skipped (N_code=0)` log shape is unchanged; the phrase `N=0 means you skip that phase yourself` no longer appears anywhere in the file.
> - Verification: `bash tests/review-gates/run-tests.sh`, section 16.

> **Contract:** the Phase 2 dispatch of `skills/orchestrating-development/SKILL.md`
> - Must convey: the plan-review controller is dispatched for every value of `N_plan`, including 0; the log entry for `N_plan = 0` names the value.
> - Invariants: the Phase 2 span no longer carries `If N_plan = 0, log the skip`; it carries the log line `## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap — unresolved 0`; the existing fill command, its `test -s` check and the sentence that dispatches the pointer are unchanged, so the existing assertions of `tests/orchestrating-development/run-tests.sh` sections 5 and 7 still pass.
> - Verification: `bash tests/orchestrating-development/run-tests.sh`, section 9.

- [ ] **Step 1: Write failing test**

In `tests/review-gates/run-tests.sh`, extend section 16 (added in Task 6) with the orchestrator's Phase 0 span and its two assertions. Add this directly below the four assertions already in that section:

```bash
# Phase 0 of the orchestrator: from its heading to the Phase 1 heading.
ORCH_P0_SPAN="$WORK/orch-phase0.txt"
ORCH_P0_START="$(first_line_of "$ORCH" '## Phase 0 — Setup (the only interactive moment)')"
ORCH_P0_END="$(first_line_of "$ORCH" '## Phase 1 — Plan Writing')"
slice_to "orchestration Phase 0 span" "$ORCH" "$ORCH_P0_START" "$ORCH_P0_END" "$ORCH_P0_SPAN"
ORCH_P0_NORM="$WORK/orch-phase0-norm.txt"
normalize_to "$ORCH_P0_SPAN" "$ORCH_P0_NORM"
assert_icontains "orchestration Phase 0 carries the readiness N=0 sentence" "$ORCH_P0_NORM" "$READINESS_N0"
assert_icontains "orchestration Phase 0 carries the readiness cost clause" "$ORCH_P0_NORM" "$READINESS_COST"
ORCH_FILE_NORM="$WORK/orch-file-norm.txt"
normalize_to "$ORCH" "$ORCH_FILE_NORM"
assert_not_icontains "orchestrator no longer narrows both phases with one N=0 sentence" "$ORCH_FILE_NORM" \
  'N=0 means you skip that phase yourself'
```

In `tests/orchestrating-development/run-tests.sh`, add this section directly before the final `echo` / `bold "Results: ..."` block:

```bash
bold "9. Phase 2 dispatches the plan-review controller for every N_plan"
assert_file_not_contains "phase 2: no N_plan=0 skip branch" "$PHASE2_RANGE" 'If N_plan = 0, log the skip'
assert_folded_contains "phase 2: names the N_plan=0 log line" "$PHASE2_RANGE" \
  '## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap — unresolved 0'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/review-gates/run-tests.sh; bash tests/orchestrating-development/run-tests.sh`
Expected: FAIL in both — "orchestration Phase 0 carries the readiness N=0 sentence (missing: …)" and "phase 2: no N_plan=0 skip branch (must not contain: If N_plan = 0, log the skip)".

- [ ] **Step 3: Implement minimal change**

In `skills/orchestrating-development/SKILL.md`, Phase 0, replace the paragraph that today reads

```
   N=0 means you skip that phase yourself — no controller dispatched;
   the log records `## Phase 2 — Plan review — skipped (N_plan=0)` /
   `## Phase 4 — Code review — skipped (N_code=0)`. The same batch
```

with:

```markdown
   N_code=0 means you skip Phase 4 yourself — no controller dispatched;
   the log records `## Phase 4 — Code review — skipped (N_code=0)`.
   N_plan=0 still dispatches the Phase 2 controller, which runs the plan's
   Execution readiness pre-sequence and no rotating round; a
   `skipped (N_plan=0)` line written by an earlier release still means
   Phase 2 is complete.

   For a plan, the Execution readiness pass runs even when N is 0.

   For a plan, add 2 to 6 further passes of M reviewers for the readiness
   sequences (1 to 3 when N is 0); on a platform without parallel dispatch
   the reviewers of a pass run one after another.

   The same batch
```

In the `## Orchestration Log Format` section, replace the sentence `Skipped loops write the \`skipped (N_x=0)\` line shapes from Phase 0.` with:

```markdown
A skipped Phase 4 writes the `skipped (N_code=0)` line shape from Phase 0;
Phase 2 is never skipped.
```

In `## Phase 2 — Plan Review Loop`, replace the opening sentence `If N_plan = 0, log the skip and go to Phase 3. Otherwise fill the plan-review prompt into the session's prompt directory, as one command (every \`NAME=\` argument single-quoted):` with:

```markdown
Fill the plan-review prompt into the session's prompt directory, as one
command (every `NAME=` argument single-quoted):
```

and append this paragraph to the end of that phase, after the sentence that ends `append and commit the Phase 2 log entry.`:

```markdown
The controller is dispatched for every `N_plan` value, 0 included: with
`N_plan = 0` it runs the plan's Execution readiness pre-sequence, no
rotating round, and returns `rounds=0 outcome=cap unresolved=0`. Its log
entry keeps the phase's line shape and reads
`## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap — unresolved 0`, so a
human and the Resume step can tell it from a controller that produced
nothing.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/review-gates/run-tests.sh && bash tests/orchestrating-development/run-tests.sh`
Expected: PASS for both — "Results: <n> passed, 0 failed".

- [ ] **Step 5: Commit**

```bash
git add skills/orchestrating-development/SKILL.md tests/review-gates/run-tests.sh tests/orchestrating-development/run-tests.sh
git commit -m "feat(orchestrating-development): dispatch Phase 2 for every N_plan" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 7/10"
```

---

### Task 8: The doc-review-loop controller template

**Files:**
- Modify: `skills/orchestrating-development/doc-review-loop-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** Deviation 3 is unchanged, so the meaning of `unresolved` and the `- [X] unresolved: …` line shape stay exactly as they are — that one bracketed single capital letter is the only such line the template may hold (Global Constraint 8). The template gains no `Resume Answer` section and no value file; Phase 2 still passes no resume answer. It does not change the `REVIEW_DONE` return shape, the controller rules, or the `[M_REVIEWERS]` placeholder.

**Contract:**

> **Contract:** `skills/orchestrating-development/doc-review-loop-prompt.md`
> - Must convey: `[N_PLAN]` accepts 0 as well as 1 to 10; the host self-review runs after the post-sequence; completeness and resume are decided by the skill's own rules, and round counting counts rotating entries only; the `_Loop complete_` line is appended as soon as the skill classifies the entry complete, by whichever clause applied, and is added when it is absent from an entry the rule already classifies as complete.
> - Invariants: the file holds exactly one line matching a bracketed single capital letter and that line is byte-identical to today's `    3. A Critical/Important finding is \`unresolved\` only when applying it` block's `- [X] unresolved: <reason> — <finding summary>` line; Deviation 3's text is unchanged; the file still carries `run the "Self-Review" checklist` and still holds no `Resume Answer` section.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 17, then `bash tests/orchestrating-development/run-tests.sh` (sections 5 and 6) and `bash tests/fill-prompt/run-tests.sh`, all green.

- [ ] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 16:

```bash
bold "17. The doc-review-loop controller template accepts N_PLAN = 0"
DOC_LOOP_PROMPT="$ROOT/skills/orchestrating-development/doc-review-loop-prompt.md"
assert_file_contains "doc-review-loop template: [N_PLAN] range starts at 0" "$DOC_LOOP_PROMPT" '`[N_PLAN]` — REQUIRED: integer 0–10'
assert_folded_contains "doc-review-loop template: host self-review after the post-sequence" "$DOC_LOOP_PROMPT" 'The host self-review runs after the post-sequence.'
assert_folded_contains "doc-review-loop template: counts rotating entries only" "$DOC_LOOP_PROMPT" 'count rotating entries only'
assert_folded_contains "doc-review-loop template: defers to the skill's completeness rule" "$DOC_LOOP_PROMPT" "the skill's completeness rule"
assert_folded_contains "doc-review-loop template: Deviation 3 is unchanged" "$DOC_LOOP_PROMPT" 'A Critical/Important finding is `unresolved` only when applying it was attempted and failed twice'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "doc-review-loop template: [N_PLAN] range starts at 0 (missing: `[N_PLAN]` — REQUIRED: integer 0–10)" and with three of the four folded needles reported missing; the Deviation 3 assertion passes already.

- [ ] **Step 3: Implement minimal change**

In `skills/orchestrating-development/doc-review-loop-prompt.md`, replace the placeholder line `- \`[N_PLAN]\` — REQUIRED: integer 1–10` with:

```markdown
- `[N_PLAN]` — REQUIRED: integer 0–10; 0 runs the plan's Execution
  readiness pre-sequence and no rotating round
```

Replace Deviation 1 with:

```markdown
    1. After the loop, run the "Self-Review" checklist from
       [WRITING_PLANS_SKILL_PATH] on the merged plan (that is the host
       checklist for plan documents); fix issues inline, note them in
       the log. The host self-review runs after the post-sequence.
```

Replace Deviation 2 with:

```markdown
    2. Classify your own `gate: orchestration` invocation entry with the
       skill's completeness rule, and continue from the stage its resume
       rule names. When you count rounds, count rotating entries only.
       As soon as that rule classifies the entry as complete — by whichever
       of its clauses applied, the clause for an entry written by an earlier
       release included, which owes no post-sequence — append to the review
       log:
       `_Loop complete — YYYY-MM-DD — rounds <r>_`
       An entry the rule classifies as interrupted is your own interrupted
       loop: continue it — the once-per-gate rule blocks re-running a
       completed loop, never continuing an interrupted one. An entry the
       rule classifies as complete is never re-run: synthesize your
       REVIEW_DONE return from the review log's recorded rounds and
       dispositions — a retry dispatched after only the final message was
       lost must not run the loop twice — and append the `_Loop complete_`
       line when it is absent.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh && bash tests/orchestrating-development/run-tests.sh && bash tests/fill-prompt/run-tests.sh`
Expected: PASS for all three — "Results: <n> passed, 0 failed" each, including "doc-review-loop-prompt.md: exactly one line with a single-letter bracket token (the checklist marker)".

- [ ] **Step 5: Commit**

```bash
git add skills/orchestrating-development/doc-review-loop-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(orchestrating-development): accept N_PLAN=0 in the plan-review template" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 8/10"
```

---

### Task 9: Documentation

**Files:**
- Modify: `docs/guide/README.md`
- Modify: `docs/FORK-IMPROVEMENTS.md`
- Modify: `docs/REVIEW-PROCESS-COMPARISON.md`

**Security flag:** `none`

**Does NOT cover:** the guide describes the plan stage, the Phase 0 parameter table, the phase table, the round-durability section and the command cheat-sheet row; the spec stage's text is excluded because no readiness pass runs for a spec. The net disclosure is limited to the fact that `skills/executing-plans/SKILL.md` has no whole-plan conflict scan; it does not propose a change there. No test asserts documentation wording, so this task's verification is a re-read plus the repository-wide block check that the other suites already run.

**Contract:**

> **Contract:** the documentation of the readiness pass
> - Must convey, in `docs/guide/README.md`: that a plan's review gate runs an Execution readiness pass before and after the rotating rounds; that it costs 2 to 6 further passes of M reviewers (1 to 3 when N is 0); that `N_plan = 0` no longer skips Phase 2; that a readiness pass is recorded in the review log like a round and a resumed loop continues from it; and the limit — a plan executed through `executing-plans`, or a writing-plans-gate user who never runs orchestration, has no later check for an owed conflict.
> - Must convey, in `docs/FORK-IMPROVEMENTS.md`: the rotating lens list is unchanged and Execution readiness is named beside it as a pass that is not part of the rotation.
> - Must convey, in `docs/REVIEW-PROCESS-COMPARISON.md`: the pre-flight plan read stays, and the decidable conflicts it used to find are now found at the plan review gate.
> - Invariants: no documentation file carries a complete `<superpowers-defaults>` block (checked by `tests/review-gates/run-tests.sh` section 2d); every phrase quoted from a skill matches that skill's text after Tasks 1 to 8.
> - Verification: `bash tests/review-gates/run-tests.sh` stays green, and `grep -n 'Execution readiness' docs/guide/README.md docs/FORK-IMPROVEMENTS.md docs/REVIEW-PROCESS-COMPARISON.md` reports at least one hit in each file.

- [ ] **Step 1: Update the guide's plan stage**

In `docs/guide/README.md`, in `### Stage 2 — Plan (\`writing-plans\`)`, replace the paragraph that begins `The plan gets its own \`multi-doc-review\` gate before you approve it` with:

```markdown
The plan gets its own `multi-doc-review` gate before you approve it, and that
gate asks you for N and M in one batch, exactly as the spec gate does; it
also audits the contracts — a task body with no stated contract, a
contract no check could fail ("must work correctly"), and an
`**Exact content:**` marker whose reason points at a file the same plan
writes (a "self-pin") are all findings.

Since v7.14.0 the plan gate also runs an **Execution readiness pass**: a
review that reads the plan as the agent that will execute it and reports
conflicts that would stop execution — tasks that contradict each other or a
Global Constraint, a task clause that contradicts the spec section it traces
to, a mandated body that breaks its own task's contract, and a sweep of
every site each Global Constraints entry binds. It runs once before the
rotating rounds and once after them, each repeated until a pass changes
nothing (at most three passes), and it runs for a plan even when you answer
N = 0. Cost: 2 to 6 further passes of M reviewers on top of the N rounds
(1 to 3 when N is 0); where the platform cannot dispatch in parallel, the M
reviewers of a pass run one after another. A conflict the pass cannot decide
— the spec contradicts itself, or the plan itself mandates something the
review rubric calls a defect — is not applied: it is listed in the review
log's `Owed:` block and in the gate's report.

The net for an owed conflict is the pre-flight plan read that
`subagent-driven-development` does before Task 1 (§3, Stage 3). That net
exists on that path only: a plan executed through `executing-plans`, or a
plan you approve at the writing-plans gate and never run through
orchestration, has no later check for it — read the `Owed:` list yourself in
that case.
```

- [ ] **Step 2: Update the guide's orchestration sections**

In the Phase 0 parameter table of `docs/guide/README.md`, replace the `N_plan` row with:

```markdown
| `N_plan` — plan-review rounds | 0–10 (0 = no rotating rounds; the Execution readiness pass still runs) | 3, or the value of `SUPERPOWERS_REVIEW_ROUNDS` |
```

In the phase table, replace the `2 — Plan review` row with:

```markdown
| 2 — Plan review | An Execution readiness pass, N independent review rounds with findings applied between rounds, then a second readiness pass | plan review-log sidecar |
```

In `## 5. "My run was interrupted"`, in the bullet that begins `- **Review loops (Phases 2 and 4)** are durable *round by round*.`, append after the sentence `Only the round in flight is lost;`:

```markdown
  A Phase 2 readiness pass is recorded in the same review log under its own
  `## Readiness` heading, so a resumed loop continues from the pass or the
  round it stopped at, never from the beginning.
```

In the `## 8. Phrase cheat-sheet` table, replace the `/multi-doc-review` row with:

```markdown
| `/multi-doc-review <doc> [N\|N=<n>] [M=<m>]` | N independent review rounds on a spec or plan, M reviewers per round; a plan also gets an Execution readiness pass before and after them | §3 |
```

- [ ] **Step 3: Update the two comparison documents**

In `docs/FORK-IMPROVEMENTS.md`, append to the bullet that ends `correctness & completeness → ambiguity & testability → feasibility & architecture risk → adversarial failure modes.`:

```markdown
 Since v7.14.0 a plan document also gets an **Execution readiness** pass before the first round and after the last one — not part of the rotation, not counted in N — which reports the conflicts that would stop an executing agent.
```

In `docs/REVIEW-PROCESS-COMPARISON.md`, replace the bullet `- **Pre-flight plan read** before the first task, surfacing internal plan conflicts at once instead of mid-run.` with:

```markdown
- **Pre-flight plan read** before the first task, surfacing internal plan
  conflicts at once instead of mid-run. Since v7.14.0 the plan review gate
  runs the same criteria as an Execution readiness pass, so the decidable
  conflicts are fixed before the plan is approved; the pre-flight read stays
  as the net for the rest.
```

and replace the phrase `one fix subagent per round covering both verdicts, pre-flight plan review,` in the v6.8.0 entry with:

```markdown
one fix subagent per round covering both verdicts, pre-flight plan review
(kept as the net once v7.14.0 moved its decidable conflicts to the plan
review gate),
```

- [ ] **Step 4: Verify**

Run: `grep -c 'Execution readiness' docs/guide/README.md docs/FORK-IMPROVEMENTS.md docs/REVIEW-PROCESS-COMPARISON.md`
Expected: a count of at least 1 for each of the three files.

Run: `bash tests/review-gates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed", including "<n> documentation files carry no complete block".

- [ ] **Step 5: Commit**

```bash
git add docs/guide/README.md docs/FORK-IMPROVEMENTS.md docs/REVIEW-PROCESS-COMPARISON.md
git commit -m "docs: describe the Execution readiness pass and its limits" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 9/10"
```

---

### Task 10: Release 7.14.0

**Files:**
- Modify: `VERSION`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugin.universal.yaml`
- Modify: `README.md`
- Modify: `RELEASE-NOTES.md`

**Security flag:** `none`

**Does NOT cover:** the release does not compile `plugin.universal.yaml` with `hookbridge compile` and does not change any hook wiring — no hook changes in this release, so the four hook configuration files stay as they are. It does not publish anything and does not reinstall the local plugin; the maintainer reinstalls before the next orchestration run.

**Contract:**

> **Contract:** the 7.14.0 release metadata
> - Invariants: the string `7.14.0` appears in `VERSION`, in `.claude-plugin/plugin.json`, in `.claude-plugin/marketplace.json`, in the `meta:` block of `plugin.universal.yaml` and in the README version badge; the two README lineage ranges read `v6.7.0–v7.14.0`; the README sentence that lists the releases covered in `RELEASE-NOTES.md` names v7.14.0 as its last entry; no badge, metadata value or lineage range still carries `7.13.0`, while the historical release lists in `README.md` and `RELEASE-NOTES.md` keep naming it; `RELEASE-NOTES.md` gains a `## v7.14.0` entry whose first three paragraphs are labelled `**Problem.**`, `**Change.**` and `**Effect.**` and total no more than 120 words.
> - Verification: `grep -rn '7\.14\.0' VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md` lists a hit in each of the six files, and the stale-version grep of Step 3 returns nothing.

- [ ] **Step 1: Bump the version in the five metadata places**

```bash
printf '7.14.0\n' > VERSION
sed -i '' 's/"version": "7\.13\.0"/"version": "7.14.0"/' .claude-plugin/plugin.json .claude-plugin/marketplace.json
sed -i '' 's/^  version: "7\.13\.0"$/  version: "7.14.0"/' plugin.universal.yaml
sed -i '' -e 's/badge\/version-7\.13\.0-white/badge\/version-7.14.0-white/' -e 's/v6\.7\.0–v7\.13\.0/v6.7.0–v7.14.0/g' README.md
```

On GNU `sed` (Linux, Git Bash) drop the `''` argument after `-i`.

Then edit by hand the `README.md` sentence that begins `The remaining
releases —` and lists every release covered in `RELEASE-NOTES.md`: replace
its closing fragment `and the \`<superpowers-defaults>\` session block
(v7.13.0) — are covered in` with:

```markdown
the `<superpowers-defaults>` session block (v7.13.0), and the Execution readiness pass at the plan review gate (v7.14.0) — are covered in
```

That sentence is a historical list, so it keeps naming v7.13.0.

- [ ] **Step 2: Add the release entry**

Insert this entry into `RELEASE-NOTES.md` directly above the `## v7.13.0` heading:

```markdown
## v7.14.0 — the Execution readiness pass

**Problem.** Plan conflicts that were findable from the plan and the spec
alone were caught by the pre-flight plan read, after four review rounds had
already passed. One run of 2026-09-09 lost about 48 minutes to three
pre-flight blocks carrying six such conflicts before Task 1 began.

**Change.** The plan review gate now runs an Execution readiness pass — five
numbered conflict checks, including a sweep of every site each Global
Constraints entry binds — before the rotating rounds and after them, each
repeated until a pass changes nothing. `N_plan = 0` no longer skips Phase 2.

**Effect.** Decidable plan conflicts are fixed at the gate; the pre-flight
read stays as the net. Reinstall the plugin before the next run. Nothing
else to migrate.

Details:

- **The lens cell.** `skills/multi-doc-review/SKILL.md` gains an
  `Execution readiness` cell with five numbered checks: tasks that
  contradict each other or a Global Constraint; anything the plan mandates
  that the review rubric treats as a defect; a task clause that contradicts
  the spec section it traces to; a mandated body that breaks its own task's
  contract; and, per Global Constraints entry, every site the entry binds.
  The sweep must end in a `coverage: GC<k> — <n> sites checked` line per
  entry — a report without it is unusable and is retried once, so a missing
  sweep can never end a sequence.
- **The sequences.** A pre-sequence runs before rotating round 1 and a
  post-sequence after the last rotating round. Each runs at most three
  passes and ends at its first *settled* pass — one that applied no Critical
  and no Important finding with all M reviewers usable. Readiness passes are
  not counted in N and are not part of the two-consecutive-clean-rounds
  streak. The host self-review stays last, after the post-sequence.
- **Triage.** Both sides of a conflict are quoted from their files before
  any disposition. Fixed text — the spec, a spec-traced Global Constraints
  entry, an externally pinned `**Exact content:**` body, a `**Contract:**`
  invariant restating an external standard — is never amended; plan text is.
  A conflict nothing decides, and a defect the plan itself mandates, are
  rejected with a reason and listed in the log's `Owed:` block. A readiness
  finding never produces an `unresolved:` line, so no new human stop is
  created.
- **`N_plan = 0`.** Phase 2 now dispatches its controller for every value of
  `N_plan`; with 0 the controller runs the readiness pre-sequence, no
  rotating round, and returns `rounds=0 outcome=cap unresolved=0`. A
  `skipped (N_plan=0)` line written by an earlier release still means
  Phase 2 is complete.
- **Logs.** A readiness pass is written under `## Readiness <pre|post> <p>`
  with a `**Result:** <settled|open>` line, never under `## Round`, so a
  session running an older installed copy counts fewer rounds and
  re-reviews rather than skipping rounds.
- **Cost.** 2 to 6 further passes of M reviewers on top of N × M (1 to 3
  when N is 0), before retries. Where the platform cannot dispatch in
  parallel, the reviewers of a pass run one after another.
```

- [ ] **Step 3: Verify the version is consistent**

Run: `grep -rn '7\.14\.0' VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md | head -20`
Expected: at least one hit in each of the five files, including the badge URL and both lineage ranges in `README.md`.

Run: `grep -n 'version-7\.13\.0\|"version": "7\.13\.0"\|version: "7\.13\.0"\|v6\.7\.0–v7\.13\.0' VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md`
Expected: no output (exit status 1) — no badge, metadata value or lineage range still carries the old version. The historical release list in `README.md` and every entry of `RELEASE-NOTES.md` keep naming v7.13.0, and this grep matches neither.

- [ ] **Step 4: Run every affected suite**

Run:

```bash
bash tests/reviewer-templates/run-tests.sh && \
bash tests/review-gates/run-tests.sh && \
bash tests/orchestrating-development/run-tests.sh && \
bash tests/writing-plans/run-tests.sh && \
bash tests/fill-prompt/run-tests.sh && \
bash tests/in-run-rulings/run-tests.sh && \
bash tests/smart-compress/run-tests.sh && \
bash tests/codex/run-unit-tests.sh
```

Expected: PASS for every suite — each ends with "Results: <n> passed, 0 failed" (the Codex suite prints its own summary) and the chain exits 0.

- [ ] **Step 5: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): 7.14.0 — the Execution readiness pass" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 10/10"
```
