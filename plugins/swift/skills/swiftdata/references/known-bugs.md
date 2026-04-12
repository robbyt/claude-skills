# Known Bugs by iOS Version

## iOS 17.0-17.1 (avoid if possible)

- Enum predicate crashes
- Broken `didSave`/`willSave` notifications
- `@ModelActor` mutations don't trigger `@Query` view updates
- Many-to-many relationship alphabetical naming bug (iOS 17.0 only, fixed 17.1)

## iOS 17.2+ (minimum recommended target)

- Most launch crashes fixed
- Optional predicate chains still unreliable

## iOS 18.0

- Major internal refactoring broke some iOS 17 patterns
- Releasing `@ModelActor` destroys all fetched model instances (regression)
- `#Expression` macro added for composable predicates

## iOS 18.x+

- `#Index` and `#Unique` macros available
- Multi-store support added

## Xcode 26 / iOS 26 (WWDC 2025)

- Model inheritance added
- **Backported to iOS 17**: @ModelActor background mutations now trigger @Query updates
- **Backported to iOS 17**: Codable model properties work in predicates
- These backports are the most significant stability improvement since launch
- `@Attribute(.preserveValueOnDeletion)` for audit trails
- `isHistoryEnabled` for history tracking
- `propertiesToFetch` on FetchDescriptor
- `minimum`/`maximum` on @Relationship

## Active Bugs (Guard Against These)

These are unresolved as of the latest known information:

- Inverse relationship updates do NOT trigger Observation/view refreshes
- Generic `#Predicate<T>` crashes in Release builds only (not Debug)
- Sort logic crashes in Release when models split across files (FB22173905)
- `didSave`/`willSave` notifications remain non-functional through iOS 18
- Providing SchemaMigrationPlan when implicit lightweight migration works causes failure
- Non-optional Codable properties block ALL future migrations (FB22151570)

## Debugging Launch Arguments

| Argument | Purpose |
|----------|---------|
| `-com.apple.CoreData.SQLDebug 1` | Log SQL queries (levels 1-4) |
| `-com.apple.CoreData.SQLDebug 3` | Includes EXPLAIN QUERY PLAN |
| `-com.apple.CoreData.ConcurrencyDebug 1` | Crash on thread violations |
| `-com.apple.coredata.swiftdata.debug 1` | SwiftData-specific debug logging |
