# BFF Architecture and Service Boundaries

This reference codifies the architectural principles for Backend-for-Frontend (BFF)
layers, backend APIs, and service boundary design. While not a specific AIP, these
patterns directly apply Google's API design philosophy to multi-tier architectures.

## The Three-Layer Model

| Layer | Responsibility | Does NOT Contain |
|-------|---------------|-----------------|
| **Frontend + BFF** | UI rendering, session management, auth token handling, request routing, lightweight response shaping | Database connections, business logic, data joins across sources, authorization decisions |
| **Backend APIs** | Business operations, domain logic, data integrity, validation, audit logging, idempotent and conflict-aware mutations | UI-specific concerns, session state, frontend formatting |
| **AuthZ Service** | Centralized access control, relationship-based policy enforcement | Business logic — answers "is this allowed?" not "what should happen?" |

## BFF Anti-Patterns

### Direct Database Connections

**Problem**: BFF contains SQL queries, connection pools, or ORM configurations.

**Why it's wrong**: The BFF now owns data integrity, schema knowledge, and connection
lifecycle. Multiple BFFs connecting to the same database create consistency risks and
make schema changes dangerous.

**Fix**: Backend API owns all data access. BFF calls API endpoints.

### Business Logic in the BFF

**Problem**: BFF contains conditional logic that determines application behavior: validation
rules, workflow state machines, pricing calculations, eligibility checks.

**Why it's wrong**: Business rules become fragmented across BFF and backend. No single
source of truth. Rules are duplicated when another client (mobile, CLI) needs the same logic.

**Fix**: Backend API exposes business-operation endpoints (AIP-136 custom methods). BFF
only calls them and shapes responses.

### Data Assembly Across Sources

**Problem**: BFF queries multiple backends, joins the data, and returns assembled objects.

**Why it's wrong**: The BFF is now an unversioned, untested orchestration layer. Join logic
is fragile, error handling is inconsistent, and partial failures are poorly handled.

**Fix**: Backend API that owns the domain provides a composite endpoint. If cross-domain
aggregation is needed, a dedicated aggregation service owns the contract.

### Independent Authorization

**Problem**: Each team's BFF implements its own RBAC/permission checks.

**Why it's wrong**: Inconsistent access control across teams. Audit is impossible. Policy
changes require updating every BFF.

**Fix**: Centralized authorization service (e.g., SpiceDB/Zanzibar model). Backend APIs
call AuthZ; BFF only forwards tokens.

## Backend API Design Principles

### Business Operations, Not Table CRUD (AIP-136)

APIs expose operations that represent real domain actions:

| Wrong (CRUD) | Right (Business Operation) |
|-------------|---------------------------|
| `POST /patients` + `PUT /patients/1` + `DELETE /patients/2` | `POST /patients:merge` |
| `PUT /teams/1 {"provisioned": true}` | `POST /teams/1:provision` |
| `PUT /orders/1 {"status": "approved"}` | `POST /orders/1:approve` |

The API owns the complete operation including validation, side effects, and audit.

### Idempotent, Conflict-Aware Mutations (AIP-154, AIP-155)

All mutating operations accept:
- **Idempotency keys** (`request_id`): safe retries after network failures
- **ETags**: optimistic concurrency preventing lost updates

```
POST /v1/teams:provision
{
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "team": {"name": "teams/new-team", "etag": "\"abc\"", ...}
}
```

### Declarative Desired-State (AIP-128)

Clients send the intended end state, not incremental deltas:

```
# Wrong: imperative sequence
PATCH /book {"title": "new"}
PATCH /book {"rating": 5}
PATCH /book {"published": true}

# Right: declarative desired state
PATCH /book {"title": "new", "rating": 5, "published": true}
→ Server reconciles current → desired
```

This eliminates ordering dependencies and race conditions.

## Integration Requirements

Teams contributing to a shared application must meet this baseline:

1. **Backend APIs expose business operations, not table-level CRUD**
2. **All mutating endpoints support idempotency keys** (AIP-155)
3. **Resources include etag for optimistic concurrency** (AIP-154)
4. **Authorization delegates to centralized AuthZ**
5. **BFF contains no database connections or business logic**
6. **Automated test coverage exists for API and BFF layers**

## Migration Strategy

### Phase 1: Establish Boundaries

1. Backend teams redesign APIs as business-operation endpoints
2. Remove BFF database connections, replace with API calls
3. Move authorization to centralized service
4. Establish test coverage requirements

### Phase 2: Harden Contracts

1. Migrate service-to-service communication to gRPC + Protocol Buffers
2. Proto schemas become canonical API contract
3. Generated client libraries with compatibility checks
4. Breaking changes caught at compile time

## Reviewing BFF Code

When auditing a BFF, look for:

| Red Flag | What It Means | AIP Guidance |
|----------|--------------|-------------|
| SQL/ORM imports | BFF owns data access | Move to backend API |
| `if/else` business rules | BFF owns domain logic | Backend custom methods (AIP-136) |
| Multiple API calls assembled into one response | BFF does orchestration | Backend composite endpoint |
| Permission checks | BFF owns auth decisions | Centralized AuthZ |
| No `request_id` on mutations | Not idempotent | Add per AIP-155 |
| No `etag` on resources | No concurrency control | Add per AIP-154 |
| `PUT` instead of `PATCH` | Backward compatibility risk | Switch to PATCH (AIP-134) |
