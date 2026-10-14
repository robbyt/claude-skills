# Codex CLI Setup & Troubleshooting

Shared reference for all Codex skills.

## MCP Server (primary interface)

The plugin's `.mcp.json` starts `scripts/codex-mcp-server.mjs` when the plugin is enabled. This server is part of the plugin. It exposes the `codex` and `codex-reply` tools and runs `codex exec --json` / `codex exec resume` for each call. All Codex skills call these MCP tools directly, without shelling out.

Plugin versions before 1.7.0 started `codex mcp-server`, which Codex CLI removed in 0.154.0. If `/mcp` shows the `cli` server failing to connect, update this plugin.

**Requirements:**
- Codex CLI **0.154 or newer**, installed and authenticated
- Node.js 18 or newer on `PATH` (runs the MCP server)
- Plugin enabled in Claude Code, and Claude Code restarted (or `/reload-plugins`) after enabling or updating it

**Verification:**
Run `/mcp` and look for the Codex tools (typically `mcp__plugin_codex_cli__codex` and `mcp__plugin_codex_cli__codex-reply`; exact prefix varies).

## Prerequisites

```bash
# Install (either)
npm install -g @openai/codex
brew install --cask codex

# Authenticate (ChatGPT account or API key)
codex login

# Verify (one-time installation check — not a runtime pattern)
codex --version
codex login status
codex exec --ephemeral --sandbox read-only "hi" < /dev/null
```

`codex doctor` diagnoses install, config, and auth problems.

At runtime, call Codex via the MCP tool, not `codex exec` — see `patterns.md`.

## Model compatibility

These skills **pin** the GPT-6 tiers explicitly (`gpt-6.1-sol` for deep tasks, `gpt-6-luna` for small ones), so an older CLI or an account without GPT-6 access will **error** rather than silently fall back.

- Tested with **Codex CLI 0.162.0**. The minimum is 0.154, which the MCP server requires; `gpt-6.1-sol` needs a newer CLI whose model list includes it. If a GPT-6 slug is rejected, upgrade first: `npm install -g @openai/codex`.
- Your **local model list is authoritative** — availability is account- and release-dependent. Confirm a slug is advertised before relying on it (an unsupported name fails fast: `codex exec -m gpt-6.1-sol --sandbox read-only --ephemeral "hi" < /dev/null`).
- **If `gpt-6.1-sol` isn't listed yet** (older CLI or account rollout), ask for `gpt-6-sol` by name; it's the previous Sol and works with the same `medium` effort.
- **Operational fallback** if your account hasn't received GPT-6: editing `~/.codex/config.toml` alone won't help, because the skills override the model per call. Instead, **explicitly ask** for a model your Codex advertises (e.g. "use gpt-5.6-sol") — the skills/agent honor a supported user-provided model — or use an API-key install that has the GPT-6 tiers.

## Authentication

Claude Code will **not** configure Codex auth. Codex CLI must be pre-authenticated (ChatGPT account or API key). See https://github.com/openai/codex for options.

**ChatGPT account note:** the GPT-6 tiers (`gpt-6-astra`, `gpt-6.1-sol`, `gpt-6-luna`) plus the older `gpt-6-sol`, `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna` work on Plus/Pro/Business/Edu/Enterprise plans. `gpt-5.5` retires from Codex on 2026-10-14. Availability is account-dependent — your local Codex model list is authoritative. Other names (`o3`, `o4-mini`, `gpt-5.4-codex`, `codex-mini-latest`, the bare `gpt-6`, …) return "model is not supported when using Codex with a ChatGPT account" — use an API-key install for those.

## Sandbox Modes

The MCP server always runs Codex with `--sandbox read-only` and rejects any other `sandbox` value. In the Bash fallback, set it with `--sandbox`/`-s`:

| Mode | Use for these skills? |
|------|----------------------|
| `read-only` | **Yes — always.** |
| `workspace-write` | No. Claude writes code, not Codex. |
| `danger-full-access` | **Forbidden.** |

Also forbidden: `--dangerously-bypass-approvals-and-sandbox`.

## Troubleshooting

### MCP tools not visible / `cli` server failed to connect

1. Run `/mcp` and check the `cli` server's status and error.
2. Confirm `node --version` is 18+ and `codex --version` is 0.154+.
3. Run the server by hand to see its error output:
   ```bash
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{}}}' \
     | node <plugin-dir>/scripts/codex-mcp-server.mjs
   ```
   A JSON line with `"serverInfo":{"name":"codex-exec-mcp",...}` means the server starts. Codex itself only runs on a tool call.
4. Restart Claude Code (or `/reload-plugins`) after fixing it. Claude Code caches a failed connection for about 15 minutes.

### "Codex CLI not found on PATH"

The MCP server couldn't start `codex`. Install it (see Prerequisites), or set `CODEX_BIN` to the full path of the executable in the environment Claude Code runs in.

### Running inside cmux

The cmux terminal puts a wrapper script in front of `codex` that adds a computer-use MCP server and hook settings to `codex exec` runs. The plugin's MCP server sets `CMUX_CODEX_HOOKS_DISABLED=1` for the Codex process, so the wrapper runs the real binary with the plugin's arguments unchanged. Plugin-started Codex runs therefore don't appear in cmux's agent sidebar.

### "model is not supported" error

You're passing a model name your Codex account or CLI doesn't advertise. Common causes: the bare `gpt-6` (unlisted — use `gpt-6.1-sol`), an account that hasn't received the GPT-6 tiers yet, or an out-of-date CLI. Pick a slug your local Codex actually lists (`codex exec -m … --sandbox read-only --ephemeral "hi"` fails fast on an unsupported name), or fall back to an older listed model — `gpt-6-sol`, `gpt-5.6-sol`, `gpt-5.6-luna`. See the compatibility note above for the operational fallback.

### Codex asks clarifying questions instead of answering

Add a one-liner to your prompt: "Provide a complete answer; don't ask clarifying questions."

### Sandbox / session file errors (Bash fallback)

If you're shelling out and see `permission denied` on `~/.codex/sessions`, add `--ephemeral` to skip session persistence, and set `dangerouslyDisableSandbox: true` on the Bash call. If `codex exec` hangs with no output, redirect stdin from `/dev/null`.

### Timeout

Complex analyses can take several minutes. Allow up to 10 minutes before assuming a hang. For long reviews or broad analyses, run the `codex:consult` agent in the background so the main session isn't blocked.
