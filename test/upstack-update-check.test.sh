#!/usr/bin/env bash
# Tests for bin/upstack-update-check
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECK="$PROJECT_DIR/bin/upstack-update-check"

PASS=0
FAIL=0

assert_eq() {
  local test_name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name"
    echo "    expected to contain: '$needle'"
    echo "    actual: '$haystack'"
    FAIL=$((FAIL + 1))
  fi
}

setup() {
  TEST_STATE_DIR=$(mktemp -d)
  TEST_UPSTACK_DIR=$(mktemp -d)
  # Copy bin scripts so upstack-update-check can find upstack-config
  cp -r "$PROJECT_DIR/bin" "$TEST_UPSTACK_DIR/bin"
  echo "1.0.0" > "$TEST_UPSTACK_DIR/VERSION"
  export UPSTACK_STATE_DIR="$TEST_STATE_DIR"
  export UPSTACK_DIR="$TEST_UPSTACK_DIR"
  # Point to a local file server that won't exist — forces curl to fail
  # We'll override UPSTACK_REMOTE_URL per test as needed
  export UPSTACK_REMOTE_URL="file:///dev/null"
}

teardown() {
  rm -rf "$TEST_STATE_DIR" "$TEST_UPSTACK_DIR"
}

# ─── Test: up to date (local = remote) ───────────────────────
setup
# Serve the same version as local
echo "1.0.0" > "$TEST_STATE_DIR/remote-version"
export UPSTACK_REMOTE_URL="file://$TEST_STATE_DIR/remote-version"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "up to date produces no output" "" "$RESULT"
# Verify cache was written
CACHE=$(cat "$TEST_STATE_DIR/last-update-check" 2>/dev/null || true)
assert_contains "cache says UP_TO_DATE" "UP_TO_DATE 1.0.0" "$CACHE"
teardown

# ─── Test: upgrade available ──────────────────────────────────
setup
echo "2.0.0" > "$TEST_STATE_DIR/remote-version"
export UPSTACK_REMOTE_URL="file://$TEST_STATE_DIR/remote-version"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "upgrade available output" "UPGRADE_AVAILABLE 1.0.0 2.0.0" "$RESULT"
teardown

# ─── Test: just upgraded marker ───────────────────────────────
setup
mkdir -p "$TEST_STATE_DIR"
echo "0.9.0" > "$TEST_STATE_DIR/just-upgraded-from"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "just upgraded output" "JUST_UPGRADED 0.9.0 1.0.0" "$RESULT"
# Marker should be cleaned up
[ ! -f "$TEST_STATE_DIR/just-upgraded-from" ] && M="cleaned" || M="still-exists"
assert_eq "marker file removed" "cleaned" "$M"
teardown

# ─── Test: update_check disabled ──────────────────────────────
setup
mkdir -p "$TEST_STATE_DIR"
echo "update_check: false" > "$TEST_STATE_DIR/config.yaml"
echo "2.0.0" > "$TEST_STATE_DIR/remote-version"
export UPSTACK_REMOTE_URL="file://$TEST_STATE_DIR/remote-version"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "disabled check produces no output" "" "$RESULT"
teardown

# ─── Test: cache freshness (fresh cache, up to date) ─────────
setup
mkdir -p "$TEST_STATE_DIR"
echo "UP_TO_DATE 1.0.0" > "$TEST_STATE_DIR/last-update-check"
# Touch to make it fresh
touch "$TEST_STATE_DIR/last-update-check"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "fresh UP_TO_DATE cache exits silently" "" "$RESULT"
teardown

# ─── Test: cache freshness (fresh cache, upgrade available) ──
setup
mkdir -p "$TEST_STATE_DIR"
echo "UPGRADE_AVAILABLE 1.0.0 2.0.0" > "$TEST_STATE_DIR/last-update-check"
touch "$TEST_STATE_DIR/last-update-check"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "fresh UPGRADE_AVAILABLE cache re-outputs" "UPGRADE_AVAILABLE 1.0.0 2.0.0" "$RESULT"
teardown

# ─── Test: snooze (active, same version) ──────────────────────
setup
mkdir -p "$TEST_STATE_DIR"
NOW=$(date +%s)
echo "2.0.0 1 $NOW" > "$TEST_STATE_DIR/update-snoozed"
echo "UPGRADE_AVAILABLE 1.0.0 2.0.0" > "$TEST_STATE_DIR/last-update-check"
touch "$TEST_STATE_DIR/last-update-check"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "active snooze suppresses output" "" "$RESULT"
teardown

# ─── Test: snooze (expired) ──────────────────────────────────
setup
mkdir -p "$TEST_STATE_DIR"
OLD_EPOCH=$(($(date +%s) - 90000))  # > 24h ago
echo "2.0.0 1 $OLD_EPOCH" > "$TEST_STATE_DIR/update-snoozed"
echo "UPGRADE_AVAILABLE 1.0.0 2.0.0" > "$TEST_STATE_DIR/last-update-check"
touch "$TEST_STATE_DIR/last-update-check"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "expired snooze shows upgrade" "UPGRADE_AVAILABLE 1.0.0 2.0.0" "$RESULT"
teardown

# ─── Test: snooze resets on new version ───────────────────────
setup
mkdir -p "$TEST_STATE_DIR"
NOW=$(date +%s)
echo "1.5.0 1 $NOW" > "$TEST_STATE_DIR/update-snoozed"
echo "2.0.0" > "$TEST_STATE_DIR/remote-version"
export UPSTACK_REMOTE_URL="file://$TEST_STATE_DIR/remote-version"
# No cache — forces remote check
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "snooze reset on new version" "UPGRADE_AVAILABLE 1.0.0 2.0.0" "$RESULT"
teardown

# ─── Test: missing VERSION file exits silently ────────────────
setup
rm -f "$TEST_UPSTACK_DIR/VERSION"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "missing VERSION exits silently" "" "$RESULT"
teardown

# ─── Test: invalid remote response treated as up to date ─────
setup
echo "<html>404 Not Found</html>" > "$TEST_STATE_DIR/remote-version"
export UPSTACK_REMOTE_URL="file://$TEST_STATE_DIR/remote-version"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "invalid remote response is silent" "" "$RESULT"
teardown

# ─── Test: corrupt snooze file is ignored ─────────────────────
setup
mkdir -p "$TEST_STATE_DIR"
echo "garbage" > "$TEST_STATE_DIR/update-snoozed"
echo "UPGRADE_AVAILABLE 1.0.0 2.0.0" > "$TEST_STATE_DIR/last-update-check"
touch "$TEST_STATE_DIR/last-update-check"
RESULT=$("$CHECK" 2>/dev/null || true)
assert_eq "corrupt snooze file shows upgrade" "UPGRADE_AVAILABLE 1.0.0 2.0.0" "$RESULT"
teardown

# ─── Summary ──────────────────────────────────────────────────
echo ""
echo "upstack-update-check: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
