#!/usr/bin/env bash
# Test script for multimedia plugin
# Run from plugin root: ./tests/test.sh

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME=$(basename "$PLUGIN_DIR")
TEST_DIR="$PLUGIN_DIR/tests"

# Ensure cleanup on exit
cleanup() {
    rm -f "$TEST_DIR/tmp/"*.txt 2>/dev/null || true
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

# Timeout for integration tests (5 minutes)
INTEGRATION_TEST_TIMEOUT=300

# Portable timeout function (macOS doesn't have timeout)
# Usage: run_with_timeout <timeout_secs> <output_file> <command...>
run_with_timeout() {
    local timeout_secs="$1"
    local output_file="$2"
    shift 2
    ( "$@" 2>&1 | tee "$output_file" ) &
    local pid=$!
    (sleep "$timeout_secs" && kill -9 "$pid" 2>/dev/null) &
    local killer=$!
    wait "$pid" 2>/dev/null
    local result=$?
    kill "$killer" 2>/dev/null
    wait "$killer" 2>/dev/null
    return "$result"
}

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

# =============================================================================
# Plugin Structure Validation
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

run_test "Verify plugin.json exists"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
    pass_test
else
    fail_test ".claude-plugin/plugin.json not found"
    exit 1
fi

run_test "Verify plugin.json has valid JSON structure"
if python3 -c "import json; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
    pass_test
else
    fail_test "plugin.json is not valid JSON"
    exit 1
fi

run_test "Verify plugin.json has required fields"
if python3 -c "
import json
d = json.load(open('$PLUGIN_JSON'))
assert 'name' in d, 'missing name'
assert 'description' in d, 'missing description'
assert 'version' in d, 'missing version'
" 2>/dev/null; then
    pass_test
else
    fail_test "plugin.json missing required fields (name, description, version)"
    exit 1
fi

# =============================================================================
# Reference Files Validation
# =============================================================================

echo
echo "Checking reference files..."

REFERENCES=(
    "artifacts.md"
    "color-space.md"
    "encoding-commands.md"
    "hdr.md"
    "quality-myths.md"
    "telecine.md"
    "tools.md"
)

for ref_file in "${REFERENCES[@]}"; do
    run_test "Verify reference $ref_file exists"
    if [ -f "$PLUGIN_DIR/references/$ref_file" ]; then
        pass_test
    else
        fail_test "$ref_file missing from references/"
        exit 1
    fi
done

# =============================================================================
# Skills Validation
# =============================================================================

echo
echo "Checking skills..."

SKILLS=(
    "video-audit"
    "artifact-detect"
    "format-explain"
    "telecine-detect"
    "source-compare"
    "hdr-audit"
    "framerate-audit"
    "subtitle-audit"
)

for skill in "${SKILLS[@]}"; do
    run_test "Verify skill $skill exists with valid frontmatter"
    SKILL_FILE="$PLUGIN_DIR/skills/$skill/SKILL.md"

    if [ ! -f "$SKILL_FILE" ]; then
        fail_test "$skill/SKILL.md not found"
        exit 1
    fi

    # Check for name frontmatter
    if ! head -20 "$SKILL_FILE" | grep -q "^name:"; then
        fail_test "$skill missing 'name' frontmatter"
        exit 1
    fi

    # Check for description frontmatter
    if ! head -20 "$SKILL_FILE" | grep -q "^description:"; then
        fail_test "$skill missing 'description' frontmatter"
        exit 1
    fi

    pass_test
done

# =============================================================================
# E2E Integration Tests
# =============================================================================

echo
echo "Running e2e integration tests..."

run_test "E2E: video-audit skill mentions analysis tools"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    mkdir -p "$TEST_DIR/tmp"
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-video-audit-$$.txt"
    TEST_PROMPT="Use the video-audit skill. Describe what information you would gather from a video file and what tools you would use."

    if run_with_timeout "$INTEGRATION_TEST_TIMEOUT" "$TEST_OUTPUT" "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --print "$TEST_PROMPT"; then
        if grep -qi "mediainfo\|ffprobe\|codec" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't mention expected tools (mediainfo/ffprobe) or codec"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "claude CLI execution failed or timed out"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi
    rm -f "$TEST_OUTPUT"
fi

run_test "E2E: artifact-detect skill discusses visual analysis"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    mkdir -p "$TEST_DIR/tmp"
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-artifact-$$.txt"
    TEST_PROMPT="Use the artifact-detect skill. Explain your approach to detecting compression artifacts in video."

    if run_with_timeout "$INTEGRATION_TEST_TIMEOUT" "$TEST_OUTPUT" "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --print "$TEST_PROMPT"; then
        if grep -qi "blocking\|banding\|artifact\|compression" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't discuss visual artifacts (blocking/banding/compression)"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "claude CLI execution failed or timed out"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi
    rm -f "$TEST_OUTPUT"
fi

run_test "E2E: hdr-audit skill mentions HDR metadata"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    mkdir -p "$TEST_DIR/tmp"
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-hdr-$$.txt"
    TEST_PROMPT="Use the hdr-audit skill. Explain what HDR metadata you would check and how to detect fake HDR."

    if run_with_timeout "$INTEGRATION_TEST_TIMEOUT" "$TEST_OUTPUT" "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --print "$TEST_PROMPT"; then
        if grep -qi "HDR\|MaxCLL\|nits\|PQ\|tonemap" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't mention HDR terminology (HDR/MaxCLL/nits/PQ/tonemap)"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "claude CLI execution failed or timed out"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi
    rm -f "$TEST_OUTPUT"
fi

run_test "E2E: telecine-detect skill distinguishes telecine vs interlacing"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    mkdir -p "$TEST_DIR/tmp"
    TEST_OUTPUT="$TEST_DIR/tmp/integration-test-telecine-$$.txt"
    TEST_PROMPT="Use the telecine-detect skill. Explain the difference between telecined content and interlaced content, and why the distinction matters."

    if run_with_timeout "$INTEGRATION_TEST_TIMEOUT" "$TEST_OUTPUT" "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" --permission-mode bypassPermissions --print "$TEST_PROMPT"; then
        if grep -qi "telecine\|interlac\|pulldown\|IVTC" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't mention telecine/interlacing distinction"
            rm -f "$TEST_OUTPUT"
            exit 1
        fi
    else
        fail_test "claude CLI execution failed or timed out"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi
    rm -f "$TEST_OUTPUT"
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
