#!/bin/bash

# Agent 3: Unit Test Generator
# This is a generic agent that generates unit tests for implemented code
# It discovers the implementation and generates comprehensive unit tests

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
	source "$SCRIPT_DIR/.env"
fi

# Default values from environment or hardcoded
PR_NUMBER=""
EXISTING_APP_BRD="${DEMO_EXISTING_APP_BRD:-}"
EXISTING_APP_ARCH="${DEMO_EXISTING_APP_ARCH:-}"
WORKSPACE_ROOT="${DEMO_WORKSPACE_ROOT:-.}"
GIT_REPO="${DEMO_GIT_REPO:-}"
CONTEXT_DIRS=""
OUTPUT_DIR="sdlc-artifacts"

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--pr-number)
		PR_NUMBER="$2"
		shift 2
		;;
	--existing-app-brd)
		EXISTING_APP_BRD="$2"
		shift 2
		;;
	--existing-app-arch)
		EXISTING_APP_ARCH="$2"
		shift 2
		;;
	--workspace-root)
		WORKSPACE_ROOT="$2"
		shift 2
		;;
	--context-dirs)
		CONTEXT_DIRS="$2"
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
if [ -z "$PR_NUMBER" ]; then
	echo "Error: --pr-number is required"
	exit 1
fi

# Validate optional files if provided
if [ -n "$EXISTING_APP_BRD" ] && [ ! -f "$EXISTING_APP_BRD" ]; then
	echo "Error: Existing application BRD file not found: $EXISTING_APP_BRD"
	exit 1
fi

if [ -n "$EXISTING_APP_ARCH" ] && [ ! -f "$EXISTING_APP_ARCH" ]; then
	echo "Error: Existing application architecture file not found: $EXISTING_APP_ARCH"
	exit 1
fi

# Clone Git repository if provided and repo directory doesn't exist
if [ -n "$GIT_REPO" ]; then
	REPO_DIR="$WORKSPACE_ROOT/Inventory-system"
	if [ ! -d "$REPO_DIR" ]; then
		echo "Cloning repository from $GIT_REPO to $REPO_DIR..."
		git clone "$GIT_REPO" "$REPO_DIR"
		echo "Repository cloned successfully."
		echo ""
	else
		echo "Repository directory already exists: $REPO_DIR"
		echo "Skipping git clone."
		echo ""
	fi
fi

# Create output directory
mkdir -p "$OUTPUT_DIR/unit-tests"

echo "=========================================="
echo "Agent 3: Unit Test Generator"
echo "=========================================="
echo "Git Repository: ${GIT_REPO:-Not provided}"
echo "PR Number: $PR_NUMBER"
echo "Existing App BRD Path: ${EXISTING_APP_BRD:-Not provided}"
echo "Existing App Architecture Path: ${EXISTING_APP_ARCH:-Not provided}"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Context Directories: $CONTEXT_DIRS"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="$SCRIPT_DIR/policies/unit-tests.policy.md"

# Load policy file
if [ ! -f "$POLICY_FILE" ]; then
	echo "Error: Policy file not found: $POLICY_FILE"
	exit 1
fi

POLICY_CONTENT=$(cat "$POLICY_FILE")

# Build unit test generation instruction
UNIT_TEST_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:
- PR Number: $PR_NUMBER
- Implementation Changes: $OUTPUT_DIR/implementation/changes-summary.md"

if [ -n "$EXISTING_APP_BRD" ]; then
	UNIT_TEST_INSTRUCTION="$UNIT_TEST_INSTRUCTION
- Existing Application BRD Path: $EXISTING_APP_BRD"
fi

if [ -n "$EXISTING_APP_ARCH" ]; then
	UNIT_TEST_INSTRUCTION="$UNIT_TEST_INSTRUCTION
- Existing Application Architecture Path: $EXISTING_APP_ARCH"
fi

UNIT_TEST_INSTRUCTION="$UNIT_TEST_INSTRUCTION
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS
- Output Directory: $OUTPUT_DIR/unit-tests/

IMPORTANT: Create unit test plans in English language as markdown files:
1. unit-test-plan.md - Detailed test plan with test cases, scenarios, and expected outcomes
2. test-coverage.md - Coverage analysis and test strategy

Begin unit test plan generation now."

# Run Auggie agent to generate test plans
echo "Running Auggie agent to generate unit test plans..."
echo ""

auggie -p \
	--workspace-root "$WORKSPACE_ROOT" \
	"$UNIT_TEST_INSTRUCTION" >"$OUTPUT_DIR/unit-tests/agent-output.txt"

# Check if test plans were generated
if [ ! -f "$OUTPUT_DIR/unit-tests/unit-test-plan.md" ]; then
	echo "Warning: unit-test-plan.md not found, creating from agent output"
	echo "# Unit Test Plan" >"$OUTPUT_DIR/unit-tests/unit-test-plan.md"
	echo "" >>"$OUTPUT_DIR/unit-tests/unit-test-plan.md"
	echo "PR: #$PR_NUMBER" >>"$OUTPUT_DIR/unit-tests/unit-test-plan.md"
	echo "" >>"$OUTPUT_DIR/unit-tests/unit-test-plan.md"
	cat "$OUTPUT_DIR/unit-tests/agent-output.txt" >>"$OUTPUT_DIR/unit-tests/unit-test-plan.md"
fi

echo ""
echo "=========================================="
echo "Unit Test Plans Generated!"
echo "=========================================="
echo "Location: $OUTPUT_DIR/unit-tests/"
echo ""
echo "Generated files:"
echo "  - unit-test-plan.md"
echo "  - test-coverage.md (if available)"
echo "=========================================="

# Display test plan
if [ -f "$OUTPUT_DIR/unit-tests/unit-test-plan.md" ]; then
	echo ""
	echo "UNIT TEST PLAN:"
	cat "$OUTPUT_DIR/unit-tests/unit-test-plan.md"
fi

# Pause for manual approval
echo ""
echo "=========================================="
echo "Manual Approval Required"
echo "=========================================="
echo "Please review the unit test plans at: $OUTPUT_DIR/unit-tests/"
echo ""
read -p "Do you approve these test plans? (y/n): " APPROVAL

if [ "$APPROVAL" != "y" ] && [ "$APPROVAL" != "Y" ]; then
	echo ""
	echo "Unit test generation cancelled by user."
	exit 0
fi

# Generate actual test code
echo ""
echo "=========================================="
echo "Generating Unit Test Code"
echo "=========================================="

TEST_CODE_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:
- PR Number: $PR_NUMBER
- Implementation Changes: $OUTPUT_DIR/implementation/changes-summary.md
- Unit Test Plan: $OUTPUT_DIR/unit-tests/unit-test-plan.md"

if [ -n "$EXISTING_APP_BRD" ]; then
	TEST_CODE_INSTRUCTION="$TEST_CODE_INSTRUCTION
- Existing Application BRD Path: $EXISTING_APP_BRD"
fi

if [ -n "$EXISTING_APP_ARCH" ]; then
	TEST_CODE_INSTRUCTION="$TEST_CODE_INSTRUCTION
- Existing Application Architecture Path: $EXISTING_APP_ARCH"
fi

TEST_CODE_INSTRUCTION="$TEST_CODE_INSTRUCTION
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS

IMPORTANT: Generate actual unit test code files based on the approved test plan.
Follow the testing framework and conventions used in the codebase.

Begin unit test code generation now."

echo "Running Auggie agent to generate unit test code..."
echo ""

auggie -p \
	--workspace-root "$WORKSPACE_ROOT" \
	"$TEST_CODE_INSTRUCTION" >"$OUTPUT_DIR/unit-tests/code-generation-output.txt"

echo ""
echo "=========================================="
echo "Unit test code generated successfully!"
echo "=========================================="

# Create PR with unit tests
echo ""
echo "=========================================="
echo "Creating Pull Request for Unit Tests"
echo "=========================================="

# Navigate to workspace
cd "$WORKSPACE_ROOT"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
	echo "Error: Not a git repository. Skipping PR creation."
	exit 1
fi

# Create branch name
BRANCH_NAME="unit-tests-pr-$PR_NUMBER"
PR_TITLE="test: Add unit tests for PR #$PR_NUMBER"
PR_BODY="## Unit Tests

This PR adds unit tests for the implementation in PR #$PR_NUMBER.

## Test Coverage
See test-coverage.md for details.

## Test Plan
See unit-test-plan.md for the complete test plan.

## Checklist
- [x] Unit test plan reviewed and approved
- [x] Unit tests implemented
- [ ] All tests passing
- [ ] Ready for review"

# Create and checkout new branch
echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

# Stage all changes
echo "Staging changes..."
git add .

# Commit changes
echo "Committing changes..."
git commit -m "$PR_TITLE" -m "$PR_BODY" || echo "No changes to commit"

# Push branch to remote
echo "Pushing branch to remote..."
git push -u origin "$BRANCH_NAME" || {
	echo "Error: Failed to push branch to remote"
	exit 1
}

# Detect default branch
DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
if [ -z "$DEFAULT_BRANCH" ]; then
	DEFAULT_BRANCH="main"
fi

echo "Default branch detected: $DEFAULT_BRANCH"

# Create PR using GitHub CLI
echo "Creating pull request..."
if command -v gh &>/dev/null; then
	gh pr create \
		--title "$PR_TITLE" \
		--body "$PR_BODY" \
		--base "$DEFAULT_BRANCH" \
		--head "$BRANCH_NAME" || {
		echo "Error: Failed to create PR. You may need to create it manually."
		echo "Branch pushed: $BRANCH_NAME"
	}

	# Get PR details
	TEST_PR_NUMBER=$(gh pr list --head "$BRANCH_NAME" --json number --jq '.[0].number')
	TEST_PR_URL=$(gh pr list --head "$BRANCH_NAME" --json url --jq '.[0].url')

	if [ -n "$TEST_PR_NUMBER" ]; then
		echo ""
		echo "=========================================="
		echo "Pull Request Created Successfully!"
		echo "=========================================="
		echo "PR Number: #$TEST_PR_NUMBER"
		echo "Branch: $BRANCH_NAME"
		echo ""
		echo "PR URL: $TEST_PR_URL"
		echo "=========================================="

		# Save PR details
		echo "$TEST_PR_NUMBER" >"$OUTPUT_DIR/unit-tests/pr-number.txt"
		echo "$TEST_PR_URL" >"$OUTPUT_DIR/unit-tests/pr-url.txt"

		echo ""
		echo "View Pull Request: $TEST_PR_URL"
	fi
else
	echo "Warning: GitHub CLI (gh) not found. Please install it to create PRs automatically."
	echo "Branch pushed: $BRANCH_NAME"
	echo "Please create the PR manually at your repository."
fi

exit 0
