# CloudKit Integration

## Enable CloudKit Sync

```swift
let schema = Schema([Track.self])
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .private("iCloud.com.example.MusicApp")
)
let container = try ModelContainer(for: schema, configurations: config)
```

### Capabilities Required

1. Enable iCloud in Xcode (Signing & Capabilities)
2. Select CloudKit
3. Add iCloud container: `iCloud.com.example.MusicApp`

SwiftData CloudKit sync is automatic — no manual conflict resolution needed. Uses last-write-wins by default.

## CloudKit Constraints (CRITICAL)

All properties must be optional or have default values. All relationships must be optional.

```swift
@Model final class Track {
    @Attribute(.unique) var id: String = UUID().uuidString  // Has default
    var title: String = ""  // Has default
    var duration: TimeInterval = 0  // Has default
    var genre: String? = nil  // Optional

    // WRONG for CloudKit:
    // var requiredField: String  // No default, not optional

    @Relationship(deleteRule: .cascade, inverse: \Album.tracks)
    var album: Album?  // Must be optional for CloudKit
}
```

**Why:** CloudKit only syncs to private zones, and network delays mean new records may not have all fields populated yet.

## Resolving "Property must be optional or have default value" Error

This error occurs when trying to use CloudKit sync with non-optional, no-default properties. Add default values or make properties optional.

## Testing CloudKit Sync

```swift
// Test without CloudKit (in-memory)
let testConfig = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: schema, configurations: testConfig)
```

For real CloudKit testing:
1. Sign in to iCloud on test device
2. Enable CloudKit in Capabilities
3. Use real device (simulator CloudKit is unreliable)
4. Check iCloud status in Settings > [Your Name] > iCloud

## CloudKit Sync Recovery (Corrupted Relationships)

If CloudKit sync creates duplicate/orphaned relationships:

```swift
// 1. Backup current state
let backup = user.following.map { $0.id }

// 2. Clear relationships
user.following.removeAll()
user.followers.removeAll()
try modelContext.save()

// 3. Rebuild from source of truth
for followingId in backup {
    if let followingUser = fetchUser(id: followingId) {
        user.following.append(followingUser)
    }
}
try modelContext.save()
```

## tvOS Considerations

SwiftData on tvOS has no persistent local storage. tvOS has no Document directory, and Application Support maps to Caches — the system deletes files under storage pressure.

**CloudKit sync is mandatory** (`cloudKitDatabase: .private(...)`) for tvOS SwiftData apps. Without iCloud, user data does not survive between app launches.

## SwiftData CloudKit Limitations

- Only supports **private** CloudKit databases
- CKShare-based record sharing is NOT supported — use SQLiteData or Core Data for shared databases
- Conflict resolution is last-write-wins only (no custom resolution without lower-level APIs)

## History Tracking (iOS 26+)

```swift
let config = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .private("iCloud.com.example.app"),
    allowsSave: true,
    isHistoryEnabled: true  // iOS 26+
)
```
