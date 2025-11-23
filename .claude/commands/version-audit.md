Audit version consistency between marketplace.json and individual plugin.json files, then help reconcile any mismatches.

## Instructions

1. **Discover all plugins** using Glob:
   ```
   pattern: plugins/*/.claude-plugin/plugin.json
   ```

2. **Read all plugin.json files** in parallel using the Read tool

3. **Read marketplace.json**:
   ```
   file_path: .claude-plugin/marketplace.json
   ```

4. **Compare versions** for each plugin:
   - Extract version from each plugin's `.claude-plugin/plugin.json`
   - Find corresponding entry in `marketplace.json` plugins array
   - Identify any mismatches

5. **Report findings** to the user:
   - List all plugins with matching versions (✓)
   - List all plugins with version mismatches (✗) showing both versions
   - If marketplace metadata version differs from plugin versions, note that too

6. **If mismatches found**, use AskUserQuestion to ask how to reconcile:
   - Option 1: "Sync from individual plugin.json files" - Update marketplace.json entries to match their plugin.json versions
   - Option 2: "Sync from marketplace.json entries" - Update individual plugin.json files to match marketplace entries
   - Option 3: "Bump all to [highest version]" - Synchronize everything to the highest version found
   - Option 4: "Do nothing" - Just report, don't make changes

7. **Apply the user's choice** by updating the appropriate files

## Context

The marketplace.json file contains a registry of all plugins with their metadata, including version numbers. Each plugin also has its own `.claude-plugin/plugin.json` file with version information. These should be kept in sync.

Version mismatches can occur when:
- A plugin is updated locally but marketplace.json isn't updated
- Marketplace.json is updated but individual plugins aren't
- New plugins are added without version consistency checks
