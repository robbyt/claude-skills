# Batch Methods

Reference: [AIP-235](https://google.aip.dev/235)

## Purpose

Batch methods allow clients to perform multiple operations in a single API call, reducing
round trips and enabling atomic operations. They complement the standard CRUD methods.

## Standard Batch Methods

### BatchGet

Retrieve multiple resources by name in one call:

```proto
rpc BatchGetBooks(BatchGetBooksRequest) returns (BatchGetBooksResponse) {
  option (google.api.http) = {
    get: "/v1/{parent=publishers/*}/books:batchGet"
  };
}

message BatchGetBooksRequest {
  string parent = 1 [
    (google.api.resource_reference) = {
      child_type: "library.googleapis.com/Book"
    }];
  repeated string names = 2 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Book"
    }];
}

message BatchGetBooksResponse {
  repeated Book books = 1;
}
```

### BatchCreate

Create multiple resources in one call:

```proto
rpc BatchCreateBooks(BatchCreateBooksRequest) returns (BatchCreateBooksResponse) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books:batchCreate"
    body: "*"
  };
}

message BatchCreateBooksRequest {
  string parent = 1 [
    (google.api.resource_reference) = {
      child_type: "library.googleapis.com/Book"
    }];
  repeated CreateBookRequest requests = 2 [
    (google.api.field_behavior) = REQUIRED];
}

message BatchCreateBooksResponse {
  repeated Book books = 1;
}
```

### BatchUpdate

Update multiple resources in one call:

```proto
rpc BatchUpdateBooks(BatchUpdateBooksRequest) returns (BatchUpdateBooksResponse) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books:batchUpdate"
    body: "*"
  };
}

message BatchUpdateBooksRequest {
  string parent = 1 [...];
  repeated UpdateBookRequest requests = 2 [
    (google.api.field_behavior) = REQUIRED];
}

message BatchUpdateBooksResponse {
  repeated Book books = 1;
}
```

### BatchDelete

Delete multiple resources in one call:

```proto
rpc BatchDeleteBooks(BatchDeleteBooksRequest) returns (google.protobuf.Empty) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books:batchDelete"
    body: "*"
  };
}

message BatchDeleteBooksRequest {
  string parent = 1 [...];
  repeated string names = 2 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Book"
    }];
}
```

## Rules

- Batch methods **should** be scoped to a single parent
- The `parent` field on individual requests **should** match the batch parent
  (or be empty, inheriting the batch parent)
- Batch methods **should** be atomic — either all succeed or all fail
- If atomic semantics are not possible, document partial failure behavior
- Response order **should** match request order
- Maximum batch size **should** be documented (common: 100-1000)
- Requests exceeding the limit **must** return `INVALID_ARGUMENT`

## Long-Running Batch

For expensive batch operations, return an LRO:

```proto
rpc BatchCreateBooks(BatchCreateBooksRequest) returns (google.longrunning.Operation) {
  option (google.longrunning.operation_info) = {
    response_type: "BatchCreateBooksResponse"
    metadata_type: "OperationMetadata"
  };
}
```

## When to Use Batch Methods

| Scenario | Recommendation |
|----------|---------------|
| Client creates 5-50 resources at once | BatchCreate |
| Client needs 10 specific resources by name | BatchGet (faster than 10 individual Gets) |
| Bulk import of thousands of records | Consider a custom `:import` method or streaming |
| Single resource operations | Use standard methods, not batch with size=1 |

## REST/JSON Mapping

Batch methods use the `:batchVerb` URL pattern:

```
GET  /v1/publishers/123/books:batchGet?names=books/1&names=books/2
POST /v1/publishers/123/books:batchCreate
POST /v1/publishers/123/books:batchUpdate
POST /v1/publishers/123/books:batchDelete
```
