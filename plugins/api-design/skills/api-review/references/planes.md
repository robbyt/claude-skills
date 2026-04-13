# API Planes: Management vs Data

Reference: [AIP-111](https://google.aip.dev/111)

## Two Planes

APIs are divided into two planes based on what they operate on:

### Management Plane

Uniform, resource-oriented API for provisioning, configuring, and retrieving resources.

**Examples:**
- Virtual machines, networks, disks
- Database instances, storage buckets
- Projects, accounts, teams
- Configuration objects

**Characteristics:**
- Must follow standard methods (AIP-131–135)
- Declarative clients (Terraform, Pulumi) operate here exclusively
- Lower throughput requirements
- Strong consistency required (mutations immediately visible)

### Data Plane

Heterogeneous API for reading and writing user data, operating on resources provisioned
by the management plane.

**Examples:**
- Reading/writing database rows
- Pushing/pulling from message queues
- Uploading/downloading blobs
- Streaming events

**Characteristics:**
- May be heterogeneous (SQL, streaming, custom protocols)
- On the critical path of user-facing functionality
- Higher availability requirements
- Higher performance and throughput requirements
- May expose via resource-oriented APIs (must then follow management plane rules)

## Key Distinctions

| Aspect | Management Plane | Data Plane |
|--------|-----------------|------------|
| **Purpose** | Provision and configure | Read/write user data |
| **Uniformity** | Must be resource-oriented | May be heterogeneous |
| **Declarative clients** | Required support | Not expected |
| **Availability** | Standard | Higher |
| **Performance** | Standard | Higher sensitivity |
| **Throughput** | Lower | Higher |
| **User-specified IDs** | **Must** allow (AIP-133) | **Should** allow |
| **Standard methods** | Required | Recommended if resource-oriented |

## Impact on API Design

### Management Plane Requirements

Management plane operations have stricter requirements:

- User-specified resource IDs **must** be supported (AIP-133)
- Strong consistency **must** be guaranteed (AIP-121)
- Standard methods **must** be used where applicable
- Declarative-friendly patterns **should** be followed (AIP-128)
- ETags **must** be included (AIP-154)

### Data Plane Flexibility

Data plane APIs have more flexibility:

- May use non-standard protocols for performance
- User-specified IDs only **should** (not must) be supported
- Exceptions allowed for: no disambiguation needed, no declarative client exposure
- May prioritize throughput/latency over strict consistency

## Architecture Connection

From the BFF architecture principles:

- **Backend APIs** (management plane): expose business operations with full AIP compliance
- **Data plane operations**: may use optimized protocols (gRPC streaming, etc.)
- **BFF**: thin layer routing to appropriate plane — never implements business logic for either

When reviewing an API, first identify which plane it operates on. Management plane APIs
have stricter requirements; data plane APIs have more flexibility but should still follow
AIP patterns where applicable.

## Review Checklist

- [ ] API plane (management vs data) is clearly identified
- [ ] Management plane APIs follow strict AIP compliance (AIP-111)
- [ ] Management plane supports user-specified IDs on Create (AIP-133)
- [ ] Management plane guarantees strong consistency (AIP-121)
- [ ] Data plane APIs follow AIP patterns where applicable (AIP-111)
- [ ] Data plane exceptions are documented and justified
