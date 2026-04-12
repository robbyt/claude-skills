# Error Handling

Reference: [AIP-193](https://google.aip.dev/193)

## Standard Error Codes

APIs **must** use standard error codes. These map to HTTP status codes:

| gRPC Code | HTTP | When to Use |
|-----------|------|------------|
| `OK` | 200 | Success |
| `INVALID_ARGUMENT` | 400 | Client sent bad data (malformed request, invalid field values) |
| `FAILED_PRECONDITION` | 400 | Request valid but system not in required state (child resources exist) |
| `OUT_OF_RANGE` | 400 | Value outside acceptable range (negative page_size) |
| `UNAUTHENTICATED` | 401 | No valid credentials provided |
| `PERMISSION_DENIED` | 403 | Valid credentials but insufficient permissions |
| `NOT_FOUND` | 404 | Resource does not exist |
| `ABORTED` | 409 | Concurrency conflict (etag mismatch, parallel operation rejected) |
| `ALREADY_EXISTS` | 409 | Resource with same name already exists |
| `RESOURCE_EXHAUSTED` | 429 | Quota or rate limit exceeded |
| `CANCELLED` | 499 | Client cancelled the request |
| `INTERNAL` | 500 | Unexpected server error |
| `UNIMPLEMENTED` | 501 | Method not implemented |
| `UNAVAILABLE` | 503 | Service temporarily unavailable (transient, safe to retry) |
| `DEADLINE_EXCEEDED` | 504 | Operation took too long |

## PERMISSION_DENIED vs NOT_FOUND

This is a critical distinction (AIP-193):

1. **Always check permission first**, before checking existence
2. If user lacks permission: return `PERMISSION_DENIED` (403)
   - This prevents information leakage about resource existence
3. If user has permission but resource doesn't exist: return `NOT_FOUND` (404)

```
User without permission → GET /books/secret → 403 PERMISSION_DENIED
User with permission    → GET /books/missing → 404 NOT_FOUND
```

**Never** return `NOT_FOUND` to a user who lacks permission — that reveals the resource
doesn't exist, which itself may be sensitive information.

## Error Response Structure

```json
{
  "error": {
    "code": 409,
    "message": "The resource has been modified. Re-read and retry.",
    "status": "ABORTED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "ETAG_MISMATCH",
        "domain": "library.googleapis.com",
        "metadata": {
          "resource": "publishers/123/books/456",
          "currentEtag": "\"def\"",
          "providedEtag": "\"abc\""
        }
      }
    ]
  }
}
```

## Error Details

Standard error detail types:

| Type | Purpose | Example |
|------|---------|---------|
| `ErrorInfo` | Machine-readable error reason | `reason: "ETAG_MISMATCH"` |
| `BadRequest` | Field-level validation errors | `field: "title", description: "too long"` |
| `PreconditionFailure` | Precondition violations | `type: "TOS", subject: "user/123"` |
| `RetryInfo` | Retry guidance | `retry_delay: "30s"` |
| `QuotaFailure` | Quota exceeded details | `subject: "project:123", limit: 100` |
| `ResourceInfo` | Resource that caused error | `type: "Book", name: "books/456"` |

## Error Handling by Method

| Method | Common Errors |
|--------|--------------|
| Get | PERMISSION_DENIED, NOT_FOUND |
| List | PERMISSION_DENIED, NOT_FOUND (parent), INVALID_ARGUMENT (bad filter/page) |
| Create | PERMISSION_DENIED, NOT_FOUND (parent), ALREADY_EXISTS, INVALID_ARGUMENT |
| Update | PERMISSION_DENIED, NOT_FOUND, ABORTED (etag), INVALID_ARGUMENT |
| Delete | PERMISSION_DENIED, NOT_FOUND, ABORTED (etag), FAILED_PRECONDITION (children) |
| Custom | PERMISSION_DENIED, NOT_FOUND, FAILED_PRECONDITION, INVALID_ARGUMENT |

## Retryable Errors

| Error | Retryable? | Strategy |
|-------|-----------|----------|
| `UNAVAILABLE` | Yes | Exponential backoff |
| `DEADLINE_EXCEEDED` | Maybe | Increase timeout, then retry |
| `ABORTED` | Yes | Re-read resource, re-apply changes, retry |
| `RESOURCE_EXHAUSTED` | Yes | Wait for `RetryInfo.retry_delay`, then retry |
| `INTERNAL` | Maybe | Retry with backoff; escalate if persistent |
| All others | No | Fix the request |

## Anti-Patterns

### Generic 500 for everything
**Problem**: All errors return 500 Internal Server Error.
**Fix**: Use specific codes. Clients can't retry intelligently without them.

### 200 with error body
**Problem**: HTTP 200 but response body contains an error object.
**Fix**: Use appropriate HTTP status codes. Error responses use 4xx/5xx.

### Leaking internals in error messages
**Problem**: Error messages expose stack traces, SQL queries, or internal paths.
**Fix**: Return user-friendly messages. Log internal details server-side.

### NOT_FOUND for unauthorized users
**Problem**: Unauthorized user gets 404, confirming resource existence when they get 403 elsewhere.
**Fix**: Always return PERMISSION_DENIED for unauthorized users, regardless of existence.
