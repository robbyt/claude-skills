---
name: diff-review
description: Get Codex's code review of git changes via the Codex MCP server. Trigger when user wants a second opinion on code changes ("have Codex review my changes", "get code review from Codex", "review this diff with Codex"), or as a final check before committing.
---

# Diff Review via Codex

Use Codex to review git changes for bugs, security issues, and style problems. Codex consults; Claude writes.

## Transport

**Always use the MCP tool.** The plugin runs `codex mcp-server` on stdio via `.mcp.json`. Tool name: `mcp__plugin_codex_cli__codex`. If the example below errors with an unknown-tool error, run `/mcp` and substitute the actual prefix (e.g., `mcp__codex_cli__codex`).

## Model

**Pin `model: "gpt-5.6-sol"` with `config: { "model_reasoning_effort": "medium" }`** for non-trivial diffs. For small diffs (~< 100 changed lines, single function, no security surface) use `model: "gpt-5.6-luna"` with `config: { "model_reasoning_effort": "low" }` to save quota. **Security- or performance-focused reviews always stay on `gpt-5.6-sol` at `medium`** — don't downgrade. Set model+effort on the opening call only; `codex-reply` inherits them. See `../references/patterns.md` → Models and Reasoning effort.

## Flow

Codex reads files from the project root. Save the diff to a file there first:

```bash
git diff --cached > codex-review.diff
```

Then:

```
mcp__plugin_codex_cli__codex({
  "prompt": "Review codex-review.diff for bugs, security issues, style problems, and missing error handling.",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
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
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

**Performance focus:**
```
mcp__plugin_codex_cli__codex({
  "prompt": "Performance review of codex-review.diff:\n- Inefficient algorithms\n- N+1 queries\n- Memory leaks\n- Blocking operations",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
})
```

## Iterative workflow (prefer `codex-reply`)

When you're still working on the same diff, **continue the existing thread** rather than starting a new `codex` call. Codex keeps the diff and its prior findings in context; fresh calls lose that.

Typical loop: initial review → Claude implements a fix → `codex-reply` asking "does the revised code still have the issue?" → Codex confirms or flags new concern → repeat.

**Cap at 3–4 rounds total.** Diff reviews should converge fast; if you're still going at round 5, stop and surface the remaining disagreement to the user rather than letting the two models debate indefinitely.

**`threadId` is an MCP argument — pass it as the `threadId` field of `codex-reply`, not in the `prompt` text.** See `../references/mcp-schema.md` for wrong-vs-right examples.

**Example — three rounds on the same diff:**

```
# Round 1 — initial review (opening call pins model + effort)
mcp__plugin_codex_cli__codex({
  "prompt": "Review codex-review.diff for bugs, security issues, and missing error handling.",
  "sandbox": "read-only",
  "model": "gpt-5.6-sol",
  "config": { "model_reasoning_effort": "medium" }
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

## After the review

Codex's findings are a second opinion, not a merge gate — weigh them, don't rubber-stamp them.

- **Relay what Codex found** to the user; don't silently fold its notes into your own review as if they were your conclusions.
- **Verify before fixing.** Codex can raise false positives or miss context it never saw (see `../references/patterns.md` → Validation). Confirm each issue against the actual code before changing anything.
- **Separate merge-blockers from nits**, and surface genuine disagreements to the user rather than looping with Codex to force consensus.

## Safety

- **Always** `sandbox: "read-only"`.
- Never use `workspace-write`, `danger-full-access`, or `--dangerously-bypass-approvals-and-sandbox`.
- Remember to clean up the temporary diff file.

## Fallback (rare)

If the MCP server is unavailable, see `../references/commands.md` for the Bash `codex exec` form. Requires `dangerouslyDisableSandbox: true`.
