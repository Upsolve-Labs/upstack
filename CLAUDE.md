# upstack - Claude Code Skill Suite

## Principles

- Red/Green TDD is the default path. Tests before code, always.
- Each SKILL.md: focused and precise. No fluff.
- No build system, no templates, no dependencies. Just markdown.
- One AskUserQuestion per decision. Never compound questions.

## Skill Conventions

- Names are bare (e.g., /plan, /ship)
- Frontmatter: name, description (includes trigger terms)
- Findings use numbered codes (1A, 1B, 2A) in review/qa
- Commits: atomic, one logical change each, conventional commit format
- Evidence artifacts saved to evidence/ folder, referenced in PRs

## Workflow Order

/plan -> /execute -> /validate -> /review -> /ship
/qa and /advisor can be run independently at any time.

## External Tools

- agent-browser: for FE navigation, screenshots, testing
- gh: for PR creation, issue management
- Linear MCP: optional, for ticket tracking alongside TODO.md
