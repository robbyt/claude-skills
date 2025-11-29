# Gemini CLI Quick Reference

For complete documentation, see [official Gemini CLI docs](https://github.com/google-gemini/gemini-cli).

## Basic Usage

```bash
gemini "[prompt]" -o text 2>&1
```

## Common Options

| Option | Description |
|--------|-------------|
| `-o text` | Human-readable output |
| `-o json` | Structured output with stats |
| `-m gemini-2.5-flash` | Faster model for simple tasks |
| `-r [index]` | Resume session by index |
| `--list-sessions` | List available sessions |

## JSON Output Structure

```json
{
  "response": "actual content",
  "stats": {
    "models": { "tokens": {...} },
    "tools": { "byName": {...} }
  }
}
```

## Session Management

```bash
gemini --list-sessions               # List sessions
echo "follow-up" | gemini -r 1 -o text   # Resume by index
```

## More Information

- Full CLI reference: `gemini --help`
- Official docs: https://github.com/google-gemini/gemini-cli
