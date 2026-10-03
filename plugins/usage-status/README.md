# usage-status

A Claude Code mod that pins your remaining subscription usage in a status row under the prompt:

```
usage-status: session 77% · week 58% remaining
```

- **session** is the rolling 5-hour window (`five_hour`)
- **week** is the 7-day window (`seven_day`)

## How it works

The mod uses the function-hooks API (`hooks/hooks.json` → `hooks/register.ts`):

- On `session.start` it reads `$.session.usage()` and sets the status row with `$.ui.status()`.
- On `session.measure`, which fires after each turn and whenever a rate-limit window moves a whole point, it refreshes the row.

The figures are the same rate-limit windows the API reports on each response, so the row appears after the first response of a session. Off a subscription (API key, gateway) no windows are reported and the row stays empty.

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
