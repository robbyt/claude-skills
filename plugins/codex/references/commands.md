# Codex CLI Quick Reference

For complete documentation, see [official Codex CLI docs](https://github.com/openai/codex).

## MCP Tools (Preferred)

When the Codex MCP server is running, use these tools:

### `mcp__plugin_codex_cli__codex`

Start a new Codex session:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Your prompt here",
  "sandbox": "read-only"
})
```

**Parameters:**
| Parameter | Required | Description |
|-----------|----------|-------------|
| `prompt` | Yes | The task or question |
| `sandbox` | No | `read-only` (default), `workspace-write`, or `danger-full-access` |
| `approval-policy` | No | Approval behavior |
| `cwd` | No | Set working directory |
| `model` | No | Specify model |

**Note:** Tool name may vary by installation. Check available tools for exact name.

### `mcp__plugin_codex_cli__codex-reply`

Continue an existing conversation:

```
mcp__plugin_codex_cli__codex-reply({
  "prompt": "Follow-up question",
  "conversationId": "abc123"
})
```

### When to Use MCP vs Bash

| Use MCP when... | Use Bash when... |
|-----------------|------------------|
| MCP server is available | MCP unavailable |
| Need session continuity | One-off commands |
| Cleaner integration | Debugging issues |

## Bash Fallback

## Basic Usage

```bash
# Interactive mode
codex "prompt"

# Non-interactive execution
codex exec "prompt" --sandbox read-only

# Code review (requires --uncommitted, --base, or --commit)
codex review --uncommitted
```

## Common Options for `codex exec`

| Option | Description |
|--------|-------------|
| `--sandbox read-only` | Most restrictive: read files only, no writes or command execution |
| `--sandbox workspace-write` | Can write to workspace and /tmp |
| `-m MODEL` | Specify model |
| `-C DIR` | Set working directory |

## Options for main `codex` command only

| Option | Description |
|--------|-------------|
| `--search` | Enable web search (not available on `codex exec`) |
| `--sandbox` | Set sandbox mode |

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `exec` | `e` | Non-interactive execution |
| `review` | | Code review (top-level or via `exec review`) |
| `resume` | | Resume previous session |
| `apply` | `a` | Apply diff to working tree |
| `login` | | Authenticate |
| `logout` | | Remove credentials |

## Review Command Options

The `codex review` command requires one of:

| Option | Description |
|--------|-------------|
| `--uncommitted` | Review uncommitted changes |
| `--base <branch>` | Review changes against a base branch |
| `--commit <sha>` | Review a specific commit |

## Examples

```bash
# Analyze codebase (read-only)
codex exec "Analyze this project structure" --sandbox read-only

# Code review of uncommitted changes
codex review --uncommitted

# Code review against main branch
codex review --base main

# Web search (uses main command, not exec)
codex "Search for latest React patterns" --search --sandbox read-only
```

## More Information

- Full CLI reference: `codex --help`
- Exec subcommand: `codex exec --help`
- Review command: `codex review --help`
- Official docs: https://github.com/openai/codex
