
## Round 1

Finding ids addressed: I1, carried task 7 security M4, carried task 7 security M7, M1, M2.

Command: `bash tests/dashboard/run-tests.sh`

Output (end): `dashboard suite: every test file passed` (exit 0). Before the fix, the new test-04 case failed with git "ambiguous argument HEAD: both revision and filename".

## Round 2

Findings addressed: M3, M1.

Command: bash tests/dashboard/run-tests.sh
Output (last line): dashboard suite: every test file passed (test-04 and test-12 included; test-13: 8 passed, 0 failed)
