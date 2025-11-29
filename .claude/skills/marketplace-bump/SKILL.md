---
name: marketplace-bump
description: Bump a plugin version in marketplace.json using semantic versioning. Use when user asks to "bump version", "increment version", "release new version", or after making changes that warrant a version update.
---

# Version Bump

Bump a plugin version in marketplace.json following semantic versioning.

## Inference Rules

Infer bump type from context:
- **Major** (X.0.0): Breaking changes, renames, restructuring
- **Minor** (x.Y.0): New features, new skills
- **Patch** (x.y.Z): Bug fixes, doc updates

## Commands

```bash
# Bump patch (e.g., 1.2.3 → 1.2.4)
jq '(.plugins[] | select(.name == "PLUGIN_NAME") | .version) |= (split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' .claude-plugin/marketplace.json > /tmp/claude/marketplace.json && mv /tmp/claude/marketplace.json .claude-plugin/marketplace.json

# Bump minor (e.g., 1.2.3 → 1.3.0)
jq '(.plugins[] | select(.name == "PLUGIN_NAME") | .version) |= (split(".") | .[1] = ((.[1] | tonumber) + 1 | tostring) | .[2] = "0" | join("."))' .claude-plugin/marketplace.json > /tmp/claude/marketplace.json && mv /tmp/claude/marketplace.json .claude-plugin/marketplace.json

# Bump major (e.g., 1.2.3 → 2.0.0)
jq '(.plugins[] | select(.name == "PLUGIN_NAME") | .version) |= (split(".") | .[0] = ((.[0] | tonumber) + 1 | tostring) | .[1] = "0" | .[2] = "0" | join("."))' .claude-plugin/marketplace.json > /tmp/claude/marketplace.json && mv /tmp/claude/marketplace.json .claude-plugin/marketplace.json
```

Replace `PLUGIN_NAME` with the actual plugin name.

## Workflow

1. Get current version first:
   ```bash
   jq '.plugins[] | select(.name == "PLUGIN_NAME") | .version' .claude-plugin/marketplace.json
   ```
2. Run the appropriate bump command
3. Confirm new version to user

## Reference

- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
