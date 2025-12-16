# Codex Integration Patterns

Shared patterns for all Codex skills.

## Core Principle

Claude Code handles all code writing, file operations, and commands. Codex provides consulting (second opinions) and search capabilities.

## Safety Requirements

**NEVER disable safety features:**
- `--dangerously-bypass-approvals-and-sandbox` - FORBIDDEN
- `--sandbox danger-full-access` - FORBIDDEN

These skills are read-only by design. Codex must not modify files.

**If flag errors occur**, run `codex --help` to verify correct flag usage.

## Non-Interactive Execution

Always use these flags for automated integration:

```bash
codex exec "prompt" --sandbox read-only --ask-for-approval never
```

- `exec` - Run without interactive mode
- `--sandbox read-only` - Prevent file modifications
- `--ask-for-approval never` - Don't wait for user input

## Working with Diffs

For diff review, use `codex review` or save diff to a file:

```bash
# Built-in review command
codex review

# Manual diff review
git diff --cached > codex-review.diff
codex exec "Review the diff at codex-review.diff" --sandbox read-only --ask-for-approval never
rm codex-review.diff
```

## Web Search

Enable web search with `--search`:

```bash
codex exec "What are the latest TypeScript 5.x features?" --search --sandbox read-only --ask-for-approval never
```

## Validation

Always validate Codex recommendations:

1. **Verify against official docs** - web search may find outdated info
2. **Test recommendations** - don't blindly implement suggestions
3. **Review for context** - Codex may miss project-specific constraints
4. **Get multiple opinions** - use Claude's reasoning to evaluate

## Best Practices

**Do use Codex for:**
- Code review and security audits
- Web research for current information
- Codebase analysis
- Second opinions on design decisions

**Don't use Codex for:**
- Primary code generation (Claude's job)
- File operations (use Claude's tools)
- Running commands (use Claude's Bash tool)

**Remember:** Claude writes code, Codex provides feedback.
