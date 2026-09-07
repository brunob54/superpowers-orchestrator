## Round 1

Findings addressed: M1, M2, M3, M4.

Fixes:
- M1 — `skills/multi-doc-review/SKILL.md` (`## Guard Interaction`, around
  line 500) and `skills/multi-code-review/SKILL.md` (`## Guard Interaction`,
  around line 1857): added a qualifying clause to each body stating the
  widened rule governs hook blocking only and that a report is still usable
  only when the marker is its first line, without touching either
  validation step.
- M2 — `hooks/subagent-guard.js` (the `MARKER_SEARCH_LINES` comment, around
  line 87): reworded the bounded-window reason to name the real
  over-exemption case — a marker reproduced at the start of a line further
  down the message (an indented or fenced quotation of a controller
  return) — instead of the case that does not follow from the prefix-match
  predicate.
- M3 — `skills/orchestrating-development/SKILL.md` (Return contract bullet,
  around line 163): replaced the colloquial "and keep saying so" with
  "and that instruction does not change".
- M4 — `skills/orchestrating-development/SKILL.md` (`## Guard Interaction`,
  around line 2244): split the long colon/"but"-clause sentence into
  several short literal sentences carrying the same facts, including the
  2026-09-06 measurement and the reason the marker instruction stays
  mandatory.

Covering tests re-run:

```
$ bash tests/codex/run-unit-tests.sh
...
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.

$ bash tests/orchestrating-development/run-tests.sh
...
Results: 162 passed, 0 failed

$ bash tests/in-run-rulings/run-tests.sh
...
Results: 512 passed, 0 failed

$ bash tests/reviewer-templates/run-tests.sh
...
Results: 60 passed, 0 failed
```

All four covering test suites passed with zero failures.

## Round 2

Findings addressed: I1, M1.

Fixes:
- I1 — `skills/orchestrating-development/SKILL.md` (`## In-run rulings`,
  the loss sentence following "A **reviewer's return**", around line
  1427): replaced "is **lost** when its completion notice arrives without
  the marker line, or reports that the reviewer failed" with an explicit
  position rule mirroring the Return contract bullet: a reviewer's return
  is lost when no line of its completion notice, with its surrounding
  whitespace removed, starts with `<!-- multi-review report -->` among
  the first 10 non-blank lines, or when the notice reports that the
  reviewer failed. The `**Lost returns.**` opening sentence and the two
  `## Guard Interaction` fragments the tests assert byte-identical were
  left untouched.
- M1 — `hooks/subagent-guard.js` (the `MARKER_SEARCH_LINES` comment,
  around lines 84-90): added one sentence recording the accepted
  residual — a quotation of that shape landing inside the window still
  exempts the message, and that is the accepted cost of the wider
  window. No executable line changed; the comment does not contain
  "opens with", "opening with" or "open with".

Covering tests:

```
$ bash tests/codex/run-unit-tests.sh
Results: 10 suites passed, 0 suites failed
All unit tests passed.

$ bash tests/orchestrating-development/run-tests.sh
Results: 162 passed, 0 failed

$ bash tests/in-run-rulings/run-tests.sh
Results: 512 passed, 0 failed

$ bash tests/reviewer-templates/run-tests.sh
Results: 60 passed, 0 failed
```

## Round 2

Findings addressed: M1, M2

- M1: skills/orchestrating-development/SKILL.md — reworded the
  "A **reviewer's return** is **lost**" sentence in `## In-run rulings`
  so the 10-non-blank-line window is counted over "the reviewer's final
  message" instead of "its completion notice", matching the Return
  contract bullet and the hook. Kept the literal phrase "first 10
  non-blank lines" and the marker spelling
  `<!-- multi-review report -->`. Did not touch the `**Lost returns.**`
  opening sentence, the two named fragments, or the `## Guard
  Interaction` / `## Prompt Templates` heading lines.
- M2: skills/researching-prior-art/SKILL.md — added one sentence to
  `## Guard interaction` stating that the widened hook-exemption rule
  governs hook blocking only, and that `controller-prompt.md`'s report
  verification still discards a report whose `<!-- research report -->`
  marker is not its first line. Heading line and all pre-existing
  sentences in the section kept byte-identical.

Covering tests:

```
$ bash tests/codex/run-unit-tests.sh
Results: 10 suites passed, 0 suites failed
All unit tests passed.

$ bash tests/orchestrating-development/run-tests.sh
Results: 162 passed, 0 failed

$ bash tests/in-run-rulings/run-tests.sh
Results: 512 passed, 0 failed

$ bash tests/reviewer-templates/run-tests.sh
Results: 60 passed, 0 failed
```

## Round 2

Findings addressed: I1

Command:
```
bash tests/codex/run-unit-tests.sh
```
Output (tail):
```
protect-secrets: 43 passed, 0 failed

==================================================
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
==================================================
```

Command:
```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
Results: 162 passed, 0 failed
```

Command:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
Results: 512 passed, 0 failed
```

Command:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
Results: 60 passed, 0 failed
```

## Round 2

Findings addressed: I2, I3

Commands run:

```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
Results: 162 passed, 0 failed
```

```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
Results: 512 passed, 0 failed
```

## Round 1

Findings addressed: I1, M1

Command:
```
bash tests/orchestrating-development/run-tests.sh
```

Output (tail):
```
Results: 162 passed, 0 failed
```

## Round 2

Findings addressed: I3, M1, M2

Fix locations:
- I3 — skills/orchestrating-development/SKILL.md (leading-token sentence): added the exception that a further line equal to the marker is skipped when locating the leading token, so a window with several marker lines reaches the note rule instead of the malformed list.
- M1 — skills/orchestrating-development/SKILL.md (equals-marker sentence): added a sentence stating that content after the marker on the marker line makes the return malformed under this equality test, even though the guard hook's prefix match tolerates it.
- M2 — skills/orchestrating-development/SKILL.md (14-lines-below sentence): stated explicitly that the 14 lines are raw lines, blank lines included, and that the bullet's "non-blank" qualifier does not apply to this count.

Covering tests run:

```
$ bash tests/orchestrating-development/run-tests.sh
...
Results: 162 passed, 0 failed
```

```
$ bash tests/codex/run-unit-tests.sh
...
Results: 10 suites passed, 0 suites failed
All unit tests passed.
```

## Round 2

Findings addressed: I1, M1, M2

Command:
```
bash tests/orchestrating-development/run-tests.sh
```

Output (tail):
```
  PASS: in-run rulings: contains 'test -s'
  PASS: in-run rulings: contains 'with the Write tool to `<PROMPT_DIR>/dispatch-<k>-answers.txt`'
  PASS: in-run rulings: contains '`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'`'

Results: 162 passed, 0 failed
```

## Round 2

Findings addressed: I3, M1, M2, M3.

Covering tests run:

```
$ bash tests/reviewer-templates/run-tests.sh
```
```
Results: 60 passed, 0 failed
```

```
$ bash tests/orchestrating-development/run-tests.sh
```
```
Results: 162 passed, 0 failed
```

## Round 2

Findings addressed: A1, A2, A3.

Command:
```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
Results: 162 passed, 0 failed
```

Command:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
Results: 512 passed, 0 failed
```

## Round 1

Findings addressed: I1, M1, M2, M3, M4, M5, CF1.

Command:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
Results: 60 passed, 0 failed
```

Command:
```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
Results: 162 passed, 0 failed
```

Command:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
Results: 512 passed, 0 failed
```

## Round 2

Findings addressed: M2, M3, M5, M6

Commands run and output:

```
$ bash tests/orchestrating-development/run-tests.sh
...
Results: 162 passed, 0 failed
```

```
$ bash tests/reviewer-templates/run-tests.sh
...
Results: 60 passed, 0 failed
```

## Round 2

Findings addressed: M2

Command:
```
bash tests/orchestrating-development/run-tests.sh
```

Output (tail):
```
Results: 162 passed, 0 failed
```

## Round 2

Findings addressed: M3, M5

Command:
```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
Results: 162 passed, 0 failed
```

Command:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
Results: 60 passed, 0 failed
```

Command:
```
bash tests/fill-prompt/run-tests.sh
```
Output (tail):
```
Results: 166 passed, 0 failed
```

## Round 2

Findings addressed: [I1]

Fix: added the three reading rules (first-marker-begins-report, read
window bounded to the marker line plus 24 lines below it, first
occurrence wins on a repeated field) to the fork-return text of the
`## In-run rulings` section's "Lost returns" paragraph in
skills/orchestrating-development/SKILL.md, immediately after the
lost-return sentence.

Command run:
    bash tests/orchestrating-development/run-tests.sh

Output (tail):
    Results: 162 passed, 0 failed

## Round 1

Findings addressed: I1, I3, M3, M2, M4, CF6

Command run:
```
bash tests/orchestrating-development/run-tests.sh
bash tests/in-run-rulings/run-tests.sh
```

Output (tails):
```
Results: 162 passed, 0 failed
```
```
Results: 512 passed, 0 failed
```

## Round 2

Findings addressed: I4, I1

Command run:
```
bash tests/orchestrating-development/run-tests.sh
bash tests/reviewer-templates/run-tests.sh
```

Output (tails):
```
Results: 162 passed, 0 failed
```
```
Results: 60 passed, 0 failed
```

## Round 1

Findings addressed: I1, I2, I3, M3, M4

Command run:
```
bash tests/reviewer-templates/run-tests.sh
bash tests/in-run-rulings/run-tests.sh
```

Output (tails):
```
Results: 60 passed, 0 failed
```
```
Results: 512 passed, 0 failed
```

## Round 2

Findings addressed: I2, M6, M7

Command run:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
Results: 60 passed, 0 failed
```

Command run:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
Results: 512 passed, 0 failed
```

Command run:
```
node tests/codex/test-subagent-guard.js
```
Output (tail):
```
subagent-guard: 60 passed, 0 failed
```

## Round 2

Findings addressed: I3, M1

Command run:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
[1mResults: 72 passed, 0 failed[0m
```

Command run:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
[1mResults: 512 passed, 0 failed[0m
```

Command run:
```
node tests/codex/test-subagent-guard.js
```
Output (tail):
```
subagent-guard: 60 passed, 0 failed
```
