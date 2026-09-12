## Round 1

Findings addressed: I1, I2, I3, I4, I5, M1.

Command:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/fill-prompt/run-tests.sh
```

Output (tail of each):
```
=== reviewer-templates ===
Results: 162 passed, 0 failed

=== orchestrating-development ===
Results: 164 passed, 0 failed

=== review-gates ===
Results: 132 passed, 0 failed

=== writing-plans ===
Results: 15 passed, 0 failed

=== fill-prompt ===
Results: 166 passed, 0 failed
```

## Round 1

Findings addressed: L1, L2, L3.

Command:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/fill-prompt/run-tests.sh
```

Output (tail of each):
```
=== reviewer-templates ===
Results: 163 passed, 0 failed

=== orchestrating-development ===
Results: 164 passed, 0 failed

=== review-gates ===
Results: 132 passed, 0 failed

=== writing-plans ===
Results: 15 passed, 0 failed

=== fill-prompt ===
Results: 166 passed, 0 failed
```

## Round 2

Findings addressed: I1, I2, I3, I4, I5, I6, I7, I8, M1, M2, M3.

Command:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/fill-prompt/run-tests.sh
```

Output (tail of each):
```
=== reviewer-templates ===
Results: 163 passed, 0 failed

=== orchestrating-development ===
Results: 164 passed, 0 failed

=== review-gates ===
Results: 132 passed, 0 failed

=== writing-plans ===
Results: 15 passed, 0 failed

=== fill-prompt ===
Results: 166 passed, 0 failed
```

## Round 3

Findings addressed: I1, M1, M2.

Command:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/fill-prompt/run-tests.sh
```

Output (tail of each):
```
=== reviewer-templates ===
Results: 163 passed, 0 failed

=== orchestrating-development ===
Results: 164 passed, 0 failed

=== review-gates ===
Results: 132 passed, 0 failed

=== writing-plans ===
Results: 15 passed, 0 failed

=== fill-prompt ===
Results: 166 passed, 0 failed
```

## Round 4

Findings addressed: I1, I2, I3, I4, I5, M1, M2.

Needle match counts measured before finishing (folded grep, target file in
parentheses):
```
1 :: the cap is one instead of three when the plan has no locatable spec (multi-doc-review/SKILL.md)
1 :: applied** no Critical and no Important finding and all M reviewers returned a usable report (multi-doc-review/SKILL.md)
1 :: a re-run started by the `another pass requested` marker is a fresh invocation for this rule (multi-doc-review/SKILL.md)
1 :: run a **readiness sequence** before rotating round 1 (multi-doc-review/SKILL.md)
1 :: when N ≥ 1, a second after the last rotating round (multi-doc-review/SKILL.md)
1 :: amend the plan side, `applied` (multi-doc-review/SKILL.md)
1 :: amend the side the spec decides against; failing that, the side the Global Constraints block decides against (multi-doc-review/SKILL.md)
1 :: A readiness finding is disposed under the skill's "Triage of a readiness finding", never logged as unresolved. (doc-review-loop-prompt.md)
1 :: and append the `_Loop complete_` line when it is absent. (doc-review-loop-prompt.md)
1 :: The controller is dispatched for every `N_plan` value, 0 included (orchestrating-development/SKILL.md)
1 :: returns `rounds=0 outcome=cap unresolved=0` (orchestrating-development/SKILL.md)
0 :: Execution readiness, in the Lens Rotation table range (line 737..746 of multi-doc-review/SKILL.md) — the new assert_folded_not_contains passes today and would fail if a row named it
```

Command:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/fill-prompt/run-tests.sh
```

Output (tail of each):
```
=== reviewer-templates ===
Results: 173 passed, 0 failed

=== orchestrating-development ===
Results: 166 passed, 0 failed

=== review-gates ===
Results: 132 passed, 0 failed

=== writing-plans ===
Results: 15 passed, 0 failed

=== fill-prompt ===
Results: 166 passed, 0 failed
```

## Round 4

Findings addressed: I1, I2, M1, M2, M3.

All fixes are additive assertions in `tests/reviewer-templates/run-tests.sh`
(section 15's needle loop and section 17), plus, for M1, replacing an inert
`else` branch with a `bad` call in the same file. No other file was edited.

### Needle-match verification (folded grep against target file, before adding assertions)

```
$ fold_file() { awk '{ line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line); if (NR > 1) printf " "; printf "%s", line } END { print "" }' "$1"; }
$ fold_file skills/multi-doc-review/SKILL.md > /tmp/folded_skill.txt
$ grep -oF '**Never use the absence of a `## Readiness` heading as that test.**' /tmp/folded_skill.txt | wc -l
1
$ grep -oF 'For a plan document N = 0 is an ordinary value' /tmp/folded_skill.txt | wc -l
1
$ grep -oF 'continues the interrupted entry under the resume order' /tmp/folded_skill.txt | wc -l
1
$ grep -oF 'For a `spec` or a `general` document, `N=0` abandons the interrupted entry instead of resuming it and is handled under **Otherwise** below (which logs the `skipped` entry), not here.' /tmp/folded_skill.txt | wc -l
1
$ grep -oF 'the controller writes at most one note instead, `readiness owed: <n>`' /tmp/folded_skill.txt | wc -l
1
$ grep -oF '`gate: orchestration`' /tmp/folded_skill.txt | wc -l
2
$ fold_file skills/orchestrating-development/doc-review-loop-prompt.md > /tmp/folded_loop.txt
$ grep -oF 'today that is one command, `git hash-object "<plan path>"`, and nothing else.' /tmp/folded_loop.txt | wc -l
1
```

Every needle matches its target file exactly once (`gate: orchestration` matches
twice, both legitimate: the invoker enum at SKILL.md:382 and the compact-report
sentence at SKILL.md:622-624), confirming each new assertion can pass today
and is not a needle that can never match.

### M1 — `bad`-branch reachability check

Verified with an isolated scratch script (`/tmp/lens_test.sh`), never touching
the real `skills/multi-doc-review/SKILL.md`, replicating the exact condition
now in `tests/reviewer-templates/run-tests.sh`:

```
$ bash /tmp/lens_test.sh
BAD: range could not be resolved (lens-rotation='1' lens-instructions='')
caseA: bad_called=1 rot=1 instr=
BAD: range could not be resolved (lens-rotation='3' lens-instructions='1')
caseB: bad_called=1 rot=3 instr=1
caseC: bad_called=0 rot=1 instr=3
```

Case A (heading `## Lens Instructions` missing/renamed) and case B (headings
inverted) both call `bad`; case C (today's real order: `## Lens Rotation` at
SKILL.md:737 before `## Lens Instructions` at SKILL.md:746) does not call
`bad` and takes the `extract_lines` branch, matching the current passing
state of the suite.

### Covering tests (after the fixes)

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 180 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 166 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed

$ bash tests/fill-prompt/run-tests.sh
Results: 166 passed, 0 failed
```

All five covering suites pass. `skills/multi-doc-review/SKILL.md` remains at
1079 lines (section 16's own check: `multi-doc-review SKILL.md is 1079 lines
(max 1080)` — PASS), confirming no line was added to that file, per the
constraint that this dispatch may only add test assertions.

No finding was left unfixed; none of the findings were instructions rather
than defects; no secret-bearing finding was present in this batch.

## Round 4

Findings addressed: [I1], [I2].

### [I1] — tests/reviewer-templates/run-tests.sh, section 15, `'has ended'` needle

The `'has ended'` needle in the section-15 for-loop (line 513) is also
matched by two unrelated sentences at `skills/multi-doc-review/SKILL.md:985`
and `:988` ("its pre-sequence has ended and the self-review marker is
present" / "... its pre-sequence has ended, its post-sequence has ended
..."), so the loop assertion stays green even if the sequence-end
definition sentence at `SKILL.md:989` ("A sequence **has ended** when its
last pass reads `**Result:** settled` or it holds at least as many passes as
its cap.") is deleted or reworded.

Fix: added one `assert_folded_contains` immediately after the `done` that
closes that for-loop (now at `tests/reviewer-templates/run-tests.sh:530`),
pinning the fragment `A sequence **has ended** when its last pass reads`
against `$DOC_SKILL` (the whole file, matching how the existing loop
assertions are matched). The existing `'has ended'` needle and every other
assertion in the loop were left unchanged.

Falsifiability check — folded grep count of the new needle against the
whole file:

```
$ fold_file skills/multi-doc-review/SKILL.md | grep -oF 'A sequence **has ended** when its last pass reads' | wc -l
1
```

Matches exactly once.

### [I2] — tests/reviewer-templates/run-tests.sh, section 12, Execution readiness lens cell

The clause-removal table (`SKILL.md:684`) and the paragraph above it
(`SKILL.md:696`, `:701`) quote the lens cell verbatim as the anchors a
controller uses to find text to remove: "the paragraph beginning `For check
(5) report ONE finding`" and "the sentence beginning `Coverage, ambiguity,
feasibility`". Neither anchor was pinned on the cell side before this fix;
section 12 pinned only the shorter substring `report ONE finding per Global
Constraints entry` (without the `For check (5) ` prefix), and the closing
sentence `Coverage, ambiguity, feasibility and style belong to the other
lenses` (`SKILL.md:844`) was asserted nowhere.

Fix: added two `assert_folded_contains` assertions against `$READINESS_CELL`
(the extracted Execution readiness cell variable section 12 already builds),
placed immediately after the existing paired assertions block — right after
the `"task-reviewer-prompt.md: still carries the rubric-defect
parenthetical"` assertion and before the `for numbered in ...` loop (now at
`tests/reviewer-templates/run-tests.sh:391-397`):

- `For check (5) report ONE finding`
- `Coverage, ambiguity, feasibility and style belong to the other lenses`

No existing assertion was changed.

Falsifiability check — folded grep count of each new needle against the
extracted cell:

```
$ fold_file /tmp/readiness-cell.txt | grep -oF 'For check (5) report ONE finding' | wc -l
1
$ fold_file /tmp/readiness-cell.txt | grep -oF 'Coverage, ambiguity, feasibility and style belong to the other lenses' | wc -l
1
```

Both match exactly once.

### Covering tests (after the fixes)

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 183 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 166 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed

$ bash tests/fill-prompt/run-tests.sh
Results: 166 passed, 0 failed
```

All five covering suites pass. No existing assertion text changed;
`MDR_MAX_LINES=1080` untouched; `skills/multi-doc-review/SKILL.md` was not
edited. No finding was left unfixed; neither finding was an instruction
rather than a defect; no secret-bearing finding was present in this batch.

## Round 4

Findings addressed: I1, I2, I3.

Added 8 new `assert_folded_contains` needles inside the existing section-13
needle loop of `tests/reviewer-templates/run-tests.sh` (the `for needle in
... done` loop under `bold "13. Readiness sequences in the multi-doc-review
procedure"`):
- 3 whole-row needles for the clause-removal table's fallback rows
  (`check (3)`, the Global Constraints row naming `check (5)` and its
  paragraph, `check (4)`), pinning both the `Missing` and `Clause removed`
  columns together with the already-pinned `Note line` column.
- 2 needles for the `<k>` numbering rule: the 1-based-position sentence and
  the repeated-or-out-of-range-counts-as-missing sentence.
- 1 needle for the whole Execution-readiness lens-wiring sentence
  (`[LENS_NAME]` / `[LENS_INSTRUCTIONS]` / `[ROUND]` mapped together).
- 2 needles for the Error Handling bullet: the tier sentence
  (`Invalid N (not an integer 0–10) → tier 2, else tier 3.`) and the
  `N = 0 → skip the rotating loop, log;` clause. The already-pinned clause
  `for a plan document the Execution readiness pre-sequence still runs`
  (pinned at :428 and :495) was deliberately not re-pinned.

Only `tests/reviewer-templates/run-tests.sh` was edited;
`skills/multi-doc-review/SKILL.md` and all plan/spec/docs files were left
untouched, per the findings' scope notes.

Sanity check (not part of the covering-test evidence below): temporarily
mutated the tier sentence's `tier 3` to `tier 9` and re-ran the suite — the
new needle failed as expected, confirming the needle is not vacuously true;
the file was then restored before the covering-test run below.

Covering tests run and their output:

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 191 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 166 passed, 0 failed
```

All three required suites pass. No finding was left unfixed. No finding was
an instruction rather than a defect. No secret-bearing finding was present
in this batch.

## Round 5

Findings addressed: I1, I2, I3, M1, M5.

- **I1** — `skills/multi-doc-review/SKILL.md`, once-per-gate interrupted test
  (originally lines 322-324). Qualified the interrupted test to `spec` or
  `general` documents only, and added a sentence stating a plan entry
  reaches the plan clause of the next sentence unconditionally, never
  through this test. This lets `Readiness entries` decide completeness for
  every plan entry, including one finished under an N = 0 resume override.
- **I2** — `skills/multi-doc-review/SKILL.md`, **On a resume** section
  (originally lines 357-363). Removed the `spec`/`general` qualifier from
  the sentence establishing the resumed round range (`r+1` through N) and
  the `## Round <i>` header numbering, so it applies to every document
  type. Reworded the plan-document sentence so `Readiness entries` below
  decides only which stage — pre-sequence, rotating rounds, post-sequence
  or the marker — runs first; the range and numbering rule is not
  duplicated.
- **I3** — `skills/multi-doc-review/SKILL.md`, Step 0 of `### Triage of a
  readiness finding` (originally lines 706-710). Added a clause exempting
  a check (2) finding (the plan mandates a rubric defect): it has only one
  side any file holds — the plan's mandated text — so Step 0 now quotes
  that text alone and disposes it with the `plan-mandated` row, without
  requiring a second side to be found.
- **M1** — `skills/multi-doc-review/SKILL.md` size budget. Reflowed the
  three paragraphs touched by I1, I2 and I3 (the `**Once per gate:**`
  paragraph, the `**On a resume**` paragraph, and the Step 0 paragraph) to
  fill lines up to the width already used elsewhere in the file (~88
  columns), per Global Constraint 1 Move 1. No wording changed, only line
  breaks. Checked first that no line in any of the three paragraphs is
  matched by `assert_file_has_line` or `assert_file_contains` in
  `tests/reviewer-templates/run-tests.sh` (all matches in these paragraphs
  use `assert_folded_contains`, which tolerates the reflow) before
  reflowing. The six exception lines Global Constraint 1 lists were not
  touched (none fall inside the three reflowed paragraphs). File line count
  after all edits: 1074 (budget: at most 1080).
- **M5** — `RELEASE-NOTES.md:36`. Changed `sweep can never end a sequence`
  to `sweep can never settle a sequence`, matching the corrected wording at
  `skills/multi-doc-review/SKILL.md` ("can never settle a sequence").

No finding was left unfixed. No finding was an instruction rather than a
defect. No secret-bearing finding was present in this batch.

Covering tests run and their output:

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 191 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 166 passed, 0 failed

$ bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed

$ bash tests/fill-prompt/run-tests.sh
Results: 166 passed, 0 failed
```

All five required suites pass.

## Round 6

Findings addressed: [I1] [I2] [I3] [I4] [I5] [I6] [I7] [I8] [M1].

- **I1** — `skills/multi-doc-review/SKILL.md`, Completeness rule (Review Log
  Format). Replaced the `**Converged:** yes` / `r` ≥ recorded N branch with
  "or when its pre-sequence has ended, its post-sequence has ended (N ≥ 1)
  and that marker is present, however its rotating rounds ended" — the same
  "however its rotating rounds ended" clause the interrupted test already
  used — so the interrupted test and the completeness rule are exact
  complements. The previously uncovered input (pre ended, post ended,
  marker present, recorded N ≥ 1, not converged, r < recorded N, from a
  resume that lowered N) is now complete.
- **I2** — `skills/multi-doc-review/SKILL.md`, Execution readiness lens
  cell, check (5) paragraph. Added the `<k>` numbering rule and the
  ordering requirement directly into the reviewer-facing text: "`<k>` is an
  entry's 1-based position among the block's top-level list items, in
  document order" and "one line per position, in that order" before the
  `coverage: GC<k> — <n> sites checked` shape. The reviewer now reads the
  same definition the controller validates against. The
  byte-identical shape and the clause-removal row at line ~676 both still
  apply.
- **I3** — `skills/orchestrating-development/SKILL.md`, Phase 2 and Phase
  5. Phase 2 now records the controller's `readiness owed: <n>` note in its
  orchestration log entry when present. Phase 5's report list now names
  "readiness conflicts owed — the plan-review log's `Owed:` block, listed
  verbatim, or `none`" beside the existing harness-probes-owed item. No
  token was added to `REVIEW_DONE`, the orchestrator does not stop on an
  owed conflict, and the meaning of `unresolved` is unchanged.
- **I4** — `skills/multi-doc-review/SKILL.md`, `Fields read`. Scoped the
  `## Round`-heading "before the first or after the last" test to "of this
  invocation entry" and changed "with none logged" to "with none logged in
  this entry" — matching the file's existing scoped definition of `r`. This
  fixes the two misclassifications the finding named (a second N = 0
  invocation, and a redo appended after an interrupted run).
- **I5** — `skills/multi-doc-review/SKILL.md`, accepted-by-design note
  (Completeness). Added the shorter of the two proposed fixes: "except that
  a resume reopening an already-ended sequence this way must also re-run
  the host self-review and rewrite `plan-blob` before the entry counts as
  complete."
- **I6** — `skills/multi-doc-review/SKILL.md`, Global Constraints
  clause-removal row explanation. Added "The row fires the same way when
  the block is present but holds no recognised top-level list item, since
  that also leaves zero entries to cover." The pinned row text at the table
  itself (line ~676) was left untouched — the new sentence sits in the
  explanatory paragraph below it, so the pinned needle and the
  `**Note:**` line stay intact while the row's condition is broadened.
- **I7** — `skills/multi-doc-review/SKILL.md`, `## Error Handling`.
  Narrowed the bullet so a readiness entry with a missing or malformed
  `**Result:**` line "leaves its sequence open, not ended, but counts
  toward nothing, including the pass count, once a resume supersedes it" —
  removing the contradiction with `Fields read`'s "counts toward nothing,
  including the pass count." Both pinned needles ("a readiness entry with a
  missing or malformed" and "as a round is") survive.
- **I8** — `skills/multi-doc-review/SKILL.md`, `### Triage of a readiness
  finding`. Added a new paragraph after the disposition table: "A check (5)
  finding has one fixed side, the Global Constraints entry, and one or more
  plan sides, its listed failing sites; `applied` requires every listed
  site amended, and a finding with any site left unamended is disposed
  `rejected: undecidable at this gate`, naming the sites left."
- **M1** — `tests/reviewer-templates/run-tests.sh:644-652`. No change: after
  applying I1/I2/I4/I5/I6/I7/I8 and reflowing the touched paragraphs at the
  file's normal width (rewrap only, no wording removed — the six
  whole-line-pinned exceptions of Global Constraint 1 were left untouched),
  `skills/multi-doc-review/SKILL.md` measures exactly 1079 lines, matching
  the comment's existing "added 291" (788+291=1079) and "the file now
  stands at 1079" figures. The comment was already correct against the
  post-fix file, so nothing needed rewriting.

No finding was left unfixed. No finding was an instruction rather than a
defect. No secret-bearing finding was present in this batch.

Covering tests run and their output:

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 191 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 166 passed, 0 failed

$ bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed

$ bash tests/fill-prompt/run-tests.sh
Results: 166 passed, 0 failed
```

All five required suites pass.

## Round 8

Findings addressed: [I1] [M1] [M4].

- **I1** — `tests/orchestrating-development/run-tests.sh`. The two
  consumer sentences of the `readiness owed` contract
  (`skills/orchestrating-development/SKILL.md:492-493` and `:644-645`)
  carried no assertion. Added `H_ORCHLOG='## Orchestration Log Format'`
  beside the other heading variables, a `PHASE5_RANGE` work file, and its
  `extract_range "Phase 5" ... "$H_PHASE5" "$H_ORCHLOG" "$PHASE5_RANGE"`
  call in section 0. Added
  `assert_folded_contains "phase 2: records the controller's readiness
  owed note in the same log entry" "$PHASE2_RANGE"` for "When the
  controller's report carries a `readiness owed: <n>` note, Phase 2
  records it in the same log entry." at the end of section 9, and a new
  section 10 ("Phase 5 reports readiness conflicts owed") with
  `assert_folded_contains "phase 5: readiness conflicts owed report item"
  "$PHASE5_RANGE"` for "readiness conflicts owed — the plan-review log's
  `Owed:` block, listed verbatim, or `none`". Both `assert_folded_contains`
  calls, never `assert_file_contains`/`assert_file_has_line`, per the
  finding's no-reflow constraint. Sanity-checked outside the suite that
  each needle fails against a text sample with the sentence absent and
  passes against the real extracted range — see the fix subagent's final
  message for the two ad hoc grep checks.
- **M1** — `tests/reviewer-templates/run-tests.sh:419-420` (section 13's
  loop). The bare-word needles `'pre-sequence'` and `'post-sequence'`
  matched 18 and 8 substring occurrences respectively and could not fail
  while any sentence of the feature survived anywhere in the file.
  Replaced them with the two trigger sentences: `'run the pre-sequence of
  \`Readiness sequences\` below before round 1'` (not asserted anywhere
  else in the suite) and `'with N = 0 there is no post-sequence, and on a
  resume the resume rule of \`Readiness entries\` decides whether it has
  already ended'` (a different fragment from the trigger sentence already
  pinned at line ~447, so this is new coverage, not a duplicate). Kept
  `assert_folded_contains`; no other needle in the loop was touched.
- **M4** — `tests/review-gates/run-tests.sh:532`. Renumbered the section
  label from `"15. The plan gates carry the Execution readiness
  sentences"` to `"16. ..."` — the next free label after the pre-existing
  `"15. Guard sentences on the sidecar-log untrusted-read path"` at line
  237. Label text only; no assertion in the section was changed.

No finding was left unfixed. No finding was an instruction rather than a
defect. No secret-bearing finding was present in this batch.

Covering tests run and their output:

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 191 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 169 passed, 0 failed

$ bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed

$ bash tests/fill-prompt/run-tests.sh
Results: 166 passed, 0 failed

$ bash tests/in-run-rulings/run-tests.sh
Results: 512 passed, 0 failed
```

All five required suites pass, plus the additionally requested
`tests/in-run-rulings/run-tests.sh` (cited by [I1] as the convention being
followed).

## Round 8

Findings addressed: [I1]

[I1] — tests/reviewer-templates/run-tests.sh:555-556 — The assertion
"multi-doc-review SKILL.md: invocation note admits the gate: orchestration
invoker" pinned the needle `` `gate: orchestration` `` alone, which occurs
twice in the folded skills/multi-doc-review/SKILL.md file (once in the
invocation-note invoker list, once in the completion-report paragraph
already covered by the preceding assertion), so it could never fail on its
own. Changed the needle to the longer fixed string
`` `gate: writing-plans` | `gate: orchestration` | `direct` `` , which
occurs exactly once in the folded file, inside the invocation-note invoker
alternation (skills/multi-doc-review/SKILL.md:373-374).

Verification that the needle occurs exactly once in the folded file, before
committing:

```
$ awk '{ line = $0; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line); if (NR > 1) printf " "; printf "%s", line } END { print "" }' skills/multi-doc-review/SKILL.md > /tmp/folded.txt
$ grep -oF '`gate: writing-plans` | `gate: orchestration` | `direct`' /tmp/folded.txt | wc -l
       1
```

Verification that the assertion fails when the invoker list is altered
(reverted before commit; skills/multi-doc-review/SKILL.md carries no diff):

```
$ sed -i '' 's/`gate: writing-plans` | `gate: orchestration` | `direct`/`gate: writing-plans` | `gate: orchestrationX` | `direct`/' skills/multi-doc-review/SKILL.md
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -i "invocation note admits"
  FAIL: multi-doc-review SKILL.md: invocation note admits the gate: orchestration invoker (missing: `gate: writing-plans` | `gate: orchestration` | `direct`)
```

Covering tests (after reverting the sanity-check edit above), all end with
0 failed:

```
$ bash tests/reviewer-templates/run-tests.sh
Results: 191 passed, 0 failed

$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 0 failed

$ bash tests/orchestrating-development/run-tests.sh
Results: 169 passed, 0 failed

$ bash tests/writing-plans/run-tests.sh
Results: 15 passed, 0 failed

$ bash tests/fill-prompt/run-tests.sh
Results: 166 passed, 0 failed
```

## Round 8

Findings addressed: I1.

Fix: added one `assert_folded_contains` in tests/reviewer-templates/run-tests.sh
section 15, pinning the sentence "The rest of the entry is the round-entry
body above under the same rules, with no `**Converged:**` line." (skills/multi-doc-review/SKILL.md
lines 958-960). Verified before committing: the needle occurs exactly once in
the folded file, and the assertion fails when that sentence is removed (tested
on a scratch copy, then restored — `git status --porcelain` showed no diff
afterward).

Command:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/review-gates/run-tests.sh
bash tests/orchestrating-development/run-tests.sh
bash tests/writing-plans/run-tests.sh
bash tests/fill-prompt/run-tests.sh
```

Output (tail of each):
```
=== tests/reviewer-templates/run-tests.sh ===
Results: 192 passed, 0 failed

=== tests/review-gates/run-tests.sh ===
Results: 132 passed, 0 failed

=== tests/orchestrating-development/run-tests.sh ===
Results: 169 passed, 0 failed

=== tests/writing-plans/run-tests.sh ===
Results: 15 passed, 0 failed

=== tests/fill-prompt/run-tests.sh ===
Results: 166 passed, 0 failed
```

## Round 8

Findings addressed: [I1].

Fix: two assertions added in `tests/review-gates/run-tests.sh` (after the
`orchestrator no longer narrows both phases with one N=0 sentence`
assertion) pin the surviving `N_code=0` half of the split Phase 0 sentence
and its `skipped (N_code=0)` log shape, using the suite's folded-needle
helper `assert_icontains` against the normalized Phase 0 span.

Covering tests:

```
$ bash tests/review-gates/run-tests.sh
Results: 134 passed, 0 failed
(exit status 0)
```

Negative check (temporary deletion of the `N_code=0` half of the Phase 0
sentence in `skills/orchestrating-development/SKILL.md`, then restored):

```
$ bash tests/review-gates/run-tests.sh
Results: 132 passed, 2 failed
  - orchestration Phase 0 keeps the N_code=0 half (missing: N_code=0 means you skip Phase 4 yourself)
  - orchestration Phase 0 names the skipped (N_code=0) log shape (missing: `## Phase 4 — Code review — skipped (N_code=0)`)
```

## Round 8

Findings addressed: [I1].

Fix: one assertion added to section 17 of
`tests/reviewer-templates/run-tests.sh` (beside the existing section 17
assertions, after the "appends the Loop complete line when it is absent"
assertion), using `assert_folded_contains` to pin the clause in Deviation 2
of `skills/orchestrating-development/doc-review-loop-prompt.md`: "by
whichever of its clauses applied, the clause for an entry written by an
earlier release included, which owes no post-sequence".

Verification run 1 (temporary deletion of that clause from
`skills/orchestrating-development/doc-review-loop-prompt.md`):

```
$ bash tests/reviewer-templates/run-tests.sh
...
17. The doc-review-loop controller template accepts N_PLAN = 0
  PASS: doc-review-loop template: [N_PLAN] range starts at 0
  PASS: doc-review-loop template: host self-review after the post-sequence
  PASS: doc-review-loop template: counts rotating entries only
  PASS: doc-review-loop template: defers to the skill's completeness rule
  PASS: doc-review-loop template: Deviation 3 is unchanged
  PASS: doc-review-loop template: controller may run read-only inspection commands
  PASS: doc-review-loop template: the read-only allowance is restricted to one command
  PASS: doc-review-loop template: readiness finding disposed under triage, never logged as unresolved
  PASS: doc-review-loop template: appends the Loop complete line when it is absent
  FAIL: doc-review-loop template: the earlier-release clause of the completeness rule owes no post-sequence (missing: by whichever of its clauses applied, the clause for an entry written by an earlier release included, which owes no post-sequence)

Results: 192 passed, 1 failed
```

Exactly the one new assertion failed; no other assertion in the suite was
affected.

Verification run 2 (template file restored with
`git checkout -- skills/orchestrating-development/doc-review-loop-prompt.md`,
confirmed unchanged via `git status --short`, then the suite re-run):

```
$ bash tests/reviewer-templates/run-tests.sh
...
17. The doc-review-loop controller template accepts N_PLAN = 0
  PASS: doc-review-loop template: [N_PLAN] range starts at 0
  PASS: doc-review-loop template: host self-review after the post-sequence
  PASS: doc-review-loop template: counts rotating entries only
  PASS: doc-review-loop template: defers to the skill's completeness rule
  PASS: doc-review-loop template: Deviation 3 is unchanged
  PASS: doc-review-loop template: controller may run read-only inspection commands
  PASS: doc-review-loop template: the read-only allowance is restricted to one command
  PASS: doc-review-loop template: readiness finding disposed under triage, never logged as unresolved
  PASS: doc-review-loop template: appends the Loop complete line when it is absent
  PASS: doc-review-loop template: the earlier-release clause of the completeness rule owes no post-sequence

Results: 193 passed, 0 failed
```

The template file `skills/orchestrating-development/doc-review-loop-prompt.md`
ends unchanged (not part of this commit); only
`tests/reviewer-templates/run-tests.sh` was modified and committed.

## Round 8

Findings addressed: [I1], [I2]. Both are changes to
`tests/reviewer-templates/run-tests.sh` only; `skills/multi-doc-review/SKILL.md`
was mutated only in temporary, restored copies during verification and ends
this round byte-identical to the committed version.

### [I1]

Fix: three folded needles added with `assert_folded_contains` (the helper
defined at `tests/reviewer-templates/run-tests.sh:102`) in section 12
("Execution readiness lens cell"), all asserted against `$READINESS_CELL`
since the three clauses all lie inside that cell:

- `tests/reviewer-templates/run-tests.sh:406` (new) — needle
  `a number missing from the list was removed on purpose for this plan —
  never reconstruct it`, copied verbatim (em dash, not the semicolon the
  finding text paraphrased it with) from
  `skills/multi-doc-review/SKILL.md:820-821`. Placed directly after the
  `for numbered in ...; do ... done` loop, next to its neighbouring
  `Run all the checks below` needle.
- `tests/reviewer-templates/run-tests.sh:411` (new) — needle
  `Write that block as the last lines of your report`, copied verbatim from
  `skills/multi-doc-review/SKILL.md:840`. Placed directly after the existing
  "coverage line shape" / "missing coverage line is discarded" needles.
- `tests/reviewer-templates/run-tests.sh:441` (new) — needle `Removing a
  clause never renumbers the checks that remain: the numbers of the
  surviving checks are left exactly as they are`, copied verbatim (folded
  across its line break) from `skills/multi-doc-review/SKILL.md:679-680`.
  This clause (the no-renumbering paragraph) sits at
  `skills/multi-doc-review/SKILL.md:679-684`, outside the `**Execution
  readiness**` lens cell (the cell is lines 817-848) and inside the
  `### Readiness sequences (plan documents only)` subsection that section 13
  already covers with `assert_folded_contains` against the whole file
  `$DOC_SKILL` — no narrower already-resolved range exists for that
  subsection, so this needle was added as a new element of section 13's
  existing `for needle in ...; do` array, next to the neighbouring
  clause-removal table-row needles, asserted against `$DOC_SKILL` like its
  neighbours.

Note on the finding's location text: the finding names all three clauses as
belonging to "the existing section 13 assertions for the readiness lens
cell", but `skills/multi-doc-review/SKILL.md:404` (the line the finding
cites) falls inside the block labelled `bold "12. Execution readiness lens
cell"`, not `bold "13. ..."`; clauses (a) and (c) are inside the lens cell
cell text itself, so they were pinned in section 12 against `$READINESS_CELL`
per the finding's own disambiguating instruction ("`$READINESS_CELL` for
text inside the lens cell, ... the narrowest already-resolved range that
holds it otherwise"); clause (b) is not inside the cell, so it was pinned in
section 13 against `$DOC_SKILL`, the range its neighbours already use.

Verification (one clause at a time, on the real file, backed up first and
restored with `cp` from the backup, never `git checkout`, so the check-out
path was never exercised on a clean-but-uncommitted repo):

```
$ cp skills/multi-doc-review/SKILL.md /tmp/SKILL.md.orig
$ shasum skills/multi-doc-review/SKILL.md /tmp/SKILL.md.orig
041eef60aa9f27d71e4c9bc8c61044b8  skills/multi-doc-review/SKILL.md
041eef60aa9f27d71e4c9bc8c61044b8  /tmp/SKILL.md.orig
```

Clause (a) — replaced `Run all the checks below; a number missing from the\n  list was removed on purpose for this plan — never reconstruct it:\n` with `Run all the checks below:\n`:

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E "FAIL|Results"
  FAIL: Execution readiness cell: missing-number-was-removed-on-purpose clause (missing: a number missing from the list was removed on purpose for this plan — never reconstruct it)
Results: 195 passed, 1 failed
```

Restored (`cp /tmp/SKILL.md.orig skills/multi-doc-review/SKILL.md`) — suite
green again: `Results: 196 passed, 0 failed`.

Clause (b) — deleted the six-line no-renumbering paragraph
(`skills/multi-doc-review/SKILL.md:679-685` including its trailing blank
line):

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E "FAIL|Results"
  FAIL: multi-doc-review SKILL.md: procedure carries 'Removing a clause never renumbers the checks that remain: the numbers of the surviving checks are left exactly as they are' (missing: Removing a clause never renumbers the checks that remain: the numbers of the surviving checks are left exactly as they are)
Results: 195 passed, 1 failed
```

Restored — suite green again: `Results: 196 passed, 0 failed`.

Clause (c) — replaced the `Write that block as the last lines of your\n  report,` wording with `, ` (dropping the sentence) around
`skills/multi-doc-review/SKILL.md:840`:

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E "FAIL|Results"
  FAIL: Execution readiness cell: coverage block placement sentence (missing: Write that block as the last lines of your report)
Results: 195 passed, 1 failed
```

Restored — suite green again: `Results: 196 passed, 0 failed`. Confirmed
byte-identical to the pre-mutation backup:

```
$ git diff --stat -- skills/multi-doc-review/SKILL.md
$ shasum skills/multi-doc-review/SKILL.md /tmp/SKILL.md.orig
48b4bf3561389a0d8b1d40ab2bbab85d94da3428  skills/multi-doc-review/SKILL.md
48b4bf3561389a0d8b1d40ab2bbab85d94da3428  /tmp/SKILL.md.orig
```
(`git diff --stat` printed nothing.)

### [I2]

Fix, in section 14 ("Triage of a readiness finding") of
`tests/reviewer-templates/run-tests.sh`:

- Added `TRIAGE_RANGE` (`$WORK/triage-of-a-readiness-finding.txt`), extracted
  with `extract_lines "$DOC_SKILL" "$TRIAGE_LINE" "$LENS_ROT_LINE_14"` — both
  bounds were already resolved by the section's existing position check — the
  same pattern section 13 already uses for `LENS_ROTATION_RANGE`, with a
  `bad` fallback when either bound is unresolved.
- Re-scoped 9 of the loop's needles (`rejected: not a conflict`, `rejected:
  plan-mandated`, `rejected: undecidable at this gate`, `out of lens scope`,
  `A readiness finding never produces an unresolved: line, in any caller.`,
  `reverses an amendment made earlier in the same sequence`, `` `rejected:
  plan-mandated — <text>`, never amended ``, `` amend the plan side,
  `applied` ``, `amend the side the spec decides against; failing that, the
  side the Global Constraints block decides against`) from `$DOC_SKILL` to
  `$TRIAGE_RANGE`, and reworded their description from `triage carries` to
  `Triage of a readiness finding subsection carries`.
- Kept the 4 needles that pin text outside the subsection — `Readiness pass
  whose reports are all unusable (u = 0) → `inconclusive`, and the pass is
  open` (`skills/multi-doc-review/SKILL.md:1064`), `a readiness entry with a
  missing or malformed` (`:1065`), `as a round is` (`:1068`), `for a plan
  document the Execution readiness pre-sequence still runs` (`:1036-1037`) —
  all four sit under `## Error Handling`, not the triage subsection. No
  narrower already-resolved range exists in this suite for `$DOC_SKILL`'s
  Error Handling section, so per the finding's own fallback ("its own
  resolved range, or the whole file when no narrower range exists") they
  stay asserted against `$DOC_SKILL`, unweakened, in their own loop with the
  description corrected to `Error Handling section carries`.
- Added two further needles to the (now `$TRIAGE_RANGE`-scoped) loop:
  `the spec contradicts itself` and `without searching for a second side`.
  These were required beyond the plain re-scope: mutation-testing the
  re-scoped loop showed the two clauses the finding names as the mutation
  targets — the `fixed text vs fixed text` row and Step 0's verify paragraph
  — each duplicate their only previously-pinned phrase
  (`reverses an amendment made earlier in the same sequence`, and `rejected:
  not a conflict` respectively) elsewhere inside the same triage subsection
  (`skills/multi-doc-review/SKILL.md:712-713` inside Step 1's authority
  paragraph, and `:733-734` inside the subsection's closing paragraph), so
  scoping to the subsection alone left both mutations green. `the spec
  contradicts itself` and `without searching for a second side` are each
  copied verbatim from the row (`:721`) and from Step 0's paragraph (`:702`)
  respectively, and verified unique in the whole file with
  `grep -n -F -- '<text>' skills/multi-doc-review/SKILL.md`.

Verification, backup taken first:

```
$ cp skills/multi-doc-review/SKILL.md /tmp/SKILL.md.orig2
```

Baseline after the section-14 edit, before adding the two extra needles —
mutating the `fixed text vs fixed text` row and, separately, Step 0's
paragraph — suite stayed green both times (`Results: 196 passed, 0 failed`),
confirming the finding's diagnosis that the plain re-scope was not
sufficient by itself. After adding the two extra needles:

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -3
Results: 198 passed, 0 failed
```

Mutation 1 — deleted the `| fixed text vs fixed text ... | rejected:
undecidable at this gate — spec inconsistent |` row
(`skills/multi-doc-review/SKILL.md:721`):

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E "FAIL|Results"
  FAIL: multi-doc-review SKILL.md: Triage of a readiness finding subsection carries 'the spec contradicts itself' (missing: the spec contradicts itself)
Results: 197 passed, 1 failed
```

Restored (`cp /tmp/SKILL.md.orig2 skills/multi-doc-review/SKILL.md`) — suite
green again: `Results: 198 passed, 0 failed`.

Mutation 2 — deleted Step 0's whole verify paragraph
(`skills/multi-doc-review/SKILL.md:699-706` including its trailing blank
line):

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | grep -E "FAIL|Results"
  FAIL: multi-doc-review SKILL.md: Triage of a readiness finding subsection carries 'without searching for a second side' (missing: without searching for a second side)
Results: 197 passed, 1 failed
```

Restored — suite green again, and confirmed byte-identical to the
pre-mutation backup:

```
$ bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -3
Results: 198 passed, 0 failed
$ git diff --stat -- skills/multi-doc-review/SKILL.md
$ shasum skills/multi-doc-review/SKILL.md /tmp/SKILL.md.orig2
48b4bf3561389a0d8b1d40ab2bbab85d94da3428  skills/multi-doc-review/SKILL.md
48b4bf3561389a0d8b1d40ab2bbab85d94da3428  /tmp/SKILL.md.orig2
```
(`git diff --stat` printed nothing — `skills/multi-doc-review/SKILL.md` is
unchanged.)

### Final covering-test run

```
$ bash tests/reviewer-templates/run-tests.sh
...
Results: 198 passed, 0 failed
```

Only `tests/reviewer-templates/run-tests.sh` is changed this round
(`git diff --stat`: `tests/reviewer-templates/run-tests.sh | 30
+++++++++++++++++++++++++-----`, 1 file changed, 25 insertions(+), 5
deletions(-)).
