# Long-Running Operations

Reference: [AIP-151](https://google.aip.dev/151)

## Purpose

When an API method takes a significant amount of time (rule of thumb: >10 seconds), it
**should** return a long-running operation (LRO) instead of blocking. This is analogous to
a Python Future or JavaScript Promise — the user gets a token to track progress and retrieve
the result.

## Pattern

```proto
rpc CreateBook(CreateBookRequest) returns (google.longrunning.Operation) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books"
    body: "book"
  };
  option (google.longrunning.operation_info) = {
    response_type: "Book"
    metadata_type: "OperationMetadata"
  };
}
```

## Rules

- Response type **must** be `google.longrunning.Operation` (don't copy the proto)
- Response **must not** be streaming
- `operation_info` annotation **must** specify both `response_type` and `metadata_type`
- Types **must** be defined in the same file or an imported file
- Use fully-qualified names when types are in another package
- `response_type` **should not** be `google.protobuf.Empty` (except for Delete)
- APIs with LRO methods **must** implement the `Operations` service
- Don't define custom LRO interfaces — use the standard one

## Standard Methods as LROs

Create, Update, and Delete **may** return Operations:

| Method | `response_type` | Notes |
|--------|-----------------|-------|
| Create | The resource | Resource should appear in List with pending state |
| Update | The resource | |
| Delete | `google.protobuf.Empty` (or resource for soft-delete) | |

When creating or deleting via LRO:
- Resource **should** appear in Get and List
- Resource **should** indicate it's not yet usable via a state enum (AIP-216)

## Metadata

The `metadata_type` provides information on each `GetOperation` call:

```proto
message OperationMetadata {
  // The time the operation was created.
  google.protobuf.Timestamp create_time = 1;
  // The time the operation finished running.
  google.protobuf.Timestamp end_time = 2;
  // Server-defined resource path for the target of the operation.
  string target = 3;
  // Name of the verb executed by the operation.
  string verb = 4;
  // Human-readable status of the operation, if any.
  string status_message = 5;
  // Percentage of completion [0, 100].
  int32 progress_percentage = 6;
}
```

## Parallel Operations

- Resources **may** accept multiple parallel operations (possibly queued)
- Resources that reject parallel operations **must** return `ABORTED`
- Declarative-friendly resources **may** allow new operations to preempt existing ones
  (previous operations marked `ABORTED`)

## Expiration

Operations **may** expire after sufficient time post-completion. A good rule of thumb
is 30 days.

## Errors

- Errors preventing an LRO from starting: return error response immediately (AIP-193)
- Errors during execution: place in `Operation.error` field
- Non-terminal errors during execution: **may** be placed in metadata

## Validate-Only Mode (AIP-163)

For validation requests on LRO methods, the response **must** be one of:
1. A completed Operation (`done=true`) with valid response — no state to maintain
2. An immediate error response
3. An Operation with `done=false` for long-running validation (must set `name` for polling)

## Backward Compatibility

Changing `response_type` or `metadata_type` is a **breaking change**.
