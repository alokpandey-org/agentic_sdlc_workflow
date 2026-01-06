# SDLC Workflow Guide

This guide explains how to use the automated SDLC workflow with GitHub Actions.

## Overview

The SDLC workflow automates the software development lifecycle from epic creation to implementation:

```
BRD Document → Epic & Stories → Manual Approval → Implementation → PR Creation → Manual Approval
```

## Workflow Steps

### 1. Epic & Story Generation
- Reads BRD document
- Generates Epic and User Stories using AI
- Creates Epic and Stories in JIRA
- Outputs story IDs for next steps

### 2. Manual Approval Gate
- Displays created Epic and Stories
- Waits for manual approval
- Allows review before proceeding

### 3. Implementation (First Story)
- Implements the first user story
- Creates a feature branch
- Generates code changes
- Creates a Pull Request

### 4. PR Review & Approval
- Displays PR information
- Waits for manual approval
- Allows code review before proceeding

## Prerequisites

Before running the workflow, ensure:

1. ✅ **Self-hosted runner** is set up and running
   - See [SELF_HOSTED_RUNNER_SETUP.md](./SELF_HOSTED_RUNNER_SETUP.md)

2. ✅ **GitHub Environment** is configured with approvers
   - See [GITHUB_ENVIRONMENT_SETUP.md](./GITHUB_ENVIRONMENT_SETUP.md)

3. ✅ **Repository Secrets** are configured:
   - `JIRA_TOKEN`
   - `JIRA_BASE_URL`
   - `JIRA_PROJECT_KEY`

4. ✅ **BRD Document** is committed to the repository

## Running the Workflow

### Step 1: Navigate to Actions

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Select **SDLC Workflow** from the left sidebar

### Step 2: Trigger the Workflow

1. Click **Run workflow** button (top right)
2. Fill in the required inputs:

| Input | Required | Description | Example |
|-------|----------|-------------|---------|
| `brd_path` | ✅ Yes | Path to BRD file | `docs/feature-brd.md` |
| `existing_app_brd` | ❌ No | Existing app BRD | `docs/app-brd.md` |
| `existing_app_arch` | ❌ No | Existing app architecture | `docs/architecture.md` |
| `workspace_root` | ❌ No | Workspace directory | `.` (default) |
| `git_repo` | ❌ No | Git repository URL | `https://github.com/org/repo` |
| `context_dirs` | ❌ No | Context directories | `src,docs` (default) |
| `policy_file` | ❌ No | Custom policy file | `agents/policies/custom.md` |

3. Click **Run workflow**

### Step 3: Monitor Execution

The workflow will execute in stages:

#### Stage 1: Generate Epic & Stories
- Status: Running
- Duration: ~5-10 minutes
- Output: Epic and Story IDs

**What to watch:**
- Check the job logs for any errors
- Verify JIRA connection succeeds
- Confirm Epic and Stories are created

#### Stage 2: Approve Implementation
- Status: Waiting for approval
- Action Required: **Manual Approval**

**How to approve:**
1. Click **Review deployments** button
2. Review the Epic and Story information displayed
3. Optionally, check JIRA to verify Epic/Stories
4. Check the `approval` environment checkbox
5. Add a comment (optional)
6. Click **Approve and deploy**

**What to review:**
- Epic title and description make sense
- Stories are well-defined
- Story count matches expectations
- JIRA links are accessible

#### Stage 3: Implement First Story
- Status: Running (after approval)
- Duration: ~10-20 minutes
- Output: Pull Request

**What to watch:**
- Implementation agent runs successfully
- Code changes are generated
- Branch is created and pushed
- PR is created in GitHub

#### Stage 4: Approve Pull Request
- Status: Waiting for approval
- Action Required: **Manual Approval**

**How to approve:**
1. Click **Review deployments** button
2. Review the PR information displayed
3. Click the PR URL to review code changes
4. Check the `approval` environment checkbox
5. Add a comment (optional)
6. Click **Approve and deploy**

**What to review:**
- PR title and description are clear
- Code changes implement the story correctly
- No obvious bugs or issues
- Tests are included (if applicable)

### Step 4: View Results

After workflow completion:

1. **JIRA**: Check the Epic and Stories
   - Epic URL: Displayed in workflow logs
   - Stories: Linked to the Epic

2. **GitHub**: Review the Pull Request
   - PR URL: Displayed in workflow logs
   - Branch: `feature/<story-id>`

3. **Artifacts**: Download workflow artifacts
   - `epic-stories-artifacts`: Contains JIRA IDs and metadata
   - `implementation-artifacts-<story-id>`: Contains PR info and implementation details

## Workflow Outputs

### JIRA Artifacts (`jira-artifacts.json`)

```json
{
  "epic_key": "PROJ-123",
  "epic_url": "https://yourcompany.atlassian.net/browse/PROJ-123",
  "story_keys": ["PROJ-124", "PROJ-125", "PROJ-126"],
  "story_count": 3,
  "created_at": "2024-01-05T10:30:00Z"
}
```

### PR Info (`pr-info.json`)

```json
{
  "pr_number": 42,
  "pr_url": "https://github.com/org/repo/pull/42",
  "branch": "feature/PROJ-124",
  "jira_ticket": "PROJ-124",
  "story_title": "Implement user authentication",
  "created_at": "2024-01-05T10:45:00Z"
}
```

## Troubleshooting

### Workflow Fails at Epic Generation

**Possible causes:**
- JIRA credentials incorrect
- BRD file not found
- Network connectivity issues

**Solutions:**
- Verify JIRA secrets are set correctly
- Check BRD path is correct
- Review runner logs

### Workflow Stuck at Approval

**Possible causes:**
- No reviewers configured
- Reviewers not notified

**Solutions:**
- Check environment has required reviewers
- Manually navigate to Actions and click "Review deployments"
- Check GitHub notification settings

### Implementation Fails

**Possible causes:**
- Story not found in JIRA
- Git authentication issues
- Code generation errors

**Solutions:**
- Verify story was created in JIRA
- Check GitHub CLI is authenticated on runner
- Review implementation agent logs

### PR Not Created

**Possible causes:**
- GitHub CLI not installed
- Authentication failed
- Branch already exists

**Solutions:**
- Install `gh` CLI on runner
- Run `gh auth login` on runner
- Delete existing branch if needed

## Best Practices

1. **Review Before Approval**: Always review generated artifacts before approving
2. **Clear BRDs**: Provide detailed, well-structured BRD documents
3. **Monitor Logs**: Watch workflow logs for warnings or errors
4. **Incremental Approach**: Start with one story, verify, then proceed
5. **Regular Cleanup**: Archive old workflow runs and artifacts

## Next Steps

After the first story is implemented:
- Review and merge the PR
- Run workflow again for next story
- Add unit test generation (coming soon)
- Add integration test generation (coming soon)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review workflow logs in GitHub Actions
3. Check runner logs on the self-hosted machine
4. Consult setup guides:
   - [Self-Hosted Runner Setup](./SELF_HOSTED_RUNNER_SETUP.md)
   - [GitHub Environment Setup](./GITHUB_ENVIRONMENT_SETUP.md)

