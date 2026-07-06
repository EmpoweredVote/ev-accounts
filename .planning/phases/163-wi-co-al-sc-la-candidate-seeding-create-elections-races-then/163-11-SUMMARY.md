---
phase: 163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then
plan: 11
title: Phase 163 consolidated 36-district verify gate
status: complete
executed: 2026-07-06
execution_mode: inline (orchestrator) — deterministic read-only gate authoring
---

# 163-11 SUMMARY — Phase 163 read-only 36-district verify gate

**Result:** Both phase-closing gates authored and **GREEN against PROD**. The consolidated read-only gate proves USHC3-02/03/04/05 across all 36 WI/CO/AL/SC/LA districts end-to-end, plus the new AL-SEVERE, LA-SEVERE, and CO1-DEGETTE invariants.

## `backend/scripts/163-verify.sql` — GREEN (psql exit 0, 11 PASS blocks)
```
PASS SCOPE: WI 8 + CO 8 + AL 7 + SC 7 + LA 6 = 36 distinct NATIONAL_LOWER races
PASS NULLOFFICE: 0 of 36 have NULL office_id (incl. the 3 withheld severe AL/LA races)
PASS NULLPID: 0 active candidates with NULL politician_id
PASS DUPNAME: 0 duplicate full_name within any state among active candidates
PASS PARTY: race_candidates has no party/party_affiliation column
PASS AL-SEVERE: AL-2 (0102) -> Polygon Pending; 6 non-severe -> AL 2026 Statewide General
PASS LA-SEVERE: LA-2/LA-6 (2202/2206) -> Polygon Pending; 4 non-severe -> LA 2026 Statewide General; all 6 LA races primary_party NULL (jungle); no Dec-2026 runoff
PASS CO1-DEGETTE: CO-1 (0801) has exactly 2 active candidates and DeGette (610bb358) is absent
PASS HEADSHOT: every active new candidate has an image or a pinned honest-skip (95 pinned)
PASS UNSOURCED: 0 unsourced stance rows for the in-scope candidate set (challengers + incumbents)
PASS COVERAGE: every in-scope new candidate has >=1 sourced stance or a pinned whole-record skip (10 pinned)
ALL ASSERTIONS PASSED
```

## `backend/scripts/163-coordinate-smoke.ts` — GREEN (5 positive + 2 severe negatives)
```
PASS WI 5501: 5 active, 4 challengers   PASS CO 0808: 2 active, 1 challenger
PASS AL 0101: 5 active, 5 challengers   PASS SC 4501: 4 active, 4 challengers
PASS LA 2205: 12 active, 12 challengers
PASS AL 0102 (severe negative): ZERO races on AL 2026 Statewide General — withholding confirmed
PASS LA 2206 (severe negative): ZERO races on LA 2026 Statewide General — withholding confirmed
COORDINATE SMOKE GREEN: 5/5 states + AL-severe + LA-severe negatives
```

## Severe geo_ids asserted withheld (→ 'XX 2026 Congressional Redistricting - Polygon Pending')
- **AL severe:** 0102 (AL-2, Figures' 2023-special-master seat). Non-severe surfacing: 0101/0103/0104/0105/0106/0107.
- **LA severe:** 2202 (LA-2, Carter), 2206 (LA-6, Fields' dissolved majority-Black seat post-SB121/Act 2). Non-severe surfacing: 2201/2203/2204/2205.

## Pin snapshots (frozen at gate-authoring time, 2026-07-06)
- **_stance_skip (10):** WI Nath -550402; AL Burger -10101; SC Ellis -450104 / Smith -450202 / Ethridge -450402; LA Arrington -220101 / Long -220102 / Collins -220201 / Walker -220303 / Williams -220604. (CO 0.)
- **_img_skip (95):** WI 27 + CO 7 + AL 20 + SC 15 + LA 26, reconstructed live. Edmonds pinned as **-220605** (post-mig-1230 re-key), not the stale -220503.

## Standing invariants — MUST be inherited downstream
- **Phase 166 (consolidated national gate)** inherits the AL-SEVERE + LA-SEVERE + CO1-DEGETTE blocks (alongside 162's MO-SEVERE + IN9-FLAG).
- **Phase 164.1 (cross-state polygon refresh / dual-map)** must **un-withhold AL-2 (0102) + LA-2 (2202) + LA-6 (2206)** on polygon refresh (mirror the MO/TN carry-forward) — and update this gate's AL-SEVERE / LA-SEVERE assertions + the coordinate-smoke negative samples to positive once the new-map polygons land. Also re-verify Edmonds (-220605) surfaces correctly in the refreshed LA-6.

## Notes
- Gate is WRITE-FREE (only CREATE TEMP TABLE ON COMMIT DROP); SELECT-only against prod.
- Transient Supabase pooler stall hit mid-authoring (recovered on retry) — the burst of stance pushes saturated connections briefly; no data impact.
- AL-2/AL-6/AL-7 are Aug-11-2026 SPECIAL primaries (per 163-08); only AL-2 is severity-routed, so the gate's AL wiring is unaffected. WI-8 Benjamin Hable + SC/MO/etc. late-filer items remain queued for Phase-167.

## For phase closeout
Phase 163 is gate-verified end-to-end. Ready for /gsd-verify-work + /gsd-complete-milestone. All 11 plans (01-11) complete.
