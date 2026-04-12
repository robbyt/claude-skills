# Pagination and Filtering

References: [AIP-158](https://google.aip.dev/158), [AIP-160](https://google.aip.dev/160)

## Pagination (AIP-158)

All List methods **must** support pagination. Even if the collection is small today,
it may grow.

### Request Fields

```proto
message ListBooksRequest {
  string parent = 1 [...];
  int32 page_size = 2;     // Max items to return
  string page_token = 3;   // Token from previous response
}
```

### Response Fields

```proto
message ListBooksResponse {
  repeated Book books = 1;
  string next_page_token = 2;  // Empty if this is the last page
}
```

### Rules

- `page_size` and `page_token` **must** be on all List requests
- `next_page_token` **must** be on all List responses
- `next_page_token` **must** be set if there are more results, empty if final page
- Document the maximum `page_size` and default value
- Values above maximum **should** be coerced, not rejected
- Negative or invalid values **must** return `INVALID_ARGUMENT`
- Server **may** return fewer items than `page_size`

### Token Behavior

- Tokens are **opaque** — clients must not parse or construct them
- All parameters besides `page_token` **must** match the original request
- Tokens **should** expire after a reasonable time
- Expired tokens **should** return `INVALID_ARGUMENT` (not silently restart)

### Total Size

Response **may** include `int32 total_size` (or `int64`):
- Value **may** be an estimate (document this)
- If filtering is active, `total_size` reflects the filtered count

## Filtering (AIP-160)

List methods **may** support a `string filter` field for server-side filtering.

### Request Field

```proto
message ListBooksRequest {
  string parent = 1 [...];
  int32 page_size = 2;
  string page_token = 3;
  string filter = 4;  // Filter expression
}
```

### Expression Syntax

AIP-160 defines a common expression language. Examples:

```
# Equality
filter: 'author = "P.L. Travers"'

# Comparison
filter: 'rating > 3'

# String contains
filter: 'title : "Poppins"'

# Boolean
filter: 'published = true'

# Combining with AND/OR
filter: 'author = "Travers" AND rating >= 4'

# Negation
filter: 'NOT published'

# Nested fields
filter: 'address.city = "London"'

# Timestamp comparison
filter: 'create_time > "2024-01-01T00:00:00Z"'
```

### Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equality | `state = "ACTIVE"` |
| `!=` | Inequality | `state != "DELETED"` |
| `<`, `>`, `<=`, `>=` | Comparison | `rating > 3` |
| `:` | Has/contains | `tags : "fiction"` |
| `AND` | Logical and | `a = 1 AND b = 2` |
| `OR` | Logical or | `a = 1 OR a = 2` |
| `NOT` | Negation | `NOT published` |

### Rules

- Filter syntax **should** be documented
- Invalid filters **must** return `INVALID_ARGUMENT`
- Filtering applies before pagination
- `total_size` should reflect post-filter count
- Only add filtering when there is an established need (can be added later)

## REST/JSON Mapping

```
# Paginated request
GET /v1/publishers/123/books?pageSize=20&pageToken=abc123

# Filtered request
GET /v1/publishers/123/books?filter=author%3D%22Travers%22&pageSize=20

# Combined
GET /v1/publishers/123/books?filter=rating%3E3&pageSize=10&orderBy=title
```

## Ordering (AIP-132)

List methods **may** support `string order_by`:

```
# Single field, ascending (default)
order_by: "title"

# Descending
order_by: "created_time desc"

# Multiple fields
order_by: "author, title desc"

# Nested
order_by: "address.city"
```

- Default order is ascending
- `" desc"` suffix for descending
- Comma-separated for multiple fields
- Only add if there is an established need

## Design Decisions

### Cursor vs Offset Pagination

| Approach | Pros | Cons |
|----------|------|------|
| **Cursor (page_token)** — AIP standard | Consistent results, scalable | Can't jump to page N |
| **Offset (page/limit)** | Simple, jump to any page | Inconsistent under concurrent writes, poor at scale |

AIP-158 mandates cursor-based pagination. Offset pagination causes problems:
- Inserts/deletes between pages cause skipped or duplicate items
- Large offsets are expensive (database must scan all preceding rows)

### Filter vs Search

- **Filter** (AIP-160): deterministic, returns same results for all authorized users
- **Search**: may use relevance ranking, may return different results per user
- Use List + filter for structured queries; use a separate Search method for fuzzy matching
