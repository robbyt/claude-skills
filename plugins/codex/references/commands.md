# Codex CLI Quick Reference

For complete documentation, run `codex --help` or see https://github.com/openai/codex.

## MCP is the primary interface

The plugin's `.mcp.json` starts `codex mcp-server` on stdio. Use the MCP tools; don't shell out.

### `mcp__plugin_codex_cli__codex` — new thread

```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this project's architecture.",
  "sandbox": "read-only"
})
```

| Parameter | Required | Default | Notes |
|-----------|----------|---------|-------|
| `prompt` | yes | — | The task or question |
| `sandbox` | no | `read-only` | Always `read-only` for these skills |
| `model` | no | `gpt-5.5` | Omit unless user specifies a model |
| `cwd` | no | project root | Working directory |
| `approval-policy` | no | — | `untrusted`, `on-request`, `never`. Usually not needed with `read-only` sandbox. |
| `config` | no | — | TOML overrides (dotted paths) |

Returns a `threadId`. Pass it to `codex-reply` for follow-ups.

> Tool prefix may be `mcp__plugin_codex_cli__codex`, `mcp__codex_cli__codex`, or similar depending on install. Run `/mcp` to confirm.

### `mcp__plugin_codex_cli__codex-reply` — continue

```
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Checked src/session/rotate.ts — rotation window is 15m, not 1h. Does that change your concern?"
})
```

**Prefer `codex-reply` over a fresh `codex` call whenever you're still iterating on the same topic and have `threadId` in context.** See `patterns.md` for the iterative-consultation workflow.

## Models

Authoritative list: https://developers.openai.com/codex/models

| Model | Notes |
|-------|-------|
| `gpt-5.5` | Default flagship — current |
| `gpt-5.4-mini` | Fast/cheap (~30% of `gpt-5.4` quota); use for small tasks |
| `gpt-5.4` | Previous flagship |
| `gpt-5.3-codex` | Coding-specialized older model |
| `gpt-5.2` | Legacy |

## Bash fallback (rare)

Only when MCP is unavailable. Requires `dangerouslyDisableSandbox: true`.

```bash
codex exec --ephemeral --sandbox read-only "prompt"
```

### `codex exec` flags

| Flag | Purpose |
|------|---------|
| `--ephemeral` | Don't persist session to `~/.codex/sessions/` |
| `--sandbox read-only` | Read-only filesystem access |
| `-m <model>` | Override default model (omit to get `gpt-5.5`) |
| `-C <dir>` | Set working directory |
| `--output-last-message <file>` | Write final agent message to file |
| `--output-schema <file>` | Enforce JSON Schema on response |
| `--json` | Stream JSONL events |
| `-i <file>` | Attach image(s) |
| `-c key=value` | TOML config override (dotted path) |

Web search is enabled by default via cache. For live results, use the top-level `codex --search "prompt"` (not an `exec` flag), or set `web_search = "live"` in `~/.codex/config.toml`.

### `codex review` — built-in diff review (Bash-only)

```bash
codex review --uncommitted          # staged + unstaged + untracked
codex review --base main            # branch vs base
codex review --commit <sha>         # a specific commit
codex review --title "..." --uncommitted
```

No `--sandbox` flag; always diff-scoped. Prefer the MCP `codex` tool with a diff saved to file for consistent integration.

### Top-level `codex` options

Relevant flags not in `exec`:

| Flag | Purpose |
|------|---------|
| `--search` | Force live web search (cached search is on by default) |
| `-a <policy>` | Approval policy: `untrusted`, `on-request`, `never` |
| `--full-auto` | Alias for `-a on-request --sandbox workspace-write` (don't use) |
| `--remote <ADDR>` | Connect TUI to a remote `codex app-server` |
| `--add-dir <DIR>` | Grant extra writable roots (N/A for `read-only`) |

### Subcommands

| Subcommand | Alias | Use |
|------------|-------|-----|
| `exec` | `e` | Non-interactive |
| `review` | | Built-in diff review |
| `resume` | | Resume a saved session |
| `apply` | `a` | `git apply` Codex's last diff |
| `mcp` | | Manage external MCP servers for Codex |
| `marketplace` | | Manage Codex plugin marketplaces |
| `mcp-server` | | Run Codex as an MCP server (used by this plugin) |
| `features` | | List feature flags (`codex features list`) |
| `login` / `logout` | | Auth |
| `sandbox` | | Run a command inside Codex's sandbox |
| `debug` | | Debugging tools |

Run `codex <subcommand> --help` for specifics.
