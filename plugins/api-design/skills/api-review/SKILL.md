---
name: api-review
description: >-
  This skill should be used when reviewing API designs, auditing REST or gRPC endpoints,
  designing backend APIs, evaluating BFF architecture, or discussing API best practices.
  Also triggers on: "review this API", "API design review", "is this API correct",
  "REST API audit", "gRPC API review", "PATCH vs PUT", "etag", "idempotency",
  "pagination design", "API error handling", "backward compatibility", "BFF architecture",
  "resource-oriented design", "TOCTOU", "race condition", "optimistic concurrency",
  "field mask", "long-running operation", "custom method", "soft delete",
  "API naming conventions", "declarative-friendly"
---

# API Design Review

Expert guidance for API design based on Google's API Improvement Proposals (AIPs) — the
same standards governing all public Google APIs. These principles are universal and apply to
any organization building REST, gRPC, or BFF/backend APIs.

## When to Use

Invoke this skill when:
- Reviewing or auditing API endpoint designs (REST or gRPC)
- Designing new backend service APIs
- Evaluating BFF (Backend-for-Frontend) architecture boundaries
- Resolving concurrency issues (TOCTOU, lost updates, race conditions)
- Choosing between PATCH and PUT, or standard vs custom methods
- Designing pagination, filtering, or error handling
- Assessing backward compatibility of API changes

**Always cite the AIP number** (e.g., "Per AIP-154, ETags must use ABORTED on mismatch")
when providing guidance. This gives teams an authoritative, linkable reference at
https://google.aip.dev/{number}.

## Core Principles

These five principles form the foundation of well-designed APIs:

| # | Principle | Key AIPs | One-liner |
|---|-----------|----------|-----------|
| 1 | **Resource-oriented design** | AIP-121, 122, 123 | Model APIs as resource hierarchies with standard methods |
| 2 | **Business operations, not CRUD** | AIP-136 | Expose domain actions, not raw table access |
| 3 | **Idempotent, conflict-aware mutations** | AIP-154, 155 | ETags prevent lost updates; request IDs enable safe retries |
| 4 | **Declarative desired-state** | AIP-128 | Clients send intended state; server reconciles |
| 5 | **Explicit contracts** | AIP-192, 203 | Field behavior is documented; breaking changes are caught |

## Standard Methods Quick Reference

Per AIP-121, every resource should expose standard methods where appropriate:

| Method | HTTP | AIP | Notes |
|--------|------|-----|-------|
| Get | `GET /v1/{name=...}` | AIP-131 | Return single resource |
| List | `GET /v1/{parent=...}/resources` | AIP-132 | Paginated collection; see AIP-158 |
| Create | `POST /v1/{parent=...}/resources` | AIP-133 | Include `{resource}_id` for client-assigned names |
| Update | `PATCH /v1/{resource.name=...}` | AIP-134 | Always PATCH, never PUT; use field masks |
| Delete | `DELETE /v1/{name=...}` | AIP-135 | Support `etag`, `force`, `allow_missing` |

Custom methods use `POST /v1/{name=...}:verb` (AIP-136) for operations that don't fit
standard methods — e.g., `:archive`, `:merge`, `:approve`.

## Decision Tables

### PATCH vs PUT (AIP-134)

| Scenario | Recommendation | Rationale |
|----------|---------------|-----------|
| Updating specific fields | **PATCH + field mask** | Adding fields later won't break existing clients |
| Full resource replacement | **PATCH with `*` mask** | Equivalent to PUT without the compatibility risk |
| Legacy system requires PUT | Discouraged | Document risks; plan migration to PATCH |

### Standard vs Custom Method (AIP-136)

| Operation | Method | Reason |
|-----------|--------|--------|
| Get a resource by name | Standard Get | Fits AIP-131 exactly |
| Search with complex filters | Standard List + filter | AIP-132 + AIP-160 |
| Archive a resource | Custom `:archive` | State change, not a data update (AIP-136) |
| Merge two resources | Custom `:merge` | Multi-resource operation with side effects |
| Approve a workflow step | Custom `:approve` | Domain action, not a field update |

### Concurrency Control (AIP-154, AIP-155)

| Problem | Solution | AIP |
|---------|----------|-----|
| TOCTOU race condition | **ETags** — server returns etag; client sends it back on mutation | AIP-154 |
| Lost updates from parallel writes | **ETags** — ABORTED (409) on mismatch | AIP-154 |
| Network retry causes duplicate creation | **Request IDs** — UUID4 `request_id` field | AIP-155 |
| Client unsure if mutation succeeded | **Request ID + idempotency** — same ID returns same result | AIP-155 |

## BFF Architecture Boundaries

A well-designed architecture separates concerns:

| Layer | Owns | Does NOT Own |
|-------|------|-------------|
| **Frontend + BFF** | UI rendering, session management, request routing, lightweight response shaping | Business logic, DB connections, data joins, authorization decisions |
| **Backend APIs** | Business operations, domain logic, data integrity, validation, audit logging | UI concerns, session state, frontend formatting |
| **AuthZ service** | Centralized access control, policy enforcement | Business logic; answers "is this allowed?" not "what should happen?" |

**Red flags** in BFF code: direct database queries, business rule enforcement, data
assembly across multiple sources, independent authorization logic.

## Audit Checklist

When reviewing an API, check these categories in order. For full details with examples and
fix guidance, consult `references/audit-checklist.md`.

### CRITICAL — Concurrency & Safety
- [ ] Mutable resources include `etag` field (AIP-154)
- [ ] Mutating endpoints accept `request_id` for idempotency (AIP-155)
- [ ] Update uses PATCH, not PUT (AIP-134)
- [ ] Delete supports `etag` for protected delete (AIP-135)

### HIGH — Resource Design
- [ ] Resources follow hierarchical naming: `{parent}/{collection}/{id}` (AIP-122)
- [ ] Standard methods used where applicable (AIP-131–135)
- [ ] Custom methods use `:verb` suffix, not faux resources (AIP-136)
- [ ] Field behavior annotated (required, optional, output_only, immutable) (AIP-203)

### MEDIUM — Usability & Evolution
- [ ] List endpoints paginated with `page_size` + `page_token` (AIP-158)
- [ ] Errors use standard codes with structured details (AIP-193)
- [ ] Changes assessed for backward compatibility (AIP-192)
- [ ] Long-running operations return Operation object (AIP-151)

### LOW — Polish
- [ ] Filtering uses common expression language (AIP-160)
- [ ] Partial responses supported via field masks (AIP-161)
- [ ] Soft delete available where appropriate (AIP-164)

## Reference Files

Consult these for detailed guidance, full AIP text, and code examples:

### Resource Design
- **`references/resource-oriented-design.md`** — Resource hierarchies, naming, types, standard methods overview (AIP-121, 122, 123)

### Standard Methods
- **`references/standard-get-list.md`** — Get and List methods with pagination, filtering, ordering (AIP-131, 132, 158, 160)
- **`references/standard-create.md`** — Create method, user-specified IDs, long-running create (AIP-133)
- **`references/standard-update.md`** — Update/PATCH method, field masks, etags on update, why not PUT (AIP-134)
- **`references/standard-delete.md`** — Delete method, soft delete, cascading delete, force/allow_missing (AIP-135, 164)

### Design Patterns
- **`references/etags-and-freshness.md`** — Optimistic concurrency, TOCTOU prevention, strong vs weak etags (AIP-154)
- **`references/idempotency.md`** — Request IDs, safe retries, UUID4 format (AIP-155)
- **`references/custom-methods.md`** — When and how to use custom methods for business operations (AIP-136)
- **`references/declarative-interfaces.md`** — Desired-state pattern, reconciliation, declarative-friendly resources (AIP-128)
- **`references/long-running-operations.md`** — LRO pattern, metadata, parallel operations, expiration (AIP-151)

### Data Handling
- **`references/field-behavior.md`** — Required, optional, output_only, input_only, immutable annotations (AIP-203)
- **`references/field-masks.md`** — Partial update and partial response with FieldMask (AIP-161)
- **`references/pagination-and-filtering.md`** — Page tokens, page size, filter expressions, ordering (AIP-158, 160)
- **`references/batch-methods.md`** — Batch get, create, update, delete patterns (AIP-235)

### Lifecycle & Errors
- **`references/errors.md`** — Standard error codes, error details, PERMISSION_DENIED vs NOT_FOUND (AIP-193)
- **`references/resource-lifecycle.md`** — State enums, soft delete/undelete, resource expiry/TTL (AIP-216, 164, 214)
- **`references/compatibility.md`** — Backward compatibility rules, breaking vs non-breaking changes (AIP-192)

### Architecture
- **`references/bff-architecture.md`** — BFF layer boundaries, anti-patterns, migration guidance
- **`references/http-transcoding.md`** — HTTP/JSON to gRPC mapping, URI conventions (AIP-127)
- **`references/audit-checklist.md`** — Full audit checklist with severity, examples, and fix patterns
