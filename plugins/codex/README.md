# Codex CLI Plugin

OpenAI Codex CLI integration for plan review, code review, adversarial review, and codebase analysis. Codex runs read-only: it consults, and Claude writes the code.

## Requirements

- [Codex CLI](https://github.com/openai/codex) **0.154 or newer**, logged in (`codex login`)
- Node.js 18 or newer (runs the bundled MCP server)

## MCP Server

The plugin bundles a small MCP server (`scripts/codex-mcp-server.mjs`, no dependencies) that starts when the plugin is enabled. It provides two tools:

- `codex` — start a Codex thread. Runs `codex exec --json --sandbox read-only`.
- `codex-reply` — continue a thread by `threadId`. Runs `codex exec resume` and reuses the thread's model, reasoning effort, and working directory.

Earlier versions of this plugin started `codex mcp-server`, which Codex CLI removed in 0.154.0. Parameters and behavior: `references/mcp-schema.md`.

## Skills

### `codex:diff-review`

Code review of git changes for bugs, security issues, and missing error handling.

**Triggers:** "have Codex review my changes", "get code review from Codex", "review this diff with Codex"

### `codex:adversarial-review`

A skeptical ship/no-ship review that challenges the design, assumptions, and failure modes of a change. Returns structured findings (verdict, severity, file:line, confidence).

**Triggers:** "adversarial review", "have Codex try to break this", "pressure-test this before I ship"

### `codex:plan-review`

Review and critique implementation plans before execution.

**Triggers:** "have Codex review this plan", "get second opinion from Codex", "critique this plan with Codex"

### `codex:codebase-analysis`

Codebase and architecture analysis with read-only sandbox.

**Triggers:** "analyze this codebase with Codex", "have Codex map dependencies"

## Agent

`codex:consult` runs any of the above in its own context window and returns Codex's response verbatim with a short summary. Run it in the background for long reviews.

## Models

Skills pin `gpt-6.1-sol` at `medium` effort for complex work and `gpt-6-luna` at `low` for small, focused tasks. Ask for a different model by name to override. See `references/patterns.md`.

## Setup

Codex CLI must be pre-configured with API keys or OAuth. See `references/setup.md` for installation, verification, and troubleshooting.

## Tests

```bash
make test-plugin PLUGIN=codex   # from the repo root; includes node --test tests/
```

## Attribution

The adversarial review prompt, `schemas/review-output.schema.json`, and parts of `references/prompting.md` are adapted from [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) (Apache-2.0). See `NOTICE`.
