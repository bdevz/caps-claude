# caps-claude

**Claude Experts for Consultadd Public Services.** A repository of Claude Code skill packs that codify how Consultadd's Public Services team does its highest-leverage work — starting with RFP/proposal authoring.

> **Are you an analyst getting started?** Jump to [`consultadd-rfp/ONBOARDING.md`](consultadd-rfp/ONBOARDING.md) for a step-by-step setup written for non-technical users.

## What's Here

| Pack | Status | Purpose |
|---|---|---|
| [`consultadd-rfp/`](consultadd-rfp/) | scaffold complete; knowledge content + dashboards pending | 12-skill Claude Code pack for the multi-expert RFP workflow with a `/rfp` orchestrator |

More packs will land here as we standardize other Consultadd workflows.

## The Approach

Modeled on [garrytan/gstack](https://github.com/garrytan/gstack): per-skill folders, slash-command invocation, autoplan-style orchestrators that read downstream skills at runtime, and persistent telemetry/learnings. Each pack hard-gates the high-stakes hallucination zones (in RFPs: eligibility, pricing, capability claims, attestations) to humans, so Claude operates as a coworker — not an autonomous replacement.

## Goal

Take Consultadd's 30+ analyst proposal team from a manual ChatGPT-then-Claude workflow to a consistent, gated, audited pipeline that scales toward **1,000 RFPs/month** without sacrificing quality. Every skill pack here is built against that thesis.

## Repository Layout

```
caps-claude/
├── README.md                  # this file
└── consultadd-rfp/            # first pack — RFP authoring
    ├── README.md              # pack-level technical reference
    ├── ONBOARDING.md          # analyst-facing setup + first-RFP walkthrough
    ├── ARCHITECTURE.md
    ├── CLAUDE.md
    ├── setup                  # symlink installer for ~/.claude/skills/
    ├── lib/telemetry.sh
    ├── knowledge/             # institutional knowledge (skeletons; DRI populates)
    └── <skill>/SKILL.md       # 12 skills
```

## Contributing

Adding a new pack: create a sibling folder to `consultadd-rfp/`, follow the same structure (per-skill folders + `setup` script + `knowledge/` for institutional content + `ONBOARDING.md` for the human users). Existing analysts shouldn't need to re-onboard each time a pack lands.
