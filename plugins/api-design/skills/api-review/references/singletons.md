# Singleton Resources

Reference: [AIP-156](https://google.aip.dev/156)

## Purpose

A singleton resource is one where exactly one instance always exists per parent. The most
common use case is a configuration object — every user has exactly one config.

## Pattern

```proto
message Config {
  option (google.api.resource) = {
    type: "api.googleapis.com/Config"
    pattern: "users/{user}/config"
    singular: "config"
    plural: "configs"
  };

  string name = 1 [(google.api.field_behavior) = IDENTIFIER];
  // ... config fields
}
```

```proto
rpc GetConfig(GetConfigRequest) returns (Config) {
  option (google.api.http) = {
    get: "/v1/{name=users/*/config}"
  };
}

rpc UpdateConfig(UpdateConfigRequest) returns (Config) {
  option (google.api.http) = {
    patch: "/v1/{config.name=users/*/config}"
    body: "config"
  };
}
```

## Rules

- **Must not** have user-provided or system-generated IDs
- Resource name = parent name + one static segment: `users/1234/config`
- Always singular in naming
- **Must** provide both `singular` and `plural` in resource annotation
- **May** parent other resources
- **Must not** define Create or Delete methods — lifecycle tied to parent
- **Should** define Get and Update
- **Must not** define Update if all fields are output-only
- **May** define List (using AIP-159 cross-collection pattern)
- **May** define custom methods

## When to Use

| Pattern | Use When |
|---------|----------|
| **Singleton** | Exactly one per parent, always exists, no ID needed |
| **Regular resource** | Zero or more per parent, user-created/deleted |
| **Sub-resource collection** | Multiple related items that grow over time |

### Examples

| Singleton | Regular Resource |
|-----------|-----------------|
| User settings/config | User profiles |
| Project billing info | Project resources |
| Repository branch protection rules | Repository branches |
| Account recovery settings | Account sessions |

## List Across Parents (AIP-159)

Singletons may support List using the `-` wildcard:

```proto
rpc ListConfigs(ListConfigsRequest) returns (ListConfigsResponse) {
  option (google.api.http) = {
    get: "/v1/{parent=users/*}/configs"
  };
}
```

```
GET /v1/users/-/configs     # All configs across all users
GET /v1/users/123/configs   # Single config for user 123
```

## Review Checklist

- [ ] Singleton has no Create or Delete methods (AIP-156)
- [ ] Resource name uses static segment, no ID (AIP-156)
- [ ] Both `singular` and `plural` specified in resource annotation (AIP-156)
- [ ] Update method omitted if all fields are output-only (AIP-156)
