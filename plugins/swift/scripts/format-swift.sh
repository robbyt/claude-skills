#!/bin/bash
set -e
# Format Swift files after Write/Edit/MultiEdit operations
#
# Uses swiftformat (brew install swiftformat) if available,
# falls back to `swift format` (built into Swift toolchain)

# Read JSON from stdin and extract Swift file path
FILE_PATH=$(jq -r '.tool_input.file_path | select(endswith(".swift"))' 2>/dev/null)

# Only format if we got a .swift file path and the file exists
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    if command -v swiftformat >/dev/null 2>&1; then
        swiftformat --quiet "$FILE_PATH" 2>/dev/null
    elif command -v swift >/dev/null 2>&1; then
        swift format --in-place "$FILE_PATH" 2>/dev/null
    fi
fi

exit 0
