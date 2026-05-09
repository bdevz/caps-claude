---
name: firm-background
description: Use when starting an RFP draft and standard Consultadd boilerplate (company overview, certifications, NAICS, key personnel, capability statements) needs to be inserted into the working RFP document. Triggers when the analyst says "fill in firm background", "add Consultadd info", "inject company overview", or starts a new RFP draft after `/parse-rfp`.
---

# Firm Background Injection

You are inserting Consultadd's institutional boilerplate into an RFP response. **Never invent details.** Read only from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/`. If a knowledge file is missing or empty, log the gap — do not fabricate.

## Workflow

1. **Identify required firm-info sections.** Read the parsed RFP — typically `./rfp-parsed.md` (output of `/parse-rfp`) or whatever path the analyst specifies. Scan for explicit asks: company overview, key personnel, past performance, certifications, NAICS, set-aside attestation, financial standing, insurance coverage, security clearances. Build a list of required sections.

2. **Map each required section to a knowledge file:**

   | RFP requirement | Knowledge source |
   |---|---|
   | Company overview / background | `knowledge/consultadd-background.md` |
   | Mission / differentiators | `knowledge/consultadd-background.md` (Mission, Core Differentiators) |
   | NAICS / set-asides / certifications | `knowledge/certifications.md` |
   | Insurance | `knowledge/certifications.md` (Insurance section) |
   | Capability statements / scope of services | `knowledge/capabilities.md` |
   | Key personnel bios | `knowledge/key-personnel/<role>.md` (pick by role match) |
   | Past performance / case studies | `knowledge/past-wins/*.md` (pick 3 most relevant by domain) |
   | Standard MSA terms | `knowledge/compliance/standard-msa-terms.md` |
   | Attestations | `knowledge/compliance/attestations/<topic>.md` |

3. **Read each mapped file verbatim.** Do NOT paraphrase, condense, or rewrite. The language has been approved by leadership / Legal. Length adjustments (e.g., short bio vs. full bio) are fine if the file provides both versions.

4. **Format output for analyst paste.** Write a single file `./firm-background-blocks.md` in the RFP working dir. Each block is tagged with the target RFP-section header so the analyst can paste it under the correct heading:

   ```markdown
   ## [RFP Section: Company Background]
   <verbatim content from knowledge/consultadd-background.md>

   ## [RFP Section: Key Personnel]
   ### Program Manager
   <verbatim short bio from knowledge/key-personnel/program-manager.md>

   ### Chief Data Architect
   <verbatim short bio from knowledge/key-personnel/chief-data-architect.md>

   ## [RFP Section: NAICS Codes]
   <verbatim from knowledge/certifications.md>
   ```

5. **Flag gaps.** For every required section where the knowledge file is missing, empty, or contains unresolved `<TODO>` markers, write a `./firm-background-gaps.md` with:
   - Which RFP requirement is unmet
   - Which knowledge file should provide it
   - What language to source (1-line summary)
   - Suggested DRI to ask

   Do NOT fabricate to fill the gap. The analyst will source it externally and ideally PR the missing content into `knowledge/`.

6. **Past-wins selection — be specific.** When picking 3 past-wins to cite:
   - Match on NAICS code first
   - Then on service-line overlap
   - Then on contract-vehicle similarity
   - Tie-break on recency (within last 3 years preferred)
   - **Always check the `Approved for Use In` field** — never cite a past win the field excludes

7. **Emit telemetry on completion:**

   *(Telemetry is out of scope for v1. When the telemetry MCP Connector is live in v1.5, this skill will call its emit tool here.)*

## Constraints

- **Read knowledge files; never fabricate.** If a fact (e.g., contract value, certification number) isn't in `knowledge/`, log to gaps and continue.
- **Never modify `knowledge/*.md` from this skill.** Knowledge updates are PR-only, gated by the knowledge DRI.
- **Past-wins approval check is mandatory.** Honor `Approved for Use In` exclusions every time.
- **Key-personnel info needs HR + named-individual sign-off** before final RFP submission. This skill outputs the bio drafts, but the analyst confirms with HR before submitting. Add a flag at the top of any output that includes personnel bios: `[VERIFY: HR + named individual sign-off required before submission]`.
- **Telemetry is best-effort.** If the emit fails (env vars unset, network down), continue silently — never block the analyst on observability.

## Output Files

- `./firm-background-blocks.md` — paste-ready content blocks tagged by RFP section
- `./firm-background-gaps.md` — list of missing content (only created if gaps exist)
