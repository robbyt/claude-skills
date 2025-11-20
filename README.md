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

For security and reproducibility, external tools are version-pinned.

Override versions by setting environment variables:

```bash
export BLACK_VERSION="24.8.0"
export CLAUDELINT_VERSION="0.1.1"
```

Available environment variables:
- `BLACK_VERSION` - Black Python formatter
- `CLAUDELINT_VERSION` - Plugin linter
- `gofmt` - Version matches your installed Go (no env var needed)

See individual plugin READMEs for details.

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

## Development

To use locally during development:

```bash
/plugin marketplace add /path/to/claude-skills
/plugin install claude-md-reflect
```

## License

MIT
