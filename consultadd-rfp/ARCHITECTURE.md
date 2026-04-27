# Architecture

## Design Principles

Borrowed from gstack:

1. **Per-skill folder, slash-command invocation** — `/rfp`, `/eligibility-check`, etc. Each skill is a self-contained folder with a `SKILL.md`. Voice-trigger aliases in frontmatter.
2. **Orchestrator reads downstream `SKILL.md` at runtime** — `/rfp` doesn't hardcode specialist behavior; it loads each specialist's `SKILL.md` so the orchestrator stays in sync as specialist prompts evolve.
3. **Decision classification rubric** — Mechanical / Taste / Challenge (see `CLAUDE.md`). Mechanical auto, Taste surface at final gate, Challenge block on human.
4. **Dual-voice cross-verification** — `cross-verify` reads the produced artifact only (not the session that produced it) so it has independent perspective. Codex CLI used as a second voice when available.
5. **Telemetry-first** — every skill emits events. Treat the dashboard as a feature, not an afterthought.

## Repo Layout

```
consultadd-rfp/
├── README.md                 # install + skill index
├── setup                     # symlink installer
├── CLAUDE.md                 # session context (loaded by Claude Code)
├── ARCHITECTURE.md           # this file
├── lib/
│   └── telemetry.sh          # shared event-emit helper
├── knowledge/                # institutional knowledge — PR-only
│   ├── consultadd-background.md
│   ├── capabilities.md
│   ├── certifications.md
│   ├── key-personnel/
│   ├── past-wins/
│   └── compliance/
└── <skill>/                  # one folder per skill
    └── SKILL.md
```

## Skill Anatomy

Every skill folder contains a `SKILL.md` with this structure:

```markdown
---
name: <kebab-case>
description: <trigger-only — when to invoke, NOT what it does>
triggers: ["voice trigger 1", "voice trigger 2"]
---

# <Title>

## Workflow
1. <step>
2. <step>
...

## Constraints
- <hard rule>
- <hard rule>

## Telemetry
source ~/.claude/skills/consultadd-rfp/lib/telemetry.sh
tel_emit <skill-name> <event> <extra-json>
```

The description is **trigger-only**. Workflow lives in the body. (See user's CLAUDE.md "Description Trap" section.)

## Orchestrator Pattern (`/rfp`)

`/rfp` is an autoplan analog. Pseudo:

```
1. parse-rfp                                    [Mechanical]
2. firm-background                              [Mechanical]
3. eligibility-check                            [CHALLENGE GATE — block]
4. section-split                                [Mechanical]
5. dispatch parallel sub-agents:
     - tech-expert
     - legal-expert
     - ops-expert
     - sales-mktg-expert
     - public-policy-expert
6. writer                                       [Taste — surface at final]
7. reviewer                                     [Mechanical]
8. cross-verify                                 [Mechanical, but if it disagrees → Taste]
9. assemble taste-decision summary              [TASTE GATE — surface for human]
10. stitch + write submission file + audit trail
```

Each phase emits telemetry on entry, exit, and gate fire. Sub-agents in step 5 run via the `Agent` tool with isolated context so they don't pollute orchestrator state.

## Telemetry Pipeline

Event format (POSTed to Supabase as JSON):

```json
{
  "skill": "firm-background",
  "event": "complete",
  "analyst": "<analyst id>",
  "rfp_id": "<rfp id, optional>",
  "ts": "<ISO 8601>",
  "duration_ms": 1234,
  "tokens_in": 5678,
  "tokens_out": 910,
  "extra": { "gaps": 2, "sections_filled": 7 }
}
```

Two consumer dashboards (separate Next.js project, out of scope for this repo):
- **Manager view** — weekly aggregates, per-analyst rollup, skill heatmap, cost-per-RFP
- **Analyst self-view** — own timeline, time-per-RFP trend, "skills you haven't used in 14 days" suggestions

## Knowledge Base Discipline

`knowledge/*.md` is canonical. Skills read; they never write. Updates go through PR review by the knowledge DRI. Rationale: a single misedit to `capabilities.md` propagates to hundreds of proposals — the bottleneck on quality is consistency, and PR review is the cheapest enforcement.

Refresh cadence: monthly minimum, plus event-triggered (new certification, new past win, leadership-approved language change).
