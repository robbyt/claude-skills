---
name: plan-review
description: Get Codex's review of an implementation plan before the user starts building — trigger when they want Codex (or a named GPT model like gpt-5.6) to review, critique, or pressure-test a plan. Applies to any plan-shaped artifact — a plan file, plan-mode plan, a migration/rearchitecture/integration/checkout write-up, or a doc describing how they intend to do something (pasted, at a repo path, or just described). Fire on any second-opinion phrasing — "poke holes in it", "sanity-check my plan", "run this past Codex", "get Codex's take", "flag the biggest risks", "look this over before I start", "did I miss edge cases, testing, or a rollback path?". The point is catching gaps, risks, missing steps, and better alternatives ahead of implementation. Do NOT use for reviewing already-written code or diffs (that's diff-review), mapping an existing codebase's architecture (codebase-analysis), or web/research questions.
---

# Plan Review via Codex

Use Codex to critique implementation plans for gaps, risks, and better alternatives. Codex consults; Claude writes.

## Transport

**Always use the MCP tool.** The plugin runs `codex mcp-server` on stdio via `.mcp.json`. Tool name: `mcp__plugin_codex_cli__codex`. If the example below errors with an unknown-tool error, run `/mcp` and substitute the actual prefix (e.g., `mcp__codex_cli__codex`).

## Model

**Pin `model: "gpt-5.6-sol"` with `config: { "model_reasoning_effort": "medium" }`** on the opening call. Plan review benefits from flagship reasoning — don't downgrade to `gpt-5.6-luna` here. Set both on the first `codex` call only; `codex-reply` inherits them. Honor an explicit user-named model if given. See `../references/patterns.md` → Models and Reasoning effort.

## Flow

Codex reads files from the project root. For plans living outside the repo (e.g., `~/.claude/plans/...`), **read them with Claude's `Read` tool first and embed the content in the prompt** — Codex can't see paths outside its `cwd`.

**Give Codex enough context to critique against reality, not assumptions.** A plan reviewed blind gets flagged for things you've already handled. State the plan's goal, the hard constraints it must respect (tech stack, deadlines, backward-compat, what's already decided), and what's deliberately out of scope. The critique is only as good as the context you prime it with.

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this implementation plan:\n\n---\n[PLAN CONTENT HERE]\n---\n\nConsider:\n1. Gaps or missing steps?\n2. Risks not addressed?\n3. Is the approach optimal? What alternatives should we consider?",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

If the plan lives inside the repo, you can just reference the path:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review the implementation plan at docs/plans/auth-rewrite.md. Flag gaps, risks, and better alternatives.",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

## With source context

Let Codex cross-check the plan against the actual code:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this plan:\n\n[PLAN CONTENT]\n\nRead these source files for context before critiquing:\n- src/auth/login.ts\n- src/middleware/session.ts\n\nEvaluate whether the plan accounts for the real code structure.",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

## Focused reviews

**Risk assessment:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Risk review of this plan:\n\n[PLAN CONTENT]\n\nEvaluate:\n- Breaking changes\n- Data loss potential\n- Rollback complexity\n- Dependencies that could fail",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

**Completeness check:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Completeness review of this plan:\n\n[PLAN CONTENT]\n\nEvaluate:\n- Edge cases covered?\n- Testing addressed?\n- Missing steps?",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

## Iterative workflow (prefer `codex-reply`)

When you're still iterating on the same plan, **continue the existing thread** rather than starting a new `codex` call. Codex keeps the plan and its prior critique in context; starting fresh discards that reasoning and forces re-reading.

Typical loop: initial critique → Claude revises the plan → `codex-reply` with the revised sections asking "does this address your concern?" → Codex confirms or pushes back → repeat.

**Cap at 3–4 rounds total.** Plan review should converge fast; if you're still going at round 5, stop and surface the open questions to the user rather than letting the dialog spiral.

**`threadId` is an MCP argument — pass it as the `threadId` field of `codex-reply`, not in the `prompt` text.** See `../references/mcp-schema.md` for wrong-vs-right examples.

**Example — three rounds on the same plan:**

```
# Round 1 — initial critique (opening call pins model + effort)
mcp__plugin_codex_cli__codex({
  "prompt": "Review this plan:\n\n[PLAN CONTENT]\n\nFlag gaps, risks, and better alternatives.",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
# → threadId: "019da14b-..."  /  flags: "No rollback strategy for the schema migration in step 3."

# Round 2 — Claude revises and resubmits only the changed section
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Revised step 3 to use an expand-contract migration with a reversible intermediate state:\n\n[REVISED SECTION]\n\nDoes this address the rollback concern?"
})

# Round 3 — triage remaining risks
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Of the risks you flagged, which would actually block merge vs. which can be mitigated post-launch?"
})
```

**Start a fresh thread when:** reviewing a different plan, the `threadId` is no longer in context, or the plan has been rewritten so substantially that re-priming is cleaner than patching. See `../references/patterns.md`.

## After the review

Codex's critique is input, not instructions — treat it the way you'd treat a thoughtful colleague's review, not a verdict.

- **Relay it.** Surface the findings to the user (or act on them); don't silently absorb a critique and quietly rewrite the plan as if it were your own conclusion.
- **Don't auto-apply.** Codex can be wrong or miss project context it never saw (see `../references/patterns.md` → Validation). Weigh each point against the actual constraints before revising.
- **Surface genuine disagreements to the user** rather than looping with Codex to force consensus — if you and Codex still differ after a round or two, that disagreement is exactly what the user needs to see.

## Safety

- **Always** `sandbox: "read-only"`.
- Never use `workspace-write`, `danger-full-access`, or `--dangerously-bypass-approvals-and-sandbox`.

## Fallback (rare)

If the MCP server is unavailable, see `../references/commands.md` for the Bash `codex exec` form. Requires `dangerouslyDisableSandbox: true`. Don't pipe with `$(cat plan.md)` — Codex doesn't expand shell substitutions; either embed the content or pass a repo-relative path.
