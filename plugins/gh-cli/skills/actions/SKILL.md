---
name: actions
description: GitHub Actions workflow management using GitHub CLI. Trigger when user wants to check CI status ("check CI", "is the build passing"), view workflow runs ("show recent runs", "view action logs"), watch running workflows ("watch CI"), or rerun failed workflows ("rerun the build").
---

# GitHub Actions

Monitor and manage GitHub Actions workflows with the `gh` CLI.

## Prerequisites

GitHub CLI must be installed and authenticated:
```bash
gh auth status
```

## Quick Reference

```bash
gh run list                         # List recent runs
gh run view 789                     # View run details
gh run view 789 --log               # View run logs
gh run watch 789                    # Watch running workflow
gh run rerun 789                    # Rerun workflow
```

## List Workflow Runs

```bash
gh run list
gh run list --limit 10
gh run list --workflow ci.yml
gh run list --status failure
gh run list --branch main
```

## View Run Details

```bash
gh run view 789
gh run view 789 --json status,conclusion,jobs
```

## View Run Logs

```bash
gh run view 789 --log
gh run view 789 --log-failed  # Only failed job logs
```

## Watch Running Workflow

```bash
gh run watch 789
gh run watch 789 --exit-status  # Exit with workflow status code
```

## Rerun Workflows

```bash
gh run rerun 789
gh run rerun 789 --failed  # Rerun only failed jobs
```

## List Workflows

```bash
gh workflow list
gh workflow view ci.yml
```
