# Execution Readiness Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Run the pre-flight plan-conflict criteria, extended by three checks, as reviewer passes inside the plan review gate — once before the rotating rounds and once after them, each repeated until a pass changes nothing — so that decidable plan conflicts are found and fixed at the gate instead of at the Phase 3 pre-flight.

**Spec:** `docs/superpowers-orchestrator/2026-09-10-execution-readiness-pass/specs/execution-readiness-pass-design.md`

**Architecture:** All work is text in Markdown skill files plus assertions in three pure-bash contract suites; no runtime code exists for this feature. `skills/multi-doc-review/SKILL.md` gains one lens cell (`Execution readiness`), two Procedure subsections (the readiness sequences and their triage), one Review Log Format subsection (the readiness entry shape, the fields a controller reads, the completeness and resume rules), one sentence in the N parameter, and one completion-report paragraph. `skills/multi-doc-review/reviewer-prompt.md` changes three lines outside its fenced prompt so the existing placeholders admit the new lens and the new round label. The two plan gates (`skills/writing-plans/SKILL.md`, Phase 0 of `skills/orchestrating-development/SKILL.md`) gain the same two sentences; Phase 2 of the orchestrator stops skipping itself when `N_plan = 0` and its controller template accepts that value. Every change is pinned by a string assertion in `tests/reviewer-templates/run-tests.sh`, `tests/review-gates/run-tests.sh` or `tests/orchestrating-development/run-tests.sh`.

**Tech Stack:** Markdown (skill bodies, prompt templates, guide and release documentation), Bash with `grep`/`awk` (the three contract suites), JSON and YAML (the release metadata files).

**Assumptions:**

- Assumes `skills/multi-doc-review/SKILL.md` is 788 lines when Task 1 starts — measured against the working tree while this plan was written. Will NOT hold if another change lands in that file first; the budget check of Global Constraint 1 then measures the real file against the fixed maximum of 1080 lines, and the prose this plan adds must be tightened until it fits.
- Assumes the two strings this plan copies still exist in `skills/subagent-driven-development/SKILL.md` (`tasks that contradict each other or the plan's Global Constraints`, line 205 today) and that the second one also exists in `skills/subagent-driven-development/task-reviewer-prompt.md` (line 142 today, wrapped across two physical lines). Will NOT hold if those files are edited; this plan modifies neither (Global Constraint 2), and Task 1's test asserts both sources still carry the strings, so a drift fails the suite instead of passing silently.
- Assumes the test suites run under `bash` with `grep`, `awk`, `sed`, `diff` and `git` on `PATH`, as the existing suites already do. Will NOT work on a shell that is not bash.
- Assumes every file in this repository is UTF-8 and that the em dash (`—`), the multiplication sign (`×`) and the en dash (`–`) survive as literal bytes in test needles, as they already do in `tests/review-gates/run-tests.sh`. Will NOT hold on a checkout that rewrites encodings.
- Assumes the reader of every rule added to a skill body is a language model reading rendered context, so no automated test can verify that a controller *obeys* a rule — the suites verify only that the rule's text is present. Will NOT catch a controller that reads the rule and ignores it; the spec's acceptance measure (the next orchestration run of this repository) is the only check of obedience, and it is outside these suites.

**Global Constraints:**

1. **`skills/multi-doc-review/SKILL.md` must be at most 1080 lines after every task.** The file is 788 lines before this plan, and the reference bodies of Tasks 1 to 4, inserted verbatim with their blank separator lines, add about 258 net lines — the file lands near 1046. The contract test asserts the maximum of 1080 and names 7.14.0 as the release that set the figure; the 34-line margin absorbs ordinary wording fixes without a re-measure.

   **This figure supersedes the spec's 150-line cap and its 938-line maximum, and the deviation is deliberate.** The spec's figures were set before the plan review found five corrections that each require prose in this file and cannot be dropped: narrowing the once-per-gate N = 0 sentence and the "Otherwise the entry is complete" sentence, narrowing the **On a resume** N = 0 sentence, wiring the coverage condition into the usability definition of Procedure step 2, and giving the `plan-blob` field a producer. Without them the feature is either contradicted by rules read earlier in the same file or silently inert. Raising the bound is the honest resolution; shrinking the rules to fit a number would reintroduce the defects. Flag this to the user at the gate.

   The cap still binds. At every task's Step 4, if `awk 'END { print NR }' skills/multi-doc-review/SKILL.md` reports more than 1080, bring it down by the two moves below, in this order.

   **Move 1 — reflow (always safe, do this first).** Reflow the added prose to fill each line, up to the width the surrounding file already uses. Reflowing changes where line breaks fall and changes no word. Nearly every needle of sections 12 to 15 is asserted with `assert_folded_contains`, which joins the file's lines before matching, so reflowed prose still matches. **Never reflow a line that any assertion matches as a whole line or within one line** — that is, every line asserted with `assert_file_has_line` or `assert_file_contains`; only lines whose needles use `assert_folded_contains` may be reflowed. Stated as a list, so it can be checked without re-reading the suite, that is six lines: the readiness heading `## Readiness <pre|post> <p> — Execution readiness — <model>`; the `**Result:** <settled|open>` line; the lens cell's `- spec: not used …` and `- general: not used …` lines; and the two invocation-line shapes `_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_` and `_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker> — plan-blob <sha>_   <!-- plan documents -->`, the second including its three interior spaces. The property is the rule; the list is its current membership, and a new whole-line assertion adds to it. Reflow alone recovers most of the 60 lines, because the reference bodies in this plan are written at a narrower width than the file they enter.

   **Move 2 — cut (only if reflow is not enough).** The universe is every paragraph any of Tasks 1 to 4 added to this file, Task 1's lens cell included, whether or not the current task wrote it. **A sentence may be deleted only when all three hold:** it carries no needle asserted by sections 12 to 15 of `tests/reviewer-templates/run-tests.sh`; it carries no clause of any `**Contract:**` field's "Must convey" list; **and** no task's "Does NOT cover" block names it as the mitigation of a residual risk. The third condition exists because Task 1's mitigation for the unchangeable fenced output format is two ordinary-looking sentences of the lens cell — `Write that block as the last lines of your report …` and `A report without a coverage line for every entry is incomplete and will be discarded.` — that the first two conditions would allow deleting, after which every readiness report is unusable and every sequence burns its full cap. Cut explanation and repetition, never a rule. The two longest bodies — the `### Readiness entries` subsection of Task 4 and the `### Readiness sequences (plan documents only)` subsection of Task 2 — hold most of the cuttable prose.

   Re-run `bash tests/reviewer-templates/run-tests.sh` after any reflow or cut; it is green only when every pinned string survived.
2. **No change to `skills/subagent-driven-development/SKILL.md`, to `skills/orchestrating-development/batch-controller-prompt.md`, or to the Phase 3 pre-flight behaviour.** The Pre-Flight Plan Review remains the net for what the reviewers miss.
3. **No change to the fenced prompt of `skills/multi-doc-review/reviewer-prompt.md`.** The pass uses the existing placeholders. Exactly three *items* outside the fence change: the header sentence naming the lens source, the `[LENS_NAME]` note and the `[ROUND]` note. The binding part is the fence, not a diff-line count: the header sentence occupies four physical lines today and its replacement rewraps them, so a correct change shows four or more changed lines in `git diff -U0`. Count items here, and verify the constraint by checking that no changed line falls between the `  prompt: |` line and its closing fence. The spec's Non-goals sentence says "two lines" while the spec's own "Files touched" list says three; this plan adopts three items and supersedes the Non-goals figure.
4. **No change to Deviation 3 of `skills/orchestrating-development/doc-review-loop-prompt.md` and no change to the meaning of `unresolved`.** The sentence this plan writes into the skill, and the needle that pins it, are both spelled without inner backticks: `A readiness finding never produces an unresolved: line, in any caller.` Use that spelling at those four sites — this constraint, Task 3's Contract, Task 3's test needle and Task 3's mandated body. Prose about the rule elsewhere, such as the `RELEASE-NOTES.md` entry of Task 10, is not one of them and may keep the inner backticks.
5. **No new key in the `<superpowers-defaults>` block and no environment variable.** The pass cap is a constant of the skill, and there is no switch that turns the readiness sequence off.
6. **No new token in the `REVIEW_DONE` return contract.** `REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>` keeps its tokens and their meanings; `rounds` counts rotating rounds only.
7. **No edit to `docs/orchestration-issues.md`.** The file is local and untracked.
8. **Every edit to `skills/orchestrating-development/doc-review-loop-prompt.md` keeps exactly one line matching a bracketed single capital letter, byte-identical.** `tests/orchestrating-development/run-tests.sh` section 5 asserts both halves — that exactly one such line exists in the template, and that it is byte-identical; `tests/fill-prompt/run-tests.sh` section 10 asserts the byte-identical half on the *filled* output. All new wording in that template is therefore prose.
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

Task order follows the reading order of `skills/multi-doc-review/SKILL.md` (lens cell → procedure → triage → log format), then its size budget, then the callers, then the documentation, then the release. Each task is a vertical slice: one wording change plus the assertion that pins it. Tasks 1 to 4 are the exception to self-containment — they split one feature across `skills/multi-doc-review/SKILL.md` for reviewability, and the file's cross-references resolve only after Task 4. Tasks 2 and 3 therefore commit a file whose new prose points at the `Readiness entries` subsection Task 4 adds. That is intended; do not stop the run between them.

---

### Task 1: Execution readiness lens cell and the reviewer-template notes

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Modify: `skills/multi-doc-review/reviewer-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** naming the coverage block in the reviewer prompt's `## Output format` section. That section is inside the fence Global Constraint 3 forbids editing, and it prescribes the report as the marker line, `### Verdict` and `### Findings` — nothing else. The lens text must therefore be self-sufficient about the block: the cell says where the block goes and that a report without it is discarded. Known residual risk, accepted: a reviewer that follows the output format and ignores the lens instruction returns an unusable report, which costs one retry and, if it repeats, leaves the pass open. Also excluded: the rendered dispatch label. With `[ROUND]` = `readiness pre 1`, the description line inside the fenced prompt — `description: "multi-doc-review round [ROUND]: [LENS_NAME]"` — renders as `multi-doc-review round readiness pre 1: Execution readiness`. That wording is display only and reaches no subagent's context, and it is left unchanged by choice. Note that Global Constraint 3's verification — no changed line between the `  prompt: |` line and its closing fence — would not by itself detect a change to the `description:` line, which sits inside the outer fence but above `  prompt: |`; the choice not to touch it is what keeps it stable. Also excluded: the cell's `plan:` text is the only one that reviews anything — the `spec:` and `general:` lines say `not used`, so a readiness pass over a spec document or a general document is excluded here and is excluded again by the procedure of Task 2. This task does not make the cell reachable: nothing dispatches a readiness reviewer until Task 2 adds the sequences. It also does not handle a plan that is missing a spec, a Global Constraints block or Contract fields — the fallback that removes a clause from the filled instructions is Task 2.

**Contract:**

> **Contract:** the `**Execution readiness**` cell in the "Lens Instructions" section of `skills/multi-doc-review/SKILL.md`
> - Must convey: read the plan as the agent that will execute it; report every conflict that would stop execution; quote both sides verbatim; run the numbered checks it lists, with a missing number understood as a deliberate removal and never reconstructed; for check (5) report one finding per Global Constraints entry and end with a coverage block; the other lenses' subjects are out of scope.
> - Invariants: the cell's first line stands after the `**Adversarial failure modes**` cell and before the `## Review Log Format` heading; its `plan:` text carries `tasks that contradict each other or the plan's Global Constraints` and `(a test that asserts nothing, verbatim duplication of a logic block)`, both of which still appear unchanged in `skills/subagent-driven-development/`; the five checks are numbered `(1)` to `(5)`; the coverage shape `coverage: GC<k> — <n> sites checked` appears; the `spec:` and `general:` lines both carry `not used`.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 12.

> **Contract:** the placeholder notes of `skills/multi-doc-review/reviewer-prompt.md`
> - Must convey: `[LENS_NAME]` and the file's header sentence admit `Execution readiness` beside the Lens Rotation table; `[ROUND]` admits a readiness pass label as well as a round number.
> - Invariant: the fenced prompt body — every line between the `  prompt: |` line and its closing fence — is byte-identical to the version before this task.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 12, plus `git diff -U0 -- skills/multi-doc-review/reviewer-prompt.md` showing no changed line inside the fence.

- [x] **Step 1: Write failing test**

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
                '(5) for each entry of the plan' \
                'Run all the checks below'; do
  assert_folded_contains "Execution readiness cell: numbered check '$numbered'" "$READINESS_CELL" "$numbered"
done
assert_folded_contains "Execution readiness cell: one finding per Global Constraints entry" "$READINESS_CELL" 'report ONE finding per Global Constraints entry'
assert_folded_contains "Execution readiness cell: coverage line shape" "$READINESS_CELL" 'coverage: GC<k> — <n> sites checked'
assert_file_contains "Execution readiness cell: spec line is not used" "$READINESS_CELL" '- spec: not used'
assert_file_contains "Execution readiness cell: general line is not used" "$READINESS_CELL" '- general: not used'
# Folded, not plain: the replacement wraps this phrase across a line break.
assert_folded_contains "doc-review template: header sentence admits the readiness lens" "$DOC_PROMPT" 'or `Execution readiness` for a readiness pass'
assert_file_contains "doc-review template: [LENS_NAME] note admits the readiness lens" "$DOC_PROMPT" "\`[LENS_NAME]\` — REQUIRED: lens name from SKILL.md's Lens Rotation, or \`Execution readiness\`"
assert_file_contains "doc-review template: [ROUND] note admits a readiness label" "$DOC_PROMPT" '`[ROUND]` — REQUIRED: round number, or a readiness pass label (display only)'
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: Execution readiness cell extract is empty" and with the three `doc-review template` needles reported missing.

- [x] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, insert this cell into the "Lens Instructions" section, after the last line of the `**Adversarial failure modes**` cell and before the `## Review Log Format` heading, separated from both by one blank line:

```markdown
**Execution readiness**
- plan: Read the plan as the agent that will execute it, task by task, and
  report every conflict that would stop execution. Quote both sides of each
  conflict verbatim. Run all the checks below; a number missing from the
  list was removed on purpose for this plan — never reconstruct it:
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
  `coverage: GC<k> — <n> sites checked`. Write that block as the last lines
  of your report, directly below the `### Findings` section; the output
  format you were given lists no such block, and this instruction is what
  adds it. A report without a coverage line for every entry is incomplete
  and will be discarded.
  Coverage, ambiguity, feasibility and style belong to the other lenses; do
  not report them here.
- spec: not used — the Execution readiness pass runs for plan documents only.
- general: not used — the Execution readiness pass runs for plan documents only.
```

In `skills/multi-doc-review/reviewer-prompt.md`, change exactly three items outside the fenced prompt (Global Constraint 3 — items, never a diff-line count).

Replace the **whole first paragraph** — today the four physical lines that begin `Use this template when dispatching a multi-doc-review reviewer subagent.` and end `The reviewers are not told that other reviewers exist.` — with the block below. Replace the paragraph, not the middle sentence alone: the block repeats the paragraph's first and last sentences, so a sentence-only replacement would leave each of them in the file twice.

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

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `git diff -U0 -- skills/multi-doc-review/reviewer-prompt.md`
Expected: exactly the three items above changed — the header sentence, the `[ROUND]` note and the `[LENS_NAME]` note — and **no** changed line falling between the `  prompt: |` line and its closing fence. Do not check a line count: the header sentence occupies four physical lines and its replacement rewraps them, so four or more changed lines is the correct result (Global Constraint 3).

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 1080. If it is larger, tighten under the rule of Global Constraint 1 before committing.

- [x] **Step 5: Commit**

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
> - Must convey: a pre-sequence runs before rotating round 1 and a post-sequence after the last rotating round when N ≥ 1; a fresh invocation always runs every sequence that applies to it (both when N ≥ 1, the pre-sequence alone when N = 0), a re-run under the `another pass requested` marker included; a resume never re-runs a sequence that has already ended; a pass is one `Execution readiness` review of M reviewers with the same validation, consolidation and triage as a round; a pass is settled only when it applied no Critical and no Important finding and all M reviewers were usable; a sequence runs at most three passes, one when the plan has no locatable spec; a report without a complete coverage block is unusable; a missing plan structure removes its check and writes a header note.
> - Invariants: the subsection carries the strings `pre-sequence`, `post-sequence`, `at most three passes`, `Readiness passes are not counted in N and are not part of the two-consecutive-clean-rounds streak.` and `The host self-review runs after the post-sequence.`; the three fallback rows name check (3), check (5) and check (4) with their note lines; the subsection never spells `**Execution readiness**` in bold, so Task 1's placement check keeps resolving to the lens cell.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 13.

> **Contract:** the N parameter sentence of `skills/multi-doc-review/SKILL.md`
> - Must convey: N = 0 skips the rotating loop, and for a plan document the readiness pre-sequence still runs.
> - Invariant: the existing sentence `N = 0 skips the loop and logs a \`skipped\` entry.` is unchanged and the new sentence follows it.
> - Verification: the same suite section asserts `For a plan document, the Execution readiness pre-sequence still runs.` and the unchanged sentence together.

- [x] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 12:

```bash
bold "13. Readiness sequences in the multi-doc-review procedure"
for needle in 'a report that carries no `coverage:` line for some entry of the plan' \
              'pre-sequence' \
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
# Position: the subsection must land in the Procedure, after the After-the-loop
# step and before the Lens Rotation heading. Without this, a subsection dropped
# into the wrong section passes every needle above.
SEQ_LINE="$(first_line_of "$DOC_SKILL" '### Readiness sequences (plan documents only)')"
AFTER_LOOP_LINE="$(first_line_of "$DOC_SKILL" '**After the loop:**')"
LENS_ROT_LINE="$(first_line_of "$DOC_SKILL" '## Lens Rotation')"
if [ -n "$SEQ_LINE" ] && [ -n "$AFTER_LOOP_LINE" ] && [ -n "$LENS_ROT_LINE" ] &&
   [ "$SEQ_LINE" -gt "$AFTER_LOOP_LINE" ] && [ "$SEQ_LINE" -lt "$LENS_ROT_LINE" ]; then
  ok "Readiness sequences subsection sits after **After the loop:** and before Lens Rotation (line $SEQ_LINE)"
else
  bad "Readiness sequences subsection is misplaced (after-loop='$AFTER_LOOP_LINE' seq='$SEQ_LINE' lens-rotation='$LENS_ROT_LINE')"
fi
```

`assert_eq` does not yet exist in this suite; add it next to `assert_file_has_line`:

```bash
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: procedure carries 'pre-sequence'" and the other nine needles reported missing.

- [x] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, in the `**N (round cap):**` bullet of the Parameters section, append one sentence directly after `N = 0 skips the loop and logs a \`skipped\` entry.`:

```markdown
  For a plan document, the Execution readiness pre-sequence still runs.
```

In the Procedure section, step 2 (`**Validate each report and consolidate:**`), append one sentence to the end of the sentence that defines usability — the one ending `A Verdict block must stand below that marker line — a report whose qualifying marker line is its last non-blank line is unusable.`:

```markdown
For an `Execution readiness` pass one further condition applies: a report
that carries no `coverage:` line for some entry of the plan's
`**Global Constraints:**` block is unusable too (`Readiness sequences`
below).
```

Without this sentence the closed definition in step 2 makes a coverage-less
report usable, a reviewer that enumerated nothing returns zero findings, the
pass is settled at pass 1, and the sweep the coverage block exists to force
is skipped with no symptom.

In the same section, insert this paragraph immediately before the paragraph that begins `For each round \`i\` in the range established above`:

```markdown
On a fresh invocation of a plan document, run the pre-sequence of
`Readiness sequences` below before round 1. On a resume, the resume rule of
`Readiness entries` decides which stage runs first — never re-run a
pre-sequence that has already ended.
```

Then insert this subsection directly after the `**After the loop:**` paragraph and before the `## Lens Rotation` heading, so that the `**After the loop:**` step is not pushed underneath a `###` heading it does not belong to:

```markdown
### Readiness sequences (plan documents only)

For a plan document, run a **readiness sequence** before rotating round 1
(the **pre-sequence**) and, when N ≥ 1, a second after the last rotating
round (the **post-sequence**), over the plan as that round's triage left it;
for `spec` and `general` documents neither sequence runs. A fresh invocation
always runs every sequence that applies to it — both when N ≥ 1, the
pre-sequence alone when N = 0 — and a re-run started by the
`another pass requested` marker is a fresh invocation for this rule. A
**readiness pass** is one review dispatched under the lens
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
`**Global Constraints:**` block is **unusable** — this is the second
usability condition named in step 2, and it applies to `Execution readiness`
passes only. It is retried once under
the report-validation rule of step 2, and a reviewer still unusable leaves
the pass with fewer than M usable reports, so the pass is open. A missing
sweep costs a retry; it can never end a sequence. When a structure the lens
cell names is missing, remove that clause from `[LENS_INSTRUCTIONS]` and
write a header note directly after the `**Result:**` line of every readiness
entry of this invocation — a header line, not a disposition line:

| Missing | Clause removed | Note line |
|---|---|---|
| no locatable spec | check (3) | `**Note:** clause-vs-spec check not run — no locatable spec` |
| no `**Global Constraints:**` block | check (5) and the paragraph beginning `For check (5) report ONE finding`, which carries the `coverage: GC<k>` shape | `**Note:** Global Constraints sweep not run — no block` |
| no task carries `**Contract:**` | check (4) | `**Note:** Contract check not run — no Contract fields` |

Removing a clause never renumbers the checks that remain: the numbers of
the surviving checks are left exactly as they are, so the filled
instructions carry a gap in the numbering. That gap is safe because the cell
opens with `Run all the checks below` and no count, and tells the reviewer
that a missing number was removed on purpose and must not be
reconstructed.
The rows for checks (3) and (4) remove their numbered item only. The Global
Constraints row removes two things — check (5), and the paragraph beginning
`For check (5) report ONE finding`, which is the paragraph that carries both
the `coverage: GC<k> — <n> sites checked` shape and the discard rule. Do not
look for a third item: the shape is a phrase inside that paragraph, not a
line of its own. The paragraph goes because a coverage requirement left with
no entries to cover would make every report of that pass unusable. Stop at
that paragraph — the sentence beginning `Coverage, ambiguity, feasibility`
belongs to no check and always stays.
```

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 1080. If it is larger, tighten under the rule of Global Constraint 1 before committing.

- [x] **Step 5: Commit**

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
> - Must convey: verify both sides verbatim before disposing; two authority levels, fixed text and plan text; four conflict shapes with one disposition each, the fixed-vs-fixed shape covering both a self-contradicting spec and a finding that reverses an amendment made earlier in the same sequence (the oscillation guard, without which a sequence can amend and re-amend the same text and never settle); a readiness finding never reaches `unresolved`; an out-of-lens finding is rejected.
> - Invariants: the subsection carries the disposition strings `rejected: not a conflict`, `rejected: plan-mandated`, `rejected: undecidable at this gate` and `out of lens scope`; it carries the sentence `A readiness finding never produces an unresolved: line, in any caller.` (no inner backticks, Global Constraint 4); it carries the phrase `reverses an amendment made earlier in the same sequence`; the plan-mandated row says the finding is never amended.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 14.

> **Contract:** the two Error Handling edits in `skills/multi-doc-review/SKILL.md`
> - Must convey: a readiness pass whose reports are all unusable is inconclusive and open; a readiness entry with a missing or malformed `**Result:**` line is read as open; a readiness pass with a prompt-delivery or round-level failure is handled by the existing bullets, as a round is; and the existing invalid-N bullet no longer says a plan's N = 0 only skips and logs — the readiness pre-sequence still runs.
> - Invariant: every Error Handling bullet other than the invalid-N bullet is unchanged; the invalid-N bullet keeps its first sentence about tier 2 and tier 3 verbatim; neither the new bullet nor the rewritten one uses the word `unresolved`.
> - Verification: the same suite section asserts the new bullet's three clauses and the narrowed invalid-N wording.

- [x] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 13:

```bash
bold "14. Triage of a readiness finding"
# Position: the triage subsection follows the sequences subsection and still
# precedes the Lens Rotation heading.
TRIAGE_LINE="$(first_line_of "$DOC_SKILL" '### Triage of a readiness finding')"
SEQ_LINE_14="$(first_line_of "$DOC_SKILL" '### Readiness sequences (plan documents only)')"
LENS_ROT_LINE_14="$(first_line_of "$DOC_SKILL" '## Lens Rotation')"
if [ -n "$TRIAGE_LINE" ] && [ -n "$SEQ_LINE_14" ] && [ -n "$LENS_ROT_LINE_14" ] &&
   [ "$TRIAGE_LINE" -gt "$SEQ_LINE_14" ] && [ "$TRIAGE_LINE" -lt "$LENS_ROT_LINE_14" ]; then
  ok "Triage subsection sits after the sequences subsection and before Lens Rotation (line $TRIAGE_LINE)"
else
  bad "Triage subsection is misplaced (seq='$SEQ_LINE_14' triage='$TRIAGE_LINE' lens-rotation='$LENS_ROT_LINE_14')"
fi
for needle in 'rejected: not a conflict' \
              'rejected: plan-mandated' \
              'rejected: undecidable at this gate' \
              'out of lens scope' \
              'A readiness finding never produces an unresolved: line, in any caller.' \
              'reverses an amendment made earlier in the same sequence' \
              '`rejected: plan-mandated — <text>`, never amended' \
              'a readiness entry with a missing or malformed' \
              'as a round is' \
              'for a plan document the Execution readiness pre-sequence still runs'; do
  assert_folded_contains "multi-doc-review SKILL.md: triage carries '$needle'" "$DOC_SKILL" "$needle"
done
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: triage carries 'rejected: not a conflict'" and the other nine needles reported missing — all ten needles of section 14 are absent from the file before this task.

- [x] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, insert this subsection directly after the `### Readiness sequences (plan documents only)` subsection added by Task 2, and before the `## Lens Rotation` heading:

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
| fixed text vs fixed text (the spec contradicts itself, or a finding reverses an amendment made earlier in the same sequence) | `rejected: undecidable at this gate — spec inconsistent` |
| the plan mandates a rubric defect (check 2) | `rejected: plan-mandated — <text>`, never amended |

`A readiness finding never produces an unresolved: line, in any caller.` A
finding whose application fails is disposed `rejected: undecidable at this
gate`; a finding outside the lens (coverage, ambiguity, feasibility, style)
is rejected with the reason `out of lens scope`. The three conflict
rejections — `rejected: undecidable at this gate`, `rejected: plan-mandated`
and `rejected: not a conflict` — are listed in the invocation entry's
`Owed:` block; an `out of lens scope` rejection never is, because it names
no conflict and has no two sides.
```

In the `## Error Handling` section of the same file, replace the existing bullet that reads `- Invalid N (not an integer 0–10) → tier 2, else tier 3. N = 0 → skip, log.` with:

```markdown
- Invalid N (not an integer 0–10) → tier 2, else tier 3. N = 0 → skip the
  rotating loop, log; for a plan document the Execution readiness
  pre-sequence still runs.
```

Then append this bullet after the existing harness-probe bullet:

```markdown
- Readiness pass whose reports are all unusable (u = 0) → `inconclusive`,
  and the pass is open; a readiness entry with a missing or malformed
  `**Result:**` line is read as open. A readiness pass with a
  prompt-delivery or round-level failure is handled by the bullets above,
  as a round is.
```

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 1080. If it is larger, tighten under the rule of Global Constraint 1 before committing.

- [x] **Step 5: Commit**

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

> **Contract:** the `Readiness entries` subsection of the `## Review Log Format` section of `skills/multi-doc-review/SKILL.md`, together with the two edits that make the `plan-blob` field get written (the Procedure's **Otherwise** step and the invocation-line example)
> - Must convey: the heading and `**Result:**` shape of a readiness entry; that the rest of the entry is the round-entry body without a `**Converged:**` line; the layout of an N = 0 plan entry; the `Owed:` block; which two fields a controller reads back; the completeness rule for this release and for earlier releases, with the `plan-blob` hash comparison that decides "unchanged"; the resume order.
> - Invariants: the Procedure's **Otherwise** step orders the `plan-blob <sha>` field written for a plan document, and the `## Review Log Format` invocation-line example carries both the unchanged shape and the plan variant with that field, each as its own whole line; the file carries the literal heading line `## Readiness <pre|post> <p> — Execution readiness — <model>`, the `**Result:**` label, the `**Host self-review:** done` line, the sentence `r counts ## Round headings only.`, the word `superseded` for an obsolete entry, the phrase `has ended` for the sequence-end test, and `git hash-object` for the unchanged test; `settled` and `open` are described as compared as whole words; the once-per-gate N = 0 sentence is narrowed to `spec` and `general` documents and its unnarrowed form appears nowhere in the file; the `Skipped invocations (N=0)` sentence names the plan layout.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 15.

> **Contract:** the readiness items of the completion report in the `**After the loop:**` step
> - Must convey: one line per sequence, the applied-conflict list and the owed-conflict list; a report missing them is defective; under the orchestration invoker the controller writes `readiness owed: <n>` instead.
> - Invariants: the four item labels `Readiness pre:`, `Readiness post:`, `Readiness conflicts applied:` and `Readiness conflicts owed:` appear; the existing `Harness probes owed:` sentence is unchanged; the `REVIEW_DONE` token list is restated without additions.
> - Verification: the same suite section asserts the four labels and `rounds=0 outcome=cap unresolved=0`.

- [x] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 14:

```bash
bold "15. Readiness log entries, completeness, resume and the completion report"
assert_file_has_line "multi-doc-review SKILL.md: readiness entry heading shape" "$DOC_SKILL" '## Readiness <pre|post> <p> — Execution readiness — <model>'
assert_file_has_line "multi-doc-review SKILL.md: readiness entry result line" "$DOC_SKILL" '**Result:** <settled|open>'
# The plan variant of the invocation line must exist as its own whole line,
# and the writing step must be told to emit the field: without both, the
# plan-blob comparison is inert because no entry ever carries the field.
assert_file_has_line "multi-doc-review SKILL.md: plan invocation-line shape carries plan-blob" "$DOC_SKILL" \
  '_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker> — plan-blob <sha>_   <!-- plan documents -->'
assert_file_has_line "multi-doc-review SKILL.md: the non-plan invocation-line shape is unchanged" "$DOC_SKILL" \
  '_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_'
for needle in '**Host self-review:** done' \
              'r counts ## Round headings only.' \
              'open (all inconclusive)' \
              '`Owed:` block' \
              'gains ` — superseded` at the end of its heading' \
              'has ended' \
              'compared as whole words' \
              'Readiness pre:' \
              'Readiness post:' \
              'Readiness conflicts applied:' \
              'Readiness conflicts owed:' \
              'rounds=0 outcome=cap unresolved=0' \
              'the invocation line, the one-line `skipped` entry, the readiness entries of the pre-sequence, then the self-review marker' \
              'git hash-object' \
              'the plan'"'"'s content hash as a trailing `plan-blob <sha>` field' \
              'counts as changed, so it never blocks'; do
  assert_folded_contains "multi-doc-review SKILL.md: log format carries '$needle'" "$DOC_SKILL" "$needle"
done
assert_folded_contains "multi-doc-review SKILL.md: completion report keeps the harness line" "$DOC_SKILL" 'Harness probes owed:'
# Position: the readiness-entries subsection is the last block of the Review
# Log Format section, standing after the Skipped-invocations paragraph and
# immediately before the Error Handling heading.
RDY_ENTRIES_LINE="$(first_line_of "$DOC_SKILL" '### Readiness entries')"
SKIPPED_LINE="$(first_line_of "$DOC_SKILL" 'Skipped invocations (N=0)')"
ERR_HANDLING_LINE="$(first_line_of "$DOC_SKILL" '## Error Handling')"
if [ -n "$RDY_ENTRIES_LINE" ] && [ -n "$SKIPPED_LINE" ] && [ -n "$ERR_HANDLING_LINE" ] &&
   [ "$RDY_ENTRIES_LINE" -gt "$SKIPPED_LINE" ] && [ "$RDY_ENTRIES_LINE" -lt "$ERR_HANDLING_LINE" ]; then
  ok "Readiness entries subsection sits after the Skipped-invocations paragraph and before Error Handling (line $RDY_ENTRIES_LINE)"
else
  bad "Readiness entries subsection is misplaced (skipped='$SKIPPED_LINE' entries='$RDY_ENTRIES_LINE' error-handling='$ERR_HANDLING_LINE')"
fi
# The once-per-gate N=0 sentence must be narrowed to spec/general documents,
# so the file never carries two rules for the same input.
assert_folded_contains "multi-doc-review SKILL.md: once-per-gate N=0 sentence is narrowed" "$DOC_SKILL" \
  'For a `spec` or a `general` document, an entry whose recorded N is `0`'
assert_folded_contains "multi-doc-review SKILL.md: once-per-gate defers a plan N=0 entry to Readiness entries" "$DOC_SKILL" \
  'For a plan document a skipped run still ran the readiness pre-sequence'
# The unnarrowed sentence must be gone, or the file carries two rules for one
# input. Folded, because the sentence wraps across line breaks in the file.
assert_folded_not_contains "multi-doc-review SKILL.md: the unnarrowed N=0 once-per-gate sentence is gone" "$DOC_SKILL" \
  'An entry whose recorded N is `0` (a skipped entry) does not block'
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "multi-doc-review SKILL.md: readiness entry heading shape (no line exactly: ## Readiness <pre|post> <p> — Execution readiness — <model>)" and the other needles reported missing.

- [x] **Step 3: Implement minimal change**

In `skills/multi-doc-review/SKILL.md`, make two edits to the **Once per gate** paragraph of the Procedure.

Edit 1 — replace the sentence that today reads `An entry whose recorded N is \`0\` (a skipped entry) does not block a later invocation from that gate, because a skipped run reviewed nothing — go to **Otherwise**.` with:

```markdown
For a `spec` or a `general` document, an entry whose recorded N is `0` (a
skipped entry) does not block a later invocation from that gate, because a
skipped run reviewed nothing — go to **Otherwise**. For a plan document a
skipped run still ran the readiness pre-sequence, so `Readiness entries`
below decides that entry instead.
```

This narrowing is required, not optional: without it the file carries two
rules for the same input, and the unnarrowed one is read first — it would
send every N = 0 plan entry to **Otherwise** before the completeness rule
below is ever consulted, making that rule dead text and restarting an
interrupted pre-sequence from pass 1.

Edit 2 — replace the sentence that today reads `Otherwise the entry is complete — its last round entry carries \`**Converged:** yes\`, or \`r\` is at least the entry's recorded N (the convergence case counts as complete even when \`r\` is less than N, because the loop exited early): do not re-run the loop, unless the invocation text carries the words \`another pass requested\`` with:

```markdown
Otherwise, for a `spec` or a `general` document, the entry is complete — its
last round entry carries `**Converged:** yes`, or `r` is at least the
entry's recorded N (the convergence case counts as complete even when `r` is
less than N, because the loop exited early); for a plan document
`Readiness entries` below decides completeness instead, and a plan entry
whose post-sequence has not ended or whose self-review marker is absent is
interrupted however its rotating rounds ended. For a complete entry: do not
re-run the loop, unless the invocation text carries the words
`another pass requested`
```

Without this edit the N ≥ 1 branch repeats the defect Edit 1 removes from the N = 0 branch: a controller reading the Procedure top-down stops at "do not re-run the loop" and never reaches `### Readiness entries`, so an interrupted post-sequence is skipped in silence — on the resume path the acceptance measure exercises.

Edit 3 — in the **On a resume** paragraph, replace `\`N=0\` abandons the interrupted entry instead of resuming it and is handled under **Otherwise** below (which logs the \`skipped\` entry), not here.` with:

```markdown
For a `spec` or a `general` document, `N=0` abandons the interrupted entry
instead of resuming it and is handled under **Otherwise** below (which logs
the `skipped` entry), not here. For a plan document N = 0 is an ordinary
value — the readiness pre-sequence still runs at it — so a resume with N = 0
continues the interrupted entry under the resume order of
`Readiness entries` below, and writes no second invocation note.
```

Edit 4 — append one sentence to the end of the **Once per gate** paragraph, after `After user-requested changes at the gate, re-run only the host self-review checklist before taking this step again.`:

```markdown
For a plan document, `Readiness entries` below adds two entry fields and one
invocation-note field to the list of fields read from the entry, and adds to
this completeness rule.
```

**Every anchor quoted in this step is wrapped across physical lines in `skills/multi-doc-review/SKILL.md`, and two of them start mid-line** — the once-per-gate sentence above begins with `An` at the end of one line, and the `Skipped invocations (N=0)` sentence spans three. Match each anchor ignoring its line breaks, replace exactly the sentence it names, and keep the paragraph it sits in intact. A literal single-line search finds none of them.

Two edits make the `plan-blob` field of the completeness rule below actually get written. In the Procedure's **Otherwise** step, replace `create or open the sidecar log \`<doc-basename>-review-log.md\` next to the target document and append an invocation note: date, N, M, and invoker (\`gate: brainstorming\` | \`gate: writing-plans\` | \`direct\`).` with:

```markdown
create or open the sidecar log `<doc-basename>-review-log.md` next to the
target document and append an invocation note: date, N, M, and invoker
(`gate: brainstorming` | `gate: writing-plans` | `gate: orchestration` |
`direct`), and — for a plan document only — the plan's content hash as a
trailing `plan-blob <sha>` field, the value `git hash-object <plan path>`
prints now. That first value is provisional: you rewrite it, once, when you
write the `**Host self-review:** done` marker, to what
`git hash-object <plan path>` prints then. The field's *presence* marks the
entry as written by this release from the note onward; its *value* is
meaningful only once the marker stands beside it.
```

Then, in the `## Review Log Format` section, replace the fenced invocation-line shape `_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_` with the two lines:

```
_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_
_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker> — plan-blob <sha>_   <!-- plan documents -->
```

Next, in the same section, replace the sentence that today reads `Skipped invocations (N=0) get a one-line \`skipped\` entry under their invocation note (which carries \`M=\` like every other); failed rounds get \`inconclusive\` entries.` with:

```markdown
Skipped invocations (N=0) get a one-line `skipped` entry under their
invocation note (which carries `M=` like every other); for a plan document
that entry is followed by the pre-sequence's readiness entries and the
self-review marker, as `Readiness entries` below sets out. Failed rounds get
`inconclusive` entries.
```

Then insert this subsection into the same section at exactly one place: **directly after the rewritten `Skipped invocations (N=0)` paragraph (the last paragraph of that section) and immediately before the `## Error Handling` heading.** Do not place it right after the `M ≥ 2` rules: two paragraphs stand between those rules and `## Error Handling` — the clean-round paragraph and the `Skipped invocations (N=0)` paragraph — and a `###` heading inserted above them would pull both under a subsection they do not belong to, and would make this step's own cross-reference ("as `Readiness entries` below sets out") point upward instead of downward.

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
lens`. An N = 0 plan invocation entry is laid out as: the invocation line,
the one-line `skipped` entry, the readiness entries of the pre-sequence,
then the self-review marker. An `Owed:` block is appended to the invocation entry when the
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
its invocation line carries a `plan-blob` field — is
complete when its recorded N is 0, its pre-sequence has ended and the
self-review marker is present, or when its rotating rounds are complete
under the once-per-gate rule, its post-sequence has ended and that marker is
present. A sequence **has ended** when its last pass reads
`**Result:** settled` or it holds as many passes as its cap; any other state
is interrupted. The cap is recomputed when the entry is read, from whether
the plan has a locatable spec at that moment, and is never recorded in the
entry. Accepted by design: a spec that appeared or disappeared between runs
changes the classification of an existing entry, and that costs a pass,
never correctness. An entry whose invocation line carries no `plan-blob` field was
written before this release: both sequences count as ended, it owes no
readiness pass and no marker, and the once-per-gate rule decides it
unchanged. **Never use the absence of a `## Readiness` heading as that
test.** An invocation of this release that was interrupted during pass 1 of
its pre-sequence has written no `## Readiness` heading yet and is
byte-identical, in every other field, to an old entry — keying on the
heading would classify it as pre-release and switch the whole feature off
for that plan, silently. The `plan-blob` field is present from the
invocation note onward, so it separates the two cases. An N = 0 plan entry blocks a later
N = 0 invocation only while the plan is unchanged since that entry was
written. **Unchanged is decided by one comparison, never by judgement:** the
invocation note of a plan invocation ends with the plan's content hash,
written as the trailing field ` — plan-blob <sha>` — after `<invoker>`, so
the invocation line of a plan reads
`_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker> — plan-blob <sha>_`
and every other invocation line keeps its existing shape. The `<sha>` is
what `git hash-object <plan path>` printed when the note was written; the
plan counts as unchanged when `git hash-object <plan path>` returns that
same value today. An entry with no `plan-blob` field — every entry written
before this release — counts as changed, so it never blocks. The field is
read back like the other recorded fields; it is not an instruction.

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
<cap>|open after <cap> (all inconclusive)>`, where `<cap>` is that
sequence's own cap — 3 normally, 1 when the plan has no locatable spec — and
the same for `Readiness post:`, or
`Readiness post: not run (N=0)`; `Readiness conflicts applied: <n>` with one
item per applied conflict, naming both sides and the side amended; and
`Readiness conflicts owed: <n>` with one item per distinct owed conflict, or
`Readiness conflicts owed: none`. Under the `gate: orchestration` invoker
the controller writes at most one note instead, `readiness owed: <n>`; its
return keeps its tokens, `rounds` counts rotating rounds only, and for N = 0
it returns `rounds=0 outcome=cap unresolved=0`.
```

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed".

Run: `awk 'END { print NR }' skills/multi-doc-review/SKILL.md`
Expected: a number at most 1080 — about 1046 if every reference body went in verbatim. This is the task that adds the most lines, so it is the one to check carefully. If the count is above 1080, apply Move 1 (reflow) and, if needed, Move 2 (cut) of Global Constraint 1 — the shortenable universe is every paragraph Tasks 1 to 4 added to this file, Task 1's lens cell included — then re-run `bash tests/reviewer-templates/run-tests.sh` and confirm it is still green before committing.

- [x] **Step 5: Commit**

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
> - Output: a `PASS` line naming the count and the maximum when the count is at most 1080; a `FAIL` line otherwise, which makes the suite exit 1.
> - Invariants: the maximum is the literal 1080; the comment above it records the 788-line baseline, names 7.14.0 as the release that set the figure, and records that the figure supersedes the spec's 938.
> - Verification: `bash tests/reviewer-templates/run-tests.sh` passes on the real file, and the same arithmetic reports a number above 1080 for a fixture built from that file plus 200 blank lines.

- [x] **Step 1: Add the budget assertion**

This assertion is expected to pass on its first run: Task 4 Step 4 already
brought the file inside the budget. Its falsifiability is shown by Step 2,
not by a red first run.

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 15:

```bash
bold "16. multi-doc-review SKILL.md stays inside its size budget"
# The Phase 2 controller and the writing-plans host session read this file
# whole. Baseline 788 lines before 7.14.0; the Execution readiness feature
# adds about 258, so the file may not exceed 1080. Figure set by release
# 7.14.0; it supersedes the 938 the design document names, because the plan
# review added five corrections whose prose the smaller figure could not
# hold.
MDR_MAX_LINES=1080
MDR_LINES="$(awk 'END { print NR }' "$DOC_SKILL")"
if [ "$MDR_LINES" -le "$MDR_MAX_LINES" ]; then
  ok "multi-doc-review SKILL.md is $MDR_LINES lines (max $MDR_MAX_LINES)"
else
  bad "multi-doc-review SKILL.md is $MDR_LINES lines, over the $MDR_MAX_LINES-line budget"
fi
```

- [x] **Step 2: Show the arithmetic reports an over-budget file**

Run:

```bash
OVER="$(mktemp)" && cat skills/multi-doc-review/SKILL.md > "$OVER" && \
  for i in $(seq 1 200); do echo >> "$OVER"; done && \
  awk 'END { print NR }' "$OVER" && rm -f "$OVER"
```

Expected: a number greater than 1080 — the same arithmetic the assertion uses reports an over-budget file, so the check is not vacuous. This exercises the arithmetic, not the suite's `bad` branch; that branch is ordinary shared code, already exercised by every other failing assertion in the file.

- [x] **Step 3: Run the suite on the real file**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: PASS, including a line "multi-doc-review SKILL.md is <n> lines (max 1080)" with `<n>` at most 1080.

- [x] **Step 4: Run the neighbouring suites**

Run: `bash tests/review-gates/run-tests.sh && bash tests/writing-plans/run-tests.sh`
Expected: PASS for both — "Results: <n> passed, 0 failed".

- [x] **Step 5: Commit**

```bash
git add tests/reviewer-templates/run-tests.sh
git commit -m "test(reviewer-templates): bound multi-doc-review SKILL.md at 1080 lines" --trailer "Session: execution-readiness-pass" --trailer "Stage: task 5/10"
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
> - Verification: `bash tests/review-gates/run-tests.sh`, section 15, and its existing assertion `plan gate carries the cost sentence`, which still passes.

- [x] **Step 1: Write failing test**

Add this section to `tests/review-gates/run-tests.sh`, directly before the final `echo` / `bold "Results: ..."` block:

```bash
bold "15. The plan gates carry the Execution readiness sentences"
READINESS_N0='For a plan, the Execution readiness pass runs even when N is 0.'
READINESS_COST='add 2 to 6 further passes of M reviewers'
assert_icontains "plan gate carries the readiness N=0 sentence" "$WP_NORM" "$READINESS_N0"
assert_icontains "plan gate carries the readiness cost clause" "$WP_NORM" "$READINESS_COST"
assert_not_icontains "brainstorming carries no readiness N=0 sentence" "$BS_FILE_NORM" "$READINESS_N0"
assert_not_icontains "brainstorming carries no readiness cost clause" "$BS_FILE_NORM" "$READINESS_COST"
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/review-gates/run-tests.sh`
Expected: FAIL with "plan gate carries the readiness N=0 sentence (missing: For a plan, the Execution readiness pass runs even when N is 0.)" and with the cost-clause assertion failing the same way; the two `brainstorming carries no …` assertions pass already.

- [x] **Step 3: Implement minimal change**

In `skills/writing-plans/SKILL.md`, in the `## Multi-Round Plan Review` section, insert one sentence directly after the clause that ends `0 skips the loop and logs a \`skipped\` entry).` and before the sentence beginning `` `<d-n>` is resolved by ``:

```markdown
For a plan, the Execution readiness pass runs even when N is 0.
```

**Both anchors this step quotes are wrapped across physical lines in `skills/writing-plans/SKILL.md`, and the first one ends mid-line** — `… 0 skips the loop and logs a \`skipped\`` closes one line and `entry). \`<d-n>\` is resolved by …` opens the next, both inside one long flowing paragraph. Match each anchor ignoring its line breaks. The first sentence is inserted **inline, inside that paragraph, between two sentences that share a physical line**; it does not become a new paragraph and introduces no blank line. The review-gates assertions normalise whitespace, so a paragraph split here would not turn the suite red — only this instruction prevents it.

In the same section, leaving the cost sentence said with the M question — the one ending `and the loop runs about N × M reviewers in total.` — unchanged, add the block below **as a new paragraph directly beneath the paragraph that sentence ends**, not as a continuation of that sentence's own line:

```markdown
For a plan, add 2 to 6 further passes of M reviewers for the readiness
sequences (1 to 3 when N is 0); on a platform without parallel dispatch the
reviewers of a pass run one after another.
```

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/review-gates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed", including the existing "plan gate carries the cost sentence".

- [x] **Step 5: Commit**

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
> - Invariants: the strings `For a plan, the Execution readiness pass runs even when N is 0.` and `add 2 to 6 further passes of M reviewers` appear inside the Phase 0 span; the `skipped (N_code=0)` log shape is unchanged; the phrase `N=0 means you skip that phase yourself` no longer appears anywhere in the file; the `## Orchestration Log Format` section itself — not only Phase 0 — carries both the sentence that an earlier release's `skipped (N_plan=0)` line still means Phase 2 is complete and the `(N_plan=0)` parenthetical of the current `rounds 0` shape.
> - Verification: `bash tests/review-gates/run-tests.sh`, section 15, whose two added assertions slice the `## Orchestration Log Format` section and match both sentences there.

> **Contract:** the Phase 2 dispatch of `skills/orchestrating-development/SKILL.md`
> - Must convey: the plan-review controller is dispatched for every value of `N_plan`, including 0; the log entry for `N_plan = 0` names the value.
> - Invariants: the Phase 2 span no longer carries `If N_plan = 0, log the skip`; it carries the log line `## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap — unresolved 0`; the existing fill command, its `test -s` check and the sentence that dispatches the pointer are unchanged, so the existing assertions of `tests/orchestrating-development/run-tests.sh` sections 5 and 7 still pass.
> - Verification: `bash tests/orchestrating-development/run-tests.sh`, section 9.

- [x] **Step 1: Write failing test**

In `tests/review-gates/run-tests.sh`, extend section 15 (added in Task 6) with the orchestrator's Phase 0 span and its two assertions. Add this directly below the four assertions already in that section:

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
# The Log Format section is what a resuming orchestrator reads to classify a
# log entry, so the earlier-release exception must stand there, not only in
# Phase 0. Span: the Log Format heading to the `## state.md Section` heading.
# Do NOT end the span at "the next line starting with ## ": the section opens
# with a fenced example log whose body lines start with `## Phase 1 — …`, so
# that rule would cut the span off after six lines and both assertions below
# would fail on a correct implementation. `first_line_of` here is `grep -nxF`
# (whole line), and `## state.md Section` is a real heading further down.
ORCH_LOGFMT_SPAN="$WORK/orch-logformat.txt"
ORCH_LOGFMT_START="$(first_line_of "$ORCH" '## Orchestration Log Format')"
ORCH_LOGFMT_END="$(first_line_of "$ORCH" '## state.md Section')"
slice_to "orchestration Log Format span" "$ORCH" "$ORCH_LOGFMT_START" "$ORCH_LOGFMT_END" "$ORCH_LOGFMT_SPAN"
ORCH_LOGFMT_NORM="$WORK/orch-logformat-norm.txt"
normalize_to "$ORCH_LOGFMT_SPAN" "$ORCH_LOGFMT_NORM"
assert_icontains "Log Format keeps the earlier-release skipped (N_plan=0) exception" "$ORCH_LOGFMT_NORM" \
  'written by an earlier release still means Phase 2 is complete'
# The bare '(N_plan=0)' would also match the earlier-release sentence above,
# so pin the current rounds shape in full.
assert_icontains "Log Format names the (N_plan=0) parenthetical of the rounds field" "$ORCH_LOGFMT_NORM" \
  'rounds 0 (N_plan=0) — cap — unresolved 0'
```

In `tests/orchestrating-development/run-tests.sh`, add this section directly before the final `echo` / `bold "Results: ..."` block:

```bash
bold "9. Phase 2 dispatches the plan-review controller for every N_plan"
assert_file_not_contains "phase 2: no N_plan=0 skip branch" "$PHASE2_RANGE" 'If N_plan = 0, log the skip'
assert_folded_contains "phase 2: names the N_plan=0 log line" "$PHASE2_RANGE" \
  '## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap — unresolved 0'
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/review-gates/run-tests.sh; bash tests/orchestrating-development/run-tests.sh`
Expected: FAIL in both, on five assertions: "orchestration Phase 0 carries the readiness N=0 sentence", "orchestration Phase 0 carries the readiness cost clause", "orchestrator no longer narrows both phases with one N=0 sentence" (the phrase `N=0 means you skip that phase yourself` is still present before Step 3), "Log Format keeps the earlier-release skipped (N_plan=0) exception" and "Log Format names the (N_plan=0) parenthetical of the rounds field" from the review-gates suite, plus "phase 2: no N_plan=0 skip branch (must not contain: If N_plan = 0, log the skip)" from the orchestrating-development suite. The two Log Format assertions fail because the span from `## Orchestration Log Format` to `## state.md Section` carries neither sentence before Step 3.

- [x] **Step 3: Implement minimal change**

**Every anchor this step quotes is wrapped across physical lines in `skills/orchestrating-development/SKILL.md` — the two Phase 2 anchors included — and the Log Format one starts mid-line** — the sentence `Skipped loops write the \`skipped (N_x=0)\` line shapes from Phase 0.` begins at the end of the line that closes the parenthetical `… line of the review log.)` and runs over three lines. Match every anchor ignoring its line breaks, replace only the sentence named, and leave the rest of the paragraph it sits in — including that closing parenthesis — untouched. The replacement stays inside that same paragraph; it does not become a new one.

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
Phase 2 is never skipped. A `## Phase 2 — Plan review — skipped (N_plan=0)`
line written by an earlier release still means Phase 2 is complete. This
release writes `## Phase 2 — Plan review — rounds 0 (N_plan=0) — cap —
unresolved 0` in that case instead, so the `rounds <r>` field of a Phase 2
line may carry an `(N_plan=0)` parenthetical.
```

This sentence belongs in the Log Format section because that is the section
a resuming orchestrator reads to classify a log entry; leaving the exception
only in Phase 0 would make the format say flatly that Phase 2 is never
skipped, and an old log's `skipped (N_plan=0)` line would read as a shape
the format forbids.

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

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/review-gates/run-tests.sh && bash tests/orchestrating-development/run-tests.sh`
Expected: PASS for both — "Results: <n> passed, 0 failed".

- [x] **Step 5: Commit**

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

**Does NOT cover:** Deviation 3 is unchanged, so the meaning of `unresolved` and the `- [X] unresolved: …` line shape stay exactly as they are — that one bracketed single capital letter is the only such line the template may hold (Global Constraint 8). The template gains no `Resume Answer` section and no value file; Phase 2 still passes no resume answer. It does not change the `REVIEW_DONE` return shape or the `[M_REVIEWERS]` placeholder. It leaves the background-read rule alone: `tests/orchestrating-development/run-tests.sh` section 5b asserts this template carries none, and it still carries none — the one command this task admits prints a single line, so nothing needs reading through `tail`. Update that section's explanatory comment in the same edit if it still says this controller runs no commands. One Controller Rules line does change — the permission list gains read-only inspection commands — because Task 4 makes a plan invocation note carry a `plan-blob` hash the controller must compute; without that clause the Phase 2 controller reads its permission list as exhaustive, never writes the field, and the N = 0 blocking rule is permanently inert on the orchestration path, which is the path the spec's acceptance measure uses.

**Contract:**

> **Contract:** `skills/orchestrating-development/doc-review-loop-prompt.md`
> - Must convey: `[N_PLAN]` accepts 0 as well as 1 to 10; the controller's permission list admits the read-only inspection commands the skill's procedure names, so it can compute the plan's content hash; the host self-review runs after the post-sequence; completeness and resume are decided by the skill's own rules, and round counting counts rotating entries only; the `_Loop complete_` line is appended as soon as the skill classifies the entry complete, by whichever clause applied, and is added when it is absent from an entry the rule already classifies as complete.
> - Invariants: the file holds exactly one line matching a bracketed single capital letter and that line is byte-identical to the checklist-marker line of Deviation 3 — `skills/orchestrating-development/doc-review-loop-prompt.md:72`, quoted with its seven spaces of indentation, its backticks and its trailing period: `` `- [X] unresolved: <reason> — <finding summary>`. `` (`tests/fill-prompt/run-tests.sh` section 10 pins the dedented form, with three spaces); Deviation 3's text is unchanged; the file still carries `run the "Self-Review" checklist` and still holds no `Resume Answer` section.
> - Verification: `bash tests/reviewer-templates/run-tests.sh`, section 17, then `bash tests/orchestrating-development/run-tests.sh` (sections 5 and 6) and `bash tests/fill-prompt/run-tests.sh`, all green.

- [x] **Step 1: Write failing test**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly after section 16:

```bash
bold "17. The doc-review-loop controller template accepts N_PLAN = 0"
DOC_LOOP_PROMPT="$ROOT/skills/orchestrating-development/doc-review-loop-prompt.md"
assert_file_contains "doc-review-loop template: [N_PLAN] range starts at 0" "$DOC_LOOP_PROMPT" '`[N_PLAN]` — REQUIRED: integer 0–10'
assert_folded_contains "doc-review-loop template: host self-review after the post-sequence" "$DOC_LOOP_PROMPT" 'The host self-review runs after the post-sequence.'
assert_folded_contains "doc-review-loop template: counts rotating entries only" "$DOC_LOOP_PROMPT" 'count rotating entries only'
assert_folded_contains "doc-review-loop template: defers to the skill's completeness rule" "$DOC_LOOP_PROMPT" "the skill's completeness rule"
assert_folded_contains "doc-review-loop template: Deviation 3 is unchanged" "$DOC_LOOP_PROMPT" 'A Critical/Important finding is `unresolved` only when applying it was attempted and failed twice'
assert_folded_contains "doc-review-loop template: controller may run read-only inspection commands" "$DOC_LOOP_PROMPT" "run the read-only inspection commands the skill's procedure names"
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL with "doc-review-loop template: [N_PLAN] range starts at 0 (missing: `[N_PLAN]` — REQUIRED: integer 0–10)" and with four of the five folded needles reported missing; the Deviation 3 assertion passes already.

- [x] **Step 3: Implement minimal change**

In `skills/orchestrating-development/doc-review-loop-prompt.md`, replace the placeholder line `- \`[N_PLAN]\` — REQUIRED: integer 1–10` with:

```markdown
- `[N_PLAN]` — REQUIRED: integer 0–10; 0 runs the plan's Execution
  readiness pre-sequence and no rotating round
```

**The anchor below is wrapped across two physical lines and both carry four leading spaces**, which the quotation here omits; match it ignoring the line break and keep the four-space indentation, because the template's indentation decides what the filled prompt body renders as. Replace the Controller Rules permission line — today the two lines `- You MAY dispatch reviewer subagents via the Agent tool, edit the` / `  plan (merging findings), and write the review log sidecar.` — with:

```markdown
    - You MAY dispatch reviewer subagents via the Agent tool, edit the
      plan (merging findings), write the review log sidecar, and run the
      read-only inspection commands the skill's procedure names — the
      plan's content hash among them.
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

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/reviewer-templates/run-tests.sh && bash tests/orchestrating-development/run-tests.sh && bash tests/fill-prompt/run-tests.sh && bash tests/review-gates/run-tests.sh`

`tests/review-gates/run-tests.sh` is in the chain because it also asserts on this template — that it names the `Self-Review` checklist and never names `Multi-Round Plan Review` — so an edit here can turn it red.
Expected: PASS for all four — "Results: <n> passed, 0 failed" each, including "doc-review-loop-prompt.md: exactly one line with a single-letter bracket token (the checklist marker)".

- [x] **Step 5: Commit**

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
> - Verification: `bash tests/review-gates/run-tests.sh` stays green, and each of these fixed strings is found in the file named — a one-word mention of the lens name would otherwise satisfy the check: `0 = no rotating rounds` and `add 2 to 6 further passes of M reviewers` and `## Readiness` and `executing-plans` in `docs/guide/README.md`; `not part of the rotation` in `docs/FORK-IMPROVEMENTS.md`; `kept as the net` in `docs/REVIEW-PROCESS-COMPARISON.md`. The remaining Must-convey items are reviewer-checked, not machine-checked; this task adds no wording suite.

- [x] **Step 1: Update the guide's plan stage**

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
N = 0. For a plan, add 2 to 6 further passes of M reviewers on top of the N rounds
(1 to 3 when N is 0); where the platform cannot dispatch in parallel, the M
reviewers of a pass run one after another.

The line above is deliberately over-width: `grep -cF` is line-based, and the
Contract's needle `add 2 to 6 further passes of M reviewers` must sit
unbroken on one physical line. Do not reflow it. A conflict the pass cannot decide
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

- [x] **Step 2: Update the guide's orchestration sections**

In the Phase 0 parameter table of `docs/guide/README.md`, replace the `N_plan` row with:

```markdown
| `N_plan` — plan-review rounds | 0–10 (0 = no rotating rounds; the Execution readiness pass still runs) | 3, or the value of `SUPERPOWERS_REVIEW_ROUNDS` |
```

In the phase table, replace the `2 — Plan review` row with:

```markdown
| 2 — Plan review | An Execution readiness pass, N independent review rounds with findings applied between rounds, then a second readiness pass | plan review-log sidecar |
```

In the pipeline diagram, replace the `P2` node — today `P2["Phase 2 — N_plan<br/>plan-review rounds"]` — with:

```markdown
P2["Phase 2 — readiness pass,<br/>N_plan rounds, readiness pass"]
```

The example orchestration log in `## 5.` keeps its `rounds 2 — converged`
line unchanged: that example is an `N_plan=3` run, and rewriting it to the
`N_plan = 0` shape would misdescribe it. The `N_plan = 0` shape is disclosed
in the Phase 0 parameter table row instead.

In `## 5. "My run was interrupted"`, append the block below to the **end** of the bullet that begins `- **Review loops (Phases 2 and 4)** are durable *round by round*.`, as a new indented paragraph. Do not insert it after `Only the round in flight is lost;` — that string is a clause, not a sentence, and inserting there would leave the rest of its sentence (`if it died mid-edit, …`) stranded as a fragment in user-facing documentation.

```markdown
  A Phase 2 readiness pass is recorded in the same review log under its own
  `## Readiness` heading, so a resumed loop continues from the pass or the
  round it stopped at, never from the beginning.
```

In the `## 8. Phrase cheat-sheet` table, replace the `/multi-doc-review` row with:

```markdown
| `/multi-doc-review <doc> [N\|N=<n>] [M=<m>]` | N independent review rounds on a spec or plan, M reviewers per round; a plan also gets an Execution readiness pass before and after them | §3 |
```

- [x] **Step 3: Update the two comparison documents**

Every anchor quoted in this step is wrapped across physical lines in its file (for example the `- **Pre-flight plan read**` bullet in `docs/REVIEW-PROCESS-COMPARISON.md`). Match each anchor ignoring its line breaks, and keep the surrounding wrapping style of the file you edit; a literal single-line search will not find them.

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

- [x] **Step 4: Verify**

Run: `grep -c 'Execution readiness' docs/guide/README.md docs/FORK-IMPROVEMENTS.md docs/REVIEW-PROCESS-COMPARISON.md`
Expected: a count of at least 1 for each of the three files.

Run, each as its own `grep -cF` and each expected to print a non-zero count:
`0 = no rotating rounds`, `add 2 to 6 further passes of M reviewers`, `## Readiness` and `executing-plans` against `docs/guide/README.md`; `not part of the rotation` against `docs/FORK-IMPROVEMENTS.md`; `kept as the net` against `docs/REVIEW-PROCESS-COMPARISON.md`. These are the Contract's machine-checked needles; a bare mention of the lens name does not satisfy them.

Run: `bash tests/review-gates/run-tests.sh`
Expected: PASS — "Results: <n> passed, 0 failed", including "<n> documentation files carry no complete block".

- [x] **Step 5: Commit**

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
> - Invariants: the string `7.14.0` appears in `VERSION`, in `.claude-plugin/plugin.json`, in `.claude-plugin/marketplace.json`, in the `meta:` block of `plugin.universal.yaml` and in the README version badge; the two README lineage ranges read `v6.7.0–v7.14.0`; the README sentence that lists the releases covered in `RELEASE-NOTES.md` names v7.14.0 as its last entry; no badge, metadata value or lineage range still carries `7.13.0`, while the historical release lists in `README.md` and `RELEASE-NOTES.md` keep naming it; `RELEASE-NOTES.md` gains a `## v7.14.0` entry whose first three paragraphs are labelled `**Problem.**`, `**Change.**` and `**Effect.**` and total no more than 120 words, counted as the command in Step 3 counts them — the words of those three paragraphs, excluding the three bold labels themselves.
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

**Problem.** Conflicts findable from the plan and the spec alone reached the
pre-flight plan read, after four review rounds had passed. One run of
2026-09-09 lost about 48 minutes to three pre-flight blocks before Task 1
began.

**Change.** The plan review gate now runs an Execution readiness pass —
five numbered conflict checks, including a sweep of every site each Global
Constraints entry binds — before the rotating rounds and after them, each
repeated until a pass changes nothing. `N_plan = 0` no longer skips Phase 2.

**Effect.** Decidable plan conflicts are fixed at the gate; the pre-flight
read stays as the net. Reinstall the plugin before the next run.

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

Run: `grep -rn '7\.14\.0' VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md | head -20`
Expected: at least one hit in each of the six files — the same six the Contract's Verification names, `RELEASE-NOTES.md` included — with the badge URL and both lineage ranges among the `README.md` hits.

Run: `grep -cF 'the Execution readiness pass at the plan review gate (v7.14.0) — are covered in' README.md`
Expected: `1`. The version badge alone would satisfy the grep above, so this second command is what checks the README release-list sentence.

Run: `awk '/^## v7\.14\.0 /{f=1;next} f&&/^Details:/{exit} f' RELEASE-NOTES.md | grep -v '^$' | sed 's/\*\*[A-Za-z]*\.\*\*//' | wc -w`
Expected: a number at most 120. The count excludes the three bold labels (`**Problem.**`, `**Change.**`, `**Effect.**`) and covers only the three summary paragraphs above `Details:` — that is the counting convention the Contract's word limit uses.

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
