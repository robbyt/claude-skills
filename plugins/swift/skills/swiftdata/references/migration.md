# Schema Migration

## Migration Plan Structure

```swift
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [Album.self, Track.self]
    @Model final class Album { var title: String; init(title: String) { self.title = title } }
    @Model final class Track { var title: String; init(title: String) { self.title = title } }
}

enum AppSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [Album.self, Track.self, MediaItem.self]
    @Model final class Album {
        var title: String
        @Attribute(originalName: "name") var artistName: String  // Renamed
        init(title: String, artistName: String) { self.title = title; self.artistName = artistName }
    }
    @Model final class Track { var title: String; init(title: String) { self.title = title } }
    @Model final class MediaItem { var path: String; init(path: String) { self.path = path } }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [AppSchemaV1.self, AppSchemaV2.self]
    static var stages: [MigrationStage] = [migrateV1toV2]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV2.self
    )
}
```

Each VersionedSchema is a complete snapshot — include ALL models, even unchanged ones.

## Lightweight Migration Handles

- Adding optional properties (or with defaults)
- Removing properties
- Renaming with `@Attribute(originalName:)`
- Adding new model types
- Changing relationship delete rules

## Custom Migration Required For

- Adding non-optional properties without defaults
- Type changes (String to AttributedString, Int to String, etc.)
- Data transformations / backfilling
- Deduplication when adding unique constraints
- Complex relationship restructuring

## The willMigrate / didMigrate Limitation

This is the architectural constraint that shapes all migration strategies.

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self,
    toVersion: SchemaV2.self,
    willMigrate: { context in
        // CAN access: SchemaV1 models (old)
        let v1Notes = try context.fetch(FetchDescriptor<SchemaV1.Note>())
        // CANNOT access: SchemaV2 models (don't exist yet)
    },
    didMigrate: { context in
        // CAN access: SchemaV2 models (new)
        let v2Notes = try context.fetch(FetchDescriptor<SchemaV2.Note>())
        // CANNOT access: SchemaV1 models (gone)
    }
)
```

Both old and new types cannot be accessed simultaneously. Use two-stage migration for type changes.

## Two-Stage Migration Pattern (Type Changes)

Use an intermediate schema version (V1.1) that has BOTH old and new properties:

```swift
// V1.1: Add new property alongside old
enum NotesSchemaV1_1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] { [Note.self, Folder.self, Tag.self] }

    @Model final class Note {
        @Attribute(.unique) var id: String
        var title: String
        @Attribute(originalName: "content") var contentOld: String = ""  // OLD
        var contentNew: AttributedString?  // NEW
        var createdAt: Date

        @Relationship(deleteRule: .nullify, inverse: \Folder.notes) var folder: Folder?
        @Relationship(deleteRule: .nullify, inverse: \Tag.notes) var tags: [Tag] = []

        init(id: String, title: String, contentOld: String, createdAt: Date) {
            self.id = id; self.title = title; self.contentOld = contentOld; self.createdAt = createdAt
        }
    }
    @Model final class Folder { /* same as V1 */ }
    @Model final class Tag { /* same as V1 */ }
}

// V2: Final schema with new type, old property removed
enum NotesSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Note.self, Folder.self, Tag.self] }

    @Model final class Note {
        @Attribute(.unique) var id: String
        var title: String
        @Attribute(originalName: "contentNew") var content: AttributedString?  // Renamed from contentNew
        var createdAt: Date

        @Relationship(deleteRule: .nullify, inverse: \Folder.notes) var folder: Folder?
        @Relationship(deleteRule: .nullify, inverse: \Tag.notes) var tags: [Tag] = []

        init(id: String, title: String, content: AttributedString?, createdAt: Date) {
            self.id = id; self.title = title; self.content = content; self.createdAt = createdAt
        }
    }
    @Model final class Folder { /* same as V1 */ }
    @Model final class Tag { /* same as V1 */ }
}
```

Migration plan:

```swift
enum NotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [NotesSchemaV1.self, NotesSchemaV1_1.self, NotesSchemaV2.self]
    }
    static var stages: [MigrationStage] { [migrateV1toV1_1, migrateV1_1toV2] }

    // Stage 1: Lightweight (adds contentNew)
    static let migrateV1toV1_1 = MigrationStage.lightweight(
        fromVersion: NotesSchemaV1.self, toVersion: NotesSchemaV1_1.self
    )

    // Stage 2: Custom (transform String to AttributedString)
    static let migrateV1_1toV2 = MigrationStage.custom(
        fromVersion: NotesSchemaV1_1.self, toVersion: NotesSchemaV2.self,
        willMigrate: { context in
            var fetchDesc = FetchDescriptor<NotesSchemaV1_1.Note>()
            fetchDesc.relationshipKeyPathsForPrefetching = [\.folder, \.tags]
            let notes = try context.fetch(fetchDesc)
            for note in notes {
                note.contentNew = try? AttributedString(markdown: note.contentOld)
            }
            try context.save()
        },
        didMigrate: nil
    )
}
```

## Many-to-Many Relationship Migration

Many-to-many relationships require explicit inverse declarations on both sides with `= []` defaults.

### iOS 17.0 Alphabetical Bug

In iOS 17.0, many-to-many could fail if model names were in alphabetical order. Always provide default values for relationship arrays. Fixed in iOS 17.1+.

### Junction Table Metadata

For additional fields on many-to-many (e.g., "when was this tag added?"), use an explicit junction model:

```swift
@Model final class NoteTag {
    @Attribute(.unique) var id: String
    var addedAt: Date
    @Relationship(deleteRule: .cascade) var note: Note?
    @Relationship(deleteRule: .cascade) var tag: Tag?

    init(id: String, note: Note, tag: Tag, addedAt: Date) {
        self.id = id; self.note = note; self.tag = tag; self.addedAt = addedAt
    }
}
```

## Deduplication for Unique Constraints

When adding `@Attribute(.unique)` to a field with existing duplicates:

```swift
static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: SchemaV1.self, toVersion: SchemaV2.self,
    willMigrate: { context in
        let trips = try context.fetch(FetchDescriptor<SchemaV1.Trip>())
        var seenNames = Set<String>()
        for trip in trips {
            if seenNames.contains(trip.name) {
                context.delete(trip)
            } else {
                seenNames.insert(trip.name)
            }
        }
        try context.save()
    },
    didMigrate: nil
)
```

## Relationship Prefetching During Migration

Prefetch relationships to avoid N+1 queries during data transformation:

```swift
willMigrate: { context in
    var fetchDesc = FetchDescriptor<SchemaV1.Note>()
    fetchDesc.relationshipKeyPathsForPrefetching = [\.folder, \.tags]
    fetchDesc.propertiesToFetch = [\.title, \.content]  // iOS 26+
    let notes = try context.fetch(fetchDesc)
    // Relationships already loaded — no N+1
}
```

## Critical Migration Rules

1. **Data access goes in `willMigrate`, NOT `didMigrate`.** `willMigrate` runs before schema changes (old schema available). `didMigrate` runs after (old data inaccessible).
2. **Every @Model class must appear in its VersionedSchema.models array.** Missing models are silently dropped — permanent data loss.
3. **Non-optional Codable properties block ALL future migrations** (confirmed bug FB22151570). Always make Codable properties optional.
4. **Do NOT specify a SchemaMigrationPlan if implicit lightweight migration would suffice.** Providing one when unnecessary causes migration failure (confirmed bug).
5. **Test migrations on real on-disk stores**, not in-memory configurations.

## Decision Tree: Lightweight vs Custom

```
What change are you making?
+-- Adding optional property              --> Lightweight
+-- Adding required property with default  --> Lightweight
+-- Renaming property (with originalName)  --> Lightweight
+-- Removing property                      --> Lightweight
+-- Changing relationship delete rule      --> Lightweight
+-- Adding new model                       --> Lightweight
+-- Changing property type                 --> Custom (two-stage)
+-- Making optional --> required           --> Custom (populate nulls)
+-- Adding unique constraint (dupes exist) --> Custom (deduplicate)
+-- Complex relationship restructure       --> Custom
```

## Container Setup with Migration

```swift
@main struct MyApp: App {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false, allowsSave: true)
            container = try ModelContainer(
                for: Schema([Album.self, Track.self, MediaItem.self]),
                configurations: config,
                migrationPlan: AppMigrationPlan.self
            )
        } catch {
            fatalError("ModelContainer creation failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(container)
    }
}
```

Only register root/parent model types — SwiftData auto-discovers related types through relationships. `ModelContainer` is `Sendable` — share freely across actors.
