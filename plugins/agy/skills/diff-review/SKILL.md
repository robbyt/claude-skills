---
name: diff-review
description: Get Google Antigravity's (`agy`) code review of git changes after Claude makes edits. Trigger when user wants a second opinion on code changes ("have agy review my changes", "get code review from Google Antigravity", "review this diff with agy"), or as a final check before committing. Replaces the deprecated gemini-cli diff-review workflow.
---

# Diff Review via Google Antigravity (`agy`)

Have Google's Antigravity CLI review git changes for a second perspective on code
quality. `agy` runs Google's Gemini models and replaces the deprecated `gemini-cli`.

## Quick Start

Save the diff into the workspace (Google Antigravity can't read paths outside it),
have it review, then clean up:

```bash
git diff --cached > agy-review.diff
agy --print "Review the code changes in agy-review.diff for issues. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

Google Antigravity has no `--allowed-tools` flag — restrict it via the "Do not make
any changes" clause in the prompt. `agy` can still read other files in the workspace
when it needs broader context.

## Patterns

**Staged changes:**
```bash
git diff --cached > agy-review.diff
agy --print "Review agy-review.diff for:
1. Bugs or logic errors
2. Security vulnerabilities
3. Style inconsistencies
4. Missing error handling
Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

**All uncommitted changes:**
```bash
git diff HEAD > agy-review.diff
agy --print "Review agy-review.diff. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

**Specific commit:**
```bash
git show abc123 > agy-review.diff
agy --print "Review the commit captured in agy-review.diff. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

## Focused Reviews

**Security focus:**
```bash
git diff --cached > agy-review.diff
agy --print "Security review of agy-review.diff. Check for:
- XSS vulnerabilities
- SQL/command injection
- Sensitive data exposure
- Authentication/authorization issues
Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

**Performance focus:**
```bash
git diff --cached > agy-review.diff
agy --print "Performance review of agy-review.diff. Check for:
- Inefficient algorithms
- N+1 queries
- Memory leaks
- Blocking operations
Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

## With File Context

Ask agy to read full files for broader context (the prompt-level read-only clause
still applies):

```bash
git diff --cached > agy-review.diff
agy --print "Review agy-review.diff. Also read the full files:
- src/auth/login.ts
- src/utils/validate.ts
to understand the broader context. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

## Multi-turn Review

Use `--continue` to drill into agy's findings:

```bash
git diff --cached > agy-review.diff
agy --print "Review agy-review.diff for security issues. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions

agy --continue --print "Of those findings, which are most likely exploitable in production? Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm agy-review.diff
```

## Notes

- **Google Antigravity must not make any changes; provide feedback ONLY.** Without the prompt clause, `agy` may attempt edits.
- `agy` reads files inside the current workspace only. Saving the diff into the project root (`agy-review.diff`) makes it accessible.
- `agy` respects `.gitignore` — it cannot read files matching gitignore patterns.
- Requires `dangerouslyDisableSandbox: true` on the Bash tool because Google Antigravity writes session state under `~/.gemini/` (shared with the old gemini-cli).
- May take 1–2 minutes for thorough review; bump `--print-timeout` if needed.
- See `references/setup.md` and `references/patterns.md` for more.
