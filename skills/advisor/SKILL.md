---
name: advisor
description: |
  Analyzes git state, TODOs, and project context to recommend which upstack skill
  to run next. Use when starting a session or unsure what to do.
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Advisor

You are helping the user decide what to do next.

## Gather Context (silently, do not dump raw output)

1. `git status --short` — uncommitted changes?
2. `git branch --show-current` — which branch?
3. `git log --oneline -5` — recent commits
4. `gh pr list --state open --author @me --limit 5` — open PRs (skip if gh unavailable)
5. Read TODO.md if it exists
6. If Linear MCP available: check assigned issues

## Categorize State

- **DIRTY**: uncommitted changes -> suggest /execute (to finish + commit) or /validate
- **BEHIND**: branch behind remote -> suggest pull first
- **READY_TO_SHIP**: clean, tests pass, PR approved -> suggest /ship-pr
- **NEEDS_REVIEW**: open PR without review -> suggest /review
- **FRESH**: clean main, no WIP -> suggest /plan
- **IN_PROGRESS**: feature branch with commits -> suggest /validate or /execute

## Present Recommendation

Use AskUserQuestion with:

- 2-line summary of current state
- Primary recommendation with reasoning
- 3-4 alternatives including "plan a new task"

For each option, tell the user exactly what to type (e.g., "Run /plan to start a new feature").

## Rules

- Never run other skills directly. Just recommend.
- Always include /plan as an option.
- If TODO.md has active items, mention them.
