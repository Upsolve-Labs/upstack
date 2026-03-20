---
name: setup
description: |
  Check and install prerequisites for upstack. Verifies git, gh, agent-browser,
  and skill symlinks. Use when first setting up or troubleshooting.
disable-model-invocation: true
---

# Setup

## Check Prerequisites

Run checks silently, then report a summary table:

| Tool          | Check                     | Required By                     |
| ------------- | ------------------------- | ------------------------------- |
| git           | `git --version`           | all skills                      |
| gh            | `gh --version`            | /ship, /review, /advisor        |
| gh auth       | `gh auth status`          | /ship, /review, /advisor        |
| agent-browser | `agent-browser --version` | /plan, /execute, /validate, /qa |
| node          | `node --version`          | /validate (JS projects)         |
| python        | `python3 --version`       | /validate (Python projects)     |

## Report

Print table with status for each tool. Mark required tools vs optional.

## Fix Missing Tools

If required tools are missing, AskUserQuestion:
"Missing: [list]. Should I show install commands?"

Install commands (never run automatically):

- gh: `brew install gh` then `gh auth login`
- agent-browser: `brew install agent-browser` then `agent-browser install`

Detect OS for appropriate package manager (brew for macOS, apt for Linux).

## Verify Skill Symlinks

List all skills in `~/.claude/skills/` that point to the upstack repo.
Report any broken or missing symlinks.
If symlinks are broken: suggest re-running `install.sh`.

## Optional: Linear

If user mentions Linear: check for Linear MCP server configuration.
Explain which skills benefit (plan, advisor, ship) and how to set it up.
