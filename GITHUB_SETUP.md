# GitHub Workflow Setup Guide

## 1. Create GitHub Environments

Navigate to: `Settings` → `Environments` → `New environment`

Create 3 environments with protection rules:

### Environment: `epic-review`
```bash
# In GitHub UI:
# 1. Click "New environment"
# 2. Name: epic-review
# 3. Check "Required reviewers"
# 4. Add yourself (or team members) as reviewers
# 5. Save protection rules
```

### Environment: `test-plan-review`
```bash
# Same steps as above
# Name: test-plan-review
```

### Environment: `pr-review`
```bash
# Same steps as above
# Name: pr-review
```

## 2. Setup Self-Hosted Runner

### On your runner machine (Azure VM):

```bash
# Install runner
cd /home/azureuser
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.321.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz

# Configure runner
# Get token from: Settings → Actions → Runners → New self-hosted runner
./config.sh --url https://github.com/alokpandey/agentic_sdlc_workflow --token YOUR_TOKEN

# Install as systemd service (runs on boot, auto-restart)
sudo ./svc.sh install
sudo ./svc.sh start

# OR run interactively (for testing/debugging)
./run.sh
```

### Verify runner has required tools:
```bash
# Check installations
which auggie
which jq
which gh
which git

# Setup GitHub CLI authentication
gh auth login
```

### Setup environment variables on runner:
```bash
# Create .env file for agents (if not already exists)
cat > /home/azureuser/agentic-sdlc-workflow/agents/.env << 'EOF'
JIRA_BASE_URL=https://your-domain.atlassian.net
JIRA_USER_EMAIL=your-email@example.com
JIRA_TOKEN=your-jira-token
JIRA_PROJECT_KEY=YOUR-PROJECT-KEY
GITHUB_TOKEN=your-github-token
EOF

# Source it
source /home/azureuser/agentic-sdlc-workflow/agents/.env
```

## 3. Verify Directory Structure

```bash
# Ensure these paths exist on runner:
ls -la /home/azureuser/agentic-sdlc-workflow/agents/
ls -la /home/azureuser/agentic-sdlc-workflow/agents/policies/
ls -la /home/azureuser/business-req-docs/

# Create workspace directory
mkdir -p /home/azureuser/agentic-sdlc-workspace
```

## 4. Run the Workflow

1. Go to: `Actions` → `Agentic SDLC Workflow` → `Run workflow`
2. Fill in inputs:
   - **git_repo**: `https://github.com/alokpandey/Inventory-system.git`
   - **new_brd_path**: `/home/azureuser/business-req-docs/new-features/your-feature.md`
   - **existing_brd_path**: `/home/azureuser/business-req-docs/current-brd-with-tech-arch.md`
   - **existing_tech_arch_path**: `/home/azureuser/business-req-docs/current-brd-with-tech-arch.md`
3. Click `Run workflow`

## 5. Approval Process

### Epic Review:
- Workflow pauses at `review-epic` job
- SSH to runner: `ssh azureuser@your-runner-ip`
- Review files: `cat /home/azureuser/agentic-sdlc-workspace/sdlc-artifacts/epic-stories/*.md`
- In GitHub UI: Click `Review deployments` → Select `epic-review` → `Approve and deploy`

### Test Plan Review (per story):
- Workflow pauses at `Review Test Plan` job in story pipeline
- SSH to runner and review: `cat /home/azureuser/agentic-sdlc-workspace/sdlc-artifacts/unit-tests-{STORY-ID}/unit-test-plan.md`
- In GitHub UI: Click `Review deployments` → Select `test-plan-review` → `Approve and deploy`

### PR Review (per story):
- Workflow pauses at `Review PR (Code + Tests)` job
- Check PR URL in job logs
- Review complete PR (implementation + unit tests) in GitHub
- In GitHub UI: Click `Review deployments` → Select `pr-review` → `Approve and deploy`

## 6. Monitoring

- **Main workflow**: Shows epic processing + orchestration
- **Story pipelines**: Separate workflow runs for each story (ASI-71, ASI-72, etc.)
- Each story pipeline shows: Implementation → UT Generate → Test Plan Review → UT Publish → PR Review

## Troubleshooting

```bash
# Check runner status (if installed as service)
sudo ./svc.sh status

# View runner logs (if installed as service)
journalctl -u actions.runner.* -f

# If running interactively, logs are in terminal

# Check workspace
ls -la /home/azureuser/agentic-sdlc-workspace/

# Verify agent scripts are executable
chmod +x /home/azureuser/agentic-sdlc-workflow/agents/*.sh
```

## Notes

**svc.sh** is a script provided by GitHub Actions runner that manages the runner as a systemd service:
- `sudo ./svc.sh install` - Installs runner as a service (runs on boot)
- `sudo ./svc.sh start` - Starts the service
- `sudo ./svc.sh stop` - Stops the service
- `sudo ./svc.sh status` - Checks service status
- `sudo ./svc.sh uninstall` - Removes the service

**Alternative**: Use `./run.sh` to run the runner interactively (useful for testing).

