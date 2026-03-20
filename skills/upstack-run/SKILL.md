---
name: upstack-run
description: |
  Full sprint flow: /plan -> /execute -> /validate -> /review -> /ship-pr.
  Skips planning if a plan already exists. Loops review/execute until clean.
  End result is a pushed PR. Use to run the entire workflow hands-free.
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Upstack Run

Chains the full sprint flow into a single run. The end result is a pushed PR.

## Step 1: Plan (skip if plan exists)

Check if a plan already exists in the current context.

- **If a plan exists:** announce "Plan found, skipping to /execute." and proceed to Step 2.
- **If no plan exists:** run /plan. This is the only interactive phase — answer the user's questions and get plan approval before continuing. Do NOT proceed until the user approves the plan.

## Step 2: Execute

Run /execute against the approved plan. Strict Red/Green TDD: write failing tests, implement until green, atomic commits.

## Step 3: Validate

Run /validate. Walk through every planned path manually, capture evidence (screenshots, API examples) to `evidence/`.

If validation finds gaps:
- Amend the plan with the gaps.
- Loop back to Step 2 (/execute) to close them.
- Re-validate. Maximum 3 loops before stopping and reporting to the user.

## Step 4: Review

Run /review. Senior engineer code review against the base branch.

If review finds CRITICAL or SECURITY findings:
- Automatically fix the flagged issues (treat them as if the user said "fix all").
- Loop back to Step 2 (/execute) for the fixes.
- Re-run /review. Maximum 3 review/execute loops before stopping and reporting to the user.

## Step 5: Ship

Run /ship-pr. Documentation, version bump, PR creation. The version bump question is the only interactive pause in this phase.

## Guardrails

- **Max loops:** 3 for validate gaps, 3 for review findings. If still failing after 3, stop and report what remains.
- **Abort on hard failure:** If tests cannot pass, gh is unavailable, or the branch is in a bad state, stop and report. Do not retry endlessly.
- **No silent skips:** Always announce which step you are entering and whether any steps were skipped or looped.
