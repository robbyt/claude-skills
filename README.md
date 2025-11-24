# Claude Skills Marketplace

A collection of Claude Code skills and plugins.

## Installation

```bash
/plugin marketplace add robbyt/claude-skills
```

Once that marketplace is added, you may need to run `/exit` and restart Claude Code with `claude --continue`.

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

Many of these plugins require the following tools to be installed:

- `uv` - Python package installer and runner ([installation guide](https://docs.astral.sh/uv/getting-started/installation/))
- `jq` - JSON processor for parsing tool input

### Tool Versions

External formatters are called directly from your PATH:
- `black` - Python formatter (install via `uv sync`)
- `gofmt` - Go formatter (version matches your installed Go)

For reproducible formatting, consider pinning tool versions in your project's dependency files (`pyproject.toml`, `go.mod`, etc.).

## Security

**Note:** Claude Code plugins can contain scripts that run on your local computer. Only install plugins from sources you trust!
Consider enabling the sandbox feature in Claude Code: `/sandbox` (see [sandboxing docs](https://docs.claude.com/en/docs/claude-code/sandboxing))

## Available Plugins

### [black-formatter](plugins/black-formatter/)

Automatically formats Python files with `black` after Write/Edit/MultiEdit operations and runs as a PostToolUse hook.

[Read more →](plugins/black-formatter/README.md)

### [claude-md-reflect](plugins/claude-md-reflect/)

Analyzes chat history to identify improvements for CLAUDE.md instruction files. Use the phrase `reflect on CLAUDE.md` to trigger this skill.

[Read more →](plugins/claude-md-reflect/README.md)

### [gemini-cli](plugins/gemini-cli/)

Orchestrates Gemini CLI for tasks requiring current web information via Google Search, deep codebase analysis, second AI opinions on code quality, or parallel task processing. Use the phrase `use Gemini` to trigger this skill, or it will activate when needing capabilities unique to Gemini.

**Requirements:** Gemini CLI v0.17.0+ ([installation guide](https://github.com/google-gemini/gemini-cli)) with authentication configured before use.

[Read more →](plugins/gemini-cli/README.md)

### [gh-cli](plugins/gh-cli/)

Interact with GitHub using the gh CLI for PR management, issues, repository operations, GitHub Actions, and viewing GitHub file links. This skill triggers on explicit `gh` mentions or natural language GitHub operations.

**Requirements:** GitHub CLI ([installation guide](https://cli.github.com/)) with authentication configured (`gh auth login`) before use.

[Read more →](plugins/gh-cli/README.md)

### [go-formatter](plugins/go-formatter/)

Automatically formats Go files with `gofmt` after Write/Edit/MultiEdit operations and runs as a PostToolUse hook.

[Read more →](plugins/go-formatter/README.md)

### [go-style-guide](plugins/go-style-guide/)

Reviews Go code for adherence to Go Style Guide (synthesizing Google and Uber style guides), identifies bugs, race conditions, and maintainability issues, and triggers with phrases like `review this Go code` or `review my PR`.

[Read more →](plugins/go-style-guide/README.md)

## Development

To use locally during development:

```bash
/plugin marketplace add /path/to/claude-skills
/plugin install claude-md-reflect
```

## License

MIT
