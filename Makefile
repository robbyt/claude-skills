.PHONY: all
all: help

## help: Display this help message
.PHONY: help
help: Makefile
	@echo
	@echo " Choose a make command to run"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'
	@echo

## test-plugin: Run tests for a specific plugin (make test-plugin PLUGIN=black-formatter)
.PHONY: test-plugin
test-plugin:
	@cd "plugins/$(PLUGIN)" && bash tests/test.sh

## test: Run all plugin tests (auto-discovers tests/test.sh in each plugin)
.PHONY: test
test:
	@FAILED=0; \
	PASSED=0; \
	for plugin_dir in plugins/*/; do \
		if [ -f "$$plugin_dir/tests/test.sh" ]; then \
			plugin_name=$$(basename "$$plugin_dir"); \
			echo "==============================================================================="; \
			if $(MAKE) -s test-plugin PLUGIN=$$plugin_name; then \
				echo "PASS: $$plugin_name"; \
				PASSED=$$((PASSED + 1)); \
			else \
				echo "FAIL: $$plugin_name"; \
				FAILED=$$((FAILED + 1)); \
			fi; \
			echo "==============================================================================="; \
		fi; \
	done; \
	echo "Results: $$PASSED passed, $$FAILED failed"; \
	if [ $$FAILED -ne 0 ]; then \
		exit 1; \
	fi

## list-tests: List all plugins with and without tests
.PHONY: list-tests
list-tests:
	@echo "Plugins with tests:"
	@for plugin_dir in plugins/*/; do \
		if [ -f "$$plugin_dir/tests/test.sh" ]; then \
			echo "  ✓ $$(basename "$$plugin_dir")"; \
		fi; \
	done
	@echo
	@echo "Plugins without tests:"
	@for plugin_dir in plugins/*/; do \
		if [ ! -f "$$plugin_dir/tests/test.sh" ]; then \
			echo "  - $$(basename "$$plugin_dir")"; \
		fi; \
	done

## clean: Clean up test artifacts
.PHONY: clean
clean:
	@echo "Cleaning up test artifacts..."
	@rm -rf /tmp/claude-skills-test-*
	@echo "Cleaned up test artifacts"

## check: Run all tests and checks
.PHONY: check
check: test
