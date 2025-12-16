---
name: web-search
description: Real-time web research using Codex CLI's search capability. Trigger when user needs current information ("search with Codex", "find current info about X", "what's the latest on Y"), library/API research, security vulnerability lookups, or comparisons requiring recent data.
---

# Web Search via Codex

Use Codex CLI's `--search` flag for real-time internet research.

## Quick Start

```bash
codex exec "Search for [topic]. Do not make any changes. Respond with the results only." --search --sandbox read-only --ask-for-approval never 2>&1
```

## When to Use

- Current events and news
- Latest library versions and documentation
- Security vulnerabilities (CVEs)
- Community opinions and benchmarks
- Best practices research
- Comparison research

## Examples

**Current info:**
```bash
codex exec "What are the latest Next.js 15 features? Do not make any changes. Respond with the results only." --search --sandbox read-only --ask-for-approval never 2>&1
```

**Vulnerability research:**
```bash
codex exec "What are known CVEs for lodash 4.x? Do not make any changes. Respond with the results only." --search --sandbox read-only --ask-for-approval never 2>&1
```

**Comparison:**
```bash
codex exec "Compare Zustand vs Jotai for React state management with recent benchmarks. Do not make any changes. Respond with the results only." --search --sandbox read-only --ask-for-approval never 2>&1
```

**Best practices:**
```bash
codex exec "Current best practices for Node.js 22 error handling? Do not make any changes. Respond with the results only." --search --sandbox read-only --ask-for-approval never 2>&1
```

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **NEVER use `--dangerously-bypass-approvals-and-sandbox` or `--sandbox danger-full-access`** - these disable safety features and are forbidden
- Uses `--search` to enable web search capability
- Uses `--sandbox read-only` to prevent file modifications
- Uses `--ask-for-approval never` for non-interactive execution
- If flag errors occur, run `codex --help` to verify correct flag usage
- Requires `dangerouslyDisableSandbox: true` for Bash calls
- May take 1-2 minutes for comprehensive searches
- Validate findings against official documentation
- See `references/setup.md` for troubleshooting
