# Partial Responses

Reference: [AIP-157](https://google.aip.dev/157)

## Purpose

When resources are large or expensive to compute, give users control over which fields
are returned. This reduces payload size, avoids expensive computation, and improves latency.

## Two Approaches

### 1. Field Mask Parameter (Preferred)

Specify a `FieldMask` as a system parameter (HTTP header, query parameter, or gRPC metadata)
rather than a request field:

```
GET /v1/publishers/123/books/456?fields=title,author
```

#### Rules

- **Should not** be a field on the request message (use side channel)
- **Must** be optional
- `"*"` **must** return all fields
- Omitted mask **must** default to `"*"` (unless otherwise documented)
- **May** allow non-terminal repeated fields (unlike update masks)

**Warning:** Changing the default value of the field mask parameter is a breaking
change (AIP-180).

### 2. View Enumeration

For APIs wanting to limit the number of permutations:

```proto
enum BookView {
  BOOK_VIEW_UNSPECIFIED = 0;  // Defaults to BASIC
  BOOK_VIEW_BASIC = 1;        // Metadata only
  BOOK_VIEW_FULL = 2;         // Everything
}
```

```proto
message GetBookRequest {
  string name = 1 [...];
  BookView view = 2;
}
```

#### Rules

- Enum name **should** end in `View`
- **Should** have at minimum `BASIC` and `FULL` values
- `UNSPECIFIED` **must** be valid (not an error)
- For List: default **should** be `BASIC`
- For Get/Create/Update: default **should** be `BASIC` or `FULL`
- Defined at top level of proto file (reused across Get and List)
- Fields **may** be added to a view over time; fields **must not** be removed (breaking)

**Declarative client warning:** Having partial responses as the default for standard
methods can degrade declarative client effectiveness. If partial responses are needed,
provide a mechanism to request the full resource (like the View pattern).

### 3. Read Mask on Request (Deprecated)

Legacy approach using `google.protobuf.FieldMask read_mask` directly on the request
message. New APIs **should** use the system parameter approach instead.

## When to Use Which

| Approach | Use When |
|----------|----------|
| **Field mask parameter** | Fine-grained control needed; many possible field combinations |
| **View enum** | Small number of useful permutations (e.g., summary vs full) |
| **Neither** | Resources are small and cheap to compute |

## Common Patterns

### List Returns BASIC, Get Returns FULL

```
GET /v1/books                    → BASIC view (title, author, name)
GET /v1/books/456                → FULL view (everything)
GET /v1/books/456?view=BASIC     → BASIC view explicitly
```

### Expensive Computed Fields

```proto
message AnalyticsReport {
  string name = 1;
  string title = 2;                    // Always returned
  ReportSummary summary = 3;           // BASIC view
  repeated DetailedMetric metrics = 4; // FULL view only (expensive)
  bytes raw_data = 5;                  // FULL view only (large)
}
```

## Review Checklist

- [ ] Large resources support partial responses (AIP-157)
- [ ] View enum has `BASIC` and `FULL` at minimum (AIP-157)
- [ ] `UNSPECIFIED` view is valid with documented default behavior (AIP-157)
- [ ] List defaults to `BASIC` view for efficiency (AIP-157)
- [ ] Default value changes documented as breaking (AIP-180)
