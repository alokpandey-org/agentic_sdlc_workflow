#!/bin/bash

# Agent 2: Implementation Generator
# This is a generic agent that generates code implementation for a user story
# It discovers context from the codebase and generates a complete implementation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source JIRA utilities
source "$SCRIPT_DIR/jira-utils.sh"

# Default values
WORKSPACE_ROOT=""
JIRA_TICKET_ID=""
EPIC_ID=""
EXISTING_APP_BRD=""
EXISTING_APP_ARCH=""
NEW_BRD=""
GIT_REPO=""
BASE_BRANCH="main"
CONTEXT_DIRS="src,docs"
POLICY_FILE="$SCRIPT_DIR/policies/implementation.policy.md"

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--workspace-root)
		WORKSPACE_ROOT="$2"
		shift 2
		;;
	--jira-ticket-id)
		JIRA_TICKET_ID="$2"
		shift 2
		;;
	--epic-id)
		EPIC_ID="$2"
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
	--new-brd)
		NEW_BRD="$2"
		shift 2
		;;
	--git-repo)
		GIT_REPO="$2"
		shift 2
		;;
	--base-branch)
		BASE_BRANCH="$2"
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
	*)
		echo "Unknown option: $1"
		echo "Usage: $0 --workspace-root PATH --jira-ticket-id ID --epic-id ID --existing-app-brd PATH --existing-app-arch PATH --new-brd PATH [--git-repo URL] [--base-branch BRANCH] [--context-dirs DIRS] [--policy-file FILE]"
		exit 1
		;;
	esac
done

# Validate required parameters
if [ -z "$WORKSPACE_ROOT" ]; then
	echo "Error: --workspace-root is required"
	exit 1
fi

if [ -z "$JIRA_TICKET_ID" ]; then
	echo "Error: --jira-ticket-id is required"
	exit 1
fi

if [ -z "$EPIC_ID" ]; then
	echo "Error: --epic-id is required"
	exit 1
fi

if [ -z "$EXISTING_APP_BRD" ]; then
	echo "Error: --existing-app-brd is required"
	exit 1
fi

if [ -z "$EXISTING_APP_ARCH" ]; then
	echo "Error: --existing-app-arch is required"
	exit 1
fi

if [ -z "$NEW_BRD" ]; then
	echo "Error: --new-brd is required"
	exit 1
fi

# Validate workspace directory exists
if [ ! -d "$WORKSPACE_ROOT" ]; then
	echo "Error: Workspace directory not found: $WORKSPACE_ROOT"
	exit 1
fi

# Validate BRD and architecture files exist
if [ ! -f "$EXISTING_APP_BRD" ]; then
	echo "Error: Existing application BRD file not found: $EXISTING_APP_BRD"
	exit 1
fi

if [ ! -f "$EXISTING_APP_ARCH" ]; then
	echo "Error: Existing application architecture file not found: $EXISTING_APP_ARCH"
	exit 1
fi

if [ ! -f "$NEW_BRD" ]; then
	echo "Error: New BRD file not found: $NEW_BRD"
	exit 1
fi

# Clone Git repository if provided (always delete and re-clone for clean state)
if [ -n "$GIT_REPO" ]; then
	# Extract repo name from URL (last part without .git)
	REPO_NAME=$(basename "$GIT_REPO" .git)
	REPO_DIR="$WORKSPACE_ROOT/$REPO_NAME"

	# Delete existing repo directory if it exists
	if [ -d "$REPO_DIR" ]; then
		echo "Deleting existing repository directory: $REPO_DIR"
		rm -rf "$REPO_DIR"
	fi

	# Clone fresh copy
	echo "Cloning repository from $GIT_REPO to $REPO_DIR..."
	git clone "$GIT_REPO" "$REPO_DIR"
	echo "Repository cloned successfully."
	echo ""

	# Update workspace root to the cloned repository
	WORKSPACE_ROOT="$REPO_DIR"
fi

# Navigate to workspace
cd "$WORKSPACE_ROOT"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
	echo "Error: Not a git repository: $WORKSPACE_ROOT"
	echo "Please provide a valid git repository via --git-repo or ensure workspace is a git repo"
	exit 1
fi

# Fetch latest changes from remote
echo "Fetching latest changes from remote..."
git fetch origin

# Create branch name from JIRA ticket ID
BRANCH_NAME="story/${JIRA_TICKET_ID}"

# Check if story branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
	echo "Branch $BRANCH_NAME already exists locally, checking out..."
	git checkout "$BRANCH_NAME"
else
	# Checkout base branch first
	echo "Checking out base branch: $BASE_BRANCH"
	git checkout "$BASE_BRANCH" 2>/dev/null || {
		# Try to checkout from remote if not available locally
		git checkout -b "$BASE_BRANCH" "origin/$BASE_BRANCH" 2>/dev/null || {
			echo "Error: Base branch $BASE_BRANCH not found locally or on remote"
			exit 1
		}
	}

	# Pull latest changes from base branch
	echo "Pulling latest changes from $BASE_BRANCH..."
	git pull origin "$BASE_BRANCH" || echo "Warning: Could not pull from $BASE_BRANCH"

	# Create new story branch from base branch
	echo "Creating new branch $BRANCH_NAME from $BASE_BRANCH..."
	git checkout -b "$BRANCH_NAME"
fi

echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo ""

# Always store SDLC artifacts under the workspace root
OUTPUT_DIR="$WORKSPACE_ROOT/sdlc-artifacts"
IMPLEMENTATION_DIR="$OUTPUT_DIR/implementation"

# Pre-check: Clean output directory if it exists
if [ -d "$IMPLEMENTATION_DIR" ]; then
	echo "Cleaning existing implementation directory: $IMPLEMENTATION_DIR"
	rm -rf "$IMPLEMENTATION_DIR"
fi

# Create output directory
mkdir -p "$IMPLEMENTATION_DIR"

echo "=========================================="
echo "Agent 2: Implementation Generator"
echo "=========================================="
echo "Git Repository: ${GIT_REPO:-Not provided}"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Base Branch: $BASE_BRANCH"
echo "Story Branch: $BRANCH_NAME"
echo "JIRA Ticket ID: $JIRA_TICKET_ID"
echo "Epic ID: $EPIC_ID"
echo "Existing App BRD Path: $EXISTING_APP_BRD"
echo "Existing App Architecture Path: $EXISTING_APP_ARCH"
echo "New BRD Path: $NEW_BRD"
echo "Context Directories: $CONTEXT_DIRS"
echo "Output Directory: $OUTPUT_DIR"
echo "Policy File: $POLICY_FILE"
echo ""

# Test JIRA connection
test_jira_connection

echo ""

# Verify Epic ID is actually an Epic
echo "Verifying Epic ID: $EPIC_ID"
if ! verify_issue_type "$EPIC_ID" "Epic"; then
	echo "Error: $EPIC_ID is not a valid Epic"
	exit 1
fi

echo ""

# Verify Story ID is actually a Story
echo "Verifying Story ID: $JIRA_TICKET_ID"
if ! verify_issue_type "$JIRA_TICKET_ID" "Story"; then
	echo "Error: $JIRA_TICKET_ID is not a valid Story"
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

# Verify story is linked to the epic
STORY_EPIC_KEY=$(echo "$STORY_JSON" | jq -r '.fields.parent.key // empty')
if [ -n "$STORY_EPIC_KEY" ] && [ "$STORY_EPIC_KEY" != "$EPIC_ID" ]; then
	echo "Error: Story $JIRA_TICKET_ID is linked to Epic $STORY_EPIC_KEY, but you specified Epic $EPIC_ID"
	exit 1
fi

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

# Build implementation instruction similar to epic agent
IMPLEMENTATION_INSTRUCTION="$POLICY_CONTENT

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

DOCUMENTS:
- New Feature BRD Path: $NEW_BRD
- Existing Application BRD Path: $EXISTING_APP_BRD
- Existing Application Architecture Path: $EXISTING_APP_ARCH

WORKSPACE:
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS
- Output Directory: $IMPLEMENTATION_DIR/
- Base Branch: $BASE_BRANCH (branch to merge into)
- Story Branch: $BRANCH_NAME (current working branch)

IMPORTANT: Create the following files:
1. changes-summary.md - Implementation summary with all changes
2. pr.json - GitHub PR metadata in JSON format (for use with gh CLI)
   - Use branch name: $BRANCH_NAME for the 'head' field
   - Use branch name: $BASE_BRANCH for the 'base' field
   - This ensures the PR merges the story branch into the correct base branch

Begin implementation now."

# Run Auggie agent
echo "Running Auggie agent to generate implementation..."
echo ""

auggie -p \
	--workspace-root "$WORKSPACE_ROOT" \
	"$IMPLEMENTATION_INSTRUCTION"

# Check if required files were generated
if [ ! -f "$IMPLEMENTATION_DIR/changes-summary.md" ] || [ ! -f "$IMPLEMENTATION_DIR/pr.json" ]; then
	echo "Error: Expected output files not found."
	echo "Please ensure changes-summary.md and pr.json are created in $IMPLEMENTATION_DIR/"
	exit 1
fi

echo ""
echo "=========================================="
echo "Implementation Generated"
echo "=========================================="
echo "Output location: $IMPLEMENTATION_DIR/"
echo ""
echo "Generated files:"
echo "- changes-summary.md"
echo "- pr.json"
echo ""
echo "Please review the generated implementation at: $IMPLEMENTATION_DIR/"
echo ""

# Approval workflow
APPROVED=false
while [ "$APPROVED" = false ]; do
	read -p "Approve and create Pull Request in GitHub? (y/n): " approval

	case $approval in
	y | Y | yes | Yes | YES)
		APPROVED=true
		;;
	n | N | no | No | NO)
		echo "Implementation not approved. Exiting."
		exit 0
		;;
	*)
		echo "Invalid input. Please enter 'y' or 'n'."
		;;
	esac
done

echo ""
echo "=========================================="
echo "Creating Pull Request in GitHub"
echo "=========================================="

# We're already in the workspace and on the correct branch
# Extract PR details from pr.json
PR_TITLE=$(jq -r '.title' "$IMPLEMENTATION_DIR/pr.json")
PR_BODY=$(jq -r '.body' "$IMPLEMENTATION_DIR/pr.json")
PR_BASE=$(jq -r '.base' "$IMPLEMENTATION_DIR/pr.json")
PR_HEAD=$(jq -r '.head' "$IMPLEMENTATION_DIR/pr.json")

# Verify we're on the correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
	echo "Warning: Current branch ($CURRENT_BRANCH) doesn't match expected branch ($BRANCH_NAME)"
	echo "Checking out $BRANCH_NAME..."
	git checkout "$BRANCH_NAME"
fi

# Stage all changes
echo "Staging changes..."
git add .

# Commit changes
echo "Committing changes..."
git commit -m "$PR_TITLE" -m "$PR_BODY" || echo "No changes to commit"

# Push branch to remote
echo "Pushing branch $BRANCH_NAME to remote..."
git push -u origin "$BRANCH_NAME" || {
	echo "Error: Failed to push branch to remote"
	exit 1
}

# Create PR using GitHub CLI
echo "Creating pull request..."
if command -v gh &>/dev/null; then
	gh pr create \
		--title "$PR_TITLE" \
		--body "$PR_BODY" \
		--base "$PR_BASE" \
		--head "$BRANCH_NAME" || {
		echo "Error: Failed to create PR. You may need to create it manually."
		echo "Branch pushed: $BRANCH_NAME"
	}

	# Get PR details
	PR_NUMBER=$(gh pr list --head "$BRANCH_NAME" --json number --jq '.[0].number')
	PR_URL=$(gh pr list --head "$BRANCH_NAME" --json url --jq '.[0].url')

	if [ -n "$PR_NUMBER" ]; then
		echo ""
		echo "=========================================="
		echo "Pull Request Created Successfully!"
		echo "=========================================="
		echo "PR Number: #$PR_NUMBER"
		echo "Branch: $BRANCH_NAME"
		echo ""
		echo "PR URL: $PR_URL"
		echo "=========================================="

		# Save PR number and URL for next agents
		echo "$PR_NUMBER" >"$IMPLEMENTATION_DIR/pr-number.txt"
		echo "$PR_URL" >"$IMPLEMENTATION_DIR/pr-url.txt"

		echo ""
		echo "View Pull Request: $PR_URL"
	fi
else
	echo "Warning: GitHub CLI (gh) not found. Please install it to create PRs automatically."
	echo "Branch pushed: $BRANCH_NAME"
	echo "Please create the PR manually at your repository."
fi

exit 0
