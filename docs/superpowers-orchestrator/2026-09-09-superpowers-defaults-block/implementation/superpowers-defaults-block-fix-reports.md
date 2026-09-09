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

## Round 2

Finding ids addressed: I1, I2, I3, M1, M2, M4, M5, M6, M8, M9, M11

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

Command (M2: fix verified, then confirmed it fails when the decoy's own
closing delimiter is removed, then the fixture edit was reverted):
```
bash tests/codex/test-session-start-defaults-block.sh
```
Output (tail, after the fix, decoy closing delimiter intact):
```
  ok   - decoy, no variable set: the workspace decoy precedes the hook's block, which ends the context
  ok   - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the workspace decoy precedes the hook's block, which ends the context
  53 passed, 0 failed
```
Output (tail, decoy closing delimiter removed — confirms the new check
actually catches the incomplete-decoy case; fixture then restored):
```
  FAIL - decoy, no variable set: the decoy block from state.md is absent or incomplete — the workspace file was not embedded, or its closing delimiter was not written literally
  FAIL - decoy, SUPERPOWERS_REVIEW_ROUNDS=8: the decoy block from state.md is absent or incomplete — the workspace file was not embedded, or its closing delimiter was not written literally
  51 passed, 2 failed
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

Command:
```
bash tests/writing-plans/run-tests.sh
```
Output (tail):
```
  PASS: self-review scoping statement 'plan-header content is out of scope' (check 5) (line 338, range 338..340)

Results: 15 passed, 0 failed
```

Command:
```
bash tests/orchestrating-development/run-tests.sh
```
Output (tail):
```
  PASS: in-run rulings: contains '`'RESUME_ANSWER=@<PROMPT_DIR>/dispatch-<k>-answers.txt'`'

Results: 162 passed, 0 failed
```

Command:
```
bash tests/reviewer-templates/run-tests.sh
```
Output (tail):
```
  PASS: multi-doc-review SKILL.md: pre-change first-line-only wording absent

Results: 72 passed, 0 failed
```

Command:
```
bash tests/in-run-rulings/run-tests.sh
```
Output (tail):
```
  PASS: decided wording is quoted on a decided line or a rejected: plan governs line of the same run (range 1080..1191, line wraps folded)

Results: 512 passed, 0 failed
```
