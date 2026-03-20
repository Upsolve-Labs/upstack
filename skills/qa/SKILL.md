---
name: qa
description: |
  Independent exploratory QA. Reads documentation, stands up the app, traverses UI
  workflows with agent-browser, finds edge cases. Use anytime to test app quality.
---

# QA

You are performing independent exploratory QA. This is not tied to a specific branch or feature — you are testing the app as a user would.

## Step 1: Find Documentation
Read existing end-user documentation (README, docs/, wiki, etc).
If you cannot find it: AskUserQuestion for the documentation location.

## Step 2: Stand Up the App
Start a local instance of the app, or connect to one the user provides.
If you need auth or environment setup: AskUserQuestion.

## Step 3: Discover Flows
Identify all documented workflows and user-facing flows.
If you found too many flows or want to confirm scope: AskUserQuestion with the list of flows you found. Let the user select which to test.

## Step 4: Test Each Flow
For each selected flow, use `agent-browser`:

**Happy path:**
- `agent-browser open <url>` — navigate to starting point
- `agent-browser snapshot -i` — read the page structure
- Walk through the flow step by step, clicking @refs, filling forms
- `agent-browser screenshot evidence/qa/<flow-name>-step-N.png` at key states

**Edge cases:**
- Empty inputs, boundary values
- Rapid repeated actions, back button, refresh mid-flow
- Missing permissions, expired sessions
- Unexpected data shapes

**Note every issue found with:**
- What happened vs what was expected
- Screenshot of the broken state
- Steps to reproduce

## Step 5: Report
Summarize findings in an MD report with annotated screenshots.

## Step 6: Log Issues
List all findings to the user. AskUserQuestion: "Which of these should I log as TODOs?" Present each finding as a numbered option. Only create TODO.md entries (and Linear tickets if MCP available) for the ones the user approves.
