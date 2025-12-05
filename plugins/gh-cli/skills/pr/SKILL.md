---
name: pr
description: Pull request operations using GitHub CLI. Trigger when user wants to list PRs ("show open PRs"), view PR details ("view PR 123"), create PRs ("create a pull request"), review/merge PRs ("merge PR", "approve PR"), or view PR diffs ("show PR diff", "what files changed in PR").
---

# Pull Request Operations

Manage pull requests with the `gh` CLI.

## Prerequisites

GitHub CLI must be installed and authenticated:
```bash
gh auth status
```

## Quick Reference

```bash
gh pr list                          # List open PRs
gh pr view 123                      # View PR details
gh pr create --fill                 # Create PR from commits
gh pr merge 123 --squash            # Merge PR
gh pr diff 123                      # View diff
```

## List PRs

```bash
gh pr list --state open
gh pr list --author @me
gh pr list --label "needs-review"
```

## View PR Details

```bash
gh pr view 123
gh pr view 123 --json title,body,state,files
```

## Create PR

```bash
gh pr create --title "Feature" --body "Description"
gh pr create --fill  # Use commit messages
```

## Review and Merge

```bash
gh pr review 123 --approve
gh pr review 123 --approve --body "LGTM"
gh pr merge 123 --squash
gh pr merge 123 --merge
```

## View PR Diff

```bash
gh pr diff 123
gh pr diff 123 -- path/to/file.go   # Specific file
```

## Helper Script: View PR Files

List or view files changed in a PR:

```bash
# List changed files
python3 scripts/view_pr_files.py 123 --list
python3 scripts/view_pr_files.py https://github.com/user/repo/pull/123 --list

# View full diff
python3 scripts/view_pr_files.py 123 --diff

# View specific file content from PR branch
python3 scripts/view_pr_files.py 123 --file path/to/file.go
```

### Fallback (if script fails)

```bash
# List changed files
gh pr view 123 --json files --jq '.files[].path'

# View diff
gh pr diff 123

# Get file content from PR branch
gh pr view 123 --json headRefName --jq '.headRefName'
gh api repos/{owner}/{repo}/contents/{path}?ref={head_ref} --jq '.content' | base64 --decode
```
