# python-formatter-ruff

Automatically formats Python files with `ruff` after Write/Edit/MultiEdit operations.

## Setup

Ensure `ruff` is installed and available in your PATH:

```bash
# Using pip
pip install ruff

# Using uv
uv tool install ruff

# For this repository (plugin development)
uv sync
```

The hook will use whatever `ruff` is in your PATH.

## Usage

Runs automatically as a PostToolUse hook - no manual invocation needed.

## What it does

- Watches for Write/Edit/MultiEdit tool usage
- Detects when .py files are modified
- Automatically runs `ruff format` on the file
- Formats code according to Ruff's style

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.py`
4. Runs `ruff format` to format the file

## Ruff configuration

To customize Ruff's formatting behavior, add a config section to your `pyproject.toml`:

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

## Works with other formatters

This plugin runs alongside other formatter plugins (like go-formatter). Each plugin filters for its own file types and they execute in parallel without conflicts.
