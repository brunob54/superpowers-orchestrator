#!/usr/bin/env bash
# Install the statusline bridge to a stable, version-independent path.
#
# The plugin's cache directory embeds the version number
# (~/.claude/plugins/cache/.../<version>/hooks/...), so pointing
# settings.json at it breaks on every release. This script copies the
# bridge to ~/.claude/statusline/ — a path that never changes — and
# prints the settings.json snippet to wire it.
#
# Re-run after plugin updates to refresh the copy (the script is safe to
# re-run any time; it just overwrites the copy).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/../hooks/statusline-context-cache.js"
DEST_DIR="$HOME/.claude/statusline"
DEST="$DEST_DIR/statusline-context-cache.js"
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SRC" ]; then
  echo "ERROR: bridge script not found at $SRC" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "Installed: $DEST"
echo ""

if [ -f "$SETTINGS" ] && grep -qF "$DEST" "$SETTINGS"; then
  echo "Already wired: your statusLine entry in $SETTINGS points at the"
  echo "bridge. Copy refreshed — nothing else to do."
  echo ""
  echo "Re-run this script after plugin updates to refresh the installed copy."
  exit 0
fi

if [ -f "$SETTINGS" ] && grep -q '"statusLine"' "$SETTINGS"; then
  echo "You already have a statusLine configured. Use DELEGATE mode so the"
  echo "bridge caches context data and your current renderer keeps drawing"
  echo "the line — replace <your current command> below with the command"
  echo "from your existing statusLine entry:"
  echo ""
  echo '  "statusLine": {'
  echo '    "type": "command",'
  echo "    \"command\": \"node $DEST -- <your current command>\""
  echo '  }'
else
  echo "Add this to $SETTINGS:"
  echo ""
  echo '  "statusLine": {'
  echo '    "type": "command",'
  echo "    \"command\": \"node $DEST\""
  echo '  }'
fi
echo ""
echo "Optional: set the pressure-gate threshold (default 60) in the same file:"
echo '  "env": { "SUPERPOWERS_PRESSURE_THRESHOLD": "50" }'
echo ""
echo "Re-run this script after plugin updates to refresh the installed copy."
