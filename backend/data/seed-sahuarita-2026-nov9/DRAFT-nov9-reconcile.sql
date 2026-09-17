-- DRAFT-nov9-reconcile.sql
-- ============================================================================
-- 🔴 DRAFT. NOT A MIGRATION. NOT APPLIED. NO SLOT RESERVED.
-- Deliberately NOT in backend/migrations/ so the numbering + reservation checks
-- do not see it. Reserve a slot from the allocator and rename it only on the day.
--
--     cd C:/EV-Accounts/backend
--     node scripts/steward.mjs slot shared --purpose "sahuarita nov-9 2026 council reconcile"
--
-- Written 2026-09-17, 53 days ahead, so that 2026-11-09 is a review-and-apply
-- rather than a rebuild. Everything below is verified against prod as of the
-- draft date EXCEPT the designation outcome, which cannot exist yet.
-- ============================================================================
--
-- WHAT HAPPENS ON 2026-11-09
-- The three seats decided at the 2026-07-21 primary are sworn in at the Nov-9
-- Town Council meeting (source: sahuaritaaz.gov/1276 -- "The candidates elected
-- at the July 21, 2026, Primary election are: Chelsea Hundal, Deborah Morales,
-- Tom Murphy" ... "will be sworn into office at the November 9, 2026, Town
-- Council meeting"). Official canvass totals: Morales 3,885 / Murphy 3,837 /
-- Hundal 3,397 / Cubillo 2,970 / Earl 2,583, all 4 columns tie to 16,722.
--
-- Kara Egbert did not seek re-election and LEAVES THE BODY. Chelsea Hundal
-- takes her place. Murphy and Morales continue in the seats they already hold --
-- re-election does not break occupancy, so THEIR ROWS ARE NOT TOUCHED unless the
-- designation vote moves them between office rows (see Part B).
--
-- ⚠ Designations are encoded in office TITLES here (mig 1863), so a change of
-- Mayor/Vice Mayor is a change of WHICH OFFICE ROW a person occupies, not a new
-- office. Record it with how_started = 'appointed', never 'elected'.
--
-- ⚠ office_terms_no_overlap is an EXCLUSION constraint with INCLUSIVE bounds, and
-- the existing rows are all (NULL, NULL) = unbounded, which overlaps everything.
-- So every seat that changes hands must CLOSE the old row before opening the new:
--   predecessor term_end = 2026-11-08, successor term_start = 2026-11-09.
--
-- ============================================================================
-- PROD STATE AS OF 2026-09-17 (re-verify on the day; do not trust these blind)
-- chamber Sahuarita Town Council = b8721569-4bda-4289-af47-0451879ad0ec
--
--   office                        office_id                             occupant         ext_id     term_id
--   Council Member (Mayor)        fdc06a34-27a6-4260-8a00-be5f7b5139ad  Tom Murphy       -4014001   dfc780c5-4a67-4856-b36c-9abd3dcc98cb
--   Council Member (Vice Mayor)   f51db53e-ad1e-4659-8192-a301ee519e55  Kara Egbert      -4014002   b1b88ff1-c61b-4197-a5f8-658c03a26ff5
--   Council Member                19bcd89d-1386-4e0f-854b-65208b5fe3c5  Deborah Morales  -4014003   0b54e6ed-3e04-4cf4-8082-46dad8f92df0
--   Council Member                b84fc740-1ebe-4625-8709-2aad4f3c824f  Steven Gillespie -4014004   8378b05d-828a-4d3d-a118-a605dfc67906
--   Council Member                10e78a80-bac8-4991-87fd-002651ae7e73  Diane Priolo     -4014005   3932e3b4-cb4d-4f3e-a1f4-754b290bf9e2
--   Council Member                65d04184-c9cd-4431-9709-45ce0096de34  Kim Lisk         -4014006   e037d2ff-ee15-4c12-88e1-cafd76756f0a
--   Council Member                9bc231e4-d24a-4796-a32d-af63f6da88e3  Edgar Lytle      -4014007   b3ed86ee-9a9f-4ef7-9dd4-7a1708061227
--
-- Sahuarita owns external_id band -4014001..-4014007; -4014008 is FREE and is
-- the natural id for Hundal. Re-check it is still free on the day.
-- ⚠ "Diane" is correct -- 2024 Pima canvass ballot name is PRIOLO, DIANE. The
-- town's council webpage spells it "Diana"; the town is wrong, we are right.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- GUARD 0: refuse to run early. This is the whole point of the draft.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF CURRENT_DATE < DATE '2026-11-09' THEN
    RAISE EXCEPTION
      'Sahuarita Nov-9 reconcile ran % day(s) EARLY. Egbert is still the sitting Vice Mayor '
      'and Hundal has not been sworn in. Do not apply before 2026-11-09.',
      DATE '2026-11-09' - CURRENT_DATE;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- GUARD 1: Chelsea Hundal must not already exist.
-- 🔴 DO NOT write this as full_name ILIKE '%hundal%'. That matches
-- 'HUNDAL FOR MAYOR 2014' (76c95733-b9b7-4b58-9d87-396f0d8687d7), a CALIFORNIA
-- CAMPAIGN-FINANCE COMMITTEE with empty first_name and no office -- one of the
-- ~77k committee rows in essentials.politicians. Match the person form.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.politicians p
   WHERE p.first_name = 'Chelsea' AND p.last_name = 'Hundal';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration <N>: Chelsea Hundal already present (% row(s)) -- has this already run?', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians WHERE external_id = -4014008;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration <N>: external_id -4014008 is taken; pick the next free id in Sahuarita band -40140xx';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- GUARD 2: the body is the shape we expect (7 seats, Egbert still seated).
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; who text;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.offices o JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = 'Sahuarita Town Council';
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration <N>: expected 7 Sahuarita seats, found %', n;
  END IF;

  SELECT p.full_name INTO who
    FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE ot.office_id = 'f51db53e-ad1e-4659-8192-a301ee519e55';
  IF who IS DISTINCT FROM 'Kara Egbert' THEN
    RAISE EXCEPTION 'migration <N>: expected Kara Egbert in the Vice Mayor seat, found % -- state has moved', coalesce(who, '<vacant>');
  END IF;
END $$;

-- ===========================================================================
-- PART A -- DETERMINISTIC. Known today; no dependence on the minutes.
-- ===========================================================================

-- A1. Kara Egbert leaves the body. Did not seek re-election => 'retired'.
--     Set term_end AND clear is_incumbent -- they are TWO SEPARATE GATES.
--     Leave is_active alone (blast radius unmeasured).
UPDATE essentials.office_terms
   SET term_end = DATE '2026-11-08', how_ended = 'retired'
 WHERE id = 'b1b88ff1-c61b-4197-a5f8-658c03a26ff5';

UPDATE essentials.politicians
   SET is_incumbent = false
 WHERE id = '071e2a28-2fef-489a-97e3-15fb5caaee51';

-- A2. Chelsea Hundal enters.
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_incumbent, is_active)
VALUES (gen_random_uuid(), -4014008, 'Chelsea Hundal', 'Chelsea', 'Hundal', true, true);

-- ===========================================================================
-- PART B -- FILL FROM THE 2026-11-09 MINUTES. DO NOT GUESS.
-- ===========================================================================
-- The council designates a Mayor and a Vice Mayor by roll call. A candidate needs
-- >= 4 AFFIRMATIVE VOTES; if nobody reaches four, "the current Mayor will continue
-- to serve" (Rules of Procedure, adopted 2024-12-09). So:
--   * Murphy being re-designated Mayor is NOT automatic.
--   * The Vice Mayor seat IS definitely changing hands -- Egbert has left.
--
-- Fill this table with the FINAL seating after the designation vote, then the
-- block below moves only the people whose office row actually changes.
--
-- CREATE TEMP TABLE nov9_final (office_title text, ext_id int) ON COMMIT DROP;
-- INSERT INTO nov9_final VALUES
--   ('Council Member (Mayor)',      <ext_id from minutes>),
--   ('Council Member (Vice Mayor)', <ext_id from minutes>),
--   ('Council Member',              -4014003),  -- Morales
--   ('Council Member',              -4014004),  -- Gillespie
--   ('Council Member',              -4014005),  -- Priolo
--   ('Council Member',              -4014006),  -- Lisk
--   ('Council Member',              -4014007),  -- Lytle
--   ('Council Member',              -4014008);  -- Hundal
--   -- NB that is 8 rows for 7 seats on purpose: whoever takes a designated seat
--   -- drops out of the plain list. Trim to exactly 7 before running.
--
-- For each seat whose occupant changes:
--   UPDATE essentials.office_terms SET term_end = DATE '2026-11-08',
--          how_ended = 'term_expired'   -- or 'unknown' for a pure designation move
--    WHERE office_id = <old office> AND term_end IS NULL;
--   INSERT INTO essentials.office_terms (id, office_id, politician_id, term_start,
--          start_precision, how_started, source)
--   VALUES (gen_random_uuid(), <new office>, <politician>, DATE '2026-11-09',
--          'day', 'appointed',            -- 'elected' ONLY for Hundal's own arrival
--          '<url of the Nov-9 minutes>');
--
-- ⚠ source is NOT NULL. Cite the minutes URL, not this file.
-- ⚠ If Murphy is re-designated Mayor, his row is NOT touched at all -- he never
--   changes office row, and re-election does not break occupancy.

-- ---------------------------------------------------------------------------
-- POST-FLIGHT (run after Part B is filled in)
-- ---------------------------------------------------------------------------
DO $$
DECLARE seated int; designated int;
BEGIN
  SELECT count(*) INTO seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id
   WHERE c.name_formal = 'Sahuarita Town Council';
  IF seated <> 7 THEN
    RAISE EXCEPTION 'migration <N>: expected 7 seated members after the reconcile, found %', seated;
  END IF;

  SELECT count(*) INTO designated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.current_office_holders coh ON coh.office_id = o.id
   WHERE c.name_formal = 'Sahuarita Town Council'
     AND o.title IN ('Council Member (Mayor)', 'Council Member (Vice Mayor)');
  IF designated <> 2 THEN
    RAISE EXCEPTION 'migration <N>: expected exactly 1 Mayor + 1 Vice Mayor seated, found %', designated;
  END IF;

  -- Egbert must be gone from the flat incumbents list as well as from occupancy
  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE id = '071e2a28-2fef-489a-97e3-15fb5caaee51' AND is_incumbent) THEN
    RAISE EXCEPTION 'migration <N>: Egbert still flagged is_incumbent -- the second gate was not closed';
  END IF;
END $$;

ROLLBACK;  -- 🔴 DRAFT ENDS IN ROLLBACK ON PURPOSE. Change to COMMIT only on the day.
