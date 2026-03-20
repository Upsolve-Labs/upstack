---
name: upgrade
description: |
  Upgrade upstack to the latest version. Detects global vs vendored install,
  runs the upgrade, and shows what's new.
disable-model-invocation: true
---

## Update Check (run first)

```bash
_UPD=$(~/.claude/skills/upstack/bin/upstack-update-check 2>/dev/null || .claude/skills/upstack/bin/upstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
```

If output shows `UPGRADE_AVAILABLE <old> <new>`: follow the "Inline upgrade flow" below. If `JUST_UPGRADED <from> <to>`: tell user "Running upstack v{to} (just updated!)" and continue.

# /upgrade

Upgrade upstack to the latest version and show what's new.

## Inline upgrade flow

This section is referenced by all skill preambles when they detect `UPGRADE_AVAILABLE`.

### Step 1: Ask the user (or auto-upgrade)

First, check if auto-upgrade is enabled:
```bash
_AUTO=""
[ "${UPSTACK_AUTO_UPGRADE:-}" = "1" ] && _AUTO="true"
[ -z "$_AUTO" ] && _AUTO=$(~/.claude/skills/upstack/bin/upstack-config get auto_upgrade 2>/dev/null || .claude/skills/upstack/bin/upstack-config get auto_upgrade 2>/dev/null || true)
echo "AUTO_UPGRADE=$_AUTO"
```

**If `AUTO_UPGRADE=true` or `AUTO_UPGRADE=1`:** Skip AskUserQuestion. Log "Auto-upgrading upstack v{old} → v{new}..." and proceed directly to Step 2. If `./install.sh` fails during auto-upgrade, restore from backup (`.bak` directory) and warn the user: "Auto-upgrade failed — restored previous version. Run `/upgrade` manually to retry."

**Otherwise**, use AskUserQuestion:
- Question: "upstack **v{new}** is available (you're on v{old}). Upgrade now?"
- Options: ["Yes, upgrade now", "Always keep me up to date", "Not now", "Never ask again"]

**If "Yes, upgrade now":** Proceed to Step 2.

**If "Always keep me up to date":**
```bash
~/.claude/skills/upstack/bin/upstack-config set auto_upgrade true 2>/dev/null || .claude/skills/upstack/bin/upstack-config set auto_upgrade true 2>/dev/null
```
Tell user: "Auto-upgrade enabled. Future updates will install automatically." Then proceed to Step 2.

**If "Not now":** Write snooze state with escalating backoff (first snooze = 24h, second = 48h, third+ = 1 week), then continue with the current skill. Do not mention the upgrade again.
```bash
_SNOOZE_FILE="${UPSTACK_STATE_DIR:-$HOME/.upstack}/update-snoozed"
_REMOTE_VER="{new}"
_CUR_LEVEL=0
if [ -f "$_SNOOZE_FILE" ]; then
  _SNOOZED_VER=$(awk '{print $1}' "$_SNOOZE_FILE")
  if [ "$_SNOOZED_VER" = "$_REMOTE_VER" ]; then
    _CUR_LEVEL=$(awk '{print $2}' "$_SNOOZE_FILE")
    case "$_CUR_LEVEL" in *[!0-9]*) _CUR_LEVEL=0 ;; esac
  fi
fi
_NEW_LEVEL=$((_CUR_LEVEL + 1))
[ "$_NEW_LEVEL" -gt 3 ] && _NEW_LEVEL=3
echo "$_REMOTE_VER $_NEW_LEVEL $(date +%s)" > "$_SNOOZE_FILE"
```
Note: `{new}` is the remote version from the `UPGRADE_AVAILABLE` output — substitute it from the update check result.

Tell user the snooze duration: "Next reminder in 24h" (or 48h or 1 week, depending on level). Tip: "Set `auto_upgrade: true` in `~/.upstack/config.yaml` for automatic upgrades."

**If "Never ask again":**
```bash
~/.claude/skills/upstack/bin/upstack-config set update_check false 2>/dev/null || .claude/skills/upstack/bin/upstack-config set update_check false 2>/dev/null
```
Tell user: "Update checks disabled. Run `~/.claude/skills/upstack/bin/upstack-config set update_check true` to re-enable."
Continue with the current skill.

### Step 2: Detect install type

```bash
if [ -d "$HOME/.claude/skills/upstack/.git" ]; then
  INSTALL_TYPE="global-git"
  INSTALL_DIR="$HOME/.claude/skills/upstack"
elif [ -d ".claude/skills/upstack/.git" ]; then
  INSTALL_TYPE="local-git"
  INSTALL_DIR=".claude/skills/upstack"
elif [ -d ".claude/skills/upstack" ]; then
  INSTALL_TYPE="vendored"
  INSTALL_DIR=".claude/skills/upstack"
elif [ -d "$HOME/.claude/skills/upstack" ]; then
  INSTALL_TYPE="vendored-global"
  INSTALL_DIR="$HOME/.claude/skills/upstack"
else
  echo "ERROR: upstack not found"
  exit 1
fi
echo "Install type: $INSTALL_TYPE at $INSTALL_DIR"
```

### Step 3: Save old version

```bash
OLD_VERSION=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")
```

### Step 4: Upgrade

**For git installs** (global-git, local-git):
```bash
cd "$INSTALL_DIR"
STASH_OUTPUT=$(git stash 2>&1)
git fetch origin
git reset --hard origin/main
./install.sh
```
If `$STASH_OUTPUT` contains "Saved working directory", warn the user: "Note: local changes were stashed. Run `git stash pop` in the skill directory to restore them."

**For vendored installs** (vendored, vendored-global):
```bash
PARENT=$(dirname "$INSTALL_DIR")
TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/upsolve/upstack.git "$TMP_DIR/upstack"
mv "$INSTALL_DIR" "$INSTALL_DIR.bak"
mv "$TMP_DIR/upstack" "$INSTALL_DIR"
cd "$INSTALL_DIR" && ./install.sh
rm -rf "$INSTALL_DIR.bak" "$TMP_DIR"
```

### Step 4.5: Sync local vendored copy

After upgrading the primary install, check if there's also a local copy in the current project that needs updating:

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
LOCAL_UPSTACK=""
if [ -n "$_ROOT" ] && [ -d "$_ROOT/.claude/skills/upstack" ]; then
  _RESOLVED_LOCAL=$(cd "$_ROOT/.claude/skills/upstack" && pwd -P)
  _RESOLVED_PRIMARY=$(cd "$INSTALL_DIR" && pwd -P)
  if [ "$_RESOLVED_LOCAL" != "$_RESOLVED_PRIMARY" ]; then
    LOCAL_UPSTACK="$_ROOT/.claude/skills/upstack"
  fi
fi
echo "LOCAL_UPSTACK=$LOCAL_UPSTACK"
```

If `LOCAL_UPSTACK` is non-empty, update it by copying from the freshly-upgraded primary install:
```bash
mv "$LOCAL_UPSTACK" "$LOCAL_UPSTACK.bak"
cp -Rf "$INSTALL_DIR" "$LOCAL_UPSTACK"
rm -rf "$LOCAL_UPSTACK/.git"
cd "$LOCAL_UPSTACK" && ./install.sh
rm -rf "$LOCAL_UPSTACK.bak"
```
Tell user: "Also updated vendored copy at `$LOCAL_UPSTACK` — commit `.claude/skills/upstack/` when you're ready."

### Step 5: Write marker + clear cache

```bash
mkdir -p "${UPSTACK_STATE_DIR:-$HOME/.upstack}"
echo "$OLD_VERSION" > "${UPSTACK_STATE_DIR:-$HOME/.upstack}/just-upgraded-from"
rm -f "${UPSTACK_STATE_DIR:-$HOME/.upstack}/last-update-check"
rm -f "${UPSTACK_STATE_DIR:-$HOME/.upstack}/update-snoozed"
```

### Step 6: Show What's New

Read `$INSTALL_DIR/CHANGELOG.md`. Find all version entries between the old version and the new version. Summarize as 5-7 bullets grouped by theme. Focus on user-facing changes.

Format:
```
upstack v{new} — upgraded from v{old}!

What's new:
- [bullet 1]
- [bullet 2]
- ...

Happy shipping!
```

### Step 7: Continue

After showing What's New, continue with whatever skill the user originally invoked. The upgrade is done — no further action needed.

---

## Standalone usage

When invoked directly as `/upgrade` (not from a preamble), follow Steps 2-6 above. If already on the latest version, tell the user: "You're already on the latest version (v{version})."
