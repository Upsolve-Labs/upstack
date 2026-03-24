---
name: plan
description: |
  Plan a feature or bug fix with deep engineering analysis. Explores the codebase,
  compares implementation alternatives, maps error paths, and produces test coverage
  diagrams — all before any code is written. Emits structured YAML tickets with
  dependency DAG and self-contained agent briefs. Optionally materializes to
  Linear and TODOS.md. Use when starting new work, breaking down a feature, or
  before any code changes. Strongly recommended as the first step before /execute.
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
For EACH package that the plan will modify, check if that package has its own test infrastructure:
- Backend packages: look for vitest/jest config, test directories, package.json test scripts, pytest.ini, etc.
- UI/frontend packages: look for Playwright/Cypress config, E2E test directories, browser test scripts.

Rules:
- If NO test rig exists at all: use AskUserQuestion to strongly recommend adding one. Explain that TDD is the foundation of quality delivery.
- If a UI/frontend package will be modified but has NO E2E test setup: recommend adding Playwright (or equivalent) as part of the plan. Add a ticket for it.
- If user refuses: explicitly warn that deliverables will be highly subpar without tests. Record this decision in the plan.
- Skip TDD only for: pure greenfield with nothing to build, or non-code repos (markdown only).
- Do NOT treat a project-wide unit test rig as sufficient for UI packages. Unit tests and E2E tests serve different purposes.

## Fast-Path Check

Before running full ceremony, check whether this is a small follow-up to existing work:

- **Conditions (ALL must be true):**
  1. A plan already exists in the current conversation context.
  2. The user's request is a small, scoped follow-up (e.g., responding to a review comment, fixing a specific bug, small tweak).

- **If fast-path applies:**
  - Announce: "Amending existing plan with follow-up fix."
  - Skip Phase 0 (System Audit), Phase 1 (alternatives), Phase 2 (error/failure map), and Phase 3 (test coverage diagram).
  - Produce only: **Purpose** (1-2 sentences on what changed and why) + **Implementation Proposal** (specific files and changes needed).
  - No AskUserQuestion for approach selection — a small fix has one obvious approach.
  - The plan phase is complete. Return the amendment — do not invoke /execute yourself.

- **If fast-path does NOT apply** (no prior plan, or the follow-up is complex enough to warrant full analysis): continue with the full flow below.

## Phase 0: System Audit

Before planning anything, ground yourself in the codebase. Run these commands:

```bash
git log --oneline -20
git diff --stat 2>/dev/null || true
grep -r "TODO\|FIXME\|HACK\|XXX" -l --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=.git . 2>/dev/null | head -20
```

Then read:
- TODOS.md if it exists. If Linear MCP tools are available, also scan relevant Linear issues.
- CLAUDE.md for project conventions.
- Any architecture docs or READMEs relevant to the area you're changing.

For frontend features: use `agent-browser open <url>` and `agent-browser snapshot -i` to see the current UI state.
For backend features: use `curl` to hit relevant endpoints and observe current behavior.
If authentication is needed: AskUserQuestion for credentials. Propose env var setup for local testing.

Report a brief summary of findings before proceeding.

### Existing Work Tracker
After the system audit, explicitly list any pre-existing TODOs or Linear tickets that this plan will address:

```
ADDRESSING EXISTING WORK
===========================
TODOS.md:
  - [ ] P1-2: Fix auth token refresh (if relevant to this plan)
  - (none found)

Linear tickets:
  - ENG-142: "Auth middleware rewrite" (In Progress)
  - (none found / Linear not available)

Codebase TODOs (from grep):
  - src/auth.ts:42 — TODO: handle token expiry
  - (none found)
===========================
```

Rules:
- If TODOS.md exists, scan it for items related to the current work. List any that this plan will fully or partially address.
- If Linear CLI or MCP tools are available, search for relevant open issues. List matching tickets with their ID, title, and status.
- If codebase grep found relevant TODO/FIXME comments, list file:line and the comment text.
- If nothing is found, say "(none found)" for each section. Do not skip the section.
- These references carry forward — they will be used by /ship-pr to link the PR to the work it completes.

### Cross-Package Impact Check
After identifying the primary files to change, check for downstream impact:
- If changing API response shapes or adding endpoints: check if the UI consumes them
  (`grep -r "api/" packages/ui/ --include="*.tsx" --include="*.ts"` or equivalent for the project structure)
- If adding config options: check if the UI has a config panel or settings page
- If changing container/pod/runtime behavior: check if the UI has a monitoring, status, or management page

If UI impact is found: include UI changes in the plan scope. Do NOT treat
backend-only plans as complete when the UI will show stale or broken content.

For ANY feature that changes API responses, configuration, or behavior visible through the UI:
use `agent-browser open <url>` and `agent-browser snapshot -i` to see the current UI state,
even if the feature is primarily backend.

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
After approach is chosen, define boundaries. Strongly recommend removing old code if the new feature replaces it. Flag anything out of scope — add those items to TODOS.md (and create Linear issues if MCP is available).

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

## Phase 5: Structured Tickets & Dependency DAG

After the implementation proposal, produce a machine-readable ticket list. This enables multi-agent orchestration, Linear integration, and dependency-aware scheduling.

### Step 1: Emit structured ticket blocks

Produce a YAML code block with one entry per TODO from the plan. Every ticket must be self-contained — a fresh agent with no prior context should be able to execute it.

```yaml
tickets:
  - id: P1-1
    title: "Short imperative description"
    priority: 1        # 1 = urgent, 2 = important, 3 = nice-to-have
    depends_on: []      # list of ticket IDs that must complete first
    milestone: "P1: Milestone Name"
    files:
      - path/to/file1.ts
      - path/to/file2.ts
    acceptance_criteria:
      - "Specific, testable condition that defines done"
      - "Another condition"
    context: |
      WHY: Why this change exists (not just what).
      READ FIRST: Key existing code to read (with file paths).
      PATTERN: Follow the same pattern as X (file path).
      DO NOT: Scope boundaries — what this ticket should NOT touch.
      VERIFY: Specific test commands or manual checks to confirm done.
    effort: S           # S / M / L
```

Rules:
- One ticket per logical unit of work. If a TODO has sub-tasks, each sub-task is its own ticket.
- `files` lists every file the ticket is expected to touch — this becomes the scope guardrail in /execute.
- `acceptance_criteria` must be specific enough to write tests from. No vague language like "works correctly."
- `context` must repeat relevant architecture/pattern info inline. Never write "see above" or "refer to Phase 1."
- `depends_on` references ticket IDs from this plan, not external systems.
- Group tickets by milestone. Milestones map to major plan sections (P1, P2, etc.).

### Step 2: Emit dependency DAG

After the ticket list, produce an ASCII dependency DAG:

```
DEPENDENCY DAG
===========================
P1-1 → P1-2 → P1-3 → P1-4
                  ↘ P1-7
P1-5 → P1-6
P2-1 → P2-3 → P2-4
P2-2 ↗
P1-4 + P2-3 → P3-5

UNBLOCKED NOW: P1-1, P1-5, P2-1, P2-2
===========================
```

Rules:
- Show every ticket. Isolated tickets (no dependencies) appear on their own line.
- End with an "UNBLOCKED NOW" line listing tickets that can start immediately.
- For milestone boundaries: note integration test specs (e.g., "After all P1 tickets: run `npm test -- --grep P1`").

## Phase 6: Materialize

After the user approves the plan, offer to materialize tickets into tracking systems.

### Step 1: Detect Linear CLI

```bash
which linear 2>/dev/null && linear me 2>/dev/null
```

### Step 2: Offer options based on what's available

- **If Linear CLI is available and authenticated:** AskUserQuestion with 3 options:
  1. "Create Linear tickets + TODOS.md" — create tickets in Linear and write TODOS.md with links
  2. "Just TODOS.md" — write TODOS.md only
  3. "Skip" — do not materialize

- **If Linear CLI is NOT available:** AskUserQuestion with 2 options:
  1. "Create TODOS.md" — write TODOS.md with ticket checkboxes
  2. "Skip" — do not materialize

### Step 3: Write TODOS.md

Format grouped by milestone, one checkbox per ticket:

```markdown
# Tickets

## P1: Milestone Name
- [ ] P1-1: Short title
- [ ] P1-2: Short title (depends on P1-1)

## P2: Another Milestone
- [ ] P2-1: Short title
```

If Linear tickets were created, append the Linear link after each title:
```markdown
- [ ] P1-1: Short title [TSC-42](https://linear.app/team/issue/TSC-42)
```

### Step 4: Create Linear tickets (if chosen)

For each ticket in the YAML block:
```bash
linear issue create --title "<title>" --description "<context + acceptance_criteria>" --priority <priority> --label "<milestone>"
```

If a ticket creation fails: warn the user, continue with remaining tickets, and note which failed in TODOS.md.

## For Bug Fixes
Simplify to: Error & Failure Map + Test Coverage Diagram + Fix Recommendation only. Skip implementation alternatives unless the fix approach is genuinely ambiguous. If unsure whether something is a feature or bug, AskUserQuestion. For simple bugs (1-2 files), skip Phase 5 and Phase 6.

## Decisions
Record every decision made via AskUserQuestion in the plan document. Use Claude Code's built-in plan infrastructure — store the plan in the standard plan file.
