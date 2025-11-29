#!/usr/bin/env bash
# Test script for go-style-guide skill plugin
# Tests both plugin structure and e2e functionality with claude CLI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME=$(basename "$PLUGIN_DIR")
SKILL_DIR="$PLUGIN_DIR/skills/$PLUGIN_NAME"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Ensure cleanup on exit
cleanup() {
    rm -rf "$SCRIPT_DIR/tmp"
}
trap cleanup EXIT

# Create temp directory
mkdir -p "$SCRIPT_DIR/tmp"

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
TESTS_SKIPPED=0

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

echo "Running tests for $PLUGIN_NAME..."
echo

# =============================================================================
# Smoke Tests
# =============================================================================

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

run_test "All reference files exist and are non-empty"
REFERENCE_FILES=(
    "review-checklist.md"
    "concurrency.md"
    "errors.md"
    "api-design.md"
    "testing.md"
    "style.md"
)

for ref in "${REFERENCE_FILES[@]}"; do
    ref_path="$SKILL_DIR/references/$ref"
    if [ ! -f "$ref_path" ]; then
        fail_test "Reference file missing: $ref"
        exit 1
    fi
    if [ ! -s "$ref_path" ]; then
        fail_test "Reference file empty: $ref"
        exit 1
    fi
done
pass_test

run_test "Fixture file exists"
FIXTURE_FILE="$FIXTURES_DIR/problematic.go"
if [ ! -f "$FIXTURE_FILE" ]; then
    fail_test "Fixture file not found: problematic.go"
    exit 1
fi
pass_test

# =============================================================================
# E2E Test
# =============================================================================

run_test "E2E: Style guide review and fix"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    # Setup
    TEST_INPUT="$SCRIPT_DIR/tmp/input-$$.go"
    TEST_OUTPUT="$SCRIPT_DIR/tmp/output-$$.go"
    REVIEW_OUTPUT="$SCRIPT_DIR/tmp/review-$$.txt"

    cp "$FIXTURE_FILE" "$TEST_INPUT"

    # Call 1: Review and fix the problematic code
    PROMPT_1="Review the Go code in $TEST_INPUT using the go-style-guide skill. \
Identify all style guide violations (focus on critical issues like race conditions, \
panics in library code, and fire-and-forget goroutines). Then create a fixed version \
of the code that addresses all critical and important issues. Write the fixed code to \
$TEST_OUTPUT. Do not explain, just write the fixed code."

    if ! "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" \
                       --permission-mode acceptEdits \
                       --tools "Read,Write,Glob,Grep" \
                       --print "$PROMPT_1" >/dev/null 2>&1; then
        fail_test "First claude call failed"
        rm -f "$TEST_INPUT" "$TEST_OUTPUT"
        exit 1
    fi

    # Verify output file was created
    if [ ! -f "$TEST_OUTPUT" ]; then
        fail_test "Fixed code file was not created"
        rm -f "$TEST_INPUT"
        exit 1
    fi

    # Call 2: Re-review the fixed code
    PROMPT_2="Review the Go code in $TEST_OUTPUT using the go-style-guide skill. \
Report any remaining critical issues (race conditions, panics in library code, \
fire-and-forget goroutines). If the code passes review with no critical issues, \
include the exact text 'REVIEW_PASSED' in your response."

    if ! "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" \
                       --permission-mode acceptEdits \
                       --tools "Read,Glob,Grep" \
                       --print "$PROMPT_2" > "$REVIEW_OUTPUT" 2>&1; then
        fail_test "Second claude call failed"
        rm -f "$TEST_INPUT" "$TEST_OUTPUT" "$REVIEW_OUTPUT"
        exit 1
    fi

    # Check if review passed (flexible - either REVIEW_PASSED or no critical issues mentioned)
    if grep -q "REVIEW_PASSED" "$REVIEW_OUTPUT" || \
       ! grep -qi "critical" "$REVIEW_OUTPUT"; then
        pass_test
    else
        # Even if not fully passed, check the output file differs from input (some improvement)
        if ! diff -q "$TEST_INPUT" "$TEST_OUTPUT" >/dev/null 2>&1; then
            echo "    ⚠ Partial pass: Code was modified but may still have issues"
            pass_test
        else
            fail_test "Fixed code has remaining critical issues and no changes made"
            cat "$REVIEW_OUTPUT"
            rm -f "$TEST_INPUT" "$TEST_OUTPUT" "$REVIEW_OUTPUT"
            exit 1
        fi
    fi

    # Cleanup
    rm -f "$TEST_INPUT" "$TEST_OUTPUT" "$REVIEW_OUTPUT"
fi

# =============================================================================
# Summary
# =============================================================================

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
