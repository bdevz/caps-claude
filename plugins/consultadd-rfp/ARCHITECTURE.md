# Architecture

## Design Principles (adapted for Claude.ai runtime)

Inspired by gstack but modified to fit Claude.ai's plugin runtime:

1. **Per-skill folder** under `skills/` — each skill is `<name>/SKILL.md` with optional companion files. Slash-command invocation; auto-invocation by description match.
2. **Linear orchestration** — `/rfp` walks phases sequentially. The analyst is the loop. No parallel sub-agent dispatch (Claude.ai's runtime doesn't expose the Agent / Task tool the way Claude Code does).
3. **Decision classification rubric** — Mechanical / Taste / Challenge. Mechanical auto-applies, Taste surfaces at the final gate, Challenge hard-blocks on human sign-off.
4. **Independent cross-verification** — `cross-verify` reads only the produced artifact (`./rfp-draft.md` + `./rfp-parsed.md`), not drafting context, so it has fresh eyes. Adversarial framing.
5. **Knowledge-first discipline** — `_shared/knowledge/` is the source of truth for Consultadd-specific content. Skills read; they never invent and never modify.
6. **Telemetry deferred to v1.5** — no bash hooks in Claude.ai skills. When the telemetry MCP Connector lands, every skill emits via the connector tool.

## Plugin Layout

```
plugins/consultadd-rfp/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (only `name` is required; we also set description, author, etc.)
├── README.md                    # Plugin reference for admins / devs
├── ARCHITECTURE.md              # this file
├── ONBOARDING.md                # Analyst-facing guide for claude.ai users
└── skills/
    ├── _shared/                 # Plugin-internal shared content
    │   └── knowledge/           # Institutional knowledge (read by skills, never written)
    │       ├── consultadd-background.md
    │       ├── capabilities.md
    │       ├── certifications.md
    │       ├── key-personnel/
    │       ├── past-wins/
    │       └── compliance/
    ├── parse-rfp/SKILL.md
    ├── firm-background/SKILL.md
    ├── eligibility-check/SKILL.md
    ├── tech-expert/SKILL.md
    ├── legal-expert/SKILL.md
    ├── ops-expert/SKILL.md
    ├── sales-mktg-expert/SKILL.md
    ├── public-policy-expert/SKILL.md
    ├── writer/SKILL.md
    ├── reviewer/SKILL.md
    ├── cross-verify/SKILL.md
    └── rfp/SKILL.md             # End-to-end orchestrator (linear, analyst-driven)
```

## Skill Anatomy

Every skill folder contains a `SKILL.md` with this structure:

```markdown
---
name: <kebab-case>
description: <When to invoke this skill — Claude reads this for auto-invocation match>
---

# <Title>

## Workflow
1. <step>
2. <step>
...

## Constraints
- <hard rule>
- <hard rule>

## Output Files
- `./<file>` — <purpose>
```

Frontmatter is intentionally minimal. Claude Team honors only `name` (required), `description`, and `disable-model-invocation`. Fields like `triggers`, `allowed-tools`, and `version` from Claude Code skill format are ignored — voice triggers are gone, tool gating happens at the org level via Connectors.

References to plugin-internal files use `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/...` — the variable resolves to the plugin's installed cache directory at runtime. **Paths outside the plugin tree (using `../`) won't resolve** because plugin install copies the directory to a cache.

## /rfp Orchestrator (linear, not autoplan)

The Claude Code-shaped autoplan analog (parallel sub-agents, gate logic in the runner) doesn't fit Claude.ai. The replacement is a linear recipe:

```
1. /parse-rfp                                    [Mechanical]
2. /firm-background                              [Mechanical]
3. /eligibility-check                            [CHALLENGE GATE — hard block]
4. (section-split, embedded in /rfp)             [Mechanical]
5. /tech-expert                                  [Mechanical]
6. /legal-expert                                 [Mechanical]
7. /ops-expert                                   [Mechanical]
8. /sales-mktg-expert                            [Mechanical]
9. /public-policy-expert (gov RFPs only)         [Mechanical]
10. /writer                                      [Taste — surface at final]
11. /reviewer                                    [Mechanical, may re-dispatch]
12. /cross-verify                                [Mechanical, severity routes]
13. TASTE / CHALLENGE GATE                       [block on human]
14. stitch + audit-trail                         [Mechanical]
```

The orchestrator reads downstream `SKILL.md` content (or just references it by behavior) so changes to specialist prompts propagate without changes to `/rfp`.

## Knowledge Base Discipline

`_shared/knowledge/*.md` is canonical. Skills read; they never write. Updates go through PR review by the knowledge DRI. Rationale: a single misedit to `capabilities.md` propagates to every proposal — the bottleneck on quality is consistency, and PR review is the cheapest enforcement.

Refresh cadence: monthly minimum, plus event-triggered (new certification, new past win, leadership-approved language change).

## Roadmap (v1.5 / v2)

| Capability | Version | How it lands |
|---|---|---|
| Reducto MCP Connector for higher-fidelity PDF parsing | v1.5 | Org admin connects Reducto MCP server; `parse-rfp` calls `Reducto:parse_pdf` |
| Telemetry pipeline | v2 | Telemetry MCP Connector + Next.js dashboards (manager + analyst self-view) |
| HubSpot CRM / Slack / Coda integration | v2 | MCP Connectors at org level; specific skills query CRM/comms when relevant |
| Per-discipline plugin split | v2+ | If `consultadd-rfp` outgrows a single plugin, split into `consultadd-rfp-core`, `consultadd-rfp-specialists`, etc. |
