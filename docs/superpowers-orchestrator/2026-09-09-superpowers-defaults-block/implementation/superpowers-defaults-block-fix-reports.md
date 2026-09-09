# superpowers-defaults-block — Fix Reports

## Round 1

Finding ids addressed: I1, I2, I3, I4, I5, M1, M2, M6, M9, CF1, CF2, CF3, CF4, CF5

Command:
```
bash tests/review-gates/run-tests.sh
```
Output (tail):
```
[1m12/13/14. No subagent path can reach a gate question[0m
  PASS: plan-writer-prompt still skips Multi-Round Plan Review
  PASS: doc-review-loop-prompt Deviation 1 names the Self-Review checklist
  PASS: doc-review-loop-prompt does not name Multi-Round Plan Review
  PASS: batch-controller-prompt does not name Core Flow step 4
  PASS: batch-controller-prompt still names only Core Flow step 3

Results: 183 passed, 0 failed
```

Command:
```
bash tests/codex/test-session-start-defaults-block.sh
```
Output (tail):
```
  ok   - decoy, no variable set: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the workspace decoy precedes the hook's block, which ends the context
  53 passed, 0 failed
```

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
