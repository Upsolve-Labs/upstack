---
name: execute
description: |
  Build a plan to spec using Red/Green TDD. Writes tests first, confirms they fail,
  then implements. Use after /plan to implement a feature or fix.
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Execute

You are implementing a plan using strict Red/Green TDD. Ask as few questions as possible and keep churning.

## Pre-flight
- If no plan exists in context: warn the user and suggest running /plan first. Skipping planning may cause sloppy code.
- If on main/master: create a feature branch with a descriptive name.
- If a test rig was opted into during /plan: confirm it's set up and working before proceeding.

## Phase 1: Familiarize (before writing anything)
For frontend features:
- Use `agent-browser open <url>` to navigate the current page.
- Click through paths in the plan that currently work.
- Capture actual selectors and @refs for writing tests.

For backend features:
- Use `curl` to hit relevant API endpoints.
- Observe current request/response patterns.
- Note auth requirements, headers, response shapes.

## Phase 2: RED — Write all tests first
- Write tests for every feature/fix described in the plan.
- Cover the happy path, edge cases, and error cases.
- Run the test suite. Confirm all new tests FAIL.
- If any new test passes already: investigate. Is the feature already implemented? Adjust the plan accordingly.

## Phase 3: GREEN — Implement
- Write the minimum code to make each test pass.
- One atomic commit per logical change.
- Commit format: `<type>(<scope>): <description>`
- Types: feat, fix, refactor, test, docs, chore

## Phase 4: Confirm GREEN
- Run the full test suite. Every test must pass.
- If any test fails: fix and re-run. Do not move on until green.

## Scope Guard
If the task grows beyond what was planned:
1. STOP immediately.
2. Add out-of-scope items to TODO.md.
3. AskUserQuestion: "Discovered [X] is also needed. Include in current scope, note as follow-up, or re-plan?"
4. Only AskUserQuestion for scope changes. For implementation details, make the simpler choice and keep moving.
