# Error Handling

Patterns for error types, wrapping, aggregation, and panic avoidance.

---

## Error Types

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

## Error Wrapping

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

### Error Chain Structure

Place `%w` at the end of error strings to mirror the error chain structure (newest to oldest):

```go
// Good - %w at end mirrors chain structure
return fmt.Errorf("read config: %w", err)
// Error chain: "read config: open file: permission denied"
//              [newest]    [middle]   [oldest/root cause]
```

Error chains form newest-to-oldest hierarchies. Placing `%w` at the end makes the chain structure clear when reading error messages.

### Error Translation at Boundaries

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

## Error Naming

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

## Error String Format

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

## Handle Errors Once

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

## Error Aggregation

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

## Don't Panic

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

## Must Functions

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

## Exit in Main

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

## Exit Once

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
