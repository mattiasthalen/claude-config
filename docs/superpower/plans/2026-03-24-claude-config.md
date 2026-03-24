# Claude Config Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Version global Claude Code configuration in a git repo with symlinks and a SessionStart sync hook.

**Architecture:** Config files live in `~/repos/claude-config/`, symlinked into `~/.claude/`. A bash script checks git status on session start and reports via JSON `systemMessage`.

**Tech Stack:** Bash, git, Claude Code hooks (SessionStart)

---

## Parallelization

Tasks 1, 2, and 3 are independent and can run in parallel.
Task 4 depends on all three.
Task 5 depends on Task 4.

```
[Task 1: sync script] ──┐
[Task 2: config files] ──┼── [Task 4: install.sh] ── [Task 5: run install + verify]
[Task 3: .gitignore]  ──┘
```

---

### Task 1: Create the sync script

**Files:**
- Create: `bin/claude-config-sync`

**Step 1: Write the sync script**

This script is called by the SessionStart hook. It checks `~/repos/claude-config/` for uncommitted changes, unpushed commits, and behind-remote status. It always outputs JSON with a `systemMessage`.

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${CLAUDE_CONFIG_DIR:-$HOME/repos/claude-config}"

# If repo doesn't exist, warn and exit
if [ ! -d "$REPO_DIR/.git" ]; then
  echo '{"systemMessage":"claude-config repo not found at '"$REPO_DIR"'. Run install.sh first."}'
  exit 0
fi

cd "$REPO_DIR"

messages=()

# Check for uncommitted changes (staged + unstaged + untracked)
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  messages+=("has uncommitted changes")
fi

# Check for unpushed commits
unpushed=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
if [ "$unpushed" -gt 0 ]; then
  messages+=("has $unpushed unpushed commit(s)")
fi

# Check if behind remote (fetch first, with timeout)
git fetch --quiet 2>/dev/null || true
behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
if [ "$behind" -gt 0 ]; then
  messages+=("is $behind commit(s) behind origin")
fi

# Build message
if [ ${#messages[@]} -eq 0 ]; then
  msg="Global Claude config is in sync with origin."
else
  # Join messages with ", "
  combined=$(printf ", %s" "${messages[@]}")
  combined=${combined:2}  # strip leading ", "
  msg="Global Claude config $combined."
fi

# Output JSON for the hook
printf '{"systemMessage":"%s"}\n' "$msg"
```

**Step 2: Verify the script runs**

Run: `bash bin/claude-config-sync`
Expected: JSON output like `{"systemMessage":"Global Claude config has uncommitted changes."}`

**Step 3: Commit**

```bash
git add bin/claude-config-sync
git commit -m "feat: add sync script for SessionStart hook"
```

---

### Task 2: Copy config files into repo

**Files:**
- Create: `CLAUDE.md` (copy from `~/.claude/CLAUDE.md`)
- Create: `rules/CONVENTIONAL-COMMITS.md` (copy from `~/.claude/CONVENTIONAL-COMMITS.md`)
- Create: `settings.json` (copy from `~/.claude/settings.json` + add SessionStart hook)

**Step 1: Copy CLAUDE.md**

Copy `~/.claude/CLAUDE.md` verbatim to repo root.

**Step 2: Copy CONVENTIONAL-COMMITS.md**

```bash
mkdir -p rules
cp ~/.claude/CONVENTIONAL-COMMITS.md rules/CONVENTIONAL-COMMITS.md
```

**Step 3: Copy settings.json and add SessionStart hook**

Copy `~/.claude/settings.json` and add the hook configuration. The final `settings.json` should be the existing content plus:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/claude-config-sync",
            "timeout": 10,
            "statusMessage": "Checking global Claude config sync status..."
          }
        ]
      }
    ]
  }
}
```

Merge this into the existing settings.json (don't replace).

**Step 4: Commit**

```bash
git add CLAUDE.md rules/CONVENTIONAL-COMMITS.md settings.json
git commit -m "feat: add config files and SessionStart hook"
```

---

### Task 3: Create .gitignore

**Files:**
- Create: `.gitignore`

**Step 1: Write .gitignore**

```
# Machine-specific
settings.local.json

# Editor
*.swp
*.swo
*~
```

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: add .gitignore"
```

---

### Task 4: Create install script

**Depends on:** Tasks 1, 2, 3

**Files:**
- Create: `install.sh`

**Step 1: Write install.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BIN_DIR="$HOME/.local/bin"

echo "Installing claude-config..."

# Ensure directories exist
mkdir -p "$CLAUDE_DIR"
mkdir -p "$BIN_DIR"

# Files to symlink: source (relative to SCRIPT_DIR) -> target
declare -A SYMLINKS=(
  ["CLAUDE.md"]="$CLAUDE_DIR/CLAUDE.md"
  ["rules/CONVENTIONAL-COMMITS.md"]="$CLAUDE_DIR/CONVENTIONAL-COMMITS.md"
  ["settings.json"]="$CLAUDE_DIR/settings.json"
)

for src_rel in "${!SYMLINKS[@]}"; do
  src="$SCRIPT_DIR/$src_rel"
  target="${SYMLINKS[$src_rel]}"

  # Skip if already correctly symlinked
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
    echo "  OK: $target -> $src_rel (already linked)"
    continue
  fi

  # Backup existing file (if it exists and is not a symlink)
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backup: $target -> $backup"
    mv "$target" "$backup"
  fi

  # Remove existing symlink if pointing elsewhere
  if [ -L "$target" ]; then
    rm "$target"
  fi

  # Create symlink
  ln -s "$src" "$target"
  echo "  Linked: $target -> $src_rel"
done

# Install sync script
SYNC_SRC="$SCRIPT_DIR/bin/claude-config-sync"
SYNC_TARGET="$BIN_DIR/claude-config-sync"

if [ -L "$SYNC_TARGET" ] && [ "$(readlink -f "$SYNC_TARGET")" = "$(readlink -f "$SYNC_SRC")" ]; then
  echo "  OK: $SYNC_TARGET (already linked)"
else
  [ -L "$SYNC_TARGET" ] && rm "$SYNC_TARGET"
  ln -s "$SYNC_SRC" "$SYNC_TARGET"
  chmod +x "$SYNC_SRC"
  echo "  Linked: $SYNC_TARGET -> bin/claude-config-sync"
fi

echo ""
echo "Done! Restart Claude Code for the SessionStart hook to take effect."
```

**Step 2: Make it executable**

```bash
chmod +x install.sh
```

**Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: add install script for symlinks and sync"
```

---

### Task 5: Run install and verify end-to-end

**Depends on:** Task 4

**Step 1: Run install.sh**

```bash
cd ~/repos/claude-config && bash install.sh
```

Expected output: symlink confirmations for each file.

**Step 2: Verify symlinks**

```bash
readlink ~/.claude/CLAUDE.md
readlink ~/.claude/CONVENTIONAL-COMMITS.md
readlink ~/.claude/settings.json
readlink ~/.local/bin/claude-config-sync
```

Each should point to the corresponding file in `~/repos/claude-config/`.

**Step 3: Verify sync script works**

```bash
claude-config-sync
```

Expected: JSON with systemMessage.

**Step 4: Verify settings.json is valid**

```bash
jq -e '.hooks.SessionStart[0].hooks[0].command' ~/.claude/settings.json
```

Expected: `"~/.local/bin/claude-config-sync"`

**Step 5: Push all commits**

```bash
git push
```

**Step 6: Commit**

No new commit needed -- just push existing commits.
