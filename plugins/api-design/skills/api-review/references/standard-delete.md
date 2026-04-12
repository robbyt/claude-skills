# Standard Methods: Delete

References: [AIP-135](https://google.aip.dev/135), [AIP-164](https://google.aip.dev/164)

## Pattern

```proto
rpc DeleteBook(DeleteBookRequest) returns (google.protobuf.Empty) {
  option (google.api.http) = {
    delete: "/v1/{name=publishers/*/books/*}"
  };
  option (google.api.method_signature) = "name";
}

message DeleteBookRequest {
  string name = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Book"
    }];
}
```

## Rules

- RPC name **must** begin with `Delete`, followed by singular resource name
- Response **should** be `google.protobuf.Empty` (or the resource for soft delete)
- HTTP verb **must** be `DELETE`
- No `body` key in HTTP annotation
- `name` field **should** be the only variable in URI path
- **Must** fail with `FAILED_PRECONDITION` if child resources exist (unless `force`)
- Singleton child resources are exempt — their lifecycle is tied to the parent

## Protected Delete (AIP-154)

Use etags to prevent deleting a resource that changed since the client last read it:

```proto
message DeleteBookRequest {
  string name = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Book"
    }];
  string etag = 2 [(google.api.field_behavior) = OPTIONAL];
}
```

- Etag provided and matches: permit delete
- Etag provided and doesn't match: return `ABORTED` (409)
- Declarative-friendly resources (AIP-128) **must** provide `etag` on Delete

## Cascading Delete

For resources with children, provide `bool force`:

```proto
message DeletePublisherRequest {
  string name = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Publisher"
    }];
  bool force = 2;
}
```

- `force=false` (default) + children exist: `FAILED_PRECONDITION` error
- `force=true`: delete resource and all children

## Delete If Existing (allow_missing)

For client-assigned names, expose `bool allow_missing`:

```proto
message DeleteBookRequest {
  string name = 1 [...];
  bool allow_missing = 2;
}
```

- Resource not found + `allow_missing`: no-op (success)
- Resource not found + no `allow_missing`: `NOT_FOUND` (404)
- Declarative-friendly resources **should** expose `allow_missing`

## Soft Delete (AIP-164)

Soft delete marks a resource as deleted without permanent removal:

- Response **should** be the resource itself (not Empty)
- Resource gets an `expire_time` indicating when it will be purged
- Soft-deleted resources **should not** appear in List by default
- Provide `bool show_deleted` on List to include them
- Provide an `UndeleteBook` custom method to restore

```proto
rpc UndeleteBook(UndeleteBookRequest) returns (Book) {
  option (google.api.http) = {
    post: "/v1/{name=publishers/*/books/*}:undelete"
    body: "*"
  };
}
```

### When to Use Soft Delete

- Resources that are expensive to recreate
- Resources that must be recoverable for compliance
- Resources with complex dependency graphs

Declarative-friendly resources **should not** implement soft-delete (unless the ID cannot
be reused, in which case it is **required**).

## Long-Running Delete (AIP-151)

For resources that take time to delete:

```proto
rpc DeleteBook(DeleteBookRequest) returns (google.longrunning.Operation) {
  option (google.longrunning.operation_info) = {
    response_type: "google.protobuf.Empty"
    metadata_type: "OperationMetadata"
  };
}
```

## Errors

- `PERMISSION_DENIED` (403): checked first, regardless of existence
- `NOT_FOUND` (404): user has permission but resource doesn't exist
- `FAILED_PRECONDITION` (400): child resources exist and `force` is not set
- `ABORTED` (409): etag mismatch
