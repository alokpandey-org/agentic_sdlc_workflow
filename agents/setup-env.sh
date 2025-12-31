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

export GH_TOKEN="$GITHUB_TOKEN"  # Some tools use GH_TOKEN

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
    echo "WARNING: JIRA connection works but project '$JIRA_PROJECT_KEY' not accessible"
    echo "   Please verify the project key or your permissions"
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
    echo "WARNING: Cannot access repository: $REPO_OWNER/$REPO_NAME"
    echo "   Token may not have repository permissions"
  fi
else
  echo "ERROR: GitHub connection failed"
  echo "   Please verify your GITHUB_TOKEN"
  exit 1
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Environment variables are set for this session."
echo "To use in future sessions, run:"
echo "  source $(dirname "$0")/.env"
echo ""
echo "You can now run the agents with these credentials."
echo ""

