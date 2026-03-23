---
name: plan
description: |
  Plan a feature or bug fix with deep engineering analysis. Explores the codebase,
  compares implementation alternatives, maps error paths, and produces test coverage
  diagrams — all before any code is written. Use when starting new work, breaking
  down a feature, or before any code changes. Strongly recommended as the first
  step before /execute.
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

## Phase 0: System Audit

Before planning anything, ground yourself in the codebase. Run these commands:

```bash
git log --oneline -20
git diff --stat 2>/dev/null || true
grep -r "TODO\|FIXME\|HACK\|XXX" -l --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git . 2>/dev/null | head -20
```

Then read:
- TODO.md if it exists. If Linear MCP tools are available, also scan relevant Linear issues.
- CLAUDE.md for project conventions.
- Any architecture docs or READMEs relevant to the area you're changing.

For frontend features: use `agent-browser open <url>` and `agent-browser snapshot -i` to see the current UI state.
For backend features: use `curl` to hit relevant endpoints and observe current behavior.
If authentication is needed: AskUserQuestion for credentials. Propose env var setup for local testing.

Report a brief summary of findings before proceeding.

## Phase 1: Purpose & Implementation Alternatives

### Purpose
What the feature/fix does and why it matters. One paragraph max.

### Implementation Alternatives (MANDATORY)
Before committing to an approach, produce 2-3 distinct alternatives. This is not optional — every plan must consider alternatives.

For each approach:
```
APPROACH A: [Name]
  Summary: [1-2 sentences]
  Effort:  [S/M/L]
  Risk:    [Low/Med/High]
  Pros:    [2-3 bullets]
  Cons:    [2-3 bullets]
  Reuses:  [existing code/patterns leveraged]
```

Rules:
- At least 2 approaches required. 3 preferred for non-trivial plans.
- One approach must be the "minimal viable" (fewest files, smallest diff).
- One approach should be the "ideal architecture" (best long-term trajectory).
- If only one approach truly exists, explain concretely why alternatives were eliminated.

State your recommendation with a one-line reason. Use AskUserQuestion to get the user's choice.

### Scope
After approach is chosen, define boundaries. Strongly recommend removing old code if the new feature replaces it. Flag anything out of scope — add those items to TODO.md (and create Linear issues if MCP is available).

## Phase 2: Engineering Deep-Dive

### Error & Failure Map
For every new method, service, or codepath that can fail, fill in this table:

```
METHOD/CODEPATH          | WHAT CAN GO WRONG        | CAUGHT? | USER SEES
-------------------------|--------------------------|---------|-------------------
ExampleService#call      | API timeout              | N ← GAP | 500 error
                         | Invalid input            | Y       | Validation message
                         | Upstream returns empty    | N ← GAP | Silent failure
```

For each GAP: specify the fix (retry, degrade gracefully, raise with context). Don't ask per-gap — note the fixes in the plan and move on.

### Architecture & Security
- Does this change the system's shape? Draw an ASCII dependency diagram if yes.
- New inputs, auth changes, data exposure? Name specific risks.
- For each new integration point: describe one realistic production failure scenario and whether the plan accounts for it.
- Rollback posture: if this ships and breaks, what's the recovery path?

Use AskUserQuestion only if there's a genuine architectural decision with meaningful tradeoffs.

## Phase 3: Test Coverage Diagram

Trace every codepath introduced by this plan. For each, check if a test exists or needs to be written.

### Step 1: Trace codepaths
For each new feature/component, follow the data:
- Where does input come from?
- What transforms it?
- Where does it go?
- What can go wrong at each step?

### Step 2: Produce ASCII coverage diagram

```
CODE PATH COVERAGE
===========================
[+] src/services/billing.ts
    │
    ├── processPayment()
    │   ├── [TESTED]  Happy path — billing.test.ts:42
    │   ├── [GAP]     Network timeout — NO TEST
    │   └── [GAP]     Invalid currency — NO TEST
    │
    └── refundPayment()
        ├── [TESTED]  Full refund — billing.test.ts:89
        └── [GAP]     Partial refund edge case — NO TEST

─────────────────────────────────
COVERAGE: 2/5 paths tested (40%)
GAPS: 3 paths need tests
─────────────────────────────────
```

### Step 3: Write test specs for each GAP
Be specific: file paths, test names, assertions, framework. This section MUST come before the implementation proposal.

```
GAP: Network timeout in processPayment()
  File: test/services/billing.test.ts
  Test: "processPayment retries twice then raises TimeoutError"
  Assert: expect(mockApi.calls).toBe(3); expect(() => ...).toThrow(TimeoutError)
```

## Phase 4: Implementation Proposal

The actual code changes needed to make the tests pass. Reference specific files and functions. Order by dependency (infrastructure first, features second).

For each file change, note:
- What changes and why
- Which test(s) it satisfies from Phase 3

## For Bug Fixes
Simplify to: Error & Failure Map + Test Coverage Diagram + Fix Recommendation only. Skip implementation alternatives unless the fix approach is genuinely ambiguous. If unsure whether something is a feature or bug, AskUserQuestion.

## Decisions
Record every decision made via AskUserQuestion in the plan document. Use Claude Code's built-in plan infrastructure — store the plan in the standard plan file.
