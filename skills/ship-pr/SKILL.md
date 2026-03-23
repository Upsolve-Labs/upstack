---
name: ship-pr
description: |
  Ship a feature branch: write docs, bump version, create PR with screenshots
  and evidence. Links Linear tickets if available. Use when ready to merge.
disable-model-invocation: true
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Ship PR

Three-in-one: documentation, versioning, and PR creation. No confirmation pauses once the version is decided.

## Pre-flight (abort if any fail)
1. Working tree is clean.
2. On a feature branch (not main/master). If on main/master, auto-create a branch named after the work (e.g., `feat/short-description` or `fix/short-description` based on the changes) and switch to it before continuing.
3. All commits are pushed (or will be pushed).
4. `gh` CLI is available and authenticated.
5. Tests pass.

If any check fails (other than #2, which is auto-resolved): report and stop. Do not ask to continue.

## Step 1: Documentation (do not skip)
Review and update these. Report each as UPDATED or NO CHANGE NEEDED (with reason):
1. README.md — does it reflect the new feature/fix?
2. CHANGELOG.md — will be updated in Step 2, but note the entry now.
3. Any `docs/` folder or inline doc comments in changed files.
4. CLAUDE.md — if conventions or workflow changed.

Keep docs close to the code — update existing doc files rather than creating new ones where possible. At minimum, review each item above and report your finding.

## Step 2: Version + Changelog
AskUserQuestion — the ONLY interactive step:
"Current version: [X.Y.Z]. Changes suggest [type]. Which version?
1. Patch (X.Y.Z+1) — bug fixes
2. Minor (X.Y+1.0) — new features, backward compatible
3. Major (X+1.0.0) — breaking changes
4. Skip version bump"

Update VERSION, package.json, or pyproject.toml (whichever exists). Update CHANGELOG.md.

## Step 3: PR Creation (no pauses from here)
1. Commit version + changelog + docs: `chore: bump to vX.Y.Z`
2. Push branch to remote.
3. Check for existing PR: `gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number'`
   - **If PR exists:** Skip `gh pr create` — the push already updated the PR. Optionally run `gh pr comment <number> --body "..."` summarizing the new changes.
   - **If no PR exists:** Create PR via `gh pr create`. PR description includes:
     - Feature summary
     - Screenshots from `evidence/screenshots/` using `![name](url?raw=true)` format
     - API examples from `evidence/api/` or link to collection
     - Linear ticket references if available (list and link them)
4. Mark completed items in TODO.md as done.

## On Failure
Report which step completed and which failed. Do NOT attempt to rollback.

## Linear Integration
If `mcp__linear__*` tools are available:
- Link the PR to relevant Linear issues found in TODO.md (`LINEAR: ENG-xxx` references).
- List linked tickets in the PR description.
