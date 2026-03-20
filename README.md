# upstack

Lightweight Claude Code (+ others) skill suite, used by the team at [Upsolve AI](https://upsolve.ai/).

Red/Green TDD workflow with 9 focused skills, minimal dependencies. Inspired by [gstack](https://github.com/garrytan/gstack) and [simon wilson](https://simonwillison.net/guides/agentic-engineering-patterns/red-green-tdd/).

Hi, I'm [Serguei](https://www.linkedin.com/in/sbalanovich/), CTO at Upsolve. I built [Hyperauto](https://www.palantir.com/offerings/hyperauto/) at Palantir and I'm now working to help teams build robust, reliable data agents for their teams and customers. Like Garry, I think we're currently on the cusp of something huge in the AI coding space. But after playing around with gstack, I found its approach to be much more suited for new & ambitious greenfield projects than iterating on existing products.

At Upsolve, we are hyper focused on security, reliability, and grounding agents in real, auditable data. So our team's engineering approach requires a slightly different approach. With code being essentially free to write now, I believe we developers now need to focus on providing tightly scoped specs, project definitions, and test suites before touching a line of code. When you use upstack, it forces you to think test-first and submits code that is instantly provable and reliable. It takes 30 seconds to set up, so give it a try!

## Quick Start: Your First 5 Minutes

1. Install upstack (30 seconds, see below)
2. Open your project in Claude Code
3. Run `/advisor` to see where you stand
4. Run `/plan` on your first feature or bug
5. Run `/execute` to build it with TDD
6. Run `/ship` to open a PR with screenshots and evidence

## Install — Takes 30 Seconds

### Install on your machine

Open Claude Code and paste this. Claude does the rest.

> Install upstack: clone `https://github.com/Upsolve-Labs/upstack.git` to `~/.upstack` (try HTTPS first, fall back to SSH with `git@github.com:Upsolve-Labs/upstack.git` if auth fails), then run `cd ~/.upstack && ./install.sh`. The script links skills and prints an `INSTALL_STATUS` report and `NEXT_STEPS`. Do NOT install anything yourself — read the status, then walk the user through each missing tool one AskUserQuestion at a time. Follow the `NEXT_STEPS` in the output.

### Codex, Gemini CLI, or Cursor

upstack uses the SKILL.md standard. Clone the repo, then copy the skills into your tool's skill directory:

```bash
git clone https://github.com/Upsolve-Labs/upstack.git ~/.upstack

# Codex
cp -r ~/.upstack/skills/* .agents/skills/

# Cursor
cp -r ~/.upstack/skills/* .cursor/skills/

# Gemini CLI
cp -r ~/.upstack/skills/* .gemini/skills/
```

Skills are plain markdown — they work in any agent that reads SKILL.md files.

## See It Work

```
you:    I want to build a telemetry dashboard for my SaaS app
you:    /plan
claude: [checks for test rig, proposes scope, eng review, test plan, then implementation plan]

you:    /execute
claude: [navigates your app with agent-browser, writes failing tests, implements, confirms green]

you:    /validate
claude: [walks through every planned path manually, screenshots UI, saves API examples to evidence/]

you:    /review
claude: [diffs against base branch, finds bugs and security issues, numbered findings like 1A, 2A]

you:    /ship
claude: [writes docs, bumps version, opens PR with screenshots and Linear links]
```

## Workflow

```
/plan -> /execute -> /validate -> /review -> /ship
```

| Skill         | What It Does                                                                           |
| ------------- | -------------------------------------------------------------------------------------- |
| **/plan**     | Purpose, scope, eng review, test proposal, implementation proposal. Tests before code. |
| **/execute**  | RED: write failing tests. GREEN: implement. Atomic commits.                            |
| **/validate** | Manually verify every path works. Save screenshots + API examples to `evidence/`.      |
| **/review**   | Senior engineer code review against base branch. Best in a clean conversation.         |
| **/ship**     | Docs, version bump, PR with evidence screenshots and Linear links.                     |

Independent skills:

| Skill        | What It Does                                                                               |
| ------------ | ------------------------------------------------------------------------------------------ |
| **/qa**      | Exploratory testing: traverse UI with agent-browser, find edge cases, screenshot findings. |
| **/advisor** | Analyze git state and recommend which skill to run next.                                   |
| **/setup**   | Check prerequisites and verify installation.                                               |
| **/upgrade** | Pull latest upstack with backup.                                                           |

## Upgrade

```
/upgrade
```

Or manually: `cd ~/.upstack && git pull`

## Philosophy

- **Tests before code, always.** Red/Green TDD is the default path.
- **Evidence-based PRs.** Screenshots and API examples ship with every PR.
- **Scope discipline.** Out-of-scope discoveries go to TODO.md (or Linear tickets), not into the current work.
- **No bloat.** 9 skills, ~400 lines total. No build system, no templates, no binaries.

## License

MIT License. Free and open source.
