# Reviewers per Lens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the parameter M (reviewers per lens, integer 1–5, default 1) to `multi-doc-review` and `multi-code-review` — M identical reviewers dispatched in parallel per round, their reports consolidated with full traceability — carried through `orchestrating-development`, `subagent-driven-development`, and the `SUPERPOWERS_REVIEWERS_PER_LENS` session tag, with tests, documentation, and the 7.4.0 release.

**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-08-27-reviewers-per-lens/specs/reviewers-per-lens-design.md`

**Architecture:** Skills are Markdown procedures read by the model; there is no code path to change for M except one bash hook. `hooks/session-start` reads the environment variable and appends a `<reviewers-per-lens>` tag to the session context it already emits (the same mechanism as `<project-map-stale>`). Each review-loop skill gains a Parameters entry for M, a per-round procedure that dispatches M reviewers in one message and consolidates their reports into one finding set before the existing triage step, and a log format that records M on the invocation line and — when M ≥ 2 — three extra header lines plus a source annotation at the end of every disposition line. The orchestrator asks M in Phase 0 and passes it to its two loop controllers through a new `[M]` template placeholder (subagents never see the session tag); SDD resolves M by the skills' own default order and never asks.

**Tech Stack:** Markdown skills, bash (`hooks/session-start`, tests), Node ≥ 16 (JSON check in the new unit test), the `claude` CLI for behavioral tests.

**Assumptions:**
- Assumes no script parses `_Invocation` lines or `fixed — … → <sha>` lines (verified: `grep -rn '_Invocation' skills/ hooks/ tests/` matches only prose in skills, one comment in `tests/sdd-scripts/run-tests.sh:759`, and no assertion quoting `→`). Will NOT hold if a future script parses those lines — it must then accept `M=<m>` and the ` ← ` annotation.
- Assumes `hooks/session-start` reads no stdin and derives `PLUGIN_ROOT` from its own file location (verified: lines 7–8); `CLAUDE_PLUGIN_ROOT` only selects the JSON output branch. Will NOT hold if the hook starts reading the SessionStart JSON from stdin — the unit test would then need to feed it.
- Assumes the text-drift assertions in `tests/sdd-scripts/run-tests.sh` (lines 637–807) pin sentences this plan does not edit (commit subjects, pathspecs, TOPIC_DIR validation, the "addendum leaves that entry's completion marker unchanged" sentence). Task 3 re-runs that suite to confirm.
- Assumes behavioral tests (`tests/claude-code/`) run against the installed plugin copy (CLAUDE.md constraint): they verify only after the local plugin is reinstalled/updated, and they take 10–30 minutes. They are run once, at the end of Task 6, not as a per-task gate.
- Assumes the frontmatter `description:` of a skill can be reworded without changing routing — routing comes from `hooks/skill-rules.json`, which the spec says needs no change.

**Global Constraints:**
- Valid M is an integer 1–5 inclusive. Any other value (0, 6, a word, a decimal) resolves to the default. Default resolution in both skills: (1) a valid value stated in the invocation; (2) otherwise a valid `<reviewers-per-lens>` tag in the session context; (3) otherwise 1. The skills never ask for M. An invalid stated M is replaced by the default and the substitution is noted in the completion message.
- Accepted invocation forms (case-insensitive; most recent wins): `M=<m>`, `<m> reviewers per lens`, `<m> reviewers per round`, `<m> parallel reviewers`. Every M form is extracted from the invocation **before** N is read. Slash forms: `/multi-doc-review <doc-path> [N] [M=<m>]`, `/multi-code-review [BASE] [N] [M=<m>]`.
- Environment variable `SUPERPOWERS_REVIEWERS_PER_LENS`; session tag `<reviewers-per-lens><m></reviewers-per-lens>`; the hook's validation pattern is exactly `[1-5]`; the tag is appended after `${context_snapshot_escaped}` and passes through `escape_for_json`. Invalid or unset → no tag (silent fallback, documented). The Codex adapter, `hooks/hooks.json`, `hooks/codex-hooks.json`, `hooks/hooks-cursor.json`, `plugin.universal.yaml` hook wiring, and `hooks/skill-rules.json` are NOT changed.
- A controller subagent takes M from its template placeholder `[M]`; a template without an M value means M = 1; a template value wins over a tag.
- Dispatch: M parallel Agent calls in one message, identical prompt and model; only the `description` differs, and only when M ≥ 2: `"multi-doc-review round <i>: <lens name> (reviewer <j>/<m>)"` / `"multi-code-review round <i>: <lens name> (reviewer <j>/<m>)"`. Reviewers are never told other reviewers exist. The reviewer prompt bodies and placeholders are untouched.
- Per-reviewer validation (marker line + Verdict block), one retry per unusable report keeping the reviewer number; u = usable reports; u = 0 → `inconclusive`; 1 ≤ u < m → partial round (never clean).
- Consolidation rules 1–8 of spec section 5.3 (union, same-issue rule, highest severity, most specific text, fresh ids ordered by agreement count, traceability `k` = `k`, renumbering of malformed ids). Carried-finding recommendations are outside the consolidated set; disagreement → most cautious (`user-decision` > `fix-before-merge` > `ship-as-is`). The fix subagent receives no source ids and no agreement counts.
- Clean round = zero Critical and zero Important in the consolidated set **and** u = m. Early exit rule otherwise unchanged (two consecutive clean rounds; N ≤ 2 no mid-loop exit; N = 1 "cap reached").
- Invocation lines record `M=<m>` after `N=<n>` for every M, including 1: `_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_` and `_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — BASE..HEAD <base7>..<head7> — branch <raw-name> — <invoker>_`. A line without `M=` reads as M = 1. Invocation lines are never rewritten; the M passed to the skill governs every round it runs.
- Round entry with M ≥ 2: after the header, `**Reviewers:** M=<m>, usable <u>/<m>`, `**Reviewer verdicts:** r1: <c> Critical, <i> Important, <mi> Minor | r2: … | r3: unusable`, `**Sources mapped:** <k>/<k>`; `**Reviewer verdict:**` keeps its name and position with consolidated counts; every disposition line of a consolidated finding ends with ` ← <a>/<m>: <source ids>` (the annotation-free lines — post-loop addendum lines, round-1 items carried from the ledger, the clean-round `- none` line — are listed in each skill's log-format rules). The `fixed` shape becomes `fixed — <summary> → <sha>[ ← <a>/<m>: <ids>]`; readers of `<sha>` take the token immediately after `→ `. M = 1 entries are byte-identical to today; a resumed invocation whose effective M is 1 while the line records a larger M writes exactly one `**Reviewers:**` line; an effective M ≥ 2 always writes the full three-line format, whatever the invocation line records.
- `REVIEW_DONE …` and `BLOCKED:` return lines of the controllers are unchanged. `requesting-code-review` is unchanged. One M applies to both loops of an orchestration run.
- Orchestration log header: `_Invocation 1 — YYYY-MM-DD — spec <path> — N_plan=<n> N_code=<n> M=<m> cap=<n> — branch feature/<slug> — BASE <sha7>_`; `state.md` line `Params: N_plan=<n> N_code=<n> M=<m> cap=<n>`; a header without `M=` → M = 1 on resume (the one defaulted resume parameter).
- Release 7.4.0: `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta, README badge, the two `v6.7.0–v7.3.0` ranges, the README release enumeration, a `## v7.4.0 — M reviewers per lens` entry in `RELEASE-NOTES.md`.
- Writing style for every sentence added to skills, docs, and comments: plain, literal English; a technical term is defined at its first use; no idioms.

---

## Scope Check

One subsystem: the plugin's review loops and their callers. One plan.

## File Structure

| File | Responsibility in this change |
|---|---|
| `hooks/session-start` (modify) | Emit the `<reviewers-per-lens>` tag from `SUPERPOWERS_REVIEWERS_PER_LENS` |
| `tests/codex/test-session-start-reviewers-tag.sh` (create) | Hermetic shell unit test of the tag (6 cases) |
| `tests/codex/run-unit-tests.sh` (modify) | Accept a bash runner; register the new test |
| `skills/multi-doc-review/SKILL.md` (modify) | Parameter M, M-reviewer round procedure with consolidation, log format, error handling |
| `skills/multi-doc-review/reviewer-prompt.md` (modify) | Header sentence; `description` suffix for M ≥ 2 |
| `skills/multi-code-review/SKILL.md` (modify) | Same as above plus argument parsing order, resume precedence, carried findings, verification re-reviews, `<sha>` reader |
| `skills/multi-code-review/reviewer-prompt.md` (modify) | Header sentence; `description` suffix for M ≥ 2 |
| `skills/orchestrating-development/SKILL.md` (modify) | Phase 0 question, log header, `state.md` Params, resume exception, template fill lists |
| `skills/orchestrating-development/doc-review-loop-prompt.md` (modify) | `[M]` placeholder and parameter line |
| `skills/orchestrating-development/code-review-loop-prompt.md` (modify) | `[M]` placeholder and parameter line; `<sha>` reader note |
| `skills/subagent-driven-development/SKILL.md` (modify) | Final gate M resolution; batched-mode handoff carries a stated M |
| `tests/claude-code/test-helpers.sh` (modify) | `assert_round_reviewers` helper shared by both behavioral tests |
| `tests/claude-code/test-multi-doc-review.sh`, `tests/claude-code/test-multi-code-review.sh` (modify) | M=2 prompts and round-1 assertions |
| `README.md`, `docs/guide/README.md`, `docs/FORK-IMPROVEMENTS.md`, `docs/REVIEW-PROCESS-COMPARISON.md` (modify) | User documentation |
| `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml`, `RELEASE-NOTES.md`, `README.md` (modify) | 7.4.0 release |

Edit notation used below: "replace A with B" means an exact-string replacement inside the named file (Edit tool, or an equivalent `sed`/script); the old text is quoted verbatim from the current file.

---

### Task 1: Session tag from `SUPERPOWERS_REVIEWERS_PER_LENS` (hook + unit test)

**Files:**
- Create: `tests/codex/test-session-start-reviewers-tag.sh`
- Modify: `tests/codex/run-unit-tests.sh`
- Modify: `hooks/session-start`

**Security flag:** `security` (validates an environment variable before interpolating it into JSON emitted to the session; the `[1-5]` pattern is the only guard).

**Does NOT cover:** the Codex adapter `hooks/codex/session-start-adapter.js` (no Codex consumer of the tag exists); a separate Cursor change (Cursor runs this same bash script); values outside 1–5 (they produce no tag — a silent fallback, documented in Task 7); making a changed value take effect without restarting the CLI.

- [x] **Step 1: Write the failing unit test**

Create `tests/codex/test-session-start-reviewers-tag.sh` with this content:

```bash
#!/usr/bin/env bash
# Unit test: hooks/session-start emits <reviewers-per-lens><m></reviewers-per-lens>
# when SUPERPOWERS_REVIEWERS_PER_LENS is an integer from 1 to 5, and emits no
# tag otherwise (unset, 0, 6, 10, abc).
#
# The hook is not a pure function of the variable, so every run is hermetic:
#   - SUPERPOWERS_AUTO_UPDATE=0   -> no network fetch, no fast-forward of the checkout
#   - an empty working directory -> no project-map.md, state.md, session-log.md,
#                                   known-issues.md or context-snapshot.json is read
#   - a temporary HOME           -> the hook writes ~/.claude/hooks-logs/update-check.cache
#   - CLAUDE_PLUGIN_ROOT set     -> the Claude Code output branch is exercised
# The output is parsed with JSON.parse (Node), so a malformed JSON document fails
# the test as well.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK="${REPO_ROOT}/hooks/session-start"
VAR_NAME="SUPERPOWERS_REVIEWERS_PER_LENS"
TAG_OPEN="<reviewers-per-lens>"
TAG_CLOSE="</reviewers-per-lens>"

TMP_HOME=$(mktemp -d)
TMP_CWD=$(mktemp -d)
trap 'rm -rf "$TMP_HOME" "$TMP_CWD"' EXIT

PASS=0
FAIL=0

ok()  { PASS=$(( PASS + 1 )); echo "  ok   - $1"; }
bad() { FAIL=$(( FAIL + 1 )); echo "  FAIL - $1"; }

# run_hook [VAR=value]
# Runs the hook in the hermetic environment, optionally with one extra
# variable assignment, and prints the additionalContext string of the Claude
# Code output branch. JSON.parse doubles as a well-formedness check.
# SYSTEMROOT and TEMP pass through when they are set: on Windows Git Bash the
# native git.exe the hook calls can need them to start; on macOS and Linux
# they are unset and nothing is added.
run_hook() {
  local extra=()
  [ $# -gt 0 ] && extra=("$1")
  (cd "$TMP_CWD" && env -i PATH="$PATH" HOME="$TMP_HOME" \
      CLAUDE_PLUGIN_ROOT="$REPO_ROOT" SUPERPOWERS_AUTO_UPDATE=0 \
      ${SYSTEMROOT:+SYSTEMROOT="$SYSTEMROOT"} ${TEMP:+TEMP="$TEMP"} \
      ${extra[@]+"${extra[@]}"} bash "$HOOK") \
    | node -e '
      const j = JSON.parse(require("fs").readFileSync(0, "utf8"));
      process.stdout.write(j.hookSpecificOutput.additionalContext);'
}

# expect_tag <value>: the tag with that value is present and ends the context
expect_tag() {
  local value="$1" ctx
  ctx=$(run_hook "${VAR_NAME}=${value}")
  case "$ctx" in
    *"${TAG_OPEN}${value}${TAG_CLOSE}") ok "${VAR_NAME}=${value} emits ${TAG_OPEN}${value}${TAG_CLOSE} at the end of the context" ;;
    *) bad "${VAR_NAME}=${value} does not end the context with ${TAG_OPEN}${value}${TAG_CLOSE}" ;;
  esac
}

# expect_no_tag <label> [VAR=value]: no tag at all in the context
expect_no_tag() {
  local label="$1" ctx
  shift
  ctx=$(run_hook "$@")
  case "$ctx" in
    *"${TAG_OPEN}"*) bad "${label} emits a tag" ;;
    *) ok "${label} emits no tag" ;;
  esac
}

echo "session-start: <reviewers-per-lens> tag"
expect_tag 3
expect_no_tag "unset ${VAR_NAME}"
for v in 0 6 10 abc; do
  expect_no_tag "${VAR_NAME}=${v}" "${VAR_NAME}=${v}"
done

echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
```

- [x] **Step 2: Register the test in the fast unit-test entry point**

In `tests/codex/run-unit-tests.sh`, replace:

```bash
run_test() {
  local label="$1"
  local file="$2"
  echo "── ${label}"
  if node "${file}"; then
```

with:

```bash
run_test() {
  local label="$1"
  local file="$2"
  # Interpreter that runs the test file: node (default) or bash.
  local runner="${3:-node}"
  echo "── ${label}"
  if "${runner}" "${file}"; then
```

and replace:

```bash
run_test "session-start-adapter" "${SCRIPT_DIR}/test-session-start-adapter.js"
```

with:

```bash
run_test "session-start-adapter" "${SCRIPT_DIR}/test-session-start-adapter.js"
run_test "session-start (reviewers-per-lens tag)" "${SCRIPT_DIR}/test-session-start-reviewers-tag.sh" bash
```

- [x] **Step 3: Run the test to verify it fails**

Run: `bash tests/codex/test-session-start-reviewers-tag.sh`
Expected: the header line `session-start: <reviewers-per-lens> tag`, then the line `  FAIL - SUPERPOWERS_REVIEWERS_PER_LENS=3 does not end the context with <reviewers-per-lens>3</reviewers-per-lens>` (two leading spaces), then five `  ok   - …` lines, then `  5 passed, 1 failed`, exit status 1.

- [x] **Step 4: Implement the hook change (three placements)**

Placement 1 — with the content blocks, before the `escape_for_json` definition. In `hooks/session-start`, replace:

```bash
    if [ -n "$changed" ]; then
        context_snapshot_content="\n\n<context-snapshot>\n${changed}\n</context-snapshot>"
    fi
fi

# ── Load using-superpowers skill body ─────────────────────────────────────────
```

with:

```bash
    if [ -n "$changed" ]; then
        context_snapshot_content="\n\n<context-snapshot>\n${changed}\n</context-snapshot>"
    fi
fi

# ── Reviewers per lens ────────────────────────────────────────────────────────
# SUPERPOWERS_REVIEWERS_PER_LENS (an integer from 1 to 5) is the number of
# reviewer subagents the review-loop skills dispatch per round. Skills are
# Markdown read by the model and cannot read environment variables, so the
# value travels as a session tag. Any other value (unset, 0, 6, 10, 3.0, a
# word) emits nothing and the skills fall back to 1. The pattern [1-5]
# matches exactly one character.
reviewers_content=""
case "${SUPERPOWERS_REVIEWERS_PER_LENS:-}" in
  [1-5]) reviewers_content="\n\n<reviewers-per-lens>${SUPERPOWERS_REVIEWERS_PER_LENS}</reviewers-per-lens>" ;;
esac

# ── Load using-superpowers skill body ─────────────────────────────────────────
```

Placement 2 — in the escape group, after the definition. Replace:

```bash
context_snapshot_escaped=$(escape_for_json "$context_snapshot_content")
```

with:

```bash
context_snapshot_escaped=$(escape_for_json "$context_snapshot_content")
reviewers_escaped=$(escape_for_json "$reviewers_content")
```

Placement 3 — the end of the `session_context` assignment. Replace:

```bash
${known_issues_escaped}${context_snapshot_escaped}"
```

with:

```bash
${known_issues_escaped}${context_snapshot_escaped}${reviewers_escaped}"
```

(That string occurs once, at the end of the single-line `session_context=` assignment.)

- [x] **Step 5: Run the tests to verify they pass**

Run: `bash tests/codex/test-session-start-reviewers-tag.sh`
Expected: six `ok` lines, `6 passed, 0 failed`, exit status 0.

Run: `bash tests/codex/run-unit-tests.sh`
Expected: the new suite `── session-start (reviewers-per-lens tag)` listed, and the line ` All unit tests passed.` (one leading space; the final line is the `=====` rule that follows it).

Run: `bash -n hooks/session-start`
Expected: no output (syntax valid).

- [x] **Step 6: Commit**

```bash
git add hooks/session-start tests/codex/test-session-start-reviewers-tag.sh tests/codex/run-unit-tests.sh
git commit -m "feat(hooks): emit the reviewers-per-lens session tag from SUPERPOWERS_REVIEWERS_PER_LENS" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 1/8"
```

---

### Task 2: `multi-doc-review` — parameter M, M-reviewer rounds, consolidation, log format

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Modify: `skills/multi-doc-review/reviewer-prompt.md`

**Security flag:** `none`

**Does NOT cover:** asking the user for M (never); a majority vote among reviewers; passing agreement counts to any fixer; file-based report transport; prompt diversity between the M reviewers; the reviewer prompt body (untouched).

- [x] **Step 1: Frontmatter description and slash form**

In `skills/multi-doc-review/SKILL.md`, replace:

```
  MUST USE when a spec or plan document needs N independent review rounds
  with findings merged between rounds. One clean-context reviewer subagent
  per round under a rotating lens; findings triaged into the document; a
  sidecar audit log records every disposition; early exit after two
  consecutive clean rounds. Invoked by brainstorming (spec gate) and
  writing-plans (plan gate), or directly via /multi-doc-review <doc-path> [N].
```

with:

```
  MUST USE when a spec or plan document needs N independent review rounds
  with findings merged between rounds. M clean-context reviewer subagents
  per round (default 1) under a rotating lens; findings triaged into the
  document; a sidecar audit log records every disposition; early exit
  after two consecutive clean rounds. Invoked by brainstorming (spec gate)
  and writing-plans (plan gate), or directly via
  /multi-doc-review <doc-path> [N] [M=<m>].
```

- [x] **Step 2: Parameters — N reads after M; new M bullet**

Replace:

```
- **N (round cap):** if the user stated a count, use it (most recent wins).
  Otherwise ask once — at gate time for gate invocations, immediately for
  direct invocations. Default **3**. Valid N is an integer 0–10; anything
  else → 3. N = 0 skips the loop and logs a `skipped` entry.
```

with:

```
- **N (round cap):** if the user stated a count, use it (most recent wins;
  every M form is extracted from the invocation first — see M below).
  Otherwise ask once — at gate time for gate invocations, immediately for
  direct invocations. Default **3**. Valid N is an integer 0–10; anything
  else → 3. N = 0 skips the loop and logs a `skipped` entry.
- **M (reviewers per lens):** the number of reviewer subagents dispatched
  per round, all under the round's lens with the identical prompt. Valid M
  is an integer 1–5; anything else (0, 6, a word, a decimal) → the default
  below, and the substitution is noted in the completion message. **Never
  ask for M.** Resolution order:
  1. a value stated in the invocation — `M=<m>`, `<m> reviewers per lens`,
     `<m> reviewers per round`, or `<m> parallel reviewers`
     (case-insensitive; the most recent wins) — if valid;
  2. otherwise the value of a `<reviewers-per-lens>` tag in the session
     context (emitted by `hooks/session-start` from the environment
     variable `SUPERPOWERS_REVIEWERS_PER_LENS`; visible to the main session
     only — subagents never receive it) — if valid;
  3. otherwise **1**.
  A controller subagent takes M from its template placeholder; a template
  without an M value means M = 1; a template value wins over a tag. Extract
  every M form from the invocation **before** reading N, so that a count
  inside an M form is never read as N: "review the spec 2 times with 3
  reviewers per round" gives N = 2 and M = 3. The M passed to this
  invocation governs every round it runs, including the remaining rounds
  of a resumed invocation whose log line records another M; an invocation
  line is never rewritten. Running time stays close to one review because
  the M reviewers run at the same time; the token cost grows about M times
  per round.
```

- [x] **Step 3: Procedure — invocation note records M**

Replace:

```
target document and append an invocation note: date, N, and invoker
```

with:

```
target document and append an invocation note: date, N, M, and invoker
```

- [x] **Step 4: Procedure — per-round steps with M reviewers and consolidation**

Replace (steps 1–5, verbatim from the current file):

```
1. **Dispatch one reviewer** using `reviewer-prompt.md` with round `i`'s
   lens (Lens Rotation below; for N > 4 cycle from lens 1). Fill ONLY the
   template placeholders. Never pass the conversation, design rationale,
   prior findings, or the log.
2. **Validate the report:** first line is `<!-- multi-review report -->` and
   a Verdict block is present. An unusable report → retry the identical
   dispatch once; on second failure log the round as `inconclusive` and
   continue to the next round.
3. **Triage and merge:** every Critical/Important finding is either applied
   to the document or `rejected: <reason>` — never silently dropped. Minor
   findings: apply at your discretion; log all dispositions either way.
4. **Append the round entry** to the log (format below).
5. **Convergence check:** severities come from the report's enumerated
   findings — the count line is informational; on disagreement the
   enumeration wins. A round is *clean* when it enumerates zero Critical and
   zero Important. Exit the loop early only after **two consecutive clean
   rounds**; an `inconclusive` round breaks the streak. Rejecting findings
   at triage never makes a round clean. With N ≤ 2 no mid-loop exit occurs,
   but still report "converged" if the final two rounds were clean; N = 1
   always reports "cap reached".
```

with:

```
1. **Dispatch M reviewers in one message** — M parallel Agent tool calls
   (the convention of `skills/dispatching-parallel-agents/SKILL.md`), each
   filled from `reviewer-prompt.md` with the same placeholder values:
   round `i`'s lens (Lens Rotation below; for N > 4 cycle from lens 1),
   the same document path, the same model. Fill ONLY the template
   placeholders. Never pass the conversation, design rationale, prior
   findings, or the log. Reviewer `j` of the round is written `r<j>`. The
   reviewers are not told that other reviewers exist: only the Agent
   call's `description` differs, and only when M ≥ 2 (the
   `(reviewer <j>/<m>)` suffix shown in the template). A platform that
   runs the calls one after another gives the same result, only slower.
2. **Validate each report and consolidate:** a report is usable when its
   first line is `<!-- multi-review report -->` and a Verdict block is
   present. Each unusable report → retry the identical dispatch once,
   keeping the same reviewer number; the retries of one round may go out
   together in one message. After the retries, *u* = the number of usable
   reports. u = 0 → log the round as `inconclusive` (nothing is triaged,
   the clean streak is broken) and continue to the next round. u ≥ 1 →
   build one **consolidated finding set** from the usable reports by the
   rules below, then continue; a round with u < M is *partial* — it is
   logged with its counts and is never clean. With M = 1 the consolidated
   set is the report's enumeration with its original ids, unchanged.
   1. Enumeration is the source of truth: findings come from each report's
      enumerated findings, never from its count line.
   2. Union: every enumerated finding of every usable report appears in
      the set, on its own or inside a consolidated finding. Nothing is
      dropped at this step.
   3. Same-issue rule: two findings are the same issue when they point at
      the same place **and** describe the same defect — one single change
      would resolve both. "Same place" means the deepest numbered section
      (or heading) cited; a finding that cites several sections is placed
      at the first one it cites. Different defects at the same place stay
      separate. When in doubt, keep them separate: a duplicate costs one
      `rejected: duplicate of [..]` disposition at triage; a wrongly merged
      pair loses a finding.
   4. Severity: a consolidated finding takes the highest severity any of
      its sources gave it.
   5. Text: keep the most specific description among the sources; details
      from several sources may be combined, but no claim that no source
      made may be added.
   6. Ids: whenever M ≥ 2 — a partial round with a single usable report
      included — consolidated findings get fresh ids per severity class,
      `C1…`, `I1…`, `M1…`, ordered by agreement count (the number of
      distinct reviewers that reported the finding, highest first), then
      by the lowest reviewer number among the sources, then by that
      reviewer's own id order. Reviewer-local ids appear only as source
      ids in the log — `r<j>:<id>`, for example `r1:I2`.
   7. Traceability: every source id maps to exactly one consolidated
      finding. Count the enumerated findings across the usable reports
      (*k*) and the source ids you mapped; the two numbers must be equal
      before the round entry is written. On a mismatch repair the
      consolidation, never the count.
   8. Malformed ids: a usable report may carry missing or duplicated ids,
      or a finding under a severity heading that does not match its id
      prefix. Before consolidation renumber that report's findings by
      position within each severity heading (`C1…`, `I1…`, `M1…` in order
      of appearance; the heading decides the severity) and note
      `ids renumbered` on that reviewer's entry of the
      `**Reviewer verdicts:**` line. This rule applies to M ≥ 2 only: with
      M = 1 the report keeps its original ids (today's behavior, unchanged)
      — there is no `**Reviewer verdicts:**` line to carry the note, and the
      M = 1 entry stays byte-identical to earlier releases.
3. **Triage and merge:** the consolidated set is the input. Every
   Critical/Important finding is either applied to the document or
   `rejected: <reason>` — never silently dropped. Minor findings: apply at
   your discretion; log all dispositions either way.
4. **Append the round entry** to the log (format below).
5. **Convergence check:** severities come from the consolidated set's
   enumerated findings — a report's count line is informational; on
   disagreement the enumeration wins, and with M ≥ 2 the disagreement is
   noted as `, counts recomputed` on that reviewer's entry of the
   `**Reviewer verdicts:**` line. A round is *clean* when the consolidated
   set enumerates zero Critical and zero Important **and** all M reviewers
   returned a usable report (u = M); a partial round is never clean and
   breaks the streak, like an `inconclusive` round. Exit the loop early
   only after **two consecutive clean rounds**. Rejecting findings at
   triage never makes a round clean. With N ≤ 2 no mid-loop exit occurs,
   but still report "converged" if the final two rounds were clean; N = 1
   always reports "cap reached". Because the union keeps every reviewer's
   findings, two consecutive clean rounds are harder to reach with M > 1
   than with M = 1 — that is the intended effect.
```

- [x] **Step 5: Review Log Format**

Replace (the whole current block and the two sentences after it):

````
```
_Invocation <k> — YYYY-MM-DD — N=<n> — <invoker>_

## Round <i> — <lens name> — <model>
**Reviewer verdict:** <n> Critical, <n> Important, <n> Minor
**Converged:** yes/no   <!-- "yes" only on the round where the loop exits
                             via convergence; every other round "no" -->

### Dispositions
- [C1] applied — <doc section>: <finding summary> → <change made>
- [I1] rejected: <reason> — <finding summary>
- [M2] deferred — <finding summary>
```

A clean round (zero findings) writes exactly one disposition line:
`- none — no material issues under this lens`.
Skipped invocations (N=0) get a one-line `skipped` entry under their
invocation note; failed rounds get `inconclusive` entries.
````

with:

````
The invocation line records M right after N, **including when M = 1**, so
that a log is self-describing. A line without `M=` (written by a release
before 7.4.0) is read as M = 1. Round entry with M = 1 (byte-identical to
earlier releases):

```
_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — <invoker>_

## Round <i> — <lens name> — <model>
**Reviewer verdict:** <n> Critical, <n> Important, <n> Minor
**Converged:** yes/no   <!-- "yes" only on the round where the loop exits
                             via convergence; every other round "no" -->

### Dispositions
- [C1] applied — <doc section>: <finding summary> → <change made>
- [I1] rejected: <reason> — <finding summary>
- [M2] deferred — <finding summary>
```

Round entry with M ≥ 2 — three lines added after the header, and a source
annotation at the **end** of every finding disposition line:

```
## Round <i> — <lens name> — <model>
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 0 Important, 1 Minor | r2: 0 Critical, 1 Important, 0 Minor | r3: 0 Critical, 1 Important, 0 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 1 Critical, 1 Important, 1 Minor
**Converged:** no

### Dispositions
- [C1] applied — <doc section>: <finding summary> → <change made> ← 2/3: r1:C1, r3:I1
- [I1] rejected: <reason> — <finding summary> ← 1/3: r2:I1
- [M1] deferred — <finding summary> ← 1/3: r1:M1
```

(In this example r1 and r3 reported the same issue — r1 as Critical,
r3 as Important — so it is one consolidated finding at the highest
severity: the four source ids (k = 4) map to three consolidated findings,
and every source id appears in exactly one annotation.)

Rules for the added lines:

- `**Reviewers:**` — M and the usable count *u* of this round. Written when
  M ≥ 2, and also when the effective M of the round is 1 while the
  invocation line records a larger M (a resumed invocation given a new M):
  then it is the only added line — `**Reviewers:** M=1, usable 1/1`, or
  `usable 0/1` for an inconclusive round — with original ids, no source
  annotation, and no `**Reviewer verdicts:**` or `**Sources mapped:**` line.
  An effective M ≥ 2 always writes all three lines and the source
  annotations, whatever M the invocation line records.
- `**Reviewer verdicts:**` — one entry per reviewer in reviewer order, the
  counts taken from each report's enumeration. A usable reviewer with no
  findings is written `r<j>: 0 Critical, 0 Important, 0 Minor`; an unusable
  reviewer `r<j>: unusable`; a reviewer whose ids were renumbered gets the
  suffix `, ids renumbered`, and one whose count line disagreed with its
  enumeration the suffix `, counts recomputed`. A reviewer that needs both
  suffixes gets `, ids renumbered` first, then `, counts recomputed`.
- `**Sources mapped:**` — the traceability check of the procedure; both
  numbers are *k*. The entry is written only after the check passed, so the
  two numbers are always equal.
- `**Reviewer verdict:**` — keeps its name and position; with M ≥ 2 it
  carries the **consolidated** counts.
- Source annotation — ` ← <a>/<m>: <source ids>` appended at the end of the
  disposition line; `<a>` is the agreement count (distinct reviewers that
  reported the finding), the source ids are comma-separated in reviewer
  order. The line keeps its existing prefix (`- [I1] applied — …`), so
  patterns anchored at the start of the line still match. The note lines
  the "After the loop" step writes for merge-introduced fixes (self-review
  notes) carry no annotation.
- The clean-round line `- none — no material issues under this lens` is
  written without annotation and only when the consolidated set is empty
  **and** u = M. A partial round with an empty consolidated set writes
  `- none — no material issues under this lens (partial round, usable <u>/<m>)`.
- An `inconclusive` round (u = 0) with M ≥ 2 writes
  `**Reviewers:** M=<m>, usable 0/<m>`,
  `**Reviewer verdicts:** r1: unusable | r2: unusable | …`, no
  `**Sources mapped:**` line (nothing was consolidated), then
  `**Reviewer verdict:** inconclusive` and `- inconclusive — <reason>`.

A clean round (zero findings) writes exactly one disposition line:
`- none — no material issues under this lens`.
Skipped invocations (N=0) get a one-line `skipped` entry under their
invocation note (which carries `M=` like every other); failed rounds get
`inconclusive` entries.
````

- [x] **Step 6: Error Handling**

Replace:

```
- Invalid N (not an integer 0–10) → 3. N = 0 → skip, log.
```

with:

```
- Invalid N (not an integer 0–10) → 3. N = 0 → skip, log.
- M stated but invalid (0, 6, `two`, `2.5`) → the default of the Parameters
  resolution (tag, else 1); never ask; note the substitution in the
  completion message. Session tag absent or invalid → 1 (silent fallback).
- One or more reviewers unusable after one retry, u ≥ 1 → partial round:
  consolidate the usable reports, log `usable <u>/<m>` and `r<j>: unusable`,
  triage normally; the round is never clean.
- All reviewers unusable after retries (u = 0) → `inconclusive` round.
- Sources-mapped mismatch (source ids mapped ≠ findings enumerated) →
  repair the consolidation before writing the entry; never write the line
  with unequal numbers.
- Reviewer report with missing or duplicated ids → renumber by position per
  severity heading, note `ids renumbered` (M ≥ 2 only; with M = 1 the report
  keeps its original ids, as today).
- Review-log invocation line without `M=` → read as M = 1; the M of this
  invocation always comes from its parameters, never from the log.
- Platform without parallel dispatch → reviewers run one after another;
  the procedure is unchanged.
```

- [x] **Step 7: Reviewer template header and `description` suffix**

In `skills/multi-doc-review/reviewer-prompt.md`, replace:

```
Use this template when dispatching a multi-doc-review reviewer subagent. One
reviewer per round; the lens comes from SKILL.md's Lens Rotation table.
```

with:

```
Use this template when dispatching a multi-doc-review reviewer subagent. M
reviewers per round (default 1), all with this identical prompt; the lens
comes from SKILL.md's Lens Rotation table. The reviewers are not told that
other reviewers exist.
```

and replace:

```
  description: "multi-doc-review round [ROUND]: [LENS_NAME]"
```

with:

```
  description: "multi-doc-review round [ROUND]: [LENS_NAME]"
               (when M ≥ 2 append " (reviewer <j>/<m>)" — reviewer j of m;
               the description is not part of the prompt)
```

- [x] **Step 8: Verify**

Run: `grep -c 'M=<m>' skills/multi-doc-review/SKILL.md`
Expected: a number ≥ 3.

Run: `grep -n 'Dispatch one reviewer\|One reviewer per round\|^reviewer per round;\|N=<n> — <invoker>' skills/multi-doc-review/SKILL.md skills/multi-doc-review/reviewer-prompt.md`
Expected: no output.

Run: `grep -n '^\*\*Reviewers:\*\* M=3, usable 3/3$\|^\*\*Sources mapped:\*\* 4/4$' skills/multi-doc-review/SKILL.md`
Expected: two matching lines (the M ≥ 2 example of the Review Log Format section).

- [x] **Step 9: Commit**

```bash
git add skills/multi-doc-review/SKILL.md skills/multi-doc-review/reviewer-prompt.md
git commit -m "feat(multi-doc-review): M reviewers per lens with report consolidation" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 2/8"
```

---

### Task 3: `multi-code-review` — parameter M, M-reviewer rounds, consolidation, carried findings, verification re-reviews, log format

**Files:**
- Modify: `skills/multi-code-review/SKILL.md`
- Modify: `skills/multi-code-review/reviewer-prompt.md`
- Test: `tests/sdd-scripts/run-tests.sh` (existing text-drift assertions, re-run only)

**Security flag:** `none`

**Does NOT cover:** `requesting-code-review` (its reviewer + red-team pair stays as it is); reading M back from a review log on resume (M always comes from the parameters); a new timeout for a hung reviewer; a change to the package generation (one package per round, shared by the M reviewers); passing agreement counts or source ids to the fix subagent.

- [ ] **Step 1: Frontmatter description and slash form**

In `skills/multi-code-review/SKILL.md`, replace:

```
  rounds with fixes applied between rounds. One clean-context reviewer
  subagent per round under a rotating lens (correctness/spec alignment,
```

with:

```
  rounds with fixes applied between rounds. M clean-context reviewer
  subagents per round (default 1) under a rotating lens (correctness/spec alignment,
```

and replace:

```
  directly via /multi-code-review [BASE] [N]. Triggers on: "multi code
```

with:

```
  directly via /multi-code-review [BASE] [N] [M=<m>]. Triggers on: "multi code
```

- [ ] **Step 2: Parameters — argument order, M bullet, direct slash form**

Replace:

```
`master`, and take `git merge-base <default> HEAD`. Single-argument
  form: an integer 0–10 is N; anything else — including an integer
  outside 0–10 — is a git ref (BASE), never an invalid N. If the
```

with:

```
`master`, and take `git merge-base <default> HEAD`. Every `M=<m>` token
  and every M prose form is extracted from the invocation **first** (see
  M below); the positional rule applies to the remaining arguments only —
  `M=2` contains `=` and would otherwise be rejected as a BASE by the ref
  charset above. Single-argument form: an integer 0–10 is N; anything
  else — including an integer outside 0–10 — is a git ref (BASE), never
  an invalid N. If the
```

Replace:

```
  Autonomous Mode never asks:** default 3, or a count the user stated
  when starting the batch run.
```

with:

```
  Autonomous Mode never asks:** default 3, or a count the user stated
  when starting the batch run.
- **M (reviewers per lens):** the number of reviewer subagents dispatched
  per round, all under the round's lens with the identical prompt and the
  same model. Valid M is an integer 1–5; anything else (0, 6, a word, a
  decimal) → the default below, and the substitution is noted in the
  completion message. **Never ask for M** (in every mode). Resolution
  order:
  1. a value stated in the invocation — `M=<m>`, `<m> reviewers per lens`,
     `<m> reviewers per round`, or `<m> parallel reviewers`
     (case-insensitive; the most recent wins) — if valid;
  2. otherwise the value of a `<reviewers-per-lens>` tag in the session
     context (emitted by `hooks/session-start` from the environment
     variable `SUPERPOWERS_REVIEWERS_PER_LENS`; visible to the main session
     only — subagents never receive it) — if valid;
  3. otherwise **1**.
  A controller subagent takes M from its template placeholder; a template
  without an M value means M = 1; a template value wins over a tag. The
  M passed to this invocation governs every round it runs, including the
  remaining rounds of a resumed invocation whose log line records another
  M. Running time stays close to one review because the M reviewers run
  at the same time; the token cost grows about M times per round.
```

Replace:

```
  `/multi-code-review [BASE] [N]` — direct, no `TOPIC_DIR`; and the pipeline
```

with:

```
  `/multi-code-review [BASE] [N] [M=<m>]` — direct, no `TOPIC_DIR`; and the pipeline
```

- [ ] **Step 3: Workspace and Log — invocation note and resume precedence**

Replace:

```
Open the log and append an invocation note recording: date, N,
BASE..HEAD, **raw branch name**, and invoker (`gate: sdd` | `direct`).
Round numbering continues across invocations; lens selection uses the
**per-invocation** round index.
```

with:

```
Open the log and append an invocation note recording: date, N, M,
BASE..HEAD, **raw branch name**, and invoker (`gate: sdd` | `direct`).
Round numbering continues across invocations; lens selection uses the
**per-invocation** round index. The resume path below matches an open
entry by invoker kind and BASE only and takes N and M from the parameters
this invocation was given — it recovers no parameter from the log, and an
invocation line is never rewritten. An invocation line without `M=`
(written before 7.4.0) reads as M = 1. When the effective M of a round
differs from the M on the invocation line, the round entry says so on its
`**Reviewers:**` line (Review Log Format).
```

- [ ] **Step 4: Procedure — dispatch M reviewers, validate each, consolidate**

Replace (steps 2–3 verbatim):

```
2. **Dispatch one reviewer** (`general-purpose`, model per Parameters)
   using `./reviewer-prompt.md` with round `i`'s lens. Fill ONLY the
   template placeholders: round number, model, repo root (the root
   anchor), package path, BASE/HEAD
   SHAs, lens name + the lens's full instruction text from Lens Rotation
   below (verbatim), the plan path on every lens-1 round, and the carried
   Minor-findings list on round 1 only. Never pass the conversation,
   prior rounds' findings, fix reports, or the log.
3. **Validate the report:** first line is `<!-- multi-review report -->`
   and a Verdict block is present. An unusable report → retry the
   identical dispatch once; on second failure log the round
   `inconclusive` (never clean) and continue to the next round.
```

with:

```
2. **Dispatch M reviewers in one message** — M parallel Agent tool calls
   (the convention of `skills/dispatching-parallel-agents/SKILL.md`), each
   `general-purpose`, model per Parameters, filled from
   `./reviewer-prompt.md` with the same placeholder values: round number,
   model, repo root (the root anchor), the **same package path** (the
   package is generated once per round), BASE/HEAD SHAs, round `i`'s lens
   name + the lens's full instruction text from Lens Rotation below
   (verbatim), the plan path on every lens-1 round, and the carried
   Minor-findings list on round 1 only. Fill ONLY the template
   placeholders. Never pass the conversation, prior rounds' findings, fix
   reports, or the log. Reviewer `j` of the round is written `r<j>`. The
   reviewers are not told that other reviewers exist: only the Agent
   call's `description` differs, and only when M ≥ 2 (the
   `(reviewer <j>/<m>)` suffix shown in the template). A platform that
   runs the calls one after another gives the same result, only slower.
3. **Validate each report and consolidate:** a report is usable when its
   first line is `<!-- multi-review report -->` and a Verdict block is
   present. Each unusable report → retry the identical dispatch once,
   keeping the same reviewer number; the retries of one round may go out
   together in one message. After the retries, *u* = the number of usable
   reports. u = 0 → log the round `inconclusive` (never clean; nothing is
   triaged) and continue to the next round. u ≥ 1 → build one
   **consolidated finding set** from the usable reports by the rules
   below, then continue; a round with u < M is *partial* — it is logged
   with its counts and is never clean. With M = 1 the consolidated set is
   the report's enumeration with its original ids, unchanged.
   1. Enumeration is the source of truth: findings come from each report's
      enumerated findings, never from its count line.
   2. Union: every enumerated finding of every usable report appears in
      the set, on its own or inside a consolidated finding. Nothing is
      dropped at this step.
   3. Same-issue rule: two findings are the same issue when they point at
      the same place **and** describe the same defect — one single change
      would resolve both. "Same place" means the same file with line
      ranges that share at least one line (a single `file:line` reference
      is a range of that one line), or the same named symbol. Different
      defects at the same place stay separate. When in doubt, keep them
      separate: a duplicate costs one `rejected: duplicate of [..]`
      disposition at triage; a wrongly merged pair loses a finding.
   4. Severity: a consolidated finding takes the highest severity any of
      its sources gave it.
   5. Text: keep the most specific description among the sources; details
      from several sources may be combined, but no claim that no source
      made may be added.
   6. Ids: whenever M ≥ 2 — a partial round with a single usable report
      included — consolidated findings get fresh ids per severity class,
      `C1…`, `I1…`, `M1…`, ordered by agreement count (the number of
      distinct reviewers that reported the finding, highest first), then
      by the lowest reviewer number among the sources, then by that
      reviewer's own id order. Reviewer-local ids appear only as source
      ids in the log — `r<j>:<id>`, for example `r1:I2`.
   7. Traceability: every source id maps to exactly one consolidated
      finding. Count the enumerated findings across the usable reports
      (*k*) and the source ids you mapped; the two numbers must be equal
      before the round entry is written. On a mismatch repair the
      consolidation, never the count.
   8. Malformed ids: a usable report may carry missing or duplicated ids,
      or a finding under a severity heading that does not match its id
      prefix. Before consolidation renumber that report's findings by
      position within each severity heading (`C1…`, `I1…`, `M1…` in order
      of appearance; the heading decides the severity) and note
      `ids renumbered` on that reviewer's entry of the
      `**Reviewer verdicts:**` line. This rule applies to M ≥ 2 only: with
      M = 1 the report keeps its original ids (today's behavior, unchanged)
      — there is no `**Reviewer verdicts:**` line to carry the note, and the
      M = 1 entry stays byte-identical to earlier releases.
   The Carried Findings Triage lines of round-1 reports are
   recommendations, not enumerated findings: they stay outside the
   consolidated set and outside *k* (see Triage).
```

- [ ] **Step 5: Procedure — fix subagent input and carried findings from M recommendations**

Replace:

```
   - **Critical/Important:** dispatch ONE fix subagent per round with the
     complete list (never one fixer per finding). The fix subagent:
```

with:

```
   - **Critical/Important:** dispatch ONE fix subagent per round with the
     complete consolidated list — id, severity, location, description; no
     source ids and no agreement counts (never one fixer per finding). The
     fix subagent:
```

Replace:

```
   - **Carried findings (round 1):** the reviewer's Carried Findings
     Triage lines are recommendations — decide each yourself:
     fix-before-merge → include it in this round's fix dispatch
     (`fixed — <summary> → <sha>`); ship-as-is → `carried`; user-decision →
     `user-decision`. Log each under the round's dispositions.
```

with:

```
   - **Carried findings (round 1):** every round-1 reviewer returns one
     recommendation per carried item (`fix-before-merge` | `ship-as-is` |
     `user-decision`). Decide each item yourself from the recommendations
     present in the usable reports; when they disagree take the most
     cautious one — `user-decision` if any reviewer recommends it (the
     disagreement itself is information for the human), else
     `fix-before-merge` if any reviewer recommends it, else `ship-as-is`;
     when no recommendation is present for an item (every reviewer
     omitted it, or the only reviewer that addressed it was unusable),
     decide alone. fix-before-merge → include it in this round's fix
     dispatch (`fixed — <summary> → <sha>`); ship-as-is → `carried`;
     user-decision → `user-decision`. Log each under the round's
     dispositions, without a source annotation.
```

- [ ] **Step 6: Procedure — convergence and verification re-reviews**

Replace:

```
6. **Convergence check:** a round is *clean* when its **enumerated
   findings** contain zero Critical and zero Important (never the count
   line; never post-triage — rejections and user-decision findings never
   make a round clean). When the report's count line disagrees with its
   enumerated findings, recompute the counts from the enumeration and log
   the recomputed counts on the round's verdict line. Exit early only after **two consecutive clean
   rounds**; `inconclusive` breaks the streak. With N ≤ 2 no mid-loop
   exit, but still report "converged" if the final two rounds were clean;
   N = 1 always reports "cap reached".
```

with:

```
6. **Convergence check:** a round is *clean* when the **consolidated set**
   enumerates zero Critical and zero Important (never the count lines;
   never post-triage — rejections and user-decision findings never make a
   round clean) **and** all M reviewers returned a usable report (u = M).
   A partial round is never clean and breaks the streak, like an
   `inconclusive` round. When a report's count line disagrees with its
   enumerated findings, recompute the counts from the enumeration: with
   M = 1 log the recomputed counts on the round's verdict line; with M ≥ 2
   the per-reviewer counts already come from the enumeration, and the
   disagreement is recorded as `, counts recomputed` on that reviewer's
   entry of the `**Reviewer verdicts:**` line. Exit early only after **two
   consecutive clean rounds**; `inconclusive` breaks the streak. With
   N ≤ 2 no mid-loop exit, but still report "converged" if the final two
   rounds were clean; N = 1 always reports "cap reached". Because the
   union keeps every reviewer's findings, two consecutive clean rounds are
   harder to reach with M > 1 — that is the intended effect.
```

Replace:

```
   1-based cycle index within that round's verification (`1`, `2`, `3`) —
   same fields as a round, no Converged line; never counts toward
```

with:

```
   1-based cycle index within that round's verification (`1`, `2`, `3`) —
   same fields as a round, the same M, the same consolidation and the same
   M ≥ 2 log lines, no Converged line; never counts toward
```

Replace:

```
   restarting the count); findings still standing
   become `unresolved: verification cap` items (blocking).
```

with:

```
   restarting the count); findings still standing
   become `unresolved: verification cap` items (blocking).

   A partial verification cycle (1 ≤ u < M) counts as a cycle, and its
   usable reports' findings are triaged normally. A partial round or cycle
   satisfies "a later round with a usable report ran on the updated
   branch": the fixes it examined count as reviewed. A partial
   verification cycle after which no unreviewed fix remains (an empty
   consolidated set included) ends the verification of its originating
   round. "Never clean" concerns only the
   convergence streak; it never reopens a verification — so a cap exit
   after a partial round ships no unreviewed fix, and three partial
   cycles with empty consolidated sets end with nothing standing and
   nothing `unresolved`.
```

- [ ] **Step 7: Review Log Format**

Replace:

````
```
_Invocation <k> — YYYY-MM-DD — N=<n> — BASE..HEAD <base7>..<head7> — branch <raw-name> — <invoker>_

## Round <i> — <lens name> — <model>
**Reviewer verdict:** <n> Critical, <n> Important, <n> Minor
**Converged:** yes/no   <!-- "yes" only on the round where the loop exits
                             via convergence; every other round "no" -->
### Dispositions
- [C1] fixed — <finding summary> → <fix commit sha>
- [I1] rejected: <reason> — <finding summary>
- [I2] user-decision — <finding summary> (plan-mandated)
- [M2] carried — <finding summary>

_Completed — YYYY-MM-DD — <converged|cap reached> — HEAD <sha>_
```
````

with:

````
The invocation line records M right after N, **including when M = 1**, so
that a log is self-describing; a line without `M=` (written before 7.4.0)
is read as M = 1. Round entry with M = 1 (byte-identical to earlier
releases):

```
_Invocation <k> — YYYY-MM-DD — N=<n> M=<m> — BASE..HEAD <base7>..<head7> — branch <raw-name> — <invoker>_

## Round <i> — <lens name> — <model>
**Reviewer verdict:** <n> Critical, <n> Important, <n> Minor
**Converged:** yes/no   <!-- "yes" only on the round where the loop exits
                             via convergence; every other round "no" -->
### Dispositions
- [C1] fixed — <finding summary> → <fix commit sha>
- [I1] rejected: <reason> — <finding summary>
- [I2] user-decision — <finding summary> (plan-mandated)
- [M2] carried — <finding summary>

_Completed — YYYY-MM-DD — <converged|cap reached> — HEAD <sha>_
```

Round entry with M ≥ 2 — three lines added after the header, and a source
annotation at the **end** of every finding disposition line
(` ← <a>/<m>: <source ids>`; `<a>` = agreement count, the number of
distinct reviewers that reported the finding; source ids comma-separated
in reviewer order):

```
## Round <i> — <lens name> — <model>
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 1 Important, 0 Minor | r2: 0 Critical, 1 Important, 1 Minor | r3: 0 Critical, 1 Important, 0 Minor
**Sources mapped:** 5/5
**Reviewer verdict:** 1 Critical, 2 Important, 1 Minor
**Converged:** no
### Dispositions
- [C1] fixed — <finding summary> → <fix commit sha> ← 2/3: r1:C1, r3:I1
- [I1] user-decision — <finding summary> (plan-mandated) ← 1/3: r1:I1
- [I2] rejected: <reason> — <finding summary> ← 1/3: r2:I1
- [M1] carried — <finding summary> ← 1/3: r2:M1
```

(In this example r1 and r3 reported the same issue — r1 as Critical,
r3 as Important — so it is one consolidated finding at the highest
severity: the five source ids (k = 5) map to four consolidated findings,
and every source id appears in exactly one annotation. `[I1]` precedes
`[I2]` because both have agreement count 1 and r1 is the lower reviewer
number. `[M1] carried` is a current-round Minor finding and keeps its
annotation — see the rule on carried findings below.)

Rules for the added lines:

- `**Reviewers:**` — M and the usable count *u* of this round. Written when
  M ≥ 2, and also when the effective M of the round is 1 while the
  invocation line records a larger M (a resumed invocation given a new M):
  then it is the only added line — `**Reviewers:** M=1, usable 1/1`, or
  `usable 0/1` for an inconclusive round — with original ids, no source
  annotation, and no `**Reviewer verdicts:**` or `**Sources mapped:**` line.
  An effective M ≥ 2 always writes all three lines and the source
  annotations, whatever M the invocation line records.
- `**Reviewer verdicts:**` — one entry per reviewer in reviewer order, the
  counts taken from each report's enumeration. A usable reviewer with no
  findings is written `r<j>: 0 Critical, 0 Important, 0 Minor`; an unusable
  reviewer `r<j>: unusable`; a reviewer whose ids were renumbered gets the
  suffix `, ids renumbered`, and one whose count line disagreed with its
  enumeration the suffix `, counts recomputed`. A reviewer that needs both
  suffixes gets `, ids renumbered` first, then `, counts recomputed`.
- `**Sources mapped:**` — the traceability check of the Procedure; both
  numbers are *k*. The entry is written only after the check passed, so the
  two numbers are always equal.
- `**Reviewer verdict:**` — keeps its name and position; with M ≥ 2 it
  carries the **consolidated** counts.
- Every disposition line keeps its existing prefix (`- [I1] fixed — …`), so
  patterns anchored at the start of the line still match. The `fixed`
  disposition keeps its single shape, which becomes
  `fixed — <summary> → <sha>[ ← <a>/<m>: <ids>]`; every reader of `<sha>`
  takes the token immediately after `→ ` (before ` ← ` when an annotation
  is present). Two kinds of disposition line carry no annotation:
  post-loop addendum lines (`decided (user): …`, addendum `fixed …`), and
  the round-1 lines written for the **Carried findings (round 1)** items
  of the Triage step — findings carried from an earlier invocation's ledger, which
  are decided from the reviewers' recommendations and never enter the
  consolidated set. A finding's annotation lives on its original
  disposition line. This exception is about the item's origin, not about
  the disposition word: a current-round finding whose disposition is
  `carried` (the `[M1] carried` line in the example) is an ordinary
  consolidated finding and keeps its annotation.
- The clean-round line `- none — no material issues under this lens` is
  written without annotation and only when the consolidated set is empty
  **and** u = M. A partial round with an empty consolidated set writes
  `- none — no material issues under this lens (partial round, usable <u>/<m>)`.
- An `inconclusive` round (u = 0) with M ≥ 2 writes
  `**Reviewers:** M=<m>, usable 0/<m>`,
  `**Reviewer verdicts:** r1: unusable | r2: unusable | …`, no
  `**Sources mapped:**` line, then `**Reviewer verdict:** inconclusive` and
  `- inconclusive — <reason>`.
- A `skipped` entry is unchanged apart from its invocation fields, which
  carry `M=` like every other. The `_Completed — …` line is unchanged.
````

- [ ] **Step 8: After the Loop — `<sha>` reader**

Replace:

```
commit already exists is not dispatched again — found in `git log` by the
`<sha>` the `fixed` line records or, when none was recorded, by the fix
```

with:

```
commit already exists is not dispatched again — found in `git log` by the
`<sha>` the `fixed` line records (the token immediately after `→ `, before
any ` ← ` source annotation) or, when none was recorded, by the fix
```

- [ ] **Step 9: Error Handling**

Replace:

```
- Invalid N → 3. N = 0 → skip, log.
```

with:

```
- Invalid N → 3. N = 0 → skip, log.
- M stated but invalid (0, 6, `two`, `2.5`) → the default of the Parameters
  resolution (tag, else 1); never ask; note the substitution in the
  completion message. Session tag absent or invalid → 1 (silent fallback).
- One or more reviewers unusable after one retry, u ≥ 1 → partial round:
  consolidate the usable reports, log `usable <u>/<m>` and `r<j>: unusable`,
  triage normally; the round is never clean.
- All reviewers unusable after retries (u = 0) → `inconclusive` round.
- Sources-mapped mismatch (source ids mapped ≠ findings enumerated) →
  repair the consolidation before writing the entry; never write the line
  with unequal numbers.
- Reviewer report with missing or duplicated ids → renumber by position per
  severity heading, note `ids renumbered` (M ≥ 2 only; with M = 1 the report
  keeps its original ids, as today).
- M recommendations for a carried finding disagree → most cautious wins:
  `user-decision`, else `fix-before-merge`, else `ship-as-is`.
- Review-log invocation line without `M=` → read as M = 1; the M of this
  invocation always comes from its parameters, never from the log.
- Platform without parallel dispatch → reviewers run one after another;
  the procedure is unchanged.
```

- [ ] **Step 10: Reviewer template header and `description` suffix**

In `skills/multi-code-review/reviewer-prompt.md`, replace:

```
Use this template when dispatching a multi-code-review reviewer subagent.
One reviewer per round; the lens comes from SKILL.md's Lens Rotation.
```

with:

```
Use this template when dispatching a multi-code-review reviewer subagent.
M reviewers per round (default 1), all with this identical prompt; the
lens comes from SKILL.md's Lens Rotation. The reviewers are not told that
other reviewers exist.
```

and replace:

```
  description: "multi-code-review round [ROUND]: [LENS_NAME]"
```

with:

```
  description: "multi-code-review round [ROUND]: [LENS_NAME]"
               (when M ≥ 2 append " (reviewer <j>/<m>)" — reviewer j of m;
               the description is not part of the prompt)
```

- [ ] **Step 11: Verify**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -5`
Expected: the summary reports 0 failures (every text-drift assertion against `multi-code-review/SKILL.md` still passes).

Run: `grep -n 'Dispatch one reviewer\|One reviewer per round\|N=<n> — BASE..HEAD' skills/multi-code-review/SKILL.md skills/multi-code-review/reviewer-prompt.md`
Expected: no output.

Run: `grep -c 'M=<m>' skills/multi-code-review/SKILL.md`
Expected: a number ≥ 4.

Run: `grep -n 'the token immediately after' skills/multi-code-review/SKILL.md`
Expected: two matching lines (Review Log Format rule and After the Loop).

- [ ] **Step 12: Commit**

```bash
git add skills/multi-code-review/SKILL.md skills/multi-code-review/reviewer-prompt.md
git commit -m "feat(multi-code-review): M reviewers per lens with report consolidation" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 3/8"
```

---

### Task 4: `orchestrating-development` — Phase 0 question, log header, `state.md`, resume, `[M]` in both loop templates

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md`
- Modify: `skills/orchestrating-development/doc-review-loop-prompt.md`
- Modify: `skills/orchestrating-development/code-review-loop-prompt.md`

**Security flag:** `none`

**Does NOT cover:** separate M values for Phase 2 and Phase 4 (one M applies to both); a change to the `REVIEW_DONE …` / `BLOCKED:` return lines; recovering M from a review log (the orchestrator reads only its own log); a Phase 0 question for M in SDD (Task 5 — SDD never asks).

- [ ] **Step 1: Phase 0 question batch**

In `skills/orchestrating-development/SKILL.md`, replace:

```
2. **Ask once (single batch):** N_plan (0–10, default 3), N_code (0–10,
   default 3), batch cap (1–5, default 3). Invalid → default. N=0 means
```

with:

```
2. **Ask once (single batch):** N_plan (0–10, default 3), N_code (0–10,
   default 3), M — reviewers per lens, the number of identical reviewer
   subagents each review round dispatches in parallel (1–5, default `<d>`,
   where `<d>` is the value of a `<reviewers-per-lens>` tag in the session
   context if present, else 1; one M applies to Phase 2 and Phase 4),
   batch cap (1–5, default 3). Invalid → default. N=0 means
```

- [ ] **Step 2: Phase 2 and Phase 4 template fill lists**

Replace:

```
`./doc-review-loop-prompt.md` (plan path, spec path, N_plan) and dispatch.
```

with:

```
`./doc-review-loop-prompt.md` (plan path, spec path, N_plan, M) and dispatch.
```

Replace:

```
stop. Fill `./code-review-loop-prompt.md` (BASE = the Phase 0
recorded branch point, N_code, plan path, ledger path
```

with:

```
stop. Fill `./code-review-loop-prompt.md` (BASE = the Phase 0
recorded branch point, N_code, M, plan path, ledger path
```

- [ ] **Step 3: Orchestration log header**

Replace:

```
_Invocation 1 — YYYY-MM-DD — spec docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md — N_plan=<n> N_code=<n> cap=<n> — branch feature/<slug> — BASE <sha7>_
```

with:

```
_Invocation 1 — YYYY-MM-DD — spec docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md — N_plan=<n> N_code=<n> M=<m> cap=<n> — branch feature/<slug> — BASE <sha7>_
```

- [ ] **Step 4: `state.md` Params line**

Replace:

```
Params: N_plan=<n> N_code=<n> cap=<n>  Branch: feature/<slug>  BASE: <sha7>
```

with:

```
Params: N_plan=<n> N_code=<n> M=<m> cap=<n>  Branch: feature/<slug>  BASE: <sha7>
```

- [ ] **Step 5: Resume step 5 — the one defaulted parameter**

Replace:

```
   taken from the most recent earlier line that records it — never
   defaulted (defaulting would silently discard the user's Phase 0
   choices). This is the designed escape from a parameter-caused stop.
```

with:

```
   taken from the most recent earlier line that records it — never
   defaulted (defaulting would silently discard the user's Phase 0
   choices). This is the designed escape from a parameter-caused stop.
   One explicit exception: a log written before 7.4.0 records `M=` on no
   line at all, so there is nothing to recover — M is 1 for such a log.
   `... with M=2` overrides M like any other parameter; the controller
   dispatched after it carries the new value in its `[M]` placeholder, and
   that value governs the review log it continues (the review log's own
   invocation line is never rewritten).
```

- [ ] **Step 6: `doc-review-loop-prompt.md` — parameter line and placeholder**

In `skills/orchestrating-development/doc-review-loop-prompt.md`, replace:

```
    - N (round cap): [N_PLAN]
```

with:

```
    - N (round cap): [N_PLAN]
    - M (reviewers per lens): [M]   (fill the review log's invocation
      line from it; never read M from the session or the log)
```

and replace:

```
- `[N_PLAN]` — REQUIRED: integer 1–10
```

with:

```
- `[N_PLAN]` — REQUIRED: integer 1–10
- `[M]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
  controller passes it to multi-doc-review as its M
```

- [ ] **Step 7: `code-review-loop-prompt.md` — parameter line, placeholder, `<sha>` reader**

In `skills/orchestrating-development/code-review-loop-prompt.md`, replace:

```
    - N (round cap): [N_CODE]
```

with:

```
    - N (round cap): [N_CODE]
    - M (reviewers per lens): [M]   (fill the review log's invocation
      line from it; never read M from the session or the log)
```

Replace:

```
- `[N_CODE]` — REQUIRED: integer 1–10
```

with:

```
- `[N_CODE]` — REQUIRED: integer 1–10
- `[M]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
  controller passes it to multi-code-review as its M
```

Replace:

```
       commit already exists — first search `git log` for the `<sha>` the
       addendum's `fixed` line records; when it recorded none, search for
```

with:

```
       commit already exists — first search `git log` for the `<sha>` the
       addendum's `fixed` line records (the token immediately after `→ `,
       before any ` ← ` source annotation); when it recorded none, search for
```

Checked, no change needed (spec section 6.1 consumer list): the template's
two other `_Invocation` mentions — Deviation 5's "LATEST `_Invocation` entry
in the review log" and "the new entry's `_Invocation` line is written and
committed together" — identify an entry by its line prefix and position,
never by its `N=` / `M=` fields.

- [ ] **Step 8: Verify**

Run: `grep -n 'M=<m>' skills/orchestrating-development/SKILL.md`
Expected: two lines — the log header and the `Params:` line.

Run: `grep -c '\[M\]' skills/orchestrating-development/doc-review-loop-prompt.md skills/orchestrating-development/code-review-loop-prompt.md skills/orchestrating-development/SKILL.md`
Expected: three lines, each prefixed with the path exactly as given on the command line: `skills/orchestrating-development/doc-review-loop-prompt.md:2`, `skills/orchestrating-development/code-review-loop-prompt.md:2`, `skills/orchestrating-development/SKILL.md:1`.

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -3`
Expected: 0 failures (the `code-review-loop-prompt.md` drift assertion at line 756 still passes).

- [ ] **Step 9: Commit**

```bash
git add skills/orchestrating-development/SKILL.md skills/orchestrating-development/doc-review-loop-prompt.md skills/orchestrating-development/code-review-loop-prompt.md
git commit -m "feat(orchestrating-development): ask and pass M (reviewers per lens) to both review loops" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 4/8"
```

---

### Task 5: `subagent-driven-development` — final gate resolution and batched-mode handoff

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** asking the user for M at the final gate or in a batch (never); writing `M=<m>` into the resume prompt when the user did not state M (then nothing is written and the resolution runs again after every resume, so a changed environment variable takes effect at the next batch started after a CLI restart).

- [ ] **Step 1: Final whole-branch gate**

In `skills/subagent-driven-development/SKILL.md`, replace:

```
   completion message. Ask the user for N unless a count was
   already stated (default 3; N=0 skips on explicit user choice). The
```

with:

```
   completion message. Ask the user for N unless a count was
   already stated (default 3; N=0 skips on explicit user choice). Never
   ask for M (reviewers per lens — the number of identical reviewer
   subagents each review round dispatches in parallel): pass the value
   the user stated, else the value of the `<reviewers-per-lens>` session
   tag, else 1 — multi-code-review's own default resolution. The
```

- [ ] **Step 2: Batched Autonomous Mode handoff**

Replace:

```
> Batch complete (N tasks). Context at P%. To continue: run `/clear`, then paste:
> "Resume the plan at <plan-path> (batched autonomous mode)"
```

with:

```
> Batch complete (N tasks). Context at P%. To continue: run `/clear`, then paste:
> "Resume the plan at <plan-path> (batched autonomous mode)"

When the user stated M (reviewers per lens for the final review loop) when
the batch run started, the paste prompt carries it so that the stated value
survives `/clear`: `"Resume the plan at <plan-path> (batched autonomous
mode, M=<m>)"`. Otherwise write nothing about M — multi-code-review's
default resolution (session tag, else 1) runs again after every resume.
```

Replace:

```
`finishing-a-development-branch` as in the Core Flow. The loop runs
autonomously: never ask for N (default 3, or a count the user stated when
starting the batch); plan-mandated/user-decision findings are journaled
under `## Open Issues` and end the batch.
```

with:

```
`finishing-a-development-branch` as in the Core Flow. The loop runs
autonomously: never ask for N (default 3, or a count the user stated when
starting the batch) and never ask for M (the value the user stated when
starting the batch or carried by the resume prompt's `M=<m>`, else the
`<reviewers-per-lens>` session tag, else 1); plan-mandated/user-decision
findings are journaled under `## Open Issues` and end the batch.
```

- [ ] **Step 3: Verify**

Run: `grep -c 'reviewers per lens' skills/subagent-driven-development/SKILL.md`
Expected: `2`.

Run: `grep -n 'batched autonomous' skills/subagent-driven-development/SKILL.md`
Expected: three lines — the existing announce line (`I'm using subagent-driven-development (batched autonomous mode).`), the original paste-prompt line, and the new paste-prompt line, which ends in `(batched autonomous` (its continuation `mode, M=<m>)"` sits on the next line and is not matched by this grep).

- [ ] **Step 4: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat(subagent-driven-development): resolve M for the final review gate and carry a stated M across /clear" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 5/8"
```

---

### Task 6: Behavioral tests — M=2 case in both review tests

**Files:**
- Modify: `tests/claude-code/test-helpers.sh`
- Modify: `tests/claude-code/test-multi-doc-review.sh`
- Modify: `tests/claude-code/test-multi-code-review.sh`

**Security flag:** `none`

**Depends on:** Tasks 1–5 committed on the working branch — Step 6 installs the branch's skill text, and the Parallel Waves grouping of subagent-driven-development (file overlap only) would otherwise put this task, whose files overlap no other task, in the first wave. Task 8 must not have started: it changes `VERSION`, which Step 6 uses to find the cache directory.

**Does NOT cover:** Case 2 of `test-multi-code-review.sh` (pipeline mode stays at M = 1 so its `p5-control` package count keeps its meaning); a test of a partial or inconclusive round (the `[1-m]` tolerance in the usable count only prevents a rare retry failure from failing the test); running these tests without the plugin reinstalled (CLAUDE.md constraint).

- [ ] **Step 1: Shared assertion helper**

Append to the end of `tests/claude-code/test-helpers.sh`:

```bash

# assert_round_reviewers <log> <round> <m>
# Checks the reviewers-per-lens lines of one round entry — the lines from
# '^## Round <round> — ' up to the next '^## Round ' or the end of the file.
# The en dash after the round number matches the round header only: a
# '## Round <round> verification <c> — …' header does not match it, so a
# verification-cycle entry ends the extraction instead of being appended.
#   - '**Reviewers:** M=<m>, usable <u>/<m>' with 1 <= u <= m (one unusable
#     reviewer is tolerated, so a rare retry failure does not fail the test)
#   - '**Sources mapped:** k/k' with equal numbers
#   - the counts on the '**Reviewer verdicts:**' line sum to k (the line is
#     not trusted: the sum is recomputed here)
#   - the distinct 'r<j>:<id>' tokens across the source annotations equal k
#   - at least one disposition line ends in ' ← <a>/<m>: <source ids>'
#     (skipped with a 'note:' line when Sources mapped is 0/0: a round whose
#     reviewers all report nothing writes no annotation, and that is correct
#     skill behavior — rerun the test if the seeded findings were expected)
# Prints one FAIL(m) line per failed check; returns the number of failed checks.
assert_round_reviewers() {
    local log="$1" round="$2" m="$3"
    local failures=0
    local entry
    entry=$(awk -v r="$round" '
        $0 ~ "^## Round " r " — " { on = 1; print; next }
        /^## Round / { if (on) exit }
        on { print }' "$log")

    local usable_re="^\\*\\*Reviewers:\\*\\* M=${m}, usable [1-${m}]/${m}\$"
    if ! printf '%s\n' "$entry" | grep -qE "$usable_re"; then
        echo "FAIL(m): round $round has no '**Reviewers:** M=$m, usable <u>/$m' line"
        failures=$((failures+1))
    fi

    local sources_line k_mapped k_total
    sources_line=$(printf '%s\n' "$entry" | grep -E '^\*\*Sources mapped:\*\* [0-9]+/[0-9]+$' | head -1 || true)
    k_mapped=$(printf '%s' "$sources_line" | sed -nE 's/.* ([0-9]+)\/[0-9]+$/\1/p')
    k_total=$(printf '%s' "$sources_line" | sed -nE 's/.* [0-9]+\/([0-9]+)$/\1/p')
    if [ -z "$sources_line" ] || [ "$k_mapped" != "$k_total" ]; then
        echo "FAIL(m): round $round has no '**Sources mapped:** k/k' line with equal numbers"
        failures=$((failures+1))
    fi

    local verdict_sum
    verdict_sum=$(printf '%s\n' "$entry" | grep -E '^\*\*Reviewer verdicts:\*\*' \
        | grep -oE '[0-9]+ (Critical|Important|Minor)' | awk '{ s += $1 } END { print s + 0 }' || true)
    if [ "$verdict_sum" != "${k_total:-none}" ]; then
        echo "FAIL(m): round $round: Reviewer verdicts counts sum to $verdict_sum, Sources mapped says ${k_total:-none}"
        failures=$((failures+1))
    fi

    local annotation_re=" ← [1-${m}]/${m}: r[1-${m}]:[CIM][0-9]+(, r[1-${m}]:[CIM][0-9]+)*\$"
    local distinct_sources
    distinct_sources=$(printf '%s\n' "$entry" | grep -oE "$annotation_re" \
        | grep -oE "r[1-${m}]:[CIM][0-9]+" | sort -u | wc -l | tr -d ' ' || true)
    if [ "$distinct_sources" != "${k_total:-none}" ]; then
        echo "FAIL(m): round $round: $distinct_sources distinct source ids in annotations, Sources mapped says ${k_total:-none}"
        failures=$((failures+1))
    fi

    if [ "${k_total:-0}" = "0" ]; then
        echo "note: round $round: Sources mapped is 0/0 (empty consolidated set); annotation check skipped — rerun if findings were expected"
    elif ! printf '%s\n' "$entry" | grep -qE "$annotation_re"; then
        echo "FAIL(m): round $round: no disposition line ends in a ' ← <a>/$m: <source ids>' annotation"
        failures=$((failures+1))
    fi

    return "$failures"
}
```

- [ ] **Step 2: Fast check of the helper against a fixture (not committed)**

Run this once from the repository root:

```bash
FIX=$(mktemp)
cat > "$FIX" <<'EOF'
_Invocation 1 — 2026-08-27 — N=2 M=2 — direct_

## Round 1 — Correctness & completeness — opus
**Reviewers:** M=2, usable 2/2
**Reviewer verdicts:** r1: 1 Critical, 1 Important, 0 Minor | r2: 1 Critical, 0 Important, 1 Minor
**Sources mapped:** 4/4
**Reviewer verdict:** 1 Critical, 1 Important, 1 Minor
**Converged:** no

### Dispositions
- [C1] applied — §2: contradiction → removed the second sentence ← 2/2: r1:C1, r2:C1
- [I1] rejected: out of scope — retry count ← 1/2: r1:I1
- [M1] deferred — wording ← 1/2: r2:M1

## Round 2 — Ambiguity & testability — opus
**Reviewer verdict:** 0 Critical, 0 Important, 0 Minor
EOF
bash -c 'source tests/claude-code/test-helpers.sh; assert_round_reviewers "$1" 1 2; echo "exit=$?"' _ "$FIX"
sed -i.bak 's/Sources mapped:\*\* 4\/4/Sources mapped:** 3\/3/' "$FIX"
bash -c 'source tests/claude-code/test-helpers.sh; assert_round_reviewers "$1" 1 2; echo "exit=$?"' _ "$FIX"
rm -f "$FIX" "$FIX.bak"
```

Expected: first run prints only `exit=0`; second run prints two `FAIL(m)` lines (verdict sum 4 vs 3; distinct sources 4 vs 3) and `exit=2`.

- [ ] **Step 3: `test-multi-doc-review.sh` — prompt and assertions**

Replace:

```bash
# Seeds a deliberately flawed spec, invokes the skill headlessly with N=2,
```

with:

```bash
# Seeds a deliberately flawed spec, invokes the skill headlessly with N=2 and M=2,
```

Replace:

```bash
#   (c) log has a disposition line or an explicit no-findings verdict
```

with:

```bash
#   (c) log has a disposition line or an explicit no-findings verdict
#   (m) round 1 carries the M=2 lines (Reviewers, Reviewer verdicts, Sources
#       mapped) and source annotations that agree with each other
```

Replace:

```bash
PROMPT="Invoke the superpowers-orchestrator:multi-doc-review skill on the document $SPEC with N=2. Do not ask me any questions — use N=2 and proceed to completion."
```

with:

```bash
PROMPT="Invoke the superpowers-orchestrator:multi-doc-review skill on the document $SPEC with N=2 and M=2. Do not ask me any questions — use N=2 and M=2 and proceed to completion."
```

Replace:

```bash
    if ! grep -qiE "applied|rejected:|deferred|no material issues|skipped|inconclusive" "$LOG"; then
        echo "FAIL(c): log has no disposition line and no no-findings verdict"
        FAILURES=$((FAILURES+1))
    fi
fi
```

with:

```bash
    if ! grep -qiE "applied|rejected:|deferred|no material issues|skipped|inconclusive" "$LOG"; then
        echo "FAIL(c): log has no disposition line and no no-findings verdict"
        FAILURES=$((FAILURES+1))
    fi
    # (m) M=2: the round-1 entry carries the reviewers-per-lens lines and
    #     source annotations, and they agree with each other
    assert_round_reviewers "$LOG" 1 2 || FAILURES=$((FAILURES+$?))
fi
```

- [ ] **Step 4: `test-multi-code-review.sh` — Case 1 prompt and assertions**

Replace:

```bash
PROMPT="Invoke the superpowers-orchestrator:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-under-review) with BASE $BASE_SHA and N=2. Do not ask me any questions — use N=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."
```

with:

```bash
PROMPT="Invoke the superpowers-orchestrator:multi-code-review skill on the git repository at $TEST_PROJECT (review its current branch feature-under-review) with BASE $BASE_SHA, N=2 and M=2. Do not ask me any questions — use N=2 and M=2 and proceed to completion, treating any finding that would need my decision as user-decision in the log."
```

Replace:

```bash
    NON_GENERIC=$(git log --format=%s "$SEEDED_HEAD_SHA..HEAD" | grep -vE "^review fixes \(([^,]+, )?round [0-9]+\)$" || true)
    if [ -n "$NON_GENERIC" ]; then
        echo "FAIL(d): fix commit subject(s) not generic:"
        echo "$NON_GENERIC"
        FAILURES=$((FAILURES+1))
    fi
fi
```

with:

```bash
    NON_GENERIC=$(git log --format=%s "$SEEDED_HEAD_SHA..HEAD" | grep -vE "^review fixes \(([^,]+, )?round [0-9]+\)$" || true)
    if [ -n "$NON_GENERIC" ]; then
        echo "FAIL(d): fix commit subject(s) not generic:"
        echo "$NON_GENERIC"
        FAILURES=$((FAILURES+1))
    fi
    # (i) the invocation line records N and M
    if ! grep -q " N=2 M=2 — " "$LOG"; then
        echo "FAIL(i): review log invocation line does not contain ' N=2 M=2 — '"
        FAILURES=$((FAILURES+1))
    fi
    # (m) M=2: the round-1 entry carries the reviewers-per-lens lines and
    #     source annotations, and they agree with each other. Case 1 passes no
    #     carried findings, so every disposition of the round carries one.
    assert_round_reviewers "$LOG" 1 2 || FAILURES=$((FAILURES+$?))
fi
```

(The replaced block occurs once, in Case 1 — its echo says `FAIL(d):`. Case 2 stays at M = 1 and is not edited.)

- [ ] **Step 5: Fast verification**

Run: `bash -n tests/claude-code/test-helpers.sh && bash -n tests/claude-code/test-multi-doc-review.sh && bash -n tests/claude-code/test-multi-code-review.sh && echo SYNTAX_OK`
Expected: `SYNTAX_OK`.

Run: `grep -c 'assert_round_reviewers' tests/claude-code/test-multi-doc-review.sh tests/claude-code/test-multi-code-review.sh`
Expected: `1` for each file.

Run: `grep -n 'N=2, and TOPIC_DIR' tests/claude-code/test-multi-code-review.sh`
Expected: the unchanged Case 2 prompt line (no `M=2` in it).

- [ ] **Step 6: Behavioral verification (slow; after the local plugin is updated to this branch)**

Preconditions: Tasks 1–5 are committed on the current branch and Task 8 has not started (see **Depends on** above). Reinstall/update the local plugin copy first (CLAUDE.md: sessions run the installed copy under `~/.claude/plugins/cache/superpowers-orchestrator/`). Facts this step relies on: the marketplace clone at `~/.claude/plugins/marketplaces/superpowers-orchestrator` tracks `main` only; its `.claude-plugin/marketplace.json` has `"source": "./"`, so the update copies the clone's checked-out working tree; the cache directory is named after the version in `.claude-plugin/plugin.json`, which is still the value of `VERSION` (`7.3.0`) at this task because Task 8 bumps it later. Run everything below from the repository root.

First confirm that the branch itself carries the Task 2 text:

```bash
# BR is feature/reviewers-per-lens under orchestrating-development; another
# executor may be on a differently named branch, so the name is read, not typed.
BR=$(git branch --show-current)
git grep -c 'usable <u>/<m>' "$BR" -- skills/multi-doc-review/SKILL.md
```

Expected: `<BR>:skills/multi-doc-review/SKILL.md:<n>` with n ≥ 1. No output means the Task 2 commit is not on this branch: stop and report "Task 6 Step 6: Tasks 2/3 are not committed on <BR>" — do not continue with the installation.

Then point the clone at the branch (a detached checkout, so a rerun after a failed test does not fail with "refusing to fetch into branch … checked out"), update, and prove that the installed copy carries the new text:

```bash
CLONE=~/.claude/plugins/marketplaces/superpowers-orchestrator
CACHE=~/.claude/plugins/cache/superpowers-orchestrator/superpowers-orchestrator/$(cat VERSION)
git -C "$CLONE" fetch "$(pwd)" "$BR" && git -C "$CLONE" checkout --detach FETCH_HEAD
claude plugin update superpowers-orchestrator -y
grep -c 'usable <u>/<m>' "$CACHE/skills/multi-doc-review/SKILL.md"
```

Expected: the last command prints a number ≥ 1 (the string is part of the log format Task 2 adds to the skill). `0` or `No such file or directory` means the installed copy is stale — one retry only: `rm -rf "$CACHE"`, run the `claude plugin update` command again, and repeat the `grep -c` check. If the count is still not ≥ 1 after that one retry, stop and report "Task 6 Step 6: the plugin update does not install the branch's skills" — do not run the behavioral tests, because a `FAIL(m)` or `FAIL(i)` line from a stale copy says nothing about the code.

Run: `tests/claude-code/run-skill-tests.sh --test test-multi-doc-review.sh --verbose --timeout 1800`
Expected: `PASS: multi-doc-review behavioral test`, no `FAIL(m)` line.

Run: `tests/claude-code/run-skill-tests.sh --test test-multi-code-review.sh --verbose --timeout 1800`
Expected: the single line `PASS: multi-code-review behavioral test` (the test's `finish()` prints one PASS line for both cases together; there are no per-case PASS lines), no `FAIL(i)` and no `FAIL(m)` line.

Restore the environment whether the tests passed or failed: `git -C "$CLONE" checkout main`. The cache directory `$CACHE` still holds the branch's skills after that — a later `claude plugin update` from `main` sees the same version and does not refresh it — so a user who wants the released 7.3.0 copy back must `rm -rf "$CACHE"` and run `claude plugin update superpowers-orchestrator -y` once more with the clone on `main`. After Task 8 is merged, an update installs 7.4.0 into its own directory.

- [ ] **Step 7: Commit**

```bash
git add tests/claude-code/test-helpers.sh tests/claude-code/test-multi-doc-review.sh tests/claude-code/test-multi-code-review.sh
git commit -m "test(claude-code): M=2 case in the multi-doc-review and multi-code-review behavioral tests" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 6/8"
```

---

### Task 7: User documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/guide/README.md`
- Modify: `docs/FORK-IMPROVEMENTS.md`
- Modify: `docs/REVIEW-PROCESS-COMPARISON.md`

**Security flag:** `none`

**Does NOT cover:** the version badge, lineage ranges, release enumeration line, and `RELEASE-NOTES.md` (Task 8); `tests/codex/post-push-validation-checklist.md` (no Codex-facing file changes).

- [ ] **Step 1: `README.md` — feature bullets**

Replace:

```
- **multi-doc-review (v6.9.0)** — N independent clean-context review rounds with rotating lenses on every spec and plan before its approval gate, with a sidecar audit log; automatic at the gates, or direct: `/multi-doc-review docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md 3`. [Details](docs/FORK-IMPROVEMENTS.md#3-multi-doc-review--n-round-independent-document-review-v690)
- **multi-code-review (v6.10.0)** — N independent whole-branch code review rounds with rotating lenses (correctness/spec alignment, adversarial red-team, security, test quality) and fixes applied between rounds, with a sidecar audit log; automatic at subagent-driven-development's final review gate, or direct: `/multi-code-review [BASE] [N]`. [Details](docs/FORK-IMPROVEMENTS.md#4-multi-code-review--n-round-independent-whole-branch-code-review-v6100)
```

with:

```
- **multi-doc-review (v6.9.0)** — N independent clean-context review rounds with rotating lenses on every spec and plan before its approval gate, with a sidecar audit log; since v7.4.0 each round can dispatch M identical reviewers in parallel (`M=<m>`, 1–5, default 1) and consolidates their reports before triage; automatic at the gates, or direct: `/multi-doc-review docs/superpowers-orchestrator/<date>-<slug>/specs/<slug>-design.md 3 M=2`. [Details](docs/FORK-IMPROVEMENTS.md#3-multi-doc-review--n-round-independent-document-review-v690)
- **multi-code-review (v6.10.0)** — N independent whole-branch code review rounds with rotating lenses (correctness/spec alignment, adversarial red-team, security, test quality) and fixes applied between rounds, with a sidecar audit log; since v7.4.0 each round can dispatch M identical reviewers in parallel (`M=<m>`, 1–5, default 1); automatic at subagent-driven-development's final review gate, or direct: `/multi-code-review [BASE] [N] [M=<m>]`. [Details](docs/FORK-IMPROVEMENTS.md#4-multi-code-review--n-round-independent-whole-branch-code-review-v6100)
```

- [ ] **Step 2: `README.md` — Skills Library entries**

Replace:

```
- **multi-doc-review** — N-round independent spec/plan review: one clean-context reviewer per round under rotating lenses, findings merged between rounds, sidecar audit log; automatic at the brainstorming/writing-plans gates or direct via `/multi-doc-review <doc> [N]`
- **multi-code-review** — N-round independent whole-branch code review: one clean-context reviewer per round under rotating lenses, one fix subagent per round, sidecar audit log; automatic at subagent-driven-development's final review gate or direct via `/multi-code-review [BASE] [N]`
```

with:

```
- **multi-doc-review** — N-round independent spec/plan review: M clean-context reviewers per round (default 1) under rotating lenses, reports consolidated per round, findings merged between rounds, sidecar audit log; automatic at the brainstorming/writing-plans gates or direct via `/multi-doc-review <doc> [N] [M=<m>]`
- **multi-code-review** — N-round independent whole-branch code review: M clean-context reviewers per round (default 1) under rotating lenses, reports consolidated per round, one fix subagent per round, sidecar audit log; automatic at subagent-driven-development's final review gate or direct via `/multi-code-review [BASE] [N] [M=<m>]`
```

- [ ] **Step 3: `README.md` — environment variables note**

Replace:

```
### Hooks (10 total)
```

with:

```
### Environment variables

Set these in `settings.json`'s `env` block so they survive plugin updates; a changed value takes effect after the CLI is restarted.

- `SUPERPOWERS_REVIEWERS_PER_LENS` — M, reviewers per lens: how many identical reviewer subagents each `multi-doc-review` / `multi-code-review` round dispatches in parallel (integer 1–5, default 1). Example: `{ "env": { "SUPERPOWERS_REVIEWERS_PER_LENS": "3" } }`. An `M=<m>` stated in an invocation, or answered in orchestration's Phase 0, wins over it. An invalid value silently falls back to 1.
- `SUPERPOWERS_PRESSURE_THRESHOLD` — the context-pressure gate's block threshold (a percentage, 10–90, default 60); see **skill-activator** below.
- `SUPERPOWERS_AUTO_UPDATE` — `0` disables the startup update check; see **Auto-update** below.

### Hooks (10 total)
```

- [ ] **Step 4: `docs/guide/README.md` — stage descriptions**

Replace:

```
and the design itself. The spec then passes a self-review and — for
non-trivial work — N independent `multi-doc-review` rounds before reaching
you.
```

with:

```
and the design itself. The spec then passes a self-review and — for
non-trivial work — N independent `multi-doc-review` rounds before reaching
you. Each round dispatches M identical reviewers in parallel (M = reviewers
per lens, default 1; see the `SUPERPOWERS_REVIEWERS_PER_LENS` setting in
§7) and consolidates their reports before findings are triaged.
```

Replace:

```
is built in: test-writing steps precede implementation steps. The plan gets its own `multi-doc-review`
gate before you approve it.
```

with:

```
is built in: test-writing steps precede implementation steps. The plan gets its own `multi-doc-review`
gate (same M reviewers per round) before you approve it.
```

Replace:

```
When the last task completes, `multi-code-review` runs N independent
whole-branch review rounds (rotating lenses: correctness, red-team, security,
test quality), with Critical/Important findings fixed between rounds and an
early exit after two consecutive clean rounds. Throughout, any "done" claim
```

with:

```
When the last task completes, `multi-code-review` runs N independent
whole-branch review rounds (rotating lenses: correctness, red-team, security,
test quality), each round dispatching M identical reviewers in parallel
(default 1) whose reports are consolidated before triage, with
Critical/Important findings fixed between rounds and an early exit after two
consecutive clean rounds — with M > 1 a round is clean only when every
reviewer returned a usable report. Throughout, any "done" claim
```

- [ ] **Step 5: `docs/guide/README.md` — Phase 0 table, log sample, settings, cheat-sheet**

Replace:

```
| Batch cap — tasks per implementation batch | 1–5 | 3 |
```

with:

```
| `M` — reviewers per lens: identical reviewers dispatched in parallel per review round, for both loops | 1–5 | 1, or the value of `SUPERPOWERS_REVIEWERS_PER_LENS` |
| Batch cap — tasks per implementation batch | 1–5 | 3 |
```

Replace:

```
_Invocation 1 — 2026-08-08 — spec docs/superpowers-orchestrator/2026-08-04-my-feature/specs/my-feature-design.md — N_plan=3 N_code=3 cap=3 — branch feature/my-feature — BASE a1b2c3d_
```

with:

```
_Invocation 1 — 2026-08-08 — spec docs/superpowers-orchestrator/2026-08-04-my-feature/specs/my-feature-design.md — N_plan=3 N_code=3 M=1 cap=3 — branch feature/my-feature — BASE a1b2c3d_
```

Replace:

````
```json
{ "env": { "SUPERPOWERS_PRESSURE_THRESHOLD": "50" } }
```
````

with:

````
```json
{ "env": { "SUPERPOWERS_PRESSURE_THRESHOLD": "50" } }
```

The number of reviewers per lens — M, the identical reviewer subagents each
`multi-doc-review` / `multi-code-review` round dispatches in parallel — is set
the same way (an integer 1–5, default 1; restart the CLI after changing it;
an invalid value silently falls back to 1):

```json
{ "env": { "SUPERPOWERS_REVIEWERS_PER_LENS": "3" } }
```
````

Replace:

```
| `/multi-doc-review <doc> [N]` | N independent review rounds on a spec or plan | §3 |
| `/multi-code-review [BASE] [N]` | N whole-branch code-review rounds with fixes | §3 |
```

with:

```
| `/multi-doc-review <doc> [N] [M=<m>]` | N independent review rounds on a spec or plan, M reviewers per round | §3 |
| `/multi-code-review [BASE] [N] [M=<m>]` | N whole-branch code-review rounds with fixes, M reviewers per round | §3 |
```

- [ ] **Step 6: `docs/FORK-IMPROVEMENTS.md` — §3 and §4**

Replace:

```
- Each round dispatches **one clean-context reviewer subagent** that has never seen the authoring conversation, the design rationale, or prior rounds' findings — under a **rotating lens**: correctness & completeness → ambiguity & testability → feasibility & architecture risk → adversarial failure modes.
```

with:

```
- Each round dispatches **M clean-context reviewer subagents** (M = reviewers per lens, 1–5, default 1, since v7.4.0; identical prompts, run in parallel, reports consolidated before triage), none of which has ever seen the authoring conversation, the design rationale, or prior rounds' findings — under a **rotating lens**: correctness & completeness → ambiguity & testability → feasibility & architecture risk → adversarial failure modes.
```

Replace:

```
`skills/multi-doc-review/` (`SKILL.md` controller + `reviewer-prompt.md` dispatch template), gate steps in `skills/brainstorming/SKILL.md` and `skills/writing-plans/SKILL.md`, `hooks/skill-rules.json` routing entry, `hooks/subagent-guard.js` marker exemption, `tests/claude-code/test-multi-doc-review.sh`.
```

with:

```
`skills/multi-doc-review/` (`SKILL.md` controller + `reviewer-prompt.md` dispatch template), gate steps in `skills/brainstorming/SKILL.md` and `skills/writing-plans/SKILL.md`, `hooks/skill-rules.json` routing entry, `hooks/subagent-guard.js` marker exemption, `hooks/session-start` (the `<reviewers-per-lens>` session tag, v7.4.0), `tests/claude-code/test-multi-doc-review.sh`, `tests/codex/test-session-start-reviewers-tag.sh`.
```

Replace:

```
- Each round dispatches **one clean-context reviewer subagent** under a **rotating lens**: correctness & spec alignment → adversarial red-team → security → test & coverage quality. Every lens carries a **prose adaptation** — for files that are instructions to an agent (skills, prompts, configs) rather than executable code, runtime-input attacks are vacuous, so the reviewer attacks *agent misexecution* instead.
```

with:

```
- Each round dispatches **M clean-context reviewer subagents** (M = reviewers per lens, 1–5, default 1, since v7.4.0; identical prompts, run in parallel, reports consolidated before triage) under a **rotating lens**: correctness & spec alignment → adversarial red-team → security → test & coverage quality. Every lens carries a **prose adaptation** — for files that are instructions to an agent (skills, prompts, configs) rather than executable code, runtime-input attacks are vacuous, so the reviewer attacks *agent misexecution* instead.
```

Replace:

```
`skills/multi-code-review/` (`SKILL.md` controller + `reviewer-prompt.md` dispatch template), the final-gate step in `skills/subagent-driven-development/SKILL.md`, `hooks/skill-rules.json` routing entry, `hooks/subagent-guard.js` roster, `tests/claude-code/test-multi-code-review.sh`, `tests/codex/test-subagent-guard.js`.
```

with:

```
`skills/multi-code-review/` (`SKILL.md` controller + `reviewer-prompt.md` dispatch template), the final-gate step in `skills/subagent-driven-development/SKILL.md`, `hooks/skill-rules.json` routing entry, `hooks/subagent-guard.js` roster, `hooks/session-start` (the `<reviewers-per-lens>` session tag, v7.4.0), `tests/claude-code/test-multi-code-review.sh`, `tests/codex/test-subagent-guard.js`, `tests/codex/test-session-start-reviewers-tag.sh`.
```

- [ ] **Step 7: `docs/REVIEW-PROCESS-COMPARISON.md`**

Replace:

```
- Each round dispatches **one fresh reviewer subagent, blind** to the authoring
  conversation, to prior rounds' findings, and to the audit log.
```

with:

```
- Each round dispatches **M fresh reviewer subagents (default 1), each blind**
  to the authoring conversation, to prior rounds' findings, to the audit log,
  and to the other reviewers of the round; their reports are consolidated
  into one finding set before triage.
```

Replace:

```
(a) self-review only, (b) one blind round, (c) the full N=3 lens loop,
```

with:

```
(a) self-review only, (b) one blind round, (c) the full N=3 lens loop, (d) M
reviewers per lens (M = 2, 3) against M = 1,
```

- [ ] **Step 8: Verify**

Run: `grep -n 'one clean-context reviewer\|one fresh reviewer subagent' README.md docs/guide/README.md docs/FORK-IMPROVEMENTS.md docs/REVIEW-PROCESS-COMPARISON.md`
Expected: no output.

Run: `grep -c 'SUPERPOWERS_REVIEWERS_PER_LENS' README.md docs/guide/README.md`
Expected: `README.md:1` or more, `docs/guide/README.md:2` or more.

Run: `grep -n 'M=1 cap=3' docs/guide/README.md`
Expected: the sample header line.

- [ ] **Step 9: Commit**

```bash
git add README.md docs/guide/README.md docs/FORK-IMPROVEMENTS.md docs/REVIEW-PROCESS-COMPARISON.md
git commit -m "docs: document M reviewers per lens and SUPERPOWERS_REVIEWERS_PER_LENS" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 7/8"
```

---

### Task 8: Release 7.4.0

**Files:**
- Modify: `VERSION`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugin.universal.yaml`
- Modify: `README.md`
- Modify: `RELEASE-NOTES.md`

**Security flag:** `none`

**Does NOT cover:** publishing a GitHub release (the fork publishes none; the badge is static); merging or creating a pull request (the orchestrator stops before that); `tests/codex/post-push-validation-checklist.md` (no Codex-facing change).

- [ ] **Step 1: Version files**

Run:

```bash
printf '7.4.0\n' > VERSION
sed -i.bak 's/"version": "7.3.0"/"version": "7.4.0"/' .claude-plugin/plugin.json .claude-plugin/marketplace.json
sed -i.bak 's/^  version: "7.3.0"$/  version: "7.4.0"/' plugin.universal.yaml
rm -f .claude-plugin/plugin.json.bak .claude-plugin/marketplace.json.bak plugin.universal.yaml.bak
```

- [ ] **Step 2: `README.md` — badge, lineage ranges, release enumeration**

Replace:

```
[![Version](https://img.shields.io/badge/version-7.3.0-white?style=for-the-badge)](RELEASE-NOTES.md)
```

with:

```
[![Version](https://img.shields.io/badge/version-7.4.0-white?style=for-the-badge)](RELEASE-NOTES.md)
```

Replace (both occurrences, lines 22 and 24; use replace-all):

```
(v6.7.0–v7.3.0)
```

with:

```
(v6.7.0–v7.4.0)
```

Replace:

```
slug-stamped commit messages (v7.1.0), and the per-topic artifact layout (v7.3.0) — are covered in [RELEASE-NOTES.md](RELEASE-NOTES.md).
```

with:

```
slug-stamped commit messages (v7.1.0), the per-topic artifact layout (v7.3.0), and M reviewers per lens (v7.4.0) — are covered in [RELEASE-NOTES.md](RELEASE-NOTES.md).
```

- [ ] **Step 3: `RELEASE-NOTES.md` entry**

Replace:

```
# Superpowers Orchestrator Release Notes

## v7.3.0 — one folder per topic, committed code reviews
```

with:

```
# Superpowers Orchestrator Release Notes

## v7.4.0 — M reviewers per lens

Field report: LLMs (large language models) are not deterministic — the same
reviewer prompt reports different findings on different runs, and one run can
miss a problem another run would report. Each round of `multi-doc-review` and
`multi-code-review` dispatched exactly one reviewer, so a round took one
sample of the reviewer's judgment under its lens.

- **M reviewers per lens.** A new parameter M (integer 1–5, default 1) sets
  how many reviewer subagents a round dispatches — in parallel, with the
  identical prompt, none told that the others exist. Their reports are
  consolidated into one finding set before triage: every finding of every
  usable report is kept (a union — no majority vote, which would drop exactly
  the findings this feature exists to catch), findings that name the same
  place and the same defect are merged at the highest severity given, and
  every reviewer-local id is traced to exactly one consolidated finding
  (`**Sources mapped:** k/k`). Running time stays close to one review; the
  token cost grows about M times per round. State it as `M=<m>`,
  `<m> reviewers per lens`, `<m> reviewers per round`, or
  `<m> parallel reviewers`: `/multi-doc-review <doc> [N] [M=<m>]`,
  `/multi-code-review [BASE] [N] [M=<m>]`. The skills never ask for M.
- **Convergence with M ≥ 2.** A round is clean only when the consolidated
  set has zero Critical and zero Important findings **and** all M reviewers
  returned a usable report; a partial round (a reviewer still unusable after
  one retry) is never clean. Verification re-reviews use the same M.
- **Log format.** Every invocation line now records `M=<m>` after `N=<n>`
  (a line without `M=` reads as M = 1). With M ≥ 2 a round entry gains
  `**Reviewers:**`, `**Reviewer verdicts:**`, and `**Sources mapped:**`
  lines, and every finding disposition line ends with
  ` ← <a>/<m>: <source ids>` — the agreement count and the
  reviewer-qualified ids (`r1:C1`). With M = 1 the entry is byte-identical
  to before. Readers of the `fixed — … → <sha>` line take the token right
  after `→ `.
- **Orchestration and SDD.** `orchestrating-development`'s Phase 0 batch
  asks for M (default: the environment variable's value, else 1); the
  orchestration-log header and `state.md` record `M=<m>`; `... with M=2`
  overrides it on resume, and a log written before 7.4.0 resumes with
  M = 1; both loop-controller templates carry `[M]`, because subagents never
  receive the session tag. The subagent-driven-development final gate and
  Batched Autonomous Mode never ask — they use the same default resolution,
  and a batch handoff carries a stated M across `/clear`.
- `SUPERPOWERS_REVIEWERS_PER_LENS` env var (integer 1–5, default 1) sets M
  for every invocation that does not state it; `hooks/session-start`
  carries it to the skills as a `<reviewers-per-lens>` session tag. Set it
  in settings.json's `env` block so it survives plugin updates; restart the
  CLI after changing it. Invalid or out-of-range values silently fall back
  to 1.
- **Tests.** `tests/codex/run-unit-tests.sh` gains a hermetic shell test of
  the tag (`tests/codex/test-session-start-reviewers-tag.sh`); the two
  behavioral review tests gain an M=2 case that cross-checks the round-1
  entry's counts against its source annotations.
- **Docs sync.** README (feature bullets, Skills Library, environment
  variables), `docs/guide/README.md` (stages, Phase 0 table, log sample,
  settings, cheat-sheet), `docs/FORK-IMPROVEMENTS.md`, and
  `docs/REVIEW-PROCESS-COMPARISON.md` updated for M.

## v7.3.0 — one folder per topic, committed code reviews
```

- [ ] **Step 4: Verify**

Run: `cat VERSION; grep -n '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json; grep -n '^  version:' plugin.universal.yaml`
Expected: `7.4.0` on every line.

Run: `grep -c '7\.4\.0' README.md`
Expected: `4` or more (badge, two ranges, enumeration).

Run: `grep -n '^## v7\.4\.0' RELEASE-NOTES.md`
Expected: line 3.

Run: `bash tests/codex/run-unit-tests.sh 2>&1 | tail -3 && bash tests/smart-compress/run-tests.sh 2>&1 | tail -3`
Expected: both suites report all tests passed.

- [ ] **Step 5: Commit**

```bash
git add VERSION .claude-plugin/plugin.json .claude-plugin/marketplace.json plugin.universal.yaml README.md RELEASE-NOTES.md
git commit -m "chore(release): v7.4.0 — M reviewers per lens" --trailer "Session: reviewers-per-lens" --trailer "Stage: task 8/8"
```
