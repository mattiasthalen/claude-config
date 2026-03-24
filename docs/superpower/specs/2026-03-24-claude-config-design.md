# Claude Config Design

## Problem

Global Claude Code configuration (`~/.claude/CLAUDE.md`, `settings.json`, rules) is unversioned. Changes are invisible, unsyncable across machines, and easy to lose.

## Goals

1. Version global Claude config in a dedicated git repo
2. Two-way sync via symlinks (edit in `~/.claude/` or repo, same file)
3. SessionStart hook that reports sync status on every session start
4. Simple install script to set up symlinks on any machine

## Repo Structure

```
claude-config/                    # ~/repos/claude-config/
├── CLAUDE.md                     # Global instructions
├── settings.json                 # Plugin/statusline config
├── rules/
│   └── CONVENTIONAL-COMMITS.md   # Reference rules
├── install.sh                    # Creates symlinks + installs sync script
├── .gitignore
└── docs/
    └── superpower/
        └── specs/
            └── 2026-03-24-claude-config-design.md
```

## Symlinks

Created by `install.sh`:

| Source (repo)                              | Target (`~/.claude/`)                    |
|--------------------------------------------|------------------------------------------|
| `~/repos/claude-config/CLAUDE.md`          | `~/.claude/CLAUDE.md`                    |
| `~/repos/claude-config/rules/CONVENTIONAL-COMMITS.md` | `~/.claude/CONVENTIONAL-COMMITS.md` |
| `~/repos/claude-config/settings.json`      | `~/.claude/settings.json`                |

Symlinks are inherently two-way: editing from either path modifies the same file.

## SessionStart Hook

A `SessionStart` hook in `settings.json` runs `~/.local/bin/claude-config-sync` on every session start.

### Sync Script Behavior

The script checks `~/repos/claude-config/` for:

| State | System Message |
|-------|----------------|
| All clean, up to date | "Global Claude config is in sync with origin." |
| Uncommitted changes | "Global Claude config has uncommitted changes." |
| Unpushed commits | "Global Claude config has N unpushed commit(s)." |
| Behind remote | "Global Claude config is N commit(s) behind origin." |
| Multiple issues | All applicable messages combined |

The script always returns a `systemMessage` so the user knows the hook ran.

### Hook Configuration

Added to `settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-config-sync",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## Install Script

`install.sh` is idempotent and:

1. Backs up existing files (if not already symlinks)
2. Creates symlinks from `~/.claude/` to repo files
3. Installs `claude-config-sync` to `~/.local/bin/`
4. Makes the sync script executable

## What Gets Versioned

- `CLAUDE.md` - global instructions
- `settings.json` - plugins, hooks, statusline, permissions
- `rules/CONVENTIONAL-COMMITS.md` - commit format reference

## What Does NOT Get Versioned

- `settings.local.json` - machine-specific overrides
- `.credentials.json` - auth tokens
- `history.jsonl`, `sessions/`, `file-history/` - ephemeral state
- `plugins/` - managed by Claude Code plugin system
