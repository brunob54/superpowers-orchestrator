# Review log — orchestrator-prompt-pointer-design.md

_Invocation 1 — 2026-09-06 — N=2 M=1 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 5 Important, 5 Minor
**Converged:** no

### Dispositions
- [I1] applied — Template changes / Testing strategy: `tests/in-run-rulings/run-tests.sh:2450` pins the batch template's old `## Resume Answer (omit only when …)` heading verbatim, so the suite cannot "stay green" unchanged → the spec names that assertion as rewritten to the new heading and fixed sentence; item 3 now reads "stay green after the one assertion above is updated"; the plan lists every pinned phrase that changes
- [I2] applied — Interfaces, fill commands: `TASK_LIST=4, 5, 6` unquoted splits into three arguments and exits 1 → every `NAME=<value>` argument of the four commands is single-quoted; the "single token" sentence replaced by the quoting rule with the batch task list as the example
- [I3] applied — Error handling: three exit-5 causes (`cannot read template`, `cannot write <out>` on a missing directory, `existing path could not be read`) were unclassified → fatal row 2 enumerates the fatal exit-5 causes; the slip row adds `cannot read template`; a new not-mechanism row treats `cannot write <out>` on a missing or unwritable directory as the path-lost state (fresh `mktemp -d`, re-fill under k = 1), a second such exit fatal
- [I4] applied — Value files: the quoted-heredoc allowance contradicted the mirrored `multi-code-review` rule (answer text is untrusted) and had no refusal path for `block-dangerous-commands.js` → the value file is written with the Write tool only; the heredoc allowance deleted
- [I5] applied — Testing strategy item 2: `\[[A-Z]\]` also matches the checklist marker `- [X]` at `doc-review-loop-prompt.md:72`, which the closing paragraph calls byte-identical → the test is narrowed to the `[M]` token, with `- [X]` named as the allowed exception
- [M1] applied — counter after a fresh directory: "continues" versus "largest plus one" versus "k = 1" disagreed → one rule: a fresh directory restarts `<k>` at 1; names are unique inside one directory only
- [M2] applied — Phase 4 fill command: `LEDGER_PATH` written relative, the template legend requires absolute → `<repository root, absolute>/.superpowers/sdd/progress.md`
- [M3] applied — fatal row 6 cause text: "one line each" and a 150-line cap described different shapes → the first line of each of the two final messages, no cap
- [M4] applied — paragraph after the tables: the reason "detected before or at dispatch, not in a return" was wrong for row 6 → replaced by the true reason (writer-side failures precede dispatch; a controller that never read its file returns no open items)
- [M5] applied — Value files bullet 1: the Phase 1 untagged, id-less user answer contradicted "one line per answer in the `[<id>] (tag)` format" → named as the one exception `## Resume` step 3 already makes

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 4 Important, 11 Minor
**Converged:** no

### Dispositions
- [I1] applied — Failure-mode check 1 still said "the counter continues" after round 1 made the fresh directory restart `<k>` at 1 → rewritten to match Interfaces and the table
- [I2] applied — exit 5 `file already exists` was fatal in Error handling and "corrected once" in Failure-mode check 2 → fatal at once everywhere (mirrors `multi-code-review`); `ls <PROMPT_DIR>` before the fill is how the guard is avoided
- [I3] applied — the fixed sentence was undefined and "answer line" excluded the plan writer's untagged line and `[task <n>/<k>]` lines → the sentence is given verbatim, placed as the last body line before the placeholder (after the batch template's six prose lines); an answer line is any non-blank line below it
- [I4] applied — the list of presence-keyed rules omitted Deviation 2 of the code-review-loop template → the list is declared non-exhaustive (the plan's task greps `Resume Answer` in every file) and the known locations are listed by file and line
- [M1] applied — Architecture said "per retry, the pointer only" while File names requires `test -s` on every dispatch → "a `test -s` and the pointer"
- [M2] applied — "largest number plus one" was ambiguous between `<k>` and `<n>` → "the largest `<k>` (the number after `dispatch-`)"
- [M3] applied — a `cannot write <out>` exit with a permission or disk error matched no row → every such exit other than the two named messages takes the mktemp-again row once
- [M4] applied — "any reference to the run" was a judgement → closed token list (plan path, topic folder, log paths, `tasks=`, `task=`, `rounds=`)
- [M5] applied — "404 assertions" is stale (496 today) → "all its assertions, 496 today"
- [M6] applied — the negative needles were undefined → named: no ``Fill `./`` between the Phase 1 and Phase 5 headings, no "paste", no "Read `./" plus a template name
- [M7] applied — the drift check had no extraction rule → `'NAME=` tokens per `fill-prompt.js` fenced block, keyed by its `--template` file, set-equal to the template's placeholders
- [M8] applied — peak context defined as the maximum of the per-message sum
- [M9] applied — the 10 percent figure is stated as a selector for the next fix, not an acceptance gate for the branch
- [M10] applied — the secrets-probe file had no name → `dispatch-<k>-probe-<n>.txt`, added to the file-name table, the hook row and Failure-mode check 3
- [M11] applied — the backticked `[TASK_LIST]` at batch template line 119 is substituted like every placeholder; stated as unchanged behaviour
