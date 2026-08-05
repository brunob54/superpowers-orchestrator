#!/usr/bin/env node
/**
 * Unit tests — hooks/statusline-context-cache.js
 *
 * Verifies:
 *   - writeCache persists session id, window size, token total, percentage
 *   - Invalid payloads (no context_window, zero window, no session) write nothing
 *   - Percentage computed from current_usage when used_percentage is absent
 *   - statusLine formatting, including the no-data fallback
 *   - End-to-end: JSON on stdin → cache file + printed status line, and a
 *     malformed payload still prints a line (statusline contract)
 *
 * Run: node tests/codex/test-statusline-cache.js
 * No dependencies beyond Node.js stdlib.
 */

'use strict';

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const SCRIPT = path.join(__dirname, '..', '..', 'hooks', 'statusline-context-cache.js');
const { writeCache, statusLine, totalInputTokens } = require(SCRIPT);

let passed = 0;
let failed = 0;

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

function withTmpHome(fn) {
  const tmpHome = fs.mkdtempSync(path.join(os.tmpdir(), 'slc-unit-'));
  const orig = { up: process.env.USERPROFILE, home: process.env.HOME };
  process.env.USERPROFILE = tmpHome;
  process.env.HOME = tmpHome;
  try {
    return fn(tmpHome);
  } finally {
    process.env.USERPROFILE = orig.up;
    process.env.HOME = orig.home;
    fs.rmSync(tmpHome, { recursive: true });
  }
}

function cacheFileIn(tmpHome) {
  return path.join(tmpHome, '.claude', 'hooks-logs', 'context-window.cache.json');
}

const FULL_INPUT = {
  session_id: 'sess-123',
  model: { display_name: 'Opus 5' },
  context_window: {
    context_window_size: 1000000,
    used_percentage: 13,
    current_usage: {
      input_tokens: 5000,
      cache_creation_input_tokens: 25000,
      cache_read_input_tokens: 100000,
    },
  },
};

console.log('\nstatusline-context-cache — writeCache');

test('Persists session id, window size, token total, and percentage', () => {
  const { entry, onDisk } = withTmpHome((tmpHome) => {
    const entry = writeCache(FULL_INPUT);
    const onDisk = JSON.parse(fs.readFileSync(cacheFileIn(tmpHome), 'utf8'));
    return { entry, onDisk };
  });
  assert.strictEqual(entry.session_id, 'sess-123');
  assert.strictEqual(entry.context_window_size, 1000000);
  assert.strictEqual(entry.input_tokens_total, 130000);
  assert.strictEqual(entry.used_percentage, 13);
  assert.deepStrictEqual(onDisk.session_id, entry.session_id, 'On-disk entry matches');
});

test('Computes percentage from current_usage when used_percentage is absent', () => {
  const input = JSON.parse(JSON.stringify(FULL_INPUT));
  delete input.context_window.used_percentage;
  const entry = withTmpHome(() => writeCache(input));
  assert.strictEqual(entry.used_percentage, 13, '130000/1000000 → 13%');
});

test('Writes nothing without context_window, session id, or a positive window', () => {
  const wrote = withTmpHome((tmpHome) => {
    writeCache({ session_id: 's' });
    writeCache({ ...FULL_INPUT, session_id: undefined });
    const zeroWindow = JSON.parse(JSON.stringify(FULL_INPUT));
    zeroWindow.context_window.context_window_size = 0;
    writeCache(zeroWindow);
    return fs.existsSync(cacheFileIn(tmpHome));
  });
  assert.strictEqual(wrote, false, 'No cache file for invalid payloads');
});

test('totalInputTokens falls back to total_input_tokens when current_usage is null', () => {
  const total = totalInputTokens({ current_usage: null, total_input_tokens: 42000 });
  assert.strictEqual(total, 42000);
});

console.log('\nstatusline-context-cache — statusLine');

test('Formats model, usage, window, and percentage', () => {
  const line = statusLine(FULL_INPUT, {
    context_window_size: 1000000, input_tokens_total: 130000, used_percentage: 13,
  });
  assert.strictEqual(line, 'Opus 5 | ctx 130K/1000K (13%)');
});

test('Falls back to the model name alone without cache data', () => {
  assert.strictEqual(statusLine(FULL_INPUT, null), 'Opus 5');
  assert.strictEqual(statusLine({}, null), 'Claude');
});

console.log('\nstatusline-context-cache — end to end (stdin → cache + line)');

test('Full payload on stdin writes the cache and prints the status line', () => {
  const { stdout, onDisk } = withTmpHome((tmpHome) => {
    const res = spawnSync(process.execPath, [SCRIPT], {
      input: JSON.stringify(FULL_INPUT),
      encoding: 'utf8',
      env: { ...process.env, HOME: tmpHome, USERPROFILE: tmpHome },
    });
    const onDisk = JSON.parse(fs.readFileSync(cacheFileIn(tmpHome), 'utf8'));
    return { stdout: res.stdout, onDisk };
  });
  assert.ok(stdout.includes('Opus 5 | ctx 130K/1000K (13%)'), `Got: ${stdout}`);
  assert.strictEqual(onDisk.session_id, 'sess-123');
});

test('Delegate mode caches AND relays the existing renderer output unchanged', () => {
  const { stdout, onDisk } = withTmpHome((tmpHome) => {
    const res = spawnSync(process.execPath, [
      SCRIPT, '--', process.execPath, '-e',
      'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>console.log("MY-HUD "+JSON.parse(d).model.display_name))',
    ], {
      input: JSON.stringify(FULL_INPUT),
      encoding: 'utf8',
      env: { ...process.env, HOME: tmpHome, USERPROFILE: tmpHome },
    });
    const onDisk = JSON.parse(fs.readFileSync(cacheFileIn(tmpHome), 'utf8'));
    return { stdout: res.stdout, onDisk };
  });
  assert.ok(stdout.includes('MY-HUD Opus 5'), `Delegate output relayed, got: ${stdout}`);
  assert.ok(!stdout.includes('ctx 130K'), 'Own line must not replace the delegate output');
  assert.strictEqual(onDisk.session_id, 'sess-123', 'Cache still written in delegate mode');
});

test('Failing delegate falls back to the bridge\'s own line', () => {
  const { stdout } = withTmpHome((tmpHome) => {
    const res = spawnSync(process.execPath, [
      SCRIPT, '--', process.execPath, '-e', 'process.exit(3)',
    ], {
      input: JSON.stringify(FULL_INPUT),
      encoding: 'utf8',
      env: { ...process.env, HOME: tmpHome, USERPROFILE: tmpHome },
    });
    return { stdout: res.stdout };
  });
  assert.ok(stdout.includes('Opus 5 | ctx 130K/1000K (13%)'), `Fallback line expected, got: ${stdout}`);
});

test('Malformed stdin still prints a line and writes no cache', () => {
  const { stdout, exists } = withTmpHome((tmpHome) => {
    const res = spawnSync(process.execPath, [SCRIPT], {
      input: '{broken',
      encoding: 'utf8',
      env: { ...process.env, HOME: tmpHome, USERPROFILE: tmpHome },
    });
    return { stdout: res.stdout, exists: fs.existsSync(cacheFileIn(tmpHome)) };
  });
  assert.ok(stdout.trim().length > 0, 'Must print a fallback line');
  assert.strictEqual(exists, false, 'No cache from malformed payload');
});

console.log('\n──────────────────────────────────────────────────');
console.log(`statusline-context-cache: ${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
