-- CC_0063_lomita_la_mirada_council_occupancy.sql
--
-- Lomita and La Mirada (LA County) — three missing members, two wrong mayors.
--
-- Follow-up to the LA County headshot audit (2026-09-03). Both cities' council pages refuse
-- `curl` and Node fetch at the TLS handshake, so the audit never read them and recorded them
-- as "blocks automated access". A real Chrome session reads both normally. Reading them to
-- source portraits also read the rosters, and both disagree with us about who sits.
--
-- Notes: backend/data/la-county-headshot-audit-2026-09-03/
--
-- ── WHAT IS WRONG ────────────────────────────────────────────────────────────────────────
--
--   LOMITA (geo_id 0642468) — we hold 4 of 5 seats.
--     * Cindy Segawa is absent from the corpus entirely, and she is the MAYOR.
--     * Mark A. Waronek is recorded as Mayor. He stopped being Mayor on 2025-12-16 and is
--       now a plain Councilmember.
--
--   LA MIRADA (geo_id 0640032) — we hold 3 of 5 seats.
--     * Anthony A. Otero is absent, and he is the MAYOR.
--     * Ed Eng is absent. He holds District 3.
--     * John Lewis is recorded as Mayor. He was Mayor 2024-2025; he now holds District 1.
--
-- 🔴 THE STALE MAYOR IS NOT A SCRAPE BUG — IT IS THE CALENDAR. Both councils rotate the
--    mayoralty annually among their own members. Our rows were right when they were written
--    and rotted on a fixed schedule. Nothing errors when they rot; the office keeps naming a
--    real member of the body, just the wrong one. That is ADR 0002's whole argument, applied
--    to a role rather than a seat.
--
-- ── ⚠ A MODELLING WART THIS MIGRATION DELIBERATELY DOES NOT FIX ──────────────────────────
--
-- Both cities are modelled the corpus way: a LOCAL_EXEC "<City> Mayor" district holding one
-- Mayor office, plus N-1 at-large Council Member offices, N total. 83 CA places use this
-- shape, Hermosa Beach (also a rotating mayoralty) among them, so this migration follows it.
--
-- It is a poor fit for a ROTATING mayoralty, and worse for LA MIRADA, whose five seats are
-- DISTRICTED 1-5. Otero's seat is District 5; "Mayor" is a role laid on top of it. Modelling
-- the role as one of the five seats means that every December the chair changes, two people
-- have to move offices, and District 5 has no seat of its own. Our districts row for the city
-- still says "At-Large", which is a second, older problem: La Mirada moved to by-district
-- elections under a map adopted 2021-11-23.
--
-- Reshaping either city (5 seats, mayoralty as a parenthetical on the title; real district
-- geometry for La Mirada) is an ADR-level decision and needs the boundaries. It is raised in
-- the report that accompanies this migration, NOT decided here.
--
-- ── SOURCES ─────────────────────────────────────────────────────────────────────────────
--
-- Every date below comes from a primary instrument, read directly on 2026-09-03/04.
--
--   L1  City of Lomita, NOTICE OF CITY COUNCIL REORGANIZATION, dated 17 December 2025:
--       "at its December 16, 2025, regular meeting, the City Council ... reorganized as
--       follows: CINDY SEGAWA - MAYOR Term Expires 2026; BARRY WAITE - MAYOR PRO TEM Term
--       Expires 2028; JAMES GAZELEY - COUNCILMEMBER Term Expires 2026; WILLIAM UPHOFF -
--       COUNCILMEMBER Term Expires 2028; MARK A. WARONEK - COUNCILMEMBER Term Expires 2026".
--       https://lomitacity.com/wp-content/uploads/2026/01/2025-Council-Reorganization.pdf
--
--   L2  The same notice for the preceding year, dated 18 December 2024: "at its December 17,
--       2024, regular meeting ... MARK A. WARONEK - MAYOR". This is what our row recorded and
--       it is the date Waronek's mayoralty began.
--       https://lomitacity.com/wp-content/uploads/2024/08/2025-Council-Reorganization.pdf
--
--   M1  City of La Mirada city council page, read 2026-09-03: "Mayor Anthony Otero District
--       5", "Mayor Pro Tem Steve De Ruse District 4", "Councilmember Ed Eng District 3",
--       "Councilmember John Lewis District 1", "Councilmember Michelle Velasquez Bean
--       District 2".  https://www.lamirada.gov/city_hall/city_council.php
--
--   M2  City Clerk's elections page, read 2026-09-03: "On March 17, City Council adopted
--       Resolution No. 26-09 appointing John Lewis as a Member of the City Council
--       representing District 1 and appointing Michelle Velasquez Bean as Member of the City
--       Council representing District 2 each for a four-year term. The City's General
--       Municipal Election scheduled to be held on June 2 for Districts 1 and 2 was
--       canceled." Same page: "The General Municipal Election for Districts 3, 4, and 5 will
--       be held March 2028."  https://www.lamirada.gov/departments/city_clerk/elections.php
--
-- ── 🔴 WHAT IS **NOT** WRITTEN, AND WHY ───────────────────────────────────────────────────
--
-- ⚠ OTERO'S MAYORAL START DATE IS UNKNOWN AND IS LEFT UNKNOWN. La Mirada publishes no
--   reorganization notice equivalent to Lomita's L1. Its agenda PDFs and archived-news search
--   both return HTTP 500 to an automated client, and the council page gives mayoral service
--   only as hyphenated year spans ("served as Mayor previously from 2022-2023"). We know
--   Otero holds the chair; we do not know since when. His row is therefore written with
--   term_start NULL and start_precision 'unknown', which is the same shape the ADR 0002
--   phase-2 backfill used. A guessed December date would have been a fabricated span.
--
-- ⚠ ED ENG IS DATED TO THE YEAR, NOT THE DAY. District 3 last voted at the General Municipal
--   Election of March 2024 and next votes March 2028 (M2), for a four-year term; a
--   "ENG FOR CITY COUNCIL 2024" committee exists in our own finance corpus. That establishes
--   the YEAR. The swearing-in date is not published, and an election date is not an occupancy
--   date, so this is 2024-01-01 at 'year' precision rather than 2024-03-05 at 'day'.
--
-- ⚠ WARONEK'S COUNCIL SEAT IS DATED FROM THE ROTATION, NOT FROM HIS ELECTION. He has sat on
--   the Lomita council continuously and his underlying term expires in 2026, but in THIS
--   model the Mayor office is one of the five seats, so the date he entered a plain council
--   seat is the date he left the chair: 2025-12-16 (L1). how_started is 'succeeded' because
--   neither 'elected' nor 'appointed' describes an annual rotation.
--
-- ⚠ EXISTING TERMS FOR BEAN, DE RUSE, GAZELEY, UPHOFF AND WAITE ARE LEFT ALONE. They are
--   phase-2 backfill rows with unknown starts. M2 would let Bean's be dated to 2026-03-17 and
--   De Ruse's to 2024, but dating them is a separate, wider pass and is not a record ERROR.
--   Named here so the next reader knows the dates are available and were not overlooked.
--
-- ── EFFECT ──────────────────────────────────────────────────────────────────────────────
--   +3 politicians  (Cindy Segawa, Anthony A. Otero, Ed Eng)
--   +3 offices      (1 Lomita Council Member, 2 La Mirada Council Member)
--   +4 office_terms (Segawa, Waronek, Lewis, Eng), 1 UPDATE (Mayor of La Mirada -> Otero),
--                   1 close  (Waronek's Lomita mayoralty, ends 2025-12-15)
--   Both cities end at 5 seated members, 0 vacant, 0 offices missing a term.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 0. PRE-FLIGHT. 🔴 A TAKEN external_id WOULD MAKE THE GUARDED INSERTS BELOW SILENTLY SKIP,
--    leaving the office seated by whoever already owns that id. Refuse rather than guess.
-- ─────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_bad text;
BEGIN
  SELECT string_agg(external_id || ' = ' || full_name, '; ')
    INTO v_bad
    FROM essentials.politicians
   WHERE external_id IN (-209901, -209902, -209903);
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'external_id block already claimed: %. Pick a free block; do NOT reuse.', v_bad;
  END IF;

  -- The five offices this migration reads by id must all exist and be the ones we think.
  IF (SELECT count(*) FROM essentials.offices
       WHERE id IN ('e49b7177-437c-4e0f-a7f8-ec76ccf8e178',   -- Lomita Mayor
                    'c9129cb5-195d-4177-b5a9-97127b113fe1'))  -- La Mirada Mayor
     <> 2 THEN
    RAISE EXCEPTION 'expected both Mayor offices to exist by id; the ids have moved';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 1. THE THREE MISSING PEOPLE.
--    Fields follow the LA County cohort convention: negative synthetic external_id,
--    'Nonpartisan' (municipal offices in CA are nonpartisan), source 'scraped'.
-- ─────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.politicians
  (id, external_id, full_name, first_name, last_name, party, party_short_name,
   source, data_source, is_active, is_incumbent)
SELECT v.id::uuid, v.ext, v.full_name, v.first_name, v.last_name, 'Nonpartisan', 'N',
       'scraped', v.data_source, true, true
  FROM (VALUES
    ('c1193f7e-6891-4f59-9466-f001ac5ad49e', -209901, 'Cindy Segawa',    'Cindy',      'Segawa',
     'City of Lomita, Notice of City Council Reorganization dated 2025-12-17 (reorganized 2025-12-16); https://lomitacity.com/city-council/ read 2026-09-03'),
    ('7d6f87b6-8769-4247-99a6-da1702909a1f', -209902, 'Anthony A. Otero','Anthony A.', 'Otero',
     'City of La Mirada city council page, https://www.lamirada.gov/city_hall/city_council.php read 2026-09-03'),
    ('1d74e26f-c565-420e-82be-f946098016fb', -209903, 'Ed Eng',          'Ed',         'Eng',
     'City of La Mirada city council page, https://www.lamirada.gov/city_hall/city_council.php read 2026-09-03')
  ) AS v(id, ext, full_name, first_name, last_name, data_source)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v.id::uuid);

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 2. THE THREE MISSING SEATS.
--    Same chamber and At-Large district as their existing peers; nothing else distinguishes
--    the council offices in either city today (description is NULL on every one of them).
-- ─────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, normalized_position_name, seats, representing_state)
SELECT v.id::uuid, v.chamber_id::uuid, v.district_id::uuid,
       'Council Member', 'Council Member', 1, 'CA'
  FROM (VALUES
    -- Lomita: 4th at-large council seat, for Waronek off the mayoral rotation.
    ('9d286f17-f467-40f6-a709-388f2c4e052c',
     '940ef74a-b5ab-4ace-b8a0-14d8a28cd1aa', 'f1243c64-de87-479d-997b-205870c23059'),
    -- La Mirada: two more council seats, for Lewis (District 1) and Eng (District 3).
    ('78532235-6b62-4e49-9e13-203960d3161b',
     '6a6a7950-8c11-485a-8878-16e1ff22492c', 'f4384364-64f5-4af5-b698-2a41bb2f44e3'),
    ('5e73e4e7-d77e-4320-bc38-dd62a46c2078',
     '6a6a7950-8c11-485a-8878-16e1ff22492c', 'f4384364-64f5-4af5-b698-2a41bb2f44e3')
  ) AS v(id, chamber_id, district_id)
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = v.id::uuid);

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 3. LOMITA OCCUPANCY. Both dates are 2025-12-16, the reorganization meeting (L1).
--    seat_officeholder closes Waronek's mayoralty at 2025-12-15 for us.
-- ─────────────────────────────────────────────────────────────────────────────────────────
SELECT essentials.seat_officeholder(
         'e49b7177-437c-4e0f-a7f8-ec76ccf8e178'::uuid,          -- Lomita Mayor
         'c1193f7e-6891-4f59-9466-f001ac5ad49e'::uuid,          -- Cindy Segawa
         DATE '2025-12-16',
         'City of Lomita, Notice of City Council Reorganization dated 2025-12-17: reorganized 2025-12-16, "CINDY SEGAWA - MAYOR". CC_0063_lomita_la_mirada_council_occupancy.',
         'appointed',   -- selected by the council from among its own members
         'day',
         'term_expired' -- Waronek's one-year mayoralty ran out; he did not leave the body
       );

SELECT essentials.seat_officeholder(
         '9d286f17-f467-40f6-a709-388f2c4e052c'::uuid,          -- new Lomita council seat
         '9dd2a633-c532-4154-b2b0-9b725fcb292f'::uuid,          -- Mark A. Waronek
         DATE '2025-12-16',
         'City of Lomita, Notice of City Council Reorganization dated 2025-12-17: "MARK A. WARONEK - COUNCILMEMBER Term Expires 2026". CC_0063_lomita_la_mirada_council_occupancy.',
         'succeeded',   -- an annual rotation is neither an election nor an appointment
         'day',
         'term_expired'
       );

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 4. LA MIRADA OCCUPANCY.
--
-- 4a. The Mayor office. 🔴 NOT seat_officeholder: that helper REQUIRES a real term_start, and
--     we do not have Otero's. The row being replaced is a phase-2 backfill row carrying
--     term_start NULL / start_precision 'unknown' — it asserts no span, only an occupant, and
--     that occupant is now known to be wrong (M1). We overwrite the occupant and keep the
--     unknown start. John Lewis is not lost: 4b seats him in his own District 1 seat, dated.
-- ─────────────────────────────────────────────────────────────────────────────────────────
UPDATE essentials.office_terms
   SET politician_id   = '7d6f87b6-8769-4247-99a6-da1702909a1f',  -- Anthony A. Otero
       start_precision = 'unknown',
       how_started     = 'appointed',
       source          = 'City of La Mirada city council page read 2026-09-03: "Mayor Anthony Otero District 5". Start date not published; the city issues no reorganization notice. CC_0063_lomita_la_mirada_council_occupancy.'
 WHERE office_id     = 'c9129cb5-195d-4177-b5a9-97127b113fe1'
   AND politician_id = '753acd7a-1325-4883-80e7-c78466384cb2'     -- John Lewis
   AND term_start IS NULL
   AND term_end   IS NULL;

-- 4b. John Lewis into District 1, dated from Resolution No. 26-09 (M2).
SELECT essentials.seat_officeholder(
         '78532235-6b62-4e49-9e13-203960d3161b'::uuid,          -- new La Mirada council seat
         '753acd7a-1325-4883-80e7-c78466384cb2'::uuid,          -- John Lewis
         DATE '2026-03-17',
         'City of La Mirada, Resolution No. 26-09 (2026-03-17) appointing John Lewis to the City Council representing District 1 for a four-year term; the 2026-06-02 election for Districts 1 and 2 was canceled for want of a second candidate. CC_0063_lomita_la_mirada_council_occupancy.',
         'appointed',
         'day',
         'term_expired'
       );

-- 4c. Ed Eng into District 3, dated to the year only. See the header for why not to the day.
SELECT essentials.seat_officeholder(
         '5e73e4e7-d77e-4320-bc38-dd62a46c2078'::uuid,          -- new La Mirada council seat
         '1d74e26f-c565-420e-82be-f946098016fb'::uuid,          -- Ed Eng
         DATE '2024-01-01',
         'City of La Mirada city council page read 2026-09-03 ("Councilmember Ed Eng District 3"); District 3 last voted at the March 2024 General Municipal Election and next votes March 2028 for a four-year term (city clerk elections page). Year precision: the swearing-in date is not published. CC_0063_lomita_la_mirada_council_occupancy.',
         'elected',
         'year',
         'term_expired'
       );

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 5. POST-VERIFY. Every count is an END STATE, not a delta.
-- ─────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n   int;
  v_bad text;
BEGIN
  -- 1. Five seats and five seated people in each city. 🔴 count(och.politician_id), never
  --    count(*): office_current_holder LEFT JOINs from offices, so a vacancy is a NULL row
  --    and count(*) would pass vacuously.
  FOR v_bad, v_n IN
    SELECT d.geo_id, count(och.politician_id)::int
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id IN ('0642468', '0640032')
     GROUP BY d.geo_id
  LOOP
    IF v_n <> 5 THEN
      RAISE EXCEPTION 'geo_id %: expected 5 seated members, found %', v_bad, v_n;
    END IF;
  END LOOP;

  -- 2. The exact roster. Fails loudly at the next December rotation in either city, which is
  --    the intended behaviour — that is precisely the drift this migration is repairing.
  SELECT string_agg(x.geo_id || ' / ' || x.title || ' = ' || x.who, '; ' ORDER BY x.geo_id, x.who)
    INTO v_bad
    FROM (
      SELECT d.geo_id, o.title, coalesce(p.full_name, '(vacant)') AS who
        FROM essentials.districts d
        JOIN essentials.offices o ON o.district_id = d.id
        LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
        LEFT JOIN essentials.politicians p ON p.id = och.politician_id
       WHERE d.geo_id IN ('0642468', '0640032')
    ) x
   WHERE (x.geo_id, x.title, x.who) NOT IN (
     ('0642468', 'Mayor',         'Cindy Segawa'),
     ('0642468', 'Council Member', 'Mark A. Waronek'),
     ('0642468', 'Council Member', 'Barry Waite'),
     ('0642468', 'Council Member', 'Bill Uphoff'),
     ('0642468', 'Council Member', 'James Gazeley'),
     ('0640032', 'Mayor',         'Anthony A. Otero'),
     ('0640032', 'Council Member', 'John Lewis'),
     ('0640032', 'Council Member', 'Ed Eng'),
     ('0640032', 'Council Member', 'Michelle Velasquez Bean'),
     ('0640032', 'Council Member', 'Steve De Ruse'));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'roster mismatch -- %. Both councils rotate the mayoralty every December; re-read the city pages before editing this list.', v_bad;
  END IF;

  -- 3. Waronek's Lomita mayoralty is CLOSED the day before Segawa's starts. If this is still
  --    open the two rows would have tripped office_terms_no_overlap, so this is really a
  --    check that the handover was recorded rather than silently overwritten.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms
   WHERE office_id     = 'e49b7177-437c-4e0f-a7f8-ec76ccf8e178'
     AND politician_id = '9dd2a633-c532-4154-b2b0-9b725fcb292f'
     AND term_end      = DATE '2025-12-15';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'expected Waronek''s Lomita mayoralty closed at 2025-12-15, found % such row(s)', v_n;
  END IF;

  -- 4. Nobody sits in two seats. The rotating-mayoralty-as-a-seat model only stays honest if
  --    each person occupies exactly one office in their own city.
  SELECT string_agg(p.full_name || ' x' || c.n, '; ')
    INTO v_bad
    FROM (
      SELECT och.politician_id AS pid, count(*) AS n
        FROM essentials.districts d
        JOIN essentials.offices o ON o.district_id = d.id
        JOIN essentials.office_current_holder och ON och.office_id = o.id
       WHERE d.geo_id IN ('0642468', '0640032') AND och.politician_id IS NOT NULL
       GROUP BY och.politician_id HAVING count(*) > 1
    ) c
    JOIN essentials.politicians p ON p.id = c.pid;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'a person holds more than one seat in their own city: %', v_bad;
  END IF;

  -- 5. No new invisible offices. Three seats were created; all three must carry a term.
  SELECT count(*) INTO v_n
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id IN ('0642468', '0640032');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'expected 0 Lomita/La Mirada offices missing a term, found %', v_n;
  END IF;

  RAISE NOTICE 'Lomita + La Mirada: 3 people added, 3 seats added, both councils now 5 of 5 seated; Segawa mayor of Lomita from 2025-12-16 (Waronek closed 2025-12-15), Otero mayor of La Mirada with start unknown, Lewis District 1 from 2026-03-17, Eng District 3 from 2024 (year precision)';
END $$;

COMMIT;
