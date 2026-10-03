# Codex MCP Server Schema

The plugin's `.mcp.json` starts `scripts/codex-mcp-server.mjs` (stdio, Node >= 18) when the plugin is enabled. The server is part of this plugin: each tool call runs `codex exec --json` (new thread) or `codex exec resume` (follow-up) and returns Codex's final message. It replaces `codex mcp-server`, which Codex CLI removed in 0.154.0.

## Discovering live tool names

Run `/mcp` in Claude Code to list the tool names and parameter schemas for your install. The server is named `cli`, so the tools are normally `mcp__plugin_codex_cli__codex` and `mcp__plugin_codex_cli__codex-reply`.

Supporting CLI commands:

```bash
codex --version          # CLI version (>= 0.154 required)
codex login status       # auth state
codex features list      # feature flags and their states
```

## `codex` — start a new thread

| Parameter | Required | Notes |
|-----------|----------|-------|
| `prompt` | yes | Initial prompt. Sent to Codex on stdin, so long embedded plans and diffs are fine. |
| `model` | no | **Pin explicitly.** Don't omit it: omitting inherits the user's `config.toml`, not a model default. Use `gpt-6-sol` for deep tasks and `gpt-6-luna` for small ones. `gpt-6-astra` is for escalation (see `patterns.md` → Escalating to gpt-6-astra). The bare `gpt-6` name is unlisted; use the slugs. See `patterns.md` → Models. |
| `sandbox` | no | Only `read-only` is accepted, and it is the default. Other values return an error. |
| `config` | no | Config overrides as dotted keys with string, number, or boolean values, each passed as `-c key=value`. Reasoning effort goes here, e.g. `{ "model_reasoning_effort": "medium" }` (`medium` for sol, `low` for luna). |
| `cwd` | no | Working directory. Defaults to the project directory. |
| `outputSchema` | no | JSON Schema for the final response. `"review"` selects the bundled `schemas/review-output.schema.json` (used by `adversarial-review`); an inline schema object also works. The final message is then JSON. |
| `profile` | no | Codex config profile, passed as `-p`. |
| `approval-policy` | no | Accepted and ignored. `codex exec` never asks for approval. |

`base-instructions`, `developer-instructions`, and `compact-prompt` from the old `codex mcp-server` are not supported and return an error.

**Result:** Codex's final message, followed by a line `threadId: <uuid>`. `structuredContent` also carries `{ threadId, content }`. Pass the threadId to `codex-reply` for follow-ups.

Opening call — pin `model` and reasoning effort via `config`:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this project's architecture.",
  "sandbox": "read-only",
  "model": "gpt-6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

The server stores the opening call's model, config, and cwd per thread and passes them again on every resume, so set them once here. A `codex-reply` can override `model`/`config` to escalate the thread. The records are kept as one file per thread in `${CLAUDE_PLUGIN_DATA}/codex-threads/` and survive an MCP server restart. Replies to one thread are run in order within a session; two Claude sessions replying to the same thread at the same time are not ordered.

### Web search

Codex enables cached web search by default. For live results, pass `config: { "web_search": "live" }`.

## `codex-reply` — continue a thread

**`threadId` is an MCP parameter — not part of the `prompt` text.** If you put it in the prompt, the server rejects the call because `threadId` is missing or is not a UUID. Before 1.7.0 this silently started a fresh thread.

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
| `threadId` | yes | UUID from a prior `codex` or `codex-reply` result. Pass as an MCP argument, never inside `prompt`. |
| `prompt` | yes | Follow-up prompt (just the question/instructions — no thread ID). |
| `model` | no | Switch the thread to this model for this reply and later ones; the thread keeps its history. Used to escalate to `gpt-6-astra`. |
| `config` | no | Overrides merged over the thread's stored config, e.g. `{ "model_reasoning_effort": "medium" }`. Kept for later replies. |
| `conversationId` | — | **Deprecated** alias for `threadId`, accepted for old callers. |

**Prefer `codex-reply` over starting a new `codex` thread whenever you're still iterating on the same topic and have `threadId` in context.** See `patterns.md` → "Iterative consultation".

## Behavior notes

- Every run uses `--sandbox read-only` and `--skip-git-repo-check`, so Codex also works outside a git repo.
- Runs are not ephemeral. Codex saves the session under `~/.codex/sessions/`, which is what makes `codex-reply` possible. You can also continue a thread in the Codex TUI with `codex resume <threadId>`.
- The server sends MCP progress notifications (thread started, commands Codex runs), and cancelling the tool call sends SIGINT to Codex.
- The server sets `CMUX_CODEX_HOOKS_DISABLED=1` for the Codex process. Inside the cmux terminal, this stops cmux's `codex` wrapper from adding its computer-use MCP server and hook-trust bypass to the run.
- `CODEX_BIN` overrides the `codex` executable path.
