# claude-md-reflect

Analyzes chat history to identify improvements for CLAUDE.md instruction files.

## Usage

```
reflect on CLAUDE.md
```

## What it does

- Reviews session history for misunderstandings and issues
- Proposes specific CLAUDE.md improvements
- Presents changes with checkboxes for approval
- Updates CLAUDE.md files with approved changes

## How it works

1. **Analysis Phase**: Uses an agent to analyze the entire session history and find all CLAUDE.md files in the repository
2. **Interaction Phase**: Presents findings with checkboxes for user approval
3. **Implementation Phase**: Updates approved changes to the appropriate CLAUDE.md files

## Resources

- `scripts/find_claude_md.py` - Locates all CLAUDE.md files
- `references/anthropic-best-practices.md` - Official CLAUDE.md guidelines
- `references/anti-patterns.md` - Common mistakes to avoid
