---
phase: 19-location-schema-rpcs
plan: 01
subsystem: database
tags: [postgres, postgis, pgcrypto, supabase-vault, migrations]

requires:
  - phase: 17-live-alpha-deployment
    provides: PostGIS and pgcrypto extensions enabled in production

provides:
  - connect.connected_profiles gains encrypted_lat, encrypted_lng, location_consent, location_set_at columns
  - inform.district_boundaries table with geometry(MultiPolygon,4326), GIST spatial index, btree type index
  - connect.upsert_user_location SECURITY DEFINER RPC (encrypt + write coords + set consent)
  - connect.resolve_user_jurisdiction SECURITY DEFINER RPC (decrypt + ST_Covers + return jurisdiction JSON)

affects: [20-location-endpoints, 19-03-apply-verify]

tech-stack:
  added: []
  patterns: [SECURITY DEFINER with SET search_path and extensions. prefix for all pgcrypto/PostGIS calls]

key-files:
  created:
    - backend/migrations/031_location_schema.sql
    - backend/migrations/032_location_rpcs.sql
    - supabase/migrations/20260310000031_location_schema.sql
    - supabase/migrations/20260310000032_location_rpcs.sql
  modified: []

key-decisions:
  - "extensions.pgp_sym_encrypt_bytea / pgp_sym_decrypt_bytea — SET search_path = '' requires extensions. prefix"
  - "extensions.ST_Covers / ST_MakePoint / ST_SetSRID — PostGIS also in extensions schema"
  - "ST_MakePoint(v_lng, v_lat) — longitude first per PostGIS X/Y convention"
  - "bytea→text→float8 decode chain for pgp_sym_decrypt_bytea output"
  - "5-key jsonb return: congressional, state_senate, state_house, county, school_district — no raw coordinates"
  - "Vault secret created in runbook, not migration — embedding key in migration history is a security anti-pattern"

patterns-established:
  - "Location RPC pattern: Vault key fetch → validate → encrypt/decrypt with extensions. prefix"

duration: ~3 minutes
completed: 2026-03-10
---

# Plan 19-01: Location Schema Migrations Summary

**Four SQL migration files establishing encrypted coordinate storage (pgcrypto AES-256 via Supabase Vault) and PostGIS jurisdiction resolution (ST_Covers against TIGER/Line district boundaries) for Indiana Alpha.**

## Accomplishments

- Migration 031 adds 4 columns to `connect.connected_profiles` for encrypted coordinate storage and consent tracking, creates `inform.district_boundaries` with `geometry(MultiPolygon, 4326)`, a GIST spatial index, a btree district_type index, and RLS authenticated read policy.
- Migration 032 creates two SECURITY DEFINER RPCs: `connect.upsert_user_location` (validates, fetches Vault key, encrypts with `extensions.pgp_sym_encrypt_bytea`, atomic UPDATE with `location_consent = true`) and `connect.resolve_user_jurisdiction` (Vault key fetch, `pgp_sym_decrypt_bytea` with `bytea→text→float8`, `extensions.ST_MakePoint(lng, lat)`, `extensions.ST_Covers`, 5-key jsonb return with no raw coordinates).
- Both migrations provided in `backend/migrations/` (no transaction wrapper, applied via psql directly) and `supabase/migrations/` (BEGIN/COMMIT wrapper for local dev).

## Task Commits

1. **Task 1: Migration 031** — `73fde9f`
2. **Task 2: Migration 032** — `9dd4949`

## Files Created/Modified

- `backend/migrations/031_location_schema.sql` — ADD COLUMN encrypted_lat/lng/location_consent/location_set_at + CREATE TABLE inform.district_boundaries + GIST/btree indexes + RLS
- `backend/migrations/032_location_rpcs.sql` — connect.upsert_user_location + connect.resolve_user_jurisdiction RPCs
- `supabase/migrations/20260310000031_location_schema.sql` — same as 031 with BEGIN/COMMIT wrapper
- `supabase/migrations/20260310000032_location_rpcs.sql` — same as 032 with BEGIN/COMMIT wrapper

## Decisions Made

- **Vault key in runbook, not migration** — creating the secret inside a migration would permanently embed the encryption key in migration history. The runbook (RUNBOOK-TIGER-LOAD.md) creates it separately via Supabase dashboard or CLI.
- **`location_set_at` column included proactively** — the plan's task description mentioned it as needed by the RPC even though LOC-01 didn't explicitly list it; included to avoid a follow-up migration.
- All decisions otherwise followed the plan specification exactly.

## Deviations from Plan

None — plan executed exactly as written. The `location_set_at` inclusion was anticipated in the task notes ("Note: The `location_set_at` column is included here even though LOC-01 doesn't explicitly list it").

## Next Phase Readiness

- Migration files ready for apply in Plan 19-03 (apply & verify runbook)
- Phase 20 Location Endpoints can reference `connect.upsert_user_location` and `connect.resolve_user_jurisdiction` once 19-03 confirms the migrations are applied to production
