# Review Checklist - Architectural & Semantic Patterns

Quick reference for patterns requiring human judgment. Linter-caught issues (unhandled errors, type assertions, formatting, etc.) are handled by `golangci-lint`.

**Focus**: Architecture, ownership, lifecycle, strategy - not syntax or common bugs.

---

## Critical Issues (Architecture & Safety)

### Fire-and-Forget Goroutines
```go
// BAD - No lifecycle management
go func() {
  for {
    doWork()
    time.Sleep(interval)
  }
}()

// GOOD - Managed lifecycle with stop channel
type Worker struct {
  stop chan struct{}
  done chan struct{}
}

func (w *Worker) Start() {
  go func() {
    defer close(w.done)
    ticker := time.NewTicker(interval)
    defer ticker.Stop()

    for {
      select {
      case <-ticker.C:
        doWork()
      case <-w.stop:
        return
      }
    }
  }()
}

func (w *Worker) Stop() {
  close(w.stop)
  <-w.done  // Wait for completion
}
```

**Why critical**: Goroutines without lifecycle control leak resources and prevent graceful shutdown.

---

### Mutex Races
```go
// BAD - Not holding lock during access
s.mu.Lock()
s.mu.Unlock()
return s.data  // Race!

// GOOD
s.mu.Lock()
defer s.mu.Unlock()
return s.data
```

**Why critical**: Race conditions cause non-deterministic bugs. Run with `go test -race` to detect.

**Note**: This requires runtime race detector, not caught by static linters.

---

### Panics in Production Code
```go
// BAD - Library code
func ParseConfig(data []byte) *Config {
  if len(data) == 0 {
    panic("empty config")  // Never panic in libraries!
  }
  ...
}

// GOOD - Return error
func ParseConfig(data []byte) (*Config, error) {
  if len(data) == 0 {
    return nil, errors.New("empty config")
  }
  ...
}

// ACCEPTABLE - main() or init() only
func main() {
  if len(os.Args) < 2 {
    log.Fatal("missing argument")  // OK in main
  }
}
```

**Why critical**: Panics in library code prevent callers from recovering. Only acceptable in `main()` and `init()`.

---

## Important Issues (Design & Patterns)

### Concurrency

#### Goroutines in init()
```go
// BAD
func init() {
  go monitor()  // Can't control lifecycle
}

// GOOD - Explicit lifecycle
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

**Why**: `init()` goroutines have no shutdown mechanism, affecting testability and predictability.

---

#### Channel Buffer Size > 1
```go
// BAD - Unjustified magic number
c := make(chan int, 64)  // Why 64? What happens at 65?

// GOOD
c := make(chan int)      // Unbuffered - explicit synchronization
c := make(chan int, 1)   // Buffered by 1 - specific use case
```

**Why**: Buffer sizes >1 require justification. How is overflow prevented? What are blocking semantics?

---

#### Manual Context Cancellation in Tests
```go
// BAD - Manual lifecycle
func TestOperation(t *testing.T) {
  ctx, cancel := context.WithCancel(context.Background())
  defer cancel()

  // test code
}

// GOOD (Go 1.24+) - Automatic cleanup
func TestOperation(t *testing.T) {
  ctx := t.Context()  // Auto-canceled when test ends

  // test code
}
```

**Why**: `t.Context()` ensures proper cleanup ordering and integrates with test lifecycle.

---

### Data Ownership

#### Not Copying Slices/Maps at Boundaries
```go
// BAD
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = trips  // Caller can mutate!
}

func (d *Driver) GetTrips() []Trip {
  return d.trips  // Caller can mutate!
}

// GOOD (Go 1.21+)
import "slices"

func (d *Driver) SetTrips(trips []Trip) {
  d.trips = slices.Clone(trips)  // Defensive copy
}

func (d *Driver) GetTrips() []Trip {
  return slices.Clone(d.trips)  // Defensive copy
}
```

**Why**: Shared slice/map references violate encapsulation. Copy at API boundaries to maintain ownership.

**Judgment required**: When performance matters, document shared ownership explicitly.

---

#### Global Mutable State
```go
// BAD
var cache = make(map[string]string)

func Get(key string) string {
  return cache[key]  // Hard to test, race-prone
}

// GOOD - Dependency injection
type Cache struct {
  mu   sync.RWMutex
  data map[string]string
}

func NewCache() *Cache {
  return &Cache{data: make(map[string]string)}
}

func (c *Cache) Get(key string) string {
  c.mu.RLock()
  defer c.mu.RUnlock()
  return c.data[key]
}
```

**Why**: Global mutable state prevents testability and causes race conditions. Use dependency injection.

---

### API Design

#### Embedded Types in Public Structs
```go
// BAD - Leaks implementation, prevents evolution
type ConcreteList struct {
  AbstractList  // Exposes all AbstractList methods publicly!
}

// GOOD - Explicit delegation
type ConcreteList struct {
  list *AbstractList  // Private field
}

func (c *ConcreteList) Add(e Entity) {
  c.list.Add(e)  // Explicit method
}
```

**Why**: Embedding in public structs couples API to implementation, preventing evolution. Use composition with explicit methods.

---

#### os.Exit or log.Fatal Outside main()
```go
// BAD - Library function
func SaveConfig(cfg Config) {
  if err := write(cfg); err != nil {
    log.Fatal(err)  // Bypasses caller's defers!
  }
}

// GOOD - Return error
func SaveConfig(cfg Config) error {
  if err := write(cfg); err != nil {
    return fmt.Errorf("save config: %w", err)
  }
  return nil
}

func main() {
  if err := SaveConfig(cfg); err != nil {
    log.Fatal(err)  // Only in main()
  }
}
```

**Why**: `log.Fatal()` and `os.Exit()` bypass `defer` statements and prevent callers from cleanup. Only use in `main()`.

---

### Error Handling

#### Handling Errors Multiple Times
```go
// BAD - Logs AND returns (doubles observability)
func processFile(path string) error {
  data, err := os.ReadFile(path)
  if err != nil {
    log.Printf("read failed: %v", err)  // Logged here
    return fmt.Errorf("read %s: %w", path, err)  // AND returned
  }
  return process(data)
}

// GOOD - Return with context, let caller decide
func processFile(path string) error {
  data, err := os.ReadFile(path)
  if err != nil {
    return fmt.Errorf("read %s: %w", path, err)  // Caller logs if needed
  }
  return process(data)
}

// Caller handles observability
if err := processFile(path); err != nil {
  log.Printf("process failed: %v", err)  // Logged once, at boundary
}
```

**Why**: Handling errors at multiple levels creates redundant logging and makes observability boundaries unclear.

**Judgment required**: Decide observability boundaries - where to log vs where to wrap and return.

---

#### Manual Error Aggregation
```go
// BAD - Manual collection
var errs []error
for _, item := range items {
  if err := process(item); err != nil {
    errs = append(errs, err)
  }
}
if len(errs) > 0 {
  return fmt.Errorf("errors: %v", errs)
}

// GOOD - Use errors.Join (Go 1.20+)
var errs []error
for _, item := range items {
  if err := process(item); err != nil {
    errs = append(errs, fmt.Errorf("process %s: %w", item.ID, err))
  }
}
return errors.Join(errs...)  // Returns nil if empty
```

**Why**: `errors.Join()` handles nil slices correctly and enables `errors.Is`/`errors.As` on joined errors.

**Judgment required**: Decide when to aggregate (batch processing) vs fail-fast (validation).

---

### Testing

#### Complex Table Tests
```go
// BAD - Too many conditionals
tests := []struct{
  name        string
  input       string
  shouldErr   bool
  shouldCall1 bool
  shouldCall2 bool
  check1      func()
  check2      func()
}{
  // Complex branching logic in test table
}

// GOOD - Split into focused tests
func TestSuccess(t *testing.T) {
  // Simple, clear success case
}

func TestError(t *testing.T) {
  // Simple, clear error case
}

func TestEdgeCase(t *testing.T) {
  // Specific edge case
}
```

**Why**: Table tests with excessive conditionals are hard to understand and maintain.

**Judgment required**: When to use table-driven vs separate tests depends on test similarity and complexity.

---

#### time.Sleep in Tests
```go
// BAD - Slow, flaky test
func TestTimeout(t *testing.T) {
  done := make(chan bool)
  go func() {
    time.Sleep(5 * time.Second)  // Slow! Flaky!
    done <- true
  }()

  select {
  case <-done:
    // success
  case <-time.After(6 * time.Second):
    t.Fatal("timeout")
  }
}

// GOOD - Deterministic with synctest (Go 1.25+)
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

**Why**: `time.Sleep()` in tests makes them slow and timing-dependent (flaky).

**Judgment required**: When to use `synctest` vs real time depends on whether you're testing timing behavior or business logic.

---

#### Manual b.N Loop
```go
// BAD - Easy to forget timer management
func BenchmarkOperation(b *testing.B) {
  data := setupExpensive()

  b.ResetTimer()  // Easy to forget!

  for i := 0; i < b.N; i++ {
    operation(data)
  }

  b.StopTimer()  // Also easy to forget
  cleanup()
}

// GOOD - Automatic timer management (Go 1.24+)
func BenchmarkOperation(b *testing.B) {
  data := setupExpensive()  // Not timed

  for b.Loop() {
    operation(data)  // Automatically timed
  }

  cleanup()  // Not timed
}
```

**Why**: `b.Loop()` handles timer management automatically and prevents measurement errors.

---

### Modernization (High-Value)

#### Unsafe Path Joining
```go
// BAD - Path traversal vulnerability
func serveFile(dir, name string) (*os.File, error) {
  path := filepath.Join(dir, name)  // User can pass "../../../etc/passwd"
  return os.Open(path)
}

// GOOD - Safe filesystem root (Go 1.24+)
func serveFile(dir, name string) (*os.File, error) {
  root, err := os.OpenRoot(dir)
  if err != nil {
    return nil, err
  }
  return root.Open(name)  // Enforces dir boundary
}
```

**Why**: `filepath.Join()` doesn't prevent path traversal. `os.Root` provides filesystem-level safety.

**Judgment required**: Use `os.Root` for security-critical file serving, not general path manipulation.

---

#### Manual Slice and Map Operations
```go
// BAD - Manual operations when stdlib provides
// Slice copy
copied := make([]int, len(original))
copy(copied, original)

// Map copy
m2 := make(map[string]int, len(m))
for k, v := range m {
  m2[k] = v
}

// GOOD - Use slices/maps package (Go 1.21+)
import (
  "maps"
  "slices"
)

copied := slices.Clone(original)
slices.Sort(items)
m2 := maps.Clone(m)
```

**Why**: `slices`/`maps` packages provide tested, optimized operations.

**Judgment required**: Use when it improves clarity. Manual operations are fine for performance-critical code with profiling justification.

---

#### Map/Slice Reallocation
```go
// BAD - Reallocates, loses capacity
for i := 0; i < iterations; i++ {
  m = make(map[string]int)  // Allocates every iteration
  // use m
}

// GOOD - Clear in place, retains capacity (Go 1.21+)
m := make(map[string]int)
for i := 0; i < iterations; i++ {
  clear(m)  // Clears but keeps allocated capacity
  // use m
}
```

**Why**: `clear()` avoids allocation overhead when reusing containers.

**Judgment required**: Only optimize when profiling shows allocation pressure.

---

## Review Workflow

1. **Critical Issues First**: Goroutine lifecycle, race conditions, panics in libraries
2. **Important Issues**: Error handling strategy, data ownership, API design
3. **Context Matters**: Some patterns are acceptable in specific contexts (panic in `main()`, global constants)
4. **Defer to Linters**: Don't report issues that `golangci-lint` catches (unhandled errors, type assertions, formatting)

## Common False Positives

- `init()` for database driver registration (acceptable)
- Panic in test code using `t.Fatal()` (acceptable)
- Global constants (acceptable - only mutable globals are problematic)
- Embedding in private structs for composition (sometimes acceptable)
- Shared slices when explicitly documented (acceptable with justification)

## Google vs Uber Style Differences

This guide synthesizes both Google and Uber Go style guides. Note these differences:

### Assertion Libraries
- **Our approach**: Use what codebase uses; don't add to new projects unless requested
- **Google**: Recommends against assertion libraries (prefer manual checks)
- **Uber**: Examples use assertion libraries (testify)
- **Review guidance**: Don't flag either approach; focus on test logic, not assertion style

### Line Length
- **Our approach**: No fixed maximum; prefer refactoring over mechanical breaking
- **Google**: No fixed maximum; prefer refactoring
- **Uber (historically)**: 99 character soft limit
- **Review guidance**: Focus on whether code could be refactored, not line counts

### Test Helpers
- **Our approach**: Helpers take `testing.T` and call `t.Helper()`
- **Google**: Recommends helpers return errors instead of taking `testing.T`
- **Uber**: Helpers take `testing.T`
- **Review guidance**: Either pattern acceptable; ensure `t.Helper()` is used when taking `testing.T`

### Interface Placement
- **Both agree**: Interfaces generally belong in consumer packages
- **Review guidance**: Flag only when interface placement prevents evolution; exceptions exist

**Reference**:
- [Google Go Style Guide](https://google.github.io/styleguide/go/)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)

---

## When in Doubt

Reference the full style guide in `uber-go-style-guide.md` for detailed explanations and architectural context.

**Remember**: Focus on design decisions that require understanding of intent, ownership, lifecycle, and architecture. Let linters handle syntax and common bugs.
