---
name: web-search
description: Real-time web research using Google Search via Google's Antigravity (`agy`) CLI — the replacement for the deprecated `gemini-cli`. Trigger when user needs current information ("search with agy", "search with Google Antigravity", "find current info about X with agy", "what's the latest on Y"), library/API research, security vulnerability lookups, or comparisons requiring recent data.
---

# Web Search via Google Antigravity (`agy`)

Use Google's Antigravity CLI (`agy`) to run Google-Search-backed web research and
return cited results. Antigravity is Google's successor to `gemini-cli` and runs
Google's Gemini models under the hood.

## Quick Start

```bash
agy --print "Use Google Search to find [topic]. Do not make any changes. Respond with the results only." --dangerously-skip-permissions
```

Google Antigravity has no `--allowed-tools` flag, so the prompt itself must scope
behavior: explicitly ask it to use Google Search and not to make changes.

## When to Use

- Current events and news
- Latest library versions and documentation
- Security vulnerabilities (CVEs)
- Community opinions and benchmarks
- Best-practices research
- Comparison research

## Examples

**Current info:**
```bash
agy --print "Use Google Search to find the latest Next.js 15 features. Do not make any changes. Respond with the results only." --dangerously-skip-permissions
```

**Vulnerability research:**
```bash
agy --print "Use Google Search to find known CVEs affecting lodash 4.x. Do not make any changes. Respond with the results only." --dangerously-skip-permissions
```

**Comparison:**
```bash
agy --print "Use Google Search to find recent benchmarks comparing Zustand vs Jotai for React state management. Do not make any changes. Respond with the results only." --dangerously-skip-permissions
```

**Best practices:**
```bash
agy --print "Use Google Search to find current best practices for Node.js 22 error handling. Do not make any changes. Respond with the results only." --dangerously-skip-permissions
```

## Multi-turn Research

Use `--continue` to refine within the same conversation:

```bash
agy --print "Search for current options for self-hosted vector databases. Do not make any changes. Respond with the results only." --dangerously-skip-permissions

agy --continue --print "Of those, which support hybrid search and quantization? Do not make any changes. Respond with the results only." --dangerously-skip-permissions
```

## Notes

- **Google Antigravity must not make any changes; provide research output ONLY.**
- `agy` has no `--allowed-tools` flag — rely on prompt instructions to keep the call read-only.
- Requires sandbox bypass: use `dangerouslyDisableSandbox: true` when calling via the Bash tool, because agy writes session state under `~/.gemini/` (shared with the old gemini-cli).
- May take 1–2 minutes for comprehensive Google searches; bump `--print-timeout` if needed.
- Validate findings against official documentation.
- See `references/setup.md` and `references/patterns.md` for more.
