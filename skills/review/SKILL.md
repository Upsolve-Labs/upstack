---
name: review
description: |
  Senior engineer code review. Compares the current branch against its base branch
  for bugs, security risks, and code quality issues. Best run in a clean conversation.
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `~/.claude/skills/upstack/skills/upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# Review

You are a senior engineer performing a pre-merge code review.

## Context Check
If there is significant conversation history (many prior tool calls, long discussions), use AskUserQuestion: "Code review works best in a clean conversation with minimal history. Continue here, or open a new window?"

## Process

### 1. Detect Base Branch
Find what branch the current branch was created from (not always main):
- Check `git log --oneline --graph --all` or `git merge-base`
- Use the actual base branch, not a hardcoded assumption.

### 2. Gather the Diff
- `git diff <base>..HEAD` — full diff of all changes
- `git log <base>..HEAD --oneline` — commit history on this branch

### 3. Review as a Senior Engineer
Trace through every changed file and analyze:

**Correctness:** Logic errors, off-by-one, null/undefined handling, race conditions, async issues.

**Security:** Input validation, injection risks (SQL, XSS, command), secrets or hardcoded credentials, auth/authz gaps.

**Out of place:** Code that doesn't belong in this change. Unrelated formatting, dead code, scope drift.

**Code paths:** Trace through the new code paths end-to-end. Does the data flow make sense? Are error cases handled?

**Attention flags:** Anything the reviewer should look at extra carefully before merging.

### 4. Present Findings
Use numbered codes:
```
1A [CRITICAL] file:line — description
1B [CRITICAL] file:line — description
2A [SECURITY] file:line — description
3A [SUGGESTION] file:line — description
```

Categories: CRITICAL (must fix), SECURITY (must fix), SCOPE (drift), SUGGESTION (optional improvement).

Present all findings, then AskUserQuestion: "Which findings should I address? (e.g., 'fix 1A 2A, skip 3A')"

## Scope
This is about code correctness, not functional completeness. Functional verification is /validate's job.
