---
name: diff-review
description: Get Gemini's code review of git changes after Claude makes edits. Trigger when user wants a second opinion on code changes ("have Gemini review my changes", "get code review from Gemini", "review this diff"), or as a final check before committing.
---

# Diff Review via Gemini

Have Gemini review git changes for a second perspective on code quality.

## Quick Start

Save diff to project root, have Gemini review, then clean up:

```bash
git diff --cached > gemini-review.diff
gemini "Review the code changes at gemini-review.diff for issues. Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

## Patterns

**Staged changes:**
```bash
git diff --cached > gemini-review.diff
gemini "Review gemini-review.diff for:
1. Bugs or logic errors
2. Security vulnerabilities
3. Style inconsistencies
4. Missing error handling
Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

**All uncommitted changes:**
```bash
git diff HEAD > gemini-review.diff
gemini "Review gemini-review.diff. Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

**Specific commit:**
```bash
git show abc123 > gemini-review.diff
gemini "Review the commit at gemini-review.diff. Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

## Focused Reviews

**Security focus:**
```bash
git diff --cached > gemini-review.diff
gemini "Security review of gemini-review.diff. Check for:
- XSS vulnerabilities
- SQL/command injection
- Sensitive data exposure
- Authentication/authorization issues
Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

**Performance focus:**
```bash
git diff --cached > gemini-review.diff
gemini "Performance review of gemini-review.diff. Check for:
- Inefficient algorithms
- N+1 queries
- Memory leaks
- Blocking operations
Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

## With File Context

Ask Gemini to read full files for better context:

```bash
git diff --cached > gemini-review.diff
gemini "Review gemini-review.diff. Also read the full files:
- src/auth/login.ts
- src/utils/validate.ts
to understand the broader context. Do not make any changes. Respond with feedback only." --allowed-tools read_file,codebase_investigator,glob,search_file_content,list_directory,write_todos -o text 2>&1
rm gemini-review.diff
```

## Notes

- **Gemini must not make any changes, provide feedback ONLY.**
- Gemini respects `.gitignore` - it cannot read files matching gitignore patterns
- Gemini can only read files in the workspace directory (project root)
- Requires `dangerouslyDisableSandbox: true` for Bash calls
- May take 1-2 minutes for thorough review
- See `references/setup.md` for troubleshooting
