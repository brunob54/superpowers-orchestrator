#!/usr/bin/env node
'use strict';
// session-start-assemble.js — builds the session-start hook's context under a
// character budget and prints it as the body of a JSON string.
//
// Why this is a Node script and not bash: Claude Code keeps a hook's
// additionalContext in the model's context only up to 10,000 characters
// (measured 2026-09-17, docs/orchestration-issues.md row 37). From 10,001 it
// writes the text to a file and keeps a 2,000-character preview. Bash's ${#var}
// counts bytes or code points depending on the locale, so a state.md full of
// emoji could pass a bash check and still exceed the limit (a character outside
// the Basic Multilingual Plane is one code point but two UTF-16 code units).
// Node measures every part in one unit and JSON.stringify escapes every control
// character, which a bash escaper missed (a form feed made the JSON invalid).
//
// Called by hooks/session-start with one argument: a directory that holds the
// parts as files, written by the hook:
//   header    the opening text up to and including the mandatory first actions
//   skill     the first part of skills/using-superpowers/SKILL.md
//   notices   the legacy-skills warning, the update notice and the git note
//   defaults  the <superpowers-defaults> block, always last in the output
//   name<i>, text<i>   workspace sections in priority order, i = 1, 2, ...
//
// The header, the skill part, the notices, the closing tag and the defaults
// block are always included. The workspace sections are added in priority
// order, each whole when it fits the remaining budget; the ones left out are
// named with their sizes in one <not-injected> line, whose room is charged only
// when at least one section is left out.
const fs = require('fs');
const path = require('path');

// The limit Claude Code applies; BUDGET keeps 100 characters of slack below it.
const LIMIT = 10000;
const BUDGET = 9900;
// The largest skill part the hook injects. tests/codex/test-session-start-budget.sh
// asserts the text above the marker is at most this long; the cut below only
// runs when the marker is missing from SKILL.md and the whole skill arrived.
const SKILL_MAX = 6400;
const CLOSING = '\n</EXTREMELY_IMPORTANT>';
const POINTER_OPEN = '\n\n<not-injected>Not injected, to keep this hook output under ' + LIMIT.toLocaleString("en-US") + ' characters: ';
const POINTER_CLOSE = '. Read the files with the Read tool when the task needs them.</not-injected>';

const dir = process.argv[2];
if (!dir) {
  process.stderr.write('usage: session-start-assemble.js <parts directory>\n');
  process.exit(2);
}

function readPart(name) {
  try {
    return fs.readFileSync(path.join(dir, name), 'utf8');
  } catch (e) {
    return '';
  }
}

// The measured limit was found with ASCII text, so whether Claude Code counts
// UTF-16 code units or UTF-8 bytes is unknown; the larger of the two is used,
// which is safe under both readings.
function size(text) {
  return Math.max(text.length, Buffer.byteLength(text, 'utf8'));
}

let skill = readPart('skill');
if (skill.length > SKILL_MAX) {
  skill = skill.slice(0, SKILL_MAX) +
    '\n[using-superpowers text cut at ' + SKILL_MAX +
    ' characters: the session-start-injection-ends marker is missing from its SKILL.md]';
}
const head = readPart('header') + '\n\n' + skill + readPart('notices') + CLOSING;
const defaults = readPart('defaults');

const sections = [];
for (let i = 1; fs.existsSync(path.join(dir, 'name' + i)); i++) {
  sections.push({ name: readPart('name' + i), text: readPart('text' + i) });
}

// pack(reserve): adds the sections in order while they fit the budget minus
// the reserve, and returns the added text and the entries left out.
function pack(reserve) {
  let remaining = BUDGET - size(head) - size(defaults) - reserve;
  let body = '';
  const skipped = [];
  for (const section of sections) {
    if (!section.text) continue;
    const n = size(section.text);
    if (n <= remaining) {
      body += section.text;
      remaining -= n;
    } else {
      skipped.push(section.name + ' (' + n + ' characters)');
    }
  }
  return { body, skipped };
}

// The pointer line's size depends on which sections are left out, and the
// room reserved for it decides which sections are left out. Repeating pack()
// with the last pointer's size as the reserve grows the reserve until it
// covers the pointer; it ends within sections.length + 1 rounds because a
// larger reserve can only add entries.
let reserve = 0;
let packed = pack(reserve);
let pointer = '';
for (let round = 0; round <= sections.length; round++) {
  packed = pack(reserve);
  pointer = packed.skipped.length ? POINTER_OPEN + packed.skipped.join(', ') + POINTER_CLOSE : '';
  if (size(pointer) <= reserve) break;
  reserve = size(pointer);
}

const context = head + packed.body + pointer + defaults;
process.stdout.write(JSON.stringify(context).slice(1, -1));
