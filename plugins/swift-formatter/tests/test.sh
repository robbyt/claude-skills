#!/usr/bin/env bash
# Test script for swift-formatter post-write hook
# This script should be run from the plugin root directory

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the plugin directory (script should run from plugin root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PLUGIN_DIR/tests"
HOOK_SCRIPT="$PLUGIN_DIR/scripts/format-swift.sh"
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

# Check for swift-format
if command -v swift-format >/dev/null 2>&1; then
    SWIFT_FORMAT_CMD="swift-format"
elif command -v swift >/dev/null 2>&1 && swift format --help >/dev/null 2>&1; then
    SWIFT_FORMAT_CMD="swift format"
else
    SWIFT_FORMAT_CMD=""
fi

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_SKIPPED=0

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

skip_test() {
    local reason="$1"
    echo -e "    ${YELLOW}⊘${NC} Skipped: $reason"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# Main test execution
echo "Running tests for swift-formatter hook..."
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

run_test "Hook formats Swift file (Write tool)"
if [ -z "$SWIFT_FORMAT_CMD" ]; then
    skip_test "swift-format not found"
else
    TEMP_SWIFT="$TEST_DIR/tmp/test_write.swift"
    cp "$TEST_DIR/fixtures/malformed.swift" "$TEMP_SWIFT"

    # Simulate Claude Code's JSON payload for Write tool
    echo "{\"tool_name\": \"Write\", \"tool_input\": {\"file_path\": \"$TEMP_SWIFT\"}}" | \
        "$HOOK_SCRIPT" 2>/dev/null

    # Check if file was modified (formatted files differ from malformed)
    if ! diff -q "$TEMP_SWIFT" "$TEST_DIR/fixtures/malformed.swift" >/dev/null 2>&1; then
        pass_test
    else
        fail_test "File was not formatted"
    fi
    rm -f "$TEMP_SWIFT"
fi

run_test "Hook formats Swift file (Edit tool)"
if [ -z "$SWIFT_FORMAT_CMD" ]; then
    skip_test "swift-format not found"
else
    TEMP_SWIFT="$TEST_DIR/tmp/test_edit.swift"
    cp "$TEST_DIR/fixtures/malformed.swift" "$TEMP_SWIFT"

    echo "{\"tool_name\": \"Edit\", \"tool_input\": {\"file_path\": \"$TEMP_SWIFT\"}}" | \
        "$HOOK_SCRIPT" 2>/dev/null

    if ! diff -q "$TEMP_SWIFT" "$TEST_DIR/fixtures/malformed.swift" >/dev/null 2>&1; then
        pass_test
    else
        fail_test "File was not formatted"
    fi
    rm -f "$TEMP_SWIFT"
fi

run_test "Hook ignores non-Swift files"
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
    fail_test "Hook modified non-Swift file"
    rm -f "$TEMP_TXT"
    exit 1
fi

run_test "Hook handles missing file gracefully"
MISSING_FILE="$TEST_DIR/tmp/nonexistent.swift"

if echo "{\"tool_name\": \"Write\", \"tool_input\": {\"file_path\": \"$MISSING_FILE\"}}" | \
    "$HOOK_SCRIPT" 2>/dev/null; then
    pass_test
else
    fail_test "Hook failed on missing file (should exit 0)"
    exit 1
fi

run_test "Hook rejects invalid JSON"
if echo "invalid json" | "$HOOK_SCRIPT" 2>/dev/null; then
    fail_test "Hook accepted invalid JSON (should fail)"
    exit 1
else
    pass_test
fi

# Summary
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
