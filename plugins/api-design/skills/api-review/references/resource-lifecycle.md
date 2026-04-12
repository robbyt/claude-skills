# Resource Lifecycle

References: [AIP-216](https://google.aip.dev/216), [AIP-164](https://google.aip.dev/164), [AIP-214](https://google.aip.dev/214)

## State Enums (AIP-216)

Resources with lifecycle stages **should** use a state enum:

```proto
message Book {
  string name = 1;
  // ... other fields ...

  // Output only. The current state of the book.
  State state = 10 [(google.api.field_behavior) = OUTPUT_ONLY];

  enum State {
    STATE_UNSPECIFIED = 0;
    ACTIVE = 1;
    CREATING = 2;     // Long-running create in progress
    DELETING = 3;     // Long-running delete in progress
    UPDATING = 4;     // Long-running update in progress
    SUSPENDED = 5;    // Administratively suspended
  }
}
```

### Rules

- State fields **must** be OUTPUT_ONLY — never directly writable via Update (AIP-134)
- State transitions belong in custom methods (AIP-136): `:suspend`, `:activate`
- The zero value **must** be `STATE_UNSPECIFIED`
- Resources in transitional states (CREATING, DELETING) **should** appear in List/Get
- Document which operations are allowed in each state

### State vs Custom Methods

| Wrong (Update) | Right (Custom Method) |
|----------------|----------------------|
| `PATCH /books/1 {"state": "SUSPENDED"}` | `POST /books/1:suspend` |
| `PATCH /books/1 {"state": "ACTIVE"}` | `POST /books/1:activate` |

State transitions often have business logic, validation, and side effects that don't
belong in a generic Update method.

## Soft Delete (AIP-164)

Soft delete marks resources as deleted without permanent removal:

```proto
message Book {
  string name = 1;
  // ... fields ...

  // Output only. If set, the time at which this resource was soft-deleted.
  google.protobuf.Timestamp delete_time = 20 [(google.api.field_behavior) = OUTPUT_ONLY];

  // Output only. If set, the time at which this resource will be purged.
  google.protobuf.Timestamp expire_time = 21 [(google.api.field_behavior) = OUTPUT_ONLY];
}
```

### Delete Behavior

- Delete RPC returns the resource (not Empty) with `delete_time` set
- Resource retains its name — it cannot be reused until purged
- Soft-deleted resources **should not** appear in List by default
- List supports `bool show_deleted` to include them
- Get **should** return soft-deleted resources (with delete_time populated)

### Undelete

```proto
rpc UndeleteBook(UndeleteBookRequest) returns (Book) {
  option (google.api.http) = {
    post: "/v1/{name=publishers/*/books/*}:undelete"
    body: "*"
  };
}
```

- Restores a soft-deleted resource
- Clears `delete_time` and `expire_time`
- If resource is already purged, return `NOT_FOUND`

### Purge

Resources are permanently deleted after `expire_time`. The default retention period
should be documented (common: 30 days).

### When to Use

| Scenario | Use Soft Delete? |
|----------|-----------------|
| Resource is expensive to recreate | Yes |
| Compliance requires recovery | Yes |
| Resource name must not be reused | Yes (required for declarative-friendly) |
| Ephemeral data (logs, events) | No |
| Storage cost of retention is prohibitive | No (or shorter retention) |

## Resource Expiry / TTL (AIP-214)

Resources that naturally expire use `expire_time`:

```proto
message Session {
  string name = 1;
  // ... fields ...

  // When this session expires. After this time, the resource may be purged.
  google.protobuf.Timestamp expire_time = 10;

  // Alternative: duration-based TTL
  google.protobuf.Duration ttl = 11 [(google.api.field_behavior) = INPUT_ONLY];
}
```

### Rules

- `expire_time` is the canonical field (Timestamp)
- `ttl` is a convenience input (Duration) — server converts to `expire_time`
- `ttl` **should** be INPUT_ONLY
- If both are provided, `expire_time` takes precedence
- Expired resources **may** be purged at any time after `expire_time`
- Expired resources **should not** appear in List by default

## Standard Resource Fields

Resources **should** include these standard timestamp fields:

```proto
message Book {
  string name = 1;
  // ... domain fields ...

  google.protobuf.Timestamp create_time = 50 [(google.api.field_behavior) = OUTPUT_ONLY];
  google.protobuf.Timestamp update_time = 51 [(google.api.field_behavior) = OUTPUT_ONLY];
  google.protobuf.Timestamp delete_time = 52 [(google.api.field_behavior) = OUTPUT_ONLY];
  google.protobuf.Timestamp expire_time = 53 [(google.api.field_behavior) = OUTPUT_ONLY];
  string etag = 99;
}
```

These are especially important for declarative-friendly resources (AIP-128, AIP-148).
