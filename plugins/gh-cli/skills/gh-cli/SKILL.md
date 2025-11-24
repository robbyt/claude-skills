---
name: gh-cli
description: Comprehensive GitHub CLI integration for PR management, issues, repository operations, GitHub Actions, and viewing GitHub file links. Triggers on explicit `gh` mentions ("use gh to create PR", "run gh issue list") or natural language GitHub operations ("show me open issues", "create a pull request", "view this GitHub file"). Handles GitHub URLs to view raw file content without HTML/JS clutter.
---

# GitHub CLI Integration

Interact with GitHub repositories using the `gh` CLI for pull requests, issues, repository operations, GitHub Actions, and viewing GitHub files.

## Prerequisites

⚠️ **This skill assumes GitHub CLI (`gh`) is already installed and authenticated.**

If you haven't completed setup:
1. Install: https://github.com/cli/cli#installation
2. Authenticate: `gh auth login`
3. Verify: `gh auth status`

**Claude Code will NOT configure authentication for you.** This must be done manually before using this skill.

## Quick Start

Verify installation:
```bash
command -v gh
gh --version
```

Check authentication:
```bash
gh auth status
```

Basic patterns:
```bash
gh pr list                          # List pull requests
gh issue create --title "Bug"       # Create issue
gh repo view owner/repo             # View repository info
gh run list                         # List workflow runs
```

## Core Capabilities

### 1. Pull Requests

**Common operations:**
```bash
# List PRs
gh pr list --state open
gh pr list --author @me

# View PR details
gh pr view 123
gh pr view 123 --json title,body,state

# Create PR
gh pr create --title "Feature" --body "Description"
gh pr create --fill  # Use git commit messages

# Review and merge
gh pr review 123 --approve
gh pr merge 123 --squash

# View PR diff
gh pr diff 123
gh pr diff 123 -- path/to/file.go   # Specific file
```

**Helper script - View PR files:**
```bash
# List all files changed in a PR
python3 scripts/view_pr_files.py 123 --list
python3 scripts/view_pr_files.py https://github.com/user/repo/pull/123 --list

# Show full diff
python3 scripts/view_pr_files.py 123 --diff

# Show specific file from PR
python3 scripts/view_pr_files.py 123 --file path/to/file.go
```

### 2. Issues

**Common operations:**
```bash
# List issues
gh issue list
gh issue list --label bug --state open
gh issue list --assignee @me

# View issue
gh issue view 456
gh issue view 456 --json title,body,labels

# Create issue
gh issue create --title "Bug report" --body "Details"
gh issue create --label bug --assignee @me

# Update issue
gh issue edit 456 --add-label "needs-review"
gh issue close 456
gh issue reopen 456
```

### 3. Repository Operations

**Common operations:**
```bash
# View repository
gh repo view owner/repo
gh repo view owner/repo --json name,description,stargazersCount

# Clone repository
gh repo clone owner/repo

# Fork repository
gh repo fork owner/repo

# List repositories
gh repo list owner
gh repo list owner --limit 50 --json name,description
```

### 4. GitHub Actions

**Common operations:**
```bash
# List workflow runs
gh run list
gh run list --workflow ci.yml

# View run details
gh run view 789
gh run view 789 --log

# Watch run in progress
gh run watch 789

# Re-run workflow
gh run rerun 789
```

### 5. Viewing GitHub File URLs

When the user provides a GitHub file URL (e.g., `https://github.com/user/repo/blob/main/path/to/file.go`), use the helper script to fetch raw file content instead of using WebFetch (which returns HTML/JS).

**Helper script - View GitHub file:**
```bash
python3 scripts/view_github_file.py https://github.com/user/repo/blob/main/path/to/file.go
```

This script:
- Parses the GitHub URL to extract owner, repo, ref (branch/tag/commit), and file path
- Uses `gh api` to fetch the file content from GitHub's API
- Decodes the base64-encoded content
- Returns clean source code without HTML wrapper

**Why use this instead of WebFetch:**
- WebFetch on GitHub URLs returns HTML with navigation, JavaScript, and GitHub UI
- This script returns only the raw file content
- Works for any branch, tag, or commit SHA
- Automatically handles base64 decoding

## GitHub API Usage

The `gh api` command provides direct access to GitHub's REST API.

**Basic pattern:**
```bash
gh api repos/{owner}/{repo}/contents/{path}
gh api repos/{owner}/{repo}/contents/{path}?ref=branch-name
```

**Using placeholders:**
The `gh` CLI automatically replaces `{owner}`, `{repo}`, and `{branch}` placeholders based on the current repository context or `GH_REPO` environment variable.

**Example - Get file content:**
```bash
# Returns JSON with base64-encoded content
gh api repos/owner/repo/contents/README.md

# Extract and decode content
gh api repos/owner/repo/contents/README.md --jq '.content' | base64 --decode
```

**Important API details:**
- API paths should NOT start with `/` (use `repos/...` not `/repos/...`)
- Use query parameters for optional fields: `?ref=branch&per_page=100`
- Use `--jq` to extract specific fields from JSON responses
- File content is base64-encoded in the API response

## Helper Scripts

### scripts/view_github_file.py

Fetches raw file content from GitHub URLs.

**Usage:**
```bash
python3 scripts/view_github_file.py <github-url>
```

**Example:**
```bash
python3 scripts/view_github_file.py https://github.com/golang/go/blob/master/README.md
```

**Supported URL formats:**
- `https://github.com/{owner}/{repo}/blob/{ref}/{path}`
- `https://github.com/{owner}/{repo}/tree/{ref}/{path}`

**Output:**
- Stderr: Status message indicating what's being fetched
- Stdout: Raw file content

### scripts/view_pr_files.py

Views files changed in a pull request.

**Usage:**
```bash
python3 scripts/view_pr_files.py <pr-number-or-url> [options]
```

**Options:**
- `--list`: List changed files only (no content)
- `--file <path>`: Show content for specific file
- `--diff`: Show full diff (default)

**Examples:**
```bash
# List files changed in PR
python3 scripts/view_pr_files.py 123 --list

# View full diff
python3 scripts/view_pr_files.py https://github.com/user/repo/pull/123

# View specific file from PR
python3 scripts/view_pr_files.py 123 --file src/main.go
```

## Fallback Strategies

If helper scripts fail (Python not available, import errors, etc.), fall back to direct `gh` CLI commands or HTTP requests.

### Viewing GitHub Files (Fallback)

**If `view_github_file.py` fails, use `gh api` directly:**
```bash
# Parse URL manually to extract: owner, repo, ref, path
# Then fetch with gh api
gh api repos/{owner}/{repo}/contents/{path}?ref={ref} --jq '.content' | base64 --decode
```

**Example:**
```bash
# URL: https://github.com/golang/go/blob/master/README.md
# Becomes:
gh api repos/golang/go/contents/README.md?ref=master --jq '.content' | base64 --decode
```

**If `gh` CLI fails, use HTTP requests:**
```bash
# Use curl or WebFetch to raw.githubusercontent.com
curl https://raw.githubusercontent.com/{owner}/{repo}/{ref}/{path}
```

**Example:**
```bash
curl https://raw.githubusercontent.com/golang/go/master/README.md
```

### Viewing PR Files (Fallback)

**If `view_pr_files.py` fails, use `gh pr` commands directly:**
```bash
# List changed files
gh pr view 123 --json files --jq '.files[].path'

# View diff
gh pr diff 123

# View specific file diff
gh pr diff 123 -- path/to/file.go
```

**To get file content from PR branch:**
```bash
# Get the head ref (branch name)
gh pr view 123 --json headRefName --jq '.headRefName'

# Fetch file content from that ref
gh api repos/{owner}/{repo}/contents/{path}?ref={head_ref} --jq '.content' | base64 --decode
```

### General Guidelines

When helper scripts fail:
1. **Try `gh` CLI directly** - Most script functionality can be replicated with `gh` commands
2. **Use `gh api` for API access** - Direct GitHub REST API access
3. **Fall back to HTTP requests** - Use `curl` or raw.githubusercontent.com URLs
4. **Report the error** - Let the user know the helper script failed and which fallback was used

**Common failure reasons:**
- Python not in PATH
- Missing Python dependencies (should be stdlib only, but environment issues can occur)
- Script file permissions
- Incorrect script path

## Common Workflows

### Reviewing a Pull Request

```bash
# 1. View PR details
gh pr view 123

# 2. List changed files
python3 scripts/view_pr_files.py 123 --list

# 3. Review specific files
python3 scripts/view_pr_files.py 123 --file path/to/file.go

# 4. View full diff
gh pr diff 123

# 5. Leave review
gh pr review 123 --approve --body "LGTM"
```

### Investigating GitHub File Links

When a user shares a GitHub URL like `https://github.com/user/repo/blob/main/src/server.go`:

```bash
# Fetch and analyze the file
python3 scripts/view_github_file.py https://github.com/user/repo/blob/main/src/server.go

# Then analyze the content as needed
```

### Checking CI/CD Status

```bash
# View recent workflow runs
gh run list --limit 5

# Check specific run
gh run view 789

# View logs if failed
gh run view 789 --log
```

## Troubleshooting

### gh: command not found

**Solution:** Install GitHub CLI from https://github.com/cli/cli#installation

### gh: Not Authenticated

**Solution:** Run `gh auth login` and follow the prompts

### API Rate Limiting

**Problem:** `gh api` returns 403 or rate limit errors

**Solution:**
- Authenticated requests have higher rate limits (5000/hour vs 60/hour)
- Check remaining quota: `gh api rate_limit`
- Wait or use a different authentication token

### File Not Found (404)

**Problem:** `gh api` returns 404 for file paths

**Possible causes:**
- File path is incorrect
- Branch/ref doesn't exist
- Private repository without access
- File was deleted or moved

**Solution:** Verify the file exists at the specified ref using GitHub web UI or `gh repo view`
