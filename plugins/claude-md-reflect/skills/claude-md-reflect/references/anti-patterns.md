# CLAUDE.md Anti-Patterns

Common mistakes to avoid when writing or improving CLAUDE.md files. You should AVOID the following:

## Vague or Subjective Instructions

**Bad:**
- Write proper code
- Use best practices
- Make it simple
- Write robust error handling
- Create clean functions

**Why:** These are subjective and provide no actionable guidance.

**Good:**
- Use 2-space indentation
- Prefix test files with `test_`
- Return errors instead of panicking
- Functions should not exceed 50 lines

## Hyperbolic or Fluff Language

**Bad:**
- The API client plays a crucial role in our architecture
- It's very important to follow these guidelines
- Make sure to write excellent documentation
- Always use proper naming conventions

**Why:** Words like "crucial", "very important", "excellent", "proper" add noise without meaning.

**Good:**
- Use the API client in `pkg/client` for all external requests
- Document all exported functions
- Use snake_case for variable names

## Long Narrative Paragraphs

**Bad:**
```
When you're working on this project, you should be aware that we have a
specific way of handling errors. In the past, we used to just return nil
and log errors, but we've since moved to a better approach where we return
the actual error values so that callers can handle them appropriately.
```

**Good:**
```
# Error handling
- Return errors to callers, don't just log them
- Use errors.Join for multiple errors
```

## Redundant Information

**Bad:**
```
# Build commands
- npm run build: This command builds the project
- npm run test: This command runs the tests
- npm run lint: This command runs the linter

# Building
To build the project, run `npm run build`
```

**Why:** Information appears multiple times.

**Good:**
```
# Commands
- npm run build: Build the project
- npm run test: Run test suite
- npm run lint: Check code style
```

## Outdated Instructions

**Bad:**
```
# Database
- Use MySQL 5.7
- Run migrations with migrate.sh (NOTE: This script was removed, use db-migrate now)
```

**Why:** Contains outdated information and historical comments.

**Good:**
```
# Database
- Use PostgreSQL 15+
- Run migrations with `npm run db:migrate`
```

## Unclear Scope

**Bad:**
```
Don't use global variables
```

**Why:** Unclear if this applies to all files, tests, or specific contexts.

**Good:**
```
# Code style
- Avoid global variables in src/ (tests can use them for fixtures)
```

## Missing Context for Commands

**Bad:**
```
Run: make proto
```

**Why:** No explanation of when or why to run this.

**Good:**
```
# After editing .proto files
- make proto: Regenerate protobuf code
```

## Over-Capitalization for Emphasis

**Bad:**
```
NEVER EVER USE VAR IN JAVASCRIPT CODE!!!
YOU MUST ALWAYS USE CONST OR LET!!!
```

**Why:** Excessive caps and punctuation create noise.

**Good:**
```
# JavaScript style
- NEVER use var, use const or let
```

## Instructions That Should Be Code

**Bad:**
```
When rotating PDFs, make sure to:
1. Load the PDF using pdfplumber
2. Iterate through each page
3. Rotate each page by the specified degrees
4. Save the output
```

**Why:** Repetitive procedural code should be in a script, not instructions.

**Good:**
```
# PDF manipulation
- Rotate PDFs: python scripts/rotate_pdf.py <input> <degrees> <output>
```

## Mixing Different Concerns

**Bad:**
```
# Instructions
- Use ES modules
- The build takes about 5 minutes
- John prefers arrow functions
- Run tests before committing
- I fixed a bug last week where...
```

**Why:** Mixes style guidelines, historical notes, timing info, and personal preferences.

**Good:**
```
# Code style
- Use ES modules
- Prefer arrow functions

# Development workflow
- Run `npm test` before committing
```
