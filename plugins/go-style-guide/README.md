# go-style-guide

Reviews Go code for adherence to Go Style Guide.

## Requirements

**Go 1.25.0 or later required.** This style guide uses modern Go features including:
- Automatic loop variable scoping (Go 1.22+)
- Generic slice/map functions and iterators (Go 1.21-1.23)
- JSON `omitzero` and `os.Root` filesystem safety (Go 1.24)
- Testing improvements (`testing/synctest`, `b.Loop()`, `t.Context()`) (Go 1.24-1.25)

## Usage

Trigger the skill by requesting a code review:
- "review this Go code"
- "check against style guide"
- "review my PR"
- "review the work done so far"

## What it does

- **Focuses on Architecture**: Concurrency patterns, data ownership, and API design
- **Ignores Linting**: Skips formatting, import ordering, and syntax nitpicks covered by `golangci-lint`
- **Modernization**: Suggests architectural refactors like `testing/synctest` and `os.Root` adoption
- **Safety**: Checks for race conditions and goroutine leaks that static analysis misses

## How it works

The skill uses a 3-phase workflow:

1. **Scope Identification** - Determines what to review (PR diff, specific files, recent commits)
2. **Code Analysis** - Reviews against bundled Go Style Guide
3. **Report Findings** - Structured output with Critical and Important issues

## Bundled Resources

- `references/go-style-guide.md` - Complete Go Style Guide for offline reference
- `references/review-checklist.md` - Quick reference of common violations

## Focus Areas

### Critical Issues (Architecture & Safety)
- Fire-and-forget goroutines (lifecycle)
- Mutex races (requires race detector)
- Panics in production code (context-dependent)

### Important Issues (Design & Patterns)
- Error handling strategy (when/where to handle)
- Data ownership (boundaries, copying)
- Concurrency patterns (channels, lifecycle)
- API design (embedding, evolution)
- Testing strategy (table-driven, parallel, time mocking)

## Recommended Linter Setup

This guide complements (not duplicates) automated tools. Use with:

```bash
golangci-lint run --enable=errcheck,staticcheck,govet,gocritic,perfsprint,goimports,gci,nilslice,prealloc,thelper
```

The style guide focuses on what linters can't catch: architectural decisions, ownership semantics, and context-aware patterns.

## Integration

Works alongside golangci-lint. The skill focuses on semantic issues while linters handle syntax and common bugs.

## Review Principles

1. **Specific** - Quote exact code, provide exact fixes
2. **Cited** - Reference specific style guide sections
3. **Explained** - Why does this matter?
4. **Prioritized** - Critical issues first, important second
5. **Balanced** - Acknowledge good code patterns

## Source

Based on the [Google Go Style Guide](https://google.github.io/styleguide/go/) and [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).
