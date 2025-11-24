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

⏱️ **Response Time**: Gemini may take several minutes to respond, especially for complex tasks involving file analysis, web search, or codebase investigation. **Allow up to 10 minutes** for responses before assuming a timeout. The CLI will show no output while processing.

Key flags:
- `-o text`: Human-readable output
- `-o json`: Structured output with token/tool stats
- `-m [model]`: Model selection (e.g., `gemini-2.5-flash` for faster tasks)

## Troubleshooting

### Command Approval Issue

**Problem**: Gemini hangs with no output when asked to execute commands.

**Cause**: Gemini requires explicit user permission for any command it runs. When Claude asks Gemini to "run X command", Gemini waits for user approval and appears to hang.

**Solution**: Run commands via Claude's Bash tool first, then pass the output or file paths to Gemini.

**Bad Pattern** (hangs waiting for approval):
```bash
gemini "Run git diff --cached and review the changes" -o text
```

**Good Pattern** (runs commands first, then passes to Gemini):
```bash
# 1. Get the diff using Bash tool
git diff --cached > /tmp/claude/changes.diff

# 2. Pass file path to Gemini
gemini "Review the git diff at /tmp/claude/changes.diff and provide feedback" -o text
```

**Alternative** (pass content directly):
```bash
# 1. Get output via Bash
diff_output=$(git diff --cached)

# 2. Save to file and reference it
echo "$diff_output" > /tmp/claude/diff.txt
gemini "Review /tmp/claude/diff.txt for code quality issues" -o text
```

### Sandbox Permission Error (EPERM)

**Problem**: Error when running gemini commands from Claude Code:
```
Error: EPERM: operation not permitted, mkdir '/Users/[user]/.gemini/tmp/...'
```

**Cause**: Gemini CLI needs write access to `~/.gemini/tmp/` for chat recording. Claude Code's sandbox blocks this by default.

**Solution 1** (Recommended): Use `dangerouslyDisableSandbox: true` when calling gemini via Bash tool:
```bash
# In Claude Code, when using Bash tool to run gemini:
dangerouslyDisableSandbox: true
```

**Solution 2**: Add `~/.gemini/tmp` to sandbox allowlist:
1. Run `/sandbox` command in Claude Code
2. Add `~/.gemini/tmp` to the filesystem write allowlist
3. Restart Claude Code

**Note**: This error only affects Claude Code's sandboxed execution. Running `gemini` directly from your terminal works without these workarounds.

## Working with Files

**Gemini can read files directly from disk.** Tell Gemini the file path instead of embedding file content in the prompt.

### Preferred Pattern (File Path)
```bash
gemini "Please review the bash script at path/to/file.sh for syntax errors" -o text
```

### Avoid This Pattern (Embedding Content)
```bash
# DON'T: Shell escaping can corrupt file content
gemini "Review this script: $(cat path/to/file.sh)" -o text
```

**Why file paths are better:**
- Avoids shell escaping issues (spaces in `[@]` become `[ @]`, quotes get mangled)
- Preserves exact file content without interpretation
- More efficient for large files
- Clearer intent in prompts

### File Operation Examples

**Single file review:**
```bash
gemini "Review plugins/foo/test.sh for bash best practices" -o text
```

**Multi-file analysis:**
```bash
gemini "Compare the test patterns in plugins/python-formatter-black/tests/test.sh and plugins/go-formatter/tests/test.sh" -o text
```

**Directory analysis:**
```bash
gemini "Analyze all Python files in src/ directory for security issues" -o text
```

## Core Workflows

### 1. Code Generation
```bash
gemini "Create [description] with [features]. Output complete file content." -o text
```

### 2. Code Review
```bash
# Provide file path - Gemini will read it directly
gemini "Review path/to/file.js for: 1) features, 2) bugs/security issues, 3) improvements" -o text
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
