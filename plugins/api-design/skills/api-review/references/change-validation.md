# Change Validation (Validate-Only)

Reference: [AIP-163](https://google.aip.dev/163)

## Purpose

Allow users to validate an intended change — see what the result would be — without
actually executing it. This is essential for operations with significant consequences:
provisioning infrastructure, modifying billing, altering access control.

## Pattern

Add `bool validate_only` to the request message:

```proto
message CreateServerRequest {
  string parent = 1 [...];
  Server server = 2 [(google.api.field_behavior) = REQUIRED];

  // If set, validate the request and preview the result,
  // but do not actually create the server.
  bool validate_only = 3;
}
```

## Rules

- The API **must** perform full permission checks and validation on validate-only requests
- A validate-only request **must** fail if the actual request would fail
- The API **should** return the same response (status code, headers, body) as a live request
- Auto-generated fields (e.g., system-assigned IDs) **may** be omitted in the response
- Declarative-friendly resources (AIP-128) **must** include `validate_only` on all mutations

## Behavior

| `validate_only` | Result |
|-----------------|--------|
| `false` (default) | Normal execution |
| `true` | Full validation, no side effects, preview response |

## Long-Running Operations (AIP-151)

For validate-only on LRO methods, the response **must** be one of:
1. A completed Operation (`done=true`) with valid response — no server state needed
2. An immediate error response
3. An Operation with `done=false` for long-running validation (must set `name`)

## Use Cases

| Scenario | Why Validate-Only Helps |
|----------|------------------------|
| Provisioning infrastructure | Preview cost/capacity impact before committing |
| Schema migration | Verify migration plan without executing it |
| Access control changes | Confirm who gains/loses access before applying |
| Bulk operations | Validate all items before processing any |
| CI/CD pipelines | Pre-flight checks in deployment pipelines |

## REST/JSON Mapping

The `validate_only` field maps to a query parameter:

```
POST /v1/projects/123/servers?validateOnly=true
{
  "name": "servers/web-1",
  "machineType": "n1-standard-4"
}
```

## Review Checklist

- [ ] Mutation endpoints with significant consequences support `validate_only` (AIP-163)
- [ ] Validate-only performs full permission and validation checks (AIP-163)
- [ ] Declarative-friendly resources include `validate_only` on all mutations (AIP-128)
- [ ] Auto-generated fields may be omitted in validate-only responses (AIP-163)
