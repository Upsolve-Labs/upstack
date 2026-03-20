---
name: ship-pr
description: |
  Ship a feature branch: write docs, bump version, create PR with screenshots
  and evidence. Links Linear tickets if available. Use when ready to merge.
disable-model-invocation: true
---

# Ship PR

Three-in-one: documentation, versioning, and PR creation. No confirmation pauses once the version is decided.

## Pre-flight (abort if any fail)
1. Working tree is clean.
2. On a feature branch (not main/master).
3. All commits are pushed (or will be pushed).
4. `gh` CLI is available and authenticated.
5. Tests pass.

If any check fails: report and stop. Do not ask to continue.

## Step 1: Documentation
Write or update docs for the feature set that was built. Keep docs close to the code — update existing doc files rather than creating new ones where possible.

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
3. Create PR via `gh pr create`. PR description includes:
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
