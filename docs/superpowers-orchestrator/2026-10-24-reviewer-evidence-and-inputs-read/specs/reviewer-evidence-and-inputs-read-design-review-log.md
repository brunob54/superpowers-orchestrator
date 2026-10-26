# Review log — reviewer-evidence-and-inputs-read-design.md

_Invocation 1 — 2026-10-24 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 7 Important, 5 Minor | r2: 0 Critical, 7 Important, 4 Minor | r3: 0 Critical, 6 Important, 5 Minor
**Sources mapped:** 34/34
**Reviewer verdict:** 0 Critical, 12 Important, 9 Minor
**Converged:** no

### Dispositions
- [I1] applied — §5.3: `whole` was satisfied by zero Read calls, by a sliced Read with a `limit`, and by the no-package Bash fallback → `whole` defined by coverage (every line from 1 to the end of the file); zero reads and sliced reads are `partial`; the fallback saves the diff to a `mktemp` path and reads it with the Read tool ← 3/3: r1:I1, r2:I2, r3:I3
- [I2] applied — §5.4: verification cycles, addendum re-reviews and readiness passes have no `**Converged:**` line and no stated behaviour for the new state → "Entry kinds" paragraph: the `**Inputs read:**` line is anchored after `**Reviewer verdict:**` in every entry kind, the `- none` parenthetical on rotating rounds only, each kind's outcome rule named ← 3/3: r1:I5, r2:I7, r3:I5
- [I3] applied — §9: the script's "first non-blank line is the marker" rule matches 0 reports on disk (53 of 60 are `SubagentHandback` inputs, 35 also `Write` inputs) → one report per transcript (last `SubagentHandback` message, else last text block), `Write` copies ignored, the controller's 10-non-blank-lines marker rule; the fixture holds each shape ← 3/3: r1:I6, r2:M3, r3:I6
- [I4] applied — §4/§5.3: the plan file is a second prompt-named input when the code prompt carries the plan line → `- plan:` line present exactly then; section 4 corrected ← 2/3: r1:I2, r2:I1
- [I5] applied — §5.2: "the quoted line lies in the named section" cannot be checked from the report alone → removed from the controller's match rule, kept as a reviewer rule ← 2/3: r1:I3, r3:I2
- [I6] applied — §5.2: with M ≥ 2 a consolidated finding carries several evidence lines → it matches when at least one source's line matches; rejection only when none does ← 2/3: r1:M1, r2:I4
- [I7] applied — §5.4: a report declaring `partial` still counted a fix as reviewed → a fix is reviewed only by at least one usable report declaring every input `whole`; a cycle without one counts toward the 3-cycle cap and does not end the verification; the addendum re-review follows the same rule ← 2/3: r2:I5, r3:I4
- [I8] applied — §5.4: "partial round" is defined inline at six further sites of the two skills → every site listed for update; negative grep added to the contract tests ← 1/3: r1:I4
- [I9] applied — §5.1: no evidence form fitted a finding that existing text is incomplete → gap form added (quote the governing line) with its match clause ← 1/3: r1:I7
- [I10] applied — §5.3: a clean-verdict report may have no `### Findings` section → the section is written in every report; position below Findings when present, below Verdict otherwise ← 1/3: r2:I3
- [I11] applied — §5.1 item 6 / §8: the placement of the doc prompt's secret-form words was ambiguous → inside the byte-identical paragraph only, no new Subagent Rules bullet; `DOC_SHARED_IN_PLACE` added to the untouched spans ← 1/3: r2:I6
- [I12] applied — §5.1: a code reviewer's line "as the Read tool returned it" would come from the diff file, whose line numbers are not the source file's → the evidence line comes from the checkout file at the finding's path, declared not a Checks Run item and not a crawl ← 1/3: r3:I1
- [M1] applied — §5.2 item 3: `rejected: evidence — <reason> — <summary>` left the reason's end ambiguous and cited a replacement rule the doc skill lacks → `rejected: evidence (<reason>)` with four fixed phrases; constraint 8.7 ← 2/3: r1:M2, r3:M3
- [M2] applied — §6: the table omitted `<a>-end` and `unknown` → added ← 2/3: r1:M4, r3:M1
- [M3] applied — §7: precedence and log text for `partial` without ranges → a line beginning `- <input>: partial` is partial whatever follows; the log writes `not read: unknown` ← 2/3: r2:M1, r3:M5
- [M4] applied — §7: the last row contradicted §5.4 on the M = 1 `- none` line → row amended ← 1/3: r1:M3
- [M5] applied — §5.4: unusable reviewers are not listed on the `**Inputs read:**` line ← 1/3: r1:M5
- [M6] applied — §5.1: Reviewer-returns line numbers corrected to 292-299 and 181-182 ← 1/3: r2:M2
- [M7] applied — §5.1/§5.2: for a range location `<path>:<a>-<b>` the evidence number lies inside the range ← 1/3: r2:M4
- [M8] applied — §5.1 item 7 / §7: one sentence for Minor findings — the reviewer writes none, the controller ignores one ← 1/3: r3:M2
- [M9] applied — §5.1 item 3: leading spaces before the Read tool's line number are dropped ← 1/3: r3:M4

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 6 Minor | r2: 0 Critical, 3 Important, 5 Minor | r3: 0 Critical, 4 Important, 7 Minor
**Sources mapped:** 29/29
**Reviewer verdict:** 0 Critical, 6 Important, 14 Minor
**Converged:** no

### Dispositions
- [I1] applied — §4/§5.3/§6: "the prompt carried the plan line" had two readings, because the controller also fills the placeholder with a no-plan sentence → the plan is an input exactly when the prompt contains the sentence beginning `Plan/requirements the branch implements (read it first):`; the expected set defined; lines for inputs outside it ignored ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — §5.4/§6/§7: a single missing input line had no log shape and was absent from the convergence sentence → three entry shapes (`<input> partial — …`, `<input> not declared`, bare `not declared`); the clean condition restated as "a `whole` line for every expected input" and the partial condition as its exact complement ← 3/3: r1:I2, r2:I2, r3:I2
- [I3] applied — §5.4: lines 1202-1212 of the code skill attach consequences to "partial" that are false for the inputs-read cause → the three sentences named and rewritten under the condition "at least one usable report declaring every input `whole`"; every consequence sentence names its cause ← 2/3: r1:M6, r3:I3
- [I4] applied — §9: the four counters were undefined → one definition each (a heading plus a grammar-valid line; id lines under the C/I headings per report; the next non-blank line starting with `evidence: `); two fixture transcripts added for the malformed cases ← 2/3: r2:I3, r3:I4
- [I5] applied — §5.2: the secret form quotes no text, so the match rule could reject a credential finding → the secret form matches on its line number alone, the removed-file form on its path ← 1/3: r1:I3
- [I6] applied — §9: `with-inputs-read = reports` was self-referential → the script prints `transcripts`, lists every transcript without a recognised report, target `reports = transcripts`; the 7 unexamined transcripts stated as such ← 1/3: r1:I4
- [M1] applied — §5.3/§12: the Read total counts one empty line after the final newline, and a page that fills its `limit` carries no end-of-file signal → ranges use the Read tool's numbering, a trailing empty-line range is not missing, a Read past the end proves the end ← 3/3: r1:M2, r2:M4, r3:M7
- [M2] applied — §5.1 item 8: the 200-character window counts the text after the prefix, marks excluded ← 2/3: r2:M3, r3:M6
- [M3] applied — §9: `ci-findings` = 0 made the evidence target vacuous → minimum of 5, repeat on another branch until reached ← 1/3: r1:M1
- [M4] applied — §5.1: a finding on a file the branch deletes or renames had no form → removed-file form `evidence: <path> — not in the checkout at HEAD` ← 1/3: r1:M3
- [M5] applied — §5.4: "this parenthetical" could be read as the whole `(partial round, …)` family → "No other entry kind writes the `inputs read` cause; the `usable <u>/<m>` form is unchanged everywhere" ← 1/3: r1:M4
- [M6] applied — §5.5: "No script parses the review log" contradicted the neighbouring bullet on `test-helpers.sh` → scoped to Node scripts under `skills/`, `hooks/`, `tools/` ← 1/3: r1:M5
- [M7] applied — §9: the pinned-line numbers named no file → `tests/reviewer-templates/run-tests.sh` named ← 1/3: r2:M1
- [M8] applied — §5.1 item 2: a finding's `file:line` is a checkout line, never a diff-file line; the reviewer corrects the location when the evidence read shows another line ← 1/3: r2:M2
- [M9] applied — §7: a `### Inputs read` section at another position is read as declared ← 1/3: r2:M5
- [M10] applied — §1: the paper title added; "the one study" replaced by "the study the analysis cited" ← 1/3: r3:M1
- [M11] applied — §12: the 30,000-character Bash cut added to the cited sources (`RELEASE-NOTES.md` 2408-2413) (harness field dropped: repository-readable) ← 1/3: r3:M2
- [M12] applied — §8 item 2: the pins named by their test constants (`CHECKS_TO_FILE`, `MKTEMP_ALONE`, `FULL_REPORT_LAST_LINE`) instead of line ranges ← 1/3: r3:M3
- [M13] applied — §9: the negative grep pins the exact phrase `a round with u < M is *partial*`, with a positive pin of the new sentence ← 1/3: r3:M4
- [M14] applied — §5.3/§6: zero reads are `1-end`; ranges separated by `, ` ← 1/3: r3:M5

## Round 3 — Feasibility & architecture risk — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 3 Minor | r2: 0 Critical, 2 Important, 4 Minor | r3: 0 Critical, 0 Important, 5 Minor
**Sources mapped:** 17/17
**Reviewer verdict:** 0 Critical, 4 Important, 9 Minor
**Converged:** no

### Dispositions
- [I1] applied — §10: the rollout item named guide sections that do not exist, while `docs/guide/README.md` lines 388-390 state the clean-round rule and become wrong → the item names that sentence, adds the inputs-read condition, and greps the guide for `clean` and `PARTIAL` ← 3/3: r1:I3, r2:M1, r3:M1
- [I2] applied — §9: a session's `subagents/` folder holds fix subagents and controllers too (50-111 transcripts per folder, 3-34 reviewers), so `reports = transcripts` could never hold → reviewer transcripts selected by the lens heading in the first user message, `other` printed, target `reports = reviewer-transcripts`, a non-reviewer fixture transcript added ← 2/3: r1:I2, r2:I2
- [I3] applied — §5.1/§6: `grep -n` with one file prints no path, so the stated grammar was never printed by the tool → `grep -nH` prescribed ← 1/3: r1:I1
- [I4] applied — §5.3/§2/§8/§9: the pinned paging rule's stop clause "until a result carries no PARTIAL notice" ends a read at a full page without a notice, making a false `whole` systematic on long inputs → the clause becomes "until a result returns fewer lines than its `limit`, or no line at all", in every file carrying the sentence (`task-reviewer-prompt.md` included), with the `PAGE_UNTIL_NO_PARTIAL` needle of test 19 ← 1/3: r2:I1
- [M1] applied — §8 item 8: `tests/in-run-rulings/run-tests.sh` pins seven fragments inside the `**No fix ships unreviewed:**` range the design rewrites → the label and the fragments stay on single lines inside the range ← 2/3: r1:M3, r3:M2
- [M2] applied — §8 item 4: the heading-based `extract_rule` cannot locate a paragraph without a heading → the lead-in label `**Evidence line.**` is the anchor, extracted to the next blank line ← 1/3: r1:M1
- [M3] applied — §5.4: the M = 1 "byte-identical to earlier releases" promise (code 1292-1293, doc 855) qualified by "when every usable report declares every input `whole`" ← 1/3: r1:M2
- [M4] applied — §5.1 item 9 / §8 item 9: the example's literal tab replaced by the visible token `<tab>`; the prompt files stay tab-free ← 1/3: r2:M2
- [M5] applied — §8 item 9: examples in a prompt body are indented plain text, never a fenced block (`fill-prompt.js` truncates at a bare column-0 fence) ← 1/3: r2:M3
- [M6] applied — §2: `skills/subagent-driven-development/task-reviewer-prompt.md` named in the non-goals with its reason; it receives the paging-clause fix only ← 1/3: r2:M4
- [M7] applied — §5.3: the fallback's diff path is converted with `cygpath -m` on Windows Git Bash, by the prompt's existing sentence ← 1/3: r3:M3
- [M8] applied — §5.1: code-only elements of the shared paragraph written as labelled branches, so the identical text reads correctly in the doc prompt ← 1/3: r3:M4
- [M9] applied — §5.4: code prompt line 213 "a file:line reference into the diff" reworded to the checkout path and line, so it no longer contradicts item 2 ← 1/3: r3:M5

## Round 4 — Adversarial failure modes — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 3 Minor | r2: 0 Critical, 4 Important, 3 Minor | r3: 0 Critical, 6 Important, 2 Minor
**Sources mapped:** 22/22
**Reviewer verdict:** 0 Critical, 10 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — §2/§5.3/§9: the old stop clause stands in seven skill files, four of them orchestrating-development controller templates pinned by a second `PAGE_UNTIL_NO_PARTIAL` needle (`tests/orchestrating-development/run-tests.sh:97`, asserted at 499) → all seven carriers and both needles named; the controller-template non-goal narrowed to the clean-round rule; "the four reviewer prompts keep one paging rule" dropped ← 3/3: r1:I1, r2:I2, r3:I1
- [I2] applied — §5.3: the new clause's "or no line at all" named a size refusal as the end of the file → the clause names the shorter-than-offset answer as the end and a refusal as never the end; `HALVE_ON_REFUSAL` fragment kept ← 2/3: r1:I2, r3:I2
- [I3] applied — §5.4/§3: the fix-reviewed rule read every expected input, so a plan paged partly on a lens-1 verification cycle made a fix "unreviewed" → the rule reads the `diff` line only; the clean-round rule keeps every input; the rewritten 1202-1212 sentence follows ← 2/3: r2:I3, r3:I3
- [I4] applied — §5.4: no disposition existed for an addendum re-review that leaves nothing standing but declares the diff partial → re-review 2 when the bound allows; at the bound the addendum ends with the declarations in the log, never a new `unresolved:` item (accepted limit, §11.5) ← 1/3: r1:I3
- [I5] applied — §5.2: the two new fields never met at triage → fifth reason `input partial` for a gap- or absence-form finding whose own report declares the input partial; counted in `<r>` ← 1/3: r1:I4
- [I6] applied — §4/§5.3/§6/§7: the spec is a prompt-named input when the lens text says "read the spec listed under Target" (plan lens 1, readiness passes) → `spec` joins the expected set exactly then; the "not a prompt-named input" claim corrected ← 1/3: r2:I1
- [I7] applied — §5.3/§7: `whole` with trailing text had no row and would be *not declared* by inference → stated explicitly: a `whole` line ends after `whole`; anything after it makes the input not declared, for controller and script alike ← 1/3: r2:I4
- [I8] applied — §5.2/§3/§6/§7: an evidence-based rejection could drop a true Critical silently (a rejection is no open item; the lens returns after four rounds) → a Critical is never rejected under this rule; `(evidence: <reason>)` note on its disposition line; rejection allowed for Important only ← 1/3: r3:I4
- [I9] applied — §5.3/§5.4: a large generated file skipped on purpose made every cycle partial and the verification never-ending → an unread range may name the diff paths it covers; the fix-reviewed rule accepts a cycle whose unread ranges name no path the fix commit changed (`git show --stat --format= <sha>`); never makes a round clean ← 1/3: r3:I5
- [I10] applied — §9: `with-inputs-read` could not see a forgotten `- plan:` line → the script derives the expected set from the transcript's first user message (four sentences) and counts per expected input ← 1/3: r3:I6
- [M1] applied — §5.1 item 5: a line the branch removed from an existing file → absence form with the removed text as the pattern, or the gap form ← 2/3: r1:M3, r2:M2
- [M2] applied — §5.1 item 2: the evidence file is opened at `[REPO_ROOT]/<path>`, never a shell-relative path (worktree case) ← 1/3: r1:M1
- [M3] applied — §8 item 7: "three replacements" corrected to the code skill's four-replacements rule, lines 1466-1480 ← 1/3: r1:M2
- [M4] applied — §5.1 item 1 / §7: a finding carrying a `harness:` field needs no evidence line ← 1/3: r2:M1
- [M5] applied — §11.7 / §9: the secret form is unverifiable by design → accepted limit; the script prints `secret-form-lines` ← 1/3: r2:M3
- [M6] applied — §5.3: a hunk the Subagent Rules order skipped is not an unread range ← 1/3: r3:M1
- [M7] applied — §9/§12: the 7 unexplained transcripts were non-reviewer agents (later count: 149 reviewer transcripts, 149 with a `SubagentHandback` report, 0 `Write`-only), so the target held; no third route added ← 1/3: r3:M2

**Host self-review:** 5 merge-introduced issues fixed inline — §11 item order (a 7 before 6), §11 item 2 lacked the round-4 Critical exemption, §9 printed line lacked the `secret-form-lines` counter defined beside it, §5.2 item 3 and §6 placed the `(evidence: <reason>)` note without regard to the code skill's location-clause order (now at the `(plan-mandated)` tag's position).

_Completed — 2026-10-24 — cap reached — rounds 4, every round applied findings_
