# Codex MCP Server Schema

The plugin's `.mcp.json` starts `codex mcp-server` (stdio) automatically when the plugin is enabled.

## Discovering live tool names

Run `/mcp` in Claude Code to list actual tool names and parameter schemas for your install. The tool prefix varies (`mcp__plugin_codex_cli__codex`, `mcp__codex_cli__codex`, ...).

Supporting CLI commands:

```bash
codex --version          # CLI version
codex --help             # all flags
codex features list      # feature flags and their states
```

## `codex` — start a new thread

| Parameter | Required | Notes |
|-----------|----------|-------|
| `prompt` | yes | Initial user prompt |
| `model` | no | Default `gpt-5.4`. Alternatives: `gpt-5.4-mini`, `gpt-5.3-codex`, `gpt-5.2`. Omit to use default. |
| `sandbox` | no | `read-only` (use this), `workspace-write`, `danger-full-access` (forbidden) |
| `approval-policy` | no | `untrusted`, `on-request`, `never` |
| `cwd` | no | Working directory |
| `config` | no | TOML overrides (dotted keys, TOML-parsed values) |

Returns `threadId` — pass to `codex-reply` for follow-ups.

### Web search

Codex enables cached web search by default. For live results, use the top-level `--search` flag (CLI) or check `/mcp` for the current MCP-config shape.

## `codex-reply` — continue a thread

| Parameter | Required | Notes |
|-----------|----------|-------|
| `threadId` | yes | From a prior `codex` or `codex-reply` response |
| `prompt` | yes | Follow-up prompt |

**Prefer `codex-reply` over starting a new `codex` thread whenever you're still iterating on the same topic and have `threadId` in context.** See `patterns.md` → "Iterative consultation".
