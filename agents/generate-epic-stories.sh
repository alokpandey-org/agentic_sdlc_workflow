#!/bin/bash

# Agent 1: Epic & User Stories Generator
# This is a generic agent that generates an epic and user stories from a BRD document
# It discovers context from the codebase and existing documentation
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
BRD_PATH=""
EXISTING_APP_BRD="${DEMO_EXISTING_APP_BRD:-}"
EXISTING_APP_ARCH="${DEMO_EXISTING_APP_ARCH:-}"
WORKSPACE_ROOT="${DEMO_WORKSPACE_ROOT:-.}"
GIT_REPO="${DEMO_GIT_REPO:-}"
CONTEXT_DIRS=""
OUTPUT_DIR="sdlc-artifacts"
INTERACTIVE_MODE=false
POLICY_FILE="$SCRIPT_DIR/policies/epic-stories-generation.policy.md"

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-i | --interactive)
		INTERACTIVE_MODE=true
		shift
		;;
	--brd-path)
		BRD_PATH="$2"
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
	--policy-file)
		POLICY_FILE="$2"
		shift 2
		;;
	*)
		echo "Unknown option: $1"
		echo "Usage: $0 [-i|--interactive] [--brd-path PATH] [--existing-app-brd PATH] [--existing-app-arch PATH] [--workspace-root PATH] [--context-dirs DIRS] [--policy-file FILE]"
		exit 1
		;;
	esac
done

# Interactive mode: prompt for inputs
if [ "$INTERACTIVE_MODE" = true ]; then
	echo "=========================================="
	echo "Interactive Mode: Epic & Stories Generator"
	echo "=========================================="
	echo ""

	# Prompt for Git repository
	if [ -n "$GIT_REPO" ]; then
		read -p "Enter Git repository URL [default: $GIT_REPO]: " input
		GIT_REPO="${input:-$GIT_REPO}"
	else
		read -p "Enter Git repository URL: " GIT_REPO
	fi

	# Prompt for workspace root
	if [ -n "$WORKSPACE_ROOT" ]; then
		read -p "Enter workspace root directory [default: $WORKSPACE_ROOT]: " input
		WORKSPACE_ROOT="${input:-$WORKSPACE_ROOT}"
	else
		read -p "Enter workspace root directory [default: .]: " input
		WORKSPACE_ROOT="${input:-.}"
	fi

	# Prompt for existing application BRD (optional)
	if [ -n "$EXISTING_APP_BRD" ]; then
		read -p "Enter existing application BRD document path [default: $EXISTING_APP_BRD] (press Enter to accept or skip): " input
		EXISTING_APP_BRD="${input:-$EXISTING_APP_BRD}"
	else
		read -p "Enter existing application BRD document path (optional, press Enter to skip): " EXISTING_APP_BRD
	fi

	# Prompt for existing application architecture (optional)
	if [ -n "$EXISTING_APP_ARCH" ]; then
		read -p "Enter existing application architecture documentation path [default: $EXISTING_APP_ARCH] (press Enter to accept or skip): " input
		EXISTING_APP_ARCH="${input:-$EXISTING_APP_ARCH}"
	else
		read -p "Enter existing application architecture documentation path (optional, press Enter to skip): " EXISTING_APP_ARCH
	fi

	# Prompt for BRD path
	if [ -z "$BRD_PATH" ]; then
		read -p "Enter new feature BRD document path: " BRD_PATH
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
	BRD_PATH="${BRD_PATH:-${ENV_BRD_PATH}}"
	EXISTING_APP_BRD="${EXISTING_APP_BRD:-${ENV_EXISTING_APP_BRD}}"
	EXISTING_APP_ARCH="${EXISTING_APP_ARCH:-${ENV_EXISTING_APP_ARCH}}"
	WORKSPACE_ROOT="${WORKSPACE_ROOT:-${ENV_WORKSPACE_ROOT:-.}}"
	CONTEXT_DIRS="${CONTEXT_DIRS:-${ENV_CONTEXT_DIRS:-src,docs}}"
	POLICY_FILE="${POLICY_FILE:-${ENV_POLICY_FILE:-$SCRIPT_DIR/policies/epic-stories-generation.policy.md}}"
fi

# Always store SDLC artifacts under the workspace root
OUTPUT_DIR="$WORKSPACE_ROOT/sdlc-artifacts"
EPIC_STORIES_DIR="$OUTPUT_DIR/epic-stories"

# Validate required parameters
if [ -z "$BRD_PATH" ]; then
	echo "Error: New feature BRD path is required"
	echo "Provide via --brd-path argument, interactive mode (-i), or ENV_BRD_PATH environment variable"
	exit 1
fi

# Validate BRD file exists
if [ ! -f "$BRD_PATH" ]; then
	echo "Error: New feature BRD file not found: $BRD_PATH"
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

# Create output directory for epic & stories artifacts (start fresh each run)
if [ -d "$EPIC_STORIES_DIR" ]; then
	echo "Clearing existing epic & stories artifacts at: $EPIC_STORIES_DIR"
	rm -rf "$EPIC_STORIES_DIR"
fi
mkdir -p "$EPIC_STORIES_DIR"

echo "=========================================="
echo "Agent 1: Epic & User Stories Generator"
echo "=========================================="
echo "Mode: $([ "$INTERACTIVE_MODE" = true ] && echo "Interactive" || echo "Non-Interactive")"
echo "Git Repository: ${GIT_REPO:-Not provided}"
echo "New Feature BRD Path: $BRD_PATH"
echo "Existing App BRD Path: ${EXISTING_APP_BRD:-Not provided}"
echo "Existing App Architecture Path: ${EXISTING_APP_ARCH:-Not provided}"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Context Directories: $CONTEXT_DIRS"
echo "Output Directory: $OUTPUT_DIR"
echo "Policy File: $POLICY_FILE"
echo ""

# Load policy file
if [ ! -f "$POLICY_FILE" ]; then
	echo "Error: Policy file not found: $POLICY_FILE"
	exit 1
fi

POLICY_CONTENT=$(cat "$POLICY_FILE")

# Build context discovery instruction
CONTEXT_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:
- New Feature BRD Document Path: $BRD_PATH"

if [ -n "$EXISTING_APP_BRD" ]; then
	CONTEXT_INSTRUCTION="$CONTEXT_INSTRUCTION
- Existing Application BRD Path: $EXISTING_APP_BRD"
fi

if [ -n "$EXISTING_APP_ARCH" ]; then
	CONTEXT_INSTRUCTION="$CONTEXT_INSTRUCTION
- Existing Application Architecture Path: $EXISTING_APP_ARCH"
fi

CONTEXT_INSTRUCTION="$CONTEXT_INSTRUCTION
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS
- Output Directory: $EPIC_STORIES_DIR/

IMPORTANT: Create the following files in JSON format:
1. epic.json - Epic with title and description (markdown) fields
2. stories.json - Array of stories with title, description (markdown), and priority fields
3. summary.md - Human-readable summary

Begin analysis and generation now."

# Run Auggie agent
echo "Running Auggie agent to generate Epic and User Stories..."
echo ""

auggie -p \
	--workspace-root "$WORKSPACE_ROOT" \
	"$CONTEXT_INSTRUCTION"

# Check if JSON files were generated
if [ ! -f "$EPIC_STORIES_DIR/epic.json" ] || [ ! -f "$EPIC_STORIES_DIR/stories.json" ]; then
	echo "Error: Expected JSON files not found."
	echo "Please ensure epic.json and stories.json are created in $EPIC_STORIES_DIR/"
	exit 1
fi

echo ""
echo "=========================================="
echo "Epic and User Stories Generated (JSON)"
echo "=========================================="
echo "Output location: $EPIC_STORIES_DIR/"
echo ""

# Convert JSON to Markdown for user review
echo "Converting JSON to Markdown for review..."
echo ""

# Generate epic.md from epic.json
EPIC_TITLE=$(jq -r '.title' "$EPIC_STORIES_DIR/epic.json")
EPIC_DESC=$(jq -r '.description' "$EPIC_STORIES_DIR/epic.json")

cat >"$EPIC_STORIES_DIR/epic.md" <<EOF
# $EPIC_TITLE

$EPIC_DESC
EOF

echo "Created epic.md for review"

# Generate stories.md from stories.json
echo "# User Stories" >"$EPIC_STORIES_DIR/stories.md"
echo "" >>"$EPIC_STORIES_DIR/stories.md"

STORY_COUNT=$(jq 'length' "$EPIC_STORIES_DIR/stories.json")
echo "Total Stories: $STORY_COUNT" >>"$EPIC_STORIES_DIR/stories.md"
echo "" >>"$EPIC_STORIES_DIR/stories.md"

# Iterate through stories and create markdown
for i in $(seq 0 $((STORY_COUNT - 1))); do
	STORY_NUM=$((i + 1))
	STORY_TITLE=$(jq -r ".[$i].title" "$EPIC_STORIES_DIR/stories.json")
	STORY_DESC=$(jq -r ".[$i].description" "$EPIC_STORIES_DIR/stories.json")
	STORY_PRIORITY=$(jq -r ".[$i].priority" "$EPIC_STORIES_DIR/stories.json")

	cat >>"$EPIC_STORIES_DIR/stories.md" <<EOF
---

## Story $STORY_NUM: $STORY_TITLE

**Priority:** $STORY_PRIORITY

$STORY_DESC

EOF
done

echo "Created stories.md for review"
echo ""

echo "=========================================="
echo "Review Files Generated"
echo "=========================================="
echo "Epic: $EPIC_STORIES_DIR/epic.md"
echo "Stories: $EPIC_STORIES_DIR/stories.md"
echo "Summary: $EPIC_STORIES_DIR/summary.md"
echo ""
echo "Please review the generated epic and stories at: $EPIC_STORIES_DIR/"
echo ""

# Approval workflow
APPROVED=false
while [ "$APPROVED" = false ]; do
	read -p "Approve and create in JIRA? (y/n): " approval

	case $approval in
	y | Y | yes | Yes | YES)
		APPROVED=true
		;;
	n | N | no | No | NO)
		echo ""
		echo "Epic and stories not approved."
		echo "Please adjust the prompt or BRD and re-run the script."
		echo ""
		read -p "Do you want to re-run with adjusted prompt? (y/n): " rerun

		if [[ "$rerun" =~ ^[Yy] ]]; then
			echo ""
			echo "Re-running agent with adjusted inputs..."
			echo "Please modify the BRD or policy file and run the script again."
			exit 0
		else
			echo "Exiting without creating JIRA items."
			exit 0
		fi
		;;
	*)
		echo "Invalid input. Please enter 'y' or 'n'."
		;;
	esac
done

echo ""
echo "=========================================="
echo "Creating Epic and Stories in JIRA"
echo "=========================================="
echo ""

# Check for JIRA credentials
if [ -z "$JIRA_TOKEN" ]; then
	echo "Error: JIRA_TOKEN environment variable not set"
	exit 1
fi

# Test JIRA connection
if ! test_jira_connection; then
	echo "Error: Failed to connect to JIRA"
	exit 1
fi

# Verify project access
if ! get_jira_project "$JIRA_PROJECT_KEY"; then
	echo "Error: Cannot access JIRA project $JIRA_PROJECT_KEY"
	exit 1
fi

echo ""

# Extract epic details from epic.json
if [ -f "$EPIC_STORIES_DIR/epic.json" ]; then
	EPIC_TITLE=$(jq -r '.title' "$EPIC_STORIES_DIR/epic.json")
	EPIC_DESCRIPTION=$(jq -r '.description' "$EPIC_STORIES_DIR/epic.json")

	# Convert markdown newlines to spaces for JIRA (simple text format)
	EPIC_DESCRIPTION=$(echo "$EPIC_DESCRIPTION" | tr '\n' ' ' | cut -c1-1000)
else
	echo "Error: epic.json not found"
	exit 1
fi

# Create epic in JIRA
echo "Creating Epic: $EPIC_TITLE"
EPIC_KEY=$(create_jira_epic "$EPIC_TITLE" "$EPIC_DESCRIPTION")

if [ -z "$EPIC_KEY" ]; then
	echo "Error: Failed to create epic in JIRA"
	exit 1
fi

echo "Epic created: $JIRA_BASE_URL/browse/$EPIC_KEY"
echo ""

# Parse and create user stories from stories.json
if [ -f "$EPIC_STORIES_DIR/stories.json" ]; then
	CREATED_STORY_COUNT=0
	STORY_COUNT=$(jq 'length' "$EPIC_STORIES_DIR/stories.json")

	echo "Creating $STORY_COUNT stories in JIRA..."
	echo ""

	# Iterate through stories array
	for i in $(seq 0 $((STORY_COUNT - 1))); do
		STORY_NUM=$((i + 1))
		STORY_TITLE=$(jq -r ".[$i].title" "$EPIC_STORIES_DIR/stories.json")
		STORY_DESC=$(jq -r ".[$i].description" "$EPIC_STORIES_DIR/stories.json")
		STORY_PRIORITY=$(jq -r ".[$i].priority" "$EPIC_STORIES_DIR/stories.json")

		# Convert markdown newlines to spaces for JIRA (simple text format)
		STORY_DESC=$(echo "$STORY_DESC" | tr '\n' ' ' | cut -c1-2000)

		echo "Creating Story $STORY_NUM: $STORY_TITLE (Priority: $STORY_PRIORITY)"
		STORY_KEY=$(create_jira_story "$STORY_TITLE" "$STORY_DESC" "$EPIC_KEY" "$STORY_PRIORITY")

		if [ -n "$STORY_KEY" ]; then
			echo "Story created: $JIRA_BASE_URL/browse/$STORY_KEY"
			((CREATED_STORY_COUNT++))
		else
			echo "WARNING: Failed to create story: $STORY_TITLE"
		fi
		echo ""
	done

	echo ""
	echo "=========================================="
	echo "JIRA Creation Complete"
	echo "=========================================="
	echo "Epic: $JIRA_BASE_URL/browse/$EPIC_KEY"
	echo "Stories created: $CREATED_STORY_COUNT / $STORY_COUNT"
	echo "=========================================="
else
	echo "Error: stories.json not found"
	exit 1
fi

# Save epic key for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
	echo "epic_key=$EPIC_KEY" >>$GITHUB_OUTPUT
	echo "artifact_path=$EPIC_STORIES_DIR" >>$GITHUB_OUTPUT
fi

exit 0
