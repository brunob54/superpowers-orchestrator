## Round 1

Findings addressed: M1, M2, M3, L1, L2, L3, L4, L8, L10, L13, L15.

Files changed: `skills/worklog/SKILL.md`, `tests/worklog/run-tests.sh`,
`hooks/session-start`.

Before the fix, the new suite cases failed as intended
(`bash tests/worklog/run-tests.sh`: 126 passed, 5 failed — the noclobber
case printed `cannot overwrite existing file` and left line 1 active; the
symbolic-link, kept-copy and awk-failure branches exited with status 0).
Mutation checks after the fix: replacing `echo "$T"; false` with
`rm -f "$T"; false` turns 2 checks red; deleting the `Grammar:` line turns 1
check red.

Hook output comparison (L15): the committed `hooks/session-start` and the
changed one were run on fixtures with 1, 3, 4 and 5 active work logs and on a
root longer than 300 characters; `cmp` found the outputs byte-identical.

Covering tests:

```
$ bash tests/worklog/run-tests.sh; echo "exit=$?"
...
Results: 131 passed, 0 failed
exit=0

$ bash tests/codex/test-session-start-worklog-notice.sh; echo "exit=$?"
...
  21 passed, 0 failed
exit=0

$ bash tests/codex/run-unit-tests.sh; echo "exit=$?"
...
 Results: 17 suites passed, 0 suites failed
 All unit tests passed.
exit=0
```
