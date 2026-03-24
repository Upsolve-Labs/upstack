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

### Screenshot Check (run before creating or updating the PR)
- If the diff includes files in UI/frontend packages AND `evidence/screenshots/`
  is empty or missing: STOP and warn the user. Recommend running /validate
  or capturing screenshots now.
- If screenshots exist: continue and embed them in the PR body using absolute GitHub blob URLs.
- Organize screenshots by feature or mode (e.g., "Docker mode" vs "Sprites mode").

1. Commit version + changelog + docs: `chore: bump to vX.Y.Z`
2. Push branch to remote.
3. Check for existing PR: `gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number'`
   - **If PR exists:** Skip `gh pr create` — the push already updated the PR. Optionally run `gh pr comment <number> --body "..."` summarizing the new changes.
   - **If no PR exists:** Create PR via `gh pr create`. PR description includes:
     - Feature summary
     - Screenshots (see Screenshot Embedding below)
     - API examples from `evidence/api/` or link to collection
     - **Closes / Addresses section** (MANDATORY — always include, even if empty):
       - TODOS.md items addressed by this PR (e.g., "Completes P1-2: Fix auth token refresh")
       - Linear ticket references using `Closes ENG-xxx` keyword format so Linear's GitHub integration auto-tracks PR completion
       - Codebase TODO/FIXME comments resolved (file:line references)
       - If none exist, write "No existing tickets or TODOs addressed."
4. Mark completed items in TODOS.md as done (change `- [ ]` to `- [x]`).

### Screenshot Embedding
When embedding screenshots in the PR body, use ABSOLUTE GitHub blob URLs, not relative paths.
Relative paths do not render in PR descriptions.

Format:
```
![description](https://github.com/{owner}/{repo}/blob/{branch}/evidence/screenshots/{filename}.png?raw=true)
```

Construct the URL from:
- `gh repo view --json nameWithOwner --jq '.nameWithOwner'` → owner/repo
- `git branch --show-current` → branch name
- The screenshot filename in `evidence/screenshots/`

Do NOT use relative paths like `![name](evidence/screenshots/name.png?raw=true)` — these are BROKEN in PR descriptions.

## On Failure
Report which step completed and which failed. Do NOT attempt to rollback.

## Linear Integration
Scan TODOS.md for Linear ticket references (patterns: `[ENG-xxx](url)`, `LINEAR: ENG-xxx`, or bare `ENG-xxx` identifiers).

### PR body keywords (primary mechanism)
Include `Closes ENG-xxx` in the PR description for each relevant ticket. Linear's GitHub integration detects these keywords and:
- Links the PR to the Linear issue automatically
- Moves the issue to "Done" when the PR merges

### CLI fallback (when Linear CLI is authenticated)
```bash
# Check if linear CLI is available and authenticated
which linear 2>/dev/null && linear me 2>/dev/null
```

If authenticated, for each ticket referenced in TODOS.md:
```bash
linear issue update <issue-id> --add-link "<pr-url>"
```

If the CLI command fails: warn but do not block. The PR body keywords are the primary tracking mechanism.
