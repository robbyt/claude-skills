---
name: diff-review
description: Get Codex's code review of git changes after Claude makes edits. Trigger when user wants a second opinion on code changes ("have Codex review my changes", "get code review from Codex", "review this diff with Codex"), or as a final check before committing.
---

# Diff Review via Codex

Have Codex review git changes for a second perspective on code quality.

## Quick Start (MCP)

If the `codex` MCP tool is available, first save the diff then review:

```bash
git diff --cached > codex-review.diff
```

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review the code changes at codex-review.diff for bugs, security issues, and style problems. Do not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

```bash
rm codex-review.diff
```

## Fallback (Bash)

If MCP is unavailable, use shell commands:

```bash
git diff --cached > codex-review.diff
codex exec "Review the code changes at codex-review.diff for issues. Do not make any changes. Respond with feedback only." --sandbox read-only 2>&1
rm codex-review.diff
```

Or use the built-in review subcommand:

```bash
codex exec review --uncommitted --sandbox read-only 2>&1
```

## Patterns

**Staged changes:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Review codex-review.diff for:\n1. Bugs or logic errors\n2. Security vulnerabilities\n3. Style inconsistencies\n4. Missing error handling\n\nDo not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

**Security focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Security review of codex-review.diff. Check for:\n- XSS vulnerabilities\n- SQL/command injection\n- Sensitive data exposure\n- Authentication/authorization issues\n\nDo not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

**Performance focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Performance review of codex-review.diff. Check for:\n- Inefficient algorithms\n- N+1 queries\n- Memory leaks\n- Blocking operations\n\nDo not make any changes. Respond with feedback only.",
  "sandbox": "read-only"
})
```

## Performance

- MCP diff review: ~5-30 seconds
- MCP with source context: ~1-2 minutes
- Bash fallback: ~2-3 minutes

## Notes

- **Codex must not make any changes, provide feedback ONLY.**
- **Always use `sandbox: "read-only"`** to prevent file modifications
- **NEVER use `sandbox: "danger-full-access"`** - this is forbidden
- Tool name may vary by installation. Check available tools for exact name.
- Save diff to project root before review (Codex can read project files)
- Clean up diff file after review
- MCP is preferred; Bash fallback requires `dangerouslyDisableSandbox: true`
- See `references/setup.md` for troubleshooting
