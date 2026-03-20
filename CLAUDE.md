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

- gh: needed for /ship to push commits, create/update PRs, and generate release notes
- agent-browser: needed for /plan, /validate, /review, /qa to navigate frontend, click around the browser, and screenshot functionality
- linear-cli: optional, integrates with your team's Linear instead of relying just on TODO.md
