---
phase: 19-location-schema-rpcs
plan: 02
subsystem: infra
tags: [postgis, tiger-line, ogr2ogr, supabase-vault, runbook]

requires:
  - phase: 19-01
    provides: Migration 031 creates inform.district_boundaries table, Migration 032 creates connect.upsert_user_location and connect.resolve_user_jurisdiction RPCs

provides:
  - docs/RUNBOOK-TIGER-LOAD.md: complete operator guide for Vault secret creation, 5 ogr2ogr loads, post-load verification, and RPC smoke tests

affects: [19-03-apply-verify, 20-location-endpoints]

tech-stack:
  added: []
  patterns: [ogr2ogr shapefile-to-PostGIS load pattern with PROMOTE_TO_MULTI and EPSG:4269→4326 reprojection]

key-files:
  created:
    - docs/RUNBOOK-TIGER-LOAD.md
  modified: []

key-decisions:
  - "Vault secret created via vault.create_secret() — not in migration (would embed key in git history)"
  - "County load uses -sql with WHERE STATEFP='18' inside the clause — not standalone -where (mutually exclusive with -sql in ogr2ogr)"
  - "PROMOTE_TO_MULTI required — TIGER/Line may include MultiPolygon features for non-contiguous districts"
  - "SRID reprojection 4269→4326 via ogr2ogr flags — not a post-load UPDATE"
  - "Bloomington smoke test expected GEOID '1809' for Indiana 9th Congressional District"
  - "ST_MakePoint uses (longitude, latitude) order — runbook makes this explicit to prevent common reversal error"

patterns-established:
  - "Runbook structure: prerequisites → secret creation → data download → data load → post-load verification → RPC smoke tests → troubleshooting"

duration: 2 minutes (18:43Z → 18:46Z)
completed: 2026-03-10
---

# Plan 19-02: TIGER/Line Runbook Summary

**Complete copy-paste-ready operator guide for loading Indiana TIGER/Line 2024 shapefiles into `inform.district_boundaries` via ogr2ogr with full Vault secret, verification, and RPC smoke test coverage.**

## Accomplishments

- Created `docs/RUNBOOK-TIGER-LOAD.md` — full operator guide covering all execution steps for the TIGER/Line data load
- Documented Vault secret creation as Step 1 (before any RPC), with both SQL and Dashboard UI options
- Provided download commands and Census Bureau URLs for all 5 Indiana TIGER/Line 2024 archives
- Wrote 5 verbatim ogr2ogr commands with all required flags (PROMOTE_TO_MULTI, EPSG reprojection, schema/geometry column lco)
- County command correctly uses WHERE inside -sql clause (documents the mutually exclusive -where/-sql footgun)
- Post-load verification: SRID check, row counts by district type with Indiana-specific expected values (9 CD, 50 senate, 100 house, 92 counties), and Bloomington point-in-polygon smoke test with GEOID '1809'
- RPC smoke tests for both RPCs: upsert confirms bytea ciphertext storage, resolve confirms GEOID JSON output with no raw coordinate values
- Troubleshooting section for the 4 most likely failure modes

## Task Commits

1. **Task 1: Write docs/RUNBOOK-TIGER-LOAD.md** — `59e8505`

**Plan metadata:** `[see final commit]`

## Files Created/Modified

- `docs/RUNBOOK-TIGER-LOAD.md` — 332-line operator guide: Vault secret (Step 1), 5 ogr2ogr commands (Step 3), post-load SQL verification (Step 4), RPC smoke tests (Step 5), 4-item troubleshooting section

## Decisions Made

- Vault secret creation documented as Step 1 explicitly before data load steps — runbook ordering enforces the prerequisite
- `openssl rand -base64 32` shown as the key generation command with example output — no ambiguity about key format
- County `-sql` approach documented with an explicit note that `-where` and `-sql` are mutually exclusive — this is a non-obvious ogr2ogr gotcha that would cause silent data corruption (loading all US counties) or a command rejection
- Troubleshooting covers both the "0 county rows" and "3,200 county rows" failure modes for that same flag error

## Deviations from Plan

None — plan executed exactly as written.
