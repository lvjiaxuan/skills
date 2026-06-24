---
name: git-history-cleanup
description: Use when user needs to clean up messy Git commit history — squash vague or meaningless commits (WIP, chaos, "update"), reorganize or reword commit messages. Triggers on "clean up git history", "reorganize commits", "squash messy commits". Requires explicit commit hash range.
---

# Git History Cleanup

## Overview

Automate interactive rebase to squash and reword messy commits into a clean, meaningful history. Core approach: fully non-interactive execution via `GIT_SEQUENCE_EDITOR` + `GIT_EDITOR` PowerShell scripts — zero manual editing.

## When to Use

- Large number of WIP / chaos / meaningless commits that need consolidation
- Commit messages need standardization (e.g., Conventional Commits)
- Pre-release history cleanup
- **Not for:** branches with active collaborators unless force push is confirmed safe

## Prerequisites (MUST confirm before starting)

1. **Commit hash range**: User MUST provide `<START_HASH>` (exclusive base) and `<END_HASH>` (inclusive, usually HEAD). Example: `v1.11.0..HEAD` or `abc1234..def5678`.
2. **Force push allowed**: Confirm the repo allows force push (no other collaborators / not published).
3. **Backup strategy**: Create `backup/main-before-cleanup` branch before any changes.

If the user does NOT provide explicit hashes, **ask for them** — never guess the range.

## Workflow

### Step 1: Analyze

```bash
git log --oneline --reverse <START_HASH>..<END_HASH>
```

Identify commit groups to squash. Typical patterns:
- Multiple `chore: update deps` / `docs: update` → squash into one
- `wip` / `chaos` / `WIP` → squash into the nearest meaningful commit
- Release commits (`Release vX.Y.Z`) → keep as `pick`, mark for tag preservation

### Step 2: Backup

```bash
git branch backup/main-before-cleanup
git show-ref --tags  # record tag → hash mapping
```

### Step 3: Delete tags that will move

Tags on commits being rewritten must be deleted first and recreated after rebase.

```bash
git tag -d <tag-name>
```

### Step 4: Phase 1 — Squash (non-interactive)

Create `.git/rebase-todo-plan.txt` with the squash plan using `pick` and `fixup`:

```
pick <hash1> <msg>
fixup <hash2> <msg>
fixup <hash3> <msg>
pick <hash4> Release vX.Y.Z
...
```

Create the helper scripts from templates in [scripts/](scripts/):
- `seq-editor.ps1` — copies plan file to rebase todo
- `msg-editor.ps1` — writes predefined messages (Phase 2)
- `run-rebase.ps1` — orchestrates env vars + rebase command

**Key rules:**
- Each commit hash appears EXACTLY once in the todo
- `fixup` merges into the preceding `pick` (or result of prior fixups)
- Commit order must match the actual history (oldest first)

### Step 5: Phase 2 — Reword (non-interactive)

Update `.git/rebase-todo-plan.txt` with `reword` for commits needing new messages, `pick` for release commits:

```
reword <new-hash1> chore: update dependencies and docs
reword <new-hash2> feat: refactor project structure
pick <new-hash3> Release vX.Y.Z
```

The `msg-editor.ps1` script uses a counter file (`.git/reword-counter.txt`) and a predefined message array. Each reword triggers the editor once, consuming the next message.

**CRITICAL**: Use UTF-8 **without BOM** when writing commit messages:
```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($file, $content, $utf8NoBom)
```

### Step 6: Recreate tags

```bash
git tag <tag-name> <new-commit-hash>
```

### Step 7: Verify

```bash
# History looks clean
git log --oneline --decorate --reverse <START_HASH>..<END_HASH>

# No code lost
git diff backup/main-before-cleanup <END_HASH>  # must be empty

# All tags present
git tag -l
```

### Step 8: Push (user decides)

User manually pushes with `--force-with-lease` and handles tag updates / branch deletion / backup cleanup.

## Quick Reference

| Operation | Command |
|-----------|--------|
| Analyze history | `git log --oneline --reverse <START>..<END>` |
| Create backup | `git branch backup/main-before-cleanup` |
| Squash phase | `GIT_SEQUENCE_EDITOR` + plan file with `pick`/`fixup` |
| Reword phase | `GIT_EDITOR` + counter-based message array |
| Verify integrity | `git diff backup/... HEAD` — must be empty |
| Recreate tags | `git tag <name> <new-hash>` |

## Common Mistakes

| Problem | Fix |
|---------|-----|
| Env vars don't persist between shell calls | Use runner `.ps1` script (`run-rebase.ps1`) |
| UTF-8 BOM corrupts commit messages | `New-Object System.Text.UTF8Encoding($false)` |
| Forgot to delete tags before rebase | `git tag -d` before, recreate after |
| Commit hash duplicated or missing in todo | Each hash appears EXACTLY once |
| Temp files left behind | Clean `.git/*.ps1`, `reword-counter.txt`, `rebase-todo-plan.txt` after |

## Script Templates

Ready-to-customize templates in [scripts/](scripts/): `seq-editor.ps1`, `msg-editor.ps1`, `run-rebase.ps1`. Customize per-run: commit hashes in plan file, message array in msg-editor.

## Example

**Before** (28 messy commits):
```
chore: update, chore: WIP, docs: update, wip, chore: chaos, ...
```

**After** (11 clean commits):
```
chore: update dependencies and docs
feat: refactor project structure and pipeline renames
Release v1.12.0
fix: resolve issue #24 and update dependencies
Release v1.12.1
chore: update dependencies and docs
feat: improve OXLint options handling and add deny options
feat: add respectjs4ts rules
Release v1.13.0
fix: improve lv() params type
chore: refactor plugin package and update dependencies
```
