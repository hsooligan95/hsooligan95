#!/usr/bin/env bash
# Platform-in-a-Box -- the together part.
#
# Runs the phase-2 platform drill from agent-trace (one trace ID across
# agent-canary, agent-gate, blast-radius, factory-floor-agent,
# agent-ledger and agent-chaos, into one hash-chained AgentTrace
# store), then serves the AgentTrace dashboard on the drill's store so
# you can watch the run on a verified timeline.
#
# The dashboard is read-only and local. Press Ctrl+C to stop it.
# Run ./platform/setup.sh first. Set PORT to choose a starting port
# (default 8765; if busy, the next free port is used and announced).
set -uo pipefail

PLATFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$PLATFORM_DIR/.." && pwd)"
FLEET="$HUB_ROOT/fleet"
TRACE="$FLEET/agent-trace"

if [ ! -x "$TRACE/.venv/bin/python" ]; then
  echo "!! fleet not set up -- run ./platform/setup.sh first" >&2
  exit 1
fi

echo "=== platform drill (agent-trace/drill/run_drill.py) ==="
( cd "$TRACE" && .venv/bin/python drill/run_drill.py ) || {
  echo "!! drill failed -- see output above" >&2
  exit 1
}

OUT_DIR="$(ls -dt "$TRACE"/drill/output/trace-drill-* 2>/dev/null | head -1)"
STORE="$OUT_DIR/store.jsonl"
if [ -z "$OUT_DIR" ] || [ ! -f "$STORE" ]; then
  echo "!! drill finished but no store.jsonl found under $TRACE/drill/output" >&2
  exit 1
fi
echo
echo "drill store: $STORE ($(wc -l < "$STORE") events)"

# ---- pick a free port (start at $PORT or 8765, walk up if busy)
port="${PORT:-8765}"
tries=0
while [ "$tries" -lt 25 ]; do
  if python3 -c 'import socket,sys; s=socket.socket(); s.settimeout(0.3); sys.exit(0 if s.connect_ex(("127.0.0.1", int(sys.argv[1]))) != 0 else 1)' "$port" 2>/dev/null; then
    break
  fi
  echo "port $port is busy, trying $((port + 1))"
  port=$((port + 1)); tries=$((tries + 1))
done

cat <<EOF

=== AgentTrace dashboard (read-only) ===
URL:  http://127.0.0.1:$port/
Stop: Ctrl+C

EOF
cd "$TRACE"
exec .venv/bin/python -m dashboard.server --store "$STORE" --port "$port"
