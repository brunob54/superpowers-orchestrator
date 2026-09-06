#!/usr/bin/env node
/**
 * Subagent Guard — SubagentStop Hook
 *
 * Detects when subagents invoke superpowers-orchestrator skills or spawn
 * recursive sub-subagents. When detected, blocks the subagent from
 * stopping and instructs it to redo its work without skill invocations.
 * Exception: orchestrating-development dispatches controller subagents that
 * intentionally spawn nested workers — that is sanctioned design, not leakage;
 * controller returns are exempted via the orchestration report marker below.
 * A report marker exempts a message when it starts one of that message's
 * first MARKER_SEARCH_LINES non-blank lines — not only the very first line —
 * so a return that carries a sentence of narration above its marker is still
 * exempt. See hasReportMarker below.
 *
 * This is the "locked door" layer of defense — prompt-based instructions
 * ("do NOT invoke skills") are the first layer; this hook catches violations
 * that slip through.
 *
 * Logs violations to: ~/.claude/hooks-logs/subagent-violations.jsonl
 */

const fs = require('fs');
const path = require('path');

// Patterns that indicate a subagent invoked skills or spawned sub-subagents.
// Each pattern requires an action verb (invoke/invoking/using/use/run/running/called/calling)
// immediately before the skill reference so that bare mentions in file content or
// code comments do not trigger false positives.
const SKILL_NAMES = [
  'using-superpowers',
  'brainstorming',
  'deliberation',
  'writing-plans',
  'executing-plans',
  'subagent-driven-development',
  'systematic-debugging',
  'test-driven-development',
  'verification-before-completion',
  'token-efficiency',
  'context-management',
  'dispatching-parallel-agents',
  'requesting-code-review',
  'receiving-code-review',
  'finishing-a-development-branch',
  'error-recovery',
  'frontend-design',
  'claude-md-creator',
  'self-consistency-reasoner',
  'using-git-worktrees',
  'premise-check',
  'red-team',
  'refactoring',
  'performance-investigation',
  'dependency-management',
  'multi-doc-review',
  'multi-code-review',
  'researching-prior-art',
];

// Multi-doc-review reviewer reports legitimately quote skill names — they review
// documents about skills. A genuine report carries this exact marker at the
// start of one of its first MARKER_SEARCH_LINES non-blank lines
// (reviewer-prompt.md still makes it the mandatory first line); a marker
// further down the message does not count.
const REVIEW_REPORT_MARKER = '<!-- multi-review report -->';

// Orchestrating-development controller subagents return status contracts whose
// free text (e.g. a BLOCKED reason quoting a plan conflict) may legitimately
// pair action verbs with skill names. A genuine controller return carries this
// exact marker at the start of one of its first MARKER_SEARCH_LINES non-blank
// lines (the skill's prompt templates still make it the mandatory first line);
// a marker further down the message does not count.
const ORCHESTRATION_REPORT_MARKER = '<!-- orchestration report -->';

// Researching-prior-art researchers and controllers report on external
// projects whose documentation legitimately contains skill-like phrases. A
// genuine research report or summary carries this exact marker at the start of
// one of its first MARKER_SEARCH_LINES non-blank lines (research-prompt.md and
// controller-prompt.md still make it the mandatory first line); a marker
// further down the message does not count.
const RESEARCH_REPORT_MARKER = '<!-- research report -->';

// How far into a final message the marker search runs, counted in non-blank
// lines. Controllers sometimes write a sentence or a short summary above the
// marker, and every recorded case fits well inside this window. The window
// stays bounded because the exemption must remain a property of a message's
// opening: without a bound, a marker reproduced at the start of a line
// further down the message — for example an indented or fenced quotation of
// a controller return — would exempt that message too.
const MARKER_SEARCH_LINES = 10;

const REPORT_MARKERS = [
  REVIEW_REPORT_MARKER,
  ORCHESTRATION_REPORT_MARKER,
  RESEARCH_REPORT_MARKER,
];

/**
 * True when one of the first MARKER_SEARCH_LINES non-blank lines of the
 * message starts with one of the three report markers, after that line's
 * surrounding whitespace (a trailing "\r" of a CRLF message included) is
 * removed. Blank lines are skipped and do not consume the window. A line that
 * contains a marker without starting with it — a finding line quoting the
 * marker — does not exempt.
 */
function hasReportMarker(message) {
  let examined = 0;
  for (const rawLine of message.split('\n')) {
    const line = rawLine.trim();
    if (line === '') continue;
    if (REPORT_MARKERS.some(marker => line.startsWith(marker))) return true;
    examined++;
    if (examined >= MARKER_SEARCH_LINES) return false;
  }
  return false;
}

const ACTION_VERB = '(?:invoking?|using|use|running?|called?|calling|activat(?:e|ed|ing)|trigger(?:ing|ed)?|execut(?:e|ed|ing)|launch(?:ing|ed)?|spawn(?:ing|ed)?|start(?:ing|ed)?)\\s+(?:the\\s+)?';

const VIOLATION_PATTERNS = [
  /Invoke the superpowers-(?:orchestrator|optimized)/i,
  /I'm using the .+ skill/i,
  /Skill\s*\(\s*["']?superpowers/i,
  /skill:\s*["']?(superpowers|using-superpowers|brainstorming|deliberation|systematic-debugging|test-driven-development|verification|executing-plans|writing-plans|context-management|frontend-design|refactoring|performance-investigation|dependency-management|researching-prior-art)/i,
  ...SKILL_NAMES.map(name => new RegExp(ACTION_VERB + name, 'i')),
];

function logViolation(agentId, agentType, matchedPattern) {
  try {
    const logDir = path.join(process.env.HOME || process.env.USERPROFILE || '', '.claude', 'hooks-logs');
    fs.mkdirSync(logDir, { recursive: true });

    const logFile = path.join(logDir, 'subagent-violations.jsonl');
    const entry = JSON.stringify({
      timestamp: new Date().toISOString(),
      agentId,
      agentType,
      matchedPattern: matchedPattern.toString(),
      action: 'blocked'
    }) + '\n';

    fs.appendFileSync(logFile, entry);
  } catch (_) {
    // Logging must never break the hook
  }
}

function main() {
  let input = '';

  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => { input += chunk; });
  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(input);
      const lastMessage = data.last_assistant_message || '';
      const agentId = data.agent_id || 'unknown';
      const agentType = data.agent_type || 'unknown';

      if (hasReportMarker(lastMessage)) {
        process.stdout.write('{}');
        return;
      }

      // Check if the subagent's output shows evidence of skill invocation
      for (const pattern of VIOLATION_PATTERNS) {
        if (pattern.test(lastMessage)) {
          logViolation(agentId, agentType, pattern);

          // Block the subagent from stopping — force it to redo without skills
          const result = {
            decision: 'block',
            reason: [
              'SKILL LEAKAGE DETECTED: You invoked a superpowers-orchestrator skill, which is not allowed for subagents.',
              'Redo your assigned task using only your core tools (Read, Edit, Write, Bash, Grep, Glob).',
              'Do NOT invoke the Skill tool. Do NOT reference any superpowers-orchestrator skills.',
              'Focus only on the task you were given.'
            ].join(' ')
          };

          process.stdout.write(JSON.stringify(result));
          return;
        }
      }

      // No violation — allow subagent to stop normally
      process.stdout.write('{}');
    } catch (_) {
      // Parse failure — allow stop (never break the pipeline)
      process.stdout.write('{}');
    }
  });
}

main();
