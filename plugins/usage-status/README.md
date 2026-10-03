# usage-status

A Claude Code mod that shows your remaining subscription usage as its own row under the prompt's hint line:

```
⏵⏵ auto mode on (shift+tab to cycle)
Claude Usage Remaining: session 94% · week 76%
```

- **session** is the rolling 5-hour window (`five_hour`)
- **week** is the 7-day window (`seven_day`)

The text is drawn in the default color, and turns yellow when either window drops below 10% remaining.

## How it works

The mod uses the function-hooks API (`hooks/hooks.json` → `hooks/register.tsx`):

- A `ui.render` hook on `PromptHint` draws the engine's hint line, then a row below it with the usage read from `$.session.usage()`.
- On `session.measure`, which fires after each turn and whenever a rate-limit window moves a whole point, it calls `$.ui.invalidate('ui.render')` to redraw the line.

The figures are the same rate-limit windows the API reports on each response, so the row appears after the first response of a session. Off a subscription (API key, gateway) no windows are reported and the hint line is left as the engine draws it.

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
