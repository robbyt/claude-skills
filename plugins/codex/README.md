# Codex CLI Plugin

OpenAI Codex CLI integration for code review, web search, plan review, and codebase analysis.

## MCP Server

This plugin includes an MCP server that starts automatically when the plugin is enabled. The server provides `codex` and `codex-reply` tools for native integration. Skills prefer MCP when available and fall back to Bash commands.

## Skills

### `codex:web-search`

Real-time web research using Codex CLI's `--search` flag.

**Triggers:** "search with Codex", "find current info about X", "what's the latest on Y"

### `codex:diff-review`

Code review of git changes. Uses `codex review` or manual diff review.

**Triggers:** "have Codex review my changes", "get code review from Codex", "review this diff with Codex"

### `codex:plan-review`

Review and critique implementation plans before execution.

**Triggers:** "have Codex review this plan", "get second opinion from Codex", "critique this plan with Codex"

### `codex:codebase-analysis`

Codebase and architecture analysis with read-only sandbox.

**Triggers:** "analyze this codebase with Codex", "have Codex map dependencies"

## Setup

Codex CLI must be pre-configured with API keys or OAuth. See `references/setup.md` for details.
