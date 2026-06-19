# Phase 134: NJ + WA + AZ House Rep Stances - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; verbatim repeat of the proven FL/NY/PA/IL/OH/NC/GA/MI pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **31 in-scope US House reps** in New Jersey (12), Washington (10), and Arizona (9) — the third wave of v2.17 (Tier 2 continuation), covering USHS-08. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. Pure scale-out of the v2.16 pipeline (phases 127–133); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {34 NJ, 53 WA, 4 AZ}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–133)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Fetch live topics FRESH at run time; write the formatted 1–5 scale to a per-batch `_TOPIC_SCALE.txt`; every research agent Reads it.
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard, VoteSmart. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **isidewith.com is BELOW the evidence bar** — DROP any row sourced ONLY by isidewith. AFA / candidate-completed voter-guide questionnaires ARE acceptable (candidate's own answers). Thin freshmen become honest-partials, auto-fill later.
- **Resolve `politician_id` by external_id→UUID map, not by name**.

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV with a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **Add the explicit RFC-4180 CSV-escaping instruction to every agent prompt.** Apply the canonical re-parse(`relax_column_count`)/re-stringify repair before merge.
- **CSV quote-repair: collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""` (3→2).** Use `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`.

### DB push
- Push via the external_id-keyed `_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- **Verify the no-scope-creep invariant via PER-SCOPE external_id counts** (push is external_id-keyed so writes are provably isolated) — NOT the global `politician_answers` row counter, which drifts from concurrent prod cron/FEC jobs (`politician_answers` has no `created_at`). Confirm each batch's in-scope reps reach their exact counts and unsourced-in-scope = 0.

### Plan structure (mirrors phases 132/133) — 6 plans, all wave 1, mutually independent
- `134-01` — NJ batch A: NJ-1..NJ-6 (external_id −34001..−34006, 6 reps) → `nj-house-a/`
- `134-02` — NJ batch B: NJ-7..NJ-12 (external_id −34007..−34012, 6 reps) → `nj-house-b/`
- `134-03` — WA batch A: WA-1..WA-5 (external_id −53001..−53005, 5 reps) → `wa-house-a/`
- `134-04` — WA batch B: WA-6..WA-10 (external_id −53006..−53010, 5 reps) → `wa-house-b/`
- `134-05` — AZ batch A: AZ-1..AZ-5 (external_id −4001..−4005, 5 reps) → `az-house-a/`
- `134-06` — AZ batch B: AZ-6..AZ-9 (external_id −4006..−4009, 4 reps) → `az-house-b/`

### Claude's Discretion
- Exact batch boundaries — but keep each push batch ≤ ~7 reps (proven cadence).
- Dated CSV filenames (e.g. `2026-06-19-nj-house-batch-a.csv`).
- Per-rep source selection within the five-chairs framing.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution, approval, DB push, five-chairs framing
- `.planning/phases/133-ga-mi-house-rep-stances/133-01-PLAN.md` — exact plan template to mirror (batch-A shape)
- `.planning/phases/133-ga-mi-house-rep-stances/133-04-SUMMARY.md` — most recent validated playbook + isolation-invariant + AFA/isidewith lessons
- `backend/data/stance-research/ga-house-a/_merge.ts` — latest merge+repair (sed-clone OUT + IN_SCOPE per batch)
- `backend/data/stance-research/pa-house-a/_push.ts` — reusable external_id-keyed push
- `backend/data/stance-research/ga-house-a/_TOPIC_SCALE.txt` — current 25-topic scale file (copy to each batch dir)

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)
</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-19)

### New Jersey (state_fips 34) — 12 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −34001 | NJ-1 | Donald Norcross | | −34007 | NJ-7 | Thomas Kean Jr. |
| −34002 | NJ-2 | Jefferson Van Drew | | −34008 | NJ-8 | Robert Menendez |
| −34003 | NJ-3 | Herbert Conaway | | −34009 | NJ-9 | Nellie Pou |
| −34004 | NJ-4 | Christopher Smith | | −34010 | NJ-10 | LaMonica McIver |
| −34005 | NJ-5 | Josh Gottheimer | | −34011 | NJ-11 | Analilia Mejia |
| −34006 | NJ-6 | Frank Pallone | | −34012 | NJ-12 | Bonnie Watson Coleman |

### Washington (state_fips 53) — 10 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −53001 | WA-1 | Suzan DelBene | | −53006 | WA-6 | Emily Randall |
| −53002 | WA-2 | Rick Larsen | | −53007 | WA-7 | Pramila Jayapal |
| −53003 | WA-3 | Marie Gluesenkamp Perez | | −53008 | WA-8 | Kim Schrier |
| −53004 | WA-4 | Dan Newhouse | | −53009 | WA-9 | Adam Smith |
| −53005 | WA-5 | Michael Baumgartner | | −53010 | WA-10 | Marilyn Strickland |

### Arizona (state_fips 4) — 9 reps
| ext_id | dist | name |
|--------|------|------|
| −4001 | AZ-1 | David Schweikert |
| −4002 | AZ-2 | Eli Crane |
| −4003 | AZ-3 | Yassamin Ansari |
| −4004 | AZ-4 | Greg Stanton |
| −4005 | AZ-5 | Andy Biggs |
| −4006 | AZ-6 | Juan Ciscomani |
| −4007 | AZ-7 | Adelita Grijalva |
| −4008 | AZ-8 | Abraham Hamadeh |
| −4009 | AZ-9 | Paul Gosar |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only. AZ-3 Ansari, AZ-7 Grijalva, AZ-8 Hamadeh are 2024/2025 freshmen — expect thinner records / honest-partials.)
</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining reps in the other 31 states — phases 135–139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).
</deferred>

---

*Phase: 134-nj-wa-az-house-rep-stances*
*Context gathered: 2026-06-19 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
