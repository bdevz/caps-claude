---
name: cross-verify
description: Use after the reviewer pass to perform an INDEPENDENT second-opinion review of the RFP draft. Reads the artifact only — never the session that produced it — so it has fresh eyes. Catches unsupported claims, weasel words, hallucinated specifics, missing requirement responses that internal review missed. Optional Codex CLI dual-voice if available.
---

# Cross-Verify — Independent Dual-Voice Review

The "independent eyes" gate. Mirrors gstack's `codex` skill pattern: read the produced artifact in fresh context (no session pollution from the producing chain), critique adversarially. Mark every claim as Substantiated / Speculative / Hallucinated / Missing-Source.

## Why Independent Context

The specialists, writer, and reviewer all share session context. Patterns of reasoning leak between them. Cross-verify deliberately reads ONLY the artifacts — `./rfp-parsed.md` (the original RFP) and `./rfp-draft.md` (the response) — so it can spot claims that look plausible to insiders but lack grounding to a fresh reader.

## Workflow

1. **Spawn isolated context.** Use the `Agent` tool with subagent_type=general-purpose. Pass it ONLY:
   - `./rfp-parsed.md` (full text)
   - `./rfp-draft.md` (full text)
   - `./rfp-eval-criteria.md` if present
   - `./eligibility-decision.md` if present (so it knows what was decided)

   **Do not pass session history, specialist drafts, or the review report.** The point is independence.

2. **The sub-agent's prompt** (used by this skill when it dispatches):

   > You are a critical reviewer of an RFP response. You have NOT seen the drafting process. You have ONLY the RFP and the response.
   >
   > Read both. For every claim in the response, classify:
   > - **Substantiated** — directly grounded in the RFP, common knowledge, or self-evident.
   > - **Speculative** — plausible but not provable from what you can see; would benefit from a citation.
   > - **Hallucinated** — appears specific (numbers, dates, named past wins, technology versions) but you have no way to verify; high suspicion of fabrication.
   > - **Missing source** — language like "industry-leading" or "best-in-class" with no substantiation.
   >
   > Also identify:
   > - **Unanswered RFP requirements** — anything the RFP asks for that the response doesn't address.
   > - **Weasel words** — language that softens commitments inappropriately ("we strive to", "we believe we can", "our goal is").
   > - **Tone mismatches** — places where the response's voice clashes with the RFP's evaluator profile (technical evaluators want different language than executive committees).
   >
   > Output a structured critique with line-references where possible.

3. **Optional: Codex dual-voice.** If `CONSULTADD_USE_CODEX=true` is set and the `codex` CLI is on PATH:

   ```bash
   if [[ "$CONSULTADD_USE_CODEX" == "true" ]] && command -v codex >/dev/null; then
     # Pass the same artifacts to Codex with a similar adversarial prompt.
     # Capture Codex's output to ./codex-critique.md
   fi
   ```

   Run Codex in parallel with the Claude sub-agent. Two independent voices catch different failure modes.

4. **Merge findings.** Combine the Claude sub-agent's critique and (if used) Codex's into `./cross-verify-report.md`:

   ```markdown
   # Cross-Verify Report — <RFP Number>

   ## Substantiated Claims
   <count + sample>

   ## Speculative Claims
   - <list with line refs>

   ## Hallucination Suspicions
   - <list with line refs — HIGH severity, surface to Taste Gate>

   ## Missing-Source Language
   - <list — superlatives without substantiation>

   ## Unanswered RFP Requirements
   - <list with RFP section refs — HIGH severity>

   ## Weasel Words
   - <list>

   ## Tone Concerns
   - <list>

   ## Reviewers
   - Claude sub-agent (independent context): <ran | failed>
   - Codex CLI: <ran | not-available | disabled>
   ```

5. **Severity routing.**
   - **Hallucination suspicions** and **unanswered requirements** → Challenge Gate.
   - **Speculative claims** and **missing-source superlatives** → Taste Gate.
   - **Weasel words** and **tone concerns** → Mechanical (writer can fix on next pass) or Taste depending on context.

6. **Emit telemetry.**

   *(Telemetry is out of scope for v1. When the telemetry MCP Connector is live in v1.5, this skill will call its emit tool here.)*

## Constraints

- **Independence is the whole point.** Sub-agent gets ONLY the two markdown files — not session history, not specialist drafts, not the review report. If you slip context in, you've just made a second internal reviewer.
- **Don't auto-fix.** This skill only critiques. Fixes go through writer → reviewer on a re-pass, or are surfaced at the Taste / Challenge gate.
- **Codex is optional.** If unavailable, run Claude-only and note in the report.

## Output Files

- `./cross-verify-report.md` — merged critique
- `./codex-critique.md` — Codex output if used (not deleted; keeps audit trail)
