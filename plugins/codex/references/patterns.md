# Codex Integration Patterns

Shared patterns for all Codex skills.

## Core Principle

Claude Code handles all code writing, file operations, and commands. Codex provides consulting and second opinions.

## Default Model: gpt-5.2

**ALWAYS use `model: "gpt-5.2"`** (MCP) or `-m gpt-5.2-codex` (Bash) unless the user explicitly requests a different model.

- Default: `gpt-5.2` - use this for all Codex calls
- Alternative: `o3` - ONLY if user explicitly asks for it
- Alternative: `o4-mini` - ONLY if user explicitly asks for it

**Do NOT choose a model on your own.** If the user doesn't specify a model, use `gpt-5.2`.

## Enabling Built-in Tools

Codex has built-in tools that can be enabled via the `config` parameter:

| Feature | Purpose |
|---------|---------|
| `web_search_request` | Allow Codex to search the web |

Example with web search enabled:
```
mcp__plugin_codex_cli__codex({
  "prompt": "Search for the latest SwiftUI changes in iOS 18",
  "sandbox": "read-only",
  "model": "gpt-5.2",
  "config": {
    "features": {
      "web_search_request": true
    }
  }
})
```

## Required Prompt Prefix

Every prompt sent to Codex MUST begin with:

> "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete response immediately."

This prevents Codex from entering interactive mode or waiting for user input.

## MCP vs Bash

**Prefer MCP** when available:

```
mcp__plugin_codex_cli__codex({
  "prompt": "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete analysis immediately.\n\nAnalyze this codebase.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

**Fall back to Bash** if MCP unavailable:

```bash
codex exec "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete analysis immediately.

Analyze this codebase." --sandbox read-only -m gpt-5.2-codex 2>&1
```

## Session Continuity (MCP only)

MCP supports follow-up questions in the same context:

```
# Initial request
mcp__plugin_codex_cli__codex({
  "prompt": "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete analysis immediately.\n\nReview the authentication flow.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
# Returns threadId: "abc123"

# Follow-up
mcp__plugin_codex_cli__codex-reply({
  "prompt": "What about the session handling?",
  "threadId": "abc123"
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
codex exec "You are running non-interactively. Do not ask questions. Do not make changes. Provide feedback immediately.

Review the file at path/to/file.md" --sandbox read-only -m gpt-5.2-codex
```

Do NOT use stdin piping with `$(cat)` - Codex doesn't expand shell command substitution.

## Working with Diffs

For diff review, use `codex review` or save diff to a file:

```bash
# Built-in review command (requires --uncommitted, --base, or --commit)
codex review --uncommitted

# Manual diff review
git diff --cached > codex-review.diff
codex exec "You are running non-interactively. Do not ask questions. Do not make changes. Provide feedback immediately.

Review the diff at codex-review.diff" --sandbox read-only -m gpt-5.2-codex
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
