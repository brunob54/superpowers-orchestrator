# Per-Topic Artifact Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every pipeline document of one feature into a single per-topic folder `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/` with stage sub-folders `specs/`, `plans/`, `implementation/`, commit the pipeline's code-review logs under `implementation/`, and update every writer, reader, hook, test and guide page accordingly.

**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-08-25-artifact-layout/specs/artifact-layout-design.md`

**Architecture:** The layout rule is written once, as a normative "Artifact Layout" section inside `skills/brainstorming/SKILL.md`. Every other skill states its own exact paths next to a citation of that section by name — subagents read only their own prompt, so no skill may rely on a lookup elsewhere. `multi-code-review` gains one optional input, `TOPIC_DIR`; with it, the skill runs in *pipeline mode* (log and fix reports committed under `<TOPIC_DIR>/implementation/`), without it in *direct mode* (today's git-ignored `.superpowers/reviews/`, unchanged). Reviewer blinding is preserved by adding git pathspec exclusions to every whole-branch diff command and by extending the reviewer's read prohibition.

**Tech Stack:** Markdown skill files, Node >= 16 hook scripts (`hooks/`), Bash scripts (`skills/subagent-driven-development/scripts/`), Bash test suites (`tests/`), JSON hook configuration (`hooks/skill-rules.json`). No build step.

**Assumptions:**

- Assumes git >= 2.32 — will NOT work if the user's git does not support the pathspec magic `top`, `exclude` and `glob`, or `git commit --trailer`. The release note (Task 22) states this floor for the first time.
- Assumes `git commit -- <path>` fails on a path git does not yet track — will NOT work if a future git version changes this; every pipeline-mode commit therefore runs `git add -- <paths>` first.
- Assumes git stores no empty directories — will NOT work as described if a topic that stopped at the spec stage is expected to show an empty `plans/` folder after a fresh clone. Stage folders are created on first write only.
- Assumes Windows Git Bash (MSYS) leaves arguments beginning with `:(` untouched. This is UNVERIFIED. Task 18 records a one-time manual check; if the conversion mangles them, the documented workaround is `MSYS_NO_PATHCONV=1` in front of those commands.
- Assumes the currently running orchestration of this very plan holds `docs/plans/2026-08-25-artifact-layout.md` and `docs/plans/2026-08-25-artifact-layout-orchestration-log.md` open by path. Task 19 therefore does NOT move those two files — moving the plan mid-run would break every later checkbox-tick commit (`subagent-driven-development/SKILL.md:74` stages the plan file by explicit path). Their move is a documented post-run manual step (Task 22).
- Assumes behavioral tests (`tests/claude-code/`) run against the INSTALLED plugin copy under `~/.claude/plugins/cache/superpowers-orchestrator/`. Editing `skills/` in this repository does not change live session behavior; the plugin must be reinstalled before those tests are run.

**Global Constraints:** *(copied verbatim from the spec; they bind every task)*

- Topic folder: `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/`, relative to the repository root (`git rev-parse --show-toplevel`; for a project that is not a git repository, the project directory).
- Slug charset is normative: lowercase ASCII letters, digits and single hyphens — it must match `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Slug uniqueness: at most one `????-??-??-<slug>/` folder may exist under `docs/superpowers-orchestrator/`. Every "folder for slug X" lookup matches the folder basename against `^[0-9]{4}-[0-9]{2}-[0-9]{2}-<slug>$` (shell glob `????-??-??-<slug>`), never against `*-<slug>`: the latter would also match `2026-01-01-user-auth/` when the slug is `auth`.
- Topic folder derivation from a document path: the document path must have the form `<D>/specs/<file>` or `<D>/plans/<file>` where `<D>` is a direct child of `docs/superpowers-orchestrator/` at the repository root and the basename of `<D>` matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`. Any other path — including every old-layout path such as `docs/plans/<file>` or `docs/specs/<file>` — is "outside the layout". Both sides of the comparison are canonicalized first (`pwd -P` on the directory, `realpath` where available).
- Stage folders are created on first write. Sidecar rule (unchanged): a document's review log is `<document path minus .md>-review-log.md`, in the same directory.
- One plan per topic: `plans/<slug>.md` is replaced when the plan is rewritten. Orchestration log sits at the topic root, no date prefix.
- No dual-layout support. Skills, hooks and tests know only the new layout.
- The blinding pathspec set, used verbatim in every whole-branch diff command:
  `-- ':(top)' ':(top,exclude)docs/superpowers-orchestrator/*/implementation/' ':(top,exclude,glob)**/*-review-log.md' ':(top,exclude,glob)**/*-fix-reports.md' ':(top,exclude,glob)**/*-orchestration-log.md' ':(top,exclude,glob)**/*-open-decisions.md'`
- Direct `/multi-code-review` runs (no `TOPIC_DIR`) keep exactly today's behavior: `.superpowers/reviews/`, a `.gitignore` containing `*`, nothing committed, sentinel and skip rules unchanged.
- Migration of existing documents uses `git mv` only; file contents are untouched. References inside the moved historical documents are left as they are.
- Not in scope: `docs/research/`, `state.md`, `session-log.md`, `known-issues.md`, `project-map.md`, `context-snapshot.json`, the `.superpowers/sdd/` workspace, `hooks/stop-reminders.js` significance rules, and Codex/Cursor/OpenCode hook wiring.

---

## File Structure

**Skills (Markdown — the layout rule and every path that cites it)**

| File | Responsibility after this plan |
|---|---|
| `skills/brainstorming/SKILL.md` | Holds the single normative "Artifact Layout" section; creates the topic folder; handles an existing folder for the same slug |
| `skills/writing-plans/SKILL.md` | Writes `<topic>/plans/<slug>.md`; handles a spec outside the layout |
| `skills/multi-doc-review/SKILL.md` | Path-segment doc-type inference |
| `skills/multi-doc-review/reviewer-prompt.md` | Reviewer read scope names the new folders |
| `skills/orchestrating-development/SKILL.md` | Derives the topic folder at intake and at resume; log, plan and open-decisions paths |
| `skills/orchestrating-development/plan-writer-prompt.md` | New plan output path wording |
| `skills/orchestrating-development/code-review-loop-prompt.md` | Passes `TOPIC_DIR`; controller write scope; extended triage list |
| `skills/subagent-driven-development/SKILL.md` | Derives the topic folder from `plan.ref`; passes `TOPIC_DIR` to the final gate |
| `skills/multi-code-review/SKILL.md` | `TOPIC_DIR` input, pipeline mode (4 rule changes), blinding pathspecs |
| `skills/multi-code-review/reviewer-prompt.md` | Extended read prohibition; blinded fallback diff commands |
| `skills/context-management/SKILL.md` | New plan-lookup glob |

**Executable and configuration**

| File | Responsibility |
|---|---|
| `skills/subagent-driven-development/scripts/review-package` | Applies the blinding pathspecs to both modes |
| `hooks/skill-rules.json` | orchestrating-development intent pattern matches the new spec path shape |

**Tests**

| File | Responsibility |
|---|---|
| `tests/codex/test-skill-activator.js` | Routing on new-layout spec paths |
| `tests/codex/test-stop-reminders.js` | Significance classification on new-layout paths |
| `tests/sdd-scripts/run-tests.sh` | `review-package` exclusions, pipeline-mode git rules, recovery greps |
| `tests/claude-code/test-multi-doc-review.sh` | Fixture in the new layout |
| `tests/claude-code/test-multi-code-review.sh` | Direct case + `TOPIC_DIR` case |
| `tests/claude-code/test-helpers.sh` | `create_test_plan` writes into the new layout (an unused helper — no test calls it today; kept consistent so a future caller does not resurrect the old path) |
| `tests/claude-code/test-subagent-driven-development-integration.sh`, `tests/explicit-skill-requests/*.sh`, `tests/skill-triggering/prompts/*.txt`, `tools/autoimprove/test-cases.json` | Prompt and fixture paths |
| `tests/codex/post-push-validation-checklist.md` | One-time Windows pathspec check |

**Repository content and release**

`docs/superpowers-orchestrator/<date>-<slug>/…` (migration target), `.gitignore`, `README.md`, `RELEASE-NOTES.md`, `docs/guide/README.md`, `docs/FORK-IMPROVEMENTS.md`, `docs/architecture/project-memory.md`, `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`.

---

### Task 1: Normative "Artifact Layout" section in brainstorming

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q '^## Artifact Layout$' skills/brainstorming/SKILL.md \
  && grep -q 'docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/' skills/brainstorming/SKILL.md \
  && ! grep -q 'docs/specs/YYYY-MM-DD-' skills/brainstorming/SKILL.md \
  && ! grep -q 'required path (`docs/specs/`)' skills/brainstorming/SKILL.md \
  && echo PASS || echo FAIL
```

Step 4 changes the old path in **two** places — `SKILL.md:53` (the save instruction) and `SKILL.md:247` (the exit criterion) — so the gate carries one negative needle per place. A single bare `! grep -q 'docs/specs/'` would NOT work here: the "Topic folder derivation" bullet that Step 3 inserts names `docs/specs/<file>` itself, as the example of a path outside the layout, so the bare needle would still match after both edits and the gate could never pass.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL` — the section does not exist yet and `SKILL.md:53` and `SKILL.md:247` still name the old path.

- [x] **Step 3: Insert the section between the Checklist and the Process Flow**

Insert immediately before the line `## Process Flow` in `skills/brainstorming/SKILL.md`:

````markdown
## Artifact Layout

This section is the single normative definition of where the pipeline's
documents live. Other skills state their own exact paths and cite this
section by name.

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

- **Topic folder:** `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/`,
  relative to the repository root (`git rev-parse --show-toplevel`; for a
  project that is not a git repository, the project directory).
- **Date:** the day brainstorming creates the topic folder. Later stages
  never change it.
- **Slug:** the topic folder's basename with the `YYYY-MM-DD-` prefix
  removed. It must match `^[a-z0-9]+(-[a-z0-9]+)*$` — lowercase ASCII
  letters, digits, single hyphens. Brainstorming normalizes the topic name
  to this form before creating the folder (lowercase; every run of other
  characters becomes one hyphen; leading and trailing hyphens dropped) and
  refuses to create a folder whose name would not match.
- **Slug uniqueness:** at most one `????-??-??-<slug>/` folder may exist
  under `docs/superpowers-orchestrator/`. Every "folder for slug X" lookup
  matches the folder basename against
  `^[0-9]{4}-[0-9]{2}-[0-9]{2}-<slug>$` (shell glob `????-??-??-<slug>`),
  never against `*-<slug>` — the latter would also match
  `2026-01-01-user-auth/` when the slug is `auth`.
- **Topic folder derivation** from a document path: the path must have the
  form `<D>/specs/<file>` or `<D>/plans/<file>`, where `<D>` is a direct
  child of `docs/superpowers-orchestrator/` at the repository root and the
  basename of `<D>` matches
  `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`. Then `<D>` is the
  topic folder. Any other path — including every old-layout path such as
  `docs/plans/<file>` or `docs/specs/<file>`, whose `plans/` parent is
  `docs/` — is **outside the layout**. Canonicalize both sides before
  comparing (`pwd -P` on the directory; `realpath` where available):
  `git rev-parse --show-toplevel` returns the physical path while a caller
  may hold the logical one, and a textual comparison would classify a
  repository reached through a symlink as outside the layout.
- **Stage folders are created on first write.** Git stores no empty
  directories, so a topic that stops at the spec stage has only `specs/`.
- **Sidecar rule:** a document's review log is
  `<document path minus .md>-review-log.md`, in the same directory.
- **One plan per topic:** `plans/<slug>.md` is replaced when the plan is
  rewritten; earlier versions stay in git history.
- **Orchestration log:** at the topic root, no date prefix. Each invocation
  entry inside carries its own date.
- The topic folder is always anchored at the **repository root**. A
  sub-project inside a monorepo gets its documents at the monorepo root;
  relocating the folder makes every document "outside the layout".
````

- [x] **Step 4: Update the two path statements in the checklist and the exit criteria**

In `skills/brainstorming/SKILL.md`, replace line 53:

```markdown
11. Save approved design to `docs/specs/YYYY-MM-DD-<topic>-design.md`.
```

with:

```markdown
11. Save approved design to
   `docs/superpowers-orchestrator/<today>-<slug>/specs/<slug>-design.md`,
   creating the folders (see **Artifact Layout** below; `<slug>` is the
   normalized topic name, `<today>` is today's date). Before writing, run
   the existing-folder check in **Artifact Layout — reusing an existing
   topic folder**.
```

That last sentence is a **forward reference**: the "Reusing an existing topic folder" sub-section is created by Task 2, Step 3. Between this task's commit and Task 2's commit the skill cites a section that does not exist yet. That is accepted — the two tasks are adjacent and neither is a batch boundary — but do not "fix" it by deleting the sentence, and do not reorder the two tasks.

and replace the exit criterion line:

```markdown
- Design document exists at the required path (`docs/specs/`).
```

with:

```markdown
- Design document exists at the required path
  (`docs/superpowers-orchestrator/*/specs/`).
```

- [x] **Step 5: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 6: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): add the normative artifact layout section" --trailer "Session: artifact-layout" --trailer "Stage: task 1/22"
```

---

### Task 2: brainstorming reuses an existing topic folder instead of creating a second one

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** the check fires only when a folder whose basename matches `????-??-??-<slug>` already exists directly under `docs/superpowers-orchestrator/`. It does NOT fire for: a folder with the same slug under a different parent directory (that folder is invisible to every lookup in this layout and is left alone); a folder whose basename carries the slug but no date prefix (it is not a topic folder, so brainstorming creates the correctly named one beside it); a folder for a *different* slug that describes the same feature (no automatic detection — the user chooses the slug); and two folders that already exist for one slug (a pre-existing uniqueness violation — brainstorming reports both and asks the user to merge or rename before continuing, it never picks one).

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q '^### Reusing an existing topic folder$' skills/brainstorming/SKILL.md \
  && grep -q '????-??-??-<slug>' skills/brainstorming/SKILL.md \
  && grep -q 'design-<old date>-review-log\.md' skills/brainstorming/SKILL.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL` — the first and third needles do not match yet.
The second needle, `????-??-??-<slug>`, is already satisfied by the
slug-uniqueness bullet Task 1 inserted, so it does not discriminate here; the
verdict comes from the other two. It is kept so the gate still fails if a
later edit removes that glob from the skill.

The first needle is **anchored to the heading line** (`^### …$`) on purpose.
Task 1 Step 4 already writes the phrase "reusing an existing topic folder"
into the same file as inline prose. An unanchored, case-insensitive needle
would therefore match Task 1's sentence — today only because Task 1 happens to
wrap that sentence across two lines, which no rule requires — and would stop
discriminating the moment anyone reflows it. Only Step 3 writes the `###`
heading.

- [x] **Step 3: Append the sub-section to the Artifact Layout section**

Append at the end of the `## Artifact Layout` section added in Task 1, immediately before the `## Process Flow` heading:

````markdown
### Reusing an existing topic folder

Before step 11 writes the design, list the candidate folders:

```bash
find docs/superpowers-orchestrator -maxdepth 1 -type d \
     -name '????-??-??-<slug>' 2>/dev/null
```

`find` is used instead of `ls -d <glob>/` because an unmatched glob is not
portable: `bash` passes the pattern through to `ls`, but `zsh` — the login
shell on macOS, and the shell many agent sessions run commands under — treats
it as a shell-level error ("no matches found"), never runs `ls`, and writes
the message before the command's own `2>/dev/null` can suppress it. `find`
prints nothing and exits 0 when there is no match, in every shell.

- **Zero matches** (no output) — create
  `docs/superpowers-orchestrator/<today>-<slug>/specs/`
  and write the design there.
- **More than one match** — a slug-uniqueness violation that predates this
  run. Stop, list both folders, and ask the user to merge or rename them.
  Never pick one, never create a third.
- **Exactly one match** — ask the user **once**, in a single message:
  reuse that folder (the design is written into its `specs/`, overwriting an
  existing `specs/<slug>-design.md`) or choose a different slug. Never create
  a second folder for the same slug.

  The question must list the files already in that folder and state the
  consequences of reuse:

  - Existing `plans/`, `implementation/` and orchestration-log files are left
    untouched.
  - `orchestrating-development`'s Phase 0 precondition requires that the plan
    path and the orchestration-log path do NOT already exist — it will stop
    until the user deletes or renames them.
  - A later `multi-code-review` continues round numbering in the existing
    `implementation/<slug>-review-log.md`: a new invocation entry is appended
    to the same file.
  - The spec gate's review appends its rounds to the existing
    `specs/<slug>-design-review-log.md` — a log that then describes two
    documents. Offer to move that sidecar aside as
    `specs/<slug>-design-<old date>-review-log.md` before the gate, where
    `<old date>` is the topic folder's date prefix. The archived name must
    still end in `-review-log.md`: the blinding pathspec set uses
    `':(top,exclude,glob)**/*-review-log.md'`, and `multi-code-review`'s
    reviewer read prohibition names the same shape. A name such as
    `specs/<slug>-design-review-log.<old date>.md` ends in the date instead,
    so neither would cover it and a blinded reviewer could read the previous
    review log.
  - Commit that move immediately, as part of the same step: `git mv` the
    sidecar to the archived name, then commit both paths — for example
    `git commit -m "chore(docs): archive the previous <slug> design review
    log" -- <old path> <new path>`. A `git mv` of a tracked file that is left
    uncommitted appears in `git status --porcelain` as a staged rename (a
    third path), and `orchestrating-development`'s Phase 0 clean-tree check
    stops the run on any dirt it does not recognize. Without this commit the
    reuse flow does not reach Phase 1.
````

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): reuse an existing topic folder instead of creating a second" --trailer "Session: artifact-layout" --trailer "Stage: task 2/22"
```

---

### Task 3: writing-plans writes into the topic folder

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
OLD_PLANS=$(grep -c 'docs/plans/' skills/writing-plans/SKILL.md)
OLD_SPEC_HDR=$(grep -c '\*\*Spec:\*\* `docs/specs/' skills/writing-plans/SKILL.md)
NEW_PATHS=$(grep -cF 'docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md' skills/writing-plans/SKILL.md)
echo "old docs/plans/ occurrences: $OLD_PLANS"
echo "old Spec header:             $OLD_SPEC_HDR"
echo "new plan path occurrences:   $NEW_PATHS"
[ "$OLD_PLANS" = "0" ] && [ "$OLD_SPEC_HDR" = "0" ] && [ "$NEW_PATHS" = "5" ] \
  && echo PASS || echo FAIL
```

The three counts are printed for diagnosis, but the verdict is the `PASS`/`FAIL` line — the same form every other task uses. Comparing three numbers by eye is how an off-by-one (one table row left un-replaced) gets missed.

The path is spelled `<date>-<slug>`, the topic folder's **basename**, not
`<topic-folder>`: the derivation paragraph defines `<D>` (and therefore "the
topic folder") as the full path `docs/superpowers-orchestrator/<date>-<slug>`,
so `docs/superpowers-orchestrator/<topic-folder>/…` would read as that prefix
written twice. `<date>-<slug>` is also the spelling every other task in this
plan uses, including Task 21 Step 3, which rewrites `docs/guide/README.md` to
quote these same strings.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `old docs/plans/ occurrences: 6`, `old Spec header: 1`, `new plan path occurrences: 0`, then `FAIL`.

- [x] **Step 3: Replace the four path statements (Output Path, the plan-header Spec line, the slug rule, and the handoff paths)**

In `skills/writing-plans/SKILL.md`:

Replace the Output Path section body:

```markdown
Save to `docs/plans/YYYY-MM-DD-<feature-name>.md`.
- User preferences for plan location override this default.
```

with:

```markdown
Derive the **topic folder** from the spec path (the derivation rule and the
folder shape are defined in the "Artifact Layout" section of
`skills/brainstorming/SKILL.md`): the spec must be
`<D>/specs/<file>` where `<D>` is a direct child of
`docs/superpowers-orchestrator/` at the repository root and `<D>`'s basename
matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`. Then `<D>` is
the topic folder, its basename is `<date>-<slug>`, and `<slug>` is that
basename minus the date prefix.

Save to `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`,
creating `plans/` if it does not exist.

- User preferences for plan location override this default.
- A spec that is **outside the layout** is handled by "Spec Outside the
  Layout" below — do not write a plan next to it.
```

Replace the plan-header template's Spec line:

```markdown
**Spec:** `docs/specs/<the spec this plan implements>.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews)*
```

with:

```markdown
**Spec:** `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/specs/<slug>-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*
```

Replace the slug rule bullet:

```markdown
- **Slug** = the plan's file basename with the `YYYY-MM-DD-` date prefix and the `.md` extension stripped: `docs/plans/2026-08-17-auth-login.md` → `auth-login`. Every skill in the pipeline derives the slug with this same rule.
```

with:

```markdown
- **Slug** = the plan's file basename with the `YYYY-MM-DD-` date prefix and the `.md` extension stripped, each only if present. Every skill in the pipeline derives the slug with this same rule. Under the artifact layout the plan basename *is* the slug, so the rule yields it unchanged: `docs/superpowers-orchestrator/2026-08-17-auth-login/plans/auth-login.md` → `auth-login`.
```

Replace the three handoff prompt paths and the Ready Message path: in the Ready Message block and in the paste-prompt table, replace every occurrence of `docs/plans/<filename>.md` with `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`. Apply it to all four lines:

```markdown
Plan saved to `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`. Ready to execute with **[Subagent-Driven / Inline Execution]** (<N> tasks[, <one-word reason>]).
```

```markdown
| Subagent-Driven, batched | `Use subagents in batched autonomous mode on docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` | Never asks mid-batch; hands off at the context boundary |
| Subagent-Driven, interactive | `Use subagents to implement docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` | Per-task subagents; stops to ask on ambiguity or blockers |
| Inline | `Execute the plan at docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` | Continuous in-session execution with checkpoints |
```

The Ready Message's first line is already covered by the replacement given above; do not apply it twice.

Leave the "Seed `state.md`" bullet (`path to the plan file`) unchanged — it names no directory, so it is correct under both layouts.

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: `old docs/plans/ occurrences: 0`, `old Spec header: 0`, `new plan path occurrences: 5`, then `PASS`. The five are Output Path, the Ready Message, and the three paste-prompt table rows.

- [x] **Step 5: Confirm the routing keywords survived the rewrite**

Run:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -c 'Use subagents in batched autonomous mode on' skills/writing-plans/SKILL.md
grep -c 'Use subagents to implement' skills/writing-plans/SKILL.md
grep -c 'Execute the plan at' skills/writing-plans/SKILL.md
```

Expected: each prints `1`. These three phrases are tuned to the skill-activator's scoring; only the path inside them changed.

- [x] **Step 6: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): write plans into the topic folder" --trailer "Session: artifact-layout" --trailer "Stage: task 3/22"
```

---

### Task 4: writing-plans handles a spec outside the layout

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** the move offer applies only when the spec path fails the topic-folder derivation. It does NOT cover: a spec inside a correctly named topic folder but in the wrong stage sub-folder (for example `<topic>/plans/foo-design.md`) — that path fails derivation as a spec and gets the same offer, whose expected location names `specs/`, so the move is a real move and never a move onto itself; a spec already at the expected location (derivation succeeds, no offer); a spec whose sidecar exists but whose spec file does not (writing-plans stops earlier — the spec path must exist); and a project that is not a git repository, where the move uses plain `mv` and no history is preserved.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q '^## Spec Outside the Layout$' skills/writing-plans/SKILL.md \
  && grep -q 'mkdir -p' skills/writing-plans/SKILL.md \
  && grep -qi 'no plan is written' skills/writing-plans/SKILL.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL` — the section does not exist.

- [x] **Step 3: Add the section immediately after "Output Path"**

Insert in `skills/writing-plans/SKILL.md`, between the Output Path section and the Plan Header section:

````markdown
## Spec Outside the Layout

A spec whose path is not `<D>/specs/<file>` — where `<D>` is a direct child
of `docs/superpowers-orchestrator/` at the repository root whose basename
matches the topic-folder shape defined in the "Artifact Layout" section of
`skills/brainstorming/SKILL.md` — gets **no plan written beside it**. The
`specs/` segment is required: the general derivation rule in that section
also accepts `<D>/plans/<file>`, but a *spec* sitting in a `plans/` folder is
outside the layout and gets the offer below, exactly as this task's "Does NOT
cover" note states. The invariant this protects: every plan lives in a topic folder
together with its spec.

1. Compute `<slug>` = the spec basename with `YYYY-MM-DD-`, `-design` and
   `.md` stripped, each only if present.
2. Name the expected location:
   `docs/superpowers-orchestrator/<today>-<slug>/specs/<slug>-design.md`. If a
   folder matching `docs/superpowers-orchestrator/????-??-??-<slug>/` already
   exists, reuse that folder instead of `<today>` (slug uniqueness). More than
   one match → stop and report the ambiguity; write nothing.
3. State the reason the spec is outside the layout — wrong parent directory,
   or a folder name that does not match
   `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$` — next to the
   expected location, so a spec already in the right place but wrongly named
   is never described as a move onto itself.
4. Ask the user **once** whether to move the spec there.
   - **Yes:** `mkdir -p` the destination `specs/` folder first (`git mv` fails
     when the destination directory does not exist), then `git mv` the spec to
     `specs/<slug>-design.md` and — when it exists — its `-review-log.md`
     sidecar to `specs/<slug>-design-review-log.md`. Use plain `mv` when the
     project is not a git repository. The sidecar is renamed together with the
     spec because the sidecar rule derives the log name from the document
     name: a sidecar that kept its old basename would be orphaned and a later
     spec review would start a new log. Then continue with the moved spec.
   - **No:** stop. No plan is written.
````

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): refuse to plan next to a spec outside the layout" --trailer "Session: artifact-layout" --trailer "Stage: task 4/22"
```

---

### Task 5: multi-doc-review infers the document type from path segments

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Modify: `skills/multi-doc-review/reviewer-prompt.md`

**Security flag:** `none`

**Does NOT cover:** the segment rule decides on the directory segment nearest the file. It does NOT cover: a document directly at the topic-folder root (for example the orchestration log) — no `specs/` or `plans/` segment is nearest, so it infers `general`, which is correct; a document under a `specs/` or `plans/` directory that is not a topic folder at all — it still infers `spec`/`plan`, which is the intended tolerant behavior for user-preferred locations; and an explicit user statement, which continues to override inference.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'segment nearest' skills/multi-doc-review/SKILL.md \
  && grep -q 'docs/superpowers-orchestrator/\*/specs/' skills/multi-doc-review/reviewer-prompt.md \
  && ! grep -q 'docs/specs/' skills/multi-doc-review/SKILL.md \
  && ! grep -q 'docs/specs/' skills/multi-doc-review/reviewer-prompt.md \
  && echo PASS || echo FAIL
```

The needles are deliberately short. The full phrase "directory segment nearest
the file" is wrapped across two lines in the text Step 3 inserts, and `grep`
matches one line at a time — a needle spanning the break can never match. The
third condition greps for the bare string `docs/specs/` because that string
occurs exactly once in the file today (in the rule Step 3 replaces) and zero
times afterwards, which makes it a gate that actually changes state.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Replace the inference rule in `skills/multi-doc-review/SKILL.md`**

Replace:

```markdown
- **Doc type:** gate invocations pass it (brainstorming → `spec`,
  writing-plans → `plan`). Direct invocations infer from path: under
  `docs/specs/` → `spec`, under `docs/plans/` → `plan`, else `general`; an
  explicit user statement overrides.
```

with:

```markdown
- **Doc type:** gate invocations pass it (brainstorming → `spec`,
  writing-plans → `plan`). Direct invocations infer from the
  **repository-relative** path (so a clone that itself lives under a
  directory named `plans/` is not affected): the **directory segment nearest
  the file** decides — `specs/` → `spec`; `plans/` → `plan`; anything else →
  `general`. An explicit user statement overrides.
```

- [x] **Step 4: Update the reviewer isolation wording**

In `skills/multi-doc-review/reviewer-prompt.md`, replace:

```markdown
    - Do NOT read any other documents under `docs/specs/` or `docs/plans/`
      — [DOC_SCOPE_RULE].
```

with:

```markdown
    - Do NOT read any other documents under
      `docs/superpowers-orchestrator/*/specs/` or
      `docs/superpowers-orchestrator/*/plans/` — [DOC_SCOPE_RULE].
```

- [x] **Step 5: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 6: Commit**

```bash
git add skills/multi-doc-review/SKILL.md skills/multi-doc-review/reviewer-prompt.md
git commit -m "docs(multi-doc-review): infer doc type from the nearest path segment" --trailer "Session: artifact-layout" --trailer "Stage: task 5/22"
```

---

### Task 6: skill-activator intent pattern for the new spec path

**Files:**
- Modify: `hooks/skill-rules.json`
- Test: `tests/codex/test-skill-activator.js`

**Security flag:** `none`

- [x] **Step 1: Write failing tests**

In `tests/codex/test-skill-activator.js`, replace the test at the `orchestrating-development routing` section:

```javascript
test('"orchestrate the development of <spec>" ranks orchestrating-development first', () => {
  assert.strictEqual(
    topSkill('orchestrate the development of docs/specs/2026-08-04-foo-design.md'), ORCH);
});
```

with:

```javascript
test('"orchestrate the development of <spec>" ranks orchestrating-development first', () => {
  assert.strictEqual(
    topSkill('orchestrate the development of docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design.md'),
    ORCH);
});

// The path-shaped intent pattern is asserted directly: the verb-phrase
// pattern above it already matches "orchestrate the development", so a
// topSkill() assertion alone cannot tell whether the path pattern changed.
test('the orchestrating-development path pattern matches a new-layout spec path', () => {
  // hooks/skill-rules.json's top-level key is `rules`, an array of entries.
  const entry = require('../../hooks/skill-rules.json')
    .rules.find(s => s.skill === ORCH);
  const pathPattern = entry.intentPatterns.find(p => p.includes('specs'));
  assert.ok(
    new RegExp(pathPattern, 'i').test(
      'orchestrate the development of docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design.md'),
    `path pattern ${pathPattern} should match a new-layout spec path`);
});

test('the orchestrating-development path pattern no longer matches an old-layout spec path', () => {
  // hooks/skill-rules.json's top-level key is `rules`, an array of entries.
  const entry = require('../../hooks/skill-rules.json')
    .rules.find(s => s.skill === ORCH);
  const pathPattern = entry.intentPatterns.find(p => p.includes('specs'));
  assert.ok(
    !new RegExp(pathPattern, 'i').test(
      'orchestrate the development of docs/specs/2026-08-04-foo-design.md'),
    `path pattern ${pathPattern} should not match an old-layout spec path`);
});
```

Also replace the two resume/abandon prompts in the same section:

```javascript
test('"Resume orchestration for <plan>" routes to orchestrating-development, not SDD', () => {
  assert.strictEqual(
    topSkill('Resume orchestration for docs/superpowers-orchestrator/2026-08-04-foo/plans/foo.md'),
    ORCH);
});

test('"Abandon orchestration for <plan>" routes to orchestrating-development', () => {
  assert.strictEqual(
    topSkill('Abandon orchestration for docs/superpowers-orchestrator/2026-08-04-foo/plans/foo.md'),
    ORCH);
});
```

Finally, move the remaining old-layout plan paths in the same file to the new
layout. These seven prompts route to `subagent-driven-development` or
`executing-plans`; no intent pattern for those two skills contains a path, so
the assertions keep passing either way. They are changed so that no test
fixture in the repository still names the old layout — Task 17 Step 5 and
Task 20 Step 1 both grep for exactly that:

| Line | Old path in the prompt string | New path |
|---|---|---|
| 1165 | `docs/plans/2026-08-02-foo.md` | `docs/superpowers-orchestrator/2026-08-02-foo/plans/foo.md` |
| 1170 | `docs/plans/2026-08-02-foo.md` | `docs/superpowers-orchestrator/2026-08-02-foo/plans/foo.md` |
| 1176 | `docs/plans/foo.md` | `docs/superpowers-orchestrator/2026-08-02-foo/plans/foo.md` |
| 1184 | `docs/plans/2026-08-02-foo.md` | `docs/superpowers-orchestrator/2026-08-02-foo/plans/foo.md` |
| 1204 | `docs/plans/2026-08-02-foo.md` | `docs/superpowers-orchestrator/2026-08-02-foo/plans/foo.md` |
| 1210 | `docs/plans/2026-08-02-foo.md` | `docs/superpowers-orchestrator/2026-08-02-foo/plans/foo.md` |
| 1252 | `docs/plans/2026-08-04-foo.md` | `docs/superpowers-orchestrator/2026-08-04-foo/plans/foo.md` |

Line numbers are the pre-edit ones and shift as the tests above are replaced;
match on the prompt string, not on the line number.

- [x] **Step 2: Run the tests to verify they fail**

Run: `node tests/codex/test-skill-activator.js`
Expected: FAIL — "path pattern ... should match a new-layout spec path" (the current pattern requires `docs/specs/` immediately).

- [x] **Step 3: Change the intent pattern**

In `hooks/skill-rules.json`, replace:

```json
        "orchestrate\\b[\\s\\S]{0,80}?docs[\\/]specs[\\/]",
```

with:

```json
        "orchestrate\\b[\\s\\S]{0,80}?docs[\\/]superpowers-orchestrator[\\/][^\\s]+[\\/]specs[\\/]",
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `node tests/codex/test-skill-activator.js`
Expected: PASS — all tests, including the two new pattern assertions.

- [x] **Step 5: Run the full hook unit suite**

Run: `bash tests/codex/run-unit-tests.sh`
Expected: PASS — no regression in the other hook tests.

- [x] **Step 6: Commit**

```bash
git add hooks/skill-rules.json tests/codex/test-skill-activator.js
git commit -m "fix(hooks): match the new-layout spec path in the orchestration intent pattern" --trailer "Session: artifact-layout" --trailer "Stage: task 6/22"
```

---

### Task 7: stop-reminders significance fixtures for the new layout

**Files:**
- Test: `tests/codex/test-stop-reminders.js`

**Security flag:** `none`

**Does NOT cover:** `hooks/stop-reminders.js` itself is unchanged. Its `specs/`/`plans/` regexes already match any parent folder, so a new-layout path is significant without a code change. This task only proves it, and proves that `implementation/` is NOT significant — an `implementation/` edit must not mark a session as decision-worthy, per the spec's non-goals.

- [x] **Step 1: Add the classification fixtures**

There is no red state to produce here, by design: `hooks/stop-reminders.js` is
unchanged (see "Does NOT cover"), so these fixtures pass as soon as they are
written. The two positive tests below are the control for the negative one —
they prove that a `writeRecentEdit` fixture does reach the hook, so a passing
`implementation/` assertion means "matched nothing", not "never ran".

In `tests/codex/test-stop-reminders.js`, replace the two existing layout tests:

```javascript
test('Detects specs/*.md edits (new pattern)', () => {
  const { homeDir, cwdDir, logDir } = makeTempDirs();
  try {
    writeRecentEdit(logDir, 'docs/specs/test-spec.md');
```

and

```javascript
test('Detects plans/*.md edits (new pattern)', () => {
  const { homeDir, cwdDir, logDir } = makeTempDirs();
  try {
    writeRecentEdit(logDir, 'docs/plans/test-plan.md');
```

so that their `writeRecentEdit` fixtures use the artifact layout:

```javascript
    writeRecentEdit(logDir, 'docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design.md');
```

```javascript
    writeRecentEdit(logDir, 'docs/superpowers-orchestrator/2026-08-25-foo/plans/foo.md');
```

Then add a third test immediately after them:

```javascript
test('Does NOT treat implementation/*.md edits as significant', () => {
  const { homeDir, cwdDir, logDir } = makeTempDirs();
  try {
    writeRecentEdit(logDir, 'docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-review-log.md');
    const { evaluatePayload } = loadHookWithHome(homeDir);
    const result = evaluatePayload({ cwd: cwdDir, session_id: TEST_SESSION_ID });
    const reason = result.reason || '';
    assert.ok(!reason.includes('Decision log'),
      `implementation/*.md edit must not trigger the decision log: ${reason}`);
  } finally {
    cleanup(homeDir, cwdDir);
  }
});
```

- [x] **Step 2: Run the tests**

Run: `node tests/codex/test-stop-reminders.js`
Expected: PASS for all three. If the `implementation/` test fails, `hooks/stop-reminders.js` matched a path it must not — stop and report; do not widen the test.

- [x] **Step 3: Run the full hook unit suite**

Run: `bash tests/codex/run-unit-tests.sh`
Expected: PASS

- [x] **Step 4: Commit**

```bash
git add tests/codex/test-stop-reminders.js
git commit -m "test(hooks): classify new-layout artifact paths in stop-reminders" --trailer "Session: artifact-layout" --trailer "Stage: task 7/22"
```

---

### Task 8: review-package excludes review material from every whole-branch diff

**Files:**
- Modify: `skills/subagent-driven-development/scripts/review-package`
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** in `--commits` mode the explicit commit list (`git log -1 --oneline "$c"`) is NOT filtered — the caller names those commits itself and they are task commits, never `chore(review)` commits; only the stat and diff output is filtered there. The exclusions also do NOT hide a review log stored anywhere else under a different name; only the five documented name shapes and the `implementation/` folder are excluded.

- [x] **Step 1: Write failing tests**

Append to `tests/sdd-scripts/run-tests.sh`, immediately before the final `bold ""` / `Results:` block:

```bash
bold "review-package (reviewer blinding)"

# A commit that carries both an ordinary source change and committed review
# material: the package must show the source hunk and hide the review files.
mkdir -p docs/superpowers-orchestrator/2026-08-25-foo/implementation
mkdir -p docs/superpowers-orchestrator/2026-08-25-foo/specs
echo "base for blinding" > blind-base.txt
git add blind-base.txt && git commit --quiet -m "base commit for blinding"
BLIND_BASE=$(git rev-parse HEAD)

echo "SECRETFINDING round 1 verdict" > docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-review-log.md
echo "SECRETFIXREPORT ran the tests" > docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-fix-reports.md
echo "SECRETSIDECAR spec round 1" > docs/superpowers-orchestrator/2026-08-25-foo/specs/foo-design-review-log.md
echo "SECRETORCH phase 1 done" > docs/superpowers-orchestrator/2026-08-25-foo/foo-orchestration-log.md
echo "SECRETDECISIONS open item" > docs/superpowers-orchestrator/2026-08-25-foo/plans-open.tmp
mkdir -p docs/superpowers-orchestrator/2026-08-25-foo/plans
mv docs/superpowers-orchestrator/2026-08-25-foo/plans-open.tmp docs/superpowers-orchestrator/2026-08-25-foo/plans/foo-open-decisions.md
echo "VISIBLESOURCE" > blind-src.txt
git add -A && git commit --quiet -m "feature plus review material"
BLIND_HEAD=$(git rev-parse HEAD)

BPKG=$("$SCRIPTS/review-package" "$BLIND_BASE" "$BLIND_HEAD" 2>/dev/null | sed 's/^wrote //; s/:.*$//')
assert_file_contains "blinding: ordinary source change is visible" "$BPKG" "VISIBLESOURCE"
assert_file_not_contains "blinding: implementation review log hidden" "$BPKG" "SECRETFINDING"
assert_file_not_contains "blinding: implementation fix reports hidden" "$BPKG" "SECRETFIXREPORT"
assert_file_not_contains "blinding: spec review-log sidecar hidden" "$BPKG" "SECRETSIDECAR"
assert_file_not_contains "blinding: orchestration log hidden" "$BPKG" "SECRETORCH"
assert_file_not_contains "blinding: open-decisions file hidden" "$BPKG" "SECRETDECISIONS"
# The five assertions above key on file CONTENT, which only the `git diff -U10`
# body can carry. The `## Files changed` section is a `git diff --stat`, which
# prints file NAMES and counts and no content at all, so a package whose
# `--stat` is un-blinded passes every one of them while still listing
# `…/implementation/foo-review-log.md` to the reviewer. This assertion keys on
# the path, so it is the only one that reaches the `--stat` edit in Step 3.
assert_file_not_contains "blinding: review file names absent from the stat summary" "$BPKG" "implementation/foo-review-log.md"

# A commit that touches ONLY review material must not appear in the commit
# list at all — a visible "chore(review)" subject with no hunks tells a
# reviewer that review rounds happened.
echo "SECRETFINDING round 2 verdict" >> docs/superpowers-orchestrator/2026-08-25-foo/implementation/foo-review-log.md
git add -A && git commit --quiet -m "chore(review): foo round 2 log"
BLIND_HEAD2=$(git rev-parse HEAD)
BPKG2=$("$SCRIPTS/review-package" "$BLIND_BASE" "$BLIND_HEAD2" 2>/dev/null | sed 's/^wrote //; s/:.*$//')
assert_file_not_contains "blinding: review-only commit absent from the commit list" "$BPKG2" "chore(review)"

# --commits mode must be blinded too. The spec requires blinding in BOTH
# modes, and the wave-execution path uses this one. Same commit, addressed by
# SHA instead of by range.
# Write it into $WS (the `.superpowers/sdd/` workspace, which carries a
# self-ignoring `.gitignore`), NOT into the repository root: a stray untracked
# file at the root would make Task 12's `git status --porcelain` assertion
# report dirty. The variable name avoids `CPKG`, already bound at line ~179.
BLIND_CPKG="$WS/blind-from-commits.diff"
"$SCRIPTS/review-package" --commits "$BLIND_HEAD" --out "$BLIND_CPKG" >/dev/null 2>&1
assert_file_contains "blinding (--commits): ordinary source change is visible" "$BLIND_CPKG" "VISIBLESOURCE"
assert_file_not_contains "blinding (--commits): implementation review log hidden" "$BLIND_CPKG" "SECRETFINDING"
# Same reasoning for `git show --stat` in --commits mode.
assert_file_not_contains "blinding (--commits): review file names absent from the stat summary" "$BLIND_CPKG" "implementation/foo-review-log.md"

# Run from a subdirectory and assert on the package CONTENT, not on the exit
# status: `review-package` exits 0 from anywhere, with or without the
# pathspecs, so an exit-status check would pass for every implementation. The
# content check is the real discriminator — with a relative scope such as
# `-- .` the diff would be restricted to `subdir-for-anchor/` and VISIBLESOURCE
# would be missing; ':(top)' anchors every pathspec at the repository root.
mkdir -p subdir-for-anchor
BLIND_SUBPKG="$WS/blind-from-subdir.diff"
( cd subdir-for-anchor && "$SCRIPTS/review-package" "$BLIND_BASE" "$BLIND_HEAD" "$BLIND_SUBPKG" >/dev/null 2>&1 )
assert_file_contains "blinding: source visible when the package is built from a subdirectory" "$BLIND_SUBPKG" "VISIBLESOURCE"
assert_file_not_contains "blinding: review log hidden when built from a subdirectory" "$BLIND_SUBPKG" "SECRETFINDING"

# `subdir-for-anchor` is an empty directory; git stores no empty directories,
# so it leaves no untracked entry behind for Task 12's clean-tree assertion.
```

- [x] **Step 2: Run the tests to verify they fail**

Run: `bash tests/sdd-scripts/run-tests.sh`
Expected: FAIL — ten assertions, because `review-package` currently diffs everything: the five `SECRET*` `assert_file_not_contains` checks on `$BPKG`, `blinding: review-only commit absent from the commit list` (a `git log --oneline` without pathspecs still lists the `chore(review)` commit), `blinding (--commits): implementation review log hidden`, `blinding: review log hidden when built from a subdirectory`, and the two `review file names absent from the stat summary` checks (one on `$BPKG`, one on `$BLIND_CPKG`).

The two `assert_file_contains` checks for `VISIBLESOURCE` pass both before and after Step 3 — they are regression guards that catch a fix which blinds the package by shrinking the diff instead of by excluding review material.

- [x] **Step 3: Add the pathspec set to `review-package`**

In `skills/subagent-driven-development/scripts/review-package`, insert immediately after the `script_dir=` line:

```bash
# Reviewer blinding: committed review material is part of the branch but must
# never reach a reviewer. ':(top)' anchors every pathspec at the repository
# root so the package is identical no matter which directory the caller runs
# from — a plain '-- .' would be relative to the cwd and silently shrink the
# diff. Keep this list in step with multi-code-review/SKILL.md.
blind_pathspecs=(
  ':(top)'
  ':(top,exclude)docs/superpowers-orchestrator/*/implementation/'
  ':(top,exclude,glob)**/*-review-log.md'
  ':(top,exclude,glob)**/*-fix-reports.md'
  ':(top,exclude,glob)**/*-orchestration-log.md'
  ':(top,exclude,glob)**/*-open-decisions.md'
)
```

In the `--commits` branch, replace:

```bash
      git show --stat --format="%h %s" "$c"
```

with:

```bash
      git show --stat --format="%h %s" "$c" -- "${blind_pathspecs[@]}"
```

and replace:

```bash
      git show -U10 --format="### commit %h %s" "$c"
```

with:

```bash
      git show -U10 --format="### commit %h %s" "$c" -- "${blind_pathspecs[@]}"
```

In the range branch, replace the three git commands:

```bash
  git log --oneline "${base}..${head}"
```

with:

```bash
  git log --oneline "${base}..${head}" -- "${blind_pathspecs[@]}"
```

```bash
  git diff --stat "${base}..${head}"
```

with:

```bash
  git diff --stat "${base}..${head}" -- "${blind_pathspecs[@]}"
```

```bash
  git diff -U10 "${base}..${head}"
```

with:

```bash
  git diff -U10 "${base}..${head}" -- "${blind_pathspecs[@]}"
```

- [x] **Step 4: Run the tests to verify they pass**

Run: `bash tests/sdd-scripts/run-tests.sh`
Expected: PASS — every assertion. That includes the pre-existing `range: alpha hunk present` and `--commits mode` assertions (which predate blinding and say nothing about it) *and* the three new `--commits` blinding assertions added in Step 1, which are what actually verify the two `git show` edits in Step 3. The two `review file names absent from the stat summary` assertions are the only ones that verify the two `git diff --stat` / `git show --stat` edits: every other blinding assertion keys on file content, which a `--stat` summary never prints.

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/scripts/review-package tests/sdd-scripts/run-tests.sh
git commit -m "fix(sdd): blind review packages to committed review material" --trailer "Session: artifact-layout" --trailer "Stage: task 8/22"
```

---

### Task 9: multi-code-review accepts and validates TOPIC_DIR

**Files:**
- Modify: `skills/multi-code-review/SKILL.md`

**Security flag:** `security` *(the validation decides where the skill writes and commits; a `TOPIC_DIR` outside the repository root would make the skill write and commit outside the tree under review)*

**Does NOT cover:** validation rejects a `TOPIC_DIR` that is not a direct child of `docs/superpowers-orchestrator/` at the repository root, or whose basename fails the date-slug regex. It does NOT cover: a valid `TOPIC_DIR` naming a topic that no other stage ever wrote into (the folder is created — the gate may legitimately run first); a `TOPIC_DIR` naming a *different* topic than the plan being reviewed (no cross-check — the caller owns that pairing); and direct `/multi-code-review` invocations, which never receive `TOPIC_DIR` and keep today's behavior unchanged.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'TOPIC_DIR' skills/multi-code-review/SKILL.md \
  && grep -q 'git check-ignore -q' skills/multi-code-review/SKILL.md \
  && grep -q 'pipeline mode' skills/multi-code-review/SKILL.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Add the parameter to the Parameters section**

Append to the Parameters list in `skills/multi-code-review/SKILL.md`, after the "Plan/requirements path" bullet:

````markdown
- **`TOPIC_DIR` (optional):** an absolute path to a topic folder under the
  repository root (layout defined in the "Artifact Layout" section of
  `skills/brainstorming/SKILL.md`). Two invocation forms:
  `/multi-code-review [BASE] [N]` — direct, no `TOPIC_DIR`; and the pipeline
  gate call — with `TOPIC_DIR`. Presence of `TOPIC_DIR` selects
  **pipeline mode**; absence selects **direct mode**.

  **Validation, before round 1:**
  1. `TOPIC_DIR` must be a direct child of `docs/superpowers-orchestrator/`
     at the repository root, and its basename must match
     `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`. Canonicalize both
     the repository root and `TOPIC_DIR` before comparing (`pwd -P`, or
     `realpath` where available). Anything else — a path outside the root,
     `docs/reviews/foo/`, a folder without a date prefix — **stops the skill
     with an error naming the path, before any round**. Without this stop the
     precondition pathspec and the diff exclusion, both written for the layout
     form, would silently miss the folder.
  2. `<slug>` = `TOPIC_DIR`'s basename minus the date prefix. `<topic>` =
     `TOPIC_DIR` with `<repo root>/` stripped — pathspecs carrying `:(top)`
     are repository-relative.
  3. A valid `TOPIC_DIR` that does not exist yet is **created**; the caller
     may invoke the gate before any other stage wrote into the folder. No
     `.gitignore` is written inside it.
  4. `git check-ignore -q <log path>` must **fail** (that is: the log path
     must not be ignored). A project `.gitignore` matching `implementation/`
     or `*-review-log.md` would otherwise surface only as a failed commit
     after a full round. If it succeeds, stop and report the ignoring rule.
  5. If the log or the fix-report file differs from HEAD — a previous round's
     `chore(review)` commit failed or was interrupted — retry that pending
     commit **first**, with the same subject rule. On repeated failure return
     `BLOCKED` with the git output and name the manual commit the user must
     run:
     `git add -- <paths> && git commit -m "chore(review): <slug> round <i> log" -- <paths>`.
     Without this retry an on-disk entry carrying a completion marker would
     read as completed, the once-per-gate skip would fire, and the
     orchestrator's Phase 5 clean-tree check would stop the run with no path
     to recovery.
````

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 5: Commit**

```bash
git add skills/multi-code-review/SKILL.md
git commit -m "docs(multi-code-review): add the TOPIC_DIR input and its validation" --trailer "Session: artifact-layout" --trailer "Stage: task 9/22"
```

---

### Task 10: multi-code-review pipeline mode — paths and the four rule changes

**Files:**
- Modify: `skills/multi-code-review/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** pipeline mode changes only the four rules stated below. It does NOT change: lens rotation, convergence, the verification re-review cycle cap, the reviewer or fix-subagent model rules, or the fix subagent's own commit subject. It does NOT cover a run that switches mode mid-loop (a resumed invocation always re-derives its mode from whether `TOPIC_DIR` was passed), and it does NOT cover a direct run finding a pipeline-mode log — the two modes write to different paths and never meet.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'effective HEAD' skills/multi-code-review/SKILL.md \
  && grep -q 'chore(review): <slug> round <i> log' skills/multi-code-review/SKILL.md \
  && grep -q "':(top,exclude)docs/superpowers-orchestrator/<topic>/implementation/'" skills/multi-code-review/SKILL.md \
  && grep -q 'Tracked-log sentinel' skills/multi-code-review/SKILL.md \
  && grep -q 'in \*\*direct mode\*\*,' skills/multi-code-review/SKILL.md \
  && grep -q '"Current HEAD" is mode-dependent' skills/multi-code-review/SKILL.md \
  && grep -qF '<TOPIC_DIR>/implementation/<slug>-review-log.md' skills/multi-code-review/SKILL.md \
  && grep -qF 'Pipeline rule 1 — Log commits' skills/multi-code-review/SKILL.md \
  && echo PASS || echo FAIL
```

The fifth needle (`in **direct mode**,`) gates Step 7's **second** edit — the "After the Loop" paragraph. Without it the task passes with that paragraph still stating the raw-HEAD rule unconditionally, which contradicts pipeline rule 4.

The sixth needle (`"Current HEAD" is mode-dependent`) gates Step 7's **third** edit — the `**Once per gate:**` paragraph, which has the same defect: unqualified it demands both the raw `git rev-parse HEAD` and an untracked log, so in pipeline mode (where the log is tracked by design, and where the raw HEAD at marker time is the round's own log commit) the skip could never fire. The two needles do not overlap: the second edit writes `in **direct mode**,` with a comma, the third writes `in **direct mode** it is the raw`.

The seventh needle gates **Step 3** and the eighth gates **Step 4**. Without
them the gate prints `PASS` with the two most important edits of this task
never applied: Step 3 is where pipeline mode's log path is defined, and Step 4
is the log-commit rule. Neither writes any of the first six needles, and the
second needle is already satisfied before this task runs (see below), so
nothing else in the gate reads them.

The second needle, `chore(review): <slug> round <i> log`, is already satisfied
by the pending-commit recovery text that Task 9 Step 3 inserted, so it does not
discriminate here; the verdict comes from the other seven needles. It is kept so
the gate still fails if a later edit removes that commit subject from the skill.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Replace the Sidecar log paragraph in "Workspace and Log"**

Replace:

```markdown
Sidecar log: `<repo-root>/.superpowers/reviews/<branch-slug>-review-log.md`;
fix reports beside it as `<branch-slug>-fix-reports.md`. On first use create
`.superpowers/reviews/` and write a `.gitignore` containing exactly `*`
inside it (nothing else ignores `.superpowers/`).
```

with:

```markdown
Sidecar log and fix reports, by mode:

- **Direct mode** (no `TOPIC_DIR`):
  `<repo-root>/.superpowers/reviews/<branch-slug>-review-log.md`; fix reports
  beside it as `<branch-slug>-fix-reports.md`. On first use create
  `.superpowers/reviews/` and write a `.gitignore` containing exactly `*`
  inside it (nothing else ignores `.superpowers/`). Nothing is committed.
- **Pipeline mode** (`TOPIC_DIR` given):
  `<TOPIC_DIR>/implementation/<slug>-review-log.md`; fix reports beside it as
  `<TOPIC_DIR>/implementation/<slug>-fix-reports.md`, with `<slug>` derived
  from `TOPIC_DIR`'s basename. The folder is created on first write and gets
  **no** `.gitignore` — the log is tracked by design. Pipeline mode changes
  exactly four rules of this skill; each is stated next to the direct-mode
  rule it replaces.
```

- [x] **Step 4: Add rule 1 (log commits) after the Sidecar paragraph**

Insert:

````markdown
**Pipeline rule 1 — Log commits.** After every round, and after that round's
fix commits:

```bash
git add -- <log> [<fix reports>]
git commit -m "chore(review): <slug> round <i> log" -- <log> [<fix reports>]
```

The fix-report file is included only once it exists — a fix subagent has to
have written to it first. The `git add` is required because
`git commit -- <path>` fails on a file git does not know yet; the
path-limited commit keeps the user's other staged files staged and out of
this commit. The fix subagent **never stages the fix-report file**, even
though it appends to it: the rule below that has it stage "the files it
changed" excludes the fix-report file, because the controller's round commit
owns both files. The completion marker and any post-loop addendum are
committed the same way, with subject
`chore(review): <slug> completed`. Each round, and the loop itself, ends with
a tree that is clean except for changes that already existed when the loop
started — those are never swept into a `chore(review)` commit.

**When the commit fails** — a pre-commit hook rejects it, a signing prompt
gets no answer, or the index conflicts — stop the loop after that round and
report the git output. Do **not** retry inside the run and do **not** start
the next round: the log and the fix reports stay on disk, uncommitted, and
the next invocation retries the pending commit before round 1 (see the
`TOPIC_DIR` validation, step 5). Starting another round would append a second
round's text to a log whose previous round was never committed, and the
retry could then no longer tell the two apart.
````

- [x] **Step 5: Add rule 2 (working-tree precondition) to the precondition paragraph**

Replace:

```markdown
**Working-tree precondition:** before any fix subagent is dispatched
(first round included), check `git status --porcelain` at the repo root.
If it is non-empty, stop and report — or, in interactive sessions only,
proceed after the user explicitly consents to fixing on top of the
pre-existing uncommitted changes.
```

with:

````markdown
**Working-tree precondition:** before any fix subagent is dispatched
(first round included), check `git status --porcelain` at the repo root.
If it is non-empty, stop and report — or, in interactive sessions only,
proceed after the user explicitly consents to fixing on top of the
pre-existing uncommitted changes.

**Pipeline rule 2 — Working-tree precondition.** In pipeline mode the check
excludes the topic's implementation folder:

```bash
git status --porcelain -- ':(top)' ':(top,exclude)docs/superpowers-orchestrator/<topic>/implementation/'
```

Without the exclusion the untracked log (round 1) or the modified log and fix
reports (later rounds) would fail the check on every round.
````

- [x] **Step 6: Add rule 3 (tracked-log sentinel) to the In-progress sentinel paragraph**

Append immediately after the existing "In-progress sentinel" paragraph:

```markdown
**Pipeline rule 3 — Tracked-log sentinel.** The rule above — "a log tracked
in the branch is set aside as abandoned" — applies to **direct mode only**.
In pipeline mode the log is tracked by design, so resumption uses the entry
rules alone: an invocation entry with no completion marker whose invoker kind
and BASE match is resumed at its next round; a mismatched entry is marked
`abandoned` and a new invocation entry is appended to the **same file**. The
file is never moved aside — its history is committed.
```

- [x] **Step 7: Add rule 4 (effective HEAD) to "After the Loop" and "Once per gate"**

Insert immediately before the `**Once per gate:**` paragraph:

````markdown
**Pipeline rule 4 — Completion marker and once-per-gate skip.** Define the
**effective HEAD** as the newest commit in `BASE..HEAD` whose subject does not
start with `chore(review):`:

```bash
effective_head=""
while read -r sha subject; do
  case "$subject" in
    'chore(review):'*) continue ;;
    *) effective_head="$sha"; break ;;
  esac
done < <(git log --format='%H %s' "$BASE..HEAD")
[ -n "$effective_head" ] || effective_head="$BASE"
```

When every commit in the range is a `chore(review):` commit — N=0, or a
branch that received only review commits — the effective HEAD is BASE.

In pipeline mode the completion marker records the **effective HEAD**, never
the raw `git rev-parse HEAD`, which at marker time is always the last round's
log commit. The post-loop addendum updates the marker under the same
definition. The once-per-gate skip and the orchestrator's retry protection
compare the recorded HEAD with the **current effective HEAD**. Direct mode
keeps the raw `git rev-parse HEAD` in both places, unchanged. The skip's
"log not tracked" condition applies to **direct mode only**.
````

Then qualify the "After the Loop" paragraph itself. It is the paragraph a
controller reads when it writes the marker, and left as it is it states the
raw-HEAD rule unconditionally — contradicting rule 4 above it. In
`skills/multi-code-review/SKILL.md`, replace:

```markdown
Append the completion marker `_Completed — <date> — <converged|cap
reached> — HEAD <sha>_` with `<sha>` = `git rev-parse HEAD` **now**
(post-fix).
```

with:

```markdown
Append the completion marker `_Completed — <date> — <converged|cap
reached> — HEAD <sha>_` with `<sha>` = in **direct mode**,
`git rev-parse HEAD` **now** (post-fix); in **pipeline mode**, the
effective HEAD as defined in "Pipeline rule 4" below, beside "Once per
gate" — the raw HEAD at marker time is the round's own log commit, which
would never match on a later comparison.
```

Then qualify the `**Once per gate:**` paragraph itself, for the same reason.
Unqualified it demands the raw `git rev-parse HEAD` **and** an untracked log,
and pipeline mode satisfies neither: its log is tracked by design (Step 3), and
its raw HEAD at marker time is the round's own log commit. Left as it stands
the skip can never fire in pipeline mode. In
`skills/multi-code-review/SKILL.md`, replace:

```markdown
**Once per gate:** the SDD gate skips the loop only when this log holds a
`gate: sdd` invocation entry whose completion-marker HEAD equals the
current `git rev-parse HEAD` AND whose recorded raw branch name matches
the current branch — and only when the log itself is not tracked in the
branch under review (same `git ls-files --error-unmatch <log path>` check
as the sentinel): a tracked log can never satisfy this skip either. A
`skipped` (N=0) entry **counts as completed** for this check — skip when
its recorded HEAD equals the current HEAD and the branch matches — and is
never a resumable/in-progress entry for the sentinel.
```

with:

```markdown
**Once per gate:** the SDD gate skips the loop only when this log holds a
`gate: sdd` invocation entry whose completion-marker HEAD equals the
current HEAD AND whose recorded raw branch name matches the current
branch. "Current HEAD" is mode-dependent: in **direct mode** it is the raw
`git rev-parse HEAD`, and the skip additionally requires that the log
itself is not tracked in the branch under review (same
`git ls-files --error-unmatch <log path>` check as the sentinel) — in
direct mode a tracked log can never satisfy this skip. In **pipeline
mode** it is the **effective HEAD** defined in "Pipeline rule 4" above,
and there is **no** tracked-log condition: in that mode the log is tracked
by design. A `skipped` (N=0) entry **counts as completed** for this check
— skip when its recorded HEAD equals the current HEAD under the same
mode-dependent definition and the branch matches — and is never a
resumable/in-progress entry for the sentinel.
```

- [x] **Step 8: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 9: Commit**

```bash
git add skills/multi-code-review/SKILL.md
git commit -m "docs(multi-code-review): define pipeline mode and its four rule changes" --trailer "Session: artifact-layout" --trailer "Stage: task 10/22"
```

---

### Task 11: reviewer blinding — diff exclusion and read prohibition

**Files:**
- Modify: `skills/multi-code-review/SKILL.md`
- Modify: `skills/multi-code-review/reviewer-prompt.md`

**Security flag:** `security` *(the change controls what review material a reviewer subagent can read; a gap here leaks prior rounds' findings into later rounds and destroys the independence the loop is built on)*

**Does NOT cover:** the exclusion covers the five documented name shapes and the `implementation/` folder. It does NOT cover: review material a user stored under some other name; the *task-level* reviewer in `subagent-driven-development` reading files outside the diff on its own initiative (the read prohibition covers that, the pathspecs cannot); and fix subagents, which keep receiving findings through their brief and never through the log — unchanged.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
NEEDLE="':(top,exclude,glob)**/*-orchestration-log.md'"
SKILL_COUNT=$(grep -cF -- "$NEEDLE" skills/multi-code-review/SKILL.md)
REVIEWER_COUNT=$(grep -cF -- "$NEEDLE" skills/multi-code-review/reviewer-prompt.md)
READ_BAN_COUNT=$(grep -cF 'docs/superpowers-orchestrator/*/implementation/' skills/multi-code-review/reviewer-prompt.md)
FALLBACK_COUNT=$(grep -cF 'each carrying the pathspec set from' skills/multi-code-review/SKILL.md)
echo "skill:    $SKILL_COUNT"
echo "reviewer: $REVIEWER_COUNT"
echo "read ban: $READ_BAN_COUNT"
echo "fallback: $FALLBACK_COUNT"
[ "$SKILL_COUNT" = "1" ] && [ "$REVIEWER_COUNT" = "1" ] && [ "$READ_BAN_COUNT" = "2" ] \
  && [ "$FALLBACK_COUNT" = "1" ] \
  && echo PASS || echo FAIL
```

The four counts are printed for diagnosis, but the verdict is the `PASS`/`FAIL`
line — the same form every other task uses. Step 2 expects `FAIL` and Step 7
expects `PASS`; without a verdict line neither expectation is checkable, and
comparing four numbers by eye is how a wrong count gets missed.

`fallback` gates **Step 6**. Step 6 adds none of the other three strings, so
without this count the gate reports `PASS` with the Error Handling bullet still
restating the un-blinded fallback commands — the exact leak Step 6 closes.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: all four counts print `0`, then the verdict line prints `FAIL`.

- [x] **Step 3: Add the blinding pathspecs to the skill's diff commands**

In `skills/multi-code-review/SKILL.md`, insert a new sub-section immediately after the "Root anchoring" paragraph:

````markdown
**Reviewer blinding — pathspecs.** Committed review material is part of the
branch. Every whole-branch diff handed to a reviewer — in this skill, in
`subagent-driven-development/scripts/review-package`, in the orchestrator's
`code-review-loop-prompt.md`, and in the reviewer's own fallback commands —
is produced with this pathspec set, verbatim:

```
-- ':(top)' ':(top,exclude)docs/superpowers-orchestrator/*/implementation/' ':(top,exclude,glob)**/*-review-log.md' ':(top,exclude,glob)**/*-fix-reports.md' ':(top,exclude,glob)**/*-orchestration-log.md' ':(top,exclude,glob)**/*-open-decisions.md'
```

The last two matter on a resumed run: after a Phase 4 stop the orchestrator
commits the orchestration log and the open-decisions file, both of which quote
prior findings. The `top` magic anchors every pathspec at the repository root,
which makes the commands independent of the current directory — a plain `-- .`
is relative to the cwd, and the sdd per-task caller of `review-package` may run
from any directory, where `-- .` would silently restrict the diff to that
subtree and the exclusions would never match. This skill already anchors its
commands at the repository root ("Root anchoring" above); `:(top)` is harmless
there and keeps one form everywhere. The exclusion also closes the
pre-existing leak of the committed doc-review sidecars.
````

- [x] **Step 4: Extend the reviewer's read prohibition**

In `skills/multi-code-review/reviewer-prompt.md`, replace:

```markdown
    - Do NOT read any file whose name matches `*-review-log.md` or
      `*-fix-reports.md`. This rule takes precedence over the
```

with:

```markdown
    - Do NOT read any file whose name matches `*-review-log.md`,
      `*-fix-reports.md`, `*-orchestration-log.md` or
      `*-open-decisions.md`, and do NOT read anything under
      `docs/superpowers-orchestrator/*/implementation/`. This rule takes
      precedence over the
```

- [x] **Step 5: Blind the reviewer's fallback diff commands**

In `skills/multi-code-review/reviewer-prompt.md`, replace:

```markdown
    `git diff --stat [BASE_SHA]..[HEAD_SHA]` and
    `git diff [BASE_SHA]..[HEAD_SHA]` — a failure fallback, not an
    alternative workflow.
```

with:

````markdown
    `git diff --stat [BASE_SHA]..[HEAD_SHA] -- ':(top)' ':(top,exclude)docs/superpowers-orchestrator/*/implementation/' ':(top,exclude,glob)**/*-review-log.md' ':(top,exclude,glob)**/*-fix-reports.md' ':(top,exclude,glob)**/*-orchestration-log.md' ':(top,exclude,glob)**/*-open-decisions.md'`
    and the same command without `--stat` — a failure fallback, not an
    alternative workflow. Keep the pathspecs: they exclude review material
    you must not read.
````

- [x] **Step 6: Correct the Error Handling bullet that describes that fallback**

`skills/multi-code-review/SKILL.md` restates the reviewer template's fallback
commands in its Error Handling list. Step 5 has just changed those commands, so
the restatement is now wrong — and a controller reading only the skill would
hand a reviewer an un-blinded fallback, which is exactly the leak this task
closes. Replace:

```markdown
- `review-package` missing or failing → dispatch with `[PACKAGE_FILE]` =
  `none — fetch the diff yourself via the git commands below` (the
  template's sanctioned no-package form; its Diff Under Review fallback
  has the reviewer run `git diff --stat BASE..HEAD` and
  `git diff BASE..HEAD` itself) and log the fallback.
```

with:

```markdown
- `review-package` missing or failing → dispatch with `[PACKAGE_FILE]` =
  `none — fetch the diff yourself via the git commands below` (the
  template's sanctioned no-package form; its Diff Under Review fallback
  has the reviewer run `git diff --stat BASE..HEAD` and
  `git diff BASE..HEAD` itself, each carrying the pathspec set from
  "Reviewer blinding — pathspecs" above) and log the fallback.
```

- [x] **Step 7: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: `skill: 1`, `reviewer: 1`, `read ban: 2`, `fallback: 1`, then the
verdict line prints `PASS`.

`read ban` is `2`, not `1`: the string `docs/superpowers-orchestrator/*/implementation/`
appears on two separate lines of `reviewer-prompt.md` after this task — once in
the read prohibition (Step 4) and once inside the blinded fallback command
(Step 5). `grep -c` counts matching lines.

- [x] **Step 8: Commit**

```bash
git add skills/multi-code-review/SKILL.md skills/multi-code-review/reviewer-prompt.md
git commit -m "fix(multi-code-review): blind reviewers to committed review material" --trailer "Session: artifact-layout" --trailer "Stage: task 11/22"
```

---

### Task 12: script-level tests for the pipeline-mode git rules

**Files:**
- Test: `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

- [x] **Step 1: Write the git-contract tests**

These assertions have **no red state**, by design — the step is deliberately
not called "write failing tests". They pin down behavior of `git` itself (a
path-limited commit, pathspec exclusion in `git status`, the effective-HEAD
walk, `git log --grep`) plus `sdd-workspace`'s existing archive-slug rule, and
this plan changes none of that. They pass before and after; what they protect
is the git contract the skill text now depends on. Step 2 therefore expects
`PASS`, not `FAIL`.

Append to `tests/sdd-scripts/run-tests.sh`, after the blinding section added in Task 8 and before the final `Results:` block:

```bash
bold "pipeline-mode git rules (multi-code-review)"

PTOPIC="docs/superpowers-orchestrator/2026-08-25-bar"
PLOG="$PTOPIC/implementation/bar-review-log.md"
mkdir -p "$PTOPIC/implementation"
echo "unrelated source" > unrelated.txt
git add unrelated.txt && git commit --quiet -m "base for pipeline rules"

# Rule 1: `git add` + a path-limited commit commits an untracked log while
# leaving an unrelated staged file staged.
echo "round 1 verdict" > "$PLOG"
echo "staged by the user" > user-staged.txt
git add user-staged.txt
git add -- "$PLOG"
git commit --quiet -m "chore(review): bar round 1 log" -- "$PLOG"
assert_eq "rule 1: log is committed" "$(git log -1 --format=%s)" "chore(review): bar round 1 log"
assert_eq "rule 1: the user's staged file is still staged" "$(git diff --cached --name-only)" "user-staged.txt"

# Rule 2: the precondition pathspec reports clean with only the log modified,
# and dirty with a source file modified.
git commit --quiet -m "keep the user file out of the way" -- user-staged.txt
echo "round 2 verdict" >> "$PLOG"
PRECOND=$(git status --porcelain -- ':(top)' ":(top,exclude)$PTOPIC/implementation/")
assert_eq "rule 2: modified implementation log reads clean" "$PRECOND" ""
echo "changed" >> unrelated.txt
PRECOND2=$(git status --porcelain -- ':(top)' ":(top,exclude)$PTOPIC/implementation/")
if [ -n "$PRECOND2" ]; then ok "rule 2: modified source file reads dirty"; else bad "rule 2: modified source file reads dirty"; fi
git checkout --quiet -- unrelated.txt
git add -- "$PLOG" && git commit --quiet -m "chore(review): bar round 2 log" -- "$PLOG"

# Rule 4: the effective-HEAD walk skips leading chore(review) commits and
# stops at the first other commit.
#
# The walk is used twice below, with two different range bases. Define it once
# as a function rather than pasting the loop twice: two byte-identical copies
# of a logic block are exactly what the review rubric treats as a defect, and
# the repository's DRY rule forbids them. The function is NOT required to be
# byte-identical to the version `multi-code-review/SKILL.md` documents — this
# test asserts the walk's behavior, not the skill's wording.
effective_head_of() {
  local base="$1" sha subject effective_head=""
  while read -r sha subject; do
    case "$subject" in
      'chore(review):'*) continue ;;
      *) effective_head="$sha"; break ;;
    esac
  done < <(git log --format='%H %s' "$base..HEAD")
  [ -n "$effective_head" ] || effective_head="$base"
  printf '%s\n' "$effective_head"
}

PBASE=$(git rev-parse HEAD~3)
echo "real work" > real-work.txt
git add real-work.txt && git commit --quiet -m "feat: real work"
REAL_WORK_SHA=$(git rev-parse HEAD)
echo "round 3 verdict" >> "$PLOG"
git add -- "$PLOG" && git commit --quiet -m "chore(review): bar round 3 log" -- "$PLOG"

assert_eq "rule 4: effective HEAD skips the trailing review commit" \
  "$(effective_head_of "$PBASE")" "$REAL_WORK_SHA"

# Rule 4, degenerate case: a range holding only chore(review) commits falls
# back to BASE.
ONLY_BASE=$(git rev-parse HEAD~1)
assert_eq "rule 4: review-only range falls back to BASE" \
  "$(effective_head_of "$ONLY_BASE")" "$ONLY_BASE"

bold "recovery greps stay intact"

# The batch controller finds task ticks with `git log --grep "task <n> complete"`
# and fix commits with the `review fixes (<slug>, round <i>)` subject. A
# pipeline-mode log commit must match neither.
#
# Both greps run against commits that REALLY EXIST in this throwaway
# repository: the three `chore(review): bar round <i> log` commits created
# above, plus one genuine tick commit and one genuine fix commit created here.
# Each grep therefore has a match it must find AND log commits it must not
# find, so a pipeline-mode subject that started colliding with either recovery
# pattern would fail this gate. (Matching a shell variable against a literal
# with `case` could never fail — both sides are written in this same file.)
echo "tick" > tick.txt
git add tick.txt && git commit --quiet -m "chore(plan): bar task 1 complete"
TICK_SHA=$(git rev-parse --short HEAD)
echo "fix" > fix.txt
git add fix.txt && git commit --quiet -m "review fixes (bar, round 1)"
FIX_SHA=$(git rev-parse --short HEAD)

# Control: each recovery grep finds its own commit. Without this the two
# "matches no review-log commit" assertions below would also pass if the grep
# matched nothing at all.
assert_eq "recovery grep: 'task 1 complete' finds exactly the tick commit" \
  "$(git log --grep 'task 1 complete' --format=%h | tr '\n' ' ' | sed 's/ *$//')" "$TICK_SHA"
assert_eq "recovery grep: 'review fixes (' finds exactly the fix commit" \
  "$(git log --grep 'review fixes (' --format=%h | tr '\n' ' ' | sed 's/ *$//')" "$FIX_SHA"

# The real assertions: neither recovery pattern matches a pipeline-mode
# `chore(review)` log commit.
assert_eq "recovery grep: 'task 1 complete' matches no review-log commit" \
  "$(git log --grep 'task 1 complete' --format=%s | grep -c 'chore(review)' | tr -d ' ')" "0"
assert_eq "recovery grep: 'review fixes (' matches no review-log commit" \
  "$(git log --grep 'review fixes (' --format=%s | grep -c 'chore(review)' | tr -d ' ')" "0"

bold "archive naming with a dateless plan basename"

# `sdd-workspace` names the archive folder from the OUTGOING plan's basename
# minus its extension (script line ~112, `slug=$(basename -- "$current")`).
# Archiving fires only when the plan identity changes, so the check switches
# from one plan to another. Under the new layout the plan basename carries no
# date prefix (`plans/<slug>.md` instead of `plans/<date>-<slug>.md`), so the
# archive folder is named `<slug>`. The rule is unchanged; this asserts the
# result, which the spec's testing strategy requires.
mkdir -p docs/superpowers-orchestrator/2026-08-25-baz/plans
mkdir -p docs/superpowers-orchestrator/2026-08-25-qux/plans
echo "# plan" > docs/superpowers-orchestrator/2026-08-25-baz/plans/baz.md
echo "# plan" > docs/superpowers-orchestrator/2026-08-25-qux/plans/qux.md
"$SCRIPTS/sdd-workspace" docs/superpowers-orchestrator/2026-08-25-baz/plans/baz.md > /dev/null
echo "leftover" > "$WS/task-1-notes.md"
"$SCRIPTS/sdd-workspace" docs/superpowers-orchestrator/2026-08-25-qux/plans/qux.md > /dev/null
if [ -d "$WS/archive/baz" ]; then
  ok "archive naming: dateless plan basename yields archive/baz"
else
  bad "archive naming: expected $WS/archive/baz, found: $(ls "$WS/archive" 2>/dev/null | tr '\n' ' ')"
fi
```

`$SCRIPTS` and `$WS` are the variables the existing tests in this file already
use for the scripts directory and the workspace directory; reuse them rather
than recomputing the paths.

- [x] **Step 2: Run the tests**

Run: `bash tests/sdd-scripts/run-tests.sh`
Expected: PASS — all new assertions plus every pre-existing one. These assertions test git's own behavior, which the skill text now depends on; a failure means the documented git contract does not hold on this git version. Report the git version (`git --version`) with any failure instead of adjusting the assertions.

- [x] **Step 3: Commit**

```bash
git add tests/sdd-scripts/run-tests.sh
git commit -m "test(sdd): verify the pipeline-mode git rules on a throwaway repository" --trailer "Session: artifact-layout" --trailer "Stage: task 12/22"
```

---

### Task 13: subagent-driven-development derives the topic folder and passes TOPIC_DIR

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** the gate passes `TOPIC_DIR` only when the plan path recorded in `.superpowers/sdd/plan.ref` derives a topic folder. It does NOT cover: a plan at a user-preferred path outside the layout (the final review then runs in direct mode, and the completion message says so); a `plan.ref` that is missing or empty (an existing `sdd-workspace` condition, unchanged); and the archive folder naming or the commit-message slug, both of which keep today's rule and yield the same result under the new layout.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'TOPIC_DIR' skills/subagent-driven-development/SKILL.md \
  && grep -q 'plan.ref' skills/subagent-driven-development/SKILL.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL` — `TOPIC_DIR` does not appear.

- [x] **Step 3: Extend the final-review gate**

In `skills/subagent-driven-development/SKILL.md`, replace the first sentence of step 4:

```markdown
4. Run the final whole-branch review loop: invoke the `multi-code-review`
   skill with BASE = the branch's merge-base (`git merge-base main HEAD`
   or the BASE recorded before Task 1), the plan path, and the ledger's
   carried Minor-findings list.
```

with:

```markdown
4. Run the final whole-branch review loop: invoke the `multi-code-review`
   skill with BASE = the branch's merge-base (`git merge-base main HEAD`
   or the BASE recorded before Task 1), the plan path, the ledger's
   carried Minor-findings list, and — when one exists — `TOPIC_DIR`.
   Derive `TOPIC_DIR` from the plan path recorded in
   `.superpowers/sdd/plan.ref` using the derivation rule in the "Artifact
   Layout" section of `skills/brainstorming/SKILL.md`: the plan must be
   `<D>/plans/<file>` with `<D>` a direct child of
   `docs/superpowers-orchestrator/` at the repository root whose basename
   matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*$`; then
   `TOPIC_DIR` is `<D>`, as an absolute path, and the review log and fix
   reports are committed under `<D>/implementation/`. A plan **outside the
   layout** derives no topic folder: pass no `TOPIC_DIR`, so the review runs
   in direct mode under `.superpowers/reviews/`, and say so in the
   completion message.
```

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "docs(sdd): pass TOPIC_DIR to the final whole-branch review gate" --trailer "Session: artifact-layout" --trailer "Stage: task 13/22"
```

---

### Task 14: orchestrating-development uses the topic folder everywhere

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** the intake rule stops the run when the spec derives no topic folder. It does NOT cover: moving the spec — the orchestrator never moves files and never asks a question after Phase 0, so the user does the move; a spec inside a valid topic folder whose `specs/` sub-folder holds several designs (the first matching path given by the user is used — no disambiguation); and `docs/research/` handling and every `state.md` rule, which are unchanged.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
! grep -q 'docs/plans/' skills/orchestrating-development/SKILL.md \
  && ! grep -q 'docs/specs/' skills/orchestrating-development/SKILL.md \
  && grep -q 'ambiguous slug' skills/orchestrating-development/SKILL.md \
  && grep -q -- '--untracked-files=all' skills/orchestrating-development/SKILL.md \
  && echo PASS || echo FAIL
```

The first two conditions require the literal strings `docs/plans/` and `docs/specs/` to be **absent** from the file after Steps 3–8. That holds only because no replacement text in this task writes either string: Step 3's prose says "an old flat-directory spec path included" instead of naming the old path. Keep it that way — a new sentence that names `docs/specs/` literally would make Step 9 unreachable.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Add the intake rule to Phase 0 step 4**

In `skills/orchestrating-development/SKILL.md`, replace the opening of step 4:

```markdown
4. **Preconditions:** git repo; spec file exists; the computed plan path
   and log path (step 7) do not already exist; `git status --porcelain`
   empty EXCEPT the spec and its `<spec-basename>-review-log.md` sidecar
   (brainstorming leaves them uncommitted). Any other dirt → stop and
   report; never stash or commit the user's unrelated changes.
```

with:

```markdown
4. **Preconditions:** git repo; spec file exists; **the spec path derives a
   topic folder** (rule in the "Artifact Layout" section of
   `skills/brainstorming/SKILL.md`) — a spec outside the layout, an old
   flat-directory spec path included, is a pre-log stop: report the expected
   location `docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md`
   and tell the user to `git mv` the spec and, when it exists, its
   `-review-log.md` sidecar there, naming both destination paths
   (`specs/<slug>-design.md` and `specs/<slug>-design-review-log.md`). The
   orchestrator never moves files itself and never asks a question after
   Phase 0. Then: the computed plan path and log path (step 7) do not already
   exist; `git status --porcelain --untracked-files=all` empty EXCEPT the spec
   and its `-review-log.md` sidecar under the topic folder's `specs/`
   (brainstorming leaves them uncommitted). `--untracked-files=all` is
   required: after brainstorming the topic folder is a **new untracked
   directory**, and plain `git status --porcelain` collapses it to one line
   (`?? docs/superpowers-orchestrator/<date>-<slug>/`), so neither file path
   would appear. Any other dirt → stop and report; never stash or commit the
   user's unrelated changes.
```

- [x] **Step 4: Update the slug derivation and the prior-run glob in step 5**

Replace:

```markdown
5. **Branch:** create and switch to `feature/<slug>` from current HEAD.
   `<slug>` = spec basename with `YYYY-MM-DD-` prefix and `-design` suffix
   each stripped only if present. If the branch exists: locate the
   existing orchestration log for that slug with the glob
   `docs/plans/*-<slug>-orchestration-log.md` (its date prefix is the
   PRIOR run's start date — never assume today's) and compare its
   recorded spec path with the invoked spec — same spec → report "prior run", suggest the resume
   prompt; different/missing → report "unrelated prior run with the same
   slug", tell the user to rename the spec or clear the old branch. Stop
   either way.
```

with:

```markdown
5. **Branch:** create and switch to `feature/<slug>` from current HEAD.
   `<slug>` = the **topic folder's** basename minus its `YYYY-MM-DD-` prefix
   — never derived from the spec basename. If the branch exists: locate the
   existing orchestration log with the glob
   `docs/superpowers-orchestrator/????-??-??-<slug>/<slug>-orchestration-log.md`.
   Zero matches → no prior run. Exactly one match → compare its recorded spec
   path with the invoked spec: same spec → report "prior run", suggest the
   resume prompt; different/missing → report "unrelated prior run with the
   same slug", tell the user to rename the spec or clear the old branch. More
   than one match → stop with "ambiguous slug: <folders>" (slug uniqueness is
   violated; the user must merge or rename before any run). Stop in every case
   except zero matches.
```

- [x] **Step 5: Update the log, plan and open-decisions paths**

Replace:

```markdown
7. **Log:** create `docs/plans/YYYY-MM-DD-<slug>-orchestration-log.md`
   (start date) with the invocation header (format below), recording
   BASE = `git rev-parse HEAD`. Commit it
   (`chore(orchestration): <slug> log started`).
```

with:

```markdown
7. **Log:** create `<topic folder>/<slug>-orchestration-log.md` — at the topic
   root, **no date prefix**; each invocation entry inside carries its own
   date — with the invocation header (format below), recording BASE =
   `git rev-parse HEAD`. The header records the spec path and the plan path in
   their new form. Commit it (`chore(orchestration): <slug> log started`).
```

Replace the Phase 1 sentence:

```markdown
Fill `./plan-writer-prompt.md` (spec path; output plan path
`docs/plans/YYYY-MM-DD-<slug>.md`, same date and slug as the log) and
dispatch.
```

with:

```markdown
Fill `./plan-writer-prompt.md` (spec path; output plan path
`<topic folder>/plans/<slug>.md`) and dispatch.
```

Add to the Phase 4 description of the code-review loop, immediately before the Phase 5 heading:

```markdown
The filled `code-review-loop-prompt.md` passes `TOPIC_DIR` = the topic folder
(absolute path) to the controller, which passes it on to `multi-code-review`.
The controller's write scope therefore adds `<topic folder>/implementation/`.
The open-decisions file is `<topic folder>/plans/<slug>-open-decisions.md`.
```

- [x] **Step 6: Update Phase 5 step 3, the log format block and the state.md block**

Replace in Phase 5 step 3:

```markdown
   (orchestration, plan review, `.superpowers/reviews/` code review).
```

with:

```markdown
   (orchestration, plan review, and the code review log at
   `<topic folder>/implementation/<slug>-review-log.md`).
```

In the Orchestration Log Format block replace:

```
_Invocation 1 — YYYY-MM-DD — spec docs/specs/<spec>.md — N_plan=<n> N_code=<n> cap=<n> — branch feature/<slug> — BASE <sha7>_
```

with:

```
_Invocation 1 — YYYY-MM-DD — spec docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md — N_plan=<n> N_code=<n> cap=<n> — branch feature/<slug> — BASE <sha7>_
```

and replace:

```
plan: docs/plans/<plan>.md — <T> tasks
```

with:

```
plan: docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md — <T> tasks
```

and replace the stop block's Resume line:

```
Resume: Resume orchestration for docs/plans/<plan>.md
```

with:

```
Resume: Resume orchestration for docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md
```

In the state.md Section block replace:

```
Spec: docs/specs/<spec>.md  Plan: docs/plans/<plan>.md
```

with:

```
Spec: <topic folder>/specs/<slug>-design.md  Plan: <topic folder>/plans/<slug>.md
```

- [x] **Step 7: Update the Resume procedure**

Replace resume step 0:

```markdown
0. Derive `feature/<slug>` from the named path; verify the branch exists
   (else stop — nothing to resume) and check it out; re-ensure the exclude
   entries (Phase 0 step 3) FIRST, then require `git status --porcelain`
   empty (else stop).
```

with:

````markdown
0. Derive the **topic folder** from the named path (same rule as Phase 0),
   then `feature/<slug>` from the topic folder's basename minus its date
   prefix; verify the branch exists (else stop — nothing to resume) and check
   it out; re-ensure the exclude entries (Phase 0 step 3) FIRST, then require
   the clean-tree check to pass:

   ```bash
   git status --porcelain -- ':(top)' ':(top,exclude)docs/superpowers-orchestrator/<topic>/implementation/'
   ```

   must be empty (else stop). The exclusion mirrors multi-code-review's
   pipeline-mode precondition: an interruption between a round's first log
   write and its `chore(review)` commit — a controller that died, a commit
   that failed — leaves `implementation/` modified or untracked. Without the
   exclusion, resume would stop with "dirty tree" before the review loop's own
   resume rule could run. The resumed loop's next `chore(review)` commit picks
   those files up.
````

Replace in resume step 1:

```markdown
1. Read the orchestration log — locate it with
   `docs/plans/*-<slug>-orchestration-log.md` (its date prefix is the
   run's start date, not today's) —
```

with:

```markdown
1. Read the orchestration log — locate it with
   `docs/superpowers-orchestrator/????-??-??-<slug>/<slug>-orchestration-log.md`;
   more than one match is an "ambiguous slug" stop —
```

- [x] **Step 8: Update the skill description's trigger phrase**

In the YAML front matter, replace `"orchestrate docs/specs/..."` with `"orchestrate docs/superpowers-orchestrator/<topic>/specs/..."`.

- [x] **Step 9: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 10: Commit**

```bash
git add skills/orchestrating-development/SKILL.md
git commit -m "docs(orchestration): derive and use the topic folder at intake and resume" --trailer "Session: artifact-layout" --trailer "Stage: task 14/22"
```

---

### Task 15: orchestrator controller prompts carry the new paths and TOPIC_DIR

**Files:**
- Modify: `skills/orchestrating-development/plan-writer-prompt.md`
- Modify: `skills/orchestrating-development/code-review-loop-prompt.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'TOPIC_DIR' skills/orchestrating-development/code-review-loop-prompt.md \
  && grep -q 'implementation/' skills/orchestrating-development/code-review-loop-prompt.md \
  && grep -q '\*-fix-reports.md' skills/orchestrating-development/code-review-loop-prompt.md \
  && grep -q 'Reviewer blinding' skills/orchestrating-development/code-review-loop-prompt.md \
  && ! grep -q 'docs/plans/YYYY-MM-DD-<slug>.md' skills/orchestrating-development/plan-writer-prompt.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Update the plan-writer prompt's output path**

In `skills/orchestrating-development/plan-writer-prompt.md`, replace:

```markdown
- `[PLAN_PATH]` — REQUIRED: absolute output path
  `docs/plans/YYYY-MM-DD-<slug>.md` computed by the orchestrator
```

with:

```markdown
- `[PLAN_PATH]` — REQUIRED: absolute output path
  `<topic folder>/plans/<slug>.md` computed by the orchestrator, where
  `<topic folder>` is `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/`
```

- [x] **Step 4: Add TOPIC_DIR to the code-review-loop prompt**

In `skills/orchestrating-development/code-review-loop-prompt.md`, replace the write-scope line:

```markdown
    - You MAY dispatch reviewer and fix subagents via the Agent tool,
      commit fixes, and write under `.superpowers/reviews/`.
```

with:

```markdown
    - You MAY dispatch reviewer and fix subagents via the Agent tool,
      commit fixes, and write under `.superpowers/reviews/` and
      `[TOPIC_DIR]/implementation/`.
```

The topic folder is **added** to the write scope, not substituted for
`.superpowers/reviews/` — that is the spec's wording (section 5.4: "The
controller's write scope adds `<topic folder>/implementation/`"). Pipeline
mode writes the log under `implementation/` and never touches
`.superpowers/reviews/`, so the extra entry is inert in the normal case; it
matters when `multi-code-review` ends up in direct mode anyway (a
`TOPIC_DIR` the controller could not fill), where a narrowed scope would
forbid the controller's own log directory.

Add a parameter line to the Procedure block, after the `Plan/requirements path` line:

```markdown
    - TOPIC_DIR: [TOPIC_DIR]   (absolute path of the topic folder; the
      review log and fix reports are written and committed under its
      `implementation/` sub-folder — pipeline mode)
```

Add the placeholder to the Placeholders list, after `[PLAN_PATH]`:

```markdown
- `[TOPIC_DIR]` — REQUIRED: absolute path of the topic folder
  `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/` at the repository root
```

- [x] **Step 5: Extend the triage rule's artifact list**

Replace:

```markdown
    3. Triage rule: any reviewer finding whose subject file is an
       orchestration artifact — `*-orchestration-log.md`, the plan file's
       checkbox ticks, or a `*-review-log.md` sidecar — whether the
```

with:

```markdown
    3. Triage rule: any reviewer finding whose subject file is an
       orchestration artifact — `*-orchestration-log.md`, the plan file's
       checkbox ticks, a `*-review-log.md` sidecar, a `*-fix-reports.md`
       file, a `*-open-decisions.md` file, or anything under
       `docs/superpowers-orchestrator/*/implementation/` — whether the
```

- [x] **Step 6: Bind the controller to the blinding pathspecs**

The controller runs `multi-code-review`'s procedure, which already carries the
pathspecs, but the spec names this template as one of the places the rule must
appear. Add a fourth deviation to the "Deviations (binding)" list:

```markdown
    4. Reviewer blinding: every whole-branch diff command you or a
       subagent runs — including any fallback when the review package is
       missing — carries the pathspec set stated in
       [MULTI_CODE_REVIEW_SKILL_PATH] under "Reviewer blinding —
       pathspecs". Never hand a reviewer a diff produced without them:
       the branch under review now contains its own review log.
```

- [x] **Step 7: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 8: Commit**

```bash
git add skills/orchestrating-development/plan-writer-prompt.md skills/orchestrating-development/code-review-loop-prompt.md
git commit -m "docs(orchestration): pass TOPIC_DIR and the new plan path to the controllers" --trailer "Session: artifact-layout" --trailer "Stage: task 15/22"
```

---

### Task 16: context-management finds plans in the new layout

**Files:**
- Modify: `skills/context-management/SKILL.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'docs/superpowers-orchestrator/\*/plans/\*.md' skills/context-management/SKILL.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Update the two plan-lookup lines**

In `skills/context-management/SKILL.md`, replace:

```markdown
   - `plan.md` (or `docs/.../plans/*.md`): the authoritative task list with checkboxes. Owned by `executing-plans`. Updated as tasks complete.
```

with:

```markdown
   - `plan.md` (or `docs/superpowers-orchestrator/*/plans/*.md`): the authoritative task list with checkboxes. Owned by `executing-plans`. Updated as tasks complete.
```

and replace:

```markdown
   If a plan exists, state.md should say "Executing plan at docs/.../plan.md, currently on Task 3" — not copy the full task list.
```

with:

```markdown
   If a plan exists, state.md should say "Executing plan at docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md, currently on Task 3" — not copy the full task list.
```

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 5: Commit**

```bash
git add skills/context-management/SKILL.md
git commit -m "docs(context-management): look for plans in the topic folder" --trailer "Session: artifact-layout" --trailer "Stage: task 16/22"
```

---

### Task 17: behavioral and routing test fixtures move to the new layout

**Files:**
- Modify: `tests/claude-code/test-multi-doc-review.sh`
- Modify: `tests/claude-code/test-multi-code-review.sh`
- Modify: `tests/claude-code/test-helpers.sh`
- Modify: `tests/claude-code/test-subagent-driven-development-integration.sh`
- Modify: `tests/explicit-skill-requests/run-test.sh`, `run-haiku-test.sh`, `run-multiturn-test.sh`, `run-extended-multiturn-test.sh`, `run-claude-describes-sdd.sh`
- Modify: `tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt`, `skip-formalities.txt`, `mid-conversation-execute-plan.txt`, `claude-suggested-it.txt`, `after-planning-flow.txt`, `action-oriented.txt`
- Modify: `tests/skill-triggering/prompts/subagent-driven-development.txt`, `tests/skill-triggering/prompts/executing-plans.txt`
- Modify: `tools/autoimprove/test-cases.json`

**Security flag:** `none`

**Does NOT cover:** the researching-prior-art behavioral tests keep their `docs/research/` allow-list unchanged — that cache does not move. Comment lines naming the spec a test implements are updated in Task 20 together with the other links, not here. `tests/claude-code/test-batched-autonomous-mode.sh` needs no change: it holds no spec or plan path fixture — it asks the model about the skill file's Resume Procedure — which was confirmed with `grep -n 'docs/plans\|docs/specs' tests/claude-code/test-batched-autonomous-mode.sh` returning nothing.

- [x] **Step 1: Update the multi-doc-review fixture to the new layout**

In `tests/claude-code/test-multi-doc-review.sh`, replace:

```bash
mkdir -p "$TEST_PROJECT/docs/specs"
SPEC="$TEST_PROJECT/docs/specs/test-feature-design.md"
```

with:

```bash
TOPIC_DIR="$TEST_PROJECT/docs/superpowers-orchestrator/2026-08-25-test-feature"
mkdir -p "$TOPIC_DIR/specs"
SPEC="$TOPIC_DIR/specs/test-feature-design.md"
```

replace:

```bash
LOG="$TEST_PROJECT/docs/specs/test-feature-design-review-log.md"
```

with:

```bash
LOG="$TOPIC_DIR/specs/test-feature-design-review-log.md"
```

and replace the inference comment:

```bash
# test to exercise path-based inference (docs/specs/ -> spec); stating the type
```

with:

```bash
# test to exercise path-segment inference (nearest segment specs/ -> spec); stating the type
```

- [x] **Step 2: Add the TOPIC_DIR case to the multi-code-review behavioral test**

In `tests/claude-code/test-multi-code-review.sh`, insert a second case between the existing direct-mode assertion block (the `if [ -z "$LOG" ] …` block, closed by the `fi` at line 141) and the file's final `if [ "$FAILURES" -eq 0 ]` summary block (line 143). Do **not** append at the end of the file: the summary block prints the verdict and calls `exit`, so every `FAILURES=$((FAILURES+1))` placed after it would have no effect and all five Case-2 assertions would pass vacuously.

```bash
# ── Case 2: pipeline mode (TOPIC_DIR) ────────────────────────────────────────
# The log and fix reports are committed under <topic>/implementation/, one
# chore(review) commit per round, and the review package the log names must
# not contain the log's own text (reviewer blinding).

git checkout --quiet -b feature-pipeline-review "$BASE_SHA"
cat > sum.js << 'DEFECT2_EOF'
function sumFirstN(arr, n) {
  // BUG (planted, blatant): off-by-one reads past n and past the array end
  let total = 0;
  for (let i = 0; i <= n; i++) total += arr[i];
  return total;
}
module.exports = { sumFirstN };
DEFECT2_EOF
git add sum.js
git commit --quiet -m "feature: extend sumFirstN (pipeline case)"

TOPIC_DIR="$TEST_PROJECT/docs/superpowers-orchestrator/2026-08-25-sum-fix"
PIPE_PROMPT="Invoke the superpowers-orchestrator:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-pipeline-review) with BASE $BASE_SHA, N=2, and TOPIC_DIR $TOPIC_DIR. Do not ask me any questions — use N=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."

# Snapshot the review-package count BEFORE this case runs. Case 1 already
# wrote at least one package into the same project, so an absolute
# "at least one package exists" control could never fail; only an increase
# proves that this case's own loop built packages. The threshold is an
# increase of at least TWO, one per round of this N=2 case — see the
# (p5-control) comment below for why one is not enough.
# `|| true` is required: the script runs under `set -euo pipefail` (line 18),
# and when the glob matches nothing `ls` exits 2, `pipefail` propagates that
# through `wc`/`tr`, and `set -e` would abort the whole script instead of
# letting the control report. Same idiom as line 99 of this file.
PKG_COUNT_BEFORE=$(ls "$TEST_PROJECT"/.superpowers/sdd/review-*.diff 2>/dev/null | wc -l | tr -d ' ' || true)

cd "$PLUGIN_DIR" && timeout 1800 claude -p "$PIPE_PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output-pipeline.txt" || true

cd "$TEST_PROJECT"
PIPE_LOG="$TOPIC_DIR/implementation/sum-fix-review-log.md"

if [ ! -f "$PIPE_LOG" ]; then
    echo "FAIL(p1): no $PIPE_LOG created in pipeline mode"
    FAILURES=$((FAILURES+1))
else
    # (p2) the log is committed, not left untracked
    if ! git ls-files --error-unmatch "$PIPE_LOG" > /dev/null 2>&1; then
        echo "FAIL(p2): the pipeline-mode review log is not tracked in the branch"
        FAILURES=$((FAILURES+1))
    fi
    # (p3) one chore(review) commit per round
    REVIEW_COMMITS=$(git log --format=%s "$BASE_SHA"..HEAD | grep -c '^chore(review): ' || true)
    if [ "$REVIEW_COMMITS" -lt 2 ]; then
        echo "FAIL(p3): expected at least 2 chore(review) commits, found $REVIEW_COMMITS"
        FAILURES=$((FAILURES+1))
    fi
    # (p4) the working tree is clean at the end.
    # The test project is a bare `mktemp -d` + `git init` with no .gitignore,
    # and both cases write their `claude -p` transcript into it
    # (`output.txt`, `output-pipeline.txt`). Those transcripts are test
    # scaffolding, not a product of the loop, so exclude them — otherwise this
    # assertion fails on every run whatever the skill does.
    DIRT=$(git status --porcelain -- ':(top)' ':(top,exclude,glob)output*.txt')
    if [ -n "$DIRT" ]; then
        echo "FAIL(p4): working tree not clean after the pipeline-mode loop:"
        echo "$DIRT"
        FAILURES=$((FAILURES+1))
    fi
    # (p5) reviewer blinding: no review package contains the log's own text.
    # Compare the package count against the pre-case snapshot. Without this
    # control the loop below reports success when this case examined nothing
    # it wrote — no package written, the `review-package` fallback path taken,
    # or the workspace archived — and this is the plan's only end-to-end check
    # that a real run does not hand the reviewer its own review log. The
    # comparison must be an INCREASE, not "at least one": Case 1 ran in the
    # same project and already left packages behind, so an absolute count
    # could never fail.
    #
    # The increase must be at least TWO — one package per round of this N=2
    # case. One new package is not enough: round 1's package is built before
    # any `chore(review)` log commit exists in `BASE..HEAD`, so it cannot
    # contain the log path and the (p5) grep below can never fail on it. Only
    # a package regenerated AFTER round 1's log commit can catch an unblinded
    # reviewer. A run that reuses round 1's package for round 2 — the exact
    # failure this control exists to detect — leaves exactly one new package,
    # which a "-le $PKG_COUNT_BEFORE" test would let through. Package files
    # are named per range (`review-<base7>..<head7>.diff`), so a correct N=2
    # run leaves two.
    PKG_COUNT=$(ls .superpowers/sdd/review-*.diff 2>/dev/null | wc -l | tr -d ' ' || true)
    if [ "$PKG_COUNT" -lt $((PKG_COUNT_BEFORE + 2)) ]; then
        echo "FAIL(p5-control): fewer than 2 new review packages under .superpowers/sdd/ (before Case 2: $PKG_COUNT_BEFORE, after: $PKG_COUNT) — round 2 did not regenerate after round 1's chore(review) log commit, so the blinding assertion examined only packages built before the log existed"
        FAILURES=$((FAILURES+1))
    fi
    for PKG in .superpowers/sdd/review-*.diff; do
        [ -f "$PKG" ] || continue
        if grep -q 'sum-fix-review-log.md' "$PKG"; then
            echo "FAIL(p5): review package $PKG contains the review log path — the reviewer was not blinded"
            FAILURES=$((FAILURES+1))
        fi
    done
fi
```

- [x] **Step 3: Update the shared plan helper and the sdd integration fixture**

In `tests/claude-code/test-helpers.sh`, replace:

```bash
    local plan_file="$project_dir/docs/plans/$plan_name.md"
```

with:

```bash
    local plan_file="$project_dir/docs/superpowers-orchestrator/2026-08-25-$plan_name/plans/$plan_name.md"
```

In `tests/claude-code/test-subagent-driven-development-integration.sh`, replace:

```bash
mkdir -p src test docs/plans
```

with:

```bash
mkdir -p src test docs/superpowers-orchestrator/2026-08-25-implementation-plan/plans
```

replace:

```bash
cat > docs/plans/implementation-plan.md <<'EOF'
```

with:

```bash
cat > docs/superpowers-orchestrator/2026-08-25-implementation-plan/plans/implementation-plan.md <<'EOF'
```

and replace both prompt strings' plan path `docs/plans/implementation-plan.md` with `docs/superpowers-orchestrator/2026-08-25-implementation-plan/plans/implementation-plan.md`.

- [x] **Step 4: Update the routing-test prompts**

In each of `tests/explicit-skill-requests/run-test.sh`, `run-haiku-test.sh`, `run-multiturn-test.sh`, `run-extended-multiturn-test.sh` and `run-claude-describes-sdd.sh`, replace:

```bash
mkdir -p "$PROJECT_DIR/docs/plans"
```

with:

```bash
mkdir -p "$PROJECT_DIR/docs/superpowers-orchestrator/2026-08-25-auth-system/plans"
```

replace the plan-writing path `"$PROJECT_DIR/docs/plans/auth-system.md"` with `"$PROJECT_DIR/docs/superpowers-orchestrator/2026-08-25-auth-system/plans/auth-system.md"`, and replace every occurrence of the string `docs/plans/auth-system.md` inside the `claude -p` prompts with `docs/superpowers-orchestrator/2026-08-25-auth-system/plans/auth-system.md`.

`run-extended-multiturn-test.sh` is the exception: it contains only the `mkdir -p` line (line 15) — no plan write and no in-prompt path. Change that one line there and nothing else; the other two replacements do not exist in that file.

The prompt files these scripts read (`run-test.sh` takes the prompt file as
`$2`) name the same plan path and must move with it — otherwise the script
creates the plan at the new path while the prompt points the model at a path
that does not exist. In each of `tests/explicit-skill-requests/prompts/i-know-what-sdd-means.txt`, `skip-formalities.txt`, `mid-conversation-execute-plan.txt`, `claude-suggested-it.txt`, `after-planning-flow.txt` and `action-oriented.txt`, replace every occurrence of `docs/plans/auth-system.md` with `docs/superpowers-orchestrator/2026-08-25-auth-system/plans/auth-system.md`. Change nothing else in those files — the surrounding wording is the routing signal under test.

In `tests/skill-triggering/prompts/subagent-driven-development.txt`, replace the whole line with:

```
Implement the next 3 tasks of the plan in docs/superpowers-orchestrator/2026-08-25-foo/plans/foo.md, then write a handoff so I can resume after /clear.
```

In `tests/skill-triggering/prompts/executing-plans.txt`, replace the whole line with:

```
I have a plan document at docs/superpowers-orchestrator/2024-01-15-auth-system/plans/auth-system.md that needs to be executed. Please implement it.
```

In `tools/autoimprove/test-cases.json`, replace `docs/plans/auth-system.md` with `docs/superpowers-orchestrator/2026-08-25-auth-system/plans/auth-system.md` in the prompt at line 28.

- [x] **Step 5: Verify no old-layout fixture path is left**

Run:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -rn 'docs/plans\|docs/specs' tests/ tools/ \
  | grep -v 'docs/superpowers-orchestrator' \
  | grep -v '^tests/sdd-scripts/run-tests.sh:' \
  | grep -v '^tests/codex/test-skill-activator.js:.*docs/specs/2026-08-04-foo-design.md'
```

The needles carry **no trailing slash**, on purpose. Six of the paths Step 4 changes are `mkdir -p` arguments with no trailing slash — `tests/explicit-skill-requests/run-test.sh:46`, `run-haiku-test.sh:15`, `run-multiturn-test.sh:19`, `run-claude-describes-sdd.sh:15`, `run-extended-multiturn-test.sh:15`, and `tests/claude-code/test-subagent-driven-development-integration.sh:46` — and a needle ending in `/` cannot see any of them. An executor could then update the plan path and the prompt path, forget the `mkdir -p`, and still pass: the test would later fail at `cat > .../plans/auth-system.md` because the directory was never created, and no suite this plan runs would catch it.

Expected: no output apart from the four comment lines naming the spec a test implements (`tests/claude-code/test-multi-doc-review.sh:6`, `test-multi-code-review.sh:6`, `test-researching-prior-art.sh:6`, `test-researching-prior-art-gate.sh:6`) — those move in Task 20. Any remaining fixture or prompt path is a miss — fix it before committing.

`tests/sdd-scripts/run-tests.sh` is excluded on purpose. Its `docs/plans/planC.md` fixtures (the `CDPATH` shadow and embedded-newline cases) test `sdd-workspace` against a plan **outside** the layout, which Task 13 keeps as supported behavior — direct mode, no `TOPIC_DIR`. Moving those fixtures would delete that coverage.

`tests/codex/test-skill-activator.js` is excluded on **one line only**: the negative assertion Task 6 Step 1 requires, which feeds `docs/specs/2026-08-04-foo-design.md` to the intent pattern and asserts the pattern no longer matches it. The old-layout path is the point of that test, so it must stay in the file. The filter matches the file name **and** that one string together, so any other old-layout path left in the same file still appears here.

- [x] **Step 6: Run the fast test suites**

Run:

```bash
bash tests/codex/run-unit-tests.sh
bash tests/sdd-scripts/run-tests.sh
```

Expected: PASS both. The behavioral suites (`tests/claude-code/`) need the plugin reinstalled first and are run in Task 22's verification, not here.

- [x] **Step 7: Commit**

```bash
git add tests/ tools/autoimprove/test-cases.json
git commit -m "test: move every fixture and prompt path to the artifact layout" --trailer "Session: artifact-layout" --trailer "Stage: task 17/22"
```

---

### Task 18: record the one-time Windows pathspec check

**Files:**
- Modify: `tests/codex/post-push-validation-checklist.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -q 'MSYS_NO_PATHCONV' tests/codex/post-push-validation-checklist.md && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Append the check**

Append to `tests/codex/post-push-validation-checklist.md`:

````markdown
## One-time: git pathspec magic under Windows Git Bash

The reviewer-blinding pathspecs (`skills/multi-code-review/SKILL.md`,
`skills/subagent-driven-development/scripts/review-package`) start with `:(`.
Under Windows Git Bash (MSYS) argument path conversion is **assumed** to leave
such arguments untouched. This is unverified. Run once, in a throwaway
repository on Windows Git Bash:

```bash
mkdir -p docs/x && echo one > docs/x/a.md && echo two > b.md
git init -q && git add -A && git commit -q -m "first"
echo changed >> docs/x/a.md && echo changed >> b.md
# Run the status check while BOTH changes are still uncommitted. Committing
# first would leave a clean tree, and `git status` would then print nothing
# whether or not MSYS mangled the pathspec — a check that cannot fail.
git status --porcelain -- ':(top)' ':(top,exclude)docs/x/'
git commit -qam "second"
git diff HEAD~1 -- ':(top,exclude,glob)**/*-review-log.md'
```

Expected: the first command prints exactly one line, ` M b.md`, and no line
for `docs/x/a.md`; the second prints the ordinary diff. If the first command
prints nothing at all, prints `docs/x/a.md`, or either command errors, the
conversion mangled the pathspecs: prefix every command carrying them, in the
skills and in `review-package`, with `MSYS_NO_PATHCONV=1`.
````

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 5: Commit**

```bash
git add tests/codex/post-push-validation-checklist.md
git commit -m "docs(tests): record the one-time Windows pathspec check" --trailer "Session: artifact-layout" --trailer "Stage: task 18/22"
```

---

### Task 19: migrate this repository's documents with git mv

**Files:**
- Modify (move): every file under `docs/specs/` and `docs/plans/` except this run's two live files; every file under `docs/superpowers-orchestrator/specs/` and `docs/superpowers-orchestrator/plans/`; `docs/2026-08-22-prior-art-research-step-design.md`
- Modify: `.gitignore`

**Security flag:** `none`

**Does NOT cover:** the two files this orchestration run is holding open — `docs/plans/2026-08-25-artifact-layout.md` (this plan; `subagent-driven-development/SKILL.md:74` stages it by explicit path on every checkbox tick) and `docs/plans/2026-08-25-artifact-layout-orchestration-log.md` (committed by the orchestrator at every phase boundary). Moving either mid-run would break every later commit. They are moved by hand after the run ends; Task 22 records that step in the release notes. It also does NOT cover `.superpowers/reviews/` in this repository (transient, untouched) and does NOT rewrite references **inside** the moved documents (they are historical records).

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
test ! -d docs/specs \
  && test ! -d docs/superpowers-orchestrator/specs \
  && test ! -d docs/superpowers-orchestrator/plans \
  && test ! -f docs/2026-08-22-prior-art-research-step-design.md \
  && test -f docs/superpowers-orchestrator/2026-08-04-orchestrating-development/specs/orchestrating-development-design.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Move the seven `docs/specs/` + `docs/plans/` topics**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
SO=docs/superpowers-orchestrator

move_topic() {  # date slug
  local date="$1" slug="$2" topic="$SO/$1-$2"
  mkdir -p "$topic/specs" "$topic/plans"
  git mv "docs/specs/$date-$slug-design.md" "$topic/specs/$slug-design.md"
  [ -f "docs/specs/$date-$slug-design-review-log.md" ] \
    && git mv "docs/specs/$date-$slug-design-review-log.md" "$topic/specs/$slug-design-review-log.md"
  # the plan carries its own date prefix, which may differ from the spec's
  local planfile
  planfile=$(ls docs/plans/????-??-??-"$slug".md 2>/dev/null | head -1)
  [ -n "$planfile" ] && git mv "$planfile" "$topic/plans/$slug.md"
  local plandate="${planfile##*/}"; plandate="${plandate%%-$slug.md}"
  [ -f "docs/plans/$plandate-$slug-review-log.md" ] \
    && git mv "docs/plans/$plandate-$slug-review-log.md" "$topic/plans/$slug-review-log.md"
  [ -f "docs/plans/$plandate-$slug-open-decisions.md" ] \
    && git mv "docs/plans/$plandate-$slug-open-decisions.md" "$topic/plans/$slug-open-decisions.md"
  [ -f "docs/plans/$plandate-$slug-orchestration-log.md" ] \
    && git mv "docs/plans/$plandate-$slug-orchestration-log.md" "$topic/$slug-orchestration-log.md"
  rmdir "$topic/plans" 2>/dev/null
  return 0
}

move_topic 2026-07-06 sdd-batched-autonomous-mode
move_topic 2026-07-18 sdd-token-optimization
move_topic 2026-07-19 multi-review
move_topic 2026-07-27 multi-code-review
move_topic 2026-07-29 sdd-plan-scoped-workspace
move_topic 2026-08-04 orchestrating-development
move_topic 2026-08-22 researching-prior-art
```

The `multi-review` topic keeps its historical slug: the skill was renamed to `multi-doc-review` later, and the folder records the name the documents use. The topic folder's date is the **spec's** date; a plan written on a later day keeps that topic folder, so `move_topic` looks the plan up by glob rather than assuming the spec's date.

- [x] **Step 4: Move this spec and its review log, then repoint the two references the running orchestration holds**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
SO=docs/superpowers-orchestrator
mkdir -p "$SO/2026-08-25-artifact-layout/specs"
git mv docs/specs/2026-08-25-artifact-layout-design.md \
       "$SO/2026-08-25-artifact-layout/specs/artifact-layout-design.md"
git mv docs/specs/2026-08-25-artifact-layout-design-review-log.md \
       "$SO/2026-08-25-artifact-layout/specs/artifact-layout-design-review-log.md"

# `git mv` moves the files but leaves the now-empty source directory on disk.
# This was the last file in `docs/specs/`, so remove the directory itself —
# Step 1's check tests `test ! -d docs/specs`. `docs/plans/` is NOT removed:
# it still holds this run's two live files.
rmdir docs/specs
```

Do **not** move `docs/plans/2026-08-25-artifact-layout.md` or `docs/plans/2026-08-25-artifact-layout-orchestration-log.md` — see "Does NOT cover" above.

Moving the spec leaves two recorded references pointing at a path that no
longer exists, both of them read by the orchestration that is still running:
this plan's `**Spec:**` header line (`multi-doc-review` reads it to locate the
spec on a direct plan review) and the orchestration log's header, whose spec
path a resume compares against the invoked spec. Repoint both, in place:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
OLD_SPEC='docs/specs/2026-08-25-artifact-layout-design.md'
NEW_SPEC='docs/superpowers-orchestrator/2026-08-25-artifact-layout/specs/artifact-layout-design.md'
# The plan header stores the spec as an absolute path; the orchestration log
# stores the repository-relative form. Replacing the repository-relative tail
# rewrites the absolute form too.
#
# Each substitution is ANCHORED to the single header line that holds the
# reference — `**Spec:**` in the plan, `_Invocation ` in the orchestration log.
# An unanchored global `s|...|...|g` must NOT be used here: the old spec path
# also occurs inside this task's own code blocks (the `git mv` above and the
# `OLD_SPEC=` assignment three lines up), so a global substitution would
# rewrite the plan's own commands and turn any retry of this step into a
# silent no-op.
sed -i '' "/^\*\*Spec:\*\*/s|$OLD_SPEC|$NEW_SPEC|" \
  docs/plans/2026-08-25-artifact-layout.md
sed -i '' "/^_Invocation /s|$OLD_SPEC|$NEW_SPEC|" \
  docs/plans/2026-08-25-artifact-layout-orchestration-log.md
# Both greps are ANCHORED to the header line each `sed` rewrote. An unanchored
# `grep -c "$NEW_SPEC" <plan>` would report at least 1 before the `sed` even
# runs, because the plan file contains the `NEW_SPEC='…'` assignment three
# lines above — so a `sed` that matched nothing would still look successful.
grep -c "^\*\*Spec:\*\*.*$NEW_SPEC" docs/plans/2026-08-25-artifact-layout.md
grep -c "^_Invocation .*$NEW_SPEC" docs/plans/2026-08-25-artifact-layout-orchestration-log.md
```

(On Linux use `sed -i` without the empty `''` argument.) Expected: each command
prints `1`. If either prints `0`, the anchored `sed` matched nothing: check
whether that file recorded the spec under a different spelling before
continuing — a resume that cannot match the recorded spec path stops the run.

- [x] **Step 5: Move the seven March–April files out of the two flat folders**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
SO=docs/superpowers-orchestrator

# The autoimprove spec and plan are one topic.
mkdir -p "$SO/2026-03-24-autoimprove/specs" "$SO/2026-03-24-autoimprove/plans"
git mv "$SO/specs/2026-03-24-autoimprove-design.md" "$SO/2026-03-24-autoimprove/specs/autoimprove-design.md"
git mv "$SO/plans/2026-03-24-autoimprove-plan.md"   "$SO/2026-03-24-autoimprove/plans/autoimprove.md"

# Each remaining file becomes its own topic. A spec keeps (or gains) the
# "-design" suffix; a plan drops a trailing "-plan".
mkdir -p "$SO/2026-03-15-subagent-behavioral-contracts/specs"
git mv "$SO/specs/2026-03-15-subagent-behavioral-contracts-design.md" \
       "$SO/2026-03-15-subagent-behavioral-contracts/specs/subagent-behavioral-contracts-design.md"

mkdir -p "$SO/2026-03-16-meta-memory-behavioral-self-evolution/specs"
git mv "$SO/specs/2026-03-16-meta-memory-behavioral-self-evolution.md" \
       "$SO/2026-03-16-meta-memory-behavioral-self-evolution/specs/meta-memory-behavioral-self-evolution-design.md"

mkdir -p "$SO/2026-03-23-context-engine/plans"
git mv "$SO/plans/2026-03-23-context-engine.md" \
       "$SO/2026-03-23-context-engine/plans/context-engine.md"

mkdir -p "$SO/2026-04-01-claude-code-capability-import-roadmap/plans"
git mv "$SO/plans/2026-04-01-claude-code-capability-import-roadmap.md" \
       "$SO/2026-04-01-claude-code-capability-import-roadmap/plans/claude-code-capability-import-roadmap.md"

mkdir -p "$SO/2026-04-14-flawless-audit/plans"
git mv "$SO/plans/2026-04-14-flawless-audit-plan.md" \
       "$SO/2026-04-14-flawless-audit/plans/flawless-audit.md"

rmdir "$SO/specs" "$SO/plans"
```

- [x] **Step 6: Classify and move the stray file at the `docs/` root**

`docs/2026-08-22-prior-art-research-step-design.md` is **not** a duplicate: `docs/specs/2026-08-22-researching-prior-art-design.md` names it explicitly as its "Rationale record" and states that the spec is the normative distillation. It is a separate document belonging to the `researching-prior-art` topic, so it moves into that topic's `specs/`, keeping its basename minus the date prefix:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
git mv docs/2026-08-22-prior-art-research-step-design.md \
       docs/superpowers-orchestrator/2026-08-22-researching-prior-art/specs/prior-art-research-step-design.md
```

- [x] **Step 7: Drop the stale `.gitignore` entry**

Line 19 of `.gitignore` ignores a path under the now-deleted flat `specs/` folder. Delete the line:

```
docs/superpowers-orchestrator/specs/2026-03-23-extension-ecosystem-design.md
```

- [x] **Step 8: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 9: Confirm every move preserved history and nothing was lost**

Run:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
git status --porcelain \
  | grep -v '^R ' \
  | grep -v '^ M .gitignore' \
  | grep -v ' docs/plans/2026-08-25-artifact-layout' \
  || echo "only renames and the .gitignore edit"
ls docs/plans/
find docs/superpowers-orchestrator -maxdepth 1 -type d | sort
```

The third filter excludes this run's own live files. `docs/plans/2026-08-25-artifact-layout.md` is modified on every checkbox tick and `…-orchestration-log.md` and `…-review-log.md` are written as the run proceeds, so they show as ` M` or `??` at this point. They are outside this task's scope (see "Does NOT cover") and their presence is not a migration failure.

Expected: the first command prints `only renames and the .gitignore edit` (every move is staged as a rename `R`); `docs/plans/` holds exactly the two live files `2026-08-25-artifact-layout.md` and `2026-08-25-artifact-layout-orchestration-log.md` (plus this plan's own `-review-log.md` sidecar if the plan review wrote one); the directory listing shows 15 lines — the parent `docs/superpowers-orchestrator` plus **14 topic folders** (7 from `docs/specs`+`docs/plans`, 1 for `artifact-layout`, 1 for `autoimprove`, and 5 for the remaining March–April files) — and no `specs` or `plans` folder directly under `docs/superpowers-orchestrator/`.

- [x] **Step 10: Commit**

```bash
git add -A -- docs .gitignore
git reset --quiet -- docs/plans/2026-08-25-artifact-layout.md \
                     docs/plans/2026-08-25-artifact-layout-orchestration-log.md \
                     docs/plans/2026-08-25-artifact-layout-review-log.md
git commit -m "chore(docs): move existing documents into per-topic folders" --trailer "Session: artifact-layout" --trailer "Stage: task 19/22"
```

The scope is `docs` as a whole, not a list of sub-directories: `docs/specs`
no longer exists at this point (Step 4 removed it), and `git add` is atomic
across its pathspecs — naming a path that matches nothing aborts the whole
command with `fatal: pathspec 'docs/specs' did not match any files` and stages
nothing, silently leaving Step 7's `.gitignore` edit out of the commit.

`git add -A -- docs` on its own would sweep this run's three live files into
the migration commit. The `git reset` line takes them back out of the index;
they keep their normal lifecycle (the plan file is committed by each checkbox
tick, the orchestration log at each phase boundary). `git reset` on a path
that is not staged is a no-op, so the line is safe whatever state those files
are in.

---

### Task 20: update every link to a moved file

**Files:**
- Modify: `RELEASE-NOTES.md`, `README.md`, `docs/FORK-IMPROVEMENTS.md`, `docs/architecture/project-memory.md`
- Modify: comment headers in `tests/claude-code/test-multi-doc-review.sh`, `test-multi-code-review.sh`, `test-researching-prior-art.sh`, `test-researching-prior-art-gate.sh`

**Security flag:** `none`

**Does NOT cover:** references **inside** the moved historical documents themselves — the spec keeps their contents untouched. It also does NOT cover `README.md:252`, whose `"docs/plans/..."` is an illustrative entry in a context-engine dependency map for an arbitrary project, not a link to a document this repository moved.

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
DATED=$(grep -rn 'docs/specs/2026-\|docs/plans/2026-\|docs/superpowers-orchestrator/specs/\|docs/superpowers-orchestrator/plans/' \
  RELEASE-NOTES.md README.md docs/FORK-IMPROVEMENTS.md docs/architecture/project-memory.md tests/ \
  | grep -v '2026-08-25-artifact-layout' \
  | grep -v '^tests/codex/test-skill-activator.js:.*docs/specs/2026-08-04-foo-design.md' || true)
GENERIC=$(grep -n 'docs/specs/<\|docs/plans/<' README.md docs/FORK-IMPROVEMENTS.md || true)
HISTORICAL=$(grep -n 'Historical documents under' docs/FORK-IMPROVEMENTS.md || true)
printf '%s\n' "$DATED" "$GENERIC" "$HISTORICAL"
[ -z "$DATED$GENERIC$HISTORICAL" ] && echo PASS || echo FAIL
```

The three greps are captured into variables, each guarded with `|| true`, and
the verdict is the final `PASS`/`FAIL` line — the same form every other task
uses. Written as three bare `grep` pipelines the block has two defects: a
successful gate makes every `grep` exit `1` (nothing matched), which aborts the
whole block under `set -euo pipefail` and reads as a failed command to anyone
judging by exit status; and there is no single line to compare against Step 2's
and Step 4's expectations.

The second command is a separate gate for the **generic** path examples Step 3
also replaces (`docs/specs/<doc>.md`, `docs/plans/<plan>.md`, and the rest).
None of them carries a `2026-` date, so the first command cannot see them; a
gate built only on the first command would report PASS with every generic-path
replacement still un-applied.

The third command gates the one remaining replacement that neither of the
first two can see: the `docs/FORK-IMPROVEMENTS.md:105` sentence "Historical
documents under `docs/specs/` and `docs/plans/` keep the old name", whose
paths carry neither a date nor a `<` placeholder. Step 3 replaces that whole
sentence, so the phrase must be gone afterwards.

The fourth `grep -v` excludes exactly one line of
`tests/codex/test-skill-activator.js`: the negative assertion Task 6 Step 1
requires, which feeds `docs/specs/2026-08-04-foo-design.md` to the intent
pattern and asserts the pattern no longer matches it. That line keeps an
old-layout path on purpose — it is what proves the pattern stopped matching
`docs/specs/` — so this gate must not demand its removal. The filter names the
file **and** the string together, so any other old-layout path in that file
still fails the gate.

`docs/guide/README.md` is deliberately **not** in this scope: its 18
old-layout path lines belong to Task 21, which runs after this task and
carries its own gate for that file. Adding it here would make Step 4
unreachable.

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: FAIL — the block prints the stale references (RELEASE-NOTES.md:359, docs/architecture/project-memory.md:197, the four test comment headers, the generic-path lines and the "Historical documents under" line), then the verdict line prints `FAIL`. It must print nothing from `tests/codex/test-skill-activator.js`. Task 6 moved every date-prefixed fixture path in that file to the new layout **except one** — the negative assertion that feeds `docs/specs/2026-08-04-foo-design.md` to the intent pattern and asserts the pattern no longer matches it. That one line stays in the file on purpose, and Step 1's fourth `grep -v` removes it from this gate's output.

- [x] **Step 3: Update the links**

Apply these exact replacements:

| File | Old | New |
|---|---|---|
| `RELEASE-NOTES.md` (v6.7.0 entry) | `docs/specs/2026-07-06-sdd-batched-autonomous-mode-design.md` | `docs/superpowers-orchestrator/2026-07-06-sdd-batched-autonomous-mode/specs/sdd-batched-autonomous-mode-design.md` |
| `docs/architecture/project-memory.md:197` | `docs/superpowers-orchestrator/specs/2026-03-16-meta-memory-behavioral-self-evolution.md` | `docs/superpowers-orchestrator/2026-03-16-meta-memory-behavioral-self-evolution/specs/meta-memory-behavioral-self-evolution-design.md` |
| `tests/claude-code/test-multi-doc-review.sh` header | `docs/specs/2026-07-19-multi-review-design.md` | `docs/superpowers-orchestrator/2026-07-19-multi-review/specs/multi-review-design.md` |
| `tests/claude-code/test-multi-code-review.sh` header | `docs/specs/2026-07-27-multi-code-review-design.md` | `docs/superpowers-orchestrator/2026-07-27-multi-code-review/specs/multi-code-review-design.md` |
| `tests/claude-code/test-researching-prior-art.sh` header | `docs/specs/2026-08-22-researching-prior-art-design.md` | `docs/superpowers-orchestrator/2026-08-22-researching-prior-art/specs/researching-prior-art-design.md` |
| `tests/claude-code/test-researching-prior-art-gate.sh` header | `docs/specs/2026-08-22-researching-prior-art-design.md` | `docs/superpowers-orchestrator/2026-08-22-researching-prior-art/specs/researching-prior-art-design.md` |

Then update the two generic path phrases:

In `docs/FORK-IMPROVEMENTS.md`, replace:

```markdown
*Named `multi-review` through v6.10.0; renamed in v6.11.0 to pair with `multi-code-review`. Historical documents under `docs/specs/` and `docs/plans/` keep the old name.*
```

with:

```markdown
*Named `multi-review` through v6.10.0; renamed in v6.11.0 to pair with `multi-code-review`. The historical topic folder `docs/superpowers-orchestrator/2026-07-19-multi-review/` keeps the old name.*
```

In `docs/FORK-IMPROVEMENTS.md`, apply the seven replacements below so the user-facing paths name the layout. There are seven bullets, not four: stopping early leaves `docs/FORK-IMPROVEMENTS.md` lines 171, 194 and 212 un-updated, and only line 151's omission would be caught by a gate.

- `implement the next 3 tasks from docs/plans/<plan>.md` → `implement the next 3 tasks from docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`
- `/multi-doc-review docs/specs/<doc>.md 3` → `/multi-doc-review docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md 3`
- `run independent review rounds on docs/plans/<plan>.md` → `run independent review rounds on docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`
- `orchestrate development of docs/specs/<spec>.md` → `orchestrate development of docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md`
- `Resume orchestration for docs/plans/<plan>.md` and `Abandon orchestration for docs/plans/<plan>.md` → the same with `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md`
- the committed orchestration log path `docs/plans/<slug>-orchestration-log.md` → `docs/superpowers-orchestrator/<date>-<slug>/<slug>-orchestration-log.md`
- the `.superpowers/reviews/<branch-slug>-review-log.md` mention at `docs/FORK-IMPROVEMENTS.md:171` gains "— or, in a pipeline run, `docs/superpowers-orchestrator/<date>-<slug>/implementation/<slug>-review-log.md`, committed". The **only other** such mention, at line 151, is NOT touched by this bullet: it is handled entirely by the whole-bullet replacement below. Applying both to line 151 would rewrite it first and then leave the whole-bullet replacement with no verbatim match"

The `docs/FORK-IMPROVEMENTS.md:151` bullet needs more than the path: its
trailing clause states the git-ignore rule as an unconditional property of the
skill, which pipeline mode contradicts and Task 22's release note announces.
Replace the whole bullet:

```markdown
- Sidecar audit log at `.superpowers/reviews/<branch-slug>-review-log.md`, git-ignored by a `*` rule so the branch under review can never author its own review record. Early exit after **two consecutive clean rounds**.
```

with:

```markdown
- Sidecar audit log at `.superpowers/reviews/<branch-slug>-review-log.md` — or, in a pipeline run, `docs/superpowers-orchestrator/<date>-<slug>/implementation/<slug>-review-log.md`, committed — so a direct review is never part of the branch under review. Early exit after **two consecutive clean rounds**.
```

The git-ignore claim is dropped rather than qualified: it was the *mechanism*
for a property that pipeline mode achieves differently, and leaving it in would
make the bullet disagree with Task 22's release note.

In `README.md`, replace the two path examples on lines 32 and 34:

- `/multi-doc-review docs/specs/<doc>.md 3` → `/multi-doc-review docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md 3`
- `orchestrate development of docs/specs/<spec>.md` → `orchestrate development of docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md`

- [x] **Step 4: Run the verification check to confirm it passes**

Run: the block from Step 1
Expected: the three greps print nothing, then the verdict line prints `PASS`.

- [x] **Step 5: Commit**

```bash
git add RELEASE-NOTES.md README.md docs/FORK-IMPROVEMENTS.md docs/architecture/project-memory.md tests/claude-code/
git commit -m "docs: repoint every link at the moved documents" --trailer "Session: artifact-layout" --trailer "Stage: task 20/22"
```

---

### Task 21: update the user guide

**Files:**
- Modify: `docs/guide/README.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
! grep -q 'docs/plans/\|docs/specs/' docs/guide/README.md \
  && grep -q 'anchored at the \*\*repository root\*\*' docs/guide/README.md \
  && grep -q 'implementation/' docs/guide/README.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL`

- [x] **Step 3: Update the two pipeline diagrams**

In the first mermaid diagram, replace:

```
    A[Feature request] --> B["Design — brainstorming<br/>spec in docs/specs/"]
```

with:

```
    A[Feature request] --> B["Design — brainstorming<br/>spec in &lt;topic&gt;/specs/"]
```

and replace:

```
    G1 --> C["Plan — writing-plans<br/>plan in docs/plans/"]
```

with:

```
    G1 --> C["Plan — writing-plans<br/>plan in &lt;topic&gt;/plans/"]
```

In the orchestration diagram, replace:

```
    A["orchestrate the development of docs/specs/&lt;spec&gt;.md"] --> P0
```

with:

```
    A["orchestrate the development of docs/superpowers-orchestrator/&lt;date&gt;-&lt;slug&gt;/specs/&lt;slug&gt;-design.md"] --> P0
```

- [x] **Step 4: Update the prose path examples**

Replace each of the following, in order of appearance:

| Old | New |
|---|---|
| `spec to \`docs/specs/YYYY-MM-DD-<name>-design.md\`` | `spec to \`docs/superpowers-orchestrator/YYYY-MM-DD-<slug>/specs/<slug>-design.md\`` |
| `` `docs/plans/YYYY-MM-DD-<name>.md`: tasks with checkboxes `` | `` `docs/superpowers-orchestrator/YYYY-MM-DD-<slug>/plans/<slug>.md`: tasks with checkboxes `` |
| `implement the next 5 tasks of docs/plans/2026-08-08-my-feature.md` | `implement the next 5 tasks of docs/superpowers-orchestrator/2026-08-04-my-feature/plans/my-feature.md` |
| `Resume the plan at docs/plans/2026-08-08-my-feature.md (batched autonomous mode)` (both occurrences) | `Resume the plan at docs/superpowers-orchestrator/2026-08-04-my-feature/plans/my-feature.md (batched autonomous mode)` |
| `Plan saved to \`docs/plans/<filename>.md\`` | `Plan saved to \`docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md\`` |
| `` `Use subagents in batched autonomous mode on docs/plans/<filename>.md` `` | `` `Use subagents in batched autonomous mode on docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` `` |
| `**An approved spec** in \`docs/specs/\`` | `**An approved spec** in \`docs/superpowers-orchestrator/<date>-<slug>/specs/\`` |
| `orchestrate the development of docs/specs/2026-08-04-my-feature-design.md` | `orchestrate the development of docs/superpowers-orchestrator/2026-08-04-my-feature/specs/my-feature-design.md` |
| `_Invocation 1 — 2026-08-08 — spec docs/specs/2026-08-04-my-feature-design.md — …` | `_Invocation 1 — 2026-08-08 — spec docs/superpowers-orchestrator/2026-08-04-my-feature/specs/my-feature-design.md — …` |
| `plan: docs/plans/2026-08-08-my-feature.md — 7 tasks` | `plan: docs/superpowers-orchestrator/2026-08-04-my-feature/plans/my-feature.md — 7 tasks` |
| `Resume orchestration for docs/plans/2026-08-08-my-feature.md` | `Resume orchestration for docs/superpowers-orchestrator/2026-08-04-my-feature/plans/my-feature.md` |
| `Abandon orchestration for docs/plans/2026-08-08-my-feature.md` | `Abandon orchestration for docs/superpowers-orchestrator/2026-08-04-my-feature/plans/my-feature.md` |
| `` `docs/plans/<date>-<slug>-orchestration-log.md`, committed at every boundary `` | `` `docs/superpowers-orchestrator/<date>-<slug>/<slug>-orchestration-log.md`, committed at every boundary `` |

In the "What happens while you're away" table, replace the two artifact cells:

| Old cell | New cell |
|---|---|
| `` `docs/plans/<date>-<slug>.md` `` | `` `docs/superpowers-orchestrator/<date>-<slug>/plans/<slug>.md` `` |
| `` `.superpowers/reviews/` log `` | `` `<topic>/implementation/<slug>-review-log.md`, committed `` |

- [x] **Step 5: Add the layout section and the committed-artifacts note**

Insert a short section immediately after the first pipeline diagram:

````markdown
### Where the documents live

Every document of one feature lives in one **topic folder**:

```
docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/
  specs/<slug>-design.md                 the design, plus its review log
  plans/<slug>.md                        the plan, plus its review log
  implementation/<slug>-review-log.md    the code review log and fix reports
  <slug>-orchestration-log.md            the orchestration run's record
```

The date is the day the design was created and never changes afterwards. The
topic folder is always anchored at the **repository root** — a sub-project
inside a monorepo gets its documents at the monorepo root, and moving the
folder elsewhere makes every document in it "outside the layout", which stops
the pipeline with a message naming the expected location.

Stage folders appear on first write: a topic that stopped at the spec has only
`specs/`.
````

In the "committed artifacts" paragraph (the numbered note about `state.md` and `.superpowers/` being git-excluded), replace:

```markdown
   committed artifacts (plan, checkboxes, logs) are the source of truth;
```

with:

```markdown
   committed artifacts (plan, checkboxes, the orchestration log, and — for a
   pipeline run — everything under the topic's `implementation/`) are the
   source of truth;
```

- [x] **Step 6: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 7: Commit**

```bash
git add docs/guide/README.md
git commit -m "docs(guide): describe the per-topic artifact layout" --trailer "Session: artifact-layout" --trailer "Stage: task 21/22"
```

---

### Task 22: release 7.3.0

**Files:**
- Modify: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `README.md`, `RELEASE-NOTES.md`

**Security flag:** `none`

- [x] **Step 1: Write the failing verification check**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
test "$(cat VERSION)" = "7.3.0" \
  && grep -q '"version": "7.3.0"' .claude-plugin/plugin.json \
  && grep -q '"version": "7.3.0"' .claude-plugin/marketplace.json \
  && grep -q 'version: "7.3.0"' plugin.universal.yaml \
  && grep -q 'version-7.3.0-white' README.md \
  && [ "$(grep -c 'v6.7.0–v7.3.0' README.md)" = "2" ] \
  && grep -q '^## v7.3.0' RELEASE-NOTES.md \
  && echo PASS || echo FAIL
```

- [x] **Step 2: Run it to verify it fails**

Run: the command from Step 1
Expected: prints `FAIL` — everything still says 7.2.0.

- [x] **Step 3: Bump the version in all five places**

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
echo "7.3.0" > VERSION
sed -i '' 's/"version": "7\.2\.0"/"version": "7.3.0"/' .claude-plugin/plugin.json .claude-plugin/marketplace.json
sed -i '' 's/version: "7\.2\.0"/version: "7.3.0"/' plugin.universal.yaml
sed -i '' 's/version-7\.2\.0-white/version-7.3.0-white/' README.md
sed -i '' 's/v6\.7\.0–v7\.2\.0/v6.7.0–v7.3.0/g' README.md
```

(On Linux use `sed -i` without the empty `''` argument.)

- [x] **Step 4: Add the git requirement to the README**

Insert immediately after the `## Installation` heading in `README.md`:

```markdown
**Requirements:** git **2.32 or newer**. The pipeline's commit trailers
(`git commit --trailer`) and its pathspec magic (`:(top)`, `:(exclude)`,
`:(glob)` — used to keep review material out of every reviewer's diff) both
need it.
```

- [x] **Step 5: Write the release-notes entry**

Insert immediately after the `# Superpowers Orchestrator Release Notes` heading in `RELEASE-NOTES.md`:

````markdown
## v7.3.0 — one folder per topic, committed code reviews

Field report: the documents of one feature were spread over three flat
directories, linked only by a shared `YYYY-MM-DD-<slug>` file-name prefix, and
the code review history was never committed. Finding, archiving, or deleting
"everything about feature X" meant matching prefixes across directories.

- **One folder per topic.** Every document of a feature now lives under
  `docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/`, with one sub-folder
  per pipeline stage:

  ```
  docs/superpowers-orchestrator/<YYYY-MM-DD>-<slug>/
    specs/<slug>-design.md                 specs/<slug>-design-review-log.md
    plans/<slug>.md                        plans/<slug>-review-log.md
    plans/<slug>-open-decisions.md
    implementation/<slug>-review-log.md    implementation/<slug>-fix-reports.md
    <slug>-orchestration-log.md
  ```

  File names drop the date — the folder carries it — and keep the slug, so
  editor tabs and grep results stay distinguishable across topics. The rule is
  defined once, in the "Artifact Layout" section of the `brainstorming` skill;
  every other skill states its own exact paths and cites that section.
- **The plugin name returns to the path.** This reverses release v6.6.1, which
  removed it. The reason: the plugin's output is now a folder tree of its own,
  and separating it from the project's own `docs/` tree is worth the extra path
  segment.
- **Code reviews are committed.** A pipeline-driven `multi-code-review` run
  receives a new optional input, `TOPIC_DIR`, and writes its review log and fix
  reports under `<topic>/implementation/`, committing them after every round
  with the subject `chore(review): <slug> round <i> log`. A direct
  `/multi-code-review` run has no plan and therefore no topic folder: it keeps
  today's git-ignored `.superpowers/reviews/` behavior exactly.
- **Reviewers stay blind.** Committed review material is now part of the
  branch, so every whole-branch diff handed to a reviewer excludes
  `<topic>/implementation/` and the file-name shapes `*-review-log.md`,
  `*-fix-reports.md`, `*-orchestration-log.md` and `*-open-decisions.md`. The
  reviewer's read prohibition lists the same set. This also closes a
  pre-existing leak: the committed spec and plan review-log sidecars were
  visible in whole-branch diffs before.
- **This repository was migrated** with `git mv`; document contents are
  untouched. **Other projects are not migrated automatically:** existing
  `docs/specs/` and `docs/plans/` files stay readable as plain files, and new
  topics use the new layout. Skills, hooks and tests know only the new layout —
  a spec or plan outside it stops the pipeline with a message naming the
  expected location, and `writing-plans` offers to move the spec there.
- **Minimum git version: 2.32**, stated explicitly for the first time (also in
  the README). It is needed for `git commit --trailer` and assumed by the
  pathspec magic above.
- **After updating:** an existing `.superpowers/sdd/plan.ref` that points at a
  moved plan makes the next `subagent-driven-development` run treat it as a
  plan switch and archive the workspace under `archive/<old plan basename>/`.
  This is expected after migration and loses nothing.

**Residual risk (accepted):** a second clone of the same branch — another
machine, or CI — that resumes the same committed in-progress review entry is
not detected. Today's batched mode already resumes automatically without such
detection; branch ownership prevents the scenario in practice, and a machine
token in the invocation entry would add state for nothing.

**Post-migration manual step for this repository:** the orchestration run that
implemented this change kept its own plan and orchestration log at
`docs/plans/2026-08-25-artifact-layout.md` and
`docs/plans/2026-08-25-artifact-layout-orchestration-log.md`, because moving
either mid-run would have broken every later checkbox-tick commit. After the
run ends, move them by hand:

```bash
# Task 19 Step 4 created only `.../2026-08-25-artifact-layout/specs`. `git mv`
# fails with "No such file or directory" when the destination directory does
# not exist, so create `plans/` first.
mkdir -p docs/superpowers-orchestrator/2026-08-25-artifact-layout/plans
git mv docs/plans/2026-08-25-artifact-layout.md \
       docs/superpowers-orchestrator/2026-08-25-artifact-layout/plans/artifact-layout.md
git mv docs/plans/2026-08-25-artifact-layout-review-log.md \
       docs/superpowers-orchestrator/2026-08-25-artifact-layout/plans/artifact-layout-review-log.md
git mv docs/plans/2026-08-25-artifact-layout-orchestration-log.md \
       docs/superpowers-orchestrator/2026-08-25-artifact-layout/artifact-layout-orchestration-log.md
```

(Skip any line whose source file does not exist.)
````

- [x] **Step 6: Run the verification check to confirm it passes**

Run: the command from Step 1
Expected: prints `PASS`

- [x] **Step 7: Run the fast test suites and confirm nothing regressed**

Run:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
bash tests/codex/run-unit-tests.sh
bash tests/sdd-scripts/run-tests.sh
bash tests/smart-compress/run-tests.sh
```

Expected: PASS for all three suites, with no failing assertions reported.

- [x] **Step 8: Confirm the README's How-It-Works counts are still correct**

Run:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
grep -n 'Skills Library (\|Hooks (' README.md
ls skills | wc -l
ls hooks/*.js | wc -l
```

Expected, exactly: `## Skills Library (28 skills)` and `### Hooks (10 total)` in the README, `28` from the skills count, `10` from the hooks count. This change adds and removes no skill and no hook, so all four numbers must agree. If a heading disagrees with its count, correct the heading.

- [x] **Step 9: Commit the release**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): 7.3.0 — per-topic artifact layout" --trailer "Session: artifact-layout" --trailer "Stage: task 22/22"
```

This commit comes **before** the reinstall step: the plugin marketplace
resolves the version from the pushed GitHub repository, so an uncommitted
version bump would leave the marketplace on 7.2.0 and Step 10's `7.3.0/`
cache check could never pass.

- [x] **Step 10: Reinstall the plugin, then run the two behavioral suites**

This is the last step of the plan. The behavioral suites run the INSTALLED plugin copy under
`~/.claude/plugins/cache/superpowers-orchestrator/`, not this working tree.
Running them before the reinstall tests the previous release and proves
nothing about this change.

Updating the plugin goes through Claude Code's interactive plugin manager, and
the marketplace entry resolves to the GitHub repository — so this step cannot
be run by an autonomous executor. **Stop and hand it to the user with these
exact instructions:**

1. Push the branch's commits (the marketplace reads
   `brunob54/superpowers-orchestrator` on GitHub, not the local checkout).
2. In a Claude Code session, run `/plugin update superpowers-orchestrator`
   to open the plugin manager, then: **Marketplaces** tab → select
   `brunob54/superpowers-orchestrator` → **Update marketplace**;
   **Installed** tab → select `superpowers-orchestrator` → **Update now**.
3. Confirm the installed copy carries this release:
   `cat ~/.claude/plugins/cache/superpowers-orchestrator/superpowers-orchestrator/7.3.0/VERSION`
   must print `7.3.0`.
4. Start a **fresh** session (the running one keeps the old copy loaded), then
   run:

```bash
cd /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers
tests/claude-code/run-skill-tests.sh --test tests/claude-code/test-multi-doc-review.sh --verbose --timeout 1800
tests/claude-code/run-skill-tests.sh --test tests/claude-code/test-multi-code-review.sh --verbose --timeout 1800
```

Expected: both report `0 failures`. These are slow (up to 30 minutes each); report their output rather than summarizing it.
