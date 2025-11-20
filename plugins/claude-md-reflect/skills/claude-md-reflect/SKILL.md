---
name: claude-md-reflect
description: Analyze chat history to identify areas for improving CLAUDE.md instruction files. Use when the user says "reflect on CLAUDE.md", "improve CLAUDE.md", or requests analysis of instruction files after a work session. Reviews recent conversation for misunderstandings, inconsistencies, or areas where instructions could be clearer.
---

# CLAUDE.md Reflection and Improvement

## Overview

This skill analyzes recent chat history and existing CLAUDE.md files to identify improvement opportunities. It follows a three-phase workflow: Analysis, Interaction, and Implementation.

## When to Use

Trigger this skill when the user requests:
- "reflect on CLAUDE.md"
- "improve CLAUDE.md"
- Analysis of instruction files after encountering issues

## Workflow

### Phase 1: Analysis

Use the Task tool with subagent_type='general-purpose' to analyze the entire session history.

**Find all CLAUDE.md files:**
```bash
python scripts/find_claude_md.py
```

The script returns paths to all CLAUDE.md files in the repository, sorted by depth (root first).

**Analyze for:**
- Inconsistencies in Claude's responses vs user expectations
- Misunderstandings of user requests
- Areas where Claude lacked necessary context
- Repetitive corrections from the user
- Common mistakes or confusion patterns
- Instructions that belong in a different CLAUDE.md file

**Read reference materials:**
- Read `references/anthropic-best-practices.md` for official CLAUDE.md guidelines
- Read `references/anti-patterns.md` for common mistakes to avoid

### Phase 2: Interaction

Present findings to the user using the AskUserQuestion tool with checkboxes.

**For each suggested improvement:**
1. Explain the issue identified in chat history
2. Propose a specific change (add, update, or delete content)
3. Show which CLAUDE.md file to update
4. Explain the rationale and expected impact

**Format suggestions as:**
- Clear, actionable changes
- Specific text additions or modifications
- NOT vague improvements

**Example:**
```
Issue: Claude repeatedly used 'var' instead of 'const' in JavaScript code
Proposal: Add to CLAUDE.md: "NEVER use var in JavaScript, use const or let"
File: ./frontend/CLAUDE.md
Rationale: Prevents repeated corrections for JavaScript variable declarations
```

Wait for user approval on each suggestion before proceeding to implementation.

### Phase 3: Implementation

For each approved change:

1. **Identify correct file and section:**
   - Root CLAUDE.md: Project-wide guidance
   - Subdirectory CLAUDE.md: Component-specific guidance
   - User CLAUDE.md (~/.claude/CLAUDE.md): Personal preferences

2. **Update the file:**
   - Add, update, or delete content as approved
   - Keep changes minimal and targeted
   - Maintain existing structure and formatting
   - Use bullet points, not paragraphs
   - Add emphasis (NEVER, ALWAYS, IMPORTANT) where critical

3. **Follow anti-patterns guidance:**
   - NO hyperbolic language (crucial, proper, robust, excellent)
   - NO vague instructions (write good code, use best practices)
   - NO historical comments (we used to do X, now we do Y)
   - NO redundant information
   - KEEP it concise and actionable

4. **Verify hierarchy:**
   - Root CLAUDE.md should link to subdirectory CLAUDE.md files
   - Instructions should be in the most appropriate file for their scope

## File Organization

**Root CLAUDE.md:**
- Project-wide guidelines
- Links to subdirectory CLAUDE.md files
- Common commands and workflows

**Subdirectory CLAUDE.md:**
- Component-specific guidance
- Should be referenced from root CLAUDE.md

**Example root CLAUDE.md structure:**
```
# Project Instructions

## Subdirectories
- Frontend: @frontend/CLAUDE.md
- Backend: @backend/CLAUDE.md

## Commands
- npm run build: Build all components
- npm test: Run all tests

## Code Style
- Use 2-space indentation
- NEVER commit directly to main branch
```

## Resources

- `scripts/find_claude_md.py` - Locate all CLAUDE.md files in repository
- `references/anthropic-best-practices.md` - Official Anthropic CLAUDE.md guidelines
- `references/anti-patterns.md` - Common mistakes to avoid
