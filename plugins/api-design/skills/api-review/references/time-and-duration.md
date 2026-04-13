# Time and Duration

Reference: [AIP-142](https://google.aip.dev/142)

## Purpose

Representing time correctly is challenging due to calendars, time zones, and the lack of
native time types in formats like JSON. Using standard protobuf time components ensures
consistency across tooling and infrastructure.

## Time Types

| Concept | Protobuf Type | JSON Format | Use When |
|---------|--------------|-------------|----------|
| Absolute instant | `google.protobuf.Timestamp` | `"2024-01-15T09:30:00Z"` | Events, deadlines, audit trails |
| Elapsed time | `google.protobuf.Duration` | `"3600s"` | Timeouts, intervals, TTLs |
| Calendar date | `google.type.Date` | `{"year":2024,"month":1,"day":15}` | Birthdays, billing dates |
| Wall-clock time | `google.type.TimeOfDay` | `{"hours":9,"minutes":30}` | Daily schedules, store hours |
| Civil datetime | `google.type.DateTime` | Structured with timezone | Appointments, local events |

## Naming Conventions

Timestamp fields **should** end in `_time` (or `_times` for repeated):

```proto
message Event {
  google.protobuf.Timestamp create_time = 1;
  google.protobuf.Timestamp publish_time = 2;
  google.protobuf.Timestamp last_update_time = 3;
}
```

Use imperative form, not past tense:
- `publish_time` (correct)
- `published_time` (wrong)

Duration fields **should** use the `Duration` type directly:

```proto
message Config {
  google.protobuf.Duration timeout = 1;
  google.protobuf.Duration retry_delay = 2;
}
```

## Relative Offsets

Fields representing a position relative to a reference point **should** end in `_offset`
with a comment noting the reference:

```proto
message AudioSegment {
  // Offset from the start of the audio stream.
  google.protobuf.Duration start_offset = 1;
  google.protobuf.Duration segment_duration = 2;
}
```

## Calendar Dates

Date fields **should** end in `_date`:

```proto
message Invoice {
  google.type.Date issue_date = 1;
  google.type.Date due_date = 2;
}
```

Civil time and datetime fields **should** end in `_time` (same as timestamps; the type
provides disambiguation).

## Legacy Compatibility

When external specs require integer timestamps or specific string formats, use integers
with unit suffixes:

```proto
message LegacyEvent {
  // Unix timestamp in milliseconds.
  int64 send_time_millis = 1;
}
```

## Anti-Patterns

### Custom integer timestamps without unit suffix
**Wrong**: `int64 created_at = 1;` (seconds? milliseconds? microseconds?)
**Right**: `google.protobuf.Timestamp create_time = 1;` or `int64 create_time_millis = 1;`

### Past-tense field names
**Wrong**: `published_time`, `created_time`, `updated_time`
**Right**: `publish_time`, `create_time`, `update_time`

### Missing offset reference
**Wrong**: `Duration offset = 1;` (offset from what?)
**Right**: `Duration start_offset = 1;` with comment noting reference point

### String timestamps without format documentation
**Wrong**: `string timestamp = 1;`
**Right**: `google.protobuf.Timestamp` or documented format string

## Review Checklist

- [ ] Time fields use standard protobuf types, not custom integers/strings (AIP-142)
- [ ] Timestamp fields end in `_time`, not past tense (AIP-142)
- [ ] Duration fields use `google.protobuf.Duration` (AIP-142)
- [ ] Relative offsets end in `_offset` with reference comments (AIP-142)
- [ ] Calendar dates end in `_date` using `google.type.Date` (AIP-142)
- [ ] Legacy integer timestamps include unit suffix (AIP-142)
