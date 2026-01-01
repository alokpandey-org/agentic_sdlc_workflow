#!/bin/bash

# JIRA Utilities for creating epics and stories
# Requires: JIRA_TOKEN, JIRA_PROJECT_KEY, JIRA_BASE_URL, JIRA_EMAIL environment variables

set -e

# Validate required environment variables
if [ -z "$JIRA_BASE_URL" ]; then
	echo "Error: JIRA_BASE_URL environment variable not set"
	exit 1
fi

if [ -z "$JIRA_EMAIL" ]; then
	echo "Error: JIRA_EMAIL environment variable not set"
	exit 1
fi

if [ -z "$JIRA_PROJECT_KEY" ]; then
	echo "Error: JIRA_PROJECT_KEY environment variable not set"
	exit 1
fi

JIRA_API_URL="$JIRA_BASE_URL/rest/api/3"

# Function to create an epic in JIRA
create_jira_epic() {
	local epic_title="$1"
	local epic_description_adf="$2" # This is already ADF JSON
	local project_key="$JIRA_PROJECT_KEY"

	# Clean up title only (description is already ADF)
	epic_title=$(echo -n "$epic_title" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -Rs '.' | sed 's/^"//' | sed 's/"$//')

	# Create JSON payload using jq to properly embed the ADF description
	local payload=$(
		jq -n \
			--arg project_key "$project_key" \
			--arg summary "$epic_title" \
			--argjson description "$epic_description_adf" \
			'{
			"fields": {
				"project": {"key": $project_key},
				"summary": $summary,
				"description": $description,
				"issuetype": {"name": "Epic"}
			}
		}'
	)

	# Create the epic
	local response=$(curl -s -X POST "$JIRA_API_URL/issue" \
		-u "$JIRA_EMAIL:$JIRA_TOKEN" \
		-H "Content-Type: application/json" \
		-d "$payload")

	# Extract epic key
	local epic_key=$(echo "$response" | jq -r '.key // empty')

	if [ -z "$epic_key" ]; then
		echo "Error creating epic. Response: $response" >&2
		return 1
	fi

	echo "$epic_key"
}

# Function to create a user story in JIRA
create_jira_story() {
	local story_title="$1"
	local story_description_adf="$2" # This is already ADF JSON
	local epic_key="$3"
	local priority="${4:-Medium}" # Default to Medium if not provided
	local project_key="$JIRA_PROJECT_KEY"

	# Clean up title only (description is already ADF)
	story_title=$(echo -n "$story_title" | tr -d '\n\r`' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -Rs '.' | sed 's/^"//' | sed 's/"$//' | cut -c1-255)

	# Create JSON payload using jq to properly embed the ADF description
	local payload
	if [ -n "$epic_key" ]; then
		payload=$(
			jq -n \
				--arg project_key "$project_key" \
				--arg summary "$story_title" \
				--argjson description "$story_description_adf" \
				--arg priority "$priority" \
				--arg epic_key "$epic_key" \
				'{
				"fields": {
					"project": {"key": $project_key},
					"summary": $summary,
					"description": $description,
					"issuetype": {"name": "Story"},
					"priority": {"name": $priority},
					"parent": {"key": $epic_key}
				}
			}'
		)
	else
		payload=$(
			jq -n \
				--arg project_key "$project_key" \
				--arg summary "$story_title" \
				--argjson description "$story_description_adf" \
				--arg priority "$priority" \
				'{
				"fields": {
					"project": {"key": $project_key},
					"summary": $summary,
					"description": $description,
					"issuetype": {"name": "Story"},
					"priority": {"name": $priority}
				}
			}'
		)
	fi

	# Validate JSON before sending
	if ! echo "$payload" | jq . >/dev/null 2>&1; then
		echo "Error: Invalid JSON payload for story '$story_title'" >&2
		echo "Payload: $payload" >&2
		return 1
	fi

	# Create the story
	local response=$(curl -s -X POST "$JIRA_API_URL/issue" \
		-u "$JIRA_EMAIL:$JIRA_TOKEN" \
		-H "Content-Type: application/json" \
		-d "$payload")

	# Extract story key
	local story_key=$(echo "$response" | jq -r '.key // empty')

	if [ -z "$story_key" ]; then
		echo "Error creating story '$story_title'. Response: $response" >&2
		return 1
	fi

	echo "$story_key"
}

# Function to test JIRA connection
test_jira_connection() {
	echo "Testing JIRA connection..."

	local response=$(curl -s -X GET "$JIRA_API_URL/myself" \
		-u "$JIRA_EMAIL:$JIRA_TOKEN")

	local display_name=$(echo "$response" | jq -r '.displayName // empty')

	if [ -z "$display_name" ]; then
		echo "ERROR: JIRA connection failed. Response: $response"
		return 1
	fi

	echo "JIRA connection successful. Logged in as: $display_name"
	return 0
}

# Function to get project details
get_jira_project() {
	local project_key="${1:-$JIRA_PROJECT_KEY}"

	echo "Getting JIRA project: $project_key"

	local response=$(curl -s -X GET "$JIRA_API_URL/project/$project_key" \
		-u "$JIRA_EMAIL:$JIRA_TOKEN")

	local project_name=$(echo "$response" | jq -r '.name // empty')

	if [ -z "$project_name" ]; then
		echo "ERROR: Project not found: $project_key"
		return 1
	fi

	echo "Project found: $project_name"
	return 0
}
