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
| `model` | no | Default `gpt-5.5` (current flagship). Alternatives: `gpt-5.4-mini` (smaller/cheaper), `gpt-5.4`, `gpt-5.3-codex`, legacy `gpt-5.2`. Omit to use default. |
| `sandbox` | no | `read-only` (use this), `workspace-write`, `danger-full-access` (forbidden) |
| `approval-policy` | no | `untrusted`, `on-failure`, `on-request`, `never` |
| `cwd` | no | Working directory |
| `config` | no | TOML overrides (dotted keys, TOML-parsed values) |

Returns `threadId` — pass to `codex-reply` for follow-ups.

### Less-common parameters

The codex MCP `codex` tool also accepts these — included for completeness; consultation skills don't need them:

| Parameter | Notes |
|-----------|-------|
| `profile` | Named config profile from `~/.codex/config.toml` |
| `developer-instructions` | Injected as a developer-role message |
| `base-instructions` | Replace codex's default base instructions |
| `compact-prompt` | Custom prompt used when codex compacts the conversation |

### Web search

Codex enables cached web search by default. For live results, use the top-level `--search` flag (CLI) or check `/mcp` for the current MCP-config shape.

## `codex-reply` — continue a thread

**`threadId` is an MCP parameter — not part of the `prompt` text.** It is a tool argument. If you concatenate it into the prompt, codex won't recognize it as a thread reference and you'll start a fresh thread by accident, discarding all prior context.

```
# ✗ wrong — threadId in the prompt body
mcp__plugin_codex_cli__codex-reply({
  "prompt": "Continue thread 019da14b-... and answer X"
})

# ✓ right — threadId as an MCP parameter
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Answer X"
})
```

| Parameter | Required | Notes |
|-----------|----------|-------|
| `threadId` | yes | From a prior `codex` or `codex-reply` response. Pass as an MCP argument, never inside `prompt`. |
| `prompt` | yes | Follow-up prompt (just the question/instructions — no thread ID) |
| `conversationId` | — | **DEPRECATED** — kept for backwards compatibility with old clients. If you see `conversationId` in old code or examples, replace with `threadId`. |

**Prefer `codex-reply` over starting a new `codex` thread whenever you're still iterating on the same topic and have `threadId` in context.** See `patterns.md` → "Iterative consultation".
