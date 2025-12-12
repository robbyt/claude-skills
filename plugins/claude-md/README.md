# claude-md

Tools for managing CLAUDE.md memory files.

## Skills

### reflect

Analyzes recent conversation history to identify improvements for CLAUDE.md memory files.

**Trigger phrases:**
- "reflect on CLAUDE.md"
- "improve CLAUDE.md"
- "update my memory"

**What it does:**
1. Finds all CLAUDE.md files in the project
2. Analyzes conversation for repeated corrections, misunderstandings, or missing context
3. Proposes specific changes with user approval
4. Updates the appropriate memory file

## Resources

- `references/memory-locations.md` - Memory file hierarchy and placement guide
- `references/anti-patterns.md` - Common mistakes to avoid
- `scripts/find_claude_md.py` - Locate all CLAUDE.md files in a directory tree

## Requirements

- Python 3.x (for find_claude_md.py script)
