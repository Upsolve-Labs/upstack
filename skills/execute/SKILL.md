---
name: execute
description: |
  Build a plan to spec using Red/Green TDD. Writes tests first, confirms they fail,
  then implements. Supports --ticket mode for scoped execution with dependency
  checks and file-level scope guardrails. Use after /plan to implement a feature or fix.
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

### Ticket Mode
If the user passes `--ticket <ID>` (e.g., `/execute --ticket P1-3`):
1. Find the structured ticket block in the plan's Phase 5 YAML output.
2. Extract: `title`, `files`, `acceptance_criteria`, `depends_on`, `context`, and `effort`.
3. If ticket ID is not found: error with a list of available ticket IDs from the plan.
4. Announce: "Executing ticket P1-3: <title>"

### Dependency Check (ticket mode only)
Before writing any code, check if dependent tickets are complete:
1. Read TODOS.md. For each ID in `depends_on`, check if it's marked `[x]`.
2. If Linear CLI is available (`which linear 2>/dev/null`), also check Linear ticket status.
3. If any dependency is incomplete: AskUserQuestion warning — "Ticket P1-3 depends on P1-1 and P1-2 which aren't done yet. Proceed anyway?"
4. If TODOS.md doesn't exist: warn and proceed (dependencies can't be verified).

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
- **Ticket mode:** scope tests to the ticket's `acceptance_criteria` only. Do not write tests for other tickets.
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
2. Add out-of-scope items to TODOS.md.
3. AskUserQuestion: "Discovered [X] is also needed. Include in current scope, note as follow-up, or re-plan?"
4. Only AskUserQuestion for scope changes. For implementation details, make the simpler choice and keep moving.

### File Scope Guard (ticket mode only)
When in ticket mode, the ticket's `files` list defines the expected scope:
- Before modifying a file not in the `files` list: AskUserQuestion — "File `path/to/file.ts` isn't in this ticket's scope. Add to scope or create a follow-up ticket?"
- This prevents parallel agents from creating merge conflicts by touching the same files.

## Phase 5: Post-Execution (ticket mode only)

After all tests pass, update tracking systems:

1. **Update TODOS.md:** Mark the ticket as done — change `- [ ]` to `- [x]` for the ticket's line.
2. **Update Linear** (if CLI available): Run `linear issue update <issue-id> --status "Done"`.
3. **Report unblocked tickets:** Read the plan's dependency DAG. List any tickets whose `depends_on` are now all complete. Announce: "Newly unblocked: P1-4, P2-3"
