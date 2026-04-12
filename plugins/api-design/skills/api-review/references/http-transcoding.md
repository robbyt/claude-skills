# HTTP and gRPC Transcoding

Reference: [AIP-127](https://google.aip.dev/127)

## Purpose

Many APIs define their canonical interface in gRPC (Protocol Buffers) but also expose a
REST/JSON interface. HTTP transcoding defines how gRPC methods map to HTTP endpoints,
allowing a single API definition to serve both protocols.

## Standard Method Mapping

| gRPC Method | HTTP Verb | URL Pattern | Body |
|-------------|-----------|-------------|------|
| GetBook | `GET` | `/v1/{name=publishers/*/books/*}` | None |
| ListBooks | `GET` | `/v1/{parent=publishers/*}/books` | None |
| CreateBook | `POST` | `/v1/{parent=publishers/*}/books` | `book` |
| UpdateBook | `PATCH` | `/v1/{book.name=publishers/*/books/*}` | `book` |
| DeleteBook | `DELETE` | `/v1/{name=publishers/*/books/*}` | None |

## Custom Method Mapping

Custom methods use POST with a `:verb` suffix:

```proto
rpc ArchiveBook(ArchiveBookRequest) returns (ArchiveBookResponse) {
  option (google.api.http) = {
    post: "/v1/{name=publishers/*/books/*}:archive"
    body: "*"
  };
}
```

- Custom methods **must** use `POST` (with side effects) or `GET` (read-only)
- The `:verb` suffix **must** match the method name
- Body **should** be `"*"` for custom methods

## URI Design

### Variable Binding

URI variables bind to request message fields:

```proto
// Single variable
get: "/v1/{name=publishers/*/books/*}"
// → name field gets "publishers/123/books/456"

// Nested variable (Update)
patch: "/v1/{book.name=publishers/*/books/*}"
// → book.name field gets "publishers/123/books/456"
```

### Query Parameters

Request fields not in the URL path become query parameters:

```proto
message ListBooksRequest {
  string parent = 1;    // In URL path
  int32 page_size = 2;  // Query parameter: ?pageSize=20
  string page_token = 3; // Query parameter: ?pageToken=abc
  string filter = 4;     // Query parameter: ?filter=rating>3
}
```

### Body Mapping

The `body` annotation controls what goes in the HTTP request body:

| Annotation | Meaning |
|-----------|---------|
| `body: "book"` | Only the `book` field is in the body |
| `body: "*"` | All fields not in the URL are in the body |
| No body key | No request body (GET, DELETE) |

## Version Prefix

REST URLs include a version prefix:

```
/v1/publishers/123/books/456
/v2/publishers/123/books/456
```

- Version **should** be the first segment
- Maps to the proto package version: `google.example.library.v1`

## JSON Encoding

### Field Names

Proto `snake_case` fields map to `camelCase` in JSON:

| Proto | JSON |
|-------|------|
| `page_size` | `pageSize` |
| `page_token` | `pageToken` |
| `update_mask` | `updateMask` |
| `create_time` | `createTime` |

### Enum Values

Enum values are encoded as strings in JSON:

```json
{"state": "ACTIVE"}
```

Not as numbers (`{"state": 1}`).

### Well-Known Types

| Proto Type | JSON Type |
|-----------|-----------|
| `google.protobuf.Timestamp` | `"2024-01-15T09:30:00Z"` (RFC 3339) |
| `google.protobuf.Duration` | `"300s"` |
| `google.protobuf.FieldMask` | `"title,author"` (comma-separated) |
| `google.protobuf.Struct` | JSON object |

## REST API Without Proto

For teams using REST/JSON without Protocol Buffers, follow the same conventions:

```yaml
# OpenAPI equivalent of AIP patterns
paths:
  /v1/publishers/{publisherId}/books:
    get:
      operationId: listBooks
      parameters:
        - name: pageSize
          in: query
          schema: { type: integer }
        - name: pageToken
          in: query
          schema: { type: string }
    post:
      operationId: createBook
      parameters:
        - name: bookId
          in: query
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/Book' }

  /v1/publishers/{publisherId}/books/{bookId}:
    get:
      operationId: getBook
    patch:
      operationId: updateBook
      parameters:
        - name: updateMask
          in: query
          schema: { type: string }
      requestBody:
        content:
          application/json:
            schema: { $ref: '#/components/schemas/Book' }
    delete:
      operationId: deleteBook
      parameters:
        - name: etag
          in: query
          schema: { type: string }
```

## Migration from REST to gRPC

When migrating internal REST APIs to gRPC (Phase 2 of architecture modernization):

1. Define resources as proto messages
2. Define standard methods with `google.api.http` annotations
3. Use an API gateway (Apigee, Envoy) for REST→gRPC transcoding
4. Proto schemas become the canonical contract
5. REST interface remains available via transcoding
6. Client libraries auto-generated from proto definitions
