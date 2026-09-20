#!/usr/bin/env node
/**
 * PostToolUse Hook — Session Statistics Tracker
 *
 * Tracks skill invocations and tool usage during a session to provide
 * visibility into how the plugin is helping. Logs to a session stats file
 * that can be read by the stop-reminders hook or on user request.
 *
 * Triggered on: Skill tool use (PostToolUse matcher: Skill)
 *
 * Input:  stdin JSON with { tool_name, tool_input, session_id, cwd, ... }
 * Output: stdout JSON (always {}, never blocks)
 */

const fs = require('fs');
const { LOG_DIR, statsFile } = require('./save-marker');

/**
 * Load the stats of one session from its file, or initialize empty. The file
 * belongs to one session, so its counts never expire by age.
 */
function loadStats(file) {
  try {
    if (fs.existsSync(file)) {
      return JSON.parse(fs.readFileSync(file, 'utf8'));
    }
  } catch {
    // Corrupted file — start fresh
  }
  return createFreshStats();
}

function createFreshStats() {
  return {
    startedAt: new Date().toISOString(),
    skillInvocations: {},
    totalSkillCalls: 0,
    hookBlocks: 0,
    filesEdited: 0,
    verificationsRun: 0,
  };
}

function saveStats(file, stats) {
  try {
    if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });
    fs.writeFileSync(file, JSON.stringify(stats, null, 2));
  } catch {
    // Silently ignore
  }
}

/**
 * Format stats into a human-readable summary.
 */
function formatSummary(stats) {
  const duration = Math.round((Date.now() - new Date(stats.startedAt).getTime()) / 60000);
  const lines = [
    `Session duration: ${duration} minutes`,
    `Skills invoked: ${stats.totalSkillCalls}`,
  ];

  const sorted = Object.entries(stats.skillInvocations)
    .sort((a, b) => b[1] - a[1]);

  if (sorted.length > 0) {
    lines.push('Skill breakdown:');
    for (const [skill, count] of sorted) {
      lines.push(`  ${skill}: ${count}x`);
    }
  }

  if (stats.hookBlocks > 0) {
    lines.push(`Dangerous operations blocked: ${stats.hookBlocks}`);
  }

  if (stats.filesEdited > 0) {
    lines.push(`Files edited: ${stats.filesEdited}`);
  }

  if (stats.verificationsRun > 0) {
    lines.push(`Verifications run: ${stats.verificationsRun}`);
  }

  return lines.join('\n');
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;

  try {
    const data = JSON.parse(input);
    const { tool_name, tool_input, session_id } = data;

    if (tool_name !== 'Skill') {
      process.stdout.write('{}');
      return;
    }

    const skillName = tool_input?.skill || 'unknown';
    const file = statsFile(session_id);
    const stats = loadStats(file);

    // Track skill invocation
    stats.skillInvocations[skillName] = (stats.skillInvocations[skillName] || 0) + 1;
    stats.totalSkillCalls += 1;

    saveStats(file, stats);
  } catch {
    // Silently ignore
  }

  process.stdout.write('{}');
}

if (require.main === module) {
  main();
} else {
  module.exports = { loadStats, saveStats, formatSummary, createFreshStats };
}
