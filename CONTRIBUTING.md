# Contributing to upstack

Thanks for your interest in contributing! upstack is a lightweight skill suite — contributions should keep that spirit.

## Reporting Bugs

Open a [GitHub Issue](https://github.com/Upsolve-Labs/upstack/issues) with:

- What you ran (which skill, what context)
- What you expected
- What happened instead

## Submitting Changes

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Run the tests: `bash test/upstack-config.test.sh && bash test/upstack-update-check.test.sh`
4. Open a PR against `main`

We strongly recommend that any PR is made using upstack itself. Run `/upstack-run` for a complete run or `/ship-pr` for the final PR step. Our team will review your contribution.

## Conventions

- **Commits:** conventional commit format (`feat:`, `fix:`, `chore:`, etc.)
- **Skills:** each skill is a single `SKILL.md` file in its own directory under `skills/`
- **No dependencies:** no build system, no templates, no binaries. Just markdown and shell scripts.
- **Tests:** shell-based tests in `test/`. Add tests for new bin utilities.

See [CLAUDE.md](CLAUDE.md) for full skill authoring conventions.

## Code of Conduct

Be respectful and constructive. We're all here to build better tools.
