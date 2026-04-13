#!/usr/bin/env bash
# Test script for api-design plugin
# Tests plugin structure and e2e functionality with claude CLI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_DIR="$PLUGIN_DIR/skills/api-review"

# Ensure cleanup on exit
cleanup() {
    rm -rf "$SCRIPT_DIR/tmp"
}
trap cleanup EXIT

mkdir -p "$SCRIPT_DIR/tmp"

# Resolve claude CLI path
if command -v claude >/dev/null 2>&1; then
    CLAUDE_CMD="claude"
elif [ -x "$HOME/.claude/local/claude" ]; then
    CLAUDE_CMD="$HOME/.claude/local/claude"
else
    CLAUDE_CMD=""
fi

# Portable timeout (macOS lacks timeout)
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

INTEGRATION_TEST_TIMEOUT=300

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

echo "Running tests for api-design..."
echo

# =============================================================================
# Plugin Structure
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

run_test "plugin.json is valid JSON"
if python3 -m json.tool "$PLUGIN_DIR/.claude-plugin/plugin.json" > /dev/null 2>&1; then
    pass_test
else
    fail_test "plugin.json is not valid JSON"
    exit 1
fi

run_test "plugin.json has required fields"
if python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
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
# Skill Structure
# =============================================================================

echo
echo "Checking skill structure..."

run_test "SKILL.md exists with valid frontmatter"
if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
    fail_test "SKILL.md not found"
    exit 1
fi
if ! head -1 "$SKILL_DIR/SKILL.md" | grep -q "^---$"; then
    fail_test "SKILL.md missing frontmatter delimiter"
    exit 1
fi
if ! head -20 "$SKILL_DIR/SKILL.md" | grep -q "^name:" || \
   ! head -20 "$SKILL_DIR/SKILL.md" | grep -q "^description:"; then
    fail_test "SKILL.md missing name or description in frontmatter"
    exit 1
fi
pass_test

run_test "All reference files exist and are non-empty"
REF_DIR="$SKILL_DIR/references"
REFERENCE_FILES=(
    "resource-oriented-design.md"
    "resource-association.md"
    "planes.md"
    "singletons.md"
    "standard-get-list.md"
    "standard-create.md"
    "standard-update.md"
    "standard-delete.md"
    "etags-and-freshness.md"
    "idempotency.md"
    "custom-methods.md"
    "declarative-interfaces.md"
    "long-running-operations.md"
    "jobs.md"
    "import-and-export.md"
    "change-validation.md"
    "cross-collection-reads.md"
    "naming-and-fields.md"
    "field-behavior.md"
    "server-modified-values.md"
    "time-and-duration.md"
    "unset-field-values.md"
    "field-masks.md"
    "sensitive-fields.md"
    "repeated-fields.md"
    "partial-responses.md"
    "pagination-and-filtering.md"
    "batch-methods.md"
    "errors.md"
    "authorization.md"
    "retry-strategy.md"
    "resource-lifecycle.md"
    "compatibility.md"
    "versioning-and-stability.md"
    "bff-architecture.md"
    "http-transcoding.md"
    "audit-checklist.md"
)
for ref in "${REFERENCE_FILES[@]}"; do
    if [ ! -f "$REF_DIR/$ref" ]; then
        fail_test "Missing: $ref"
        exit 1
    fi
    if [ ! -s "$REF_DIR/$ref" ]; then
        fail_test "Empty: $ref"
        exit 1
    fi
done
pass_test

run_test "SKILL.md references all reference files"
UNREFERENCED=0
for ref in "${REFERENCE_FILES[@]}"; do
    if ! grep -q "$ref" "$SKILL_DIR/SKILL.md"; then
        echo "      UNREFERENCED: $ref"
        UNREFERENCED=$((UNREFERENCED + 1))
    fi
done
if [ "$UNREFERENCED" -eq 0 ]; then
    pass_test
else
    fail_test "$UNREFERENCED reference files not mentioned in SKILL.md"
    exit 1
fi

# =============================================================================
# E2E Integration Tests
# =============================================================================

echo
echo "Running e2e integration tests..."

run_test "E2E: skill triggers on API review and cites AIPs"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    TEST_OUTPUT="$SCRIPT_DIR/tmp/e2e-api-review-$$.txt"
    TEST_PROMPT="Use the api-review skill. A team has designed a REST API where \
the update endpoint uses PUT instead of PATCH and has no etag field. The API also \
lacks request_id on create. What specific issues would you flag and why?"

    if run_with_timeout "$INTEGRATION_TEST_TIMEOUT" "$TEST_OUTPUT" \
        "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" \
                      --permission-mode bypassPermissions \
                      --print "$TEST_PROMPT"; then
        # Verify the skill loaded and produced AIP citations
        if grep -qi "AIP-" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output does not cite AIP numbers — skill may not have triggered"
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

run_test "E2E: skill covers BFF architecture concerns"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
else
    TEST_OUTPUT="$SCRIPT_DIR/tmp/e2e-bff-review-$$.txt"
    TEST_PROMPT="Use the api-review skill. A BFF layer has direct database connections \
and contains business logic for order approval workflows. What architectural issues \
does this raise?"

    if run_with_timeout "$INTEGRATION_TEST_TIMEOUT" "$TEST_OUTPUT" \
        "$CLAUDE_CMD" --plugin-dir "$PLUGIN_DIR" \
                      --permission-mode bypassPermissions \
                      --print "$TEST_PROMPT"; then
        if grep -qi "business logic\|backend\|BFF\|separation" "$TEST_OUTPUT" && [ -s "$TEST_OUTPUT" ]; then
            pass_test
        else
            fail_test "Output doesn't address BFF architectural concerns"
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
