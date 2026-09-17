#!/usr/bin/env node
'use strict';
// analyze-compaction.js — report what a Claude Code session did right after
// each context compaction.
//
// Usage: node tools/analyze-compaction.js <transcript.jsonl> [--after N]
//   N (default 30) = how many tool calls to list after each compaction.
//
// Terms used in this file:
// - Transcript: the file Claude Code writes for one session. It is a JSONL
//   file (JSON Lines): one JSON object per line.
// - Record: one line of the transcript, parsed as a JSON object. Its `type`
//   field says what it is: "user", "assistant", "system", "attachment", ...
// - Compaction: the moment Claude Code replaces the older part of the
//   conversation with a short summary, because the context window (the text
//   the model can see at once) is nearly full. Claude Code writes a "system"
//   record with subtype "compact_boundary", then a "user" record that holds
//   the summary text, then several "attachment" records that re-attach
//   material the summary dropped (skill bodies, hook outputs).
// - requestId: the identifier of one API call. One API response is written to
//   the transcript as several "assistant" records (one per content block),
//   each repeating the same requestId and usage figures. This script counts
//   each requestId once.
// - Re-attachment: after a compaction, Claude Code adds back a truncated copy
//   of each skill that was invoked before the compaction (attachment type
//   "invoked_skills"), and runs the "SessionStart:compact" hooks again
//   (attachment types "hook_success" and "hook_additional_context").
//
// The script supports a probe of a skill rule: after a compaction summary,
// before acting on the next subagent return, the session must run
// `grep -n '^## ' <path>/SKILL.md` and then Read the section it is executing
// with `offset` and `limit`.

const fs = require('fs');
const path = require('path');

const DEFAULT_AFTER = 30;
const SUMMARY_PREVIEW_CHARS = 200;
const BASH_COMMAND_MAX_CHARS = 140;
const MIN_ITEMS_BEFORE_AGENT_STOP = 3;
const SKILL_INJECTION_MARKER = 'Base directory for this skill';
const SKILL_BASE_DIRECTORY_PATTERN = /Base directory for this skill:\s*(\S+)/;
const PARTIAL_MARKER = 'PARTIAL';
const GREP_HEADINGS_PATTERNS = [`grep -n '^## '`, `grep -n "^## "`];
const RULING_LOG_BASENAMES = ['orchestration-log.md', 'open-decisions.md'];
const HEADING_PATTERN = /^## (RULING|STOPPED)\b.*$/gm;

// Re-attachment records are looked for in this many records after a
// compact_boundary record. Measured on a 10-compaction transcript
// (2026-09-16): the "SessionStart:compact" hook records sit 9 to 14 records
// after the boundary, so 12 was too small.
const REATTACHMENT_WINDOW_RECORDS = 16;
const ATTACHMENT_INVOKED_SKILLS = 'invoked_skills';
const ATTACHMENT_HOOK_SUCCESS = 'hook_success';
const ATTACHMENT_HOOK_ADDITIONAL_CONTEXT = 'hook_additional_context';
const PERSISTED_OUTPUT_MARKER = '<persisted-output>';
const PERSISTED_NOTE = 'persisted (preview only)';

const RECORD_TYPE_USER = 'user';
const RECORD_TYPE_ASSISTANT = 'assistant';
const RECORD_TYPE_SYSTEM = 'system';
const RECORD_TYPE_ATTACHMENT = 'attachment';
const SUBTYPE_COMPACT_BOUNDARY = 'compact_boundary';

const TOOL_BASH = 'Bash';
const TOOL_READ = 'Read';
const TOOL_EDIT = 'Edit';
const TOOL_WRITE = 'Write';
const TOOL_AGENT = 'Agent';
const TOOL_SKILL = 'Skill';

function parseArgs(argv) {
  let file = null;
  let after = DEFAULT_AFTER;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--after') {
      after = parseInt(argv[++i], 10);
      if (!Number.isFinite(after) || after < 1) {
        fail('--after needs a positive integer');
      }
    } else if (file === null) {
      file = argv[i];
    } else {
      fail(`unexpected argument: ${argv[i]}`);
    }
  }
  if (file === null) fail('usage: node tools/analyze-compaction.js <transcript.jsonl> [--after N]');
  return { file, after };
}

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

function readRecords(file) {
  const text = fs.readFileSync(file, 'utf8');
  const records = [];
  text.split('\n').forEach((line, lineIndex) => {
    if (!line.trim()) return;
    try {
      records.push({ index: lineIndex, rec: JSON.parse(line) });
    } catch (err) {
      process.stderr.write(`line ${lineIndex}: JSON that cannot be parsed, skipped\n`);
    }
  });
  return records;
}

// Collect all text of a message content (a string, or an array of blocks).
function contentText(content) {
  if (typeof content === 'string') return content;
  if (!Array.isArray(content)) return '';
  return content
    .map((block) => {
      if (typeof block === 'string') return block;
      if (block && typeof block.text === 'string') return block.text;
      if (block && block.type === 'tool_result') return contentText(block.content);
      return '';
    })
    .join('\n');
}

function messageContent(rec) {
  return rec.message && rec.message.content;
}

function contentBlocks(rec) {
  const content = messageContent(rec);
  return Array.isArray(content) ? content : [];
}

function timeOfDay(timestamp) {
  if (typeof timestamp !== 'string') return '--:--:--';
  const match = timestamp.match(/T(\d\d:\d\d:\d\d)/);
  return match ? match[1] : timestamp;
}

function shortPath(filePath) {
  if (typeof filePath !== 'string') return '?';
  return path.join(path.basename(path.dirname(filePath)), path.basename(filePath));
}

function trimCommand(command) {
  const oneLine = String(command).replace(/\r?\n/g, '\\n');
  return oneLine.length > BASH_COMMAND_MAX_CHARS
    ? oneLine.slice(0, BASH_COMMAND_MAX_CHARS) + '…'
    : oneLine;
}

function baseName(filePath) {
  return typeof filePath === 'string' ? path.basename(filePath) : '?';
}

// The base directory of a re-attached skill is read from the first line of
// its content ("Base directory for this skill: <dir>"); the `path` field of
// the attachment is a plugin identifier, not a filesystem path.
function skillBaseDirectoryName(skill) {
  const match = String(skill.content || '').match(SKILL_BASE_DIRECTORY_PATTERN);
  return match ? path.basename(match[1]) : String(skill.name || '?');
}

function describeReattachment(rec) {
  const attachment = rec.attachment || {};
  if (attachment.type === ATTACHMENT_INVOKED_SKILLS) {
    const skills = Array.isArray(attachment.skills) ? attachment.skills : [];
    return {
      kind: ATTACHMENT_INVOKED_SKILLS,
      skills: skills.map((skill) => ({
        name: skillBaseDirectoryName(skill),
        chars: String(skill.content || '').length,
      })),
    };
  }
  if (attachment.type === ATTACHMENT_HOOK_SUCCESS) {
    return {
      kind: ATTACHMENT_HOOK_SUCCESS,
      hookName: String(attachment.hookName || '?'),
      stdoutChars: String(attachment.stdout || '').length,
    };
  }
  if (attachment.type === ATTACHMENT_HOOK_ADDITIONAL_CONTEXT) {
    const parts = Array.isArray(attachment.content) ? attachment.content : [attachment.content];
    const text = parts.map((part) => String(part || '')).join('');
    return {
      kind: ATTACHMENT_HOOK_ADDITIONAL_CONTEXT,
      chars: text.length,
      persisted: text.includes(PERSISTED_OUTPUT_MARKER),
    };
  }
  return null;
}

// ---- pass 1: walk records, collect tool calls, API calls, compactions -----

function analyze(records) {
  const apiCalls = []; // deduplicated on requestId, in order of first appearance
  const apiCallByRequestId = new Map();
  const toolCalls = []; // every tool_use block, in record order
  const resultTextByToolUseId = new Map();
  const compactions = [];
  const skillInjections = [];
  const headings = [];
  let toolUseCount = 0;
  let invokedSkillsAttachmentCount = 0;

  for (const { index, rec } of records) {
    if (rec.type === RECORD_TYPE_SYSTEM && rec.subtype === SUBTYPE_COMPACT_BOUNDARY) {
      compactions.push({
        index,
        timestamp: rec.timestamp,
        meta: rec.compactMetadata || {},
        summaryIndex: null,
        summaryText: '',
        reattachments: [],
      });
      continue;
    }

    if (rec.type === RECORD_TYPE_ATTACHMENT) {
      const attachmentType = rec.attachment && rec.attachment.type;
      if (attachmentType === ATTACHMENT_INVOKED_SKILLS) invokedSkillsAttachmentCount++;
      const last = compactions[compactions.length - 1];
      if (last && index - last.index <= REATTACHMENT_WINDOW_RECORDS) {
        const described = describeReattachment(rec);
        if (described) last.reattachments.push({ index, ...described });
      }
      continue;
    }

    if (rec.type === RECORD_TYPE_USER) {
      const text = contentText(messageContent(rec));
      if (rec.isCompactSummary) {
        const last = compactions[compactions.length - 1];
        if (last && last.summaryIndex === null) {
          last.summaryIndex = index;
          last.summaryText = text;
        } else {
          // A summary without a preceding boundary record: treat it as its own compaction.
          compactions.push({
            index,
            timestamp: rec.timestamp,
            meta: {},
            summaryIndex: index,
            summaryText: text,
            reattachments: [],
          });
        }
      }
      if (text.includes(SKILL_INJECTION_MARKER)) {
        skillInjections.push({ index, bytes: Buffer.byteLength(text, 'utf8') });
      }
      for (const block of contentBlocks(rec)) {
        if (block && block.type === 'tool_result' && block.tool_use_id) {
          resultTextByToolUseId.set(block.tool_use_id, contentText(block.content));
        }
      }
      continue;
    }

    if (rec.type === RECORD_TYPE_ASSISTANT) {
      const requestId = rec.requestId || `no-requestId@${index}`;
      let call = apiCallByRequestId.get(requestId);
      if (!call) {
        const usage = (rec.message && rec.message.usage) || {};
        call = {
          callIndex: apiCalls.length + 1,
          recordIndex: index,
          timestamp: rec.timestamp,
          context:
            (usage.input_tokens || 0) +
            (usage.cache_read_input_tokens || 0) +
            (usage.cache_creation_input_tokens || 0),
          tools: new Map(),
        };
        apiCallByRequestId.set(requestId, call);
        apiCalls.push(call);
      }
      for (const block of contentBlocks(rec)) {
        if (!block || block.type !== 'tool_use') continue;
        toolUseCount++;
        call.tools.set(block.name, (call.tools.get(block.name) || 0) + 1);
        const input = block.input || {};
        toolCalls.push({ index, name: block.name, input, id: block.id });
        const written = typeof input.new_string === 'string' ? input.new_string
          : typeof input.content === 'string' ? input.content : '';
        if (written && (block.name === TOOL_EDIT || block.name === TOOL_WRITE)) {
          for (const m of written.matchAll(HEADING_PATTERN)) {
            headings.push({ index, heading: m[0].trim() });
          }
        }
      }
    }
  }

  return {
    apiCalls,
    toolCalls,
    resultTextByToolUseId,
    compactions,
    skillInjections,
    headings,
    toolUseCount,
    invokedSkillsAttachmentCount,
  };
}

// ---- formatting -----------------------------------------------------------

function describeToolCall(call, resultTextByToolUseId) {
  const { name, input } = call;
  let detail = '';
  let mark = '';
  if (name === TOOL_BASH) {
    const command = String(input.command || '');
    detail = trimCommand(command);
    if (GREP_HEADINGS_PATTERNS.some((p) => command.includes(p))) mark = ` <-- grep '^## '`;
  } else if (name === TOOL_READ) {
    detail = shortPath(input.file_path);
    const range = [];
    if (input.offset !== undefined) range.push(`offset=${input.offset}`);
    if (input.limit !== undefined) range.push(`limit=${input.limit}`);
    if (range.length) detail += ` (${range.join(', ')})`;
    const result = resultTextByToolUseId.get(call.id);
    if (result && result.includes(PARTIAL_MARKER)) mark = ' <-- PARTIAL';
  } else if (name === TOOL_EDIT || name === TOOL_WRITE) {
    const base = baseName(input.file_path);
    detail = base;
    if (RULING_LOG_BASENAMES.some((suffix) => base.endsWith(suffix))) mark = ' <-- ruling/log write';
  } else if (name === TOOL_AGENT) {
    detail = `${input.name || '(unnamed)'} — ${input.description || ''}`;
  } else if (name === TOOL_SKILL) {
    detail = String(input.skill || '');
  }
  return `${name}${detail ? ' ' + detail : ''}${mark}`;
}

function formatToolList(toolsMap) {
  const tools = [...toolsMap.entries()].map(([name, count]) => `${name}${count > 1 ? `×${count}` : ''}`);
  return tools.join(',') || '-';
}

function formatReattachments(reattachments) {
  const lines = [];
  const skillsAttachments = reattachments.filter((r) => r.kind === ATTACHMENT_INVOKED_SKILLS);
  const skillEntries = skillsAttachments.flatMap((r) => r.skills);
  const skillList = skillEntries.map((s) => `${s.name} ${s.chars} chars`).join('; ');
  lines.push(`re-attached invoked_skills: ${skillsAttachments.length}${skillList ? ` (${skillList})` : ''}`);

  const hooks = reattachments.filter((r) => r.kind === ATTACHMENT_HOOK_SUCCESS);
  const hookList = hooks.map((h) => `${h.hookName} stdout ${h.stdoutChars} chars`).join('; ');
  lines.push(`re-attached hook_success: ${hooks.length}${hookList ? ` (${hookList})` : ''}`);

  const contexts = reattachments.filter((r) => r.kind === ATTACHMENT_HOOK_ADDITIONAL_CONTEXT);
  const totalChars = contexts.reduce((sum, c) => sum + c.chars, 0);
  const persisted = contexts.some((c) => c.persisted);
  lines.push(
    `re-attached hook_additional_context: ${contexts.length}${contexts.length ? ` (${totalChars} chars total${persisted ? `, ${PERSISTED_NOTE}` : ''})` : ''}`
  );
  return lines;
}

function printReport(file, records, analysis, after) {
  const {
    apiCalls,
    toolCalls,
    resultTextByToolUseId,
    compactions,
    skillInjections,
    headings,
    toolUseCount,
    invokedSkillsAttachmentCount,
  } = analysis;
  const out = [];

  out.push(`file: ${file}`);
  out.push(`records: ${records.length}`);
  out.push(`distinct API calls (requestIds): ${apiCalls.length}`);
  out.push(`assistant tool_use blocks: ${toolUseCount}`);
  out.push(`compactions: ${compactions.length}`);
  const injectionSizes = skillInjections.map((s) => `record ${s.index}: ${s.bytes} bytes`).join('; ');
  out.push(`Skill injections: ${skillInjections.length}${injectionSizes ? ` (${injectionSizes})` : ''}`);
  out.push(`invoked_skills attachments in the whole file: ${invokedSkillsAttachmentCount}`);

  out.push('');
  // Mark the first API call after each compaction with "C": its context size is
  // the size of the window right after the summary was inserted.
  const firstCallAfterCompaction = new Set();
  for (const comp of compactions) {
    const first = apiCalls.find((call) => call.recordIndex > comp.index);
    if (first) firstCallAfterCompaction.add(first);
  }
  out.push('API calls (call, C = first call after a compaction, record, time, context, tools):');
  for (const call of apiCalls) {
    const mark = firstCallAfterCompaction.has(call) ? 'C' : ' ';
    out.push(
      `  ${String(call.callIndex).padStart(3)} ${mark}  rec ${String(call.recordIndex).padStart(4)}  ${timeOfDay(call.timestamp)}  ctx ${String(call.context).padStart(7)}  ${formatToolList(call.tools)}`
    );
  }

  for (let c = 0; c < compactions.length; c++) {
    const comp = compactions[c];
    const meta = comp.meta;
    out.push('');
    out.push(`=== compaction ${c + 1} of ${compactions.length} ===`);
    out.push(`record ${comp.index}  ${timeOfDay(comp.timestamp)}  trigger=${meta.trigger || '?'}  preTokens=${meta.preTokens ?? '?'}  postTokens=${meta.postTokens ?? '?'}`);
    const preview = comp.summaryText.replace(/\s+/g, ' ').slice(0, SUMMARY_PREVIEW_CHARS);
    out.push(`summary${comp.summaryIndex !== null ? ` (record ${comp.summaryIndex})` : ' (none found)'}: ${preview}`);
    out.push(...formatReattachments(comp.reattachments));
    const nextBoundary = c + 1 < compactions.length ? compactions[c + 1].index : Infinity;
    const nextCalls = toolCalls.filter((t) => t.index > comp.index && t.index < nextBoundary);
    const listed = [];
    let endedAtAgent = false;
    for (const call of nextCalls) {
      if (call.name === TOOL_AGENT && listed.length >= MIN_ITEMS_BEFORE_AGENT_STOP) {
        listed.push(call);
        endedAtAgent = true;
        break;
      }
      listed.push(call);
      if (listed.length >= after) break;
    }
    out.push(`next ${listed.length} tool call${listed.length === 1 ? '' : 's'}:`);
    listed.forEach((call, k) => {
      out.push(`  ${k + 1}. ${describeToolCall(call, resultTextByToolUseId)}`);
    });
    if (endedAtAgent) out.push('  (list ended at an Agent dispatch)');
    if (listed.length === 0) out.push('  (no tool calls after this compaction)');
  }

  out.push('');
  const headingList = headings.map((h) => `rec ${h.index}: ${h.heading}`).join('; ');
  out.push(`RULING/STOPPED headings written: ${headings.length}${headingList ? ` — ${headingList}` : ''}`);

  process.stdout.write(out.join('\n') + '\n');
}

function main() {
  const { file, after } = parseArgs(process.argv.slice(2));
  const records = readRecords(file);
  const analysis = analyze(records);
  printReport(file, records, analysis, after);
}

main();
