---
name: plan
description: |
  Plan a feature or bug fix with TDD-first approach. Use when starting new work,
  breaking down a feature, or before any code changes. Strongly recommended as the
  first step before /execute.
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Plan

You are creating a plan for a feature or bug fix. Never write code in this phase.

## Gate: Test Rig Check
Check if the project has a test rig (look for test config files, test directories, package.json test scripts, pytest.ini, etc).
- If NO test rig exists: use AskUserQuestion to strongly recommend adding one. Explain that TDD is the foundation of quality delivery.
- If user refuses: explicitly warn that deliverables will be highly subpar without tests. Record this decision in the plan.
- Skip TDD only for: pure greenfield with nothing to build, or non-code repos (markdown only).

## Context Gathering
- Read TODO.md if it exists. If Linear MCP tools are available, also scan relevant Linear issues.
- For frontend features: use `agent-browser open <url>` and `agent-browser snapshot -i` to see the current UI state.
- For backend features: use `curl` to hit relevant endpoints and observe current behavior.
- If authentication is needed: AskUserQuestion for credentials. Propose env var setup for local testing.

## Plan Sections (write all of these out, only AskUserQuestion when a clear decision is needed)

### 1. Purpose
What the feature/fix does and why it matters.

### 2. Scope
Boundaries within the current codebase. Strongly recommend removing old code if the new feature replaces it. Minimize scope creep and tech debt. Flag anything out of scope — add those items to TODO.md (and create Linear issues if MCP is available).

### 3. Engineering Review
- Architecture risk: does this change the system's shape?
- Security risk: new inputs, auth changes, data exposure?
- User confusion risk: does this change existing behavior?

### 4. Test Proposal (BEFORE implementation)
What tests to write, where they go, what framework to use. Be specific: file paths, test names, assertions. This section MUST come before the implementation proposal.

### 5. Implementation Proposal
The actual code changes needed to make the tests pass. Reference specific files and functions. Order by dependency (infrastructure first, features second).

## For Bug Fixes
Simplify to: Test Proposal + Fix Recommendation only. If unsure whether something is a feature or bug, AskUserQuestion.

## Decisions
Record every decision made via AskUserQuestion in the plan document. Use Claude Code's built-in plan infrastructure — store the plan in the standard plan file.
