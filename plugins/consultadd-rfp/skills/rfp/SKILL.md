---
name: rfp
description: End-to-end RFP authoring orchestrator. Walks the analyst through a linear pipeline — parse → firm-background → eligibility-check (gate) → expert drafting → writer → reviewer → cross-verify → final pre-submission gate → submission-ready output. Use when the analyst uploads an RFP and says "build the proposal", "run RFP", "draft the response from this PDF", or "do the full pipeline".
---

# /rfp — End-to-End RFP Authoring Recipe

A linear, analyst-driven pipeline. Unlike Claude Code's autoplan-style orchestrator, this skill does NOT spawn parallel sub-agents — the analyst drives the loop in chat, invoking each phase explicitly. At every gate, you (Claude) summarize the decision the human must make and hold position until they make it.

This skill can be invoked two ways:
- **Single-prompt mode:** the analyst uploads the PDF and says "/rfp" — Claude runs Phases 1-3, hits the eligibility gate, waits for human confirmation, then continues through Phase 10.
- **Step-by-step mode:** the analyst invokes each sub-skill manually (`/parse-rfp`, then `/firm-background`, then `/eligibility-check`, etc.). `/rfp` itself is then a recipe / reference, not the runner.

Both paths produce the same artifacts. Single-prompt is faster; step-by-step gives the analyst more control.

## Decision Classification

Throughout the pipeline, classify every judgment call:

- **Mechanical** — formatting, well-defined facts pulled from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/`, section ordering matching the RFP's TOC. Auto, silent.
- **Taste** — auto-decide and **surface at the final pre-submission gate**. Tone, narrative emphasis, optional sections, language style.
- **Challenge** — **never auto. Block on human sign-off.** Eligibility judgment, pricing, capability claims, attestations, key-personnel commitments, unusual MSA terms.

**Never escape a Challenge gate without explicit human approval.**

## Phases

### Phase 1 — `/parse-rfp` (Mechanical)

Use the uploaded PDF. Run the `parse-rfp` skill workflow. Produces `./rfp-parsed.md` and `./rfp-meta.json`.

If parse warnings exist (`./rfp-parse-warnings.md`), surface them to the analyst and ask whether to proceed.

### Phase 2 — `/firm-background` (Mechanical)

Read the parsed RFP, identify required firm-info sections, pull approved boilerplate from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/knowledge/`, and produce `./firm-background-blocks.md` (paste-ready content blocks tagged by RFP section). If knowledge files have gaps, write `./firm-background-gaps.md` and continue — gaps are flagged but don't block.

### Phase 3 — `/eligibility-check` (CHALLENGE GATE)

Run the eligibility check. Compares RFP requirements against `certifications.md` and `capabilities.md`. Produces `./eligibility-report.md` with a recommendation: **QUALIFIED**, **MITIGATABLE**, or **NO-BID**.

**This is a hard gate.** If recommendation is QUALIFIED with no gaps: continue.

If MITIGATABLE or NO-BID: STOP. Tell the analyst:

> Eligibility check complete. Recommendation: \<REC\>. \<N\> gaps require your decision. Open `./eligibility-report.md` to see them. For each gap, decide: confirm a mitigation (partnership / sub-vendor / teaming / license rental), accept the risk, or no-bid. Write your decisions in plain English to `./eligibility-decision.md`. When ready, say "continue /rfp" and we'll resume from Phase 4.

DO NOT proceed without an `./eligibility-decision.md` file from the analyst. If the recommendation was NO-BID and the analyst confirms no-bid, end the pipeline cleanly with a "no-bid logged" message.

### Phase 4 — Section split (Mechanical)

Read `./rfp-parsed.md`. For each top-level section in the RFP's response structure (Section L / Submission Format), classify which specialist owns it:

- **tech-expert** — architecture, methodology, technical approach, technology, integration, data, security/technical, performance
- **legal-expert** — MSA, terms, attestations, IP, liability, indemnification, governing law
- **ops-expert** — project management, transition, risk, QA/QC, staffing, schedule, deliverables, communications
- **sales-mktg-expert** — cover letter, executive summary, value proposition, win themes, why-us
- **public-policy-expert** — regulatory alignment, equity/access, sustainability, accessibility, small-business utilization (only if government / public-sector)

Write each specialist's assigned-sections list to `./rfp-sections-<expert>.md`. Sections may be assigned to multiple specialists when they straddle.

### Phase 5 — Specialist drafting (sequential, NOT parallel)

In Claude.ai's runtime, sub-skills run sequentially — there is no parallel sub-agent dispatch. Run each specialist whose assigned-sections file is non-empty:

1. `/tech-expert` — produces `./drafts/tech-*.md`
2. `/legal-expert` — produces `./drafts/legal-*.md`
3. `/ops-expert` — produces `./drafts/ops-*.md`
4. `/sales-mktg-expert` — produces `./drafts/sales-mktg-*.md`
5. `/public-policy-expert` — produces `./drafts/public-policy-*.md` (skip if not applicable)

Each specialist reads only its assigned sections (`./rfp-sections-<expert>.md`) plus its relevant knowledge files. Each flags `[VERIFY: ...]` markers for any specific claim that wasn't grounded in `_shared/knowledge/`.

### Phase 6 — `/writer` (Taste — surface at final gate)

Read all `./drafts/*.md`. Stitch into `./rfp-draft.md` with consistent voice, transitions, and structure matching the RFP's required outline. Don't change facts — preserve `[VERIFY: ...]` markers.

### Phase 7 — `/reviewer` (Mechanical, may re-dispatch)

Internal QA pass: coverage check, consistency check, citation check, spelling, format. Mechanical fixes auto-apply to `./rfp-draft.md`. If high-severity issues (MISSING coverage, contradictions across sections):

- Identify which specialist owns the gap
- Re-run that specialist for the affected section
- Re-run `/writer`
- Re-run `/reviewer`
- One re-pass max — if issues remain, surface to analyst rather than infinite-loop

### Phase 8 — `/cross-verify` (Mechanical, severity routes)

Independent second-opinion review of `./rfp-draft.md` against `./rfp-parsed.md`. Reads only the artifacts, not the drafting history. Produces `./cross-verify-report.md` classifying every claim as Substantiated / Speculative / Hallucinated / Missing-Source, plus unanswered RFP requirements and weasel words.

Severity routing:
- **Hallucination suspicions** + **unanswered requirements** → Challenge Gate (Phase 9 below — surfaces to human)
- **Speculative claims** + **missing-source superlatives** → Taste Gate (Phase 9)
- **Weasel words** + **tone concerns** → Mechanical fix on next writer pass

### Phase 9 — TASTE / CHALLENGE GATE (block on human)

Compile `./taste-gate.md` listing everything the analyst must look at:

- All `[VERIFY: ...]` markers across drafts
- All Speculative claims from cross-verify
- Unanswered RFP requirements (Challenge — must address)
- Hallucination suspicions (Challenge)
- Missing-Source superlatives
- Voice / emphasis decisions from writer
- Pricing language (always Taste)
- Capability claims (always Taste)
- Attestations (always Challenge)
- Key-personnel commitments (always Challenge)

Tell the analyst:

> Pre-submission review ready. Open `./taste-gate.md` — it lists every claim, number, or commitment that needs your eyes. For each item: confirm, edit `./rfp-draft.md` directly, or replace it. When you're satisfied, create `./taste-gate-cleared.md` (any content, even just "approved by [name] on [date]") and say "finalize /rfp". I'll stitch the final submission and write the audit trail.

DO NOT proceed without `./taste-gate-cleared.md`.

### Phase 10 — Stitch + audit trail (Mechanical)

1. Final-pass writer polish on `./rfp-draft.md` (apply any remaining mechanical fixes)
2. Output `./rfp-submission.md` — submission-ready (note any RFP page-count / formatting compliance issues)
3. Write `./rfp-audit-<YYYYMMDD-HHMM>.md` capturing:
   - Phases run (with start/end timestamps if available)
   - Knowledge files read
   - All `[VERIFY: ...]` markers and how each was resolved
   - All gate decisions with the analyst's choice
   - Specialist drafts retained for traceability
   - Final word count, section count, citation count
4. Tell the analyst:

> Submission-ready proposal at `./rfp-submission.md`. Audit trail at `./rfp-audit-<timestamp>.md`. Submit manually via the agency's portal — never auto-submit.

## Constraints

- **Never escape a Challenge Gate without explicit human sign-off.** This is the entire reason this skill exists.
- **Never auto-submit.** Submission is always human-initiated.
- **One re-pass max for reviewer issues.** Don't infinite-loop on quality issues; surface to human after one fix attempt.
- **Audit trail is mandatory.** Every run, regardless of outcome (including no-bid), writes an audit file.
- **Sequential specialist dispatch.** No parallel sub-agents in Claude.ai runtime — the user can run them in any order they prefer step-by-step, but the canonical order is tech → legal → ops → sales-mktg → public-policy.

## Output Files

| Phase | File | Purpose |
|---|---|---|
| 1 | `./rfp-parsed.md`, `./rfp-meta.json`, `./rfp-parse-warnings.md`* | Parsed source |
| 2 | `./firm-background-blocks.md`, `./firm-background-gaps.md`* | Boilerplate injection |
| 3 | `./eligibility-report.md`, `./eligibility-decision.md` (analyst-authored) | Qualification decision |
| 4 | `./rfp-sections-<expert>.md` | Section split assignments |
| 5 | `./drafts/<expert>-<section>.md`, `./drafts/<expert>-flags.md` | Specialist drafts |
| 6 | `./rfp-draft.md` | Stitched draft |
| 7 | `./review-report.md` | Internal QA |
| 8 | `./cross-verify-report.md` | Independent review |
| 9 | `./taste-gate.md`, `./taste-gate-cleared.md` (analyst-authored) | Pre-submission gate |
| 10 | `./rfp-submission.md`, `./rfp-audit-<timestamp>.md` | Submission-ready output |

*= only created if relevant.
