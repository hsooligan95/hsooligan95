---
mode: agent
description: Review the current diff against hsooligan95's invariants
---

Review my current diff against this repo's invariants:

- Every claim in the README must be true of the linked repo TODAY — verify against that repo before editing a claim; never round up.
- The portfolio is one platform story (govern -> gate -> execute -> record -> meter -> stress -> run), not a list; slot new projects into that arc.
- Honest limitations stay visible rather than being smoothed over.
- No title-forward copy: no seniority claims or years-of-experience boasts; the projects speak for themselves.

Flag every violation with file and line. Also flag any change that
alters a documented behavior contract (output shapes, exit codes,
event schemas, recorded artifacts) without updating the docs and
tests that describe it. No style nitpicks — correctness and contract
violations only.
