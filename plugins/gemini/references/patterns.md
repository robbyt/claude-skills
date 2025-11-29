# Gemini Integration Patterns

Shared patterns for all Gemini skills.

## Core Principle

Claude Code handles all code writing, file operations, and commands. Gemini provides consulting (second opinions) and search capabilities.

## Model Selection

```
Deep analysis or complex review?
├── Yes → Use default (Gemini 3 Pro)
└── No → Use gemini-2.5-flash
```

```bash
# Deep analysis - use Pro (default)
gemini "Use codebase_investigator to analyze architecture" -o text

# Quick search - use Flash
gemini "Latest React version?" -m gemini-2.5-flash -o text
```

## Rate Limit Management

Free tier: 60/min, 1000/day. Strategies:

**Let auto-retry handle it:** CLI retries automatically with backoff.

**Use Flash for lower priority:** Flash has separate quota.

**Batch related questions:**
```bash
# Instead of multiple calls, batch them:
gemini "Review files A, B, and C. For each, identify bugs." -o text
```

## Session Continuity

Use sessions for multi-turn consultations:

```bash
# Initial analysis (session saved automatically)
gemini "Use codebase_investigator to analyze this project" -o text

# Continue in same session
echo "What patterns did you find?" | gemini -r 1 -o text
```

## Validation

Always validate Gemini's recommendations:

1. **Verify against official docs** - web search may find outdated info
2. **Test recommendations** - don't blindly implement suggestions
3. **Review for context** - Gemini may miss project-specific constraints
4. **Get multiple opinions** - use Claude's reasoning to evaluate

## Best Practices

**Do use Gemini for:**
- Code review and security audits
- Web research for current information
- Architecture analysis
- Second opinions on design decisions

**Don't use Gemini for:**
- Primary code generation (Claude's job)
- File operations (use Claude's tools)
- Running commands (use Claude's Bash tool)

**Remember:** Claude writes code, Gemini provides feedback.
