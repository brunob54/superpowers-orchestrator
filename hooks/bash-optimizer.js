#!/usr/bin/env node
'use strict';

/**
 * Bash Output Optimizer — executes a command and compresses its output.
 *
 * Called by bash-compress-hook.js via PreToolUse command rewriting.
 * Usage: node bash-optimizer.js <base64-encoded-command> <rule-type> [<call-time-out-in-milliseconds>]
 *
 * Cross-platform:
 *   - macOS:   uses /bin/bash (always available, ships with macOS)
 *   - Linux:   uses /bin/bash or /usr/bin/bash (always available)
 *   - Windows: uses Git Bash (required by Claude Code), falls back to sh
 *
 * Safety:
 *   - Fail-open: any error results in raw output passthrough
 *   - Exit codes are always preserved from the original command
 *   - stderr is always passed through uncompressed
 *   - Compressed output includes a transparency marker
 *   - At the Bash call's time-out, Claude Code moves the call to the
 *     background. It does not stop the command. From then on the optimizer
 *     writes output raw (not compressed), as for a command it did not rewrite.
 */

const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { RULES, MIN_OUTPUT_LENGTH } = require('./compression-rules');

const b64Command = process.argv[2];
const ruleType = process.argv[3];

// Time-out of the Bash tool call, in milliseconds (ms). The hook passes the
// call's timeout field when it has one. Claude Code does not document how it
// computes the time-out; these rules were read from Claude Code 2.1.273:
//   - The default is BASH_DEFAULT_TIMEOUT_MS, or 120000 ms when it is not set.
//   - The maximum is BASH_MAX_TIMEOUT_MS, or 600000 ms when it is not set, and
//     never less than the default. A larger time-out is lowered to it.
//   - CLAUDE_CODE_AUTO_BACKGROUND_TIMEOUT_MS, when set, moves the call to the
//     background earlier, but never before 2000 ms. Claude Code applies it to
//     the main agent only. The optimizer applies it always, because a switch
//     to raw output that comes too early only loses compression.
const DEFAULT_CALL_TIMEOUT_MS = 120000;
const MAX_CALL_TIMEOUT_MS = 600000;
const MIN_AUTO_BACKGROUND_MS = 2000;

// The number in a text value when it is above 0; otherwise undefined
function positiveNumber(text) {
  const value = Number(text);
  return value > 0 ? value : undefined;
}

const defaultTimeoutMs = positiveNumber(process.env.BASH_DEFAULT_TIMEOUT_MS) ?? DEFAULT_CALL_TIMEOUT_MS;
const maxTimeoutMs = Math.max(positiveNumber(process.env.BASH_MAX_TIMEOUT_MS) ?? MAX_CALL_TIMEOUT_MS, defaultTimeoutMs);
const autoBackgroundMs = positiveNumber(process.env.CLAUDE_CODE_AUTO_BACKGROUND_TIMEOUT_MS);
const callTimeoutMs = Math.min(
  positiveNumber(process.argv[4]) ?? defaultTimeoutMs,
  maxTimeoutMs,
  autoBackgroundMs === undefined ? Infinity : Math.max(autoBackgroundMs, MIN_AUTO_BACKGROUND_MS),
);

// When held output passes this size, the optimizer writes all output raw
const MAX_HELD_BYTES = 10 * 1024 * 1024; // 10 MB (megabytes)

if (!b64Command) {
  process.stderr.write('[smart-compress] Error: no command argument\n');
  process.exit(1);
}

// Decode the original command from base64
let cmd;
try {
  cmd = Buffer.from(b64Command, 'base64').toString('utf8');
} catch (e) {
  process.stderr.write(`[smart-compress] Decode error: ${e.message}\n`);
  process.exit(1);
}

/**
 * Detect the appropriate shell for the current platform.
 *
 * macOS/Linux: bash is always at a known location.
 * Windows: Git Bash is required by Claude Code. We check common install
 * locations, then fall back to 'bash' in PATH, then 'sh'.
 */
function getShell() {
  if (process.platform === 'win32') {
    // Git Bash common locations on Windows
    const candidates = [
      path.join(process.env.ProgramFiles || 'C:\\Program Files', 'Git', 'bin', 'bash.exe'),
      path.join(process.env['ProgramFiles(x86)'] || 'C:\\Program Files (x86)', 'Git', 'bin', 'bash.exe'),
      // Git Bash installed via scoop, chocolatey, or manual — rely on PATH
    ];
    for (const p of candidates) {
      try { if (fs.existsSync(p)) return p; } catch {}
    }
    // Fall back to PATH lookup (works if Git Bash bin is in PATH)
    return 'bash';
  }

  // macOS: /bin/bash is always present (bash 3.2+, sufficient for -c)
  // Linux: /bin/bash or /usr/bin/bash
  if (process.platform === 'darwin') return '/bin/bash';

  // Linux: prefer /bin/bash, fall back to /usr/bin/bash, then PATH
  if (fs.existsSync('/bin/bash')) return '/bin/bash';
  if (fs.existsSync('/usr/bin/bash')) return '/usr/bin/bash';
  return 'bash';
}

// Find the matching compression rule
const rule = RULES.find(r => r.type === ruleType);

/**
 * Run the command. Hold its output for compression until it ends, or write
 * the output raw from the call's time-out (or from MAX_HELD_BYTES) onwards.
 */
function run() {
  const child = spawn(getShell(), ['-c', cmd], {
    stdio: ['inherit', 'pipe', 'pipe'],
    cwd: process.cwd(),
  });
  const heldStdout = [];
  const heldStderr = [];
  let heldBytes = 0;
  let raw = false;

  // Write the held output unchanged; later output is written as it arrives
  function switchToRaw() {
    if (raw) return;
    raw = true;
    process.stdout.write(Buffer.concat(heldStdout));
    process.stderr.write(Buffer.concat(heldStderr));
  }

  function onOutput(held, stream) {
    return chunk => {
      if (raw) {
        stream.write(chunk);
        return;
      }
      held.push(chunk);
      heldBytes += chunk.length;
      if (heldBytes > MAX_HELD_BYTES) switchToRaw();
    };
  }

  child.stdout.on('data', onOutput(heldStdout, process.stdout));
  child.stderr.on('data', onOutput(heldStderr, process.stderr));
  const timer = setTimeout(switchToRaw, callTimeoutMs);

  // The shell could not be started
  child.on('error', e => {
    clearTimeout(timer);
    process.stderr.write(`[smart-compress] Execution error: ${e.message}\n`);
    switchToRaw();
    process.exit(1);
  });

  child.on('close', (status, signal) => {
    clearTimeout(timer);
    try {
      // A signal stopped the command
      if (signal) {
        switchToRaw();
        process.stderr.write(`[smart-compress] Command killed by ${signal}\n`);
        process.exitCode = 1;
        return;
      }
      if (raw) {
        process.exitCode = status;
        return;
      }
      writeResult(Buffer.concat(heldStdout).toString('utf8'), Buffer.concat(heldStderr).toString('utf8'), status);
    } catch (e) {
      // The top-level try/catch below does not reach this callback: fail open here
      process.stderr.write(`[smart-compress] Fatal error: ${e.message}, writing raw output\n`);
      switchToRaw();
      process.exitCode = 1;
    }
  });
}

/**
 * Write the output of a command that ended before the switch to raw output:
 * compressed when the rule allows it, raw otherwise.
 */
function writeResult(rawStdout, rawStderr, status) {
  // Normalize line endings (Windows CRLF -> LF)
  const stdout = rawStdout.replace(/\r\n/g, '\n');
  const stderr = rawStderr.replace(/\r\n/g, '\n');
  const exitCode = status != null ? status : 0;

  // No matching rule — pass through raw (shouldn't happen, but fail-open)
  if (!rule) {
    writeRaw(stdout, stderr, exitCode);
    return;
  }

  // If output is too short, compression isn't worth it
  const totalOutput = stdout + stderr;
  if (totalOutput.length < MIN_OUTPUT_LENGTH) {
    writeRaw(stdout, stderr, exitCode);
    return;
  }

  // Attempt compression
  let compressed = null;
  try {
    compressed = rule.compress(stdout, stderr, exitCode);
  } catch (e) {
    // Compression threw — fail-open with raw output
    process.stderr.write(`[smart-compress] Compression error (${rule.type}): ${e.message}\n`);
  }

  // Rule declined to compress (returned null) — pass through raw
  if (compressed == null) {
    writeRaw(stdout, stderr, exitCode);
    return;
  }

  // Calculate stats for transparency marker
  const originalLines = totalOutput.split('\n').filter(l => l.trim()).length;
  const compressedLines = compressed.split('\n').filter(l => l.trim()).length;

  // Output compressed result
  process.stdout.write(compressed);

  // Add transparency marker only if we actually reduced the output
  if (originalLines > compressedLines) {
    process.stdout.write(`\n[compressed: ${originalLines}->${compressedLines} lines | ${rule.type}]\n`);
  }

  // Always pass stderr through uncompressed — errors must be seen in full
  process.stderr.write(stderr);
  process.exitCode = exitCode;
}

/**
 * Write output unchanged and set the exit code. The process ends by itself
 * after the writes: on macOS, process.exit() right after a large write to a
 * pipe ends the process before the write ends, and output is lost.
 */
function writeRaw(stdout, stderr, exitCode) {
  process.stdout.write(stdout);
  process.stderr.write(stderr);
  process.exitCode = exitCode;
}

// Execute with top-level fail-open safety net
try {
  run();
} catch (e) {
  // Catastrophic failure — attempt raw execution as last resort
  process.stderr.write(`[smart-compress] Fatal error: ${e.message}, running raw\n`);
  try {
    const shell = getShell();
    const result = spawnSync(shell, ['-c', cmd], {
      encoding: 'utf8',
      stdio: ['inherit', 'pipe', 'pipe'],
    });
    process.stdout.write(result.stdout || '');
    process.stderr.write(result.stderr || '');
    process.exit(result.status != null ? result.status : 1);
  } catch {
    process.exit(1);
  }
}
