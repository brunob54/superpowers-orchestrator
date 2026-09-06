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
