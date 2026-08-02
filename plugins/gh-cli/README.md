# gh-cli

GitHub CLI integration with focused skills for pull requests, stacked pull requests, issues, GitHub Actions, repository info, and viewing GitHub file URLs.

## Setup

Install and authenticate the GitHub CLI before using this plugin. See the [official installation guide](https://cli.github.com/).

```bash
gh auth login
gh auth status  # verify authentication
```

The `stacks` skill additionally uses the [`gh-stack`](https://github.com/github/gh-stack) extension (public preview). It's assumed already installed; if a `gh stack` command reports the extension is missing, install it with `gh extension install github/gh-stack`.

## Skills

### pr

Pull request operations.

**Triggers:** "show open PRs", "view PR 123", "create a pull request", "merge PR", "approve PR", "show PR diff", "what files changed in PR"

**Examples:**
```
"Show me all open PRs" → gh pr list --state open
"Create a PR for my current branch" → gh pr create --fill
"What files changed in PR #123?" → view_pr_files.py 123 --list
```

### stacks

Stacked pull requests via the `gh stack` extension — split a large change into a chain of small, independently reviewable PRs.

**Triggers:** "stack this into smaller PRs", "split this branch into a stack", "create a stacked PR", "add a layer on top of the stack", "rebase my stack", "sync the stack", "merge the stack"

**Examples:**
```
"Split this auth work into a stack of PRs" → gh stack init … → add … → submit --auto
"Fix the middle layer and carry it up" → gh stack checkout … → commit → rebase --upstack → push
"Merge the stack through PR 2" → gh stack merge 2 --yes --squash
```

### issues

Issue management.

**Triggers:** "show open issues", "view issue 456", "create an issue", "file a bug", "close issue", "add label to issue"

**Examples:**
```
"Create an issue for the login bug" → gh issue create --title "..." --body "..."
"Show me all bugs assigned to me" → gh issue list --label bug --assignee @me
```

### actions

GitHub Actions workflow management.

**Triggers:** "check CI", "is the build passing", "show recent runs", "view action logs", "watch CI", "rerun the build"

**Examples:**
```
"Check if CI is passing" → gh run list --limit 5
"Show me the failed workflow logs" → gh run view 789 --log-failed
```

### repo

Repository information (read-only).

**Triggers:** "show repo info", "what's this repo about", "list my repos", "show repos for user", "stars", "languages", "topics"

**Examples:**
```
"How many stars does this repo have?" → gh repo view --json stargazersCount
"List all Go repos for user X" → gh repo list X --language go
```

### view-file

Fetch raw file content from GitHub URLs without HTML/JS clutter.

**Triggers:** User shares a GitHub file URL like `https://github.com/user/repo/blob/main/file.go`

**Examples:**
```
"View this file https://github.com/golang/go/blob/master/README.md"
→ view_github_file.py https://github.com/golang/go/blob/master/README.md
```

## Helper Scripts

### `pr/scripts/view_pr_files.py`

Analyzes files changed in pull requests.
- Lists all files changed in a PR
- Shows diff for specific files
- Displays file content from PR branch

### `view-file/scripts/view_github_file.py`

Fetches raw file content from GitHub URLs.
- Parses GitHub URLs to extract owner, repo, ref, and file path
- Uses `gh api` to fetch content
- Decodes base64-encoded content
