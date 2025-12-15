---
name: web-search
description: Real-time web research using Gemini's Google Search. Trigger when user needs current information ("search with Gemini", "find current info about X", "what's the latest on Y"), library/API research, security vulnerability lookups, or comparisons requiring recent data.
---

# Web Search via Gemini

Use Gemini's `google_web_search` tool for real-time internet research.

## Quick Start

```bash
gemini "Use Google Search to find [topic]. Do not make any changes. Respond with the results only." --allowed-tools google_web_search -o text 2>&1
```

Use `-m gemini-2.5-flash` for faster searches:
```bash
gemini "Latest version of React? Do not make any changes. Respond with the results only." --allowed-tools google_web_search -m gemini-2.5-flash -o text 2>&1
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
gemini "What are the latest Next.js 15 features? Use Google Search. Do not make any changes. Respond with the results only." --allowed-tools google_web_search -o text
```

**Vulnerability research:**
```bash
gemini "What are known CVEs for lodash 4.x? Use Google Search. Do not make any changes. Respond with the results only." --allowed-tools google_web_search -o text
```

**Comparison:**
```bash
gemini "Compare Zustand vs Jotai for React state management. Use Google Search for recent benchmarks. Do not make any changes. Respond with the results only." --allowed-tools google_web_search -o text
```

**Best practices:**
```bash
gemini "Current best practices for Node.js 22 error handling? Use Google Search. Do not make any changes. Respond with the results only." --allowed-tools google_web_search -o text
```

## Notes

- **Gemini must not make any changes, provide feedback ONLY.**
- Requires sandbox bypass: use `dangerouslyDisableSandbox: true`
- May take 1-2 minutes for comprehensive searches
- Validate findings against official documentation
- See `references/setup.md` for troubleshooting
