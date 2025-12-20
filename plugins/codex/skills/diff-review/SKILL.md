---
name: diff-review
description: Get Codex's code review of git changes after Claude makes edits. Trigger when user wants a second opinion on code changes ("have Codex review my changes", "get code review from Codex", "review this diff with Codex"), or as a final check before committing.
---

# Diff Review via Codex

Have Codex review git changes for a second perspective on code quality.

## CRITICAL: Instruct Codex

Every prompt sent to Codex MUST include these instructions:

> "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete feedback immediately."

Codex is a consultant. Claude Code handles all file modifications.

## Quick Start (MCP)

If the `codex` MCP tool is available, first save the diff then review:

```bash
git diff --cached > codex-review.diff
```

```
mcp__plugin_codex_cli__codex({
  "prompt": "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete feedback immediately.\n\nReview the code changes at codex-review.diff for bugs, security issues, and style problems.",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

```bash
rm codex-review.diff
```

## Fallback (Bash)

If MCP is unavailable, use shell commands:

```bash
git diff --cached > codex-review.diff
codex exec "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete feedback immediately.

Review the code changes at codex-review.diff for issues." --sandbox read-only -m gpt-5.2-codex 2>&1
rm codex-review.diff
```

Or use the built-in review command:

```bash
codex review --uncommitted 2>&1
```

Note: The review command is scoped to diffs and doesn't support `--sandbox`.

## Patterns

**Staged changes:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete feedback immediately.\n\nReview codex-review.diff for:\n1. Bugs or logic errors\n2. Security vulnerabilities\n3. Style inconsistencies\n4. Missing error handling",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

**Security focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete feedback immediately.\n\nSecurity review of codex-review.diff. Check for:\n- XSS vulnerabilities\n- SQL/command injection\n- Sensitive data exposure\n- Authentication/authorization issues",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

**Performance focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "You are running non-interactively as part of a script. Do not ask questions or wait for input. Do not make any changes. Provide your complete feedback immediately.\n\nPerformance review of codex-review.diff. Check for:\n- Inefficient algorithms\n- N+1 queries\n- Memory leaks\n- Blocking operations",
  "sandbox": "read-only",
  "model": "gpt-5.2"
})
```

## Performance

- MCP diff review: ~5-30 seconds
- MCP with source context: ~1-2 minutes
- Bash fallback: ~2-3 minutes

## Notes

- **Always use `sandbox: "read-only"`** to prevent file modifications
- **NEVER use `sandbox: "danger-full-access"`** - this is forbidden
- Tool name may vary by installation. Check available tools for exact name.
- Save diff to project root before review (Codex can read project files)
- Clean up diff file after review
- MCP is preferred; Bash fallback requires `dangerouslyDisableSandbox: true`
- See `references/setup.md` for troubleshooting
