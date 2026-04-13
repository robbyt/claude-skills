# Retry Strategy

Reference: [AIP-194](https://google.aip.dev/194)

## When to Retry

Automatic retries are appropriate only for:
- **Non-transactional** requests (no multi-step transaction context)
- **Stateless unary** requests (not streaming)
- **Repeated runs would not cause unintended state changes**

For transactional requests, retry the **entire transaction**, not individual RPCs.

## Retry Classification by Error Code

### Retryable — Always Safe to Retry

| Code | HTTP | Meaning | Strategy |
|------|------|---------|----------|
| `UNAVAILABLE` | 503 | Network hiccup, transient | Exponential backoff |

### Never Retry — Fix the Request

| Code | HTTP | Meaning | Why Not |
|------|------|---------|---------|
| `OK` | 200 | Success | Already succeeded |
| `CANCELLED` | 499 | Client cancelled | Must be honored |
| `DEADLINE_EXCEEDED` | 504 | Timeout | Must be honored |
| `INVALID_ARGUMENT` | 400 | Bad input | Will never succeed |
| `DATA_LOSS` | 500 | Unrecoverable | Surface immediately |

### Generally Do Not Retry — Requires Higher-Level Action

| Code | HTTP | Meaning | What to Do Instead |
|------|------|---------|-------------------|
| `ABORTED` | 409 | Concurrency conflict (etag mismatch) | Re-read resource, re-apply changes, retry whole operation |
| `RESOURCE_EXHAUSTED` | 429 | Quota/rate limit | Wait for `RetryInfo.retry_delay`; may be hours |
| `INTERNAL` | 500 | Server bug | Surface to application; file a bug |
| `UNKNOWN` | 500 | Truly unknown error | Surface to application |
| `NOT_FOUND` | 404 | Resource missing | Don't retry until resource created |
| `ALREADY_EXISTS` | 409 | Duplicate | Don't retry until resource deleted |
| `PERMISSION_DENIED` | 403 | Insufficient permission | Don't retry until permission granted |
| `UNAUTHENTICATED` | 401 | No/invalid credentials | Don't retry until authenticated |
| `FAILED_PRECONDITION` | 400 | System state wrong | Don't retry until state changes |
| `OUT_OF_RANGE` | 400 | Value outside range | Don't retry until range extended |
| `UNIMPLEMENTED` | 501 | Not implemented | Don't retry until implemented |

## Exponential Backoff Pattern

For retryable errors (primarily `UNAVAILABLE`):

```
attempt 1: wait 0ms         (immediate)
attempt 2: wait 1000ms      (1s + jitter)
attempt 3: wait 2000ms      (2s + jitter)
attempt 4: wait 4000ms      (4s + jitter)
attempt 5: wait 8000ms      (8s + jitter)
...
max delay: 30-60 seconds
max attempts: 5-10
```

Always add random jitter to prevent thundering herd.

## Relationship to Other AIPs

| AIP | Interaction with Retry |
|-----|----------------------|
| AIP-154 (ETags) | `ABORTED` from etag mismatch → re-read, re-apply, retry at application level |
| AIP-155 (Request IDs) | Include `request_id` to make retries idempotent; server deduplicates |
| AIP-151 (LROs) | Don't retry the initial call; poll the operation instead |
| AIP-193 (Errors) | Use `RetryInfo` error detail for server-recommended delay |

## Client Implementation Guidance

### With Request IDs (AIP-155)

```
request_id = generate_uuid4()
for attempt in range(max_retries):
    response = call_api(request_id=request_id, ...)
    if response.ok:
        return response
    if response.code == UNAVAILABLE:
        sleep(backoff_with_jitter(attempt))
        continue
    if response.code == ABORTED:
        # Re-read the resource, get fresh etag, re-apply changes
        resource = get_resource(...)
        apply_changes(resource)
        request_id = generate_uuid4()  # New logical operation
        continue
    raise ApiError(response)
```

### Key Points

- Always use the **same** `request_id` when retrying the same logical operation
- Generate a **new** `request_id` when re-reading and re-applying after ABORTED
- `ABORTED` retry loops should have a cap to prevent infinite retry cycles

## Review Checklist

- [ ] Client retry logic only retries `UNAVAILABLE` automatically (AIP-194)
- [ ] `ABORTED` (etag mismatch) triggers re-read + re-apply, not blind retry (AIP-154, AIP-194)
- [ ] `RESOURCE_EXHAUSTED` not retried automatically (may be quota, not transient) (AIP-194)
- [ ] `INTERNAL`/`UNKNOWN` surfaced to application, not silently retried (AIP-194)
- [ ] Exponential backoff with jitter used for retries (AIP-194)
- [ ] Request IDs included on mutations for idempotent retries (AIP-155)
