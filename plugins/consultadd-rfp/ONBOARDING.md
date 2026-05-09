# Onboarding — Consultadd RFP Skills (claude.ai)

Welcome. You're about to get a Claude RFP coworker that already knows how Consultadd writes proposals. There's no install — your Claude Team admin pushes the skills to your account automatically. Setup takes about 60 seconds. Then you can take an RFP PDF and run `/rfp` to draft a full response, with checkpoints where you (the human) make the important calls.

You don't need to be technical. Just follow the numbered steps.

---

## Before You Start — Checklist

- [ ] You're signed in at **[claude.ai](https://claude.ai)** (web) or have the **Claude Desktop** app
- [ ] You're logged in with your **Consultadd Claude Team account**
- [ ] You've heard from the admin (Jason / `#rfp-tools`) that the `consultadd-rfp` plugin has been pushed to the team

If any of those aren't true, ping `#rfp-tools` in Slack — someone will help.

---

## One-Time Setup (~60 seconds)

### Step 1 — Verify the plugin is installed

In claude.ai, click your profile → **Customize** → **Skills**.

You should see a section labeled **Team skills** (or similar) with `consultadd-rfp` listed and toggled on. The skills `parse-rfp`, `firm-background`, `eligibility-check`, `rfp`, and the specialists should all be visible.

If you don't see them, the admin hasn't pushed yet — ping `#rfp-tools`.

### Step 2 — That's it

There's no Terminal, no clone, no API keys to paste. The plugin auto-syncs from the team's GitHub. When the admin merges a change to `main`, you'll get the update within minutes — no action needed on your end.

---

## Your First RFP

This is the everyday workflow. Plan ~15-30 minutes for your first run; you'll get faster.

### Step 1 — Start a new chat in claude.ai

Open claude.ai. Click "New chat".

### Step 2 — Upload the RFP PDF

Click the paperclip / upload icon in the chat input. Pick your RFP PDF from Downloads. Wait for it to finish uploading (you'll see the file attached above the input box).

### Step 3 — Run `/rfp`

Type:

```
/rfp build the proposal from the attached RFP
```

Hit Enter. Now Claude does the heavy lifting:

- Parses the PDF using Claude's native PDF reader
- Pulls Consultadd's firm boilerplate from the knowledge files
- Checks if we're eligible to bid
- Splits the RFP into sections
- Runs through specialist experts (tech, legal, ops, sales-marketing, public-policy) one by one
- Polishes the draft
- Reviews it internally
- Cross-checks with a fresh second opinion

You'll see Claude's progress in chat. **It will pause at two checkpoints.** That's where you come in.

### Checkpoint 1 — Eligibility (CHALLENGE GATE)

After the eligibility check, if there are any qualification gaps, Claude will stop and tell you something like:

> Eligibility check complete. Recommendation: MITIGATABLE. 2 gaps require your decision. For each gap, decide: confirm a mitigation (partnership / sub-vendor / teaming / license rental), accept the risk, or no-bid. Write your decisions in plain English to `./eligibility-decision.md`. When ready, say "continue /rfp".

**What to do:**

1. Look at the eligibility report Claude shared in chat. It lists each gap and suggests options.
2. For each gap, decide what you want to do.
3. Reply in chat with your decisions in plain English. Example:

   > Gap: HUBZone certification — DECISION: team with Acme Corp as prime; we sub.
   > Gap: Section 508 capability — DECISION: confirmed, we did this on the DOT engagement; proceed as prime.

4. Say "continue /rfp". Claude resumes from Phase 4.

> If the recommendation is **NO-BID** and you agree — stop here. Tell your team lead. Don't draft a bid you can't deliver on.

### Checkpoint 2 — Pre-submission Taste / Challenge Gate

After the draft is fully assembled and reviewed, Claude will pause again:

> Pre-submission review ready. The taste-gate report lists every claim, number, or commitment that needs your eyes. For each item, confirm, edit the draft directly in our chat, or replace it. When you're satisfied, say "finalize /rfp".

**What to do:**

1. Read the taste-gate report Claude shared. It lists every spot Claude wasn't 100% sure about — pricing, capability claims, attestations, key-personnel assignments.
2. For each item, either:
   - **Confirm** it — fact is right, leave it
   - **Edit it** — tell Claude the correction in chat, e.g., "change the 8 FTE estimate to 12"
   - **Replace it** — write the right answer
3. When the whole draft is right, say:

   > Reviewed and approved. Finalize /rfp.

4. Claude finishes the stitch and produces the final RFP-submission document plus an audit-trail log.

### Step 4 — Submit

Claude gives you the final document in chat. Copy it, paste into the agency's submission portal (or convert to PDF if they want PDF). **You always submit manually** — Claude never auto-submits.

---

## Step-by-Step Mode (instead of `/rfp`)

If you'd rather drive each phase yourself, you can. Each skill stands alone:

| Step | Command | What it does |
|---|---|---|
| 1 | `/parse-rfp` | Read the uploaded PDF → structured markdown |
| 2 | `/firm-background` | Inject Consultadd boilerplate |
| 3 | `/eligibility-check` | Qualification check |
| 4 | `/tech-expert` | Draft technical sections |
| 5 | `/legal-expert` | Draft legal / MSA-response sections |
| 6 | `/ops-expert` | Draft PM / staffing / transition sections |
| 7 | `/sales-mktg-expert` | Draft executive summary, win themes |
| 8 | `/public-policy-expert` | Draft regulatory / equity / sustainability sections (gov RFPs only) |
| 9 | `/writer` | Polish + unify into one document |
| 10 | `/reviewer` | Internal QA pass |
| 11 | `/cross-verify` | Independent second-opinion review |

Step-by-step is slower but gives you more control. Use it for high-value RFPs where you want to inspect every phase.

---

## When Something Goes Wrong

### "I don't see the consultadd-rfp skills in claude.ai"

The admin hasn't pushed the marketplace yet, or your account isn't in the right Claude Team. Ping `#rfp-tools`.

### "PDF parsing didn't capture everything"

The PDF might be image-only or oddly structured. Tell Claude in chat: "the parsed content is missing the requirements section — can you re-extract from pages 14-22?" Claude will re-read those pages with extra attention. If still bad, ask the agency for a text version of the RFP.

### "Knowledge files are empty / Claude says it can't find facts"

The `_shared/knowledge/` files at the plugin root need to be populated by the knowledge DRI before skills produce ship-ready content. Claude will write a "gaps" file in chat listing what's missing — share that with your team lead.

### "Eligibility check stopped and I don't know what to do"

That's a Challenge Gate — Claude is waiting for your decision. Look at the eligibility report Claude shared, decide for each gap, and reply with your decisions in chat. Then say "continue /rfp".

### "I made a mistake at the taste gate"

Just tell Claude what to change. You can iterate as many times as you want before submission. The "finalize /rfp" trigger is the only commitment point — and even then, you submit to the agency manually.

### Anything else

Post in `#rfp-tools` with: what you tried, what Claude said, and a screenshot. Someone will help within the day.

---

## Where to Get Help

- **Slack `#rfp-tools`** — technical questions, slash commands, errors
- **Slack `#rfp-content`** — knowledge file gaps, capability statements, past-win citations
- **Team lead** — for eligibility judgment calls, no-bid decisions, pricing
- **Legal** — for high-severity MSA deltas surfaced at the Challenge Gate

You're never expected to make these calls alone. The whole point of the gates is to make sure the right human makes the right call.

---

## What's Different vs. the Old Workflow

You used to: download PDF → put in team project → ask ChatGPT to cross-check → polish in Claude. That worked but had three problems: 10% of PDFs failed to parse, you typed firm background every time, and there was no consistency across team members.

This new flow: same Claude you're used to, but it now knows Consultadd. It pulls firm background from approved files. It catches eligibility gaps before you waste time drafting an unwinnable bid. And it gives you ONE document to review at the end instead of five tools to coordinate.

The trade: you spend a few minutes at the eligibility and taste gates instead of in scattered chat windows. The win: more consistent, faster, fewer hallucinations slipping through.
