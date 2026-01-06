# Self-Hosted GitHub Actions Runner Setup

This guide explains how to set up a self-hosted runner for the SDLC workflow.

## Why Self-Hosted Runner?

Self-hosted runners provide:
- **Access to local resources**: JIRA, internal networks, databases
- **Custom environment**: Pre-installed tools (auggie, jq, adf2md, gh CLI)
- **Better performance**: No cold starts, persistent caching
- **Cost control**: No GitHub Actions minutes consumed

## Prerequisites

### System Requirements
- **OS**: Linux, macOS, or Windows
- **RAM**: Minimum 4GB (8GB+ recommended)
- **Disk**: 20GB+ free space
- **Network**: Stable internet connection

### Required Software
The following tools must be installed on the runner machine:

1. **Git** - Version control
2. **Bash** - Shell scripting (pre-installed on Linux/macOS)
3. **jq** - JSON processing
4. **auggie** - AI agent CLI
5. **adf2md** - Atlassian Document Format converter
6. **gh** - GitHub CLI (for PR creation)
7. **Node.js** (optional) - If needed by your codebase

## Step-by-Step Setup

### Step 1: Navigate to Runner Settings

1. Go to your GitHub repository
2. Click **Settings** (top navigation)
3. In the left sidebar, scroll down to **Actions**
4. Click **Runners**
5. Click **New self-hosted runner** button

### Step 2: Choose Operating System

Select your runner's operating system:
- Linux (most common)
- macOS
- Windows

GitHub will display platform-specific instructions.

### Step 3: Download the Runner

On your runner machine, execute the download commands shown by GitHub:

```bash
# Example for Linux x64
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
```

**Note**: The version number and URL will be provided by GitHub in the UI.

### Step 4: Configure the Runner

Run the configuration script with the token provided by GitHub:

```bash
./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN
```

You'll be prompted for:

1. **Runner name**: Give it a descriptive name (e.g., `sdlc-runner-01`)
2. **Runner group**: Press Enter for default
3. **Labels**: Add custom labels (optional, e.g., `sdlc,auggie`)
4. **Work folder**: Press Enter for default (`_work`)

Example interaction:
```
Enter the name of the runner: sdlc-runner-01
Enter any additional labels (ex. label-1,label-2): sdlc,auggie
Enter name of work folder: [press Enter]
```

### Step 5: Install Required Tools

Before starting the runner, install all required tools:

#### Install jq (JSON processor)
```bash
# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install -y jq

# macOS
brew install jq
```

#### Install GitHub CLI
```bash
# Linux (Ubuntu/Debian)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# macOS
brew install gh
```

#### Install auggie
```bash
# Follow auggie installation instructions
# Example (adjust based on actual installation method):
npm install -g @augmentcode/cli
# or
pip install auggie-cli
```

#### Install adf2md
```bash
# Follow adf2md installation instructions
npm install -g adf2md
# or check the specific installation method for your setup
```

#### Verify Installations
```bash
git --version
jq --version
gh --version
auggie --version
adf2md --version
```

### Step 6: Start the Runner

You have two options:

#### Option A: Run Interactively (for testing)
```bash
./run.sh
```

This runs the runner in the foreground. Good for testing, but stops when you close the terminal.

#### Option B: Run as a Service (recommended for production)

**Linux (systemd)**:
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

**macOS (launchd)**:
```bash
./svc.sh install
./svc.sh start
./svc.sh status
```

**Windows (as a service)**:
```powershell
.\svc.sh install
.\svc.sh start
.\svc.sh status
```

### Step 7: Verify Runner is Online

1. Go back to GitHub: **Settings** → **Actions** → **Runners**
2. You should see your runner listed with a green "Idle" status
3. If it shows "Offline", check the runner logs

## Configuration for SDLC Workflow

### Environment Variables

The runner needs access to certain environment variables. You can set these:

#### Option 1: System-wide (recommended)
```bash
# Add to ~/.bashrc or ~/.bash_profile
export JIRA_TOKEN="your-jira-token"
export JIRA_BASE_URL="https://yourcompany.atlassian.net"
export JIRA_PROJECT_KEY="PROJ"
```

#### Option 2: In GitHub Secrets
Configure these as repository secrets (see GITHUB_ENVIRONMENT_SETUP.md)

### GitHub CLI Authentication

The runner needs to authenticate with GitHub to create PRs:

```bash
gh auth login
```

Follow the prompts to authenticate.

## Managing the Runner

### View Status
```bash
sudo ./svc.sh status  # Linux/macOS with sudo
./svc.sh status       # macOS without sudo
```

### Stop the Runner
```bash
sudo ./svc.sh stop
```

### Start the Runner
```bash
sudo ./svc.sh start
```

### View Logs
```bash
# Service logs
sudo journalctl -u actions.runner.* -f  # Linux

# Runner logs
tail -f _diag/Runner_*.log
```

### Remove the Runner

1. Stop the service:
```bash
sudo ./svc.sh stop
sudo ./svc.sh uninstall
```

2. Remove from GitHub:
```bash
./config.sh remove --token YOUR_REMOVAL_TOKEN
```

3. Get removal token from: **Settings** → **Actions** → **Runners** → Click runner → **Remove**

## Troubleshooting

### Runner Shows Offline
- Check if the service is running: `sudo ./svc.sh status`
- Check network connectivity
- Review logs: `tail -f _diag/Runner_*.log`

### Workflow Fails with "Command not found"
- Ensure all required tools are installed
- Check PATH environment variable
- Verify tools are accessible: `which jq`, `which gh`, etc.

### Permission Denied Errors
- Ensure runner has write access to the repository directory
- Check file permissions on agent scripts: `chmod +x agents/*.sh`

### JIRA Connection Fails
- Verify JIRA_TOKEN is set correctly
- Check JIRA_BASE_URL format (no trailing slash)
- Test connection: `curl -H "Authorization: Bearer $JIRA_TOKEN" $JIRA_BASE_URL/rest/api/3/myself`

## Security Best Practices

1. **Dedicated Machine**: Use a dedicated machine for the runner
2. **Limited Access**: Restrict who can access the runner machine
3. **Secrets Management**: Use GitHub Secrets, not hardcoded values
4. **Regular Updates**: Keep the runner software updated
5. **Monitoring**: Monitor runner logs for suspicious activity
6. **Network Security**: Use firewall rules to restrict outbound connections

## Next Steps

After setting up the runner:
1. ✅ Verify runner shows as "Idle" in GitHub
2. ✅ Test with a simple workflow
3. ✅ Set up GitHub Environments (see GITHUB_ENVIRONMENT_SETUP.md)
4. ✅ Configure repository secrets
5. ✅ Run the SDLC workflow

