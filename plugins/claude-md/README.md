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

### condense

Deduplicates and consolidates CLAUDE.md memory files to remove redundancy.

**Trigger phrases:**
- "condense my CLAUDE.md files"
- "deduplicate CLAUDE.md"
- "clean up my memory files"
- "consolidate my instructions"

**What it does:**
1. Finds all CLAUDE.md files in the project
2. Identifies duplication within and across files
3. Detects misplaced instructions (subdirectory content that belongs in root or vice versa)
4. Proposes consolidation with user approval
5. Removes duplicates and reorganizes content

## Resources

- `skills/reflect/references/memory-locations.md` - Memory file hierarchy and placement guide
- `skills/reflect/references/anti-patterns.md` - Common mistakes to avoid
- `skills/reflect/scripts/find_claude_md.py` - Locate all CLAUDE.md files in a directory tree

## Requirements

- Python 3.x (for find_claude_md.py script)
