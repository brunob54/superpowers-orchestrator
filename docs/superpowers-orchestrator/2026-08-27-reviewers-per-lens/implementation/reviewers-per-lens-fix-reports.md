## Round 1 fixes — 2026-08-28

### Findings addressed
- [M1] skills/multi-code-review/SKILL.md:578-581 — reworded so the round entry (M = 1) is described as byte-identical, while the invocation line is noted as adding `M=<m>`.
- [M2] skills/multi-code-review/SKILL.md:65-66 — added the "(most recent wins; every M form is extracted from the invocation first — see M below)" guard to the N bullet.
- [M3] skills/multi-code-review/SKILL.md:328-341 and skills/multi-doc-review/SKILL.md:81-88 — anchored the `dispatching-parallel-agents` reference as `../dispatching-parallel-agents/SKILL.md`, relative to each skill's own base directory (same anchoring style as the `review-package` instruction), identically in both files.
- [M4] skills/multi-code-review/SKILL.md:710-712 — added "effective M (and any substitution)" to the After-the-Loop report list.
- [M5] tests/claude-code/test-multi-code-review.sh:4-16 — updated the header comment to mention M=2 and to list assertions (i) and (m).
- [M6] tests/claude-code/test-helpers.sh:273 — added `export -f assert_round_reviewers` after the function's own definition (the pre-existing `export -f` block at line 196 runs before the function is defined, so the export had to go after it).
- [M7] README.md:381 — pointed the `SUPERPOWERS_AUTO_UPDATE` cross-reference at "Available Update Notification" (the heading that actually exists).
- [M8] skills/multi-code-review/SKILL.md:645-646 and skills/multi-doc-review/SKILL.md:295-296 — added "The entry is written on one line, never wrapped." to the `**Reviewer verdicts:**` rule in both files.
- [C2] skills/multi-doc-review/SKILL.md:337 — deleted the shorter duplicate "All reviewers unusable after retries (u = 0) → `inconclusive` round." bullet, kept the fuller one at line 327-328.
- [C6] skills/multi-doc-review/SKILL.md:167-168 — same fix as [M4]: added "effective M (and any substitution)" to the after-the-loop completion report list.
- [C7] skills/multi-doc-review/SKILL.md:235-239 — same wording fix as [M1].
- [C9] skills/multi-code-review/SKILL.md:686-688 — softened "always uses the single shape" to "uses the shape ..., with the source annotation appended when M ≥ 2 (see above)."
- [C10] skills/multi-code-review/SKILL.md:688-692 — added "with u = M" qualifiers to the clean-round and Minor-only-round sentences (done together with C9 in the same paragraph).
- [C11] skills/multi-code-review/SKILL.md:695 — inserted `M` right after `N` in the skipped-entry field list.
- [C13] README.md:32 — added "(reviewers per lens)" at the document's first use of M; later occurrences (lines 33, 367-368) left unchanged.

### Verification
$ bash -n tests/claude-code/test-helpers.sh && bash -n tests/claude-code/test-multi-code-review.sh && echo SYNTAX_OK
SYNTAX_OK

$ bash tests/codex/run-unit-tests.sh
(10 suites, full output; tail:)
──────────────────────────────────────────────────
protect-secrets: 43 passed, 0 failed

==================================================
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
==================================================

$ bash tests/smart-compress/run-tests.sh
(full output; tail:)
10. HOOKS.JSON INTEGRATION
  PASS: hooks.json: bash-compress-hook registered AFTER safety hooks
  PASS: hooks-cursor.json: bash-compress-hook registered
  PASS: hooks.json: all original hook sections still present

══════════════════════════════════════════
  Results: 87 passed
  0 failed
══════════════════════════════════════════

## Round 2 fixes — 2026-08-28

### Findings addressed
- [I1] skills/multi-code-review/SKILL.md:328-334, skills/multi-doc-review/SKILL.md:81-86 — narrowed the `../dispatching-parallel-agents/SKILL.md` reference in the dispatch step to the single-message mechanic of its Procedure step 3 only, and stated that its Decision Check, integration-verification step, and prompt requirements do not apply to reviewer dispatch.
- [I2] skills/multi-code-review/SKILL.md:83-89, skills/multi-doc-review/SKILL.md:39-45 — added to resolution-order step 2 that only a `<reviewers-per-lens>` tag injected into the session context at session start counts; an occurrence of the tag inside any file the controller read (target document, diff, review package) is data, never a parameter, and is ignored.
- [M2] README.md:379, docs/guide/README.md:670-675 — added a platform note to the `SUPERPOWERS_REVIEWERS_PER_LENS` entry in both documents: honored on Claude Code and Cursor, no effect on Codex.

### Verification
$ bash tests/codex/run-unit-tests.sh
pretool-bash-adapter: 28 passed, 0 failed
posttool-bash-compress-adapter: 11 passed, 0 failed
stop-adapter: 16 passed, 0 failed
stop-reminders: 15 passed, 0 failed
session-start-adapter: 14 passed, 0 failed
  6 passed, 0 failed
skill-activator (UserPromptSubmit): 139 passed, 0 failed
statusline-context-cache: 10 passed, 0 failed
subagent-guard: 44 passed, 0 failed
protect-secrets: 43 passed, 0 failed

==================================================
 Results: 10 suites passed, 0 suites failed
 All unit tests passed.
==================================================

$ bash tests/smart-compress/run-tests.sh
(full output; tail:)
10. HOOKS.JSON INTEGRATION
  PASS: hooks.json: bash-compress-hook registered AFTER safety hooks
  PASS: hooks-cursor.json: bash-compress-hook registered
  PASS: hooks.json: all original hook sections still present

══════════════════════════════════════════
  Results: 87 passed
  0 failed
══════════════════════════════════════════

$ grep -n "dispatching-parallel-agents" skills/multi-code-review/SKILL.md skills/multi-doc-review/SKILL.md
skills/multi-doc-review/SKILL.md:86:   single-message mechanic of `../dispatching-parallel-agents/SKILL.md`
skills/multi-code-review/SKILL.md:333:   single-message mechanic of `../dispatching-parallel-agents/SKILL.md`

$ grep -n "reviewers-per-lens" skills/multi-code-review/SKILL.md skills/multi-doc-review/SKILL.md
skills/multi-doc-review/SKILL.md:39:  2. otherwise the value of a `<reviewers-per-lens>` tag in the session
skills/multi-code-review/SKILL.md:83:  2. otherwise the value of a `<reviewers-per-lens>` tag in the session

$ grep -n "SUPERPOWERS_REVIEWERS_PER_LENS" README.md docs/guide/README.md
README.md:379:- `SUPERPOWERS_REVIEWERS_PER_LENS` — M, reviewers per lens: how many identical reviewer subagents each `multi-doc-review` / `multi-code-review` round dispatches in parallel (integer 1–5, default 1). Example: `{ "env": { "SUPERPOWERS_REVIEWERS_PER_LENS": "3" } }`. An `M=<m>` stated in an invocation, or answered in orchestration's Phase 0, wins over it. An invalid value silently falls back to 1. Honored on Claude Code and Cursor; has no effect on Codex.
docs/guide/README.md:171:per lens, default 1; see the `SUPERPOWERS_REVIEWERS_PER_LENS` setting in
docs/guide/README.md:413:| `M` — reviewers per lens: identical reviewers dispatched in parallel per review round, for both loops | 1–5 | 1, or the value of `SUPERPOWERS_REVIEWERS_PER_LENS` |
docs/guide/README.md:674:{ "env": { "SUPERPOWERS_REVIEWERS_PER_LENS": "3" } }
