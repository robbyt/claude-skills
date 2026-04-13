# Field Naming and Standard Fields

References: [AIP-140](https://google.aip.dev/140), [AIP-148](https://google.aip.dev/148), [AIP-126](https://google.aip.dev/126), [AIP-143](https://google.aip.dev/143)

## Field Names (AIP-140)

Field names should be simple, intuitive, and consistent across APIs. Users learn patterns
from one API and apply them to others — inconsistency creates unnecessary confusion.

### Case and Format

- **Must** use `lower_snake_case` in proto definitions (mapped to camelCase in JSON)
- Words **must not** begin with a number
- **Must not** have leading, trailing, or adjacent underscores

### Naming Rules

| Rule | Good | Bad | AIP |
|------|------|-----|-----|
| Use American English | `color` | `colour` | AIP-140 |
| Avoid prepositions | `error_reason` | `reason_for_error` | AIP-140 |
| Abbreviate well-known terms | `config`, `id`, `spec`, `stats` | `configuration`, `identifier` | AIP-140 |
| Abbreviate units | `distance_km` | `distance_kilometers` | AIP-140 |
| Adjective before noun | `collected_items` | `items_collected` | AIP-140 |
| Fields must be nouns, not verbs | `disabled` | `disable` | AIP-140 |
| Booleans omit "is" prefix | `disabled`, `required` | `is_disabled`, `is_required` | AIP-140 |
| Repeated fields use plural | `books`, `authors` | `book`, `author` | AIP-140 |
| Non-repeated use singular | `book`, `author` | `books` | AIP-140 |
| Avoid reserved words | `is_new` | `new` (keyword conflict) | AIP-140 |
| Use `uri` for general, `url` for URLs only | `image_url`, `uri` | `link`, `href` | AIP-140 |
| Use `display_name` for human-readable | `display_name` | `label`, `friendly_name` | AIP-140 |
| Use `title` for official/formal names | `title` | `official_name` | AIP-140 |

### Strings vs Bytes

- Use `bytes` for binary content (auto base64-encoded in JSON)
- Do **not** ask users to manually base64-encode into `string` fields

## Standard Fields (AIP-148)

These field names have standardized meanings. Use them consistently:

### Resource Identity

| Field | Type | Behavior | Purpose |
|-------|------|----------|---------|
| `name` | `string` | IDENTIFIER | Resource name (AIP-122). First field. |
| `parent` | `string` | REQUIRED | Parent resource for List/Create |
| `uid` | `string` | OUTPUT_ONLY | System-assigned UUID4 |
| `display_name` | `string` | — | Mutable human-readable name (≤63 chars) |
| `title` | `string` | — | Official/formal name |

### Person Names

| Field | Type | Notes |
|-------|------|-------|
| `given_name` | `string` | **Not** `first_name` (not first in all cultures) |
| `family_name` | `string` | **Not** `last_name` (not last in all cultures) |

### Timestamps

| Field | Type | Behavior | Purpose |
|-------|------|----------|---------|
| `create_time` | `Timestamp` | OUTPUT_ONLY | When resource was created |
| `update_time` | `Timestamp` | OUTPUT_ONLY | Last user-initiated modification |
| `delete_time` | `Timestamp` | OUTPUT_ONLY | When soft-deleted (AIP-164) |
| `expire_time` | `Timestamp` | — | When resource expires (AIP-214) |
| `purge_time` | `Timestamp` | — | When soft-deleted resource will be purged |

### Other Standard Fields

| Field | Type | Purpose |
|-------|------|---------|
| `etag` | `string` | Optimistic concurrency (AIP-154) |
| `request_id` | `string` | Idempotency key (AIP-155) |
| `filter` | `string` | List filtering (AIP-160) |
| `order_by` | `string` | List ordering (AIP-132) |
| `validate_only` | `bool` | Dry-run mode (AIP-163) |
| `annotations` | `map<string, string>` | Arbitrary key-value metadata |

### IP Addresses

- Use type `string`, name `ip_address` or `*_ip_address`
- Specify format: `IPV4`, `IPV6`, or `IPV4_OR_IPV6` (AIP-202)

## Enumerations (AIP-126)

Use enums for discrete, limited value sets that change infrequently (roughly once a year
or less):

```proto
enum Format {
  FORMAT_UNSPECIFIED = 0;  // Default, zero value
  HARDBACK = 1;
  PAPERBACK = 2;
  EBOOK = 3;
}
```

### Rules

- Values **must** use `UPPER_SNAKE_CASE`
- First value **should** be `{ENUM_NAME}_UNSPECIFIED` (the zero value)
- Exception: `UNKNOWN` may be the zero value if more useful
- Nested enums (single message use) go immediately before the field
- Package-level enums go at the bottom of the proto file
- Package-level values **should** be prefixed with enum name (C++ hoists values)
- Document whether the enum is frozen or may receive new values

### When NOT to Use Enums

- Values change frequently → use `string` with `kebab-case` values
- Widely-adopted standard exists (language codes, media types) → use that standard
- Only two states needed → `bool` may suffice (default must be `false`)

## Standardized Codes (AIP-143)

For common concepts with established standards, use the standard representation:

| Concept | Standard | Field Name | Example |
|---------|----------|------------|---------|
| Content type | IANA media types | `mime_type` | `application/json` |
| Country/region | Unicode CLDR | `region_code` | `US`, `CH` |
| Currency | ISO-4217 | `currency_code` | `USD`, `EUR` |
| Language | BCP-47 | `language_code` | `en-US` |
| Time zone | IANA TZ | `time_zone` | `America/New_York` |
| UTC offset | ISO-8601 | `utc_offset` | `+05:30` |

- Field names **should** end in `_code` or `_type`
- Accept values case-insensitively; return canonical case
- Do **not** use enums for standard codes — it leads to frustrating lookup tables

## Review Checklist

- [ ] Field names use `lower_snake_case` (AIP-140)
- [ ] No prepositions, no verbs, no reserved words in field names (AIP-140)
- [ ] Booleans omit "is" prefix (AIP-140)
- [ ] Standard fields use standard names (`name`, `create_time`, `display_name`) (AIP-148)
- [ ] Person names use `given_name`/`family_name`, not `first_name`/`last_name` (AIP-148)
- [ ] Enums use `UPPER_SNAKE_CASE` with `_UNSPECIFIED` zero value (AIP-126)
- [ ] Standard codes (country, currency, language) use the established standard (AIP-143)
