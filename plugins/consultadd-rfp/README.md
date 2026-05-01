# Consultadd RFP Plugin

> **Are you an analyst getting started?** Read [`ONBOARDING.md`](ONBOARDING.md) — it's a step-by-step setup + first-RFP walkthrough written for non-technical claude.ai users. The README below is the technical reference.

A 12-skill plugin for Consultadd's analyst proposal team. Codifies the multi-expert RFP authoring workflow: parse → firm-background → eligibility check (gate) → expert drafting → writer/reviewer/cross-verify → final gate → submission-ready output. Hard-gates the high-stakes hallucination zones (eligibility, pricing, capability claims, attestations) to humans.

Distributed via the [`caps-claude`](../../) plugin marketplace.

## Skills

| Skill | What it does | Phase |
|---|---|---|
| `/parse-rfp` | Read uploaded RFP PDF → clean structured markdown | 1 |
| `/firm-background` | Inject Consultadd boilerplate from `_shared/knowledge/` | 2 |
| `/eligibility-check` | Compare RFP requirements vs. our certifications/capabilities; flag gaps; recommend QUALIFIED / MITIGATABLE / NO-BID. **CHALLENGE GATE.** | 3 |
| `/tech-expert` | Draft technical RFP sections (architecture, methodology, security, etc.) | 5 |
| `/legal-expert` | Draft legal sections + flag MSA deltas vs. Consultadd standard terms | 5 |
| `/ops-expert` | Draft project management, transition, staffing, schedule, QA sections | 5 |
| `/sales-mktg-expert` | Draft cover letter, executive summary, win themes, value prop | 5 |
| `/public-policy-expert` | Draft regulatory alignment + equity/access/sustainability sections (gov RFPs only) | 5 |
| `/writer` | Polish all specialist drafts into one cohesive document | 6 |
| `/reviewer` | Internal QA: coverage, consistency, citations, spelling, format | 7 |
| `/cross-verify` | Independent second-opinion review on artifacts only (no drafting context) | 8 |
| `/rfp` | End-to-end orchestrator that walks the analyst through Phases 1–10 | all |

## Workflow

```
parse-rfp → firm-background → eligibility-check (CHALLENGE)
  → section-split → tech-expert → legal-expert → ops-expert → sales-mktg-expert → public-policy-expert
  → writer → reviewer → cross-verify
  → TASTE/CHALLENGE GATE (pricing, claims, attestations, key personnel)
  → stitch → submission-ready
```

In Claude.ai's runtime, specialist drafting is **sequential** (no parallel sub-agent dispatch). The analyst either invokes `/rfp` for single-prompt mode, or runs each skill manually for step-by-step control.

## Knowledge Base

Institutional knowledge lives in `skills/_shared/knowledge/` — **co-located inside the plugin tree** because the plugin install copies the plugin directory to a cache, and external paths don't resolve.

| File / Folder | Owner | Purpose |
|---|---|---|
| `consultadd-background.md` | Knowledge DRI | Company overview, mission, differentiators |
| `capabilities.md` | Knowledge DRI | Service lines, methodologies, deliverables |
| `certifications.md` | Knowledge DRI | NAICS, set-asides, GSA, certs, insurance |
| `key-personnel/` | HR + Knowledge DRI | One file per role/person; bios for personnel sections |
| `past-wins/` | Sales + Knowledge DRI | One file per won engagement; case studies for past-performance citations |
| `compliance/` | Legal + Knowledge DRI | Approved MSA terms, attestations, data-handling language |

**Skills read; they never invent and never modify these files.** Updates go through PR review.

## Decision Classification

Throughout the pipeline, every judgment call is classified:

- **Mechanical** — silent auto. Formatting, well-defined facts pulled from `_shared/knowledge/`.
- **Taste** — auto-decide and surface at the final pre-submission gate. Tone, narrative emphasis, optional sections.
- **Challenge** — never auto. Block on human sign-off. Eligibility, pricing, capability claims, attestations, key-personnel commitments.

**Never escape a Challenge gate without explicit human approval.**

## v1.5 / v2 Roadmap

| Capability | Version | Notes |
|---|---|---|
| Reducto MCP Connector for higher-fidelity PDF parsing | v1.5 | Org admin connects Reducto MCP server; `parse-rfp` updated to call `Reducto:parse_pdf` instead of native PDF read |
| Telemetry pipeline + dashboards | v2 | MCP Connector exposes `tel_emit`-equivalent tool; dashboards (Next.js + Supabase) consume |
| HubSpot / Slack / Coda MCP integrations | v2 | Currently `_shared/knowledge/` is static markdown; v2 lets skills query CRM directly |
| Splitting `consultadd-rfp` into multiple plugins (per-discipline) | v2+ | Reassess at Week 4 when we see how the single-plugin UX feels |

## Maintainer

Owned by Jason and the Consultadd RFP team. Issues / suggestions: open a PR or ping in `#rfp-tools` Slack.
