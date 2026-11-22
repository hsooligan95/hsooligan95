# Platform-in-a-Box

One-command local setup for the whole agent platform: clone **only this
hub repo**, run three scripts, and you can test every component on its
own and then watch them work together. No API keys, no accounts, no
cloud spend — everything runs locally against stub models and mock
data, the same way the repos' own CI runs.

## Quick start

```bash
git clone https://github.com/hsooligan95/hsooligan95.git
cd hsooligan95
./platform/setup.sh      # clone the 15 project repos + install deps
./platform/test-all.sh   # every repo's own test suite, one by one
./platform/demo.sh       # the platform drill + live dashboard
```

## What each script does

### `./platform/setup.sh`

Checks prerequisites first and fails with a plain message (and the fix)
if anything is missing:

- `git`
- `python3` >= 3.11, with a working `venv` module
  (on Ubuntu/WSL: `sudo apt install python3 python3-venv`)
- `node` >= 20 and `npm` (for the two TypeScript repos)

Then it clones the 15 project repos as siblings under `./fleet/` and
installs dependencies: a `.venv` per Python repo (mirroring
`agent-trace/ci/run_drill_ci.sh`, the same install logic the nightly CI
drill uses) and `npm ci` + build for `agent-gate` and
`mcp-cloud-explorer`.

It is idempotent: re-running skips repos already cloned and venvs
already installed (a `.platform-deps-stamp` in each `.venv`). Delete
`fleet/<repo>` — or just its `.venv` — to force a fresh install of one
repo.

### `./platform/test-all.sh`

Runs **each repo's own test suite separately**, in its own venv, and
prints a summary table (repo, command, passed / failed, duration).
One suite failing does not stop the others, but the script exits
non-zero if anything failed, so it can gate other automation.

### `./platform/demo.sh`

The together part. Runs the phase-2 platform drill from `agent-trace`:
one trace ID across agent-canary (promotion block), agent-gate
(screening), blast-radius (plan → approve → kill -9 → resume → verify →
rollback), factory-floor-agent (grounded answer), agent-ledger (cost
accounting) and agent-chaos (failure matrix), all recorded into one
hash-chained AgentTrace store that is verified at the end of the run.

Then it starts the AgentTrace dashboard (read-only) on the drill's
store and prints the URL — `http://127.0.0.1:8765/` by default; if that
port is busy it picks the next free one and says so. Set `PORT` to
choose a different starting port. **Ctrl+C stops it.**

## Expected runtimes

Measured on a clean clone (this project's VM, 2026-11-22; a typical
WSL2 laptop will differ somewhat):

| Phase | First run | Re-run |
| --- | --- | --- |
| `setup.sh` | ~11 min (clone 15 repos + all installs) | ~10 s (stamps skip installs) |
| `test-all.sh` | ~2 min | same |
| `demo.sh` drill | ~1 min | same (dashboard then runs until Ctrl+C) |

## WSL notes

- Works under WSL2 with Ubuntu: clone inside the WSL filesystem
  (e.g. under `~/`), not under `/mnt/c` — venvs and `node_modules` are
  much slower on the Windows mount, and file permissions can bite.
- The dashboard URL is `localhost` — from WSL2 it is reachable from
  your Windows browser at the same `http://127.0.0.1:<port>/` address.
- Nothing here needs Windows-side tooling, Docker, or WSL features
  beyond a normal Ubuntu install.

## Layout after setup

```
hsooligan95/            <- this hub repo
  platform/             <- these scripts
  fleet/
    agent-trace/        <- trace/audit spine + drill + dashboard
    agent-gate/  agent-canary/  blast-radius/  agent-chaos/
    agent-ledger/  agent-flightsim/  factory-floor-agent/
    rag-evaluation-harness/  mcp-cloud-explorer/  mission-control/
    cred-broker/  context-vault/  agentcore-port/  ato-in-a-box/
```

The sibling layout is load-bearing: several repos find each other by
relative path (the drill drives its producers from their own `.venv`s;
agent-flightsim runs the sibling factory-floor-agent; agentcore-port
serves it). `fleet/` is where `setup.sh` puts them so those paths
resolve exactly as they do in CI.
