#!/bin/bash

# Agent 2: Implementation Generator
# This is a generic agent that generates code implementation for a user story
# It discovers context from the codebase and generates a complete implementation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
fi

# Default values from environment or hardcoded
STORY_PATH=""
EXISTING_APP_BRD="${DEMO_EXISTING_APP_BRD:-}"
EXISTING_APP_ARCH="${DEMO_EXISTING_APP_ARCH:-}"
WORKSPACE_ROOT="${DEMO_WORKSPACE_ROOT:-.}"
GIT_REPO="${DEMO_GIT_REPO:-}"
CONTEXT_DIRS=""
OUTPUT_DIR="sdlc-artifacts"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --story-path)
      STORY_PATH="$2"
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
if [ -z "$STORY_PATH" ]; then
  echo "Error: --story-path is required"
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
mkdir -p "$OUTPUT_DIR/implementation"

echo "=========================================="
echo "Agent 2: Implementation Generator"
echo "=========================================="
echo "Git Repository: ${GIT_REPO:-Not provided}"
echo "Story Path: $STORY_PATH"
echo "Existing App BRD Path: ${EXISTING_APP_BRD:-Not provided}"
echo "Existing App Architecture Path: ${EXISTING_APP_ARCH:-Not provided}"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Context Directories: $CONTEXT_DIRS"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Read the user story
if [ ! -f "$STORY_PATH" ]; then
  echo "Error: Story file not found: $STORY_PATH"
  exit 1
fi

STORY_CONTENT=$(cat "$STORY_PATH")
STORY_ID=$(echo "$STORY_CONTENT" | jq -r '.story_id // "STORY-001"')
STORY_TITLE=$(echo "$STORY_CONTENT" | jq -r '.title // "Implementation"')

echo "Implementing Story: $STORY_ID - $STORY_TITLE"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="$SCRIPT_DIR/policies/implementation.policy.md"

# Load policy file
if [ ! -f "$POLICY_FILE" ]; then
  echo "Error: Policy file not found: $POLICY_FILE"
  exit 1
fi

POLICY_CONTENT=$(cat "$POLICY_FILE")

# Build implementation instruction
IMPLEMENTATION_INSTRUCTION="$POLICY_CONTENT

---

EXECUTION CONTEXT:

USER STORY:
$STORY_CONTENT

EXISTING APPLICATION CONTEXT:"

if [ -n "$EXISTING_APP_BRD" ]; then
  IMPLEMENTATION_INSTRUCTION="$IMPLEMENTATION_INSTRUCTION
- Existing Application BRD Path: $EXISTING_APP_BRD"
fi

if [ -n "$EXISTING_APP_ARCH" ]; then
  IMPLEMENTATION_INSTRUCTION="$IMPLEMENTATION_INSTRUCTION
- Existing Application Architecture Path: $EXISTING_APP_ARCH"
fi

IMPLEMENTATION_INSTRUCTION="$IMPLEMENTATION_INSTRUCTION

WORKSPACE:
- Workspace Root: $WORKSPACE_ROOT
- Context Directories: $CONTEXT_DIRS
- Output Directory: $OUTPUT_DIR/implementation/

Begin implementation now."

# Run Auggie agent
echo "Running Auggie agent to generate implementation..."
echo ""

auggie -p \
  --workspace-root "$WORKSPACE_ROOT" \
  "$IMPLEMENTATION_INSTRUCTION" > "$OUTPUT_DIR/implementation/agent-output.txt"

# Check if implementation was successful
if [ ! -f "$OUTPUT_DIR/implementation/changes-summary.md" ]; then
  echo "Warning: changes-summary.md not found, creating from agent output"
  echo "# Implementation Summary" > "$OUTPUT_DIR/implementation/changes-summary.md"
  echo "" >> "$OUTPUT_DIR/implementation/changes-summary.md"
  echo "Story: $STORY_ID - $STORY_TITLE" >> "$OUTPUT_DIR/implementation/changes-summary.md"
  echo "" >> "$OUTPUT_DIR/implementation/changes-summary.md"
  cat "$OUTPUT_DIR/implementation/agent-output.txt" >> "$OUTPUT_DIR/implementation/changes-summary.md"
fi

# Generate PR metadata
BRANCH_NAME=$(echo "$STORY_ID" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
FEATURE_NAME="$STORY_TITLE"

if [ -f "$OUTPUT_DIR/implementation/pr-description.md" ]; then
  PR_TITLE=$(head -n 1 "$OUTPUT_DIR/implementation/pr-description.md")
  PR_BODY=$(tail -n +2 "$OUTPUT_DIR/implementation/pr-description.md")
else
  PR_TITLE="feat($STORY_ID): $STORY_TITLE"
  PR_BODY="## User Story
$STORY_ID: $STORY_TITLE

## Implementation
See changes-summary.md for details.

## Testing
- [ ] Unit tests (to be added)
- [ ] Integration tests (to be added)

## Checklist
- [x] Code follows project conventions
- [x] Documentation updated
- [ ] Tests added (next step)
- [ ] Ready for review"
fi

# Output for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "feature_name=$FEATURE_NAME" >> $GITHUB_OUTPUT
  echo "branch_name=$BRANCH_NAME" >> $GITHUB_OUTPUT
  echo "pr_title=$PR_TITLE" >> $GITHUB_OUTPUT
  echo "pr_body<<EOF" >> $GITHUB_OUTPUT
  echo "$PR_BODY" >> $GITHUB_OUTPUT
  echo "EOF" >> $GITHUB_OUTPUT
fi

echo ""
echo "=========================================="
echo "Implementation completed successfully!"
echo "Branch: $BRANCH_NAME"
echo "Output location: $OUTPUT_DIR/implementation/"
echo "=========================================="

# Display summary
if [ -f "$OUTPUT_DIR/implementation/changes-summary.md" ]; then
  echo ""
  echo "CHANGES SUMMARY:"
  cat "$OUTPUT_DIR/implementation/changes-summary.md"
fi

# Create PR in the git repository
echo ""
echo "=========================================="
echo "Creating Pull Request"
echo "=========================================="

# Navigate to workspace
cd "$WORKSPACE_ROOT"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo "Error: Not a git repository. Skipping PR creation."
  exit 1
fi

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

# Detect default branch (main or master)
DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
if [ -z "$DEFAULT_BRANCH" ]; then
  # Fallback to main if detection fails
  DEFAULT_BRANCH="main"
fi

echo "Default branch detected: $DEFAULT_BRANCH"

# Create PR using GitHub CLI
echo "Creating pull request..."
if command -v gh &> /dev/null; then
  gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base "$DEFAULT_BRANCH" \
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
    echo "$PR_NUMBER" > "$OUTPUT_DIR/implementation/pr-number.txt"
    echo "$PR_URL" > "$OUTPUT_DIR/implementation/pr-url.txt"

    echo ""
    echo "View Pull Request: $PR_URL"
  fi
else
  echo "Warning: GitHub CLI (gh) not found. Please install it to create PRs automatically."
  echo "Branch pushed: $BRANCH_NAME"
  echo "Please create the PR manually at your repository."
fi

exit 0

