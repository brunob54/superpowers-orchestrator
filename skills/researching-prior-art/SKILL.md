---
name: researching-prior-art
description: >
  Grounds one technology decision in verified external evidence before
  design approaches are compared. Dispatches a controller subagent that
  runs N read-only researcher subagents in parallel (candidate source
  reading, version verification anchored to this repository's manifest,
  registry existence and health, prior art) and merges their file-based
  reports into one evidence report. Invoked by brainstorming at its
  research gate with the decision, candidate list, N, and topic slug;
  or directly via /researching-prior-art. Triggers on: "research prior
  art", "prior-art research", "research the candidates", "verify the
  library", "research this dependency".
---

# Researching Prior Art

Gather verified external evidence for one technology decision, in
parallel, without touching the working tree. Evidence only — this skill
never chooses an approach.

**When invoked by brainstorming, never ask the user anything** — all
user interaction already happened at brainstorming's research gate. The
one exception: invoked directly by the user without an explicit N,
present the gate message below yourself to obtain N (the user is the
invoker; no gate has happened yet). Never pick N silently.

On that direct path, present this gate message verbatim — the same
block brainstorming presents, copied character-exactly (`<candidates>`
and `<S>` filled in — the backticks around them are placeholder
markup, dropped with the angle brackets when the values are filled;
the bracketed sentence appears only when the choice is difficult to
reverse):

> Research gate: this decision triggers prior-art research.
> Candidates: `<candidates>`.
> [This choice is difficult to reverse — consider a higher N.]
> How many research subagents should I dispatch? Suggested N=`<S>`
> (number of candidates + 3, at most 10). Reply with a number, or 0 to
> skip — a skip is recorded in the spec.

A direct invocation usually has no spec. On a 0 reply, state the skip
in the conversation and stop; record it in a spec's "Prior art and
alternatives" section only when a spec exists. A negative or
non-numeric reply → ask once more; a second unusable reply → use the
suggested `<S>` (the same rule brainstorming applies at its gate).

## Inputs (from the invoker)

- **Decision**: one sentence, with the candidate technologies named.
- **Candidates**: registry or ecosystem plus exact canonical name, per
  candidate.
- **N**: how many researcher subagents to dispatch. Valid N is 0-10; a
  larger value is clamped to 10. When brainstorming invokes this
  skill, N=0 never reaches it — brainstorming records the skip. On a
  direct invocation, a 0 reply is handled here (see the gate message
  above): state the skip and stop.
- **Topic slug**: kebab-case, no date (example: `http-retry-library`).

**Root anchoring:** everything this skill does — the git snapshot,
`.superpowers/research/`, `docs/research/` — is rooted at the top level
of the repository under research: resolve it once at invocation start
(`git rev-parse --show-toplevel`, from the repo path the invoker named
or the current repo) and use absolute paths from there, never the
session's incidental working directory.

## Trigger predicate (fired by the invoker's gate, restated here)

> This decision would add or change an entry in a dependency manifest (for
> example package.json, pyproject.toml, go.mod, Cargo.toml), or it depends
> on version-sensitive external API behavior, or it selects an external
> hosted service, platform, or base image that the system will depend on.

"Version-sensitive external API behavior" means behavior that has
changed, or is documented as changing, across the external API's
released versions — deprecations, breaking changes, or version-gated
features. The third branch covers decisions that change no manifest (a
hosted service, a CDN script tag, a Docker base image).

## Degradation ladder (detect the rung before anything else)

1. **Claude Code** — the only supported platform with nested dispatch
   (the same requirement orchestrating-development states): the full
   flow below.
2. **Agent tool present on another platform**, or the controller
   returns reporting it could not dispatch subagents: dispatch the N
   researchers directly from `research-prompt.md`; reports still go to
   files; apply the controller contract in `controller-prompt.md`
   yourself (budgets, discard rules, spot-fetch verification, merge
   rules, cache writes, re-verifier dispatch for cache hits).
   Procedure step 6 below still applies on this rung: run its checks
   after you write the merged report yourself.
3. **No Agent tool** (Codex, Cursor, OpenCode): skip. State in the
   conversation and in the spec which evidence is missing and that
   technology claims are provisional.

Researcher agent type: `Explore` where available; otherwise
`general-purpose` with the read-only instruction.

## Procedure

### 1. Snapshot the working tree

Run `git status --porcelain` at the repo root and keep the output. Not
a git repository → skip the check and state the skip in the
conversation.

### 2. Prepare the transient directory

Create `.superpowers/research/` at the repo root if missing, and write
a `.gitignore` containing exactly `*` inside it (the multi-code-review
pattern — nothing else ignores `.superpowers/`). Researchers may clone
candidate repositories under `.superpowers/research/clones/`.

Delete any existing `.superpowers/research/<slug>-*` files (a previous
run's merged report and per-researcher reports for this same topic
slug) before the controller is dispatched, so the current run cannot
inherit stale files left by an earlier failed or partial run.

### 3. Cache check (`docs/research/<candidate-slug>.md`)

**Slug rule:** prefix the registry or ecosystem in kebab-case, then the
candidate name: lowercase; drop `@`; replace `/`, `.`, spaces, and
every other non-alphanumeric character with `-`; collapse repeated `-`.
Examples: npm `lodash.merge` → `npm-lodash-merge`; `@tanstack/react-query`
on npm → `npm-tanstack-react-query`; the Stripe service →
`service-stripe`. The registry prefix and the header's canonical-name
field together prevent cross-registry and typosquat collisions.

**Header line** (first body line of a cache entry):
`_Researched: YYYY-MM-DD | registry: <registry> | canonical name: <exact name> | versions inspected: <list>_`

**Hit rule:** a cache file counts as a hit ONLY when its registry and
exact canonical name match the candidate — a slug match alone is not a
hit. A future-dated header is invalid, not fresh.

- **Fresh** (younger than 90 days): remove the candidate's
  per-candidate assignment (angles 1+5) and reduce N by exactly 1 —
  but every cache hit, fresh included, still gets a Haiku-class
  re-verifier (existence and current version), because the header is
  self-reported and a committed cache file can be planted or edited.
  Fresh-hit findings may be used provisionally while re-verification
  runs.
- **Stale** (90 days or older): same reduction, but the entry's
  findings are used only after its re-verifier confirms.
- Post-cache N is floored at 1, unconditionally — never reduced to 0,
  whether or not any candidate remains un-researched. Report the
  reduction to the invoker.
- Re-verifiers are always dispatched in addition to the (reduced) N
  and sit outside the merge/split algorithm — the researcher total may
  exceed N by the number of cache hits plus any invalidated entries;
  the controller notes this in the merged report.
- All candidates cached and fresh → the controller is STILL dispatched
  as usual, with the reduced assignment set (the re-verifiers plus the
  angle-4 researcher — prior art is decision-scoped, not
  candidate-scoped, and can never be satisfied from per-candidate
  cache files). The controller performs all its normal duties and
  writes the merged report from the cache entries and those results
  ("Sources fetched: cache + re-verification" noted). The merged
  report is always controller-written, so the file-existence check in
  step 6 holds on this path too.

Re-verifier outcomes (mismatch → invalidate and re-research; confirmed
→ keep the reduction and refresh the date) are handled by the
controller; see `controller-prompt.md`.

### 4. Resolve assignments (deterministic)

The angle catalog:

1. **Candidate implementation** (per candidate): read the candidate's
   source and test files; APIs, patterns, edge cases, boundaries, with
   citations.
2. **Version and documentation verification**: anchored to THIS
   repository's manifest/lockfile versions, not the latest release.
3. **Health, risk, and existence**: registry existence (similar-name
   confusion check), then OpenSSF criteria — maintenance activity,
   known vulnerabilities, license, security posture. (OpenSSF is the
   Open Source Security Foundation; its criteria are a standard
   checklist for project health.)
4. **Prior art and community experience**: existing solutions NOT
   among the candidates; issue trackers, migration reports,
   postmortems.
5. **Local fit**: candidate versus this repository's declared runtime
   and framework versions, license compatibility, platform
   constraints.

With C candidates remaining after cache reduction, the **ordered
assignment list** is:

1. …C: one per candidate — candidate implementation plus local fit
   (angles 1+5 merged);
2. C+1: version and documentation verification (all non-cached
   candidates);
3. C+2: health, risk, and existence (all non-cached candidates);
4. C+3: prior art and community experience.

This makes the suggested N = C+3 exact. Cached candidates are excluded
from the shared assignments (C+1, C+2); those two drop out entirely
when no non-cached candidate remains. The prior-art assignment never
drops — it is decision-scoped.

**Merging (N below the list length):** fold from the bottom of the
list upward — first C+3 into C+2, then C+2 into C+1; if the count
still exceeds N, distribute ALL remaining assignments (the folded
shared assignment included) round-robin across exactly N researchers.
This terminates for every N ≥ 1; N=1 gives a single researcher
covering the whole list.

**Splitting (N above the list length):** in order — local fit (angle
5) out of each candidate assignment, then angle 3 into registry
existence vs OpenSSF health, then angle 4 into prior-art sweep vs
community experience. If N exceeds the maximum split count for this C,
dispatch the maximum and report the difference — never invent
assignments to fill N.

### 5. Fill and dispatch the controller

Fill `./controller-prompt.md` (this skill's directory):

- `[REPO_ROOT]` — the Root-anchoring result
  (`git rev-parse --show-toplevel`, absolute); it anchors every
  controller and researcher write,
- `[DECISION]`, `[CANDIDATES]` (registry + canonical name each),
- `[ASSIGNMENTS]` — the resolved ordered list from step 4,
- `[CACHE_STATE]` — per candidate: none / fresh / stale, with entry
  paths,
- `[REPORT_DIR]` = `<repo-root>/.superpowers/research`, where
  `<repo-root>` is the Root-anchoring result
  (`git rev-parse --show-toplevel`); pass the resolved absolute path,
  never the relative form,
- `[MERGED_REPORT_FILE]` =
  `<repo-root>/.superpowers/research/<slug>-research-report.md`
  (resolved absolute path, same rule),
- `[RESEARCHER_MODELS]` — the tier mapping per assignment,
- `[RESEARCH_PROMPT_PATH]` — absolute path of `./research-prompt.md`,
- `[SLUG]` — the topic slug.

Dispatch ONE controller subagent, agent type `general-purpose`. On
rung 1, never dispatch researchers from the main session.

### 6. After the research completes (rung 1: the controller returned; rung 2: you wrote the merged report)

1. Verify `[MERGED_REPORT_FILE]` exists. Missing → report research as
   failed to the invoker: evidence gap, claims stay provisional. Never
   block the session.
2. Compare `git status --porcelain` with the step-1 snapshot. Changes
   under `docs/research/` and `.superpowers/research/` are expected.
   Any other new path, or a newly-modified previously-clean path, is
   unexpected: report the diff to the invoker (brainstorming presents
   it and asks the user whether to continue — concurrent tooling such
   as format-on-save can legitimately dirty the tree mid-research).
   Do not halt unconditionally. Honest coverage statement: this
   comparison detects new paths and newly-modified previously-clean
   paths only — it cannot see writes to files that were already dirty
   or untracked at snapshot time.
3. Report to the invoker: the merged report path, the cache reduction
   (if any), the re-verifier count, the status-comparison result, and
   the controller's summary.

## Files

| Artifact | Path | Lifetime |
|---|---|---|
| Researcher report | `.superpowers/research/<slug>-r<K>-report.md` | transient (self-gitignored) |
| Merged report | `.superpowers/research/<slug>-research-report.md` | transient (self-gitignored); survives `/clear` |
| Durable cache | `docs/research/<candidate-slug>.md` | committed |
| Spec section | "Prior art and alternatives" in the spec | committed (written by brainstorming) |

## Error handling

| Failure | Behavior |
|---|---|
| Controller subagent dies or times out (the Agent dispatch returns an error, or the platform's own timeout fires — no additional timer) | Report the failure; the invoker states the evidence gap and continues with provisional claims (never blocks the session) |
| Merged report file missing after return | Research counts as failed: evidence gap, provisional claims |
| Post-research status differs from the snapshot outside `docs/research/` and `.superpowers/research/` | Report the diff; the invoker presents it and asks the user whether to continue |
| Project is not a git repository | Cleanliness check skipped; the skip stated in the conversation |
| All researcher reports discarded | Merged report contains only evidence gaps; surfaced to the user |
| N=0 or platform skip | Brainstorming-invoked: never reaches this skill; brainstorming records the skip in the spec. Direct invocation answered 0: state the skip in the conversation and stop |

## Guard interaction

`hooks/subagent-guard.js` exempts messages opening with
`<!-- research report -->` from skill-leakage blocking — research
reports legitimately quote skill-like phrases found in external
documentation. Never remove the marker instruction from
`research-prompt.md` or `controller-prompt.md`; without it, reports
get blocked and assignments degrade to evidence gaps.
