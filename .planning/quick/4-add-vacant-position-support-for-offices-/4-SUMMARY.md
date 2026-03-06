---
phase: quick-4
plan: 01
subsystem: essentials
tags: [vacancy, offices, backend, frontend]
dependency_graph:
  requires: []
  provides: [VACANT-01, VACANT-02, VACANT-03]
  affects: [essentials-frontend, EV-Backend-essentials]
tech_stack:
  added: []
  patterns:
    - Office-centric LEFT JOIN queries returning vacant seats alongside filled ones
    - is_vacant flag on Office model as source of truth (supersedes Politician.is_vacant legacy field)
    - Dimmed card rendering with badge prop for vacant seats in frontend
key_files:
  created:
    - EV-Backend/scripts/apply_noem_vacancy.sql
  modified:
    - EV-Backend/internal/essentials/models.go
    - EV-Backend/internal/essentials/handlers.go
    - EV-Backend/internal/essentials/geofence_lookup.go
    - EV-Backend/internal/essentials/transform.go
    - EV-Backend/internal/staging/handlers.go
    - essentials/src/lib/classify.js
    - essentials/src/pages/Results.jsx
decisions:
  - Office.IsVacant (not Politician.IsVacant) is the source of truth for vacancy
  - PoliticianID on Office made nullable (*uuid.UUID) to support future orphan-free vacant offices
  - Queries use (p.is_active = true OR o.is_vacant = true) — vacant offices visible even with inactive politician
  - COALESCE all p.* fields to handle NULL politician on vacant seats
  - Dimmed opacity 0.55 on wrapping div for vacant cards
metrics:
  duration: ~20 minutes
  completed: 2026-03-06T21:07:40Z
  tasks: 3
  files: 7
---

# Quick Task 4: Add Vacant Position Support for Offices — Summary

**One-liner:** Office-level vacancy flags with LEFT JOIN queries return vacant seats in API responses; frontend renders them inline with 0.55 opacity, "Vacant" badge, and no click handler.

## Tasks Completed

### Task 1: Backend — Vacancy fields and query path updates (EV-Backend)
**Commit:** `3e49070`

Added `IsVacant bool` and `VacantSince *time.Time` fields to the `Office` struct in `models.go`. Made `PoliticianID` nullable (`*uuid.UUID`) so vacant offices can exist without a linked politician.

Updated all three query functions to use offices as the base table with `LEFT JOIN essentials.politicians p ON o.politician_id = p.id`:
- `fetchOfficialsFromDB` — ZIP-based lookup
- `fetchFederalAndStateFromDBFiltered` — state/federal lookup (also adds `is_active` filter that was previously missing)
- `FindPoliticiansByGeoMatches` — PostGIS geofence-based lookup

All three now use `AND (p.is_active = true OR o.is_vacant = true)` and COALESCE all `p.*` fields for NULL safety. `OfficialOut.IsVacant` now sources from `Office.IsVacant` (not the legacy `Politician.IsVacant` field). `VacantSince` added to `OfficialOut`.

Fixed `PoliticianID: &polID` pointer usage in `handlers.go`, `transform.go`, and `staging/handlers.go`.

### Task 2: Frontend — Vacant card rendering (essentials)
**Commit:** `3e2f8e3`

- `classify.js`: Removed `if (pol?.first_name === "VACANT") return { tier: "Hidden", group: "Vacant" }` — the legacy hack that hid vacant-named entries. Vacant offices now classify normally based on `district_type`/`office_title`.
- `Results.jsx`: Removed `list.filter((p) => p?.first_name !== 'VACANT')` filter. Added vacant card branch in `renderPoliticianCard`: when `pol.is_vacant === true`, renders `PoliticianCard` with `name="Vacant"`, `badge="Vacant"`, `imageSrc={undefined}`, `onClick={undefined}`, wrapped in a `div` with `opacity: 0.55`. Updated dedup key to include `pol.is_vacant || false` to prevent vacant/filled collisions.

### Task 3: SQL migration script
**Commit:** `7cd4527`

Created `EV-Backend/scripts/apply_noem_vacancy.sql`:
- Transactional PL/pgSQL block with row count safety checks
- Sets `essentials.politicians.is_active = false` for Kristi Noem
- Sets `essentials.offices.is_vacant = true, vacant_since = '2025-01-20'` for her DHS Secretary seat
- Verification SELECT at end
- Must be run manually after deploying backend migration

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing is_active filter in fetchFederalAndStateFromDBFiltered**
- **Found during:** Task 1
- **Issue:** The plan notes mentioned `fetchFederalAndStateFromDBFiltered` had NO `is_active` filter at all. During implementation, confirmed this: the original query had no `is_active` filter in the WHERE clause. The new `AND (p.is_active = true OR o.is_vacant = true)` also fixes this pre-existing omission.
- **Fix:** Added `AND (p.is_active = true OR o.is_vacant = true)` which correctly filters inactive politicians while still showing vacant offices.
- **Files modified:** `EV-Backend/internal/essentials/handlers.go`
- **Commit:** `3e49070`

**2. [Rule 3 - Blocking] Fixed PoliticianID pointer usage in staging/handlers.go**
- **Found during:** Task 1 build check
- **Issue:** `internal/staging/handlers.go:1676` constructed an `essentials.Office{}` with `PoliticianID: pol.ID` (non-pointer), which broke after `PoliticianID` became `*uuid.UUID`.
- **Fix:** Introduced `polIDPtr := pol.ID` and used `PoliticianID: &polIDPtr`.
- **Files modified:** `EV-Backend/internal/staging/handlers.go`
- **Commit:** `3e49070`

## Success Criteria Check

- [x] Office model has `is_vacant` (bool) and `vacant_since` (*time.Time) — GORM AutoMigrate adds columns on next server start
- [x] PoliticianID on Office is nullable (*uuid.UUID)
- [x] All three query paths (fetchOfficialsFromDB, fetchFederalAndStateFromDBFiltered, FindPoliticiansByGeoMatches) return vacant offices
- [x] OfficialOut.IsVacant sourced from Office.IsVacant
- [x] Frontend renders vacant offices with dimmed styling (opacity 0.55), "Vacant" badge, no click handler
- [x] Frontend no longer filters by first_name === 'VACANT'
- [x] SQL script ready to apply Kristi Noem vacancy
- [x] Go backend builds without errors
- [x] React frontend builds without errors

## Deployment Notes

1. Deploy backend — AutoMigrate adds `is_vacant` and `vacant_since` columns to `essentials.offices`
2. Run `psql $DATABASE_URL -f scripts/apply_noem_vacancy.sql` against production DB
3. After migration: searching a DC-area address will show "Secretary of Homeland Security" as a dimmed Vacant card; Kristi Noem will not appear as a filled card

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `EV-Backend/scripts/apply_noem_vacancy.sql` | FOUND |
| `.planning/quick/4-.../4-SUMMARY.md` | FOUND |
| Commit `3e49070` (backend vacancy fields + queries) | FOUND |
| Commit `3e2f8e3` (frontend vacant card rendering) | FOUND |
| Commit `7cd4527` (Noem SQL script) | FOUND |
| `go build -o /dev/null .` | PASS |
| `npm run build` (essentials) | PASS |
