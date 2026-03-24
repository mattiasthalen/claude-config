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
