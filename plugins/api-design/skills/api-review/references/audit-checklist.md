# API Design Audit Checklist

Comprehensive checklist for reviewing APIs against AIP standards. Organized by severity.
Each item includes the relevant AIP, what to look for, and how to fix it.

## CRITICAL — Concurrency & Data Safety

### C1: No ETags on mutable resources (AIP-154)
**Look for**: Resources that can be updated or deleted but have no `etag` field.
**Risk**: TOCTOU race conditions. Concurrent writes silently overwrite each other.
**Fix**: Add `string etag` to the resource. Return it on all responses. Check it on Update
and Delete. Return `ABORTED` (409) on mismatch.

### C2: No idempotency on Create/mutation (AIP-155)
**Look for**: Create and custom mutating methods without `request_id` field.
**Risk**: Network retry creates duplicate resources or triggers duplicate side effects.
**Fix**: Add `string request_id` (UUID4 format) to request messages. Deduplicate server-side.

### C3: Using PUT instead of PATCH (AIP-134)
**Look for**: HTTP `PUT` on update endpoints.
**Risk**: Adding new fields to the resource breaks existing clients (they unknowingly erase
new fields).
**Fix**: Switch to `PATCH` with `update_mask`. Support `*` mask for full-replacement use case.

### C4: State transitions via Update (AIP-216, AIP-136)
**Look for**: State/status fields that are writable via PATCH/PUT.
**Risk**: State transitions have business logic and side effects that bypass validation.
**Fix**: Make state fields OUTPUT_ONLY. Create custom methods for transitions (`:activate`,
`:suspend`, `:archive`).

### C5: BFF contains database connections
**Look for**: SQL imports, ORM configuration, connection pool setup in BFF code.
**Risk**: BFF owns data integrity. Schema changes break the BFF. No contract enforcement.
**Fix**: Move all data access to backend API. BFF calls API endpoints only.

## HIGH — Resource Design

### H1: Table-level CRUD instead of business operations (AIP-136)
**Look for**: APIs that mirror database tables 1:1 with only CRUD operations.
**Risk**: Callers must assemble business logic from raw data. Logic duplicated across clients.
**Fix**: Design APIs around domain operations. Use custom methods for business actions.

### H2: Non-hierarchical resource names (AIP-122)
**Look for**: Flat IDs, GUIDs without parent context, or inconsistent naming.
**Risk**: No clear ownership hierarchy. Harder to reason about permissions and scope.
**Fix**: Use hierarchical names: `publishers/{publisher}/books/{book}`.

### H3: Missing field behavior annotations (AIP-203)
**Look for**: Fields with no documentation of required/optional/output_only behavior.
**Risk**: Clients guess incorrectly. Some send output_only fields, others omit required ones.
**Fix**: Annotate every field. For REST APIs, document in OpenAPI `required` and `readOnly`.

### H4: Custom methods using wrong HTTP verb (AIP-136)
**Look for**: Custom methods using GET for mutations, or POST for read-only operations.
**Risk**: Caching proxies cache GET mutations. POST read-only ops miss CDN caching.
**Fix**: GET for read-only, POST for side effects.

### H5: Missing standard methods (AIP-121)
**Look for**: Resources that lack Get, List, or Delete when those operations make sense.
**Risk**: Clients work around missing methods with fragile alternatives.
**Fix**: Implement standard methods. Get and List are almost always needed.

## MEDIUM — Usability & Evolution

### M1: No pagination on List (AIP-158)
**Look for**: List endpoints that return all results without `page_size`/`page_token`.
**Risk**: Works fine until the collection grows. Then responses become huge, slow, and
memory-intensive. Pagination is a breaking change to add later.
**Fix**: Always include pagination fields, even for small collections.

### M2: Generic error responses (AIP-193)
**Look for**: All errors returning 500, or 200 with error body, or missing error details.
**Risk**: Clients can't retry intelligently. Debugging is impossible. UX suffers.
**Fix**: Use standard error codes. Include structured error details.

### M3: PERMISSION_DENIED leaks existence (AIP-193)
**Look for**: Unauthorized users getting NOT_FOUND instead of PERMISSION_DENIED.
**Risk**: Attackers can enumerate resources by checking which return 404 vs 403.
**Fix**: Always check permission first. Return PERMISSION_DENIED if unauthorized.

### M4: No backward compatibility assessment (AIP-192)
**Look for**: API changes that remove fields, change types, or add required fields.
**Risk**: Existing clients break on deploy.
**Fix**: Only make additive changes. Use versioning for breaking changes.

### M5: Long operations block request (AIP-151)
**Look for**: API calls that take >10 seconds and don't return an Operation object.
**Risk**: Client timeouts, retries that duplicate work, poor UX.
**Fix**: Return `google.longrunning.Operation` for slow methods.

## LOW — Polish & Best Practices

### L1: No filtering support (AIP-160)
**Look for**: List endpoints without `filter` parameter when users clearly need to query.
**Fix**: Add `string filter` with documented expression syntax.

### L2: No field masks (AIP-161)
**Look for**: Update endpoints without `update_mask`; Get endpoints returning huge payloads.
**Fix**: Add `update_mask` to Update. Consider `read_mask` for expensive resources.

### L3: No soft delete (AIP-164)
**Look for**: Resources that are expensive to recreate with only hard delete available.
**Fix**: Implement soft delete with `delete_time`, `expire_time`, and Undelete method.

### L4: No batch methods (AIP-235)
**Look for**: Clients making many individual requests in loops.
**Fix**: Add BatchGet, BatchCreate as needed.

### L5: Inconsistent naming (AIP-122)
**Look for**: Mixed naming conventions (camelCase vs snake_case, plural vs singular).
**Fix**: Follow AIP conventions: snake_case in proto, camelCase in JSON, plural collections.

## Risk Scoring

Calculate risk score for audit prioritization:

```
Score = (CRITICAL × 5) + (HIGH × 3) + (MEDIUM × 2) + (LOW × 1)
```

| Score | Rating | Action |
|-------|--------|--------|
| 0 | Excellent | Ship it |
| 1–5 | Good | Address before next release |
| 6–15 | Needs Work | Address before integration |
| 16–30 | High Risk | Block integration until resolved |
| 31+ | Critical | Architectural redesign required |

## Quick Review Template

```markdown
## API Design Review: [Service Name]

**Reviewer**: [Name]
**Date**: [Date]
**Score**: [X] (CRITICAL: X, HIGH: X, MEDIUM: X, LOW: X)

### Critical Issues
- [ ] C1: ETags — [status]
- [ ] C2: Idempotency — [status]
- [ ] C3: PATCH vs PUT — [status]
- [ ] C4: State transitions — [status]
- [ ] C5: BFF boundaries — [status]

### High Issues
- [ ] H1-H5: [findings]

### Medium Issues
- [ ] M1-M5: [findings]

### Recommendations
1. [Highest priority fix]
2. [Next priority]
3. [...]

### AIP References Cited
- AIP-XXX: [reason]
```
