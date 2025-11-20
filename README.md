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

## Security

**Important:** Claude Code plugins can contain scripts that run on your local computer. Only install plugins from sources you trust!
Consider enabling the sandbox feature in Claude Code: `/sandbox` (see [sandboxing docs](https://docs.claude.com/en/docs/claude-code/sandboxing))

## Available Plugins

### claude-md-reflect

Analyzes chat history to identify improvements for CLAUDE.md instruction files.

**Usage:**
```
reflect on CLAUDE.md
```

**What it does:**
- Reviews session history for misunderstandings and issues
- Proposes specific CLAUDE.md improvements
- Presents changes with checkboxes for approval
- Updates CLAUDE.md files with approved changes

### go-formatter

Automatically formats Go files with `gofmt` after Write/Edit/MultiEdit operations.

**Usage:**
Runs automatically as a PostToolUse hook - no manual invocation needed.

**What it does:**
- Watches for Write/Edit/MultiEdit tool usage
- Detects when .go files are modified
- Automatically runs `gofmt -w` on the file
- Formats code to Go's standard style

**Note:** Once this plugin is installed, you can remove the PostToolUse hook from `~/.claude/settings.json` to avoid duplication.

## Development

To use locally during development:

```bash
/plugin marketplace add /path/to/claude-skills
/plugin install claude-md-reflect
```

## License

MIT
