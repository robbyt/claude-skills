# Predicates and Queries

## Safe Predicate Patterns

```swift
// String operations
#Predicate<Track> { $0.title.localizedStandardContains(searchText) }
#Predicate<Track> { $0.title.starts(with: prefix) }
#Predicate<Track> { $0.title.contains("Love") }
#Predicate<Track> { $0.artist.hasPrefix("The ") }

// Numeric/date comparisons
#Predicate<Track> { $0.trackNumber > 5 && $0.duration < 300 }

// Relationship traversal
#Predicate<Track> { $0.album?.title == "Abbey Road" }
#Predicate<Album> { $0.tracks.count > 10 }

// Bool and nil checks on primitives
#Predicate<Track> { $0.isFavorite == true }
#Predicate<Track> { $0.lyrics != nil }

// Compound conditions
#Predicate<Track> { $0.title.contains(search) || $0.artistName.contains(search) }
```

## Patterns That Compile but CRASH at Runtime

```swift
// Enum properties (even RawRepresentable)
#Predicate<MediaItem> { $0.mediaType == .audio }

// @Transient properties
#Predicate<Track> { $0.computedDisplayName.contains("x") }

// Computed properties
#Predicate<Track> { $0.fullTitle.contains("x") }

// Generic predicates — crash in Release builds only (not Debug!)
func fetch<T: PersistentModel>(matching predicate: Predicate<T>) { ... }

// Optional to-many relationships
#Predicate<Album> { $0.tags?.count ?? 0 > 0 }  // tags: [Tag]?

// Contents of value-type arrays ([String], [Int]) — stored as binary blobs
#Predicate<Track> { $0.genres.contains("rock") }  // genres: [String]

// Sub-properties of Codable structs
#Predicate<Track> { $0.metadata.genre == "rock" }  // metadata: TrackMetadata (Codable)
```

## Dynamic Predicates with @Query

`@Query` predicates must be set in `init` — use the child view pattern:

```swift
struct FilteredTrackList: View {
    @Query private var tracks: [Track]

    init(searchText: String, albumID: PersistentIdentifier) {
        let search = searchText  // Capture to local — required
        _tracks = Query(
            filter: #Predicate<Track> {
                $0.album?.persistentModelID == albumID &&
                $0.title.localizedStandardContains(search)
            },
            sort: [SortDescriptor(\.trackNumber)]
        )
    }

    var body: some View {
        ForEach(tracks) { TrackRow(track: $0) }
    }
}
```

## Prefer FetchDescriptor over @Query for Non-Trivial Work

`@Query` runs on the main thread with no background option, no `propertiesToFetch`, no `relationshipKeyPathsForPrefetching`, and silently swallows fetch errors.

```swift
var descriptor = FetchDescriptor<Track>(
    predicate: #Predicate { $0.mediaTypeRaw == "audio" },
    sortBy: [SortDescriptor(\.title)]
)
descriptor.fetchLimit = 100
descriptor.fetchOffset = page * 100
descriptor.propertiesToFetch = [\.title, \.artistName, \.duration]
descriptor.relationshipKeyPathsForPrefetching = [\.album]
descriptor.includePendingChanges = false  // Skip unsaved changes for performance
```

## Basic @Query Patterns

```swift
// Filtered
@Query(filter: #Predicate<Track> { $0.genre == "Rock" }) var rockTracks: [Track]

// Sorted (single)
@Query(sort: \.title, order: .forward) var tracks: [Track]

// Sorted (multiple descriptors)
@Query(sort: [SortDescriptor(\.artist), SortDescriptor(\.title)]) var tracks: [Track]

// Combined filter + sort
@Query(filter: #Predicate<Track> { $0.duration > 180 }, sort: \.title) var longTracks: [Track]
```

## ModelContext CRUD Operations

```swift
// Insert
let track = Track(id: "1", title: "Song", artist: "Artist", duration: 240)
modelContext.insert(track)

// Fetch
let descriptor = FetchDescriptor<Track>(
    predicate: #Predicate { $0.genre == "Rock" },
    sortBy: [SortDescriptor(\.title)]
)
let rockTracks = try modelContext.fetch(descriptor)

// Update — just modify properties, SwiftData tracks changes
track.title = "Updated Title"

// Delete
modelContext.delete(track)

// Batch delete
try modelContext.delete(model: Track.self, where: #Predicate { $0.genre == "Classical" })

// Save
try modelContext.save()
```

## #Expression Macro (iOS 18+)

Composable predicate building for complex, reusable filter logic.
