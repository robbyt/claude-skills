# Repeated Fields

Reference: [AIP-144](https://google.aip.dev/144)

## Purpose

Representing lists in APIs is trickier than it appears. The key challenge: field masks
cannot address individual elements in a repeated field, so the entire list is replaced
on update. This creates update strategy decisions.

## Rules

```proto
message Book {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  repeated string authors = 2;
}
```

- **Must** use plural field name (`authors`, not `author`)
- **Should** enforce an upper bound (~100 elements) to prevent oversized payloads
- **Must not** inline full resource bodies — use resource names instead
- Prefer scalars (`string`) if additional data won't be needed
- Use messages if future expansion is likely (avoids parallel repeated fields)

## Update Strategies

### Strategy 1: Standard Update (Read-Modify-Write)

Client reads the resource, modifies the list, sends the entire list back via Update.

```
GET /books/1           → {authors: ["Alice", "Bob"]}
PATCH /books/1         → {authors: ["Alice", "Bob", "Carol"]}
                          updateMask: "authors"
```

**When to use:**
- List is small (fewer than ~10 elements)
- Race conditions are acceptable or guarded by ETags (AIP-154)
- Declarative-friendly resources (AIP-128) **must** use this approach

**Limitation:** Field masks cannot address individual elements. The entire list is replaced.

### Strategy 2: Add/Remove Custom Methods

For atomic modifications without read-modify-write:

```proto
rpc AddAuthor(AddAuthorRequest) returns (Book) {
  option (google.api.http) = {
    post: "/v1/{book=publishers/*/books/*}:addAuthor"
    body: "*"
  };
}

rpc RemoveAuthor(RemoveAuthorRequest) returns (Book) {
  option (google.api.http) = {
    post: "/v1/{book=publishers/*/books/*}:removeAuthor"
    body: "*"
  };
}
```

**When to use:**
- Atomic modifications required (concurrent access to the list)
- List may be large
- NOT for declarative-friendly resources

### Add/Remove Method Rules (AIP-144)

- RPC name **must** begin with `Add` or `Remove`
- Remainder **should** be singular form of the field name
- HTTP verb **must** be `POST`
- URI **must** end with `:addAuthor` or `:removeAuthor` (snake_case)
- Response **should** be the resource itself (fully populated)
- Adding an already-present value → `ALREADY_EXISTS`
- Removing a not-present value → `NOT_FOUND`

### Add/Remove Request Messages

```proto
message AddAuthorRequest {
  string book = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference).type = "library.googleapis.com/Book"
  ];
  string author = 2 [(google.api.field_behavior) = REQUIRED];
}
```

- Resource field **should** be the resource name (e.g., `book`), not `name` or `parent`
- Value field **should** be singular name of the item being added/removed
- No other required fields

### Strategy 3: Sub-Resource

If both strategies above are too restrictive, consider making list elements their own
sub-resource with full CRUD:

```
POST   /books/1/authors      # Create
GET    /books/1/authors/alice # Get
PATCH  /books/1/authors/alice # Update
DELETE /books/1/authors/alice # Delete
LIST   /books/1/authors       # List with pagination
```

## Decision Table

| Factor | Update | Add/Remove | Sub-Resource |
|--------|--------|------------|-------------|
| List size | Small (<10) | Medium | Large or unbounded |
| Concurrency | ETags sufficient | Atomic needed | Full CRUD needed |
| Declarative-friendly | **Required** | Not allowed | Allowed |
| Element complexity | Simple values | Simple values | Complex objects |
| Individual element access | No | No | Yes |

## Review Checklist

- [ ] Repeated fields use plural names (AIP-144)
- [ ] Upper bound documented and enforced (~100 elements) (AIP-144)
- [ ] No inline resource bodies in repeated fields (AIP-144)
- [ ] Update strategy appropriate for list size and concurrency needs (AIP-144)
- [ ] Declarative-friendly resources use standard Update, not Add/Remove (AIP-128, AIP-144)
