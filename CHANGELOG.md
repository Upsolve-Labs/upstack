# Changelog

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
