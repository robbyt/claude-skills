---
name: web-search
description: Real-time web research using Codex CLI's search capability. Trigger when user needs current information ("search with Codex", "find current info about X", "what's the latest on Y"), library/API research, security vulnerability lookups, or comparisons requiring recent data.
---

# Web Search via Codex

Use Codex for real-time internet research.

## Quick Start (MCP)

If the `codex` MCP tool is available, use it with web search enabled:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Search for [topic]. Do not make any changes. Respond with the results only.",
  "sandbox": "read-only"
})
```

Note: Web search is enabled by default in Codex MCP mode.

## Fallback (Bash)

If MCP is unavailable, use shell command with `--search` flag:

```bash
codex "Search for [topic]. Do not make any changes. Respond with the results only." --search --sandbox read-only 2>&1
```

Note: `--search` is only available on the main `codex` command, not `codex exec`.

## When to Use

- Current events and news
- Latest library versions and documentation
- Security vulnerabilities (CVEs)
- Community opinions and benchmarks
- Best practices research
- Comparison research

## Examples

**Current info:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "What are the latest Next.js 15 features? Do not make any changes. Respond with the results only.",
  "sandbox": "read-only"
})
```

**Vulnerability research:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "What are known CVEs for lodash 4.x? Do not make any changes. Respond with the results only.",
  "sandbox": "read-only"
})
```

**Comparison:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Compare Zustand vs Jotai for React state management with recent benchmarks. Do not make any changes. Respond with the results only.",
  "sandbox": "read-only"
})
```

**Best practices:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Current best practices for Node.js 22 error handling? Do not make any changes. Respond with the results only.",
  "sandbox": "read-only"
})
```

## Performance

- MCP search: ~5-30 seconds
- Bash fallback with --search: ~1-2 minutes

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **Always use `sandbox: "read-only"`** to prevent file modifications
- **NEVER use `sandbox: "danger-full-access"`** - this is forbidden
- Tool name may vary by installation. Check available tools for exact name.
- MCP is preferred; Bash fallback requires `dangerouslyDisableSandbox: true`
- Bash uses `codex` (not `codex exec`) because `--search` is only on main command
- Validate findings against official documentation
- See `references/setup.md` for troubleshooting
