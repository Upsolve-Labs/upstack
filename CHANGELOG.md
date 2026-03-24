# Changelog

## 0.8.0

### Added
- **`/plan` Cross-Package Impact Check** — Phase 0 now checks for downstream UI impact when changing API shapes, config options, or runtime behavior. Backend-only plans that affect the UI are flagged before they're approved.
- **`/plan` per-package test rig gate** — Gate check now evaluates test infrastructure per-package. UI packages without E2E test setup (Playwright/Cypress) get a ticket recommendation, rather than being silently skipped because a unit test rig exists elsewhere.
- **`/execute` UI-aware familiarization** — Phase 1 detects UI impact in the plan and runs the frontend familiarization flow (dev server, agent-browser navigation) even when the primary feature is backend.
- **`/validate` mandatory UI screenshot rule** — If the PR modifies UI files, screenshots are required regardless of whether E2E tests pass. Screenshots are evidence for reviewers, not test assertions.
- **`/ship-pr` screenshot safety check** — Warns when the diff includes UI files but `evidence/screenshots/` is empty. Prevents shipping UI changes without visual evidence.
- **`/ship-pr` absolute GitHub blob URLs** — Screenshot embeds now use absolute `https://github.com/{owner}/{repo}/blob/{branch}/...?raw=true` URLs instead of relative paths, which break in PR descriptions.
- **`/upstack-run` UI validation mandate** — Step 3 explicitly states that passing Playwright tests is not a substitute for `/validate` when UI files are in the diff.

## 0.7.0

### Added
- **`/plan` Existing Work Tracker** — after the Phase 0 system audit, /plan now explicitly lists TODOS.md items, Linear tickets, and codebase TODO/FIXME comments that the plan will address. These references carry forward to /ship-pr for PR linking.
- **`/ship-pr` Closes / Addresses section** — PR descriptions now include a mandatory section listing TODOS.md items completed, Linear tickets (using `Closes ENG-xxx` keywords for auto-tracking), and codebase TODOs resolved.
- **`/ship-pr` enhanced Linear Integration** — scans TODOS.md for ticket references, includes `Closes ENG-xxx` in PR body for automatic Linear-GitHub linking, and falls back to `linear issue update --add-link` when CLI is authenticated.

### Fixed
- **TODOS.md naming consistency** — standardized all references across skills, docs, and install.sh from `TODO.md` to `TODOS.md`.

## 0.6.1

### Fixed
- **`/plan` fast-path** — replaced "proceed directly to /execute" with "return the amendment" to prevent fast-path from hijacking `/upstack-run` orchestration, which caused later steps (docs, version bump) to be skipped
- **`/ship-pr` Step 1** — replaced vague "write or update docs" with concrete checklist requiring explicit UPDATED/NO CHANGE NEEDED report for README.md, CHANGELOG.md, docs/, and CLAUDE.md
- **`/upstack-run` Step 5** — marked Ship step as MANDATORY with explicit "do not skip" and "do not end conversation without completing" guardrails

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
