# Phase 120: MA City Officials Seeding — Research

## ## RESEARCH COMPLETE

Researched via direct Supabase DB queries and review of migrations 578–622.

---

## Current State Summary

Migrations 578–592 (applied, in ledger) already seeded the COMPLETE government stack for all 7 cities.

| City | geo_id | Districts | Politicians | Offices | null_office_id | null_chamber_id | tiger_geoid |
|------|--------|-----------|-------------|---------|----------------|-----------------|-------------|
| Fall River | 2523000 | 2 ✅ | 10 ✅ | 10 ✅ | 0 ✅ | 0 ✅ | 2523000 ✅ |
| Lynn | 2537490 | 2 ✅ | 12 ✅ | 12 ✅ | 0 ✅ | 0 ✅ | 2537490 ✅ |
| Medford | 2539835 | 2 ✅ | 8 ✅ | 8 ✅ | 0 ✅ | 0 ✅ | 2539835 ✅ |
| New Bedford | 2545000 | 2 ✅ | 12 ✅ | 12 ✅ | 0 ✅ | 0 ✅ | 2545000 ✅ |
| Newton | 2545560 | 2 ✅ | 25 ✅ | 25 ✅ | 0 ✅ | 0 ✅ | **NULL ❌** |
| Somerville | 2562535 | 2 ✅ | 12 ✅ | 12 ✅ | 0 ✅ | 0 ✅ | 2562535 ✅ |
| Waltham | 2572600 | 2 ✅ | 16 ✅ | 16 ✅ | 0 ✅ | 0 ✅ | 2572600 ✅ |

**Total: 95 politicians across all 7 cities, 95 offices, all with office_id and chamber_id set.**

---

## The One Gap: Newton tiger_geoid = NULL

Migration 622 (`medford_fix_and_city_tiger_geoid_backfill`) backfilled `tiger_geoid = geo_id` for 6 cities (Somerville, Lynn, Medford, Fall River, Waltham, New Bedford) but explicitly excluded Newton. Newton's G4110 geofence exists and is valid (`essentials.geofence_boundaries WHERE geo_id='2545560' AND mtfcc='G4110'`).

**Fix:** One migration (~683) sets `tiger_geoid = '2545560'` on Newton's 2 district rows (LOCAL + LOCAL_EXEC) using the same `WHERE tiger_geoid IS NULL` guard pattern as migration 622.

---

## Council Structures (from migration headers — verified 2026-06-14)

| City | Mayor | At-Large | Ward | Total | Spelling |
|------|-------|----------|------|-------|---------|
| Newton | Mayor Marc C. Laredo | 16 (2 per ward) | 8 (1 per ward) | 25 | 'City Councilor' |
| Somerville | Mayor Jake Wilson | 4 | 7 | 12 | 'City Councilor' |
| Lynn | Mayor Jared Nicholson | 3 | 8 | 12 | 'City Councilor' |
| Fall River | Mayor Coogan | 0 | 9 at-large | 10 | 'City Councilor' |
| Waltham | Mayor Donahue | 6 | 9 | 16 | 'City Councillor' (double-L) |
| Medford | Mayor Breanna Lungo-Koehn | 2 | 6 | 8 | 'City Councilor' |
| New Bedford | Mayor Jon Mitchell | 3 | 8 | 12 | 'City Councilor' |

---

## Requirements Coverage Check

| Requirement | Status |
|-------------|--------|
| MAOF-01 Newton | ✅ Migration 578 applied (version '578' in ledger) |
| MAOF-02 Somerville | ✅ Migration 581 applied (version '581' in ledger) |
| MAOF-03 Lynn | ✅ Migration 584 applied (version '584' in ledger) |
| MAOF-04 Fall River | ✅ Migration 590 applied (version '590' in ledger) |
| MAOF-05 Waltham | ✅ Migration 592 applied (version '592' in ledger) |
| MAOF-06 Medford | ✅ Migration 591 applied + 622 geo_id fix |
| MAOF-07 New Bedford | ✅ Migration 587 applied |

---

## Success Criteria Evaluation

1. **Newton: district rows + politicians + office rows + migration applied** → ✅ migration 578
2. **Somerville: same** → ✅ migration 581
3. **Lynn/Fall River/Waltham/Medford/New Bedford: same** → ✅ migrations 584/590/592/591/587
4. **COUNT(offices) > 0 for every city** → ✅ 10–25 offices per city
5. **Zero NULL office_id on politicians; zero NULL chamber_id on offices** → ✅

**Only gap:** Newton `tiger_geoid = NULL` — not explicitly in Phase 120 success criteria, but it blocks Phase 123 (Ward Geofencing for Newton). Should be fixed in this phase to unblock Phase 123.

---

## District Structure Pattern (Tier 3)

All 7 cities use the same Tier 3 pattern:
- `district_type='LOCAL_EXEC'`: 1 row per city, geo_id = city FIPS, mtfcc=NULL (Mayor's district)
- `district_type='LOCAL'`: 1 row per city, geo_id = city FIPS, mtfcc=NULL (all councillors)
- No per-ward rows at this stage (those are Phase 123)
- `government_id = NULL` on all district rows — this is by design in the seeding pattern; routing uses geo_id+state, not government_id FK

---

## Migration Reference

- Existing patterns to follow: migrations 578, 581, 622
- Latest applied migration: 682 (`tseng_stances`)
- Next migration number: **687**

---

## What Phase 120 Plans Need to Do

Given existing work, Phase 120 is a lightweight "close the loop" phase:

1. **Plan 01 (migration 683)**: Newton tiger_geoid backfill — 4-line UPDATE, pre-flight + post-verification DO blocks following migration 622 pattern. Prerequisite for Phase 123 Newton ward geofencing.

2. **Plan 02 (phase gate verification)**: SQL assertions confirming all 7 cities satisfy MAOF-01..07 success criteria. Documents that migrations 578–592 + 622 + 683 collectively fulfill Phase 120.

---

## Validation Architecture

### Test Queries (for phase gate)

```sql
-- MAOF completeness per city: should return 7 rows with politicians > 0
SELECT g.city, g.geo_id,
       COUNT(DISTINCT o.id) AS offices,
       COUNT(DISTINCT p.id) AS politicians
FROM essentials.governments g
JOIN essentials.districts d ON d.geo_id = g.geo_id AND d.state = 'ma'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE g.state = 'MA'
  AND g.city IN ('Newton','Somerville','Lynn','Fall River','Waltham','Medford','New Bedford')
GROUP BY g.id, g.city, g.geo_id
ORDER BY g.city;
-- Expected: 7 rows, all offices >= 8, all politicians >= 8

-- Newton tiger_geoid (after migration 683)
SELECT tiger_geoid FROM essentials.districts
WHERE geo_id = '2545560' AND state = 'ma';
-- Expected: 2 rows, both = '2545560'

-- Zero NULL office_id in the 7-city batch
SELECT COUNT(*) FROM essentials.politicians
WHERE external_id BETWEEN -2572600999 AND -2523000001
  AND office_id IS NULL;
-- Expected: 0
```
