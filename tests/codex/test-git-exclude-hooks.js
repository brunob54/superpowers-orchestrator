#!/usr/bin/env node
/**
 * Unit tests — hooks/track-edits.js and hooks/context-engine.js: ignore entries
 *
 * Both hooks keep AI workspace files (state.md, session-log.md, project-map.md,
 * known-issues.md, context-snapshot.json) out of `git status`. They must do it
 * without editing any file that git tracks, so an unattended run never meets an
 * uncommitted change it did not make. Each test runs a hook as a separate
 * process on a temporary git repository and checks the repository afterwards.
 *
 * Run: node tests/codex/test-git-exclude-hooks.js
 * No dependencies beyond Node.js stdlib and git.
 */

'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const HOOKS_DIR = path.join(__dirname, '..', '..', 'hooks');
const TRACK_EDITS = path.join(HOOKS_DIR, 'track-edits.js');
const CONTEXT_ENGINE = path.join(HOOKS_DIR, 'context-engine.js');
const GITIGNORE = '.gitignore';
const STATE_FILE = 'state.md';
const SNAPSHOT_FILE = 'context-snapshot.json';

const WORK_ROOT = fs.mkdtempSync(path.join(os.tmpdir(), 'git-exclude-hooks-'));

// Isolate git from the developer's own configuration: a global excludes file
// that already ignores state.md would make every test pass without the hooks.
const EMPTY_GLOBAL_CONFIG = path.join(WORK_ROOT, 'empty-gitconfig');
fs.writeFileSync(EMPTY_GLOBAL_CONFIG, '');
const ENV = {
  ...process.env,
  HOME: WORK_ROOT,
  USERPROFILE: WORK_ROOT,
  GIT_CONFIG_GLOBAL: EMPTY_GLOBAL_CONFIG,
  GIT_CONFIG_NOSYSTEM: '1',
  GIT_AUTHOR_NAME: 'test',
  GIT_AUTHOR_EMAIL: 'test@example.com',
  GIT_COMMITTER_NAME: 'test',
  GIT_COMMITTER_EMAIL: 'test@example.com',
};

let passed = 0;
let failed = 0;
let repoCount = 0;

function test(label, fn) {
  try {
    fn();
    console.log(`  ✓ ${label}`);
    passed++;
  } catch (err) {
    console.error(`  ✗ ${label}`);
    console.error(`    ${err.message}`);
    failed++;
  }
}

function git(cwd, ...args) {
  return execFileSync('git', args, { cwd, env: ENV, encoding: 'utf8' });
}

/** A new repository with one commit, so HEAD exists for context-engine. */
function makeRepo() {
  repoCount++;
  const dir = path.join(WORK_ROOT, `repo-${repoCount}`);
  fs.mkdirSync(dir);
  git(dir, 'init', '-q');
  fs.writeFileSync(path.join(dir, 'README.md'), 'fixture\n');
  git(dir, 'add', 'README.md');
  git(dir, 'commit', '-q', '-m', 'initial');
  return dir;
}

function runHook(hookPath, cwd, input) {
  return execFileSync(process.execPath, [hookPath], {
    cwd,
    env: ENV,
    input: JSON.stringify(input),
    encoding: 'utf8',
    // context-engine prints git errors for a repository with one commit.
    stdio: ['pipe', 'pipe', 'ignore'],
  });
}

/** Write a file the way the Write tool does, then run track-edits on it. */
function writeWithTool(cwd, relativePath) {
  const filePath = path.join(cwd, relativePath);
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, 'content\n');
  return runHook(TRACK_EDITS, cwd, {
    tool_name: 'Write',
    tool_input: { file_path: filePath, content: 'content\n' },
    cwd,
    session_id: 'test-session',
  });
}

function status(cwd) {
  return git(cwd, 'status', '--porcelain', '--untracked-files=all');
}

function excludeContent(cwd) {
  const excludePath = path.resolve(cwd, git(cwd, 'rev-parse', '--git-path', 'info/exclude').trim());
  return fs.existsSync(excludePath) ? fs.readFileSync(excludePath, 'utf8') : '';
}

function isIgnored(cwd, relativePath) {
  try {
    git(cwd, 'check-ignore', '-q', '--', relativePath);
    return true;
  } catch {
    return false;
  }
}

console.log('\ntrack-edits.js');

test('an artifact at the repository root is ignored, and no .gitignore is created', () => {
  const repo = makeRepo();
  assert.strictEqual(writeWithTool(repo, STATE_FILE), '{}');
  assert.strictEqual(status(repo), '');
  assert.ok(!fs.existsSync(path.join(repo, GITIGNORE)), '.gitignore was created');
});

test('an artifact in a subfolder is ignored at that path only', () => {
  const repo = makeRepo();
  writeWithTool(repo, path.join('sub', STATE_FILE));
  assert.strictEqual(status(repo), '');
  assert.ok(!fs.existsSync(path.join(repo, 'sub', GITIGNORE)), 'sub/.gitignore was created');
  assert.ok(!isIgnored(repo, path.join('other', STATE_FILE)), 'other/state.md is ignored too');
});

test('a folder name with gitignore pattern characters is matched literally', () => {
  const repo = makeRepo();
  writeWithTool(repo, path.join('a[1]*?', STATE_FILE));
  assert.strictEqual(status(repo), '');
  assert.ok(!isIgnored(repo, path.join('a1xy', STATE_FILE)), 'the pattern matched another folder');
});

test('a second write of the same artifact adds no second entry', () => {
  const repo = makeRepo();
  writeWithTool(repo, STATE_FILE);
  const once = excludeContent(repo);
  writeWithTool(repo, STATE_FILE);
  assert.strictEqual(excludeContent(repo), once);
});

test('an artifact already ignored by a committed .gitignore changes no file', () => {
  const repo = makeRepo();
  fs.writeFileSync(path.join(repo, GITIGNORE), `# AI assistant artifacts\n${STATE_FILE}\n`);
  git(repo, 'add', GITIGNORE);
  git(repo, 'commit', '-q', '-m', 'ignore');
  const excludeBefore = excludeContent(repo);
  writeWithTool(repo, STATE_FILE);
  assert.strictEqual(status(repo), '');
  assert.strictEqual(excludeContent(repo), excludeBefore);
});

test('a file that is not an AI artifact gets no ignore entry', () => {
  const repo = makeRepo();
  const excludeBefore = excludeContent(repo);
  writeWithTool(repo, 'notes.md');
  assert.strictEqual(excludeContent(repo), excludeBefore);
  assert.strictEqual(status(repo), '?? notes.md\n');
});

test('an artifact in a linked worktree is ignored there, and no .gitignore is created', () => {
  const repo = makeRepo();
  const worktree = `${repo}-linked`;
  git(repo, 'worktree', 'add', '-q', worktree);
  writeWithTool(worktree, STATE_FILE);
  assert.strictEqual(status(worktree), '');
  assert.ok(!fs.existsSync(path.join(worktree, GITIGNORE)), '.gitignore was created');
});

test('outside a git repository nothing is written besides the artifact', () => {
  repoCount++;
  const dir = path.join(WORK_ROOT, `plain-${repoCount}`);
  fs.mkdirSync(dir);
  assert.strictEqual(writeWithTool(dir, STATE_FILE), '{}');
  assert.deepStrictEqual(fs.readdirSync(dir), [STATE_FILE]);
});

console.log('\ncontext-engine.js');

test('the snapshot at the repository root is ignored, and no .gitignore is created', () => {
  const repo = makeRepo();
  assert.strictEqual(runHook(CONTEXT_ENGINE, repo, { cwd: repo }), '{}');
  assert.ok(fs.existsSync(path.join(repo, SNAPSHOT_FILE)), 'no snapshot was written');
  assert.strictEqual(status(repo), '');
  assert.ok(!fs.existsSync(path.join(repo, GITIGNORE)), '.gitignore was created');
});

test('a snapshot written from a subfolder is ignored, and a tracked .gitignore is unchanged', () => {
  const repo = makeRepo();
  const sub = path.join(repo, 'sub');
  fs.mkdirSync(sub);
  const gitignoreText = 'node_modules/\n';
  fs.writeFileSync(path.join(repo, GITIGNORE), gitignoreText);
  git(repo, 'add', GITIGNORE);
  git(repo, 'commit', '-q', '-m', 'ignore');
  runHook(CONTEXT_ENGINE, sub, { cwd: sub });
  assert.ok(fs.existsSync(path.join(sub, SNAPSHOT_FILE)), 'no snapshot was written');
  assert.strictEqual(status(repo), '');
  assert.strictEqual(fs.readFileSync(path.join(repo, GITIGNORE), 'utf8'), gitignoreText);
});

fs.rmSync(WORK_ROOT, { recursive: true, force: true });

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
