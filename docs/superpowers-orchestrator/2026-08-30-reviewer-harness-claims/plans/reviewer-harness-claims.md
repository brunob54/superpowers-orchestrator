# Reviewer Harness Claims Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A review finding that rests on a harness property (a claim about the agent runtime, not about the document or diff) must carry a probe the reviewer ran, or name the one probe the controller runs before triage — so an untested runtime claim never stops an unattended run.

**Spec:** `/Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/specs/reviewer-harness-claims-design.md`

**Architecture:** Wording-only change to four Markdown files. Both reviewer templates (`skills/multi-doc-review/reviewer-prompt.md`, `skills/multi-code-review/reviewer-prompt.md`) gain one identical `### Harness claims` sub-section inside the `prompt: |` block and an optional trailing `| harness: …` field on finding lines. Both controller skills (`skills/multi-doc-review/SKILL.md`, `skills/multi-code-review/SKILL.md`) gain a triage step that runs a named probe once and disposes on the observation, plus a `Harness probes owed:` line in the completion report; `multi-code-review` also gains a guard before any `user-decision`. One new pure-bash fast test suite, `tests/reviewer-templates/run-tests.sh`, asserts these wording contracts on the repository's own files and is listed in `CLAUDE.md`.

**Tech Stack:** Markdown (skill and template text), bash (test suite: `grep`, `awk`, `diff`), git.

**Assumptions:**
- Assumes the plan basename is the slug: `reviewer-harness-claims`. Will NOT hold if the plan is renamed — the commit trailers below would then name the wrong workstream.
- Assumes the `Harness probes owed:` item shape `- [<id>] <probe> (round <i>)`: the spec gives `- [id] <probe>`, and the round suffix is added because finding ids restart every round, so an id alone is ambiguous across rounds. Will NOT matter for the tests (they assert only the `Harness probes owed:` line); revise the shape if the user wants the spec's literal form.
- Assumes the rule text lands at about 24 lines inside the prompt block. The spec's "near 15 lines" is a guideline that no test asserts; the rule below keeps every normative property of spec §1 and cannot be shortened further without dropping one.
- Assumes the existing drift assertions in `tests/sdd-scripts/run-tests.sh` (lines 586–600) pin only the blinding pathspec entries of `multi-code-review/reviewer-prompt.md`, which this plan does not touch. Task 6 re-runs that suite to confirm.
- Assumes no CI workflow lists the fast suites (verified: only `CLAUDE.md` names them; `RELEASE-NOTES.md` and `docs/` mention them historically). Will NOT hold if a CI file is added later — it would then need the new suite too.

**Global Constraints:**
- The `Harness claims` rule text is **identical, byte for byte**, in both reviewer templates: a level-three heading indented four spaces (`    ### Harness claims`), the **last** sub-section under `## Subagent Rules`, immediately before the prompt's next level-two heading (`    ## Target` in doc review, `    ## Diff Under Review` in code review). The rule is inside `prompt: |` — never in the `description:` comment above it.
- Exact strings the tests assert: `harness: tested —`, `harness: untested —` (both templates); `harness probe —`, `harness probe not runnable here`, `Harness probes owed:` (both SKILL.md files); ``never logged `user-decision` on the strength of an untested harness claim`` (multi-code-review SKILL.md only). The em dash is `—` (U+2014), matching every other disposition string in these files.
- Finding format: the existing reference sentences stay unchanged — "Every finding must reference a section or line of the target document." (doc review) and "Every finding must carry a file:line reference into the diff." (code review). The harness field is optional, trailing, and only on findings whose premise is a harness property.
- The harness triage branch ends only in `applied`/`fixed` (through normal triage) or `rejected: <reason>` — never `deferred`, `unresolved`, or `user-decision` on an untested claim. The `— harness probe: <observation>` clause goes on the disposition line **before** any ` ← a/m: …` source annotation.
- The `Harness probes owed:` line is always written in the completion report — `none` when empty.
- Do NOT touch: the `## Shared checkout — read-only inspection only` sections; the blinding pathspec line (`git diff --stat [BASE_SHA]..[HEAD_SHA] -- ':(top)' …`) in `multi-code-review/reviewer-prompt.md`; the `<!-- multi-review report -->` marker instruction; the `description:` canary comment ("verified 2026-08-28 …") in both templates; lenses, severities, convergence rules.
- No new hook, script, or `hooks/skill-rules.json` entry. No version bump, `RELEASE-NOTES.md` entry, or `docs/guide/` change. No behavioural test run (no real `claude` sessions). `docs/orchestration-issues.md` is not edited by this plan.
- Test suite: pure bash, no `claude` invocation, no `/dev/stdin`, no process substitution (`<(…)`) — temp files instead (Git Bash on Windows).

---

## File Structure

| File | Change | Responsibility |
|---|---|---|
| `tests/reviewer-templates/run-tests.sh` | Create | Fast static checks on the four wording files (spec Testing strategy items 1–6). |
| `skills/multi-doc-review/reviewer-prompt.md` | Modify | Reviewer rule `### Harness claims` inside the prompt block; finding-format extension paragraph. |
| `skills/multi-code-review/reviewer-prompt.md` | Modify | Same rule (identical text); finding-format extension paragraph, with the `### Checks Run` listing sentence. |
| `skills/multi-doc-review/SKILL.md` | Modify | Triage step 3 gains the harness sub-steps; completion report gains `Harness probes owed:`; log-format and Error Handling notes. |
| `skills/multi-code-review/SKILL.md` | Modify | Triage step 4 gains a first `Harness claims` bullet with the `user-decision` guard; fix-subagent input excludes the field; completion report gains `Harness probes owed:`; log-format and Error Handling notes. |
| `CLAUDE.md` | Modify | One line in the Testing block for the new suite. |

Task order is TDD: Task 1 writes the suite (16 of 19 assertions fail on the unchanged repository); Tasks 2–5 each make a predictable subset pass; Task 6 lists the suite and runs every fast suite.

---

### Task 1: Fast test suite for the reviewer-template wording contracts

**Files:**
- Create: `tests/reviewer-templates/run-tests.sh`
- Test: `tests/reviewer-templates/run-tests.sh` (this file is the test)

**Security flag:** `none`

**Does NOT cover:** behaviour of a real reviewer or controller session (a non-goal of the spec); the wording of lenses, severities, or the review-log entry format; any file other than the four named ones and their two string contracts (pathspec, marker). A heading placed inside the fence but above `prompt: |` fails check 1 by design; a rule placed after the next `## ` heading passes check 1 but yields an empty or wrong extract in check 5.

- [ ] **Step 1: Write the test suite**

Create `tests/reviewer-templates/run-tests.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Reviewer-template test suite: static wording checks on the reviewer
# templates and SKILL.md files of multi-doc-review and multi-code-review.
# Pure bash; no claude invocation.
# Windows note: avoids /dev/stdin and process substitution (not reliable in
# Git Bash on Windows) — extracted text goes through temp files.
#
# Contract source: docs/superpowers-orchestrator/2026-08-30-reviewer-harness-claims/
# specs/reviewer-harness-claims-design.md, section "Testing strategy".

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_PROMPT="$ROOT/skills/multi-doc-review/reviewer-prompt.md"
CODE_PROMPT="$ROOT/skills/multi-code-review/reviewer-prompt.md"
DOC_SKILL="$ROOT/skills/multi-doc-review/SKILL.md"
CODE_SKILL="$ROOT/skills/multi-code-review/SKILL.md"

# Wording contracts asserted below. Each is one fixed string.
RULE_HEADING='    ### Harness claims'
PROMPT_OPEN='  prompt: |'
FIELD_TESTED='harness: tested —'
FIELD_UNTESTED='harness: untested —'
REASON_PROBE='harness probe —'
REASON_NOT_RUNNABLE='harness probe not runnable here'
OWED_LINE='Harness probes owed:'
GUARD='never logged `user-decision` on the strength of an untested harness claim'
MARKER='<!-- multi-review report -->'
PATHSPEC="':(top,exclude)docs/superpowers-orchestrator/*/*-review-log.md'"

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}

# Line number of the first line containing the fixed string $2 in file $1;
# empty when absent.
first_line_of() { grep -nF -- "$2" "$1" | head -n 1 | cut -d: -f1; }

# Line number of the first line starting with ``` after line $2 in file $1;
# empty when absent.
fence_after() {
  awk -v start="$2" 'NR > start && substr($0, 1, 3) == "```" { print NR; exit }' "$1"
}

# Print the Harness claims rule of file $1: from its heading line up to, but
# not including, the next level-two heading of the prompt block (`    ## `).
extract_rule() {
  awk -v h="$RULE_HEADING" '
    $0 == h { found = 1 }
    found && /^    ## / { exit }
    found { print }
  ' "$1"
}

check_rule_inside_prompt() { # label file
  local label="$1" file="$2" open close rule
  open="$(first_line_of "$file" "$PROMPT_OPEN")"
  if [ -z "$open" ]; then bad "$label: no '$PROMPT_OPEN' line"; return; fi
  close="$(fence_after "$file" "$open")"
  if [ -z "$close" ]; then bad "$label: no closing fence after '$PROMPT_OPEN'"; return; fi
  rule="$(first_line_of "$file" "$RULE_HEADING")"
  if [ -z "$rule" ]; then bad "$label: no '$RULE_HEADING' heading"; return; fi
  if [ "$rule" -gt "$open" ] && [ "$rule" -lt "$close" ]; then
    ok "$label: Harness claims rule inside the prompt block (line $rule, block $open..$close)"
  else
    bad "$label: Harness claims rule at line $rule is outside the prompt block ($open..$close)"
  fi
}

check_field_spellings() { # label file
  assert_file_contains "$1: field spelling '$FIELD_TESTED'" "$2" "$FIELD_TESTED"
  assert_file_contains "$1: field spelling '$FIELD_UNTESTED'" "$2" "$FIELD_UNTESTED"
}

check_controller_strings() { # label file
  assert_file_contains "$1: reason string '$REASON_PROBE'" "$2" "$REASON_PROBE"
  assert_file_contains "$1: reason string '$REASON_NOT_RUNNABLE'" "$2" "$REASON_NOT_RUNNABLE"
  assert_file_contains "$1: completion-report line '$OWED_LINE'" "$2" "$OWED_LINE"
}

bold "1. Harness claims rule is inside the prompt block"
check_rule_inside_prompt "doc-review template" "$DOC_PROMPT"
check_rule_inside_prompt "code-review template" "$CODE_PROMPT"

bold "2. Finding-format field spellings"
check_field_spellings "doc-review template" "$DOC_PROMPT"
check_field_spellings "code-review template" "$CODE_PROMPT"

bold "3. Controller triage reason strings and completion-report line"
check_controller_strings "multi-doc-review SKILL.md" "$DOC_SKILL"
check_controller_strings "multi-code-review SKILL.md" "$CODE_SKILL"

bold "4. user-decision guard"
assert_file_contains "multi-code-review SKILL.md: guard fragment" "$CODE_SKILL" "$GUARD"

bold "5. Rule text drift between the two templates"
DOC_RULE="$WORK/doc-rule.txt"
CODE_RULE="$WORK/code-rule.txt"
extract_rule "$DOC_PROMPT" > "$DOC_RULE"
extract_rule "$CODE_PROMPT" > "$CODE_RULE"
if [ -s "$DOC_RULE" ]; then ok "doc-review template: rule extract is non-empty"; else bad "doc-review template: rule extract is empty"; fi
if [ -s "$CODE_RULE" ]; then ok "code-review template: rule extract is non-empty"; else bad "code-review template: rule extract is empty"; fi
if [ -s "$DOC_RULE" ] && [ -s "$CODE_RULE" ] && diff -q "$DOC_RULE" "$CODE_RULE" >/dev/null; then
  ok "rule text identical in both templates"
else
  bad "rule text differs between templates (or an extract is empty)"
  diff "$DOC_RULE" "$CODE_RULE" || true
fi

bold "6. Unchanged contracts"
assert_file_contains "code-review template: blinding pathspec line" "$CODE_PROMPT" "$PATHSPEC"
assert_file_contains "code-review template: report marker instruction" "$CODE_PROMPT" "$MARKER"
assert_file_contains "doc-review template: report marker instruction" "$DOC_PROMPT" "$MARKER"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
```

- [ ] **Step 2: Make it executable and run it to verify it fails on the unchanged repository**

Run: `chmod +x tests/reviewer-templates/run-tests.sh && bash tests/reviewer-templates/run-tests.sh; echo "exit=$?"`
Expected: `Results: 3 passed, 16 failed` and `exit=1`. The 3 passes are section 6 (pathspec line and the two marker instructions already exist). The 16 failures: section 1 (2: no `### Harness claims` heading), section 2 (4), section 3 (6), section 4 (1), section 5 (3: both extracts empty, drift check fails because an extract is empty).

- [ ] **Step 3: Confirm the suite is self-contained (no `/dev/stdin`, no process substitution)**

Run: `grep -nE '/dev/stdin|<\(' tests/reviewer-templates/run-tests.sh; echo "matches=$?"`
Expected: no output lines and `matches=1` (grep found nothing).

- [ ] **Step 4: Commit**

```bash
git add tests/reviewer-templates/run-tests.sh
git commit -m "test(reviewer-templates): add fast wording-contract suite for harness claims" --trailer "Session: reviewer-harness-claims" --trailer "Stage: task 1/6"
```

---

### Task 2: Harness claims rule and finding field in the doc-review reviewer template

**Files:**
- Modify: `skills/multi-doc-review/reviewer-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** claims about the document under review (they keep the existing section/line reference rule); the `description:` canary comment above `prompt: |` (unchanged); the code-review template (Task 3). The rule tells a reviewer to run only reviewer-safe probes — it does not cover probes that need a dispatch (condition (d)); those are named for the controller.

- [ ] **Step 1: Insert the rule as the last sub-section of `## Subagent Rules`**

In `skills/multi-doc-review/reviewer-prompt.md`, replace this text (currently lines 40–42):

```markdown
    - Your review is read-only: do not modify any file.

    ## Target
```

with this text (the rule block between the bullet and `## Target`; every line of the rule is indented four spaces, and the block ends with one blank line before `## Target`):

```markdown
    - Your review is read-only: do not modify any file.

    ### Harness claims

    A *harness property* is a statement about how the agent runtime
    behaves when the pipeline runs — what a dispatch delivers to a
    subagent's context, what a hook injects, whether a nested dispatch
    blocks, what an environment variable or a tool does at run time — and
    its truth cannot be read from the repository. When unsure whether a
    premise is one, ask: can its truth be read from the repository? If
    not, it is a harness property. A *probe* is one action (one command,
    one dispatch of a throwaway subagent, one read of your own context)
    whose result is one clause that matches or contradicts the claim;
    the model probe: a subagent dispatched with a token only in its
    `description` reports the token absent from its context.
    A finding whose premise is a harness property MUST either carry a
    reviewer-safe probe you ran and what you observed, or name the single
    probe the controller should run (the `harness:` field under Output
    format). A harness claim with neither is not a finding: drop it.
    A probe is reviewer-safe only when it (a) writes nothing to the
    checkout, the index, HEAD, or branch state; (b) binds no shared
    resource (fixed port, fixed temporary path, shared database); (c)
    runs no code from the change under review (the branch, or the
    repository a document describes); and (d) dispatches no subagent.
    Anything else is a controller probe: name it, never run it. One
    probe per finding — a claim that one probe cannot settle is tagged
    `harness: untested — not settled by one probe; first: <probe>`. Any
    allowance elsewhere in this prompt to run a focused test is never a
    probe: condition (c) governs every harness claim.

    ## Target
```

- [ ] **Step 2: Add the finding-format extension at the end of the prompt block**

In the same file, replace this text (currently the last paragraph inside the fence, followed by the closing fence):

```markdown
    Every finding must reference a section or line of the target document.
    Use "No material issues under this lens." only when you have zero
    findings of any severity; a Minor-only review reports counts with empty
    Critical/Important sections.
```
```

with:

```markdown
    Every finding must reference a section or line of the target document.
    Use "No material issues under this lens." only when you have zero
    findings of any severity; a Minor-only review reports counts with empty
    Critical/Important sections.

    A finding whose premise is a harness property (Subagent Rules, Harness
    claims) ends with one extra field after its suggested fix:
    `| harness: tested — <probe in one clause>; observed <result>` or
    `| harness: untested — <the one probe the controller should run>`.
    Findings about the document itself carry no `harness:` field.
```
```

(The closing triple-backtick fence stays as the line right after the new paragraph.)

- [ ] **Step 3: Run the suite to verify the doc-review checks pass**

Run: `bash tests/reviewer-templates/run-tests.sh; echo "exit=$?"`
Expected: `Results: 8 passed, 11 failed`, `exit=1`. Newly passing: "doc-review template: Harness claims rule inside the prompt block", both doc-review field spellings, "doc-review template: rule extract is non-empty". Still failing: the code-review counterparts (Task 3), section 3 (Tasks 4–5), section 4 (Task 5), and the drift check (until Task 3).

- [ ] **Step 4: Verify placement by hand — the rule is the last sub-section before `## Target` and the canary comment is untouched**

Run: `grep -n '^    ### Harness claims\|^    ## Target\|verified 2026-08-28' skills/multi-doc-review/reviewer-prompt.md`
Expected: three lines, in file order: the `verified 2026-08-28` canary comment at line 20 (untouched), `42:    ### Harness claims`, and `70:    ## Target` — the heading at line 42 and `## Target` at line 70 with nothing but the 25-line rule body and two blank lines between them.

- [ ] **Step 5: Commit**

```bash
git add skills/multi-doc-review/reviewer-prompt.md
git commit -m "feat(multi-doc-review): reviewer must probe or name a probe for harness claims" --trailer "Session: reviewer-harness-claims" --trailer "Stage: task 2/6"
```

---

### Task 3: Harness claims rule and finding field in the code-review reviewer template

**Files:**
- Modify: `skills/multi-code-review/reviewer-prompt.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** claims about the diff under review (they keep the file:line rule); the `## Tests` focused-test allowance, which stays as it is — the rule says such a run is never a probe; the `## Shared checkout` section, the blinding pathspec line, the marker instruction, and the `description:` canary comment (all unchanged).

- [ ] **Step 1: Insert the rule as the last sub-section of `## Subagent Rules`**

In `skills/multi-code-review/reviewer-prompt.md`, replace this text (currently lines 60–64):

```markdown
    - Cite secret-bearing findings by `file:line` and a description
      only; never reproduce a credential, token, or key value in your
      report.

    ## Diff Under Review
```

with this text. The rule block is **byte-identical** to Task 2's — copy it from here, not by paraphrase; the drift check compares the two extracts with `diff`:

```markdown
    - Cite secret-bearing findings by `file:line` and a description
      only; never reproduce a credential, token, or key value in your
      report.

    ### Harness claims

    A *harness property* is a statement about how the agent runtime
    behaves when the pipeline runs — what a dispatch delivers to a
    subagent's context, what a hook injects, whether a nested dispatch
    blocks, what an environment variable or a tool does at run time — and
    its truth cannot be read from the repository. When unsure whether a
    premise is one, ask: can its truth be read from the repository? If
    not, it is a harness property. A *probe* is one action (one command,
    one dispatch of a throwaway subagent, one read of your own context)
    whose result is one clause that matches or contradicts the claim;
    the model probe: a subagent dispatched with a token only in its
    `description` reports the token absent from its context.
    A finding whose premise is a harness property MUST either carry a
    reviewer-safe probe you ran and what you observed, or name the single
    probe the controller should run (the `harness:` field under Output
    format). A harness claim with neither is not a finding: drop it.
    A probe is reviewer-safe only when it (a) writes nothing to the
    checkout, the index, HEAD, or branch state; (b) binds no shared
    resource (fixed port, fixed temporary path, shared database); (c)
    runs no code from the change under review (the branch, or the
    repository a document describes); and (d) dispatches no subagent.
    Anything else is a controller probe: name it, never run it. One
    probe per finding — a claim that one probe cannot settle is tagged
    `harness: untested — not settled by one probe; first: <probe>`. Any
    allowance elsewhere in this prompt to run a focused test is never a
    probe: condition (c) governs every harness claim.

    ## Diff Under Review
```

- [ ] **Step 2: Add the finding-format extension at the end of the prompt block**

In the same file, replace this text (currently the last paragraph inside the fence, followed by the closing fence):

```markdown
    Every finding must carry a file:line reference into the diff. Use
    "No material issues under this lens." only with zero findings of any
    severity; a Minor-only review reports counts with empty
    Critical/Important sections.
```
```

with:

```markdown
    Every finding must carry a file:line reference into the diff. Use
    "No material issues under this lens." only with zero findings of any
    severity; a Minor-only review reports counts with empty
    Critical/Important sections.

    A finding whose premise is a harness property (Subagent Rules, Harness
    claims) ends with one extra field after its suggested fix:
    `| harness: tested — <probe in one clause>; observed <result>` or
    `| harness: untested — <the one probe the controller should run>`.
    Findings about the diff itself carry no `harness:` field. A probe you
    ran is also listed under Checks Run.
```
```

(The closing triple-backtick fence stays as the line right after the new paragraph.)

- [ ] **Step 3: Run the suite to verify sections 1, 2, 5 and 6 pass**

Run: `bash tests/reviewer-templates/run-tests.sh; echo "exit=$?"`
Expected: `Results: 12 passed, 7 failed`, `exit=1`. Now passing: all of sections 1, 2, 5 (including "rule text identical in both templates") and 6. Still failing: section 3 (6 assertions, Tasks 4–5) and section 4 (1, Task 5). If "rule text differs between templates" fails, the printed `diff` output shows the divergent line — fix it in this file to match Task 2's text exactly.

- [ ] **Step 4: Confirm the pinned contracts of the existing sdd-scripts drift check still hold**

Run: `bash tests/sdd-scripts/run-tests.sh 2>&1 | grep -c 'FAIL:'; echo "grep-exit=$?"`
Expected: `0` and `grep-exit=1` (no `FAIL:` line — the blinding pathspec entries are still present verbatim).

- [ ] **Step 5: Commit**

```bash
git add skills/multi-code-review/reviewer-prompt.md
git commit -m "feat(multi-code-review): reviewer must probe or name a probe for harness claims" --trailer "Session: reviewer-harness-claims" --trailer "Stage: task 3/6"
```

---

### Task 4: Controller triage of harness claims in multi-doc-review

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** a `user-decision` guard — `multi-doc-review` has no `user-decision` disposition, so the guard exists only in `multi-code-review` (Task 5); findings tagged `harness: tested` beyond accepting their observation; any disposition other than the two the triage sentence already names (`applied`, `rejected: <reason>`); the lens, convergence, and consolidation rules (unchanged). A probe that needs a dispatch is run only when the dispatch rule passes; on every other platform the "not runnable here" branch applies.

- [ ] **Step 1: Replace Procedure step 3 with the harness sub-steps followed by the existing triage sentence**

In `skills/multi-doc-review/SKILL.md`, replace this text (currently lines 164–167):

```markdown
3. **Triage and merge:** the consolidated set is the input. Every
   Critical/Important finding is either applied to the document or
   `rejected: <reason>` — never silently dropped. Minor findings: apply at
   your discretion; log all dispositions either way.
```

with:

```markdown
3. **Triage and merge:** the consolidated set is the input. Before any
   disposition is chosen, settle the harness claims — findings whose
   premise is a property of the agent runtime, tagged by the reviewer with
   the trailing `harness:` field of `reviewer-prompt.md`:
   1. A finding tagged `harness: untested — <probe>` — except one tagged
      `not settled by one probe`, which takes the "not runnable here"
      branch of 3.2 directly (its `first: <probe>` text fills only the
      `Harness probes owed:` line of the completion report) — gets that
      probe run once, by you. Constraints: the probe writes nothing to
      the checkout, the index, HEAD, or branch state; binds no shared
      resource (fixed port, fixed temporary path, shared database); runs
      no code from the change under review; and is one action — one
      command, one read of your own context, or one dispatch of a
      throwaway subagent whose prompt is self-contained and that writes
      nothing. **Dispatch rule:** run a dispatch-based probe only when you
      know the dispatch will complete within your own turn — you are the
      main session (the Agent tool's result or a task notification comes
      back to you), or your own prompt states that you were dispatched
      with a `name:` (the `orch-*` controllers of
      `orchestrating-development`, whose dispatches block since v7.5.0).
      An unnamed subagent's child runs detached and its completion never
      reaches the subagent; when you cannot tell which case you are in,
      take the "not runnable here" branch with the reason `dispatch would
      not block`. The reviewer's condition (d) exists for exactly this
      reason and does not apply to a controller that passes the dispatch
      rule.
   2. Dispose on the observation:
      - it contradicts the claim → `rejected: harness probe —
        <observation>`;
      - it supports the claim → triage the finding as if it had been
        `harness: tested`; the ordinary rules apply from here, and the
        observation is recorded on the disposition line as a trailing
        clause `— harness probe: <observation>`, placed before any source
        annotation (` ← a/m: …`), whatever the disposition;
      - the probe cannot be run here (tool missing, a platform without
        nested dispatch, the dispatch rule of 3.1 fails, the reviewer
        tagged it `not settled by one probe`, the probe would break a
        constraint of 3.1, or the observation is ambiguous — it cannot be
        written in one clause that matches or contradicts the result the
        claim predicts) → `rejected: harness probe not runnable here —
        <probe>`. This rejection never blocks the gate; every such
        rejection is listed on the completion report's
        `Harness probes owed:` line.
   3. A finding tagged `harness: tested — …` is triaged normally and its
      observation is accepted: the rule keeps claims tested, it does not
      re-verify every observation. When the stated probe was not
      reviewer-safe (the reviewer dispatched a subagent, for example),
      append `(reviewer probe not reviewer-safe)` to the disposition
      line. You may re-run a probe whose observation looks inconsistent
      with the reviewer's conclusion; you are not required to.
   The harness branch adds no disposition: it always ends in one of the
   two below. Every Critical/Important finding is either applied to the
   document or `rejected: <reason>` — never silently dropped. Minor
   findings: apply at your discretion; log all dispositions either way.
```

- [ ] **Step 2: Add the `Harness probes owed:` line to the after-loop report**

In the same file, replace this text (currently lines 188–190):

```markdown
Fix merge-introduced issues inline and note them in the log. Then report:
rounds run, per-round finding counts, converged vs cap reached, log path,
effective M (and any substitution).
```

with:

```markdown
Fix merge-introduced issues inline and note them in the log. Then report:
rounds run, per-round finding counts, converged vs cap reached, log path,
effective M (and any substitution), and a `Harness probes owed:` line —
one item `- [<id>] <probe> (round <i>)` per
`rejected: harness probe not runnable here` disposition of this invocation,
or `Harness probes owed: none`. The line is always written; a report
without it is defective. The user runs the owed probes after the loop.
```

- [ ] **Step 3: Note the clause placement in the Review Log Format**

In the same file, replace this text (currently lines 324–330, the source-annotation bullet):

```markdown
- Source annotation — ` ← <a>/<m>: <source ids>` appended at the end of the
  disposition line; `<a>` is the agreement count (distinct reviewers that
  reported the finding), the source ids are comma-separated in reviewer
  order. The line keeps its existing prefix (`- [I1] applied — …`), so
  patterns anchored at the start of the line still match. The note lines
  the "After the loop" step writes for merge-introduced fixes (self-review
  notes) carry no annotation.
```

with:

```markdown
- Source annotation — ` ← <a>/<m>: <source ids>` appended at the end of the
  disposition line; `<a>` is the agreement count (distinct reviewers that
  reported the finding), the source ids are comma-separated in reviewer
  order. The line keeps its existing prefix (`- [I1] applied — …`), so
  patterns anchored at the start of the line still match. A
  `— harness probe: <observation>` clause (Procedure step 3.2) sits before
  the annotation, never after it. The note lines
  the "After the loop" step writes for merge-introduced fixes (self-review
  notes) carry no annotation.
```

- [ ] **Step 4: Add the Error Handling bullet**

In the same file, in `## Error Handling`, replace this text (currently the last bullet of the list):

```markdown
- Plan with no locatable spec → lens phrasing omits spec-coverage; round 1
  uses the `general` correctness instructions; log that coverage was not
  reviewed.
```

with:

```markdown
- Plan with no locatable spec → lens phrasing omits spec-coverage; round 1
  uses the `general` correctness instructions; log that coverage was not
  reviewed.
- Harness probe result ambiguous, probe not runnable here, or probe would
  break a constraint of Procedure step 3.1 →
  `rejected: harness probe not runnable here — <probe>`, never treated as
  support for the claim; the probe goes on the `Harness probes owed:` line.
```

- [ ] **Step 5: Run the suite to verify the doc-review controller strings pass**

Run: `bash tests/reviewer-templates/run-tests.sh; echo "exit=$?"`
Expected: `Results: 15 passed, 4 failed`, `exit=1`. Newly passing: the three `multi-doc-review SKILL.md` assertions of section 3. Still failing: the three `multi-code-review SKILL.md` assertions of section 3 and the section 4 guard (Task 5).

- [ ] **Step 6: Commit**

```bash
git add skills/multi-doc-review/SKILL.md
git commit -m "feat(multi-doc-review): controller probes untested harness claims before triage" --trailer "Session: reviewer-harness-claims" --trailer "Stage: task 4/6"
```

---

### Task 5: Controller triage, user-decision guard, and fix-subagent input in multi-code-review

**Files:**
- Modify: `skills/multi-code-review/SKILL.md`
- Test: `tests/reviewer-templates/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** `user-decision` items that are not harness claims (plan-mandated findings whose premise is about the code keep today's path); the Batched Autonomous Mode journaling of a `user-decision` (unchanged — the guard runs before the disposition is chosen, so batched mode sees only guarded dispositions); the fix subagent's behaviour beyond what it receives; the verification re-review cycle; the pipeline rules and completion marker. The guard applies to every `user-decision`, the carried-findings path included.

- [ ] **Step 1: Insert the `Harness claims` bullet as the first bullet of Procedure step 4 (Triage)**

In `skills/multi-code-review/SKILL.md`, replace this text (currently lines 419–422, the start of the Triage step):

```markdown
4. **Triage:**
   - **Critical/Important:** dispatch ONE fix subagent per round with the
     complete consolidated list — id, severity, location, description; no
     source ids and no agreement counts (never one fixer per finding). The
```

with:

```markdown
4. **Triage:**
   - **Harness claims (settled before any disposition below is chosen):**
     a finding whose premise is a property of the agent runtime, tagged by
     the reviewer with the trailing `harness:` field of
     `reviewer-prompt.md`.
     1. A finding tagged `harness: untested — <probe>` — except one tagged
        `not settled by one probe`, which takes the "not runnable here"
        branch of item 2 directly (its `first: <probe>` text fills only
        the `Harness probes owed:` line of the completion report) — gets
        that probe run once, by you. Constraints: the probe writes nothing
        to the checkout, the index, HEAD, or branch state; binds no shared
        resource (fixed port, fixed temporary path, shared database); runs
        no code from the change under review; and is one action — one
        command, one read of your own context, or one dispatch of a
        throwaway subagent whose prompt is self-contained and that writes
        nothing. **Dispatch rule:** run a dispatch-based probe only when
        you know the dispatch will complete within your own turn — you are
        the main session (the Agent tool's result or a task notification
        comes back to you), or your own prompt states that you were
        dispatched with a `name:` (the `orch-*` controllers of
        `orchestrating-development`, whose dispatches block since v7.5.0).
        An unnamed subagent's child runs detached and its completion never
        reaches the subagent; when you cannot tell which case you are in,
        take the "not runnable here" branch with the reason `dispatch
        would not block`. The reviewer's condition (d) exists for exactly
        this reason and does not apply to a controller that passes the
        dispatch rule.
     2. Dispose on the observation:
        - it contradicts the claim → `rejected: harness probe —
          <observation>`;
        - it supports the claim → triage the finding as if it had been
          `harness: tested`; the ordinary rules below apply from here, and
          the observation is recorded on the disposition line as a
          trailing clause `— harness probe: <observation>`, placed before
          any source annotation (` ← a/m: …`), whatever the disposition
          (`fixed`, `user-decision`, …);
        - the probe cannot be run here (tool missing, a platform without
          nested dispatch, the dispatch rule of item 1 fails, the reviewer
          tagged it `not settled by one probe`, the probe would break a
          constraint of item 1, or the observation is ambiguous — it
          cannot be written in one clause that matches or contradicts the
          result the claim predicts) → `rejected: harness probe not
          runnable here — <probe>`. This is the existing "reject as
          unverifiable" path with the probe text kept, and it is not
          blocking — `unresolved` and `user-decision` both stop the host
          gate; this does not. Every such rejection is listed on the
          completion report's `Harness probes owed:` line.
     3. **Guard:** a finding is never logged `user-decision` on the
        strength of an untested harness claim. Before any `user-decision`
        — a plan-mandated finding, or a carried item decided from reviewer
        recommendations — ask whether the finding's premise is a harness
        property. If it is and the reviewer tagged it, item 1 applies
        first; only a supported claim can then become `user-decision`. If
        it is and the reviewer did not tag it, name one probe yourself
        when one exists within the constraints of item 1 and run it; when
        you cannot name one, take the "not runnable here" branch with the
        reason `no probe named`. This guard is a backstop, not the primary
        mechanism: the reviewer's tag is.
     4. A finding tagged `harness: tested — …` is triaged normally and its
        observation is accepted: the rule keeps claims tested, it does not
        re-verify every observation. When the stated probe was not
        reviewer-safe (the reviewer dispatched a subagent, for example),
        append `(reviewer probe not reviewer-safe)` to the disposition
        line. You may re-run a probe whose observation looks inconsistent
        with the reviewer's conclusion; you are not required to.
   - **Critical/Important:** dispatch ONE fix subagent per round with the
     complete consolidated list — id, severity, location, description; no
     source ids, no agreement counts, and no `harness:` field or probe
     observation (the finding text already states what to change; the
     fix subagent fixes the code). Never one fixer per finding. The
```

- [ ] **Step 2: Reference the guard from the plan-mandated and carried-findings bullets**

In the same file, replace this text (currently lines 452–455):

```markdown
   - **Plan-mandated findings** (conflicting with what the plan's text
     requires) are the user's decision — log `user-decision`, present at
     the after-loop report. In Batched Autonomous Mode: journal under
     `## Open Issues` and end the batch.
```

with:

```markdown
   - **Plan-mandated findings** (conflicting with what the plan's text
     requires) are the user's decision — after the harness guard above,
     log `user-decision`, present at
     the after-loop report. In Batched Autonomous Mode: journal under
     `## Open Issues` and end the batch.
```

and replace this text (currently lines 476–479, the end of the carried-findings bullet):

```markdown
     decide alone. fix-before-merge → include it in this round's fix
     dispatch (`fixed — <summary> → <sha>`); ship-as-is → `carried`;
     user-decision → `user-decision`. Log each under the round's
     dispositions, without a source annotation.
```

with:

```markdown
     decide alone. fix-before-merge → include it in this round's fix
     dispatch (`fixed — <summary> → <sha>`); ship-as-is → `carried`;
     user-decision → `user-decision`, after the harness guard above: a
     carried item whose premise is a harness property is checked the same
     way before it is logged `user-decision`. Log each under the round's
     dispositions, without a source annotation.
```

- [ ] **Step 3: Add the `Harness probes owed:` line to the after-loop report**

In the same file, replace this text (currently lines 746–748):

```markdown
would never match on a later comparison. Then report to the host gate: rounds run, per-round finding
counts, fixes applied (commit SHAs), unresolved and user-decision items,
converged vs cap reached, log path, effective M (and any substitution).
```

with:

```markdown
would never match on a later comparison. Then report to the host gate: rounds run, per-round finding
counts, fixes applied (commit SHAs), unresolved and user-decision items,
converged vs cap reached, log path, effective M (and any substitution),
and a `Harness probes owed:` line — one item `- [<id>] <probe> (round <i>)`
per `rejected: harness probe not runnable here` disposition of this
invocation, or `Harness probes owed: none`. The line is always written; a
report without it is defective. The user runs the owed probes after the
loop.
```

- [ ] **Step 4: Note the clause placement in the Review Log Format**

In the same file, replace this text (currently lines 684–689, the start of the disposition-prefix bullet):

```markdown
- Every disposition line keeps its existing prefix (`- [I1] fixed — …`), so
  patterns anchored at the start of the line still match. The `fixed`
  disposition keeps its single shape, which becomes
  `fixed — <summary> → <sha>[ ← <a>/<m>: <ids>]`; every reader of `<sha>`
  takes the token immediately after `→ ` (before ` ← ` when an annotation
  is present). Two kinds of disposition line carry no annotation:
```

with:

```markdown
- Every disposition line keeps its existing prefix (`- [I1] fixed — …`), so
  patterns anchored at the start of the line still match. The `fixed`
  disposition keeps its single shape, which becomes
  `fixed — <summary> → <sha>[ ← <a>/<m>: <ids>]`; every reader of `<sha>`
  takes the token immediately after `→ ` (before ` ← ` when an annotation
  is present). A `— harness probe: <observation>` clause (Triage, Harness
  claims item 2) sits after the disposition text and before the ` ← `
  annotation, never after it. Two kinds of disposition line carry no annotation:
```

- [ ] **Step 5: Add the Error Handling bullet**

In the same file, in `## Error Handling`, replace this text (currently the bullet that ends the carried-finding disagreement rule):

```markdown
  `user-decision` under M >= 2 becomes `fix-before-merge`: the item is fixed
  rather than stopping an unattended run.
```

with:

```markdown
  `user-decision` under M >= 2 becomes `fix-before-merge`: the item is fixed
  rather than stopping an unattended run.
- Harness probe result ambiguous, probe not runnable here, probe would
  break a constraint of Triage item 1, or no probe can be named for an
  untagged harness premise before a `user-decision` →
  `rejected: harness probe not runnable here — <probe>`, never treated as
  support for the claim; the probe goes on the `Harness probes owed:` line.
```

- [ ] **Step 6: Run the suite to verify every assertion passes**

Run: `bash tests/reviewer-templates/run-tests.sh; echo "exit=$?"`
Expected: `Results: 19 passed, 0 failed` and `exit=0`.

- [ ] **Step 7: Confirm the guard fragment is present exactly once and the pathspec drift check still holds**

Run: `grep -c 'never logged `user-decision` on the strength of an untested harness claim' skills/multi-code-review/SKILL.md; bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -n 3`
Expected: `1`, then the sdd-scripts summary with `0 failed` (or its equivalent all-green last lines).

- [ ] **Step 8: Commit**

```bash
git add skills/multi-code-review/SKILL.md
git commit -m "feat(multi-code-review): probe untested harness claims; guard user-decision" --trailer "Session: reviewer-harness-claims" --trailer "Stage: task 5/6"
```

---

### Task 6: List the suite in CLAUDE.md and run every fast suite

**Files:**
- Modify: `CLAUDE.md`
- Test: `tests/reviewer-templates/run-tests.sh`, `tests/codex/run-unit-tests.sh`, `tests/smart-compress/run-tests.sh`, `tests/sdd-scripts/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** the behavioural suites under `tests/claude-code/`, `tests/skill-triggering/`, `tests/explicit-skill-requests/`, `tests/opencode/` (a non-goal: they must not run concurrently with a review loop); `RELEASE-NOTES.md`, `VERSION`, `docs/guide/` (release work, decided after the branch outcome); `docs/orchestration-issues.md` (local, hand-edited).

- [ ] **Step 1: Add the suite to the Testing block**

In `CLAUDE.md`, replace this text:

```markdown
bash tests/codex/run-unit-tests.sh        # hook unit tests (Node >= 16 only, fast — run these first)
bash tests/smart-compress/run-tests.sh    # Bash-output compression rules
```

with:

```markdown
bash tests/codex/run-unit-tests.sh        # hook unit tests (Node >= 16 only, fast — run these first)
bash tests/smart-compress/run-tests.sh    # Bash-output compression rules
bash tests/reviewer-templates/run-tests.sh # reviewer-template and review-skill wording contracts (harness claims)
```

- [ ] **Step 2: Run every fast suite**

Run: `bash tests/reviewer-templates/run-tests.sh 2>&1 | tail -n 1; bash tests/codex/run-unit-tests.sh 2>&1 | tail -n 3; bash tests/smart-compress/run-tests.sh 2>&1 | tail -n 3; bash tests/sdd-scripts/run-tests.sh 2>&1 | tail -n 3`
Expected: `Results: 19 passed, 0 failed` for the new suite, and the three existing suites end with their all-passed summary lines (zero failures each). Any failure in an existing suite is a regression introduced by Tasks 2–5 — the only plausible cause is a changed sentence that `tests/sdd-scripts/run-tests.sh` pins; restore that sentence.

- [ ] **Step 3: Verify the whole change is wording plus one test file**

Run: `git diff --stat main...HEAD -- . ':(exclude)docs/superpowers-orchestrator' | tail -n 8`
Expected: exactly six files — `CLAUDE.md`, `skills/multi-code-review/SKILL.md`, `skills/multi-code-review/reviewer-prompt.md`, `skills/multi-doc-review/SKILL.md`, `skills/multi-doc-review/reviewer-prompt.md`, `tests/reviewer-templates/run-tests.sh` — and nothing under `hooks/`, no `VERSION`, no `RELEASE-NOTES.md`.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): list the reviewer-templates fast test suite" --trailer "Session: reviewer-harness-claims" --trailer "Stage: task 6/6"
```

---

## Self-Review

**1. Spec coverage.**
- §1 Reviewer rule (definitions, MUST rule, conditions (a)–(d), model probe inline, one-probe-per-finding tag, focused-test allowance is never a probe, placement) → Tasks 2 and 3.
- §2 Finding format extension, both spellings, reference sentences kept, Checks Run listing in code review → Tasks 2 and 3.
- §3 step 1 (run the probe once, constraints, dispatch rule, `dispatch would not block`) → Tasks 4 and 5. Step 2 (three branches, reason strings, trailing clause before ` ← `, non-blocking, `Harness probes owed:` always written) → Tasks 4 and 5. Step 3 (guard, untagged premise, `no probe named`, carried-findings path) → Task 5. Fix subagent does not receive the field → Task 5 Step 1. `harness: tested` accepted, `(reviewer probe not reviewer-safe)` → Tasks 4 and 5.
- Error handling (premise test in the rule; ambiguous result; shared-checkout breach) → rule text in Tasks 2–3; Error Handling bullets in Tasks 4–5.
- Testing strategy items 1–6 → Task 1; `CLAUDE.md` line → Task 6; existing fast suites re-run → Tasks 3, 5, 6.
- Interfaces: pathspec line and marker untouched (Task 1 section 6 guards; Tasks 2–5 never edit them); reason strings free text; no new disposition.
- Non-goals honoured: no hook, no `skill-rules.json`, no version bump, no behavioural run, no `docs/orchestration-issues.md` edit.

**2. Placeholder scan.** No "TBD", "TODO", "similar to Task N", or "add validation". Every code step carries the full text. The rule block is repeated verbatim in Task 3 rather than referenced.

**3. Type consistency.** Strings are identical across tasks: `harness: tested —`, `harness: untested —`, `harness probe —`, `harness probe not runnable here`, `Harness probes owed:`, `— harness probe: <observation>`, `(reviewer probe not reviewer-safe)`, `dispatch would not block`, `no probe named`, `not settled by one probe; first: <probe>`. The test variables in Task 1 (`FIELD_TESTED`, `FIELD_UNTESTED`, `REASON_PROBE`, `REASON_NOT_RUNNABLE`, `OWED_LINE`, `GUARD`) match those strings. Cross-references inside each SKILL.md (`3.1`/`3.2` in doc review; `item 1`/`item 2` in code review) match the numbering written in that file.

**4. Scope-reduction scan.** No "v1", "basic", "simple", "for now", "placeholder", "initial version", "minimal". The rule length (about 24 lines) exceeds the spec's "near 15" guideline; the spec marks that guideline as asserted by no test, and the plan header records the reason.
