# Google Antigravity (agy) CLI Setup & Troubleshooting

Shared reference for all agy skills.

## What is `agy`?

`agy` is the CLI for **Google Antigravity**, Google's agentic successor to `gemini-cli`.
It runs Google's Gemini models, reuses the existing `~/.gemini/` auth and session
directory, and is the migration target now that Google is deprecating `gemini-cli`.
Throughout this plugin, "agy" and "Google Antigravity" refer to the same thing.

## Prerequisites

The `agy` CLI must be installed and authenticated before using any agy skill.

**Verify:**
```bash
agy --version
agy --print "test" --dangerously-skip-permissions
```

If `agy` is not on `PATH`, run `agy install` to configure environment paths and shell
settings.

## Authentication

Claude Code will NOT configure authentication. Complete setup manually following
Google's Antigravity instructions. Auth state is stored under
`~/.gemini/config/projects/...` — the same directory the old `gemini-cli` used, since
both share Google's Gemini auth backend. A symlink at `.antigravitycli/<uuid>.json`
may also exist inside the project.

## Non-interactive Use

`agy` prompts the user before running tools, which will hang any non-interactive call.
**Always** pass `--dangerously-skip-permissions` from Claude Code:

```bash
agy --print "..." --dangerously-skip-permissions
```

Without that flag, the Bash tool call will appear to hang forever.

## Tool Restrictions (no --allowed-tools)

`agy` does **not** support a `--tools` or `--allowed-tools` flag. Trying to pass one
yields `flags provided but not defined`. Restrict behavior in one of these ways:

1. **Prompt-level instruction** — embed an explicit "Do not edit any files; respond
   with feedback only" in the prompt. Used by the consulting skills (web-search,
   plan-review, diff-review).
2. **`--sandbox`** — runs the agent with restricted terminal access. The agent can
   still read/write files in the workspace but cannot execute arbitrary shell
   commands. Used by `codebase-analysis` so agy can explore the tree without being
   able to mutate it through shell side-effects.
3. **Omit `--dangerously-skip-permissions`** (interactive only) — user approves each
   tool call. Not appropriate for Claude-driven scripting.

## Workspace & File Access

`agy` reads files from its workspace. The primary workspace is the directory you
launched it from; add more with `--add-dir <path>` (repeatable).

`agy` does **not** read prompt content from stdin. To feed in a file outside the
workspace (e.g. `~/.claude/plans/foo.md`), copy or symlink it into the workspace
first, or pass its path via `--add-dir`:

```bash
cp ~/.claude/plans/foo.md ./agy-plan.md
agy --print "Review agy-plan.md ..." --dangerously-skip-permissions
rm ./agy-plan.md
```

or

```bash
agy --add-dir ~/.claude/plans \
    --print "Review the plan at ~/.claude/plans/foo.md ..." \
    --dangerously-skip-permissions
```

## Sandbox Permission Errors

Like the old `gemini-cli`, Google Antigravity writes session state under `~/.gemini/...`
(both share Google's CLI infrastructure). Claude Code's bash sandbox blocks that path.

**Solution:** call `agy` with `dangerouslyDisableSandbox: true` on the Bash tool, the
same as the gemini skills did.

## Response Time

Tasks like codebase analysis and search can take several minutes. The `--print-timeout`
flag defaults to `5m0s`; raise it for big jobs. The duration needs a unit (`30s`, `3m`,
`10m`, `1h`):

```bash
agy --print-timeout 10m --print "..." --dangerously-skip-permissions
```

## Conversation Resume

```bash
agy --print "Initial question" --dangerously-skip-permissions
agy --continue --print "Follow up" --dangerously-skip-permissions
agy --conversation <ID> --print "..." --dangerously-skip-permissions
```

`--continue` resumes the most recent conversation; `--conversation <ID>` resumes a
specific one.
