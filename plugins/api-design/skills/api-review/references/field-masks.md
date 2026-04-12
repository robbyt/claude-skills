# Field Masks

Reference: [AIP-161](https://google.aip.dev/161)

## Purpose

Field masks serve two purposes in APIs:

1. **Partial update** (on Update requests): specify which fields to modify
2. **Partial response** (on Get/List requests): specify which fields to return

## Partial Update (AIP-134)

The `update_mask` on Update requests controls which fields are written:

```proto
message UpdateBookRequest {
  Book book = 1 [(google.api.field_behavior) = REQUIRED];
  google.protobuf.FieldMask update_mask = 2;
}
```

### Behavior

| `update_mask` value | Effect |
|--------------------|--------|
| `"title"` | Only update the title field |
| `"title,author"` | Update title and author |
| `"*"` | Full replacement (like PUT) |
| Omitted/empty | Implied mask = all populated fields |

### Rules

- Fields in the mask refer to the resource, not the request message
- Omitted mask **must** be treated as "all populated fields"
- `*` mask **must** be supported for full replacement
- Fields not in the mask **must not** be modified
- OUTPUT_ONLY fields in the mask **should** be ignored

### Nested Fields

Use dot notation for nested fields:

```
update_mask: "address.city,address.state"
```

### Repeated Fields

For repeated (array) fields, the entire list is replaced — there is no way to add/remove
individual elements via field mask. The full list must be sent.

## Partial Response (AIP-157)

For Get and List, a `read_mask` controls which fields are returned:

```proto
message GetBookRequest {
  string name = 1 [...];
  google.protobuf.FieldMask read_mask = 2;
}
```

### Benefits

- Reduces response payload size
- Avoids computing expensive fields
- Improves latency for large resources

### Rules

- If `read_mask` is omitted, return the full resource
- If specified, only return listed fields (plus `name` always)
- Invalid field paths **should** return `INVALID_ARGUMENT`

## REST/JSON Mapping

In REST APIs, field masks are typically query parameters:

```
# Partial update — only change title
PATCH /v1/publishers/123/books/456?updateMask=title
{"title": "New Title"}

# Partial response — only return title and author
GET /v1/publishers/123/books/456?readMask=title,author
```

## Common Anti-Patterns

### No field mask on Update
**Problem**: Every update replaces the entire resource (PUT semantics).
**Fix**: Add `update_mask` to the request. Omitted mask = update populated fields.

### Requiring `*` for full update
**Problem**: Clients must know about `*` to do simple updates.
**Fix**: Omitted mask should default to "all populated fields" — the common case.

### Ignoring field mask on response
**Problem**: Server returns full resource despite `read_mask`.
**Fix**: Honor the mask; return only requested fields plus `name`.

## OpenAPI/REST Equivalent

For REST APIs without protobuf, implement field masks as query parameters:

```yaml
parameters:
  - name: updateMask
    in: query
    description: "Comma-separated list of fields to update"
    schema:
      type: string
  - name: fields
    in: query
    description: "Comma-separated list of fields to return"
    schema:
      type: string
```

Google's JSON API convention uses `fields` for response masking and `updateMask` for
update operations.
