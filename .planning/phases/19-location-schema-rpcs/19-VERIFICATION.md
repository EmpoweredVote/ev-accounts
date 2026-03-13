---
phase: 19-location-schema-rpcs
verified: 2026-03-13T00:41:59Z
status: passed
score: 5/5 must-haves verified
gaps: []
---

# Phase 19: Location Schema & RPCs Verification Report

**Phase Goal:** Encrypted coordinates can be written and read via SECURITY DEFINER RPCs, and Indiana TIGER/Line district boundaries are loaded and queryable via PostGIS.
**Verified:** 2026-03-13T00:41:59Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | upsert_user_location writes bytea ciphertext — direct DB inspection confirms no plaintext floats | VERIFIED | backend/migrations/032_location_rpcs.sql uses extensions.pgp_sym_encrypt_bytea(p_lat::text::bytea, v_key, 'cipher-algo=aes256') writing to encrypted_lat/encrypted_lng bytea columns; human smoke-test in plan 19-03 confirmed hex ciphertext output |
| 2 | resolve_user_jurisdiction returns GEOID '1809' for Bloomington, IN | VERIFIED | convert_from(extensions.pgp_sym_decrypt_bytea(...), 'UTF8')::float8 decrypt chain is correct; extensions.ST_Covers against inform.district_boundaries with SRID 4326; human smoke-test confirmed {"congressional": "1809", ...} |
| 3 | ST_Covers queries return correct Monroe County districts for Bloomington | VERIFIED | TIGER/Line data load confirmed by human operator (9 CD, 50 state_senate, 100 state_house, 92 county, 200+ school_district rows); RUNBOOK Step 4 Query 3 smoke-test confirmed 5 rows for Bloomington |
| 4 | Raw coordinates never appear in resolve_user_jurisdiction return value | VERIFIED | RPC returns jsonb_build_object with 5 district-type keys only; v_lat/v_lng are local DECLARE variables, never referenced in RETURN |
| 5 | TIGER/Line data load runbook documents ogr2ogr flags, Indiana FIPS filter, SRID reprojection 4269->4326, and post-load SRID verification query | VERIFIED | docs/RUNBOOK-TIGER-LOAD.md Step 3 has all 5 ogr2ogr commands with -s_srs EPSG:4269 -t_srs EPSG:4326, -nlt PROMOTE_TO_MULTI, county command uses -sql with WHERE STATEFP='18' inside the clause; Step 4 Query 1 is SELECT DISTINCT ST_SRID(geom) |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| backend/migrations/031_location_schema.sql | Schema columns + district_boundaries table | VERIFIED | 75 lines; adds 4 columns to connect.connected_profiles, creates inform.district_boundaries with geometry(MultiPolygon, 4326), GIST + btree indexes, RLS via DO block workaround |
| backend/migrations/032_location_rpcs.sql | Two SECURITY DEFINER RPCs | VERIFIED | 157 lines; upsert_user_location and resolve_user_jurisdiction both present with all post-execution bug fixes applied (public.geometry, convert_from, extensions.ST_*) |
| docs/RUNBOOK-TIGER-LOAD.md | Operator runbook for TIGER/Line load | VERIFIED | 333 lines; 5 steps (Vault secret, download, load, post-load verification, RPC smoke tests) plus troubleshooting section covering 4 failure modes |
| supabase/migrations/20260310000031_location_schema.sql | Supabase-wrapped mirror of 031 | PARTIAL | Has CREATE POLICY IF NOT EXISTS (line 56) — the unfixed syntax. Fails on Postgres 17.4 in local dev. Production not affected (backend migration is authoritative). |
| supabase/migrations/20260310000032_location_rpcs.sql | Supabase-wrapped mirror of 032 | PARTIAL | Has bare geometry (not public.geometry) on line 102 of the DECLARE block. Fails on local dev with SET search_path = ''. Production not affected. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| upsert_user_location | vault.decrypted_secrets | SELECT decrypted_secret WHERE name = 'location_encryption_key' | WIRED | Present in function body |
| upsert_user_location | connect.connected_profiles | UPDATE ... SET encrypted_lat/lng | WIRED | UPDATE with IF NOT FOUND RAISE EXCEPTION guard |
| resolve_user_jurisdiction | vault.decrypted_secrets | SELECT decrypted_secret WHERE name = 'location_encryption_key' | WIRED | Present in function body |
| resolve_user_jurisdiction | connect.connected_profiles | SELECT encrypted_lat, encrypted_lng WHERE location_consent = true | WIRED | Includes consent check; raises exception if NULL |
| resolve_user_jurisdiction | inform.district_boundaries | ST_Covers(geom, v_point) | WIRED | FROM inform.district_boundaries WHERE extensions.ST_Covers(geom, v_point) with MAX(geoid) FILTER aggregation |
| Decrypt chain | float8 output | convert_from(pgp_sym_decrypt_bytea(...), 'UTF8')::float8 | WIRED | Correct fix applied — not ::text::float8 which would produce hex repr |
| Geometry point | SRID 4326 | extensions.ST_SetSRID(extensions.ST_MakePoint(v_lng, v_lat), 4326) | WIRED | Longitude-first ordering correct; SRID matches table definition |

---

### Requirements Coverage

No separate REQUIREMENTS.md for v1.3 assessed here. All 5 phase-level success criteria map directly to the 5 verified truths above.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| supabase/migrations/20260310000031_location_schema.sql | 56 | CREATE POLICY IF NOT EXISTS — unsupported on Postgres 17.4 | Warning | Local dev supabase db reset will fail on this migration; production unaffected |
| supabase/migrations/20260310000032_location_rpcs.sql | 102 | Bare geometry type in DECLARE with SET search_path = '' | Warning | Local dev supabase db reset will fail with type "geometry" does not exist; production unaffected |

Neither anti-pattern blocks the phase goal. Both are local-dev parity gaps. The 19-03 SUMMARY states that supabase/migrations/20260310000032_location_rpcs.sql received the same fixes as the backend file, but the actual file on disk still has bare geometry on line 102. This is a discrepancy between the summary claim and the file state — the fix was either not applied or was applied to a different path.

---

### Human Verification Completed (Plan 19-03 Checkpoint)

The following were confirmed by human DB inspection during plan 19-03 execution:

1. **Bytea ciphertext storage** — encrypted_lat column returned hex ciphertext, not the plaintext float 39.1653.
2. **Jurisdiction resolution** — resolve_user_jurisdiction returned {"congressional": "1809", ...} with correct Monroe County GEOIDs.
3. **TIGER/Line row counts** — 9 congressional, 50 state_senate, 100 state_house, 92 county, 200+ school_district rows confirmed.
4. **No raw coordinates in return value** — JSON output contained only the 5 district-type keys with GEOID strings.

---

### Notable Finding: Supabase Mirror Divergence

The backend/migrations/ files (applied to production) are correct and fully patched. The supabase/migrations/ mirror files diverge in two places:

1. **031 supabase mirror** — still has CREATE POLICY IF NOT EXISTS (the original unfixed syntax). The backend 031 was patched to use a DO block checking pg_policies.
2. **032 supabase mirror** — still has bare geometry instead of public.geometry in the DECLARE block. The backend 032 was patched to use public.geometry.

These gaps will cause supabase db reset to fail for any developer setting up a local environment before Phase 20 development. Recommend patching both supabase mirror files before Phase 20 begins.

---

## Gaps Summary

No gaps blocking goal achievement. The phase goal — encrypted coordinate RPCs working and TIGER/Line boundaries queryable in production — is fully achieved and human-confirmed. The supabase mirror divergence is a local-dev parity issue, not a production correctness issue.

---

_Verified: 2026-03-13T00:41:59Z_
_Verifier: Claude (gsd-verifier)_
