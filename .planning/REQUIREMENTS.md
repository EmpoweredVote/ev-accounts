# Requirements: v2.15 National House Rep Seeding (Tier 1)

**Milestone:** v2.15  
**Status:** Active  
**Last updated:** 2026-06-16

Every US resident who enters their address sees their actual sitting US House representative. Geofencing infrastructure is already complete (Phase 116/v2.11): all 436 CD119 polygons imported and `tiger_geoid` backfilled on all 440 `NATIONAL_LOWER` district rows. Only 137/435 House reps are currently seeded. This milestone seeds the ~298 missing House politician + office records, FK-linked to the existing districts. **Stance research for these reps is Tier 2, deferred to v2.16+ (NOT in this milestone). FEC finance is a separate FINA stream, also out of scope.**

Data source: `unitedstates/congress-legislators` `legislators-current.yaml`. Insert pattern reuses migration 311 (VA federal officials). Shared US House chamber UUID `c2facc31-7b13-428c-b7b9-32d0d3b95f76`. See `.planning/research/SUMMARY.md` for the full mapping + gotchas.

---

## House Rep Seeding (USHR)

- [x] **USHR-01**: All sitting US House representatives for the 50 states + DC delegate are seeded as `essentials.politicians` + `essentials.offices` records, FK-linked to the correct `NATIONAL_LOWER` district via `tiger_geoid`, sourced from `legislators-current.yaml`. ✅ Phase 125 (migration 739; 299 seeded; linked 137→436)
- [x] **USHR-02**: Ingestion is idempotent and touches only currently-unseeded districts — the 137 already-linked reps and all other data are untouched; re-running is a no-op and creates no orphan politicians (every new politician has a linked office). ✅ Phase 125 (clean no-op re-run; 0 orphans)
- [x] **USHR-03**: Data normalization correct — party mapped `Democrat→Democratic` (preserving v2.6 SACC-03 normalization); at-large districts (`district 0` → geoid suffix `00`) and the DC delegate handled; territory delegates (PR/GU/VI/AS/MP) excluded. ✅ Phase 125 (0 'Democrat' rows; at-large/territory handled)
- [x] **USHR-04**: Every newly-seeded House rep has a headshot (`photo_origin_url`) imported via the `find-headshots` skill, or is documented as no-photo-found. ✅ Phase 126 (299/299: 292 canonical congress URLs + 7 official Wikimedia portraits storage-mirrored)
- [x] **USHR-05**: Phase-gate verify SQL confirms national coverage — every YAML-listed current House rep (50 states + DC) is linked; Path 0 returns the correct rep for spot-check addresses across ≥5 states (including an at-large state and DC); zero orphan politicians; party-normalization assertion holds. ✅ Phase 126 (verify-phase-125-126.sql, all assertions pass)

---

## Future Requirements (deferred)

- **Tier 2 (v2.16+)**: Sourced stance + context research for the ~298 newly-seeded House reps (one state/wave at a time per rate-limit rule). 21 compass topics, Chair methodology, honest-skip where no record.
- FEC finance summary ingestion for newly-seeded House reps (FINA stream).

## Out of Scope

- Stance research for the new reps (→ Tier 2, v2.16+)
- FEC / campaign finance data (→ FINA stream)
- US Senate (already fully covered: 50 `NATIONAL_UPPER`, 143 politicians)
- Congressional district polygon import / `tiger_geoid` backfill (already complete — Phase 116/v2.11)
- Non-voting territory delegates (PR/GU/VI/AS/MP) — no `NATIONAL_LOWER` district rows exist for them

---

## Traceability

| Requirement | Phase |
|-------------|-------|
| USHR-01 | 125 |
| USHR-02 | 125 |
| USHR-03 | 125 |
| USHR-04 | 126 |
| USHR-05 | 126 |
