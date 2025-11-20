#!/bin/bash
# Format Go files with gofmt after Write/Edit/MultiEdit operations

# Read JSON from stdin and extract Go file path
FILE_PATH=$(jq -r '.tool_input.file_path | select(endswith(".go"))' 2>/dev/null)

# Only format if we got a .go file path and the file exists
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    gofmt -w "$FILE_PATH" 2>/dev/null
fi

exit 0
