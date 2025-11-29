# go-style-guide

Reviews Go code against a style guide combining Google and Uber Go style guides.

## Requirements

Go 1.25.0 or later. Uses features from Go 1.22-1.25:
- Automatic loop variable scoping (Go 1.22+)
- Generic slice/map functions and iterators (Go 1.21-1.23)
- JSON `omitzero` and `os.Root` filesystem safety (Go 1.24)
- Testing improvements (`testing/synctest`, `b.Loop()`, `t.Context()`) (Go 1.24-1.25)

## Triggers

- "review this Go code"
- "check against style guide"
- "review my PR"
- "review the work done so far"

## Workflow

1. **Scope Identification** - Determines what to review (PR diff, specific files, recent commits)
2. **Code Analysis** - Reviews against bundled Go Style Guide
3. **Report Findings** - Structured output with Critical and Important issues

## Focus Areas

### Critical (Architecture & Safety)
- Fire-and-forget goroutines (lifecycle)
- Mutex races (requires race detector)
- Panics in production code

### Important (Design & Patterns)
- Error handling strategy
- Data ownership boundaries
- Concurrency patterns
- API design
- Testing strategy

## Linter Integration

This guide complements automated tools. Use with:

```bash
golangci-lint run --enable=errcheck,staticcheck,govet,gocritic,perfsprint,goimports,gci,nilslice,prealloc,thelper
```

The skill focuses on what linters cannot catch: architectural decisions, ownership semantics, and context-aware patterns.

## Resources

- `references/go-style-guide.md` - Go Style Guide
- `references/review-checklist.md` - Common violations

## Source

Based on the [Google Go Style Guide](https://google.github.io/styleguide/go/) and [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).
