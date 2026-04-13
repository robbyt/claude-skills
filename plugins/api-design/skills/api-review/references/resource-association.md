# Resource Association

Reference: [AIP-124](https://google.aip.dev/124)

## Purpose

APIs sometimes have resource hierarchies that cannot be expressed as a clean tree. A resource
may have a many-to-one relationship with two resource types, or a many-to-many relationship
with another type. AIP-124 provides patterns for these cases while preserving the single-parent
tree constraint.

## Core Rule: One Canonical Parent

Every resource **must** have at most one canonical parent. List requests **must not** require
two distinct parent fields. When a resource relates to multiple other resources, choose one
as the canonical parent and reference the others through fields.

```proto
message Book {
  option (google.api.resource) = {
    type: "library.googleapis.com/Book"
    pattern: "publishers/{publisher}/books/{book}"
  };

  string name = 1 [(google.api.field_behavior) = IDENTIFIER];

  // Secondary association via resource reference
  string author = 2 [(google.api.resource_reference) = {
    type: "library.googleapis.com/Author"
  }];
}
```

To list books by a secondary association, use filter expressions (AIP-160):

```
GET /v1/publishers/-/books?filter=author="authors/twain"
```

## Many-to-Many Patterns

### Simple Case: Repeated Resource References

When no metadata is needed on the relationship, use a repeated field:

```proto
message Book {
  repeated string authors = 2 [(google.api.resource_reference) = {
    type: "library.googleapis.com/Author"
  }];
}
```

### With Relationship Metadata: Association Sub-Resource

When the relationship carries its own data (role, timestamp, permissions), model it as a
sub-resource under one side:

```proto
message BookAuthor {
  option (google.api.resource) = {
    type: "library.googleapis.com/BookAuthor"
    pattern: "publishers/{publisher}/books/{book}/authors/{book_author}"
  };

  string name = 1 [(google.api.field_behavior) = IDENTIFIER];

  string author = 2 [(google.api.resource_reference) = {
    type: "library.googleapis.com/Author"
  }];

  // Relationship metadata
  string role = 3;  // e.g., "primary", "editor", "translator"
}
```

## Anti-Patterns

### Multiple required parents in List
**Wrong**: `ListBooks(publisher, author)` requiring both parents
**Right**: One canonical parent (`publisher`), filter by secondary (`?filter=author="..."`)

### Flattening relationships that need metadata
**Wrong**: Repeated author field when you also need role/contribution data
**Right**: Association sub-resource (`BookAuthor`) with metadata fields

### No canonical parent
**Wrong**: Resource that can be listed under either parent interchangeably
**Right**: Choose one canonical parent; use wildcard `-` (AIP-159) for cross-parent queries

## Review Checklist

- [ ] Each resource has exactly one canonical parent (AIP-124)
- [ ] Secondary associations use resource references, not extra parent fields (AIP-124)
- [ ] List requests have a single parent field (AIP-124)
- [ ] Many-to-many with metadata uses association sub-resources (AIP-124)
- [ ] Cross-parent queries use filter (AIP-160) or wildcard (AIP-159), not dual parents
