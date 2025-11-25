# Style Guide

Core principles, naming conventions, documentation standards, and code style.

---

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
)
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

### Switch and Break

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

### Consistency

Maintain uniform style within packages. Apply conventions at package level or larger.

### Package Names

- All lowercase
- No underscores
- Short, succinct
- Singular (e.g., `net/url` not `net/urls`)
- Avoid generic names: "common," "util," "shared," "lib"

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
