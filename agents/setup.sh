#!/bin/bash

# Setup script for environment variables
# This script sets up JIRA and GitHub tokens and tests connectivity
#
# IMPORTANT: This script should read credentials from environment variables
# or prompt the user. Never hardcode credentials in this file.
#
# To use this script:
# 1. Copy .env_sample to .env
# 2. Fill in your actual credentials in .env
# 3. Run: source agents/.env
# 4. Run: bash agents/setup-env.sh

set -e

echo "=========================================="
echo "Environment Setup for SDLC Agents"
echo "=========================================="
echo ""

# Check for required command-line tools
echo "Checking required command-line tools..."
echo ""

MISSING_TOOLS=0

# Check for jq
if ! command -v jq &>/dev/null; then
	echo "❌ ERROR: 'jq' is not installed"
	echo "   jq is required for JSON processing"
	echo "   Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
	MISSING_TOOLS=1
else
	echo "✓ jq found: $(command -v jq)"
fi

# Check for adf2md
if ! command -v adf2md &>/dev/null; then
	echo "❌ ERROR: 'adf2md' is not installed"
	echo "   adf2md is required for converting ADF to markdown"
	echo "   Install it from: https://github.com/carylee/adf2md"
	echo "   Quick install: npm install -g @carylee/adf2md"
	MISSING_TOOLS=1
else
	echo "✓ adf2md found: $(command -v adf2md)"
fi

# Check for curl
if ! command -v curl &>/dev/null; then
	echo "❌ ERROR: 'curl' is not installed"
	echo "   curl is required for API calls"
	echo "   Install it with: brew install curl (macOS) or apt-get install curl (Linux)"
	MISSING_TOOLS=1
else
	echo "✓ curl found: $(command -v curl)"
fi

# Check for auggie
if ! command -v auggie &>/dev/null; then
	echo "❌ ERROR: 'auggie' is not installed"
	echo "   auggie is required for AI agent execution"
	echo "   Please install auggie CLI"
	MISSING_TOOLS=1
else
	echo "✓ auggie found: $(command -v auggie)"
fi

# Check for gh (GitHub CLI)
if ! command -v gh &>/dev/null; then
	echo "❌ ERROR: 'gh' (GitHub CLI) is not installed"
	echo "   gh is required for creating pull requests automatically"
	echo "   Install it from: https://cli.github.com/"
	echo "   Quick install: brew install gh (macOS)"
	MISSING_TOOLS=1
else
	echo "✓ gh found: $(command -v gh)"
fi

echo ""

if [ $MISSING_TOOLS -eq 1 ]; then
	echo "ERROR: Missing required command-line tools"
	echo "Please install the missing tools and run this script again"
	exit 1
fi

echo "All required command-line tools are installed ✓"
echo ""

# Check if .env file exists and source it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
	echo "Loading environment variables from .env file..."
	source "$SCRIPT_DIR/.env"
else
	echo "ERROR: .env file not found!"
	echo "Please copy .env_sample to .env and fill in your credentials."
	echo "  cp $SCRIPT_DIR/.env_sample $SCRIPT_DIR/.env"
	exit 1
fi

# Verify required variables are set
if [ -z "$JIRA_TOKEN" ] || [ -z "$JIRA_PROJECT_KEY" ] || [ -z "$JIRA_BASE_URL" ] || [ -z "$JIRA_EMAIL" ]; then
	echo "ERROR: JIRA environment variables not set!"
	echo "Please ensure .env file contains: JIRA_TOKEN, JIRA_PROJECT_KEY, JIRA_BASE_URL, JIRA_EMAIL"
	exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
	echo "ERROR: GITHUB_TOKEN not set!"
	echo "Please ensure .env file contains: GITHUB_TOKEN"
	exit 1
fi

echo "JIRA_TOKEN set"
echo "JIRA_PROJECT_KEY set to: $JIRA_PROJECT_KEY"
echo ""

export GH_TOKEN="$GITHUB_TOKEN" # Some tools use GH_TOKEN

echo "GITHUB_TOKEN set"
echo ""

# Test JIRA connection
echo "=========================================="
echo "Testing JIRA Connection"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/jira-utils.sh"

if test_jira_connection; then
	echo ""
	if get_jira_project "$JIRA_PROJECT_KEY"; then
		echo ""
		echo "JIRA setup complete and verified!"
	else
		echo ""
		echo "ERROR: JIRA connection works but project '$JIRA_PROJECT_KEY' not accessible"
		echo "   Please verify the project key or your permissions"
		exit 1
	fi
else
	echo ""
	echo "ERROR: JIRA connection failed"
	echo "   Please verify your JIRA_TOKEN and credentials"
	exit 1
fi

echo ""

# Test GitHub connection
echo "=========================================="
echo "Testing GitHub Connection"
echo "=========================================="
echo ""

# Test with curl
GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -r '.login // empty')

if [ -n "$GITHUB_USER" ]; then
	echo "GitHub connection successful"
	echo "   Logged in as: $GITHUB_USER"

	# Test repository access
	REPO_OWNER="alokpandey"
	REPO_NAME="agentic_sdlc_workflow"

	REPO_CHECK=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
		"https://api.github.com/repos/$REPO_OWNER/$REPO_NAME" | jq -r '.name // empty')

	if [ -n "$REPO_CHECK" ]; then
		echo "Repository access verified: $REPO_OWNER/$REPO_NAME"
	else
		echo "ERROR: Cannot access repository: $REPO_OWNER/$REPO_NAME"
		echo "   Token may not have repository permissions"
		echo "   Please verify your GITHUB_TOKEN has access to this repository"
		exit 1
	fi
else
	echo "ERROR: GitHub connection failed"
	echo "   Please verify your GITHUB_TOKEN"
	exit 1
fi

echo ""

# Configure GitHub CLI (gh) if available
if command -v gh &>/dev/null; then
	echo "=========================================="
	echo "Configuring GitHub CLI (gh)"
	echo "=========================================="
	echo ""

	# Check if gh is already authenticated
	if gh auth status &>/dev/null; then
		echo "GitHub CLI is already authenticated"
		GH_USER=$(gh api user -q .login 2>/dev/null || echo "")
		if [ -n "$GH_USER" ]; then
			echo "   Authenticated as: $GH_USER"
		fi
	else
		echo "GitHub CLI is not authenticated. Configuring with GITHUB_TOKEN..."

		# Authenticate gh using the token
		echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null

		if gh auth status &>/dev/null; then
			echo "✓ GitHub CLI authenticated successfully"
			GH_USER=$(gh api user -q .login 2>/dev/null || echo "")
			if [ -n "$GH_USER" ]; then
				echo "   Authenticated as: $GH_USER"
			fi
		else
			echo "ERROR: Failed to authenticate GitHub CLI"
			echo "   Please manually authenticate with: gh auth login"
			echo "   Or check that your GITHUB_TOKEN is valid"
			exit 1
		fi
	fi

	echo ""
fi

echo ""
echo "=========================================="
echo "Configuring Git Credentials"
echo "=========================================="
echo ""

# Configure git to use GitHub token for authentication
echo "Setting up git credential helper to use GITHUB_TOKEN..."
git config --global credential.helper "!f() { echo \"username=x-access-token\"; echo \"password=$GITHUB_TOKEN\"; }; f"
echo "✓ Git configured to use GITHUB_TOKEN for authentication"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Set the environment variables for this session before running the agents."
echo "  source $(dirname "$0")/.env"
echo ""
