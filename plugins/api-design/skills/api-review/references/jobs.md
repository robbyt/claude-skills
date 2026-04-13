# Jobs

Reference: [AIP-152](https://google.aip.dev/152)

## Purpose

Some tasks need to run repeatedly, have separate configuration and execution phases, or
require distinct permissions for setup vs running. Jobs are persistent resources for these
cases -- unlike transient long-running operations (AIP-151), a Job can be configured once
and executed many times.

## When to Use Jobs vs LROs

| Characteristic | LRO (AIP-151) | Job (AIP-152) |
|----------------|---------------|---------------|
| Persistence | Transient, expires | Persistent resource |
| Execution | Once per operation | Repeatable via `:run` |
| Configuration | Inline in request | Stored on the resource |
| Permissions | Single permission | Separate config vs run permissions |
| Scheduling | Not applicable | Can be triggered on schedule |

## Resource Design

Job resource names **must** end with "Job" and the prefix **must** be a valid RPC name
(verb + noun):

```proto
message WriteBookJob {
  option (google.api.resource) = {
    type: "library.googleapis.com/WriteBookJob"
    pattern: "publishers/{publisher}/writeBookJobs/{write_book_job}"
  };

  string name = 1 [(google.api.field_behavior) = IDENTIFIER];

  // Job configuration fields
  string template = 2;
  string output_format = 3;
}
```

## Standard Methods + Run

Jobs **should** define all five standard methods (Create, Get, List, Update, Delete) for
configuration, plus a custom Run method for execution:

```proto
rpc RunWriteBookJob(RunWriteBookJobRequest)
    returns (google.longrunning.Operation) {
  option (google.api.http) = {
    post: "/v1/{name=publishers/*/writeBookJobs/*}:run"
    body: "*"
  };
  option (google.longrunning.operation_info) = {
    response_type: "RunWriteBookJobResponse"
    metadata_type: "RunWriteBookJobMetadata"
  };
}
```

### Run Method Rules

- **Must** begin with `Run` followed by singular job resource name
- **Must** return a long-running operation
- **Must** use `POST` with URI ending in `:run`
- **Must not** require additional required arguments beyond `name`
- Body clause **must** be `"*"`

## REST Examples

```
# Create and configure a job
POST /v1/publishers/acme/writeBookJobs?writeBookJobId=daily-report
{
  "template": "quarterly-summary",
  "outputFormat": "pdf"
}

# Run the job
POST /v1/publishers/acme/writeBookJobs/daily-report:run

# Returns an LRO
{
  "name": "publishers/acme/writeBookJobs/daily-report/operations/op-123",
  "done": false,
  "metadata": { ... }
}
```

## Execution History

For recurring jobs, execution results **may** be stored as a sub-collection:

- Executions **should** support Get, List, and Delete methods
- The LRO returned by Run **should** reference the child execution resource

## Anti-Patterns

### Conflating Job with LRO
**Wrong**: Using a Job for a one-time operation that doesn't need persistence
**Right**: Use LRO (AIP-151) for transient tasks; use Job only when config persists

### Extra required fields on Run
**Wrong**: `RunJob(name, additional_required_param)`
**Right**: All configuration stored on the Job resource; Run only takes `name`

### Missing standard methods
**Wrong**: Only Create + Run, no way to update or list jobs
**Right**: Full CRUD (Create, Get, List, Update, Delete) + Run

## Review Checklist

- [ ] Job resource name ends with "Job" (AIP-152)
- [ ] Job prefix is a valid verb + noun RPC name (AIP-152)
- [ ] Standard CRUD methods defined for configuration (AIP-152)
- [ ] Run method returns LRO, uses POST `:run` (AIP-152)
- [ ] Run method has no required fields beyond `name` (AIP-152)
- [ ] Job vs LRO choice is justified (AIP-151, AIP-152)
