# Changelog

## 0.6.0

### Added
- **`/plan` Phase 5: Structured Tickets & Dependency DAG** — after the implementation proposal, emits a YAML ticket block per TODO with `id`, `title`, `priority`, `depends_on`, `milestone`, `files`, `acceptance_criteria`, `context` (self-contained agent brief), and `effort`. Includes an ASCII dependency DAG with "UNBLOCKED NOW" line for scheduling.
- **`/plan` Phase 6: Materialize** — detects Linear CLI availability upfront, then offers to create Linear tickets + TODOS.md, just TODOS.md, or skip. Graceful fallback when Linear is unavailable.
- **`/execute` ticket mode** — `--ticket <ID>` reads the structured ticket block from the plan, scopes tests to acceptance criteria, and enforces file-level scope guardrails.
- **`/execute` dependency check** — verifies dependent tickets are complete in TODOS.md (and Linear if available) before starting work.
- **`/execute` post-execution updates** — marks tickets done in TODOS.md, updates Linear status, reports newly unblocked tickets.

## 0.5.1

### Added
- **`/plan` fast-path check** — when a plan already exists and the request is a small follow-up (review comment, quick fix), skips full ceremony (system audit, alternatives, error maps, test diagrams) and produces a lightweight plan amendment
- **`/ship-pr` existing PR detection** — checks `gh pr list` before creating; if a PR already exists on the branch, pushes and comments instead of calling `gh pr create`
- **`/review` auto-fix mode** — when running inside `/upstack-run` with a fast-path plan, auto-fixes all findings without asking the user

### Changed
- **`/upstack-run` Step 1** — always runs `/plan` instead of skipping when a plan exists; delegates ceremony decisions to `/plan`'s fast-path check

## 0.5.0

### Changed
- **`/plan` skill rewritten** — deeper engineering analysis before any code is written:
  - **Phase 0: System Audit** — git log, diff stats, TODO/FIXME scan to ground the plan in codebase reality
  - **Phase 1: Implementation Alternatives** — mandatory 2-3 approaches compared (effort/risk/pros/cons) before committing
  - **Phase 2: Error & Failure Map** — table of every codepath that can fail, whether it's caught, what the user sees
  - **Phase 3: Test Coverage Diagram** — ASCII diagram of every codepath with TESTED/GAP markers and specific test specs per gap

## 0.4.0

### Added
- **`LICENSE`** — MIT license (Upsolve Labs, Inc.)
- **`.gitignore`** — standard ignores for OS, editor, and local config files
- **`CONTRIBUTING.md`** — contributor guidelines, conventions, and testing instructions
- **`SECURITY.md`** — responsible disclosure policy via GitHub Security Advisories
- **`.github/workflows/release.yml`** — auto-create GitHub Release on merge to main when VERSION changes

## 0.3.0

### Added
- **`bin/upstack-update-check`** — periodic version check script with 12h cache, exponential snooze backoff (24h → 48h → 1 week), and `update_check: false` config option to disable
- **`bin/upstack-config`** — simple get/set/list CLI for `~/.upstack/config.yaml`
- **Auto-upgrade mode** — set `auto_upgrade: true` in config or `UPSTACK_AUTO_UPGRADE=1` env var to skip the upgrade prompt
- **4-option upgrade prompt** — "Yes, upgrade now", "Always keep me up to date", "Not now" (snooze), "Never ask again" (disable)
- **Update check preamble** in all 10 SKILL.md files — every skill checks for updates on invocation
- **Vendored copy sync** — `/upgrade` detects and updates local vendored copies after upgrading the primary install
- 26 tests: 12 for upstack-config, 14 for upstack-update-check

### Changed
- `/upgrade` skill rewritten with inline upgrade flow, install type detection, and changelog diff

## 0.2.0

- Add /upstack-run skill: chains /plan -> /execute -> /validate -> /review -> /ship-pr into a single automated flow with loop-back on validation gaps and review findings
- Rename /ship to /ship-pr
- Rename /qa to /qa-review
- Update all references across CLAUDE.md, README.md, install.sh, and dependent skills

## 0.1.0

- Initial release with 9 skills: /plan, /execute, /validate, /review, /ship, /qa, /advisor, /setup, /upgrade
