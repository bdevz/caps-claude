---
name: rfp
description: End-to-end RFP orchestrator — autoplan analog. Runs the full pipeline from raw PDF to submission-ready response, hard-gating eligibility / pricing / capability claims / attestations to humans. Triggers on "run RFP", "build the proposal", "draft the response from this PDF".
triggers: ["run rfp", "build the proposal", "full rfp pipeline"]
---

# /rfp — End-to-End RFP Orchestrator

The autoplan analog for RFP work. Sequences every specialist, dispatches parallel sub-agents, classifies decisions Mechanical / Taste / Challenge, hard-blocks at gates, writes a complete audit trail.

## Phases

```
Phase 1: parse-rfp                              [Mechanical]
Phase 2: firm-background                        [Mechanical]
Phase 3: eligibility-check                      [CHALLENGE GATE — block]
Phase 4: section-split (embedded logic)         [Mechanical]
Phase 5: parallel specialist dispatch           [Mechanical, sub-agents]
Phase 6: writer                                 [Taste — surface at final]
Phase 7: reviewer                               [Mechanical, may re-dispatch]
Phase 8: cross-verify                           [Mechanical, surfaces severity]
Phase 9: TASTE GATE                             [block on human approval]
Phase 10: stitch + audit-trail                  [Mechanical]
```

## Workflow

### Phase 1 — parse-rfp

Invoke `/parse-rfp` with the analyst-supplied PDF. Wait for `./rfp-parsed.md` and `./rfp-meta.json`. If parse-rfp returns parse warnings, surface to the analyst before continuing — but proceed if they accept.

### Phase 2 — firm-background

Invoke `/firm-background`. It reads `./rfp-parsed.md` + `knowledge/` and produces `./firm-background-blocks.md`. If `./firm-background-gaps.md` is produced, the orchestrator does NOT block, but flags for the analyst (gaps may be fillable from specialist content downstream; if not, they surface at the Taste gate).

### Phase 3 — eligibility-check (CHALLENGE GATE)

Invoke `/eligibility-check`. If recommendation is QUALIFIED with no gaps: continue. Otherwise: hard-stop. Write `./rfp-orchestrator-state.json` with `phase: 3, status: blocked-on-eligibility`. Tell the analyst:

> Eligibility check complete. Recommendation: <REC>. <N> gaps require your decision (see ./eligibility-decision-required.md). Resolve and create `./eligibility-decision.md`, then run `/rfp --resume` to continue.

The orchestrator must not proceed without `./eligibility-decision.md` present.

### Phase 4 — section-split (embedded logic)

Read `./rfp-parsed.md`. For each top-level section in the RFP response structure (Section L / Submission Format), classify which specialist owns it:

- **tech-expert** — architecture, methodology, technical approach, technology, integration, data, security/technical, performance
- **legal-expert** — MSA, terms, attestations, IP, liability, indemnification, governing law
- **ops-expert** — project management, transition, risk, QA/QC, staffing, schedule, deliverables, communications
- **sales-mktg-expert** — cover letter, executive summary, value proposition, win themes, why-us
- **public-policy-expert** — regulatory alignment, equity/access, sustainability, accessibility, small-business utilization (only if government / public-sector — check `./rfp-meta.json` agency type)

For each specialist, write the section list to `./rfp-sections-<expert>.md`. Sections may be assigned to multiple specialists when they straddle (e.g., a "Security" section may need both tech-expert for technical controls and legal-expert for contractual security terms).

### Phase 5 — parallel specialist dispatch

Use the Claude Code Agent tool to launch one sub-agent per specialist that has assigned sections, in parallel. Each sub-agent:

- Receives its assigned-sections list (`./rfp-sections-<expert>.md`)
- Invokes the corresponding skill (`/tech-expert`, `/legal-expert`, etc.)
- Produces drafts in `./drafts/<expert>-<section-slug>.md`
- Returns a summary

Wait for ALL specialists to return. If any specialist fails, decide: re-dispatch (transient) or surface to analyst (structural problem like missing knowledge file).

### Phase 6 — writer

Invoke `/writer`. Produces `./rfp-draft.md`.

### Phase 7 — reviewer

Invoke `/reviewer`. Produces `./review-report.md`. Mechanical fixes auto-apply. If the report flags MISSING coverage or HIGH-severity consistency issues:
- Re-run section-split + relevant specialist + writer (single re-pass)
- Then re-run reviewer
- If still issues after one re-pass: surface to analyst, don't infinite-loop

### Phase 8 — cross-verify

Invoke `/cross-verify`. Produces `./cross-verify-report.md`. Severity routes to the appropriate gate.

### Phase 9 — TASTE GATE

Compile a Taste-gate summary into `./taste-gate.md`:

- All `[VERIFY: ...]` markers across drafts
- All Speculative claims from cross-verify
- All Missing-Source superlatives
- All Weasel words and tone concerns
- All Challenge-Gate items not yet resolved (if any leaked through — should be zero, but surface anyway)
- Voice / emphasis decisions from writer
- Pricing language (always Taste)
- Capability claims (always Taste)
- Attestations (always Challenge)
- Key-personnel commitments (always Challenge)

Block on the analyst. They review `./taste-gate.md`, make decisions, edit `./rfp-draft.md` directly where needed, and then create `./taste-gate-cleared.md` (a one-line confirmation file) to unblock the orchestrator.

### Phase 10 — stitch + audit trail

Once Taste gate is cleared:

1. Final-pass writer polish on `./rfp-draft.md`
2. Output `./rfp-submission.md` — submission-ready (with formatting / page-count compliance noted)
3. Write `./rfp-audit-<timestamp>.md` capturing:
   - All phases run + durations
   - All knowledge files read
   - All `[VERIFY: ...]` markers and how each was resolved
   - All gate decisions and who approved (analyst id from `CONSULTADD_ANALYST_ID`)
   - Specialist drafts retained for traceability
   - Final word count, section count, citation count
4. Telemetry final emit:

   ```bash
   source ~/.claude/skills/consultadd-rfp/lib/telemetry.sh
   tel_emit rfp complete "{\"phases\": 10, \"taste_decisions\": ${T}, \"challenge_decisions\": ${C}, \"duration_total_ms\": ${DUR}, \"audit_file\": \"./rfp-audit-${TS}.md\"}"
   ```

## Resume Behavior

If `--resume` is supplied or `./rfp-orchestrator-state.json` exists with a `blocked-on-*` status:
- Read state file
- Validate the unblock condition (e.g., for Phase 3 block, check that `./eligibility-decision.md` exists and is non-empty)
- Resume from the next phase

## State File

Throughout the run, maintain `./rfp-orchestrator-state.json`:

```json
{
  "rfp_id": "<from meta>",
  "started_at": "<ISO 8601>",
  "current_phase": 5,
  "phases_complete": [1, 2, 3, 4],
  "status": "in-progress | blocked-on-eligibility | blocked-on-taste | complete | failed",
  "block_reason": "...",
  "next_action": "..."
}
```

## Telemetry

Emit on every phase entry and exit. Phase 5 emits per-specialist (one event per sub-agent). Final phase emits the summary above.

## Constraints

- **Never escape a Challenge Gate without explicit human sign-off.** This is the whole point.
- **Never auto-submit.** The orchestrator produces `./rfp-submission.md` — the analyst submits it manually.
- **One re-pass max for reviewer issues.** Don't infinite-loop on quality issues; surface to human after one fix attempt.
- **Audit trail is mandatory.** Every run, regardless of outcome, writes an audit file. The audit is the artifact that gets reviewed when something goes wrong post-submission.
- **Sub-agents in Phase 5 get isolated context.** Each specialist sees only its assigned sections + relevant knowledge — not other specialists' drafts.

## Output Files

- `./rfp-parsed.md`, `./rfp-meta.json` (Phase 1)
- `./firm-background-blocks.md`, `./firm-background-gaps.md` (Phase 2)
- `./eligibility-report.md`, `./eligibility-decision-required.md`, `./eligibility-decision.md` (Phase 3)
- `./rfp-sections-<expert>.md` (Phase 4, per expert with assignments)
- `./drafts/<expert>-<section>.md`, `./drafts/<expert>-flags.md` (Phase 5)
- `./rfp-draft.md` (Phase 6, modified through 7-8)
- `./review-report.md` (Phase 7)
- `./cross-verify-report.md`, `./codex-critique.md` (Phase 8)
- `./taste-gate.md`, `./taste-gate-cleared.md` (Phase 9)
- `./rfp-submission.md`, `./rfp-audit-<ts>.md`, `./rfp-orchestrator-state.json` (Phase 10)
