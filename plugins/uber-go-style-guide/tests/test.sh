#!/usr/bin/env bash
# Test script for uber-go-style-guide skill plugin
# This script should be run from the plugin root directory

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PLUGIN_DIR="$(pwd)"
PLUGIN_NAME=$(basename "$PLUGIN_DIR")
SKILL_DIR="$PLUGIN_DIR/skills/$PLUGIN_NAME"

echo "Running validation tests for $PLUGIN_NAME..."
echo

# Test 1: Verify skill file exists
echo "  Checking skill file structure..."
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo -e "    ${GREEN}✓${NC} SKILL.md exists"
else
    echo -e "    ${RED}✗${NC} SKILL.md not found"
    exit 1
fi

# Test 2: Verify SKILL.md has required frontmatter
echo "  Validating SKILL.md frontmatter..."
if head -20 "$SKILL_DIR/SKILL.md" | grep -q "^name:"; then
    echo -e "    ${GREEN}✓${NC} Frontmatter 'name' field present"
else
    echo -e "    ${RED}✗${NC} Frontmatter 'name' field missing"
    exit 1
fi

if head -20 "$SKILL_DIR/SKILL.md" | grep -q "^description:"; then
    echo -e "    ${GREEN}✓${NC} Frontmatter 'description' field present"
else
    echo -e "    ${RED}✗${NC} Frontmatter 'description' field missing"
    exit 1
fi

# Test 3: Verify plugin.json is valid JSON
echo "  Validating plugin.json..."
if [ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    echo -e "    ${RED}✗${NC} plugin.json not found"
    exit 1
fi

if jq empty "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null; then
    echo -e "    ${GREEN}✓${NC} plugin.json is valid JSON"
else
    echo -e "    ${RED}✗${NC} plugin.json is invalid"
    exit 1
fi

# Test 4: Check for required fields in plugin.json
echo "  Checking required plugin fields..."
REQUIRED_FIELDS=("name" "description" "version")
ALL_PRESENT=true
for field in "${REQUIRED_FIELDS[@]}"; do
    if jq -e ".$field" "$PLUGIN_DIR/.claude-plugin/plugin.json" > /dev/null 2>&1; then
        echo -e "    ${GREEN}✓${NC} Field '$field' present"
    else
        echo -e "    ${RED}✗${NC} Field '$field' missing"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    exit 1
fi

# Test 5: Verify reference files exist
echo "  Checking reference files..."
if [ -f "$SKILL_DIR/references/uber-go-style-guide.md" ]; then
    echo -e "    ${GREEN}✓${NC} uber-go-style-guide.md exists"
else
    echo -e "    ${RED}✗${NC} uber-go-style-guide.md missing"
    exit 1
fi

if [ -f "$SKILL_DIR/references/review-checklist.md" ]; then
    echo -e "    ${GREEN}✓${NC} review-checklist.md exists"
else
    echo -e "    ${RED}✗${NC} review-checklist.md missing"
    exit 1
fi

echo
echo -e "${GREEN}All tests passed!${NC}"
exit 0
