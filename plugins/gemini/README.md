# Gemini CLI Plugin for Claude Code

A Claude Code plugin that enables orchestration of Google's Gemini CLI as an auxiliary AI tool.

## What This Plugin Provides

**Skill:** `gemini-cli`

Teaches Claude Code how to leverage Gemini CLI for:
- Code review and security audits
- Current web information via Google Search
- Codebase architecture analysis
- Second AI perspective on code quality

## Installation

This plugin is part of the `robbyt-claude-skills` marketplace.

## Prerequisites

**Required before using this skill:**

1. [Gemini CLI](https://github.com/google-gemini/gemini-cli) v0.17.0+ installed
2. Authentication configured **manually** (API key or OAuth)
3. Verified working: `gemini "test" -o text` succeeds

⚠️ **Note:** Claude Code will NOT configure authentication. You must complete the one-time setup manually before using this skill. See the skill's `references/commands.md` for detailed setup instructions.

## Usage

Once installed, Claude Code automatically uses the skill when appropriate:

```
"Use Gemini to review this code for security issues"
"Ask Gemini what's new in TypeScript 5.5"
"Get Gemini to analyze this codebase architecture"
"Have Gemini research best practices for React hooks"
```

## Gemini's Unique Capabilities

- **google_web_search**: Real-time Google Search grounding
- **codebase_investigator**: Architectural analysis
- **save_memory**: Cross-session persistence

## License

MIT
