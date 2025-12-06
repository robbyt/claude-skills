---
name: issues
description: GitHub issue management using GitHub CLI. Trigger when user wants to list issues ("show open issues"), view issue details ("view issue 456"), create issues ("create an issue", "file a bug"), or edit/close issues ("close issue", "add label to issue").
---

# Issue Management

Manage GitHub issues with the `gh` CLI.

## Prerequisites

GitHub CLI must be installed and authenticated:
```bash
gh auth status
```

## Quick Reference

```bash
gh issue list                       # List open issues
gh issue view 456                   # View issue details
gh issue create --title "Bug"       # Create issue
gh issue close 456                  # Close issue
```

## List Issues

```bash
gh issue list
gh issue list --state open
gh issue list --label bug
gh issue list --assignee @me
gh issue list --state all --limit 50
```

## View Issue

```bash
gh issue view 456
gh issue view 456 --json title,body,labels,state
```

## Create Issue

```bash
gh issue create --title "Bug report" --body "Details"
gh issue create --label bug --assignee @me
gh issue create --title "Feature" --label enhancement
```

## Edit Issue

```bash
gh issue edit 456 --title "Updated title"
gh issue edit 456 --add-label "needs-review"
gh issue edit 456 --remove-label "in-progress"
gh issue edit 456 --add-assignee @me
```

## Close and Reopen

```bash
gh issue close 456
gh issue close 456 --reason "not planned"
gh issue reopen 456
```
