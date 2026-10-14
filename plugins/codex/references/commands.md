# Codex CLI Quick Reference

For complete documentation, run `codex --help` or see https://github.com/openai/codex.

## MCP is the primary interface

The plugin's `.mcp.json` starts its own MCP server (`scripts/codex-mcp-server.mjs`), which runs `codex exec` for each call. Use the MCP tools; don't shell out. Full parameter reference: `mcp-schema.md`.

### `mcp__plugin_codex_cli__codex` — new thread

```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this project's architecture.",
  "sandbox": "read-only",
  "model": "gpt-6.1-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

| Parameter | Required | Default | Notes |
|-----------|----------|---------|-------|
| `prompt` | yes | — | The task or question |
| `sandbox` | no | `read-only` | Only `read-only` is accepted |
| `model` | no | — | **Pin explicitly.** `gpt-6.1-sol` for deep tasks, `gpt-6-luna` for small ones (see Models). Don't omit — see `patterns.md` → Reasoning effort. |
| `config` | no | — | TOML overrides (dotted paths). Carries reasoning effort: `{ "model_reasoning_effort": "medium" }`. |
| `cwd` | no | project root | Working directory |
| `outputSchema` | no | — | `"review"` for the bundled review schema, or an inline JSON Schema object |
| `approval-policy` | no | — | Accepted and ignored; `codex exec` never asks for approval |

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

Authoritative list (snapshot below may go stale): https://learn.chatgpt.com/docs/models — and what your local Codex advertises. The bare `gpt-6` name is **not** in the CLI list; use explicit slugs. Pin effort alongside the model — see `patterns.md` → Reasoning effort.

| Model | Notes | Pinned effort |
|-------|-------|---------------|
| `gpt-6.1-sol` | Complex coding and multi-step agent work — default for deep tasks | `medium` |
| `gpt-6-luna` | Focused, repeatable tasks | `low` |
| `gpt-6-astra` | Frontier tier; escalate to it for repeated refinement (round 3+, see `patterns.md`) | `medium` |
| `gpt-6-sol` | Previous Sol; deep-task fallback when `gpt-6.1-sol` isn't listed | `medium` |
| `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna` | Older generation | `medium` / `medium` / `low` |
| `gpt-5.5` | Retires from Codex 2026-10-14; don't use | — |

## Bash fallback (rare)

Only when MCP is unavailable. Requires `dangerouslyDisableSandbox: true`.

```bash
codex exec --ephemeral --sandbox read-only \
  -m gpt-6.1-sol -c 'model_reasoning_effort="medium"' "prompt" < /dev/null
```

`codex exec` reads stdin to EOF when stdin is not a terminal and appends it to the prompt. Redirect from `/dev/null` (or pipe the prompt in and pass `-` as the prompt) so it doesn't wait on an open pipe.

### `codex exec` flags

| Flag | Purpose |
|------|---------|
| `--ephemeral` | Don't persist session to `~/.codex/sessions/` |
| `--sandbox read-only` | Read-only filesystem access |
| `-m <model>` | Model to use — pin explicitly (`gpt-6.1-sol` deep, `gpt-6-luna` small) |
| `-c 'model_reasoning_effort="<level>"'` | Reasoning effort (`medium` for sol, `low` for luna). Quote the value so the shell keeps the TOML string. |
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
| `plugin` | | Manage Codex plugins |
| `app-server` | | Run the Codex app server (experimental JSON-RPC API; not MCP) |
| `doctor` | | Diagnose install, config, auth, and runtime health |
| `features` | | List feature flags (`codex features list`) |
| `login` / `logout` | | Auth |
| `sandbox` | | Run a command inside Codex's sandbox |
| `debug` | | Debugging tools |

Run `codex <subcommand> --help` for specifics.
