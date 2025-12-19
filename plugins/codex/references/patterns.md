# Codex Integration Patterns

Shared patterns for all Codex skills.

## Core Principle

Claude Code handles all code writing, file operations, and commands. Codex provides consulting and second opinions.

## MCP vs Bash

**Prefer MCP** when available:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Analyze this codebase. Do not make any changes. Respond with analysis only.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

**Fall back to Bash** if MCP unavailable:

```bash
codex exec "Analyze this codebase. Do not make any changes. Respond with analysis only." --sandbox read-only -m gpt-5.2-codex 2>&1
```

## Session Continuity (MCP only)

MCP supports follow-up questions in the same context:

```
# Initial request
mcp__plugin_codex_cli__codex({
  "prompt": "Review the authentication flow",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
# Returns conversation_id: "abc123"

# Follow-up
mcp__plugin_codex_cli__codex-reply({
  "prompt": "What about the session handling?",
  "conversationId": "abc123"
})
```

## Safety Requirements

**NEVER disable safety features:**
- `--dangerously-bypass-approvals-and-sandbox` - FORBIDDEN
- `--sandbox danger-full-access` - FORBIDDEN

These skills are read-only by design. Codex must not modify files.

**If flag errors occur**, run `codex --help` to verify correct flag usage.

## Non-Interactive Execution

Always use these flags for automated integration:

```bash
codex exec "prompt" --sandbox read-only -m gpt-5.2-codex
```

- `exec` - Run without interactive mode
- `--sandbox read-only` - Prevent file modifications
- `-m gpt-5.2-codex` - Preferred model

## File Paths

Codex runs in the current working directory. Use paths relative to project root:
- ✓ `src/components/Button.tsx`
- ✗ `~/projects/myapp/src/components/Button.tsx`

Provide file paths in the prompt and let Codex read them directly:

```bash
# CORRECT - works
codex exec "Review the file at path/to/file.md" --sandbox read-only -m gpt-5.2-codex
```

Do NOT use stdin piping with `$(cat)` - Codex doesn't expand shell command substitution:

```bash
# WRONG - doesn't work
cat file.md | codex exec "Review: $(cat)" --sandbox read-only -m gpt-5.2-codex
```

## Working with Diffs

For diff review, use `codex review` or save diff to a file:

```bash
# Built-in review command (requires --uncommitted, --base, or --commit)
codex review --uncommitted

# Manual diff review
git diff --cached > codex-review.diff
codex exec "Review the diff at codex-review.diff" --sandbox read-only -m gpt-5.2-codex
rm codex-review.diff
```

Note: `codex review` doesn't support `--sandbox` - it's scoped to diffs.

## Validation

Always validate Codex recommendations:

1. **Verify against official docs** - web search may find outdated info
2. **Test recommendations** - don't blindly implement suggestions
3. **Review for context** - Codex may miss project-specific constraints
4. **Get multiple opinions** - use Claude's reasoning to evaluate

## Best Practices

**Do use Codex for:**
- Code review and security audits
- Codebase analysis
- Second opinions on design decisions

**Don't use Codex for:**
- Primary code generation (Claude's job)
- File operations (use Claude's tools)
- Running commands (use Claude's Bash tool)

**Remember:** Claude writes code, Codex provides feedback.
