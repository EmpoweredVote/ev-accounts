# Phase 123: Ward Geofencing — All 7 Cities - Research

**Researched:** 2026-06-16
**Domain:** GIS boundary import, PostGIS, MassGIS FeatureServer, district re-linking SQL
**Confidence:** HIGH (all GIS data verified via live API calls; all external_ids confirmed from migration files read this session)

---

## Summary

Phase 123 imports ward boundary polygons for 7 MA cities (Newton, Somerville, Lynn, Fall River, Waltham, Medford, New Bedford) into `essentials.geofence_boundaries`, then inserts per-ward `essentials.districts` rows with `tiger_geoid` set, and re-links ward councillors' `offices.district_id` from the citywide LOCAL row to the new per-ward rows.

Three critical structural differences from Phase 119 must be understood before planning:

1. **Fall River is entirely at-large** — 9 at-large councilors, zero ward seats. MassGIS has 9 Fall River voting wards, but no ward councillors exist to re-link. Fall River geofencing means importing 9 ward polygons so the citywide G4110 geofence can be replaced by per-ward resolution — but the migration re-link step has NO office moves (all offices already point to the citywide LOCAL row and stay there). This is different from Phase 119 cities which all had ward seats.

2. **Medford is entirely at-large** — 7 at-large City Councilors, zero ward seats (per charter reform 2020, confirmed in migration 591). Same situation: import 8 Medford voting ward polygons from MassGIS for boundary resolution, but no office re-links needed.

3. **Newton and Waltham have both at-large and ward seats** — Newton has 8 ward councillors (1 per ward) + 16 at-large (2 per ward) = 24 total. Waltham has 9 ward councillors (1 per ward) + 6 at-large = 15 total. These two cities require the full Phase 119 treatment: import polygons + per-ward district rows + tiger_geoid + office re-links for the ward councillors only.

The `load-ma-ward-boundaries.ts` script already handles the MassGIS precinct dissolution approach and is parameterized for city names. It needs to be extended to add the 7 new city configs (replacing the current hardcoded list of SPRINGFIELD/LOWELL/BROCKTON/QUINCY).

**Primary recommendation:** Extend `load-ma-ward-boundaries.ts` to accept all 7 new cities (add configs). Run the script for each city. Then write one migration per city (7 migrations total) following the Phase 119 pattern — pre-flight assertion, per-ward district rows, tiger_geoid backfill, office re-links (where applicable).

Next available migration number: **706** (migrations 703-705 are in use by prior work; canonical Phase 123 range is 706-712). [VERIFIED: plans use 706-712]

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Ward polygon import | CLI script (Node.js) | Database (PostGIS ST_Union) | Matches Phase 119 pattern — fetchJson + pg pool + unnest dissolution |
| Ward polygon dissolution | Database (PostGIS ST_Union) | — | MassGIS precincts must be dissolved server-side |
| tiger_geoid backfill | Database (SQL migration) | — | Pure SQL UPDATE, no application logic needed |
| Office re-linking | Database (SQL migration) | — | UPDATE essentials.offices SET district_id = new per-ward id |
| Path 0 geofencing | Database (PostGIS ST_Contains) | API | Already implemented in essentialsService; no code change needed |

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAGE-16 | Newton ward polygons imported; tiger_geoid backfilled on district rows; Path 0 verified | load-ma-ward-boundaries.ts --city NEWTON --ward-count 8 + migration 706 |
| MAGE-17 | Somerville ward polygons imported; tiger_geoid backfilled; Path 0 verified | load-ma-ward-boundaries.ts --city SOMERVILLE --ward-count 7 + migration 707 |
| MAGE-18 | Lynn ward polygons imported; tiger_geoid backfilled; Path 0 verified | load-ma-ward-boundaries.ts --city LYNN --ward-count 7 + migration 708 |
| MAGE-19 | Fall River ward polygons imported; tiger_geoid backfilled; Path 0 verified | load-ma-ward-boundaries.ts --city FALL RIVER --ward-count 9 + migration 709 |
| MAGE-20 | Waltham ward polygons imported; tiger_geoid backfilled; Path 0 verified | load-ma-ward-boundaries.ts --city WALTHAM --ward-count 9 + migration 710 |
| MAGE-21 | Medford ward polygons imported; tiger_geoid backfilled; Path 0 verified | load-ma-ward-boundaries.ts --city MEDFORD --ward-count 8 + migration 711 |
| MAGE-22 | New Bedford ward polygons imported; tiger_geoid backfilled; Path 0 verified | load-ma-ward-boundaries.ts --city NEW BEDFORD --ward-count 6 + migration 712 |
</phase_requirements>

---

## City-by-City Data Compendium

This section is the single most important section for the planner. Every external_id, geo_id, ward count, and geo_id slug pattern is verified from migration files read this session.

### Newton (MAGE-16)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2545560` | migration 578 [VERIFIED] |
| FIPS place code | 2545560 | migration 578 [VERIFIED] |
| MassGIS TOWN key | `NEWTON` | Live API query [VERIFIED] |
| Voting ward count | 8 (Wards 1–8) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 4 | Live MassGIS API [VERIFIED] |
| Council ward seats | 8 (one per ward) | migration 578 [VERIFIED] |
| At-large seats | 16 (two per ward) | migration 578 [VERIFIED] |
| Mayor | Marc C. Laredo (-2545560001) | migration 578 [VERIFIED] |
| tiger_geoid status | SET (migration 699 applied) | migration 699 [VERIFIED] |
| geo_id slug pattern | `newton-ma-council-ward-{N}` | (new — follows Phase 119 pattern) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | YES — 8 ward councillors | See mapping below |

**Newton ward councillor → external_id mapping** [VERIFIED: migration 578]:
- Ward 1: Maria S. Greenberg (-2545560022)
- Ward 2: David Micley (-2545560025)
- Ward 3: Julia Malakie (-2545560024)
- Ward 4: Randy Block (-2545560020)
- Ward 5: Julie Irish (-2545560023)
- Ward 6: Martha Bixby (-2545560019)
- Ward 7: R. Lisle Baker (-2545560018)
- Ward 8: Stephen Farrell (-2545560021)

**Newton at-large councillors (no re-link):** external_ids -2545560002 through -2545560017 (16 politicians, titles 'City Councilor' without ward qualifier)

---

### Somerville (MAGE-17)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2562535` | migration 581 [VERIFIED] |
| MassGIS TOWN key | `SOMERVILLE` | Live API query [VERIFIED] |
| Voting ward count | 7 (Wards 1–7) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 4 | Live MassGIS API [VERIFIED] |
| Council ward seats | 7 (one per ward) | migration 581 [VERIFIED] |
| At-large seats | 4 | migration 581 [VERIFIED] |
| Mayor | Jake Wilson (-2562535001) | migration 581 [VERIFIED] |
| tiger_geoid status | SET (migration 622 applied) | migration 622 [VERIFIED] |
| geo_id slug pattern | `somerville-ma-council-ward-{N}` | (new — follows Phase 119 pattern) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | YES — 7 ward councillors | See mapping below |

**Somerville ward councillor → external_id mapping** [VERIFIED: migrations 581 + 583]:
- Ward 1: Matthew McLaughlin (-2562535006)
- Ward 2: Jefferson Thomas Scott (-2562535007)
- Ward 3: Ben Ewen-Campen (-2562535008)
- Ward 4: Jesse Clingan (-2562535009)
- Ward 5: Naima Sait (-2562535010)
- Ward 6: Lance L. Davis (-2562535011) (Council President — title stays 'City Councilor (Ward 6)')
- Ward 7: Emily Hardt (-2562535012)

**Somerville at-large councillors (no re-link):** Jon Link (-2562535002), Wilfred N. Mbah (-2562535003), Kristen E. Strezo (-2562535004), Ben Wheeler (-2562535005)

---

### Lynn (MAGE-18)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2537490` | migration 584 [VERIFIED] |
| MassGIS TOWN key | `LYNN` | Live API query [VERIFIED] |
| Voting ward count | 7 (Wards 1–7) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 4 | Live MassGIS API [VERIFIED] |
| Council ward seats | 7 (one per ward) | migration 584 [VERIFIED] |
| At-large seats | 4 | migration 584 [VERIFIED] |
| Mayor | Jared C. Nicholson (-2537490001) | migration 584 [VERIFIED] |
| tiger_geoid status | SET (migration 622 applied) | migration 622 [VERIFIED] |
| geo_id slug pattern | `lynn-ma-council-ward-{N}` | (new — follows Phase 119 pattern) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | YES — 7 ward councillors | See mapping below |

**Lynn ward councillor → external_id mapping** [VERIFIED: migrations 584 + 586]:
- Ward 1: Peter D. Meaney (-2537490006)
- Ward 2: Obed A. Matul (-2537490007)
- Ward 3: Constantino Alinsug (-2537490008) (Council President — title stays 'City Councilor (Ward 3)')
- Ward 4: Natasha S. Megie-Maddrey (-2537490009)
- Ward 5: Cardeliz Paez (-2537490010)
- Ward 6: Frederick W. Hogan (-2537490011)
- Ward 7: Jordan T. Avery (-2537490012)

**Lynn at-large councillors (no re-link):** Brian M. Field (-2537490002), Brian P. LaPierre (-2537490003), Nicole D. McClain (-2537490004), Hong L. Net (-2537490005)

---

### Fall River (MAGE-19)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2523000` | migration 590 [VERIFIED] |
| MassGIS TOWN key | `FALL RIVER` | Live API query [VERIFIED] |
| Voting ward count | 9 (Wards 1–9) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 3 | Live MassGIS API [VERIFIED] |
| Council ward seats | **0 — fully at-large** | migration 590 [VERIFIED] |
| At-large seats | 9 | migration 590 [VERIFIED] |
| Mayor | Paul Coogan (-2523000001) | migration 590 [VERIFIED] |
| tiger_geoid status | SET (migration 622 applied) | migration 622 [VERIFIED] |
| geo_id slug pattern | `fall-river-ma-council-ward-{N}` | (new) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | **NO** — fully at-large council | No ward seats exist |

**CRITICAL: Fall River import strategy differs from other cities.** Importing 9 ward polygons for boundary coverage is correct. However, migration 709 must NOT attempt any office re-links — all 9 councilors plus the Mayor are already linked to the citywide LOCAL row (geo_id='2523000'), and they must remain there. The migration only needs: (1) pre-flight assertion, (2) 9 per-ward district rows, (3) tiger_geoid on per-ward rows, (4) tiger_geoid on citywide LOCAL/LOCAL_EXEC if not already set. No UPDATE on essentials.offices.

**Why per-ward rows if no ward seats?** Having per-ward district rows enables future ward councillors if Fall River ever restructures its council, and enables the ward-boundary split in the UI even for at-large councillors (a user can see "Ward 5 representative: [all at-large councilors]"). For now, Path 0 will return all at-large councillors for any Fall River address (via the citywide LOCAL tiger_geoid), which is correct behavior.

---

### Waltham (MAGE-20)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2572600` | migration 592 [VERIFIED] |
| MassGIS TOWN key | `WALTHAM` | Live API query [VERIFIED] |
| Voting ward count | 9 (Wards 1–9) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 2 | Live MassGIS API [VERIFIED] |
| Council ward seats | 9 (one per ward) | migration 592 [VERIFIED] |
| At-large seats | 6 | migration 592 [VERIFIED] |
| Mayor | Arthur Donahue (-2572600001) | migration 592 [VERIFIED] |
| tiger_geoid status | SET (migration 622 applied) | migration 622 [VERIFIED] |
| geo_id slug pattern | `waltham-ma-council-ward-{N}` | (new — follows Phase 119 pattern) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | YES — 9 ward councillors | See mapping below |
| Title spelling | 'City Councillor' (double-L) | migration 592 [VERIFIED] — Waltham uses British spelling |

**Waltham ward councillor → external_id mapping** [VERIFIED: migrations 592 + 596]:
- Ward 1: Anthony LaFauci (-2572600008)
- Ward 2: Caren Dunn (-2572600009)
- Ward 3: Bill Hanley (-2572600010)
- Ward 4: John J. McLaughlin (-2572600011)
- Ward 5: Joseph P. LaCava (-2572600012)
- Ward 6: Sean Durkee (-2572600013)
- Ward 7: Paul S. Katz (-2572600014)
- Ward 8: Cathyann Harris (-2572600015)
- Ward 9: Robert G. Logan (-2572600016) (Council President — title stays 'City Councillor (Ward 9)')

**Waltham at-large councillors (no re-link):** Colleen Bradley-MacArthur (-2572600002), Paul J. Brasco (-2572600003), Tim King (-2572600004), Randall J. LeBlanc (-2572600005), Emma Tzioumis (-2572600006), Carlos A. Vidal (-2572600007)

---

### Medford (MAGE-21)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2539835` | migration 622 (Medford fix) [VERIFIED] |
| MassGIS TOWN key | `MEDFORD` | Live API query [VERIFIED] |
| Voting ward count | 8 (Wards 1–8) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 2 | Live MassGIS API [VERIFIED] |
| Council ward seats | **0 — fully at-large** | migration 591 [VERIFIED] |
| At-large seats | 7 | migration 591 [VERIFIED] |
| Mayor | Breanna Lungo-Koehn (-2540115001) | migration 591 [VERIFIED] |
| tiger_geoid status | SET (migration 622 applied) | migration 622 [VERIFIED] |
| geo_id slug pattern | `medford-ma-council-ward-{N}` | (new) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | **NO** — fully at-large council | No ward seats exist |

**CRITICAL: Medford geo_id is '2539835', NOT '2540115'.** Migration 591 seeded Medford with the wrong geo_id (2540115 = Melrose). Migration 622 fixed this. The correct geo_id for Medford is `2539835`. The external_id range for Medford politicians remains -2540115001 through -2540115008 (the external_id encoding was not changed by migration 622). This asymmetry is intentional: external_ids are internal identifiers, geo_id is the FIPS place code.

**Same at-large-only treatment as Fall River** — import 8 ward polygons, no office re-links. Migration 711 inserts 8 per-ward district rows + tiger_geoid, nothing else.

---

### New Bedford (MAGE-22)

| Property | Value | Source |
|----------|-------|--------|
| geo_id (citywide) | `2545000` | migration 587 [VERIFIED] |
| MassGIS TOWN key | `NEW BEDFORD` | Live API query [VERIFIED] |
| Voting ward count | 6 (Wards 1–6) | Live MassGIS API [VERIFIED] |
| Precincts per ward | 6 | Live MassGIS API [VERIFIED] |
| Council ward seats | 6 (one per ward) | migration 587 [VERIFIED] |
| At-large seats | 5 | migration 587 [VERIFIED] |
| Mayor | Jonathan F. Mitchell (-2545000001) | migration 587 [VERIFIED] |
| tiger_geoid status | SET (migration 622 applied) | migration 622 [VERIFIED] |
| geo_id slug pattern | `new-bedford-ma-council-ward-{N}` | (new — follows Phase 119 pattern) |
| mtfcc | `X0014` | Continues Phase 119 registry |
| Office re-links needed? | YES — 6 ward councillors | See mapping below |

**New Bedford ward councillor → external_id mapping** [VERIFIED: migration 587]:
- Ward 1: Leo Choquette (-2545000007)
- Ward 2: Scott Pemberton (-2545000008)
- Ward 3: Shawn Oliver (-2545000009)
- Ward 4: Derek Baptiste (-2545000010)
- Ward 5: Joseph Lopes (-2545000011)
- Ward 6: Ryan Pereira (-2545000012) (Council President — title stays 'City Councilor (Ward 6)')

**New Bedford at-large councillors (no re-link):** Ian Abreu (-2545000002), Shane Burgo (-2545000003), Naomi Carney (-2545000004), Brian Gomes (-2545000005), James Roy (-2545000006)

---

## Council Structure Summary

| City | Ward Count | Ward Seats | At-Large Seats | Office Re-Links | tiger_geoid already set? |
|------|-----------|------------|----------------|-----------------|--------------------------|
| Newton | 8 | 8 | 16 | YES (8) | YES (migration 699) |
| Somerville | 7 | 7 | 4 | YES (7) | YES (migration 622) |
| Lynn | 7 | 7 | 4 | YES (7) | YES (migration 622) |
| Fall River | 9 | 0 (at-large) | 9 | **NO** | YES (migration 622) |
| Waltham | 9 | 9 | 6 | YES (9) | YES (migration 622) |
| Medford | 8 | 0 (at-large) | 7 | **NO** | YES (migration 622) |
| New Bedford | 6 | 6 | 5 | YES (6) | YES (migration 622) |

**Total office re-links across all 7 cities: 37** (8 + 7 + 7 + 0 + 9 + 0 + 6)

---

## GIS Data Sources

### All 7 Cities — MassGIS WARDSPRECINCTS2022_POLY FeatureServer

**URL:** `https://services6.arcgis.com/hNDcO07QfnsUMldG/arcgis/rest/services/WARDSPRECINCTS2022_POLY/FeatureServer/0` [VERIFIED: live API query this session]

All 7 cities are in this single dataset. No city-specific FeatureServer is needed (unlike Worcester, which uses a city-owned service). The `load-ma-ward-boundaries.ts` script was designed for this approach and handles precinct dissolution via ST_Union.

**CRITICAL: TOWN filter must be uppercase.** [VERIFIED: existing script comment + Phase 119 pitfall]

| City | TOWN filter | Ward count | Precincts/ward | Total rows |
|------|-------------|-----------|----------------|------------|
| Newton | `NEWTON` | 8 (1–8) | 4 each | 32 |
| Somerville | `SOMERVILLE` | 7 (1–7) | 4 each | 28 |
| Lynn | `LYNN` | 7 (1–7) | 4 each | 28 |
| Fall River | `FALL RIVER` | 9 (1–9) | 3 each | 27 |
| Waltham | `WALTHAM` | 9 (1–9) | 2 each | 18 |
| Medford | `MEDFORD` | 8 (1–8) | 2 each | 16 |
| New Bedford | `NEW BEDFORD` | 6 (1–6) | 6 each | 36 |

[VERIFIED: live MassGIS FeatureServer statistics query this session]

**CRITICAL: `FALL RIVER` has a space in the TOWN filter.** This is different from all other cities. The URL-encoded form is `FALL%20RIVER`. The existing script's allowlist and TOWN filter construction must handle city names with spaces. [VERIFIED: live API returned FALL RIVER results this session]

**CRITICAL: `NEW BEDFORD` also has a space in the TOWN filter.** Same issue — must be `NEW%20BEDFORD` when URL-encoded.

### No city-specific FeatureServers needed

Unlike Worcester (which required `load-worcester-council-boundaries.ts` because the city has 10 voting wards vs. 5 council districts), all 7 Phase 123 cities align their voting ward count with the MassGIS data. No separate city-owned FeatureServer is needed.

---

## Script Strategy

### Extend `load-ma-ward-boundaries.ts` (DO NOT create new scripts)

The existing `load-ma-ward-boundaries.ts` handles all 4 Phase 119 cities. For Phase 123, extend the `CITY_CONFIGS` map with 7 new entries. No structural script changes needed — the dissolution logic, validation, and DB insert pattern are identical.

**New CITY_CONFIGS entries to add:**

```typescript
NEWTON: {
  geoIdPrefix: 'newton-ma-council-ward-',
  wardLabel: 'Ward',
},
SOMERVILLE: {
  geoIdPrefix: 'somerville-ma-council-ward-',
  wardLabel: 'Ward',
},
LYNN: {
  geoIdPrefix: 'lynn-ma-council-ward-',
  wardLabel: 'Ward',
},
'FALL RIVER': {
  geoIdPrefix: 'fall-river-ma-council-ward-',
  wardLabel: 'Ward',
},
WALTHAM: {
  geoIdPrefix: 'waltham-ma-council-ward-',
  wardLabel: 'Ward',
},
MEDFORD: {
  geoIdPrefix: 'medford-ma-council-ward-',
  wardLabel: 'Ward',
},
'NEW BEDFORD': {
  geoIdPrefix: 'new-bedford-ma-council-ward-',
  wardLabel: 'Ward',
},
```

**City names with spaces in CITY_CONFIGS keys** require updating the `toUpperCase()` normalization step in `parseArgs()` — currently converts input to uppercase and checks against `ALLOWED_CITIES`. Cities like "FALL RIVER" need exact key matching. The simplest fix: normalize the input `city` argument to uppercase (already done), and change the ALLOWED_CITIES check to use `CITY_CONFIGS[city]` lookup.

**Usage after extension:**
```bash
npx tsx scripts/load-ma-ward-boundaries.ts --city NEWTON --ward-count 8
npx tsx scripts/load-ma-ward-boundaries.ts --city SOMERVILLE --ward-count 7
npx tsx scripts/load-ma-ward-boundaries.ts --city LYNN --ward-count 7
npx tsx scripts/load-ma-ward-boundaries.ts --city "FALL RIVER" --ward-count 9
npx tsx scripts/load-ma-ward-boundaries.ts --city WALTHAM --ward-count 9
npx tsx scripts/load-ma-ward-boundaries.ts --city MEDFORD --ward-count 8
npx tsx scripts/load-ma-ward-boundaries.ts --city "NEW BEDFORD" --ward-count 6
```

---

## Migration Architecture

### Next Available Migration Number

**703** — last on-disk migration is `702_new_bedford_gaps.sql`. [VERIFIED: ls migrations/*.sql this session]

### Recommended Migration Sequence

| Migration | City | Ward rows | Office re-links | Notes |
|-----------|------|-----------|-----------------|-------|
| 706 | Newton | 8 per-ward LOCAL | 8 | Ward councillors: -2545560018 through -2545560025 (non-sequential) |
| 707 | Somerville | 7 per-ward LOCAL | 7 | Ward councillors: -2562535006 through -2562535012 |
| 708 | Lynn | 7 per-ward LOCAL | 7 | Ward councillors: -2537490006 through -2537490012 |
| 709 | Fall River | 9 per-ward LOCAL | 0 | At-large only — NO office re-links |
| 710 | Waltham | 9 per-ward LOCAL | 9 | Ward councillors: -2572600008 through -2572600016 |
| 711 | Medford | 8 per-ward LOCAL | 0 | At-large only — NO office re-links |
| 712 | New Bedford | 6 per-ward LOCAL | 6 | Ward councillors: -2545000007 through -2545000012 |

Each migration runs AFTER the corresponding city's import script has loaded ward polygons into `geofence_boundaries`.

### Migration Template (city with ward seats — Newton example)

```sql
-- Step 1: Pre-flight — confirm ward polygons are loaded
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'newton-ma-council-ward-%' AND mtfcc = 'X0014';
  IF v_count < 8 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 8 newton-ma-council-ward-* X0014 rows, found %. Run load-ma-ward-boundaries.ts --city NEWTON first.', v_count;
  END IF;
END $$;

BEGIN;

-- Step 2: Insert per-ward LOCAL district rows
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'newton-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);
-- ... repeat for Wards 2-8

-- Step 3: tiger_geoid backfill on per-ward rows
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id LIKE 'newton-ma-council-ward-%'
  AND mtfcc = 'X0014'
  AND tiger_geoid IS NULL;

-- Step 4: Re-link ward councillors' offices
-- Newton Ward 1: Maria S. Greenberg (-2545560022) → newton-ma-council-ward-1
UPDATE essentials.offices
SET district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = 'newton-ma-council-ward-1'
    AND district_type = 'LOCAL'
    AND state = 'ma'
)
WHERE politician_id = (
  SELECT id FROM essentials.politicians WHERE external_id = -2545560022
)
  AND district_id = (
  SELECT id FROM essentials.districts
  WHERE geo_id = '2545560'
    AND district_type = 'LOCAL'
    AND state = 'ma'
);
-- ... one UPDATE per ward councillor

-- Step 5: Verification DO block
-- ... (assert 8 per-ward rows, tiger_geoid set, office re-links applied)

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('706') ON CONFLICT (version) DO NOTHING;

COMMIT;
```

### Migration Template (at-large-only city — Fall River example)

```sql
-- Step 1: Pre-flight — confirm ward polygons are loaded
DO $$
DECLARE v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.geofence_boundaries
  WHERE geo_id LIKE 'fall-river-ma-council-ward-%' AND mtfcc = 'X0014';
  IF v_count < 9 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: expected 9 fall-river-ma-council-ward-* X0014 rows, found %. Run load-ma-ward-boundaries.ts --city "FALL RIVER" first.', v_count;
  END IF;
END $$;

BEGIN;

-- Step 2: Insert per-ward LOCAL district rows (for boundary data completeness only)
-- Fall River is at-large — NO office re-links will be done in this migration.
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc)
SELECT gen_random_uuid(), 'LOCAL', 'ma', 'fall-river-ma-council-ward-1', 'Ward 1', 'X0014'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = 'fall-river-ma-council-ward-1' AND district_type = 'LOCAL' AND state = 'ma'
);
-- ... repeat for Wards 2-9

-- Step 3: tiger_geoid backfill on per-ward rows
UPDATE essentials.districts
SET tiger_geoid = geo_id
WHERE state = 'ma'
  AND geo_id LIKE 'fall-river-ma-council-ward-%'
  AND mtfcc = 'X0014'
  AND tiger_geoid IS NULL;

-- NO Step 4 (office re-links) — Fall River is fully at-large.
-- All councilors remain linked to citywide LOCAL row (geo_id='2523000').
-- At-large councillors and Mayor continue to resolve via tiger_geoid='2523000' → G4110 citywide polygon.

-- Step 5: Verification DO block (no office re-link assertion)

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('709') ON CONFLICT (version) DO NOTHING;

COMMIT;
```

---

## geo_id Slug Patterns — All 7 Cities

| City | Pattern | Example |
|------|---------|---------|
| Newton | `newton-ma-council-ward-{N}` | `newton-ma-council-ward-1` |
| Somerville | `somerville-ma-council-ward-{N}` | `somerville-ma-council-ward-7` |
| Lynn | `lynn-ma-council-ward-{N}` | `lynn-ma-council-ward-3` |
| Fall River | `fall-river-ma-council-ward-{N}` | `fall-river-ma-council-ward-9` |
| Waltham | `waltham-ma-council-ward-{N}` | `waltham-ma-council-ward-5` |
| Medford | `medford-ma-council-ward-{N}` | `medford-ma-council-ward-8` |
| New Bedford | `new-bedford-ma-council-ward-{N}` | `new-bedford-ma-council-ward-6` |

Note: All 7 cities use "ward" in the slug, as each city's MassGIS data uses the "WARD" field to represent their voting ward division. This is consistent regardless of whether the city has ward council seats.

---

## mtfcc Registry

X0014 is shared for all Phase 119 and Phase 123 cities (unique constraint is on `(geo_id, mtfcc)`, so sharing mtfcc is fine). [VERIFIED: migration 622 + Phase 119 research]

| mtfcc | Owner |
|-------|-------|
| X0013 | Boston MA council districts |
| X0014 | Worcester, Springfield, Lowell, Brockton, Quincy (Phase 119) + Newton, Somerville, Lynn, Fall River, Waltham, Medford, New Bedford (Phase 123) |

---

## Standard Stack

### Core (no new packages)
| Library | Purpose | Why Standard |
|---------|---------|--------------|
| `pg` (Pool) | DB writes | Existing pattern in all boundary import scripts |
| Node.js `https` | ArcGIS/MassGIS fetch | Proven in load-ma-ward-boundaries.ts |
| `dotenv` | DATABASE_URL config | Standard env pattern |
| `tsx` | Run TypeScript scripts | Existing devDependency |
| PostGIS `ST_Union`, `ST_MakeValid`, `ST_ForcePolygonCCW` | Geometry operations | Already in Supabase/Postgres; proven in Phase 119 |

No new packages needed — all tooling is already installed.

---

## Package Legitimacy Audit

No new packages are installed in this phase. All scripts use existing dependencies.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
  load-ma-ward-boundaries.ts (extended with 7 new city configs)
         |
         | (--city NEWTON|SOMERVILLE|LYNN|"FALL RIVER"|WALTHAM|MEDFORD|"NEW BEDFORD")
         |
  MassGIS WARDSPRECINCTS2022_POLY FeatureServer
  (precinct polygons for all 7 cities)
         |
         | (group by WARD → ST_Union in PostGIS)
         |
         ▼
  essentials.geofence_boundaries
  (geo_id='city-ma-council-ward-N', mtfcc='X0014')
         |
   SQL Migrations (706 → 712, one per city)
         |
         ▼
  essentials.districts
  (per-ward LOCAL rows, tiger_geoid set)
         |
   office re-links (for cities with ward seats only)
         |
         ▼
  essentials.offices
  (ward councillors: district_id → per-ward LOCAL row)
  (at-large councillors: district_id stays → citywide LOCAL row)
         |
         ▼
  Path 0 Join
  ST_Contains(gb.geometry, user_point)
  WHERE d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
```

### Recommended Project Structure

No new directories or scripts needed. Extend existing script, add migrations.

```
backend/
├── scripts/
│   └── load-ma-ward-boundaries.ts    (extend CITY_CONFIGS with 7 new entries)
└── migrations/
    ├── 706_newton_council_ward_geofencing.sql
    ├── 707_somerville_council_ward_geofencing.sql
    ├── 708_lynn_council_ward_geofencing.sql
    ├── 709_fall_river_council_ward_geofencing.sql  (no office re-links)
    ├── 710_waltham_council_ward_geofencing.sql
    ├── 711_medford_council_ward_geofencing.sql     (no office re-links)
    └── 712_new_bedford_council_ward_geofencing.sql
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ward polygon dissolution | Custom JavaScript union | PostGIS `ST_Union` | Topological edge cases, slivers, shared borders; already proven in Phase 119 |
| Geometry validation | Manual GeoJSON checks | `ST_MakeValid` + `ST_ForcePolygonCCW` | Phase 119 pattern validated; winding order requirements for PostGIS |
| New ward import script | New load-*.ts script | Extend existing `load-ma-ward-boundaries.ts` CITY_CONFIGS | All 7 cities use same MassGIS source; no structural difference |
| Ward → councillor mapping | Parsing office title strings | Hardcoded external_id mapping from migration headers | Safer, auditable, matches Phase 119 approach |

---

## Common Pitfalls

### Pitfall 1: Fall River and Medford have no ward councillors
**What goes wrong:** Writing office re-link SQL for Fall River or Medford, causing migration to UPDATE 0 rows or (worse) silently re-linking wrong offices.
**Why it happens:** Fall River has 9 MassGIS voting wards but 9 at-large council seats — no ward seats. Medford has 8 MassGIS voting wards but 7 at-large seats — no ward seats.
**How to avoid:** Migration 709 (Fall River) and 711 (Medford) must have NO `UPDATE essentials.offices` steps. Migration verification DO block must NOT assert any office re-links.
**Warning signs:** If you see office re-link SQL in migrations 709 or 711, the plan has a bug.

### Pitfall 2: FALL RIVER and NEW BEDFORD have spaces in TOWN filter
**What goes wrong:** Script CLI arg parsing normalizes to uppercase but splits on space — `--city FALL RIVER` becomes `FALL` with `RIVER` as next arg, breaking the ward-count parse.
**Why it happens:** Current argparse in `load-ma-ward-boundaries.ts` uses positional `args[cityIdx + 1]` which stops at the first space.
**How to avoid:** Pass city with quotes: `--city "FALL RIVER"`. Update the script to treat the city arg as the full string after `--city` until the next `--` flag. Test with: `npx tsx scripts/load-ma-ward-boundaries.ts --city "FALL RIVER" --ward-count 9 --dry-run`.
**Warning signs:** Script prints "city: FALL, ward-count: NaN" or fails validation with "city not found in ALLOWED_CITIES".

### Pitfall 3: Newton external_ids are non-sequential for ward councillors
**What goes wrong:** Assuming ward councillors are -2545560018..-2545560025 sequentially (one per ward in order). The actual mapping is Ward 7 = -2545560018, Ward 6 = -2545560019, Ward 4 = -2545560020, Ward 8 = -2545560021, Ward 1 = -2545560022, Ward 5 = -2545560023, Ward 3 = -2545560024, Ward 2 = -2545560025. They are in insertion order from migration 578, not ward-number order.
**How to avoid:** Use the exact mapping table in this research. Do NOT derive mapping from external_id sequence.
**Warning signs:** Re-link UPDATE affects the wrong councillor (e.g., assigns Ward 2 polygon to Lisle Baker who represents Ward 7).

### Pitfall 4: Medford geo_id is 2539835, external_ids use 2540115
**What goes wrong:** Using 2540115 as the Medford geo_id in migration 711 (the wrong Melrose FIPS that migration 591 originally used).
**Why it happens:** Migration 591 had a bug (seeded Medford with Melrose's FIPS). Migration 622 fixed the geo_id to 2539835 but external_ids (-2540115001 through -2540115008) were not renamed.
**How to avoid:** Migration 711 must use `geo_id = '2539835'` for Medford's citywide LOCAL rows. The pre-flight query for geofence_boundaries must also use `geo_id = '2539835'`. External_id range for politician lookup remains -2540115001..-2540115008.
**Warning signs:** Pre-flight assertion for G4110 geofence fails (there is no G4110 for geo_id='2540115'; it was corrected to '2539835').

### Pitfall 5: TOWN field case sensitivity (inherited from Phase 119)
**What goes wrong:** Querying `TOWN='Newton'` (mixed case) returns 0 results — MassGIS TOWN field is uppercase.
**How to avoid:** Always use uppercase: `TOWN='NEWTON'`, `TOWN='SOMERVILLE'`, etc. [VERIFIED: existing script + Phase 119 pitfall]

### Pitfall 6: outSR=4326 required on MassGIS queries (inherited from Phase 119)
**What goes wrong:** Omitting `outSR=4326` — MassGIS serves in Web Mercator (WKID 102100/3857) by default. Path 0 ST_Contains returns no matches.
**How to avoid:** Always append `&outSR=4326`. Already in `load-ma-ward-boundaries.ts` as a CRITICAL comment.

### Pitfall 7: Tiger_geoid already set for all 7 citywide rows
**What goes wrong:** Migration pre-flight assumes tiger_geoid is NULL on citywide rows, adds redundant assertions.
**Why it matters:** Migration 622 already set tiger_geoid on 6 of the 7 cities. Migration 699 set Newton's. All 7 citywide LOCAL/LOCAL_EXEC rows should already have tiger_geoid = geo_id. The migrations should NOT include citywide tiger_geoid backfill (it's already done). Including it as a no-op is harmless (WHERE tiger_geoid IS NULL guard) but adds confusion.
**How to avoid:** Confirm state with a quick SELECT before writing migrations: `SELECT geo_id, district_type, tiger_geoid FROM essentials.districts WHERE state='ma' AND geo_id IN ('2545560','2562535','2537490','2523000','2572600','2539835','2545000') AND district_type IN ('LOCAL','LOCAL_EXEC')`. All should return tiger_geoid = geo_id.

---

## Validation Architecture

### Phase Gate Verification Queries

For each city, after script + migration:

```sql
-- Gate 1: geofence_boundaries has correct ward count
SELECT COUNT(*) FROM essentials.geofence_boundaries
WHERE geo_id LIKE '{city}-ma-council-ward-%' AND mtfcc = 'X0014';
-- Expected: 8 Newton / 7 Somerville / 7 Lynn / 9 Fall River / 9 Waltham / 8 Medford / 6 New Bedford

-- Gate 2: district rows exist with tiger_geoid set
SELECT COUNT(*) FROM essentials.districts
WHERE state = 'ma' AND geo_id LIKE '{city}-ma-council-ward-%' AND tiger_geoid IS NOT NULL;

-- Gate 3: Path 0 join works for a sample address in each city
SELECT d.geo_id, d.district_type, d.label, p.full_name
FROM essentials.districts d
JOIN essentials.geofence_boundaries gb ON d.tiger_geoid = gb.geo_id AND gb.mtfcc = d.mtfcc
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE ST_Contains(gb.geometry, ST_SetSRID(ST_Point({test_lon}, {test_lat}), 4326))
  AND d.state = 'ma'
  AND d.district_type = 'LOCAL';

-- Gate 4: ward councillors re-linked (for cities with ward seats only)
SELECT COUNT(*) FROM essentials.offices o
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE p.external_id BETWEEN {ward_councillor_min} AND {ward_councillor_max}
  AND d.geo_id = '{city_fips}'   -- should be 0 after re-link
  AND d.district_type = 'LOCAL';
```

### Test Addresses for Path 0 Validation

| City | Test Coordinates | Expected Ward |
|------|-----------------|---------------|
| Newton | (-71.209, 42.337) City Hall area | Ward 2 or 3 area |
| Somerville | (-71.100, 42.387) Davis Square area | Ward 7 area |
| Lynn | (-70.947, 42.467) Lynn City Hall | Ward 1 or 3 area |
| Fall River | (-71.157, 41.701) Fall River City Hall | Ward area (returns all at-large) |
| Waltham | (-71.236, 42.376) Waltham City Hall | Ward 5 area |
| Medford | (-71.107, 42.418) Medford City Hall | Ward area (returns all at-large) |
| New Bedford | (-70.924, 41.635) New Bedford City Hall | Ward 3 area |

### Test Framework

| Property | Value |
|----------|-------|
| Framework | SQL assertions (DO $$ DECLARE ... BEGIN ... RAISE EXCEPTION ... END $$) |
| Config file | none — inline SQL |
| Quick run command | Run via Supabase execute_sql or psql |
| Full suite command | backend/scripts/verify-phase-123.sql (new file, following verify-phase-119.sql pattern) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| MAGE-16 | 8 Newton ward polygons + per-ward district rows + office re-links | SQL assertion | verify-phase-123.sql ASSERTION 1 |
| MAGE-17 | 7 Somerville ward polygons + per-ward district rows + office re-links | SQL assertion | verify-phase-123.sql ASSERTION 2 |
| MAGE-18 | 7 Lynn ward polygons + per-ward district rows + office re-links | SQL assertion | verify-phase-123.sql ASSERTION 3 |
| MAGE-19 | 9 Fall River ward polygons + per-ward district rows (no re-links) | SQL assertion | verify-phase-123.sql ASSERTION 4 |
| MAGE-20 | 9 Waltham ward polygons + per-ward district rows + office re-links | SQL assertion | verify-phase-123.sql ASSERTION 5 |
| MAGE-21 | 8 Medford ward polygons + per-ward district rows (no re-links) | SQL assertion | verify-phase-123.sql ASSERTION 6 |
| MAGE-22 | 6 New Bedford ward polygons + per-ward district rows + office re-links | SQL assertion | verify-phase-123.sql ASSERTION 7 |

### Wave 0 Gaps

None — existing test infrastructure (SQL assertion pattern) covers all phase requirements.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js / tsx | Import scripts | ✓ | In use across all prior phases | — |
| `pg` package | DB writes in scripts | ✓ | In backend/package.json | — |
| DATABASE_URL env var | pg Pool connection | ✓ | Supabase session pooler | — |
| PostGIS (ST_Union, ST_MakeValid) | Ward dissolution | ✓ | Supabase has PostGIS | — |
| Internet access | MassGIS REST API | ✓ | Public endpoints, no auth | — |
| PROJ_LIB (GDAL) | NOT needed | — | No ogr2ogr — pure HTTP fetch | — |

**Missing dependencies:** None. This phase uses the same pure HTTP fetch approach as Phase 119.

---

## Security Domain

No authentication, no user input, no API endpoints added in this phase. All work is:
- Admin CLI scripts run by operators
- SQL migrations with pre-flight guards
- No user-facing surface area changes

ASVS V5 (Input Validation): The WARD field values from MassGIS must be validated as integers in range before use in geo_id construction. This is already implemented in `load-ma-ward-boundaries.ts` (T-119-M1 mitigation: parseInt + isNaN + range check before geo_id construction). The city name allowlist in CITY_CONFIGS prevents injection.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Fall River voting ward boundaries in MassGIS align with political geography well enough to be useful for boundary display | GIS Data Sources | Boundary display would show wrong ward coverage for a user; no functional impact since all Fall River councillors are at-large |
| A2 | Migration 699 successfully applied Newton tiger_geoid (geo_id='2545560') to production | City-by-City Compendium | Phase 123 Newton geofencing fails pre-flight; needs another backfill migration first |
| A3 | WARDSPRECINCTS2022 ward numbers for Somerville (1–7) match office title strings 'City Councilor (Ward N)' in migration 581 | Ward councillor mapping | Wrong councillor linked to wrong ward polygon; geofencing returns wrong representative |
| A4 | WARDSPRECINCTS2022 ward numbers for Lynn (1–7), Waltham (1–9), New Bedford (1–6) match office title strings in their respective seeding migrations | Ward councillor mapping | Wrong councillor linked to wrong ward polygon |
| A5 | MassGIS geometry for 'FALL RIVER' and 'NEW BEDFORD' (two-word TOWN names) is fetched correctly with URL-encoded space | Script Strategy | Script returns 0 features; no polygons imported for Fall River or New Bedford |

**A2 is low risk:** Migration 699 (or the earlier 687) applied this backfill. The 120-01-PLAN.md shows the migration was planned and the 120-01-PLAN.md must_haves include tiger_geoid verification. Planner should add a pre-verification step to confirm before writing migrations.

---

## Open Questions (RESOLVED)

1. **Newton tiger_geoid — confirm via pre-flight SQL before writing migration 706**
   - What we know: Migration 699 was the on-disk canonical record. The 120-01-PLAN.md SUMMARY should confirm it was applied.
   - Recommendation: Migration 706 pre-flight should include `SELECT tiger_geoid FROM essentials.districts WHERE geo_id='2545560' AND state='ma'` and RAISE EXCEPTION if NULL. If the backfill is missing, migration 706 can include it as an inline fix.
   - RESOLVED: Plan 02 Task 1 action includes a `WHERE tiger_geoid IS NULL` no-op guard on Steps 3-4 for Newton citywide rows, making the migration safe regardless of prior backfill state. The pre-flight check in Plan 04's verify-phase-123.sql covers this assertion after execution.

2. **Fall River ward polygon utility**
   - What we know: Fall River has 9 at-large councillors. Importing 9 ward polygons creates per-ward district rows with no councillors re-linked.
   - What's unclear: Does the planner want to import Fall River ward polygons at all? The MAGE-19 requirement says "ward polygons imported" — so yes.
   - Recommendation: Import all 9 polygons. The per-ward district rows exist as boundary data; the at-large councillors continue to resolve citywide.
   - RESOLVED: Plan 02 includes migration 709 (Fall River) with 9 per-ward district row inserts and tiger_geoid backfill, explicitly omitting office re-links. MAGE-19 satisfied.

---

## Sources

### Primary (HIGH confidence — verified via live API calls or migration file reads this session)

- `services6.arcgis.com/hNDcO07QfnsUMldG/.../WARDSPRECINCTS2022_POLY/FeatureServer/0` — MassGIS wards/precincts 2022, ward counts verified for all 7 cities [VERIFIED]
- `backend/migrations/578_newton_city_government.sql` — Newton geo_id, external_ids, ward/AL mapping [VERIFIED]
- `backend/migrations/581_somerville_city_government.sql` + `583_somerville_headshots.sql` — Somerville geo_id, external_ids, ward mapping [VERIFIED]
- `backend/migrations/584_lynn_city_government.sql` + `586_lynn_headshots.sql` — Lynn geo_id, external_ids, ward mapping [VERIFIED]
- `backend/migrations/590_fall_river_city_government.sql` — Fall River geo_id, at-large-only structure [VERIFIED]
- `backend/migrations/592_waltham_city_government.sql` + `596_waltham_headshots.sql` — Waltham geo_id, external_ids, ward mapping [VERIFIED]
- `backend/migrations/591_medford_city_government.sql` — Medford geo_id (2540115 original, later corrected), at-large-only structure [VERIFIED]
- `backend/migrations/622_medford_fix_and_city_tiger_geoid_backfill.sql` — Medford corrected geo_id = 2539835; confirms 6 cities' tiger_geoid already set [VERIFIED]
- `backend/migrations/587_new_bedford_city_government.sql` — New Bedford geo_id, external_ids, ward mapping [VERIFIED]
- `backend/migrations/699_newton_tiger_geoid_backfill.sql` — Newton tiger_geoid backfill on-disk canonical record [VERIFIED]
- `backend/scripts/load-ma-ward-boundaries.ts` — full script reviewed; CITY_CONFIGS, dissolution approach, argparse [VERIFIED]

### Secondary (MEDIUM confidence)
- Phase 119 RESEARCH.md — comprehensive reference for Phase 119 which established the entire pattern Phase 123 extends

---

## Metadata

**Confidence breakdown:**
- GIS data sources / ward counts: HIGH — verified via live MassGIS API statistics query this session
- Ward councillor → external_id mappings: HIGH — read from migration files and headshot files this session
- Script extension approach: HIGH — direct adaptation of existing proven script
- Migration SQL patterns: HIGH — direct copy/extension of migrations 660–664
- Fall River / Medford at-large-only detection: HIGH — confirmed from migration files (no ward title strings in office rows)
- mtfcc X0014 assignment: HIGH — confirmed from Phase 119 research + migration registry

**Research date:** 2026-06-16
**Valid until:** 2026-09-16 (MassGIS WARDSPRECINCTS2022 data is stable; ArcGIS FeatureServer URL may change)
