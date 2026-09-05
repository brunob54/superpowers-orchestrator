'use strict';
// fill-prompt.js — fill a prompt template into a file.
//
// Usage:
//   node fill-prompt.js --template <path> --out <path> [NAME=<value> | NAME=@<file>]...
//
// The template has the shape of reviewer-prompt.md: prose, one fenced code
// block holding an Agent call with a `prompt: |` line, then more prose (the
// placeholder legend). Only the prompt body — the lines after `prompt: |` up
// to the closing fence — is filled and written, with the indentation of its
// first non-empty line removed from every line.
//
// A placeholder is `[NAME]` where NAME is uppercase letters and underscores,
// at least two characters. `NAME=<value>` gives the value inline;
// `NAME=@<file>` reads it from a file (one trailing newline removed). An
// empty value on a line whose only non-blank content is the placeholder
// removes the whole line.
//
// A value whose text is untrusted (reviewer findings, lens text, failure
// text) must always be passed in the `NAME=@<file>` form, written by the
// caller to a file, never inline. An inline value that begins with `@` is
// always read as a file reference — there is no escape for it — so the
// caller is responsible for keeping untrusted text out of the inline form.
//
// Exit codes: 0 written; 1 usage error; 2 malformed template; 3 a body
// placeholder has no value; 4 a NAME= names no placeholder in the body or
// the wrapper (the fenced block's lines above and including `prompt: |`);
// 5 a file could not be read or written, including when `--out` already
// exists. Nothing is printed on success.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const EXIT_USAGE = 1;
const EXIT_TEMPLATE = 2;
const EXIT_UNCOVERED = 3;
const EXIT_UNKNOWN_NAME = 4;
const EXIT_IO = 5;

const USAGE =
  'usage: node fill-prompt.js --template <path> --out <path> [NAME=<value> | NAME=@<file>]...';
const NAME_PATTERN = '[A-Z][A-Z_]*[A-Z]';
const NAME_RE = new RegExp('^' + NAME_PATTERN + '$');
const PLACEHOLDER_RE = new RegExp('\\[(' + NAME_PATTERN + ')\\]', 'g');
const WHOLE_LINE_RE = new RegExp('^\\s*\\[(' + NAME_PATTERN + ')\\]\\s*$');
const PROMPT_OPEN_RE = /^\s*prompt: \|\s*$/;
const FENCE_RE = /^```/;
const LINE_SPLIT_RE = /\r?\n/;
const OPTION_PREFIX = '--';
const OPTION_TEMPLATE = 'template';
const OPTION_OUT = 'out';
const FILE_REF_PREFIX = '@';
const CRLF = '\r\n';
const LF = '\n';
const MALFORMED = 'malformed template: ';

function fail(code, message) {
  // Write directly to the file descriptor, synchronously, so the message is
  // never lost when standard error is a pipe (an asynchronous write could
  // otherwise be cut short by the immediately following process exit).
  fs.writeSync(2, message + LF);
  process.exit(code);
}

function parseArgs(argv) {
  const opts = { [OPTION_TEMPLATE]: null, [OPTION_OUT]: null, values: [] };
  // Repeated names are a usage error and are caught here, before any file is
  // read, so a usage error always exits 1 whatever the template contains.
  const seen = new Set();
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === OPTION_PREFIX + OPTION_TEMPLATE || arg === OPTION_PREFIX + OPTION_OUT) {
      const key = arg.slice(OPTION_PREFIX.length);
      if (opts[key] !== null || i + 1 >= argv.length) fail(EXIT_USAGE, USAGE);
      i += 1;
      opts[key] = argv[i];
      continue;
    }
    const eq = arg.indexOf('=');
    const name = arg.slice(0, eq);
    if (eq < 0 || !NAME_RE.test(name) || seen.has(name)) fail(EXIT_USAGE, USAGE);
    seen.add(name);
    opts.values.push({ name, raw: arg.slice(eq + 1) });
  }
  if (opts[OPTION_TEMPLATE] === null || opts[OPTION_OUT] === null) fail(EXIT_USAGE, USAGE);
  return opts;
}

function readText(file, what) {
  try {
    return fs.readFileSync(file, 'utf8');
  } catch (err) {
    return fail(EXIT_IO, `cannot read ${what} ${file}: ${err.message}`);
  }
}

// Split the template lines into the wrapper (inside the first fence, above
// and including `prompt: |`) and the body (below it, up to the closing fence).
function extract(lines) {
  const open = lines.findIndex((line) => FENCE_RE.test(line));
  if (open < 0) fail(EXIT_TEMPLATE, MALFORMED + 'no fenced code block');
  let close = -1;
  for (let i = open + 1; i < lines.length; i++) {
    if (FENCE_RE.test(lines[i])) { close = i; break; }
  }
  if (close < 0) fail(EXIT_TEMPLATE, MALFORMED + 'the first fenced block is not closed');
  // A fenced example written at column 0 inside the prompt body would be
  // taken as the closing fence and would silently truncate the body. After a
  // real closing fence the template continues with prose at column 0, so an
  // indented first non-blank line after the chosen fence means the fence was
  // inside the body.
  for (let i = close + 1; i < lines.length; i++) {
    if (isBlank(lines[i])) continue;
    if (/^[ \t]/.test(lines[i])) {
      fail(EXIT_TEMPLATE, MALFORMED + 'the first fenced block closes inside the prompt body');
    }
    break;
  }
  let promptLine = -1;
  for (let i = open + 1; i < close; i++) {
    if (PROMPT_OPEN_RE.test(lines[i])) { promptLine = i; break; }
  }
  if (promptLine < 0) fail(EXIT_TEMPLATE, MALFORMED + 'no `prompt: |` line inside the first fenced block');
  // `bodyStart` is the 1-based line number, in the template file, of the
  // first body line — so an error message can name a line of the file the
  // controller can open, not an offset inside the body.
  return {
    wrapper: lines.slice(open + 1, promptLine + 1),
    body: lines.slice(promptLine + 1, close),
    bodyStart: promptLine + 2,
  };
}

function isBlank(line) {
  return line.trim() === '';
}

// Remove the indentation of the first non-empty body line from every body
// line. A whitespace-only line becomes an empty line. A non-empty line that
// does not start with that exact indentation is a malformed template.
// `bodyStart` is the 1-based template-file line number of the first body
// line, used only to report the failing line by its number in the file.
function dedent(body, bodyStart) {
  const first = body.find((line) => !isBlank(line));
  if (first === undefined) fail(EXIT_TEMPLATE, MALFORMED + 'the prompt body is empty');
  const indent = first.match(/^[ \t]*/)[0];
  return body.map((line, index) => {
    if (isBlank(line)) return '';
    if (!line.startsWith(indent)) {
      fail(EXIT_TEMPLATE, MALFORMED + `template line ${bodyStart + index} is not indented at least as far as the first body line`);
    }
    return line.slice(indent.length);
  });
}

// Drop trailing blank lines from the filled body, so the written output
// always ends with exactly one newline even when a blank line precedes the
// closing fence, or when the last body line is a whole-line placeholder
// that `fill` removed because its value is empty (which leaves a blank
// line, that preceded the placeholder, as the new last line). This must run
// AFTER `fill`, not before it, so it sees the line removal `fill` performs.
function dropTrailingBlank(lines) {
  const out = lines.slice();
  while (out.length > 0 && out[out.length - 1] === '') out.pop();
  return out;
}

// Resolve `NAME=@<file>` references; strip exactly one trailing newline from
// file content so a file written by the Write tool or a heredoc inserts
// without an extra line break.
function resolveValues(entries) {
  const values = new Map();
  for (const entry of entries) {
    let value = entry.raw;
    if (value.startsWith(FILE_REF_PREFIX)) {
      value = readText(value.slice(FILE_REF_PREFIX.length), 'value file');
      if (value.endsWith(CRLF)) value = value.slice(0, -CRLF.length);
      else if (value.endsWith(LF)) value = value.slice(0, -LF.length);
    }
    values.set(entry.name, value);
  }
  return values;
}

function placeholderNames(lines) {
  const names = new Set();
  for (const line of lines) {
    for (const match of line.matchAll(PLACEHOLDER_RE)) names.add(match[1]);
  }
  return names;
}

// Exit 3 for a body placeholder without a value; exit 4 for a value whose
// name appears neither in the body nor in the wrapper. The prose outside the
// fence is never scanned.
function checkCoverage(body, wrapper, values) {
  const inBody = placeholderNames(body);
  const inWrapper = placeholderNames(wrapper);
  for (const name of inBody) {
    if (!values.has(name)) fail(EXIT_UNCOVERED, `placeholder [${name}] has no ${name}= argument`);
  }
  for (const name of values.keys()) {
    if (!inBody.has(name) && !inWrapper.has(name)) {
      fail(EXIT_UNKNOWN_NAME, `argument ${name}= names a placeholder that appears nowhere in the template body or wrapper`);
    }
  }
}

// One pass per line. The replacer is a function, so `$` sequences inside a
// value are never interpreted as replacement patterns, and bracketed text
// inside a value is never substituted again.
function fill(body, values) {
  const out = [];
  for (const line of body) {
    const whole = line.match(WHOLE_LINE_RE);
    if (whole && values.get(whole[1]) === '') continue;
    out.push(line.replace(PLACEHOLDER_RE, (match, name) => values.get(name)));
  }
  return out;
}

// Write to a temporary name in the output's directory, then rename, so a
// partial file never passes `test -s`. When `outPath` already exists, the
// rule is: exit 0 without writing anything if its content is byte-identical
// to the text this run would write — the same fill was already completed,
// for example when the caller lost the result of the first run and repeated
// the command, and the file stays written once and never rewritten —
// otherwise exit 5 before any write, so a prompt file is never silently
// replaced by a different fill. The temporary name carries a random
// component in addition to the process id so it cannot be predicted, and
// 'wx' opens with O_EXCL: a pre-existing file or symlink at that name makes
// the write fail instead of writing through it.
function writeAtomic(outPath, text) {
  if (fs.existsSync(outPath)) {
    let existing = null;
    try {
      existing = fs.readFileSync(outPath);
    } catch (err) {
      // Unreadable, or not a regular file: treat it as different content.
      existing = null;
    }
    if (existing !== null && existing.equals(Buffer.from(text, 'utf8'))) {
      return;
    }
    fail(EXIT_IO, `cannot write ${outPath}: file already exists`);
  }
  const random = crypto.randomBytes(6).toString('hex');
  const tmp = path.join(path.dirname(outPath), `.${path.basename(outPath)}.${process.pid}.${random}.tmp`);
  // Set only once the 'wx' open below has actually created the temporary
  // file, so the catch block never unlinks a pre-existing file or symlink
  // at that name that caused the open itself to fail.
  let created = false;
  try {
    fs.writeFileSync(tmp, text, { encoding: 'utf8', flag: 'wx', mode: 0o600 });
    created = true;
    fs.renameSync(tmp, outPath);
  } catch (err) {
    if (created) {
      try { fs.unlinkSync(tmp); } catch (ignored) { /* already gone, e.g. renamed */ }
    }
    fail(EXIT_IO, `cannot write ${outPath}: ${err.message}`);
  }
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const text = readText(opts[OPTION_TEMPLATE], 'template');
  // Split on either line ending so a template with mixed line endings never
  // yields a line that still contains a newline character; the end-of-line
  // detected here is used only when joining the output back together.
  const eol = text.includes(CRLF) ? CRLF : LF;
  const { wrapper, body, bodyStart } = extract(text.split(LINE_SPLIT_RE));
  const dedented = dedent(body, bodyStart);
  const values = resolveValues(opts.values);
  checkCoverage(dedented, wrapper, values);
  const filled = dropTrailingBlank(fill(dedented, values));
  writeAtomic(opts[OPTION_OUT], filled.join(eol) + eol);
}

main();
