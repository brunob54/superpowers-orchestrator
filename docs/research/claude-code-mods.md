# Claude Code mods — could they help superpowers-orchestrator?

Research findings, 2026-10-10. Claude Code version on this machine: 2.1.296.

Method: ten research subagents ran in parallel, each with its own angle
(see [Appendix A](#appendix-a--method)). This document merges their reports.
Three more subagents then reviewed the merged text: one against the ten
reports, one against the live documentation, one for clarity. Every fact
carries its source. A fact marked *(inferred)* is a researcher's reasoning that
nobody checked against a source or a live run.

---

## Summary

**What a mod is.** A *mod* is a Claude Code plugin that contains JavaScript or
TypeScript functions. Claude Code calls these functions when an event happens:
a tool call, a submitted prompt, a subagent start, or a part of the screen
being drawn. A mod can watch the event, change it, or answer it itself. This
plugin's hooks today are *settings hooks*: Node scripts that Claude Code starts
as separate processes. A mod, in contrast, runs *inside* Claude Code, so it can
draw its own interface: a pane beside the transcript, a band above the prompt,
buttons, and slash commands that run at once without a Claude turn. The public
release was Claude Code 2.1.287 on 1 October 2026 (9 days before this
document); a hidden prototype existed from 2 September.

**Main answer.** Yes, a mod could give this project a feature that no other
plugin offers today. The evidence, with its limits:

1. **A mod can see subagent activity, but two points are not yet proven.**
   The documentation says that `tool.call` fires for the tool calls of
   subagents. The orchestrator already names every dispatch with a fixed
   pattern (`orchestration phase 3: batch 2 (tasks 4,5,6)`,
   `multi-code-review round 2: …`). So a mod could turn these names into a live
   pipeline view with no change to any skill. Two things are not proven:
   - The *depth-2* case (a reviewer started by a controller subagent) appears
     only in an older types file (2.1.277) and was never tested.
   - On 2.1.287 a user reported that `agent.spawn` did not fire for named
     background agents. The same user found that `$.agent.list()` shows the
     first ~40 characters of the prompt, not the description. The orchestrator
     uses exactly named background agents.

   Step 0 of the plan tests both points. If they fail, the view falls back to
   reading the run's log files (idea A).
2. **No known mod shows this fork's pipeline** *(inferred)*. About 3,000
   community mods exist. Two show parts of a pipeline: *superpowers-tracker*
   (built for the upstream "superpowers" project) and *ledger*. One more,
   *claude-console*, shows a six-step pipeline. None is known to read this
   fork's review rounds, in-run rulings and work logs together. The
   superpowers-tracker matches `.superpowers/sdd/`, which this fork also uses,
   so it may see part of our runs. Nobody tested this.
3. **One recorded run waited 6 h 09 min for a human.** The pipeline stopped
   for a decision, and nobody resumed it for 6 h 09 min. A mod can show such a
   stop in the terminal at once.
4. **A mod can show status with zero model tokens.** A mod command can draw
   its answer in a pane and return nothing to Claude. It then uses no model
   call and adds nothing to Claude's context. Claude Code's own `statusLine`
   command can also show one line of status at zero tokens, without a mod.
5. **The risks are real.** The API is still marked "EARLY ACCESS". It had 87
   changelog lines in the 10 releases 2.1.287–2.1.296. Two recent fixes were in
   exactly the cases the orchestrator uses (worktree subagents, working
   folder). Mod code is not sandboxed. The researchers who looked at packaging
   agree: the mod must **not** go into the main plugin's `hooks/hooks.json`.

**Recommendation.** Three steps. The first two are private, outside the
repository, and can be deleted without trace.

- **Step 0 — a probe mod.** It answers the open questions with a live run.
- **Step 1 — a private status mod**: a `/runs` pane, plus a "needs you" alert
  during orchestration. Keep it only if it meets measured criteria.
- **Step 2 — "Mission Control"** (a working name), a separate optional plugin
  in the same marketplace. It shows the orchestration pipeline live.

[Section 8](#8-recommended-path) gives the details. The critic researcher
advised building nothing now; [section 7](#7-disagreements-between-researchers)
records this and the other disagreements.

---

## 1. Terms used in this document

| Term | Meaning |
|---|---|
| **Mod** | A plugin whose code registers event handlers that run inside the Claude Code process. |
| **Hooks module** | The one JS/TS file of a mod (for example `register.js`). It exports `register(on)`. Inside it, `on('<event>', handler)` attaches a handler to an event. |
| **Mod hook** | One handler in the hooks module. The docs call it a "hook". |
| **Settings hook** | The older kind of hook: a shell command, HTTP request or prompt listed in a settings file or in a plugin's `hooks/hooks.json`. All hooks of this plugin today are settings hooks (Node scripts started through `hooks/run-hook.cmd`). |
| **`$` (mods API)** | The object a mod hook receives. A hook can reach anything outside its own code only through it: drawing, files, processes, timers, model calls. |
| **Site** | A place where a mod draws (a pane, the band, a restyled row). |
| **Props** | The input values of a drawn element (React terminology). When they change, the element is drawn again. |
| **Pane** | A region a mod draws. In a wide full-screen terminal it is a sidebar; otherwise it is a framed region above the prompt. |
| **Band** | A shared region above the prompt, where several mods can draw one line each. |
| **Toast** | A short notice that disappears after about 4 seconds. |
| **`$.ui.status`** | One line under the prompt. It always starts with `⚠` and the mod's name, so it reads as a warning. |
| **`$.ui.log`** | A dim line written into the transcript. Claude does not read it, so it costs no context. |
| **Immediate command** | A `/command` registered by a mod with `immediate: true`. It runs the mod's function at once, with no Claude turn, even while Claude is working. |
| **Zero-token** | Uses no model call and adds nothing to Claude's context window. |
| **`statusLine`** | A Claude Code setting that names a command; Claude Code runs it and shows its output as the bottom line of the terminal. It costs no tokens. The owner's status line chains to the oh-my-claudecode HUD (heads-up display: a status display that stays on screen). |
| **Headless** | Running Claude Code with `claude -p`, without an interactive terminal interface. This repository's behavioural tests run headless. |
| **General availability** | The date from which a feature is on for everyone, not only for early testers. |
| **Worktree** | A second working folder of the same git repository (`git worktree`). Subagents started with `isolation: "worktree"` work in one. |
| **Controller** | In this plugin, the background subagent that runs one orchestration phase and dispatches implementer, reviewer and fix subagents. |
| **Depth 2** | A subagent started by another subagent (for example a reviewer started by a controller). |
| **Lens** | The review angle given to one reviewer subagent in a round (for example correctness or security). |
| **Ruling** | A decision the orchestration controller takes during a run without asking the user, recorded as a `RULING` entry in the run log. |
| **Recall** | The text that this plugin's skill-activator hook adds to Claude's context for a prompt (past decisions and known issues). |
| **Protected path** | A folder where Claude Code asks for approval before every edit. |
| **Worker thread** | A separate thread inside the Claude Code process where all installed mods run. |
| **Pinning test** | A test that fails when a fixed text (for example a rule id in a refusal message) changes. |
| **TUI** | Text user interface: an interface drawn with text characters in a terminal. |

---

## 2. What a mod can see and do (facts relevant to this project)

Main sources: the mods docs pages *overview*, *interface*, *events*, *api*,
*reference*, *test*, *troubleshoot* and *admin* under
`https://code.claude.com/docs/en/plugins/mods/`. Some facts come only from the
published TypeScript types file (`claude-code.d.ts` on GitHub). That file says
it was generated by Claude Code 2.1.277, which is older than the installed
2.1.296. Running `/plugin-types` writes the types for the installed version.

### 2.1 Seeing subagents — the key question for orchestration progress

| Fact | Source |
|---|---|
| `tool.call` fires "including calls a subagent makes". | events page, "Guard or change a tool call" |
| `turn.step` / `turn.complete` carry `e.agentId` for a subagent's requests. `tool.check` carries `e.agentId` from v2.1.290. | events page, "Follow a turn"; reference, "Agent and organization fields on tool.check" |
| `agent.spawn` fires before a subagent or teammate starts. The reference "Agents" table documents only `e.isTeammate`, a model change through `next({...e, model})`, and `{deny}`. | reference, "Agents" |
| The fields `description`, `name`, `subagentType`, `background`, `parentAgentId` of `agent.spawn` | types file 2.1.277 only; **not in the guide pages** |
| `$.agent.list()` returns every subagent with a `status` (7 values; `idle` and `waiting` need 2.1.289). | reference, "Mods API methods" |
| `$.agent.list()` also returns a `parentId`. | types file 2.1.277 only |
| Depth 2 is stated only in the types file. The guide pages do not mention it. | types file; **needs a live test** |
| A mod is loaded once per session. Subagent events reach that one copy, tagged with an agent id. | *(inferred)* from the event fields |
| On 2.1.287, `agent.spawn` did not fire for named background agents, and `$.agent.list()` showed the first ~40 characters of the prompt instead of the description. | a comment in issue #91870; fix status unknown |
| `$.agent.list()` omits workflow agents. | issue #100918 (open) |
| Teammate ids do not match between events. | a comment in issue #91870; fix status unknown |
| One text over 10,000 characters blanks a whole pane. | reference docs |

**Why this matters.** During Phases 1 to 4 the controllers run in the
background, and the main session makes **no tool call for up to 116 minutes**
(measured on past runs). A view built only on the main session's own tool
calls would therefore change only at phase ends. Subagent events would solve
this, as long as they reach the mod for named background agents at depth 2.

### 2.2 Drawing

- **Surfaces:** pane, band above the prompt, `$.ui.status` line, toast,
  `$.ui.log` line. *(interface page, "Pick where to draw"; api page)*
- **Elements:** `Box`, `Text`, `Button`, `Link`, `Code` (can draw a diff),
  `Markdown`, `Input`, `Select`, `Client`. `Raster`/`Image` work in the
  terminal only; `Svg` works in the Desktop app only. There is **no chart
  element and no tab element**; tabs are built as a row of buttons.
  *(reference, "Elements")*
- **Redraw:** only after `$.ui.invalidate`, a `$.state` write, a change of
  props, or a change of terminal width. Timers use `$.clock.every`. At most 10
  redraws per second (30 in the terminal). *(interface, "Redraw a site")*
- **Opening a pane:** a command or a button opens it at any width. A mod that
  opens a pane by itself needs at least 144 terminal columns (110 after the
  user has opened it once). *(interface, "When a pane waits for a wider
  terminal")*
- **Restyling Claude Code's own rows:** messages, `ToolUse` / `ToolResult` /
  `ToolGroup` rows, the spinner, the question dialog, `PromptHint` and others.
  **The permission prompt cannot be changed.** *(overview; interface)*
- **Where nothing draws:** `claude -p`, the Agent SDK, the VS Code chat panel,
  cloud sessions. The hooks still run there. In a WSL session of the Desktop
  app, neither the hooks nor the drawing run. *(overview, "Where mods run")*

### 2.3 Commands, files, processes, timers, state

- **Immediate command:** `$.command.register({ name, immediate: true })` plus a
  `command.run` hook. It runs no model turn and works while a turn is running.
  **Trap:** if the command returns `{ text }`, that text enters the transcript,
  and Claude reads it on its next turn. A zero-token command must return `{}`
  and draw its answer in a pane. `register` throws an error for the name of a
  built-in command, and the error skips the rest of the mod's `session.start`
  hook; so the name must not be `/status` or another built-in name.
  *(api page, "Add a command")*
- **Files:** `$.fs` has `read`, `write`, `exists`, `stat`, `list` and
  `ancestors`. **There is no file-watch method**, so mods poll with a timer.
  `$.fs.write` is not atomic. *(api page; reference)*
- **Processes:** `$.process.run([...])` starts a program, for example `node` or
  `git`. Time limit: 30 s by default, 10 min at most *(reference, "Limits")*.
  A `cwd` option exists and defaults to the session folder *(types file
  2.1.277)*.
- **Timers:** `$.clock.every`. *(api page)*
- **State:**
  - `$.state` lasts one session. `/clear`, `/resume` and `/branch` also reset
    it.
  - `$.store` is one JSON file per plugin under `~/.claude/plugins/store/`,
    with a limit of 4 MiB. Every session that runs the mod shares it, so keys
    must contain the repository path. Each `set` changes only its own key, but
    a `get` followed by a `set` is not atomic.
  - Module variables reset when the module reloads.

  *(interface page, "Keep state" and "Save from more than one session")*
- **Model calls:** `$.model` calls are billed to the user's plan or API key.
- **Messages:** a mod can send a message to another session or to a subagent.
  *(api page)*

### 2.4 Runtime limits that shape any design

- **One hooks module per plugin.** "An array with one path"; a second entry
  fails validation. *(reference, "Files"; checked with `claude plugin
  validate`)*
- **No Node.js inside the module.** There is no `require` and no `process`.
  Allowed imports are relative files inside the plugin and `claude-code`, so
  **no npm packages**. A mod therefore cannot import this plugin's CommonJS
  scripts (`pickup-scan.js`, `git-runs.js`, `dashboard-extract.js`,
  `hooks/safety/shell-words.js`). It must run them with
  `$.process.run(['node', …])`. *(api page, "Reach files, processes, and the
  network"; create page; checked with `claude plugin test`)*
- **Language:** plain ES-module JavaScript, or TypeScript that Claude Code
  compiles itself. No build step. *(create page; reference)*
- **Time limits:** a hook's own work may take 10 s. Waiting inside `next` or
  inside a `$` call does not count, except `$.clock.sleep`. Other limits: 50 ms
  for a `prompt.edit` hook, 1 s for a `.catch` handler, 1.5 s for all
  `session.end` hooks together. *(reference, "Limits")*
- **Failure:** a hook that fails *before* it calls `next` is skipped, and the
  session goes on. When it fails *after* `next` resolved, the result of `next`
  stands. A result of the wrong shape also counts as a failure. A `.catch`
  handler can refuse the event instead. *(events page, "Handle a hook that
  fails")*
- **Crashes:** all installed mods share one worker thread. After three
  crashes, Claude Code unloads the one mod that caused them. When the crashes
  cannot be traced to one mod, it unloads every installed mod; built-in mods
  stay loaded. *(troubleshoot and admin pages)* Anthropic can also turn
  installed mods off remotely (#99130).
- **Order against settings hooks:**
  - `PreToolUse` hooks from **managed** settings run before the first mod, and
    their block is final.
  - A plugin's `PreToolUse` settings hooks run *after* the last mod calls
    `next` on `tool.call`.
  - `tool.check` fires *after* those hooks and the permission rules. There a
    mod can answer `allow`. The overview page warns that a mod can approve a
    call that one of your own `PreToolUse` hooks blocked.

  *(events page, "Where settings hooks run in the order"; overview, "What a
  mod can reach")*
- **Organization policy:** an organization that sets `allowManagedModsOnly`
  never loads a user-installed mod. `disableAllHooks` also stops mods.
  *(overview; admin page)*

### 2.5 Testing and debugging

- `claude plugin validate <dir>` lists the events a mod handles (`hooks:`) and
  the API calls it makes (`calls:`), without running it. *(overview)*
- `claude plugin test [dir]` runs `*.test.ts` and `*.test.tsx` files with a
  test kit built into `claude` (`claude-code/testing`). It needs **no session,
  no sign-in and no network**. Fakes exist for the clock, the store and the
  environment. A test draws a site with `$.ui.mount(...)`; the handle it
  returns offers `press`, `find` and `unmount`. *(test page)*
- `claude plugin test` exits 1 on a failing test **and also when mods are
  turned off**; it then prints `claude plugin test: hooks modules are turned
  off`. A test suite must read the printed message, not only the exit code.
  *(test page; checked in the scratchpad)*
- `validate` does **not** catch a `require` or a `process` reference; only
  `test` does. One community author found 4 bugs that showed up only in live
  sessions. *(packaging and community reports)*
- `/reload-plugins` reloads a mod after an edit. A debug log records skipped
  hooks and worker crashes. *(troubleshoot page)*

---

## 3. State of the feature

### 3.1 Timeline

| Date | Version | Event |
|---|---|---|
| 2–3 Sep 2026 | 2.1.259–2.1.260 | Prototype behind `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS`. An Anthropic engineer asked for feedback in issue #91870 (252 comments, 131 thumbs-up). |
| 9 Sep | 2.1.267 | Name "Claude Mods" chosen; public testing allowed. Breaking renames in the first week (`fs.readFile` → `fs.read`). |
| 30 Sep | 2.1.286 | Mods work in the Desktop app. |
| 1 Oct | 2.1.287 | General availability, blog post and tutorial. |
| 1–10 Oct | 2.1.287–2.1.296 | 87 changelog lines about mods, mostly fixes. |

Source: news report (npm release dates, `CHANGELOG.md` of anthropics/claude-code,
issue #91870).

### 3.2 Stability

- The type declarations still start with "EARLY ACCESS: this surface may change
  between releases without notice". The docs say "events and methods can
  change between releases".
- Nothing was removed after general availability. But in 2.1.290 and 2.1.292
  behaviour changed in a way that can break existing mod code: a hook that
  denies or drops an event *after* calling `next(e)` is now reported as
  failed.

### 3.3 Known problems that touch this project

| Issue | Problem | Why it matters here |
|---|---|---|
| #92533 | A Bash `tool.call` hook (or one with a RegExp matcher or no matcher) broke Bash in `isolation: "worktree"` subagents. Said to be fixed in 2.1.288; the issue is still open. | The orchestrator uses worktree subagents. |
| 2.1.296 fix | `$` methods ran in the wrong working folder for subagents. | Status scripts depend on the working folder. |
| #100869, #96831 | `classic.*` events do not reach a hooks module, although the types file and `validate` say they do. The issues name Stop, PreToolUse, Notification, PermissionRequest and `skill.prompt`. | Blocks the idea of wrapping this plugin's settings hooks (ideas E and F below). |
| #99045 | The VS Code extension draws no mod interface. | VS Code users see nothing. |
| #99211, #99265 | Desktop app: any change redraws every site, so buttons lose clicks. The band is drawn only in the leftmost split-view chat. | Desktop users get a weaker experience. |
| #100918 | `$.agent.list()` omits workflow agents. | Use events, not only `list()`. |

Before 2.1.295, headless runs also wrote type files into the repository.

### 3.4 Security

- Mods are not sandboxed. A mod can read files and secrets, see every prompt
  and tool call, rewrite them, submit prompts, approve tool calls, and spend
  usage. *(overview, "What a mod can reach")*
- Pluto Security (22 Sep, tested on 2.1.274) showed a mod that read the
  credentials file and sent it out without a prompt, and a mod that drew fake
  prompts. <https://pluto.security/blog/claude-code-function-hooks-security/>
- Five recent fixes closed ways for a user-installed mod to get past an
  organization's guard mod or deny rules.
- Critics note that there is no review and no signing of mods.

**Consequence for this project:** a published mod asks every user to trust its
code. A **read-only** mod (no tool, prompt or permission hooks) asks for much
less trust than a guard mod, and `claude plugin validate` shows a user exactly
which events and calls it uses.

---

## 4. What the community built

- **Size:** the catalogue *awesome-claude-code-mods*
  (<https://github.com/karanb192/awesome-claude-code-mods>, 456 stars) counted
  **3,075 mods in 1,502 repositories** on 2026-10-10. The GitHub topics
  `claude-code-mod` and `claude-code-mods` have 407 and 163 repositories. 578
  mods predate general availability, so their code may use old API names.
- **Most mods** are usage meters, pets, games and themes.
- **Keyword counts** in the catalogue: subagent 162, review 104, handoff 51,
  orchestration 18, work log or journal 15, superpowers 5.

### 4.1 The five most relevant to this project

| Mod | What it does | Lesson for us |
|---|---|---|
| **superpowers-tracker** <https://github.com/nalyk/nalyk-skills/tree/main/plugins/superpowers-tracker> | Built for upstream obra/superpowers (tested on 2.1.289). A band with the stages (Brainstorm → … → Finish) and a 7-tab pane: flow map, plan with fix-round marks, agents, ledger of rulings, tests, workspace, warnings. Offers to resume unfinished plans. | Someone already sees the value of a pipeline view. It matches `docs/superpowers/`, not this fork's `docs/superpowers-orchestrator/`, but it also matches `.superpowers/sdd/`, which this fork uses. So it may see part of our runs *(inferred, not tested)*. A second mod for upstream, *superpowers-progress*, also exists. |
| **gsd-status-mod** <https://github.com/helenkwok/gsd-status-mod> | Reads a workflow's state files. Shows "stopped at", a warning when the state file is N commits older than the code, and the next action as a Tab suggestion. | Best model for "unfinished runs" and work-log status. |
| **ledger** <https://github.com/BuddyLim/claude-code-mod-ledger> | Records an orchestrated run: tasks, subagents per task (linked by a `[T3]` prefix in the description), gate verdicts, reviewer findings. | Same idea as our audit logs, driven by dispatch descriptions. |
| **council-pane** in <https://github.com/hex/claude-council> (860 stars) | Shows parallel reviewers ("seats") with cancel and retry. A shell script writes status files; the mod only reads them and draws. With mods off, the old path works unchanged. | The cheapest integration pattern for us. |
| **handoff-compact** <https://github.com/trytofly94/handoff-compact> | Answers `session.compact` itself: a forked session writes a structured handoff (goal, proof, decisions, dead ends, last prompts word for word) instead of a generic summary. | Directly related to this repository's compaction-guard work. High risk; see idea H. |

Other themes: subagent monitors (agentpane
<https://github.com/xuanji86/claude-agentpane>, flightdeck
<https://github.com/scasella/claude-flightdeck>, agent-flow); workflow
trackers (claude-console shows a six-step pipeline); "needs you" queues
(Logbook lists "decided without you" items and lets the user reverse each
one); verification guards (ultramod flags a "tests pass" claim that no test
run supports; probe-check warns about `grep` used as proof of absence).

### 4.2 What no known mod does yet *(inferred from the catalogue search)*

- No mod targets superpowers-orchestrator.
- No mod shows multi-round review progress (round k of N, M reviewers per
  round, findings by severity).
- No mod reads a long-lived work log.
- Only two mods show decisions taken without the user.

### 4.3 Other tools

GitHub Copilot CLI (which this plugin also supports) has "extensions" in a
separate process, marked experimental since Copilot CLI 1.0.3 *(the current
status is inferred)*. Their rich interface is HTML "canvases" in the Copilot
desktop app or a separate window, not in the terminal. Copilot CLI also has
`statusLine.command` and hook progress lines. Pi extensions and OpenCode TUI
plugins draw in the terminal. Gemini CLI, Codex, Cursor and Zed seem to have no
plugin-drawn interface *(inferred)*. So a mod would be a layer for Claude Code
only; Copilot CLI users would keep today's behaviour.

---

## 5. Ideas for this project, ranked

The ranking weighs value to the user, whether any other plugin offers the
same, and risk. "Size" is lines of mod code, estimated from the official
samples: a first mod is 120–200 source lines and 100–250 test lines; a live
pipeline pane is 300–450 source lines.

### A. Mission Control — a live orchestration pipeline view

- **Band** (visible while a run is active), for example:
  `orchestrate <slug> · phase 3/5 · batch 2/4 · tasks 7/12 · review r2/3 · 1 Important open · 41 min`
- **Pane** (opened with a command such as `/mission`; tabs as buttons):
  - *Pipeline:* the five phases with their times, and the current step of each
    worker (brief → implement → review).
  - *Reviews:* rounds k of N, M reviewers, lens per round, findings by
    severity, early-exit state.
  - *Rulings:* the decisions the controller took without the user, each with
    a link to the log. The owner delegates every in-run decision before
    Phase 5, so this is the list to check afterwards.
  - *Agents:* the agent tree with status and last activity.
- **Data sources, in order of preference:**
  1. `agent.spawn` events, if Step 0 shows they arrive for named background
     agents at depth 2. The dispatch descriptions already follow fixed
     patterns: `orchestration phase N: …`
     (`skills/orchestrating-development/SKILL.md:119-122`),
     `Implement Task N: …`, `Review Task N (spec + quality)`,
     `multi-doc-review round <i>: <lens>`,
     `multi-code-review round <i>: fix subagent`. Only the security-review
     description is free text; making it follow the pattern is an optional
     one-line skill change.
  2. `turn.complete` and `$.agent.list()` for completion and status.
  3. A timer (every 15–30 s, only while the pane is open) that reads the run's
     `<slug>-orchestration-log.md` (phase headings, `RULING`, `STOPPED`), the
     review logs (one entry per round) and `.superpowers/sdd/progress.md`
     (`Task N: complete` lines). These files survive a session restart, which
     events do not.
- **If Step 0 fails** (no events for depth-2 background agents): the view uses
  only source 3. It then changes once per finished task and once per review
  round, not at every subagent start. The *Agents* tab and the silence alarm
  of idea B are lost.
- **The researchers disagree about one more source** (section 7, row 7): the
  `agent-<id>.meta.json` files under `~/.claude/projects/`. They are written
  live, but they are internal to Claude Code, and their fields already changed
  between two past runs (`spawnDepth`). This document does not recommend
  them.
- **Skill changes needed:** none (one optional).
- **Value:** high. **Offered elsewhere:** partly (superpowers-tracker, ledger).
  **Risk:** medium (depends on Step 0 and on the worktree-subagent bugs).
  **Size:** 300–450 lines.

### B. "Needs you" alert and silence alarm

- When the orchestration log gets a `STOPPED` heading, or a controller hands
  back a stop, show a `$.ui.status` line (its `⚠` prefix fits here) and a toast
  with the log's `Open:` and `Resume:` lines.
- **Silence alarm:** if no subagent event arrives for 10 minutes, show a
  warning. On normal runs, the longest gap with no new record in any of the
  run's transcripts was 166–208 s. One past run had a 68-minute silence inside
  a reviewer's call; the researcher thinks it was a permission prompt waiting
  for a human, but could not prove it.
- **Evidence of value:** one recorded case. The dashboard run waited 6 h 09 min
  after its stop before anyone resumed it.
- **Limit:** a toast disappears after 4 s, and any alert inside the terminal
  does not reach a user who is away from it. An operating-system notification
  from a settings hook (for example on `Stop` or `Notification`) works without
  a mod and reaches a user at another window. Compare both in Step 1
  *(inferred: whether the main session's `Stop` fires reliably at a
  controller's stop was not checked)*.
- **Value:** high if stops happen often; the evidence is one case. **Risk:**
  low (read-only). **Size:** small; it fits inside A or the Step 1 mod.

### C. Project status with zero tokens — band plus status pane

- **Band** (only when there is something to show): active work log · part X of
  Y · N open items · last update · unfinished runs · handoff present.
- **Pane** (a command such as `/sp-status`, not `/status`) with tabs: Work
  logs | Runs | Branches | Session | Worklist. Buttons put `/pickup …` or
  `Resume orchestration for …` into the prompt box for the user to send.
- **Toast at session start** when a work log is 7 or more days old and newer
  commits exist (the same rule the session-start hook uses for `state.md`).
- **Data:** run the existing scripts as processes, so the logic stays in one
  place:
  - `pickup-scan.js` prints git, handoff and unfinished-run lines (the rule for
    "unfinished run" lives in `git-runs.js`);
  - `dashboard-extract.js` prints the work logs and the rest. It runs in 0.5 s
    and prints 61 KB of JSON. It lacks three fields the band needs: work-log
    title, count of done parts, date of last update.
- **Tokens saved (estimates from file sizes):** a plain "what is the status?"
  question costs about 4–8K tokens today; the scan part of `/pickup` about
  1.3K; `/dashboard local` about 7K. A mod command that returns `{}` costs 0.
  `/worklog`, `/handoff` and the decision part of `/pickup` need Claude's
  judgement and stay skills.
- **Demand:** `/pickup` appears in 40 of 68 transcripts (a count of files that
  contain the string, so mentions inflate it). Its result must be read by
  Claude, so a pane would not replace it. `/dashboard` appears in about 1.
- **Alternative without a mod:** the owner's `statusLine` command could show
  the one-line part (active work log, unfinished runs) at zero tokens. It
  cannot show a pane or buttons.
- **Relation to the dashboard:** the Artifact dashboard stays. It serves the
  browser, the phone, sharing and the approval of edits. The mod serves the
  terminal while working.
- **Value:** medium. **Risk:** low. **Size:** 120–200 lines. The `/runs`
  command of Step 1 is a reduced version of C.

### D. Explain the safety refusals — explanation only

- When `hooks/safety/block-dangerous-commands.js` or `protect-secrets.js`
  refuses a call, draw a short line that names the rule and the reason, and
  how to proceed by hand.
- **Measured:** 178 refusals in 49 real sessions over 35 days (32 of them for
  `git reset --hard`). Each safety hook takes about 19 ms.
- **No "Run it once" button.** The hooks researcher proposed one at
  `tool.check`; the critic and this document advise against it (section 7,
  row 5). At `tool.check` a mod *can* approve a call that our `PreToolUse`
  hook refused, so the button would be a way around the guard. It could also
  hold an orchestrated run waiting for a human. And the remote off switch and
  the crash rule mean a mod must never hold a safety function.
- **Blocker:** the explanation must read our hook's refusal. That needs either
  `classic.*` events (see the open issues) or text matching on the tool
  result, which needs a pinning test.
- **Value:** medium. **Risk:** low if read-only.

### E. Skill-routing visibility

- Show in one dim line, which Claude does not read, which skills the
  skill-activator suggested and how large its recall was. Today only Claude
  sees this.
- **Blocked** until a live test shows that `classic.UserPromptSubmit` reaches a
  hooks module. Issues #100869 and #96831 report that other `classic.*` events
  do not; `UserPromptSubmit` is not named in them.

### F. Wrapping settings hooks (general pattern) — blocked

According to the types file (lines 969–1088) and the events page, a mod
handler on `classic.<Event>` that calls `next(e)` gets back the combined
answer of the plugin's settings hooks (`additionalContext`, `block`,
`updatedToolOutput`). So a mod could *show* what each hook did without running
the hook logic a second time. The hooks would stay the single place of the
rules and would still run on Copilot CLI. This depends on the same open issues
as E.

### G. "Show raw output" for compressed Bash results

smart-compress replaces long Bash output after the command ends. A control on
the compressed row could show the raw output. **First check** whether Claude
Code's row already shows the raw output. Low priority.

### H. Structured handoff at compaction (postponed)

Following handoff-compact, a mod could answer `session.compact` and produce a
structured handoff instead of the generic summary. This touches the core of
this repository's compaction-guard work, and it is the riskiest idea: it
replaces Claude Code behaviour, spends model usage, and depends on internal
event shapes. Look at it again only after A–C have run for some weeks.

### Things to avoid (this document's recommendation)

Section 7 lists where single researchers proposed otherwise.

- Adding a `modules` key to the **main** `hooks/hooks.json` (see section 6).
- Moving any guard or rule into a mod, or approving tool calls from a mod.
- Rewriting prompts or tool inputs.
- `$.model` calls (cost, trust).
- Status commands that return `text` (they add tokens).
- Rewriting the status logic in TypeScript instead of running the existing
  scripts.
- Depending on `meta.json` files or other Claude Code internals.

---

## 6. How to ship a mod

### 6.1 Layout: a separate plugin in the same marketplace

A mod is declared by `"modules": ["./register.js"]` in a plugin's
`hooks/hooks.json`. One file can hold both settings hooks and `modules`
*(reference, "Files")*. The packaging researcher added the key to a scratch
copy of our `hooks/hooks.json`, and it passed `claude plugin validate` and
`claude plugin test` on 2.1.296. Even so, the packaging, hooks, news and
critic researchers all recommend **a second plugin** (for example
`mods/superpowers-hud/`, listed as `plugins[1]` in
`.claude-plugin/marketplace.json`), for five reasons:

1. **Safety hooks could disappear.** A malformed `modules` value seems to make
   the whole hooks file fail to load, and that file holds the safety hooks
   *(read in the 2.1.296 program text, not run)*.
2. **Copilot CLI reads the same `hooks/hooks.json`.** Its handling of an
   unknown top-level key is not documented and not tested. Cursor probably
   reads it too *(inferred: `.cursor-plugin/plugin.json` names no other hooks
   file)*. Codex uses its own file and is not affected.
3. **The headless test suites load this checkout with `--plugin-dir`.** A mod
   in the main plugin would run in every behavioural test, wait for its
   `session.start`, and could change what the routing tests measure.
4. **`--plugin-dir` makes the loaded folder a protected path** *(documented)*.
   Loading the repository root as a mod would make every edit in the
   repository ask for approval, including the edits of orchestrated subagents.
5. **Users can turn off the interface alone**, without losing the skills and
   hooks.

**Cost of this layout:** `$.plugin.root` points at the mod's own folder, so the
mod has to find the main plugin's scripts some other way (open question).

### 6.2 Older and other platforms

- Claude Code 2.1.200 drops unknown top-level keys in `hooks.json`. 2.1.260
  already reads `modules`, but only behind the environment variable
  `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS` and a remote switch. *(program text read,
  not run)* The news report quoted an issue comment saying that builds before
  2.1.250 dropped the whole file on an unknown key; the raw comment says
  "unknown *event* key", so the two reports probably do not conflict (section
  7, row 8).
- Claude Code before 2.1.287 does not run mods. A separate plugin then does
  nothing, and the main plugin is unaffected.
- Copilot CLI users get nothing from a mod. This plugin already behaves
  differently there: Copilot CLI drops the output of `userPromptSubmitted`
  hooks and uses `modifiedResult` instead of `updatedToolOutput`, so
  skill-activator and smart-compress already do nothing there.

### 6.3 Tests

A new `tests/mod/run-tests.sh` would run `claude plugin validate --strict` and
`claude plugin test` on the mod folder. It must:

- print SKIP when `claude` is missing or older than 2.1.287, so that the
  repository's undefined-command guard does not stop the suite on exit code
  127;
- decide by the printed message, not only the exit code (see 2.5);
- not run `--strict` on the repository root (the current CLAUDE.md warning
  makes it fail).

### 6.4 Release impact

Two more version places: the mod's `plugin.json` and `plugins[1]` in
`marketplace.json`. `tests/codex/test-version-files.js` would need to check
them. The mod's version must change whenever its code changes, because
installs are cached by version. `tools/sync-dev-install.sh` probably cannot
sync a plugin that lives in a sub-folder as it is today *(inferred)*.

---

## 7. Disagreements between researchers

These are reported as found, not resolved silently. "Merging session" means
the session that wrote this document.

| # | Topic | Position 1 | Position 2 | Merging session's reading |
|---|---|---|---|---|
| 1 | **Build a mod at all?** | Critic: not now. No recorded case needs one; the API is 9 days old; the only unique gain (zero-token status) is small; a second terminal running `pickup-scan.js`, or the existing `statusLine`, gives it with no mod code. | Orchestration, community and news researchers: no known mod shows this fork's pipeline, and a recorded stop waited 6 h 09 min for a human. | Both hold. The 6 h 09 min wait is the kind of case the critic asked for, but one case is weak evidence. Hence the stepped path: private first, measured, then published. |
| 2 | **Can a mod wrap the settings hooks (`classic.*`)?** | Hooks researcher: yes, from the types file (lines 969–1088) and the events page. | News researcher: open issues #100869 and #96831 say `classic.*` events do not reach a hooks module. | Documented but reported broken. Ideas E and F wait for a live probe. |
| 3 | **Use `$.ui.status` for progress?** | Official-source researcher: it is the cheapest progress line. | Interface researcher and critic: it always starts with `⚠`, so it reads as a warning. | Use it only for "needs you" (idea B). Use the band for progress. |
| 4 | **Can a mod's "Proceed" button get past our guard?** | Official-source researcher: no; a plugin's `PreToolUse` hooks run after the mods on `tool.call`, so our deny still wins. | Hooks researcher and critic, from the overview page: at `tool.check` (after the hooks) a mod can answer `allow`, even for a call a `PreToolUse` hook blocked. | Both are right for their event. The `tool.check` route is a real way around the guard. |
| 5 | **Add a "Run it once" button to the git guard?** | Hooks researcher: yes, at `tool.check`, main conversation only (32 real `git reset --hard` refusals in 35 days). | Critic: never move a guard into a mod. | No button (idea D). Row 4 shows the button would bypass the guard, and a held call could stop an orchestrated run. |
| 6 | **Cost of a mod command's reply** | Official-source researcher: an immediate command uses no model turn, and its `/runs` sketch returns `{ text }`. | Events and work-log researchers: returned `text` is read by Claude on the next turn. | Both are true. Zero tokens needs `return {}` and drawing in a pane. |
| 7 | **Use Claude Code's `meta.json` files as a live source?** | Orchestration researcher: the best live source (written when each subagent starts). | The same researcher's own warning and the critic: internal to Claude Code; fields changed between runs. | Not recommended; events first, the repository's own files as fallback. |
| 8 | **Do old Claude Code builds reject an unknown key in `hooks.json`?** | News researcher: builds before 2.1.250 dropped the whole file on an unknown key (from an issue comment). | Packaging researcher: 2.1.200 drops unknown top-level keys (program text). | The raw comment says "unknown *event* key", so the packaging reading probably stands. Not run. |
| 9 | **Number of mods changelog lines** | Critic: about 80 (its fetch was cut off). | News researcher: 87 (full read). | Use 87. |

---

## 8. Recommended path

### Step 0 — probe mod (private)

A temporary mod outside the repository (for example `~/mods/sp-probe`, loaded
with `--plugin-dir`). It only writes `$.ui.log` lines, so it costs no context.
Run one short orchestration on a scratch repository (a one-task plan, one
review round) and answer:

1. Do `agent.spawn` and `tool.call` fire for **named background** subagents,
   and for **depth-2** subagents (reviewers dispatched by a controller), on
   2.1.296? Does `agent.spawn` carry the dispatch description, or only the
   start of the prompt?
2. Does `turn.complete` fire for a background subagent after the main turn has
   ended?
3. Does `classic.UserPromptSubmit` reach the module? Does
   `classic.FileChanged` work when a `SessionStart` hook returns `watchPaths`?
   If it does, it would give real file watching.
4. Does `$.process.run` keep the right working folder inside a worktree
   subagent (the 2.1.296 fix)?
5. Only if the mod ever goes into the main plugin: on a scratch copy of the
   plugin, does Copilot CLI accept a `modules` key in `hooks/hooks.json`?

Before the run, without installing anything:

- run `/plugin-types` once, to get the type file for the installed version;
- read the code of superpowers-tracker, to see whether it already reads
  `.superpowers/sdd/` the way this fork writes it. Installing it would run
  third-party code with your permissions.

**Effort:** the mod is a few dozen lines. Most of the time goes into the
scratch orchestration run, which takes as long as a small real run.

**If question 1 fails:** Mission Control (idea A) falls back to file polling
only (see idea A). Step 1 is still possible, without the silence alarm.

### Step 1 — private status mod

Also outside the repository, loaded with `--plugin-dir`:

- an immediate `/runs` command (a reduced idea C) that runs `pickup-scan.js`
  for the unfinished runs and the handoff, and `dashboard-extract.js` for the
  active work logs. It draws them in a pane and returns `{}`;
- idea B, the "needs you" alert and the silence alarm, if Step 0 shows the
  events arrive; compare it with an operating-system notification from a
  settings hook;
- no tool, prompt or permission hooks.

**Effort:** 120–200 source lines and 100–250 test lines (estimate from the
official samples).

**Keep it only if** (adapted from the critic's criteria):

- it is used at least 3 times across the next two orchestrated runs;
- for each use, the session transcript gains no record that Claude reads with
  the command's output (check with a search in the transcript file for a
  string that only the pane shows);
- the debug log shows no skipped hook and no worker crash.

Otherwise delete it and add one line to `## Accepted limits` in
`docs/orchestration-issues.md`.

### Step 2 — Mission Control as a separate plugin

If Step 1 meets the keep criteria: build idea A, plus the rest of C, as
`mods/superpowers-hud/` in the same marketplace, with
`tests/mod/run-tests.sh`, the release changes of 6.4, and a README section
that shows what the mod reads (the `claude plugin validate` output) and states
that it is read-only.

**Effort:** 300–450 source lines for A, 120–200 for the rest of C, and tests.
**Maintenance:** the API changed in 87 changelog lines over 10 releases. Plan
to re-run `tests/mod/run-tests.sh` after each Claude Code update, and to bump
the mod's version with every change.

### Not on the path (for now)

Ideas D–H, until Step 0 is done and the API stops changing every few days.

---

## 9. Open questions

**Need a live test** (Step 0 covers 1–4):

1. Subagent events for named background agents and at depth 2, and the field
   that carries the dispatch description.
2. `turn.complete` for a background subagent after the main turn has ended.
3. `classic.*` reachability (`UserPromptSubmit`, `FileChanged`).
4. `$.process.run` working folder inside worktree subagents.
5. Copilot CLI and Cursor with a `modules` key in `hooks/hooks.json`.
6. Does `{"hooks": {}, "modules": [...]}` load quietly on an old Claude Code?
7. Does a malformed `modules` value really drop the safety hooks?
8. Can `$.tool.call` reach the Artifact tool without a Claude turn? If yes, a
   dashboard refresh could also cost zero tokens.

**Need reading or a decision, no live test:**

9. How should a separate mod plugin find the main plugin's scripts?
10. Does the community superpowers-tracker mod read this fork's
    `.superpowers/sdd/` files (Step 0, reading its code)?

---

## 10. Sources

**Claude Code docs** (read 2026-10-10):

- Overview: <https://code.claude.com/docs/en/plugins/mods/overview>
- Create: <https://code.claude.com/docs/en/plugins/mods/create>
- Interface: <https://code.claude.com/docs/en/plugins/mods/interface>
- Events: <https://code.claude.com/docs/en/plugins/mods/events>
- API: <https://code.claude.com/docs/en/plugins/mods/api>
- Test: <https://code.claude.com/docs/en/plugins/mods/test>
- Troubleshoot: <https://code.claude.com/docs/en/plugins/mods/troubleshoot>
- Admin: <https://code.claude.com/docs/en/plugins/mods/admin>
- Reference: <https://code.claude.com/docs/en/plugins/mods/reference>
- Types file `claude-code.d.ts` (generated by 2.1.277), published in the
  anthropics GitHub repositories.

**Anthropic source:**

- Sample mods: <https://github.com/anthropics/claude-code-playground/tree/main/claude-code/mods>
  (token-weather 122 lines; replay-theater 249; blast-radius 528; no published
  tests)
- Built-in mods: <https://github.com/anthropics/claude-code/tree/main/mods>
  (diff 8,238 lines and 212 tests; sec-default 668 and 57; telemetry 3,061
  and 34; agents-md 1,070 and 5)

**GitHub issues** (anthropics/claude-code): #91870 (early-access feedback
thread), #92533, #96831, #99045, #99130, #99211, #99265, #100869, #100918.

**Community:** see the links in section 4.

**Security:** <https://pluto.security/blog/claude-code-function-hooks-security/>

**Repository files read:** `skills/orchestrating-development/SKILL.md`,
`skills/subagent-driven-development/`, `skills/multi-doc-review/`,
`skills/multi-code-review/`, `skills/worklog/`, `skills/dashboard/scripts/`,
`skills/pickup/scripts/`, `hooks/hooks.json`, `hooks/*.js`,
`hooks/safety/*.js`, `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, past run folders under
`docs/superpowers-orchestrator/`.

---

## Appendix A — Method

Ten research subagents ran in parallel on 2026-10-10. Each had one angle, and
all had read-only access to the repository:

| # | Angle |
|---|---|
| 1 | Drawing surfaces (interface and reference pages) |
| 2 | Events and the mods API, including subagent visibility |
| 3 | Packaging, compatibility, testing and debugging inside this plugin (with checks in a scratch folder) |
| 4 | Source code of Anthropic's sample and built-in mods |
| 5 | Community mods on GitHub and in catalogues |
| 6 | Changelog, GitHub issues, reception, similar features in other tools |
| 7 | Signals of orchestration progress in this repository and past runs |
| 8 | Work-log, dashboard and pickup data; zero-token commands |
| 9 | This plugin's settings hooks: which a mod could improve |
| 10 | Critic: premise check, risks, smallest worthwhile step |

Three review subagents then checked the merged document: against the ten
reports, against the live documentation (12 of 18 checked claims confirmed;
the others were corrected in this version), and for clarity and internal
consistency.

The full reports (each claim marked verified or inferred) were written to the
session's scratchpad folder, which is temporary.
