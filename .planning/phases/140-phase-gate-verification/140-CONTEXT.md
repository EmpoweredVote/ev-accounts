# Phase 140: Phase Gate Verification - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning
**Source:** Authored inline by orchestrator from the v2.16 gate pattern (`verify-phase-127-131.sql`) + a production diagnostic run 2026-06-20 that fixed every assertion constant.

<domain>
## Phase Boundary

Author **one read-only, labeled-assertion SQL script** — `backend/scripts/verify-phase-132-140.sql` — that proves v2.17 is complete: every in-scope US House rep across the 8 research waves (phases 132–139) has sourced stance coverage, with **zero unsourced answer rows**. The script follows the proven `backend/scripts/verify-phase-127-131.sql` pattern (anonymous `DO $$` blocks, `RAISE EXCEPTION` on failure / `RAISE NOTICE` on pass, run with `psql -v ON_ERROR_STOP=1`). No schema changes, no data writes — verification only.

Deliverable = the committed script + proof that every labeled assertion PASSES against production.
</domain>

<decisions>
## Implementation Decisions (LOCKED — fixed by the 2026-06-20 production diagnostic)

### Scope facts (verified in prod `kxsdzaojfaibhuzmclfq`)
- Full national House set `external_id BETWEEN -56999 AND -1000` = **299 seeded = v2.16's 87 (FL/NY/PA/IL) + v2.17's 212**. No other-milestone reps occupy this range, so per-state-FIPS counts are clean (no pre-existing-answer contamination).
- The **v2.17 in-scope set = the 38 state FIPS** touched by phases 132–139 = **212 seeded reps**.
- **211 of 212 are covered. The single uncovered rep is `-37006` Addison McDowell (NC-6)** — the documented honest-skip from Phase 132 (brand-new freshman, no documentable record; recorded in 132's SUMMARY/verification). This is an accepted exemption, NOT a miss.
- **In-scope unsourced answer rows = 0.**

### State FIPS per requirement (exact assertion constants)
| Req | States (FIPS) | seeded | covered (assert) |
|-----|---------------|--------|------------------|
| USHS-06 | OH 39, NC 37 | 29 | **28** (McDowell −37006 honest-skip) |
| USHS-07 | GA 13, MI 26 | 26 | 26 |
| USHS-08 | NJ 34, WA 53, AZ 4 | 31 | 31 |
| USHS-09 | TN 47, CO 8, MN 27, MO 29 | 33 | 33 |
| USHS-10 | WI 55, AL 1, SC 45, KY 21 | 28 | 28 |
| USHS-11 | LA 22, CT 9, IN 18, OK 40, AR 5, IA 19 | 29 | 29 |
| USHS-12 | KS 20, MS 28, NV 32, NE 31, NM 35 | 18 | 18 |
| USHS-13 | HI 15, ID 16, MT 30, NH 33, RI 44, WV 54, AK 2, DE 10, ND 38, SD 46, VT 50, WY 56 | 18 | 18 |
| **USHS-14** | all 38 above | **212** | **211** + 0 unsourced |

### Gate construction rules
- **FIPS-range coverage** per the v2.16 pattern: a state's reps are `external_id` such that `floor((-external_id)/1000) = <fips>` within `-56999..-1000`. Coverage = rep has ≥1 `inform.politician_answers` row.
- **Honest-skip handling (the one deviation from the v2.16 gate, where all 87 were covered):** USHS-06 asserts covered = **28** (not 29). USHS-14a asserts the set of uncovered in-scope reps is **exactly `{-37006}`** — this both proves the 211 coverage AND proves no OTHER rep slipped through. The script comments must name McDowell −37006 as the documented Phase-132 honest-skip so the "missing" rep is never mistaken for a regression.
- **USHS-14b (zero unsourced):** reuse the v2.16 `verify-phase-127-131.sql` USHS-05b assertion verbatim, swapping the FIPS predicate to the v2.17 38-state set: every in-scope `politician_answers` row must have a paired `politician_context` row with `sources[1] LIKE 'http%'`.
- The 38-state predicate is large; implement it as `floor((-p.external_id)/1000) IN (1,2,4,5,8,9,10,13,15,16,18,19,20,21,22,26,27,28,29,30,31,32,33,34,35,37,38,39,40,44,45,46,47,50,53,54,55,56)` (or `= ANY(ARRAY[...])`), both bounded by `external_id BETWEEN -56999 AND -1000`.
- Final `RAISE NOTICE 'verify-phase-132-140: ALL USHS-06..14 ASSERTIONS PASSED'`.

### Claude's Discretion
- Exact SQL phrasing of the McDowell exemption (a `<> 28` check plus a separate "uncovered set = {−37006}" assertion is the recommended belt-and-suspenders form).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before implementing.**

- `backend/scripts/verify-phase-127-131.sql` — exact pattern to mirror (DO-block labeled assertions, RAISE EXCEPTION/NOTICE, FIPS-range coverage + the USHS-05b unsourced check)
- `.planning/phases/132-oh-nc-house-rep-stances/132-VERIFICATION.md` (and 132 SUMMARYs) — documents McDowell NC-6 (−37006) as the accepted honest-skip
- `.planning/phases/13{3,4,5,6,7,8,9}-*/`*-VERIFICATION.md — per-wave covered counts (all full except OH+NC)
- DB push/verify connection: `backend/src/lib/db.ts` `pool` (scripts load `import 'dotenv/config'`; run from inside `backend/`). MCP Supabase token expires ~hourly — prefer psql or the pool.

</canonical_refs>

<specifics>
## How to run the gate
```
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-132-140.sql
```
If `psql` is unavailable in this environment, run the same SQL via `node --import tsx` using the `pool` from `backend/src/lib/db.ts` (execute each DO block; a thrown error = failed assertion). Expected: every assertion emits its `... PASS` NOTICE and the final `ALL USHS-06..14 ASSERTIONS PASSED`.
</specifics>

<deferred>
## Deferred Ideas

- Auto-filling McDowell NC-6 once he builds a documentable record — future gap-fill stream, not this phase.
- FEC finance coverage gate — separate FINA stream.
- After this gate passes: `/gsd-complete-milestone` to archive v2.17.

</deferred>

---

*Phase: 140-phase-gate-verification*
*Context gathered: 2026-06-20 (inline authoring from v2.16 gate pattern + production diagnostic)*
