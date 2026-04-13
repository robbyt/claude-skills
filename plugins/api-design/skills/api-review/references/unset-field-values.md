# Unset Field Values

Reference: [AIP-149](https://google.aip.dev/149)

## Purpose

In protobuf, primitive fields (int32, bool, string) have default values (0, false, "").
Sometimes an API needs to distinguish between "the user set this to 0" and "the user did
not set this at all." The `optional` keyword enables this distinction -- but it adds
complexity and **should** only be used when truly necessary.

## When to Use `optional`

Use `optional` **only** when the default value is a valid, meaningful input that differs
from "not set":

```proto
message Book {
  string name = 1 [(google.api.field_behavior) = IDENTIFIER];

  // Rating of 0 is meaningful and distinct from "no rating"
  optional int32 rating = 2;
}
```

**Should** only be needed for integers and floats. Booleans and strings rarely need this
distinction.

## When NOT to Use `optional`

Most fields **should not** use `optional`. If the default value and "not set" are
semantically equivalent, omit it:

```proto
message Book {
  string name = 1;
  string title = 2;       // Empty string = no title = same thing
  bool is_published = 3;  // false = not published = same thing
  int32 page_count = 4;   // 0 pages = no page count = same thing (usually)
}
```

## Relationship to Field Behavior

`optional` and `field_behavior` (AIP-203) are **unrelated** concepts:

- `optional` controls wire-level presence tracking
- `field_behavior` documents API-level semantics (REQUIRED, OUTPUT_ONLY, etc.)

Both can be used together:

```proto
// A required field that also tracks presence
optional string display_name = 2 [
  (google.api.field_behavior) = REQUIRED
];
```

## Backward Compatibility

Adding or removing `optional` on an existing field is **backward incompatible** in many
languages. Treat it as a breaking change (AIP-180).

## Anti-Patterns

### Using optional everywhere
**Wrong**: Marking every field `optional` "just in case"
**Right**: Only use when 0/false/"" is a valid, distinct value from unset

### Using optional for booleans
**Wrong**: `optional bool enabled = 1;` (false and unset are almost always equivalent)
**Right**: `bool enabled = 1;`

### Confusing optional with field_behavior
**Wrong**: Thinking `optional` means the field is not required
**Right**: `optional` is about wire-level presence; use `REQUIRED` annotation for API semantics

### Adding optional to existing fields
**Wrong**: Adding `optional` to a shipped field to gain presence tracking
**Right**: This is a breaking change; consider a new field instead

## Review Checklist

- [ ] `optional` used only when default value differs from "not set" (AIP-149)
- [ ] `optional` limited to integers and floats where possible (AIP-149)
- [ ] `optional` not confused with field_behavior annotations (AIP-149, AIP-203)
- [ ] No retroactive addition of `optional` to existing fields (AIP-149, AIP-180)
