# Testing Patterns

Patterns for table-driven tests, parallel tests, benchmarks, and test helpers.

---

## CRITICAL: Don't Call t.Fatal from Goroutines

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

## Table-Driven Tests

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

## Avoid Test Complexity

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

## Parallel Tests

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

## Context in Tests

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

## Testing Time

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

## Benchmark Loop Pattern

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

## Test Helper Patterns

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

## Test Failure Messages

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

## t.Error vs t.Fatal Choice

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

## Test Assertions

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
