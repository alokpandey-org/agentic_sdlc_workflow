#!/bin/bash

# Agent 3: Unit Test Generator
# This agent generates unit tests for implemented user stories
# It assumes the story implementation is already complete on the specified branch
# It only generates unit tests if applicable based on existing test patterns
# Supports interactive (-i) and non-interactive modes

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
	source "$SCRIPT_DIR/.env"
fi

# Source JIRA utilities
source "$SCRIPT_DIR/jira-utils.sh"

# Default values from environment or hardcoded
WORKSPACE_ROOT="${DEMO_WORKSPACE_ROOT:-}"
JIRA_TICKET_ID=""
STORY_BRANCH=""
EXISTING_APP_BRD="${DEMO_EXISTING_APP_BRD:-}"
EXISTING_APP_ARCH="${DEMO_EXISTING_APP_ARCH:-}"
GIT_REPO="${DEMO_GIT_REPO:-}"
CONTEXT_DIRS=""
INTERACTIVE_MODE=false
POLICY_FILE="$SCRIPT_DIR/policies/unit-tests.policy.md"
GENERATE_ONLY=false
PUBLISH_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-i | --interactive)
		INTERACTIVE_MODE=true
		shift
		;;
	--workspace-root)
		WORKSPACE_ROOT="$2"
		shift 2
		;;
	--jira-ticket-id)
		JIRA_TICKET_ID="$2"
		shift 2
		;;
	--story-branch)
		STORY_BRANCH="$2"
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
	--git-repo)
		GIT_REPO="$2"
		shift 2
		;;
	--context-dirs)
		CONTEXT_DIRS="$2"
		shift 2
		;;
	--policy-file)
		POLICY_FILE="$2"
		shift 2
		;;
	--generate-only)
		GENERATE_ONLY=true
		shift
		;;
	--publish-only)
		PUBLISH_ONLY=true
		shift
		;;
	*)
		echo "Unknown option: $1"
		echo "Usage: $0 [-i|--interactive] [--workspace-root PATH] [--jira-ticket-id ID] [--story-branch BRANCH] [--existing-app-brd PATH] [--existing-app-arch PATH] [--git-repo URL] [--context-dirs DIRS] [--policy-file FILE] [--generate-only] [--publish-only]"
		exit 1
		;;
	esac
done

# Interactive mode: prompt for inputs
if [ "$INTERACTIVE_MODE" = true ]; then
	echo "=========================================="
	echo "Interactive Mode: Unit Test Generator"
	echo "=========================================="
	echo ""

	# Prompt for Git repository
	if [ -n "$GIT_REPO" ]; then
		read -p "Enter Git repository URL [default: $GIT_REPO]: " input
		GIT_REPO="${input:-$GIT_REPO}"
	else
		read -p "Enter Git repository URL (optional, press Enter to skip): " GIT_REPO
	fi

	# Prompt for workspace root
	if [ -n "$WORKSPACE_ROOT" ]; then
		read -p "Enter workspace root directory [default: $WORKSPACE_ROOT]: " input
		WORKSPACE_ROOT="${input:-$WORKSPACE_ROOT}"
	else
		read -p "Enter workspace root directory [default: .]: " input
		WORKSPACE_ROOT="${input:-.}"
	fi

	# Prompt for JIRA ticket ID
	if [ -z "$JIRA_TICKET_ID" ]; then
		read -p "Enter JIRA ticket ID (Story): " JIRA_TICKET_ID
	fi

	# Prompt for story branch
	if [ -z "$STORY_BRANCH" ]; then
		read -p "Enter story branch name (with implementation): " STORY_BRANCH
	fi

	# Prompt for existing application BRD
	if [ -n "$EXISTING_APP_BRD" ]; then
		read -p "Enter existing application BRD document path [default: $EXISTING_APP_BRD]: " input
		EXISTING_APP_BRD="${input:-$EXISTING_APP_BRD}"
	else
		read -p "Enter existing application BRD document path: " EXISTING_APP_BRD
	fi

	# Prompt for existing application architecture
	if [ -n "$EXISTING_APP_ARCH" ]; then
		read -p "Enter existing application architecture documentation path [default: $EXISTING_APP_ARCH]: " input
		EXISTING_APP_ARCH="${input:-$EXISTING_APP_ARCH}"
	else
		read -p "Enter existing application architecture documentation path: " EXISTING_APP_ARCH
	fi

	# Prompt for context directories
	read -p "Enter context directories (comma-separated) [default: src,docs]: " input
	CONTEXT_DIRS="${input:-src,docs}"

	# Prompt for policy file
	read -p "Enter policy file path [default: $POLICY_FILE]: " input
	POLICY_FILE="${input:-$POLICY_FILE}"

	echo ""
fi

# Non-interactive mode: use environment variables if parameters not provided
if [ "$INTERACTIVE_MODE" = false ]; then
	WORKSPACE_ROOT="${WORKSPACE_ROOT:-${ENV_WORKSPACE_ROOT:-.}}"
	JIRA_TICKET_ID="${JIRA_TICKET_ID:-${ENV_JIRA_TICKET_ID}}"
	STORY_BRANCH="${STORY_BRANCH:-${ENV_STORY_BRANCH}}"
	EXISTING_APP_BRD="${EXISTING_APP_BRD:-${ENV_EXISTING_APP_BRD}}"
	EXISTING_APP_ARCH="${EXISTING_APP_ARCH:-${ENV_EXISTING_APP_ARCH}}"
	GIT_REPO="${GIT_REPO:-${ENV_GIT_REPO}}"
	CONTEXT_DIRS="${CONTEXT_DIRS:-${ENV_CONTEXT_DIRS:-src,docs}}"
	POLICY_FILE="${POLICY_FILE:-${ENV_POLICY_FILE:-$SCRIPT_DIR/policies/unit-tests.policy.md}}"
fi

# Validate flag usage: --generate-only and --publish-only only work in non-interactive mode
if [ "$INTERACTIVE_MODE" = true ]; then
	if [ "$GENERATE_ONLY" = true ] || [ "$PUBLISH_ONLY" = true ]; then
		echo "Error: --generate-only and --publish-only flags are only supported in non-interactive mode"
		exit 1
	fi
fi

# Validate that --generate-only and --publish-only are mutually exclusive
if [ "$GENERATE_ONLY" = true ] && [ "$PUBLISH_ONLY" = true ]; then
	echo "Error: --generate-only and --publish-only cannot be used together"
	exit 1
fi

# Validate required parameters
if [ -z "$WORKSPACE_ROOT" ]; then
	echo "Error: Workspace root is required"
	echo "Provide via --workspace-root argument, interactive mode (-i), or ENV_WORKSPACE_ROOT environment variable"
	exit 1
fi

if [ -z "$JIRA_TICKET_ID" ]; then
	echo "Error: JIRA ticket ID is required"
	echo "Provide via --jira-ticket-id argument, interactive mode (-i), or ENV_JIRA_TICKET_ID environment variable"
	exit 1
fi

if [ -z "$STORY_BRANCH" ]; then
	echo "Error: Story branch is required"
	echo "Provide via --story-branch argument, interactive mode (-i), or ENV_STORY_BRANCH environment variable"
	exit 1
fi

if [ -z "$EXISTING_APP_BRD" ]; then
	echo "Error: Existing application BRD is required"
	echo "Provide via --existing-app-brd argument, interactive mode (-i), or ENV_EXISTING_APP_BRD environment variable"
	exit 1
fi

if [ -z "$EXISTING_APP_ARCH" ]; then
	echo "Error: Existing application architecture is required"
	echo "Provide via --existing-app-arch argument, interactive mode (-i), or ENV_EXISTING_APP_ARCH environment variable"
	exit 1
fi

# Validate files exist
if [ ! -f "$EXISTING_APP_BRD" ]; then
	echo "Error: Existing application BRD file not found: $EXISTING_APP_BRD"
	exit 1
fi

if [ ! -f "$EXISTING_APP_ARCH" ]; then
	echo "Error: Existing application architecture file not found: $EXISTING_APP_ARCH"
	exit 1
fi

# Display configuration
echo "=========================================="
echo "Agent 3: Unit Test Generator"
echo "=========================================="
echo "Mode: $([ "$INTERACTIVE_MODE" = true ] && echo "Interactive" || echo "Non-Interactive")"
if [ "$GENERATE_ONLY" = true ]; then
	echo "Phase: Generate Only (Phase 1 - Test Plan)"
elif [ "$PUBLISH_ONLY" = true ]; then
	echo "Phase: Publish Only (Phase 2 - Test Code)"
fi
echo "JIRA Ticket ID: $JIRA_TICKET_ID"
echo "Epic ID: $EPIC_ID"
echo "Story Branch: $STORY_BRANCH"
echo "Git Repository: ${GIT_REPO:-Not provided}"
echo "Existing App BRD: $EXISTING_APP_BRD"
echo "Existing App Architecture: $EXISTING_APP_ARCH"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Context Directories: $CONTEXT_DIRS"
echo "Policy File: $POLICY_FILE"
echo ""
echo "NOTE: This agent assumes story implementation"
echo "      is already complete on branch: $STORY_BRANCH"
echo "=========================================="
echo ""

# Navigate to workspace
cd "$WORKSPACE_ROOT"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
	echo "Error: Not a git repository at $WORKSPACE_ROOT"
	exit 1
fi

# Checkout the story branch (assumes implementation is already done)
echo "Checking out story branch: $STORY_BRANCH"
git checkout "$STORY_BRANCH" || {
	echo "Error: Failed to checkout branch $STORY_BRANCH"
	echo "Please ensure the branch exists and contains the story implementation"
	exit 1
}

# Pull latest changes
echo "Pulling latest changes from remote..."
git pull origin "$STORY_BRANCH" || echo "Warning: Could not pull from remote"

echo ""

# Create artifacts directory structure
ARTIFACTS_DIR="sdlc-artifacts"
UNIT_TESTS_ARTIFACTS_DIR="$ARTIFACTS_DIR/unit-tests"
mkdir -p "$UNIT_TESTS_ARTIFACTS_DIR"

echo "Artifacts will be saved to: $UNIT_TESTS_ARTIFACTS_DIR"
echo ""

# Verify Story ID is actually a Story
echo "Verifying Story ID: $JIRA_TICKET_ID"
if ! verify_issue_type "$JIRA_TICKET_ID" "Story"; then
	echo "Error: $JIRA_TICKET_ID is not a valid Story"
	exit 1
fi

echo ""

# Fetch Story details from JIRA
echo "Fetching Story details from JIRA..."
STORY_JSON=$(get_jira_issue "$JIRA_TICKET_ID")
if [ $? -ne 0 ]; then
	echo "Error: Failed to fetch Story from JIRA"
	exit 1
fi

STORY_TITLE=$(echo "$STORY_JSON" | jq -r '.fields.summary // empty')
STORY_DESCRIPTION_ADF=$(echo "$STORY_JSON" | jq -c '.fields.description // {}')
STORY_PRIORITY=$(echo "$STORY_JSON" | jq -r '.fields.priority.name // "Medium"')

echo "Story: $JIRA_TICKET_ID - $STORY_TITLE"
echo "Priority: $STORY_PRIORITY"
echo ""

# Derive Epic ID from Story's parent
echo "Deriving Epic from Story's parent..."
EPIC_ID=$(echo "$STORY_JSON" | jq -r '.fields.parent.key // empty')

if [ -z "$EPIC_ID" ]; then
	echo "Error: Story $JIRA_TICKET_ID does not have a parent Epic"
	echo "Please ensure the Story is linked to an Epic in JIRA"
	exit 1
fi

echo "Found parent Epic: $EPIC_ID"
echo ""

# Verify parent is actually an Epic
echo "Verifying parent is an Epic..."
if ! verify_issue_type "$EPIC_ID" "Epic"; then
	echo "Error: Parent $EPIC_ID is not a valid Epic"
	exit 1
fi

echo ""

# Fetch Epic details from JIRA
echo "Fetching Epic details from JIRA..."
EPIC_JSON=$(get_jira_issue "$EPIC_ID")
if [ $? -ne 0 ]; then
	echo "Error: Failed to fetch Epic from JIRA"
	exit 1
fi

EPIC_TITLE=$(echo "$EPIC_JSON" | jq -r '.fields.summary // empty')
EPIC_DESCRIPTION_ADF=$(echo "$EPIC_JSON" | jq -c '.fields.description // {}')

echo "Epic: $EPIC_ID - $EPIC_TITLE"
echo ""

# Load policy file
if [ ! -f "$POLICY_FILE" ]; then
	echo "Error: Policy file not found: $POLICY_FILE"
	exit 1
fi

POLICY_CONTENT=$(cat "$POLICY_FILE")

# Convert ADF to markdown for better readability in prompt
EPIC_DESCRIPTION_MD=$(echo "$EPIC_DESCRIPTION_ADF" | adf2md 2>/dev/null || echo "$EPIC_DESCRIPTION_ADF")
STORY_DESCRIPTION_MD=$(echo "$STORY_DESCRIPTION_ADF" | adf2md 2>/dev/null || echo "$STORY_DESCRIPTION_ADF")

# Build unit test plan generation instruction
UNIT_TEST_PLAN_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:

EPIC:
Epic ID: $EPIC_ID
Title: $EPIC_TITLE
Description:
$EPIC_DESCRIPTION_MD

USER STORY:
Story ID: $JIRA_TICKET_ID
Title: $STORY_TITLE
Priority: $STORY_PRIORITY
Description:
$STORY_DESCRIPTION_MD

IMPLEMENTATION:
- Story Branch: $STORY_BRANCH (contains completed implementation)
- Existing Application BRD: $EXISTING_APP_BRD
- Existing Application Architecture: $EXISTING_APP_ARCH
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS
- Output Directory: $UNIT_TESTS_ARTIFACTS_DIR/

Create the following markdown files in $UNIT_TESTS_ARTIFACTS_DIR/:
unit-test-plan.md - A test plan which briefly describes the tests to be written i.e., cases we're going to cover:
  - Assessment of whether UTs are needed (and why/why not)
  - Test cases, scenarios, and expected outcomes (if applicable)
  - Existing test patterns to follow

Begin unit test plan generation now."

# Clean up existing artifacts to start with a clean slate
# In publish-only mode, preserve existing artifacts; otherwise start fresh
echo ""
echo "=========================================="
if [ "$PUBLISH_ONLY" = true ]; then
	echo "Publish-Only Mode: Using Existing Artifacts"
else
	echo "Cleaning Up Existing Artifacts"
fi
echo "=========================================="

if [ "$PUBLISH_ONLY" = true ]; then
	echo "Publish-only mode: Using existing test plan at: $UNIT_TESTS_ARTIFACTS_DIR"
	if [ ! -d "$UNIT_TESTS_ARTIFACTS_DIR" ]; then
		echo "Error: Artifacts directory not found: $UNIT_TESTS_ARTIFACTS_DIR"
		echo "Run with --generate-only first to create test plan"
		exit 1
	fi
	if [ ! -f "$UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md" ]; then
		echo "Error: Test plan not found: $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
		echo "Run with --generate-only first to create test plan"
		exit 1
	fi
	echo "✓ Found existing test plan"
else
	# Start fresh for generation
	if [ -d "$UNIT_TESTS_ARTIFACTS_DIR" ]; then
		echo "Found existing artifacts directory: $UNIT_TESTS_ARTIFACTS_DIR"
		echo "Removing old artifacts to start fresh..."

		# Show what will be deleted
		if [ "$(ls -A "$UNIT_TESTS_ARTIFACTS_DIR" 2>/dev/null)" ]; then
			echo ""
			echo "Files to be removed:"
			ls -la "$UNIT_TESTS_ARTIFACTS_DIR"
			echo ""
		fi

		# Remove the directory
		rm -rf "$UNIT_TESTS_ARTIFACTS_DIR"
		echo "✓ Old artifacts removed"
	else
		echo "No existing artifacts found - starting fresh"
	fi

	# Create fresh artifacts directory
	mkdir -p "$UNIT_TESTS_ARTIFACTS_DIR"
	echo "✓ Created clean artifacts directory: $UNIT_TESTS_ARTIFACTS_DIR"
fi
echo ""

# Skip Phase 1 if in publish-only mode
if [ "$PUBLISH_ONLY" = true ]; then
	echo "=========================================="
	echo "Skipping Phase 1 (publish-only mode)"
	echo "=========================================="
	echo "Using existing test plan from: $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
	echo ""
else
	# Run Auggie agent to generate test plans (PHASE 1)
	echo "=========================================="
	echo "PHASE 1: Generating Unit Test Plan"
	echo "=========================================="
	echo "Running Auggie agent to analyze implementation and create test plan..."
	echo ""

	auggie -p \
		--workspace-root "$WORKSPACE_ROOT" \
		"$UNIT_TEST_PLAN_INSTRUCTION"

	# Check if test plans were generated
	if [ ! -f "$UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md" ]; then
		echo "Error: unit-test-plan.md not found"
		echo "Expected location: $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
		exit 1
	fi

	echo ""
	echo "=========================================="
	echo "Unit Test Plan Generated!"
	echo "=========================================="
	echo "Location: $UNIT_TESTS_ARTIFACTS_DIR/"
	echo ""
	echo "Generated files:"
	ls -la "$UNIT_TESTS_ARTIFACTS_DIR/"
	echo "=========================================="

	# Display test plan
	echo ""
	echo "UNIT TEST PLAN:"
	echo "=========================================="
	cat "$UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
	echo "=========================================="
fi

# Exit early if in generate-only mode
if [ "$GENERATE_ONLY" = true ]; then
	echo ""
	echo "=========================================="
	echo "Generate-only mode: Test plan created successfully"
	echo "=========================================="
	echo "Test plan saved to: $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
	echo ""
	echo "Next steps:"
	echo "1. Review the generated test plan"
	echo "2. Run with --publish-only to generate test code"
	echo ""
	exit 0
fi

# Pause for manual approval (only if not in publish-only mode)
if [ "$PUBLISH_ONLY" != true ]; then
	echo ""
	echo "=========================================="
	echo "REVIEW REQUIRED - Unit Test Plan Generated"
	echo "=========================================="
	echo ""
	echo "📄 Test Plan Location:"
	echo "   $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
	echo ""
	echo "Please review the test plan to verify:"
	echo "  ✓ Applicability assessment is correct"
	echo "  ✓ Test scenarios cover all requirements"
	echo "  ✓ Mocking strategy is appropriate"
	echo "  ✓ Test files and structure follow conventions"
	echo ""
	echo "You can:"
	echo "  • Open the file in your editor to review"
	echo "  • Modify the plan if needed"
	echo "  • Approve to proceed with test code generation"
	echo ""

	# Approval workflow between Phase 1 and Phase 2
	# Interactive mode only (non-interactive without flags would have exited in generate-only above)
	if [ "$INTERACTIVE_MODE" = true ]; then
		# Interactive mode: ask for approval
		read -p "Do you approve this test plan and want to proceed with Phase 2 (code generation)? (y/n): " APPROVAL

		if [ "$APPROVAL" != "y" ] && [ "$APPROVAL" != "Y" ]; then
			echo ""
			echo "Unit test generation paused."
			echo "You can review and modify the test plan at:"
			echo "  $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
			echo ""
			echo "To resume, re-run this script with the same parameters."
			exit 0
		fi
	fi
fi

# Generate actual test code (PHASE 2)
echo ""
echo "=========================================="
echo "PHASE 2: Generating Unit Test Code"
echo "=========================================="

TEST_CODE_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:

EPIC:
Epic ID: $EPIC_ID
Title: $EPIC_TITLE
Description:
$EPIC_DESCRIPTION_MD

USER STORY:
Story ID: $JIRA_TICKET_ID
Title: $STORY_TITLE
Priority: $STORY_PRIORITY
Description:
$STORY_DESCRIPTION_MD

IMPLEMENTATION:
- Story Branch: $STORY_BRANCH (contains completed implementation)
- Approved Unit Test Plan: $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md
- Existing Application BRD: $EXISTING_APP_BRD
- Existing Application Architecture: $EXISTING_APP_ARCH
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS

Generate actual unit test code files based on the approved test plan at $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md.
Place test files in the appropriate test directories following codebase conventions.
Do not alter the approved test plan.
Begin unit test code generation now."

echo "Running Auggie agent to generate unit test code..."
echo ""

auggie -p \
	--workspace-root "$WORKSPACE_ROOT" \
	"$TEST_CODE_INSTRUCTION"

echo ""
echo "=========================================="
echo "Unit Test Code Generation Complete!"
echo "=========================================="

# Commit and push unit tests to the story branch
echo ""
echo "=========================================="
echo "Committing Unit Tests to Story Branch"
echo "=========================================="

# Navigate to workspace
cd "$WORKSPACE_ROOT"

# Verify we're on the story branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$STORY_BRANCH" ]; then
	echo "Warning: Current branch ($CURRENT_BRANCH) doesn't match story branch ($STORY_BRANCH)"
	echo "Checking out $STORY_BRANCH..."
	git checkout "$STORY_BRANCH"
fi

# Stage all changes (unit tests only)
echo "Staging unit test changes..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
	echo ""
	echo "=========================================="
	echo "No unit test changes to commit"
	echo "=========================================="
	echo "This may indicate that:"
	echo "  1. Unit tests were not applicable for this implementation"
	echo "  2. Unit tests already exist and no new tests were needed"
	echo "  3. The test plan indicated tests were not needed"
	exit 0
fi

# Commit changes with story title as commit message
echo "Committing unit tests..."
COMMIT_MESSAGE="test($JIRA_TICKET_ID): Add unit tests"

git commit -m "$COMMIT_MESSAGE" || {
	echo "Error: Failed to commit changes"
	exit 1
}

# Push to remote
echo "Pushing unit tests to remote branch: $STORY_BRANCH"
git push origin "$STORY_BRANCH" || {
	echo "Error: Failed to push to remote"
	echo "You may need to push manually: git push origin $STORY_BRANCH"
	exit 1
}

echo ""
echo "=========================================="
echo "Unit Tests Committed Successfully!"
echo "=========================================="
echo "Story: $JIRA_TICKET_ID - $STORY_TITLE"
echo "Branch: $STORY_BRANCH"
echo "Unit tests have been added to the story implementation branch"
echo ""
echo "Next Steps:"
echo "  1. Run the unit tests to verify they pass"
echo "  2. Review test coverage"
echo "  3. The unit tests will be included in the story's PR"
echo ""
echo "Artifacts:"
echo "  - Test Plan: $UNIT_TESTS_ARTIFACTS_DIR/unit-test-plan.md"
echo "=========================================="

exit 0
