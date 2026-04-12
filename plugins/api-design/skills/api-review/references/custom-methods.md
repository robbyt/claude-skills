# Custom Methods

Reference: [AIP-136](https://google.aip.dev/136)

## Purpose

Custom methods express arbitrary actions that don't fit standard methods (Get, List, Create,
Update, Delete). They are essential for business operations — domain actions that are more
than simple data manipulation.

**Prefer standard methods** when possible due to their consistent semantics. Use custom
methods only when the operation genuinely doesn't conform to standard method behavior.

## Pattern

```proto
rpc ArchiveBook(ArchiveBookRequest) returns (ArchiveBookResponse) {
  option (google.api.http) = {
    post: "/v1/{name=publishers/*/books/*}:archive"
    body: "*"
  };
}
```

## Rules

### Naming
- Name **should** be a verb followed by a noun: `ArchiveBook`, `MergePatients`
- **Must not** contain prepositions: no `CreateBookFromDictation` (use `TranscribeBook`)
- **Should not** reuse standard method verbs (Get, List, Create, Update, Delete)
- **Must not** include "Async" — use `LongRunning` suffix if needed

### HTTP Mapping
- HTTP method **must** be `GET` (read-only) or `POST` (side effects)
- URI **must** use `:verb` suffix: `/v1/{name=...}:archive`
- `body` **should** be `"*"`
- Use `camelCase` in URI if word separation needed: `:moveBook`

### Messages
- Request message **should** match RPC name + `Request`
- Response message **should** match RPC name + `Response`
- May return the resource itself when operating on a specific resource

## Types of Custom Methods

### Resource-Based

Operates on a single resource:

```proto
rpc ArchiveBook(ArchiveBookRequest) returns (ArchiveBookResponse) {
  option (google.api.http) = {
    post: "/v1/{name=publishers/*/books/*}:archive"
    body: "*"
  };
}
```

- Resource parameter **must** be called `name`

### Collection-Based

Operates on a collection:

```proto
rpc SortBooks(SortBooksRequest) returns (SortBooksResponse) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books:sort"
    body: "*"
  };
}
```

- Parent **must** be called `parent`
- Collection key (`books`) **must** be literal

### Stateless

Not attached to any resource:

```proto
rpc TranslateText(TranslateTextRequest) returns (TranslateTextResponse) {
  option (google.api.http) = {
    post: "/v1/{project=projects/*}:translateText"
    body: "*"
  };
}
```

- URI **should** put both verb and noun after `:` — `:translateText` not `text:translate`
- **Must** use `POST` if method involves billing

## Common Business Operations

These operations are natural custom methods, not Updates:

| Operation | Custom Method | Why Not Update? |
|-----------|--------------|-----------------|
| Archive a resource | `:archive` | State transition, not field change (AIP-216) |
| Approve a workflow | `:approve` | Domain action with side effects |
| Merge records | `:merge` | Multi-resource operation |
| Provision a team | `:provision` | Complex orchestration |
| Export data | `:export` | Read-only but complex, may be long-running |
| Cancel an operation | `:cancel` | Imperative action, not a state field update |
| Publish a document | `:publish` | State transition with side effects |
| Revoke access | `:revoke` | Authorization action |

## Declarative-Friendly Resources (AIP-128)

Declarative-friendly resources **should not** use custom methods — declarative tools cannot
automatically determine what to do with them.

Exception: rarely-used, fundamentally imperative operations like `Move` or `Rename` where
declarative support is not expected.

## Anti-Patterns

### Using Update for state transitions
**Wrong**: `PATCH /books/1 {"state": "ARCHIVED"}`
**Right**: `POST /books/1:archive`
**Why**: State transitions have side effects and business logic. Update should only change data fields.

### Faux collection keys
**Wrong**: `POST /v1/projects/123/text:translate`
**Right**: `POST /v1/projects/123:translateText`
**Why**: `text` looks like a collection but isn't. Put the full action after `:`.

### Prepositions in method names
**Wrong**: `CreateBookFromDictation`, `GetBookByAuthor`
**Right**: `TranscribeBook`, `SearchBooks` with `author` filter
**Why**: Prepositions signal that a field should be added to an existing method or a different verb used.
