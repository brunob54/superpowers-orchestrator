# Open decisions — review-gate-m-question

## Ruling 1 — 2026-09-08 — phase 4 — [CF4] the CLAUDE.md registration line does not ship

- **Class:** forced
- **Item:** [CF4 inv 1] carried CLAUDE.md:17 — CLAUDE.md is git-ignored in this repository, so Task 5's Testing-section line never ships with the branch (plan-mandated)
- **Contract clause:** "Must convey: `bash tests/review-gates/run-tests.sh` belongs to the fast, non-behavioural suites, with a one-line description of what it covers." — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** plan governs: "Must convey: `bash tests/review-gates/run-tests.sh` belongs to the fast, non-behavioural suites, with a one-line description of what it covers." — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md — The clause requires the line to be conveyed in `CLAUDE.md`, and it stands at `CLAUDE.md:17` with its one-line description; `CLAUDE.md` is excluded by this repository's own `.gitignore:7` and is untracked, and neither the spec nor the plan asks this branch to change that ignore configuration.

## Ruling 2 — 2026-09-08 — phase 4 — [I2] "never by `<d>`" forbids the fallback the batched mode's own rule ends at

- **Class:** forced
- **Item:** [I2 inv 1] Important skills/subagent-driven-development/SKILL.md:81 — the code gate's 'never by `<d>`' qualifier forbids the very session-tag fallback Batched Autonomous Mode's own rule ends at, so two agents pass M=3 and M=1 for the same run (plan-mandated)
- **Contract clause:** "Batched Autonomous Mode and every subagent-dispatched controller ask nothing and resolve both values by their own rule, never by `<d>`. (Spec R5, R7)" — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** amend plan: disambiguate the Global Constraints entry so that `<d>` names the gate's default-offering resolution, which these paths never enter, and state that Batched Autonomous Mode's own rule may still end at the `<reviewers-per-lens>` session tag as that rule's own last resort; fix it: carry the same disambiguation into the Batched Autonomous Mode qualifier of Core Flow step 4 in `skills/subagent-driven-development/SKILL.md`, so the shipped text no longer forbids the session-tag fallback that mode's own rule ends at — Spec R5 states that mode's own rule verbatim as "the value the user stated when starting the batch or carried by the resume prompt's `M=<m>`, else the `<reviewers-per-lens>` session tag, else 1", which ends at the same value `<d>` names, so reading "never by `<d>`" as forbidding that tag fallback makes spec R5 contradict its own quoted rule.

## Ruling 3 — 2026-09-08 — phase 4 — [I1] doc gates recover M from the committed sidecar log

- **Class:** forced
- **Item:** [I1 inv 1] Important skills/brainstorming/SKILL.md:65 — the document gates recover M from the committed sidecar log, so a repository file chooses a review parameter, which the project's own invariant for the `<reviewers-per-lens>` tag forbids; the spec's R5 requires that recovery (plan-mandated)
- **Contract clause:** "Must convey, in this order: the platform check; the suppression check with the origin echo; the question one question batch for whichever of N and M" — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** plan governs: "Must convey, in this order: the platform check; the suppression check with the origin echo; the question one question batch for whichever of N and M" — docs/superpowers-orchestrator/2026-09-08-review-gate-m-question/plans/review-gate-m-question.md — Spec R5 requires this recovery by name ("On a doc gate's non-asking path, the gate passes the M recorded on the log's invocation line when it is recoverable, else `<d>`"), and the invariant it is set against governs only a `<reviewers-per-lens>` element read as a parameter, never a review log's own recorded `M=<m>`, so the two do not collide.
