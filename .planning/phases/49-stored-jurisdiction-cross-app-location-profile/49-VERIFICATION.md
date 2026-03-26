---
phase: 49-stored-jurisdiction-cross-app-location-profile
verified: 2026-03-26T00:00:00Z
status: passed
score: 5/5 must-haves verified
---

# Phase 49: Stored Jurisdiction Cross-App Location Profile — Verification Report

**Phase Goal:** Connected users' district GEO IDs are stored on `connected_profiles` at set-location time and returned on `/api/account/me` — every app that already calls `/account/me` can read the user's jurisdiction without asking for their address again. `home_address` is not stored for Connected tier.
**Verified:** 2026-03-26
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | set-location writes 5 GEO IDs + 5 _name fields + state + city to connected_profiles; does NOT write home_address | VERIFIED | connect.ts lines 574-608: pool.query UPDATE writes all 12 columns. No home_address write in set-location handler (only enrollment schema at line 56 references it). |
| 2 | GET /account/me returns jurisdiction from stored columns (not RPC) | VERIFIED | account.ts lines 104-152: pool.query SELECT on 12 stored columns, location_consent guard, nulled when not populated. Zero resolve_user_jurisdiction matches in file. |
| 3 | GET /account/me/jurisdiction and PATCH /account/me also read stored columns, not RPC | VERIFIED | account.ts lines 241-305 and 455-491: both routes use identical pool.query pattern on stored columns. resolve_user_jurisdiction absent from entire file. |
| 4 | /representatives/me Path 1 reads stored GEO IDs — no resolve_user_jurisdiction RPC | VERIFIED | essentials.ts lines 327-363: pool.query on congressional_geo_id through jurisdiction_city; X-Formatted-Address uses [city, state].filter(Boolean).join(', ') with homeAddress fallback. resolve_user_jurisdiction absent. |
| 5 | Read & Rank AuthState has jurisdictionState from /account/me; CTC AccountProfile has full jurisdiction type | VERIFIED | useAuthState.ts: jurisdictionState: string | null in interface, populated from data.jurisdiction?.state ?? null at all 5 setState call sites. CTC auth.ts: 12-field jurisdiction?: {...} | null on AccountProfile. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/src/lib/geocodingService.ts` | city in return type | VERIFIED | Line 71: return type includes city: string. Line 139: city extracted from addressComponents. Line 142: cached. Line 144: returned. |
| `backend/src/routes/connect.ts` | GEO ID + _name writes at set-location | VERIFIED | Lines 574-608: 12-column UPDATE, try/catch wrapper, state+city in response. |
| `backend/src/routes/account.ts` | Jurisdiction from column read (all 3 routes) | VERIFIED | GET /me (lines 104-152), GET /me/jurisdiction (lines 241-305), PATCH /me (lines 455-491) all use pool.query. |
| `backend/src/routes/essentials.ts` | Stored GEO ID lookup for /representatives/me | VERIFIED | Lines 329-363: pool.query on stored columns, no RPC, X-Formatted-Address from stored fields. |
| `supabase/migrations/20260326000053_phase49_jurisdiction_columns.sql` | 12 ADD COLUMN IF NOT EXISTS statements | VERIFIED | Migration file present. All 12 columns defined (congressional_geo_id, congressional_district_name, state_senate_geo_id, state_senate_district_name, state_house_geo_id, state_house_district_name, county_geo_id, county_name, school_district_geo_id, school_district_name, jurisdiction_state, jurisdiction_city). 49-01 SUMMARY confirms 12/12 verified in production. |
| `C:/read-rank/src/hooks/useAuthState.ts` | jurisdictionState in AuthState | VERIFIED | jurisdictionState: string | null in interface; populated from data.jurisdiction?.state ?? null; null in all fallback paths. |
| `C:/Project Test/frontend/src/types/auth.ts` | jurisdiction on AccountProfile | VERIFIED | Lines 24-37: jurisdiction?: { congressional_district, congressional_district_name, state_senate_district, state_senate_district_name, state_house_district, state_house_district_name, county, county_name, school_district, school_district_name, state, city } | null |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| connect.ts set-location | connect.connected_profiles | pool.query UPDATE 12 columns | WIRED | Lines 574-608: parameterized UPDATE writes all 5 GEO IDs, 5 _name fields, jurisdiction_state, jurisdiction_city from geocodeAddress + resolve_user_jurisdiction result |
| account.ts GET /me | connect.connected_profiles | pool.query SELECT jurisdiction columns | WIRED | Lines 122-131: SELECT all 12 columns WHERE user_id = $1; result mapped to jurisdiction response object |
| account.ts GET /me/jurisdiction | connect.connected_profiles | pool.query SELECT jurisdiction columns | WIRED | Lines 273-282: same SELECT pattern; returns full jurisdiction shape |
| account.ts PATCH /me | connect.connected_profiles | pool.query SELECT jurisdiction columns | WIRED | Lines 467-476: same SELECT pattern in PATCH response construction |
| essentials.ts /representatives/me | getRepresentativesByJurisdiction | stored GEO IDs from pool.query | WIRED | Lines 338-352: SELECT 5 GEO IDs + state/city; passed directly to getRepresentativesByJurisdiction |
| useAuthState.ts | /api/account/me | apiFetch jurisdictionState extraction | WIRED | data.jurisdiction?.state ?? null at success setState call site |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| backend/src/routes/essentials.ts | 365 | Stale comment: "no encrypted coordinates" (should be "no stored GEO IDs") | Info | Comment only — does not affect behavior |

No blockers. No stub patterns. No TODO/FIXME in modified files.

### TypeScript Compilation

`npx tsc --noEmit` from `backend/` directory: clean (no output, exit 0).

### Human Verification Required

None — all functional requirements are verifiable via static analysis. The DB columns' presence in production is supported by: (1) the migration file with correct SQL, (2) 49-01 SUMMARY stating 12/12 columns confirmed via Supabase MCP execute_sql query during plan execution.

If desired, re-run the following SQL against project `kxsdzaojfaibhuzmclfq` to confirm production state:

```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'connect' AND table_name = 'connected_profiles'
AND column_name IN (
  'congressional_geo_id', 'congressional_district_name',
  'state_senate_geo_id', 'state_senate_district_name',
  'state_house_geo_id', 'state_house_district_name',
  'county_geo_id', 'county_name',
  'school_district_geo_id', 'school_district_name',
  'jurisdiction_state', 'jurisdiction_city'
);
```
Expected: 12 rows.

## Summary

Phase 49 goal achieved. All five must-have truths verified against actual code:

- **geocodingService** returns `city` from Census `addressComponents.city`
- **set-location** writes all 12 jurisdiction columns at location-set time with a non-fatal try/catch; no `home_address` write
- **account.ts** (all 3 routes) reads jurisdiction entirely from stored columns via `pool.query`; `resolve_user_jurisdiction` is absent from the file
- **essentials.ts** Path 1 reads stored GEO IDs directly; `resolve_user_jurisdiction` absent
- **Read & Rank** and **CTC** consumer types updated and wired to the new fields

The architecture shift from per-request RPC to stored-column reads is complete end-to-end across the schema, API, and consumer layers.

---

_Verified: 2026-03-26_
_Verifier: Claude (gsd-verifier)_
