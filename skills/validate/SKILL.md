---
name: validate
description: |
  Functional verification against the plan. Manually confirms every planned path works,
  takes screenshots, saves API examples as evidence for the PR. Use after /execute.
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Validate

You are verifying that what was built matches the plan. This is NOT a code review and NOT automated testing. You are manually walking through every planned path to confirm it works.

## Process

### 1. Read the Plan
Load the plan document. List every "green" path that was supposed to be implemented.

### 2. Manual Verification
For each planned path:

**Frontend paths:**
- Use `agent-browser open <url>` to navigate to the relevant page.
- Walk through the UI flow described in the plan.
- Take screenshots at key states: `agent-browser screenshot evidence/<name>.png`
- Note any discrepancies between plan and reality.

**Backend paths:**
- Use `curl` to hit the relevant endpoints with the expected inputs.
- Save request/response pairs to `evidence/` in markdown format.
- Verify response shapes, status codes, error handling match the plan.

### UI Screenshot Rule (MANDATORY)
If the PR modifies any file in a UI/frontend package:
1. Start the dev server (`pnpm dev`, `npm run dev`, or equivalent).
2. Navigate to EVERY page affected by the changes.
3. Take at least one screenshot per affected page state using `agent-browser screenshot evidence/screenshots/<name>.png`.
4. Save to `evidence/screenshots/` with descriptive names.
5. If the feature has multiple modes (e.g., different runtimes, different user roles, different config states): capture screenshots of EACH mode.

Do NOT skip this even if automated E2E tests pass. Screenshots are
PR evidence for human reviewers, not test assertions.

If the plan contains backend tickets that change API responses, config, or runtime
behavior consumed by the UI: start the dev server and take at least one screenshot
of each page that would reflect the change, even if no frontend files were
directly modified.

### 3. Evidence Artifacts
Save all evidence to the `evidence/` folder in the project root (create if needed):
- `evidence/screenshots/` — UI state screenshots
- `evidence/api/` — Request/response examples in markdown or Postman-compatible format

These artifacts will be referenced by /ship-pr in the PR description.

### 4. Gap Analysis
If anything is off:
- Write a plan amendment listing exactly what's wrong and what needs to change.
- Recommend sending the amended plan back to /execute to close the gaps.
- Use AskUserQuestion: "Found [N] gaps. Should I amend the plan and recommend re-running /execute?"

## Output
A verification report listing each planned path, its status (PASS/FAIL), and links to evidence artifacts.
