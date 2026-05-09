# Reducto MCP Server (v1.5)

A thin remote MCP server that wraps the Reducto REST API and exposes a `parse_pdf` tool to Claude Team / claude.ai. Connects to Claude Team as a **Custom Connector** (Org admin → Connectors → Custom → Web → enter the deployed HTTPS URL).

**Why we built this:** Claude Team Custom Connectors only accept remote HTTPS endpoints — no stdio/local MCP servers. No official Reducto MCP server exists, the community PyPI package is unverified and stdio-only, and the Gumloop hosted alternative routes RFP PDFs through a third party. Self-hosting keeps the Reducto API key + every RFP PDF inside Consultadd's infrastructure.

## What it exposes

One MCP tool, callable from any Consultadd skill once the Connector is enabled:

| Tool | Input | Output | Behavior |
|---|---|---|---|
| `parse_pdf` | `{ pdf_url?: string, pdf_base64?: string }` (one required) | `{ markdown: string, page_count: number, parse_method: "reducto" }` | Calls Reducto `POST /upload` (when given base64 file content) → receives `file_id` → calls `POST /parse` → concatenates `result.chunks[].content` and returns. Handles `result.type=full` and `result.type=url` (large-doc fallback). |

Future tools (out of scope for v1.5):
- `parse_pdf_async` — for documents over Reducto's sync threshold; returns a job_id and a poll endpoint
- `extract_data` — Reducto's structured-extraction endpoint (different output contract)
- `split_document` — Reducto's document-splitting endpoint

Add these only when a real RFP needs them. v1.5's bar is "PDF → markdown" parity with Claude.ai's native PDF read, just at higher fidelity.

## Architecture

```
claude.ai user →
  consultadd-rfp plugin → /parse-rfp skill →
    (calls tool by fully-qualified name) →
      Anthropic's MCP Connector dispatch →
        HTTPS POST → our Reducto MCP server →
          Reducto REST API (using REDUCTO_API_KEY in our env) →
            markdown back through the same chain
```

The skill never sees the API key. The server holds it. The user uploads a PDF in claude.ai; Claude.ai sends the file content to our server (via the connector); we forward to Reducto; markdown comes back.

## Tech stack

- **Runtime:** Node.js 22+ (TypeScript)
- **MCP SDK:** [`@modelcontextprotocol/sdk`](https://github.com/modelcontextprotocol/typescript-sdk) — the official TypeScript SDK
- **Transport:** Streamable HTTP (the supported remote MCP transport for Claude Team)
- **HTTP client:** native `fetch` (Node 22 has it built-in)
- **Deploy target:** **Fly.io** recommended for v1.5 (one machine, always-on, ~$3/mo). Render or Cloud Run also work.

Why Fly.io: simplest deploy (`fly launch && fly deploy`), automatic HTTPS with a `fly.dev` subdomain (no DNS work for v1.5), and persistent machines (no cold-start latency on RFP parses). Scale to zero is fine for our 12-user volume.

## File layout (when implemented)

```
mcp-servers/reducto/
├── README.md                # this file
├── package.json
├── tsconfig.json
├── Dockerfile
├── fly.toml                 # Fly.io deploy config
├── .dockerignore
├── .env.example             # REDUCTO_API_KEY=... + REDUCTO_BASE_URL=...
└── src/
    ├── index.ts             # MCP server entrypoint, /mcp endpoint, tool registration
    ├── reducto.ts           # Thin wrapper around Reducto REST (upload + parse)
    └── tools/
        └── parse_pdf.ts     # parse_pdf tool implementation
```

## Build plan (~1-2 days)

**Day 1 — local dev:**
1. `npm init -y` + install `@modelcontextprotocol/sdk`, `zod`
2. Implement `src/reducto.ts` — port the curl flow we already verified working (`POST /upload`, `POST /parse`, handle `result.type=full|url`)
3. Implement `src/tools/parse_pdf.ts` — define input/output schemas with zod, call into reducto.ts
4. Implement `src/index.ts` — MCP server with Streamable HTTP transport, register the tool
5. Test locally: `curl` against `http://localhost:8080/mcp` with a sample PDF; verify markdown comes back

**Day 2 — deploy + connect:**
1. Write `Dockerfile` (Node 22-alpine, copy src, `npm ci --omit=dev`, `CMD node dist/index.js`)
2. `fly launch` → answer prompts → `fly secrets set REDUCTO_API_KEY=<key>` → `fly deploy`
3. Verify health: `curl https://<app>.fly.dev/health` (add a `/health` endpoint that returns 200)
4. In Claude Desktop: Org settings → Connectors → Add → Custom → Web → enter `https://<app>.fly.dev/mcp`
5. Verify connector appears for an admin test user; toggle it on
6. Test from a real chat: upload a PDF, watch the connector call resolve, confirm the markdown comes back

**Day 3 (optional) — wire into the plugin:**
1. Update `plugins/consultadd-rfp/skills/parse-rfp/SKILL.md` to call the connector tool by its fully-qualified name (verify the exact form once the connector is connected — the docs don't formally specify the syntax; observe what claude.ai shows in the tools panel)
2. Bump `parse_method` in `rfp-meta.json` from `claude-native` to `reducto-mcp`
3. Open PR — merge — auto-syncs to all 12 users

## Security notes

- **API key never leaves the server.** Never commit it. Use `fly secrets set` (encrypted at rest, injected as env at runtime).
- **No request logging of PDF content.** RFPs often contain agency-sensitive material. Log only metadata (job_id, page_count, status, duration). Never log payload bytes.
- **HTTPS only.** Fly.io provides this by default on `*.fly.dev` subdomains.
- **Rate limit at the server.** A simple token-bucket per source IP / connector session prevents accidental loops from blowing through the Reducto budget.
- **No persistence.** Don't store parsed markdown server-side. Forward and forget.

## Connecting to Claude Team

Once deployed:

1. Owner or Primary Owner opens **Claude Desktop** (web doesn't have admin → connectors yet)
2. **Organization settings → Connectors**
3. **Add → Custom → Web**
4. **Remote MCP server URL:** `https://<your-app>.fly.dev/mcp`
5. Optional: OAuth (skip for v1.5 — internal use, IP allowlist instead if paranoid)
6. **Add**
7. Each user: **Customize → Connectors → Reducto → Connect**
8. Skill can now reference the tool

## Open questions to resolve during build

1. **Tool naming convention in skill prompts.** Anthropic's Connector docs don't formally document `Server:tool` vs. `Server.tool` vs. bare tool name in skill content. Observe what claude.ai shows once connected, then update `parse-rfp/SKILL.md` accordingly.
2. **Auto-invocation matching.** Will Claude.ai auto-pick `Reducto:parse_pdf` when our parse-rfp skill runs, or do we need to instruct in the skill prose? Test once connected.
3. **Streamable HTTP vs SSE.** MCP supports both transports. Streamable HTTP is the newer recommendation; SSE is older. Use Streamable HTTP unless Anthropic's Connector dispatch only supports SSE — verify by trying both during Day 2 if Day 2 hits an issue.
4. **Per-user vs org-level credentials.** v1.5 ships with one shared `REDUCTO_API_KEY` (matches the current testing posture). v2 may move to per-user keys via OAuth — defer.

## Cost model

For 12 users × ~3 RFPs/week × ~30 pages each = ~108 RFPs/month × ~30 pages = ~3,240 pages/month. At Reducto's published rates (~$0.01/page on standard tier), that's ~$32/month for parsing. Fly.io hosting: ~$3/month for one shared-cpu-1x machine. Total v1.5 ops cost: **<$50/month**.

For the goal scale of 1,000 RFPs/month: ~$300/month parsing + still ~$3/month hosting. Add a second Fly machine for redundancy at that point.

## Status

**As of 2026-05-01:** Design only. Not yet implemented. No code in `src/`. This README captures the decision and sets up the file scaffold for whoever picks this up in v1.5 (Week 3-4 of the rollout plan).
