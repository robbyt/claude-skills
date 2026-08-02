---
name: stacks
description: Stacked pull requests with the GitHub CLI `gh stack` extension. Trigger whenever the user wants to split a large branch or change into a chain of dependent PRs ("stack this into smaller PRs", "split this into a stack", "create a stacked PR", "break this feature into reviewable layers"), or manage an existing stack ("add a layer on top", "rebase my stack", "sync the stack after the bottom PR merged", "merge the stack"). Use this instead of the `pr` skill whenever the work involves more than one dependent PR or any `gh stack` command; use `pr` for single, standalone pull requests.
---

# Stacked Pull Requests via `gh stack`

A **stack** is a chain of small PRs where each targets the branch below it, and the whole
chain lands on a **trunk** (usually `main`). Instead of one giant diff, reviewers get
focused, independently reviewable layers. This is the antidote to the un-reviewable
"here's 4,000 lines of AI-generated code" PR.

Use this skill for any multi-PR dependent chain or any `gh stack …` command. For a single
standalone PR, use the `pr` skill instead.

## Preview status & constraints (read before you start)

- **Public preview**, extension **`github/gh-stack` v0.1.0** (snapshot: 2026-08-02).
  Behavior may change — if a command or flag here doesn't match reality, run
  `gh stack <command> --help` and trust that.
- **Trunk** = the base branch of the *bottom* PR. Defaults to the repo's default branch;
  set a different one with `--base`.
- **Same-repository only** — no cross-fork stacks. Not supported in GitHub Desktop.
- **Stack-base evaluation rule (surprising, important):** branch protection, required
  checks, CODEOWNERS, code scanning, and Actions are evaluated against the **stack base**
  (the trunk), *not* the branch directly below. Every mid-stack PR is held to the trunk's
  standard, and a PR merges only after every PR below it also passes.
- **Linear history is mandatory** before merging. Closing a mid-stack PR blocks every PR
  above it.

## Assume the extension is installed

Just run `gh stack …`. **Don't** run a detect/install check on every invocation — it adds
latency and noise for the common case. Base requirements: `gh` ≥ 2.90, git ≥ 2.20, and
`gh auth status` authenticated.

**Only if a `gh stack` command actually fails, diagnose before installing anything:**

| Failure | Response |
|---|---|
| `unknown command "stack"` / extension not found | Offer `gh extension install github/gh-stack` — **ask the user first** (it downloads and runs third-party code). |
| A documented command/flag is missing | Preview drift — offer an approval-gated `gh extension upgrade gh-stack` (not a reinstall). |
| `gh` < 2.90 or git < 2.20 | Report the version prerequisite; installing the extension won't fix it. |
| Auth / repo / divergence / network error | Do **not** suggest installing anything — fix the actual error. |

`gh skill install github/gh-stack` is *not* a prerequisite — that installs GitHub's own
agent skill; this skill is your guidance.

## Design the stack first

Order layers by dependency, foundation at the bottom, each layer a single coherent change
small enough to review on its own. A reader should be able to go bottom-to-top and watch
the feature come together. Example for "add user auth":

1. data model + migration → 2. CRUD endpoints → 3. JWT middleware/guards → 4. tests

## Build a stack

Lifecycle — don't skip the "commit each layer" step or you'll create empty/mislayered
branches:

```
verify clean tree → choose trunk + bottom-to-top branch names → init (or adopt existing)
→ implement & commit layer → add next branch from the current top → gh stack view → submit
```

```bash
# Start a new stack (bottom branch based on the trunk)
gh stack init auth-model

# ...or create/adopt several layers bottom-to-top in one shot
gh stack init --base main auth-model auth-endpoints auth-middleware

# Add the next layer on top of the current top branch.
# -A stages ALL changes (incl. untracked) — prefer a deliberate `git add` of just this
# layer's files so unrelated work isn't swept in, then:
gh stack add -m "Add CRUD endpoints" auth-endpoints

# Inspect before submitting
gh stack view --short

# Create/update the PRs. In a terminal this opens an editor; pass --auto to skip it.
gh stack submit --auto          # new PRs as drafts
gh stack submit --auto --open   # new PRs marked ready for review
```

**Use `gh stack submit`, not `gh pr create`, for stack branches** — `submit` pushes
branches, creates/updates each PR, fixes PR base branches, and creates/updates the stack
object on GitHub. `gh pr create` does none of the stack wiring.

## Change a lower layer

Fix the layer where the change belongs, not at the top — a fix on the wrong branch
corrupts the diffs of every branch above it.

```bash
git status && gh stack view --short   # know where you are first
gh stack checkout auth-model          # or: gh stack down
# ...confirm you're on the intended branch, then edit + commit HERE...
git add <this-layer's-files> && git commit -m "Fix token expiry handling"
gh stack rebase --upstack             # carry the fix up into the branches above
gh stack push
gh stack top                          # return to where you were working
```

## Keep a linear history (rebase)

Merging requires a linear history; restore it with a cascading rebase, then push.

```bash
gh stack rebase            # cascade bottom→top (also: --downstack, --upstack, --no-trunk)
gh stack push
```

On conflict: resolve the markers → `git add .` → `gh stack rebase --continue`. To bail
out: `gh stack rebase --abort` (restores all branches).

**Signed commits:** the website "Rebase stack" button rebases server-side and produces
**unsigned** commits. If the repo requires signed commits, rebase locally with
`gh stack rebase` so commits follow your local signing config.

### Rebasing rewrites SHAs — beware phantom conflicts

Every rebase/sync replays commits onto a new base, giving them **new SHAs** (same content,
new identity). A branch that was cut from an *old* SHA is now parented to a commit that no
longer exists on the remote, and **GitHub reports this as a merge conflict even though the
contents agree** — a phantom conflict.

- **Prevention:** extend a stack only with `gh stack add`, **never a bare `git checkout -b`
  off a stack branch.** A branch the stack tracks is carried along by every sync; one it
  doesn't track silently rots.
- **`gh stack view` shows your *local* tips, which can be stale** after someone else syncs.
  Run `git fetch` first, or read `view` as "what my machine believes," not "what GitHub has."
- **Diagnose before resolving:** `git fetch` and look for a `(forced update)` line on the
  parent; then compare commit **subjects** across the divide, not SHAs
  (`git log --oneline HEAD..origin/<parent>` vs `origin/<parent>..HEAD`). Same subjects +
  different SHAs = phantom conflict. **Never hand-resolve a conflict whose two sides are the
  same change** — you'd be merging a change with itself. Instead let the cascade fix it:
  `gh stack checkout <pr#>` (import if untracked) → `gh stack view` → `gh stack sync`
  (rebase drops the duplicates by patch-id and replays only the genuinely new commits).

## Push is not atomic

`gh stack push` does per-branch `--force-with-lease`; one branch can update while another
is rejected (merged/queued branches are skipped). **A push failure does not mean nothing
changed** — inspect `gh stack view` to see which branches moved before retrying. Contrast:
`gh stack sync` pushes **atomically** (`--force-with-lease --atomic`).

## Sync after merges (with preconditions)

`gh stack sync` fetches, reconciles the remote stack, fast-forwards the trunk,
cascade-rebases the remaining branches, pushes atomically, and syncs PR state. `--prune`
also deletes local branches for merged PRs.

It is **not categorically safe** — before running it confirm: clean worktree, correct
repo/remote, no unexpected local-only commits, and the stack isn't diverged. Prefer plain
`gh stack sync`; add `--prune` **only with explicit user authorization** (it deletes local
branches). A diverged stack aborts non-interactively rather than guessing.

```bash
gh stack sync            # safe reconcile after a bottom PR merges
gh stack sync --prune    # + delete merged local branches (needs authorization)
```

## Merge (bottom-up, via the CLI)

Merging is a real CLI command — not website-only. `gh stack merge [<stack#>|<pr#>]` merges
everything from the bottom **up to and including** the selected PR in one all-or-nothing
operation; GitHub auto-retargets the next layer.

```bash
gh stack view --short                 # ALWAYS preview the cutoff first
gh stack merge 2 --yes --squash       # merge through the 2nd layer, squash, no prompt
```

Merge-safety rules — an agent gets these wrong easily:

- **Preview first** with `gh stack view --short`/`--json`.
- **Cutoff semantics:** selecting PR N merges N and everything **below** it, nothing above.
- **Bare-number ambiguity:** a bare number resolves as a **stack number before a PR
  number**. Verify what `gh stack merge 42` actually targets before confirming.
- **Always name the method** non-interactively (`--squash` / `--merge` / `--rebase` /
  `--merge-method`) — otherwise the extension reuses its last-used method (hidden state).
  Use the repo-approved method; don't assume squash.
- **`--yes` is non-interactive — require explicit user authorization** before using it.
- **Don't loop `gh pr merge` manually** — that loses atomicity and merge-queue grouping.
- The CLI does only basic local prechecks (open, not draft). **GitHub evaluates branch
  protection and rules server-side**, against the stack base; bypassing isn't supported
  for stacks. Surface any server-side failure back to the user.
- **Queued ≠ landed:** if the base uses a merge queue, a "success" means *queued*. Report
  queued-vs-completed accurately; queue ejection cascades upward. Reserve the word
  "atomic" for the actual server-side merge, not a queued grouping.
- **Don't auto-rebase/push** just because a merge reports non-linear history — those
  rewrite remote branches and need their own authorization. After a completed merge,
  inspect status, then plain `gh stack sync` (`--prune` only with authorization).

## Restructure

`gh stack modify` opens an **interactive TUI** (drop / fold / insert / reorder / rename).
It's not scriptable non-interactively — surface restructuring to the user rather than
attempting to drive it. After a modify session, run `gh stack submit` (not just `push`) so
PR bases and stack metadata update. `gh stack unstack` dissolves a stack.

## Interactive vs. agent-safe commands

Several subcommands prompt or open a TUI. Prefer the non-interactive form:

| Command | Default | Agent-safe form |
|---|---|---|
| `submit` | opens editor | `gh stack submit --auto` / `--auto --open` |
| `merge` | interactive wizard | `gh stack merge [<n>] --yes --squash` (with authorization) |
| `checkout` (no arg) | interactive picker | pass an explicit `<branch>`/`<pr>`/`<stack#>` |
| `switch` | interactive | use `down`/`up`/`top`/`bottom`/`trunk`, or `checkout <x>` |
| `modify` | TUI only | not scriptable — surface to user; run `submit` after |
| `sync` (diverged) | prompts; aborts non-interactively | never force; resolve divergence first |
| `view` | interactive view | `gh stack view --short` / `--json` — your go-to inspector |

## More detail

See `references/commands.md` for the full command/flag reference, per-command destructive
effects, recovery steps, and a troubleshooting table.
