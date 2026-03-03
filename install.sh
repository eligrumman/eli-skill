#!/bin/bash
# eli — Your Claude Code Expert
# https://github.com/eligrumman/eli-skill

set -e

SKILL_DIR="$HOME/.claude/skills/eli"
REPO_URL="https://github.com/eligrumman/eli-skill.git"
TEMP_DIR=$(mktemp -d)

echo "Installing eli..."
echo ""

# Clone to temp directory
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null

# Create skill directory
mkdir -p "$SKILL_DIR"

# Copy skill file
cp "$TEMP_DIR/skills/eli/SKILL.md" "$SKILL_DIR/SKILL.md"

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ eli installed to $SKILL_DIR"
echo ""
echo "Now tell your Claude Code agent:"
echo ""
echo "  eli help me install ccbot"
echo ""
