#!/usr/bin/env bash
# Test script for gemini plugin
# This script should be run from the plugin root directory

set -eo pipefail  # Exit on first error and catch failures in pipelines

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME=$(basename "$PLUGIN_DIR")
SKILL_DIR="$PLUGIN_DIR/skills/cli"
TEST_DIR="$PLUGIN_DIR/tests"

# Ensure cleanup on exit
cleanup() {
    rm -f "$TEST_DIR/tmp/integration-test-"*.txt
}
trap cleanup EXIT

# Resolve claude CLI path
if command -v claude >/dev/null 2>&1; then
    CLAUDE_CMD="claude"
elif [ -x "$HOME/.claude/local/claude" ]; then
    CLAUDE_CMD="$HOME/.claude/local/claude"
else
    CLAUDE_CMD=""
fi

# Check for gemini CLI
if command -v gemini >/dev/null 2>&1; then
    GEMINI_CMD="gemini"
else
    GEMINI_CMD=""
fi

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_SKIPPED=0

# Test helper functions
run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "  Running: $test_name"
}

pass_test() {
    echo -e "    ${GREEN}✓${NC} Passed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    local reason="$1"
    echo -e "    ${RED}✗${NC} $reason"
}

skip_test() {
    local reason="$1"
    echo -e "    ${YELLOW}⊘${NC} Skipped: $reason"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

echo "Running validation tests for $PLUGIN_NAME..."
echo

run_test "Verify SKILL.md exists"
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    pass_test
else
    fail_test "SKILL.md not found"
    exit 1
fi

run_test "Verify SKILL.md has 'name' field"
if head -20 "$SKILL_DIR/SKILL.md" | grep -q "^name:"; then
    pass_test
else
    fail_test "Frontmatter 'name' field missing"
    exit 1
fi

run_test "Verify SKILL.md has 'description' field"
if head -20 "$SKILL_DIR/SKILL.md" | grep -q "^description:"; then
    pass_test
else
    fail_test "Frontmatter 'description' field missing"
    exit 1
fi

run_test "Verify plugin.json exists and is valid JSON"
if [ ! -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]; then
    fail_test "plugin.json not found"
    exit 1
fi

if jq empty "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null; then
    pass_test
else
    fail_test "plugin.json is invalid"
    exit 1
fi

REQUIRED_FIELDS=("name" "description" "version")
for field in "${REQUIRED_FIELDS[@]}"; do
    run_test "Verify plugin.json has '$field' field"
    if jq -e ".$field" "$PLUGIN_DIR/.claude-plugin/plugin.json" > /dev/null 2>&1; then
        pass_test
    else
        fail_test "Field '$field' missing"
        exit 1
    fi
done

REFERENCE_FILES=("commands.md" "patterns.md" "templates.md" "tools.md")
for ref_file in "${REFERENCE_FILES[@]}"; do
    run_test "Verify reference file $ref_file exists"
    if [ -f "$SKILL_DIR/references/$ref_file" ]; then
        pass_test
    else
        fail_test "$ref_file missing"
        exit 1
    fi
done

run_test "End-to-end integration with Claude CLI and Gemini (locating the largest cat)"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
elif [ -z "$GEMINI_CMD" ]; then
    skip_test "gemini CLI not found"
elif ! gemini "test" -o text >/dev/null 2>&1; then
    skip_test "gemini CLI not authenticated"
else
    mkdir -p "$TEST_DIR/tmp"
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-$$.txt"
    TEST_PROMPT="Ask Gemini to use the GoogleSearch to find the current world record holder for the largest domestic cat. After Gemini is finished with its research, report back what it found."

    if "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --tools "Bash" --print "$TEST_PROMPT" 2>&1 | tee "$TEST_OUTPUT"; then
        if grep -qi "gemini" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't contain expected Gemini response"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "claude CLI execution failed"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi

    rm -f "$TEST_OUTPUT"
fi

echo
if [ "$((TESTS_PASSED + TESTS_SKIPPED))" -eq "$TESTS_RUN" ]; then
    if [ "$TESTS_SKIPPED" -gt 0 ]; then
        echo -e "${GREEN}All tests passed!${NC} ($TESTS_PASSED/$TESTS_RUN, $TESTS_SKIPPED skipped)"
    else
        echo -e "${GREEN}All tests passed!${NC} ($TESTS_PASSED/$TESTS_RUN)"
    fi
    exit 0
else
    echo -e "${RED}Some tests failed.${NC} ($TESTS_PASSED/$TESTS_RUN passed, $TESTS_SKIPPED skipped)"
    exit 1
fi
