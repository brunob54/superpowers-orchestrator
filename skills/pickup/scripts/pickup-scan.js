#!/usr/bin/env node
// Prints the facts the /pickup skill needs, as "key: value" lines:
// - the git state of the current directory;
// - the newest handoff file (or the one named by the argument), its header,
//   the working tree, and the commits made after the handoff (its staleness);
// - without an argument, the unfinished orchestration runs found on local
//   feature branches that are not merged into the default branch.
// Usage: node pickup-scan.js [handoff-path]
// A path argument is looked up from the current directory, then from the
// repository top; tmp/docs and the branch files are read from the top. Every
// printed path is relative to the top.
// Exit status is 0 on every normal outcome; a status word carries the result.
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const DATE_PATTERN = '\\d{4}-\\d{2}-\\d{2}';
const HANDOFF_DIR = 'tmp/docs';
const HANDOFF_NAME = new RegExp(`^(${DATE_PATTERN})-handoff-.+\\.md$`);
const BYTE_ORDER_MARK = /^\uFEFF/;
const HEADER = /^Handoff: +written=(\S+) +branch=(\S+) +head=(\S+)/;
// written=<YYYY-MM-DD>T<HH:MM>, optionally followed by a time-zone offset
// such as +0200.
const WRITTEN = new RegExp(`^(${DATE_PATTERN})T(\\d{2}):(\\d{2})([+-]\\d{4})?$`);
const OFFSET_MINUTES = { min: -12 * 60, max: 14 * 60 };
const VALID_HEAD = /^[0-9a-f]{7,40}$/;
const DONE_WHEN = /^Done when: (.+)$/;
const DONE_WHEN_LINES = 5;
const NONE = 'none';
const NOT_LISTED = 'not-listed';
const GIT_OK = 'ok';
const GIT_NO_COMMITS = 'no-commits';
const LOG_ROOT = 'docs/superpowers-orchestrator';
// Files that /handoff itself writes after the handoff, and the work logs of
// skills/worklog, which the same sessions update; they are not work. This list
// covers the uncommitted-change check only: a commit made after the handoff
// still counts, also when it touches only docs/worklogs.
const NOT_WORK = [HANDOFF_DIR, 'state.md', 'session-log.md', 'docs/worklogs'];
const GIT_MAX_BUFFER = 256 * 1024 * 1024;
const FEATURE_PREFIX = 'feature/';
const HEADS = 'refs/heads/';
const COMPLETED = '_Completed — ';
const MAX_COMMITS = 30;
const STATUS = { fresh: 'FRESH', check: 'CHECK', unknown: 'UNKNOWN' };

function print(key, value) {
  console.log(`${key}: ${value}`);
}

function printList(items) {
  items.forEach((item) => console.log(`  ${item}`));
}

function lines(text) {
  return text ? text.split(/\r?\n/) : [];
}

// Runs git with an argument array (no shell) and colors off, whatever the
// user's configuration. Returns the exit state and the trimmed standard output.
function git(args) {
  const result = spawnSync('git', ['-c', 'color.ui=never', ...args], { encoding: 'utf8', maxBuffer: GIT_MAX_BUFFER });
  return { ok: result.status === 0, out: (result.stdout || '').trim() };
}

// The output lines of a git command, or null when the command failed.
function gitLines(args) {
  const result = git(args);
  return result.ok ? lines(result.out) : null;
}

function branchExists(name) {
  return git(['show-ref', '--verify', '--quiet', HEADS + name]).ok;
}

function localDate() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

// "ok", "none" (not a work tree, including a bare repository) or "no-commits".
function gitState() {
  const tree = git(['rev-parse', '--is-inside-work-tree']);
  if (!tree.ok || tree.out !== 'true') return NONE;
  if (!git(['rev-parse', '--verify', '--quiet', 'HEAD^{commit}']).ok) return GIT_NO_COMMITS;
  return GIT_OK;
}

// The local branch that origin/HEAD points to, else local main, else local
// master. Merge checks use this LOCAL branch, never origin/main: a branch
// merged locally but not pushed is merged.
function defaultBranch() {
  const remote = git(['symbolic-ref', '--quiet', 'refs/remotes/origin/HEAD']);
  const candidates = remote.ok ? [remote.out.replace(/^refs\/remotes\/origin\//, '')] : [];
  return candidates.concat(['main', 'master']).find(branchExists) || null;
}

function currentBranch() {
  const ref = git(['symbolic-ref', '--quiet', 'HEAD']);
  return ref.ok ? ref.out.slice(HEADS.length) : 'detached';
}

// A path relative to the repository top, with forward slashes.
function topPath(top, file) {
  return path.relative(top, file).split(path.sep).join('/');
}

// Parses a written= value. Returns null unless the date is a real calendar
// day, the time is 00:00-23:59 and the optional offset is -1200..+1400.
function parseWritten(value) {
  const match = value.match(WRITTEN);
  if (!match) return null;
  const [year, month, day] = match[1].split('-').map(Number);
  const calendar = new Date(Date.UTC(year, month - 1, day));
  const realDay = calendar.getUTCFullYear() === year
    && calendar.getUTCMonth() === month - 1
    && calendar.getUTCDate() === day;
  if (!realDay || Number(match[2]) > 23 || Number(match[3]) > 59) return null;
  const offset = match[4] || '';
  if (offset) {
    const minutes = Number(offset.slice(3, 5));
    const total = (offset[0] === '-' ? -1 : 1) * (Number(offset.slice(1, 3)) * 60 + minutes);
    if (minutes > 59 || total < OFFSET_MINUTES.min || total > OFFSET_MINUTES.max) return null;
  }
  return { date: match[1], time: `${match[2]}:${match[3]}`, offset };
}

// Reads a handoff file: the header fields of its first line (a byte-order
// mark is removed) and a "Done when:" line among the first non-empty lines.
// Returns null when the path is not a readable regular file.
function readHandoff(file) {
  let text;
  let mtime;
  try {
    const stat = fs.statSync(file);
    if (!stat.isFile()) return null;
    text = lines(fs.readFileSync(file, 'utf8').replace(BYTE_ORDER_MARK, ''));
    mtime = stat.mtimeMs;
  } catch (error) {
    return null;
  }
  const header = (text[0] || '').match(HEADER);
  const nameDate = path.basename(file).match(HANDOFF_NAME);
  const done = text.filter((line) => line.trim())
    .slice(0, DONE_WHEN_LINES)
    .map((line) => line.match(DONE_WHEN))
    .find(Boolean);
  return {
    file,
    header: header ? { written: header[1], branch: header[2], head: header[3] } : null,
    written: header ? parseWritten(header[1]) : null,
    nameDate: nameDate ? nameDate[1] : null,
    doneWhen: done ? done[1] : null,
    mtime,
  };
}

function handoffDate(handoff) {
  return handoff.written ? handoff.written.date : handoff.nameDate;
}

// The newest handoff in tmp/docs: ordered by a valid header "written=" value,
// then the file-name date, then the modification time. A file dated after
// today, and an entry that is not a readable file, are skipped.
function newestHandoff(top) {
  const dir = path.join(top, HANDOFF_DIR);
  let names;
  try {
    names = fs.readdirSync(dir);
  } catch (error) {
    return null;
  }
  const today = localDate();
  const key = (h) => (h.written ? `${h.written.date}T${h.written.time}` : h.nameDate);
  const found = names
    .filter((name) => HANDOFF_NAME.test(name))
    .map((name) => readHandoff(path.join(dir, name)))
    .filter((h) => h && h.nameDate <= today && handoffDate(h) <= today)
    .sort((a, b) => key(b).localeCompare(key(a))
      || b.nameDate.localeCompare(a.nameDate)
      || b.mtime - a.mtime);
  return found[0] || null;
}

// Prints the length of a commit list and at most MAX_COMMITS of its lines,
// oldest first, or "not-listed" when the list could not be produced.
function printCommits(key, list) {
  print(key, list ? list.length : NOT_LISTED);
  if (!list) return;
  if (list.length > MAX_COMMITS) print('commits-listed', MAX_COMMITS);
  printList(list.slice(0, MAX_COMMITS));
}

// The --since value of the window after the handoff, or null when no date is
// known. A bare --since=<date> means that date at the current time of day, so
// a date alone always gets 00:00.
function sinceValue(handoff, withTime) {
  const date = handoffDate(handoff);
  if (!date) return null;
  const written = handoff.written;
  const time = withTime && written ? written.time : '00:00';
  return `${date} ${time}${written && written.offset ? ` ${written.offset}` : ''}`;
}

// Prints the head check and two commit lists, and returns them.
// - self: the commits on HEAD after the handoff head, merges included and
//   whatever their date (HEAD moved, so they are new here). Without a head,
//   the commits on HEAD since 00:00 of the handoff date.
// - other: commits on other local branches, not on HEAD, made after the
//   handoff time (the file-name date at 00:00 when written= is not valid).
//   Each line names the first local ref that reaches it.
function reportCommits(handoff) {
  const head = handoff.header ? handoff.header.head : NONE;
  const headFound = VALID_HEAD.test(head) && git(['cat-file', '-e', `${head}^{commit}`]).ok;
  print('head', headFound ? head : 'not-found');
  const since = sinceValue(handoff, headFound);
  print('since', since || NONE);
  const sinceArgs = since ? [`--since=${since}`] : null;
  const log = ['log', '--reverse', '--oneline'];
  let selfRange = null;
  if (headFound) selfRange = [`${head}..HEAD`];
  else if (sinceArgs) selfRange = [...sinceArgs, 'HEAD'];
  const self = selfRange && gitLines([...log, ...selfRange]);
  printCommits('commits-self', self);
  if (self && self.length > MAX_COMMITS) {
    printCommits('first-parent', gitLines([...log, '--first-parent', ...selfRange]));
  }
  const notReached = headFound ? ['HEAD', head] : ['HEAD'];
  const other = sinceArgs
    && gitLines([...log, '--no-merges', '--source', ...sinceArgs, '--branches', '--not', ...notReached]);
  printCommits('commits-other', other);
  return { self, other };
}

// Prints the working tree and the commits made after the handoff. Returns the
// status word.
function reportStaleness(handoff, state) {
  if (state !== GIT_OK) return STATUS.unknown;
  const current = currentBranch();
  print('current-branch', current);
  const excludes = NOT_WORK.map((file) => `:(top,exclude)${file}`);
  const dirty = gitLines(['status', '--porcelain', '--untracked-files=normal', '--', ':(top)', ...excludes]);
  print('dirty', dirty ? dirty.length : NOT_LISTED);
  const branch = handoff.header ? handoff.header.branch : NONE;
  const branchDiffers = branch !== NONE && branch !== current;
  if (branchDiffers) print('branch-differs', 'yes');
  const { self, other } = reportCommits(handoff);
  if (!self || !other) return STATUS.unknown;
  const changed = self.length > 0 || other.length > 0 || !dirty || dirty.length > 0 || branchDiffers;
  return changed ? STATUS.check : STATUS.fresh;
}

function reportHandoff(handoff, state, top) {
  print('handoff', topPath(top, handoff.file));
  if (handoff.header) {
    print('written', handoff.header.written);
    print('branch', handoff.header.branch);
  } else {
    print('header', NONE);
  }
  if (handoff.doneWhen) print('done-when', handoff.doneWhen);
  print('status', reportStaleness(handoff, state));
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// The resume path of a run: its plan when the branch has it, else its spec.
function resumePath(topic, slug, files) {
  const plan = `${topic}/plans/${slug}.md`;
  const spec = `${topic}/specs/${slug}-design.md`;
  return [plan, spec].find((p) => files.has(p)) || NONE;
}

// The orchestration logs of one feature branch for its slug, read from the
// branch (never from the working tree).
function branchLogs(ref, slug, files) {
  const slugPattern = escapeRegExp(slug);
  const logPattern = new RegExp(`^(${LOG_ROOT}/${DATE_PATTERN}-${slugPattern})/${slugPattern}-orchestration-log\\.md$`);
  return [...files]
    .map((file) => file.match(logPattern))
    .filter(Boolean)
    .map((match) => ({ file: match[0], topic: match[1], text: gitLines(['show', `${ref}:${match[0]}`]) || [] }));
}

// A branch is a run when it carries two or more logs for its slug (ambiguous:
// the orchestrator's Resume stops on them, completed or not) or exactly one
// unfinished log.
function reportRuns(base) {
  const filter = base ? [`--no-merged=${HEADS}${base}`] : [];
  const refs = gitLines(['for-each-ref', ...filter, '--format=%(refname)', HEADS + FEATURE_PREFIX]) || [];
  const runs = [];
  for (const ref of refs) {
    const slug = ref.slice(HEADS.length + FEATURE_PREFIX.length);
    const files = new Set(gitLines(['ls-tree', '-r', '--full-tree', '--name-only', ref, '--', LOG_ROOT]) || []);
    const logs = branchLogs(ref, slug, files);
    const completed = logs.length === 1 && logs[0].text.some((line) => line.startsWith(COMPLETED));
    if (logs.length && !completed) runs.push({ ref, slug, files, logs });
  }
  print('runs', runs.length || NONE);
  for (const run of runs) {
    print('run', run.ref.slice(HEADS.length));
    printList(run.logs.map((log) => `log: ${log.file}`));
    const ambiguous = run.logs.length > 1;
    const details = [];
    if (ambiguous) {
      details.push('ambiguous: yes');
    } else {
      const headings = run.logs[0].text.filter((line) => line.startsWith('## '));
      details.push(`last: ${headings.length ? headings[headings.length - 1] : NONE}`);
    }
    details.push(`last-commit: ${git(['log', '-1', '--format=%cr', run.ref]).out}`);
    details.push(`resume: ${ambiguous ? NONE : resumePath(run.logs[0].topic, run.slug, run.files)}`);
    printList(details);
  }
}

// Reports a path argument: an orchestrator file (a plan, spec or log is not a
// handoff), a missing or unreadable path, or the handoff.
function reportArgument(target, state, top) {
  const candidates = [path.resolve(target), path.resolve(top, target)];
  const file = candidates.find((candidate) => fs.existsSync(candidate));
  const shown = topPath(top, file || candidates[0]);
  if (shown.startsWith(`${LOG_ROOT}/`)) {
    print('handoff', `orchestrator-file ${shown}`);
    return;
  }
  const handoff = file ? readHandoff(file) : null;
  if (handoff) reportHandoff(handoff, state, top);
  else print('handoff', `${file ? 'unreadable' : 'missing'} ${target}`);
}

function main() {
  const target = process.argv[2];
  const state = gitState();
  print('git', state);
  const inGit = state === GIT_OK;
  const base = inGit ? defaultBranch() : null;
  if (inGit) print('default-branch', base || 'unknown (no merge filter: every feature branch is scanned)');
  const top = state === NONE ? process.cwd() : git(['rev-parse', '--show-toplevel']).out;
  if (target) {
    reportArgument(target, state, top);
    return;
  }
  const handoff = newestHandoff(top);
  if (handoff) reportHandoff(handoff, state, top);
  else print('handoff', NONE);
  if (inGit) reportRuns(base);
  else print('runs', NONE);
}

main();
