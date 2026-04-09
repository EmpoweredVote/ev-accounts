---
phase: quick-014
plan: "01"
subsystem: jurisdiction
tags: [city-council, jurisdiction, postgis, connected-profiles, dashboard]

dependency_graph:
  requires:
    - "Migration 045: resolve_user_jurisdiction base RPC"
    - "Migration 046: resolve_user_local_officials (X% MTFCC pattern reference)"
    - "essentials.geofence_boundaries + districts with LOCAL type rows"
  provides:
    - "city_council_geo_id + city_council_district_name columns on connected_profiles"
    - "resolve_user_jurisdiction returns city_council + city_council_name keys"
    - "GET /api/account/me jurisdiction block includes city_council fields"
    - "GET /api/account/me/jurisdiction includes city_council fields"
    - "POST /api/connect/set-location writes + returns city_council fields"
    - "DashboardPage Connected Spaces shows City Council as first (most prominent) row"
  affects:
    - "Civic Spaces integration (can now target ward/district level)"
    - "Essentials representatives: local officials matching context"

tech_stack:
  added: []
  patterns:
    - "Sub-city MTFCC preference: X% before G4040/G4110/G4120 via ORDER BY CASE"
    - "LIMIT 1 over MAX() FILTER for single-row local district resolution"

key_files:
  created:
    - backend/migrations/047_add_city_council_district_columns.sql
  modified:
    - backend/src/routes/account.ts
    - backend/src/routes/connect.ts
    - app/src/pages/DashboardPage.tsx

decisions:
  - "Sub-city preference: ORDER BY CASE WHEN mtfcc LIKE 'X%' THEN 0 ELSE 1 END, d.geo_id — prefers ward/district boundaries over city-wide G4040 boundaries. Deterministic via geo_id tiebreak."
  - "City Council placed first in DISTRICT_LABELS — most local level = most prominent in 'Your Connected Spaces'"
  - "city_council guard NOT added to the congressional_geo_id || state_senate_geo_id check — city council alone should not trigger jurisdiction display if core federal/state districts are missing"
  - "Backfill run in-migration: 9 users updated. WHERE city_council_geo_id IS NULL makes it idempotent."

metrics:
  duration: "~6 minutes"
  completed: "2026-04-09"
  tasks_completed: 3
  tasks_total: 3
---

# Quick Task 014: Add City Council District to Jurisdiction — Summary

**One-liner:** City council district stored in connected_profiles, returned in all jurisdiction API responses, and surfaced as the first row in the DashboardPage Connected Spaces section.

## What Was Done

City council is the most local elected race most users vote in. This task adds full pipeline support: database storage, RPC resolution, API exposure, and frontend display.

### Task 1: Migration (commit 13d9e34)

Created `backend/migrations/047_add_city_council_district_columns.sql` with three sections:

**Section 1 — Columns:** `ALTER TABLE connect.connected_profiles ADD COLUMN IF NOT EXISTS city_council_geo_id TEXT, city_council_district_name TEXT`

**Section 2 — RPC extension:** `CREATE OR REPLACE connect.resolve_user_jurisdiction` adds a second PostGIS query after the existing SELECT...INTO block. Selection logic uses `ORDER BY CASE WHEN mtfcc LIKE 'X%' THEN 0 ELSE 1 END, d.geo_id LIMIT 1` to prefer sub-city ward boundaries over city-wide boundaries, with a deterministic geo_id tiebreak.

**Section 3 — Backfill:** `UPDATE connect.connected_profiles ... WHERE city_council_geo_id IS NULL` — updated 9 users.

Verification: RPC for an LA user returns `"city_council": "ocd-division/country:us/state:ca/county:los_angeles/council_district:2"`.

### Task 2: Backend routes (commit 92b879c)

Updated three pool.query calls in `account.ts`:
- GET /me: type annotation, SELECT, and response mapping
- GET /me/jurisdiction: type annotation, SELECT, and response mapping
- PATCH /me: type annotation, SELECT, and response mapping

Updated `connect.ts` set-location handler:
- UPDATE query extended to `$14` (city_council_geo_id) and `$15` (city_council_district_name)
- Response JSON includes `city_council_district` and `city_council_district_name`

TypeScript: `npx tsc --noEmit` — clean.

### Task 3: Frontend (commit 4dc506b)

`DashboardPage.tsx`:
- `Jurisdiction` interface: added `city_council_district_name: string | null`
- `DISTRICT_LABELS`: added `{ key: 'city_council_district_name', label: 'City Council' }` at position 0
- Existing `filter+map` rendering picks it up automatically when non-null

Vite build: `built in 1.04s` — clean.

## Decisions Made

| Decision | Rationale |
|---|---|
| Sub-city preference via ORDER BY CASE | A user in LA District 2 should see "District 2" not "City of Los Angeles". X% MTFCC boundaries are actual ward boundaries; G4040 is the city boundary. |
| City Council first in DISTRICT_LABELS | Most local = most proximate representative identity. Mirrors the product goal of surfacing the closest civic connection. |
| No city_council guard in /me | The `congressional_geo_id \|\| state_senate_geo_id` guard remains unchanged — city_council alone shouldn't trigger the jurisdiction block if federal/state data is absent. |
| LIMIT 1 instead of MAX() FILTER | City council requires tiebreaking logic (X% priority) that MAX() can't express. Separate SELECT...INTO with ORDER BY + LIMIT 1 is cleaner and correct. |

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

| Check | Result |
|---|---|
| `city_council_geo_id`, `city_council_district_name` columns exist | 2 rows in information_schema |
| Backfill: users with location_consent | 9 users updated, 3 spot-checked with non-null values |
| RPC includes new keys | `"city_council": "ocd-division/.../council_district:2", "city_council_name": "District 2"` |
| `npx tsc --noEmit` | Pass |
| `npx vite build` | Pass (1.04s) |
