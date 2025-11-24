# Claude Skills Marketplace

Collection of Claude Code skills and plugins that I use.

## Installation

```bash
/plugin marketplace add robbyt/claude-skills
```

Once that marketplace is added, you may need to run `/exit` and restart it with `claude --continue`.

Then install individual skills:
1. Run `/plugin plugins`
2. Select `Browse and install plugins`
3. Select the `robbyt-claude-skills` marketplace

Updating skills:
1. Run `/plugin plugins`
2. Select `Manage and uninstall plugins`
3. Select `robbyt-claude-skills`
4. Select the plugins you wish to update

## Requirements

These plugins require the following tools to be installed:

- `uv` - Python package installer and runner ([installation guide](https://docs.astral.sh/uv/getting-started/installation/))
- `jq` - JSON processor for parsing tool input

### Tool Versions

External formatters are called directly from your PATH:
- `black` - Python formatter (install via `uv sync`)
- `gofmt` - Go formatter (version matches your installed Go)
- `claudelint` - Plugin linter (if using linting features)

For reproducible formatting, consider pinning tool versions in your project's dependency files (`pyproject.toml`, `go.mod`, etc.).

## Security

**Important:** Claude Code plugins can contain scripts that run on your local computer. Only install plugins from sources you trust!
Consider enabling the sandbox feature in Claude Code: `/sandbox` (see [sandboxing docs](https://docs.claude.com/en/docs/claude-code/sandboxing))

## Available Plugins

### [claude-md-reflect](plugins/claude-md-reflect/)

Analyzes chat history to identify improvements for CLAUDE.md instruction files. Trigger with `reflect on CLAUDE.md`.

[Read more →](plugins/claude-md-reflect/README.md)

### [go-formatter](plugins/go-formatter/)

Automatically formats Go files with `gofmt` after Write/Edit/MultiEdit operations. Runs as a PostToolUse hook.

[Read more →](plugins/go-formatter/README.md)

### [black-formatter](plugins/black-formatter/)

Automatically formats Python files with `black` after Write/Edit/MultiEdit operations. Runs as a PostToolUse hook.

[Read more →](plugins/black-formatter/README.md)

### [go-style-guide](plugins/go-style-guide/)

Reviews Go code for adherence to Go Style Guide (synthesizing Google and Uber style guides). Focuses on critical bugs and important maintainability issues. Trigger with `review this Go code` or `review my PR`.

[Read more →](plugins/go-style-guide/README.md)

## Development

To use locally during development:

```bash
/plugin marketplace add /path/to/claude-skills
/plugin install claude-md-reflect
```

## License

MIT
