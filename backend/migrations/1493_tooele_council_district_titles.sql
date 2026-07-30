-- 1493 — Tooele County Council: put the district number in the office title
--
-- Four of Tooele's five council members share the bare title "County Council", so the
-- five seats are indistinguishable from each other in Essentials. Tooele runs a
-- council-manager form with five DISTRICT seats (1-5), published on the county's own
-- council page: https://tooeleco.gov/council/index.php
--
--   Scott Wardle    District 1 (Vice Chair)
--   Kendall Thomas  District 2
--   Tye Hoffmann    District 3
--   Jared Hamner    District 4 (Chair)
--   Erik Stromberg  District 5
--
-- Mapping is by name, which is unambiguous — all five names match the county roster
-- exactly, and each holds exactly one council office.
--
-- SCOPE — titles only. These five offices deliberately stay attached to the whole-county
-- G4020 district (geo_id 49045): Tooele publishes no council-district polygons, so there
-- is nothing to geofence against and address search is unaffected either way. Adding the
-- district to the title is a labelling fix, not an occupancy or geography change.
--
-- Safe with respect to external_id: the UT county-roster loader hashes slugify(role) only
-- when MINTING an external_id, so renaming offices.title after first load does not shift
-- any politician's external_id (data/rosters/manual/_audit_notes.md -> "At-Large Officer
-- Convention"). No politician row is touched here at all.
--
-- Hamner's existing "(Chair)" annotation is PRESERVED rather than stripped, to keep this
-- change minimal and reversible. Worth noting though: a chairmanship rotates annually, so
-- carrying it in offices.title is the same "cached current value" anti-pattern that
-- CLAUDE.md warns about for occupancy — nothing fires when the calendar advances, and
-- Tooele's own page already lists Wardle as Vice Chair with no annotation on our side.
-- Deciding whether rotating roles belong in a title at all is a separate call; this
-- migration does not make it.
--
-- Found by the 2026-07-29 UT county seat audit. Idempotent — re-running is a no-op
-- because each UPDATE is guarded on the pre-rename title.

BEGIN;

UPDATE essentials.offices SET title = 'County Council District 1'
 WHERE id = '5aae706e-a3eb-47f8-9995-cbd603fe8d80' AND title = 'County Council';        -- Wardle

UPDATE essentials.offices SET title = 'County Council District 2'
 WHERE id = '103f25a9-8961-447e-9397-5881f07713d8' AND title = 'County Council';        -- Thomas

UPDATE essentials.offices SET title = 'County Council District 3'
 WHERE id = '69d202b4-3340-4f6c-afdd-26c386354058' AND title = 'County Council';        -- Hoffmann

UPDATE essentials.offices SET title = 'County Council District 4 (Chair)'
 WHERE id = 'ccac16fe-c025-431c-90cb-d9894190e5a1' AND title = 'County Council (Chair)'; -- Hamner

UPDATE essentials.offices SET title = 'County Council District 5'
 WHERE id = '9fa719da-ee82-46d8-ae60-47dafb2d5fba' AND title = 'County Council';        -- Stromberg

-- ── post-verify gate ────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_distinct int;
  v_bare     int;
  v_total    int;
  v_expected text[] := ARRAY[
    'County Council District 1','County Council District 2','County Council District 3',
    'County Council District 4 (Chair)','County Council District 5'];
  v_actual   text[];
BEGIN
  SELECT count(*), count(DISTINCT o.title), array_agg(o.title ORDER BY o.title)
    INTO v_total, v_distinct, v_actual
    FROM essentials.offices   o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.ocd_id = 'ocd-division/country:us/state:ut/county:tooele'
     AND o.title ILIKE '%council%';

  IF v_total <> 5 THEN
    RAISE EXCEPTION '1493: expected 5 Tooele council offices, found %', v_total;
  END IF;

  -- the whole point: five seats, five distinct titles
  IF v_distinct <> 5 THEN
    RAISE EXCEPTION '1493: expected 5 DISTINCT council titles, found % (%)', v_distinct, v_actual;
  END IF;

  IF v_actual <> (SELECT array_agg(t ORDER BY t) FROM unnest(v_expected) t) THEN
    RAISE EXCEPTION '1493: titles are %, expected %', v_actual, v_expected;
  END IF;

  -- no seat left carrying an unnumbered title
  SELECT count(*) INTO v_bare
    FROM essentials.offices   o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.ocd_id = 'ocd-division/country:us/state:ut/county:tooele'
     AND o.title IN ('County Council','County Council (Chair)');

  IF v_bare <> 0 THEN
    RAISE EXCEPTION '1493: % Tooele council office(s) still unnumbered', v_bare;
  END IF;

  RAISE NOTICE '1493 OK — 5 Tooele council seats, 5 distinct district titles, 0 unnumbered';
END $$;

COMMIT;
