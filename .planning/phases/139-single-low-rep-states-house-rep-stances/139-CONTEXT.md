# Phase 139: Single/Low-Rep States House Rep Stances - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from locked v2.16/v2.17 methodology + production roster (web research skipped — milestone-level decision; verbatim repeat of the proven phases 127–138 pattern).

<domain>
## Phase Boundary

Research and ingest sourced compass stances for the **18 in-scope US House reps** across the 12 smallest-delegation states — six two-rep states (HI, ID, MT, NH, RI, WV) + six at-large single-rep states (AK, DE, ND, SD, VT, WY) — the eighth and final research wave of v2.17 (Tier 2 continuation), covering USHS-13. Each rep currently has **0 stances**. On completion every rep has ≥1 sourced `inform.politician_answers` row (or a documented honest-skip), each paired with an `inform.politician_context` row carrying real fetched source URLs. Pure scale-out of the v2.16 pipeline (phases 127–138); **no new architecture, no schema changes, no geofencing.**

**In-scope filter:** `essentials.politicians` with `external_id BETWEEN -56999 AND -1000`, state_fips ∈ {15 HI, 16 ID, 30 MT, 33 NH, 44 RI, 54 WV, 2 AK, 10 DE, 38 ND, 46 SD, 50 VT, 56 WY}, and NO existing `inform.politician_answers` rows. Production project: `kxsdzaojfaibhuzmclfq`. Roster verified 2026-06-20: all 18 reps confirmed `has_answers=false`.

**CRITICAL external_id quirk — at-large states use `−{fips}000`, NOT `−{fips}001`:** AK=−2000, DE=−10000, ND=−38000, SD=−46000, VT=−50000, WY=−56000. The six two-rep states use the standard −{fips}001/002. The merge `IN_SCOPE` sets MUST list these exact ids (verified in prod) — do NOT assume a −{fips}001 pattern for the at-large singles.
</domain>

<decisions>
## Implementation Decisions (LOCKED — validated playbook from phases 127–138)

### Research methodology
- **25 federal topics in scope** = the 44 live `inform.compass_topics` minus 11 city-level topics minus all `judicial-*` topics. Reuse the current per-batch `_TOPIC_SCALE.txt` (copy from a Phase 138 batch dir, e.g. `ks-house/_TOPIC_SCALE.txt` — confirmed current vs live DB 2026-06-20); every research agent Reads it.
- **Concurrency: up to 3 `politician-stance-researcher` agents at a time** (validated on premium tier). WebFetch ONLY. Verify each wave's rows before dispatching the next; retry empty-output agents solo.
- **EFFICIENCY rule (bake into every agent prompt):** try each source URL ONCE; if it 403s/404s/times out, move on immediately — do NOT retry or loop. Finish in a few minutes.
- **Five-chairs / evidence-over-party framing**: match the documented record to the exact stance text; **never infer a stance from party affiliation**; honest-skip any topic with no documentable evidence. Productive sources: Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard, VoteSmart. house.gov / congress.gov / govtrack / clerk.house.gov consistently 403 to WebFetch.
- **isidewith.com is BELOW the evidence bar** — DROP any row sourced ONLY by isidewith. AFA / candidate-completed voter-guide questionnaires ARE acceptable.
- **Proxy-row review gate (reinforced phase 138, 7 drops):** agents routinely emit rows scored from "no direct vote found, overall record alignment" / "committee membership" / "caucus member indicating support." DROP these at review before push. KEEP a caucus row ONLY when that caucus has a published platform DIRECTLY on the topic (e.g. Equality Caucus → same-sex-marriage is acceptable; Equality Caucus → trans-athletes or a generic "diversity VP role" → civil-rights is NOT).
- **SSM=5 calibration discipline:** `same-sex-marriage=5` ("make illegal") requires a documented anti-recognition vote OR explicit support for a one-man-one-woman constitutional amendment. DROP an SSM=5 whose only evidence is Equality Act opposition / "opposes legalization" / a religious-exemption bill / a belief quote.
- **Resolve `politician_id` by external_id→UUID map, not by name**.

### CSV handling
- Each agent writes a **per-rep CSV** (`<surname>.csv`) into the batch dir. Merge per-rep CSVs into the dated batch CSV with a real RFC-4180 parser (csv-parse/sync), validating every row: valid `topic_key`, value 1–5, non-empty reasoning, ≥1 `http` source.
- **CSV quote-repair: collapse `""""`→`"""` ONLY (4→3); NEVER `"""`→`""`.** `_merge.ts` uses `replace(/"""""+/g,'"""').replace(/""""/g,'"""')` + csv-parse `relax_quotes`/`relax_column_count`. Per-row artifacts: stray trailing `"` on empty final field → `sed -i 's/,"$/,/'`; malformed `,""text""` wrap (no escaped `""` inside reasoning, verify with grep) → line-scoped `sed 's/""/"/g'`.

### DB push
- Push via the external_id-keyed `_push.ts` (answers + context + quotes in one transaction; ON CONFLICT (politician_id, topic_id) DO UPDATE on both; suffix-aware surname leak-check on quotes). Swap the CSV path per batch.
- **`_push.ts` does NOT load dotenv** — run pushes with `set -a && source .env && set +a && node --import tsx <dir>/_push.ts <csv>`.
- **Verify the no-scope-creep invariant via PER-SCOPE external_id counts** — NOT the global `politician_answers` counter. Confirm each batch's in-scope reps reach exact counts and unsourced-in-scope = 0.
- **MCP Supabase token expires ~hourly** — fall back to a `node --import tsx` script that imports `pool` from `src/lib/db.js` (script must live INSIDE `backend/` to resolve node_modules; load `dotenv/config` first).
- **Standing user decision this milestone:** auto-push batches that merge 0-problems AND 0-unsourced (still show the STEP 3 summary), no per-batch approval pause.

### Plan structure (3 balanced 6-rep plans, all wave 1, mutually independent)
- `139-01` — HI + ID + MT: HI-1,2 (−15001,−15002), ID-1,2 (−16001,−16002), MT-1,2 (−30001,−30002) = 6 reps → `hi-id-mt-house/`
- `139-02` — NH + RI + WV: NH-1,2 (−33001,−33002), RI-1,2 (−44001,−44002), WV-1,2 (−54001,−54002) = 6 reps → `nh-ri-wv-house/`
- `139-03` — AK + DE + ND + SD + VT + WY (at-large singles, `−{fips}000` ids): AK (−2000), DE (−10000), ND (−38000), SD (−46000), VT (−50000), WY (−56000) = 6 reps → `atlarge-house/`

### Claude's Discretion
- Dated CSV filenames (e.g. `2026-06-20-hi-id-mt-house.csv`).
- Per-rep source selection within the five-chairs framing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Pipeline (proven, reuse verbatim)
- `.claude/skills/research-stances/SKILL.md` — topic resolution, approval, DB push, five-chairs framing
- `.planning/phases/138-ks-ms-nv-ne-nm-house-rep-stances/138-01-PLAN.md` — exact plan template to mirror
- `.planning/phases/138-ks-ms-nv-ne-nm-house-rep-stances/138-05-SUMMARY.md` + `138-VERIFICATION.md` — most recent validated playbook + proxy-row / calibration lessons
- `backend/data/stance-research/ks-house/_merge.ts` — latest merge+repair (sed-clone OUT + IN_SCOPE per batch)
- `backend/data/stance-research/ks-house/_push.ts` — reusable external_id-keyed push
- `backend/data/stance-research/ks-house/_TOPIC_SCALE.txt` — current 25-topic scale file (copy to each batch dir)

### Gate
- `backend/scripts/verify-phase-127-131.sql` — pattern for the v2.17 consolidated gate (built in Phase 140, not here)

</canonical_refs>

<specifics>
## In-scope roster (production, verified 2026-06-20 — all has_answers=false)

### Two-rep states
| ext_id | dist | name | | ext_id | dist | name |
|--------|------|------|-|--------|------|------|
| −15001 | HI-1 | Ed Case (D) | | −15002 | HI-2 | Jill N. Tokuda (D) |
| −16001 | ID-1 | Russ Fulcher | | −16002 | ID-2 | Michael K. Simpson |
| −30001 | MT-1 | Ryan K. Zinke | | −30002 | MT-2 | Troy Downing (2024 freshman) |
| −33001 | NH-1 | Chris Pappas (D) | | −33002 | NH-2 | Maggie Goodlander (D, 2024 freshman) |
| −44001 | RI-1 | Gabe Amo (D, elected 2023 special) | | −44002 | RI-2 | Seth Magaziner (D) |
| −54001 | WV-1 | Carol D. Miller | | −54002 | WV-2 | Riley M. Moore (2024 freshman) |

### At-large single-rep states (external_id = −{fips}000)
| ext_id | dist | name |
|--------|------|------|
| −2000 | AK-AL | Nicholas J. Begich III (2024 freshman) |
| −10000 | DE-AL | Sarah McBride (D, 2024 freshman; prior DE state senator + national advocate — record documentable) |
| −38000 | ND-AL | Julie Fedorchak (2024 freshman; prior ND Public Service Commissioner) |
| −46000 | SD-AL | Dusty Johnson |
| −50000 | VT-AL | Becca Balint (D) |
| −56000 | WY-AL | Harriet M. Hageman |

(Resolve `politician_id` by external_id→UUID at run time — names above are for source-finding only. Expected thin records / honest-partials: the 2024 freshmen (Downing MT-2, Goodlander NH-2, Moore WV-2, Begich AK, McBride DE, Fedorchak ND). McBride/Fedorchak/Goodlander have documentable prior records (state office, advocacy, DOJ). Document the actual record — never infer from party.)

</specifics>

<deferred>
## Deferred Ideas

- FEC finance summary for these reps — separate FINA stream, not in scope.
- Consolidated verify SQL for all 212 — Phase 140 (USHS-14), the final v2.17 gate.

</deferred>

---

*Phase: 139-single-low-rep-states-house-rep-stances*
*Context gathered: 2026-06-20 (inline authoring from locked v2.16/v2.17 methodology + production roster)*
