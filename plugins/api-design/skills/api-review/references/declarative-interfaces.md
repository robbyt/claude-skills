# Declarative-Friendly Interfaces

Reference: [AIP-128](https://google.aip.dev/128)

## Purpose

Declarative-friendly APIs support DevOps tooling (Terraform, Pulumi, Crossplane, etc.) that
operates on the principle of **configuration as code**: the user specifies the intended
landscape, and tooling reconciles current state to match.

These tools are **declarative**: they specify desired outcomes, not specific actions. Because
hundreds of resource types must integrate with multiple tools, uniformity is essential.

## Core Concept: Desired State

Instead of imperative commands ("change field X to value Y"), the client sends the complete
intended state. The server determines what changes are needed.

```
Client sends:    {"title": "New Title", "rating": 5, "etag": "abc"}
Server computes: title changed, rating unchanged → apply title change only
```

## Resource Requirements

Declarative-friendly resources **must**:

1. Use only strongly-consistent standard methods for lifecycle management
2. Include an `etag` field (AIP-154) — required, not optional
3. Include standard fields (AIP-148): `create_time`, `update_time`, `delete_time`, `etag`
4. Support the Update method for repeated fields (AIP-144)
5. Provide change validation (AIP-163)

Declarative-friendly resources **should**:

6. Use long-running operations for Create, Update, Delete (AIP-151)
7. Not employ custom methods (AIP-136) — tools can't reason about arbitrary actions
8. Not implement soft-delete (unless ID cannot be reused)

### Style Annotation

```proto
message Book {
  option (google.api.resource) = {
    type: "library.googleapis.com/Book"
    pattern: "publishers/{publisher}/books/{book}"
    style: DECLARATIVE_FRIENDLY
  };
  // fields...
}
```

## Reconciliation

When a resource takes time for updates to be realized:

```proto
message Book {
  // ... other fields ...

  // True if the current state does not match the user's intended state.
  bool reconciling = 10 [(google.api.field_behavior) = OUTPUT_ONLY];
}
```

- Set `reconciling = true` when current state ≠ intended state
- This applies regardless of whether the trigger was user or system action
- GET requests **must** return current state, not intended state

## Implications for API Design

### Delete Must Support ETags and allow_missing

```proto
message DeleteBookRequest {
  string name = 1 [...];
  string etag = 2;           // MUST for declarative
  bool allow_missing = 3;    // SHOULD for declarative
}
```

### Update Must Support allow_missing

Declarative tools may try to update a resource before it exists:

```proto
message UpdateBookRequest {
  Book book = 1 [...];
  google.protobuf.FieldMask update_mask = 2;
  bool allow_missing = 3;    // Creates if not found
}
```

### Custom Methods Are Discouraged

Declarative tools work by comparing current vs desired state and calling standard methods.
They cannot automatically determine when or how to call custom methods.

Exception: imperative operations like `Move` or `Rename` that don't have a declarative
equivalent.

## Declarative vs Imperative

| Aspect | Declarative (AIP-128) | Imperative |
|--------|----------------------|------------|
| Client says | "This is what I want" | "Do this action" |
| Server determines | What to change | N/A — executes as told |
| Concurrency | ETags required | ETags optional |
| Tooling | Terraform, Pulumi, Crossplane | Custom scripts, SDKs |
| Operations | Standard methods only | Standard + custom methods |
| Reconciliation | `reconciling` field | Not applicable |

## Architecture Connection

The user's architecture document emphasizes "declarative desired-state payloads":

> Clients send the intended end state, not incremental deltas. The server reconciles
> current state to desired state, eliminating ordering dependencies and race conditions.

This maps directly to AIP-128. Backend APIs should:
1. Accept the full desired state of a resource
2. Compute the diff internally
3. Apply changes atomically
4. Return the current state (which may differ during reconciliation)
5. Expose `reconciling` to signal in-flight changes

This eliminates ordering dependencies that arise when BFFs must orchestrate incremental
updates across multiple services.
