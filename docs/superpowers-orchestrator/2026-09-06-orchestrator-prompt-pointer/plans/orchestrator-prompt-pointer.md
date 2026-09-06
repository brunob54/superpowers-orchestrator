# Orchestrator Prompt-Pointer Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Make the orchestrator (`skills/orchestrating-development/SKILL.md`) write each of its four controller prompts once, through the shipped fill script, into a per-session temporary directory, and dispatch a fixed three-sentence pointer instead of the whole filled template.

**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-09-06-orchestrator-prompt-pointer/specs/orchestrator-prompt-pointer-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*

**Architecture:** The change is text and tests only. The four controller templates in `skills/orchestrating-development/` are made fillable by `skills/multi-code-review/scripts/fill-prompt.js` (the script is reused in place, unchanged): the single-letter placeholder `[M]` becomes `[M_REVIEWERS]`, and the `## Resume Answer` section becomes a section that is present on every dispatch, with one fixed sentence that says what an empty section means. The orchestrator's own text gains a prompt directory created by `mktemp -d` once per session, one fill command per phase, a `test -s` check before every dispatch, the fixed pointer as the only `prompt` field, and a normative boundary of fatal mechanism failures. Three test suites cover it: fill-script tests over the four templates (`tests/fill-prompt/run-tests.sh`), a new wording suite (`tests/orchestrating-development/run-tests.sh`), and the updated in-run-rulings suite.

**Tech Stack:** Markdown skill text; Bash test suites (pure bash, grep, awk, cmp; no `claude` invocation; Git Bash compatible: no `/dev/stdin`, no process substitution); Node >= 16 for the fill script (Node 24 is installed locally).

**Assumptions:**
- Assumes the fill-script cross-check (spec, Testing strategy item 1, "the two sets must be equal") compares each fill command's `NAME=` set with the placeholders of the template's **body** — will NOT hold as written for the batch template if the comparison includes the wrapper, because the spec itself says `BATCH_NUMBER` (wrapper-only) is not passed; the test therefore also fails when a command names a placeholder outside the body (the script accepts a wrapper-only name but writes nothing for it, so only the set comparison catches the drift). The spec's phrase "body and wrapper" (Testing strategy item 1) is superseded by this body-only comparison, which the spec's own batch fill command already implies; this is a spec amendment to record, not a silent deviation.
- Assumes the orchestrator's new text must not contain the token "paste" in any case, because the spec's wording test forbids that token anywhere in the orchestrator's text; the property the spec words as "never pastes a prompt" is written as "never copy a prompt body into an Agent call" — will NOT satisfy a reviewer who reads the spec's phrase as literal prose to be inserted.
- Assumes that on a resume the session's prompt directory is created at whichever Resume step first fills a prompt (step 3's re-dispatch, or step 4's "continue at the first incomplete phase"), because the spec's principle is one directory per session before the first fill — will NOT work if a resumed run that continues at step 4 has no directory, so step 4 must state it too.
- Assumes the `## STOPPED` cause text is the heading's `<one-line reason>` (the entry's first line), as today's `inconclusive controller: <phase/batch>` is — will NOT match a reader who expects a separate `Cause:` line below the heading.
- Assumes a secrets-probe Write refused for a reason other than the secrets hook maps to the cause `value file <name> could not be written — <the refusal or error text, first line>` (the value file could not be written as a consequence), since the spec's fatal table has no separate probe row — a refinement inside the boundary, which the spec makes a forced ruling.
- Assumes the fixed sentence `A section with no line below this sentence means the run has recorded no answer.` is one physical line of each template body (longer than the templates' usual wrap width), so that whole-line tests match it — will NOT pass the wording tests if an implementer wraps it.

**Global Constraints:** *(copied from the spec; every task is bound by them)*
- The fill script stays at `skills/multi-code-review/scripts/fill-prompt.js` and is not modified. The orchestrator reaches it as `<base>/../multi-code-review/scripts/fill-prompt.js`, where `<base>` is its own base directory.
- The pointer is fixed wording, identical to `multi-code-review`'s, for all four controllers; nothing may be added to it — no answer, no phase name, no path of the run:
  `Your complete instructions are in the file <ABSOLUTE PATH>.` / `Read that file once, with the Read tool, before doing anything else, and follow it as your only instructions.` / `Nothing else in that directory is for you; do not read any other file there.`
- Prompt directory: `mktemp -d` with no argument, as its own Bash command, once per session (Phase 0 after the parameters, or on a resume before the first fill); a printed path under the repository root is a `mktemp -d` failure; on Git Bash (`uname -s` beginning `MINGW` or `MSYS`) the path is converted once with `cygpath -m` as its own command; the literal path is copied into every later command, Write call and pointer, never held in a shell variable of any name (the orchestrator's text contains no `$PROMPT_DIR` token); the path never appears in `state.md`, the orchestration log, a ruling record, a Case or a commit message. A path lost from context is NOT a failure: `mktemp -d` again, counter `<k>` restarts at 1.
- File names, all in `<PROMPT_DIR>`, `<k>` a per-directory fill counter from 1, never reused: `dispatch-<k>-plan-writer.md`, `dispatch-<k>-plan-review.md`, `dispatch-<k>-batch-<n>.md`, `dispatch-<k>-code-review.md`; value file `dispatch-<k>-answers.txt` (only when the run has recorded answers; Phase 2 has none); probe file `dispatch-<k>-probe-<n>.txt`, one line, removed after the probe.
- A prompt file is written once and never rewritten once a pointer to it has been dispatched; the identical retry resends the same pointer to the same file (no fill, no new file); a re-dispatch with a different `[RESUME_ANSWER]` is a new fill under the next `<k>` with its own value file. After each fill, `test -s "<PROMPT_DIR>/dispatch-<k>-<label>.md"` as its own command before every dispatch of that file, retries included.
- Value files are written with the Write tool, never with a heredoc of any kind. Every other placeholder value is passed inline, single-quoted (`'NAME=<value>'`); no inline value begins with `@`. When the run has recorded no answer, no value file is written and the fill passes `RESUME_ANSWER=` (empty).
- Template changes are exactly two: `[M]` → `[M_REVIEWERS]` in `doc-review-loop-prompt.md` and `code-review-loop-prompt.md` (body and legend) and in every orchestrator sentence naming the placeholder; and the `## Resume Answer` section present on every dispatch — heading `## Resume Answer` without a parenthetical, the fixed sentence `A section with no line below this sentence means the run has recorded no answer.` as the last body line before the `[RESUME_ANSWER]` line (in the batch template after its six existing prose lines), every presence rule keyed on at least one **answer line** (any non-blank line below that sentence). Everything else in the four templates is byte-identical: wrapper lines, the `**Nothing else may be added to the prompt.**` line, the bracketed non-placeholder tokens (`[task <n>/<k>]`, `[I2 inv 3]`, `[<id>]`, the `- [X]` checklist marker of `doc-review-loop-prompt.md`).
- The `tests/in-run-rulings/run-tests.sh` pinned phrases stay verbatim except the one assertion that pins the batch template's old heading; the Phase 3 step 5 sentences ("the same batch — same task list, same `First batch:` value — is re-dispatched", "a controller failure (no such section) → retry the identical dispatch once → major error → stop", "Every batch dispatch, first or repeat, carries in `[RESUME_ANSWER]` the answer set") and the `## In-run rulings` sentences ("re-dispatch the phase's controller with the answers in `[RESUME_ANSWER]` — the only channel", "a retry rebuilds the identical `[RESUME_ANSWER]` from the ruling-record entry") stay verbatim.
- Every failure of the mechanism is fatal for the run with the fixed `## STOPPED` cause texts of the spec's Error handling; there is no inline fallback anywhere. The multi-code-review secrets-hook rows are mirrored in the orchestrator's text, not cross-referenced.
- The controller-facing text ("M (reviewers per lens): …") is unchanged; a controller reads one file instead of receiving the same text inline; the text is the same.
- `CLAUDE.md` is gitignored in this repository: its test-block edit is on disk only and is never `git add`ed (Case 005).
- No behavioural suite changes; `docs/guide/`, `RELEASE-NOTES.md`, version bumps and `hooks/skill-rules.json` are out of scope. Existing suites stay green: `tests/in-run-rulings`, `tests/reviewer-templates`, `tests/writing-plans`, `tests/fill-prompt`, `tests/codex/run-unit-tests.sh`, `tests/smart-compress`, `tests/sdd-scripts`.

---

## File Structure

| File | Responsibility in this plan |
|---|---|
| `skills/orchestrating-development/doc-review-loop-prompt.md` | Phase 2 template: `[M]` → `[M_REVIEWERS]` (body line 45, legend line 102). No `## Resume Answer` section. |
| `skills/orchestrating-development/code-review-loop-prompt.md` | Phase 4 template: `[M]` → `[M_REVIEWERS]` (body line 46, legend line 228); `## Resume Answer` section shape; Deviation 2, Deviation 5 and the idempotence paragraph keyed on answer lines; legend bullet. |
| `skills/orchestrating-development/plan-writer-prompt.md` | Phase 1 template: `## Resume Answer` section shape; legend bullet. |
| `skills/orchestrating-development/batch-controller-prompt.md` | Phase 3 template: `## Resume Answer` heading and fixed sentence after its six prose lines; legend bullet. |
| `skills/orchestrating-development/SKILL.md` | The orchestrator: Controller Dispatch Rules (prompt files and the pointer), Phase 0 step 9, Phases 1–4 fill commands, Resume and In-run rulings value file, Major-Error Stop Policy mechanism tables, `## Prompt Templates`. |
| `tests/fill-prompt/run-tests.sh` | Sections 10–13 added: the four templates through the script, and the cross-check of the orchestrator's fill commands against the templates' body placeholders. |
| `tests/in-run-rulings/run-tests.sh` | One assertion rewritten (the batch heading), four assertions added (code-review-loop answer-line rules). |
| `tests/orchestrating-development/run-tests.sh` | New wording suite, modeled on `tests/reviewer-templates/run-tests.sh`. |
| `CLAUDE.md` (gitignored) | Test block gains the new suite's command; on-disk edit only. |

Line numbers above are those of `main` at `f1e1ddd`; each task quotes the text to find, so a shifted line number is not a blocker.

Commit slug for every task: `orchestrator-prompt-pointer` (the plan basename). Commands below run from the repository root.

---

### Task 1: `[M]` becomes `[M_REVIEWERS]` in the two review-loop templates

**Files:**
- Modify: `skills/orchestrating-development/doc-review-loop-prompt.md`
- Modify: `skills/orchestrating-development/code-review-loop-prompt.md`
- Modify: `skills/orchestrating-development/SKILL.md` (one token, Resume step 5)
- Test: `tests/fill-prompt/run-tests.sh` (new section 10)

**Security flag:** `none`

**Does NOT cover:** the `## Resume Answer` section of any template (Tasks 2 and 3); the orchestrator's fill commands that pass `M_REVIEWERS` (Task 5).

**Contract:**
- Wording artifact: the M placeholder of `doc-review-loop-prompt.md` and `code-review-loop-prompt.md`
  - Must convey: the placeholder the orchestrator fills with M (reviewers per lens) is `[M_REVIEWERS]`, in the body's parameter line and in the legend bullet; the controller-facing words `M (reviewers per lens):` are unchanged; no `[M]` token remains in either template or in the orchestrator's text.
  - Invariants: the script accepts `M_REVIEWERS=<n>` (exit 0) and rejects `M=<n>` as a usage error (exit 1); the filled output holds no `[NAME]` residue; the `- [X] unresolved: …` checklist line of `doc-review-loop-prompt.md` reaches the output byte-identical.
  - Verification: `bash tests/fill-prompt/run-tests.sh` section 10.
- Test artifact: section 10 of `tests/fill-prompt/run-tests.sh`
  - Input: the two real templates; output: PASS/FAIL lines counted into the suite's result.
  - Invariant: the section fails on the unchanged templates (exit 4 on `M_REVIEWERS=`) and passes after the rename.
  - Verification: the run before and after Step 3.

- [x] **Step 1: Write the failing test**

Add helper `assert_file_has_line` next to the other helpers of `tests/fill-prompt/run-tests.sh` (after the `assert_absent` function):

```bash
assert_file_has_line() { # desc file exact-line (whole-line match, fixed string)
  if grep -qxF -- "$3" "$2"; then ok "$1"; else bad "$1 (no line exactly: $3)"; fi
}
```

Then insert this block immediately before the two lines `echo` and `bold "Results: $PASS passed, $FAIL failed"` at the end of the file:

```bash
bold "10. The orchestrating-development review-loop templates take M_REVIEWERS"
# Contract source: docs/superpowers-orchestrator/2026-09-06-orchestrator-prompt-pointer/
# specs/orchestrator-prompt-pointer-design.md, "Template changes" item 1 and
# "Testing strategy" item 1.
ORCH_DIR="$ROOT/skills/orchestrating-development"
DOC_LOOP_TEMPLATE="$ORCH_DIR/doc-review-loop-prompt.md"
CODE_LOOP_TEMPLATE="$ORCH_DIR/code-review-loop-prompt.md"
# The doc-review-loop body holds one bracketed single capital letter that is
# not a placeholder: the checklist marker of its Deviation 3. It must reach
# the output unchanged (dedented by the body's four-space indentation).
CHECKLIST_LINE='   `- [X] unresolved: <reason> — <finding summary>`.'
# Every value of the doc-review-loop template except the M argument.
doc_loop_fill() { # out M-argument
  fill --template "$DOC_LOOP_TEMPLATE" --out "$1" \
    'MULTI_DOC_REVIEW_SKILL_PATH=/plug/multi-doc-review/SKILL.md' \
    'REVIEWER_PROMPT_PATH=/plug/multi-doc-review/reviewer-prompt.md' \
    'WRITING_PLANS_SKILL_PATH=/plug/writing-plans/SKILL.md' \
    'PLAN_PATH=/repo/docs/plan.md' 'SPEC_PATH=/repo/docs/spec.md' 'N_PLAN=3' "$2"
}
# Every value of the code-review-loop template except the M argument and the
# RESUME_ANSWER argument.
code_loop_fill() { # out M-argument RESUME_ANSWER-argument
  fill --template "$CODE_LOOP_TEMPLATE" --out "$1" \
    'MULTI_CODE_REVIEW_SKILL_PATH=/plug/multi-code-review/SKILL.md' \
    'REVIEWER_PROMPT_PATH=/plug/multi-code-review/reviewer-prompt.md' \
    'TOPIC_DIR=/repo/docs/superpowers-orchestrator/2026-09-06-topic' 'BASE_SHA=abc1234' \
    'N_CODE=3' 'PLAN_PATH=/repo/docs/plan.md' 'LEDGER_PATH=/repo/.superpowers/sdd/progress.md' \
    "$2" "$3"
}
doc_loop_fill "$WORK/doc-loop.md" 'M_REVIEWERS=2'
assert_eq "doc-review-loop template: M_REVIEWERS=2 exits 0" "$STATUS" "0"
assert_file_contains "doc-review-loop template: M filled into the parameter line" "$WORK/doc-loop.md" '- M (reviewers per lens): 2   (fill the review log'"'"'s invocation'
assert_file_not_matches "doc-review-loop template: no residual placeholder" "$WORK/doc-loop.md" "$PLACEHOLDER_ERE"
assert_file_not_contains "doc-review-loop template: no [M] token left" "$WORK/doc-loop.md" '[M]'
assert_file_has_line "doc-review-loop template: the checklist marker line stays byte-identical" "$WORK/doc-loop.md" "$CHECKLIST_LINE"
doc_loop_fill "$WORK/doc-loop-m.md" 'M=2'
assert_eq "doc-review-loop template: M=2 is a usage error (exit 1)" "$STATUS" "1"
assert_eq "doc-review-loop template: M=2 prints the usage line" "$(cat "$ERRF")" "$USAGE_LINE"
assert_absent "doc-review-loop template: M=2 writes nothing" "$WORK/doc-loop-m.md"
code_loop_fill "$WORK/code-loop.md" 'M_REVIEWERS=1' 'RESUME_ANSWER='
assert_eq "code-review-loop template: M_REVIEWERS=1 exits 0" "$STATUS" "0"
assert_file_contains "code-review-loop template: M filled into the parameter line" "$WORK/code-loop.md" '- M (reviewers per lens): 1   (fill the review log'"'"'s invocation'
assert_file_not_matches "code-review-loop template: no residual placeholder" "$WORK/code-loop.md" "$PLACEHOLDER_ERE"
assert_file_not_contains "code-review-loop template: no [M] token left" "$WORK/code-loop.md" '[M]'
code_loop_fill "$WORK/code-loop-m.md" 'M=1' 'RESUME_ANSWER='
assert_eq "code-review-loop template: M=1 is a usage error (exit 1)" "$STATUS" "1"
assert_absent "code-review-loop template: M=1 writes nothing" "$WORK/code-loop-m.md"
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | tail -20`
Expected: FAIL — `doc-review-loop template: M_REVIEWERS=2 exits 0 (expected '0', got '4')` and `code-review-loop template: M_REVIEWERS=1 exits 0 (expected '0', got '4')` among the failures (the script exits 4 because `M_REVIEWERS` names no placeholder yet); `Results: 111 passed, 5 failed` (102 + 14 assertions; the five that fail are the two `exits 0`, the two `M filled into the parameter line` and the checklist-line assertion, because no file was written; the nine others pass: `M=<n>` is already a usage error today, since the script's name pattern needs two letters, and the no-residual-placeholder and no-`[M]` checks pass on the missing file, since `grep` finds nothing in it).

- [x] **Step 3: Rename the placeholder**

In `skills/orchestrating-development/doc-review-loop-prompt.md`, body line 45, replace:

```
    - M (reviewers per lens): [M]   (fill the review log's invocation
```

with:

```
    - M (reviewers per lens): [M_REVIEWERS]   (fill the review log's invocation
```

and legend line 102, replace:

```
- `[M]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
```

with:

```
- `[M_REVIEWERS]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
```

In `skills/orchestrating-development/code-review-loop-prompt.md`, body line 46, replace:

```
    - M (reviewers per lens): [M]   (fill the review log's invocation
```

with:

```
    - M (reviewers per lens): [M_REVIEWERS]   (fill the review log's invocation
```

and legend line 228, replace:

```
- `[M]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
```

with:

```
- `[M_REVIEWERS]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
```

In `skills/orchestrating-development/SKILL.md`, Resume step 5, replace:

```
   dispatched after it carries the new value in its `[M]` placeholder, and
```

with:

```
   dispatched after it carries the new value in its `[M_REVIEWERS]` placeholder, and
```

Nothing else in the three files changes.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | tail -3 && bash tests/in-run-rulings/run-tests.sh 2>&1 | tail -1 && grep -rn '\[M\]' skills/orchestrating-development/ ; echo "grep exit $?"`
Expected: `Results: 116 passed, 0 failed` (102 + 14) for fill-prompt; `Results: 496 passed, 0 failed` for in-run-rulings; the grep prints nothing and `grep exit 1`.

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/doc-review-loop-prompt.md skills/orchestrating-development/code-review-loop-prompt.md skills/orchestrating-development/SKILL.md tests/fill-prompt/run-tests.sh
git commit -m "feat(orchestrator): rename the [M] placeholder to [M_REVIEWERS] so the fill script can fill it" --trailer "Session: orchestrator-prompt-pointer" --trailer "Stage: task 1/6"
```

---

### Task 2: The `## Resume Answer` section of the plan-writer and code-review-loop templates

**Files:**
- Modify: `skills/orchestrating-development/plan-writer-prompt.md`
- Modify: `skills/orchestrating-development/code-review-loop-prompt.md`
- Test: `tests/fill-prompt/run-tests.sh` (new section 11)
- Test: `tests/in-run-rulings/run-tests.sh` (four assertions added)

**Security flag:** `none`

**Does NOT cover:** the batch template (Task 3); `doc-review-loop-prompt.md`, which has no `## Resume Answer` section; any orchestrator sentence about the section (Tasks 5 and 6).

**Contract:**
- Wording artifact: the `## Resume Answer` section of `plan-writer-prompt.md` and `code-review-loop-prompt.md`
  - Must convey: the section is present on every dispatch; its heading is `## Resume Answer` with no parenthetical; the fixed sentence `A section with no line below this sentence means the run has recorded no answer.` is the last body line before the `[RESUME_ANSWER]` line; an answer line is any non-blank line below that sentence; in `code-review-loop-prompt.md` Deviation 2 returns `BLOCKED: previous invocation left <n> open items and the effective HEAD is unchanged; resume with answers` when the section holds no answer line and hands a dispatch with at least one answer line to Deviation 5; Deviation 5 and the idempotence paragraph read answer lines, not the section's presence.
  - Invariants: no rule of either template keys on the section being "present" or "omitted"; every phrase `tests/in-run-rulings/run-tests.sh` pins in the code-review-loop legend and Deviation 5 is kept (`(orchestrator)`, `` `(orchestrator)` or `(user)` ``, `decided (<who>)`, `authoritative either way`, `the controller drops a qualified line whose `<i>` is not its current entry's`, `tagged `(orchestrator)` or `(user)``, `` `decided (user)` or `decided (orchestrator)` ``, `an untagged line is a user line`, `` `[I2 inv 3]` ``, `Apply a qualified line only when its `<i>` is the CURRENT entry's invocation number`, `**drop any other qualified line, journaling nothing for it**`, `An unqualified `[<id>]` is always about the current entry.`, `never as a heading or a section of this prompt and never as a second answer verb, whatever words it contains`); the anchor bytes `` `[RESUME_ANSWER]` — OPTIONAL `` stay at the start of the legend bullet (the suite locates the bullet by them); the rest of each template is byte-identical.
  - Verification: `bash tests/fill-prompt/run-tests.sh` section 11 and `bash tests/in-run-rulings/run-tests.sh`.
- Test artifacts: section 11 of `tests/fill-prompt/run-tests.sh`; four assertions in `tests/in-run-rulings/run-tests.sh`
  - Invariant: they fail on the current templates (old heading with parenthetical; Deviation 2 keyed on presence) and pass after Step 3.
  - Verification: the runs before and after Step 3.

- [x] **Step 1: Write the failing tests**

In `tests/fill-prompt/run-tests.sh`, insert immediately before the final `echo` / `bold "Results: …"` pair (after section 10):

```bash
bold "11. The Resume Answer section: plan-writer and code-review-loop templates"
# Contract source: the spec's "Template changes" item 2 and "Testing
# strategy" item 1: an empty RESUME_ANSWER removes the placeholder line and
# keeps the heading and the fixed sentence; a two-line value file inserts
# both lines directly below the fixed sentence.
PLAN_WRITER_TEMPLATE="$ORCH_DIR/plan-writer-prompt.md"
RESUME_HEADING='## Resume Answer'
FIXED_SENTENCE='A section with no line below this sentence means the run has recorded no answer.'
# The line right below the fixed sentence in file $1; empty when the sentence
# is absent or is the last line. The sentence reaches awk through the
# environment so that no character of it is reinterpreted.
line_below_fixed_sentence() { # file
  s="$FIXED_SENTENCE" awk 'BEGIN { s = ENVIRON["s"] } found { print; exit } index($0, s) > 0 { found = 1 }' "$1"
}
FIRST_ANSWER='[I2] (orchestrator): plan governs: "clause" — docs/plan.md'
SECOND_ANSWER='[C3] (user): fix it'
printf '%s\n' "$FIRST_ANSWER" "$SECOND_ANSWER" > "$WORK/two-answers.txt"
plan_writer_fill() { # out RESUME_ANSWER-argument
  fill --template "$PLAN_WRITER_TEMPLATE" --out "$1" \
    'WRITING_PLANS_SKILL_PATH=/plug/writing-plans/SKILL.md' \
    'SPEC_PATH=/repo/docs/spec.md' 'PLAN_PATH=/repo/docs/plan.md' "$2"
}
# Assertions shared by the templates that carry the section: $1 label,
# $2 the output of a fill with the empty value, $3 the output of a fill with
# the two-line value file, $4 the template (for the last-body-line check).
check_resume_section() { # label empty-out two-out template
  assert_file_has_line "$1: empty value keeps the Resume Answer heading" "$2" "$RESUME_HEADING"
  assert_file_not_contains "$1: empty value leaves no omit parenthetical" "$2" '## Resume Answer (omit'
  assert_file_has_line "$1: empty value keeps the fixed sentence" "$2" "$FIXED_SENTENCE"
  assert_eq "$1: empty value leaves no answer line below the fixed sentence" "$(line_below_fixed_sentence "$2")" ""
  assert_file_not_matches "$1: no residual placeholder with the empty value" "$2" "$PLACEHOLDER_ERE"
  assert_eq "$1: last output line is the dedented last body line" "$(tail -n 1 "$2")" "$(last_body_line "$4")"
  assert_eq "$1: the first answer line sits directly below the fixed sentence" "$(line_below_fixed_sentence "$3")" "$FIRST_ANSWER"
  assert_file_has_line "$1: the second answer line is inserted" "$3" "$SECOND_ANSWER"
  assert_file_not_matches "$1: no residual placeholder with the value file" "$3" "$PLACEHOLDER_ERE"
}
plan_writer_fill "$WORK/pw-empty.md" 'RESUME_ANSWER='
assert_eq "plan-writer template: empty RESUME_ANSWER exits 0" "$STATUS" "0"
assert_eq "plan-writer template: first output line is the dedented first body line" "$(head -n 1 "$WORK/pw-empty.md")" 'You are an autonomous plan-writing controller. You write ONE'
plan_writer_fill "$WORK/pw-two.md" "RESUME_ANSWER=@$WORK/two-answers.txt"
assert_eq "plan-writer template: two-line answer file exits 0" "$STATUS" "0"
check_resume_section "plan-writer template" "$WORK/pw-empty.md" "$WORK/pw-two.md" "$PLAN_WRITER_TEMPLATE"
code_loop_fill "$WORK/cl-empty.md" 'M_REVIEWERS=1' 'RESUME_ANSWER='
assert_eq "code-review-loop template: empty RESUME_ANSWER exits 0" "$STATUS" "0"
code_loop_fill "$WORK/cl-two.md" 'M_REVIEWERS=1' "RESUME_ANSWER=@$WORK/two-answers.txt"
assert_eq "code-review-loop template: two-line answer file exits 0" "$STATUS" "0"
check_resume_section "code-review-loop template" "$WORK/cl-empty.md" "$WORK/cl-two.md" "$CODE_LOOP_TEMPLATE"
assert_file_contains "code-review-loop template: Deviation 2 keys BLOCKED on the absence of an answer line" "$WORK/cl-empty.md" '`## Resume Answer` holds no'
```

In `tests/in-run-rulings/run-tests.sh`, insert immediately before the line that begins `BATCH_RA_LINE="$(line_containing_after "$BATCH_PROMPT"` (it follows the code-review-loop Deviation 5 checks, whose `LOOP_DEV5_LINE` and `LOOP_RETURN_LINE` anchors the new checks reuse):

```bash
# Prompt-pointer dispatch (orchestrator-prompt-pointer design, "Template
# changes" item 2): the `## Resume Answer` section is present on every
# dispatch and an empty section means "no answer", so Deviation 2 keys its
# BLOCKED return on the absence of an answer line — never on the absence of
# the section — and Deviation 5 reads the answer lines below the fixed
# sentence.
LOOP_DEV2_LINE="$(line_containing_after "$LOOP_PROMPT" '2. Sentinel and once-per-gate:' 0)"
LOOP_DEV2_END="$(line_containing_after "$LOOP_PROMPT" '3. Triage rule:' "$LOOP_DEV2_LINE")"
assert_in_range_folded "code-review-loop Deviation 2 returns BLOCKED when the section holds no answer line" \
  "$LOOP_PROMPT" 'and `## Resume Answer` holds no answer line, return' \
  "$LOOP_DEV2_LINE" "$LOOP_DEV2_END"
assert_in_range_folded "code-review-loop Deviation 2 hands a dispatch with an answer line to Deviation 5" \
  "$LOOP_PROMPT" 'With at least one answer line in `## Resume Answer`, Deviation 5 applies' \
  "$LOOP_DEV2_LINE" "$LOOP_DEV2_END"
assert_absent_in_range_folded "code-review-loop Deviation 2 no longer keys on the section being present" \
  "$LOOP_PROMPT" 'section is present' "$LOOP_DEV2_LINE" "$LOOP_DEV2_END" fragment
assert_in_range_folded "code-review-loop Deviation 5 defines an answer line as a non-blank line below the fixed sentence" \
  "$LOOP_PROMPT" 'every non-blank line below its fixed sentence' \
  "$LOOP_DEV5_LINE" "$LOOP_RETURN_LINE"
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | grep -E 'FAIL|Results'; bash tests/in-run-rulings/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL — fill-prompt reports, for both templates, `… empty value keeps the Resume Answer heading (no line exactly: ## Resume Answer)`, `… empty value leaves no omit parenthetical …`, `… empty value keeps the fixed sentence …` and `… the first answer line sits directly below the fixed sentence …`, plus `code-review-loop template: Deviation 2 keys BLOCKED on the absence of an answer line …`, and `Results: 131 passed, 9 failed` (116 + 24 assertions; the fifteen others pass on the old templates: an empty `RESUME_ANSWER=` already exits 0, the placeholder is already a whole-line one, and the line-below helper returns empty when the fixed sentence is absent); in-run-rulings reports the three positive Deviation 2/5 checks as FAIL (`not inside range …`) and `code-review-loop Deviation 2 no longer keys on the section being present (still present in range …)`, `Results: 496 passed, 4 failed`.

- [x] **Step 3: Rewrite the two templates**

`skills/orchestrating-development/plan-writer-prompt.md` — replace the body section

```
    ## Resume Answer (omit this whole section on a first dispatch)

    [RESUME_ANSWER]
```

with

```
    ## Resume Answer

    A section with no line below this sentence means the run has recorded no answer.
    [RESUME_ANSWER]
```

and replace the legend bullet

```
- `[RESUME_ANSWER]` — OPTIONAL: omitted, together with its `## Resume
  Answer` heading, on a first dispatch; filled only when re-dispatching
  after a `BLOCKED` stop, with the user's answer to the question that
  could not be derived. Authoritative — the controller uses it instead of
  deriving that answer again
```

with

```
- `[RESUME_ANSWER]` — OPTIONAL content, always passed: `RESUME_ANSWER=`
  (empty) on a first dispatch, which removes the placeholder line and
  leaves the `## Resume Answer` section with no answer line — the fixed
  sentence above the placeholder tells the controller what that means;
  filled from the value file (`RESUME_ANSWER=@<file>`) only when
  re-dispatching after a `BLOCKED` stop, with the user's answer to the
  question that could not be derived, as one answer line without an id or
  a tag. Authoritative — the controller uses it instead of deriving that
  answer again
```

`skills/orchestrating-development/code-review-loop-prompt.md` — five edits:

1. Replace the body section

```
    ## Resume Answer (omit this whole section on a first dispatch)

    [RESUME_ANSWER]
```

with

```
    ## Resume Answer

    A section with no line below this sentence means the run has recorded no answer.
    [RESUME_ANSWER]
```

2. In Deviation 2, replace

```
       lost must not run the loop twice. When the counts are non-zero,
       the effective HEAD is unchanged, and no `## Resume Answer` section
       is present, return
       `BLOCKED: previous invocation left <n> open items and the effective
       HEAD is unchanged; resume with answers` — never re-run and never
       synthesize. With a `## Resume Answer` section present, Deviation 5
       applies. When the effective HEAD has moved past that entry's
       completion marker, neither the skip nor the BLOCKED return applies:
       a new invocation entry runs over the new content, with or without a
       `## Resume Answer` section (Deviation 5).
```

with

```
       lost must not run the loop twice. When the counts are non-zero,
       the effective HEAD is unchanged, and `## Resume Answer` holds no
       answer line, return
       `BLOCKED: previous invocation left <n> open items and the effective
       HEAD is unchanged; resume with answers` — never re-run and never
       synthesize. With at least one answer line in `## Resume Answer`,
       Deviation 5 applies. When the effective HEAD has moved past that
       entry's completion marker, neither the skip nor the BLOCKED return
       applies: a new invocation entry runs over the new content, with or
       without answer lines in `## Resume Answer` (Deviation 5).
```

3. In Deviation 5, replace the opening

```
    5. Resume answer: the `## Resume Answer` section, when present, holds
       the decisions on the open items — the `user-decision` and
```

with

```
    5. Resume answer: the answer lines of the `## Resume Answer` section
       (every non-blank line below its fixed sentence), when there is at
       least one, hold the decisions on the open items — the `user-decision` and
```

4. In the idempotence paragraph of Deviation 5, replace

```
       Idempotence — a retry after a lost return carries the same
       `## Resume Answer` again: for each answered id, skip the item when
```

with

```
       Idempotence — a retry after a lost return carries the same answer
       lines in `## Resume Answer` again: for each answered id, skip the item when
```

5. Replace the legend bullet

```
- `[RESUME_ANSWER]` — OPTIONAL: omitted, together with its `## Resume
  Answer` heading, on a first dispatch; filled when re-dispatching
  after a return that left `unresolved` or `user_decision` items, with
  the decisions on those items by review-log id, each line tagged
  `(orchestrator)` or `(user)`. Authoritative either way — the
  controller records them as `decided (<who>): <answer>` (Deviation 5).
  An id decided against an earlier review-log invocation is written
  qualified, `[<id> inv <i>]`; the controller drops a qualified line
  whose `<i>` is not its current entry's (Deviation 5)
```

with

```
- `[RESUME_ANSWER]` — OPTIONAL content, always passed: `RESUME_ANSWER=`
  (empty) on a first dispatch, which removes the placeholder line and
  leaves the `## Resume Answer` section with no answer line — the fixed
  sentence above the placeholder tells the controller what that means;
  filled from the value file (`RESUME_ANSWER=@<file>`) when
  re-dispatching after a return that left `unresolved` or `user_decision`
  items, with the decisions on those items by review-log id, one answer
  line each, tagged `(orchestrator)` or `(user)`. Authoritative either
  way — the controller records them as `decided (<who>): <answer>`
  (Deviation 5). An id decided against an earlier review-log invocation
  is written qualified, `[<id> inv <i>]`; the controller drops a
  qualified line whose `<i>` is not its current entry's (Deviation 5)
```

The line `       layout): ignore the `## Resume Answer` section and start` (Deviation 5, the pre-7.3.0 case) stays: ignoring the section ignores its lines. Nothing else in the two files changes.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | tail -1 && bash tests/in-run-rulings/run-tests.sh 2>&1 | tail -1 && bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -1 && grep -n 'Resume Answer' skills/orchestrating-development/plan-writer-prompt.md skills/orchestrating-development/code-review-loop-prompt.md`
Expected: `Results: 140 passed, 0 failed` for fill-prompt (116 + 24); `Results: 500 passed, 0 failed` for in-run-rulings (496 + 4); sdd-scripts `Results: 193 passed, 0 failed` (its drift check on the loop template still finds Deviation 5's "always starts a new invocation" sentence); the grep shows no line containing `section is present`, `section present` or `(omit`.

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/plan-writer-prompt.md skills/orchestrating-development/code-review-loop-prompt.md tests/fill-prompt/run-tests.sh tests/in-run-rulings/run-tests.sh
git commit -m "feat(orchestrator): Resume Answer section present on every dispatch in the plan-writer and code-review-loop templates" --trailer "Session: orchestrator-prompt-pointer" --trailer "Stage: task 2/6"
```

---

### Task 3: The `## Resume Answer` section of the batch-controller template

**Files:**
- Modify: `skills/orchestrating-development/batch-controller-prompt.md`
- Test: `tests/fill-prompt/run-tests.sh` (new section 12)
- Test: `tests/in-run-rulings/run-tests.sh` (one assertion rewritten as three)

**Security flag:** `none`

**Does NOT cover:** the orchestrator's Phase 3 fill command (Task 5); the batch template's Deviation 1 and Batch Parameters sentences, which already key on the presence of a `[task <n>/<k>]` **line** in `## Resume Answer` and stay byte-identical.

**Contract:**
- Wording artifact: the `## Resume Answer` section and legend bullet of `batch-controller-prompt.md`
  - Must convey: the heading is `## Resume Answer` without a parenthetical; the six existing prose lines about an `amend plan: …` answer stay; the fixed sentence `A section with no line below this sentence means the run has recorded no answer.` is the last body line before `[RESUME_ANSWER]`; the legend says the placeholder is passed empty only when the run has recorded no answer at all and filled from the value file otherwise, on every dispatch, first or repeat.
  - Invariants: the phrases `tests/in-run-rulings/run-tests.sh` pins in the legend (`(orchestrator)`, `(user)`, `[task <n>/<k>]`, `authoritative either way`, `An `amend plan: …` answer is the record of an amendment the orchestrator has already made and committed`, `never edits the plan itself, its only write to the plan file staying the checkbox tick`, `with every answer the run has recorded so far, whatever batch its task belongs to`, `never as a heading or a section of this prompt and never as a second answer verb, whatever words it contains`, `A `[task <n>/<k>]` line reaches only task `<n>`'s implementer, never a different task the same conflict touched`, `a `plan governs` answer for a conflict between tasks has no effect on the other task; only an `amend plan: …` answer reaches it`, `a bare `[task <n>]` line from the user means `[task <n>/1]``) and in the body (`the implementer follows the amended plan text and never edits the plan itself`, `under Deviation 1's pre-flight rule`, `A bare `[task <n>]` line always means `[task <n>/1]`, whatever the number of sections the report file holds`, every Deviation 1 pin) are kept; the anchor `` `[RESUME_ANSWER]` — OPTIONAL `` stays at the start of the legend bullet; the one changed pin is the old heading `## Resume Answer (omit only when the run has recorded no answer at all)`, replaced by the new heading and the fixed sentence.
  - Verification: `bash tests/fill-prompt/run-tests.sh` section 12; `bash tests/in-run-rulings/run-tests.sh`.
- Test artifacts: section 12 of `tests/fill-prompt/run-tests.sh` (fills without `BATCH_NUMBER`; the quoted task list; the section with an empty value and with a two-line value file; the never-rewrite guard; the unquoted task list) and the three assertions in `tests/in-run-rulings/run-tests.sh`.
  - Invariant: the section fails on the current template (old heading) and passes after Step 3.

- [x] **Step 1: Write the failing tests**

In `tests/fill-prompt/run-tests.sh`, insert immediately before the final `echo` / `bold "Results: …"` pair (after section 11):

```bash
bold "12. The batch-controller template: no BATCH_NUMBER, the Resume Answer section, the never-rewrite guard"
BATCH_TEMPLATE="$ORCH_DIR/batch-controller-prompt.md"
AMEND_FIRST_LINE='An `amend plan: …` answer in this section is the record of an'
TASK_FIRST_ANSWER='[task 2/1] (orchestrator): plan governs: "clause" — docs/plan.md'
TASK_SECOND_ANSWER='[task 3] (user): amend plan: use the constant'
printf '%s\n' "$TASK_FIRST_ANSWER" "$TASK_SECOND_ANSWER" > "$WORK/task-answers.txt"
# Every value of the batch template except the task list and the
# RESUME_ANSWER argument. BATCH_NUMBER is never passed: it stands only in the
# wrapper, which the script does not write.
batch_fill() { # out TASK_LIST-value RESUME_ANSWER-argument
  fill --template "$BATCH_TEMPLATE" --out "$1" \
    'SDD_SKILL_PATH=/plug/subagent-driven-development/SKILL.md' \
    'SDD_SCRIPTS_DIR=/plug/subagent-driven-development/scripts' \
    'IMPLEMENTER_PROMPT_PATH=/plug/subagent-driven-development/implementer-prompt.md' \
    'TASK_REVIEWER_PROMPT_PATH=/plug/subagent-driven-development/task-reviewer-prompt.md' \
    'PLAN_PATH=/repo/docs/plan.md' "TASK_LIST=$2" 'TASK_RANGE=4..6' 'FIRST_BATCH=yes' "$3"
}
batch_fill "$WORK/batch-empty.md" '4, 5, 6' 'RESUME_ANSWER='
assert_eq "batch template: fills without BATCH_NUMBER and exits 0" "$STATUS" "0"
assert_file_contains "batch template: quoted task list inserted verbatim" "$WORK/batch-empty.md" 'Tasks to implement, in order: 4, 5, 6'
assert_file_contains "batch template: the task list is substituted inside the pre-flight sentence too" "$WORK/batch-empty.md" 'never best-guess a number inside `4, 5, 6`'
assert_file_contains "batch template: task range filled into the return line" "$WORK/batch-empty.md" 'BATCH_COMPLETE tasks=4..6'
assert_file_has_line "batch template: empty value keeps the Resume Answer heading" "$WORK/batch-empty.md" "$RESUME_HEADING"
assert_file_not_contains "batch template: empty value leaves no omit parenthetical" "$WORK/batch-empty.md" '## Resume Answer (omit'
assert_file_has_line "batch template: empty value keeps the amend-plan paragraph" "$WORK/batch-empty.md" "$AMEND_FIRST_LINE"
assert_file_has_line "batch template: empty value keeps the fixed sentence" "$WORK/batch-empty.md" "$FIXED_SENTENCE"
assert_eq "batch template: empty value leaves no answer line below the fixed sentence" "$(line_below_fixed_sentence "$WORK/batch-empty.md")" ""
assert_file_not_matches "batch template: no residual placeholder" "$WORK/batch-empty.md" "$PLACEHOLDER_ERE"
assert_eq "batch template: last output line is the dedented last body line" "$(tail -n 1 "$WORK/batch-empty.md")" "$(last_body_line "$BATCH_TEMPLATE")"
batch_fill "$WORK/batch-two.md" '4, 5, 6' "RESUME_ANSWER=@$WORK/task-answers.txt"
assert_eq "batch template: two-line answer file exits 0" "$STATUS" "0"
assert_eq "batch template: the first answer line sits directly below the fixed sentence" "$(line_below_fixed_sentence "$WORK/batch-two.md")" "$TASK_FIRST_ANSWER"
assert_file_has_line "batch template: the second answer line is inserted" "$WORK/batch-two.md" "$TASK_SECOND_ANSWER"
# The never-rewrite guard: a dispatched name reused with different content
# exits 5 and leaves the file as it was.
batch_fill "$WORK/batch-empty.md" '7, 8' 'RESUME_ANSWER='
assert_eq "batch template: re-filling a dispatched name with different content exits 5" "$STATUS" "5"
assert_file_contains "batch template: the refusal says the file already exists" "$ERRF" 'file already exists'
assert_file_contains "batch template: the existing file is unchanged" "$WORK/batch-empty.md" 'Tasks to implement, in order: 4, 5, 6'
# An unquoted task list splits into three arguments; the second is not
# NAME=<value>, so the script exits 1 before reading anything.
fill --template "$BATCH_TEMPLATE" --out "$WORK/batch-unquoted.md" TASK_LIST=4, 5, 6
assert_eq "batch template: an unquoted task list is a usage error (exit 1)" "$STATUS" "1"
assert_absent "batch template: unquoted task list writes nothing" "$WORK/batch-unquoted.md"
```

In `tests/in-run-rulings/run-tests.sh`, replace

```bash
# The section heading's condition for omitting the section must match the
# placeholder documentation's: no answer recorded by the run at all.
assert_in_range "batch-controller Resume Answer heading states the omit condition" \
  "$BATCH_PROMPT" '## Resume Answer (omit only when the run has recorded no answer at all)' \
  1 "$BATCH_RA_LINE" exact
```

with

```bash
# Prompt-pointer dispatch: the section is present on every dispatch, its
# heading carries no omit condition, and one fixed sentence of the body says
# what an empty section means (orchestrator-prompt-pointer design, "Template
# changes" item 2).
# `exact` mode is a per-line substring match in this suite, so this line
# also matches the old parenthesized heading; the negative assertion below
# it is the one that rejects the parenthetical.
assert_in_range "batch-controller Resume Answer heading line exists" \
  "$BATCH_PROMPT" '    ## Resume Answer' 1 "$BATCH_RA_LINE" exact
assert_absent_in_range_folded "batch-controller Resume Answer heading no longer states an omit condition" \
  "$BATCH_PROMPT" '## Resume Answer (omit' 1 "$BATCH_RA_LINE" exact
assert_in_range "batch-controller Resume Answer section states what an empty section means" \
  "$BATCH_PROMPT" 'A section with no line below this sentence means the run has recorded no answer.' \
  1 "$BATCH_RA_LINE" exact
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | grep -E 'FAIL|Results'; bash tests/in-run-rulings/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL — fill-prompt reports `batch template: empty value keeps the Resume Answer heading (no line exactly: ## Resume Answer)`, `batch template: empty value leaves no omit parenthetical …`, `batch template: empty value keeps the fixed sentence …`, `batch template: the first answer line sits directly below the fixed sentence …`; in-run-rulings reports `batch-controller Resume Answer heading no longer states an omit condition (still present …)` and `batch-controller Resume Answer section states what an empty section means (not inside range …)`, `Results: 500 passed, 2 failed`.

- [x] **Step 3: Rewrite the batch template**

`skills/orchestrating-development/batch-controller-prompt.md` — replace the heading line

```
    ## Resume Answer (omit only when the run has recorded no answer at all)
```

with

```
    ## Resume Answer
```

and replace the end of that section

```
    itself, its only write to the plan file staying the checkbox tick.

    [RESUME_ANSWER]
```

with

```
    itself, its only write to the plan file staying the checkbox tick.

    A section with no line below this sentence means the run has recorded no answer.
    [RESUME_ANSWER]
```

Then replace the start of the legend bullet

```
- `[RESUME_ANSWER]` — OPTIONAL: omitted, together with its `## Resume
  Answer` heading, only when the run has recorded no answer at all;
  filled otherwise, on every dispatch, first or repeat, with every answer
  the run has recorded so far, whatever batch its task belongs to — one
```

with

```
- `[RESUME_ANSWER]` — OPTIONAL content, always passed: `RESUME_ANSWER=`
  (empty) only when the run has recorded no answer at all, which removes
  the placeholder line and leaves the `## Resume Answer` section with no
  answer line — the fixed sentence above the placeholder tells the
  controller what that means; filled from the value file
  (`RESUME_ANSWER=@<file>`) otherwise, on every dispatch, first or
  repeat, with every answer the run has recorded so far, whatever batch
  its task belongs to — one
```

The rest of the bullet (from `` `[task <n>/<k>]` line each `` to the end) and everything else in the file stay byte-identical.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | tail -1 && bash tests/in-run-rulings/run-tests.sh 2>&1 | tail -1 && git diff --stat && grep -n 'Resume Answer' skills/orchestrating-development/batch-controller-prompt.md skills/orchestrating-development/SKILL.md | grep -i 'omit\|section is present\|section present\|when present'; echo "presence grep exit $?"`
Expected: `Results: 159 passed, 0 failed` for fill-prompt (140 + 19); `Results: 502 passed, 0 failed` for in-run-rulings (500 − 1 + 3); the diff touches only the three files of this task; the presence grep prints nothing and `presence grep exit 1` (every remaining `Resume Answer` mention in the batch template and the orchestrator keys on a `[task <n>/<k>]` line standing in the section, never on the section's presence).

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/batch-controller-prompt.md tests/fill-prompt/run-tests.sh tests/in-run-rulings/run-tests.sh
git commit -m "feat(orchestrator): Resume Answer section present on every dispatch in the batch-controller template" --trailer "Session: orchestrator-prompt-pointer" --trailer "Stage: task 3/6"
```

---

### Task 4: Controller Dispatch Rules, the mechanism's failure boundary, `## Prompt Templates`, and the wording suite

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md` (Controller Dispatch Rules; Major-Error Stop Policy; `## Prompt Templates`)
- Create: `tests/orchestrating-development/run-tests.sh`
- Modify: `CLAUDE.md` (on disk only — gitignored, never staged)

**Security flag:** `none`

**Does NOT cover:** Phase 0 step 9 and the per-phase fill commands (Task 5); the Resume and In-run rulings value-file text (Task 6). The wording suite's sections 7 and 8 for those parts are added by those tasks. The dispatch-rules bullet written here cites "Phase 0 step 9"; that step exists only after Task 5 lands, which is accepted for the one commit in between.

**Contract:**
- Wording artifact: the "Prompt files and the pointer" bullet and the rewritten "Build the prompt" bullet of Controller Dispatch Rules
  - Must convey: one prompt directory per session created by `mktemp -d` (no argument; a printed path under the repository root is a failure; `cygpath -m` once on Git Bash; the literal path copied everywhere and never held in a variable; never recorded in `state.md`, the log, a ruling record, a Case or a commit message; a lost path means `mktemp -d` again with `<k>` restarting at 1, not a failure); every prompt is written once by the fill script from the phase's template; the orchestrator never reads a template and never copies a prompt body into an Agent call; the file-name table; the counter `<k>` and the `ls` recovery; written once and never rewritten after a dispatched pointer, removable with `rm --` before it; a re-dispatch with a different `[RESUME_ANSWER]` is a new fill under the next `<k>`; `test -s` after every fill and before every dispatch, retries included; never dispatch a pointer to a file that failed the check; the `prompt` field is the three-sentence pointer only; the identical retry is the same pointer to the same file.
  - Invariants: the three pointer sentences appear verbatim, each on one physical line; the text holds no `$PROMPT_DIR` token and no occurrence of "paste" in any case; the Agent call keeps `name`, `description`, `model`.
  - Verification: `bash tests/orchestrating-development/run-tests.sh` sections 1 and 2.
- Wording artifact: the prompt-file mechanism failure boundary under `## Major-Error Stop Policy`
  - Must convey: every failure of the mechanism is fatal (log entry owed, `## STOPPED` with the fixed cause text as the heading's one-line reason, `state.md` rewritten, stop); no inline fallback anywhere; the table of failures OF the mechanism with the six cause texts of the spec; the enumeration of the script's exit-5 causes; the table of NOT-mechanism conditions with today's handling (environment death; a slip in the orchestrator's own fill command corrected once; an exit-5 `cannot write` for a lost or unwritable directory → `mktemp -d` again and re-fill under `<k>` = 1, a second one fatal; a malformed return; a lost path; a controller reading another file; a stale directory); the mirrored secrets-hook probe rule (Write tool only; `dispatch-<k>-probe-<n>.txt` removed with `rm --`; outcomes a/b/c; pairs; the withheld-line form `file:line` plus `secret-bearing finding, value withheld`; one retry; second refusal fatal).
  - Invariants: every cause text of the spec's fatal table appears verbatim; every row of the not-mechanism table has a recognizable fragment; the text stands alone (no "see multi-code-review" for the hook rule).
  - Verification: `bash tests/orchestrating-development/run-tests.sh` section 3.
- Wording artifact: `## Prompt Templates`
  - Must convey: the four templates are filled by the script into the prompt directory and never read by the orchestrator; the four file list lines stay.
  - Verification: section 4 of the suite.
- Code artifact: `tests/orchestrating-development/run-tests.sh`
  - Inputs: the orchestrator's text and the four templates; output: PASS/FAIL lines, exit 0 only when every check passes.
  - Invariants: pure bash + grep/awk, no `/dev/stdin`, no process substitution, temp files under `mktemp -d` removed on exit; ranges located by whole-line heading matches so that a prose mention of a heading cannot retarget a range; prose fragments are matched on a folded copy of their range (lines trimmed and joined with one space), so that wrapping the orchestrator's text across a line break never fails a check, while whole-line needles (list lines, template wrapper lines, the fixed sentence) are matched unfolded; the suite fails on the pre-change orchestrator text.
  - Verification: the runs of Steps 2 and 4.
- Test-block entry in `CLAUDE.md`: on-disk only; verification `git status --porcelain CLAUDE.md` prints nothing (the file is ignored) and `git ls-files --error-unmatch CLAUDE.md` fails.

- [x] **Step 1: Write the failing test**

Create `tests/orchestrating-development/run-tests.sh` with this content and make it executable (`chmod +x`):

```bash
#!/usr/bin/env bash
# orchestrating-development wording test suite: static checks on the
# prompt-pointer dispatch text of skills/orchestrating-development/SKILL.md
# (the orchestrator) and on its four controller prompt templates.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# extracted text goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-09-06-orchestrator-prompt-pointer/
# specs/orchestrator-prompt-pointer-design.md, section "Testing strategy"
# item 2.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORCH_DIR="$ROOT/skills/orchestrating-development"
ORCH_SKILL="$ORCH_DIR/SKILL.md"
TEMPLATES=(plan-writer-prompt.md doc-review-loop-prompt.md batch-controller-prompt.md code-review-loop-prompt.md)
# The three templates that carry a `## Resume Answer` section.
RESUME_TEMPLATES=(plan-writer-prompt.md batch-controller-prompt.md code-review-loop-prompt.md)

# Section headings of the orchestrator, matched as whole lines.
H_DISPATCH='## Controller Dispatch Rules (apply to every phase)'
H_PHASE0='## Phase 0 — Setup (the only interactive moment)'
H_PHASE1='## Phase 1 — Plan Writing'
H_PHASE5='## Phase 5 — Completion'
H_RESUME='## Resume'
H_INRUN='## In-run rulings'
H_MAJOR='## Major-Error Stop Policy'
H_GUARD='## Guard Interaction'
H_TEMPLATES='## Prompt Templates'

# Wording contracts. Each is one fixed string.
POINTER_PREFIX='Your complete instructions are in the file'
POINTER_FIRST='Your complete instructions are in the file <ABSOLUTE PATH>.'
POINTER_READ='Read that file once, with the Read tool, before doing anything else, and follow it as your only instructions.'
POINTER_ONLY='Nothing else in that directory is for you; do not read any other file there.'
PROMPT_DIR_VARIABLE='$PROMPT_DIR'
MKTEMP='mktemp -d'
FILL_SCRIPT='fill-prompt.js'
TEST_S='test -s'
NEVER_READS='never read a template'
NEVER_REWRITTEN='written once and never rewritten'
SAME_POINTER='the same pointer to the same file'
NEVER_FAILED_FILE='never dispatch a pointer to a file that failed the check'
NO_FALLBACK='no inline fallback'
VALUE_WITHHELD='value withheld'
NO_HEREDOC='never with a heredoc'
PASTE='paste'
FILL_DOT='Fill `./'
READ_DOT='Read `./'
# `## STOPPED` cause texts of the fatal rows, and the Node row's wording.
CAUSES=(
  'prompt directory could not be created — <error text>'
  'prompt file <name> not produced — <the script'"'"'s message, or "empty">'
  'Treated as the script failing'
  'value file <name> could not be written — <the error>'
  'value file <name> refused twice by protect-secrets — <the hook'"'"'s reason>'
  'prompt file <name> not read by <controller name>'
)
# One fragment per row of the not-mechanism table.
NOT_MECHANISM_ROWS=(
  'dies of the environment'
  'A slip in your own fill command'
  'treat it as a path lost from context'
  'unusable on format alone'
  'lost from your context'
  'reads another file in the directory'
  'stale directory from an earlier session'
)
# File names of the prompt directory.
FILE_NAMES=(
  'dispatch-<k>-plan-writer.md'
  'dispatch-<k>-plan-review.md'
  'dispatch-<k>-batch-<n>.md'
  'dispatch-<k>-code-review.md'
  'dispatch-<k>-answers.txt'
  'dispatch-<k>-probe-<n>.txt'
)
# Template wrapper and body contracts.
AGENT_LINE='Agent tool (general-purpose):'
NAME_PREFIX='  name: "orch-'
PROMPT_OPEN='  prompt: |'
NOTHING_ELSE='**Nothing else may be added to the prompt.**'
RESUME_HEADING='    ## Resume Answer'
FIXED_SENTENCE='    A section with no line below this sentence means the run has recorded no answer.'
PLACEHOLDER_LINE='    [RESUME_ANSWER]'
M_TOKEN='[M]'
SINGLE_LETTER_ERE='\[[A-Z]\]'
CHECKLIST_LINE='       `- [X] unresolved: <reason> — <finding summary>`.'

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
: "${WORK:?mktemp failed — refusing to run with an empty work path}"
trap 'rm -rf "$WORK"' EXIT

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }
ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}
assert_file_not_contains_i() { # desc file needle (case-insensitive)
  if grep -qiF -- "$3" "$2"; then bad "$1 (must not contain, in any case: $3)"; else ok "$1"; fi
}
assert_file_has_line() { # desc file exact-line (whole-line match, fixed string)
  if grep -qxF -- "$3" "$2"; then ok "$1"; else bad "$1 (no line exactly: $3)"; fi
}
# Join the lines of file $1 into one line — each line trimmed of leading and
# trailing blanks, lines separated by one space — so that a prose fragment
# that the text wraps across a line break still matches as one fixed
# string. Whole-line needles never go through this; they use
# assert_file_has_line on the unfolded file.
fold_file() { # file
  awk '{ line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line); if (NR > 1) printf " "; printf "%s", line } END { print "" }' "$1"
}
assert_folded_contains() { # desc file needle (fixed string, matched across line breaks)
  if fold_file "$2" | grep -qF -- "$3"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}

# Line number of the first line of file $1 equal to $2 as a whole line;
# empty when absent.
first_line_of() { grep -nxF -- "$2" "$1" | head -n 1 | cut -d: -f1; }
# Write the lines of file $2 from heading $3 (inclusive) to heading $4
# (exclusive) into file $5. A missing or inverted range writes an empty file
# and FAILs, so that every later check on that file fails visibly.
extract_range() { # label file start-heading end-heading out
  local start end
  start="$(first_line_of "$2" "$3")"
  end="$(first_line_of "$2" "$4")"
  if [ -z "$start" ] || [ -z "$end" ] || [ "$start" -ge "$end" ]; then
    : > "$5"
    bad "$1: could not locate the range '$3' .. '$4' in ${2#$ROOT/}"
    return
  fi
  awk -v s="$start" -v e="$end" 'NR >= s && NR < e' "$2" > "$5"
  ok "$1: range located ($start..$end)"
}
# The line right below the first line of file $1 that equals $2 as a whole
# line; empty when absent or last. The needle reaches awk through the
# environment so that no character of it is reinterpreted.
line_below() { # file exact-line
  needle="$2" awk 'BEGIN { n = ENVIRON["needle"] } found { print; exit } $0 == n { found = 1 }' "$1"
}

DISPATCH_RANGE="$WORK/dispatch.txt"
PHASE0_RANGE="$WORK/phase0.txt"
PHASES_RANGE="$WORK/phases.txt"
RESUME_RANGE="$WORK/resume.txt"
INRUN_RANGE="$WORK/inrun.txt"
MAJOR_RANGE="$WORK/major.txt"
TEMPLATES_RANGE="$WORK/templates.txt"

bold "0. Section ranges of the orchestrator"
extract_range "Controller Dispatch Rules" "$ORCH_SKILL" "$H_DISPATCH" "$H_PHASE0" "$DISPATCH_RANGE"
extract_range "Phase 0" "$ORCH_SKILL" "$H_PHASE0" "$H_PHASE1" "$PHASE0_RANGE"
extract_range "Phases 1 to 4" "$ORCH_SKILL" "$H_PHASE1" "$H_PHASE5" "$PHASES_RANGE"
extract_range "Resume" "$ORCH_SKILL" "$H_RESUME" "$H_INRUN" "$RESUME_RANGE"
extract_range "In-run rulings" "$ORCH_SKILL" "$H_INRUN" "$H_MAJOR" "$INRUN_RANGE"
extract_range "Major-Error Stop Policy" "$ORCH_SKILL" "$H_MAJOR" "$H_GUARD" "$MAJOR_RANGE"
# `## Prompt Templates` is the last section: its range runs to the end.
TEMPLATES_START="$(first_line_of "$ORCH_SKILL" "$H_TEMPLATES")"
if [ -n "$TEMPLATES_START" ]; then
  awk -v s="$TEMPLATES_START" 'NR >= s' "$ORCH_SKILL" > "$TEMPLATES_RANGE"
  ok "Prompt Templates: range located ($TEMPLATES_START..end)"
else
  : > "$TEMPLATES_RANGE"
  bad "Prompt Templates: heading '$H_TEMPLATES' not found"
fi

bold "1. Controller Dispatch Rules: the prompt directory, the fill, the check, the pointer"
for needle in "$MKTEMP" "$FILL_SCRIPT" "$TEST_S" "$POINTER_PREFIX" "$POINTER_READ" "$POINTER_ONLY" \
              "$NEVER_READS" "$NEVER_REWRITTEN" "$SAME_POINTER" "$NEVER_FAILED_FILE" \
              'cygpath -m' 'never held in a variable' 'the pointer only' "${FILE_NAMES[@]}"; do
  assert_folded_contains "dispatch rules: contains '$needle'" "$DISPATCH_RANGE" "$needle"
done
# Each pointer sentence stands on one physical line. The dispatch-rules
# text indents them inside a list item, so the indentation is trimmed
# before the whole-line match.
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$DISPATCH_RANGE" > "$WORK/dispatch-trimmed.txt"
for s in "$POINTER_FIRST" "$POINTER_READ" "$POINTER_ONLY"; do
  assert_file_has_line "dispatch rules: pointer sentence on one physical line: '$s'" "$WORK/dispatch-trimmed.txt" "$s"
done

bold "2. Negative needles over the whole orchestrator text"
assert_file_not_contains "orchestrator never holds the prompt directory in a shell variable" "$ORCH_SKILL" "$PROMPT_DIR_VARIABLE"
assert_file_not_contains_i "orchestrator never says '$PASTE'" "$ORCH_SKILL" "$PASTE"
for t in "${TEMPLATES[@]}"; do
  assert_file_not_contains "orchestrator never reads ./$t" "$ORCH_SKILL" "${READ_DOT}${t}"
done

bold "3. Major-Error Stop Policy: every failure of the mechanism is fatal, with its cause text"
for needle in "${CAUSES[@]}" "${NOT_MECHANISM_ROWS[@]}" "$VALUE_WITHHELD" "$NEVER_FAILED_FILE" \
              "$NO_FALLBACK" "$SAME_POINTER" "$NO_HEREDOC" 'hooks/safety/protect-secrets.js' \
              'dispatch-<k>-probe-<n>.txt' 'Never withhold a line on this outcome'; do
  assert_folded_contains "stop policy: contains '$needle'" "$MAJOR_RANGE" "$needle"
done

bold "4. Prompt Templates: filled by the script, never read"
assert_folded_contains "prompt templates: names the fill script" "$TEMPLATES_RANGE" "$FILL_SCRIPT"
assert_folded_contains "prompt templates: never read by the orchestrator" "$TEMPLATES_RANGE" 'never read by the orchestrator'
for t in "${TEMPLATES[@]}"; do
  assert_file_has_line "prompt templates: lists ./$t" "$TEMPLATES_RANGE" "- \`./$t\`"
done

bold "5. The four templates: no single-letter placeholder, wrapper lines kept"
for t in "${TEMPLATES[@]}"; do
  f="$ORCH_DIR/$t"
  assert_file_not_contains "$t: no [M] token" "$f" "$M_TOKEN"
  assert_file_has_line "$t: Agent tool wrapper line" "$f" "$AGENT_LINE"
  assert_file_contains "$t: name line starts with orch-" "$f" "$NAME_PREFIX"
  assert_file_has_line "$t: prompt: | line" "$f" "$PROMPT_OPEN"
  # A substring check, not a whole line: plan-writer-prompt.md continues the
  # sentence on the same line, and that line stays byte-identical.
  assert_file_contains "$t: nothing-else line" "$f" "$NOTHING_ELSE"
  single="$(grep -cE -- "$SINGLE_LETTER_ERE" "$f" | tr -d ' ')"
  if [ "$t" = "doc-review-loop-prompt.md" ]; then
    assert_eq "$t: exactly one line with a single-letter bracket token (the checklist marker)" "$single" "1"
    assert_file_has_line "$t: the checklist marker line is byte-identical" "$f" "$CHECKLIST_LINE"
  else
    assert_eq "$t: no single-letter bracket token" "$single" "0"
  fi
done

bold "6. The Resume Answer section: heading without a parenthetical, the fixed sentence, the placeholder below it"
for t in "${RESUME_TEMPLATES[@]}"; do
  f="$ORCH_DIR/$t"
  assert_file_has_line "$t: Resume Answer heading stands alone" "$f" "$RESUME_HEADING"
  assert_file_not_contains "$t: no omit parenthetical on the heading" "$f" '## Resume Answer (omit'
  assert_file_has_line "$t: the fixed sentence is one line of the body" "$f" "$FIXED_SENTENCE"
  assert_eq "$t: the placeholder line follows the fixed sentence directly" "$(line_below "$f" "$FIXED_SENTENCE")" "$PLACEHOLDER_LINE"
done
assert_file_not_contains "doc-review-loop-prompt.md: has no Resume Answer section" "$ORCH_DIR/doc-review-loop-prompt.md" 'Resume Answer'

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
```

- [x] **Step 2: Run the test to verify it fails**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL — every section 1 needle (`dispatch rules: contains 'mktemp -d' (missing: …)` and the others), every section 3 cause and row, section 4's `prompt templates: names the fill script`; sections 5 and 6 pass (Tasks 1–3 shipped them); `Results: <p> passed, <n> failed` with `<n>` ≥ 40.

- [x] **Step 3: Write the orchestrator text**

In `skills/orchestrating-development/SKILL.md`, under `## Controller Dispatch Rules (apply to every phase)`, replace the bullet

```
- Build the prompt ONLY from the filled template — never pass conversation
  history, prior phases' returns, or your own reasoning.
```

with the two bullets

````
- **Prompt files and the pointer.** A controller's instructions are a
  file, not the `prompt` field. Once per session, before the session's
  first fill — Phase 0 step 9 in a fresh run; on a resume, the Resume
  step that first fills a prompt — run `mktemp -d` as its own Bash
  command, with no argument (never a template and never a path inside
  the repository), and copy the literal path it prints — written
  `<PROMPT_DIR>` in this file — into every later command, Write call and
  pointer. A printed path under the repository root is treated as a
  `mktemp -d` failure. On Git Bash (Windows) — when `uname -s` prints a
  name beginning with `MINGW` or `MSYS` — first convert that path once
  with `cygpath -m "<printed path>"` as its own command and use the
  converted path as `<PROMPT_DIR>`; on every other platform the printed
  path is used as is. A shell variable set in one tool call does not
  exist in the next: the path is always spelled out in full, never held
  in a variable of any name. The path never appears in `state.md`, the
  orchestration log, a ruling record, a Case or a commit message. When
  the literal path is no longer in your context — after a context
  compaction, typically — do not guess it, do not search the temporary
  location for it and do not reuse a path from any file: run `mktemp -d`
  again and continue in the new directory, where the counter `<k>` below
  restarts at 1. That is not a failure of the mechanism: every file is
  named by the counter, and a re-fill from the same values produces the
  same content, so an identical retry issued after the path was lost
  re-fills the prompt under `<k>` = 1 there and is still the identical
  dispatch of the retry rule. Every prompt is written once into
  `<PROMPT_DIR>` by the fill script,
  `<base>/../multi-code-review/scripts/fill-prompt.js` (`<base>` is this
  skill's base directory), from the phase's template and the values the
  phase's fill command lists; you never read a template and never copy a
  prompt body into an Agent call. File names, all in `<PROMPT_DIR>`,
  where `<k>` counts the fills run into the current prompt directory
  from 1 and is never reused inside it, and `<label>` names the
  dispatch:

  | Dispatch | Prompt file | Value file (only when the run has recorded answers) |
  |---|---|---|
  | Phase 1 plan writer | `dispatch-<k>-plan-writer.md` | `dispatch-<k>-answers.txt` |
  | Phase 2 plan-review loop | `dispatch-<k>-plan-review.md` | — (the template has no `[RESUME_ANSWER]`) |
  | Phase 3 batch `<n>` | `dispatch-<k>-batch-<n>.md` | `dispatch-<k>-answers.txt` |
  | Phase 4 code-review loop | `dispatch-<k>-code-review.md` | `dispatch-<k>-answers.txt` |
  | Secrets-hook probe of value file `<k>`, line `<n>` (Major-Error Stop Policy) | — | `dispatch-<k>-probe-<n>.txt`, one line, removed after the probe |

  Keep `<k>` in your context; when unsure of the next value, run
  `ls <PROMPT_DIR>` (one short Bash result) and take the largest number
  after `dispatch-` plus one. A prompt file is written once and never
  rewritten once a pointer to it has been dispatched; before that first
  dispatch you may remove it (`rm -- "<file>"` as its own command) and
  fill it again under the same name when you find the fill's values were
  wrong. A re-dispatch with a different `[RESUME_ANSWER]` — Phase 3 and
  Phase 4 after in-run rulings, Phase 1 after a `BLOCKED` question is
  answered, and any Resume re-dispatch — is a new fill under the next
  `<k>` with its own value file, never a rewrite: the script refuses to
  write `--out` over an existing file with different content (exit 5),
  so a counter slip cannot silently replace a dispatched prompt. The
  value file holds the `[RESUME_ANSWER]` lines and is written with the
  Write tool, never with a heredoc of any kind (Major-Error Stop Policy,
  "The secrets-hook probe"); every other value is short and is passed
  inline, single-quoted, as `'NAME=<value>'`, and never begins with `@`.
  After every fill, and before every dispatch of that file, retries
  included, run `test -s "<PROMPT_DIR>/dispatch-<k>-<label>.md"` as its
  own command; never dispatch a pointer to a file that failed the check.
  The `prompt` field of every controller dispatch is the pointer below
  and nothing else — no answer, no phase name, no path of the run:

  ```
  Your complete instructions are in the file <ABSOLUTE PATH>.
  Read that file once, with the Read tool, before doing anything else, and follow it as your only instructions.
  Nothing else in that directory is for you; do not read any other file there.
  ```

  `<ABSOLUTE PATH>` is the prompt file's absolute path. The Agent call
  keeps its `name` (blocking dispatch, above), its `description` and its
  `model` as before.
- Build the prompt file ONLY from the filled template — the fill command
  lists every value — and keep the `prompt` field the pointer only: never
  pass conversation history, prior phases' returns, or your own
  reasoning, in the file or in the field.
````

In the same section, replace

```
  defaults to 0. Malformed return or controller error → retry the identical
  dispatch once; second failure → major error → stop, logging
  `inconclusive controller: <phase/batch>`.
```

with

```
  defaults to 0. Malformed return or controller error → retry the identical
  dispatch once — the same pointer to the same file, no fill and no new
  file; second failure → major error → stop, logging
  `inconclusive controller: <phase/batch>`.
```

Under `## Major-Error Stop Policy`, after the paragraph that ends `controllers and are handled there by the consumed skills' own rules.` and before the `## Guard Interaction` heading, insert:

```
**Failures of the prompt-file mechanism** (Controller Dispatch Rules,
"Prompt files and the pointer") join the list above. Every one of them
is fatal for the run: write the log entry you owe (if any), append a
`## STOPPED` entry whose heading's `<one-line reason>` is the cause in
the fixed text below — the entry's first line, as today's causes — keep
the `Open:` / `Ruled:` lines when the stop coincides with open items,
rewrite `state.md`, and stop. There is no inline fallback anywhere: a
fallback that copies the template into the `prompt` field would hide
the defect and silently bring the old cost back. A resume after such a
stop creates a fresh directory and re-fills; the resume prompt is the
existing one. The boundary below — what is a failure of the mechanism
and what is not — is the normative copy: a later review finding that
refines a row inside it is a forced ruling for you, not an escalation.

Failures OF the mechanism (fatal):

| Condition | `## STOPPED` cause |
|---|---|
| `mktemp -d` fails, prints a path under the repository root, or `cygpath` fails where the path must be converted | `prompt directory could not be created — <error text>`. Nothing is dispatched. |
| The fill script exits 2 (malformed template); or exits 5 with `cannot read` on an `@<file>` you did write, with `cannot write <out>: existing path could not be read`, or with `cannot write <out>: file already exists` (a dispatched name reused with different content); or exits non-zero a second time after a corrected command; or `test -s` fails on the prompt file | `prompt file <name> not produced — <the script's message, or "empty">`; never dispatch a pointer to a file that failed the check. |
| Node is missing | Treated as the script failing (row above). |
| A value-file Write fails for a reason other than the secrets hook — a permission denial, a tool error, a refusal by another hook — or a probe Write of the rule below is refused for such a reason | `value file <name> could not be written — <the error>` (`<name>` is always the value file's name, `dispatch-<k>-answers.txt`; for a probe, the error text is the refusal or error text, first line, and names the probe file). |
| A value-file Write is refused by `hooks/safety/protect-secrets.js` twice | `value file <name> refused twice by protect-secrets — <the hook's reason>`. The secrets-hook probe below runs between the two attempts. |
| A controller's final message shows it could not read, or did not follow, its prompt file — after the one identical retry of the Controller Dispatch Rules | `prompt file <name> not read by <controller name> — <the first line of each of the two final messages>`. The sign: the final message says it could not read, find or open the file, or it carries neither the report marker nor any of these tokens: the plan path, the topic folder path, the orchestration or review log path, `tasks=`, `task=`, `rounds=` — no sign of the prompt file's content. A message carrying at least one of them, without the marker, is a malformed return (table below). |

The script's exit-5 causes, in full: `cannot read template <path>:
<error>`; `cannot read value file <path>: <error>`; `cannot write <out>:
file already exists`; `cannot write <out>: existing path could not be
read: <error>`; `cannot write <out>: <error>` (any other error text —
a missing directory, a permission error, a full disk). The row above and
the two rows below say which are fatal at once, which are corrected
once, and which mean a lost directory.

NOT failures of the mechanism (today's paths, unchanged):

| Condition | Handling |
|---|---|
| A controller dies of the environment (usage limit, rate limit, tool error, no final message at all) | The identical retry once, then the major-error stop above (`inconclusive controller: <phase/batch>`), as the Controller Dispatch Rules say. The retry is the same pointer to the same file. |
| A slip in your own fill command: the script exits 1 (usage), 3 (a placeholder without a value), 4 (a value naming no placeholder), 5 with `cannot read template` (a wrong `--template` path), or 5 naming an `@<file>` you never wrote | Correct the command once and run it again; a second non-zero exit is fatal (table above). |
| The fill script exits 5 with `cannot write <out>: <error>` for any error text other than `file already exists` and `existing path could not be read` | The prompt directory is gone, unwritable, or the path in the command is wrong: treat it as a path lost from context — `mktemp -d` again and re-fill under `<k>` = 1 in the fresh directory. A second such exit in the fresh directory is fatal (table above): the temporary location itself is not writable. |
| A return unusable on format alone (the marker or a consumed field missing) whose text shows the controller worked on the run | Malformed return: the identical retry once, then the major-error stop above. Not a pointer failure. |
| The prompt directory's path is lost from your context | `mktemp -d` again and continue (Controller Dispatch Rules). |
| A controller reads another file in the directory | Cannot be prevented by wording alone; the directory holds only this session's prompt and value files, and the pointer forbids it. Accepted. |
| A stale directory from an earlier session is still on disk | Never reused (the path is recorded nowhere); the platform's temporary-directory cleaning removes it. Accepted. |

**The secrets-hook probe.** This rule stands here in full so that this
file needs no other skill's text. `hooks/safety/protect-secrets.js` scans
the path of every Read, Edit and Write and the content of every Edit and
Write for hardcoded secrets; `hooks/safety/block-dangerous-commands.js`
and the secrets hook's own file-access patterns scan the whole Bash
command string, a heredoc body included, and their refusals have no
rewrite path. The value file is the one place answer text is written by
a scanned tool — answer text quotes plan clauses and finding text, which
may contain `$(...)`, backticks, or a line equal to a heredoc delimiter —
so it is written with the Write tool and never with a heredoc of any
kind; the fill command itself carries paths, integers and short tokens
and matches no pattern. When `hooks/safety/protect-secrets.js` refuses a
value-file Write, find the offending lines yourself: the hook's refusal
names a credential kind — the kind of the first pattern that matched the
whole content — and never a line. For each line of the file you tried to
write, make ONE Write tool call of a throwaway file holding that one
line, `<PROMPT_DIR>/dispatch-<k>-probe-<n>.txt`, `<n>` counting the probe
Writes for value file `<k>` from 1, and remove it with `rm -- "<file>"`
as its own command after the probe. The probe is a Write tool call and
nothing else: never a Bash command, because
`hooks/safety/block-dangerous-commands.js` would refuse a command that
merely quotes a secret-shaped string, and never a hook path, because a
path such as `hooks/safety/protect-secrets.js` resolves only inside this
plugin's own checkout. Each probe is exactly one of three outcomes:
(a) the Write succeeds — the line is allowed and stays as it is;
(b) the Write is refused by `hooks/safety/protect-secrets.js`, whose
refusal names the credential kind — the line is withheld;
(c) the Write is refused for any other reason — a permission denial, a
tool error, any refusal whose text does not come from
`hooks/safety/protect-secrets.js`. That is a failure of the mechanism
and not a refused line: stop with the `value file <name> could not be
written` cause of the table above. Never withhold a line on this
outcome. When no single line is refused, probe each pair of consecutive
lines the same way — one Write holding the two lines joined by one
newline, under the next `<n>` — and withhold both lines of a refused
pair: a pattern spans at most one line break, so pairs are enough.
Replace every withheld line by a line that keeps its id and its tag and
carries the location instead of the value:
`[<id>] (<tag>): <file:line> — secret-bearing finding, value withheld`
— the location-only form your own "Never reproduce a secret" rule
already imposes on every answer — and retry the Write once; a second
refusal is fatal (table above). Apart from that one replacement, never
alter answer text to pass a hook, and never retry the Write through a
Bash command to get around a refusal.
```

Replace the `## Prompt Templates` section

```
## Prompt Templates

- `./plan-writer-prompt.md`
- `./doc-review-loop-prompt.md`
- `./batch-controller-prompt.md`
- `./code-review-loop-prompt.md`
```

with

```
## Prompt Templates

Filled by `<base>/../multi-code-review/scripts/fill-prompt.js` into the
session's prompt directory, by the fill command each phase states; never
read by the orchestrator, and never copied into a `prompt` field. Their
placeholder legends are for the reader of this file: the script checks
the fill command against the template (exit 3: a body placeholder
without a value; exit 4: a value naming no placeholder).

- `./plan-writer-prompt.md`
- `./doc-review-loop-prompt.md`
- `./batch-controller-prompt.md`
- `./code-review-loop-prompt.md`
```

Then, in `CLAUDE.md` (on disk only; this file is gitignored — never `git add` it), add to the test block after the `tests/fill-prompt/run-tests.sh` line:

```bash
bash tests/orchestrating-development/run-tests.sh  # orchestrator prompt-pointer dispatch and controller-template wording contracts
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'; bash tests/in-run-rulings/run-tests.sh 2>&1 | tail -1; bash tests/writing-plans/run-tests.sh 2>&1 | tail -1; git status --porcelain CLAUDE.md; git ls-files --error-unmatch CLAUDE.md; echo "ls-files exit $?"`
Expected: the wording suite prints only `Results: <p> passed, 0 failed`; in-run-rulings `Results: 502 passed, 0 failed`; writing-plans `Results: 15 passed, 0 failed`; `git status --porcelain CLAUDE.md` prints nothing; `git ls-files` prints an error and `ls-files exit 1`.

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/SKILL.md tests/orchestrating-development/run-tests.sh
git commit -m "feat(orchestrator): prompt files and the pointer in the dispatch rules, the mechanism's failure boundary, and a wording suite" --trailer "Session: orchestrator-prompt-pointer" --trailer "Stage: task 4/6"
```

---

### Task 5: Phase 0 creates the prompt directory; Phases 1–4 fill, check and dispatch the pointer

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md` (Phase 0; Phases 1–4)
- Test: `tests/fill-prompt/run-tests.sh` (new section 13, the cross-check)
- Test: `tests/orchestrating-development/run-tests.sh` (new section 7)

**Security flag:** `none`

**Does NOT cover:** Resume and In-run rulings (Task 6); Phase 5, which dispatches nothing.

**Contract:**
- Wording artifact: Phase 0 step 9
  - Must convey: `mktemp -d` under the Controller Dispatch Rules after the parameters are settled and before the Phase 1 dispatch; a failure is a major error with the cause `prompt directory could not be created — <error text>`, nothing dispatched; `<k>` starts at 1.
  - Verification: wording suite section 7 (`mktemp -d` and the cause fragment in the Phase 0 range).
- Wording artifact: the fill-and-dispatch text of Phases 1, 2, 3 (step 2) and 4
  - Must convey: the fill command of the spec for that phase (as one command, every `NAME=` single-quoted, `<base>` and `<sdd>` explained, the multi-code-review path spelled out as `<base>/../multi-code-review/...`, every path absolute); when the value file is written and when `RESUME_ANSWER=` is passed empty; `[BATCH_NUMBER]` not passed (the orchestrator fills `name` and `description` itself); `test -s` on the phase's file as its own command; "dispatch the pointer to that file"; the expected return unchanged.
  - Invariants: the four fenced blocks holding `fill-prompt.js` name `--template "<base>/<template>.md"` and exactly the `NAME=` set of that template's body placeholders (the cross-check); no line matching ``Fill `./`` between the Phase 1 and Phase 5 headings; the Phase 3 step 5 sentences `tests/in-run-rulings` pins stay verbatim ("the same batch — same task list, same `First batch:` value — is re-dispatched", "a controller failure (no such section) → retry the identical dispatch once → major error → stop", "Every batch dispatch, first or repeat, carries in `[RESUME_ANSWER]` the answer set"); step 2's phrase "the run-wide answer set that step 5 states, filled on every dispatch, first or repeat, whenever this run has recorded any answer" stays.
  - Verification: `bash tests/fill-prompt/run-tests.sh` section 13; wording suite section 7; `bash tests/in-run-rulings/run-tests.sh`.
- Code artifact: section 13 of `tests/fill-prompt/run-tests.sh`
  - Input: the orchestrator's text and the four templates. Output: one PASS/FAIL per fill block, plus the block count and the one-block-per-template check.
  - Invariant: fails when a fill command and its template's body placeholders differ, when a block names no existing template, or when the block count is not four.
  - Verification: the runs of Steps 2 and 4.

- [x] **Step 1: Write the failing tests**

In `tests/fill-prompt/run-tests.sh`, insert immediately before the final `echo` / `bold "Results: …"` pair (after section 12):

```bash
bold "13. The orchestrator's fill commands name exactly the body placeholders of their templates"
# The spec's drift guard ("Testing strategy" item 1): every 'NAME= token of
# each fenced block of the orchestrator's text that holds fill-prompt.js,
# keyed by the template on that block's --template line, must equal the
# template body's placeholder set. Wrapper-only names (BATCH_NUMBER) are not
# passed, so the body set is the comparison target.
ORCH_SKILL="$ROOT/skills/orchestrating-development/SKILL.md"
BLOCKS_DIR="$WORK/orch-blocks"
mkdir -p "$BLOCKS_DIR"
# One file per fenced block of the orchestrator's text (a fence may be
# indented inside a list item).
awk -v dir="$BLOCKS_DIR" '
  /^[ \t]*```/ { if (inblk) { close(out); inblk = 0 } else { inblk = 1; n++; out = dir "/block-" n ".txt" }; next }
  inblk { print > out }
' "$ORCH_SKILL"
# The `[NAME]` placeholders of the prompt body of template $1 — the lines
# after its `prompt: |` line up to the closing fence — one name per line,
# sorted, unique.
template_body_names() { # template
  awk '/^```[ \t]*$/ && seen { exit } seen { print } /^[[:space:]]*prompt: \|[[:space:]]*$/ { seen = 1 }' "$1" \
    | grep -oE '\[[A-Z][A-Z_]*[A-Z]\]' | tr -d '[]' | sort -u
}
FILL_BLOCKS=0
SEEN_TEMPLATES="$WORK/seen-templates.txt"
: > "$SEEN_TEMPLATES"
for blk in "$BLOCKS_DIR"/block-*.txt; do
  [ -e "$blk" ] || continue
  grep -qF 'fill-prompt.js' "$blk" || continue
  FILL_BLOCKS=$((FILL_BLOCKS+1))
  tmpl="$(sed -n 's/.*--template "[^"]*\/\([^"/]*\)".*/\1/p' "$blk" | head -n 1)"
  if [ -z "$tmpl" ] || [ ! -f "$ORCH_DIR/$tmpl" ]; then
    bad "fill block $(basename "$blk"): names no existing template ('$tmpl')"
    continue
  fi
  printf '%s\n' "$tmpl" >> "$SEEN_TEMPLATES"
  grep -oE "'[A-Z][A-Z_]*[A-Z]=" "$blk" | sed -e "s/^'//" -e 's/=$//' | sort -u > "$WORK/cmd-names.txt"
  template_body_names "$ORCH_DIR/$tmpl" > "$WORK/body-names.txt"
  if cmp -s "$WORK/cmd-names.txt" "$WORK/body-names.txt"; then
    ok "fill command for $tmpl names exactly its body placeholders ($(tr '\n' ' ' < "$WORK/cmd-names.txt" | sed 's/ *$//'))"
  else
    bad "fill command for $tmpl and its body placeholders differ"
    diff "$WORK/body-names.txt" "$WORK/cmd-names.txt" || true
  fi
done
assert_eq "the orchestrator holds one fill block per template (four)" "$FILL_BLOCKS" "4"
assert_eq "each template is filled by exactly one block" "$(sort "$SEEN_TEMPLATES" | uniq | wc -l | tr -d ' ')" "4"
```

In `tests/orchestrating-development/run-tests.sh`, insert immediately before the final `echo` / `bold "Results: …"` pair (after section 6):

```bash
bold "7. Phase 0 creates the prompt directory; Phases 1 to 4 fill, check and dispatch the pointer"
assert_folded_contains "phase 0: mktemp -d step" "$PHASE0_RANGE" "$MKTEMP"
assert_folded_contains "phase 0: names the creation-failure cause" "$PHASE0_RANGE" 'prompt directory could not be created'
for t in "${TEMPLATES[@]}"; do
  assert_folded_contains "phases: fill command names --template \"<base>/$t\"" "$PHASES_RANGE" "--template \"<base>/$t\""
done
for name in 'dispatch-<k>-plan-writer.md' 'dispatch-<k>-plan-review.md' 'dispatch-<k>-batch-<n>.md' 'dispatch-<k>-code-review.md'; do
  assert_folded_contains "phases: test -s on $name" "$PHASES_RANGE" "test -s \"<PROMPT_DIR>/$name\""
done
assert_file_not_contains "phases: no template is filled by hand (no 'Fill \`./' line)" "$PHASES_RANGE" "$FILL_DOT"
assert_folded_contains "phases: BATCH_NUMBER is not passed to the script" "$PHASES_RANGE" 'is not passed'
POINTER_DISPATCHES="$(grep -cF -- 'dispatch the pointer' "$PHASES_RANGE" | tr -d ' ')"
if [ "$POINTER_DISPATCHES" -ge 4 ]; then
  ok "phases: 'dispatch the pointer' appears $POINTER_DISPATCHES times (at least once per phase)"
else
  bad "phases: 'dispatch the pointer' appears $POINTER_DISPATCHES times, fewer than 4"
fi
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | grep -E 'FAIL|Results'; bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL — fill-prompt reports `the orchestrator holds one fill block per template (four) (expected '4', got '0')` and `each template is filled by exactly one block (expected '4', got '0')`, `Results: 159 passed, 2 failed`; the wording suite reports `phase 0: mktemp -d step (missing: mktemp -d)`, `phase 0: names the creation-failure cause …`, the four `--template` needles, the four `test -s` needles, `phases: no template is filled by hand … (must not contain: Fill `./)`, `phases: BATCH_NUMBER is not passed …` and the pointer count as FAIL.

- [x] **Step 3: Write the phase text**

In `skills/orchestrating-development/SKILL.md`, Phase 0, after step 8

```
8. **Seed `state.md`:** the sections writing-plans seeds, plus
   `## Orchestration` (format below).
```

add step 9:

```
9. **Prompt directory:** run `mktemp -d` as its own command, under the
   Controller Dispatch Rules ("Prompt files and the pointer"): no
   argument, the printed path copied literally into every later command,
   Write call and pointer and never held in a variable, converted once
   with `cygpath -m` on Git Bash. A failure here — the command fails,
   prints a path under the repository root, or `cygpath` fails where it
   must run — is a major error: stop with the `## STOPPED` cause
   `prompt directory could not be created — <error text>`, nothing
   dispatched (Major-Error Stop Policy). The fill counter `<k>` of the
   prompt-file names starts at 1.
```

Leave the paragraph `Any failure in steps 1–6 is a **pre-log stop** …` unchanged (step 9 runs after the log exists, so its failure is the `## STOPPED` stop above).

Replace the whole `## Phase 1 — Plan Writing` body

```
Fill `./plan-writer-prompt.md` (spec path; output plan path
`<topic folder>/plans/<slug>.md`) and dispatch. Expected return: `PLAN_READY <path> tasks=<T>` or
`BLOCKED: <question>` (spec ambiguity → major error → stop). On success:
commit the plan (`docs(plan): <slug> implementation plan`), append and
commit the Phase 1 log entry.
```

with

````
Fill the plan-writer prompt into the session's prompt directory, as one
command (every `NAME=` argument single-quoted):

```bash
node "<base>/../multi-code-review/scripts/fill-prompt.js" \
  --template "<base>/plan-writer-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-plan-writer.md" \
  'WRITING_PLANS_SKILL_PATH=<base>/../writing-plans/SKILL.md' \
  'SPEC_PATH=<spec path>' 'PLAN_PATH=<topic folder>/plans/<slug>.md' \
  'RESUME_ANSWER='
```

`<base>` is this skill's base directory, from which the Controller
Dispatch Rules resolve the procedure-source paths; every path value is
absolute. `RESUME_ANSWER=` is empty on a first dispatch. A re-dispatch
after an answered `BLOCKED` question (Resume step 3) writes the answer —
one line, without an id or a tag — with the Write tool to
`<PROMPT_DIR>/dispatch-<k>-answers.txt` and passes
`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'` instead. Then run
`test -s "<PROMPT_DIR>/dispatch-<k>-plan-writer.md"` as its own command
and dispatch the pointer to that file (`name: "orch-plan-writer"`, the
template's `description`, the session model with the sonnet floor).
Expected return: `PLAN_READY <path> tasks=<T>` or
`BLOCKED: <question>` (spec ambiguity → major error → stop). On success:
commit the plan (`docs(plan): <slug> implementation plan`), append and
commit the Phase 1 log entry.
````

Replace the `## Phase 2 — Plan Review Loop` opening

```
If N_plan = 0, log the skip and go to Phase 3. Otherwise fill
`./doc-review-loop-prompt.md` (plan path, spec path, N_plan, M) and dispatch.
Expected return: `REVIEW_DONE rounds=<r> outcome=<converged|cap>
```

with

````
If N_plan = 0, log the skip and go to Phase 3. Otherwise fill the
plan-review prompt into the session's prompt directory, as one command
(every `NAME=` argument single-quoted):

```bash
node "<base>/../multi-code-review/scripts/fill-prompt.js" \
  --template "<base>/doc-review-loop-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-plan-review.md" \
  'MULTI_DOC_REVIEW_SKILL_PATH=<base>/../multi-doc-review/SKILL.md' \
  'REVIEWER_PROMPT_PATH=<base>/../multi-doc-review/reviewer-prompt.md' \
  'WRITING_PLANS_SKILL_PATH=<base>/../writing-plans/SKILL.md' \
  'PLAN_PATH=<plan path>' 'SPEC_PATH=<spec path>' 'N_PLAN=<N_plan>' \
  'M_REVIEWERS=<M>'
```

This template has no `[RESUME_ANSWER]` and no value file. Then run
`test -s "<PROMPT_DIR>/dispatch-<k>-plan-review.md"` as its own command
and dispatch the pointer to that file (`name: "orch-plan-review"`).
Expected return: `REVIEW_DONE rounds=<r> outcome=<converged|cap>
````

In `## Phase 3 — Implementation Batches`, replace step 2

```
2. Fill `./batch-controller-prompt.md` (plan path, task numbers,
   first-batch flag for SDD's Pre-Flight Plan Review, and
   `[RESUME_ANSWER]` — the run-wide answer set that step 5 states, filled
   on every dispatch, first or repeat, whenever this run has recorded any
   answer) and dispatch.
```

with

````
2. Fill the batch prompt into the session's prompt directory, as one
   command (every `NAME=` argument single-quoted — an unquoted
   `TASK_LIST=4, 5, 6` splits into three arguments and exits 1):

   ```bash
   node "<base>/../multi-code-review/scripts/fill-prompt.js" \
     --template "<base>/batch-controller-prompt.md" \
     --out "<PROMPT_DIR>/dispatch-<k>-batch-<n>.md" \
     'SDD_SKILL_PATH=<sdd>/SKILL.md' 'SDD_SCRIPTS_DIR=<sdd>/scripts' \
     'IMPLEMENTER_PROMPT_PATH=<sdd>/implementer-prompt.md' \
     'TASK_REVIEWER_PROMPT_PATH=<sdd>/task-reviewer-prompt.md' \
     'PLAN_PATH=<plan path>' 'TASK_LIST=<i>, <i+1>, <j>' 'TASK_RANGE=<i>..<j>' \
     'FIRST_BATCH=<yes|no>' \
     'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'
   ```

   `<sdd>` is `<base>/../subagent-driven-development`; `<n>` is the
   1-based batch index; `FIRST_BATCH` is `yes` for the first batch of the
   run (SDD's Pre-Flight Plan Review) and `no` otherwise; `TASK_LIST` is
   the selected task numbers, comma-separated. `[RESUME_ANSWER]` is the
   run-wide answer set that step 5 states, filled on every dispatch,
   first or repeat, whenever this run has recorded any answer: write its
   lines with the Write tool to `<PROMPT_DIR>/dispatch-<k>-answers.txt`
   first (`## In-run rulings`, "The answers, and how a ruling reaches the
   plan"); when the run has recorded no answer, write no value file and
   pass `'RESUME_ANSWER='` (empty) instead. `[BATCH_NUMBER]` stands only
   in the template's wrapper and is not passed to the script: fill the
   Agent call's `name` (`orch-batch-<n>`) and `description` yourself, as
   before. Then run `test -s "<PROMPT_DIR>/dispatch-<k>-batch-<n>.md"` as
   its own command and dispatch the pointer to that file.
````

Steps 1, 3, 4 and 5 of Phase 3 stay byte-identical.

In `## Phase 4 — Final Code Review Loop`, replace

```
stop. Fill `./code-review-loop-prompt.md` (BASE = the Phase 0
recorded branch point, N_code, M, plan path, ledger path
`.superpowers/sdd/progress.md`) and dispatch. Expected return:
```

with

````
stop. Fill the code-review prompt into the session's prompt directory,
as one command (every `NAME=` argument single-quoted):

```bash
node "<base>/../multi-code-review/scripts/fill-prompt.js" \
  --template "<base>/code-review-loop-prompt.md" \
  --out "<PROMPT_DIR>/dispatch-<k>-code-review.md" \
  'MULTI_CODE_REVIEW_SKILL_PATH=<base>/../multi-code-review/SKILL.md' \
  'REVIEWER_PROMPT_PATH=<base>/../multi-code-review/reviewer-prompt.md' \
  'TOPIC_DIR=<topic folder, absolute>' 'BASE_SHA=<BASE>' 'N_CODE=<N_code>' \
  'M_REVIEWERS=<M>' 'PLAN_PATH=<plan path>' \
  'LEDGER_PATH=<repository root, absolute>/.superpowers/sdd/progress.md' \
  'RESUME_ANSWER='
```

`<BASE>` is the Phase 0 recorded branch point. `RESUME_ANSWER=` is empty
on a first dispatch; a re-dispatch with answers — after in-run rulings,
or at Resume step 3 — writes them with the Write tool to
`<PROMPT_DIR>/dispatch-<k>-answers.txt` and passes
`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'` instead. Then run
`test -s "<PROMPT_DIR>/dispatch-<k>-code-review.md"` as its own command
and dispatch the pointer to that file (`name: "orch-code-review"`).
Expected return:
````

The paragraph that begins `The filled `code-review-loop-prompt.md` passes `TOPIC_DIR`` stays as it is. Nothing else in Phases 1–5 changes.

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | grep -E 'fill command|FAIL|Results'; bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'; bash tests/in-run-rulings/run-tests.sh 2>&1 | tail -1`
Expected: fill-prompt prints four `PASS: fill command for <template> names exactly its body placeholders (…)` lines and `Results: 165 passed, 0 failed` (159 + 6); the wording suite prints only `Results: <p> passed, 0 failed`; in-run-rulings `Results: 502 passed, 0 failed` (the Phase 3 step 5 pins are proven intact).

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/SKILL.md tests/fill-prompt/run-tests.sh tests/orchestrating-development/run-tests.sh
git commit -m "feat(orchestrator): Phase 0 creates the prompt directory and Phases 1-4 fill, check and dispatch the pointer" --trailer "Session: orchestrator-prompt-pointer" --trailer "Stage: task 5/6"
```

---

### Task 6: Resume and In-run rulings write the answer lines into the value file

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md` (`## Resume` steps 3 and 4; `## In-run rulings`: "The answers, and how a ruling reaches the plan", "The RULING log entry, the commit and the re-dispatch", the idempotence paragraph)
- Test: `tests/orchestrating-development/run-tests.sh` (new section 8)

**Security flag:** `none`

**Does NOT cover:** the composition rules of the answer set (unchanged); Row 13 fixes 2 and 3 and the compaction probe (spec Non-goals).

**Contract:**
- Wording artifact: Resume steps 3 and 4
  - Must convey: a resumed session has no prompt directory, so the re-dispatch step creates it (`mktemp -d`) before its first fill and fills the stopped phase's prompt under `<k>` = 1 with the answer lines written to `<PROMPT_DIR>/dispatch-1-answers.txt`; a re-dispatch that carries no answer line (the Phase 4 moved-HEAD and migrated-run paths) writes no value file and passes `RESUME_ANSWER=` empty, as the Global Constraints require of every phase; step 4 creates the directory the same way before its first fill.
  - Invariants: the sentence `re-dispatch the stopped phase's controller with that `[RESUME_ANSWER]` in the template's placeholder — the only channel for it` stays; the pinned tagging sentence `each tagged `(orchestrator)`, plus the resume prompt's answers, each tagged `(user)`` stays; no `### ` heading is added anywhere in `## Resume` or `## In-run rulings` (the in-run-rulings suite anchors sub-sections by the next `### ` line).
  - Verification: wording suite section 8; `bash tests/in-run-rulings/run-tests.sh`.
- Wording artifact: the In-run rulings re-dispatch text
  - Must convey: the answer lines are the content of `<PROMPT_DIR>/dispatch-<k>-answers.txt`, written with the Write tool and never with a heredoc; the re-dispatch is a new fill under the next `<k>` with that file, `test -s`, then the pointer; a retry's "rebuilt" `[RESUME_ANSWER]` is a new fill from the same ruling-record entry, which produces the same content.
  - Invariants: `re-dispatch the phase's controller with the answers in `[RESUME_ANSWER]` — the only channel`, `a retry rebuilds the identical `[RESUME_ANSWER]` from the ruling-record entry` and `A controller that answers an in-run resume with `BLOCKED: previous invocation left <n> open items …` did not receive the answers — a malformed dispatch: retry the identical dispatch once, then stop under the Major-Error Stop Policy` each stay verbatim as one unbroken sentence (the in-run-rulings suite pins each as one folded fragment); other text may stand between them, and Step 3 places its new sentences between the first and the third.
  - Verification: wording suite section 8; `bash tests/in-run-rulings/run-tests.sh`.

- [ ] **Step 1: Write the failing test**

In `tests/orchestrating-development/run-tests.sh`, insert immediately before the final `echo` / `bold "Results: …"` pair (after section 7):

```bash
bold "8. Resume and In-run rulings: the answer lines go into a value file"
for needle in "$MKTEMP" 'a resumed session has none' 'dispatch-1-answers.txt' '`<k>` = 1' 'the only channel for it' 'no answer line'; do
  assert_folded_contains "resume: contains '$needle'" "$RESUME_RANGE" "$needle"
done
for needle in 'dispatch-<k>-answers.txt' "$NO_HEREDOC" 'the only channel' 'a new fill under the next `<k>`' "$TEST_S"; do
  assert_folded_contains "in-run rulings: contains '$needle'" "$INRUN_RANGE" "$needle"
done
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E 'FAIL|Results'`
Expected: FAIL — `resume: contains 'mktemp -d' (missing: mktemp -d)`, `resume: contains 'a resumed session has none' …`, `resume: contains 'dispatch-1-answers.txt' …`, `resume: contains '`<k>` = 1' …`, `resume: contains 'no answer line' …`, `in-run rulings: contains 'dispatch-<k>-answers.txt' …`, `in-run rulings: contains 'never with a heredoc' …`, `in-run rulings: contains 'a new fill under the next `<k>`' …`, `in-run rulings: contains 'test -s' …`; `Results: <p> passed, 9 failed`.

- [ ] **Step 3: Write the Resume and In-run rulings text**

In `skills/orchestrating-development/SKILL.md`, Resume step 3, replace

```
   resume touched no ruling. Then
   re-dispatch the stopped phase's controller with that `[RESUME_ANSWER]`
   in the template's placeholder — the only channel for it. Phases whose
```

with

```
   resume touched no ruling. Then create the session's prompt directory
   — a resumed session has none: run `mktemp -d` under the Controller
   Dispatch Rules ("Prompt files and the pointer"), before the first
   fill, the counter `<k>` starting at 1 — write the answer lines with
   the Write tool to `<PROMPT_DIR>/dispatch-1-answers.txt`, fill the
   stopped phase's prompt under `<k>` = 1 with that phase's fill command
   and `'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-1-answers.txt'` — when the
   re-dispatch carries no answer line (for example a Phase 4 re-dispatch
   on a moved effective HEAD without answers, or one for a migrated run
   whose old log is absent, below), write no value file and pass
   `'RESUME_ANSWER='`, as every phase does — run its
   `test -s`, and
   re-dispatch the stopped phase's controller with that `[RESUME_ANSWER]`
   in the template's placeholder — the only channel for it. Phases whose
```

Resume step 4, replace

```
4. Otherwise continue at the first incomplete phase/batch. Your own log's
   phase entries are the primary re-run guard; the sub-skills' logs are
   the backstop.
```

with

```
4. Otherwise continue at the first incomplete phase/batch. The session's
   prompt directory is created before that phase's first fill, exactly as
   step 3 creates it (`mktemp -d`, `<k>` from 1). Your own log's
   phase entries are the primary re-run guard; the sub-skills' logs are
   the backstop.
```

Under `### The answers, and how a ruling reaches the plan`, after the paragraph

```
A line without a `(<who>)` tag is a user line — an untagged answer such as
`[I2]: plan governs; [C3]: fix it` keeps working.
```

insert a new paragraph:

```
These lines are the content of the value file
`<PROMPT_DIR>/dispatch-<k>-answers.txt`, written with the Write tool —
never with a heredoc of any kind, because answer text quotes plan clauses
and finding text — and the placeholder is filled from that file by
`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'` in the phase's
fill command (Controller Dispatch Rules, "Prompt files and the pointer").
```

Under `### The RULING log entry, the commit and the re-dispatch`, replace

```
and re-dispatch the phase's controller with the answers in
`[RESUME_ANSWER]` — the only channel. In Phase 3 the answers are the full
set defined above, not only the newest return's. A controller that answers
```

with

```
and re-dispatch the phase's controller with the answers in
`[RESUME_ANSWER]` — the only channel. In Phase 3 the answers are the full
set defined above, not only the newest return's. The re-dispatch is a new
fill under the next `<k>`: write the answer lines with the Write tool to
`<PROMPT_DIR>/dispatch-<k>-answers.txt`, run the phase's fill command with
`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'` (Phase 3 step 2,
Phase 4), run its `test -s` and dispatch the pointer to the new file —
never a rewrite of a dispatched prompt file. A controller that answers
```

In the paragraph `**Idempotence of an in-run resume after a crash.**`, replace

```
committed before the re-dispatch, so a retry rebuilds the identical
`[RESUME_ANSWER]` from the ruling-record entry; the batch controller's
```

with

```
committed before the re-dispatch, so a retry rebuilds the identical
`[RESUME_ANSWER]` from the ruling-record entry — a new fill under the next
`<k>` from the same entry, which produces the same content; the batch controller's
```

- [ ] **Step 4: Run every suite to verify they pass**

Run: `for s in orchestrating-development in-run-rulings fill-prompt reviewer-templates writing-plans smart-compress sdd-scripts; do printf '%s: ' "$s"; bash tests/$s/run-tests.sh 2>&1 | grep -E 'Results|passed' | tail -1; done; bash tests/codex/run-unit-tests.sh 2>&1 | tail -3; git status --porcelain`
Expected: `orchestrating-development: Results: <p> passed, 0 failed`; `in-run-rulings: Results: 502 passed, 0 failed`; `fill-prompt: Results: 165 passed, 0 failed`; `reviewer-templates: Results: 60 passed, 0 failed`; `writing-plans: Results: 15 passed, 0 failed`; `smart-compress: … 87 passed … 0 failed`; `sdd-scripts: Results: 193 passed, 0 failed`; codex `Results: 10 suites passed, 0 suites failed` / `All unit tests passed.`; `git status --porcelain` lists only `skills/orchestrating-development/SKILL.md` and `tests/orchestrating-development/run-tests.sh` as modified (never `CLAUDE.md`, which is ignored).

- [ ] **Step 5: Commit**

```bash
git add skills/orchestrating-development/SKILL.md tests/orchestrating-development/run-tests.sh
git commit -m "feat(orchestrator): Resume and in-run re-dispatch fill the answer lines through the value file" --trailer "Session: orchestrator-prompt-pointer" --trailer "Stage: task 6/6"
```
