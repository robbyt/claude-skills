# Migration Diagnostics

90% of migration failures stem from missing models in VersionedSchema, relationship inverse issues, or untested migration paths — not SwiftData bugs.

## Red Flags — Suspect Migration Issue

- App crashes on launch after schema change
- "Expected only Arrays for Relationships" error
- "The model used to open the store is incompatible with the one used to create the store"
- "Failed to fulfill faulting for [relationship]"
- Migration works in simulator but crashes on real device
- Data exists before migration, gone after
- Relationships broken after migration (nil where they shouldn't be)

**FORBIDDEN reasoning:** "SwiftData migrations are broken, we should use Core Data." SwiftData handles millions of migrations in production. Schema mismatches and relationship errors are always configuration, not framework.

## Mandatory First Steps (Before Changing Code)

### Step 1: Identify the crash type

| Error Message | Root Cause |
|---------------|-----------|
| "Expected only Arrays for Relationships" | Many-to-many inverse missing |
| "incompatible model" / crash on launch | Schema version mismatch |
| "Failed to fulfill faulting for..." | Relationship integrity broken |
| Simulator works, device crashes | Untested migration path |
| Data gone after migration | willMigrate/didMigrate misuse |

### Step 2: Check schema version configuration

```swift
enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        // VERIFY: All versions in order?
        // VERIFY: Latest version matches container?
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }
    static var stages: [MigrationStage] {
        // VERIFY: Migration stages match schema transitions?
        [migrateV1toV2, migrateV2toV3]
    }
}

// In your app:
let schema = Schema(versionedSchema: SchemaV3.self)  // VERIFY: Matches latest in plan?
let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self)
```

### Step 3: Check all models included in VersionedSchema

Every @Model class must appear in models array — even unchanged ones.

### Step 4: Check relationship inverse declarations

All many-to-many relationships need explicit `@Relationship(inverse:)` on both sides.

### Step 5: Enable debug logging

Add launch argument: `-com.apple.coredata.swiftdata.debug 1`

## Decision Tree

```
SwiftData migration problem suspected?
+-- Error: "Expected only Arrays for Relationships"?
|   +-- Many-to-many relationship? --> Fix: Add explicit inverse
|   +-- One-to-many relationship?  --> Fix: Verify both sides declared
|   +-- iOS 17.0?                  --> Fix: Add = [] default value
|
+-- Error: "incompatible model" or crash on launch?
|   +-- Latest schema not in plan?   --> Fix: Add to schemas array
|   +-- Migration stage missing?     --> Fix: Add stage
|   +-- Container using wrong schema --> Fix: Verify version
|
+-- Migration runs but data missing?
|   +-- Used didMigrate for old models? --> Fix: Use willMigrate
|   +-- Forgot to save in willMigrate?  --> Fix: Add context.save()
|   +-- Custom migration logic wrong?   --> Fix: Debug transformation
|
+-- Works in simulator, crashes on device?
|   +-- Never tested on real device?  --> Fix: Real device testing
|   +-- Never tested upgrade path?    --> Fix: Test v1 -> v2 upgrade
|   +-- Production data differs?      --> Fix: Test with prod data
|
+-- Relationships nil after migration?
    +-- Forgot to prefetch?   --> Fix: Add prefetching
    +-- Inverse wrong?        --> Fix: Fix inverse declaration
    +-- Delete rule cascade?  --> Fix: Check delete rules
```

## Verification Checklist (After Migration)

```swift
// 1. Verify record count
let postMigrationCount = try context.fetch(FetchDescriptor<Note>()).count
print("Post-migration count: \(postMigrationCount)")

// 2. Spot-check specific records
let sampleNote = try context.fetch(
    FetchDescriptor<Note>(predicate: #Predicate { $0.id == "known-test-id" })
).first
print("Sample note title: \(sampleNote?.title ?? "MISSING")")

// 3. Verify relationships intact
if let note = sampleNote {
    print("Folder relationship: \(note.folder != nil ? "OK" : "BROKEN")")
    print("Tags count: \(note.tags.count)")

    // Verify inverse
    if let folder = note.folder {
        let folderHasNote = folder.notes.contains { $0.id == note.id }
        print("Inverse relationship: \(folderHasNote ? "OK" : "BROKEN")")
    }
}

// 4. Check for orphaned data
let orphanedNotes = try context.fetch(
    FetchDescriptor<Note>(predicate: #Predicate { $0.folder == nil })
)
print("Orphaned notes: \(orphanedNotes.count)")
```

### What Success Looks Like

```
Post-migration count: 1523  // Matches pre-migration
Sample note title: Test Note  // Not "MISSING"
Folder relationship: OK
Tags count: 3
Inverse relationship: OK
Orphaned notes: 0
```

### What Failure Looks Like

- Record count differs: Data loss (check willMigrate logic)
- "MISSING" records: Schema mismatch or fetch error
- Relationships nil: Inverse configuration or prefetching issue
- Orphaned records >0: Cascade delete rule not working

## Common Error-to-Fix Reference

| Error | Fix | Time |
|-------|-----|------|
| "Expected only Arrays" | Add `@Relationship(inverse:)` | 2 min |
| "incompatible model" | Add missing version to schemas array | 2 min |
| "Failed to fulfill faulting" | Add `relationshipKeyPathsForPrefetching` | 5 min |
| Data loss in migration | Move data access to willMigrate | 5 min |
| Device crash after schema change | Test real device upgrade path | 30 min |

## Stuck After 30 Minutes

If diagnostics are contradictory or unclear:
1. Add `-com.apple.coredata.swiftdata.debug 1` and examine SQL output
2. Check file system: does .sqlite file exist? What size?
3. Establish baseline: what is actually happening vs what was assumed
4. Consider whether implicit lightweight migration would work (remove SchemaMigrationPlan)
