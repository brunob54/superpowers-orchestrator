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
