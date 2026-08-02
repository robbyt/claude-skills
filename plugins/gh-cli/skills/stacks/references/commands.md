# `gh stack` command reference

**Extension:** `github/gh-stack` **v0.1.0** · **Snapshot:** 2026-08-02 · Public preview.

This feature is evolving. If anything here doesn't match your install, run
`gh stack <command> --help` and trust the CLI over this file. The `alias` and `feedback`
utility subcommands are intentionally omitted.

## Table of contents

- [Core workflow commands](#core-workflow-commands)
- [Navigation](#navigation)
- [Interactive vs. non-interactive behavior](#interactive-vs-non-interactive-behavior)
- [Destructive / remote-mutating effects](#destructive--remote-mutating-effects)
- [Recovery](#recovery)
- [Merge methods & merge queue](#merge-methods--merge-queue)
- [Stack-base evaluation rule](#stack-base-evaluation-rule)
- [Troubleshooting](#troubleshooting)

## Core workflow commands

| Command | Purpose | Key flags |
|---|---|---|
| `gh stack init [branches...]` | Start a new stack; adopts existing branches, creates missing ones (bottom-to-top). Bottom branch is based on the trunk. | `-b, --base <branch>` set trunk (default: repo default branch) |
| `gh stack add [branch]` | Add a new branch on top of the current stack. | `-A, --all` stage all incl. untracked; `-u, --update` stage tracked only; `-m, --message <msg>` commit with message (auto-names branch if no name) |
| `gh stack view` | Show the stack + PR status. | `-s, --short` compact; `--json` machine-readable |
| `gh stack submit` | Push branches, create/update PRs, fix PR bases, create/update the stack object. | `--auto` skip editor (new PRs → drafts); `--open` mark ready; `--remote <name>` |
| `gh stack rebase [branch]` | Cascading rebase so each branch contains the tip of the one below. | `--downstack`, `--upstack`, `--no-trunk`, `--continue`, `--abort`, `--committer-date-is-author-date`/`--preserve-dates`, `--remote` |
| `gh stack push` | Push active branches with per-branch `--force-with-lease`. **Not atomic** — skips merged/queued branches. | `--remote <name>` |
| `gh stack sync` | Fetch, reconcile remote stack, fast-forward trunk, cascade-rebase, push **atomically** (`--force-with-lease --atomic`), sync PR state. | `--prune` delete merged local branches; `--remote <name>` |
| `gh stack merge [<stack#>\|<pr#>]` | Atomic bottom-up merge through the selected PR. | `--yes`, `--squash`/`--merge`/`--rebase`, `--merge-method <m>` |
| `gh stack modify` | Interactive TUI: drop / fold / insert / reorder / rename. | `--continue`, `--abort` |
| `gh stack checkout [<stack#>\|<pr#>\|<pr-url>\|<branch>]` | Check out a stack/branch; no arg → interactive picker; can fetch a remote-only stack. | — |
| `gh stack unstack [<stack#>]` | Dissolve a stack on GitHub + remove local tracking. | `--local` local tracking only (leave remote untouched) |
| `gh stack link <refs...>` | Create/update a stack on GitHub from branch/PR/URL refs (bottom-to-top) **without** local tracking — for jj/Sapling/ghstack/git-town users. | — |

## Navigation

All skip merged branches automatically.

| Command | Moves to |
|---|---|
| `gh stack down [n]` | `n` branches toward the trunk (default 1) |
| `gh stack up [n]` | `n` branches away from the trunk (default 1) |
| `gh stack bottom` | bottom branch (closest to trunk) |
| `gh stack top` | top branch (furthest from trunk) |
| `gh stack trunk` | the trunk branch |
| `gh stack switch` | **interactive** branch picker — avoid in automation; use the above or `checkout <ref>` |

## Interactive vs. non-interactive behavior

Several commands prompt or open a TUI in a terminal. For agents, prefer the explicit form:

| Command | Interactive default | Agent-safe form |
|---|---|---|
| `submit` | single-screen editor | `gh stack submit --auto` (drafts) / `--auto --open` (ready) |
| `merge` | wizard (choose cutoff/method/confirm) | `gh stack merge [<n>] --yes --<method>` (**needs user authorization**) |
| `checkout` (no arg) | picker of all stacks | pass an explicit `<branch>`/`<pr>`/`<stack#>` |
| `switch` | picker | `down`/`up`/`top`/`bottom`/`trunk` or `checkout <ref>` |
| `modify` | TUI (no non-interactive form) | surface to the user; run `submit` after |
| `sync` (diverged) | prompts to resolve | aborts non-interactively — resolve divergence first, never force |
| `view` | full view | `--short` / `--json` |

## Destructive / remote-mutating effects

| Command | Effect |
|---|---|
| `submit` | Pushes branches; creates/updates PRs; changes PR base branches; creates/updates the remote stack object. |
| `push` | Force-with-lease per branch (rewrites remote branch tips). Non-atomic — partial success possible. |
| `sync` | Fast-forwards trunk, cascade-rebases, atomic force-push; `--prune` **deletes local branches**. |
| `merge` | Merges PRs (or enqueues them) into the base branch — irreversible. |
| `rebase` | Rewrites local commits across the stack (branch tips move). |
| `modify` | Rewrites stack structure; requires `submit` afterward to reflect on GitHub. |
| `unstack` | Dissolves the stack on GitHub and/or drops local tracking. |
| `link` | Creates/updates a remote stack object. |

## Recovery

- **Rebase conflict:** resolve markers → `git add .` → `gh stack rebase --continue`; or
  `gh stack rebase --abort` to restore all branches.
- **Modify interrupted/conflict:** `gh stack modify --continue` after resolving, or
  `gh stack modify --abort` to restore the pre-modify snapshot.
- **Sync conflict:** all branches are restored to their original state; run
  `gh stack rebase` to resolve interactively, then `gh stack push`.
- **Partial push:** `gh stack push` may leave some branches updated and others rejected.
  Inspect `gh stack view` to see what moved, fix the rejected branch, and run it again —
  already-updated branches stay unchanged.

## Merge methods & merge queue

- Methods: `--merge` (merge commit), `--squash` (one squashed commit per PR), `--rebase`
  (replay commits), or `--merge-method <merge|squash|rebase>`. **Always name one
  non-interactively** — otherwise the extension reuses its last-used method.
- `gh stack merge` is atomic and bottom-up through the chosen PR; nothing above it merges.
- Merge queue: the stack is added together; the queue allows a merge group to exceed its
  max size by up to 50% to keep a stack intact, splitting across consecutive groups if
  needed. If a PR is ejected, everything above it is ejected too. A queued stack is
  **queued, not landed** — don't report it as merged until GitHub confirms completion.

## Stack-base evaluation rule

Branch protection, required reviews, required status checks, CODEOWNERS, code scanning, and
Actions (`on: pull_request` targeting the trunk) are all evaluated against the **stack
base** (the trunk), not the branch directly below. Consequences:

- Every mid-stack PR is held to the trunk's standard.
- A PR merges only when it **and every PR below it** satisfy those requirements and the
  stack has a fully linear history.
- `github.event.pull_request.stack` exposes stack metadata in workflow expressions (present
  only for PRs in a stack).

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Rebase reports a conflict | Resolve → `git add` → `gh stack rebase --continue`, or `--abort`. |
| Sync stopped on a conflict | Branches restored; run `gh stack rebase` then `gh stack push`. |
| `gh stack modify` won't start | Needs a clean tree, an active stack, no in-progress rebase, no queued merge, linear history. Run `gh stack rebase` first if history isn't linear. |
| `modify` interrupted | `gh stack modify --abort` restores the pre-modify snapshot. |
| A PR can't be merged | It or a PR below it fails a required check/review, or history isn't linear. Run `gh stack rebase` + `gh stack push`. |
| Merge stopped partway | PRs below the failure stay landed; the failed PR and everything above stay open. Fix the failed PR and retry. |
| PR removed from the merge queue | Everything above it is ejected too. Re-add the stack once the cause is fixed. |
| Closed a mid-stack PR | Blocks every PR above it; dissolve/restructure with `gh stack unstack` or `gh stack modify`, then re-submit. |
| Commits unsigned after a rebase | The website/server-side rebase is unsigned. Rebase locally with `gh stack rebase` (uses your local signing config), then `gh stack push`. |
| "cross-fork" / different-repo error | Not supported — all branches must be in the same repository. |
| An untouched PR suddenly reports `CONFLICTING` / `DIRTY` | Likely a **phantom conflict**: the parent was rebased (new SHAs) and this branch was parented to an orphaned SHA. `git fetch`, look for `(forced update)`; compare commit **subjects** not SHAs. Same subject + different SHA → don't hand-resolve; run `gh stack checkout <pr#>` → `gh stack sync` (dedups by patch-id). Prevent by extending stacks with `gh stack add`, never bare `git checkout -b`. |
| `gh stack view` shows old SHAs | `view` reflects **local** tips, which go stale after someone else syncs. `git fetch` first. |
| Squash-merge closed a child PR | Deleting a merged PR's branch (`--delete-branch`) can close children based on it. Reparent children (or re-sync) before deleting, or delete last. |
