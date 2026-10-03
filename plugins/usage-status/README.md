# usage-status

A Claude Code mod that shows your remaining subscription and context usage as its own row under the prompt's hint line:

```
⏵⏵ auto mode on (shift+tab to cycle)
Claude Usage Remaining: session 94% · week 76% · context 63%
```

- **session** is the rolling 5-hour window (`five_hour`)
- **week** is the 7-day window (`seven_day`)
- **context** is this session's context window, measured against the current model's window size

The row is drawn in the default color, and turns yellow when session or week drops below 10% remaining, or context below 15%. Auto-compact measures against its own limit, which can be smaller than the model's window, so it may fire while context still shows a little left.

## How it works

The mod uses the function-hooks API (`hooks/hooks.json` → `hooks/register.tsx`):

- A `ui.render` hook on `PromptHint` draws the engine's hint line, then a row below it with the rate-limit windows and context fill read from `$.session.usage()`.
- On `session.measure`, which fires after each turn and whenever a rate-limit window or the context fill moves, it calls `$.ui.invalidate('ui.render')` to redraw the line.

The figures come from the API's response to each turn, so the row appears after the first response of a session; context is also missing right after a compaction, until the next response. Off a subscription (API key, gateway) no rate-limit windows are reported and the row shows context alone.

`hooks.json` carries an empty `"hooks": {}` beside `"modules"` so skillsaw's `claude-hooks-valid` rule accepts it.

## Install

```bash
/plugin install usage-status@robbyt-claude-skills
```

Or load it from a checkout:

```bash
claude --plugin-dir plugins/usage-status
```

## Development

```bash
make test-plugin PLUGIN=usage-status
```

Runs `claude plugin validate` and `claude plugin test` against the plugin.
