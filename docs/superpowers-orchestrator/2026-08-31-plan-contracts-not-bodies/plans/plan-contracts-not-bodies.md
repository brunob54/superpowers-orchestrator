# Plan Contracts, Not Literal Bodies — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `writing-plans` produce plans that bind contracts (falsifiable properties plus verification) instead of literal bodies, add matching review-lens targets to `multi-doc-review`, and pin the new wording with fast grep test suites.

**Spec:** `docs/superpowers-orchestrator/2026-08-31-plan-contracts-not-bodies/specs/plan-contracts-not-bodies-design.md` *(multi-doc-review reads this line to locate the spec on direct plan reviews; an old-layout path here would produce a plan whose spec is outside the layout)*

**Architecture:** Two skill files gain wording: `skills/writing-plans/SKILL.md` gets a new normative section ("Contracts and Literal Bodies"), a Task Template field (`**Contract:**`), a Plan Header authority note, a fifth Self-Review check, and one reconciliation sentence in "No Placeholders"; `skills/multi-doc-review/SKILL.md` gets three finding targets in the plan cell of the Ambiguity & testability lens. Every piece of new wording is pinned by a fast grep suite written first (TDD at the wording level): a new suite `tests/writing-plans/run-tests.sh` and one new check section in `tests/reviewer-templates/run-tests.sh`. A final on-disk-only edit adds the new suite to the Testing list in the gitignored `CLAUDE.md`.

**Tech Stack:** Markdown (skill files), plain bash + grep/awk (test suites, same style as `tests/reviewer-templates/run-tests.sh`). No Node, no `claude` invocation, no hook changes.

**Assumptions:**
- Assumes `skills/writing-plans/SKILL.md` in this repository is identical to the installed 7.6.0 copy (verified at plan time with `diff` — they are identical), so the section anchors `## Plan Header`, `## Task Rules`, `## Task Template`, `## No Placeholders`, `## Self-Review` exist exactly as named. Will NOT work if a concurrent change renames or removes one of these headings.
- Assumes `CLAUDE.md` is gitignored in this clone (verified at plan time: `.gitignore` line 7). Will NOT work if a future clone tracks `CLAUDE.md` — Task 6 would then need a different delivery for the Testing-list line.
- Assumes the Task Template fenced block is the only 4-backtick (` ```` `) fence after the `## Task Template` heading, and the Plan Header fenced block is the first 3-backtick fence after the `## Plan Header` heading (both true today). The block-scoped test helpers rely on this.
- Assumes the Ambiguity & testability lens cell in `skills/multi-doc-review/SKILL.md` keeps its current shape: a `**Ambiguity & testability**` line followed by `- spec:` / `- plan:` / `- general:` bullets (true today, lines 317–327).

**Global Constraints:**
- Binding literal labels, matched exactly and case-sensitively (`grep -F`): `## Contracts and Literal Bodies` (heading), `**Exact content:**`, `**Contract:**` (the latter asserted inside the Task Template fenced block). These are byte pins — do not reword them.
- Binding free-text fragments, matched case-insensitively (`grep -iF`): "ordinary fix", "together as one ordinary fix", "falsifiable", "reference implementations" (asserted inside the Plan Header fenced template), "no stated contract" and "self-pin" (asserted inside the Ambiguity & testability plan cell). The sentences carrying them may be reworded as long as the fragment and the spec-bound properties survive.

> **Amended 2026-08-31 (code review [I1]):** The `multi-doc-review` gate now switches on the byte-pin label `**Body authority:**`, not on the free-text phrase "reference implementations". `**Body authority:**` joins the binding literal labels above (byte pin, exact match).
- All other new wording in this plan's code blocks is reference wording: the spec (section "Design", preamble) explicitly allows rewording it as long as the bound properties hold.
- No change to `skills/multi-code-review/**`, no hook/activation/packaging change, no file in `hooks/` touched, no skill added or renamed (spec Non-goals).
- Never `git add` or commit `CLAUDE.md` — the Task 6 edit is on-disk only (spec R8).
- Verification uses only the fast suites: `bash tests/writing-plans/run-tests.sh`, `bash tests/reviewer-templates/run-tests.sh`, `bash tests/codex/run-unit-tests.sh`. No behavioural suite runs in this workstream (spec Non-goals).
- New test code follows the `tests/reviewer-templates/run-tests.sh` style: plain bash, `set -u`, per-check `PASS`/`FAIL` lines, failures accumulated and all checks printed, exit non-zero at the end when any check failed, no `/dev/stdin`, no process substitution.

---

## File Structure

- `tests/writing-plans/run-tests.sh` — **create** (Task 1, extended in Tasks 2–4). Static wording checks on `skills/writing-plans/SKILL.md`.
- `skills/writing-plans/SKILL.md` — **modify** (Tasks 1–4). New section between "Task Rules" and "Task Template"; one sentence appended to "No Placeholders"; one field added to the Task Template; one note added to the Plan Header template; one check added to Self-Review.
- `tests/reviewer-templates/run-tests.sh` — **modify** (Task 5). One new check section for the Ambiguity & testability plan cell.
- `skills/multi-doc-review/SKILL.md` — **modify** (Task 5). Three finding targets added to the plan cell of the Ambiguity & testability lens.
- `CLAUDE.md` — **modify on disk only** (Task 6). One line in the Testing list. Never staged, never committed.

Tasks 1–6 run strictly in order. Tasks 1–4 are sequential (same two files). Task 5 touches different files but is NOT independent of Tasks 1–4: its Step 4 verification runs `bash tests/writing-plans/run-tests.sh` and expects the 7-check pass state that exists only after Task 4 — do not dispatch Task 5 in parallel with or before Tasks 1–4. Task 6 is last (final verification over everything).

---

### Task 1: Wording suite skeleton + "Contracts and Literal Bodies" section (spec R1, R7, part of R6)

**Files:**
- Create: `tests/writing-plans/run-tests.sh`
- Modify: `skills/writing-plans/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** the Task Template `**Contract:**` field (Task 2), the Plan Header note (Task 3), the Self-Review check (Task 4), any lens change (Task 5). The new section's rules do not change how THIS plan is reviewed — they take effect only for plans generated after a release installs the changed skill (spec Rollout).

Binding in this task: the heading `## Contracts and Literal Bodies`, the label `**Exact content:**`, the fragments "ordinary fix" and "together as one ordinary fix". The rest of the section text below is reference wording — rewordable while the spec R1 properties hold.

- [x] **Step 1: Write the failing test suite**

Create `tests/writing-plans/run-tests.sh` with this content:

```bash
#!/usr/bin/env bash
# writing-plans wording test suite: static checks on
# skills/writing-plans/SKILL.md for the contracts-not-bodies rules.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows).
#
# Matching rule (design R6): binding literal labels are byte pins, matched
# exactly and case-sensitively (grep -F); free-text fragments are matched
# case-insensitively (grep -iF) because free text gets reworded by review
# fixes.
#
# Contract source: docs/superpowers-orchestrator/
# 2026-08-31-plan-contracts-not-bodies/specs/
# plan-contracts-not-bodies-design.md, section R6.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$ROOT/skills/writing-plans/SKILL.md"

# Binding literal labels (byte pins).
SECTION_HEADING='## Contracts and Literal Bodies'
EXACT_LABEL='**Exact content:**'

# Binding free-text fragments.
FRAG_ORDINARY_FIX='ordinary fix'
FRAG_SELF_PIN='together as one ordinary fix'

PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

# Byte-pin match: exact, case-sensitive.
assert_exact() { # desc needle
  if grep -qF -- "$2" "$SKILL"; then ok "$1"; else bad "$1 (missing: $2)"; fi
}

# Free-text fragment match: case-insensitive.
assert_fragment() { # desc needle
  if grep -qiF -- "$2" "$SKILL"; then ok "$1"; else bad "$1 (missing: $2)"; fi
}

# Line number of the first line containing the fixed string $1; empty when
# absent.
first_line_of() { grep -nF -- "$1" "$SKILL" | head -n 1 | cut -d: -f1; }

# Line number of the first line after line $2 whose text starts with $1;
# empty when absent.
line_starting_with_after() {
  awk -v pfx="$1" -v start="$2" \
    'NR > start && index($0, pfx) == 1 { print NR; exit }' "$SKILL"
}

# Assert that string $2 occurs inside the fenced block that follows heading
# $3. $4 is the fence prefix ("```" or "````"); $5 is the match mode:
# "exact" (case-sensitive) or "fragment" (case-insensitive).
assert_in_block() { # desc needle heading fence mode
  local desc="$1" needle="$2" heading="$3" fence="$4" mode="$5"
  local h open close hit
  h="$(first_line_of "$heading")"
  if [ -z "$h" ]; then bad "$desc (no heading: $heading)"; return; fi
  open="$(line_starting_with_after "$fence" "$h")"
  if [ -z "$open" ]; then bad "$desc (no $fence fence after the heading)"; return; fi
  close="$(line_starting_with_after "$fence" "$open")"
  if [ -z "$close" ]; then bad "$desc (no closing $fence fence)"; return; fi
  if [ "$mode" = "exact" ]; then
    hit="$(awk -v needle="$needle" -v a="$open" -v b="$close" \
      'NR > a && NR < b && index($0, needle) > 0 { print NR; exit }' "$SKILL")"
  else
    hit="$(awk -v needle="$needle" -v a="$open" -v b="$close" \
      'NR > a && NR < b && index(tolower($0), tolower(needle)) > 0 { print NR; exit }' "$SKILL")"
  fi
  if [ -n "$hit" ]; then
    ok "$desc (line $hit, block $open..$close)"
  else
    bad "$desc (not inside block $open..$close)"
  fi
}

bold "1. Contracts and Literal Bodies section (R1)"
assert_exact "section heading '$SECTION_HEADING'" "$SECTION_HEADING"
assert_exact "exact-content label '$EXACT_LABEL'" "$EXACT_LABEL"
assert_fragment "authority-default fragment '$FRAG_ORDINARY_FIX'" "$FRAG_ORDINARY_FIX"
assert_fragment "self-pin fragment '$FRAG_SELF_PIN'" "$FRAG_SELF_PIN"

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
```

*(The helpers `assert_in_block` and `first_line_of` are unused until Tasks 2–3 — they are defined here once so later tasks only append check sections. `EXACT_LABEL` deliberately does not yet occur in the skill file.)*

- [x] **Step 2: Run the suite to verify it fails**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: FAIL — exit code 1, `Results: 0 passed, 4 failed` (heading, label, and both fragments are all absent from the current skill file; the current file contains none of "ordinary fix", "Exact content", or the section heading).

- [x] **Step 3: Add the section and the "No Placeholders" sentence**

In `skills/writing-plans/SKILL.md`, insert the following section, followed by one blank line, immediately **before** the line `## Task Template` (i.e. between "Task Rules" and "Task Template", so the template's new field in Task 2 has its definition above it):

```markdown
## Contracts and Literal Bodies

A **contract** is the set of properties an artifact must guarantee, stated
so that a check can falsify them. A **reference implementation** is a
concrete body (a code block or quoted text) that satisfies the contract:
it shows one way, it does not bind.

1. **State a contract for every governed artifact.** For every helper,
   function, command, or piece of wording a task introduces or modifies,
   state the contract in the task's `**Contract:**` field: the invariants
   that must hold and the verification (a runnable command or check) that
   would falsify them; for code artifacts also inputs and outputs. A task
   that creates or modifies several artifacts holds one entry per artifact
   in the same field (a list) — or is a candidate for splitting.
   Procedural step blocks that operate the pipeline rather than build the
   feature — the Step 5 commit command, `Run:` verification lines — need
   no contract entry; rule 3's default covers them. The boundary is a
   test, not a feeling: a block is procedural exactly when it creates or
   modifies no file named in the task's `**Files:**` list. Two contract
   shapes exist — code artifact and wording artifact — shown in the
   examples below.

> **Amended 2026-08-31 (code review [I3], [M3]):** Rule 1's boundary test
> changed from the relational form above (the task's `**Files:**` list)
> to an intrinsic, working-tree-scoped test with a fail-closed tie-break;
> the orphaned `**Files:**`-list completeness clause was deleted. See the
> design's Amendments section for the full ruling. The actual wording
> committed to `skills/writing-plans/SKILL.md` rule 1 reads: "The test is
> intrinsic to the block: it asks what the block itself does to the
> working tree, never what any list elsewhere in the task records. A
> block is procedural exactly when it creates, modifies, or deletes no
> file in the working tree. … a procedural block only runs pipeline
> commands — the two canonical forms are the Step 5 commit block and a
> verification `Run:` line; the Step 5 commit block qualifies because it
> writes the git index and git objects but no working-tree file. When it
> is unclear whether a block writes a working-tree file, treat the block
> as not procedural — ambiguity produces a contract entry, never a
> silent exemption."

> **Amended 2026-08-31 (code review [I3], round 3):** The quote above is
> superseded. Rule 1's boundary sentence was restated in conjunctive form
> so it is identical to the same test already committed to Self-Review
> check 5 bucket (c) and to `skills/multi-doc-review/SKILL.md`'s plan
> lens cell. The actual wording committed to `skills/writing-plans/SKILL.md`
> rule 1 now reads: "A block is procedural when it creates, modifies, or
> deletes no file in the working tree, running only pipeline commands —
> the two canonical forms are the Step 5 commit block and a verification
> `Run:` line; the Step 5 commit block qualifies because it writes the
> git index and git objects but no working-tree file. This is the one
> test for "procedural" used everywhere in the plan you are writing and
> in review. When it is unclear whether a block meets this test, treat
> the block as not procedural — ambiguity produces a contract entry,
> never a silent exemption." Reason: read literally, the earlier
> "exactly when" phrasing stated the test over the file-writing clause
> alone, which would make any inert quoted-wording body procedural —
> inverting the intent for the wording-artifact contract shape.

> **Amended 2026-08-31 (code review [M5], round 4):** The quote above is
> superseded. "Running only pipeline commands" is vacuously true of a
> block that runs no command at all, so a task step whose body is
> markdown wording to be inserted into a file — creating no working-tree
> file itself and running no command — passed both conjuncts and read as
> procedural, exempting every wording artifact from a contract entry. The
> command conjunct is now stated positively. The actual wording committed
> to `skills/writing-plans/SKILL.md` rule 1 now reads: "A block is
> procedural when it creates, modifies, or deletes no file in the working
> tree, and runs at least one command, every command it runs being a
> pipeline command — the two canonical forms are the Step 5 commit block
> and a verification `Run:` line; the Step 5 commit block qualifies
> because it writes the git index and git objects but no working-tree
> file. This is the one test for "procedural" used everywhere in the plan
> you are writing and in review. When it is unclear whether a block meets
> this test, treat the block as not procedural — ambiguity produces a
> contract entry, never a silent exemption." The same predicate change is
> applied identically to Self-Review check 5 bucket (c) and to
> `skills/multi-doc-review/SKILL.md`'s plan lens cell — see the design's
> Amendments section.

> **Amended 2026-08-31 (code review [M4], round 4 verification 1):** The
> quote above is superseded. The `Run:`-line example named a verification
> `Run:` line as a canonical procedural form unconditionally, while the
> predicate itself requires the block to write no working-tree file — a
> `Run:` line invoking a formatter, a snapshot-updating test, or a
> fixture regenerator satisfied the example but failed the predicate. The
> actual wording committed to `skills/writing-plans/SKILL.md` rule 1 now
> reads: "…the two canonical forms are the Step 5 commit block and a
> verification `Run:` line, though a `Run:` line is a procedural form only
> when the command it runs writes no working-tree file; the Step 5 commit
> block qualifies because it writes the git index and git objects but no
> working-tree file. …" The same qualifier is applied identically to
> Self-Review check 5 bucket (c) and to
> `skills/multi-doc-review/SKILL.md`'s plan lens cell — see the design's
> Amendments section.

2. **Pin an interface only when something outside the plan depends on
   it.** An interface (signature, flag set, file format) is pinned in the
   contract only when something *outside the plan* already depends on it.
   Stating inputs and outputs in the `**Contract:**` field does not pin
   them: a concrete signature written there is descriptive — part of the
   reference implementation — unless the external-dependency condition
   holds, and a fix may amend the signature together with the contract's
   inputs/outputs wording as one ordinary fix.

3. **Bodies are reference implementations by default.** Code blocks and
   quoted wording in task steps are reference implementations. The
   implementer follows them as written; a later review finding against
   such a body is an **ordinary fix** so long as the stated contract still
   holds. Only a change that breaks or amends the contract itself is a
   plan conflict.

4. **Mark exact content explicitly.** A block is binding byte-for-byte
   only when the line immediately above the fenced block or block quote it
   pins reads `**Exact content:** <reason>`. The reason must name the
   *external* pin: a pre-existing test asserting the string, another file
   that must already match byte-for-byte, or user-approved copy — and a
   user-approval reason must cite where the approval is recorded (a spec
   section, a review-log disposition, or a plan amendment quote); an
   uncited approval claim is not a valid reason. A marker with no reason
   is a plan failure of the same class as the "No Placeholders" patterns.
   Never place the marker inline on the same line as the content it pins.

5. **A self-pin never justifies the marker.** A pin the plan itself
   introduces (the plan also writes the test that asserts the string, or
   also writes the matching file) does not justify `**Exact content:**`:
   body and pin are amendable **together as one ordinary fix** — the fix
   changes the text and its pinning test in the same commit. The same
   applies to a *pre-existing* pin whose assertion the same plan edits: a
   pin the plan controls is a self-pin, whatever its age. Only a pin the
   plan leaves untouched binds. Circular reasons — a reason citing an
   artifact the same plan creates or modifies — are a plan failure.

6. **Boundaries.**
   (a) This section defines the *authority* of bodies; it does not license
   vague steps — the "No Placeholders" rules still require actual code.
   (b) The default never applies to the plan header's
   `**Global Constraints:**` block, which binds as stated; a conflict with
   a global constraint is genuine and stops the run.
   (c) Other non-task plan content (header prose such as
   `**Architecture:**` and `**Assumptions:**`, the File Structure section)
   follows the same reference default: findings against it are ordinary
   fixes unless they contradict a stated contract or a global constraint.
   (d) A finding against a body in a task whose field reads
   `**Contract:** none — <reason>` is an ordinary fix under rule 3's
   default — there is no contract to break.
   (e) The implementer follows the reference body; the contract governs
   later findings.

**Example — code artifact contract:**

> **Contract:** `assert_round_reviewers <log> <round> <m> <required|optional>`
> - Inputs: review-log path, round number, expected reviewer count M, an
>   expectation mode supplied by the caller.
> - Output: exit 0 only when the round entry demonstrates M reviewers per
>   lens and every consolidated finding maps to reviewer sources.
> - Invariants: mode `required` makes a `Sources mapped: 0/0` entry fail;
>   mode `optional` keeps the documented skip; a missing or misspelled
>   mode fails.
> - Verification: synthetic-fixture checks covering both modes × both
>   outcomes, bad mode, missing round entry.
> - Interface not externally pinned — the signature above is descriptive
>   and may change in a fix (rule 2).

**Example — wording artifact contract:**

> **Contract:** model-probe example in `reviewer-prompt.md`
> - Must convey: a reviewer asserting a harness property runs a probe; the
>   probe prompt must not name the canary token.
> - Invariant: no example places the token inside the probe prompt text.
> - Verification: `bash tests/reviewer-templates/run-tests.sh` asserts the
>   section exists and the example probe omits the token.
> - Sentence wording is free; the properties above bind.
```

Then append this sentence (spec R7) as a new final paragraph of the `## No Placeholders` section, after its bullet list:

```markdown
These patterns are about *content completeness*; the "Contracts and
Literal Bodies" section defines the *authority* of that content. A body
must still be actual code or actual wording even when it binds only as a
reference implementation.
```

*(Note for Step 3: the section text above deliberately avoids the word "falsifiable" — Task 4's failing-test step depends on that word being absent until Task 4 adds it. It says "falsify", which the case-insensitive fragment `falsifiable` does not match.)*

- [x] **Step 4: Run the suite to verify it passes**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: PASS — exit code 0, `Results: 4 passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add tests/writing-plans/run-tests.sh skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): add Contracts and Literal Bodies section with wording suite" --trailer "Session: plan-contracts-not-bodies" --trailer "Stage: task 1/6"
```

---

### Task 2: Task Template `**Contract:**` field (spec R2)

**Files:**
- Modify: `tests/writing-plans/run-tests.sh`
- Modify: `skills/writing-plans/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** the meaning of the field — that lives in Task 1's section. This task only adds the field line to the template and its block-scoped test.

Binding in this task: the literal label `**Contract:**` inside the Task Template fenced block. The parenthetical instruction is reference wording, but must keep two properties (spec R2): it points at the "Contracts and Literal Bodies" section and it names the two shapes (code artifact, wording artifact).

- [x] **Step 1: Add the failing block-scoped check**

In `tests/writing-plans/run-tests.sh`, add to the variable definitions (after the line `EXACT_LABEL='**Exact content:**'`):

```bash
CONTRACT_LABEL='**Contract:**'
```

and insert this check section immediately before the `echo` line that precedes the `Results:` footer:

```bash
bold "2. Task Template Contract field (R2)"
assert_in_block "Task Template block carries '$CONTRACT_LABEL'" \
  "$CONTRACT_LABEL" '## Task Template' '````' exact
```

- [x] **Step 2: Run the suite to verify the new check fails**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: FAIL — exit code 1, `Results: 4 passed, 1 failed`; the failing line names the Task Template block. (`**Contract:**` already occurs in the file from Task 1's section, but not *inside* the 4-backtick Task Template block — the block-scoped helper is what makes this check meaningful.)

- [x] **Step 3: Add the field to the Task Template**

In `skills/writing-plans/SKILL.md`, inside the Task Template fenced block (the ` ````markdown ` block under `## Task Template`), insert the following line as its own paragraph directly **after** the `**Does NOT cover:**` line's paragraph and before Step 1:

```markdown
**Contract:** *(one entry per artifact this task creates or modifies: the invariants that must hold and the verification that would falsify them; inputs and outputs for code artifacts. See "Contracts and Literal Bodies" for the two shapes — code artifact and wording artifact. Write `none — <reason>` when the task creates or modifies nothing a later review finding could be judged against.)*
```

- [x] **Step 4: Run the suite to verify it passes**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: PASS — exit code 0, `Results: 5 passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add tests/writing-plans/run-tests.sh skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): add Contract field to the Task Template" --trailer "Session: plan-contracts-not-bodies" --trailer "Stage: task 2/6"
```

---

### Task 3: Plan Header authority note (spec R3)

**Files:**
- Modify: `tests/writing-plans/run-tests.sh`
- Modify: `skills/writing-plans/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** how controllers *use* the note at triage time — spec Non-goals places delivery on the controller side and changes no controller skill. Plans without the note keep their old authority (spec Non-goals); this task adds no compatibility logic anywhere.

Binding in this task: the fragment "reference implementations" inside the Plan Header fenced template. The note's other sentences are reference wording, but must keep the R3 properties: reference-default for fenced/quoted task-step bodies, ordinary fix while the contract holds, `**Exact content:**` as the only byte-for-byte binding, and `**Global Constraints:**` binding as stated.

- [x] **Step 1: Add the failing block-scoped check**

In `tests/writing-plans/run-tests.sh`, add to the variable definitions (after `FRAG_SELF_PIN=...`):

```bash
FRAG_REF_IMPL='reference implementations'
```

and insert this check section immediately before the `echo` line that precedes the `Results:` footer (after the Task 2 section):

```bash
bold "3. Plan Header authority note (R3)"
assert_in_block "Plan Header template carries '$FRAG_REF_IMPL'" \
  "$FRAG_REF_IMPL" '## Plan Header' '```' fragment
```

- [x] **Step 2: Run the suite to verify the new check fails**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: FAIL — exit code 1, `Results: 5 passed, 1 failed`. ("reference implementations" occurs in Task 1's section, but not inside the Plan Header fenced block — again the block scoping is what the check tests.)

- [x] **Step 3: Add the note to the Plan Header template**

In `skills/writing-plans/SKILL.md`, inside the Plan Header fenced block (the ` ```markdown ` block under `## Plan Header`), extend the existing `> **For agentic workers:** …` block quote with a second paragraph — add these two lines directly after the `> **For agentic workers:** …` line (same block-quote mechanism, so the rule travels inside every generated plan to reviewers who never read this skill):

```markdown
>
> **Body authority:** Fenced code blocks and block-quoted wording in task steps are reference implementations for the task's stated `**Contract:**`. A review finding against such a body is an ordinary fix while the contract holds; only blocks marked `**Exact content:**` bind byte-for-byte. The `**Global Constraints:**` block binds as stated.
```

> **Amended 2026-08-31 (code review [I1], round 3):** The quote above is
> superseded. Design R3 bullet 2 requires the note to state both that the
> `**Global Constraints:**` block binds as stated AND that the note
> itself binds as stated alongside it; the wording above stated only the
> first half. The actual wording committed to `skills/writing-plans/SKILL.md`'s
> Plan Header note now ends: "The `**Global Constraints:**` block binds
> as stated, and this note binds as stated alongside it." The first half
> of the note's wording is unchanged.

> **Amended 2026-08-31 (code review [I1], round 4):** The quote above is
> superseded again. Rule 6(b) carves out one exception to the
> `**Global Constraints:**` bind — an entry failing the two-part self-pin
> test is an ordinary fix, not a plan conflict — and the note is the only
> copy of that rule a review controller actually reads at triage time, so
> the note now states the same exception. The actual wording committed to
> `skills/writing-plans/SKILL.md`'s Plan Header note now ends: "The
> `**Global Constraints:**` block binds as stated — except an entry
> failing the two-part self-pin test (rule 6(b)), which is an ordinary
> fix — and this note binds as stated alongside it." The first half of
> the note's wording is unchanged.

> **Amended 2026-08-31 (code review [I2], [I3], round 4 verification 1):**
> The quote above is superseded. The note is the only copy of the
> body-authority regime a review controller ever reads — it reads the
> plan, never `skills/writing-plans/SKILL.md` — so every rule the note
> states must be decidable from the note alone: no cross-reference to a
> rule number that exists only in the skill file, and no undecidable
> reading. The actual wording committed to
> `skills/writing-plans/SKILL.md`'s Plan Header note now reads in full:
> "Fenced code blocks and block-quoted wording in task steps are reference
> implementations for the task's stated `**Contract:**`. A review finding
> against such a body is an ordinary fix while the contract holds; a block
> marked `**Exact content:**` binds byte-for-byte unless its reason names
> a pin the plan itself writes or edits, in which case it is a self-pin
> and body and pin are amendable together as one ordinary fix. The
> `**Global Constraints:**` block binds as stated, except an entry that
> both does not trace to the spec named on the plan's `**Spec:**` line
> and restates the body of an artifact the plan itself creates or
> modifies, which is an ordinary fix; every other entry binds as stated —
> and this note binds as stated alongside it." See the design's
> Amendments section for the full ruling.

> **Amended 2026-09-01 (code review [I1], [I2], round 4 verification 2):**
> The quote above is superseded. Rules 6(c), 6(d), and 4's no-reason case
> had no counterpart in the note, so a controller triaging a finding
> against them at the note alone found nothing covering the case. The
> actual wording committed to `skills/writing-plans/SKILL.md`'s Plan
> Header note now reads in full: "Fenced code blocks and block-quoted
> wording in task steps are reference implementations for the task's
> stated `**Contract:**`. Other non-task plan content — header prose such
> as `**Architecture:**` and `**Assumptions:**`, and the File Structure
> section — follows the same reference default: a finding against it is
> an ordinary fix unless it contradicts a stated contract or a global
> constraint. A finding against a body in a task whose `**Contract:**`
> field reads `none — <reason>` is an ordinary fix, because there is no
> contract to break. A review finding against such a body is an ordinary
> fix while the contract holds; a block marked `**Exact content:**` binds
> byte-for-byte unless its reason names a pin the plan itself writes or
> edits, in which case it is a self-pin and body and pin are amendable
> together as one ordinary fix. A block marked `**Exact content:**` with
> no reason does not bind byte-for-byte; the body is an ordinary fix, and
> the missing reason is itself a finding. The `**Global Constraints:**`
> block binds as stated, except an entry that both does not trace to the
> spec named on the plan's `**Spec:**` line and restates the body of an
> artifact the plan itself creates or modifies, which is an ordinary fix;
> every other entry binds as stated — and this note binds as stated
> alongside it." See the design's Amendments section for the full ruling.

- [x] **Step 4: Run the suite to verify it passes**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: PASS — exit code 0, `Results: 6 passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add tests/writing-plans/run-tests.sh skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): add body-authority note to the Plan Header template" --trailer "Session: plan-contracts-not-bodies" --trailer "Stage: task 3/6"
```

---

### Task 4: Self-Review check 5 (spec R4)

**Files:**
- Modify: `tests/writing-plans/run-tests.sh`
- Modify: `skills/writing-plans/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** enforcement by reviewers — that is Task 5's lens change. This check is the plan writer's own audit, run inline like the existing four checks.

Binding in this task: the fragment "falsifiable". The check's wording is otherwise reference wording, but must keep the R4 properties: three buckets for every fenced/quoted body (contract-covered, `**Exact content:**`-marked, or procedural), external-and-untouched pins with the circular case called out, falsifiability of every contract, and the false-`none` case.

- [x] **Step 1: Add the failing check**

In `tests/writing-plans/run-tests.sh`, add to the variable definitions (after `FRAG_REF_IMPL=...`):

```bash
FRAG_FALSIFIABLE='falsifiable'
```

and insert this check section immediately before the `echo` line that precedes the `Results:` footer (after the Task 3 section):

```bash
bold "4. Self-Review contract audit (R4)"
assert_fragment "self-review fragment '$FRAG_FALSIFIABLE'" "$FRAG_FALSIFIABLE"
```

- [x] **Step 2: Run the suite to verify the new check fails**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: FAIL — exit code 1, `Results: 6 passed, 1 failed`. (Task 1's section says "falsify", which the fragment `falsifiable` does not match, so the word is still absent.)

- [x] **Step 3: Add the fifth Self-Review check**

In `skills/writing-plans/SKILL.md`, section `## Self-Review`, insert the following paragraph after the `**4. Scope-reduction scan:** …` paragraph and before the closing "If you find issues…" paragraph:

```markdown
**5. Contract audit:** Every fenced block or quoted wording in the plan is in one of three buckets: (a) it falls under its task's stated `**Contract:**`; (b) it carries an `**Exact content:**` marker; or (c) it is a procedural step block (verification command, commit command) covered by the reference default of "Contracts and Literal Bodies" rule 3. Every marker's reason names a pin external to the plan and untouched by it — a reason citing an artifact this same plan creates or modifies is circular and invalid. Every `**Contract:**` field is falsifiable: a contract no check could fail ("must work correctly") is treated as missing, and so is a `none — <reason>` field on a task that does create or modify a governed artifact (a false `none`).
```

> **Amended 2026-08-31 (code review [I3], [M3]):** The actual wording committed to `skills/writing-plans/SKILL.md` Self-Review check 5, bucket (c), reads: "it is a procedural step block under rule 1's test — it creates, modifies, or deletes no file in the working tree, running only pipeline commands such as the Step 5 commit block or a verification `Run:` line, with an unclear case treated as not procedural — covered by the reference default …". Same predicate as rule 1's amended boundary test; see the design's Amendments section.

> **Amended 2026-08-31 (code review [M5], round 4):** The quote above is superseded. The command conjunct is now stated positively, so a block that runs no command at all does not qualify as procedural. The actual wording committed to `skills/writing-plans/SKILL.md` Self-Review check 5, bucket (c), now reads: "it is a procedural step block under rule 1's test — it creates, modifies, or deletes no file in the working tree, and runs at least one command, every command it runs being a pipeline command, such as the Step 5 commit block or a verification `Run:` line, with an unclear case treated as not procedural — covered by the reference default …". Same predicate as rule 1's amended boundary test; see the design's Amendments section.

> **Amended 2026-08-31 (code review [M4], round 4 verification 1):** The quote above is superseded. The actual wording committed to `skills/writing-plans/SKILL.md` Self-Review check 5, bucket (c), now reads: "it is a procedural step block under rule 1's test — it creates, modifies, or deletes no file in the working tree, and runs at least one command, every command it runs being a pipeline command, such as the Step 5 commit block or a verification `Run:` line (a `Run:` line is a procedural form only when the command it runs writes no working-tree file), with an unclear case treated as not procedural — covered by the reference default …". Same qualifier as rule 1's amended boundary test; see the design's Amendments section.

- [x] **Step 4: Run the suite to verify it passes**

Run: `bash tests/writing-plans/run-tests.sh`
Expected: PASS — exit code 0, `Results: 7 passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add tests/writing-plans/run-tests.sh skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): add contract audit as Self-Review check 5" --trailer "Session: plan-contracts-not-bodies" --trailer "Stage: task 4/6"
```

---

### Task 5: Ambiguity & testability lens targets + reviewer-templates check (spec R5, part of R6)

**Files:**
- Modify: `tests/reviewer-templates/run-tests.sh`
- Modify: `skills/multi-doc-review/SKILL.md`

**Security flag:** `none`

**Does NOT cover:** any other lens or cell of the rotation (the spec confines the change to the plan cell of Ambiguity & testability — a second lens would duplicate findings under the rotation); any change to `skills/multi-code-review/**`; reviewer behaviour on plans **without** the authority note — the new targets are gated on the note's phrase, and a plan lacking it is reviewed under today's lens text only (spec Non-goals). If a plan carries the note phrase outside its header the gate would still fire — accepted: the phrase is asserted into the header template by Task 3, so generated plans carry it there.

Binding in this task: the fragments "no stated contract" and "self-pin" inside the plan cell. The rest of the cell wording is reference wording, but must keep the R5 properties: three targets (uncontracted bodies with the false-`none` case and the procedural exemption; vacuous/unverifiable contracts; markers with missing or self-pinning reasons), gated on the header phrase "reference implementations".

> **Amended 2026-08-31 (code review [I1], [I2]):** The gate is now the byte-pin label `**Body authority:**`, not the phrase "reference implementations". A fourth target applies too: a `**Global Constraints:**` entry that fails a decidable two-part test (does not trace to the spec, and restates a body the plan itself creates or modifies) is a self-pin in disguise and is flagged. A plan with `**Contract:**` fields but no `**Body authority:**` label is itself flagged as an inconsistent regime.

- [x] **Step 1: Add the failing checks to the reviewer-templates suite**

In `tests/reviewer-templates/run-tests.sh`, add this helper after the existing `assert_file_contains()` definition:

```bash
assert_file_contains_i() { # desc file needle (case-insensitive)
  if grep -qiF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
```

and insert this check section immediately before the `echo` line that precedes the `Results:` footer (after section 6):

```bash
bold "7. Ambiguity & testability plan-cell contract targets"
AMB_PLAN_CELL="$WORK/ambiguity-plan-cell.txt"
awk '
  $0 == "**Ambiguity & testability**" { inlens = 1; next }
  inlens && /^\*\*/ { exit }
  inlens && /^- plan:/ { incell = 1; print; next }
  incell && /^- / { incell = 0 }
  incell { print }
' "$DOC_SKILL" > "$AMB_PLAN_CELL"
if [ -s "$AMB_PLAN_CELL" ]; then
  ok "multi-doc-review SKILL.md: Ambiguity plan-cell extract is non-empty"
else
  bad "multi-doc-review SKILL.md: Ambiguity plan-cell extract is empty"
fi
assert_file_contains_i "Ambiguity plan cell: fragment 'no stated contract'" "$AMB_PLAN_CELL" 'no stated contract'
assert_file_contains_i "Ambiguity plan cell: fragment 'self-pin'" "$AMB_PLAN_CELL" 'self-pin'
```

- [x] **Step 2: Run the suite to verify the new checks fail**

Run: `bash tests/reviewer-templates/run-tests.sh`
Expected: FAIL — exit code 1; all pre-existing checks still PASS, the extract check passes (the cell exists today), and exactly the two new fragment checks FAIL.

- [x] **Step 3: Extend the plan cell**

In `skills/multi-doc-review/SKILL.md`, section `## Lens Instructions`, lens `**Ambiguity & testability**`, replace the entire `- plan:` bullet — in the file it is wrapped across three lines (its unwrapped text is: `- plan: Find: placeholder patterns (TBD, "add appropriate...", steps without code); vague steps; missing or unverifiable verification commands; steps interpretable two ways.`); replace the whole wrapped bullet, not a one-line exact string — with:

```markdown
- plan: Find: placeholder patterns (TBD, "add appropriate...", steps without
  code); vague steps; missing or unverifiable verification commands; steps
  interpretable two ways. When the plan header contains the phrase
  "reference implementations" (the body-authority note), also find:
  task-step bodies of artifacts the task creates or modifies that fix
  behaviour with no stated contract — a `**Contract:** none — <reason>`
  field on a task that does create or modify a governed artifact counts as
  no stated contract; procedural step blocks (verification commands, commit
  commands) are exempt; contracts that are vacuous or unverifiable (no
  check could falsify them); `**Exact content:**` markers with no reason,
  or whose reason cites an artifact the same plan creates or modifies (a
  self-pin). A plan whose header lacks that phrase predates the contract
  rules — review it under the first sentence of this cell only.
```

> **Amended 2026-08-31 (code review [I1], [I2]):** The actual wording committed to `skills/multi-doc-review/SKILL.md` gates on the label `**Body authority:**` instead of the phrase "reference implementations", adds the inconsistent-regime guard, and adds a fourth target for `**Global Constraints:**` self-pins in disguise — see the design's Amendments section for the full ruling.

> **Amended 2026-08-31 (code review [I3], [M3]):** The plan-cell's procedural-block exemption also gates on the amended, intrinsic working-tree test rather than the task's `**Files:**` list. The actual wording committed to `skills/multi-doc-review/SKILL.md` reads: "procedural step blocks — those that create, modify, or delete no file in the working tree, running only pipeline commands (the Step 5 commit block, a verification `Run:` line) with an unclear case treated as not procedural — are exempt". Same predicate as rule 1's amended boundary test; see the design's Amendments section.

> **Amended 2026-08-31 (code review [M5], round 4):** The quote above is superseded. The command conjunct is now stated positively, so a block that runs no command at all does not qualify as procedural. The actual wording committed to `skills/multi-doc-review/SKILL.md` now reads: "procedural step blocks — those that create, modify, or delete no file in the working tree, and run at least one command, every command they run being a pipeline command (the Step 5 commit block, a verification `Run:` line), with an unclear case treated as not procedural — are exempt". Same predicate as rule 1's amended boundary test; see the design's Amendments section.

> **Amended 2026-08-31 (code review [I2], round 4):** The inconsistent-regime guard's `**Contract:**` predicate is scoped to the field itself — a label starting a top-level line of a task's body — instead of the bare string anywhere in the plan, mirroring the "not merely mentioned" qualifier the same cell already uses for the `**Body authority:**` gate. The actual wording committed to `skills/multi-doc-review/SKILL.md` now reads: "A plan that carries a `**Contract:**` field — the label starting a top-level line of a task's body, not merely mentioned inside a fenced code block or a block quote — in its tasks but no `**Body authority:**` label in its header is an inconsistent regime and is itself a finding — it is never reviewed silently as a legacy plan." Reason: the bare-string predicate false-flagged a plan whose tasks merely quote the label `**Contract:**` inside a fenced block or block quote written into another file — a concrete instance is this plan itself.

> **Amended 2026-08-31 (code review [M4], round 4 verification 1):** The quote above (round 4, [M5]) is superseded on one point. The actual wording committed to `skills/multi-doc-review/SKILL.md` now reads: "procedural step blocks — those that create, modify, or delete no file in the working tree, and run at least one command, every command they run being a pipeline command (the Step 5 commit block, a verification `Run:` line — a `Run:` line is a procedural form only when the command it runs writes no working-tree file), with an unclear case treated as not procedural — are exempt". Same qualifier as rule 1's amended boundary test; see the design's Amendments section.

- [x] **Step 4: Run both suites to verify they pass**

Run: `bash tests/reviewer-templates/run-tests.sh && bash tests/writing-plans/run-tests.sh`
Expected: PASS — both exit 0; the reviewer-templates suite reports all sections (1–7) passing, the writing-plans suite reports `Results: 9 passed, 0 failed`.

> **Amended 2026-08-31 (code review [M1]):** The writing-plans suite's check count rose from 7 to 8 because the round-2 review fix added a block-scoped assertion for the `**Body authority:**` label. The earlier per-task expected counts in this plan (4, 5, 6, 7) record the suite size at each task's own point in time and are superseded by this count.

> **Amended 2026-08-31 (code review [I3]):** The count rose again, from 8 to 9, because the [I3] fix added a fragment assertion (rule 1's range) falsifying the new fail-closed tie-break clause. See the design's Amendments section.

> **Amended 2026-08-31 (code review [M3], round 4 verification 1):** The count rose again, from 9 to 12, because the [M3] fix added three block-scoped assertions inside the Plan Header check (the self-pin qualification, the Global-Constraints self-pin exception, and the note's self-binding clause), each falsifying a property the note carried with no prior assertion. The writing-plans suite now reports `Results: 12 passed, 0 failed`.

> **Amended 2026-09-01 (code review [I1], [I2], round 4 verification 2):** The count rose again, from 12 to 15, because the [I1]/[I2] fix added three block-scoped assertions inside the Plan Header check (the non-task-content default, the no-contract clause, and the unreasoned-marker clause), each falsifying a clause the note gained in this round. The writing-plans suite now reports `Results: 15 passed, 0 failed`.

- [x] **Step 5: Commit**

```bash
git add tests/reviewer-templates/run-tests.sh skills/multi-doc-review/SKILL.md
git commit -m "feat(multi-doc-review): contract-target findings in the Ambiguity lens plan cell" --trailer "Session: plan-contracts-not-bodies" --trailer "Stage: task 5/6"
```

---

### Task 6: CLAUDE.md Testing-list line (on-disk only) + final verification (spec R8, R6 closing condition)

**Files:**
- Modify (on disk only, NEVER staged or committed): `CLAUDE.md`

**Security flag:** `none`

**Does NOT cover:** committing `CLAUDE.md` in any form — the file is gitignored in this clone (`.gitignore` line 7) and the spec forbids `git add CLAUDE.md`; this task therefore has **no commit step**. It also does not run any behavioural suite (spec Non-goals) and does not touch `docs/guide/`, `VERSION`, or release files — the release-time work stays with the release process.

- [x] **Step 1: Confirm the file is still gitignored**

Run: `git check-ignore CLAUDE.md`
Expected: exit code 0, prints `CLAUDE.md`. (If this ever fails, STOP — the on-disk-only assumption is broken and the edit must not be made without a user decision.)

- [x] **Step 2: Add the suite to the Testing list**

In `CLAUDE.md`, inside the fenced command list of the `## Testing` section, add this line directly after the `bash tests/reviewer-templates/run-tests.sh …` line:

```bash
bash tests/writing-plans/run-tests.sh     # writing-plans contract/authority wording rules
```

- [x] **Step 3: Verify the edit landed and stayed out of git**

Run: `grep -F "tests/writing-plans/run-tests.sh" CLAUDE.md` then `git status --porcelain -- CLAUDE.md`
Expected: the grep prints the new line; the path-anchored `git status --porcelain -- CLAUDE.md` prints nothing (the file is ignored, so it cannot appear as tracked or untracked). Other untracked paths elsewhere in the repository are outside this check and are not a failure.

- [x] **Step 4: Final verification — all fast suites green**

Run: `bash tests/writing-plans/run-tests.sh && bash tests/reviewer-templates/run-tests.sh && bash tests/codex/run-unit-tests.sh`
Expected: PASS — all three exit 0. The codex unit tests guard against collateral edits: no wording this plan touches is pinned there, so any failure indicates an accidental edit outside this plan's scope and must be investigated, not waved through.

*(No Step 5 — nothing to commit: the only file this task touches is gitignored.)*
