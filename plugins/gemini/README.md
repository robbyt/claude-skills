# Gemini CLI Plugin

## Skills

### `gemini:web-search`

Real-time web research using Gemini's Google Search integration.

**Triggers:** "search with Gemini", "find current info about X", "what's the latest on Y"

### `gemini:diff-review`

Code review of git changes for a second perspective.

**Triggers:** "have Gemini review my changes", "get code review from Gemini", "review this diff"

### `gemini:plan-review`

Review and critique implementation plans.

**Triggers:** "have Gemini review this plan", "get second opinion", "critique this plan"

### `gemini:codebase-analysis`

Architectural analysis using Gemini's `codebase_investigator` tool.

**Triggers:** "analyze this codebase", "map dependencies"

## Setup

See `references/setup.md` for installation and authentication.

## Gemini Tools

- `google_web_search` - Real-time Google Search
- `codebase_investigator` - Architectural analysis
- `save_memory` - Cross-session persistence
