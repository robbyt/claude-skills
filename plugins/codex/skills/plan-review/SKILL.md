---
name: plan-review
description: Get Codex's review of Claude's implementation plans via the Codex MCP server. Trigger when user wants a second opinion on a plan ("have Codex review this plan", "get second opinion from Codex", "critique this plan with Codex"), or after Claude creates a plan file that needs validation before implementation.
---

# Plan Review via Codex

Use Codex to critique implementation plans for gaps, risks, and better alternatives. Codex consults; Claude writes.

## Transport

**Always use the MCP tool.** The plugin runs `codex mcp-server` on stdio via `.mcp.json`. Tool name: `mcp__plugin_codex_cli__codex`. If the example below errors with an unknown-tool error, run `/mcp` and substitute the actual prefix (e.g., `mcp__codex_cli__codex`).

## Model

**Omit `model` to use the default (`gpt-5.5`).** Plan review benefits from flagship reasoning — don't downgrade to `gpt-5.4-mini` here. Only set `model` if the user explicitly names one. See `../references/patterns.md`.

## Flow

Codex reads files from the project root. For plans living outside the repo (e.g., `~/.claude/plans/...`), **read them with Claude's `Read` tool first and embed the content in the prompt.** Codex doesn't expand shell substitutions and can't see paths outside its `cwd`.

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this implementation plan:\n\n---\n[PLAN CONTENT HERE]\n---\n\nConsider:\n1. Gaps or missing steps?\n2. Risks not addressed?\n3. Is the approach optimal? What alternatives should we consider?",
  "sandbox": "read-only"
})
```

If the plan lives inside the repo, you can just reference the path:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review the implementation plan at docs/plans/auth-rewrite.md. Flag gaps, risks, and better alternatives.",
  "sandbox": "read-only"
})
```

## With source context

Let Codex cross-check the plan against the actual code:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this plan:\n\n[PLAN CONTENT]\n\nRead these source files for context before critiquing:\n- src/auth/login.ts\n- src/middleware/session.ts\n\nEvaluate whether the plan accounts for the real code structure.",
  "sandbox": "read-only"
})
```

## Focused reviews

**Risk assessment:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Risk review of this plan:\n\n[PLAN CONTENT]\n\nEvaluate:\n- Breaking changes\n- Data loss potential\n- Rollback complexity\n- Dependencies that could fail",
  "sandbox": "read-only"
})
```

**Completeness check:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Completeness review of this plan:\n\n[PLAN CONTENT]\n\nEvaluate:\n- Edge cases covered?\n- Testing addressed?\n- Missing steps?",
  "sandbox": "read-only"
})
```

## Iterative workflow (prefer `codex-reply`)

When you're still iterating on the same plan, **continue the existing thread** rather than starting a new `codex` call. Codex keeps the plan and its prior critique in context; starting fresh discards that reasoning and forces re-reading.

Typical loop: initial critique → Claude revises the plan → `codex-reply` with the revised sections asking "does this address your concern?" → Codex confirms or pushes back → repeat.

**Cap at 3–4 rounds total.** Plan review should converge fast; if you're still going at round 5, stop and surface the open questions to the user rather than letting the dialog spiral.

**`threadId` is an MCP argument — pass it as the `threadId` field of `codex-reply`, not in the `prompt` text.** See `../references/mcp-schema.md` for wrong-vs-right examples.

**Example — three rounds on the same plan:**

```
# Round 1 — initial critique
mcp__plugin_codex_cli__codex({
  "prompt": "Review this plan:\n\n[PLAN CONTENT]\n\nFlag gaps, risks, and better alternatives.",
  "sandbox": "read-only"
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

## Recommended pattern

1. If the plan is outside the workspace, use Claude's `Read` to fetch it.
2. Embed the plan content in the Codex prompt.
3. List any in-repo source files Codex should read for context.
4. Use `codex-reply` to drill in rather than starting new threads.

## Performance

- Plan-only review: ~5–30 s
- Plan + source cross-check: ~1–2 min

## Safety

- **Always** `sandbox: "read-only"`.
- Never use `workspace-write`, `danger-full-access`, or `--dangerously-bypass-approvals-and-sandbox`.

## Fallback (rare)

If the MCP server is unavailable, see `../references/commands.md` for the Bash `codex exec` form. Requires `dangerouslyDisableSandbox: true`. Don't pipe with `$(cat plan.md)` — Codex doesn't expand shell substitutions; either embed the content or pass a repo-relative path.
