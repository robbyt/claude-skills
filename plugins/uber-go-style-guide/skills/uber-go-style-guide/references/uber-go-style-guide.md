# Uber Go Style Guide

This is the complete Uber Go Style Guide, bundled for offline reference during code reviews.

**Source**: https://github.com/uber-go/guide/blob/master/style.md

---

## Table of Contents

- [Overview](#overview)
- [Core Principles](#core-principles)
- [Interface & Type Handling](#interface--type-handling)
- [Interface Design Principles](#interface-design-principles)
- [Function Design](#function-design)
- [Data Management](#data-management)
- [Error Handling](#error-handling)
- [Concurrency Best Practices](#concurrency-best-practices)
- [Struct & Type Organization](#struct--type-organization)
- [Documentation Standards](#documentation-standards)
- [Program Initialization & Exit](#program-initialization--exit)
- [Logging and Configuration](#logging-and-configuration)
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

**This guide requires Go 1.25.0 or later** and leverages modern language features including generics, automatic loop variable scoping, range functions, and testing improvements. **This guide does not consider backwards compatibility** - all patterns use current Go best practices.

Recommended linting tools: `staticcheck`, `golangci-lint`, and `go vet`.

## Core Principles

When writing Go code, apply these five principles in hierarchical order. Earlier principles take precedence over later ones:

1. **Clarity**: Code should be understandable. The purpose and rationale should be clear to readers.
2. **Simplicity**: Code should accomplish its goals in the most straightforward way possible.
3. **Concision**: Code should have a high signal-to-noise ratio with minimal redundancy.
4. **Maintainability**: Code should be easy for future programmers to modify correctly and safely.
5. **Consistency**: Code should align with broader patterns in the codebase and ecosystem.

### Using These Principles

These principles form a decision-making framework for situations not explicitly covered by the guide:

- When code patterns conflict, apply these principles in order to determine the better approach
- When multiple valid implementations exist, choose the one that best satisfies these principles
- When making trade-offs, explain which principle takes precedence and why

**Example**: A function could be made more concise by using clever shortcuts, but doing so would reduce clarity. In this case, **clarity takes precedence** - write the clearer version even if it's slightly longer.

**Example**: Code could be made more consistent with outdated patterns in an old codebase, but modern Go has better approaches. Here **simplicity and maintainability** (using modern patterns) may outweigh strict consistency with legacy code.

These principles guide all specific recommendations in this style guide.

---

## Interface & Type Handling

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

---

## Interface Design Principles

### Interfaces Belong in Consumer Packages

Interfaces generally belong in packages that consume interface values, not packages that implement them.

**Bad - producer defines interface**:
```go
package producer

// Wrong - interface defined where it's implemented
type Reader interface {
  Read() []byte
}

type FileReader struct{}

func (f *FileReader) Read() []byte {
  // implementation
}
```

**Good - consumer defines interface**:
```go
package consumer

// Interface defined where it's needed
type Reader interface {
  Read() []byte
}

func Process(r Reader) {
  data := r.Read()
  // use data
}
```

```go
package producer

// Returns concrete type
type FileReader struct{}

func (f *FileReader) Read() []byte {
  // implementation
}
```

**Why**: This pattern:
- Allows adding new implementations without modifying the original package
- Keeps interfaces minimal (only methods actually needed)
- Prevents premature abstraction
- Enables better API evolution

**Exceptions exist**: Sometimes producer-defined interfaces make sense (e.g., `io.Reader`, plugin systems). Use judgment based on your use case.

---

### Return Concrete Types

Functions should return concrete types, not interfaces, unless there's a compelling reason to hide the implementation.

**Bad**:
```go
func NewUserStore() UserStore {
  return &userStoreImpl{}
}
```

**Good**:
```go
func NewUserStore() *UserStore {
  return &UserStore{}
}
```

**Why**: Returning concrete types allows adding methods later without breaking callers. Only return interfaces when you need to enforce abstraction boundaries.

---

### Avoid Premature Interface Definitions

Don't define interfaces before you have realistic usage. Interfaces should emerge from actual needs.

**Bad**:
```go
// No consumers yet - premature abstraction
type DataProcessor interface {
  Process(data []byte) error
  Validate() bool
  Transform() Result
}
```

**Good**:
```go
// Start with concrete implementation
type DataProcessor struct {
  // fields
}

func (d *DataProcessor) Process(data []byte) error {
  // implementation
}

// Later, when you have multiple implementations, extract interface
```

**Why**: Interfaces defined without real usage tend to be too large or poorly designed. Let usage patterns guide interface design.

---

### Don't Create Custom Context Types

Always use `context.Context` from the standard library. Custom context types fragment the ecosystem.

**Bad**:
```go
type AppContext struct {
  context.Context
  UserID string
}

func ProcessRequest(ctx AppContext) {
  // ...
}
```

**Good**:
```go
func ProcessRequest(ctx context.Context) {
  userID := ctx.Value(userIDKey).(string)
  // ...
}
```

**Why**: Custom context types prevent interoperability with standard library functions and third-party code expecting `context.Context`.

---

## Function Design

### Prefer Synchronous Functions

Prefer synchronous functions over asynchronous ones. Keep goroutine management localized to callers.

**Bad**:
```go
func ProcessData(data []byte) {
  go func() {
    // Hidden concurrency - caller can't control it
    result := process(data)
    store(result)
  }()
}
```

**Good**:
```go
func ProcessData(data []byte) Result {
  result := process(data)
  return result
}

// Caller controls concurrency
go func() {
  result := ProcessData(data)
  store(result)
}()
```

**Why**: Synchronous functions give callers control over concurrency, making goroutine lifetimes clear and testability easier.

---

### Make Goroutine Lifetimes Clear

When functions do spawn goroutines, make it obvious when or whether they exit.

**Bad**:
```go
func StartMonitor() {
  go monitor()  // When does this stop? How?
}
```

**Good**:
```go
type Monitor struct {
  stop chan struct{}
  done chan struct{}
}

func (m *Monitor) Start() {
  go m.run()
}

func (m *Monitor) Stop() {
  close(m.stop)
  <-m.done  // Wait for completion
}
```

**Why**: Clear goroutine lifetimes prevent leaks and enable graceful shutdown.

---

### Context Should Be First Parameter

Context should be the first parameter of functions (except HTTP handlers and streaming RPC methods where it's implicit).

**Good**:
```go
func FetchUser(ctx context.Context, userID string) (*User, error) {
  // ...
}

func ProcessBatch(ctx context.Context, items []Item, opts *Options) error {
  // ...
}
```

**Exception - HTTP handlers**:
```go
func HandleRequest(w http.ResponseWriter, r *http.Request) {
  ctx := r.Context()  // Context from request
  // ...
}
```

**Why**: Consistent parameter order improves API discoverability and follows ecosystem conventions.

---

### Pass Values, Not Pointers (Usually)

Pass values unless the function needs to mutate the argument or the type is non-copyable.

**Prefer values**:
```go
func FormatTimestamp(t time.Time) string {
  return t.Format(time.RFC3339)
}
```

**Use pointers when**:
```go
// 1. Function mutates the argument
func UpdateUser(u *User) {
  u.LastModified = time.Now()
}

// 2. Type contains non-copyable fields (sync.Mutex, etc.)
type Config struct {
  mu sync.Mutex
  data map[string]string
}

func LoadConfig(c *Config) error {
  // Must use pointer - Config contains mutex
}

// 3. Type is very large and copying would be expensive (profile first!)
```

**Why**: Value parameters prevent accidental mutations and make data flow clearer. Only use pointers when necessary for correctness.

---

### Receiver Type Choice

Choose receiver types based on correctness, not performance optimization.

**Use pointer receivers when**:
- Method mutates the receiver
- Receiver contains non-copyable fields (mutexes, channels)
- Receiver is very large (but profile first)
- Some methods already have pointer receivers (consistency)

**Use value receivers when**:
- Method doesn't mutate receiver
- Receiver is a small struct or primitive type
- Receiver is a copyable value type (like `time.Time`)

**Mixing**: Avoid mixing pointer and value receivers for the same type (except for specific performance needs identified through profiling).

---

## Data Management

### JSON omitzero

Use the `omitzero` struct tag (Go 1.24+) to omit zero values during marshaling, replacing error-prone `omitempty` pointer patterns.

**Bad**:
```go
type User struct {
  // Pointer used only to allow omitting zero value (0)
  Age *int `json:"age,omitempty"`
}
```

**Good**:
```go
type User struct {
  // Clearer intent, no pointer needed
  Age int `json:"age,omitzero"`
}
```

---

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

### Safe File System Access

Use `os.Root` (Go 1.24+) for traversal-resistant file access within a directory.

**Bad**:
```go
// Vulnerable to "../" traversal
f, err := os.Open(filepath.Join(dir, filename))
```

**Good**:
```go
root, err := os.OpenRoot(dir)
if err != nil {
  return err
}
defer root.Close()

// Safe: errors if path escapes root
f, err := root.Open(filename)
```

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

### Generic Slice and Map Functions

Use the `slices` and `maps` packages (Go 1.21+) for common operations instead of manual implementations.

**Slices**:
```go
import "slices"

// Clone - replaces manual copy
original := []int{1, 2, 3}
copy := slices.Clone(original)

// Sort - generic sorting
items := []string{"c", "a", "b"}
slices.Sort(items)

// Compact - remove consecutive duplicates
data := []int{1, 1, 2, 2, 3}
unique := slices.Compact(data)
```

**Maps**:
```go
import "maps"

// Clone
m := map[string]int{"a": 1}
copy := maps.Clone(m)

// Equal
m1 := map[string]int{"a": 1}
m2 := map[string]int{"a": 1}
if maps.Equal(m1, m2) {
  // ...
}

// DeleteFunc (Go 1.21+)
maps.DeleteFunc(m, func(k string, v int) bool {
  return v%2 == 0
})
```

**Replacing manual slice and map copying**:

**Bad**:
```go
// Slice
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}

// Map
func (d *Driver) SetCache(cache map[string]int) {
  d.cache = make(map[string]int, len(cache))
  for k, v := range cache {
    d.cache[k] = v
  }
}
```

**Good**:
```go
import (
  "maps"
  "slices"
)

func (d *Driver) SetTrips(trips []Trip) {
  d.trips = slices.Clone(trips)
}

func (d *Driver) SetCache(cache map[string]int) {
  d.cache = maps.Clone(cache)
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

#### Error Chain Structure

Place `%w` at the end of error strings to mirror the error chain structure (newest to oldest):

```go
// Good - %w at end mirrors chain structure
return fmt.Errorf("read config: %w", err)
// Error chain: "read config: open file: permission denied"
//              [newest]    [middle]   [oldest/root cause]
```

Error chains form newest-to-oldest hierarchies. Placing `%w` at the end makes the chain structure clear when reading error messages.

#### Error Translation at Boundaries

At system boundaries (RPC, IPC, storage), use `%v` instead of `%w` to translate errors into your canonical error space:

```go
// At RPC boundary - translate to gRPC status
func (s *Server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
  user, err := s.db.FindUser(req.Id)
  if err != nil {
    // Use %v to prevent exposing internal error types across RPC
    return nil, status.Errorf(codes.NotFound, "user %s: %v", req.Id, err)
  }
  return user, nil
}

// Within service - preserve error chain with %w
func (db *DB) FindUser(id string) (*User, error) {
  user, err := db.query(id)
  if err != nil {
    // Use %w to maintain error chain for internal inspection
    return nil, fmt.Errorf("query user %s: %w", id, err)
  }
  return user, nil
}
```

**Why**: System boundaries need canonical error representations. Internal code preserves error chains for debugging.

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

### Error String Format

Error strings should not be capitalized (unless beginning with proper nouns or acronyms) and should not end with punctuation. Errors typically appear within larger context where they're interpolated into other messages.

**Bad**:
```go
return errors.New("Something bad happened.")
return errors.New("Configuration failed")
```

**Good**:
```go
return errors.New("something bad happened")
return errors.New("configuration failed")
```

**Why**: Error messages appear in larger context:
```go
fmt.Printf("operation failed: %v", err)
// Produces: "operation failed: something bad happened"
// Not: "operation failed: Something bad happened."
```

**Exception**: Proper nouns and acronyms maintain their casing:
```go
return errors.New("GitHub API unavailable")
return fmt.Errorf("failed to connect to PostgreSQL: %w", err)
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

### Must Functions

Reserve the `MustXYZ` naming pattern for setup helpers that terminate the program on failure. These functions should only be called early in program startup, never in library code or at runtime.

**Acceptable - program initialization**:
```go
var defaultConfig = MustLoadConfig("config.yaml")

func MustLoadConfig(path string) *Config {
  cfg, err := LoadConfig(path)
  if err != nil {
    log.Fatalf("failed to load config: %v", err)
  }
  return cfg
}

func main() {
  // defaultConfig available here
}
```

**Bad - library function**:
```go
package parser

// Wrong - library functions shouldn't panic
func MustParseJSON(data []byte) *Object {
  obj, err := ParseJSON(data)
  if err != nil {
    panic(err)  // Forces panic on caller
  }
  return obj
}
```

**Good - library function**:
```go
package parser

// Return error - let caller decide how to handle
func ParseJSON(data []byte) (*Object, error) {
  // ...
}
```

**Why**: `MustXYZ` functions are appropriate only for initialization code where failure prevents meaningful execution. Library code should always return errors.

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

### Specify Channel Direction

Always specify channel direction (`<-chan`, `chan<-`) in function signatures to prevent accidental misuse and document intent.

**Bad** (bidirectional allows misuse):
```go
func process(ch chan int) {
  // Could accidentally send when should only receive
  val := <-ch
}
```

**Good** (direction constraints):
```go
// Send-only parameter
func produce(ch chan<- int) {
  ch <- 42
}

// Receive-only parameter
func consume(ch <-chan int) {
  val := <-ch
}

// Bidirectional only when truly needed
func bridge(in <-chan int, out chan<- int) {
  for v := range in {
    out <- v
  }
}
```

**Why**: Channel direction constraints:
- Prevent accidental misuse (sending on receive-only channel)
- Document function intent clearly
- Enable compile-time safety

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

### Don't Copy Types with Sync Primitives

Don't copy types containing synchronization primitives (`sync.Mutex`, `sync.Cond`, etc.) or types with pointer-only methods.

**Bad**:
```go
type Counter struct {
  mu    sync.Mutex
  count int
}

func (c Counter) Inc() {  // Value receiver copies mutex!
  c.mu.Lock()
  defer c.mu.Unlock()
  c.count++
}

// Copying the struct copies the mutex
c1 := Counter{}
c2 := c1  // Bug - copies mutex in locked/unlocked state
```

**Good**:
```go
type Counter struct {
  mu    sync.Mutex
  count int
}

func (c *Counter) Inc() {  // Pointer receiver - no copy
  c.mu.Lock()
  defer c.mu.Unlock()
  c.count++
}
```

**Why**: Copying a `sync.Mutex` or similar types breaks synchronization guarantees and causes undefined behavior.

---

### Struct Literal Field Names

Use field names in struct literals for types from other packages. Omitting names is fragile.

**Bad**:
```go
// Fragile - breaks if fields reordered
user := User{"alice", 30, "alice@example.com"}
```

**Good**:
```go
user := User{
  Name:  "alice",
  Age:   30,
  Email: "alice@example.com",
}
```

**Exception**: Field names optional for same-package types when field order is stable (e.g., test tables).

---

### Type Alias vs Type Definition

Use type definitions (`type T1 T2`) for creating new types. Reserve type aliases (`type T1 = T2`) only for migration scenarios.

**Type definition** (creates new type):
```go
type UserID int  // New type - not assignable to int

var id UserID = 42
var n int = id  // Compile error - different types
```

**Type alias** (same type, different name):
```go
type StringAlias = string  // Alias - same type as string

var s StringAlias = "hello"
var str string = s  // OK - same type
```

**When to use aliases**:
```go
// During API migration only
package oldpkg

import "newpkg"

// Temporary alias during migration period
type OldUserID = newpkg.UserID

// Deprecated: Use newpkg.UserID instead
```

**Why**: Type definitions provide type safety. Aliases are rarely needed and create confusion.

---

### Avoid init()

Make code deterministic and testable. Only use `init()` for specific scenarios. Most initialization should happen explicitly.

**Avoid** in init():
- I/O operations
- Environment variable access
- Global state manipulation
- Anything that can fail

**Bad**:
```go
var config Config

func init() {
  config = loadConfig()  // I/O in init - can fail, hard to test
}
```

**Good**:
```go
var defaultConfig = Config{
  Timeout: 10 * time.Second,
}

func NewConfig() (*Config, error) {
  return loadConfig()  // Explicit, testable, can handle errors
}
```

---

#### Acceptable init() Uses

**1. Database driver registration** (pluggable hooks):
```go
package postgres

import (
  "database/sql"
  _ "github.com/lib/pq"  // Registers postgres driver in init()
)

// The imported package's init() registers the driver:
// func init() {
//   sql.Register("postgres", &Driver{})
// }
```

**2. Deterministic precomputation** (no I/O, no failures):
```go
package math

var powersOfTwo [64]int

func init() {
  // Pure computation, deterministic, cannot fail
  for i := range powersOfTwo {
    powersOfTwo[i] = 1 << i
  }
}
```

**3. Complex expressions requiring loops**:
```go
package constants

var httpStatusText = map[int]string{}

func init() {
  // Can't use map literal for computed values
  for code := 200; code < 600; code++ {
    httpStatusText[code] = computeStatusText(code)
  }
}
```

**Why these are acceptable**: Deterministic, cannot fail, no external dependencies, improve performance by computing once at startup.

**Reference**: [Google Go Style Guide - init](https://google.github.io/styleguide/go/best-practices#init)

---

## Documentation Standards

### Document Non-Obvious Behavior

Document error-prone or non-obvious fields and behaviors. Don't restate what's already clear from the code.

**Bad** (restates obvious):
```go
// Name is the user's name
Name string
```

**Good** (documents non-obvious behavior):
```go
// Name is the user's display name. May be empty if user hasn't set one.
// In that case, use Email as fallback for display purposes.
Name string
```

---

### Document Concurrent Safety

Explicitly document whether types or functions are safe for concurrent use.

**Good**:
```go
// Cache is safe for concurrent use by multiple goroutines.
type Cache struct {
  mu sync.RWMutex
  data map[string]interface{}
}

// Get retrieves a value. Safe for concurrent use.
func (c *Cache) Get(key string) interface{} {
  c.mu.RLock()
  defer c.mu.RUnlock()
  return c.data[key]
}
```

**Also good** (documenting NOT safe):
```go
// Buffer is NOT safe for concurrent use. Callers must synchronize access.
type Buffer struct {
  data []byte
}
```

---

### Document Resource Cleanup

Explicitly document cleanup requirements for resources.

**Good**:
```go
// Open returns a connection to the database.
// Callers must call Close() when done to release resources.
func Open(dsn string) (*DB, error) {
  // ...
}

// Close releases database resources.
// It's safe to call Close multiple times.
func (db *DB) Close() error {
  // ...
}
```

---

### Document Error Conditions

Specify what error types are returned and under what conditions.

**Bad**:
```go
// Parse parses the input.
func Parse(input string) (*Result, error)
```

**Good**:
```go
// Parse parses the input string.
// Returns ErrInvalidSyntax if input has syntax errors.
// Returns ErrTooLarge if input exceeds maximum size.
func Parse(input string) (*Result, error)
```

**When using errors.Is**:
```go
// FetchUser retrieves a user by ID.
// Returns ErrNotFound if user doesn't exist (use errors.Is to check).
// Returns ErrPermission if caller lacks access (use errors.Is to check).
func FetchUser(ctx context.Context, id string) (*User, error)
```

---

### Context Cancellation Semantics

Context cancellation semantics are usually implied. Only document non-standard behavior.

**Don't document** (standard behavior):
```go
// Fetch retrieves data. Respects ctx cancellation.
func Fetch(ctx context.Context) (*Data, error)
```

**Do document** (non-standard behavior):
```go
// Fetch retrieves data. Even if ctx is canceled, the fetch completes
// and resources are cleaned up before returning ctx.Err().
func Fetch(ctx context.Context) (*Data, error)
```

---

### Comments Should Explain WHY

Comments should explain why code does something, not what it does. The code itself shows what.

**Bad** (explains what):
```go
// Loop through users
for _, user := range users {
  // Check if user is active
  if user.Active {
    // Process the user
    process(user)
  }
}
```

**Good** (explains why):
```go
// Only process active users to avoid sending notifications
// to users who have disabled their accounts
for _, user := range users {
  if user.Active {
    process(user)
  }
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

## Logging and Configuration

### Logging Best Practices

Use `log.Info(v)` over formatting functions when no string manipulation is needed.

**Good**:
```go
log.Info("processing started")  // No formatting needed
log.Infof("processing %d items", count)  // Formatting needed
```

Use `log.V()` levels for development tracing that should be disabled in production.

**Example**:
```go
if log.V(2) {
  log.Info("detailed debug information")
}
```

Avoid calling expensive functions when verbose logging is disabled:

**Bad**:
```go
log.V(2).Infof("state: %s", expensiveDebugString())  // Always calls function
```

**Good**:
```go
if log.V(2) {
  log.Infof("state: %s", expensiveDebugString())  // Only calls when enabled
}
```

---

### Configuration Flags

Define flags only in `package main`. Don't export flags as package side effects.

**Bad**:
```go
package config

import "flag"

// Bad - package exports flags as side effect
var Port = flag.Int("port", 8080, "server port")
```

**Good**:
```go
package main

import "flag"

func main() {
  port := flag.Int("port", 8080, "server port")
  flag.Parse()
  // use *port
}
```

**Flag naming**: Use `snake_case` for flag names, `camelCase` for variable names.

```go
var (
  maxConnections = flag.Int("max_connections", 100, "maximum connections")
  readTimeout    = flag.Duration("read_timeout", 30*time.Second, "read timeout")
}
```

---

## Performance Guidelines

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

No fixed maximum line length exists. If a line feels too long, prefer refactoring the code instead of mechanically splitting it.

Long lines often indicate that code is doing too much:
- Extract complex expressions into well-named variables
- Break large functions into smaller, focused ones
- Simplify nested logic

**When line breaks are necessary**, indent continuation lines clearly to distinguish them from subsequent lines of code.

---

###Switch and Break

Don't use `break` at the end of switch clauses - Go automatically breaks. Use comments for empty clauses.

**Good**:
```go
switch x {
case 1:
  doSomething()
  // No break needed - automatic
case 2:
  doOtherThing()
case 3:
  // Intentionally empty
default:
  doDefault()
}
```

---

### Variable Shadowing

Distinguish between "stomping" (reassigning) and "shadowing" (creating new variable in inner scope). Prefer clear names over implicit shadowing.

**Shadowing** (new variable in inner scope):
```go
func process() error {
  err := firstOperation()

  if err != nil {
    // This 'err' shadows outer 'err'
    err := wrapError(err)
    log.Print(err)
  }

  return err  // Returns outer err, not wrapped one!
}
```

**Better** (clear names):
```go
func process() error {
  err := firstOperation()

  if err != nil {
    wrappedErr := wrapError(err)
    log.Print(wrappedErr)
  }

  return err
}
```

---

### Consistency

Maintain uniform style within packages. Apply conventions at package level or larger.

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
- Don't use `Get` prefix for getters unless the concept inherently uses "get"

**Good**:
```go
func Count() int { }       // Not GetCount()
func User(id string) *User { }  // Not GetUser()
```

**Acceptable** (concept inherently uses "get"):
```go
func GetPage(url string) (*Page, error) { }  // HTTP GET
```

---

### Receiver Names

Receiver names should be short (1-2 letters), abbreviate the type, and be consistent across all methods.

**Good**:
```go
type Client struct{}

func (c *Client) Connect() { }
func (c *Client) Disconnect() { }
```

**Bad**:
```go
type Client struct{}

func (client *Client) Connect() { }  // Too long
func (cl *Client) Disconnect() { }   // Inconsistent
```

**Convention**: Use first letter(s) of type name, always the same across all methods.

---

### Variable Names

Variable name length should scale with scope size and inverse to usage frequency:
- **Short names** for small scopes and frequently used variables: `i`, `c`, `buf`
- **Longer names** for large scopes and infrequently used variables: `requestTimeout`, `maxRetryAttempts`

**Good**:
```go
// Short scope, frequent use
for i, v := range items {
  process(v)
}

// Large scope, infrequent use
var requestTimeout = 30 * time.Second
```

---

### Initialism Casing

Initialisms should maintain consistent casing - all uppercase or all lowercase, never mixed.

**Good**:
```go
var url string              // All lowercase
var userID int             // ID all uppercase
type URLParser struct { }  // URL all uppercase
type HTTPClient struct { } // HTTP all uppercase
```

**Bad**:
```go
var Url string             // Never Url
var userId int             // Never Id
type UrlParser struct { }  // Never Url
```

**Special cases** - preserve standard prose formatting:
- iOS not IOS or Ios
- gRPC not GRPC or Grpc

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

Choose declaration form based on clarity and intent.

**Prefer `:=`** with non-zero values:
```go
name := "Alice"
count := 42
result := process()
```

**Use `var`** for zero-value initialization when values are "ready for later use":
```go
var filtered []int  // Will be populated later
var buf bytes.Buffer  // Zero value is ready to use
var mu sync.Mutex  // Zero value is ready to use
```

**Prefer `new()`** over empty composite literals for pointer-to-zero-value:
```go
// When you need *T with zero value
p := new(Person)  // Clearer than &Person{}
```

**Size hints**: Preallocate capacity only when final size is known through empirical analysis (profiling):
```go
// Don't guess
items := make([]Item, 0)  // Let it grow

// Only if profiling shows benefit AND size is known
items := make([]Item, 0, expectedSize)
```

**Reference**: [Google Go Style Guide - Variable Declarations](https://google.github.io/styleguide/go/best-practices#variable-declarations)

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

### CRITICAL: Don't Call t.Fatal from Goroutines

Calling `t.Fatal()`, `t.FailNow()`, or `t.Skip()` from goroutines causes immediate panic and corrupted test state. These functions must only be called from the goroutine running the test function.

**CRITICAL BUG - causes panic**:
```go
func TestConcurrent(t *testing.T) {
  go func() {
    result, err := fetchData()
    if err != nil {
      t.Fatal(err)  // PANIC! Called from wrong goroutine
    }
  }()
}
```

**Correct - use t.Error and coordinate with main goroutine**:
```go
func TestConcurrent(t *testing.T) {
  errCh := make(chan error, 1)

  go func() {
    result, err := fetchData()
    if err != nil {
      errCh <- err  // Send error to main goroutine
      return
    }
    errCh <- nil
  }()

  if err := <-errCh; err != nil {
    t.Fatalf("fetchData failed: %v", err)  // Called from test goroutine
  }
}
```

**Alternative - use t.Error from goroutine**:
```go
func TestConcurrent(t *testing.T) {
  var wg sync.WaitGroup
  wg.Add(1)

  go func() {
    defer wg.Done()
    result, err := fetchData()
    if err != nil {
      t.Error(err)  // Safe - doesn't terminate immediately
      return
    }
  }()

  wg.Wait()
}
```

**Why**: `t.Fatal()` calls `runtime.Goexit()`, which is only safe from the test's main goroutine. From other goroutines, it causes panics and prevents proper test cleanup.

---

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

---

### Context in Tests

Use `t.Context()` (Go 1.24+) to obtain a context that is automatically canceled when the test completes.

**Bad**:
```go
func TestService(t *testing.T) {
  ctx, cancel := context.WithCancel(context.Background())
  defer cancel()  // Manual cleanup

  result, err := service.Run(ctx)
  // ...
}
```

**Good**:
```go
func TestService(t *testing.T) {
  ctx := t.Context()  // Auto-canceled on cleanup

  result, err := service.Run(ctx)
  // ...
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

### Test Helper Patterns

Test helpers should call `t.Helper()` to improve failure line reporting. Helpers take `testing.T` as a parameter, allowing them to report failures directly.

**Pattern**:
```go
func setupUser(t *testing.T, name string) *User {
  t.Helper()  // Failure reports point to caller, not this line

  user, err := createUser(name)
  if err != nil {
    t.Fatalf("failed to setup user: %v", err)
  }
  return user
}

func TestUserWorkflow(t *testing.T) {
  user := setupUser(t, "alice")  // Failure points here, not inside helper
  // ... test logic
}
```

**Why**: `t.Helper()` marks the function as a test helper, causing failure messages to report the caller's location instead of the line inside the helper.

**Benefits**:
- Clear failure locations in test output
- Helpers can fail tests directly
- Simplified test code

---

### Test Failure Messages

Format test failure messages to include function name, inputs, actual value, and expected value.

**Pattern**: `FunctionName(inputs) = actual, want expected`

**Good**:
```go
func TestParseInt(t *testing.T) {
  got, err := ParseInt("invalid")
  if err == nil {
    t.Errorf("ParseInt(%q) succeeded, want error", "invalid")
  }

  got, err = ParseInt("42")
  want := 42
  if got != want {
    t.Errorf("ParseInt(%q) = %d, want %d", "42", got, want)
  }
}
```

**Conventions**:
- Include function name
- Include inputs if short
- Show actual value BEFORE expected value
- Use "got" for actual, "want" for expected
- Be specific about what failed

**Bad**:
```go
t.Errorf("wrong value")  // What value? What was it? What was expected?
t.Errorf("expected %d but got %d", want, got)  // Backwards (expected first)
```

**Why**: Consistent, informative failure messages make test output easier to parse and debug.

---

### t.Error vs t.Fatal Choice

Choose between `t.Error` and `t.Fatal` based on whether subsequent checks are meaningful.

**Prefer t.Error** to reveal all failures in one run:
```go
func TestValidation(t *testing.T) {
  result := Validate(input)

  if result.Name == "" {
    t.Error("Name should not be empty")  // Continue checking
  }

  if result.Email == "" {
    t.Error("Email should not be empty")  // Shows both failures
  }
}
```

**Use t.Fatal** when subsequent checks would panic or be meaningless:
```go
func TestDatabase(t *testing.T) {
  db, err := OpenDB()
  if err != nil {
    t.Fatalf("OpenDB failed: %v", err)  // Can't continue without DB
  }
  defer db.Close()

  // These would panic if db is nil
  result := db.Query("SELECT * FROM users")
}
```

**In table-driven tests**:
- Use `t.Fatal()` in subtests (per-entry failures)
- Use `t.Error()` + `continue` in non-subtest loops

**Why**: `t.Error` reveals multiple issues; `t.Fatal` prevents cascading failures.

---

### Test Assertions

**Simple rule**: If the codebase already uses an assertion library (testify, etc.), continue using it for consistency. For new projects, use standard library testing patterns unless an assertion library is explicitly requested.

**Standard library pattern**:
```go
func TestAdd(t *testing.T) {
  got := Add(2, 3)
  want := 5
  if got != want {
    t.Errorf("Add(2, 3) = %d, want %d", got, want)
  }
}
```

**With assertion library** (if already in codebase):
```go
func TestAdd(t *testing.T) {
  got := Add(2, 3)
  assert.Equal(t, 5, got)
}
```

**Why**: Consistency within a project matters more than the specific assertion style. Avoid adding dependencies to new projects without explicit need.

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

### Option Struct Pattern

For functions with many optional parameters where most have sensible defaults, consider option structs as a simpler alternative to functional options.

**When to use**:
- Many optional parameters (3+)
- Most fields have sensible defaults
- Callers typically specify only 1-2 options
- Simpler than functional options for straightforward cases

**Pattern**:
```go
type ClientOptions struct {
  Timeout     time.Duration
  Retries     int
  Logger      *log.Logger
  EnableCache bool
}

func NewClient(addr string, opts *ClientOptions) (*Client, error) {
  // Apply defaults for nil options
  if opts == nil {
    opts = &ClientOptions{
      Timeout:     30 * time.Second,
      Retries:     3,
      Logger:      log.Default(),
      EnableCache: true,
    }
  }

  // Use opts fields
  return &Client{
    addr:    addr,
    timeout: opts.Timeout,
    retries: opts.Retries,
    logger:  opts.Logger,
    cache:   opts.EnableCache,
  }, nil
}
```

**Usage**:
```go
// Use defaults
client, _ := NewClient("localhost:8080", nil)

// Override specific options
client, _ := NewClient("localhost:8080", &ClientOptions{
  Retries: 5,  // Other fields use defaults
})
```

**Comparison with Functional Options**:

| Aspect | Option Struct | Functional Options |
|--------|--------------|-------------------|
| Simplicity | Simpler, less code | More complex |
| Extensibility | Requires version management | Seamlessly extensible |
| Discovery | IDE autocomplete shows all options | Must know function names |
| Best for | Stable APIs, many defaults | Evolving APIs, few overrides |

**Reference**: [Google Go Style Guide - Option Structs](https://google.github.io/styleguide/go/best-practices#option-structure)

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

## Package Organization

### Group Related Types

Group related types in the same package when client code typically needs both. Use godoc grouping as a guide for package boundaries.

**Good**:
```go
package user

// Related types together
type User struct { }
type UserRepository interface { }
type UserService struct { }
```

**Consider splitting when**:
- Package has thousands of lines in a single file
- Types have distinct responsibilities with separate clients
- Clear separation improves testability

---

### Package Size

Avoid single-file packages with thousands of lines. Split into multiple files by:
- Responsibility (handlers.go, models.go, repository.go)
- Type groupings (user.go, account.go, payment.go)

No strict line limits, but consider splitting when navigation becomes difficult.

---

### Package Names as Context

Package names provide context. Don't repeat package name in type names.

**Bad**:
```go
package user

type UserService struct { }  // Redundant
```

**Good**:
```go
package user

type Service struct { }  // Used as user.Service
```

**Reference**: [Google Go Style Guide - Package Names](https://google.github.io/styleguide/go/decisions#package-names)

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
