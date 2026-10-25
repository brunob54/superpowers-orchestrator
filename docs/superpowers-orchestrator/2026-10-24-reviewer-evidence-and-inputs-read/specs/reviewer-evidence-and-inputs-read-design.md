# Reviewer evidence line and inputs-read declaration — design

**Date:** 2026-10-24
**Status:** design approved by the user on 2026-10-24 (approach B of three presented)
**Release:** 7.75.0 (new behaviour in two skills; not a patch release)
**Repository state the line numbers refer to:** commit e9cadaf0 (main, 2026-10-24)

## 1. Problem

The review loops of this plugin (`multi-code-review` for a branch,
`multi-doc-review` for a spec or a plan) dispatch reviewer subagents whose
report is consumed by a controller. The controller is the subagent that runs
the loop: it reads each report, decides what to do with each finding (the
*triage*), writes the decision to the sidecar audit log, and decides whether a
round is *clean* (zero Critical and zero Important findings in the
consolidated set, and all M reviewers returned a usable report). Two
consecutive clean rounds end the loop early.

Two things are invisible to the controller today:

1. **Whether a finding's claim was checked against the file.** A reviewer
   must give a `file:line` (code) or a document section (doc), but nothing
   makes it re-open that line before reporting. Measured on this
   repository's 63 review logs (3,948 disposition lines): 26 rejections were
   for a wrong reviewer finding (0.66 %), of which about 6 claimed a wrong
   line number or claimed text was absent when it was present. One false
   claim about the harness cost a full stop of an autonomous run (release
   v7.6.0). A wrong Critical or Important finding goes to the fix subagent
   as it is: the fix subagent has no rule to refuse a finding on its merits.
2. **Whether the reviewer read its inputs to the end.** The Read tool returns
   about 25,000 tokens per call and then a notice `PARTIAL view — <path>:
   showing lines A-B of T total`. The reviewer prompts order paging to the
   end and "Never act from a first page or a preview alone", but the report
   has no field for it, so a reviewer that stopped early is silent. Measured:
   22 partial Read views by reviewers, all paged to the end; one reviewer
   skipped diff lines 547 to 864 on purpose, and whether it said so is not
   recorded. A silent partial read cannot be measured from the logs at all,
   because reports are not stored; "0 found" is therefore weak evidence.
   Median plan length is 1,273 lines and a diff read was cut at about line
   548 of 1,869, so paging is the normal case, not the exception.

This design adds two fields to the reviewer report and the rules that consume
them. It follows an analysis (three independent reviews of seven proposed
rules) that rejected a same-context "reread your report" rule: the study the
analysis cited (Huang et al., "Large Language Models Cannot Self-Correct
Reasoning Yet", ICLR 2024) found no gain, and the pipeline
already provides independent second looks through M reviewers and N rounds.

## 2. Scope and non-goals

**In scope**

- `skills/multi-code-review/reviewer-prompt.md` and
  `skills/multi-doc-review/reviewer-prompt.md`: the report format, two new
  reviewer rules, and the stop clause of the paging rule (section 5.3).
- The same paging-rule stop clause in the five other files that carry the
  sentence `until a result carries no PARTIAL notice` (seven carriers in
  all): `skills/subagent-driven-development/task-reviewer-prompt.md` (line
  76) and the four controller templates of orchestrating-development —
  `doc-review-loop-prompt.md` (62), `code-review-loop-prompt.md` (77),
  `batch-controller-prompt.md` (90), `plan-writer-prompt.md` (52) — together
  with both test needles named `PAGE_UNTIL_NO_PARTIAL`:
  `tests/reviewer-templates/run-tests.sh` line 45 (test 19, whose
  `PAGING_TEMPLATES` holds the two reviewer prompts and the task-reviewer
  prompt) and `tests/orchestrating-development/run-tests.sh` line 97
  (asserted at line 499 for every controller template). The plan greps the
  repository for the sentence once more before editing, so that no carrier
  is missed.
- `skills/multi-code-review/SKILL.md` and `skills/multi-doc-review/SKILL.md`:
  one triage rule, the widened *partial round* term at every site that
  defines it, the "no fix ships unreviewed" rule (code skill), one audit-log
  line.
- `tests/reviewer-templates/run-tests.sh`: contract tests for the new
  wording.
- `tools/count-report-fields.js` and a fast test suite for it: the
  acceptance measure (section 9).
- Release work: version files, `RELEASE-NOTES.md`, `docs/guide/`.

**Non-goals** (each with its reason)

- The three single-pass review templates
  (`skills/requesting-code-review/code-reviewer.md`,
  `agents/code-reviewer.md`, `agents/red-team.md`). No round gate consumes
  their report; the user chose to leave them for a later change.
- `skills/subagent-driven-development/task-reviewer-prompt.md`, the
  per-task reviewer of subagent-driven development. Its report feeds one
  per-task gate ("Spec ✅ and quality approved?"), not a round loop; in this
  release it receives only the paging-rule stop clause. The evidence line
  and the inputs-read declaration for it belong to the later change above.
- `skills/multi-code-review/fix-prompt.md` and the content of the fix
  dispatch. The fix subagent keeps receiving id, severity, location and
  description; the evidence line is not passed (section 5.2).
- A self-rated confidence scale on findings. Rejected in the analysis: the
  faculty that would rate confidence is the one that wrote false statements
  into every release note that was fact-checked; the evidence line is an
  objective substitute.
- Recording `whole` reads in the audit log. Only exceptions are logged, so
  a normal round's log entry stays byte-identical to today (section 5.4).
- The *settled* rule of the readiness passes of `multi-doc-review`
  (`Execution readiness` lens). It is not changed by the inputs-read state in
  this release: a readiness sequence runs at most three passes and a pass
  that is not settled costs M more reviewers, so an imperfectly obeyed
  declaration would cost two extra passes per plan. Revisit after the
  acceptance measure (section 9) shows the obedience rate. Readiness
  reviewers still produce the new fields, since they use the same prompt,
  and a readiness entry records them (section 5.4, entry kinds).
- The clean-round rule in the orchestrating-development controller
  templates (`skills/orchestrating-development/code-review-loop-prompt.md`,
  `doc-review-loop-prompt.md`, `batch-controller-prompt.md`,
  `plan-writer-prompt.md`). They summarize recorded rounds and do not
  restate the clean-round rule; the plan verifies this with a grep and
  changes that text only if the grep proves otherwise. Their paging-rule
  stop clause does change (in scope above): a controller pages its own
  skill body, the plan and the spec with the same sentence.
- Any change to the retry rule or to what makes a report usable
  (section 7).

No decision in this design matched the prior-art trigger predicate.

## 3. Decisions already taken

| Decision | Choice | Made by |
|---|---|---|
| Which prompts change | The two multi-review reviewer prompts and their controllers | User |
| A report without an `### Inputs read` section | Treated as *not declared*: the report is usable, its findings are triaged, the round is never clean | User |
| Evidence line passed to the fix subagent | No; the fix dispatch is unchanged | Design |
| A Critical/Important finding without an evidence line | Triaged normally at its stated severity; the controller may reject it with a logged reason (the shape of the code skill's existing "finding without a file:line" rule) | Design |
| Name of the new report section | `### Inputs read` — `Coverage` is taken by the readiness lens's `coverage: GC<k> — <n> sites checked` block | Design |
| Source of a code finding's evidence line | The checkout file at the finding's path, never the diff file (its line numbers differ) | Design, round 1 |
| A fix reviewed by a report whose `diff` line is `partial` | Does not count as reviewed — unless every unread range names diff paths the fix commit did not change; the existing verification re-review and its 3-cycle cap apply; the rule reads the `diff` line only | Design, rounds 1 and 4 |
| `rejected: evidence (<reason>)` on a Critical finding | Never; a Critical is triaged normally and the mismatch is noted on its disposition line | Design, round 4 |
| Acceptance measure | A committed script under `tools/`, not a scratch script | User |

## 4. Terms

- **Id line**: a finding's line in the report, `- [C1] <location> — <what is
  wrong> | <why it matters> | <suggested fix>`. The controller enumerates
  findings from id lines and never from the count line.
- **Consolidated set**: the union of all usable reports' findings of a round,
  after duplicates across reviewers are merged. With M ≥ 2 a consolidated
  finding has one to M *source* findings, each with its own evidence line.
- **Partial round** (existing term): a round where fewer than M reviewers
  returned a usable report (u < M). It is never clean. This design widens the
  term (section 5.4).
- **Prompt-named input**: a file the reviewer prompt tells the reviewer to
  read whole. Code reviewer: the diff file ("Read the diff file whole, with
  the Read tool"), and the plan file **exactly when the prompt contains the
  sentence beginning `Plan/requirements the branch implements (read it
  first):`**. The controller fills `[PLAN_LINE]` with that path-bearing
  sentence on a lens-1 round that has a plan, with the sentence `No
  requirements document is available — review correctness only …` on a
  lens-1 round without one, and with nothing on other rounds (code skill
  lines 574-580; code prompt lines 276-281); only the path-bearing sentence
  names an input. The paging rule applies to "every file this prompt tells
  you to read", and lens 1 needs the whole plan to find missing
  requirements. Doc reviewer: the target document ("Document (read it whole,
  with the Read tool)"), and the spec **exactly when the filled lens
  instructions contain the words `read the spec listed under Target`** —
  plan lens 1 ("spec-coverage gaps — spec requirements with no implementing
  task (read the spec listed under Target)", doc skill lines 750-751) and
  the readiness cell (lines 824-826); in every other pass the spec is "you
  may read it" and not an input. The **expected set** of inputs is therefore
  known to the controller from the prompt it filled: `diff`, plus `plan`
  when it filled the path-bearing sentence; `document`, plus `spec` when the
  lens text it pasted carries that sentence. A declaration line for an input
  outside the expected set (`- plan:` in any other code round, `- spec:` in a
  doc pass whose lens text does not name it) is ignored for the clean-round
  rule and for the log.
- **Entry kinds built from the round-entry rules**: rotating round entries;
  in the code skill, verification cycles (`## Round <i> verification <c>`)
  and addendum re-reviews (`## Round <i> addendum <n> re-review <c>`); in the
  doc skill, readiness passes (`## Readiness <pre|post> <p>`). All are
  written "with the same fields as a round"; none of the last three carries
  a `**Converged:**` line.

## 5. Design

### 5.1 Evidence line — reviewer rule

Two additions to each reviewer prompt, both inside its `## Output format`
section:

- **In the format example:** one `evidence:` line under the `- [C1]` example
  line (item 9 below).
- **A rule paragraph, identical in both prompts**, placed directly after the
  paragraph that defines the `harness:` field (the paragraph ending "carry
  no `harness:` field." in the doc prompt and "also listed under Checks Run."
  in the code prompt): before `**Where the report goes.**` in the code
  prompt, and before the closing fence of the prompt block in the doc
  prompt. This position lies between two pinned fragments and inside no
  pinned span (section 8, item 2). The paragraph must not use the phrase
  "in this checkout" (pinned to exactly two occurrences per prompt).

The two prompts' pinned spans (the Harness claims span, the folded
shared-checkout and Tests spans, the doc prompt's Subagent Rules bullets)
are not touched; the paging rule changes in its stop clause only (section
5.3), together with its test needle.

The paragraph starts with the bold lead-in `**Evidence line.**`, a stable
anchor for the contract test (section 8, item 4). Every element that applies
to one prompt only is written as a labelled branch — "for a code finding, …;
for a document finding, …" — so the identical text reads correctly in both
prompts (the doc reviewer has no diff file and no Checks Run section).

Normative content of the rule (the plan carries the exact wording; the
wording must keep every element below and must name the verb and the
output):

1. Directly below each **Critical** and each **Important** id line, the
   reviewer writes one line, indented by two spaces, starting with
   `evidence: `. A finding that carries a `harness:` field (a harness claim)
   needs no evidence line: its premise is a runtime property, not a line of
   any file, and the harness procedure settles it first.
2. **Which file the line comes from.** For a code finding: the file at the
   finding's path in the checkout, opened at `[REPO_ROOT]/<path>` — the
   repository root named at the top of the prompt, never a path relative to
   the shell's working directory, which is reset between Bash calls and may
   be another checkout when the branch under review lives in a worktree —
   and read at the cited line (the Read tool with `offset` set to that line
   and a `limit` of 1, or `grep -nH`), never the diff file — the diff file's
   line numbers are its own, not the source file's. Opening the finding's own file at its cited line is part
   of writing the finding: it is not a check outside the diff and is not
   listed under Checks Run. The `file:line` of a code finding is a path and
   a line of the checkout, never of the diff file; when the evidence read
   shows the defect at another line, the reviewer corrects the location
   before it reports. For a doc finding: the target document.
3. **Presence form.** The line the finding is about, copied from the tool
   output: as the Read tool returned it (line number, a tab, the text —
   leading spaces before the number dropped) or as `grep -nH` returned it
   (`<path>:<line>:<text>`; `-H` prints the path also for a single file —
   plain `grep -n` with one file prints `<line>:<text>` without the path, in
   GNU grep, BSD grep and ugrep alike). When the finding's location is a line, the
   evidence line's number is that line; when the location is a range
   `<path>:<a>-<b>`, the number lies inside the range; when the location is
   a document section, the quoted line lies in that section.
4. **Gap form.** When the finding states that existing text is incomplete
   (a case not covered, an error path not specified, a rule that does not
   say what happens when …): the governing line — the sentence, table row
   or list entry where the missing case belongs — in the presence form.
   This is the usual form for a document review.
5. **Absence form.** When the finding states that something is missing
   entirely and no governing line exists: the search that found nothing, as
   `evidence: grep -n '<pattern>' <path> → no match`, with the pattern that
   describes the missing thing. This form also covers a line the branch
   removed from a file that still exists (a deleted null check, a dropped
   assertion): the pattern is the removed text, searched in the checkout
   file; the gap form with the enclosing line is the alternative.
6. **Secret form.** When the line holds a credential or other secret:
   `evidence: <line number> — secret-bearing line, not quoted`. This clause
   lives inside the byte-identical paragraph in both prompts; the doc prompt
   gets no new Subagent Rules bullet (its bullets are a pinned span), and
   the code prompt's existing secret-bearing rule stays the general rule.
7. **Removed-file form.** When the finding's path is not in the checkout at
   HEAD (a file the branch deletes or renames), `evidence: <path> — not in
   the checkout at HEAD`; the diff file is still not quoted.
8. A quoted line whose text after the prefix is longer than 200 characters
   is cut to one window of at most 200 characters of that text that
   contains the defect; each cut end is marked with `…` (the prefix and the
   marks do not count toward the 200). The line is one line, never wrapped.
   A Minor finding gets no evidence line from the reviewer; the controller
   ignores one if present.
9. Example in the format block (code prompt; the doc prompt's example uses
   a document line):

   ```
   #### Critical
   - [C1] src/retry.js:40 — <what is wrong> | <why it matters> | <suggested fix>
     evidence: 40<tab>  return attempts > max ? null : retry(fn)
   ```

   The example renders the tab as the visible token `<tab>`, and the rule
   paragraph says so; a real evidence line holds the tab the Read tool
   printed. The prompt files therefore stay free of literal tab characters,
   which an editor's tab expansion would turn into spaces silently and
   which neither `.gitattributes` nor a test protects.

Why this shape: the indentation and the `evidence:` prefix keep the line out
of the controller's enumeration, which counts `- [X<n>]` items; the tool
prefix (a line number or `<path>:<line>`) guarantees that a quoted document
line beginning with `- [C1]` can never be read as a finding. Pasting tool
output is the step that forces the reviewer to re-open the exact line before
it reports; that is where the verification happens, independent of what the
controller does with the line.

The prompt's **Reviewer returns** list (code prompt, lines 292-299; doc
prompt, lines 181-182) names the evidence line and the `### Inputs read`
section as parts of the report.

### 5.2 Evidence line — controller rule

In both `SKILL.md` files, in the triage step, next to the existing rules
for Critical/Important findings (code skill: the sentence "A finding without
a file:line reference is triaged normally …", lines 961-965; doc skill: the
sentence "Every Critical/Important finding is either applied to the document
or `rejected: <reason>`", lines 553-558). Normative content:

1. Before choosing the disposition of a Critical or Important finding, the
   controller reads the finding's evidence line against the finding's claim.
   This is a text comparison inside the report; the controller opens no file
   for it. With M ≥ 2 the consolidated finding has one evidence line per
   source finding; the controller reads them in the source reports (the
   consolidation copies no evidence line) and the finding *matches* when at
   least one source's line matches.
2. An evidence line *matches* when: for a line location, its line number
   equals the finding's line (lies inside the range, for a range location);
   and, in every form, the quoted text shows the defect the finding names —
   in the gap form, it is the text the finding says is incomplete; in the
   absence form, the pattern describes the thing the finding says is
   missing; in the secret form, the line matches on its line number alone;
   in the removed-file form, on its path alone. Whether a quoted line lies
   in the named section of a document
   is a reviewer rule (5.1, item 3), not part of this check: the report
   alone cannot show it.
3. A finding whose evidence line is missing in every source, or matches in
   no source, is **triaged normally at its stated severity**. For an
   **Important** finding the controller **may** instead reject it with
   `rejected: evidence (<reason>)`, where `<reason>` is one of five fixed
   phrases: `missing`, `line differs`, `text does not show the defect`,
   `pattern does not describe the missing thing`, or `input partial`. The
   last applies to a gap-form or absence-form finding whose own report
   declares the input the finding concerns `partial` or not declared: the
   governing line or the empty search proves nothing about text the
   reviewer did not read, and the report itself says what was skipped —
   this is where the two new fields meet at triage. A **Critical** finding
   is never rejected under this rule, as the code skill already says of its
   plan rule ("a Critical is never rejected under this rule"): the
   controller triages it normally and places `(evidence: <reason>)` directly
   after the finding summary — the position of the existing
   `(plan-mandated)` tag, before any `— at` location clause, `— harness
   probe:` clause or ` ← ` annotation, so the line-order rules of the code
   skill's "Self-sufficient open-item lines" are untouched — so the
   mismatch is recorded without dropping the finding — a rejected finding is no open
   item in an orchestrated run, and its lens returns only after four
   rounds. The parentheses keep the disposition's own ` — <finding summary>`
   separator unambiguous; the sentence that adds this rule to each skill
   also states that the parenthesis holds one of the five phrases and
   nothing else, so no quoted text enters a disposition line through it.
4. The evidence line is **never copied into the audit log**: the
   orchestrator reads the last `- [id]` line of an invocation as its open
   item, and the fix prompt requires one finding per line in the findings
   file. The log records only the disposition, as today.

Unchanged: the fix dispatch content (id, severity, location, description),
the fix prompt, the harness-claim procedure (a `harness:` field and an
evidence line can both be present; the harness procedure runs first, as
today).

### 5.3 Inputs read — reviewer rule

A new section `### Inputs read` in both report formats.

- **Written in every report**, including a report whose verdict is exactly
  "No material issues under this lens." and that has no `### Findings`
  section — the clean report is the case where the declaration decides the
  outcome.
- **Position.** Below the `### Findings` section when the report has one,
  below `### Verdict` otherwise; in the code prompt before `### Checks Run`.
  For the readiness lens of the doc skill, whose instruction adds a
  `coverage: GC<k> — <n> sites checked` block "as the last lines of your
  report, below the `### Findings` section", that block stays last: it
  follows `### Inputs read`. The readiness instruction text is not changed.
- **Content.** One line per prompt-named input (section 4), in this fixed
  grammar and no other words:

  ```
  ### Inputs read
  - diff: whole
  - plan: partial — not read: 735-end
  ```

  The code report carries `- diff:` always and `- plan:` exactly when the
  prompt contains the sentence beginning `Plan/requirements the branch
  implements (read it first):`; the doc report carries `- document:` always
  and `- spec:` exactly when the lens text contains `read the spec listed
  under Target` (section 4). A `whole` line ends after the word `whole`:
  a line that continues (`- diff: whole (4 pages)`) is outside the grammar
  and makes that input *not declared*, for the controller and for the
  acceptance script alike; the prompt's example states this. Line numbers
  in this section are the Read tool's, as its line prefixes and notices
  print them.
- **`whole`** is defined by coverage, not by the absence of a notice: the
  reviewer's Read calls of that input together returned every line from 1
  to the end of the file. The end of the file is the total `T` that a
  PARTIAL notice names, or the last line of a Read result that reached the
  end — a result that returned fewer lines than its `limit`, or that had no
  `limit` and carried no PARTIAL notice. A Read with an explicit `limit`
  that returns exactly `limit` lines carries no notice and proves nothing
  about the lines after it; to prove the end after such a page, the
  reviewer reads once more at the offset after the last received line, and
  a result with no line (the tool answers that the file is shorter than the
  offset and names its total line count) proves the end. The Read tool's
  total counts one empty line after the file's final newline
  (`tools/measure-context.js` lines 55-58), so it is one more than `wc -l`;
  a range that covers only that position after the final newline is not a
  missing range.
- **Every other case is `partial`**, including zero Read calls of the
  input, which is written `partial — not read: 1-end`. `partial — not read:
  <ranges>` names the file line numbers the reviewer did not read, separated
  by a comma and one space (`547-864, 1200-end`), each `<a>-<b>`; `<a>-end`
  when the end of the file is unknown; `unknown` when the reviewer cannot name the
  ranges (it read the input only from a shell preview or from Bash output,
  which carry no line numbers). The numbers come from the Read tool's own
  notice, from the offsets the reviewer used, or from a skip the reviewer
  chose; a skip chosen on purpose is a partial read. An unread range of the
  diff may carry, in parentheses, the diff paths it covers, when the range
  starts at a `diff --git` header and ends before the next one:
  `not read: 547-864 (package-lock.json)`. This is the only annotation
  allowed; it lets a skipped generated file (a lock file, a snapshot) leave
  the fix-reviewed rule of 5.4 intact, and it never makes a round clean. A
  hunk the Subagent Rules order the reviewer to SKIP (the sidecar patterns,
  code prompt lines 40-45) is not an unread range.
- **The no-package fallback** of the code prompt (`[PACKAGE_FILE]` =
  `none — fetch the diff yourself`) delivers the diff through Bash output,
  which is cut at 30,000 characters. A reviewer on that path redirects the
  diff command's output to a path `mktemp` printed (a shell redirection,
  not the Write tool, which the prompt reserves for the report file) — on
  Windows Git Bash converted once with `cygpath -m`, by the same sentence
  the prompt already uses for the report file, because the Read tool does
  not resolve a `/tmp/…` path there either — and reads that file with the
  Read tool; a reviewer that read the diff only from Bash output writes
  `- diff: partial — not read: unknown`.
- **The paging rule's stop clause changes.** The rule in both prompts (code
  prompt lines 143-155, doc prompt lines 99-111) ends "Read again with the
  offset and the limit the notice names, halving the limit when a call is
  refused for size, until a result carries no PARTIAL notice." A Read that
  fills its `limit` carries no notice, so on an input of three or more pages
  the second page — read with the notice's `limit` — stops a reviewer that
  obeys the clause before the end, and a false `whole` becomes systematic
  on every long input. The clause becomes: "… until a result returns fewer
  lines than its `limit`, or no line because the file is shorter than the
  offset (the tool then names the file's total line count); a result that
  fills its `limit` is not the end, even when it carries no PARTIAL notice,
  and a call refused for size returns no line either and is never the end —
  halve the limit and read again." A refusal for size delivers no line and
  no notice (observed on `RELEASE-NOTES.md` with `limit` 2500 and 3000), so
  a clause that said only "or no line at all" would name a refusal as the
  end. The fragment `halving the limit when a call is refused for size`
  stays intact (needle `HALVE_ON_REFUSAL`, pinned in both suites). The same
  clause changes in all seven carriers (section 2), and both
  `PAGE_UNTIL_NO_PARTIAL` needles change with it, in the same release.
- The section is fixed text, so it cannot become hedging prose ("I may have
  missed something" is not a value).

### 5.4 Inputs read — controller rules

**Convergence** (code skill step 6, lines 1078-1096; doc skill step 5,
lines 573-584). A round is *clean* only when, in addition to the existing
conditions (the consolidated set enumerates zero Critical and zero
Important; u = M), **every usable report's `### Inputs read` section
carries, for every input of the expected set (section 4), a line that reads
`whole`**. The partial-round condition is the exact complement: a round
where, in any usable report, an expected input is declared `partial`, or its
line is missing or outside the grammar (*input not declared*), or the whole
section is missing (*not declared*), is a **partial round**: its findings
are consolidated and triaged normally, the round is never clean, and it
breaks the streak. This widens the existing term "partial round" (today:
u < M) instead of adding a second concept.

**Every site that defines the term is updated**, so the skills carry one
definition: code skill lines 691 ("a round with u < M is *partial*"), 1078-
1081 (the convergence step), 1202-1211 (the verification-cycle parenthetical
"(1 ≤ u < M)"), the Error Handling bullets at lines 1755-1756 and 1788-1789;
doc skill lines 436 ("a round with u < M is *partial*"), 573-584 (the
convergence step) and 1043. The plan greps both files for `partial` and
`u < M` and lists every hit it changes or leaves, with the reason. Two
further sentences are qualified, not widened: the format promise "the round
entry that follows it (M = 1) is byte-identical to earlier releases" (code
skill lines 1292-1293; doc skill line 855) gains "when every usable report
declares every input `whole`"; and the code prompt's sentence "Every finding
must carry a file:line reference into the diff" (line 213, pinned by no
suite) becomes "a file:line reference — the path and line of the changed
code in the checkout", so it no longer contradicts 5.1 item 2.

Lines 1202-1212 of the code skill are **rewritten, not only widened**.
Their sentences — "A partial round or cycle satisfies 'a later round with a
usable report ran on the updated branch': the fixes it examined count as
reviewed", "A partial verification cycle after which no unreviewed fix
remains … ends the verification", and "'Never clean' concerns only the
convergence streak; it never reopens a verification — so a cap exit after a
partial round ships no unreviewed fix" — are true for the u < M cause and
false for the inputs-read cause. Rule for both skills: every sentence that
attaches a consequence to "partial" names its cause (u < M, or inputs
read), and the "No fix ships unreviewed" paragraph below is the authority
for the inputs-read cause. The replacement for the first sentence reads: "a
round or cycle with at least one usable report whose `diff` line reads
`whole`, or `partial` with every unread range naming diff paths the fix
commit did not change, satisfies 'a later round with a usable report ran on
the updated branch'; the fixes it examined count as reviewed"; the other
two sentences are restated under the same condition.

**No fix ships unreviewed** (code skill, lines 1099-1105 and 1202-1212). A
fix lands in the diff, never in the plan, so this rule reads the `diff`
line only — the clean-round rule above reads every expected input, and a
lens-1 verification cycle (which reuses the originating round's lens and so
carries the plan sentence) must not count a fix as unreviewed because the
plan was paged partly. A fix counts as *reviewed* only when a later round
or verification cycle ran on the updated branch with **at least one usable
report whose `diff` line reads `whole`, or reads `partial` with every unread
range annotated with the diff paths it covers, none of which the fix commit
changed** (the controller lists the fix commit's paths with `git show --stat
--format= <sha>`, one cheap command; an unannotated range, or one naming a
changed path, fails the test). A usable report whose `diff` line is
`partial` without such annotations, or not declared, has, by its own
statement, not examined the whole diff. Consequences, inside the existing
rules: a round with no such report leaves the fixes it was meant to review
unreviewed, so the existing verification re-review is dispatched before
exit; a verification cycle in that state counts toward the 3-cycle cap and
does not end the verification; a cycle with one such report ends it as
today. When the cap is reached this way, the fix ships as the cap already
allows, and the log shows the declarations (accepted limit, section 11).
The addendum re-review (code skill lines 1540-1564: re-review 1, at most
one more fix and re-review 2, then `unresolved: addendum re-review`)
follows the same test for what counts as examined: a re-review that leaves
no Critical or Important standing but has no such report is followed by
re-review 2 when the bound allows; when the bound is spent, the addendum
ends and the fix stands, with the declarations in the log — never a new
`unresolved:` item, which would turn a reviewer's declaration into a human
moment (accepted limit, section 11).

**Usability and retry are unchanged.** A report with a `partial`
declaration, or without the section, is usable. No retry is ever made for
these fields.

**Audit log** (Review Log Format of both skills). One new line, written
**only** when at least one usable report declares an input `partial` or is
not declared, placed directly after the `**Reviewer verdict:**` line, which
every entry kind has (the `**Converged:**` line exists in rotating round
entries only):

```
**Inputs read:** r1: plan partial — not read: 735-end | r2: diff partial — not read: 549-1869; plan not declared | r3: not declared
```

Three entry shapes: `<input> partial — not read: <ranges>` for a partial
input, `<input> not declared` for an expected input whose line is missing
or outside the grammar, and the bare `not declared` for a report without the
section. One entry per affected usable reviewer, in reviewer order,
separated by ` | `; a reviewer with several affected inputs lists them in
one entry separated by `; `; `r<j>` numbering as on the `**Reviewer
verdicts:**` line; with M = 1 the single entry is `r1: …`. Unusable
reviewers are not listed (they appear on the `**Reviewer verdicts:**` line
only). A line that declares `partial` without ranges is written `partial —
not read: unknown`.
A round whose usable reports all declare `whole` writes nothing new, so an
M = 1 round entry stays byte-identical to earlier releases, as the format
promises.

**Entry kinds.** The `**Inputs read:**` line is written, under the rule
above, in every entry kind built from the round-entry rules (section 4):
rotating rounds, verification cycles, addendum re-reviews and readiness
passes. The outcome rule of each kind is: rotating round — the widened
clean-round rule above; verification cycle and addendum re-review — the
"no fix ships unreviewed" rule above; readiness pass — the *settled* rule,
unchanged (section 2), so a settled pass may carry an `**Inputs read:**`
line and that is not a contradiction: the line is a record, the result is
computed as today.

The clean-round disposition line of a **rotating round** gains the cause
when the consolidated set is empty and the round is partial for this
reason: `- none — no material issues under this lens (partial round, inputs
read)`; with both causes: `(partial round, usable <u>/<m>, inputs read)`.
The existing form `(partial round, usable <u>/<m>)` is unchanged when only
u < M applies, in every entry kind that writes it today. No other entry kind
writes the `inputs read` cause.

### 5.5 What stays unchanged, stated explicitly

- Report usability: marker line within the first 10 non-blank lines plus a
  Verdict block (both skills); the readiness `coverage:` condition.
- Consolidation: enumeration from id lines; severity from the heading;
  `, counts recomputed` and `, ids renumbered` suffixes; no evidence line is
  copied into a consolidated finding.
- Triage dispositions and their syntax, except the new `rejected: evidence
  (<reason>)` reason text, which is an ordinary `rejected: <reason>`.
- Fix dispatch, fix prompt, the 3-cycle verification cap, the addendum
  re-review procedure apart from the rule in 5.4.
- The `**Reviewers:**`, `**Reviewer verdicts:**`, `**Sources mapped:**`
  lines; the ` ← a/m` annotation; the behavioural log greps in
  `tests/claude-code/test-helpers.sh` (lines 488, 496, 508, 517-518, 524)
  keep matching.
- No Node script under `skills/`, `hooks/` or `tools/` parses the report or
  the review log (verified 2026-10-24: `skills/pickup/scripts/*.js` and
  `skills/dashboard/scripts/*.js` read orchestration logs only; `hooks/*.js`
  and `tools/*.js` have no match for the report or log line names). The
  only parser of log lines is the behavioural test helper named in the
  previous bullet.

## 6. Interfaces and contracts

| Field | Writer | Reader | Grammar |
|---|---|---|---|
| Evidence line | Reviewer | Controller (triage, text-only) | `  evidence: <n><tab><text>` (Read of the finding's file, leading spaces dropped) or `  evidence: <path>:<n>:<text>` (`grep -nH`) — presence and gap forms; `  evidence: grep -n '<pattern>' <path> → no match` — absence form; `  evidence: <n> — secret-bearing line, not quoted` — secret form; `  evidence: <path> — not in the checkout at HEAD` — removed-file form; one line; under each C/I id line; none under a Minor finding |
| `### Inputs read` | Reviewer | Controller (convergence, fix-reviewed rule) | heading, then one line per input of the expected set: `- <input>: whole` (nothing after `whole`) or `- <input>: partial — not read: <ranges>`; `<input>` is `diff` (code, always), `plan` (code, when the prompt contains the `Plan/requirements the branch implements (read it first):` sentence), `document` (doc, always) or `spec` (doc, when the lens text contains `read the spec listed under Target`); `<ranges>` is `<a>-<b>` or `<a>-end`, each optionally followed by ` (<diff paths>)`, separated by `, `, or `unknown`; an unread input is `1-end` |
| `rejected: evidence (<reason>)` | Controller | Log readers, Phase 5 report (as any rejection) | an ordinary `rejected: <reason>` disposition, Important findings only; `<reason>` is one of `missing`, `line differs`, `text does not show the defect`, `pattern does not describe the missing thing`, `input partial` |
| `(evidence: <reason>)` | Controller | Log readers | note placed directly after a Critical finding's summary on its disposition line (the position of the `(plan-mandated)` tag), before any `— at` clause, `— harness probe:` clause or ` ← ` annotation; same five reasons |
| `**Inputs read:** …` log line | Controller | Log readers | `**Inputs read:** r<j>: <entry>[; <entry>] \| r<k>: not declared`, where `<entry>` is `<input> partial — not read: <ranges>` or `<input> not declared`, and the bare `not declared` stands for a report without the section; after `**Reviewer verdict:**`; written only when needed; in every entry kind |
| `(partial round, inputs read)` | Controller | Log readers | parenthetical on the `- none —` clean-round line of a rotating round |

## 7. Error handling

| Situation | Behaviour |
|---|---|
| Important finding without an evidence line in any source, or matching in none | Triaged normally; controller may reject with `rejected: evidence (<reason>)` |
| Critical finding without an evidence line, or matching in none | Triaged normally, never rejected on this ground; `(evidence: <reason>)` appended to its disposition line |
| C/I finding carrying a `harness:` field | No evidence line expected; the harness procedure applies |
| `- <input>: whole` followed by anything | Outside the grammar: that input is *not declared* |
| Evidence line under a Minor finding | Ignored by the controller (the reviewer writes none) |
| Evidence line that is a second `- [id]` line | Impossible by grammar (indented, prefixed); if a reviewer writes one anyway it is a malformed id line and is treated as a finding without a location under the existing rules |
| `### Inputs read` missing | *Not declared*: usable, triaged, round not clean, log entry `r<j>: not declared` |
| A line beginning `- <input>: partial` | A partial declaration whatever follows; with no range named, the log writes `partial — not read: unknown` |
| An expected input's line missing, or outside the grammar (for example no `- plan:` line in a lens-1 round with a plan) | That input is *not declared*: the round is partial; log entry `r<j>: <input> not declared` |
| A line for an input outside the expected set (`- plan:` in a round without the plan sentence, `- spec:` in a doc pass whose lens text does not name the spec) | Ignored for the clean-round rule and for the log |
| `### Inputs read` present at another position (above `### Verdict`, after `### Checks Run`) | Read as declared; the position is a reviewer rule, not part of the controller's check |
| Readiness report whose `coverage:` block precedes `### Inputs read` | Still usable: the readiness condition is about the block's presence, not its position relative to the new section |
| M = 1 rotating round, partial for inputs read | `**Inputs read:** r1: …` line written; when the consolidated set is empty, the `- none —` line carries `(partial round, inputs read)` |
| Verification cycle whose usable reports all declare `partial` | Counts toward the 3-cycle cap; does not end the verification (section 5.4) |

## 8. Constraints for the implementation

1. `skills/multi-doc-review/SKILL.md` is at 1,079 lines; the
   `tests/reviewer-templates/run-tests.sh` budget is 1,080 (`MDR_MAX_LINES`),
   and the test's comment states that further additions must first recover
   lines by reflowing. The additions to that file (about 12 lines) are paid
   by reflowing prose; no content is removed and no pinned span is reflowed.
2. The pinned spans of both reviewer prompts in
   `tests/reviewer-templates/run-tests.sh` are not edited: the Harness claims
   span (byte-identical across the two prompts), the folded shared-checkout
   and Tests spans, the doc prompt's Subagent Rules fragment
   (`DOC_SHARED_IN_PLACE`), the paging rule except its stop clause (section
   5.3), the Report Marker sections, the "in this checkout" count of exactly
   2, the forbidden phrases. New text
   goes in the `## Output format` section at the two positions sections 5.1
   and 5.3 name — the format example (the `evidence:` line under `[C1]`, the
   `### Inputs read` block after `- [M1] ...` and before `### Checks Run` in
   the code prompt or at the end of the example in the doc prompt) and the
   rule paragraph after the `harness:` field paragraph — where no span is
   pinned: around that position the test pins sentences as folded phrases
   (the `CHECKS_TO_FILE`, `MKTEMP_ALONE` and `FULL_REPORT_LAST_LINE`
   constants, asserted with `assert_folded_contains`) and extracts the
   Harness claims rule from its heading; none of these pins a line range,
   so an insertion between the `harness:` field paragraph and `**Where the
   report goes.**` breaks no pin. New text adds no heading after the
   closing fence.
3. `skills/multi-code-review/scripts/fill-prompt.js` exits 3 on a leftover
   `[UPPERCASE]` token. New template text uses `<a>-<b>`, `<n>`, `<path>` and
   never square-bracket upper-case placeholders.
4. The evidence paragraph is byte-identical in both prompts, so that a
   single contract test can diff it. The Harness claims mechanism
   (`extract_rule`, from a heading to the next `## ` heading) does not fit a
   paragraph without a heading and with different text after it in the two
   prompts: the test extracts from the lead-in label `**Evidence line.**` to
   the next blank line in each prompt and compares the two extracts. The
   `### Inputs read` lines differ by input name (`diff` and `plan` /
   `document`) and are pinned separately.
5. The plan verifies by grep that `skills/orchestrating-development/
   code-review-loop-prompt.md` and `doc-review-loop-prompt.md` do not
   restate the clean-round definition or the round-entry line list. If one
   does, that template is updated in the same release.
6. The code prompt's sentence "Do not crawl the broader codebase" (lines
   138-141) is left as it is; the exemption for the finding's own file is
   stated inside the new evidence paragraph (5.1, item 2).
7. The four-replacements rule for quoted text (code skill lines 1466-1480:
   "All FOUR replacements belong to the one rule") exists in the code skill
   only; the doc skill needs none for this change because the
   `rejected: evidence (<reason>)` parenthesis and the `(evidence:
   <reason>)` note hold one of five fixed phrases and no quoted text (5.2,
   item 3).
8. `tests/in-run-rulings/run-tests.sh` lines 2541-2550 locate the line
   containing `**No fix ships unreviewed:**` in the code skill and assert,
   between it and the next `## ` heading, on unfolded lines, the exact
   phrase `plan governs (loop decision)` and the fragments `a Critical is
   never rejected under this rule`, `decided wording`, `(amended by
   ruling`, `same BASE`, `never edits plan text` and `3-cycle cap is
   unchanged`. The rewrite of section 5.4 keeps the bold label on its own
   line and each of those fragments on a single line inside that range.
9. Examples inside a prompt body are plain text indented like the existing
   format example, never a fenced block: `fill-prompt.js` (lines 113-128,
   `CLOSE_FENCE_RE`) takes a bare ``` at column 0 inside the body as the
   closing fence and truncates the prompt silently, with exit 0. The
   prompt files hold no literal tab character; the example renders it as
   `<tab>` (5.1, item 9).

## 9. Testing strategy

**Contract tests** (fast, `tests/reviewer-templates/run-tests.sh`):

- The evidence paragraph is present in both prompts and byte-identical
  between them, and names the checkout file as the source for a code
  finding.
- The paging rule's new stop clause is pinned in every file of
  `PAGING_TEMPLATES` (the `PAGE_UNTIL_NO_PARTIAL` needle of
  `tests/reviewer-templates/run-tests.sh` test 19 replaced by the new
  clause) and in every controller template (the needle of the same name in
  `tests/orchestrating-development/run-tests.sh` line 97 replaced, asserted
  at line 499); the `HALVE_ON_REFUSAL` fragment keeps passing in both
  suites; the old clause `until a result carries no PARTIAL notice` is
  absent from `skills/` (negative grep).
- Both format blocks contain `### Inputs read` at the stated position; the
  `- diff:` / `- plan:` / `- document:` lines, the `whole` definition by
  coverage and the `partial — not read:` shape with `<a>-end` and `unknown`
  are pinned.
- Both prompts' **Reviewer returns** lists name the evidence line and the
  section.
- Both `SKILL.md` files contain: the convergence sentence naming `### Inputs
  read` and `not declared`; the triage sentence with `rejected: evidence (`;
  the `**Inputs read:**` log-line rule with its position and the entry-kinds
  sentence; the `(partial round, inputs read)` form; the exact old phrase
  `a round with u < M is *partial*` absent from both files (negative grep)
  and the new definition sentence present (positive pin). The code skill
  contains the widened "no fix ships unreviewed" sentence and the rewritten
  sentences of lines 1202-1212.
- The readiness `coverage:` strings (already pinned by
  `tests/reviewer-templates/run-tests.sh` lines 472-474, 483, 489) are
  unchanged; the doc `SKILL.md` stays within 1,080 lines (existing
  assertion).
- All suites listed in `CLAUDE.md` pass.

**Acceptance measure** (one real run; a template is obeyed only when its
step is concrete, so wording is checked against behaviour): one
`multi-code-review` or orchestrated run with M ≥ 2 on a branch of this
repository, after the plugin is reinstalled. The reviewer subagents'
transcripts (`~/.claude/projects/<project>/<session>/subagents/*.jsonl`) are
read with `node tools/count-report-fields.js <subagents-dir> <review-log>`.
For each transcript the script takes **one** report: the `message` input of
the last `SubagentHandback` tool call, else the last assistant text block
(measured on 60 reviewer transcripts of this repository: 53 reports were
`SubagentHandback` inputs, 0 were text blocks, and 35 code reviewers also
hold a copy in a `Write` tool input, which the script ignores). A report is
recognised by the controller's own rule — the marker
`<!-- multi-review report -->` within the first 10 non-blank lines — and the
script prints:

```
reviewer-transcripts: <t>  other: <o>  reports: <n>  with-inputs-read: <k>  ci-findings: <f>  with-evidence: <e>  secret-form-lines: <s>  rejected-evidence-lines: <r>
```

One definition each. `reviewer-transcripts`: the `.jsonl` files whose first
user message contains the lens heading `## Lens (your ONLY focus in this
review)`; the folder also holds fix subagents, controllers and other agents
of the session (measured on this machine: 50 to 111 transcripts per session
folder, 3 to 34 of them reviewers), counted as `other`. `reports`: reviewer
transcripts whose taken report carries the marker; every reviewer
transcript without one is listed by path below the counts, with the
`description` of its `.meta.json` neighbour when that file exists, so the
acceptance run explains each (a later count over 39 session folders found
149 reviewer transcripts, all 149 with a `SubagentHandback` report and none
`Write`-only, so the 7 unexplained transcripts of the first sample were
non-reviewer agents and the target held). `with-inputs-read`: reports whose
`### Inputs read` section holds a grammar-valid line (section 6) for every
input of the expected set, which the script derives from the transcript's
first user message: `diff` when it contains `Read the diff file whole`,
`plan` when it contains `Plan/requirements the branch implements (read it
first):`, `document` when it contains `Document (read it whole`, `spec`
when it contains `read the spec listed under Target`; the script also
prints the count per expected input, so a forgotten `- plan:` line on
lens-1 rounds is visible. A heading followed by prose does not count.
`secret-form-lines`: evidence lines in the secret form, printed as an extra
counter so an acceptance run shows the share of the one form that quotes
no text. `ci-findings`: id lines under
`#### Critical` and `#### Important` across the taken reports, counted per
report without merging. `with-evidence`: those id lines whose next
non-blank line starts, after indentation, with `evidence: ` (presence only,
no form check). `<r>`: `rejected: evidence (` disposition lines plus
`(evidence: ` notes in the review log.

Targets: `reports` = `reviewer-transcripts`; `with-inputs-read` = `reports`;
`ci-findings` ≥ 5 (repeat the run on another branch until reached, so that
the evidence rule is exercised); `with-evidence` ≥ 0.9 × `ci-findings`. A
lower rate means a wording fix, as with "with the Read tool" (0/11 obeyed
as bare "Read", 11/11 with the tool named). An `<r>` above a quarter of
`ci-findings` means the controller over-rejects and the triage rule's
wording is revisited. The script has a fast test suite
`tests/count-report-fields/run-tests.sh`, listed in `CLAUDE.md` and loading
`tests/lib/undefined-command-guard.sh` like every suite, with a fixture
`subagents/` folder of six transcripts: one report in a `SubagentHandback`
input with a `Write` copy of the same report (counted once), one report as
an assistant text block with a sentence above its marker, one with no
`### Inputs read` section, one with the heading followed by prose (not
counted as with-inputs-read), one with an `evidence:` line that is not
directly below its id line (not counted as with-evidence), and one
non-reviewer transcript (a fix subagent's prompt, no lens heading; counted
under `other`); between them one C/I finding with an evidence line directly
below it.

## 10. Rollout

- Version 7.75.0 in `VERSION`, `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, the
  `README.md` badge and the two lineage ranges; a `RELEASE-NOTES.md` entry
  with the three-line summary (Problem / Change / Effect). Effect: "Reinstall
  the plugin; nothing to migrate. Existing logs are read unchanged: the new
  line is optional and absent from them."
- `docs/guide/README.md` lines 388-390 state the clean-round rule ("an early
  exit after two consecutive clean rounds — with M > 1 a round is clean only
  when every reviewer returned a usable report"); that sentence gains the
  inputs-read condition, which also applies at M = 1. A grep of
  `docs/guide/` for `clean` and `PARTIAL` finds any other sentence to
  update. No guide page shows a reviewer report or a round entry, so
  nothing else changes there.
- Sessions run the installed copy under
  `~/.claude/plugins/cache/superpowers-orchestrator/`; the acceptance run of
  section 9 happens after reinstall.
- No hook, no `hooks/skill-rules.json` change: no new skill, no new trigger.

## 11. Failure modes and accepted limits

1. **A reviewer types the evidence line from memory instead of pasting.**
   Possible, but the Read output is in its context and the required tool
   prefix makes a typed line unnatural. Accepted limit; the acceptance
   measure catches a systematic failure, not a single one.
2. **A controller rejects a true finding over a trivial mismatch** (an
   off-by-one line, re-flowed whitespace). The rule compares meaning, not
   bytes, rejection is allowed, not required, never for a Critical finding,
   and with M ≥ 2 one matching source suffices; the next round's reviewer
   can re-report the defect under its own lens. Minor, documented; the `<r>` count of section 9 makes
   over-rejection visible.
3. **A false `whole`.** A reviewer that lost a page and declares `whole` is
   the status quo, where nothing is declared at all; the coverage definition
   (5.3) leaves it no truthful way to write `whole` after a sliced read or
   no read, and the stop-clause change of 5.3 removes the one systematic
   cause (a full page without a notice read as the end). Minor; not worse
   than today.
4. **Reviewers forget the section systematically**, so no round is ever
   clean. Visible in every log as `not declared`; early exit fired in one of
   30 logs, so the cost in rounds is near zero; the fix is wording.
5. **Verification cap or addendum bound reached under partial
   declarations.** When every verification cycle's usable reports declare
   the diff `partial` without clearing annotations, the fix ships at the
   3-cycle cap with the declarations in the log; an addendum re-review in
   the same state ends at its two-re-review bound the same way. The cap and
   the bound already limit this cost today for u < M; measured obedience
   (22 of 22 partial views paged to the end) makes the case rare, and the
   path annotation of 5.3 removes the systematic case of a skipped
   generated file. Accepted limit.
6. **The secret form is unverifiable by design.** `evidence: <n> —
   secret-bearing line, not quoted` can be written without re-opening the
   file, and the controller cannot tell. It is the one form without the
   forcing function; the acceptance script prints its share
   (`secret-form-lines`). Accepted limit.
7. **The Bash-output routes.** A reviewer that reads an input through `cat`
   or through the no-package fallback without saving the diff to a file
   cannot name ranges and must write `partial — not read: unknown`; the
   prompts already name the Read tool for every prompt-named input
   (measured 11/11 obeyed). Accepted limit.

## 12. Evidence basis (measured 2026-10-24 on this repository)

- 63 review logs, 3,948 disposition lines: applied 1,659; fixed 837; carried
  1,022; rejected 196 (5.0 %); of the rejections, 26 wrong reviewer findings,
  about 6 of them a wrong line or an absent-text claim; 0 self-contradicting
  reports found (reports are not stored, so not measurable); 0 free-text
  uncertainty phrases ("could not verify", "low confidence") in any log.
- 217 `**Reviewers:**` lines, 0 with fewer usable reports than M; 22 partial
  Read views by reviewers, all paged to the end; 1 declared cut-off (retried).
- The largest avoidable reviewer-side waste is re-reporting settled items
  (27 duplicates, 17 already decided, 11 already resolved), not wrong facts;
  that is outside this design.
- Read tool notice text, the 25,000-token cap, the 30,000-character cut of
  Bash output, and the Read total that counts one empty line after the
  file's final newline: `tools/measure-context.js` lines 42-58 and
  `RELEASE-NOTES.md` lines 5767-5768 and 2408-2413. A Read with an explicit
  `limit` that stops before the end of the file prints no PARTIAL notice
  (observed by two round-1 reviewers on `skills/multi-code-review/SKILL.md`),
  and a Read at an offset past the end returns no line and names the file's
  total line count (observed by a round-2 reviewer on
  `skills/multi-doc-review/reviewer-prompt.md`: 182 lines by `wc -l`, "The
  file has 183 lines" by the tool).
- Reviewer reports on disk: 53 of 60 transcripts hold the report as a
  `SubagentHandback` input, 35 also as a `Write` input, 0 as an assistant
  text block beginning with the marker (observed by a round-1 reviewer). A
  session's `subagents/` folder holds every subagent of the session: 50 to
  111 transcripts per folder, 3 to 34 of them carrying the reviewer lens
  heading (observed by two round-3 reviewers).
- `grep -n` with one file argument prints `<line>:<text>` without the path
  in GNU grep, BSD grep and ugrep; `-H` adds it (observed by a round-3
  reviewer in this checkout). A Read that fills its `limit` carries no
  PARTIAL notice (observed with `limit` 3 on a 1,994-line file). A Read
  refused for size delivers no line and no notice: "File content (60692
  tokens) exceeds maximum allowed tokens (25000)" (observed by two round-4
  reviewers on `RELEASE-NOTES.md`). A Read at an offset past the end
  answers "The file has 779 lines" where `wc -l` prints 778 (observed on
  this document).
- Over 39 session folders of this project: 149 reviewer transcripts (first
  record holds the lens heading), 149 with a `SubagentHandback` report, 0
  `Write`-only, 0 without (observed by a round-4 reviewer).
