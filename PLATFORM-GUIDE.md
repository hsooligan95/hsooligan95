# How this platform works — the full picture

**The one-sentence model:** one agent does real work; everything else exists to
decide what it's allowed to do, remember what happened, measure what it cost,
and prove it later. Nothing acts without passing a checkpoint, and every
checkpoint writes to one shared record.

## The cast, by job

### The worker

- **[factory-floor-agent](https://github.com/hsooligan95/factory-floor-agent)** —
  the only agent that does a "job": it answers questions about a factory from
  its documents. Everything else in the platform exists because this one can't
  be trusted unsupervised.

### The checkpoints it must pass

- **[agent-canary](https://github.com/hsooligan95/agent-canary)** — before a new
  version of an agent is promoted, it runs against a golden test suite. If
  quality collapses, promotion is BLOCKED. (In the drill: a bad config drops
  success 100% → 36% with 10 forbidden outputs, and never ships.)
- **[cred-broker](https://github.com/hsooligan95/cred-broker)** — issues
  credentials that are narrow and short-lived: not "access to the database,"
  but "read-only on this one table, for 300 seconds." It *narrows* what agents
  ask for.
- **[agent-gate](https://github.com/hsooligan95/agent-gate)** — sits on every
  tool call. Verifies the broker's credential actually covers this call,
  screens inputs and results for injections and leaked secrets, and records
  allow / flag / block. The broker decides what an agent *may* do; the gate
  enforces it *per call*.
- **[blast-radius](https://github.com/hsooligan95/blast-radius)** — for changes
  to infrastructure: executes step-by-step with snapshots before each step, so
  any change can be rolled back to identical state — even if the process is
  killed mid-run with `kill -9`.

### Memory and judgment

- **[context-vault](https://github.com/hsooligan95/context-vault)** — the shared
  memory agents read and write: versioned, every entry stamped with who wrote
  it and why. Factory Floor uses it as its memory across runs.
- **[mission-control](https://github.com/hsooligan95/mission-control)** — when
  agents disagree, it doesn't vote. It gathers evidence from the record and
  rules — in the drill story it overrules a more confident agent and orders a
  rollback, 0.6 confidence beating 0.8 because the evidence said so.

### The measurers

- **[agent-ledger](https://github.com/hsooligan95/agent-ledger)** — meters every
  step's cost and attributes it to the agent that spent it. It can halt a
  runaway agent mid-loop when a budget cap trips.
- **[agent-chaos](https://github.com/hsooligan95/agent-chaos)** — deliberately
  breaks things (kills processes, corrupts inputs) to see whether the platform
  notices.
- **[agent-flightsim](https://github.com/hsooligan95/agent-flightsim)** —
  rehearses agents against simulated worlds before they run for real. This is
  the one that caught the platform's most embarrassing failure: an agent
  confidently reporting a pump that had been removed for repair as "running
  normally."
- **[rag-evaluation-harness](https://github.com/hsooligan95/rag-evaluation-harness)** —
  the question set and scoring the quality claims rest on. The canary's BLOCK
  is only meaningful because this suite exists.

### The record

- **[agent-trace](https://github.com/hsooligan95/agent-trace)** — the spine.
  Every checkpoint above writes its decisions and actions here as a
  hash-chained, append-only record. The dashboard reads only this. If it isn't
  in the trace, it didn't happen.

### The translators

- **[ato-in-a-box](https://github.com/hsooligan95/ato-in-a-box)** — reads the
  trace and turns it into compliance evidence packs (mapped to NIST 800-53 and
  the NIST AI RMF): "here's the proof this system enforces access control,"
  with the gaps declared just as plainly.
- **[agentcore-port](https://github.com/hsooligan95/agentcore-port)** — the
  factory-floor agent, unmodified, running on AWS's Bedrock AgentCore runtime
  contract — proof the design isn't welded to one vendor.
- **[mcp-cloud-explorer](https://github.com/hsooligan95/mcp-cloud-explorer)** —
  the tool surface: how agents query cloud resources across AWS, Azure, Google
  Cloud, and OCI in one shape, over mock data. In the architecture it sits
  *behind* the gate.

## How one run flows

The drill the dashboard replays, step by step:

1. **agent-canary** evaluates a candidate config against the golden suite —
   success collapses, promotion BLOCKED.
2. **cred-broker** issues a credential, narrowed to a fraction of what was
   requested.
3. **agent-gate** verifies that credential and screens the agent's tool calls
   as they happen.
4. **factory-floor-agent** answers questions, reading its memory from
   **context-vault**.
5. **agent-chaos** kills **blast-radius** mid-change (`kill -9`).
6. **blast-radius** resumes from its checkpoint; verification fails; every step
   rolls back to identical snapshots.
7. **agent-ledger** totals the cost of the whole run: $0.57313.
8. Every step above lands in **agent-trace**, on one verified timeline.
9. Nightly CI re-runs the whole story from fresh checkouts, to prove it still
   holds together.

## What you can do with it

- **Interrogate it** — in the AgentTrace dashboard: the overview for system
  health, incidents for "why did that happen," replay to walk any run step by
  step, per-agent pages for everything one agent type has ever done, and a
  config view where changes are proposed as patches — never applied from the
  dashboard.
- **Run any piece alone** — each repo is self-contained with its own tests and
  demo. The gate screening text, the canary blocking a config, the flightsim
  grid reproducing the pump failure — all runnable in isolation. The scripts
  in [`platform/`](platform/) run all fifteen suites (`test-all.sh`).
- **Show it** — the [interactive site](https://hsooligan95.github.io/) and this
  hub tell the story publicly; the ATO evidence pack is the artifact you'd hand
  a compliance-minded reader.
- **Extend it** — the pieces compose because they only talk through the trace
  and the checkpoints. LoopClosure — findings automatically becoming canary
  test cases — is the queued next piece.

## The honest limit

The *plumbing* is real — governance, memory, cost, audit, and rollback all
genuinely work. The *intelligence* is stand-ins: stub models and mock cloud
data. And the enforcement has known soft spots — a Red Team audit of this
platform exists, and its findings drive the fix queue. This is a working model
of how you'd run agents you don't trust — which is the actual point of it.
