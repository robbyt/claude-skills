---
name: plugin-bump
description: Bump a plugin version in its plugin.json file using semantic versioning. Use when user asks to "bump plugin version", "increment plugin version", or after making changes to a plugin that warrant a version update.
---

# Plugin Version Bump

Bump a plugin version in `plugins/PLUGIN_NAME/.claude-plugin/plugin.json` following semantic versioning.

## Inference Rules

Infer bump type from context:
- **Major** (X.0.0): Breaking changes, renames, restructuring
- **Minor** (x.Y.0): New features, new skills
- **Patch** (x.y.Z): Bug fixes, doc updates, grammar fixes

## Commands

```bash
# Bump patch (e.g., 1.2.3 → 1.2.4)
jq '.version |= (split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' plugins/PLUGIN_NAME/.claude-plugin/plugin.json > /tmp/claude/plugin.json && mv /tmp/claude/plugin.json plugins/PLUGIN_NAME/.claude-plugin/plugin.json

# Bump minor (e.g., 1.2.3 → 1.3.0)
jq '.version |= (split(".") | .[1] = ((.[1] | tonumber) + 1 | tostring) | .[2] = "0" | join("."))' plugins/PLUGIN_NAME/.claude-plugin/plugin.json > /tmp/claude/plugin.json && mv /tmp/claude/plugin.json plugins/PLUGIN_NAME/.claude-plugin/plugin.json

# Bump major (e.g., 1.2.3 → 2.0.0)
jq '.version |= (split(".") | .[0] = ((.[0] | tonumber) + 1 | tostring) | .[1] = "0" | .[2] = "0" | join("."))' plugins/PLUGIN_NAME/.claude-plugin/plugin.json > /tmp/claude/plugin.json && mv /tmp/claude/plugin.json plugins/PLUGIN_NAME/.claude-plugin/plugin.json
```

Replace `PLUGIN_NAME` with the actual plugin name (e.g., `gemini`, `go-formatter`).

## Workflow

1. Get current version first:
   ```bash
   jq '.version' plugins/PLUGIN_NAME/.claude-plugin/plugin.json
   ```
2. Run the appropriate bump command
3. Confirm new version to user

## Reference

- [Plugins](https://code.claude.com/docs/en/plugins)
