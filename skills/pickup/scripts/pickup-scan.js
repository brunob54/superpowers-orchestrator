#!/usr/bin/env node
// Prints the facts the /pickup skill needs, as "key: value" lines:
// - the git state of the current directory;
// - the newest handoff file (or the one named by the argument), its header,
//   and the commits made after it (its staleness);
// - without an argument, the unfinished orchestration runs found on local
//   feature branches that are not merged into the default branch.
// Usage: node pickup-scan.js [handoff-path]   (run from the project root)
// Exit status is 0 on every normal outcome; a status word carries the result.
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const HANDOFF_DIR = 'tmp/docs';
const HANDOFF_NAME = /^(\d{4}-\d{2}-\d{2})-handoff-.+\.md$/;
const HEADER = /^Handoff: written=(\S+) branch=(\S+) head=(\S+)/;
const DONE_WHEN = /^Done when: (.+)$/;
const DATE = /^\d{4}-\d{2}-\d{2}/;
const NONE = 'none';
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

function printList(lines) {
  lines.forEach((line) => console.log(`  ${line}`));
}

function lines(text) {
  return text ? text.split(/\r?\n/) : [];
}

// Runs git with an argument array (no shell). Returns the exit state and the
// trimmed standard output.
function git(args) {
  const result = spawnSync('git', args, { encoding: 'utf8' });
  return { ok: result.status === 0, out: (result.stdout || '').trim() };
}

function branchExists(name) {
  return git(['show-ref', '--verify', '--quiet', HEADS + name]).ok;
}

function localDate() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

// "ok", "none" (not a git work tree) or "no-commits".
function gitState() {
  if (!git(['rev-parse', '--is-inside-work-tree']).ok) return NONE;
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

// Reads a handoff file: the header fields of its first line and an optional
// "Done when:" second line.
function readHandoff(file) {
  const text = lines(fs.readFileSync(file, 'utf8'));
  const header = (text[0] || '').match(HEADER);
  const nameDate = path.basename(file).match(HANDOFF_NAME);
  const done = (text[1] || '').match(DONE_WHEN);
  return {
    file,
    header: header ? { written: header[1], branch: header[2], head: header[3] } : null,
    nameDate: nameDate ? nameDate[1] : null,
    doneWhen: done ? done[1] : null,
    mtime: fs.statSync(file).mtimeMs,
  };
}

function writtenDate(handoff) {
  const written = handoff.header && handoff.header.written.match(DATE);
  return written ? written[0] : handoff.nameDate;
}

// The newest handoff in tmp/docs: ordered by the header "written=" value, then
// the file-name date, then the modification time. A file dated after today is
// skipped.
function newestHandoff() {
  if (!fs.existsSync(HANDOFF_DIR)) return null;
  const today = localDate();
  const key = (h) => (h.header ? h.header.written : h.nameDate);
  const found = fs.readdirSync(HANDOFF_DIR)
    .filter((name) => HANDOFF_NAME.test(name))
    .map((name) => readHandoff(path.posix.join(HANDOFF_DIR, name)))
    .filter((h) => h.nameDate <= today && writtenDate(h) <= today)
    .sort((a, b) => key(b).localeCompare(key(a))
      || b.nameDate.localeCompare(a.nameDate)
      || b.mtime - a.mtime);
  return found[0] || null;
}

// Prints the commits of the range: oldest first, each naming its branch. A
// list longer than MAX_COMMITS is replaced by the first-parent list of HEAD.
// Returns the status word.
function reportCommits(range) {
  const log = git(['log', '--reverse', '--oneline', '--no-merges', '--source', '--branches', 'HEAD', ...range.all]);
  if (!log.ok) {
    print('commits', 'not-listed (git log failed)');
    return STATUS.unknown;
  }
  const commits = lines(log.out);
  if (commits.length > MAX_COMMITS) {
    print('commits', `${commits.length} (more than ${MAX_COMMITS}: the first-parent list of HEAD follows)`);
    printList(lines(git(['log', '--oneline', '--first-parent', 'HEAD', ...range.firstParent]).out));
  } else {
    print('commits', commits.length);
    printList(commits);
  }
  return commits.length === 0 ? STATUS.fresh : STATUS.check;
}

// Prints the head check and the commits made after the handoff. Returns the
// status word.
function reportStaleness(handoff, state) {
  if (state !== GIT_OK) return STATUS.unknown;
  const head = handoff.header ? handoff.header.head : NONE;
  if (head !== NONE && git(['cat-file', '-e', `${head}^{commit}`]).ok) {
    print('head', head);
    return reportCommits({ all: ['--not', head], firstParent: [`^${head}`] });
  }
  print('head', 'not-found');
  const date = writtenDate(handoff);
  if (!date) {
    print('since', NONE);
    return STATUS.unknown;
  }
  // A bare --since=<date> means that date at the current time of day.
  const midnight = `${date} 00:00`;
  const since = [`--since=${midnight}`];
  print('since', midnight);
  return reportCommits({ all: since, firstParent: since });
}

function reportHandoff(handoff, state) {
  print('handoff', handoff.file);
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

function reportRuns(base) {
  const filter = base ? [`--no-merged=${HEADS}${base}`] : [];
  const refs = lines(git(['for-each-ref', ...filter, '--format=%(refname)', HEADS + FEATURE_PREFIX]).out);
  const runs = [];
  for (const ref of refs) {
    const branch = ref.slice(HEADS.length);
    const slug = branch.slice(FEATURE_PREFIX.length);
    const files = new Set(lines(git(['ls-tree', '-r', '--name-only', ref, '--', LOG_ROOT]).out));
    const slugPattern = escapeRegExp(slug);
    const logPattern = new RegExp(`^(${LOG_ROOT}/\\d{4}-\\d{2}-\\d{2}-${slugPattern})/${slugPattern}-orchestration-log\\.md$`);
    for (const file of files) {
      const match = file.match(logPattern);
      if (!match) continue;
      const topic = match[1];
      const text = lines(git(['show', `${ref}:${file}`]).out);
      if (text.some((line) => line.startsWith(COMPLETED))) continue;
      runs.push({ branch, file, topic, slug, text, files, ref });
    }
  }
  print('runs', runs.length || NONE);
  for (const run of runs) {
    const headings = run.text.filter((line) => line.startsWith('## '));
    print('run', run.branch);
    printList([
      `log: ${run.file}`,
      `last: ${headings.length ? headings[headings.length - 1] : NONE}`,
      `last-commit: ${git(['log', '-1', '--format=%cr', run.ref]).out}`,
      `resume: ${resumePath(run.topic, run.slug, run.files)}`,
    ]);
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
    if (fs.existsSync(target)) reportHandoff(readHandoff(target), state);
    else print('handoff', `missing ${target}`);
    return;
  }
  const handoff = newestHandoff();
  if (handoff) reportHandoff(handoff, state);
  else print('handoff', NONE);
  if (inGit) reportRuns(base);
  else print('runs', NONE);
}

main();
