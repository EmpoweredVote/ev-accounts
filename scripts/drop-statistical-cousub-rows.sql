-- =============================================================================
-- drop-statistical-cousub-rows.sql
--
-- Removes the 58 statistical county-subdivision rows that the FIRST municipal
-- boundary load (ev-accounts#541, wave 1) put into essentials.geofence_boundaries
-- before that loader learned to filter them:
--
--     MI  40   PA  1   OH  17        all mtfcc = 'G4040', all imported 2026-09-18
--
-- ---------------------------------------------------------------------------
-- WHY A SCRIPT AND NOT A RE-RUN OF THE LOADER
-- ---------------------------------------------------------------------------
-- ⚠⚠ THE LOADER CANNOT DO THIS. It is INSERT ... ON CONFLICT DO UPDATE and has
-- no DELETE. Re-running it with the Z-class filter simply omits these rows from
-- staging; it does not remove the rows already in the table. A "refresh" would
-- update imported_at on everything else and leave all 58 exactly where they are.
-- Saying otherwise — as we did, to Civic Spaces — was wrong.
--
-- ---------------------------------------------------------------------------
-- WHY THESE ROWS SHOULD GO
-- ---------------------------------------------------------------------------
-- TIGER CLASSFP Z1/Z3/Z5/Z9 are Census County Divisions and unorganized
-- territories: statistical areas, not governments. TIGER tags them G4040, the
-- same MTFCC as a real township, and CLASSFP DOES NOT SURVIVE THE IMPORT — this
-- table has no CLASSFP and no FUNCSTAT column. So once loaded, nothing in the
-- row distinguishes a statistical area from a government.
--
-- ⚠ Twelve of Ohio's seventeen are named "... township" — `Columbus City
-- township`, `Medina City township`, `Wayne township`. They are not named
-- "County subdivisions not defined" and carry no " CCD" suffix, so a name-based
-- sweep cannot find them, and a human reviewing the list would pass all twelve.
-- That is why they are enumerated by GEOID below rather than matched by pattern.
--
-- ---------------------------------------------------------------------------
-- WHY ENUMERATED, NOT "DELETE WHAT IS NOT IN STAGING"
-- ---------------------------------------------------------------------------
-- ⚠⚠ This table has MULTIPLE WRITERS — ~19 distinct import days, and 263 rows
-- appeared between two of our own measurements on 2026-09-18. A sync-style
-- "delete anything not in my staging set" would silently destroy another team's
-- rows. Every id below was read from the 2024 TIGER source files, verified
-- present, and is deleted by exact match. The script REFUSES to commit unless
-- exactly 58 rows go.
--
-- USAGE (same connection rules as the loader — session pooler, port 5432):
--     psql "$DB_URL" -v ON_ERROR_STOP=1 -f scripts/drop-statistical-cousub-rows.sql
-- =============================================================================

BEGIN;

CREATE TEMP TABLE _statistical_cousub(geo_id text PRIMARY KEY) ON COMMIT DROP;

INSERT INTO _statistical_cousub(geo_id) VALUES
  -- Michigan — 40, all CLASSFP Z9 ("County subdivisions not defined")
  ('2600100000'),('2600300000'),('2600500000'),('2600700000'),('2600900000'),
  ('2601100000'),('2601300000'),('2601700000'),('2601900000'),('2602100000'),
  ('2602900000'),('2603100000'),('2603300000'),('2604100000'),('2604700000'),
  ('2605300000'),('2605500000'),('2606100000'),('2606300000'),('2606900000'),
  ('2608300000'),('2608900000'),('2609500000'),('2609700000'),('2609900000'),
  ('2610100000'),('2610300000'),('2610500000'),('2610900000'),('2611500000'),
  ('2612100000'),('2612700000'),('2613100000'),('2613900000'),('2614100000'),
  ('2614700000'),('2615100000'),('2615300000'),('2615700000'),('2615900000'),
  -- Pennsylvania — 1, CLASSFP Z9
  ('4204900000'),
  -- Ohio — 5 CLASSFP Z9 ("County subdivisions not defined")
  ('3900700000'),('3903500000'),('3904300000'),('3908500000'),('3909300000'),
  -- Ohio — 12 CLASSFP Z1, EVERY ONE NAMED "... township". These are the rows a
  -- name-based sweep cannot see and a human reviewer would wave through.
  ('3903329176'),  -- Galion City township
  ('3904118010'),  -- Columbus City township
  ('3904121469'),  -- Delaware City township
  ('3904175620'),  -- Sunbury Village township
  ('3904183349'),  -- Westerville City township
  ('3904541740'),  -- Lancaster City township
  ('3908966396'),  -- Reynoldsburg City township
  ('3909567752'),  -- Roche de Boeuf township
  ('3910348808'),  -- Medina City township
  ('3910371488'),  -- Seville Village township
  ('3910782206'),  -- Wayne township
  ('3911378625');  -- Union City township

-- ── Safety, re-checked at run time rather than trusted from a measurement ────
DO $$
DECLARE
  n_listed   int;
  n_present  int;
  n_tt       int;
  n_slices   int;
BEGIN
  SELECT count(*) INTO n_listed FROM _statistical_cousub;
  IF n_listed <> 58 THEN
    RAISE EXCEPTION 'expected 58 enumerated geoids, found %', n_listed;
  END IF;

  SELECT count(*) INTO n_present
    FROM essentials.geofence_boundaries g
    JOIN _statistical_cousub z ON z.geo_id = g.geo_id
   WHERE g.mtfcc = 'G4040';
  IF n_present <> 58 THEN
    RAISE EXCEPTION 'expected 58 matching G4040 rows present, found % — the table has changed since this script was written; re-measure before deleting', n_present;
  END IF;

  -- A geoid referenced by a Treasury Tracker entity is coverage, not noise.
  SELECT count(*) INTO n_tt
    FROM treasury.municipalities m
    JOIN _statistical_cousub z ON z.geo_id = m.geoid;
  IF n_tt <> 0 THEN
    RAISE EXCEPTION '% TT entities reference these geoids — deleting would open a coverage gap', n_tt;
  END IF;

  -- A live Civic Spaces slice on one of these would lose its boundary.
  SELECT count(*) INTO n_slices
    FROM civic_spaces.slices s
    JOIN _statistical_cousub z ON z.geo_id = s.geoid;
  IF n_slices <> 0 THEN
    RAISE EXCEPTION '% Civic Spaces slices sit on these geoids — not ours to remove', n_slices;
  END IF;
END $$;

-- ── The delete, scoped to G4040 so a same-geoid row at another layer survives ─
-- ⚠ Done in plpgsql with GET DIAGNOSTICS, NOT with `\gset` + a DO block: psql
-- does not interpolate :variables inside dollar-quoted strings, so the guard
-- would have been a syntax error rather than a guard.
DO $$
DECLARE n int;
BEGIN
  DELETE FROM essentials.geofence_boundaries g
   USING _statistical_cousub z
   WHERE g.geo_id = z.geo_id
     AND g.mtfcc  = 'G4040';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 58 THEN
    RAISE EXCEPTION 'deleted % rows, expected 58 — rolling back', n;
  END IF;
  RAISE NOTICE 'deleted % statistical G4040 rows (MI 40, PA 1, OH 17)', n;
END $$;

COMMIT;

-- ── Verification, printed after the commit ───────────────────────────────────
\echo ''
\echo '--- statistical G4040 rows still detectable, by state (expect IN 2 only) ---'
SELECT left(geo_id,2) AS fips, count(*) AS rows
  FROM essentials.geofence_boundaries
 WHERE mtfcc = 'G4040'
   AND (name = 'County subdivisions not defined' OR right(geo_id,5) = '00000')
 GROUP BY 1 ORDER BY 1;

\echo ''
\echo '--- G4040 totals by state (MI 1540, PA 2572, OH 1590, others unchanged) ---'
SELECT left(geo_id,2) AS fips, count(*) AS g4040
  FROM essentials.geofence_boundaries
 WHERE mtfcc = 'G4040'
 GROUP BY 1 ORDER BY 2 DESC;

\echo ''
\echo '--- TT coverage must still be ZERO unmatched ---'
WITH tt AS (
  SELECT state, geoid FROM treasury.municipalities
   WHERE geoid IS NOT NULL AND length(geoid) IN (7,10)
)
SELECT count(*) AS tt_entities,
       count(*) FILTER (WHERE NOT EXISTS (
         SELECT 1 FROM essentials.geofence_boundaries g
          WHERE g.geo_id = tt.geoid AND g.mtfcc IN ('G4110','G4040'))) AS still_unmatched
  FROM tt;
