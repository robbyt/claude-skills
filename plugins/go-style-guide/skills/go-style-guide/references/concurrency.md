# Concurrency

Patterns for goroutines, mutexes, channels, and race condition prevention.

---

## Atomic Operations

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

## Avoid Mutable Globals

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

## Don't Fire-and-Forget Goroutines

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

## No Goroutines in init()

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

## Closure Variable Capture

Closures capture variables from their enclosing scope by reference. When multiple goroutines write to the same captured variable, this causes a data race.

**Bad** (captures outer variable):
```go
func Run() error {
  err := setup()
  if err != nil {
    return err
  }

  var wg sync.WaitGroup
  wg.Go(func() {
    err = taskA()  // Race: writes to captured outer err
  })
  wg.Go(func() {
    err = taskB()  // Race: writes to captured outer err
  })
  wg.Wait()
  return err
}
```

**Good** (local variable):
```go
wg.Go(func() {
  err := taskA()  // New local variable
  // handle err locally
})
```

**Good** (named return):
```go
wg.Go(func() (err error) {
  err = taskA()  // Named return is local to closure
  return
})
```

**Why**: The one-character difference between `err =` and `err :=` determines whether a closure captures an outer variable or creates a new local one.

**Debugging**: Use `go build -gcflags='-d closure=1'` to print captured variables.

**Note**: Go 1.22+ fixed range loop variable capture, but general closure capture remains a manual concern.

---

## Stdlib Concurrent Safety Caveats

Types documented as "safe for concurrent use" (like `http.Client`) typically mean **some methods** are safe - not that all fields or operations are thread-safe. Modifying struct fields concurrently causes data races.

**Bad** (modifying shared client fields concurrently):
```go
type Fetcher struct {
  client *http.Client
}

func (f *Fetcher) FetchWithRedirects(ctx context.Context, url string) (*http.Response, error) {
  f.client.CheckRedirect = customPolicy  // Race if called concurrently!
  return f.client.Get(url)
}

func (f *Fetcher) FetchNoRedirects(ctx context.Context, url string) (*http.Response, error) {
  f.client.CheckRedirect = nil  // Race!
  return f.client.Get(url)
}
```

**Good** (inject pre-configured clients):
```go
type Fetcher struct {
  clientWithRedirects *http.Client
  clientNoRedirects   *http.Client
}

func NewFetcher() *Fetcher {
  return &Fetcher{
    clientWithRedirects: &http.Client{CheckRedirect: customPolicy},
    clientNoRedirects:   &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error {
      return http.ErrUseLastResponse
    }},
  }
}

func (f *Fetcher) FetchWithRedirects(ctx context.Context, url string) (*http.Response, error) {
  return f.clientWithRedirects.Get(url)
}

func (f *Fetcher) FetchNoRedirects(ctx context.Context, url string) (*http.Response, error) {
  return f.clientNoRedirects.Get(url)
}
```

**Why**: "Safe for concurrent use" means method calls (Get, Do) are synchronized internally. Field modification is not protected and requires external synchronization or separate instances.

**Common types affected**: `http.Client`, `http.Transport`, `sql.DB` configuration fields

**Rule**: Configure stdlib types at construction time. If goroutines need different configurations, inject separate pre-configured instances.

**Note**: Most stdlib types (`bytes.Buffer`, slices, maps) are NOT thread-safe. When passing `io.Writer`/`io.Reader` to libraries you don't control, wrap with a synchronized adapter that locks in `Write()`/`Read()`.

---

## Mutex and Data Scope Mismatch

A mutex only synchronizes access when all goroutines share the **same** mutex instance. Creating a new mutex per-request while sharing the underlying data provides no synchronization.

**Bad** (per-request mutex, shared data):
```go
var globalData = map[string]int{"a": 1}

type Service struct {
  data map[string]int
  mu   sync.Mutex
}

func NewService() *Service {
  return &Service{
    data: globalData,  // Shallow copy - shares underlying map!
    mu:   sync.Mutex{},  // New mutex per call - no shared synchronization
  }
}

func Handler(w http.ResponseWriter, r *http.Request) {
  svc := NewService()  // Each request gets own mutex
  svc.mu.Lock()
  defer svc.mu.Unlock()
  svc.data["key"] = 42  // Race! Different mutexes, same map
}
```

**Good** (Option 1 - global mutex for global data):
```go
var (
  globalData = map[string]int{"a": 1}
  globalMu   sync.Mutex
)

func Handler(w http.ResponseWriter, r *http.Request) {
  globalMu.Lock()
  defer globalMu.Unlock()
  globalData["key"] = 42  // All handlers share same mutex
}
```

**Good** (Option 2 - deep copy for per-request isolation):
```go
func NewService() *Service {
  return &Service{
    data: maps.Clone(globalData),  // Deep copy - isolated data
    mu:   sync.Mutex{},  // Own mutex for own data
  }
}
```

**Why**: Go's struct assignment is shallow - maps and slices copy the pointer, not the data. The mutex and data must have matching scope.

**Rule**: Mutex scope must match data scope. 1 mutex for N goroutines accessing shared data, or N mutexes for N isolated copies.

---

## Specify Channel Direction

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

## Channel Size

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

## Zero-value Mutexes

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

## Don't Copy Types with Sync Primitives

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
