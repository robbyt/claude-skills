#!/usr/bin/env bash
# Test script for claude-md plugin
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
REFLECT_SKILL_DIR="$SKILLS_DIR/reflect"
TEST_DIR="$PLUGIN_DIR/tests"

# Ensure cleanup on exit
cleanup() {
    rm -f "$TEST_DIR/tmp/"*.txt
    rm -f "$TEST_DIR/tmp/CLAUDE.md"
    rmdir "$TEST_DIR/tmp" 2>/dev/null || true
}
trap cleanup EXIT

# Create temp directory for tests
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

run_test "Verify all skills exist"
SKILL_NAMES=("reflect" "condense")
for skill_name in "${SKILL_NAMES[@]}"; do
    if [ ! -d "$SKILLS_DIR/$skill_name" ]; then
        fail_test "Skill directory missing: $skill_name"
        exit 1
    fi
    if [ ! -f "$SKILLS_DIR/$skill_name/SKILL.md" ]; then
        fail_test "SKILL.md missing for: $skill_name"
        exit 1
    fi
done
pass_test

run_test "Verify reference files exist"
if [ -f "$REFLECT_SKILL_DIR/references/memory-locations.md" ] && \
   [ -f "$REFLECT_SKILL_DIR/references/anti-patterns.md" ]; then
    pass_test
else
    fail_test "Reference files missing"
    exit 1
fi

run_test "Verify script exists"
if [ -f "$REFLECT_SKILL_DIR/scripts/find_claude_md.py" ]; then
    pass_test
else
    fail_test "find_claude_md.py script missing"
    exit 1
fi

run_test "Test find_claude_md.py script directly"
# Create a test CLAUDE.md file
cat > "$TEST_DIR/tmp/CLAUDE.md" << 'EOF'
# Test CLAUDE.md
- This is a test file
EOF

TEST_OUTPUT="$TEST_DIR/tmp/script-test-$$.txt"
if python3 "$REFLECT_SKILL_DIR/scripts/find_claude_md.py" "$TEST_DIR/tmp" > "$TEST_OUTPUT" 2>&1; then
    if grep -q "CLAUDE.md" "$TEST_OUTPUT"; then
        pass_test
    else
        fail_test "Script didn't find test CLAUDE.md file"
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

run_test "End-to-end integration with Claude CLI (find CLAUDE.md files)"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-$$.txt"
    TEST_PROMPT="Use the claude-md:reflect skill to find all CLAUDE.md files in the tests/tmp directory using the find_claude_md.py script. Report what files were found."

    if "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --tools "Bash" --print "$TEST_PROMPT" 2>&1 | tee "$TEST_OUTPUT"; then
        if grep -qi "CLAUDE.md" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't contain expected CLAUDE.md reference"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "Claude CLI execution failed"
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
