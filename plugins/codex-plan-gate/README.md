# codex-plan-gate

Routes every plan-mode plan through a **Codex review before you see it**. When Claude finishes planning and calls `ExitPlanMode`, a `PreToolUse` hook intercepts it, hands Claude instructions to consult the Codex MCP server, iterate on the plan over a capped loop, and only then presents the refined plan.

## What it does

```
Claude drafts a plan
        │
        ▼
  ExitPlanMode ──► PreToolUse hook  ──►  DENY + instructions
        ▲                                     │
        │                                     ▼
        │                          Claude consults Codex (read-only),
        │                          iterates up to 3 rounds, revises plan
        │                                     │
        └─────────────  re-call ExitPlanMode ─┘
                                              │
                                  hook sees fresh marker ──► ALLOW
                                              │
                                              ▼
                                   You see the refined plan
```

The hook **denies the first `ExitPlanMode` call** for a plan and feeds Claude a set of instructions: consult Codex via `mcp__plugin_codex_cli__codex` (sandbox `read-only`), have it flag gaps/risks/alternatives, iterate up to **3 rounds** with `codex-reply`, revise the plan, then re-submit. A short-lived, session-keyed marker file lets the refined re-submission through, so you only ever see the Codex-reviewed version.

Claude is told to **skip the review for trivial plans** (single obvious edits, doc/config tweaks) and just note that it skipped.

## Requirements

- **The `codex` plugin must be installed and enabled** — it provides the `codex mcp-server` that exposes the `mcp__plugin_codex_cli__codex` / `codex-reply` tools. Without it, the gate still runs but Claude will note that Codex is unavailable and pass the plan through unreviewed.
- `jq` on `PATH` (used by the hook script). If `jq` is missing the hook **fails open** — plan mode keeps working, just without the review.

## Installation

From this marketplace:

```
/plugin install codex-plan-gate
```

Or load locally for testing:

```bash
cc --plugin-dir /path/to/plugins/codex-plan-gate
```

> Hooks load at session start. After installing or editing the hook, **restart Claude Code** for it to take effect.

## How it works (internals)

- **Hook:** `hooks/hooks.json` registers a `PreToolUse` hook matching `ExitPlanMode|exit_plan_mode`.
- **Script:** `hooks/scripts/plan-review-gate.sh` is a deterministic command hook that manages the deny/allow gate.
- **State:** a marker file at `$TMPDIR/claude-codex-plan-gate/<session_id>.pending` prevents an infinite deny loop. It has a **30-minute freshness window** — an abandoned plan won't permanently disable the gate; the next plan after the window is reviewed again.

Decision model:

| Condition | Decision |
|-----------|----------|
| No marker, or marker older than 30 min | **deny** + (re)write marker — review this plan |
| Fresh marker (< 30 min) | **allow** + clear marker — this is the refined re-submission |
| `jq` unavailable / unexpected error | **allow** (fail open) |

## Disabling

Toggle the plugin off (`/plugin`) for a session where you don't want plans gated, or uninstall it. There is no per-plan opt-out beyond Claude's own triviality skip.

## Testing the hook directly

```bash
# First call for a session -> deny with instructions
echo '{"session_id":"demo","tool_name":"ExitPlanMode","tool_input":{"plan":"..."}}' \
  | bash hooks/scripts/plan-review-gate.sh | jq .

# Same session again -> allow (empty output) — simulates the refined re-submission
echo '{"session_id":"demo"}' | bash hooks/scripts/plan-review-gate.sh
```

## Caveats

- The gate relies on Claude following the injected instructions. It enforces *that a review happens before the plan is shown* via the deny/allow gate, but the depth of the Codex consultation is driven by Claude.
- Because the marker is session-keyed with a time window, two genuinely distinct plans submitted within seconds of each other could let the second through without its own review. In practice plans are minutes apart.
