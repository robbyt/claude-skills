# Google Antigravity (agy) CLI Plugin

Integrates **Google Antigravity** — Google's successor to `gemini-cli` — into Claude
Code as a set of consulting and research skills.

> Antigravity is Google's new agentic CLI. It uses Google's Gemini models under the
> hood (and shares the same `~/.gemini/` auth/session directory as `gemini-cli`), but
> exposes a different command surface. Since `gemini-cli` is being deprecated by
> Google, this plugin migrates the gemini consulting workflow to `agy`.

## Skills

### `agy:web-search`

Real-time web research using Google's search via the Antigravity CLI.

**Triggers:** "search with agy", "search with Antigravity", "ask Google's agy for current info on X"

### `agy:diff-review`

Code review of git changes by Google Antigravity for a second perspective.

**Triggers:** "have agy review my changes", "get a Google Antigravity code review", "review this diff with agy"

### `agy:plan-review`

Review and critique implementation plans using Google Antigravity.

**Triggers:** "have agy review this plan", "get a second opinion from Google Antigravity", "critique this plan with agy"

### `agy:codebase-analysis`

Architectural analysis of the current workspace using Google Antigravity.

**Triggers:** "analyze this codebase with agy", "map dependencies with Google Antigravity"

## Setup

See `references/setup.md` for installation and authentication. The full CLI surface is
documented in the project root's [AGY_CLI.md](../../AGY_CLI.md) and summarized in
`references/commands.md`.
