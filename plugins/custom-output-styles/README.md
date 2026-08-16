# custom-output-styles

Custom [output styles](https://code.claude.com/docs/en/output-styles) for Claude Code. Output styles are text appended to the system prompt on every turn; they change role, tone, and default response format. Plugin-shipped styles appear in `/config` → **Output style** as `custom-output-styles:<Style>`.

Styles in this plugin:

| Style | Picker entry | Purpose |
|---|---|---|
| Programming | `custom-output-styles:Programming` | Describe things instead of inventing vocabulary; keep established programming terminology |

## Programming

An output style that has Claude **describe things instead of naming them**. It stops the habit of inventing a word for an idea (turning a process into a noun, borrowing a term from finance or law for a file check, compressing a multi-part idea into one token) and replaces it with the plain sentence the word would have stood for.

The style keeps Claude Code's built-in software engineering instructions (`keep-coding-instructions: true`), so Claude scopes changes, comments, and verifies work exactly as before. Only the writing changes.

### What it does

An output style is text appended to Claude Code's system prompt, on every turn. This one tells Claude to:

- Say what a thing is and what it does, in a sentence, every time it comes up — rather than coining a term for it.
- Keep established vocabulary precise. The style names the categories of programming terminology that stay (language and runtime, concurrency and systems, data and algorithms, tools and workflow — `race condition`, `idempotent`, `invariant`, `rebase`, and so on) and gives a test for the boundary: a term stays when it already has a stable meaning in the relevant technical community, independent of this codebase; a label coined in the conversation gets described instead. This is not a request to dumb the content down.
- Quote existing bad identifiers as locators in parentheses instead of adopting them as the register of the sentence.
- Translate what comes back from subagents, reviews, and external tools into plain language before relaying it.

The full text is in [`output-styles/programming.md`](output-styles/programming.md).

## Installation

From this marketplace:

```
/plugin install custom-output-styles
```

Or load locally:

```bash
claude --plugin-dir /path/to/plugins/custom-output-styles
```

## Selecting the style

Installing the plugin does **not** switch the style on. It appears as an option; you opt in:

1. Run `/config` and choose **Output style**.
2. Select **Programming**. Plugin-shipped styles are listed under the plugin's name, so the entry is `custom-output-styles:Programming`.
3. Run `/clear` or start a new session.

Or set it directly in a settings file (this is what `/config` writes to `.claude/settings.local.json`):

```json
{
  "outputStyle": "custom-output-styles:Programming"
}
```

The plugin prefix is required. `"outputStyle": "Programming"` on its own only resolves if you also have a file of that name in `~/.claude/output-styles/` or `.claude/output-styles/`.

Use `/config`, not `/output-style` — the standalone command was deprecated in Claude Code v2.1.73 and removed in v2.1.91.

## Things to know

- **Changes take effect after `/clear` or a new session.** The system prompt is read once at session start. If you select the style mid-session and see no change, that is why; it is not broken.
- **Only one output style is active at a time.** Selecting this one replaces whatever style was selected before (including the built-in Explanatory or Learning styles). Styles do not stack.
- **The style does not apply to subagents.** A subagent runs its own system prompt. Work delegated to a subagent, an external review tool (Codex, Gemini, agy), or an MCP server comes back in its own voice. The style tells Claude to translate that output before relaying it, but the delegated work itself is written without the style. Forks are the exception: a fork inherits the parent's full system prompt.
- **This plugin never forces the style on.** It does not set `force-for-plugin`. Enabling the plugin for its style leaves your `outputStyle` setting alone until you pick it in `/config`.

## Repo conventions for output styles

This is the first plugin in the marketplace to ship an `output-styles/` directory. Rules the tests enforce, so the next style added here inherits them:

- Every style sets `keep-coding-instructions` **explicitly**, whatever its value. The default is `false`, which silently drops Claude Code's own coding instructions; a missing field looks like nothing and is the easiest mistake to make.
- No style in the marketplace sets `force-for-plugin`. If one ever does, at most one plugin across the whole marketplace may, since two forced styles resolve by plugin load order.
- The `name` in the style's frontmatter is the name the README tells users to select.
- A style contains no repository-specific paths, project names, or conventions. It applies to every repository the user opens; project facts belong in `CLAUDE.md`.

## Testing

```bash
make test-plugin PLUGIN=custom-output-styles
```

Behavior is not unit-testable; the tests check structure — frontmatter parses, `name`/`description`/`keep-coding-instructions` are present, `force-for-plugin` is absent (and the at-most-one rule holds across the marketplace), the frontmatter name matches this README, and the style is free of repository-specific content.
