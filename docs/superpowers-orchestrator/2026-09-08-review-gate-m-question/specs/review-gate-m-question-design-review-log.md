# Review log — review-gate-m-question design

_Invocation 1 — 2026-09-08 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 2 Critical, 6 Important, 2 Minor | r2: 1 Critical, 7 Important, 6 Minor | r3: 1 Critical, 6 Important, 3 Minor
**Sources mapped:** 34/34
**Reviewer verdict:** 3 Critical, 10 Important, 8 Minor
**Converged:** no

### Dispositions
- [C1] applied — §5/§7/R6: Batched Autonomous Mode routes through Core Flow step 4 ("as in the Core Flow", SDD:232-241), so the new question lands on an autonomous path → step-4 wording carries an explicit exception, R6 gains condition 3, F1 lists the path, assertion 8 added ← 2/3: r1:C1, r3:I5
- [C2] applied — §5/§7: step 4's existing "Never ask for M …" sentence was never deleted, giving a paragraph that both asks and forbids → §7 row deletes it; assertion 7 now anchors the surviving rule to the Batched Autonomous Mode section ← 2/3: r1:C2, r3:C1
- [C3] applied — §5 model wording: the subject was the review skill ("It asks for N …") and the ask was ordered after the invocation → rewritten with the gate as subject and ask-then-invoke order ← 1/3: r2:C1
- [I1] applied — R5/§6/§7: nothing said how the answered N reaches the review skill, so N would be asked twice → the gate passes `N=<n> M=<m>`; both skills' "ask once — at gate time" clauses become direct-invocation only ← 3/3: r1:I1, r2:I1, r3:I1
- [I2] applied — R6: no mechanism or owner for the once-per-gate pre-check → per-gate pre-check named; the code gate deliberately does not duplicate the mode-dependent predicate and the consequence is stated ← 3/3: r1:I2, r2:I3, r3:I2
- [I3] applied — §9 assertion 2: a byte-identical comparison cannot pass (four different wrappings, Phase 0's trailing clause) → span fixed from "the value of the" to "never a parameter", compared after whitespace collapse ← 3/3: r1:I4, r2:I4, r3:I3
- [I4] applied — §10 F1: the Phase 2 doc-review controller also reads writing-plans/SKILL.md (doc-review-loop-prompt.md:52-56) → path added to F1 with assertion 10 ← 2/3: r1:I5, r3:I4
- [I5] applied — §2/§7/§11: "five skill files" contradicted a §7 naming none → §2 names all five; §7 lists the two review-skill clauses ← 2/3: r1:I6, r2:M6
- [I6] applied — R1/R3: an invalid stated M fell in a hole (not asked, silently dropped) → an invalid stated value counts as not stated; the gate asks and says why ← 2/3: r2:I6, r3:I6
- [I7] applied — R1: a stated N=0 makes any M answer unusable → the gate asks nothing ← 1/3: r1:I3
- [I8] applied — §8: the re-entry row contradicted the skip rules it cited → split into "skill will skip" and "loop will run" rows ← 1/3: r2:I2
- [I9] applied — §5: the model wording carried no cost line while assertion 4 required one → cost line added to the wording ← 1/3: r2:I5
- [I10] applied — §2 Codex paragraph: multi-code-review refuses on Codex and Cursor (mcr:26-30), so no question is ever reached there → rewritten ← 1/3: r2:I7
- [M1] applied — R6 second bullet: the code gate falls back to the single-pass review rather than skipping (SDD:98-100) ← 2/3: r2:M2, r3:M2
- [M2] applied — §8: added a row for a session with no interactive user (headless, or dismissed question) ← 2/3: r2:M4, r3:M3
- [M3] applied — §5: option sets and pre-selected defaults now stated for both questions ← 1/3: r1:M1
- [M4] applied — §10: the orchestration path costs a third M question; noted with the §2 non-goal ← 1/3: r1:M2
- [M5] applied — §3: added the direct-invocation clause (asks N only, never M) ← 1/3: r2:M1
- [M6] applied — R1: "already stated" widened to any statement in the session since the host skill was invoked ← 1/3: r2:M3
- [M7] applied — R5: noted the resumed-invocation exception to "records a chosen M" ← 1/3: r2:M5
- [M8] applied — §3: rule qualified with "for whichever of the two the user has not already stated" ← 1/3: r3:M1

## Round 2 — Ambiguity & testability — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 6 Important, 6 Minor, counts recomputed | r2: 2 Critical, 7 Important, 8 Minor, counts recomputed | r3: 1 Critical, 4 Important, 5 Minor
**Sources mapped:** 39/39
**Reviewer verdict:** 3 Critical, 9 Important, 10 Minor
**Converged:** no

### Dispositions
- [C1] applied — §2/R5/§7: `N=<n>` is not a form either skill parses (both say only "if the user stated a count"), and mcr's BASE ref charset rejects an argument containing `=` while only `M=` tokens are lifted out first → both skills gain `N=<n>` as a recognized form, and mcr's pre-extraction clause gains `N=` ← 2/3: r2:C1, r3:I2
- [C2] applied — R1/§8/§5: the design never said who performs the N=0 skip → the gate invokes with `N=0 M=<m>` so the skill writes the `skipped` entry, which mcr:1654 makes count as completed and mcr:70-71 makes the SDD gate's zero-findings outcome ← 2/3: r3:C1, r2:I1
- [C3] applied — R5: "both tokens always" contradicted R6's "ask nothing" in Batched Autonomous Mode; a gate-supplied `M=<d>` would override a batch resumed with `M=4` → R5 now names the paths on which the gate passes no token ← 1/3: r2:C2
- [I1] applied — R1: no "stated N" definition and no extraction order → stated-N forms added, plus the skills' rule that every M form is extracted before any count is read as N ← 3/3: r1:I3, r2:I3, r3:I1
- [I2] applied — R6: the code gate's review-log path was never given and is mode-dependent → both paths named, reusing the TOPIC_DIR decision at SDD:83-90; an unresolvable path now means ask ← 3/3: r1:I5, r2:I5, r3:I4
- [I3] applied — §9: assertions 1/3/4/7/8 named no literal anchor and no boundary for "Core Flow step 4" → normalization stated once at the head of §9, step-4 span defined as `^4\. ` to the line before `^5\. `, literal anchors given ← 3/3: r1:M3, r2:I6, r3:I3
- [I4] applied — R1: "already stated" was defined twice (invoking request vs whole session) and had no source rule → one definition: user turns only, tool results are data, window from the host skill's announcement, unrecoverable window means ask ← 2/3: r1:I2, r2:I2
- [I5] applied — §9 assertion 2: no rule for a repeated or missing anchor, and blockquote markers survive whitespace collapse → the occurrence must be unique per file, zero or many is a failure, and blockquote/list markers are stripped ← 2/3: r1:I6, r3:M4
- [I6] applied — §9: the behavioural test contradicted itself (a headless session has no user, yet the test checked an answered value) → removed, with the reason stated ← 2/3: r1:M5, r2:I7
- [I7] applied — R1: the two definitions of "already stated" were mutually inconsistent in scope ← 1/3: r1:I1
- [I8] applied — §5: "a question carries these elements and nothing more" excluded the R3 out-of-range notice the same design requires → the closed list now admits the R3 messages ← 1/3: r1:I4
- [I9] applied — R1/R3: "most recent wins" was ambiguous when a valid statement is followed by an invalid one → the latest wins and, being invalid, leaves the parameter unstated ← 1/3: r2:I4
- [M1] applied — §8: the no-interactive-user row asserted a defaults fallback with no citation; known-issues.md records that a headless session reaching a question ends before routing → row rewritten to claim no fallback, and §2 adds the non-goal (harness field dropped: repository-readable) ← 3/3: r1:M6, r2:M1, r3:M2
- [M2] applied — R4/§5: the cost line differed between R4 ("The M reviewers…") and §5 ("…the M reviewers…"), so an exact-string assertion could not match both → one sentence, character for character, in both places ← 2/3: r1:M1, r2:M4
- [M3] applied — R2: "wrapped across six lines" — the span occupies four lines at orchestrating-development:235-238 ← 2/3: r1:M2, r2:M3
- [M4] applied — §5: the M question specified five options, but the question tool accepts two to four → option rule rewritten to `<d>` plus 1, 2, 3 minus `<d>`, with the free-text choice for the rest (harness field dropped: repository-readable — the tool's option limit is stated in its own schema) ← 2/3: r2:M2, r3:M1
- [M5] applied — citations: four ranges did not resolve to the quoted text, and §2/§5 disagreed on the plan-gate span → re-anchored to :36-55, :62-63, :63-65, :232-240, and one span (344-350) stated once ← 2/3: r2:M8, r3:M5
- [M6] applied — §7: the guide row offered "a table or a sentence" with no acceptance criterion → one sentence per stage narrative, no new table ← 1/3: r1:M4
- [M7] applied — §5: only the plan gate's wording was written out while assertion 2 compares all three → all three gate sentences now written in full ← 1/3: r2:M5
- [M8] applied — §7: whether brainstorming:335-339's existing once-per-gate sentence is kept was undecided → kept unchanged; the spec gate's wording points at it instead of restating it ← 1/3: r2:M6
- [M9] applied — R3: four required messages had no wording → one model sentence given per case ← 1/3: r2:M7
- [M10] applied — R4: the cost line carries no measured figure, so it prices nothing → §2 now states plainly that pricing M is out of scope and the line is orientation only ← 1/3: r3:M3

## Round 3 — Feasibility & architecture risk — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 4 Minor | r2: 0 Critical, 5 Important, 1 Minor | r3: 1 Critical, 6 Important, 3 Minor
**Sources mapped:** 24/24
**Reviewer verdict:** 1 Critical, 9 Important, 7 Minor
**Converged:** no

### Dispositions
- [C1] applied — R6/§5/§8: "ask nothing, invoke nothing" on entry-existence would make an interrupted loop unresumable and would skip the whole-branch review after HEAD moved (doc-review-loop-prompt.md:61-63 "blocks re-running a completed loop, never continuing an interrupted one"; mcr:306-319 tracked-log `abandoned` and untracked resume) → the pre-check now suppresses only the question; every gate always invokes and the skill is the sole authority on run/resume/skip ← 2/3: r3:C1, r2:I4
- [I1] applied — §9: the step-4 span `^4\. `..`^5\. ` is not unique (matches 77/131/285/301 and 101/132/302) → span anchored to the first `^4\. ` after `## Core Flow` through the line before the next `^5\. `, and the suite fails when an anchor does not resolve ← 3/3: r1:I4, r2:I1, r3:I3
- [I2] applied — §5: the code gate's shipped wording carried no once-per-gate clause while R6 and three §8 rows depended on one, and SDD has no such rule to point at → the code gate now has no pre-check and always asks, stated in both R6 and the gate text ← 2/3: r1:I1, r3:I2
- [I3] applied — §9: assertion 1's lowercase anchor could not match the code gate's capitalised "Ask", and no matching convention was stated → all three gates use the same lowercase anchor, and §9 adopts tests/writing-plans/run-tests.sh:8-11's byte-pin/free-text convention ← 2/3: r1:I3, r2:I2
- [I4] applied — R6: `<branch-slug>` was used but never defined (mcr:285-293: detached-HEAD detection, non-alphanumeric runs replaced, `detached-<sha>`), and the tracked-log condition was invisible to the gate → both cited, and the direct-mode branch dropped by removing the code gate's pre-check ← 2/3: r2:I3, r3:I5
- [I5] applied — §2/§5: step 4 opens at line 77 with its own invoke instruction, so appending a question after it leaves a step that invokes before it asks → step 4 is rewritten as a whole with the question first and one invocation ← 1/3: r1:I2
- [I6] applied — §7: `docs/FORK-IMPROVEMENTS.md:127` states the gates ask for N only, and README.md:32-33 sends users there → row added, with the neighbouring paragraphs to check ← 1/3: r2:I5
- [I7] applied — §5: the replacement texts carried none of R1's or R3's rules, and a rule written in no shipped file does not ship → a shared rules block is now part of all three gate texts, with assertion 5 pinning it ← 1/3: r3:I1
- [I8] applied — §2: Cursor was declared out of scope, but it lacks only nested dispatch (guide:53), runs session-start (hooks-cursor.json) and honours the tag (README:379) → Cursor is in scope for the two doc gates; only the code gate is unavailable there ← 1/3: r3:I4
- [I9] applied — §5: the option-count limit was asserted with no citable source in the document → restated as "at most four options, full range reachable through the free-text choice", with the limit attributed to the question tool's schema rather than to this repository (harness field dropped: settleable from a citable source) ← 1/3: r3:I6
- [M1] applied — §9: "Batched Autonomous Mode" occurs five times (6, 119, 171, 368, 407); anchoring on the first match starts at the frontmatter and makes assertion 7 vacuous → anchored to `^## Batched Autonomous Mode` ← 2/3: r1:M1, r3:M2
- [M2] applied — §1/§8: both cite files that are local and untracked, so a fresh clone cannot check them → the row-14 figures and the known-issues case are quoted inline and both files labelled local-only ← 1/3: r1:M2
- [M3] applied — §9: no portability note, though the span extraction is exactly where `/dev/stdin` or process substitution appears → note added, matching CLAUDE.md's cross-platform rule ← 1/3: r1:M3
- [M4] applied — §9 assertion 2: "a partial deletion would leave two" did not follow from a span match → the assertion now counts start-marker occurrences and fails on anything but exactly one, before extracting ← 1/3: r1:M4
- [M5] applied — §7: `N=<n>` was added only to the guide's command table → row extended to both skills' frontmatter descriptions, README:33/368 and FORK-IMPROVEMENTS ← 1/3: r2:M1
- [M6] applied — §2/§1: the code-gate span cut mid-sentence at both ends (line 91 opens with "completion message.", line 96 ends with "The"), and the M citation was 34-35 → span stated by sentence, citation corrected to 33-35 ← 1/3: r3:M1
- [M7] applied — R2: "at session start" understated the hook, registered with matcher `startup|clear|compact` (hooks/hooks.json:5) → stated outside the compared span, which explains why a lost window costs only the stated values, never `<d>` ← 1/3: r3:M3

## Round 4 — Adversarial failure modes — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 3 Important, 3 Minor | r2: 2 Critical, 4 Important, 3 Minor | r3: 1 Critical, 6 Important, 4 Minor, counts recomputed
**Sources mapped:** 27/27
**Reviewer verdict:** 3 Critical, 7 Important, 8 Minor
**Converged:** no

### Dispositions
- [C1] applied — R1: a stated value was accepted silently, so pasted text (a review-log line, a resume prompt, a guide excerpt) or a stale sentence could decide the review — and an inherited `N=0` could skip it entirely and send the branch to finishing-a-development-branch "as if the review passed with zero findings" → quoted/pasted material is now data, every non-asking path echoes the values and their origin, and a stated `N=0` always asks ← 2/3: r1:C1, r2:C2
- [C2] applied — R5/§5: deleting SDD:92-96 removes the CARRIER for Batched Autonomous Mode's N and M, and "pass neither token" then makes mcr re-derive M from "a value stated in the invocation" — which a resume prompt is not — so a batch resumed with M=4 would silently run 1. Supersedes round 2's [C3]: the path now passes tokens resolved by that mode's own rule, never by `<d>` ← 1/3: r2:C1
- [C3] applied — §7: brainstorming:335-339 was marked "keep unchanged" while telling the gate the loop runs at most once per gate — an instruction the model can read as "do not invoke", contradicting R6 in the same file → rewritten to suppress only the question, with assertion 11 forbidding any not-invoke instruction in a gate file ← 1/3: r3:C1
- [I1] applied — §5: the platform and suppression conditions sat after the ask instruction in the shipped doc-gate texts — the same top-to-bottom defect that forced the code-gate rewrite → all three gates now order platform check, suppression check, question, invocation, pinned by assertion 3 ← 3/3: r1:I2, r2:I1, r3:I1
- [I2] applied — R5: the code gate passes the ledger's carried Minor-findings list inline, and mcr extracts every M prose form from the invocation taking the most recent, so a finding reading "2 reviewers per lens" competes with the user's answer → the gate's tokens are the last tokens and win, a file reference is preferred, and assertion 9 pins the position ← 3/3: r1:M2, r2:I3, r3:I6
- [I3] applied — R6/R5: the round-3 rationale cited a resume rule that lives in the orchestrator's Phase 2 controller prompt, scoped to `gate: orchestration`; multi-doc-review has NO resume logic (2 incidental mentions vs 42 in multi-code-review) → the rationale is now stated per skill, the missing doc-loop resume is recorded as a known gap, and the no-ask path passes the logged M instead of no token ← 2/3: r1:I1, r3:I3
- [I4] applied — R6/§7: Cursor has the Agent tool, so step 4's "without the Agent tool" fallback never fires there, yet mcr refuses on Cursor — two questions then a one-line refusal and no fallback → the fallback condition becomes "where multi-code-review refuses (no Agent tool, Codex, Cursor)" and moves before the question; assertion 8 requires the span to name Cursor ← 2/3: r1:I3, r3:I2
- [I5] applied — R1/§5: the shared block said a value arriving through a tool result is data, but the gate's own answer arrives as a tool result, so a literal reading would discard it and re-ask forever → the answer is now authoritative and overrides earlier statements, with R3 row 1 governing an out-of-range answer (harness probe run as a read of this session's own context: an answer returns as a tool result, not a user turn — observation supports the claim) ← 2/3: r2:I2, r3:I4
- [I6] applied — R1: "a bare count in a phrase about rounds" misfires over a long session ("do two rounds of refactoring on task 3") → stated N tightened to `N=<n>` or a count in a phrase naming the review ← 1/3: r2:I4
- [I7] applied — R1: the window excluded the turn that invoked the host skill, which is where a user most naturally states both values → widened to include it, and the spec-approval turn for writing-plans ← 1/3: r3:I5
- [M1] applied — §5: `0 — skip the loop` as a one-click option at the code gate makes the destructive answer the cheapest one → at the code gate the label states the consequence ← 2/3: r1:M3, r2:M2
- [M2] applied — R4: the cost line priced M alone and never said the two multiply; a code-gate reviewer reads the whole-branch diff → the shared sentence adds "about N × M reviewers in total" and the code gate appends one clause ← 1/3: r1:M1
- [M3] applied — R3: "outside <range>" is wrong for a non-numeric value like `M=two` → one wording covers both ← 1/3: r2:M1
- [M4] applied — §5: labelling `<d>`=1 "recommended" would recommend the behaviour being fixed on the very machine that produced the complaint → "current default" when nothing was configured ← 1/3: r2:M3
- [M5] applied — §9 assertion 2: "the value of the" is common English and would fail the suite on unrelated future edits in four large files → marker lengthened to the `<reviewers-per-lens>` fragment ← 1/3: r3:M1
- [M6] applied — R2/§2: the hook matcher is `startup|clear|compact` and omits `resume`, so `--resume`/`--continue` re-emits no tag and `<d>` can fall to 1 where the variable says 3 → stated as a known limitation; changing three hook config files is out of scope (harness field dropped: repository-readable — the matcher is in hooks/hooks.json:5) ← 1/3: r3:M2
- [M7] rejected: harness probe not runnable here — in a Cursor session, report whether an option-based user-question tool is exposed to the model — (tool missing). The defensive clause was added regardless, since asking the same two questions in plain text is safe whether or not the premise holds ← 1/3: r3:M3
- [M8] applied — R2: no branch existed for a `<d>` outside 1–5 on a platform that does not run the hook → `<d>` outside 1–5 is 1 ← 1/3: r3:M4

_Loop complete — 2026-09-08 — rounds 4_
