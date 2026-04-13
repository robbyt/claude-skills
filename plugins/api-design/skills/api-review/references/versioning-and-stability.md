# Versioning and Stability

References: [AIP-180](https://google.aip.dev/180), [AIP-181](https://google.aip.dev/181), [AIP-185](https://google.aip.dev/185)

## Backward Compatibility (AIP-180)

Old clients **must** work against newer servers with the same major version. Three types
of compatibility matter:

1. **Source compatibility** — code compiles and runs against newer client library
2. **Wire compatibility** — serialization/deserialization continues to work
3. **Semantic compatibility** — behavior matches what reasonable developers expect

### Breaking Changes (Never Do These in Same Major Version)

| Category | Examples |
|----------|---------|
| **Remove/rename** | Removing a field, method, enum value, or message |
| **Change types** | Changing a field's type, even if wire-compatible |
| **Add requirements** | Making an optional field required |
| **Move components** | Moving fields between files or into/out of oneofs |
| **Change resource names** | Resource names must never change, even across major versions |
| **Change string length** | Increasing upper bound for string field sizes |
| **Change defaults** | Changing default value behavior |
| **Change serialization** | Changing whether a default-valued field appears in output |
| **Change format** | Changing format/algorithm for computing field values |

### Safe Changes (Additive Only)

| Change | Caveat |
|--------|--------|
| Add new optional field | Default behavior must match pre-addition behavior |
| Add new method/endpoint | Existing clients unaffected |
| Add new enum value | Clients with exhaustive switches may break — document |
| Add new resource type | No existing references |
| Add new response field | Unknown fields ignored |
| Relax validation | Previously valid requests still valid |

### The Pagination Trap

Adding pagination after the fact is dangerous. If the collection previously returned all
items and the new default `page_size` is smaller, old clients will incorrectly assume all
results were returned. Always include pagination from the start (AIP-158).

## Stability Levels (AIP-181)

| Level | Breaking Changes? | User Expectations | Duration |
|-------|-------------------|-------------------|----------|
| **Alpha** | Allowed and expected | Users must be tolerant of change | Curated, manageable user set |
| **Beta** | Discouraged; allowed with deprecation period | Complete, ready to be declared stable | Time-boxed (recommend 90 days) |
| **Stable** | Not allowed within major version | Fully supported for lifetime of major version | Permanent |

### Alpha

- Rapid iteration with known users
- Breaking changes must be both allowed and expected
- Users must have no expectation of stability

### Beta

- Complete and ready for public testing
- Should be available to the public (not behind allowlist)
- Breaking changes allowed only after reasonable deprecation period
- Deprecation period **must** be defined when marked beta
- Should be time-boxed; promote to stable if no issues found

### Stable

- No breaking changes within the major version
- When breaking changes become necessary, create the next major version
- Turn-down of any stable version **must** have a formal process with reasonable advance warning

### Emergency Changes

Security concerns or regulatory requirements **may** override stability guarantees.
No deprecation is promised in these exceptional situations.

## Major Version Strategy

### When to Create a New Major Version

- Accumulated design debt requires fundamental restructuring
- Incompatible changes to resource schemas or behavior
- New security or compliance requirements incompatible with existing contract

### URL Versioning

```
/v1/publishers/123/books     # Stable
/v2/publishers/123/books     # Breaking changes from v1
/v1alpha1/experiments/...    # Alpha
/v1beta1/features/...        # Beta
```

### Resource Name Continuity

Resource names **must not** change across major versions. A resource created in v1
must be accessible by the same name in v2:

```
# Same resource, accessible from both versions
v1: publishers/123/books/456
v2: publishers/123/books/456
```

## Compatibility Checklist for API Changes

Before releasing any change to a stable API:

- [ ] No fields removed or renamed (AIP-180)
- [ ] No field types changed (AIP-180)
- [ ] No optional fields made required (AIP-180)
- [ ] No enum values removed (AIP-180)
- [ ] No resource names or URL patterns changed (AIP-180)
- [ ] New fields have sensible defaults matching pre-addition behavior (AIP-180)
- [ ] Default values unchanged (AIP-180)
- [ ] String field size bounds unchanged (AIP-180)
- [ ] Value format/construction unchanged for existing fields (AIP-180)
- [ ] Serialization behavior unchanged (AIP-180)
- [ ] Stability level documented and commitments honored (AIP-181)
- [ ] Proto field numbers unchanged; removed numbers marked `reserved` (AIP-180)
