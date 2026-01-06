# GitHub Environment Setup for Manual Approvals

This guide explains how to set up GitHub Environments with required reviewers to enable manual approval gates in the SDLC workflow.

## What are GitHub Environments?

GitHub Environments allow you to configure protection rules for deployments, including:
- Required reviewers (manual approval gates)
- Wait timers
- Deployment branches
- Environment secrets

In our SDLC workflow, we use the `approval` environment to pause execution and wait for manual approval before proceeding.

## Steps to Create the Approval Environment

### 1. Navigate to Repository Settings

1. Go to your GitHub repository
2. Click on **Settings** (top navigation bar)
3. In the left sidebar, click on **Environments**

### 2. Create New Environment

1. Click the **New environment** button
2. Enter the environment name: `approval`
3. Click **Configure environment**

### 3. Configure Protection Rules

On the environment configuration page:

#### Required Reviewers
1. Check the box for **Required reviewers**
2. Click **Add reviewers**
3. Search for and select the team members who should approve workflow runs
   - You can add up to 6 reviewers
   - At least one reviewer must approve before the workflow continues
4. Click **Save protection rules**

#### Optional: Wait Timer
- You can optionally set a wait timer (e.g., 5 minutes) before reviewers can approve
- This is useful if you want to ensure artifacts are ready before approval

#### Optional: Deployment Branches
- By default, all branches can use this environment
- You can restrict to specific branches (e.g., only `main` or `develop`)

### 4. Verify Configuration

After saving, you should see:
- ✅ Environment name: `approval`
- ✅ Required reviewers: [List of reviewers]
- ✅ Protection rules enabled

## How Manual Approval Works in the Workflow

### Workflow Execution Flow

```
Job 1: generate-epic-stories
  ↓
Job 2: approve-implementation (WAITS FOR APPROVAL)
  ↓ (After approval)
Job 3: implement-first-story
  ↓
Job 4: approve-pr (WAITS FOR APPROVAL)
  ↓ (After approval)
[Future: Unit tests, etc.]
```

### Approval Process

1. **Workflow Pauses**: When a job with `environment: approval` starts, it pauses
2. **Notification**: Reviewers receive a notification (email/GitHub notification)
3. **Review**: Reviewers can:
   - View the workflow run
   - Check the outputs from previous jobs
   - Review generated artifacts (Epic, Stories, PR)
4. **Approve/Reject**:
   - Click **Review deployments** button
   - Select the environment to approve
   - Add optional comment
   - Click **Approve and deploy** or **Reject**
5. **Continue/Stop**: 
   - If approved: Workflow continues to next job
   - If rejected: Workflow stops

## Required Secrets

The workflow also requires these repository secrets to be configured:

### Navigate to Secrets
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**

### Add These Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `JIRA_TOKEN` | JIRA API token | `ATATxxxxxxxxxxxxx` |
| `JIRA_BASE_URL` | JIRA instance URL | `https://yourcompany.atlassian.net` |
| `JIRA_PROJECT_KEY` | JIRA project key | `PROJ` |
| `GITHUB_TOKEN` | Automatically provided by GitHub Actions | (Auto-generated) |

**Note**: `GITHUB_TOKEN` is automatically provided by GitHub Actions and doesn't need to be manually configured.

## Testing the Approval Flow

### 1. Trigger the Workflow

1. Go to **Actions** tab in your repository
2. Select **SDLC Workflow** from the left sidebar
3. Click **Run workflow**
4. Fill in the required inputs (BRD path, etc.)
5. Click **Run workflow**

### 2. Monitor Execution

1. Click on the running workflow
2. Watch as jobs execute:
   - `generate-epic-stories` runs automatically
   - `approve-implementation` pauses and shows "Waiting for approval"

### 3. Approve

1. Click **Review deployments** button (appears when job is waiting)
2. Check the `approval` environment checkbox
3. Optionally add a comment
4. Click **Approve and deploy**
5. Watch the workflow continue

## Troubleshooting

### "Environment not found" Error
- Ensure the environment name is exactly `approval` (lowercase)
- Check that you have admin access to the repository

### No "Review deployments" Button
- Ensure you're added as a required reviewer
- Check that the environment protection rules are saved

### Workflow Skips Approval
- Verify the job has `environment: approval` in the YAML
- Check that protection rules are enabled for the environment

## Best Practices

1. **Multiple Reviewers**: Add at least 2-3 reviewers for redundancy
2. **Clear Comments**: When approving, add comments explaining what you reviewed
3. **Artifact Review**: Always check the generated artifacts before approving
4. **Timeout**: Consider setting a maximum wait time to prevent indefinite hangs

