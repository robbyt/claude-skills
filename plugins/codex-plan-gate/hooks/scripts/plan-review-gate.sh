#!/usr/bin/env bash
#
# codex-plan-gate :: PreToolUse hook for ExitPlanMode
#
# Intercepts the first ExitPlanMode call for a plan and DENIES it, handing Claude
# instructions to consult the Codex MCP server, refine the plan over a capped
# iterative loop, and re-submit. A short-lived, session-keyed marker file lets the
# refined re-submission through so we don't block forever.
#
# Decision model:
#   - no marker (or stale marker)  -> DENY + (re)write marker   [first/initial plan]
#   - fresh marker                 -> ALLOW + clear marker       [refined re-submission]
#
# Fails OPEN: if jq is missing or anything unexpected happens, the plan is allowed
# through unreviewed rather than breaking plan mode.

set -euo pipefail

# Freshness window (seconds). A marker older than this is treated as stale, so an
# abandoned plan can't permanently disable the gate.
WINDOW=1800

allow() { exit 0; }  # no stdout => default allow

# jq is required to parse the hook payload and emit safe JSON. Fail open without it.
if ! command -v jq >/dev/null 2>&1; then
  allow
fi

input="$(cat)"
session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"')"
# Sanitize to a safe filename component (defends the marker path from traversal/odd chars).
session_id="${session_id//[^A-Za-z0-9_-]/_}"
[ -n "$session_id" ] || session_id="unknown"

state_dir="${TMPDIR:-/tmp}/claude-codex-plan-gate"
mkdir -p "$state_dir" 2>/dev/null || allow
marker="$state_dir/${session_id}.pending"

now="$(date +%s)"

if [ -f "$marker" ]; then
  mtime="$(stat -f %m "$marker" 2>/dev/null || stat -c %m "$marker" 2>/dev/null || echo 0)"
  age=$(( now - mtime ))
  if [ "$age" -lt "$WINDOW" ]; then
    # This is the refined re-submission for a plan we already gated. Let it through.
    rm -f "$marker" 2>/dev/null || true
    allow
  fi
  # Stale marker: fall through and treat as a brand-new plan.
fi

# First time we've seen this plan: record the marker and block with instructions.
touch "$marker" 2>/dev/null || true

read -r -d '' reason <<'EOF' || true
Plan gate: before exiting plan mode, route this plan through a Codex review. Do the
steps below, then call ExitPlanMode AGAIN with the (possibly revised) plan - this gate
will let the re-submission through.

1. SKIP CHECK. If the plan is trivial - a single obvious edit, a doc/typo/config tweak,
   or low-risk work with no real design decisions - skip the review. Re-call ExitPlanMode
   and append one line to the plan: "_Codex review skipped: trivial plan._"

2. CONSULT CODEX. Otherwise call the MCP tool `mcp__plugin_codex_cli__codex` with
   `sandbox: "read-only"`. Embed the FULL plan you just wrote in the prompt and ask Codex
   to flag gaps, missing steps, risks, and better alternatives. List any in-repo files
   Codex should read for context. Note the `threadId` it returns - you need it for step 3.
   (If that tool name errors, run /mcp to find the codex prefix. If there is no codex MCP
   tool, the `codex` plugin isn't installed - note that in the plan and just re-call
   ExitPlanMode.)

3. ITERATE on the SAME thread (cap 3 rounds). For every follow-up, call
   `mcp__plugin_codex_cli__codex-reply` and pass the `threadId` from step 2's response as the
   `threadId` tool argument (NOT inside the prompt text, and do NOT start a fresh `codex`
   call). Reusing the thread is what keeps the plan and Codex's prior critique in context;
   a new `codex` call discards that reasoning. Each round: revise the plan to address the
   material concerns, send the revised sections back via `codex-reply`, and ask whether the
   revision resolves them. Keep using the same `threadId` for rounds 2 and 3. Stop at 3
   rounds total; if anything is still unresolved, surface it as an open question in the plan
   instead of looping further.

4. RE-SUBMIT. Call ExitPlanMode with the refined plan, and note briefly at the end what
   Codex changed or confirmed.
EOF

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  },
  systemMessage: "codex-plan-gate: routing this plan through a Codex review before it is shown."
}' || allow  # if emitting the deny payload ever fails, fail open rather than erroring plan mode

exit 0
