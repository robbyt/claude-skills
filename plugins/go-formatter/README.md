# go-formatter

Automatically formats Go files with `gofmt` after Write/Edit/MultiEdit operations.

## Usage

Runs automatically as a PostToolUse hook - no manual invocation needed.

## What it does

- Watches for Write/Edit/MultiEdit tool usage
- Detects when .go files are modified
- Automatically runs `gofmt -w` on the file
- Formats code to Go's standard style

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.go`
4. Runs `gofmt -w` to format the file in-place

## Version Information

`gofmt` is bundled with Go, so its version matches your installed Go version. No separate version pinning is needed.

Requires Go 1.16 or later.

## Note

Once this plugin is installed, you can remove the PostToolUse hook from `~/.claude/settings.json` to avoid running gofmt twice.
