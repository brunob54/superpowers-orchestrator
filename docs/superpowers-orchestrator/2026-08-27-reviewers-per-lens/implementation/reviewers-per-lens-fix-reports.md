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
