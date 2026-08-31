-- CC_0006_fl_legislature_structure.sql
-- Knight Foundation program, wave FL-2 (structure half).
--
-- Creates the two Florida legislative chambers under the existing 'State of Florida'
-- government, and one office per district: 120 Representatives + 40 Senators = 160.
-- Creates NO people and NO terms -- the incumbents migration does that, and the two
-- are applied back to back.
--
-- 🔴 5 OF THE 160 OFFICES ARE VACANT and are flagged is_vacant HERE, in the
-- structure migration, not later:
--   HD-55: vacant since 2026-08-06, after Kevin M. Steele
--   HD-78: vacant since 2026-05-21, after Jenna Persons-Mulicka
--   HD-113: vacant since 2025-11-19, after Vicki L. Lopez
--   HD-116: vacant since 2026-08-22, after Daniel Perez
--   SD-39: vacant since UNKNOWN (not published)
--
-- Flagging here is load-bearing twice over:
--   1. check-address-reachability.mjs classifies DEAD_GEOGRAPHY as
--      "reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0".
--      An unflagged empty office fires a NEW fl|STATE_LOWER bucket and fails the gate.
--   2. essentials.offices_missing_terms separates flagged-vacant rows from unflagged
--      ones, and only the unflagged count is drift (measured before this wave: 814
--      total / 159 flagged / 655 unflagged, against a 699 unflagged threshold).
--      Flagging here keeps the unflagged count at 655 even in the window between the
--      two applies.
--
-- SD-39's vacancy start is NOT PUBLISHED -- the roster row and the member page both
-- read only "Vacant" -- so vacant_since is left NULL rather than invented. CLAUDE.md:
-- do not write a vacancy span whose start date you do not know.
--
-- Districts and geometry come from scripts/load-state-tiger-boundaries.ts (wave FL-1),
-- not from this migration.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded, and the vacancy UPDATE is guarded on
-- the current value. Ends with a post-verify gate.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT '623ac987-c7bc-4da1-8112-68adaec10cb2', 'Florida House of Representatives', 'Florida House of Representatives', 120
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '623ac987-c7bc-4da1-8112-68adaec10cb2' AND name = 'Florida House of Representatives'
);

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT '623ac987-c7bc-4da1-8112-68adaec10cb2', 'Florida Senate', 'Florida Senate', 40
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '623ac987-c7bc-4da1-8112-68adaec10cb2' AND name = 'Florida Senate'
);

-- ─── House offices: 120, one per STATE_LOWER district ─────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Representative', 'FL', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = '623ac987-c7bc-4da1-8112-68adaec10cb2' AND ch.name = 'Florida House of Representatives'
) c
WHERE d.district_type = 'STATE_LOWER'
  AND lower(d.state) = 'fl'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Representative'
  );

-- ─── Senate offices: 40, one per STATE_UPPER district ───────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Senator', 'FL', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = '623ac987-c7bc-4da1-8112-68adaec10cb2' AND ch.name = 'Florida Senate'
) c
WHERE d.district_type = 'STATE_UPPER'
  AND lower(d.state) = 'fl'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Senator'
  );

-- ─── Flag the 5 vacant seats ─────────────────────────────────────────────────
-- 🔴 The join pairs geo_id WITH district_type. FL's sldl and sldu GEOIDs BOTH start at
-- 12001, so an unpaired join would match HD-n against SD-n for every n <= 40 -- and
-- SD-39 is one of these five, well inside that range.

CREATE TEMP TABLE fl_leg_vacancy (
  geo_id        text,
  district_type text,
  office_title  text,
  vacant_since  date,
  source        text
) ON COMMIT DROP;

INSERT INTO fl_leg_vacancy VALUES
    ('12039', 'STATE_UPPER', 'Senator', NULL, 'flsenate.gov/Senators/2024-2026/S39 - roster row and member page both read only "Vacant"; no date or reason published, so vacant_since is unknown rather than invented'),
    ('12055', 'STATE_LOWER', 'Representative', DATE '2026-08-06', 'flhouse.gov/Representatives "Pending Election - District: 55" card (alt text: "District 55 is currently vacant."); predecessor Kevin M. Steele term window 11/06/24-08/05/26'),
    ('12078', 'STATE_LOWER', 'Representative', DATE '2026-05-21', 'flhouse.gov/Representatives "Pending Election - District: 78" card (alt text: "District 78 is currently vacant."); predecessor Jenna Persons-Mulicka term window 11/06/24-05/20/26'),
    ('12113', 'STATE_LOWER', 'Representative', DATE '2025-11-19', 'flhouse.gov/Representatives "Pending Election - District: 113" card (alt text: "District 113 is currently vacant."); predecessor Vicki L. Lopez term window 11/06/24-11/18/25'),
    ('12116', 'STATE_LOWER', 'Representative', DATE '2026-08-22', 'flhouse.gov/Representatives "Pending Election - District: 116" card (alt text: "District 116 is currently vacant."); predecessor Daniel Perez term window 11/06/24-08/21/26');

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM fl_leg_vacancy;
  IF v_n <> 5 THEN RAISE EXCEPTION 'vacancy payload: expected 5 rows, got %', v_n; END IF;
END $$;

UPDATE essentials.offices o
   SET is_vacant = true,
       vacant_since = v.vacant_since
  FROM fl_leg_vacancy v
  JOIN essentials.districts d
    ON d.geo_id = v.geo_id
   AND d.district_type = v.district_type
   AND lower(d.state) = 'fl'
 WHERE o.district_id = d.id
   AND o.title = v.office_title
   AND (o.is_vacant IS DISTINCT FROM true
        OR o.vacant_since IS DISTINCT FROM v.vacant_since);

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE n_ch int; n_off int; n_orphan int; n_vac int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers c
   WHERE c.government_id = '623ac987-c7bc-4da1-8112-68adaec10cb2'
     AND c.name IN ('Florida House of Representatives', 'Florida Senate');
  IF n_ch <> 2 THEN RAISE EXCEPTION 'CC_0006: expected 2 FL legislative chambers, found %', n_ch; END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 160 THEN RAISE EXCEPTION 'CC_0006: expected 160 FL legislative offices, found %', n_off; END IF;

  -- Every office must hang off a district that actually has geometry, or the seat is
  -- unreachable by address and nothing will error.
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CC_0006: % FL legislative offices lack district geometry', n_orphan; END IF;

  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND o.is_vacant = true;
  IF n_vac <> 5 THEN RAISE EXCEPTION 'CC_0006: expected 5 FL legislative offices flagged is_vacant, found %', n_vac; END IF;
END $$;

-- Second gate: per-chamber shape + no cross-wiring. Catches exactly the failure mode
-- where a bare geo_id join fans a House office onto a Senate district while still
-- producing a plausible 160 total. FL's sldl and sldu GEOIDs BOTH start at 12001, so
-- this collision is total for districts 1-40 and this gate is not theoretical.
DO $$
DECLARE n_lower int; n_upper int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_lower FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='fl' AND d.district_type='STATE_LOWER';
  IF n_lower <> 120 THEN RAISE EXCEPTION 'CC_0006: expected 120 FL House offices, found %', n_lower; END IF;

  SELECT count(*) INTO n_upper FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='fl' AND d.district_type='STATE_UPPER';
  IF n_upper <> 40 THEN RAISE EXCEPTION 'CC_0006: expected 40 FL Senate offices, found %', n_upper; END IF;

  SELECT count(*) INTO n_dupe FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state)='fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION 'CC_0006: % FL districts carry more than one office — geo_id join fanned across chambers', n_dupe; END IF;
END $$;

COMMIT;
