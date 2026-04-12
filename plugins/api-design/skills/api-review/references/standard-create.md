# Standard Methods: Create

Reference: [AIP-133](https://google.aip.dev/133)

## Pattern

```proto
rpc CreateBook(CreateBookRequest) returns (Book) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books"
    body: "book"
  };
  option (google.api.method_signature) = "parent,book";
}

message CreateBookRequest {
  string parent = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      child_type: "library.googleapis.com/Book"
    }];
  string book_id = 2 [(google.api.field_behavior) = REQUIRED];
  Book book = 3 [(google.api.field_behavior) = REQUIRED];
}
```

## Rules

- RPC name **must** begin with `Create`, followed by singular resource name
- Response **must** be the resource itself (no `CreateBookResponse`)
- HTTP verb **must** be `POST`
- `body` **must** map to the resource field
- `parent` field **must** be included (unless top-level resource)
- `{resource}_id` **must** be included for management plane resources
- Request **must not** contain other required fields
- Response **should** include fully populated resource

## User-Specified IDs

Management plane APIs **must** allow users to specify the resource ID:

```
publishers/lacroix/books/les-miserables    // user-specified
publishers/012345678-abcd/books/12341234   // system-generated
```

- `{resource}_id` **must** be on the request message, not the resource
- Document acceptable format (recommended: 4-63 chars, `/[a-z][0-9]-/`)
- Duplicate name **must** return `ALREADY_EXISTS`
- If user lacks permission to see duplicate, return `PERMISSION_DENIED` instead

## Long-Running Create (AIP-151)

For resources that take significant time to create:

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

- `response_type` **must** be the resource
- Both `response_type` and `metadata_type` **must** be specified
- Declarative-friendly resources (AIP-128) **should** use long-running create

## Idempotency (AIP-155)

Create requests **should** include `string request_id` to enable safe retries:

```proto
message CreateBookRequest {
  // ... other fields ...
  string request_id = 4 [(google.api.field_info).format = UUID4];
}
```

- If duplicate request detected, return the previously successful response
- `request_id` must be on the request message, never on the resource

## Strong Consistency

For management plane operations, completion of create **must** mean:
- The resource exists and is readable via Get
- The resource appears in List results
- All user-settable values have reached steady-state
