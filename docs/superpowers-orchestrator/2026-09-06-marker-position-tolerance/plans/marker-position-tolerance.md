# Marker Position Tolerance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-orchestrator:subagent-driven-development (recommended) or superpowers-orchestrator:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Body authority:** Exactly two things in this plan bind: the `**Global Constraints:**` block, and a block whose immediately preceding paragraph reads `**Exact content:** <reason>` where that reason names a pin this plan does not itself write or edit. Everything else is reference: fenced code blocks and block-quoted wording in task steps are reference implementations, and so is every other code block, every quoted wording, every header field, and this note itself — a finding against any of them is an ordinary fix, not a plan conflict, unless it contradicts a stated `**Contract:**` or a global constraint. A finding whose subject is this note's own wording is never a plan conflict: record it against the plan-writing skill at `skills/writing-plans/SKILL.md` and continue. That disposition covers the note's own text alone; a finding that this note contradicts something specific to this plan — one of its global constraints, say — is about that interaction and is triaged as an ordinary finding.

**Goal:** Let a controller return and a reviewer report be accepted when the report marker starts one of the message's first 10 non-blank lines, instead of only its very first line.

**Spec:** /Users/bruno/Programming/AI/AI_Coding/My_tools/Superpowers/docs/superpowers-orchestrator/2026-09-06-marker-position-tolerance/specs/marker-position-tolerance-design.md

**Architecture:** Today one boolean — `lastMessage.trimStart().startsWith(<marker>)` — answers both the hook's question ("may this subagent stop?") and the orchestrator's question ("is this return usable?"). The change gives each side its own predicate over the same window, the first 10 non-blank lines of the final message. The hook keeps a **prefix** test over **all three** markers, because its wrong answer costs a controller a redo turn. The orchestrator gets a **whole-line equality** test over **its own marker only**, because it must know exactly which line carries the leading token. Hook-exempt stays a superset of orchestrator-accepted, so nothing the orchestrator would parse can be blocked by the hook.

**Tech Stack:** Node.js >= 16 (`hooks/subagent-guard.js`, `tests/codex/test-subagent-guard.js`), Bash + grep/awk wording-contract suites, Markdown skill files. No build step, no new dependency.

**Assumptions:**

- Assumes the hook receives the subagent's final message as `last_assistant_message` in a single JSON object on standard input — will NOT work if the harness ever splits the message across fields or delivers it pre-trimmed of blank lines.
- Assumes line endings are `\n` or `\r\n` — will NOT work for a classic Mac `\r`-only message, which `split('\n')` would deliver as one long line; no such message has ever been observed and none is handled.
- Assumes `tests/in-run-rulings/run-tests.sh` keeps ranging between the whole lines `## Guard Interaction` and `## Prompt Templates` of `skills/orchestrating-development/SKILL.md` — will NOT hold if either heading is renamed, and both must therefore survive every edit in this plan.
- Assumes `tests/reviewer-templates/run-tests.sh:262` keeps using the whole line `## Guard Interaction` of `skills/multi-code-review/SKILL.md` as the end of its Error Handling range (`ERR_END`) — will NOT hold if that heading is renamed or removed, so Task 4 rewrites only the section body and leaves the heading line untouched.
- Assumes the four controller prompt templates keep instructing "First line exactly" — will NOT hold if a later change relaxes them too; the tolerance in this plan is receiver-side only and does not license a template edit.

**Global Constraints:**

1. **The window is the first 10 non-blank lines** of the final message, on both sides. Blank lines are skipped and do not consume the budget.
2. **The hook predicate is a prefix match over all three markers**, in one predicate: exempt when one of the first 10 non-blank lines, with its surrounding whitespace removed, **starts with** `<!-- multi-review report -->`, `<!-- orchestration report -->` or `<!-- research report -->`. A line that contains a marker without starting with it does not exempt.
3. **The orchestrator predicate is whole-line equality over its own marker only**: a line whose surrounding whitespace is removed **equals** `<!-- orchestration report -->`, among the first 10 non-blank lines. A line equal to another skill's marker is ordinary preamble. With more than one such line, the first begins the report; everything above it is ignored. When the window holds more than one such line, the orchestrator records `note: return carried <n> marker lines; parsed from the first` in the orchestration log, so that the ignored block leaves a trace. The same reading rules govern a fork's reviewer return read under `## In-run rulings`: the first line in the window that starts with `<!-- multi-review report -->` begins the report, everything above it is ignored, and the return's `ITEM:`, `VERDICT:`, `REASON:`, `CONTRADICTS:` and `TABLED:` lines are read only from that line and the 24 lines below it, the first occurrence of each being its value. (amended by ruling 1) (amended by ruling 7)
4. **The 15-line cap counts from the marker line, which is line 1 of the 15, and exceeding it is not a malformed condition.** The malformed list stays closed: no marker line in the window, no leading token, or a consumed field (`tasks=`, per-task numbers, `rounds=`, `outcome=`, `unresolved=`, `user_decision=`, `fixes=`) absent or unparseable. An unparseable stop-rule field never defaults to 0. Every consumed field is read only from the marker line and the 14 lines below it: a value standing below that block is not part of the return the contract describes and is never read. When a consumed field appears more than once inside that block, the first occurrence is its value, matching the first-match rule of constraint 3. (amended by ruling 2) (amended by ruling 5)
5. **The hook gains no second condition.** It never checks for a leading token, and its exemption only ever widens.
6. **The four controller prompt templates are not modified** — `plan-writer-prompt.md`, `doc-review-loop-prompt.md`, `batch-controller-prompt.md`, `code-review-loop-prompt.md` each keep their "First line exactly: `<!-- orchestration report -->`" instruction and their `## Return (final message, 15 lines max)` heading.
7. **No hook wiring file changes.** `hooks/hooks.json`, `plugin.universal.yaml`, `hooks/codex-hooks.json`, `hooks/hooks-cursor.json` and `hooks/codex/` are untouched: only the script body changes, not the command line.
8. **No release work in this plan** — no `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugin.universal.yaml` meta version, `README.md`, `RELEASE-NOTES.md`, `docs/project-map.md` or `docs/orchestration-issues.md` edit. Those belong to the release step after the pipeline ends.
9. **`tests/in-run-rulings/run-tests.sh` must keep passing unchanged.** It is not edited by this plan. It ranges between the whole lines `## Guard Interaction` and `## Prompt Templates` of `skills/orchestrating-development/SKILL.md` and asserts three fragments inside that range; both headings and all three fragments must survive.
10. **Cross-platform:** Node >= 16, no `/dev/stdin`, and each examined line is trimmed before comparison so a CRLF message behaves the same as an LF one.
11. **No behavioural suite may be run** against this clone (`docs/orchestration-issues.md` Case 004). Every verification in this plan is a fast unit or wording-contract suite.

> **Amendment 1 (orchestrator ruling):** Global Constraint 3 kept its first-match rule and gained a log note. Two reviewers of round 2 and verification 1 proposed taking the last qualifying marker line instead, or gating the choice on a recognised leading token. Both were rejected because the design's own invariant is that each side accepts everything it accepts today and more: a return whose first line is the marker and which carries a second marker line lower in the window is accepted today, and last-match would make it malformed — a narrowing. What the reviewers were right about is that the ignored block leaves no trace, so the constraint now requires the orchestrator to record how many marker lines the window held and that it parsed from the first.

> **Amendment 2 (orchestrator ruling):** Global Constraint 4 now bounds where a consumed field is read. Because exceeding the 15-line cap is no longer a malformed condition, nothing stopped a field from being read below the report block — an appendix line holding `unresolved=2` under a `unresolved=0` report could flip a stop rule. The contract defines the report as the marker line plus at most 14 lines below it, so a value outside that block is text the contract never defined; reading it there is indefensible, which makes this a forced ruling rather than a design choice.

> **Amendment 5 (orchestrator ruling):** Global Constraint 4 gained a tie-break for a consumed field that appears twice inside the report block. Ruling 2 bounded WHERE a field may be read but said nothing about a field read twice inside that bound, and a reviewer of invocation 2 named the gap. First-occurrence-wins is the only answer consistent with constraint 3, which already resolves a duplicate marker line the same way.

> **Amendment 7 (orchestrator ruling):** Global Constraint 3 now states that a fork's reviewer return is read the same way as a controller return. Rulings 1, 2 and 5 answered three questions for the controller side — which marker line begins the report, where a consumed field may be read, and what happens when one appears twice — and the widened fork lost-return rule left all three unanswered on the fork side, where a preamble `VERDICT:` and the report's own would give two orchestrators two answers. The answers are copied unchanged, with the fork's own 25-line cap in place of the controller's 15.

---

## Scope Check

The spec covers one subsystem — the report-marker exemption — on two sides of the same boundary (the `SubagentStop` hook and the orchestrator's return contract) plus the prose that documents it. It does not need splitting into separate plans.

## File Structure

| File | Change | Responsibility after the change |
|---|---|---|
| `hooks/subagent-guard.js` | Modify | Holds the single marker predicate `hasReportMarker`, the named window constant `MARKER_SEARCH_LINES`, and comments that state the window rule. |
| `tests/codex/test-subagent-guard.js` | Modify | Replaces the three strictness assertions the change reverses; adds the window boundary cases for all three markers. |
| `skills/orchestrating-development/SKILL.md` | Modify | Return contract bullet (receiver-side rule); `## Guard Interaction` and the `**Lost returns.**` paragraph (documentation of the hook's rule and of a blocked return's real cost). |
| `tests/orchestrating-development/run-tests.sh` | Modify | Adds the three wording assertions pinning the window, the marker spelling and the cap's new status in the Return contract rule (Task 2), and the three pinning the widened guard rule in the two passages that describe the hook (Task 3). |
| `skills/multi-doc-review/SKILL.md` | Modify | `## Guard Interaction` states the widened rule. |
| `skills/multi-code-review/SKILL.md` | Modify | `## Guard Interaction` states the widened rule. |
| `skills/researching-prior-art/SKILL.md` | Modify | The accepted-residual-risk paragraph and `## Guard interaction` state the widened rule. |
| `skills/multi-doc-review/reviewer-prompt.md` | Modify | The "marker line is load-bearing" note states the widened rule instead of "messages that OPEN with it". |
| `skills/multi-code-review/reviewer-prompt.md` | Modify | The same note, same change. |
| `docs/FORK-IMPROVEMENTS.md` | Modify | Both guard bullets (the reviewer-report bullet and the orchestration bullet) state the widened rule. |

Task 1 owns the hook and its unit tests. Task 2 owns the orchestrator's receiver-side contract and its wording assertions. Task 3 owns the two documentation passages inside `skills/orchestrating-development/SKILL.md` that describe the hook, and its own wording assertions. Tasks 2 and 3 both add blocks to `tests/orchestrating-development/run-tests.sh`, in different numbered sections (`1b` and `3b`) and in this order, so the two edits do not overlap. Task 4 owns the remaining passages — the five the spec enumerates plus the three the spec's acceptance sentence reaches but its checklist does not name (the two `reviewer-prompt.md` notes and the reviewer-report bullet of `docs/FORK-IMPROVEMENTS.md`, which spell the rule as "OPEN with" or "open with" and therefore escape the spec's own grep) — and runs the spec's full acceptance check. Tasks 2 and 3 touch the same file in different sections and are ordered to avoid overlapping edits.

---

### Task 1: Widen the guard exemption to the first 10 non-blank lines

**Files:**
- Modify: `hooks/subagent-guard.js`
- Test: `tests/codex/test-subagent-guard.js`

**Security flag:** `security` *(the hook is a leakage-detection boundary; this task changes the condition under which it stops inspecting a message)*

**Does NOT cover:** The exemption still requires a marker at the **start of a line**, inside the window. These scenarios stay unexempt and are meant to: a marker that first appears on the 11th or later non-blank line; a marker preceded on its line by any other character (a finding line such as `- [C1] the <!-- orchestration report --> marker …`); a message with no marker at all. The hook also gains **no** second condition — it does not check that a known leading token (`PLAN_READY`, `BATCH_COMPLETE`, `REVIEW_DONE`, `BLOCKED`) follows the marker, because that would create a new way to block a genuine controller return. A leaking subagent that emits an exact marker at the start of one of its first 10 non-blank lines is exempt; that was already true at line 1 and the prompt instruction remains the first layer of defence.

**Contract:**

1. `hasReportMarker(message)` in `hooks/subagent-guard.js`
   - Inputs: the raw `last_assistant_message` string (possibly empty).
   - Output: boolean.
   - Invariants: returns true exactly when one of the first `MARKER_SEARCH_LINES` non-blank lines of `message`, after its surrounding whitespace (a trailing `\r` included) is removed, **starts with** one of the three report markers. Blank lines are skipped and never consume the window, so any number of leading blank lines keeps today's `trimStart()` behaviour. The 10th non-blank line is examined; the 11th is not. A line that contains a marker without starting with it never returns true. An empty message returns false.
   - Verification: `node tests/codex/test-subagent-guard.js` — the "Marker search window" section asserts the 10th-line pass and the 11th-line fail for each of the three markers, the blank-line case, the mid-line case, the prefix-plus-text case, the two-marker case, the leading-whitespace case and the two CRLF cases. Note what each CRLF case can and cannot catch: under a prefix match a trailing `\r` sits **after** the marker, so `A CRLF message with the marker on the second non-blank line exempts` passes even for an implementation that trims only the start of a line. The case that actually pins the trailing-`\r` half of Global Constraint 10 is `Twelve CRLF blank lines before the marker still exempt`: with only `trimStart()`, each blank CRLF line is the single character `\r`, counts as non-blank, consumes the window, and pushes the marker past it. That case may not be dropped.
   - Interface not externally pinned — the function name and signature are descriptive and may change in a fix (`skills/writing-plans/SKILL.md`, Contracts and Literal Bodies, rule 2; every "rule <n>" below refers to that same numbered list, never to this plan's Global Constraints).
2. `MARKER_SEARCH_LINES` in `hooks/subagent-guard.js`
   - Invariants: declared exactly once, with the value `10`, and carrying a comment that states why the window is bounded.
   - Verification: the test `The marker search window is a single named constant` in `tests/codex/test-subagent-guard.js` counts the declarations in the hook source.
   - This name is a self-pin: the same task writes both the constant and the test that asserts its name, so a later fix may rename both together as one ordinary fix (`skills/writing-plans/SKILL.md`, Contracts and Literal Bodies, rule 5).
3. The four rewritten block comments in `hooks/subagent-guard.js` (the file's opening comment and the three above the marker constants) — wording artifact
   - Must convey: a report marker exempts a message when it starts one of the message's first `MARKER_SEARCH_LINES` non-blank lines, not only its very first line.
   - Invariant: no comment in the file still says the marker counts only at the start of the message.
   - Verification: inside this task, the test `The hook comments state the window rule` in `tests/codex/test-subagent-guard.js` (Step 1 below) asserts that the hook source contains no `opens with` and does contain `MARKER_SEARCH_LINES non-blank lines`, so the comment rewrite is verified by the same commit that makes it. Task 4's acceptance grep — `grep -rn "opening with\|opens with" skills/ hooks/ docs/FORK-IMPROVEMENTS.md` returning no hit that describes `hooks/subagent-guard.js` — is the second, whole-repository check.
   - Sentence wording is free; the properties above bind.

- [x] **Step 1: Write failing tests**

In `tests/codex/test-subagent-guard.js`, first add the marker constants and the message builder just below the existing `runGuard` helper (they are added first because the three replacement tests below already use `VERB_SKILL_BODY`; in the file they sit above every test, so the order inside the file is unambiguous):

```javascript
const REVIEW_MARKER = '<!-- multi-review report -->';
const ORCHESTRATION_MARKER = '<!-- orchestration report -->';
const RESEARCH_MARKER = '<!-- research report -->';
// The window the guard searches, in non-blank lines. Kept in step with
// MARKER_SEARCH_LINES in hooks/subagent-guard.js.
const WINDOW = 10;
// A body that pairs an action verb with a skill name. Every exemption test
// carries one, so the test fails on the unmodified guard instead of passing
// vacuously — the convention this file already states at its whitespace tests.
const VERB_SKILL_BODY =
  'BLOCKED task=3: plan says use executing-plans semantics but the spec forbids it.';

/**
 * A message whose Nth non-blank line is `marker`, with (n - 1) lines of
 * narration above it and a verb+skill body below.
 */
function markerOnNonBlankLine(marker, n) {
  const lines = [];
  for (let i = 1; i < n; i++) {
    lines.push(`Narration line ${i} of the controller's own summary.`);
  }
  lines.push(marker, VERB_SKILL_BODY);
  return lines.join('\n');
}
```

Then replace the three assertions that state the strictness this change reverses. Each keeps its input shape and flips its expectation, so the replacement is visible in the diff. Each carries `VERB_SKILL_BODY` **below** its marker line as well, matching the shape `markerOnNonBlankLine` builds, so that removing the narration line above the marker could never make the test vacuous.

Replace the test at the `multi-doc-review` section (currently `Marker mid-message does not exempt`):

```javascript
test('multi-review marker on the second non-blank line exempts', () => {
  const out = runGuard(`I was invoking brainstorming.\n${REVIEW_MARKER}\n${VERB_SKILL_BODY}`);
  assert.deepStrictEqual(out, {});
});
```

Replace the test at the `Orchestration report marker` section (currently `orchestration marker after the first line does not exempt`):

```javascript
test('orchestration marker on the second non-blank line exempts', () => {
  const out = runGuard(`I was using executing-plans.\n${ORCHESTRATION_MARKER}\n${VERB_SKILL_BODY}`);
  assert.deepStrictEqual(out, {});
});
```

Replace the test at the `researching-prior-art` section (currently `Research marker mid-message does not exempt`):

```javascript
test('research marker on the second non-blank line exempts', () => {
  const out = runGuard(`I was invoking brainstorming.\n${RESEARCH_MARKER}\n${VERB_SKILL_BODY}`);
  assert.deepStrictEqual(out, {});
});
```

Then add a new section immediately before the `── Summary ──` block:

```javascript
// ── Marker search window ─────────────────────────────────────────────────────

console.log('\nMarker search window');

test('The marker search window is a single named constant', () => {
  const declarations = source.match(/const\s+MARKER_SEARCH_LINES\b/g) || [];
  assert.strictEqual(
    declarations.length, 1,
    `Expected exactly one MARKER_SEARCH_LINES declaration, found ${declarations.length}`
  );
  assert.ok(
    /const\s+MARKER_SEARCH_LINES\s*=\s*10\s*;/.test(source),
    'MARKER_SEARCH_LINES must be 10'
  );
});

test('The hook comments state the window rule', () => {
  assert.ok(
    !/opens with/.test(source),
    'No comment in hooks/subagent-guard.js may still say a marker "opens with" the message'
  );
  assert.ok(
    source.includes('MARKER_SEARCH_LINES non-blank lines'),
    'The hook comments must state the window in terms of MARKER_SEARCH_LINES non-blank lines'
  );
});

for (const [label, marker] of [
  ['multi-review', REVIEW_MARKER],
  ['orchestration', ORCHESTRATION_MARKER],
  ['research', RESEARCH_MARKER],
]) {
  test(`${label} marker on the 10th non-blank line exempts`, () => {
    const out = runGuard(markerOnNonBlankLine(marker, WINDOW));
    assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
  });

  test(`${label} marker on the 11th non-blank line does not exempt`, () => {
    const out = runGuard(markerOnNonBlankLine(marker, WINDOW + 1));
    assert.strictEqual(out.decision, 'block', `Expected block, got: ${JSON.stringify(out)}`);
  });
}

test('Twelve blank lines before the marker still exempt (blanks do not consume the window)', () => {
  const message = new Array(12).fill('').concat([ORCHESTRATION_MARKER, VERB_SKILL_BODY]).join('\n');
  const out = runGuard(message);
  assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
});

// This is the case that pins the TRAILING half of the line trim. With
// trimStart() alone every blank CRLF line is the single character "\r",
// counts as non-blank, consumes the window, and pushes the marker out of it.
test('Twelve CRLF blank lines before the marker still exempt', () => {
  const message = new Array(12).fill('').concat([ORCHESTRATION_MARKER, VERB_SKILL_BODY]).join('\r\n');
  const out = runGuard(message);
  assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
});

test('Marker followed by text on the first line still exempts (prefix match)', () => {
  const out = runGuard([
    '<!-- orchestration report --> REVIEW_DONE rounds=2',
    'The loop finished by using multi-code-review semantics.',
  ].join('\n'));
  assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
});

test('A marker quoted after other text on its line does not exempt', () => {
  const out = runGuard([
    'Round 1 findings:',
    `- [C1] the ${ORCHESTRATION_MARKER} marker is described wrongly | reword`,
    'I was using executing-plans to check that.',
  ].join('\n'));
  assert.strictEqual(out.decision, 'block', `Expected block, got: ${JSON.stringify(out)}`);
});

test('Leading whitespace before a marker on the third non-blank line still exempts', () => {
  const out = runGuard([
    'Self-Review complete.',
    'No spec requirement is left without a task.',
    `   ${ORCHESTRATION_MARKER}`,
    VERB_SKILL_BODY,
  ].join('\n'));
  assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
});

test('Two marker lines inside the window exempt', () => {
  const out = runGuard([
    'The round 2 reviewer returned this, quoted below in full.',
    REVIEW_MARKER,
    'Quoted above from the round 2 reviewer return.',
    ORCHESTRATION_MARKER,
    'REVIEW_DONE rounds=2 — the loop ran by using multi-code-review semantics.',
  ].join('\n'));
  assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
});

test('A CRLF message with the marker on the second non-blank line exempts', () => {
  const out = runGuard(`Self-Review complete.\r\n${ORCHESTRATION_MARKER}\r\n${VERB_SKILL_BODY}\r\n`);
  assert.deepStrictEqual(out, {}, `Expected exempt, got: ${JSON.stringify(out)}`);
});
```

Finally, extend the file's header comment `Verifies:` list with one line:

```javascript
 *   - Marker search window: a marker at the start of any of the first 10
 *     non-blank lines exempts; the 11th does not
```

- [x] **Step 2: Run test to verify it fails**

Run: `node tests/codex/test-subagent-guard.js`
Expected: FAIL — the runner prints `✗` for `multi-review marker on the second non-blank line exempts`, `orchestration marker on the second non-blank line exempts`, `research marker on the second non-blank line exempts`, `The marker search window is a single named constant`, `The hook comments state the window rule`, the three `… on the 10th non-blank line exempts` cases, `Leading whitespace before a marker on the third non-blank line still exempts`, `Two marker lines inside the window exempt`, `Twelve CRLF blank lines before the marker still exempt` and `A CRLF message with the marker on the second non-blank line exempts`, then exits non-zero with `subagent-guard: <p> passed, <f> failed`.

- [x] **Step 3: Implement minimal change**

Replace the file's opening block comment (lines 2–17) with:

```javascript
/**
 * Subagent Guard — SubagentStop Hook
 *
 * Detects when subagents invoke superpowers-orchestrator skills or spawn
 * recursive sub-subagents. When detected, blocks the subagent from
 * stopping and instructs it to redo its work without skill invocations.
 * Exception: orchestrating-development dispatches controller subagents that
 * intentionally spawn nested workers — that is sanctioned design, not leakage;
 * controller returns are exempted via the orchestration report marker below.
 * A report marker exempts a message when it starts one of that message's
 * first MARKER_SEARCH_LINES non-blank lines — not only the very first line —
 * so a return that carries a sentence of narration above its marker is still
 * exempt. See hasReportMarker below.
 *
 * This is the "locked door" layer of defense — prompt-based instructions
 * ("do NOT invoke skills") are the first layer; this hook catches violations
 * that slip through.
 *
 * Logs violations to: ~/.claude/hooks-logs/subagent-violations.jsonl
 */
```

Replace the three marker declarations and their comments (lines 57–75) with:

```javascript
// Multi-doc-review reviewer reports legitimately quote skill names — they review
// documents about skills. A genuine report carries this exact marker at the
// start of one of its first MARKER_SEARCH_LINES non-blank lines
// (reviewer-prompt.md still makes it the mandatory first line); a marker
// further down the message does not count.
const REVIEW_REPORT_MARKER = '<!-- multi-review report -->';

// Orchestrating-development controller subagents return status contracts whose
// free text (e.g. a BLOCKED reason quoting a plan conflict) may legitimately
// pair action verbs with skill names. A genuine controller return carries this
// exact marker at the start of one of its first MARKER_SEARCH_LINES non-blank
// lines (the skill's prompt templates still make it the mandatory first line);
// a marker further down the message does not count.
const ORCHESTRATION_REPORT_MARKER = '<!-- orchestration report -->';

// Researching-prior-art researchers and controllers report on external
// projects whose documentation legitimately contains skill-like phrases. A
// genuine research report or summary carries this exact marker at the start of
// one of its first MARKER_SEARCH_LINES non-blank lines (research-prompt.md and
// controller-prompt.md still make it the mandatory first line); a marker
// further down the message does not count.
const RESEARCH_REPORT_MARKER = '<!-- research report -->';

// How far into a final message the marker search runs, counted in non-blank
// lines. Controllers sometimes write a sentence or a short summary above the
// marker, and every recorded case fits well inside this window. The window
// stays bounded because the exemption must remain a property of a message's
// opening: reports in this repository quote marker lines inside their
// findings, and a whole-message search would exempt those too.
const MARKER_SEARCH_LINES = 10;

const REPORT_MARKERS = [
  REVIEW_REPORT_MARKER,
  ORCHESTRATION_REPORT_MARKER,
  RESEARCH_REPORT_MARKER,
];

/**
 * True when one of the first MARKER_SEARCH_LINES non-blank lines of the
 * message starts with one of the three report markers, after that line's
 * surrounding whitespace (a trailing "\r" of a CRLF message included) is
 * removed. Blank lines are skipped and do not consume the window. A line that
 * contains a marker without starting with it — a finding line quoting the
 * marker — does not exempt.
 */
function hasReportMarker(message) {
  let examined = 0;
  for (const rawLine of message.split('\n')) {
    const line = rawLine.trim();
    if (line === '') continue;
    if (REPORT_MARKERS.some(marker => line.startsWith(marker))) return true;
    examined++;
    if (examined >= MARKER_SEARCH_LINES) return false;
  }
  return false;
}
```

Replace the exemption test inside `main` (lines 119–127) with:

```javascript
      if (hasReportMarker(lastMessage)) {
        process.stdout.write('{}');
        return;
      }
```

Nothing else in the hook changes: the violation patterns, `logViolation`, the block reason and the parse-failure fallback that allows the stop all stay as they are.

- [x] **Step 4: Run test to verify it passes**

Run: `node tests/codex/test-subagent-guard.js`
Expected: PASS — `subagent-guard: <n> passed, 0 failed`, exit 0.

- [x] **Step 5: Commit**

```bash
git add hooks/subagent-guard.js tests/codex/test-subagent-guard.js
git commit -m "fix(hooks): exempt a report marker within the first 10 non-blank lines" --trailer "Session: marker-position-tolerance" --trailer "Stage: task 1/4"
```

---

### Task 2: Widen the orchestrator's Return contract

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md` (the `**Return contract:**` bullet of `## Controller Dispatch Rules (apply to every phase)`)
- Test: `tests/orchestrating-development/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** The widened acceptance applies only to the **position** of the marker line. A return whose marker first appears below the 10th non-blank line, or which has no line equal to the marker at all, is still malformed, still gets one identical retry, and in Phase 4 can still meet `code-review-loop-prompt.md` Deviation 2 and stop the run — the spec states this residual risk rather than removing it. The change also does **not** relax the field rules: a missing leading token or an absent or unparseable consumed field is malformed exactly as today. The 15-line cap stops being a receiver-side test, so a longer report is accepted; it is not otherwise policed.

**Contract:**

1. The `**Return contract:**` bullet of `## Controller Dispatch Rules` — wording artifact
   - Must convey, all of: the templates still tell the controller to put the marker on its first line; a return is accepted when a line whose surrounding whitespace is removed equals `<!-- orchestration report -->` and is among the first 10 non-blank lines; blank lines are skipped and do not consume that budget; only this marker is searched for, so a line equal to another skill's marker is ordinary preamble; with more than one such line the first begins the report and everything above it is ignored and is never a reason to retry; the leading token is on the first non-blank line below the marker line, using the same meaning of "non-blank" as the window rule, so a whitespace-only line is skipped rather than being read as the token line; the 15-line cap counts from the marker line, which is line 1 of the 15, and exceeding it is not malformed; the malformed list is otherwise unchanged, and a malformed return or controller error gets one identical retry before the major-error stop.
   - Invariant: no sentence in the bullet still makes the marker's position on the first line a condition of acceptance.
   - Verification: `bash tests/orchestrating-development/run-tests.sh` asserts, inside the Controller Dispatch Rules range, the fragment `among the **first 10 non-blank lines**`, the fragment `<!-- orchestration report -->` and the fragment `a longer report is **not** malformed`.
   - Sentence wording is free; the properties above bind.
2. The three new assertions of block `1b` in `tests/orchestrating-development/run-tests.sh` (Task 3 adds a separate block `3b` to the same file)
   - Invariants: the suite fails if any of the three fragments leaves the Controller Dispatch Rules range — an assertion on the window alone would pass a bullet that lost the marker's spelling, an assertion on the marker alone would pass a bullet that returned to the first-line rule, and without the third a later edit could restore a cap-based malformed condition with every suite still green.
   - Verification: run the suite against the unedited skill file and see the window assertion and the cap assertion fail (Step 2 below).
   - These fragments are a self-pin: this task writes both the bullet and the assertions, so a later fix may amend them together as one ordinary fix (`skills/writing-plans/SKILL.md`, Contracts and Literal Bodies, rule 5).

- [x] **Step 1: Write failing test**

In `tests/orchestrating-development/run-tests.sh`, add the three fragment constants next to the other wording contracts, just below the `VALUE_WITHHELD_OLD_FORM` line:

```bash
# The Return contract's marker tolerance, pinned in halves so that no later
# edit can restore any of the extremes: the window (with the words
# "non-blank", so that a bare `10` cannot satisfy it), the marker's exact
# spelling, and the 15-line cap's new status as an instruction rather than a
# malformed condition.
RETURN_WINDOW='among the **first 10 non-blank lines**'
RETURN_MARKER='<!-- orchestration report -->'
RETURN_CAP_NOT_MALFORMED='a longer report is **not** malformed'
```

Then add a new block immediately after the `bold "1. Controller Dispatch Rules: ..."` block ends — that is, right before `bold "2. Negative needles over the whole orchestrator text"`:

```bash
bold "1b. Return contract: the marker may start any of the first 10 non-blank lines"
assert_folded_contains "dispatch rules: the return contract states the 10-non-blank-line window" \
  "$DISPATCH_RANGE" "$RETURN_WINDOW"
assert_folded_contains "dispatch rules: the return contract spells the orchestration marker exactly" \
  "$DISPATCH_RANGE" "$RETURN_MARKER"
assert_folded_contains "dispatch rules: the return contract says exceeding the 15-line cap is not malformed" \
  "$DISPATCH_RANGE" "$RETURN_CAP_NOT_MALFORMED"
```

- [x] **Step 2: Run test to verify it fails**

Run: `bash tests/orchestrating-development/run-tests.sh`
Expected: FAIL — `FAIL: dispatch rules: the return contract states the 10-non-blank-line window (missing: among the **first 10 non-blank lines**)` and `FAIL: dispatch rules: the return contract says exceeding the 15-line cap is not malformed (missing: a longer report is **not** malformed)`, and a non-zero exit. The marker assertion passes already, because the current bullet spells the marker; the window and cap assertions fail until Step 3.

- [x] **Step 3: Implement minimal change**

In `skills/orchestrating-development/SKILL.md`, replace the whole `**Return contract:**` bullet (the last bullet of `## Controller Dispatch Rules (apply to every phase)`, currently beginning "first line exactly `<!-- orchestration report -->` (guard exemption)") with:

```markdown
- **Return contract:** the four templates tell the controller to make
  `<!-- orchestration report -->` its first line and keep saying so. You
  accept a return when a line whose surrounding whitespace is removed
  **equals** `<!-- orchestration report -->` and is among the **first 10
  non-blank lines** of the final message; blank lines are skipped and do not
  consume that budget. Only this marker is searched for: a line equal to
  another skill's marker is ordinary preamble. When more than one such line
  is present, the **first** begins the report; everything above it is
  ignored and is never a reason to retry. The leading token is on the first
  non-blank line below that marker line — "non-blank" throughout this bullet,
  so a line holding only spaces is skipped here exactly as it is skipped in
  the window. The 15-line cap counts from the
  marker line, which is line 1 of the 15; it is an instruction to the
  controller, not a test you run — a longer report is **not** malformed.
  Detail goes to files. A return is **malformed** when no such marker line
  is in the window, OR the leading token is absent, OR any field you consume
  (`tasks=`, per-task numbers, `rounds=`, `outcome=`, `unresolved=`,
  `user_decision=`, `fixes=`) is absent or unparseable. An unparseable
  stop-rule field never defaults to 0. Malformed return or controller error
  → retry the identical dispatch once — the same pointer to the same file,
  no fill and no new file; second failure → major error → stop, logging
  `inconclusive controller: <phase/batch>`.
```

- [x] **Step 4: Run test to verify it passes**

Run: `bash tests/orchestrating-development/run-tests.sh`
Expected: PASS — all three `1b` assertions report `PASS`, and the run ends with `Results: <n> passed, 0 failed`, exit 0.

- [x] **Step 5: Commit**

```bash
git add skills/orchestrating-development/SKILL.md tests/orchestrating-development/run-tests.sh
git commit -m "feat(orchestrating-development): accept a marker within the first 10 non-blank lines" --trailer "Session: marker-position-tolerance" --trailer "Stage: task 2/4"
```

---

### Task 3: Correct the orchestrator's two descriptions of the hook

> **Amendment 3 (orchestrator ruling):** Task 3's "Does NOT cover" said the lost-return rule was not touched. That became false when the rule's sentence was rewritten: it now reads "no line of the reviewer's final message ... starts with the marker", an unbounded every-line prefix test where the old text said "opens with". Under it a fork failure notice that merely quotes the reviewer marker counts as a usable return toward the two-usable-returns threshold, so a design ruling could be made with no verdict behind it. Four reviewer pairs raised it in four consecutive cycles. Bounding the test to the first 10 non-blank lines corrects a regression this branch introduced; it is not new scope.

**Files:**
- Modify: `skills/orchestrating-development/SKILL.md` (`## Guard Interaction`, and the `**Lost returns.**` paragraph inside `## In-run rulings`)
- Test: `tests/orchestrating-development/run-tests.sh`

**Security flag:** `none`

**Does NOT cover:** Only the two passages that describe the *hook's* exemption change. The lost-return **rule** of `## In-run rulings` — a fork return whose completion notice arrives without the marker line is lost, re-dispatched once, and a second loss leaves that lens out — keys on the marker's *presence*, not its position. Its marker test is nevertheless bounded to the same first 10 non-blank lines as every other predicate of this change, because the rewrite of its sentence turned an opens-with test into an every-line prefix test and so changed the rule after all; nothing else about it is touched. The four controller prompt templates are not touched either (Global Constraint 6).

**Contract:**

1. `## Guard Interaction` of `skills/orchestrating-development/SKILL.md` — wording artifact
   - Must convey: the guard exempts a message when one of its first 10 non-blank lines starts with the marker, so a return with a sentence above its marker is still exempt; the marker instruction stays mandatory in the four templates because an unmarked return is answered with `decision: block` and a redo instruction, which costs an extra turn and can make a controller repeat work it has already committed.
   - Invariants: the section no longer claims that an unmarked return would "hang the dispatch, and stall the unattended run"; the headings `## Guard Interaction` and `## Prompt Templates` both survive as whole lines; the two fork sentences and the exact spelling `<!-- multi-review report -->` survive inside the range.
   - Verification: `bash tests/orchestrating-development/run-tests.sh` asserts positively that the phrase `first 10 non-blank lines` stands inside the `## Guard Interaction` range, and negatively that the whole skill file no longer contains `hang the dispatch`. Both halves of this contract are therefore falsifiable by one command: a rewrite that dropped the window, or that kept the hang claim, fails. `bash tests/in-run-rulings/run-tests.sh` (its three ranged assertions between those two headings) protects what must survive, and Task 4's acceptance greps are the whole-repository check.
2. The `**Lost returns.**` paragraph inside `## In-run rulings` — wording artifact
   - Must convey: the guard exempts a final message when one of its first 10 non-blank lines starts with the marker; a message without such a line that names a plugin skill is answered with `decision: block` and a redo instruction, so the fork spends another turn rewriting and the notice still arrives, later.
   - Invariant: the sentences the same section pins further down — `A lost return is re-dispatched once under the same lens; a second loss leaves that lens out and the ruling records \`forks: <k> of <planned>\`` and `The bound is stated over the ROUND, never over one lens` — are untouched.
   - Verification: `bash tests/orchestrating-development/run-tests.sh` asserts positively that the phrase `first 10 non-blank lines` stands inside the `## In-run rulings` range, so a rewrite that dropped the window fails. `bash tests/in-run-rulings/run-tests.sh` protects the pinned sentences, and Task 4's acceptance greps are the whole-repository check.
3. The three new assertions of block `3b` in `tests/orchestrating-development/run-tests.sh` (block `1b`, added by Task 2, is untouched)
   - Invariants: one positive assertion per rewritten passage (the `## Guard Interaction` range and the `## In-run rulings` range each contain `first 10 non-blank lines`) and one negative assertion over the whole file (`hang the dispatch` is absent). A negative check alone would pass a rewrite that simply deleted the exemption sentence; a positive check alone would pass a rewrite that kept the corrected-away "hang" claim beside the new window sentence.
   - Verification: run the suite against the unedited skill file and see all three assertions fail (Step 2 below).
   - These fragments are a self-pin: this task writes both the passages and the assertions, so a later fix may amend them together as one ordinary fix (`skills/writing-plans/SKILL.md`, Contracts and Literal Bodies, rule 5).

- [x] **Step 1: Write failing assertions**

In `tests/orchestrating-development/run-tests.sh`, add the two fragment constants next to the other wording contracts, below the `VALUE_WITHHELD_OLD_FORM` line:

```bash
# The widened guard rule, pinned positively in both passages that state it,
# and the superseded "hang" claim pinned negatively. `$H_GUARD` and
# `$H_TEMPLATES` already exist in this file (they bound the Major-Error Stop
# Policy range and the Prompt Templates range). `assert_folded_contains`
# joins the file's lines with single spaces before matching, so the window
# fragment matches even where the prose wraps between "10" and "non-blank".
GUARD_WINDOW='first 10 non-blank lines'
GUARD_HANG_OLD_CLAIM='hang the dispatch'
```

Add the range file path with the other `*_RANGE` declarations (they sit below `WORK="$(mktemp -d)"`, which this path needs):

```bash
GUARD_RANGE="$WORK/guard.txt"
```

Add the range extraction to the `bold "0. Section ranges of the orchestrator"` block, immediately after the Major-Error Stop Policy line:

```bash
extract_range "Guard Interaction" "$ORCH_SKILL" "$H_GUARD" "$H_TEMPLATES" "$GUARD_RANGE"
```

Then add a new block immediately before `bold "4. Prompt Templates: filled by the script, never read"`:

```bash
bold "3b. Guard Interaction and Lost returns state the widened exemption"
assert_folded_contains "guard interaction: states the 10-non-blank-line window" \
  "$GUARD_RANGE" "$GUARD_WINDOW"
assert_folded_contains "lost returns: states the 10-non-blank-line window" \
  "$INRUN_RANGE" "$GUARD_WINDOW"
assert_file_not_contains "orchestrator no longer claims an unmarked return hangs the dispatch" \
  "$ORCH_SKILL" "$GUARD_HANG_OLD_CLAIM"
```

- [x] **Step 2: Run the suite to verify the three assertions fail**

Run: `bash tests/orchestrating-development/run-tests.sh`
Expected: FAIL — `FAIL: guard interaction: states the 10-non-blank-line window (missing: first 10 non-blank lines)`, `FAIL: lost returns: states the 10-non-blank-line window (missing: first 10 non-blank lines)` and `FAIL: orchestrator no longer claims an unmarked return hangs the dispatch`, and a non-zero exit. Task 2's `1b` assertions all pass at this point, because Task 2 already landed.

- [x] **Step 3: Rewrite `## Guard Interaction`**

Replace the first two sentences of the section — from "Controller returns open with" through "and stall the unattended run." — with the text below. The rest of the section (from "Nested workers dispatched by batch controllers" to the end) stays exactly as it is.

```markdown
Controller returns open with `<!-- orchestration report -->`;
`hooks/subagent-guard.js` exempts a message when one of its first 10
non-blank lines starts with that marker, so a return that carries a sentence
above its marker line is still exempt. Never remove the marker instruction
from the four templates — free-text `BLOCKED` reasons legitimately pair
action verbs with skill names, and an unmarked return is answered with
`decision: block` and a redo instruction: measured on 2026-09-06, the
dispatch resumed after one extra turn rather than hanging, but a controller
that obeys "redo your assigned task" can repeat review rounds and fix
commits it has already written.
```

The two sentences below already stand in the section and their character sequence must survive this edit, between the `## Guard Interaction` and `## Prompt Templates` headings. Line wrapping is free: `tests/in-run-rulings/run-tests.sh` folds line breaks before matching, so re-wrapping is safe and only the words themselves are pinned. Note also that in the file the first pinned sentence starts on the same physical line as the last sentence you are deleting, so the replacement paragraph may end mid-line. They are quoted here for checking only — the `> ` prefix of the quotation is not part of the file's text, and the simplest way to keep them intact is not to retype them at all.

**Exact content:** `tests/in-run-rulings/run-tests.sh:798-811` asserts these two fragments and the spelling `<!-- multi-review report -->` inside the range that runs from the whole line `## Guard Interaction` to the whole line `## Prompt Templates`; that test file is not written or edited by this plan.

> Nested workers dispatched by batch controllers carry
> SDD's leakage-prevention line; nested reviewers inside the two loop
> controllers emit `<!-- multi-review report -->`, which the guard already
> exempts. Forks dispatched under `## In-run rulings` open their return
> with that same `<!-- multi-review report -->` marker; a fork return
> without it is a lost return under that section's rule, never a reason to
> remove the marker instruction from the fork prompt.

- [x] **Step 4: Rewrite the `**Lost returns.**` paragraph**

Replace the paragraph that currently begins "**Lost returns.** `hooks/subagent-guard.js` exempts a final message that opens with the marker line" with:

```markdown
**Lost returns.** `hooks/subagent-guard.js` exempts a final message when one
of its first 10 non-blank lines starts with the marker; a message with no
such line that names a plugin skill is answered with `decision: block` and a
redo instruction, so the fork spends another turn rewriting — the notice
still arrives, later.
```

- [x] **Step 5: Run the ranged suite to verify nothing pinned was lost**

Run: `bash tests/in-run-rulings/run-tests.sh`
Expected: PASS — in particular `Guard Interaction states that forks open with the reviewer marker`, `Guard Interaction makes a markerless fork return a lost return` and `Guard Interaction still spells the nested-reviewer marker exactly` all report PASS, and the run exits 0.

- [x] **Step 6: Run the orchestrator wording suite to verify the three assertions now pass and the headings still anchor its ranges**

Run: `bash tests/orchestrating-development/run-tests.sh`
Expected: PASS — the three `3b` assertions report PASS, `Guard Interaction: range located (...)`, `Major-Error Stop Policy: range located (...)` and `Prompt Templates: range located (...)` all report PASS, and the run ends with `Results: <n> passed, 0 failed`, exit 0.

- [x] **Step 7: Commit**

```bash
git add skills/orchestrating-development/SKILL.md tests/orchestrating-development/run-tests.sh
git commit -m "docs(orchestrating-development): state the widened guard exemption and a blocked return's real cost" --trailer "Session: marker-position-tolerance" --trailer "Stage: task 3/4"
```

---

### Task 4: Correct the remaining guard passages and run the acceptance check

**Files:**
- Modify: `skills/multi-doc-review/SKILL.md`
- Modify: `skills/multi-code-review/SKILL.md`
- Modify: `skills/researching-prior-art/SKILL.md`
- Modify: `skills/multi-doc-review/reviewer-prompt.md`
- Modify: `skills/multi-code-review/reviewer-prompt.md`
- Modify: `docs/FORK-IMPROVEMENTS.md`

**Security flag:** `none`

**Does NOT cover:** Only the passages that describe the *hook's* exemption change. The skill-side usability rules of the other two markers are untouched: `skills/multi-code-review/SKILL.md:602`, `skills/multi-doc-review/SKILL.md:114`, `skills/researching-prior-art/research-prompt.md:164` and `controller-prompt.md:126`/`:233` keep requiring the marker as a report's **first line**, and the unusable-report path (one identical retry, then `inconclusive` when no reviewer of the round returns a usable report) is unchanged. The two `reviewer-prompt.md` notes rewritten in Step 5 likewise keep telling the reviewer to make the marker its first output line: only their sentence about what the *hook* exempts changes. No release file is edited (Global Constraint 8).

**Contract:**

1. The `## Guard Interaction` section of `skills/multi-doc-review/SKILL.md`, the `## Guard Interaction` section of `skills/multi-code-review/SKILL.md`, the accepted-residual-risk paragraph and `## Guard interaction` section of `skills/researching-prior-art/SKILL.md`, the "marker line is load-bearing" note of `skills/multi-doc-review/reviewer-prompt.md` and of `skills/multi-code-review/reviewer-prompt.md`, and both guard bullets of `docs/FORK-IMPROVEMENTS.md` (the reviewer-report bullet and the orchestration bullet) — wording artifacts, one entry each with the same properties
   - Must convey: `hooks/subagent-guard.js` exempts a message from skill-leakage blocking when one of its first 10 non-blank lines starts with the relevant marker, not only when the message opens with it.
   - Invariants: every passage that carries an instruction never to remove the marker from its own prompt template(s) today keeps it — that is the two `## Guard Interaction` sections, `## Guard interaction` of `skills/researching-prior-art/SKILL.md` and the two `reviewer-prompt.md` notes; the residual-risk paragraph of `skills/researching-prior-art/SKILL.md` and the two `docs/FORK-IMPROVEMENTS.md` bullets carry no such instruction today and none is added. `skills/researching-prior-art/SKILL.md`'s residual-risk paragraph states the widened scope of the accepted risk. No passage still describes the exemption as applying only to a message that opens with a marker, in any spelling.
   - Invariant (heading lines): the section headings `## Guard Interaction` (both skills) and `## Guard interaction` survive as whole lines — `tests/reviewer-templates/run-tests.sh:262` ranges on the `multi-code-review` one. Only section bodies are replaced.
   - Verification: the two acceptance greps of Step 7 — the spec's own `grep -rn "opening with\|opens with" skills/ hooks/ docs/FORK-IMPROVEMENTS.md` leaves no hit that describes `hooks/subagent-guard.js`, and the supplementary `grep -rn "OPEN with\|open with" skills/ hooks/ docs/FORK-IMPROVEMENTS.md` leaves no hit that describes the hook's exemption.
   - Sentence wording is free; the properties above bind.

- [x] **Step 1: Rewrite `skills/multi-doc-review/SKILL.md` `## Guard Interaction`**

Replace the section body — the heading line `## Guard Interaction` itself stays untouched — with:

```markdown
`hooks/subagent-guard.js` exempts a message from skill-leakage blocking when
one of its first 10 non-blank lines starts with `<!-- multi-review report -->`
— reviewer reports legitimately quote skill names. A report that carries a
sentence above its marker line is therefore still exempt. Never remove the
marker instruction from `reviewer-prompt.md`; without it, reports about
skill-discussing documents get blocked and rounds degrade to retries.
```

- [x] **Step 2: Rewrite `skills/multi-code-review/SKILL.md` `## Guard Interaction`**

Replace the section body with the text below. The heading line `## Guard Interaction` itself stays untouched: `tests/reviewer-templates/run-tests.sh:262` uses that whole line as the end of its Error Handling range, so renaming or moving it breaks that suite.

```markdown
Reviewer reports open with `<!-- multi-review report -->` —
`hooks/subagent-guard.js` exempts a message from skill-leakage blocking when
one of its first 10 non-blank lines starts with that marker (code reviews in
this repository legitimately quote skill names), so a report with a sentence
above its marker line is still exempt. Never remove the marker instruction
from `reviewer-prompt.md`.
```

- [x] **Step 3: Rewrite the accepted-residual-risk paragraph of `skills/researching-prior-art/SKILL.md`**

Replace the first sentence of that paragraph — from "Accepted residual risk:" through "first line of their returns." — with the text below, keeping the paragraph's list indentation and leaving the rest of the paragraph ("This means the guard never inspects …") unchanged. The replacement deliberately avoids the phrases "opens with" and "opening with", so that the Step 7 acceptance grep stays an all-or-nothing check with no new expected hit.

```markdown
   Accepted residual risk: `hooks/subagent-guard.js` exempts a message
   from skill-leakage blocking when one of its first 10 non-blank lines
   starts with the `<!-- research report -->` marker — the marker does
   not have to be the message's first line — and both the controller and
   researcher prompt templates require that marker as the first line of
   their returns.
```

- [x] **Step 4: Rewrite `skills/researching-prior-art/SKILL.md` `## Guard interaction`**

Replace the section body — the heading line `## Guard interaction` itself stays untouched — with:

```markdown
`hooks/subagent-guard.js` exempts a message from skill-leakage blocking when
one of its first 10 non-blank lines starts with `<!-- research report -->` —
research reports legitimately quote skill-like phrases found in external
documentation. Never remove the marker instruction from `research-prompt.md`
or `controller-prompt.md`; without it, reports get blocked and assignments
degrade to evidence gaps.
```

- [x] **Step 5: Rewrite the two `reviewer-prompt.md` load-bearing-marker notes**

These two notes are the reason the spec's own grep is not sufficient: they spell the rule `OPEN with`, in capitals, so `grep -rn "opening with\|opens with"` never sees them, and without this step the Step 7 check would report success while two files still stated the pre-change rule.

In `skills/multi-doc-review/reviewer-prompt.md`, replace the paragraph that begins "The marker line in the output format is load-bearing" with:

```markdown
The marker line in the output format is load-bearing: `hooks/subagent-guard.js`
exempts a message from skill-leakage blocking when one of its first 10 non-blank
lines starts with that marker. Without the marker, reports quoting skill names
get blocked and the round degrades to a retry — so the template keeps requiring
it as the report's first line.
```

In `skills/multi-code-review/reviewer-prompt.md`, replace the paragraph that begins "The marker line in the output format is load-bearing" with the same text, re-wrapped to that file's narrower column width if needed. Both files keep every other sentence, and both keep instructing the reviewer to make the marker the report's first line (Does NOT cover, above).

- [x] **Step 6: Rewrite the two guard bullets of `docs/FORK-IMPROVEMENTS.md`**

Replace the bullet that begins "- Reviewer reports open with the marker" with:

```markdown
- Reviewer reports carry the marker `<!-- multi-review report -->` on their first line; `hooks/subagent-guard.js` exempts a message from skill-leakage blocking when one of its first 10 non-blank lines starts with that marker, since reports about skill-discussing documents legitimately quote skill names.
```

Replace the bullet that begins "- Controllers dispatch their own nested workers" with:

```markdown
- Controllers dispatch their own nested workers (implementers, reviewers, fix subagents). `hooks/subagent-guard.js` records this sanctioned nesting and exempts a return from skill-leakage blocking when one of its first 10 non-blank lines starts with the `<!-- orchestration report -->` marker — free-text `BLOCKED` reasons may legitimately name skills, and a controller that writes a sentence above its marker still returns cleanly.
```

- [x] **Step 7: Run the three acceptance greps**

The first two are negative (nothing may still state the old rule); the third is positive (every rewritten file must state the new one). A negative check alone would pass a rewrite that deleted the exemption sentence altogether, which is why the third exists.

Run: `grep -rn "opening with\|opens with" skills/ hooks/ docs/FORK-IMPROVEMENTS.md`
Expected: exactly one hit remains, and it is unrelated to the guard exemption — the `// 'wx' opens with O_EXCL:` comment in `skills/multi-code-review/scripts/fill-prompt.js` (matched by its text, not by a line number, which any unrelated edit above it would change).
No hit may name or describe `hooks/subagent-guard.js`. If any of the eight passages of this task's Contract still matches, fix that passage before continuing.

Then run the supplementary grep, which catches the word forms the spec's command misses (`OPEN with`, `open with`):

Run: `grep -rniE "open(s|ing)? with" skills/ hooks/ docs/FORK-IMPROVEMENTS.md`
Expected — stated as a property, not a count, because each rewritten passage's sentence wording is free: **no remaining hit may state what `hooks/subagent-guard.js` exempts.** Hits that say what a controller or a reviewer is told to *emit* are correct and must survive; so are hits unrelated to markers. On the reference wording of this plan that is four hits — `skills/orchestrating-development/SKILL.md` (`Controller returns open with ...`), `skills/multi-code-review/SKILL.md` (`Reviewer reports open with ...`), the `O_EXCL` comment above, and `hooks/bash-optimizer.js` (`fail-open with raw output`, a file-mode phrase) — but a rewrite that words those two sections differently and yields two hits is equally correct. Judge each hit by the property, never by the total.

Finally run the positive check, which proves every rewritten prose file states the new rule. The phrase is wrapped across lines in several of these files, so the check folds each file to one line before searching — the same treatment `assert_folded_contains` gives a needle in the bash suites:

Run:

```bash
for f in skills/multi-doc-review/SKILL.md skills/multi-code-review/SKILL.md \
         skills/researching-prior-art/SKILL.md \
         skills/multi-doc-review/reviewer-prompt.md \
         skills/multi-code-review/reviewer-prompt.md \
         docs/FORK-IMPROVEMENTS.md skills/orchestrating-development/SKILL.md; do
  tr '\n' ' ' < "$f" | grep -qF 'first 10 non-blank lines' || echo "MISSING: $f"
done
```

Expected: no output. Any `MISSING:` line names a file that no longer states the widened rule — fix that file before continuing. The list is the six files of this task plus `skills/orchestrating-development/SKILL.md` from Task 3, so this one command re-checks every prose passage of the change. `hooks/subagent-guard.js` is deliberately absent: its comments state the window as `first MARKER_SEARCH_LINES non-blank lines`, and Task 1's own test `The hook comments state the window rule` is the check for it.

- [x] **Step 8: Run every fast suite**

Run: `bash tests/codex/run-unit-tests.sh && bash tests/smart-compress/run-tests.sh && bash tests/reviewer-templates/run-tests.sh && bash tests/writing-plans/run-tests.sh && bash tests/in-run-rulings/run-tests.sh && bash tests/fill-prompt/run-tests.sh && bash tests/orchestrating-development/run-tests.sh && bash tests/measure-context/run-tests.sh`
Expected: PASS — every suite exits 0; `tests/codex/run-unit-tests.sh` ends with `All unit tests passed.` and `tests/orchestrating-development/run-tests.sh` and `tests/in-run-rulings/run-tests.sh` each end with `Results: <n> passed, 0 failed`.

- [x] **Step 9: Commit**

```bash
git add skills/multi-doc-review/SKILL.md skills/multi-code-review/SKILL.md skills/researching-prior-art/SKILL.md skills/multi-doc-review/reviewer-prompt.md skills/multi-code-review/reviewer-prompt.md docs/FORK-IMPROVEMENTS.md
git commit -m "docs(skills): state the widened guard exemption in the remaining passages" --trailer "Session: marker-position-tolerance" --trailer "Stage: task 4/4"
```
