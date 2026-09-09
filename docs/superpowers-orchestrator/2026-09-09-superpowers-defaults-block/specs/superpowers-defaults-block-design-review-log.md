# Review log — superpowers-defaults-block-design.md

_Invocation 1 — 2026-09-09 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — opus-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 7 Important, 4 Minor | r2: 1 Critical, 9 Important, 5 Minor | r3: 0 Critical, 6 Important, 4 Minor
**Sources mapped:** 36/36
**Reviewer verdict:** 1 Critical, 12 Important, 7 Minor
**Converged:** no

### Dispositions
- [C1] applied — Parameter table: 1–5 read as clamping a user-stated task count X, silently capping "implement the next 8 tasks" at 3 → new "What the ranges constrain" paragraph limits 1–5 to the variable and the block line; X stays unbounded ← 1/3: r2:C1
- [I1] applied — Block format / resolution rule: "complete" used in two incompatible senses → defined once as delimiters only (opening and closing line), and the "always complete" sentence reworded to "always carries every parameter" ← 3/3: r1:I1, r2:I5, r3:I2
- [I2] applied — Offered-default rule: N's list already holds four options, so the construction yields five and no drop rule was given → explicit build order (offered, 3, 2, 4; stop at three; append 0), reproducing today's list when offered is 3 ← 3/3: r1:I2, r2:I7, r3:I1
- [I3] applied — Placeholder names: Phase 0 asks two counts, N_plan and N_code → new paragraph states one review-rounds value seeds both and <d-n> appears twice ← 3/3: r1:I3, r2:I2, r3:I3
- [I4] applied — Testing strategy: the existing D_MARKER / span-equality anti-drift block contradicts the new assertions → spec now names its removal and the citation asserts that replace it ← 3/3: r1:I7, r2:I6, r3:M2
- [I5] applied — Silent paths: one edit site named where the tag occurs 15 times across six skills → new "Edit-site inventory" section with per-file counts and the three sites needing more than a name substitution ← 2/3: r1:I4, r2:I9
- [I6] applied — Silent paths: the two resume-from-review-log paths fall back to a hardcoded 3 without asking → both added, with the origin sentence they must print when the value comes from the block ← 2/3: r1:I5, r2:I4
- [I7] applied — Parameter table: review-rounds=0 would silently disable spec, plan and code review on every session → 0 removed from the accepted values; N=0 stays available per invocation and per question ← 2/3: r1:I6, r2:I8
- [I8] applied — Resolution rule: deleting the skills' local rules would drop the tier-1 injection guard → first property now covers every tier, naming the two rules it replaces ← 1/3: r2:I1
- [I9] applied — Silent paths: direct invocation undefined → new non-goal and an explicit sentence; the block changes the offered value, never suppresses a question ← 1/3: r2:I3
- [I10] applied — Silent paths: "meaning preserved exactly" was false, since naming the block gives N a last resort it lacks today → phrase dropped, the change stated as intended ← 1/3: r3:I4
- [I11] applied — Architecture: "subagents never receive it" contradicted by forks (orchestrating-development:1337) → reworded; a fork may see the block and still resolves nothing from it ← 1/3: r3:I5
- [I12] applied — Error handling: no behaviour specified when compaction drops the block → new table row; a value already resolved in a run is kept and never re-resolved mid-run (harness field dropped: repository-readable) ← 1/3: r3:I6
- [M1] applied — Documentation: the canonical structure had no platform field, dropping a true caveat → sixth field "where it is honored" added, plus a non-goal recording that the Codex adapter emits no block ← 3/3: r1:M1, r2:M3, r3:M4
- [M2] applied — Documentation: docs/FORK-IMPROVEMENTS.md:133 and :176 name the tag and the replaced test file → both added to the update list ← 2/3: r1:M2, r2:M2
- [M3] applied — Resolution rule: the controller-template sub-rules were lost → fourth property carries both, generalized to any parameter ← 2/3: r1:M3, r2:M4
- [M4] applied — Edit-site inventory: the cited line was 70; the sentence is at 83 → corrected throughout ← 2/3: r2:M1, r3:M1
- [M5] applied — Offered-default rule: N's "3 (recommended)" becomes "3 (current default)" → recorded as an intended wording change so it is not read as an accidental edit ← 1/3: r1:M4
- [M6] applied — Error handling: no row for an invalid line value or a repeated line → both rows added ← 1/3: r2:M5
- [M7] applied — Testing strategy: the ambient-environment guard covers one variable only → generalized to all three, with the reason it exists ← 1/3: r3:M3

## Round 2 — Ambiguity & testability — opus-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 7 Important, 8 Minor | r2: 0 Critical, 5 Important, 7 Minor | r3: 0 Critical, 7 Important, 7 Minor
**Sources mapped:** 42/42
**Reviewer verdict:** 1 Critical, 13 Important, 13 Minor
**Converged:** no

### Dispositions
- [C1] applied — Testing strategy: the shared rejected-form list held `6`, which round 1 made an ACCEPTED value for review-rounds; a literal reading would narrow the case alternatives and break the 6-10 range the design exists for → rejected forms now split per parameter ← 2/3: r1:C1, r3:I1
- [I1] applied — Testing strategy: "each of the five citing skills names that section exactly once" cannot pass, since SDD alone needs four citation sites → "at least once", plus a per-file expected count table ← 3/3: r1:I2, r2:I1, r3:I5
- [I2] applied — Edit-site inventory: built from the tag string only, so it missed the 34 `<d>` sites (brainstorming 11, writing-plans 11, SDD 10, orchestrating 2; all verified) → second inventory table added with the default placeholder mapping ← 3/3: r1:M2, r2:M3, r3:I6
- [I3] applied — Error handling: "run" was undefined and the kept-value rule untestable → "run" defined as one skill invocation, and the row rewritten around the verified compact wiring ← 2/3: r1:I1, r3:I7
- [I4] applied — What the ranges constrain: "nowhere else" contradicted Phase 0's preserved question `batch cap (1-5, default 3). Invalid → default` → both entry points now state their own validity range ← 2/3: r1:I3, r3:I2
- [I5] applied — Testing strategy: the comparison rule had no operand once the span comparison was removed → exact citation marker string defined, and the rule attached to it ← 2/3: r1:I5, r2:I2
- [I6] applied — Error handling: the compaction premise was an uncited platform claim; `hooks/hooks.json:5` and `hooks/hooks-cursor.json:6` both match `startup|clear|compact`, so session-start re-runs and the block is re-injected → row rewritten around that citation ← 2/3: r1:I6, r2:M6
- [I7] applied — Resolution rule: tier 1 said "if valid" with no validity set defined anywhere → per-parameter invocation-validity table added to the rule ← 2/3: r2:M5, r3:I3
- [I8] applied — Architecture: the fork sentence was neither rule nor observation → marked a design assumption that produces no edit and no test ← 1/3: r1:I4
- [I9] applied — Offered-default rule: Phase 0's N questions are prose, so "presented first" had no meaning → sentence added matching the cap question's ← 1/3: r1:I7
- [I10] applied — Resolution rule: tier 2 selected by origin while the properties selected by position; the two diverge for a block pasted in a user message → origin made the single criterion, position kept as defence in depth ← 1/3: r2:I3
- [I11] applied — Error handling: no row named a test → verification column added, marking each row hook-tested or prose-only ← 1/3: r2:I4
- [I12] applied — Offered-default rule: the document never said which file holds it → placed in the same `Resolving a default` section, stated explicitly ← 1/3: r2:I5
- [I13] applied — Silent paths: gate invocations under orchestration run inside a dispatched controller that never receives the block, so the prose promised tier 2 where tier 3 would apply → each path now names its execution context; a controller takes values from its template, as M already does ← 1/3: r3:I4
- [M1] applied — Block format: the emitted string's leading separator was unspecified while a test must assert it exactly → the two leading newlines of hooks/session-start:436 are now part of the stated format, with the reader's tolerance rule ← 3/3: r1:M7, r2:M4, r3:M1
- [M2] applied — Non-goals: the "twelve/eight knobs" counts were uncheckable → counts dropped ← 2/3: r1:M4, r2:M1
- [M3] applied — Documentation: the override field is meaningless for the three hook-internal variables → it reads "not overridable in an invocation" for them ← 2/3: r1:M5, r3:M4
- [M4] applied — Resolution rule: tier 3 pointed at "the skill", leaving the legacy log-line M=1 convention unaddressed → the parameter table is named the single source, and that convention recorded as surviving unchanged ← 1/3: r1:M1
- [M5] applied — Error handling: the repeated-line row describes a state the hook cannot emit → kept, marked defensive and out of test scope ← 1/3: r1:M3
- [M6] applied — Silent paths: the five paths overlapped, so the count was not a checklist → regrouped by execution context ← 1/3: r1:M8
- [M7] applied — Testing strategy: the span-block line range was wrong; extraction ends at 347 and the identity loop is 348-351 → corrected ← 1/3: r2:M2
- [M8] applied — Error handling: unclear which parameters produce a completion-message note → stated per parameter ← 1/3: r2:M7
- [M9] applied — Offered-default rule: "the block value" is undefined when no block exists → reworded to "the value resolved by `Resolving a default`" ← 1/3: r3:M2
- [M10] applied — Complete block: pairing was undefined when an unclosed opening line precedes the hook's block → scan-backwards pairing rule stated ← 1/3: r3:M3
- [M11] applied — N's option list: SDD:116's zero option carries the label `0 — skip; the branch finishes with no whole-branch review` → stated that each gate keeps its own zero-option label text ← 1/3: r3:M5
- [M12] applied — Silent paths: the third origin sentence was described but not written → given verbatim ← 1/3: r3:M6
- [M13] rejected: harness probe not runnable here — start a session, invoke a skill, change that skill's file in the installed plugin cache, invoke it again in the same session, and observe whether the changed text is used — (would break a constraint) ← 1/3: r3:M7

## Round 3 — Feasibility & architecture risk — opus-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 2 Important, 4 Minor | r2: 1 Critical, 4 Important, 5 Minor | r3: 1 Critical, 4 Important, 3 Minor
**Sources mapped:** 25/25
**Reviewer verdict:** 1 Critical, 5 Important, 10 Minor
**Converged:** no

### Dispositions
- [C1] applied — Block format: all three reviewers independently found that `hooks/session-start:436` builds its tag as a bash double-quoted "\n", which is a literal backslash-n, and escape_for_json then doubles the backslash, so the block would arrive as ONE physical line and every line-based reader rule would match nothing, silently dropping the whole feature to tier 3. Controller reproduced it and the fix: double-quoted form gives 1 line, ANSI-C `$'...'` gives 5 real lines through the same escaper → the spec now requires real newlines, warns that this differs from line 436, and requires the test to assert the JSON-decoded additionalContext ← 3/3: r1:C1, r2:C1, r3:C1
- [I1] applied — Edit-site inventory: the two greps missed every site stating N's default as a bare literal, including multi-doc-review:36-38 and multi-code-review:75-83 — the very files where N is resolved, so review-rounds would have been emitted and never read on those paths → third grep added with the file-and-line list, plus SDD:286-290 ← 3/3: r1:I1, r2:I2, r3:I2
- [I2] applied — Documentation: docs/guide/README.md never names the tag, so "where it describes the tag" reached nothing; its Phase 0 table at 516-520 states the three defaults this design moves, and 885-896 documents M's variable alone → both sites named explicitly ← 3/3: r1:I2, r2:I4, r3:I4
- [I3] applied — Testing strategy: no test file SETS the variable — two unset it and test-helpers only detects it in settings.json; their other "reviewers-per-lens" mentions are review-log field names that must not be renamed → behavioral work restated as exactly two edits, with the review-log string declared out of scope ← 2/3: r2:I1, r3:I3
- [I4] applied — Placeholder names: the mapping rule's second branch is unreachable, since all 34 `<d>` sites are M sites; the novel work is introducing `<d-n>` and `<d-cap>` where the default is the literal 3 → rule simplified to "all 34 become `<d-m>`", with the introduction sites listed ← 1/3: r2:I3
- [I5] applied — Resolution rule: a bare citation has no precedent in this repository (every cross-skill reference restates the rule inline) and `skills/multi-doc-review/SKILL.md` is not resolvable at run time, since the session's working directory is the user's project while the plugin lives in the cache → citation sentence KEPT and paired with a short self-contained restatement of the three tiers at each site; this partially reverses the mechanism choice and is flagged for the user ← 1/3: r3:I1
- [M1] applied — Documentation: SP_NO_COMPRESS is not in README's Environment variables section at all; it lives at README.md:394 in the hook inventory → stated as an addition, with 394 kept as a cross-reference ← 3/3: r1:M1, r2:M5, r3:M1
- [M2] applied — Non-goals: OpenCode is a fourth delivery path that never runs hooks/session-start → named alongside Codex as a platform resolving everything at tier 3 ← 1/3: r1:M2
- [M3] applied — Testing strategy: per-file citation counts are predictions about an edit not yet made → contract is "at least once"; counts recorded as expected, not asserted ← 1/3: r1:M3
- [M4] applied — Rollout: the mechanism claim was unverified and half of it is now known false, since the block is re-injected on compact → mechanism claim dropped, observable advice kept (harness field dropped: repository-readable) ← 1/3: r1:M4
- [M5] applied — Resolution rule: citations off by two; the controller sub-rules are at multi-doc-review:70-71 and the legacy convention runs brainstorming:78-82 → corrected ← 1/3: r2:M1
- [M6] applied — Block format: "and a closing newline" contradicted the literal string shown below it → literal and prose reconciled ← 1/3: r2:M2
- [M7] applied — Edit-site inventory: "neither grep finds them" was wrong for the 296-300 span, since line 299 carries the tag → claim narrowed to the N clause on line 296 ← 1/3: r2:M3
- [M8] applied — Testing strategy: `<D>` is a live Artifact Layout placeholder in three skills, so a case-insensitive `<d>` check would fail permanently → assertion declared case-sensitive ← 1/3: r2:M4
- [M9] applied — Resolution rule: fill-prompt.js exits 3 on an unfilled body placeholder, so that state cannot arise on the orchestration path → labelled defensive only ← 1/3: r3:M2
- [M10] applied — Testing strategy: the replaced test runs in an empty temporary directory, so the ordering assertion would pass vacuously → the new test must first write a workspace file carrying a decoy block ← 1/3: r3:M3

## Round 4 — Adversarial failure modes — opus-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 1 Critical, 4 Important, 3 Minor | r2: 1 Critical, 4 Important, 3 Minor | r3: 2 Critical, 5 Important, 2 Minor
**Sources mapped:** 25/25
**Reviewer verdict:** 4 Critical, 7 Important, 8 Minor
**Converged:** no

### Dispositions
- [C1] applied — Resolution rule: "the last complete block in the context" selects a LATER-loaded skill body, doc or diff, and this design puts literal example blocks in exactly those places; today's M rule scopes it as "the last such element inside the injected block" and the rewrite dropped that phrase → scoping restored everywhere position is mentioned, plus a normative ban on any complete block in a skill body, a doc or this spec, and a wording assertion for it — harness probe: the session-start injection arrived before every skill body loaded later in this session, so a later example would indeed be last ← 2/3: r1:C1, r3:I1
- [C2] applied — Non-goals vs resolution rule: on Codex the adapter embeds project-map, session-log, state and known-issues but emits NO block, so a block planted in any of them is the only and last one, and repository content would choose N, M and the cap; the always-emit defence does not exist there → platform clause added: where hooks/session-start does not run, ignore every block and resolve tier 3 unconditionally ← 2/3: r2:C1, r1:I1
- [C3] applied — Resolution rule: the citing sites were to restate only the three tiers, leaving the origin and tool-result guards in a file the design itself says is unfetchable — in the two skills whose job is reading attacker-controlled files → minimum restatement content specified, and it includes both guards ← 1/3: r3:C1
- [C4] applied — Resolution rule: widening the tool-result guard from "the controller" to "the session or a controller", with "a review log" in the list, forbids the resume paths from reading the N and M their own log records → guard re-scoped to the controller, with an explicit carve-out for a gate reading its own review log's invocation line ← 1/3: r3:C2
- [I1] applied — Parameter table: the argument that bans 0 applies equally to a forgotten high value, which silently takes an unattended gate from 3 to about 50 reviewer subagents, and the design refused any note → never-ask paths must now echo the resolved value and its source ← 3/3: r1:I3, r2:I1, r3:I4
- [I2] applied — Execution contexts: the Phase 3 batch controller was missing, yet it is where SDD's cap and N sentences are read; the block is unreachable there → row added, and the :83 and :299 rewrites must hold in both contexts ← 2/3: r2:I3, r3:I3
- [I3] applied — Origin sentences: only the block form was given, so a resume on a platform with no block would attribute the value to a block never injected → two forms, one per tier, each bound to when it applies ← 2/3: r2:I4, r3:I5
- [I4] applied — Offered-default rule: "recommended" for any value differing from the default labels a WEAKER setting as advice, since N and the cap can be set below default unlike M → label split by direction, with a neutral form for a weaker value ← 1/3: r1:I2
- [I5] applied — Batched Autonomous Mode: its resume prompt carries only M, so X and N re-resolve after every /clear, contradicting this design's own "a pipeline never re-resolves mid-flight" → cross-resume behaviour stated, with X and N carried in the resume prompt ← 1/3: r1:I4
- [I6] applied — Reader tolerance: strictness was presented as a defence though the reader is a model and every such row is prose-only; and the newline bug would present intermittently, not as a uniform silent tier 3 → restated as a writing convention, and the consequence reworded as possibly non-deterministic ← 1/3: r2:I2
- [I7] applied — Resolution rule: origin cannot separate a decoy inside an embedded workspace file, because hooks/session-start concatenates those files into the same additionalContext — same origin → the two defences are now described as covering different attacks, neither redundant ← 1/3: r3:I2
- [M1] applied — Testing strategy: the existing test already writes a decoy state.md and runs both an unset and a set assertion; the replacement described only one → both decoy cases required ← 1/3: r1:M1
- [M2] applied — Rollout: the window was described for M alone → all three parameters and both directions named ← 1/3: r1:M2
- [M3] applied — Block format: "matching the spacing the current tag has" pointed at the very construction the section warns against ← 1/3: r1:M3
- [M4] applied — Block format: escape_for_json was quoted inexactly → quoted verbatim from hooks/session-start:452 ← 1/3: r2:M1
- [M5] applied — Testing strategy: three test files carry comments describing the tag that read false once it is removed → "exactly two edits" corrected ← 1/3: r2:M2
- [M6] rejected: harness probe not runnable here — register a second SessionStart hook in a scratch settings file that emits a block as additionalContext, start one session, and read the delivered context to see whether it lands before or after superpowers' block — (would break a constraint) ← 1/3: r2:M3
- [M7] applied — Ranges: an invalid X fell to tier 2, so "implement the next 0 tasks" would implement 3; the one fallback that turns a stated no into action → X=0 is an explicit stop ← 1/3: r3:M1
- [M8] applied — Testing strategy: hooks/session-start embeds project-map.md in full only under 200 lines, so the decoy fixture could be silently discarded → fixture must stay under the threshold and the test must assert the decoy is present before asserting order ← 1/3: r3:M2
