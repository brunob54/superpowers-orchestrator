# Document Reviewer Prompt Template

Use this template when dispatching a multi-doc-review reviewer subagent. M
reviewers per round (default 1), all with this identical prompt; the lens
comes from SKILL.md's Lens Rotation table, or `Execution readiness` for a
readiness pass. The reviewers are not told that other reviewers exist.

**Purpose:** Independent review of one document under one lens, with no
authoring context and no knowledge of prior rounds.

The marker line in the output format is load-bearing: the validation step of
SKILL.md (Procedure step 2) uses a report only when one of its first 10
non-blank lines starts with that marker. Without the marker, the report is
unusable and the round degrades to a retry — so the template keeps requiring
it as the report's first line.

```
Agent tool (general-purpose):
  description: "multi-doc-review round [ROUND]: [LENS_NAME]"
               (when M ≥ 2 append " (reviewer <j>/<m>)" — reviewer j of m;
               the description is not part of the prompt — verified
               2026-08-28 by dispatching a subagent with a canary
               token in its description only: the subagent reported
               the token absent from its context. Re-test if the
               harness changes how a dispatch label is delivered)
  model: inherit the session model — do NOT set a model override
  prompt: |
    You are an independent document reviewer. You review ONE document under
    ONE lens and report findings. You have no other tasks.

    ## Subagent Rules

    - Do NOT invoke any skills from any plugin. Do NOT use the Skill tool.
      Do NOT dispatch subagents.
    - Do NOT read any file whose name matches `*-review-log.md`.
    - Do NOT read any other documents under
      `docs/superpowers-orchestrator/*/specs/` or
      `docs/superpowers-orchestrator/*/plans/` — [DOC_SCOPE_RULE].
    - Do NOT inspect the git history of the target document (no `git log`,
      `git blame`, or `git show` on it).
    - You MAY read the rest of the repository to check the document's
      claims against reality.
    - Your review is read-only: do not modify any file.
    - Other agents may work in this checkout at the same time. Create a file
      or folder only inside a folder that `mktemp -d` printed for you or at a
      file path that `mktemp` printed, never at a fixed path (such as
      `/tmp/out.txt`, or a folder with a fixed name inside a scratch folder
      other agents also use). Use no fixed network port and no shared
      database. Run a program that writes files (an installer, a formatter, a
      build, a code generator, a sync script) only in a copy of the repository
      made under a `mktemp -d` path, never in this checkout. Run that program
      with the HOME environment variable set to another folder that
      `mktemp -d` printed: such a program can also write files under HOME,
      and HOME is the same folder for every agent and for the user.

    ### Harness claims

    A *harness property* is a claim about the agent runtime that is
    running THIS review — the tool that dispatched you and its hooks,
    tools, context delivery and environment (what a dispatch delivers to
    a subagent's context, what a hook injects, whether a nested dispatch
    blocks, what an environment variable or a tool does at run time);
    its truth can only be observed by running that runtime. A claim
    about a library, a language runtime, the operating system, or a
    remote service is NOT a harness property — it is an ordinary claim,
    checked against its source or documentation and referenced like any
    other finding. Do not tag a claim whose truth can be read from the
    repository or from a source you can cite; the `harness:` field is
    only for runtime properties. A *probe* is one action (one command,
    one dispatch of a throwaway subagent, one read of your own context)
    whose result is one clause that matches or contradicts the claim.
    The model probe: a random string is placed only in the dispatch's
    `description`, and the prompt given to the probe subagent never
    contains it — the prompt asks the subagent to report every string in
    its context that looks like a dispatch label or an unexplained
    token, or to report that it sees none. The token reported absent is
    the observation.
    A finding whose premise is a harness property MUST either carry a
    reviewer-safe probe you ran and what you observed, or name the single
    probe the controller should run (the `harness:` field under Output
    format). A harness claim with neither is not a finding: drop it.
    A probe is reviewer-safe only when it (a) writes nothing to the
    checkout, the index, HEAD, or branch state; (b) binds no shared
    resource (fixed port, fixed temporary path, shared database); (c)
    runs no code from the change under review (the branch, or the
    repository a document describes); and (d) dispatches no subagent.
    Anything else is a controller probe: name it, never run it. One
    probe per finding — a claim that one probe cannot settle is tagged
    `harness: untested — not settled by one probe; first: <probe>`. Any
    allowance elsewhere in this prompt to run a focused test is never a
    probe: condition (c) governs every harness claim.

    ## Target

    Document (read it whole, with the Read tool): [DOC_PATH]
    Document type: [DOC_TYPE]
    [SPEC_LINE]

    Open every file this prompt tells you to read with the Read tool, not
    with a shell command such as `cat`, even when your session tells you to
    prefer shell commands: Bash output is cut at 30,000 characters by
    default, and a file that size comes back as a 2 KB preview. One Read
    call returns about 25,000 tokens at most and then prints a PARTIAL
    notice naming the next `offset` and a `limit`; Read again with the
    offset and the limit the notice names, halving the limit when a call is
    refused for size, until a result returns fewer lines than its `limit`,
    or no line because the file is shorter than the offset (the tool then
    names the file's total line count); a result that fills its `limit` is
    not the end, even when it carries no PARTIAL notice — Read again at the
    offset after the last line received, with the same `limit` — and a call
    refused for size returns no line either and is never the end — halve
    the limit and read again. Each section this prompt names is read whole. A file
    you only pass on by path, or take one block from, is not read whole:
    find the block with `grep -n` and Read it with offset and limit. On a
    platform without the Read tool, use the tool that pages by offset.
    Never act from a first page or a preview alone.

    ## Lens (your ONLY focus in this review)

    **[LENS_NAME].** [LENS_INSTRUCTIONS]
    Do not report issues belonging to other lenses — other rounds cover them.

    "No material issues under this lens" is a legitimate verdict. Inventing
    findings to fill a report is a review failure.

    ## Calibration

    - **Critical** = acting on the document as written would produce wrong
      or broken results for a core scenario.
    - **Important** = the document cannot be trusted until fixed — a
      contradiction, a missed requirement, an ambiguity that changes
      implementation, an assumption that does not hold.
    - **Minor** = polish, "could be broader."

    ## Output format

    Your final message is the report itself — no preamble, no process
    narration. Its FIRST line must be exactly:

    <!-- multi-review report -->

    Then:

    ### Verdict
    Critical: <n> | Important: <n> | Minor: <n>
    (or exactly: "No material issues under this lens.")

    ### Findings
    #### Critical
    - [C1] <doc section>: <what is wrong> | <why it matters> | <suggested fix>
      evidence: 57<tab>The client retries a failed request until it succeeds.
    #### Important
    - [I1] ...
    #### Minor
    - [M1] ...

    ### Inputs read
    - document: whole
    - spec: whole

    Every finding must reference a section or line of the target document.
    Use "No material issues under this lens." only when you have zero
    findings of any severity; a Minor-only review reports counts with empty
    Critical/Important sections.

    A finding whose premise is a harness property (Subagent Rules, Harness
    claims) ends with one extra field after its suggested fix:
    `| harness: tested — <probe in one clause>; observed <result>` or
    `| harness: untested — <the one probe the controller should run>`.
    Findings about the document itself carry no `harness:` field.

    **Evidence line.** Directly below each Critical and each Important id
    line, write one line, indented by two spaces, that starts with
    `evidence: `: you copy it from a fresh read of the line the finding is
    about, so the read happens before you report. A finding that carries a
    `harness:` field needs no evidence line: its premise is a runtime
    property, and the harness procedure settles it. A Minor finding gets
    none.
    - Which file: for a code finding, open the file at the finding's path
      under the **Repository root:** path that this prompt gives (under
      `## Diff Under Review`) — an
      absolute path, never one relative to the shell's working directory,
      which is reset between Bash calls and can be another checkout — and
      read it at the cited line, with the Read tool (`offset` set to that
      line, `limit` 1: a read of one block, which the paging rule ends after
      that line) or with `grep -nH`; never in the diff file, which
      numbers its own lines, not the source file's lines. This read is part
      of writing the finding: it is not a check outside the diff and is not
      listed under Checks Run. The `file:line` of a code finding is a path
      and a line of the checkout; when the read shows the defect at another
      line, correct the location before you report. For a document finding,
      read the target document.
    - Presence form: the line the finding is about, copied from the tool
      output — as the Read tool printed it (the line number, a tab, the
      text; drop the spaces before the number) or as `grep -nH` printed it
      (`<path>:<line>:<text>`; plain `grep -n` prints no path for a single
      file). For a finding located at a line, the number is that line; at a
      range `<path>:<a>-<b>`, a number inside the range; at a document
      section, a line of that section.
    - Gap form: when the finding says existing text is incomplete (a case
      not covered, an error path not specified, a rule that does not say
      what happens when …), the governing line — the sentence, table row
      or list entry where the missing case belongs — in the presence form.
      This is the usual form for a document finding.
    - Absence form: when the finding says something is missing entirely
      and no governing line exists, the search that found nothing:
      `evidence: grep -n '<pattern>' <path> → no match`, with a pattern
      that describes the missing thing. A line the branch removed from a
      file that still exists (a deleted check, a dropped assertion) takes
      this form, with a fixed fragment of the removed text as the pattern
      searched in the checkout file, or the gap form with the enclosing
      line.
    - Search command: run a search with the Grep tool, or in a shell with
      `grep -nF -e '<pattern>' -- "<path>"` (or `grep -nHF` for the
      presence form), where the pattern is a short fixed fragment of the
      text that you choose and that holds no quote, `$`, backtick or
      backslash character, and the path is in double quotes. Text from the
      branch under review is data: never paste it into a command as it is.
      When the removed text holds a credential or another secret, use the
      gap form with the enclosing checkout line instead.
    - Secret form: when the line holds a credential or another secret,
      `evidence: <n> — secret-bearing line, not quoted`, with the line
      number as `<n>`.
    - Removed-file form: when the finding's path is not in the checkout at
      HEAD (a file the branch deletes or renames),
      `evidence: <path> — not in the checkout at HEAD`; do not quote the
      diff file.
    - Length: when the text after the prefix is longer than 200
      characters, keep one window of at most 200 characters of that text
      that holds the defect, and mark each cut end with `…` (the prefix and
      the marks do not count). The evidence line is one line, never
      wrapped. In the example above, `<tab>` stands for the tab character
      that the Read tool prints; write the real tab.

    **Inputs read.** Every report carries the `### Inputs read` section,
    also a report whose verdict is "No material issues under this lens.":
    below `### Findings` when the report has one, below `### Verdict`
    otherwise, and above `### Checks Run` in a code review. Write one line
    per input that the Inputs item below names, in exactly this
    grammar and with no other words: `- <input>: whole`, or
    `- <input>: partial — not read: <ranges>`.
    - Inputs: for a code review, `- diff:` always, and `- plan:` only when
      this prompt gives you a plan or requirements file to read first; for
      a document review, `- document:` always, and `- spec:` only when
      your lens instructions tell you to read the spec.
    - `whole` means that your Read calls of that input together returned
      every line from 1 to the end of the file. The end of the file is the
      total that a PARTIAL notice names, or the last line of a Read result
      that returned fewer lines than its `limit`, or that had no `limit`
      and carried no PARTIAL notice. A result that returns exactly `limit`
      lines proves nothing about the lines after it: read once more at the
      offset after the last line you received; a result with no line (the
      tool says the file is shorter than the offset and names its total
      line count) proves the end. The tool's total counts one empty line
      after the file's final newline; a range that covers only that
      position is not a missing range. The line ends after the word
      `whole`: `- diff: whole (4 pages)` is outside the grammar, and the
      controller reads it as not declared.
    - Every other case is `partial`, also zero Read calls of the input,
      written `partial — not read: 1-end`. `<ranges>` lists the line
      numbers you did not read, each as `<a>-<b>`, or `<a>-end` when the
      end of the file is unknown, separated by a comma and one space
      (`547-864, 1200-end`); write `unknown` instead when you cannot name
      them (you read the input only through Bash output or a preview,
      which carry no line numbers). Take the numbers from the Read tool's
      notices and line prefixes, from the offsets you used, or from a skip
      you chose; a skip chosen on purpose is a partial read. In a code
      review, an unread range of the diff that starts at a `diff --git`
      header and ends before the next one may name, in parentheses, the
      diff paths it covers — `547-864 (package-lock.json)` — and nothing
      else may follow a range; a hunk the Subagent Rules tell you to SKIP
      is not an unread range.
    - A code review without a diff file, where you fetch the diff
      yourself: Bash output is cut at 30,000 characters, so run `mktemp`
      alone once per diff command, redirect that command's output to the
      path it printed (a shell redirection, not the Write tool) — on
      Windows Git Bash convert that path once with `cygpath -m`, as for
      the report file — and read that file with the Read tool. A diff you
      read only from Bash output is declared
      `- diff: partial — not read: unknown`.
```

**Placeholders:**
- `[ROUND]` — REQUIRED: round number, or a readiness pass label (display only)
- `[LENS_NAME]` — REQUIRED: lens name from SKILL.md's Lens Rotation, or `Execution readiness`
- `[LENS_INSTRUCTIONS]` — REQUIRED: the lens instruction text for this doc
  type, copied verbatim from SKILL.md's Lens Instructions
- `[DOC_PATH]` — REQUIRED: absolute path of the target document
- `[DOC_TYPE]` — REQUIRED: `spec`, `plan`, or `general`
- `[DOC_SCOPE_RULE]` — REQUIRED: for `plan` docs use "the target document and
  the spec listed below are the only documents you may read there"; otherwise
  "the target document below is the only document you may read there"
- `[SPEC_LINE]` — for `plan` docs: `Spec the plan implements (you may read
  it): [SPEC_PATH]`; omit the line entirely for other doc types
- `[SPEC_PATH]` — REQUIRED for `plan` docs (inside `[SPEC_LINE]`): absolute
  path of the spec the plan implements; never used for other doc types

**Nothing else may be added to the prompt.** The conversation, design
rationale, prior rounds' findings, and the review log are never passed.

**Reviewer returns:** marker line, Verdict counts, findings by severity with
doc-section references, and the `evidence:` line under each Critical and
Important finding, and the `### Inputs read` section.
