---
name: diff-review
description: Get Codex's code review of git changes after Claude makes edits. Trigger when user wants a second opinion on code changes ("have Codex review my changes", "get code review from Codex", "review this diff with Codex"), or as a final check before committing.
---

# Diff Review via Codex

Have Codex review git changes for a second perspective on code quality.

## Quick Start

Use the built-in review command:

```bash
codex review 2>&1
```

Or save diff to project root for manual review:

```bash
git diff --cached > codex-review.diff
codex exec "Review the code changes at codex-review.diff for issues. Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

## Patterns

**Staged changes:**
```bash
git diff --cached > codex-review.diff
codex exec "Review codex-review.diff for:
1. Bugs or logic errors
2. Security vulnerabilities
3. Style inconsistencies
4. Missing error handling

Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

**All uncommitted changes:**
```bash
git diff HEAD > codex-review.diff
codex exec "Review codex-review.diff. Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

**Specific commit:**
```bash
git show abc123 > codex-review.diff
codex exec "Review the commit at codex-review.diff. Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

## Focused Reviews

**Security focus:**
```bash
git diff --cached > codex-review.diff
codex exec "Security review of codex-review.diff. Check for:
- XSS vulnerabilities
- SQL/command injection
- Sensitive data exposure
- Authentication/authorization issues

Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

**Performance focus:**
```bash
git diff --cached > codex-review.diff
codex exec "Performance review of codex-review.diff. Check for:
- Inefficient algorithms
- N+1 queries
- Memory leaks
- Blocking operations

Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

## With File Context

Ask Codex to read full files for better context:

```bash
git diff --cached > codex-review.diff
codex exec "Review codex-review.diff. Also read the full files:
- src/auth/login.ts
- src/utils/validate.ts

to understand the broader context. Do not make any changes. Respond with feedback only." --sandbox read-only --ask-for-approval never 2>&1
rm codex-review.diff
```

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **NEVER use `--dangerously-bypass-approvals-and-sandbox` or `--sandbox danger-full-access`** - these disable safety features and are forbidden
- Uses `--sandbox read-only` to prevent file modifications
- Uses `--ask-for-approval never` for non-interactive execution
- If flag errors occur, run `codex --help` to verify correct flag usage
- Requires `dangerouslyDisableSandbox: true` for Bash calls
- May take 1-2 minutes for thorough review
- See `references/setup.md` for troubleshooting
