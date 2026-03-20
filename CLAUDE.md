# upstack - Claude Code Skill Suite

## Principles

- Red/Green TDD is the default path. Tests before code, always.
- Each SKILL.md: focused and precise. No fluff.
- No build system, no templates, no dependencies. Just markdown.
- One AskUserQuestion per decision. Never compound questions.

## Skill Conventions

- Names are bare (e.g., /plan, /ship-pr)
- Frontmatter: name, description (includes trigger terms)
- Findings use numbered codes (1A, 1B, 2A) in review/qa-review
- Commits: atomic, one logical change each, conventional commit format
- Evidence artifacts saved to evidence/ folder, referenced in PRs

## Workflow Order

/plan -> /execute -> /validate -> /review -> /ship-pr
/qa-review and /advisor can be run independently at any time.
/upstack-run chains the full flow automatically.

## External Tools

- gh: needed for /ship-pr to push commits, create/update PRs, and generate release notes
- agent-browser: needed for /plan, /validate, /review, /qa-review to navigate frontend, click around the browser, and screenshot functionality
- linear-cli: optional, integrates with your team's Linear instead of relying just on TODO.md

## upstack

- Use agent-browser for all web browsing.
- Available skills: /plan, /execute, /validate, /review, /ship-pr, /qa-review, /advisor, /setup, /upgrade, /upstack-run.
