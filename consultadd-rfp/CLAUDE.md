# Consultadd RFP Workflow — Session Context

You are assisting a Consultadd analyst on an RFP. This file is loaded into every Claude Code session in this repo.

## Source of Truth

Consultadd's institutional knowledge lives in `~/.claude/skills/consultadd-rfp/knowledge/`. **Read those files when you need firm context — never invent capabilities, certifications, key personnel, or past wins.** If a knowledge file is empty or missing, log the gap to a `firm-background-gaps.md` in the RFP working dir and continue; do not fabricate to fill the hole.

## Workflow Anchor

1. `/parse-rfp` — Reducto PDF → markdown
2. `/firm-background` — inject boilerplate from `knowledge/`
3. **CHALLENGE GATE — `/eligibility-check`** — partnerships, licenses, sub-vendors, teaming agreements. Hard-blocks on human approval before proceeding.
4. Section-split → expert dispatch (`/tech-expert`, `/legal-expert`, `/ops-expert`, `/sales-mktg-expert`, `/public-policy-expert`) in parallel sub-agents
5. `/writer` (narrative polish) → `/reviewer` (internal QA) → `/cross-verify` (independent second opinion)
6. **TASTE GATE** — pre-submission human review: pricing, capability claims, attestations, key-personnel commitments, low-confidence language flagged by experts
7. Stitch → submission-ready RFP + audit trail file

## Decision Classification

When the orchestrator (or any specialist) makes a judgment call, classify it:

- **Mechanical** — silent auto. Formatting, well-defined facts pulled from `knowledge/`, section ordering matching RFP TOC. No human attention needed.
- **Taste** — auto-decide but surface at the final pre-submission gate. Tone, narrative emphasis, optional sections, language style.
- **Challenge** — never auto. Block on human sign-off. Eligibility judgment, pricing, capability claims, attestations, key-personnel commitments. **Never escape a Challenge gate without explicit human approval.**

## Audit Trail

Every `/rfp` run writes an audit trail to `./rfp-audit-<timestamp>.md` capturing: which skills ran, what gates fired, every Taste/Challenge decision and who approved, every knowledge file read. This is the artifact reviewed when something goes wrong post-submission.

## Telemetry

Each skill sources `lib/telemetry.sh` and emits an event on entry and on exit. Required env vars: `CONSULTADD_TEL_ENDPOINT`, `CONSULTADD_TEL_KEY`, `CONSULTADD_ANALYST_ID`. If unset, telemetry silently no-ops — never block skill execution on telemetry failures.

## Hard Rules

- Never fabricate Consultadd content. Read from `knowledge/` or flag a gap.
- Never bypass a Challenge gate.
- Never modify `knowledge/*.md` from a skill — those files are PR-only.
- Never commit secrets (API keys, customer data, RFP drafts) to git.
- Never auto-submit an RFP. Submission is always human-initiated.
