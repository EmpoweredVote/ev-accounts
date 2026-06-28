# Phase 138: KS + MS + NV + NE + NM House Rep Stances - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; verbatim repeat of the proven phases 127–137 pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **18 in-scope US House reps** in Kansas (4), Mississippi (4), Nevada (4), Nebraska (3), and New Mexico (3) — the seventh wave of v2.17 (Tier 2 continuation), covering USHS-12. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. Pure scale-out of the v2.16 pipeline (phases 127–137); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {20 KS, 28 MS, 32 NV, 31 NE, 35 NM}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`. Roster verified 2026-06-20: all 18 reps confirmed `has_answers=false` and **contiguous** within each state's external_id range (no non-contiguous gaps like Phase 137's Indiana).
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–137)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Reuse the current per-batch `_TOPIC_SCALE.txt` (copy from a Phase 137 batch dir, e.g. `ok-house/_TOPIC_SCALE.txt`); every research agent Reads it.
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **EFFICIENCY rule (Phase 137 lesson — bake into every agent prompt):** try each source URL ONCE; if it 403s/404s/times out, move on immediately — do NOT retry or loop. A single agent hung ~6.5 hours on a WebFetch stall in Phase 137; this rule kept all later agents to 1–5 min. Avoid co-dispatching where one long-tail agent blocks the whole wave's return.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard, VoteSmart. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch — do not rely on them.
- **isidewith.com is BELOW the evidence bar** — DROP any row sourced ONLY by isidewith. AFA / candidate-completed voter-guide questionnaires ARE acceptable. Thin freshmen / source-blocked reps become honest-partials, auto-fill later.
- **SSM=5 calibration discipline (phases 135–137, 8 drops):** `same-sex-marriage=5` ("make illegal") requires a documented anti-recognition vote OR explicit support for a one-man-one-woman constitutional amendment. KEEP when backed by Federal Marriage Amendment / state constitutional-amendment votes or explicit pro-amendment + Obergefell-opposition. DROP when the only evidence is Equality Act opposition / "opposes special LGBTQ protections" / "opposes legalization" / a religious-exemption service-refusal bill / a belief-quote alone. (Equality-Act opposition alone IS still valid for religious-freedom=4/5 — it's about exemptions.) Apply the same "no vague-listing → topic" discipline to all topics.
- **Resolve `politician_id` by external_id→UUID map, not by name**.

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV with a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **CSV quote-repair: collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""`.** `_merge.ts` uses `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`/`relax_column_count`.
- **Three known per-row artifacts to repair (Phase 134/137 lessons):**
  1. Stray-trailing-quote on the empty final field (`,"$`) → `sed -i 's/,"$/,/'` per file.
  2. Malformed quote-wrap `,""text""` (doubled quotes WITHOUT an outer wrap; the quad-quote repair does NOT catch it) → if a per-rep CSV has it AND no legitimately-escaped `""` exists inside reasoning fields (verify with grep first), run line-scoped `sed 's/""/"/g'` to convert to valid single-wrapped quoted fields.
  3. Quad-quote `""""` → handled by `_merge.ts` 4→3 collapse.

### DB push
- Push via the external_id-keyed `_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- **`_push.ts` does NOT load dotenv** — run pushes with `set -a && source .env && set +a && node --import tsx <dir>/_push.ts <csv>`. Verify scripts use `import 'dotenv/config'`.
- **Verify the no-scope-creep invariant via PER-SCOPE external_id counts** (push is external_id-keyed; writes are provably isolated) — NOT the global `politician_answers` counter (no `created_at`; drifts from concurrent prod cron/FEC jobs). Confirm each batch's in-scope reps reach exact counts and unsourced-in-scope = 0.
- **Standing user decision this milestone:** auto-push batches that merge 0-problems AND 0-unsourced (still show the STEP 3 summary), no per-batch approval pause.
- If MCP Supabase tokens expire mid-run (~hourly), fall back to `node --import tsx` + `pool` from `backend/src/lib/db.ts` (load `dotenv/config` first) for verification queries.

### Plan structure (clean per-state batching) — 5 plans, all wave 1, mutually independent
- `138-01` — KS: KS-1..KS-4 (external_id −20001..−20004, 4 reps) → `ks-house/`
- `138-02` — MS: MS-1..MS-4 (external_id −28001..−28004, 4 reps) → `ms-house/`
- `138-03` — NV: NV-1..NV-4 (external_id −32001..−32004, 4 reps) → `nv-house/`
- `138-04` — NE: NE-1..NE-3 (external_id −31001..−31003, 3 reps) → `ne-house/`
- `138-05` — NM: NM-1..NM-3 (external_id −35001..−35003, 3 reps) → `nm-house/`

### Claude's Discretion
- Dated CSV filenames (e.g. `2026-06-20-ks-house.csv`).
- Per-rep source selection within the five-chairs framing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution, approval, DB push, five-chairs framing
- `.planning/phases/137-la-ct-in-ok-ar-ia-house-rep-stances/137-01-PLAN.md` — exact plan template to mirror
- `.planning/phases/137-la-ct-in-ok-ar-ia-house-rep-stances/137-06-SUMMARY.md` + `137-VERIFICATION.md` — most recent validated playbook + calibration lessons
- `backend/data/stance-research/ok-house/_merge.ts` — latest merge+repair (sed-clone OUT + IN_SCOPE per batch)
- `backend/data/stance-research/ok-house/_push.ts` — reusable external_id-keyed push
- `backend/data/stance-research/ok-house/_TOPIC_SCALE.txt` — current 25-topic scale file (copy to each batch dir)

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)

</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-20 — all has_answers=false, all contiguous)

### Kansas (state_fips 20) — 4 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −20001 | KS-1 | Tracey Mann | | −20003 | KS-3 | Sharice Davids (D) |
| −20002 | KS-2 | Derek Schmidt | | −20004 | KS-4 | Ron Estes |

### Mississippi (state_fips 28) — 4 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −28001 | MS-1 | Trent Kelly | | −28003 | MS-3 | Michael Guest |
| −28002 | MS-2 | Bennie G. Thompson (D) | | −28004 | MS-4 | Mike Ezell |

### Nevada (state_fips 32) — 4 reps
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −32001 | NV-1 | Dina Titus (D) | | −32003 | NV-3 | Susie Lee (D) |
| −32002 | NV-2 | Mark E. Amodei | | −32004 | NV-4 | Steven Horsford (D) |

### Nebraska (state_fips 31) — 3 reps
| ext_id | dist | name |
|--------|------|------|
| −31001 | NE-1 | Mike Flood |
| −31002 | NE-2 | Don Bacon |
| −31003 | NE-3 | Adrian Smith |

### New Mexico (state_fips 35) — 3 reps (all Democrats)
| ext_id | dist | name |
|--------|------|------|
| −35001 | NM-1 | Melanie A. Stansbury (D) |
| −35002 | NM-2 | Gabe Vasquez (D) |
| −35003 | NM-3 | Teresa Leger Fernandez (D) |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only. Expected thin record / honest-partial: **Derek Schmidt KS-2** (2024 freshman, but former Kansas Attorney General — his AG record is documentable). All other 17 are established multi-term members. Document the actual record — never infer from party.)

</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Remaining single/low-rep states — Phase 139.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14).

</deferred>

---

*Phase: 138-ks-ms-nv-ne-nm-house-rep-stances*
*Context gathered: 2026-06-20 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
