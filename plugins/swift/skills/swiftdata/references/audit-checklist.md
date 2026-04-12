# SwiftData Audit Checklist

When reviewing SwiftData code, check these in order of severity.

## CRITICAL (crash or data loss)

| # | Violation | Detection Pattern | Fix |
|---|-----------|-------------------|-----|
| 1 | `@Model struct` instead of `@Model final class` | grep: `@Model\s+struct` | Change to `@Model final class` |
| 2 | Missing models in VersionedSchema.models array | Compare `@Model.*class` definitions against `static var models:` arrays | Add all @Model classes to models array |
| 3 | Array relationship without `= []` default | `@Relationship` with `[ModelType]` but no `= []` | Add `= []` default |
| 4 | Fetch/model access in `didMigrate` | grep: `didMigrate.*fetch\|didMigrate.*context` | Move data access to `willMigrate` |
| 5 | Enum property used in `#Predicate` | grep for enum types inside `#Predicate` blocks | Use rawValue property workaround |

## HIGH (data races, silent corruption)

| # | Violation | Detection Pattern | Fix |
|---|-----------|-------------------|-----|
| 6 | Background Task using @Environment modelContext | `Task {.*modelContext\.(insert\|delete\|save)` where context is from @Environment | Create ModelContext(container) for background work |
| 7 | Missing save() after background context mutations | `context.insert\|delete` without `context.save()` in non-main contexts | Add explicit `try context.save()` |
| 8 | Updating both sides of @Relationship(inverse:) | Manual set/append on both sides of a declared inverse pair | Only set one side; SwiftData manages the inverse |
| 9 | Passing @Model object across actor boundary | @Model instance used in `await` or sent to another actor | Pass PersistentIdentifier, re-fetch on target context |
| 10 | Relationship assignment inside init() | Setting relationship properties in @Model init body | Set relationships after context.insert() |

## MEDIUM (performance degradation)

| # | Violation | Detection Pattern | Fix |
|---|-----------|-------------------|-----|
| 11 | N+1 relationship access in loops | `for.*in.*{` with relationship traversal inside body | Use `relationshipKeyPathsForPrefetching` |
| 12 | 5+ indexes on a single model | Count `@Attribute(.indexed)` and `#Index` entries per model | Reduce to 2-3 indexes on queried/sorted properties |
| 13 | Bulk insert without chunking | `for.*{ context.insert` with >100 items, single save | Chunk into batches of 500-1000, save each chunk |
| 14 | @Query with >1000 potential results | `@Query` without `fetchLimit` on large collections | Use FetchDescriptor with fetchLimit/fetchOffset |
| 15 | Large binary data without .externalStorage | `Data` property >few KB without `@Attribute(.externalStorage)` | Add `.externalStorage` or store file path instead |

## Risk Score

Calculate: CRITICAL x 3 + HIGH x 2 + MEDIUM x 1 (cap at 10)

- **0-2**: Low risk — production ready
- **3-5**: Medium risk — fix before release
- **6-8**: High risk — fix immediately
- **9-10**: Critical risk — do not ship

## False Positives (Skip These)

- `@Model struct` in comments or documentation strings
- Array properties that are plain `[String]`, not `@Relationship`
- `context.insert` in test files (test cleanup is separate)
- Single-item inserts (chunking not needed)
- Main context mutations relying on autosave (HIGH only in background contexts)

## Audit Procedure

1. **Scan for CRITICAL issues first** — stop and fix before proceeding
2. **Check HIGH issues** — these cause subtle data corruption
3. **Review MEDIUM issues** — performance improvements
4. **Calculate risk score** — report to stakeholder
5. **Verify fixes** — re-run audit after changes
