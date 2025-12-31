#!/bin/bash

# Agent 5 & 6: Test Executor with Auto-Fix and Retry
# This is a generic agent that runs tests and automatically fixes failures
# It retries up to MAX_RETRIES times before failing

set -e

# Default values
TEST_TYPE=""
MAX_RETRIES=5
WORKSPACE_ROOT="."
OUTPUT_DIR="sdlc-artifacts"

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--test-type)
		TEST_TYPE="$2"
		shift 2
		;;
	--max-retries)
		MAX_RETRIES="$2"
		shift 2
		;;
	--workspace-root)
		WORKSPACE_ROOT="$2"
		shift 2
		;;
	--output-dir)
		OUTPUT_DIR="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

# Validate required parameters
if [ -z "$TEST_TYPE" ]; then
	echo "Error: --test-type is required (unit or integration)"
	exit 1
fi

if [ "$TEST_TYPE" != "unit" ] && [ "$TEST_TYPE" != "integration" ]; then
	echo "Error: --test-type must be 'unit' or 'integration'"
	exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR/test-results/$TEST_TYPE"

echo "=========================================="
echo "Agent 5/6: CI Pipeline - $TEST_TYPE Tests"
echo "=========================================="
echo "Test Type: $TEST_TYPE"
echo "Max Retries: $MAX_RETRIES"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Initialize retry counter
RETRY_COUNT=0
TEST_PASSED=false

# Function to discover and run tests
run_tests() {
	local attempt=$1

	echo "=========================================="
	echo "Attempt $attempt of $((MAX_RETRIES + 1))"
	echo "=========================================="

	# Discover test command based on project structure
	TEST_COMMAND=""

	# Check for Python/pytest
	if [ -f "$WORKSPACE_ROOT/pytest.ini" ] || [ -f "$WORKSPACE_ROOT/pyproject.toml" ]; then
		if [ "$TEST_TYPE" == "unit" ]; then
			TEST_COMMAND="pytest tests/unit -v --tb=short --junitxml=$OUTPUT_DIR/test-results/$TEST_TYPE/results-$attempt.xml"
		else
			TEST_COMMAND="pytest tests/integration -v --tb=short --junitxml=$OUTPUT_DIR/test-results/$TEST_TYPE/results-$attempt.xml"
		fi
	# Check for Node.js/npm
	elif [ -f "$WORKSPACE_ROOT/package.json" ]; then
		if [ "$TEST_TYPE" == "unit" ]; then
			TEST_COMMAND="npm run test:unit"
		else
			TEST_COMMAND="npm run test:integration"
		fi
	# Check for Django
	elif [ -f "$WORKSPACE_ROOT/manage.py" ]; then
		if [ "$TEST_TYPE" == "unit" ]; then
			TEST_COMMAND="python manage.py test --tag=unit"
		else
			TEST_COMMAND="python manage.py test --tag=integration"
		fi
	else
		echo "Error: Could not detect test framework"
		return 1
	fi

	echo "Running command: $TEST_COMMAND"
	echo ""

	# Run tests and capture output
	if eval "$TEST_COMMAND" >"$OUTPUT_DIR/test-results/$TEST_TYPE/output-$attempt.txt" 2>&1; then
		echo "All tests passed!"
		cat "$OUTPUT_DIR/test-results/$TEST_TYPE/output-$attempt.txt"
		return 0
	else
		echo "ERROR: Tests failed!"
		cat "$OUTPUT_DIR/test-results/$TEST_TYPE/output-$attempt.txt"
		return 1
	fi
}

# Function to analyze failures and fix
fix_test_failures() {
	local attempt=$1

	echo ""
	echo "=========================================="
	echo "Analyzing failures and attempting fix..."
	echo "=========================================="

	# Get the directory where this script is located
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	POLICY_FILE="$SCRIPT_DIR/policies/test-execution.policy.md"

	# Load policy file
	if [ ! -f "$POLICY_FILE" ]; then
		echo "Error: Policy file not found: $POLICY_FILE"
		exit 1
	fi

	POLICY_CONTENT=$(cat "$POLICY_FILE")

	# Build fix instruction
	FIX_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:
- Test Type: $TEST_TYPE tests
- Attempt: $attempt of $((MAX_RETRIES + 1))
- Test Output: $OUTPUT_DIR/test-results/$TEST_TYPE/output-$attempt.txt
- Workspace Root: $WORKSPACE_ROOT
- Output Directory: $OUTPUT_DIR/test-results/$TEST_TYPE/

Begin analysis and fix now."

	# Run Auggie agent to fix failures
	auggie -p \
		--workspace-root "$WORKSPACE_ROOT" \
		--max-turns 10 \
		"$FIX_INSTRUCTION" >"$OUTPUT_DIR/test-results/$TEST_TYPE/fix-output-$attempt.txt"

	# Check if fix summary was created
	if [ -f "$OUTPUT_DIR/test-results/$TEST_TYPE/fix-summary-$attempt.md" ]; then
		echo ""
		echo "FIX SUMMARY:"
		cat "$OUTPUT_DIR/test-results/$TEST_TYPE/fix-summary-$attempt.md"
	fi

	# Commit the fixes
	git config user.name "github-actions[bot]"
	git config user.email "github-actions[bot]@users.noreply.github.com"
	git add .
	git commit -m "fix: auto-fix $TEST_TYPE test failures (attempt $attempt)" || echo "No changes to commit"
	git push || echo "Failed to push changes"
}

# Main retry loop
while [ $RETRY_COUNT -le $MAX_RETRIES ]; do
	ATTEMPT=$((RETRY_COUNT + 1))

	if run_tests $ATTEMPT; then
		TEST_PASSED=true
		break
	else
		if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
			echo ""
			echo "Tests failed on attempt $ATTEMPT. Attempting to fix..."
			fix_test_failures $ATTEMPT
			echo ""
			echo "Retrying tests after fix..."
			RETRY_COUNT=$((RETRY_COUNT + 1))
		else
			echo ""
			echo "=========================================="
			echo "ERROR: HARD FAILURE: All $((MAX_RETRIES + 1)) attempts exhausted"
			echo "=========================================="
			break
		fi
	fi
done

# Final result
echo ""
echo "=========================================="
if [ "$TEST_PASSED" = true ]; then
	echo "SUCCESS: $TEST_TYPE tests passed!"
	echo "Attempts used: $ATTEMPT"
	echo "=========================================="
	exit 0
else
	echo "ERROR: FAILURE: $TEST_TYPE tests failed after $((MAX_RETRIES + 1)) attempts"
	echo "=========================================="
	echo ""
	echo "Please review the test output and fix manually:"
	echo "- Test outputs: $OUTPUT_DIR/test-results/$TEST_TYPE/"
	echo "- Latest output: $OUTPUT_DIR/test-results/$TEST_TYPE/output-$ATTEMPT.txt"
	exit 1
fi
