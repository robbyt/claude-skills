---
name: plan-review
description: Get Codex's review of Claude's implementation plans. Trigger when user wants a second opinion on a plan ("have Codex review this plan", "get second opinion from Codex", "critique this plan with Codex"), or after Claude creates a plan file that needs validation before implementation.
---

# Plan Review via Codex

Have Codex critique Claude's implementation plans for a second perspective.

## Quick Start

```bash
cat ~/.claude/plans/example-plan.md | codex exec "Review this implementation plan:

\$(cat)

Do not make any changes. Provide critique and feedback only." --sandbox read-only --ask-for-approval never 2>&1
```

## Pattern

Claude writes plans to `~/.claude/plans/`. Pipe plan content via stdin since Codex may not have access to that directory:

```bash
cat ~/.claude/plans/example-plan.md | codex exec "Review this implementation plan:

\$(cat)

Consider:
1. Are there gaps or missing steps?
2. Are there risks not addressed?
3. Is the approach optimal?
4. What alternatives should be considered?

Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
```

## With Source Context

Pipe the plan via stdin and let Codex read source files from the project:

```bash
cat ~/.claude/plans/auth-refactor.md | codex exec "Review this implementation plan:

\$(cat)

Also read these source files for context:
- src/auth/login.ts
- src/middleware/session.ts

Evaluate if the plan addresses the actual codebase structure. Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
```

## Focused Reviews

**Risk assessment:**
```bash
cat ~/.claude/plans/migration.md | codex exec "Review this plan for risks:

\$(cat)

Evaluate:
- Breaking changes
- Data loss potential
- Rollback complexity
- Dependencies that could fail

Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
```

**Completeness check:**
```bash
cat ~/.claude/plans/feature.md | codex exec "Review this plan for completeness:

\$(cat)

Evaluate:
- Are all edge cases covered?
- Is testing addressed?
- Are there missing steps?

Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
```

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **NEVER use `--dangerously-bypass-approvals-and-sandbox` or `--sandbox danger-full-access`** - these disable safety features and are forbidden
- Pipe plan content via stdin using `$(cat)` - Codex may not read `~/.claude/plans/` directly
- Uses `--sandbox read-only` to prevent file modifications
- Uses `--ask-for-approval never` for non-interactive execution
- If flag errors occur, run `codex --help` to verify correct flag usage
- Requires `dangerouslyDisableSandbox: true` for Bash calls
- May take 2-3 minutes for thorough review with source analysis
- See `references/setup.md` for troubleshooting
