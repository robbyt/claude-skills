# Uber Go Style Guide

This is the complete Uber Go Style Guide, bundled for offline reference during code reviews.

**Source**: https://github.com/uber-go/guide/blob/master/style.md

---

## Table of Contents

- [Overview](#overview)
- [Interface & Type Handling](#interface--type-handling)
- [Data Management](#data-management)
- [Error Handling](#error-handling)
- [Concurrency Best Practices](#concurrency-best-practices)
- [Struct & Type Organization](#struct--type-organization)
- [Program Initialization & Exit](#program-initialization--exit)
- [Performance Guidelines](#performance-guidelines)
- [Code Style Standards](#code-style-standards)
- [Testing Patterns](#testing-patterns)
- [Advanced Patterns](#advanced-patterns)
- [Linting & Tools](#linting--tools)

---

## Overview

The Uber Go Style Guide establishes conventions for writing Go code at Uber. It draws from:
- Effective Go
- Go Common Mistakes
- Go Code Review Comments
- Google Go Style Guide

**This guide requires Go 1.25.0 or later** and leverages modern language features including generics, automatic loop variable scoping, range functions, and testing improvements.

Recommended linting tools: `staticcheck`, `golangci-lint`, and `go vet`.

## Interface & Type Handling

### Pointers to Interfaces

**Bad**:
```go
type F interface {
  f()
}

type S1 struct{}
func (s S1) f() {}

type S2 struct{}
func (s *S2) f() {}

func bad() {
  s1Val := S1{}
  s1Ptr := &S1{}
  s2Val := S2{}
  s2Ptr := &S2{}

  var i F
  i = s1Val
  i = s1Ptr
  i = s2Ptr

  // Won't compile - s2Val is not addressable
  i = s2Val
}
```

**Good**:
```go
// Use interface directly, not pointer to interface
func good() {
  var i F
  i = &S1{}  // Pointer works
  i = S1{}   // Value works for value receiver methods
  i = &S2{}  // Pointer works for pointer receiver methods
}
```

**Why**: Interfaces already contain type information and data pointers. Passing them as pointers is redundant and can cause confusion.

---

### Verify Interface Compliance

**Bad**:
```go
type Handler struct {
  // ...
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  // ...
}

// No compile-time verification
```

**Good**:
```go
type Handler struct {
  // ...
}

// Compile-time verification
var _ http.Handler = (*Handler)(nil)

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  // ...
}
```

**Why**: Compile-time verification catches interface compliance issues immediately rather than at runtime.

---

### Receivers and Interfaces

Methods with value receivers work on both pointers and values. Methods with pointer receivers only work on pointers or addressable values.

**Example**:
```go
type S struct {
  data string
}

func (s S) Read() string {
  return s.data
}

func (s *S) Write(str string) {
  s.data = str
}

// Maps store non-addressable values
sVals := map[int]S{1: {"A"}}

// You can call Read on values
sVals[1].Read()

// COMPILE ERROR: cannot call pointer-receiver method on non-addressable value
sVals[1].Write("test")
```

**Why**: Understanding addressability prevents runtime errors and API design issues.

---

### Zero-value Mutexes

**Bad**:
```go
mu := new(sync.Mutex)
mu.Lock()
```

**Good**:
```go
var mu sync.Mutex
mu.Lock()
```

**Why**: `sync.Mutex` and `sync.RWMutex` have valid zero values. Use `var` declaration for clarity.

**Never embed mutexes**:

**Bad**:
```go
type SMap struct {
  sync.Mutex  // Exposes Lock/Unlock publicly
  data map[string]string
}

func NewSMap() *SMap {
  return &SMap{
    data: make(map[string]string),
  }
}
```

**Good**:
```go
type SMap struct {
  mu   sync.Mutex  // Private, unexported field
  data map[string]string
}

func NewSMap() *SMap {
  return &SMap{
    data: make(map[string]string),
  }
}
```

---

## Data Management

### Copy Slices and Maps at Boundaries

**Bad**:
```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = trips  // Caller can mutate
}

trips := ...
d1.SetTrips(trips)

trips[0] = ...  // Modifies d1.trips!
```

**Good**:
```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}

trips := ...
d1.SetTrips(trips)

trips[0] = ...  // Does not affect d1.trips
```

**Why**: Prevents unintended mutations and maintains encapsulation.

Similarly, return copies of internal slices/maps:

**Bad**:
```go
type Stats struct {
  mu sync.Mutex
  counters []int
}

func (s *Stats) Snapshot() []int {
  s.mu.Lock()
  defer s.mu.Unlock()
  return s.counters  // Caller can mutate without lock!
}
```

**Good**:
```go
func (s *Stats) Snapshot() []int {
  s.mu.Lock()
  defer s.mu.Unlock()

  result := make([]int, len(s.counters))
  copy(result, s.counters)
  return result
}
```

---

### Defer for Cleanup

**Bad**:
```go
p.Lock()
if p.count < 10 {
  p.Unlock()
  return p.count
}

p.count++
newCount := p.count
p.Unlock()

return newCount
```

**Good**:
```go
p.Lock()
defer p.Unlock()

if p.count < 10 {
  return p.count
}

p.count++
return p.count
```

**Why**: Defer ensures cleanup happens regardless of control flow. The performance overhead is negligible.

---

### Channel Size

Use buffer sizes of **zero** (unbuffered) or **one** only.

**Bad**:
```go
c := make(chan int, 64)  // Why 64? What happens at 65?
```

**Good**:
```go
c := make(chan int)      // Unbuffered - synchronous
c := make(chan int, 1)   // Buffered by 1 - specific use case
```

**Why**: Larger buffer sizes require extensive justification regarding overflow prevention and blocking behavior.

---

### Generic Slice Functions

Use the `slices` package (Go 1.21+) for common slice operations instead of manual implementations.

**Example operations**:
```go
import "slices"

// Clone - replaces manual copy
original := []int{1, 2, 3}
copy := slices.Clone(original)  // More readable than make+copy

// Sort - generic sorting
items := []string{"c", "a", "b"}
slices.Sort(items)  // In-place sort

// Compact - remove consecutive duplicates
data := []int{1, 1, 2, 2, 3}
unique := slices.Compact(data)  // Returns []int{1, 2, 3}

// Contains - membership test
found := slices.Contains(items, "a")

// Equal - deep equality
same := slices.Equal([]int{1, 2}, []int{1, 2})
```

**Replacing manual slice copying**:

**Bad**:
```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}
```

**Good**:
```go
import "slices"

func (d *Driver) SetTrips(trips []Trip) {
  d.trips = slices.Clone(trips)
}
```

**Important**: Modification functions in `slices` (Go 1.22+) "clear the tail" - zeroing obsolete elements. Always use the returned slice value:

```go
// Correct - use returned value
items = slices.Delete(items, 0, 1)

// Bug - original slice may have stale tail elements
slices.Delete(items, 0, 1)  // Don't ignore return value
```

---

### Range Functions & Iterators

Go 1.23+ supports custom iterators using `iter.Seq` for range loops.

**When to provide iterators**: For container types that benefit from idiomatic `for range` syntax.

**Example**:
```go
import "iter"

type Set[E comparable] struct {
  m map[E]struct{}
}

// Provide iterator for range loops
func (s *Set[E]) All() iter.Seq[E] {
  return func(yield func(E) bool) {
    for v := range s.m {
      if !yield(v) {
        return
      }
    }
  }
}

// Usage - idiomatic for/range
for v := range s.All() {
  fmt.Println(v)
}
```

**Replaces**: Channel-based iterators and callback patterns.

**Benefits**:
- Standard `for range` syntax
- Compiler-optimized iteration
- Early termination with `break`
- Compatible with range-over-function patterns

---

## Error Handling

### Error Types

Choose error approach based on needs:

| Error matching needed? | Error has dynamic message? | Approach |
|------------------------|----------------------------|----------|
| No | No | `errors.New` |
| No | Yes | `fmt.Errorf` |
| Yes | No | Top-level `var` with `errors.New` |
| Yes | Yes | Custom error type |

**Examples**:

```go
// No matching, static
err := errors.New("timeout")

// No matching, dynamic
err := fmt.Errorf("connection to %s failed", host)

// Matching, static
var ErrTimeout = errors.New("timeout")

// Matching, dynamic
type ConfigError struct {
  Path string
  Err  error
}

func (e *ConfigError) Error() string {
  return fmt.Sprintf("config error at %s: %v", e.Path, e.Err)
}
```

---

### Error Wrapping

Use `%w` when callers should access underlying errors. Use `%v` to obfuscate.

**Bad**:
```go
return fmt.Errorf("failed to create new store: %w", err)
```

**Good**:
```go
return fmt.Errorf("new store: %w", err)
```

**Why**: Avoid redundant "failed to" phrases. Error chains already show the failure path.

---

### Error Naming

- **Exported errors**: Use `Err` prefix (e.g., `ErrCouldNotOpen`)
- **Unexported errors**: Use `err` prefix (e.g., `errInvalidInput`)
- **Custom error types**: Use `Error` suffix (e.g., `NotFoundError`)

**Examples**:
```go
var (
  ErrNotFound     = errors.New("not found")
  errInvalidInput = errors.New("invalid input")
)

type ValidationError struct {
  Field string
}
```

---

### Handle Errors Once

Each error should be handled at **one** point in the call stack.

**Bad**:
```go
func writeFile(path string, data []byte) error {
  if err := os.WriteFile(path, data, 0644); err != nil {
    log.Printf("write failed: %v", err)  // Logs AND returns
    return fmt.Errorf("write %s: %w", path, err)
  }
  return nil
}
```

**Good**:
```go
func writeFile(path string, data []byte) error {
  if err := os.WriteFile(path, data, 0644); err != nil {
    return fmt.Errorf("write %s: %w", path, err)  // Return with context
  }
  return nil
}

// Caller decides to log
if err := writeFile(path, data); err != nil {
  log.Printf("failed: %v", err)
}
```

**Why**: Handling errors at multiple levels creates redundant logging and makes control flow unclear.

---

### Error Aggregation

Use `errors.Join` (Go 1.20+) to combine multiple errors.

**Example**:
```go
func processAll(items []Item) error {
  var errs []error

  for _, item := range items {
    if err := process(item); err != nil {
      errs = append(errs, fmt.Errorf("process %s: %w", item.ID, err))
    }
  }

  return errors.Join(errs...)  // Returns nil if errs is empty
}
```

**Why**: `errors.Join` automatically returns `nil` for empty slices and properly wraps multiple errors for inspection with `errors.Is` and `errors.As`.

**Checking aggregated errors**:
```go
err := processAll(items)
if errors.Is(err, ErrNotFound) {
  // Returns true if any joined error is ErrNotFound
}
```

---

### Type Assertions

Always use the comma-ok idiom.

**Bad**:
```go
t := i.(string)  // Panics if assertion fails
```

**Good**:
```go
t, ok := i.(string)
if !ok {
  // Handle gracefully
}
```

**Why**: Production code should never panic due to type assertions.

---

### Don't Panic

Production code must avoid panics. Return errors instead and let callers decide handling strategy.

**Exceptions**:
- Program initialization (main package)
- Test failures using `t.Fatal` or `t.FailNow`

**Bad**:
```go
func run(args []string) {
  if len(args) == 0 {
    panic("no arguments")  // Don't panic in production
  }
}
```

**Good**:
```go
func run(args []string) error {
  if len(args) == 0 {
    return errors.New("no arguments")
  }
  return nil
}

func main() {
  if err := run(os.Args[1:]); err != nil {
    log.Fatal(err)  // Only panic-equivalent in main
  }
}
```

---

## Concurrency Best Practices

### Atomic Operations

Use `sync/atomic` types for type-safe atomic operations (Go 1.19+).

**Bad**:
```go
import "sync/atomic"

type foo struct {
  running int32  // atomic
}

func (f *foo) start() {
  if atomic.SwapInt32(&f.running, 1) == 1 {
    return  // already running
  }
}
```

**Good**:
```go
import "sync/atomic"

type foo struct {
  running atomic.Bool
}

func (f *foo) start() {
  if f.running.Swap(true) {
    return  // already running
  }
}
```

**Why**: Type safety and convenience methods reduce errors. The `sync/atomic` package provides `Bool`, `Int32`, `Int64`, `Uint32`, `Uint64`, `Uintptr`, `Pointer[T]`, and `Value` types.

---

### Avoid Mutable Globals

**Bad**:
```go
var db *sql.DB

func init() {
  db = connectDB()  // Mutable global state
}

func GetDB() *sql.DB {
  return db
}
```

**Good**:
```go
type Config struct {
  DB *sql.DB
}

func New() (*Config, error) {
  db, err := connectDB()
  if err != nil {
    return nil, err
  }
  return &Config{DB: db}, nil
}
```

**Why**: Dependency injection improves testability by allowing mock substitution.

---

### Don't Fire-and-Forget Goroutines

Every spawned goroutine needs:
- A predictable stop time, OR
- A signaling mechanism to request stopping
- A way to wait for completion

**Bad**:
```go
go func() {
  for {
    flush()
    time.Sleep(delay)
  }
}()  // No way to stop this
```

**Good**:
```go
type Worker struct {
  stop chan struct{}
  done chan struct{}
}

func (w *Worker) Start() {
  go func() {
    defer close(w.done)
    ticker := time.NewTicker(delay)
    defer ticker.Stop()

    for {
      select {
      case <-ticker.C:
        flush()
      case <-w.stop:
        return
      }
    }
  }()
}

func (w *Worker) Stop() {
  close(w.stop)
  <-w.done
}
```

**Test with `go.uber.org/goleak`**:
```go
func TestWorker(t *testing.T) {
  defer goleak.VerifyNone(t)

  w := &Worker{
    stop: make(chan struct{}),
    done: make(chan struct{}),
  }
  w.Start()
  w.Stop()
}
```

---

### No Goroutines in init()

**Bad**:
```go
func init() {
  go monitor()  // Can't control lifecycle
}
```

**Good**:
```go
type Monitor struct {
  stop chan struct{}
}

func (m *Monitor) Start() {
  go m.run()
}

func (m *Monitor) Close() error {
  close(m.stop)
  return nil
}
```

**Why**: Objects should have explicit lifecycle methods like `Close()` or `Shutdown()`.

---

## Struct & Type Organization

### Avoid Embedding in Public Structs

**Bad**:
```go
type AbstractList struct{}

func (l *AbstractList) Add(e Entity) {
  // ...
}

type ConcreteList struct {
  AbstractList  // Exposes Add as public API
}
```

**Good**:
```go
type AbstractList struct{}

func (l *AbstractList) Add(e Entity) {
  // ...
}

type ConcreteList struct {
  list *AbstractList  // Private field
}

func (c *ConcreteList) Add(e Entity) {
  c.list.Add(e)  // Explicit delegation
}
```

**Why**: Embedding leaks implementation details and inhibits evolution.

---

### Avoid Built-in Names

Don't shadow predeclared identifiers.

**Bad**:
```go
func handleError(error string) {
  // Shadows built-in 'error' type
}

var string = "foo"  // Shadows built-in 'string'
```

**Good**:
```go
func handleError(errorMsg string) {
  // Clear and doesn't shadow
}

var msg = "foo"
```

---

### Avoid init()

Make code deterministic and testable. Only use `init()` for:
- Complex expressions that can't be single assignments
- Pluggable hooks (database drivers)
- Deterministic precomputation

**Avoid** in init():
- I/O operations
- Environment variable access
- Global state manipulation

**Bad**:
```go
var config Config

func init() {
  config = loadConfig()  // I/O in init
}
```

**Good**:
```go
var defaultConfig = Config{
  Timeout: 10 * time.Second,
}

func NewConfig() (*Config, error) {
  return loadConfig()
}
```

---

## Program Initialization & Exit

### Exit in Main

Call `os.Exit` or `log.Fatal` **only in `main()`**.

**Bad**:
```go
func run() {
  if err := setup(); err != nil {
    log.Fatal(err)  // Bypasses defers in caller
  }
}

func main() {
  defer cleanup()
  run()
}
```

**Good**:
```go
func run() error {
  if err := setup(); err != nil {
    return err
  }
  return nil
}

func main() {
  defer cleanup()
  if err := run(); err != nil {
    log.Fatal(err)  // Only in main
  }
}
```

**Why**: Preserves `defer` cleanup and improves testability.

---

### Exit Once

Refactor business logic into a separate function returning errors.

**Pattern**:
```go
func main() {
  if err := run(); err != nil {
    log.Fatal(err)
  }
}

func run() error {
  // All business logic here
  // Return errors instead of exiting
}
```

---

## Performance Guidelines

### Prefer strconv

For primitive-to-string conversions, `strconv` is ~2x faster than `fmt`.

**Bad**:
```go
s := fmt.Sprint(123)
```

**Good**:
```go
s := strconv.Itoa(123)
```

**Benchmark**:
```
BenchmarkFmtSprint-4    143 ns/op    2 allocs/op
BenchmarkStrconv-4       64.2 ns/op  1 allocs/op
```

---

### Avoid Repeated String-to-Byte Conversions

**Bad**:
```go
for i := 0; i < b.N; i++ {
  w.Write([]byte("Hello world"))  // Repeated conversion
}
```

**Good**:
```go
data := []byte("Hello world")
for i := 0; i < b.N; i++ {
  w.Write(data)  // Convert once
}
```

---

### Specify Container Capacity

Specify capacity hints when initializing maps and slices to avoid reallocation.

**Bad**:
```go
m := make(map[string]os.FileInfo)
for _, f := range files {
  m[f.Name()] = f
}
```

**Good**:
```go
m := make(map[string]os.FileInfo, len(files))
for _, f := range files {
  m[f.Name()] = f
}
```

**Slices**:
```go
// Append-only: specify capacity
files := make([]string, 0, len(input))

// Exact size known: specify length
files := make([]string, len(input))
```

---

### Clear Built-in

Use the `clear()` built-in (Go 1.21+) to efficiently clear maps and slices in place.

**Maps**:
```go
// Old - reallocates, loses capacity
m = make(map[string]int)

// Modern - clears in place, retains capacity
clear(m)
```

**Slices**:
```go
// Zeros all elements in place
s := make([]int, 10)
s[0] = 5
clear(s)  // All elements now zero
```

**Performance benefit**: Retains allocated memory, avoiding GC pressure and reallocation costs.

**When to use**:
- Reusing maps/slices across iterations
- Pooled objects that need clearing
- Performance-sensitive code where allocation matters

---

## Code Style Standards

### Line Length

Target 99 characters as a soft limit. Horizontal scrolling reduces readability.

---

### Consistency

Maintain uniform style within packages. Apply conventions at package level or larger.

---

### Import Grouping

Two groups only:
1. Standard library
2. Everything else

Separated by blank line. Use `goimports` for automatic formatting.

**Example**:
```go
import (
  "fmt"
  "os"
  "sync/atomic"

  "golang.org/x/sync/errgroup"
  "google.golang.org/protobuf/proto"
)
```

---

### Package Names

- All lowercase
- No underscores
- Short, succinct
- Singular (e.g., `net/url` not `net/urls`)
- Avoid generic names: "common," "util," "shared," "lib"

---

### Function Names

- Use `MixedCaps`
- Tests may contain underscores for grouping: `TestFunc_Condition`

---

### Group Similar Declarations

**Good**:
```go
const (
  a = 1
  b = 2
)

var (
  x = 1
  y = 2
)

type (
  Area float64
  Volume float64
)
```

Only group related items.

---

### Top-level Variables

Omit types if they match the expression.

**Bad**:
```go
var _s string = F()
```

**Good**:
```go
var _s = F()
```

---

### Prefix Unexported Globals

Use underscore prefix.

**Example**:
```go
var (
  _defaultPort = 8080
  _maxRetries  = 3
)
```

**Exception**: Unexported error values use `err` prefix without underscore.

---

### Local Variables

- Use `:=` for explicit assignments
- Use `var` when zero values are clearer

**Example**:
```go
var filtered []int  // Clear: empty slice

result := process()  // Explicit assignment
```

---

### nil is a Valid Slice

Return `nil` for empty slices, not `[]T{}`.

**Bad**:
```go
if len(results) == 0 {
  return []Result{}
}
```

**Good**:
```go
if len(results) == 0 {
  return nil
}
```

Check emptiness with `len(s) == 0`, not `s == nil`.

---

### Reduce Nesting

Handle error cases first, returning early.

**Bad**:
```go
if condition {
  // Deep nesting
  if anotherCondition {
    // More nesting
    if yetAnother {
      // Success case buried
    }
  }
}
```

**Good**:
```go
if !condition {
  return err
}

if !anotherCondition {
  return err
}

if !yetAnother {
  return err
}

// Success case at top level
```

---

### Unnecessary Else

If both branches set the same variable, eliminate else.

**Bad**:
```go
var a int
if b {
  a = 100
} else {
  a = 10
}
```

**Good**:
```go
a := 10
if b {
  a = 100
}
```

---

### Struct Initialization

Always use field names.

**Bad**:
```go
user := User{"John", "Doe", 30}  // Fragile
```

**Good**:
```go
user := User{
  FirstName: "John",
  LastName:  "Doe",
  Age:       30,
}
```

Omit zero-value fields unless they provide context.

**Zero-value structs**:
```go
var user User  // All fields zero-valued
```

**Pointer initialization**:
```go
user := &User{}  // Prefer over new(User)
```

---

### Map Initialization

- Use `make(map[T1]T2)` for empty maps
- Use literals for fixed elements

**Examples**:
```go
var m map[string]int  // nil map - read-only

m := make(map[string]int)  // Empty map - can write

m := map[string]int{
  "a": 1,
  "b": 2,
}
```

---

### Format Strings as const

Declare Printf format strings as `const` for static analysis.

**Bad**:
```go
msg := "values %v, %v\n"
fmt.Printf(msg, x, y)
```

**Good**:
```go
const msg = "values %v, %v\n"
fmt.Printf(msg, x, y)
```

---

### Raw String Literals

Use backticks to avoid escaping.

**Bad**:
```go
msg := "unknown error:\"test\""
```

**Good**:
```go
msg := `unknown error:"test"`
```

---

## Testing Patterns

### Table-Driven Tests

Use when testing against multiple input/output conditions.

**Example**:
```go
func TestParseURL(t *testing.T) {
  tests := []struct{
    name     string
    give     string
    wantHost string
    wantErr  bool
  }{
    {
      name:     "simple",
      give:     "http://example.com",
      wantHost: "example.com",
    },
    {
      name:    "invalid",
      give:    "://invalid",
      wantErr: true,
    },
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      u, err := ParseURL(tt.give)

      if tt.wantErr {
        assert.Error(t, err)
        return
      }

      assert.NoError(t, err)
      assert.Equal(t, tt.wantHost, u.Host)
    })
  }
}
```

**Benefits**:
- Reduces redundancy
- Easy to add new cases
- Clear test data structure

---

### Avoid Test Complexity

Split table tests with excessive conditionals into separate test functions.

**Bad**:
```go
tests := []struct{
  give        string
  shouldErr   bool
  shouldCall1 bool
  shouldCall2 bool
  check1      func()
  check2      func()
}{
  // Complex logic in table
}
```

**Good**:
```go
func TestSuccess(t *testing.T) {
  // Simple, focused test
}

func TestError(t *testing.T) {
  // Simple, focused test
}
```

---

### Parallel Tests

Go 1.22+ automatically scopes loop variables per-iteration, eliminating the need for manual capture.

**Example**:
```go
tests := []struct{ give string }{{give: "A"}, {give: "B"}}
for _, tt := range tests {
  t.Run(tt.give, func(t *testing.T) {
    t.Parallel()
    // tt is automatically per-iteration in Go 1.22+
  })
}
```

**Critical**: Never call `t.Fatal()` or `t.FailNow()` from goroutines other than the test goroutine - use `t.Error()` instead:

```go
func TestConcurrent(t *testing.T) {
  done := make(chan bool)

  go func() {
    if err := someOperation(); err != nil {
      t.Error(err)  // NOT t.Fatal - would panic
      done <- false
      return
    }
    done <- true
  }()

  if !<-done {
    t.Fatal("operation failed") // Only in main test goroutine
  }
}
```

---

### Testing Time

Use `testing/synctest` (Go 1.25+) for fast, deterministic testing of time-dependent code.

**Problem**: Tests using `time.Sleep` or `time.After` are slow and can be flaky.

**Old approach**:
```go
func TestTimeout(t *testing.T) {
  done := make(chan bool)

  go func() {
    time.Sleep(5 * time.Second)  // Slow!
    done <- true
  }()

  <-done
}
```

**Modern approach with synctest**:
```go
import "testing/synctest"

func TestTimeout(t *testing.T) {
  synctest.Run(func() {
    done := make(chan bool)

    go func() {
      time.Sleep(5 * time.Second)  // Executes instantly
      done <- true
    }()

    synctest.Wait()  // Wait for goroutines to block
    <-done           // Completes instantly
  })
}
```

**Benefits**:
- Tests run instantly (no actual sleeping)
- Deterministic timing behavior
- No modifications to production code
- Detects deadlocks and timing bugs

**When to use**: Any test involving `time.Sleep`, `time.After`, `time.NewTimer`, or `time.NewTicker`.

---

### Benchmark Loop Pattern

Use `b.Loop()` (Go 1.24+) for cleaner benchmark code.

**Old pattern**:
```go
func BenchmarkOperation(b *testing.B) {
  // Expensive setup
  data := setupData()

  b.ResetTimer()  // Easy to forget!

  for i := 0; i < b.N; i++ {
    operation(data)
  }

  b.StopTimer()  // Also easy to forget
  // Cleanup
}
```

**Modern pattern**:
```go
func BenchmarkOperation(b *testing.B) {
  // Expensive setup - timer not running yet
  data := setupData()

  for b.Loop() {
    operation(data)  // Automatically measured
  }

  // Cleanup - timer already stopped
}
```

**Benefits**:
- Eliminates forgotten `ResetTimer`/`StopTimer` calls
- Prevents dead-code elimination issues
- Cleaner, less error-prone API
- Setup/cleanup automatically excluded from timing

---

## Advanced Patterns

### Functional Options

For APIs with optional parameters that may expand over time.

**Pattern**:
```go
type options struct {
  cache  bool
  logger *zap.Logger
}

type Option interface {
  apply(*options)
}

type cacheOption bool

func (c cacheOption) apply(opts *options) {
  opts.cache = bool(c)
}

func WithCache(c bool) Option {
  return cacheOption(c)
}

func Open(addr string, opts ...Option) (*Connection, error) {
  options := options{
    cache:  defaultCache,
    logger: zap.NewNop(),
  }

  for _, o := range opts {
    o.apply(&options)
  }

  // Use options
}
```

**Benefits**:
- Optional parameters only when needed
- Future extensibility without breaking changes
- Self-documenting API

---

### Generic Interface Patterns

Use generic interfaces (Go 1.18+) for type-safe constraints and self-referential patterns.

**Self-referential constraints**:
```go
// Constraint where types must compare with themselves
type Comparer[T any] interface {
  Compare(T) int
}

// Generic function using the constraint
func BinarySearch[E Comparer[E]](items []E, target E) int {
  low, high := 0, len(items)-1

  for low <= high {
    mid := (low + high) / 2
    cmp := target.Compare(items[mid])

    if cmp == 0 {
      return mid
    } else if cmp < 0 {
      high = mid - 1
    } else {
      low = mid + 1
    }
  }

  return -1
}
```

**Type-safe builder pattern**:
```go
type Builder[T any] interface {
  Build() T
}

func BuildAll[T any, B Builder[T]](builders []B) []T {
  results := make([]T, len(builders))
  for i, b := range builders {
    results[i] = b.Build()
  }
  return results
}
```

**When to use**:
- Types that need to reference themselves in method signatures
- Abstracting operations across varied types with different constraints
- Type-safe collections and algorithms

**Benefits**:
- Eliminates `interface{}` and type assertions
- Compile-time type safety
- Clearer API contracts

---

## Linting & Tools

### Recommended Linters

- **errcheck**: Error handling verification
- **goimports**: Code formatting and import management
- **golint**: Common style issues
- **govet**: Common mistakes
- **staticcheck**: Static analysis

### golangci-lint

Recommended runner for large codebases. Offers performance and multi-linter configuration.

**Configuration**:
```yaml
linters:
  enable:
    - errcheck
    - goimports
    - golint
    - govet
    - staticcheck
```

### Editor Setup

Configure editors to:
- Run `goimports` on save
- Validate with `golint` and `go vet`
- Show inline linter warnings

---

## Summary

This guide emphasizes that style conventions go beyond formatting—they encompass:
- Error handling patterns
- Concurrency safety
- API design principles
- Maintainability practices

These are essential for productive Go development at scale.
