# Server-Modified Values and Defaults

Reference: [AIP-129](https://google.aip.dev/129)

## Purpose

Services often provide default values for resource fields or normalize user input before
returning it. Clear field ownership rules prevent surprises for clients and ensure
declarative tools (Terraform, Pulumi) work correctly.

## Core Rule: Single Field Ownership

Every field **must** have a single owner -- either the client or the server:

- **Client-owned fields**: The service **must** return the client's value unchanged
- **Server-owned fields**: Annotated `OUTPUT_ONLY` (AIP-203), set exclusively by the service

A service **must not** silently modify client-owned field values. If a client sends
`ip_address: "10.0.0.1"`, the response **must** return `ip_address: "10.0.0.1"`.

## Effective Values Pattern

When the server computes, allocates, or generates the actual value used (e.g., auto-assigned
IP, computed schedule), model it as two fields:

```proto
message VirtualMachine {
  // Client-owned: the requested IP (may be empty for auto-assign)
  string ip_address = 4;

  // Server-owned: the actual IP in use
  string effective_ip_address = 5 [
    (google.api.field_behavior) = OUTPUT_ONLY
  ];
}
```

The effective field **must** be named `effective_{mutable_field_name}`.

## Normalization Rules

A service **may** normalize string values only for fields with explicit data type annotations:

| Annotation | Allowed Normalization |
|------------|----------------------|
| `UUID4` | Lowercase hex, add hyphens |
| `IPV4` | Remove leading zeros |
| `IPV6` | Lowercase, expand shorthand |
| `EMAIL` | Lowercase domain portion |

All other fields **must** return the client's exact input. Normalization behavior **must**
be documented in field comments.

## REST Examples

```
# Client sends a VM with requested IP
POST /v1/projects/myproject/vms
{
  "ipAddress": "10.0.0.1"
}

# Server returns both client value and effective value
{
  "name": "projects/myproject/vms/vm-123",
  "ipAddress": "10.0.0.1",
  "effectiveIpAddress": "10.0.0.5"
}
```

## Anti-Patterns

### Silently modifying client input
**Wrong**: Client sends `ip_address: "10.0.0.1"`, server returns `ip_address: "10.0.0.5"`
**Right**: Return client value unchanged; use `effective_ip_address` for the computed value

### Single field for both input and effective value
**Wrong**: One `schedule` field that sometimes reflects client input, sometimes server default
**Right**: Separate `schedule` (client-owned) and `effective_schedule` (OUTPUT_ONLY)

### Undocumented normalization
**Wrong**: Silently lowercasing or reformatting without documentation
**Right**: Document normalization in field comments; limit to allowed data types

## Review Checklist

- [ ] Each field has single ownership (client or server) (AIP-129)
- [ ] Server-owned fields are annotated OUTPUT_ONLY (AIP-129, AIP-203)
- [ ] Client-owned field values returned unchanged (AIP-129)
- [ ] Effective values use `effective_{field}` pattern with OUTPUT_ONLY (AIP-129)
- [ ] Normalization is documented and limited to allowed data types (AIP-129)
