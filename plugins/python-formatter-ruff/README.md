# python-formatter-ruff

Formats Python files with `ruff` after Write/Edit/MultiEdit operations.

## Setup

`ruff` must be installed and available in your PATH. See main README for installation options.

## Usage

Runs as a PostToolUse hook. No manual invocation needed.

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.py`
4. Runs `ruff format` to format the file

## Configuration

Customize Ruff's formatting in `pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

## Note

Do not enable both `python-formatter-ruff` and `python-formatter-black` simultaneously.
