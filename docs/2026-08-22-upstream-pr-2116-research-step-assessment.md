# Assessment: porting upstream PR #2116 (research step in brainstorming)

**Date:** 2026-08-22
**Upstream PR:** https://github.com/obra/superpowers/pull/2116 (open, not merged)
**File changed upstream:** `skills/brainstorming/SKILL.md` (33 additions, 10 deletions)
**Verdict:** worth porting, with manual adaptation. The upstream diff does not apply to this fork.

## What the upstream PR does

It adds one conditional step to the brainstorming skill, between "ask
clarifying questions" and "propose 2-3 approaches":

- When a design decision depends on external technology — a library choice, an
  unfamiliar API (Application Programming Interface), or an architecture
  decision that is hard to reverse — brainstorming must dispatch **one
  read-only research subagent** before comparing approaches.
- The subagent must inspect the candidate technology's actual source code and
  test files — not only its README, documentation, issue threads, or
  popularity numbers. It reports usable APIs, patterns, edge cases, and
  boundaries, and it labels missing or contradictory evidence.
- Self-contained decisions (no external technology involved) skip the step.
- If subagent dispatch is not available on the platform, the skill must state
  the evidence gap and mark unsupported claims as provisional.

The motivating failure case: in a real session, brainstorming recommended the
pg-boss library over BullMQ and SQLite purely from model memory. It ran no
research, inspected no code, and presented compatibility and durability claims
with no source — for an infrastructure choice that is expensive to reverse.

## Evidence quality in the PR

- Behavioral evaluations: without the step, the test scenario failed (a
  confident recommendation with zero research). With the refined wording, it
  passed 7 of 7 deterministic checks. A control scenario confirmed the step
  correctly skips self-contained work (no over-triggering).
- An earlier wording was rejected during the PR's own testing because it let
  the subagent treat documentation and issue threads as implementation
  evidence. The final wording requires direct source and test inspection.
- Task-completion evaluations (2 paired runs on a DeepSWE subset) are weakly
  positive: 1 of 2 tasks moved from unsolved to solved, runtime +25.8%,
  cost −0.2%. These are one-attempt smoke runs, not statistically stable.
- One treatment run was excluded because the research subagent **edited the
  shared worktree** — the read-only constraint was instruction-only, and the
  instruction was violated. This is a known weakness the fork can fix
  structurally (see below).

## Why the fork should port it

1. **The gap exists here too.** The fork's brainstorming has an "Engineering
   Rigor" section and a failure-mode check, but nothing forces evidence for
   claims about external technology. Today it would reproduce the pg-boss
   failure case exactly.
2. **The fork amplifies the cost of the failure.** Upstream brainstorming
   hands off to a human-paced flow. This fork hands off to
   `orchestrating-development`, which runs plan writing, implementation, and
   code reviews **autonomously**. A wrong library choice in the spec
   propagates through the whole unattended pipeline: the code reviewers check
   the code against the spec, not the spec's technology choice against
   reality. A research step at the top of the pipeline is the cheapest place
   to catch this class of error.
3. **It fits existing fork conventions.** The fork's skills already use
   "dispatch a focused subagent" and "skip on platforms without the Agent
   tool" patterns.
4. **The fork can enforce read-only structurally.** Claude Code provides the
   `Explore` agent type, which has no write tools. Dispatching the research
   subagent as `Explore` prevents the worktree-editing failure that upstream
   could only forbid by instruction.
5. **Cost is bounded.** The step is conditional; the control evaluation
   confirmed trivial decisions skip it.

## Port considerations

- **Manual re-implementation, not a diff apply.** The fork's checklist,
  process graph, and sections have diverged from upstream (batched clarifying
  questions, scope decomposition, multi-doc-review gate, orchestration
  handoff; no visual companion, no spike/bounded/architectural paths). The
  port is: one new checklist step between current steps 3 and 4, two nodes in
  the process graph, and one guidance section — a single-file change in
  `skills/brainstorming/SKILL.md`.
- **Release chores apply:** version bump in the five usual files, a
  RELEASE-NOTES.md entry, and a `docs/guide/` check for affected wording. No
  `hooks/skill-rules.json` change — no skill is added or renamed.
- **Overlap with `deliberation` is complementary, not redundant.** The
  deliberation skill assembles named opinion perspectives when the decision
  space is unclear; this step gathers implementation evidence. A technology
  choice can use both. The ported text should say in one sentence that the
  research findings feed whichever comparison runs.
- **Upstream merge status:** the PR is open with a change-request review from
  the maintainer ("direction affirmed", five revisions required — see the
  "Related upstream discussion" section below). The fork is severed from
  upstream, so merge status does not block anything. The maintainer requested
  this exact design in the review of the earlier PR #386, so the change is
  likely to land upstream in some revised form; the port should adopt the
  requested revisions up front rather than copy the current PR text.

## Related upstream discussion (surveyed 2026-08-22)

A search of the obra/superpowers issue tracker shows this idea has a long
history and active maintainer engagement. In time order:

- **Issue #231 (closed, stale):** early ask to hook external code-research
  tools (for example Chunkhound) into the workflow. Maintainer answer: since
  v5.0 the skills honor `CLAUDE.md` instructions, so users can integrate
  research tools there. No skill change.
- **PR #386 (open, older):** first attempt at a research step — GitHub- and
  `gh`-specific ("search GitHub, present stars/license/update date"). The
  maintainer (obra) affirmed the idea but rejected the shape: *"I don't think
  it makes sense to tie this explicitly to the gh tool and github ... I think
  it makes sense that we explicitly tell the agent to use a subagent to do
  that research."* This comment set the design direction that #2116
  implements.
- **Issue #983 (closed, duplicate):** same ask, well argued — "the agent
  proposes approaches based entirely on what it already knows ... might
  suggest an API method that was deprecated two versions ago." A community
  comment reports that manually triggered research cycles "markedly improve"
  plans. Closed in favor of tracker #2129.
- **Issue #2093 (closed, split):** bundled two asks; the maintainer split it
  into #2128 (goal-setting step, needs evidence) and #2129 (research step).
- **Issue #2129 (open, tracker):** the canonical tracking issue for the
  research step. States that PR #2116 implements exactly this and the issue
  closes when the PR lands.
- **PR #724 (open, no maintainer response):** a separate
  "efficient-multi-agent-research" skill (partition items, parallel
  investigate, consolidate report). Different scope: bulk codebase
  investigation, not a brainstorming gate. Not a competitor to the port.
- **PR #1911 (closed, venue call):** a general "prefer mature open-source
  reuse" rule for the root CLAUDE.md — rejected because of where it would
  live, not its content.
- **PR #2116 author comment:** the author uses a research step routinely and
  suggests a possible future separate `/research-implementations` skill; the
  in-brainstorming step is the deliberately smaller version.

### The maintainer's full review of #2116 (most important finding)

The maintainer posted a change-request review: *"Direction affirmed ... this
was already the strongest outside submission of the window"* — but the PR
cannot land as written. Five substantive changes were requested. These are
directly useful for the port, because they are corrections to the exact text
we would otherwise copy:

1. **Re-key the trigger to an observable predicate.** "Unfamiliar external
   knowledge" and "project context is sufficient" are the model's
   self-assessment of its own recall — the same faculty that failed in the
   pg-boss case (a stale recommendation does not *feel* unfamiliar). Trigger
   instead on checkable facts: the decision introduces or replaces an
   external dependency, is difficult to reverse, or depends on
   version-sensitive API behavior.
2. **Recipe form, not prohibition form.** Replace "not only READMEs,
   documentation, issue threads..." with a positive recipe: report reusable
   patterns, APIs, edge cases, and boundaries, each with a source-file
   citation from the **external project's** implementation and tests. The
   prohibition wording also never says whose source files, so an agent could
   satisfy it by re-reading the local repository.
3. **Read-only compliance must be measured, not excluded.** The PR excluded
   the run where the research subagent edited the shared worktree — an
   observed violation rate of 1 in 3. This directly supports the fork's plan
   to enforce read-only structurally via the `Explore` agent type instead of
   by instruction.
4. **One gate, one phrasing.** The PR states the trigger in three different
   wordings and the skip condition in two. The single predicate must be
   mirrored verbatim in the checklist, the process graph, and the prose.
5. **Evaluation coverage.** All PR evaluations ran on Codex-family models;
   Claude — the skill's primary consumer — was never tested. The +25.8%
   runtime cost also touches a documented maintainer concern: commit
   `3f80f1c` upstream removed subagent loops from brainstorming for exactly
   that overhead profile.

## Wider context: web survey (2026-08-22)

Four parallel research subagents surveyed the web from four angles: AI
coding-agent workflows, traditional software-engineering practice, academic
evidence on LLM (large language model) grounding, and design-document review
cultures. Summary of each, with the sources that matter most.

### 1. AI coding-agent workflows: the step is now standard, vendor-endorsed practice

Every major vendor now tells users to research before implementing:

- **Anthropic** (Claude Code best practices,
  https://code.claude.com/docs/en/best-practices): a dedicated section
  "Explore first, then plan, then code" — separate research and planning from
  implementation "to avoid solving the wrong problem", use read-only plan
  mode, use subagents for investigation.
- **GitHub Spec Kit** (https://github.com/github/spec-kit): its `/plan` phase
  spawns dedicated research agents that write a `research.md` artifact before
  any code — the closest existing analogue to what the port adds.
- **Devin** (Cognition): the built-in planning phase is restricted to
  read-only tools before any edit — the same structural enforcement the fork
  plans via the `Explore` agent type.
- **OpenAI Codex** best practices: "skipping the planning step on hard tasks
  is the most common cause of degraded sessions."
- **Cursor**: "ask the agent to explore first."
- **Microsoft, Google, and Context7** push MCP (Model Context Protocol)
  documentation servers as a grounding step, because "the agent invents an
  API" when it relies on training data.

Two observations relevant to the port: most vendor guidance means *reading
the local codebase*; grounding in *external* library source and tests — what
PR #2116 requires — is the less common, stricter form (documentation fetching
is the usual external form). And every vendor states the same skip condition
the PR has: trivial tasks do not need the step.

### 2. Traditional engineering practice: a prior-art step is textbook standard

The practice long predates AI agents:

- **Code Complete** (McConnell), chapter "Measure Twice, Cut Once": upstream
  prerequisites — including build-versus-buy for major components — come
  before construction; skipping them multiplies rework cost.
- **SWEBOK v4.0** (IEEE): reuse "is best practiced systematically, according
  to a well-defined, repeatable process"; component selection is a defined
  evaluation step, not improvisation.
- **Spolsky's "In Defense of Not-Invented-Here"**: the standard decision
  rule — build only what is core to your differentiation; reuse everything
  else.
- **OpenSSF** (Open Source Security Foundation) codifies the evaluation
  criteria for adopting a dependency: first "can you avoid adding it?", then
  maintenance activity, known vulnerabilities, license, security practices
  (the automated Scorecard checks), community health
  (https://best.openssf.org/Concise-Guide-for-Evaluating-Open-Source-Software.html).

The named failure modes bracket the design space on both sides: NIH syndrome
(rebuilding what exists) and uncritical adoption (importing an unmaintained
or insecure dependency). A research step defends against both.

### 3. Academic evidence: LLM memory is unreliable exactly where the step triggers

The strongest finding of the survey — replicated, quantified evidence that
technology recommendations from model memory fail:

- **Package hallucination:** across 576,000 generated code samples and 16
  models, 19.7% of samples referenced at least one non-existent package;
  43% of hallucinated names recur deterministically, which makes them
  registrable by attackers ("slopsquatting"; Spracklen et al., USENIX
  Security 2025, https://arxiv.org/abs/2406.10279). A researcher registered
  the hallucinated `huggingface-cli` package and collected 15,000+ downloads
  in three months. Frontier models in 2026 still hallucinate at ~5-6%.
- **Stale API knowledge:** 25-38% of code completions use deprecated APIs
  (Wang et al., ICSE 2025, https://arxiv.org/abs/2406.09834);
  version-conditioned correctness is 48-51% even for state-of-the-art
  models (GitChameleon, https://arxiv.org/abs/2507.12367) — roughly a coin
  flip.
- **Grounding helps most where memory is weakest:** retrieving API
  documentation improves generation by 83-220% on less-common libraries
  (https://arxiv.org/abs/2503.15231), and code examples in documentation
  contribute the most — supporting PR #2116's insistence on reading actual
  code, not prose descriptions.
- **Limit of the evidence:** gains shrink for well-known APIs, noisy
  retrieval can hurt, and one study found no correctness gain for test
  generation. This supports a *conditional* step (as the PR and the
  maintainer's observable predicate both specify), not research on every
  brainstorm.

### 4. Design-review cultures: prior-art sections are a near-universal convention

- **Rust RFCs** have the strongest template: separate "Rationale and
  alternatives" and "Prior art" sections, the latter added by a deliberate
  governance decision (RFC 2333) — with the warning that precedent alone is
  not sufficient motivation.
- **Google design docs** treat "Alternatives considered" as a core section:
  reviewers expect the trade-offs of each rejected design.
- **Python PEPs** institutionalize "Rejected Ideas" to record reasoning and
  prevent settled questions from being reopened.
- **ADRs** (Architecture Decision Records) show the trend direction: the
  original 2011 Nygard template had no alternatives section; the now-popular
  MADR successor made "Considered Options" with per-option pros and cons its
  defining feature.
- **Kubernetes KEPs** include "Alternatives"; **Amazon PR/FAQ** is the
  weakest formal requirement (alternatives surface implicitly).

### What the survey adds to the port decision

1. **The port aligns with an industry-wide consensus**, not one upstream
   PR: vendors mandate an explore-first step, classic engineering treats
   prior-art evaluation as an upstream prerequisite, and design cultures
   require documented alternatives.
2. **The academic numbers give the port its justification in one line:**
   dependency and API choices from model memory fail at measured rates
   (~20% hallucinated packages, 25-38% deprecated API usage, ~50%
   version-conditioned correctness), and documentation/source retrieval
   demonstrably fixes the weak cases.
3. **The conditional trigger is validated from three directions:** the
   academic literature (gains concentrate where memory is stale), vendor
   guidance (skip for trivial tasks), and the upstream maintainer's
   observable predicate all converge on the same shape.
4. **Two enrichments the fork could add beyond PR #2116:**
   - Have the research subagent apply the OpenSSF evaluation criteria
     (maintenance activity, vulnerabilities, license, security posture) when
     the decision is a dependency adoption — the criteria exist and are
     authoritative; the PR never names concrete evaluation criteria.
   - Record the research findings in the spec as an "alternatives
     considered" entry (the fork's spec template already has the design
     sections to hold it) — matching the Rust RFC / Google design-doc
     convention and preventing the same alternatives from being re-litigated
     in later sessions.

## Four alternatives for introducing the step in this project

The alternatives differ in **where the research lives** and **how it is
enforced**. All four assume the maintainer's corrections from the #2116
review: the observable trigger predicate, recipe form, and read-only
enforcement.

### Alternative 1 — Inline conditional step in brainstorming (the direct port)

Add one checklist step to `skills/brainstorming/SKILL.md`, between "ask
clarifying questions" and "propose 2-3 approaches". When the trigger
predicate fires (the decision introduces or replaces an external dependency,
is hard to reverse, or depends on version-sensitive API behavior),
brainstorming dispatches N independent `Explore` subagents in parallel
(default N = number of candidates + 3, minimum 4; one research angle each —
see the angle catalog in the port-shape section) and feeds their merged
findings into the approach comparison.

- **Strengths:** smallest change (one file, no `hooks/skill-rules.json`
  edit); matches the upstream-affirmed design, so future comparison with
  upstream stays easy; the research lands exactly where the failure happens —
  before approaches are proposed.
- **Weaknesses:** the capability is trapped inside brainstorming.
  `deliberation`, `writing-plans`, and `dependency-management` face the same
  stale-memory risk and get nothing. Brainstorming's SKILL.md grows again.

### Alternative 2 — Standalone sub-skill (`researching-prior-art`)

Create a new skill that performs the research (predicate check, `Explore`
dispatch, evidence report with citations), and have brainstorming invoke it
at the right point — the same composition pattern this fork already uses for
`multi-doc-review`, which is invoked by both brainstorming and writing-plans.
Other skills (`deliberation`, `dependency-management`) can invoke it later,
and users can call it directly.

- **Strengths:** reusable and testable in isolation; follows an established
  fork pattern; one authoritative definition instead of copies drifting in
  several skills.
- **Weaknesses:** the largest release surface (new skill,
  `hooks/skill-rules.json` entry, README skill count, guide). The upstream
  author reported that a *separately invoked* research skill was unreliable
  in their evaluation — mitigated here because the calling skill invokes it,
  but the indirection adds one more hand-off that can silently fail.

### Alternative 3 — Hook-enforced gate on the spec artifact

Do not change how research happens; enforce that it *happened*. A
`PostToolUse(Write|Edit)` hook detects a spec file being written under
`docs/specs/` and checks it for a prior-art section with source citations
whenever the spec names an external dependency; if the section is missing,
the hook emits a blocking reminder. Deterministic enforcement survives the
paraphrase drift that has repeatedly eroded instruction-only rules in this
fork (the v7.0.1 spec-gate fix exists for exactly that reason).

- **Strengths:** enforcement instead of exhortation — skill text can be
  ignored, a hook cannot; catches specs produced by *any* path, including
  orchestration.
- **Weaknesses:** a hook can demand research but cannot perform it, so it
  must pair with instruction somewhere anyway; dependency detection by
  pattern matching will produce false positives and false negatives; hook
  changes touch up to four platform configuration files, and Codex has only
  partial hook parity.

### Alternative 4 — Required "Prior art and alternatives" spec section

Follow the Rust RFC / MADR convention from the survey: add a required
section to brainstorming's Design Contents ("Prior art and alternatives:
existing solutions considered, with source-level evidence and reasons for
rejection") and add a check for it to the multi-doc-review reviewer lenses,
which already gate every spec.

- **Strengths:** rides entirely on existing machinery (spec template plus
  multi-doc-review); produces a durable artifact, so rejected options are
  recorded and not re-litigated; no new subagent plumbing.
- **Weaknesses:** the research arrives at spec-writing time — *after* the
  approaches were compared, which is exactly when the pg-boss-style failure
  occurs; and a section requirement can be satisfied by plausible prose
  written from the same stale memory, unless a reviewer lens explicitly
  verifies citations.

### Recommendation

**Alternative 1 as the core, plus Alternative 4 as its record.** The inline
step is the only shape that puts evidence in front of the approach
comparison (the actual failure point) at minimal cost, and writing its
findings into a required spec section gives persistence and reviewability
almost for free. Alternative 2 becomes attractive only when a second skill
actually needs the capability — extract it then, not speculatively (YAGNI:
"you aren't gonna need it"). Alternative 3 is the strongest *enforcement*
but the weakest *capability*; add it later only if field reports show the
inline step being skipped.

The next section details the implementation shape of the recommended core
(Alternative 1, with Alternative 4 as item 9).

## Recommended port shape (summary, updated with the review findings)

1. New checklist step in `skills/brainstorming/SKILL.md`, after the
   clarifying-questions step, gated by the **observable predicate** from the
   maintainer review (external dependency introduced or replaced, hard to
   reverse, or version-sensitive API behavior) — not by self-assessed
   familiarity.
2. Dispatch **N independent research subagents in parallel**, each as the
   `Explore` agent type where available, making the read-only constraint
   structural (justified by the measured 1-in-3 instruction-only violation
   rate). Each subagent gets exactly one angle from the catalog below, so
   the angles are covered independently rather than by one agent's single
   pass. **Default N = number of candidate technologies + 3, with a minimum
   of 4**; an explicit user N always wins (the fork's existing N-parameter
   convention — multi-doc-review and multi-code-review work the same way).
   With fewer agents than angles, merge angles by the priority order below;
   with more, split them. This is a **deliberate deviation from upstream
   PR #2116, which dispatches exactly one subagent** — the fork chooses
   parallel independent coverage; the 2026-08-22 survey in this document
   was itself produced this way (four agents, four angles).

   **Angle catalog** — each angle exists because the survey measured the
   failure it defends against; in priority order:

   1. *Candidate implementation* (one agent per candidate): read the
      candidate's implementation source and test files; report APIs,
      patterns, edge cases, boundaries with file-level citations. (The
      PR's core requirement; the retrieval evidence found code examples
      contribute more than descriptive documentation.)
   2. *Version and documentation verification*: every API the decision
      relies on exists in the current release; deprecations and version
      floors. (25-38% deprecated-API usage; ~50% version-conditioned
      correctness from memory.)
   3. *Health, risk, and existence*: the packages exist on the registry
      and are the intended projects, not similarly named ones
      (slopsquatting); then the OpenSSF criteria — maintenance activity,
      known vulnerabilities, license, security posture. (19.7% hallucinated
      package references; the registered `huggingface-cli` experiment.)
   4. *Prior art and community experience*: existing solutions NOT among
      the candidates (the anti-NIH direction: build only what is core);
      issue trackers, migration reports, and postmortems for the
      candidates — "the good and the bad", as the Rust prior-art RFC
      phrases it.

   At the default N (candidates + 3), angles 2, 3, and 4 each get one
   agent alongside the per-candidate agents. A larger N splits angle 3
   (existence/supply-chain vs OpenSSF health) and angle 4 (prior-art sweep
   vs community experience) into separate agents.
3. Write the subagent's task in **recipe form**: report patterns, APIs, edge
   cases, and boundaries, each with a citation into the external project's
   source and test files.
4. Use **one phrasing** of the trigger predicate, repeated verbatim in the
   checklist step, the process-graph diamond, and the guidance section.
5. Two new process-graph nodes: the predicate diamond and the research box.
6. Plain English throughout, per the repository's writing rules.
7. Optional follow-up if the fork wants its own evidence: a small behavioral
   test on Claude Code (the upstream evaluations never ran on Claude), or
   accept the upstream direction-affirmed review as sufficient signal for a
   fork-local change.
8. Optional enrichment (from the web survey): when the decision adopts a
   dependency, have the research subagent apply the OpenSSF evaluation
   criteria (maintenance activity, known vulnerabilities, license, security
   posture).
9. Optional enrichment (from the web survey): carry the research findings
   into the spec as an "alternatives considered" entry, so rejected options
   and their reasons are recorded and not re-litigated later.

## Appendix A: draft prompt template for the research subagents

The port ships this as a `research-prompt.md` file next to the skill's
SKILL.md — the same pattern subagent-driven-development uses for
`implementer-prompt.md`. The controller fills the placeholders and
dispatches one subagent per angle.

````
Agent tool (Explore):
  description: "Research angle K/N: [ANGLE NAME]"
  prompt: |
    You are a read-only research subagent. Do not create, edit, or delete
    any file. Do not invoke any skill. Your only job is to gather evidence.

    ## Decision under research
    [DECISION — verbatim, with the candidate technologies named]

    ## Your angle (K of N; each subagent gets exactly one)
    [ANGLE — assigned by the controller from the angle catalog:
     per-candidate implementation source and tests; version and
     documentation verification; health, risk, and existence;
     prior art and community experience]

    ## What to report (evidence only, never a recommendation)
    - Reusable patterns and APIs relevant to the decision — each with a
      citation (file path or URL) into the EXTERNAL project's source or
      tests. The project under evaluation, not this repository.
    - Edge cases and boundaries the source and tests reveal
    - Version facts: current release; presence or deprecation of the APIs
      the decision relies on
    - Evidence gaps: what you could not verify; contradictions you found

    ## Constraints
    - Sources: the external project's repository files, official
      documentation, changelogs; web search allowed.
    - Do not choose or rank approaches — the controller runs the
      comparison.
    - Final message: structured findings, under 60 lines; every claim
      carries a citation or the label "unverified".
````

Each design choice traces to a finding recorded earlier in this document:

- **Read-only is structural**, not instructed: the `Explore` agent type has
  no write tools (the measured 1-in-3 instruction-only violation rate).
- **"What to report" is recipe form**, not a prohibition list (maintainer
  review point 2).
- **The EXTERNAL-project emphasis** closes the "whose source files"
  loophole: without it, an agent can satisfy the instruction by re-reading
  the local repository (same review point).
- **"Never a recommendation"** is upstream's own rule — "do not ask the
  subagent to choose the design"; the controller runs the comparison with
  all N reports in view.
- **The bounded final message** (under 60 lines, citations required) keeps
  N parallel reports mergeable in the controller's context window.

## Appendix B: reference verification (2026-08-22)

The citations in this document have two different provenance levels:

- **First-hand (verified at collection time):** everything in the "Related
  upstream discussion" section — PRs #2116, #386, #724, #1911, issues
  #2129, #2093, #983, #231, and the maintainer's five-point review — was
  fetched directly from the GitHub API during this assessment.
- **Second-hand (reported by the four survey subagents), then verified:**
  all 8 URLs cited in this document were checked on 2026-08-22. All
  resolve (HTTP 200). The four arXiv titles match the claims exactly:
  2406.10279 = "We Have a Package for You! A Comprehensive Analysis of
  Package Hallucinations by Code Generating LLMs"; 2406.09834 = "LLMs Meet
  Library Evolution: Evaluating Deprecated API Usage in LLM-based Code
  Completion"; 2503.15231 = "When LLMs Meet API Documentation: Can
  Retrieval Augmentation Aid Code Generation Just as It Helps
  Developers?"; 2507.12367 = "GitChameleon 2.0: Evaluating AI Code
  Generation Against Python Library Version Incompatibilities". The two
  abstracts pulled through the arXiv API confirm the reported methodology
  word-for-word (for 2406.09834: "seven advanced LLMs, 145 API mappings
  from eight popular Python libraries, and 28,125 completion prompts").

**Remaining caveat:** the fine-grained result figures (19.7% hallucinated
samples, 43% deterministic recurrence, 83-220% retrieval improvement) sit
in the paper bodies, not the abstracts. They are topic-confirmed and
consistent with secondary reporting, but were not re-derived number by
number from the papers' full texts. Sources named by the survey subagents
but not cited by URL in this document were not individually re-checked.
