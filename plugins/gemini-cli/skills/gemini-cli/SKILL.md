---
name: gemini-cli
description: Orchestrate Gemini CLI (v0.17.0+) for tasks requiring current web information via Google Search, deep codebase analysis with codebase_investigator, second AI opinions on code quality/security, or parallel task processing. Trigger when user explicitly requests Gemini ("use Gemini", "ask Gemini") or when needing capabilities unique to Gemini.
---

# Gemini CLI Integration

Leverage Gemini CLI for alternative AI perspectives and unique tools (Google Search, codebase_investigator).

## Prerequisites

⚠️ **This skill assumes Gemini CLI is already installed and authenticated.**

If you haven't completed setup:
1. See `references/commands.md` for installation and authentication instructions
2. Complete the **manual authentication setup** (API key or OAuth)
3. Verify with: `gemini "test" -o text`

**Claude Code will NOT configure authentication for you.** This must be done manually before using this skill.

## Quick Start

Verify installation:
```bash
command -v gemini
```

Basic pattern:
```bash
gemini "[prompt]" -o text 2>&1
```

Key flags:
- `-o text`: Human-readable output
- `-o json`: Structured output with token/tool stats
- `-m [model]`: Model selection (e.g., `gemini-2.5-flash` for faster tasks)

## Core Workflows

### 1. Code Generation
```bash
gemini "Create [description] with [features]. Output complete file content." -o text
```

### 2. Code Review
```bash
gemini "Review [file] for: 1) features, 2) bugs/security issues, 3) improvements" -o text
```

### 3. Test Generation
```bash
gemini "Generate [Jest/pytest] tests for [file]. Focus on [areas]." -o text
```

### 4. Architecture Analysis (Unique to Gemini)
```bash
gemini "Use codebase_investigator to analyze this project" -o text
```

### 5. Web Research (Unique to Gemini)
```bash
gemini "What are the latest [topic]? Use Google Search." -o text
```

## Gemini's Unique Capabilities

These tools are only available through Gemini:
- **google_web_search**: Real-time Google Search for current info
- **codebase_investigator**: Deep architectural analysis and dependency mapping
- **save_memory**: Cross-session persistent memory

## Rate Limits

Free tier: 60 requests/min, 1000/day. CLI auto-retries with backoff. Use `-m gemini-2.5-flash` for lower-priority tasks.

## Validation

Always verify Gemini's output:
- Security vulnerabilities (XSS, injection)
- Functionality matches requirements
- Code style consistency
- Appropriate dependencies

## JSON Output Parsing

When using `-o json`, parse structured response:
```json
{
  "response": "actual content",
  "stats": {
    "models": { "tokens": {...} },
    "tools": { "byName": {...} }
  }
}
```

## Configuration

Optional: Create `.gemini/GEMINI.md` in project root for persistent context Gemini auto-reads.

Session management:
```bash
gemini --list-sessions               # List sessions
echo "follow-up" | gemini -r 1 -o text   # Resume by index
```

## Reference Documentation

For detailed guidance, see:
- **references/commands.md**: Complete CLI flags and options reference
- **references/patterns.md**: Advanced integration patterns (Generate-Review-Fix, background execution, model selection, validation pipelines)
- **references/templates.md**: Reusable prompt templates for common operations
- **references/tools.md**: Gemini's built-in tools documentation and comparison with Claude Code

Load these references when you need deeper knowledge about specific aspects of Gemini CLI usage.
