# Authorization Checks

Reference: [AIP-211](https://google.aip.dev/211)

## Core Rule

Services **must** check authorization before validating any request. This ensures a
secure API surface and consistent user experience.

## Authorization Flow

```
Request received
  → Check authorization FIRST
    → Fails? Return PERMISSION_DENIED (403)
  → Check if resource exists
    → Not found? Return NOT_FOUND (404)
  → Validate request
    → Invalid? Return INVALID_ARGUMENT (400)
  → Execute operation
```

## Error Message Format

When authorization fails, the error message **should** follow this pattern:

```
Permission '{permission}' denied on resource '{resource}' (or it might not exist).
```

The "(or it might not exist)" suffix is critical — it prevents leaking information about
whether a resource exists to unauthorized users.

## Why This Order Matters

### Information Leakage Prevention

If an unauthorized user sends:
```
GET /v1/projects/secret-project/databases/customer-db
```

| Wrong Approach | Risk |
|----------------|------|
| Check existence first, return NOT_FOUND | Attacker learns the resource doesn't exist |
| Return NOT_FOUND for some, PERMISSION_DENIED for others | Attacker enumerates which resources exist |

| Correct Approach | Result |
|-----------------|--------|
| Always check auth first, return PERMISSION_DENIED | No information leaked about existence |

### Consistency

Users should never see different error codes for the same lack of permission based on
whether the resource happens to exist. `PERMISSION_DENIED` means "you can't do this" —
always.

## When Resource Doesn't Exist

If authorization cannot be determined because the resource doesn't exist:
- Check authorization to read children on the **parent** resource
- If that passes, return `NOT_FOUND` (the user has enough permission to know it's missing)
- If that fails, return `PERMISSION_DENIED`

## Multiple Operations

When a service has two operations with different permissions that could both reveal
resource existence:

- Only check the permission for the operation being called
- Do **not** check related permissions to "help out"
- Cross-checking permissions is complex, error-prone, and risks accidental information leaks

### Example

A user can create resources (and would get `ALREADY_EXISTS` revealing a duplicate) but
cannot read them. The Create method should only check Create permission, not Read
permission, when deciding what error to return.

## Why Not 404 for Unauthorized Users?

RFC 7231 permits using 404 instead of 403 to hide existence, but AIP-211 recommends
against this because:

1. "Getting 404 until you have enough permission to get 403" is counter-intuitive
2. 404 is often a valid, actionable response (e.g., "get or create"); overloading it
   for permission errors removes this benefit
3. 404 responses are cacheable by default; permission errors should not be cached
4. Using 403 consistently is more aligned with real-world authorization systems

## Centralized Authorization

From the BFF architecture principles: authorization belongs in a centralized service
(e.g., SpiceDB/Zanzibar), not scattered across individual BFFs or services.

Backend APIs call the AuthZ service; the BFF forwards tokens but does not make
authorization decisions.

## Review Checklist

- [ ] Authorization checked before any other validation (AIP-211)
- [ ] PERMISSION_DENIED (403) returned for unauthorized users, regardless of resource existence (AIP-211)
- [ ] Error message includes "(or it might not exist)" to prevent existence leakage (AIP-211)
- [ ] NOT_FOUND (404) only returned to users who have sufficient permission (AIP-193, AIP-211)
- [ ] Each operation only checks its own permissions, not related ones (AIP-211)
- [ ] Authorization is centralized, not per-team/per-BFF
