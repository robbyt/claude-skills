# Concurrency Patterns (Swift 6 Strict)

## @ModelActor for Background Work

```swift
@ModelActor
actor TrackImporter {
    func importBatch(_ dtos: [TrackDTO]) throws -> Int {
        let batchSize = 1000
        var imported = 0
        for batch in stride(from: 0, to: dtos.count, by: batchSize) {
            let end = min(batch + batchSize, dtos.count)
            for dto in dtos[batch..<end] {
                modelContext.insert(Track(from: dto))
            }
            try modelContext.save()
            imported += (end - batch)
        }
        return imported
    }
}
```

## @ModelActor Creation Context Matters

If created on MainActor, it runs on the main thread:

```swift
// CORRECT — runs on background cooperative pool
let importer = await Task.detached {
    TrackImporter(modelContainer: container)
}.value

// WRONG — created on MainActor, runs on main thread despite being an actor
@MainActor func startImport() {
    let importer = TrackImporter(modelContainer: container)  // Main thread!
}
```

## Alternative: Manual Background Context

```swift
actor DataImporter {
    let modelContainer: ModelContainer

    init(container: ModelContainer) {
        self.modelContainer = container
    }

    func importTracks(_ tracks: [TrackData]) async throws {
        let context = ModelContext(modelContainer)
        for track in tracks {
            context.insert(Track(id: track.id, title: track.title, artist: track.artist, duration: track.duration))
        }
        try context.save()
    }
}
```

Use `ModelContext(modelContainer)` for background operations, not `@Environment(\.modelContext)` which is main-actor bound.

## Cross-Actor Communication via PersistentIdentifier

```swift
@ModelActor
actor BackgroundProcessor {
    func processAlbum(_ albumID: PersistentIdentifier) throws -> AlbumDTO {
        guard let album = modelContext.model(for: albumID) as? Album else {
            throw ProcessingError.notFound
        }
        album.lastProcessed = Date()
        try modelContext.save()
        return AlbumDTO(album)  // Return Sendable DTO, not @Model
    }
}

// On MainActor:
let dto = try await processor.processAlbum(album.persistentModelID)
// Update UI with dto — never with the @Model object
```

## @MainActor Isolation for Models

```swift
@MainActor
@Model
final class Track {
    var id: String
    var title: String

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
```

SwiftData models are not `Sendable`. Use `@MainActor` to ensure safe access from SwiftUI views.

## Calling Background Work from SwiftUI

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button("Import") {
            Task {
                let importer = DataImporter(container: modelContext.container)
                try await importer.importTracks(data)
            }
        }
    }
}
```

## Avoiding Retain Cycles in Background Tasks

```swift
// WRONG — potential retain cycle
actor TrackManager {
    func startSync() {
        Task {
            for await notification in NotificationCenter.default
                .notifications(named: .init("CloudKitSyncDidComplete")) {
                self.refreshUI()
            }
        }
    }
}

// CORRECT — weak capture
actor TrackManager {
    func startSync() {
        Task { [weak self] in
            guard let self else { return }
            for await notification in NotificationCenter.default
                .notifications(named: .init("CloudKitSyncDidComplete")) {
                await self.refreshUI()
            }
        }
    }
}
```
