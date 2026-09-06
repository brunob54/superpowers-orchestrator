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

function measure(records) {
  const totals = Object.fromEntries(CLASSES.map((c) => [c, 0]));
  // tool_use id -> tool name, so a tool_result can be attributed to its tool.
  const toolNameById = new Map();
  // requestId -> context tokens. A Map keyed on requestId is the deduplication.
  const requests = new Map();
  let assistantRecords = 0;
  // Counted so the report can say when thinking text was not stored: the
  // transcript keeps the signature and drops the text, so those bytes are
  // missing from `content` and every share is an upper bound.
  let thinkingBlocks = 0;

  for (const rec of records) {
    if (rec.type === 'attachment') {
      totals.attachments += bytes(rec.attachment);
      continue;
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
          classifyToolUse(block, totals, toolNameById);
        }
      }
      continue;
    }

    if (rec.type === 'user') {
      const content = (rec.message || {}).content;
      if (!Array.isArray(content)) {
        totals['user-messages'] += bytes(content);
        continue;
      }
      for (const block of content) {
        if (block.type === 'tool_result') {
          const tool = toolNameById.get(block.tool_use_id);
          const size = bytes(block.content);
          if (tool === 'Read') totals['read-results'] += size;
          else if (tool === 'Bash') totals['bash-results'] += size;
          else if (AGENT_TOOLS.has(tool)) totals['agent-reports'] += size;
          else totals['other-results'] += size;
        } else if (block.type === 'text') {
          totals['user-messages'] += bytes(block.text);
        }
      }
    }
  }

  const content = CLASSES.reduce((sum, c) => sum + totals[c], 0);
  const promptMaterial = PROMPT_MATERIAL.reduce((sum, c) => sum + totals[c], 0);
  const peakTokens = requests.size ? Math.max(...requests.values()) : 0;

  return {
    totals,
    content,
    promptMaterial,
    promptMaterialPercent: content ? (promptMaterial * 100) / content : 0,
    peakTokens,
    assistantRecords,
    distinctRequests: requests.size,
    thinkingBlocks,
    thinkingTextStored: totals.thinking > 0,
  };
}

function classifyToolUse(block, totals, toolNameById) {
  const name = block.name;
  const input = block.input || {};
  toolNameById.set(block.id, name);

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

function kb(n) {
  return `${(n / 1024).toFixed(1)} KB`;
}

function report(file, m) {
  const rows = CLASSES
    .map((c) => [c, m.totals[c]])
    .filter(([, v]) => v > 0)
    .sort((a, b) => b[1] - a[1]);
  const width = Math.max(...rows.map(([c]) => c.length), 'prompt material'.length);

  console.log(`Transcript: ${file}`);
  console.log(`Assistant records: ${m.assistantRecords}  ` +
    `distinct requests: ${m.distinctRequests}  ` +
    `(deduplicated on requestId)`);
  console.log(`Peak context: ${m.peakTokens.toLocaleString('en-US')} tokens ` +
    `(a maximum over requests, never a sum)`);
  console.log(`Content: ${kb(m.content)}`);
  console.log('');
  for (const [name, value] of rows) {
    const pct = ((value * 100) / m.content).toFixed(1);
    console.log(`  ${name.padEnd(width)}  ${kb(value).padStart(9)}  ${pct.padStart(5)}%`);
  }
  console.log('');
  console.log(`  ${'prompt material'.padEnd(width)}  ` +
    `${kb(m.promptMaterial).padStart(9)}  ` +
    `${m.promptMaterialPercent.toFixed(1).padStart(5)}%  ` +
    `(${PROMPT_MATERIAL.join(' + ')})`);

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
