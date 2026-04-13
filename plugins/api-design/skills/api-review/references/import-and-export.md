# Import and Export

Reference: [AIP-153](https://google.aip.dev/153)

## Purpose

Enterprise users need to load data into an API and extract data out. Import and export
operations move bulk data between an API and external systems (storage buckets, other APIs,
inline payloads). These are long-running custom methods with specific patterns for source/
destination configuration.

## Two Patterns

### Multiple Resources (Parent-Based)

Import or export an entire collection of resources under a parent:

```proto
rpc ImportBooks(ImportBooksRequest)
    returns (google.longrunning.Operation) {
  option (google.api.http) = {
    post: "/v1/{parent=publishers/*}/books:import"
    body: "*"
  };
}

message ImportBooksRequest {
  string parent = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      child_type: "library.googleapis.com/Book"
    }
  ];

  oneof source {
    GcsSource gcs_source = 2;
    InlineSource inline_source = 3;
  }

  // Common data configuration at top level
  string isbn_prefix = 4;
}
```

- URI suffix: `:import` or `:export`
- **Must** include `parent` in URI
- Imported resources targeting a different parent **must** be rejected

### Single Resource (Resource-Based)

Populate or extract data within a single resource:

```proto
rpc ImportPages(ImportPagesRequest)
    returns (google.longrunning.Operation) {
  option (google.api.http) = {
    post: "/v1/{book=publishers/*/books/*}:importPages"
    body: "*"
  };
}
```

- URI suffix includes verb + noun: `:importPages`, `:exportPages`
- Resource identifier field named after the resource (not `name`)

## Source and Destination Configuration

Use `oneof` to wrap source/destination options:

```proto
message ExportBooksRequest {
  string parent = 1 [...];

  oneof destination {
    GcsDestination gcs_destination = 2;
    BigQueryDestination bigquery_destination = 3;
  }
}
```

### Inline Sources

For small payloads, support inline data:

```proto
message InlineSource {
  repeated Book books = 1;
}
```

- **Should** be named `InlineSource` or `InlineDestination`
- **Should** contain a repeated field for the resources

## Key Rules

- **Must** return a long-running operation (unless guaranteed to complete in seconds)
- **Must** use HTTP `POST` with body `"*"`
- **May** allow `-` wildcard in parent for cross-collection import (AIP-159)
- Source/destination config goes in `oneof`; common data config at request top level
- **Should** include partial failure info in LRO metadata as `repeated google.rpc.Status`

## REST Examples

```
# Import books from Cloud Storage
POST /v1/publishers/acme/books:import
{
  "gcsSource": { "uri": "gs://bucket/books.json" },
  "isbnPrefix": "978-0"
}

# Export books to BigQuery
POST /v1/publishers/acme/books:export
{
  "bigqueryDestination": {
    "dataset": "projects/p/datasets/d",
    "table": "books"
  }
}

# Import inline
POST /v1/publishers/acme/books:import
{
  "inlineSource": {
    "books": [
      {"title": "Book One", "author": "authors/twain"},
      {"title": "Book Two", "author": "authors/austen"}
    ]
  }
}
```

## Anti-Patterns

### Synchronous bulk operations
**Wrong**: Blocking request that times out on large datasets
**Right**: Return LRO; client polls for completion

### Missing oneof for source/destination
**Wrong**: Flat fields `gcs_uri`, `bigquery_table` at top level
**Right**: `oneof source { GcsSource, InlineSource }` grouping

### No partial failure reporting
**Wrong**: Entire import fails silently on one bad record
**Right**: LRO metadata includes `repeated google.rpc.Status` with per-record errors

## Review Checklist

- [ ] Import/export returns long-running operation (AIP-153, AIP-151)
- [ ] Uses POST with `:import`/`:export` suffix (AIP-153)
- [ ] Source/destination wrapped in oneof (AIP-153)
- [ ] Common data config at request top level, not inside source (AIP-153)
- [ ] Inline source uses `InlineSource` naming convention (AIP-153)
- [ ] Partial failures reported in LRO metadata (AIP-153)
- [ ] Single-resource variant uses verb+noun suffix (`:importPages`) (AIP-153)
