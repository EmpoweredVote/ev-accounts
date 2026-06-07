# Phase 105: DC Infrastructure + Official Records - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 105 delivers the complete DC data foundation — government stub, all district records (ward + SBOE + EHN at-large), TIGER 2024 ward boundary polygons for geofencing, and ~26 politician + office records with photos. No new API endpoints. Phases 106 (stances) and 107 (finance) depend entirely on valid FK targets created here.

**Requirements in scope:** DCIN-01, DCIN-02, DCIN-03, DCIN-04, DCOF-01, DCOF-02, DCOF-03, DCOF-04

**Out of scope:** DC stances (Phase 106), DC finance (Phase 107), DC elections (DCEL future), ANC members, non-elected DC officials.

</domain>

<decisions>
## Implementation Decisions

### Plan Split

- **D-01:** 2 plans for this phase.
  - **105-01** — DCIN infrastructure: government stub, district records, TIGER ward import script update + execution, tiger_geoid backfill (DCIN-01 through DCIN-04)
  - **105-02** — DCOF official records: ~26 politician + office records + photo_origin_url + EHN full update (DCOF-01 through DCOF-04)
  - 105-01 gates 105-02 via FK constraint (office records require district_id to exist)

### TIGER Ward Import

- **D-02:** Extend `backend/scripts/load-state-tiger-boundaries.ts` — do NOT write a new one-off script. Add `DC: new Set(['sldl'])` to `STATE_LAYER_ALLOWLIST`.
- **D-03:** Add a `STATE_LAYER_TYPE_MAP` alongside `STATE_LAYER_ALLOWLIST`: `{ DC: { sldl: 'CITY_COUNCIL' } }`. DC's `sldl` maps to `CITY_COUNCIL` district type, NOT `STATE_LOWER` like CA/TX/etc.
- **D-04:** Wire the `sldl` processLayer dispatch in the existing script (currently throws "not yet wired — see 130-04"). Completing this dispatch for DC is in scope for 105-01.
- **D-05 (pre-decided):** Layer discriminator name = `dc_ward` (established in STATE.md scope notes). TIGER source = `tl_2024_11_sldl.zip` (DC FIPS = 11). 8 ward polygons.

### At-Large / Shadow Senator FK Structure

- **D-06:** Shadow Senators (Paul Strauss + Michael D. Brown) → `office.district_id` points to the DC NATIONAL_LOWER district (the same district record created for EHN in DCIN-02). Shadow Senators are DC's non-voting federal delegates — sharing EHN's district is conceptually correct.
- **D-07:** SBOE at-large seat → SCHOOL_BOARD district record (the 9th SBOE district in DCIN-02), `tiger_geoid = NULL`. At-large SBOE member won't surface via ward-based Path 0 geofencing lookup (acceptable — no ward geometry for at-large).

### Eleanor Holmes Norton (EHN) Migration Scope

- **D-08:** Full update — NOT photo-only. Verify her existing office record exists and points to the new DC NATIONAL_LOWER district created in DCIN-02. If the office record is missing or points to a wrong district, INSERT or UPDATE it. Update `photo_origin_url` if null. Query her current DB state before writing any UPDATE (use `WHERE full_name = 'Eleanor Holmes Norton'` after confirming exact name in live DB per v2.3 senator lesson).

### District Record Structure

- **D-09:** 18 total district records for DC in DCIN-02:
  - 8 × `CITY_COUNCIL` ward districts (Ward 1–8), all FK'd to DC government stub — these get `tiger_geoid` backfilled in DCIN-04
  - 9 × `SCHOOL_BOARD` seat districts (Ward 1–8 + 1 at-large) — 8 ward-based + 1 at-large with `tiger_geoid = NULL`
  - 1 × `NATIONAL_LOWER` at-large delegate seat (for EHN + Shadow Senators)
- **D-10:** All 18 district records FK to the DC government stub created in DCIN-01.

### Migration Numbers

- **D-11:** Next available migration is 284. Verify against `SELECT MAX(version) FROM supabase_migrations.schema_migrations` at pre-flight before writing any migration file — migrations 282–283 (visible in git status) must be confirmed applied. 105-01 will use migrations 284+; 105-02 will use the next available after 105-01 completes.

### External ID Ranges

- **D-12:** DC politicians need a distinct negative external_id range. Ranges consumed: senators (-400001 to -400090), 2026 candidates (-400101 to -400143). City officials (SF/SJ/SD/Berkeley/Fremont) used ranges starting at -500001. Use **-600001 onward** for DC officials to avoid collision. Verify exact city official ranges in DB at pre-flight before committing to this range.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements + Roadmap
- `.planning/REQUIREMENTS.md` — DCIN-01/02/03/04 + DCOF-01/02/03/04 exact requirement text; out-of-scope list
- `.planning/ROADMAP.md` §Phase 105 — Goal, depends-on, requirements list
- `.planning/STATE.md` §v2.8 Scope Notes — dc_ward layer name decision, DC official count, district types, FEC/OCF guidance, migration number derivation

### TIGER / Geospatial Infrastructure
- `supabase/migrations/20260509000001_089_tiger_geo_districts_schema.sql` — `essentials.geo_districts` schema: layer+geoid UNIQUE, GIST index, RLS; patterns to replicate for dc_ward rows
- `supabase/migrations/20260509000003_091_tiger_geoid_backfill.sql` — tiger_geoid backfill pattern; documents dual-column `(tiger_geoid, district_type)` join requirement and why single-column fails
- `backend/scripts/load-state-tiger-boundaries.ts` — script to extend for DC; see `STATE_LAYER_ALLOWLIST` (add DC) and note that `processLayer` dispatch for `sldl` is currently a stub that throws

### DC Official Records
- `empowered-accounts-design.md` — full essentials schema: `governments`, `districts`, `politicians`, `offices` tables with column definitions
- `empowered-vote-primer.md` — platform philosophy + schema conventions; read before writing any code

### Pattern References (prior city work)
- `supabase/migrations/20260509000002_090_tiger_resolve_user_districts_rpcs.sql` — `resolve_user_districts` + `cache_user_districts` RPCs; Path 0 fast path pattern
- `supabase/migrations/20260501054106_087_tx_schema_geo_id_state_county.sql` — government stub INSERT pattern: `(name, type, state, city, geo_id)` shape

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/load-state-tiger-boundaries.ts` — extend directly; handles TIGER download, ogr2ogr EPSG:4269→4326 reprojection, shapefile parsing, idempotent `INSERT ... ON CONFLICT`
- `supabase/migrations/20260509000003_091_tiger_geoid_backfill.sql` — exact SQL pattern for tiger_geoid UPDATE via district_type filter; copy and adapt for `CITY_COUNCIL` + `dc_ward` layer

### Established Patterns
- **`(layer, geoid)` UNIQUE constraint** on `essentials.geo_districts` — seed scripts must use `INSERT ... ON CONFLICT (layer, geoid) DO NOTHING` for idempotency
- **GIST index mandatory** on `geom` column — `CREATE INDEX IF NOT EXISTS idx_geo_districts_geom ON essentials.geo_districts USING GIST (geom)` already exists; no new index needed for dc_ward rows
- **Dual-column join required**: always `(tiger_geoid, district_type)` together — never single column (SLDL + SLDU share geoid format)
- **`SET search_path = ''`** on all SECURITY DEFINER functions; PostGIS calls = `public.ST_Contains`, `public.ST_SetSRID`, `public.ST_MakePoint`
- **`ST_MakePoint(lng, lat)`** — X then Y (longitude first); never reverse
- **`DROP FUNCTION IF EXISTS`** before changing function arity (v2.2 migration 094 lesson)
- **ogr2ogr session pooler on Windows** — DC host DNS may fail IPv6; use `aws-0-*.pooler.supabase.com:5432`; set `PROJ_LIB="C:/Program Files/GDAL/projlib"`
- **DB full_name check before name-based SQL** — always query live DB for exact `full_name` before writing `WHERE full_name = '...'` UPDATE conditions (v2.3 Schiff lesson: DB stores 'Adam B. Schiff', not 'Adam Schiff')
- **Migration number pre-flight** — run `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing any migration number (v2.3 lesson: plan said 172, corrected to 174)

### Integration Points
- `essentials.governments` → FK target for all DC district records
- `essentials.districts` → FK target for `essentials.offices.district_id`; tiger_geoid used in Path 0 hot-path join
- `essentials.geo_districts` (layer=`dc_ward`) → feeds `essentials.resolve_user_districts` RPC for DC users
- `connect.user_districts` → cache table written by `cache_user_districts` RPC after location-set for DC users

</code_context>

<specifics>
## Specific Ideas

- **DC government geo_id**: Use `'11'` (DC FIPS state-equivalent code) — consistent with TX using `'48'` in migration 087.
- **DC SBOE at-large seat**: Create the at-large SCHOOL_BOARD district with `tiger_geoid = NULL`. Downstream Phase 106 SBOE at-large member won't surface via ward geofencing but will still appear via government join.
- **EHN pre-flight query**: Before writing 105-02 migration, researcher should run `SELECT p.id, p.full_name, p.photo_origin_url, o.id AS office_id, o.district_id FROM essentials.politicians p LEFT JOIN essentials.offices o ON o.politician_id = p.id WHERE p.full_name ILIKE '%Eleanor%Norton%'` to get her UUID, office state, and current district_id.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 130 full sldl generalization** — the script extension for DC wires just enough of the sldl dispatch to handle FIPS=11. Full multi-state sldl generalization (other state lower chambers) remains Phase 130 scope.
- **DC school board geofencing** — SBOE ward-based members do have ward geometry (same as CITY_COUNCIL wards), but geofencing school board members via user_districts is a future enhancement (not in v2.8 scope).

</deferred>

---

*Phase: 105-DC Infrastructure + Official Records*
*Context gathered: 2026-06-07*
