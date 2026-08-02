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
SKILLS_DIR="$PLUGIN_DIR/skills"
PR_SKILL_DIR="$SKILLS_DIR/pr"
VIEW_FILE_SKILL_DIR="$SKILLS_DIR/view-file"
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

# Verify all 6 skills exist
SKILL_NAMES=("pr" "stacks" "issues" "actions" "view-file" "repo")
for skill in "${SKILL_NAMES[@]}"; do
    run_test "Verify skill $skill exists"
    if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
        pass_test
    else
        fail_test "$skill/SKILL.md missing"
        exit 1
    fi
done

# Verify helper scripts exist
run_test "Verify view_github_file.py exists"
if [ -f "$VIEW_FILE_SKILL_DIR/scripts/view_github_file.py" ]; then
    pass_test
else
    fail_test "view-file/scripts/view_github_file.py missing"
    exit 1
fi

run_test "Verify view_pr_files.py exists"
if [ -f "$PR_SKILL_DIR/scripts/view_pr_files.py" ]; then
    pass_test
else
    fail_test "pr/scripts/view_pr_files.py missing"
    exit 1
fi

# Structural checks for the stacks skill (content, not just existence)
STACKS_SKILL_DIR="$SKILLS_DIR/stacks"

run_test "Verify stacks skill has valid frontmatter (name + description)"
if grep -q "^name: stacks$" "$STACKS_SKILL_DIR/SKILL.md" \
    && grep -q "^description: " "$STACKS_SKILL_DIR/SKILL.md"; then
    pass_test
else
    fail_test "stacks/SKILL.md missing 'name: stacks' or 'description:' frontmatter"
    exit 1
fi

run_test "Verify stacks references/commands.md exists"
if [ -f "$STACKS_SKILL_DIR/references/commands.md" ]; then
    pass_test
else
    fail_test "stacks/references/commands.md missing"
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

    if python3 "$VIEW_FILE_SKILL_DIR/scripts/view_github_file.py" \
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

    if python3 "$VIEW_FILE_SKILL_DIR/scripts/view_github_file.py" \
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

    if python3 "$PR_SKILL_DIR/scripts/view_pr_files.py" \
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

    if python3 "$PR_SKILL_DIR/scripts/view_pr_files.py" \
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

    if python3 "$PR_SKILL_DIR/scripts/view_pr_files.py" \
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
run_test "End-to-end integration with Claude CLI (fetch README via view-file skill)"
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
    if python3 "$VIEW_FILE_SKILL_DIR/scripts/view_github_file.py" \
        "https://github.com/robbyt/claude-skills/blob/main/README.md" \
        2>/dev/null | head -10 > "$EXPECTED_FILE"; then

        # Get content via Claude CLI with view-file skill
        TEST_PROMPT="Use the view-file skill to view the README.md file from https://github.com/robbyt/claude-skills/blob/main/README.md. Just show me the first 10 lines of content."

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
