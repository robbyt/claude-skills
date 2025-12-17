# Codex CLI Setup & Troubleshooting

Shared reference for all Codex skills.

## MCP Server

The Codex plugin includes an MCP server that starts automatically when the plugin is enabled. This provides the `codex` and `codex-reply` tools.

**Requirements:**
- Plugin must be enabled in Claude Code
- Claude Code restart required after enabling plugin
- Codex CLI must be installed and authenticated

**Verification:**
MCP tools should appear as `mcp__plugin_codex_cli__codex` when working (tool name may vary by installation). If MCP is unavailable, fall back to Bash commands.

## Prerequisites

Codex CLI must be installed and authenticated before using any Codex skill.

**Installation:**
```bash
# Via npm
npm install -g @openai/codex

# Verify installation
codex --version
```

**Verify:**
```bash
codex --version  # Should show version
codex exec "Say hello" --sandbox read-only  # Should respond
```

## Authentication

Claude Code will NOT configure authentication. Codex CLI must be pre-configured with API keys or OAuth before using these skills. See [official Codex CLI docs](https://github.com/openai/codex) for authentication options.

## Sandbox Modes

Codex supports three sandbox modes via `--sandbox` or `-s`, from most to least restrictive:

| Mode | Description |
|------|-------------|
| `read-only` | **Most restrictive.** Can read files but cannot write or execute commands that modify files. Use for all analysis tasks. |
| `workspace-write` | Can read anywhere, write to workspace and /tmp only. |
| `danger-full-access` | **FORBIDDEN.** No restrictions. Never use with these skills. |

These skills always use `--sandbox read-only` to prevent Codex from modifying files.

## Interactive vs Non-Interactive

- **Interactive mode**: `codex "prompt"` - runs with user interaction
- **Non-interactive mode**: `codex exec "prompt"` - runs without user interaction

For non-interactive execution with `codex exec`, approval is automatically bypassed.

## Troubleshooting

### Sandbox Permission Error

**Problem:** Codex cannot read files as expected.

**Solution:** Ensure `--sandbox read-only` is specified. These skills should only read files, never write.

### Authentication Issues

**Problem:** `codex` commands fail with authentication errors.

**Solution:** Verify your Codex CLI authentication configuration. See [official docs](https://github.com/openai/codex) for API key or OAuth setup.

### Timeout

Complex analysis may take several minutes. Allow up to 10 minutes before assuming timeout.

## Working with Files

Codex can read files directly. Pass file paths in prompts:

```bash
codex exec "Review the code in src/main.ts" --sandbox read-only
```

For files outside the workspace, save them to the project root first.

## Non-Interactive Execution

Use `codex exec` for non-interactive execution:

```bash
codex exec "Your prompt here" --sandbox read-only
```
