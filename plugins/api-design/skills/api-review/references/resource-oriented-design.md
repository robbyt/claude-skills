# Resource-Oriented Design

References: [AIP-121](https://google.aip.dev/121), [AIP-122](https://google.aip.dev/122), [AIP-123](https://google.aip.dev/123)

## Resource Hierarchies (AIP-121)

Resource-oriented design models APIs as resource hierarchies where each node is either a
simple resource or a collection of resources. The fundamental building blocks:

- **Resources** (nouns) and the relationships between them
- **Standard methods** (verbs) for common operations
- **Stateless protocol** with clear client/server roles

### Design Process

When designing an API, consider (roughly in order):
1. The resources the API will provide
2. The relationships and hierarchies between those resources
3. The schema of each resource
4. The methods each resource provides (prefer standard methods)

### Collections

A collection contains resources of the same type. For example, a publisher has a collection
of books. Resources may have fields and sub-resources (usually collections).

### Methods

Standard methods (Get, List, Create, Update, Delete) **should** be used for the most common
operations. Custom methods are available when standard methods do not fit.

### Strong Consistency

For management plane APIs, completion of a mutating operation **must** mean that:
- The full resource state has reached steady-state
- Reading back the resource returns consistent, up-to-date data
- The resource appears (or disappears) correctly in List results

## Resource Names (AIP-122)

Most resources exposed by an API have a **resource name** that uniquely identifies them within
the API.

### Format

```
publishers/{publisher_id}/books/{book_id}
```

- Resource names **must** be unique within an API
- Resource IDs **should** be user-settable for management plane resources
- Resource IDs are typically the last segment of the resource name
- Resource names are hierarchical, reflecting parent-child relationships

### Full Resource Names

Fully qualified resource names prepend the service name:

```
//library.googleapis.com/publishers/123/books/456
```

### Guidelines

- Resource IDs **should** clearly belong to the parent collection
- IDs **should** be 4-63 characters, matching `/[a-z][a-z0-9-]*/`
- The `name` field on a resource **must** be a string
- The `name` field **should** be the first field in the resource message
- The `name` field **must** be output only (set by the server)

## Resource Types (AIP-123)

Every resource in an API **must** have a unique resource type:

```
library.googleapis.com/Book
```

### Format

`{Service Name}/{Type Name}`

- Service name: the DNS-compatible name of the API service
- Type name: the CamelCase name of the resource (singular)

### Annotations

Resources **must** annotate their type and pattern:

```proto
message Book {
  option (google.api.resource) = {
    type: "library.googleapis.com/Book"
    pattern: "publishers/{publisher}/books/{book}"
  };

  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
}
```

### Cross-references

When a field references another resource, it **must** use `google.api.resource_reference`:

```proto
// Direct type reference
string author = 1 [(google.api.resource_reference) = {
  type: "library.googleapis.com/Author"
}];

// Child type reference (on parent fields)
string parent = 1 [(google.api.resource_reference) = {
  child_type: "library.googleapis.com/Book"
}];
```

## REST/JSON Mapping

For REST APIs, resource names map directly to URLs:

| Resource Name | REST URL |
|--------------|----------|
| `publishers/123` | `/v1/publishers/123` |
| `publishers/123/books/456` | `/v1/publishers/123/books/456` |

The version prefix (`v1`) is part of the URL but not the resource name.
