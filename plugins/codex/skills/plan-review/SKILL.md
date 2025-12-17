---
name: plan-review
description: Get Codex's review of Claude's implementation plans. Trigger when user wants a second opinion on a plan ("have Codex review this plan", "get second opinion from Codex", "critique this plan with Codex"), or after Claude creates a plan file that needs validation before implementation.
---

# Plan Review via Codex

Have Codex critique Claude's implementation plans for a second perspective.

## Quick Start (MCP)

If the `codex` MCP tool is available, read the plan and pass it to Codex:

First, read the plan file content, then:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this implementation plan:\n\n[PLAN CONTENT HERE]\n\nConsider:\n1. Are there gaps or missing steps?\n2. Are there risks not addressed?\n3. Is the approach optimal?\n4. What alternatives should be considered?\n\nDo not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

## Fallback (Bash)

If MCP is unavailable, tell Codex to read the file directly:

```bash
codex exec "Review the implementation plan at path/to/plan.md

Consider:
1. Are there gaps or missing steps?
2. Are there risks not addressed?
3. Is the approach optimal?

Do not make any changes. Respond with feedback only." --sandbox read-only 2>&1
```

**Note:** Do NOT use stdin piping with `$(cat)` - Codex doesn't expand shell command substitution. Instead, provide file paths in the prompt and let Codex read them directly.

## With Source Context

Include source files for context in the prompt:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this implementation plan:\n\n[PLAN CONTENT]\n\nAlso read these source files for context:\n- src/auth/login.ts\n- src/middleware/session.ts\n\nEvaluate if the plan addresses the actual codebase structure. Do not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

## Focused Reviews

**Risk assessment:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this plan for risks:\n\n[PLAN CONTENT]\n\nEvaluate:\n- Breaking changes\n- Data loss potential\n- Rollback complexity\n- Dependencies that could fail\n\nDo not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

**Completeness check:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Review this plan for completeness:\n\n[PLAN CONTENT]\n\nEvaluate:\n- Are all edge cases covered?\n- Is testing addressed?\n- Are there missing steps?\n\nDo not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

## Recommended Pattern

1. Use Claude's Read tool to get plan file content
2. Embed content directly in the Codex prompt
3. List additional source files for Codex to read from project

## Performance

- MCP plan review: ~5-30 seconds
- MCP with source files: ~1-2 minutes
- Bash fallback: ~2-3 minutes

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **Always use `sandbox: "read-only"`** to prevent file modifications
- **NEVER use `sandbox: "danger-full-access"`** - this is forbidden
- Tool name may vary by installation. Check available tools for exact name.
- Read plan file content first, then include in prompt (Codex may not access ~/.claude/plans/)
- MCP is preferred; Bash fallback requires `dangerouslyDisableSandbox: true`
- See `references/setup.md` for troubleshooting
