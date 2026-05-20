# Google Antigravity (agy) CLI Quick Reference

`agy` is Google Antigravity, the successor to Google's `gemini-cli`. It runs Google's
Gemini models under a different command surface.

For the complete CLI surface and migration notes from `gemini-cli`, see
[AGY_CLI.md](../../../AGY_CLI.md) at the repo root.

## Basic Usage

```bash
agy --print "[prompt]" --dangerously-skip-permissions
```

## Common Flags

| Flag | Alias | Description |
|------|-------|-------------|
| `--print "<prompt>"` | `-p`, `--prompt` | Run a single prompt non-interactively and print the response |
| `--continue` | `-c` | Resume the most recent conversation |
| `--conversation <ID>` | | Resume a specific conversation by ID |
| `--dangerously-skip-permissions` | | Auto-approve all tool requests. Required for scripting |
| `--add-dir <path>` | | Add a directory to the workspace (repeatable) |
| `--sandbox` | | Restrict terminal access (still allows workspace file I/O) |
| `--print-timeout <duration>` | | Override the 5-minute print-mode timeout |
| `--prompt-interactive` | `-i` | Seed an interactive session with an initial prompt |
| `--log-file <path>` | | Override CLI log file path |

## Subcommands

- `agy changelog` — show release notes
- `agy install` — configure shell/PATH integration
- `agy update` — update CLI
- `agy plugin list | import | install | uninstall | enable | disable | validate | link`
  — manage installed plugins

## Session Management

```bash
# Initial turn
agy --print "Start here" --dangerously-skip-permissions

# Most recent session
agy --continue --print "Follow up" --dangerously-skip-permissions

# Specific session
agy --conversation "e4d54090-7274-40fe-aca3-6704079dd83f" \
    --print "Another prompt" --dangerously-skip-permissions
```

## Things That Differ From `gemini-cli`

Google's `gemini-cli` is being retired in favor of Antigravity. Key migration deltas:

| Google `gemini-cli` | Google Antigravity (`agy`) |
|---------------------|----------------------------|
| `gemini "q" -o text` | `agy --print "q" --dangerously-skip-permissions` |
| `gemini "q" -o json` | Not supported as a flag; response is plain text |
| `gemini "q" --allowed-tools X` | Not supported; use `--sandbox` or prompt instructions |
| `gemini "q" -m gemini-2.5-flash` | No model flag; uses default configured Gemini model |
| `echo X \| gemini -r 1` | `agy --continue --print "X" --dangerously-skip-permissions` (no stdin) |
| `gemini --list-sessions` | Not available; track session IDs yourself |

## More Information

- Full CLI reference: `agy --help`
- Migration guide: `AGY_CLI.md` at repo root
