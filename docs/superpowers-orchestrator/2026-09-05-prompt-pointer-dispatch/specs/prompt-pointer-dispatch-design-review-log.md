# Review log — prompt-pointer-dispatch-design.md

_Invocation 1 — 2026-09-05 — N=2 M=1 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 5 Important, 7 Minor
**Converged:** no

### Dispositions
- [I1] applied — Prompt directory and file names, data flow, step 2, fix dispatch: `$PROMPT_DIR` used as a shell variable across tool calls → the controller copies the literal path `mktemp -d` prints into every later command; notation `<PROMPT_DIR>`; wording test asserts no `$PROMPT_DIR` token in the Procedure — harness probe: reviewer exported a variable in one Bash call and read it as UNSET in the next
- [I2] applied — Error handling: fallback content undefined for the fix dispatch → "inline dispatch" defined as reading the relevant template and filling its body by hand; the only case the controller reads a template
- [I3] applied — fix-prompt.md rules: never stage the fix-report file (Pipeline rule 1) → rule added to the template list and the wording contracts
- [I4] applied — value-file safety rule stated only for lens text → moved to Prompt directory and file names as a rule for every value file (findings and failure text included); "only multi-line values" sentence removed
- [I5] applied — `@<file>` trailing newline and empty file undefined → exactly one trailing newline removed; empty after removal counts as empty; two fixture cases added
- [M1] applied — Testing item 2: "four pointer sentences" → three
- [M2] applied — value files named for cycles and addenda; cycle reuses its round's lens file; addendum prompt named `addendum-<k>-fix.md`
- [M3] applied — `[FAILURE_BLOCK]`: heading line is in the controller's failure file, template holds only the placeholder
- [M4] applied — Testing item 3: in-run-rulings reason corrected (Procedure-range assertions pin phrases outside step 2 and the fix bullet)
- [M5] applied — fill-prompt: order extraction → dedent → fill; a less-indented body line exits 2
- [M6] applied — fix-prompt.md: no skills, no subagents rule added
- [M7] rejected: harness probe not runnable here — in a Git Bash session, Read (with the Read tool) a file whose path was printed by `mktemp -d`; observe whether the read succeeds — (tool missing) — Git Bash path form of the pointer on Windows

## Round 2 — Ambiguity & testability — claude-fable-5-1
**Reviewer verdict:** 0 Critical, 3 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — Acceptance measure: metric defined only by reference to an untracked file → unit, denominator (transcript content classes), numerator (Agent prompts, value-file writes, fill-prompt commands, template/prompt-file reads) and exclusions stated inline; measuring script written from these rules at measurement time, not part of this branch
- [I2] applied — fill-prompt Strictness: "wrapper" undefined → defined as the non-body lines of the first fenced block; legend never scanned; unit test with a legend-only name (`PLAN_PATH`) exits 4
- [I3] applied — data flow and pointer: untestable byte-identity claim and a pointer sentence the template does not carry → replaced by the testable property (template body filled under the legend's rules, asserted by the fill test); the "do not read other files there" sentence named as the one sanctioned exception, pinned by the wording test
- [M1] applied — argument grammar: split at first `=`, inline value cannot start with `@`, usage error exit 1
- [M2] applied — whitespace-only lines written as empty lines; trailing newline rule for the output
- [M3] applied — Error handling row 2: fallback unit is every dispatch the file serves (all M reviewers of the round, or the one fix dispatch)
- [M4] applied — Testing item 2: pointer needles named (fixed prefix plus the two fixed sentences in full)
- [M5] applied — fix-prompt.md: each rule carries its quoted test clause; the no-skill/no-subagent rule marked as an addition
- [M6] applied — grep claim qualified: GNU `grep -r` ignores .gitignore, ripgrep (the Grep tool) does not
- [M7] applied — Problem: heredoc estimate restated with the measured denominator (338 KB of 813 KB; ~137 KB after, about 17 percent)
- [M8] rejected: harness probe not runnable here — on Windows Git Bash, run `mktemp -d`, write one file into it with the Write tool by the printed path, then Read it by that path; observe whether both tools resolve it — (tool missing) — `mktemp -d` path usable by the Write and Read tools on Windows Git Bash

_Completed — 2026-09-05 — 2 rounds, cap reached (N=2); not converged (round 2 not clean)_
