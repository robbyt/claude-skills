# Codex CLI Setup & Troubleshooting

Shared reference for all Codex skills.

## MCP Server (primary interface)

The plugin's `.mcp.json` starts `codex mcp-server` automatically when the plugin is enabled. All Codex skills expect to call the MCP tools directly — no shelling out.

**Requirements:**
- Plugin enabled in Claude Code
- Claude Code restarted after enabling the plugin
- Codex CLI installed and authenticated

**Verification:**
Run `/mcp` and look for the Codex tools (typically `mcp__plugin_codex_cli__codex` and `mcp__plugin_codex_cli__codex-reply`; exact prefix varies).

## Prerequisites

```bash
# Install
npm install -g @openai/codex

# Verify (one-time installation check — not a runtime pattern)
codex --version
codex exec --ephemeral "hi" --sandbox read-only
```

At runtime, call Codex via the MCP tool, not `codex exec` — see `patterns.md`.

## Authentication

Claude Code will **not** configure Codex auth. Codex CLI must be pre-authenticated (ChatGPT account or API key). See https://github.com/openai/codex for options.

**ChatGPT account note:** `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.3-codex`, and `gpt-5.2` work on Plus/Pro/Business/Edu/Enterprise plans. Other names (`o3`, `o4-mini`, `gpt-5.4-codex`, `codex-mini-latest`, …) return "model is not supported when using Codex with a ChatGPT account" — use an API-key install for those.

## Sandbox Modes

Set via the `sandbox` MCP parameter (or `--sandbox`/`-s` in Bash):

| Mode | Use for these skills? |
|------|----------------------|
| `read-only` | **Yes — always.** |
| `workspace-write` | No. Claude writes code, not Codex. |
| `danger-full-access` | **Forbidden.** |

Also forbidden: `--dangerously-bypass-approvals-and-sandbox`.

## Troubleshooting

### MCP tools not visible

Restart Claude Code after enabling the plugin. Run `/mcp` to confirm the `cli` server is connected.

### "model is not supported" error

You're passing a model name not covered by your Codex account. Omit the `model` parameter to use the default (`gpt-5.5`), or pick from `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.3-codex`, `gpt-5.2`.

### Codex asks clarifying questions instead of answering

Add a one-liner to your prompt: "Provide a complete answer; don't ask clarifying questions."

### Sandbox / session file errors (Bash fallback)

If you're shelling out and see `permission denied` on `~/.codex/sessions`, add `--ephemeral` to skip session persistence, and set `dangerouslyDisableSandbox: true` on the Bash call.

### Timeout

Complex analyses can take several minutes. Allow up to 10 minutes before assuming a hang.
