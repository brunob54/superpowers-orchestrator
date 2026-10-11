## Round 1

Findings addressed: M1, M3.

Command: `bash tests/codex/run-unit-tests.sh`

Output (end):

```
  26 passed, 0 failed

==================================================
 Results: 26 suites passed, 0 suites failed
 All unit tests passed.
==================================================
```

`node tests/codex/test-stop-reminders.js` ends with `stop-reminders: 158 passed, 0 failed`. The new NUL-path row failed before the fix (157 passed, 1 failed) and passes after it.
