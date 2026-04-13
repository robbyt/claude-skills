# Cross-Collection Reads and Partial Failures

References: [AIP-159](https://google.aip.dev/159), [AIP-217](https://google.aip.dev/217)

## Reading Across Collections (AIP-159)

Allow users to retrieve resources across multiple parent collections using `-` as a
wildcard:

```
GET /v1/publishers/-/books?filter=rating>4
```

This returns books from all publishers matching the filter.

### Rules

- URI pattern still uses `*` — never hard-code `-`
- **Must** explicitly document that wildcard is supported
- Response uses **canonical** resource names (actual parent IDs, not `-`)
- List across collections: allowed regardless of child ID uniqueness
- Get across collections: only if child IDs are unique across parents
- `order_by` **should not** be supported on cross-parent requests (or document as best-effort)

### Unique Resource Lookup

If child IDs are unique across parents, support Get with wildcard:

```
GET /v1/publishers/-/books/978-0-13-468599-1
→ returns publishers/penguin/books/978-0-13-468599-1
```

The response uses the canonical name with the actual parent, not `-`.

## Partial Failures / Unreachable Resources (AIP-217)

When listing across collections, some parents may be temporarily unreachable (e.g., a
region is down). The API should return available data while indicating what's missing.

### Response Pattern

```proto
message ListBooksResponse {
  repeated Book books = 1;
  string next_page_token = 2;

  // Resources or collections that could not be reached.
  repeated string unreachable = 3 [
    (google.api.field_behavior) = UNORDERED_LIST
  ];
}
```

### Rules

- `unreachable` **must** be `repeated string` containing service-relative resource names
- Names are **not** full resource names or URIs — just the resource path
- **Must not** provide error reasons for individual unreachable entries
- The list **must** be unordered (`UNORDERED_LIST` annotation)
- May be heterogeneous (locations and specific resources mixed)
- Reported per page, not accumulated to the end of pagination

### When Single Parent Is Unreachable

If a request targets a single parent and that parent is unreachable, **fail the entire
request** with an error. The `unreachable` pattern is only for cross-collection queries
where partial results are meaningful.

### Pagination with Unreachable Resources

- Include `unreachable` on every page where it's relevant
- If a previously unreachable resource becomes available on a later page, include it
  (if paging parameters allow)
- Document the maximum number of unreachable entries per response

### Adopting Partial Success (Brownfield)

For existing APIs that currently fail entirely when any parent is unreachable:

1. Add `bool return_partial_success` to the request message
2. Add `repeated string unreachable` to the response message
3. Both fields **must** be added simultaneously
4. Default behavior (no `return_partial_success`) **must** retain the old fail behavior

```proto
message ListBooksRequest {
  string parent = 1 [...];
  int32 page_size = 2;
  string page_token = 3;

  // If true, return available resources and list unreachable ones
  // instead of failing the entire request.
  bool return_partial_success = 4;
}
```

## REST Examples

```
# All books across all publishers
GET /v1/publishers/-/books

# All books across all publishers, with partial success
GET /v1/publishers/-/books?returnPartialSuccess=true

# Get a specific book without knowing the publisher
GET /v1/publishers/-/books/isbn-123

# Response includes unreachable publishers
{
  "books": [...],
  "nextPageToken": "...",
  "unreachable": [
    "publishers/offline-press"
  ]
}
```

## Review Checklist

- [ ] Cross-collection List uses `-` wildcard, documented explicitly (AIP-159)
- [ ] Response uses canonical resource names, not `-` (AIP-159)
- [ ] Cross-collection Get only supported if child IDs are unique (AIP-159)
- [ ] `order_by` not supported on cross-parent requests (or documented as best-effort) (AIP-159)
- [ ] Partial failures include `unreachable` field with service-relative names (AIP-217)
- [ ] Single unreachable parent fails the request, not partial success (AIP-217)
- [ ] Brownfield adoption uses `return_partial_success` opt-in (AIP-217)
