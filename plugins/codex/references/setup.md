# Codex CLI Setup & Troubleshooting

Shared reference for all Codex skills.

## Prerequisites

Codex CLI must be installed and authenticated before using any Codex skill.

**Installation:**
```bash
# Via npm
npm install -g @openai/codex

# Verify installation
codex --version
```

**Verify:**
```bash
codex --version  # Should show version
codex "test" --ask-for-approval never --sandbox read-only  # Should respond
```

## Authentication

Claude Code will NOT configure authentication. Codex CLI must be pre-configured with API keys or OAuth before using these skills. See [official Codex CLI docs](https://github.com/openai/codex) for authentication options.

## Sandbox Modes

Codex supports three sandbox modes via `--sandbox` or `-s`:

| Mode | Description |
|------|-------------|
| `read-only` | Can read files but cannot write. Use for analysis tasks. |
| `workspace-write` | Can write within the workspace directory only. |
| `danger-full-access` | Full filesystem access. Use with caution. |

For read-only analysis skills, always use `--sandbox read-only`.

## Approval Policies

Control when Codex asks for approval via `--ask-for-approval` or `-a`:

| Policy | Description |
|--------|-------------|
| `untrusted` | Only trusted commands run without approval |
| `on-failure` | Run all commands, ask on failure |
| `on-request` | Model decides when to ask |
| `never` | Never ask for approval |

For non-interactive use, use `--ask-for-approval never`.

## Troubleshooting

### Sandbox Permission Error

**Problem:** Codex cannot read/write files as expected.

**Solution:** Ensure the correct sandbox mode is specified. For read-only analysis, use `--sandbox read-only`. For tasks requiring file writes, use `--sandbox workspace-write`.

### Authentication Issues

**Problem:** `codex` commands fail with authentication errors.

**Solution:** Verify your Codex CLI authentication configuration. See [official docs](https://github.com/openai/codex) for API key or OAuth setup.

### Timeout

Complex analysis may take several minutes. Allow up to 10 minutes before assuming timeout.

## Working with Files

Codex can read files directly. Pass file paths in prompts:

```bash
codex exec "Review the code in src/main.ts" --sandbox read-only --ask-for-approval never
```

For files outside the workspace, save them to the project root first.

## Non-Interactive Execution

Use `codex exec` for non-interactive execution:

```bash
codex exec "Your prompt here" --sandbox read-only --ask-for-approval never
```
