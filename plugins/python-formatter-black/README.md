# python-formatter-black

Formats Python files with `black` after Write/Edit/MultiEdit operations.

## Setup

`black` must be installed and available in your PATH. See main README for installation options.

## Usage

Runs as a PostToolUse hook. No manual invocation needed.

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.py`
4. Runs `black` to format the file

## Configuration

Customize Black's formatting in `pyproject.toml`:

```toml
[tool.black]
line-length = 100
target-version = ["py311"]
```

## Note

This plugin runs alongside other formatter plugins (like go-formatter). Each plugin filters for its own file types.
