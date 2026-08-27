# Per-topic artifact layout — design

Date: 2026-08-25
Slug: `artifact-layout`
Status: reviewed (multi-doc-review, 4 rounds, cap reached — see the
`-review-log.md` sidecar), awaiting user approval

## 1. Problem

The plugin's skills write the documents of one feature into three flat
directories: `docs/specs/` (design + review log), `docs/plans/` (plan,
review log, open-decisions, orchestration log) and `.superpowers/reviews/`
(code review log + fix reports, git-ignored). The only link between the
files of one feature is a shared `YYYY-MM-DD-<slug>` file name prefix.
Finding, archiving, or deleting "everything about feature X" means
matching prefixes across directories, and the code review history is
never committed.

## 2. Scope

One layout rule, applied everywhere the plugin writes or reads a feature
document:

- One folder per topic under `docs/superpowers-orchestrator/`, with one
  sub-folder per pipeline stage (`specs/`, `plans/`, `implementation/`).
- Code review logs and fix reports produced by the pipeline are committed
  under `implementation/`.
- Every writer, reader, hook, test and guide page that names the old
  paths is updated to the new layout.
- The existing documents in this repository are moved into the new
  layout with `git mv`.

### Non-goals

- Dual-layout support. Skills, hooks and tests know only the new layout.
- Committing per-task briefs and reports of `subagent-driven-development`
  (`.superpowers/sdd/task-N-*.md`). They stay transient.
- Any change to `docs/research/` (a cross-feature cache keyed by library
  name, not by topic), `state.md`, `session-log.md`, `known-issues.md`,
  `project-map.md`, `context-snapshot.json`, or the `.superpowers/sdd/`
  workspace.
- Marking edits under `implementation/` as "significant" in
  `hooks/stop-reminders.js`. Only `specs/` and `plans/` edits are, as
  today.
- Codex, Cursor and OpenCode hook changes. The skills are Markdown and the
  only hook file touched (`hooks/skill-rules.json`) is shared by all
  platforms.
- Detecting a second clone of the same branch (another machine, CI) that
  resumes the same committed in-progress review entry. Today's batched
  mode already resumes automatically without such detection; the tracked
  log adds no new exposure, and a machine token in the invocation entry
  would add state for a scenario branch ownership already prevents.
  Recorded as a residual risk in the release note.
- Hiding review material stored outside the plugin's own folders. The
  blinding pathspecs (section 6) hide only files whose names match the
  plugin's four sidecar patterns, inside `docs/superpowers-orchestrator/*/`
  or at the legacy locations `docs/specs/` and `docs/plans/`. The plugin
  folder holds plugin output only, and a project must not put its own
  files there; every other file — a `*-review-log.md` elsewhere, or a
  file under `implementation/` whose name matches none of the four
  patterns — stays visible to reviewers. Recorded as a residual risk in
  the release note.

No decision in this design matched the prior-art trigger predicate.

## 3. Decisions already taken (with reasons)

| Decision | Reason |
|---|---|
| Plugin name in the path (`docs/superpowers-orchestrator/`) | Separates plugin output from the project's own `docs/` tree. This reverses release v6.6.1, which removed the plugin name; the release note for this change must state the reversal and this reason. |
| Stage sub-folders `specs/`, `plans/`, `implementation/` | The three folders map to the three pipeline stages. Each skill belongs to exactly one stage, so each skill knows its output folder without a lookup table. |
| `plans/` plural, `specs/` plural | `hooks/stop-reminders.js` and `multi-doc-review` key on the path segments `specs/` and `plans/`; keeping them means no change there. |
| Review-log sidecars stay beside their document | Four skills derive the sidecar path from the document path; a `reviews/` sub-folder would hold one file and change four derivations for nothing. |
| `implementation/` holds only the code review log and the fix reports | These are the two files `.superpowers/reviews/` holds today. |
| Direct `/multi-code-review` runs stay in `.superpowers/reviews/` | A direct run has no plan and therefore no topic folder. Only pipeline-driven runs (a caller that knows the plan) commit under `implementation/`. |
| File names drop the date, keep the slug | The folder already carries the date. Keeping the slug in the basename keeps editor tabs and grep results distinguishable across topics. |
| History moved with `git mv`, contents untouched | Existing documents are historical records; only their location changes. |
| Layout defined once, cited everywhere (approach B) | The rule lives in one normative section; every skill states its own exact paths (subagents read only their own prompt) and cites that section. Same pattern as the slug rule defined once in `writing-plans`. |

Rejected: approach A (each skill derives paths on its own — five
independent derivations that drift) and approach C (a helper script like
`sdd-workspace` — an executable dependency for a rule that is two
`dirname` calls).

## 4. Layout (normative)

This section is the single definition. It is copied into
`skills/brainstorming/SKILL.md` as a section named "Artifact layout";
every other skill cites that section by name next to the exact paths it
writes.

```
docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/
  specs/<slug>-design.md                 the design (spec)
  specs/<slug>-design-review-log.md      sidecar written by multi-doc-review
  plans/<slug>.md                        the plan
  plans/<slug>-review-log.md             sidecar written by multi-doc-review
  plans/<slug>-open-decisions.md         written by orchestrating-development
  implementation/<slug>-review-log.md    code review log (multi-code-review)
  implementation/<slug>-fix-reports.md   fix reports (multi-code-review)
  <slug>-orchestration-log.md            written by orchestrating-development
```

Definitions:

- **Topic folder**: `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/`,
  relative to the repository root (`git rev-parse --show-toplevel`; for a
  project that is not a git repository, the project directory).
- **Date**: the day brainstorming creates the topic folder. Later stages
  never change it.
- **Slug**: the topic folder's basename with the `YYYY-MM-DD-` prefix
  removed. Normative charset: lowercase ASCII letters, digits and single
  hyphens — it must match `^[a-z0-9]+(-[a-z0-9]+)*$`. Brainstorming
  normalizes the topic name to this form before creating the folder
  (lowercase; every run of other characters becomes one hyphen; leading
  and trailing hyphens dropped) and refuses to create a folder whose
  name would not match. Every "outside the layout" message (sections
  5.2, 5.4, 5.6) states the reason — wrong parent directory or name not
  matching the regex — next to the expected location, so a folder that
  is already in the right place but wrongly named is not "moved onto
  itself". The plan file's basename minus `.md`
  equals the slug, so the existing rule in `writing-plans` ("plan basename
  with the `YYYY-MM-DD-` prefix and `.md` stripped, each only if present")
  still yields the slug.
- **Slug uniqueness**: at most one `????-??-??-<slug>/` folder may exist under
  `docs/superpowers-orchestrator/`. Brainstorming enforces this at
  creation (section 5.1); the orchestrator checks it at resume (section
  5.4). Every "folder for slug X" lookup in this spec matches the folder
  basename against `^[0-9]{4}-[0-9]{2}-[0-9]{2}-<slug>$` (shell glob
  `????-??-??-<slug>`), never against `*-<slug>`: the latter would also
  match `2026-01-01-user-auth/` when the slug is `auth`.
- **Topic folder derivation** from a document path: the document path
  must have the form `<D>/specs/<file>` or `<D>/plans/<file>` where `<D>`
  is a direct child of `docs/superpowers-orchestrator/` at the repository
  root and the basename of `<D>` matches
  `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`. Then `<D>` is the
  topic folder. Any other path — including every old-layout path such as
  `docs/plans/<file>` or `docs/specs/<file>`, whose `plans/` parent is
  `docs/` — is "outside the layout" (section 7). The parent check is
  what keeps old-layout paths out: without it, `docs/` would be derived
  as a topic folder. Both sides of the comparison are canonicalized
  first (`pwd -P` on the directory, as `sdd-workspace` already does;
  `realpath` where available): `git rev-parse --show-toplevel` returns
  the physical path, while a caller may hold the logical one — on macOS
  `mktemp -d` gives `/var/folders/…` and the toplevel is
  `/private/var/folders/…`, and any repository reached through a symlink
  behaves the same. A textual comparison would classify every such
  repository, including the behavioral-test fixtures, as outside the
  layout.
- **Stage folders are created on first write.** Git stores no empty
  directories, so a topic that stops at the spec stage has only `specs/`.
- **Sidecar rule (unchanged)**: a document's review log is
  `<document path minus .md>-review-log.md`, in the same directory.
- **One plan per topic**: `plans/<slug>.md` is replaced when the plan is
  rewritten; earlier versions stay in git history.
- **Orchestration log**: at the topic root, no date prefix. Each
  invocation entry inside carries its own date, as today.

## 5. Writers and readers

### 5.1 brainstorming (creates the topic folder)

- Step 11 ("save approved design") writes
  `docs/superpowers-orchestrator/<today>-<slug>/specs/<slug>-design.md`,
  creating the folders.
- Before writing: if a folder `docs/superpowers-orchestrator/????-??-??-<slug>/`
  already exists (any date), brainstorming asks the user once: reuse that
  folder (the design is written into its `specs/`, the existing design
  file is overwritten) or choose a different slug. It never creates a
  second folder for the same slug. On reuse, existing `plans/`,
  `implementation/` and orchestration-log files are left untouched;
  brainstorming lists them in its question and states the consequence:
  the orchestrator's Phase 0 precondition (plan path and log path must
  not exist) will stop until the user deletes or renames them, a
  later `multi-code-review` continues round numbering in the existing
  `implementation/` log (a new invocation entry in the same file), and
  the spec gate's review appends its rounds to the existing
  `specs/<slug>-design-review-log.md` — a log that now describes two
  documents. Brainstorming offers to move that sidecar aside
  (`<slug>-design-review-log.<old date>.md`) before the gate.
- The exit criterion "design document exists at the required path
  (`docs/specs/`)" becomes "… under `docs/superpowers-orchestrator/*/specs/`".
- The User Review Gate message is unchanged except that `<path>` is the
  new path.
- Gains the normative "Artifact layout" section (section 4 of this spec).

### 5.2 writing-plans

- Input: the spec path (as today). Topic folder = derived from the spec
  path (section 4). Output: `<topic folder>/plans/<slug>.md`.
- Spec outside the layout (section 7): writing-plans does not write a
  plan next to a spec that is outside the layout. It computes `<slug>` =
  the spec basename with `YYYY-MM-DD-`, `-design` and `.md` stripped, each
  only if present, then normalized by the "Slug" rule of section 4 (the
  same normalization brainstorming applies to a topic name; without it a
  basename such as `MyFeature-design.md` never satisfies the layout check
  and the move offer repeats on every run), names the expected location
  `docs/superpowers-orchestrator/<today>-<slug>/specs/<slug>-design.md`
  (an existing `????-??-??-<slug>/` folder is reused instead, slug uniqueness), and
  asks the user once whether to move the spec there. If the reused folder
  already holds `specs/<slug>-design.md` or its
  `specs/<slug>-design-review-log.md` sidecar, writing-plans stops and
  reports the collision — a different spec already owns that slug — and
  moves and writes nothing. On yes: `mkdir -p`
  of the `specs/` folder (git mv fails when the destination directory
  does not exist), then `git mv`
  (plain `mv` when the project is not a git repository) of the spec to
  `specs/<slug>-design.md` and, when it exists, of its `-review-log.md`
  sidecar to `specs/<slug>-design-review-log.md` — renamed together with
  the spec, because the sidecar rule derives the log name from the
  document name; a sidecar that kept its old basename would be orphaned
  and a later spec review would start a new log. Then continue with the
  moved spec. On no:
  stop; no plan is written. The invariant kept: every plan lives in a
  topic folder together with its spec.
- The slug rule text stays as is; a sentence notes that under the layout
  the plan basename is the slug itself.
- Edit sites: the primary write instruction (`SKILL.md:16`, "Save to
  `docs/plans/YYYY-MM-DD-<feature-name>.md`"), the plan-header template
  (`SKILL.md:27`, `**Spec:** docs/specs/<...>.md` — the line
  multi-doc-review reads on direct plan reviews to locate the spec, so an
  old-layout example there would produce plans whose spec path is
  outside the layout), and the handoff prompts (`docs/plans/<filename>.md`
  at lines ~187-204).
- The `state.md` seed is unchanged except for the paths it records.

### 5.3 multi-doc-review

- Sidecar rule unchanged (beside the document).
- Document-type inference for direct invocations (`SKILL.md:30-31`) is
  today a prefix rule: "under `docs/specs/` → spec, under `docs/plans/` →
  plan, else general". A new-layout path would infer `general`. It is
  rewritten to a path-segment rule, applied to the repository-relative
  path (so a clone that itself lives under a directory named `plans/`
  is not affected): the directory segment nearest the file decides —
  `specs/` → `spec`; `plans/` → `plan`; anything else → `general`. The
  `**Spec:**`-header warning for `general` documents stays.
- Examples and the reviewer isolation wording (`reviewer-prompt.md:25`,
  which lists `docs/specs/` and `docs/plans/`) are updated to
  `docs/superpowers-orchestrator/*/specs/` and `*/plans/`.

### 5.4 orchestrating-development

- Intake (Phase 0): the spec path must derive a topic folder (section 4
  rule). Slug = derived from the topic folder, not from the spec basename.
  A spec outside the layout (an old `docs/specs/…` path, or any other
  location) is a pre-log stop: report the expected location
  `docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md` and
  tell the user to move the spec and, when it exists, its `-review-log.md`
  sidecar there (`git mv`; the message names both destination paths,
  `specs/<slug>-design.md` and `specs/<slug>-design-review-log.md`) — the
  orchestrator never moves files itself and never asks a question after
  Phase 0. When the spec belongs to a run that stopped under the pre-7.3.0
  layout (a plan or an orchestration log for it exists at the old flat
  paths), the message points to the migration recipe in the v7.3.0 release
  note instead (section 8), which moves every document of the run.
- Resume step 0 ("derive `feature/<slug>` from the named path") derives
  the slug from the topic folder, same rule; a named path outside the
  layout is a stop that points to the same recipe. Resume step 1's no-log
  stop (no orchestration log matches the glob) points to the recipe for a
  run stopped under the pre-7.3.0 layout and otherwise suggests a fresh
  orchestration. Its clean-tree check
  (`SKILL.md:300-303`, today `git status --porcelain` empty with only
  `state.md` and `.superpowers/` excluded) gains the same exclusion as
  multi-code-review's precondition:
  `git status --porcelain -- ':(top)' ':(top,exclude)<topic>/implementation/*'`.
  Reason: an interruption between a round's first log write and its
  `chore(review)` commit (controller death, failed commit) leaves
  `implementation/` modified or untracked; without the exclusion, resume
  would stop with "dirty tree" before the review loop's own resume rule
  could run. The resumed loop's next `chore(review)` commit picks those
  files up.
- Phase 0 step 4 (`SKILL.md:79-82`, porcelain "empty except the spec and
  its sidecar"): after brainstorming, the topic folder is a new untracked
  directory and plain `git status --porcelain` shows it as one line
  (`?? docs/superpowers-orchestrator/<date>-<slug>/`), so neither file
  path appears. The check uses `git status --porcelain
  --untracked-files=all` and its exception reads "the spec and its
  `-review-log.md` sidecar under the topic folder's `specs/`".
- Concrete edit sites beyond the ones above:
  `plan-writer-prompt.md:62` (output plan path), Phase 5 step 3 (reports
  the code review log path — now `<topic folder>/implementation/…`), and
  the Phase 1 plan-path sentence (`docs/plans/YYYY-MM-DD-<slug>.md`).
- Prior-run detection and resume, when `feature/<slug>` already exists:
  glob
  `docs/superpowers-orchestrator/????-??-??-<slug>/<slug>-orchestration-log.md`.
  Zero matches → stop with "branch feature/<slug> exists but no
  orchestration log was found: rename the spec or delete the branch" (for a
  run stopped under the pre-7.3.0 layout, the message points to the
  migration recipe in the v7.3.0 release note). One match → compare its
  recorded spec path with the invoked spec, as today; the recorded spec
  path is read from the most recent `_Invocation` line that records one —
  a resumed override line (`_Invocation <k> — … — resumed_`) records no
  spec path (the per-parameter rule of Resume step 5). The same comparison
  runs earlier, in Phase 0 step 4, where the computed log path is tested
  BEFORE the computed plan path: the log exists → the orchestrator does not
  stop with a bare "already exists" — same spec → "prior run" with the
  resume prompt; different or missing → "unrelated prior run with the same
  slug: rename the spec or clear the old topic folder"; both stop. Only
  when no log exists and the plan path exists does the orchestrator stop
  with the bare "plan exists without a log: remove or rename it" — a run
  stopped after Phase 1 has both files and takes the log branch, so that
  bare stop is never its outcome.
  More than one match → stop with "ambiguous slug: <folders>" (slug
  uniqueness violated; the user must merge or rename before any run). The
  run stops in every case; only a branch that does not exist yet is
  created.
- Log: `<topic folder>/<slug>-orchestration-log.md`, created in step 7,
  committed as today. The log header records the spec path and the plan
  path in the new form.
- Plan path handed to the plan writer: `<topic folder>/plans/<slug>.md`.
- Open-decisions file: `<topic folder>/plans/<slug>-open-decisions.md`.
- Code review loop: the filled `code-review-loop-prompt.md` passes
  `TOPIC_DIR` = the topic folder (absolute path) to the controller, which
  passes it on to `multi-code-review` (section 5.6). The controller's
  write scope adds `<topic folder>/implementation/`.
- Phase 4 stop and resume: `unresolved > 0` or `user_decision > 0` stops
  the run; the `## STOPPED` entry names the review log and lists the open
  items by their review-log ids. `Resume orchestration` with answers to
  those ids re-dispatches the code-review-loop controller with the answers
  in the template's optional `[RESUME_ANSWER]` placeholder (same shape as
  the plan-writer and batch-controller templates); the controller records
  each answer as `decided (user): <answer>` in a post-loop addendum on the
  review log's LATEST `_Invocation` entry — the current entry is always the
  latest one, never an older entry selected by its BASE — committed as
  `chore(review): <slug> decisions`, and drops the items decided without a
  code change from the counts. An answer never requests a re-review by
  itself. Resume step 3 has a second trigger: when the effective HEAD
  (section 5.6, rule 4) has moved past that entry's completion marker —
  code was committed after the stop — Phase 4 is re-dispatched with or
  without answers, and the controller ALWAYS starts a new invocation over
  the new content (with answers, the addendum is journaled and committed
  first). Resume presents the question and stops only when the effective
  HEAD is unchanged AND no answers were given. Without answers, a
  re-dispatch over an unchanged effective HEAD returns `BLOCKED` (section
  5.6, rule 4) — never a silent no-op. The addendum is idempotent, because
  a retry after a lost return carries the same answers again: an answered
  id that already holds a `decided (user)` line is skipped, and a `fix it`
  answer whose fix commit already exists (found in `git log` by the `<sha>`
  or the subject the addendum recorded) is not dispatched again.
- `docs/research/` handling and every `state.md` rule: unchanged.

### 5.5 subagent-driven-development

- Topic folder = derived from the plan path recorded in
  `.superpowers/sdd/plan.ref` (section 4). A plan outside the layout gives
  no topic folder; the final review then runs without `TOPIC_DIR`
  (section 5.6, direct mode).
- Final whole-branch review gate (step 4, line ~77): invokes
  `multi-code-review` with `TOPIC_DIR` when a topic folder exists.
- Archive folder naming (`.superpowers/sdd/archive/<slug>/`) and the
  commit-message slug: unchanged rule, same result (section 4).

### 5.6 multi-code-review

- New optional input `TOPIC_DIR`: an absolute path to a topic folder
  under the repository root. Invocation forms: `/multi-code-review [BASE]
  [N]` (direct, no `TOPIC_DIR`) and the pipeline gate call (with
  `TOPIC_DIR`).
- With `TOPIC_DIR` (pipeline mode): log =
  `<TOPIC_DIR>/implementation/<slug>-review-log.md`, fix reports =
  `<TOPIC_DIR>/implementation/<slug>-fix-reports.md`, `<slug>` derived
  from `TOPIC_DIR`'s basename. The folder is created on first write, no
  `.gitignore` inside. Pipeline mode changes four rules of the skill,
  each stated explicitly in `multi-code-review/SKILL.md` next to the
  direct-mode rule it replaces:
  1. **Log commits.** After every round, after that round's fix commits:
     `git add -- <log>` (plus `<fix reports>` when the file exists — it
     exists only once a fix subagent has written to it), then
     `git commit -m "chore(review): <slug> round <i> log" -- <log>
     [<fix reports>]`. The `git add` is required because `git commit --
     <path>` fails on a file git does not know yet; the path-limited
     commit keeps the user's other staged files out. The fix subagent
     never stages the fix-report file, even though it appends to it
     (`SKILL.md:160-166` says the fix subagent stages "the files it
     changed" — the fix-report file is excluded from that rule): the
     controller's round commit owns both files. The completion
     marker and any post-loop addendum are committed the same way with
     subject `chore(review): <slug> completed`; a `skipped` (N=0) entry
     the same way with subject `chore(review): <slug> skipped`; a
     post-loop addendum recording the user's decisions on open items
     (`decided (user): <answer>`) the same way with subject
     `chore(review): <slug> decisions`. Each round and the loop
     itself end with a tree that is clean except for changes that
     already existed when the loop started (the precondition in rule 2
     lets an interactive user consent to fixing on top of such changes;
     they are never swept into a `chore(review)` commit).
  2. **Working-tree precondition.** The `git status --porcelain` check
     before a fix dispatch excludes the topic's implementation folder:
     `git status --porcelain -- ':(top)' ':(top,exclude)<topic>/implementation/*'`.
     Without the exclusion the untracked log (round 1) or the modified
     log and fix reports (later rounds) would fail the check on every
     round.
  3. **Tracked-log sentinel.** The rule "a log tracked in the branch is
     set aside as abandoned" applies to direct mode only. In pipeline
     mode the log is tracked by design. Resumption uses the entry rules
     alone: an invocation entry with no completion marker and matching
     invoker kind and BASE is resumed at its next round; a mismatched
     entry is marked `abandoned` and a new invocation entry is appended
     to the same file (the file is never moved aside — its history is
     committed).
  4. **Completion marker and once-per-gate skip.** Define the
     *effective HEAD* as the newest commit in `BASE..HEAD` that changes
     at least one path outside the blinding pathspec set of section 6
     (`git log -1 --full-history --format=%H BASE..HEAD -- <the blinding
     pathspecs>`); the commit subject plays no part, so a user commit
     titled `chore(review): …` that changes code is the effective HEAD
     and a commit with any other subject that changes only a sidecar is
     not. When no commit in that range changes such a path (N=0, or a
     branch that received only sidecar commits), the effective HEAD is
     BASE.
     In pipeline mode
     the completion marker records the effective HEAD — never the raw
     `git rev-parse HEAD`, which at marker time is always the last
     round's log commit. The post-loop addendum updates the marker with
     the same definition. The once-per-gate skip and the orchestrator's
     retry protection compare the recorded HEAD with the current
     effective HEAD. Direct mode keeps the raw `git rev-parse HEAD` in
     both places, as today. The "log not tracked" condition of the skip
     applies to direct mode only. The skip applies only to an invocation
     that ended with `unresolved = 0` and `user_decision = 0`; with open
     items, an unchanged effective HEAD and no decisions supplied by the
     invoker, the loop returns `BLOCKED: previous invocation left <n>
     open items and the effective HEAD is unchanged; resume with answers`
     instead of re-running or synthesizing. Decisions supplied by the
     invoker are journaled idempotently (an id already decided is skipped,
     a fix already committed is not dispatched again), and a new
     invocation starts only when the effective HEAD has moved past the
     completion marker (section 5.4, "Phase 4 stop and resume").
- Without `TOPIC_DIR` (direct mode): exactly today's behavior —
  `.superpowers/reviews/<branch-slug>-review-log.md`,
  `<branch-slug>-fix-reports.md`, `.gitignore` containing `*`, nothing
  committed, sentinel and skip rules unchanged.
- Validation: `TOPIC_DIR` must be a topic folder by the section 4 rule
  — a direct child of `docs/superpowers-orchestrator/` at the repository
  root whose basename matches the date-slug regex. Anything else (a path
  outside the root, `docs/reviews/foo/`, a folder without a date prefix)
  → stop with an error naming the path before any round; otherwise the
  precondition pathspec and the diff exclusion, which are written for
  the section 4 form, would silently miss it. `<slug>` = the basename
  minus the date prefix. `<topic>` in the pathspecs below = `TOPIC_DIR`
  with `<repo root>/` stripped (pathspecs with `:(top)` are
  repository-relative). A valid `TOPIC_DIR` that does not exist yet →
  created (the caller may invoke the gate before any other stage wrote
  into the folder). Two more checks run at invocation start, before
  round 1: `git check-ignore -q <log path>` must fail (a project
  `.gitignore` that matches `implementation/` or `*-review-log.md` would
  otherwise surface only as a failed commit after a full round); and
  when the log or the fix-report file differs from HEAD (a previous
  round's `chore(review)` commit failed or was interrupted), the pending
  commit is retried first with the same subject rule — on repeated
  failure the skill returns `BLOCKED` with the git output and names the
  manual commit (`git add -- <paths> && git commit -m "<the pending
  subject>" -- <paths>`) the user must run. Without this
  retry, an on-disk entry with a completion marker would be read as
  completed, the once-per-gate skip would fire, and the orchestrator's
  Phase 5 clean-tree check would stop the run with no path to recovery.

### 5.7 context-management

- The "does a plan exist" lookup (`SKILL.md:72-75`) uses
  `docs/superpowers-orchestrator/*/plans/*.md`.

### 5.8 Hooks

- `hooks/skill-rules.json:191`: the orchestrating-development intent
  pattern `orchestrate\b[\s\S]{0,80}?docs[\/]specs[\/]` becomes
  `orchestrate\b[\s\S]{0,80}?docs[\/]superpowers-orchestrator[\/][^\s]+[\/]specs[\/]`.
- `hooks/stop-reminders.js:298-299`: unchanged. A unit-test fixture with a
  new-layout path proves the `specs/` and `plans/` regexes still match.
- `hooks/track-edits.js`, `hooks/session-start`, the Codex adapters:
  untouched (they handle the root memory files only).

## 6. Reviewer blinding

Committed review material is now part of the branch. Two measures, both
required:

1. **Diff exclusion.** Every whole-branch diff handed to a reviewer is
   produced with the pathspecs
   `-- ':(top)' ':(top,exclude)docs/superpowers-orchestrator/*/*-review-log.md' ':(top,exclude)docs/superpowers-orchestrator/*/*-fix-reports.md' ':(top,exclude)docs/superpowers-orchestrator/*/*-orchestration-log.md' ':(top,exclude)docs/superpowers-orchestrator/*/*-open-decisions.md' ':(top,exclude)docs/specs/*-review-log.md' ':(top,exclude)docs/plans/*-review-log.md' ':(top,exclude)docs/plans/*-orchestration-log.md' ':(top,exclude)docs/plans/*-open-decisions.md'`.
   Every exclusion names one of the plugin's four sidecar patterns and
   is anchored to a folder the plugin writes to:
   `docs/superpowers-orchestrator/`, its own output folder, or one of the
   two legacy locations (`docs/specs/`, `docs/plans/`) it wrote to before
   the topic-folder layout. Nothing else is hidden: a file outside those
   folders is never hidden, whatever its name, and a file under
   `implementation/` whose name matches none of the four patterns (a
   `CLAUDE.md`, a note) is shown — hidden, such a file would reach the
   controller, which reads that folder every round, and no reviewer.
   Without the anchor, a branch could hide any file from every reviewer
   round by giving it one of these names. No `glob` magic is used: a
   plain `*` in a git pathspec matches across `/`, which is what lets
   `*/` stand for the topic folder and `*-review-log.md` for a sidecar
   at any depth below it. The four legacy entries exist for sidecars
   moved out of the old layout with `git mv`: git pairs a rename only
   when both sides of the move are in the diff, so with the destination
   excluded and the source not, the move appears as a deletion of the
   source whose hunk carries the sidecar's whole old content; excluding
   the source paths too removes the hunk, while a moved file that is not
   a sidecar still appears as an ordinary rename.
   The orchestration-log and open-decisions entries matter on a resumed
   run: after a Phase 4 stop the
   orchestrator commits the orchestration log and the open-decisions
   file, both of which quote prior findings; without the exclusion every
   reviewer of the resumed loop would read them in the diff. In
   `review-package` the pathspecs apply to all three commands it runs —
   `git log --oneline`, `git diff --stat` and `git diff` — so the commit
   list shows no `chore(review)` commits without visible hunks.
   The `top` magic anchors every pathspec at the repository root, which
   makes the commands independent of the current directory: a plain
   `-- .` is relative to the cwd, and the sdd per-task caller of
   `review-package` may run from any directory, where `-- .` would
   silently restrict the diff to that subtree and the exclusions would
   never match. multi-code-review already anchors its commands at the
   repository root ("Root anchoring", `SKILL.md:89-94`); `:(top)` is
   harmless there and keeps one form everywhere. Places:
   the diff commands in `multi-code-review/SKILL.md`, the
   `subagent-driven-development/scripts/review-package` script (both
   modes), the orchestrator's `code-review-loop-prompt.md`, and the
   reviewer's own fallback commands in
   `multi-code-review/reviewer-prompt.md:58-60` (`git diff --stat
   BASE..HEAD` and `git diff BASE..HEAD`, used when the package file is
   missing). This also closes the pre-existing leak of the committed
   doc-review sidecars.
2. **Read prohibition.** `multi-code-review/reviewer-prompt.md:24-25`
   already lists `*-review-log.md` and `*-fix-reports.md`; it gains
   `*-orchestration-log.md` and `*-open-decisions.md`, with all four
   name shapes limited to files under `docs/superpowers-orchestrator/*/`,
   plus the four legacy sidecar locations (`docs/specs/*-review-log.md`,
   `docs/plans/*-review-log.md`, `docs/plans/*-orchestration-log.md`,
   `docs/plans/*-open-decisions.md`) — the same surface as the diff
   exclusion, so the read prohibition cannot hide what the pathspecs
   show. The orchestrator's triage rule
   (`code-review-loop-prompt.md:53-55`), which discards findings whose
   subject file is an orchestration artifact, extends its list from
   `*-orchestration-log.md`, plan checkbox ticks and `*-review-log.md` to
   `*-fix-reports.md` and `*-open-decisions.md`, limited to the same
   folders — so a reviewer that still sees these files (fallback path)
   produces no spurious finding per round, and a finding about a file
   outside those folders is never discarded by name.

Fix subagents keep receiving the findings through their brief, never
through the log — unchanged.

**Git assumptions** (sections 4, 5.6 and 6): pathspec magic `top` and
`exclude` is documented in `gitglossary(7)` ("pathspec");
`git commit -- <path>` on a file git does not track fails, and a
path-limited commit leaves other staged files staged, per
`git-commit(1)`; git stores no empty directories; `git mv` fails when
the destination directory does not exist (`mkdir -p` first). Minimum git
version assumed: 2.32 — implied by the `git commit --trailer` use of the
v7.1.0 commit convention but stated nowhere yet; the release note of this
change states it explicitly (section 10). All behaviors above were
reproduced on git 2.50.1 during review. Unverified assumption: under
Windows Git Bash (MSYS), argument path conversion leaves pathspecs that
start with `:(` untouched. Section 9 includes a one-time check; if the
conversion mangles them, the documented workaround is
`MSYS_NO_PATHCONV=1` in front of those commands.

## 7. Error handling

| Situation | Behavior |
|---|---|
| Brainstorming finds an existing `????-??-??-<slug>/` folder | Ask once: reuse or new slug. Never a second folder. |
| Orchestrator resume glob matches more than one folder | Stop: "ambiguous slug", list the folders. Pre-log stop (nothing written). |
| Spec outside the layout given to writing-plans | Name the expected location, ask once to move the spec and its sidecar (`git mv`); on no, stop without writing a plan. |
| Spec outside the layout given to orchestrating-development | Pre-log stop: report the expected location for the spec and its sidecar; the user moves them. |
| Plan outside the layout in `plan.ref` | Final review runs in direct mode (`.superpowers/reviews/`), reported in the completion message. |
| `TOPIC_DIR` outside the repository root | multi-code-review stops before round 1 with an error naming the path. |
| `chore(review)` commit fails (hook, signing prompt, conflict) | multi-code-review stops the loop after the round and reports the failure; the log and fix reports stay on disk uncommitted. The next invocation retries the pending commit before round 1 (section 5.6 validation); a second failure returns `BLOCKED` naming the manual commit. |
| Existing `.superpowers/sdd/plan.ref` points at a moved plan | The next sdd run treats it as a plan switch and archives the workspace under `archive/<old plan basename>/` (`sdd-workspace` names the archive after the old `plan.ref` basename minus `.md`, date included) — expected after migration; documented in the release note. |

## 8. Migration of this repository

`git mv` only; file contents untouched (they are historical records).
Every move is preceded by `mkdir -p` of the destination stage folder.

1. For each of the 7 topics in `docs/specs/` + `docs/plans/`
   (`sdd-batched-autonomous-mode`, `sdd-token-optimization`,
   `multi-review`, `multi-code-review`, `sdd-plan-scoped-workspace`,
   `orchestrating-development`, `researching-prior-art`): create
   `docs/superpowers-orchestrator/<spec date>-<slug>/`, move the design and
   its review log into `specs/` and the plan, its review log, the
   open-decisions file into `plans/`, the orchestration log to the topic
   root; rename each file to the dateless form of section 4. The
   `multi-review` topic keeps its historical slug (the skill was renamed
   later).
2. The 7 March–April files already under
   `docs/superpowers-orchestrator/{specs,plans}/`. One pair belongs to
   one topic: `specs/2026-03-24-autoimprove-design.md` and
   `plans/2026-03-24-autoimprove-plan.md` go together into
   `2026-03-24-autoimprove/` as `specs/autoimprove-design.md` and
   `plans/autoimprove.md`. The other five each get their own
   `<date>-<slug>/` folder, where `<date>` is the file's own date prefix
   and `<slug>` is the basename with the date prefix, a trailing
   `-design` or `-plan`, and `.md` stripped (so
   `2026-03-15-subagent-behavioral-contracts-design.md` gives the folder
   `2026-03-15-subagent-behavioral-contracts/`). Rename rule for this item: a spec file
   becomes `specs/<slug>-design.md` (strip the date; add `-design` when
   the basename lacks it, so
   `2026-03-16-meta-memory-behavioral-self-evolution.md` becomes
   `specs/meta-memory-behavioral-self-evolution-design.md`); a plan file
   becomes `plans/<slug>.md` (strip the date and a trailing `-plan`, so
   `2026-04-14-flawless-audit-plan.md` becomes `plans/flawless-audit.md`).
   Then delete the two old flat folders and remove `.gitignore:19`, which
   ignores a path under the deleted `specs/` folder.
3. This spec (`docs/specs/2026-08-25-artifact-layout-design.md`) and its
   review log: moved into `2026-08-25-artifact-layout/specs/`.
4. `docs/2026-08-22-prior-art-research-step-design.md` at the `docs/`
   root: the plan classifies it (duplicate of the `researching-prior-art`
   design → delete; separate document → move into that topic's `specs/`).
5. Update every link to a moved file in `RELEASE-NOTES.md`, `README.md`,
   `docs/guide/README.md`, `docs/FORK-IMPROVEMENTS.md`,
   `docs/architecture/project-memory.md`, and the autoimprove fixture
   `tools/autoimprove/test-cases.json` (search `docs/specs/`,
   `docs/plans/`, `docs/superpowers-orchestrator/specs`,
   `docs/superpowers-orchestrator/plans`). References inside the moved
   historical documents themselves are left as they are (item "contents
   untouched").
6. `.superpowers/reviews/` in this repository: untouched (transient).

Other projects using the plugin: no automatic migration. Their existing
`docs/specs/` and `docs/plans/` files stay readable as plain files; new
topics use the new layout. The release note says so. A run that stopped
under the old layout is moved by hand with the recipe in the v7.3.0
release note: create the topic folder with `specs/` and `plans/`; `git mv`
the spec, the plan, their `-review-log.md` sidecars and the orchestration
log into it, dropping the date prefix from the file names; edit the
recorded paths (the orchestration log's `_Invocation` header `spec` path
and `plan:` line, the plan's `**Spec:**` header); commit; then
`Resume orchestration for <new plan path>`. Every orchestrator stop that
such a run can reach points to that recipe: the topic-folder derivation
failure (Phase 0 step 4 and Resume step 0 — the old paths are outside the
layout), the zero-match stop (Phase 0 step 5, reached when only the spec
was moved), and Resume step 1's no-log stop.

## 9. Testing strategy

Unit tests (fast, run first):

- `tests/codex/test-skill-activator.js`: the orchestrating-development
  intent pattern matches
  `orchestrate the development of docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design.md`
  and no longer matches `docs/specs/2026-08-04-foo-design.md`.
- `tests/codex/test-stop-reminders.js`: fixtures
  `docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design.md` and
  `.../plans/foo.md` classify as significant;
  `.../implementation/foo-review-log.md` does not.
- `tests/sdd-scripts/run-tests.sh`: `review-package` output excludes a
  committed `implementation/foo-review-log.md`, a `*-review-log.md`
  sidecar under `specs/`, and includes an ordinary source change from the
  same commits. The same run proves the folder rule and the anchoring on
  a throwaway repository, with the real `review-package` script:
  `implementation/leak-check.md` (a name that matches no sidecar
  pattern) is excluded; `implementation/code.js`, `notes/x-review-log.md`
  and `src/implementation/real.js` (outside the plugin folder) are
  included. Archive folder naming with a dateless plan basename yields
  the same slug.

Behavioral tests (real `claude` CLI, slow):

- `tests/claude-code/test-multi-doc-review.sh`: fixture at
  `docs/superpowers-orchestrator/<date>-test-feature/specs/test-feature-design.md`;
  asserts the sidecar next to it.
- `tests/claude-code/test-multi-code-review.sh`: two cases. Direct: log
  under `.superpowers/reviews/`, nothing committed. `TOPIC_DIR`: log and
  fix reports under `<topic>/implementation/`, one `chore(review)` commit
  per round, working tree clean at the end, and the review package file
  whose path the log records (the diff file under `.superpowers/sdd/`)
  does not contain the log's own text.
- `tests/claude-code/test-helpers.sh` `create_plan` and the sdd
  integration fixture: new plan path.
- `tests/claude-code/test-batched-autonomous-mode.sh`,
  `tests/claude-code/test-researching-prior-art.sh`, and
  `tests/claude-code/test-researching-prior-art-gate.sh`: new spec/plan
  paths in their fixtures and prompts; the `researching-prior-art` test's
  ignored-artifact allow-list is unchanged (`docs/research/` does not
  move).
- `tests/explicit-skill-requests/` and `tests/skill-triggering/` prompt
  texts that mention `docs/plans/...` or `docs/specs/...`: updated so the
  routing tests exercise the new phrasing.

Recovery greps stay intact: a test asserts that
`chore(review): foo round 1 log` matches neither the batch-controller's
`task <n> complete` pattern nor the `review fixes (<slug>, round <i>)`
pattern.

Pipeline-mode git rules (section 5.6) get script-level tests in
`tests/sdd-scripts/run-tests.sh` or a sibling file, on a throwaway
repository: the `git add` + path-limited `git commit` sequence commits an
untracked log while leaving an unrelated staged file staged; the
precondition command with the `:(top,exclude)` pathspec reports clean
with a modified `implementation/` log and dirty with a modified source
file; the effective-HEAD rule returns the newest commit in `BASE..HEAD`
that changes a path outside the blinding pathspec set, so a top
`chore(review):` commit that changes only review material is skipped.

One-time platform check, recorded in
`tests/codex/post-push-validation-checklist.md`: under Windows Git Bash,
run `git status --porcelain -- ':(top)' ':(top,exclude)docs/x/'` and
`git diff HEAD~1 -- ':(top,exclude)docs/superpowers-orchestrator/*/*-review-log.md'` in a
throwaway repository and confirm the pathspecs are not rewritten (the
output must exclude the named paths). If they are rewritten, prefix the
commands in the skills with `MSYS_NO_PATHCONV=1` (section 6, Git
assumptions).

## 10. Release and documentation

- Version 7.3.0 in `VERSION`, `.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, the
  README version badge, and the two `v6.7.0–vX.Y.Z` ranges in the README
  lineage note.
- `RELEASE-NOTES.md` entry: the layout, the reason the plugin name returns
  to the path (reverses v6.6.1), the committed code reviews, the
  `TOPIC_DIR` input, the blinding exclusion, the migration of this
  repository, the note for other projects (section 8), and the minimum
  git version (2.32, needed for `--trailer` and assumed by the pathspec
  magic) — stated explicitly for the first time, also added to the
  README requirements.
- `docs/guide/README.md`: every path example and the pipeline diagrams;
  the "committed artifacts" paragraph (~line 572) lists `implementation/`;
  one sentence states that the topic folder is always anchored at the
  repository root — a sub-project inside a monorepo gets its documents at
  the monorepo root, and relocating the folder makes every document
  "outside the layout".
- `README.md` How-It-Works counts if a rule is added or removed.
- Reinstall the local plugin before behavioral testing (sessions run the
  installed copy).

## 11. Open questions

None. All decisions are in section 3; the classification of the stray
file in section 8 item 4 is a planning task, not a design question.
