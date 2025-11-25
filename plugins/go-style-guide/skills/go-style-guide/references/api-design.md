# API Design

Patterns for interfaces, function design, data management, and struct organization.

---

## Interfaces Belong in Consumer Packages

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

## Return Concrete Types

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

## Avoid Premature Interface Definitions

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

## Verify Interface Compliance

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

## Receivers and Interfaces

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

## Receiver Type Choice

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

## Don't Create Custom Context Types

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

## Prefer Synchronous Functions

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

## Make Goroutine Lifetimes Clear

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

## Context Should Be First Parameter

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

## Pass Values, Not Pointers (Usually)

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

## Copy Slices and Maps at Boundaries

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
  d.trips = slices.Clone(trips)  // Defensive copy
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
  return slices.Clone(s.counters)
}
```

---

## Generic Slice and Map Functions

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

**Important**: Modification functions in `slices` (Go 1.22+) "clear the tail" - zeroing obsolete elements. Always use the returned slice value:

```go
// Correct - use returned value
items = slices.Delete(items, 0, 1)

// Bug - original slice may have stale tail elements
slices.Delete(items, 0, 1)  // Don't ignore return value
```

---

## JSON omitzero

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

## Safe File System Access

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

## Range Functions & Iterators

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

## Avoid Embedding in Public Structs

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

## Struct Literal Field Names

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

## Type Alias vs Type Definition

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

## Avoid init()

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

### Acceptable init() Uses

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

---

## Functional Options

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

## Option Struct Pattern

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

---

## Generic Interface Patterns

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

### Package Size

Avoid single-file packages with thousands of lines. Split into multiple files by:
- Responsibility (handlers.go, models.go, repository.go)
- Type groupings (user.go, account.go, payment.go)

No strict line limits, but consider splitting when navigation becomes difficult.

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
