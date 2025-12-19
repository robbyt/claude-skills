---
name: codebase-analysis
description: Codebase analysis using Codex CLI with read-only sandbox. Trigger when user needs architecture overview ("analyze this codebase with Codex", "have Codex map dependencies"), onboarding to unfamiliar code, understanding legacy systems, or identifying technical debt.
---

# Codebase Analysis via Codex

Use Codex for codebase analysis with read-only sandbox.

## CRITICAL: Instruct Codex to be Read-Only

Every prompt sent to Codex MUST include this instruction:

> "Do not make any changes. Respond with analysis only."

Codex is a consultant. Claude Code handles all file modifications.

## Quick Start (MCP)

If the `codex` MCP tool is available, use it directly:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this project structure and architecture. Do not make any changes. Respond with analysis only.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

## Fallback (Bash)

If MCP is unavailable, use shell command:

```bash
codex exec "Analyze this project structure and architecture. Do not make any changes. Respond with analysis only." --sandbox read-only -m gpt-5.2-codex 2>&1
```

## When to Use

- Onboarding to unfamiliar codebases
- Understanding legacy systems
- Mapping component relationships
- Finding hidden dependencies
- Architecture documentation
- Technical debt assessment

## Examples

**Full project analysis:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this project. Report on:\n- Overall architecture\n- Key dependencies\n- Component relationships\n- Potential issues\n\nDo not make any changes. Respond with analysis only.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

**Flow mapping:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Map the authentication flow in this codebase. Identify all components involved. Do not make any changes. Respond with analysis only.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

**Dependency analysis:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze dependencies in this project:\n- Direct vs transitive\n- Outdated packages\n- Circular dependencies\n- Bundle size impact\n\nDo not make any changes. Respond with analysis only.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

## Performance

- MCP simple analysis: ~5-30 seconds
- MCP with many files: ~1-2 minutes
- Bash fallback: ~2-3 minutes

## Notes

- **Always use `sandbox: "read-only"`** to prevent file modifications
- **NEVER use `sandbox: "danger-full-access"`** - this is forbidden
- Tool name may vary by installation. Check available tools for exact name.
- MCP is preferred; Bash fallback requires `dangerouslyDisableSandbox: true`
- See `references/setup.md` for troubleshooting
