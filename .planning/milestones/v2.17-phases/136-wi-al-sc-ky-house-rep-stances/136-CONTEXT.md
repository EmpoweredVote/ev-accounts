# Phase 136: WI + AL + SC + KY House Rep Stances - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; verbatim repeat of the proven FL/NY/PA/IL/OH/NC/GA/MI/NJ/WA/AZ/TN/CO/MN/MO pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **28 in-scope US House reps** in Wisconsin (8), Alabama (7), South Carolina (7), and Kentucky (6) — the fifth wave of v2.17 (Tier 2 continuation), covering USHS-10. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. Pure scale-out of the v2.16 pipeline (phases 127–135); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {55 WI, 1 AL, 45 SC, 21 KY}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`. Roster verified 2026-06-19: all 28 reps confirmed `ans=0`.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–135)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Reuse the current per-batch `_TOPIC_SCALE.txt` (verified live 2026-06-19); every research agent Reads it.
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard, VoteSmart. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **isidewith.com is BELOW the evidence bar** — DROP any row sourced ONLY by isidewith. AFA / candidate-completed voter-guide questionnaires ARE acceptable (candidate's own answers). Thin freshmen become honest-partials, auto-fill later.
- **Calibration discipline (Phase 135 lessons):** DROP over-read `same-sex-marriage=5` rows whose only evidence is "opposes legalization" / a religious-exemption (service-refusal) bill / group-alignment — value-5 SSM = "make illegal" and needs a documented anti-recognition vote or direct quote. DROP topic rows that rest only on a vague "core value" listing. Caucus MEMBERSHIP with a published platform IS acceptable documentary evidence.
- **Resolve `politician_id` by external_id→UUID map, not by name**.

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV with a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **Add the explicit RFC-4180 CSV-escaping instruction to every agent prompt.**
- **CSV quote-repair: collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""` (3→2).** `_merge.ts` uses `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`/`relax_column_count`.
- **Stray-trailing-quote artifact:** if csv-parse throws "Invalid Closing Quote", fix per-file with `sed -i 's/,"$/,/'` (a line ending `,"` is the artifact).

### DB push
- Push via the external_id-keyed `_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- **`_push.ts` does NOT load dotenv** — run pushes with `set -a && source .env && set +a && node --import tsx .../_push.ts <csv>`. Verify scripts use `import 'dotenv/config'`.
- **Verify the no-scope-creep invariant via PER-SCOPE external_id counts** (push is external_id-keyed so writes are provably isolated) — NOT the global `politician_answers` row counter (no `created_at`; drifts from concurrent prod cron/FEC jobs). Confirm each batch's in-scope reps reach their exact counts and unsourced-in-scope = 0.
- **Standing user decision this milestone:** auto-push batches that merge 0-problems AND 0-unsourced (still show the STEP 3 summary), no per-batch approval pause.

### Plan structure (mirrors phases 132–135) — 8 plans, all wave 1, mutually independent
- `136-01` — WI batch A: WI-1..WI-4 (external_id −55001..−55004, 4 reps) → `wi-house-a/`
- `136-02` — WI batch B: WI-5..WI-8 (external_id −55005..−55008, 4 reps) → `wi-house-b/`
- `136-03` — AL batch A: AL-1..AL-4 (external_id −1001..−1004, 4 reps) → `al-house-a/`
- `136-04` — AL batch B: AL-5..AL-7 (external_id −1005..−1007, 3 reps) → `al-house-b/`
- `136-05` — SC batch A: SC-1..SC-4 (external_id −45001..−45004, 4 reps) → `sc-house-a/`
- `136-06` — SC batch B: SC-5..SC-7 (external_id −45005..−45007, 3 reps) → `sc-house-b/`
- `136-07` — KY batch A: KY-1..KY-3 (external_id −21001..−21003, 3 reps) → `ky-house-a/`
- `136-08` — KY batch B: KY-4..KY-6 (external_id −21004..−21006, 3 reps) → `ky-house-b/`

### Claude's Discretion
- Exact batch boundaries — but keep each push batch ≤ ~7 reps (proven cadence).
- Dated CSV filenames (e.g. `2026-06-19-wi-house-batch-a.csv`).
- Per-rep source selection within the five-chairs framing.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution, approval, DB push, five-chairs framing
- `.planning/phases/135-tn-co-mn-mo-house-rep-stances/135-01-PLAN.md` — exact plan template to mirror (batch-A shape)
- `.planning/phases/135-tn-co-mn-mo-house-rep-stances/135-08-SUMMARY.md` + `135-VERIFICATION.md` — most recent validated playbook + calibration lessons
- `backend/data/stance-research/mo-house-a/_merge.ts` — latest merge+repair (sed-clone OUT + IN_SCOPE per batch)
- `backend/data/stance-research/mo-house-a/_push.ts` — reusable external_id-keyed push
- `backend/data/stance-research/mo-house-a/_TOPIC_SCALE.txt` — current 25-topic scale file (copy to each batch dir)

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)
</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-19 — all ans=0)

### Wisconsin (state_fips 55) — 8 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −55001 | WI-1 | Bryan Steil | | −55005 | WI-5 | Scott Fitzgerald |
| −55002 | WI-2 | Mark Pocan | | −55006 | WI-6 | Glenn Grothman |
| −55003 | WI-3 | Derrick Van Orden | | −55007 | WI-7 | Thomas Tiffany |
| −55004 | WI-4 | Gwen Moore | | −55008 | WI-8 | Tony Wied |

### Alabama (state_fips 1) — 7 reps (single-thousands external_id range)
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −1001 | AL-1 | Barry Moore | | −1005 | AL-5 | Dale Strong |
| −1002 | AL-2 | Shomari Figures | | −1006 | AL-6 | Gary Palmer |
| −1003 | AL-3 | Mike Rogers | | −1007 | AL-7 | Terri Sewell |
| −1004 | AL-4 | Robert Aderholt | | | | |

### South Carolina (state_fips 45) — 7 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −45001 | SC-1 | Nancy Mace | | −45005 | SC-5 | Ralph Norman |
| −45002 | SC-2 | Joe Wilson | | −45006 | SC-6 | James Clyburn |
| −45003 | SC-3 | Sheri Biggs | | −45007 | SC-7 | Russell Fry |
| −45004 | SC-4 | William Timmons | | | | |

### Kentucky (state_fips 21) — 6 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −21001 | KY-1 | James Comer | | −21004 | KY-4 | Thomas Massie |
| −21002 | KY-2 | Brett Guthrie | | −21005 | KY-5 | Harold Rogers |
| −21003 | KY-3 | Morgan McGarvey | | −21006 | KY-6 | Garland (Andy) Barr |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only. Expected thin records / honest-partials: **Shomari Figures AL-2** (2024 freshman, new district), **Sheri Biggs SC-3** (2024 freshman), **Tony Wied WI-8** (2024 special-election freshman). Document the actual record — never infer from party. Note KY-6 "Garland Barr" = longtime Rep. Andy Barr (in office since 2013, NOT a freshman).)
</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining reps in the other states — phases 137–139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).
</deferred>

---

*Phase: 136-wi-al-sc-ky-house-rep-stances*
*Context gathered: 2026-06-19 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
