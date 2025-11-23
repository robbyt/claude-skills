Run the automated test suite for all plugins using the Makefile test discovery system.

## Instructions

Use the Bash tool to run:
```bash
make test
```

This automatically discovers and runs all plugin tests (any plugin with a `tests/test.sh` script).

## Alternative Commands

Test a specific plugin:
```bash
make test-plugin PLUGIN=<plugin-name>
```

List which plugins have tests:
```bash
make list-tests
```

See TESTING.md for more information about the test discovery system.
