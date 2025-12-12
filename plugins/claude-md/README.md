# claude-md

Tools for managing CLAUDE.md memory files.

## Skills

### reflect

Analyzes recent conversation history to identify improvements for CLAUDE.md memory files.

**Trigger phrases:**
- "reflect on this session"
- "reflect on this conversation"
- "reflect on this code"
- "improve CLAUDE.md by reflecting on this session"

**What it does:**
1. Finds all CLAUDE.md files in the project
2. Analyzes conversation for repeated corrections, misunderstandings, or missing context
3. Proposes specific changes with user approval
4. Updates the appropriate memory file

## Resources

- `skills/reflect/references/memory-locations.md` - Memory file hierarchy and placement guide
- `skills/reflect/references/anti-patterns.md` - Common mistakes to avoid
- `skills/reflect/scripts/find_claude_md.py` - Locate all CLAUDE.md files in a directory tree

## Requirements

- Python 3.x (for find_claude_md.py script)
