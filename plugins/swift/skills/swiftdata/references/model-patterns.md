# Model Design Patterns

## Relationships: Initialization, Ordering, and Delete Rules

```swift
@Model final class Album {
    var title: String

    // Always: explicit inverse, explicit delete rule, default empty array
    @Relationship(deleteRule: .cascade, inverse: \Track.album)
    var tracks: [Track] = []

    // Ordering: SwiftData does NOT preserve array order — add explicit sort property
    // Use: album.tracks.sorted(by: { $0.trackNumber < $1.trackNumber })

    init(title: String) {
        self.title = title
        // Do NOT assign relationship properties in init — foreign keys stay NULL
    }
}

@Model final class Track {
    var title: String
    var trackNumber: Int  // Explicit ordering property
    var album: Album?     // Inverse side — always optional

    init(title: String, trackNumber: Int) {
        self.title = title
        self.trackNumber = trackNumber
    }
}

// After inserting into context, THEN set relationships:
context.insert(album)
context.insert(track)
track.album = album  // Only set ONE side — SwiftData handles the inverse
```

### Delete Rules Reference

- `.cascade` — delete parent deletes children (use for owned relationships)
- `.nullify` — delete parent sets child reference to nil (default, crashes if child property is non-optional)
- `.deny` — prevents deletion if children exist
- `.noAction` — leaves orphaned records (almost never correct)

### Many-to-Many Self-Referential Relationships

```swift
@MainActor
@Model
final class User {
    @Attribute(.unique) var id: String
    var name: String

    @Relationship(deleteRule: .nullify, inverse: \User.following)
    var followers: [User] = []

    @Relationship(deleteRule: .nullify)
    var following: [User] = []

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
```

SwiftData automatically manages BOTH sides when ONE side is modified. Only modify ONE side — modifying both causes duplicates (especially with CloudKit sync).

```swift
// CORRECT — modify ONE side only
user1.following.append(user2)
try modelContext.save()
// SwiftData AUTOMATICALLY updates user2.followers

// WRONG — creates duplicates
user1.following.append(user2)
user2.followers.append(user1)  // Redundant!
```

## Enum Properties: The rawValue Workaround

Enum-typed properties crash in `#Predicate` even when RawRepresentable. Store the raw value:

```swift
enum MediaType: String, Codable { case audio, video, image, unknown }

@Model final class MediaItem {
    var title: String
    var mediaTypeRaw: String  // Use this in predicates

    // Computed property for type-safe access — NOT persisted, NOT queryable
    var mediaType: MediaType {
        get { MediaType(rawValue: mediaTypeRaw) ?? .unknown }
        set { mediaTypeRaw = newValue.rawValue }
    }

    init(title: String, mediaType: MediaType) {
        self.title = title
        self.mediaTypeRaw = mediaType.rawValue
    }
}

// Predicate uses raw string
#Predicate<MediaItem> { $0.mediaTypeRaw == "audio" }

// CRASH — enum in predicate compiles but crashes at runtime
#Predicate<MediaItem> { $0.mediaType == .audio }
```

## Property Attributes Reference

| Macro | Purpose | Notes |
|-------|---------|-------|
| `@Attribute(.unique)` | Upsert on collision | Primitives only |
| `@Attribute(.externalStorage)` | External file for large data | Mandatory for images/audio data |
| `@Attribute(originalName:)` | Map renamed property to old column | Enables lightweight migration on rename |
| `@Attribute(.preserveValueOnDeletion)` | Values survive after object deleted | Useful for analytics, audit trails |
| `@Transient` | Not persisted | Must have default value. Cannot appear in predicates (compiles, crashes) |
| `#Unique<T>([\.a, \.b])` | Compound uniqueness (iOS 18+) | |
| `#Index<T>([\.a], [\.b])` | Compound/single indexes (iOS 18+) | Index predicate/sort properties only. 2-3 per model typical |

## Binary Data: Filesystem, Not Database

Store metadata in SwiftData, store files on disk:

```swift
@Model final class MediaAsset {
    var filename: String
    var fileSize: Int64
    var mimeType: String

    // Store path reference — actual file on filesystem
    var relativePath: String

    // For thumbnails only (small), use external storage
    @Attribute(.externalStorage) var thumbnail: Data?

    // NEVER store large binary data as a regular property
    // var fileData: Data  // This bloats the SQLite DB catastrophically
}
```

## Codable Struct Properties: Migration Hazard

SwiftData destructures Codable structs into separate SQLite columns. Changing the struct definition breaks lightweight migration:

```swift
// V1: stored as columns title_text, title_locale
struct LocalizedTitle: Codable { var text: String; var locale: String }

// V2: adding a field BREAKS lightweight migration — requires custom migration
struct LocalizedTitle: Codable { var text: String; var locale: String; var isDefault: Bool }
```

Always make Codable properties optional with nil defaults to avoid blocking future migrations entirely.

## Class Inheritance (iOS 26+)

Apply `@Model` to both base class and subclasses. Omit `final` on the base class.

```swift
@Model class Trip {
    @Attribute(.preserveValueOnDeletion) var name: String
    var destination: String
    var startDate: Date
    var endDate: Date

    init(name: String, destination: String, startDate: Date, endDate: Date) {
        self.name = name; self.destination = destination
        self.startDate = startDate; self.endDate = endDate
    }
}

@Model class BusinessTrip: Trip {
    var purpose: String
    var expenseCode: String

    @Relationship(deleteRule: .cascade, inverse: \BusinessMeal.trip)
    var businessMeals: [BusinessMeal] = []

    init(name: String, destination: String, startDate: Date, endDate: Date,
         purpose: String, expenseCode: String) {
        self.purpose = purpose
        self.expenseCode = expenseCode
        super.init(name: name, destination: destination, startDate: startDate, endDate: endDate)
    }
}
```

### Type-Based Queries with #Predicate

```swift
// All trips (includes subclasses)
@Query(sort: \Trip.startDate) var allTrips: [Trip]

// Only business trips
@Query(filter: #Predicate<Trip> { $0 is BusinessTrip }) var businessTrips: [Trip]

// Filter on subclass-specific properties
let vacationPredicate = #Predicate<Trip> {
    if let personal = $0 as? PersonalTrip {
        return personal.reason == .vacation
    }
    return false
}
```

### When to Use Inheritance vs Alternatives

| Signal | Use Inheritance | Use Enum/Flag Instead |
|--------|----------------|----------------------|
| Subclasses share many base properties | Yes | -- |
| Need type-based queries across all models | Yes | -- |
| Subclasses have their own relationships | Yes | -- |
| Only 1-2 distinguishing properties | -- | Yes |
| Protocol conformance suffices | -- | Yes |

Keep hierarchies shallow (1-2 levels). Deep chains complicate migrations and queries.
