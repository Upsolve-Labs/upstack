---
name: upgrade
description: |
  Self-upgrade bstack by pulling the latest version from the git repo.
  Backs up before upgrading.
disable-model-invocation: true
---

# Upgrade

## Locate Installation
1. Check if `~/.bstack` exists and is a git repo.
2. If not: follow symlinks from `~/.claude/skills/advisor` to find the repo root.
3. If neither works: report "bstack not installed via git clone. Re-clone to upgrade."

## Current Version
Read VERSION from the repo root. Print it.

## Backup
Copy the repo to `<repo>-backup-YYYYMMDD-HHMMSS`. Keep only the 3 most recent backups (delete older ones).

## Pull Latest
`git -C <repo> pull --rebase origin main`

If pull fails (conflicts): restore from backup, report the error. Never force-pull.

## Verify
1. Read new VERSION file.
2. `git -C <repo> log --oneline <old-version-tag>..HEAD` to show what changed.
3. Check that skill symlinks in `~/.claude/skills/` still resolve.

## Report
Print: version change, list of new commits, symlink status.
