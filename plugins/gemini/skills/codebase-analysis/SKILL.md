---
name: codebase-analysis
description: Deep architectural analysis using Gemini's codebase_investigator tool. Trigger when user needs architecture overview ("analyze this codebase", "map dependencies"), onboarding to unfamiliar code, understanding legacy systems, or identifying technical debt.
---

# Codebase Analysis via Gemini

Use Gemini's `codebase_investigator` tool for deep architectural analysis.

## Quick Start

```bash
gemini "Use codebase_investigator to analyze this project" -o text 2>&1
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
gemini "Use codebase_investigator to analyze this project. Report on:
- Overall architecture
- Key dependencies
- Component relationships
- Potential issues" -o text
```

**Flow mapping:**
```bash
gemini "Use codebase_investigator to map the authentication flow. Identify all components involved." -o text
```

**Dependency analysis:**
```bash
gemini "Use codebase_investigator to analyze dependencies:
- Direct vs transitive
- Outdated packages
- Circular dependencies
- Bundle size impact" -o text
```

**Technical debt:**
```bash
gemini "Use codebase_investigator to identify technical debt:
- Deprecated patterns
- Inconsistent conventions
- Missing documentation
- Complex dependency chains" -o text
```

## Iterative Analysis

Use sessions for multi-turn investigation:

```bash
# Initial analysis
gemini "Use codebase_investigator to analyze this project" -o text

# Follow-up (continues session)
echo "What patterns did you find in the auth module?" | gemini -r 1 -o text

# Deeper dive
echo "Are there security concerns with that pattern?" | gemini -r 1 -o text
```

## Notes

- Can take 5-10 minutes for large codebases
- Requires sandbox bypass: use `dangerouslyDisableSandbox: true`
- Use sessions for iterative exploration
- See `references/setup.md` for troubleshooting
