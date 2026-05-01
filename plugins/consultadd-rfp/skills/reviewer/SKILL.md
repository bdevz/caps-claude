---
name: reviewer
description: Use after the writer produces `./rfp-draft.md` to perform first-pass internal QA — coverage check (every RFP requirement answered), consistency check (no contradictions across sections), spell/grammar, citation check (every specific claim sourced or flagged). Triggers on "review the RFP", "QA the draft", or invoked by /rfp after writer phase.
---

# Reviewer — Internal First-Pass Review

The first set of eyes on the unified draft. Mechanical-decision pass: coverage, consistency, citations, spelling, formatting. Surfaces issues for fixing — never ships independently.

## Workflow

1. **Read inputs.**
   - `./rfp-draft.md` (the writer's output)
   - `./rfp-parsed.md` (so we know what was asked)
   - `./rfp-meta.json` and `./rfp-eval-criteria.md` if present
   - All `./drafts/*-flags.md` files (existing flags from specialists)
   - `./writer-fact-flags.md` if present

2. **Coverage check.** For each requirement in the RFP's response instructions (Section L / Submission Format), confirm the draft has a matching section. Build a coverage table:

   ```markdown
   | RFP Requirement | Draft Section | Status |
   |---|---|---|
   | 2.1 Technical Approach | ## 2.1 Technical Approach | COVERED |
   | 2.2 Management Plan | ## 2.2 Management Plan | COVERED |
   | 2.3 Past Performance | <not found> | MISSING |
   | ... | ... | ... |
   ```

   Any MISSING is a high-severity issue.

3. **Consistency check.** Cross-section contradictions — common ones:
   - Team size in tech section vs. ops staffing model (e.g., tech says "8 engineers", ops says "team of 12")
   - Schedule duration (tech says "12 months", ops says "10 months")
   - Methodology terms (tech says "Agile/Scrum", ops says "Waterfall")
   - Past-win citations (tech cites a past win that legal didn't include in compliance)
   - Pricing references in narrative vs. cost volume

4. **Citation check.** Every specific claim — number, certification, named individual, named past win, vendor partnership, technology version — must be either:
   - Sourced from a `knowledge/` file (citation is implicit if it matches a knowledge entry)
   - Flagged with `[VERIFY: ...]`
   - Otherwise: write a citation issue.

5. **Spell + grammar.** Standard pass. American English unless RFP specifies otherwise.

6. **Format check.**
   - Heading levels consistent
   - Tables render correctly
   - Page-count / word-count limits respected (if RFP specifies, check against `./rfp-meta.json`)
   - Formatting requirements met (font, margin instructions are typically in Section L)

7. **Emphasis vs. eval-criteria check.** If `./rfp-eval-criteria.md` exists, sanity-check that emphasis (length, prominence) of each section roughly matches the criteria's weights. Don't auto-rewrite — just flag mismatches.

8. **Output `./review-report.md`.**

   ```markdown
   # Review Report — <RFP Number>

   **Status:** PASS | ISSUES FOUND

   ## Coverage
   <coverage table>

   ## Consistency Issues
   - <list, severity tagged>

   ## Citation Issues
   - <unsourced claims, ungrounded specifics>

   ## Spelling / Grammar
   - <list of corrections suggested>

   ## Format Issues
   - <page count, headings, tables>

   ## Eval-Criteria Emphasis
   - <if applicable>
   ```

9. **Auto-fix policy.** Mechanical fixes (spelling, heading-level inconsistency, format) — apply directly to `./rfp-draft.md`. Substantive fixes (coverage gaps, consistency, citation) — flag in report only; don't rewrite specialist content.

10. **Emit telemetry.**

    *(Telemetry is out of scope for v1. When the telemetry MCP Connector is live in v1.5, this skill will call its emit tool here.)*

## Constraints

- **Mechanical fixes auto-apply.** Spelling, format, heading levels.
- **Substantive fixes flag-only.** Don't rewrite specialist content; surface for re-dispatch to the specialist.
- **MISSING coverage is high-severity.** The orchestrator should re-run section-split + dispatch if coverage gaps exist.
- **Don't re-evaluate evaluation criteria.** That's the analyst's call. Just flag emphasis mismatches.

## Output Files

- `./review-report.md`
- `./rfp-draft.md` — modified in place if mechanical fixes applied
