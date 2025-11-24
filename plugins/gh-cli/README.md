# gh-cli

Interact with GitHub repositories using the GitHub CLI (`gh`) for pull request management, issue tracking, repository operations, GitHub Actions monitoring, and viewing GitHub file links.

## What This Plugin Provides

This plugin enables Claude Code to work with GitHub through the `gh` CLI tool, supporting:

- **Pull Requests**: Create, review, merge, and analyze PRs
- **Issues**: Create, list, update, and manage issues
- **Repository Operations**: View, clone, fork repositories
- **GitHub Actions**: Monitor workflow runs, view logs, trigger re-runs
- **File Viewing**: Fetch raw file content from GitHub URLs without HTML clutter

The plugin includes helper scripts for common tasks:
- `view_github_file.py`: Fetch raw file content from GitHub URLs
- `view_pr_files.py`: View files changed in pull requests

## Prerequisites

**GitHub CLI (`gh`) must be installed and authenticated before using this plugin.**

### Installation

Install the GitHub CLI for your platform:

**macOS:**
```bash
brew install gh
```

**Linux (Debian/Ubuntu):**
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Windows:**
```powershell
winget install --id GitHub.cli
```

**Other platforms:** See https://github.com/cli/cli#installation

### Authentication

After installation, authenticate with GitHub:

```bash
gh auth login
```

Follow the prompts to:
1. Choose GitHub.com or GitHub Enterprise
2. Select HTTPS or SSH protocol
3. Authenticate via web browser or token

Verify authentication:
```bash
gh auth status
```

## Usage

The skill triggers on:
- Explicit `gh` mentions: "use gh to create a PR", "run gh issue list"
- Natural language GitHub operations: "show me open issues", "create a pull request"
- GitHub file URLs: "view this file https://github.com/user/repo/blob/main/file.go"

### Examples

**Pull Requests:**
```
User: "Show me all open PRs"
Claude: Uses `gh pr list --state open`

User: "Create a PR for my current branch"
Claude: Uses `gh pr create --fill`

User: "What files changed in PR #123?"
Claude: Uses helper script `view_pr_files.py 123 --list`
```

**Issues:**
```
User: "Create an issue for the login bug"
Claude: Uses `gh issue create --title "..." --body "..."`

User: "Show me all bugs assigned to me"
Claude: Uses `gh issue list --label bug --assignee @me`
```

**GitHub Files:**
```
User: "Analyze this file: https://github.com/user/repo/blob/main/src/server.go"
Claude: Uses `view_github_file.py` to fetch raw content, then analyzes it
```

**GitHub Actions:**
```
User: "Check if CI is passing"
Claude: Uses `gh run list --limit 5` to check recent workflow runs
```

## How It Works

The plugin:

1. **Skill Triggering**: Activates on explicit `gh` mentions or natural language GitHub operations
2. **Authentication**: Uses your existing `gh` CLI authentication (must be set up beforehand)
3. **Command Execution**: Runs `gh` commands via Claude Code's Bash tool
4. **Helper Scripts**: Provides Python utilities for complex operations (file viewing, PR analysis)
5. **API Integration**: Direct access to GitHub's REST API via `gh api`

The helper scripts handle GitHub-specific tasks:
- Parsing GitHub URLs
- Base64 decoding of file content
- PR file analysis

## Bundled Resources

### scripts/

**view_github_file.py**: Fetches raw file content from GitHub URLs
- Parses GitHub URLs to extract owner, repo, ref, and file path
- Uses `gh api` to fetch content from GitHub's REST API
- Decodes base64-encoded content
- Returns clean source code without HTML

**view_pr_files.py**: Analyzes files changed in pull requests
- Lists all files changed in a PR
- Shows diff for specific files
- Displays file content from PR branch
- Supports PR numbers or full GitHub URLs

### references/

(No reference files currently bundled)

## License

MIT
