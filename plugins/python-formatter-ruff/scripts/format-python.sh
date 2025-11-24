#!/bin/bash
# Format Python files with Ruff after Write/Edit/MultiEdit operations

# Read JSON from stdin and extract Python file path
FILE_PATH=$(jq -r '.tool_input.file_path | select(endswith(".py"))' 2>/dev/null)

# Only format if we got a .py file path and the file exists
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    ruff format "$FILE_PATH" 2>/dev/null
fi

exit 0
