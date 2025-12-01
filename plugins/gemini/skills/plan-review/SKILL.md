---
name: plan-review
description: Get Gemini's review of Claude's implementation plans. Trigger when user wants a second opinion on a plan ("have Gemini review this plan", "get second opinion", "critique this plan"), or after Claude creates a plan file that needs validation before implementation.
---

# Plan Review via Gemini

Have Gemini critique Claude's implementation plans for a second perspective.

## Quick Start

```bash
gemini "Review the implementation plan at [plan-file-path] and provide critique" --allowed-tools read_file -o text 2>&1
```

## Pattern

Claude writes plans to `~/.claude/plans/`. Pass the file path to Gemini:

```bash
gemini "Review the plan at ~/.claude/plans/example-plan.md. Consider:
1. Are there gaps or missing steps?
2. Are there risks not addressed?
3. Is the approach optimal?
4. What alternatives should be considered?
Read relevant source files to understand context." --allowed-tools read_file -o text 2>&1
```

## With Source Context

Ask Gemini to also read relevant source files:

```bash
gemini "Review the plan at ~/.claude/plans/auth-refactor.md.
Also read:
- src/auth/login.ts
- src/middleware/session.ts
Evaluate if the plan addresses the actual codebase structure." --allowed-tools read_file -o text 2>&1
```

## Focused Reviews

**Risk assessment:**
```bash
gemini "Review ~/.claude/plans/migration.md for risks:
- Breaking changes
- Data loss potential
- Rollback complexity
- Dependencies that could fail" --allowed-tools read_file -o text
```

**Completeness check:**
```bash
gemini "Review ~/.claude/plans/feature.md for completeness:
- Are all edge cases covered?
- Is testing addressed?
- Are there missing steps?" --allowed-tools read_file -o text
```

## Notes

- Gemini respects `.gitignore` - it cannot read files matching gitignore patterns
- Gemini can only read files in its workspace (project root and subdirectories)
- Plans at `~/.claude/plans/` are accessible for projects under the user's home directory
- For projects outside home, copy the plan to workspace first: `cp ~/.claude/plans/plan.md .`
- Pass file paths to Gemini instead of embedding content
- Requires `dangerouslyDisableSandbox: true` for Bash calls
- May take 2-3 minutes for thorough review with source analysis
- See `references/setup.md` for troubleshooting
