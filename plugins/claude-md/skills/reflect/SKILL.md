---
name: reflect
description: Analyze recent conversation to identify improvements for CLAUDE.md memory files. Trigger when user says "reflect on this session", "reflect on this conversation", "reflect on this code", or "improve CLAUDE.md by reflecting on this session". The verb "reflect" combined with a session/conversation/code subject is the key trigger.
---

# CLAUDE.md Reflection

Analyze recent conversation history to identify improvements for CLAUDE.md memory files.

## Workflow

### Phase 1: Analysis

**Find all CLAUDE.md files:**
```bash
python scripts/find_claude_md.py
```

**Analyze conversation for:**
- Repeated corrections from the user
- Misunderstandings of user requests
- Missing context that caused confusion
- Inconsistencies between responses and user expectations
- Instructions that belong in a different memory file

**Read reference materials:**
- `references/memory-locations.md` - Memory file hierarchy and placement
- `references/anti-patterns.md` - Common mistakes to avoid

### Phase 2: Interaction

Present findings using AskUserQuestion with checkboxes.

**For each suggestion:**
1. Explain the issue found in conversation
2. Propose specific change (add, update, or delete)
3. Identify which memory file to update
4. Show the exact text to add/modify

**Example:**
```
Issue: Repeatedly used 'var' instead of 'const' in JavaScript
Proposal: Add "NEVER use var in JavaScript, use const or let"
File: ./frontend/CLAUDE.md
```

Wait for user approval before implementing.

### Phase 3: Implementation

For approved changes:

1. **Select correct memory file:**
   - `./CLAUDE.md` - Project-wide, shared with team
   - `./.claude/CLAUDE.md` - Alternative project location
   - `./.claude/rules/*.md` - Modular topic-specific rules
   - `~/.claude/CLAUDE.md` - Personal preferences (all projects)
   - `./CLAUDE.local.md` - Personal project-specific (gitignored)

2. **Apply changes:**
   - Keep minimal and targeted
   - Use bullet points, not paragraphs
   - Be specific ("Use 2-space indentation" not "Format code properly")
   - Add emphasis (NEVER, ALWAYS) only where critical
   - Maintain existing structure

3. **Avoid anti-patterns:**
   - NO hyperbolic language (crucial, proper, robust)
   - NO vague instructions (write good code, use best practices)
   - NO historical comments (we used to do X)
   - NO redundant information

## Memory File Hierarchy

| Type | Location | Purpose | Shared |
|------|----------|---------|--------|
| Project | `./CLAUDE.md` | Team instructions | Yes (git) |
| Rules | `./.claude/rules/*.md` | Modular topic rules | Yes (git) |
| User | `~/.claude/CLAUDE.md` | Personal preferences | No |
| Local | `./CLAUDE.local.md` | Personal project prefs | No (gitignored) |

Files higher in hierarchy take precedence. Use `@path/to/file` syntax to import files.

## Resources

- `scripts/find_claude_md.py` - Locate all CLAUDE.md files
- `references/memory-locations.md` - Detailed memory hierarchy docs
- `references/anti-patterns.md` - Common mistakes to avoid
