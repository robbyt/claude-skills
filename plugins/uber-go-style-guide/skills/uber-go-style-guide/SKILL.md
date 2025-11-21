---
name: uber-go-style-guide
description: Review Go code for adherence to Uber's Go Style Guide. Use when the user requests a code review of completed work, pull requests, or feature branches in Go projects. Focuses on critical bugs, race conditions, and important maintainability issues. Trigger phrases include "review this Go code", "check against Uber style guide", "review my PR", or "review the work done so far".
---

# Uber Go Style Guide Reviewer

Review Go code against Uber's comprehensive style guide, focusing on critical bugs and important maintainability issues.

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

3. **Consult full guide as needed** (load `references/uber-go-style-guide.md`):
   - For detailed explanations of specific patterns
   - When encountering unfamiliar idioms
   - To verify best practices for specific scenarios

**Grep patterns for common issues**:
```bash
# Find potential unhandled errors
rg '^\s*[a-zA-Z_][a-zA-Z0-9_]*\(' --type go

# Find type assertions
rg '\.\([a-zA-Z]' --type go

# Find panic usage
rg 'panic\(' --type go

# Find go keyword (goroutines)
rg '\bgo\s+' --type go

# Find os.Exit or log.Fatal outside main
rg '(os\.Exit|log\.Fatal)' --type go
```

### Phase 3: Report Findings

Structure the review with **Critical** and **Important** issues only (skip Minor issues per user preference).

**Format**:

```markdown
## Code Review Summary

[1-2 sentence overview of code quality and adherence]

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

### Critical (Must Catch)
- Unhandled errors
- Panics in production
- Race conditions
- Goroutine lifecycle issues
- Type assertion failures

### Important (Should Catch)
- Error handling patterns (wrapping, multiple handling)
- Boundary safety (slice/map copying)
- Exit handling (os.Exit location)
- Struct design (embedding, initialization)
- Performance (strconv vs fmt, container capacity)

### Skip
- Minor style inconsistencies
- Line length nitpicks
- Trivial naming suggestions

## Review Principles

1. **Be specific**: Quote exact code, provide exact fixes
2. **Cite guidelines**: Reference specific sections of the style guide
3. **Explain impact**: Why does this matter? (correctness, maintainability, performance)
4. **Prioritize**: Critical issues first, important second
5. **Acknowledge good code**: Recognize proper patterns

## When to Load Full Style Guide

Load `references/uber-go-style-guide.md` when:
- Encountering unfamiliar patterns that need detailed explanation
- User asks about specific style guide sections
- Need comprehensive examples for a particular topic
- Verifying best practices for complex scenarios (functional options, advanced concurrency)

The review-checklist covers 90% of common issues. Load the full guide for the remaining 10%.

## Context Matters

Some patterns have exceptions:
- `init()` acceptable for database driver registration
- `panic()` acceptable in tests (use `t.Fatal` or `t.FailNow`)
- Global constants acceptable
- Embedding in private structs sometimes acceptable for composition

Apply judgment based on context and domain.
