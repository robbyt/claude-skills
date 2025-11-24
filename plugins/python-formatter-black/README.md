# python-formatter-black

Automatically formats Python files with `black` after Write/Edit/MultiEdit operations.

## Setup

Ensure `black` is installed and available in your PATH:

```bash
# Using pip
pip install black

# Using uv
uv tool install black

# For this repository (plugin development)
uv sync
```

The hook will use whatever `black` is in your PATH.

## Usage

Runs automatically as a PostToolUse hook - no manual invocation needed.

## What it does

- Watches for Write/Edit/MultiEdit tool usage
- Detects when .py files are modified
- Automatically runs `black` on the file
- Formats code according to Black's style

## How it works

The plugin uses a PostToolUse hook that:
1. Receives tool execution data via stdin
2. Extracts the file path using `jq`
3. Checks if the file ends with `.py`
4. Runs `black` to format the file

## Black configuration

To customize Black's formatting behavior, add a config section to your `pyproject.toml`:

```toml
[tool.black]
line-length = 100
target-version = ["py311"]
```

## Works with other formatters

This plugin runs alongside other formatter plugins (like go-formatter). Each plugin filters for its own file types and they execute in parallel without conflicts.
