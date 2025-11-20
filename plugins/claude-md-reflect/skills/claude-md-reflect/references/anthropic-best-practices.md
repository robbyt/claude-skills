# CLAUDE.md Best Practices

Reference: Official Anthropic documentation

## What to Include

- Common bash commands with descriptions
- Core files and utility functions
- Code style guidelines
- Testing instructions and workflows
- Repository etiquette (branch naming, merge vs. rebase)
- Developer environment setup (tool versions, compiler requirements)
- Project-specific quirks or unexpected behaviors
- Information to remember across sessions

## Format and Structure

- Keep concise and human-readable
- Use simple lists with brief explanations
- Use bullet points, not lengthy prose
- Use descriptive markdown headings to organize related items

Example:
```
# Bash commands
- npm run build: Build the project
- npm run test: Run test suite

# Code style
- Use ES modules syntax
- Destructure imports when possible
```

## File Placement

- **Repository root**: `./CLAUDE.md` or `./.claude/CLAUDE.md` (checked into git for team sharing)
- **Subdirectories**: In monorepos for project-specific guidance
- **Home folder**: `~/.claude/CLAUDE.md` for personal preferences across all sessions
- **Local variants**: `./CLAUDE.local.md` (.gitignored) for machine-specific configuration

## CLAUDE.md Hierarchy

Files are loaded recursively from current directory up to root, in this order:
1. Enterprise policy (system-wide)
2. Project memory (repository root)
3. User memory (home folder)
4. Project memory local (current project only)

Files higher in hierarchy take precedence.

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

## Best Practices

- **Be specific**: "Use 2-space indentation" not "Format code properly"
- **Use structure**: Format as bullet points, group under descriptive headings
- **Iterate continuously**: Test effectiveness rather than adding extensively
- **Add emphasis**: Use "IMPORTANT" or "YOU MUST" for critical instructions
- **Review periodically**: Update as project evolves
- **Include in commits**: Share accumulated guidance with teammates

## What to Avoid

- Bloated files without validating impact on performance
- Redundancy with existing documentation
- Long narrative paragraphs
- Commentary or nice-to-have information
- Hyperbolic or subjective language
- Vague instructions
