# Backward Compatibility

Reference: [AIP-192](https://google.aip.dev/192)

## Purpose

APIs evolve over time. Understanding what changes are backward-compatible prevents breaking
existing clients. This is especially critical when multiple teams build against shared APIs.

## Breaking Changes (Do NOT make these to a stable API)

### Message/Resource Changes

| Change | Why It Breaks |
|--------|--------------|
| Removing or renaming a field | Existing clients reference the old field |
| Changing a field's type | Serialization/deserialization fails |
| Changing a field number (proto) | Wire format incompatibility |
| Making an optional field required | Existing requests that omit it will fail |
| Changing field behavior (e.g., optional → required) | Existing clients not sending the field |
| Removing an enum value | Clients using that value get errors |
| Changing resource name pattern | Existing stored references break |

### Method Changes

| Change | Why It Breaks |
|--------|--------------|
| Removing an RPC/endpoint | Clients calling it get NOT_FOUND/UNIMPLEMENTED |
| Renaming an RPC | Clients reference the old name |
| Changing HTTP verb (e.g., PUT → PATCH) | Existing client code uses wrong verb |
| Changing URL pattern | Existing URLs stop working |
| Changing error codes for existing conditions | Client error handling breaks |
| Adding required fields to request messages | Existing requests missing the field fail |

### Behavioral Changes

| Change | Why It Breaks |
|--------|--------------|
| Changing default values | Clients relying on old defaults get different behavior |
| Changing validation rules (stricter) | Previously valid requests rejected |
| Changing ordering of list results | Clients relying on order break |
| Removing pagination support | Clients using page_token break |
| Changing semantics of existing fields | Client assumptions invalid |

## Non-Breaking Changes (Safe to make)

### Additive Changes

| Change | Why It's Safe |
|--------|--------------|
| Adding a new optional field | Existing clients ignore it |
| Adding a new RPC/endpoint | Existing clients don't call it |
| Adding a new enum value | Existing clients won't encounter it (but see warning below) |
| Adding a new resource type | No existing references to break |
| Adding a new response field | Existing clients ignore unknown fields |
| Relaxing validation (less strict) | Previously valid requests still valid |

### Warning: New Enum Values

Adding an enum value is technically non-breaking, but can surprise clients that have
exhaustive switches. Recommend clients handle an "unknown" case.

## Versioning Strategy

### Major Versions

For breaking changes, increment the major version:

```
/v1/publishers/123/books    → stable
/v2/publishers/123/books    → breaking changes from v1
```

- Major versions **should** be the first segment of the URL
- Old versions must continue to work during a migration period
- Document the migration path clearly

### Stability Levels

| Level | Breaking Changes Allowed? |
|-------|--------------------------|
| Alpha (v1alpha1) | Yes — expect changes |
| Beta (v1beta1) | Discouraged — should be mostly stable |
| Stable (v1) | No — backward compatibility required |

## Compatibility Checklist for API Changes

Before releasing an API change:

- [ ] No fields removed or renamed
- [ ] No field types changed
- [ ] No optional fields made required
- [ ] No enum values removed
- [ ] No URL patterns changed
- [ ] No HTTP verbs changed
- [ ] No existing error codes changed
- [ ] No default values changed (or change is explicitly documented)
- [ ] No validation rules made stricter
- [ ] New fields are optional with sensible defaults
- [ ] Proto field numbers unchanged

## PATCH Prevents Compatibility Issues (AIP-134)

This is why Google standardizes on PATCH over PUT:

```
# V1 resource: {title, author}
# V2 resource: {title, author, rating}

# PUT from V1 client (doesn't know about rating):
PUT /books/1 {"title": "...", "author": "..."}
→ Wipes out rating! Breaking for V2 clients.

# PATCH from V1 client:
PATCH /books/1 {"title": "..."} updateMask=title
→ Only title updated. Rating preserved. Safe.
```

## gRPC/Proto-Specific

- Never reuse a field number after removing a field (use `reserved`)
- Proto3 handles unknown fields gracefully (ignored, not rejected)
- Adding fields to `oneof` is breaking if clients exhaustively match

```proto
message Book {
  reserved 4;  // Was 'isbn', removed in v1.2
  reserved "isbn";
}
```
