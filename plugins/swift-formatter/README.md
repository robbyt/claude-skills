# swift-formatter

Formats Swift files with `swift-format` after Write/Edit/MultiEdit operations.

## Usage

Runs as a PostToolUse hook. No manual invocation needed.

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.swift`
4. Formats the file using the first available formatter

## Formatter Priority

1. **swiftformat** - [Nick Lockwood's SwiftFormat](https://github.com/nicklockwood/SwiftFormat) (`brew install swiftformat`). More configurable, widely adopted.
2. **swift format** - Built into Swift toolchain. Fallback if swiftformat is not installed.

## Requirements

- `swiftformat` or Swift toolchain - At least one must be available
- `jq` - JSON processor for parsing tool input

## Note

Once installed, remove any existing swift-format PostToolUse hooks from `~/.claude/settings.json` to avoid running swift-format twice.
