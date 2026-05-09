---
name: parse-rfp
description: Use when the analyst has uploaded an RFP PDF (or other source document) and needs Claude to extract the content into clean structured markdown for downstream skills. First step of every RFP workflow. Triggers when the analyst uploads a PDF, says "parse this RFP", "extract the RFP", or invokes /rfp.
---

# Parse RFP — PDF to Clean Markdown

Convert an uploaded RFP into structured markdown that downstream skills can read reliably. v1 uses Claude.ai's native PDF reading capability. v1.5 will swap in a Reducto MCP Connector when available; the SKILL.md output contract stays the same so downstream skills don't change.

## Workflow

1. **Identify input.** The analyst uploads an RFP file in the claude.ai chat (PDF, DOCX, HTML). If nothing is uploaded yet, ask them to attach the file. For an RFP available at a public URL, the analyst can paste the URL and Claude will fetch it.

2. **Read the document end-to-end.** Use Claude.ai's native PDF read on the uploaded file. Walk every page. Preserve:
   - Heading hierarchy (use the source's heading levels — `#`, `##`, `###` — verbatim)
   - Tables (markdown tables, never collapsed into prose)
   - Form fields (preserved as form fields)
   - Numbered lists, bullet lists
   - Footnotes, references, appendix pointers

3. **Write the parsed content** to `./rfp-parsed.md`. This is the contract downstream skills depend on.

4. **Extract metadata** to `./rfp-meta.json`:
   - `agency` — issuing agency or entity
   - `rfp_number` — solicitation/RFP number
   - `title` — RFP title
   - `due_date` — proposal due date (ISO 8601 if parseable)
   - `q_and_a_deadline` — questions due date if specified
   - `page_count` — total pages
   - `sections_detected` — list of top-level section headers found
   - `attachments_referenced` — appendices/forms the RFP references that we may need
   - `parse_method` — `claude-native` (v1) or `reducto-mcp` (v1.5)
   - `parse_confidence` — `high` / `medium` / `low` (use `medium` if you had to OCR image-only pages)

5. **Smoke-check the parse.** Quick sanity passes:
   - Did we capture at least one obvious requirements section ("Statement of Work", "Scope of Work", "Requirements", "Tasks")?
   - Did we capture the response submission instructions?
   - Did we capture due dates?

   If any are missing, write findings to `./rfp-parse-warnings.md` and surface to the analyst before continuing.

6. **Telemetry:** *(Out of scope for v1. When the telemetry MCP Connector is live in v1.5, this skill will call its emit tool here.)*

## Constraints

- **Never proceed silently on parse failure.** If the document is malformed, encrypted, image-only without OCR, or otherwise unreadable, stop and surface the error to the analyst with a path forward (request a text version from the agency, manual OCR, etc.).
- **Preserve structure.** Heading levels, tables, forms — verbatim. Downstream skills depend on this for section-split.
- **Don't summarize or compress the RFP.** Verbatim extraction. The whole point is to give downstream skills the full text.
- **Don't fabricate metadata.** If the RFP doesn't state a due date in a way you can confidently parse, set `due_date` to `null` and note it in `rfp-parse-warnings.md` — never guess.

## Output Files

- `./rfp-parsed.md` — the parsed markdown (contract for downstream skills)
- `./rfp-meta.json` — extracted metadata
- `./rfp-parse-warnings.md` — only created if smoke-checks flagged issues

## Roadmap (v1.5)

A **self-hosted Reducto MCP wrapper** is designed at `mcp-servers/reducto/` (in this same repo). When deployed and connected as a Claude Team Custom Connector, this skill will be updated to:

1. Call `Reducto:parse_pdf` (the wrapper exposes one tool that handles both Reducto's `/upload` and `/parse` internally; exact fully-qualified tool name to be verified once the connector is connected)
2. Receive `{ markdown, page_count, parse_method }`
3. Write the markdown into `./rfp-parsed.md`
4. Set `parse_method=reducto-mcp` and `parse_confidence=high` in `./rfp-meta.json`

Output contract (`rfp-parsed.md`, `rfp-meta.json`) stays identical, so downstream skills don't need any change. The wrapper's design + deploy plan lives in `mcp-servers/reducto/README.md`.
