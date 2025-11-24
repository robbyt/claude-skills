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
- `ruff` - Python formatter (install via `uv sync`)
- `black` - Python formatter (install via `uv sync`)
- `gofmt` - Go formatter (version matches your installed Go)

For reproducible formatting, consider pinning tool versions in your project's dependency files (`pyproject.toml`, `go.mod`, etc.).

## Security

**Note:** Claude Code plugins can contain scripts that run on your local computer. Only install plugins from sources you trust!
Consider enabling the sandbox feature in Claude Code: `/sandbox` (see [sandboxing docs](https://docs.claude.com/en/docs/claude-code/sandboxing))

## Available Plugins

### [python-formatter-black](plugins/python-formatter-black/)

Automatically formats Python files with `black` after Write/Edit/MultiEdit operations and runs as a PostToolUse hook.

[Read more →](plugins/python-formatter-black/README.md)

### [python-formatter-ruff](plugins/python-formatter-ruff/)

Automatically formats Python files with `ruff` after Write/Edit/MultiEdit operations and runs as a PostToolUse hook. Recommended Python formatter.

[Read more →](plugins/python-formatter-ruff/README.md)

### [claude-md-reflect](plugins/claude-md-reflect/)

Analyzes chat history to identify improvements for CLAUDE.md instruction files. Use the phrase `reflect on CLAUDE.md` to trigger this skill.

[Read more →](plugins/claude-md-reflect/README.md)

### [gemini-cli](plugins/gemini-cli/)

Uses the Gemini CLI for a "second opinion" on code reviews, debugging, web search via Google Search, or planning. Triggers with `use gemini to ...`, or `ask gemini ...`.

**Requirements:** Gemini CLI v0.17.0+ ([installation guide](https://github.com/google-gemini/gemini-cli)) with authentication configured before use.

[Read more →](plugins/gemini-cli/README.md)

### [gh-cli](plugins/gh-cli/)

Interact with GitHub using the gh CLI for PR management, issues, repository operations, GitHub Actions, and viewing GitHub file links. This skill triggers on explicit `gh` mentions, or other implied GitHub operations such as viewing a file from a `github.com` link, or viewing a patch from a PR.

**Requirements:** GitHub CLI ([installation guide](https://cli.github.com/)) with authentication configured (`gh auth login`) before use.

[Read more →](plugins/gh-cli/README.md)

### [go-formatter](plugins/go-formatter/)

Automatically formats Go files with `gofmt` after Write/Edit/MultiEdit operations and runs as a PostToolUse hook.

[Read more →](plugins/go-formatter/README.md)

### [go-style-guide](plugins/go-style-guide/)

Reviews Go code for adherence to the Go Style Guide (which is my personal combo of the Google and Uber style guides.) It identifies issues that are not typically found by static analysis. Trigger this action with phrases like `review this Go code` or `review my PR`.

[Read more →](plugins/go-style-guide/README.md)

## Development

To use locally during development:

```bash
/plugin marketplace add /path/to/claude-skills
/plugin install claude-md-reflect
```

## License

MIT
