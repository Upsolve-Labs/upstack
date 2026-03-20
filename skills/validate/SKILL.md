---
name: validate
description: |
  Functional verification against the plan. Manually confirms every planned path works,
  takes screenshots, saves API examples as evidence for the PR. Use after /execute.
---

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
