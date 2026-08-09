-- 1635_repair_la_county_duplicate_districts.sql
--
-- Los Angeles County repair. Consolidates 3 duplicate county district rows into 1, moves the 3
-- countywide offices onto a single chamber matching the rest of the CA county wave, and replaces
-- 8 unknown-precision term rows with dates from the county's own published tenure document.
--
-- ── WHAT WAS WRONG ─────────────────────────────────────────────────────────────────────────────
-- essentials.districts held THREE rows for district_type='COUNTY', geo_id='06037', identical in
-- label/ocd_id/population, distinguished only by external_id (-100006, -100008, -100010). LA's
-- three countywide offices were spread ONE PER ROW, each on its own per-role chamber:
--     -100006 (3d46c39b) -> Assessor          on chamber "County Officers"
--     -100008 (b6f94367) -> District Attorney on chamber "Office of the District Attorney"
--     -100010 (f06aa860) -> Sheriff           on chamber "Office of the Sheriff"
-- So an address lookup resolving one row saw one office, never all three.
--
-- All three rows also carry state='CA', while all 57 other CA counties carry lowercase 'ca'.
-- There was therefore no already-correct row to adopt. The canonical shape is taken from the 57
-- non-duplicated peers, not from any of the three: lowercase state, one row, one chamber.
--
-- CANONICAL ROW: 3d46c39b (external_id -100006), chosen by smallest |external_id| -- a
-- deterministic rule, since the three rows are otherwise identical. The other two are deleted
-- AFTER their offices are repointed.
--
-- Safe to delete because the reference surface was measured, not assumed: the only columns named
-- district_id anywhere in essentials/inform/public/treasury are essentials.offices,
-- essentials.districts, the offices_missing_terms VIEW, and inform.politicians -- which holds
-- ZERO rows pointing at any of the three. races carry office_id, not district_id, so the 3 races
-- attached to these offices follow the offices and are never orphaned. This matters because
-- essentials.districts has NO inbound FKs: a delete would silently orphan, not error.
--
-- ── WHAT WAS *NOT* WRONG (a carried-forward note, corrected) ───────────────────────────────────
-- The two chambers both named "County Board of Supervisors" are NOT duplicates of each other:
--     9de1e8c8 = LOS ANGELES supervisors -- all 5 districts seated
--     9e68f81c = ORANGE supervisors      -- only districts 1 and 4 seated
-- They are two different counties' boards sharing a generic name. Nothing is merged here. The
-- naming ambiguity and Orange County's 3 missing supervisor seats are left for separate work --
-- renaming would change chambers.slug, which is GENERATED ALWAYS from name_formal.
--
-- Note also that LA and Orange supervisorial districts DO exist as district rows with proper
-- ocd_id county:.../council_district:N. The wave's decision to exclude Boards of Supervisors was
-- based on polygons being absent for MOST counties; it is not universal.
--
-- ── TERM DATES ─────────────────────────────────────────────────────────────────────────────────
-- All 8 LA elected officials carried term_start NULL / start_precision 'unknown' from the phase-2
-- backfill. Replaced with "First term began" from the county's own document, which is exactly the
-- occupancy-start semantics this wave uses (not the current term -- the same document prints a
-- separate "Present term began" that is deliberately NOT used):
--   https://file.lacounty.gov/SDSInter/lac/1044065_ElectedOfficialsSalaries.pdf  (REV. 08/07/26)
-- Read as a binary PDF, not via a summariser -- see migration 1633 for why that distinction is
-- load-bearing. The document gives month and year only, so start_precision is 'month' and the day
-- is not invented.
--
-- Names are left as stored. The county document writes "Jeffrey Prang" and "Robert G. Luna" where
-- we hold "Jeff Prang" and "Robert Luna"; renaming is cosmetic, touches matching behaviour, and is
-- out of scope for a structural repair.
--
-- Idempotent.

BEGIN;

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'Los Angeles County, California, US', 'County', 'CA', '06037'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06037' AND g.type='County');

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'Los Angeles County Countywide Elected Officials', g.id, 3, 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06037' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='Los Angeles County Countywide Elected Officials');

-- 1. Repoint all three offices onto the canonical district row and the single new chamber.
UPDATE essentials.offices o
   SET district_id = '3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid,
       chamber_id  = ch.id
  FROM essentials.chambers ch
 WHERE ch.name_formal = 'Los Angeles County Countywide Elected Officials'
   AND o.district_id IN ('3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid,
                         'b6f94367-1d2f-4216-b91e-aa32d23beb33'::uuid,
                         'f06aa860-c875-44c6-921d-0b09b3bc9e76'::uuid)
   AND (o.district_id <> '3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid OR o.chamber_id IS DISTINCT FROM ch.id);

-- 2. Normalise the survivor to the shape of the 57 peers.
UPDATE essentials.districts d
   SET state = 'ca',
       government_id = g.id
  FROM essentials.governments g
 WHERE d.id = '3d46c39b-df5d-4959-a7f8-f9ab2d4a787d'::uuid
   AND g.geo_id='06037' AND g.type='County'
   AND (d.state <> 'ca' OR d.government_id IS DISTINCT FROM g.id);

-- 3. Drop the two now-empty duplicates. Guarded: refuses to delete a row that still owns an office.
DELETE FROM essentials.districts d
 WHERE d.id IN ('b6f94367-1d2f-4216-b91e-aa32d23beb33'::uuid,
                'f06aa860-c875-44c6-921d-0b09b3bc9e76'::uuid)
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- 4. Replace unknown-precision terms with the county's published first-term dates.
UPDATE essentials.office_terms t
   SET term_start      = v.first_term,
       start_precision = 'month',
       how_started     = 'elected',
       source          = 'migration 1635 — LA County "Salary and Tenure Data, Elected Officials" (REV. 08/07/26), read 2026-08-08'
  FROM (VALUES
          ('Assessor',          'Jeff Prang',         DATE '2014-12-01'),
          ('District Attorney', 'Nathan Hochman',     DATE '2024-12-01'),
          ('Sheriff',           'Robert Luna',        DATE '2022-12-01'),
          ('Supervisor',        'Hilda L. Solis',     DATE '2014-12-01'),
          ('Supervisor',        'Holly J. Mitchell',  DATE '2020-12-01'),
          ('Supervisor',        'Lindsey P. Horvath', DATE '2022-12-01'),
          ('Supervisor',        'Janice Hahn',        DATE '2016-12-01'),
          ('Supervisor',        'Kathryn Barger',     DATE '2016-12-01')
       ) AS v(title, full_name, first_term),
       essentials.offices o,
       essentials.politicians p
 WHERE t.office_id = o.id
   AND t.politician_id = p.id
   AND t.term_end IS NULL
   AND o.title = v.title
   AND p.full_name = v.full_name
   AND t.term_start IS DISTINCT FROM v.first_term;

DO $$
DECLARE
  v_rows integer; v_offices integer; v_seated integer; v_state text;
  v_chambers integer; v_unknown integer; v_orphans integer; v_oc_offices integer;
BEGIN
  -- Exactly one LA county district row remains, lowercase, and it owns all three offices.
  SELECT count(*) INTO v_rows FROM essentials.districts
   WHERE district_type='COUNTY' AND geo_id='06037';
  IF v_rows <> 1 THEN RAISE EXCEPTION 'Expected 1 LA county district row, found %', v_rows; END IF;

  SELECT state INTO v_state FROM essentials.districts
   WHERE district_type='COUNTY' AND geo_id='06037';
  IF v_state <> 'ca' THEN RAISE EXCEPTION 'LA county row state is "%", expected lowercase "ca"', v_state; END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND d.geo_id='06037';
  IF v_offices <> 3 THEN RAISE EXCEPTION 'Expected 3 LA countywide offices, found %', v_offices; END IF;

  -- No office was orphaned by the delete.
  SELECT count(*) INTO v_orphans FROM essentials.offices o
   WHERE o.district_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = o.district_id);
  IF v_orphans <> 0 THEN RAISE EXCEPTION '% office(s) now point at a deleted district', v_orphans; END IF;

  -- All three still have their holder.
  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND d.geo_id='06037' AND och.politician_id IS NOT NULL;
  IF v_seated <> 3 THEN RAISE EXCEPTION 'Expected 3 seated LA holders, found %', v_seated; END IF;

  -- All three sit on ONE chamber.
  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND d.geo_id='06037';
  IF v_chambers <> 1 THEN RAISE EXCEPTION 'LA countywide offices span % chambers, expected 1', v_chambers; END IF;

  -- The 8 term rows now carry real dates.
  SELECT count(*) INTO v_unknown
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id=t.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE t.term_end IS NULL
     AND (   (d.district_type='COUNTY' AND d.geo_id='06037')
          OR o.chamber_id='9de1e8c8-8f8c-4c6e-a77d-6c41c8d363ab'::uuid)
     AND (t.term_start IS NULL OR t.start_precision = 'unknown');
  IF v_unknown <> 0 THEN
    RAISE EXCEPTION '% LA term row(s) still carry an unknown start', v_unknown;
  END IF;

  -- The Orange County supervisor chamber must be untouched -- it is a different county, not a dupe.
  SELECT count(*) INTO v_oc_offices FROM essentials.offices
   WHERE chamber_id='9e68f81c-065a-4665-9687-b2dcd903fae3'::uuid;
  IF v_oc_offices <> 2 THEN
    RAISE EXCEPTION 'Orange County supervisor chamber changed to % offices, expected 2', v_oc_offices;
  END IF;
END $$;

COMMIT;
