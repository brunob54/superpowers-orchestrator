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
