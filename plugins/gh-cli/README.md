# gh-cli

Interacts with GitHub repositories using the GitHub CLI (`gh`).

## Setup

Install and authenticate the GitHub CLI before using this plugin. See the [official installation guide](https://cli.github.com/).

```bash
gh auth login
gh auth status  # verify authentication
```

## Triggers

- Explicit `gh` mentions: "use gh to create a PR", "run gh issue list"
- Natural language GitHub operations: "show me open issues", "create a pull request"
- GitHub file URLs: "view this file https://github.com/user/repo/blob/main/file.go"

## Examples

**Pull Requests:**
```
"Show me all open PRs" → gh pr list --state open
"Create a PR for my current branch" → gh pr create --fill
"What files changed in PR #123?" → view_pr_files.py 123 --list
```

**Issues:**
```
"Create an issue for the login bug" → gh issue create --title "..." --body "..."
"Show me all bugs assigned to me" → gh issue list --label bug --assignee @me
```

**GitHub Actions:**
```
"Check if CI is passing" → gh run list --limit 5
```

## Helper Scripts

### `scripts/view_github_file.py`

Fetches raw file content from GitHub URLs without HTML markup.
- Parses GitHub URLs to extract owner, repo, ref, and file path
- Uses `gh api` to fetch content
- Decodes base64-encoded content

### `scripts/view_pr_files.py`

Analyzes files changed in pull requests.
- Lists all files changed in a PR
- Shows diff for specific files
- Displays file content from PR branch
