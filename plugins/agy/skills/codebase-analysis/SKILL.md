---
name: codebase-analysis
description: Deep architectural analysis of the current workspace using Google Antigravity (`agy`). Trigger when the user needs an architecture overview ("analyze this codebase with agy", "map dependencies with Google Antigravity"), is onboarding to unfamiliar code, exploring legacy systems, or hunting technical debt. Replaces the deprecated gemini-cli `codebase_investigator` workflow.
---

# Codebase Analysis via Google Antigravity (`agy`)

Use Google's Antigravity CLI for deep architectural analysis. `agy` is Google's
agentic successor to `gemini-cli` and runs Google's Gemini models — it can roam the
workspace, follow references, and surface structure that surface-level grep cannot.

## Why `--sandbox` Here

Codebase analysis benefits from broad workspace access — `agy` needs to read many
files, follow imports, and chase references. But it should not run arbitrary shell
commands while doing so. Google Antigravity has no `--allowed-tools` flag, so use
`--sandbox` to grant file access while denying shell execution:

```bash
agy --sandbox --print "..." --dangerously-skip-permissions
```

Pair `--sandbox` with a "Do not make any changes" clause for belt-and-suspenders
safety.

## Quick Start

```bash
agy --sandbox --print "Analyze this project's architecture. Do not make any changes. Respond with analysis only." --dangerously-skip-permissions
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
```bash
agy --sandbox --print "Analyze this project. Report on:
- Overall architecture
- Key dependencies
- Component relationships
- Potential issues
Do not make any changes. Respond with analysis only." --dangerously-skip-permissions
```

**Flow mapping:**
```bash
agy --sandbox --print "Map the authentication flow in this project. Identify all components involved. Do not make any changes. Respond with analysis only." --dangerously-skip-permissions
```

**Dependency analysis:**
```bash
agy --sandbox --print "Analyze this project's dependencies:
- Direct vs transitive
- Outdated packages
- Circular dependencies
- Bundle size impact
Do not make any changes. Respond with analysis only." --dangerously-skip-permissions
```

**Technical debt:**
```bash
agy --sandbox --print "Identify technical debt in this project:
- Deprecated patterns
- Inconsistent conventions
- Missing documentation
- Complex dependency chains
Do not make any changes. Respond with analysis only." --dangerously-skip-permissions
```

## Iterative Analysis

Use `--continue` (still inside `--sandbox`) for multi-turn investigation:

```bash
agy --sandbox --print "Analyze this project. Do not make any changes. Respond with analysis only." --dangerously-skip-permissions

agy --continue --sandbox --print "What patterns did you find in the auth module? Do not make any changes. Respond with analysis only." --dangerously-skip-permissions

agy --continue --sandbox --print "Are there security concerns with that pattern? Do not make any changes. Respond with analysis only." --dangerously-skip-permissions
```

## Notes

- **Google Antigravity must not make any changes; provide analysis ONLY.** `--sandbox` blocks shell side-effects, but the prompt-level clause keeps it from editing files in the workspace.
- `agy` respects `.gitignore` — it cannot read files matching gitignore patterns.
- Can take 5–10 minutes for large codebases; bump `--print-timeout` to `10m` or more for big jobs:
  ```bash
  agy --sandbox --print-timeout 10m --print "..." --dangerously-skip-permissions
  ```
- Requires sandbox bypass on the Bash tool: `dangerouslyDisableSandbox: true` (because Google Antigravity writes session state under `~/.gemini/`, shared with the old gemini-cli).
- Use sessions for iterative exploration.
- See `references/setup.md` and `references/patterns.md` for more.
