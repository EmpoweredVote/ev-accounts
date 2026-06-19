# Phase 135: TN + CO + MN + MO House Rep Stances - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; verbatim repeat of the proven FL/NY/PA/IL/OH/NC/GA/MI/NJ/WA/AZ pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **33 in-scope US House reps** in Tennessee (9), Colorado (8), Minnesota (8), and Missouri (8) — the fourth wave of v2.17 (Tier 2 continuation), covering USHS-09. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. Pure scale-out of the v2.16 pipeline (phases 127–134); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {47 TN, 8 CO, 27 MN, 29 MO}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`. Roster verified 2026-06-19: all 33 reps confirmed `ans=0`.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–134)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Fetch live topics FRESH at run time; write the formatted 1–5 scale to a per-batch `_TOPIC_SCALE.txt`; every research agent Reads it.
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard, VoteSmart. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **isidewith.com is BELOW the evidence bar** — DROP any row sourced ONLY by isidewith. AFA / candidate-completed voter-guide questionnaires ARE acceptable (candidate's own answers). Thin freshmen become honest-partials, auto-fill later.
- **Resolve `politician_id` by external_id→UUID map, not by name**.

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV with a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **Add the explicit RFC-4180 CSV-escaping instruction to every agent prompt.** Apply the canonical re-parse(`relax_column_count`)/re-stringify repair before merge.
- **CSV quote-repair: collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""` (3→2).** Use `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`.
- **Stray-trailing-quote artifact (Phase 134 lesson):** agents sometimes append a lone trailing `"` to the empty final field on every row → csv-parse "Invalid Closing Quote". Fix per-file with `sed -i 's/,"$/,/'` (a line ending `,"` is always the artifact; valid empty final field ends `,`). DISTINCT from the quad-quote artifact `_merge.ts` already repairs.

### DB push
- Push via the external_id-keyed `_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- **Verify the no-scope-creep invariant via PER-SCOPE external_id counts** (push is external_id-keyed so writes are provably isolated) — NOT the global `politician_answers` row counter, which drifts from concurrent prod cron/FEC jobs (`politician_answers` has no `created_at`). Confirm each batch's in-scope reps reach their exact counts and unsourced-in-scope = 0.
- **Mid-run MCP Supabase tokens expire (~1h)** — fall back to `node --import tsx` + `pool` from `backend/src/lib/db.ts` (load `dotenv/config` first) for verification queries.

### Plan structure (mirrors phases 132/133/134) — 8 plans, all wave 1, mutually independent
- `135-01` — TN batch A: TN-1..TN-5 (external_id −47001..−47005, 5 reps) → `tn-house-a/`
- `135-02` — TN batch B: TN-6..TN-9 (external_id −47006..−47009, 4 reps) → `tn-house-b/`
- `135-03` — CO batch A: CO-1..CO-4 (external_id −8001..−8004, 4 reps) → `co-house-a/`
- `135-04` — CO batch B: CO-5..CO-8 (external_id −8005..−8008, 4 reps) → `co-house-b/`
- `135-05` — MN batch A: MN-1..MN-4 (external_id −27001..−27004, 4 reps) → `mn-house-a/`
- `135-06` — MN batch B: MN-5..MN-8 (external_id −27005..−27008, 4 reps) → `mn-house-b/`
- `135-07` — MO batch A: MO-1..MO-4 (external_id −29001..−29004, 4 reps) → `mo-house-a/`
- `135-08` — MO batch B: MO-5..MO-8 (external_id −29005..−29008, 4 reps) → `mo-house-b/`

### Claude's Discretion
- Exact batch boundaries — but keep each push batch ≤ ~7 reps (proven cadence).
- Dated CSV filenames (e.g. `2026-06-19-tn-house-batch-a.csv`).
- Per-rep source selection within the five-chairs framing.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution, approval, DB push, five-chairs framing
- `.planning/phases/134-nj-wa-az-house-rep-stances/134-01-PLAN.md` — exact plan template to mirror (batch-A shape)
- `.planning/phases/134-nj-wa-az-house-rep-stances/134-06-SUMMARY.md` — most recent validated playbook + isolation-invariant + stray-trailing-quote + AFA/isidewith lessons
- `backend/data/stance-research/az-house-a/_merge.ts` — latest merge+repair (sed-clone OUT + IN_SCOPE per batch); else `ga-house-a/_merge.ts`
- `backend/data/stance-research/pa-house-a/_push.ts` — reusable external_id-keyed push
- `backend/data/stance-research/ga-house-a/_TOPIC_SCALE.txt` — current 25-topic scale file (copy to each batch dir)

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)
</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-19 — all ans=0)

### Tennessee (state_fips 47) — 9 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −47001 | TN-1 | Diana Harshbarger | | −47006 | TN-6 | John Rose |
| −47002 | TN-2 | Tim Burchett | | −47007 | TN-7 | Matt Van Epps |
| −47003 | TN-3 | Charles Fleischmann | | −47008 | TN-8 | David Kustoff |
| −47004 | TN-4 | Scott DesJarlais | | −47009 | TN-9 | Steve Cohen |
| −47005 | TN-5 | Andrew Ogles | | | | |

### Colorado (state_fips 8) — 8 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −8001 | CO-1 | Diana DeGette | | −8005 | CO-5 | Jeff Crank |
| −8002 | CO-2 | Joe Neguse | | −8006 | CO-6 | Jason Crow |
| −8003 | CO-3 | Jeff Hurd | | −8007 | CO-7 | Brittany Pettersen |
| −8004 | CO-4 | Lauren Boebert | | −8008 | CO-8 | Gabe Evans |

### Minnesota (state_fips 27) — 8 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −27001 | MN-1 | Brad Finstad | | −27005 | MN-5 | Ilhan Omar |
| −27002 | MN-2 | Angie Craig | | −27006 | MN-6 | Tom Emmer |
| −27003 | MN-3 | Kelly Morrison | | −27007 | MN-7 | Michelle Fischbach |
| −27004 | MN-4 | Betty McCollum | | −27008 | MN-8 | Pete Stauber |

### Missouri (state_fips 29) — 8 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −29001 | MO-1 | Wesley Bell | | −29005 | MO-5 | Emanuel Cleaver |
| −29002 | MO-2 | Ann Wagner | | −29006 | MO-6 | Sam Graves |
| −29003 | MO-3 | Robert Onder | | −29007 | MO-7 | Eric Burlison |
| −29004 | MO-4 | Mark Alford | | −29008 | MO-8 | Jason Smith |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only. Expected thin records / honest-partials: **Matt Van Epps TN-7** (2025 special-election freshman), **Jeff Hurd CO-3 / Jeff Crank CO-5 / Gabe Evans CO-8** (2024 freshmen), **Kelly Morrison MN-3**, **Wesley Bell MO-1 / Robert Onder MO-3** (2024 freshmen). Document the actual record — never infer from party.)
</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining reps in the other states — phases 136–139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).
</deferred>

---

*Phase: 135-tn-co-mn-mo-house-rep-stances*
*Context gathered: 2026-06-19 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
