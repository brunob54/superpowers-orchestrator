#!/usr/bin/env node
// Count the reviewer report fields of one review run.
//
// Written for the acceptance measure of release 7.75.0 (spec
// docs/superpowers-orchestrator/2026-10-24-reviewer-evidence-and-inputs-read/
// specs/reviewer-evidence-and-inputs-read-design.md, section 9): every
// reviewer report carries an `### Inputs read` section, and every Critical
// and Important finding carries an `evidence:` line directly below it.
//
// Usage: node tools/count-report-fields.js <subagents-dir> <review-log>
//
// <subagents-dir> is the `subagents/` folder of one session
// (~/.claude/projects/<project>/<session>/subagents/). It holds one `.jsonl`
// transcript per subagent of the session — reviewers, fix subagents,
// controllers and others — and a `.meta.json` file next to most of them.
// <review-log> is the review log of the same run.
//
// A transcript is a reviewer transcript when its prompt holds the lens
// heading of the two reviewer templates. The prompt is the first user
// message. When that message is the pointer of a dispatch by pointer ("Your
// complete instructions are in the file <path>."), the prompt also includes
// the Read results of that file, because the reviewer receives its
// instructions there and not in its first message (multi-code-review
// dispatches every reviewer by pointer). The spec's definition names the
// first user message only; that definition finds no pointer-dispatched
// reviewer.
//
// One report is taken per transcript: the `message` input of the last
// SubagentHandback tool call, else the last assistant text block. A copy of
// the report in a Write tool input is never counted.
//
// Exit codes: 0 counted; 2 usage error (an argument missing, or the folder or
// the log cannot be read).

'use strict';

const fs = require('fs');
const path = require('path');

const USAGE = 'usage: node tools/count-report-fields.js <subagents-dir> <review-log>';
const EXIT_USAGE = 2;
const TRANSCRIPT_EXT = '.jsonl';
const META_EXT = '.meta.json';
const LENS_HEADING = '## Lens (your ONLY focus in this review)';
const POINTER_RE = /Your complete instructions are in the file (\S+?)\.(?:\s|$)/;
// A Read result prefixes each line with its line number and a tab.
const READ_LINE_PREFIX_RE = /^\s*\d+\t/;
const MARKER = '<!-- multi-review report -->';
const MARKER_WINDOW = 10;
const HANDBACK_TOOL = 'SubagentHandback';
const READ_TOOL = 'Read';
const HEADING_RE = /^#{1,6} /;
const CI_HEADINGS = ['#### Critical', '#### Important'];
const ID_LINE_RE = /^- \[[A-Z]+[0-9]+\]/;
const EVIDENCE_PREFIX = 'evidence: ';
const SECRET_FORM_RE = /^evidence: [0-9]+ — secret-bearing line, not quoted$/;
const INPUTS_HEADING = '### Inputs read';
// One unread range: `<a>-<b>` or `<a>-end`, optionally followed by the diff
// paths it covers in parentheses.
const RANGE = '[0-9]+-(?:[0-9]+|end)(?: \\([^()]+\\))?';
// Each input of the expected set, with the prompt sentence that names it.
const INPUTS = [
  { name: 'diff', needle: 'Read the diff file whole' },
  { name: 'plan', needle: 'Plan/requirements the branch implements (read it first):' },
  { name: 'document', needle: 'Document (read it whole' },
  { name: 'spec', needle: 'read the spec listed under Target' },
];
const INPUT_LINE_RE = new RegExp(
  '^- (' + INPUTS.map((input) => input.name).join('|') + '): (?:whole|partial — not read: (?:unknown|' + RANGE + '(?:, ' + RANGE + ')*))$'
);
const DISPOSITION_PREFIX = '- [';
const REJECTED_EVIDENCE = 'rejected: evidence (';
const CRITICAL_NOTE = '(evidence: ';

function usage(detail) {
  process.stderr.write((detail ? detail + '\n' : '') + USAGE + '\n');
  process.exit(EXIT_USAGE);
}

function readRecords(file) {
  const records = [];
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (!line.trim()) continue;
    try {
      records.push(JSON.parse(line));
    } catch (e) {
      // The last line of a transcript that was still being written can be
      // cut; it holds no complete record, so it is skipped.
    }
  }
  return records;
}

function blocks(record) {
  const content = record && record.message && record.message.content;
  if (typeof content === 'string') return [{ type: 'text', text: content }];
  return Array.isArray(content) ? content : [];
}

function resultText(block) {
  const content = block.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) return content.filter((b) => b && b.type === 'text').map((b) => b.text).join('\n');
  return '';
}

function stripReadPrefixes(text) {
  return text.split('\n').map((line) => line.replace(READ_LINE_PREFIX_RE, '')).join('\n');
}

// The prompt of a transcript with every run of whitespace folded to one
// space, so that a sentence wrapped across a line break still matches.
function promptText(records) {
  const first = records.find((r) => r.type === 'user' && blocks(r).some((b) => b.type === 'text'));
  if (!first) return '';
  const parts = blocks(first).filter((b) => b.type === 'text').map((b) => b.text);
  const pointer = parts.join('\n').match(POINTER_RE);
  if (pointer) {
    const readIds = new Set();
    for (const r of records) {
      if (r.type !== 'assistant') continue;
      for (const b of blocks(r)) {
        if (b.type === 'tool_use' && b.name === READ_TOOL && b.input && b.input.file_path === pointer[1]) readIds.add(b.id);
      }
    }
    for (const r of records) {
      if (r.type !== 'user') continue;
      for (const b of blocks(r)) {
        if (b.type === 'tool_result' && readIds.has(b.tool_use_id)) parts.push(stripReadPrefixes(resultText(b)));
      }
    }
  }
  return parts.join('\n').replace(/\s+/g, ' ');
}

function takenReport(records) {
  let handback = null;
  let text = null;
  for (const r of records) {
    if (r.type !== 'assistant') continue;
    for (const b of blocks(r)) {
      if (b.type === 'tool_use' && b.name === HANDBACK_TOOL && b.input && typeof b.input.message === 'string') {
        handback = b.input.message;
      } else if (b.type === 'text' && typeof b.text === 'string') {
        text = b.text;
      }
    }
  }
  return handback !== null ? handback : text;
}

// The report's lines below its marker line, or null when no line among the
// first MARKER_WINDOW non-blank lines starts with the marker.
function reportBody(report) {
  if (typeof report !== 'string') return null;
  const lines = report.split('\n').map((line) => line.replace(/\s+$/, ''));
  let nonBlank = 0;
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    nonBlank += 1;
    if (nonBlank > MARKER_WINDOW) return null;
    if (lines[i].trim().startsWith(MARKER)) return lines.slice(i + 1);
  }
  return null;
}

function ciEvidence(lines) {
  let heading = '';
  let findings = 0;
  let withEvidence = 0;
  lines.forEach((line, i) => {
    if (HEADING_RE.test(line)) {
      heading = line.trim();
      return;
    }
    if (!CI_HEADINGS.includes(heading) || !ID_LINE_RE.test(line)) return;
    findings += 1;
    const next = lines.slice(i + 1).find((l) => l.trim() !== '');
    if (next !== undefined && next.trim().startsWith(EVIDENCE_PREFIX)) withEvidence += 1;
  });
  return { findings, withEvidence };
}

function declaredInputs(lines) {
  const declared = new Set();
  const start = lines.findIndex((line) => line.trim() === INPUTS_HEADING);
  if (start < 0) return declared;
  for (const line of lines.slice(start + 1)) {
    if (HEADING_RE.test(line)) break;
    const match = line.match(INPUT_LINE_RE);
    if (match) declared.add(match[1]);
  }
  return declared;
}

function description(file) {
  const meta = file.slice(0, -TRANSCRIPT_EXT.length) + META_EXT;
  try {
    const text = JSON.parse(fs.readFileSync(meta, 'utf8')).description;
    return typeof text === 'string' ? ' — ' + text : '';
  } catch (e) {
    return '';
  }
}

function main(argv) {
  if (argv.length !== 2) usage();
  const [dir, log] = argv;
  let names;
  let logText;
  try {
    names = fs.readdirSync(dir).filter((name) => name.endsWith(TRANSCRIPT_EXT)).sort();
    logText = fs.readFileSync(log, 'utf8');
  } catch (e) {
    usage(e.message);
  }
  const count = { transcripts: 0, other: 0, reports: 0, withInputs: 0, ci: 0, evidence: 0, secret: 0 };
  const perInput = {};
  INPUTS.forEach((input) => { perInput[input.name] = { valid: 0, expected: 0 }; });
  const noReport = [];
  for (const name of names) {
    const file = path.join(dir, name);
    const records = readRecords(file);
    const prompt = promptText(records);
    if (!prompt.includes(LENS_HEADING)) {
      count.other += 1;
      continue;
    }
    count.transcripts += 1;
    const body = reportBody(takenReport(records));
    if (body === null) {
      noReport.push(file);
      continue;
    }
    count.reports += 1;
    const expected = INPUTS.filter((input) => prompt.includes(input.needle)).map((input) => input.name);
    const declared = declaredInputs(body);
    expected.forEach((inputName) => {
      perInput[inputName].expected += 1;
      if (declared.has(inputName)) perInput[inputName].valid += 1;
    });
    // A prompt that matches no needle has an empty expected set; `every` is
    // true on an empty set, so the report is counted only when the set is not
    // empty.
    if (expected.length > 0 && expected.every((inputName) => declared.has(inputName))) count.withInputs += 1;
    const fields = ciEvidence(body);
    count.ci += fields.findings;
    count.evidence += fields.withEvidence;
    count.secret += body.filter((line) => SECRET_FORM_RE.test(line.trim())).length;
  }
  const rejected = logText
    .split('\n')
    .filter((line) => line.startsWith(DISPOSITION_PREFIX) && (line.includes(REJECTED_EVIDENCE) || line.includes(CRITICAL_NOTE)))
    .length;
  console.log(
    `reviewer-transcripts: ${count.transcripts}  other: ${count.other}  reports: ${count.reports}  ` +
    `with-inputs-read: ${count.withInputs}  ci-findings: ${count.ci}  with-evidence: ${count.evidence}  ` +
    `secret-form-lines: ${count.secret}  rejected-evidence-lines: ${rejected}`
  );
  console.log('per-input: ' + INPUTS.map((input) => `${input.name} ${perInput[input.name].valid}/${perInput[input.name].expected}`).join('  '));
  noReport.forEach((file) => console.log(`no report: ${file}${description(file)}`));
}

main(process.argv.slice(2));
