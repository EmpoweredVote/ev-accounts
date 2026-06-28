# Phase 137: LA + CT + IN + OK + AR + IA House Rep Stances - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; verbatim repeat of the proven phases 127–136 pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **29 in-scope US House reps** in Louisiana (6), Connecticut (5), Indiana (5 in-scope), Oklahoma (5), Arkansas (4), and Iowa (4) — the sixth wave of v2.17 (Tier 2 continuation), covering USHS-11. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. Pure scale-out of the v2.16 pipeline (phases 127–136); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {22 LA, 9 CT, 18 IN, 40 OK, 5 AR, 19 IA}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`. Roster verified 2026-06-19: all 29 reps confirmed `ans=0`.

**NOTE — Indiana is non-contiguous:** in-scope IN = exactly {−18001, −18002, −18003, −18005, −18006} (IN-1,2,3,5,6). IN-4 (−18004) and IN-7/8/9 are NOT in scope (already have answers or unseeded). The IN merge IN_SCOPE set must list these 5 explicitly — do NOT use a −18001..−18006 contiguous range.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–136)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Reuse the current per-batch `_TOPIC_SCALE.txt` (verified live 2026-06-19); every research agent Reads it.
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard, VoteSmart. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **isidewith.com is BELOW the evidence bar** — DROP any row sourced ONLY by isidewith. AFA / candidate-completed voter-guide questionnaires ARE acceptable. Thin freshmen / source-blocked reps become honest-partials, auto-fill later.
- **SSM=5 calibration discipline (phases 135–136, 6 drops):** `same-sex-marriage=5` ("make illegal") requires a documented anti-recognition vote OR explicit support for a one-man-one-woman constitutional amendment. KEEP when backed by Federal Marriage Amendment / state constitutional-amendment votes or explicit pro-amendment + Obergefell-opposition. DROP when the only evidence is Equality Act opposition / "opposes special LGBTQ protections" / "opposes legalization" / a religious-exemption service-refusal bill. (Equality-Act opposition alone IS still valid for religious-freedom=4/5 — it's about exemptions.) Apply the same "no vague-listing → topic" discipline to all topics.
- **Resolve `politician_id` by external_id→UUID map, not by name**.

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV with a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **CSV quote-repair: collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""`.** `_merge.ts` uses `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`/`relax_column_count`. Stray-trailing-quote artifact → `sed -i 's/,"$/,/'`.

### DB push
- Push via the external_id-keyed `_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- **`_push.ts` does NOT load dotenv** — run pushes with `set -a && source .env && set +a && node --import tsx <dir>/_push.ts <csv>`. Verify scripts use `import 'dotenv/config'`.
- **Verify the no-scope-creep invariant via PER-SCOPE external_id counts** (push is external_id-keyed; writes are provably isolated) — NOT the global `politician_answers` counter (no `created_at`; drifts). Confirm each batch's in-scope reps reach exact counts and unsourced-in-scope = 0.
- **Standing user decision this milestone:** auto-push batches that merge 0-problems AND 0-unsourced (still show the STEP 3 summary), no per-batch approval pause.

### Plan structure (clean per-state batching) — 6 plans, all wave 1, mutually independent
- `137-01` — LA: LA-1..LA-6 (external_id −22001..−22006, 6 reps) → `la-house/`
- `137-02` — CT: CT-1..CT-5 (external_id −9001..−9005, 5 reps) → `ct-house/`
- `137-03` — IN: IN-1,2,3,5,6 (external_id −18001,−18002,−18003,−18005,−18006, 5 reps — NON-CONTIGUOUS) → `in-house/`
- `137-04` — OK: OK-1..OK-5 (external_id −40001..−40005, 5 reps) → `ok-house/`
- `137-05` — AR: AR-1..AR-4 (external_id −5001..−5004, 4 reps — single-thousands range) → `ar-house/`
- `137-06` — IA: IA-1..IA-4 (external_id −19001..−19004, 4 reps) → `ia-house/`

### Claude's Discretion
- Dated CSV filenames (e.g. `2026-06-19-la-house.csv`).
- Per-rep source selection within the five-chairs framing.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution, approval, DB push, five-chairs framing
- `.planning/phases/136-wi-al-sc-ky-house-rep-stances/136-01-PLAN.md` — exact plan template to mirror
- `.planning/phases/136-wi-al-sc-ky-house-rep-stances/136-08-SUMMARY.md` + `136-VERIFICATION.md` — most recent validated playbook + SSM calibration lessons
- `backend/data/stance-research/ky-house-a/_merge.ts` — latest merge+repair (sed-clone OUT + IN_SCOPE per batch)
- `backend/data/stance-research/ky-house-a/_push.ts` — reusable external_id-keyed push
- `backend/data/stance-research/ky-house-a/_TOPIC_SCALE.txt` — current 25-topic scale file (copy to each batch dir)

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)
</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-19 — all ans=0)

### Louisiana (state_fips 22) — 6 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −22001 | LA-1 | Steve Scalise (Majority Leader) | | −22004 | LA-4 | Mike Johnson (Speaker) |
| −22002 | LA-2 | Troy Carter (D) | | −22005 | LA-5 | Julia Letlow |
| −22003 | LA-3 | Clay Higgins | | −22006 | LA-6 | Cleo Fields (D) |

### Connecticut (state_fips 9) — 5 reps (all Democrats)
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −9001 | CT-1 | John Larson | | −9004 | CT-4 | James Himes |
| −9002 | CT-2 | Joe Courtney | | −9005 | CT-5 | Jahana Hayes |
| −9003 | CT-3 | Rosa DeLauro | | | | |

### Indiana (state_fips 18) — 5 reps (NON-CONTIGUOUS)
| ext_id | dist | name |
|--------|------|------|
| −18001 | IN-1 | Frank Mrvan (D) |
| −18002 | IN-2 | Rudy Yakym |
| −18003 | IN-3 | Marlin Stutzman |
| −18005 | IN-5 | Victoria Spartz |
| −18006 | IN-6 | Jefferson Shreve |

### Oklahoma (state_fips 40) — 5 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −40001 | OK-1 | Kevin Hern | | −40004 | OK-4 | Tom Cole |
| −40002 | OK-2 | Josh Brecheen | | −40005 | OK-5 | Stephanie Bice |
| −40003 | OK-3 | Frank Lucas | | | | |

### Arkansas (state_fips 5) — 4 reps (single-thousands range)
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −5001 | AR-1 | Eric "Rick" Crawford | | −5003 | AR-3 | Steve Womack |
| −5002 | AR-2 | French Hill (J. Hill) | | −5004 | AR-4 | Bruce Westerman |

### Iowa (state_fips 19) — 4 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −19001 | IA-1 | Mariannette Miller-Meeks | | −19003 | IA-3 | Zach Nunn |
| −19002 | IA-2 | Ashley Hinson | | −19004 | IA-4 | Randy Feenstra |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only. Expected thin records / honest-partials: **Cleo Fields LA-6** (2024 freshman in new district, though served in Congress in the 1990s — his prior record exists), **Jefferson Shreve IN-6** (2024 freshman). **Marlin Stutzman IN-3** returned to the House in 2025 after prior 2010–2017 service — his older record is documentable. Document the actual record — never infer from party.)
</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining reps in the other states — phases 138–139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).
</deferred>

---

*Phase: 137-la-ct-in-ok-ar-ia-house-rep-stances*
*Context gathered: 2026-06-19 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
