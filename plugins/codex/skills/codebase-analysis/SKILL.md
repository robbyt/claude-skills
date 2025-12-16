---
name: codebase-analysis
description: Codebase analysis using Codex CLI with read-only sandbox. Trigger when user needs architecture overview ("analyze this codebase with Codex", "have Codex map dependencies"), onboarding to unfamiliar code, understanding legacy systems, or identifying technical debt.
---

# Codebase Analysis via Codex

Use Codex CLI for codebase analysis with read-only sandbox.

## Quick Start

```bash
codex exec "Analyze this project structure and architecture. Do not make any changes. Respond with analysis only." --sandbox read-only --ask-for-approval never 2>&1
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
codex exec "Analyze this project. Report on:
- Overall architecture
- Key dependencies
- Component relationships
- Potential issues

Do not make any changes. Respond with analysis only." --sandbox read-only --ask-for-approval never 2>&1
```

**Flow mapping:**
```bash
codex exec "Map the authentication flow in this codebase. Identify all components involved. Do not make any changes. Respond with analysis only." --sandbox read-only --ask-for-approval never 2>&1
```

**Dependency analysis:**
```bash
codex exec "Analyze dependencies in this project:
- Direct vs transitive
- Outdated packages
- Circular dependencies
- Bundle size impact

Do not make any changes. Respond with analysis only." --sandbox read-only --ask-for-approval never 2>&1
```

**Technical debt:**
```bash
codex exec "Identify technical debt in this codebase:
- Deprecated patterns
- Inconsistent conventions
- Missing documentation
- Complex dependency chains

Do not make any changes. Respond with analysis only." --sandbox read-only --ask-for-approval never 2>&1
```

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **NEVER use `--dangerously-bypass-approvals-and-sandbox` or `--sandbox danger-full-access`** - these disable safety features and are forbidden
- Uses `--sandbox read-only` to prevent file modifications
- Uses `--ask-for-approval never` for non-interactive execution
- If flag errors occur, run `codex --help` to verify correct flag usage
- May take several minutes for large codebases
- Requires `dangerouslyDisableSandbox: true` for Bash calls
- See `references/setup.md` for troubleshooting
