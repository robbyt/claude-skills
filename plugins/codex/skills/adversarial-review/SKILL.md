---
name: adversarial-review
description: Have Codex try to break a change before it ships — a skeptical review that challenges the design, assumptions, and failure modes of a diff or branch and returns structured findings (verdict, severity, file:line, confidence). Trigger on "adversarial review", "challenge this change/design with Codex", "pressure-test this before I ship", "have Codex try to break this", "is this safe to merge", or a review focused on a risk area (auth, data loss, rollback, race conditions, retries). Do NOT use for a routine bug/style pass over a diff (that's diff-review), for critiquing a plan before code exists (plan-review), or for mapping architecture (codebase-analysis).
---

# Adversarial Review via Codex

Have Codex argue against shipping a change: question the chosen approach, the assumptions it relies on, and how it fails under real conditions. This is different from `diff-review`, which looks for defects in the code as written. Codex consults; Claude writes.

Prompt and output schema adapted from OpenAI's Codex plugin for Claude Code (openai/codex-plugin-cc, Apache-2.0).

## Transport

**Always use the MCP tool.** The plugin's MCP server (`scripts/codex-mcp-server.mjs`) runs `codex exec` for each call. Tool name: `mcp__plugin_codex_cli__codex`. If it errors with an unknown-tool error, run `/mcp` and substitute the actual prefix.

## Model

**Pin `model: "gpt-6-sol"` with `config: { "model_reasoning_effort": "medium" }`.** Don't downgrade to `gpt-6-luna`; this review depends on reasoning depth. Honor an explicit user-named model or effort. See `../references/patterns.md` → Models.

## Flow

1. **Pick the target and save the diff** in the project root (Codex reads files relative to it):

   ```bash
   git diff HEAD > codex-review.diff            # uncommitted work (staged + unstaged)
   git diff main...HEAD > codex-review.diff     # branch vs base
   ```

   `git diff HEAD` doesn't include untracked files. If `git status --short` shows new files that belong to the change, `git add -N <file>` them first so they appear in the diff. If the diff is empty, tell the user there is nothing to review and stop.

2. **Call Codex** with the bundled review schema (`outputSchema: "review"`). Replace `[TARGET]` with a short label (e.g. "uncommitted changes", "branch feature-x vs main") and `[FOCUS]` with the user's focus area, or "none" if they gave none:

   ```
   mcp__plugin_codex_cli__codex({
     "prompt": "<role>\nYou are Codex performing an adversarial software review.\nYour job is to break confidence in the change, not to validate it.\n</role>\n\n<task>\nReview the change in codex-review.diff as if you are trying to find the strongest reasons it should not ship yet. Read the surrounding source files as needed.\nTarget: [TARGET]\nUser focus: [FOCUS]\n</task>\n\n<operating_stance>\nDefault to skepticism. Assume the change can fail in subtle, high-cost, or user-visible ways until the evidence says otherwise. Do not give credit for good intent, partial fixes, or likely follow-up work. If something only works on the happy path, treat that as a real weakness.\n</operating_stance>\n\n<attack_surface>\nPrioritize failures that are expensive, dangerous, or hard to detect:\n- auth, permissions, tenant isolation, and trust boundaries\n- data loss, corruption, duplication, and irreversible state changes\n- rollback safety, retries, partial failure, and idempotency gaps\n- race conditions, ordering assumptions, stale state, and re-entrancy\n- empty-state, null, timeout, and degraded dependency behavior\n- version skew, schema drift, migration hazards, and compatibility regressions\n- observability gaps that would hide failure or make recovery harder\n</attack_surface>\n\n<review_method>\nActively try to disprove the change. Look for violated invariants, missing guards, unhandled failure paths, and assumptions that stop being true under stress. Trace how bad inputs, retries, concurrent actions, or partially completed operations move through the code. If the user supplied a focus area, weight it heavily, but still report any other material issue you can defend.\n</review_method>\n\n<finding_bar>\nReport only material findings. No style, naming, or low-value cleanup, and no speculative concerns without evidence. Each finding answers: what can go wrong, why this code path is vulnerable, the likely impact, and what concrete change would reduce the risk.\n</finding_bar>\n\n<structured_output_contract>\nReturn only valid JSON matching the provided schema. Use needs-attention if there is any material risk worth blocking on; use approve only if you cannot support any substantive adversarial finding. Every finding includes the file, line_start and line_end, a confidence from 0 to 1, and a concrete recommendation. Write the summary as a terse ship/no-ship assessment.\n</structured_output_contract>\n\n<grounding_rules>\nBe aggressive but grounded. Every finding must be defensible from the repository or tool output. Do not invent files, lines, code paths, or runtime behavior. If a conclusion depends on an inference, say so in the finding body and keep the confidence honest.\n</grounding_rules>\n\n<calibration_rules>\nPrefer one strong finding over several weak ones. If the change looks safe, say so and return no findings.\n</calibration_rules>",
     "sandbox": "read-only",
     "model": "gpt-6-sol",
     "config": { "model_reasoning_effort": "medium" },
     "outputSchema": "review"
   })
   ```

3. **Clean up:** `rm codex-review.diff`.

For large diffs, run this through the `codex:consult` agent in the background (`run_in_background: true`) so the session isn't blocked. Reviews of multi-file changes can take several minutes.

## Presenting the result

The final message is JSON with this shape (`schemas/review-output.schema.json`):

```json
{
  "verdict": "approve | needs-attention",
  "summary": "terse ship/no-ship assessment",
  "findings": [
    { "severity": "critical|high|medium|low", "title": "...", "body": "...", "file": "...",
      "line_start": 1, "line_end": 1, "confidence": 0.0, "recommendation": "..." }
  ],
  "next_steps": ["..."]
}
```

Render it for the user instead of pasting raw JSON:

```
**Codex verdict: needs-attention** — <summary>

1. [high] <title> — `path/to/file.ts:42-58` (confidence 0.8)
   <body>
   Recommendation: <recommendation>

Next steps: …
```

- Order findings by severity, then confidence. Keep file paths and line ranges exactly as reported.
- Keep the confidence scores, and any place where Codex said a finding depends on an inference.
- If `findings` is empty, say Codex found nothing to block on, in one line.
- If the text isn't valid JSON, show it as-is and say that the structured output failed.
- **Then stop and ask the user which findings, if any, to address.** Don't fix anything automatically. See `../references/patterns.md` → Presenting results.

## Follow-ups

To dig into one finding, or to check whether a fix resolves it, use `mcp__plugin_codex_cli__codex-reply` with the `threadId` argument from the result. Don't put the threadId in the prompt. Re-save the diff first if the code changed, and say so in the prompt ("codex-review.diff was regenerated after the fix — re-read it"). From round 3, or if a finding is still disputed after a round, pass `"model": "gpt-6-astra"` and `"config": { "model_reasoning_effort": "medium" }` on the `codex-reply` (see `../references/patterns.md` → Escalating to gpt-6-astra). Re-running an adversarial review on a revised version of the same change also opens on `gpt-6-astra`. Cap follow-ups at 3–4 rounds.

## Safety

- **Always** `sandbox: "read-only"`. The server rejects anything else.
- Never use `--dangerously-bypass-approvals-and-sandbox`.
- Remove the temporary diff file when done.
