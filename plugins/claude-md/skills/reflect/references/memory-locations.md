# Memory File Locations

Reference: https://code.claude.com/docs/en/memory

## Memory Types

| Type | Location | Purpose | Shared |
|------|----------|---------|--------|
| Enterprise policy | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br/>Linux: `/etc/claude-code/CLAUDE.md` | Organization-wide instructions | All users in org |
| Project memory | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared project instructions | Team (git) |
| Project rules | `./.claude/rules/*.md` | Modular topic-specific rules | Team (git) |
| User memory | `~/.claude/CLAUDE.md` | Personal preferences (all projects) | Just you |
| Project local | `./CLAUDE.local.md` | Personal project-specific prefs | Just you (gitignored) |

Files higher in hierarchy take precedence and load first.

## File Lookup

Memory files are read recursively from the current working directory up to (but not including) the root directory. Useful for monorepos where you run from `foo/bar/` and have memories in both `foo/CLAUDE.md` and `foo/bar/CLAUDE.md`.

Nested CLAUDE.md files in subtrees are discovered but only loaded when files in those subtrees are read.

## Imports

CLAUDE.md files can import additional files using `@path/to/import` syntax:

```
See @README for project overview and @package.json for available npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
- @~/.claude/my-project-instructions.md
```

- Both relative and absolute paths allowed
- Imports not evaluated inside code spans or blocks
- Max depth: 5 hops

## Modular Rules (.claude/rules/)

Organize instructions into multiple files:

```
your-project/
├── .claude/
│   ├── CLAUDE.md
│   └── rules/
│       ├── code-style.md
│       ├── testing.md
│       └── security.md
```

All `.md` files in `.claude/rules/` are loaded as project memory.

### Path-Specific Rules

Use YAML frontmatter to scope rules to specific files:

```markdown
---
paths: src/api/**/*.ts
---

# API Development Rules
- All API endpoints must include input validation
```

Rules without `paths` apply to all files.

### Glob Patterns

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All TypeScript files |
| `src/**/*` | All files under src/ |
| `*.md` | Markdown files in project root |
| `src/components/*.tsx` | React components in specific dir |

Use braces for multiple patterns: `src/**/*.{ts,tsx}` or `{src,lib}/**/*.ts`

## Quick Memory Commands

- `#` prefix: Add quick memory (prompts for file selection)
- `/memory`: Open memory file in editor
- `/init`: Bootstrap CLAUDE.md for codebase

## Placement Guidelines

**Root CLAUDE.md:**
- Project-wide guidelines
- Common commands and workflows
- Links to subdirectory files

**Subdirectory CLAUDE.md:**
- Component-specific guidance
- Referenced from root CLAUDE.md

**~/.claude/CLAUDE.md:**
- Personal preferences
- Tooling shortcuts
- Cross-project defaults

**CLAUDE.local.md:**
- Machine-specific config
- Personal sandbox URLs
- Test data preferences
