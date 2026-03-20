#!/usr/bin/env bash
# Tests for bin/upstack-config
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG="$PROJECT_DIR/bin/upstack-config"

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

setup() {
  TEST_STATE_DIR=$(mktemp -d)
  export UPSTACK_STATE_DIR="$TEST_STATE_DIR"
}

teardown() {
  rm -rf "$TEST_STATE_DIR"
}

# ─── Test: get on missing config returns empty ────────────────
setup
RESULT=$("$CONFIG" get foo 2>/dev/null || true)
assert_eq "get missing key returns empty" "" "$RESULT"
teardown

# ─── Test: set then get ──────────────────────────────────────
setup
"$CONFIG" set mykey myvalue
RESULT=$("$CONFIG" get mykey)
assert_eq "set then get returns value" "myvalue" "$RESULT"
teardown

# ─── Test: set overwrites existing key ────────────────────────
setup
"$CONFIG" set mykey original
"$CONFIG" set mykey updated
RESULT=$("$CONFIG" get mykey)
assert_eq "set overwrites existing key" "updated" "$RESULT"
teardown

# ─── Test: set multiple keys ─────────────────────────────────
setup
"$CONFIG" set alpha one
"$CONFIG" set beta two
RESULT_A=$("$CONFIG" get alpha)
RESULT_B=$("$CONFIG" get beta)
assert_eq "get alpha" "one" "$RESULT_A"
assert_eq "get beta" "two" "$RESULT_B"
teardown

# ─── Test: list shows all config ──────────────────────────────
setup
"$CONFIG" set auto_upgrade true
"$CONFIG" set update_check false
RESULT=$("$CONFIG" list)
echo "$RESULT" | grep -q "auto_upgrade: true" && L1="found" || L1="missing"
echo "$RESULT" | grep -q "update_check: false" && L2="found" || L2="missing"
assert_eq "list contains auto_upgrade" "found" "$L1"
assert_eq "list contains update_check" "found" "$L2"
teardown

# ─── Test: list on missing config returns empty ───────────────
setup
RESULT=$("$CONFIG" list)
assert_eq "list on missing config returns empty" "" "$RESULT"
teardown

# ─── Test: no args prints usage and exits 1 ──────────────────
setup
RESULT=$("$CONFIG" 2>&1 || true)
echo "$RESULT" | grep -q "Usage:" && U="found" || U="missing"
assert_eq "no args shows usage" "found" "$U"
teardown

# ─── Test: set creates state dir if missing ───────────────────
setup
rm -rf "$TEST_STATE_DIR"
"$CONFIG" set created yes
RESULT=$("$CONFIG" get created)
assert_eq "set creates state dir" "yes" "$RESULT"
teardown

# ─── Test: get with boolean values ────────────────────────────
setup
"$CONFIG" set update_check false
RESULT=$("$CONFIG" get update_check)
assert_eq "get boolean false" "false" "$RESULT"
"$CONFIG" set update_check true
RESULT=$("$CONFIG" get update_check)
assert_eq "get boolean true" "true" "$RESULT"
teardown

# ─── Summary ──────────────────────────────────────────────────
echo ""
echo "upstack-config: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
