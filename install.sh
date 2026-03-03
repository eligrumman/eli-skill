#!/bin/bash
# Telegram Agents Master — CCBot Setup Skill Installer
# https://github.com/eligrumman/telegram-agents-master

set -e

SKILL_DIR="$HOME/.claude/skills/ccbot-setup"
REPO_URL="https://github.com/eligrumman/telegram-agents-master.git"
TEMP_DIR=$(mktemp -d)

echo "🔴🔵 Installing CCBot Setup Skill..."
echo ""

# Clone to temp directory
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null

# Create skill directory
mkdir -p "$SKILL_DIR"

# Copy skill file
cp "$TEMP_DIR/skills/ccbot-setup/SKILL.md" "$SKILL_DIR/SKILL.md"

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ Skill installed to $SKILL_DIR"
echo ""
echo "Now tell your Claude Code agent:"
echo ""
echo "  install ccbot"
echo ""
echo "The agent will offer you two pills. Choose wisely."
