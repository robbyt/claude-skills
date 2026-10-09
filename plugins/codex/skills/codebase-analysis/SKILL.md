---
name: codebase-analysis
description: Codebase analysis via the Codex MCP server with a read-only sandbox. Trigger when user needs architecture overview ("analyze this codebase with Codex", "have Codex map dependencies"), onboarding to unfamiliar code, understanding legacy systems, or identifying technical debt.
---

# Codebase Analysis via Codex

Use Codex to get a second-opinion architectural read of the current project, with the sandbox locked to `read-only`. Codex consults; Claude writes.

## Transport

**Always use the MCP tool.** The plugin's MCP server (`scripts/codex-mcp-server.mjs`, started from `.mcp.json`) runs `codex exec` for each call. Tool name: `mcp__plugin_codex_cli__codex`. If the example below errors with an unknown-tool error, run `/mcp` and substitute the actual prefix (e.g., `mcp__codex_cli__codex`). Shell fallback is a last resort (see `../references/commands.md`).

## Model

**Pin `model: "gpt-6.1-sol"` with `config: { "model_reasoning_effort": "medium" }`** on the opening call. Codebase analysis benefits from the flagship's reasoning across many files — don't downgrade to `gpt-6-luna` here. Set both on the first `codex` call only; `codex-reply` reuses them unless you escalate. Honor an explicit user-named model if given. See `../references/patterns.md` → Models and Reasoning effort. **Escalate to `gpt-6-astra`** (pass `model` + `config` on the `codex-reply`) from round 3, when a disagreement survives a round, or when re-reviewing the same area in a fresh thread — see `../references/patterns.md` → Escalating to gpt-6-astra.

## Basic call

```
mcp__plugin_codex_cli__codex({
  "prompt": "<task>\nAnalyze this project's architecture: entry points, major modules, component relationships, and notable dependencies.\n</task>\n\n<compact_output_contract>\nStructured sections, one per topic. Cite the files each claim is based on.\n</compact_output_contract>\n\n<grounding_rules>\nGround claims in files you read. Label inferences, and list what you could not determine.\n</grounding_rules>",
  "sandbox": "read-only",
  "model": "gpt-6.1-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

The response includes a `threadId`. Use `mcp__plugin_codex_cli__codex-reply` with that id to drill in without re-establishing context.

## When to Use

- Onboarding to an unfamiliar codebase
- Understanding legacy systems
- Mapping component relationships
- Finding hidden dependencies
- Architecture documentation
- Technical debt assessment

## Examples

**Full project analysis:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this project. Report on:\n- Overall architecture\n- Key dependencies\n- Component relationships\n- Potential issues",
  "sandbox": "read-only",
  "model": "gpt-6.1-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

**Flow mapping:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Map the authentication flow. Identify every component involved from request to session creation.",
  "sandbox": "read-only",
  "model": "gpt-6.1-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

**Dependency analysis:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze dependencies: direct vs transitive, outdated packages, circular dependencies, bundle-size impact.",
  "sandbox": "read-only",
  "model": "gpt-6.1-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

## Iterative workflow (prefer `codex-reply`)

When you're still working on the same area of the codebase, **continue the existing thread** rather than starting a new `codex` call. Codex retains context between rounds; fresh calls force it to re-read files and drift from its prior reasoning.

Typical loop:

1. Initial consult → save the `threadId` from the response.
2. Claude reads related files / runs a query / makes a change.
3. `codex-reply` with new findings or a follow-up question.
4. Repeat — but **cap at 3–4 rounds total**, and run round 3 onward on `gpt-6-astra`. If the thread isn't converging, stop and bring the current state back to the user.

**`threadId` is an MCP argument — pass it as the `threadId` field of `codex-reply`, not in the `prompt` text.** See `../references/mcp-schema.md` for wrong-vs-right examples.

**Example — three rounds on the same architecture thread:**

```
# Round 1 — initial map (opening call pins model + effort)
mcp__plugin_codex_cli__codex({
  "prompt": "Map the auth flow end-to-end.",
  "sandbox": "read-only",
  "model": "gpt-6.1-sol",
  "config": { "model_reasoning_effort": "medium" }
})
# → threadId: "019da14b-..."  /  flags: uncertainty about session rotation

# Round 2 — Claude reads src/session/ and reports back
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "src/session/rotate.ts shows a 15m rotation window, not the 1h you assumed. Does that change anything in your flow map?"
})

# Round 3 — drill into a specific layer; escalate to gpt-6-astra (the thread keeps its history)
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Focus on the data layer. What invariants does this flow depend on and where are they enforced?",
  "model": "gpt-6-astra",
  "config": { "model_reasoning_effort": "medium" }
})
```

**Start a fresh thread when:** the user switches topic, the `threadId` is no longer in context, or Claude has made substantial code changes that would be cleaner to re-prime than to patch incrementally. See `../references/patterns.md`.

## After the analysis

Codex's read is a second opinion, not authoritative — it can misread structure or miss context it never saw.

- **Relay the findings** to the user and attribute them to Codex, rather than presenting them as verified fact.
- **Spot-check claims against the actual code** before acting on them (see `../references/patterns.md` → Validation) — especially dependency, impact, and "nothing else uses this" claims.
- **Surface uncertainty or disagreement** to the user instead of smoothing it over into a confident-sounding summary.
- For broad analyses, consider running the `codex:consult` agent in the background. For prompt blocks and recipes, see `../references/prompting.md`.

## Safety

- **Always** `sandbox: "read-only"`. Codex must not modify files.
- Never use `workspace-write` or `danger-full-access`.
- Never use `--dangerously-bypass-approvals-and-sandbox`.

## Fallback (rare)

If the MCP server is unavailable (plugin disabled, server crashed), see `../references/commands.md` for the Bash equivalent. Requires `dangerouslyDisableSandbox: true` because Codex writes its own session state.
