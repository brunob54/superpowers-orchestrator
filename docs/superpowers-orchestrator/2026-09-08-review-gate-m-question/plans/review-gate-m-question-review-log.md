# Review log — review-gate-m-question.md

_Invocation 1 — 2026-09-08 — N=3 M=3 — gate: orchestration_

## Round 1 — Correctness & completeness — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 2 Critical, 2 Important, 4 Minor | r2: 1 Critical, 6 Important, 5 Minor | r3: 1 Critical, 4 Important, 3 Minor
**Sources mapped:** 28/28
**Reviewer verdict:** 4 Critical, 5 Important, 8 Minor
**Converged:** no

### Dispositions
- [C1] applied — Task 1 Step 3: the third edit named line range 56–61, which does not match the sentence it replaces and would delete the default-branch BASE clause and the whole `Single-argument form:` rule → rewritten as a text-anchored replacement, both neighbours quoted, two survival greps added, and the contract invariant extended ← 3/3: r1:I2, r2:I3, r3:C1
- [C2] applied — Task 6 Steps 1/2/4 and Contract: `grep -rn 'asks for N once' docs/ README.md` can never print nothing, because the plan and its spec live under `docs/` and quote the phrase (8 hits verified) → scoped to `README.md docs/FORK-IMPROVEMENTS.md docs/guide/README.md`, both expectations restated ← 2/3: r1:C1, r3:I1
- [C3] applied — Task 1 Step 4b and Task 5 Step 2b: both `perl -pi` mutation proofs target strings that wrap across two lines, so both substitutions are no-ops and both suites exit 0 instead of 1 → single-line fragments (`ask for M.**`, `else 1 — a`), a `grep -c` guard before each, and a note that `perl -pi` is line-oriented ← 2/3: r1:C2, r2:I1, r2:I2
- [C4] applied — Task 1 Steps 3 and 4b: `git checkout -- skills/multi-doc-review/SKILL.md` restores from the index, discarding Step 3's unstaged edits → Step 3 now stages the three files, and Step 4b's expectation names the index restore ← 1/3: r2:C1
- [I1] applied — Task 6 Step 3: the README bullets are lines 32/33 and 367/368 (not 33/34 and 368/369) and the FORK-IMPROVEMENTS `**Automatic:**` bullet is line 169 (not 170) → numbers corrected and every edit keyed to the bullet's opening text ← 3/3: r1:M1, r2:I6, r3:I3
- [I2] applied — Task 4 Step 3, Contract and test block: the `## Integration` section keeps a second, narrower copy of the fallback condition ("On platforms without the Agent tool") that the new step 4 points at for Cursor → the Integration sentence is edited too, with a span-scoped assertion pair ← 2/3: r2:I4, r3:I2
- [I3] applied — Global Constraints: "A gate always invokes the review skill" dropped spec R6's platform exception and contradicted the three skip paths → reworded with the R6 condition-1 exception, and the token constraint qualified to paths that reach the invocation ← 1/3: r1:I1
- [I4] applied — Global Constraints and the three gate texts: spec R1's "in one question batch" had no implementing wording → added to all three gate questions, to a new global constraint, to the three contracts, and pinned as a fifth shared-block byte pin ← 1/3: r2:I5
- [I5] applied — Task 6 Contract: the invariant "every command form that shows `[M=<m>]` also shows the `N=<n>` form" is contradicted by `docs/REVIEW-PROCESS-COMPARISON.md:195,219`, which no task edits → invariant narrowed to the four edited files, exclusion recorded with its reason (that file is a dated snapshot) ← 1/3: r3:I4
- [M1] applied — Task 6 "Does NOT cover": spec §7 asks to check `docs/FORK-IMPROVEMENTS.md:148`, which no step mentioned → recorded as checked and deliberately unchanged, with the reason ← 3/3: r1:M3, r2:M2, r3:M1
- [M2] applied — Task 5 Step 2 and Task 6 Step 2 were titled "Run test to verify it fails" while expecting a pass → both renamed "Record the pre-change state", each naming its real falsification step ← 2/3: r2:M4, r3:M3
- [M3] applied — Task 6 Step 3: `docs/guide/README.md`'s `SUPERPOWERS_REVIEWERS_PER_LENS` paragraph (~875) mirrors `README.md:379` and was not updated → added to the edit list; guide line 509 (Phase 0 table) recorded as deliberately unchanged ← 1/3: r1:M2
- [M4] applied — Task 7 Contract and Step 4: the check grepped only the literal `7.12.0`, so a location left at 7.11.0 could not be detected → version-pattern grep with `sort -u` plus an exact README count ← 1/3: r1:M4
- [M5] applied — Task 5 Contract: the block reads `D_MARKER`/`D_TAIL`, which Task 2's block defines → the ordering dependency is stated in the contract's Inputs ← 1/3: r2:M1
- [M6] applied — Task 1 Step 1: the `slice_to` comment described the wrong argument positions → corrected to match the signature ← 1/3: r2:M3
- [M7] applied — Tasks 2 and 3 gate texts: the suppression sentence used `<d>` before the same item defines it → now reads "M's default `<d>` (defined below)" ← 1/3: r2:M5
- [M8] applied — Task 1 Step 1 `assert_order`: empty offsets from an unresolved span raise "integer expression expected" → both offsets default to 0 ← 1/3: r3:M2

## Round 2 — Ambiguity & testability — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 6 Minor | r2: 0 Critical, 4 Important, 7 Minor | r3: 0 Critical, 4 Important, 7 Minor
**Sources mapped:** 31/31
**Reviewer verdict:** 0 Critical, 6 Important, 14 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 4 Step 3, the `## Integration` correction: the prose named one sentence while the replacement block also repeats the preceding clause `(session model, sonnet floor).`, so a literal reading duplicates it → the replacement span is now stated explicitly, from that clause through `code-reviewer.md.` ← 3/3: r1:I1, r2:I2, r3:M4
- [I2] applied — Task 6 Contract vs Step 3: the invariant on command forms was unsatisfiable while `docs/FORK-IMPROVEMENTS.md:170` (`[BASE] [N] [M=<m>]`) was marked "must not be touched" → line 170 added to the edit list, line 128 recorded as an example rather than a bracket form, and a `grep -n '\[N\] \[M=<m>\]'` check added to Steps 2 and 4 ← 3/3: r1:I2, r2:I1, r3:I1
- [I3] applied — Task 4 Contract: the invariants on the carried-over half of step 4 (`TOPIC_DIR` derivation, outside-the-layout direct mode, completion-blocking sentence) had no assertion → three byte pins added to the block and named in the Verification field ← 3/3: r1:M4, r2:I4, r3:I3
- [I4] applied — Task 7: the drafted `RELEASE-NOTES.md` summary was 134 words against the plan's own 120-word limit → trimmed to 119 words, and a `wc -w` check added to Step 4 and to the contract ← 2/3: r2:I3, r3:I2
- [I5] applied — Tasks 2 and 3 gate texts: the suppression path mandated the sentence "recorded on the log's invocation line" even when the values fell back to defaults, and the shared block mandated a second, different template for the same situation → the suppression echo is now two sentences chosen by the path taken, and the shared block's template is scoped to the user-stated case ← 1/3: r1:I3
- [I6] applied — Tasks 2, 3 and 4 Step 3 preambles: the copy source was cited as `skills/orchestrating-development/SKILL.md:234–238`, a range whose tail carries `; one M applies to Phase 2 and Phase 4` — wording a gate must not hold, and which block 2 cannot see → the line reference is replaced by the span the suite compares, with the Phase tail named as excluded ← 1/3: r3:I4
- [M1] applied — Task 6 Step 3: both README anchors are already followed by `, or direct:`, so the stated insertions produce a double comma → both edits restated as full replacements ← 2/3: r1:M2, r3:M3
- [M2] applied — Task 6 Step 1 duplicated Step 2 and was labelled "Write failing test" while expecting a pass; Task 7 Step 1 carried the same label → Task 6 Step 1 now states why no assertion exists and runs no command; Task 7 Step 1 renamed "Record the pre-change state" ← 2/3: r1:M3, r2:M7
- [M3] applied — Task 1: the frontmatter `description` edit appeared in no contract and no assertion → added to both wording contracts and pinned by two new assertions ← 2/3: r2:M1, r3:M7
- [M4] applied — Tasks 2, 3 and 4 Contracts: "R4's cost sentence appears character for character" claims more than `assert_icontains` (`grep -iF`) can falsify → reworded to "with the spec's wording, matched case-insensitively", naming spec §9's free-text rule ← 2/3: r2:M4, r3:M2
- [M5] applied — Tasks 3 and 4 Contracts: their test blocks read `ANCHOR`, `COST_LINE`, `SHARED_PINS` and the rest, which only Task 2's block defines, under `set -u` → the ordering dependency is now stated in both contracts, as Task 5 already states its own ← 1/3: r1:M1
- [M6] applied — Task 6 Step 3: `docs/guide/README.md:227` keeps "(same M reviewers per round)", which the gate question makes wrong → the parenthetical is now replaced, and a `grep` for it added to Steps 2 and 4 ← 1/3: r1:M5
- [M7] applied — Task 6 Step 3: the two `tests/claude-code/test-multi-doc-review.sh` replacements land inside `#`-prefixed comment blocks and were given as unwrapped prose → the step now requires re-wrapping and a `# ` prefix on every line ← 1/3: r1:M6
- [M8] applied — Task 5 Contract: the `CLAUDE.md` invariant pins the line's position while `grep -n` matched anywhere in the file → replaced with an `awk`-scoped count over the first fenced block of `## Testing`, in the contract and in Step 4 ← 1/3: r2:M2
- [M9] applied — Task 1: the plan's cross-platform constraint (no `/dev/stdin`, no process substitution) had no check → `grep -c '/dev/stdin\|<('` added to Step 4 and to the contract ← 1/3: r2:M3
- [M10] applied — Task 6 Step 3: "add after the first sentence" is ambiguous in two multi-clause guide paragraphs → the Stage 2 edit is now a full replacement and the Stage 4 insert quotes the exact text it follows ← 1/3: r2:M5
- [M11] applied — Task 3 Contract: "the section still tells the writer to re-run only Self-Review" had no assertion → one added to block 11 and named in the Verification field ← 1/3: r2:M6
- [M12] applied — Task 1 and Task 7 Contracts: the BASE ref charset rule, the Batched Autonomous Mode sentence and the README badge were invariants with no check → four survival assertions added to block 10 and a `grep -c 'version-7\.12\.0-white'` to Task 7 Step 4 ← 1/3: r3:M1
- [M13] applied — Task 1 Step 4b and Task 5 Step 2b: their "Expected" text named `git diff`/`git status` commands absent from the `Run:` blocks → both commands added to the blocks ← 1/3: r3:M5
- [M14] applied — Task 4 Step 1: `CG_FINDINGS`/`CG_TOKENS` lacked the `${x:-0}` default that `assert_order` applies, so an unresolved span raises "integer expression expected" → both defaulted to 0 ← 1/3: r3:M6

## Round 3 — Feasibility & architecture risk — claude-opus-5[1m]
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 2 Minor | r2: 0 Critical, 2 Important, 5 Minor | r3: 0 Critical, 2 Important, 3 Minor
**Sources mapped:** 17/17
**Reviewer verdict:** 0 Critical, 4 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — Task 6 Step 3: two `docs/guide/README.md` anchors are quoted as single strings but wrap across lines (227–228 and 265–266), so a literal replacement matches nothing → both edits now say the anchor crosses a line break and must be matched across it and re-wrapped ← 3/3: r1:I1, r2:M4, r3:M2
- [I2] applied — Task 7: the drafted `RELEASE-NOTES.md` summary measures 123 with `wc -w` (which counts the stand-alone em dashes) against the task's own "at most 120" check → summary trimmed to 112 as measured by that command, and Step 4's expectation states the measured figure and why a margin is needed ← 3/3: r1:I2, r2:I1, r3:I2
- [I3] applied — Tasks 1, 3 and 4 Step 2: the expected-failure lists included regression pins that pass on the unmodified tree (the four survival assertions, "re-run only Self-Review", the three carried-over pins) → each list now names only the assertions that genuinely fail, and says which pins pass already ← 3/3: r1:I3, r2:M1, r3:I1
- [I4] applied — Task 4 Step 3: the Batched Autonomous Mode exception sat after the question, although spec R6 lists that mode as a suppression condition and this plan's Assumptions state a suppression check after the question defeats its purpose → the exception moved to directly after the platform check, a fourth ordering assertion added, and the contract's ordering and invariants updated ← 1/3: r2:I2
- [M1] applied — Task 5: the `CLAUDE.md` position check used `/^```$/`, which never matches the ```` ```bash ```` opening fences, so the window ran past the first block → fence pattern changed to `/^```/` in the contract and in Step 4, with the reason recorded ← 3/3: r1:M1, r2:M2, r3:M1
- [M2] applied — Task 5 Contract: the ordering dependency named only Task 2, but the marker-count assertions need the `<d>` spans Tasks 3 and 4 write → changed to "after Tasks 2, 3 and 4", with the zero-marker fact recorded ← 2/3: r1:M2, r2:M5
- [M3] applied — Task 1 Step 3: `skills/multi-code-review/SKILL.md` carries the command form a second time in its `TOPIC_DIR` bullet, which the task left at `[N] [M=<m>]` while changing the frontmatter → that copy added to the edit list and to the contract ← 1/3: r2:M3
- [M4] applied — Task 4 Step 3: the Integration end anchor was written `code-reviewer.md.`, which is not literal — the file backticks the path → anchor restated as `` `requesting-code-review/code-reviewer.md`. `` ← 1/3: r3:M3

_Loop complete — 2026-09-08 — rounds 3_

### Post-loop self-review (writing-plans checklist)
- **1. Spec coverage** — every spec section maps to a task: §3/§4 R1–R7 and §5 → Tasks 2, 3, 4 (gate wording) and Task 1 (both skills parse `N=<n>`); §6 → the token-ordering assertion of Task 4; §7 → Tasks 1, 4 and 6; §8 → the shared rules block of each gate; §9's 14 assertions → Tasks 1–5; §10 F1/F3/F4 → Task 4's ordering fix, Task 4's "Does NOT cover" and Task 5's anti-drift block; §11 → Task 7. No gap found.
- **2. Placeholder scan** — no `TBD`, "add appropriate", or step without code. The only matches for the scan patterns are the template's own step title "Implement minimal change" (seven times).
- **3. Type/name consistency** — every shell variable read by a later task's test block is defined by an earlier one (checked mechanically over all fenced `bash` blocks: no variable used but never defined); `SDD_FILE_NORM`, dropped when the Integration span replaced it, is referenced nowhere.
- **4. Scope-reduction scan** — no "v1", "basic", "for now", "initial version" or unsanctioned "minimal"; the seven "minimal change" hits are the template's step titles.
- **5. Contract audit** — seven tasks, seven falsifiable `**Contract:**` fields, no `**Exact content:**` marker in any task step (the label appears only in the header's Body-authority note, which is out of scope). One fix applied: the cross-platform `**Global Constraints:**` entry cited only `CLAUDE.md`, an artifact Task 5 modifies; it now also cites spec §9, which states the same Git Bash constraint, so the entry traces to the spec and is not a self-pin.
