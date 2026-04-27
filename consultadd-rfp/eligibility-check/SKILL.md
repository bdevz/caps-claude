---
name: eligibility-check
description: Use after `/parse-rfp` to determine whether Consultadd qualifies to bid this RFP, what gaps exist, and whether gaps can be closed via partnership / license rental / sub-vendor / teaming agreement. CHALLENGE GATE — hard-blocks the orchestrator on human approval if any gap exists. Triggers on "check eligibility", "can we bid this", "qualification check".
triggers: ["check eligibility", "can we bid this", "qualification check"]
---

# Eligibility Check — CHALLENGE GATE

Determine whether Consultadd is qualified to respond to this RFP. Compares hard requirements (NAICS, set-asides, certifications, clearances, past-performance thresholds, insurance, bonding, geography) against `knowledge/certifications.md` + `knowledge/capabilities.md` + `knowledge/past-wins/*`. Outputs an explicit qualified / mitigatable / no-bid recommendation. **Hard-blocks the orchestrator** until the analyst makes an explicit decision on every gap.

## Workflow

1. **Read sources.**
   - `./rfp-parsed.md` (RFP) and `./rfp-meta.json` (metadata)
   - `~/.claude/skills/consultadd-rfp/knowledge/certifications.md`
   - `~/.claude/skills/consultadd-rfp/knowledge/capabilities.md`
   - `~/.claude/skills/consultadd-rfp/knowledge/past-wins/*.md` (for past-performance threshold matching)

2. **Extract hard requirements from the RFP.** Build a structured list:
   - **NAICS code(s)** required
   - **Set-aside status** required (e.g., 8(a), HUBZone, WOSB, SDVOSB) or "full and open"
   - **Certifications** required (ISO, CMMI, SOC 2, etc.)
   - **Security clearance** required (facility level, personnel levels + counts)
   - **Past performance threshold** (often "$X in similar contracts in last Y years" or "Z prior engagements of similar scope")
   - **Insurance minimums** (general liability $X, professional liability $Y, cyber $Z)
   - **Bonding** (bid bond, performance bond, payment bond — amounts)
   - **Geography** (registered to do business in state X, local-presence requirement)
   - **Workforce composition** (% local hire, DBE/MBE/WBE participation)
   - **Software / platform certifications** (specific vendor partnerships, FedRAMP, StateRAMP)
   - **Other** (anything else stated as mandatory — "shall", "must", "required")

3. **Compare each requirement against `knowledge/`.** For each, mark:
   - **MET** — knowledge file confirms we satisfy
   - **GAP** — we don't satisfy, plus assessment of mitigation:
     - `partnership` — large-business partner can prime, we sub
     - `sub-vendor` — we prime, sub the gap-filling capability
     - `teaming agreement` — joint venture for this specific bid
     - `license rental` — buy/rent the missing certification or vendor partnership
     - `not mitigatable` — gap is structural; recommend no-bid
   - **UNCLEAR** — knowledge file insufficient to determine; needs human research

4. **Past-performance threshold check.** If the RFP requires N prior engagements of $X+ in <domain> within <Y years>, count matching `knowledge/past-wins/*.md` files. Honor `Approved for Use In` filters.

5. **Output `./eligibility-report.md`.** Structure:

   ```markdown
   # Eligibility Report — <RFP Number>

   **Recommendation:** QUALIFIED | MITIGATABLE | NO-BID

   ## Met Requirements
   - <list, each with knowledge-source citation>

   ## Gaps (Mitigatable)
   ### <Requirement Name>
   - **What's required:** <RFP quote>
   - **Our status:** <gap detail>
   - **Suggested mitigation:** <partnership | sub-vendor | teaming | license rental>
   - **Recommended partner candidates:** <if any in past-wins or known network>
   - **Cost / effort to close:** <rough estimate>

   ## Gaps (Not Mitigatable)
   - <list — these would force a no-bid recommendation>

   ## Unclear Requirements (Need Human Research)
   - <list>
   ```

6. **CHALLENGE GATE — hard block.** Output a `./eligibility-decision-required.md` with the explicit decision the analyst must make:

   ```markdown
   # DECISION REQUIRED — Eligibility

   The orchestrator is paused. Before /rfp continues, you must explicitly resolve each gap below.

   ## Gaps Awaiting Decision
   1. <Gap name> — choose one: [confirm mitigation: <option>] [accept risk] [no-bid]
   2. ...

   ## Recommendation
   <model's recommendation, but the decision is yours>

   ## How to Resume
   After deciding, run `/rfp --resume` (or invoke the next phase manually).
   ```

   The orchestrator MUST NOT proceed past this gate until the analyst writes their decision. Implementation: orchestrator checks for `./eligibility-decision.md` (analyst-authored) before continuing — if absent, stop.

7. **Emit telemetry.**

   ```bash
   source ~/.claude/skills/consultadd-rfp/lib/telemetry.sh
   tel_emit eligibility-check complete "{\"recommendation\": \"${REC}\", \"gaps\": ${GAPS}, \"mitigatable\": ${MIT}, \"unclear\": ${UNC}}"
   ```

## Constraints

- **Hard requirements only.** Don't list nice-to-haves or scoring criteria — those are for sales-mktg-expert and the response itself.
- **No fabricating mitigation paths.** Suggested partners come from past-wins files or are flagged as "needs research" — never invented.
- **Recommendation must be unambiguous.** QUALIFIED / MITIGATABLE / NO-BID. No "probably qualified" hedging.
- **Past-performance citation must honor `Approved for Use In`.** Don't count an excluded past win toward the threshold.
- **Hard block is non-negotiable.** Never let the orchestrator skip past a real gap.

## Output Files

- `./eligibility-report.md` — full analysis
- `./eligibility-decision-required.md` — created only if gaps exist; orchestrator blocks on this
- `./eligibility-decision.md` — analyst-authored response (presence unblocks orchestrator)
