# Codex Integration Patterns

Shared patterns for all Codex skills.

## Core Principle

Claude writes code. Codex provides second opinions, reviews, and analysis.

## Transport: MCP stdio (always)

This plugin ships an MCP server configured in `.mcp.json` that runs `codex mcp-server` over stdio. **Always use the MCP tool — never shell out to `codex` via Bash** unless the MCP server is unavailable.

Why MCP over Bash:
- No shell-quoting issues with multi-line prompts
- No `dangerouslyDisableSandbox: true` approval prompt
- Session continuity via `threadId`
- Richer structured responses

Tool names (check `/mcp` for exact names on your install):
- `mcp__plugin_codex_cli__codex` — start a new thread
- `mcp__plugin_codex_cli__codex-reply` — continue an existing thread

## Models

Authoritative list: https://developers.openai.com/codex/models

| Model | When to use |
|-------|-------------|
| `gpt-5.5` | **Default.** Flagship — strongest agentic coding. Used when `model` is omitted. |
| `gpt-5.4-mini` | Smaller/cheaper. Use for small or trivial tasks (single-function diff, dependency lookup, yes/no triage). ~30% of `gpt-5.4` quota. |
| `gpt-5.3-codex` | Coding-specialized older model. Codex prompts an upgrade to `gpt-5.4` — listed for completeness. |
| `gpt-5.4` | Previous flagship. |
| `gpt-5.2` | Legacy. |

**Default behavior: omit the `model` parameter.** Codex CLI picks `gpt-5.5` on its own. Set `model: gpt-5.5` only when you want to be explicit. Set `model: gpt-5.4-mini` when the task is clearly small — a brief lookup, a tiny diff, a yes/no triage — to save quota and latency. **Don't switch to `gpt-5.4-mini` for plan critique, codebase analysis, or security review** — those benefit from the flagship's reasoning.

Models not listed above (e.g., `o3`, `o4-mini`, `gpt-5.4-codex`, `codex-mini-latest`) either don't exist or aren't available to ChatGPT-account users. Don't guess — pick from the table.

## Sandbox

Always `read-only`. Codex consults; Claude writes.

Forbidden:
- `workspace-write` — Claude's job, not Codex's
- `danger-full-access` — never
- `--dangerously-bypass-approvals-and-sandbox` — never

## Prompt style

Codex in non-interactive MCP mode already knows not to prompt back. You don't need a lengthy "you are running non-interactively" preamble. A single line is enough when needed:

> "Read-only review — do not modify files. Provide a complete answer; don't ask clarifying questions."

Task-specific prompts should just state the task directly.

## Iterative consultation (continue the thread)

**Default behavior when iterating on the same topic: reuse the `threadId`, don't start fresh.**

Every `codex` and `codex-reply` response returns a `threadId`. As long as it's still in your context, use `codex-reply` for every subsequent round on the same topic. Fresh `codex` calls discard Codex's prior reasoning and force it to re-read the same files — wasted tokens and drift-prone.

**`threadId` is an MCP argument, never prompt content.** Pass it as the `threadId` field of the `codex-reply` MCP call. Don't write `"Continue thread abc123 and …"` into the `prompt` — codex won't read it as a thread reference, and you'll silently start a fresh thread.

### The loop

1. Claude consults Codex on a topic → response includes `threadId`.
2. Claude researches further (reads code, runs tests, applies a fix).
3. Claude has a follow-up question, a correction to a Codex assumption, or new findings to share.
4. Claude calls `codex-reply` with the same `threadId`, feeding in what it learned.
5. Repeat from step 2 until the thread is resolved.

**Cap the dialog at 3–4 rounds.** Each round costs tokens and Codex time; productive iteration converges fast. If you're past round 4 and still going, stop and summarize what you have — either act on the current answer, surface the disagreement to the user, or start a fresh thread with a sharper question. Don't let Claude and Codex debate a topic indefinitely.

### Example: 3-round iteration

```
# Round 1 — initial consult
mcp__plugin_codex_cli__codex({
  "prompt": "Review the auth flow in src/auth/. Call out concerns.",
  "sandbox": "read-only"
})
# → response includes threadId: "019da14b-8e9d-..."
# → Codex flags: "Session rotation looks too infrequent — looks like ~1h window."

# Round 2 — Claude reads the actual rotation code, finds Codex's assumption was wrong
# Note: threadId is an MCP arg, NOT in the prompt text.
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-8e9d-...",
  "prompt": "I checked src/session/rotate.ts — the rotation window is 15m, not 1h. Does that change your concern, or is there still an issue?"
})
# → Codex updates: "15m window is fine for the threat model; the remaining concern is CSRF on the refresh endpoint."

# Round 3 — Claude drills in (threadId still as MCP arg)
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-8e9d-...",
  "prompt": "The refresh endpoint uses SameSite=Strict cookies. Does that mitigate your CSRF concern?"
})
```

### When to start a fresh thread instead

- **New unrelated topic.** User asks about a different area of the codebase.
- **`threadId` no longer in context.** Conversation was compacted, or it's a new Claude Code session.
- **Codex's prior answer is now stale.** Claude made enough code changes that Codex's assumptions are broadly wrong — re-priming with a fresh call is cleaner than patching assumptions incrementally. If changes are targeted and you can describe them in a follow-up prompt, just continue the thread.

When the topic hasn't changed and the `threadId` is still in context, continue the thread. If files Codex read have been modified, tell Codex to re-read them in your follow-up prompt.

## Web search

Codex enables cached web search by default — no action needed to let it look things up.

For live (non-cached) results, use `codex --search "prompt"` for a single run, or set `web_search = "live"` in `~/.codex/config.toml`. Use `web_search = "disabled"` to turn it off.

## File access

Codex reads files from its working directory. Pass repo-relative paths in the prompt:

- ✓ `"Review src/auth/login.ts"`
- ✗ `"Review ~/projects/foo/src/auth/login.ts"`

For files outside the workspace (e.g., plans in `~/.claude/plans/`), read them with Claude's `Read` tool and embed the content into the prompt rather than passing the path.

Don't use `$(cat file)` in Bash prompts — Codex doesn't expand shell substitutions.

## Validation

Codex can be wrong. Verify recommendations against:
1. Official docs (for API claims, especially for recently changed libraries)
2. Actual project constraints
3. Your own reasoning

Don't implement Codex's suggestions blindly.

## Bash fallback (rare)

Only when the MCP server is unavailable (plugin disabled, server crashed):

```bash
codex exec --ephemeral --sandbox read-only "prompt"
```

- Omit `-m` to get the default (`gpt-5.5`).
- `--ephemeral` avoids persisting a session to `~/.codex/sessions/`.
- This requires `dangerouslyDisableSandbox: true` because Codex writes to its own state dirs.

If you reach for Bash, first verify MCP really is unavailable: look for `mcp__*_codex` tools in the current tool list, or run `/mcp`.
