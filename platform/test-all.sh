#!/usr/bin/env bash
# Platform-in-a-Box -- test every component separately.
#
# Runs each fleet repo's OWN test suite, one repo at a time, in that
# repo's own venv (or npm, for the TypeScript repos), then prints a
# summary table: repo, command, passed / failed counts, duration.
# A suite that fails does not stop the others -- you see the whole
# fleet's state -- but the script exits non-zero if anything failed.
#
# Run ./platform/setup.sh first.
set -uo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$PLATFORM_DIR/.." && pwd)"
FLEET="$HUB_ROOT/fleet"

if [ ! -d "$FLEET" ]; then
  echo "!! no fleet/ directory -- run ./platform/setup.sh first" >&2
  exit 1
fi

RESULTS="$(mktemp)"
trap 'rm -f "$RESULTS"' EXIT
overall_fail=0

num() { # num <pattern> <file> -> first integer match or 0
  local n
  n="$(grep -oE "$1" "$2" 2>/dev/null | grep -oE '[0-9]+' | tail -1)"
  echo "${n:-0}"
}

record() { # record <repo> <cmd-label> <passed> <failed> <seconds> <ok:0/1>
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" >> "$RESULTS"
  [ "$6" -eq 0 ] || overall_fail=1
}

run_pytest() { # run_pytest <repo> [pytest args...]
  local repo="$1"; shift
  local dir="$FLEET/$repo" logf start end rc passed failed errors
  if [ ! -x "$dir/.venv/bin/python" ]; then
    echo "== $repo: NOT SET UP (no .venv) -- run ./platform/setup.sh"
    record "$repo" "pytest" - - 0 1
    return
  fi
  logf="$(mktemp)"
  echo "== $repo: .venv/bin/python -m pytest $*"
  start=$SECONDS
  ( cd "$dir" && .venv/bin/python -m pytest "$@" ) >"$logf" 2>&1
  rc=$?
  end=$SECONDS
  tail -3 "$logf" | sed 's/^/   /'
  passed="$(num '[0-9]+ passed' "$logf")"
  failed="$(num '[0-9]+ failed' "$logf")"
  errors="$(num '[0-9]+ errors?' "$logf")"
  record "$repo" "pytest" "$passed" "$((failed + errors))" "$((end - start))" "$rc"
  rm -f "$logf"
}

run_unittest() { # run_unittest <repo>
  local repo="$1"
  local dir="$FLEET/$repo" logf start end rc ran fails errs skips passed
  if [ ! -x "$dir/.venv/bin/python" ]; then
    echo "== $repo: NOT SET UP (no .venv) -- run ./platform/setup.sh"
    record "$repo" "unittest" - - 0 1
    return
  fi
  logf="$(mktemp)"
  echo "== $repo: .venv/bin/python -m unittest discover tests"
  start=$SECONDS
  ( cd "$dir" && .venv/bin/python -m unittest discover tests ) >"$logf" 2>&1
  rc=$?
  end=$SECONDS
  tail -3 "$logf" | sed 's/^/   /'
  ran="$(num 'Ran [0-9]+ tests?' "$logf")"
  fails="$(num 'failures=[0-9]+' "$logf")"
  errs="$(num 'errors=[0-9]+' "$logf")"
  skips="$(num 'skipped=[0-9]+' "$logf")"
  passed=$((ran - fails - errs - skips))
  [ "$passed" -ge 0 ] || passed=0
  record "$repo" "unittest" "$passed" "$((fails + errs))" "$((end - start))" "$rc"
  rm -f "$logf"
}

run_npm() { # run_npm <repo> <script> <parse:node-test|smoke>
  local repo="$1" script="$2" parse="$3"
  local dir="$FLEET/$repo" logf start end rc passed failed
  if [ ! -d "$dir/node_modules" ]; then
    echo "== $repo: NOT SET UP (no node_modules) -- run ./platform/setup.sh"
    record "$repo" "npm run $script" - - 0 1
    return
  fi
  logf="$(mktemp)"
  echo "== $repo: npm run $script"
  start=$SECONDS
  ( cd "$dir" && npm run "$script" ) >"$logf" 2>&1
  rc=$?
  end=$SECONDS
  tail -3 "$logf" | sed 's/^/   /'
  if [ "$parse" = "node-test" ]; then
    passed="$(num 'pass [0-9]+' "$logf")"
    failed="$(num 'fail [0-9]+' "$logf")"
  else
    passed="-"; failed="-"
    grep -qE '[0-9]+/[0-9]+' "$logf" && passed="$(grep -oE '[0-9]+/[0-9]+' "$logf" | tail -1)"
  fi
  record "$repo" "npm run $script" "$passed" "$failed" "$((end - start))" "$rc"
  rm -f "$logf"
}

echo "Testing each component separately (fleet: $FLEET)"
echo

run_pytest    agent-trace
run_pytest    agent-canary
run_pytest    blast-radius
run_pytest    agent-chaos
run_pytest    agent-ledger
run_pytest    agent-flightsim
run_unittest  factory-floor-agent
run_unittest  rag-evaluation-harness
run_pytest    mission-control
run_pytest    cred-broker
run_pytest    context-vault
run_pytest    agentcore-port tests/
run_pytest    ato-in-a-box
run_npm       agent-gate test node-test
run_npm       mcp-cloud-explorer smoke smoke

echo
echo "================ summary ================"
printf '%-24s %-18s %8s %8s %8s  %s\n' "repo" "command" "passed" "failed" "time" "result"
total_pass=0
while IFS=$'\t' read -r repo cmd passed failed secs ok; do
  if [ "$ok" -eq 0 ]; then res="PASS"; else res="FAIL"; fi
  printf '%-24s %-18s %8s %8s %6ss  %s\n' "$repo" "$cmd" "$passed" "$failed" "$secs" "$res"
  case "$passed" in (*[!0-9]*|'') : ;; (*) total_pass=$((total_pass + passed)) ;; esac
done < "$RESULTS"
echo "total passed (countable suites): $total_pass"

if [ "$overall_fail" -ne 0 ]; then
  echo "RESULT: at least one suite FAILED"
  exit 1
fi
echo "RESULT: all suites green"
