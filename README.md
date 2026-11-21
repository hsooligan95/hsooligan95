# Andrew Hsu — Senior Software Engineer

Senior Software Engineer with 8 years of experience building cloud infrastructure and
developer platforms on AWS and Azure. Infrastructure as code practitioner in
general-purpose languages (AWS CDK and CloudFormation in TypeScript, Python, and Go),
with deep experience in serverless systems, deployment orchestration, and multi-cloud
environments — including AWS GovCloud region deployments.

Currently at **GDH Consulting** as an AWS Software Engineer. Previously at
**Amazon Web Services** (System Development Engineer, GovCloud deployments) and
**Athena Sciences** (Software Engineer / Solutions Architect on mission-planning and
simulation systems).

## Skills

| Area | Technologies |
| --- | --- |
| Languages | Go, TypeScript, Python, Java, Ruby |
| Cloud | AWS (Lambda, S3, Athena, QuickSight, EventBridge, IAM, VPC), Microsoft Azure |
| Infrastructure as Code | AWS CDK, CloudFormation |
| Platforms & DevOps | OpenShift (Kubernetes-based), Docker, CI/CD (Jenkins, GitLab), Ansible |
| Practices | Microservices, APIs, deployment orchestration, automated regression testing (Cucumber), developer tooling |
| AI / Agents (project work) | LLM APIs, LangGraph, tool calling, multi-step agent orchestration, RAG, evaluation frameworks |

## Certifications

- AWS Certified Solutions Architect – Associate
- AWS Certified Developer – Associate
- AWS Certified Cloud Practitioner

## Education

- B.S. Computer Science, Virginia Tech

## Projects

My recent project work forms one arc: building AI agents, then building the platform
layer that makes them safe to run in production — govern the tools, gate the changes,
execute safely, meter the cost.

**The agent platform layer**

| Project | What it is |
| --- | --- |
| [agent-gate](https://github.com/hsooligan95/agent-gate) | An MCP security gateway in TypeScript: per-agent identity and tool allowlists, policy decisions (allow / deny / human approval), prompt-injection and PII screening of tool results, and a tamper-evident, hash-chained audit log with per-run evidence-pack export. |
| [agent-canary](https://github.com/hsooligan95/agent-canary) | CI for agent behavior: shadow-runs a candidate agent version against the current one over a golden task suite with programmatic checks, diffs success / accuracy / cost / latency, and blocks promotion on regression. |
| [blast-radius](https://github.com/hsooligan95/blast-radius) | An infrastructure remediation agent (LangGraph + mock AWS) whose engineering is the execution shell: reviewable plan → human approval → durable checkpointed execution that survives `kill -9` mid-task → verification → automatic rollback, under least-privilege policies with a compliance-style audit log. |
| [agent-chaos](https://github.com/hsooligan95/agent-chaos) | Chaos engineering for agents: injects tool timeouts, hallucinating tools, prompt injection, poisoned results, and context corruption, and measures detected / recovered / failed-loudly / failed-silently — with and without defenses. |
| [agent-ledger](https://github.com/hsooligan95/agent-ledger) | FinOps for agents: OpenTelemetry (GenAI conventions) cost attribution per agent / run / task / step, runtime budgets that halt a runaway agent mid-run, and model routing with measured savings. |

**Agents and evaluation**

| Project | What it is |
| --- | --- |
| [factory-floor-agent](https://github.com/hsooligan95/factory-floor-agent) | A LangGraph agent (plan → retrieve → answer → groundedness check, with retry-then-abstain) over hybrid BM25/TF-IDF retrieval. Answers only from retrieved passages with cited sources; abstains when the evidence isn't there. Runs fully offline in demo mode. |
| [rag-evaluation-harness](https://github.com/hsooligan95/rag-evaluation-harness) | The evaluation framework for that retrieval pipeline: a labeled eval set (answerable + must-abstain cases), per-case diagnosis naming the failing stage, and a grounding-threshold sweep. |

**Infrastructure as code and MCP**

| Project | What it is |
| --- | --- |
| [mcp-aws-explorer](https://github.com/hsooligan95/mcp-aws-explorer) | A Model Context Protocol (MCP) server in TypeScript that exposes read-only AWS inventory and cost tools over a local mock dataset — list resources, summarize costs, find idle resources. Also serves as the demo upstream behind AgentGate. |
| [pulumi-serverless-stack](https://github.com/hsooligan95/pulumi-serverless-stack) | A Pulumi program in TypeScript defining a serverless API (API Gateway + Lambda + DynamoDB) as real code — no YAML templates. |

## What I'm focused on

- Infrastructure as code in general-purpose languages (Pulumi, CDK)
- AI agent systems with tool calling, orchestration, and evaluation
- Serverless architecture on AWS, including cost and usage visibility

## Contact

- LinkedIn: [linkedin.com/in/andrew-hsu-715927241](https://www.linkedin.com/in/andrew-hsu-715927241)
- Email: andrew.hsu95@yahoo.com
