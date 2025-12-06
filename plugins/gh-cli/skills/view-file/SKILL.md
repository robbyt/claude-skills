---
name: view-file
description: Fetch raw file content from GitHub URLs. Trigger when user shares a GitHub file link (https://github.com/user/repo/blob/main/file.go) and wants to view the source code. Avoids HTML/JS clutter from WebFetch.
---

# View GitHub Files

Fetch raw file content from GitHub URLs without HTML/JS clutter.

## Prerequisites

GitHub CLI must be installed and authenticated:
```bash
gh auth status
```

## When to Use

When a user shares a GitHub file URL like:
- `https://github.com/user/repo/blob/main/src/file.go`
- `https://github.com/user/repo/tree/v1.0/docs/README.md`

Use this skill instead of WebFetch to get clean source code.

## Helper Script

```bash
python3 scripts/view_github_file.py https://github.com/user/repo/blob/main/path/to/file.go
```

The script:
- Parses the GitHub URL to extract owner, repo, ref, and path
- Uses `gh api` to fetch file content
- Decodes base64-encoded response
- Returns clean source code

## Supported URL Formats

```
https://github.com/{owner}/{repo}/blob/{ref}/{path}
https://github.com/{owner}/{repo}/tree/{ref}/{path}
```

Where `{ref}` can be a branch name, tag, or commit SHA.

## Fallback (if script fails)

Parse the URL manually and use `gh api`:

```bash
# From URL: https://github.com/golang/go/blob/master/README.md
# Extract: owner=golang, repo=go, ref=master, path=README.md
gh api repos/golang/go/contents/README.md?ref=master --jq '.content' | base64 --decode
```

Or use raw.githubusercontent.com:

```bash
curl https://raw.githubusercontent.com/golang/go/master/README.md
```
