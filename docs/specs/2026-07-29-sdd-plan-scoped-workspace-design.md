# SDD Plan-Scoped Workspace — Design

**Date:** 2026-07-29
**Status:** Approved (pending spec review)
**Problem:** `.superpowers/sdd/progress.md` carries no plan identity. A leftover
ledger from an earlier plan reads exactly like a finished record of the current
plan (`Task 1: complete…`), so a controller starting a new plan can conclude all
work is done and dispatch nothing. This happened in practice: a ledger from the
multi-review plan (v6.9.0) masqueraded as a completed record of the
multi-code-review plan.

## Scope

Make the SDD artifact workspace (`.superpowers/sdd/`) plan-scoped, enforced by
script — not by prose the controller must remember to follow.

- `scripts/sdd-workspace` (i.e.
  `skills/subagent-driven-development/scripts/sdd-workspace`) gains an
  optional `PLAN_FILE` argument and becomes the single enforcement point for
  plan identity. (Residual prose dependency: the
  controller must still pass `PLAN_FILE`, per the rewritten SKILL.md step 1.
  A version-skewed session calling arg-less gets stderr signal — a warning on
  a legacy workspace, an informational scoping line whenever `plan.ref`
  exists — but a pre-fix SKILL.md that ignores stderr can still misread a
  scoped workspace's ledger; the backstop informs, it cannot enforce. See
  Architecture.)
- On plan mismatch, the previous plan's artifacts are archived aside, never left
  where the controller looks.
- The check covers the **whole workspace** (ledger, task briefs, reports, review
  packages), fixing the staleness class, not just the one file.

## Non-Goals

- **Concurrent SDD runs with different plans in one worktree.** The workspace
  has never been concurrency-safe (`task-brief` overwrites shared paths).
  Note this design does add one loss mode there: run B's startup call
  relocates run A's live ledger into `archive/`, so run A's post-compaction
  recovery reads an empty ledger — today both runs at least share one
  appendable file. Accepted: concurrent same-worktree runs remain
  unsupported, and the authoritative recovery path (checkboxes + `git log`)
  still holds.
- **Plan renamed/moved mid-plan.** Identity is the plan path (repo-relative,
  or absolute physical for out-of-repo plans). A
  rename between sessions reads as a new plan and archives the workspace; the
  authoritative recovery path (plan checkboxes + `git log`, per Durable
  Progress) still works, and the archived ledger is recoverable by hand.
- **Content-based plan identity.** Editing a plan file in place does not
  trigger archiving; path identity is the contract.
- **Archive retention/pruning.** `archive/` grows until `git clean -fdx`; it is
  git-ignored scratch, same lifecycle as the rest of the workspace.
- **Ledger line-format changes.** Enforcement is script-side only (per approved
  decision); `Task N: complete (…)` lines are unchanged, and no `# Plan:`
  header is added to `progress.md`.

## Architecture

### `scripts/sdd-workspace [PLAN_FILE]`

Single source of truth for both the workspace location (as today) and, newly,
its plan identity, recorded in `<workspace>/plan.ref` (one line: the
repo-relative plan path, or the absolute physical path for out-of-repo plans).

**With `PLAN_FILE`** — the controller's one-time call at skill start:

1. Validate the plan file exists **and is readable** (`[ -f ] && [ -r ]`);
   exit 2 with usage on error (same convention as `task-brief`).
2. Normalize the given path to a repo-root-relative path. Algorithm: resolve
   `PLAN_FILE` to a **physical** absolute path against the current directory
   (`cd "$(dirname …)" && pwd -P` style, so macOS `/var` → `/private/var`
   symlink prefixes cannot defeat the comparison — this resolves directory
   symlinks only; a symlink at the file's basename is deliberately NOT
   resolved, and that dirname-physical behavior is the contract); resolve the
   repo root the same way; if the plan's physical path is under the physical
   toplevel, strip the toplevel prefix; otherwise the identity IS the
   absolute physical path (out-of-repo plans — e.g. a worktree session
   pointing at a plan in the original checkout, or plans kept in a notes
   directory — work today via `task-brief`'s any-path acceptance and must not
   regress to an error). This handles absolute, `./`-prefixed, and
   cwd-relative invocations from any subdirectory identically. Normalization
   lives in this script only — no per-caller reimplementation.
3. Compare with the existing `plan.ref`:
   - **Match** → no-op beyond ensuring the dir and `.gitignore` exist.
     Crash-recovery resume of the same plan is untouched.
   - **Fresh workspace** (no usable `plan.ref` and no content) → write
     `plan.ref`; no archive. "Content" means any entry other than
     `.gitignore`, `archive/`, and `plan.ref` itself — an empty `plan.ref`
     alone reads as fresh, keeping "empty ≡ absent" exact.
   - **Mismatch**, or **workspace has content but no `plan.ref`** (legacy
     pre-fix workspace) → archive, then write the new `plan.ref`.
4. Print the workspace path (unchanged output contract).

**Without arguments** — existing internal calls from `task-brief` and
`review-package`: resolve and print the path exactly as today. No validation;
identity is checked once at skill start, so the helpers never race it and their
call sites do not change. Two stderr backstops (stdout contract unchanged):
when the workspace has content but no `plan.ref`, the arg-less call prints a
warning (unprotected-legacy case); when `plan.ref` exists, it prints one
informational line — `workspace is scoped to plan <path>` — so a
version-skewed session whose cached SKILL.md calls arg-less at least sees
which plan the ledger belongs to before trusting it.

### Archiving

- Destination: `<workspace>/archive/<slug>/`, where `<slug>` is the basename of
  the old `plan.ref` value without extension (e.g.
  `2026-07-27-multi-code-review`), or `unknown-<timestamp>` (timestamp =
  epoch seconds, `date +%s`) when no usable `plan.ref` exists. On any
  destination collision — plan slugs and `unknown-*` alike — append a numeric
  suffix (`<slug>-2`, …).
- Everything in the workspace moves into the destination **except** `archive/`
  itself and `.gitignore`. Dotfiles other than `.gitignore` move too.
  `plan.ref` moves **last**: a crash mid-archive then leaves the remainder
  still slug-identified, so the rerun archives it under the same slug (into a
  suffixed dir) instead of scattering it under `unknown-*`.
- Archive is a move, never a delete: Minor-findings history and reports stay
  available for forensics, and a false mismatch costs the resume convenience,
  not correctness.
- `archive/` sits inside the workspace, so the existing self-ignoring
  `.gitignore` (`*`) covers it; no new ignore rules.

### SKILL.md changes (`skills/subagent-driven-development/SKILL.md`)

- Step 1 becomes: run `scripts/sdd-workspace PLAN_FILE` once. State the
  guarantee: the script archives any workspace belonging to a different plan,
  so a surviving `progress.md` is **by construction** the current plan's —
  "tasks it marks complete are DONE; never re-dispatch them" is now safe to
  trust *as plan identity*. Plan checkboxes + `git log` remain authoritative
  for position on any conflict (e.g. a `git reset --hard` rolled back commits
  the git-ignored ledger still records as complete) — the existing Durable
  Progress precedence is restated, not weakened, by the new guarantee.
- Batched Autonomous Mode's Resume Procedure (and any re-entry after
  `/clear`) must also run `scripts/sdd-workspace PLAN_FILE` before trusting
  the ledger — resume is a skill start for this purpose. If another plan ran
  in between, this archives that plan's workspace and starts the resumed
  plan with a fresh ledger; the resumed plan's own earlier ledger sits in
  `archive/<its-slug>/progress.md`, which the controller consults (read-only)
  to recover carried Minor findings for final-review triage. Position still
  comes from checkboxes + `git log`.
- Durable Progress section: one added sentence — the workspace is plan-scoped
  via `plan.ref`; prior plans' artifacts live under
  `.superpowers/sdd/archive/<slug>/`.

## Interfaces / Contracts

| Surface | Before | After |
|---|---|---|
| `sdd-workspace` | no args; prints path | `[PLAN_FILE]` optional; prints path (unchanged); exit 2 on missing/unreadable plan file |
| `task-brief`, `review-package` | call `sdd-workspace` arg-less when no explicit output path is given | unchanged |
| `progress.md` format | `Task N: complete (…)` lines | unchanged |
| `plan.ref` | — | new; one line, repo-relative plan path (absolute physical path for out-of-repo plans); written only by `sdd-workspace`. Read as: first line, trailing whitespace stripped. Empty or unreadable `plan.ref` is treated identically to "no `plan.ref`" (legacy rule, `unknown-<timestamp>` slug) — this is the recovery state after a crash during the `plan.ref` write itself |
| `archive/<slug>/` | — | new; moved prior-plan artifacts |

## Error Handling

- Missing/unreadable `PLAN_FILE` → usage message on stderr, exit 2.
- Not inside a git repo → `git rev-parse` fails; `set -euo pipefail` propagates
  (unchanged from today).
- Archive move failure or crash mid-archive → script fails loudly (`set -e`)
  and may leave the old plan's artifacts split between the workspace and a
  partial archive dir. This is recoverable, not atomic: `plan.ref` is written
  only after the move completes, so a rerun re-triggers the mismatch/legacy
  rule and archives the remainder (possibly into a suffixed second dir).

## Testing Strategy

Extend `tests/sdd-scripts/run-tests.sh` (existing suite covering these
scripts):

1. First call with plan A on a fresh repo → workspace created, `plan.ref`
   contains repo-relative plan A path.
2. Second call with plan A (and with an absolute path to plan A, and with a
   cwd-relative path from a repo subdirectory) → no archive; existing ledger
   content untouched (resume case).
3. Call with plan B after A → old content (ledger, a brief, a diff) moved to
   `archive/<slug-A>/` intact; workspace root fresh; `plan.ref` = plan B.
4. Legacy workspace: content present, no `plan.ref` → archived under
   `unknown-*`; new `plan.ref` written. Same outcome with an **empty**
   `plan.ref` (crash-during-write recovery state).
5. Arg-less call → same output path, no validation side effects (helpers'
   contract).
6. Missing plan file → exit 2. Plan file outside the repo → accepted;
   `plan.ref` holds its absolute physical path, and a repeat call with the
   same out-of-repo plan does not archive (stable identity).
7. Slug collision (A → B → A → B, with content created before each switch) →
   the fourth call archives the workspace (whose `plan.ref` is A) into
   `<slug-A>-2`, since `archive/<slug-A>/` already exists.
8. Arg-less call on a legacy workspace (content, no `plan.ref`) → warning on
   stderr, stdout path unchanged.

## Rollout

- No new skill → `hooks/skill-rules.json` unchanged.
- Version bump in `VERSION`, `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json` (+ `plugin.universal.yaml` meta), and a
  `RELEASE-NOTES.md` entry, per repo convention.
- Live behavior requires reinstalling the plugin cache (editing this repo does
  not change running sessions).
- Upgrade note: the first run after upgrade archives any pre-fix workspace
  (legacy rule above) even when resuming the same plan — a one-time cost;
  position recovery falls back to plan checkboxes + `git log` as Durable
  Progress already specifies. This also strands any carried Minor findings in
  `archive/unknown-*/progress.md`; the controller should consult that archive
  during final-review triage after an upgrade-boundary archive, mirroring the
  resume rule in SKILL.md changes.

## Failure-Mode Check (summary)

- **False mismatch archives a live workspace** (path normalization edge, plan
  rename): minor — archive-not-delete bounds damage; authoritative recovery
  path unaffected. Mitigated by single-point normalization.
- **Concurrent runs, different plans**: pre-existing limitation, non-goal.
- **Legacy heuristic archives same-plan resume once at upgrade**: accepted
  one-time cost, documented in Rollout.
- **Version-skewed session with a pre-fix SKILL.md** on a post-fix workspace:
  can still misread a scoped ledger — the arg-less stderr scoping line
  informs but cannot enforce. Residual risk, documented in Scope; resolved
  by plugin cache reinstall.

No critical failure modes in compliant sessions; worst case degrades to
today's authoritative recovery path instead of silently skipping work.
