# Review log — reviewer-evidence-and-inputs-read.md

_Invocation 1 — 2026-10-25 — N=4 M=3 — gate: orchestration — plan-blob bca1b3814f5a4d9255808ddc356230e85ccb7566_

## Readiness pre 1 — Execution readiness — opus
**Result:** open
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 3 Minor | r2: 0 Critical, 1 Important, 5 Minor | r3: 0 Critical, 0 Important, 5 Minor
**Sources mapped:** 16/16
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor

### Dispositions
- [I1] applied — Task 2 Contract / Task 3 Contract: Global Constraint 2 (fixed, spec 8.2) names two edit positions while Tasks 2-3 also edit the code prompt's file:line reference sentence and both Reviewer returns lists after the closing fence → plan side amended: Task 2's Contract now states that these edits are spec-required (5.1, 5.4, 9), touch no pinned span, and add no heading after the fence (the only post-fence rule of GC2); Task 3's Contract cites the same reading ← 3/3: r1:I1, r2:M2, r3:M2
- [I2] applied — Task 3 test 30 (and Task 2 test 29): the Reviewer returns checks searched the whole prompt file, where the new rule paragraph already holds the needle, so spec 9's "Reviewer returns lists name the evidence line and the section" was not verified → test 29 now extracts the text from the `**Reviewer returns:**` line to the end of each file and both tests assert on those extracts; Step 2 expectation updated ← 3/3: r1:I2, r2:M3, r3:M4
- [I3] applied — Task 5 Step 4 / Task 7 Step 4: the "exactly" grep expectations omitted the `input partial` lines that Task 4 (spec 5.2) inserts and named sites that are no grep hit (code line 736, doc item 8 — verified by running the grep) → expectations now include the evidence paragraph's lines and drop the non-hits; the two Does NOT cover lists say why those sentences are not printed ← 2/3: r1:M3, r2:I1
- [M1] applied — Task 6 Contract / Task 7 Contract: Task 6's "the room Task 7 needs" was false (Task 7 adds about 65-70 lines), and the untouched list missed the `first_line_of "$DOC_SKILL"` anchors such as `Skipped invocations (N=0)` (mid-line at SKILL.md line 943, verified) → Task 6's invariant now says Task 7 continues the reflow and protects every `first_line_of` anchor; Task 7's line-budget item states the further reflow is the expected path ← 3/3: r1:M1, r2:M1, r3:M1
- spec deviation: the plan states that Task 7 adds about 65-70 lines to skills/multi-doc-review/SKILL.md — spec: "The additions to that file (about 12 lines) are paid by reflowing prose" (docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md, section 8 item 1) — kept because the spec's figure is an estimate that the plan's own reference texts exceed; the budget of 1,080 lines and the reflow method are unchanged
- [M2] applied — Task 5 Contract: Global Constraint 8's "keeps the bold label on its own line" read literally conflicts with the mandated layout (label followed by text, as at line 1099) → Task 5's Contract states the reading: the label stays whole at the start of its line, never split ← 2/3: r1:M2, r3:M3
- [M3] applied — Task 7 Step 3 item 2: the doc evidence paragraph omitted the removed-file match rule that Task 7's Contract (same properties as Task 4) and spec 5.2 item 2 require → added "and the removed-file form on its path alone" ← 2/3: r2:M4, r3:M5
- [M4] applied — Task 9 Contract: "no `7.74.1` left outside `RELEASE-NOTES.md`" cannot hold (this plan and other docs keep historical mentions) and Step 2 checks five files only → contract narrowed to the version files and README.md ← 1/3: r2:M5

## Readiness pre 2 — Execution readiness — opus
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 3 Minor | r2: 0 Critical, 0 Important, 3 Minor | r3: 0 Critical, 0 Important, 3 Minor
**Sources mapped:** 9/9
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor

### Dispositions
- [M1] applied — Assumptions / Global Constraint 1: GC1's "about 12 lines" disagrees with Tasks 6-7's 65-70 lines; GC1 copies spec 8.1 verbatim (fixed text, never amended here), so the plan side carries the reading → new Assumptions bullet states that the figure is the spec's estimate and the reflow pays the real additions (covered by the pre 1 spec deviation line) ← 3/3: r1:M1, r2:M1, r3:M1
- [M2] applied — Assumptions / Global Constraint 2: the reconciliation of the reference sentence and Reviewer returns edits stood only in Task 2's Contract → same Assumptions bullet states GC2's reading in the header (GC2 is spec 8.2 verbatim, not amended) ← 3/3: r1:M2, r2:M2, r3:M2
- [M3] applied — Assumptions / Global Constraint 8: "on its own line" disagrees with the label-plus-text layout, and the six fragments are matched folded and case-insensitively (verified: tests/in-run-rulings/run-tests.sh lines 115-116 and 181) → same Assumptions bullet states the reading and the real match rule (GC8 is spec 8.8 verbatim, not amended) ← 3/3: r1:M3, r2:M3, r3:M3

## Round 1 — Correctness & completeness — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 2 Minor | r2: 0 Critical, 2 Important, 4 Minor | r3: 0 Critical, 2 Important, 2 Minor
**Sources mapped:** 15/15
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 5 Step 3b item 6 / Task 7 Step 3 item 5: the rewritten clean-round bullet required every input `whole` for the plain line in every entry kind, but allowed the `inputs read` cause in rotating rounds only, leaving verification cycles, addendum re-reviews and readiness passes with no allowed line and contradicting the unchanged "A settled pass … writes the one disposition line" (doc SKILL.md line 960) and spec 5.4 ("The clean-round disposition line of a **rotating round**") → the condition is scoped to rotating rounds in both bullets; other entry kinds keep today's line and record declarations on the `**Inputs read:**` line; new pin `CLEAN_LINE_SCOPE` in tests 32/33; contract bullets added ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — Task 5 / Task 7 edit lists: the Review Log Format sentences "A clean round (… with u = M) writes exactly one disposition line", "A Minor-only round is clean for convergence (with u = M)" (code 1436-1440, doc 942) and the `**Sources mapped:**` parenthesis (code 1376, doc 915) kept a u = M-only definition, against spec 5.4's one-definition rule (verified by grep; no suite pins them) → Task 5 item 10 and Task 7 item 8 rewrite them; negative pins added to tests 32/33; a second Step 4 grep lists the clean-round sentences ← 3/3: r1:I2, r2:I2, r3:I2
- [I3] applied — Task 4 Step 3 / Task 7 Step 3 item 2: the match rule required the line number to equal the finding's line, which an absence-form line (no number) can never satisfy, so every correct absence-form Important code finding could be rejected as `line differs` → both paragraphs now say the absence form carries no line number and matches on its pattern alone (doc: line-number test limited to presence and gap forms); pin `EVIDENCE_ABSENCE` added to tests 31/33; contract updated ← 1/3: r1:I3
- spec deviation: the absence form carries no line number and matches on its pattern alone — spec: "for a line location, its line number equals the finding's line … and, in every form, the quoted text shows the defect" with no exemption for the absence form (docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md, section 5.2 item 2) — kept because the spec's rule cannot be met by the absence form it defines, and following it would reject every correct absence-form finding at a line location
- [M1] applied — Task 5 Step 3b item 2 / Task 7 Step 3 item 3: a line such as `- diff: partial` fit both "outside that grammar" (not declared) and "names no range" (partial — unknown) → convergence text now says a line beginning `- <input>: partial` is a `partial` declaration whatever follows (spec section 7 error table); pin `PARTIAL_WHATEVER` added ← 3/3: r1:M1, r2:M2, r3:M1
- [M2] applied — Task 8 Step 2: the expected red run omitted the three section-2 exit-code failures (node exits 1 for a missing script) → added ← 2/3: r1:M2, r2:M4
- [M3] applied — Task 7 Step 3: the further reflow had no word-stream check → an "Order of work" paragraph now reflows before item 1 with Task 6's `SAME-WORDS` check, and a post-edit reflow compares against a saved word stream; Step 3 opens with a pointer to it; line estimates updated to about 70-75 ← 2/3: r2:M3, r3:M2
- [M4] applied — Task 7 Step 3 item 2: the plan did not say whether the evidence rule applies to readiness findings → the doc paragraph now says it applies to rotating rounds and a readiness finding is disposed under `Triage of a readiness finding`; pin `DOC_EVIDENCE_READINESS` added ← 1/3: r2:M1

## Round 2 — Ambiguity & testability — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 6 Minor | r2: 0 Critical, 1 Important, 6 Minor | r3: 0 Critical, 1 Important, 6 Minor
**Sources mapped:** 21/21
**Reviewer verdict:** 0 Critical, 2 Important, 12 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 1 Contract and Step 3 (paging paragraph, dashboard text): a result that fills its `limit` "is not the end", but the only next-call rule names the notice's offset, which does not exist in that case → both reference texts and the Contract now say "Read again at the offset after the last line received, with the same `limit`"; needle `NEXT_AFTER_FULL` added to test 19 (templates and dashboard) and test 5c; Step 2 expectations updated ← 2/3: r1:I1, r3:M1
- [I2] applied — Task 6 Step 2 / Task 7 Step 3: the word-stream comparison cannot see a reflowed fence, table row, heading, protected section, new long line or new list prefix → Step 2 now defines `reflow_check` (SAME-WORDS, SAME-ZONES, NO-NEW-LONG, SAME-LIST-COUNT; smoke-tested under bash and zsh on the current file and a modified copy), Task 7's two reflow points call it against a saved copy, and the 88 limit is stated in characters ← 2/3: r2:I1, r3:I1
- [M1] applied — Task 1 Step 4 / Task 8 Step 4: expected results were hidden by the pipe (`tail`/`grep` exit status; suite-guard PASS lines filtered) → dashboard and fill-prompt now print their own exit codes; suite-guard grep shows the `found N suites` and `count-report-fields` PASS lines, expected count 21 (measured today: 20) ← 3/3: r1:M1, r2:M4, r3:M4
- [M2] applied — Task 3/5/7 Step 2: expected-failure lists omitted the new negative pins (strings present today, verified) and the empty-extract checks → lists completed ← 2/3: r1:M2, r2:M2
- [M3] applied — Task 1 / Task 4 Contracts: "Sentence wording is free" against fixed needle strings shared by tests 31 and 33 → both Contracts now say the needles are fixed and a rewording updates needle and paragraphs in the same commit ← 2/3: r1:M4, r2:M1
- [M4] applied — Task 8 Contract: "(rule 2)" undefined in the plan → replaced by the reason (no other component reads the output) ← 2/3: r1:M6, r3:M6
- [M5] applied — Contracts of Tasks 3/4/5/7: "Verification: test N" claimed properties no needle pins → Task 4's Verification names what test 31 pins and what is checked by reading; the File Structure note states this reading for every test section ← 1/3: r1:M3
- [M6] applied — Task 7 Step 3 item 2: blank lines around the inserted paragraph unstated → "no blank line before or after", like the neighbouring paragraph (verified at doc SKILL.md lines 558-559) ← 1/3: r1:M5
- [M7] applied — Task 9 Step 2: the fast-suite loop omitted `tests/context-management/run-tests.sh` (a guarded suite, verified) → added; expected 22 lines ← 1/3: r2:M3
- [M8] applied — Task 8 Contract: no contract bound the fixture cases → new "Fixture cases" bullet lists each case and the counter it drives ← 1/3: r2:M5
- [M9] applied — Task 7 Step 3: no named zones or fallback when reflow cannot reach 1,080 lines → zones ordered, and the task stops as blocked rather than raising the budget or removing content ← 1/3: r2:M6
- [M10] applied — Task 3 Step 3 `**Inputs read.**` paragraph: "one line per input that this prompt tells you to read whole" while plan/spec sentences never say "whole" → "one line per input that the Inputs item below names" ← 1/3: r3:M2
- [M11] applied — Task 7 Step 3 item 3: whether a line break counts in `read the spec listed under Target` (wrapped in the readiness cell, doc SKILL.md lines 824-825) → "any run of whitespace, a line break included, counts as one space" ← 1/3: r3:M3
- [M12] applied — Tasks 2-5 and 7: test sections 29-33 had no contract of their own → File Structure note: every listed check binds as a minimum, may be made stricter, never removed or weakened ← 1/3: r3:M5

## Round 3 — Feasibility & architecture risk — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 2 Minor | r2: 0 Critical, 0 Important, 2 Minor | r3: 0 Critical, 1 Important, 2 Minor
**Sources mapped:** 7/7
**Reviewer verdict:** 0 Critical, 1 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 6 Contract / Task 7 Contract and Step 3: three independent dry runs put the most reflow can recover at 78-87 lines, while Task 7's texts added about 79-82, so Task 7 would likely end blocked → Task 7's doc-skill reference texts shortened (evidence paragraph 31 → 21 lines, `**Inputs read:**` paragraph 22 → 15, clean-round bullet 12 → 9; every test-33 needle re-checked folded against the new texts, widths ≤ 88 checked); additions now about 60-65; Task 6 target 1015 and Task 7 threshold 1015; measured recovery bound written into Task 6's Contract; a sanctioned fallback (shorten the new texts, keeping every needle) now precedes "blocked" ← 3/3: r1:I1, r2:M1, r3:I1
- spec deviation: the plan states that Task 7 adds about 60-65 lines to skills/multi-doc-review/SKILL.md (this supersedes the 65-70 figure of the pre 1 deviation line above) — spec: "The additions to that file (about 12 lines) are paid by reflowing prose" (docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-and-inputs-read/specs/reviewer-evidence-and-inputs-read-design.md, section 8 item 1) — kept because the spec's figure is an estimate the required texts exceed; budget and reflow method unchanged
- [M1] applied — Task 7 Step 3 item 2: one reference line was 89 characters → the paragraph was rewritten (I1) and every line checked at ≤ 88 characters ← 1/3: r1:M1
- [M2] applied — Tasks 4 and 5 Step 4: four other fast suites read `skills/multi-code-review/SKILL.md` → a Run line now runs review-gates, orchestrating-development, sdd-scripts and fill-prompt with their exit codes ← 1/3: r1:M2
- [M3] applied — Task 7 Step 3 "Order of work": a saved path and the `reflow_check` function do not survive between Bash calls → the paragraph now says to use the printed path literally and paste the function into the call that runs it ← 1/3: r2:M2
- [M4] applied — every Step 4 / Step 2 filter: `grep -E 'FAIL|Results'` also matched PASS lines naming `FAILURE_BLOCK` (verified: the new filter prints 1 line on HEAD for both suites) → all 23 filters now read `grep -E '  FAIL: |Results'` ← 1/3: r3:M1
- [M5] applied — Task 2 Step 3 evidence paragraph and the Assumptions deviation line: "the **Repository root:** path at the top of this prompt" — the field is under `## Diff Under Review` (code prompt line 117, verified) → "the **Repository root:** path that this prompt gives (under `## Diff Under Review`)" ← 1/3: r3:M2

## Round 4 — Adversarial failure modes — opus
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 5 Minor | r2: 0 Critical, 1 Important, 3 Minor | r3: 0 Critical, 0 Important, 4 Minor
**Sources mapped:** 14/14
**Reviewer verdict:** 0 Critical, 2 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 6 Step 2 `reflow_check` (reused by Task 7): deleting a blank line or de-indenting a list item's continuation lines passed all four checks (r2 ran it; reproduced here on copies of the skill) → fifth check `SAME-PARAGRAPHS` added (blank lines kept, text-column sequence unchanged); smoke-tested under bash and zsh: unchanged file and a legitimate line join pass it, a removed blank line and a de-indented step fail it; Task 6 invariant now says no blank line is added or removed and indentation is kept ← 2/3: r1:M3, r2:I1
- [I2] applied — Task 5: `skills/orchestrating-development/code-review-loop-prompt.md` Deviation 5 restates the addendum rule ("only when a Critical/Important finding still stands — one more fix subagent and re-review 2"), which item 8 widens; Step 3a's grep cannot see it (verified, lines 193-198) → item 11 rewrites the sentence (keeping the two phrases `tests/in-run-rulings` pins), Step 3a gains a second grep, Files, Does NOT cover and the commit list name the template, and test 32 pins the new trigger ← 1/3: r1:I1
- [M1] applied — Tasks 2, 3 and 5: cited line numbers predate Task 1's and Task 4's insertions → both Files lists now say the numbers are pre-task and each site is located by its quoted text; item 6 quotes the old bullet's first line ← 3/3: r1:M1, r2:M1, r3:M1
- [M2] applied — Task 6 Contract vs Step 2: "at most 1015" against "up to 1025 commit it" → one rule in both places (≤ 1015; up to 1025 accepted with the shortfall reported; above 1025 blocked) ← 2/3: r1:M2, r3:M2
- [M3] rejected: harness probe not runnable here — in the permission mode of the executing session, run the Task 4 Step 4 loop as written and observe whether Claude Code refuses it — (would break a constraint) — Tasks 4/5/9 Step 4: a `for` loop over suites may be refused by Claude Code's removal check ← 1/3: r1:M4
- [M4] applied — Task 2 Step 3 evidence paragraph: the `limit` 1 evidence read fills its limit, which the new paging rule says is not the end → the paragraph now says this one-block read is ended by the paging rule after that line ← 1/3: r1:M5
- [M5] applied — Task 7 Step 3 item 6: the M = 1 label of the single `**Inputs read:**` entry was dropped → "(`r1: …` when M = 1)" added ← 1/3: r2:M2
- [M6] applied — Task 7 "Order of work" first bullet: no next step when the zones run out above 1015 → "go on with items 1-8: the After item 8 rules then decide" ← 1/3: r2:M3
- [M7] applied — Task 8 Step 3: no rule when the git-ignored `CLAUDE.md` is absent in a fresh worktree → skip the edit, never create the file, name it in the report ← 1/3: r3:M3
- [M8] applied — Task 8 suite: the `no report:` line compared a POSIX absolute path that Windows Git Bash would print differently → the check strips the path up to its last separator (`/` or `\`, sed tested on both forms) and compares the file name ← 1/3: r3:M4

## Readiness post 1 — Execution readiness — opus
**Result:** settled
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 0 Important, 2 Minor | r2: 0 Critical, 0 Important, 1 Minor | r3: 0 Critical, 0 Important, 1 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 0 Critical, 0 Important, 3 Minor

### Dispositions
- [M1] applied — Assumptions (Global Constraint 1 reading) / Task 6 Step 1: "pinned span" was undefined while zones 1-3 hold folded range and phrase pins (tests 11, 13, 14, `DOC_CONTROLLER_SHARED_RULE`) → the reading now defines a pinned span for GC1 as a line-anchored pin (Task 6's untouched list) and states that folded pins may be reflowed, as test 16's comment records for the earlier Procedure step 3 reflow (verified, run-tests.sh line 751) ← 2/3: r1:M1, r2:M1
- [M2] applied — Task 1 Contract: the reference paragraph rewraps the sentences after the stop clause, which GC2 and GC12 read literally forbid → the Contract states that those sentences may be rewrapped, their words unchanged and every pin on them folded ← 1/3: r1:M2
- [M3] applied — Task 7 Step 3: the item 1-8 rewrites were not bound by Task 6's no-break rule, and item 8 lengthens the line before the `Skipped invocations (N=0)` anchor → Step 3 now applies Task 6's untouched-zone and no-break rules to items 1-8 and names that anchor ← 1/3: r3:M1

### Host self-review (writing-plans Self-Review)
- Spec coverage: covered by round 1 and both readiness sequences; no gap left open.
- Placeholder scan: no TBD/TODO/"add appropriate" pattern; every "placeholder" hit names a template placeholder on purpose.
- Type consistency: every name added in this loop is defined before use — `CODE_RETURNS`/`DOC_RETURNS`/`extract_from_lead` (test 29, reused by test 30), `EVIDENCE_ABSENCE` (test 31, reused by test 33), `PARTIAL_WHATEVER`/`CLEAN_LINE_SCOPE`/`CODE_LOOP_TEMPLATE` (test 32), `DOC_EVIDENCE_READINESS` (test 33), `NEXT_AFTER_FULL` (both suites), `reflow_check` (Task 6 Step 2, reused by Task 7); none clashes with an existing name in the two suites (grep).
- Scope-reduction scan: no hit.
- Contract audit: the template edit added in round 4 (Task 5 item 11) had no Contract item → fixed inline: Task 5's Contract gains a "Code-review loop template, Deviation 5" bullet.

**Host self-review:** done

_Loop complete — 2026-10-25 — rounds 4_
