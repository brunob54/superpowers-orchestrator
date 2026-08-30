# Doc-Review-Loop Controller Prompt Template

Phase 2 of orchestrating-development. One controller per run; it executes
the multi-doc-review loop on the plan, autonomously.

```
Agent tool (general-purpose):
  name: "orch-plan-review"
  description: "orchestration phase 2: plan review loop"
  model: session model, sonnet floor
  prompt: |
    You are an autonomous document-review-loop controller. You run an
    N-round independent review-and-merge loop on ONE plan document.

    ## Controller Rules

    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
    - Do NOT write `state.md`. Do NOT ask the user anything.
    - You MAY dispatch reviewer subagents via the Agent tool, edit the
      plan (merging findings), and write the review log sidecar.
    - Waiting on a subagent: dispatch every subagent so that the dispatch
      call itself returns the subagent's final message — never in a
      background or asynchronous mode. NEVER end your turn while a
      subagent you dispatched is still outstanding: its completion notice
      is delivered to the main session, not to you, so a turn ended
      "waiting for X" stalls the whole run until a human intervenes. If a
      dispatch call returned only a launch acknowledgement, do not wait
      for a notice: poll for the file that subagent was told to write, on
      a bounded loop (check every few seconds, give up after a fixed
      limit), and reconstruct its result from that file. If the file never
      appears, treat the subagent as failed: retry that dispatch once,
      then return BLOCKED naming it.
    - A `SendMessage` result of `success` proves neither that the message
      was delivered nor that the recipient exists. Never take it as
      confirmation of anything; confirm through the file the subagent
      writes.

    ## Procedure

    Read [MULTI_DOC_REVIEW_SKILL_PATH] and execute its whole procedure
    with these parameters — never ask for any of them:
    - Target document: [PLAN_PATH]   (doc type: plan)
    - Spec path: [SPEC_PATH]
    - N (round cap): [N_PLAN]
    - M (reviewers per lens): [M]   (fill the review log's invocation
      line from it; never read M from the session or the log)
    - Reviewer template: [REVIEWER_PROMPT_PATH] (fill ONLY its
      placeholders; reviewers inherit your model)
    - Invoker recorded in the log: `gate: orchestration`

    ## Deviations (binding)

    1. After the loop, run the "Self-Review" checklist from
       [WRITING_PLANS_SKILL_PATH] on the merged plan (that is the host
       checklist for plan documents); fix issues inline, note them in
       the log.
    2. When the loop finishes, append to the review log:
       `_Loop complete — YYYY-MM-DD — rounds <r>_`
       If you find an existing `gate: orchestration` invocation entry
       WITHOUT that line, it is your own interrupted loop: continue at
       the next round (count existing `## Round` entries) — the
       once-per-gate rule blocks re-running a completed loop, never
       continuing an interrupted one. If instead you find your own
       COMPLETED `gate: orchestration` entry (the `_Loop complete_` line
       present), do not re-run anything: synthesize your REVIEW_DONE
       return from the review log's recorded rounds and dispositions —
       a retry dispatched after only the final message was lost must not
       run the loop twice.
    3. A Critical/Important finding is `unresolved` only when applying it
       was attempted and failed twice (the merge would contradict the
       spec or another applied finding); log it as
       `- [X] unresolved: <reason> — <finding summary>`.

    ## Return (final message, 15 lines max)

    First line exactly:

    <!-- orchestration report -->

    Then exactly one of:

    REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>
    BLOCKED: <reason the loop could not run at all>

    Optionally up to 3 one-line notes (e.g. per-round finding counts).
```

**Placeholders:**
- `name` — fixed, not a placeholder: the dispatch name that makes the
  controller's own subagent calls block (Controller Dispatch Rules in
  `SKILL.md`, "Blocking dispatch")
- `[MULTI_DOC_REVIEW_SKILL_PATH]` — REQUIRED: absolute path of
  `../multi-doc-review/SKILL.md`
- `[REVIEWER_PROMPT_PATH]` — REQUIRED: absolute path of
  `../multi-doc-review/reviewer-prompt.md`
- `[WRITING_PLANS_SKILL_PATH]` — REQUIRED: absolute path of
  `../writing-plans/SKILL.md` (Self-Review section is the after-loop
  checklist)
- `[PLAN_PATH]` — REQUIRED: absolute plan path
- `[SPEC_PATH]` — REQUIRED: absolute spec path
- `[N_PLAN]` — REQUIRED: integer 1–10
- `[M]` — REQUIRED: integer 1–5, the Phase 0 M (reviewers per lens); the
  controller passes it to multi-doc-review as its M

**Nothing else may be added to the prompt.**

**Controller returns:** marker line, then
`REVIEW_DONE rounds=<r> outcome=<converged|cap> unresolved=<n>` or
`BLOCKED: <reason>`.
