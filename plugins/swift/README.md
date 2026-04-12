# swift

Swift development tools for Claude Code.

## Components

### Hooks: Swift Formatter

Automatically formats Swift files with `swift-format` after Write/Edit/MultiEdit operations.

**Formatter Priority:**
1. **swiftformat** - [Nick Lockwood's SwiftFormat](https://github.com/nicklockwood/SwiftFormat) (`brew install swiftformat`). More configurable, widely adopted.
2. **swift format** - Built into Swift toolchain. Fallback if swiftformat is not installed.

**Requirements:** `swiftformat` or Swift toolchain, `jq`

### Skills: SwiftData

Expert guidance for SwiftData development covering @Model definitions, @Query, @Relationship, ModelContext, schema migration, Swift 6 concurrency, performance optimization, CloudKit integration, and architecture auditing.

Includes 11 reference files for progressive disclosure of detailed patterns.

## Usage

Once installed, the formatter hook runs automatically. The SwiftData skill triggers when working on SwiftData-related tasks.

Remove any existing swift-format PostToolUse hooks from `~/.claude/settings.json` to avoid running swift-format twice.
