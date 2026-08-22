-- verify-nc-place-import.sql — NC wave 2 (Durham). Read-only; run after the `place` load.
--
-- 🔴 NOT RUN YET as of authoring: Task 1 only writes this file. The rows it checks are created
-- by Task 1 Step 4 (the real, non-dry-run load), which is controller-only in this pass because
-- it writes to production and requires a `postgres`-owned `REFRESH MATERIALIZED VIEW CONCURRENTLY
-- essentials.geofence_child_county` afterward (places nest inside counties). Run this file only
-- after that load and refresh have both completed.

\echo '== G4110 incorporated places (expect 552) =='
SELECT count(*) AS g4110_count
FROM essentials.geofence_boundaries
WHERE state = '37' AND mtfcc = 'G4110';

-- 🔴 THIS IS THE CDP GUARD. A Census Designated Place (G4210) is a statistical area, not a
-- government — loading one would invent a fake municipality with no elected officials, invisible
-- and unfixable downstream. The loader's G4110 filter (load-state-tiger-boundaries.ts) is supposed
-- to keep every G4210 record out; this assertion is what actually PROVES the filter held, rather
-- than trusting that it did.
\echo '== G4210 CDPs (expect 0 — the loader must never write these) =='
SELECT count(*) AS g4210_count
FROM essentials.geofence_boundaries
WHERE state = '37' AND mtfcc = 'G4210';

-- Note on why this file, unlike verify-nc-tiger-import.sql, does NOT pair mtfcc with a second
-- discriminator in its geo_id lookups: geo_id is NOT unique across TIGER layers in this schema in
-- general (verify-nc-tiger-import.sql's own comment documents 85 NC legislative districts sharing
-- a geo_id with a county). For `place`, TIGER geo_ids are 7-character place codes (e.g. Durham
-- city = '3719000'), which cannot collide with the 5-character county/legislative geo_ids used
-- elsewhere in NC — so a plain geo_id lookup is safe HERE specifically. This is a deliberate,
-- verified exception, not an oversight carried over from the sibling file.
--
-- 🔴 FUNCSTAT is NOT a stored column on essentials.geofence_boundaries (schema checked 2026-08-22:
-- id, geo_id, ocd_id, name, state, mtfcc, geometry, source, valid_from, valid_to, imported_at,
-- quality_flag — no funcstat). It exists only in the source TIGER dbf and is consumed pre-write by
-- the loader's filters, never persisted. This query can therefore only assert Durham's geo_id/name
-- made it into the table — it cannot re-check FUNCSTAT post-load. FUNCSTAT='A' for Durham
-- (GEOID 3719000) was confirmed directly against the raw TIGER 2024 FIPS 37 place shapefile on
-- 2026-08-22 (read-only shapefile inspection, no DB writes): of the 552 G4110 records, 549 are
-- FUNCSTAT='A' and 3 are FUNCSTAT='I' (inactive) — NC's `place` layer does not filter by FUNCSTAT
-- (unlike WI/MA `cousub`), matching every other state's `place` handling in
-- load-state-tiger-boundaries.ts. Durham itself is one of the 549 'A' records.
\echo '== Durham city present (expect 1 row; FUNCSTAT A confirmed pre-load, not a stored column) =='
SELECT geo_id, name
FROM essentials.geofence_boundaries
WHERE state = '37' AND mtfcc = 'G4110' AND geo_id = '3719000';

\echo '== Durham City Hall point-in-polygon (expect 1 row: 3719000) =='
SELECT g.geo_id, g.name
FROM essentials.geofence_boundaries g
WHERE g.state = '37' AND g.mtfcc = 'G4110'
  AND public.ST_Covers(
        g.geometry,
        public.ST_SetSRID(public.ST_MakePoint(-78.8996816092, 35.996066837243), 4326)
      );
