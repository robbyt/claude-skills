# ETags and Resource Freshness Validation

Reference: [AIP-154](https://google.aip.dev/154)

## Purpose

ETags solve the **TOCTOU (Time-of-Check to Time-of-Use) problem**: two processes reading the
same resource, then both writing back changes, where the second write silently overwrites
the first. ETags provide optimistic concurrency control.

## How It Works

1. Server computes a checksum (etag) based on the resource's current content
2. Server returns the etag with every resource response
3. Client sends the etag back on mutation requests (Update, Delete)
4. Server compares: if etags match, proceed; if not, reject with `ABORTED` (409)

## Resource Field

```proto
message Book {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  string title = 2;
  string author = 3;

  // Computed by server. Send on update/delete to ensure freshness.
  string etag = 99;
}
```

### Rules

- **Must** be a string named `etag`
- **Must** be provided by the server on output
- Values **should** conform to [RFC 7232](https://tools.ietf.org/html/rfc7232#section-2.3)
- Values **should** include quotes: `"foo"`, not `foo`
- On the resource itself, **should not** have behavior annotations

## Behavior on Requests

| Client sends | Etag matches? | Result |
|-------------|---------------|--------|
| Correct etag | Yes | Request proceeds |
| Wrong etag | No | `ABORTED` (HTTP 409) |
| No etag | N/A | Generally permitted* |

*Services with strong consistency needs **may** require etags and reject with
`INVALID_ARGUMENT` when omitted.

**Priority**: Other errors (e.g., `PERMISSION_DENIED`) take precedence over etag mismatch.

## ETags on Request Messages

For methods like Delete that don't carry the resource in the body, the etag goes on
the request message:

```proto
message DeleteBookRequest {
  string name = 1 [
    (google.api.field_behavior) = REQUIRED,
    (google.api.resource_reference) = {
      type: "library.googleapis.com/Book"
    }];
  string etag = 2 [(google.api.field_behavior) = OPTIONAL];
}
```

On request messages, the etag field **should** have a behavior annotation (REQUIRED or
OPTIONAL).

## Strong vs Weak ETags

| Type | Meaning | Prefix | Use When |
|------|---------|--------|----------|
| **Strong** | Byte-for-byte identical | None | Exact content matters |
| **Weak** | Semantically equivalent | `W/` | Minor variations acceptable |

Weak etags **must** use the `W/` prefix per RFC 7232. Document which type the API uses.

## Declarative-Friendly Resources (AIP-128)

Declarative-friendly resources **must** include an etag field. This is required because
declarative tools need a reliable mechanism to detect concurrent modifications.

## Common Anti-Patterns

### No etag on mutable resources
**Problem**: Two clients read the same resource, both update it — second write silently
overwrites the first.
**Fix**: Add `string etag` to the resource. Return it on all responses. Check it on mutations.

### Using FAILED_PRECONDITION instead of ABORTED
**Problem**: Historical Google APIs used `FAILED_PRECONDITION` (HTTP 400) for etag mismatches.
**Fix**: Per updated AIP-154, use `ABORTED` (HTTP 409) which semantically indicates a
concurrency conflict that can be resolved by re-reading and retrying.

### Etag on resource but not checked on delete
**Problem**: Resource has etag but Delete doesn't accept it — deletes can't be protected.
**Fix**: Add `string etag` to DeleteRequest (AIP-135).

### Client caches etag but resource is updated server-side
**Problem**: Background process updates resource; client's cached etag is stale.
**Fix**: This is working as designed — client should re-read before retrying. The ABORTED
error tells the client exactly what happened.

## TOCTOU Prevention Pattern

The complete flow for preventing race conditions:

```
Client A: GET /books/1          → {title: "v1", etag: "abc"}
Client B: GET /books/1          → {title: "v1", etag: "abc"}
Client A: PATCH /books/1        → {title: "v2", etag: "abc"}  ✓ Success, new etag: "def"
Client B: PATCH /books/1        → {title: "v3", etag: "abc"}  ✗ ABORTED (409)
Client B: GET /books/1          → {title: "v2", etag: "def"}  (re-read)
Client B: PATCH /books/1        → {title: "v3", etag: "def"}  ✓ Success
```

The client's retry loop:
1. Read the resource (get current etag)
2. Make changes locally
3. Send mutation with etag
4. If ABORTED: go to step 1
5. If success: done
