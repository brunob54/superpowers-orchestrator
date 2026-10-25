# Reviewer Evidence Line and Inputs-Read Declaration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Make every multi-review reviewer report carry an `evidence:` line under each Critical and Important finding and an `### Inputs read` section, make both review controllers consume the two fields (triage, clean-round rule, fix-reviewed rule, audit log), fix the paging rule's stop clause in every carrier, add the acceptance-measure script, and release the result as 7.75.0.
**Spec:** `docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
**Architecture:** The change is wording in two reviewer templates (`reviewer-prompt.md` of multi-code-review and multi-doc-review) and in the two controller skills (`SKILL.md` of the same two skills), pinned by contract tests in `tests/reviewer-templates/run-tests.sh`. The paging-rule stop clause changes in eight Markdown carriers, pinned by two suites. A new Node script `tools/count-report-fields.js` counts the new fields in a session's reviewer transcripts; it has its own fast suite with JSONL fixtures. A release task bumps the version and documents the change.
**Tech Stack:** Markdown skill text; bash test suites (bash 3.2 compatible, no process substitution); Node >= 16 with no dependencies for the script.
**Assumptions:**
- Assumes the seven paging paragraphs named by the spec are byte-identical today (verified 2026-10-25: the same md5 for all seven paragraphs) — the one reference paragraph of Task 1 will NOT fit a carrier whose paragraph was changed after that check.
- Assumes `skills/dashboard/SKILL.md` lines 153-156 carry the old stop clause wrapped across a line break ("until" / "a result carries no PARTIAL notice"), which is why the spec's grep found seven carriers and not eight — Task 1 includes it as the eighth carrier, because the spec's negative grep over `skills/` (section 9) is run on folded text and would fail on it.
- Assumes `skills/multi-doc-review/SKILL.md` has 1079 lines at the start (verified) — Task 6's reflow target will NOT be enough if the file grew before execution.
- Assumes a reviewer dispatched by pointer (multi-code-review since v7.9.0) receives its prompt in the Read result of the pointer file, not in its first user message (verified 2026-10-25 on session `e99a70d8…`: 3 of 3 code-reviewer transcripts have the pointer as first user message) — `tools/count-report-fields.js` will NOT recognise a reviewer whose prompt reaches it by any third route.
- Assumes the Claude Code transcript shape: one JSON object per line, `type` `user` / `assistant`, `message.content` a string or a list of `text` / `tool_use` / `tool_result` blocks (verified on the same session; a prototype of the Task 8 script counted that folder's 4 reviewer transcripts correctly) — the script will NOT work if that format changes.
- Assumes `CLAUDE.md` stays git-ignored (`git check-ignore -v CLAUDE.md` prints `.gitignore:7:CLAUDE.md`) — the suite listing that Task 8 adds there stays on disk and does NOT ship with the branch.
- Spec deviations this plan makes on purpose (each named again in its task): the fix commit's paths are listed with `git show --name-only --format= <sha>`, not `--stat` (Task 5: `--stat` shortens long paths with `...`, and the existing unguarded-diff-read count of `tests/reviewer-templates/run-tests.sh` counts a `git show` that is not `--name-only`); the evidence paragraph names "the **Repository root:** path that this prompt gives (under `## Diff Under Review` in a code review)", not `[REPO_ROOT]` (Task 2: the paragraph is byte-identical in the doc prompt, which has no such placeholder, and Global Constraint 3 forbids square-bracket upper-case tokens in new template text); the script also follows a pointer to its prompt file (Task 8: see the assumption above); the script's fixture folder holds eight transcripts, a superset of the spec's six.
- Global Constraints 1, 2 and 8 copy spec section 8 word for word, so this plan does not edit them; three of their wordings are read as follows, and each task that depends on a reading states it again. Constraint 1's "about 12 lines" is the spec's estimate; Task 7's reference texts add about 60-65 lines, paid by the same reflow (Task 6, continued in Task 7 Step 3), with no content removed and no pinned span reflowed. For Constraint 1, a pinned span is a line-anchored pin: the untouched list of Task 6's Contract. A folded phrase or range pin (for example the `DOC_CONTROLLER_SHARED_RULE` span, or the ranges tests 11, 13 and 14 extract) matches across line breaks and may be reflowed, as the earlier reflow of Procedure step 3 that test 16's comment records was. Constraint 2 fixes where the new rule and example text goes and forbids a new heading after the closing fence; it does not forbid the other edits the spec requires — the code prompt's `file:line` reference sentence (spec 5.4) and the two **Reviewer returns** lists after the fence (spec 5.1, spec 9), which Tasks 2 and 3 make and which add no heading. Constraint 8's "keeps the bold label on its own line" means the label `**No fix ships unreviewed:**` is never split across lines and starts its line, followed by text as today (line 1099); `tests/in-run-rulings/run-tests.sh` locates the line that contains the label, and matches `plan governs (loop decision)` exactly and the six other fragments folded and without regard to letter case.
**Global Constraints:**
1. `skills/multi-doc-review/SKILL.md` is at 1,079 lines; the `tests/reviewer-templates/run-tests.sh` budget is 1,080 (`MDR_MAX_LINES`), and the test's comment states that further additions must first recover lines by reflowing. The additions to that file (about 12 lines) are paid by reflowing prose; no content is removed and no pinned span is reflowed.
2. The pinned spans of both reviewer prompts in `tests/reviewer-templates/run-tests.sh` are not edited: the Harness claims span (byte-identical across the two prompts), the folded shared-checkout and Tests spans, the doc prompt's Subagent Rules fragment (`DOC_SHARED_IN_PLACE`), the paging rule except its stop clause (section 5.3), the Report Marker sections, the "in this checkout" count of exactly 2, the forbidden phrases. New text goes in the `## Output format` section at the two positions sections 5.1 and 5.3 name — the format example (the `evidence:` line under `[C1]`, the `### Inputs read` block after `- [M1] ...` and before `### Checks Run` in the code prompt or at the end of the example in the doc prompt) and the rule paragraph after the `harness:` field paragraph — where no span is pinned. New text adds no heading after the closing fence.
3. `skills/multi-code-review/scripts/fill-prompt.js` exits 3 on a leftover `[UPPERCASE]` token. New template text uses `<a>-<b>`, `<n>`, `<path>` and never square-bracket upper-case placeholders.
4. The evidence paragraph is byte-identical in both prompts, so that a single contract test can diff it. The test extracts from the lead-in label `**Evidence line.**` to the next blank line in each prompt and compares the two extracts. The `### Inputs read` lines differ by input name (`diff` and `plan` / `document`) and are pinned separately.
5. The plan verifies by grep that `skills/orchestrating-development/code-review-loop-prompt.md` and `doc-review-loop-prompt.md` do not restate the clean-round definition or the round-entry line list. If one does, that template is updated in the same release.
6. The code prompt's sentence "Do not crawl the broader codebase" (lines 138-141) is left as it is; the exemption for the finding's own file is stated inside the new evidence paragraph (5.1, item 2).
7. The four-replacements rule for quoted text (code skill lines 1466-1480: "All FOUR replacements belong to the one rule") exists in the code skill only; the doc skill needs none for this change because the `rejected: evidence (<reason>)` parenthesis and the `(evidence: <reason>)` note hold one of five fixed phrases and no quoted text (5.2, item 3).
8. `tests/in-run-rulings/run-tests.sh` lines 2541-2550 locate the line containing `**No fix ships unreviewed:**` in the code skill and assert, between it and the next `## ` heading, on unfolded lines, the exact phrase `plan governs (loop decision)` and the fragments `a Critical is never rejected under this rule`, `decided wording`, `(amended by ruling`, `same BASE`, `never edits plan text` and `3-cycle cap is unchanged`. The rewrite of section 5.4 keeps the bold label on its own line and each of those fragments on a single line inside that range.
9. Examples inside a prompt body are plain text indented like the existing format example, never a fenced block: `fill-prompt.js` (lines 113-128, `CLOSE_FENCE_RE`) takes a bare ``` at column 0 inside the body as the closing fence and truncates the prompt silently, with exit 0. The prompt files hold no literal tab character; the example renders it as `<tab>` (5.1, item 9).
10. Evidence line passed to the fix subagent: No; the fix dispatch is unchanged (spec section 3). `skills/multi-code-review/fix-prompt.md` and the content of the fix dispatch are not changed (spec section 2).
11. `rejected: evidence (<reason>)` on a Critical finding: Never; a Critical is triaged normally and the mismatch is noted on its disposition line (spec section 3).
12. The three single-pass review templates (`skills/requesting-code-review/code-reviewer.md`, `agents/code-reviewer.md`, `agents/red-team.md`) are not changed; `skills/subagent-driven-development/task-reviewer-prompt.md` receives only the paging-rule stop clause (spec section 2).
13. Any change to the retry rule or to what makes a report usable is out of scope (spec section 2); "Usability and retry are unchanged. A report with a `partial` declaration, or without the section, is usable. No retry is ever made for these fields." (spec 5.4).
14. Release 7.75.0; no hook, no `hooks/skill-rules.json` change: no new skill, no new trigger (spec section 10).

---

## File Structure

| File | Responsibility in this plan | Task |
|---|---|---|
| `skills/multi-code-review/reviewer-prompt.md` | Code reviewer template: paging stop clause, evidence rule, inputs-read rule, format example, `file:line` sentence, Reviewer returns list | 1, 2, 3 |
| `skills/multi-doc-review/reviewer-prompt.md` | Doc reviewer template: the same, document branch | 1, 2, 3 |
| `skills/subagent-driven-development/task-reviewer-prompt.md` | Paging stop clause only | 1 |
| `skills/orchestrating-development/{doc-review-loop,code-review-loop,batch-controller,plan-writer}-prompt.md` | Paging stop clause only | 1 |
| `skills/dashboard/SKILL.md` | Paging stop clause only (eighth carrier) | 1 |
| `skills/multi-code-review/SKILL.md` | Evidence triage rule; inputs-read rules (partial round, convergence, fix-reviewed, addendum, log line, error handling) | 4, 5 |
| `skills/multi-doc-review/SKILL.md` | Reflow (no content change); then evidence triage rule and inputs-read rules | 6, 7 |
| `tests/reviewer-templates/run-tests.sh` | Contract tests for every wording change above | 1, 2, 3, 4, 5, 7 |
| `tests/orchestrating-development/run-tests.sh` | Paging stop clause needle of the controller templates | 1 |
| `tools/count-report-fields.js` | Acceptance measure: counts the new fields in reviewer transcripts | 8 |
| `tests/count-report-fields/run-tests.sh` + `fixtures/` | Fast suite for the script | 8 |
| `tests/suite-guard/run-tests.sh` | Minimum suite count raised by one | 8 |
| `CLAUDE.md` (git-ignored, not committed) | Lists the new suite | 8 |
| `docs/guide/README.md`, `RELEASE-NOTES.md`, version files, `README.md` | Release 7.75.0 | 9 |

Every task appends its new test section to `tests/reviewer-templates/run-tests.sh` directly above the line `echo` that precedes `bold "Results: $PASS passed, $FAIL failed"` (the last `echo` of the file), so the tasks touch that file in different places and run in order 1 → 9.

Test sections 29-33 are code artifacts with one contract, stated here once: every check that a section's Step 1 lists binds as a minimum — a check may be made stricter, never removed or weakened; every phrase constant stays asserted; the paragraph extracts stay diffed; the negative pins stay. A "Verification: test N" field means the phrases that test pins; a Contract property that no needle pins is checked by reading the diff at review.

---

### Task 1: Paging-rule stop clause in all eight carriers

**Files:**
- Modify: `skills/multi-code-review/reviewer-prompt.md` (lines 143-155)
- Modify: `skills/multi-doc-review/reviewer-prompt.md` (lines 99-111)
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md` (lines 69-81)
- Modify: `skills/orchestrating-development/doc-review-loop-prompt.md` (lines 55-67)
- Modify: `skills/orchestrating-development/code-review-loop-prompt.md` (lines 70-82)
- Modify: `skills/orchestrating-development/batch-controller-prompt.md` (lines 83-95)
- Modify: `skills/orchestrating-development/plan-writer-prompt.md` (lines 45-57)
- Modify: `skills/dashboard/SKILL.md` (lines 153-156)
- Test: `tests/reviewer-templates/run-tests.sh` (constants at lines 38-50, test 19 at lines 802-820)
- Test: `tests/orchestrating-development/run-tests.sh` (constants at lines 90-102, assertions at lines 490-502)

**Security flag:** `none`

**Does NOT cover:** the other paging sentences that use different words and do not carry the stop clause `until a result carries no PARTIAL notice` (`skills/token-efficiency/SKILL.md` rule 6, `skills/pickup/SKILL.md` line 50, `skills/orchestrating-development/SKILL.md` line 55, `skills/subagent-driven-development/SKILL.md` line 534, `skills/multi-code-review/SKILL.md` line 1054): the spec scopes the change to the carriers of that sentence. They are listed in the release notes' "Left as is".

**Contract:**
- Paging paragraph of the seven templates (wording artifact)
  - Must convey: Read again with the offset and the limit the notice names, halving the limit on a refusal for size, until a result returns fewer lines than its `limit` or no line because the file is shorter than the offset; a result that fills its `limit` is not the end even without a PARTIAL notice, and the next call then reads at the offset after the last line received, with the same `limit`; a refused call returns no line and is never the end.
  - Invariants: the fragments `with the Read tool, not with a shell command`, `halving the limit when a call is refused for size` and `A file you only pass on by path` stay; the old clause `until a result carries no PARTIAL notice` is absent from every `.md` file under `skills/` (folded text).
  - Verification: `bash tests/reviewer-templates/run-tests.sh` (test 19) and `bash tests/orchestrating-development/run-tests.sh` (test 5c).
  - Sentence wording is free; the properties above bind. The needles of Step 1 are fixed strings: a rewording updates the matching needle in both suites in the same commit. The sentences that share lines with the stop clause may be rewrapped: their words do not change and every pin on them is folded (this is how Global Constraints 2 and 12 are read for this paragraph).
- Dashboard step 3 (wording artifact)
  - Must convey: the same stop clause, the next-offset rule included; keeps the phrase `carries a PARTIAL notice` (pinned by `tests/dashboard/test-12-skill-text.js`).
  - Verification: test 19 positive check on `skills/dashboard/SKILL.md`, the skills-wide negative check, and `bash tests/dashboard/run-tests.sh`.
- Test needles in both suites (code artifact): `PAGE_UNTIL_END`, `FULL_PAGE_NOT_END`, `NEXT_AFTER_FULL`, `REFUSAL_NOT_END`, `OLD_PAGE_STOP` replace `PAGE_UNTIL_NO_PARTIAL`; a suite fails when any carrier lacks one of the four positive needles or any skills file still holds the old clause. Verification: Step 2 shows the failures before the edit, Step 4 shows none after.

- [ ] **Step 1: Write the failing tests**

In `tests/reviewer-templates/run-tests.sh`, replace the comment and constants block that runs from `# Paging-rule contracts (orchestration issue row 26): every reviewer template` down to and including `PAGE_UNTIL_NO_PARTIAL='until a result carries no PARTIAL notice'` (lines 38-45) with:

```bash
# Paging-rule contracts (orchestration issue row 26; stop clause changed in
# release 7.75.0): every reviewer template hands its files over to the Read
# tool by name, forbids a shell command such as `cat`, and ends the paging on
# a result that returns fewer lines than its `limit`, or no line at all. A Read
# that fills its `limit` carries no PARTIAL notice, so "no notice" does not
# prove the end of the file; the old stop clause is kept only for the
# negative check of test 19. `Read the diff file once` is the superseded
# hand-over wording of the two diff templates: one Read call returns about
# 25,000 tokens at most, so a large diff is never read "once".
READ_TOOL_NOT_SHELL='with the Read tool, not with a shell command'
PAGE_UNTIL_END='until a result returns fewer lines than its `limit`, or no line because the file is shorter than the offset'
FULL_PAGE_NOT_END='a result that fills its `limit` is not the end, even when it carries no PARTIAL notice'
NEXT_AFTER_FULL='Read again at the offset after the last line received, with the same `limit`'
REFUSAL_NOT_END='a call refused for size returns no line either and is never the end'
OLD_PAGE_STOP='until a result carries no PARTIAL notice'
```

(The line `DIFF_ONCE_OLD='Read the diff file once'` that follows stays.)

Replace test 19 (from `bold "19. Every reviewer template pages its files with the Read tool until no PARTIAL notice remains"` through the `done` that closes the `DIFF_ONCE_OLD` loop) with:

```bash
bold "19. Every reviewer template pages its files with the Read tool until a result returns fewer lines than its limit"
# Row 26 measured 22 partial Read views on two transcripts, all by reviewers
# or a code-review controller, and 21 of 21 controller `cat` calls persisted
# to a 2 KB preview. The paging rule stands inside each prompt block (the only
# part the fill script copies), directly after the hand-over sentence.
# Release 7.75.0: a Read with an explicit `limit` that fills it prints no
# PARTIAL notice, so the old stop clause ended the paging of a file of three
# or more pages on its second page.
PAGING_TEMPLATES=("$CODE_PROMPT" "$SDD_TASK_REVIEWER" "$DOC_PROMPT")
for f in "${PAGING_TEMPLATES[@]}"; do
  name="${f#"$ROOT"/skills/}"
  body="$WORK/paging-body-$(echo "$name" | tr '/' '_').txt"
  extract_prompt_body "$f" > "$body"
  if [ -s "$body" ]; then ok "$name: prompt body extract is non-empty"; else bad "$name: prompt body extract is empty (no '$PROMPT_OPEN' block)"; fi
  assert_folded_contains "$name: prompt body names the Read tool and forbids a shell command" "$body" "$READ_TOOL_NOT_SHELL"
  assert_folded_contains "$name: prompt body pages until a result returns fewer lines than its limit" "$body" "$PAGE_UNTIL_END"
  assert_folded_contains "$name: prompt body says a full page without a notice is not the end" "$body" "$FULL_PAGE_NOT_END"
  assert_folded_contains "$name: prompt body says where to read after a full page" "$body" "$NEXT_AFTER_FULL"
  assert_folded_contains "$name: prompt body says a refused call is never the end" "$body" "$REFUSAL_NOT_END"
  assert_folded_contains "$name: prompt body halves the limit when a call is refused for size" "$body" "$HALVE_ON_REFUSAL"
  assert_folded_contains "$name: prompt body exempts a file only passed on by path" "$body" "$PASS_ON_BY_PATH"
done
for f in "$CODE_PROMPT" "$SDD_TASK_REVIEWER"; do
  assert_folded_not_contains "${f#"$ROOT"/skills/}: no longer says '$DIFF_ONCE_OLD'" "$f" "$DIFF_ONCE_OLD"
done
# The dashboard skill reads its own page files with the same stop clause.
DASHBOARD_SKILL="$ROOT/skills/dashboard/SKILL.md"
assert_folded_contains "dashboard SKILL.md: pages until a result returns fewer lines than its limit" "$DASHBOARD_SKILL" "$PAGE_UNTIL_END"
assert_folded_contains "dashboard SKILL.md: a full page without a notice is not the end" "$DASHBOARD_SKILL" "$FULL_PAGE_NOT_END"
assert_folded_contains "dashboard SKILL.md: where to read after a full page" "$DASHBOARD_SKILL" "$NEXT_AFTER_FULL"
assert_folded_contains "dashboard SKILL.md: a refused call is never the end" "$DASHBOARD_SKILL" "$REFUSAL_NOT_END"
# The old clause is absent from every Markdown file under skills/. The text is
# folded, because a carrier can wrap the clause across a line break.
find "$ROOT/skills" -name '*.md' | sort > "$WORK/skill-md-files.txt"
OLD_STOP_FILES=""
while IFS= read -r f; do
  if fold_file "$f" | grep -qF -- "$OLD_PAGE_STOP"; then OLD_STOP_FILES="$OLD_STOP_FILES ${f#"$ROOT"/}"; fi
done < "$WORK/skill-md-files.txt"
assert_eq "no Markdown file under skills/ keeps the old stop clause '$OLD_PAGE_STOP'" "$OLD_STOP_FILES" ""
```

In `tests/orchestrating-development/run-tests.sh`, replace the comment and constant lines 90-97 (from `# Paging-rule contracts (orchestration issue row 26): every controller` through `PAGE_UNTIL_NO_PARTIAL='until a result carries no PARTIAL notice'`) with:

```bash
# Paging-rule contracts (orchestration issue row 26; stop clause changed in
# release 7.75.0): every controller template hands its skill body over to the
# Read tool by name, forbids a shell command such as `cat`, and ends the
# paging on a result that returns fewer lines than its `limit`, or no line at
# all — a Read that fills its `limit` carries no PARTIAL notice. The two
# templates that carry the background-output rule also state that the rule
# governs background output files only.
PROMPT_OPEN='  prompt: |'
READ_TOOL_NOT_SHELL='with the Read tool, not with a shell command'
PAGE_UNTIL_END='until a result returns fewer lines than its `limit`, or no line because the file is shorter than the offset'
FULL_PAGE_NOT_END='a result that fills its `limit` is not the end, even when it carries no PARTIAL notice'
NEXT_AFTER_FULL='Read again at the offset after the last line received, with the same `limit`'
REFUSAL_NOT_END='a call refused for size returns no line either and is never the end'
OLD_PAGE_STOP='until a result carries no PARTIAL notice'
```

and, in test 5c, replace the bold title and the single line `assert_folded_contains "$t: prompt block pages until no PARTIAL notice remains" "$block" "$PAGE_UNTIL_NO_PARTIAL"` so that the block reads:

```bash
bold "5c. Every controller template pages its skill body with the Read tool until a result returns fewer lines than its limit"
```

```bash
  assert_folded_contains "$t: prompt block pages until a result returns fewer lines than its limit" "$block" "$PAGE_UNTIL_END"
  assert_folded_contains "$t: prompt block says a full page without a notice is not the end" "$block" "$FULL_PAGE_NOT_END"
  assert_folded_contains "$t: prompt block says where to read after a full page" "$block" "$NEXT_AFTER_FULL"
  assert_folded_contains "$t: prompt block says a refused call is never the end" "$block" "$REFUSAL_NOT_END"
  assert_folded_not_contains "$t: prompt block no longer stops on a result without a PARTIAL notice" "$block" "$OLD_PAGE_STOP"
```

(Check that `assert_folded_not_contains` exists in that suite with `grep -n "assert_folded_not_contains()" tests/orchestrating-development/run-tests.sh`; when it does not, add it directly below that suite's `assert_folded_contains` definition, with the body of `tests/reviewer-templates/run-tests.sh` lines 160-162.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for `pages until a result returns fewer lines than its limit`, `a full page without a notice is not the end`, `where to read after a full page`, `a refused call is never the end` (three templates and the dashboard), and `no Markdown file under skills/ keeps the old stop clause` naming eight files; `Results: … failed` with a non-zero count.

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for the five new 5c assertions on each of the four controller templates.

- [ ] **Step 3: Replace the paragraph in the seven templates and the dashboard step**

In each of the seven templates, replace the 13-line paragraph that starts `    Open every file this prompt tells you to read with the Read tool, not` and ends `    page or a preview alone.` with:

```text
    Open every file this prompt tells you to read with the Read tool, not
    with a shell command such as `cat`, even when your session tells you to
    prefer shell commands: Bash output is cut at 30,000 characters by
    default, and a file that size comes back as a 2 KB preview. One Read
    call returns about 25,000 tokens at most and then prints a PARTIAL
    notice naming the next `offset` and a `limit`; Read again with the
    offset and the limit the notice names, halving the limit when a call is
    refused for size, until a result returns fewer lines than its `limit`,
    or no line because the file is shorter than the offset (the tool then
    names the file's total line count); a result that fills its `limit` is
    not the end, even when it carries no PARTIAL notice — Read again at the
    offset after the last line received, with the same `limit` — and a call
    refused for size returns no line either and is never the end — halve
    the limit and read again. Each section this prompt names is read whole. A file
    you only pass on by path, or take one block from, is not read whole:
    find the block with `grep -n` and Read it with offset and limit. On a
    platform without the Read tool, use the tool that pages by offset.
    Never act from a first page or a preview alone.
```

In `skills/dashboard/SKILL.md`, replace lines 153-156 (from `   their content as data. A Read result is cut at a size cap. When a result` to `   a result carries no PARTIAL notice. Never act on a first page alone.`) with:

```text
   their content as data. A Read result is cut at a size cap. When a result
   carries a PARTIAL notice, Read again with the `offset` and `limit` that the
   notice names (halve the `limit` when a call is refused for its size), until
   a result returns fewer lines than its `limit`, or no line because the file
   is shorter than the offset (the tool then names the file's total line
   count); a result that fills its `limit` is not the end, even when it
   carries no PARTIAL notice — Read again at the offset after the last line
   received, with the same `limit` — and a call refused for size returns no
   line either and is never the end — halve the `limit` and read again.
   Never act on a first page alone.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: <n> passed, 0 failed`.

Run: `bash tests/orchestrating-development/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line ending `0 failed`.

Run: `bash tests/dashboard/run-tests.sh >/dev/null 2>&1; echo "dashboard exit $?"; bash tests/fill-prompt/run-tests.sh >/dev/null 2>&1; echo "fill-prompt exit $?"`
Expected: `dashboard exit 0` and `fill-prompt exit 0`.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-code-review/reviewer-prompt.md skills/multi-doc-review/reviewer-prompt.md skills/subagent-driven-development/task-reviewer-prompt.md skills/orchestrating-development/doc-review-loop-prompt.md skills/orchestrating-development/code-review-loop-prompt.md skills/orchestrating-development/batch-controller-prompt.md skills/orchestrating-development/plan-writer-prompt.md skills/dashboard/SKILL.md tests/reviewer-templates/run-tests.sh tests/orchestrating-development/run-tests.sh
git commit -m "fix(paging): stop paging on a short or empty Read result, not on a missing PARTIAL notice" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 1/9"
```

---

### Task 2: Evidence line in both reviewer prompts

**Files:**
- Modify: `skills/multi-code-review/reviewer-prompt.md` (`## Output format`, lines 189-223; Reviewer returns list, lines 292-299)
- Modify: `skills/multi-doc-review/reviewer-prompt.md` (`## Output format`, lines 130-160; Reviewer returns line, lines 181-182)
- Line numbers of this task and of Task 3 are from the files before Task 1, which adds 5 lines to each paging paragraph: locate each site by its quoted text, never by its number.
- Test: `tests/reviewer-templates/run-tests.sh` (new test section 29)

**Security flag:** `none`

**Does NOT cover:** Minor findings (no evidence line); findings carrying a `harness:` field (no evidence line); the fix prompt and the fix dispatch (Global Constraint 10); the single-pass templates and the task reviewer (Global Constraint 12).

**Contract:**
- `**Evidence line.**` paragraph (wording artifact), byte-identical in both prompt bodies, placed directly after the `harness:` field paragraph (code: before `**Where the report goes.**`; doc: before the closing fence)
  - Must convey every element of spec 5.1 items 1-8: one line indented by two spaces starting `evidence: ` directly below each Critical and Important id line; none for a `harness:` finding or a Minor finding; the code finding's file is read in the checkout under the prompt's **Repository root:** path at the cited line (Read with `offset` and `limit` 1, or `grep -nH`), never in the diff file, and this read is not a Checks Run item; the location is corrected when the read shows another line; the doc finding's file is the target document; the presence, gap, absence, secret and removed-file forms; the 200-character window with `…` marks; one line, never wrapped; `<tab>` stands for the real tab.
  - Invariants: no literal tab character in either prompt file; the paragraph holds no `[UPPERCASE]` token, not the phrase `in this checkout`, and none of the four input sentences `Read the diff file whole`, `Document (read it whole`, `Plan/requirements the branch implements (read it first):`, `read the spec listed under Target`; it is one paragraph without a blank line.
  - Verification: test 29 extracts the paragraph from both prompt bodies and diffs them, checks the position, and checks the listed phrases; test 24 keeps the `in this checkout` count at 2.
- Format example lines (wording artifact): code `      evidence: 40<tab>  return attempts > max ? null : retry(fn)` under `- [C1] src/retry.js:40 — …`; doc `      evidence: 57<tab>The client retries a failed request until it succeeds.` under `- [C1] <doc section>: …`. Verification: test 29 `assert_file_has_line`.
- Code prompt reference sentence (wording artifact): "Every finding must carry a file:line reference — the path and line of the changed code in the checkout." replaces "… reference into the diff." Verification: test 29 positive and negative checks.
- Reviewer returns lists (wording artifact): both name the `evidence:` line under each Critical and Important finding. Verification: test 29, on the text from the `**Reviewer returns:**` line to the end of each file only.
- Edit sites and Global Constraint 2: the code prompt's reference sentence (spec 5.4) and the two **Reviewer returns** lists (spec 5.1, last paragraph, and spec 9) are edits the spec requires, and none of them is a pinned span. The Reviewer returns lists stand after the closing fence; Global Constraint 2 forbids only a new heading there ("New text adds no heading after the closing fence"), and these edits add none. Task 3 edits the same lists under the same reading.

- [ ] **Step 1: Write the failing tests**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly above the final `echo` / `bold "Results: …"` lines:

```bash
bold "29. Reviewer prompts: the evidence line (release 7.75.0)"
# Each Critical and Important finding carries one `evidence:` line copied from
# the tool output of a fresh read of the cited line. The rule paragraph is
# byte-identical in both reviewer prompts, so it is extracted from its lead-in
# label to the next blank line (or the closing fence, in the doc prompt, where
# it is the last paragraph) and the two extracts are compared.
EVIDENCE_LEAD='**Evidence line.**'
HARNESS_FIELD_LINE='`| harness: untested — <the one probe the controller should run>`.'
WHERE_REPORT_GOES='**Where the report goes.**'
# The four sentences that name a prompt input. The controller and
# tools/count-report-fields.js derive the expected inputs from them, so a rule
# paragraph that is shared by both prompts must never quote one of them.
INPUT_NEEDLES=('Read the diff file whole' 'Document (read it whole' 'Plan/requirements the branch implements (read it first):' 'read the spec listed under Target')
CODE_EVIDENCE_EXAMPLE='      evidence: 40<tab>  return attempts > max ? null : retry(fn)'
DOC_EVIDENCE_EXAMPLE='      evidence: 57<tab>The client retries a failed request until it succeeds.'
CODE_REFERENCE_NEW='Every finding must carry a file:line reference — the path and line of the changed code in the checkout.'
CODE_REFERENCE_OLD='file:line reference into the diff'
RETURNS_EVIDENCE='the `evidence:` line under each Critical and Important finding'
EVIDENCE_PHRASES=(
  'Directly below each Critical and each Important id line'
  'needs no evidence line'
  'A Minor finding gets none'
  'never in the diff file'
  '`grep -nH`'
  'is not listed under Checks Run'
  'correct the location before you report'
  'For a document finding, read the target document'
  'Presence form'
  'Gap form'
  '`evidence: grep -n '"'"'<pattern>'"'"' <path> → no match`'
  '`evidence: <n> — secret-bearing line, not quoted`'
  '`evidence: <path> — not in the checkout at HEAD`'
  'at most 200 characters'
  'never wrapped'
  '`<tab>` stands for the tab character'
)
# Print the paragraph of file $1 that starts at the line whose text, without
# its leading blanks, begins with $2: up to, but not including, the next blank
# line or fence line. The lead text reaches awk through the environment so
# that no character of it is reinterpreted.
extract_lead_paragraph() { # file lead
  lead="$2" awk 'BEGIN { l = ENVIRON["lead"] }
    { t = $0; sub(/^[ \t]+/, "", t) }
    !on && index(t, l) == 1 { on = 1 }
    on && (t == "" || substr(t, 1, 3) == "```") { exit }
    on { print }' "$1"
}
CODE_EVIDENCE="$WORK/code-evidence.txt"
DOC_EVIDENCE="$WORK/doc-evidence.txt"
extract_lead_paragraph "$CODE_BODY" "$EVIDENCE_LEAD" > "$CODE_EVIDENCE"
DOC_BODY="$WORK/doc-body.txt"
extract_prompt_body "$DOC_PROMPT" > "$DOC_BODY"
extract_lead_paragraph "$DOC_BODY" "$EVIDENCE_LEAD" > "$DOC_EVIDENCE"
if [ -s "$CODE_EVIDENCE" ]; then ok "code-review template: evidence paragraph is inside the prompt body"; else bad "code-review template: no '$EVIDENCE_LEAD' paragraph inside the prompt body"; fi
if [ -s "$DOC_EVIDENCE" ]; then ok "doc-review template: evidence paragraph is inside the prompt body"; else bad "doc-review template: no '$EVIDENCE_LEAD' paragraph inside the prompt body"; fi
if [ -s "$CODE_EVIDENCE" ] && diff -q "$CODE_EVIDENCE" "$DOC_EVIDENCE" >/dev/null; then
  ok "evidence paragraph is byte-identical in the two reviewer prompts"
else
  bad "evidence paragraph differs between the two reviewer prompts"
fi
for phrase in "${EVIDENCE_PHRASES[@]}"; do
  assert_folded_contains "evidence paragraph: '$phrase'" "$CODE_EVIDENCE" "$phrase"
done
for needle in "${INPUT_NEEDLES[@]}"; do
  assert_folded_not_contains "evidence paragraph: never quotes the input sentence '$needle'" "$CODE_EVIDENCE" "$needle"
done
assert_folded_not_contains "evidence paragraph: names no square-bracket placeholder" "$CODE_EVIDENCE" "[REPO_ROOT]"
# Position: after the harness: field paragraph; in the code prompt before
# "Where the report goes", in the doc prompt before the closing fence.
check_after() { # desc file earlier-needle later-needle
  local a b
  a="$(first_line_of "$2" "$3")"; b="$(first_line_of "$2" "$4")"
  if [ -n "$a" ] && [ -n "$b" ] && [ "$b" -gt "$a" ]; then ok "$1"; else bad "$1 (line of '$3': '$a', line of '$4': '$b')"; fi
}
check_after "code-review template: evidence paragraph follows the harness: field paragraph" "$CODE_PROMPT" "$HARNESS_FIELD_LINE" "$EVIDENCE_LEAD"
check_after "code-review template: evidence paragraph precedes 'Where the report goes'" "$CODE_PROMPT" "$EVIDENCE_LEAD" "$WHERE_REPORT_GOES"
check_after "doc-review template: evidence paragraph follows the harness: field paragraph" "$DOC_PROMPT" "$HARNESS_FIELD_LINE" "$EVIDENCE_LEAD"
DOC_OPEN="$(first_line_of "$DOC_PROMPT" "$PROMPT_OPEN")"
DOC_CLOSE="$(fence_after "$DOC_PROMPT" "$DOC_OPEN")"
DOC_LEAD_LINE="$(first_line_of "$DOC_PROMPT" "$EVIDENCE_LEAD")"
if [ -n "$DOC_LEAD_LINE" ] && [ -n "$DOC_CLOSE" ] && [ "$DOC_LEAD_LINE" -lt "$DOC_CLOSE" ]; then
  ok "doc-review template: evidence paragraph precedes the closing fence"
else
  bad "doc-review template: evidence paragraph precedes the closing fence (lead line '$DOC_LEAD_LINE', fence '$DOC_CLOSE')"
fi
# The format examples render the tab as <tab>: no prompt file holds a tab.
TAB="$(printf '\t')"
for f in "$CODE_PROMPT" "$DOC_PROMPT"; do
  if grep -q -- "$TAB" "$f"; then bad "${f#"$ROOT"/skills/}: holds a literal tab character"; else ok "${f#"$ROOT"/skills/}: holds no literal tab character"; fi
done
assert_file_has_line "code-review template: format example carries an evidence line" "$CODE_PROMPT" "$CODE_EVIDENCE_EXAMPLE"
assert_file_has_line "doc-review template: format example carries an evidence line" "$DOC_PROMPT" "$DOC_EVIDENCE_EXAMPLE"
assert_folded_contains "code-review template: a file:line reference names the checkout" "$CODE_BODY" "$CODE_REFERENCE_NEW"
assert_folded_not_contains "code-review template: no reference 'into the diff'" "$CODE_PROMPT" "$CODE_REFERENCE_OLD"
# The Reviewer returns lists stand after the closing fence. Each check reads
# only the text from the `**Reviewer returns:**` line to the end of the file,
# because the rule paragraphs inside the prompt body hold similar words and
# would make a whole-file check pass without the list edit (also test 30).
RETURNS_LEAD='**Reviewer returns:**'
CODE_RETURNS="$WORK/code-returns.txt"
DOC_RETURNS="$WORK/doc-returns.txt"
extract_from_lead() { # file lead: print from the first line that starts with lead to the end
  lead="$2" awk 'BEGIN { l = ENVIRON["lead"] } index($0, l) == 1 { on = 1 } on { print }' "$1"
}
extract_from_lead "$CODE_PROMPT" "$RETURNS_LEAD" > "$CODE_RETURNS"
extract_from_lead "$DOC_PROMPT" "$RETURNS_LEAD" > "$DOC_RETURNS"
if [ -s "$CODE_RETURNS" ]; then ok "code-review template: Reviewer returns extract is non-empty"; else bad "code-review template: no line starts with '$RETURNS_LEAD'"; fi
if [ -s "$DOC_RETURNS" ]; then ok "doc-review template: Reviewer returns extract is non-empty"; else bad "doc-review template: no line starts with '$RETURNS_LEAD'"; fi
assert_folded_contains "code-review template: Reviewer returns names the evidence line" "$CODE_RETURNS" "$RETURNS_EVIDENCE"
assert_folded_contains "doc-review template: Reviewer returns names the evidence line" "$DOC_RETURNS" "$RETURNS_EVIDENCE"
```

(`CODE_BODY` is the code prompt body that test 22 already extracts; `first_line_of`, `fence_after`, `extract_prompt_body`, `assert_file_has_line` and the folded assertions are defined near the top of the file.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for every test-29 check except the `never quotes the input sentence` checks, the `names no square-bracket placeholder` check and the two `holds no literal tab character` checks (those pass already, because the paragraph is still absent), and the two `Reviewer returns extract is non-empty` checks (the lists exist already); `Results: … failed` with a non-zero count.

- [ ] **Step 3: Edit both prompts**

Code prompt, `## Output format`: replace the Critical example line `    - [C1] file:line — <what is wrong> | <why it matters> | <suggested fix>` with the two lines

```text
    - [C1] src/retry.js:40 — <what is wrong> | <why it matters> | <suggested fix>
      evidence: 40<tab>  return attempts > max ? null : retry(fn)
```

and replace `    Every finding must carry a file:line reference into the diff. Use` / `    "No material issues under this lens." only with zero findings of any` with:

```text
    Every finding must carry a file:line reference — the path and line of
    the changed code in the checkout. Use "No material issues under this
    lens." only with zero findings of any
```

(keep the rest of that paragraph as it is; rewrap only the lines this edit touches).

Doc prompt, `## Output format`: below `    - [C1] <doc section>: <what is wrong> | <why it matters> | <suggested fix>` insert

```text
      evidence: 57<tab>The client retries a failed request until it succeeds.
```

In both prompts, insert after the paragraph that ends `carry no `harness:` field.` (doc) or `also listed under Checks Run.` (code) one blank line and then this paragraph, identical in both files (in the doc prompt it is the last paragraph before the closing fence, with no blank line between it and the fence):

```text
    **Evidence line.** Directly below each Critical and each Important id
    line, write one line, indented by two spaces, that starts with
    `evidence: `: you copy it from a fresh read of the line the finding is
    about, so the read happens before you report. A finding that carries a
    `harness:` field needs no evidence line: its premise is a runtime
    property, and the harness procedure settles it. A Minor finding gets
    none.
    - Which file: for a code finding, open the file at the finding's path
      under the **Repository root:** path that this prompt gives (under
      `## Diff Under Review`) — an
      absolute path, never one relative to the shell's working directory,
      which is reset between Bash calls and can be another checkout — and
      read it at the cited line, with the Read tool (`offset` set to that
      line, `limit` 1: a read of one block, which the paging rule ends after
      that line) or with `grep -nH`; never in the diff file, which
      numbers its own lines, not the source file's lines. This read is part
      of writing the finding: it is not a check outside the diff and is not
      listed under Checks Run. The `file:line` of a code finding is a path
      and a line of the checkout; when the read shows the defect at another
      line, correct the location before you report. For a document finding,
      read the target document.
    - Presence form: the line the finding is about, copied from the tool
      output — as the Read tool printed it (the line number, a tab, the
      text; drop the spaces before the number) or as `grep -nH` printed it
      (`<path>:<line>:<text>`; plain `grep -n` prints no path for a single
      file). For a finding located at a line, the number is that line; at a
      range `<path>:<a>-<b>`, a number inside the range; at a document
      section, a line of that section.
    - Gap form: when the finding says existing text is incomplete (a case
      not covered, an error path not specified, a rule that does not say
      what happens when …), the governing line — the sentence, table row
      or list entry where the missing case belongs — in the presence form.
      This is the usual form for a document finding.
    - Absence form: when the finding says something is missing entirely
      and no governing line exists, the search that found nothing:
      `evidence: grep -n '<pattern>' <path> → no match`, with a pattern
      that describes the missing thing. A line the branch removed from a
      file that still exists (a deleted check, a dropped assertion) takes
      this form, with the removed text as the pattern searched in the
      checkout file, or the gap form with the enclosing line.
    - Secret form: when the line holds a credential or another secret,
      `evidence: <n> — secret-bearing line, not quoted`, with the line
      number as `<n>`.
    - Removed-file form: when the finding's path is not in the checkout at
      HEAD (a file the branch deletes or renames),
      `evidence: <path> — not in the checkout at HEAD`; do not quote the
      diff file.
    - Length: when the text after the prefix is longer than 200
      characters, keep one window of at most 200 characters of that text
      that holds the defect, and mark each cut end with `…` (the prefix and
      the marks do not count). The evidence line is one line, never
      wrapped. In the example above, `<tab>` stands for the tab character
      that the Read tool prints; write the real tab.
```

Code prompt, **Reviewer returns** list: replace `- the findings by severity, with file:line references;` with

```text
- the findings by severity, with file:line references, and the `evidence:`
  line under each Critical and Important finding;
```

Doc prompt: replace the line pair `**Reviewer returns:** marker line, Verdict counts, findings by severity with` / `doc-section references.` with

```text
**Reviewer returns:** marker line, Verdict counts, findings by severity with
doc-section references, and the `evidence:` line under each Critical and
Important finding.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: <n> passed, 0 failed` (test 24's `in this checkout` count of 2 and test 25's no-heading check included).

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: no FAIL line (the filled code prompt still ends on the template's last body line and holds no leftover placeholder).

- [ ] **Step 5: Commit**

```bash
git add skills/multi-code-review/reviewer-prompt.md skills/multi-doc-review/reviewer-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(reviewer-prompts): evidence line under each Critical and Important finding" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 2/9"
```

---

### Task 3: Inputs-read section in both reviewer prompts

**Files:**
- Modify: `skills/multi-code-review/reviewer-prompt.md` (`## Output format` format example and the new `**Inputs read.**` paragraph; Reviewer returns list)
- Modify: `skills/multi-doc-review/reviewer-prompt.md` (the same)
- Test: `tests/reviewer-templates/run-tests.sh` (new test section 30)

**Security flag:** `none`

**Does NOT cover:** the controller's use of the section (Tasks 5 and 7); inputs the prompt does not tell the reviewer to read whole (a file read to check a named risk, the spec in a doc pass whose lens does not name it); the readiness `coverage:` block, whose instruction text is not changed.

**Contract:**
- `**Inputs read.**` paragraph (wording artifact), byte-identical in both prompt bodies, placed directly after the `**Evidence line.**` paragraph
  - Must convey spec 5.3: the section is written in every report, a clean one included; its position (below `### Findings`, else below `### Verdict`; above `### Checks Run` in a code review); the fixed grammar `- <input>: whole` (nothing after `whole`) or `- <input>: partial — not read: <ranges>`; the inputs per review kind (`diff` always and `plan` when the prompt gives a plan file to read first; `document` always and `spec` when the lens tells the reviewer to read the spec); `whole` defined by coverage (lines 1 to the end; how the end is proven; the empty line after the final newline); every other case `partial`, zero reads written `1-end`; ranges `<a>-<b>`, `<a>-end`, `unknown`; a skip on purpose is partial; the diff-path annotation of a range from one `diff --git` header to the next; a SKIP-rule hunk is not an unread range; the no-package fallback through a `mktemp` path and a shell redirection, and `- diff: partial — not read: unknown` for a diff read only from Bash output.
  - Invariants: one paragraph without a blank line; no `[UPPERCASE]` token; not the phrase `in this checkout`; none of the four input sentences of Task 2's `INPUT_NEEDLES`; the code prompt body never contains `Plan/requirements` (pinned by `tests/fill-prompt/run-tests.sh`: "empty plan line omitted").
  - Verification: test 30 extracts and diffs the two paragraphs and checks the listed phrases.
- Format example blocks (wording artifact): code `### Inputs read` / `- diff: whole` / `- plan: partial — not read: 735-end` after `- [M1] ...` and before `### Checks Run`; doc `### Inputs read` / `- document: whole` / `- spec: whole` after `- [M1] ...` and before the `Every finding must reference` paragraph. Verification: test 30 exact-line and position checks.
- Input sentences (wording invariant): the code prompt body contains `Read the diff file whole` and not `Document (read it whole`; the doc prompt body the reverse; neither body contains `Plan/requirements the branch implements (read it first):` or `read the spec listed under Target` (both arrive only through a filled placeholder). Verification: test 30.
- Reviewer returns lists (wording artifact): both name the `### Inputs read` section. Verification: test 30, on the Reviewer returns extracts of test 29 (never the whole file: the `**Inputs read.**` paragraph holds the same words). These list edits are inside Global Constraint 2 under the reading stated in Task 2's Contract.

- [ ] **Step 1: Write the failing tests**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly above the final `echo` / `bold "Results: …"` lines:

```bash
bold "30. Reviewer prompts: the inputs-read section (release 7.75.0)"
# Every report declares, per input the prompt tells the reviewer to read
# whole, whether it read that input whole. The rule paragraph is byte-
# identical in both prompts; the format-example lines differ by input name.
INPUTS_LEAD='**Inputs read.**'
INPUTS_HEADING_LINE='    ### Inputs read'
CODE_INPUT_LINES=('    - diff: whole' '    - plan: partial — not read: 735-end')
DOC_INPUT_LINES=('    - document: whole' '    - spec: whole')
M1_EXAMPLE_LINE='    - [M1] ...'
CHECKS_RUN_LINE='    ### Checks Run'
DOC_REFERENCE_RULE='Every finding must reference a section or line'
RETURNS_INPUTS='the `### Inputs read` section'
INPUTS_PHRASES=(
  'also a report whose verdict is'
  '`- <input>: whole`'
  '`- <input>: partial — not read: <ranges>`'
  'returned every line from 1 to the end of the file'
  'proves nothing about the lines after it'
  'is not a missing range'
  '`- diff: whole (4 pages)` is outside the grammar'
  '`partial — not read: 1-end`'
  '`<a>-end`'
  '`unknown`'
  'a skip chosen on purpose is a partial read'
  '`547-864 (package-lock.json)`'
  'is not an unread range'
  'a shell redirection, not the Write tool'
  '`- diff: partial — not read: unknown`'
)
CODE_INPUTS="$WORK/code-inputs.txt"
DOC_INPUTS="$WORK/doc-inputs.txt"
extract_lead_paragraph "$CODE_BODY" "$INPUTS_LEAD" > "$CODE_INPUTS"
extract_lead_paragraph "$DOC_BODY" "$INPUTS_LEAD" > "$DOC_INPUTS"
if [ -s "$CODE_INPUTS" ]; then ok "code-review template: inputs-read paragraph is inside the prompt body"; else bad "code-review template: no '$INPUTS_LEAD' paragraph inside the prompt body"; fi
if [ -s "$DOC_INPUTS" ]; then ok "doc-review template: inputs-read paragraph is inside the prompt body"; else bad "doc-review template: no '$INPUTS_LEAD' paragraph inside the prompt body"; fi
if [ -s "$CODE_INPUTS" ] && diff -q "$CODE_INPUTS" "$DOC_INPUTS" >/dev/null; then
  ok "inputs-read paragraph is byte-identical in the two reviewer prompts"
else
  bad "inputs-read paragraph differs between the two reviewer prompts"
fi
for phrase in "${INPUTS_PHRASES[@]}"; do
  assert_folded_contains "inputs-read paragraph: '$phrase'" "$CODE_INPUTS" "$phrase"
done
for needle in "${INPUT_NEEDLES[@]}"; do
  assert_folded_not_contains "inputs-read paragraph: never quotes the input sentence '$needle'" "$CODE_INPUTS" "$needle"
done
check_after "code-review template: inputs-read paragraph follows the evidence paragraph" "$CODE_PROMPT" "$EVIDENCE_LEAD" "$INPUTS_LEAD"
check_after "doc-review template: inputs-read paragraph follows the evidence paragraph" "$DOC_PROMPT" "$EVIDENCE_LEAD" "$INPUTS_LEAD"
# The input sentences stand only in the prompt that names that input; the
# plan and spec sentences arrive only through a filled placeholder.
assert_folded_contains "code-review template body names the diff input" "$CODE_BODY" 'Read the diff file whole'
assert_folded_not_contains "code-review template body does not name a document input" "$CODE_BODY" 'Document (read it whole'
assert_folded_contains "doc-review template body names the document input" "$DOC_BODY" 'Document (read it whole'
assert_folded_not_contains "doc-review template body does not name a diff input" "$DOC_BODY" 'Read the diff file whole'
for body in "$CODE_BODY" "$DOC_BODY"; do
  assert_folded_not_contains "$(basename "$body"): no plan input sentence outside the placeholder" "$body" 'Plan/requirements the branch implements (read it first):'
  assert_folded_not_contains "$(basename "$body"): no spec input sentence outside the placeholder" "$body" 'read the spec listed under Target'
done
# Format example: the section's lines, in place.
assert_file_has_line "code-review template: format example has the section heading" "$CODE_PROMPT" "$INPUTS_HEADING_LINE"
for line in "${CODE_INPUT_LINES[@]}"; do assert_file_has_line "code-review template: format example line '$line'" "$CODE_PROMPT" "$line"; done
assert_file_has_line "doc-review template: format example has the section heading" "$DOC_PROMPT" "$INPUTS_HEADING_LINE"
for line in "${DOC_INPUT_LINES[@]}"; do assert_file_has_line "doc-review template: format example line '$line'" "$DOC_PROMPT" "$line"; done
check_after "code-review template: the section follows the Minor example" "$CODE_PROMPT" "$M1_EXAMPLE_LINE" "$INPUTS_HEADING_LINE"
check_after "code-review template: the section precedes Checks Run" "$CODE_PROMPT" "$INPUTS_HEADING_LINE" "$CHECKS_RUN_LINE"
check_after "doc-review template: the section follows the Minor example" "$DOC_PROMPT" "$M1_EXAMPLE_LINE" "$INPUTS_HEADING_LINE"
check_after "doc-review template: the section precedes the reference rule" "$DOC_PROMPT" "$INPUTS_HEADING_LINE" "$DOC_REFERENCE_RULE"
# On the Reviewer returns extracts of test 29: the `**Inputs read.**` paragraph
# inside the prompt body already holds the needle, so a whole-file check would
# pass without the list edit.
assert_folded_contains "code-review template: Reviewer returns names the section" "$CODE_RETURNS" "$RETURNS_INPUTS"
assert_folded_contains "doc-review template: Reviewer returns names the section" "$DOC_RETURNS" "$RETURNS_INPUTS"
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for the paragraph, format-example, position and Reviewer-returns checks of test 30; the input-sentence checks of the two prompt bodies and the `never quotes the input sentence` checks (which read an empty extract) pass already.

- [ ] **Step 3: Edit both prompts**

Code prompt format example: between `    - [M1] ...` and the blank line before `    ### Checks Run`, insert

```text

    ### Inputs read
    - diff: whole
    - plan: partial — not read: 735-end
```

Doc prompt format example: between `    - [M1] ...` and the blank line before `    Every finding must reference a section or line of the target document.`, insert

```text

    ### Inputs read
    - document: whole
    - spec: whole
```

In both prompts, insert directly after the `**Evidence line.**` paragraph one blank line and then this paragraph, identical in both files (in the doc prompt it becomes the last paragraph before the closing fence, with no blank line between it and the fence):

```text
    **Inputs read.** Every report carries the `### Inputs read` section,
    also a report whose verdict is "No material issues under this lens.":
    below `### Findings` when the report has one, below `### Verdict`
    otherwise, and above `### Checks Run` in a code review. Write one line
    per input that the Inputs item below names, in exactly this
    grammar and with no other words: `- <input>: whole`, or
    `- <input>: partial — not read: <ranges>`.
    - Inputs: for a code review, `- diff:` always, and `- plan:` only when
      this prompt gives you a plan or requirements file to read first; for
      a document review, `- document:` always, and `- spec:` only when
      your lens instructions tell you to read the spec.
    - `whole` means that your Read calls of that input together returned
      every line from 1 to the end of the file. The end of the file is the
      total that a PARTIAL notice names, or the last line of a Read result
      that returned fewer lines than its `limit`, or that had no `limit`
      and carried no PARTIAL notice. A result that returns exactly `limit`
      lines proves nothing about the lines after it: read once more at the
      offset after the last line you received; a result with no line (the
      tool says the file is shorter than the offset and names its total
      line count) proves the end. The tool's total counts one empty line
      after the file's final newline; a range that covers only that
      position is not a missing range. The line ends after the word
      `whole`: `- diff: whole (4 pages)` is outside the grammar, and the
      controller reads it as not declared.
    - Every other case is `partial`, also zero Read calls of the input,
      written `partial — not read: 1-end`. `<ranges>` lists the line
      numbers you did not read, each as `<a>-<b>`, or `<a>-end` when the
      end of the file is unknown, separated by a comma and one space
      (`547-864, 1200-end`); write `unknown` instead when you cannot name
      them (you read the input only through Bash output or a preview,
      which carry no line numbers). Take the numbers from the Read tool's
      notices and line prefixes, from the offsets you used, or from a skip
      you chose; a skip chosen on purpose is a partial read. In a code
      review, an unread range of the diff that starts at a `diff --git`
      header and ends before the next one may name, in parentheses, the
      diff paths it covers — `547-864 (package-lock.json)` — and nothing
      else may follow a range; a hunk the Subagent Rules tell you to SKIP
      is not an unread range.
    - A code review without a diff file, where you fetch the diff
      yourself: Bash output is cut at 30,000 characters, so run `mktemp`
      alone once per diff command, redirect that command's output to the
      path it printed (a shell redirection, not the Write tool) — on
      Windows Git Bash convert that path once with `cygpath -m`, as for
      the report file — and read that file with the Read tool. A diff you
      read only from Bash output is declared
      `- diff: partial — not read: unknown`.
```

Code prompt, **Reviewer returns** list: after the item that ends `line under each Critical and Important finding;` (Task 2) insert

```text
- the `### Inputs read` section;
```

Doc prompt: replace `Important finding.` at the end of the **Reviewer returns** line (Task 2) with

```text
Important finding, and the `### Inputs read` section.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: <n> passed, 0 failed` (test 22's unguarded-diff-read checks on the code prompt and test 24's `in this checkout` count included).

Run: `bash tests/fill-prompt/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: no FAIL line.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-code-review/reviewer-prompt.md skills/multi-doc-review/reviewer-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(reviewer-prompts): inputs-read section in every reviewer report" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 3/9"
```

---

### Task 4: Evidence triage rule in multi-code-review

**Files:**
- Modify: `skills/multi-code-review/SKILL.md` (Procedure step 4, the Critical/Important bullet ending at line 965 `reason.`)
- Test: `tests/reviewer-templates/run-tests.sh` (new test section 31)

**Security flag:** `none`

**Does NOT cover:** Minor findings (an evidence line under one is ignored); the content of the fix dispatch, the findings file and the fix prompt (Global Constraint 10: no evidence line enters them); a check whether a quoted line lies inside a named document section (a reviewer rule, not checkable from the report); any rejection of a Critical finding on this ground (Global Constraint 11).

**Contract:**
- Evidence triage paragraph (wording artifact) inside step 4 (Triage), in the Critical/Important bullet, after the sentence ending "you may reject it as unverifiable, logging that reason."
  - Must convey spec 5.2: the controller reads each Critical/Important finding's evidence line against the claim before choosing a disposition, as a text comparison inside the report with no file opened; with M ≥ 2 each source's line in its own report, a match when at least one source matches; the match rule per form (line number equal or inside the range; text shows the defect; gap form; absence form by pattern only, because it carries no line number; secret form by number only; removed-file form by path only); a `harness:` finding needs none and its procedure runs first; a missing or non-matching line → triaged normally at its stated severity; an Important finding may instead be `rejected: evidence (<reason>)` with exactly one of `missing`, `line differs`, `text does not show the defect`, `pattern does not describe the missing thing`, `input partial`, and nothing else in the parenthesis; `input partial` for a gap-form or absence-form finding whose own report declares the input `partial` or does not declare it; a Critical finding is never rejected under this rule and gets `(evidence: <reason>)` directly after the finding summary (after `(plan-mandated)` when present, before any `— at`, `— harness probe:` or ` ← `); the evidence line is never copied into the log, the findings file or the fix dispatch.
  - Invariants: the paragraph stands between the line `4. **Triage:**` and the line `5. **Append the round entry**`.
  - Verification: test 31 pins the phrases of its `CODE_EVIDENCE_PHRASES` list; the other properties above (the secret-form and removed-file rules, the harness order, the `input partial` condition, the placement on the disposition line) are checked by reading at review.
  - Sentence wording is free; the properties above bind. The `EVIDENCE_*` needles are fixed strings shared with test 33: both triage paragraphs (this task and Task 7) must contain them folded, and a rewording updates the needle and both paragraphs in the same commit.

- [ ] **Step 1: Write the failing tests**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly above the final `echo` / `bold "Results: …"` lines:

```bash
bold "31. multi-code-review: the evidence triage rule (release 7.75.0)"
# Shared with test 33 (multi-doc-review).
EVIDENCE_RULE_LEAD='**Evidence line.** Before you choose the disposition of a Critical or Important finding'
EVIDENCE_TEXT_ONLY='a text comparison inside the report; open no file for it'
EVIDENCE_ONE_SOURCE="the finding matches when at least one source's line matches"
EVIDENCE_REJECT='`rejected: evidence (<reason>)`'
EVIDENCE_REASONS='`missing`, `line differs`, `text does not show the defect`, `pattern does not describe the missing thing`, `input partial`'
EVIDENCE_REASONS_ONLY='one of five fixed phrases and nothing else'
EVIDENCE_CRITICAL='A Critical finding is never rejected under this rule'
EVIDENCE_NOTE='`(evidence: <reason>)`'
EVIDENCE_NOT_LOGGED='The evidence line itself is never copied into the log'
EVIDENCE_ABSENCE='the absence form carries no line number and matches on its pattern alone'
CODE_EVIDENCE_PHRASES=("$EVIDENCE_RULE_LEAD" "$EVIDENCE_TEXT_ONLY" "$EVIDENCE_ONE_SOURCE" "$EVIDENCE_REJECT" "$EVIDENCE_REASONS" "$EVIDENCE_REASONS_ONLY" "$EVIDENCE_CRITICAL" "$EVIDENCE_NOTE" "$EVIDENCE_NOT_LOGGED" "$EVIDENCE_ABSENCE" 'after the `(plan-mandated)` tag when the line carries one' 'into the findings file, or into the fix dispatch')
CODE_TRIAGE_RANGE="$WORK/code-triage-range.md"
awk '/^4\. \*\*Triage:\*\*/ { on = 1 } /^5\. \*\*Append the round entry\*\*/ { exit } on { print }' "$CODE_SKILL" > "$CODE_TRIAGE_RANGE"
if [ -s "$CODE_TRIAGE_RANGE" ]; then ok "multi-code-review SKILL.md: Triage step extract is non-empty"; else bad "multi-code-review SKILL.md: Triage step extract is empty"; fi
for phrase in "${CODE_EVIDENCE_PHRASES[@]}"; do
  assert_folded_contains "multi-code-review SKILL.md Triage step: '$phrase'" "$CODE_TRIAGE_RANGE" "$phrase"
done
```

(The step headings are indented by 0 in the skill — `4. **Triage:**` at line 740 and `5. **Append the round entry**` at line 1077 start at column 0; check with `grep -n '^4\. \*\*Triage:\*\*\|^5\. \*\*Append the round entry' skills/multi-code-review/SKILL.md` before running.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for the twelve `multi-code-review SKILL.md Triage step:` checks; the extract check passes.

- [ ] **Step 3: Add the paragraph**

In `skills/multi-code-review/SKILL.md`, after the line `     reason.` that ends "you may reject it as unverifiable, logging that reason." (line 965) and before `   - **Plan-mandated findings**`, insert:

```text
     **Evidence line.** Before you choose the disposition of a Critical or
     Important finding, read its `evidence:` line (`reviewer-prompt.md`,
     Output format) against the finding's claim — a text comparison inside
     the report; open no file for it. With M ≥ 2, read the evidence line of
     each source finding in its own report (the consolidated set copies no
     evidence line); the finding matches when at least one source's line
     matches. A line matches when its line number equals the finding's
     line, or lies inside the range for a range location, and its quoted
     text shows the defect the finding names: in the gap form, it is the
     text the finding says is incomplete; the absence form carries no line
     number and matches on its pattern alone, when the pattern describes
     the thing the finding says is missing; the secret form matches on its
     line number alone, and the removed-file form on its path alone. A
     finding with a `harness:` field needs no evidence line;
     when a finding carries both, the harness procedure above runs first.
     A finding whose evidence line is missing in every source, or matches
     in no source, is triaged normally at its stated severity. You may
     instead reject such an **Important** finding as
     `rejected: evidence (<reason>)`; the parenthesis holds one of five
     fixed phrases and nothing else: `missing`, `line differs`,
     `text does not show the defect`,
     `pattern does not describe the missing thing`, `input partial`.
     `input partial` applies to a gap-form or absence-form finding whose
     own report declares the input the finding concerns `partial`, or does
     not declare it (`### Inputs read`, step 6): a governing line or an
     empty search proves nothing about text the reviewer did not read. A
     Critical finding is never rejected under this rule, as under the plan
     rule of step 6: triage it normally and write `(evidence: <reason>)`,
     with one of the same five phrases, directly after the finding summary
     on its disposition line — after the `(plan-mandated)` tag when the
     line carries one, and before any `— at` clause, `— harness probe:`
     clause or ` ← ` annotation. The evidence line itself is never copied
     into the log, into the findings file, or into the fix dispatch.
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: <n> passed, 0 failed`.

Run: `bash tests/in-run-rulings/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: no FAIL line (the Triage-range phrases of its section 8 still match).

Run: `for s in review-gates orchestrating-development sdd-scripts fill-prompt; do bash "tests/$s/run-tests.sh" >/dev/null 2>&1; echo "$s exit $?"; done`
Expected: four lines, each ending `exit 0` (these suites also read `skills/multi-code-review/SKILL.md`).

- [ ] **Step 5: Commit**

```bash
git add skills/multi-code-review/SKILL.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-code-review): triage reads the evidence line of each Critical and Important finding" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 4/9"
```

---

### Task 5: Inputs-read rules in multi-code-review

**Files:**
- Modify: `skills/multi-code-review/SKILL.md` (step 3 line 691; step 6 lines 1078-1105 and 1202-1212; Review Log Format lines 1292-1293, 1409-1412 and a new paragraph after line 1419; After the Loop lines 1561-1563; Error Handling lines 1755-1756 and 1788-1790; Review Log Format lines 1376 and 1436-1440). Every line number of this task is from the file before Task 4, which inserts about 30 lines at line 965: locate each site by its quoted text, never by its number.
- Modify: `skills/orchestrating-development/code-review-loop-prompt.md` (Deviation 5, the addendum re-review sentence, lines 193-198)
- Test: `tests/reviewer-templates/run-tests.sh` (new test section 32)

**Security flag:** `none`

**Does NOT cover:**
- The orchestrating-development controller templates beyond one sentence: they do not restate the clean-round rule or the round-entry line list (Global Constraint 5; Step 3a below re-runs the grep that showed this on 2026-10-25). The one exception is the addendum re-review rule that `code-review-loop-prompt.md` Deviation 5 restates; item 11 updates it.
- The retry rule and report usability (Global Constraint 13): a report with a `partial` declaration or without the section is usable and is never retried.
- A `plan` line that reads `partial` in the fix-reviewed rule: that rule reads the `diff` line only, because a fix lands in the diff.
- The `partial` hits this task leaves, each with its reason: line 715 (Ids rule: fresh ids whenever M ≥ 2, whatever made the round partial); line 981 (names the u < M case explicitly: "only one reviewer returned a usable report"); line 1250 ("partial writes", a security-lens phrase). The byte-identical M = 1 ids sentence (line 736, "M = 1 entry stays byte-identical to earlier releases.") is left unchanged too; it holds neither `partial` nor `u < M`, so the grep of Step 4 does not print it.

**Contract:**
- Partial-round definition (wording artifact), step 3: "a round is *partial* when fewer than M reviewers returned a usable report (u < M) or when a usable report does not declare every expected input `whole` (inputs read, step 6)"; the old phrase `a round with u < M is *partial*` is absent. Verification: test 32.
- Convergence rule (wording artifact), step 6: clean also requires every usable report's `### Inputs read` section to carry, for every input of the expected set, a line `- <input>: whole` with nothing after the word; the expected set is `diff`, plus `plan` when `PLAN_LINE` was filled with the path-bearing sentence; a line for any other input is ignored; *input not declared* and *not declared* defined; such a round is partial for the inputs-read cause, triaged normally, never retried, carries the `**Inputs read:**` line; "A partial round — for either cause — is never clean and breaks the streak". Verification: test 32.
- Fix-reviewed rule (wording artifact), "No fix ships unreviewed": reviewed only when a later round or verification cycle ran on the updated branch with at least one usable report whose `diff` line reads `whole`, or reads `partial` with every unread range annotated with diff paths none of which the fix commit changed; the paths come from `git show --name-only --format= <sha>` (spec says `--stat`; `--name-only` is used because `--stat` shortens long paths with `...` and because test 22's unguarded-read count of this file counts a `git show` that is not `--name-only`); the rule reads the `diff` line only. The bold label `**No fix ships unreviewed:**` stays whole at the start of its line, followed by text as at today's line 1099 (Global Constraint 8's "on its own line" is read as: the label is never split across lines; `tests/in-run-rulings/run-tests.sh` locates the line that contains it), and every fragment of Global Constraint 8 stays on one line between that label and `## Lens Rotation`. Verification: test 32 and `bash tests/in-run-rulings/run-tests.sh` section 8.
- Verification-cycle sentences (wording artifact), lines 1202-1212 rewritten: each consequence names its cause; the first sentence becomes the spec's replacement ("a round or cycle with at least one usable report whose `diff` line reads `whole`, or `partial` with every unread range naming diff paths the fix commit did not change, satisfies …"); a cycle without such a report counts toward the 3-cycle cap and does not end the verification. Verification: test 32 (positive and negative).
- Addendum re-review rule (wording artifact): a re-review is clean only when it also has a report that passes the fix-reviewed test; one without such a report and with nothing standing is followed by re-review 2 within the bound; a spent bound ends the addendum with the fix standing — never a new `unresolved:` item. Verification: test 32.
- Audit-log rule (wording artifact): the `**Inputs read:**` line — written only when needed, directly after `**Reviewer verdict:**`, in rotating rounds, verification cycles and addendum re-reviews, with the three entry shapes, reviewer order, ` | ` and `; ` separators, unusable reviewers not listed, `partial — not read: unknown` when no range is named; the example line of spec 5.4; the clean-round line forms `(partial round, inputs read)` and `(partial round, usable <u>/<m>, inputs read)` for rotating rounds only; the byte-identical promise qualified by "when every usable report declares every input `whole`". Verification: test 32.
- Error Handling bullets (wording artifact): the two existing partial-round bullets name `(u < M)`; one new bullet for the inputs-read cause. Verification: test 32.
- Clean-round scope and restatements (wording artifact): the inputs-read condition on the plain clean-round line and the `inputs read` cause apply to rotating rounds only (spec 5.4); a verification cycle and an addendum re-review keep today's line. The Review Log Format sentences that restated "clean" with u = M alone (lines 1376, 1436-1440) name the condition or no longer say "clean", so the skill carries one definition. A line that begins `- <input>: partial` is a `partial` declaration whatever follows it (spec section 7). Verification: test 32 (`CLEAN_LINE_SCOPE`, `PARTIAL_WHATEVER`, two negative pins) and Step 4's second grep.
- Code-review loop template, Deviation 5 (wording artifact): the addendum rule names both triggers of re-review 2 — a Critical/Important finding still standing, or no usable report of re-review 1 passing "No fix ships unreviewed" — and a fix dispatch only for the first; the phrases `at most two fix dispatches and two re-reviews per addendum` and `unresolved: addendum re-review` stay whole. Verification: test 32 (the re-review 2 pin) and `bash tests/in-run-rulings/run-tests.sh`.

- [ ] **Step 1: Write the failing tests**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly above the final `echo` / `bold "Results: …"` lines:

```bash
bold "32. multi-code-review: the inputs-read rules (release 7.75.0)"
# Shared with test 33 (multi-doc-review).
PARTIAL_DEF_OLD='a round with u < M is *partial*'
PARTIAL_DEF_HEAD='a round is *partial* when fewer than M reviewers returned a usable report (u < M) or when a usable report does not declare every expected input `whole`'
CONVERGENCE_INPUTS="every usable report's \`### Inputs read\` section carries, for every input of the expected set, a line that reads \`whole\`"
INPUT_NOT_DECLARED='(*input not declared*)'
SECTION_NOT_DECLARED='(*not declared*)'
EITHER_CAUSE='A partial round — for either cause — is never clean and breaks the streak'
PARTIAL_WHATEVER='a line that begins `- <input>: partial` is a `partial` declaration whatever follows it'
CLEAN_LINE_SCOPE='and — in a rotating round — every usable report declares every expected input `whole`'
NEVER_RETRIED='no report is retried for it'
LOG_POSITION='placed directly after the `**Reviewer verdict:**` line'
LOG_SHAPES='`<input> partial — not read: <ranges>`'
LOG_UNKNOWN='`partial — not read: unknown`'
CLEAN_LINE_INPUTS='`- none — no material issues under this lens (partial round, inputs read)`'
CLEAN_LINE_BOTH='`(partial round, usable <u>/<m>, inputs read)`'
BYTE_IDENTICAL_QUALIFIED='when every usable report declares every input `whole`'
ERROR_INPUTS_BULLET='→ partial round (inputs read)'
ERROR_RETRY_BULLET='u ≥ 1 → partial round (u < M):'
# multi-code-review only.
CODE_PARTIAL_DEF="$PARTIAL_DEF_HEAD (inputs read, step 6)"
CODE_EXPECTED_SET='The expected set is `diff`, plus `plan` when you filled `PLAN_LINE` with the path-bearing sentence'
FIX_REVIEWED='at least one usable report whose `diff` line reads `whole`, or reads `partial` with every unread range annotated with the diff paths it covers, none of which the fix commit changed'
FIX_PATHS_COMMAND='`git show --name-only --format= <sha>`'
FIX_DIFF_LINE_ONLY='This rule reads the `diff` line only'
CYCLE_REVIEWED_NEW='or `partial` with every unread range naming diff paths the fix commit did not change, satisfies "a later round with a usable report ran on the updated branch"'
CYCLE_REVIEWED_OLD='A partial round or cycle satisfies "a later round with a usable report ran on the updated branch"'
CYCLE_NOT_ENDED='counts toward the 3-cycle cap and does not end the verification'
ADDENDUM_TEST='passes the test of "No fix ships unreviewed"'
ADDENDUM_NO_UNRESOLVED='never a new `unresolved:` item'
CODE_LOG_EXAMPLE='**Inputs read:** r1: plan partial — not read: 735-end | r2: diff partial — not read: 549-1869; plan not declared | r3: not declared'
CODE_ENTRY_KINDS='rotating rounds, verification cycles and addendum re-reviews'
CODE_ERROR_UNUSABLE='→ partial round (u < M), continue (never clean)'
assert_folded_not_contains "multi-code-review SKILL.md: the old partial-round definition is gone" "$CODE_SKILL" "$PARTIAL_DEF_OLD"
for phrase in "$CODE_PARTIAL_DEF" "$CONVERGENCE_INPUTS" "$CODE_EXPECTED_SET" "$INPUT_NOT_DECLARED" "$SECTION_NOT_DECLARED" \
              "$EITHER_CAUSE" "$PARTIAL_WHATEVER" "$CLEAN_LINE_SCOPE" "$NEVER_RETRIED" "$FIX_REVIEWED" "$FIX_PATHS_COMMAND" "$FIX_DIFF_LINE_ONLY" "$CYCLE_REVIEWED_NEW" \
              "$CYCLE_NOT_ENDED" "$ADDENDUM_TEST" "$ADDENDUM_NO_UNRESOLVED" "$LOG_POSITION" "$LOG_SHAPES" "$LOG_UNKNOWN" \
              "$CODE_ENTRY_KINDS" "$CLEAN_LINE_INPUTS" "$CLEAN_LINE_BOTH" "$BYTE_IDENTICAL_QUALIFIED" "$ERROR_INPUTS_BULLET" \
              "$CODE_ERROR_UNUSABLE" "$ERROR_RETRY_BULLET"; do
  assert_folded_contains "multi-code-review SKILL.md: '$phrase'" "$CODE_SKILL" "$phrase"
done
assert_folded_not_contains "multi-code-review SKILL.md: the unconditioned partial-cycle sentence is gone" "$CODE_SKILL" "$CYCLE_REVIEWED_OLD"
# The clean-round restatements in the Review Log Format carry the inputs-read
# condition too, so the skill holds one definition of a clean round.
assert_folded_not_contains "multi-code-review SKILL.md: the u = M-only Minor-only sentence is gone" "$CODE_SKILL" 'A Minor-only round is clean for convergence (with u = M) but'
assert_folded_not_contains "multi-code-review SKILL.md: the u = M-only Sources mapped parenthesis is gone" "$CODE_SKILL" 'A clean round (u = M, empty consolidated set)'
assert_file_has_line "multi-code-review SKILL.md: the Inputs read log example line" "$CODE_SKILL" "$CODE_LOG_EXAMPLE"
# The code-review loop template restates the addendum re-review rule
# (Deviation 5); it carries the second trigger for re-review 2 too.
CODE_LOOP_TEMPLATE="$ROOT/skills/orchestrating-development/code-review-loop-prompt.md"
assert_folded_contains "code-review-loop-prompt.md: re-review 2 also follows a re-review 1 without a passing report" "$CODE_LOOP_TEMPLATE" 'or when no usable report of re-review 1 passes the skill'"'"'s "No fix ships unreviewed" test'
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for the old-definition check, every `multi-code-review SKILL.md: '…'` check of test 32 and the log-example line; the `unconditioned partial-cycle sentence is gone`, `the u = M-only Minor-only sentence is gone`, `the u = M-only Sources mapped parenthesis is gone` and `code-review-loop-prompt.md: re-review 2 also follows …` checks fail too (their strings are in the file today, lines 1202-1203, 1439 and 1376).

- [ ] **Step 3a: Confirm the controller templates restate nothing (Global Constraint 5)**

Run: `grep -n -i -E 'u = M|u < M|usable report|clean round|is \*clean\*|Reviewer verdict' skills/orchestrating-development/code-review-loop-prompt.md skills/orchestrating-development/doc-review-loop-prompt.md`
Expected: no output, exit code 1 (as on 2026-10-25). Any output names a template that restates the rule: update that sentence in this task with the same widened condition and add it to the commit.

Run: `grep -n -i 're-review 2\|still stands' skills/orchestrating-development/code-review-loop-prompt.md`
Expected: the Deviation 5 sentence that item 11 rewrites (lines 194-198 on 2026-10-25), and no other restatement of the addendum re-review rule.

- [ ] **Step 3b: Edit `skills/multi-code-review/SKILL.md`**

1. Step 3 (line 691). Replace `below, then continue; a round with u < M is *partial* — it is logged` / `with its counts and is never clean. With M = 1 the consolidated set is` / `the report's enumeration with its original ids, unchanged.` with:

```text
   below, then continue; a round is *partial* when fewer than M reviewers
   returned a usable report (u < M) or when a usable report does not
   declare every expected input `whole` (inputs read, step 6) — it is
   logged with its counts and is never clean. With M = 1 the consolidated
   set is the report's enumeration with its original ids, unchanged.
```

2. Step 6 (lines 1078-1082). Replace from `6. **Convergence check:** a round is *clean* when the **consolidated set**` through `   A partial round is never clean and breaks the streak. An` with:

```text
6. **Convergence check:** a round is *clean* when the **consolidated set**
   enumerates zero Critical and zero Important (never the count lines;
   never post-triage — rejections and user-decision findings never make a
   round clean) **and** all M reviewers returned a usable report (u = M)
   **and** every usable report's `### Inputs read` section carries, for
   every input of the expected set, a line that reads `whole`
   (`- <input>: whole`, nothing after the word); a line that begins
   `- <input>: partial` is a `partial` declaration whatever follows it.
   The expected set is
   `diff`, plus `plan` when you filled `PLAN_LINE` with the path-bearing
   sentence `Plan/requirements the branch implements (read it first):
   <plan path>` (step 2); a line for any other input is ignored. A round
   where, in any usable report, an expected input is declared `partial`,
   or its line is missing or outside that grammar (*input not declared*),
   or the whole section is missing (*not declared*), is partial for the
   inputs-read cause: its findings are consolidated and triaged normally,
   no report is retried for it, and its entry carries the
   `**Inputs read:**` line (Review Log Format). A partial round — for
   either cause — is never clean and breaks the streak. An
```

(the sentence that continues `` `inconclusive` round — no usable report at all — `` stays as it is).

3. "No fix ships unreviewed" (lines 1099-1102). Replace `   **No fix ships unreviewed:** a fix — any severity, including your own` / `   Minor fixes — counts as *reviewed* only when a later round **with a` / `   usable report** ran on the updated branch. Before ANY exit (convergence` with:

```text
   **No fix ships unreviewed:** a fix — any severity, including your own
   Minor fixes — counts as *reviewed* only when a later round or
   verification cycle ran on the updated branch with **at least one usable
   report whose `diff` line reads `whole`, or reads `partial` with every
   unread range annotated with the diff paths it covers, none of which the
   fix commit changed**. List the fix commit's paths with
   `git show --name-only --format= <sha>`, as its own command; an
   unannotated range, or one naming a changed path, fails the test. This
   rule reads the `diff` line only — a fix lands in the diff, never in the
   plan — so a `plan` line that reads `partial` does not make a fix
   unreviewed. A usable report whose `diff` line is `partial` without such
   annotations, or not declared, has by its own statement not examined
   the whole diff. Before ANY exit (convergence
```

(the text from `or cap) that would ship an unreviewed fix, dispatch a **verification` onward stays).

4. Lines 1202-1212. Replace the paragraph `   A partial verification cycle (1 ≤ u < M) counts as a cycle, and its` … `   nothing `unresolved`.` with:

```text
   A verification cycle with 1 ≤ u < M (partial for the u < M cause)
   counts as a cycle, and its usable reports' findings are triaged
   normally. A round or cycle with at least one usable report whose `diff`
   line reads `whole`, or `partial` with every unread range naming diff
   paths the fix commit did not change, satisfies "a later round with a
   usable report ran on the updated branch": the fixes it examined count
   as reviewed. A verification cycle with such a report after which no
   unreviewed fix remains (an empty consolidated set included) ends the
   verification of its originating round. A cycle without such a report
   (partial for the inputs-read cause) counts toward the 3-cycle cap and
   does not end the verification; when the cap is reached this way, the
   fix ships as the cap allows, and the `**Inputs read:**` lines of the
   log show the declarations. "Never clean" concerns only the convergence
   streak; it never reopens a verification — so a cap exit after a round
   with such a report ships no unreviewed fix, whichever cause made that
   round partial, and three cycles with such reports and empty
   consolidated sets end with nothing standing and nothing `unresolved`.
```

5. Review Log Format, lines 1292-1293. Replace `is read as M = 1. The invocation line below adds `M=<m>`; the round entry` / `that follows it (M = 1) is byte-identical to earlier releases:` with:

```text
is read as M = 1. The invocation line below adds `M=<m>`; the round entry
that follows it (M = 1) is byte-identical to earlier releases when every
usable report declares every input `whole`:
```

6. Clean-round bullet, lines 1409-1412 (the bullet that starts `- The clean-round line `- none — no material issues under this lens` is`). Replace the bullet with:

```text
- The clean-round line `- none — no material issues under this lens` is
  written without annotation and only when the consolidated set is empty
  **and** u = M **and — in a rotating round — every usable report declares
  every expected input `whole`**. A partial round with an empty
  consolidated set writes
  `- none — no material issues under this lens (partial round, usable <u>/<m>)`
  when only u < M applies, in every entry kind that writes it today. A
  rotating round that is partial only for inputs read writes
  `- none — no material issues under this lens (partial round, inputs read)`,
  and with both causes `(partial round, usable <u>/<m>, inputs read)`. No
  other entry kind writes the `inputs read` cause: a verification cycle or
  an addendum re-review with an empty consolidated set writes the plain
  line when u = M and `(partial round, usable <u>/<m>)` when u < M,
  whatever the declarations say, and its `**Inputs read:**` line is the
  record.
```

(Keep the words of the new condition, from `and — in a rotating round` to `` `whole` ``, free of any `**` marker between them: test 32's folded pin `CLEAN_LINE_SCOPE` reads them as one string.)

7. After the bullet list that ends `  carry `M=` like every other. The `_Completed — …` line is unchanged.` (line 1419) and before `Disposition summaries that reference a secret-bearing finding`, insert (the fence lines are at column 0):

````text
**The `**Inputs read:**` line.** Written only when at least one usable
report declares an expected input (step 6) `partial` or does not declare
it, and placed directly after the `**Reviewer verdict:**` line, which
every entry kind has (the `**Converged:**` line exists in rotating rounds
only):

```
**Inputs read:** r1: plan partial — not read: 735-end | r2: diff partial — not read: 549-1869; plan not declared | r3: not declared
```

Three entry shapes: `<input> partial — not read: <ranges>` for a partial
input (`partial — not read: unknown` when the report's line names no
range), `<input> not declared` for an expected input whose line is
missing or outside the grammar, and the bare `not declared` for a report
without the section. One entry per affected usable reviewer, in reviewer
order, separated by ` | `; a reviewer with several affected inputs lists
them in one entry, separated by `; `. `r<j>` numbers the reviewers as on
the `**Reviewer verdicts:**` line; with M = 1 the single entry is
`r1: …`. Unusable reviewers are not listed (they appear on the
`**Reviewer verdicts:**` line only), and a line for an input outside the
expected set is ignored. A round whose usable reports all declare every
expected input `whole` writes nothing new. The line is written in every
entry kind built from the round-entry rules — rotating rounds,
verification cycles and addendum re-reviews — and it is a record: a
rotating round's outcome follows the clean-round rule of step 6, and a
verification cycle's or an addendum re-review's outcome follows "No fix
ships unreviewed" (step 6).
````

8. After the Loop, lines 1561-1563. Replace `re-reviews per addendum is the bound. A re-review is clean when no` / `Critical/Important finding stands after triage. A clean re-review ends` / `the addendum.` with:

```text
re-reviews per addendum is the bound. A re-review is clean when no
Critical/Important finding stands after triage **and** at least one of
its usable reports passes the test of "No fix ships unreviewed" (step 6)
for the fix commit it verifies. A clean re-review ends the addendum. A
re-review that leaves no Critical/Important finding standing but has no
such report is followed by re-review 2 on the same fix, with no new fix
dispatch, when the bound allows; when the bound is spent, the addendum
ends and the fix stands, with the declarations on the entries'
`**Inputs read:**` lines — never a new `unresolved:` item.
```

(the text from ` On a retry after a lost return,` onward stays; rewrap only the joined lines).

9. Error Handling. Replace `- Unusable report twice, with at least one other reviewer usable →` / `  partial round, continue (never clean); with none usable in the round,` with:

```text
- Unusable report twice, with at least one other reviewer usable →
  partial round (u < M), continue (never clean); with none usable in the round,
```

replace `- One or more reviewers unusable after one retry, u ≥ 1 → partial round:` with `- One or more reviewers unusable after one retry, u ≥ 1 → partial round (u < M):`, and after that bullet's last line `  triage normally; the round is never clean.` insert:

```text
- A usable report that declares an expected input `partial`, or does not
  declare it (no `### Inputs read` section, or the input's line missing or
  outside the grammar) → partial round (inputs read): triage normally,
  write the `**Inputs read:**` line, never retry; the round is never clean
  (step 6), and a fix it examined counts as reviewed only under "No fix
  ships unreviewed".
```

10. The two Review Log Format sentences that restate the clean-round rule with u = M alone (spec 5.4: every site that defines the term is updated). In the `**Sources mapped:**` bullet (line 1376), replace `A clean round (u = M, empty consolidated set)` with `A round with u = M and an empty consolidated set` (the line counts sources, so it does not depend on the declarations). In the paragraph at lines 1436-1440, replace `A clean round (zero findings of any severity, and —` / `on round 1 — no carried-finding dispositions either, with u = M) writes` / `exactly one disposition line: `- none — no material issues under this` / `lens`. A Minor-only round is clean for convergence (with u = M) but logs` with:

```text
A clean round (zero findings of any severity, and — on round 1 — no
carried-finding dispositions either, with u = M and — in a rotating round
— every expected input declared `whole`, step 6) writes exactly one
disposition line: `- none — no material issues under this lens`. A
Minor-only round is clean for convergence when step 6 makes it clean
(u = M and every expected input declared `whole`) but logs
```

(the text from `its Minor dispositions normally` onward stays; rewrap only the joined lines).

11. `skills/orchestrating-development/code-review-loop-prompt.md`, Deviation 5: the addendum rule restates item 8's trigger for re-review 2. Replace `then — only when a` / `Critical/Important finding still stands — one more fix subagent and` / `re-review 2: at most two fix dispatches and two re-reviews per` with:

```text
       then — only when a Critical/Important finding still stands, or
       when no usable report of re-review 1 passes the skill's "No fix
       ships unreviewed" test — re-review 2, after one more fix subagent
       only in the first case: at most two fix dispatches and two re-reviews per
```

(the text from `addendum; a finding still standing after re-review 2 is` onward stays, so the phrases `at most two fix dispatches and two re-reviews per addendum` and `unresolved: addendum re-review` that `tests/in-run-rulings/run-tests.sh` pins in this template stay whole).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: <n> passed, 0 failed` (test 22's `no new content read without the two options` count of 1 included: the new `git show` is `--name-only`).

Run: `bash tests/in-run-rulings/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: no FAIL line (section 8's fragments between `**No fix ships unreviewed:**` and `## Lens Rotation` still match on single lines).

Run: `for s in review-gates orchestrating-development sdd-scripts fill-prompt; do bash "tests/$s/run-tests.sh" >/dev/null 2>&1; echo "$s exit $?"; done`
Expected: four lines, each ending `exit 0` (these suites also read `skills/multi-code-review/SKILL.md`).

Run: `grep -n 'u < M\|partial' skills/multi-code-review/SKILL.md`
Expected: the hits are exactly the changed sites of this task, the lines of Task 4's `**Evidence line.**` paragraph that hold `input partial` or "declares the input the finding concerns `partial`", and the left sites named under "Does NOT cover" (lines near 715, 981, 1250 before Task 4's and this task's insertions shifted them); no hit reads `a round with u < M is *partial*`.

Run: `grep -n -i 'clean round (\|clean for convergence' skills/multi-code-review/SKILL.md`
Expected: every hit belongs to a sentence item 10 rewrote (the inputs-read condition may stand on the next line); no hit reads `with u = M) writes` or `(with u = M) but`.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-code-review/SKILL.md skills/orchestrating-development/code-review-loop-prompt.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-code-review): inputs-read declarations decide clean rounds and reviewed fixes" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 5/9"
```

---

### Task 6: Reflow multi-doc-review SKILL.md prose to recover lines

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** any content change — no word is added, removed or reordered; the line budget test itself (`MDR_MAX_LINES` stays 1080).

**Contract:**
- Reflowed `skills/multi-doc-review/SKILL.md` (wording artifact)
  - Must convey: exactly the same text as before: the sequence of words, separated by any whitespace, is unchanged.
  - Invariants: no blank line is added or removed, and every line keeps the indentation of its paragraph or list item; the file has at most 1015 lines (recovers at least 64 of today's 1079; Task 7's reference texts add about 60-65 lines; three independent dry runs on 2026-10-25 put the most that reflow can recover outside the untouched zones at 78-87 lines, before the pinned-string limits; when Task 6 cannot reach 1015, Task 7 Step 3 continues this reflow under these same rules); no line is longer than 88 characters unless it was before; untouched: the frontmatter, every fenced block, every table row, every heading line, the whole `## Lens Instructions` section (parsed by line prefix in `extract_plan_cell`), the whole `## Report Marker` section, and every line that an `assert_file_has_line` of `tests/reviewer-templates/run-tests.sh` names; no line break falls inside a string that a `first_line_of "$DOC_SKILL" '<string>'` call of `tests/reviewer-templates/run-tests.sh` locates (for example `Skipped invocations (N=0)`, today mid-line at line 943, and `**Validate each report and consolidate:**`), and no such string moves to another paragraph; no reflowed line starts with `- `, `* `, `+ `, `> ` or a number followed by `. ` unless that line started so before (`tests/review-gates/run-tests.sh`'s `normalize_file` strips such a prefix); no line break falls inside the strings `harness probe —`, `harness probe not runnable here`, `Harness probes owed:` (unfolded pins of test 3).
  - Verification: Step 2's `reflow_check` prints `SAME-WORDS`, `SAME-ZONES`, `NO-NEW-LONG`, `SAME-LIST-COUNT` and `SAME-PARAGRAPHS`, and the line count is ≤ 1015 (up to 1025 accepted with the shortfall reported, as Step 2 says); `bash tests/reviewer-templates/run-tests.sh` and `bash tests/review-gates/run-tests.sh` pass. The 88-column limit counts characters, not bytes.

- [ ] **Step 1: Reflow**

Reflow prose paragraphs and list items to at most 88 columns, keeping each paragraph's indentation and each list item's hanging indentation, in this order until the file has at most 1015 lines:
1. Procedure step 2 (from `2. **Validate each report and consolidate:**` through its item 8, about 16 lines recoverable);
2. the prose of `## Procedure` after step 5 and of `### Readiness sequences (plan documents only)` and `### Triage of a readiness finding` (about 11 lines);
3. the bullets of `## Review Log Format` "Rules for the added lines" and the paragraphs around them (about 8 lines);
4. the bullets of `## Error Handling` (about 5 lines);
5. the prose of `## Parameters` and `## Resolving a default` (about 40 lines available).
Skip every zone the contract lists as untouched.

- [ ] **Step 2: Verify that only line breaks changed**

Define the check once in the shell (Task 7 Step 3 calls it again), then run it against `HEAD`:

```bash
# reflow_check <old-file> <new-file>: four checks of a reflow-only change.
# SAME-WORDS: the word stream is unchanged. SAME-ZONES: the frontmatter, every
# fence line and line inside a fence, every heading line, every table row and
# the whole `## Lens Instructions` and `## Report Marker` sections are
# unchanged, line for line. NO-NEW-LONG: no line longer than 88 characters
# (characters, not bytes) exists that the old file did not have. SAME-LIST-COUNT:
# the number of lines that start with a list or quote marker is unchanged.
# SAME-PARAGRAPHS: every blank line stays, and the sequence of text columns
# (the indentation, plus the list marker on a marker line) is unchanged once
# equal neighbours are merged, so no paragraph is joined to another and no
# continuation line leaves its list item.
reflow_check() {
  local o="$1" n="$2" t z l p
  t=$(mktemp -d)
  tr -s ' \n' '  ' < "$o" > "$t/ow"; tr -s ' \n' '  ' < "$n" > "$t/nw"
  if cmp -s "$t/ow" "$t/nw"; then echo SAME-WORDS; else echo WORDS-DIFFER; fi
  z='NR == 1 && $0 == "---" { fm = 1; print; next }
     fm { print; if ($0 == "---") fm = 0; next }
     /^## / { keep = ($0 == "## Lens Instructions" || $0 == "## Report Marker") }
     /^[ ]*```/ { print; f = !f; next }
     f || keep || /^#/ || /^[ ]*\|/ { print }'
  awk "$z" "$o" > "$t/oz"; awk "$z" "$n" > "$t/nz"
  if cmp -s "$t/oz" "$t/nz"; then echo SAME-ZONES; else echo ZONES-DIFFER; fi
  perl -CSD -ne 'chomp; print "$_\n" if length > 88' "$o" | sort > "$t/ol"
  perl -CSD -ne 'chomp; print "$_\n" if length > 88' "$n" | sort > "$t/nl"
  if [ -z "$(comm -13 "$t/ol" "$t/nl")" ]; then echo NO-NEW-LONG; else echo NEW-LONG-LINES; fi
  l='^ *([-*+>] |[0-9]+\. )'
  if [ "$(grep -cE "$l" "$o")" = "$(grep -cE "$l" "$n")" ]; then echo SAME-LIST-COUNT; else echo LIST-COUNT-DIFFERS; fi
  p='{ if ($0 ~ /^[ \t]*$/) { print "B"; last = ""; next }
       match($0, /^ */); ind = RLENGTH; rest = substr($0, ind + 1)
       if (match(rest, /^([-*+>] |[0-9]+\. )/)) ind += RLENGTH
       if (ind "" != last) print ind; last = ind "" }'
  awk "$p" "$o" > "$t/op"; awk "$p" "$n" > "$t/np"
  if cmp -s "$t/op" "$t/np"; then echo SAME-PARAGRAPHS; else echo PARAGRAPHS-DIFFER; fi
  rm -rf "$t"
}
old=$(mktemp); git show HEAD:skills/multi-doc-review/SKILL.md > "$old"
reflow_check "$old" skills/multi-doc-review/SKILL.md; wc -l < skills/multi-doc-review/SKILL.md; rm -f "$old"
```

Expected: `SAME-WORDS`, `SAME-ZONES`, `NO-NEW-LONG`, `SAME-LIST-COUNT`, `SAME-PARAGRAPHS`, then a number ≤ 1015. When every zone is reflowed and the number is still above 1015, a number up to 1025 is accepted: commit it and name the shortfall in the report (Task 7 Step 3 continues the reflow). Above 1025, stop and report the task as blocked. The pinned strings of the contract (`first_line_of` anchors, `assert_file_has_line` lines, the three test-3 strings) are checked by the two suites below.

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'` and `bash tests/review-gates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: no FAIL line in either; both end `0 failed`.

- [ ] **Step 3: Commit**

```bash
git add skills/multi-doc-review/SKILL.md
git commit -m "style(multi-doc-review): reflow prose to 88 columns to recover lines for 7.75.0" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 6/9"
```

---

### Task 7: Evidence and inputs-read rules in multi-doc-review

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md` (Procedure step 2 partial definition; step 3 triage; step 5 convergence; Review Log Format; Error Handling)
- Modify: `tests/reviewer-templates/run-tests.sh` (new test section 33; the comment of test 16)

**Security flag:** `none`

**Does NOT cover:**
- The *settled* rule of the readiness passes (`Execution readiness` lens): unchanged in this release (spec section 2); a settled pass may carry an `**Inputs read:**` line.
- A fix-reviewed rule: the doc skill applies findings to the document and has no fix commit to review.
- The `partial` hit this task leaves: Procedure step 2 item 6 (Ids rule: fresh ids whenever M ≥ 2, whatever made the round partial). Item 8's byte-identical M = 1 ids sentence is left unchanged too (unrelated to inputs); it holds neither `partial` nor `u < M`, so the grep of Step 4 does not print it.
- The readiness instruction text and the `coverage:` strings pinned by test 12-15 (unchanged; a `coverage:` block may follow `### Inputs read`).

**Contract:**
- Evidence triage paragraph (wording artifact), in step 3 after the sentence "Every Critical/Important finding is either applied to the document or `rejected: <reason>` — never silently dropped." and the Minor sentence that follows, before `**A deliberate spec deviation is recorded on a fixed line.**`: the same properties as Task 4's contract, with "triaged normally" meaning applied or `rejected: <reason>` on its merits, and `(evidence: <reason>)` placed directly after the finding summary, before any `— harness probe:` clause or ` ← ` annotation. Verification: test 33 (shared phrases of test 31).
- Partial-round definition (wording artifact), step 2: "… (inputs read, step 5)"; old phrase absent. Verification: test 33.
- Convergence rule (wording artifact), step 5: as Task 5's, with the expected set `document`, plus `spec` when the pasted lens text contains `read the spec listed under Target`; and "A readiness pass keeps its *settled* rule unchanged". Verification: test 33.
- Audit-log rule (wording artifact): the `**Inputs read:**` line as in Task 5, written in rotating rounds and readiness passes, with the example line `**Inputs read:** r1: spec partial — not read: 735-end | r2: document partial — not read: 549-1069; spec not declared | r3: not declared`; clean-round line forms; byte-identical qualifier. Verification: test 33.
- Error Handling bullets (wording artifact): `(u < M)` named; new inputs-read bullet. Verification: test 33.
- Clean-round scope and restatements (wording artifact): as in Task 5 — the condition on the plain line and the `inputs read` cause apply to rotating rounds only, so a settled readiness pass with an empty consolidated set still writes the plain line `Readiness entries` names; the restatements at lines 915 and 942 are rewritten; the `- <input>: partial` rule; the evidence rule applies to rotating rounds, and a readiness finding is disposed under `Triage of a readiness finding`. Verification: test 33 and Step 4's second grep.
- Line budget (code artifact invariant): the file stays at most 1080 lines. The additions of this task are about 60-65 lines at 88 columns; with Task 6 at 1015 lines they fit, and Step 3's further reflow, under Task 6's contract rules, covers a shortfall of Task 6. Verification: test 16.

- [ ] **Step 1: Write the failing tests**

Add this section to `tests/reviewer-templates/run-tests.sh`, directly above the final `echo` / `bold "Results: …"` lines:

```bash
bold "33. multi-doc-review: the evidence triage rule and the inputs-read rules (release 7.75.0)"
DOC_PARTIAL_DEF="$PARTIAL_DEF_HEAD (inputs read, step 5)"
DOC_EXPECTED_SET='The expected set is `document`, plus `spec` when the lens text you pasted into `[LENS_INSTRUCTIONS]` contains the words `read the spec listed under Target`'
DOC_SETTLED_UNCHANGED='A readiness pass keeps its *settled* rule unchanged'
DOC_EVIDENCE_READINESS='a readiness finding is disposed under `Triage of a readiness finding`'
DOC_LOG_EXAMPLE='**Inputs read:** r1: spec partial — not read: 735-end | r2: document partial — not read: 549-1069; spec not declared | r3: not declared'
DOC_ENTRY_KINDS='rotating rounds and readiness passes'
DOC_TRIAGE_RANGE="$WORK/doc-triage-range.md"
awk '/^3\. \*\*Triage and merge:\*\*/ { on = 1 } /^4\. \*\*Append the round entry\*\*/ { exit } on { print }' "$DOC_SKILL" > "$DOC_TRIAGE_RANGE"
if [ -s "$DOC_TRIAGE_RANGE" ]; then ok "multi-doc-review SKILL.md: Triage step extract is non-empty"; else bad "multi-doc-review SKILL.md: Triage step extract is empty"; fi
for phrase in "$EVIDENCE_RULE_LEAD" "$EVIDENCE_TEXT_ONLY" "$EVIDENCE_ONE_SOURCE" "$EVIDENCE_REJECT" "$EVIDENCE_REASONS" \
              "$EVIDENCE_REASONS_ONLY" "$EVIDENCE_CRITICAL" "$EVIDENCE_NOTE" "$EVIDENCE_NOT_LOGGED" "$EVIDENCE_ABSENCE" \
              "$DOC_EVIDENCE_READINESS"; do
  assert_folded_contains "multi-doc-review SKILL.md Triage step: '$phrase'" "$DOC_TRIAGE_RANGE" "$phrase"
done
assert_folded_not_contains "multi-doc-review SKILL.md: the old partial-round definition is gone" "$DOC_SKILL" "$PARTIAL_DEF_OLD"
for phrase in "$DOC_PARTIAL_DEF" "$CONVERGENCE_INPUTS" "$DOC_EXPECTED_SET" "$INPUT_NOT_DECLARED" "$SECTION_NOT_DECLARED" \
              "$EITHER_CAUSE" "$PARTIAL_WHATEVER" "$CLEAN_LINE_SCOPE" "$NEVER_RETRIED" "$DOC_SETTLED_UNCHANGED" "$LOG_POSITION" "$LOG_SHAPES" "$LOG_UNKNOWN" \
              "$DOC_ENTRY_KINDS" "$CLEAN_LINE_INPUTS" "$CLEAN_LINE_BOTH" "$BYTE_IDENTICAL_QUALIFIED" "$ERROR_INPUTS_BULLET" \
              "$ERROR_RETRY_BULLET"; do
  assert_folded_contains "multi-doc-review SKILL.md: '$phrase'" "$DOC_SKILL" "$phrase"
done
assert_file_has_line "multi-doc-review SKILL.md: the Inputs read log example line" "$DOC_SKILL" "$DOC_LOG_EXAMPLE"
assert_folded_not_contains "multi-doc-review SKILL.md: the u = M-only clean-round sentence is gone" "$DOC_SKILL" 'A clean round (zero findings, with u = M) writes'
assert_folded_not_contains "multi-doc-review SKILL.md: the u = M-only Sources mapped parenthesis is gone" "$DOC_SKILL" 'A clean round (u = M, empty consolidated set)'
```

In the comment of test 16, replace the two lines `# addition must first recover lines by reflowing, per the plan's Global` / `# Constraint 1.` with:

```bash
# addition must first recover lines by reflowing, per the plan's Global
# Constraint 1. Release 7.75.0 reflowed prose to 88 columns before it added
# the evidence-line and inputs-read rules.
```

(Check the step headings first: `grep -n '^3\. \*\*Triage and merge:\*\*\|^4\. \*\*Append the round entry' skills/multi-doc-review/SKILL.md` prints two lines.)

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for the test-33 Triage-step phrases, the old-definition check, every `multi-doc-review SKILL.md: '…'` check, the log-example line, and the two negative checks `the u = M-only clean-round sentence is gone` and `the u = M-only Sources mapped parenthesis is gone` (their strings are in the file today, lines 942 and 915).

- [ ] **Step 3: Edit `skills/multi-doc-review/SKILL.md`**

Locate each sentence by its words (Task 6 changed the line breaks), and write the new text at 88 columns with the indentation of its paragraph. First read the "Order of work" paragraph at the end of this step: its first item runs before item 1. The rewrites of items 1-8 follow the untouched-zone and no-break rules of Task 6's Contract too; in particular, item 8 leaves `Skipped invocations (N=0)` whole on one line.

1. Step 2: the clause `a round with u < M is *partial* — it is logged with its counts and is never clean.` becomes `a round is *partial* when fewer than M reviewers returned a usable report (u < M) or when a usable report does not declare every expected input `whole` (inputs read, step 5) — it is logged with its counts and is never clean.`

2. Step 3: after the sentence `Minor findings: apply at your discretion; log all dispositions either way.` insert, as a paragraph at three-space indentation, with no blank line before or after it (like the neighbouring `**A deliberate spec deviation …**` paragraph, which follows that sentence today with no blank line):

```text
   **Evidence line.** Before you choose the disposition of a Critical or Important
   finding, read its `evidence:` line against the finding's claim — a text comparison
   inside the report; open no file for it. With M ≥ 2 read each source's line in its own
   report; the finding matches when at least one source's line matches. A presence or
   gap line matches when its quoted text shows the defect (in the gap form, the text the
   finding says is incomplete) and, for a line or range location, its number is that
   line or lies inside the range; the absence form carries no line number and matches on
   its pattern alone, when the pattern describes the missing thing; the secret form
   matches on its number alone, the removed-file form on its path alone. A finding with
   a `harness:` field needs no evidence line; the harness procedure runs first. A
   finding whose line is missing or matches in no source is triaged normally (applied,
   or `rejected: <reason>` on its merits); you may instead reject such an **Important**
   finding as `rejected: evidence (<reason>)`, the parenthesis holding one of five fixed
   phrases and nothing else: `missing`, `line differs`, `text does not show the defect`,
   `pattern does not describe the missing thing`, `input partial` — the last for a
   gap-form or absence-form finding whose report declares that input `partial` or not
   at all (step 5). A Critical finding is never rejected under this rule: write
   `(evidence: <reason>)` after its finding summary, before any `— harness probe:`
   clause or ` ← ` annotation. The evidence line itself is never copied into the log.
   Whether a quoted line lies in the named section is not checked here; a readiness
   finding is disposed under `Triage of a readiness finding`, never by this rule.
```

3. Step 5: replace the sentence that starts `A round is *clean* when the consolidated set enumerates zero Critical and zero Important` and ends `breaks the streak, like an `inconclusive` round.` with:

```text
   A round is *clean* when the consolidated set enumerates zero Critical and zero
   Important **and** all M reviewers returned a usable report (u = M) **and** every
   usable report's `### Inputs read` section carries, for every input of the expected
   set, a line that reads `whole` (`- <input>: whole`, nothing after the word); a line
   that begins `- <input>: partial` is a `partial` declaration whatever follows it. The
   expected set is `document`, plus `spec` when the lens text you pasted into
   `[LENS_INSTRUCTIONS]` contains the words `read the spec listed under Target` (any run
   of whitespace, a line break included, counts as one space; the words stand in the
   `plan` cell of `Correctness & completeness` and in the `Execution readiness` cell); a
   line for any other input is ignored. A round where, in any usable report, an
   expected input is declared `partial`, or its line is missing or outside that grammar
   (*input not declared*), or the whole section is missing (*not declared*), is partial
   for the inputs-read cause: its findings are consolidated and triaged normally, no
   report is retried for it, and its entry carries the `**Inputs read:**` line. A
   partial round — for either cause — is never clean and breaks the streak, like an
   `inconclusive` round. A readiness pass keeps its *settled* rule unchanged.
```

4. Review Log Format: the sentence `the round entry that follows them (M = 1) is byte-identical to earlier releases:` becomes `the round entry that follows them (M = 1) is byte-identical to earlier releases when every usable report declares every input `whole`:`.

5. The clean-round bullet (`- The clean-round line `- none — no material issues under this lens` is`) becomes:

```text
- The clean-round line `- none — no material issues under this lens` is written without
  annotation and only when the consolidated set is empty **and** u = M **and — in a
  rotating round — every usable report declares every expected input `whole`**. A
  partial round with an empty consolidated set writes
  `- none — no material issues under this lens (partial round, usable <u>/<m>)` when
  only u < M applies. A rotating round that is partial only for inputs read writes
  `- none — no material issues under this lens (partial round, inputs read)`, and with
  both causes `(partial round, usable <u>/<m>, inputs read)`. No other entry kind
  writes the `inputs read` cause; a readiness pass keeps today's line.
```

(As in Task 5: no `**` marker between `and — in a` and `` `whole` ``; test 33's folded pin `CLEAN_LINE_SCOPE` reads them as one string.)

6. After the `An `inconclusive` round (u = 0) with M ≥ 2 writes` bullet (the last bullet of "Rules for the added lines") and before `A clean round (zero findings, with u = M) writes exactly one disposition line`, insert (fence lines at column 0):

````text
**The `**Inputs read:**` line.** Written only when a usable report declares an expected
input (step 5) `partial` or does not declare it, and placed directly after the
`**Reviewer verdict:**` line:

```
**Inputs read:** r1: spec partial — not read: 735-end | r2: document partial — not read: 549-1069; spec not declared | r3: not declared
```

Entry shapes: `<input> partial — not read: <ranges>` (`partial — not read: unknown` when
the line names no range), `<input> not declared` (line missing or outside the grammar),
and a bare `not declared` (no section). One entry per affected usable reviewer, in
reviewer order, separated by ` | `, its inputs by `; `; `r<j>` as on the
`**Reviewer verdicts:**` line (`r1: …` when M = 1); unusable reviewers are not
listed. It is written in rotating rounds and readiness passes, as a record: the
outcome follows step 5 or, in a readiness pass, the unchanged *settled* rule.
````

7. Error Handling: `- One or more reviewers unusable after one retry, u ≥ 1 → partial round:` becomes `- One or more reviewers unusable after one retry, u ≥ 1 → partial round (u < M):`; after that bullet insert:

```text
- A usable report that declares an expected input `partial`, or does not declare it (no
  `### Inputs read` section, or the input's line missing or outside the grammar) →
  partial round (inputs read): triage normally, write the `**Inputs read:**` line,
  never retry; the round is never clean.
```

8. The two Review Log Format sentences that restate the clean-round rule with u = M alone (spec 5.4: every site that defines the term is updated). In the `**Sources mapped:**` bullet (today line 915), replace `A clean round (u = M, empty consolidated set)` with `A round with u = M and an empty consolidated set`. The sentence `A clean round (zero findings, with u = M) writes exactly one disposition line:` (today line 942, directly below the paragraph item 6 inserts) becomes `A clean round (zero findings, with u = M and — in a rotating round — every expected input declared `whole`, step 5) writes exactly one disposition line:`.

Order of work, so that every reflow is checked by Task 6's `reflow_check`. Each Bash call may start a new shell, so a variable or a function does not survive to the next call: write down the path that `mktemp` prints and use it literally in later commands, and paste the `reflow_check` definition of Task 6 Step 2 again into the Bash call that runs it.
- Before item 1: when `wc -l < skills/multi-doc-review/SKILL.md` prints more than 1015 (1080 minus the about 65 lines items 1-8 add), save a copy (`pre=$(mktemp); cp skills/multi-doc-review/SKILL.md "$pre"`), reflow further zones under the rules of Task 6's contract until it prints at most 1015, then run `reflow_check "$pre" skills/multi-doc-review/SKILL.md`; it must print `SAME-WORDS`, `SAME-ZONES`, `NO-NEW-LONG`, `SAME-LIST-COUNT` and `SAME-PARAGRAPHS`. When every zone is reflowed and the file is still above 1015, go on with items 1-8: the "After item 8" rules then decide.
- After item 8: when the file still has more than 1080 lines, save a copy the same way, reflow paragraphs this step did not write until the file has at most 1080 lines, and run `reflow_check` against that copy with the same expected five words.
- Zones, in this order: the zones of Task 6 Step 1 not yet reflowed, then any other prose paragraph or list item outside the untouched list of Task 6's contract. When every such zone is reflowed and the file still has more than 1080 lines, shorten the new text of items 2, 3, 5 and 6 (reference texts: only the test-33 needles bind; keep every needle of `EVIDENCE_*`, `LOG_*`, `CLEAN_LINE_*`, `DOC_*`, `PARTIAL_*` and the shared phrases folded in the file). When that is not enough, stop the task and report it as blocked, naming the line count: do not raise `MDR_MAX_LINES`, and remove no existing content (Global Constraint 1).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: <n> passed, 0 failed` (test 16's 1080-line budget included).

Run: `bash tests/review-gates/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: no FAIL line.

Run: `grep -n 'u < M\|partial' skills/multi-doc-review/SKILL.md`
Expected: the changed sites of this task (the `**Evidence line.**` paragraph's `input partial` lines included) plus the one left site named under "Does NOT cover"; no hit reads `a round with u < M is *partial*`.

Run: `grep -n -i 'clean round (' skills/multi-doc-review/SKILL.md`
Expected: only the sentence item 8 rewrote (the inputs-read condition may stand on the next line); no hit reads `with u = M) writes`.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-doc-review/SKILL.md tests/reviewer-templates/run-tests.sh
git commit -m "feat(multi-doc-review): evidence triage rule and inputs-read declarations decide clean rounds" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 7/9"
```

---

### Task 8: Acceptance-measure script `tools/count-report-fields.js` and its suite

**Files:**
- Create: `tools/count-report-fields.js`
- Create: `tests/count-report-fields/run-tests.sh`
- Create: `tests/count-report-fields/fixtures/review-log.md`
- Create: `tests/count-report-fields/fixtures/subagents/handback-with-write.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/text-block-report.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/no-inputs-section.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/heading-then-prose.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/evidence-not-adjacent.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/fix-subagent.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/pointer-reviewer.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/no-marker-reviewer.jsonl`
- Create: `tests/count-report-fields/fixtures/subagents/no-marker-reviewer.meta.json`
- Modify: `tests/suite-guard/run-tests.sh` (lines 62-66, `MIN_GUARDED_SUITES`)
- Modify (git-ignored, not committed): `CLAUDE.md` (Testing list)

**Security flag:** `none`

**Does NOT cover:** a reviewer whose prompt reaches it neither in the first user message nor in the Read result of a pointer file; nested `subagents/` folders (the folder is read flat, as the spec states every subagent of a session sits in it); a form check of evidence lines (presence only, spec section 9); disposition text outside lines that start `- [`.

**Contract:**
- `count-report-fields.js <subagents-dir> <review-log>` (code artifact)
  - Inputs: a folder of `.jsonl` transcripts (with optional `.meta.json` neighbours) and a review-log file.
  - Output, line 1 exactly: `reviewer-transcripts: <t>  other: <o>  reports: <n>  with-inputs-read: <k>  ci-findings: <f>  with-evidence: <e>  secret-form-lines: <s>  rejected-evidence-lines: <r>`; line 2: `per-input: diff <v>/<x>  plan <v>/<x>  document <v>/<x>  spec <v>/<x>` (valid declarations / reports that expect that input); then one `no report: <path>[ — <description>]` line per reviewer transcript without a marked report. Exit 0; exit 2 with the usage line on standard error when an argument is missing or the folder or the log cannot be read.
  - Invariants: a transcript is a reviewer transcript when its prompt — the first user message, plus the Read results of the file a pointer message names — holds `## Lens (your ONLY focus in this review)`; one report per transcript (the last `SubagentHandback` `message` input, else the last assistant text block; a `Write` copy is never counted); a report is recognised by `<!-- multi-review report -->` within its first 10 non-blank lines; expected inputs come from the four prompt sentences matched on whitespace-folded text; a line counts for an input only in the grammar `- <input>: whole` or `- <input>: partial — not read: <ranges>`; a C/I finding is an id line `- [X<n>]` under `#### Critical` or `#### Important`, and it has evidence when its next non-blank line starts, after indentation, with `evidence: `; `<r>` counts log lines starting `- [` that contain `rejected: evidence (` or `(evidence: `.
  - Verification: `bash tests/count-report-fields/run-tests.sh` on the eight fixture transcripts.
  - Interface not externally pinned — the output format is the spec's (section 9); no other component reads it, so it may change in a later fix, and only together with this suite.
- Fixture cases (code artifact): the fixture folder keeps one transcript per case, each driving the named counter: a `SubagentHandback` report with a `Write` copy (counted once: `reports`); a text-block report with a sentence above its marker (`reports`, `spec` per-input); a report without `### Inputs read` (`with-inputs-read` not counted, `plan` expected); a heading followed by prose (not with-inputs-read; `secret-form-lines`); an evidence line not directly below its id line and `whole (4 pages)` (`with-evidence` and the grammar); a pointer-dispatched reviewer (`reviewer-transcripts`, annotated partial range); a reviewer without a marked report (`no report:` line with its description); a fix subagent (`other`); and `review-log.md` with one `rejected: evidence (` line, one `(evidence: ` line and one non-disposition line (`rejected-evidence-lines`). Verification: Step 4's expected lines.
- `tests/count-report-fields/run-tests.sh` (code artifact): loads `tests/lib/undefined-command-guard.sh` within its first 45 lines; fails when any expected line differs. Verification: Step 2 (fails without the script), Step 4 (passes), `bash tests/suite-guard/run-tests.sh`.
- `MIN_GUARDED_SUITES` (code artifact): 21. Verification: `bash tests/suite-guard/run-tests.sh` passes with 21 suites.

- [ ] **Step 1: Write the fixtures and the failing suite**

Create `tests/count-report-fields/fixtures/review-log.md`:

```markdown
## Round 1 — Correctness & spec alignment — opus
**Reviewer verdict:** 1 Critical, 2 Important, 0 Minor
**Inputs read:** r1: diff partial — not read: 547-864
**Converged:** no
### Dispositions
- [C1] fixed — retry loop never stops (evidence: line differs) → abc1234
- [I1] rejected: evidence (missing) — helper skips the empty case
- [I2] rejected: duplicate of [I1] — same defect as I1
- note: the words rejected: evidence (missing) in prose are not a disposition line
```

Create the transcripts, one JSON object per line, exactly as below.

`tests/count-report-fields/fixtures/subagents/handback-with-write.jsonl` (a report in a `SubagentHandback` input with a `Write` copy: counted once; C1 has an evidence line directly below, I1 has none):

```json
{"type":"user","message":{"role":"user","content":"You are an independent code reviewer.\n\nRead the diff file whole, with the Read tool.\n\n## Lens (your ONLY focus in this review)\n\n**Adversarial red-team.** Break it."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"w1","name":"Write","input":{"file_path":"/tmp/report-1","content":"<!-- multi-review report -->\n\n### Verdict\nCritical: 1 | Important: 1 | Minor: 0\n\n### Findings\n#### Critical\n- [C1] src/retry.js:40 — loops forever | hangs the worker | stop after max\n  evidence: 40\t  return attempts > max ? null : retry(fn)\n#### Important\n- [I1] src/retry.js:52 — no back-off | floods the server | add a delay\n#### Minor\n\n### Inputs read\n- diff: whole\n\n### Checks Run\n- none"}}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"h1","name":"SubagentHandback","input":{"message":"<!-- multi-review report -->\n\n### Verdict\nCritical: 1 | Important: 1 | Minor: 0\n\n### Findings\n#### Critical\n- [C1] src/retry.js:40 — loops forever | hangs the worker | stop after max\n  evidence: 40\t  return attempts > max ? null : retry(fn)\n#### Important\n- [I1] src/retry.js:52 — no back-off | floods the server | add a delay\n#### Minor\n\n### Inputs read\n- diff: whole\nFull report: /tmp/report-1"}}]}}
```

`…/text-block-report.jsonl` (a doc reviewer; the report is the last assistant text block with a sentence above its marker; the spec sentence is wrapped across a line break; `partial` with a range is grammar-valid):

```json
{"type":"user","message":{"role":"user","content":"You are an independent document reviewer.\n\nDocument (read it whole, with the Read tool): /repo/plan.md\n\n## Lens (your ONLY focus in this review)\n\n**Correctness & completeness.** Find: spec-coverage gaps (read the\n  spec listed under Target)."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Here is my report.\n<!-- multi-review report -->\n\n### Verdict\nNo material issues under this lens.\n\n### Inputs read\n- document: whole\n- spec: partial — not read: 120-end"}]}}
```

`…/no-inputs-section.jsonl` (no `### Inputs read` section; a lens-1 prompt with the plan sentence; C1 has a `grep -nH` evidence line):

```json
{"type":"user","message":{"role":"user","content":"You are an independent code reviewer.\n\nRead the diff file whole, with the Read tool.\n\nPlan/requirements the branch implements (read it first): /repo/plan.md\n\n## Lens (your ONLY focus in this review)\n\n**Correctness & spec alignment.** Compare."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"h3","name":"SubagentHandback","input":{"message":"<!-- multi-review report -->\n\n### Verdict\nCritical: 1 | Important: 0 | Minor: 0\n\n### Findings\n#### Critical\n- [C1] src/a.js:7 — wrong operator | inverts the check | use >=\n  evidence: src/a.js:7:  if (n > max) {\n#### Important\n#### Minor\nFull report: /tmp/report-3"}}]}}
```

`…/heading-then-prose.jsonl` (the heading followed by prose: not with-inputs-read; I1 carries a secret-form evidence line):

```json
{"type":"user","message":{"role":"user","content":"You are an independent document reviewer.\n\nDocument (read it whole, with the Read tool): /repo/spec.md\n\n## Lens (your ONLY focus in this review)\n\n**Adversarial failure modes.** Break the design."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"h4","name":"SubagentHandback","input":{"message":"<!-- multi-review report -->\n\n### Verdict\nCritical: 0 | Important: 1 | Minor: 0\n\n### Findings\n#### Critical\n#### Important\n- [I1] §3: the token is pasted in the text | leaks a credential | cite it by line\n  evidence: 57 — secret-bearing line, not quoted\n#### Minor\n\n### Inputs read\nI read the whole document."}}]}}
```

`…/evidence-not-adjacent.jsonl` (an evidence line that is not directly below its id line: not with-evidence; `- diff: whole (4 pages)` is outside the grammar):

```json
{"type":"user","message":{"role":"user","content":"You are an independent code reviewer.\n\nRead the diff file whole, with the Read tool.\n\n## Lens (your ONLY focus in this review)\n\n**Security.** Find unsafe code."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"h5","name":"SubagentHandback","input":{"message":"<!-- multi-review report -->\n\n### Verdict\nCritical: 0 | Important: 1 | Minor: 0\n\n### Findings\n#### Critical\n#### Important\n- [I1] src/b.js:9 — path not checked | reads any file | check the root\n  (the same input reaches line 12)\n  evidence: 9\t  fs.readFileSync(userPath)\n#### Minor\n\n### Inputs read\n- diff: whole (4 pages)"}}]}}
```

`…/fix-subagent.jsonl` (a non-reviewer: no lens heading, counted under `other`):

```json
{"type":"user","message":{"role":"user","content":"You are a fix subagent. Fix the findings below.\n\n- [I1] src/b.js:9 — path not checked"}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"h6","name":"SubagentHandback","input":{"message":"Fixed I1 in abc1234."}}]}}
```

`…/pointer-reviewer.jsonl` (a reviewer dispatched by pointer: the lens heading and the input sentences are in the Read result of the pointer file, with Read line prefixes; an annotated partial range is grammar-valid):

```json
{"type":"user","message":{"role":"user","content":"Your complete instructions are in the file /tmp/fixture-prompts/round-1-reviewer.md.\nRead that file once, with the Read tool, before doing anything else, and follow it as your only instructions.\nNothing else in that directory is for you; do not read any other file there."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"r7","name":"Read","input":{"file_path":"/tmp/fixture-prompts/round-1-reviewer.md"}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"r7","content":"1\tYou are an independent code reviewer.\n2\t\n3\tRead the diff file whole, with the Read tool.\n4\t\n5\tPlan/requirements the branch implements (read it first): /repo/plan.md\n6\t\n7\t## Lens (your ONLY focus in this review)\n8\t\n9\t**Correctness & spec alignment.** Compare."}]}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"h7","name":"SubagentHandback","input":{"message":"<!-- multi-review report -->\n\n### Verdict\nNo material issues under this lens.\n\n### Inputs read\n- diff: partial — not read: 547-864 (package-lock.json)\n- plan: whole"}}]}}
```

`…/no-marker-reviewer.jsonl` (a reviewer without a marked report: listed with its description):

```json
{"type":"user","message":{"role":"user","content":"You are an independent code reviewer.\n\nRead the diff file whole, with the Read tool.\n\n## Lens (your ONLY focus in this review)\n\n**Adversarial red-team.** Break it."}}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"I ran out of time before writing the report."}]}}
```

`…/no-marker-reviewer.meta.json`:

```json
{"agentType":"general-purpose","description":"multi-code-review round 2: Adversarial red-team"}
```

Create `tests/count-report-fields/run-tests.sh` (and `chmod +x` it, like the other suites):

```bash
#!/usr/bin/env bash
# count-report-fields test suite: unit tests on tools/count-report-fields.js,
# the committed script that takes the acceptance measure of release 7.75.0
# (the reviewer evidence line and the inputs-read declaration). Pure bash +
# node; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# output goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-
# and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md, section 9.
#
# The fixture folder holds eight transcripts. Seven are reviewers (the lens
# heading is in the prompt): a report in a SubagentHandback input with a Write
# copy (counted once); a report as a text block with a sentence above its
# marker; a report with no `### Inputs read` section; a section heading
# followed by prose; an evidence line that is not directly below its id line
# and a `whole` line with words after it; a reviewer dispatched by pointer,
# whose prompt is in the Read result of the pointer file; a reviewer without a
# marked report. One is a fix subagent (no lens heading).

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/tools/count-report-fields.js"
FIX="$ROOT/tests/count-report-fields/fixtures"
SUBAGENTS="$FIX/subagents"
LOG="$FIX/review-log.md"
EXIT_OK=0
EXIT_USAGE=2
USAGE_FRAGMENT='usage: node tools/count-report-fields.js <subagents-dir> <review-log>'
EXPECTED_COUNTS='reviewer-transcripts: 7  other: 1  reports: 6  with-inputs-read: 3  ci-findings: 5  with-evidence: 3  secret-form-lines: 1  rejected-evidence-lines: 2'
EXPECTED_PER_INPUT='per-input: diff 2/4  plan 1/2  document 1/2  spec 1/1'
# The path part is compared from its last separator on: on Windows Git Bash
# node receives a C:/ path and writes back-slashes.
EXPECTED_NO_REPORT='no report: no-marker-reviewer.jsonl — multi-code-review round 2: Adversarial red-team'
EXPECTED_LINES=3

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }
ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }
assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
# run_script <out-file> <err-file> [args...]: run the script, leave its exit
# code in STATUS.
run_script() {
  local out="$1" err="$2"
  shift 2
  node "$SCRIPT" "$@" > "$out" 2> "$err"
  STATUS=$?
}
assert_usage_error() { # desc err-file
  assert_eq "$1: exit code" "$STATUS" "$EXIT_USAGE"
  if grep -qF -- "$USAGE_FRAGMENT" "$2"; then ok "$1: prints the usage line"; else bad "$1: prints the usage line"; fi
}

bold "1. Counts over the fixture folder"
OUT="$WORK/out.txt"
run_script "$OUT" "$WORK/err.txt" "$SUBAGENTS" "$LOG"
assert_eq "exit code" "$STATUS" "$EXIT_OK"
assert_eq "line 1: the counts" "$(sed -n 1p "$OUT")" "$EXPECTED_COUNTS"
assert_eq "line 2: the count per expected input" "$(sed -n 2p "$OUT")" "$EXPECTED_PER_INPUT"
assert_eq "line 3: the reviewer transcript without a report, with its description" "$(sed -n 3p "$OUT" | sed 's#^no report: .*[/\\]#no report: #')" "$EXPECTED_NO_REPORT"
assert_eq "no further line" "$(awk 'END { print NR }' "$OUT")" "$EXPECTED_LINES"

bold "2. Usage errors"
run_script "$WORK/out2.txt" "$WORK/err2.txt"
assert_usage_error "no argument" "$WORK/err2.txt"
run_script "$WORK/out3.txt" "$WORK/err3.txt" "$WORK/missing-folder" "$LOG"
assert_usage_error "a folder that does not exist" "$WORK/err3.txt"
run_script "$WORK/out4.txt" "$WORK/err4.txt" "$SUBAGENTS" "$WORK/missing-log.md"
assert_usage_error "a review log that does not exist" "$WORK/err4.txt"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
```

In `tests/suite-guard/run-tests.sh`, replace

```bash
# guarded suites on the day of its last change (12 when it was written, 20
# now). Raise it when a suite is added: a suite file that disappears then
# fails the check.
MIN_GUARDED_SUITES=20
```

with

```bash
# guarded suites on the day of its last change (12 when it was written, 21
# now). Raise it when a suite is added: a suite file that disappears then
# fails the check.
MIN_GUARDED_SUITES=21
```

(Check the exact current wording first with `sed -n 60,67p tests/suite-guard/run-tests.sh`.)

- [ ] **Step 2: Run the suite to verify it fails**

Run: `bash tests/count-report-fields/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: FAIL lines for every check of section 1 (node cannot find `tools/count-report-fields.js`, so the exit code is 1 and the output is empty), for the three section-2 exit-code checks (node exits 1, not 2) and for the `prints the usage line` checks; `Results: … failed`.

- [ ] **Step 3: Write the script**

Create `tools/count-report-fields.js`:

```js
#!/usr/bin/env node
// Count the reviewer report fields of one review run.
//
// Written for the acceptance measure of release 7.75.0 (spec
// docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-and-inputs-read/
// specs/reviewer-evidence-and-inputs-read-design.md, section 9): every
// reviewer report carries an `### Inputs read` section, and every Critical
// and Important finding carries an `evidence:` line directly below it.
//
// Usage: node tools/count-report-fields.js <subagents-dir> <review-log>
//
// <subagents-dir> is the `subagents/` folder of one session
// (~/.claude/projects/<project>/<session>/subagents/). It holds one `.jsonl`
// transcript per subagent of the session — reviewers, fix subagents,
// controllers and others — and a `.meta.json` file next to most of them.
// <review-log> is the review log of the same run.
//
// A transcript is a reviewer transcript when its prompt holds the lens
// heading of the two reviewer templates. The prompt is the first user
// message. When that message is the pointer of a dispatch by pointer ("Your
// complete instructions are in the file <path>."), the prompt also includes
// the Read results of that file, because the reviewer receives its
// instructions there and not in its first message (multi-code-review
// dispatches every reviewer by pointer). The spec's definition names the
// first user message only; that definition finds no pointer-dispatched
// reviewer.
//
// One report is taken per transcript: the `message` input of the last
// SubagentHandback tool call, else the last assistant text block. A copy of
// the report in a Write tool input is never counted.
//
// Exit codes: 0 counted; 2 usage error (an argument missing, or the folder or
// the log cannot be read).

'use strict';

const fs = require('fs');
const path = require('path');

const USAGE = 'usage: node tools/count-report-fields.js <subagents-dir> <review-log>';
const EXIT_USAGE = 2;
const TRANSCRIPT_EXT = '.jsonl';
const META_EXT = '.meta.json';
const LENS_HEADING = '## Lens (your ONLY focus in this review)';
const POINTER_RE = /Your complete instructions are in the file (\S+?)\.(?:\s|$)/;
// A Read result prefixes each line with its line number and a tab.
const READ_LINE_PREFIX_RE = /^\s*\d+\t/;
const MARKER = '<!-- multi-review report -->';
const MARKER_WINDOW = 10;
const HANDBACK_TOOL = 'SubagentHandback';
const READ_TOOL = 'Read';
const HEADING_RE = /^#{1,6} /;
const CI_HEADINGS = ['#### Critical', '#### Important'];
const ID_LINE_RE = /^- \[[A-Z]+[0-9]+\]/;
const EVIDENCE_PREFIX = 'evidence: ';
const SECRET_FORM_RE = /^evidence: [0-9]+ — secret-bearing line, not quoted$/;
const INPUTS_HEADING = '### Inputs read';
// One unread range: `<a>-<b>` or `<a>-end`, optionally followed by the diff
// paths it covers in parentheses.
const RANGE = '[0-9]+-(?:[0-9]+|end)(?: \\([^()]+\\))?';
const INPUT_LINE_RE = new RegExp(
  '^- (diff|plan|document|spec): (?:whole|partial — not read: (?:unknown|' + RANGE + '(?:, ' + RANGE + ')*))$'
);
// Each input of the expected set, with the prompt sentence that names it.
const INPUTS = [
  { name: 'diff', needle: 'Read the diff file whole' },
  { name: 'plan', needle: 'Plan/requirements the branch implements (read it first):' },
  { name: 'document', needle: 'Document (read it whole' },
  { name: 'spec', needle: 'read the spec listed under Target' },
];
const DISPOSITION_PREFIX = '- [';
const REJECTED_EVIDENCE = 'rejected: evidence (';
const CRITICAL_NOTE = '(evidence: ';

function usage(detail) {
  process.stderr.write((detail ? detail + '\n' : '') + USAGE + '\n');
  process.exit(EXIT_USAGE);
}

function readRecords(file) {
  const records = [];
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (!line.trim()) continue;
    try {
      records.push(JSON.parse(line));
    } catch (e) {
      // The last line of a transcript that was still being written can be
      // cut; it holds no complete record, so it is skipped.
    }
  }
  return records;
}

function blocks(record) {
  const content = record && record.message && record.message.content;
  if (typeof content === 'string') return [{ type: 'text', text: content }];
  return Array.isArray(content) ? content : [];
}

function resultText(block) {
  const content = block.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) return content.filter((b) => b && b.type === 'text').map((b) => b.text).join('\n');
  return '';
}

function stripReadPrefixes(text) {
  return text.split('\n').map((line) => line.replace(READ_LINE_PREFIX_RE, '')).join('\n');
}

// The prompt of a transcript with every run of whitespace folded to one
// space, so that a sentence wrapped across a line break still matches.
function promptText(records) {
  const first = records.find((r) => r.type === 'user' && blocks(r).some((b) => b.type === 'text'));
  if (!first) return '';
  const parts = blocks(first).filter((b) => b.type === 'text').map((b) => b.text);
  const pointer = parts.join('\n').match(POINTER_RE);
  if (pointer) {
    const readIds = new Set();
    for (const r of records) {
      if (r.type !== 'assistant') continue;
      for (const b of blocks(r)) {
        if (b.type === 'tool_use' && b.name === READ_TOOL && b.input && b.input.file_path === pointer[1]) readIds.add(b.id);
      }
    }
    for (const r of records) {
      if (r.type !== 'user') continue;
      for (const b of blocks(r)) {
        if (b.type === 'tool_result' && readIds.has(b.tool_use_id)) parts.push(stripReadPrefixes(resultText(b)));
      }
    }
  }
  return parts.join('\n').replace(/\s+/g, ' ');
}

function takenReport(records) {
  let handback = null;
  let text = null;
  for (const r of records) {
    if (r.type !== 'assistant') continue;
    for (const b of blocks(r)) {
      if (b.type === 'tool_use' && b.name === HANDBACK_TOOL && b.input && typeof b.input.message === 'string') {
        handback = b.input.message;
      } else if (b.type === 'text' && typeof b.text === 'string') {
        text = b.text;
      }
    }
  }
  return handback !== null ? handback : text;
}

// The report's lines below its marker line, or null when no line among the
// first MARKER_WINDOW non-blank lines starts with the marker.
function reportBody(report) {
  if (typeof report !== 'string') return null;
  const lines = report.split('\n').map((line) => line.replace(/\s+$/, ''));
  let nonBlank = 0;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    nonBlank += 1;
    if (nonBlank > MARKER_WINDOW) return null;
    if (lines[i].trim().startsWith(MARKER)) return lines.slice(i + 1);
  }
  return null;
}

function ciEvidence(lines) {
  let heading = '';
  let findings = 0;
  let withEvidence = 0;
  lines.forEach((line, i) => {
    if (HEADING_RE.test(line)) {
      heading = line.trim();
      return;
    }
    if (!CI_HEADINGS.includes(heading) || !ID_LINE_RE.test(line)) return;
    findings += 1;
    const next = lines.slice(i + 1).find((l) => l.trim() !== '');
    if (next !== undefined && next.trim().startsWith(EVIDENCE_PREFIX)) withEvidence += 1;
  });
  return { findings, withEvidence };
}

function declaredInputs(lines) {
  const declared = new Set();
  const start = lines.findIndex((line) => line.trim() === INPUTS_HEADING);
  if (start < 0) return declared;
  for (const line of lines.slice(start + 1)) {
    if (HEADING_RE.test(line)) break;
    const match = line.match(INPUT_LINE_RE);
    if (match) declared.add(match[1]);
  }
  return declared;
}

function description(file) {
  const meta = file.slice(0, -TRANSCRIPT_EXT.length) + META_EXT;
  try {
    const text = JSON.parse(fs.readFileSync(meta, 'utf8')).description;
    return typeof text === 'string' ? ' — ' + text : '';
  } catch (e) {
    return '';
  }
}

function main(argv) {
  if (argv.length !== 2) usage();
  const [dir, log] = argv;
  let names;
  let logText;
  try {
    names = fs.readdirSync(dir).filter((name) => name.endsWith(TRANSCRIPT_EXT)).sort();
    logText = fs.readFileSync(log, 'utf8');
  } catch (e) {
    usage(e.message);
  }
  const count = { transcripts: 0, other: 0, reports: 0, withInputs: 0, ci: 0, evidence: 0, secret: 0 };
  const perInput = {};
  INPUTS.forEach((input) => { perInput[input.name] = { valid: 0, expected: 0 }; });
  const noReport = [];
  for (const name of names) {
    const file = path.join(dir, name);
    const records = readRecords(file);
    const prompt = promptText(records);
    if (!prompt.includes(LENS_HEADING)) {
      count.other += 1;
      continue;
    }
    count.transcripts += 1;
    const body = reportBody(takenReport(records));
    if (body === null) {
      noReport.push(file);
      continue;
    }
    count.reports += 1;
    const expected = INPUTS.filter((input) => prompt.includes(input.needle)).map((input) => input.name);
    const declared = declaredInputs(body);
    expected.forEach((inputName) => {
      perInput[inputName].expected += 1;
      if (declared.has(inputName)) perInput[inputName].valid += 1;
    });
    if (expected.every((inputName) => declared.has(inputName))) count.withInputs += 1;
    const fields = ciEvidence(body);
    count.ci += fields.findings;
    count.evidence += fields.withEvidence;
    count.secret += body.filter((line) => SECRET_FORM_RE.test(line.trim())).length;
  }
  const rejected = logText
    .split('\n')
    .filter((line) => line.startsWith(DISPOSITION_PREFIX) && (line.includes(REJECTED_EVIDENCE) || line.includes(CRITICAL_NOTE)))
    .length;
  console.log(
    `reviewer-transcripts: ${count.transcripts}  other: ${count.other}  reports: ${count.reports}  ` +
    `with-inputs-read: ${count.withInputs}  ci-findings: ${count.ci}  with-evidence: ${count.evidence}  ` +
    `secret-form-lines: ${count.secret}  rejected-evidence-lines: ${rejected}`
  );
  console.log('per-input: ' + INPUTS.map((input) => `${input.name} ${perInput[input.name].valid}/${perInput[input.name].expected}`).join('  '));
  noReport.forEach((file) => console.log(`no report: ${file}${description(file)}`));
}

main(process.argv.slice(2));
```

Add to `CLAUDE.md`, in the fast-suite list of `## Testing`, directly after the `tests/measure-context/run-tests.sh` line:

```text
bash tests/count-report-fields/run-tests.sh  # tools/count-report-fields.js: reviewer report fields (evidence line, inputs read) of one review run
```

`CLAUDE.md` is git-ignored (`.gitignore:7`): this edit stays on disk and does not ship with the branch. When `CLAUDE.md` does not exist in the working folder (a fresh clone or a separate worktree), skip this edit, never create the file, and name the skipped edit in the task report.

- [ ] **Step 4: Run the suites to verify they pass**

Run: `bash tests/count-report-fields/run-tests.sh 2>&1 | grep -E '  FAIL: |Results'`
Expected: one line, `Results: 11 passed, 0 failed`.

Run: `bash tests/suite-guard/run-tests.sh 2>&1 | grep -E '  FAIL: |Results|found [0-9]+ suites|count-report-fields'`
Expected: no FAIL line; a PASS line names `tests/count-report-fields/run-tests.sh`, and a PASS line reads `… found 21 suites that must load the guard` (20 today, measured 2026-10-25, plus the new suite).

- [ ] **Step 5: Commit**

```bash
git add tools/count-report-fields.js tests/count-report-fields/run-tests.sh tests/count-report-fields/fixtures tests/suite-guard/run-tests.sh
git commit -m "feat(tools): count-report-fields.js measures evidence lines and inputs-read sections" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 8/9"
```

---

### Task 9: Guide and release 7.75.0

**Files:**
- Modify: `docs/guide/README.md` (lines 388-390)
- Modify: `VERSION`, `.claude-plugin/plugin.json` (line 4), `.claude-plugin/marketplace.json` (line 13), `plugin.universal.yaml` (line 7)
- Modify: `README.md` (line 6 badge; the two `v6.7.0–v7.74.1` ranges on lines 22 and 24)
- Modify: `RELEASE-NOTES.md` (new entry above `## v7.74.1`)

**Security flag:** `none`

**Does NOT cover:** hooks and `hooks/skill-rules.json` (Global Constraint 14); the acceptance run of spec section 9, which happens after reinstall and outside this plan; the guide's readiness sentence at line 301 (the *settled* rule is unchanged).

**Contract:**
- Version (code artifact): `7.75.0` in `VERSION`, both `.claude-plugin` files, the `plugin.universal.yaml` meta, the README badge and both lineage ranges; no `7.74.1` left in `VERSION`, `README.md`, the two `.claude-plugin` files and `plugin.universal.yaml` (other files, such as `RELEASE-NOTES.md` and this plan, keep their historical mentions). Verification: Step 2 grep.
- Release-notes entry (wording artifact): heading `## v7.75.0 — …` above `## v7.74.1`; the three-line summary (Problem / Change / Effect) near 100 words, 120 at most, each statement supported by the entry's prose; Effect states "Reinstall the plugin; nothing to migrate. Existing logs are read unchanged: the new line is optional and absent from them." Verification: Step 2 word count and a reading against the What changed list.
- Guide sentence (wording artifact): the clean-round sentence names the inputs-read condition and says it holds at M = 1. Verification: Step 2 grep.

- [ ] **Step 1: Edit the guide, the version files and the release notes**

`docs/guide/README.md` lines 388-390: replace `Critical/Important findings fixed between rounds and an early exit after two` / `consecutive clean rounds — with M > 1 a round is clean only when every` / `reviewer returned a usable report. In interactive SDD the gate asks you` with:

```text
Critical/Important findings fixed between rounds and an early exit after two
consecutive clean rounds — a round is clean only when every reviewer returned
a usable report and every report declares, in its `### Inputs read` section,
each file it was told to read as read `whole`; this holds also at M = 1. In
interactive SDD the gate asks you
```

Then run `grep -n -i 'clean\|PARTIAL' docs/guide/*.md` and update any other sentence that states the clean-round rule or the paging stop (none expected beyond line 389).

Version: replace `7.74.1` by `7.75.0` in `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` (meta `version`), the `README.md` badge (`version-7.74.1-white` → `version-7.75.0-white`) and both `v6.7.0–v7.74.1` ranges of `README.md` (→ `v6.7.0–v7.75.0`).

`RELEASE-NOTES.md`: insert above `## v7.74.1 — the update check reads the plugin registry of CLAUDE_CONFIG_DIR`:

```markdown
## v7.75.0 — reviewer reports carry an evidence line and an inputs-read section

**Problem.** A review controller could not see whether a reviewer had re-opened the line a finding cites, nor whether it had read its inputs to the end. The paging rule also ended on a full page, which carries no PARTIAL notice.

**Change.** Each Critical and Important finding carries an `evidence:` line copied from a fresh read; every report carries an `### Inputs read` section; a round is clean only when every expected input reads `whole`. Paging stops on a short or empty Read result.

**Effect.** Reinstall the plugin; nothing to migrate. Existing logs are read unchanged: the new line is optional and absent from them.

### What changed

- **Reviewer prompts** (`skills/multi-code-review/reviewer-prompt.md`, `skills/multi-doc-review/reviewer-prompt.md`). A byte-identical `**Evidence line.**` rule: directly below each Critical and Important finding, one line indented by two spaces, copied from a Read at the cited line (or `grep -nH`) in the checkout file, never in the diff file. Five forms: presence, gap, absence (`grep -n '<pattern>' <path> → no match`), secret (`<n> — secret-bearing line, not quoted`) and removed file. A byte-identical `**Inputs read.**` rule: every report, also a clean one, declares each input it was told to read whole as `- <input>: whole` or `- <input>: partial — not read: <ranges>`; `whole` is defined by coverage of lines 1 to the end. The code prompt's reference sentence now names the checkout, not the diff.
- **Controllers** (`skills/multi-code-review/SKILL.md`, `skills/multi-doc-review/SKILL.md`). Triage reads each Critical/Important finding's evidence line as text; an Important finding without a matching line may be `rejected: evidence (<reason>)` with one of five fixed reasons; a Critical one is never rejected on this ground and gets `(evidence: <reason>)` on its line. A round is *partial* also when a usable report does not declare every expected input `whole`; such a round is triaged normally, never clean, and never retried. A fix counts as reviewed only when a later round or cycle has a report whose `diff` line reads `whole`, or `partial` with every unread range annotated with diff paths the fix did not change. The log gains an `**Inputs read:**` line, written only when a declaration is not `whole`.
- **Paging rule**, in the two reviewer prompts, the task reviewer, the four orchestrating-development controller templates and the dashboard skill: "until a result returns fewer lines than its `limit`, or no line because the file is shorter than the offset"; a full page is not the end. Measured: a Read with `limit` 3 on a 1,994-line file returned 3 lines and no PARTIAL notice.
- **`tools/count-report-fields.js`** with the fast suite `tests/count-report-fields/run-tests.sh`: counts reviewer transcripts, marked reports, reports with a valid `### Inputs read` section, Critical/Important findings, findings with an evidence line, secret-form lines and evidence rejections in a session's `subagents/` folder. It also follows a dispatch by pointer to the reviewer's prompt file.
- **Tests.** `tests/reviewer-templates/run-tests.sh` sections 29-33 pin the new wording; test 19 and `tests/orchestrating-development/run-tests.sh` test 5c pin the new stop clause and check that the old clause is gone from every Markdown file under `skills/`.

### Left as is

- **The single-pass review templates** (`skills/requesting-code-review/code-reviewer.md`, `agents/code-reviewer.md`, `agents/red-team.md`) and the evidence line and declaration for the task reviewer: a later change.
- **The fix dispatch and `fix-prompt.md`**: the evidence line is never passed to the fix subagent and never copied into the log.
- **The readiness *settled* rule**: unchanged until the acceptance measure shows how often reviewers obey the declaration.
- **Other paging sentences in other words** (`skills/token-efficiency/SKILL.md` rule 6, `skills/pickup/SKILL.md`, `skills/orchestrating-development/SKILL.md`, `skills/subagent-driven-development/SKILL.md`, `skills/multi-code-review/SKILL.md` failure-text cap): they do not carry the changed stop clause.
```

- [ ] **Step 2: Verify**

Run: `grep -rn '7\.74\.1' VERSION README.md .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml`
Expected: no output.

Run: `grep -c '7\.75\.0' README.md`
Expected: `3`.

Run: `awk '/^## v7.75.0/{on=1;next} on && /^### What changed/{exit} on' RELEASE-NOTES.md | wc -w`
Expected: a number ≤ 120 (the three labelled lines; 105 words as written here).

Run: `grep -n 'Inputs read' docs/guide/README.md`
Expected: one hit near line 390.

Run every fast suite: `for s in codex/run-unit-tests.sh smart-compress/run-tests.sh reviewer-templates/run-tests.sh writing-plans/run-tests.sh in-run-rulings/run-tests.sh fill-prompt/run-tests.sh orchestrating-development/run-tests.sh review-gates/run-tests.sh measure-context/run-tests.sh pickup/run-tests.sh analyze-compaction/run-tests.sh sdd-scripts/run-tests.sh suite-guard/run-tests.sh worklog/run-tests.sh dashboard/run-tests.sh finishing-branch/run-tests.sh using-git-worktrees/run-tests.sh skill-test-runner/run-tests.sh find-polluter/run-tests.sh verification-before-completion/run-tests.sh context-management/run-tests.sh count-report-fields/run-tests.sh; do bash "tests/$s" >/dev/null 2>&1 && echo "ok $s" || echo "FAILED $s"; done`
Expected: 22 lines, each starting `ok` (the codex unit tests and the 21 guarded suites).

- [ ] **Step 3: Commit**

```bash
git add docs/guide/README.md VERSION README.md .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml RELEASE-NOTES.md
git commit -m "chore(release): v7.75.0 — reviewer evidence line and inputs-read section" --trailer "Session: reviewer-evidence-and-inputs-read" --trailer "Stage: task 9/9"
```
