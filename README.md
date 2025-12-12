# Claude Skills Marketplace

A collection of Claude Code skills and plugins.

> **Note:** This marketplace is under active development and has not yet reached a stable release. Skills may be renamed, reorganized, or change considerably. A stable release is expected soon.

## Installation

```bash
/plugin marketplace add robbyt/claude-skills
```

After adding the marketplace, run `/exit` and restart Claude Code with `claude --continue`.

To install individual skills:
1. Run `/plugin plugins`
2. Select `Browse and install plugins`
3. Select the `robbyt-claude-skills` marketplace

To update skills:
1. Run `/plugin plugins`
2. Select `Manage and uninstall plugins`
3. Select `robbyt-claude-skills`
4. Select the plugins to update

## Requirements

Some plugins require the following tools:

- `uv` - Python package installer and runner ([installation guide](https://docs.astral.sh/uv/getting-started/installation/))
- `jq` - JSON processor for parsing tool input

### Tool Versions

External formatters are called directly from your PATH:
- `ruff` - Python formatter (install via `uv sync`)
- `black` - Python formatter (install via `uv sync`)
- `gofmt` - Go formatter (version matches your installed Go)

For reproducible formatting, pin tool versions in your project's dependency files (`pyproject.toml`, `go.mod`, etc.).

## Security

Claude Code plugins can contain scripts that run on your local computer. Only install plugins from sources you trust. Consider enabling the sandbox feature: `/sandbox` (see [sandboxing docs](https://docs.claude.com/en/docs/claude-code/sandboxing))

## Available Plugins

### [claude-md](plugins/claude-md/)

Tools for managing CLAUDE.md memory files. Includes `reflect` skill for analyzing conversation history to improve memory files. Trigger with `reflect on this session` or `reflect on this conversation`.

[Read more →](plugins/claude-md/README.md)

### [gemini](plugins/gemini/)

Integrates the Gemini CLI for code reviews, web search via Google Search, plan review, and codebase analysis. Includes four skills: `web-search`, `diff-review`, `plan-review`, and `codebase-analysis`. Trigger with `use gemini to ...` or `ask gemini ...`.

**Requirements:** Gemini CLI v0.17.0+ ([installation guide](https://github.com/google-gemini/gemini-cli)) with authentication configured.

[Read more →](plugins/gemini/README.md)

### [gh-cli](plugins/gh-cli/)

Interacts with GitHub using the gh CLI for PR management, issues, repository operations, GitHub Actions, and viewing GitHub file links. Triggers on `gh` mentions or GitHub operations such as viewing a `github.com` link.

**Requirements:** GitHub CLI ([installation guide](https://cli.github.com/)) with authentication configured (`gh auth login`).

[Read more →](plugins/gh-cli/README.md)

### [go-formatter](plugins/go-formatter/)

Formats Go files with `gofmt` after Write/Edit/MultiEdit operations. Runs as a PostToolUse hook.

[Read more →](plugins/go-formatter/README.md)

### [go-style-guide](plugins/go-style-guide/)

Reviews Go code against a style guide combining Google and Uber Go style guides. Identifies issues not typically found by static analysis. Trigger with `review this Go code` or `review my PR`.

[Read more →](plugins/go-style-guide/README.md)

### [python-formatter-black](plugins/python-formatter-black/)

Formats Python files with `black` after Write/Edit/MultiEdit operations. Runs as a PostToolUse hook.

[Read more →](plugins/python-formatter-black/README.md)

### [python-formatter-ruff](plugins/python-formatter-ruff/)

Formats Python files with `ruff` after Write/Edit/MultiEdit operations. Runs as a PostToolUse hook. Ruff formats faster than Black.

**Note:** Do not enable both `python-formatter-ruff` and `python-formatter-black` simultaneously, as both will attempt to format the same files.

[Read more →](plugins/python-formatter-ruff/README.md)

## Development

To use locally during development:

```bash
/plugin marketplace add /path/to/claude-skills
/plugin install claude-md
```

## License

MIT
