# Gemini CLI Setup & Troubleshooting

Shared reference for all Gemini skills.

## Prerequisites

Gemini CLI must be installed and authenticated before using any Gemini skill.

**Installation:**
```bash
# macOS
brew install gemini-cli

# Cross-platform
npm install -g @google/gemini-cli
```

**Verify:**
```bash
gemini --version  # Should show v0.17.0+
gemini "test" -o text  # Should respond
```

## Authentication

Claude Code will NOT configure authentication. Complete setup manually using [official docs](https://github.com/google-gemini/gemini-cli).

## File Access

Gemini can only read files within the workspace directory (project root). It cannot access `/tmp/` or other system directories.

```bash
# Save to project root for Gemini to read
git diff > .gemini-review.diff
gemini "Review .gemini-review.diff" -o text 2>&1
rm .gemini-review.diff
```

## Troubleshooting

### Command Execution

Gemini cannot run shell commands in the current environment. Claude must run commands and save output to files for Gemini to review.

```bash
git diff > .gemini-review.diff
gemini "Review the diff at .gemini-review.diff" -o text 2>&1
rm .gemini-review.diff
```

### Sandbox Permission Error (EPERM)

**Problem:** `EPERM: operation not permitted, mkdir '/Users/[user]/.gemini/tmp/...'`

**Cause:** Gemini needs write access to `~/.gemini/tmp/` for chat recording. Claude Code's sandbox blocks this.

**Solution:** Use `dangerouslyDisableSandbox: true` when calling gemini via Bash tool.

## Working with Files

Gemini can read files directly from disk. Pass file paths instead of embedding content.

```bash
gemini "Review the script at path/to/file.sh" -o text
```

**Why paths are better:**
- Avoids shell escaping issues
- Preserves exact file content
- More efficient for large files

## Response Time

Gemini may take several minutes for complex tasks (file analysis, web search, codebase investigation). Allow up to 10 minutes before assuming timeout.

## Rate Limits

Free tier: 60 requests/min, 1000/day. The CLI auto-retries with backoff.

Use `-m gemini-2.5-flash` for faster, lower-priority tasks.
