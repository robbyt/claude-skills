# uber-go-style-guide

Reviews Go code for adherence to Uber's Go Style Guide.

## Requirements

**Go 1.25.0 or later required.** This style guide uses modern Go features including:
- Automatic loop variable scoping (Go 1.22+)
- Generic slice functions and iterators (Go 1.21-1.23)
- Testing improvements (`testing/synctest`, `b.Loop()`) (Go 1.24-1.25)

## Usage

Trigger the skill by requesting a code review:
- "review this Go code"
- "check against Uber style guide"
- "review my PR"
- "review the work done so far"

## What it does

- Reviews Go code for critical bugs and important maintainability issues
- Checks for common violations like unhandled errors, race conditions, and panics
- Provides specific, actionable feedback with code examples
- Focuses on correctness, concurrency safety, and idiomatic patterns

## How it works

The skill uses a 3-phase workflow:

1. **Scope Identification** - Determines what to review (PR diff, specific files, recent commits)
2. **Code Analysis** - Reviews against bundled Uber Go Style Guide
3. **Report Findings** - Structured output with Critical and Important issues

## Bundled Resources

- `references/uber-go-style-guide.md` - Complete Uber Go Style Guide for offline reference
- `references/review-checklist.md` - Quick reference of common violations

## Focus Areas

### Critical Issues (Must Fix)
- Unhandled errors
- Type assertions without check
- Panics in production code
- Fire-and-forget goroutines
- Mutex races and missing defers

### Important Issues (Should Fix)
- Error handling patterns
- Boundary safety (slice/map copying)
- Struct design and initialization
- Concurrency lifecycle management
- Performance optimizations

## Integration

Works alongside automated linters. Optionally invoke the `golangci-lint` skill for complementary static analysis.

## Review Principles

1. **Specific** - Quote exact code, provide exact fixes
2. **Cited** - Reference specific style guide sections
3. **Explained** - Why does this matter?
4. **Prioritized** - Critical issues first, important second
5. **Balanced** - Acknowledge good code patterns

## Source

Based on the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).
