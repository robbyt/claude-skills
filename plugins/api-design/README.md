# api-design

API design review, audit, and architecture guidance based on Google's API Improvement Proposals (AIPs).

## Skill: API Review

Expert guidance for API design based on the same standards governing all public Google APIs. These principles are universal and apply to any organization building REST, gRPC, or BFF/backend APIs.

**Triggers on:** "review this API", "API design review", "PATCH vs PUT", "etag", "idempotency", "pagination design", "BFF architecture", "resource-oriented design", "TOCTOU", "race condition", "backward compatibility", and more.

### What It Covers

- **Resource-oriented design** (AIP-121, 122, 123) — hierarchies, naming, types
- **Standard methods** (AIP-131–135) — Get, List, Create, Update, Delete
- **Custom methods** (AIP-136) — business operations beyond CRUD
- **Concurrency control** (AIP-154, 155) — ETags, idempotency, TOCTOU prevention
- **Declarative interfaces** (AIP-128) — desired-state pattern, reconciliation
- **Data handling** (AIP-158, 160, 161, 203, 235) — pagination, filtering, field masks, batch
- **Lifecycle & errors** (AIP-193, 216, 164, 214) — error codes, state enums, soft delete
- **Compatibility** (AIP-192) — breaking vs non-breaking changes
- **BFF architecture** — layer boundaries, anti-patterns, migration guidance

### Reference Files

Includes 20 reference documents with detailed AIP guidance, code examples, and review checklists.

## Usage

Once installed, the skill triggers when working on API design tasks. When reviewing code, it cites specific AIP numbers for every recommendation, giving teams linkable references at https://google.aip.dev/{number}.
