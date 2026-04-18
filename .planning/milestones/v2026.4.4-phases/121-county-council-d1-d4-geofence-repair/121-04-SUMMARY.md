---
phase: 121-county-council-d1-d4-geofence-repair
plan: 04
subsystem: documentation, database
tags: [gap-report, production-verification, geofence, monroe-county, kirkwood]

# Dependency graph
requires:
  - phase: 121-03
    provides: dev smoke green, SQL re-link complete
provides:
  - Corrected GAP-REPORT.md PATTERN-004 (D4 is correct, not D1)
  - Production smoke evidence (smoke-kirkwood-prod.txt)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Production verification via DATABASE_URL pointing to prod Supabase project"

key-files:
  created:
    - .planning/phases/121-county-council-d1-d4-geofence-repair/evidence/smoke-kirkwood-prod.txt
  modified:
    - .planning/GAP-REPORT.md

key-decisions:
  - "Production DATABASE_URL was already configured in ev-accounts/backend/.env — no PROD_DATABASE_URL export needed"
  - "Prod DB was already in the correct state at task execution time: 4 MCC races linked to election-mcc-d{N} offices, geofence_boundaries has 18105-mcc-d{N} rows"
  - "GAP-REPORT.md PATTERN-004 root-cause rewritten to reflect the actual bug (all-4-districts, not D1-vs-D4) with cross-reference to ground-truth-attestation.md"

patterns-established:
  - "Phase 121: Prod smoke uses same audit-112-geofence.ts script with DATABASE_URL pointing to prod"

requirements-completed: [GEO-01, GEO-02]

# Metrics
duration: 15min
completed: 2026-04-16
---

# Phase 121 Plan 04: Documentation Correction + Production Verification Summary

**GAP-REPORT.md PATTERN-004 corrected to verified ground truth; production smoke confirms Kirkwood → Monroe County Council District 4 exclusively (`[121-geo] PASS`, `exit_code=0`).**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-04-16
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- **Task 1:** Rewrote GAP-REPORT.md PATTERN-004 Root cause bullet. Old framing ("should resolve to D1, returns D4") replaced with the correct structural description: all four MCC offices link to the shared county-wide `geo_id='18105'` district, so every Monroe County address matches all four races. Added `**Correction (Phase 121):**` bullet documenting the Ballotpedia superset misinterpretation. Cross-referenced `evidence/ground-truth-attestation.md`.

- **Task 2:** Ran `audit-112-geofence.ts` against production DB (`kxsdzaojfaibhuzmclfq` — confirmed via project ID in DATABASE_URL). Production was already in the correct state (import + link had already been applied). Smoke output captured to `evidence/smoke-kirkwood-prod.txt`.

## GAP-REPORT.md Diff Summary

**Removed (old wording):**
> A Kirkwood Bloomington address that should resolve to County Council District 1 returns District 4 instead. The geofence row exists (per AUDIT-01 race table linking CC D1) but the polygon binding is incorrect.

**Added (corrected wording):**
> A Kirkwood Bloomington address (200 W Kirkwood Ave, Bloomington IN 47404; lat=39.166646, lng=-86.534947) resolves to all four Monroe County Council District races (D1/D2/D3/D4) instead of exactly one. The authoritative district for this address is **D4** (Jennifer Crossley) per two independent GIS sources... The bug is structural, not a polygon coordinate error...

**Added correction block:** Documents that "D1" framing came from Ballotpedia superset, verified D4 via Monroe County GIS + IN state GIS.

## Production Smoke Result

```
[121-geo] PASS: Kirkwood returns exactly 1 MCC Council race: Monroe County Council District 4
exit_code=0
```

Full output in `evidence/smoke-kirkwood-prod.txt`.

## Production DB Preflight Findings

At task execution time, production already had:
- `essentials.geofence_boundaries`: rows `18105-mcc-d1` through `18105-mcc-d4` with `mtfcc=X-MCC-DIST` ✓
- `essentials.races`: all 4 MCC races linked to `election-mcc-d{N}` district_ids ✓

The import + link SQL had already been applied to prod (consistent with dev DB state from Plan 01 diagnosis). No additional DB writes were needed in this plan.

## Human Approval

User explicitly authorized production script execution: "you go ahead and run these" — recorded as approval for the checkpoint gate.

## Self-Check

### Files exist:
- `.planning/GAP-REPORT.md` — MODIFIED (PATTERN-004 corrected) ✓
- `.planning/phases/121-county-council-d1-d4-geofence-repair/evidence/smoke-kirkwood-prod.txt` — CREATED ✓

### Key strings present in GAP-REPORT.md:
- `Correction (Phase 121)` — FOUND ✓
- `Jennifer Crossley` — FOUND ✓
- `ground-truth-attestation.md` — FOUND ✓
- `gis.co.monroe.in.us` — FOUND ✓
- Old incorrect phrase removed ✓

### Smoke file:
- `[121-geo] PASS` — FOUND ✓
- `exit_code=0` — FOUND ✓
- No `postgres://` URL leaked — CONFIRMED ✓

## Self-Check: PASSED
