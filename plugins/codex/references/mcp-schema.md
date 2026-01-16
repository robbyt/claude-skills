# Codex MCP Server Schema

Quick reference for the Codex MCP server tools.

## Checking the Schema

The MCP tool definitions are available in the current session. Check:
- Tool names: `mcp__plugin_codex_cli__codex` and `mcp__plugin_codex_cli__codex-reply`
- Use `/mcp` command to list available MCP tools and their schemas

To check CLI options:
```bash
codex --help
codex --version
codex features list
```

## Tools

### `codex` - Run a Codex session

**Key parameters:**

| Name | Required | Notes |
|------|----------|-------|
| `prompt` | Yes | The initial user prompt |
| `model` | No | Use `gpt-5.2` (default) |
| `sandbox` | No | `read-only`, `workspace-write`, `danger-full-access` |
| `approval-policy` | No | `untrusted`, `on-failure`, `on-request`, `never` |
| `cwd` | No | Working directory |
| `config` | No | Override config.toml settings |

**Enabling features via config:**

```json
{
  "config": {
    "features": {
      "web_search_request": true
    }
  }
}
```

Check available features with `codex features list`.

### `codex-reply` - Continue a conversation

**Key parameters:**

| Name | Required | Notes |
|------|----------|-------|
| `threadId` | Yes | Thread ID from previous `codex` call |
| `prompt` | Yes | Follow-up prompt |
| `conversationId` | No | **DEPRECATED** - use `threadId` |
