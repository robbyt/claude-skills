# Standard Methods: Update

Reference: [AIP-134](https://google.aip.dev/134)

## Pattern

```proto
rpc UpdateBook(UpdateBookRequest) returns (Book) {
  option (google.api.http) = {
    patch: "/v1/{book.name=publishers/*/books/*}"
    body: "book"
  };
  option (google.api.method_signature) = "book,update_mask";
}

message UpdateBookRequest {
  Book book = 1 [(google.api.field_behavior) = REQUIRED];
  google.protobuf.FieldMask update_mask = 2;
}
```

## Rules

- RPC name **must** begin with `Update`, followed by singular resource name
- Response **must** be the resource itself
- HTTP verb **should** be `PATCH` (never use `PUT` — see below)
- `body` **must** map to the resource field
- Resource's `name` field maps to URI path (note: nested field `book.name`)
- `update_mask` **must** be included for partial updates
- `update_mask` **must** be optional; omitted = implied mask of all populated fields
- `update_mask` **must** support `*` for full replacement
- Request **must not** contain other required fields

## Why PATCH, Not PUT (AIP-134)

Google standardizes on PATCH because APIs evolve. Consider a `PUT` to a Book:

```json
PUT /v1/publishers/123/books/456
{"title": "Mary Poppins", "author": "P.L. Travers"}
```

When a `rating` field is added later, existing PUT clients unknowingly wipe it out.
PATCH with field masks avoids this — only specified fields are updated.

**This is a critical backward compatibility concern.** Moving from PUT to PATCH is a
breaking change; starting with PATCH avoids the problem entirely.

## Field Masks

- Fields in the mask correspond to the resource, not the request message
- Omitted mask = update all populated fields
- `*` mask = full replacement (equivalent to PUT)
- API producers must consider how new fields interact with `*` masks
- Consumers should explicitly list fields rather than using `*`

## ETags on Update (AIP-154)

To prevent TOCTOU race conditions, include an `etag` field on the resource:

```proto
message Book {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  string title = 2;
  string author = 3;
  string etag = 4;
}
```

- If `etag` is provided and matches, permit the request
- If `etag` doesn't match, return `ABORTED` (409)
- If `etag` is omitted, generally permit (unless service requires it)
- `update_mask` does not affect `etag` behavior — etag protects the whole resource

## Create or Update (allow_missing)

For client-assigned resource names, Update may expose `bool allow_missing`:

```proto
message UpdateBookRequest {
  Book book = 1 [(google.api.field_behavior) = REQUIRED];
  google.protobuf.FieldMask update_mask = 2;
  bool allow_missing = 3;
}
```

Behavior:
- Resource not found + `allow_missing`: create it (all fields applied, mask ignored)
- Resource exists + fields match: return unchanged
- Resource exists + fields differ: apply mask

## Side Effects

Update methods **should not** trigger side effects. State transitions belong in custom
methods (AIP-136). State fields (AIP-216) **must not** be directly writable in Update.

## Long-Running Update (AIP-151)

For resources that take time to update:

```proto
rpc UpdateBook(UpdateBookRequest) returns (google.longrunning.Operation) {
  option (google.longrunning.operation_info) = {
    response_type: "Book"
    metadata_type: "OperationMetadata"
  };
}
```

Declarative-friendly resources (AIP-128) **should** use long-running update.

## Errors

- `NOT_FOUND` (404): resource doesn't exist (unless `allow_missing` is true)
- `ABORTED` (409): etag mismatch
- `PERMISSION_DENIED` (403): insufficient permissions (checked before existence)
