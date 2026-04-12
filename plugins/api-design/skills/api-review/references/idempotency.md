# Request Identification and Idempotency

Reference: [AIP-155](https://google.aip.dev/155)

## Purpose

Request IDs provide **idempotency guarantees**: the same request can be issued more than once
without subsequent calls having any effect. This is critical for:

- **Network failures**: Client can safely retry without causing duplicates
- **Parallel processes**: De-duplicate requests from distributed systems
- **Auditing**: Trace specific requests across systems

## Pattern

```proto
message CreateBookRequest {
  string parent = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      child_type: "library.googleapis.com/Book"
    }];
  string book_id = 2 [(google.api.field_behavior) = REQUIRED];
  Book book = 3 [(google.api.field_behavior) = REQUIRED];

  // A unique identifier for this request. Restricted to 36 ASCII characters.
  // A random UUID is recommended.
  // This request is only idempotent if a `request_id` is provided.
  string request_id = 4 [(google.api.field_info).format = UUID4];
}
```

## Rules

- Providing a `request_id` **must** guarantee idempotency
- If duplicate detected, server **should** return the previously successful response
- `request_id` **must** be on the request message (never on the resource)
- **Should** be optional
- **Should** accept UUIDs; **may** require UUID as the only valid format
- UUIDs **must** use the `UUID4` format annotation
- APIs **may** choose any reasonable timeframe for honoring request IDs
- Document the format restrictions

## Duplicate Detection Behavior

| Scenario | Behavior |
|----------|----------|
| First request with ID "abc" | Process normally, store result |
| Second request with same ID "abc" | Return stored result (no re-processing) |
| Same ID but different parameters | Implementation-defined (may reject or ignore) |
| No request ID provided | Not idempotent — process every time |

## Stale Success Responses

In unusual situations, it may not be possible to return an identical success response. For
example, a duplicate Create request arrives after the resource was subsequently updated.

In this case, the method **may** return the current state of the resource instead. The key
point: the operation is not re-executed, but the response may reflect more current data.

## When to Use Request IDs

| Method | Recommendation | Rationale |
|--------|---------------|-----------|
| Create | **Always** | Most critical — prevents duplicate resource creation |
| Custom methods with side effects | **Always** | Side effects must not repeat |
| Update | Optional | ETags handle concurrency; request IDs add retry safety |
| Delete | Optional | Delete is naturally idempotent (second call returns NOT_FOUND) |
| Get / List | Not needed | Read-only, inherently idempotent |

## Implementation Guidance

### Server-Side

1. On receiving a request with `request_id`:
   - Check if this ID has been seen before
   - If yes: return the stored response
   - If no: process the request, store the response keyed by request ID
2. Set a TTL on stored responses (30 days is a reasonable default)
3. Use a fast lookup store (e.g., Redis, database unique constraint)

### Client-Side

1. Generate a UUID4 for each logical operation
2. Store the UUID locally before sending
3. On network error or timeout: retry with the same UUID
4. On success: discard the UUID

### REST/JSON Mapping

The `request_id` field maps to a query parameter in REST:

```
POST /v1/publishers/123/books?bookId=les-miserables&requestId=550e8400-e29b-41d4-a716-446655440000
```

## Relationship to ETags (AIP-154)

ETags and request IDs solve different problems:

| Mechanism | Solves | How |
|-----------|--------|-----|
| **ETags** (AIP-154) | Concurrent writes (TOCTOU) | Server rejects stale writes |
| **Request IDs** (AIP-155) | Duplicate requests (retries) | Server deduplicates by ID |

Both should be used together for robust mutation handling. A typical Create request might
include both a `request_id` (for safe retry) and the created resource might include an
`etag` (for future safe updates).
