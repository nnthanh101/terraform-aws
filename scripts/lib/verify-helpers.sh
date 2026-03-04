#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# verify-helpers.sh — Shared helpers for deployment verification scripts
#
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/lib/verify-helpers.sh"
# Provides: check_pass(), check_fail(), check_warn() + PASS/FAIL/WARN/TOTAL counters

PASS=0; FAIL=0; WARN=0; TOTAL=0

check_pass() {
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1))
  echo "PASS [$TOTAL]: $1"
}

check_fail() {
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "FAIL [$TOTAL]: $1"
  echo "  REASON: $2"
}

check_warn() {
  TOTAL=$((TOTAL + 1)); WARN=$((WARN + 1))
  echo "WARN [$TOTAL]: $1"
  echo "  DETAIL: $2"
}
