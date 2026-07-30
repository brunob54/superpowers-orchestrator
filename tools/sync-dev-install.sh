#!/usr/bin/env bash
#
# Sync this working tree into the installed superpowers-optimized plugin under
# ~/.claude, so local edits take effect in every project without pushing or
# running `claude plugin update`.
#
# What gets copied: every file git considers part of the project — tracked files
# (including uncommitted modifications) plus untracked files that are not
# gitignored. Dev-only artifacts already excluded by .gitignore (CLAUDE.md,
# state.md, session-log.md, known-issues.md, .claude/, .idea/, ...) stay out,
# which matches exactly what the marketplace installer would have placed there.
#
# Files in the install directory that are no longer in the repo are deleted, so
# the install is a mirror rather than an accumulation. The plugin's `.in_use`
# lock directory is preserved.
#
# Usage:
#   tools/sync-dev-install.sh [--dry-run] [--target DIR]
#
set -euo pipefail

PLUGIN_ID="${PLUGIN_ID:-superpowers-optimized@superpowers-optimized}"
REGISTRY="${CLAUDE_PLUGIN_REGISTRY:-$HOME/.claude/plugins/installed_plugins.json}"
LOCK_DIR=".in_use"
PLUGIN_MANIFEST=".claude-plugin/plugin.json"

# `cd` inside a command substitution echoes the resolved directory when CDPATH is
# exported, which would corrupt REPO_ROOT — neutralize it for that subshell.
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

target=""
dry_run=0

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Sync this working tree into the installed $PLUGIN_ID plugin under ~/.claude.

Usage: $(basename "${BASH_SOURCE[0]}") [--dry-run] [--target DIR]

  -n, --dry-run     show what would change without writing anything
  -t, --target DIR  install directory to sync into
                    (default: installPath from $REGISTRY)
  -h, --help        show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) dry_run=1; shift ;;
    -t|--target)  [ $# -ge 2 ] || die "--target requires a directory"; target="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *)            die "unknown argument: $1 (try --help)" ;;
  esac
done

command -v git >/dev/null 2>&1 || die "git is required"
command -v node >/dev/null 2>&1 || die "node is required to read $REGISTRY"
git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "$REPO_ROOT is not a git work tree"

# Resolve the install directory from the plugin registry unless one was given.
if [ -z "$target" ]; then
  [ -f "$REGISTRY" ] || die "plugin registry not found: $REGISTRY (pass --target DIR)"
  target="$(node -e '
    const fs = require("fs");
    const [registry, pluginId] = process.argv.slice(1);
    let data;
    try { data = JSON.parse(fs.readFileSync(registry, "utf8")); }
    catch (e) { console.error(`cannot parse ${registry}: ${e.message}`); process.exit(1); }
    const records = (data.plugins || {})[pluginId];
    if (!Array.isArray(records) || records.length === 0) {
      console.error(`no install record for ${pluginId} in ${registry}`);
      process.exit(1);
    }
    const record = records.find((r) => r.scope === "user") || records[0];
    if (!record.installPath) {
      console.error(`install record for ${pluginId} has no installPath`);
      process.exit(1);
    }
    process.stdout.write(record.installPath);
  ' "$REGISTRY" "$PLUGIN_ID")" || die "could not resolve the install directory (pass --target DIR)"
fi

[ -d "$target" ] || die "install directory does not exist: $target"
# This script deletes files under the target; make sure it really is a plugin.
[ -f "$target/$PLUGIN_MANIFEST" ] \
  || die "$target does not look like an installed plugin (no $PLUGIN_MANIFEST)"

stage="$(mktemp -d "${TMPDIR:-/tmp}/superpowers-dev-install.XXXXXX")"
trap 'rm -rf "$stage"' EXIT

# Stage the project files, then mirror the stage onto the install directory.
# Staging first is what makes deletion of removed files safe and exact.
git -C "$REPO_ROOT" ls-files -z --cached --others --exclude-standard \
  | tar -cf - -C "$REPO_ROOT" --null -T - \
  | tar -xf - -C "$stage"

rsync_opts=(-a --delete --exclude "$LOCK_DIR")
[ "$dry_run" -eq 1 ] && rsync_opts+=(-n -v)
rsync "${rsync_opts[@]}" "$stage/" "$target/"

repo_version="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo unknown)"
installed_dir_version="$(basename "$target")"

if [ "$dry_run" -eq 1 ]; then
  printf '\nDRY RUN — nothing was written.\n'
fi
printf 'source: %s (VERSION %s)\ntarget: %s\n' "$REPO_ROOT" "$repo_version" "$target"

if [ "$repo_version" != "$installed_dir_version" ]; then
  printf 'note:   the install directory is named %s while the repo is at %s.\n' \
    "$installed_dir_version" "$repo_version"
  printf '        That is harmless — Claude Code loads whatever is at the path above —\n'
  printf '        but the plugin will keep being listed as %s until a real install.\n' \
    "$installed_dir_version"
fi
printf 'Restart Claude Code (or start a new session) to pick up the changes.\n'
