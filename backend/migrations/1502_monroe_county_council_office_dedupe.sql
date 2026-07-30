-- 1502_monroe_county_council_office_dedupe.sql
--
-- Monroe County, Indiana has a CARTESIAN office-duplication bug: the four
-- "Monroe County Council District N" offices were created against EVERY Monroe County district row,
-- not just the four council districts. Result: 14 copies of each title, 56 offices across 17
-- districts, attached to things like "Monroe County Assessor", "Monroe County Sheriff",
-- "Monroe County Treasurer", "Monroe County Circuit Court Clerk" and "At-Large".
--
-- All 56 are termless, so per ADR 0002 every one of them is invisible and nothing errors — which is
-- exactly why this survived. It surfaced only when `npm run check:reachability` flagged the four real
-- council districts as DEAD_GEOGRAPHY (polygons that resolve nobody).
--
-- Split:
--   KEEP    4 offices on `18105-mcc-d1` .. `-d4` — the districts carrying the real council-district
--           polygons imported by scripts/import-mcc-district-polygons.ts (phase 121).
--   DELETE 52 offices on `geo_id 18105` — the county-wide polygon. A council DISTRICT seat has no
--           business hanging off the whole-county geography, and 13 copies of it even less.
--
-- WHY THIS RUNS BEFORE SEEDING. The obvious next step for Monroe was "seed the 4 council members",
-- and that would have been actively harmful: choosing 4 of 56 identically-titled offices leaves 52
-- ambiguous duplicates behind, which is precisely the condition migrations 1495, 1496 and 1498
-- existed to clean up. Dedupe first, seed second.
--
-- THE RACE TRAP, CHECKED: `races.office_id` is ON DELETE NO ACTION, so a race would block the delete
-- (the same trap `candidate_staging` set in migration 1495). There are exactly 4 such races — 2026
-- Indiana Primary, 2026-05-05, one candidate each — and ALL FOUR are on the KEEPERS, none on a
-- duplicate. So nothing needs repointing. The pre-flight re-asserts this rather than trusting it.
--
-- NOT IN SCOPE, needs a human decision: "Monroe County Commissioner District N" has the same bug —
-- 13 termless offices across 13 districts. Unlike Council there is NO commissioner-district polygon
-- anywhere in the DB, so there is no obvious keeper to dedupe toward, and Monroe elects 3
-- commissioners rather than 4. Left alone deliberately.
--
-- ALSO STILL OPEN: the 4 surviving council offices remain UNSEEDED. The 4 races above are 2026
-- PRIMARY contests, so their candidates are nominees, NOT officeholders — do not seat them from that.
-- Roster research is a separate job, and per the lesson in migration 1500 it must not come from the
-- GIS layer's `Rep` attribute, which goes stale.
--
-- Idempotent: selects only offices still in the pre-fix shape, so a re-run matches zero rows.

BEGIN;

-- ── pre-flight ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_dupes int; v_keepers int; v_terms int; v_holders int; v_races int;
BEGIN
  SELECT count(*) INTO v_dupes
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%'
     AND d.geo_id = '18105';
  SELECT count(*) INTO v_keepers
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%'
     AND d.geo_id LIKE '18105-mcc-%';

  IF v_keepers <> 4 THEN
    RAISE EXCEPTION '1502: expected 4 keeper offices on the mcc polygons, found %', v_keepers;
  END IF;
  IF v_dupes NOT IN (0, 52) THEN
    RAISE EXCEPTION '1502: expected 52 duplicates (fresh) or 0 (re-run), found % — partial state', v_dupes;
  END IF;
  IF v_dupes = 0 THEN
    RAISE NOTICE '1502: already applied — statements will match zero rows';
  END IF;

  -- refuse to delete anything occupied, or anything carrying a race
  SELECT count(*) INTO v_terms
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%'
     AND d.geo_id = '18105';
  IF v_terms <> 0 THEN
    RAISE EXCEPTION '1502: % duplicate offices carry an office_terms row — aborting', v_terms;
  END IF;

  SELECT count(*) INTO v_holders
    FROM essentials.office_current_holder h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%'
     AND d.geo_id = '18105' AND h.politician_id IS NOT NULL;
  IF v_holders <> 0 THEN
    RAISE EXCEPTION '1502: % duplicate offices resolve a holder — aborting', v_holders;
  END IF;

  SELECT count(*) INTO v_races
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%'
     AND d.geo_id = '18105';
  IF v_races <> 0 THEN
    RAISE EXCEPTION '1502: % duplicate offices carry a race (NO ACTION FK would block) — aborting', v_races;
  END IF;
END $$;

-- Drop the 52 duplicates. Guarded on termless/race-free so the statement itself cannot remove an
-- occupied or contested seat even if the pre-flight were somehow bypassed.
DELETE FROM essentials.offices o
 USING essentials.districts d
 WHERE d.id = o.district_id
   AND lower(d.state) = 'in'
   AND o.title ILIKE 'Monroe County Council District%'
   AND d.geo_id = '18105'
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);

-- ── post-verify gate (END STATE) ────────────────────────────────────────────────────────
DO $$
DECLARE v_total int; v_per_district int; v_races int; v_cands int; v_orphans int;
BEGIN
  SELECT count(*) INTO v_total
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%';
  IF v_total <> 4 THEN
    RAISE EXCEPTION '1502: expected exactly 4 Monroe council-district offices to remain, found %', v_total;
  END IF;

  -- exactly one per polygon-bearing district, and each on its OWN matching district
  SELECT count(*) INTO v_per_district
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%'
     AND d.geo_id = '18105-mcc-d' || right(o.title, 1)
     AND (SELECT count(*) FROM essentials.geofence_boundaries gb WHERE gb.geo_id = d.geo_id) = 1;
  IF v_per_district <> 4 THEN
    RAISE EXCEPTION '1502: only % of 4 survivors sit on their own polygon-bearing district', v_per_district;
  END IF;

  -- the four 2026 primary races and their candidates must be untouched
  SELECT count(*), coalesce(sum((SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id)), 0)
    INTO v_races, v_cands
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'in' AND o.title ILIKE 'Monroe County Council District%';
  IF v_races <> 4 OR v_cands <> 4 THEN
    RAISE EXCEPTION '1502: expected 4 races with 4 candidates, found % / %', v_races, v_cands;
  END IF;

  -- offices.district_id has no FK; prove nothing was orphaned
  SELECT count(*) INTO v_orphans
    FROM essentials.offices o
   WHERE o.district_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = o.district_id);
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION '1502: % offices orphaned', v_orphans;
  END IF;

  RAISE NOTICE '1502 OK: 52 duplicate Monroe council offices removed; 4 remain on their own polygons, races intact';
END $$;

COMMIT;
