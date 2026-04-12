# Core Rules — Detailed Code Examples

## Rule 1: @Model must be final class

```swift
// CORRECT
@Model final class Track {
    var title: String
    init(title: String) { self.title = title }
}

// CRASH — compiles but crashes at runtime or silently corrupts data
@Model struct Track { ... }
```

Omit `final` only when using class inheritance (iOS 26+).

## Rule 2: Never pass @Model objects across actor boundaries

`ModelContainer` and `PersistentIdentifier` are `Sendable`. Everything else is not.

```swift
// CORRECT — pass identifier, re-fetch on target context
let id = track.persistentModelID  // Sendable
await backgroundActor.process(id)

// DATA RACE — @Model is not Sendable
await backgroundActor.process(track)
```

## Rule 3: Repository pattern with DTOs

This is the single architectural decision that determines success or failure with SwiftData.

### DTO Definition

```swift
struct TrackDTO: Sendable, Identifiable {
    let id: PersistentIdentifier
    let title: String
    let trackNumber: Int
    let albumTitle: String?

    init(_ track: Track) {
        self.id = track.persistentModelID
        self.title = track.title
        self.trackNumber = track.trackNumber
        self.albumTitle = track.album?.title
    }
}
```

### Repository Protocol

```swift
@MainActor
protocol TrackRepository {
    func fetchTracks(matching: String?, limit: Int) throws -> [TrackDTO]
    func deleteTrack(id: PersistentIdentifier) throws
}
```

### SwiftData Implementation

```swift
@MainActor
final class SwiftDataTrackRepository: TrackRepository {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) { self.container = container }

    func fetchTracks(matching search: String?, limit: Int) throws -> [TrackDTO] {
        var descriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.trackNumber)])
        descriptor.fetchLimit = limit
        if let search {
            descriptor.predicate = #Predicate { $0.title.localizedStandardContains(search) }
        }
        return try context.fetch(descriptor).map(TrackDTO.init)
    }

    func deleteTrack(id: PersistentIdentifier) throws {
        guard let track = context.model(for: id) as? Track else { return }
        context.delete(track)
        try context.save()
    }
}
```

### Mock for Tests and Previews

```swift
@MainActor
final class MockTrackRepository: TrackRepository {
    var tracks: [TrackDTO] = []
    func fetchTracks(matching: String?, limit: Int) throws -> [TrackDTO] { tracks }
    func deleteTrack(id: PersistentIdentifier) throws {}
}
```

## Rule 4: Version schema from the first release

```swift
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [Album.self, Track.self]

    @Model final class Album { /* V1 shape */ }
    @Model final class Track { /* V1 shape */ }
}

// Current version — typealias for convenience
typealias Album = AppSchemaV1.Album
typealias Track = AppSchemaV1.Track

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [AppSchemaV1.self]
    static var stages: [MigrationStage] = []
}
```

Every @Model class MUST appear in the `models` array. Missing models are silently dropped during migration — permanent data loss.

## Rule 5: Call save() explicitly

Main context autosaves on runloop idle. Background contexts have `autosaveEnabled = false`. On macOS, closing a window can lose unsaved main context changes.

```swift
// Always explicit save after mutations
context.insert(track)
try context.save()

// Background contexts MUST save explicitly
@ModelActor
actor DataImporter {
    func importTracks(_ dtos: [TrackDTO]) throws {
        for dto in dtos {
            modelContext.insert(Track(from: dto))
        }
        try modelContext.save()  // Required — no autosave
    }
}
```
