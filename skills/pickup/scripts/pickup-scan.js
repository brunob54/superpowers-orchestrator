#!/usr/bin/env node
// Prints the facts the /pickup skill needs, as "key: value" lines:
// - the git state of the current directory;
// - the newest handoff file (or the one named by the argument), its header,
//   the working tree, and the commits made after the handoff (its staleness);
// - without an argument, the unfinished orchestration runs found on local
//   feature branches that are not merged into the default branch.
// Usage: node pickup-scan.js [handoff-path]
// A path argument is read from the current directory; tmp/docs and the
// branch files are read from the repository top.
// Exit status is 0 on every normal outcome; a status word carries the result.
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const DATE_PATTERN = '\\d{4}-\\d{2}-\\d{2}';
const HANDOFF_DIR = 'tmp/docs';
const HANDOFF_NAME = new RegExp(`^(${DATE_PATTERN})-handoff-.+\\.md$`);
const HEADER = /^Handoff: written=(\S+) branch=(\S+) head=(\S+)/;
const VALID_WRITTEN = new RegExp(`^(${DATE_PATTERN})T(\\d{2}:\\d{2})$`);
const VALID_HEAD = /^[0-9a-f]{7,40}$/;
const DONE_WHEN = /^Done when: (.+)$/;
const NONE = 'none';
const NOT_LISTED = 'not-listed';
const GIT_OK = 'ok';
const GIT_NO_COMMITS = 'no-commits';
const LOG_ROOT = 'docs/superpowers-orchestrator';
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
  const result = spawnSync('git', ['-c', 'color.ui=never', ...args], { encoding: 'utf8' });
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

// A path relative to the current directory, with forward slashes.
function displayPath(file) {
  return path.relative(process.cwd(), file).split(path.sep).join('/');
}

// Reads a handoff file: the header fields of its first line (written= is
// kept only in the YYYY-MM-DDTHH:MM form) and an optional "Done when:" second
// line. Returns null when the path is not a readable regular file.
function readHandoff(file) {
  let text;
  let mtime;
  try {
    const stat = fs.statSync(file);
    if (!stat.isFile()) return null;
    text = lines(fs.readFileSync(file, 'utf8'));
    mtime = stat.mtimeMs;
  } catch (error) {
    return null;
  }
  const header = (text[0] || '').match(HEADER);
  const written = header && header[1].match(VALID_WRITTEN);
  const nameDate = path.basename(file).match(HANDOFF_NAME);
  const done = (text[1] || '').match(DONE_WHEN);
  return {
    file,
    header: header ? { written: header[1], branch: header[2], head: header[3] } : null,
    written: written ? { key: header[1], date: written[1], time: written[2] } : null,
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
  const key = (h) => (h.written ? h.written.key : h.nameDate);
  const found = names
    .filter((name) => HANDOFF_NAME.test(name))
    .map((name) => readHandoff(path.join(dir, name)))
    .filter((h) => h && h.nameDate <= today && handoffDate(h) <= today)
    .sort((a, b) => key(b).localeCompare(key(a))
      || b.nameDate.localeCompare(a.nameDate)
      || b.mtime - a.mtime);
  return found[0] || null;
}

// Prints the length of a list and at most MAX_COMMITS of its lines, or
// "not-listed" when git failed.
function printCapped(key, list) {
  print(key, list ? list.length : NOT_LISTED);
  if (list) printList(list.slice(0, MAX_COMMITS));
}

// Prints the commits of the window, oldest first, each with the first local
// ref that reaches it. A list longer than MAX_COMMITS shows its first
// MAX_COMMITS lines, then the first-parent list of HEAD, also capped.
// Returns the number of commits, or null when the list could not be produced.
function reportCommits(window) {
  const list = gitLines(['log', '--reverse', '--oneline', '--no-merges', '--source', '--branches', 'HEAD', ...window.all]);
  if (!list) {
    print('commits', NOT_LISTED);
    return null;
  }
  print('commits', list.length);
  if (list.length <= MAX_COMMITS) {
    printList(list);
    return list.length;
  }
  print('commits-listed', MAX_COMMITS);
  printList(list.slice(0, MAX_COMMITS));
  printCapped('first-parent', gitLines(['log', '--reverse', '--oneline', '--first-parent', 'HEAD', ...window.firstParent]));
  return list.length;
}

// Chooses the commit window after the handoff and prints it. Returns the
// git log arguments, or null when neither a head nor a date is known.
function commitWindow(handoff) {
  const head = handoff.header ? handoff.header.head : NONE;
  const headFound = VALID_HEAD.test(head) && git(['cat-file', '-e', `${head}^{commit}`]).ok;
  print('head', headFound ? head : 'not-found');
  const date = handoffDate(handoff);
  if (!headFound && !date) {
    print('since', NONE);
    return null;
  }
  // With a head, the window starts at the written time: an older commit on an
  // unmerged branch is not work done after the handoff. Without a head, it
  // starts at 00:00 of the handoff date: a bare --since=<date> means that date
  // at the current time of day.
  const written = handoff.written && `${handoff.written.date} ${handoff.written.time}`;
  const since = headFound ? written : `${date} 00:00`;
  if (since) print('since', since);
  const sinceArgs = since ? [`--since=${since}`] : [];
  return {
    all: headFound ? [...sinceArgs, '--not', head] : sinceArgs,
    firstParent: headFound ? [...sinceArgs, `^${head}`] : sinceArgs,
  };
}

// Prints the working tree, the head check and the commits made after the
// handoff. Returns the status word.
function reportStaleness(handoff, state) {
  if (state !== GIT_OK) return STATUS.unknown;
  const current = currentBranch();
  print('current-branch', current);
  // The handoff files themselves live in tmp/docs and are not work.
  const dirty = gitLines(['status', '--porcelain', '--untracked-files=all', '--', ':(top)', `:(top,exclude)${HANDOFF_DIR}`]);
  print('dirty', dirty ? dirty.length : NOT_LISTED);
  const branch = handoff.header ? handoff.header.branch : NONE;
  const branchDiffers = branch !== NONE && branch !== current;
  if (branchDiffers) print('branch-differs', 'yes');
  const window = commitWindow(handoff);
  const count = window ? reportCommits(window) : null;
  if (count === null || !dirty) return STATUS.unknown;
  return count > 0 || dirty.length > 0 || branchDiffers ? STATUS.check : STATUS.fresh;
}

function reportHandoff(handoff, state) {
  print('handoff', displayPath(handoff.file));
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

// The unfinished orchestration logs of one feature branch, read from the
// branch (never from the working tree).
function unfinishedLogs(ref, slug, files) {
  const slugPattern = escapeRegExp(slug);
  const logPattern = new RegExp(`^(${LOG_ROOT}/${DATE_PATTERN}-${slugPattern})/${slugPattern}-orchestration-log\\.md$`);
  const logs = [];
  for (const file of files) {
    const match = file.match(logPattern);
    if (!match) continue;
    const text = gitLines(['show', `${ref}:${file}`]) || [];
    if (text.some((line) => line.startsWith(COMPLETED))) continue;
    logs.push({ file, topic: match[1], text });
  }
  return logs;
}

function reportRuns(base) {
  const filter = base ? [`--no-merged=${HEADS}${base}`] : [];
  const refs = gitLines(['for-each-ref', ...filter, '--format=%(refname)', HEADS + FEATURE_PREFIX]) || [];
  const runs = [];
  for (const ref of refs) {
    const slug = ref.slice(HEADS.length + FEATURE_PREFIX.length);
    const files = new Set(gitLines(['ls-tree', '-r', '--full-tree', '--name-only', ref, '--', LOG_ROOT]) || []);
    const logs = unfinishedLogs(ref, slug, files);
    if (logs.length) runs.push({ ref, slug, files, logs });
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

function main() {
  const target = process.argv[2];
  const state = gitState();
  print('git', state);
  const inGit = state === GIT_OK;
  const base = inGit ? defaultBranch() : null;
  if (inGit) print('default-branch', base || 'unknown (no merge filter: every feature branch is scanned)');
  if (target) {
    const exists = fs.existsSync(target);
    const handoff = exists ? readHandoff(target) : null;
    if (handoff) reportHandoff(handoff, state);
    else print('handoff', `${exists ? 'unreadable' : 'missing'} ${target}`);
    return;
  }
  const top = state === NONE ? process.cwd() : git(['rev-parse', '--show-toplevel']).out;
  const handoff = newestHandoff(top);
  if (handoff) reportHandoff(handoff, state);
  else print('handoff', NONE);
  if (inGit) reportRuns(base);
  else print('runs', NONE);
}

main();
