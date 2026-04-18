---
phase: 121
slug: county-council-d1-d4-geofence-repair
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 121 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 2.1.0 (route tests) + standalone tsx smoke script (live-DB) |
| **Config file** | `ev-accounts/backend/vitest.config.ts` |
| **Quick run command** | `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts --dry-run` |
| **Full suite command** | `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts` |
| **Estimated runtime** | ~15 seconds (full smoke run against dev DB) |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts --dry-run` (no DB hit — validates script integrity)
- **After every plan wave:** Run `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts` (live DEV DB)
- **Before `/gsd-verify-work`:** Full smoke test green on DEV, then re-run against PROD (api.empowered.vote) per D-06 discipline
- **Max feedback latency:** ~15 seconds (dev DB smoke)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 121-01-01 | 01 | 0 | GEO-01 | — | Diagnostic SQL read-only against dev DB | script | `cd ev-accounts/backend && npx tsx scripts/diagnose-121-mcc-state.ts` | ❌ W0 | ⬜ pending |
| 121-01-02 | 01 | 0 | GEO-01 | — | Extend smoke test with MCC exclusivity assertion (`councilRaces.length === 1`) | script | `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts --dry-run` | ✅ (extend) | ⬜ pending |
| 121-02-01 | 02 | 1 | GEO-01 | — | Fetch 4 MCC polygons from Monroe County ArcGIS FeatureServer as GeoJSON (EPSG:4326) | script | `cd ev-accounts/backend && npx tsx scripts/fetch-mcc-district-polygons.ts --dry-run` | ❌ W0 | ⬜ pending |
| 121-02-02 | 02 | 1 | GEO-01 | — | Insert 4 `essentials.geofence_boundaries` rows with `geo_id=18105-mcc-d{1..4}`, `mtfcc=X-MCC-DISTRICT`, ST_Force2D on geometry | migration/script | `cd ev-accounts/backend && npx tsx scripts/import-mcc-district-polygons.ts --check` | ❌ W0 | ⬜ pending |
| 121-02-03 | 02 | 1 | GEO-01 | — | Insert 4 `essentials.districts` rows linked by geo_id to the new polygons | migration/script | post-import SELECT count = 4 | ❌ W0 | ⬜ pending |
| 121-03-01 | 03 | 2 | GEO-01 | — | Update `link-monroe-county-races-to-geofences.sql` §2a to map each MCC race to its per-district geofence (idempotent) | SQL | `psql -f link-monroe-county-races-to-geofences.sql` (idempotent re-run) | ✅ (edit) | ⬜ pending |
| 121-03-02 | 03 | 2 | GEO-01, GEO-02 | — | Kirkwood returns exactly 1 MCC race (D4) | smoke | `cd ev-accounts/backend && npx tsx scripts/audit-112-geofence.ts` | ✅ (extend) | ⬜ pending |
| 121-04-01 | 04 | 3 | GEO-01 | — | Correct the disputed doc text — ROADMAP.md success criteria #1 wording and GAP-REPORT PATTERN-004 direction must match verified ground truth (D4) | doc edit | grep confirms corrected wording in both files | ✅ (edit) | ⬜ pending |
| 121-04-02 | 04 | 3 | GEO-02 | — | Production verification against api.empowered.vote after Render deploy | smoke | `curl` against prod API asserting 1 MCC race for Kirkwood | ✅ (smoke harness) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ev-accounts/backend/scripts/diagnose-121-mcc-state.ts` — read-only diagnostic: dump current `geofence_boundaries` rows for Monroe County, current `districts` rows with `district_type IN ('LOCAL','COUNTY')` for geo_id=18105, current `offices` linking MCC races, and live `ST_Covers` query for the Kirkwood point. Writes CSV to `.planning/phases/121-.../diagnosis.csv`.
- [ ] `ev-accounts/backend/scripts/fetch-mcc-district-polygons.ts` — fetches 4 GeoJSON features from Monroe County GIS FeatureServer, validates SRS=EPSG:4326, writes to `.planning/phases/121-.../mcc-district-polygons.geojson`.
- [ ] `ev-accounts/backend/scripts/import-mcc-district-polygons.ts` — idempotent INSERT of 4 `geofence_boundaries` rows + 4 `districts` rows using the saved GeoJSON. `--check` flag reports counts without inserting.
- [ ] Extend `ev-accounts/backend/scripts/audit-112-geofence.ts` with exclusivity assertion: for Kirkwood coords, assert exactly 1 MCC council race returned.

*Existing Vitest infrastructure (`backend/tests/essentials-elections.test.ts`) is route-wiring only — insufficient for GEO-01/GEO-02 which require live PostGIS data.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Ground-truth attestation (D4 correct for Kirkwood) | GEO-01 | Requires human sign-off on two independent authoritative GIS sources (Monroe County FeatureServer + IN state Admin Boundaries) | Planner/executor records FeatureServer URLs + query JSON + screenshot in RESEARCH.md evidence block; reviewer confirms |
| Production smoke after deploy | GEO-02 | Render deploy pipeline sits outside the test harness (D-06 inherited from Phase 118/119) | After PR merge + deploy completes, re-run smoke against `api.empowered.vote` and paste output into phase verification report |
| Disputed doc correction | GEO-01 | Requires a human decision about which wording is authoritative before edit | Update ROADMAP.md success criteria #1 and GAP-REPORT.md PATTERN-004 direction once research confirms D4 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (diagnose / fetch / import scripts + smoke extension)
- [ ] No watch-mode flags (scripts are one-shot)
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter (flip on phase completion)

**Approval:** pending
