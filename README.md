# caps-claude

**Claude Skills Marketplace for Consultadd Public Services.** This repository is a Claude Team plugin marketplace that auto-distributes Consultadd's institutional skills to every analyst on the team via Claude.ai's GitHub sync.

When the Consultadd Claude Team admin connects this repo via the Claude GitHub App and tracks the `main` branch, every plugin listed in `.claude-plugin/marketplace.json` becomes available to all 12+ team members in claude.ai web/desktop. Updates land via `main` and propagate automatically.

## Plugins in this marketplace

| Plugin | Status | What it does |
|---|---|---|
| [`consultadd-rfp`](plugins/consultadd-rfp/) | v1 in pilot (April 2026) | 12-skill RFP authoring pipeline — parse, eligibility check, multi-expert drafting, cross-verify, with human gates at the high-stakes decisions |

More plugins will land here as we standardize other Consultadd workflows (sales discovery, client research, account-planning, etc.).

## For analysts: getting started

If you're an analyst on the Consultadd Claude Team and the admin has already connected this marketplace: open claude.ai → Customize → Skills, look for the `consultadd-rfp` plugin, then read [`plugins/consultadd-rfp/ONBOARDING.md`](plugins/consultadd-rfp/ONBOARDING.md) for your first-RFP walkthrough.

## For admins: connecting the marketplace

In Claude Desktop:

1. Organization settings → Plugins → "Add plugins" → "GitHub"
2. Enter the repo: `bdevz/caps-claude`
3. Pick branch `main`, set `consultadd-rfp` to "Installed by default"
4. Verify plugins appear under Customize → Skills for a test user

The Claude GitHub App must be installed on the repo before the marketplace can sync. Sync triggers on PR merge to `main`.

## Repository layout

```
caps-claude/
├── .claude-plugin/
│   └── marketplace.json              # Catalog Claude Team reads to discover plugins
├── plugins/
│   └── consultadd-rfp/
│       ├── .claude-plugin/plugin.json
│       ├── README.md                 # Plugin technical reference
│       ├── ARCHITECTURE.md
│       ├── ONBOARDING.md             # Analyst-facing setup + first-RFP walkthrough
│       └── skills/
│           ├── _shared/knowledge/    # Institutional knowledge (PR-only updates)
│           └── <skill>/SKILL.md      # 12 skills — see plugin README for details
├── README.md                         # this file
└── .gitignore
```

## Approach

Modeled on the gstack philosophy (per-skill folders, slash-command invocation, autoplan-style review loops, persistent learnings) but adapted for Claude.ai's runtime — no sub-agent dispatch, no bash hooks, no `.env` secrets at runtime. Skills are pure prompt content; secrets live in MCP Connectors at the org level when needed (v1.5+).

## Goal

Take Consultadd's analyst proposal team to a consistent, gated, audited pipeline that scales toward **1,000 RFPs/month** without sacrificing quality. Every plugin here is built against that thesis. The strategic plan lives at `~/.claude/plans/system-instruction-you-are-working-shimmering-quiche.md` (local, not in repo).

## Contributing

Adding a new plugin: create a sibling folder under `plugins/`, add its `.claude-plugin/plugin.json`, register it in `.claude-plugin/marketplace.json`, and PR. Once `main` is merged, the new plugin propagates to all installed analysts within minutes.
