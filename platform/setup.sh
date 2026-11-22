#!/usr/bin/env bash
# Platform-in-a-Box -- setup.
#
# From a clone of ONLY the hub repo (hsooligan95/hsooligan95), this:
#   1. checks prerequisites (git, python3 >= 3.11, node >= 20, npm,
#      and a working python3 venv module),
#   2. clones the 15 project repos as siblings under ./fleet/,
#   3. creates a .venv per Python repo and installs its dependencies
#      (mirroring agent-trace's ci/run_drill_ci.sh install logic), and
#      npm-ci + builds the two TypeScript repos.
#
# Idempotent: repos already cloned are left alone, and a repo whose
# .venv carries the deps stamp is not reinstalled. Delete fleet/<repo>
# (or its .venv) to force a fresh install of that one repo.
#
# No API keys, no accounts, no cloud spend: everything runs locally
# against stub models and mock data, exactly like the repos' own CI.
set -uo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$PLATFORM_DIR/.." && pwd)"
FLEET="$HUB_ROOT/fleet"
STAMP=".platform-deps-stamp"
GH="https://github.com/hsooligan95"

REPOS=(
  agent-trace agent-gate agent-canary blast-radius agent-chaos
  agent-ledger agent-flightsim factory-floor-agent rag-evaluation-harness
  mcp-cloud-explorer mission-control cred-broker context-vault
  agentcore-port ato-in-a-box
)

log()  { printf '\n=== %s ===\n' "$*"; }
warn() { printf '!! %s\n' "$*" >&2; }

# ---------------------------------------------------------------- prereqs
log "prerequisites"
missing=0

if command -v git >/dev/null 2>&1; then
  echo "git        : $(git --version)"
else
  warn "git is not installed.  WSL/Ubuntu:  sudo apt install git"
  missing=1
fi

PY=""
if command -v python3 >/dev/null 2>&1; then
  if python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)'; then
    PY=python3
    echo "python3    : $(python3 --version 2>&1)"
  else
    warn "python3 is $(python3 --version 2>&1) but >= 3.11 is required."
    warn "WSL/Ubuntu:  sudo apt install python3.11 (or newer) and re-run."
    missing=1
  fi
else
  warn "python3 is not installed.  WSL/Ubuntu:  sudo apt install python3 python3-venv"
  missing=1
fi

if command -v node >/dev/null 2>&1; then
  node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "$node_major" -ge 20 ] 2>/dev/null; then
    echo "node       : $(node --version)"
  else
    warn "node is $(node --version) but >= 20 is required (agent-gate, mcp-cloud-explorer)."
    warn "Install a current Node LTS from https://nodejs.org or via nvm."
    missing=1
  fi
else
  warn "node is not installed but >= 20 is required (agent-gate, mcp-cloud-explorer)."
  warn "Install a current Node LTS from https://nodejs.org or via nvm."
  missing=1
fi

if command -v npm >/dev/null 2>&1; then
  echo "npm        : $(npm --version)"
else
  warn "npm is not installed (it ships with Node.js)."
  missing=1
fi

# venv module probe: Ubuntu splits venv support into its own package,
# and the failure otherwise surfaces mid-install with a cryptic error.
if [ -n "$PY" ]; then
  probe="$(mktemp -d)"
  if "$PY" -m venv "$probe/v" >/dev/null 2>&1; then
    echo "python venv: ok"
  else
    warn "python3 -m venv does not work on this machine."
    warn "WSL/Ubuntu:  sudo apt install python3-venv python3.11-venv (match your python3 minor version)"
    missing=1
  fi
  rm -rf "$probe"
fi

if [ "$missing" -ne 0 ]; then
  warn "prerequisite check failed -- fix the items above and re-run ./platform/setup.sh"
  exit 1
fi

# ---------------------------------------------------------------- clones
log "cloning the fleet into $FLEET"
mkdir -p "$FLEET"
for r in "${REPOS[@]}"; do
  if [ -d "$FLEET/$r/.git" ]; then
    echo "$r: already cloned, skipping"
  elif [ -e "$FLEET/$r" ]; then
    warn "$FLEET/$r exists but is not a git clone -- move it away and re-run."
    exit 1
  else
    echo "$r: cloning..."
    git clone --quiet --depth 1 "$GH/$r.git" "$FLEET/$r" || {
      warn "clone of $r failed (network?). Fix and re-run; completed repos are kept."
      exit 1
    }
  fi
done

# ---------------------------------------------------------------- installs
# venv_for <repo-dir> <install-command...>
# Mirrors agent-trace/ci/run_drill_ci.sh: create .venv if absent, run
# the install with the venv's pip unless a previous run stamped it.
venv_for() {
  local dir="$1"; shift
  if [ ! -x "$dir/.venv/bin/python" ]; then
    "$PY" -m venv "$dir/.venv" || {
      warn "venv creation failed for ${dir##*/} -- see the python3-venv note above."
      exit 1
    }
  fi
  if [ -f "$dir/.venv/$STAMP" ]; then
    echo "${dir##*/}: deps already installed (stamp present, skipping)"
    return 0
  fi
  echo "${dir##*/}: installing deps..."
  "$dir/.venv/bin/pip" install --quiet --upgrade pip
  ( cd "$dir" && "$@" ) || { warn "dependency install failed for ${dir##*/}"; exit 1; }
  touch "$dir/.venv/$STAMP"
}

log "python deps (one .venv per repo)"
# agent-trace: stdlib core; [dev] adds pytest for its suite, and the
# drill additionally drives blast-radius with this venv, so its frozen
# requirements land here too (same as the CI glue).
venv_for "$FLEET/agent-trace" "$FLEET/agent-trace/.venv/bin/pip" install --quiet \
  -e ".[dev]" -r "$FLEET/blast-radius/requirements.txt"
venv_for "$FLEET/agent-canary" "$FLEET/agent-canary/.venv/bin/pip" \
  install --quiet -e ".[dev]"
venv_for "$FLEET/blast-radius" "$FLEET/blast-radius/.venv/bin/pip" \
  install --quiet -r requirements.txt
venv_for "$FLEET/agent-chaos" "$FLEET/agent-chaos/.venv/bin/pip" \
  install --quiet -e ".[test]"
venv_for "$FLEET/agent-ledger" "$FLEET/agent-ledger/.venv/bin/pip" \
  install --quiet -r requirements.txt
venv_for "$FLEET/agent-flightsim" "$FLEET/agent-flightsim/.venv/bin/pip" \
  install --quiet -e ".[dev]" -r requirements.txt
venv_for "$FLEET/factory-floor-agent" "$FLEET/factory-floor-agent/.venv/bin/pip" \
  install --quiet -r requirements.txt
venv_for "$FLEET/rag-evaluation-harness" "$FLEET/rag-evaluation-harness/.venv/bin/pip" \
  install --quiet -r requirements.txt
venv_for "$FLEET/mission-control" "$FLEET/mission-control/.venv/bin/pip" \
  install --quiet -e ".[dev]"
venv_for "$FLEET/cred-broker" "$FLEET/cred-broker/.venv/bin/pip" \
  install --quiet -e . "pytest>=8"
venv_for "$FLEET/context-vault" "$FLEET/context-vault/.venv/bin/pip" \
  install --quiet -e ".[dev]"
venv_for "$FLEET/agentcore-port" "$FLEET/agentcore-port/.venv/bin/pip" \
  install --quiet -r requirements.txt
venv_for "$FLEET/ato-in-a-box" "$FLEET/ato-in-a-box/.venv/bin/pip" \
  install --quiet -e . "pytest>=8"

log "typescript deps (npm ci + build; dist/ is not committed)"
for r in agent-gate mcp-cloud-explorer; do
  d="$FLEET/$r"
  if [ ! -d "$d/node_modules" ]; then
    echo "$r: npm ci..."
    ( cd "$d" && npm ci --no-audit --no-fund ) || { warn "npm ci failed for $r"; exit 1; }
  else
    echo "$r: node_modules present, skipping npm ci"
  fi
  if [ ! -f "$d/dist/index.js" ] && [ ! -f "$d/dist/src/index.js" ]; then
    echo "$r: npm run build..."
    ( cd "$d" && npm run build ) || { warn "build failed for $r"; exit 1; }
  else
    echo "$r: dist/ present, skipping build"
  fi
done

log "setup complete"
cat <<EOF
Fleet layout: $FLEET

Next:
  ./platform/test-all.sh   # every repo's own test suite, one by one
  ./platform/demo.sh       # the platform drill + live AgentTrace dashboard
EOF
