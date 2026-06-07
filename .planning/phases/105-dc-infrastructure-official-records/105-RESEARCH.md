# Phase 105: DC Infrastructure + Official Records — Research

**Researched:** 2026-06-07
**Domain:** Geospatial infrastructure (TIGER 2024) + civic data seeding (DC government, districts, politicians)
**Confidence:** HIGH — all critical facts verified against live DB and authoritative sources

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** 2 plans: 105-01 (DCIN infrastructure) gates 105-02 (DCOF official records) via FK
- **D-02:** Extend `backend/scripts/load-state-tiger-boundaries.ts` — add `DC: new Set(['sldl'])` to `STATE_LAYER_ALLOWLIST`
- **D-03:** Add `STATE_LAYER_TYPE_MAP: { DC: { sldl: 'CITY_COUNCIL' } }` to override the default `STATE_LOWER` type
- **D-04:** Wire the `sldl` processLayer dispatch for DC (currently throws stub error)
- **D-05:** Layer discriminator = `dc_ward`; TIGER source = `tl_2024_11_sldl.zip`; 8 ward polygons
- **D-06:** Shadow Senators → `office.district_id` points to the DC NATIONAL_LOWER district (EHN's district)
- **D-07:** SBOE at-large seat → SCHOOL_BOARD district with `tiger_geoid = NULL`
- **D-08:** EHN — full update (INSERT if no record, UPDATE photo if null) — query live DB first
- **D-09:** 18 total district records — 8 CITY_COUNCIL, 9 SCHOOL_BOARD, 1 NATIONAL_LOWER
- **D-10:** All 18 district records FK to DC government stub via `government_id`
- **D-11:** Migration number pre-flight required before writing any number
- **D-12:** DC external_id range starts at -600001

### Claude's Discretion
- Photo URL strategy per official body (council, mayor, AG, SBOE, shadow senators)
- OCD-ID format for DC ward districts
- Whether to extend `resolve_user_districts` default p_layers in same migration as backfill or separate

### Deferred Ideas (OUT OF SCOPE)
- Phase 130 full sldl generalization
- DC school board geofencing via user_districts
- DC stances (Phase 106), DC finance (Phase 107)
- ANC members, non-elected officials
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCIN-01 | `essentials.governments` stub for Washington D.C. | Government INSERT pattern from migration 087 / 217; DC geo_id = '11' |
| DCIN-02 | 18 district records — 8 CITY_COUNCIL, 9 SCHOOL_BOARD, 1 NATIONAL_LOWER | Districts INSERT pattern from migration 217; `government_id` FK column confirmed in live schema |
| DCIN-03 | TIGER 2024 DC ward polygons into `essentials.geo_districts` (layer=`dc_ward`) + GIST index | Requires ogr2ogr seed script approach (same as Phase 69); geo_districts confirmed empty for DC |
| DCIN-04 | `tiger_geoid` backfilled on DC CITY_COUNCIL district rows | Backfill SQL pattern from migration 091; confirmed tiger_geoid column exists; TIGER geoid format = '11001'-'11008' |
| DCOF-01 | Politician + office records for Mayor Bowser + all 13 DC Council members | Full roster verified from dccouncil.gov; INSERT pattern from migration 218 |
| DCOF-02 | Politician + office records for AG Schwalb + 2 Shadow Senators | CRITICAL: Michael D. Brown is no longer a shadow senator — replaced by Ankit Jain (sworn in Jan 2025) |
| DCOF-03 | Politician + office records for all 9 SBOE members | Full roster verified from sboe.dc.gov with photo URLs |
| DCOF-04 | `photo_origin_url` for all new DC officials; EHN verified | EHN does NOT exist in DB — must INSERT; photo URLs sourced per body below |
</phase_requirements>

---

## Research Summary

Phase 105 delivers the complete DC data foundation across two gated plans. The infrastructure is well-understood from prior TIGER/city-official work. Three critical facts discovered during research require attention from the planner:

**1. EHN does not exist as a politician record.** The live DB query confirmed zero rows for any name containing 'Eleanor' + 'Norton' in `essentials.politicians`. CONTEXT.md D-08 was written assuming she might need updating — she needs a full INSERT instead. Her `at-large` congressional district does exist in `geofence_boundaries` (geo_id='1198', ocd_id='ocd-division/country:us/state:dc/cd:98'), which confirms DC FIPS 11 is present in the boundary table but the politician herself is not.

**2. Michael D. Brown is no longer a shadow senator.** His term ended January 2025. The current junior DC shadow senator is **Ankit Jain** (sworn in January 2025). DCOF-02 requirement text names "Michael D. Brown" but the correct current roster is Paul Strauss (senior, D) + Ankit Jain (junior, D). The planner must use the correct names. [VERIFIED: senatorjaindc.com/about + Wikipedia]

**3. `essentials.geo_districts` does NOT contain `dc_ward` data.** It only has `ca_assembly`, `ca_senate`, `us_house`, and three school layers. The `load-state-tiger-boundaries.ts` script writes to `essentials.geofence_boundaries`, which is a SEPARATE table from `essentials.geo_districts`. Point-in-polygon via `resolve_user_districts` reads from `geo_districts`. DCIN-03 requires a seed script that writes to `geo_districts`, plus a migration extending the `resolve_user_districts` / `cache_user_districts` default `p_layers` to include `dc_ward`.

---

## Pre-flight DB Findings

All queries run against live DB on 2026-06-07.

### Migration Number

```
SELECT MAX(version) FROM supabase_migrations.schema_migrations
→ 283
```

Next available migration: **284**. Confirmed correct per STATE.md (migrations 282-283 = Phase 103/104 work, applied).

### External ID Range for DC Officials

Range analysis: `-600001` to `-629999` is completely free (0 rows).

Occupied ranges in the `-500000` to `-700000` bucket:
- `-630001` to `-630NNN` = SF Council (Connie Chan etc.) — Connie Chan is -630001 (closest to -600001)
- `-640001` to `-640019` = San Jose Council + Mayor
- `-680NNN` to `-690021` = Portland/Multnomah/OR officials

The range **-600001 onward** is safe for DC officials. The full DC roster is ~26 politicians, so -600001 to -600030 is recommended. Gap to the nearest occupied row (-630001) is 30,000 slots — ample buffer.

### EHN DB State

```sql
SELECT p.id, p.full_name, p.photo_origin_url, o.id AS office_id, o.district_id
FROM essentials.politicians p
LEFT JOIN essentials.offices o ON o.politician_id = p.id
WHERE p.full_name ILIKE '%Eleanor%Norton%'
→ 0 rows
```

**EHN does not exist.** Must INSERT, not UPDATE. The NATIONAL_LOWER district for DC needs to be created (DCIN-02) before the office record can be inserted.

### DC Government State

```sql
SELECT id, name FROM essentials.governments WHERE state = 'DC'
→ 0 rows
```

No DC government row. DCIN-01 creates it fresh.

### geo_districts Layers (live DB)

```
ca_assembly: 80 rows
ca_senate:   40 rows
us_house:    52 rows
school_unified:    346 rows
school_elementary: 517 rows
school_secondary:  112 rows
dc_ward: 0 rows (does not exist)
```

### geofence_boundaries DC State

One row exists:
- `geo_id='1198'`, `mtfcc='G5200'`, `name='Delegate District (at Large)'`, `ocd_id='ocd-division/country:us/state:dc/cd:98'`

This is EHN's at-large congressional district from the US House national import. Not useful for ward geofencing.

### Current resolve_user_districts Default Layers

```
ARRAY['ca_assembly', 'ca_senate', 'us_house', 'school_unified', 'school_elementary', 'school_secondary']
```

`dc_ward` is NOT in the default. Adding DC ward geofencing requires extending both `resolve_user_districts` and `cache_user_districts` to include `dc_ward` in their `p_layers` default.

---

## TIGER Script Analysis

### Two Separate Tables — Critical Distinction

`essentials.geofence_boundaries` and `essentials.geo_districts` are **different tables** with different schemas and different use cases:

| Table | Written By | Read By | Purpose |
|-------|-----------|---------|---------|
| `essentials.geofence_boundaries` | `load-state-tiger-boundaries.ts` | `essentialsService.ts` (representative lookup, place matching) | General boundary matching, broader polygon queries |
| `essentials.geo_districts` | ogr2ogr + psql seed script (Phase 69 pattern) | `resolve_user_districts` RPC | Point-in-polygon for user district resolution (Path 0 geofencing) |

**For DCIN-03, the target is `essentials.geo_districts`, not `geofence_boundaries`.** The `load-state-tiger-boundaries.ts` script cannot be used directly for DCIN-03 — it writes to the wrong table.

### What `load-state-tiger-boundaries.ts` Actually Does (for DCIN-03)

The CONTEXT.md D-02/D-03/D-04 decisions ask to extend this script. However, based on the architecture above, adding DC to `STATE_LAYER_ALLOWLIST` in `load-state-tiger-boundaries.ts` would write to `geofence_boundaries`, not `geo_districts`. The geofencing geofence_boundaries table already has DC data (1 row). The missing piece is `geo_districts`.

**Resolution for planner:** The script extension per D-02/D-03/D-04 can proceed as decided — it adds 8 DC ward polygon rows to `geofence_boundaries` (useful for broader essentials queries). SEPARATELY, a seed script (following the Phase 69 `seed-tiger-districts.sh` pattern using ogr2ogr + psql) must import those same 8 ward polygons into `essentials.geo_districts` with `layer='dc_ward'`. This is 2 writes to 2 tables from the same TIGER shapefile.

### Current Script State

The `sldl` layer IS wired in `processLayer` — the comment "processLayer dispatch not yet wired — see 130-04" in the file header is outdated (written in the 130-03 skeleton). The `LAYER_DISPATCH` table has a full `sldl` entry, and `processLayer` streams and upserts records. The dispatch works for CA/TX/etc. sldl today.

What IS missing for DC sldl:
1. `DC` is not in `STATE_LAYER_ALLOWLIST`
2. `LAYER_DISPATCH['sldl'].district_type = 'STATE_LOWER'` — DC sldl must map to `'CITY_COUNCIL'` per D-03

### Required Changes to `load-state-tiger-boundaries.ts`

1. Add `DC: new Set(['sldl'])` to `STATE_LAYER_ALLOWLIST` (line ~35)
2. Add a `STATE_LAYER_TYPE_MAP` object alongside `STATE_LAYER_ALLOWLIST`:
   ```typescript
   const STATE_LAYER_TYPE_MAP: Record<string, Record<string, string>> = {
     DC: { sldl: 'CITY_COUNCIL' },
   };
   ```
3. In `processLayer`, when dispatching `sldl`, override `layerDef.district_type` with `STATE_LAYER_TYPE_MAP[state]?.[layer] ?? layerDef.district_type`
4. Add DC MTFCC pre-flight assertion block (expected = 8 ward polygons, FIPS `'11'`)
5. The `geofence_boundaries` write uses `layerDef.mtfcc = 'G5220'` for sldl — that's correct, no change needed
6. The `insertDistrictIfMissing` write with overridden `district_type='CITY_COUNCIL'` writes to `essentials.districts` — this is NOT what DCIN-02 uses (we're doing that via a clean migration), so `writeDistrictRow` should be `false` for DC sldl to avoid conflicting with the migration's district rows. Or: set it `true` but use idempotent WHERE NOT EXISTS guard (it already does that).

### TIGER 2024 DC SLDL Shapefile Details

- URL: `https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_11_sldl.zip`
- FIPS: `11` (DC is a state-equivalent)
- SLDLST field values: `'001'` through `'008'` (3-digit zero-padded, verified via Census geocoder)
- GEOID format: `11001` through `11008` (STATEFP `11` + SLDLST `001`-`008`)
- Number of records: 8 (one per ward)
- NAMELSAD: e.g. `'Ward 1'` through `'Ward 8'`
- OCD-ID: `ocd-division/country:us/state:dc/sldl:1` through `ocd-division/country:us/state:dc/sldl:8`
  (The `buildOcdId` helper strips leading zeros via `parseInt`: `'001'` → `1`)

### DCIN-03 Seed Script (geo_districts population)

Follows the Phase 69 `seed-tiger-districts.sh` pattern exactly:

```bash
# Download
curl -sSL https://www2.census.gov/geo/tiger/TIGER2024/SLDL/tl_2024_11_sldl.zip -o dc_sldl.zip
unzip dc_sldl.zip

# Reproject NAD83 → WGS84 and stage
ogr2ogr -f "PostgreSQL" -nlt MULTIPOLYGON -t_srs EPSG:4326 \
  PG:"$DATABASE_URL sslmode=require" tl_2024_11_sldl.shp \
  -nln tiger_stage -overwrite

# Insert into geo_districts with ON CONFLICT
psql "$DATABASE_URL" << 'SQL'
INSERT INTO essentials.geo_districts (layer, geoid, district_num, name, geom)
SELECT
  'dc_ward' AS layer,
  s."GEOID" AS geoid,
  CAST(CAST(s."SLDLST" AS INTEGER) AS TEXT) AS district_num,  -- '001' → '1'
  s."NAMELSAD" AS name,
  s.wkb_geometry AS geom
FROM tiger_stage s
ON CONFLICT (layer, geoid) DO UPDATE
  SET name = EXCLUDED.name,
      geom = EXCLUDED.geom;
SQL
```

This produces 8 rows: layer='dc_ward', geoid='11001'-'11008', district_num='1'-'8'.

### Migration Required: Extend RPC Defaults

A migration is needed in 105-01 to extend both RPCs (requires `DROP FUNCTION IF EXISTS` first due to signature change per v2.2 migration 094 lesson):

```sql
-- Drop both old signatures first (v2.2 lesson: CREATE OR REPLACE cannot change defaults without amending sig)
DROP FUNCTION IF EXISTS essentials.resolve_user_districts(float8, float8, text[]);
DROP FUNCTION IF EXISTS essentials.cache_user_districts(UUID, float8, float8, text[]);

CREATE OR REPLACE FUNCTION essentials.resolve_user_districts(
  p_lat    float8,
  p_lng    float8,
  p_layers text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary',
    'dc_ward'
  ]
) ...

CREATE OR REPLACE FUNCTION essentials.cache_user_districts(
  p_user_id UUID,
  p_lat     float8,
  p_lng     float8,
  p_layers  text[] DEFAULT ARRAY[
    'ca_assembly', 'ca_senate', 'us_house',
    'school_unified', 'school_elementary', 'school_secondary',
    'dc_ward'
  ]
) ...
```

**Important:** The signature of these functions does NOT change (same param count, same types). `CREATE OR REPLACE` alone might work here (no DROP needed) since only the DEFAULT value changes. But per the v2.2 pattern, dropping first is safer. The planner should opt for DROP + CREATE in a BEGIN/COMMIT block.

---

## DC Officials Complete Roster

All 26 new politicians confirmed from authoritative sources on 2026-06-07.

### DCOF-02 CORRECTION: Shadow Senators

CONTEXT.md and DCOF-02 name "Michael D. Brown" as the second shadow senator. This is INCORRECT as of 2026-06-07:

- **Michael D. Brown** — served junior shadow senator 2007–January 3, 2025. No longer in office.
- **Ankit Jain** — elected 2024, sworn in January 3, 2025. Current junior DC shadow senator. First Indian-American elected above ANC in DC. Voting rights attorney, DC statehood advocate.

**The planner must use Ankit Jain, not Michael D. Brown.** [VERIFIED: senatorjaindc.com/about + Michael Donald Brown Wikipedia]

### Mayor

| Name | Title | District | party |
|------|-------|----------|-------|
| Muriel Bowser | Mayor | DC Citywide (LOCAL_EXEC) | Democratic |

Photo: `https://mayor.dc.gov/biography/muriel-bowser` — official DC.gov biography page [VERIFIED: mayor.dc.gov]

### DC Council (13 members)

[VERIFIED: dccouncil.gov/councilmembers — fetched 2026-06-07]

| Name | Seat | District Row | Party |
|------|------|-------------|-------|
| Phil Mendelson | Chairman (At-Large) | At-large | Democratic |
| Anita Bonds | At-Large | At-large | Democratic |
| Robert C. White, Jr. | At-Large | At-large | Democratic |
| Christina Henderson | At-Large | At-large | Democratic |
| Doni Crawford | At-Large | At-large | Democratic |
| Brianne K. Nadeau | Ward 1 | CITY_COUNCIL Ward 1 | Democratic |
| Brooke Pinto | Ward 2 | CITY_COUNCIL Ward 2 | Democratic |
| Matthew Frumin | Ward 3 | CITY_COUNCIL Ward 3 | Democratic |
| Janeese Lewis George | Ward 4 | CITY_COUNCIL Ward 4 | Democratic |
| Zachary Parker | Ward 5 | CITY_COUNCIL Ward 5 | Democratic |
| Charles Allen | Ward 6 | CITY_COUNCIL Ward 6 | Democratic |
| Wendell Felder | Ward 7 | CITY_COUNCIL Ward 7 | Democratic |
| Trayon White, Sr. | Ward 8 | CITY_COUNCIL Ward 8 | Democratic |

Note: Ward 8 is Trayon White, Sr. — he was expelled Feb 2025, won special election July 2025, and rejoined council Aug 2025. The current holder of the Ward 8 seat is Trayon White, Sr. [VERIFIED: WTOP/HillRag reporting 2025]

Note: At-large members (non-Chairman) have 4 seats. All 5 at-large (including Chairman) share no ward-based district — they need a separate at-large district record or `district_id = NULL`. Review D-09: the 1 NATIONAL_LOWER district is for EHN + shadow senators. The Council at-large seats are a separate concern. See "At-Large District FK" section below.

### At-Large District FK for Council Members

CONTEXT.md D-09 creates 8 CITY_COUNCIL ward districts, 9 SCHOOL_BOARD, and 1 NATIONAL_LOWER. It does NOT create a CITY_COUNCIL at-large district for the Chairman or the 4 at-large council members.

For the at-large Council seats (Chairman + 4 at-large), there are two options:
- Option A: Create a 9th CITY_COUNCIL district record as "DC Citywide At-Large" (no tiger_geoid) — same pattern as SJ's `LOCAL_EXEC` for the Mayor
- Option B: Set `office.district_id` to the nearest citywide district and accept it as a convention

**Recommendation:** Add a 9th CITY_COUNCIL district (geo_id='dc-council-at-large', district_type='CITY_COUNCIL', tiger_geoid=NULL) for the 5 at-large Council seats. This keeps all Council offices in the same district_type. It does NOT conflict with D-09 which specifies "8 ward districts" — adding a 9th at-large is additive and consistent with D-07 (SBOE at-large follows the same pattern). **Flag for planner decision.**

### Attorney General

| Name | Title | Party |
|------|-------|-------|
| Brian Schwalb | Attorney General | Democratic |

Photo: `https://oag.dc.gov/about-oag/our-structure-divisions/about-attorney-general` [VERIFIED: oag.dc.gov]

### Shadow Senators

| Name | Title | Party | Notes |
|------|-------|-------|-------|
| Paul Strauss | Senior US Shadow Senator (D) | Democratic | Serving since 1997, reelected continuously |
| Ankit Jain | Junior US Shadow Senator | Democratic | Sworn in January 3, 2025; replaced Michael D. Brown |

Photos: Paul Strauss — Wikipedia or official statehood.dc.gov page. Ankit Jain — senatorjaindc.com [VERIFIED]

### Eleanor Holmes Norton

EHN is NOT in the DB. Must INSERT.

| Name | Title | Party | Notes |
|------|-------|-------|-------|
| Eleanor Holmes Norton | Delegate, DC at-large | Democratic | Serving since 1991; announced retirement — NOT seeking re-election in 2026 |

Photo: `https://bioguide.congress.gov/search/bio/N000147` (bioguide ID = N000147) [VERIFIED: bioguide.congress.gov]

Note: Per v2.3 lesson, check `https://unitedstates.github.io/images/congress/225x275/N000147.jpg` first — may be available from unitedstates CDN.

### DC School Board of Education (SBOE)

All 9 members [VERIFIED: sboe.dc.gov/page/board-biographies — fetched 2026-06-07]

| Name | Ward | Term | Photo path (relative to sboe.dc.gov) |
|------|------|------|--------------------------------------|
| Jacque Patterson | At-Large (President) | 2025–2029 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Patterson%20Headshot%202025.jpeg |
| Ben Williams | Ward 1 | 2023–2027 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Williams%20Headshot%202025.jpeg |
| Allister Chang | Ward 2 | 2025–2029 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Chang%20Headshot%202025.jpeg |
| Eric Goulet | Ward 3 (Vice President) | 2023–2027 | /sites/default/files/dc/sites/sboe/multimedia_content/images/photobatch-27-2.jpg |
| T. Michelle Colson | Ward 4 | 2025–2029 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Colson%20Headshot%202025.jpeg |
| Robert Henderson | Ward 5 | 2023–2027 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Henderson%20Headshot%202025.jpeg |
| Brandon Best | Ward 6 | 2023–2027 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Best%20Headshot%202025.jpeg |
| Eboni-Rose Thompson | Ward 7 | 2025–2029 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Thompson%20Headshot%202025.jpeg |
| LaJoy Johnson-Law | Ward 8 | 2025–2029 | /sites/default/files/dc/sites/sboe/multimedia_content/images/Johnson-Law%20Headshot%202025.jpeg |

Photo URL construction: `https://sboe.dc.gov` + path above.

### Photo URL Strategy Summary

| Body | Source | URL Pattern |
|------|--------|-------------|
| Mayor | mayor.dc.gov biography | `https://mayor.dc.gov/biography/muriel-bowser` |
| DC Council | dccouncil.gov member pages | `https://dccouncil.gov/council/[member-slug]/` |
| AG | oag.dc.gov | `https://oag.dc.gov/about-oag/our-structure-divisions/about-attorney-general` |
| SBOE | sboe.dc.gov | `https://sboe.dc.gov` + path from roster above |
| Shadow Senators | statehood.dc.gov or Wikipedia | Per senator page |
| EHN | bioguide.congress.gov / unitedstates CDN | `https://unitedstates.github.io/images/congress/225x275/N000147.jpg` (check first) |

For DC Council, photo URLs follow pattern: each councilmember has an individual page. The planner should use `https://dccouncil.gov/councilmembers/` as the `photo_origin_url` for all 13 council members unless individual portrait URLs are discovered during migration authoring.

---

## Migration Patterns

### Government Stub INSERT (DCIN-01)

Pattern from migration 087 (TX) and 217 (San Jose). `government_id` is a UUID on `essentials.governments`. DC geo_id = '11' (DC FIPS, consistent with TX = '48').

```sql
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'District of Columbia', 'LOCAL', 'DC', 'Washington', '11'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments
  WHERE name = 'District of Columbia' AND state = 'DC'
);
```

Note: `type` — prior city migrations use 'LOCAL'. DC is not technically a state government but it is the only government body for DC. Use `'LOCAL'` consistent with San Jose/SF pattern. (If a 'DISTRICT' type existed it might fit better, but the schema only has known values like 'STATE', 'LOCAL', 'County'.)

### District Records INSERT (DCIN-02)

Pattern from migration 217 (San Jose) — bulk VALUES with WHERE NOT EXISTS guard. Key column is `label` (not `name`).

The `government_id` FK column was confirmed present in the live schema. Subquery pattern:

```sql
INSERT INTO essentials.districts (geo_id, district_type, label, state, government_id)
SELECT v.geo_id, v.district_type, v.label, v.state,
       (SELECT id FROM essentials.governments WHERE name = 'District of Columbia' AND state = 'DC')
FROM (VALUES
  ('dc-ward-1', 'CITY_COUNCIL', 'Ward 1', 'DC'),
  ('dc-ward-2', 'CITY_COUNCIL', 'Ward 2', 'DC'),
  ...
  ('dc-ward-8', 'CITY_COUNCIL', 'Ward 8', 'DC'),
  ('dc-sboe-ward-1', 'SCHOOL_BOARD', 'SBOE Ward 1', 'DC'),
  ...
  ('dc-sboe-at-large', 'SCHOOL_BOARD', 'SBOE At-Large', 'DC'),
  ('dc-national-lower', 'NATIONAL_LOWER', 'District of Columbia At-Large', 'DC')
) AS v(geo_id, district_type, label, state)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = v.state
);
```

**Geo_id naming convention:** Use slug pattern consistent with SJ (`sj-council-district-N`). For DC: `dc-ward-1` through `dc-ward-8` for CITY_COUNCIL; `dc-sboe-ward-1` through `dc-sboe-ward-8` + `dc-sboe-at-large` for SCHOOL_BOARD; `dc-national-lower` for NATIONAL_LOWER.

These geo_ids are internal FK handles — they do NOT need to match TIGER GEOIDs. The `tiger_geoid` column (backfilled in DCIN-04) handles the TIGER join.

**At-large Council seat:** Planner decision required (see "At-Large District FK" above). If a 9th CITY_COUNCIL row is added: `('dc-council-at-large', 'CITY_COUNCIL', 'DC Council At-Large', 'DC')`.

### Politician + Office INSERT (DCOF-01/02/03)

Pattern from migration 218 (San Jose). WITH CTE + INSERT + CROSS JOIN:

```sql
-- Example: Ward 1 Council Member
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Brianne K. Nadeau', 'Brianne', 'Nadeau', 'Democratic',
          true, false, false, true, -600001, 'https://dccouncil.gov/...')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       NULL,   -- no chamber rows for DC (not created in this phase)
       p.id,
       'Council Member (Ward 1)', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-ward-1'
  AND d.district_type = 'CITY_COUNCIL'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );
```

Note: `chamber_id` is NULL. The San Jose migration created chambers first, but that requires a separate chamber design. For DC Phase 105, skip chambers (they are not required for FKs on the other tables). `chamber_id` is nullable in the offices schema.

Note: `party` should be `'Democratic'` (not `'Democrat'`) per the v2.6 party string normalization migration 126.

### EHN INSERT Pattern

EHN is a congressional delegate, not a local DC official, so she has a different title pattern:

```sql
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, bioguide_id, photo_origin_url)
  VALUES (gen_random_uuid(), 'Eleanor Holmes Norton', 'Eleanor', 'Norton', 'Democratic',
          true, false, false, true, -600030,
          'N000147',
          'https://unitedstates.github.io/images/congress/225x275/N000147.jpg')
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       p.id,
       'Delegate, District of Columbia', 'DC', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = 'dc-national-lower'
  AND d.district_type = 'NATIONAL_LOWER'
  AND d.state = 'DC'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );
```

Shadow senators use the same `dc-national-lower` district. The `last_name` for Ankit Jain is 'Jain', `first_name` = 'Ankit'.

---

## tiger_geoid Backfill Pattern (DCIN-04)

Adapted from migration 091. The join is `d.geo_id = gd.geoid` — but DC uses slug geo_ids (`dc-ward-1`) for `essentials.districts`, NOT TIGER GEOIDs. So the standard 091 join pattern DOES NOT APPLY directly.

The correct approach for DC: after the seed script populates `geo_districts` with `geoid='11001'`-`'11008'`, the backfill must match by district number, not by geo_id equality.

```sql
-- DCIN-04: tiger_geoid backfill for DC CITY_COUNCIL ward districts
-- Matches on CAST(district_num AS INT) = ward number derived from label
UPDATE essentials.districts d
SET tiger_geoid = gd.geoid
FROM essentials.geo_districts gd
WHERE d.tiger_geoid IS NULL
  AND d.state = 'DC'
  AND d.district_type = 'CITY_COUNCIL'
  AND gd.layer = 'dc_ward'
  AND CAST(gd.district_num AS INTEGER) = CAST(
    regexp_replace(d.geo_id, 'dc-ward-', '') AS INTEGER
  );
```

Or more cleanly, if the district rows use `label = 'Ward 1'`..`'Ward 8'` and geo_districts has `name = 'Ward 1'`..`'Ward 8'`:

```sql
UPDATE essentials.districts d
SET tiger_geoid = gd.geoid
FROM essentials.geo_districts gd
WHERE d.tiger_geoid IS NULL
  AND d.state = 'DC'
  AND d.district_type = 'CITY_COUNCIL'
  AND gd.layer = 'dc_ward'
  AND gd.district_num = regexp_replace(d.geo_id, 'dc-ward-', '');
```

This matches `gd.district_num='1'` with `d.geo_id='dc-ward-1'` by stripping the prefix.

**Alternative (simpler):** Hard-code the 8 pairs directly in the migration:

```sql
UPDATE essentials.districts SET tiger_geoid = '11001' WHERE geo_id = 'dc-ward-1' AND state = 'DC';
UPDATE essentials.districts SET tiger_geoid = '11002' WHERE geo_id = 'dc-ward-2' AND state = 'DC';
-- ... through 11008 / dc-ward-8
```

**Recommendation:** Use the hard-coded approach. 8 lines, zero regex ambiguity. Matches the idiomatic precedent of directly specifying known GEOIDs.

---

## Architecture Patterns

### DCIN-03 Import Flow (geo_districts)

```
TIGER 2024 Census FTP
  └── tl_2024_11_sldl.zip (DC FIPS=11, 8 ward polygons)
        │
        ├── ogr2ogr reproject NAD83→WGS84
        │     └── INSERT INTO essentials.geo_districts
        │           layer='dc_ward', geoid='11001'-'11008'
        │           district_num='1'-'8', MULTIPOLYGON 4326
        │
        └── load-state-tiger-boundaries.ts (DC sldl)
              └── INSERT INTO essentials.geofence_boundaries
                    geo_id='11001'-'11008', mtfcc='G5220'
```

### Path 0 DC User Flow (after all migrations)

```
DC user sets location
  └── cache_user_districts(user_id, lat, lng)
        └── resolve_user_districts(lat, lng, [..., 'dc_ward'])
              └── ST_Contains on essentials.geo_districts (dc_ward layer)
                    └── returns geoid='11003' for Ward 3 user
        └── writes connect.user_districts (user_id, 'dc_ward', '11003', '3')
  └── GET /api/account/districts
        └── reads connect.user_districts
              └── JOINs essentials.districts ON (tiger_geoid='11003', district_type='CITY_COUNCIL')
                    └── returns Ward 3 record with politician links
```

---

## Implementation Risks and Pitfalls

### PITFALL-1: sldl processLayer is NOT a stub

CONTEXT.md D-04 says "wire the sldl processLayer dispatch (currently throws 'not yet wired')". This is based on outdated information. The `load-state-tiger-boundaries.ts` processLayer function is fully wired — it streams records, resolves GEOID, computes OCD-IDs, and upserts to both `geofence_boundaries` and `essentials.districts`. The only required changes are (1) adding DC to `STATE_LAYER_ALLOWLIST` and (2) adding `STATE_LAYER_TYPE_MAP` for the district_type override. D-04 is a simpler task than it appears.

### PITFALL-2: geo_districts vs geofence_boundaries

The `load-state-tiger-boundaries.ts` script writes to `geofence_boundaries`. Point-in-polygon geofencing (Path 0) uses `geo_districts`. Two separate writes are required from the same TIGER shapefile. Missing the `geo_districts` write means DC users are never geofenced to their ward even after the script runs.

### PITFALL-3: resolve_user_districts default layers

Even after populating `geo_districts` with dc_ward data, DC users will NOT be geofenced unless `dc_ward` is in the `p_layers` default array. A migration must extend both RPCs. Failing to do this causes silent failure — the RPC runs but simply doesn't look at the dc_ward layer.

### PITFALL-4: EHN is a fresh INSERT, not an UPDATE

CONTEXT.md D-08 was written assuming EHN might already have a DB record. The live DB has zero rows for her. The plan must INSERT, not UPDATE. The NATIONAL_LOWER district (DCIN-02) must be created before EHN's office record can be inserted.

### PITFALL-5: Ankit Jain, not Michael D. Brown

CONTEXT.md DCOF-02 names "Michael D. Brown" as a shadow senator. He left office January 3, 2025. The correct person is Ankit Jain. Inserting a record for a person who no longer holds office would be wrong data. The planner should insert Ankit Jain.

### PITFALL-6: At-large Council seat has no district in D-09

D-09 creates 8 CITY_COUNCIL ward districts + 9 SCHOOL_BOARD + 1 NATIONAL_LOWER = 18 total. The Chairman and 4 at-large council members cannot FK to a ward district (they represent the whole city). No at-large CITY_COUNCIL district is specified. The planner must either add a 19th district (`dc-council-at-large`) or use NULL for `district_id` on at-large council office records. NULL is allowed per the schema (nullable FK) but means those officials won't surface via geofencing. Adding the at-large district (pattern from D-07 SBOE at-large) is the cleaner solution.

### PITFALL-7: DC government type

No `'DISTRICT'` type exists in the `essentials.governments.type` enum/constraint. Use `'LOCAL'` (consistent with city governments) rather than inventing a new type. If a constraint violation occurs, check the governments table's CHECK constraint.

### PITFALL-8: Windows ogr2ogr session pooler

Per the v2.2 geospatial pattern: on Windows, use the session pooler URL (`aws-0-*.pooler.supabase.com:5432`), NOT the direct DB host. Set `PROJ_LIB="C:/Program Files/GDAL/projlib"`. The DC sldl seed follows the same procedure.

### PITFALL-9: Ward 8 bribery context

Trayon White, Sr. (Ward 8) has been indicted for bribery (federal charges) and was expelled from council in Feb 2025, but won the special election in July 2025 and rejoined in Aug 2025. He IS the current ward 8 member as of 2026-06-07. Insert him as `is_incumbent=true`, `is_active=true`. Include a `notes` field comment in the migration acknowledging the legal context is outside platform scope.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | DC government `type` = `'LOCAL'` is accepted by schema CHECK constraint | Migration Patterns | Migration will fail with constraint violation; use 'STATE' or check valid enum values |
| A2 | EHN's bioguide photo `https://unitedstates.github.io/images/congress/225x275/N000147.jpg` is a valid non-404 URL | Photo URLs | photo_origin_url set but image missing; need to fall back to norton.house.gov portrait |
| A3 | The `dc_ward` layer name will not conflict with any future state abbreviation convention | Script + migration | Low risk — established precedent with 'ca_assembly', 'ca_senate', 'us_house' |
| A4 | SBOE photo URLs at sboe.dc.gov are stable long-term | Photo URLs | URLs could change after SBOE redesign; acceptable risk for photo_origin_url (not cached) |
| A5 | Ankit Jain is still the junior shadow senator as of 2026-06-07 | DCOF-02 | Term dates not confirmed; verify current DC shadow senator page before finalizing |

---

## Open Questions (RESOLVED)

1. **At-large Council district: add or use NULL?**
   - RESOLVED: Add `dc-council-at-large` CITY_COUNCIL district (19th district total). Plan 105-01 Task 1 creates it with `tiger_geoid = NULL`, consistent with D-07 (SBOE at-large pattern). All 5 at-large Council offices FK to this district.

2. **Should `load-state-tiger-boundaries.ts` also write to `geo_districts`?**
   - RESOLVED: Keep separate. Plan 105-01 Task 3 runs the TypeScript script for `geofence_boundaries` and a separate `seed-dc-ward-geo-districts.sh` for `geo_districts`. Unifying is a future Phase 130 refactor.

3. **DC government `type` value**
   - RESOLVED: Use `'LOCAL'` (same as San Jose/SF). Plan 105-01 Task 1 includes a pre-flight `SELECT DISTINCT type FROM essentials.governments` verification before writing the INSERT.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| ogr2ogr (GDAL) | DCIN-03 geo_districts seed | [ASSUMED - was used in Phases 69/71] | Unknown | Cannot reproject without it; must install |
| psql | DCIN-03 geo_districts seed | [ASSUMED - present from prior work] | Unknown | Use pg client in TypeScript if needed |
| DATABASE_URL | All migrations + seed | Available | — | — |
| Node.js / tsx | load-state-tiger-boundaries.ts | Available | v24.13.0 | — |

GDAL/ogr2ogr was used in Phase 69-02 for CA TIGER import. Assume still installed at `C:/Program Files/GDAL/`. Verify with `ogr2ogr --version` before executing DCIN-03.

---

## Sources

### Primary (HIGH confidence)
- Live DB queries (2026-06-07) — migration max, external_id ranges, EHN state, geo_districts layers, governments table
- `supabase/migrations/20260509000001_089_tiger_geo_districts_schema.sql` — geo_districts schema
- `supabase/migrations/20260509000003_091_tiger_geoid_backfill.sql` — backfill pattern
- `backend/migrations/217_sj_government_structure.sql` — government/district INSERT pattern
- `backend/migrations/218_sj_officials.sql` — politician/office INSERT pattern
- `backend/scripts/load-state-tiger-boundaries.ts` — TIGER loader, confirmed processLayer is wired
- `dccouncil.gov/councilmembers/` (fetched 2026-06-07) — DC Council roster
- `sboe.dc.gov/page/board-biographies` (fetched 2026-06-07) — SBOE roster with photo URLs

### Secondary (MEDIUM confidence)
- `senatorjaindc.com/about` (fetched 2026-06-07) — Ankit Jain confirmation + Michael D. Brown exit
- Census Geocoder (geocoding.geo.census.gov) — DC ward GEOID format '11001'-'11008'
- Wikipedia: Michael Donald Brown, Trayon White Ward 8 special election

### Tertiary (LOW confidence)
- TIGER 2024 SLDL URL structure (assumed from FIPS_TO_STATE map in script confirming FIPS 11 = DC)

---

## Metadata

**Confidence breakdown:**
- Migration numbers: HIGH — queried live DB
- External ID ranges: HIGH — queried live DB
- EHN state: HIGH — queried live DB (zero rows)
- DC government state: HIGH — queried live DB (zero rows)
- DC officials roster: HIGH — fetched official pages
- SBOE roster + photo URLs: HIGH — fetched sboe.dc.gov directly
- Shadow senator roster: HIGH — fetched senatorjaindc.com directly
- TIGER GEOID format: HIGH — confirmed via Census geocoder
- geo_districts vs geofence_boundaries: HIGH — confirmed from schema + live data
- processLayer wiring: HIGH — read source code directly
- RPC default layers: HIGH — queried live DB function signature

**Research date:** 2026-06-07
**Valid until:** 2026-07-07 (30 days — personnel data and DB state can shift)
