# Prompting Codex

How to write prompts for the `codex` and `codex-reply` MCP tools. Adapted for read-only consultation from the `gpt-5-4-prompting` skill in OpenAI's Codex plugin for Claude Code (openai/codex-plugin-cc, Apache-2.0).

## Rules

- **One task per call.** Split unrelated asks (review + docs + roadmap) into separate threads.
- **Say what a finished answer looks like.** Give an output contract instead of hoping Codex infers the shape.
- **Ground reviews and analysis.** Require claims to be tied to files, lines, or tool output, and require inferences to be labelled.
- **Improve the prompt before raising effort.** A clearer contract and verification rule usually help more than moving from `medium` to `high`.
- **Use XML tags for structure.** Use the tag names below consistently so prompts have a predictable shape.
- **On `codex-reply`, send only the change.** Codex already has the earlier prompt and its own answer. Restate everything only if the direction changed.

## Blocks

Include `<task>` in every prompt. Add the other blocks only when the task needs them.

| Block | Use for | Text |
|-------|---------|------|
| `<task>` | Every prompt | The concrete job, the relevant repo context (paths, constraints, what's already decided), and the expected end state. |
| `<structured_output_contract>` | Reviews, anything you will parse or rank | "Return exactly this shape: … Put the highest-severity findings first. Keep it compact." |
| `<compact_output_contract>` | Short prose answers | "Keep the answer compact and structured. No scene-setting or recap." |
| `<grounding_rules>` | Review, analysis, root cause | "Ground every claim in the files you read or tool output. Do not present inferences as facts; label hypotheses." |
| `<missing_context_gating>` | Anywhere Codex might guess | "Do not guess missing repository facts. Read the code, or state exactly what remains unknown." |
| `<dig_deeper_nudge>` | Reviews | "After the first plausible issue, check second-order failures, empty state, retries, stale state, and rollback paths." |
| `<verification_loop>` | Diagnosis | "Before finalizing, check that the conclusion matches the observed evidence; revise if it doesn't." |
| `<default_follow_through_policy>` | Every non-trivial task | "Pick the most reasonable interpretation and keep going. Don't ask clarifying questions; note assumptions instead." |
| `<research_mode>` | Comparisons, recommendations | "Separate observed facts, reasoned inferences, and open questions." |
| `<citation_rules>` | Web or docs research | "Back important claims with links to primary sources." |

## Recipes

### Review (diff or plan)

```xml
<task>
Review codex-review.diff for material correctness, security, and regression risks.
Context: [what the change is for; constraints that are already settled].
</task>

<structured_output_contract>
Return findings ordered by severity (critical, high, medium, low). For each: file:line, what goes wrong, why, and a concrete fix.
If there are no material findings, say so in one line.
</structured_output_contract>

<grounding_rules>
Ground every finding in the diff or files you read. Label inferences. No style or naming nits.
</grounding_rules>

<dig_deeper_nudge>
After the first issue, check error paths, empty state, retries, and concurrency before finishing.
</dig_deeper_nudge>
```

### Diagnosis (read-only)

```xml
<task>
Diagnose why [failing test / command / behavior] fails in this repository. Do not modify files.
Observed: [error output, what was already tried].
</task>

<compact_output_contract>
Return: 1. most likely root cause, 2. evidence (file:line, output), 3. smallest safe next step.
</compact_output_contract>

<verification_loop>
Before finalizing, check the root cause against the observed evidence.
</verification_loop>

<missing_context_gating>
Do not guess. If something needed is absent, say exactly what is unknown.
</missing_context_gating>
```

### Research / current information

```xml
<task>
[Question]. Context: [stack, versions, constraints].
</task>

<research_mode>
Separate observed facts, inferences, and open questions. Go broad first, then deep only where it changes the recommendation.
</research_mode>

<citation_rules>
Link primary sources (official docs, release notes, source) for important claims.
</citation_rules>
```

## Antipatterns

| Instead of | Write |
|------------|-------|
| "Take a look and tell me what you think." | `<task>Review this change for material correctness and regression risks.</task>` |
| "Investigate and report back." | An output contract: root cause, evidence, next step. |
| "Think really hard." | A `<verification_loop>` or `<grounding_rules>` block. |
| "Review the diff, fix the bug, update the docs." | Separate calls; and Codex doesn't fix anything in this plugin. |
| "Tell me exactly why prod failed." | `<grounding_rules>` requiring labelled inferences. |
| "Continue thread 019d… and answer X" in the prompt | `codex-reply` with `threadId` as the argument and just "Answer X" as the prompt. |
