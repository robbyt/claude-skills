# Gemini CLI Quick Reference

Minimal reference for using Gemini CLI with this skill. For complete documentation, see [official Gemini CLI docs](https://github.com/google-gemini/gemini-cli).

## Installation

**macOS (Recommended):**
```bash
brew install gemini-cli
```

**Cross-Platform (npm):**
```bash
npm install -g @google/gemini-cli
```

**Verify:**
```bash
gemini --version  # Should show v0.17.0+
```

## Authentication

⚠️ **IMPORTANT:** Gemini CLI must be authenticated before using this skill. Claude Code will NOT configure authentication for you.

**Prerequisites:**
- Gemini CLI installed and authenticated
- Test that `gemini "test" -o text` works

**Setup instructions:** See the [official Gemini CLI documentation](https://github.com/google-gemini/gemini-cli) for authentication setup.

**If this skill fails with auth errors:**
- Complete authentication setup manually using official docs
- Verify with: `gemini "test" -o text`
- Then retry using the skill

## Basic Usage

**For code review:**
```bash
gemini "Review this code for security issues: [code]" -o text
```

**For web research:**
```bash
gemini "What's new in React 19? Use Google Search." -o text
```

**For architecture analysis:**
```bash
gemini "Use codebase_investigator to analyze this project" -o text
```

## Common Options

Run `gemini --help` for complete list. Key options used by this skill:

- `-o text` - Human-readable output (default for consulting)
- `-o json` - Structured output with stats
- `-m gemini-2.5-flash` - Faster model for simple tasks

## More Information

- **Full CLI reference:** `gemini --help`
- **Official documentation:** https://github.com/google-gemini/gemini-cli
- **Models, configuration, troubleshooting:** See official docs above
