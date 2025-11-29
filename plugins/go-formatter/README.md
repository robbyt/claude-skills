# go-formatter

Formats Go files with `gofmt` after Write/Edit/MultiEdit operations.

## Usage

Runs as a PostToolUse hook. No manual invocation needed.

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.go`
4. Runs `gofmt -w` to format the file in-place

## Version

`gofmt` is bundled with Go. No separate version pinning needed.

## Note

Once installed, remove any existing gofmt PostToolUse hooks from `~/.claude/settings.json` to avoid running gofmt twice.
