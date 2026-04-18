---
name: diff-review
description: Get Codex's code review of git changes via the Codex MCP server. Trigger when user wants a second opinion on code changes ("have Codex review my changes", "get code review from Codex", "review this diff with Codex"), or as a final check before committing.
---

# Diff Review via Codex

Use Codex to review git changes for bugs, security issues, and style problems. Codex consults; Claude writes.

## Transport

**Always use the MCP tool.** The plugin runs `codex mcp-server` on stdio via `.mcp.json`. Tool name: `mcp__plugin_codex_cli__codex`. If the example below errors with an unknown-tool error, run `/mcp` and substitute the actual prefix (e.g., `mcp__codex_cli__codex`).

## Model

**Omit `model` unless the user names one.** Codex picks `gpt-5.4` on its own. See `../references/patterns.md` for the full table.

## Flow

Codex reads files from the project root. Save the diff to a file there first:

```bash
git diff --cached > codex-review.diff
```

Then:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review codex-review.diff for bugs, security issues, style problems, and missing error handling.",
  "sandbox": "read-only"
})
```

Clean up after:

```bash
rm codex-review.diff
```

## Patterns

**Uncommitted (staged + unstaged + untracked):**
```bash
git diff HEAD > codex-review.diff
```

**Branch vs base:**
```bash
git diff main...HEAD > codex-review.diff
```

**Specific commit:**
```bash
git show <sha> > codex-review.diff
```

## Focused reviews

**Security focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Security review of codex-review.diff:\n- XSS vulnerabilities\n- SQL/command injection\n- Sensitive data exposure\n- Auth/authz issues",
  "sandbox": "read-only"
})
```

**Performance focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Performance review of codex-review.diff:\n- Inefficient algorithms\n- N+1 queries\n- Memory leaks\n- Blocking operations",
  "sandbox": "read-only"
})
```

## Iterative workflow (prefer `codex-reply`)

When you're still working on the same diff, **continue the existing thread** rather than starting a new `codex` call. Codex keeps the diff and its prior findings in context; fresh calls lose that.

Typical loop: initial review → Claude implements a fix → `codex-reply` asking "does the revised code still have the issue?" → Codex confirms or flags new concern → repeat.

**Cap at 3–4 rounds total.** Diff reviews should converge fast; if you're still going at round 5, stop and surface the remaining disagreement to the user rather than letting the two models debate indefinitely.

**Example — three rounds on the same diff:**

```
# Round 1 — initial review
mcp__plugin_codex_cli__codex({
  "prompt": "Review codex-review.diff for bugs, security issues, and missing error handling.",
  "sandbox": "read-only"
})
# → threadId: "019da14b-..."  /  flags: "parseToken doesn't handle malformed JWTs — will throw unhandled."

# Round 2 — Claude fixes and re-exports the updated diff
git diff --cached > codex-review.diff
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "I've re-written codex-review.diff with a fix — please re-read the file. I added a try/catch around parseToken that returns 401 on any JWT parse error. Does this address your concern?"
})

# Round 3 — triage
mcp__plugin_codex_cli__codex-reply({
  "threadId": "019da14b-...",
  "prompt": "Of the remaining issues, which are merge-blockers vs. nits we can defer?"
})
```

**Start a fresh thread when:** reviewing a different diff, the `threadId` is no longer in context, or the diff has diverged so much that re-priming is cleaner than incremental updates. See `../references/patterns.md`.

## Built-in `codex review` subcommand

**Don't use this by default** — the MCP flow above is the standard path. `codex review` is a separate, specialized diff-review subcommand that runs in Bash, doesn't go through MCP, and doesn't support `--sandbox`. Only reach for it when the user explicitly asks for Codex's built-in review output, or when MCP is unavailable:

```bash
codex review --uncommitted
codex review --base main
codex review --commit <sha>
```

Requires `dangerouslyDisableSandbox: true`.

## Performance

- Simple diff: ~5–30 s
- Large diff with source traversal: ~1–2 min

## Safety

- **Always** `sandbox: "read-only"`.
- Never use `workspace-write`, `danger-full-access`, or `--dangerously-bypass-approvals-and-sandbox`.
- Remember to clean up the temporary diff file.

## Fallback (rare)

If the MCP server is unavailable, see `../references/commands.md` for the Bash `codex exec` form. Requires `dangerouslyDisableSandbox: true`.
