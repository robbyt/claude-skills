#!/usr/bin/env bash
# Test script for black-formatter post-write hook
# This script should be run from the plugin root directory

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get the plugin directory (script should run from plugin root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PLUGIN_DIR/tests"
HOOK_SCRIPT="$PLUGIN_DIR/scripts/format-python.sh"
HOOKS_JSON="$PLUGIN_DIR/hooks/hooks.json"

# Ensure cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR/tmp"
}
trap cleanup EXIT

# Create temp directory
mkdir -p "$TEST_DIR/tmp"

# Resolve claude CLI path
if command -v claude >/dev/null 2>&1; then
    CLAUDE_CMD="claude"
elif [ -x "$HOME/.claude/local/claude" ]; then
    CLAUDE_CMD="$HOME/.claude/local/claude"
else
    CLAUDE_CMD=""
fi

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function
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

# Main test execution
echo "Running tests for black-formatter hook..."
echo

run_test "Validate hooks.json schema"
if [ ! -f "$HOOKS_JSON" ]; then
    fail_test "hooks.json not found"
    exit 1
fi

if ! jq empty "$HOOKS_JSON" 2>/dev/null; then
    fail_test "hooks.json is invalid JSON"
    exit 1
fi

if ! jq -e '.hooks.PostToolUse[0].matcher' "$HOOKS_JSON" >/dev/null 2>&1; then
    fail_test "Missing PostToolUse matcher"
    exit 1
fi

if ! jq -e '.hooks.PostToolUse[0].hooks[0].command' "$HOOKS_JSON" >/dev/null 2>&1; then
    fail_test "Missing hook command"
    exit 1
fi

pass_test

run_test "Hook script exists"
if [ ! -f "$HOOK_SCRIPT" ]; then
    fail_test "Hook script not found at $HOOK_SCRIPT"
    exit 1
fi

if [ ! -x "$HOOK_SCRIPT" ]; then
    fail_test "Hook script is not executable"
    exit 1
fi

pass_test

run_test "Hook formats Python file (Write tool)"
TEMP_PY="$TEST_DIR/tmp/test_write.py"
cp "$TEST_DIR/fixtures/malformed.py" "$TEMP_PY"

# Simulate Claude Code's JSON payload for Write tool
echo "{\"tool_name\": \"Write\", \"tool_input\": {\"file_path\": \"$TEMP_PY\"}}" | \
    "$HOOK_SCRIPT" 2>/dev/null

if black --check "$TEMP_PY" >/dev/null 2>&1; then
    pass_test
    rm -f "$TEMP_PY"
else
    fail_test "File was not formatted correctly"
    rm -f "$TEMP_PY"
    exit 1
fi

run_test "Hook formats Python file (Edit tool)"
TEMP_PY="$TEST_DIR/tmp/test_edit.py"
cp "$TEST_DIR/fixtures/malformed.py" "$TEMP_PY"

echo "{\"tool_name\": \"Edit\", \"tool_input\": {\"file_path\": \"$TEMP_PY\"}}" | \
    "$HOOK_SCRIPT" 2>/dev/null

if black --check "$TEMP_PY" >/dev/null 2>&1; then
    pass_test
    rm -f "$TEMP_PY"
else
    fail_test "File was not formatted correctly"
    rm -f "$TEMP_PY"
    exit 1
fi

run_test "Hook ignores non-Python files"
TEMP_TXT="$TEST_DIR/tmp/test.txt"
echo "unformatted text" > "$TEMP_TXT"
ORIGINAL_CONTENT=$(cat "$TEMP_TXT")

echo "{\"tool_name\": \"Write\", \"tool_input\": {\"file_path\": \"$TEMP_TXT\"}}" | \
    "$HOOK_SCRIPT" 2>/dev/null

NEW_CONTENT=$(cat "$TEMP_TXT")
if [ "$ORIGINAL_CONTENT" = "$NEW_CONTENT" ]; then
    pass_test
    rm -f "$TEMP_TXT"
else
    fail_test "Hook modified non-Python file"
    rm -f "$TEMP_TXT"
    exit 1
fi

run_test "Hook handles missing file gracefully"
MISSING_FILE="$TEST_DIR/tmp/nonexistent.py"

if echo "{\"tool_name\": \"Write\", \"tool_input\": {\"file_path\": \"$MISSING_FILE\"}}" | \
    "$HOOK_SCRIPT" 2>/dev/null; then
    pass_test
else
    fail_test "Hook failed on missing file (should exit 0)"
    exit 1
fi

run_test "Hook handles invalid JSON gracefully"
if echo "invalid json" | "$HOOK_SCRIPT" 2>/dev/null; then
    pass_test
else
    fail_test "Hook failed on invalid JSON (should exit 0)"
    exit 1
fi

run_test "End-to-end integration with Claude CLI"
if [ -z "$CLAUDE_CMD" ]; then
    fail_test "claude CLI not found"
    exit 1
fi

# Create test file in plugin directory
TEST_FILE="$TEST_DIR/tmp/test-$$.py"
cp "$TEST_DIR/fixtures/malformed.py" "$TEST_FILE"

# Use claude CLI to read and write the file (triggers hook)
TEST_PROMPT="This is an automated test of the black-formatter post-write hook. Please read the \
Python file at $TEST_FILE using the Read tool, then write it back unchanged using the Write tool. \
The post-write hook will automatically format the file with Black after the write operation. Leave \
the intentionally malformed file content untouched so we can confirm the post-write hook tool is \
working correctly."

if ! "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode acceptEdits --tools "Read,Write" --print "$TEST_PROMPT"; then
    fail_test "claude CLI execution failed"
    rm -f "$TEST_FILE"
    exit 1
fi

# Verify Black formatted it
if black --check "$TEST_FILE" >/dev/null 2>&1; then
    pass_test
else
    fail_test "File not formatted by hook"
    rm -f "$TEST_FILE"
    exit 1
fi

# Cleanup
rm -f "$TEST_FILE"

# Summary
echo
if [ $TESTS_PASSED -eq $TESTS_RUN ]; then
    echo -e "${GREEN}All tests passed!${NC} ($TESTS_PASSED/$TESTS_RUN)"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC} ($TESTS_PASSED/$TESTS_RUN passed)"
    exit 1
fi
