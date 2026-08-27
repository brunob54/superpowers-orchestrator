# Review log — 2026-07-29-sdd-plan-scoped-workspace-design.md

_Invocation 1 — 2026-07-29 — N=4 — gate: brainstorming_

## Round 1 — Correctness & completeness — session model
**Reviewer verdict:** 0 Critical, 1 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — Architecture step 2: normalization underspecified (cwd-relative from subdir, plan outside repo, macOS symlink prefixes) → specified physical-path algorithm (`pwd -P` resolution, exit 2 outside repo, prefix strip); added subdirectory-invocation and outside-repo test cases
- [M1] applied — Architecture step 3: fresh-workspace outcome unstated → added explicit fresh-workspace branch (write `plan.ref`, no archive)
- [M2] applied — Error Handling: false atomicity claim → replaced with recoverable-not-atomic property (rerun re-triggers legacy rule, archives remainder)
- [M3] applied — Non-Goals: "restated, not a regression" inaccurate for ledger → documented the new run-A ledger-relocation loss mode honestly, still non-goal
- [M4] applied — Scope: enforcement still prose-triggered → acknowledged residual dependency; added arg-less stderr warning backstop for legacy workspace + test case

## Round 2 — Ambiguity & testability — session model
**Reviewer verdict:** 0 Critical, 2 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — Testing test 7: A→B→A sequence cannot produce a slug collision → corrected to A→B→A→B, fourth call archives into `<slug-A>-2`
- [I2] applied — empty/malformed `plan.ref` undefined (crash-during-write state) → defined read contract (first line, trailing whitespace stripped); empty/unreadable = no `plan.ref` (legacy rule); test 4 extended
- [M1] applied — file-level symlink ambiguity in "physical absolute path" → contract stated: directory symlinks resolved, file-basename symlink NOT resolved
- [M2] applied — `unknown-<timestamp>` format unspecified; suffix rule scoped to plan slugs → epoch seconds (`date +%s`); suffix rule applies to all destination collisions
- [M3] applied — "exists" (step 1) vs "unreadable" (Error Handling) divergence → step 1 now requires `[ -f ] && [ -r ]`

## Round 3 — Feasibility & architecture risk — session model
**Reviewer verdict:** 0 Critical, 0 Important, 2 Minor
**Converged:** no

### Dispositions
- [M1] applied — spec never states the script's actual location (no top-level `scripts/` dir exists) → added parenthetical `skills/subagent-driven-development/scripts/sdd-workspace` at first mention
- [M2] applied — Interfaces table overstates: helpers skip `sdd-workspace` when an explicit output path is given → reworded "Before" cell

## Round 4 — Adversarial failure modes — session model
**Reviewer verdict:** 0 Critical, 3 Important, 3 Minor
**Converged:** no

### Dispositions
- [I1] applied — version-skew backstop silent once `plan.ref` exists (flagship failure recurs with zero signal) → arg-less call now prints informational `workspace is scoped to plan <path>` stderr line whenever `plan.ref` exists; Scope claim narrowed (backstop informs, cannot enforce)
- [I2] applied — Batched Autonomous Mode Resume Procedure bypasses step 1 → spec now requires resume/re-entry to run `sdd-workspace PLAN_FILE`; archived resumed-plan ledger consulted read-only from `archive/<slug>/progress.md` for Minor-findings triage
- [I3] applied — out-of-repo plans exit 2 is an unacknowledged regression (worktree/notes-dir workflows) → REVERSES round 1 [I1] remedy: identity falls back to absolute physical path instead of exit 2; test 6 updated
- [M1] applied — "by construction" wording sharpened ledger-vs-checkboxes precedence conflict → step-1 rewrite states checkboxes + `git log` stay authoritative for position on conflict
- [M2] applied — crash after `plan.ref` moved scatters remainder under `unknown-*` → `plan.ref` moves last; remainder keeps slug, rerun archives into suffixed dir
- [M3] applied — upgrade-boundary archive silently strands carried Minor findings → Rollout instructs consulting `archive/unknown-*/progress.md` during final-review triage

## Post-loop self-review (merge-introduced issues, fixed inline)
- `plan.ref` described as "repo-relative plan path" in two places while round 4 [I3] added the absolute-path fallback → both mentions now carry the out-of-repo case; Non-Goals rename bullet aligned
- Interfaces table said exit 2 "on missing plan file" vs step 1's missing/unreadable → aligned
- Failure-Mode Check summary predated round 4 [I1] → added version-skew residual-risk bullet; "No critical failure modes" qualified to "in compliant sessions"

**Result: 4 rounds run (cap reached, N=4). Findings: R1 0C/1I/4M, R2 0C/2I/3M, R3 0C/0I/2M (clean), R4 0C/3I/3M. Not converged (no two consecutive clean rounds); all 18 findings applied, 0 rejected.**
