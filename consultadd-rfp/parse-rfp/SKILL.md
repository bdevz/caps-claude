---
name: parse-rfp
description: Use when the analyst has an RFP PDF (or other source document) and needs it converted to clean markdown for downstream skills. First step of every RFP workflow. Triggers when the analyst says "parse this RFP", "extract the RFP", "convert this PDF", or invokes /rfp.
triggers: ["parse rfp", "extract rfp", "convert this pdf"]
---

# Parse RFP — PDF to Clean Markdown

Convert an RFP PDF into structured markdown that downstream skills can read reliably. Reducto primary, Claude vision fallback. Surfaces parse failures explicitly — never proceed silently on a partial parse.

## Workflow

1. **Identify input.** Take the PDF path or URL the analyst provides. If the analyst hasn't specified, prompt them. Accept `.pdf`, `.docx`, `.html`. For other formats, stop and ask.

2. **Primary path: Reducto API.**

   ```bash
   # Required env vars (set in shell profile):
   #   REDUCTO_API_KEY=<key>
   #   REDUCTO_BASE_URL=https://platform.reducto.ai/api  (default)
   #
   # Reducto returns markdown with structure preserved.
   ```

   POST to Reducto's parse endpoint with the PDF. Wait for the job to complete. Save the returned markdown to `./rfp-parsed.md`.

3. **Fallback: Claude vision.** If Reducto returns an error or `REDUCTO_API_KEY` is unset:
   - Use Claude's PDF/vision capability via the Read tool on the PDF (Claude Code can read PDFs natively).
   - Walk the PDF page by page, extracting text + structure into markdown.
   - Save to `./rfp-parsed.md` with a `[PARSED VIA CLAUDE VISION FALLBACK]` header line so downstream skills know parse confidence is lower.

4. **Extract metadata.** From the parsed content, identify and save to `./rfp-meta.json`:
   - `agency` — issuing agency or entity
   - `rfp_number` — solicitation/RFP number
   - `title` — RFP title
   - `due_date` — proposal due date (ISO 8601 if parseable)
   - `q_and_a_deadline` — questions due date if specified
   - `page_count` — total pages
   - `sections_detected` — list of top-level section headers found
   - `attachments_referenced` — any attachments / appendices the RFP references that we may need
   - `parse_method` — `reducto` or `claude-vision-fallback`
   - `parse_confidence` — `high` (Reducto) / `medium` (vision fallback) / `low` (heuristics flagged issues)

5. **Smoke-check the parse.** Quick sanity passes:
   - Did we capture at least one obvious requirements section (often "Statement of Work", "Scope of Work", "Requirements", "Tasks")?
   - Did we capture the response submission instructions?
   - Did we capture due dates?

   If any of these are missing, write findings to `./rfp-parse-warnings.md` and surface to the analyst before continuing.

6. **Emit telemetry.**

   ```bash
   source ~/.claude/skills/consultadd-rfp/lib/telemetry.sh
   tel_emit parse-rfp complete "{\"method\": \"${METHOD}\", \"pages\": ${PAGES}, \"sections\": ${SECTIONS}, \"confidence\": \"${CONF}\"}"
   ```

## Constraints

- **Never proceed silently on parse failure.** If Reducto fails AND vision fails, stop and surface the error to the analyst with a path forward (manual OCR? request the source-doc from the issuing agency?).
- **Preserve structure.** Heading levels in the output markdown must reflect heading levels in the source. Tables stay as markdown tables. Form fields stay as form fields. Downstream skills depend on this structure for section-split.
- **Don't summarize or compress the RFP.** Verbatim extraction. The whole point is to give downstream skills the full text.
- **Telemetry is best-effort** (env vars unset → no-op).

## Output Files

- `./rfp-parsed.md` — the parsed markdown
- `./rfp-meta.json` — extracted metadata
- `./rfp-parse-warnings.md` — only created if smoke-checks flagged issues

## Integration Stub Notes

- **Reducto API call** — exact endpoint, auth header format, polling pattern: confirm with Reducto docs at https://docs.reducto.ai when you wire this. Pseudocode pattern: POST file → receive job_id → poll job_id until status=complete → fetch result.
- **PDF length limits** — large RFPs (>500 pages) may exceed Reducto's per-job limits or Claude's context. Document chunking strategy when you hit a real one.
