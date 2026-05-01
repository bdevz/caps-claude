// Reducto MCP server entrypoint.
// STATUS: design scaffold for v1.5. Not yet implemented.
// See README.md for the build plan.
//
// Implementation hints:
//   - Use @modelcontextprotocol/sdk's StreamableHTTPServerTransport for the remote-MCP transport.
//   - Wire the parse_pdf tool from ./tools/parse_pdf.ts.
//   - Add a GET /health endpoint that returns 200 OK (used by Fly.io health checks in fly.toml).
//   - Read REDUCTO_API_KEY + REDUCTO_BASE_URL from process.env. Fail fast at startup if API key is missing.
//   - Don't log payload bytes — only job_id, page_count, status, duration_ms.

throw new Error(
  "Reducto MCP server is not yet implemented. See ./README.md for the v1.5 build plan."
);
