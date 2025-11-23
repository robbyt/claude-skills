# Plugin Testing Guide

## Overview

This repository uses an automated test discovery system. All plugins must use a `tests/` directory (plural). Any plugin with `tests/test.sh` will be automatically tested when running `make test`.

## Running Tests

```bash
# Run all plugin tests
make test

# Run tests for a specific plugin
make test-plugin PLUGIN=black-formatter

# List plugins with/without tests
make list-tests

# Clean up test artifacts
make clean
```

## Adding Tests to a Plugin

1. Create a `tests/` directory in your plugin root
2. Add a `test.sh` script (see existing plugins for examples)
3. Make it executable: `chmod +x tests/test.sh`
4. The script should:
   - Run from the plugin root directory
   - Exit 0 on success, non-zero on failure
   - Print clear pass/fail messages

## Test Script Templates

### For Formatter/Hook Plugins

See `plugins/black-formatter/tests/test.sh` for a complete example.

These tests validate that post-write hooks work correctly by:
1. Validating hook configuration (`hooks.json` schema)
2. Testing hook script execution with simulated Claude Code JSON payloads
3. Verifying files are formatted when hooks fire
4. Testing edge cases (non-target files, missing files, invalid JSON)
5. End-to-end integration test using `claude` CLI

#### End-to-End Integration Tests

Hook plugins include an integration test that requires the `claude` CLI:
- Tests complete workflow: Read → Write → Hook execution → Formatting
- Uses specific flags: `--permission-mode acceptEdits`, `--tools "Read,Write"`, `--print`
- Test artifacts stored in `tests/tmp/` (gitignored)
- Fails if `claude` command not found in PATH or `~/.claude/local/claude`

### For Skill Plugins

See `plugins/claude-md-reflect/tests/test.sh` or `plugins/uber-go-style-guide/tests/test.sh` for complete examples.

These tests validate plugin structure:
1. Verify SKILL.md exists and has required frontmatter
2. Verify plugin.json is valid JSON
3. Check required fields are present
4. Verify reference files exist

## Test Directory Structure

### For Formatter/Hook Plugins:
```
plugin-name/
├── tests/
│   ├── test.sh          # Hook integration tests
│   ├── tmp/             # Test artifacts (gitignored)
│   └── fixtures/
```

### For Skill Plugins:
```
plugin-name/
├── tests/
│   └── test.sh          # Validation script
```

## Test Output Format

Test scripts produce clear pass/fail output:

```
Running tests for black-formatter hook...

  Running: Validate hooks.json schema
    ✓ Passed
  Running: Hook formats Python file (Write tool)
    ✓ Passed

All tests passed! (7/7)
```

## Continuous Integration

The test discovery system is designed to work seamlessly in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: make test
```

## Best Practices

1. **Keep tests fast**: Tests should complete in seconds
2. **Test integration**: For hooks, test the hook mechanism, not just the underlying tool
3. **Validate structure**: For skills, validate file structure and required fields
4. **Provide clear output**: Use colored indicators (✓/✗) and descriptive messages
5. **Exit correctly**: Return 0 for success, non-zero for any failure
6. **Clean up**: Remove test artifacts in gitignored directories

## Debugging Failed Tests

When a test fails:

1. Run the specific plugin test: `make test-plugin PLUGIN=<name>`
2. For hook tests: verify the hook script has execute permissions
3. For hook tests: check that `claude` CLI is installed and tool commands are accessible (e.g., `black`, `gofmt`)
4. Ensure dependencies are installed: `uv sync`
5. Review test output for specific failure reasons
