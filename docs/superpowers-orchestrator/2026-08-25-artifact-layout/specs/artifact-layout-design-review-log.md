# Review Log — 2026-08-25-artifact-layout-design.md

_Invocation 1 — 2026-08-25 — N=4 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5
**Reviewer verdict:** 3 Critical, 6 Important, 5 Minor
**Converged:** no

### Dispositions
- [C1] applied — §4 derivation: rule also matched old-layout paths (`docs/plans/x.md` → topic `docs/`) → topic folder must be a direct child of `docs/superpowers-orchestrator/` with a `YYYY-MM-DD-<slug>` basename; everything else is outside the layout
- [C2] applied — §5.6: tracked-log sentinel, once-per-gate skip and completion-marker HEAD all break when the log is committed → pipeline-mode rules 3 and 4 added (sentinel direct-only; effective HEAD = newest non-`chore(review):` commit; marker and addendum committed as `chore(review): <slug> completed`)
- [C3] applied — §5.6: `git status --porcelain` precondition never clean with a tracked/modified log → rule 2 excludes `implementation/` via `:(top,exclude)`
- [I1] applied — §5.6 rule 1: `git add -- <paths>` before the path-limited commit; fix-reports path conditional on existence
- [I2] applied — §5.3: multi-doc-review type inference is a `docs/specs/` prefix rule today → rewritten to a `/specs/`, `/plans/` segment rule
- [I3] applied — §5.4 + §7: spec outside the layout is a pre-log stop naming the expected location; §5.2 writing-plans asks once to `git mv` the spec, stops on no
- [I4] applied — §6: pathspecs use `:(top)` magic; reason recorded (review-package runs from the session cwd)
- [I5] applied — §8 item 2: autoimprove spec+plan paired in one folder; rename rule for item 2 stated (add `-design`, strip `-plan`)
- [I6] applied — §6: reviewer fallback diff commands get the same pathspecs; orchestrator triage rule extended to `*-fix-reports.md` and `implementation/`
- [M1] applied — §5.1: reuse leaves other stage files untouched, brainstorming warns about the orchestrator's Phase 0 precondition and continued round numbering
- [M2] applied — §5.4: edit sites `plan-writer-prompt.md:62`, Phase 5 step 3, Resume step 0, Phase 1 plan-path sentence listed
- [M3] applied — §6 item 2: reviewer-prompt already lists `*-fix-reports.md`; only `implementation/` is new
- [M4] applied — §7: archive folder is `archive/<old plan basename>/`, date included
- [M5] applied — §8 item 2: `.gitignore:19` removed with the deleted flat folder

## Round 2 — Ambiguity & testability — claude-fable-5
**Reviewer verdict:** 1 Critical, 3 Important, 6 Minor
**Converged:** no

### Dispositions
- [C1] applied — §5.6 rule 4: marker recorded raw HEAD (always the last log commit) and compared it with the effective HEAD → marker and addendum record the effective HEAD in pipeline mode; direct mode keeps raw HEAD
- [I1] applied — §4/5.1/5.2/5.4: `*-<slug>/` also matched `user-auth` for slug `auth` → every lookup uses `????-??-??-<slug>` (regex stated once in §4)
- [I2] applied — §5.6 validation: `TOPIC_DIR` must satisfy the §4 derivation rule, else stop; `<slug>` and repository-relative `<topic>` defined
- [I3] applied — §5.2/5.4/§7: the spec's review-log sidecar moves with the spec; orchestrator stop message names both files
- [M1] applied — §5.6 rule 1: "clean tree" qualified as clean except pre-existing consented changes
- [M2] applied — §5.6: `<topic>` = `TOPIC_DIR` minus `<repo root>/` (merged into the validation paragraph)
- [M3] applied — §5.3: segment rule on the repository-relative path, nearest segment wins
- [M4] applied — §9: assertion targets the review package file whose path the log records
- [M5] applied — §6: git assumptions paragraph with `gitglossary(7)`/`git-commit(1)` citations, minimum git 2.32, reproduced on 2.50.1
- [M6] applied — §8 item 2: folder slug rule for the single-file topics stated

## Round 3 — Feasibility & architecture risk — claude-fable-5
**Reviewer verdict:** 0 Critical, 2 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §5.4: orchestrator Resume step 0 clean-tree check gains the `implementation/` exclusion pathspec; a partial log from an interrupted round is picked up by the resumed loop's next `chore(review)` commit
- [I2] applied — §5.4: Phase 0 step 4 precondition uses `--untracked-files=all` and its exception names the spec and sidecar under the topic folder's `specs/` (a new untracked folder collapses to one porcelain line otherwise)
- [M1] applied — §5.2/§8: `mkdir -p` of the destination stage folder before every `git mv`
- [M2] applied — §6/§10: git 2.32 reworded as implied by `--trailer`; the release note and README state it explicitly
- [M3] applied — §5.6 rule 1: the fix subagent never stages the fix-report file; the controller's round commit owns both files
- [M4] applied — §6: `:(top)` rationale reworded — cwd-independence for the sdd per-task caller; harmless under mcr's existing root anchoring
- [M5] applied — §5.2: edit sites `writing-plans/SKILL.md:16` and `:27` (plan-header `**Spec:**` template) listed
- [M6] applied — §6/§9: MSYS path-conversion assumption labeled unverified; one-time Git Bash check added to the post-push checklist with `MSYS_NO_PATHCONV=1` as the workaround

## Round 4 — Adversarial failure modes — claude-fable-5
**Reviewer verdict:** 0 Critical, 5 Important, 6 Minor
**Converged:** no

### Dispositions
- [I1] applied — §4: both sides of the topic-folder comparison canonicalized (`pwd -P`/`realpath`); `git rev-parse --show-toplevel` is physical, `mktemp -d` on macOS is logical
- [I2] applied — §6: `*-orchestration-log.md` and `*-open-decisions.md` added to the diff exclusion and the reviewer read prohibition (both are committed and quote prior findings on a resumed run)
- [I3] applied — §5.2/5.4: the sidecar is renamed with the spec (`specs/<slug>-design-review-log.md`); the orchestrator message names both destination paths
- [I4] applied — §4: slug charset normative (`^[a-z0-9]+(-[a-z0-9]+)*$`); brainstorming normalizes before creating the folder; "outside the layout" messages state the reason
- [I5] applied — §5.6 validation + §7: pending `chore(review)` commit retried at invocation start; second failure returns `BLOCKED` naming the manual commit
- [M1] applied — §6: pathspecs apply to `git log --oneline`, `git diff --stat` and `git diff` in `review-package`
- [M2] rejected: same exposure as today's automatic batched-mode resume; a machine token adds state for a case branch ownership already prevents — recorded as a non-goal (§2) and a residual risk for the release note
- [M3] applied — §5.1: reuse consequence for the spec's own review log stated; brainstorming offers to move it aside
- [M4] applied — §5.6 validation: `git check-ignore -q <log path>` must fail before round 1
- [M5] applied — §10: guide sentence on repository-root anchoring (monorepo sub-projects)
- [M6] applied — §5.6 rule 4: effective-HEAD walk bounded to `BASE..HEAD`, falls back to BASE

_Invocation 1 result — 4 rounds, cap reached (no clean round) — 2026-08-25_
