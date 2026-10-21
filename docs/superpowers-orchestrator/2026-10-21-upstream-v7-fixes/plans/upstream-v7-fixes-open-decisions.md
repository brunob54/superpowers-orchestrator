# Open decisions — upstream-v7-fixes

## Ruling 1 — 2026-10-21 — phase 4 — [I1] C9 "did not cause" criterion misses indirect regressions

- **Class:** forced
- **Item:** [I1 inv 1] Important skills/subagent-driven-development/implementer-prompt.md:57 — the C9 'did not cause' criterion counts only a test that is a changed file or directly imports or reads one, so a regression the task causes through another module, a run script or a shared fixture is labelled not caused and left unfixed
- **Contract clause:** "Must convey: a test outside the task that fails and that the change did not cause is not fixed, unless the brief or the controller's dispatch names that test as" — docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/plans/upstream-v7-fixes.md, Task 6
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** plan governs: "Must convey: a test outside the task that fails and that the change did not cause is not fixed, unless the brief or the controller's dispatch names that test as" — docs/superpowers-orchestrator/2026-10-21-upstream-v7-fixes/plans/upstream-v7-fixes.md — The spec mandates this criterion verbatim (section 4.7: "Your change did not cause the failure when the test neither is a file that your task changes nor imports or reads one", chosen because it "can be checked from the task's own file list and the test's source"), and its failure mode 8 accepts, as a user decision of 2026-10-21, that "a failure that the task caused while the implementer claims it did not" is named as an observation with its failing output and left to the controller and the task reviewer; so any wider criterion changes the spec, and the finding's case is the one the spec already accepted.
