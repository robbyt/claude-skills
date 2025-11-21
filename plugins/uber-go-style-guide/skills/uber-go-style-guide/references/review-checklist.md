# Review Checklist - Common Violations

Quick reference for frequently violated patterns in Go code. Use this to prioritize review focus.

## Critical Issues (Must Fix)

### Unhandled Errors
```go
// BAD
file.Close()
json.Unmarshal(data, &v)

// GOOD
if err := file.Close(); err != nil {
  return fmt.Errorf("close file: %w", err)
}
if err := json.Unmarshal(data, &v); err != nil {
  return fmt.Errorf("unmarshal: %w", err)
}
```

### Type Assertions Without Check
```go
// BAD - Panics if wrong type
str := value.(string)

// GOOD
str, ok := value.(string)
if !ok {
  return fmt.Errorf("expected string, got %T", value)
}
```

### Panics in Production Code
```go
// BAD
if len(args) == 0 {
  panic("missing args")
}

// GOOD
if len(args) == 0 {
  return errors.New("missing args")
}
```

### Fire-and-Forget Goroutines
```go
// BAD - No lifecycle management
go func() {
  for {
    doWork()
    time.Sleep(interval)
  }
}()

// GOOD
type Worker struct {
  stop chan struct{}
  done chan struct{}
}

func (w *Worker) Start() {
  go func() {
    defer close(w.done)
    for {
      select {
      case <-time.After(interval):
        doWork()
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

### Missing Defer for Unlock
```go
// BAD
m.Lock()
if condition {
  m.Unlock()
  return
}
doWork()
m.Unlock()

// GOOD
m.Lock()
defer m.Unlock()
if condition {
  return
}
doWork()
```

## Important Issues (Should Fix)

### Handling Errors Multiple Times
```go
// BAD - Logs AND returns
if err != nil {
  log.Printf("error: %v", err)
  return fmt.Errorf("operation failed: %w", err)
}

// GOOD - Return with context
if err != nil {
  return fmt.Errorf("operation failed: %w", err)
}
// Let caller decide whether to log
```

### Not Copying Slices/Maps at Boundaries
```go
// BAD
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = trips  // Caller can mutate!
}

// GOOD (Go 1.21+)
import "slices"

func (d *Driver) SetTrips(trips []Trip) {
  d.trips = slices.Clone(trips)
}

// GOOD (Alternative)
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}
```

### Embedded Types in Public Structs
```go
// BAD - Leaks implementation
type ConcreteList struct {
  AbstractList  // Public API couples to AbstractList
}

// GOOD - Explicit delegation
type ConcreteList struct {
  list *AbstractList
}

func (c *ConcreteList) Add(e Entity) {
  c.list.Add(e)
}
```

### os.Exit or log.Fatal Outside main()
```go
// BAD
func process() {
  if err := validate(); err != nil {
    log.Fatal(err)  // Bypasses caller's defers!
  }
}

// GOOD
func process() error {
  if err := validate(); err != nil {
    return fmt.Errorf("validate: %w", err)
  }
  return nil
}

func main() {
  if err := process(); err != nil {
    log.Fatal(err)  // Only in main
  }
}
```

### Goroutines in init()
```go
// BAD
func init() {
  go backgroundTask()  // Can't control lifecycle
}

// GOOD
type Service struct {
  stop chan struct{}
}

func (s *Service) Start() {
  go s.backgroundTask()
}

func (s *Service) Close() error {
  close(s.stop)
  return nil
}
```

### Mutex Embedding
```go
// BAD - Exposes Lock/Unlock publicly
type Counter struct {
  sync.Mutex
  n int
}

// GOOD - Private field
type Counter struct {
  mu sync.Mutex
  n  int
}
```

### Not Using var for Zero Values
```go
// BAD
users := []User{}
config := Config{}

// GOOD
var users []User   // Nil slice is valid and usable
var config Config  // All fields zero-valued
```

### Missing Field Names in Struct Initialization
```go
// BAD - Fragile to field reordering
u := User{"John", "Doe", 30}

// GOOD
u := User{
  FirstName: "John",
  LastName:  "Doe",
  Age:       30,
}
```

### Redundant Error Wrapping Messages
```go
// BAD
return fmt.Errorf("failed to create store: %w", err)

// GOOD
return fmt.Errorf("create store: %w", err)
```

### Not Specifying Container Capacity
```go
// BAD - Multiple reallocations
results := make([]Result, 0)
for _, item := range items {
  results = append(results, process(item))
}

// GOOD
results := make([]Result, 0, len(items))
for _, item := range items {
  results = append(results, process(item))
}
```

### Using fmt.Sprint Instead of strconv
```go
// BAD - Slower, more allocations
s := fmt.Sprint(id)

// GOOD
s := strconv.Itoa(id)
```

### Inconsistent Import Grouping
```go
// BAD
import (
  "go.uber.org/zap"
  "fmt"
  "github.com/user/pkg"
  "os"
)

// GOOD - stdlib, then external
import (
  "fmt"
  "os"

  "github.com/user/pkg"
  "go.uber.org/zap"
)
```

### Using new() Instead of &T{}
```go
// BAD
cfg := new(Config)

// GOOD
cfg := &Config{}
```

### Excessive Nesting
```go
// BAD
if err == nil {
  if valid {
    if ready {
      // Success case deeply nested
    }
  }
}

// GOOD - Early returns
if err != nil {
  return err
}
if !valid {
  return ErrInvalid
}
if !ready {
  return ErrNotReady
}
// Success case at top level
```

### Unnecessary else
```go
// BAD
var a int
if b {
  a = 100
} else {
  a = 10
}

// GOOD
a := 10
if b {
  a = 100
}
```

### Complex Table Tests
Look for table tests with:
- Multiple boolean flags (`shouldErr`, `shouldCallX`, `shouldCallY`)
- Cascading assertions (if X then check Y, else check Z)
- Deep mock setup with branching

**Solution**: Split into separate test functions

### Channel Buffer Size > 1
```go
// BAD - Hard to justify
c := make(chan int, 100)

// GOOD
c := make(chan int)      // Unbuffered
c := make(chan int, 1)   // Buffered by 1 for specific use case
```

### Interface Pointers
```go
// BAD
var i *io.Reader

// GOOD
var i io.Reader
```

### Global Mutable State
```go
// BAD
var cache = make(map[string]string)

func Get(key string) string {
  return cache[key]  // Hard to test
}

// GOOD - Dependency injection
type Cache struct {
  data map[string]string
}

func New() *Cache {
  return &Cache{data: make(map[string]string)}
}

func (c *Cache) Get(key string) string {
  return c.data[key]
}
```

### Manual Slice Operations (Should Use slices Package)
```go
// BAD - Manual operations
original := []int{1, 2, 3}
copy := make([]int, len(original))
copy(copy, original)

// GOOD - Use slices package (Go 1.21+)
import "slices"

copy := slices.Clone(original)
slices.Sort(items)
found := slices.Contains(items, value)
```

### time.Sleep in Tests (Should Use testing/synctest)
```go
// BAD - Slow test
func TestTimeout(t *testing.T) {
  time.Sleep(5 * time.Second)  // Slow!
}

// GOOD - Use synctest (Go 1.25+)
import "testing/synctest"

func TestTimeout(t *testing.T) {
  synctest.Run(func() {
    time.Sleep(5 * time.Second)  // Instant
  })
}
```

### Manual b.N Loop (Should Use b.Loop())
```go
// BAD - Manual loop management
func BenchmarkOp(b *testing.B) {
  setup()
  b.ResetTimer()  // Easy to forget
  for i := 0; i < b.N; i++ {
    operation()
  }
}

// GOOD - Use b.Loop() (Go 1.24+)
func BenchmarkOp(b *testing.B) {
  setup()
  for b.Loop() {
    operation()
  }
}
```

### t.Fatal in Goroutines (Critical Safety Issue)
```go
// BAD - Will panic
go func() {
  if err != nil {
    t.Fatal(err)  // Unsafe from goroutine!
  }
}()

// GOOD - Use t.Error
go func() {
  if err != nil {
    t.Error(err)  // Safe from goroutine
  }
}()
```

### Manual Error Aggregation (Should Use errors.Join)
```go
// BAD - Manual aggregation
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
    errs = append(errs, err)
  }
}
return errors.Join(errs...)  // Returns nil if empty
```

### Map/Slice Reallocation (Should Use clear())
```go
// BAD - Loses capacity
m = make(map[string]int)

// GOOD - Retains capacity (Go 1.21+)
clear(m)
```

### Atomic Package Import (Should Use sync/atomic)
```go
// BAD - External dependency
import "go.uber.org/atomic"

// GOOD - Standard library (Go 1.19+)
import "sync/atomic"

type Counter struct {
  n atomic.Int64
}
```

## Review Workflow

1. **Critical Issues First**: Scan for panics, unhandled errors, race conditions
2. **Important Issues**: Check error handling, boundaries, lifecycle management
3. **Pattern Recognition**: Look for repeated violations in the checklist
4. **Context Matters**: Some patterns are acceptable in specific contexts (e.g., panic in tests)

## Common False Positives

- `init()` for database driver registration (acceptable)
- Panic in test code using `t.Fatal` (acceptable)
- Global constants (acceptable)
- Embedding in private structs for composition (sometimes acceptable)

## When in Doubt

Reference the full style guide in `uber-go-style-guide.md` for detailed explanations and additional patterns.
