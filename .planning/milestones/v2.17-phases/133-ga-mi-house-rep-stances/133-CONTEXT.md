# Phase 133: GA + MI House Rep Stances - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; this phase is a verbatim repeat of the proven FL/NY/PA/IL/OH/NC pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **26 in-scope US House reps** in Georgia (13) and Michigan (13) — the second wave of v2.17 (Tier 2 continuation), covering USHS-07. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. This is a pure scale-out of the v2.16 pipeline (phases 127–132); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {13 GA, 26 MI}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–132)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Fetch live topics FRESH at run time; write the formatted 1–5 scale to a per-batch `_TOPIC_SCALE.txt`; every research agent Reads it (token-efficient, satisfies the embed-fresh-scale-texts rule).
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **isidewith.com is BELOW the evidence bar** (132 lesson): its candidate "positions" are aggregator characterizations, not documented votes/statements/scorecards. DROP any row sourced ONLY by isidewith (no ballotpedia/wikipedia/ontheissues/lcv/votesmart/.gov backing); thin freshmen become honest-partials, auto-fill later.
- **Resolve `politician_id` by external_id→UUID map, not by name** (name variants break name matching).

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV using a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **Add the explicit RFC-4180 CSV-escaping instruction to every agent prompt.** Apply the canonical re-parse(`relax_column_count`)/re-stringify repair step before merge to absorb escaping artifacts.
- **CSV quote-repair (132 lesson, critical): collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""` (3→2).** Agents emit valid `"""quote"""` (literal-quoted field) and the 3→2 collapse corrupts it. `_merge.ts` uses `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`.

### DB push
- Push via the reusable external_id-keyed pattern in `backend/data/stance-research/pa-house-a/_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both `inform.politician_answers` and `inform.politician_context`; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- Quotes pushed to `essentials.quotes` with Read & Rank selection.
- After push: stance counts for all politicians OTHER than the in-scope reps must be unchanged.

### Plan structure (mirrors phases 129/132)
Split each state into two batches by district number → **4 plans, all wave 1, mutually independent**:
- `133-01` — GA batch A: GA-1..GA-7 (external_id −13001..−13007, 7 reps) → `backend/data/stance-research/ga-house-a/`
- `133-02` — GA batch B: GA-8..GA-12, GA-14 (external_id −13008..−13012, −13014, 6 reps) → `ga-house-b/`
- `133-03` — MI batch A: MI-1..MI-7 (external_id −26001..−26007, 7 reps) → `mi-house-a/`
- `133-04` — MI batch B: MI-8..MI-13 (external_id −26008..−26013, 6 reps) → `mi-house-b/`

### Claude's Discretion
- Exact batch boundaries — but keep each push batch ≤ ~9 reps (proven cadence).
- Dated CSV filenames (e.g. `2026-06-19-ga-house-batch-a.csv`).
- Per-rep source selection within the five-chairs framing.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution (STEP 1/2), approval (STEP 3), DB push (STEP 4), five-chairs framing
- `.planning/phases/132-oh-nc-house-rep-stances/132-01-PLAN.md` — exact plan template to mirror (batch-A shape)
- `.planning/phases/132-oh-nc-house-rep-stances/132-04-SUMMARY.md` — most recent validated playbook + isidewith / CSV-escaping lessons
- `backend/data/stance-research/pa-house-a/_push.ts` — reusable external_id-keyed push (answers+context+quotes, leak-check)
- `backend/data/stance-research/nc-house-b/_merge.ts` — latest merge+repair (4→3 quote collapse, relax_quotes)
- `backend/data/stance-research/pa-house-a/_TOPIC_SCALE.txt` — format example for the per-batch scale file

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)
</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-19)

### Georgia (state_fips 13) — 13 reps
| external_id | district | name |
|-------------|----------|------|
| −13001 | GA-1 | Earl Carter |
| −13002 | GA-2 | Sanford Bishop |
| −13003 | GA-3 | Brian Jack |
| −13004 | GA-4 | Henry Johnson |
| −13005 | GA-5 | Nikema Williams |
| −13006 | GA-6 | Lucy McBath |
| −13007 | GA-7 | Rich McCormick |
| −13008 | GA-8 | Austin Scott |
| −13009 | GA-9 | Andrew Clyde |
| −13010 | GA-10 | Mike Collins |
| −13011 | GA-11 | Barry Loudermilk |
| −13012 | GA-12 | Rick Allen |
| −13014 | GA-14 | Clay Fuller |

(GA-13 is out of scope — not in the 0-answer in-scope set.)

### Michigan (state_fips 26) — 13 reps
| external_id | district | name |
|-------------|----------|------|
| −26001 | MI-1 | Jack Bergman |
| −26002 | MI-2 | John Moolenaar |
| −26003 | MI-3 | Hillary Scholten |
| −26004 | MI-4 | Bill Huizenga |
| −26005 | MI-5 | Tim Walberg |
| −26006 | MI-6 | Debbie Dingell |
| −26007 | MI-7 | Tom Barrett |
| −26008 | MI-8 | Kristen McDonald Rivet |
| −26009 | MI-9 | Lisa McClain |
| −26010 | MI-10 | John James |
| −26011 | MI-11 | Haley Stevens |
| −26012 | MI-12 | Rashida Tlaib |
| −26013 | MI-13 | Shri Thanedar |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only.)
</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining reps in the other 34 states — phases 134–139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).
</deferred>

---

*Phase: 133-ga-mi-house-rep-stances*
*Context gathered: 2026-06-19 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
