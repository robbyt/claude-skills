---
name: plan-review
description: Get Google Antigravity's (`agy`) review of Claude's implementation plans. Trigger when user wants a second opinion on a plan ("have agy review this plan", "get a second opinion from Google Antigravity", "critique this plan with agy"), or after Claude creates a plan file that needs validation before implementation. Replaces the deprecated gemini-cli plan-review workflow.
---

# Plan Review via Google Antigravity (`agy`)

Have Google's Antigravity CLI critique Claude's implementation plans for a second
perspective. `agy` is Google's successor to `gemini-cli` and runs Google's Gemini
models.

## Why This Skill Differs From gemini-cli's

Google Antigravity does **not** read prompt input from stdin and cannot read files
outside its workspace. Plans typically live under `~/.claude/plans/`, so the
`cat plan.md | gemini` pattern doesn't apply. Instead, copy the plan into the workspace
or add the plans directory to agy's workspace.

## Quick Start

Copy the plan into the workspace, run review, clean up:

```bash
cp ~/.claude/plans/example-plan.md ./agy-plan.md
agy --print "Review the implementation plan in agy-plan.md.

Consider:
1. Are there gaps or missing steps?
2. Are there risks not addressed?
3. Is the approach optimal?
4. What alternatives should be considered?

Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm ./agy-plan.md
```

Alternative: extend the workspace instead of copying:

```bash
agy --add-dir ~/.claude/plans \
    --print "Review the implementation plan at ~/.claude/plans/example-plan.md.
Do not make any changes. Respond with feedback only." \
    --dangerously-skip-permissions
```

Google Antigravity has no `--allowed-tools` flag — the "Do not make any changes"
clause is what keeps the call read-only.

## With Source Context

`agy` can read files within the workspace, so Google Antigravity can pull source code
context while reviewing:

```bash
cp ~/.claude/plans/auth-refactor.md ./agy-plan.md
agy --print "Review the implementation plan in agy-plan.md.

Also read these source files for context:
- src/auth/login.ts
- src/middleware/session.ts

Evaluate whether the plan addresses the actual codebase structure. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm ./agy-plan.md
```

## Focused Reviews

**Risk assessment:**
```bash
cp ~/.claude/plans/migration.md ./agy-plan.md
agy --print "Review agy-plan.md for risks:
- Breaking changes
- Data loss potential
- Rollback complexity
- Dependencies that could fail

Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm ./agy-plan.md
```

**Completeness check:**
```bash
cp ~/.claude/plans/feature.md ./agy-plan.md
agy --print "Review agy-plan.md for completeness:
- Are all edge cases covered?
- Is testing addressed?
- Are there missing steps?

Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm ./agy-plan.md
```

## Multi-turn Review

Use `--continue` to drill into Google Antigravity's critique:

```bash
cp ~/.claude/plans/migration.md ./agy-plan.md
agy --print "Review agy-plan.md for risks. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions

agy --continue --print "For the highest-risk items, suggest mitigations. Do not make any changes. Respond with feedback only." --dangerously-skip-permissions
rm ./agy-plan.md
```

## Notes

- **Google Antigravity must not make any changes; provide feedback ONLY.**
- Plans must be inside the workspace (copy in or use `--add-dir`); `agy` cannot read stdin or arbitrary paths.
- Choose a temp name that won't collide with project files (`agy-plan.md` is reasonable). Always `rm` it after.
- `agy` respects `.gitignore` — it cannot read files matching gitignore patterns.
- Requires `dangerouslyDisableSandbox: true` on the Bash tool because Google Antigravity writes session state under `~/.gemini/` (shared with the old gemini-cli).
- May take 2–3 minutes for thorough review with source analysis; bump `--print-timeout` if needed (use a unit, e.g. `--print-timeout 10m`).
- See `references/setup.md` and `references/patterns.md` for more.
