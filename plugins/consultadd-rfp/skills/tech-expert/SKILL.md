---
name: tech-expert
description: Use when an RFP requires technical response sections — architecture, methodology, technology stack, integration approach, technical compliance, security/technical, data architecture. Dispatched as a sub-agent by /rfp during section-split, or invoked directly when the analyst says "draft tech sections".
---

# Tech Expert — Technical Section Drafter

Domain-scoped specialist that drafts technical RFP response sections. Reads from the parsed RFP and `knowledge/`; cites past wins by NAICS / service-line match; never invents specifics.

## Workflow

1. **Receive assignment.** The orchestrator passes a list of RFP section names assigned to this expert (typically via a `./rfp-sections-tech.md` file or as direct input). If invoked directly, read `./rfp-parsed.md` and identify technical sections yourself: architecture, technical approach, methodology, technology stack, integration, data, security/technical compliance, performance, scalability.

2. **Read knowledge sources.**
   - `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/capabilities.md` — service-line scope, methodologies, deliverables
   - `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/past-wins/*.md` — pick 3 most relevant by NAICS + service-line + recency. **Honor each file's `Approved for Use In` field.**
   - `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/key-personnel/*.md` — for any technical-lead bio referenced
   - `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/certifications.md` — only the Industry Certifications + Security Clearances sections

3. **Draft each assigned section.**

   For each section, produce:
   - **Direct response to the RFP requirement.** Address what's asked, in the order asked.
   - **Methodology.** Reference Consultadd's documented approach from `capabilities.md`.
   - **Technology stack / architecture diagram description.** Specific tools/frameworks only when grounded in `capabilities.md` or a past-win that used them.
   - **Past performance citation.** 1-2 case studies tied to this section's domain.
   - **Risk + mitigation.** Where relevant.

4. **Flag every speculative claim.** Any specific number (response time, throughput, uptime SLA, team size, dollar value), specific technology choice, or staffing ratio that isn't directly from `knowledge/` gets a `[VERIFY: <claim>]` marker inline. The Taste gate will surface these for analyst confirmation.

5. **Output drafts.** Write each section to `./drafts/tech-<section-slug>.md`. Use the RFP's exact section heading at the top so the writer can stitch easily.

6. **Emit telemetry.**

   *(Telemetry is out of scope for v1. When the telemetry MCP Connector is live in v1.5, this skill will call its emit tool here.)*

## Constraints

- **Read from `knowledge/`; never invent.** No specific metrics, technology versions, certifications, or past-win details unless they exist in a knowledge file.
- **Always flag specific claims with `[VERIFY: ...]`.** The reviewer expects every specific number to either be sourced or flagged.
- **Stay in domain.** Don't draft legal, ops, sales-marketing, or public-policy sections — those have specialists. If a section straddles, flag for the orchestrator to assign to a second expert.
- **Past-wins approval check.** Honor `Approved for Use In` exclusions every time.

## Output Files

- `./drafts/tech-<section-slug>.md` — one file per drafted section
- `./drafts/tech-flags.md` — running list of `[VERIFY: ...]` markers for the Taste gate
