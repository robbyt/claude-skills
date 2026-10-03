# Codex Integration Patterns

Shared patterns for all Codex skills.

## Core Principle

Claude writes code. Codex provides second opinions, reviews, and analysis.

## Transport: MCP stdio (always)

This plugin ships its own MCP server (`scripts/codex-mcp-server.mjs`, configured in `.mcp.json`). Each tool call runs `codex exec --json`, or `codex exec resume` for follow-ups. **Always use the MCP tool — never shell out to `codex` via Bash** unless the MCP server is unavailable.

Why MCP over Bash:
- No shell-quoting issues with multi-line prompts
- No `dangerouslyDisableSandbox: true` approval prompt
- Session continuity via `threadId`, with the model and effort passed again on every reply
- The server enforces `read-only`

Tool names (check `/mcp` for exact names on your install):
- `mcp__plugin_codex_cli__codex` — start a new thread
- `mcp__plugin_codex_cli__codex-reply` — continue an existing thread

## Models

Authoritative list (current snapshot below may go stale): https://developers.openai.com/codex/models — and what your local Codex advertises. The bare `gpt-6` name is **not** in the CLI's model list; use the explicit `-astra`/`-sol`/`-luna` slugs.

| Model | When to use | Pinned effort |
|-------|-------------|---------------|
| `gpt-6-sol` | **Default for these skills.** OpenAI's recommendation for complex coding and multi-step agent work: plan review, codebase analysis, security/perf review. | `medium` |
| `gpt-6-luna` | OpenAI's recommendation for focused, repeatable tasks: single-function diff, dependency lookup, yes/no triage. | `low` |
| `gpt-6-astra` | Frontier tier. Not used on the first call; escalate to it when a thread needs repeated refinement (see [Escalating to gpt-6-astra](#escalating-to-gpt-6-astra)) or when the user asks. | `medium` |
| `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna` | Previous generation. Use only if the user asks or the account lacks GPT-6. | `medium` / `medium` / `low` |
| `gpt-5.5` | Legacy. | — |

**Default behavior: pin both `model` and effort explicitly** (see [Reasoning effort](#reasoning-effort) for why omitting is not the same as using a model default). For deep tasks — plan critique, codebase analysis, security/perf review — use `gpt-6-sol` at `medium`. For clearly small tasks — a brief lookup, a tiny diff, a yes/no triage — use `gpt-6-luna` at `low` to save quota and latency. **Don't downgrade to `luna` for deep reasoning tasks.**

Models not listed above (e.g., `o3`, `o4-mini`, `codex-mini-latest`, a `gpt-6-terra` tier, or the bare `gpt-6`) either don't exist, aren't advertised by the CLI, or aren't available to ChatGPT-account users. Don't guess — pick a slug from the table, or one your local Codex actually lists.

## Reasoning effort

GPT-6 models expose a reasoning-effort setting. **Set it explicitly on every opening call** — don't rely on "the default." Omitting effort does **not** pick the model's own default; it inherits whatever `model_reasoning_effort` is in the user's `~/.codex/config.toml`, which is unknown and could be anything (`high`, `max`, …). For reproducible behavior, pin it: `sol` → `medium`, `luna` → `low`, `astra` → `medium`. Raise sol to `high` only for a task that measurably benefits.

Pass it via the MCP `config` object (overrides `config.toml` for that call). Model + effort go on the **opening `codex` call**; `codex-reply` reuses both, so set them once when you start the thread. The exception is escalation: pass `model`/`config` on a `codex-reply` to switch the thread to a stronger model (next section).

```
mcp__plugin_codex_cli__codex({
  "prompt": "...",
  "sandbox": "read-only",
  "model": "gpt-6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

Bash equivalent (quote the TOML value so the shell keeps it): `-m gpt-6-sol -c 'model_reasoning_effort="medium"'`.

**Capability vs. recommendation** — supported effort levels (capability snapshot observed with Codex CLI 0.155.1 on 2026-09-23, from the account's local model list; availability and levels are account- and release-dependent and may change — check your local Codex model list):

| Model | Supported efforts |
|-------|-------------------|
| `gpt-6-astra`, `gpt-6-sol` | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` |
| `gpt-6-luna` | `low`, `medium`, `high`, `xhigh`, `max` |

This table is *capability*, not policy. By default this plugin uses only `gpt-6-sol`/`medium` and `gpt-6-luna`/`low`.

## Escalating to gpt-6-astra

Repeated refinement is a sign the task is harder than the opening model handles well. When that happens, move the thread to `gpt-6-astra` at `medium` instead of continuing on the same model.

**Escalate when any of these is true:**
- **Round 3 of a thread.** The opening call and one follow-up haven't settled it, and you are about to send another substantive round (a revised plan or diff, or a point still in dispute).
- **A disagreement survives a round.** You pushed back with evidence and Codex either held its position without new evidence or reversed itself, and the point still matters.
- **A second review of the same work in a fresh thread.** For example, re-reviewing a revised plan or diff after the earlier `threadId` was lost, or after an earlier review round in this session already led to revisions. Open the new thread on astra.
- **A `gpt-6-luna` thread turns out not to be small.** Move it to `gpt-6-sol` on the first substantive follow-up, then to astra if it reaches round 3.

**How:** pass `model` (and effort) on the `codex-reply`. The thread keeps its history and later replies stay on astra:

```
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Revised step 3 below. You flagged the rollback gap twice; does this version close it?\n\n[REVISED SECTION]",
  "model": "gpt-6-astra",
  "config": { "model_reasoning_effort": "medium" }
})
```

**Don't escalate** for a short confirmation round ("does this fix address it?" → "yes"), or for a first review, even a long one. Don't escalate when the user named a model; their choice wins. Keep astra at `medium`: switch model before raising effort.

Escalating doesn't extend the round cap below. Tell the user when you escalated and why (e.g., "moved to gpt-6-astra at round 3: the migration rollback concern was still open").

## Sandbox

Always `read-only`. Codex consults; Claude writes.

Forbidden:
- `workspace-write` — Claude's job, not Codex's
- `danger-full-access` — never
- `--dangerously-bypass-approvals-and-sandbox` — never

## Prompt style

Codex running under `codex exec` knows it is non-interactive and never asks for approval. Skip the "you are running non-interactively" preamble.

Structure prompts as short XML-tagged blocks: `<task>` for the job and its context, an output contract for the shape of the answer, and `<grounding_rules>` for reviews and analysis. Add other blocks only when the task needs them. Tighten the prompt before raising reasoning effort. See `prompting.md` for the blocks, recipes, and antipatterns.

## Iterative consultation (continue the thread)

**Default behavior when iterating on the same topic: reuse the `threadId`, don't start fresh.**

Every `codex` and `codex-reply` response returns a `threadId`. As long as it's still in your context, use `codex-reply` for every subsequent round on the same topic. Fresh `codex` calls discard Codex's prior reasoning and force it to re-read the same files — wasted tokens and drift-prone.

**`threadId` is an MCP argument, never prompt content.** Pass it as the `threadId` field of the `codex-reply` MCP call. Don't write `"Continue thread abc123 and …"` into the `prompt` — Codex won't read it as a thread reference, and the server rejects a `codex-reply` call without a valid `threadId` argument.

### The loop

1. Claude consults Codex on a topic → response includes `threadId`.
2. Claude researches further (reads code, runs tests, applies a fix).
3. Claude has a follow-up question, a correction to a Codex assumption, or new findings to share.
4. Claude calls `codex-reply` with the same `threadId`, feeding in what it learned.
5. Repeat from step 2 until the thread is resolved.

**Cap the dialog at 3–4 rounds.** From round 3, run the thread on `gpt-6-astra` (see [Escalating to gpt-6-astra](#escalating-to-gpt-6-astra)). Each round costs tokens and Codex time; productive iteration converges fast. If you're past round 4 and still going, stop and summarize what you have — either act on the current answer, surface the disagreement to the user, or start a fresh thread with a sharper question. Don't let Claude and Codex debate a topic indefinitely.

### Example: 3-round iteration

```
# Round 1 — initial consult (opening call pins model + effort)
mcp__plugin_codex_cli__codex({
  "prompt": "Review the auth flow in src/auth/. Call out concerns.",
  "sandbox": "read-only",
  "model": "gpt-6-sol",
  "config": { "model_reasoning_effort": "medium" }
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

# Round 3 — Claude drills in (threadId still as MCP arg); escalate to astra from here
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-8e9d-...",
  "prompt": "The refresh endpoint uses SameSite=Strict cookies. Does that mitigate your CSRF concern?",
  "model": "gpt-6-astra",
  "config": { "model_reasoning_effort": "medium" }
})
```

### When to start a fresh thread instead

- **New unrelated topic.** User asks about a different area of the codebase.
- **`threadId` no longer in context.** Conversation was compacted, or it's a new Claude Code session.
- **Codex's prior answer is now stale.** Claude made enough code changes that Codex's assumptions are broadly wrong — re-priming with a fresh call is cleaner than patching assumptions incrementally. If changes are targeted and you can describe them in a follow-up prompt, just continue the thread.

When the topic hasn't changed and the `threadId` is still in context, continue the thread. If files Codex read have been modified, tell Codex to re-read them in your follow-up prompt.

## Web search

Codex enables cached web search by default — no action needed to let it look things up.

For live (non-cached) results through MCP, pass `"config": { "web_search": "live" }` on the opening `codex` call. From the CLI, use `codex --search "prompt"` for a single run, or set `web_search = "live"` in `~/.codex/config.toml`. Use `web_search = "disabled"` to turn it off.

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

## Presenting results

When relaying a Codex response to the user:

- Keep Codex's structure (verdict, summary, findings, next steps). For reviews, list findings first, ordered by severity.
- Keep file paths and line numbers exactly as Codex reported them.
- Keep Codex's distinctions between observed facts, inferences, and open questions. If Codex marked something as a hypothesis or gave a confidence score, carry that through.
- If Codex found nothing, say so plainly and keep any residual-risk note short.
- **After presenting review findings, stop and ask the user which issues, if any, to fix.** Don't apply fixes from a review automatically, even obvious ones.
- If the tool returns an error, show the most useful error lines and stop. Don't substitute your own answer for Codex's. If the error says Codex is missing or not logged in, point the user to `setup.md`; don't try to log in for them.

## Bash fallback (rare)

Only when the MCP server is unavailable (plugin disabled, server failed to start):

```bash
codex exec --ephemeral --sandbox read-only "prompt" < /dev/null
```

- Pin the model and effort explicitly: `-m gpt-6-sol -c 'model_reasoning_effort="medium"'` (quote the TOML value so the shell keeps it). Use `-m gpt-6-luna -c 'model_reasoning_effort="low"'` for small tasks.
- `--ephemeral` avoids persisting a session to `~/.codex/sessions/`.
- `< /dev/null` stops `codex exec` from waiting on stdin.
- This requires `dangerouslyDisableSandbox: true` because Codex writes to its own state dirs.

If you reach for Bash, first verify MCP really is unavailable: look for `mcp__*_codex` tools in the current tool list, or run `/mcp`.
