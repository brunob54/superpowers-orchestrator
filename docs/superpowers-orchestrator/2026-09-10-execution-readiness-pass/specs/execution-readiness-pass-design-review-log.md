# Review log — execution-readiness-pass-design.md

_Invocation 1 — 2026-09-10 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 7 Important, 5 Minor | r2: 0 Critical, 5 Important, 5 Minor | r3: 0 Critical, 7 Important, 4 Minor
**Sources mapped:** 34/34
**Reviewer verdict:** 1 Critical, 9 Important, 10 Minor
**Converged:** no

### Dispositions
- [C1] applied — Gate wording / Scope: orchestration never dispatches the Phase 2 controller for N_plan = 0, so the promised pass could not run there → Phase 2 now dispatches the controller for every N_plan value; `[N_PLAN]` widened to 0–10; Phase 2 log line keeps its shape with `rounds 0 — cap`; the `skipped (N_plan=0)` form retired; Phase 0 "no controller dispatched" narrowed to N_code; anchor for the added sentence corrected ← 3/3: r1:C1, r2:I1, r3:I1
- [I1] applied — Files touched / Resume rule: `doc-review-loop-prompt.md` Deviation 2 counts every `## Round` entry and `_Loop complete — rounds <r>_` would include readiness passes → template added to Files touched; Deviation 2 defers to the skill's classification and resume rules; `rounds` and `_Loop complete_` count rotating entries only, written after the post-sequence ends ← 3/3: r1:I1, r2:I2, r3:I2
- [I2] applied — Where the sequences run: the host self-review's position relative to the post-sequence was unstated → procedure now: pre-sequence, rotating rounds, host self-review, post-sequence, report; nothing edits the plan after the post-sequence except its own triage; Deviation 1 updated; limitation 2 amended ← 3/3: r1:I2, r2:I4, r3:I5
- [I3] applied — Completeness rule: an N = 0 plan entry was both "interrupted, resumed" and "never blocks" → for plan documents an N = 0 entry follows the completeness rule (ended pre-sequence = complete and blocking; unended = resumed); the never-blocks sentence scoped to spec/general; N=0 on a resume abandons and runs a fresh pre-sequence; N = 0 entry layout fixed (invocation line, skipped line, readiness entries) ← 3/3: r1:I3, r2:I3, r3:I4
- [I4] applied — The lens cell / Error handling: no behaviour for a plan with no locatable spec → new section: the pass runs with the clause-vs-spec item removed from `[LENS_INSTRUCTIONS]` and every readiness entry carries `- note — clause-vs-spec check not run: no locatable spec` ← 3/3: r1:I6, r2:I5, r3:I6
- [I5] applied — Fields the controller reads: a header whose lens name is neither a rotation lens nor `Execution readiness` was dropped from `r` → any header not named `Execution readiness` counts as rotating ← 1/3: r1:I4
- [I6] applied — Resume rule: a readiness entry left between rotating entries after an N override had no sequence → such entries belong to no sequence and are ignored; the post-sequence is the readiness entries after the last rotating entry, numbered from 1 ← 1/3: r1:I5
- [I7] applied — Gate wording: the pinned cost sentence understates a plan review by the readiness term → plan-gate-only clause added after it: "add 2 to 6 further passes of M reviewers for the readiness sequences (1 to 3 when N is 0)"; listed in the review-gates test additions ← 1/3: r1:I7
- [I8] applied — Completeness rule vs Rollout: a complete pre-7.14.0 entry has no readiness entries and would read as interrupted → earlier-release clause: an entry whose first rotating entry has no preceding readiness entry, with r ≥ 1, keeps the old rule and owes no post-sequence; r = 0 with no readiness entry starts at pre pass 1; Rollout reworded ← 1/3: r3:I3
- [I9] applied — Triage: no rule for which side of a two-sided conflict governs → authority order spec > Global Constraints > Contract > task body; same-level conflicts the spec does not decide are `rejected: undecidable at this gate` and listed on a new `Readiness conflicts owed:` report line; Deviation 3 counts them as unresolved ← 1/3: r3:I7
- [M1] applied — Review log line: `**Converged:**` value of a readiness entry unspecified → always `no` ← 3/3: r1:M3, r2:M1, r3:M1
- [M2] applied — Review log line: position of the new line read as two positions → after `**Converged:**`, before `### Dispositions`, for every M; example to be shown in the log format ← 2/3: r1:M5, r3:M2
- [M3] applied — Evidence table: `Ruling` numbering did not match the orchestration log → column relabelled `Item` with `<ruling>/<item>` ids 1/1, 1/2, 3/1, 4/1, 4/2, 4/3; Global Constraint 11 added to 3/1 ← 2/3: r2:M4, r3:M3
- [M4] applied — Unresolved path: the skill has no unresolved path; it is Deviation 3 of the controller template → named; non-orchestration behaviour is the `Readiness conflicts owed:` line ← 1/3: r1:M1
- [M5] applied — Testing strategy: the pinned parenthetical is line-wrapped in task-reviewer-prompt.md → assertions run on whitespace-normalised text ← 1/3: r1:M2
- [M6] applied — N = 0 entry: order of the skipped line and the readiness entries unstated → invocation line, skipped line, then readiness entries ← 1/3: r1:M4
- [M7] applied — Cost bound: retries ignored → stated as a count before retries, which can double any round ← 1/3: r2:M2
- [M8] applied — Completion report: readiness results not reported → one line per sequence plus the owed line; gate outcome sentence unchanged ← 1/3: r2:M3
- [M9] applied — reviewer-prompt.md placeholder note says the lens name comes from the Lens Rotation → note amended to add `Execution readiness`; non-goal narrowed to the fenced prompt ← 1/3: r2:M5
- [M10] applied — `another pass requested`: whether both sequences run again was unstated → a fresh invocation always runs the full procedure ← 1/3: r3:M4

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 4 Important, 6 Minor | r2: 0 Critical, 4 Important, 6 Minor | r3: 0 Critical, 3 Important, 11 Minor
**Sources mapped:** 34/34
**Reviewer verdict:** 0 Critical, 8 Important, 11 Minor
**Converged:** no

### Dispositions
- [I1] applied — Gate wording: the named anchors do not exist (no cost sentence in Phase 0; the Phase 0 question has no option list; writing-plans' cost sentence belongs to the M question) → anchors quoted verbatim per gate: writing-plans sentence 1 after the N-definition sentence, sentence 2 appended to the M-question cost sentence; Phase 0 gets both as one block after the `N=0 means you skip that phase yourself` sentence ← 3/3: r1:I1, r2:I1, r3:M3
- [I2] applied — Triage / Deviation 3: the undecidable disposition was keyed on `rejected:` while Deviation 3 writes `unresolved:` lines the orchestrator reads → the line carries `undecidable at this gate — <both sides>` after the caller's prefix (`rejected:` at the writing-plans gate and direct, `unresolved:` in orchestration); the owed line, Deviation 3 and the test key on the substring ← 2/3: r1:I2, r2:I3
- [I3] applied — Where the sequences run, N = 0: whether the host self-review runs after the pre-sequence was unstated and the stated reason was untrue → the self-review runs once per invocation, after the rotating rounds or after the pre-sequence when N = 0; the post-sequence is skipped for N = 0 with the real reason; limitation 2 extended to the N = 0 self-review fixes ← 2/3: r1:I3, r3:M11
- [I4] applied — Testing strategy: the acceptance measure had no pass criterion → zero pre-flight blocks whose conflict was findable from the plan and spec alone; blocks needing repository state or implementation results do not count; recorded as an orchestration-issues case ← 2/3: r1:I4, r3:M8
- [I5] applied — Reviewer blinding: the claim that reviewers may not read skill files is false (the fenced prompt allows the rest of the repository) → section rewritten to the prompt's actual rules; the real reason for copying is that `[LENS_INSTRUCTIONS]` is filled verbatim and must be self-contained ← 2/3: r1:M1, r3:I3
- [I6] applied — Triage: the review rubric sat at no level of the authority order and the same-level rule named task bodies only → rubric inserted at level 2 (below the spec); a plan-mandated rubric defect is amended unless spec-mandated (`rejected: spec-mandated`); the same-level rule applies at every level ← 2/3: r2:I2, r3:I2
- [I7] applied — Completeness rule, earlier releases: the `r = 0, no readiness entry` resume sentence also matched N = 0 entries that the fresh-path sentence covers → the resume sentence restricted to recorded N ≥ 1; an N = 0 entry with no readiness entry always takes the fresh path ← 1/3: r2:I4
- [I8] applied — Completeness rule vs writing-plans' "a recorded N=0 is never inherited: always ask" → an N = 0 plan entry blocks or resumes only under an invocation whose N is also 0; an invocation with N ≥ 1 goes to Otherwise and runs the full procedure ← 1/3: r3:I1
- [M1] applied — Lens cell: "site" undefined → defined in the cell and in Definitions: any task step, mandated body, verification line or header field whose text the entry constrains ← 3/3: r1:M3, r2:M1, r3:M1
- [M2] applied — Review log line / Error handling: which governs when the written `<p>` disagrees with position → only the trailing clean/not clean token is read; `<pre|post>` and `<p>` are display only; position always governs ← 3/3: r1:M4, r2:M4, r3:M2
- [M3] applied — Testing strategy: pinned sentences given by meaning, and `at most three passes` absent from the body → exact strings quoted for every pin; Definitions and Architecture use `at most three passes` ← 3/3: r1:M6, r2:M6, r3:M4
- [M4] applied — Problem: "67 minutes" did not match its endpoints → 48 minutes between the Phase 2 log commit `1474b60` (19:43) and Task 1's first commit `5a47d9c` (20:31), commits named ← 2/3: r1:M2, r3:M6
- [M5] applied — Completion report / Return contract: repeats of an undecidable conflict across passes → listed and counted once per distinct conflict, in the owed line, in `unresolved` and in Deviation 3 ← 2/3: r2:M5, r3:M5
- [M6] applied — Deviation 2: an entry complete under the skill's rule but without a `_Loop complete_` line → synthesized, and the line appended ← 1/3: r1:M5
- [M7] applied — Lens cell: how the reviewer finds the spec section a clause traces to → stated in the cell: the section whose text the clause restates or implements, found from the task's stated purpose ← 1/3: r2:M2
- [M8] applied — Plan with no locatable spec: the note as a second disposition line broke the one-line clean-round rule → the note is a header line `**Note:** …` after `**Readiness pass:**` ← 1/3: r2:M3
- [M9] applied — Where the sequences run: "once in thirty logs" unsourced → labelled as an earlier count not recorded in the repository, to be treated as unverified ← 1/3: r3:M7
- [M10] applied — Fields the controller reads: "a whole line at the start of a round entry" readable as the entry's first line → copied the existing phrasing "at the start of a line of a round entry" ← 1/3: r3:M9
- [M11] applied — Cost bound: `docs/orchestration-issues.md` is local and untracked and not in Files touched → non-goal added: no edit to that file; the maintainer notes the term in row 14 ← 1/3: r3:M10

## Round 3 — Feasibility & architecture risk — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 4 Minor | r2: 1 Critical, 2 Important, 4 Minor | r3: 0 Critical, 1 Important, 5 Minor
**Sources mapped:** 18/18
**Reviewer verdict:** 1 Critical, 3 Important, 6 Minor
**Converged:** no

### Dispositions
- [C1] applied — Triage / Deviation 3: counting an undecidable conflict as Phase 2 unresolved would create a major-error stop with no resume path, while a Phase 3 pre-flight conflict is inside the in-run rulings and was settled autonomously three times on 2026-09-09 → round 2's decision reversed: the disposition is `rejected: undecidable at this gate — <both sides>` in every caller, Deviation 3 is untouched, `unresolved` keeps its meaning, and the class is left for the Phase 3 ruling path; the sentence claiming Phase 3 needs a human is removed; new accepted limitation 3 ← 2/3: r2:C1, r3:I1
- [I1] applied — Cost bound / Files touched: `docs/guide/README.md` has no cost section or cost paragraph → the guide gains one sentence in its Stage 2 (plan) section after the N and M description; the claim that an existing section names the term is removed ← 1/3: r1:I1
- [I2] applied — Where the sequences run: the writing-plans gate allows a post-gate user edit plus self-review that no readiness pass sees, and the completeness rule blocks a new pass → recorded in accepted limitation 2 as a limitation of the interactive path ← 1/3: r2:I1
- [I3] applied — Deviation 3 / tests: `tests/orchestrating-development/run-tests.sh` requires exactly one bracketed-single-letter line, byte-identical → constraint stated under the template bullet: new sentences are prose and add no such line (moot after [C1], kept as a standing constraint on template edits) ← 2/3: r2:I2, r3:M1
- [M1] applied — Testing strategy: the reviewer-templates suite has no `*_NORM` files → `assert_folded_contains` named for that suite, `*_NORM` for review-gates ← 3/3: r1:M2, r2:M2, r3:(same issue in M1 context)
- [M2] applied — reviewer-prompt.md: the header sentence above the fence also names the Lens Rotation as the only lens source → added to the edit; both lines gain the `or Execution readiness` clause ← 3/3: r1:M3, r2:M4, r3:M4
- [M3] applied — orchestrating-development: the Orchestration Log Format sentence `Skipped loops write the skipped (N_x=0) line shapes from Phase 0` still implies a Phase 2 skip → added to the Phase 0 narrowing and to Files touched ← 3/3: r1:M1, r2:M3, r3:M3
- [M4] applied — Gate wording: the quoted anchors dropped the backticks the files carry → both anchors quoted with backticks and with the line-wrap note ← 2/3: r2:M1, r3:M2
- [M5] applied — Testing strategy: the hard-coded 121 assertion count cannot be checked read-only and goes stale → replaced by "the count the suite prints today", left to the plan's verification step ← 1/3: r1:M4
- [M6] applied — Architecture: no size budget for a skill file the Phase 2 controller reads whole → 150-line budget for the additions, pinned by a test, plus a `make measure-context` reading in the acceptance case ← 1/3: r3:M5

## Round 4 — Adversarial failure modes — claude-fable-5-1
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 10 Important, 3 Minor, counts recomputed | r2: 3 Critical, 9 Important, 2 Minor, counts recomputed | r3: 2 Critical, 6 Important, 3 Minor
**Sources mapped:** 39/39
**Reviewer verdict:** 5 Critical, 16 Important, 5 Minor
**Converged:** no

### Dispositions
- [C1] applied — Definitions: a rejected finding kept a pass "not clean", so one recurring rejection made every pass of both sequences not clean, the sequence always ran to its cap and always ended on an unreviewed merge — the defect the design exists to remove → the clean-pass rule is replaced by the settled-pass rule: a pass ends the sequence when it APPLIED no Critical or Important finding and all M reports were usable; cost claims re-derived ← 3/3: r1:I4, r2:C3, r3:I6
- [C2] applied — The lens cell: the sweep had no coverage evidence, so a reviewer that enumerated nothing returned zero findings and ended the sequence at pass 1 → the cell requires a `coverage: GC<k> — <n> sites checked` line per Global Constraints entry, and a report missing any of them is unusable, so a missing sweep costs a retry and can never end a sequence ← 2/3: r2:I5, r3:C2
- [C3] applied — Triage: the authority order let the triage amend a Global Constraints entry copied verbatim from the spec, an externally pinned `**Exact content:**` body, and a plan-mandated rubric defect, deleting the human checkpoint the rubric guarantees → two levels only: fixed text (spec, spec-traceable constraints, externally pinned bodies, Contract invariants restating an external standard) is never amended; a plan-mandated rubric defect is `rejected: plan-mandated` and owed ← 3/3: r2:C1, r2:C2, r3:I2
- [C4] applied — Triage / Return contract: the closing sentence still said an undecidable conflict is "counted once in `unresolved`", contradicting two paragraphs above it and re-creating an unanswerable Phase 2 stop → deleted; the skill now states `A readiness finding never produces an unresolved: line, in any caller.` and Deviation 3 is a non-goal ← 3/3: r1:I2, r2:I1, r3:C1
- [C5] applied — Completeness rule: an earlier-release entry has zero readiness entries, which satisfied neither end condition, so an upgraded session resumed by running pre pass 1 after the rotating entries and never reached the interrupted rounds → an entry with no `## Readiness` heading and N >= 1 has both sequences ended, owes no pass and no marker, and resumes at rotating index r+1 ← 1/3: r1:C1
- [I1] applied — an installed copy older than 7.14.0 counts every `## Round` heading, so a new-format log would read as complete and skip rotating rounds silently → readiness passes get their own heading `## Readiness <pre|post> <p>`; the old reader now under-counts and re-reviews instead; this also removes the lens-name classification rule entirely ← 2/3: r2:I2, r3:I5
- [I2] applied — round 1's [I2] reversed: with the self-review before the post-sequence, every post-sequence merge was covered by no checklist and no lens → the order is rotating rounds, post-sequence, host self-review last (today's behaviour); the evidence names findings merges, not checklist fixes, as the loop-introduced conflict source ← 1/3: r3:I3
- [I3] applied — an N=0 entry was complete before the self-review ran, and no marker recorded it → `**Host self-review:** done` line; completeness requires it; resume step 4 runs it when absent ← 2/3: r2:I3, r3:M3
- [I4] applied — the owed list cannot travel in a controller return capped at 15 lines with 3 notes → the durable record is an `Owed:` block in the review log; orchestration writes at most `readiness owed: <n>`; the defective-report rule applies to the in-session gates ← 2/3: r1:I8, r3:I1
- [I5] applied — nothing verified that a reported conflict was real before it became a mandatory edit → step 0 quotes both sides from their files; `rejected: not a conflict — <side not found>` ← 1/3: r1:I1
- [I6] applied — with no locatable spec the authority order loses its top level, so every same-level conflict was undecidable: full cost, no benefit → each sequence runs at most one pass in that case, and the Global Constraints block is the second tie-break ← 2/3: r1:I3, r2:I7
- [I7] applied — plans with no Global Constraints block and legacy plans with no Contract fields had no fallback → both get the no-spec treatment: clause removed, header note written ← 1/3: r3:I4
- [I8] applied — "the Phase 3 pre-flight is the net" holds only on the SDD path; executing-plans has no whole-plan scan → accepted limitation 4, and the guide's plan stage section says so ← 1/3: r1:I5
- [I9] applied — three inconclusive passes were indistinguishable from a gate that ran → `open (all inconclusive)`, surfaced in the report, and such a run does not count for the acceptance measure ← 1/3: r1:I6
- [I10] applied — the cell called every fenced block a mandated body, contradicting the Body authority note that fenced blocks are reference implementations → check (4) covers `**Exact content:**` blocks and verbatim-ordered sentences only ← 1/3: r2:I8
- [I11] applied — one finding per failing site would make a systemic breach produce a dozen findings per reviewer → the cell asks for one finding per Global Constraints entry listing its failing sites ← 1/3: r1:I7
- [I12] applied — the completion report surfaced only owed conflicts, hiding the applied edits from the gate's single user approval → `Readiness conflicts applied:` with both sides and the amended side ← 1/3: r2:I6
- [I13] applied — the cost was stated in dispatches only, but a platform without parallel dispatch runs them one after another → said in the cost bound and in the gate clause ← 1/3: r2:I9
- [I14] rejected: the user decided at the design gate that a plan's readiness pre-sequence runs even at N = 0, and a defaults-block key is a stated non-goal — instead the cost is disclosed in the gate clause and recorded as accepted limitation 6 — no off switch for the readiness sequence ← 1/3: r1:I9
- [I15] applied — `clean` is a substring of `not clean`, so a partial read turned an open pass into a clean one → the values are `settled` and `open`, compared as whole words ← 1/3: r2:I4
- [I16] applied — Deviation 2 wrote `_Loop complete_` only after a post-sequence, which an earlier-release entry never owes, so a retried dispatch would re-run the loop → the line is written as soon as the skill classifies the entry complete, by whichever clause applied ← 1/3: r1:I10
- [M1] applied — the 150-line budget measured "file length minus 788", which ages on any unrelated edit → an absolute maximum of 938 lines, baseline 788 recorded in the assertion's comment with the release that set it ← 3/3: r1:M2, r2:M1, r3:M1
- [M2] applied — a self-contradicting spec could make two passes amend the same clause in opposite directions → a finding that reverses an amendment made earlier in the same sequence is `rejected: undecidable at this gate — spec inconsistent` ← 1/3: r1:M1
- [M3] applied — an N=0 entry blocked a later N=0 invocation even after the plan changed → the block applies only while the plan is unchanged; the marker is named as the other escape ← 1/3: r1:M3
- [M4] applied — `rounds 0 — cap` was indistinguishable from a controller that produced nothing, and the narrowing removed the meaning of `skipped (N_plan=0)` lines already written → the line reads `rounds 0 (N_plan=0) — cap`, and one sentence keeps the old form's meaning ← 1/3: r3:M2
- [M5] applied — readiness entries orphaned by an N override stayed in the log as apparent work → such an entry gains ` — superseded` on its heading ← 1/3: r2:M2

### Self-review (after the loop)
- note — Definitions / Completeness rule: "a sequence has ended when it holds three passes" contradicted the one-pass cap for a plan with no locatable spec, so such a sequence could never end → both sentences now say "as many passes as its cap (three; one when the plan has no locatable spec)"
- note — Definitions: the phrase the contract test pins, `at most three passes`, did not appear verbatim → wording aligned
- note — Files touched: `[ROUND]` is filled with a readiness pass label, so its placeholder note is a third line to edit in `reviewer-prompt.md`

_Loop complete — 2026-09-10 — rounds 4 — cap_
