# Performance Patterns

## Preventing N+1 Queries

```swift
// SLOW: 1 + N queries (N = number of tracks)
let tracks = try context.fetch(FetchDescriptor<Track>())
for track in tracks {
    print(track.album?.title)  // Each access fires a separate SQL query
}

// FAST: 2 queries total
var descriptor = FetchDescriptor<Track>()
descriptor.relationshipKeyPathsForPrefetching = [\.album]
let tracks = try context.fetch(descriptor)
for track in tracks {
    print(track.album?.title)  // Already in memory
}
```

Performance impact:
- Without prefetching: 1 + N + N queries (tracks + folders + tags)
- With prefetching: 3 queries total (1 per entity type)

## Batch Operations

```swift
@ModelActor
actor BulkOperator {
    // Batch insert with chunking
    func insertTracks(_ dtos: [TrackDTO]) throws {
        let chunkSize = 1000
        for chunk in stride(from: 0, to: dtos.count, by: chunkSize) {
            let end = min(chunk + chunkSize, dtos.count)
            for dto in dtos[chunk..<end] {
                modelContext.insert(Track(from: dto))
            }
            try modelContext.save()
        }
    }

    // Batch delete (native)
    func deleteAllTracks(olderThan date: Date) throws {
        try modelContext.delete(
            model: Track.self,
            where: #Predicate { $0.createdAt < date }
        )
        try modelContext.save()
    }
}
```

### Single Save for Batch Updates

```swift
// SLOW: 1000 individual saves
for track in largeDataset {
    track.genre = "Updated"
    try modelContext.save()  // Expensive — 1000 times
}

// FAST: Single save operation
for track in largeDataset {
    track.genre = "Updated"
}
try modelContext.save()  // Once for entire batch
```

## Memory Optimization: Fetch Chunks

For very large datasets (100k+ records):

```swift
actor DataImporter {
    let modelContainer: ModelContainer

    func importLargeDataset(_ items: [Item]) async throws {
        let chunkSize = 1000
        let context = ModelContext(modelContainer)

        for chunk in items.chunked(into: chunkSize) {
            for item in chunk {
                context.insert(Track(id: item.id, title: item.title, artist: item.artist, duration: item.duration))
            }
            try context.save()  // Save after each chunk
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

## Batch Fetching with Pagination

```swift
let descriptor = FetchDescriptor<Track>(sortBy: [SortDescriptor(\.title)])
descriptor.fetchLimit = 100    // Page size
descriptor.fetchOffset = page * 100  // Skip previous pages

let tracks = try modelContext.fetch(descriptor)
```

## Indexing Strategy

```swift
@Model final class MediaItem {
    // Index properties used in predicates and sort descriptors
    // 2-3 indexes per model is typical — each index slows writes
    #Index<MediaItem>([\.title], [\.mediaTypeRaw], [\.createdAt])

    var title: String
    var mediaTypeRaw: String
    var createdAt: Date
    // ... other properties (NOT indexed unless queried/sorted)
}
```

### When to Add Indexes

- Properties used in `@Query` filters frequently
- Properties used in sort operations
- Properties used in relationship lookups
- NOT properties that are rarely filtered
- NOT properties that change frequently (maintenance cost)

## Faulting (Lazy Loading)

SwiftData uses faulting by default — relationships load on access.

- Good when accessing relationships in only 10-20% of cases
- Good for large relationship graphs partially used
- Bad when accessing relationships in loops — use prefetching instead

## Profiling

Launch arguments for debugging (Scheme > Run > Arguments):
- `-com.apple.CoreData.SQLDebug 1` — log SQL queries (levels 1-4)
- `-com.apple.CoreData.SQLDebug 3` — includes EXPLAIN QUERY PLAN
- `-com.apple.CoreData.ConcurrencyDebug 1` — crash on thread violations

Instruments: use the Data Persistence instrument for faults, fetches, saves, cache misses. Use the SwiftUI instrument to track @Query-triggered view re-renders.
