#!/usr/bin/env node
/**
 * Statusline bridge: caches the harness's authoritative context_window data
 * so the skill-activator's 60% start gate can be model-window-aware.
 *
 * Claude Code pipes a JSON payload to the configured statusLine command on
 * every refresh. This script tees the payload's context_window (plus the
 * session id) into ~/.claude/hooks-logs/context-window.cache.json and prints
 * a one-line status. getContextPressure() in skill-activator.js prefers the
 * cache when its session id matches the asking session; otherwise it falls
 * back to transcript parsing against the 200K default.
 *
 * Opt-in — wire it in settings.json:
 *   "statusLine": { "type": "command",
 *     "command": "node <plugin-root>/hooks/statusline-context-cache.js" }
 *
 * Already have a statusline? Delegate mode caches, then feeds the same
 * payload to your existing renderer and relays its output unchanged:
 *   "command": "node <plugin-root>/hooks/statusline-context-cache.js -- node ~/.claude/hud/my-hud.mjs"
 *
 * Never throws; on any failure it still prints a line (statusline contract).
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const CACHE_FILE_NAME = 'context-window.cache.json';

function homeDir() {
  return process.env.USERPROFILE || process.env.HOME || '';
}

function cachePath() {
  return path.join(homeDir(), '.claude', 'hooks-logs', CACHE_FILE_NAME);
}

/** Total prompt-side tokens currently in the window, from current_usage. */
function totalInputTokens(cw) {
  const u = cw.current_usage;
  if (u && typeof u === 'object') {
    const total = (u.input_tokens || 0)
      + (u.cache_creation_input_tokens || 0)
      + (u.cache_read_input_tokens || 0);
    if (total > 0) return total;
  }
  return cw.total_input_tokens || 0;
}

function writeCache(input) {
  const cw = input.context_window;
  if (!cw || typeof cw !== 'object') return null;
  const windowSize = cw.context_window_size || 0;
  const total = totalInputTokens(cw);
  if (!input.session_id || windowSize <= 0 || total <= 0) return null;

  const percent = typeof cw.used_percentage === 'number'
    ? Math.round(cw.used_percentage)
    : Math.round((total / windowSize) * 100);

  const entry = {
    session_id: input.session_id,
    context_window_size: windowSize,
    input_tokens_total: total,
    used_percentage: percent,
    updated_at: new Date().toISOString(),
  };
  const file = cachePath();
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(entry));
  return entry;
}

function statusLine(input, entry) {
  const model = (input.model && input.model.display_name) || 'Claude';
  if (!entry) return model;
  const windowK = Math.round(entry.context_window_size / 1000);
  const usedK = Math.round(entry.input_tokens_total / 1000);
  return `${model} | ctx ${usedK}K/${windowK}K (${entry.used_percentage}%)`;
}

/** Argv after a `--` separator: an existing statusline command to delegate to. */
function delegateCommand(argv) {
  const idx = argv.indexOf('--');
  if (idx < 0 || idx === argv.length - 1) return null;
  return argv.slice(idx + 1);
}

/** Feed the raw payload to the delegate renderer; null when it fails. */
function runDelegate(cmd, raw) {
  try {
    const res = spawnSync(cmd[0], cmd.slice(1), { input: raw, encoding: 'utf8', timeout: 5000 });
    if (res.status === 0 && res.stdout && res.stdout.trim()) return res.stdout;
  } catch {
    // Fall through to our own line.
  }
  return null;
}

function main() {
  const delegate = delegateCommand(process.argv.slice(2));
  let raw = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (chunk) => { raw += chunk; });
  process.stdin.on('end', () => {
    let line = 'Claude';
    try {
      const input = JSON.parse(raw);
      const entry = writeCache(input);
      line = statusLine(input, entry);
    } catch {
      // Malformed payload — keep the fallback line; never break the statusline.
    }
    const delegated = delegate ? runDelegate(delegate, raw) : null;
    process.stdout.write(delegated !== null ? delegated : line + '\n');
  });
}

if (require.main === module) {
  main();
} else {
  module.exports = {
    writeCache, statusLine, totalInputTokens, cachePath,
    delegateCommand, runDelegate, CACHE_FILE_NAME,
  };
}
