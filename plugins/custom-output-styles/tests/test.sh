#!/usr/bin/env bash
# Test script for the custom-output-styles plugin.
# Run from the plugin root directory (make test-plugin PLUGIN=custom-output-styles).
#
# Behavior of an output style is not unit-testable. These checks cover the
# structural mistakes that are silent at runtime: a missing
# keep-coding-instructions field, a stray force-for-plugin, a name that
# does not match what the README tells users to select, and repository-
# specific content in a style that applies to every repository.

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME=$(basename "$PLUGIN_DIR")
STYLES_DIR="$PLUGIN_DIR/output-styles"
MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"
README="$PLUGIN_DIR/README.md"
REPO_ROOT="$(cd "$PLUGIN_DIR/../.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

if command -v claude >/dev/null 2>&1; then
    CLAUDE_CMD="claude"
elif [ -x "$HOME/.claude/local/claude" ]; then
    CLAUDE_CMD="$HOME/.claude/local/claude"
else
    CLAUDE_CMD=""
fi

if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}Error: 'jq' is required but not installed.${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

TESTS_RUN=0
TESTS_PASSED=0
TESTS_SKIPPED=0

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo "  Running: $1"
}
pass_test() {
    echo -e "    ${GREEN}✓${NC} Passed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}
fail_test() {
    echo -e "    ${RED}✗${NC} $1"
    exit 1
}
skip_test() {
    echo -e "    ${YELLOW}⊘${NC} Skipped: $1"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# Print the YAML frontmatter block of a markdown file (lines between the
# first two '---' lines), or nothing if the file does not start with '---'.
frontmatter() {
    awk 'NR==1 && $0!="---" {exit} NR==1 {next} $0=="---" {exit} {print}' "$1"
}

# Value of a frontmatter key (first occurrence), trailing whitespace trimmed.
fm_value() {
    frontmatter "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 | sed 's/[[:space:]]*$//'
}

# Validate the frontmatter of an output style file. Prints one diagnostic and
# returns 1 on the first problem; prints nothing and returns 0 when valid.
#
# This is deliberately a narrow grammar, not a YAML parser. Claude Code output
# styles use a flat mapping of four keys with plain scalar values, so that is
# all we accept: no quotes, flow collections ([ ] { }), block scalars (| >),
# anchors, comments (#), embedded ": ", unknown keys, or duplicate keys. A file
# that passes here cannot be reinterpreted differently by a real YAML parser.
check_style_frontmatter() {
    local file="$1" line key val block seen=" "
    [ -f "$file" ] || { echo "file not found: $file"; return 1; }
    [ "$(head -1 "$file")" = "---" ] || { echo "missing opening --- on line 1"; return 1; }
    [ "$(sed -n '2,$p' "$file" | grep -c '^---$')" -ge 1 ] || { echo "missing closing ---"; return 1; }
    block=$(frontmatter "$file")
    [ -n "$block" ] || { echo "empty frontmatter block"; return 1; }
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if ! printf '%s\n' "$line" | grep -qE '^[a-z][a-z-]*: '; then
            echo "line is not 'key: value': $line"; return 1
        fi
        key=${line%%:*}
        val=${line#*: }
        case "$key" in
            name|description|keep-coding-instructions|force-for-plugin) ;;
            *) echo "unknown key: $key"; return 1 ;;
        esac
        case "$seen" in *" $key "*) echo "duplicate key: $key"; return 1 ;; esac
        seen="$seen$key "
        # Positive allowlist for values: letters, digits, spaces and . , ; ( ) / _ ' -
        if ! printf '%s\n' "$val" | grep -qE "^[A-Za-z0-9][A-Za-z0-9 .,;()/_'-]*\$"; then
            echo "value of $key is not a plain scalar (letters, digits, spaces, . , ; ( ) / _ ' - only): $val"; return 1
        fi
        case "$key" in
            name|description)
                if printf '%s\n' "$val" | grep -qiE '^(null|true|false|yes|no|on|off|[0-9.]+|[0-9]{4}-[0-9]{2}-[0-9]{2})$'; then
                    echo "$key would be read as a non-string by YAML: $val"; return 1
                fi ;;
            keep-coding-instructions|force-for-plugin)
                case "$val" in
                    true|false) ;;
                    *) echo "$key must be true or false, got: $val"; return 1 ;;
                esac ;;
        esac
    done <<< "$block"
    case "$seen" in *" name "*) ;; *) echo "missing name"; return 1 ;; esac
    case "$seen" in *" description "*) ;; *) echo "missing description"; return 1 ;; esac
    # The default for this field is false, which silently strips Claude Code's
    # own coding instructions. Every style must state its value explicitly.
    case "$seen" in *" keep-coding-instructions "*) ;; *) echo "missing keep-coding-instructions (default false silently drops the coding instructions)"; return 1 ;; esac
    return 0
}

echo "Running validation tests for $PLUGIN_NAME..."
echo

# ---------------------------------------------------------------------------
# Plugin structure
# ---------------------------------------------------------------------------

run_test "Validate plugin with claude CLI"
if [ -z "$CLAUDE_CMD" ]; then
    skip_test "claude CLI not found"
elif "$CLAUDE_CMD" plugin validate "$PLUGIN_DIR"; then
    pass_test
else
    fail_test "Plugin validation failed"
fi

run_test "plugin.json is valid JSON with required fields"
if jq -e '.name and .description and .version and .author.name and .license and (.keywords | length > 0)' "$MANIFEST" >/dev/null 2>&1; then
    pass_test
else
    fail_test "plugin.json missing one of: name, description, version, author.name, license, keywords"
fi

run_test "plugin.json name matches directory name"
if [ "$(jq -r .name "$MANIFEST")" = "$PLUGIN_NAME" ]; then
    pass_test
else
    fail_test "plugin.json name '$(jq -r .name "$MANIFEST")' != directory '$PLUGIN_NAME'"
fi

run_test "Plugin is registered in marketplace.json with matching version"
if [ ! -f "$MARKETPLACE" ]; then
    skip_test "marketplace.json not found at $MARKETPLACE"
else
    MP_VERSION=$(jq -r --arg n "$PLUGIN_NAME" '.plugins[] | select(.name==$n) | .version' "$MARKETPLACE")
    PL_VERSION=$(jq -r .version "$MANIFEST")
    if [ -z "$MP_VERSION" ]; then
        fail_test "no marketplace entry named '$PLUGIN_NAME'"
    elif [ "$MP_VERSION" != "$PL_VERSION" ]; then
        fail_test "marketplace version $MP_VERSION != plugin.json version $PL_VERSION"
    else
        pass_test
    fi
fi

run_test "output-styles/ contains at least one style"
STYLE_FILES=()
while IFS= read -r f; do STYLE_FILES+=("$f"); done < <(find "$STYLES_DIR" -maxdepth 1 -name '*.md' 2>/dev/null | sort)
if [ "${#STYLE_FILES[@]}" -gt 0 ]; then
    pass_test
else
    fail_test "no .md files in $STYLES_DIR"
fi

# ---------------------------------------------------------------------------
# Per-style frontmatter checks
# ---------------------------------------------------------------------------

for style in "${STYLE_FILES[@]}"; do
    base=$(basename "$style")

    run_test "$base: frontmatter is valid (name, description, explicit keep-coding-instructions)"
    if msg=$(check_style_frontmatter "$style"); then
        pass_test
    else
        fail_test "$base: $msg"
    fi

    run_test "$base: 'force-for-plugin' is absent"
    if frontmatter "$style" | grep -q '^force-for-plugin:'; then
        fail_test "force-for-plugin set; this plugin lets users opt in via /config"
    else
        pass_test
    fi

    run_test "$base: no repository-specific paths or names"
    # Drop line 1 ('---') through the closing '---'; what remains is the body.
    body=$(sed '1,/^---$/d' "$style")
    if [ -z "$body" ]; then
        fail_test "$base has an empty body after the frontmatter"
    fi
    # Absolute paths, home-relative paths, marketplace/repo names, plugin dirs.
    if printf '%s\n' "$body" | grep -nE '(^|[^A-Za-z0-9])(/Users/|/home/|~/|\.claude-plugin|plugins/[a-z-]+/|robbyt|claude-skills|marketplace\.json|CLAUDE\.md)' ; then
        fail_test "style contains repository-specific content (see lines above)"
    else
        pass_test
    fi
done

# ---------------------------------------------------------------------------
# The validator itself: each bad fixture must be rejected with the intended
# diagnostic, and the good fixture must pass.
# ---------------------------------------------------------------------------

FIXTURES_DIR="$SCRIPT_DIR/fixtures"
# fixture|expected diagnostic substring (empty = must pass)
FIXTURE_TABLE="good.md|
unterminated-flow.md|not a plain scalar
embedded-colon.md|not a plain scalar
embedded-hash.md|not a plain scalar
quoted-value.md|not a plain scalar
duplicate-key.md|duplicate key
missing-kci.md|missing keep-coding-instructions
bad-kci-value.md|must be true or false
bad-force-value.md|must be true or false
unknown-key.md|unknown key
no-frontmatter.md|missing opening ---
missing-closing-delimiter.md|missing closing ---
null-name.md|non-string by YAML
empty-value.md|not a plain scalar"

run_test "Frontmatter validator rejects each bad fixture with the intended diagnostic"
while IFS='|' read -r fx expected; do
    f="$FIXTURES_DIR/$fx"
    [ -f "$f" ] || fail_test "fixture missing: $fx"
    rc=0
    msg=$(check_style_frontmatter "$f") || rc=$?
    if [ -z "$expected" ]; then
        [ "$rc" -eq 0 ] || fail_test "$fx should pass, got: $msg"
    else
        [ "$rc" -ne 0 ] || fail_test "$fx should be rejected but passed"
        case "$msg" in
            *"$expected"*) ;;
            *) fail_test "$fx: expected diagnostic containing '$expected', got: $msg" ;;
        esac
    fi
done <<< "$FIXTURE_TABLE"
pass_test

# ---------------------------------------------------------------------------
# README ↔ style agreement
# ---------------------------------------------------------------------------

run_test "README tells users to select the exact frontmatter name of each style"
for style in "${STYLE_FILES[@]}"; do
    style_name=$(fm_value "$style" name)
    if ! grep -qF "**$style_name**" "$README"; then
        fail_test "README does not tell users to select **$style_name**"
    fi
    # Plugin-shipped styles are selected as "<plugin-name>:<frontmatter name>"
    # (verified empirically with --plugin-dir; the bare name does not resolve).
    if ! grep -qF "\"outputStyle\": \"$PLUGIN_NAME:$style_name\"" "$README"; then
        fail_test "README outputStyle example does not use \"$PLUGIN_NAME:$style_name\""
    fi
done
pass_test

run_test "README documents /clear, /config, and the subagent limitation"
if grep -q '/clear' "$README" && grep -q '/config' "$README" && grep -qi 'subagent' "$README"; then
    pass_test
else
    fail_test "README must mention /clear (when changes apply), /config (how to select), and subagents (where the style does not apply)"
fi

# ---------------------------------------------------------------------------
# Marketplace-wide rules, applied to every output style of every plugin:
#   - frontmatter valid, incl. an explicit keep-coding-instructions
#   - at most one plugin sets force-for-plugin: true (load order decides
#     between two, which nobody can reason about)
# ---------------------------------------------------------------------------

run_test "Marketplace-wide output-style rules (valid frontmatter, explicit keep-coding-instructions, at most one force-for-plugin)"
if [ ! -f "$MARKETPLACE" ]; then
    skip_test "marketplace.json not found"
else
    forcing=()
    scanned=0
    while IFS= read -r src; do
        # Marketplace sources are relative to the repository root.
        dir="$REPO_ROOT/$src"
        [ -d "$dir" ] || fail_test "marketplace source '$src' does not resolve to a directory"
        scanned=$((scanned + 1))
        [ -d "$dir/output-styles" ] || continue
        for f in "$dir"/output-styles/*.md; do
            [ -f "$f" ] || continue
            label="$(basename "$dir")/output-styles/$(basename "$f")"
            if ! msg=$(check_style_frontmatter "$f"); then
                fail_test "$label: $msg"
            fi
            if [ "$(fm_value "$f" force-for-plugin)" = "true" ]; then
                forcing+=("$label")
            fi
        done
    done < <(jq -r '.plugins[].source' "$MARKETPLACE")
    if [ "$scanned" -eq 0 ]; then
        fail_test "no plugin sources found in marketplace.json"
    elif [ "${#forcing[@]}" -le 1 ]; then
        pass_test
    else
        fail_test "more than one plugin forces a style (load order decides the winner): ${forcing[*]}"
    fi
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
