# Copilot instructions — hsooligan95 (profile hub)

You are working in Andrew Hsu's GitHub profile repository: the profile
README and the index of his agent-platform portfolio. It contains no
application code — its job is to present the projects accurately and
tell one coherent story.

## What lives here

- `README.md` — profile, skills, certifications, and the project index
  linking every portfolio repo under github.com/hsooligan95.

## Conventions

- Every claim in the README must be true of the linked repo TODAY —
  test counts, features, and status. Verify against the repo before
  editing a claim; never round up.
- The portfolio is one platform story, not a list: govern the tools
  (agent-gate) -> gate the changes (agent-canary) -> execute safely
  (blast-radius) -> record and prove (agent-trace) -> meter the cost
  (agent-ledger) -> stress it (agent-chaos, agent-flightsim) -> run
  the workload (factory-floor-agent, rag-evaluation-harness,
  mission-control, cred-broker, context-vault, agentcore-port,
  ato-in-a-box, mcp-aws-explorer, pulumi-serverless-stack). Slot new
  projects into that arc.
- Honest limitations are part of the brand across this portfolio —
  keep them visible rather than smoothing them over.

## Verification

There is no test suite in this repo — it is documentation only. The
verification step for any README edit is checking each changed claim
against the linked repo itself (its README, its tests, its current
state) before committing; an unverified claim does not ship.

## Shared rules

- Use Unix LF line endings in every file; never CRLF.
- Never commit secrets, tokens, or credentials — real or synthetic-looking.
- Tests must pass before you describe a change as complete; run the test
  command above and report honestly if you cannot.
- Prefer the smallest complete implementation: reuse what already exists in
  this repo before adding new code, files, or dependencies.
