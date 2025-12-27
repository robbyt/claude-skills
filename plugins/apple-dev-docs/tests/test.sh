#!/usr/bin/env bash
# Test script for apple-dev-docs plugin
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

# Check for npx (required for MCP server)
if command -v npx >/dev/null 2>&1; then
    NPX_CMD="npx"
else
    NPX_CMD=""
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

run_test "Validate plugin with claude CLI"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    if "$CLAUDE_CMD" plugin validate "$PLUGIN_DIR"; then
        pass_test
    else
        fail_test "Plugin validation failed"
        exit 1
    fi
fi

# Verify wrapper script exists and is executable
run_test "Verify scripts/apple-docs.sh exists"
if [ -f "$PLUGIN_DIR/scripts/apple-docs.sh" ]; then
    pass_test
else
    fail_test "scripts/apple-docs.sh not found"
    exit 1
fi

run_test "Verify scripts/apple-docs.sh is executable"
if [ -x "$PLUGIN_DIR/scripts/apple-docs.sh" ]; then
    pass_test
else
    fail_test "scripts/apple-docs.sh is not executable"
    exit 1
fi

# Verify skill exists
run_test "Verify skill apple-docs exists"
SKILL_FILE="$PLUGIN_DIR/skills/apple-docs/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
    fail_test "apple-docs/SKILL.md not found"
    exit 1
fi
pass_test

run_test "Verify skill has trigger keywords"
if grep -q "SwiftUI\|UIKit\|iOS\|macOS\|WWDC" "$SKILL_FILE"; then
    pass_test
else
    fail_test "Skill missing expected trigger keywords"
    exit 1
fi

# Test wrapper script directly with offline WWDC data
run_test "Test wrapper script with list_wwdc_years (offline data)"
if [ -z "$NPX_CMD" ]; then
    skip_test "npx not found"
else
    SCRIPT_OUTPUT=$("$PLUGIN_DIR/scripts/apple-docs.sh" list_wwdc_years '{}' 2>/dev/null || echo "")
    if echo "$SCRIPT_OUTPUT" | grep -q '"jsonrpc"'; then
        if echo "$SCRIPT_OUTPUT" | grep -q "WWDC Years\|2024\|2025"; then
            pass_test
        else
            fail_test "Response doesn't contain expected WWDC year data"
            exit 1
        fi
    else
        fail_test "No JSON-RPC response received"
        exit 1
    fi
fi

run_test "Test wrapper script with browse_wwdc_topics (offline data)"
if [ -z "$NPX_CMD" ]; then
    skip_test "npx not found"
else
    SCRIPT_OUTPUT=$("$PLUGIN_DIR/scripts/apple-docs.sh" browse_wwdc_topics '{}' 2>/dev/null || echo "")
    if echo "$SCRIPT_OUTPUT" | grep -q '"jsonrpc"'; then
        if echo "$SCRIPT_OUTPUT" | grep -q "swift\|swiftui\|machine-learning"; then
            pass_test
        else
            fail_test "Response doesn't contain expected topic data"
            exit 1
        fi
    else
        fail_test "No JSON-RPC response received"
        exit 1
    fi
fi

run_test "Test wrapper script with search_wwdc_content (offline data)"
if [ -z "$NPX_CMD" ]; then
    skip_test "npx not found"
else
    SCRIPT_OUTPUT=$("$PLUGIN_DIR/scripts/apple-docs.sh" search_wwdc_content '{"query":"SwiftUI","limit":3}' 2>/dev/null || echo "")
    if echo "$SCRIPT_OUTPUT" | grep -q '"jsonrpc"'; then
        if echo "$SCRIPT_OUTPUT" | grep -q "SwiftUI\|WWDC"; then
            pass_test
        else
            fail_test "Response doesn't contain expected SwiftUI content"
            exit 1
        fi
    else
        fail_test "No JSON-RPC response received"
        exit 1
    fi
fi

# End-to-end integration test with claude CLI
run_test "End-to-end integration with apple-docs skill"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
elif [ -z "$NPX_CMD" ]; then
    skip_test "npx not found"
else
    mkdir -p "$TEST_DIR/tmp"
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-$$.txt"
    TEST_PROMPT="Use the apple-dev-docs:apple-docs skill to find how many WWDC videos are in 2025."

    if "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --tools "Bash" --print "$TEST_PROMPT" 2>&1 | tee "$TEST_OUTPUT"; then
        if grep -qi "122\|videos\|2025" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't contain expected WWDC 2025 response"
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
