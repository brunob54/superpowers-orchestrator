/**
 * Keep a file that a hook or the AI assistant writes out of `git status`.
 *
 * The entry goes to the repository's local exclude file, found with
 * `git rev-parse --git-path info/exclude`. Git never commits that file, so the
 * repository gets no uncommitted change (an edit to .gitignore would be one,
 * and it stops an unattended run at a clean-tree check). In a linked worktree
 * the command returns the exclude file shared by all worktrees.
 *
 * Fails silently on any error: a hook must never block the session.
 */

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const GIT_TIMEOUT_MS = 5000;

// Characters that have a special meaning in a gitignore pattern.
const PATTERN_SPECIAL_CHARACTERS = /[\\*?[]/g;

function git(args, cwd) {
  return execFileSync('git', args, {
    cwd,
    encoding: 'utf8',
    timeout: GIT_TIMEOUT_MS,
    stdio: ['ignore', 'pipe', 'ignore'],
  });
}

/**
 * Add an exclude entry for `filePath` (absolute) when git does not ignore it yet.
 * Does nothing outside a git repository.
 */
function excludeFromGit(filePath) {
  try {
    const dir = path.dirname(filePath);
    const name = path.basename(filePath);

    // `git check-ignore -q` exits 0 when the path is already ignored (by any
    // .gitignore, the exclude file or the global excludes file) and exits
    // non-zero otherwise, which execFileSync reports by throwing.
    try {
      git(['check-ignore', '-q', '--', name], dir);
      return;
    } catch {
      // Not ignored yet, or not a git repository: the next command tells which.
    }

    // Two output lines: the folder's path from the repository root ('' at the
    // root, else ending in '/'), then the exclude file's path relative to `dir`.
    const [prefix, excludeFile] = git(['rev-parse', '--show-prefix', '--git-path', 'info/exclude'], dir)
      .split('\n');
    const excludePath = path.resolve(dir, excludeFile);
    const pattern = '/' + (prefix + name).replace(PATTERN_SPECIAL_CHARACTERS, '\\$&');

    fs.mkdirSync(path.dirname(excludePath), { recursive: true });
    const content = fs.existsSync(excludePath) ? fs.readFileSync(excludePath, 'utf8') : '';
    const separator = content.length > 0 && !content.endsWith('\n') ? '\n' : '';
    fs.appendFileSync(excludePath, `${separator}${pattern}\n`);
  } catch {
    // Not a git repository, or the exclude file cannot be written.
  }
}

module.exports = { excludeFromGit };
