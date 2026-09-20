#!/usr/bin/env node
/**
 * PostToolUse Hook — File Edit Tracking
 *
 * After every Edit|Write tool use, logs the file path and timestamp
 * to a session-scoped edit log. This log feeds downstream hooks
 * (stop-reminders) to know what was changed during the session.
 *
 * Input:  stdin JSON with { tool_name, tool_input, session_id, cwd, ... }
 * Output: stdout JSON (always {}, never blocks)
 */

const fs = require('fs');
const path = require('path');
const { excludeFromGit } = require('./git-exclude');
const { LOG_DIR, editLogFile, markerFile, writeTimeFile } = require('./save-marker');

// AI-generated workspace artifacts that should never be committed
const AI_ARTIFACTS = ['project-map.md', 'session-log.md', 'state.md', 'known-issues.md'];

/**
 * Keep an AI artifact file out of `git status` without editing a tracked file.
 * Called after every Edit or Write; it acts only when the file name is in
 * AI_ARTIFACTS.
 */
function excludeArtifact(filePath) {
  if (!AI_ARTIFACTS.includes(path.basename(filePath))) return;
  excludeFromGit(filePath);
}

const SAVED_TAG = '[saved]';
const REGEXP_SPECIAL_CHARACTER = /[.*+?^${}()|[\]\\]/g;
// A Markdown heading line that holds the tag, for example `## 2026-09-20 [saved]`.
// Markdown allows up to three spaces before the `#`; four spaces start a code block.
const SAVED_HEADING = new RegExp(
  `^ {0,3}#{1,6}\\s.*${SAVED_TAG.replace(REGEXP_SPECIAL_CHARACTER, '\\$&')}`,
  'gm'
);

function countSavedHeadings(text) {
  return (String(text || '').match(SAVED_HEADING) || []).length;
}

/**
 * True when this Edit or Write of session-log.md adds a `[saved]` entry.
 * An Edit adds an entry when the new text holds more `[saved]` headings than
 * the old text. An Edit that trims an old entry, or that changes the text of
 * an entry, does not count. Limit: the payload of a Write holds no old text,
 * so every Write whose content holds the tag counts.
 */
function addsSavedEntry(toolName, toolInput) {
  if (toolName === 'Edit') {
    return countSavedHeadings(toolInput.new_string) > countSavedHeadings(toolInput.old_string);
  }
  return String(toolInput.content || '').includes(SAVED_TAG);
}

/**
 * Append an entry to the edit log of the session. The log is never rewritten
 * or trimmed here; save-marker.js deletes a log that is older than 7 days.
 * Format: ISO-timestamp | session_id | tool | file_path
 * (Legacy format without session_id is still accepted on read)
 */
function logEdit(tool, filePath, cwd, sessionId) {
  try {
    if (!fs.existsSync(LOG_DIR)) {
      fs.mkdirSync(LOG_DIR, { recursive: true });
    }

    // Resolve relative paths against cwd
    let resolved = filePath;
    if (filePath && !path.isAbsolute(filePath) && cwd) {
      resolved = path.resolve(cwd, filePath);
    }

    const sid = sessionId || '';
    const entry = `${new Date().toISOString()} | ${sid} | ${tool} | ${resolved}\n`;
    fs.appendFileSync(editLogFile(sessionId), entry);

    // Keep AI workspace artifacts out of git status on first write
    excludeArtifact(resolved);
  } catch {
    // Silently ignore logging errors — never block the tool
  }
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;

  try {
    const data = JSON.parse(input);
    const { tool_name, tool_input, cwd, session_id } = data;

    // Only track Edit and Write operations
    if (tool_name !== 'Edit' && tool_name !== 'Write') {
      process.stdout.write('{}');
      return;
    }

    const filePath = tool_input?.file_path;
    if (filePath) {
      logEdit(tool_name, filePath, cwd, session_id);

      // Track when a [saved] entry is written to session-log.md so that
      // stop-reminders can ask "any significant edits since last [saved]?"
      // rather than "any significant edits in the last 30 minutes?"
      // The marker belongs to this session, so a save by another session
      // does not reset this session's reminder.
      if (
        path.basename(filePath).toLowerCase().startsWith('session-log') &&
        addsSavedEntry(tool_name, tool_input)
      ) {
        writeTimeFile(markerFile(session_id));
      }
    }
  } catch {
    // Silently ignore parse errors
  }

  process.stdout.write('{}');
}

if (require.main === module) {
  main();
} else {
  module.exports = { logEdit, excludeArtifact, LOG_DIR };
}
