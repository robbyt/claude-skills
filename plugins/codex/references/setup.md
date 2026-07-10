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

## Model compatibility

These skills **pin** the GPT-5.6 tiers explicitly (`gpt-5.6-sol` for deep tasks, `gpt-5.6-luna` for small ones), so — unlike the old "omit to get the default" behavior — an older CLI or an account without 5.6 access will **error** rather than silently fall back.

- Tested with **Codex CLI 0.144.1** (not asserted as the minimum). If a 5.6 slug is rejected, upgrade first: `npm install -g @openai/codex`.
- Your **local model list is authoritative** — availability is account- and release-dependent. Confirm a slug is advertised before relying on it (an unsupported name fails fast: `codex exec -m gpt-5.6-sol --sandbox read-only --ephemeral "hi"`).
- **Operational fallback** if your account hasn't received 5.6: editing `~/.codex/config.toml` alone won't help, because the skills override the model per call. Instead, **explicitly ask** for a model your Codex advertises (e.g. "use gpt-5.5") — the skills/agent honor a supported user-provided model — or use an API-key install that has the 5.6 tiers.

## Authentication

Claude Code will **not** configure Codex auth. Codex CLI must be pre-authenticated (ChatGPT account or API key). See https://github.com/openai/codex for options.

**ChatGPT account note:** the GPT-5.6 tiers (`gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`) plus older `gpt-5.5`, `gpt-5.4`, and `gpt-5.4-mini` work on Plus/Pro/Business/Edu/Enterprise plans. Availability is account-dependent — your local Codex model list is authoritative. Other names (`o3`, `o4-mini`, `gpt-5.4-codex`, `codex-mini-latest`, the bare `gpt-5.6`, …) return "model is not supported when using Codex with a ChatGPT account" — use an API-key install for those.

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

You're passing a model name your Codex account or CLI doesn't advertise. Common causes: the bare `gpt-5.6` (unlisted — use `gpt-5.6-sol`), an account that hasn't received the 5.6 tiers yet, or an out-of-date CLI. Pick a slug your local Codex actually lists (`codex exec -m … --sandbox read-only --ephemeral "hi"` fails fast on an unsupported name), or fall back to an older listed model — `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`. See the compatibility note above for the operational fallback.

### Codex asks clarifying questions instead of answering

Add a one-liner to your prompt: "Provide a complete answer; don't ask clarifying questions."

### Sandbox / session file errors (Bash fallback)

If you're shelling out and see `permission denied` on `~/.codex/sessions`, add `--ephemeral` to skip session persistence, and set `dangerouslyDisableSandbox: true` on the Bash call.

### Timeout

Complex analyses can take several minutes. Allow up to 10 minutes before assuming a hang.
