# Installing Superpowers Orchestrator for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git installed

## Installation Steps

### 1. Clone Superpowers

**Unix/macOS:**
```bash
git clone https://github.com/brunob54/superpowers-orchestrator.git ~/.config/opencode/superpowers
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/brunob54/superpowers-orchestrator.git "$env:USERPROFILE\.config\opencode\superpowers"
```

### 2. Register the Plugin

Create a symlink so OpenCode discovers the plugin:

**Unix/macOS:**
```bash
mkdir -p ~/.config/opencode/plugins
rm -f ~/.config/opencode/plugins/superpowers-orchestrator.js
ln -s ~/.config/opencode/superpowers/.opencode/plugins/superpowers-orchestrator.js ~/.config/opencode/plugins/superpowers-orchestrator.js
```

> **Upgrading from a version before v7.0.0:** the plugin file was named `superpowers-optimized.js`. Remove the old symlink first: `rm -f ~/.config/opencode/plugins/superpowers-optimized.js` (PowerShell: `Remove-Item "$env:USERPROFILE\.config\opencode\plugins\superpowers-optimized.js"`).

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\plugins"
Remove-Item -Force "$env:USERPROFILE\.config\opencode\plugins\superpowers-orchestrator.js" -ErrorAction SilentlyContinue
cmd /c mklink "$env:USERPROFILE\.config\opencode\plugins\superpowers-orchestrator.js" "$env:USERPROFILE\.config\opencode\superpowers\.opencode\plugins\superpowers-orchestrator.js"
```

> **Windows note:** File symlinks require Developer Mode enabled (`Settings → For developers → Developer Mode`) or an elevated PowerShell prompt.

### 3. Symlink Skills

Create a symlink so OpenCode's native skill tool discovers superpowers skills:

**Unix/macOS:**
```bash
mkdir -p ~/.config/opencode/skills
rm -rf ~/.config/opencode/skills/superpowers
ln -s ~/.config/opencode/superpowers/skills ~/.config/opencode/skills/superpowers
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config\opencode\skills"
Remove-Item -Recurse -Force "$env:USERPROFILE\.config\opencode\skills\superpowers" -ErrorAction SilentlyContinue
cmd /c mklink /J "$env:USERPROFILE\.config\opencode\skills\superpowers" "$env:USERPROFILE\.config\opencode\superpowers\skills"
```

### 4. Restart OpenCode

Restart OpenCode. The plugin will automatically inject superpowers context.

Verify by asking: "do you have superpowers?"

## Usage

### Finding Skills

Use OpenCode's native `skill` tool to list available skills:

```
use skill tool to list skills
```

### Loading a Skill

Use OpenCode's native `skill` tool to load a specific skill:

```
use skill tool to load superpowers/brainstorming
```

### Personal Skills

Create your own skills in `~/.config/opencode/skills/`:

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

Create `~/.config/opencode/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when <specific trigger conditions>
---

# My Skill

[Your skill content here]
```

### Project Skills

Create project-specific skills in `.opencode/skills/` within your project.

**Skill Priority:** Project skills > Personal skills > Superpowers skills

## Updating

**Unix/macOS:**
```bash
cd ~/.config/opencode/superpowers && git pull
```

**Windows (PowerShell):**
```powershell
Set-Location "$env:USERPROFILE\.config\opencode\superpowers"; git pull
```

## Troubleshooting

### Plugin not loading

**Unix/macOS:**
1. Check plugin symlink: `ls -l ~/.config/opencode/plugins/superpowers-orchestrator.js`
2. Check source exists: `ls ~/.config/opencode/superpowers/.opencode/plugins/superpowers-orchestrator.js`
3. Check OpenCode logs for errors

**Windows (PowerShell):**
1. Check plugin symlink: `Get-Item "$env:USERPROFILE\.config\opencode\plugins\superpowers-orchestrator.js"`
2. Check source exists: `Test-Path "$env:USERPROFILE\.config\opencode\superpowers\.opencode\plugins\superpowers-orchestrator.js"`
3. Check OpenCode logs for errors

### Skills not found

**Unix/macOS:**
1. Check skills symlink: `ls -l ~/.config/opencode/skills/superpowers`
2. Verify it points to: `~/.config/opencode/superpowers/skills`
3. Use `skill` tool to list what's discovered

**Windows (PowerShell):**
1. Check skills junction: `Get-Item "$env:USERPROFILE\.config\opencode\skills\superpowers"`
2. Verify it points to: `$env:USERPROFILE\.config\opencode\superpowers\skills`
3. Use `skill` tool to list what's discovered

### Tool mapping

When skills reference Claude Code tools:
- `TodoWrite` → `update_plan`
- `Task` with subagents → `task` tool or `@mention` syntax (nested dispatch is off by default — see "Nested subagents" below)
- `Skill` tool → OpenCode's native `skill` tool
- File operations → your native tools

### Nested subagents

Skills such as `orchestrating-development` dispatch a controller subagent
that dispatches worker subagents (*nested dispatch*). OpenCode blocks this
by default: the `task` tool is removed from every subagent. To enable it,
you need OpenCode v1.18.2 or newer and two settings in `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "subagent_depth": 2,
  "agent": {
    "general": {
      "permission": {
        "task": { "*": "allow" }
      }
    }
  }
}
```

`subagent_depth` is a top-level key (default `1`; `2` allows
session → controller → worker). `permission.task` goes on the agent that
acts as controller; without an explicit rule OpenCode denies the `task`
tool to children even when the depth allows them.

Caveat: prompts raised by a depth-2 subagent never reach the user and the
session hangs (open OpenCode issues #13715, #39112, #43996), so unattended
pipeline runs are still not supported on OpenCode. See
`docs/platforms/opencode.md`, section "Nested Subagents", for details.

## Getting Help

- Report issues: https://github.com/brunob54/superpowers-orchestrator/issues
- Full documentation: https://github.com/brunob54/superpowers-orchestrator/blob/main/docs/platforms/opencode.md
