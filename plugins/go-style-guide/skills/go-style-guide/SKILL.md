---
name: go-style-guide
description: Review Go code for adherence to Go Style Guide. Use when the user requests a code review of completed work, pull requests, or feature branches in Go projects. Focuses on critical bugs, race conditions, and important maintainability issues. Trigger phrases include "review this Go code", "check against style guide", "review my PR", or "review the work done so far".
---

# Go Style Guide Reviewer

Review Go code against comprehensive style guide, focusing on critical bugs and important maintainability issues.

**This guide assumes Go 1.25+ and does not consider backwards compatibility.** All patterns use modern Go best practices.

## Reference Files

Load references based on code patterns found during review:

| Code Pattern | Reference File |
|--------------|----------------|
| `go func()`, `sync.Mutex`, `sync.`, channels, atomic | `references/concurrency.md` |
| `err`, `error`, `panic`, `Must` functions | `references/errors.md` |
| `interface`, embedding, receivers, `func New`, `init()` | `references/api-design.md` |
| slice/map return, `slices.Clone`, `maps.Clone` | `references/api-design.md` |
| `_test.go`, `t.`, `b.` | `references/testing.md` |
| naming, comments, logging | `references/style.md` |

**Quick reference**: `references/review-checklist.md` - critical patterns with code examples

**Note**: "Copying at boundaries" lives in api-design.md but relates to concurrency safety - check both when ownership/encapsulation is the concern.

## Quick Style Reference

Basic rules that don't need a file lookup:

- **Package names**: lowercase, no underscores, singular (`net/url` not `net/urls`)
- **Receiver names**: 1-2 letters, consistent across all methods (`func (c *Client) Connect()`)
- **Error strings**: lowercase, no punctuation (`errors.New("connection failed")`)
- **Variable names**: short for small scopes (`i`, `v`), longer for large scopes (`requestTimeout`)

## Review Process

Follow this 3-phase workflow for systematic code review:

### Phase 1: Scope Identification

Determine what code to review based on the user's request:

**Pull Request / Branch Review**:
```bash
# Get all changed files in branch
git diff --name-only main...HEAD | grep '\.go$'

# Get diff with context
git diff main...HEAD
```

**Specific Files**:
```bash
# User specifies file(s) directly
# Read the files using the Read tool
```

**Recent Work**:
```bash
# Review recent commits
git log --oneline -n 10
git diff HEAD~5..HEAD
```

**Output**: List of Go files and changes to review.

### Phase 2: Code Analysis

Review the code systematically using the bundled references:

1. **Start with critical issues** (load `references/review-checklist.md` for quick patterns):
   - Unhandled errors
   - Type assertions without check
   - Panics in production code
   - Fire-and-forget goroutines
   - Mutex races and missing defers
   - Nil pointer dereferences

2. **Check important patterns**:
   - Error handling (wrapping, naming, handling once)
   - Boundary safety (copying slices/maps)
   - Struct design (embedding, initialization)
   - Concurrency lifecycle (goroutine management)
   - Exit handling (os.Exit only in main)

3. **Consult topic files as needed** (see Reference Files table above):
   - For detailed explanations of specific patterns
   - When encountering unfamiliar idioms
   - To verify best practices for specific scenarios

**Grep patterns for architectural issues**:
```bash
# Find panic usage (context-dependent - init/main vs library)
rg 'panic\(' --type go

# Find goroutine launches (check lifecycle management)
rg '\bgo\s+' --type go

# Find os.Exit or log.Fatal (should only be in main)
rg '(os\.Exit|log\.Fatal)' --type go

# Find global var declarations (check for mutable state)
rg '^var\s+\w+\s*=' --type go
```

### Phase 3: Report Findings

Structure the review with **Critical** and **Important** issues only (skip Minor issues per user preference).

**Format**:

```markdown
## Code Review Summary

[1-2 sentence overview of code quality and adherence]

**Note**: This review focuses on architectural and semantic issues that require human judgment. For syntax, formatting, and common bugs (unhandled errors, type assertions, etc.), ensure `golangci-lint` is run separately.

## Critical Issues

[Issues that could cause bugs, panics, or data races - MUST fix]

### [Issue Title]
**Location**: `file.go:123` or `functionName()`
**Severity**: Critical

**Current Code**:
```go
[problematic code snippet]
```

**Issue**: [What's wrong and why it's critical]

**Recommended**:
```go
[corrected code]
```

**Guideline**: [Reference to style guide section, e.g., "Error Handling > Type Assertions"]

---

## Important Issues

[Issues affecting maintainability, performance, or style - Should fix]

[Use same format as Critical Issues]

---

## Positive Observations

[Acknowledge good practices: proper error wrapping, clean concurrency patterns, good test structure]

---

## Recommendations

1. [Prioritized action items]
2. [Suggest running golangci-lint skill if not already done]
```

## Optional: Automated Linting Integration

Before or after manual review, suggest running automated linters for complementary coverage:

**If golangci-lint skill is available**:
"Consider running the `golangci-lint` skill for automated static analysis. Say 'run golangci-lint' to execute."

**Manual linting**:
```bash
# Run staticcheck
staticcheck ./...

# Run golangci-lint
golangci-lint run
```

## Key Focus Areas

### Critical (Architecture & Safety)
- Goroutine lifecycle issues (fire-and-forget)
- Race conditions (requires race detector, not linter)
- Panics in production (context-dependent: library vs main)

### Important (Design & Patterns)
- Error handling strategy (when/where to handle, observability boundaries)
- Data ownership (boundaries, copying, shared state)
- Concurrency patterns (channel sizing, context propagation)
- API design (embedding, evolution, encapsulation)
- Testing strategy (table-driven, parallel, time mocking)

### Skip (Handled by Linters or Out of Scope)

**Linter-Caught Issues**:
- Unhandled errors (errcheck)
- Type assertions without checks (staticcheck)
- Missing struct field names (govet)
- Import grouping (goimports/gci)
- Formatting issues (gofmt)
- Common bugs (staticcheck, govet)

**Subjective Preferences (Do Not Flag)**:
- **Assertion library choice**: Use what codebase uses; don't add to new projects unless requested. Both manual checks and assertion libraries (testify, assert) are valid.
- **Line length variations**: Focus on refactoring opportunities, not mechanical line breaking
- **Test helper patterns**: Either `testing.T` parameter or returning errors acceptable; ensure `t.Helper()` used
- **Performance nitpicks**: Only flag when profiling data shows actual impact

## Review Principles

When evaluating code, apply Google's Core Principles in order (from `references/style.md`):
1. **Clarity**: Is the purpose and rationale clear?
2. **Simplicity**: Does it accomplish goals in the straightforward manner?
3. **Concision**: High signal-to-noise ratio?
4. **Maintainability**: Can future programmers modify it correctly?
5. **Consistency**: Aligns with broader codebase patterns?

Then apply specific review guidance:
1. **Be specific**: Quote exact code, provide exact fixes
2. **Cite guidelines**: Reference specific sections of the style guide
3. **Explain impact**: Why does this matter? (correctness, maintainability, performance)
4. **Prioritize**: Critical issues first, important second
5. **Acknowledge good code**: Recognize patterns that follow the core principles

## When to Load Reference Files

Load `references/review-checklist.md` first for quick architectural patterns - it focuses on semantic issues requiring judgment.

Load topic-specific files based on code patterns (see Reference Files table):
- `concurrency.md` - goroutines, mutexes, races, channels
- `errors.md` - error types, wrapping, panic avoidance
- `api-design.md` - interfaces, function design, data boundaries
- `testing.md` - table tests, parallel tests, benchmarks
- `style.md` - naming, documentation, code style

**Important**: Skip reporting issues that golangci-lint would catch. The agent should focus on design, architecture, and context-dependent patterns that require human understanding.

## Context Matters

Some patterns have exceptions:
- `init()` acceptable for database driver registration
- `panic()` acceptable in tests (use `t.Fatal` or `t.FailNow`)
- Global constants acceptable
- Embedding in private structs sometimes acceptable for composition

Apply judgment based on context and domain.
