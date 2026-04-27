---
name: parse-rfp
description: Use when the analyst has an RFP PDF (or other source document) and needs it converted to clean markdown for downstream skills. First step of every RFP workflow. Triggers when the analyst says "parse this RFP", "extract the RFP", "convert this PDF", or invokes /rfp.
triggers: ["parse rfp", "extract rfp", "convert this pdf"]
---

# Parse RFP — PDF to Clean Markdown

Convert an RFP PDF into structured markdown that downstream skills can read reliably. Reducto primary, Claude vision fallback. Surfaces parse failures explicitly — never proceed silently on a partial parse.

## Workflow

1. **Identify input.** Take the PDF path (or URL) the analyst provides. If unspecified, prompt. Accept `.pdf`, `.docx`, `.html`. For other formats, stop and ask.

2. **Primary path: Reducto API.**

   ```bash
   # Load env (REDUCTO_API_KEY, REDUCTO_BASE_URL) from ~/.claude/skills/consultadd-rfp/.env
   source ~/.claude/skills/consultadd-rfp/lib/load-env.sh

   if [[ -z "${REDUCTO_API_KEY:-}" ]]; then
     echo "REDUCTO_API_KEY not set — skipping Reducto, going to vision fallback." >&2
     # jump to step 3
   fi

   RFP_PDF="<path supplied by analyst>"
   BASE="${REDUCTO_BASE_URL:-https://platform.reducto.ai}"

   # Step A — upload local PDF, receive a reducto:// file_id
   UPLOAD_JSON=$(curl -fsS -X POST "${BASE}/upload" \
     -H "Authorization: Bearer ${REDUCTO_API_KEY}" \
     -F "file=@${RFP_PDF}")
   FILE_ID=$(echo "$UPLOAD_JSON" | jq -r '.file_id')

   # Step B — synchronous parse on the uploaded file
   PARSE_JSON=$(curl -fsS -X POST "${BASE}/parse" \
     -H "Authorization: Bearer ${REDUCTO_API_KEY}" \
     -H "Content-Type: application/json" \
     -d "{\"input\": \"${FILE_ID}\"}")

   # Step C — extract markdown.
   #   When result.type == "full":  concatenate result.chunks[].content
   #   When result.type == "url":   fetch the URL and concatenate from it (large-doc path)
   RESULT_TYPE=$(echo "$PARSE_JSON" | jq -r '.result.type')
   if [[ "$RESULT_TYPE" == "full" ]]; then
     echo "$PARSE_JSON" | jq -r '.result.chunks[].content' > ./rfp-parsed.md
   elif [[ "$RESULT_TYPE" == "url" ]]; then
     RESULT_URL=$(echo "$PARSE_JSON" | jq -r '.result.url')
     curl -fsS "$RESULT_URL" | jq -r '.chunks[].content' > ./rfp-parsed.md
   else
     echo "Unexpected Reducto result.type: $RESULT_TYPE" >&2
     # fall through to vision fallback
   fi
   ```

   For docs hosted at a public URL, you can skip the upload step and pass the URL directly as `"input"` to `/parse`.

3. **Fallback: Claude vision.** If Reducto returned an error, `REDUCTO_API_KEY` was unset, or `result.type` was unexpected:
   - Use Claude's native PDF read (Claude Code can `Read` PDFs directly) — page by page, extract text + structure into markdown.
   - Save to `./rfp-parsed.md` with header line `[PARSED VIA CLAUDE VISION FALLBACK]` so downstream skills know parse confidence is lower.

4. **Extract metadata.** From the parsed content, identify and save to `./rfp-meta.json`:
   - `agency` — issuing agency or entity
   - `rfp_number` — solicitation/RFP number
   - `title` — RFP title
   - `due_date` — proposal due date (ISO 8601 if parseable)
   - `q_and_a_deadline` — questions due date if specified
   - `page_count` — total pages
   - `sections_detected` — list of top-level section headers found
   - `attachments_referenced` — appendices the RFP references that we may need
   - `parse_method` — `reducto` / `claude-vision-fallback`
   - `parse_confidence` — `high` (Reducto) / `medium` (vision fallback) / `low` (heuristics flagged issues)

5. **Smoke-check the parse.** Quick sanity passes:
   - Did we capture at least one obvious requirements section ("Statement of Work", "Scope", "Requirements", "Tasks")?
   - Did we capture the response submission instructions?
   - Did we capture due dates?

   If any are missing, write findings to `./rfp-parse-warnings.md` and surface to the analyst before continuing.

6. **Emit telemetry.**

   ```bash
   source ~/.claude/skills/consultadd-rfp/lib/telemetry.sh
   tel_emit parse-rfp complete "{\"method\": \"${METHOD}\", \"pages\": ${PAGES}, \"sections\": ${SECTIONS}, \"confidence\": \"${CONF}\"}"
   ```

## Constraints

- **Never proceed silently on parse failure.** If both Reducto and vision fail, stop and surface to the analyst with a path forward (manual OCR? request source-doc from agency?).
- **Preserve structure.** Heading levels in the output markdown reflect heading levels in the source. Tables stay as markdown tables. Form fields stay as form fields. Downstream skills depend on this structure for section-split.
- **Don't summarize or compress the RFP.** Verbatim extraction. The whole point is to give downstream skills the full text.
- **Telemetry is best-effort** (env vars unset → no-op).
- **API key hygiene.** Never echo `$REDUCTO_API_KEY` to logs or audit trails. Treat any rfp-audit file as if it could be shared.

## Output Files

- `./rfp-parsed.md` — the parsed markdown
- `./rfp-meta.json` — extracted metadata
- `./rfp-parse-warnings.md` — only created if smoke-checks flagged issues

## API Reference

- Upload: `POST https://platform.reducto.ai/upload` (multipart `file=@...`) → `{"file_id": "reducto://abc.pdf"}`
- Parse: `POST https://platform.reducto.ai/parse` (json `{"input": "<file_id-or-url>"}`) → `{"result": {"type": "full"|"url", "chunks": [{"content": "..."}]}, "job_id": "...", "duration": ..., "usage": {...}}`
- Auth: `Authorization: Bearer $REDUCTO_API_KEY`
- Docs: https://docs.reducto.ai/quickstart and https://docs.reducto.ai/api-reference/parse
