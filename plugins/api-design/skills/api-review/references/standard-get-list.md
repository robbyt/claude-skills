# Standard Methods: Get and List

References: [AIP-131](https://google.aip.dev/131), [AIP-132](https://google.aip.dev/132), [AIP-158](https://google.aip.dev/158), [AIP-160](https://google.aip.dev/160)

## Get (AIP-131)

Retrieves a single resource by name.

```proto
rpc GetBook(GetBookRequest) returns (Book) {
  option (google.api.http) = {
    get: "/v1/{name=publishers/*/books/*}"
  };
  option (google.api.method_signature) = "name";
}

message GetBookRequest {
  string name = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Book"
    }];
}
```

### Rules

- RPC name **must** begin with `Get`, followed by singular resource name
- Request message **must** match RPC name + `Request` suffix
- Response **must** be the resource itself (no `GetBookResponse` wrapper)
- HTTP verb **must** be `GET`
- URI **should** contain single variable for `name`
- No `body` key in HTTP annotation
- One `method_signature` annotation with value `"name"`
- Request **must not** contain other required fields

### Errors (AIP-193)

- `PERMISSION_DENIED` (403): user lacks permission, regardless of existence
- `NOT_FOUND` (404): user has permission but resource doesn't exist

## List (AIP-132)

Returns a paginated collection of resources.

```proto
rpc ListBooks(ListBooksRequest) returns (ListBooksResponse) {
  option (google.api.http) = {
    get: "/v1/{parent=publishers/*}/books"
  };
  option (google.api.method_signature) = "parent";
}

message ListBooksRequest {
  string parent = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      child_type: "library.googleapis.com/Book"
    }];
  int32 page_size = 2;
  string page_token = 3;
}

message ListBooksResponse {
  repeated Book books = 1;
  string next_page_token = 2;
}
```

### Rules

- RPC name **must** begin with `List`, followed by plural resource name
- HTTP verb **must** be `GET`
- Collection identifier (`books`) **must** be literal in URL
- `page_size` and `page_token` fields **must** be present (AIP-158)
- Response **must** include `next_page_token` (empty if final page)
- Response **may** include `total_size` (may be an estimate)
- List **should** return same results for any authorized user
- Soft-deleted resources **should not** be included by default; use `show_deleted`

### Pagination (AIP-158)

- `page_size`: max items to return; server may return fewer
- `page_token`: opaque token from previous response
- Document the maximum allowed `page_size` and default value
- Values above maximum **should** be coerced (not rejected)
- Negative values **must** return `INVALID_ARGUMENT`
- All parameters besides `page_token` **must** match the original request

### Ordering

List may support `string order_by` field:
- Comma-separated fields: `"created_time,name"`
- Append `" desc"` for descending: `"created_time desc, name"`
- Subfields use `.`: `"address.city"`
- Only add ordering when there is an established need

### Filtering (AIP-160)

List may support `string filter` field:
- Use a common expression language
- Filters apply before pagination
- `total_size` should reflect post-filter count
- Only add filtering when there is an established need
