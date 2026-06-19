# Phase 132: OH + NC House Rep Stances - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16 methodology + production roster (web research skipped — milestone-level decision; this phase is a verbatim repeat of the proven FL/NY/PA/IL pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **29 in-scope US House reps** in Ohio (15) and North Carolina (14) — the first wave of v2.17 (Tier 2 continuation), covering USHS-06. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. This is a pure scale-out of the v2.16 pipeline (phases 127–131); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {39 OH, 37 NC}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–130)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Fetch live topics FRESH at run time; write the formatted 1–5 scale to a per-batch `_TOPIC_SCALE.txt`; every research agent Reads it (token-efficient, satisfies the embed-fresh-scale-texts rule).
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **Resolve `politician_id` by external_id→UUID map, not by name** (name variants like "Michael A. Rulli" / "Mike Carey" break name matching).

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV using a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **Add the explicit RFC-4180 CSV-escaping instruction to every agent prompt.** Apply the canonical re-parse(`relax_column_count`)/re-stringify repair step before merge to absorb escaping artifacts (quad-quotes `""""`, unwrapped quote/name fields, stray trailing commas) — 0-problem merges.

### DB push
- Push via the reusable external_id-keyed pattern in `backend/data/stance-research/pa-house-a/_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both `inform.politician_answers` and `inform.politician_context`; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- Quotes pushed to `essentials.quotes` with Read & Rank selection.
- After push: stance counts for all politicians OTHER than the in-scope reps must be unchanged.

### Plan structure (recommended — mirrors PA phase 129)
Split each state into two batches by district number → **4 plans, all wave 1, mutually independent**:
- `132-01` — OH batch A: OH-1..OH-8 (external_id −39001..−39008, 8 reps) → `backend/data/stance-research/oh-house-a/`
- `132-02` — OH batch B: OH-9..OH-15 (external_id −39009..−39015, 7 reps) → `oh-house-b/`
- `132-03` — NC batch A: NC-1..NC-7 (external_id −37001..−37007, 7 reps) → `nc-house-a/`
- `132-04` — NC batch B: NC-8..NC-14 (external_id −37008..−37014, 7 reps) → `nc-house-b/`

### Claude's Discretion
- Exact batch boundaries (2 plans per state vs. 1 per state) — but keep each push batch ≤ ~9 reps (proven cadence).
- Dated CSV filenames (e.g. `2026-06-18-oh-house-batch-a.csv`).
- Per-rep source selection within the five-chairs framing.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution (STEP 1/2), approval (STEP 3), DB push (STEP 4), five-chairs framing
- `.planning/phases/129-pa-house-rep-stances/129-01-PLAN.md` — exact plan template to mirror (batch-A shape)
- `.planning/phases/130-il-house-rep-stances/130-02-SUMMARY.md` — most recent validated playbook + escaping lessons
- `backend/data/stance-research/pa-house-a/_push.ts` — reusable external_id-keyed push (answers+context+quotes, leak-check)
- `backend/data/stance-research/pa-house-a/_TOPIC_SCALE.txt` — format example for the per-batch scale file

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)
</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-18)

### Ohio (state_fips 39) — 15 reps
| external_id | district | name |
|-------------|----------|------|
| −39001 | OH-1 | Greg Landsman |
| −39002 | OH-2 | David J. Taylor |
| −39003 | OH-3 | Joyce Beatty |
| −39004 | OH-4 | Jim Jordan |
| −39005 | OH-5 | Robert E. Latta |
| −39006 | OH-6 | Michael A. Rulli |
| −39007 | OH-7 | Max L. Miller |
| −39008 | OH-8 | Warren Davidson |
| −39009 | OH-9 | Marcy Kaptur |
| −39010 | OH-10 | Michael R. Turner |
| −39011 | OH-11 | Shontel M. Brown |
| −39012 | OH-12 | Troy Balderson |
| −39013 | OH-13 | Emilia Strong Sykes |
| −39014 | OH-14 | David P. Joyce |
| −39015 | OH-15 | Mike Carey |

### North Carolina (state_fips 37) — 14 reps
| external_id | district | name |
|-------------|----------|------|
| −37001 | NC-1 | Donald G. Davis |
| −37002 | NC-2 | Deborah K. Ross |
| −37003 | NC-3 | Gregory F. Murphy |
| −37004 | NC-4 | Valerie P. Foushee |
| −37005 | NC-5 | Virginia Foxx |
| −37006 | NC-6 | Addison P. McDowell |
| −37007 | NC-7 | David Rouzer |
| −37008 | NC-8 | Mark Harris |
| −37009 | NC-9 | Richard Hudson |
| −37010 | NC-10 | Pat Harrigan |
| −37011 | NC-11 | Chuck Edwards |
| −37012 | NC-12 | Alma S. Adams |
| −37013 | NC-13 | Brad Knott |
| −37014 | NC-14 | Tim Moore |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only.)
</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining 183 reps in the other 36 states — phases 133–139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).
</deferred>

---

*Phase: 132-oh-nc-house-rep-stances*
*Context gathered: 2026-06-18 (inline authoring from locked v2.16 methodology + production roster)*
