# Codex CLI Quick Reference

For complete documentation, see [official Codex CLI docs](https://github.com/openai/codex).

## Basic Usage

```bash
# Interactive mode
codex "prompt"

# Non-interactive execution
codex exec "prompt" --sandbox read-only --ask-for-approval never

# Code review
codex review
```

## Common Options

| Option | Description |
|--------|-------------|
| `--sandbox read-only` | Read-only file access |
| `--sandbox workspace-write` | Write within workspace |
| `--ask-for-approval never` | Non-interactive mode |
| `--search` | Enable web search |
| `-m MODEL` | Specify model |
| `-C DIR` | Set working directory |

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `exec` | `e` | Non-interactive execution |
| `review` | | Code review |
| `resume` | | Resume previous session |
| `apply` | `a` | Apply diff to working tree |
| `login` | | Authenticate |
| `logout` | | Remove credentials |

## Examples

```bash
# Analyze codebase (read-only)
codex exec "Analyze this project structure" --sandbox read-only --ask-for-approval never

# Code review
codex review

# Web search
codex exec "Search for latest React patterns" --search --sandbox read-only --ask-for-approval never
```

## More Information

- Full CLI reference: `codex --help`
- Official docs: https://github.com/openai/codex
