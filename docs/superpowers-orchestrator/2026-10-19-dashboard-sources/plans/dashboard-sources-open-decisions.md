# Open decisions — dashboard-sources

## Ruling 1 — 2026-10-20 — phase 3 — [task 8/1] shared-ref line built in two files

- **Class:** forced
- **Item:** [task 8/1] n/a n/a — task review Important (plan-mandated): the shared-ref line is built by the same logic in template.html and dashboard-extract.js; which governs, the plan's two copies or the rubric's one copy?
- **Contract clause:** "`sharedRefLine(info, branch)`, `notShownText(info, branch)`, `sharedRefWarns(info, generatedAt)`, `renderSharedRef(data)` and the static element `<p id='shared-ref' hidden></p>`" — docs/superpowers-orchestrator/2026-10-19-dashboard-sources/plans/dashboard-sources.md, Task 8
- **Defensible answers:** n/a
- **Forks:** none; contradiction: none
- **Resolution:** plan governs: "`sharedRefLine(info, branch)`, `notShownText(info, branch)`, `sharedRefWarns(info, generatedAt)`, `renderSharedRef(data)` and the static element `<p id='shared-" — docs/superpowers-orchestrator/2026-10-19-dashboard-sources/plans/dashboard-sources.md — the spec mandates both copies: section 4.5 "Report" says "The extractor builds the line once; the template builds the page text from the data fields. Both produce the exact texts above; test-07 compares them", so the one-copy outcome changes the spec and is not open to this run; the duplication is guarded by test-07's same-wording checks.
