#!/usr/bin/env node
// Measure where a Claude Code session's context window went.
//
// Written for the acceptance measure of worklist row 13 fix 1 (see
// docs/orchestration-issues.md, Cases 017 and 018): the orchestrator's own
// "prompt material" — the text it writes and re-sends in order to dispatch a
// controller — must stay below 10 percent of the session's content.
//
// The script is committed on purpose. The two earlier versions of this
// measurement lived in a session scratchpad under /private/tmp and were both
// lost, so the same counting rules had to be rediscovered twice.
//
// Two numbers, counted in two different units, on purpose:
//
//   1. Shares by class are BYTES of message content. A share is a proportion,
//      so the unit cancels out; bytes need no tokenizer and are exact.
//   2. Peak context is TOKENS, read from the `usage` object of each API
//      response, and it is a MAXIMUM over requests, never a sum.
//
// THE COUNTING TRAP THIS SCRIPT AVOIDS. One API response is written to the
// transcript as several records that all repeat the same `usage` object. A
// naive sum over records therefore overcounts tokens by 3 to 5 times. Every
// token figure below is deduplicated on `requestId` first. (Verified on a real
// transcript: 166 assistant records, 90 distinct requests, one requestId
// carrying 6 records.)
//
// Worklist row 27 added four measures on top of the shares:
//
//   3. A second share table, "model-visible", that leaves out the attachment
//      records the model never sees (`hook_success` and `prompt_snapshot`).
//   4. The skill body: the growth of the context, in tokens, from the request
//      that made a Skill tool call to the next request; and a count of reads
//      under any path containing `/skills/`.
//   5. PARTIAL notices: how many times the Read tool cut a file at its token
//      cap, and whether the agent then paged to the end, paged short, or did
//      not page at all.
//   6. File coverage: for every file whose first read was cut, the union of
//      the line ranges the agent received over BOTH hand-over routes, the
//      uncovered ranges, and whether the last line was reached. A "hand-over"
//      is the moment a large file reaches the model in pieces:
//        - Read route: a Read call returns at most about 25,000 tokens, then
//          a notice "PARTIAL view — <path>: showing lines A-B of T total"
//          names the next offset. The notice sits in the tool result or in a
//          separate attachment record (type read_truncation_notice).
//        - cat route: a Bash `cat <file>` whose output exceeds 30,000
//          characters is persisted; the result says "Output too large (N KB).
//          Full output saved to: <path>" with a 2 KB preview. The agent may
//          read the persisted path back with sed, head, tail, awk or Read.
//      A PARTIAL count alone cannot see the cat route, which is why the
//      acceptance measure is the line coverage over both routes.
//
// Usage:
//   node tools/measure-context.js <transcript.jsonl> [--json]
//
// The transcript is a session file
// (~/.claude/projects/<project>/<session-uuid>.jsonl) or a subagent file
// (<session-uuid>/subagents/agent-<id>.jsonl). Both have the same shape, so a
// controller's window is measured with the same command.

'use strict';

const fs = require('fs');
const path = require('path');

// A Write whose file name begins like this is a dispatch value file — the
// answers/lens/findings text a controller or the orchestrator writes for a
// prompt to be filled from. Those bytes are prompt material; other writes are
// ordinary work (a log entry, a source edit) and are not.
const VALUE_FILE_NAME = /^dispatch-\d+-/;
// A Bash command that fills a prompt template. These bytes are prompt material.
const FILL_COMMAND = 'fill-prompt.js';
// Tool names that dispatch a subagent. `Task` is the older name for `Agent`.
const AGENT_TOOLS = new Set(['Agent', 'Task']);
const WRITE_TOOLS = new Set(['Write', 'Edit', 'NotebookEdit']);
const SKILL_TOOL = 'Skill';
// A path segment that marks a read of a skill directory.
const SKILL_DIRECTORY = '/skills/';
// Attachment record kinds the model never sees: a hook's success record and
// the harness's snapshot of the system prompt.
const MODEL_INVISIBLE_ATTACHMENTS = ['hook_success', 'prompt_snapshot'];

// Classes reported, in the order they are printed.
const CLASSES = [
  'agent-prompts',
  'fill-commands',
  'value-files',
  'bash-commands',
  'other-tool-inputs',
  'other-writes',
  'thinking',
  'assistant-text',
  'read-results',
  'bash-results',
  'agent-reports',
  'other-results',
  'attachments',
  'user-messages',
];
// The three classes that make up prompt material: what the session writes and
// re-sends so that a subagent can be dispatched.
const PROMPT_MATERIAL = ['agent-prompts', 'fill-commands', 'value-files'];

// --- Hand-over patterns (row 27) ---
// The notice the Read tool leaves when a file exceeds its token cap.
const PARTIAL_NOTICE = /PARTIAL view — (\S+?): showing lines (\d+)-(\d+) of (\d+) total/g;
// The marker in a Bash result whose output was too large and was persisted.
const PERSISTED_OUTPUT = /Full output saved to: (\S+)/;
// The preview text of a persisted result sits between these two markers; the
// last preview line is usually cut in the middle, so only complete lines count.
const PREVIEW_START = /Preview \(first [^)]*\):\n/;
const PREVIEW_END = /\n\.\.\.\n?<\/persisted-output>\s*$/;
// One line of a Read result: line number, a tab, then the text.
const READ_LINE = /^\s*(\d+)\t/;
// A shell assignment `NAME=value` at the start of a command unit, so that a
// later `$NAME` can be resolved to the path it names.
const SHELL_ASSIGNMENT = /(?:^|[;&|\n]\s*)([A-Za-z_]\w*)=(["']?)([^\s"';|&]+)\2/g;
// A command is split into units at `;`, `&&`, `||` and newlines, and a unit
// into pipeline segments at `|`.
const UNIT_SPLIT = /\s*(?:;|&&|\|\||\n)\s*/;
const CD_UNIT = /^cd\s+(["']?)([^\s"']+)\1/;
// A unit that is a plain `cat` of one file, nothing piped after it.
const CAT_TARGET = /^cat\s+(?:-[a-zA-Z]+\s+)*(["']?)([^\s"'|;&<>]+)\1\s*$/;
// The expression argument of sed and awk, quoted or bare.
const SED_EXPRESSION = /\bsed\s+(?:-[a-zA-Z]+\s+)*(?:'([^']*)'|"([^"]*)"|(\S+))/;
const AWK_EXPRESSION = /\bawk\s+(?:'([^']*)'|"([^"]*)")/;
const HEAD_COUNT = /\bhead\s+(?:-n\s*)?-?(\d+)/;
const TAIL_FROM = /\btail\s+(?:-n\s*)?\+(\d+)/;
const TAIL_COUNT = /\btail\s+(?:-n\s*)?-?(\d+)/;
// Where a file's total line count came from, in order of trust.
const TOTAL_FROM_NOTICE = 'from a PARTIAL notice';
const TOTAL_FROM_READ = 'from a Read result';
const TOTAL_FROM_DISK = 'counted on disk';
const UNKNOWN = 'unknown';

function bytes(value) {
  if (value === undefined || value === null) return 0;
  const s = typeof value === 'string' ? value : JSON.stringify(value);
  return Buffer.byteLength(s, 'utf8');
}

function readRecords(file) {
  const out = [];
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (!line.trim()) continue;
    try {
      out.push(JSON.parse(line));
    } catch {
      // A partial last line is normal while a session is still running.
    }
  }
  return out;
}

// Tokens held in the model's context for one request. `output_tokens` is what
// the model produced, not what it was holding, so it is excluded.
function contextTokens(usage) {
  if (!usage) return 0;
  return (usage.input_tokens || 0) +
    (usage.cache_read_input_tokens || 0) +
    (usage.cache_creation_input_tokens || 0);
}

// The text of a tool_result block: a string, or a list of text blocks.
function resultText(block) {
  const content = block.content;
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  return content.map((part) => (part && part.text) || '').join('\n');
}

function measure(records) {
  const totals = Object.fromEntries(CLASSES.map((c) => [c, 0]));
  // Bytes of the attachment records the model never sees, by kind.
  const excluded = Object.fromEntries(MODEL_INVISIBLE_ATTACHMENTS.map((k) => [k, 0]));
  // tool_use id -> tool_use block, so a tool_result can be attributed to its
  // tool and read with its input.
  const toolUseById = new Map();
  // requestId -> context tokens. A Map keyed on requestId is the deduplication.
  const requests = new Map();
  // requestId -> names of the skills called by that request.
  const skillCallsByRequest = new Map();
  let skillDirectoryReads = 0;
  let assistantRecords = 0;
  // Counted so the report can say when thinking text was not stored: the
  // transcript keeps the signature and drops the text, so those bytes are
  // missing from `content` and every share is an upper bound.
  let thinkingBlocks = 0;
  const coverage = newCoverage();

  records.forEach((rec, index) => {
    if (rec.type === 'attachment') {
      const size = bytes(rec.attachment);
      totals.attachments += size;
      const kind = rec.attachment && rec.attachment.type;
      if (kind in excluded) excluded[kind] += size;
      trackNoticeAttachment(coverage, rec, index);
      return;
    }

    if (rec.type === 'assistant') {
      assistantRecords += 1;
      const msg = rec.message || {};
      const key = rec.requestId || msg.id || `norequestid-${rec.uuid}`;
      if (!requests.has(key)) requests.set(key, contextTokens(msg.usage));

      for (const block of Array.isArray(msg.content) ? msg.content : []) {
        if (block.type === 'thinking') {
          thinkingBlocks += 1;
          totals.thinking += bytes(block.thinking);
        } else if (block.type === 'text') {
          totals['assistant-text'] += bytes(block.text);
        } else if (block.type === 'tool_use') {
          classifyToolUse(block, totals, toolUseById);
          if (block.name === SKILL_TOOL) {
            if (!skillCallsByRequest.has(key)) skillCallsByRequest.set(key, []);
            skillCallsByRequest.get(key).push((block.input || {}).skill || '?');
          }
          if (readsSkillDirectory(block)) skillDirectoryReads += 1;
        }
      }
      return;
    }

    if (rec.type === 'user') {
      const content = (rec.message || {}).content;
      if (!Array.isArray(content)) {
        totals['user-messages'] += bytes(content);
        return;
      }
      for (const block of content) {
        if (block.type === 'tool_result') {
          const use = toolUseById.get(block.tool_use_id) || {};
          const size = bytes(block.content);
          if (use.name === 'Read') totals['read-results'] += size;
          else if (use.name === 'Bash') totals['bash-results'] += size;
          else if (AGENT_TOOLS.has(use.name)) totals['agent-reports'] += size;
          else totals['other-results'] += size;
          trackToolResult(coverage, rec, index, block, use);
        } else if (block.type === 'text') {
          totals['user-messages'] += bytes(block.text);
        }
      }
    }
  });

  const content = CLASSES.reduce((sum, c) => sum + totals[c], 0);
  const promptMaterial = PROMPT_MATERIAL.reduce((sum, c) => sum + totals[c], 0);
  const peakTokens = requests.size ? Math.max(...requests.values()) : 0;
  const excludedBytes = Object.values(excluded).reduce((a, b) => a + b, 0);
  const modelVisibleTotals = Object.assign({}, totals, {
    attachments: totals.attachments - excludedBytes,
  });
  const modelVisibleContent = content - excludedBytes;

  return {
    totals,
    content,
    promptMaterial,
    promptMaterialPercent: percent(promptMaterial, content),
    peakTokens,
    assistantRecords,
    distinctRequests: requests.size,
    thinkingBlocks,
    thinkingTextStored: totals.thinking > 0,
    modelVisible: {
      totals: modelVisibleTotals,
      content: modelVisibleContent,
      excluded,
      promptMaterialPercent: percent(promptMaterial, modelVisibleContent),
    },
    skillBody: skillBody(requests, skillCallsByRequest),
    skillDirectoryReads,
    ...finishCoverage(coverage),
  };
}

function percent(part, whole) {
  return whole ? (part * 100) / whole : 0;
}

function classifyToolUse(block, totals, toolUseById) {
  const name = block.name;
  const input = block.input || {};
  toolUseById.set(block.id, block);

  if (AGENT_TOOLS.has(name)) {
    totals['agent-prompts'] += bytes(input.prompt);
    const rest = Object.assign({}, input);
    delete rest.prompt;
    totals['other-tool-inputs'] += bytes(rest);
    return;
  }

  if (name === 'Bash') {
    const command = input.command || '';
    const size = bytes(command);
    if (command.includes(FILL_COMMAND)) totals['fill-commands'] += size;
    else totals['bash-commands'] += size;
    const rest = Object.assign({}, input);
    delete rest.command;
    totals['other-tool-inputs'] += bytes(rest);
    return;
  }

  if (WRITE_TOOLS.has(name)) {
    const size = bytes(input.content) + bytes(input.new_string);
    const base = path.basename(input.file_path || '');
    if (VALUE_FILE_NAME.test(base)) totals['value-files'] += size;
    else totals['other-writes'] += size;
    return;
  }

  totals['other-tool-inputs'] += bytes(input);
}

// A Read call, or a Bash command, that names a path under a skill directory.
function readsSkillDirectory(block) {
  const input = block.input || {};
  if (block.name === 'Read') return (input.file_path || '').includes(SKILL_DIRECTORY);
  if (block.name === 'Bash') return (input.command || '').includes(SKILL_DIRECTORY);
  return false;
}

// The skill body, in tokens: for each request that made a Skill call, the
// context tokens of the next request minus this one. The jump holds the skill
// body plus whatever else arrived with it (the tool result, hook records),
// which is what the row asks for: the cost of the Skill call as the API saw it.
function skillBody(requests, skillCallsByRequest) {
  const keys = Array.from(requests.keys());
  const perCall = [];
  let calls = 0;
  keys.forEach((key, i) => {
    const skills = skillCallsByRequest.get(key);
    if (!skills) return;
    calls += skills.length;
    const next = keys[i + 1];
    const tokens = next === undefined ? 0 : requests.get(next) - requests.get(key);
    perCall.push({ skill: skills.join(' + '), tokens, nextRequestSeen: next !== undefined });
  });
  return { calls, tokens: perCall.reduce((sum, c) => sum + c.tokens, 0), perCall };
}

// --- File coverage over both hand-over routes (row 27) ---

function newCoverage() {
  return {
    files: new Map(),           // file path -> state, in first-seen order
    aliases: new Map(),         // persisted output path -> file path
    notices: [],                // every PARTIAL notice, once per tool call
    noticedToolUses: new Set(), // tool_use ids whose notice is already counted
    diskLines: new Map(),       // file path -> its lines on disk, or null
  };
}

// The state of one file. A persisted output path is an alias of the file it
// was made from, so reads of the copy count for the original.
function fileFor(coverage, rawPath) {
  const filePath = coverage.aliases.get(rawPath) || rawPath;
  if (!coverage.files.has(filePath)) {
    coverage.files.set(filePath, {
      path: filePath,
      firstRoute: null,     // 'Read' or 'cat'
      cut: false,           // the first read did not deliver the whole file
      whole: false,         // one call delivered the whole file
      covered: new Set(),   // line numbers received
      openRanges: [],       // starts of ranges that run to the end of the file
      readTotal: null,      // total lines as the Read tool counts them
      totalSource: null,
      phantom: false,       // the Read total counts an empty line after the final newline
      lastRangeRecord: -1,  // index of the last record that delivered lines
      events: [],
    });
  }
  return coverage.files.get(filePath);
}

function firstRead(file, route, cut, whole) {
  if (!file.firstRoute) {
    file.firstRoute = route;
    file.cut = cut;
  }
  if (whole) file.whole = true;
}

function addRange(file, from, to, recordIndex, event) {
  if (!(from >= 1)) return;
  if (to === Infinity) {
    file.openRanges.push(from);
    file.events.push(`${event} -> ${from}-end`);
    return;
  }
  if (!(to >= from)) return;
  for (let line = from; line <= to; line += 1) file.covered.add(line);
  file.lastRangeRecord = Math.max(file.lastRangeRecord, recordIndex);
  file.events.push(`${event} -> ${from}-${to}`);
}

// A PARTIAL notice's total is preferred over a Read result's, although both
// count lines the same way; the label then says which one the reader sees.
function setTotal(file, total, source) {
  if (!(total >= 1)) return;
  if (file.readTotal === null || source === TOTAL_FROM_NOTICE) {
    file.readTotal = total;
    file.totalSource = source;
  }
}

function noticesIn(text) {
  return Array.from(text.matchAll(PARTIAL_NOTICE)).map((m) => ({
    path: m[1], from: Number(m[2]), to: Number(m[3]), total: Number(m[4]),
  }));
}

function registerNotice(coverage, key, notice) {
  if (coverage.noticedToolUses.has(key)) return;
  coverage.noticedToolUses.add(key);
  coverage.notices.push(notice);
}

// A notice carried by an attachment record (type read_truncation_notice).
function trackNoticeAttachment(coverage, rec, index) {
  const attachment = rec.attachment;
  if (!attachment || typeof attachment !== 'object') return;
  const text = typeof attachment.banner === 'string' ? attachment.banner : JSON.stringify(attachment);
  for (const notice of noticesIn(text)) {
    const file = fileFor(coverage, notice.path);
    setTotal(file, notice.total, TOTAL_FROM_NOTICE);
    firstRead(file, 'Read', true, false);
    registerNotice(coverage, attachment.toolUseID || `${notice.path}:${notice.from}`, Object.assign(notice, {
      path: file.path, persisted: notice.path !== file.path, recordIndex: index,
    }));
  }
}

function trackToolResult(coverage, rec, index, block, use) {
  if (use.name === 'Read') trackRead(coverage, rec, index, block, use.input || {});
  else if (use.name === 'Bash') trackBash(coverage, rec, index, block, use.input || {});
}

function trackRead(coverage, rec, index, block, input) {
  const rawPath = input.file_path || '';
  if (!rawPath) return;
  const file = fileFor(coverage, rawPath);
  const text = resultText(block);
  const info = (rec.toolUseResult || {}).file || {};
  // The harness's own record of what was returned is preferred; the line
  // numbers printed in the result text are the fallback.
  const numbers = text.split('\n').map((l) => READ_LINE.exec(l)).filter(Boolean).map((m) => Number(m[1]));
  const start = info.startLine || (numbers.length ? numbers[0] : (input.offset || 1));
  const end = info.numLines ? start + info.numLines - 1 : (numbers.length ? numbers[numbers.length - 1] : start - 1);
  const inText = noticesIn(text);
  const cut = Boolean(info.truncatedByTokenCap) || inText.length > 0;
  const paged = input.offset !== undefined || input.limit !== undefined;

  if (info.totalLines) {
    setTotal(file, info.totalLines, TOTAL_FROM_READ);
    // The Read tool numbers the empty line after the file's final newline as
    // a line of its own, so its total is one more than sed or wc count. A
    // result whose last line is that empty line proves the extra line exists.
    const lastLine = text.slice(text.lastIndexOf('\n') + 1);
    const m = /^\s*(\d+)\t$/.exec(lastLine);
    if (m && Number(m[1]) === info.totalLines) file.phantom = true;
  }
  firstRead(file, 'Read', cut, !paged && !cut && start === 1);
  const label = `Read${paged ? ` offset=${input.offset} limit=${input.limit}` : ''}${cut ? ' (cut)' : ''}`;
  addRange(file, start, end, index, label);
  if (cut) {
    const notice = inText[0] || { from: start, to: end, total: info.totalLines || null };
    if (inText[0]) setTotal(file, notice.total, TOTAL_FROM_NOTICE);
    registerNotice(coverage, block.tool_use_id, Object.assign(notice, {
      path: file.path, persisted: rawPath !== file.path, recordIndex: index,
    }));
  }
}

// Resolve `$NAME`, `${NAME}` and `"$NAME"` from assignments in the same
// command, so that `S=<path>; sed -n '1,9p' $S` names the path.
function substituteShellVariables(command) {
  let out = command;
  for (const m of command.matchAll(SHELL_ASSIGNMENT)) {
    const [, name, , value] = m;
    out = out.split(`"\${${name}}"`).join(value)
      .split(`"$${name}"`).join(value)
      .split(`\${${name}}`).join(value)
      .replace(new RegExp(`\\$${name}(?![A-Za-z0-9_])`, 'g'), value);
  }
  return out;
}

function absolutePath(p, cwd) {
  if (path.isAbsolute(p) || !cwd) return p;
  return path.join(cwd, p);
}

// The complete lines in a persisted result's preview. The preview ends with a
// line cut in the middle, so only lines that end with a newline are counted.
function previewLineCount(text) {
  const start = PREVIEW_START.exec(text);
  if (!start) return 0;
  const preview = text.slice(start.index + start[0].length).replace(PREVIEW_END, '');
  return preview.split('\n').length - 1;
}

function trackBash(coverage, rec, index, block, input) {
  const text = resultText(block);
  const command = substituteShellVariables(input.command || '');
  const persisted = PERSISTED_OUTPUT.exec(text);
  let cwd = rec.cwd || '';

  for (const unit of command.split(UNIT_SPLIT)) {
    const cd = CD_UNIT.exec(unit);
    if (cd) {
      cwd = absolutePath(cd[2], cwd);
      continue;
    }
    const cat = CAT_TARGET.exec(unit);
    if (cat) {
      const file = fileFor(coverage, absolutePath(cat[2], cwd));
      if (persisted) {
        coverage.aliases.set(persisted[1], file.path);
        const preview = previewLineCount(text);
        firstRead(file, 'cat', true, false);
        addRange(file, 1, preview, index, `cat persisted (${preview} complete preview lines)`);
      } else {
        firstRead(file, 'cat', false, true);
        addRange(file, 1, Infinity, index, 'cat whole');
      }
      continue;
    }
    const segments = unit.split('|');
    segments.forEach((segment, i) => {
      const file = trackedFileNamed(coverage, segment, cwd);
      if (!file) return;
      const cap = HEAD_COUNT.exec(segments.slice(i + 1).join('|'));
      const ranges = capRanges(rangesOf(coverage, file, segment), cap ? Number(cap[1]) : null);
      for (const [from, to] of ranges) addRange(file, from, to, index, segment.trim().slice(0, 60));
    });
  }
}

// The tracked file that a pipeline segment names, by absolute path, by the
// path relative to the working directory, or by a persisted alias of it.
function trackedFileNamed(coverage, segment, cwd) {
  const names = Array.from(coverage.files.keys()).map((p) => [p, p])
    .concat(Array.from(coverage.aliases.entries()));
  for (const [name, filePath] of names) {
    const candidates = [name];
    if (cwd && name.startsWith(cwd + '/')) candidates.push(name.slice(cwd.length + 1));
    for (const candidate of candidates) {
      const token = new RegExp(`(^|[\\s"'=])${candidate.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(?=$|[\\s"'|;&)])`);
      if (token.test(segment)) return coverage.files.get(filePath);
    }
  }
  return null;
}

// The line ranges a segment delivers from the file it names. `Infinity` as
// the end of a range means "to the end of the file", resolved when the total
// is known.
function rangesOf(coverage, file, segment) {
  const out = [];
  let m;
  const sed = SED_EXPRESSION.exec(segment);
  if (sed) {
    const expression = [sed[1], sed[2], sed[3]].find((e) => e !== undefined) || '';
    for (const part of expression.split(';').map((p) => p.trim())) {
      if ((m = /^(\d+),(\d+)p$/.exec(part))) out.push([Number(m[1]), Number(m[2])]);
      else if ((m = /^(\d+)p$/.exec(part))) out.push([Number(m[1]), Number(m[1])]);
      else if ((m = /^(\d+),\$p$/.exec(part))) out.push([Number(m[1]), Infinity]);
      else if ((m = /^\/(.*)\/,(?:\/(.*)\/|(\$))p$/.exec(part))) out.push(...patternRanges(coverage, file, m[1], m[2]));
    }
    return out;
  }
  const awk = AWK_EXPRESSION.exec(segment);
  if (awk) {
    const expression = (awk[1] !== undefined ? awk[1] : awk[2]).trim();
    if ((m = /NR\s*>=\s*(\d+)\s*&&\s*NR\s*<=\s*(\d+)/.exec(expression))) out.push([Number(m[1]), Number(m[2])]);
    else if ((m = /NR\s*==\s*(\d+)\s*,\s*NR\s*==\s*(\d+)/.exec(expression))) out.push([Number(m[1]), Number(m[2])]);
    else if ((m = /^\/(.*)\/,(?:\/(.*)\/|(0))$/.exec(expression))) out.push(...patternRanges(coverage, file, m[1], m[2]));
    return out;
  }
  if ((m = TAIL_FROM.exec(segment))) out.push([Number(m[1]), Infinity]);
  else if ((m = TAIL_COUNT.exec(segment))) {
    const total = knownTotal(file);
    if (total) out.push([Math.max(1, total - Number(m[1]) + 1), total]);
  } else if ((m = HEAD_COUNT.exec(segment))) out.push([1, Number(m[1])]);
  else if (/\bcat\b/.test(segment)) out.push([1, Infinity]);
  return out;
}

// `awk '/A/,/B/'` and `sed -n '/A/,/B/p'` are emulated on the file's text on
// disk: from each line matching A to the first later line matching B, both
// included; no end pattern means to the end of the file.
function patternRanges(coverage, file, startPattern, endPattern) {
  const lines = linesOnDisk(coverage, file);
  if (!lines) {
    file.events.push(`pattern range /${startPattern}/ not resolved: file not on disk`);
    return [];
  }
  const out = [];
  let startRe;
  let endRe;
  try {
    startRe = new RegExp(startPattern);
    endRe = endPattern === undefined ? null : new RegExp(endPattern);
  } catch {
    file.events.push(`pattern range /${startPattern}/ not resolved: not a JavaScript regular expression`);
    return [];
  }
  let i = 0;
  while (i < lines.length) {
    if (!startRe.test(lines[i])) {
      i += 1;
      continue;
    }
    let j = i + 1;
    if (endRe) {
      while (j < lines.length && !endRe.test(lines[j])) j += 1;
      j = Math.min(j + 1, lines.length);
    } else {
      j = lines.length;
    }
    out.push([i + 1, j]);
    i = j;
  }
  return out;
}

// A `| head -n N` after a range keeps the first N lines the range emits.
function capRanges(ranges, cap) {
  if (cap === null) return ranges;
  const out = [];
  let left = cap;
  for (const [from, to] of ranges) {
    if (left <= 0) break;
    const take = Math.min(to - from + 1, left);
    out.push([from, from + take - 1]);
    left -= take;
  }
  return out;
}

// The file's text on disk, by its own path or by a persisted alias, split into
// lines the way `wc -l` counts them. Cached; null when unreadable.
function linesOnDisk(coverage, file) {
  if (coverage.diskLines.has(file.path)) return coverage.diskLines.get(file.path);
  const candidates = [file.path].concat(
    Array.from(coverage.aliases.entries()).filter(([, p]) => p === file.path).map(([alias]) => alias));
  let lines = null;
  for (const candidate of candidates) {
    try {
      const text = fs.readFileSync(candidate, 'utf8');
      lines = text.split('\n');
      if (lines.length && lines[lines.length - 1] === '') lines.pop();
      break;
    } catch {
      // Try the next candidate.
    }
  }
  coverage.diskLines.set(file.path, lines);
  return lines;
}

// Total lines as sed and wc count them, when the transcript says.
function knownTotal(file) {
  return file.readTotal === null ? null : file.readTotal - (file.phantom ? 1 : 0);
}

function rangesToString(lines) {
  const sorted = Array.from(lines).sort((a, b) => a - b);
  const parts = [];
  let i = 0;
  while (i < sorted.length) {
    let j = i;
    while (j + 1 < sorted.length && sorted[j + 1] === sorted[j] + 1) j += 1;
    parts.push(sorted[i] === sorted[j] ? String(sorted[i]) : `${sorted[i]}-${sorted[j]}`);
    i = j + 1;
  }
  return parts.length ? parts.join(', ') : 'none';
}

function finishCoverage(coverage) {
  const fileCoverage = [];
  let fullyReceivedFiles = 0;
  for (const file of coverage.files.values()) {
    let total = knownTotal(file);
    let totalSource = file.totalSource;
    if (total === null && file.cut) {
      const disk = linesOnDisk(coverage, file);
      if (disk) {
        total = disk.length;
        totalSource = TOTAL_FROM_DISK;
      }
    }
    if (total !== null) {
      for (const from of file.openRanges) addRange(file, from, total, file.lastRangeRecord, 'to the end');
      if (file.whole) addRange(file, 1, total, file.lastRangeRecord, 'whole file');
    }
    const received = total === null ? file.covered : new Set(Array.from(file.covered).filter((l) => l <= total));
    const uncovered = [];
    if (total !== null) for (let l = 1; l <= total; l += 1) if (!received.has(l)) uncovered.push(l);
    const complete = file.whole || (total !== null && uncovered.length === 0);
    file.lastLineReached = total !== null ? received.has(total) : (file.whole ? true : null);

    if (!file.cut) {
      if (file.whole) fullyReceivedFiles += 1;
      continue;
    }
    fileCoverage.push({
      path: file.path,
      firstRoute: file.firstRoute,
      totalLines: total,
      totalLinesSource: total === null ? null : totalSource,
      receivedRanges: rangesToString(received),
      receivedLines: received.size,
      coveragePercent: total !== null ? Math.round(percent(received.size, total) * 10) / 10 : (complete ? 100 : null),
      uncoveredRanges: total !== null ? rangesToString(uncovered) : (complete ? 'none' : null),
      lastLineReached: file.lastLineReached,
      events: file.events,
    });
  }

  const partialNotices = { count: 0, pagedToEnd: 0, pagedShort: 0, notPaged: 0, persistedThenRead: 0 };
  for (const notice of coverage.notices) {
    const file = coverage.files.get(notice.path);
    const paged = file.lastRangeRecord > notice.recordIndex;
    partialNotices.count += 1;
    if (!paged) partialNotices.notPaged += 1;
    else if (file.lastLineReached === true) partialNotices.pagedToEnd += 1;
    else partialNotices.pagedShort += 1;
    if (notice.persisted) partialNotices.persistedThenRead += 1;
  }
  return { fileCoverage, fullyReceivedFiles, partialNotices };
}

// --- Report ---

function kb(n) {
  return `${(n / 1024).toFixed(1)} KB`;
}

function printShares(totals, content, promptMaterial) {
  const rows = CLASSES
    .map((c) => [c, totals[c]])
    .filter(([, v]) => v > 0)
    .sort((a, b) => b[1] - a[1]);
  const width = Math.max(...rows.map(([c]) => c.length), 'prompt material'.length);
  for (const [name, value] of rows) {
    const pct = percent(value, content).toFixed(1);
    console.log(`  ${name.padEnd(width)}  ${kb(value).padStart(9)}  ${pct.padStart(5)}%`);
  }
  console.log('');
  console.log(`  ${'prompt material'.padEnd(width)}  ` +
    `${kb(promptMaterial).padStart(9)}  ` +
    `${percent(promptMaterial, content).toFixed(1).padStart(5)}%  ` +
    `(${PROMPT_MATERIAL.join(' + ')})`);
}

function yesNo(value) {
  if (value === null || value === undefined) return UNKNOWN;
  return value ? 'yes' : 'no';
}

function report(file, m) {
  console.log(`Transcript: ${file}`);
  console.log(`Assistant records: ${m.assistantRecords}  ` +
    `distinct requests: ${m.distinctRequests}  ` +
    `(deduplicated on requestId)`);
  console.log(`Peak context: ${m.peakTokens.toLocaleString('en-US')} tokens ` +
    `(a maximum over requests, never a sum)`);
  console.log(`Content: ${kb(m.content)}`);
  console.log('');
  console.log('Shares over every record (the table the issues log cites):');
  printShares(m.totals, m.content, m.promptMaterial);

  const mv = m.modelVisible;
  const excludedList = MODEL_INVISIBLE_ATTACHMENTS.map((k) => `${k} ${kb(mv.excluded[k])}`).join(', ');
  console.log('');
  console.log(`Model-visible shares (without ${MODEL_INVISIBLE_ATTACHMENTS.join(' and ')} ` +
    `attachment records, which the model never sees): content ${kb(mv.content)}, ` +
    `excluded ${excludedList}`);
  printShares(mv.totals, mv.content, m.promptMaterial);

  console.log('');
  const sb = m.skillBody;
  console.log(`Skill body: ${sb.tokens.toLocaleString('en-US')} tokens over ${sb.calls} ` +
    `Skill call${sb.calls === 1 ? '' : 's'} (context tokens of the request after each ` +
    `Skill call minus the request that made it); skill-directory reads: ` +
    `${m.skillDirectoryReads} (Read calls and Bash commands naming a path under ${SKILL_DIRECTORY})`);
  const pn = m.partialNotices;
  console.log(`PARTIAL notices: ${pn.count} (paged to the end: ${pn.pagedToEnd}, ` +
    `paged short: ${pn.pagedShort}, not paged: ${pn.notPaged}; of these on a ` +
    `persisted output file: ${pn.persistedThenRead})`);
  console.log('File coverage (files whose first read was cut; lines received over both routes):');
  for (const f of m.fileCoverage) {
    const firstRead = f.firstRoute === 'cat' ? 'cat, persisted' : 'Read, cut by a PARTIAL notice';
    const total = f.totalLines === null ? UNKNOWN : `${f.totalLines} (${f.totalLinesSource})`;
    const pct = f.coveragePercent === null ? UNKNOWN : `${f.coveragePercent.toFixed(1)}%`;
    console.log(`  ${f.path} | first read: ${firstRead} | total lines: ${total} | ` +
      `received: ${f.receivedRanges} (${f.receivedLines} lines) | coverage: ${pct} | ` +
      `uncovered: ${f.uncoveredRanges === null ? UNKNOWN : f.uncoveredRanges} | ` +
      `last line reached: ${yesNo(f.lastLineReached)}`);
  }
  console.log(`  Files fully received in one call: ${m.fullyReceivedFiles}`);

  if (m.thinkingBlocks > 0 && !m.thinkingTextStored) {
    console.log('');
    console.log(`Note: ${m.thinkingBlocks} thinking blocks carry a signature ` +
      `but no stored text, so their bytes are absent from Content. Every ` +
      `share above is therefore an upper bound.`);
  }
}

function main(argv) {
  const args = argv.filter((a) => a !== '--json');
  const asJson = argv.includes('--json');
  const file = args[0];

  if (!file) {
    console.error('usage: node tools/measure-context.js <transcript.jsonl> [--json]');
    return 2;
  }
  if (!fs.existsSync(file)) {
    console.error(`no such transcript: ${file}`);
    return 2;
  }

  const m = measure(readRecords(file));
  if (asJson) console.log(JSON.stringify(Object.assign({ file }, m), null, 2));
  else report(file, m);
  return 0;
}

if (require.main === module) process.exit(main(process.argv.slice(2)));

module.exports = { measure, readRecords, CLASSES, PROMPT_MATERIAL };
