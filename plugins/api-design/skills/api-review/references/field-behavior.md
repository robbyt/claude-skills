# Field Behavior Documentation

Reference: [AIP-203](https://google.aip.dev/203)

## Purpose

Field behavior annotations document the contract between client and server for each field.
They communicate whether fields are required, optional, read-only, write-only, or immutable.

## Annotations

```proto
import "google/api/field_behavior.proto";

message Book {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  string title = 2 [(google.api.field_behavior) = REQUIRED];
  string author = 3 [(google.api.field_behavior) = REQUIRED];
  string isbn = 4 [(google.api.field_behavior) = OPTIONAL];
  google.protobuf.Timestamp create_time = 5 [(google.api.field_behavior) = OUTPUT_ONLY];
  string etag = 6;
}
```

## Behavior Types

| Annotation | Meaning | Who Sets | Example |
|-----------|---------|----------|---------|
| `REQUIRED` | Must be provided on input | Client | `title`, `parent`, `name` on requests |
| `OPTIONAL` | May be omitted | Client | `page_size`, `filter`, `etag` on requests |
| `OUTPUT_ONLY` | Set by server, ignored on input | Server | `create_time`, `update_time`, `reconciling` |
| `INPUT_ONLY` | Accepted on input, not returned | Client | `password`, `request_id` |
| `IMMUTABLE` | Set once on create, cannot be changed | Client (once) | `region`, `project` |
| `IDENTIFIER` | The resource name field | Server | `name` |

## Rules

- Every field **should** have a behavior annotation
- `REQUIRED` fields cause an error if missing
- `OPTIONAL` fields have default behavior when omitted
- `OUTPUT_ONLY` fields **must** be ignored on input (do not error)
- `INPUT_ONLY` fields **must not** be returned in responses
- `IMMUTABLE` fields **should** cause an error if changed on update

## Common Patterns

### Request Fields

```proto
message CreateBookRequest {
  // REQUIRED — where to create the book
  string parent = 1 [(google.api.field_behavior) = REQUIRED, ...];
  // REQUIRED — the book data
  Book book = 2 [(google.api.field_behavior) = REQUIRED];
  // OPTIONAL — client-assigned ID
  string book_id = 3 [(google.api.field_behavior) = OPTIONAL];
  // OPTIONAL — for idempotency
  string request_id = 4;
}
```

### Resource Fields

```proto
message Book {
  // IDENTIFIER — set by server
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  // REQUIRED — must be set on create
  string title = 2 [(google.api.field_behavior) = REQUIRED];
  // IMMUTABLE — set once, cannot change
  string region = 3 [(google.api.field_behavior) = IMMUTABLE];
  // OUTPUT_ONLY — computed by server
  google.protobuf.Timestamp create_time = 4 [(google.api.field_behavior) = OUTPUT_ONLY];
  google.protobuf.Timestamp update_time = 5 [(google.api.field_behavior) = OUTPUT_ONLY];
  // No annotation needed for general read-write fields
  string description = 6;
}
```

## REST/JSON Implications

For REST APIs without proto annotations, document field behavior in OpenAPI/Swagger:

```yaml
properties:
  name:
    type: string
    readOnly: true
    description: "Resource name. Format: publishers/{publisher}/books/{book}"
  title:
    type: string
    description: "Required. The title of the book."
  create_time:
    type: string
    format: date-time
    readOnly: true
    description: "Output only. When the book was created."
```

## Review Checklist

When reviewing an API:
- [ ] All fields have clear behavior (documented or annotated)
- [ ] `name`/`create_time`/`update_time` are OUTPUT_ONLY
- [ ] `request_id` is INPUT_ONLY or OPTIONAL
- [ ] Immutable fields are clearly marked
- [ ] Required fields are minimal (don't over-require)
- [ ] No OUTPUT_ONLY fields are accepted on input without silently ignoring
