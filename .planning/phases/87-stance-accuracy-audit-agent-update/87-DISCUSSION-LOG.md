# Phase 87: Stance Accuracy Audit + Agent Update — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 87-stance-accuracy-audit-agent-update
**Areas discussed:** Five-chairs framing, Audit artifact format + home, Audit SQL methodology

---

## Five-Chairs Framing

| Option | Description | Selected |
|--------|-------------|----------|
| Replace SCALE RULE with five-chairs block | Rewrite the section as a five-chairs philosophy block using the chair metaphor front and center | ✓ |
| Keep SCALE RULE, add five-chairs block above it | Belt-and-suspenders — preserve existing rule, add philosophy block before it | |
| Add five-chairs as worked example per topic | Include a worked example showing reasoning process for one topic | |

**User's choice:** Replace the existing SCALE RULE with a new five-chairs block

**Source for block content:**
User provided the full five-chairs philosophy document in session. Key concepts:
- Five named positions ("chairs"), not a degree-of-agreement dial
- The scale has no partisan direction — the chart can be visually flipped; value=1 is not conservative, value=5 is not progressive
- The unit of comparison is the written position text, not the number — matches are defensible because you can cite the specific stance text + source
- Core agent instruction: find sources, match documented record to the chair whose text fits, do not pick based on party expectation

**Notes:** User emphasized the defensibility angle: "That's what makes the compass something we can stand behind when anyone asks how a match was made." The five-chairs document shared in session is the canonical source; planner writes the block naturally from it.

**SKILL.md emphasis decision:**
"You decide — use the document I provided as the source and write the block naturally."

---

## Audit Artifact Format + Home

| Option | Description | Selected |
|--------|-------------|----------|
| .planning/phases/87-*/87-AUDIT-REPORT.md | Markdown in planning hierarchy; Phase 88 planner finds it directly | ✓ |
| data/stance-accuracy/2026-06-XX-audit.md | In the data dir alongside stance CSVs | |
| STATE.md update only | Append to Accumulated Context section | |

**User's choice:** `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md`

**Table columns:**
| Option | Description | Selected |
|--------|-------------|----------|
| name, party, office, stance_count, flagged_count, priority_tier, flagged_topics | Enough for Phase 88 to know who to re-research, in what order, on which topics | ✓ |
| Full stance breakdown — every topic + value per politician | Much larger artifact | |
| Summary only — name + tier + flag count | Minimal; Phase 88 wouldn't know which topics triggered flags | |

**Notes:** Three priority tiers: `confirmed-inversion` / `borderline` / `likely-correct`. Audit SQL documented in the report for future re-runs. 8 confirmed inversions pre-seeded into `confirmed-inversion` tier at top of report.

---

## Audit SQL Methodology

**Initial question asked for clarification** — user asked for a better explanation of the options. Claude explained:
- Option A: party-distribution comparison (statistical outlier vs. party median per topic)
- Option B: low-variance flag (catches all-N-values lazy research)
- Option C: formalize existing findings (the 2026-06-02 informal audit is the canonical list)

| Option | Description | Selected |
|--------|-------------|----------|
| Party-distribution comparison (A) | Flag politicians whose values deviate from their party's per-topic median | Optional exploration only |
| Low-variance flag (B) | Flag politicians where >= 60% of stances are the same single value | ✓ Primary |
| Formalize existing findings (C) | 2026-06-02 informal audit findings are the baseline | ✓ Baseline |

**User's choice:** "Can we do B and C? I'm ok with A as an exploration, but it assumes party preference in a way that I don't want to lean on."

**Threshold decision:**
>= 60% of stances at the same single value (e.g., 18+ of 30 topics all at value=4).

**Notes:** Using party distributions as the primary flag would encode the same partisan directional assumption that five-chairs framing rejects — the audit should catch data problems without importing political assumptions into the methodology. Party-distribution query may be included in the report as a documented optional tool only.

**Low-variance threshold:** >= 60% of stances at same single value. Planner may tune: lower to 50% if < ~30 flags beyond known 8 inversions; raise to 70% if > ~100 flags.

---

## Claude's Discretion

- Threshold tuning for low-variance flag (planner adjusts based on result count)
- Report sectioning beyond required columns (summary stats if useful)

## Deferred Ideas

- **Ukraine-support Rs (26 at value=2):** Phase 88 scope — individual verification with source citation
- **Party string normalization ("Democrat" vs "Democratic"):** Phase 88 scope (SACC-03)
- **Party-distribution query as primary signal:** Deferred indefinitely — conflicts with five-chairs philosophy
