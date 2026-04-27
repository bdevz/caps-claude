# Onboarding — Consultadd RFP Skills

Welcome. You're about to set up Claude as a smart RFP coworker that knows how Consultadd writes proposals. After ~15 minutes of one-time setup, you'll be able to take an RFP PDF and run `/rfp` to draft a full response, with checkpoints where you (the human) make the important calls.

You don't need to be technical. Just follow the numbered steps.

---

## Before You Start — Checklist

You need these on your Mac. If anything is missing, ping #rfp-tools in Slack and someone will help.

- [ ] **Claude Code app** installed (download from claude.ai/code)
- [ ] **Conductor app** installed (download from conductor.build)
- [ ] **You're signed into Claude** in Claude Code with your Consultadd account
- [ ] **You have access to** the `consultadd-rfp` skills repo (ask in #rfp-tools if you can't clone it yet)

---

## One-Time Setup (~10 minutes)

Do this once. It installs the skills so Claude knows how to do RFP work the Consultadd way.

### Step 1 — Open Terminal

Press `Cmd+Space`, type `Terminal`, press Enter. A black-and-white window opens. That's it.

### Step 2 — Clone the repo

Copy this line, paste it into Terminal, press Enter:

```bash
cd ~ && git clone <REPO-URL> consultadd-rfp
```

> Ask in #rfp-tools for the actual `<REPO-URL>` to paste in.

You'll see a few lines of output. When the prompt comes back, you're done.

### Step 3 — Run the installer

Copy this, paste, Enter:

```bash
cd ~/consultadd-rfp && ./setup
```

You'll see a list like `linked parse-rfp`, `linked firm-background`, etc. — that's good. It means each skill is now hooked into Claude Code.

### Step 4 — Set your telemetry name

This tags your work so the dashboard shows you're being productive. Copy, paste, Enter (replace `Your Name` with your actual name):

```bash
echo 'export CONSULTADD_ANALYST_ID="Your Name"' >> ~/.zshrc
```

> If you got telemetry credentials from your team lead, also paste these lines (with your real values):
>
> ```bash
> echo 'export CONSULTADD_TEL_ENDPOINT="<from team lead>"' >> ~/.zshrc
> echo 'export CONSULTADD_TEL_KEY="<from team lead>"' >> ~/.zshrc
> ```
>
> If you didn't get those values yet, skip them — skills will still work, you just won't appear on the dashboard until you add them later.

### Step 5 — Restart Claude Code

Quit Claude Code (Cmd+Q), reopen it. The skills are now ready.

You're done with setup. **You only do this once.**

---

## Your First RFP

This is the everyday workflow. Plan ~30-60 minutes for your first run; you'll get faster.

### Step 1 — Start a Conductor workspace

Open Conductor. Click "New Workspace". Give it a name like `acme-rfp-2026-april`. Conductor creates a folder for this RFP and opens a Claude Code session inside it.

### Step 2 — Drop the RFP PDF into the workspace

Drag the RFP PDF from your Downloads into the Conductor workspace folder. Or save it to the workspace folder directly. Note the file name — you'll reference it next.

### Step 3 — Run /rfp

In the Claude Code chat, type:

```
/rfp parse and draft from <pdf-filename>.pdf
```

Hit Enter. Now Claude does the heavy lifting:

- Parses the PDF
- Pulls Consultadd's firm boilerplate from the knowledge files
- Checks if we're eligible to bid
- Splits the RFP into sections
- Dispatches specialist sub-experts (tech, legal, ops, sales-marketing, public-policy) in parallel
- Polishes the draft
- Reviews it internally
- Cross-checks it with a fresh second opinion

You'll see progress messages. **It will pause at two checkpoints.** That's where you come in.

### Checkpoint 1 — Eligibility (CHALLENGE GATE)

After eligibility check, if there are any qualification gaps, Claude will stop and tell you:

> Eligibility check complete. Recommendation: MITIGATABLE. 2 gaps require your decision (see ./eligibility-decision-required.md). Resolve and create `./eligibility-decision.md`, then run `/rfp --resume` to continue.

**What to do:**

1. Open `./eligibility-decision-required.md` in the workspace. It lists each gap and suggests options (partner with prime, sub-vendor, teaming agreement, etc.).
2. For each gap, decide what you want to do.
3. Create a new file `./eligibility-decision.md` and write your decision in plain English. Example:

   ```
   Gap: HUBZone certification — DECISION: team with Acme Corp as prime; we sub.
   Gap: Section 508 capability — DECISION: confirmed, our team has done this on the DOT engagement; proceed as prime.
   ```

4. Type `/rfp --resume` in chat. Claude continues.

> If the recommendation is NO-BID and you agree — stop here and tell your team lead. Don't draft a bid you can't deliver on.

### Checkpoint 2 — Pre-submission Taste Gate

After the draft is fully assembled and reviewed, Claude will pause again:

> Taste gate ready. Review ./taste-gate.md, edit ./rfp-draft.md if needed, then create ./taste-gate-cleared.md to finish.

**What to do:**

1. Open `./taste-gate.md`. It lists every claim, number, or commitment that needs your eyes — pricing, capability claims, attestations, key-personnel assignments, anything where Claude wasn't 100% confident.
2. For each item, either:
   - **Confirm** it — fact is right, leave it
   - **Edit** `./rfp-draft.md` directly to fix it
   - **Replace** it — write the right answer into the draft
3. When you're satisfied with the whole draft, create a file `./taste-gate-cleared.md` with anything in it (just a confirmation):

   ```
   Reviewed and approved by Your Name on 2026-04-27.
   ```

4. Claude finishes the stitch and produces `./rfp-submission.md` (your final document) plus `./rfp-audit-<timestamp>.md` (the trail of what happened).

### Step 4 — Submit

Open `./rfp-submission.md`. Copy it into the agency's submission portal (or convert to PDF if they want PDF). **You always submit manually** — Claude never submits for you.

---

## What Each Slash Command Does (Cheat Sheet)

You can run any of these one at a time if you don't want the full pipeline:

| Command | What it does |
|---|---|
| `/rfp` | Full pipeline, end-to-end |
| `/parse-rfp` | Just convert a PDF to clean text |
| `/firm-background` | Just inject Consultadd boilerplate |
| `/eligibility-check` | Just run the qualification check |
| `/tech-expert` | Draft just the technical sections |
| `/legal-expert` | Draft just the legal sections |
| `/ops-expert` | Draft just the project-management sections |
| `/sales-mktg-expert` | Draft just the executive summary / win themes |
| `/public-policy-expert` | Draft just the policy-aligned sections |
| `/writer` | Polish and unify drafts into one document |
| `/reviewer` | Internal QA pass |
| `/cross-verify` | Independent second-opinion review |

---

## When Something Goes Wrong

### "Claude doesn't recognize /rfp"

Skills aren't installed or Claude Code wasn't restarted. Run setup again:

```bash
cd ~/consultadd-rfp && ./setup
```

Then quit Claude Code (Cmd+Q) and reopen.

### "PDF parsing failed"

The PDF might be image-only or oddly structured. Two options:
1. Tell Claude: "use the vision fallback" — it will OCR with Claude vision
2. Ask the agency for a text version of the RFP

### "Knowledge files are empty / Claude says it can't find facts"

The `knowledge/*.md` files at `~/consultadd-rfp/knowledge/` need to be populated by the knowledge DRI before skills produce ship-ready content. If your DRI hasn't filled them yet, Claude will write a `firm-background-gaps.md` listing what's missing — pass that to your team lead.

### "Eligibility check is taking forever"

It's a Challenge Gate — it's WAITING for you. Look for `./eligibility-decision-required.md` in your workspace and follow the steps in Checkpoint 1.

### "I made a mistake at the Taste gate"

Just edit `./rfp-draft.md` directly and re-create `./taste-gate-cleared.md`. You can iterate as many times as you want before submission.

### Anything else

Post in #rfp-tools with: what you tried, what error you saw, and a screenshot. Someone will help within the day.

---

## Where to Get Help

- **Slack:** #rfp-tools (technical setup, slash commands, errors)
- **Slack:** #rfp-content (knowledge file gaps, capability statements, past-win citations)
- **Team lead:** for eligibility judgment calls, no-bid decisions, pricing
- **Legal:** for high-severity MSA deltas surfaced at the Challenge Gate

You're never expected to make these calls alone. The whole point of the gates is to make sure the right human makes the right call.

---

## What's Different About This vs. ChatGPT-then-Claude

You used to: download PDF → put in team project → ask ChatGPT to cross-check → polish in Claude. That worked but had three problems: 10% of PDFs failed to parse, you typed firm background every time, and there was no consistency across team members.

This new flow: same Claude you're used to, but it now knows Consultadd. It pulls firm background from approved files instead of asking you to retype it. It catches eligibility gaps before you waste time drafting an unwinnable bid. And it gives you ONE document to review at the end instead of five tools to coordinate.

The trade: you spend a few minutes at the eligibility and taste gates instead of in scattered chat windows. The win: more consistent, faster, fewer hallucinations slipping through.
