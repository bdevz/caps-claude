# Consultadd RFP Skills Pack

> **Are you an analyst getting started?** Read [ONBOARDING.md](ONBOARDING.md) — it's a step-by-step setup + first-RFP walkthrough written for non-technical users. The README below is the technical reference.

Claude Code skills pack that codifies Consultadd's multi-expert RFP workflow. Models gstack's per-skill folder + slash-command pattern, with a `/rfp` autoplan-style orchestrator that runs the pipeline end-to-end and hard-gates the high-stakes hallucination zones (eligibility, pricing, capability claims, attestations) to humans.

## Install

```bash
git clone <this-repo> ~/code/consultadd-rfp
cd ~/code/consultadd-rfp
./setup
```

This symlinks every skill folder into `~/.claude/skills/` so edits in this repo are immediately live in Claude Code.

## Skills

| Skill | Purpose |
|---|---|
| `/parse-rfp` | Reducto PDF → clean markdown |
| `/firm-background` | Inject Consultadd boilerplate from `knowledge/` |
| `/eligibility-check` | Qualification + partnership/license/sub-vendor/teaming flags (CHALLENGE GATE) |
| `/tech-expert` | Technical section drafter |
| `/legal-expert` | Legal section drafter |
| `/ops-expert` | Operations section drafter |
| `/sales-mktg-expert` | Sales & marketing section drafter |
| `/public-policy-expert` | Public policy section drafter |
| `/writer` | Narrative polish across sections |
| `/reviewer` | Internal first-pass quality check |
| `/cross-verify` | Independent dual-voice second opinion |
| `/rfp` | End-to-end orchestrator (autoplan analog) |

## Workflow Anchor

```
parse-rfp → firm-background → eligibility-check (CHALLENGE)
  → section-split → parallel(tech, legal, ops, sales-mktg, public-policy)
  → writer → reviewer → cross-verify
  → TASTE GATE (pricing, claims, attestations)
  → stitch → submission-ready
```

## Knowledge Base

Institutional knowledge lives as static markdown in `knowledge/`. Updated via PR by the knowledge DRI. **Skills read; they never invent and never modify.**

- `consultadd-background.md` — company overview, history, scale
- `capabilities.md` — service lines and offering descriptions
- `certifications.md` — NAICS codes, set-asides, GSA, certs
- `key-personnel/` — bios per role
- `past-wins/` — case studies (1 file per win)
- `compliance/` — standard MSA terms, attestations

## Telemetry

Every skill emits a structured event via `lib/telemetry.sh` to a Supabase ingest endpoint. Two dashboards consume the same data: manager (aggregate + per-analyst rollup) and analyst self-view (own usage + coaching suggestions). Configure with environment variables — see `setup` output.
