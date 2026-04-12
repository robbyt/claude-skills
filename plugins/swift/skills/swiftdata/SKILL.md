---
name: swiftdata
description: >
  This skill should be used when working with SwiftData — @Model definitions, @Query, @Relationship,
  ModelContext, ModelContainer, schema migration, Swift 6 concurrency, performance optimization, or
  architecture review. Also triggers on: "SwiftData audit", "@Model issues", "SwiftData crashes",
  "predicate problems", "background context patterns", "N+1 queries", "SwiftData vs SQLiteData vs GRDB",
  "CloudKit sync with SwiftData", "SwiftData migration fails", or "SwiftData migration diagnostics".
  Covers auditing existing code, writing new SwiftData code, migration debugging, and architecture review.
version: 0.1.0
---

# SwiftData — Architecture, Patterns, and Audit Guide

Swift 6 strict concurrency only. No Swift 5 patterns.

## Decision: SwiftData vs SQLiteData vs GRDB

| Need | Choose | Why |
|------|--------|-----|
| Simple local CRUD + SwiftUI | **SwiftData** | Native integration, @Query, automatic observation |
| Complex queries, JOINs, FTS | **GRDB** | Full SQL access, 11 years battle-tested |
| SwiftData ergonomics + SQL power | **SQLiteData** | @Table structs, @FetchAll, CloudKit sharing support |
| Cross-platform (Android/Linux) | **GRDB** or raw SQLite | No Apple framework dependency |
| CloudKit shared databases | **SQLiteData** or Core Data | SwiftData only supports private CloudKit databases |

SwiftData is viable for production IF the patterns in this guide are followed. Most "SwiftData is broken" complaints trace to bad data modeling or missing abstractions, not framework bugs.

## Core Rules (Non-Negotiable)

These five rules prevent the most common crashes and data corruption. Violating any one is a critical-severity finding. For detailed code examples, consult `references/core-rules.md`.

### 1. @Model must be final class — never struct

`@Model struct` compiles but crashes at runtime or silently corrupts data. Always use `@Model final class` (omit `final` only for class inheritance on iOS 26+).

### 2. Never pass @Model objects across actor boundaries

`ModelContainer` and `PersistentIdentifier` are `Sendable`. Everything else is not. Pass `persistentModelID`, re-fetch on the target context.

### 3. Always use repository pattern with DTOs

The single architectural decision that determines success or failure with SwiftData. Views never touch `@Model` directly — repositories return `Sendable` DTOs, accept `PersistentIdentifier` for mutations. See `references/core-rules.md` for the full pattern.

### 4. Version your schema from the first release

Every @Model class MUST appear in its `VersionedSchema.models` array. Missing models are silently dropped during migration — permanent data loss. See `references/migration.md`.

### 5. Call save() explicitly for critical data

Main context autosaves on runloop idle. Background contexts have `autosaveEnabled = false`. On macOS, closing a window can lose unsaved main context changes. Always call `try context.save()` after mutations.

## Model Design Quick Reference

| Macro/Pattern | Purpose | Notes |
|---------------|---------|-------|
| `@Attribute(.unique)` | Upsert on collision | Primitives only |
| `@Attribute(.externalStorage)` | External file for large data | Mandatory for images/audio data |
| `@Attribute(originalName:)` | Rename property, preserve data | Enables lightweight migration |
| `@Transient` | Not persisted | Must have default value. Cannot appear in predicates |
| `#Unique<T>([\.a, \.b])` | Compound uniqueness | iOS 18+ |
| `#Index<T>([\.a], [\.b])` | Compound/single indexes | iOS 18+. Index predicate/sort properties only |
| `.cascade` delete rule | Delete parent deletes children | Use for owned relationships |
| `.nullify` delete rule | Sets child reference to nil | Default. Crashes if child property is non-optional |

For relationship initialization, enum workarounds, binary data patterns, and Codable struct hazards, consult `references/model-patterns.md`.

## Predicate Safety Summary

**Safe in #Predicate:** String operations (`localizedStandardContains`, `starts(with:)`), numeric/date comparisons, relationship traversal (`$0.album?.title`), Bool checks, nil checks, compound conditions.

**Compiles but CRASHES:** Enum properties (even RawRepresentable), `@Transient` properties, computed properties, generic predicates (Release builds only), optional to-many relationships, contents of value-type arrays (`[String]`), sub-properties of Codable structs.

For the full safe/crash pattern catalog and dynamic `@Query` patterns, consult `references/predicates-and-queries.md`.

## Concurrency (Swift 6 Strict)

Use `@ModelActor` for background work. Create with `Task.detached` to avoid running on main thread. Communicate across actors via `PersistentIdentifier` and `Sendable` DTOs only. For detailed patterns and gotchas, consult `references/concurrency.md`.

## Performance Essentials

- **N+1 prevention:** Use `relationshipKeyPathsForPrefetching` on FetchDescriptor
- **Batch operations:** Chunk inserts into batches of 500-1000, save each chunk
- **Indexing:** 2-3 indexes per model on queried/sorted properties. Each index slows writes
- **Prefer FetchDescriptor over @Query** for non-trivial work (fetchLimit, fetchOffset, propertiesToFetch, error handling)
- **Profiling:** `-com.apple.CoreData.SQLDebug 3` for EXPLAIN QUERY PLAN

For complete performance patterns, batch operation code, and profiling techniques, consult `references/performance.md`.

## Schema Migration

Lightweight migration handles: adding optional properties, removing properties, renaming with `@Attribute(originalName:)`, adding new models. Custom migration required for: type changes, non-optional without defaults, data transformations, deduplication.

Critical migration rules:
1. Data access goes in `willMigrate`, NOT `didMigrate`
2. Every @Model class must appear in its VersionedSchema.models array
3. Non-optional Codable properties block ALL future migrations (confirmed bug FB22151570)
4. Do NOT specify a SchemaMigrationPlan if implicit lightweight migration would suffice
5. Test migrations on real on-disk stores, not in-memory configurations

For complete migration patterns (including two-stage migration for type changes, many-to-many migration, junction table metadata, and deduplication), consult `references/migration.md`.

## Migration Diagnostics

When a migration fails, crashes, or loses data:

| Error Message | Likely Cause | Fix |
|---------------|-------------|-----|
| "Expected only Arrays for Relationships" | Many-to-many inverse missing | Add `@Relationship(inverse:)` |
| "incompatible model" / crash on launch | Schema version mismatch | Verify migration plan schemas array |
| "Failed to fulfill faulting for..." | Relationship integrity broken | Prefetch relationships during migration |
| Data gone after migration | Used didMigrate for old models | Move data access to willMigrate |
| Simulator works, device crashes | Simulator deletes DB on rebuild | Test on real device with real data |

For the complete diagnostic decision tree, step-by-step debugging protocol, verification checklists, and escalation procedures, consult `references/migration-diagnostics.md`.

## CloudKit Integration

SwiftData supports automatic CloudKit sync to private databases. All properties must be optional or have default values. All relationships must be optional. SwiftData uses last-write-wins conflict resolution by default. For full CloudKit patterns, constraints, sync status monitoring, and tvOS considerations, consult `references/cloudkit.md`.

## Audit Checklist

When reviewing SwiftData code, check in order of severity. Calculate risk: CRITICAL x 3 + HIGH x 2 + MEDIUM x 1 (cap at 10).

**CRITICAL (crash or data loss):** `@Model struct`, missing models in VersionedSchema, array relationship without `= []`, fetch in `didMigrate`, enum in `#Predicate`

**HIGH (data races, silent corruption):** Background Task using @Environment modelContext, missing save() in background contexts, updating both sides of inverse relationship, passing @Model across actor boundary, relationship assignment inside init()

**MEDIUM (performance):** N+1 relationship access in loops, 5+ indexes on one model, bulk insert without chunking, @Query with >1000 results, large Data without .externalStorage

For the full audit table with detection patterns, fixes, false positives, and risk scoring, consult `references/audit-checklist.md`.

## Known Bugs by iOS Version

- **iOS 17.0-17.1:** Avoid if possible. Enum predicate crashes, broken didSave/willSave, @ModelActor mutations don't trigger @Query updates
- **iOS 17.2+:** Minimum recommended target. Optional predicate chains still unreliable
- **iOS 18.0:** Major refactoring broke some iOS 17 patterns. Releasing @ModelActor destroys fetched instances. `#Expression` macro added
- **iOS 18.x+:** `#Index` and `#Unique` macros. Multi-store support
- **Xcode 26 / iOS 26:** Model inheritance. Backported to iOS 17: @ModelActor triggers @Query updates, Codable in predicates

For the full active bugs list and version-specific details, consult `references/known-bugs.md`.

## Testing

Use in-memory `ModelConfiguration` for unit tests. Tests cannot run in parallel — use `@MainActor` on test classes. For preview support, inject mock repositories via Environment. For testing patterns, consult `references/testing.md`.

## Additional Resources

### Reference Files

All detailed content lives in `references/`:

- **`references/core-rules.md`** — Detailed code for the 5 non-negotiable rules, repository pattern, DTO pattern
- **`references/model-patterns.md`** — Relationships, enums, properties, binary data, Codable hazards, class inheritance
- **`references/concurrency.md`** — @ModelActor, cross-actor communication, Swift 6 patterns
- **`references/predicates-and-queries.md`** — Safe/crash predicate patterns, dynamic @Query, FetchDescriptor
- **`references/performance.md`** — N+1, batch ops, indexing, profiling, memory optimization
- **`references/migration.md`** — VersionedSchema, migration plans, two-stage migration, many-to-many, deduplication
- **`references/migration-diagnostics.md`** — Diagnostic decision tree, error-to-fix mapping, verification, escalation
- **`references/cloudkit.md`** — CloudKit sync, constraints, conflict resolution, tvOS, sharing
- **`references/audit-checklist.md`** — Full audit tables with detection patterns and risk scoring
- **`references/known-bugs.md`** — iOS version bugs, active bugs, workarounds
- **`references/testing.md`** — Test setup, repository mocking, migration testing on real devices

### WWDC References

- **2023-10187**: Meet SwiftData
- **2023-10195**: Model your schema with SwiftData
- **2023-10196**: Dive deeper into SwiftData
- **2023-10154**: Build an app with SwiftData
- **2024-10137**: What's new in SwiftData
- **2025-10138**: SwiftData updates (model inheritance, backports)

### Community Resources

- fatbobman.com — Most thorough SwiftData analysis
- blog.jacobstechtavern.com — Performance profiling
- pado.name — "@Query Considered Harmful" (repository pattern motivation)
- wadetregaskis.com — Comprehensive pitfalls catalog
- donnywals.com — Migration deep dives
- pointfree.co — SQLiteData as alternative
