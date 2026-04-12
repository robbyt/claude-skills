# Testing Patterns

## Unit Test Setup

```swift
@MainActor
final class TrackRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: SwiftDataTrackRepository!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Album.self, Track.self,
            configurations: config
        )
        repository = SwiftDataTrackRepository(container: container)
    }

    func testFetchFiltersCorrectly() throws {
        let context = container.mainContext
        let album = Album(title: "Test Album")
        context.insert(album)
        let track1 = Track(title: "Hello World", trackNumber: 1)
        track1.album = album
        context.insert(track1)
        let track2 = Track(title: "Goodbye", trackNumber: 2)
        track2.album = album
        context.insert(track2)
        try context.save()

        let results = try repository.fetchTracks(matching: "Hello", limit: 50)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Hello World")
    }
}
```

## Testing Rules

- In-memory SwiftData tests cannot run in parallel — use `@MainActor` on test classes
- For preview support, inject `MockTrackRepository` via Environment
- Use `ModelConfiguration(isStoredInMemoryOnly: true)` for test isolation

## Swift Testing Framework

```swift
import Testing
import SwiftData

@Test func testMigrationFromV1ToV2() throws {
    // 1. Create V1 data
    let v1Schema = Schema(versionedSchema: SchemaV1.self)
    let v1Config = ModelConfiguration(isStoredInMemoryOnly: true)
    let v1Container = try ModelContainer(for: v1Schema, configurations: v1Config)

    let context = v1Container.mainContext
    let note = SchemaV1.Note(id: "1", title: "Test", content: "Original")
    context.insert(note)
    try context.save()

    // 2. Run migration to V2
    let v2Schema = Schema(versionedSchema: SchemaV2.self)
    let v2Container = try ModelContainer(
        for: v2Schema,
        migrationPlan: MigrationPlan.self,
        configurations: v1Config
    )

    // 3. Verify data migrated
    let v2Context = v2Container.mainContext
    let notes = try v2Context.fetch(FetchDescriptor<SchemaV2.Note>())

    #expect(notes.count == 1)
    #expect(notes.first?.content != nil)
}
```

## Migration Testing on Real Devices

Simulator deletes database on rebuild — migration code never runs. ALWAYS test on real devices.

### Testing Workflow

1. Install v1 build on real device
2. Create sample data (100+ records with all relationship types)
3. Verify data exists
4. Install v2 build (with migration) — do NOT delete app
5. Launch app
6. Verify:
   - App launches without crash
   - All records still exist
   - Relationships intact
   - New fields populated correctly

### Migration Testing Checklist

- [ ] Test fresh install (all migrations run from V1 to latest)
- [ ] Test upgrade from each previous version
- [ ] Test on REAL device (not just simulator)
- [ ] Verify relationship integrity after migration
- [ ] Check for data loss (count records before/after)
- [ ] Test with production-sized dataset

### Test Data Preparation

- **Minimal dataset**: 10-20 records with all relationship types
- **Realistic dataset**: 1,000+ records matching production scale
- **Edge cases**: Empty relationships, max relationship counts, optional fields

## Preview Support with Mock Repositories

```swift
struct ContentView: View {
    let repository: TrackRepository

    var body: some View {
        // Use repository for data access
    }
}

#Preview {
    let mock = MockTrackRepository()
    mock.tracks = [
        TrackDTO(id: .init(), title: "Preview Track", trackNumber: 1, albumTitle: "Preview Album")
    ]
    return ContentView(repository: mock)
}
```
