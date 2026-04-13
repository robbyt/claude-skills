# Sensitive Fields

Reference: [AIP-147](https://google.aip.dev/147)

## Purpose

APIs sometimes collect sensitive information (passwords, private keys, secrets) that must
be stored but should never be readable after writing. Extra care is needed to avoid
accidentally exposing sensitive data in responses.

## Required Sensitive Fields

When sensitive data is required for the resource to exist (e.g., a private key for a
keypair), use INPUT_ONLY with no corresponding output:

```proto
message SelfManagedKeypair {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  bytes public_key = 2;

  // The private key data. Write-only.
  bytes private_key = 3 [(google.api.field_behavior) = INPUT_ONLY];
}
```

Resource existence implies the sensitive data was stored.

## Optional Sensitive Fields

When sensitive data is optional, add an OUTPUT_ONLY boolean `_set` indicator:

```proto
message Integration {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  string uri = 2;

  // Write-only. A secret for webhook authorization.
  string shared_secret = 3 [(google.api.field_behavior) = INPUT_ONLY];

  // True if a shared_secret has been set.
  bool shared_secret_set = 4 [(google.api.field_behavior) = OUTPUT_ONLY];
}
```

This lets clients know whether the secret exists without exposing it.

## Obfuscated Representation

When users need to identify (but not fully read) sensitive data, use an `obfuscated_`
prefix:

```proto
message AccountRecoverySettings {
  // Write-only. The recovery email.
  string email = 1 [(google.api.field_behavior) = INPUT_ONLY];

  // Read-only. Obfuscated form: "a**@e*****e.com"
  string obfuscated_email = 2 [(google.api.field_behavior) = OUTPUT_ONLY];
}
```

## Patterns Summary

| Scenario | Input Field | Output Field |
|----------|-------------|-------------|
| Required secret (private key) | `INPUT_ONLY` field | None — existence implies storage |
| Optional secret (webhook token) | `INPUT_ONLY` field | `bool {field}_set` (OUTPUT_ONLY) |
| Identifiable secret (email, phone) | `INPUT_ONLY` field | `obfuscated_{field}` (OUTPUT_ONLY) |

## Anti-Patterns

### Returning sensitive data in responses
**Wrong**: `GET /users/1` returns `{"password": "hunter2"}`
**Right**: Password field is INPUT_ONLY, never returned

### No indicator for optional secrets
**Wrong**: Client can't tell if a webhook secret was configured
**Right**: `shared_secret_set: true` tells the client without exposing the value

### Masking in the same field
**Wrong**: `password: "****"` in GET response (same field, different meaning)
**Right**: Separate `obfuscated_` field or `_set` boolean

## Review Checklist

- [ ] Sensitive fields are INPUT_ONLY (AIP-147, AIP-203)
- [ ] No sensitive data returned in GET/List responses (AIP-147)
- [ ] Optional secrets have `_set` boolean indicator (AIP-147)
- [ ] Identifiable secrets use `obfuscated_` prefix field (AIP-147)
- [ ] Error messages don't leak sensitive field values (AIP-193)
