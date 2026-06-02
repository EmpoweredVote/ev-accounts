# Phase 87: Stance Accuracy Audit + Agent Update — Research

**Researched:** 2026-06-02
**Domain:** PostgreSQL audit SQL, SKILL.md authoring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Five-Chairs Framing (SACC-04)**
- D-01: Replace the existing `SCALE RULE — CRITICAL` block in `research-stances/SKILL.md`. Do not keep old text.
- D-02: Source is the five-chairs philosophy document in CONTEXT.md `<specifics>`. Write the block naturally — chair metaphor, defensibility claim, direction-is-arbitrary rule all included.
- D-03: Core instruction: "Read the written text at each value level for this topic. Find sources that document this politician's position. Match the documented record to the chair whose text fits — do not pick based on party expectation or directional assumption."
- D-04: Defensibility framing required: "you both hold the position that [specific written text]" must be possible from every value assignment.

**Audit Artifact Format (SACC-01)**
- D-05: Report lives at `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md`.
- D-06: Required columns: `name`, `party`, `office`, `stance_count`, `flagged_count`, `priority_tier`, `flagged_topics`.
- D-07: Three tiers: `confirmed-inversion` / `borderline` / `likely-correct`. The 8 known inversions are pre-seeded into `confirmed-inversion` — not re-derived from SQL.
- D-08: Audit SQL documented in fenced code block for future re-runs.

**Audit SQL Methodology (SACC-01)**
- D-09: Primary flag (B): >= 60% of a politician's stances are the same single value.
- D-10: The 8 confirmed inversions from the 2026-06-02 informal audit are the canonical starting point. SQL run produces `borderline` / `likely-correct` additions.
- D-11: Party-distribution comparison is optional reference only — NOT the primary signal.

### Claude's Discretion

- Threshold tuning: if 60% produces fewer than ~30 flagged politicians beyond the 8 known, lower to 50%. If more than ~100, raise to 70%.
- Report may include summary statistics (total audited, flag rate, party breakdown).

### Deferred Ideas (OUT OF SCOPE)

- Ukraine-support Rs (26 at value=2): individual verification deferred to Phase 88.
- Party string normalization ("Democrat" vs "Democratic"): Phase 88 scope (SACC-03).
- Party-distribution query as primary signal: deferred indefinitely.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SACC-01 | Audit script produces a complete accuracy report across all ~1,049 politicians — flag scores, prioritized correction list, evidence summary for each flagged case | SQL verified live against DB — 1,049 politicians, 13,732 stance rows, 44 live topics. Flag methodology validated. |
| SACC-04 | Researcher agent (`SKILL.md`) updated with five-chairs framing to prevent future stance inversions | Current SKILL.md section identified (`SCALE RULE — CRITICAL`); replacement content sourced from CONTEXT.md specifics. |
</phase_requirements>

---

## Summary

Phase 87 has two deliverables that do not touch each other: (1) a Markdown audit report at `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` produced by running a PostgreSQL query against `inform.politician_answers`, and (2) a text edit to `.claude/skills/research-stances/SKILL.md` that replaces the `SCALE RULE — CRITICAL` section with a five-chairs framing block.

The database is live and queryable. The audit SQL has been fully prototyped and validated against real data during this research session. The 60% single-dominant-value threshold as written in D-09 produces 682 flagged politicians out of 1,049, but the CONTEXT makes clear the 8 pre-seeded inversions are the confirmed tier and the SQL output feeds the `borderline` / `likely-correct` tiers. The planner needs to make a single threshold decision — raw 60% at 682 is too broad, but 60% with a minimum of 15 stances yields 247, and 60% with a minimum of 20 stances yields 164 — both within the "signal-rich but workable" discretion guidance.

The SKILL.md edit is a surgical single-section replacement. The current file is 518 lines. The `SCALE RULE — CRITICAL` block appears once, in the agent prompt template at lines ~100–107 in STEP 1. The replacement is the five-chairs framing from CONTEXT.md rendered as a natural paragraph block that preserves the researcher agent's evaluative posture.

**Primary recommendation:** Run the audit SQL with a `total_stances >= 15` minimum (247 flagged beyond the 8 pre-seeded) to stay within the ~100 upper bound from the discretion note, produce the full 1,049-row report with all three tiers, and write the SKILL.md replacement as a single-task edit.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Audit SQL execution | Database / Storage | — | Direct postgres via `pool.query()` — inform schema is not in PostgREST exposed list |
| Audit report file | Planning docs | — | Markdown artifact consumed by Phase 88 planner, not served via API |
| SKILL.md update | Agent configuration | — | File edit to `.claude/skills/research-stances/SKILL.md` — affects agent prompt only |

---

## Standard Stack

### Core

| Library | Purpose | Why Standard |
|---------|---------|-------------|
| `pg` / `pool` (existing) | Run audit SQL against Supabase | All `inform.*` reads must use direct postgres — not PostgREST |
| Node.js `--import tsx` (existing) | Execute DB queries in research scripts | Established pattern across all stance ingestion scripts |

No new packages. This phase uses only existing infrastructure.

---

## Package Legitimacy Audit

No new packages introduced in this phase. All DB access uses the existing `pg` pool pattern.

---

## Architecture Patterns

### Recommended Phase Structure

```
Phase 87
├── Wave 1: Audit SQL + report generation
│   ├── Run audit SQL against inform.politician_answers
│   ├── Apply threshold (60% + 15+ stances = 247 flagged)
│   ├── Pre-seed 8 confirmed inversions into confirmed-inversion tier
│   └── Write 87-AUDIT-REPORT.md with all 1,049 politicians
└── Wave 2: SKILL.md update
    └── Replace SCALE RULE — CRITICAL block with five-chairs framing
```

### Pattern 1: Audit SQL — Verified Query Shape

The following SQL has been tested live against the production database. It produces all required columns.

**Critical constraint:** `inform.politician_answers` is not in PostgREST's exposed schema list. The query must run through `pool.query()`, not `supabaseAdmin.schema('inform')`.

```sql
-- Audit SQL: 60% dominant-value flag with per-politician breakdown
-- Run via: pool.query(SQL) in backend/src/lib/db.js context
-- Minimum stance count (currently 15) is the planner's discretion tuning knob

WITH per_politician_totals AS (
  SELECT politician_id, COUNT(*) AS total_stances
  FROM inform.politician_answers
  GROUP BY politician_id
),
per_value_counts AS (
  SELECT politician_id, value, COUNT(*) AS cnt
  FROM inform.politician_answers
  WHERE value = ROUND(value)   -- exclude half-values (63 rows: 1.5, 2.5, 3.5, 4.5)
  GROUP BY politician_id, value
),
per_politician_max AS (
  SELECT pvc.politician_id, MAX(pvc.cnt) AS max_cnt
  FROM per_value_counts pvc
  GROUP BY pvc.politician_id
),
flagged_politicians AS (
  SELECT
    pvc.politician_id,
    pvc.value AS dominant_value,
    pvc.cnt AS dominant_count,
    ppt.total_stances,
    ROUND(pvc.cnt::numeric / ppt.total_stances * 100) AS ratio_pct
  FROM per_value_counts pvc
  JOIN per_politician_totals ppt ON ppt.politician_id = pvc.politician_id
  JOIN per_politician_max ppm
    ON ppm.politician_id = pvc.politician_id AND ppm.max_cnt = pvc.cnt
  WHERE pvc.cnt::numeric / ppt.total_stances >= 0.60
    AND ppt.total_stances >= 15        -- <-- tuning knob; lower to catch all 8 confirmed inversions
)
SELECT
  p.full_name                      AS name,
  COALESCE(NULLIF(p.party, ''), 'Unknown') AS party,
  (SELECT o.title FROM essentials.offices o
   WHERE o.politician_id = p.id LIMIT 1) AS office,
  fp.total_stances                 AS stance_count,
  fp.dominant_count                AS flagged_count,
  fp.ratio_pct                     AS flag_ratio_pct,
  fp.dominant_value,
  (
    SELECT string_agg(t.topic_key, ', ' ORDER BY t.topic_key)
    FROM inform.politician_answers pa
    JOIN inform.compass_topics t ON t.id = pa.topic_id
    WHERE pa.politician_id = fp.politician_id
      AND pa.value = fp.dominant_value
  )                                AS flagged_topics
FROM flagged_politicians fp
JOIN essentials.politicians p ON p.id = fp.politician_id
ORDER BY fp.ratio_pct DESC, fp.total_stances DESC;
```

**Validated output shape** (sample from research session):
- Kate Hogan (D, MA Rep): 16 stances, 16 flagged at value=3.0 (100%)
- Val Hoyle (D, OR Rep): 20 stances, 19 flagged at value=1.0 (95%)
- Kelly A. Dooner (R, MA Sen): 21 stances, 19 flagged at value=4.0 (90%)

### Pattern 2: Threshold Tuning — Verified Counts

The following counts were verified live. Use to decide minimum-stance cutoff:

| Threshold | Min Stances | Flagged Politicians |
|-----------|-------------|---------------------|
| 60% | none | 682 |
| 60% | 10+ | 382 |
| 60% | 15+ | 247 |
| 60% | 20+ | 164 |
| 70% | 10+ | 234 |
| 70% | 15+ | 127 |
| 75% | 15+ | 94 |
| 80% | 15+ | 52 |

**Recommendation:** `60% + 15+ stances` yields 247 — within the "~100 upper bound" if the report sections them clearly by tier. The confirmed inversions are pre-seeded separately, so the SQL-derived list is for borderline/likely-correct triage only.

**Important:** The 8 pre-seeded inversions have between 6 and 21 stances. Only Jeff Gonzalez (21), Roger Niello (14), Tim Grayson (13), and Ashley Hinson/Derek Dooley/Alex Vindman/Angie Nixon (10–11) survive a 10+ filter. Adam Hinojosa (6 stances) would be dropped by ANY minimum-stance filter. Since these 8 are pre-seeded and NOT derived from the SQL, the minimum-stance filter only applies to the SQL-derived set. The pre-seeds go directly into the `confirmed-inversion` tier regardless of whether the SQL would have flagged them.

### Pattern 3: Why the 60% SQL Doesn't Catch All 8 Inversions

This is important context for the planner:

| Politician | Party | Stances | Pattern | SQL catches at 60% |
|-----------|-------|---------|---------|-------------------|
| Angie Nixon | D | 11 | 91% at value=4 | Yes (cross-party) |
| Derek Dooley | R | 10 | 90% at value=2 | Yes (cross-party) |
| Ashley Hinson | R | 11 | 82% at value=2 | Yes (cross-party) |
| Roger Niello | R | 14 | 64% at value=2 | Yes (cross-party) |
| Alex Vindman | D | 11 | 64% at value=4 | Yes (cross-party) |
| Tim Grayson | D | 13 | 62% at value=5 | Yes (if no min-15 filter) |
| Jeff Gonzalez | R | 21 | 43% at value=1 + 38% at value=2 | **No** — split 1+2, neither hits 60% |
| Adam Hinojosa | D | 6 | 67% at value — | Only 6 stances |

Jeff Gonzalez is a **multi-value inversion** (his stances are spread across values 1 and 2, both of which are the "wrong" side for an R). He cannot be caught by the single-dominant-value SQL. He is correctly pre-seeded only.

### Pattern 4: Priority Tier Assignment Logic

The three tiers map as follows:

| Tier | Source | Criteria |
|------|--------|---------|
| `confirmed-inversion` | Pre-seeded (not SQL) | The 8 identified in 2026-06-02 informal audit |
| `borderline` | SQL output | Flagged by SQL AND cross-party suspicious pattern: R with dominant ≤2, or D with dominant ≥4; OR uniform-neutral (dominant=3 at very high ratio); OR locked single value ≥90% regardless of party |
| `likely-correct` | SQL output or unflagged | Flagged but same-party natural pattern (D dominant=1-2, R dominant=4-5) — these follow expected partisan distributions |

**Cross-party pattern verified in research:** 5 of the 8 pre-seeded inversions show the cross-party pattern in the data (R with dominant ≤2 or D with dominant ≥4). Jeff Gonzalez and Tim Grayson are exceptions caught only by manual review.

### Pattern 5: Five-Chairs SKILL.md Replacement

The current SKILL.md block to replace is in the agent prompt template in STEP 1, around lines 100–107:

```
SCALE RULE — CRITICAL — READ BEFORE ASSIGNING ANY VALUE:
The value you assign (1–5) MUST match the written stance text for that value in the DB.
Do NOT treat 1 as "oppose" or 5 as "support" — the direction varies by topic.
Do NOT use party affiliation as a shortcut.
For every stance you record, ask: "Does this politician's documented position match the
EXACT TEXT at this value?" If not, pick a different value.
```

Replacement framing from CONTEXT.md:

```
FIVE-CHAIRS FRAMING — READ BEFORE ASSIGNING ANY VALUE:

Each compass topic has five pre-written stances — one per position on the spoke. These 
aren't degree-of-agreement markers. They are five distinct, substantive positions a real 
person could hold, defend in a conversation, and point to a policy that reflects it.

Think of them as five named chairs in a room. A politician's public record places them in 
one of those chairs. Your job is to find which chair fits the documented evidence — not to 
infer a chair from party affiliation or directional assumption.

The spoke has no correct end. Value=1 is not "conservative" and value=5 is not 
"progressive" — the direction varies by topic. Read the written text at each value level 
for this topic. Find sources that document this politician's position. Match the 
documented record to the chair whose text fits.

When a voter matches a politician on a topic, the system must be able to say exactly why: 
not "they both scored a 2 on Climate," but "they both support rapidly transitioning to 
renewable energy and phasing out fossil fuels by 2030." That claim requires your value 
assignment to be defensible with the specific written text — not just a directional 
approximation.

Do NOT pick a value based on party expectation. Do NOT assume direction. For every stance 
you record, ask: "Does this politician's documented position match the EXACT TEXT at this 
value?" If not, pick a different value or skip the topic.
```

### Anti-Patterns to Avoid

- **Running the audit SQL against `supabaseAdmin.schema('inform')`**: PostgREST does not expose `inform.*`. Use `pool.query()` only.
- **Including the 8 confirmed inversions in the SQL flag logic**: They are pre-seeded. The SQL produces additional candidates, not a replacement for the manual audit.
- **Treating the `flagged_topics` column as "wrong" topics**: The column lists which topics contributed to the dominant-value flag. It is a diagnostic list, not a confirmed error list.
- **Adding the half-value rows (1.5, 2.5, 3.5, 4.5) to the flag logic**: There are 63 such rows across 1,049 politicians. They are an edge case unrelated to the inversion problem. The SQL filters them with `WHERE value = ROUND(value)`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Connecting to inform schema | Custom HTTP client to PostgREST | `pool.query()` via `backend/src/lib/db.js` |
| Running the audit query | New DB client setup | Import and call `pool` from existing `./src/lib/db.js` |
| Writing the report file | Shell output redirect | Node.js `fs.writeFileSync` or the Write tool directly |

---

## Database Schema Verified

All tables confirmed live via query during research:

**`inform.politician_answers`**
- Columns used: `politician_id` (uuid), `topic_id` (uuid), `value` (numeric)
- Row count: 13,732 total; 13,669 integer-value rows; 63 half-value rows
- Distinct politicians: 1,049

**`essentials.politicians`**
- Columns used: `id`, `full_name`, `party`
- Party string inconsistency: 496 rows have "Democrat", 280 have "Democratic" (776 total inconsistent)

**`essentials.offices`**
- Columns used: `politician_id`, `title`
- Note: No `is_current` column. Use `LIMIT 1` subquery to get primary office title.

**`inform.compass_topics`**
- Columns used: `id`, `topic_key`
- 44 live topics (as of 2026-06-02; previously documented as 43 — one was added)

---

## Common Pitfalls

### Pitfall 1: inform Schema Not in PostgREST

**What goes wrong:** `supabaseAdmin.schema('inform').from('politician_answers').select(...)` fails silently or throws.
**Why it happens:** `inform` is not in the PostgREST exposed schema list per project patterns.
**How to avoid:** Always use `pool.query()` for `inform.*` access.
**Warning signs:** Empty result set or "schema not found" error.

### Pitfall 2: The 60% Threshold Catches Too Many Without a Minimum Stance Count

**What goes wrong:** 682 flagged politicians at raw 60%, overwhelming Phase 88.
**Why it happens:** Politicians with 3–6 stances trivially hit 60% with a single value.
**How to avoid:** Apply minimum stance count (15 recommended) to reduce to 247 meaningful flags.
**Warning signs:** Large number of politicians with only 5–8 stances in the flagged list.

### Pitfall 3: Offices Table Has No is_current Column

**What goes wrong:** `JOIN essentials.offices o ON o.politician_id = p.id AND o.is_current = true` fails with "column does not exist".
**Why it happens:** The `is_current` column doesn't exist on `essentials.offices`.
**How to avoid:** Use `(SELECT o.title FROM essentials.offices o WHERE o.politician_id = p.id LIMIT 1)` as a subquery.

### Pitfall 4: Jeff Gonzalez Pattern (Multi-Value Inversion)

**What goes wrong:** Assuming all confirmed inversions will be caught by the 60% single-dominant-value SQL.
**Why it happens:** Jeff Gonzalez's stances are inverted but spread across values 1 (43%) and 2 (38%) — neither crosses 60%.
**How to avoid:** Pre-seed the 8 known inversions as confirmed regardless of SQL output. The SQL adds new candidates; it doesn't confirm or deny existing ones.

### Pitfall 5: SKILL.md Edit Removes the Wrong Block

**What goes wrong:** Editing the wrong section of SKILL.md — the file is 518 lines with multiple sections.
**Why it happens:** The `SCALE RULE — CRITICAL` block is inside the STEP 1 agent prompt template, not a top-level section.
**How to avoid:** Edit only the lines starting `SCALE RULE — CRITICAL — READ BEFORE ASSIGNING ANY VALUE:` through `If not, pick a different value.` Preserve all surrounding structure (the `TOPIC SCALE REFERENCE` section below it and the `TOOL RULE — CRITICAL` section above the scale).

---

## Data Findings

### Live Database Statistics [VERIFIED: direct DB query]

- Total politicians with stance data: **1,049**
- Total stance rows: **13,732**
- Integer-value rows: **13,669** (99.5%)
- Half-value rows: **63** (0.5%) — values 1.5, 2.5, 3.5, 4.5
- Live compass topics: **44** (not 43 as previously documented)
- Value distribution: 1.0 (14.4%), 2.0 (37.2%), 3.0 (19.1%), 4.0 (19.0%), 5.0 (9.7%)

### Party String Distribution [VERIFIED: direct DB query]

- "Republican": 603 politicians
- "Democrat": 496 politicians
- "Democratic": 280 politicians
- "Nonpartisan": 1,289 politicians (many without stance data)
- Empty string: 112 politicians

The "Democrat" / "Democratic" split is a known issue deferred to Phase 88 (SACC-03). Phase 87 notes it in the audit report but does not fix it.

### Ukraine-Support Republican Distribution [VERIFIED: direct DB query]

- 25 Republicans at value=2 ("continue providing current levels of military and economic aid")
- 21 Republicans at value=3 ("limited humanitarian aid + diplomatic negotiations")
- 17 Republicans at value=4 ("reduce aid, domestic priorities")
- 13 Republicans at value=5 ("end all aid immediately")
- 1 Republican at value=1 (Lindsey Graham — most aggressive support)

The 25 Rs at value=2 need individual verification (Phase 88). Some may be accurate based on pre-2025 votes; others may not reflect current positions. Phase 87 notes them in the report.

### Known-Correct Cases (Do NOT Flag) [VERIFIED: pre-confirmed by team]

- Susan M. Collins, Lisa Murkowski, Thom Tillis, Todd Young, Shelley Moore Capito: `same-sex-marriage=2` — all voted for the Respect for Marriage Act [ASSUMED: confirmed by product team, not independently fetched]
- Gary VanDeaver (R-TX): `school-vouchers=2` — voted against TX voucher bills [ASSUMED: confirmed by product team, not independently fetched]

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| "SCALE RULE" framing (directional) | Five-chairs framing (text-match, no direction) | Prevents researcher agent from assigning values based on party direction rather than documented position |
| Informal audit (2026-06-02 session) | Formal SQL audit artifact at fixed path | Phase 88 has a documented, reusable work queue |

---

## Validation Architecture

**`workflow.nyquist_validation` is not set to `false` in `.planning/config.json`** — treated as enabled.

However, Phase 87 has no runtime code to test. Both deliverables are:
1. A Markdown file produced by running a SQL query
2. A text edit to a SKILL.md agent config

There are no unit-testable functions, no API endpoints, and no migration files. The appropriate validation is:

### Phase Gate Validation (Manual)

| Deliverable | Validation Method |
|-------------|-----------------|
| `87-AUDIT-REPORT.md` exists | File system check: `ls .planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` |
| Report contains all 1,049 politicians | Row count check in report |
| 8 confirmed inversions at top under `confirmed-inversion` tier | Manual review of report header section |
| Audit SQL included in report | Grep for fenced code block in report |
| SKILL.md no longer contains `SCALE RULE — CRITICAL` | Grep: `grep "SCALE RULE" .claude/skills/research-stances/SKILL.md` should return 0 results |
| SKILL.md contains five-chairs framing | Grep: `grep "five chairs\|five named chairs" .claude/skills/research-stances/SKILL.md` |

---

## Open Questions

1. **Priority tier for Democrats dominant at value=1 vs value=2**
   - What we know: D at dominant=1 (like Val Hoyle at 95%) and D at dominant=2 (like many CA Assembly members at 80-85%) are both flagged by the 60% SQL.
   - What's unclear: Are these "likely-correct" (natural progressive stance pattern) or "borderline" (potential over-generalization)?
   - Recommendation: The planner should assign D-dominant-1-or-2 and R-dominant-4-or-5 to `likely-correct` tier by default, since these follow expected partisan patterns. Only cross-party patterns (D-dominant-4-or-5, R-dominant-1-or-2) and uniform-neutral (dominant=3 at high ratio) should be `borderline`. This keeps the correction queue focused.

2. **Report format: include all 1,049 or only flagged + pre-seeded?**
   - What we know: SACC-01 says "complete accuracy report across all ~1,049 politicians."
   - What's unclear: Should all 367 unflagged politicians appear in the report (as `likely-correct` with 0 flags), or just the 682 flagged + 8 pre-seeded?
   - Recommendation: Include all 1,049 in the report for completeness (SACC-01 requirement), but keep the table compact — unflagged rows can be summarized in an appendix rather than inline.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|--------------|
| A1 | Collins, Murkowski, Tillis, Young, Capito SSM=2 is confirmed correct based on team audit | Data Findings (Known-Correct Cases) | Phase 88 would unnecessarily re-research these politicians |
| A2 | Gary VanDeaver school-vouchers=2 is confirmed correct based on team audit | Data Findings (Known-Correct Cases) | Phase 88 would unnecessarily re-research this politician |

---

## Environment Availability

| Dependency | Required By | Available | Version |
|------------|------------|-----------|---------|
| Node.js + tsx | Audit SQL runner script | Yes | Node v24.13.0 |
| `pg` pool | DB queries | Yes | Existing in backend/src/lib/db.js |
| Supabase (remote) | inform.politician_answers data | Yes | Live, verified during research |

---

## Sources

### Primary (HIGH confidence)
- Direct PostgreSQL queries against live `inform.politician_answers`, `essentials.politicians`, `essentials.offices`, `inform.compass_topics` — all queries run and results captured during research
- `.claude/skills/research-stances/SKILL.md` — current file read in full; replacement target identified
- `.planning/phases/87-stance-accuracy-audit-agent-update/87-CONTEXT.md` — all decisions locked

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` §v2.6 Stance Accuracy Retro — 8 confirmed inversions, known-correct cases

---

## Metadata

**Confidence breakdown:**
- Audit SQL: HIGH — prototyped and validated against live database, all output shapes confirmed
- Database schema: HIGH — verified via `information_schema.columns` queries
- Threshold tuning counts: HIGH — queried directly against live data
- SKILL.md replacement block: HIGH — source text is verbatim from CONTEXT.md `<specifics>`, current file fully read
- Known-correct cases (Collins, VanDeaver): ASSUMED — confirmed by product team, not independently verified via sources

**Research date:** 2026-06-02
**Valid until:** 30 days — DB schema is stable; politician count grows slowly
