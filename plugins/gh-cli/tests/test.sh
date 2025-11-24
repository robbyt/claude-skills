#!/usr/bin/env bash
# Test script for gh-cli plugin
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
SKILL_DIR="$PLUGIN_DIR/skills/gh-cli"
TEST_DIR="$PLUGIN_DIR/tests"

# Ensure cleanup on exit
cleanup() {
    rm -f "$TEST_DIR/tmp/"*.txt
    rm -f "$TEST_DIR/tmp/"*.diff
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

# Check for gh CLI
if command -v gh >/dev/null 2>&1; then
    GH_CMD="gh"
else
    GH_CMD=""
fi

# Check for jq (required for JSON parsing)
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}Error: 'jq' is required but not installed.${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Create temp directory for tests
mkdir -p "$TEST_DIR/tmp"

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

# Basic structure validation
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

# Verify helper scripts exist and are executable
HELPER_SCRIPTS=("view_github_file.py" "view_pr_files.py")
for script in "${HELPER_SCRIPTS[@]}"; do
    run_test "Verify helper script $script exists"
    if [ -f "$SKILL_DIR/scripts/$script" ]; then
        pass_test
    else
        fail_test "$script missing"
        exit 1
    fi

    run_test "Verify $script is executable"
    if [ -x "$SKILL_DIR/scripts/$script" ]; then
        pass_test
    else
        fail_test "$script is not executable"
        exit 1
    fi
done

run_test "Verify references directory exists"
if [ -d "$SKILL_DIR/references" ]; then
    pass_test
else
    fail_test "references/ directory missing"
    exit 1
fi

# Integration tests with helper scripts
run_test "Test view_github_file.py with real GitHub URL (README.md)"
if [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    TEST_OUTPUT="$TEST_DIR/tmp/readme-test-$$.txt"

    if python3 "$SKILL_DIR/scripts/view_github_file.py" \
        "https://github.com/robbyt/claude-skills/blob/main/README.md" \
        > "$TEST_OUTPUT" 2>&1; then

        if grep -q "Claude Skills" "$TEST_OUTPUT" || grep -q "claude-skills" "$TEST_OUTPUT"; then
            pass_test
        else
            fail_test "Output doesn't contain expected README content"
            cat "$TEST_OUTPUT"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "Script execution failed"
        cat "$TEST_OUTPUT"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi

    rm -f "$TEST_OUTPUT"
fi

run_test "Test view_github_file.py error handling (invalid URL)"
if [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    TEST_OUTPUT="$TEST_DIR/tmp/invalid-url-test-$$.txt"

    if python3 "$SKILL_DIR/scripts/view_github_file.py" \
        "https://invalid-url" \
        > "$TEST_OUTPUT" 2>&1; then
        fail_test "Script should have failed with invalid URL"
        rm -f "$TEST_OUTPUT"
        exit 1
    else
        if grep -qi "error" "$TEST_OUTPUT" || grep -qi "invalid" "$TEST_OUTPUT"; then
            pass_test
        else
            fail_test "Expected error message not found"
            cat "$TEST_OUTPUT"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    fi

    rm -f "$TEST_OUTPUT"
fi

run_test "Test view_pr_files.py --list with real PR"
if [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    TEST_OUTPUT="$TEST_DIR/tmp/pr-list-test-$$.txt"

    if python3 "$SKILL_DIR/scripts/view_pr_files.py" \
        "https://github.com/robbyt/claude-skills/pull/1" \
        --list \
        > "$TEST_OUTPUT" 2>&1; then

        if [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output is empty, expected list of files"
            cat "$TEST_OUTPUT"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "Script execution failed"
        cat "$TEST_OUTPUT"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi

    rm -f "$TEST_OUTPUT"
fi

run_test "Test view_pr_files.py --diff with real PR"
if [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    TEST_OUTPUT="$TEST_DIR/tmp/pr-diff-test-$$.diff"

    if python3 "$SKILL_DIR/scripts/view_pr_files.py" \
        "1" \
        --diff \
        > "$TEST_OUTPUT" 2>&1; then

        if [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output is empty, expected diff content"
            cat "$TEST_OUTPUT"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "Script execution failed"
        cat "$TEST_OUTPUT"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi

    rm -f "$TEST_OUTPUT"
fi

run_test "Test view_pr_files.py error handling (invalid PR)"
if [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    TEST_OUTPUT="$TEST_DIR/tmp/invalid-pr-test-$$.txt"

    if python3 "$SKILL_DIR/scripts/view_pr_files.py" \
        "999999" \
        --list \
        > "$TEST_OUTPUT" 2>&1; then
        fail_test "Script should have failed with invalid PR"
        rm -f "$TEST_OUTPUT"
        exit 1
    else
        if grep -qi "error" "$TEST_OUTPUT" || grep -qi "not found" "$TEST_OUTPUT"; then
            pass_test
        else
            fail_test "Expected error message not found"
            cat "$TEST_OUTPUT"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    fi

    rm -f "$TEST_OUTPUT"
fi

# gh CLI availability test
run_test "Check gh CLI availability and authentication"
if [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    pass_test
fi

# End-to-end integration test with Claude CLI
run_test "End-to-end integration with Claude CLI (fetch README via gh-cli)"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
elif [ -z "$GH_CMD" ]; then
    skip_test "gh CLI not found"
elif ! gh auth status >/dev/null 2>&1; then
    skip_test "gh CLI not authenticated"
else
    EXPECTED_FILE="$TEST_DIR/tmp/expected-readme-$$.txt"
    ACTUAL_FILE="$TEST_DIR/tmp/integration-test-$$.txt"

    # Get expected content directly from helper script (first 10 lines)
    if python3 "$SKILL_DIR/scripts/view_github_file.py" \
        "https://github.com/robbyt/claude-skills/blob/main/README.md" \
        2>/dev/null | head -10 > "$EXPECTED_FILE"; then

        # Get content via Claude CLI with gh-cli skill
        TEST_PROMPT="Use the gh-cli skill to view the README.md file from https://github.com/robbyt/claude-skills/blob/main/README.md. Just show me the first 10 lines of content."

        if "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --tools "Bash" --print "$TEST_PROMPT" > "$ACTUAL_FILE" 2>&1; then
            # Check if Claude's output contains the expected content
            EXPECTED_CONTENT=$(cat "$EXPECTED_FILE")

            if grep -qF "$EXPECTED_CONTENT" "$ACTUAL_FILE"; then
                pass_test
            else
                skip_test "Output doesn't match expected README content"
            fi
        else
            skip_test "Claude CLI execution failed"
        fi
    else
        skip_test "Failed to fetch expected content"
    fi

    rm -f "$EXPECTED_FILE" "$ACTUAL_FILE"
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
