#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

echo "=== Swift Plugin Tests ==="

# --- Plugin structure ---

echo -n "Test 1: plugin.json is valid JSON... "
if python3 -m json.tool "$PLUGIN_DIR/.claude-plugin/plugin.json" > /dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

# --- Formatter hook ---

echo -n "Test 2: hooks.json exists and is valid JSON... "
if python3 -m json.tool "$PLUGIN_DIR/hooks/hooks.json" > /dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 3: format-swift.sh exists and is executable... "
if [ -x "$PLUGIN_DIR/scripts/format-swift.sh" ]; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 4: hooks.json references format-swift.sh... "
if grep -q "format-swift.sh" "$PLUGIN_DIR/hooks/hooks.json"; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

# --- SwiftData skill ---

echo -n "Test 5: SKILL.md exists... "
if [ -f "$PLUGIN_DIR/skills/swiftdata/SKILL.md" ]; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 6: SKILL.md has valid frontmatter... "
if head -1 "$PLUGIN_DIR/skills/swiftdata/SKILL.md" | grep -q "^---$"; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 7: SKILL.md has name and description... "
if grep -q "^name:" "$PLUGIN_DIR/skills/swiftdata/SKILL.md" && \
   grep -q "^description:" "$PLUGIN_DIR/skills/swiftdata/SKILL.md"; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 8: Description uses third person... "
if grep -A5 "^description:" "$PLUGIN_DIR/skills/swiftdata/SKILL.md" | grep -qi "this skill"; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 9: All reference files exist... "
REF_DIR="$PLUGIN_DIR/skills/swiftdata/references"
MISSING=0
for ref in core-rules.md model-patterns.md concurrency.md predicates-and-queries.md \
           performance.md migration.md migration-diagnostics.md cloudkit.md \
           audit-checklist.md known-bugs.md testing.md; do
    if [ ! -f "$REF_DIR/$ref" ]; then
        echo ""
        echo "  MISSING: $ref"
        MISSING=$((MISSING + 1))
    fi
done
if [ $MISSING -eq 0 ]; then
    echo "PASS (11 files)"
else
    echo "FAIL ($MISSING missing)"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 10: SKILL.md references all reference files... "
UNREFERENCED=0
for ref in core-rules.md model-patterns.md concurrency.md predicates-and-queries.md \
           performance.md migration.md migration-diagnostics.md cloudkit.md \
           audit-checklist.md known-bugs.md testing.md; do
    if ! grep -q "$ref" "$PLUGIN_DIR/skills/swiftdata/SKILL.md"; then
        echo ""
        echo "  UNREFERENCED: $ref"
        UNREFERENCED=$((UNREFERENCED + 1))
    fi
done
if [ $UNREFERENCED -eq 0 ]; then
    echo "PASS"
else
    echo "FAIL ($UNREFERENCED unreferenced)"
    ERRORS=$((ERRORS + 1))
fi

echo -n "Test 11: SKILL.md word count is reasonable... "
WORDS=$(wc -w < "$PLUGIN_DIR/skills/swiftdata/SKILL.md" | tr -d ' ')
if [ "$WORDS" -ge 1000 ] && [ "$WORDS" -le 5000 ]; then
    echo "PASS ($WORDS words)"
else
    echo "WARN ($WORDS words, target 1500-3000)"
fi

echo ""
echo "=== Results: $ERRORS failures ==="
exit $ERRORS
