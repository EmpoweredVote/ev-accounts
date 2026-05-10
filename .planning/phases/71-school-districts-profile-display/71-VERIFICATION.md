---
phase: 71-school-districts-profile-display
verified: 2026-05-10T20:07:19Z
status: passed
score: 10/10 must-haves verified
---

# Phase 71: School Districts + Profile Display — Verification Report

**Phase Goal:** California school district TIGER polygons (unified, elementary, secondary) live in `essentials.geo_districts`, every authenticated user sees their resolved school district by name on a new Location tab on `login.empowered.vote/profile` (with a Google search link), and the Path 0 representatives feed is forward-wired to surface school board members in the main "All" feed once a future ingestion phase populates `essentials.politicians`.

**Verified:** 2026-05-10T20:07:19Z
**Status:** passed
**UAT:** Human-approved on live site (login.empowered.vote/profile) prior to verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | School district TIGER layers are wired into `resolve_user_districts` and `cache_user_districts` defaults | VERIFIED | Migration 093 confirms default p_layers array includes `school_unified`, `school_elementary`, `school_secondary` in both RPCs |
| 2 | Seed script imports TIGER 2024 school shapefiles using `NAME` (not `NAMELSAD`) | VERIFIED | `seed-tiger-school-districts.sh` uses `NAME AS name` in all three ogr2ogr SQL selects |
| 3 | `/account/school-district` endpoint exists with pool.query and correct layer filter | VERIFIED | `account.ts` line 785 has `router.get('/school-district'` with `pool.query` filtering `ud.layer IN ('school_unified', 'school_elementary', 'school_secondary')` |
| 4 | `essentials.ts` layerTypeMap forward-wires school layers for Path 0 rep feed | VERIFIED | `school_unified`, `school_elementary`, `school_secondary` mapped to `SCHOOL_UNIFIED`, `SCHOOL_ELEMENTARY`, `SCHOOL_SECONDARY` with Phase 71 forward-compat comments |
| 5 | `SchoolDistrictSection` component exists with Google search link via `encodeURIComponent` | VERIFIED | Component defined at line 488 of `ProfilePage.tsx`; `makeLink` builds `https://www.google.com/search?q=${encodeURIComponent(label)}` |
| 6 | `'location'` tab exists in `activeTab` union type | VERIFIED | `useState<'profile' \| 'location' \| 'referrals' \| 'posts' \| 'contributor'>('profile')` at line 557 |
| 7 | Profile fetches both `/account/districts` and `/account/school-district` with `.catch(() => {})` | VERIFIED | Both fetches present at lines 578-583 with explicit catch; also re-fetched after location update at lines 646-647 |
| 8 | `city_council_district_name` in MeResponse type and rendered in Location tab | VERIFIED | In interface at line 39, rendered conditionally at line 954-960 |
| 9 | `force: true` in location update POST body | VERIFIED | Line 639: `body: JSON.stringify({ address: address.trim(), force: true })` |
| 10 | Migration 094 drops the old 3-arg `cache_user_districts` overload | VERIFIED | `20260510000000_094_drop_old_cache_user_districts_3arg.sql` exists with `DROP FUNCTION IF EXISTS essentials.cache_user_districts(uuid, double precision, double precision)` |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/migrations/20260509000004_093_extend_cache_user_districts_school_layers.sql` | Extends default p_layers to 6 layers including school types | VERIFIED | 73 lines; both `resolve_user_districts` and `cache_user_districts` updated |
| `scripts/seed-tiger-school-districts.sh` | Imports UNSD/ELSD/SCSD from TIGER 2024 using NAME column | VERIFIED | 117 lines; idempotent ON CONFLICT DO UPDATE; spot-check query included |
| `backend/src/routes/account.ts` | `GET /school-district` endpoint | VERIFIED | Lines 785-800+; pool.query with JOIN to geo_districts for name lookup |
| `backend/src/routes/essentials.ts` | layerTypeMap school entries | VERIFIED | 3 entries with forward-compat comments |
| `admin/src/pages/ProfilePage.tsx` | SchoolDistrictSection + Location tab | VERIFIED | Component at line 488; tab in union type at line 557; rendered at line 964 |
| `supabase/migrations/20260510000000_094_drop_old_cache_user_districts_3arg.sql` | Drops ambiguous 3-arg overload | VERIFIED | 1-line DROP FUNCTION; fixes "function is not unique" production bug |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ProfilePage.tsx` | `/account/school-district` | `apiFetch` | WIRED | Fetched on load (line 581) and after location update (line 647) |
| `ProfilePage.tsx` | `SchoolDistrictSection` | `schoolDistrict` state | WIRED | State set from fetch result; component renders at line 964 |
| `SchoolDistrictSection` | Google Search | `encodeURIComponent` + district name | WIRED | `makeLink` builds full URL and returns anchor element |
| `cache_user_districts` (4-arg) | school layer rows | default p_layers | WIRED | Migration 093 updated default; migration 094 drops ambiguous 3-arg overload |
| `essentials.ts` layerTypeMap | future school board reps | `school_*` → `SCHOOL_*` district_type | WIRED | Forward-compat; Path 0 query will surface school board members once politicians seeded |

### Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| GEO-13: School districts imported from TIGER 2024 | SATISFIED | Migration 093 + seed script cover import, RPC extension, and layer wiring |
| GEO-14: School districts surface on profile | SATISFIED | Location tab, SchoolDistrictSection, `/account/school-district` endpoint all verified |

### Anti-Patterns Found

None. No TODO/FIXME/placeholder patterns in verified files. School district endpoint and component have real implementations with DB queries and rendered JSX.

### Human Verification

UAT already completed by human on live site (`login.empowered.vote/profile`) prior to this verification run. No further human testing required.

## Gaps Summary

No gaps. All 10 must-haves pass at all three verification levels (exists, substantive, wired). Phase 71 goal is fully achieved in the codebase.

---

_Verified: 2026-05-10T20:07:19Z_
_Verifier: Claude (gsd-verifier)_
