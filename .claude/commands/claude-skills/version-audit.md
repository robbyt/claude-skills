Manage plugin versions in marketplace.json using semantic versioning.

## Read Versions

List all plugin versions:
```bash
jq '.plugins[] | {name, version}' .claude-plugin/marketplace.json
```

Get specific plugin version:
```bash
jq '.plugins[] | select(.name == "PLUGIN_NAME") | .version' .claude-plugin/marketplace.json
```

## Bump Versions

When asked to bump a version, infer the change type:
- **Major**: Breaking changes, renames, restructuring → increment first number, reset others
- **Minor**: New features, new skills → increment second number, reset patch
- **Patch**: Bug fixes, doc updates → increment third number

Use jq to update (write output to temp file, then move):
```bash
# Bump patch (e.g., 1.2.3 → 1.2.4)
jq '(.plugins[] | select(.name == "PLUGIN_NAME") | .version) |= (split(".") | .[2] = ((.[2] | tonumber) + 1 | tostring) | join("."))' .claude-plugin/marketplace.json > /tmp/claude/marketplace.json && mv /tmp/claude/marketplace.json .claude-plugin/marketplace.json

# Bump minor (e.g., 1.2.3 → 1.3.0)
jq '(.plugins[] | select(.name == "PLUGIN_NAME") | .version) |= (split(".") | .[1] = ((.[1] | tonumber) + 1 | tostring) | .[2] = "0" | join("."))' .claude-plugin/marketplace.json > /tmp/claude/marketplace.json && mv /tmp/claude/marketplace.json .claude-plugin/marketplace.json

# Bump major (e.g., 1.2.3 → 2.0.0)
jq '(.plugins[] | select(.name == "PLUGIN_NAME") | .version) |= (split(".") | .[0] = ((.[0] | tonumber) + 1 | tostring) | .[1] = "0" | .[2] = "0" | join("."))' .claude-plugin/marketplace.json > /tmp/claude/marketplace.json && mv /tmp/claude/marketplace.json .claude-plugin/marketplace.json
```

## Inference Guidelines

When user says "bump version" without specifying type, infer from context:
- Renamed plugin/skill → major
- New skill added → minor
- Fixed bug, updated docs → patch
- Restructured directories → major
- Added new feature to existing skill → minor
